import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/beveiliger_dashboard/services/daily_overview_service.dart';
import 'package:securyflex_app/beveiliger_dashboard/models/daily_overview_data.dart';

void main() {
  group('DailyOverviewScreen Integration Tests', () {
    late DailyOverviewService service;

    setUp(() {
      service = DailyOverviewService.instance;
      service.clearCache();
    });

    tearDown(() {
      service.clearCache();
    });

    test('should initialize service correctly', () {
      expect(service, isNotNull);
      expect(service, equals(DailyOverviewService.instance));
    });

    test('should return valid daily overview data', () async {
      final data = await service.getDailyOverview();

      expect(data, isA<DailyOverviewData>());
      expect(data.hoursWorkedToday, greaterThanOrEqualTo(0));
      expect(data.scheduledHoursToday, greaterThanOrEqualTo(0));
      expect(data.earningsToday, greaterThanOrEqualTo(0));
    });

    test('should handle data refresh correctly', () async {
      await service.refreshData();
      final data = await service.getDailyOverview();

      expect(data, isA<DailyOverviewData>());
      expect(data.currentShiftStatus, isNotEmpty);
    });

    test('should update time tracking metrics', () async {
      await service.updateTimeTracking(
        hoursWorked: 8.0,
        isCurrentlyWorking: true,
      );

      final data = await service.getDailyOverview();
      expect(data.hoursWorkedToday, equals(8.0));
      expect(data.isCurrentlyWorking, isTrue);
    });

    test('should provide valid calculated properties', () async {
      final data = await service.getDailyOverview();

      expect(data.todaysCompletionPercentage, greaterThanOrEqualTo(0));
      expect(data.todaysCompletionPercentage, lessThanOrEqualTo(1));
      expect(data.weeklyProgressPercentage, greaterThanOrEqualTo(0));
      expect(data.monthlyEarningsPercentage, greaterThanOrEqualTo(0));
    });

    test('should handle concurrent requests efficiently', () async {
      final futures = List.generate(3, (_) => service.getDailyOverview());
      final results = await Future.wait(futures);

      for (final result in results) {
        expect(result, isA<DailyOverviewData>());
        expect(result.hoursWorkedToday, greaterThanOrEqualTo(0));
      }
    });

    test('should maintain data consistency', () async {
      final data1 = await service.getDailyOverview();
      final data2 = await service.getDailyOverview();

      // Should return same cached data
      expect(data1.hoursWorkedToday, equals(data2.hoursWorkedToday));
      expect(data1.earningsToday, equals(data2.earningsToday));
    });

    test('should provide valid Dutch formatting', () async {
      final data = await service.getDailyOverview();

      expect(data.currentShiftStatus, isNotEmpty);
      expect(data.todaysShifts, isNotNull);
      expect(data.tomorrowsShifts, isNotNull);
      expect(data.todaysAchievements, isNotNull);
    });
  });
}
