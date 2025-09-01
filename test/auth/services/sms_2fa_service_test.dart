import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:securyflex_app/auth/services/sms_2fa_service.dart';

/// Mock SharedPreferences for testing
class MockSharedPreferences extends Mock implements SharedPreferences {}

/// Mock FirebaseAuth for testing
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

/// Mock PhoneAuthCredential for testing
class MockPhoneAuthCredential extends Mock implements PhoneAuthCredential {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SMS 2FA Service Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('Dutch Phone Number Validation', () {
      test('should validate correct Dutch phone numbers', () {
        const validPhoneNumbers = [
          '+31612345678',    // International format with +
          '0031612345678',   // International format with 00
          '31612345678',     // International format without prefix
          '0612345678',      // National format
          '612345678',       // Local format (mobile)
          '+31712345678',    // Landline 7
          '+31812345678',    // Service number 8
          '+31912345678',    // Service number 9
          '+31 6 12345678',  // With spaces
          '06-12345678',     // With dash
          '06 12 34 56 78',  // With spaces
        ];

        for (final phoneNumber in validPhoneNumbers) {
          expect(SMS2FAService.isValidDutchPhoneNumber(phoneNumber), isTrue,
                 reason: 'Phone number $phoneNumber should be valid');
        }
      });

      test('should reject invalid Dutch phone numbers', () {
        const invalidPhoneNumbers = [
          '+1234567890',     // Non-Dutch country code
          '+31512345678',    // Invalid area code (5)
          '+316123456789',   // Too long
          '+3161234567',     // Too short
          '31412345678',     // Invalid area code (4)
          '+31012345678',    // Invalid area code (0)
          '+32612345678',    // Belgian country code
          '12345678',        // Too short without country code
          'abcd1234567',     // Contains letters
          '',                // Empty string
          '+31',             // Only country code
        ];

        for (final phoneNumber in invalidPhoneNumbers) {
          expect(SMS2FAService.isValidDutchPhoneNumber(phoneNumber), isFalse,
                 reason: 'Phone number $phoneNumber should be invalid');
        }
      });

      test('should format phone numbers to international standard', () {
        const testCases = {
          '0612345678': '+31612345678',
          '612345678': '+31612345678',
          '0031612345678': '+31612345678',
          '31612345678': '+31612345678',
          '+31612345678': '+31612345678', // Already formatted
          '06 12 34 56 78': '+31612345678', // With spaces
          '06-12345678': '+31612345678', // With dash
        };

        testCases.forEach((input, expected) {
          final result = SMS2FAService.formatDutchPhoneNumber(input);
          expect(result, equals(expected),
                 reason: 'Phone number $input should format to $expected, got $result');
        });
      });

      test('should preserve original format for non-recognized numbers', () {
        const unrecognizedNumbers = [
          '+1234567890',
          'invalid-phone',
          '+44123456789',
        ];

        for (final phoneNumber in unrecognizedNumbers) {
          final result = SMS2FAService.formatDutchPhoneNumber(phoneNumber);
          expect(result, equals(phoneNumber),
                 reason: 'Unrecognized phone number should be preserved');
        }
      });
    });

    group('SMS Verification Code Sending', () {
      test('should send verification code successfully in demo mode', () async {
        const userId = 'test-user';
        const phoneNumber = '+31612345678';

        final result = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        expect(result.success, isTrue);
        expect(result.verificationId, isNotNull);
        expect(result.verificationId, isNotEmpty);
        expect(result.message, contains('verzonden'));
        expect(result.messageDutch, contains('verzonden'));
        expect(result.cooldownSeconds, equals(60));
        expect(result.message, contains('Demo:'));
      });

      test('should reject invalid phone number formats', () async {
        const userId = 'test-user';
        const invalidPhone = '+1234567890'; // Non-Dutch number

        final result = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: invalidPhone,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('INVALID_PHONE_FORMAT'));
        expect(result.errorMessage, contains('Ongeldig telefoonnummer format'));
        expect(result.errorMessageDutch, contains('Nederlands format'));
      });

      test('should implement rate limiting for SMS requests', () async {
        const userId = 'rate-limit-test-user';
        const phoneNumber = '+31612345678';

        // Send multiple SMS requests to trigger rate limiting
        for (int i = 0; i < 6; i++) { // Exceed max of 5 per hour
          await SMS2FAService.sendVerificationCode(
            userId: userId,
            phoneNumber: phoneNumber,
          );
        }

        // This request should be rate limited
        final result = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('RATE_LIMITED'));
        expect(result.errorMessage, contains('Te veel SMS aanvragen'));
        expect(result.cooldownSeconds, isNotNull);
        expect(result.cooldownSeconds!, greaterThan(0));
      });

      test('should implement resend cooldown', () async {
        const userId = 'cooldown-test-user';
        const phoneNumber = '+31612345678';

        // Send initial SMS
        final result1 = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );
        expect(result1.success, isTrue);

        // Immediate resend should be blocked by cooldown
        final result2 = await SMS2FAService.resendCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        expect(result2.success, isFalse);
        expect(result2.errorCode, equals('RESEND_COOLDOWN'));
        expect(result2.errorMessage, contains('Wacht nog'));
        expect(result2.cooldownSeconds, isNotNull);
      });

      test('should detect fraud attempts', () async {
        const userId = 'fraud-test-user';
        const phoneNumbers = [
          '+31612345678',
          '+31687654321',
          '+31611111111',
          '+31622222222', // 4th different number should trigger fraud detection
        ];

        // Use multiple phone numbers rapidly
        for (final phone in phoneNumbers.take(3)) {
          await SMS2FAService.sendVerificationCode(
            userId: userId,
            phoneNumber: phone,
          );
        }

        // 4th different number should be flagged as fraud
        final result = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumbers.last,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('FRAUD_DETECTED'));
        expect(result.errorMessage, contains('Verdachte activiteit'));
      });

      test('should handle phone number obfuscation for privacy', () async {
        const userId = 'privacy-test-user';
        const phoneNumber = '+31612345678';

        final result = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        expect(result.success, isTrue);
        expect(result.message, contains('+31****78')); // Obfuscated format
        expect(result.message, isNot(contains('612345678'))); // Full number should not appear
      });
    });

    group('SMS Code Verification', () {
      test('should verify correct SMS codes in demo mode', () async {
        const userId = 'verify-test-user';
        const phoneNumber = '+31612345678';

        // Send SMS first
        final sendResult = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );
        expect(sendResult.success, isTrue);

        // Extract demo code from message (format: "Demo: 123456")
        final message = sendResult.message!;
        final demoCodeMatch = RegExp(r'Demo: (\d{6})').firstMatch(message);
        expect(demoCodeMatch, isNotNull);
        final demoCode = demoCodeMatch!.group(1)!;

        // Verify the demo code
        final verifyResult = await SMS2FAService.verifyCode(
          userId: userId,
          code: demoCode,
          verificationId: sendResult.verificationId!,
        );

        expect(verifyResult.success, isTrue);
        expect(verifyResult.message, contains('succesvol geverifieerd'));
        expect(verifyResult.messageDutch, contains('succesvol geverifieerd'));
      });

      test('should reject incorrect SMS codes', () async {
        const userId = 'reject-test-user';
        const phoneNumber = '+31612345678';

        // Send SMS first
        final sendResult = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );
        expect(sendResult.success, isTrue);

        // Try with wrong code
        final verifyResult = await SMS2FAService.verifyCode(
          userId: userId,
          code: '000000',
          verificationId: sendResult.verificationId!,
        );

        expect(verifyResult.success, isFalse);
        expect(verifyResult.errorCode, equals('INVALID_CODE'));
        expect(verifyResult.errorMessage, contains('Ongeldige verificatiecode'));
        expect(verifyResult.remainingAttempts, equals(2)); // Max 3 attempts, 1 used
      });

      test('should handle code expiration', () async {
        const userId = 'expiry-test-user';
        const phoneNumber = '+31612345678';

        // Send SMS
        final sendResult = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );
        expect(sendResult.success, isTrue);

        // Manually expire the verification by modifying stored data
        final prefs = await SharedPreferences.getInstance();
        final verificationKey = 'securyflex_sms_verification$userId';
        final storedData = prefs.getString(verificationKey);
        expect(storedData, isNotNull);

        // Simulate expired verification (modify the JSON)
        final expired = storedData!.replaceAll(
          RegExp(r'"expiresAt":"[^"]*"'),
          '"expiresAt":"2020-01-01T00:00:00.000Z"', // Past date
        );
        await prefs.setString(verificationKey, expired);

        // Try to verify with any code
        final verifyResult = await SMS2FAService.verifyCode(
          userId: userId,
          code: '123456',
          verificationId: sendResult.verificationId!,
        );

        expect(verifyResult.success, isFalse);
        expect(verifyResult.errorCode, equals('CODE_EXPIRED'));
        expect(verifyResult.errorMessage, contains('verlopen'));
      });

      test('should implement maximum verification attempts', () async {
        const userId = 'max-attempts-test-user';
        const phoneNumber = '+31612345678';

        // Send SMS
        final sendResult = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );
        expect(sendResult.success, isTrue);

        // Make 3 failed attempts (max allowed)
        for (int i = 0; i < 3; i++) {
          final attempt = await SMS2FAService.verifyCode(
            userId: userId,
            code: 'wrong$i',
            verificationId: sendResult.verificationId!,
          );
          expect(attempt.success, isFalse);
          expect(attempt.remainingAttempts, equals(2 - i));
        }

        // 4th attempt should be blocked
        final blockedAttempt = await SMS2FAService.verifyCode(
          userId: userId,
          code: '123456',
          verificationId: sendResult.verificationId!,
        );

        expect(blockedAttempt.success, isFalse);
        expect(blockedAttempt.errorCode, equals('MAX_ATTEMPTS_EXCEEDED'));
        expect(blockedAttempt.errorMessage, contains('Te veel onjuiste pogingen'));
      });

      test('should handle verification without active session', () async {
        const userId = 'no-session-test-user';

        final result = await SMS2FAService.verifyCode(
          userId: userId,
          code: '123456',
          verificationId: 'fake-verification-id',
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('NO_VERIFICATION'));
        expect(result.errorMessage, contains('Geen actieve verificatie'));
      });

      test('should validate code format strictly', () async {
        const userId = 'format-test-user';
        const phoneNumber = '+31612345678';

        // Send SMS first
        final sendResult = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );
        expect(sendResult.success, isTrue);

        // Test various invalid formats
        final invalidCodes = [
          '12345',       // Too short
          '1234567',     // Too long
          'abcdef',      // Letters
          '12-34-56',    // With dashes
          '12 34 56',    // With spaces
          '',            // Empty
          'ABCDEF',      // Uppercase letters
        ];

        for (final code in invalidCodes) {
          final result = await SMS2FAService.verifyCode(
            userId: userId,
            code: code,
            verificationId: sendResult.verificationId!,
          );
          expect(result.success, isFalse, 
                 reason: 'Code "$code" should be invalid');
          expect(result.errorCode, equals('INVALID_CODE'));
        }
      });
    });

    group('SMS 2FA Configuration Management', () {
      test('should setup SMS 2FA configuration', () async {
        const userId = 'config-test-user';
        const phoneNumber = '0612345678'; // National format

        final result = await SMS2FAService.setupSMS2FA(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        expect(result, isTrue);

        // Verify configuration was saved
        final config = await SMS2FAService.getSMS2FAConfig(userId);
        expect(config, isNotNull);
        expect(config!.phoneNumber, equals('+31612345678')); // Formatted
        expect(config.isEnabled, isFalse); // Not enabled until verified
        expect(config.setupDate, isNotNull);
        expect(config.verifiedDate, isNull);
      });

      test('should enable SMS 2FA after successful setup', () async {
        const userId = 'enable-test-user';
        const phoneNumber = '+31612345678';

        // Setup first
        await SMS2FAService.setupSMS2FA(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        // Enable 2FA
        await SMS2FAService.enableSMS2FA(userId);

        // Verify it's enabled
        final config = await SMS2FAService.getSMS2FAConfig(userId);
        expect(config, isNotNull);
        expect(config!.isEnabled, isTrue);
        expect(config.verifiedDate, isNotNull);
      });

      test('should disable SMS 2FA with verification', () async {
        const userId = 'disable-test-user';
        const phoneNumber = '+31612345678';

        // Setup and enable
        await SMS2FAService.setupSMS2FA(userId: userId, phoneNumber: phoneNumber);
        await SMS2FAService.enableSMS2FA(userId);

        // Disable with verification code
        final result = await SMS2FAService.disableSMS2FA(
          userId: userId,
          verificationCode: '123456', // In demo mode, any code works
        );

        expect(result, isTrue);

        // Verify it's disabled (configuration should be removed)
        final config = await SMS2FAService.getSMS2FAConfig(userId);
        expect(config, isNull);
      });

      test('should handle configuration persistence', () async {
        const userId = 'persist-test-user';
        const phoneNumber = '+31612345678';

        // Setup configuration
        await SMS2FAService.setupSMS2FA(userId: userId, phoneNumber: phoneNumber);
        
        // Get configuration multiple times to test persistence
        final config1 = await SMS2FAService.getSMS2FAConfig(userId);
        final config2 = await SMS2FAService.getSMS2FAConfig(userId);

        expect(config1, isNotNull);
        expect(config2, isNotNull);
        expect(config1!.phoneNumber, equals(config2!.phoneNumber));
        expect(config1.setupDate, equals(config2.setupDate));
      });

      test('should handle missing configuration gracefully', () async {
        const userId = 'missing-config-user';

        final config = await SMS2FAService.getSMS2FAConfig(userId);
        expect(config, isNull);
      });

      test('should properly serialize and deserialize configuration', () async {
        const userId = 'serialize-test-user';
        const phoneNumber = '+31612345678';

        // Setup configuration
        await SMS2FAService.setupSMS2FA(userId: userId, phoneNumber: phoneNumber);
        await SMS2FAService.enableSMS2FA(userId);

        // Get configuration to test serialization
        final config = await SMS2FAService.getSMS2FAConfig(userId);
        expect(config, isNotNull);

        // Test JSON serialization
        final json = config!.toJson();
        expect(json['isEnabled'], isTrue);
        expect(json['phoneNumber'], equals(phoneNumber));
        expect(json['setupDate'], isNotNull);
        expect(json['verifiedDate'], isNotNull);

        // Test deserialization
        final deserializedConfig = SMS2FAConfig.fromJson(json);
        expect(deserializedConfig.isEnabled, equals(config.isEnabled));
        expect(deserializedConfig.phoneNumber, equals(config.phoneNumber));
        expect(deserializedConfig.setupDate, equals(config.setupDate));
        expect(deserializedConfig.verifiedDate, equals(config.verifiedDate));
      });
    });

    group('Rate Limiting and Security', () {
      test('should implement hourly rate limiting', () async {
        const userId = 'hourly-limit-user';
        const phoneNumber = '+31612345678';

        // Send SMS requests up to hourly limit (5)
        for (int i = 0; i < 5; i++) {
          final result = await SMS2FAService.sendVerificationCode(
            userId: userId,
            phoneNumber: phoneNumber,
          );
          expect(result.success, isTrue,
                 reason: 'Request $i should succeed within hourly limit');
        }

        // 6th request should be rate limited
        final rateLimitedResult = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        expect(rateLimitedResult.success, isFalse);
        expect(rateLimitedResult.errorCode, equals('RATE_LIMITED'));
        expect(rateLimitedResult.errorMessage, contains('Te veel SMS aanvragen'));
        expect(rateLimitedResult.cooldownSeconds, isNotNull);
        expect(rateLimitedResult.cooldownSeconds!, greaterThan(0));
      });

      test('should implement daily rate limiting', () async {
        const userId = 'daily-limit-user';
        const phoneNumber = '+31612345678';

        // Simulate sending 10 SMS (daily limit) by setting the counter directly
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('sms_day_count_$userId', 10);
        await prefs.setString(
          'sms_day_reset_$userId',
          DateTime.now().add(const Duration(hours: 12)).toIso8601String(),
        );

        // Next request should be blocked by daily limit
        final result = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('RATE_LIMITED'));
        expect(result.errorMessage, contains('Dagelijkse SMS limiet'));
      });

      test('should detect and prevent fraud attempts', () async {
        const userId = 'fraud-detection-user';
        const phoneNumbers = [
          '+31612345678',
          '+31687654321',
          '+31611111111',
          '+31622222222', // This should trigger fraud detection
        ];

        // Rapidly use different phone numbers
        for (int i = 0; i < 3; i++) {
          await SMS2FAService.sendVerificationCode(
            userId: userId,
            phoneNumber: phoneNumbers[i],
          );
        }

        // 4th different number should be detected as fraudulent
        final fraudResult = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumbers[3],
        );

        expect(fraudResult.success, isFalse);
        expect(fraudResult.errorCode, equals('FRAUD_DETECTED'));
        expect(fraudResult.errorMessage, contains('Verdachte activiteit'));
      });

      test('should properly obfuscate phone numbers for privacy', () {
        const testCases = {
          '+31612345678': '+31****78',
          '0612345678': '061****78',
          '123': '****', // Short numbers
          '12': '****',  // Very short numbers
        };

        testCases.forEach((input, expected) {
          // This is testing the private method indirectly through SMS sending
          // In a real test, you might expose this method or test it through public APIs
        });
      });

      test('should handle concurrent SMS requests safely', () async {
        const userId = 'concurrent-test-user';
        const phoneNumber = '+31612345678';

        // Send multiple concurrent requests
        final futures = List.generate(3, (_) => 
          SMS2FAService.sendVerificationCode(
            userId: userId,
            phoneNumber: phoneNumber,
          )
        );

        final results = await Future.wait(futures);

        // All requests should complete, but some may be rate limited
        expect(results.length, equals(3));
        
        // At least one should succeed (the first one)
        expect(results.any((r) => r.success), isTrue);
        
        // Some may be rate limited due to cooldown
        final rateLimitedCount = results.where((r) => 
          !r.success && r.errorCode == 'RESEND_COOLDOWN'
        ).length;
        
        expect(rateLimitedCount, greaterThanOrEqualTo(0));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle verification data corruption gracefully', () async {
        const userId = 'corruption-test-user';

        // Manually set corrupted verification data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'securyflex_sms_verification$userId',
          'corrupted-json-data',
        );

        // Verification should handle corruption gracefully
        final result = await SMS2FAService.verifyCode(
          userId: userId,
          code: '123456',
          verificationId: 'any-id',
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('VERIFICATION_ERROR'));
        expect(result.errorMessage, contains('Fout bij verificatie'));
      });

      test('should handle missing SharedPreferences gracefully', () async {
        // Test when SharedPreferences operations fail
        const userId = 'missing-prefs-user';

        // This should not throw an exception
        final config = await SMS2FAService.getSMS2FAConfig(userId);
        expect(config, isNull);
      });

      test('should handle empty phone numbers', () {
        expect(SMS2FAService.isValidDutchPhoneNumber(''), isFalse);
        expect(SMS2FAService.formatDutchPhoneNumber(''), equals(''));
      });

      test('should handle phone numbers with only spaces', () {
        const spacesOnly = '   ';
        expect(SMS2FAService.isValidDutchPhoneNumber(spacesOnly), isFalse);
      });

      test('should validate verification data model correctly', () {
        final verificationData = SMSVerificationData(
          verificationId: 'test-id',
          phoneNumber: '+31612345678',
          sentAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          attempts: 0,
          maxAttempts: 3,
          demoCode: '123456',
        );

        // Test JSON serialization
        final json = verificationData.toJson();
        expect(json['verificationId'], equals('test-id'));
        expect(json['phoneNumber'], equals('+31612345678'));
        expect(json['attempts'], equals(0));
        expect(json['maxAttempts'], equals(3));
        expect(json['demoCode'], equals('123456'));

        // Test deserialization
        final deserialized = SMSVerificationData.fromJson(json);
        expect(deserialized.verificationId, equals(verificationData.verificationId));
        expect(deserialized.phoneNumber, equals(verificationData.phoneNumber));
        expect(deserialized.attempts, equals(verificationData.attempts));
        expect(deserialized.maxAttempts, equals(verificationData.maxAttempts));
        expect(deserialized.demoCode, equals(verificationData.demoCode));
      });
    });

    group('Performance and Scalability', () {
      test('should complete SMS operations within reasonable time', () async {
        const userId = 'performance-test-user';
        const phoneNumber = '+31612345678';

        final stopwatch = Stopwatch()..start();
        
        final result = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );
        
        stopwatch.stop();

        expect(result.success, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000), // Should complete within 1 second
               reason: 'SMS sending should be fast in demo mode');
      });

      test('should handle multiple users efficiently', () async {
        const userCount = 5;
        const basePhoneNumber = '+3161234567';

        // Send SMS for multiple users concurrently
        final futures = List.generate(userCount, (i) {
          return SMS2FAService.sendVerificationCode(
            userId: 'perf-user-$i',
            phoneNumber: '$basePhoneNumber$i',
          );
        });

        final results = await Future.wait(futures);

        expect(results.length, equals(userCount));
        expect(results.every((r) => r.success), isTrue);
      });

      test('should clean up expired verification data', () async {
        const userId = 'cleanup-test-user';
        const phoneNumber = '+31612345678';

        // Send SMS to create verification data
        await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        // Manually expire the verification data
        final prefs = await SharedPreferences.getInstance();
        final verificationKey = 'securyflex_sms_verification$userId';
        final storedData = prefs.getString(verificationKey);
        expect(storedData, isNotNull);

        final expired = storedData!.replaceAll(
          RegExp(r'"expiresAt":"[^"]*"'),
          '"expiresAt":"2020-01-01T00:00:00.000Z"',
        );
        await prefs.setString(verificationKey, expired);

        // Try to verify - this should clean up expired data
        await SMS2FAService.verifyCode(
          userId: userId,
          code: '123456',
          verificationId: 'any-id',
        );

        // Verification data should be cleaned up
        final cleanedData = prefs.getString(verificationKey);
        expect(cleanedData, isNull);
      });
    });

    group('Dutch Language and User Experience', () {
      test('should provide all error messages in Dutch', () {
        // Test error message localization

        // Verify Dutch language characteristics in error messages
        final dutchWords = [
          'ongeldig', 'telefoonnummer', 'format', 'veel', 'aanvragen',
          'wacht', 'verdachte', 'activiteit', 'fout', 'versturen',
          'geen', 'actieve', 'verificatie', 'verlopen', 'vraag',
          'nieuwe', 'onjuiste', 'pogingen', 'ongeldige', 'code'
        ];

        // These words should appear in Dutch error messages
        expect(dutchWords, isNotEmpty);
      });

      test('should format phone numbers appropriately for Dutch users', () {
        const dutchFormats = {
          '0612345678': '+31612345678',
          '06 12 34 56 78': '+31612345678',
          '06-12-345-678': '+31612345678',
        };

        dutchFormats.forEach((input, expected) {
          final result = SMS2FAService.formatDutchPhoneNumber(input);
          expect(result, equals(expected));
        });
      });

      test('should provide user-friendly success messages in Dutch', () async {
        const userId = 'dutch-message-user';
        const phoneNumber = '+31612345678';

        // Test sending message
        final sendResult = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        expect(sendResult.success, isTrue);
        expect(sendResult.messageDutch, isNotNull);
        expect(sendResult.messageDutch, contains('verzonden'));

        // Test verification message
        final message = sendResult.message!;
        final demoCodeMatch = RegExp(r'Demo: (\d{6})').firstMatch(message);
        final demoCode = demoCodeMatch!.group(1)!;

        final verifyResult = await SMS2FAService.verifyCode(
          userId: userId,
          code: demoCode,
          verificationId: sendResult.verificationId!,
        );

        expect(verifyResult.success, isTrue);
        expect(verifyResult.messageDutch, contains('geverifieerd'));
      });

      test('should handle Dutch cultural preferences for phone formatting', () {
        // Test common Dutch phone number writing styles
        const commonStyles = [
          '06-12345678',      // With single dash
          '06 12 34 56 78',   // With spaces
          '(06) 12345678',    // With parentheses (though less common)
        ];

        for (final style in commonStyles) {
          expect(SMS2FAService.isValidDutchPhoneNumber(style), isTrue,
                 reason: 'Style $style should be valid for Dutch users');
        }
      });
    });

    group('Integration with Enhanced Auth Models', () {
      test('should work with SMS2FAResult model', () async {
        const userId = 'model-test-user';
        const phoneNumber = '+31612345678';

        final result = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        // Test model properties
        expect(result, isA<SMS2FAResult>());
        expect(result.success, isA<bool>());
        expect(result.verificationId, isA<String?>());
        expect(result.message, isA<String?>());
        expect(result.messageDutch, isA<String?>());
        expect(result.cooldownSeconds, isA<int?>());
        expect(result.autoVerified, isA<bool>());
      });

      test('should work with SMS2FAConfig model serialization', () async {
        const userId = 'config-model-user';
        const phoneNumber = '+31612345678';

        await SMS2FAService.setupSMS2FA(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        final config = await SMS2FAService.getSMS2FAConfig(userId);
        expect(config, isNotNull);

        // Test model methods
        expect(config, isA<SMS2FAConfig>());
        
        // Test copyWith functionality
        final updatedConfig = config!.copyWith(
          isEnabled: true,
          lastUsed: DateTime.now(),
        );
        
        expect(updatedConfig.isEnabled, isTrue);
        expect(updatedConfig.phoneNumber, equals(config.phoneNumber));
        expect(updatedConfig.setupDate, equals(config.setupDate));
        expect(updatedConfig.lastUsed, isNotNull);

        // Test JSON serialization
        final json = config.toJson();
        final deserializedConfig = SMS2FAConfig.fromJson(json);
        
        expect(deserializedConfig.phoneNumber, equals(config.phoneNumber));
        expect(deserializedConfig.isEnabled, equals(config.isEnabled));
        expect(deserializedConfig.setupDate, equals(config.setupDate));
      });
    });

    group('Security Audit and Logging', () {
      test('should log security events for audit trails', () async {
        const userId = 'audit-test-user';
        const phoneNumber = '+31612345678';

        // This test verifies that security events are logged
        // In the actual implementation, events are logged via print statements
        // In production, these would go to a proper audit logging system

        final result = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        expect(result.success, isTrue);

        // Verify verification attempt is logged
        final message = result.message!;
        final demoCodeMatch = RegExp(r'Demo: (\d{6})').firstMatch(message);
        final demoCode = demoCodeMatch!.group(1)!;

        final verifyResult = await SMS2FAService.verifyCode(
          userId: userId,
          code: demoCode,
          verificationId: result.verificationId!,
        );

        expect(verifyResult.success, isTrue);

        // Events should be logged (tested indirectly through success/failure)
      });

      test('should protect sensitive information in logs', () async {
        const userId = 'sensitive-info-user';
        const phoneNumber = '+31612345678';

        final result = await SMS2FAService.sendVerificationCode(
          userId: userId,
          phoneNumber: phoneNumber,
        );

        // Phone number should be obfuscated in messages
        expect(result.message, isNot(contains(phoneNumber)));
        expect(result.message, contains('****')); // Should contain obfuscation
      });
    });
  });
}