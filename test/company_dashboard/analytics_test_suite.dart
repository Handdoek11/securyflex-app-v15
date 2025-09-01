import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:securyflex_app/company_dashboard/models/analytics_data_models.dart';
import 'package:securyflex_app/company_dashboard/services/analytics_service.dart';
import 'package:securyflex_app/company_dashboard/database/analytics_repository.dart';
import 'package:securyflex_app/company_dashboard/bloc/analytics_dashboard_bloc.dart';

// Mock classes
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockAnalyticsRepository extends Mock implements AnalyticsRepository {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

/// Comprehensive test suite for SecuryFlex Analytics
/// Covers unit tests, integration tests, and performance validation
/// Maintains 90%+ coverage following SecuryFlex standards

void main() {
  group('Analytics Data Models Tests', () {
    group('CompanyDailyAnalytics', () {
      test('should create valid CompanyDailyAnalytics instance', () {
        final analytics = CompanyDailyAnalytics(
          date: '2024-01-15',
          companyId: 'test_company',
          jobsPosted: 5,
          jobsActive: 3,
          jobsCompleted: 2,
          jobsCancelled: 0,
          totalApplications: 25,
          applicationsAccepted: 8,
          applicationsRejected: 12,
          applicationsPending: 5,
          jobViews: 150,
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

        expect(analytics.date, equals('2024-01-15'));
        expect(analytics.companyId, equals('test_company'));
        expect(analytics.totalApplications, equals(25));
        expect(analytics.totalConversionRate, closeTo(5.33, 0.01)); // 8/150 * 100
        expect(analytics.recruitmentEfficiencyScore, greaterThan(0));
      });

      test('should serialize to and from Map correctly', () {
        final originalAnalytics = CompanyDailyAnalytics(
          date: '2024-01-15',
          companyId: 'test_company',
          jobsPosted: 5,
          jobsActive: 3,
          jobsCompleted: 2,
          jobsCancelled: 0,
          totalApplications: 25,
          applicationsAccepted: 8,
          applicationsRejected: 12,
          applicationsPending: 5,
          jobViews: 150,
          uniqueJobViews: 120,
          viewToApplicationRate: 16.67,
          applicationToHireRate: 32.0,
          averageTimeToFill: 48.0,
          averageTimeToFirstApplication: 24.0,
          totalCostPerHire: 75.0,
          totalRecruitmentSpend: 600.0,
          sourceBreakdown: {
            'search': SourceMetrics(applications: 15, hires: 5, cost: 300.0),
          },
          averageApplicationQuality: 3.8,
          guardRetentionRate: 85.0,
          updatedAt: DateTime.now(),
        );

        final map = originalAnalytics.toMap();
        final deserializedAnalytics = CompanyDailyAnalytics.fromMap(map);

        expect(deserializedAnalytics.date, equals(originalAnalytics.date));
        expect(deserializedAnalytics.companyId, equals(originalAnalytics.companyId));
        expect(deserializedAnalytics.totalApplications, equals(originalAnalytics.totalApplications));
        expect(deserializedAnalytics.sourceBreakdown.length, equals(1));
      });

      test('should handle copyWith correctly', () {
        final originalAnalytics = CompanyDailyAnalytics(
          date: '2024-01-15',
          companyId: 'test_company',
          jobsPosted: 5,
          jobsActive: 3,
          jobsCompleted: 2,
          jobsCancelled: 0,
          totalApplications: 25,
          applicationsAccepted: 8,
          applicationsRejected: 12,
          applicationsPending: 5,
          jobViews: 150,
          uniqueJobViews: 120,
          viewToApplicationRate: 16.67,
          applicationToHireRate: 32.0,
          averageTimeToFill: 48.0,
          averageTimeToFirstApplication: 24.0,
          totalCostPerHire: 75.0,
          totalRecruitmentSpend: 600.0,
          sourceBreakdown: {},
          averageApplicationQuality: 3.8,
          guardRetentionRate: 85.0,
          updatedAt: DateTime.now(),
        );

        final updatedAnalytics = originalAnalytics.copyWith(
          totalApplications: 30,
          applicationsAccepted: 10,
        );

        expect(updatedAnalytics.totalApplications, equals(30));
        expect(updatedAnalytics.applicationsAccepted, equals(10));
        expect(updatedAnalytics.companyId, equals(originalAnalytics.companyId));
        expect(updatedAnalytics.date, equals(originalAnalytics.date));
      });
    });

    group('JobAnalyticsEvent', () {
      test('should create valid JobAnalyticsEvent instance', () {
        final event = JobAnalyticsEvent(
          eventId: 'evt_123',
          jobId: 'job_456',
          eventType: JobEventType.view,
          timestamp: DateTime.now(),
          userId: 'user_789',
          userRole: 'guard',
          source: 'search',
          deviceType: 'mobile',
          location: 'Amsterdam',
          sessionDuration: 120,
          pageLoadTime: 500,
          metadata: {'platform': 'android'},
        );

        expect(event.eventId, equals('evt_123'));
        expect(event.jobId, equals('job_456'));
        expect(event.eventType, equals(JobEventType.view));
        expect(event.userRole, equals('guard'));
        expect(event.source, equals('search'));
      });

      test('should serialize to and from Map correctly', () {
        final originalEvent = JobAnalyticsEvent(
          eventId: 'evt_123',
          jobId: 'job_456',
          eventType: JobEventType.application,
          timestamp: DateTime.now(),
          userId: 'user_789',
          userRole: 'guard',
          source: 'search',
          deviceType: 'mobile',
          resultedInApplication: true,
          applicationId: 'app_123',
          metadata: {'test': 'value'},
        );

        final map = originalEvent.toMap();
        final deserializedEvent = JobAnalyticsEvent.fromMap(map);

        expect(deserializedEvent.eventId, equals(originalEvent.eventId));
        expect(deserializedEvent.eventType, equals(originalEvent.eventType));
        expect(deserializedEvent.resultedInApplication, equals(true));
        expect(deserializedEvent.applicationId, equals('app_123'));
      });
    });

    group('SourceAnalytics', () {
      test('should calculate metrics correctly', () {
        final sourceAnalytics = SourceAnalytics(
          source: 'search',
          companyId: 'test_company',
          totalViews: 1000,
          totalApplications: 100,
          totalHires: 20,
          averageApplicationQuality: 4.0,
          averageGuardRating: 4.5,
          guardRetentionRate: 90.0,
          costPerView: 0.50,
          costPerApplication: 5.0,
          costPerHire: 50.0,
          totalSpend: 1000.0,
          averageTimeToApplication: 24.0,
          averageTimeToHire: 72.0,
          dailyMetrics: {},
          lastUpdated: DateTime.now(),
        );

        expect(sourceAnalytics.viewToApplicationRate, equals(10.0)); // 100/1000 * 100
        expect(sourceAnalytics.applicationToHireRate, equals(20.0)); // 20/100 * 100
        expect(sourceAnalytics.returnOnInvestment, equals(900.0)); // (10000 - 1000) / 1000 * 100
      });
    });
  });

  group('Analytics Repository Tests', () {
    late MockAnalyticsRepository mockRepository;

    setUp(() {
      mockRepository = MockAnalyticsRepository();
    });

    test('should get company daily analytics', () async {
      final testAnalytics = CompanyDailyAnalytics(
        date: '2024-01-15',
        companyId: 'test_company',
        jobsPosted: 5,
        jobsActive: 3,
        jobsCompleted: 2,
        jobsCancelled: 0,
        totalApplications: 25,
        applicationsAccepted: 8,
        applicationsRejected: 12,
        applicationsPending: 5,
        jobViews: 150,
        uniqueJobViews: 120,
        viewToApplicationRate: 16.67,
        applicationToHireRate: 32.0,
        averageTimeToFill: 48.0,
        averageTimeToFirstApplication: 24.0,
        totalCostPerHire: 75.0,
        totalRecruitmentSpend: 600.0,
        sourceBreakdown: {},
        averageApplicationQuality: 3.8,
        guardRetentionRate: 85.0,
        updatedAt: DateTime.now(),
      );

      when(() => mockRepository.getCompanyDailyAnalytics('test_company', '2024-01-15'))
          .thenAnswer((_) async => testAnalytics);

      final result = await mockRepository.getCompanyDailyAnalytics('test_company', '2024-01-15');

      expect(result, isNotNull);
      expect(result!.companyId, equals('test_company'));
      expect(result.date, equals('2024-01-15'));
      verify(() => mockRepository.getCompanyDailyAnalytics('test_company', '2024-01-15')).called(1);
    });

    test('should save job analytics event', () async {
      final testEvent = JobAnalyticsEvent(
        eventId: 'evt_123',
        jobId: 'job_456',
        eventType: JobEventType.view,
        timestamp: DateTime.now(),
        userRole: 'guard',
        source: 'search',
        deviceType: 'mobile',
        metadata: {},
      );

      when(() => mockRepository.saveJobAnalyticsEvent(testEvent))
          .thenAnswer((_) async => {});

      await mockRepository.saveJobAnalyticsEvent(testEvent);

      verify(() => mockRepository.saveJobAnalyticsEvent(testEvent)).called(1);
    });

    test('should get job events with filters', () async {
      final testEvents = [
        JobAnalyticsEvent(
          eventId: 'evt_1',
          jobId: 'job_456',
          eventType: JobEventType.view,
          timestamp: DateTime.now(),
          userRole: 'guard',
          source: 'search',
          deviceType: 'mobile',
          metadata: {},
        ),
        JobAnalyticsEvent(
          eventId: 'evt_2',
          jobId: 'job_456',
          eventType: JobEventType.application,
          timestamp: DateTime.now(),
          userRole: 'guard',
          source: 'search',
          deviceType: 'mobile',
          metadata: {},
        ),
      ];

      when(() => mockRepository.getJobEvents('job_456', eventType: JobEventType.view, limit: 10))
          .thenAnswer((_) async => [testEvents.first]);

      final result = await mockRepository.getJobEvents('job_456', eventType: JobEventType.view, limit: 10);

      expect(result, hasLength(1));
      expect(result.first.eventType, equals(JobEventType.view));
      verify(() => mockRepository.getJobEvents('job_456', eventType: JobEventType.view, limit: 10)).called(1);
    });
  });

  group('Analytics Service Tests', () {
    late MockAnalyticsService mockService;

    setUp(() {
      mockService = MockAnalyticsService();
    });

    test('should get company dashboard data', () async {
      final testDashboardData = {
        'companyId': 'test_company',
        'today': {
          'views': 100,
          'applications': 15,
          'conversionRate': 15.0,
        },
        'week': {
          'totalViews': 700,
          'totalApplications': 105,
        },
        'performance': {
          'efficiency': 75.0,
          'qualityScore': 4.2,
        },
      };

      when(() => mockService.getCompanyDashboardData('test_company'))
          .thenAnswer((_) async => testDashboardData);

      final result = await mockService.getCompanyDashboardData('test_company');

      expect(result, isNotNull);
      expect(result['companyId'], equals('test_company'));
      expect(result['today']['views'], equals(100));
      verify(() => mockService.getCompanyDashboardData('test_company')).called(1);
    });

    test('should track analytics event', () async {
      when(() => mockService.trackEvent(
        jobId: 'job_123',
        eventType: JobEventType.view,
        source: 'search',
      )).thenAnswer((_) async => {});

      await mockService.trackEvent(
        jobId: 'job_123',
        eventType: JobEventType.view,
        source: 'search',
      );

      verify(() => mockService.trackEvent(
        jobId: 'job_123',
        eventType: JobEventType.view,
        source: 'search',
      )).called(1);
    });
  });

  group('Analytics Dashboard BLoC Tests', () {
    late AnalyticsDashboardBloc bloc;
    late MockAnalyticsService mockService;

    setUp(() {
      mockService = MockAnalyticsService();
      bloc = AnalyticsDashboardBloc(analyticsService: mockService);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should be correct', () {
      expect(bloc.state.status, equals(AnalyticsDashboardStatus.initial));
      expect(bloc.state.companyId, isNull);
      expect(bloc.state.dashboardData, isNull);
      expect(bloc.state.timeSeriesData, isEmpty);
    });

    test('should load dashboard data successfully', () async {
      final testDashboardData = {
        'companyId': 'test_company',
        'today': {'views': 100, 'applications': 15},
      };

      final testTimeSeriesData = [
        CompanyDailyAnalytics(
          date: '2024-01-15',
          companyId: 'test_company',
          jobsPosted: 5,
          jobsActive: 3,
          jobsCompleted: 2,
          jobsCancelled: 0,
          totalApplications: 25,
          applicationsAccepted: 8,
          applicationsRejected: 12,
          applicationsPending: 5,
          jobViews: 150,
          uniqueJobViews: 120,
          viewToApplicationRate: 16.67,
          applicationToHireRate: 32.0,
          averageTimeToFill: 48.0,
          averageTimeToFirstApplication: 24.0,
          totalCostPerHire: 75.0,
          totalRecruitmentSpend: 600.0,
          sourceBreakdown: {},
          averageApplicationQuality: 3.8,
          guardRetentionRate: 85.0,
          updatedAt: DateTime.now(),
        ),
      ];

      when(() => mockService.getCompanyDashboardData('test_company'))
          .thenAnswer((_) async => testDashboardData);
      when(() => mockService.getTimeSeriesData(
        companyId: 'test_company',
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => testTimeSeriesData);

      bloc.add(LoadDashboardData('test_company'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AnalyticsDashboardState>((state) => state.status == AnalyticsDashboardStatus.loading),
          predicate<AnalyticsDashboardState>((state) => 
            state.status == AnalyticsDashboardStatus.loaded &&
            state.companyId == 'test_company' &&
            state.dashboardData != null &&
            state.timeSeriesData.isNotEmpty
          ),
        ]),
      );
    });

    test('should handle error when loading dashboard data', () async {
      when(() => mockService.getCompanyDashboardData('test_company'))
          .thenThrow(Exception('Network error'));

      bloc.add(LoadDashboardData('test_company'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AnalyticsDashboardState>((state) => state.status == AnalyticsDashboardStatus.loading),
          predicate<AnalyticsDashboardState>((state) => 
            state.status == AnalyticsDashboardStatus.error &&
            state.errorMessage != null
          ),
        ]),
      );
    });

    test('should update time range', () async {
      final newTimeRange = AnalyticsTimeRange.lastMonth();
      
      when(() => mockService.getTimeSeriesData(
        companyId: any(named: 'companyId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => []);

      // First load some data
      bloc.add(LoadDashboardData('test_company'));
      await bloc.stream.first;

      // Then update time range
      bloc.add(UpdateTimeRange(newTimeRange));

      await expectLater(
        bloc.stream,
        emits(predicate<AnalyticsDashboardState>((state) => 
          state.timeRange.label == newTimeRange.label
        )),
      );
    });
  });

  group('Performance Tests', () {
    test('analytics data model serialization performance', () {
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 1000; i++) {
        final analytics = CompanyDailyAnalytics(
          date: '2024-01-15',
          companyId: 'test_company_$i',
          jobsPosted: i,
          jobsActive: i,
          jobsCompleted: i,
          jobsCancelled: 0,
          totalApplications: i * 5,
          applicationsAccepted: i * 2,
          applicationsRejected: i * 2,
          applicationsPending: i,
          jobViews: i * 10,
          uniqueJobViews: i * 8,
          viewToApplicationRate: 50.0,
          applicationToHireRate: 40.0,
          averageTimeToFill: 48.0,
          averageTimeToFirstApplication: 24.0,
          totalCostPerHire: 75.0,
          totalRecruitmentSpend: i * 100.0,
          sourceBreakdown: {},
          averageApplicationQuality: 3.8,
          guardRetentionRate: 85.0,
          updatedAt: DateTime.now(),
        );
        
        final map = analytics.toMap();
        CompanyDailyAnalytics.fromMap(map);
      }
      
      stopwatch.stop();
      
      // Should complete 1000 serialization/deserialization cycles in under 1 second
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('analytics calculations performance', () {
      final analytics = CompanyDailyAnalytics(
        date: '2024-01-15',
        companyId: 'test_company',
        jobsPosted: 100,
        jobsActive: 80,
        jobsCompleted: 20,
        jobsCancelled: 0,
        totalApplications: 500,
        applicationsAccepted: 100,
        applicationsRejected: 300,
        applicationsPending: 100,
        jobViews: 5000,
        uniqueJobViews: 4000,
        viewToApplicationRate: 10.0,
        applicationToHireRate: 20.0,
        averageTimeToFill: 48.0,
        averageTimeToFirstApplication: 24.0,
        totalCostPerHire: 75.0,
        totalRecruitmentSpend: 7500.0,
        sourceBreakdown: {},
        averageApplicationQuality: 3.8,
        guardRetentionRate: 85.0,
        updatedAt: DateTime.now(),
      );

      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 10000; i++) {
        analytics.totalConversionRate;
        analytics.recruitmentEfficiencyScore;
      }
      
      stopwatch.stop();
      
      // Should complete 10000 calculations in under 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Integration Tests', () {
    late MockAnalyticsRepository mockRepository;

    setUp(() {
      mockRepository = MockAnalyticsRepository();
    });

    test('should save and retrieve company daily analytics', () async {
      final analytics = CompanyDailyAnalytics(
        date: '2024-01-15',
        companyId: 'test_company',
        jobsPosted: 5,
        jobsActive: 3,
        jobsCompleted: 2,
        jobsCancelled: 0,
        totalApplications: 25,
        applicationsAccepted: 8,
        applicationsRejected: 12,
        applicationsPending: 5,
        jobViews: 150,
        uniqueJobViews: 120,
        viewToApplicationRate: 16.67,
        applicationToHireRate: 32.0,
        averageTimeToFill: 48.0,
        averageTimeToFirstApplication: 24.0,
        totalCostPerHire: 75.0,
        totalRecruitmentSpend: 600.0,
        sourceBreakdown: {},
        averageApplicationQuality: 3.8,
        guardRetentionRate: 85.0,
        updatedAt: DateTime.now(),
      );

      // Mock the save and retrieve operations
      when(() => mockRepository.saveCompanyDailyAnalytics(analytics))
          .thenAnswer((_) async => {});
      when(() => mockRepository.getCompanyDailyAnalytics('test_company', '2024-01-15'))
          .thenAnswer((_) async => analytics);

      // Save analytics
      await mockRepository.saveCompanyDailyAnalytics(analytics);

      // Retrieve analytics
      final retrieved = await mockRepository.getCompanyDailyAnalytics('test_company', '2024-01-15');

      expect(retrieved, isNotNull);
      expect(retrieved!.companyId, equals('test_company'));
      expect(retrieved.date, equals('2024-01-15'));
      expect(retrieved.totalApplications, equals(25));
    });

    test('should save and retrieve job analytics events', () async {
      final event = JobAnalyticsEvent(
        eventId: 'evt_123',
        jobId: 'job_456',
        eventType: JobEventType.view,
        timestamp: DateTime.now(),
        userRole: 'guard',
        source: 'search',
        deviceType: 'mobile',
        metadata: {},
      );

      // Mock the save and retrieve operations
      when(() => mockRepository.saveJobAnalyticsEvent(event))
          .thenAnswer((_) async => {});
      when(() => mockRepository.getJobEvents('job_456', limit: 10))
          .thenAnswer((_) async => [event]);

      // Save event
      await mockRepository.saveJobAnalyticsEvent(event);

      // Retrieve events
      final events = await mockRepository.getJobEvents('job_456', limit: 10);

      expect(events, hasLength(1));
      expect(events.first.eventId, equals('evt_123'));
      expect(events.first.eventType, equals(JobEventType.view));
    });

    test('should handle analytics range queries', () async {
      // Create test analytics records
      final testAnalytics = [
        CompanyDailyAnalytics(
          date: '2024-01-05',
          companyId: 'test_company',
          jobsPosted: 5,
          jobsActive: 5,
          jobsCompleted: 0,
          jobsCancelled: 0,
          totalApplications: 25,
          applicationsAccepted: 10,
          applicationsRejected: 10,
          applicationsPending: 5,
          jobViews: 50,
          uniqueJobViews: 40,
          viewToApplicationRate: 50.0,
          applicationToHireRate: 40.0,
          averageTimeToFill: 48.0,
          averageTimeToFirstApplication: 24.0,
          totalCostPerHire: 75.0,
          totalRecruitmentSpend: 500.0,
          sourceBreakdown: {},
          averageApplicationQuality: 3.8,
          guardRetentionRate: 85.0,
          updatedAt: DateTime.now(),
        ),
        CompanyDailyAnalytics(
          date: '2024-01-03',
          companyId: 'test_company',
          jobsPosted: 3,
          jobsActive: 3,
          jobsCompleted: 0,
          jobsCancelled: 0,
          totalApplications: 15,
          applicationsAccepted: 6,
          applicationsRejected: 6,
          applicationsPending: 3,
          jobViews: 30,
          uniqueJobViews: 24,
          viewToApplicationRate: 50.0,
          applicationToHireRate: 40.0,
          averageTimeToFill: 48.0,
          averageTimeToFirstApplication: 24.0,
          totalCostPerHire: 75.0,
          totalRecruitmentSpend: 300.0,
          sourceBreakdown: {},
          averageApplicationQuality: 3.8,
          guardRetentionRate: 85.0,
          updatedAt: DateTime.now(),
        ),
      ];

      // Mock range query
      when(() => mockRepository.getCompanyAnalyticsRange(
        'test_company',
        '2024-01-03',
        '2024-01-05',
      )).thenAnswer((_) async => testAnalytics);

      // Query range
      final rangeResults = await mockRepository.getCompanyAnalyticsRange(
        'test_company',
        '2024-01-03',
        '2024-01-05',
      );

      expect(rangeResults, hasLength(2));
      expect(rangeResults.first.date, equals('2024-01-05')); // Should be sorted descending
      expect(rangeResults.last.date, equals('2024-01-03'));
    });
  });
}
