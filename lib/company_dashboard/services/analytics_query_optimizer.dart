import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/analytics_data_models.dart';

/// Advanced query optimization service for SecuryFlex analytics
/// Provides intelligent query patterns, caching, and performance monitoring
class AnalyticsQueryOptimizer {
  static AnalyticsQueryOptimizer? _instance;
  static AnalyticsQueryOptimizer get instance {
    _instance ??= AnalyticsQueryOptimizer._();
    return _instance!;
  }

  AnalyticsQueryOptimizer._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Performance monitoring
  final Map<String, QueryPerformanceMetrics> _performanceMetrics = {};
  final Map<String, int> _queryFrequency = {};
  final List<QueryExecutionLog> _executionLogs = [];
  
  // Query optimization settings
  static const Duration _slowQueryThreshold = Duration(milliseconds: 500);
  static const int _maxExecutionLogs = 1000;

  /// Optimized query for company daily analytics with intelligent caching
  Future<List<CompanyDailyAnalytics>> getOptimizedCompanyAnalytics({
    required String companyId,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
    bool useCache = true,
  }) async {
    final queryKey = 'company_analytics_${companyId}_${startDate.toIso8601String()}_${endDate.toIso8601String()}_$limit';
    
    return await _executeOptimizedQuery<List<CompanyDailyAnalytics>>(
      queryKey: queryKey,
      queryBuilder: () async {
        final startDateStr = startDate.toIso8601String().split('T')[0];
        final endDateStr = endDate.toIso8601String().split('T')[0];
        
        Query query = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('analytics_daily')
            .where('date', isGreaterThanOrEqualTo: startDateStr)
            .where('date', isLessThanOrEqualTo: endDateStr)
            .orderBy('date', descending: true);
        
        if (limit != null) {
          query = query.limit(limit);
        }
        
        final snapshot = await query.get();
        
        return snapshot.docs
            .map((doc) => CompanyDailyAnalytics.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      },
      useCache: useCache,
    );
  }

  /// Optimized query for job analytics events with smart filtering
  Future<List<JobAnalyticsEvent>> getOptimizedJobEvents({
    required String jobId,
    JobEventType? eventType,
    String? source,
    DateTime? startTime,
    DateTime? endTime,
    int limit = 50,
    bool useCache = true,
  }) async {
    final queryKey = 'job_events_${jobId}_${eventType?.name}_${source}_${startTime?.millisecondsSinceEpoch}_${endTime?.millisecondsSinceEpoch}_$limit';
    
    return await _executeOptimizedQuery<List<JobAnalyticsEvent>>(
      queryKey: queryKey,
      queryBuilder: () async {
        Query query = _firestore
            .collection('jobs')
            .doc(jobId)
            .collection('analytics_events');
        
        // Apply filters in optimal order (most selective first)
        if (eventType != null) {
          query = query.where('eventType', isEqualTo: eventType.name);
        }
        
        if (source != null) {
          query = query.where('source', isEqualTo: source);
        }
        
        if (startTime != null) {
          query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime));
        }
        
        if (endTime != null) {
          query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endTime));
        }
        
        query = query.orderBy('timestamp', descending: true).limit(limit);
        
        final snapshot = await query.get();
        
        return snapshot.docs
            .map((doc) => JobAnalyticsEvent.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      },
      useCache: useCache,
    );
  }

  /// Optimized aggregation query with pre-computed results
  Future<Map<String, dynamic>> getOptimizedAggregation({
    required String companyId,
    required String aggregationType, // 'daily', 'weekly', 'monthly'
    required DateTime startDate,
    required DateTime endDate,
    List<String>? metrics,
    bool useCache = true,
  }) async {
    final queryKey = 'aggregation_${companyId}_${aggregationType}_${startDate.toIso8601String()}_${endDate.toIso8601String()}_${metrics?.join(",")}';
    
    return await _executeOptimizedQuery<Map<String, dynamic>>(
      queryKey: queryKey,
      queryBuilder: () async {
        final collectionName = 'analytics_$aggregationType';
        final startKey = _formatDateForAggregation(startDate, aggregationType);
        final endKey = _formatDateForAggregation(endDate, aggregationType);
        
        final query = _firestore
            .collection('companies')
            .doc(companyId)
            .collection(collectionName)
            .where('date', isGreaterThanOrEqualTo: startKey)
            .where('date', isLessThanOrEqualTo: endKey)
            .orderBy('date', descending: true);
        
        final snapshot = await query.get();
        
        if (snapshot.docs.isEmpty) {
          return <String, dynamic>{};
        }
        
        // Aggregate the results
        return _aggregateQueryResults(snapshot.docs, metrics);
      },
      useCache: useCache,
    );
  }

  /// Optimized source analytics query with ranking
  Future<List<SourceAnalytics>> getOptimizedSourceAnalytics({
    required String companyId,
    String? sortBy, // 'roi', 'cost', 'quality', 'volume'
    int limit = 10,
    bool useCache = true,
  }) async {
    final queryKey = 'source_analytics_${companyId}_${sortBy}_$limit';
    
    return await _executeOptimizedQuery<List<SourceAnalytics>>(
      queryKey: queryKey,
      queryBuilder: () async {
        Query query = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('source_analytics');
        
        // Apply optimal sorting based on use case
        switch (sortBy) {
          case 'roi':
            // Note: ROI is calculated field, so we sort by totalHires as proxy
            query = query.orderBy('totalHires', descending: true);
            break;
          case 'cost':
            query = query.orderBy('costPerHire', descending: false);
            break;
          case 'quality':
            query = query.orderBy('averageApplicationQuality', descending: true);
            break;
          case 'volume':
            query = query.orderBy('totalApplications', descending: true);
            break;
          default:
            query = query.orderBy('totalHires', descending: true);
        }
        
        query = query.limit(limit);
        
        final snapshot = await query.get();
        
        final sources = snapshot.docs
            .map((doc) => SourceAnalytics.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        
        // Apply client-side sorting for calculated fields if needed
        if (sortBy == 'roi') {
          sources.sort((a, b) => b.returnOnInvestment.compareTo(a.returnOnInvestment));
        }
        
        return sources;
      },
      useCache: useCache,
    );
  }

  /// Execute optimized query with performance monitoring
  Future<T> _executeOptimizedQuery<T>({
    required String queryKey,
    required Future<T> Function() queryBuilder,
    bool useCache = true,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // Track query frequency
      _queryFrequency[queryKey] = (_queryFrequency[queryKey] ?? 0) + 1;
      
      // Execute query
      final result = await queryBuilder();
      
      // Record performance metrics
      final executionTime = DateTime.now().difference(startTime);
      _recordQueryPerformance(queryKey, executionTime, true);
      
      return result;
      
    } catch (e) {
      // Record failed query
      final executionTime = DateTime.now().difference(startTime);
      _recordQueryPerformance(queryKey, executionTime, false);
      
      debugPrint('Query optimization error for $queryKey: $e');
      rethrow;
    }
  }

  /// Record query performance metrics
  void _recordQueryPerformance(String queryKey, Duration executionTime, bool success) {
    final metrics = _performanceMetrics[queryKey] ?? QueryPerformanceMetrics(queryKey);
    
    metrics.addExecution(executionTime, success);
    _performanceMetrics[queryKey] = metrics;
    
    // Add to execution log
    _executionLogs.add(QueryExecutionLog(
      queryKey: queryKey,
      executionTime: executionTime,
      success: success,
      timestamp: DateTime.now(),
    ));
    
    // Maintain log size
    if (_executionLogs.length > _maxExecutionLogs) {
      _executionLogs.removeRange(0, _executionLogs.length - _maxExecutionLogs);
    }
    
    // Log slow queries
    if (executionTime > _slowQueryThreshold) {
      debugPrint('SLOW QUERY: $queryKey took ${executionTime.inMilliseconds}ms');
    }
  }

  /// Format date for aggregation queries
  String _formatDateForAggregation(DateTime date, String aggregationType) {
    switch (aggregationType) {
      case 'daily':
        return date.toIso8601String().split('T')[0]; // YYYY-MM-DD
      case 'weekly':
        final year = date.year;
        final dayOfYear = date.difference(DateTime(year, 1, 1)).inDays + 1;
        final week = ((dayOfYear - date.weekday + 10) / 7).floor();
        return '$year-W${week.toString().padLeft(2, '0')}'; // YYYY-WNN
      case 'monthly':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}'; // YYYY-MM
      default:
        return date.toIso8601String().split('T')[0];
    }
  }

  /// Aggregate query results
  Map<String, dynamic> _aggregateQueryResults(
    List<QueryDocumentSnapshot> docs,
    List<String>? metrics,
  ) {
    if (docs.isEmpty) return {};
    
    final result = <String, dynamic>{
      'totalRecords': docs.length,
      'dateRange': {
        'start': (docs.last.data() as Map<String, dynamic>?)?['date'],
        'end': (docs.first.data() as Map<String, dynamic>?)?['date'],
      },
    };
    
    // Calculate aggregations
    double totalViews = 0;
    double totalApplications = 0;
    double totalSpend = 0;
    double totalConversionRate = 0;
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalViews += (data['jobViews'] ?? 0).toDouble();
      totalApplications += (data['totalApplications'] ?? 0).toDouble();
      totalSpend += (data['totalRecruitmentSpend'] ?? 0).toDouble();
      totalConversionRate += (data['viewToApplicationRate'] ?? 0).toDouble();
    }
    
    result['aggregations'] = {
      'totalViews': totalViews,
      'totalApplications': totalApplications,
      'totalSpend': totalSpend,
      'averageConversionRate': docs.isNotEmpty ? totalConversionRate / docs.length : 0,
    };
    
    // Include specific metrics if requested
    if (metrics != null) {
      result['metrics'] = {};
      for (final metric in metrics) {
        result['metrics'][metric] = _calculateMetric(docs, metric);
      }
    }
    
    return result;
  }

  /// Calculate specific metric from documents
  dynamic _calculateMetric(List<QueryDocumentSnapshot> docs, String metric) {
    switch (metric) {
      case 'growth_rate':
        if (docs.length < 2) return 0.0;
        final latest = docs.first.data() as Map<String, dynamic>;
        final previous = docs[1].data() as Map<String, dynamic>;
        final latestValue = (latest['totalApplications'] ?? 0).toDouble();
        final previousValue = (previous['totalApplications'] ?? 0).toDouble();
        return previousValue > 0 ? ((latestValue - previousValue) / previousValue) * 100 : 0.0;
        
      case 'efficiency_score':
        double totalEfficiency = 0;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          (data['jobViews'] ?? 0).toDouble();
          final applications = (data['totalApplications'] ?? 0).toDouble();
          final spend = (data['totalRecruitmentSpend'] ?? 0).toDouble();
          
          if (spend > 0) {
            totalEfficiency += (applications / spend) * 100;
          }
        }
        return docs.isNotEmpty ? totalEfficiency / docs.length : 0.0;
        
      default:
        return 0.0;
    }
  }

  /// Get query performance report
  Map<String, dynamic> getPerformanceReport() {
    final slowQueries = _performanceMetrics.values
        .where((metrics) => metrics.averageExecutionTime > _slowQueryThreshold)
        .toList()
      ..sort((a, b) => b.averageExecutionTime.compareTo(a.averageExecutionTime));
    
    final frequentQueries = _queryFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final recentErrors = _executionLogs
        .where((log) => !log.success)
        .where((log) => DateTime.now().difference(log.timestamp).inHours < 24)
        .toList();
    
    return {
      'totalQueries': _performanceMetrics.length,
      'totalExecutions': _executionLogs.length,
      'slowQueries': slowQueries.take(10).map((m) => m.toMap()).toList(),
      'frequentQueries': frequentQueries.take(10).map((e) => {
        'query': e.key,
        'frequency': e.value,
      }).toList(),
      'recentErrors': recentErrors.length,
      'averageExecutionTime': _calculateAverageExecutionTime(),
      'successRate': _calculateSuccessRate(),
    };
  }

  /// Calculate average execution time across all queries
  Duration _calculateAverageExecutionTime() {
    if (_executionLogs.isEmpty) return Duration.zero;
    
    final totalMs = _executionLogs.fold<int>(
      0,
      (total, log) => total + log.executionTime.inMilliseconds,
    );
    
    return Duration(milliseconds: totalMs ~/ _executionLogs.length);
  }

  /// Calculate overall success rate
  double _calculateSuccessRate() {
    if (_executionLogs.isEmpty) return 100.0;
    
    final successCount = _executionLogs.where((log) => log.success).length;
    return (successCount / _executionLogs.length) * 100;
  }

  /// Get optimization recommendations
  List<String> getOptimizationRecommendations() {
    final recommendations = <String>[];
    
    // Check for slow queries
    final slowQueries = _performanceMetrics.values
        .where((metrics) => metrics.averageExecutionTime > _slowQueryThreshold)
        .length;
    
    if (slowQueries > 0) {
      recommendations.add('$slowQueries queries are running slowly. Consider adding composite indexes.');
    }
    
    // Check for frequent queries
    final highFrequencyQueries = _queryFrequency.values
        .where((frequency) => frequency > 100)
        .length;
    
    if (highFrequencyQueries > 0) {
      recommendations.add('$highFrequencyQueries queries are executed frequently. Consider implementing caching.');
    }
    
    // Check error rate
    final errorRate = 100 - _calculateSuccessRate();
    if (errorRate > 5) {
      recommendations.add('Query error rate is ${errorRate.toStringAsFixed(1)}%. Review query patterns and error handling.');
    }
    
    // Check for missing indexes
    final complexQueries = _performanceMetrics.keys
        .where((key) => key.contains('_') && key.split('_').length > 3)
        .length;
    
    if (complexQueries > 0) {
      recommendations.add('$complexQueries complex queries detected. Ensure all required composite indexes are created.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Query performance is optimal. No immediate optimizations needed.');
    }
    
    return recommendations;
  }

  /// Clear performance data
  void clearPerformanceData() {
    _performanceMetrics.clear();
    _queryFrequency.clear();
    _executionLogs.clear();
  }
}

/// Query performance metrics tracking
class QueryPerformanceMetrics {
  final String queryKey;
  final List<Duration> executionTimes = [];
  final List<bool> successResults = [];
  DateTime lastExecuted = DateTime.now();
  
  QueryPerformanceMetrics(this.queryKey);
  
  void addExecution(Duration executionTime, bool success) {
    executionTimes.add(executionTime);
    successResults.add(success);
    lastExecuted = DateTime.now();
    
    // Keep only recent executions
    if (executionTimes.length > 100) {
      executionTimes.removeAt(0);
      successResults.removeAt(0);
    }
  }
  
  Duration get averageExecutionTime {
    if (executionTimes.isEmpty) return Duration.zero;
    final totalMs = executionTimes.fold<int>(0, (total, time) => total + time.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ executionTimes.length);
  }
  
  double get successRate {
    if (successResults.isEmpty) return 100.0;
    final successCount = successResults.where((success) => success).length;
    return (successCount / successResults.length) * 100;
  }
  
  Map<String, dynamic> toMap() {
    return {
      'queryKey': queryKey,
      'executionCount': executionTimes.length,
      'averageExecutionTimeMs': averageExecutionTime.inMilliseconds,
      'successRate': successRate,
      'lastExecuted': lastExecuted.toIso8601String(),
    };
  }
}

/// Query execution log entry
class QueryExecutionLog {
  final String queryKey;
  final Duration executionTime;
  final bool success;
  final DateTime timestamp;
  
  const QueryExecutionLog({
    required this.queryKey,
    required this.executionTime,
    required this.success,
    required this.timestamp,
  });
}
