import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/schedule/services/location_verification_service.dart';
import 'package:securyflex_app/schedule/models/shift_model.dart';

void main() {
  late LocationVerificationService service;

  setUp(() {
    service = LocationVerificationService();
  });

  // Helper function to create test job site
  ShiftLocation _createTestJobSite() {
    return ShiftLocation(
      address: 'Test Address 123',
      city: 'Amsterdam',
      postalCode: '1000AB',
      latitude: 52.3676,
      longitude: 4.9041,
      geofenceRadius: 100.0,
      locationNotes: 'Test location',
      landmarks: [],
    );
  }

  group('LocationVerificationService Tests', () {
    group('Check-In Location Verification', () {
      test('should verify valid check-in location', () async {
        // Arrange
        final jobSite = _createTestJobSite();

        // Act
        final result = await service.verifyCheckInLocation(jobSite: jobSite);

        // Assert
        expect(result.isSuccessful, isTrue);
        expect(result.targetLocation, equals(jobSite));
        expect(result.verificationType, equals(LocationVerificationType.checkIn));
      });

      test('should verify check-in location with custom radius', () async {
        // Arrange
        final jobSite = _createTestJobSite();

        // Act
        final result = await service.verifyCheckInLocation(
          jobSite: jobSite, 
          customRadius: 150.0,
        );

        // Assert
        expect(result.isSuccessful, isTrue);
        expect(result.geofenceRadius, equals(150.0));
      });
    });

    group('Check-Out Location Verification', () {
      test('should verify valid check-out location', () async {
        // Arrange
        final jobSite = _createTestJobSite();

        // Act
        final result = await service.verifyCheckOutLocation(jobSite: jobSite);

        // Assert
        expect(result.isSuccessful, isTrue);
        expect(result.targetLocation, equals(jobSite));
        expect(result.verificationType, equals(LocationVerificationType.checkOut));
      });
    });

    group('Location Monitoring', () {
      test('should start location monitoring', () async {
        // Arrange
        final jobSite = _createTestJobSite();

        // Act & Assert - Should not throw
        await service.startLocationMonitoring(
          shiftId: 'test_shift_123',
          jobSite: jobSite,
        );
      });

      test('should stop location monitoring', () async {
        // Act & Assert - Should not throw
        await service.stopLocationMonitoring();
      });
    });

    group('Multiple Geofences', () {
      test('should check multiple geofences', () async {
        // Arrange
        final locations = [
          _createTestJobSite(),
          ShiftLocation(
            address: 'Another Address 456',
            city: 'Rotterdam',
            postalCode: '2000AB',
            latitude: 51.9244,
            longitude: 4.4777,
            geofenceRadius: 200.0,
            locationNotes: 'Second location',
            landmarks: [],
          ),
        ];

        // Act
        final results = await service.checkMultipleGeofences(locations: locations);

        // Assert
        expect(results, isNotEmpty);
        expect(results.length, equals(locations.length));
      });
    });

    group('Location History', () {
      test('should get location history for shift', () async {
        // Arrange
        final shiftId = 'test_shift_123';

        // Act
        final history = await service.getLocationHistory(shiftId: shiftId);

        // Assert - Should not throw and return list
        expect(history, isA<List<LocationVerificationResult>>());
      });

      test('should get location history with time range', () async {
        // Arrange
        final shiftId = 'test_shift_123';
        final startTime = DateTime.now().subtract(Duration(hours: 8));
        final endTime = DateTime.now();

        // Act
        final history = await service.getLocationHistory(
          shiftId: shiftId,
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(history, isA<List<LocationVerificationResult>>());
      });
    });

    group('Anti-Spoofing Statistics', () {
      test('should get anti-spoofing stats', () async {
        // Act
        final stats = await service.getAntiSpoofingStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalVerifications'), isTrue);
        expect(stats.containsKey('mockDetections'), isTrue);
        expect(stats.containsKey('spoofingAttempts'), isTrue);
      });
    });
  });
}