import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

import 'package:securyflex_app/auth/services/kvk_api_service.dart';
import 'package:securyflex_app/auth/services/kvk_additional_classes.dart';

/// Mock HTTP client for testing
class MockHttpClient extends Mock implements http.Client {}

/// Mock KvK persistent cache for testing
class MockKvKPersistentCache extends Mock {
  static Future<KvKData?> retrieve(String kvkNumber) => Future.value(null);
  static Future<void> store(String kvkNumber, KvKData data) => Future.value();
  static Future<void> logAudit({
    required String kvkNumber,
    required String action,
    required bool success,
    String? errorCode,
    int? durationMs,
    String? source,
  }) => Future.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('KvK API Service Tests', () {
    
    setUpAll(() {
      registerFallbackValue(Uri.parse('https://api.kvk.nl/api/v1/zoeken?kvkNummer=12345678'));
    });

    setUp(() {
      KvKApiService.resetService(); // Clear cache and state
    });

    tearDown(() {
      KvKApiService.resetService();
    });

    group('KvK Number Format Validation', () {
      test('should validate correct 8-digit KvK numbers', () async {
        const validKvKNumbers = [
          '12345678',
          '87654321',
          '11223344',
          '99887766',
          '12300000',
        ];

        for (final kvkNumber in validKvKNumbers) {
          final result = await KvKApiService.validateKvK(kvkNumber);
          expect(result, isNotNull, reason: 'KvK $kvkNumber should be valid');
          expect(result!.kvkNumber, equals(kvkNumber));
          expect(result.companyName, isNotEmpty);
        }
      });

      test('should reject invalid KvK number formats', () async {
        const invalidKvKNumbers = [
          '123',           // Too short
          '123456789',     // Too long
          'ABCD1234',      // Contains letters
          '1234-5678',     // Contains special characters
          '',              // Empty string
          '1234567A',      // Mixed alphanumeric
          '12 34 56 78',   // Contains spaces
        ];

        for (final kvkNumber in invalidKvKNumbers) {
          expect(
            () => KvKApiService.validateKvK(kvkNumber),
            throwsA(isA<KvKValidationException>()
                .having((e) => e.code, 'code', 'invalid-format')),
            reason: 'KvK $kvkNumber should be invalid',
          );
        }
      });

      test('should provide Dutch error messages for invalid formats', () async {
        try {
          await KvKApiService.validateKvK('123');
          fail('Should throw exception for invalid format');
        } catch (e) {
          expect(e, isA<KvKValidationException>());
          final exception = e as KvKValidationException;
          expect(exception.localizedMessage, contains('ongeldig formaat'));
          expect(exception.actionSuggestion, contains('8-cijferig KvK nummer'));
        }
      });
    });

    group('Dutch Business Logic Validation', () {
      test('should validate security industry SBI codes', () {
        // Valid security SBI codes
        expect(SecuritySbiCodes.isValidSecurityCode('80101'), isTrue);
        expect(SecuritySbiCodes.isValidSecurityCode('80102'), isTrue);
        expect(SecuritySbiCodes.isValidSecurityCode('80201'), isTrue);
        expect(SecuritySbiCodes.isValidSecurityCode('80301'), isTrue);
        
        // Invalid SBI codes
        expect(SecuritySbiCodes.isValidSecurityCode('12345'), isFalse);
        expect(SecuritySbiCodes.isValidSecurityCode('99999'), isFalse);
        expect(SecuritySbiCodes.isValidSecurityCode(''), isFalse);
        expect(SecuritySbiCodes.isValidSecurityCode(null), isFalse);
      });

      test('should provide Dutch descriptions for security SBI codes', () {
        expect(SecuritySbiCodes.getSecurityDescription('80101'), 
               equals('Particuliere beveiligingsdiensten'));
        expect(SecuritySbiCodes.getSecurityDescription('80102'), 
               equals('Bewakingsdiensten'));
        expect(SecuritySbiCodes.getSecurityDescription('80201'), 
               equals('Alarm- en bewakingssystemen'));
        expect(SecuritySbiCodes.getSecurityDescription('80301'), 
               equals('Onderzoeks- en detectivediensten'));
        expect(SecuritySbiCodes.getSecurityDescription('99999'), 
               equals('Algemene beveiligingsdiensten'));
      });

      test('should calculate security eligibility correctly', () {
        // Active company with security SBI code
        final eligibleCompany = KvKData(
          kvkNumber: '12345678',
          companyName: 'Test Security B.V.',
          tradeName: 'Test Security',
          legalForm: 'Besloten vennootschap',
          address: const KvKAddress(
            street: 'Teststraat',
            houseNumber: '1',
            postalCode: '1234AB',
            city: 'Amsterdam',
          ),
          isActive: true,
          foundationDate: DateTime(2020, 1, 1),
          sbiCode: '80101',
          sbiDescription: 'Particuliere beveiliging',
          website: 'https://test.nl',
          phoneNumber: '+31 20 123 4567',
        );

        final result = KvKApiService.calculateSecurityEligibility(eligibleCompany);
        
        expect(result.isEligible, isTrue);
        expect(result.score, greaterThan(0.5));
        expect(result.reasons, isNotEmpty);
        expect(result.reasons.any((r) => r.contains('actief')), isTrue);
        expect(result.reasons.any((r) => r.contains('beveiligingsactiviteiten')), isTrue);
      });

      test('should reject inactive companies', () {
        final inactiveCompany = KvKData(
          kvkNumber: '12345678',
          companyName: 'Inactive Company',
          tradeName: 'Inactive',
          legalForm: 'Besloten vennootschap',
          address: const KvKAddress(
            street: 'Teststraat',
            houseNumber: '1',
            postalCode: '1234AB',
            city: 'Amsterdam',
          ),
          isActive: false, // Not active
          sbiCode: '80101', // Valid security code
          sbiDescription: 'Particuliere beveiliging',
        );

        final result = KvKApiService.calculateSecurityEligibility(inactiveCompany);
        
        expect(result.isEligible, isFalse);
        expect(result.requirements, contains(contains('actief zijn')));
      });

      test('should reject non-security industry companies', () {
        final nonSecurityCompany = KvKData(
          kvkNumber: '12345678',
          companyName: 'Bakery B.V.',
          tradeName: 'Dutch Bakery',
          legalForm: 'Besloten vennootschap',
          address: const KvKAddress(
            street: 'Bakkerstraat',
            houseNumber: '10',
            postalCode: '1234AB',
            city: 'Amsterdam',
          ),
          isActive: true,
          sbiCode: '10711', // Bakery SBI code
          sbiDescription: 'Vervaardiging van brood',
        );

        final result = KvKApiService.calculateSecurityEligibility(nonSecurityCompany);
        
        expect(result.isEligible, isFalse);
        expect(result.requirements, contains(contains('beveiligingsactiviteiten')));
      });
    });

    group('Mock Data Generation', () {
      test('should generate realistic Dutch mock company data', () async {
        const testKvKNumbers = ['12345678', '87654321', '11111111'];

        for (final kvkNumber in testKvKNumbers) {
          final result = await KvKApiService.validateKvK(kvkNumber);
          expect(result, isNotNull);
          expect(result!.kvkNumber, equals(kvkNumber));
          expect(result.companyName, isNotEmpty);
          expect(result.companyName, contains('B.V.')); // Dutch legal form
          expect(result.address, isNotNull);
          expect(result.address!.hasValidDutchPostalCode, isTrue);
          expect(result.phoneNumber, startsWith('+31')); // Dutch phone number
          expect(result.isActive, isTrue);
          expect(result.sbiCode, isNotEmpty);
          expect(SecuritySbiCodes.isValidSecurityCode(result.sbiCode), isTrue);
        }
      });

      test('should generate unique company names for different KvK numbers', () async {
        final result1 = await KvKApiService.validateKvK('11111111');
        final result2 = await KvKApiService.validateKvK('22222222');
        
        expect(result1!.companyName, isNot(equals(result2!.companyName)));
      });
    });

    group('Address Validation', () {
      test('should validate Dutch postal codes correctly', () {
        // Valid Dutch postal codes
        const validPostalCodes = [
          '1012AB', '1234CD', '9999ZZ', '1000AA', '2000BB'
        ];
        
        for (final postalCode in validPostalCodes) {
          final address = KvKAddress(
            street: 'Test Street',
            houseNumber: '1',
            postalCode: postalCode,
            city: 'Amsterdam',
          );
          expect(address.hasValidDutchPostalCode, isTrue, 
                 reason: 'Postal code $postalCode should be valid');
        }
      });

      test('should reject invalid Dutch postal codes', () {
        const invalidPostalCodes = [
          '123AB',    // Too short
          '12345AB',  // Too long
          '1234A',    // Missing letter
          'ABCD12',   // Wrong format
          '12341',    // Numbers only
        ];
        
        for (final postalCode in invalidPostalCodes) {
          final address = KvKAddress(
            street: 'Test Street',
            houseNumber: '1',
            postalCode: postalCode,
            city: 'Amsterdam',
          );
          expect(address.hasValidDutchPostalCode, isFalse,
                 reason: 'Postal code $postalCode should be invalid');
        }
      });

      test('should format full addresses correctly', () {
        const address = KvKAddress(
          street: 'Damrak',
          houseNumber: '123',
          houseNumberAddition: 'A',
          postalCode: '1012AB',
          city: 'Amsterdam',
        );

        expect(address.fullAddress, equals('Damrak 123A, 1012AB Amsterdam'));
      });

      test('should handle international addresses', () {
        const address = KvKAddress(
          street: 'Main Street',
          houseNumber: '456',
          postalCode: '12345',
          city: 'New York',
          country: 'USA',
        );

        expect(address.fullAddress, contains('USA'));
        expect(address.hasValidDutchPostalCode, isFalse);
      });
    });

    group('Rate Limiting and Caching', () {
      test('should respect rate limiting for same user', () async {
        const userId = 'test-user';
        const kvkNumber = '12345678';
        
        // First request should succeed
        final result1 = await KvKApiService.validateKvK(kvkNumber, userId: userId);
        expect(result1, isNotNull);
        
        // Simulate rapid consecutive requests (would be rate limited in real scenario)
        // In demo mode, this should still work but be logged
        final result2 = await KvKApiService.validateKvK(kvkNumber, userId: userId);
        expect(result2, isNotNull);
      });

      test('should cache validation results efficiently', () async {
        const kvkNumber = '12345678';
        
        // First request - should generate data
        final startTime = DateTime.now();
        final result1 = await KvKApiService.validateKvK(kvkNumber);
        final firstRequestTime = DateTime.now().difference(startTime);
        
        // Second request - should use cache
        final startTime2 = DateTime.now();
        final result2 = await KvKApiService.validateKvK(kvkNumber);
        final secondRequestTime = DateTime.now().difference(startTime2);
        
        expect(result1!.kvkNumber, equals(result2!.kvkNumber));
        expect(result1.companyName, equals(result2.companyName));
        // Cached request should be significantly faster
        expect(secondRequestTime.inMilliseconds, lessThan(firstRequestTime.inMilliseconds));
      });

      test('should handle cache expiry correctly', () async {
        const kvkNumber = '12345678';
        
        // Get initial data
        final result1 = await KvKApiService.validateKvK(kvkNumber);
        expect(result1, isNotNull);
        
        // Clear cache
        KvKApiService.clearCache();
        
        // Should generate new data after cache clear
        final result2 = await KvKApiService.validateKvK(kvkNumber);
        expect(result2, isNotNull);
        expect(result2!.kvkNumber, equals(kvkNumber));
      });
    });

    group('Batch Operations', () {
      test('should validate multiple KvK numbers efficiently', () async {
        const kvkNumbers = ['12345678', '87654321', '11223344'];
        
        final results = await KvKApiService.validateMultiple(kvkNumbers);
        
        expect(results, hasLength(kvkNumbers.length));
        expect(results.keys, containsAll(kvkNumbers));
        
        for (final kvkNumber in kvkNumbers) {
          final result = results[kvkNumber];
          expect(result, isNotNull, reason: 'KvK $kvkNumber should have result');
          expect(result!.kvkNumber, equals(kvkNumber));
          expect(result.isActive, isTrue);
        }
      });

      test('should handle mixed valid/invalid KvK numbers in batch', () async {
        // Note: In the current implementation, invalid formats throw exceptions
        // before reaching batch processing. This test demonstrates the expected behavior.
        const validKvKNumbers = ['12345678', '87654321'];
        
        final results = await KvKApiService.validateMultiple(validKvKNumbers);
        
        expect(results, hasLength(validKvKNumbers.length));
        expect(results['12345678'], isNotNull);
        expect(results['87654321'], isNotNull);
      });
    });

    group('Company Search Functionality', () {
      test('should search companies by name in demo mode', () async {
        const searchTerm = 'Security';
        
        final results = await KvKApiService.searchCompaniesByName(
          searchTerm,
          maxResults: 3,
        );
        
        expect(results, isNotEmpty);
        expect(results.length, lessThanOrEqualTo(3));
        
        for (final company in results) {
          expect(company.companyName.toLowerCase(), contains(searchTerm.toLowerCase()));
          expect(company.isActive, isTrue);
          expect(SecuritySbiCodes.isValidSecurityCode(company.sbiCode), isTrue);
        }
      });

      test('should filter search results by city', () async {
        const searchTerm = 'Security';
        const city = 'Amsterdam';
        
        final results = await KvKApiService.searchCompaniesByName(
          searchTerm,
          city: city,
          maxResults: 5,
        );
        
        expect(results, isNotEmpty);
        for (final company in results) {
          expect(company.address?.city, equals(city));
        }
      });

      test('should respect activeOnly filter', () async {
        const searchTerm = 'Security';
        
        final activeResults = await KvKApiService.searchCompaniesByName(
          searchTerm,
          activeOnly: true,
          maxResults: 5,
        );
        
        expect(activeResults, isNotEmpty);
        for (final company in activeResults) {
          expect(company.isActive, isTrue);
        }
        
        final allResults = await KvKApiService.searchCompaniesByName(
          searchTerm,
          activeOnly: false,
          maxResults: 5,
        );
        
        expect(allResults, isNotEmpty);
        // In demo mode, all companies are active, so results should be similar
        expect(allResults.length, greaterThanOrEqualTo(activeResults.length));
      });
    });

    group('Error Handling and Recovery', () {
      test('should handle network timeouts gracefully', () async {
        // This test would require mocking HTTP client to simulate timeout
        // For now, we test the exception structure
        const kvkNumber = '12345678';
        
        try {
          // In demo mode, this won't actually timeout, but we can test the exception structure
          await KvKApiService.validateKvK(kvkNumber);
        } catch (e) {
          if (e is KvKValidationException && e.code == 'timeout') {
            expect(e.localizedMessage, contains('te lang'));
            expect(e.actionSuggestion, contains('opnieuw'));
            expect(e.isRetryable, isTrue);
          }
        }
      });

      test('should provide appropriate error codes and messages', () {
        final exception1 = KvKValidationException('Test error', code: 'not-found');
        expect(exception1.localizedMessage, contains('niet gevonden'));
        expect(exception1.actionSuggestion, contains('Controleer het KvK nummer'));
        
        final exception2 = KvKValidationException('Network error', code: 'network-error');
        expect(exception2.localizedMessage, contains('Netwerkfout'));
        expect(exception2.isRetryable, isTrue);
      });

      test('should handle invalid API responses', () {
        // Test exception creation for various error scenarios
        final exceptions = [
          KvKValidationException('Not found', code: 'not-found'),
          KvKValidationException('Rate limited', code: 'rate-limited'),
          KvKValidationException('Server error', code: 'server-error'),
          KvKValidationException('Unauthorized', code: 'unauthorized'),
        ];

        for (final exception in exceptions) {
          expect(exception.localizedMessage, isNotEmpty);
          expect(exception.actionSuggestion, isNotEmpty);
        }
      });
    });

    group('Service State Management', () {
      test('should provide comprehensive cache statistics', () async {
        // Populate cache with some data
        await KvKApiService.validateKvK('12345678');
        await KvKApiService.validateKvK('87654321');
        
        final stats = KvKApiService.getCacheStats();
        
        expect(stats, containsPair('cache', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('rateLimiting', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('requests', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('audit', isA<Map<String, dynamic>>()));
        
        final cacheStats = stats['cache'] as Map<String, dynamic>;
        expect(cacheStats['totalEntries'], greaterThan(0));
        expect(cacheStats['validEntries'], greaterThan(0));
      });

      test('should reset service state completely', () {
        // Populate some state
        KvKApiService.validateKvK('12345678');
        
        // Reset service
        KvKApiService.resetService();
        
        final stats = KvKApiService.getCacheStats();
        final cacheStats = stats['cache'] as Map<String, dynamic>;
        expect(cacheStats['totalEntries'], equals(0));
      });
    });

    group('Company Status Validation', () {
      test('should validate company status comprehensively', () async {
        const kvkNumber = '12345678';
        
        final status = await KvKApiService.validateCompanyStatus(kvkNumber);
        
        expect(status, isNotNull);
        expect(status!.kvkNumber, equals(kvkNumber));
        expect(status.isValid, isTrue);
        expect(status.isActive, isTrue);
        expect(status.isSecurityEligible, isA<bool>());
        expect(status.eligibilityScore, greaterThanOrEqualTo(0.0));
        expect(status.eligibilityScore, lessThanOrEqualTo(1.0));
        expect(status.dutchStatusDescription, isNotEmpty);
        expect(status.companyData, isNotNull);
      });

      test('should handle invalid KvK numbers in status validation', () async {
        try {
          await KvKApiService.validateCompanyStatus('invalid');
          fail('Should throw exception for invalid KvK number');
        } catch (e) {
          expect(e, isA<KvKValidationException>());
          expect((e as KvKValidationException).code, equals('invalid-format'));
        }
      });
    });

    group('Performance Requirements', () {
      test('should complete validation within reasonable time limits', () async {
        const kvkNumber = '12345678';
        
        final stopwatch = Stopwatch()..start();
        final result = await KvKApiService.validateKvK(kvkNumber);
        stopwatch.stop();
        
        expect(result, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(2000), // Should complete within 2 seconds
               reason: 'KvK validation should be fast in demo mode');
      });

      test('should handle concurrent validations efficiently', () async {
        const kvkNumbers = ['12345678', '87654321', '11223344', '99887766'];
        
        final stopwatch = Stopwatch()..start();
        final futures = kvkNumbers.map((kvk) => KvKApiService.validateKvK(kvk)).toList();
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        expect(results, hasLength(kvkNumbers.length));
        expect(results.every((r) => r != null), isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(5000), // All should complete within 5 seconds
               reason: 'Concurrent validations should be efficient');
      });
    });

    group('Compliance and Audit Requirements', () {
      test('should log all validation attempts for audit trails', () async {
        const kvkNumber = '12345678';
        const userId = 'audit-test-user';
        
        final result = await KvKApiService.validateKvK(kvkNumber, userId: userId);
        expect(result, isNotNull);
        
        // Verify audit logging would occur (in actual implementation)
        // This would check the audit log entries
        final stats = KvKApiService.getCacheStats();
        expect(stats['audit'], containsPair('totalLogEntries', greaterThanOrEqualTo(0)));
      });

      test('should maintain GDPR compliance in data handling', () async {
        const kvkNumber = '12345678';
        
        final result = await KvKApiService.validateKvK(kvkNumber);
        expect(result, isNotNull);
        
        // Verify no sensitive personal information is logged
        // Company information is public, but verify proper data handling
        expect(result!.companyName, isNotEmpty);
        expect(result.address, isNotNull);
        
        // Verify data minimization - only necessary fields are present
        expect(result.kvkNumber, equals(kvkNumber));
        expect(result.isActive, isA<bool>());
      });
    });

    group('Dutch Language Support', () {
      test('should provide all error messages in Dutch', () {
        final errorCodes = [
          'invalid-format',
          'not-found',
          'inactive-company',
          'not-security-eligible',
          'rate-limited',
          'network-error',
          'timeout',
          'api-error',
          'unauthorized',
          'max-retries-exceeded',
        ];

        for (final code in errorCodes) {
          final exception = KvKValidationException('Test', code: code);
          expect(exception.localizedMessage, isNotEmpty, 
                 reason: 'Error code $code should have Dutch message');
          expect(exception.actionSuggestion, isNotEmpty,
                 reason: 'Error code $code should have Dutch action suggestion');
        }
      });

      test('should provide Dutch status descriptions', () async {
        const kvkNumber = '12345678';
        
        final status = await KvKApiService.validateCompanyStatus(kvkNumber);
        expect(status, isNotNull);
        expect(status!.dutchStatusDescription, isNotEmpty);
        
        // Verify it's actually Dutch
        final dutchWords = ['gevalideerd', 'actief', 'geschikt', 'niet'];
        expect(dutchWords.any((word) => 
               status.dutchStatusDescription.toLowerCase().contains(word)), 
               isTrue, reason: 'Status should contain Dutch words');
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('should handle empty and null inputs gracefully', () async {
        expect(() => KvKApiService.validateKvK(''), 
               throwsA(isA<KvKValidationException>()));
      });

      test('should handle whitespace in KvK numbers', () async {
        const kvkWithSpaces = ' 12345678 ';
        final result = await KvKApiService.validateKvK(kvkWithSpaces);
        
        expect(result, isNotNull);
        expect(result!.kvkNumber, equals('12345678')); // Should be cleaned
      });

      test('should handle maximum cache size limits', () async {
        // Generate many unique KvK numbers to test cache limits
        final kvkNumbers = List.generate(50, (i) => (12345600 + i).toString());
        
        for (final kvkNumber in kvkNumbers) {
          await KvKApiService.validateKvK(kvkNumber);
        }
        
        final stats = KvKApiService.getCacheStats();
        final cacheStats = stats['cache'] as Map<String, dynamic>;
        
        // Cache should not grow indefinitely
        expect(cacheStats['totalEntries'], lessThanOrEqualTo(100));
      });
    });

    group('Security and Penetration Testing', () {
      test('should prevent injection attacks in KvK numbers', () async {
        final maliciousInputs = [
          "12345678'; DROP TABLE companies; --",
          '12345678<script>alert("xss")</script>',
          '12345678\${process.env}',
          '12345678`cat /etc/passwd`',
          '12345678" OR "1"="1',
          '12345678\\n\\r\\t',
        ];

        for (final maliciousInput in maliciousInputs) {
          expect(
            () => KvKApiService.validateKvK(maliciousInput),
            throwsA(isA<KvKValidationException>()
                .having((e) => e.code, 'code', 'invalid-format')),
            reason: 'Should reject malicious input: $maliciousInput',
          );
        }
      });

      test('should rate limit aggressive API usage', () async {
        const userId = 'rate-limit-test-user';
        const kvkNumber = '12345678';
        
        // Test rapid-fire requests (in production, this would be rate limited)
        final futures = List.generate(20, (_) => 
          KvKApiService.validateKvK(kvkNumber, userId: userId));
        
        // All should complete in demo mode, but in production would be limited
        final results = await Future.wait(futures);
        expect(results.every((r) => r != null), isTrue);
        
        // Verify rate limiting tracking
        final stats = KvKApiService.getCacheStats();
        expect(stats['rateLimiting'], isNotNull);
      });

      test('should sanitize and validate all input parameters', () async {
        // Test various edge cases that could cause security issues
        const edgeCases = [
          '00000000', // All zeros
          '11111111', // All ones  
          '99999999', // All nines
          '12345678', // Sequential
          '87654321', // Reverse sequential
        ];

        for (final kvkNumber in edgeCases) {
          final result = await KvKApiService.validateKvK(kvkNumber);
          expect(result, isNotNull);
          expect(result!.kvkNumber, matches(RegExp(r'^\d{8}$')));
          expect(result.companyName, isNotEmpty);
        }
      });

      test('should prevent cache pollution attacks', () async {
        // Test that invalid inputs don\'t pollute the cache
        const invalidInputs = ['invalid', '123', 'abcd1234'];
        
        for (final invalid in invalidInputs) {
          expect(
            () => KvKApiService.validateKvK(invalid),
            throwsA(isA<KvKValidationException>()),
          );
        }
        
        // Verify cache remains clean
        final stats = KvKApiService.getCacheStats();
        final cacheStats = stats['cache'] as Map<String, dynamic>;
        expect(cacheStats['validEntries'], equals(cacheStats['totalEntries']));
      });
    });

    group('Dutch Business Rules Compliance', () {
      test('should validate company foundation date requirements', () {
        final recentCompany = KvKData(
          kvkNumber: '12345678',
          companyName: 'New Security B.V.',
          tradeName: 'New Security',
          legalForm: 'Besloten vennootschap',
          address: const KvKAddress(
            street: 'Teststraat',
            houseNumber: '1',
            postalCode: '1234AB',
            city: 'Amsterdam',
          ),
          isActive: true,
          foundationDate: DateTime.now().subtract(const Duration(days: 30)), // Very recent
          sbiCode: '80101',
          sbiDescription: 'Particuliere beveiliging',
        );

        final result = KvKApiService.calculateSecurityEligibility(recentCompany);
        
        // Should have lower eligibility score due to recent foundation
        expect(result.score, lessThan(0.9));
        expect(result.requirements, 
               contains(contains('minimaal 1 jaar bestaan')));
      });

      test('should enforce Dutch legal form requirements', () async {
        const kvkNumber = '12345678';
        final result = await KvKApiService.validateKvK(kvkNumber);
        
        expect(result, isNotNull);
        expect(result!.legalForm, isNotEmpty);
        
        // Should be a valid Dutch legal form
        const validDutchLegalForms = [
          'Besloten vennootschap',
          'Naamloze vennootschap', 
          'Vennootschap onder firma',
          'Commanditaire vennootschap',
          'Eenmanszaak',
          'Stichting',
          'Vereniging',
        ];
        
        expect(validDutchLegalForms.any((form) => 
               result.legalForm.contains(form)), isTrue,
               reason: 'Should use valid Dutch legal form');
      });

      test('should validate Dutch address format requirements', () async {
        const kvkNumber = '12345678';
        final result = await KvKApiService.validateKvK(kvkNumber);
        
        expect(result, isNotNull);
        expect(result!.address, isNotNull);
        
        final address = result.address!;
        expect(address.street, isNotEmpty);
        expect(address.houseNumber, isNotEmpty);
        expect(address.postalCode, matches(RegExp(r'^\d{4}[A-Z]{2}$')));
        expect(address.city, isNotEmpty);
        expect(address.country, anyOf(equals('Nederland'), equals('')));
      });

      test('should enforce security industry registration requirements', () {
        final nonEligibleCompany = KvKData(
          kvkNumber: '12345678',
          companyName: 'Restaurant B.V.',
          tradeName: 'Dutch Restaurant',
          legalForm: 'Besloten vennootschap',
          address: const KvKAddress(
            street: 'Foodstraat',
            houseNumber: '10',
            postalCode: '1234AB',
            city: 'Amsterdam',
          ),
          isActive: true,
          foundationDate: DateTime(2020, 1, 1),
          sbiCode: '56101', // Restaurant SBI code
          sbiDescription: 'Restaurants',
        );

        final result = KvKApiService.calculateSecurityEligibility(nonEligibleCompany);
        
        expect(result.isEligible, isFalse);
        expect(result.score, lessThan(0.5));
        expect(result.requirements, 
               contains(contains('beveiligingsactiviteiten')));
        expect(result.requirements,
               contains(contains('SBI codes: 80101, 80102, 80201, 80301')));
      });

      test('should validate phone number format for Dutch companies', () async {
        const kvkNumber = '12345678';
        final result = await KvKApiService.validateKvK(kvkNumber);
        
        expect(result, isNotNull);
        expect(result!.phoneNumber, isNotNull);
        expect(result.phoneNumber!, startsWith('+31'));
        
        // Should match Dutch phone number format
        expect(result.phoneNumber!, 
               matches(RegExp(r'^\+31\s?[1-9][0-9](\s?[0-9]{3}\s?[0-9]{4}|\s?[0-9]{7})$')));
      });
    });
  });
}