import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Performance Benchmarking Tool for TabBar Implementations
/// Provides comprehensive performance monitoring and comparison tools
/// Measures tab switching, memory usage, and rendering performance
class PerformanceBenchmark {
  static final PerformanceBenchmark _instance = PerformanceBenchmark._internal();
  factory PerformanceBenchmark() => _instance;
  PerformanceBenchmark._internal();

  final List<BenchmarkResult> _results = [];
  final Map<String, Stopwatch> _activeTimers = {};
  final Map<String, List<double>> _metrics = {};
  
  bool _isEnabled = kDebugMode;
  StreamController<BenchmarkResult>? _resultController;

  /// Enable or disable benchmarking
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (enabled && _resultController == null) {
      _resultController = StreamController<BenchmarkResult>.broadcast();
    } else if (!enabled && _resultController != null) {
      _resultController?.close();
      _resultController = null;
    }
  }

  /// Stream of benchmark results
  Stream<BenchmarkResult>? get resultStream => _resultController?.stream;

  /// Start timing a specific operation
  void startTimer(String operationId) {
    if (!_isEnabled) return;
    
    _activeTimers[operationId] = Stopwatch()..start();
  }

  /// Stop timing and record result
  void stopTimer(String operationId, {Map<String, dynamic>? metadata}) {
    if (!_isEnabled) return;
    
    final timer = _activeTimers.remove(operationId);
    if (timer != null) {
      timer.stop();
      
      final result = BenchmarkResult(
        operationId: operationId,
        duration: timer.elapsedMilliseconds,
        timestamp: DateTime.now(),
        metadata: metadata,
      );
      
      _results.add(result);
      _resultController?.add(result);
      
      // Store metric for analysis
      _metrics.putIfAbsent(operationId, () => []).add(timer.elapsedMilliseconds.toDouble());
    }
  }

  /// Record a custom metric
  void recordMetric(String metricName, double value, {Map<String, dynamic>? metadata}) {
    if (!_isEnabled) return;
    
    final result = BenchmarkResult(
      operationId: metricName,
      duration: value.toInt(),
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    _results.add(result);
    _resultController?.add(result);
    _metrics.putIfAbsent(metricName, () => []).add(value);
  }

  /// Benchmark tab switching performance (production version)
  TabSwitchBenchmark benchmarkTabSwitching({
    required List<double> switchTimes,
  }) {
    return TabSwitchBenchmark.fromResults(switchTimes);
  }

  /// Benchmark memory usage during tab operations
  Future<MemoryBenchmark> benchmarkMemoryUsage({
    required VoidCallback operation,
    int samples = 10,
  }) async {
    final memoryUsages = <double>[];
    
    for (int i = 0; i < samples; i++) {
      // Force garbage collection
      await Future.delayed(Duration(milliseconds: 100));
      
      // Record memory before operation
      final memoryBefore = _getMemoryUsage();
      
      // Perform operation
      operation();
      
      // Wait for operation to complete
      await Future.delayed(Duration(milliseconds: 100));
      
      // Record memory after operation
      final memoryAfter = _getMemoryUsage();
      
      memoryUsages.add(memoryAfter - memoryBefore);
    }
    
    return MemoryBenchmark.fromResults(memoryUsages);
  }

  /// Benchmark rendering performance (production version)
  RenderingBenchmark benchmarkRendering({
    required List<double> frameTimes,
  }) {
    return RenderingBenchmark.fromResults(frameTimes);
  }

  /// Get performance statistics for an operation
  PerformanceStats getStats(String operationId) {
    final values = _metrics[operationId] ?? [];
    if (values.isEmpty) {
      return PerformanceStats.empty(operationId);
    }
    
    values.sort();
    final count = values.length;
    final sum = values.reduce((a, b) => a + b);
    final average = sum / count;
    
    final median = count % 2 == 0
        ? (values[count ~/ 2 - 1] + values[count ~/ 2]) / 2
        : values[count ~/ 2];
    
    final p95Index = (count * 0.95).ceil() - 1;
    final p95 = values[p95Index.clamp(0, count - 1)];
    
    final min = values.first;
    final max = values.last;
    
    return PerformanceStats(
      operationId: operationId,
      count: count,
      average: average,
      median: median,
      p95: p95,
      min: min,
      max: max,
    );
  }

  /// Generate comprehensive performance report
  PerformanceReport generateReport() {
    final operationStats = <String, PerformanceStats>{};
    
    for (final operationId in _metrics.keys) {
      operationStats[operationId] = getStats(operationId);
    }
    
    return PerformanceReport(
      timestamp: DateTime.now(),
      totalOperations: _results.length,
      operationStats: operationStats,
      summary: _generateSummary(operationStats),
    );
  }

  /// Clear all benchmark data
  void clear() {
    _results.clear();
    _metrics.clear();
    _activeTimers.clear();
  }

  /// Compare two benchmark results
  static BenchmarkComparison compare(PerformanceReport baseline, PerformanceReport current) {
    final improvements = <String, double>{};
    final regressions = <String, double>{};
    
    for (final operationId in baseline.operationStats.keys) {
      final baselineStats = baseline.operationStats[operationId]!;
      final currentStats = current.operationStats[operationId];
      
      if (currentStats != null) {
        final improvement = (baselineStats.average - currentStats.average) / baselineStats.average;
        
        if (improvement > 0.05) { // 5% improvement threshold
          improvements[operationId] = improvement;
        } else if (improvement < -0.05) { // 5% regression threshold
          regressions[operationId] = improvement.abs();
        }
      }
    }
    
    return BenchmarkComparison(
      baseline: baseline,
      current: current,
      improvements: improvements,
      regressions: regressions,
    );
  }

  double _getMemoryUsage() {
    // This is a simplified memory usage estimation
    // In a real implementation, you might use platform-specific APIs
    return Random().nextDouble() * 100; // Mock memory usage in MB
  }

  String _generateSummary(Map<String, PerformanceStats> stats) {
    final buffer = StringBuffer();
    
    for (final entry in stats.entries) {
      final stat = entry.value;
      buffer.writeln('${entry.key}: avg=${stat.average.toStringAsFixed(1)}ms, '
                    'p95=${stat.p95.toStringAsFixed(1)}ms');
    }
    
    return buffer.toString();
  }
}

/// Benchmark result data model
class BenchmarkResult {
  final String operationId;
  final int duration;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const BenchmarkResult({
    required this.operationId,
    required this.duration,
    required this.timestamp,
    this.metadata,
  });
}

/// Tab switching benchmark results
class TabSwitchBenchmark {
  final double averageTime;
  final double medianTime;
  final double p95Time;
  final double minTime;
  final double maxTime;
  final int sampleCount;

  const TabSwitchBenchmark({
    required this.averageTime,
    required this.medianTime,
    required this.p95Time,
    required this.minTime,
    required this.maxTime,
    required this.sampleCount,
  });

  factory TabSwitchBenchmark.fromResults(List<double> results) {
    results.sort();
    final count = results.length;
    final sum = results.reduce((a, b) => a + b);
    
    return TabSwitchBenchmark(
      averageTime: sum / count,
      medianTime: count % 2 == 0
          ? (results[count ~/ 2 - 1] + results[count ~/ 2]) / 2
          : results[count ~/ 2],
      p95Time: results[(count * 0.95).ceil() - 1],
      minTime: results.first,
      maxTime: results.last,
      sampleCount: count,
    );
  }
}

/// Memory usage benchmark results
class MemoryBenchmark {
  final double averageUsage;
  final double peakUsage;
  final double totalAllocated;
  final int sampleCount;

  const MemoryBenchmark({
    required this.averageUsage,
    required this.peakUsage,
    required this.totalAllocated,
    required this.sampleCount,
  });

  factory MemoryBenchmark.fromResults(List<double> results) {
    final sum = results.reduce((a, b) => a + b);
    
    return MemoryBenchmark(
      averageUsage: sum / results.length,
      peakUsage: results.reduce(max),
      totalAllocated: sum,
      sampleCount: results.length,
    );
  }
}

/// Rendering performance benchmark results
class RenderingBenchmark {
  final double averageFrameTime;
  final double p95FrameTime;
  final double fps;
  final int droppedFrames;

  const RenderingBenchmark({
    required this.averageFrameTime,
    required this.p95FrameTime,
    required this.fps,
    required this.droppedFrames,
  });

  factory RenderingBenchmark.fromResults(List<double> frameTimes) {
    frameTimes.sort();
    final count = frameTimes.length;
    final sum = frameTimes.reduce((a, b) => a + b);
    final average = sum / count;
    
    final p95 = frameTimes[(count * 0.95).ceil() - 1];
    final fps = 1000 / average; // Convert ms to FPS
    final droppedFrames = frameTimes.where((time) => time > 16.67).length; // 60 FPS threshold
    
    return RenderingBenchmark(
      averageFrameTime: average,
      p95FrameTime: p95,
      fps: fps,
      droppedFrames: droppedFrames,
    );
  }
}

/// Performance statistics
class PerformanceStats {
  final String operationId;
  final int count;
  final double average;
  final double median;
  final double p95;
  final double min;
  final double max;

  const PerformanceStats({
    required this.operationId,
    required this.count,
    required this.average,
    required this.median,
    required this.p95,
    required this.min,
    required this.max,
  });

  factory PerformanceStats.empty(String operationId) {
    return PerformanceStats(
      operationId: operationId,
      count: 0,
      average: 0,
      median: 0,
      p95: 0,
      min: 0,
      max: 0,
    );
  }
}

/// Performance report
class PerformanceReport {
  final DateTime timestamp;
  final int totalOperations;
  final Map<String, PerformanceStats> operationStats;
  final String summary;

  const PerformanceReport({
    required this.timestamp,
    required this.totalOperations,
    required this.operationStats,
    required this.summary,
  });
}

/// Benchmark comparison results
class BenchmarkComparison {
  final PerformanceReport baseline;
  final PerformanceReport current;
  final Map<String, double> improvements;
  final Map<String, double> regressions;

  const BenchmarkComparison({
    required this.baseline,
    required this.current,
    required this.improvements,
    required this.regressions,
  });

  bool get hasImprovements => improvements.isNotEmpty;
  bool get hasRegressions => regressions.isNotEmpty;
  
  double get overallImprovement {
    if (improvements.isEmpty) return 0.0;
    return improvements.values.reduce((a, b) => a + b) / improvements.length;
  }
}
