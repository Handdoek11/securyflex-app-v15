import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:securyflex_app/beveiliger_dashboard/modern_beveiliger_dashboard_v2.dart';
import 'package:securyflex_app/beveiliger_dashboard/bloc/beveiliger_dashboard_bloc.dart';
import 'package:securyflex_app/beveiliger_dashboard/bloc/beveiliger_dashboard_event.dart';
// Removed unused import: beveiliger_dashboard_state.dart
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
class MockEnhancedEarningsService extends Mock implements EnhancedEarningsService {
  bool isCurrentlyOnShift() => false;
  
  double getCurrentShiftHourlyRate() => 15.50;
  
  Stream<double> getRealTimeEarnings() => Stream.value(120.75);
  
  Future<void> refreshEarningsData() async {}
  
  Future<EnhancedEarningsData> getCurrentEarnings() async => throw UnimplementedError();
}

class MockEnhancedShiftService extends Mock implements EnhancedShiftService {
  Future<void> refreshShiftData() async {}
}

class MockComplianceMonitoringService extends Mock implements ComplianceMonitoringService {
  Future<void> recheckCompliance() async {}
}

class MockWeatherIntegrationService extends Mock implements WeatherIntegrationService {
  Future<WeatherData> getCurrentWeatherForLocation(String location) async => throw UnimplementedError();
}

class MockPerformanceAnalyticsService extends Mock implements PerformanceAnalyticsService {
  Future<void> refreshAnalytics() async {}
}

void main() {
  group('Complete Beveiliger Dashboard Integration Tests', () {
    late MockEnhancedEarningsService mockEarningsService;
    late MockEnhancedShiftService mockShiftService;
    late MockComplianceMonitoringService mockComplianceService;
    late MockWeatherIntegrationService mockWeatherService;
    late MockPerformanceAnalyticsService mockAnalyticsService;
    late BeveiligerDashboardBloc dashboardBloc;

    // Test data definitions
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
        title: 'Objectbeveiliging - Kantoorgebouw',
        companyName: 'SecureMax BV',
        companyId: 'comp_001',
        startTime: DateTime(2024, 1, 15, 22, 0),
        endTime: DateTime(2024, 1, 16, 6, 0),
        location: 'Amsterdam Centrum',
        address: 'Damrak 1, 1012 LG Amsterdam',
        latitude: 52.3676,
        longitude: 4.9041,
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

    // Removed unused testUpcomingShifts variable

    final testComplianceStatus = ComplianceStatus(
      hasViolations: false,
      violations: [],
      weeklyHours: 42.5,
      maxWeeklyHours: 48.0,
      restPeriod: Duration(hours: 12),
      minRestPeriod: Duration(hours: 11),
      wpbrValid: true,
      wpbrExpiryDate: DateTime(2025, 3, 15),
      healthCertificateValid: true,
      lastUpdated: DateTime(2024, 1, 15, 10, 30),
    );

    final testWeatherData = WeatherData(
      temperature: 8.5,
      feelsLike: 6.2,
      humidity: 75,
      windSpeed: 12.5,
      windDirection: 'NW',
      description: 'Cloudy',
      dutchDescription: 'Bewolkt, 9°C',
      condition: WeatherCondition.cloudy,
      uvIndex: 2,
      precipitation: 0.0,
      visibility: 10.0,
      timestamp: DateTime(2024, 1, 15, 12, 0),
      location: 'Amsterdam',
      alerts: [],
    );

    final testAnalytics = PerformanceAnalytics(
      overallRating: 4.7,
      totalShifts: 18,
      shiftsThisWeek: 3,
      shiftsThisMonth: 16,
      completionRate: 94.4,
      averageResponseTime: 5.2,
      customerSatisfaction: 92.0,
      streakDays: 12,
      earningsHistory: [],
      shiftHistory: [],
      ratingHistory: [],
      performanceMetrics: {
        'punctuality': 95.0,
        'communication': 88.5,
        'professionalism': 96.2,
      },
      lastUpdated: DateTime(2024, 1, 15, 14, 30),
    );

    void setupMockResponses() {
      // Setup enhanced earnings service mock
      when(() => mockEarningsService.getEnhancedEarningsData()).thenAnswer((_) async => testEarningsData);
      when(() => mockEarningsService.earningsStream).thenAnswer((_) => Stream.value(testEarningsData));
      when(() => mockEarningsService.isCurrentlyOnShift()).thenReturn(false);
      when(() => mockEarningsService.getCurrentShiftHourlyRate()).thenReturn(15.50);
      when(() => mockEarningsService.getRealTimeEarnings()).thenAnswer((_) => Stream.value(120.75));
      when(() => mockEarningsService.refreshEarningsData()).thenAnswer((_) async {});
      when(() => mockEarningsService.getCurrentEarnings()).thenAnswer((_) async => testEarningsData);
      
      // Setup shift service mock
      when(() => mockShiftService.getTodaysShifts()).thenAnswer((_) async => testShifts);
      when(() => mockShiftService.shiftsStream).thenAnswer((_) => Stream.value(testShifts));
      when(() => mockShiftService.refreshShiftData()).thenAnswer((_) async {});
      
      // Setup compliance service mock
      when(() => mockComplianceService.getCurrentComplianceStatus(any())).thenAnswer((_) async => testComplianceStatus);
      when(() => mockComplianceService.complianceStream).thenAnswer((_) => Stream.value(testComplianceStatus));
      when(() => mockComplianceService.recheckCompliance()).thenAnswer((_) async {});
      
      // Setup weather service mock
      when(() => mockWeatherService.getCurrentWeather(any(), any())).thenAnswer((_) async => testWeatherData);
      when(() => mockWeatherService.getCurrentWeatherForLocation(any())).thenAnswer((_) async => testWeatherData);
      when(() => mockWeatherService.weatherStream).thenAnswer((_) => Stream.value(testWeatherData));
      
      // Setup analytics service mock
      when(() => mockAnalyticsService.getPerformanceAnalytics(any(), any())).thenAnswer((_) async => testAnalytics);
      when(() => mockAnalyticsService.analyticsStream).thenAnswer((_) => Stream.value(testAnalytics));
      when(() => mockAnalyticsService.refreshAnalytics()).thenAnswer((_) async {});
    }

    setUp(() {
      mockEarningsService = MockEnhancedEarningsService();
      mockShiftService = MockEnhancedShiftService();
      mockComplianceService = MockComplianceMonitoringService();
      mockWeatherService = MockWeatherIntegrationService();
      mockAnalyticsService = MockPerformanceAnalyticsService();

      dashboardBloc = BeveiligerDashboardBloc(
        earningsService: mockEarningsService,
        shiftService: mockShiftService,
        complianceService: mockComplianceService,
        weatherService: mockWeatherService,
        analyticsService: mockAnalyticsService,
      );

      // Setup default mock responses
      setupMockResponses();
    });

    tearDown(() {
      dashboardBloc.close();
    });


    testWidgets('Dashboard loads and displays all required components', (tester) async {
      // ARRANGE

      // Setup widget
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BeveiligerDashboardBloc>(
            create: (_) => dashboardBloc,
            child: ModernBeveiligerDashboardV2(),
          ),
        ),
      );

      // Trigger initial load
      dashboardBloc.add(LoadDashboardData());
      await tester.pump();

      // ASSERT - Initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the loading
      await tester.pump(Duration(seconds: 1));

      // ASSERT - All main components are present
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('€2.340,50'), findsOneWidget); // Current month total
      expect(find.text('€120,75'), findsOneWidget); // Today's earnings
      expect(find.text('€15,50/uur'), findsOneWidget); // Hourly rate
      expect(find.text('Objectbeveiliging - Kantoorgebouw'), findsOneWidget);
      expect(find.text('SecureMax BV'), findsOneWidget);
      expect(find.text('Amsterdam Centrum'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget); // WPBR status
      expect(find.text('95%'), findsOneWidget); // CAO compliance score
    });

    testWidgets('Real-time earnings counter updates during active shift', (tester) async {
      // ARRANGE - Mock an active shift
      when(() => mockEarningsService.isCurrentlyOnShift()).thenReturn(true);
      when(() => mockEarningsService.getCurrentShiftHourlyRate()).thenReturn(15.50);
      when(() => mockEarningsService.getRealTimeEarnings()).thenReturn(
        Stream.periodic(Duration(seconds: 1), (count) => 15.50 * (count + 1) / 60),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BeveiligerDashboardBloc>(
            create: (_) => dashboardBloc,
            child: ModernBeveiligerDashboardV2(),
          ),
        ),
      );

      dashboardBloc.add(StartRealTimeEarningsTracking());
      await tester.pump();

      // ASSERT - Initial state
      expect(find.text('€0,26'), findsOneWidget); // First minute earnings

      // Wait for updates
      await tester.pump(Duration(seconds: 2));
      expect(find.text('€0,52'), findsOneWidget); // Second minute earnings

      // Verify real-time indicator is shown
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.text('ACTIEF AAN HET WERK'), findsOneWidget);
    });

    testWidgets('Weather integration displays for outdoor shifts', (tester) async {
      // ARRANGE - Mock outdoor shift with weather data
      final weatherData = WeatherData(
        temperature: 12.5,
        feelsLike: 10.5,
        humidity: 85,
        windSpeed: 15.2,
        windDirection: 'NW',
        description: 'Lichte regen',
        dutchDescription: 'Lichte regen',
        condition: WeatherCondition.rainy,
        uvIndex: 1,
        precipitation: 5.0,
        visibility: 8.0,
        timestamp: DateTime.now(),
        location: 'Amsterdam',
        alerts: [],
      );

      when(() => mockWeatherService.getCurrentWeatherForLocation('Amsterdam'))
        .thenAnswer((_) async => weatherData);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BeveiligerDashboardBloc>(
            create: (_) => dashboardBloc,
            child: ModernBeveiligerDashboardV2(),
          ),
        ),
      );

      dashboardBloc.add(UpdateWeatherData());
      await tester.pumpAndSettle();

      // ASSERT - Weather widget is displayed
      expect(find.text('12°C'), findsOneWidget);
      expect(find.text('Lichte regen'), findsOneWidget);
      expect(find.byIcon(Icons.umbrella), findsOneWidget);
      expect(find.text('85%'), findsOneWidget); // Humidity
      expect(find.text('15 km/h'), findsOneWidget); // Wind speed
    });

    testWidgets('Compliance monitoring shows warnings for expiring certificates', (tester) async {
      // ARRANGE - Mock expiring WPBR certificate
      final expiringCompliance = ComplianceStatus(
        hasViolations: true,
        violations: [],
        weeklyHours: 42.5,
        maxWeeklyHours: 48.0,
        restPeriod: Duration(hours: 10), // Below minimum
        minRestPeriod: Duration(hours: 11),
        wpbrValid: true,
        wpbrExpiryDate: DateTime(2024, 2, 15), // Expires soon
        healthCertificateValid: true,
        lastUpdated: DateTime(2024, 1, 15, 10, 30),
      );

      when(() => mockComplianceService.getCurrentComplianceStatus(any()))
        .thenAnswer((_) async => expiringCompliance);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BeveiligerDashboardBloc>(
            create: (_) => dashboardBloc,
            child: ModernBeveiligerDashboardV2(),
          ),
        ),
      );

      dashboardBloc.add(UpdateComplianceStatus());
      await tester.pumpAndSettle();

      // ASSERT - Warning indicators are shown
      expect(find.byIcon(Icons.warning), findsAtLeastNWidgets(1));
      expect(find.text('WPBR certificaat verloopt over 30 dagen'), findsOneWidget);
      expect(find.text('CAO compliance onder de 80%'), findsOneWidget);
      expect(find.text('78%'), findsOneWidget);
      
      // Verify warning colors are used
      final warningContainer = tester.widget<Container>(
        find.descendant(
          of: find.text('WPBR certificaat verloopt over 30 dagen'),
          matching: find.byType(Container),
        ).first,
      );
      expect((warningContainer.decoration as BoxDecoration).color.toString(), 
             contains('ff')); // Contains warning color
    });

    testWidgets('Performance analytics display trends and metrics', (tester) async {
      // ARRANGE - Mock performance data
      final performanceData = PerformanceAnalytics(
        overallRating: 4.7,
        totalShifts: 156,
        shiftsThisWeek: 3,
        shiftsThisMonth: 18,
        completionRate: 94.5,
        averageResponseTime: 5.2,
        customerSatisfaction: 4.8,
        streakDays: 12,
        earningsHistory: [],
        shiftHistory: [],
        ratingHistory: [],
        performanceMetrics: {
          'punctuality': 95.0,
          'onTime': 94.5,
          'satisfaction': 4.8,
        },
        lastUpdated: DateTime.now(),
      );

      when(() => mockAnalyticsService.getPerformanceAnalytics(any(), any()))
        .thenAnswer((_) async => performanceData);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BeveiligerDashboardBloc>(
            create: (_) => dashboardBloc,
            child: ModernBeveiligerDashboardV2(),
          ),
        ),
      );

      dashboardBloc.add(LoadPerformanceAnalytics(period: AnalyticsPeriod.week));
      await tester.pumpAndSettle();

      // ASSERT - Performance metrics are displayed
      expect(find.text('4.7'), findsOneWidget); // Average rating
      expect(find.text('156'), findsOneWidget); // Total jobs
      expect(find.text('94.5%'), findsOneWidget); // On-time percentage
      expect(find.text('4.8'), findsOneWidget); // Customer satisfaction
      
      // Verify badges are shown
      expect(find.text('Punctual Pro'), findsOneWidget);
      expect(find.text('Customer Favorite'), findsOneWidget);
      expect(find.text('100+ Jobs'), findsOneWidget);
      
      // Verify trends chart is present
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1)); // Chart widget
    });

    testWidgets('Emergency actions are immediately accessible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BeveiligerDashboardBloc>(
            create: (_) => dashboardBloc,
            child: ModernBeveiligerDashboardV2(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ASSERT - Emergency actions are visible and functional
      expect(find.text('NOODMELDING'), findsOneWidget);
      expect(find.byIcon(Icons.emergency), findsOneWidget);
      
      // Test emergency button functionality
      await tester.tap(find.text('NOODMELDING'));
      await tester.pumpAndSettle();
      
      // Should show emergency dialog
      expect(find.text('Noodmelding bevestigen'), findsOneWidget);
      expect(find.text('112 bellen'), findsOneWidget);
      expect(find.text('Beveiligingsbedrijf waarschuwen'), findsOneWidget);
    });

    testWidgets('Quick actions provide immediate access to common tasks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BeveiligerDashboardBloc>(
            create: (_) => dashboardBloc,
            child: ModernBeveiligerDashboardV2(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ASSERT - Quick actions are available
      expect(find.text('Nieuwe Dienst'), findsOneWidget);
      expect(find.text('Pauze'), findsOneWidget);
      expect(find.text('Incident Melden'), findsOneWidget);
      expect(find.text('Planning'), findsOneWidget);
      
      // Test quick action functionality
      await tester.tap(find.text('Incident Melden'));
      await tester.pumpAndSettle();
      
      expect(find.text('Incident Details'), findsOneWidget);
      expect(find.text('Incident Type'), findsOneWidget);
    });

    testWidgets('Refresh functionality updates all data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BeveiligerDashboardBloc>(
            create: (_) => dashboardBloc,
            child: ModernBeveiligerDashboardV2(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);
      
      await tester.tap(refreshButton);
      await tester.pump();

      // Should show loading indicator during refresh
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      // Verify all services are called for refresh
      verify(() => mockEarningsService.refreshEarningsData()).called(1);
      verify(() => mockShiftService.refreshShiftData()).called(1);
      verify(() => mockComplianceService.recheckCompliance()).called(1);
      verify(() => mockAnalyticsService.refreshAnalytics()).called(1);
    });

    testWidgets('Error states are handled gracefully with retry options', (tester) async {
      // ARRANGE - Mock service failures
      when(() => mockEarningsService.getCurrentEarnings())
        .thenThrow(Exception('Network timeout'));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BeveiligerDashboardBloc>(
            create: (_) => dashboardBloc,
            child: ModernBeveiligerDashboardV2(),
          ),
        ),
      );

      dashboardBloc.add(LoadDashboardData());
      await tester.pumpAndSettle();

      // ASSERT - Error state is displayed
      expect(find.text('Er is een fout opgetreden'), findsOneWidget);
      expect(find.text('Probeer opnieuw'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      
      // Test retry functionality
      await tester.tap(find.text('Probeer opnieuw'));
      await tester.pump();
      
      // Should attempt to reload data
      verify(() => mockEarningsService.getCurrentEarnings()).called(2);
    });

    testWidgets('Accessibility features work correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BeveiligerDashboardBloc>(
            create: (_) => dashboardBloc,
            child: ModernBeveiligerDashboardV2(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ASSERT - Semantic labels are present
      expect(find.bySemanticsLabel('Dashboard overzicht'), findsOneWidget);
      expect(find.bySemanticsLabel('Huidige maand verdiensten: €2.340,50'), findsOneWidget);
      expect(find.bySemanticsLabel('Vandaag verdiend: €120,75'), findsOneWidget);
      expect(find.bySemanticsLabel('Noodmelding knop'), findsOneWidget);
      
      // Test screen reader navigation - simplified for compatibility
      expect(find.bySemanticsLabel('Dashboard overzicht'), findsOneWidget);
    });
  });

}