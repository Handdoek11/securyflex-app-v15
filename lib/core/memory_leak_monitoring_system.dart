import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'memory_leak_detector.dart';
import 'animation_controller_monitor.dart';
import 'tab_performance_monitor.dart';
import 'memory_optimization_reporter.dart';

/// Memory Leak Monitoring System Coordinator
/// 
/// This is the master coordinator that initializes and manages all memory leak
/// detection and performance monitoring systems for the SecuryFlex tab optimizations.
/// 
/// **Integrated Systems:**
/// - MemoryLeakDetector: Real-time memory leak detection (<1s response)
/// - AnimationControllerMonitor: Controller lifecycle and pool tracking
/// - TabPerformanceMonitor: Tab-specific performance monitoring
/// - MemoryOptimizationReporter: Comprehensive reporting and trend analysis
/// 
/// **Usage:**
/// ```dart
/// // Initialize monitoring (call in main.dart)
/// MemoryLeakMonitoringSystem.instance.initialize();
/// 
/// // Get real-time status
/// final status = await MemoryLeakMonitoringSystem.instance.getSystemStatus();
/// 
/// // Generate comprehensive report
/// final report = await MemoryLeakMonitoringSystem.instance.generateReport();
/// ```
class MemoryLeakMonitoringSystem {
  static final MemoryLeakMonitoringSystem _instance = MemoryLeakMonitoringSystem._internal();
  factory MemoryLeakMonitoringSystem() => _instance;
  MemoryLeakMonitoringSystem._internal();
  
  static MemoryLeakMonitoringSystem get instance => _instance;
  
  bool _isInitialized = false;
  Timer? _healthCheckTimer;
  
  // System health status
  SystemHealthStatus _healthStatus = SystemHealthStatus.unknown;
  DateTime? _lastHealthCheck;
  final List<SystemAlert> _systemAlerts = [];
  
  /// Initialize the complete monitoring system
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🛡️ MemoryLeakMonitoringSystem: Already initialized');
      return;
    }
    
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🛡️ MemoryLeakMonitoringSystem: Initializing comprehensive monitoring system...');
      
      // Initialize individual monitoring systems
      MemoryLeakDetector.instance.initialize();
      AnimationControllerMonitor.instance.initialize();
      TabPerformanceMonitor.instance.initialize();
      MemoryOptimizationReporter.instance.initialize();
      
      // Start system health monitoring
      _startHealthMonitoring();
      
      _isInitialized = true;
      _healthStatus = SystemHealthStatus.healthy;
      
      stopwatch.stop();
      
      debugPrint('✅ MemoryLeakMonitoringSystem: Initialization complete (${stopwatch.elapsedMilliseconds}ms)');
      debugPrint('   🔍 Memory leak detection: ACTIVE (target: <1s response)');
      debugPrint('   🎬 Animation controller monitoring: ACTIVE (pool size tracking)');
      debugPrint('   📊 Tab performance monitoring: ACTIVE (Dashboard: 40MB, Jobs: 10MB, Planning: 25MB)');
      debugPrint('   📊 Optimization reporting: ACTIVE (5min snapshots)');
      debugPrint('   ❤️ System health monitoring: ACTIVE (30s intervals)');
      
      // Log system targets
      _logOptimizationTargets();
      
    } catch (e) {
      stopwatch.stop();
      _healthStatus = SystemHealthStatus.critical;
      
      debugPrint('🚨 MemoryLeakMonitoringSystem: Initialization failed: $e');
      rethrow;
    }
  }
  
  /// Dispose the complete monitoring system
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    debugPrint('🛡️ MemoryLeakMonitoringSystem: Shutting down monitoring system...');
    
    _healthCheckTimer?.cancel();
    
    // Dispose individual systems
    MemoryLeakDetector.instance.dispose();
    AnimationControllerMonitor.instance.dispose();
    TabPerformanceMonitor.instance.dispose();
    MemoryOptimizationReporter.instance.dispose();
    
    _isInitialized = false;
    _healthStatus = SystemHealthStatus.stopped;
    
    debugPrint('✅ MemoryLeakMonitoringSystem: Shutdown complete');
  }
  
  /// Get real-time system monitoring status
  Future<SystemMonitoringStatus> getSystemStatus() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Collect data from all monitoring systems
      final memoryReport = MemoryLeakDetector.instance.getOptimizationReport();
      final controllerMetrics = AnimationControllerMonitor.instance.getPerformanceMetrics();
      final tabReport = TabPerformanceMonitor.instance.getOverallPerformanceReport();
      
      // Perform real-time leak detection
      final leakAnalysis = await MemoryLeakDetector.instance.detectMemoryLeaks();
      final controllerLeaks = await AnimationControllerMonitor.instance.detectControllerLeaks();
      
      stopwatch.stop();
      
      // Calculate system health
      final systemHealth = _calculateSystemHealth(
        memoryReport,
        controllerMetrics,
        tabReport,
        leakAnalysis,
        controllerLeaks,
      );
      
      return SystemMonitoringStatus(
        isHealthy: systemHealth.isHealthy,
        healthStatus: systemHealth.status,
        statusCheckTimeMs: stopwatch.elapsedMilliseconds,
        
        // Memory monitoring
        memoryOptimizationEffective: memoryReport.optimizationEffectiveness > 0.8,
        dashboardMemoryMB: _getScreenMemoryUsage(memoryReport, 'dashboard'),
        jobsMemoryMB: _getScreenMemoryUsage(memoryReport, 'jobs'),
        planningMemoryMB: _getScreenMemoryUsage(memoryReport, 'planning'),
        
        // Controller monitoring
        controllerPoolHealthy: controllerMetrics.optimizationTargetMet,
        activeControllers: memoryReport.controllerMetrics.activeControllers,
        memorySavedMB: controllerMetrics.totalMemorySavedMB,
        memoryReductionPercentage: controllerMetrics.memoryReductionPercentage,
        
        // Performance monitoring
        tabPerformanceGood: tabReport.overallOptimizationEffectiveness > 0.8,
        activeTab: tabReport.currentActiveTab,
        totalViolations: tabReport.totalViolations,
        
        // Leak detection
        memoryLeaksDetected: leakAnalysis.leaksDetected.length,
        controllerLeaksDetected: controllerLeaks.length,
        leakDetectionTimeMs: leakAnalysis.detectionTimeMs,
        
        // Alerts
        activeAlerts: _systemAlerts.length,
        criticalAlerts: _systemAlerts.where((a) => a.severity == AlertSeverity.critical).length,
        
        // System info
        monitoringActive: _isInitialized,
        lastHealthCheck: _lastHealthCheck ?? DateTime.now(),
        statusTimestamp: DateTime.now(),
      );
      
    } catch (e) {
      stopwatch.stop();
      
      debugPrint('🚨 Error getting system status: $e');
      
      return SystemMonitoringStatus(
        isHealthy: false,
        healthStatus: SystemHealthStatus.critical,
        statusCheckTimeMs: stopwatch.elapsedMilliseconds,
        memoryOptimizationEffective: false,
        dashboardMemoryMB: 0,
        jobsMemoryMB: 0,
        planningMemoryMB: 0,
        controllerPoolHealthy: false,
        activeControllers: 0,
        memorySavedMB: 0,
        memoryReductionPercentage: 0,
        tabPerformanceGood: false,
        activeTab: null,
        totalViolations: 0,
        memoryLeaksDetected: 0,
        controllerLeaksDetected: 0,
        leakDetectionTimeMs: stopwatch.elapsedMilliseconds,
        activeAlerts: 0,
        criticalAlerts: 0,
        monitoringActive: _isInitialized,
        lastHealthCheck: _lastHealthCheck,
        statusTimestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }
  
  /// Generate comprehensive optimization report
  Future<ComprehensiveOptimizationReport> generateReport() async {
    if (!_isInitialized) {
      throw StateError('Monitoring system not initialized. Call initialize() first.');
    }
    
    developer.log(
      '📊 Generating comprehensive optimization report...',
      name: 'MemoryLeakMonitoringSystem'
    );
    
    final report = await MemoryOptimizationReporter.instance.generateReport();
    
    developer.log(
      '✅ Comprehensive report generated: ${report.toString()}',
      name: 'MemoryLeakMonitoringSystem'
    );
    
    return report;
  }
  
  /// Get production-safe summary
  ProductionSummaryReport getProductionSummary() {
    return MemoryOptimizationReporter.instance.generateProductionSummary();
  }
  
  /// Record a system alert
  void recordAlert(AlertSeverity severity, String message, String component, Map<String, dynamic> context) {
    final alert = SystemAlert(
      severity: severity,
      message: message,
      component: component,
      timestamp: DateTime.now(),
      context: context,
    );
    
    _systemAlerts.add(alert);
    
    // Keep only last 100 alerts
    if (_systemAlerts.length > 100) {
      _systemAlerts.removeAt(0);
    }
    
    developer.log(
      '🚨 System Alert [${severity.toString().toUpperCase()}]: $message',
      name: 'MemoryLeakMonitoringSystem'
    );
  }
  
  /// Get active system alerts
  List<SystemAlert> getActiveAlerts() {
    final now = DateTime.now();
    return _systemAlerts.where((alert) => 
      now.difference(alert.timestamp).inMinutes < 30 // Active for 30 minutes
    ).toList();
  }
  
  /// Check if system is healthy
  bool get isHealthy => _healthStatus == SystemHealthStatus.healthy;
  
  /// Get current health status
  SystemHealthStatus get healthStatus => _healthStatus;
  
  /// Clear all monitoring data (for testing)
  void clearAllMonitoringData() {
    MemoryLeakDetector.instance.clearMonitoringData();
    AnimationControllerMonitor.instance.clearMonitoringData();
    TabPerformanceMonitor.instance.clearMonitoringData();
    MemoryOptimizationReporter.instance.clearHistoricalData();
    _systemAlerts.clear();
    
    debugPrint('🛡️ MemoryLeakMonitoringSystem: All monitoring data cleared');
  }
  
  // Private methods
  
  void _startHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }
      
      _performHealthCheck();
    });
  }
  
  void _performHealthCheck() async {
    try {
      _lastHealthCheck = DateTime.now();
      
      // Quick health assessment
      final status = await getSystemStatus();
      
      if (!status.isHealthy) {
        _healthStatus = SystemHealthStatus.degraded;
        
        recordAlert(
          AlertSeverity.high,
          'System health check failed: ${status.error ?? "Performance degraded"}',
          'health_monitor',
          {
            'memoryOptimizationEffective': status.memoryOptimizationEffective,
            'controllerPoolHealthy': status.controllerPoolHealthy,
            'tabPerformanceGood': status.tabPerformanceGood,
          },
        );
      } else {
        _healthStatus = SystemHealthStatus.healthy;
      }
      
    } catch (e) {
      _healthStatus = SystemHealthStatus.critical;
      
      recordAlert(
        AlertSeverity.critical,
        'Health check failed: $e',
        'health_monitor',
        {'error': e.toString()},
      );
    }
  }
  
  void _logOptimizationTargets() {
    debugPrint('💯 MemoryLeakMonitoringSystem: Optimization Targets');
    debugPrint('   🔄 Dashboard Memory: 40MB target (50MB alert threshold)');
    debugPrint('   🔄 Jobs Memory: 10MB target (15MB alert threshold)');
    debugPrint('   🔄 Planning Memory: 25MB target (30MB alert threshold)');
    debugPrint('   🎬 Animation Controllers: ≤8 active (pool optimization)');
    debugPrint('   ⌚ Tab Switching: <100ms target');
    debugPrint('   📊 Memory Reduction: ≥80% target');
    debugPrint('   🔍 Leak Detection: <1000ms response time');
  }
  
  SystemHealthAssessment _calculateSystemHealth(
    MemoryOptimizationReport memoryReport,
    ControllerPerformanceMetrics controllerMetrics,
    TabPerformanceReport tabReport,
    MemoryLeakAnalysis leakAnalysis,
    List<ControllerLeak> controllerLeaks,
  ) {
    final issues = <String>[];
    
    // Check memory optimization effectiveness
    if (memoryReport.optimizationEffectiveness < 0.8) {
      issues.add('Memory optimization below 80%');
    }
    
    // Check controller pool health
    if (!controllerMetrics.optimizationTargetMet) {
      issues.add('Controller optimization targets not met');
    }
    
    // Check for memory leaks
    if (leakAnalysis.leaksDetected.isNotEmpty) {
      issues.add('${leakAnalysis.leaksDetected.length} memory leaks detected');
    }
    
    // Check for controller leaks
    if (controllerLeaks.isNotEmpty) {
      issues.add('${controllerLeaks.length} controller leaks detected');
    }
    
    // Check performance violations
    if (tabReport.totalViolations > 5) {
      issues.add('High number of performance violations (${tabReport.totalViolations})');
    }
    
    // Check leak detection performance
    if (leakAnalysis.detectionTimeMs > 1000) {
      issues.add('Leak detection too slow (${leakAnalysis.detectionTimeMs}ms)');
    }
    
    SystemHealthStatus status;
    if (issues.isEmpty) {
      status = SystemHealthStatus.healthy;
    } else if (issues.length <= 2) {
      status = SystemHealthStatus.degraded;
    } else {
      status = SystemHealthStatus.critical;
    }
    
    return SystemHealthAssessment(
      isHealthy: status == SystemHealthStatus.healthy,
      status: status,
      issues: issues,
    );
  }
  
  int _getScreenMemoryUsage(MemoryOptimizationReport report, String screenName) {
    return report.currentSnapshots[screenName]?.memoryUsageMB ?? 0;
  }
}

/// System monitoring status
class SystemMonitoringStatus {
  final bool isHealthy;
  final SystemHealthStatus healthStatus;
  final int statusCheckTimeMs;
  
  // Memory monitoring
  final bool memoryOptimizationEffective;
  final int dashboardMemoryMB;
  final int jobsMemoryMB;
  final int planningMemoryMB;
  
  // Controller monitoring
  final bool controllerPoolHealthy;
  final int activeControllers;
  final int memorySavedMB;
  final double memoryReductionPercentage;
  
  // Performance monitoring
  final bool tabPerformanceGood;
  final String? activeTab;
  final int totalViolations;
  
  // Leak detection
  final int memoryLeaksDetected;
  final int controllerLeaksDetected;
  final int leakDetectionTimeMs;
  
  // Alerts
  final int activeAlerts;
  final int criticalAlerts;
  
  // System info
  final bool monitoringActive;
  final DateTime? lastHealthCheck;
  final DateTime statusTimestamp;
  final String? error;
  
  const SystemMonitoringStatus({
    required this.isHealthy,
    required this.healthStatus,
    required this.statusCheckTimeMs,
    required this.memoryOptimizationEffective,
    required this.dashboardMemoryMB,
    required this.jobsMemoryMB,
    required this.planningMemoryMB,
    required this.controllerPoolHealthy,
    required this.activeControllers,
    required this.memorySavedMB,
    required this.memoryReductionPercentage,
    required this.tabPerformanceGood,
    required this.activeTab,
    required this.totalViolations,
    required this.memoryLeaksDetected,
    required this.controllerLeaksDetected,
    required this.leakDetectionTimeMs,
    required this.activeAlerts,
    required this.criticalAlerts,
    required this.monitoringActive,
    required this.lastHealthCheck,
    required this.statusTimestamp,
    this.error,
  });
  
  @override
  String toString() {
    return 'SystemMonitoringStatus(';
  }
}

/// System health assessment
class SystemHealthAssessment {
  final bool isHealthy;
  final SystemHealthStatus status;
  final List<String> issues;
  
  const SystemHealthAssessment({
    required this.isHealthy,
    required this.status,
    required this.issues,
  });
}

/// System alert
class SystemAlert {
  final AlertSeverity severity;
  final String message;
  final String component;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  
  const SystemAlert({
    required this.severity,
    required this.message,
    required this.component,
    required this.timestamp,
    required this.context,
  });
}

/// System health status levels
enum SystemHealthStatus {
  unknown,
  healthy,
  degraded,
  critical,
  stopped,
}

/// Alert severity levels
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}