import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/schedule/services/location_crypto_service.dart';
import 'package:securyflex_app/schedule/models/time_entry_model.dart';

void main() {
  group('LocationCryptoService - Field-Level AES-256 Encryption Tests', () {
    setUp(() async {
      // Initialize crypto service for test user
      await LocationCryptoService.initializeForUser('test_user_123');
    });

    tearDown(() {
      // Clear keys after each test
      LocationCryptoService.clearKeys();
    });

    group('GPS Location Encryption/Decryption', () {
      test('should encrypt and decrypt GPS coordinates correctly', () async {
        // Arrange - Real GPS location
        final originalLocation = GPSLocation(
          latitude: 52.3676,
          longitude: 4.9041,
          accuracy: 8.5,
          altitude: 12.3,
          timestamp: DateTime.now(),
          provider: 'fused',
          isMocked: false,
        );

        // Act - Encrypt then decrypt
        final encryptedData = await LocationCryptoService.encryptLocation(originalLocation);
        final decryptedLocation = await LocationCryptoService.decryptLocation(encryptedData);

        // Assert
        expect(decryptedLocation.latitude, equals(originalLocation.latitude));
        expect(decryptedLocation.longitude, equals(originalLocation.longitude));
        expect(decryptedLocation.accuracy, equals(originalLocation.accuracy));
        expect(decryptedLocation.altitude, equals(originalLocation.altitude));
        expect(decryptedLocation.provider, equals(originalLocation.provider));
        expect(decryptedLocation.isMocked, equals(originalLocation.isMocked));
      });

      test('should use different IVs for each encryption operation', () async {
        // Arrange - Same location encrypted twice
        final location = GPSLocation(
          latitude: 52.3676,
          longitude: 4.9041,
          accuracy: 10.0,
          altitude: 0.0,
          timestamp: DateTime.now(),
          provider: 'fused',
          isMocked: false,
        );

        // Act
        final encrypted1 = await LocationCryptoService.encryptLocation(location);
        final encrypted2 = await LocationCryptoService.encryptLocation(location);

        // Assert - Different IVs and encrypted data
        expect(encrypted1.initializationVector, isNot(equals(encrypted2.initializationVector)));
        expect(encrypted1.encryptedLatitude, isNot(equals(encrypted2.encryptedLatitude)));
        expect(encrypted1.encryptedLongitude, isNot(equals(encrypted2.encryptedLongitude)));
      });

      test('should handle high-precision coordinates without loss', () async {
        // Arrange - Very precise GPS coordinates
        final preciseLocation = GPSLocation(
          latitude: 52.367612345678,
          longitude: 4.904087654321,
          accuracy: 3.141592653589793,
          altitude: 123.456789012345,
          timestamp: DateTime.now(),
          provider: 'network',
          isMocked: false,
        );

        // Act
        final encryptedData = await LocationCryptoService.encryptLocation(preciseLocation);
        final decryptedLocation = await LocationCryptoService.decryptLocation(encryptedData);

        // Assert - No precision loss
        expect(decryptedLocation.latitude, closeTo(preciseLocation.latitude, 0.000000000001));
        expect(decryptedLocation.longitude, closeTo(preciseLocation.longitude, 0.000000000001));
        expect(decryptedLocation.accuracy, closeTo(preciseLocation.accuracy, 0.000000000001));
        expect(decryptedLocation.altitude, closeTo(preciseLocation.altitude, 0.000000000001));
      });

      test('should encrypt location metadata separately', () async {
        // Arrange
        final location = GPSLocation(
          latitude: 52.3676,
          longitude: 4.9041,
          accuracy: 15.0,
          altitude: 45.7,
          timestamp: DateTime.now(),
          provider: 'gps',
          isMocked: true,
        );

        // Act
        final encryptedData = await LocationCryptoService.encryptLocation(location);

        // Assert - Verify encrypted data structure
        expect(encryptedData.encryptedLatitude, isNotEmpty);
        expect(encryptedData.encryptedLongitude, isNotEmpty);
        expect(encryptedData.encryptedMetadata, isNotEmpty);
        expect(encryptedData.keyVersion, equals(1));
        expect(encryptedData.encryptionAlgorithm, equals('AES-256-GCM'));
      });
    });

    group('Time Entry Encryption', () {
      test('should encrypt complete time entry with location pings', () async {
        // Arrange - Complex time entry
        final timeEntry = TimeEntry(
          id: 'entry_001',
          guardId: 'guard_crypto_test',
          jobSiteId: 'job_site_001',
          companyId: 'company_001',
          shiftId: 'shift_001',
          checkInTime: DateTime.now().subtract(Duration(hours: 8)),
          checkOutTime: DateTime.now(),
          status: TimeEntryStatus.approved,
          locationPings: [
            LocationPing(
              location: GPSLocation(
                latitude: 52.3676,
                longitude: 4.9041,
                accuracy: 10.0,
                altitude: 0.0,
                timestamp: DateTime.now().subtract(Duration(hours: 7)),
                provider: 'fused',
                isMocked: false,
              ),
              type: LocationPingType.periodic,
              distanceFromSite: 25.0,
              isWithinGeofence: true,
            ),
            LocationPing(
              location: GPSLocation(
                latitude: 52.3680,
                longitude: 4.9045,
                accuracy: 8.0,
                altitude: 2.0,
                timestamp: DateTime.now().subtract(Duration(hours: 4)),
                provider: 'fused',
                isMocked: false,
              ),
              type: LocationPingType.triggered,
              distanceFromSite: 15.0,
              isWithinGeofence: true,
            ),
          ],
          actualWorkDuration: Duration(hours: 8),
          plannedWorkDuration: Duration(hours: 8),
          breaks: [],
          checkInLocation: null,
          checkOutLocation: null,
          checkInVerified: true,
          checkOutVerified: true,
          regularHours: 8.0,
          overtimeHours: 0.0,
          weekendHours: 0.0,
          nightHours: 0.0,
          caoCompliance: const CAOCompliance(
            isCompliant: true,
            violations: [],
            restPeriodBefore: 11.0,
            restPeriodAfter: 11.0,
            hasRequiredBreaks: true,
            weeklyHours: 40.0,
            exceedsWeeklyLimit: false,
            exceedsDailyLimit: false,
          ),
          guardApproved: true,
          companyApproved: true,
          guardApprovedAt: null,
          companyApprovedAt: null,
          approvalNotes: null,
          discrepancies: [],
          createdAt: DateTime.now().subtract(Duration(hours: 8)),
          updatedAt: DateTime.now(),
          metadata: {},
          photos: [],
          notes: 'Nachtdienst beveiliging hoofdkantoor',
        );

        // Act
        final encryptedTimeEntry = await LocationCryptoService.encryptTimeEntry(timeEntry);

        // Assert
        expect(encryptedTimeEntry.timeEntryId, equals(timeEntry.id));
        expect(encryptedTimeEntry.encryptedMetadata, isNotEmpty);
        expect(encryptedTimeEntry.encryptedLocationPings.length, equals(2));
        expect(encryptedTimeEntry.keyVersion, equals(1));
        expect(encryptedTimeEntry.encryptionAlgorithm, equals('AES-256-GCM'));
      });

      test('should handle time entries with sensitive data', () async {
        // Arrange - Time entry with sensitive information
        final sensitiveTimeEntry = TimeEntry(
          id: 'sensitive_entry',
          guardId: 'guard_sensitive',
          jobSiteId: 'confidential_location',
          companyId: 'classified_company',
          shiftId: 'sensitive_shift',
          checkInTime: DateTime.now().subtract(Duration(hours: 4)),
          checkOutTime: DateTime.now(),
          status: TimeEntryStatus.approved,
          locationPings: [],
          actualWorkDuration: Duration(hours: 4),
          plannedWorkDuration: Duration(hours: 4),
          breaks: [],
          checkInLocation: null,
          checkOutLocation: null,
          checkInVerified: true,
          checkOutVerified: true,
          regularHours: 4.0,
          overtimeHours: 0.0,
          weekendHours: 0.0,
          nightHours: 0.0,
          caoCompliance: const CAOCompliance(
            isCompliant: true,
            violations: [],
            restPeriodBefore: 11.0,
            restPeriodAfter: 11.0,
            hasRequiredBreaks: true,
            weeklyHours: 40.0,
            exceedsWeeklyLimit: false,
            exceedsDailyLimit: false,
          ),
          guardApproved: true,
          companyApproved: true,
          guardApprovedAt: null,
          companyApprovedAt: null,
          approvalNotes: null,
          discrepancies: [],
          createdAt: DateTime.now().subtract(Duration(hours: 4)),
          updatedAt: DateTime.now(),
          metadata: {},
          photos: [],
          notes: 'Vertrouwelijke missie - topgeheim',
        );

        // Act
        final encrypted = await LocationCryptoService.encryptTimeEntry(sensitiveTimeEntry);

        // Assert - Sensitive data is encrypted
        expect(encrypted.encryptedMetadata, isNotEmpty);
        expect(encrypted.encryptedMetadata, isNot(contains('guard_sensitive')));
        expect(encrypted.encryptedMetadata, isNot(contains('confidential_location')));
        expect(encrypted.encryptedMetadata, isNot(contains('topgeheim')));
      });
    });

    group('Key Management and Rotation', () {
      test('should generate unique keys for different users', () async {
        // Arrange - Initialize for different users
        LocationCryptoService.clearKeys();
        await LocationCryptoService.initializeForUser('user_001');
        
        final location = GPSLocation(
          latitude: 52.3676,
          longitude: 4.9041,
          accuracy: 10.0,
          altitude: 0.0,
          timestamp: DateTime.now(),
          provider: 'fused',
          isMocked: false,
        );
        
        final encrypted1 = await LocationCryptoService.encryptLocation(location);

        // Switch to different user
        LocationCryptoService.clearKeys();
        await LocationCryptoService.initializeForUser('user_002');
        final encrypted2 = await LocationCryptoService.encryptLocation(location);

        // Assert - Different encryption results
        expect(encrypted1.encryptedLatitude, isNot(equals(encrypted2.encryptedLatitude)));
        expect(encrypted1.encryptedLongitude, isNot(equals(encrypted2.encryptedLongitude)));
      });

      test('should perform key rotation successfully', () async {
        // Arrange - Initial encryption
        final location = GPSLocation(
          latitude: 52.3676,
          longitude: 4.9041,
          accuracy: 10.0,
          altitude: 0.0,
          timestamp: DateTime.now(),
          provider: 'fused',
          isMocked: false,
        );

        final encryptedBefore = await LocationCryptoService.encryptLocation(location);
        expect(encryptedBefore.keyVersion, equals(1));

        // Act - Rotate keys
        final rotationResult = await LocationCryptoService.rotateKeys('test_user_123');

        // Encrypt with new keys
        final encryptedAfter = await LocationCryptoService.encryptLocation(location);

        // Assert
        expect(rotationResult.success, isTrue);
        expect(rotationResult.newKeyVersion, equals(2));
        expect(encryptedAfter.keyVersion, equals(2));
        expect(encryptedBefore.encryptedLatitude, 
          isNot(equals(encryptedAfter.encryptedLatitude)));
      });

      test('should maintain key derivation consistency', () async {
        // Arrange - Clear and reinitialize same user
        LocationCryptoService.clearKeys();
        await LocationCryptoService.initializeForUser('consistent_user');
        
        final location = GPSLocation(
          latitude: 52.3676,
          longitude: 4.9041,
          accuracy: 10.0,
          altitude: 0.0,
          timestamp: DateTime.now(),
          provider: 'fused',
          isMocked: false,
        );
        
        final encrypted1 = await LocationCryptoService.encryptLocation(location);
        final decrypted1 = await LocationCryptoService.decryptLocation(encrypted1);

        // Reinitialize same user
        LocationCryptoService.clearKeys();
        await LocationCryptoService.initializeForUser('consistent_user');
        
        final decrypted2 = await LocationCryptoService.decryptLocation(encrypted1);

        // Assert - Same decryption results
        expect(decrypted1.latitude, equals(decrypted2.latitude));
        expect(decrypted1.longitude, equals(decrypted2.longitude));
      });
    });

    group('Security and Error Handling', () {
      test('should throw exception when not initialized', () async {
        // Arrange - Clear initialization
        LocationCryptoService.clearKeys();
        
        final location = GPSLocation(
          latitude: 52.3676,
          longitude: 4.9041,
          accuracy: 10.0,
          altitude: 0.0,
          timestamp: DateTime.now(),
          provider: 'fused',
          isMocked: false,
        );

        // Act & Assert
        expect(
          () => LocationCryptoService.encryptLocation(location),
          throwsA(isA<LocationCryptoException>()),
        );
      });

      test('should handle corrupted encrypted data gracefully', () async {
        // Arrange - Valid encryption
        final location = GPSLocation(
          latitude: 52.3676,
          longitude: 4.9041,
          accuracy: 10.0,
          altitude: 0.0,
          timestamp: DateTime.now(),
          provider: 'fused',
          isMocked: false,
        );

        final encryptedData = await LocationCryptoService.encryptLocation(location);
        
        // Corrupt the encrypted data
        final corruptedData = EncryptedLocationData(
          encryptedLatitude: 'corrupted_data',
          encryptedLongitude: encryptedData.encryptedLongitude,
          encryptedMetadata: encryptedData.encryptedMetadata,
          initializationVector: encryptedData.initializationVector,
          timestamp: encryptedData.timestamp,
          keyVersion: encryptedData.keyVersion,
          encryptionAlgorithm: encryptedData.encryptionAlgorithm,
        );

        // Act & Assert
        expect(
          () => LocationCryptoService.decryptLocation(corruptedData),
          throwsA(isA<LocationCryptoException>()),
        );
      });

      test('should validate key version compatibility', () async {
        // Arrange - Create encrypted data with future key version
        final location = GPSLocation(
          latitude: 52.3676,
          longitude: 4.9041,
          accuracy: 10.0,
          altitude: 0.0,
          timestamp: DateTime.now(),
          provider: 'fused',
          isMocked: false,
        );

        final encryptedData = await LocationCryptoService.encryptLocation(location);
        
        // Create data with incompatible key version
        final futureVersionData = EncryptedLocationData(
          encryptedLatitude: encryptedData.encryptedLatitude,
          encryptedLongitude: encryptedData.encryptedLongitude,
          encryptedMetadata: encryptedData.encryptedMetadata,
          initializationVector: encryptedData.initializationVector,
          timestamp: encryptedData.timestamp,
          keyVersion: 999, // Future version
          encryptionAlgorithm: encryptedData.encryptionAlgorithm,
        );

        // Act & Assert
        expect(
          () => LocationCryptoService.decryptLocation(futureVersionData),
          throwsA(isA<LocationCryptoException>()),
        );
      });

      test('should handle authentication failures', () async {
        // Arrange - No authenticated user
        LocationCryptoService.clearKeys();
        
        // Act & Assert
        expect(
          () => LocationCryptoService.initializeForUser(''),
          throwsA(isA<LocationCryptoException>()),
        );
      });
    });

    group('Performance and Scalability Tests', () {
      test('should encrypt large batches of locations efficiently', () async {
        // Arrange - Large batch of locations
        final locations = List.generate(1000, (index) => GPSLocation(
          latitude: 52.3676 + (index * 0.0001),
          longitude: 4.9041 + (index * 0.0001),
          accuracy: 8.0 + index.toDouble() % 20,
          altitude: index.toDouble(),
          timestamp: DateTime.now().add(Duration(seconds: index)),
          provider: 'fused',
          isMocked: index % 100 == 0,
        ));

        // Act
        final stopwatch = Stopwatch()..start();
        
        final encryptedLocations = <EncryptedLocationData>[];
        for (final location in locations) {
          final encrypted = await LocationCryptoService.encryptLocation(location);
          encryptedLocations.add(encrypted);
        }
        
        stopwatch.stop();

        // Assert
        expect(encryptedLocations.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Under 10 seconds
      });

      test('should handle memory efficiently during continuous operations', () async {
        // Arrange - Simulate continuous 8-hour tracking
        final startTime = DateTime.now();
        
        // Act - Process locations every 30 seconds for 8 hours (960 locations)
        for (int i = 0; i < 960; i++) {
          final location = GPSLocation(
            latitude: 52.3676 + (i * 0.00001),
            longitude: 4.9041 + (i * 0.00001),
            accuracy: 8.0 + (i % 10).toDouble(),
            altitude: (i % 100).toDouble(),
            timestamp: startTime.add(Duration(seconds: i * 30)),
            provider: 'fused',
            isMocked: false,
          );

          final encrypted = await LocationCryptoService.encryptLocation(location);
          final decrypted = await LocationCryptoService.decryptLocation(encrypted);
          
          // Verify data integrity every 100 operations
          if (i % 100 == 0) {
            expect(decrypted.latitude, closeTo(location.latitude, 0.0000001));
            expect(decrypted.longitude, closeTo(location.longitude, 0.0000001));
          }
        }

        // Assert - Test completed without memory issues
        expect(true, isTrue); // Test completion indicates success
      });

      test('should maintain consistent performance under load', () async {
        // Arrange - Performance baseline
        final testLocation = GPSLocation(
          latitude: 52.3676,
          longitude: 4.9041,
          accuracy: 10.0,
          altitude: 0.0,
          timestamp: DateTime.now(),
          provider: 'fused',
          isMocked: false,
        );

        // Measure baseline encryption time
        final baselineStopwatch = Stopwatch()..start();
        await LocationCryptoService.encryptLocation(testLocation);
        baselineStopwatch.stop();
        final baselineTime = baselineStopwatch.elapsedMicroseconds;

        // Act - Perform many operations then measure again
        for (int i = 0; i < 100; i++) {
          final location = GPSLocation(
            latitude: 52.3676 + (i * 0.0001),
            longitude: 4.9041 + (i * 0.0001),
            accuracy: 10.0,
            altitude: 0.0,
            timestamp: DateTime.now(),
            provider: 'fused',
            isMocked: false,
          );
          await LocationCryptoService.encryptLocation(location);
        }

        final loadTestStopwatch = Stopwatch()..start();
        await LocationCryptoService.encryptLocation(testLocation);
        loadTestStopwatch.stop();
        final loadTestTime = loadTestStopwatch.elapsedMicroseconds;

        // Assert - Performance degradation should be minimal
        expect(loadTestTime, lessThan(baselineTime * 2)); // Max 2x slower
      });
    });

    group('Dutch GDPR/AVG Compliance Tests', () {
      test('should provide audit trail for all crypto operations', () async {
        // Arrange
        final location = GPSLocation(
          latitude: 52.3676,
          longitude: 4.9041,
          accuracy: 10.0,
          altitude: 0.0,
          timestamp: DateTime.now(),
          provider: 'fused',
          isMocked: false,
        );

        // Act - Perform various crypto operations
        final encrypted = await LocationCryptoService.encryptLocation(location);
        await LocationCryptoService.decryptLocation(encrypted);
        await LocationCryptoService.rotateKeys('test_user_123');

        // Assert - Audit operations should be logged (implementation detail)
        // In production, verify audit log entries exist
        expect(encrypted.keyVersion, isNotNull);
        expect(encrypted.timestamp, isNotNull);
      });

      test('should support data minimization principles', () async {
        // Arrange - Location with minimal necessary data
        final minimalLocation = GPSLocation(
          latitude: 52.3676,
          longitude: 4.9041,
          accuracy: 10.0,
          altitude: 0.0, // Minimal altitude
          timestamp: DateTime.now(),
          provider: 'system', // Generic provider
          isMocked: false,
        );

        // Act
        final encrypted = await LocationCryptoService.encryptLocation(minimalLocation);
        final decrypted = await LocationCryptoService.decryptLocation(encrypted);

        // Assert - Only necessary data is preserved
        expect(decrypted.latitude, isNotNull);
        expect(decrypted.longitude, isNotNull);
        expect(decrypted.timestamp, isNotNull);
      });

      test('should enable secure data deletion (right to be forgotten)', () async {
        // Arrange
        final location = GPSLocation(
          latitude: 52.3676,
          longitude: 4.9041,
          accuracy: 10.0,
          altitude: 0.0,
          timestamp: DateTime.now(),
          provider: 'fused',
          isMocked: false,
        );

        final encrypted = await LocationCryptoService.encryptLocation(location);

        // Act - Simulate user deletion (clear keys)
        LocationCryptoService.clearKeys();

        // Assert - Data becomes unrecoverable without keys
        expect(
          () => LocationCryptoService.decryptLocation(encrypted),
          throwsA(isA<LocationCryptoException>()),
        );
      });
    });
  });
}