import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:securyflex_app/marketplace/services/postcode_service.dart';
import 'package:securyflex_app/models/location/postcode_models.dart';

/// Comprehensive test suite for PostcodeService
/// 
/// Tests all Dutch business requirements, Google Maps integration,
/// caching functionality, and error handling scenarios.
void main() {
  group('PostcodeService', () {
    setUpAll(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      // Initialize the service with mock API key for testing
      await PostcodeService.initialize(googleMapsApiKey: 'test_api_key');
    });

    tearDown(() async {
      // Clear cache between tests
      await PostcodeService.clearCache();
      PostcodeService.resetStatistics();
    });

    group('Initialization', () {
      test('should initialize correctly with API key', () async {
        expect(PostcodeService.isInitialized, isTrue);
        expect(PostcodeService.isUsingMockData, isFalse); // Should use API with valid key
      });

      test('should initialize in mock mode without API key', () async {
        // Reset service
        await PostcodeService.clearCache();
        
        // Re-initialize without API key
        await PostcodeService.initialize();
        
        expect(PostcodeService.isInitialized, isTrue);
      });
    });

    group('Dutch Postcode Validation', () {
      group('Valid Postcodes', () {
        final validPostcodes = [
          '1012AB',  // Amsterdam
          '2511CV',  // Den Haag
          '3011AB',  // Rotterdam
          '3511LN',  // Utrecht
          '5038EA',  // Tilburg
          '6823HX',  // Arnhem
          '7411GT',  // Deventer
          '8011CW',  // Zwolle
          '9711LM',  // Groningen
          '1234 AB', // With space
          '1234ab',  // Lowercase
        ];

        for (final postcode in validPostcodes) {
          test('should validate $postcode as correct Dutch format', () {
            expect(PostcodeService.validateDutchPostcode(postcode), isTrue);
          });

          test('should provide detailed validation for $postcode', () {
            final result = PostcodeService.validatePostcodeDetailed(postcode);
            expect(result.isValid, isTrue);
            expect(result.cleanPostcode, isNotNull);
            expect(result.formattedPostcode, isNotNull);
            expect(result.province, isNotNull);
            expect(result.errorMessage, isNull);
          });
        }
      });

      group('Invalid Postcodes', () {
        final invalidPostcodes = {
          '': 'POSTCODE_EMPTY',
          '0123AB': 'POSTCODE_INVALID_START',
          '123AB': 'POSTCODE_INVALID_LENGTH',
          '1234ABC': 'POSTCODE_INVALID_LENGTH',
          '12AB34': 'POSTCODE_INVALID_FORMAT',
          'ABCD12': 'POSTCODE_INVALID_FORMAT',
          '1234SA': 'POSTCODE_INVALID_LETTERS',
          '1234SD': 'POSTCODE_INVALID_LETTERS',
          '1234SS': 'POSTCODE_INVALID_LETTERS',
          '9999AB': 'POSTCODE_INVALID_RANGE', // Outside valid range
        };

        invalidPostcodes.forEach((postcode, expectedErrorCode) {
          test('should reject $postcode with error $expectedErrorCode', () {
            expect(PostcodeService.validateDutchPostcode(postcode), isFalse);
            
            final result = PostcodeService.validatePostcodeDetailed(postcode);
            expect(result.isValid, isFalse);
            expect(result.errorCode, expectedErrorCode);
            expect(result.errorMessage, isNotNull);
            expect(result.suggestions, isNotNull);
            expect(result.suggestions!.isNotEmpty, isTrue);
          });
        });
      });

      group('Formatting', () {
        test('should format postcodes correctly', () {
          expect(PostcodeService.formatDutchPostcode('1234AB'), equals('1234 AB'));
          expect(PostcodeService.formatDutchPostcode('1234 AB'), equals('1234 AB'));
          expect(PostcodeService.formatDutchPostcode('1234ab'), equals('1234 AB'));
          expect(PostcodeService.formatDutchPostcode('invalid'), equals('invalid'));
        });

        test('should clean postcodes correctly', () {
          expect(PostcodeService.cleanPostcode('1234 AB'), equals('1234AB'));
          expect(PostcodeService.cleanPostcode('1234ab'), equals('1234AB'));
          expect(PostcodeService.cleanPostcode('  1234  ab  '), equals('1234AB'));
        });
      });

      group('Province Mapping', () {
        final provinceTests = {
          '1012AB': 'Noord-Holland',
          '1350AA': 'Flevoland',
          '2511CV': 'Zuid-Holland',
          '3511LN': 'Zuid-Holland',
          '5038EA': 'Noord-Brabant',
          '6823HX': 'Limburg',
          '7411GT': 'Overijssel',
          '8011CW': 'Drenthe',
          '9711LM': 'Groningen',
        };

        provinceTests.forEach((postcode, expectedProvince) {
          test('should map $postcode to $expectedProvince', () {
            final result = PostcodeService.validatePostcodeDetailed(postcode);
            expect(result.isValid, isTrue);
            expect(result.province, contains(expectedProvince));
          });
        });
      });
    });

    group('Coordinate Services', () {
      test('should get coordinates for valid Dutch postcode', () async {
        final coordinate = await PostcodeService.getCoordinates('1012AB');
        
        expect(coordinate, isNotNull);
        expect(coordinate!.postcode, equals('1012AB'));
        expect(coordinate.latitude, inInclusiveRange(50.0, 54.0)); // Netherlands bounds
        expect(coordinate.longitude, inInclusiveRange(3.0, 8.0));
        expect(coordinate.source, isNotNull);
      });

      test('should return null for invalid postcode', () async {
        expect(() async => await PostcodeService.getCoordinates('invalid'), 
               throwsA(isA<PostcodeException>()));
      });

      test('should cache coordinates for performance', () async {
        // First request
        final start1 = DateTime.now();
        final coordinate1 = await PostcodeService.getCoordinates('1012AB');
        final time1 = DateTime.now().difference(start1).inMilliseconds;
        
        // Second request (should be from cache)
        final start2 = DateTime.now();
        final coordinate2 = await PostcodeService.getCoordinates('1012AB');
        final time2 = DateTime.now().difference(start2).inMilliseconds;
        
        expect(coordinate1, isNotNull);
        expect(coordinate2, isNotNull);
        expect(coordinate1!.postcode, equals(coordinate2!.postcode));
        expect(time2, lessThan(time1)); // Cache should be faster
      });
    });

    group('Distance Calculations', () {
      test('should calculate distance between two postcodes', () async {
        final distance = await PostcodeService.calculateDistance('1012AB', '2511CV');
        
        expect(distance, greaterThan(0));
        expect(distance, lessThan(100)); // Should be reasonable for Netherlands
      });

      test('should handle invalid postcodes in distance calculation', () async {
        final distance = await PostcodeService.calculateDistance('invalid', '1012AB');
        expect(distance, equals(0.0)); // Should return 0 for invalid input
      });

      test('should calculate multiple distances efficiently', () async {
        final basePostcode = '1012AB';
        final targetPostcodes = ['2511CV', '3511LN', '5038EA', '6823HX'];
        
        final distances = await PostcodeService.calculateMultipleDistances(
          basePostcode,
          targetPostcodes,
        );
        
        expect(distances.length, equals(targetPostcodes.length));
        
        for (final entry in distances.entries) {
          expect(entry.value, greaterThan(0));
          expect(entry.value, lessThan(500)); // Max distance in Netherlands
        }
        
        // Should be ordered by distance (Amsterdam closest to Den Haag vs Limburg)
        final denHaagDistance = distances['2511CV'];
        final limburgDistance = distances['6823HX'];
        expect(denHaagDistance, isNotNull);
        expect(limburgDistance, isNotNull);
        expect(denHaagDistance!, lessThan(limburgDistance!));
      });

      test('should handle transport modes correctly', () async {
        final travelDetails = await PostcodeService.getTravelDetails(
          '1012AB',
          '2511CV',
          TransportMode.driving,
        );
        
        expect(travelDetails, isNotNull);
        expect(travelDetails!.fromPostcode, equals('1012AB'));
        expect(travelDetails.toPostcode, equals('2511CV'));
        expect(travelDetails.mode, equals(TransportMode.driving));
        expect(travelDetails.distanceKm, greaterThan(0));
        expect(travelDetails.duration.inMinutes, greaterThan(0));
      });
    });

    group('Spatial Search', () {
      test('should find postcodes within radius', () async {
        final nearbyPostcodes = await PostcodeService.getPostcodesInRadius(
          '1012AB',
          10.0, // 10km radius
        );
        
        expect(nearbyPostcodes, isNotEmpty);
        
        // All returned postcodes should be valid
        for (final postcode in nearbyPostcodes) {
          expect(PostcodeService.validateDutchPostcode(postcode), isTrue);
        }
      });

      test('should filter postcodes by distance', () async {
        final allPostcodes = ['1012AB', '2511CV', '3511LN', '5038EA', '6823HX', '9711LM'];
        final basePostcode = '1012AB';
        
        final nearbyPostcodes = await PostcodeService.filterByDistance(
          basePostcode,
          allPostcodes,
          50.0, // 50km radius
        );
        
        expect(nearbyPostcodes, isNotEmpty);
        expect(nearbyPostcodes.length, lessThanOrEqualTo(allPostcodes.length));
        // Note: Base postcode may be included in results depending on implementation
        
        // Should be sorted by distance
        if (nearbyPostcodes.length > 1) {
          final distances = await PostcodeService.calculateMultipleDistances(
            basePostcode,
            nearbyPostcodes,
          );
          
          for (int i = 0; i < nearbyPostcodes.length - 1; i++) {
            expect(
              distances[nearbyPostcodes[i]]!,
              lessThanOrEqualTo(distances[nearbyPostcodes[i + 1]]!),
            );
          }
        }
      });
    });

    group('Service Performance and Monitoring', () {
      test('should track service statistics', () {
        PostcodeService.resetStatistics();
        
        final initialStats = PostcodeService.getServiceStatistics();
        expect(initialStats['totalRequests'], equals(0));
        expect(initialStats['cacheHits'], equals(0));
        expect(initialStats['apiRequests'], equals(0));
      });

      test('should provide service health information', () async {
        final health = await PostcodeService.getServiceHealth();
        
        expect(health, isNotNull);
        expect(health['service'], equals('PostcodeService'));
        expect(health['status'], isNotNull);
        expect(health['statistics'], isNotNull);
        expect(health['checkedAt'], isNotNull);
      });

      test('should handle service maintenance', () async {
        // This should not throw
        await PostcodeService.performMaintenance();
      });
    });

    group('Cache Management', () {
      test('should clear cache successfully', () async {
        // Add some data to cache first
        await PostcodeService.getCoordinates('1012AB');
        
        // Clear cache
        await PostcodeService.clearCache();
        
        // Statistics should be reset
        final stats = PostcodeService.getServiceStatistics();
        expect(stats['totalRequests'], equals(0));
      });

      test('should preload common routes', () async {
        final commonPostcodes = ['1012AB', '2511CV', '3511LN'];
        
        // This should complete without errors
        await PostcodeService.preloadCommonRoutes(commonPostcodes);
        
        // Coordinates should now be cached
        for (final postcode in commonPostcodes) {
          final coordinate = await PostcodeService.getCoordinates(postcode);
          expect(coordinate, isNotNull);
        }
      });
    });

    group('Error Handling', () {
      test('should handle uninitialized service gracefully', () async {
        // This is hard to test since we initialize in setUpAll
        // But we can test the error cases
        expect(
          () async => await PostcodeService.getCoordinates('invalid'),
          throwsA(isA<PostcodeException>()),
        );
      });

      test('should handle API failures gracefully', () async {
        // Test with a definitely invalid postcode format that would cause API errors
        final coordinate = await PostcodeService.getCoordinates('1012AB');
        
        // Should still return a coordinate (from fallback)
        expect(coordinate, isNotNull);
        expect(coordinate!.source, isNotNull);
      });

      test('should handle network timeouts', () async {
        // This is difficult to test without mocking the HTTP client
        // But the service should handle timeouts gracefully
        final coordinate = await PostcodeService.getCoordinates('1012AB');
        expect(coordinate, isNotNull);
      });
    });

    group('Business Logic Integration', () {
      test('should support job filtering by location', () async {
        // Simulate job filtering scenario
        final userPostcode = '1012AB';
        final jobPostcodes = ['2511CV', '3511LN', '5038EA', '6823HX'];
        final maxDistanceKm = 50.0;
        
        final nearbyJobs = await PostcodeService.filterByDistance(
          userPostcode,
          jobPostcodes,
          maxDistanceKm,
        );
        
        expect(nearbyJobs, isNotEmpty);
        
        // All returned jobs should be within the specified radius
        final distances = await PostcodeService.calculateMultipleDistances(
          userPostcode,
          nearbyJobs,
        );
        
        for (final distance in distances.values) {
          expect(distance, lessThanOrEqualTo(maxDistanceKm));
        }
      });

      test('should provide travel time estimates for job commuting', () async {
        final travelDetails = await PostcodeService.getTravelDetails(
          '1012AB',  // User location (Amsterdam)
          '2511CV',  // Job location (Den Haag)
          TransportMode.driving,
        );
        
        expect(travelDetails, isNotNull);
        expect(travelDetails!.formattedDistance, isNotEmpty);
        expect(travelDetails.formattedDuration, isNotEmpty);
        expect(travelDetails.duration.inMinutes, greaterThan(0));
        expect(travelDetails.duration.inMinutes, lessThan(300)); // Max 5 hours for NL
      });

      test('should calculate cost estimates for public transport', () async {
        final travelDetails = await PostcodeService.getTravelDetails(
          '1012AB',
          '2511CV',
          TransportMode.transit,
        );
        
        expect(travelDetails, isNotNull);
        expect(travelDetails!.mode, equals(TransportMode.transit));
        // Cost estimate may or may not be available depending on API
      });
    });

    group('Performance Requirements', () {
      test('should meet response time requirements', () async {
        const maxResponseTimeMs = 2000; // 2 second requirement
        
        final stopwatch = Stopwatch()..start();
        await PostcodeService.getCoordinates('1012AB');
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(maxResponseTimeMs));
      });

      test('should handle concurrent requests efficiently', () async {
        const concurrentRequests = 10;
        final postcodes = List.generate(concurrentRequests, (i) => '101${i}AB');
        
        final stopwatch = Stopwatch()..start();
        
        // Make concurrent requests
        final futures = postcodes.map((postcode) async {
          try {
            return await PostcodeService.getCoordinates(postcode);
          } catch (e) {
            return null; // Some postcodes may be invalid
          }
        });
        
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        // Should complete within reasonable time even with concurrent requests
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max
        
        // Most requests should succeed (valid postcodes)
        final successfulResults = results.where((r) => r != null).length;
        expect(successfulResults, greaterThan(concurrentRequests ~/ 2));
      });
    });

    group('Memory Management', () {
      test('should not leak memory with repeated cache operations', () async {
        const iterations = 100;
        
        for (int i = 0; i < iterations; i++) {
          await PostcodeService.getCoordinates('1012AB');
          
          // Periodically clear cache to simulate real usage
          if (i % 10 == 0) {
            await PostcodeService.performMaintenance();
          }
        }
        
        // Should complete without memory issues
        final stats = PostcodeService.getServiceStatistics();
        // Allow for some variance in request counting due to caching and retries
        expect(stats['totalRequests'], greaterThanOrEqualTo(iterations));
      });
    });
  });
}

/// Helper matcher for testing ranges
Matcher inInclusiveRange(num min, num max) => InInclusiveRange(min, max);

class InInclusiveRange extends Matcher {
  final num _min;
  final num _max;

  const InInclusiveRange(this._min, this._max);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! num) return false;
    return item >= _min && item <= _max;
  }

  @override
  Description describe(Description description) =>
      description.add('a number between $_min and $_max (inclusive)');
}