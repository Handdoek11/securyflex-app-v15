import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics_data_models.dart';
import '../database/analytics_repository.dart';
import '../../auth/auth_service.dart';

/// Real-time analytics event tracking service
/// Handles event capture with batching, error handling, and performance optimization
class AnalyticsEventService {
  static AnalyticsEventService? _instance;
  static AnalyticsEventService get instance {
    _instance ??= AnalyticsEventService._();
    return _instance!;
  }

  AnalyticsEventService._();

  final AnalyticsRepository _repository = FirebaseAnalyticsRepository();
  final Queue<JobAnalyticsEvent> _eventQueue = Queue<JobAnalyticsEvent>();
  Timer? _batchTimer;
  bool _isProcessing = false;

  // Configuration
  static const int _batchSize = 10;
  static const Duration _batchInterval = Duration(seconds: 30);
  static const int _maxRetries = 3;

  // Event tracking state
  final Map<String, DateTime> _lastEventTime = {};
  final Map<String, int> _retryCount = {};

  /// Track job view event
  Future<void> trackJobView({
    required String jobId,
    required String source,
    String? userId,
    String? location,
    int? sessionDuration,
    int? pageLoadTime,
  }) async {
    final event = JobAnalyticsEvent(
      eventId: _generateEventId(),
      jobId: jobId,
      eventType: JobEventType.view,
      timestamp: DateTime.now(),
      userId: userId ?? AuthService.currentUserId,
      userRole: AuthService.currentUserType,
      source: source,
      deviceType: _getDeviceType(),
      location: location,
      sessionDuration: sessionDuration,
      pageLoadTime: pageLoadTime,
      metadata: {
        'platform': defaultTargetPlatform.name,
        'timestamp_ms': DateTime.now().millisecondsSinceEpoch,
      },
    );

    await _queueEvent(event);
  }

  /// Track job application event
  Future<void> trackJobApplication({
    required String jobId,
    required String applicationId,
    String? userId,
    String? source,
    Map<String, dynamic>? applicationMetadata,
  }) async {
    final event = JobAnalyticsEvent(
      eventId: _generateEventId(),
      jobId: jobId,
      eventType: JobEventType.application,
      timestamp: DateTime.now(),
      userId: userId ?? AuthService.currentUserId,
      userRole: AuthService.currentUserType,
      source: source ?? 'direct',
      deviceType: _getDeviceType(),
      resultedInApplication: true,
      applicationId: applicationId,
      metadata: {
        'platform': defaultTargetPlatform.name,
        'timestamp_ms': DateTime.now().millisecondsSinceEpoch,
        ...?applicationMetadata,
      },
    );

    await _queueEvent(event);
  }

  /// Track job hire event
  Future<void> trackJobHire({
    required String jobId,
    required String applicationId,
    String? userId,
    double? hireCost,
    Duration? timeToHire,
  }) async {
    final event = JobAnalyticsEvent(
      eventId: _generateEventId(),
      jobId: jobId,
      eventType: JobEventType.hire,
      timestamp: DateTime.now(),
      userId: userId ?? AuthService.currentUserId,
      userRole: AuthService.currentUserType,
      source: 'application',
      deviceType: _getDeviceType(),
      applicationId: applicationId,
      metadata: {
        'platform': defaultTargetPlatform.name,
        'timestamp_ms': DateTime.now().millisecondsSinceEpoch,
        'hire_cost': hireCost,
        'time_to_hire_hours': timeToHire?.inHours,
      },
    );

    await _queueEvent(event);
  }

  /// Track job rejection event
  Future<void> trackJobRejection({
    required String jobId,
    required String applicationId,
    String? userId,
    String? rejectionReason,
  }) async {
    final event = JobAnalyticsEvent(
      eventId: _generateEventId(),
      jobId: jobId,
      eventType: JobEventType.rejection,
      timestamp: DateTime.now(),
      userId: userId ?? AuthService.currentUserId,
      userRole: AuthService.currentUserType,
      source: 'application',
      deviceType: _getDeviceType(),
      applicationId: applicationId,
      metadata: {
        'platform': defaultTargetPlatform.name,
        'timestamp_ms': DateTime.now().millisecondsSinceEpoch,
        'rejection_reason': rejectionReason,
      },
    );

    await _queueEvent(event);
  }

  /// Track job completion event
  Future<void> trackJobCompletion({
    required String jobId,
    String? userId,
    double? finalCost,
    int? guardRating,
    String? feedback,
  }) async {
    final event = JobAnalyticsEvent(
      eventId: _generateEventId(),
      jobId: jobId,
      eventType: JobEventType.completion,
      timestamp: DateTime.now(),
      userId: userId ?? AuthService.currentUserId,
      userRole: AuthService.currentUserType,
      source: 'job_management',
      deviceType: _getDeviceType(),
      metadata: {
        'platform': defaultTargetPlatform.name,
        'timestamp_ms': DateTime.now().millisecondsSinceEpoch,
        'final_cost': finalCost,
        'guard_rating': guardRating,
        'feedback': feedback,
      },
    );

    await _queueEvent(event);
  }

  /// Track custom event with metadata
  Future<void> trackCustomEvent({
    required String jobId,
    required JobEventType eventType,
    String? userId,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    final event = JobAnalyticsEvent(
      eventId: _generateEventId(),
      jobId: jobId,
      eventType: eventType,
      timestamp: DateTime.now(),
      userId: userId ?? AuthService.currentUserId,
      userRole: AuthService.currentUserType,
      source: source ?? 'unknown',
      deviceType: _getDeviceType(),
      metadata: {
        'platform': defaultTargetPlatform.name,
        'timestamp_ms': DateTime.now().millisecondsSinceEpoch,
        ...?metadata,
      },
    );

    await _queueEvent(event);
  }

  /// Queue event for batch processing
  Future<void> _queueEvent(JobAnalyticsEvent event) async {
    // Prevent duplicate events within short time window
    final eventKey = '${event.jobId}_${event.eventType.name}_${event.userId}';
    final lastTime = _lastEventTime[eventKey];
    final now = DateTime.now();
    
    if (lastTime != null && now.difference(lastTime).inSeconds < 5) {
      debugPrint('Skipping duplicate event: $eventKey');
      return;
    }
    
    _lastEventTime[eventKey] = now;
    _eventQueue.add(event);
    
    // Start batch timer if not already running
    _startBatchTimer();
    
    // Process immediately if queue is full
    if (_eventQueue.length >= _batchSize) {
      await _processBatch();
    }
  }

  /// Start batch processing timer
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer(_batchInterval, () {
      _processBatch();
    });
  }

  /// Process queued events in batch
  Future<void> _processBatch() async {
    if (_isProcessing || _eventQueue.isEmpty) return;
    
    _isProcessing = true;
    _batchTimer?.cancel();
    
    try {
      final batch = <JobAnalyticsEvent>[];
      
      // Extract batch from queue
      while (batch.length < _batchSize && _eventQueue.isNotEmpty) {
        batch.add(_eventQueue.removeFirst());
      }
      
      if (batch.isEmpty) {
        _isProcessing = false;
        return;
      }
      
      debugPrint('Processing analytics batch: ${batch.length} events');
      
      // Process events in parallel with error handling
      final futures = batch.map((event) => _processEventWithRetry(event));
      await Future.wait(futures, eagerError: false);
      
      debugPrint('Analytics batch processed successfully');
      
    } catch (e) {
      debugPrint('Error processing analytics batch: $e');
    } finally {
      _isProcessing = false;
      
      // Continue processing if more events are queued
      if (_eventQueue.isNotEmpty) {
        _startBatchTimer();
      }
    }
  }

  /// Process individual event with retry logic
  Future<void> _processEventWithRetry(JobAnalyticsEvent event) async {
    final eventKey = event.eventId;
    int retryCount = _retryCount[eventKey] ?? 0;
    
    try {
      await _repository.saveJobAnalyticsEvent(event);
      
      // Clear retry count on success
      _retryCount.remove(eventKey);
      
    } catch (e) {
      debugPrint('Error saving analytics event ${event.eventId}: $e');
      
      retryCount++;
      _retryCount[eventKey] = retryCount;
      
      if (retryCount < _maxRetries) {
        // Exponential backoff retry
        final delay = Duration(seconds: (2 * retryCount).clamp(1, 60));
        Timer(delay, () => _processEventWithRetry(event));
      } else {
        debugPrint('Max retries exceeded for event ${event.eventId}');
        _retryCount.remove(eventKey);
      }
    }
  }

  /// Generate unique event ID
  String _generateEventId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'evt_${timestamp}_$random';
  }

  /// Get device type based on platform
  String _getDeviceType() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return 'mobile';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'desktop';
      default:
        return 'unknown';
    }
  }

  /// Flush all queued events immediately
  Future<void> flush() async {
    while (_eventQueue.isNotEmpty) {
      await _processBatch();
    }
  }

  /// Get queue status for monitoring
  Map<String, dynamic> getQueueStatus() {
    return {
      'queueSize': _eventQueue.length,
      'isProcessing': _isProcessing,
      'retryCount': _retryCount.length,
      'lastEventTime': _lastEventTime.isNotEmpty 
          ? _lastEventTime.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }

  /// Dispose service and cleanup resources
  void dispose() {
    _batchTimer?.cancel();
    _eventQueue.clear();
    _lastEventTime.clear();
    _retryCount.clear();
    _isProcessing = false;
  }
}

/// Analytics aggregation service for scheduled data processing
/// Handles daily, weekly, and monthly analytics rollups
class AnalyticsAggregationService {
  static AnalyticsAggregationService? _instance;
  static AnalyticsAggregationService get instance {
    _instance ??= AnalyticsAggregationService._();
    return _instance!;
  }

  AnalyticsAggregationService._();

  final AnalyticsRepository _repository = FirebaseAnalyticsRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Aggregate daily analytics for a specific company and date
  Future<void> aggregateCompanyDailyAnalytics(String companyId, String date) async {
    try {
      debugPrint('Aggregating daily analytics for company $companyId on $date');

      // Get all jobs for the company
      final jobsQuery = await _firestore
          .collection('jobs')
          .where('companyId', isEqualTo: companyId)
          .get();

      int totalViews = 0;
      int uniqueViews = 0;
      int newApplications = 0;
      int totalApplications = 0;
      double totalTimeToFill = 0;
      int completedJobs = 0;
      final Map<String, SourceMetrics> sourceBreakdown = {};

      // Aggregate data from job analytics
      for (final jobDoc in jobsQuery.docs) {
        final jobId = jobDoc.id;
        final jobAnalytics = await _repository.getJobDailyAnalytics(jobId, date);

        if (jobAnalytics != null) {
          totalViews += jobAnalytics.totalViews;
          uniqueViews += jobAnalytics.uniqueViews;
          newApplications += jobAnalytics.newApplications;
          totalApplications += jobAnalytics.totalApplications;
        }

        // Get job events for the date to analyze sources
        final events = await _repository.getJobEvents(jobId, limit: 100);
        final dayEvents = events.where((e) =>
          e.timestamp.toIso8601String().split('T')[0] == date
        ).toList();

        for (final event in dayEvents) {
          final source = event.source;
          if (!sourceBreakdown.containsKey(source)) {
            sourceBreakdown[source] = const SourceMetrics(
              applications: 0,
              hires: 0,
              cost: 0.0,
            );
          }

          if (event.eventType == JobEventType.application) {
            sourceBreakdown[source] = SourceMetrics(
              applications: sourceBreakdown[source]!.applications + 1,
              hires: sourceBreakdown[source]!.hires,
              cost: sourceBreakdown[source]!.cost + 5.0, // Estimated cost per application
            );
          } else if (event.eventType == JobEventType.hire) {
            sourceBreakdown[source] = SourceMetrics(
              applications: sourceBreakdown[source]!.applications,
              hires: sourceBreakdown[source]!.hires + 1,
              cost: sourceBreakdown[source]!.cost + 50.0, // Estimated cost per hire
            );
          }
        }
      }

      // Get application data for the date
      final applicationsQuery = await _firestore
          .collection('applications')
          .where('companyName', isEqualTo: await _getCompanyName(companyId))
          .get();

      int applicationsAccepted = 0;
      int applicationsRejected = 0;
      int applicationsPending = 0;

      for (final appDoc in applicationsQuery.docs) {
        final appData = appDoc.data();
        final appDate = (appData['applicationDate'] as Timestamp?)?.toDate();

        if (appDate != null && appDate.toIso8601String().split('T')[0] == date) {
          final status = appData['status'] as String? ?? 'pending';
          switch (status) {
            case 'accepted':
              applicationsAccepted++;
              break;
            case 'rejected':
              applicationsRejected++;
              break;
            default:
              applicationsPending++;
          }
        }
      }

      // Calculate metrics
      final viewToApplicationRate = totalViews > 0 ? (newApplications / totalViews) * 100 : 0.0;
      final applicationToHireRate = totalApplications > 0 ? (applicationsAccepted / totalApplications) * 100 : 0.0;

      // Create daily analytics
      final dailyAnalytics = CompanyDailyAnalytics(
        date: date,
        companyId: companyId,
        jobsPosted: jobsQuery.docs.length,
        jobsActive: jobsQuery.docs.where((doc) =>
          (doc.data()['status'] as String? ?? '') == 'active'
        ).length,
        jobsCompleted: completedJobs,
        jobsCancelled: 0, // Calculate from job status changes
        totalApplications: newApplications,
        applicationsAccepted: applicationsAccepted,
        applicationsRejected: applicationsRejected,
        applicationsPending: applicationsPending,
        jobViews: totalViews,
        uniqueJobViews: uniqueViews,
        viewToApplicationRate: viewToApplicationRate,
        applicationToHireRate: applicationToHireRate,
        averageTimeToFill: completedJobs > 0 ? totalTimeToFill / completedJobs : 0.0,
        averageTimeToFirstApplication: 24.0, // Default estimate
        totalCostPerHire: applicationsAccepted > 0 ? 75.0 : 0.0, // Estimated cost per hire
        totalRecruitmentSpend: sourceBreakdown.values.fold(0.0, (total, metrics) => total + metrics.cost),
        sourceBreakdown: sourceBreakdown,
        averageApplicationQuality: 3.5, // Default quality score
        guardRetentionRate: 85.0, // Default retention rate
        updatedAt: DateTime.now(),
      );

      await _repository.saveCompanyDailyAnalytics(dailyAnalytics);
      debugPrint('Daily analytics aggregated successfully for company $companyId');

    } catch (e) {
      debugPrint('Error aggregating daily analytics: $e');
      rethrow;
    }
  }

  /// Aggregate all companies for a specific date
  Future<void> aggregateAllCompaniesDailyAnalytics(String date) async {
    try {
      final companies = await _firestore.collection('companies').get();

      for (final companyDoc in companies.docs) {
        await aggregateCompanyDailyAnalytics(companyDoc.id, date);
      }

      debugPrint('Daily analytics aggregated for all companies on $date');
    } catch (e) {
      debugPrint('Error aggregating all companies daily analytics: $e');
      rethrow;
    }
  }

  /// Helper method to get company name by ID
  Future<String> _getCompanyName(String companyId) async {
    try {
      final companyDoc = await _firestore.collection('companies').doc(companyId).get();
      return companyDoc.data()?['companyName'] as String? ?? '';
    } catch (e) {
      debugPrint('Error getting company name: $e');
      return '';
    }
  }
}
