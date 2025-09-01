import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/analytics_data_models.dart';
import '../database/analytics_repository.dart';
import 'analytics_event_service.dart';

/// Comprehensive data aggregation engine for SecuryFlex analytics
/// Handles scheduled aggregation with incremental updates and cost optimization
class AnalyticsAggregationEngine {
  static AnalyticsAggregationEngine? _instance;
  static AnalyticsAggregationEngine get instance {
    _instance ??= AnalyticsAggregationEngine._();
    return _instance!;
  }

  AnalyticsAggregationEngine._();

  final AnalyticsRepository _repository = FirebaseAnalyticsRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsAggregationService _aggregationService = AnalyticsAggregationService.instance;

  // Aggregation state tracking
  final Map<String, DateTime> _lastAggregationTime = {};
  Timer? _scheduledAggregationTimer;
  bool _isAggregating = false;

  /// Initialize scheduled aggregation
  void initializeScheduledAggregation() {
    debugPrint('Initializing scheduled analytics aggregation...');
    
    // Schedule daily aggregation at 2 AM
    _scheduleNextAggregation();
  }

  /// Schedule next aggregation run
  void _scheduleNextAggregation() {
    final now = DateTime.now();
    final nextRun = DateTime(now.year, now.month, now.day + 1, 2, 0); // 2 AM next day
    final delay = nextRun.difference(now);
    
    _scheduledAggregationTimer?.cancel();
    _scheduledAggregationTimer = Timer(delay, () {
      _runScheduledAggregation();
      _scheduleNextAggregation(); // Schedule next run
    });
    
    debugPrint('Next aggregation scheduled for: $nextRun');
  }

  /// Run scheduled aggregation for all companies
  Future<void> _runScheduledAggregation() async {
    if (_isAggregating) {
      debugPrint('Aggregation already in progress, skipping...');
      return;
    }

    _isAggregating = true;
    
    try {
      debugPrint('Starting scheduled analytics aggregation...');
      
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr = yesterday.toIso8601String().split('T')[0];
      
      // Aggregate daily analytics for all companies
      await aggregateDailyAnalytics(dateStr);
      
      // Aggregate weekly analytics if it's Monday
      if (yesterday.weekday == DateTime.monday) {
        await aggregateWeeklyAnalytics(_getWeekIdentifier(yesterday));
      }
      
      // Aggregate monthly analytics if it's the first day of the month
      if (yesterday.day == 1) {
        final previousMonth = DateTime(yesterday.year, yesterday.month - 1);
        await aggregateMonthlyAnalytics(_getMonthIdentifier(previousMonth));
      }
      
      debugPrint('Scheduled analytics aggregation completed successfully');
      
    } catch (e) {
      debugPrint('Error in scheduled aggregation: $e');
    } finally {
      _isAggregating = false;
    }
  }

  /// Aggregate daily analytics for all companies
  Future<void> aggregateDailyAnalytics(String date) async {
    try {
      debugPrint('Aggregating daily analytics for date: $date');
      
      final companies = await _firestore.collection('companies').get();
      final futures = <Future<void>>[];
      
      for (final companyDoc in companies.docs) {
        futures.add(_aggregateCompanyDailyAnalytics(companyDoc.id, date));
      }
      
      // Process companies in parallel with limited concurrency
      await _processConcurrently(futures, maxConcurrency: 5);
      
      debugPrint('Daily analytics aggregation completed for $date');
      
    } catch (e) {
      debugPrint('Error aggregating daily analytics: $e');
      rethrow;
    }
  }

  /// Aggregate weekly analytics for all companies
  Future<void> aggregateWeeklyAnalytics(String week) async {
    try {
      debugPrint('Aggregating weekly analytics for week: $week');
      
      final companies = await _firestore.collection('companies').get();
      
      for (final companyDoc in companies.docs) {
        await _aggregateCompanyWeeklyAnalytics(companyDoc.id, week);
      }
      
      debugPrint('Weekly analytics aggregation completed for $week');
      
    } catch (e) {
      debugPrint('Error aggregating weekly analytics: $e');
      rethrow;
    }
  }

  /// Aggregate monthly analytics for all companies
  Future<void> aggregateMonthlyAnalytics(String month) async {
    try {
      debugPrint('Aggregating monthly analytics for month: $month');
      
      final companies = await _firestore.collection('companies').get();
      
      for (final companyDoc in companies.docs) {
        await _aggregateCompanyMonthlyAnalytics(companyDoc.id, month);
      }
      
      debugPrint('Monthly analytics aggregation completed for $month');
      
    } catch (e) {
      debugPrint('Error aggregating monthly analytics: $e');
      rethrow;
    }
  }

  /// Aggregate daily analytics for a specific company
  Future<void> _aggregateCompanyDailyAnalytics(String companyId, String date) async {
    try {
      // Check if already aggregated recently
      final lastAggregation = _lastAggregationTime['${companyId}_daily_$date'];
      if (lastAggregation != null && 
          DateTime.now().difference(lastAggregation).inHours < 1) {
        return; // Skip if aggregated within last hour
      }
      
      await _aggregationService.aggregateCompanyDailyAnalytics(companyId, date);
      _lastAggregationTime['${companyId}_daily_$date'] = DateTime.now();
      
    } catch (e) {
      debugPrint('Error aggregating daily analytics for company $companyId: $e');
    }
  }

  /// Aggregate weekly analytics for a specific company
  Future<void> _aggregateCompanyWeeklyAnalytics(String companyId, String week) async {
    try {
      // Get daily analytics for the week
      final weekStart = _parseWeekIdentifier(week);
      final weekDays = List.generate(7, (index) => 
        weekStart.add(Duration(days: index)).toIso8601String().split('T')[0]
      );
      
      final dailyAnalyticsList = <CompanyDailyAnalytics>[];
      for (final day in weekDays) {
        final dailyAnalytics = await _repository.getCompanyDailyAnalytics(companyId, day);
        if (dailyAnalytics != null) {
          dailyAnalyticsList.add(dailyAnalytics);
        }
      }
      
      if (dailyAnalyticsList.isEmpty) return;
      
      // Aggregate weekly data
      final weeklyAnalytics = _aggregateWeeklyData(companyId, week, dailyAnalyticsList);
      
      // Save weekly analytics (using daily collection with week identifier)
      await _repository.saveCompanyDailyAnalytics(weeklyAnalytics);
      
    } catch (e) {
      debugPrint('Error aggregating weekly analytics for company $companyId: $e');
    }
  }

  /// Aggregate monthly analytics for a specific company
  Future<void> _aggregateCompanyMonthlyAnalytics(String companyId, String month) async {
    try {
      // Get daily analytics for the month
      final monthStart = _parseMonthIdentifier(month);
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
      
      final startDate = monthStart.toIso8601String().split('T')[0];
      final endDate = monthEnd.toIso8601String().split('T')[0];
      
      final dailyAnalyticsList = await _repository.getCompanyAnalyticsRange(
        companyId, startDate, endDate
      );
      
      if (dailyAnalyticsList.isEmpty) return;
      
      // Aggregate monthly data
      final monthlyAnalytics = _aggregateMonthlyData(companyId, month, dailyAnalyticsList);
      
      // Save monthly analytics (using daily collection with month identifier)
      await _repository.saveCompanyDailyAnalytics(monthlyAnalytics);
      
    } catch (e) {
      debugPrint('Error aggregating monthly analytics for company $companyId: $e');
    }
  }

  /// Aggregate weekly data from daily analytics
  CompanyDailyAnalytics _aggregateWeeklyData(
    String companyId, 
    String week, 
    List<CompanyDailyAnalytics> dailyAnalytics
  ) {
    final totalJobsPosted = dailyAnalytics.fold(0, (total, analytics) => total + analytics.jobsPosted);
    final totalApplications = dailyAnalytics.fold(0, (total, analytics) => total + analytics.totalApplications);
    final totalViews = dailyAnalytics.fold(0, (total, analytics) => total + analytics.jobViews);
    final totalSpend = dailyAnalytics.fold(0.0, (total, analytics) => total + analytics.totalRecruitmentSpend);
    
    final avgViewToApplicationRate = dailyAnalytics.isNotEmpty
        ? dailyAnalytics.fold(0.0, (total, analytics) => total + analytics.viewToApplicationRate) / dailyAnalytics.length
        : 0.0;
    
    final avgApplicationToHireRate = dailyAnalytics.isNotEmpty
        ? dailyAnalytics.fold(0.0, (total, analytics) => total + analytics.applicationToHireRate) / dailyAnalytics.length
        : 0.0;
    
    // Merge source breakdowns
    final Map<String, SourceMetrics> mergedSources = {};
    for (final analytics in dailyAnalytics) {
      for (final entry in analytics.sourceBreakdown.entries) {
        final source = entry.key;
        final metrics = entry.value;
        
        if (mergedSources.containsKey(source)) {
          final existing = mergedSources[source]!;
          mergedSources[source] = SourceMetrics(
            applications: existing.applications + metrics.applications,
            hires: existing.hires + metrics.hires,
            cost: existing.cost + metrics.cost,
          );
        } else {
          mergedSources[source] = metrics;
        }
      }
    }
    
    return CompanyDailyAnalytics(
      date: week, // Use week identifier as date
      companyId: companyId,
      jobsPosted: totalJobsPosted,
      jobsActive: dailyAnalytics.last.jobsActive, // Use latest value
      jobsCompleted: dailyAnalytics.fold(0, (total, analytics) => total + analytics.jobsCompleted),
      jobsCancelled: dailyAnalytics.fold(0, (total, analytics) => total + analytics.jobsCancelled),
      totalApplications: totalApplications,
      applicationsAccepted: dailyAnalytics.fold(0, (total, analytics) => total + analytics.applicationsAccepted),
      applicationsRejected: dailyAnalytics.fold(0, (total, analytics) => total + analytics.applicationsRejected),
      applicationsPending: dailyAnalytics.last.applicationsPending, // Use latest value
      jobViews: totalViews,
      uniqueJobViews: dailyAnalytics.fold(0, (total, analytics) => total + analytics.uniqueJobViews),
      viewToApplicationRate: avgViewToApplicationRate,
      applicationToHireRate: avgApplicationToHireRate,
      averageTimeToFill: dailyAnalytics.isNotEmpty
          ? dailyAnalytics.fold(0.0, (total, analytics) => total + analytics.averageTimeToFill) / dailyAnalytics.length
          : 0.0,
      averageTimeToFirstApplication: dailyAnalytics.isNotEmpty
          ? dailyAnalytics.fold(0.0, (total, analytics) => total + analytics.averageTimeToFirstApplication) / dailyAnalytics.length
          : 0.0,
      totalCostPerHire: dailyAnalytics.isNotEmpty
          ? dailyAnalytics.fold(0.0, (total, analytics) => total + analytics.totalCostPerHire) / dailyAnalytics.length
          : 0.0,
      totalRecruitmentSpend: totalSpend,
      sourceBreakdown: mergedSources,
      averageApplicationQuality: dailyAnalytics.isNotEmpty
          ? dailyAnalytics.fold(0.0, (total, analytics) => total + analytics.averageApplicationQuality) / dailyAnalytics.length
          : 0.0,
      guardRetentionRate: dailyAnalytics.isNotEmpty
          ? dailyAnalytics.fold(0.0, (total, analytics) => total + analytics.guardRetentionRate) / dailyAnalytics.length
          : 0.0,
      updatedAt: DateTime.now(),
    );
  }

  /// Aggregate monthly data from daily analytics
  CompanyDailyAnalytics _aggregateMonthlyData(
    String companyId, 
    String month, 
    List<CompanyDailyAnalytics> dailyAnalytics
  ) {
    // Similar to weekly aggregation but for monthly data
    return _aggregateWeeklyData(companyId, month, dailyAnalytics);
  }

  /// Process futures with limited concurrency
  Future<void> _processConcurrently(List<Future<void>> futures, {int maxConcurrency = 3}) async {
    for (int i = 0; i < futures.length; i += maxConcurrency) {
      final batch = futures.skip(i).take(maxConcurrency);
      await Future.wait(batch, eagerError: false);
    }
  }

  /// Get week identifier (YYYY-WW format)
  String _getWeekIdentifier(DateTime date) {
    final year = date.year;
    final dayOfYear = date.difference(DateTime(year, 1, 1)).inDays + 1;
    final week = ((dayOfYear - date.weekday + 10) / 7).floor();
    return '$year-W${week.toString().padLeft(2, '0')}';
  }

  /// Parse week identifier to DateTime
  DateTime _parseWeekIdentifier(String week) {
    final parts = week.split('-W');
    final year = int.parse(parts[0]);
    final weekNumber = int.parse(parts[1]);
    
    final jan1 = DateTime(year, 1, 1);
    final daysToAdd = (weekNumber - 1) * 7 - jan1.weekday + 1;
    return jan1.add(Duration(days: daysToAdd));
  }

  /// Get month identifier (YYYY-MM format)
  String _getMonthIdentifier(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Parse month identifier to DateTime
  DateTime _parseMonthIdentifier(String month) {
    final parts = month.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
  }

  /// Trigger manual aggregation for a specific company and date range
  Future<void> triggerManualAggregation({
    required String companyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      debugPrint('Triggering manual aggregation for company $companyId from $startDate to $endDate');
      
      final current = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        final dateStr = current.toIso8601String().split('T')[0];
        await _aggregateCompanyDailyAnalytics(companyId, dateStr);
        current.add(const Duration(days: 1));
      }
      
      debugPrint('Manual aggregation completed for company $companyId');
      
    } catch (e) {
      debugPrint('Error in manual aggregation: $e');
      rethrow;
    }
  }

  /// Get aggregation status
  Map<String, dynamic> getAggregationStatus() {
    return {
      'isAggregating': _isAggregating,
      'lastAggregationCount': _lastAggregationTime.length,
      'nextScheduledRun': _scheduledAggregationTimer != null 
          ? DateTime.now().add(Duration(milliseconds: _scheduledAggregationTimer!.tick))
          : null,
    };
  }

  /// Dispose aggregation engine
  void dispose() {
    _scheduledAggregationTimer?.cancel();
    _lastAggregationTime.clear();
    _isAggregating = false;
  }
}
