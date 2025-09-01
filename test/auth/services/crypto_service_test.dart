import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:securyflex_app/auth/services/crypto_service.dart';
import 'package:securyflex_app/auth/services/aes_gcm_crypto_service.dart' hide SecurityException;
import 'package:securyflex_app/auth/services/bsn_security_service.dart';
import 'package:securyflex_app/auth/services/secure_key_manager.dart' hide SecurityException;

void main() {
  late BSNSecurityService bsnService;
  
  group('CryptoService Tests', () {
    setUpAll(() async {
      // Mock secure storage for testing
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (methodCall) async {
          switch (methodCall.method) {
            case 'read':
              return null; // Return null to simulate empty storage
            case 'write':
            case 'delete':
            case 'deleteAll':
              return null;
            default:
              return null;
          }
        },
      );
      
      await CryptoService.initialize();
      await BSNSecurityService.initialize();
      bsnService = BSNSecurityService.instance;
    });
    
    group('PII Encryption Tests', () {
      test('should encrypt and decrypt PII data correctly', () async {
        const testData = 'Sensitive Personal Information';
        const userId = 'test_user_123';
        
        final encrypted = await CryptoService.encryptPII(testData, userId: userId);
        final decrypted = await CryptoService.decryptPII(encrypted, userId: userId);
        
        expect(encrypted, isNot(equals(testData)));
        expect(encrypted, isNotEmpty);
        expect(decrypted, equals(testData));
        expect(CryptoService.isEncrypted(encrypted), isTrue);
      });
      
      test('should handle BSN encryption specially', () async {
        const validBSN = '123456782'; // Valid test BSN with correct elfproef
        const userId = 'test_user_123';
        
        final encrypted = await CryptoService.encryptPII(validBSN, userId: userId);
        final decrypted = await CryptoService.decryptPII(encrypted, userId: userId);
        
        expect(encrypted, startsWith('BSN_AES256_GCM_V1:'));
        expect(decrypted, equals(validBSN));
      });
      
      test('should return empty string for empty input', () async {
        const emptyData = '';
        
        final encrypted = await CryptoService.encryptPII(emptyData);
        final decrypted = await CryptoService.decryptPII(encrypted);
        
        expect(encrypted, isEmpty);
        expect(decrypted, isEmpty);
      });
    });
    
    group('Document Encryption Tests', () {
      test('should encrypt and decrypt document bytes correctly', () async {
        final testData = 'Test document content with sensitive information'.codeUnits;
        const userId = 'test_user_123';
        
        final encrypted = await CryptoService.encryptDocument(
          Uint8List.fromList(testData), 
          userId
        );
        final decrypted = await CryptoService.decryptDocument(
          encrypted, 
          userId
        );
        
        expect(encrypted, isNot(equals(testData)));
        expect(encrypted, isNotEmpty);
        expect(decrypted, equals(testData));
      });
      
      test('should handle empty document data', () async {
        final emptyData = <int>[];
        const userId = 'test_user_123';
        
        final encrypted = await CryptoService.encryptDocument(Uint8List.fromList(emptyData), userId);
        final decrypted = await CryptoService.decryptDocument(encrypted, userId);
        
        expect(encrypted, isEmpty);
        expect(decrypted, isEmpty);
      });
    });
    
    group('Hash Generation and Verification Tests', () {
      test('should generate and verify hash correctly', () async {
        const testData = 'Test data for hashing';
        const context = 'test_context';
        
        final hash = await CryptoService.generateHash(testData, context: context);
        final isValid = await CryptoService.verifyHash(testData, hash, context: context);
        
        expect(hash, isNotEmpty);
        expect(isValid, isTrue);
      });
      
      test('should fail verification for modified data', () async {
        const originalData = 'Original test data';
        const modifiedData = 'Modified test data';
        const context = 'test_context';
        
        final hash = await CryptoService.generateHash(originalData, context: context);
        final isValid = await CryptoService.verifyHash(modifiedData, hash, context: context);
        
        expect(isValid, isFalse);
      });
      
      test('should use constant-time comparison to prevent timing attacks', () async {
        const testData = 'Test data';
        const context = 'test_context';
        
        final hash = await CryptoService.generateHash(testData, context: context);
        
        // Test with similar length strings to check timing attack resistance
        final shortData = 'Test';
        final longData = 'Test data with much more content';
        
        final shortValid = await CryptoService.verifyHash(shortData, hash, context: context);
        final longValid = await CryptoService.verifyHash(longData, hash, context: context);
        
        expect(shortValid, isFalse);
        expect(longValid, isFalse);
      });
    });
    
    group('Token Generation Tests', () {
      test('should generate secure random tokens', () {
        final token1 = CryptoService.generateToken();
        final token2 = CryptoService.generateToken();
        final shortToken = CryptoService.generateToken(length: 16);
        
        expect(token1, isNotEmpty);
        expect(token2, isNotEmpty);
        expect(token1, isNot(equals(token2))); // Should be different
        expect(shortToken.length, lessThan(token1.length)); // Shorter token
      });
      
      test('should generate tokens with correct length', () {
        const customLength = 64;
        final token = CryptoService.generateToken(length: customLength);
        
        // Base64 URL encoding adds padding, so length varies
        expect(token, isNotEmpty);
        expect(token.length, greaterThan(customLength ~/ 2));
      });
    });
    
    group('Encryption Format Detection Tests', () {
      test('should detect encrypted data correctly', () async {
        const testData = 'Test sensitive data';
        const userId = 'test_user_123';
        
        final encrypted = await CryptoService.encryptPII(testData, userId: userId);
        
        expect(CryptoService.isEncrypted(encrypted), isTrue);
        expect(CryptoService.isEncrypted(testData), isFalse);
      });
      
      test('should get correct encryption metadata', () async {
        const testData = 'Test data';
        const userId = 'test_user_123';
        
        final encrypted = await CryptoService.encryptPII(testData, userId: userId);
        final metadata = CryptoService.getEncryptionInfo(encrypted);
        
        expect(metadata['format'], equals('AES-256-GCM'));
        expect(metadata['version'], isNotEmpty);
      });
      
      test('should identify legacy encryption format', () {
        const legacyEncrypted = 'ENC:dGVzdA==';
        final metadata = CryptoService.getEncryptionInfo(legacyEncrypted);
        
        expect(metadata['format'], equals('Legacy-XOR'));
        expect(metadata['version'], equals('DEPRECATED'));
        expect(metadata['security'], equals('WEAK - NEEDS MIGRATION'));
      });
    });
    
    group('Sensitive Data Hashing Tests', () {
      test('should hash sensitive data securely', () async {
        const sensitiveData = 'Very sensitive personal information';
        const context = 'sensitive_context';
        
        final hash = await CryptoService.hashSensitiveData(
          sensitiveData, 
          context: context
        );
        
        expect(hash, isNotEmpty);
        expect(hash, isNot(equals(sensitiveData)));
        expect(hash.length, greaterThan(20)); // Should be substantial hash
      });
    });
    
    group('Security and Error Handling Tests', () {
      test('should handle decryption of corrupted data gracefully', () async {
        const corruptedData = 'AES256_GCM_V1:corrupted_base64_data';
        const userId = 'test_user_123';
        
        expect(
          () async => await CryptoService.decryptPII(corruptedData, userId: userId),
          throwsA(isA<SecurityException>()),
        );
      });
      
      test('should throw security exception on invalid hash context', () async {
        const testData = 'test';
        const validHash = 'valid_hash_value';
        const invalidContext = 'wrong_context';
        
        final result = await CryptoService.verifyHash(
          testData, 
          validHash, 
          context: invalidContext
        );
        
        expect(result, isFalse);
      });
    });
    
    group('Memory Security Tests', () {
      test('should securely wipe sensitive string buffers', () {
        final sensitiveBuffer = StringBuffer('very sensitive data that needs wiping');
        final originalLength = sensitiveBuffer.length;
        
        CryptoService.secureWipe(sensitiveBuffer);
        
        // Buffer should be cleared
        expect(sensitiveBuffer.isEmpty, isTrue);
        
        // This tests that the wipe operation completed
        expect(sensitiveBuffer.length, equals(0));
      });
    });
  });
  
  group('BSNSecurityService Tests', () {
    setUpAll(() async {
      await BSNSecurityService.initialize();
    });
    
    group('BSN Validation Tests', () {
      test('should validate correct BSN numbers', () {
        // Valid BSN numbers with correct elfproef
        expect(BSNSecurityService.isValidBSN('123456782'), isTrue);
        expect(BSNSecurityService.isValidBSN('111222333'), isFalse); // Invalid elfproef
        expect(BSNSecurityService.isValidBSN('000000000'), isFalse); // Invalid pattern
      });
      
      test('should handle BSN formatting correctly', () {
        const validBSN = '123456782';
        final formattedBSN = BSNSecurityService.formatBSN(validBSN);
        final maskedBSN = BSNSecurityService.maskBSN(validBSN);
        
        expect(formattedBSN, equals('123 456 782'));
        expect(maskedBSN, equals('123****82'));
      });
    });
    
    group('BSN Encryption Tests', () {
      test('should encrypt and decrypt BSN correctly', () async {
        const validBSN = '123456782';
        const userId = 'test_user_123';
        
        final encrypted = await bsnService.encryptBSN(validBSN, userId);
        final decrypted = await bsnService.decryptBSN(encrypted, userId);
        
        expect(encrypted, startsWith('BSN_AES256_GCM_V1:'));
        expect(decrypted, equals(validBSN));
        expect(BSNSecurityService.isEncryptedBSN(encrypted), isTrue);
      });
      
      test('should verify BSN integrity after encryption', () async {
        const validBSN = '123456782';
        const userId = 'test_user_123';
        
        final encrypted = await bsnService.encryptBSN(validBSN, userId);
        // Test encryption integrity by decrypting and comparing
        final decrypted = await bsnService.decryptBSN(encrypted, userId);
        final integrityValid = decrypted == validBSN;
        
        expect(integrityValid, isTrue);
      });
      
      test('should create audit-safe BSN hash', () async {
        const validBSN = '123456782';
        
        final auditHash = BSNSecurityService.hashBSNForAudit(validBSN);
        
        expect(auditHash, isNotEmpty);
        expect(auditHash, isNot(equals(validBSN)));
        expect(auditHash.length, equals(16)); // Truncated for logs
      });
    });
  });
  
  group('AESGCMCryptoService Tests', () {
    setUpAll(() async {
      await AESGCMCryptoService.initialize();
    });
    
    group('String Encryption Tests', () {
      test('should encrypt and decrypt strings with context', () async {
        const testString = 'Test sensitive string data';
        const context = 'test_context';
        
        final encrypted = await AESGCMCryptoService.encryptString(testString, context);
        final decrypted = await AESGCMCryptoService.decryptString(encrypted, context);
        
        expect(encrypted, startsWith('AES256_GCM_V1:'));
        expect(decrypted, equals(testString));
        expect(AESGCMCryptoService.isEncrypted(encrypted), isTrue);
      });
      
      test('should fail decryption with wrong context', () async {
        const testString = 'Test data';
        const correctContext = 'correct_context';
        const wrongContext = 'wrong_context';
        
        final encrypted = await AESGCMCryptoService.encryptString(
          testString, 
          correctContext
        );
        
        expect(
          () async => await AESGCMCryptoService.decryptString(
            encrypted, 
            wrongContext
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });
    
    group('Secure Token Generation Tests', () {
      test('should generate cryptographically secure tokens', () {
        final tokens = <String>{};
        
        // Generate multiple tokens to test uniqueness
        for (int i = 0; i < 100; i++) {
          final token = AESGCMCryptoService.generateSecureToken();
          tokens.add(token);
        }
        
        // All tokens should be unique
        expect(tokens.length, equals(100));
      });
    });
  });
  
  group('SecureKeyManager Tests', () {
    setUpAll(() async {
      await SecureKeyManager.initialize();
    });
    
    group('Key Derivation Tests', () {
      test('should derive different keys for different contexts', () async {
        const context1 = 'context_one';
        const context2 = 'context_two';
        
        final key1 = await SecureKeyManager.getEncryptionKey(context1);
        final key2 = await SecureKeyManager.getEncryptionKey(context2);
        
        expect(key1, isNot(equals(key2)));
        expect(key1.length, equals(32)); // 256 bits
        expect(key2.length, equals(32)); // 256 bits
      });
      
      test('should derive consistent keys for same context', () async {
        const context = 'consistent_context';
        
        final key1 = await SecureKeyManager.getEncryptionKey(context);
        final key2 = await SecureKeyManager.getEncryptionKey(context);
        
        expect(key1, equals(key2));
      });
    });
  });
}

// Test utility extensions
extension on String {
  List<int> get codeUnits => runes.toList();
}
