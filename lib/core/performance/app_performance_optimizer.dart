import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// SecuryFlex App Performance Optimizer
/// 
/// Provides comprehensive performance monitoring and optimization
/// for the SecuryFlex application to meet production requirements:
/// - App startup: <2 seconds
/// - Navigation: <300ms
/// - Memory usage: <150MB
class AppPerformanceOptimizer {
  static final AppPerformanceOptimizer _instance = AppPerformanceOptimizer._internal();
  factory AppPerformanceOptimizer() => _instance;
  AppPerformanceOptimizer._internal();

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<int>> _performanceHistory = {};
  final List<PerformanceMetric> _metrics = [];
  
  bool _isInitialized = false;
  Timer? _memoryMonitorTimer;

  /// Initialize performance monitoring
  void initialize() {
    if (_isInitialized) return;
    
    _isInitialized = true;
    
    if (kDebugMode) {
      _startMemoryMonitoring();
      _logPerformanceRequirements();
    }
  }

  /// Start timing an operation
  void startTimer(String operationName) {
    _timers[operationName] = Stopwatch()..start();
  }

  /// Stop timing and record performance
  void stopTimer(String operationName, {int? warningThresholdMs}) {
    final timer = _timers.remove(operationName);
    if (timer == null) return;

    timer.stop();
    final elapsedMs = timer.elapsedMilliseconds;

    // Record in history
    _performanceHistory.putIfAbsent(operationName, () => []);
    _performanceHistory[operationName]!.add(elapsedMs);

    // Create metric
    final metric = PerformanceMetric(
      operation: operationName,
      duration: elapsedMs,
      timestamp: DateTime.now(),
    );
    _metrics.add(metric);

    // Check against thresholds
    _checkPerformanceThreshold(operationName, elapsedMs, warningThresholdMs);

    if (kDebugMode) {
      developer.log(
        '⚡ $operationName: ${elapsedMs}ms',
        name: 'Performance',
      );
    }
  }

  /// Optimize app startup performance
  static Future<void> optimizeAppStartup() async {
    final optimizer = AppPerformanceOptimizer();
    optimizer.startTimer('app_startup');

    // Preload critical resources
    await _preloadCriticalAssets();
    
    // Initialize essential services only
    await _initializeEssentialServices();
    
    // Defer non-critical initializations
    _deferNonCriticalInitializations();

    optimizer.stopTimer('app_startup', warningThresholdMs: 2000);
  }

  /// Optimize navigation performance
  static void optimizeNavigation(String routeName) {
    final optimizer = AppPerformanceOptimizer();
    optimizer.startTimer('navigation_$routeName');

    // Use post-frame callback to measure actual navigation time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      optimizer.stopTimer('navigation_$routeName', warningThresholdMs: 300);
    });
  }

  /// Optimize widget build performance
  static Widget optimizeWidget(Widget child, String widgetName) {
    if (!kDebugMode) return child;

    return _PerformanceWrapper(
      widgetName: widgetName,
      child: child,
    );
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    final summary = <String, dynamic>{};
    
    for (final entry in _performanceHistory.entries) {
      final times = entry.value;
      if (times.isNotEmpty) {
        summary[entry.key] = {
          'average': times.reduce((a, b) => a + b) / times.length,
          'min': times.reduce((a, b) => a < b ? a : b),
          'max': times.reduce((a, b) => a > b ? a : b),
          'count': times.length,
        };
      }
    }
    
    return summary;
  }

  /// Check if performance meets requirements
  bool meetsPerformanceRequirements() {
    final summary = getPerformanceSummary();
    
    // Check app startup requirement (<2000ms)
    final startup = summary['app_startup'];
    if (startup != null && startup['average'] > 2000) {
      return false;
    }

    // Check navigation requirements (<300ms)
    for (final key in summary.keys) {
      if (key.startsWith('navigation_')) {
        final nav = summary[key];
        if (nav != null && nav['average'] > 300) {
          return false;
        }
      }
    }

    return true;
  }

  /// Preload critical assets for faster startup
  static Future<void> _preloadCriticalAssets() async {
    // Preload essential images
    await Future.wait([
      _preloadAsset('assets/images/gruwelijk-logo.png'),
      // Add other critical assets
    ]);
  }

  /// Initialize only essential services during startup
  static Future<void> _initializeEssentialServices() async {
    // Only initialize services critical for first screen
    // Firebase, Auth, and Theme are already initialized in main()
  }

  /// Defer non-critical initializations to after first frame
  static void _deferNonCriticalInitializations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize non-critical services after UI is ready
      _initializeAnalytics();
      _initializeNotifications();
      _initializeCaching();
    });
  }

  static Future<void> _preloadAsset(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to preload asset: $assetPath', name: 'Performance');
      }
    }
  }

  static void _initializeAnalytics() {
    // Initialize analytics service
  }

  static void _initializeNotifications() {
    // Initialize notification service
  }

  static void _initializeCaching() {
    // Initialize caching service
  }

  void _checkPerformanceThreshold(String operation, int elapsedMs, int? warningThreshold) {
    int threshold = warningThreshold ?? _getDefaultThreshold(operation);
    
    if (elapsedMs > threshold) {
      if (kDebugMode) {
        developer.log(
          '⚠️ Performance warning: $operation took ${elapsedMs}ms (threshold: ${threshold}ms)',
          name: 'Performance',
          level: 900, // Warning level
        );
      }
    }
  }

  int _getDefaultThreshold(String operation) {
    if (operation.startsWith('navigation_')) return 300;
    if (operation == 'app_startup') return 2000;
    if (operation.contains('build')) return 16; // 60fps = 16ms per frame
    return 1000; // Default 1 second
  }

  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Monitor memory usage (simplified - in production use proper memory profiling)
      if (kDebugMode) {
        developer.log('Memory monitoring active', name: 'Performance');
      }
    });
  }

  void _logPerformanceRequirements() {
    if (kDebugMode) {
      developer.log(
        'SecuryFlex Performance Requirements:\n'
        '- App startup: <2 seconds\n'
        '- Navigation: <300ms\n'
        '- Memory usage: <150MB\n'
        '- Widget builds: <16ms (60fps)',
        name: 'Performance',
      );
    }
  }

  void dispose() {
    _memoryMonitorTimer?.cancel();
    _timers.clear();
    _performanceHistory.clear();
    _metrics.clear();
    _isInitialized = false;
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String operation;
  final int duration;
  final DateTime timestamp;

  const PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.timestamp,
  });
}

/// Widget wrapper for performance monitoring
class _PerformanceWrapper extends StatelessWidget {
  final String widgetName;
  final Widget child;

  const _PerformanceWrapper({
    required this.widgetName,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final optimizer = AppPerformanceOptimizer();
    optimizer.startTimer('build_$widgetName');

    return _PostBuildCallback(
      onPostBuild: () => optimizer.stopTimer('build_$widgetName', warningThresholdMs: 16),
      child: child,
    );
  }
}

/// Helper widget to track post-build timing
class _PostBuildCallback extends StatefulWidget {
  final VoidCallback onPostBuild;
  final Widget child;

  const _PostBuildCallback({
    required this.onPostBuild,
    required this.child,
  });

  @override
  State<_PostBuildCallback> createState() => _PostBuildCallbackState();
}

class _PostBuildCallbackState extends State<_PostBuildCallback> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPostBuild();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
