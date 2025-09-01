import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:securyflex_app/beveiliger_dashboard/modern_beveiliger_dashboard_v2.dart';
import 'package:securyflex_app/beveiliger_dashboard/bloc/beveiliger_dashboard_bloc.dart';
import 'package:securyflex_app/beveiliger_dashboard/bloc/beveiliger_dashboard_event.dart';
import 'package:securyflex_app/beveiliger_dashboard/bloc/beveiliger_dashboard_state.dart';
import 'package:securyflex_app/beveiliger_dashboard/services/enhanced_earnings_service.dart';
import 'package:securyflex_app/beveiliger_dashboard/services/enhanced_shift_service.dart';
import 'package:securyflex_app/beveiliger_dashboard/services/compliance_monitoring_service.dart';
import 'package:securyflex_app/beveiliger_dashboard/services/weather_integration_service.dart';
import 'package:securyflex_app/beveiliger_dashboard/services/performance_analytics_service.dart';
import 'package:securyflex_app/beveiliger_dashboard/models/enhanced_dashboard_data.dart';
import 'package:securyflex_app/beveiliger_dashboard/models/compliance_status.dart';
import 'package:securyflex_app/beveiliger_dashboard/models/weather_data.dart';
import 'package:securyflex_app/beveiliger_dashboard/models/performance_analytics.dart';

// Mock services
class MockEnhancedEarningsService extends Mock implements EnhancedEarningsService {}
class MockEnhancedShiftService extends Mock implements EnhancedShiftService {}
class MockComplianceMonitoringService extends Mock implements ComplianceMonitoringService {}
class MockWeatherIntegrationService extends Mock implements WeatherIntegrationService {}
class MockPerformanceAnalyticsService extends Mock implements PerformanceAnalyticsService {}

void main() {
  group('Simple Beveiliger Dashboard Tests', () {
    late MockEnhancedEarningsService mockEarningsService;
    late MockEnhancedShiftService mockShiftService;
    late MockComplianceMonitoringService mockComplianceService;
    late MockWeatherIntegrationService mockWeatherService;
    late MockPerformanceAnalyticsService mockAnalyticsService;
    late BeveiligerDashboardBloc dashboardBloc;

    // Simple test data
    final testEarningsData = EnhancedEarningsData(
      totalToday: 120.75,
      totalWeek: 856.25,
      totalMonth: 2340.50,
      hourlyRate: 15.50,
      hoursWorkedToday: 7.5,
      hoursWorkedWeek: 42.5,
      overtimeHours: 2.5,
      overtimeRate: 23.25,
      vakantiegeld: 187.24,
      btwAmount: 491.51,
      isFreelance: true,
      dutchFormattedToday: '€120,75',
      dutchFormattedWeek: '€856,25',
      dutchFormattedMonth: '€2.340,50',
      lastCalculated: DateTime(2024, 1, 15, 14, 30),
    );

    final testShifts = [
      EnhancedShiftData(
        id: 'shift_001',
        title: 'Test Shift',
        companyName: 'Test Company',
        companyId: 'comp_001',
        startTime: DateTime(2024, 1, 15, 9, 0),
        endTime: DateTime(2024, 1, 15, 17, 0),
        location: 'Amsterdam',
        address: 'Test Address',
        hourlyRate: 15.50,
        status: ShiftStatus.confirmed,
        type: ShiftType.regular,
        requiredCertifications: ['WPBR'],
        isOutdoor: false,
        requiresUniform: true,
        emergencyResponse: false,
        dutchStatusText: 'Bevestigd',
      ),
    ];

    final testCompliance = ComplianceStatus(
      hasViolations: false,
      violations: [],
      weeklyHours: 40.0,
      maxWeeklyHours: 48.0,
      restPeriod: Duration(hours: 12),
      minRestPeriod: Duration(hours: 11),
      wpbrValid: true,
      wpbrExpiryDate: DateTime(2025, 3, 15),
      healthCertificateValid: true,
      lastUpdated: DateTime(2024, 1, 15, 10, 30),
    );

    setUp(() {
      mockEarningsService = MockEnhancedEarningsService();
      mockShiftService = MockEnhancedShiftService();
      mockComplianceService = MockComplianceMonitoringService();
      mockWeatherService = MockWeatherIntegrationService();
      mockAnalyticsService = MockPerformanceAnalyticsService();

      // Setup basic mocks
      when(() => mockEarningsService.getEnhancedEarningsData()).thenAnswer((_) async => testEarningsData);
      when(() => mockEarningsService.earningsStream).thenAnswer((_) => Stream.value(testEarningsData));
      when(() => mockShiftService.getTodaysShifts()).thenAnswer((_) async => testShifts);
      when(() => mockShiftService.shiftsStream).thenAnswer((_) => Stream.value(testShifts));
      when(() => mockComplianceService.getCurrentComplianceStatus(any())).thenAnswer((_) async => testCompliance);

      dashboardBloc = BeveiligerDashboardBloc(
        earningsService: mockEarningsService,
        shiftService: mockShiftService,
        complianceService: mockComplianceService,
        weatherService: mockWeatherService,
        analyticsService: mockAnalyticsService,
      );
    });

    tearDown(() {
      dashboardBloc.close();
    });

    test('BLoC initializes with correct initial state', () {
      expect(dashboardBloc.state, isA<BeveiligerDashboardInitial>());
    });

    test('LoadDashboardData event triggers loading state', () async {
      // Act
      dashboardBloc.add(const LoadDashboardData());
      
      // Wait for state emission
      await expectLater(
        dashboardBloc.stream,
        emits(isA<BeveiligerDashboardLoading>()),
      );
    });

    testWidgets('Dashboard widget can be instantiated', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BeveiligerDashboardBloc>(
            create: (_) => dashboardBloc,
            child: ModernBeveiligerDashboardV2(),
          ),
        ),
      );

      expect(find.byType(ModernBeveiligerDashboardV2), findsOneWidget);
    });
  });
}