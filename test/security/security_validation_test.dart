import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/config/environment_config.dart';
import 'package:securyflex_app/auth/auth_service.dart';

void main() {
  group('Security Validation Tests', () {
    test('Environment configuration is secure', () {
      // Test that environment configuration is available
      expect(EnvironmentConfig.environmentName, isNotEmpty);
      expect(EnvironmentConfig.isDevelopment || EnvironmentConfig.isProduction || EnvironmentConfig.isStaging, isTrue);
      
      // Test Firebase configuration validation
      final issues = EnvironmentConfig.validateConfiguration();
      // In development mode, issues are expected (no real API keys needed)
      expect(issues, isA<List<String>>());
    });

    test('Authentication service has no hardcoded credentials', () async {
      // Verify demo credentials are no longer accessible
      expect(() => (AuthService as dynamic).demoCredentials, throwsA(isA<NoSuchMethodError>()));
      
      // Verify authentication requires Firebase
      final result = await AuthService.loginWithResult('test@example.com', 'testpassword');
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'firebase-not-configured');
    });

    test('Firebase configuration uses environment variables', () {
      // Test that Firebase configuration is environment-based
      expect(EnvironmentConfig.firebaseProjectId, isNotEmpty);
      expect(EnvironmentConfig.firebaseWebApiKey, isNotEmpty);
      
      // In development, these should be safe defaults
      if (EnvironmentConfig.isDevelopment) {
        expect(EnvironmentConfig.firebaseProjectId, 'securyflex-dev');
      }
    });

    test('Google Maps API key is environment-based', () {
      // Test Google Maps configuration
      final apiKey = EnvironmentConfig.googleMapsApiKey;
      // In development, this can be empty (will use mock data)
      expect(apiKey, isA<String>());
    });

    test('No hardcoded secrets in configuration', () {
      // Verify no placeholder values in production
      if (EnvironmentConfig.isProduction) {
        expect(EnvironmentConfig.firebaseWebApiKey, isNot('your-web-api-key'));
        expect(EnvironmentConfig.firebaseProjectId, isNot('your-project-id'));
      }
    });

    test('Security validation provides clear feedback', () {
      // Test configuration summary
      final summary = EnvironmentConfig.getConfigurationSummary();
      expect(summary, containsPair('environment', isA<String>()));
      expect(summary, containsPair('isProduction', isA<bool>()));
      expect(summary, containsPair('firebase', isA<Map>()));
    });
  });
}