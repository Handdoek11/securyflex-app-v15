import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/beveiliger_dashboard/modern_beveiliger_dashboard_v2.dart';
import 'package:securyflex_app/company_dashboard/modern_company_dashboard.dart';
import 'package:securyflex_app/modern_dashboard_routes.dart';
import 'package:securyflex_app/unified_components/modern_earnings_widget.dart';
import 'package:securyflex_app/unified_components/modern_quick_actions_widget.dart';
import 'package:securyflex_app/unified_components/modern_active_jobs_widget.dart';
import 'package:securyflex_app/unified_components/modern_business_intelligence_widget.dart';
import 'package:securyflex_app/unified_components/modern_job_management_widget.dart';
import 'package:securyflex_app/unified_components/modern_applications_overview_widget.dart';

void main() {
  group('Modern Dashboard Tests', () {
    
    group('Modern Beveiliger Dashboard', () {
      testWidgets('should render without errors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: const ModernBeveiligerDashboardV2(),
          ),
        );

        // Wait for animations to complete
        await tester.pumpAndSettle();

        // Verify dashboard renders
        expect(find.byType(ModernBeveiligerDashboardV2), findsOneWidget);
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Welkom terug, Jan!'), findsOneWidget);
      });

      testWidgets('should display earnings widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: const ModernBeveiligerDashboardV2(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify earnings widget is present
        expect(find.byType(ModernEarningsWidget), findsOneWidget);
        expect(find.text('Verdiensten'), findsOneWidget);
        expect(find.text('€1.280,00'), findsOneWidget);
      });

      testWidgets('should display quick actions widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: const ModernBeveiligerDashboardV2(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify quick actions widget is present
        expect(find.byType(ModernQuickActionsWidget), findsOneWidget);
        expect(find.text('Snelle Acties'), findsOneWidget);
        expect(find.text('Incident Melden'), findsOneWidget);
      });

      testWidgets('should display active jobs widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: const ModernBeveiligerDashboardV2(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify active jobs widget is present
        expect(find.byType(ModernActiveJobsWidget), findsOneWidget);
        expect(find.text('Actieve Opdrachten'), findsOneWidget);
      });

      testWidgets('should handle refresh', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: const ModernBeveiligerDashboardV2(),
          ),
        );

        await tester.pumpAndSettle();

        // Find and trigger refresh
        await tester.fling(find.byType(SingleChildScrollView), const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Verify dashboard still renders after refresh
        expect(find.byType(ModernBeveiligerDashboardV2), findsOneWidget);
      });
    });

    group('Modern Company Dashboard', () {
      testWidgets('should render without errors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const ModernCompanyDashboard(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify dashboard renders
        expect(find.byType(ModernCompanyDashboard), findsOneWidget);
        expect(find.text('Bedrijf Dashboard'), findsOneWidget);
        expect(find.text('Welkom terug, SecureGuard BV!'), findsOneWidget);
      });

      testWidgets('should display business intelligence widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const ModernCompanyDashboard(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify business intelligence widget is present
        expect(find.byType(ModernBusinessIntelligenceWidget), findsOneWidget);
        expect(find.text('Business Intelligence'), findsOneWidget);
        expect(find.text('€45.280'), findsOneWidget);
      });

      testWidgets('should display job management widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const ModernCompanyDashboard(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify job management widget is present
        expect(find.byType(ModernJobManagementWidget), findsOneWidget);
        expect(find.text('Opdracht Beheer'), findsOneWidget);
        expect(find.text('Nieuwe Opdracht'), findsOneWidget);
      });

      testWidgets('should display applications overview widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const ModernCompanyDashboard(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify applications overview widget is present
        expect(find.byType(ModernApplicationsOverviewWidget), findsOneWidget);
        expect(find.text('Sollicitaties Overzicht'), findsOneWidget);
        expect(find.text('Beoordelen'), findsOneWidget);
      });
    });

    group('Dashboard Routing', () {
      testWidgets('should route to correct dashboard for guard role', (WidgetTester tester) async {
        final dashboard = ModernDashboardRoutes.getDashboardForRole(UserRole.guard);
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: dashboard,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(ModernBeveiligerDashboardV2), findsOneWidget);
      });

      testWidgets('should route to correct dashboard for company role', (WidgetTester tester) async {
        final dashboard = ModernDashboardRoutes.getDashboardForRole(UserRole.company);
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: dashboard,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(ModernCompanyDashboard), findsOneWidget);
      });

      test('should return correct route names', () {
        expect(
          ModernDashboardRoutes.getRouteNameForRole(UserRole.guard),
          equals('/modern-beveiliger-dashboard'),
        );
        expect(
          ModernDashboardRoutes.getRouteNameForRole(UserRole.company),
          equals('/modern-company-dashboard'),
        );
        expect(
          ModernDashboardRoutes.getRouteNameForRole(UserRole.admin),
          equals('/modern-admin-dashboard'),
        );
      });
    });

    group('Performance Tests', () {
      testWidgets('beveiliger dashboard should load within performance requirements', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: const ModernBeveiligerDashboardV2(),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should load within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        print('Beveiliger dashboard loaded in ${stopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('company dashboard should load within performance requirements', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const ModernCompanyDashboard(),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should load within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        print('Company dashboard loaded in ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Widget Integration Tests', () {
      testWidgets('earnings widget should handle animation controller', (WidgetTester tester) async {
        late AnimationController controller;
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Builder(
              builder: (context) {
                controller = AnimationController(
                  duration: const Duration(milliseconds: 500),
                  vsync: const TestVSync(),
                );
                return ModernEarningsWidget(
                  animationController: controller,
                  animation: controller,
                );
              },
            ),
          ),
        );

        // Start animation
        controller.forward();
        await tester.pumpAndSettle();

        expect(find.byType(ModernEarningsWidget), findsOneWidget);
        expect(find.text('Verdiensten'), findsOneWidget);

        controller.dispose();
      });

      testWidgets('quick actions should handle button taps', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: const Scaffold(
              body: ModernQuickActionsWidget(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap incident report button
        final incidentButton = find.text('Incident Melden');
        expect(incidentButton, findsOneWidget);
        
        await tester.tap(incidentButton);
        await tester.pumpAndSettle();

        // Should show coming soon message
        expect(find.text('Incident rapportage komt binnenkort beschikbaar'), findsOneWidget);
      });
    });
  });
}

class TestVSync implements TickerProvider {
  const TestVSync();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
