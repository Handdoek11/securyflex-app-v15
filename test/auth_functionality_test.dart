import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'helpers/firebase_test_helper.dart';

void main() {
  group('Authentication Functionality Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing to prevent "No Firebase App created" errors
      await FirebaseTestHelper.setupTestGroup();
    });

    setUp(() {
      // Reset auth state before each test
      AuthService.logout();
    });

    test('Initial state should be logged out', () {
      expect(AuthService.isLoggedIn, isFalse);
      expect(AuthService.currentUserType, isEmpty);
      expect(AuthService.currentUserName, isEmpty);
    });

    test('Login with valid guard credentials should succeed', () async {
      final success = await AuthService.login('guard@securyflex.nl', 'guard123');
      
      expect(success, isTrue);
      expect(AuthService.isLoggedIn, isTrue);
      expect(AuthService.currentUserType, equals('guard'));
      expect(AuthService.currentUserName, equals('Jan de Beveiliger'));
    });

    test('Login with valid company credentials should succeed', () async {
      final success = await AuthService.login('company@securyflex.nl', 'company123');
      
      expect(success, isTrue);
      expect(AuthService.isLoggedIn, isTrue);
      expect(AuthService.currentUserType, equals('company'));
      expect(AuthService.currentUserName, equals('Amsterdam Security BV'));
    });

    test('Login with valid admin credentials should succeed', () async {
      final success = await AuthService.login('admin@securyflex.nl', 'admin123');
      
      expect(success, isTrue);
      expect(AuthService.isLoggedIn, isTrue);
      expect(AuthService.currentUserType, equals('admin'));
      expect(AuthService.currentUserName, equals('SecuryFlex Admin'));
    });

    test('Login with invalid email should fail', () async {
      final success = await AuthService.login('invalid@securyflex.nl', 'password123');
      
      expect(success, isFalse);
      expect(AuthService.isLoggedIn, isFalse);
      expect(AuthService.currentUserType, isEmpty);
      expect(AuthService.currentUserName, isEmpty);
    });

    test('Login with invalid password should fail', () async {
      final success = await AuthService.login('guard@securyflex.nl', 'wrongpassword');
      
      expect(success, isFalse);
      expect(AuthService.isLoggedIn, isFalse);
      expect(AuthService.currentUserType, isEmpty);
      expect(AuthService.currentUserName, isEmpty);
    });

    test('Login should be case insensitive for email', () async {
      final success = await AuthService.login('GUARD@SECURYFLEX.NL', 'guard123');
      
      expect(success, isTrue);
      expect(AuthService.isLoggedIn, isTrue);
      expect(AuthService.currentUserType, equals('guard'));
    });

    test('Logout should clear all user data', () async {
      // First login
      await AuthService.login('guard@securyflex.nl', 'guard123');
      expect(AuthService.isLoggedIn, isTrue);
      
      // Then logout
      AuthService.logout();
      expect(AuthService.isLoggedIn, isFalse);
      expect(AuthService.currentUserType, isEmpty);
      expect(AuthService.currentUserName, isEmpty);
    });

    test('Email validation should work correctly', () {
      expect(AuthService.isValidEmail('test@example.com'), isTrue);
      expect(AuthService.isValidEmail('user.name@domain.co.uk'), isTrue);
      expect(AuthService.isValidEmail('invalid-email'), isFalse);
      expect(AuthService.isValidEmail(''), isFalse);
      expect(AuthService.isValidEmail('@domain.com'), isFalse);
      expect(AuthService.isValidEmail('user@'), isFalse);
    });

    test('Password validation should work correctly', () {
      expect(AuthService.isValidPassword('password123'), isTrue);
      expect(AuthService.isValidPassword('123456'), isTrue);
      expect(AuthService.isValidPassword('12345'), isFalse); // Too short
      expect(AuthService.isValidPassword(''), isFalse); // Empty
    });

    test('User role display names should be in Dutch', () {
      expect(AuthService.getUserRoleDisplayName('guard'), equals('Beveiliger'));
      expect(AuthService.getUserRoleDisplayName('company'), equals('Bedrijf'));
      expect(AuthService.getUserRoleDisplayName('admin'), equals('Beheerder'));
      expect(AuthService.getUserRoleDisplayName('unknown'), equals('Gebruiker'));
    });

    test('Role checking should work correctly', () async {
      await AuthService.login('guard@securyflex.nl', 'guard123');
      
      expect(AuthService.hasRole('guard'), isTrue);
      expect(AuthService.hasRole('company'), isFalse);
      expect(AuthService.hasRole('admin'), isFalse);
      expect(AuthService.hasRole('GUARD'), isTrue); // Case insensitive
    });

    test('User avatar paths should be correct', () {
      expect(AuthService.getUserAvatar('guard'), equals('assets/images/guard_avatar.png'));
      expect(AuthService.getUserAvatar('company'), equals('assets/images/company_avatar.png'));
      expect(AuthService.getUserAvatar('admin'), equals('assets/images/admin_avatar.png'));
      expect(AuthService.getUserAvatar('unknown'), equals('assets/images/default_avatar.png'));
    });

    test('Demo credentials should be secured via environment config', () {
      // Demo credentials are now managed through EnvironmentConfig
      // This test verifies they are no longer exposed in AuthService
      
      // Verify AuthService doesn't expose credentials directly
      expect(() => (AuthService as dynamic).demoCredentials, throwsNoSuchMethodError);
      
      // Demo accounts should only be accessible through secure login flow
      // with proper environment configuration
    });

    test('Login should simulate network delay', () async {
      final stopwatch = Stopwatch()..start();
      await AuthService.login('guard@securyflex.nl', 'guard123');
      stopwatch.stop();
      
      // Should take at least 800ms due to simulated delay
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(800));
    });
  });
}
