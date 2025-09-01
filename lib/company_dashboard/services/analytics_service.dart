import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/analytics_data_models.dart';
import '../database/analytics_repository.dart';
import 'analytics_event_service.dart';
import 'analytics_aggregation_engine.dart';
import '../../core/services/firebase_analytics_service.dart';

/// High-level analytics service with intelligent caching and optimization
/// Provides dashboard-ready data with efficient query patterns
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  AnalyticsService._();

  final AnalyticsRepository _repository = FirebaseAnalyticsRepository();
  final AnalyticsEventService _eventService = AnalyticsEventService.instance;
  final AnalyticsAggregationEngine _aggregationEngine = AnalyticsAggregationEngine.instance;

  // Service-level caching for dashboard data
  final Map<String, Map<String, dynamic>> _dashboardCache = {};
  final Map<String, DateTime> _dashboardCacheTimestamps = {};
  static const Duration _dashboardCacheValidDuration = Duration(minutes: 5);

  /// Get comprehensive dashboard data for a company
  Future<Map<String, dynamic>> getCompanyDashboardData(String companyId) async {
    final cacheKey = 'dashboard_$companyId';
    
    // Check dashboard cache
    if (_isDashboardCacheValid(cacheKey)) {
      debugPrint('Returning cached dashboard data for company $companyId');
      return _dashboardCache[cacheKey]!;
    }

    try {
      debugPrint('Loading dashboard data for company $companyId');
      
      // Get current date and recent dates
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];
      final yesterdayStr = today.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
      final weekAgoStr = today.subtract(const Duration(days: 7)).toIso8601String().split('T')[0];
      
      // Fetch data in parallel for performance
      final futures = await Future.wait([
        _repository.getCompanyDailyAnalytics(companyId, todayStr),
        _repository.getCompanyDailyAnalytics(companyId, yesterdayStr),
        _repository.getCompanyAnalyticsRange(companyId, weekAgoStr, todayStr),
        _repository.getFunnelAnalytics(companyId, 'current'),
        _repository.getAllSourceAnalytics(companyId),
      ]);

      final todayAnalytics = futures[0] as CompanyDailyAnalytics?;
      final yesterdayAnalytics = futures[1] as CompanyDailyAnalytics?;
      final weekAnalytics = futures[2] as List<CompanyDailyAnalytics>;
      final funnelAnalytics = futures[3] as RecruitmentFunnelAnalytics?;
      final sourceAnalytics = futures[4] as List<SourceAnalytics>;

      // Calculate dashboard metrics
      final dashboardData = _buildDashboardData(
        companyId: companyId,
        todayAnalytics: todayAnalytics,
        yesterdayAnalytics: yesterdayAnalytics,
        weekAnalytics: weekAnalytics,
        funnelAnalytics: funnelAnalytics,
        sourceAnalytics: sourceAnalytics,
      );

      // Cache the dashboard data
      _dashboardCache[cacheKey] = dashboardData;
      _dashboardCacheTimestamps[cacheKey] = DateTime.now();

      return dashboardData;

    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      return _getEmptyDashboardData(companyId);
    }
  }

  /// Get time-series analytics data for charts
  Future<List<CompanyDailyAnalytics>> getTimeSeriesData({
    required String companyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];
      
      return await _repository.getCompanyAnalyticsRange(companyId, startDateStr, endDateStr);
    } catch (e) {
      debugPrint('Error getting time series data: $e');
      return [];
    }
  }

  /// Get job performance analytics
  Future<Map<String, dynamic>> getJobPerformanceAnalytics(String jobId) async {
    try {
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];
      
      // Get recent job analytics and events
      final futures = await Future.wait([
        _repository.getJobDailyAnalytics(jobId, todayStr),
        _repository.getJobEvents(jobId, limit: 100),
      ]);

      final jobAnalytics = futures[0] as JobDailyAnalytics?;
      final jobEvents = futures[1] as List<JobAnalyticsEvent>;

      return {
        'jobId': jobId,
        'dailyAnalytics': jobAnalytics?.toMap(),
        'totalEvents': jobEvents.length,
        'eventsByType': _groupEventsByType(jobEvents),
        'eventsBySource': _groupEventsBySource(jobEvents),
        'recentEvents': jobEvents.take(10).map((e) => e.toMap()).toList(),
        'performanceScore': _calculateJobPerformanceScore(jobAnalytics, jobEvents),
      };
    } catch (e) {
      debugPrint('Error getting job performance analytics: $e');
      return {'jobId': jobId, 'error': e.toString()};
    }
  }

  /// Get recruitment funnel insights
  Future<Map<String, dynamic>> getRecruitmentFunnelInsights(String companyId) async {
    try {
      final funnelAnalytics = await _repository.getFunnelAnalytics(companyId, 'current');
      
      if (funnelAnalytics == null) {
        return _getEmptyFunnelInsights(companyId);
      }

      return {
        'companyId': companyId,
        'funnelData': funnelAnalytics.toMap(),
        'conversionRates': funnelAnalytics.conversionRates.toMap(),
        'dropOffAnalysis': funnelAnalytics.dropOffPoints.map((p) => p.toMap()).toList(),
        'funnelEfficiency': funnelAnalytics.funnelEfficiency,
        'recommendations': _generateFunnelRecommendations(funnelAnalytics),
      };
    } catch (e) {
      debugPrint('Error getting funnel insights: $e');
      return _getEmptyFunnelInsights(companyId);
    }
  }

  /// Get source effectiveness analysis
  Future<Map<String, dynamic>> getSourceEffectivenessAnalysis(String companyId) async {
    try {
      final sourceAnalytics = await _repository.getAllSourceAnalytics(companyId);
      
      if (sourceAnalytics.isEmpty) {
        return _getEmptySourceAnalysis(companyId);
      }

      // Calculate source rankings and insights
      final rankedSources = sourceAnalytics.toList()
        ..sort((a, b) => b.returnOnInvestment.compareTo(a.returnOnInvestment));

      return {
        'companyId': companyId,
        'totalSources': sourceAnalytics.length,
        'bestPerformingSource': rankedSources.first.toMap(),
        'worstPerformingSource': rankedSources.last.toMap(),
        'sourceRankings': rankedSources.map((s) => s.toMap()).toList(),
        'costAnalysis': _analyzeCosts(sourceAnalytics),
        'qualityAnalysis': _analyzeQuality(sourceAnalytics),
        'recommendations': _generateSourceRecommendations(sourceAnalytics),
      };
    } catch (e) {
      debugPrint('Error getting source effectiveness analysis: $e');
      return _getEmptySourceAnalysis(companyId);
    }
  }

  /// Track analytics event (convenience method)
  Future<void> trackEvent({
    required String jobId,
    required JobEventType eventType,
    String? userId,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    // Track to existing local analytics system
    await _eventService.trackCustomEvent(
      jobId: jobId,
      eventType: eventType,
      userId: userId,
      source: source,
      metadata: metadata,
    );
    
    // Also track to Firebase Analytics for aggregated insights
    try {
      await _trackToFirebaseAnalytics(
        jobId: jobId,
        eventType: eventType,
        userId: userId,
        source: source,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('Failed to track to Firebase Analytics: $e');
      // Don't throw - Firebase Analytics is supplementary
    }
  }
  
  /// Track events to Firebase Analytics for broader insights
  Future<void> _trackToFirebaseAnalytics({
    required String jobId,
    required JobEventType eventType,
    String? userId,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    final firebaseAnalytics = FirebaseAnalyticsService.instance;
    
    // Map JobEventType to Firebase-friendly event names
    String? firebaseEventName;
    Map<String, Object> firebaseParameters = {
      'job_id': jobId,
      'event_category': 'job_marketplace',
      if (userId != null) 'user_id': userId,
      if (source != null) 'source': source,
    };
    
    switch (eventType) {
      case JobEventType.view:
        firebaseEventName = 'view_item';
        firebaseParameters['item_id'] = jobId;
        firebaseParameters['item_category'] = 'security_job';
        break;
      case JobEventType.application:
        firebaseEventName = 'select_content';
        firebaseParameters['content_type'] = 'job_application';
        firebaseParameters['item_id'] = jobId;
        break;
      case JobEventType.completion:
        firebaseEventName = 'achievement_unlocked';
        firebaseParameters['achievement_id'] = 'job_completed';
        firebaseParameters['item_id'] = jobId;
        break;
      case JobEventType.cancellation:
        firebaseEventName = 'remove_from_cart';
        firebaseParameters['item_id'] = jobId;
        firebaseParameters['reason'] = 'cancelled';
        break;
      case JobEventType.view:
        firebaseEventName = 'view_item';
        firebaseParameters['item_category'] = 'user_profile';
        break;
      default:
        firebaseEventName = 'custom_event';
        firebaseParameters['event_type'] = eventType.toString();
        break;
    }
    
    // Add metadata to Firebase parameters
    if (metadata != null) {
      for (final entry in metadata.entries) {
        if (entry.value != null) {
          // Convert to Firebase-compatible types
          if (entry.value is String || entry.value is num || entry.value is bool) {
            firebaseParameters['meta_${entry.key}'] = entry.value;
          } else {
            firebaseParameters['meta_${entry.key}'] = entry.value.toString();
          }
        }
      }
    }
    
    // Track to Firebase Analytics
    await firebaseAnalytics.trackEvent(
      eventName: firebaseEventName,
      parameters: firebaseParameters,
    );
  }

  /// Trigger manual aggregation for a company
  Future<void> triggerAggregation({
    required String companyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final end = endDate ?? DateTime.now();
    
    await _aggregationEngine.triggerManualAggregation(
      companyId: companyId,
      startDate: start,
      endDate: end,
    );
    
    // Clear related caches
    _clearCompanyCaches(companyId);
  }

  /// Build comprehensive dashboard data
  Map<String, dynamic> _buildDashboardData({
    required String companyId,
    CompanyDailyAnalytics? todayAnalytics,
    CompanyDailyAnalytics? yesterdayAnalytics,
    required List<CompanyDailyAnalytics> weekAnalytics,
    RecruitmentFunnelAnalytics? funnelAnalytics,
    required List<SourceAnalytics> sourceAnalytics,
  }) {
    // Calculate trends and changes
    final todayViews = todayAnalytics?.jobViews ?? 0;
    final yesterdayViews = yesterdayAnalytics?.jobViews ?? 0;
    final viewsChange = yesterdayViews > 0 ? ((todayViews - yesterdayViews) / yesterdayViews) * 100 : 0.0;

    final todayApplications = todayAnalytics?.totalApplications ?? 0;
    final yesterdayApplications = yesterdayAnalytics?.totalApplications ?? 0;
    final applicationsChange = yesterdayApplications > 0 ? ((todayApplications - yesterdayApplications) / yesterdayApplications) * 100 : 0.0;

    // Calculate week totals
    final weekTotalViews = weekAnalytics.fold(0, (sum, analytics) => sum + analytics.jobViews);
    final weekTotalApplications = weekAnalytics.fold(0, (sum, analytics) => sum + analytics.totalApplications);
    final weekTotalSpend = weekAnalytics.fold(0.0, (sum, analytics) => sum + analytics.totalRecruitmentSpend);

    return {
      'companyId': companyId,
      'lastUpdated': DateTime.now().toIso8601String(),
      
      // Today's metrics
      'today': {
        'views': todayViews,
        'applications': todayApplications,
        'activeJobs': todayAnalytics?.jobsActive ?? 0,
        'conversionRate': todayAnalytics?.viewToApplicationRate ?? 0.0,
        'spend': todayAnalytics?.totalRecruitmentSpend ?? 0.0,
      },
      
      // Changes from yesterday
      'changes': {
        'views': viewsChange,
        'applications': applicationsChange,
        'trend': viewsChange > 0 ? 'up' : viewsChange < 0 ? 'down' : 'stable',
      },
      
      // Week summary
      'week': {
        'totalViews': weekTotalViews,
        'totalApplications': weekTotalApplications,
        'totalSpend': weekTotalSpend,
        'averageConversionRate': weekAnalytics.isNotEmpty 
            ? weekAnalytics.fold(0.0, (sum, analytics) => sum + analytics.viewToApplicationRate) / weekAnalytics.length
            : 0.0,
      },
      
      // Funnel data
      'funnel': funnelAnalytics?.toMap(),
      
      // Top sources
      'topSources': sourceAnalytics.take(3).map((s) => s.toMap()).toList(),
      
      // Performance indicators
      'performance': {
        'efficiency': todayAnalytics?.recruitmentEfficiencyScore ?? 0.0,
        'qualityScore': todayAnalytics?.averageApplicationQuality ?? 0.0,
        'retentionRate': todayAnalytics?.guardRetentionRate ?? 0.0,
      },
      
      // Time series data for charts
      'timeSeries': weekAnalytics.map((analytics) => {
        'date': analytics.date,
        'views': analytics.jobViews,
        'applications': analytics.totalApplications,
        'conversionRate': analytics.viewToApplicationRate,
      }).toList(),
    };
  }

  /// Group events by type for analysis
  Map<String, int> _groupEventsByType(List<JobAnalyticsEvent> events) {
    final grouped = <String, int>{};
    for (final event in events) {
      final type = event.eventType.name;
      grouped[type] = (grouped[type] ?? 0) + 1;
    }
    return grouped;
  }

  /// Group events by source for analysis
  Map<String, int> _groupEventsBySource(List<JobAnalyticsEvent> events) {
    final grouped = <String, int>{};
    for (final event in events) {
      final source = event.source;
      grouped[source] = (grouped[source] ?? 0) + 1;
    }
    return grouped;
  }

  /// Calculate job performance score
  double _calculateJobPerformanceScore(JobDailyAnalytics? analytics, List<JobAnalyticsEvent> events) {
    if (analytics == null) return 0.0;
    
    final engagementScore = analytics.engagementScore;
    final conversionScore = analytics.viewToApplicationRate;
    final qualityScore = analytics.applicationQualityScore * 20; // Scale to 100
    
    return (engagementScore + conversionScore + qualityScore) / 3;
  }

  /// Generate funnel recommendations
  List<String> _generateFunnelRecommendations(RecruitmentFunnelAnalytics funnel) {
    final recommendations = <String>[];
    
    if (funnel.conversionRates.viewToApplication < 10) {
      recommendations.add('Verbeter job beschrijvingen om meer sollicitaties te genereren');
    }
    
    if (funnel.conversionRates.applicationToInterview < 30) {
      recommendations.add('Optimaliseer het sollicitatieproces voor betere kandidaatselectie');
    }
    
    if (funnel.conversionRates.interviewToHire < 50) {
      recommendations.add('Verbeter het interview- en selectieproces');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Uitstekende funnel prestaties! Behoud de huidige aanpak.');
    }
    
    return recommendations;
  }

  /// Generate source recommendations
  List<String> _generateSourceRecommendations(List<SourceAnalytics> sources) {
    final recommendations = <String>[];
    
    if (sources.isNotEmpty) {
      final bestSource = sources.reduce((a, b) => a.returnOnInvestment > b.returnOnInvestment ? a : b);
      recommendations.add('Focus meer budget op ${bestSource.source} (beste ROI: ${bestSource.returnOnInvestment.toStringAsFixed(1)}%)');
      
      final worstSource = sources.reduce((a, b) => a.returnOnInvestment < b.returnOnInvestment ? a : b);
      if (worstSource.returnOnInvestment < 0) {
        recommendations.add('Overweeg budget te verminderen voor ${worstSource.source} (negatieve ROI)');
      }
    }
    
    return recommendations;
  }

  /// Analyze costs across sources
  Map<String, dynamic> _analyzeCosts(List<SourceAnalytics> sources) {
    if (sources.isEmpty) return {};
    
    final totalSpend = sources.fold(0.0, (sum, source) => sum + source.totalSpend);
    final avgCostPerHire = sources.fold(0.0, (sum, source) => sum + source.costPerHire) / sources.length;
    
    return {
      'totalSpend': totalSpend,
      'averageCostPerHire': avgCostPerHire,
      'mostExpensive': sources.reduce((a, b) => a.costPerHire > b.costPerHire ? a : b).source,
      'mostCostEffective': sources.reduce((a, b) => a.costPerHire < b.costPerHire ? a : b).source,
    };
  }

  /// Analyze quality across sources
  Map<String, dynamic> _analyzeQuality(List<SourceAnalytics> sources) {
    if (sources.isEmpty) return {};
    
    final avgQuality = sources.fold(0.0, (sum, source) => sum + source.averageApplicationQuality) / sources.length;
    final avgRetention = sources.fold(0.0, (sum, source) => sum + source.guardRetentionRate) / sources.length;
    
    return {
      'averageQuality': avgQuality,
      'averageRetention': avgRetention,
      'highestQuality': sources.reduce((a, b) => a.averageApplicationQuality > b.averageApplicationQuality ? a : b).source,
      'bestRetention': sources.reduce((a, b) => a.guardRetentionRate > b.guardRetentionRate ? a : b).source,
    };
  }

  /// Check if dashboard cache is valid
  bool _isDashboardCacheValid(String cacheKey) {
    final timestamp = _dashboardCacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _dashboardCacheValidDuration;
  }

  /// Clear company-specific caches
  void _clearCompanyCaches(String companyId) {
    final keysToRemove = _dashboardCache.keys.where((key) => key.contains(companyId)).toList();
    for (final key in keysToRemove) {
      _dashboardCache.remove(key);
      _dashboardCacheTimestamps.remove(key);
    }
    
    // Also clear repository cache
    if (_repository is FirebaseAnalyticsRepository) {
      (_repository).clearCache();
    }
  }

  /// Get empty dashboard data
  Map<String, dynamic> _getEmptyDashboardData(String companyId) {
    return {
      'companyId': companyId,
      'lastUpdated': DateTime.now().toIso8601String(),
      'today': {'views': 0, 'applications': 0, 'activeJobs': 0, 'conversionRate': 0.0, 'spend': 0.0},
      'changes': {'views': 0.0, 'applications': 0.0, 'trend': 'stable'},
      'week': {'totalViews': 0, 'totalApplications': 0, 'totalSpend': 0.0, 'averageConversionRate': 0.0},
      'funnel': null,
      'topSources': [],
      'performance': {'efficiency': 0.0, 'qualityScore': 0.0, 'retentionRate': 0.0},
      'timeSeries': [],
    };
  }

  /// Get empty funnel insights
  Map<String, dynamic> _getEmptyFunnelInsights(String companyId) {
    return {
      'companyId': companyId,
      'funnelData': null,
      'conversionRates': null,
      'dropOffAnalysis': [],
      'funnelEfficiency': 0.0,
      'recommendations': ['Geen data beschikbaar voor funnel analyse'],
    };
  }

  /// Get empty source analysis
  Map<String, dynamic> _getEmptySourceAnalysis(String companyId) {
    return {
      'companyId': companyId,
      'totalSources': 0,
      'bestPerformingSource': null,
      'worstPerformingSource': null,
      'sourceRankings': [],
      'costAnalysis': {},
      'qualityAnalysis': {},
      'recommendations': ['Geen data beschikbaar voor bron analyse'],
    };
  }

  /// Clear all caches
  void clearAllCaches() {
    _dashboardCache.clear();
    _dashboardCacheTimestamps.clear();
    
    if (_repository is FirebaseAnalyticsRepository) {
      (_repository).clearCache();
    }
  }

  /// Get service statistics
  Map<String, dynamic> getServiceStats() {
    return {
      'dashboardCacheSize': _dashboardCache.length,
      'repositoryStats': _repository is FirebaseAnalyticsRepository 
          ? (_repository).getCacheStats()
          : {},
      'eventServiceStats': _eventService.getQueueStatus(),
      'aggregationStats': _aggregationEngine.getAggregationStatus(),
    };
  }
}
