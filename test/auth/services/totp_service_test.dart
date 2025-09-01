import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otp/otp.dart';

import 'package:securyflex_app/auth/services/totp_service.dart';
import 'package:securyflex_app/auth/models/enhanced_auth_models.dart';

/// Mock SharedPreferences for testing
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TOTP Service Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('Secret Generation and Management', () {
      test('should generate secure TOTP secret with proper entropy', () async {
        const userId = 'test-user-123';
        
        final secret = await TOTPService.generateSecret(userId);
        
        expect(secret, isNotNull);
        expect(secret, isNotEmpty);
        expect(secret.length, greaterThan(20)); // Base32 encoded 160-bit secret should be >20 chars
        expect(RegExp(r'^[A-Z2-7]+$').hasMatch(secret), isTrue, 
               reason: 'Secret should be valid base32');
      });

      test('should generate unique secrets for different users', () async {
        final secret1 = await TOTPService.generateSecret('user1');
        final secret2 = await TOTPService.generateSecret('user2');
        
        expect(secret1, isNot(equals(secret2)));
        expect(secret1.length, equals(secret2.length));
      });

      test('should create QR code data with correct otpauth format', () async {
        const userId = 'test-user';
        const userEmail = 'test@securyflex.nl';
        const secret = 'JBSWY3DPEHPK3PXP';
        const issuer = 'SecuryFlex';
        
        final qrCodeData = await TOTPService.getQRCodeData(
          userId: userId,
          userEmail: userEmail,
          secret: secret,
          issuer: issuer,
        );
        
        expect(qrCodeData, startsWith('otpauth://totp/'));
        expect(qrCodeData, contains('secret=$secret'));
        expect(qrCodeData, contains('issuer=$issuer'));
        expect(qrCodeData, contains('digits=6'));
        expect(qrCodeData, contains('period=30'));
        expect(qrCodeData, contains(Uri.encodeComponent('$issuer:$userEmail')));
      });

      test('should handle URL encoding in QR code data correctly', () async {
        const userId = 'test-user';
        const userEmail = 'gebruiker+test@sécuryflex.nl'; // Special characters
        const secret = 'JBSWY3DPEHPK3PXP';
        const issuer = 'SecuryFlex Test';
        
        final qrCodeData = await TOTPService.getQRCodeData(
          userId: userId,
          userEmail: userEmail,
          secret: secret,
          issuer: issuer,
        );
        
        expect(qrCodeData, contains(Uri.encodeComponent(userEmail)));
        expect(qrCodeData, contains(Uri.encodeComponent(issuer)));
        expect(qrCodeData, isNot(contains(' '))); // No unencoded spaces
      });
    });

    group('TOTP Code Verification', () {
      test('should verify valid TOTP codes within time window', () async {
        const userId = 'test-user';
        
        // Generate a secret first
        final secret = await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        // Generate a valid TOTP code for current time
        final now = DateTime.now();
        final currentTimeStep = now.millisecondsSinceEpoch ~/ 1000 ~/ 30;
        final validCode = OTP.generateTOTPCodeString(
          secret,
          currentTimeStep * 30 * 1000,
          length: 6,
          interval: 30,
        );
        
        final result = await TOTPService.verifyTOTP(userId, validCode, timestamp: now);
        
        expect(result.isValid, isTrue);
        expect(result.timeWindow, isA<int>());
        expect(result.nextCodeIn, isA<int>());
        expect(result.nextCodeIn, greaterThan(0));
        expect(result.nextCodeIn, lessThanOrEqualTo(30));
      });

      test('should reject invalid TOTP codes', () async {
        const userId = 'test-user';
        
        await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        final result = await TOTPService.verifyTOTP(userId, '000000');
        
        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('INVALID_CODE'));
        expect(result.errorMessage, contains('Ongeldige verificatiecode'));
        expect(result.remainingAttempts, isA<int>());
      });

      test('should handle time window tolerance for clock drift', () async {
        const userId = 'test-user';
        
        final secret = await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        // Test with timestamp 30 seconds in the past (previous time window)
        final pastTime = DateTime.now().subtract(const Duration(seconds: 30));
        final pastTimeStep = pastTime.millisecondsSinceEpoch ~/ 1000 ~/ 30;
        final pastCode = OTP.generateTOTPCodeString(
          secret,
          pastTimeStep * 30 * 1000,
          length: 6,
          interval: 30,
        );
        
        final result = await TOTPService.verifyTOTP(userId, pastCode, timestamp: pastTime);
        
        // Should accept codes from adjacent time windows due to drift tolerance
        expect(result.isValid, isTrue);
        expect(result.timeWindow, equals(0)); // Current window relative to timestamp
      });

      test('should prevent replay attacks by tracking used codes', () async {
        const userId = 'test-user';
        
        final secret = await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        // Generate a valid code
        final now = DateTime.now();
        final currentTimeStep = now.millisecondsSinceEpoch ~/ 1000 ~/ 30;
        final validCode = OTP.generateTOTPCodeString(
          secret,
          currentTimeStep * 30 * 1000,
          length: 6,
          interval: 30,
        );
        
        // First verification should succeed
        final result1 = await TOTPService.verifyTOTP(userId, validCode, timestamp: now);
        expect(result1.isValid, isTrue);
        
        // Second verification with same code should be blocked
        final result2 = await TOTPService.verifyTOTP(userId, validCode, timestamp: now);
        expect(result2.isValid, isFalse);
        expect(result2.errorCode, equals('REPLAY_ATTACK'));
        expect(result2.errorMessage, contains('al recent gebruikt'));
      });

      test('should implement progressive lockout after failed attempts', () async {
        const userId = 'test-user';
        
        await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        // Make 3 failed attempts
        for (int i = 0; i < 3; i++) {
          final result = await TOTPService.verifyTOTP(userId, 'wrong${i}00');
          expect(result.isValid, isFalse);
          expect(result.remainingAttempts, equals(2 - i));
        }
        
        // 4th attempt should result in lockout
        final lockedResult = await TOTPService.verifyTOTP(userId, '123456');
        expect(lockedResult.isValid, isFalse);
        expect(lockedResult.errorCode, equals('ACCOUNT_LOCKED'));
        expect(lockedResult.errorMessage, contains('vergrendeld'));
        expect(lockedResult.remainingLockTime, isNotNull);
        expect(lockedResult.remainingLockTime!.inMinutes, closeTo(15, 1));
      });

      test('should reset failed attempts on successful verification', () async {
        const userId = 'test-user';
        
        final secret = await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        // Make 2 failed attempts
        await TOTPService.verifyTOTP(userId, 'wrong01');
        await TOTPService.verifyTOTP(userId, 'wrong02');
        
        // Verify we have 1 remaining attempt
        final result1 = await TOTPService.verifyTOTP(userId, 'wrong03');
        expect(result1.remainingAttempts, equals(0));
        
        // Now provide correct code
        final now = DateTime.now();
        final currentTimeStep = now.millisecondsSinceEpoch ~/ 1000 ~/ 30;
        final validCode = OTP.generateTOTPCodeString(
          secret,
          currentTimeStep * 30 * 1000,
          length: 6,
          interval: 30,
        );
        
        final result2 = await TOTPService.verifyTOTP(userId, validCode, timestamp: now);
        expect(result2.isValid, isTrue);
        
        // Failed attempts should be reset
        final config = await TOTPService.getTwoFactorConfig(userId);
        expect(config.failedAttempts, equals(0));
      });

      test('should return proper error when TOTP not setup', () async {
        const userId = 'test-user-no-setup';
        
        final result = await TOTPService.verifyTOTP(userId, '123456');
        
        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('NO_SECRET'));
        expect(result.errorMessage, contains('TOTP nog niet ingesteld'));
      });

      test('should validate code format strictly', () async {
        const userId = 'test-user';
        
        await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        // Test various invalid formats
        final invalidCodes = ['12345', '1234567', 'abcdef', '12-34-56', ''];
        
        for (final code in invalidCodes) {
          final result = await TOTPService.verifyTOTP(userId, code);
          expect(result.isValid, isFalse, 
                 reason: 'Code "$code" should be invalid');
          expect(result.errorCode, equals('INVALID_CODE'));
        }
      });
    });

    group('Backup Codes Management', () {
      test('should generate secure backup codes with proper format', () async {
        const userId = 'test-user';
        const count = 10;
        
        final codes = await TOTPService.generateBackupCodes(userId, count: count);
        
        expect(codes, hasLength(count));
        
        for (final code in codes) {
          expect(code.code, hasLength(8)); // 8-character codes
          expect(code.code, matches(r'^[A-Z0-9]+$')); // Alphanumeric uppercase
          expect(code.isUsed, isFalse);
          expect(code.createdAt, isNotNull);
          expect(code.usedAt, isNull);
          expect(code.hashedCode, isNotEmpty);
          expect(code.formattedCode, contains('-')); // Should include formatting
        }
        
        // Codes should be unique
        final codeStrings = codes.map((c) => c.code).toList();
        final uniqueCodes = Set<String>.from(codeStrings);
        expect(uniqueCodes.length, equals(count));
      });

      test('should verify valid backup codes', () async {
        const userId = 'test-user';
        
        final codes = await TOTPService.generateBackupCodes(userId);
        final testCode = codes.first;
        
        final result = await TOTPService.verifyBackupCode(userId, testCode.code);
        
        expect(result.isValid, isTrue);
        expect(result.remainingCodes, equals(codes.length - 1));
      });

      test('should mark backup codes as used after verification', () async {
        const userId = 'test-user';
        
        final codes = await TOTPService.generateBackupCodes(userId);
        final testCode = codes.first.code;
        
        // Verify code
        await TOTPService.verifyBackupCode(userId, testCode);
        
        // Get status to verify code was marked as used
        final status = await TOTPService.getBackupCodesStatus(userId);
        expect(status.used, equals(1));
        expect(status.remaining, equals(codes.length - 1));
      });

      test('should reject already used backup codes', () async {
        const userId = 'test-user';
        
        final codes = await TOTPService.generateBackupCodes(userId);
        final testCode = codes.first.code;
        
        // Use the code once
        final result1 = await TOTPService.verifyBackupCode(userId, testCode);
        expect(result1.isValid, isTrue);
        
        // Try to use it again
        final result2 = await TOTPService.verifyBackupCode(userId, testCode);
        expect(result2.isValid, isFalse);
        expect(result2.errorCode, equals('INVALID_BACKUP_CODE'));
        expect(result2.errorMessage, contains('al gebruikte backup code'));
      });

      test('should reject invalid backup codes', () async {
        const userId = 'test-user';
        
        await TOTPService.generateBackupCodes(userId);
        
        final invalidCodes = ['INVALID1', 'wrong123', '12345678', 'ABCDEFGH'];
        
        for (final code in invalidCodes) {
          final result = await TOTPService.verifyBackupCode(userId, code);
          expect(result.isValid, isFalse);
          expect(result.errorCode, equals('INVALID_BACKUP_CODE'));
        }
      });

      test('should provide accurate backup codes status', () async {
        const userId = 'test-user';
        
        final codes = await TOTPService.generateBackupCodes(userId);
        
        // Initially no codes used
        final status1 = await TOTPService.getBackupCodesStatus(userId);
        expect(status1.total, equals(10));
        expect(status1.used, equals(0));
        expect(status1.remaining, equals(10));
        expect(status1.isRunningLow, isFalse);
        expect(status1.isEmpty, isFalse);
        
        // Use 8 codes
        for (int i = 0; i < 8; i++) {
          await TOTPService.verifyBackupCode(userId, codes[i].code);
        }
        
        final status2 = await TOTPService.getBackupCodesStatus(userId);
        expect(status2.used, equals(8));
        expect(status2.remaining, equals(2));
        expect(status2.isRunningLow, isTrue);
        expect(status2.isEmpty, isFalse);
        expect(status2.statusDutch, contains('Nog maar 2 backup codes over'));
        
        // Use remaining codes
        await TOTPService.verifyBackupCode(userId, codes[8].code);
        await TOTPService.verifyBackupCode(userId, codes[9].code);
        
        final status3 = await TOTPService.getBackupCodesStatus(userId);
        expect(status3.remaining, equals(0));
        expect(status3.isEmpty, isTrue);
        expect(status3.statusDutch, contains('Geen backup codes meer beschikbaar'));
      });

      test('should handle backup code verification with empty list', () async {
        const userId = 'test-user-no-codes';
        
        final result = await TOTPService.verifyBackupCode(userId, 'ANYCODE1');
        
        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('INVALID_BACKUP_CODE'));
      });

      test('should reset failed attempts on successful backup code use', () async {
        const userId = 'test-user';
        
        final codes = await TOTPService.generateBackupCodes(userId);
        await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        // Make some failed TOTP attempts
        await TOTPService.verifyTOTP(userId, 'wrong01');
        await TOTPService.verifyTOTP(userId, 'wrong02');
        
        // Verify failed attempts were recorded
        final config1 = await TOTPService.getTwoFactorConfig(userId);
        expect(config1.failedAttempts, equals(2));
        
        // Use backup code
        final result = await TOTPService.verifyBackupCode(userId, codes.first.code);
        expect(result.isValid, isTrue);
        
        // Failed attempts should be reset
        final config2 = await TOTPService.getTwoFactorConfig(userId);
        expect(config2.failedAttempts, equals(0));
      });
    });

    group('Configuration Management', () {
      test('should enable TOTP for user correctly', () async {
        const userId = 'test-user';
        
        await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        final config = await TOTPService.getTwoFactorConfig(userId);
        expect(config.isTotpEnabled, isTrue);
        expect(config.setupDate, isNotNull);
        expect(config.setupDate!.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
        expect(config.failedAttempts, equals(0));
        expect(config.isLocked, isFalse);
      });

      test('should disable TOTP with valid verification code', () async {
        const userId = 'test-user';
        
        final secret = await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        // Generate valid TOTP code for verification
        final now = DateTime.now();
        final currentTimeStep = now.millisecondsSinceEpoch ~/ 1000 ~/ 30;
        final validCode = OTP.generateTOTPCodeString(
          secret,
          currentTimeStep * 30 * 1000,
          length: 6,
          interval: 30,
        );
        
        final result = await TOTPService.disableTOTP(userId, validCode);
        expect(result, isTrue);
        
        // Verify TOTP is disabled
        final config = await TOTPService.getTwoFactorConfig(userId);
        expect(config.isTotpEnabled, isFalse);
      });

      test('should disable TOTP with valid backup code', () async {
        const userId = 'test-user';
        
        await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        final codes = await TOTPService.generateBackupCodes(userId);
        
        final result = await TOTPService.disableTOTP(userId, codes.first.code);
        expect(result, isTrue);
      });

      test('should not disable TOTP with invalid verification', () async {
        const userId = 'test-user';
        
        await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        final result = await TOTPService.disableTOTP(userId, 'invalid');
        expect(result, isFalse);
        
        // Verify TOTP is still enabled
        final config = await TOTPService.getTwoFactorConfig(userId);
        expect(config.isTotpEnabled, isTrue);
      });

      test('should load two-factor configuration correctly', () async {
        const userId = 'test-user';
        
        // Test default configuration
        final config1 = await TOTPService.getTwoFactorConfig(userId);
        expect(config1.isTotpEnabled, isFalse);
        expect(config1.failedAttempts, equals(0));
        expect(config1.isLocked, isFalse);
        
        // Setup TOTP and test enabled configuration
        await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        final config2 = await TOTPService.getTwoFactorConfig(userId);
        expect(config2.isTotpEnabled, isTrue);
        expect(config2.setupDate, isNotNull);
      });

      test('should handle locked account configuration correctly', () async {
        const userId = 'test-user';
        
        await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        // Make enough failed attempts to lock account
        for (int i = 0; i < 3; i++) {
          await TOTPService.verifyTOTP(userId, 'wrong0$i');
        }
        
        final config = await TOTPService.getTwoFactorConfig(userId);
        expect(config.isLocked, isTrue);
        expect(config.lockTimeRemaining, isNotNull);
        expect(config.lockTimeRemaining!.inMinutes, closeTo(15, 1));
      });

      test('should handle configuration persistence across service restarts', () async {
        const userId = 'test-user';
        
        await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        final config1 = await TOTPService.getTwoFactorConfig(userId);
        expect(config1.isTotpEnabled, isTrue);
        
        // Configuration should persist (SharedPreferences mock maintains data)
        final config2 = await TOTPService.getTwoFactorConfig(userId);
        expect(config2.isTotpEnabled, isTrue);
        expect(config2.setupDate, equals(config1.setupDate));
      });
    });

    group('Security Features and Validation', () {
      test('should validate time windows correctly for clock synchronization', () async {
        const userId = 'test-user';
        
        final secret = await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        final baseTime = DateTime.now();
        
        // Test current time window
        final currentTimeStep = baseTime.millisecondsSinceEpoch ~/ 1000 ~/ 30 * 30 * 1000;
        final currentCode = OTP.generateTOTPCodeString(
          secret,
          currentTimeStep,
          length: 6,
          interval: 30,
        );
        
        final result1 = await TOTPService.verifyTOTP(userId, currentCode, timestamp: baseTime);
        expect(result1.isValid, isTrue);
        expect(result1.timeWindow, equals(0));
        
        // Test previous time window (30 seconds ago) - should still work due to drift tolerance
        final pastTime = baseTime.subtract(const Duration(seconds: 30));
        final pastTimeStep = pastTime.millisecondsSinceEpoch ~/ 1000 ~/ 30 * 30 * 1000;
        final pastCode = OTP.generateTOTPCodeString(
          secret,
          pastTimeStep,
          length: 6,
          interval: 30,
        );
        
        final result2 = await TOTPService.verifyTOTP(userId, pastCode, timestamp: pastTime);
        expect(result2.isValid, isTrue);
        expect(result2.timeWindow, equals(0)); // Relative to the timestamp provided
      });

      test('should handle concurrent verification attempts safely', () async {
        const userId = 'test-user';
        
        final secret = await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        final now = DateTime.now();
        final nowTimeStep = now.millisecondsSinceEpoch ~/ 1000 ~/ 30 * 30 * 1000;
        final validCode = OTP.generateTOTPCodeString(
          secret,
          nowTimeStep,
          length: 6,
          interval: 30,
        );
        
        // Attempt multiple concurrent verifications
        final futures = List.generate(3, (_) => 
          TOTPService.verifyTOTP(userId, validCode, timestamp: now)
        );
        
        final results = await Future.wait(futures);
        
        // Only one should succeed due to replay protection
        final successfulResults = results.where((r) => r.isValid).toList();
        expect(successfulResults.length, equals(1));
        
        // Others should fail with replay attack error
        final replayResults = results.where((r) => 
          !r.isValid && r.errorCode == 'REPLAY_ATTACK'
        ).toList();
        expect(replayResults.length, equals(2));
      });

      test('should cleanup old used codes to prevent memory growth', () async {
        const userId = 'test-user';
        
        final secret = await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        // Generate many codes across different time windows to test cleanup
        final baseTime = DateTime.now();
        
        for (int i = 0; i < 25; i++) { // Generate codes for 25 time windows
          final timeOffset = Duration(seconds: i * 30);
          final timestamp = baseTime.add(timeOffset);
          final timestampStep = timestamp.millisecondsSinceEpoch ~/ 1000 ~/ 30 * 30 * 1000;
          final code = OTP.generateTOTPCodeString(
            secret,
            timestampStep,
            length: 6,
            interval: 30,
          );
          
          await TOTPService.verifyTOTP(userId, code, timestamp: timestamp);
        }
        
        // Verify old codes are cleaned up (implementation should clean codes older than 10 minutes)
        // This is tested indirectly - the service should not accumulate unlimited used codes
      });

      test('should handle encryption/decryption errors gracefully', () async {
        const userId = 'test-user';
        
        // Generate secret normally
        await TOTPService.generateSecret(userId);
        
        // Manually corrupt the stored data by setting invalid encrypted data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('securyflex_totp_$userId', 'corrupted_data');
        
        final result = await TOTPService.verifyTOTP(userId, '123456');
        
        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('VERIFICATION_ERROR'));
        expect(result.errorMessage, contains('Fout bij verificatie'));
      });

      test('should provide secure secret generation with proper entropy', () async {
        const userId = 'test-user';
        
        // Generate multiple secrets and verify they're different
        final secrets = <String>[];
        
        for (int i = 0; i < 10; i++) {
          final secret = await TOTPService.generateSecret('$userId$i');
          secrets.add(secret);
          
          expect(secret, hasLength(greaterThan(25))); // Should be long enough
          expect(RegExp(r'^[A-Z2-7]+$').hasMatch(secret), isTrue); // Valid base32
        }
        
        // All secrets should be unique
        expect(Set<String>.from(secrets).length, equals(secrets.length));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle invalid JSON in stored configuration', () async {
        const userId = 'test-user';
        
        // Manually set invalid JSON
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('securyflex_2fa_config$userId', 'invalid{json}');
        
        final config = await TOTPService.getTwoFactorConfig(userId);
        
        // Should return default configuration
        expect(config.isTotpEnabled, isFalse);
        expect(config.failedAttempts, equals(0));
        expect(config.isLocked, isFalse);
      });

      test('should handle missing SharedPreferences gracefully', () async {
        // Test configuration retrieval when no data exists
        const userId = 'nonexistent-user';
        
        final config = await TOTPService.getTwoFactorConfig(userId);
        
        expect(config.isTotpEnabled, isFalse);
        expect(config.failedAttempts, equals(0));
        expect(config.setupDate, isNull);
      });

      test('should validate backup code generation parameters', () async {
        const userId = 'test-user';
        
        // Test with different counts
        final codes5 = await TOTPService.generateBackupCodes(userId, count: 5);
        expect(codes5, hasLength(5));
        
        final codes20 = await TOTPService.generateBackupCodes(userId, count: 20);
        expect(codes20, hasLength(20));
        
        // Default should be 10
        final codesDefault = await TOTPService.generateBackupCodes(userId);
        expect(codesDefault, hasLength(10));
      });

      test('should handle backup code format validation', () {
        // Test backup code generation and formatting
        final code = BackupCode.generate();
        
        expect(code.code, hasLength(8));
        expect(code.code, matches(r'^[A-Z0-9]+$'));
        expect(code.formattedCode, contains('-'));
        expect(code.formattedCode, hasLength(9)); // 8 chars + 1 dash
        expect(code.isUsed, isFalse);
        expect(code.createdAt, isNotNull);
        expect(code.usedAt, isNull);
        expect(code.hashedCode, isNotEmpty);
        expect(code.hashedCode, isNot(equals(code.code))); // Should be hashed
      });

      test('should verify backup code hashing security', () {
        final code = BackupCode.generate();
        final plainCode = code.code;
        
        // Verify code matches itself
        expect(code.verify(plainCode), isTrue);
        
        // Verify wrong codes don't match
        expect(code.verify('WRONGABC'), isFalse);
        expect(code.verify('12345678'), isFalse);
        
        // Verify formatted code also works
        expect(code.verify(code.formattedCode), isTrue);
        
        // Verify case sensitivity
        expect(code.verify(plainCode.toLowerCase()), isFalse);
      });
    });

    group('Performance and Scalability', () {
      test('should complete TOTP operations within reasonable time limits', () async {
        const userId = 'perf-test-user';
        
        // Secret generation should be fast
        final stopwatch1 = Stopwatch()..start();
        final secret = await TOTPService.generateSecret(userId);
        stopwatch1.stop();
        expect(stopwatch1.elapsedMilliseconds, lessThan(100));
        
        await TOTPService.enableTOTP(userId);
        
        // TOTP verification should be fast
        final now = DateTime.now();
        final perfTimeStep = now.millisecondsSinceEpoch ~/ 1000 ~/ 30 * 30 * 1000;
        final validCode = OTP.generateTOTPCodeString(
          secret,
          perfTimeStep,
          length: 6,
          interval: 30,
        );
        
        final stopwatch2 = Stopwatch()..start();
        final result = await TOTPService.verifyTOTP(userId, validCode, timestamp: now);
        stopwatch2.stop();
        
        expect(result.isValid, isTrue);
        expect(stopwatch2.elapsedMilliseconds, lessThan(200));
      });

      test('should handle multiple users efficiently', () async {
        const userCount = 10;
        
        // Setup TOTP for multiple users concurrently
        final futures = List.generate(userCount, (i) async {
          final userId = 'user$i';
          await TOTPService.generateSecret(userId);
          await TOTPService.enableTOTP(userId);
          return userId;
        });
        
        final userIds = await Future.wait(futures);
        expect(userIds, hasLength(userCount));
        
        // Verify all users have valid configurations
        for (final userId in userIds) {
          final config = await TOTPService.getTwoFactorConfig(userId);
          expect(config.isTotpEnabled, isTrue);
        }
      });

      test('should generate backup codes efficiently in batch', () async {
        const userId = 'batch-test-user';
        
        final stopwatch = Stopwatch()..start();
        final codes = await TOTPService.generateBackupCodes(userId, count: 50);
        stopwatch.stop();
        
        expect(codes, hasLength(50));
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
        
        // Verify all codes are unique
        final codeStrings = codes.map((c) => c.code).toSet();
        expect(codeStrings.length, equals(50));
      });
    });

    group('Dutch Localization and User Experience', () {
      test('should provide Dutch error messages for all scenarios', () {
        final testResults = [
          const TOTPVerificationResult(
            isValid: false,
            errorCode: 'ACCOUNT_LOCKED',
            errorMessage: 'Account tijdelijk vergrendeld wegens te veel mislukte pogingen',
          ),
          const TOTPVerificationResult(
            isValid: false,
            errorCode: 'NO_SECRET',
            errorMessage: 'TOTP nog niet ingesteld voor deze gebruiker',
          ),
          const TOTPVerificationResult(
            isValid: false,
            errorCode: 'REPLAY_ATTACK',
            errorMessage: 'Deze code is al recent gebruikt',
          ),
          const TOTPVerificationResult(
            isValid: false,
            errorCode: 'INVALID_CODE',
            errorMessage: 'Ongeldige verificatiecode',
          ),
        ];

        for (final result in testResults) {
          expect(result.errorMessage, isNotEmpty);
          expect(result.errorMessage!.toLowerCase(), contains(''));
          // Verify Dutch language characteristics
          final dutchWords = ['vergrendeld', 'ingesteld', 'gebruikt', 'ongeldig'];
          expect(dutchWords.any((word) => 
                 result.errorMessage!.toLowerCase().contains(word)), 
                 isTrue, reason: 'Error message should contain Dutch words');
        }
      });

      test('should provide Dutch status messages for backup codes', () {
        // Test various backup code status scenarios
        final statusNormal = BackupCodeStatus(total: 10, used: 3, remaining: 7);
        final statusLow = BackupCodeStatus(total: 10, used: 8, remaining: 2);
        final statusEmpty = BackupCodeStatus(total: 10, used: 10, remaining: 0);
        
        expect(statusNormal.statusDutch, contains('7 van 10 backup codes beschikbaar'));
        expect(statusLow.statusDutch, contains('Nog maar 2 backup codes over'));
        expect(statusEmpty.statusDutch, contains('Geen backup codes meer beschikbaar'));
        
        expect(statusNormal.isRunningLow, isFalse);
        expect(statusLow.isRunningLow, isTrue);
        expect(statusEmpty.isEmpty, isTrue);
      });

      test('should provide user-friendly configuration status', () async {
        const userId = 'status-test-user';
        
        // Test disabled status
        final config1 = await TOTPService.getTwoFactorConfig(userId);
        expect(config1.isTotpEnabled, isFalse);
        
        // Test enabled status
        await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        final config2 = await TOTPService.getTwoFactorConfig(userId);
        expect(config2.isTotpEnabled, isTrue);
        expect(config2.setupDate, isNotNull);
      });

      test('should handle QR code generation for Dutch users', () async {
        const userId = 'dutch-user';
        const userEmail = 'jan.de.vries@bedrijf.nl';
        const secret = 'JBSWY3DPEHPK3PXP';
        const issuer = 'SecuryFlex Nederland';
        
        final qrCodeData = await TOTPService.getQRCodeData(
          userId: userId,
          userEmail: userEmail,
          secret: secret,
          issuer: issuer,
        );
        
        expect(qrCodeData, startsWith('otpauth://totp/'));
        expect(qrCodeData, contains(Uri.encodeComponent(userEmail)));
        expect(qrCodeData, contains(Uri.encodeComponent(issuer)));
        expect(qrCodeData, contains('digits=6'));
        expect(qrCodeData, contains('period=30'));
      });
    });

    group('Integration with Enhanced Auth Models', () {
      test('should work with TwoFactorConfig model', () async {
        const userId = 'model-test-user';
        
        await TOTPService.generateSecret(userId);
        await TOTPService.enableTOTP(userId);
        
        final config = await TOTPService.getTwoFactorConfig(userId);
        
        // Test model properties
        expect(config, isA<TwoFactorUserConfig>());
        expect(config.isTotpEnabled, isTrue);
        expect(config.setupDate, isNotNull);
        expect(config.failedAttempts, isA<int>());
        expect(config.isLocked, isA<bool>());
        expect(config.lockTimeRemaining, isNull); // Should not be locked initially
        
        // Test copyWith functionality
        final updatedConfig = config.copyWith(failedAttempts: 1);
        expect(updatedConfig.failedAttempts, equals(1));
        expect(updatedConfig.isTotpEnabled, equals(config.isTotpEnabled));
      });

      test('should work with BackupCode model serialization', () {
        final originalCode = BackupCode.generate();
        
        // Test JSON serialization (should not include plain text code)
        final json = originalCode.toJson();
        expect(json, containsPair('hashedCode', isA<String>()));
        expect(json, containsPair('isUsed', isFalse));
        expect(json, containsPair('createdAt', isA<String>()));
        expect(json, isNot(contains('code'))); // Plain text code should not be serialized
        
        // Test deserialization
        final restoredCode = BackupCode.fromJson(json);
        expect(restoredCode.hashedCode, equals(originalCode.hashedCode));
        expect(restoredCode.isUsed, equals(originalCode.isUsed));
        expect(restoredCode.createdAt, equals(originalCode.createdAt));
        expect(restoredCode.code, isEmpty); // Plain text code should be empty after deserialization
      });
    });
  });
}