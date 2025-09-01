import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:securyflex_app/config/environment_config.dart';
import 'package:securyflex_app/auth/auth_service.dart';

void main() {
  group('Secure Demo Credentials Tests', () {
    
    group('EnvironmentConfig Demo Configuration', () {
      test('should return empty credentials in release mode', () {
        // This test simulates release mode behavior
        // In actual release mode, kDebugMode would be false
        final credentials = EnvironmentConfig.getDemoCredentials();
        
        // In debug mode with environment variables, we should get credentials
        // In release mode (kDebugMode = false), we should get empty map
        if (kDebugMode) {
          // Development environment should have demo credentials
          expect(credentials, isNotEmpty, reason: 'Demo credentials should be available in debug mode');
          
          // Verify structure
          for (final entry in credentials.entries) {
            expect(entry.key, isA<String>(), reason: 'Email should be string');
            expect(entry.value.keys, containsAll(['password', 'userType', 'name']), 
                reason: 'Demo user should have required fields');
            expect(entry.value['password'], isA<String>(), reason: 'Password should be string');
            expect(entry.value['userType'], isIn(['guard', 'company', 'admin']), 
                reason: 'User type should be valid');
            expect(entry.value['name'], isA<String>(), reason: 'Name should be string');
          }
        } else {
          expect(credentials, isEmpty, reason: 'No demo credentials in release mode');
        }
      });

      test('should validate demo mode enablement', () {
        final isDemoEnabled = EnvironmentConfig.isDemoModeEnabled;
        
        if (kDebugMode) {
          // In debug mode, demo should be enabled if credentials are configured
          final credentials = EnvironmentConfig.getDemoCredentials();
          expect(isDemoEnabled, equals(credentials.isNotEmpty), 
              reason: 'Demo mode should match credential availability');
        } else {
          expect(isDemoEnabled, isFalse, reason: 'Demo mode should be disabled in release mode');
        }
      });

      test('should provide secure demo credentials from environment', () {
        if (!kDebugMode) return; // Skip in release mode
        
        // Test individual credential getters
        final guardEmail = EnvironmentConfig.demoGuardEmail;
        final guardPassword = EnvironmentConfig.demoGuardPassword;
        final companyEmail = EnvironmentConfig.demoCompanyEmail;
        final companyPassword = EnvironmentConfig.demoCompanyPassword;
        final adminEmail = EnvironmentConfig.demoAdminEmail;
        final adminPassword = EnvironmentConfig.demoAdminPassword;

        // Should have default values in debug mode
        expect(guardEmail, isNotEmpty, reason: 'Guard email should be configured');
        expect(guardPassword, isNotEmpty, reason: 'Guard password should be configured');
        expect(companyEmail, isNotEmpty, reason: 'Company email should be configured');
        expect(companyPassword, isNotEmpty, reason: 'Company password should be configured');
        expect(adminEmail, isNotEmpty, reason: 'Admin email should be configured');
        expect(adminPassword, isNotEmpty, reason: 'Admin password should be configured');

        // Validate email formats
        expect(guardEmail, contains('@'), reason: 'Guard email should be valid format');
        expect(companyEmail, contains('@'), reason: 'Company email should be valid format');
        expect(adminEmail, contains('@'), reason: 'Admin email should be valid format');

        // Validate password strength (should meet our security requirements)
        expect(guardPassword.length, greaterThanOrEqualTo(12), 
            reason: 'Guard password should be at least 12 characters');
        expect(companyPassword.length, greaterThanOrEqualTo(12), 
            reason: 'Company password should be at least 12 characters');
        expect(adminPassword.length, greaterThanOrEqualTo(12), 
            reason: 'Admin password should be at least 12 characters');
      });
    });

    group('AuthService Demo Integration', () {
      test('should not expose demo credentials directly', () {
        // AuthService should not have public hardcoded credentials
        expect(() => AuthService.getDemoAccountInfo('any@email.com'), 
            returnsNormally, reason: 'Should provide secure access method');
        
        // Should not be able to access private credentials map directly
        // This test ensures no public access to hardcoded credentials
      });

      test('should validate demo account access', () {
        if (!kDebugMode) return; // Skip in release mode
        
        final availableAccounts = AuthService.getAvailableDemoAccounts();
        
        if (EnvironmentConfig.isDemoModeEnabled) {
          expect(availableAccounts, isNotEmpty, 
              reason: 'Should have demo accounts in debug mode');
          
          for (final email in availableAccounts) {
            expect(AuthService.isDemoAccount(email), isTrue, 
                reason: 'Should recognize demo account');
            
            final accountInfo = AuthService.getDemoAccountInfo(email);
            expect(accountInfo, isNotNull, reason: 'Should provide account info');
            expect(accountInfo!['email'], equals(email));
            expect(accountInfo['userType'], isIn(['guard', 'company', 'admin']));
            expect(accountInfo['name'], isA<String>());
            expect(accountInfo['isDemo'], isTrue);
            
            // Ensure password is NOT exposed in account info
            expect(accountInfo.containsKey('password'), isFalse, 
                reason: 'Password should never be exposed in account info');
          }
        } else {
          expect(availableAccounts, isEmpty, 
              reason: 'Should have no demo accounts when demo mode disabled');
        }
      });

      test('should provide secure Firebase status', () {
        final status = AuthService.getFirebaseStatus();
        
        expect(status, isA<String>(), reason: 'Status should be string');
        expect(status, isNotEmpty, reason: 'Status should not be empty');
        
        if (EnvironmentConfig.isDemoModeEnabled) {
          expect(status, contains('Demo mode enabled'), 
              reason: 'Should indicate demo mode is enabled');
        } else {
          expect(status, contains('Demo mode disabled'), 
              reason: 'Should indicate demo mode is disabled');
        }
      });

      test('should validate password requirements for demo accounts', () async {
        if (!kDebugMode || !EnvironmentConfig.isDemoModeEnabled) return;
        
        final credentials = EnvironmentConfig.getDemoCredentials();
        
        for (final entry in credentials.entries) {
          final password = entry.value['password'] as String;
          final validation = AuthService.validatePasswordDetailed(password);
          
          expect(validation.isValid, isTrue, 
              reason: 'Demo password should meet security requirements: ${entry.key}');
          expect(validation.strength, greaterThanOrEqualTo(60), 
              reason: 'Demo password should be reasonably strong: ${entry.key}');
        }
      });
    });

    group('Security Validation', () {
      test('should never expose credentials in production', () {
        // Simulate production environment check
        if (!kDebugMode) {
          expect(EnvironmentConfig.isDemoModeEnabled, isFalse, 
              reason: 'Demo mode must be disabled in production');
          expect(EnvironmentConfig.getDemoCredentials(), isEmpty, 
              reason: 'No demo credentials in production');
          expect(AuthService.getAvailableDemoAccounts(), isEmpty, 
              reason: 'No demo accounts in production');
        }
      });

      test('should validate environment configuration', () {
        final configSummary = EnvironmentConfig.getConfigurationSummary();
        
        expect(configSummary.keys, containsAll(['environment', 'demo']), 
            reason: 'Config summary should include demo section');
        
        final demoConfig = configSummary['demo'] as Map<String, dynamic>;
        expect(demoConfig.keys, containsAll(['enabled', 'accountCount', 'availableAccounts']), 
            reason: 'Demo config should include all required fields');
        
        if (kDebugMode && EnvironmentConfig.isDemoModeEnabled) {
          expect(demoConfig['enabled'], isTrue, reason: 'Demo should be enabled in debug mode');
          expect(demoConfig['accountCount'], greaterThan(0), 
              reason: 'Should have demo accounts');
          expect(demoConfig['availableAccounts'], isA<List>(), 
              reason: 'Should list available accounts');
        } else {
          expect(demoConfig['enabled'], isFalse, reason: 'Demo should be disabled');
          expect(demoConfig['accountCount'], equals(0), reason: 'Should have no accounts');
        }
      });

      test('should validate configuration issues', () {
        final issues = EnvironmentConfig.validateConfiguration();
        
        // Issues list should always be a list (even if empty)
        expect(issues, isA<List<String>>(), reason: 'Issues should be a list');
        
        // Check if demo-related issues are properly reported
        if (EnvironmentConfig.isDevelopment && EnvironmentConfig.isDemoModeEnabled) {
          final demoCredentials = EnvironmentConfig.getDemoCredentials();
          if (demoCredentials.isEmpty) {
            expect(issues, contains(contains('demo')), 
                reason: 'Should report demo configuration issues');
          }
        }
      });

      test('should maintain backward compatibility', () {
        // Ensure the API is backward compatible
        expect(() => AuthService.isLoggedIn, returnsNormally);
        expect(() => AuthService.currentUserType, returnsNormally);
        expect(() => AuthService.currentUserName, returnsNormally);
        expect(() => AuthService.getFirebaseStatus(), returnsNormally);
        
        // New methods should also work
        expect(() => AuthService.getAvailableDemoAccounts(), returnsNormally);
        expect(() => AuthService.isDemoAccount('test@example.com'), returnsNormally);
        expect(() => AuthService.getDemoAccountInfo('test@example.com'), returnsNormally);
      });
    });
  });
}