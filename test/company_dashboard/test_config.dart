import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:securyflex_app/company_dashboard/models/analytics_data_models.dart';
import 'package:securyflex_app/company_dashboard/services/analytics_service.dart';
import 'package:securyflex_app/company_dashboard/database/analytics_repository.dart';

/// Test configuration and utilities for SecuryFlex Analytics tests
/// Provides common test data, mocks, and helper functions
/// Ensures consistent testing patterns across all analytics tests

class AnalyticsTestConfig {
  static const String testCompanyId = 'test_company_123';
  static const String testJobId = 'test_job_456';
  static const String testUserId = 'test_user_789';
  static const String testApplicationId = 'test_app_101';
  
  /// Create test company daily analytics
  static CompanyDailyAnalytics createTestCompanyAnalytics({
    String? date,
    String? companyId,
    int? jobsPosted,
    int? totalApplications,
    int? jobViews,
  }) {
    return CompanyDailyAnalytics(
      date: date ?? '2024-01-15',
      companyId: companyId ?? testCompanyId,
      jobsPosted: jobsPosted ?? 5,
      jobsActive: 3,
      jobsCompleted: 2,
      jobsCancelled: 0,
      totalApplications: totalApplications ?? 25,
      applicationsAccepted: 8,
      applicationsRejected: 12,
      applicationsPending: 5,
      jobViews: jobViews ?? 150,
      uniqueJobViews: 120,
      viewToApplicationRate: 16.67,
      applicationToHireRate: 32.0,
      averageTimeToFill: 48.0,
      averageTimeToFirstApplication: 24.0,
      totalCostPerHire: 75.0,
      totalRecruitmentSpend: 600.0,
      sourceBreakdown: {
        'search': SourceMetrics(applications: 15, hires: 5, cost: 300.0),
        'direct': SourceMetrics(applications: 10, hires: 3, cost: 300.0),
      },
      averageApplicationQuality: 3.8,
      guardRetentionRate: 85.0,
      updatedAt: DateTime.now(),
    );
  }

  /// Create test job analytics event
  static JobAnalyticsEvent createTestJobEvent({
    String? eventId,
    String? jobId,
    JobEventType? eventType,
    DateTime? timestamp,
    String? userId,
    String? source,
  }) {
    return JobAnalyticsEvent(
      eventId: eventId ?? 'evt_test_123',
      jobId: jobId ?? testJobId,
      eventType: eventType ?? JobEventType.view,
      timestamp: timestamp ?? DateTime.now(),
      userId: userId ?? testUserId,
      userRole: 'guard',
      source: source ?? 'search',
      deviceType: 'mobile',
      location: 'Amsterdam',
      sessionDuration: 120,
      pageLoadTime: 500,
      metadata: {
        'platform': 'test',
        'version': '1.0.0',
      },
    );
  }

  /// Create test job daily analytics
  static JobDailyAnalytics createTestJobAnalytics({
    String? date,
    String? jobId,
    String? companyId,
    int? totalViews,
    int? newApplications,
  }) {
    return JobDailyAnalytics(
      date: date ?? '2024-01-15',
      jobId: jobId ?? testJobId,
      companyId: companyId ?? testCompanyId,
      totalViews: totalViews ?? 100,
      uniqueViews: 80,
      averageViewDuration: 45.0,
      bounceRate: 35.0,
      newApplications: newApplications ?? 10,
      totalApplications: 10,
      applicationQualityScore: 3.5,
      viewToApplicationRate: 10.0,
      applicationToResponseRate: 85.0,
      searchRanking: 5,
      recommendationScore: 0.7,
      competitiveIndex: 0.6,
      viewsByLocation: {
        'Amsterdam': 40,
        'Rotterdam': 30,
        'Utrecht': 20,
        'Den Haag': 10,
      },
      viewsByHour: List.generate(24, (index) => index < 8 || index > 18 ? 2 : 6),
      peakViewingHours: ['09:00', '14:00', '20:00'],
      updatedAt: DateTime.now(),
    );
  }

  /// Create test source analytics
  static SourceAnalytics createTestSourceAnalytics({
    String? source,
    String? companyId,
    int? totalViews,
    int? totalApplications,
    int? totalHires,
  }) {
    return SourceAnalytics(
      source: source ?? 'search',
      companyId: companyId ?? testCompanyId,
      totalViews: totalViews ?? 1000,
      totalApplications: totalApplications ?? 100,
      totalHires: totalHires ?? 20,
      averageApplicationQuality: 4.0,
      averageGuardRating: 4.5,
      guardRetentionRate: 90.0,
      costPerView: 0.50,
      costPerApplication: 5.0,
      costPerHire: 50.0,
      totalSpend: 1000.0,
      averageTimeToApplication: 24.0,
      averageTimeToHire: 72.0,
      dailyMetrics: {
        '2024-01-15': DailySourceMetrics(
          views: 50,
          applications: 5,
          hires: 1,
          cost: 50.0,
        ),
      },
      lastUpdated: DateTime.now(),
    );
  }

  /// Create test funnel analytics data
  static Map<String, dynamic> createTestFunnelAnalytics({
    String? period,
    String? companyId,
  }) {
    return {
      'period': period ?? 'current',
      'companyId': companyId ?? testCompanyId,
      'posted': {'count': 10},
      'viewed': {'count': 500},
      'applied': {'count': 50},
      'interviewed': {'count': 25},
      'hired': {'count': 10},
      'conversionRates': {
        'viewToApplication': 10.0, // 50/500 * 100
        'applicationToInterview': 50.0, // 25/50 * 100
        'interviewToHire': 40.0, // 10/25 * 100
        'overallConversion': 2.0, // 10/500 * 100
      },
      'dropOffPoints': [
        {
          'stage': 'viewed',
          'dropOffRate': 90.0,
          'commonReasons': ['Job requirements too high', 'Location not suitable'],
          'recommendations': ['Adjust requirements', 'Offer remote work'],
        },
        {
          'stage': 'interviewed',
          'dropOffRate': 60.0,
          'commonReasons': ['Salary expectations not met', 'Better offer elsewhere'],
          'recommendations': ['Review salary ranges', 'Improve interview process'],
        },
      ],
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create test dashboard data
  static Map<String, dynamic> createTestDashboardData({
    String? companyId,
  }) {
    return {
      'companyId': companyId ?? testCompanyId,
      'lastUpdated': DateTime.now().toIso8601String(),
      'today': {
        'views': 100,
        'applications': 15,
        'activeJobs': 5,
        'conversionRate': 15.0,
        'spend': 250.0,
      },
      'changes': {
        'views': 12.5,
        'applications': -8.3,
        'trend': 'up',
      },
      'week': {
        'totalViews': 700,
        'totalApplications': 105,
        'totalSpend': 1750.0,
        'averageConversionRate': 15.0,
      },
      'funnel': createTestFunnelAnalytics(),
      'topSources': [
        createTestSourceAnalytics(source: 'search').toMap(),
        createTestSourceAnalytics(source: 'direct').toMap(),
        createTestSourceAnalytics(source: 'recommendation').toMap(),
      ],
      'performance': {
        'efficiency': 75.0,
        'qualityScore': 4.2,
        'retentionRate': 85.0,
      },
      'timeSeries': List.generate(7, (i) => {
        'date': DateTime.now().subtract(Duration(days: 6 - i)).toIso8601String().split('T')[0],
        'views': 100 + (i * 10),
        'applications': 15 + (i * 2),
        'conversionRate': 15.0 + (i * 0.5),
      }),
    };
  }

  /// Create mock test data structure
  static Map<String, dynamic> createMockFirestoreData() {
    return {
      'companies': {
        testCompanyId: {
          'companyName': 'Test Company',
          'totalJobsPosted': 10,
          'activeJobs': 5,
          'completedJobs': 5,
          'totalSpent': 2500.0,
          'totalGuardsHired': 15,
          'averageJobValue': 250.0,
          'averageRating': 4.2,
        }
      },
      'jobs': {
        testJobId: {
          'companyId': testCompanyId,
          'title': 'Test Security Job',
          'status': 'active',
          'createdDate': DateTime.now(),
          'applicationsCount': 10,
        }
      },
      'applications': {
        testApplicationId: {
          'jobId': testJobId,
          'companyName': 'Test Company',
          'applicantEmail': 'test@example.com',
          'status': 'pending',
          'applicationDate': DateTime.now(),
        }
      },
    };
  }

  /// Create mock analytics service with test data
  static MockAnalyticsService createMockAnalyticsService() {
    final mockService = MockAnalyticsService();

    // Setup default mock responses
    when(() => mockService.getCompanyDashboardData(any()))
        .thenAnswer((_) async => createTestDashboardData());

    when(() => mockService.getTimeSeriesData(
      companyId: any(named: 'companyId'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    )).thenAnswer((_) async => [createTestCompanyAnalytics()]);

    when(() => mockService.getJobPerformanceAnalytics(any()))
        .thenAnswer((_) async => {
          'jobId': testJobId,
          'dailyAnalytics': createTestJobAnalytics().toMap(),
          'totalEvents': 5,
          'performanceScore': 75.0,
        });

    when(() => mockService.getSourceEffectivenessAnalysis(any()))
        .thenAnswer((_) async => {
          'companyId': testCompanyId,
          'totalSources': 3,
          'bestPerformingSource': createTestSourceAnalytics(source: 'search').toMap(),
          'sourceRankings': [
            createTestSourceAnalytics(source: 'search').toMap(),
            createTestSourceAnalytics(source: 'direct').toMap(),
            createTestSourceAnalytics(source: 'recommendation').toMap(),
          ],
          'recommendations': ['Focus more budget on search', 'Improve direct traffic'],
        });

    return mockService;
  }

  /// Performance test helpers
  static void expectPerformance(Duration actual, Duration expected, {String? operation}) {
    final message = operation != null 
        ? '$operation took ${actual.inMilliseconds}ms (expected < ${expected.inMilliseconds}ms)'
        : 'Operation took ${actual.inMilliseconds}ms (expected < ${expected.inMilliseconds}ms)';
    
    expect(actual, lessThan(expected), reason: message);
  }

  /// Memory usage helpers
  static void expectMemoryUsage(int actualMB, int expectedMB, {String? operation}) {
    final message = operation != null
        ? '$operation used ${actualMB}MB (expected < ${expectedMB}MB)'
        : 'Operation used ${actualMB}MB (expected < ${expectedMB}MB)';
    
    expect(actualMB, lessThan(expectedMB), reason: message);
  }

  /// Test data validation helpers
  static void validateCompanyAnalytics(CompanyDailyAnalytics analytics) {
    expect(analytics.date, isNotEmpty);
    expect(analytics.companyId, isNotEmpty);
    expect(analytics.jobsPosted, greaterThanOrEqualTo(0));
    expect(analytics.totalApplications, greaterThanOrEqualTo(0));
    expect(analytics.jobViews, greaterThanOrEqualTo(0));
    expect(analytics.viewToApplicationRate, greaterThanOrEqualTo(0));
    expect(analytics.applicationToHireRate, greaterThanOrEqualTo(0));
    expect(analytics.averageApplicationQuality, greaterThanOrEqualTo(0));
    expect(analytics.guardRetentionRate, greaterThanOrEqualTo(0));
  }

  static void validateJobEvent(JobAnalyticsEvent event) {
    expect(event.eventId, isNotEmpty);
    expect(event.jobId, isNotEmpty);
    expect(event.timestamp, isNotNull);
    expect(event.userRole, isNotEmpty);
    expect(event.source, isNotEmpty);
    expect(event.deviceType, isNotEmpty);
  }

  static void validateSourceAnalytics(SourceAnalytics analytics) {
    expect(analytics.source, isNotEmpty);
    expect(analytics.companyId, isNotEmpty);
    expect(analytics.totalViews, greaterThanOrEqualTo(0));
    expect(analytics.totalApplications, greaterThanOrEqualTo(0));
    expect(analytics.totalHires, greaterThanOrEqualTo(0));
    expect(analytics.costPerView, greaterThanOrEqualTo(0));
    expect(analytics.costPerApplication, greaterThanOrEqualTo(0));
    expect(analytics.costPerHire, greaterThanOrEqualTo(0));
  }
}

/// Mock classes for testing
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockAnalyticsRepository extends Mock implements AnalyticsRepository {}
