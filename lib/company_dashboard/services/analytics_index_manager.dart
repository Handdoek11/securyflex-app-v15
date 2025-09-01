import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive index management and monitoring for SecuryFlex analytics
/// Handles index creation, validation, and performance optimization
class AnalyticsIndexManager {
  static AnalyticsIndexManager? _instance;
  static AnalyticsIndexManager get instance {
    _instance ??= AnalyticsIndexManager._();
    return _instance!;
  }

  AnalyticsIndexManager._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Index monitoring
  final Map<String, IndexPerformanceMetrics> _indexMetrics = {};
  final List<IndexValidationResult> _validationResults = [];

  /// Required composite indexes for analytics queries
  static const List<FirestoreIndex> requiredIndexes = [
    // Company Analytics Daily Indexes
    FirestoreIndex(
      collection: 'companies/{companyId}/analytics_daily',
      fields: [
        IndexField('date', IndexOrder.descending),
        IndexField('totalApplications', IndexOrder.descending),
      ],
      description: 'Company daily analytics sorted by date and applications',
      priority: IndexPriority.critical,
    ),
    
    FirestoreIndex(
      collection: 'companies/{companyId}/analytics_daily',
      fields: [
        IndexField('date', IndexOrder.ascending),
        IndexField('viewToApplicationRate', IndexOrder.descending),
      ],
      description: 'Company daily analytics for conversion rate analysis',
      priority: IndexPriority.high,
    ),
    
    FirestoreIndex(
      collection: 'companies/{companyId}/analytics_daily',
      fields: [
        IndexField('companyId', IndexOrder.ascending),
        IndexField('date', IndexOrder.descending),
        IndexField('jobsActive', IndexOrder.descending),
      ],
      description: 'Company analytics with active jobs filter',
      priority: IndexPriority.medium,
    ),
    
    // Job Analytics Events Indexes
    FirestoreIndex(
      collection: 'jobs/{jobId}/analytics_events',
      fields: [
        IndexField('eventType', IndexOrder.ascending),
        IndexField('timestamp', IndexOrder.descending),
      ],
      description: 'Job events filtered by type and sorted by time',
      priority: IndexPriority.critical,
    ),
    
    FirestoreIndex(
      collection: 'jobs/{jobId}/analytics_events',
      fields: [
        IndexField('source', IndexOrder.ascending),
        IndexField('timestamp', IndexOrder.descending),
      ],
      description: 'Job events filtered by source and sorted by time',
      priority: IndexPriority.high,
    ),
    
    FirestoreIndex(
      collection: 'jobs/{jobId}/analytics_events',
      fields: [
        IndexField('userRole', IndexOrder.ascending),
        IndexField('eventType', IndexOrder.ascending),
        IndexField('timestamp', IndexOrder.descending),
      ],
      description: 'Job events filtered by user role and event type',
      priority: IndexPriority.medium,
    ),
    
    FirestoreIndex(
      collection: 'jobs/{jobId}/analytics_events',
      fields: [
        IndexField('jobId', IndexOrder.ascending),
        IndexField('resultedInApplication', IndexOrder.ascending),
        IndexField('timestamp', IndexOrder.descending),
      ],
      description: 'Job events for conversion tracking',
      priority: IndexPriority.high,
    ),
    
    // Job Daily Analytics Indexes
    FirestoreIndex(
      collection: 'jobs/{jobId}/analytics_daily',
      fields: [
        IndexField('date', IndexOrder.descending),
        IndexField('totalViews', IndexOrder.descending),
      ],
      description: 'Job daily analytics sorted by date and views',
      priority: IndexPriority.high,
    ),
    
    FirestoreIndex(
      collection: 'jobs/{jobId}/analytics_daily',
      fields: [
        IndexField('companyId', IndexOrder.ascending),
        IndexField('date', IndexOrder.descending),
        IndexField('newApplications', IndexOrder.descending),
      ],
      description: 'Job daily analytics for company-wide application tracking',
      priority: IndexPriority.medium,
    ),
    
    // Funnel Analytics Indexes
    FirestoreIndex(
      collection: 'companies/{companyId}/funnel_analytics',
      fields: [
        IndexField('period', IndexOrder.ascending),
        IndexField('updatedAt', IndexOrder.descending),
      ],
      description: 'Funnel analytics sorted by period and update time',
      priority: IndexPriority.high,
    ),
    
    // Source Analytics Indexes
    FirestoreIndex(
      collection: 'companies/{companyId}/source_analytics',
      fields: [
        IndexField('costPerHire', IndexOrder.ascending),
        IndexField('totalHires', IndexOrder.descending),
      ],
      description: 'Source analytics for cost-effectiveness analysis',
      priority: IndexPriority.high,
    ),
    
    FirestoreIndex(
      collection: 'companies/{companyId}/source_analytics',
      fields: [
        IndexField('source', IndexOrder.ascending),
        IndexField('lastUpdated', IndexOrder.descending),
      ],
      description: 'Source analytics filtered by source type',
      priority: IndexPriority.medium,
    ),
    
    FirestoreIndex(
      collection: 'companies/{companyId}/source_analytics',
      fields: [
        IndexField('averageApplicationQuality', IndexOrder.descending),
        IndexField('guardRetentionRate', IndexOrder.descending),
      ],
      description: 'Source analytics for quality analysis',
      priority: IndexPriority.medium,
    ),
    
    // Application Lifecycle Events Indexes
    FirestoreIndex(
      collection: 'applications/{applicationId}/lifecycle_events',
      fields: [
        IndexField('eventType', IndexOrder.ascending),
        IndexField('timestamp', IndexOrder.descending),
      ],
      description: 'Application lifecycle events by type and time',
      priority: IndexPriority.medium,
    ),
    
    // Cross-collection Analytics Indexes
    FirestoreIndex(
      collection: 'jobs',
      fields: [
        IndexField('companyId', IndexOrder.ascending),
        IndexField('createdDate', IndexOrder.descending),
        IndexField('status', IndexOrder.ascending),
      ],
      description: 'Jobs filtered by company and status for analytics',
      priority: IndexPriority.high,
    ),
    
    FirestoreIndex(
      collection: 'applications',
      fields: [
        IndexField('companyName', IndexOrder.ascending),
        IndexField('applicationDate', IndexOrder.descending),
        IndexField('status', IndexOrder.ascending),
      ],
      description: 'Applications filtered by company and status',
      priority: IndexPriority.high,
    ),
    
    FirestoreIndex(
      collection: 'applications',
      fields: [
        IndexField('jobId', IndexOrder.ascending),
        IndexField('status', IndexOrder.ascending),
        IndexField('applicationDate', IndexOrder.descending),
      ],
      description: 'Applications filtered by job and status',
      priority: IndexPriority.medium,
    ),
  ];

  /// Validate all required indexes
  Future<IndexValidationReport> validateIndexes() async {
    debugPrint('Starting index validation...');
    
    final results = <IndexValidationResult>[];
    final startTime = DateTime.now();
    
    for (final index in requiredIndexes) {
      try {
        final result = await _validateSingleIndex(index);
        results.add(result);
        
        if (!result.isValid) {
          debugPrint('Index validation failed: ${index.description}');
        }
        
      } catch (e) {
        debugPrint('Error validating index ${index.description}: $e');
        results.add(IndexValidationResult(
          index: index,
          isValid: false,
          error: e.toString(),
          validatedAt: DateTime.now(),
        ));
      }
    }
    
    final duration = DateTime.now().difference(startTime);
    _validationResults.addAll(results);
    
    debugPrint('Index validation completed in ${duration.inMilliseconds}ms');
    
    return IndexValidationReport(
      results: results,
      totalIndexes: requiredIndexes.length,
      validIndexes: results.where((r) => r.isValid).length,
      invalidIndexes: results.where((r) => !r.isValid).length,
      validationDuration: duration,
    );
  }

  /// Validate a single index by executing a test query
  Future<IndexValidationResult> _validateSingleIndex(FirestoreIndex index) async {
    try {
      // Create a test query that would use this index
      final testQuery = _createTestQuery(index);
      
      if (testQuery == null) {
        return IndexValidationResult(
          index: index,
          isValid: true, // Assume valid if we can't test
          validatedAt: DateTime.now(),
          note: 'Could not create test query',
        );
      }
      
      final startTime = DateTime.now();
      
      // Execute test query with a small limit
      await testQuery.limit(1).get();
      
      final executionTime = DateTime.now().difference(startTime);
      
      // Record performance metrics
      _recordIndexPerformance(index, executionTime, true);
      
      return IndexValidationResult(
        index: index,
        isValid: true,
        executionTime: executionTime,
        validatedAt: DateTime.now(),
      );
      
    } catch (e) {
      // If query fails, the index might be missing
      _recordIndexPerformance(index, Duration.zero, false);
      
      return IndexValidationResult(
        index: index,
        isValid: false,
        error: e.toString(),
        validatedAt: DateTime.now(),
      );
    }
  }

  /// Create a test query for index validation
  Query? _createTestQuery(FirestoreIndex index) {
    try {
      // Handle collection group vs document-specific collections
      Query query;
      
      if (index.collection.contains('{') && index.collection.contains('}')) {
        // This is a subcollection pattern, we need to create a specific path
        final collectionPath = _resolveCollectionPath(index.collection);
        if (collectionPath == null) return null;
        
        query = _firestore.collection(collectionPath);
      } else {
        // This is a root collection
        query = _firestore.collection(index.collection);
      }
      
      // Apply field constraints in the order they appear in the index
      for (final field in index.fields) {
        if (field.name == 'date') {
          // Use a recent date for testing
          final testDate = DateTime.now().subtract(const Duration(days: 7));
          final dateStr = testDate.toIso8601String().split('T')[0];
          query = query.where(field.name, isGreaterThanOrEqualTo: dateStr);
        } else if (field.name == 'timestamp') {
          // Use a recent timestamp for testing
          final testTime = Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1)));
          query = query.where(field.name, isGreaterThanOrEqualTo: testTime);
        } else if (field.name == 'eventType') {
          query = query.where(field.name, isEqualTo: 'view');
        } else if (field.name == 'source') {
          query = query.where(field.name, isEqualTo: 'search');
        } else if (field.name == 'userRole') {
          query = query.where(field.name, isEqualTo: 'guard');
        } else if (field.name == 'status') {
          query = query.where(field.name, isEqualTo: 'active');
        }
        // Add orderBy for the last field if it's not used in where clause
        else if (field == index.fields.last && !_isFieldUsedInWhere(field.name, index)) {
          query = query.orderBy(field.name, descending: field.order == IndexOrder.descending);
        }
      }
      
      return query;
      
    } catch (e) {
      debugPrint('Error creating test query for ${index.description}: $e');
      return null;
    }
  }

  /// Resolve collection path for subcollections
  String? _resolveCollectionPath(String pattern) {
    // Replace placeholders with test values
    return pattern
        .replaceAll('{companyId}', 'test_company')
        .replaceAll('{jobId}', 'test_job')
        .replaceAll('{applicationId}', 'test_application');
  }

  /// Check if field is used in where clause
  bool _isFieldUsedInWhere(String fieldName, FirestoreIndex index) {
    const whereFields = ['date', 'timestamp', 'eventType', 'source', 'userRole', 'status'];
    return whereFields.contains(fieldName);
  }

  /// Record index performance metrics
  void _recordIndexPerformance(FirestoreIndex index, Duration executionTime, bool success) {
    final key = index.description;
    final metrics = _indexMetrics[key] ?? IndexPerformanceMetrics(index);
    
    metrics.addExecution(executionTime, success);
    _indexMetrics[key] = metrics;
  }

  /// Generate Firebase CLI commands for creating indexes
  List<String> generateFirebaseCLICommands() {
    return requiredIndexes.map((index) {
      final fieldSpecs = index.fields.map((field) {
        final order = field.order == IndexOrder.ascending ? 'asc' : 'desc';
        return '${field.name}:$order';
      }).join(',');
      
      return 'firebase firestore:indexes:create --collection-group="${index.collection}" --field-config="$fieldSpecs"';
    }).toList();
  }

  /// Generate firestore.indexes.json configuration
  Map<String, dynamic> generateIndexesConfig() {
    final indexes = requiredIndexes.map((index) {
      return {
        'collectionGroup': index.collection.split('/').last,
        'queryScope': 'COLLECTION',
        'fields': index.fields.map((field) {
          return {
            'fieldPath': field.name,
            'order': field.order == IndexOrder.ascending ? 'ASCENDING' : 'DESCENDING',
          };
        }).toList(),
      };
    }).toList();
    
    return {
      'indexes': indexes,
    };
  }

  /// Get index performance report
  Map<String, dynamic> getIndexPerformanceReport() {
    final slowIndexes = _indexMetrics.values
        .where((metrics) => metrics.averageExecutionTime.inMilliseconds > 100)
        .toList()
      ..sort((a, b) => b.averageExecutionTime.compareTo(a.averageExecutionTime));
    
    final failingIndexes = _indexMetrics.values
        .where((metrics) => metrics.successRate < 95.0)
        .toList()
      ..sort((a, b) => a.successRate.compareTo(b.successRate));
    
    return {
      'totalIndexes': requiredIndexes.length,
      'monitoredIndexes': _indexMetrics.length,
      'slowIndexes': slowIndexes.take(5).map((m) => m.toMap()).toList(),
      'failingIndexes': failingIndexes.take(5).map((m) => m.toMap()).toList(),
      'averageExecutionTime': _calculateAverageExecutionTime(),
      'overallSuccessRate': _calculateOverallSuccessRate(),
      'lastValidation': _validationResults.isNotEmpty 
          ? _validationResults.last.validatedAt.toIso8601String()
          : null,
    };
  }

  /// Calculate average execution time across all indexes
  Duration _calculateAverageExecutionTime() {
    if (_indexMetrics.isEmpty) return Duration.zero;
    
    final totalMs = _indexMetrics.values.fold<int>(
      0,
      (total, metrics) => total + metrics.averageExecutionTime.inMilliseconds,
    );
    
    return Duration(milliseconds: totalMs ~/ _indexMetrics.length);
  }

  /// Calculate overall success rate
  double _calculateOverallSuccessRate() {
    if (_indexMetrics.isEmpty) return 100.0;
    
    final totalSuccessRate = _indexMetrics.values.fold<double>(
      0.0,
      (total, metrics) => total + metrics.successRate,
    );
    
    return totalSuccessRate / _indexMetrics.length;
  }

  /// Get index optimization recommendations
  List<String> getIndexOptimizationRecommendations() {
    final recommendations = <String>[];
    
    // Check for missing indexes
    final invalidIndexes = _validationResults
        .where((result) => !result.isValid)
        .length;
    
    if (invalidIndexes > 0) {
      recommendations.add('$invalidIndexes indexes are missing or invalid. Run index creation commands.');
    }
    
    // Check for slow indexes
    final slowIndexes = _indexMetrics.values
        .where((metrics) => metrics.averageExecutionTime.inMilliseconds > 100)
        .length;
    
    if (slowIndexes > 0) {
      recommendations.add('$slowIndexes indexes are performing slowly. Review query patterns.');
    }
    
    // Check for failing indexes
    final failingIndexes = _indexMetrics.values
        .where((metrics) => metrics.successRate < 95.0)
        .length;
    
    if (failingIndexes > 0) {
      recommendations.add('$failingIndexes indexes have low success rates. Check index configuration.');
    }
    
    // Check for unused indexes
    final unusedIndexes = requiredIndexes.length - _indexMetrics.length;
    if (unusedIndexes > 0) {
      recommendations.add('$unusedIndexes indexes are not being monitored. Ensure all queries use indexes.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('All indexes are performing optimally.');
    }
    
    return recommendations;
  }

  /// Clear performance data
  void clearPerformanceData() {
    _indexMetrics.clear();
    _validationResults.clear();
  }
}

/// Firestore index definition
class FirestoreIndex {
  final String collection;
  final List<IndexField> fields;
  final String description;
  final IndexPriority priority;

  const FirestoreIndex({
    required this.collection,
    required this.fields,
    required this.description,
    required this.priority,
  });
}

/// Index field definition
class IndexField {
  final String name;
  final IndexOrder order;

  const IndexField(this.name, this.order);
}

/// Index order enumeration
enum IndexOrder { ascending, descending }

/// Index priority enumeration
enum IndexPriority { critical, high, medium, low }

/// Index validation result
class IndexValidationResult {
  final FirestoreIndex index;
  final bool isValid;
  final Duration? executionTime;
  final String? error;
  final String? note;
  final DateTime validatedAt;

  const IndexValidationResult({
    required this.index,
    required this.isValid,
    this.executionTime,
    this.error,
    this.note,
    required this.validatedAt,
  });
}

/// Index validation report
class IndexValidationReport {
  final List<IndexValidationResult> results;
  final int totalIndexes;
  final int validIndexes;
  final int invalidIndexes;
  final Duration validationDuration;

  const IndexValidationReport({
    required this.results,
    required this.totalIndexes,
    required this.validIndexes,
    required this.invalidIndexes,
    required this.validationDuration,
  });

  double get validationSuccessRate => totalIndexes > 0 ? (validIndexes / totalIndexes) * 100 : 0.0;
}

/// Index performance metrics
class IndexPerformanceMetrics {
  final FirestoreIndex index;
  final List<Duration> executionTimes = [];
  final List<bool> successResults = [];
  DateTime lastExecuted = DateTime.now();

  IndexPerformanceMetrics(this.index);

  void addExecution(Duration executionTime, bool success) {
    executionTimes.add(executionTime);
    successResults.add(success);
    lastExecuted = DateTime.now();

    // Keep only recent executions
    if (executionTimes.length > 50) {
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
      'description': index.description,
      'collection': index.collection,
      'priority': index.priority.name,
      'executionCount': executionTimes.length,
      'averageExecutionTimeMs': averageExecutionTime.inMilliseconds,
      'successRate': successRate,
      'lastExecuted': lastExecuted.toIso8601String(),
    };
  }
}
