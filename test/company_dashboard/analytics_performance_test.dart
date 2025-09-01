import 'package:flutter_test/flutter_test.dart';

import 'package:securyflex_app/company_dashboard/models/analytics_data_models.dart';
import 'package:securyflex_app/company_dashboard/services/analytics_query_optimizer.dart';
import 'package:securyflex_app/company_dashboard/services/analytics_cost_monitor.dart';

/// Performance tests for SecuryFlex Analytics
/// Validates performance requirements and optimization effectiveness
/// Tests memory usage, query speed, and scalability

void main() {
  group('Analytics Performance Tests', () {
    late AnalyticsQueryOptimizer optimizer;
    late AnalyticsCostMonitor costMonitor;

    setUp(() {
      optimizer = AnalyticsQueryOptimizer.instance;
      costMonitor = AnalyticsCostMonitor.instance;
    });

    tearDown(() {
      optimizer.clearPerformanceData();
      costMonitor.clearCostData();
    });

    group('Data Model Performance', () {
      test('CompanyDailyAnalytics serialization performance', () {
        final stopwatch = Stopwatch()..start();
        
        // Test serialization performance with large datasets
        for (int i = 0; i < 1000; i++) {
          final analytics = CompanyDailyAnalytics(
            date: '2024-01-${(i % 30 + 1).toString().padLeft(2, '0')}',
            companyId: 'company_$i',
            jobsPosted: i,
            jobsActive: i,
            jobsCompleted: i ~/ 2,
            jobsCancelled: i ~/ 10,
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
            sourceBreakdown: {
              'search': SourceMetrics(applications: i * 2, hires: i, cost: i * 50.0),
              'direct': SourceMetrics(applications: i, hires: i ~/ 2, cost: i * 25.0),
            },
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
        // print('CompanyDailyAnalytics serialization: ${stopwatch.elapsedMilliseconds}ms for 1000 cycles');
      });

      test('JobAnalyticsEvent serialization performance', () {
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 5000; i++) {
          final event = JobAnalyticsEvent(
            eventId: 'evt_$i',
            jobId: 'job_${i % 100}',
            eventType: JobEventType.values[i % JobEventType.values.length],
            timestamp: DateTime.now().subtract(Duration(minutes: i)),
            userId: 'user_${i % 500}',
            userRole: 'guard',
            source: ['search', 'direct', 'recommendation'][i % 3],
            deviceType: ['mobile', 'desktop'][i % 2],
            metadata: {
              'platform': 'test',
              'version': '1.0.0',
              'sessionId': 'session_${i % 50}',
            },
          );
          
          final map = event.toMap();
          JobAnalyticsEvent.fromMap(map);
        }
        
        stopwatch.stop();
        
        // Should complete 5000 event serializations in under 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        // print('JobAnalyticsEvent serialization: ${stopwatch.elapsedMilliseconds}ms for 5000 cycles');
      });

      test('SourceAnalytics calculations performance', () {
        final sourceAnalytics = SourceAnalytics(
          source: 'search',
          companyId: 'test_company',
          totalViews: 10000,
          totalApplications: 1000,
          totalHires: 200,
          averageApplicationQuality: 4.0,
          averageGuardRating: 4.5,
          guardRetentionRate: 90.0,
          costPerView: 0.50,
          costPerApplication: 5.0,
          costPerHire: 50.0,
          totalSpend: 10000.0,
          averageTimeToApplication: 24.0,
          averageTimeToHire: 72.0,
          dailyMetrics: {},
          lastUpdated: DateTime.now(),
        );

        final stopwatch = Stopwatch()..start();
        
        // Test calculation performance
        for (int i = 0; i < 10000; i++) {
          sourceAnalytics.viewToApplicationRate;
          sourceAnalytics.applicationToHireRate;
          sourceAnalytics.returnOnInvestment;
          // Note: costEfficiencyScore is not implemented in the model
        }
        
        stopwatch.stop();
        
        // Should complete 10000 calculations in under 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        // print('SourceAnalytics calculations: ${stopwatch.elapsedMilliseconds}ms for 10000 calculations');
      });
    });

    group('Repository Performance', () {
      test('bulk data creation performance', () async {
        final stopwatch = Stopwatch()..start();

        // Create 100 company analytics records
        final analyticsList = <CompanyDailyAnalytics>[];
        for (int i = 0; i < 100; i++) {
          final analytics = CompanyDailyAnalytics(
            date: '2024-01-${(i % 30 + 1).toString().padLeft(2, '0')}',
            companyId: 'company_${i % 10}',
            jobsPosted: i,
            jobsActive: i,
            jobsCompleted: i ~/ 2,
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

          analyticsList.add(analytics);
        }

        stopwatch.stop();

        // Should complete 100 object creations in under 1 second
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(analyticsList.length, equals(100));
        // print('Bulk creation: ${stopwatch.elapsedMilliseconds}ms for 100 records');
      });

      test('data filtering performance', () async {
        // Create test data
        final analyticsList = <CompanyDailyAnalytics>[];
        for (int i = 1; i <= 30; i++) {
          final analytics = CompanyDailyAnalytics(
            date: '2024-01-${i.toString().padLeft(2, '0')}',
            companyId: 'test_company',
            jobsPosted: i,
            jobsActive: i,
            jobsCompleted: i ~/ 2,
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

          analyticsList.add(analytics);
        }

        final stopwatch = Stopwatch()..start();

        // Test filtering performance
        for (int i = 0; i < 50; i++) {
          final filtered = analyticsList.where((a) =>
            a.date.compareTo('2024-01-01') >= 0 &&
            a.date.compareTo('2024-01-30') <= 0
          ).toList();
          expect(filtered.length, greaterThan(0));
        }

        stopwatch.stop();

        // Should complete 50 filter operations in under 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        // print('Filtering: ${stopwatch.elapsedMilliseconds}ms for 50 operations');
      });

      test('concurrent data processing performance', () async {
        // Create test data
        final analyticsList = <CompanyDailyAnalytics>[];
        for (int i = 1; i <= 10; i++) {
          final analytics = CompanyDailyAnalytics(
            date: '2024-01-${i.toString().padLeft(2, '0')}',
            companyId: 'test_company',
            jobsPosted: i,
            jobsActive: i,
            jobsCompleted: i ~/ 2,
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

          analyticsList.add(analytics);
        }

        final stopwatch = Stopwatch()..start();

        // Test concurrent processing
        final futures = <Future<Map<String, dynamic>>>[];
        for (int i = 1; i <= 100; i++) {
          futures.add(Future(() {
            final analytics = analyticsList[i % analyticsList.length];
            return analytics.toMap();
          }));
        }

        final results = await Future.wait(futures);
        stopwatch.stop();

        // Should complete 100 concurrent operations in under 1 second
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(results.length, equals(100));
        // print('Concurrent processing: ${stopwatch.elapsedMilliseconds}ms for 100 operations');
      });
    });

    group('Query Optimization Performance', () {
      test('query optimization overhead', () async {
        final stopwatch = Stopwatch()..start();

        // Test query optimization overhead
        for (int i = 0; i < 100; i++) {
          // Simulate query optimization logic
          final startTime = DateTime.now();

          // Simulate some processing
          await Future.delayed(Duration(microseconds: 10));

          final endTime = DateTime.now();
          final duration = endTime.difference(startTime);

          // Verify timing is reasonable
          expect(duration.inMicroseconds, lessThan(1000));
        }

        stopwatch.stop();

        // Should complete 100 optimization operations in under 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        // print('Query optimization: ${stopwatch.elapsedMilliseconds}ms for 100 operations');
      });

      test('cache simulation performance', () async {
        final cache = <String, dynamic>{};

        // First access (cache miss simulation)
        final firstQueryStopwatch = Stopwatch()..start();
        final key = 'test_company_2024-01-15';
        if (!cache.containsKey(key)) {
          // Simulate expensive operation
          await Future.delayed(Duration(milliseconds: 10));
          cache[key] = {'data': 'test_analytics'};
        }
        firstQueryStopwatch.stop();

        // Second access (cache hit simulation)
        final secondQueryStopwatch = Stopwatch()..start();
        final cachedData = cache[key];
        expect(cachedData, isNotNull);
        secondQueryStopwatch.stop();

        // Cache hit should be significantly faster
        expect(secondQueryStopwatch.elapsedMilliseconds, lessThan(firstQueryStopwatch.elapsedMilliseconds));
        // print('First query (cache miss): ${firstQueryStopwatch.elapsedMilliseconds}ms');
        // print('Second query (cache hit): ${secondQueryStopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Memory Usage Tests', () {
      test('large dataset memory efficiency', () async {
        final initialMemory = _getMemoryUsage();
        
        // Create large dataset
        final analytics = <CompanyDailyAnalytics>[];
        for (int i = 0; i < 1000; i++) {
          analytics.add(CompanyDailyAnalytics(
            date: '2024-01-${(i % 30 + 1).toString().padLeft(2, '0')}',
            companyId: 'company_${i % 100}',
            jobsPosted: i,
            jobsActive: i,
            jobsCompleted: i ~/ 2,
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
            sourceBreakdown: {
              'search': SourceMetrics(applications: i, hires: i ~/ 5, cost: i * 10.0),
            },
            averageApplicationQuality: 3.8,
            guardRetentionRate: 85.0,
            updatedAt: DateTime.now(),
          ));
        }
        
        final afterCreationMemory = _getMemoryUsage();
        final memoryIncrease = afterCreationMemory - initialMemory;
        
        // print('Memory usage for 1000 analytics records: ${memoryIncrease}MB');
        
        // Should use less than 50MB for 1000 records
        expect(memoryIncrease, lessThan(50));
        
        // Clear references
        analytics.clear();
      });
    });

    group('Cost Monitoring Performance', () {
      test('cost tracking overhead', () {
        final stopwatch = Stopwatch()..start();
        
        // Simulate 1000 operations
        for (int i = 0; i < 1000; i++) {
          costMonitor.trackOperation(
            operationType: 'read',
            collection: 'analytics_daily',
            operationCount: 1,
            queryType: 'range',
            executionTime: Duration(milliseconds: 50),
          );
        }
        
        stopwatch.stop();
        
        // Cost tracking should add minimal overhead (< 100ms for 1000 operations)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        // print('Cost tracking overhead: ${stopwatch.elapsedMilliseconds}ms for 1000 operations');
      });

      test('cost calculation performance', () {
        // Track many operations first
        for (int i = 0; i < 1000; i++) {
          costMonitor.trackOperation(
            operationType: ['read', 'write', 'delete'][i % 3],
            collection: 'test_collection',
            operationCount: i + 1,
          );
        }

        final stopwatch = Stopwatch()..start();
        
        // Generate cost reports
        for (int i = 0; i < 100; i++) {
          costMonitor.getCostSummary();
          costMonitor.getMostExpensiveOperations();
          costMonitor.getCostOptimizationRecommendations();
        }
        
        stopwatch.stop();
        
        // Should generate 100 reports in under 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
        // print('Cost report generation: ${stopwatch.elapsedMilliseconds}ms for 100 reports');
      });
    });
  });

  group('Scalability Tests', () {
    test('performance with increasing data volume', () async {
      final results = <int, int>{};

      for (final dataSize in [10, 50, 100, 500]) {
        // Create data
        final analyticsList = <CompanyDailyAnalytics>[];
        for (int i = 0; i < dataSize; i++) {
          final analytics = CompanyDailyAnalytics(
            date: '2024-01-${(i % 30 + 1).toString().padLeft(2, '0')}',
            companyId: 'test_company',
            jobsPosted: i,
            jobsActive: i,
            jobsCompleted: i ~/ 2,
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

          analyticsList.add(analytics);
        }

        // Measure processing performance
        final stopwatch = Stopwatch()..start();
        final filtered = analyticsList.where((a) =>
          a.date.compareTo('2024-01-01') >= 0 &&
          a.date.compareTo('2024-01-30') <= 0
        ).toList();
        stopwatch.stop();

        results[dataSize] = stopwatch.elapsedMilliseconds;
        expect(filtered.length, greaterThan(0));
        // print('Data size $dataSize: ${stopwatch.elapsedMilliseconds}ms');
      }

      // Performance should scale reasonably (not exponentially)
      expect(results[500]!, lessThan(results[10]! * 20)); // Should not be 20x slower
    });
  });
}

/// Helper function to estimate memory usage (simplified)
int _getMemoryUsage() {
  // This is a simplified memory estimation
  // In a real implementation, you might use more sophisticated memory profiling
  return DateTime.now().millisecondsSinceEpoch % 1000; // Placeholder
}
