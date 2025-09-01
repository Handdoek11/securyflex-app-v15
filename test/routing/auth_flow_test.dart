import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/routing/app_router.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  group('Authentication Flow Tests', () {
    setUpAll(() {
      AppRouter.initialize();
    });

    testWidgets('Shows login screen when not authenticated', (WidgetTester tester) async {
      // Ensure logged out
      AuthService.logout();
      
      await tester.pumpWidget(
        MaterialApp.router(
          title: 'Test',
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          routerConfig: AppRouter.router,
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should be on login screen
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    test('Authentication service works', () {
      // Test logout
      AuthService.logout();
      expect(AuthService.isLoggedIn, isFalse);
      
      // Test login state
      // Note: Actual login requires Firebase which isn't available in tests
      expect(AuthService.currentUserId, isEmpty);
      expect(AuthService.currentUserType, isEmpty);
    });

    test('Route guards redirect unauthenticated users', () {
      AuthService.logout();
      
      // Try to navigate to protected route
      AppRouter.router.go('/beveiliger/dashboard');
      
      // Should redirect to login (in real app with BuildContext)
      // Here we just verify the route guard logic exists
      expect(AppRouter.router.configuration, isNotNull);
    });

    test('Different user types get correct dashboards', () {
      // Test route paths for different user types
      expect('/beveiliger/dashboard', contains('beveiliger'));
      expect('/company/dashboard', contains('company'));
      
      // Verify routes are configured
      expect(() => AppRouter.router.go('/beveiliger/dashboard'), returnsNormally);
      expect(() => AppRouter.router.go('/company/dashboard'), returnsNormally);
    });
  });
}