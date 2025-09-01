import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/beveiliger_dashboard/services/daily_overview_service.dart';
import 'package:securyflex_app/beveiliger_dashboard/models/daily_overview_data.dart';

void main() {
  group('DailyOverviewService Tests', () {
    late DailyOverviewService service;

    setUp(() {
      service = DailyOverviewService.instance;
      service.clearCache();
    });

    tearDown(() {
      service.clearCache();
    });

    test('should be a singleton', () {
      final service1 = DailyOverviewService.instance;
      final service2 = DailyOverviewService.instance;
      
      expect(service1, equals(service2));
      expect(identical(service1, service2), isTrue);
    });

    test('should return daily overview data', () async {
      final data = await service.getDailyOverview();
      
      expect(data, isA<DailyOverviewData>());
      expect(data.hoursWorkedToday, greaterThanOrEqualTo(0));
      expect(data.scheduledHoursToday, greaterThanOrEqualTo(0));
      expect(data.earningsToday, greaterThanOrEqualTo(0));
      expect(data.projectedEarningsToday, greaterThanOrEqualTo(0));
    });

    test('should cache data for performance', () async {
      final stopwatch = Stopwatch()..start();
      
      // First call - should fetch data
      final data1 = await service.getDailyOverview();
      final firstCallTime = stopwatch.elapsedMilliseconds;
      
      stopwatch.reset();
      
      // Second call - should use cache
      final data2 = await service.getDailyOverview();
      final secondCallTime = stopwatch.elapsedMilliseconds;
      
      stopwatch.stop();
      
      // Verify data is the same
      expect(data1.hoursWorkedToday, equals(data2.hoursWorkedToday));
      expect(data1.earningsToday, equals(data2.earningsToday));
      
      // Second call should be significantly faster (cached)
      expect(secondCallTime, lessThan(firstCallTime));
    });

    test('should refresh data when requested', () async {
      // Refresh data
      await service.refreshData();

      // Get data again
      final refreshedData = await service.getDailyOverview();

      // Data should be available (might be the same sample data)
      expect(refreshedData, isA<DailyOverviewData>());
      expect(refreshedData.hoursWorkedToday, greaterThanOrEqualTo(0));
    });

    test('should update time tracking metrics', () async {
      // Update time tracking
      await service.updateTimeTracking(
        hoursWorked: 8.5,
        isCurrentlyWorking: true,
      );

      // Get updated data
      final updatedData = await service.getDailyOverview();

      // Verify updates were applied
      expect(updatedData.hoursWorkedToday, equals(8.5));
      expect(updatedData.isCurrentlyWorking, isTrue);
    });

    test('should handle null cache gracefully', () async {
      // Clear cache
      service.clearCache();
      
      // Should still return data
      final data = await service.getDailyOverview();
      
      expect(data, isA<DailyOverviewData>());
    });

    group('Data Validation', () {
      test('should return valid daily metrics', () async {
        final data = await service.getDailyOverview();
        
        // Time metrics
        expect(data.hoursWorkedToday, greaterThanOrEqualTo(0));
        expect(data.scheduledHoursToday, greaterThanOrEqualTo(0));
        expect(data.remainingHoursToday, greaterThanOrEqualTo(0));
        expect(data.overtimeHours, greaterThanOrEqualTo(0));
        
        // Earnings metrics
        expect(data.earningsToday, greaterThanOrEqualTo(0));
        expect(data.projectedEarningsToday, greaterThanOrEqualTo(0));
        expect(data.averageHourlyRate, greaterThanOrEqualTo(0));
        expect(data.bonusEarnings, greaterThanOrEqualTo(0));
        expect(data.totalWeeklyEarnings, greaterThanOrEqualTo(0));
        expect(data.monthlyTarget, greaterThanOrEqualTo(0));
        expect(data.monthlyProgress, greaterThanOrEqualTo(0));
        
        // Performance metrics
        expect(data.punctualityScore, greaterThanOrEqualTo(0));
        expect(data.punctualityScore, lessThanOrEqualTo(100));
        expect(data.weeklyEfficiencyScore, greaterThanOrEqualTo(0));
        expect(data.weeklyEfficiencyScore, lessThanOrEqualTo(100));
        expect(data.consecutiveWorkDays, greaterThanOrEqualTo(0));
        expect(data.clientSatisfactionScore, greaterThanOrEqualTo(0));
        expect(data.clientSatisfactionScore, lessThanOrEqualTo(5));
        
        // Counts
        expect(data.completedShiftsToday, greaterThanOrEqualTo(0));
        expect(data.remainingShiftsToday, greaterThanOrEqualTo(0));
        expect(data.newJobOffers, greaterThanOrEqualTo(0));
        expect(data.shiftsCompletedThisWeek, greaterThanOrEqualTo(0));
        
        // Weekly metrics
        expect(data.weeklyHoursWorked, greaterThanOrEqualTo(0));
        expect(data.weeklyHoursTarget, greaterThan(0));
        expect(data.weeklyEarnings, greaterThanOrEqualTo(0));
      });

      test('should return valid calculated properties', () async {
        final data = await service.getDailyOverview();
        
        // Completion percentage should be between 0 and 1
        expect(data.todaysCompletionPercentage, greaterThanOrEqualTo(0));
        expect(data.todaysCompletionPercentage, lessThanOrEqualTo(1));
        
        // Weekly progress percentage should be between 0 and 1
        expect(data.weeklyProgressPercentage, greaterThanOrEqualTo(0));
        expect(data.weeklyProgressPercentage, lessThanOrEqualTo(1));
        
        // Monthly earnings percentage should be between 0 and 1
        expect(data.monthlyEarningsPercentage, greaterThanOrEqualTo(0));
        expect(data.monthlyEarningsPercentage, lessThanOrEqualTo(1));
        
        // Current shift status should not be empty
        expect(data.currentShiftStatus, isNotEmpty);
      });

      test('should return valid lists', () async {
        final data = await service.getDailyOverview();
        
        // Lists should not be null
        expect(data.todaysShifts, isNotNull);
        expect(data.tomorrowsShifts, isNotNull);
        expect(data.todaysAchievements, isNotNull);
        expect(data.urgentNotifications, isNotNull);
        expect(data.reminders, isNotNull);
        expect(data.availableTimeSlots, isNotNull);
      });
    });

    group('Performance Tests', () {
      test('should load data within reasonable time', () async {
        final stopwatch = Stopwatch()..start();
        
        await service.getDailyOverview();
        
        stopwatch.stop();
        
        // Should load within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });

      test('should handle multiple concurrent requests', () async {
        final futures = List.generate(5, (_) => service.getDailyOverview());
        
        final results = await Future.wait(futures);
        
        // All results should be valid
        for (final result in results) {
          expect(result, isA<DailyOverviewData>());
          expect(result.hoursWorkedToday, greaterThanOrEqualTo(0));
        }
        
        // All results should be the same (cached)
        for (int i = 1; i < results.length; i++) {
          expect(results[i].hoursWorkedToday, equals(results[0].hoursWorkedToday));
          expect(results[i].earningsToday, equals(results[0].earningsToday));
        }
      });
    });

    group('Error Handling', () {
      test('should handle service errors gracefully', () async {
        // The service is designed to return sample data on error
        // so this test verifies that behavior
        final data = await service.getDailyOverview();
        
        expect(data, isA<DailyOverviewData>());
        expect(data.hoursWorkedToday, greaterThanOrEqualTo(0));
      });
    });

    group('Cache Management', () {
      test('should clear cache properly', () async {
        // Get data to populate cache
        await service.getDailyOverview();
        
        // Clear cache
        service.clearCache();
        
        // Next call should fetch fresh data
        final data = await service.getDailyOverview();
        
        expect(data, isA<DailyOverviewData>());
      });

      test('should respect cache duration', () async {
        // This test would require mocking time or waiting
        // For now, we just verify the cache works
        final data1 = await service.getDailyOverview();
        final data2 = await service.getDailyOverview();
        
        // Should return same cached data
        expect(data1.hoursWorkedToday, equals(data2.hoursWorkedToday));
      });
    });
  });
}
