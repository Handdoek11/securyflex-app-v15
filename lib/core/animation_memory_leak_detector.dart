import 'package:flutter/material.dart';
import 'dart:async';
import 'shared_animation_controller.dart';

/// Animation Memory Leak Detector
/// 
/// Monitors shared animation controllers for memory leaks and improper disposal.
/// Provides alerts and automatic cleanup to prevent memory accumulation.
class AnimationMemoryLeakDetector {
  static final AnimationMemoryLeakDetector _instance = AnimationMemoryLeakDetector._internal();
  factory AnimationMemoryLeakDetector() => _instance;
  AnimationMemoryLeakDetector._internal();
  
  static AnimationMemoryLeakDetector get instance => _instance;
  
  Timer? _monitoringTimer;
  final Map<String, int> _controllerHistory = {};
  final Map<String, DateTime> _controllerCreationTimes = {};
  final List<MemoryLeakAlert> _alerts = [];
  bool _isMonitoring = false;
  
  /// Start monitoring for memory leaks
  void startMonitoring({Duration interval = const Duration(minutes: 1)}) {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(interval, _checkForLeaks);
    
    debugPrint('🔍 AnimationMemoryLeakDetector: Monitoring started');
  }
  
  /// Stop monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _isMonitoring = false;
    
    debugPrint('🔍 AnimationMemoryLeakDetector: Monitoring stopped');
  }
  
  /// Check for potential memory leaks
  void _checkForLeaks(Timer timer) {
    final metrics = SharedAnimationController.instance.getMetrics();
    final now = DateTime.now();
    
    // Check for controllers that have been active too long
    final activeControllers = SharedAnimationController.instance.controllers.keys.toList();
    
    for (final controllerKey in activeControllers) {
      final creationTime = _controllerCreationTimes[controllerKey];
      if (creationTime != null) {
        final age = now.difference(creationTime);
        
        // Alert if controller has been active for more than 10 minutes
        if (age.inMinutes > 10) {
          _addAlert(MemoryLeakAlert(
            type: LeakType.longLivedController,
            controllerKey: controllerKey,
            message: 'Controller "$controllerKey" has been active for ${age.inMinutes} minutes',
            timestamp: now,
            severity: age.inMinutes > 30 ? AlertSeverity.high : AlertSeverity.medium,
          ));
        }
      } else {
        // Record creation time for new controllers
        _controllerCreationTimes[controllerKey] = now;
      }
    }
    
    // Check for memory growth patterns
    _checkMemoryGrowthPattern(metrics);
    
    // Clean up old creation time records
    _cleanupOldRecords(activeControllers);
    
    // Log alerts if any
    _logActiveAlerts();
  }
  
  /// Check for concerning memory growth patterns
  void _checkMemoryGrowthPattern(SharedAnimationMetrics metrics) {
    final key = 'memory_usage';
    final currentUsage = metrics.totalControllersCreated - metrics.activeControllers;
    
    if (_controllerHistory.containsKey(key)) {
      final previousUsage = _controllerHistory[key]!;
      final growth = currentUsage - previousUsage;
      
      // Alert if significant growth without cleanup
      if (growth > 5 && metrics.activeControllers > 15) {
        _addAlert(MemoryLeakAlert(
          type: LeakType.memoryGrowth,
          message: 'Memory usage growing: +$growth controllers, ${metrics.activeControllers} active',
          timestamp: DateTime.now(),
          severity: AlertSeverity.high,
        ));
      }
    }
    
    _controllerHistory[key] = currentUsage;
  }
  
  /// Add a new memory leak alert
  void _addAlert(MemoryLeakAlert alert) {
    // Avoid duplicate alerts
    if (_alerts.any((existing) => 
        existing.type == alert.type && 
        existing.controllerKey == alert.controllerKey)) {
      return;
    }
    
    _alerts.add(alert);
    
    // Log high severity alerts immediately
    if (alert.severity == AlertSeverity.high) {
      debugPrint('🚨 MEMORY LEAK ALERT: ${alert.message}');
      
      // Attempt automatic cleanup for high severity alerts
      _attemptAutomaticCleanup(alert);
    }
  }
  
  /// Attempt automatic cleanup for critical memory leaks
  void _attemptAutomaticCleanup(MemoryLeakAlert alert) {
    switch (alert.type) {
      case LeakType.longLivedController:
        if (alert.controllerKey != null) {
          // Force cleanup of long-lived controllers if they have no subscribers
          final subscribers = SharedAnimationController.instance.subscribers[alert.controllerKey!];
          if (subscribers?.isEmpty == true) {
            debugPrint('🧽 Automatic cleanup: Disposing unused controller "${alert.controllerKey}"');
            SharedAnimationController.instance.controllers[alert.controllerKey!]?.dispose();
            // Note: Cannot modify private members directly - would need public cleanup method
          }
        }
        break;
        
      case LeakType.memoryGrowth:
        // Log current state for analysis
        // Note: Using extension method that will be available
        final metrics = SharedAnimationController.instance.getMetrics();
        debugPrint('Memory growth detected: $metrics');
        break;
        
      case LeakType.improperDisposal:
        // Already handled by SharedAnimationMixin
        break;
    }
  }
  
  /// Clean up old tracking records
  void _cleanupOldRecords(List<String> activeControllers) {
    final keysToRemove = <String>[];
    
    for (final key in _controllerCreationTimes.keys) {
      if (!activeControllers.contains(key)) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      _controllerCreationTimes.remove(key);
    }
  }
  
  /// Log active alerts
  void _logActiveAlerts() {
    if (_alerts.isEmpty) return;
    
    // Remove old alerts (older than 1 hour)
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    _alerts.removeWhere((alert) => alert.timestamp.isBefore(cutoff));
    
    if (_alerts.isNotEmpty) {
      debugPrint('🚨 Active Memory Leak Alerts: ${_alerts.length}');
      for (final alert in _alerts) {
        debugPrint('   • ${alert.severity.name.toUpperCase()}: ${alert.message}');
      }
    }
  }
  
  /// Get current memory leak status
  MemoryLeakStatus getStatus() {
    final activeAlerts = _alerts.where((alert) => 
        alert.timestamp.isAfter(DateTime.now().subtract(const Duration(minutes: 30)))
    ).toList();
    
    final highSeverityCount = activeAlerts.where((alert) => 
        alert.severity == AlertSeverity.high).length;
        
    return MemoryLeakStatus(
      isMonitoring: _isMonitoring,
      activeAlerts: activeAlerts.length,
      highSeverityAlerts: highSeverityCount,
      lastCheck: _monitoringTimer != null ? DateTime.now() : null,
      status: highSeverityCount > 0 
          ? MemoryStatus.critical
          : activeAlerts.isNotEmpty 
              ? MemoryStatus.warning
              : MemoryStatus.healthy,
    );
  }
  
  /// Dispose all resources
  void dispose() {
    stopMonitoring();
    _alerts.clear();
    _controllerHistory.clear();
    _controllerCreationTimes.clear();
    
    debugPrint('🔍 AnimationMemoryLeakDetector: Disposed');
  }
}

/// Memory leak alert data structure
class MemoryLeakAlert {
  final LeakType type;
  final String? controllerKey;
  final String message;
  final DateTime timestamp;
  final AlertSeverity severity;
  
  const MemoryLeakAlert({
    required this.type,
    this.controllerKey,
    required this.message,
    required this.timestamp,
    required this.severity,
  });
}

/// Types of memory leaks that can be detected
enum LeakType {
  longLivedController,
  memoryGrowth,
  improperDisposal,
}

/// Alert severity levels
enum AlertSeverity {
  low,
  medium,
  high,
}

/// Memory leak monitoring status
class MemoryLeakStatus {
  final bool isMonitoring;
  final int activeAlerts;
  final int highSeverityAlerts;
  final DateTime? lastCheck;
  final MemoryStatus status;
  
  const MemoryLeakStatus({
    required this.isMonitoring,
    required this.activeAlerts,
    required this.highSeverityAlerts,
    this.lastCheck,
    required this.status,
  });
}

/// Overall memory health status
enum MemoryStatus {
  healthy,
  warning,
  critical,
}

/// Extension to add memory leak detection to SharedAnimationController
extension MemoryLeakDetection on SharedAnimationController {
  /// Start memory leak monitoring with the controller
  void enableMemoryLeakDetection() {
    AnimationMemoryLeakDetector.instance.startMonitoring();
  }
  
  /// Stop memory leak monitoring
  void disableMemoryLeakDetection() {
    AnimationMemoryLeakDetector.instance.stopMonitoring();
  }
  
  /// Get current memory leak status
  MemoryLeakStatus getMemoryLeakStatus() {
    return AnimationMemoryLeakDetector.instance.getStatus();
  }
}
