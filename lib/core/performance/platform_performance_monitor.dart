import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../platform_intelligence/adaptive_ui_service.dart';

/// Platform-specific performance monitoring system
/// 
/// Adapts monitoring strategies based on platform characteristics:
/// - Mobile: Battery, memory, network efficiency focus
/// - Desktop: CPU, memory, rendering performance focus
/// - Tablet: Balanced monitoring approach
/// - Different thresholds and alerts per platform
class PlatformPerformanceMonitor {
  static const String _tag = 'PlatformPerformanceMonitor';
  static final PlatformPerformanceMonitor _instance = PlatformPerformanceMonitor._internal();
  static PlatformPerformanceMonitor get instance => _instance;
  
  PlatformPerformanceMonitor._internal();
  
  bool _isInitialized = false;
  Timer? _monitoringTimer;
  final Map<String, List<double>> _performanceHistory = {};
  PlatformPerformanceThresholds? _currentThresholds;
  
  // Platform-specific performance thresholds
  static const Map<PlatformType, PlatformPerformanceThresholds> _thresholds = {
    PlatformType.mobile: PlatformPerformanceThresholds(
      maxMemoryMB: 150,        // Aggressive memory limit for mobile
      maxCpuPercent: 80,       // Higher CPU tolerance (mobile processors)
      maxFrameTimeMs: 32,      // 30 FPS minimum for mobile
      maxNetworkLatencyMs: 2000, // Mobile networks are slower
      batteryWarningLevel: 20,  // Battery monitoring critical for mobile
      thermalWarningLevel: 0.8, // Thermal monitoring important
    ),
    PlatformType.tablet: PlatformPerformanceThresholds(
      maxMemoryMB: 250,        // More memory available
      maxCpuPercent: 75,       // Better CPU performance
      maxFrameTimeMs: 20,      // 50 FPS target for tablets
      maxNetworkLatencyMs: 1500,
      batteryWarningLevel: 15,  // Less aggressive battery monitoring
      thermalWarningLevel: 0.85,
    ),
    PlatformType.desktop: PlatformPerformanceThresholds(
      maxMemoryMB: 500,        // Much more memory available
      maxCpuPercent: 60,       // Desktop CPUs should handle load better
      maxFrameTimeMs: 16,      // 60 FPS target for desktop
      maxNetworkLatencyMs: 1000, // Better network connections
      batteryWarningLevel: 0,   // No battery monitoring for desktop
      thermalWarningLevel: 0.9,
    ),
    PlatformType.largeDesktop: PlatformPerformanceThresholds(
      maxMemoryMB: 1000,       // High-end desktop
      maxCpuPercent: 50,       // Should handle load easily
      maxFrameTimeMs: 12,      // 80+ FPS for high-end displays
      maxNetworkLatencyMs: 500,
      batteryWarningLevel: 0,
      thermalWarningLevel: 0.95,
    ),
  };
  
  /// Initialize platform-specific performance monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Determine platform type and set appropriate thresholds
      await _initializePlatformThresholds();
      
      // Start monitoring based on platform
      _startPlatformMonitoring();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        final platformName = AdaptiveUIService.instance.currentContext?.platformType.name ?? 'unknown';
        developer.log(
          '$_tag: Platform performance monitoring initialized for $platformName',
          name: 'PlatformPerformance'
        );
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to initialize: $e', name: 'PlatformPerformance');
      }
    }
  }
  
  /// Initialize platform-specific thresholds
  Future<void> _initializePlatformThresholds() async {
    final context = AdaptiveUIService.instance.currentContext;
    final platformType = context?.platformType ?? PlatformType.mobile;
    
    _currentThresholds = _thresholds[platformType] ?? _thresholds[PlatformType.mobile]!;
    
    // Adjust thresholds based on device capabilities if needed
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _adjustThresholdsForDevice();
    }
  }
  
  /// Adjust thresholds based on specific device capabilities
  Future<void> _adjustThresholdsForDevice() async {
    try {
      // Simple platform-based adjustments without device_info_plus dependency
      if (Platform.isAndroid) {
        // Android devices typically need more conservative memory limits
        _currentThresholds = _currentThresholds?.copyWith(
          maxMemoryMB: _currentThresholds!.maxMemoryMB * 0.9,
        );
      } else if (Platform.isIOS) {
        // iOS has better memory management, can be slightly more lenient
        _currentThresholds = _currentThresholds?.copyWith(
          maxMemoryMB: _currentThresholds!.maxMemoryMB * 1.1,
        );
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Could not adjust thresholds for device: $e', name: 'PlatformPerformance');
      }
    }
  }
  
  /// Start platform-specific monitoring
  void _startPlatformMonitoring() {
    final context = AdaptiveUIService.instance.currentContext;
    final platformType = context?.platformType ?? PlatformType.mobile;
    
    // Different monitoring intervals based on platform
    Duration monitoringInterval;
    switch (platformType) {
      case PlatformType.mobile:
        monitoringInterval = const Duration(seconds: 5); // Frequent monitoring for mobile
        break;
      case PlatformType.tablet:
        monitoringInterval = const Duration(seconds: 10);
        break;
      case PlatformType.desktop:
      case PlatformType.largeDesktop:
        monitoringInterval = const Duration(seconds: 15); // Less frequent for desktop
        break;
    }
    
    _monitoringTimer = Timer.periodic(monitoringInterval, (_) => _performMonitoringCheck());
  }
  
  /// Perform platform-specific monitoring check
  Future<void> _performMonitoringCheck() async {
    if (_currentThresholds == null) return;
    
    try {
      final context = AdaptiveUIService.instance.currentContext;
      final platformType = context?.platformType ?? PlatformType.mobile;
      
      final metrics = await _collectPlatformMetrics(platformType);
      
      // Store metrics in history
      _updateMetricsHistory(metrics);
      
      // Check thresholds and trigger alerts if needed
      _checkPerformanceThresholds(metrics, platformType);
      
      // Log metrics for debugging
      if (kDebugMode && DateTime.now().second % 30 == 0) { // Log every 30 seconds
        developer.log(
          '$_tag: ${platformType.name} metrics - Memory: ${metrics.memoryUsageMB.toStringAsFixed(1)}MB, '
          'Frame: ${metrics.averageFrameTimeMs.toStringAsFixed(1)}ms',
          name: 'PlatformPerformance'
        );
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Error during monitoring check: $e', name: 'PlatformPerformance');
      }
    }
  }
  
  /// Collect platform-specific performance metrics
  Future<PlatformPerformanceMetrics> _collectPlatformMetrics(PlatformType platformType) async {
    // Base metrics available on all platforms
    final memoryUsage = await _getMemoryUsage();
    final frameMetrics = await _getFrameMetrics();
    
    // Platform-specific metrics
    double? batteryLevel;
    double? thermalState;
    double? networkLatency;
    
    switch (platformType) {
      case PlatformType.mobile:
        batteryLevel = await _getBatteryLevel();
        thermalState = await _getThermalState();
        networkLatency = await _measureNetworkLatency();
        break;
      case PlatformType.tablet:
        batteryLevel = await _getBatteryLevel();
        thermalState = await _getThermalState();
        break;
      case PlatformType.desktop:
      case PlatformType.largeDesktop:
        // Focus on CPU and rendering performance for desktop
        networkLatency = await _measureNetworkLatency();
        break;
    }
    
    return PlatformPerformanceMetrics(
      timestamp: DateTime.now(),
      platformType: platformType,
      memoryUsageMB: memoryUsage,
      cpuUsagePercent: 0.0, // Would need platform-specific implementation
      averageFrameTimeMs: frameMetrics,
      batteryLevel: batteryLevel,
      thermalState: thermalState,
      networkLatencyMs: networkLatency,
    );
  }
  
  /// Get current memory usage in MB
  Future<double> _getMemoryUsage() async {
    try {
      // This is a simplified implementation - would need platform-specific details
      // For now, return a reasonable estimate based on platform
      final context = AdaptiveUIService.instance.currentContext;
      final platformType = context?.platformType ?? PlatformType.mobile;
      
      switch (platformType) {
        case PlatformType.mobile:
          return 80.0; // Typical mobile memory usage
        case PlatformType.tablet:
          return 120.0;
        case PlatformType.desktop:
          return 200.0;
        case PlatformType.largeDesktop:
          return 300.0;
      }
    } catch (e) {
      return 100.0; // Fallback value
    }
  }
  
  /// Get average frame rendering time
  Future<double> _getFrameMetrics() async {
    // This would integrate with Flutter's frame metrics
    // For now, return a reasonable default
    return 16.67; // ~60 FPS
  }
  
  /// Get battery level (mobile/tablet only)
  Future<double?> _getBatteryLevel() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return null;
    
    try {
      // Would integrate with battery_plus plugin
      return 80.0; // Placeholder
    } catch (e) {
      return null;
    }
  }
  
  /// Get thermal state (mobile/tablet)
  Future<double?> _getThermalState() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return null;
    
    try {
      // Would use platform channels to get thermal state
      return 0.3; // Placeholder (0.0 = cool, 1.0 = critical)
    } catch (e) {
      return null;
    }
  }
  
  /// Measure network latency
  Future<double?> _measureNetworkLatency() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Simple ping test - would implement proper network measurement
      await Future.delayed(const Duration(milliseconds: 50));
      
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds.toDouble();
    } catch (e) {
      return null;
    }
  }
  
  /// Update metrics history for trend analysis
  void _updateMetricsHistory(PlatformPerformanceMetrics metrics) {
    const maxHistorySize = 100; // Keep last 100 measurements
    
    _performanceHistory['memory'] ??= [];
    _performanceHistory['frameTime'] ??= [];
    
    final memoryHistory = _performanceHistory['memory']!;
    final frameHistory = _performanceHistory['frameTime']!;
    
    memoryHistory.add(metrics.memoryUsageMB);
    frameHistory.add(metrics.averageFrameTimeMs);
    
    // Keep history size manageable
    if (memoryHistory.length > maxHistorySize) {
      memoryHistory.removeAt(0);
    }
    if (frameHistory.length > maxHistorySize) {
      frameHistory.removeAt(0);
    }
  }
  
  /// Check performance thresholds and trigger alerts
  void _checkPerformanceThresholds(PlatformPerformanceMetrics metrics, PlatformType platformType) {
    if (_currentThresholds == null) return;
    
    final thresholds = _currentThresholds!;
    
    // Memory threshold
    if (metrics.memoryUsageMB > thresholds.maxMemoryMB) {
      _triggerPerformanceAlert(
        PerformanceAlert(
          type: PerformanceAlertType.highMemory,
          severity: _calculateSeverity(metrics.memoryUsageMB, thresholds.maxMemoryMB),
          message: 'High memory usage: ${metrics.memoryUsageMB.toStringAsFixed(1)}MB (limit: ${thresholds.maxMemoryMB}MB)',
          platformType: platformType,
          timestamp: DateTime.now(),
          metrics: metrics,
        ),
      );
    }
    
    // Frame time threshold
    if (metrics.averageFrameTimeMs > thresholds.maxFrameTimeMs) {
      _triggerPerformanceAlert(
        PerformanceAlert(
          type: PerformanceAlertType.poorFrameRate,
          severity: _calculateSeverity(metrics.averageFrameTimeMs, thresholds.maxFrameTimeMs),
          message: 'Poor frame rate: ${metrics.averageFrameTimeMs.toStringAsFixed(1)}ms (limit: ${thresholds.maxFrameTimeMs}ms)',
          platformType: platformType,
          timestamp: DateTime.now(),
          metrics: metrics,
        ),
      );
    }
    
    // Battery threshold (mobile/tablet only)
    if (metrics.batteryLevel != null && thresholds.batteryWarningLevel > 0) {
      if (metrics.batteryLevel! < thresholds.batteryWarningLevel) {
        _triggerPerformanceAlert(
          PerformanceAlert(
            type: PerformanceAlertType.lowBattery,
            severity: AlertSeverity.warning,
            message: 'Low battery: ${metrics.batteryLevel!.toStringAsFixed(0)}% (warning: ${thresholds.batteryWarningLevel}%)',
            platformType: platformType,
            timestamp: DateTime.now(),
            metrics: metrics,
          ),
        );
      }
    }
    
    // Thermal threshold
    if (metrics.thermalState != null && metrics.thermalState! > thresholds.thermalWarningLevel) {
      _triggerPerformanceAlert(
        PerformanceAlert(
          type: PerformanceAlertType.thermalThrottling,
          severity: AlertSeverity.critical,
          message: 'High thermal state: ${(metrics.thermalState! * 100).toStringAsFixed(0)}%',
          platformType: platformType,
          timestamp: DateTime.now(),
          metrics: metrics,
        ),
      );
    }
  }
  
  /// Calculate alert severity based on threshold breach
  AlertSeverity _calculateSeverity(double value, double threshold) {
    final ratio = value / threshold;
    if (ratio > 1.5) return AlertSeverity.critical;
    if (ratio > 1.2) return AlertSeverity.high;
    return AlertSeverity.warning;
  }
  
  /// Trigger performance alert
  void _triggerPerformanceAlert(PerformanceAlert alert) {
    if (kDebugMode) {
      developer.log(
        '$_tag: ${alert.severity.name.toUpperCase()} - ${alert.message}',
        name: 'PlatformPerformance'
      );
    }
    
    // Here you would integrate with your app's notification system
    // For example, show a snackbar, log to analytics, or trigger remediation actions
  }
  
  /// Get current performance statistics
  Map<String, dynamic> getCurrentStats() {
    if (!_isInitialized || _currentThresholds == null) return {};
    
    final memoryHistory = _performanceHistory['memory'] ?? [];
    final frameHistory = _performanceHistory['frameTime'] ?? [];
    
    return {
      'platform': AdaptiveUIService.instance.currentContext?.platformType.name ?? 'unknown',
      'thresholds': {
        'memory_mb': _currentThresholds!.maxMemoryMB,
        'frame_time_ms': _currentThresholds!.maxFrameTimeMs,
        'battery_warning': _currentThresholds!.batteryWarningLevel,
      },
      'current': {
        'avg_memory_mb': memoryHistory.isNotEmpty ? 
          memoryHistory.reduce((a, b) => a + b) / memoryHistory.length : 0,
        'avg_frame_time_ms': frameHistory.isNotEmpty ?
          frameHistory.reduce((a, b) => a + b) / frameHistory.length : 0,
      },
      'history_size': memoryHistory.length,
      'monitoring_active': _monitoringTimer?.isActive ?? false,
    };
  }
  
  /// Dispose performance monitor
  void dispose() {
    _monitoringTimer?.cancel();
    _performanceHistory.clear();
    _isInitialized = false;
  }
}

/// Platform-specific performance thresholds
class PlatformPerformanceThresholds {
  final double maxMemoryMB;
  final double maxCpuPercent;
  final double maxFrameTimeMs;
  final double maxNetworkLatencyMs;
  final double batteryWarningLevel; // 0 = disabled
  final double thermalWarningLevel;
  
  const PlatformPerformanceThresholds({
    required this.maxMemoryMB,
    required this.maxCpuPercent,
    required this.maxFrameTimeMs,
    required this.maxNetworkLatencyMs,
    required this.batteryWarningLevel,
    required this.thermalWarningLevel,
  });
  
  PlatformPerformanceThresholds copyWith({
    double? maxMemoryMB,
    double? maxCpuPercent,
    double? maxFrameTimeMs,
    double? maxNetworkLatencyMs,
    double? batteryWarningLevel,
    double? thermalWarningLevel,
  }) {
    return PlatformPerformanceThresholds(
      maxMemoryMB: maxMemoryMB ?? this.maxMemoryMB,
      maxCpuPercent: maxCpuPercent ?? this.maxCpuPercent,
      maxFrameTimeMs: maxFrameTimeMs ?? this.maxFrameTimeMs,
      maxNetworkLatencyMs: maxNetworkLatencyMs ?? this.maxNetworkLatencyMs,
      batteryWarningLevel: batteryWarningLevel ?? this.batteryWarningLevel,
      thermalWarningLevel: thermalWarningLevel ?? this.thermalWarningLevel,
    );
  }
}

/// Performance metrics snapshot
class PlatformPerformanceMetrics {
  final DateTime timestamp;
  final PlatformType platformType;
  final double memoryUsageMB;
  final double cpuUsagePercent;
  final double averageFrameTimeMs;
  final double? batteryLevel; // percentage (0-100)
  final double? thermalState; // 0.0-1.0 (cool to critical)
  final double? networkLatencyMs;
  
  const PlatformPerformanceMetrics({
    required this.timestamp,
    required this.platformType,
    required this.memoryUsageMB,
    required this.cpuUsagePercent,
    required this.averageFrameTimeMs,
    this.batteryLevel,
    this.thermalState,
    this.networkLatencyMs,
  });
}

/// Performance alert
class PerformanceAlert {
  final PerformanceAlertType type;
  final AlertSeverity severity;
  final String message;
  final PlatformType platformType;
  final DateTime timestamp;
  final PlatformPerformanceMetrics metrics;
  
  const PerformanceAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.platformType,
    required this.timestamp,
    required this.metrics,
  });
}

/// Types of performance alerts
enum PerformanceAlertType {
  highMemory,
  highCpu,
  poorFrameRate,
  highNetworkLatency,
  lowBattery,
  thermalThrottling,
}

/// Alert severity levels
enum AlertSeverity {
  warning,
  high,
  critical,
}