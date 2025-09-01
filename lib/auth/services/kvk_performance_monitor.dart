import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Performance monitoring and analytics for KvK validation service
/// Tracks metrics, identifies bottlenecks, and provides optimization insights
class KvKPerformanceMonitor {
  // Performance metrics storage
  static final Queue<PerformanceMetric> _metrics = Queue<PerformanceMetric>();
  static const int _maxMetricsHistory = 1000;
  
  // Real-time monitoring
  static final Map<String, Stopwatch> _activeRequests = {};
  static final List<StreamController<PerformanceAlert>> _alertStreams = [];
  
  // Thresholds for performance alerts
  static const Duration _slowRequestThreshold = Duration(milliseconds: 2000);
  static const Duration _verySlowRequestThreshold = Duration(milliseconds: 5000);
  static const int _errorRateThreshold = 10; // % over 5 minutes
  static const int _cacheHitRateThreshold = 70; // % minimum expected
  
  /// Start monitoring a KvK validation request
  static String startRequest(String kvkNumber, String userId, String source) {
    final requestId = '${DateTime.now().millisecondsSinceEpoch}_${kvkNumber}_$userId';
    _activeRequests[requestId] = Stopwatch()..start();
    
    debugPrint('📊 Started monitoring request $requestId');
    return requestId;
  }
  
  /// Complete monitoring a KvK validation request
  static void completeRequest(
    String requestId, 
    bool success, 
    String? errorCode,
    Map<String, dynamic>? additionalData,
  ) {
    final stopwatch = _activeRequests.remove(requestId);
    if (stopwatch == null) return;
    
    stopwatch.stop();
    final duration = stopwatch.elapsed;
    
    final metric = PerformanceMetric(
      requestId: requestId,
      timestamp: DateTime.now(),
      duration: duration,
      success: success,
      errorCode: errorCode,
      additionalData: additionalData ?? {},
    );
    
    _addMetric(metric);
    _checkAlerts(metric);
    
    debugPrint('📊 Completed request $requestId in ${duration.inMilliseconds}ms (${success ? 'SUCCESS' : 'FAILED'})');
  }
  
  /// Add a performance metric to the history
  static void _addMetric(PerformanceMetric metric) {
    _metrics.add(metric);
    
    // Maintain maximum history size
    while (_metrics.length > _maxMetricsHistory) {
      _metrics.removeFirst();
    }
  }
  
  /// Check for performance alerts and notify listeners
  static void _checkAlerts(PerformanceMetric metric) {
    final alerts = <PerformanceAlert>[];
    
    // Check for slow request
    if (metric.duration >= _verySlowRequestThreshold) {
      alerts.add(PerformanceAlert(
        type: AlertType.verySlowRequest,
        severity: AlertSeverity.high,
        message: 'Zeer langzame KvK validatie: ${metric.duration.inMilliseconds}ms',
        metric: metric,
        timestamp: DateTime.now(),
      ));
    } else if (metric.duration >= _slowRequestThreshold) {
      alerts.add(PerformanceAlert(
        type: AlertType.slowRequest,
        severity: AlertSeverity.medium,
        message: 'Langzame KvK validatie: ${metric.duration.inMilliseconds}ms',
        metric: metric,
        timestamp: DateTime.now(),
      ));
    }
    
    // Check for errors
    if (!metric.success) {
      alerts.add(PerformanceAlert(
        type: AlertType.requestError,
        severity: AlertSeverity.medium,
        message: 'KvK validatie fout: ${metric.errorCode}',
        metric: metric,
        timestamp: DateTime.now(),
      ));
    }
    
    // Check system-wide alerts
    final systemAlerts = _checkSystemAlerts();
    alerts.addAll(systemAlerts);
    
    // Notify all listeners
    for (final alert in alerts) {
      for (final stream in _alertStreams) {
        if (!stream.isClosed) {
          stream.add(alert);
        }
      }
    }
  }
  
  /// Check for system-wide performance alerts
  static List<PerformanceAlert> _checkSystemAlerts() {
    final alerts = <PerformanceAlert>[];
    final now = DateTime.now();
    final recentMetrics = _getMetricsInTimeRange(
      now.subtract(const Duration(minutes: 5)),
      now,
    );
    
    if (recentMetrics.isEmpty) return alerts;
    
    // Check error rate
    final errorCount = recentMetrics.where((m) => !m.success).length;
    final errorRate = (errorCount / recentMetrics.length * 100).round();
    
    if (errorRate >= _errorRateThreshold) {
      alerts.add(PerformanceAlert(
        type: AlertType.highErrorRate,
        severity: AlertSeverity.high,
        message: 'Hoge foutpercentage: $errorRate% in de laatste 5 minuten',
        timestamp: now,
        additionalData: {
          'errorRate': errorRate,
          'totalRequests': recentMetrics.length,
          'errorCount': errorCount,
        },
      ));
    }
    
    // Check cache hit rate (if data available)
    final cacheHits = recentMetrics
        .where((m) => m.additionalData['fromCache'] == true)
        .length;
    if (recentMetrics.length > 10) { // Only check if we have enough data
      final cacheHitRate = (cacheHits / recentMetrics.length * 100).round();
      if (cacheHitRate < _cacheHitRateThreshold) {
        alerts.add(PerformanceAlert(
          type: AlertType.lowCacheHitRate,
          severity: AlertSeverity.medium,
          message: 'Lage cache hit rate: $cacheHitRate%',
          timestamp: now,
          additionalData: {
            'cacheHitRate': cacheHitRate,
            'totalRequests': recentMetrics.length,
            'cacheHits': cacheHits,
          },
        ));
      }
    }
    
    return alerts;
  }
  
  /// Get performance summary for a given time period
  static PerformanceSummary getPerformanceSummary({Duration? period}) {
    final now = DateTime.now();
    final startTime = period != null ? now.subtract(period) : null;
    
    final relevantMetrics = startTime != null 
        ? _getMetricsInTimeRange(startTime, now)
        : _metrics.toList();
    
    if (relevantMetrics.isEmpty) {
      return PerformanceSummary.empty(period);
    }
    
    // Calculate basic statistics
    final totalRequests = relevantMetrics.length;
    final successfulRequests = relevantMetrics.where((m) => m.success).length;
    final failedRequests = totalRequests - successfulRequests;
    
    final durations = relevantMetrics.map((m) => m.duration).toList();
    durations.sort((a, b) => a.compareTo(b));
    
    final avgDuration = Duration(
      milliseconds: durations.isEmpty 
        ? 0 
        : durations.map((d) => d.inMilliseconds).reduce((a, b) => a + b) ~/ durations.length
    );
    
    final medianDuration = durations.isEmpty 
        ? Duration.zero 
        : durations[durations.length ~/ 2];
    
    final p95Duration = durations.isEmpty 
        ? Duration.zero 
        : durations[(durations.length * 0.95).round() - 1];
    
    final p99Duration = durations.isEmpty 
        ? Duration.zero 
        : durations[(durations.length * 0.99).round() - 1];
    
    // Calculate error breakdown
    final errorsByCode = <String, int>{};
    for (final metric in relevantMetrics.where((m) => !m.success)) {
      final errorCode = metric.errorCode ?? 'unknown';
      errorsByCode[errorCode] = (errorsByCode[errorCode] ?? 0) + 1;
    }
    
    // Calculate source breakdown
    final requestsBySource = <String, int>{};
    for (final metric in relevantMetrics) {
      final source = metric.additionalData['source']?.toString() ?? 'unknown';
      requestsBySource[source] = (requestsBySource[source] ?? 0) + 1;
    }
    
    // Calculate cache statistics
    final cacheHits = relevantMetrics
        .where((m) => m.additionalData['fromCache'] == true)
        .length;
    final cacheHitRate = totalRequests > 0 ? cacheHits / totalRequests : 0.0;
    
    return PerformanceSummary(
      period: period,
      totalRequests: totalRequests,
      successfulRequests: successfulRequests,
      failedRequests: failedRequests,
      successRate: totalRequests > 0 ? successfulRequests / totalRequests : 0.0,
      avgDuration: avgDuration,
      medianDuration: medianDuration,
      p95Duration: p95Duration,
      p99Duration: p99Duration,
      minDuration: durations.isEmpty ? Duration.zero : durations.first,
      maxDuration: durations.isEmpty ? Duration.zero : durations.last,
      errorsByCode: errorsByCode,
      requestsBySource: requestsBySource,
      cacheHitRate: cacheHitRate,
      cacheHits: cacheHits,
    );
  }
  
  /// Get metrics within a time range
  static List<PerformanceMetric> _getMetricsInTimeRange(DateTime start, DateTime end) {
    return _metrics
        .where((metric) => 
          metric.timestamp.isAfter(start) && 
          metric.timestamp.isBefore(end))
        .toList();
  }
  
  /// Get real-time performance stream
  static Stream<PerformanceAlert> getAlertStream() {
    final controller = StreamController<PerformanceAlert>.broadcast();
    _alertStreams.add(controller);
    
    // Clean up closed streams periodically
    _alertStreams.removeWhere((stream) => stream.isClosed);
    
    return controller.stream;
  }
  
  /// Get comprehensive performance diagnostics
  static Map<String, dynamic> getPerformanceDiagnostics() {
    final now = DateTime.now();
    final last5Minutes = getPerformanceSummary(period: const Duration(minutes: 5));
    final lastHour = getPerformanceSummary(period: const Duration(hours: 1));
    final lastDay = getPerformanceSummary(period: const Duration(days: 1));
    
    // Identify performance bottlenecks
    final bottlenecks = <String>[];
    
    if (last5Minutes.avgDuration > _slowRequestThreshold) {
      bottlenecks.add('Hoge gemiddelde response tijd');
    }
    
    if (last5Minutes.successRate < 0.95) {
      bottlenecks.add('Lage success rate');
    }
    
    if (last5Minutes.cacheHitRate < 0.7) {
      bottlenecks.add('Lage cache hit rate');
    }
    
    // Performance recommendations
    final recommendations = <String>[];
    
    if (last5Minutes.cacheHitRate < 0.7) {
      recommendations.add('Verbeter cache strategie');
    }
    
    if (last5Minutes.p95Duration > _slowRequestThreshold) {
      recommendations.add('Optimaliseer langzame queries');
    }
    
    if (last5Minutes.errorsByCode.containsKey('timeout')) {
      recommendations.add('Verhoog timeout instellingen');
    }
    
    if (last5Minutes.errorsByCode.containsKey('rate-limited')) {
      recommendations.add('Optimaliseer rate limiting configuratie');
    }
    
    return {
      'timestamp': now.toIso8601String(),
      'activeRequests': _activeRequests.length,
      'metricsCount': _metrics.length,
      'summaries': {
        'last5Minutes': last5Minutes.toJson(),
        'lastHour': lastHour.toJson(),
        'lastDay': lastDay.toJson(),
      },
      'bottlenecks': bottlenecks,
      'recommendations': recommendations,
      'thresholds': {
        'slowRequest': _slowRequestThreshold.inMilliseconds,
        'verySlowRequest': _verySlowRequestThreshold.inMilliseconds,
        'errorRateThreshold': _errorRateThreshold,
        'cacheHitRateThreshold': _cacheHitRateThreshold,
      },
    };
  }
  
  /// Clear performance history
  static void clearHistory() {
    _metrics.clear();
    _activeRequests.clear();
    debugPrint('📊 Performance history cleared');
  }
  
  /// Export performance metrics for external analysis
  static List<Map<String, dynamic>> exportMetrics({Duration? period}) {
    final now = DateTime.now();
    final relevantMetrics = period != null 
        ? _getMetricsInTimeRange(now.subtract(period), now)
        : _metrics.toList();
    
    return relevantMetrics.map((metric) => metric.toJson()).toList();
  }
  
  /// Get performance trends over time
  static Map<String, List<double>> getPerformanceTrends({
    Duration? period,
    Duration interval = const Duration(minutes: 5),
  }) {
    final now = DateTime.now();
    final startTime = period != null ? now.subtract(period) : 
        (_metrics.isEmpty ? now : _metrics.first.timestamp);
    
    final trends = <String, List<double>>{
      'avgResponseTime': [],
      'successRate': [],
      'requestRate': [],
      'cacheHitRate': [],
    };
    
    var currentTime = startTime;
    while (currentTime.isBefore(now)) {
      final intervalEnd = currentTime.add(interval);
      final intervalMetrics = _getMetricsInTimeRange(currentTime, intervalEnd);
      
      if (intervalMetrics.isNotEmpty) {
        // Average response time
        final avgMs = intervalMetrics
            .map((m) => m.duration.inMilliseconds)
            .reduce((a, b) => a + b) / intervalMetrics.length;
        trends['avgResponseTime']!.add(avgMs);
        
        // Success rate
        final successRate = intervalMetrics
            .where((m) => m.success)
            .length / intervalMetrics.length;
        trends['successRate']!.add(successRate * 100);
        
        // Request rate (requests per minute)
        final requestRate = intervalMetrics.length / (interval.inMinutes > 0 ? interval.inMinutes : 1);
        trends['requestRate']!.add(requestRate);
        
        // Cache hit rate
        final cacheHits = intervalMetrics
            .where((m) => m.additionalData['fromCache'] == true)
            .length;
        final cacheHitRate = cacheHits / intervalMetrics.length;
        trends['cacheHitRate']!.add(cacheHitRate * 100);
      } else {
        // No data for this interval
        trends['avgResponseTime']!.add(0);
        trends['successRate']!.add(0);
        trends['requestRate']!.add(0);
        trends['cacheHitRate']!.add(0);
      }
      
      currentTime = intervalEnd;
    }
    
    return trends;
  }
}

/// Individual performance metric
class PerformanceMetric {
  final String requestId;
  final DateTime timestamp;
  final Duration duration;
  final bool success;
  final String? errorCode;
  final Map<String, dynamic> additionalData;

  const PerformanceMetric({
    required this.requestId,
    required this.timestamp,
    required this.duration,
    required this.success,
    this.errorCode,
    required this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'timestamp': timestamp.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'success': success,
      'errorCode': errorCode,
      'additionalData': additionalData,
    };
  }
}

/// Performance alert
class PerformanceAlert {
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;
  final PerformanceMetric? metric;
  final Map<String, dynamic> additionalData;

  const PerformanceAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.metric,
    this.additionalData = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'severity': severity.toString(),
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'metric': metric?.toJson(),
      'additionalData': additionalData,
    };
  }
}

/// Performance summary for a time period
class PerformanceSummary {
  final Duration? period;
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final double successRate;
  final Duration avgDuration;
  final Duration medianDuration;
  final Duration p95Duration;
  final Duration p99Duration;
  final Duration minDuration;
  final Duration maxDuration;
  final Map<String, int> errorsByCode;
  final Map<String, int> requestsBySource;
  final double cacheHitRate;
  final int cacheHits;

  const PerformanceSummary({
    this.period,
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.successRate,
    required this.avgDuration,
    required this.medianDuration,
    required this.p95Duration,
    required this.p99Duration,
    required this.minDuration,
    required this.maxDuration,
    required this.errorsByCode,
    required this.requestsBySource,
    required this.cacheHitRate,
    required this.cacheHits,
  });

  factory PerformanceSummary.empty(Duration? period) {
    return PerformanceSummary(
      period: period,
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      successRate: 0.0,
      avgDuration: Duration.zero,
      medianDuration: Duration.zero,
      p95Duration: Duration.zero,
      p99Duration: Duration.zero,
      minDuration: Duration.zero,
      maxDuration: Duration.zero,
      errorsByCode: {},
      requestsBySource: {},
      cacheHitRate: 0.0,
      cacheHits: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period?.inMilliseconds,
      'totalRequests': totalRequests,
      'successfulRequests': successfulRequests,
      'failedRequests': failedRequests,
      'successRate': successRate,
      'avgDurationMs': avgDuration.inMilliseconds,
      'medianDurationMs': medianDuration.inMilliseconds,
      'p95DurationMs': p95Duration.inMilliseconds,
      'p99DurationMs': p99Duration.inMilliseconds,
      'minDurationMs': minDuration.inMilliseconds,
      'maxDurationMs': maxDuration.inMilliseconds,
      'errorsByCode': errorsByCode,
      'requestsBySource': requestsBySource,
      'cacheHitRate': cacheHitRate,
      'cacheHits': cacheHits,
    };
  }

  String get dutchSummary {
    return '''
Periode: ${period != null ? '${period!.inMinutes} minuten' : 'alle tijd'}
Totaal verzoeken: $totalRequests
Succesvol: $successfulRequests (${(successRate * 100).toStringAsFixed(1)}%)
Gefaald: $failedRequests
Gemiddelde tijd: ${avgDuration.inMilliseconds}ms
95e percentiel: ${p95Duration.inMilliseconds}ms
Cache hit rate: ${(cacheHitRate * 100).toStringAsFixed(1)}%
    '''.trim();
  }
}

enum AlertType {
  slowRequest,
  verySlowRequest,
  requestError,
  highErrorRate,
  lowCacheHitRate,
  systemOverload,
}

enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}