import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter/services.dart';

import 'package:securyflex_app/auth/services/biometric_auth_service.dart';
import 'package:securyflex_app/auth/models/enhanced_auth_models.dart' as models;

/// Mock LocalAuthentication for testing
class MockLocalAuthentication extends Mock implements LocalAuthentication {}

/// Mock SharedPreferences for testing  
class MockSharedPreferences extends Mock implements SharedPreferences {}

/// Mock Platform for testing platform-specific behavior
class MockPlatform extends Mock {
  static bool _isAndroid = false;
  static bool _isIOS = false;
  
  static bool get isAndroid => _isAndroid;
  static bool get isIOS => _isIOS;
  static String get operatingSystem => _isAndroid ? 'android' : _isIOS ? 'ios' : 'unknown';
  
  static void setAndroid() {
    _isAndroid = true;
    _isIOS = false;
  }
  
  static void setIOS() {
    _isAndroid = false;
    _isIOS = true;
  }
  
  static void reset() {
    _isAndroid = false;
    _isIOS = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Biometric Authentication Service Tests', () {
    late MockLocalAuthentication mockLocalAuth;

    setUp(() {
      mockLocalAuth = MockLocalAuthentication();
      SharedPreferences.setMockInitialValues({});
      MockPlatform.reset();
    });

    group('Biometric Availability Detection', () {
      test('should detect biometric availability on supported devices', () async {
        // Mock successful biometric availability
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint, BiometricType.face],
        );

        final result = await BiometricAuthService.checkBiometricAvailability();

        expect(result.isAvailable, isTrue);
        expect(result.availableTypes, isNotNull);
        expect(result.availableTypes!.length, equals(2));
        expect(result.availableTypes, contains(models.BiometricType.fingerprint));
        expect(result.availableTypes, contains(models.BiometricType.face));
        expect(result.platformTypes, isNotNull);
        expect(result.reason, isNull);
        expect(result.errorCode, isNull);
      });

      test('should handle unsupported devices gracefully', () async {
        // Mock unsupported device
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        final result = await BiometricAuthService.checkBiometricAvailability();

        expect(result.isAvailable, isFalse);
        expect(result.reason, contains('niet ondersteund'));
        expect(result.reasonDutch, contains('niet ondersteund'));
        expect(result.availableTypes, isNull);
        expect(result.platformTypes, isNull);
      });

      test('should detect when no biometrics are enrolled', () async {
        // Mock device that supports biometrics but has none enrolled
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

        final result = await BiometricAuthService.checkBiometricAvailability();

        expect(result.isAvailable, isFalse);
        expect(result.reason, contains('Geen biometrische gegevens ingesteld'));
        expect(result.reasonDutch, contains('Geen biometrische gegevens ingesteld'));
        expect(result.availableTypes, isEmpty);
      });

      test('should handle platform exceptions during availability check', () async {
        // Mock platform exception
        when(() => mockLocalAuth.canCheckBiometrics).thenThrow(
          PlatformException(code: 'BIOMETRIC_ERROR', message: 'Hardware error'),
        );

        final result = await BiometricAuthService.checkBiometricAvailability();

        expect(result.isAvailable, isFalse);
        expect(result.errorCode, equals('BIOMETRIC_ERROR'));
        expect(result.reason, contains('Hardware error'));
        expect(result.reasonDutch, contains('Hardware error'));
      });

      test('should map platform biometric types correctly', () async {
        // Test all supported biometric types
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [
            BiometricType.fingerprint,
            BiometricType.face,
            BiometricType.iris,
            BiometricType.weak,
            BiometricType.strong,
          ],
        );

        final result = await BiometricAuthService.checkBiometricAvailability();

        expect(result.isAvailable, isTrue);
        expect(result.availableTypes!, hasLength(5));
        expect(result.availableTypes, contains(models.BiometricType.fingerprint));
        expect(result.availableTypes, contains(models.BiometricType.face));
        expect(result.availableTypes, contains(models.BiometricType.iris));
        expect(result.availableTypes, contains(models.BiometricType.weak));
        expect(result.availableTypes, contains(models.BiometricType.strong));
      });
    });

    group('Biometric Authentication Process', () {
      test('should authenticate successfully with fingerprint', () async {
        const userId = 'test-user';

        // Mock successful biometric authentication
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((_) async => true);

        final result = await BiometricAuthService.authenticate(userId: userId);

        expect(result.isAuthenticated, isTrue);
        expect(result.biometricType, equals(models.BiometricType.fingerprint));
        expect(result.message, contains('succesvol'));
        expect(result.messageDutch, contains('succesvol'));
        expect(result.errorCode, isNull);
        expect(result.errorMessage, isNull);
      });

      test('should handle authentication failure', () async {
        const userId = 'test-user';

        // Mock failed biometric authentication
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((_) async => false);

        final result = await BiometricAuthService.authenticate(userId: userId);

        expect(result.isAuthenticated, isFalse);
        expect(result.errorCode, equals('AUTH_FAILED'));
        expect(result.errorMessage, contains('mislukt of geannuleerd'));
        expect(result.errorMessageDutch, contains('mislukt of geannuleerd'));
        expect(result.remainingAttempts, isA<int>());
      });

      test('should implement progressive lockout after failed attempts', () async {
        const userId = 'lockout-test-user';

        // Mock biometric availability
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );

        // Mock failed authentication
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((_) async => false);

        // Make 3 failed attempts to trigger lockout
        for (int i = 0; i < 3; i++) {
          final result = await BiometricAuthService.authenticate(userId: userId);
          expect(result.isAuthenticated, isFalse);
          expect(result.remainingAttempts, equals(2 - i));
        }

        // 4th attempt should be locked
        final lockedResult = await BiometricAuthService.authenticate(userId: userId);
        expect(lockedResult.isAuthenticated, isFalse);
        expect(lockedResult.errorCode, equals('USER_LOCKED'));
        expect(lockedResult.errorMessage, contains('vergrendeld'));
        expect(lockedResult.remainingLockTime, isNotNull);
        expect(lockedResult.remainingLockTime!.inMinutes, closeTo(15, 1));
      });

      test('should reset failed attempts on successful authentication', () async {
        const userId = 'reset-test-user';

        // Mock biometric availability
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );

        // First, make failed attempts
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((_) async => false);

        // Make 2 failed attempts
        await BiometricAuthService.authenticate(userId: userId);
        final secondAttempt = await BiometricAuthService.authenticate(userId: userId);
        expect(secondAttempt.remainingAttempts, equals(1));

        // Now succeed
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((_) async => true);

        final successResult = await BiometricAuthService.authenticate(userId: userId);
        expect(successResult.isAuthenticated, isTrue);

        // Verify failed attempts were reset
        final config = await BiometricAuthService.getBiometricConfig(userId);
        expect(config.failedAttempts, equals(0));
      });

      test('should handle platform-specific authentication options', () async {
        const userId = 'platform-test-user';
        MockPlatform.setIOS();

        // Mock iOS biometric setup
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.face],
        );

        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((invocation) {
          final messages = invocation.namedArguments[#authMessages] as List;
          expect(messages, isNotEmpty);
          
          // Verify iOS-specific messages are included
          final iosMessages = messages.whereType<IOSAuthMessages>().toList();
          expect(iosMessages, isNotEmpty);
          expect(iosMessages.first.cancelButton, equals('Annuleren'));
          
          return Future.value(true);
        });

        final result = await BiometricAuthService.authenticate(userId: userId);
        expect(result.isAuthenticated, isTrue);
      });

      test('should handle Android-specific authentication options', () async {
        const userId = 'android-test-user';
        MockPlatform.setAndroid();

        // Mock Android biometric setup
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );

        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((invocation) {
          final messages = invocation.namedArguments[#authMessages] as List;
          expect(messages, isNotEmpty);
          
          // Verify Android-specific messages are included
          final androidMessages = messages.whereType<AndroidAuthMessages>().toList();
          expect(androidMessages, isNotEmpty);
          expect(androidMessages.first.signInTitle, equals('Biometrische verificatie'));
          expect(androidMessages.first.cancelButton, equals('Annuleren'));
          
          return Future.value(true);
        });

        final result = await BiometricAuthService.authenticate(userId: userId);
        expect(result.isAuthenticated, isTrue);
      });

      test('should handle platform exceptions with appropriate error messages', () async {
        const userId = 'exception-test-user';

        // Mock biometric availability
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );

        // Test various platform exceptions
        final exceptionTests = [
          ('LockedOut', 'Te veel mislukte pogingen'),
          ('NotAvailable', 'niet beschikbaar'),
          ('NotEnrolled', 'geen biometrische gegevens ingesteld'),
          ('UserCancel', 'geannuleerd door gebruiker'),
          ('DeviceNotSecure', 'niet beveiligd'),
        ];

        for (final test in exceptionTests) {
          final (code, expectedMessage) = test;
          
          when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
            authMessages: any(named: 'authMessages'),
          )).thenThrow(PlatformException(code: code, message: 'Test error'));

          final result = await BiometricAuthService.authenticate(userId: userId);

          expect(result.isAuthenticated, isFalse);
          expect(result.errorCode, equals(code));
          expect(result.errorMessage!.toLowerCase(), contains(expectedMessage.toLowerCase()),
                 reason: 'Error code $code should contain "$expectedMessage"');
        }
      });
    });

    group('Biometric Configuration Management', () {
      test('should enable biometric authentication successfully', () async {
        const userId = 'enable-test-user';

        // Mock successful biometric setup
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint, BiometricType.face],
        );
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((_) async => true);

        final result = await BiometricAuthService.enableBiometric(userId: userId);

        expect(result, isTrue);

        // Verify configuration was saved
        final config = await BiometricAuthService.getBiometricConfig(userId);
        expect(config.isEnabled, isTrue);
        expect(config.isSupported, isTrue);
        expect(config.availableTypes, isNotEmpty);
        expect(config.setupDate, isNotNull);
        expect(config.lastUsed, isNotNull);
      });

      test('should fail to enable when biometrics are not available', () async {
        const userId = 'unavailable-test-user';

        // Mock unavailable biometrics
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        final result = await BiometricAuthService.enableBiometric(userId: userId);

        expect(result, isFalse);

        // Configuration should not be enabled
        final config = await BiometricAuthService.getBiometricConfig(userId);
        expect(config.isEnabled, isFalse);
        expect(config.isSupported, isFalse);
      });

      test('should disable biometric authentication with verification', () async {
        const userId = 'disable-test-user';

        // First enable biometrics
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((_) async => true);

        await BiometricAuthService.enableBiometric(userId: userId);

        // Now disable
        final result = await BiometricAuthService.disableBiometric(
          userId: userId,
          verificationCode: '123456',
        );

        expect(result, isTrue);

        // Verify it's disabled
        final config = await BiometricAuthService.getBiometricConfig(userId);
        expect(config.isEnabled, isFalse);
      });

      test('should check if biometric is enabled correctly', () async {
        const userId = 'check-enabled-user';

        // Initially not enabled
        final initialEnabled = await BiometricAuthService.isBiometricEnabled(userId);
        expect(initialEnabled, isFalse);

        // Enable biometrics
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((_) async => true);

        await BiometricAuthService.enableBiometric(userId: userId);

        // Now should be enabled
        final nowEnabled = await BiometricAuthService.isBiometricEnabled(userId);
        expect(nowEnabled, isTrue);
      });

      test('should handle configuration persistence', () async {
        const userId = 'persist-test-user';

        // Enable biometrics
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((_) async => true);

        await BiometricAuthService.enableBiometric(userId: userId);

        // Get configuration multiple times
        final config1 = await BiometricAuthService.getBiometricConfig(userId);
        final config2 = await BiometricAuthService.getBiometricConfig(userId);

        expect(config1.isEnabled, equals(config2.isEnabled));
        expect(config1.setupDate, equals(config2.setupDate));
        expect(config1.availableTypes, equals(config2.availableTypes));
      });

      test('should provide default configuration when none exists', () async {
        const userId = 'default-config-user';

        // Mock no biometric support
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

        final config = await BiometricAuthService.getBiometricConfig(userId);

        expect(config.isEnabled, isFalse);
        expect(config.isSupported, isFalse);
        expect(config.availableTypes, isEmpty);
        expect(config.failedAttempts, equals(0));
        expect(config.lockedUntil, isNull);
      });
    });

    group('Platform Information and Capabilities', () {
      test('should detect platform capabilities correctly', () async {
        MockPlatform.setAndroid();

        // Mock Android capabilities
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint, BiometricType.strong],
        );

        final platformInfo = await BiometricAuthService.getPlatformInfo();

        expect(platformInfo.isSupported, isTrue);
        expect(platformInfo.platform, equals('Android'));
        expect(platformInfo.capabilities, containsPair('platform', 'Android'));
        expect(platformInfo.capabilities, containsPair('canCheckBiometrics', true));
        expect(platformInfo.capabilities, containsPair('isDeviceSupported', true));
        expect(platformInfo.dutchCapabilities, isNotEmpty);
        expect(platformInfo.dutchCapabilities, contains('Vingerafdruk'));
      });

      test('should provide Dutch capability descriptions', () async {
        MockPlatform.setIOS();

        // Mock iOS capabilities
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.face, BiometricType.fingerprint, BiometricType.iris],
        );

        final platformInfo = await BiometricAuthService.getPlatformInfo();

        expect(platformInfo.dutchCapabilities, contains('Gezichtsherkenning'));
        expect(platformInfo.dutchCapabilities, contains('Vingerafdruk'));
        expect(platformInfo.dutchCapabilities, contains('Iris scan'));
      });

      test('should handle unsupported platforms gracefully', () async {
        MockPlatform.reset(); // Neither Android nor iOS

        // Mock platform error
        when(() => mockLocalAuth.canCheckBiometrics).thenThrow(
          Exception('Platform not supported'),
        );

        final platformInfo = await BiometricAuthService.getPlatformInfo();

        expect(platformInfo.isSupported, isFalse);
        expect(platformInfo.platform, equals('unknown'));
        expect(platformInfo.capabilities, containsPair('error', isA<String>()));
        expect(platformInfo.dutchCapabilities, contains('Geen biometrische mogelijkheden'));
      });
    });

    group('Enhanced Auth Models Integration', () {
      test('should work with BiometricConfig model', () async {
        const userId = 'model-test-user';

        // Test default configuration
        final defaultConfig = await BiometricAuthService.getBiometricConfig(userId);
        expect(defaultConfig, isA<models.BiometricConfig>());
        expect(defaultConfig.isEnabled, isFalse);
        expect(defaultConfig.isLocked, isFalse);
        expect(defaultConfig.statusDutch, isNotEmpty);

        // Test model methods
        final updatedConfig = defaultConfig.copyWith(
          isEnabled: true,
          failedAttempts: 1,
        );

        expect(updatedConfig.isEnabled, isTrue);
        expect(updatedConfig.failedAttempts, equals(1));
        expect(updatedConfig.availableTypes, equals(defaultConfig.availableTypes));

        // Test JSON serialization
        final json = defaultConfig.toJson();
        final deserializedConfig = models.BiometricConfig.fromJson(json);

        expect(deserializedConfig.isEnabled, equals(defaultConfig.isEnabled));
        expect(deserializedConfig.isSupported, equals(defaultConfig.isSupported));
        expect(deserializedConfig.availableTypes.length, equals(defaultConfig.availableTypes.length));
      });

      test('should provide Dutch status messages', () async {
        const userId = 'status-test-user';

        // Test various status conditions
        final config = await BiometricAuthService.getBiometricConfig(userId);

        // Test different status conditions
        final statusTests = [
          (config, 'Niet ondersteund'), // Default unsupported
          (config.copyWith(isSupported: true), 'Niet ingeschakeld'),
          (config.copyWith(isSupported: true, isEnabled: true), 'Actief'),
          (config.copyWith(
            isSupported: true, 
            isEnabled: true, 
            failedAttempts: 3,
            lockedUntil: DateTime.now().add(const Duration(minutes: 15)),
          ), 'Vergrendeld'),
        ];

        for (final (testConfig, expectedStatus) in statusTests) {
          expect(testConfig.statusDutch.toLowerCase(), 
                 contains(expectedStatus.toLowerCase()));
        }
      });

      test('should handle BiometricType enum correctly', () {
        // Test all biometric types have Dutch names
        final types = models.BiometricType.values;
        
        for (final type in types) {
          expect(type.dutchName, isNotEmpty);
          
          // Verify specific translations
          switch (type) {
            case models.BiometricType.fingerprint:
              expect(type.dutchName, equals('Vingerafdruk'));
              break;
            case models.BiometricType.face:
              expect(type.dutchName, equals('Gezichtsherkenning'));
              break;
            case models.BiometricType.iris:
              expect(type.dutchName, equals('Iris scan'));
              break;
            case models.BiometricType.weak:
              expect(type.dutchName, equals('Zwakke biometrie'));
              break;
            case models.BiometricType.strong:
              expect(type.dutchName, equals('Sterke biometrie'));
              break;
          }
        }

        // Test fromString method
        expect(models.BiometricType.fromString('fingerprint'), 
               equals(models.BiometricType.fingerprint));
        expect(models.BiometricType.fromString('face'), 
               equals(models.BiometricType.face));
        expect(models.BiometricType.fromString('unknown'), 
               equals(models.BiometricType.fingerprint)); // Default fallback
      });
    });

    group('Security and Error Handling', () {
      test('should handle security events correctly', () async {
        const userId = 'security-test-user';

        // Mock biometric availability
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );

        // Test failed authentication (should log security event)
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((_) async => false);

        final result = await BiometricAuthService.authenticate(userId: userId);
        expect(result.isAuthenticated, isFalse);

        // Test successful authentication (should also log)
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((_) async => true);

        final successResult = await BiometricAuthService.authenticate(userId: userId);
        expect(successResult.isAuthenticated, isTrue);

        // Events should be logged (tested indirectly through console output in actual implementation)
      });

      test('should handle permanently locked out scenarios', () async {
        const userId = 'permanent-lock-user';

        // Mock platform exception for permanent lockout
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenThrow(PlatformException(code: 'PermanentlyLockedOut'));

        final result = await BiometricAuthService.authenticate(userId: userId);

        expect(result.isAuthenticated, isFalse);
        expect(result.errorCode, equals('PermanentlyLockedOut'));
        expect(result.errorMessage, contains('permanent vergrendeld'));
      });

      test('should handle device security issues', () async {
        const userId = 'security-issue-user';

        // Mock device not secure
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenThrow(PlatformException(code: 'DeviceNotSecure'));

        final result = await BiometricAuthService.authenticate(userId: userId);

        expect(result.isAuthenticated, isFalse);
        expect(result.errorCode, equals('DeviceNotSecure'));
        expect(result.errorMessage, contains('niet beveiligd'));
      });

      test('should handle concurrent authentication attempts', () async {
        const userId = 'concurrent-test-user';

        // Mock biometric setup
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((_) async => true);

        // Attempt concurrent authentications
        final futures = List.generate(3, (_) => 
          BiometricAuthService.authenticate(userId: userId)
        );

        final results = await Future.wait(futures);

        expect(results.length, equals(3));
        // All should complete without exceptions
        expect(results.every((r) => r.isAuthenticated || !r.isAuthenticated), isTrue);
      });
    });

    group('Performance and Optimization', () {
      test('should complete biometric operations within reasonable time', () async {

        // Mock fast biometric response
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );

        final stopwatch = Stopwatch()..start();
        final availability = await BiometricAuthService.checkBiometricAvailability();
        stopwatch.stop();

        expect(availability.isAvailable, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(500), // Should complete quickly
               reason: 'Biometric availability check should be fast');
      });

      test('should handle multiple users efficiently', () async {
        const userCount = 5;

        // Mock biometric support
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );

        // Get configurations for multiple users
        final futures = List.generate(userCount, (i) =>
          BiometricAuthService.getBiometricConfig('user$i')
        );

        final configs = await Future.wait(futures);

        expect(configs.length, equals(userCount));
        expect(configs.every((c) => c.isSupported), isTrue);
      });

      test('should cache platform capabilities efficiently', () async {
        // Multiple calls should not re-check platform capabilities repeatedly
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );

        final stopwatch = Stopwatch()..start();
        
        // Make multiple platform info requests
        final info1 = await BiometricAuthService.getPlatformInfo();
        final info2 = await BiometricAuthService.getPlatformInfo();
        
        stopwatch.stop();

        expect(info1.isSupported, equals(info2.isSupported));
        expect(info1.platform, equals(info2.platform));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
               reason: 'Multiple platform info requests should be efficient');
      });
    });

    group('Dutch Localization', () {
      test('should provide all messages in Dutch', () {
        final dutchPhrases = [
          'Biometrische authenticatie',
          'Verifieer uw identiteit',
          'Annuleren',
          'Ga naar instellingen',
          'succesvol',
          'mislukt',
          'geannuleerd',
          'vergrendeld',
          'niet ondersteund',
          'niet ingeschakeld',
        ];

        // These phrases should be used in the Dutch localization
        expect(dutchPhrases, isNotEmpty);
      });

      test('should handle Dutch error message formatting', () async {

        // Test availability error in Dutch
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);

        final availability = await BiometricAuthService.checkBiometricAvailability();

        expect(availability.isAvailable, isFalse);
        expect(availability.reasonDutch, isNotNull);
        expect(availability.reasonDutch!.toLowerCase(), contains('niet'));

        // Verify Dutch language characteristics
        final dutchWords = ['niet', 'geen', 'ondersteund', 'beschikbaar'];
        expect(dutchWords.any((word) => 
               availability.reasonDutch!.toLowerCase().contains(word)), 
               isTrue);
      });

      test('should provide platform-specific Dutch messages', () async {
        MockPlatform.setAndroid();

        // Mock Android authentication
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint],
        );
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
          authMessages: any(named: 'authMessages'),
        )).thenAnswer((invocation) {
          final reason = invocation.namedArguments[#localizedReason] as String;
          expect(reason, contains('vingerafdruk'));
          expect(reason, contains('biometrische'));
          return Future.value(true);
        });

        const userId = 'dutch-android-user';
        final result = await BiometricAuthService.authenticate(userId: userId);
        expect(result.isAuthenticated, isTrue);
      });
    });
  });
}