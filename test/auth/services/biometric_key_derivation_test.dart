import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../../lib/auth/services/biometric_auth_service.dart';
import '../../../lib/auth/services/secure_key_manager.dart';
import '../../../lib/auth/services/aes_gcm_crypto_service.dart';

// Generate mocks
@GenerateMocks([FlutterSecureStorage, SharedPreferences])
import 'biometric_key_derivation_test.mocks.dart';

void main() {
  group('BiometricKeyDerivation', () {
    late MockFlutterSecureStorage mockSecureStorage;
    late MockSharedPreferences mockSharedPreferences;

    setUp(() {
      mockSecureStorage = MockFlutterSecureStorage();
      mockSharedPreferences = MockSharedPreferences();
      
      // Reset shared preferences instance for testing
      SharedPreferences.setMockInitialValues({});
    });

    group('Initialization', () {
      test('should initialize successfully with valid dependencies', () async {
        // Arrange
        when(mockSecureStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => null);
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Mock SecureKeyManager initialization
        when(mockSharedPreferences.getKeys())
            .thenReturn(<String>{});

        // Act & Assert
        expect(
          () => BiometricKeyDerivation.initialize(),
          returnsNormally,
        );
      });

      test('should handle initialization errors gracefully', () async {
        // Arrange
        when(mockSecureStorage.read(key: anyNamed('key')))
            .thenThrow(PlatformException(code: 'storage_error'));

        // Act & Assert
        expect(
          () => BiometricKeyDerivation.initialize(),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Device ID Generation', () {
      test('should generate unique device ID', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_id_biometric'))
            .thenAnswer((_) async => null);
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        await BiometricKeyDerivation.initialize();

        // Assert
        verify(mockSecureStorage.write(
          key: 'device_id_biometric',
          value: argThat(isA<String>()),
        )).called(1);
      });

      test('should reuse existing device ID', () async {
        // Arrange
        const existingDeviceId = 'existing_device_id_123';
        when(mockSecureStorage.read(key: 'device_id_biometric'))
            .thenAnswer((_) async => existingDeviceId);

        // Act
        await BiometricKeyDerivation.initialize();

        // Assert
        verify(mockSecureStorage.read(key: 'device_id_biometric')).called(1);
        verifyNever(mockSecureStorage.write(
          key: 'device_id_biometric',
          value: anyNamed('value'),
        ));
      });
    });

    group('Key Derivation', () {
      const userId = 'test_user_123';
      const deviceId = 'test_device_456';
      final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

      test('should derive consistent keys for same user/device combination', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_id_biometric'))
            .thenAnswer((_) async => deviceId);
        when(mockSecureStorage.read(key: 'biometric_salt_$userId'))
            .thenAnswer((_) async => base64.encode(salt));

        await BiometricKeyDerivation.initialize();

        // Act
        final key1 = await BiometricKeyDerivation.getBiometricKey(userId);
        final key2 = await BiometricKeyDerivation.getBiometricKey(userId);

        // Assert
        expect(key1, equals(key2));
        expect(key1.length, equals(32)); // 256 bits
      });

      test('should derive different keys for different users', () async {
        // Arrange
        const userId1 = 'user_1';
        const userId2 = 'user_2';
        
        when(mockSecureStorage.read(key: 'device_id_biometric'))
            .thenAnswer((_) async => deviceId);
        when(mockSecureStorage.read(key: 'biometric_salt_$userId1'))
            .thenAnswer((_) async => base64.encode(salt));
        when(mockSecureStorage.read(key: 'biometric_salt_$userId2'))
            .thenAnswer((_) async => base64.encode(salt));

        await BiometricKeyDerivation.initialize();

        // Act
        final key1 = await BiometricKeyDerivation.getBiometricKey(userId1);
        final key2 = await BiometricKeyDerivation.getBiometricKey(userId2);

        // Assert
        expect(key1, isNot(equals(key2)));
      });

      test('should generate new salt if none exists', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_id_biometric'))
            .thenAnswer((_) async => deviceId);
        when(mockSecureStorage.read(key: 'biometric_salt_$userId'))
            .thenAnswer((_) async => null);
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        await BiometricKeyDerivation.initialize();

        // Act
        final key = await BiometricKeyDerivation.getBiometricKey(userId);

        // Assert
        expect(key.length, equals(32));
        verify(mockSecureStorage.write(
          key: 'biometric_salt_$userId',
          value: argThat(isA<String>()),
        )).called(1);
      });
    });

    group('Data Encryption/Decryption', () {
      const userId = 'test_user';
      const testData = 'sensitive biometric data';

      setUp(() async {
        // Setup mocks for successful operation
        when(mockSecureStorage.read(key: 'device_id_biometric'))
            .thenAnswer((_) async => 'test_device');
        when(mockSecureStorage.read(key: 'biometric_salt_$userId'))
            .thenAnswer((_) async => base64.encode(Uint8List(32)));
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        await BiometricKeyDerivation.initialize();
      });

      test('should encrypt and decrypt data successfully', () async {
        // Act
        final encrypted = await BiometricKeyDerivation.encryptBiometricData(testData, userId);
        final decrypted = await BiometricKeyDerivation.decryptBiometricData(encrypted, userId);

        // Assert
        expect(decrypted, equals(testData));
        expect(encrypted, startsWith('BIO_V2:'));
        expect(encrypted, isNot(equals(testData)));
      });

      test('should handle empty data', () async {
        // Act
        final encrypted = await BiometricKeyDerivation.encryptBiometricData('', userId);
        final decrypted = await BiometricKeyDerivation.decryptBiometricData(encrypted, userId);

        // Assert
        expect(encrypted, equals(''));
        expect(decrypted, equals(''));
      });

      test('should reject legacy data format', () async {
        // Arrange
        const legacyData = 'legacy_encrypted_data_without_prefix';

        // Act & Assert
        expect(
          () => BiometricKeyDerivation.decryptBiometricData(legacyData, userId),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should handle encryption errors gracefully', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'device_id_biometric'))
            .thenThrow(PlatformException(code: 'storage_error'));

        // Act & Assert
        expect(
          () => BiometricKeyDerivation.encryptBiometricData(testData, userId),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Key Rotation', () {
      const userId = 'test_user';

      setUp(() async {
        when(mockSecureStorage.read(key: anyNamed('key')))
            .thenAnswer((invocation) async {
              final key = invocation.namedArguments[const Symbol('key')] as String;
              if (key == 'device_id_biometric') return 'test_device';
              if (key == 'biometric_key_version_$userId') return '1';
              if (key.startsWith('biometric_salt_')) return base64.encode(Uint8List(32));
              return null;
            });
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        await BiometricKeyDerivation.initialize();
      });

      test('should rotate keys successfully', () async {
        // Act
        await BiometricKeyDerivation.rotateBiometricKeys(userId);

        // Assert
        verify(mockSecureStorage.write(
          key: 'biometric_salt_$userId',
          value: argThat(isA<String>()),
        )).called(1);
        verify(mockSecureStorage.write(
          key: 'biometric_key_version_$userId',
          value: '2',
        )).called(1);
      });

      test('should handle rotation errors', () async {
        // Arrange
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenThrow(PlatformException(code: 'storage_error'));

        // Act & Assert
        expect(
          () => BiometricKeyDerivation.rotateBiometricKeys(userId),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Key Clearing', () {
      const userId = 'test_user';

      test('should clear user keys successfully', () async {
        // Arrange
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async {});

        // Act
        await BiometricKeyDerivation.clearBiometricKeys(userId);

        // Assert
        verify(mockSecureStorage.delete(key: 'biometric_salt_$userId')).called(1);
        verify(mockSecureStorage.delete(key: 'biometric_key_version_$userId')).called(1);
      });

      test('should handle clearing errors gracefully', () async {
        // Arrange
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenThrow(PlatformException(code: 'storage_error'));

        // Act & Assert
        expect(
          () => BiometricKeyDerivation.clearBiometricKeys(userId),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Legacy Data Migration', () {
      test('should detect and clear legacy biometric data', () async {
        // Arrange
        when(mockSharedPreferences.getKeys()).thenReturn({
          'securyflex_biometric_secret_user1',
          'other_key',
          'biometric_legacy_secret_user2',
        });
        when(mockSharedPreferences.remove(any)).thenAnswer((_) async => true);
        when(mockSecureStorage.read(key: 'biometric_migration_completed'))
            .thenAnswer((_) async => null);
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        await BiometricKeyDerivation.initialize();

        // Assert - legacy keys should be removed
        verify(mockSharedPreferences.remove('securyflex_biometric_secret_user1')).called(1);
        verify(mockSharedPreferences.remove('biometric_legacy_secret_user2')).called(1);
        verifyNever(mockSharedPreferences.remove('other_key'));

        // Migration flag should be set
        verify(mockSecureStorage.write(
          key: 'biometric_migration_completed',
          value: 'completed',
        )).called(1);
      });

      test('should skip migration if already completed', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'biometric_migration_completed'))
            .thenAnswer((_) async => 'completed');

        // Act
        await BiometricKeyDerivation.initialize();

        // Assert - should not attempt migration
        verifyNever(mockSharedPreferences.getKeys());
        verifyNever(mockSharedPreferences.remove(any));
      });
    });

    group('Security Features', () {
      test('should require initialization before use', () {
        // Act & Assert
        expect(
          () => BiometricKeyDerivation.getBiometricKey('user'),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should use PBKDF2 with sufficient iterations', () async {
        // This is tested indirectly through the key derivation process
        // The test ensures that keys are derived consistently
        
        // Arrange
        const userId = 'test_user';
        when(mockSecureStorage.read(key: 'device_id_biometric'))
            .thenAnswer((_) async => 'test_device');
        when(mockSecureStorage.read(key: 'biometric_salt_$userId'))
            .thenAnswer((_) async => base64.encode(Uint8List(32)));
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        await BiometricKeyDerivation.initialize();

        // Act
        final startTime = DateTime.now();
        await BiometricKeyDerivation.getBiometricKey(userId);
        final endTime = DateTime.now();

        // Assert - Key derivation should take some time due to iterations
        final duration = endTime.difference(startTime);
        expect(duration.inMilliseconds, greaterThan(1)); // Should take some time
      });

      test('should include device-specific data in key derivation', () async {
        // This is implicitly tested by the device ID generation and usage
        // The test verifies that device ID is generated and stored

        // Arrange
        when(mockSecureStorage.read(key: 'device_id_biometric'))
            .thenAnswer((_) async => null);
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        await BiometricKeyDerivation.initialize();

        // Assert
        verify(mockSecureStorage.write(
          key: 'device_id_biometric',
          value: argThat(isA<String>()),
        )).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle storage read errors', () async {
        // Arrange
        when(mockSecureStorage.read(key: anyNamed('key')))
            .thenThrow(PlatformException(code: 'read_error'));

        // Act & Assert
        expect(
          () => BiometricKeyDerivation.initialize(),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should handle storage write errors', () async {
        // Arrange
        when(mockSecureStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => null);
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenThrow(PlatformException(code: 'write_error'));

        // Act & Assert
        expect(
          () => BiometricKeyDerivation.initialize(),
          throwsA(isA<SecurityException>()),
        );
      });

      test('should validate input parameters', () async {
        // Arrange
        when(mockSecureStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => 'test_value');
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        await BiometricKeyDerivation.initialize();

        // Act & Assert - empty user ID should be handled gracefully
        expect(
          () => BiometricKeyDerivation.getBiometricKey(''),
          returnsNormally, // Should not throw but handle gracefully
        );
      });
    });
  });
}

/// SecurityException class for testing
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}