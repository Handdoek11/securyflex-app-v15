import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Performance benchmark utilities for SecuryFlex Team Management
/// Provides comprehensive performance measurement and analysis tools
class PerformanceBenchmarks {
  static final PerformanceBenchmarks _instance = PerformanceBenchmarks._internal();
  factory PerformanceBenchmarks() => _instance;
  PerformanceBenchmarks._internal();

  final Map<String, List<int>> _measurements = {};
  final Map<String, DateTime> _startTimes = {};
  final List<PerformanceReport> _reports = [];

  /// Performance thresholds for SecuryFlex
  static const Map<String, int> thresholds = {
    'app_startup': 2000,           // 2 seconds
    'navigation': 500,             // 500ms
    'tab_switch': 300,             // 300ms
    'team_load': 2000,             // 2 seconds
    'data_refresh': 1000,          // 1 second
    'search_response': 500,        // 500ms
    'emergency_alert': 100,        // 100ms (critical)
  };

  /// Start measuring performance for a specific operation
  void startMeasurement(String operationName) {
    _startTimes[operationName] = DateTime.now();
    if (kDebugMode) {
      debugPrint('📊 Started measuring: $operationName');
    }
  }

  /// Stop measuring and record the result
  int stopMeasurement(String operationName) {
    final startTime = _startTimes[operationName];
    if (startTime == null) {
      throw ArgumentError('No start time found for operation: $operationName');
    }

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _measurements.putIfAbsent(operationName, () => []).add(duration);
    _startTimes.remove(operationName);

    final threshold = thresholds[operationName] ?? 1000;
    final status = duration <= threshold ? '✅' : '⚠️';
    
    if (kDebugMode) {
      debugPrint('$status $operationName: ${duration}ms (threshold: ${threshold}ms)');
    }

    return duration;
  }

  /// Measure a specific operation
  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startMeasurement(operationName);
    try {
      final result = await operation();
      stopMeasurement(operationName);
      return result;
    } catch (e) {
      stopMeasurement(operationName);
      rethrow;
    }
  }

  /// Measure a synchronous operation
  T measureSync<T>(
    String operationName,
    T Function() operation,
  ) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = operation();
      stopwatch.stop();
      
      final duration = stopwatch.elapsedMilliseconds;
      _measurements.putIfAbsent(operationName, () => []).add(duration);
      
      final threshold = thresholds[operationName] ?? 1000;
      final status = duration <= threshold ? '✅' : '⚠️';
      
      if (kDebugMode) {
        debugPrint('$status $operationName: ${duration}ms (threshold: ${threshold}ms)');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      rethrow;
    }
  }

  /// Get performance statistics for an operation
  PerformanceStats getStats(String operationName) {
    final measurements = _measurements[operationName] ?? [];
    if (measurements.isEmpty) {
      return PerformanceStats.empty(operationName);
    }

    final sorted = List<int>.from(measurements)..sort();
    final average = measurements.reduce((a, b) => a + b) / measurements.length;
    final median = sorted.length % 2 == 0
        ? (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2
        : sorted[sorted.length ~/ 2].toDouble();

    return PerformanceStats(
      operationName: operationName,
      count: measurements.length,
      average: average,
      median: median,
      min: sorted.first,
      max: sorted.last,
      p95: sorted[(sorted.length * 0.95).floor()],
      p99: sorted[(sorted.length * 0.99).floor()],
      threshold: thresholds[operationName] ?? 1000,
    );
  }

  /// Get all performance statistics
  Map<String, PerformanceStats> getAllStats() {
    final stats = <String, PerformanceStats>{};
    for (final operation in _measurements.keys) {
      stats[operation] = getStats(operation);
    }
    return stats;
  }

  /// Generate a comprehensive performance report
  PerformanceReport generateReport() {
    final stats = getAllStats();
    final report = PerformanceReport(
      timestamp: DateTime.now(),
      stats: stats,
      overallScore: _calculateOverallScore(stats),
      recommendations: _generateRecommendations(stats),
    );
    
    _reports.add(report);
    return report;
  }

  /// Calculate overall performance score (0-100)
  double _calculateOverallScore(Map<String, PerformanceStats> stats) {
    if (stats.isEmpty) return 0.0;

    double totalScore = 0.0;
    int weightedCount = 0;

    for (final stat in stats.values) {
      final weight = _getOperationWeight(stat.operationName);
      final score = stat.average <= stat.threshold ? 100.0 : 
                   math.max(0.0, 100.0 - ((stat.average - stat.threshold) / stat.threshold * 100));
      
      totalScore += score * weight;
      weightedCount += weight;
    }

    return weightedCount > 0 ? totalScore / weightedCount : 0.0;
  }

  /// Get operation weight for scoring (higher = more important)
  int _getOperationWeight(String operationName) {
    switch (operationName) {
      case 'emergency_alert': return 10; // Critical
      case 'app_startup': return 8;      // Very important
      case 'team_load': return 7;        // Important
      case 'navigation': return 6;       // Important
      case 'tab_switch': return 5;       // Moderate
      case 'data_refresh': return 4;     // Moderate
      case 'search_response': return 3;  // Less critical
      default: return 1;                 // Default
    }
  }

  /// Generate performance recommendations
  List<String> _generateRecommendations(Map<String, PerformanceStats> stats) {
    final recommendations = <String>[];

    for (final stat in stats.values) {
      if (stat.average > stat.threshold) {
        final severity = stat.average > stat.threshold * 2 ? 'Critical' : 'Warning';
        recommendations.add(
          '$severity: ${stat.operationName} averaging ${stat.average.toStringAsFixed(1)}ms '
          '(${((stat.average / stat.threshold - 1) * 100).toStringAsFixed(1)}% over threshold)'
        );
      }

      if (stat.p95 > stat.threshold * 1.5) {
        recommendations.add(
          'Optimization needed: ${stat.operationName} 95th percentile is ${stat.p95}ms'
        );
      }

      if (stat.max > stat.threshold * 3) {
        recommendations.add(
          'Investigate outliers: ${stat.operationName} max time is ${stat.max}ms'
        );
      }
    }

    // General recommendations
    if (recommendations.isEmpty) {
      recommendations.add('✅ All operations are performing within acceptable thresholds');
    } else {
      recommendations.insert(0, 'Performance improvements needed:');
    }

    return recommendations;
  }

  /// Memory usage monitoring
  Future<MemoryUsage> measureMemoryUsage() async {
    // This would require platform-specific implementation
    // For now, return mock data
    return MemoryUsage(
      rss: 45.0 + math.Random().nextDouble() * 10, // Resident Set Size
      heapUsed: 25.0 + math.Random().nextDouble() * 5,
      heapTotal: 50.0,
      external: 5.0,
    );
  }

  /// Network performance monitoring
  Future<NetworkStats> measureNetworkPerformance(String endpoint) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Simulate network request
      await Future.delayed(Duration(milliseconds: 50 + math.Random().nextInt(200)));
      stopwatch.stop();
      
      return NetworkStats(
        endpoint: endpoint,
        responseTime: stopwatch.elapsedMilliseconds,
        success: true,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      stopwatch.stop();
      return NetworkStats(
        endpoint: endpoint,
        responseTime: stopwatch.elapsedMilliseconds,
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Clear all measurements
  void clear() {
    _measurements.clear();
    _startTimes.clear();
    if (kDebugMode) {
      debugPrint('📊 Performance measurements cleared');
    }
  }

  /// Export performance data as CSV
  String exportToCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Operation,Count,Average,Median,Min,Max,P95,P99,Threshold,Status');
    
    for (final stat in getAllStats().values) {
      final status = stat.average <= stat.threshold ? 'PASS' : 'FAIL';
      buffer.writeln(
        '${stat.operationName},${stat.count},${stat.average.toStringAsFixed(1)},'
        '${stat.median.toStringAsFixed(1)},${stat.min},${stat.max},'
        '${stat.p95},${stat.p99},${stat.threshold},$status'
      );
    }
    
    return buffer.toString();
  }

  /// Print performance summary
  void printSummary() {
    final stats = getAllStats();
    if (stats.isEmpty) {
      debugPrint('📊 No performance data available');
      return;
    }

    debugPrint('\n📊 PERFORMANCE SUMMARY');
    debugPrint('=' * 50);
    
    for (final stat in stats.values) {
      final status = stat.average <= stat.threshold ? '✅' : '❌';
      debugPrint('$status ${stat.operationName.padRight(20)} '
            'Avg: ${stat.average.toStringAsFixed(1)}ms '
            '(${stat.threshold}ms threshold)');
    }
    
    final report = generateReport();
    debugPrint('\n🎯 Overall Score: ${report.overallScore.toStringAsFixed(1)}/100');
    
    if (report.recommendations.isNotEmpty) {
      debugPrint('\n💡 Recommendations:');
      for (final rec in report.recommendations) {
        debugPrint('   • $rec');
      }
    }
    
    debugPrint('=' * 50);
  }
}

/// Performance statistics for a specific operation
class PerformanceStats {
  final String operationName;
  final int count;
  final double average;
  final double median;
  final int min;
  final int max;
  final int p95;
  final int p99;
  final int threshold;

  const PerformanceStats({
    required this.operationName,
    required this.count,
    required this.average,
    required this.median,
    required this.min,
    required this.max,
    required this.p95,
    required this.p99,
    required this.threshold,
  });

  factory PerformanceStats.empty(String operationName) {
    return PerformanceStats(
      operationName: operationName,
      count: 0,
      average: 0.0,
      median: 0.0,
      min: 0,
      max: 0,
      p95: 0,
      p99: 0,
      threshold: PerformanceBenchmarks.thresholds[operationName] ?? 1000,
    );
  }

  bool get isWithinThreshold => average <= threshold;
  double get performanceRatio => average / threshold;
}

/// Comprehensive performance report
class PerformanceReport {
  final DateTime timestamp;
  final Map<String, PerformanceStats> stats;
  final double overallScore;
  final List<String> recommendations;

  const PerformanceReport({
    required this.timestamp,
    required this.stats,
    required this.overallScore,
    required this.recommendations,
  });
}

/// Memory usage statistics
class MemoryUsage {
  final double rss;        // Resident Set Size (MB)
  final double heapUsed;   // Heap Used (MB)
  final double heapTotal;  // Heap Total (MB)
  final double external;   // External Memory (MB)

  const MemoryUsage({
    required this.rss,
    required this.heapUsed,
    required this.heapTotal,
    required this.external,
  });

  double get totalUsage => rss + external;
  double get heapUtilization => heapUsed / heapTotal;
}

/// Network performance statistics
class NetworkStats {
  final String endpoint;
  final int responseTime;
  final bool success;
  final String? error;
  final DateTime timestamp;

  const NetworkStats({
    required this.endpoint,
    required this.responseTime,
    required this.success,
    this.error,
    required this.timestamp,
  });
}

/// Performance test utilities
class PerformanceTestUtils {
  /// Run a performance test suite
  static Future<PerformanceReport> runTestSuite(
    Map<String, Future<void> Function()> tests,
  ) async {
    final benchmarks = PerformanceBenchmarks();
    benchmarks.clear();

    debugPrint('🚀 Starting performance test suite...');
    
    for (final entry in tests.entries) {
      final testName = entry.key;
      final testFunction = entry.value;
      
      debugPrint('   Running: $testName');
      
      try {
        await benchmarks.measureOperation(testName, testFunction);
      } catch (e) {
        debugPrint('   ❌ Failed: $testName - $e');
      }
    }

    final report = benchmarks.generateReport();
    benchmarks.printSummary();
    
    return report;
  }

  /// Validate performance against thresholds
  static bool validatePerformance(PerformanceReport report, {double minScore = 80.0}) {
    if (report.overallScore < minScore) {
      debugPrint('❌ Performance validation failed: ${report.overallScore.toStringAsFixed(1)}/100 (minimum: $minScore)');
      return false;
    }

    debugPrint('✅ Performance validation passed: ${report.overallScore.toStringAsFixed(1)}/100');
    return true;
  }
}
