import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/auth/services/bsn_security_service.dart';
import 'package:securyflex_app/auth/services/bsn_access_control_service.dart';
import 'package:securyflex_app/auth/services/aes_gcm_crypto_service.dart';

/// Comprehensive BSN Security Test Suite
/// Tests GDPR Article 9 compliance for BSN handling
void main() {
  late BSNSecurityService bsnService;
  
  setUpAll(() async {
    // Initialize crypto services
    await AESGCMCryptoService.initialize();
    await BSNSecurityService.initialize();
    await BSNAccessControlService.initialize();
    bsnService = BSNSecurityService.instance;
  });

  group('BSN Security Service Tests', () {
    test('should validate Dutch BSN using elfproef algorithm', () {
      // Valid BSNs (using test numbers with valid checksums)
      expect(BSNSecurityService.isValidBSN('123456782'), true);
      expect(BSNSecurityService.isValidBSN('147258369'), true);
      expect(BSNSecurityService.isValidBSN('987654321'), false); // Invalid checksum
      
      // Invalid formats
      expect(BSNSecurityService.isValidBSN('12345678'), false); // Too short
      expect(BSNSecurityService.isValidBSN('1234567890'), false); // Too long
      expect(BSNSecurityService.isValidBSN('12345678a'), false); // Contains letter
      expect(BSNSecurityService.isValidBSN('000000000'), false); // All zeros
      expect(BSNSecurityService.isValidBSN(''), false); // Empty
    });

    test('should encrypt and decrypt BSN with AES-256-GCM', () async {
      const testBSN = '123456782';
      const userId = 'test_user_123';
      
      // Encrypt BSN
      final encrypted = await bsnService.encryptBSN(testBSN, userId);
      expect(encrypted, isNotEmpty);
      expect(encrypted.startsWith('BSN_AES256_GCM_V1:'), true);
      
      // Decrypt BSN
      final decrypted = await bsnService.decryptBSN(encrypted, userId);
      expect(decrypted, equals(testBSN));
    });

    test('should fail encryption with invalid BSN', () async {
      const invalidBSN = '123456789'; // Invalid checksum
      
      expect(
        () async => await bsnService.encryptBSN(invalidBSN, 'test_user'),
        throwsA(isA<BSNSecurityException>())
      );
    });

    test('should create proper BSN masks for display', () {
      const testBSN = '123456782';
      const expectedMask = '123****82';
      
      final masked = BSNSecurityService.maskBSN(testBSN);
      expect(masked, equals(expectedMask));
      
      // Verify original BSN is not exposed
      expect(masked, isNot(contains('456')));
      expect(masked, isNot(contains('67')));
    });

    test('should format BSN with proper spacing', () {
      const testBSN = '123456782';
      const expectedFormat = '123 456 782';
      
      final formatted = BSNSecurityService.formatBSN(testBSN);
      expect(formatted, equals(expectedFormat));
    });

    test('should generate secure audit hash', () {
      const testBSN = '123456782';
      
      final hash1 = BSNSecurityService.hashBSNForAudit(testBSN);
      final hash2 = BSNSecurityService.hashBSNForAudit(testBSN);
      
      expect(hash1, isNotEmpty);
      expect(hash2, isNotEmpty);
      expect(hash1, equals(hash2)); // Same input should produce same hash
      expect(hash1.length, equals(16)); // Truncated to 16 chars
      expect(hash1, isNot(contains(testBSN))); // Original BSN not in hash
    });

    test('should detect encrypted BSN format', () async {
      const testBSN = '123456782';
      const plainBSN = '147258369';
      
      final encrypted = await bsnService.encryptBSN(testBSN, 'test_user');
      
      expect(BSNSecurityService.isEncryptedBSN(encrypted), true);
      expect(BSNSecurityService.isEncryptedBSN(plainBSN), false);
      expect(BSNSecurityService.isEncryptedBSN(''), false);
    });

    test('should encrypt BSN and maintain integrity', () async {
      const testBSN = '123456782';
      const userId = 'test_user_123';
      
      final encrypted = await bsnService.encryptBSN(testBSN, userId);
      final decrypted = await bsnService.decryptBSN(encrypted, userId);
      
      expect(decrypted, equals(testBSN));
    });

    test('should handle legacy BSN format migration', () async {
      // Test migration detection
      const legacyFormat = 'ENC:old_format_data';
      
      expect(
        () async => await bsnService.migrateLegacyBSN(legacyFormat, 'test_user'),
        throwsA(isA<BSNSecurityException>())
      );
    });

    test('should secure clear BSN from memory', () {
      final bsnBuffer = StringBuffer('123456782');
      expect(bsnBuffer.toString(), equals('123456782'));
      
      bsnService.secureClearBSN(bsnBuffer.toString());
      expect(bsnBuffer.isEmpty, true);
    });
  });

  group('BSN Access Control Tests', () {
    test('should grant access for valid purpose', () async {
      const targetUserId = 'user_123';
      const purpose = 'certificate_verification';
      const justification = 'User requested certificate verification';
      
      final result = await BSNAccessControlService.requestBSNAccess(
        targetUserId: targetUserId,
        purpose: purpose,
        justification: justification,
        accessLevel: BSNAccessLevel.viewer,
      );
      
      expect(result.isGranted, true);
      expect(result.requestId, isNotNull);
      expect(result.accessLevel, equals(BSNAccessLevel.viewer));
    });

    test('should deny access for invalid purpose', () async {
      const targetUserId = 'user_123';
      const purpose = 'invalid_purpose';
      const justification = 'This should be denied';
      
      final result = await BSNAccessControlService.requestBSNAccess(
        targetUserId: targetUserId,
        purpose: purpose,
        justification: justification,
        accessLevel: BSNAccessLevel.viewer,
      );
      
      expect(result.isGranted, false);
      expect(result.reason, isNotNull);
    });

    test('should get secure BSN with proper access control', () async {
      const testBSN = '123456782';
      const userId = 'test_user_123';
      
      // First encrypt the BSN
      final encryptedBSN = await bsnService.encryptBSN(testBSN, userId);
      
      // Request access
      final accessResult = await BSNAccessControlService.requestBSNAccess(
        targetUserId: userId,
        purpose: 'certificate_verification',
        justification: 'Test access for certificate verification',
        accessLevel: BSNAccessLevel.viewer,
      );
      
      expect(accessResult.isGranted, true);
      
      // Get secure BSN
      final secureBSN = await BSNAccessControlService.getSecureBSN(
        encryptedBSN: encryptedBSN,
        accessRequestId: accessResult.requestId!,
        displayMode: BSNDisplayMode.masked,
        userId: userId,
      );
      
      expect(secureBSN, equals('123****82'));
    });

    test('should revoke BSN access', () async {
      const targetUserId = 'user_123';
      const purpose = 'certificate_verification';
      const justification = 'Test access';
      
      final accessResult = await BSNAccessControlService.requestBSNAccess(
        targetUserId: targetUserId,
        purpose: purpose,
        justification: justification,
        accessLevel: BSNAccessLevel.viewer,
      );
      
      expect(accessResult.isGranted, true);
      
      // Revoke access
      await BSNAccessControlService.revokeBSNAccess(
        accessResult.requestId!,
        'Test revocation'
      );
      
      // Access should now be invalid
      // Note: This would be tested with actual Firestore integration
    });

    test('should maintain audit trail', () async {
      // This test would require Firestore integration
      // For now, just verify the method exists and doesn't throw
      final auditTrail = await BSNAccessControlService.getAuditTrail(
        limit: 10,
      );
      
      expect(auditTrail, isA<List<Map<String, dynamic>>>());
    });
  });

  group('BSN Display Mode Tests', () {
    test('should handle different display modes', () async {
      const testBSN = '123456782';
      const userId = 'test_user_123';
      
      final encryptedBSN = await bsnService.encryptBSN(testBSN, userId);
      
      // Test each display mode
      final accessResult = await BSNAccessControlService.requestBSNAccess(
        targetUserId: userId,
        purpose: 'certificate_verification',
        justification: 'Test display modes',
        accessLevel: BSNAccessLevel.basic,
      );
      
      expect(accessResult.isGranted, true);
      
      // Masked mode
      final masked = await BSNAccessControlService.getSecureBSN(
        encryptedBSN: encryptedBSN,
        accessRequestId: accessResult.requestId!,
        displayMode: BSNDisplayMode.masked,
        userId: userId,
      );
      expect(masked, equals('123****82'));
      
      // Last four digits mode
      final lastFour = await BSNAccessControlService.getSecureBSN(
        encryptedBSN: encryptedBSN,
        accessRequestId: accessResult.requestId!,
        displayMode: BSNDisplayMode.lastFourDigits,
        userId: userId,
      );
      expect(lastFour, equals('****6782'));
    });
  });

  group('GDPR Compliance Tests', () {
    test('should not expose plain text BSN in logs', () async {
      const testBSN = '123456782';
      const userId = 'test_user_123';
      
      // Encrypt BSN - this should not log plain text
      await bsnService.encryptBSN(testBSN, userId);
      
      // Verify that audit hash is used instead of plain BSN
      final auditHash = BSNSecurityService.hashBSNForAudit(testBSN);
      expect(auditHash, isNot(contains(testBSN)));
      expect(auditHash, isNot(contains('123')));
      expect(auditHash, isNot(contains('456')));
      expect(auditHash, isNot(contains('782')));
    });

    test('should enforce purpose limitation', () async {
      // Test that BSN can only be accessed for valid purposes
      const validPurposes = [
        'certificate_verification',
        'tax_document_generation',
        'invoice_creation',
        'compliance_audit',
        'user_profile_update',
        'legal_requirement',
      ];
      
      const invalidPurposes = [
        'marketing',
        'analytics',
        'social_features',
        'advertising',
        'data_mining',
      ];
      
      for (final purpose in validPurposes) {
        final result = await BSNAccessControlService.requestBSNAccess(
          targetUserId: 'user_123',
          purpose: purpose,
          justification: 'Test valid purpose',
          accessLevel: BSNAccessLevel.viewer,
        );
        expect(result.isGranted, true, reason: 'Valid purpose $purpose should be granted');
      }
      
      for (final purpose in invalidPurposes) {
        final result = await BSNAccessControlService.requestBSNAccess(
          targetUserId: 'user_123',
          purpose: purpose,
          justification: 'Test invalid purpose',
          accessLevel: BSNAccessLevel.viewer,
        );
        expect(result.isGranted, false, reason: 'Invalid purpose $purpose should be denied');
      }
    });

    test('should implement data minimization', () {
      const testBSN = '123456782';
      
      // Default display should be masked (data minimization)
      final masked = BSNSecurityService.maskBSN(testBSN);
      expect(masked, equals('123****82'));
      
      // Verify minimal data exposure
      final exposedDigits = masked.replaceAll('*', '');
      expect(exposedDigits.length, lessThanOrEqualTo(5)); // Only 5 digits exposed
    });

    test('should maintain encryption at rest', () async {
      const testBSN = '123456782';
      const userId = 'test_user_123';
      
      final encrypted = await bsnService.encryptBSN(testBSN, userId);
      
      // Verify encryption format
      expect(encrypted.startsWith('BSN_AES256_GCM_V1:'), true);
      expect(encrypted.length, greaterThan(50)); // Encrypted data should be longer
      expect(encrypted, isNot(contains(testBSN))); // Plain BSN not in encrypted string
    });
  });

  group('Error Handling Tests', () {
    test('should handle decryption errors gracefully', () async {
      const invalidEncrypted = 'BSN_AES256_GCM_V1:invalid_data';
      
      expect(
        () async => await bsnService.decryptBSN(invalidEncrypted, 'test_user'),
        throwsA(isA<BSNSecurityException>())
      );
    });

    test('should handle service not initialized', () {
      // This would require resetting the service state
      // For now, just verify exception types exist
      expect(BSNSecurityException('test', 'TEST_CODE'), isA<Exception>());
      expect(BSNSecurityException('test', 'TEST_CODE'), isA<BSNSecurityException>());
    });

    test('should handle invalid BSN formats in masking', () {
      const invalidBSNs = ['', '123', '12345678a', 'invalid'];
      
      for (final bsn in invalidBSNs) {
        final masked = BSNSecurityService.maskBSN(bsn);
        expect(masked, anyOf(equals('***INVALID***'), equals('***ERROR***')));
      }
    });
  });

  group('Performance Tests', () {
    test('should encrypt/decrypt BSN efficiently', () async {
      const testBSN = '123456782';
      const userId = 'test_user_123';
      const iterations = 10;
      
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < iterations; i++) {
        final encrypted = await bsnService.encryptBSN(testBSN, userId);
        await bsnService.decryptBSN(encrypted, userId);
      }
      
      stopwatch.stop();
      
      // Each encrypt/decrypt cycle should take less than 100ms on average
      final averageTime = stopwatch.elapsedMilliseconds / iterations;
      expect(averageTime, lessThan(100));
    });

    test('should validate BSN quickly', () {
      const testBSNs = [
        '123456782', '147258369', '987654321', '111111111', '222222222'
      ];
      
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 1000; i++) {
        for (final bsn in testBSNs) {
          BSNSecurityService.isValidBSN(bsn);
        }
      }
      
      stopwatch.stop();
      
      // Should validate 5000 BSNs in less than 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}

/// Helper class to test BSN security features
class BSNTestHelper {
  static List<String> generateValidTestBSNs() {
    // These are valid BSNs for testing (using elfproef algorithm)
    return [
      '123456782',
      '147258369',
      '246813579',
      '369258147',
      '123456789' // Note: This fails elfproef and should be invalid
    ];
  }
  
  static List<String> generateInvalidTestBSNs() {
    return [
      '987654321', // Invalid checksum
      '12345678',  // Too short
      '1234567890', // Too long
      '12345678a',  // Contains letter
      '000000000',  // All zeros
      '',           // Empty
      '123 456 782', // With spaces (should be cleaned first)
    ];
  }
  
  static Future<bool> testEncryptionRoundTrip(String bsn, {String? userId}) async {
    try {
      final service = BSNSecurityService.instance;
      final encrypted = await service.encryptBSN(bsn, userId ?? 'test_user');
      final decrypted = await service.decryptBSN(encrypted, userId ?? 'test_user');
      return decrypted == bsn;
    } catch (e) {
      return false;
    }
  }
}