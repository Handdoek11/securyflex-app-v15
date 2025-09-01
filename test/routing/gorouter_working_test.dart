import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/routing/app_router.dart';
import 'package:securyflex_app/routing/app_routes.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  group('GoRouter Working Tests', () {
    testWidgets('GoRouter navigation works', (WidgetTester tester) async {
      // Initialize router
      AppRouter.initialize();
      
      // Build app with router
      await tester.pumpWidget(
        MaterialApp.router(
          title: 'Test',
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          routerConfig: AppRouter.router,
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show login screen (enhanced glassmorphic login)
      expect(find.text('E-mailadres'), findsWidgets);
      
      // Navigate to register programmatically
      AppRouter.router.go('/register');
      await tester.pumpAndSettle();
      
      // Should be on registration screen now
      expect(find.text('Account Aanmaken'), findsWidgets);
    });
    
    test('Route structure is correct', () {
      // Initialize router
      AppRouter.initialize();
      
      // Verify router is not null
      expect(AppRouter.router, isNotNull);
      
      // Verify routes are defined
      expect(AppRoutes.login, equals('/login'));
      expect(AppRoutes.beveiligerDashboard, equals('/beveiliger/dashboard'));
      expect(AppRoutes.companyDashboard, equals('/company/dashboard'));
    });
  });
}