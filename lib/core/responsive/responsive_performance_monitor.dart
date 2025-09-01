import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'responsive_provider.dart';

/// Performance monitoring for responsive system
class ResponsivePerformanceMonitor {
  static final ResponsivePerformanceMonitor _instance = ResponsivePerformanceMonitor._internal();
  static ResponsivePerformanceMonitor get instance => _instance;
  ResponsivePerformanceMonitor._internal();

  static const Duration _defaultMeasurementWindow = Duration(seconds: 10);
  
  // Performance metrics
  int _mediaQueryCallsSaved = 0;
  int _widgetRebuildsPrevented = 0;
  Duration _totalTimeSaved = Duration.zero;
  DateTime _startTime = DateTime.now();
  
  // Active monitoring
  bool _isMonitoring = false;
  
  /// Initialize performance monitoring
  void initialize() {
    if (!kDebugMode) return; // Only in debug mode
    
    _isMonitoring = true;
    _startTime = DateTime.now();
    
    debugPrint('🚀 ResponsivePerformanceMonitor initialized');
  }

  /// Record when a MediaQuery call was avoided due to caching
  void recordMediaQueryCallSaved() {
    if (!_isMonitoring) return;
    _mediaQueryCallsSaved++;
  }

  /// Record when widget rebuild was prevented by debouncing
  void recordWidgetRebuildPrevented() {
    if (!_isMonitoring) return;
    _widgetRebuildsPrevented++;
  }

  /// Record time saved by responsive optimizations
  void recordTimeSaved(Duration timeSaved) {
    if (!_isMonitoring) return;
    _totalTimeSaved += timeSaved;
  }

  /// Get performance report
  ResponsivePerformanceReport getReport() {
    final runningTime = DateTime.now().difference(_startTime);
    
    return ResponsivePerformanceReport(
      runningTime: runningTime,
      mediaQueryCallsSaved: _mediaQueryCallsSaved,
      widgetRebuildsPrevented: _widgetRebuildsPrevented,
      totalTimeSaved: _totalTimeSaved,
    );
  }

  /// Print performance summary (debug only)
  void printPerformanceSummary() {
    if (!kDebugMode || !_isMonitoring) return;
    
    final report = getReport();
    final efficiency = report.calculateEfficiencyGain();
    
    debugPrint('');
    debugPrint('🎯 === RESPONSIVE PERFORMANCE SUMMARY ===');
    debugPrint('⏱️ Running time: ${report.runningTime.inSeconds}s');
    debugPrint('💾 MediaQuery calls saved: ${report.mediaQueryCallsSaved}');
    debugPrint('🚫 Widget rebuilds prevented: ${report.widgetRebuildsPrevented}');
    debugPrint('⚡ Total time saved: ${report.totalTimeSaved.inMilliseconds}ms');
    debugPrint('📈 Efficiency gain: ${efficiency.toStringAsFixed(1)}%');
    debugPrint('=========================================');
    debugPrint('');
  }

  /// Reset performance counters
  void reset() {
    _mediaQueryCallsSaved = 0;
    _widgetRebuildsPrevented = 0;
    _totalTimeSaved = Duration.zero;
    _startTime = DateTime.now();
  }
}

/// Performance report data
class ResponsivePerformanceReport {
  final Duration runningTime;
  final int mediaQueryCallsSaved;
  final int widgetRebuildsPrevented;
  final Duration totalTimeSaved;

  const ResponsivePerformanceReport({
    required this.runningTime,
    required this.mediaQueryCallsSaved,
    required this.widgetRebuildsPrevented,
    required this.totalTimeSaved,
  });

  /// Calculate efficiency gain percentage
  double calculateEfficiencyGain() {
    if (runningTime.inMilliseconds <= 0) return 0.0;
    
    // Estimate time that would have been spent without optimizations
    final estimatedTimeWithoutOptimizations = 
        (mediaQueryCallsSaved * 30) + // ~30ms per MediaQuery call
        (widgetRebuildsPrevented * 50); // ~50ms per prevented rebuild
    
    if (estimatedTimeWithoutOptimizations <= 0) return 0.0;
    
    return (totalTimeSaved.inMilliseconds / estimatedTimeWithoutOptimizations) * 100;
  }

  /// Get formatted performance summary
  String getFormattedSummary() {
    return '''
Responsive Performance Report:
• Running Time: ${runningTime.inSeconds}s
• MediaQuery Calls Saved: $mediaQueryCallsSaved
• Widget Rebuilds Prevented: $widgetRebuildsPrevented
• Total Time Saved: ${totalTimeSaved.inMilliseconds}ms
• Efficiency Gain: ${calculateEfficiencyGain().toStringAsFixed(1)}%
''';
  }
}

/// Widget to display responsive performance stats (debug only)
class ResponsivePerformanceOverlay extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const ResponsivePerformanceOverlay({
    super.key,
    required this.child,
    this.showOverlay = true,
  });

  @override
  State<ResponsivePerformanceOverlay> createState() => _ResponsivePerformanceOverlayState();
}

class _ResponsivePerformanceOverlayState extends State<ResponsivePerformanceOverlay> {
  ResponsivePerformanceReport? _lastReport;

  @override
  void initState() {
    super.initState();
    if (kDebugMode && widget.showOverlay) {
      // Update performance stats every 2 seconds
      _startPeriodicUpdates();
    }
  }

  void _startPeriodicUpdates() {
    if (!mounted) return;
    
    setState(() {
      _lastReport = ResponsivePerformanceMonitor.instance.getReport();
    });
    
    Future.delayed(const Duration(seconds: 2), _startPeriodicUpdates);
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !widget.showOverlay || _lastReport == null) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          left: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🚀 Responsive Performance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MediaQuery saved: ${_lastReport!.mediaQueryCallsSaved}',
                  style: TextStyle(color: Colors.green, fontSize: 10),
                ),
                Text(
                  'Rebuilds prevented: ${_lastReport!.widgetRebuildsPrevented}',
                  style: TextStyle(color: Colors.blue, fontSize: 10),
                ),
                Text(
                  'Time saved: ${_lastReport!.totalTimeSaved.inMilliseconds}ms',
                  style: TextStyle(color: Colors.orange, fontSize: 10),
                ),
                Text(
                  'Efficiency: ${_lastReport!.calculateEfficiencyGain().toStringAsFixed(1)}%',
                  style: TextStyle(color: Colors.yellow, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}