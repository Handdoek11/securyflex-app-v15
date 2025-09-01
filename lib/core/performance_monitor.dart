import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Performance monitoring system for SecuryFlex
/// 
/// Tracks key performance metrics including:
/// - Widget build times
/// - Navigation performance  
/// - Memory usage
/// - Frame rendering metrics
/// - Critical path optimizations
class PerformanceMonitor {
  static final _instance = PerformanceMonitor._internal();
  static PerformanceMonitor get instance => _instance;

  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<int>> _durations = {};
  final List<PerformanceEvent> _events = [];

  /// Start measuring a performance event
  void startMeasurement(String eventName) {
    if (!kDebugMode) return;
    _startTimes[eventName] = DateTime.now();
    developer.log('⏱️ Started: $eventName', name: 'Performance');
  }

  /// End measuring and record performance event
  void endMeasurement(String eventName) {
    if (!kDebugMode) return;
    
    final startTime = _startTimes.remove(eventName);
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _durations.putIfAbsent(eventName, () => []).add(duration);
    
    final event = PerformanceEvent(
      name: eventName,
      duration: duration,
      timestamp: DateTime.now(),
    );
    
    _events.add(event);
    
    // Log performance warnings
    _checkPerformanceThresholds(eventName, duration);
    
    developer.log('✅ Completed: $eventName (${duration}ms)', name: 'Performance');
  }

  /// Measure widget build time
  T measureWidgetBuild<T>(String widgetName, T Function() builder) {
    if (!kDebugMode) return builder();
    
    startMeasurement('widget_build_$widgetName');
    final result = builder();
    endMeasurement('widget_build_$widgetName');
    return result;
  }

  /// Measure navigation performance
  void measureNavigation(String routeName) {
    if (!kDebugMode) return;
    startMeasurement('navigation_$routeName');
    
    // End measurement after next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      endMeasurement('navigation_$routeName');
    });
  }

  /// Record frame rendering metrics
  void recordFrameMetrics() {
    if (!kDebugMode) return;
    
    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final buildDuration = timing.buildDuration.inMicroseconds / 1000;
        final rasterDuration = timing.rasterDuration.inMicroseconds / 1000;
        
        if (buildDuration > 16.0 || rasterDuration > 16.0) {
          developer.log(
            '⚠️ Frame drop detected: Build ${buildDuration.toStringAsFixed(1)}ms, '
            'Raster ${rasterDuration.toStringAsFixed(1)}ms',
            name: 'Performance'
          );
          
          _events.add(PerformanceEvent(
            name: 'frame_drop',
            duration: (buildDuration + rasterDuration).round(),
            timestamp: DateTime.now(),
            metadata: {
              'buildDuration': buildDuration,
              'rasterDuration': rasterDuration,
            },
          ));
        }
      }
    });
  }

  /// Get performance summary
  PerformanceSummary getSummary() {
    final Map<String, PerformanceMetric> metrics = {};
    
    for (final entry in _durations.entries) {
      final durations = entry.value;
      final average = durations.reduce((a, b) => a + b) / durations.length;
      final max = durations.reduce((a, b) => a > b ? a : b);
      final min = durations.reduce((a, b) => a < b ? a : b);
      
      metrics[entry.key] = PerformanceMetric(
        name: entry.key,
        average: average,
        max: max,
        min: min,
        count: durations.length,
      );
    }
    
    return PerformanceSummary(
      metrics: metrics,
      totalEvents: _events.length,
      criticalEvents: _events.where((e) => e.duration > 100).length,
      generatedAt: DateTime.now(),
    );
  }

  /// Log performance summary
  void logSummary() {
    if (!kDebugMode) return;
    
    final summary = getSummary();
    developer.log(
      '📊 Performance Summary:\n'
      'Total events: ${summary.totalEvents}\n'
      'Critical events (>100ms): ${summary.criticalEvents}\n'
      'Top slow operations:',
      name: 'Performance'
    );
    
    final sortedMetrics = summary.metrics.values.toList()
      ..sort((a, b) => b.average.compareTo(a.average));
    
    for (final metric in sortedMetrics.take(5)) {
      developer.log(
        '  ${metric.name}: avg ${metric.average.toStringAsFixed(1)}ms, '
        'max ${metric.max}ms (${metric.count} calls)',
        name: 'Performance'
      );
    }
  }

  /// Clear all performance data
  void clear() {
    _startTimes.clear();
    _durations.clear();
    _events.clear();
  }

  void _checkPerformanceThresholds(String eventName, int duration) {
    String? warning;
    
    if (eventName.startsWith('widget_build_')) {
      if (duration > 16) {
        warning = 'Widget build exceeded 16ms target';
      }
    } else if (eventName.startsWith('navigation_')) {
      if (duration > 300) {
        warning = 'Navigation exceeded 300ms target';
      }
    } else if (eventName.contains('dashboard')) {
      if (duration > 100) {
        warning = 'Dashboard render exceeded 100ms target';
      }
    }
    
    if (warning != null) {
      developer.log('⚠️ $warning: $eventName (${duration}ms)', name: 'Performance');
    }
  }
}

/// Performance event data class
class PerformanceEvent {
  final String name;
  final int duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PerformanceEvent({
    required this.name,
    required this.duration,
    required this.timestamp,
    this.metadata = const {},
  });
}

/// Performance metric aggregation
class PerformanceMetric {
  final String name;
  final double average;
  final int max;
  final int min;
  final int count;

  const PerformanceMetric({
    required this.name,
    required this.average,
    required this.max,
    required this.min,
    required this.count,
  });
}

/// Performance summary
class PerformanceSummary {
  final Map<String, PerformanceMetric> metrics;
  final int totalEvents;
  final int criticalEvents;
  final DateTime generatedAt;

  const PerformanceSummary({
    required this.metrics,
    required this.totalEvents,
    required this.criticalEvents,
    required this.generatedAt,
  });
}

/// Widget mixin for automatic performance tracking
mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  late String _widgetName;

  @override
  void initState() {
    super.initState();
    _widgetName = T.toString();
    PerformanceMonitor.instance.startMeasurement('lifecycle_$_widgetName');
  }

  @override
  Widget build(BuildContext context) {
    return PerformanceMonitor.instance.measureWidgetBuild(
      _widgetName,
      () => buildWidget(context),
    );
  }

  @override
  void dispose() {
    PerformanceMonitor.instance.endMeasurement('lifecycle_$_widgetName');
    super.dispose();
  }

  /// Override this instead of build()
  Widget buildWidget(BuildContext context);
}