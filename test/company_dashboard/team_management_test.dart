import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/company_dashboard/models/team_management_data.dart';
import 'package:securyflex_app/company_dashboard/services/team_management_service.dart';
import 'package:securyflex_app/company_dashboard/services/guard_location_service.dart';
import 'package:securyflex_app/company_dashboard/services/coverage_gap_service.dart';
import 'package:securyflex_app/company_dashboard/services/emergency_management_service.dart';
import 'package:securyflex_app/company_dashboard/screens/team_management_screen.dart';
import 'package:securyflex_app/company_dashboard/localization/team_management_nl.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart' show GuardAvailabilityStatus;

void main() {
  group('Team Management Data Models', () {
    test('TeamStatusData should create and serialize correctly', () {
      final teamStatus = TeamStatusData(
        companyId: 'test_company',
        totalGuards: 10,
        availableGuards: 6,
        onDutyGuards: 3,
        offDutyGuards: 1,
        emergencyGuards: 0,
        lastUpdated: DateTime.now(),
        metrics: const TeamMetrics(
          averageRating: 4.5,
          reliabilityScore: 95.0,
          averageResponseTime: 12.5,
        ),
      );

      expect(teamStatus.companyId, equals('test_company'));
      expect(teamStatus.totalGuards, equals(10));
      expect(teamStatus.availableGuards, equals(6));
      expect(teamStatus.onDutyGuards, equals(3));
      expect(teamStatus.offDutyGuards, equals(1));
      expect(teamStatus.emergencyGuards, equals(0));
      expect(teamStatus.metrics.averageRating, equals(4.5));
      expect(teamStatus.metrics.reliabilityScore, equals(95.0));
      expect(teamStatus.metrics.averageResponseTime, equals(12.5));

      // Test serialization
      final map = teamStatus.toFirestore();
      expect(map['companyId'], isNull); // companyId is not included in toFirestore
      expect(map['totalGuards'], equals(10));
      expect(map['availableGuards'], equals(6));
      expect(map['onDutyGuards'], equals(3));
      expect(map['offDutyGuards'], equals(1));
      expect(map['emergencyGuards'], equals(0));
    });

    test('GuardLocationData should handle location data correctly', () {
      final guardLocation = GuardLocationData(
        guardId: 'guard_001',
        guardName: 'Jan de Vries',
        latitude: 52.3676,
        longitude: 4.9041,
        lastUpdate: DateTime.now(),
        status: GuardAvailabilityStatus.available,
        currentLocation: 'Amsterdam Centrum',
        isLocationEnabled: true,
      );

      expect(guardLocation.guardId, equals('guard_001'));
      expect(guardLocation.guardName, equals('Jan de Vries'));
      expect(guardLocation.latitude, equals(52.3676));
      expect(guardLocation.longitude, equals(4.9041));
      expect(guardLocation.status, equals(GuardAvailabilityStatus.available));
      expect(guardLocation.currentLocation, equals('Amsterdam Centrum'));
      expect(guardLocation.isLocationEnabled, isTrue);

      // Test serialization
      final map = guardLocation.toMap();
      expect(map['guardId'], equals('guard_001'));
      expect(map['guardName'], equals('Jan de Vries'));
      expect(map['latitude'], equals(52.3676));
      expect(map['longitude'], equals(4.9041));
      expect(map['status'], equals('available'));
      expect(map['currentLocation'], equals('Amsterdam Centrum'));
      expect(map['isLocationEnabled'], isTrue);
    });

    test('CoverageGap should handle severity levels correctly', () {
      final coverageGap = CoverageGap(
        gapId: 'gap_001',
        companyId: 'test_company',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 8)),
        location: 'Amsterdam Centrum',
        postalCode: '1012',
        severity: CoverageGapSeverity.high,
        affectedJobIds: ['job_001'],
        affectedJobTitles: ['Nachtbeveiliging'],
        createdAt: DateTime.now(),
      );

      expect(coverageGap.gapId, equals('gap_001'));
      expect(coverageGap.companyId, equals('test_company'));
      expect(coverageGap.location, equals('Amsterdam Centrum'));
      expect(coverageGap.postalCode, equals('1012'));
      expect(coverageGap.severity, equals(CoverageGapSeverity.high));
      expect(coverageGap.affectedJobIds, contains('job_001'));
      expect(coverageGap.affectedJobTitles, contains('Nachtbeveiliging'));
      expect(coverageGap.isResolved, isFalse);

      // Test serialization
      final map = coverageGap.toMap();
      expect(map['gapId'], equals('gap_001'));
      expect(map['companyId'], equals('test_company'));
      expect(map['location'], equals('Amsterdam Centrum'));
      expect(map['severity'], equals('high'));
      expect(map['isResolved'], isFalse);
    });

    test('TeamMetrics should calculate values correctly', () {
      const metrics = TeamMetrics(
        averageRating: 4.7,
        reliabilityScore: 95.5,
        averageResponseTime: 12.5,
        clientSatisfactionScore: 4.8,
        totalJobsCompleted: 156,
        jobsCompletedThisMonth: 23,
        revenueGenerated: 45230.50,
        revenueThisMonth: 8450.00,
        emergencyResponseCount: 3,
        emergencyResponseTime: 8.2,
      );

      expect(metrics.averageRating, equals(4.7));
      expect(metrics.reliabilityScore, equals(95.5));
      expect(metrics.averageResponseTime, equals(12.5));
      expect(metrics.clientSatisfactionScore, equals(4.8));
      expect(metrics.totalJobsCompleted, equals(156));
      expect(metrics.jobsCompletedThisMonth, equals(23));
      expect(metrics.revenueGenerated, equals(45230.50));
      expect(metrics.revenueThisMonth, equals(8450.00));
      expect(metrics.emergencyResponseCount, equals(3));
      expect(metrics.emergencyResponseTime, equals(8.2));

      // Test serialization
      final map = metrics.toMap();
      expect(map['averageRating'], equals(4.7));
      expect(map['reliabilityScore'], equals(95.5));
      expect(map['averageResponseTime'], equals(12.5));
      expect(map['clientSatisfactionScore'], equals(4.8));
      expect(map['totalJobsCompleted'], equals(156));
      expect(map['jobsCompletedThisMonth'], equals(23));
      expect(map['revenueGenerated'], equals(45230.50));
      expect(map['revenueThisMonth'], equals(8450.00));
      expect(map['emergencyResponseCount'], equals(3));
      expect(map['emergencyResponseTime'], equals(8.2));
    });
  });

  group('Team Management Service', () {
    late TeamManagementService service;

    setUp(() {
      service = TeamManagementService();
    });

    test('should generate mock team data correctly', () {
      final mockData = service.generateMockTeamData('test_company');

      expect(mockData.companyId, equals('test_company'));
      expect(mockData.totalGuards, greaterThan(0));
      expect(mockData.activeGuardLocations, isNotEmpty);
      expect(mockData.metrics.averageRating, greaterThanOrEqualTo(0.0));
      expect(mockData.metrics.averageRating, lessThanOrEqualTo(5.0));
      expect(mockData.metrics.reliabilityScore, greaterThanOrEqualTo(0.0));
      expect(mockData.metrics.reliabilityScore, lessThanOrEqualTo(100.0));
      expect(mockData.lastUpdated, isNotNull);

      // Verify guard locations have valid data
      for (final guard in mockData.activeGuardLocations) {
        expect(guard.guardId, isNotEmpty);
        expect(guard.guardName, isNotEmpty);
        expect(guard.latitude, isNotNull);
        expect(guard.longitude, isNotNull);
        expect(guard.lastUpdate, isNotNull);
        expect(guard.isLocationEnabled, isTrue);
      }
    });

    test('should handle cache correctly', () {
      expect(service.isCacheFresh, isFalse);
      expect(service.getCachedTeamStatus(), isNull);
      expect(service.getCachedGuardLocations(), isNull);
      expect(service.getCachedCoverageGaps(), isNull);
    });
  });

  group('Guard Location Service', () {
    late GuardLocationService service;

    setUp(() {
      service = GuardLocationService();
    });

    test('should calculate distance correctly', () {
      // Distance between Amsterdam and Rotterdam (approximately 57 km)
      final distance = service.calculateDistance(
        52.3676, 4.9041, // Amsterdam
        51.9244, 4.4777, // Rotterdam
      );

      expect(distance, greaterThan(50.0));
      expect(distance, lessThan(70.0));
    });

    test('should find nearest guards correctly', () {
      final guards = service.generateMockLocationData('test_company');
      final targetLat = 52.3676; // Amsterdam center
      final targetLon = 4.9041;

      final nearestGuards = service.findNearestGuards(
        guards,
        targetLat,
        targetLon,
        maxDistanceKm: 10.0,
        maxResults: 3,
      );

      expect(nearestGuards.length, lessThanOrEqualTo(3));
      
      // Verify all returned guards are available
      for (final guard in nearestGuards) {
        expect(guard.status, equals(GuardAvailabilityStatus.available));
      }
    });

    test('should generate mock location data correctly', () {
      final mockData = service.generateMockLocationData('test_company');

      expect(mockData, isNotEmpty);
      
      for (final guard in mockData) {
        expect(guard.guardId, isNotEmpty);
        expect(guard.guardName, isNotEmpty);
        expect(guard.latitude, isNotNull);
        expect(guard.longitude, isNotNull);
        expect(guard.lastUpdate, isNotNull);
        expect(guard.isLocationEnabled, isTrue);
        
        // Verify coordinates are reasonable (around Amsterdam area)
        expect(guard.latitude!, greaterThan(52.0));
        expect(guard.latitude!, lessThan(53.0));
        expect(guard.longitude!, greaterThan(4.0));
        expect(guard.longitude!, lessThan(5.0));
      }
    });
  });

  group('Coverage Gap Service', () {
    late CoverageGapService service;

    setUp(() {
      service = CoverageGapService();
    });

    test('should generate mock coverage gaps correctly', () {
      final mockGaps = service.generateMockCoverageGaps('test_company');

      for (final gap in mockGaps) {
        expect(gap.companyId, equals('test_company'));
        expect(gap.gapId, isNotEmpty);
        expect(gap.location, isNotEmpty);
        expect(gap.postalCode, isNotEmpty);
        expect(gap.startTime, isNotNull);
        expect(gap.endTime, isNotNull);
        expect(gap.endTime.isAfter(gap.startTime), isTrue);
        expect(gap.createdAt, isNotNull);
        expect(gap.isResolved, isFalse);
        expect(gap.affectedJobIds, isNotEmpty);
        expect(gap.affectedJobTitles, isNotEmpty);
      }
    });
  });

  group('Emergency Management Service', () {
    test('EmergencyAlert should serialize correctly', () {
      final alert = EmergencyAlert(
        alertId: 'alert_001',
        companyId: 'test_company',
        alertType: EmergencyAlertType.guardEmergency,
        severity: CoverageGapSeverity.critical,
        title: 'Test Emergency',
        description: 'Test emergency description',
        guardId: 'guard_001',
        location: 'Amsterdam Centrum',
        latitude: 52.3676,
        longitude: 4.9041,
        createdAt: DateTime.now(),
      );

      expect(alert.alertId, equals('alert_001'));
      expect(alert.companyId, equals('test_company'));
      expect(alert.alertType, equals(EmergencyAlertType.guardEmergency));
      expect(alert.severity, equals(CoverageGapSeverity.critical));
      expect(alert.title, equals('Test Emergency'));
      expect(alert.description, equals('Test emergency description'));
      expect(alert.guardId, equals('guard_001'));
      expect(alert.location, equals('Amsterdam Centrum'));
      expect(alert.latitude, equals(52.3676));
      expect(alert.longitude, equals(4.9041));
      expect(alert.isResolved, isFalse);

      // Test serialization
      final map = alert.toMap();
      expect(map['alertId'], equals('alert_001'));
      expect(map['companyId'], equals('test_company'));
      expect(map['alertType'], equals('guardEmergency'));
      expect(map['severity'], equals('critical'));
      expect(map['title'], equals('Test Emergency'));
      expect(map['description'], equals('Test emergency description'));
      expect(map['guardId'], equals('guard_001'));
      expect(map['location'], equals('Amsterdam Centrum'));
      expect(map['latitude'], equals(52.3676));
      expect(map['longitude'], equals(4.9041));
      expect(map['isResolved'], isFalse);
    });
  });

  group('Dutch Localization', () {
    test('should provide correct Dutch translations', () {
      expect(TeamManagementNL.teamManagement, equals('Team Management'));
      expect(TeamManagementNL.available, equals('Beschikbaar'));
      expect(TeamManagementNL.onDuty, equals('Actief'));
      expect(TeamManagementNL.unavailable, equals('Niet Beschikbaar'));
      expect(TeamManagementNL.emergency, equals('Noodgeval'));
      expect(TeamManagementNL.coverageGaps, equals('Dekking Problemen'));
      expect(TeamManagementNL.findCoverage, equals('Zoek Dekking'));
      expect(TeamManagementNL.emergencyAlert, equals('Noodmelding'));
      expect(TeamManagementNL.planningAndSchedules, equals('Planning & Roosters'));
      expect(TeamManagementNL.teamAnalytics, equals('Team Analytics'));
    });

    test('should format helper methods correctly', () {
      expect(TeamManagementNL.guardCount(1), equals('1 beveiliger'));
      expect(TeamManagementNL.guardCount(5), equals('5 beveiligers'));
      
      expect(TeamManagementNL.timeAgoFormat(const Duration(minutes: 5)), equals('5 minuten geleden'));
      expect(TeamManagementNL.timeAgoFormat(const Duration(hours: 2)), equals('2 uur geleden'));
      expect(TeamManagementNL.timeAgoFormat(const Duration(days: 1)), equals('1 dagen geleden'));
      
      expect(TeamManagementNL.distanceFormat(0.5), equals('500 meter'));
      expect(TeamManagementNL.distanceFormat(2.5), equals('2.5 kilometer'));
      
      expect(TeamManagementNL.currencyFormat(1234.56), equals('€1234,56'));
      expect(TeamManagementNL.percentageFormat(95.5), equals('95.5%'));
      expect(TeamManagementNL.ratingFormat(4.7), equals('4.7'));
    });

    test('should provide correct status descriptions', () {
      expect(TeamManagementNL.emergencyStatusDescription('normal'), 
             equals('Alle systemen operationeel'));
      expect(TeamManagementNL.emergencyStatusDescription('warning'), 
             equals('Aandacht vereist'));
      expect(TeamManagementNL.emergencyStatusDescription('critical'), 
             equals('Onmiddellijke actie nodig'));
      expect(TeamManagementNL.emergencyStatusDescription('emergency'), 
             equals('Noodsituatie actief'));
      
      expect(TeamManagementNL.coverageGapSeverityDescription('low'), 
             equals('Minimale impact op service'));
      expect(TeamManagementNL.coverageGapSeverityDescription('medium'), 
             equals('Matige impact op service'));
      expect(TeamManagementNL.coverageGapSeverityDescription('high'), 
             equals('Significante impact op service'));
      expect(TeamManagementNL.coverageGapSeverityDescription('critical'), 
             equals('Kritieke impact op service'));
    });
  });

  group('Team Management Screen Widget Tests', () {
    testWidgets('should display team management screen with tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const TeamManagementScreen(),
        ),
      );

      // Wait for initial load
      await tester.pump(const Duration(milliseconds: 100));

      // Verify tabs are present
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Planning'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);

      // Verify header is present
      expect(find.text('Team Management'), findsOneWidget);
    });

    testWidgets('should maintain TabController state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const TeamManagementScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial tab is Status (index 0)
      final TabBar tabBar = tester.widget(find.byType(TabBar));
      expect(tabBar.controller?.index, equals(0));

      // Switch to Planning tab
      await tester.tap(find.text('Planning'));
      await tester.pumpAndSettle();

      // Verify tab controller updated
      expect(tabBar.controller?.index, equals(1));

      // Switch to Analytics tab
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Verify tab controller updated
      expect(tabBar.controller?.index, equals(2));
    });

    testWidgets('should handle TabController disposal correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const TeamManagementScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate away (simulating disposal)
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const Scaffold(body: Text('Different Screen')),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no exceptions are thrown during disposal
      expect(find.text('Different Screen'), findsOneWidget);
    });

    testWidgets('should show loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const TeamManagementScreen(),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Team gegevens laden...'), findsOneWidget);
    });

    testWidgets('should display team status after loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const TeamManagementScreen(),
        ),
      );

      // Wait for loading to complete
      await tester.pump(const Duration(milliseconds: 900));

      // Should show team status cards
      expect(find.text('Totaal'), findsOneWidget);
      expect(find.text('Beschikbaar'), findsOneWidget);
      expect(find.text('Actief'), findsOneWidget);
      expect(find.text('Dekking'), findsOneWidget);
    });

    testWidgets('should switch between tabs correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const TeamManagementScreen(),
        ),
      );

      // Wait for loading to complete
      await tester.pump(const Duration(milliseconds: 900));

      // Tap on Planning tab
      await tester.tap(find.text('Planning'));
      await tester.pumpAndSettle();

      // Should show planning content
      expect(find.text('Planning & Roosters'), findsOneWidget);
      expect(find.text('Vandaag'), findsOneWidget);

      // Tap on Analytics tab
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Should show analytics content
      expect(find.text('Team Analytics'), findsOneWidget);
    });

    testWidgets('should display guard status list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const TeamManagementScreen(),
        ),
      );

      // Wait for loading to complete
      await tester.pump(const Duration(milliseconds: 900));

      // Should show guard status list
      expect(find.text('Team Status'), findsOneWidget);

      // Should show guard names from mock data
      expect(find.text('Jan de Vries'), findsOneWidget);
      expect(find.text('Marie Bakker'), findsOneWidget);
      expect(find.text('Piet Janssen'), findsOneWidget);
    });

    testWidgets('should display coverage gaps when present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const TeamManagementScreen(),
        ),
      );

      // Wait for loading to complete
      await tester.pump(const Duration(milliseconds: 900));

      // Should show coverage gaps section
      expect(find.text('Dekking Problemen'), findsOneWidget);
      expect(find.text('Rotterdam Centrum'), findsOneWidget);
      expect(find.text('Oplossen'), findsOneWidget);
    });

    testWidgets('should display quick action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const TeamManagementScreen(),
        ),
      );

      // Wait for loading to complete
      await tester.pump(const Duration(milliseconds: 900));

      // Should show quick action buttons
      expect(find.text('Noodmelding'), findsOneWidget);
      expect(find.text('Zoek Dekking'), findsOneWidget);
    });

    testWidgets('should display schedule tab content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const TeamManagementScreen(),
        ),
      );

      // Wait for loading to complete
      await tester.pump(const Duration(milliseconds: 900));

      // Tap on Planning tab
      await tester.tap(find.text('Planning'));
      await tester.pumpAndSettle();

      // Should show schedule content
      expect(find.text('Planning & Roosters'), findsOneWidget);
      expect(find.text('Vandaag'), findsOneWidget);
      expect(find.text('Deze Week'), findsOneWidget);
      expect(find.text('06:00 - 14:00'), findsOneWidget);
      expect(find.text('14:00 - 22:00'), findsOneWidget);
      expect(find.text('22:00 - 06:00'), findsOneWidget);
      expect(find.text('Optimaliseer Rooster'), findsOneWidget);
      expect(find.text('Nieuwe Shift'), findsOneWidget);
    });

    testWidgets('should display analytics tab content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const TeamManagementScreen(),
        ),
      );

      // Wait for loading to complete
      await tester.pump(const Duration(milliseconds: 900));

      // Tap on Analytics tab
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Should show analytics content
      expect(find.text('Team Analytics'), findsOneWidget);
      expect(find.text('Gem. Rating'), findsOneWidget);
      expect(find.text('Betrouwbaar'), findsOneWidget);
      expect(find.text('Responstijd'), findsOneWidget);
      expect(find.text('Omzet'), findsOneWidget);
    });
  });
}
