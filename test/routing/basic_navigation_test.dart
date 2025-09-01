import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/routing/app_router.dart';
import 'package:securyflex_app/routing/app_routes.dart';

void main() {
  group('Basic Navigation Tests', () {
    setUp(() {
      // Initialize fresh for each test to avoid state issues
      AppRouter.initialize();
    });

    test('Router initializes correctly', () {
      expect(AppRouter.router, isNotNull);
    });

    test('Routes are defined correctly', () {
      // Verify the routes are correctly defined
      // Note: Actual navigation requires BuildContext which isn't available in unit tests
      expect(AppRoutes.login, equals('/login'));
      
      // Verify router accepts the login route (doesn't throw)
      expect(() => AppRouter.router.go('/login'), returnsNormally);
    });

    test('Can navigate programmatically', () {
      // Test navigation by verifying routes exist
      // Note: Actual navigation requires BuildContext which isn't available in unit tests
      
      // Verify we can create navigation paths
      expect(AppRoutes.login, isNotEmpty);
      expect(AppRoutes.register, isNotEmpty);
      expect(AppRoutes.beveiligerDashboard, isNotEmpty);
      
      // Verify router accepts these paths (doesn't throw)
      expect(() => AppRouter.router.go('/login'), returnsNormally);
      expect(() => AppRouter.router.go('/register'), returnsNormally);
      expect(() => AppRouter.router.go('/beveiliger/dashboard'), returnsNormally);
    });

    test('Route constants are correctly defined', () {
      expect(AppRoutes.login, equals('/login'));
      expect(AppRoutes.register, equals('/register'));
      expect(AppRoutes.beveiligerDashboard, equals('/beveiliger/dashboard'));
      expect(AppRoutes.companyDashboard, equals('/company/dashboard'));
    });
  });
}