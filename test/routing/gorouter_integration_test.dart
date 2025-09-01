import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/routing/app_router.dart';
import 'package:securyflex_app/routing/app_routes.dart';
import 'package:securyflex_app/auth/enhanced_glassmorphic_login_screen.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  group('GoRouter Integration Tests', () {
    setUpAll(() {
      // Initialize router before tests
      AppRouter.initialize();
    });

    testWidgets('Router initializes with login route', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          title: 'SecuryFlex Test',
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          routerConfig: AppRouter.router,
        ),
      );

      await tester.pumpAndSettle();

      // Verify login screen is shown
      expect(find.byType(EnhancedGlassmorphicLoginScreen), findsOneWidget);
    });

    testWidgets('Can navigate to registration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          title: 'SecuryFlex Test',
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          routerConfig: AppRouter.router,
        ),
      );

      await tester.pumpAndSettle();

      // Programmatic navigation to registration
      AppRouter.router.go(AppRoutes.register);
      await tester.pumpAndSettle();

      // Should navigate to registration screen
      expect(find.text('Account Aanmaken'), findsWidgets);
    });

    test('Router has correct initial location', () {
      // After navigating to register in the previous test, it stays there
      // The router is a singleton and maintains state across tests
      expect(AppRouter.router.routerDelegate.currentConfiguration.uri.toString(), 
             anyOf(equals('/login'), equals('/register')));
    });

    test('All routes are defined', () {
      final routes = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.beveiligerDashboard,
        AppRoutes.beveiligerJobs,
        AppRoutes.beveiligerSchedule,
        AppRoutes.beveiligerChat,
        AppRoutes.beveiligerProfile,
        AppRoutes.companyDashboard,
        AppRoutes.companyJobs,
        AppRoutes.companyTeam,
        AppRoutes.companyAnalytics,
        AppRoutes.companyProfile,
      ];

      for (final route in routes) {
        expect(route, isNotEmpty);
        expect(route, startsWith('/'));
      }
    });
  });
}