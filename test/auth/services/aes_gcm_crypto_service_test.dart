import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/auth/services/aes_gcm_crypto_service.dart';
import 'package:securyflex_app/auth/services/secure_key_manager.dart' hide SecurityException;

void main() {
  group('AESGCMCryptoService', () {
    setUpAll(() async {
      // Initialize services for testing
      await SecureKeyManager.initialize();
      await AESGCMCryptoService.initialize();
    });
    
    group('String Encryption/Decryption', () {
      test('should encrypt and decrypt strings correctly', () async {
        const testData = 'Test sensitive data for encryption';
        const context = 'test_context';
        
        final encrypted = await AESGCMCryptoService.encryptString(testData, context);
        final decrypted = await AESGCMCryptoService.decryptString(encrypted, context);
        
        expect(decrypted, equals(testData));
        expect(encrypted, isNot(equals(testData)));
        expect(AESGCMCryptoService.isEncrypted(encrypted), isTrue);
      });
      
      test('should handle empty strings', () async {
        const context = 'test_context';
        
        final encrypted = await AESGCMCryptoService.encryptString('', context);
        final decrypted = await AESGCMCryptoService.decryptString(encrypted, context);
        
        expect(encrypted, equals(''));
        expect(decrypted, equals(''));
      });
      
      test('should use different ciphertext for same plaintext', () async {
        const testData = 'Same plaintext';
        const context = 'test_context';
        
        final encrypted1 = await AESGCMCryptoService.encryptString(testData, context);
        final encrypted2 = await AESGCMCryptoService.encryptString(testData, context);
        
        // Different nonces should produce different ciphertext
        expect(encrypted1, isNot(equals(encrypted2)));
        
        // But both should decrypt to the same plaintext
        final decrypted1 = await AESGCMCryptoService.decryptString(encrypted1, context);
        final decrypted2 = await AESGCMCryptoService.decryptString(encrypted2, context);
        
        expect(decrypted1, equals(testData));
        expect(decrypted2, equals(testData));
      });
      
      test('should fail with wrong context', () async {
        const testData = 'Context test data';
        const context1 = 'context_1';
        const context2 = 'context_2';
        
        final encrypted = await AESGCMCryptoService.encryptString(testData, context1);
        
        // Should throw when trying to decrypt with wrong context
        expect(
          () async => await AESGCMCryptoService.decryptString(encrypted, context2),
          throwsA(isA<SecurityException>()),
        );
      });
    });
    
    group('Byte Encryption/Decryption', () {
      test('should encrypt and decrypt bytes correctly', () async {
        final testData = Uint8List.fromList([1, 2, 3, 4, 5, 255, 128, 64]);
        const context = 'byte_test_context';
        
        final encrypted = await AESGCMCryptoService.encryptBytes(testData, context);
        final decrypted = await AESGCMCryptoService.decryptBytes(encrypted, context);
        
        expect(decrypted, equals(testData));
        expect(encrypted, isNot(equals(testData)));
      });
      
      test('should handle empty byte arrays', () async {
        final testData = Uint8List(0);
        const context = 'empty_byte_context';
        
        final encrypted = await AESGCMCryptoService.encryptBytes(testData, context);
        final decrypted = await AESGCMCryptoService.decryptBytes(encrypted, context);
        
        expect(encrypted.length, equals(0));
        expect(decrypted.length, equals(0));
      });
      
      test('should detect tampering (authentication)', () async {
        final testData = Uint8List.fromList([10, 20, 30, 40, 50]);
        const context = 'tamper_test_context';
        
        final encrypted = await AESGCMCryptoService.encryptBytes(testData, context);
        
        // Tamper with the encrypted data
        final tamperedEncrypted = Uint8List.fromList(encrypted);
        tamperedEncrypted[tamperedEncrypted.length - 1] ^= 1; // Flip a bit
        
        // Should throw when trying to decrypt tampered data
        expect(
          () async => await AESGCMCryptoService.decryptBytes(tamperedEncrypted, context),
          throwsA(isA<SecurityException>()),
        );
      });
    });
    
    group('Hash Generation and Verification', () {
      test('should generate and verify secure hashes', () async {
        const testData = 'Data to hash';
        const context = 'hash_test_context';
        
        final hash = await AESGCMCryptoService.generateSecureHash(testData, context);
        final isValid = await AESGCMCryptoService.verifySecureHash(testData, hash, context);
        
        expect(hash, isNotEmpty);
        expect(isValid, isTrue);
      });
      
      test('should fail verification with wrong data', () async {
        const testData1 = 'Original data';
        const testData2 = 'Modified data';
        const context = 'hash_verify_context';
        
        final hash = await AESGCMCryptoService.generateSecureHash(testData1, context);
        final isValid = await AESGCMCryptoService.verifySecureHash(testData2, hash, context);
        
        expect(isValid, isFalse);
      });
      
      test('should fail verification with wrong context', () async {
        const testData = 'Context sensitive data';
        const context1 = 'context_1';
        const context2 = 'context_2';
        
        final hash = await AESGCMCryptoService.generateSecureHash(testData, context1);
        final isValid = await AESGCMCryptoService.verifySecureHash(testData, hash, context2);
        
        expect(isValid, isFalse);
      });
    });
    
    group('Token Generation', () {
      test('should generate secure tokens of correct length', () {
        final token1 = AESGCMCryptoService.generateSecureToken(length: 16);
        final token2 = AESGCMCryptoService.generateSecureToken(length: 32);
        final token3 = AESGCMCryptoService.generateSecureToken(length: 64);
        
        expect(token1.length, greaterThanOrEqualTo(16));
        expect(token2.length, greaterThanOrEqualTo(32));
        expect(token3.length, greaterThanOrEqualTo(64));
        
        // Should generate different tokens
        expect(token1, isNot(equals(token2)));
        expect(token2, isNot(equals(token3)));
      });
      
      test('should generate different tokens each time', () {
        final tokens = <String>{};
        
        for (int i = 0; i < 100; i++) {
          final token = AESGCMCryptoService.generateSecureToken(length: 32);
          tokens.add(token);
        }
        
        // All tokens should be unique
        expect(tokens.length, equals(100));
      });
    });
    
    group('Encryption Format Detection', () {
      test('should correctly identify encrypted data', () async {
        const testData = 'Format test data';
        const context = 'format_test_context';
        
        final encrypted = await AESGCMCryptoService.encryptString(testData, context);
        
        expect(AESGCMCryptoService.isEncrypted(encrypted), isTrue);
        expect(AESGCMCryptoService.isEncrypted(testData), isFalse);
        expect(AESGCMCryptoService.isEncrypted(''), isFalse);
      });
      
      test('should provide correct encryption metadata', () async {
        const testData = 'Metadata test';
        const context = 'metadata_context';
        
        final encrypted = await AESGCMCryptoService.encryptString(testData, context);
        final metadata = AESGCMCryptoService.getEncryptionMetadata(encrypted);
        
        expect(metadata['format'], equals('AES-256-GCM'));
        expect(metadata['version'], equals('AES256_GCM_V1'));
        expect(metadata['prefix'], equals('AES256_GCM_V1'));
      });
    });
    
    group('Memory Security', () {
      test('should securely wipe memory buffers', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        final originalData = Uint8List.fromList(buffer);
        
        AESGCMCryptoService.secureWipe(buffer);
        
        // Buffer should be overwritten
        expect(buffer, isNot(equals(originalData)));
        
        // Should be all zeros after wiping
        expect(buffer.every((byte) => byte == 0), isTrue);
      });
      
      test('should handle empty buffers gracefully', () {
        final emptyBuffer = Uint8List(0);
        
        // Should not throw
        expect(() => AESGCMCryptoService.secureWipe(emptyBuffer), returnsNormally);
      });
    });
    
    group('Error Handling', () {
      test('should throw on corrupted encrypted data', () async {
        const context = 'error_test_context';
        const corruptedData = 'AES256_GCM_V1:invalid_base64_data!!!';
        
        expect(
          () async => await AESGCMCryptoService.decryptString(corruptedData, context),
          throwsA(isA<SecurityException>()),
        );
      });
      
      test('should throw on unsupported encryption version', () async {
        const context = 'version_test_context';
        const unsupportedVersion = 'AES256_GCM_V999:dGVzdA==';
        
        expect(
          () async => await AESGCMCryptoService.decryptString(unsupportedVersion, context),
          throwsA(isA<SecurityException>()),
        );
      });
      
      test('should throw on too short encrypted data', () async {
        const context = 'short_data_context';
        final tooShortData = Uint8List(5); // Less than nonce + tag size
        
        expect(
          () async => await AESGCMCryptoService.decryptBytes(tooShortData, context),
          throwsA(isA<SecurityException>()),
        );
      });
    });
    
    group('Performance Tests', () {
      test('should handle large data efficiently', () async {
        // Test with 1MB of data
        final largeData = Uint8List(1024 * 1024);
        for (int i = 0; i < largeData.length; i++) {
          largeData[i] = i % 256;
        }
        
        const context = 'performance_test';
        final stopwatch = Stopwatch()..start();
        
        final encrypted = await AESGCMCryptoService.encryptBytes(largeData, context);
        final decrypted = await AESGCMCryptoService.decryptBytes(encrypted, context);
        
        stopwatch.stop();
        
        expect(decrypted, equals(largeData));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete in < 5 seconds
      });
      
      test('should handle multiple concurrent operations', () async {
        const context = 'concurrent_test';
        final futures = <Future<String>>[];
        
        // Start 10 concurrent encrypt/decrypt operations
        for (int i = 0; i < 10; i++) {
          final testData = 'Concurrent test data $i';
          final future = AESGCMCryptoService.encryptString(testData, context)
              .then((encrypted) => AESGCMCryptoService.decryptString(encrypted, context));
          futures.add(future);
        }
        
        final results = await Future.wait(futures);
        
        // All operations should succeed
        for (int i = 0; i < results.length; i++) {
          expect(results[i], equals('Concurrent test data $i'));
        }
      });
    });
    
    tearDownAll(() async {
      // Clean up after tests
      await SecureKeyManager.clearAllKeys();
    });
  });
}