import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/analytics_data_models.dart';
import 'analytics_firestore_schema.dart';

/// Repository interface for analytics data access
/// Provides abstraction layer for analytics data operations
abstract class AnalyticsRepository {
  // Company Analytics
  Future<CompanyDailyAnalytics?> getCompanyDailyAnalytics(String companyId, String date);
  Future<List<CompanyDailyAnalytics>> getCompanyAnalyticsRange(String companyId, String startDate, String endDate);
  Future<void> saveCompanyDailyAnalytics(CompanyDailyAnalytics analytics);
  Stream<CompanyDailyAnalytics?> watchCompanyDailyAnalytics(String companyId, String date);
  
  // Job Analytics
  Future<void> saveJobAnalyticsEvent(JobAnalyticsEvent event);
  Future<List<JobAnalyticsEvent>> getJobEvents(String jobId, {JobEventType? eventType, int? limit});
  Stream<List<JobAnalyticsEvent>> watchJobEvents(String jobId, {JobEventType? eventType});
  Future<JobDailyAnalytics?> getJobDailyAnalytics(String jobId, String date);
  Future<void> saveJobDailyAnalytics(JobDailyAnalytics analytics);
  
  // Funnel Analytics
  Future<RecruitmentFunnelAnalytics?> getFunnelAnalytics(String companyId, String period);
  Future<void> saveFunnelAnalytics(RecruitmentFunnelAnalytics analytics);
  Stream<RecruitmentFunnelAnalytics?> watchFunnelAnalytics(String companyId, String period);
  
  // Source Analytics
  Future<SourceAnalytics?> getSourceAnalytics(String companyId, String source);
  Future<List<SourceAnalytics>> getAllSourceAnalytics(String companyId);
  Future<void> saveSourceAnalytics(SourceAnalytics analytics);
  Stream<List<SourceAnalytics>> watchSourceAnalytics(String companyId);
}

/// Firebase implementation of analytics repository with caching and optimization
/// Handles all Firestore operations for analytics data with performance enhancements
class FirebaseAnalyticsRepository implements AnalyticsRepository {
  // Caching layer
  final Map<String, CompanyDailyAnalytics> _companyAnalyticsCache = {};
  final Map<String, List<JobAnalyticsEvent>> _jobEventsCache = {};
  final Map<String, RecruitmentFunnelAnalytics> _funnelAnalyticsCache = {};
  final Map<String, List<SourceAnalytics>> _sourceAnalyticsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache configuration
  static const Duration _cacheValidDuration = Duration(minutes: 15);
  static const int _maxCacheSize = 100;

  FirebaseAnalyticsRepository();

  @override
  Future<CompanyDailyAnalytics?> getCompanyDailyAnalytics(String companyId, String date) async {
    final cacheKey = '${companyId}_$date';

    // Check cache first
    if (_isCacheValid(cacheKey) && _companyAnalyticsCache.containsKey(cacheKey)) {
      debugPrint('Returning cached company analytics for $cacheKey');
      return _companyAnalyticsCache[cacheKey];
    }

    try {
      final doc = await AnalyticsFirestoreSchema
          .getCompanyAnalyticsDaily(companyId)
          .doc(date)
          .get();

      if (!doc.exists) return null;

      final analytics = CompanyDailyAnalytics.fromMap(doc.data() as Map<String, dynamic>);

      // Cache the result
      _cacheCompanyAnalytics(cacheKey, analytics);

      return analytics;
    } catch (e) {
      debugPrint('Error getting company daily analytics: $e');
      return null;
    }
  }

  @override
  Future<List<CompanyDailyAnalytics>> getCompanyAnalyticsRange(
    String companyId, 
    String startDate, 
    String endDate
  ) async {
    try {
      final query = await AnalyticsFirestoreSchema
          .getCompanyAnalyticsDaily(companyId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true)
          .get();
      
      return query.docs
          .map((doc) => CompanyDailyAnalytics.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting company analytics range: $e');
      return [];
    }
  }

  @override
  Future<void> saveCompanyDailyAnalytics(CompanyDailyAnalytics analytics) async {
    try {
      await AnalyticsFirestoreSchema
          .getCompanyAnalyticsDaily(analytics.companyId)
          .doc(analytics.date)
          .set(analytics.toMap());
    } catch (e) {
      debugPrint('Error saving company daily analytics: $e');
      rethrow;
    }
  }

  @override
  Stream<CompanyDailyAnalytics?> watchCompanyDailyAnalytics(String companyId, String date) {
    return AnalyticsFirestoreSchema
        .getCompanyAnalyticsDaily(companyId)
        .doc(date)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return CompanyDailyAnalytics.fromMap(doc.data() as Map<String, dynamic>);
        });
  }

  @override
  Future<void> saveJobAnalyticsEvent(JobAnalyticsEvent event) async {
    try {
      await AnalyticsFirestoreSchema
          .getJobAnalyticsEvents(event.jobId)
          .doc(event.eventId)
          .set(event.toMap());
    } catch (e) {
      debugPrint('Error saving job analytics event: $e');
      rethrow;
    }
  }

  @override
  Future<List<JobAnalyticsEvent>> getJobEvents(
    String jobId, {
    JobEventType? eventType,
    int? limit,
  }) async {
    final cacheKey = '${jobId}_${eventType?.name ?? 'all'}_${limit ?? 'unlimited'}';

    // Check cache first
    if (_isCacheValid(cacheKey) && _jobEventsCache.containsKey(cacheKey)) {
      debugPrint('Returning cached job events for $cacheKey');
      return _jobEventsCache[cacheKey]!;
    }

    try {
      Query query = AnalyticsFirestoreSchema
          .getJobAnalyticsEvents(jobId)
          .orderBy('timestamp', descending: true);

      if (eventType != null) {
        query = query.where('eventType', isEqualTo: eventType.name);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      final events = snapshot.docs
          .map((doc) => JobAnalyticsEvent.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Cache the result
      _cacheJobEvents(cacheKey, events);

      return events;
    } catch (e) {
      debugPrint('Error getting job events: $e');
      return [];
    }
  }

  @override
  Stream<List<JobAnalyticsEvent>> watchJobEvents(
    String jobId, {
    JobEventType? eventType,
  }) {
    Query query = AnalyticsFirestoreSchema
        .getJobAnalyticsEvents(jobId)
        .orderBy('timestamp', descending: true)
        .limit(50); // Limit for performance
    
    if (eventType != null) {
      query = query.where('eventType', isEqualTo: eventType.name);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => JobAnalyticsEvent.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<JobDailyAnalytics?> getJobDailyAnalytics(String jobId, String date) async {
    try {
      final doc = await AnalyticsFirestoreSchema
          .getJobAnalyticsDaily(jobId)
          .doc(date)
          .get();
      
      if (!doc.exists) return null;
      
      return JobDailyAnalytics.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting job daily analytics: $e');
      return null;
    }
  }

  @override
  Future<void> saveJobDailyAnalytics(JobDailyAnalytics analytics) async {
    try {
      await AnalyticsFirestoreSchema
          .getJobAnalyticsDaily(analytics.jobId)
          .doc(analytics.date)
          .set(analytics.toMap());
    } catch (e) {
      debugPrint('Error saving job daily analytics: $e');
      rethrow;
    }
  }

  @override
  Future<RecruitmentFunnelAnalytics?> getFunnelAnalytics(String companyId, String period) async {
    final cacheKey = '${companyId}_$period';

    // Check cache first
    if (_isCacheValid(cacheKey) && _funnelAnalyticsCache.containsKey(cacheKey)) {
      debugPrint('Returning cached funnel analytics for $cacheKey');
      return _funnelAnalyticsCache[cacheKey];
    }

    try {
      final doc = await AnalyticsFirestoreSchema
          .getCompanyFunnelAnalytics(companyId)
          .doc(period)
          .get();

      if (!doc.exists) return null;

      final analytics = RecruitmentFunnelAnalytics.fromMap(doc.data() as Map<String, dynamic>);

      // Cache the result
      _cacheFunnelAnalytics(cacheKey, analytics);

      return analytics;
    } catch (e) {
      debugPrint('Error getting funnel analytics: $e');
      return null;
    }
  }

  @override
  Future<void> saveFunnelAnalytics(RecruitmentFunnelAnalytics analytics) async {
    try {
      await AnalyticsFirestoreSchema
          .getCompanyFunnelAnalytics(analytics.companyId)
          .doc(analytics.period)
          .set(analytics.toMap());
    } catch (e) {
      debugPrint('Error saving funnel analytics: $e');
      rethrow;
    }
  }

  @override
  Stream<RecruitmentFunnelAnalytics?> watchFunnelAnalytics(String companyId, String period) {
    return AnalyticsFirestoreSchema
        .getCompanyFunnelAnalytics(companyId)
        .doc(period)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return RecruitmentFunnelAnalytics.fromMap(doc.data() as Map<String, dynamic>);
        });
  }

  @override
  Future<SourceAnalytics?> getSourceAnalytics(String companyId, String source) async {
    try {
      final doc = await AnalyticsFirestoreSchema
          .getCompanySourceAnalytics(companyId)
          .doc(source)
          .get();
      
      if (!doc.exists) return null;
      
      return SourceAnalytics.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting source analytics: $e');
      return null;
    }
  }

  @override
  Future<List<SourceAnalytics>> getAllSourceAnalytics(String companyId) async {
    final cacheKey = '${companyId}_all_sources';

    // Check cache first
    if (_isCacheValid(cacheKey) && _sourceAnalyticsCache.containsKey(cacheKey)) {
      debugPrint('Returning cached source analytics for $cacheKey');
      return _sourceAnalyticsCache[cacheKey]!;
    }

    try {
      final query = await AnalyticsFirestoreSchema
          .getCompanySourceAnalytics(companyId)
          .orderBy('totalHires', descending: true)
          .get();

      final analytics = query.docs
          .map((doc) => SourceAnalytics.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Cache the result
      _cacheSourceAnalytics(cacheKey, analytics);

      return analytics;
    } catch (e) {
      debugPrint('Error getting all source analytics: $e');
      return [];
    }
  }

  @override
  Future<void> saveSourceAnalytics(SourceAnalytics analytics) async {
    try {
      await AnalyticsFirestoreSchema
          .getCompanySourceAnalytics(analytics.companyId)
          .doc(analytics.source)
          .set(analytics.toMap());
    } catch (e) {
      debugPrint('Error saving source analytics: $e');
      rethrow;
    }
  }

  @override
  Stream<List<SourceAnalytics>> watchSourceAnalytics(String companyId) {
    return AnalyticsFirestoreSchema
        .getCompanySourceAnalytics(companyId)
        .orderBy('totalHires', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SourceAnalytics.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }

  // Cache management methods

  /// Check if cache entry is valid
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheValidDuration;
  }

  /// Cache company analytics
  void _cacheCompanyAnalytics(String cacheKey, CompanyDailyAnalytics analytics) {
    _manageCacheSize();
    _companyAnalyticsCache[cacheKey] = analytics;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Cache job events
  void _cacheJobEvents(String cacheKey, List<JobAnalyticsEvent> events) {
    _manageCacheSize();
    _jobEventsCache[cacheKey] = events;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Cache funnel analytics
  void _cacheFunnelAnalytics(String cacheKey, RecruitmentFunnelAnalytics analytics) {
    _manageCacheSize();
    _funnelAnalyticsCache[cacheKey] = analytics;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Cache source analytics
  void _cacheSourceAnalytics(String cacheKey, List<SourceAnalytics> analytics) {
    _manageCacheSize();
    _sourceAnalyticsCache[cacheKey] = analytics;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Manage cache size to prevent memory issues
  void _manageCacheSize() {
    if (_cacheTimestamps.length >= _maxCacheSize) {
      // Remove oldest entries
      final sortedEntries = _cacheTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final entriesToRemove = sortedEntries.take(_maxCacheSize ~/ 4); // Remove 25%

      for (final entry in entriesToRemove) {
        final key = entry.key;
        _cacheTimestamps.remove(key);
        _companyAnalyticsCache.remove(key);
        _jobEventsCache.remove(key);
        _funnelAnalyticsCache.remove(key);
        _sourceAnalyticsCache.remove(key);
      }
    }
  }

  /// Clear all caches
  void clearCache() {
    _companyAnalyticsCache.clear();
    _jobEventsCache.clear();
    _funnelAnalyticsCache.clear();
    _sourceAnalyticsCache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) >= _cacheValidDuration)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cacheTimestamps.remove(key);
      _companyAnalyticsCache.remove(key);
      _jobEventsCache.remove(key);
      _funnelAnalyticsCache.remove(key);
      _sourceAnalyticsCache.remove(key);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalEntries': _cacheTimestamps.length,
      'companyAnalytics': _companyAnalyticsCache.length,
      'jobEvents': _jobEventsCache.length,
      'funnelAnalytics': _funnelAnalyticsCache.length,
      'sourceAnalytics': _sourceAnalyticsCache.length,
      'oldestEntry': _cacheTimestamps.values.isNotEmpty
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'newestEntry': _cacheTimestamps.values.isNotEmpty
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }
}
