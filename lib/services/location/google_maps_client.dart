import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/location/postcode_models.dart';

/// Google Maps API client for Dutch postcode operations
/// 
/// Provides secure integration with Google Maps APIs for geocoding,
/// distance calculation, and route planning. Implements rate limiting,
/// circuit breaker pattern, and cost optimization for production use.
class GoogleMapsClient {
  GoogleMapsClient._();
  
  static final GoogleMapsClient _instance = GoogleMapsClient._();
  static GoogleMapsClient get instance => _instance;

  // API configuration
  static const String _geocodingApiUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const String _distanceMatrixApiUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json';
  static const String _directionsApiUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  // API key management (should be loaded from secure configuration)
  static String? _apiKey;
  
  // Rate limiting
  static DateTime _lastRequest = DateTime.now();
  static const int _minRequestIntervalMs = 100; // 10 requests per second max
  static int _requestCount = 0;
  static DateTime _requestCountReset = DateTime.now();
  static const int _maxRequestsPerMinute = 50; // Conservative limit

  // Circuit breaker pattern
  static int _failureCount = 0;
  static DateTime? _circuitBreakerOpenUntil;
  static const int _maxFailures = 5;
  static const int _circuitBreakerTimeoutMinutes = 5;

  // Service health monitoring
  static ServiceStatus _serviceStatus = ServiceStatus.active;
  static String? _lastErrorMessage;
  static DateTime _lastHealthCheck = DateTime.now();

  /// Initialize Google Maps client with API key
  static void initialize(String apiKey) {
    _apiKey = apiKey;
    debugPrint('GoogleMapsClient: Initialized with API key');
  }

  /// Check if client is initialized
  static bool get isInitialized => _apiKey != null && _apiKey!.isNotEmpty;

  /// Get current service status
  static ServiceStatus get serviceStatus => _serviceStatus;

  /// Get last error message
  static String? get lastError => _lastErrorMessage;

  // =========================================================================
  // GEOCODING API
  // =========================================================================

  /// Get coordinates for Dutch postcode using Google Geocoding API
  static Future<PostcodeCoordinate?> geocodePostcode(String postcode) async {
    if (!isInitialized) {
      throw ApiException('Google Maps API key not initialized', 'GoogleMapsClient');
    }

    await _checkRateLimit();
    await _checkCircuitBreaker();

    try {
      final startTime = DateTime.now();
      
      // Build request URL
      final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();
      final formattedPostcode = '${cleanPostcode.substring(0, 4)} ${cleanPostcode.substring(4)}';
      
      final uri = Uri.parse(_geocodingApiUrl).replace(queryParameters: {
        'address': '$formattedPostcode, Netherlands',
        'region': 'nl',
        'key': _apiKey!,
      });

      // Make API request
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Geocoding request timed out', const Duration(seconds: 10)),
      );

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List<dynamic>;
          if (results.isNotEmpty) {
            final result = results.first as Map<String, dynamic>;
            final geometry = result['geometry'] as Map<String, dynamic>;
            final location = geometry['location'] as Map<String, dynamic>;
            
            // Extract address components
            String? city;
            String? province;
            
            final addressComponents = result['address_components'] as List<dynamic>?;
            if (addressComponents != null) {
              for (final component in addressComponents) {
                final types = component['types'] as List<dynamic>;
                if (types.contains('locality')) {
                  city = component['long_name'] as String;
                } else if (types.contains('administrative_area_level_1')) {
                  province = component['long_name'] as String;
                }
              }
            }

            _recordSuccess(responseTime);
            
            return PostcodeCoordinate(
              postcode: cleanPostcode,
              latitude: (location['lat'] as num).toDouble(),
              longitude: (location['lng'] as num).toDouble(),
              city: city,
              province: province,
              cachedAt: DateTime.now(),
              source: 'google_maps',
            );
          }
        }
        
        // Handle API errors
        final status = data['status'] as String;
        final errorMessage = data['error_message'] as String? ?? 'Unknown geocoding error';
        
        if (status == 'ZERO_RESULTS') {
          return null; // Valid response but no results
        }
        
        throw ApiException(
          'Geocoding failed: $status - $errorMessage',
          'GoogleMapsGeocoding',
          response.statusCode,
          response.body,
        );
      } else {
        _recordFailure('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        throw ApiException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'GoogleMapsGeocoding',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      _recordFailure(e.toString());
      throw ApiException(
        'Geocoding request failed: $e',
        'GoogleMapsGeocoding',
      );
    }
  }

  // =========================================================================
  // DISTANCE MATRIX API
  // =========================================================================

  /// Calculate travel details between postcodes using Distance Matrix API
  static Future<TravelDetails?> calculateTravelDetails(
    String fromPostcode,
    String toPostcode,
    TransportMode mode,
  ) async {
    if (!isInitialized) {
      throw ApiException('Google Maps API key not initialized', 'GoogleMapsClient');
    }

    await _checkRateLimit();
    await _checkCircuitBreaker();

    try {
      final startTime = DateTime.now();
      
      // Format postcodes
      final fromFormatted = _formatPostcodeForAPI(fromPostcode);
      final toFormatted = _formatPostcodeForAPI(toPostcode);
      
      // Build request URL
      final uri = Uri.parse(_distanceMatrixApiUrl).replace(queryParameters: {
        'origins': '$fromFormatted, Netherlands',
        'destinations': '$toFormatted, Netherlands',
        'mode': mode.apiValue,
        'language': 'nl',
        'units': 'metric',
        'key': _apiKey!,
      });

      // Make API request
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Distance Matrix request timed out', const Duration(seconds: 15)),
      );

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK') {
          final rows = data['rows'] as List<dynamic>;
          if (rows.isNotEmpty) {
            final row = rows.first as Map<String, dynamic>;
            final elements = row['elements'] as List<dynamic>;
            if (elements.isNotEmpty) {
              final element = elements.first as Map<String, dynamic>;
              
              if (element['status'] == 'OK') {
                final distance = element['distance'] as Map<String, dynamic>;
                final duration = element['duration'] as Map<String, dynamic>;
                
                _recordSuccess(responseTime);
                
                return TravelDetails(
                  fromPostcode: fromPostcode,
                  toPostcode: toPostcode,
                  distanceKm: (distance['value'] as int) / 1000.0,
                  duration: Duration(seconds: duration['value'] as int),
                  mode: mode,
                  routeDescription: distance['text'] as String,
                  calculatedAt: DateTime.now(),
                  source: 'google_maps',
                );
              }
            }
          }
        }
        
        // Handle API errors
        final status = data['status'] as String;
        final errorMessage = data['error_message'] as String? ?? 'Unknown distance calculation error';
        
        throw ApiException(
          'Distance calculation failed: $status - $errorMessage',
          'GoogleMapsDistanceMatrix',
          response.statusCode,
          response.body,
        );
      } else {
        _recordFailure('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        throw ApiException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'GoogleMapsDistanceMatrix',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      _recordFailure(e.toString());
      throw ApiException(
        'Distance calculation request failed: $e',
        'GoogleMapsDistanceMatrix',
      );
    }
  }

  /// Calculate multiple travel options at once (batch processing)
  static Future<Map<TransportMode, TravelDetails>> calculateMultipleTransportModes(
    String fromPostcode,
    String toPostcode,
    List<TransportMode> modes,
  ) async {
    final results = <TransportMode, TravelDetails>{};
    
    // Process modes sequentially to respect rate limits
    for (final mode in modes) {
      try {
        final travelDetails = await calculateTravelDetails(fromPostcode, toPostcode, mode);
        if (travelDetails != null) {
          results[mode] = travelDetails;
        }
      } catch (e) {
        debugPrint('GoogleMapsClient: Failed to calculate travel for mode ${mode.displayName}: $e');
        // Continue with other modes
      }
    }
    
    return results;
  }

  // =========================================================================
  // DIRECTIONS API (for detailed route instructions)
  // =========================================================================

  /// Get detailed directions between postcodes
  static Future<TravelDetails?> getDetailedDirections(
    String fromPostcode,
    String toPostcode,
    TransportMode mode,
  ) async {
    if (!isInitialized) {
      throw ApiException('Google Maps API key not initialized', 'GoogleMapsClient');
    }

    await _checkRateLimit();
    await _checkCircuitBreaker();

    try {
      final startTime = DateTime.now();
      
      // Format postcodes
      final fromFormatted = _formatPostcodeForAPI(fromPostcode);
      final toFormatted = _formatPostcodeForAPI(toPostcode);
      
      // Build request URL
      final uri = Uri.parse(_directionsApiUrl).replace(queryParameters: {
        'origin': '$fromFormatted, Netherlands',
        'destination': '$toFormatted, Netherlands',
        'mode': mode.apiValue,
        'language': 'nl',
        'units': 'metric',
        'key': _apiKey!,
      });

      // Make API request
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Directions request timed out', const Duration(seconds: 15)),
      );

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK') {
          final routes = data['routes'] as List<dynamic>;
          if (routes.isNotEmpty) {
            final route = routes.first as Map<String, dynamic>;
            final legs = route['legs'] as List<dynamic>;
            if (legs.isNotEmpty) {
              final leg = legs.first as Map<String, dynamic>;
              
              final distance = leg['distance'] as Map<String, dynamic>;
              final duration = leg['duration'] as Map<String, dynamic>;
              
              // Extract step-by-step instructions
              final steps = leg['steps'] as List<dynamic>;
              final instructions = steps.map((step) {
                final instruction = step['html_instructions'] as String;
                // Remove HTML tags for simple text instructions
                return instruction.replaceAll(RegExp(r'<[^>]*>'), '');
              }).toList();
              
              _recordSuccess(responseTime);
              
              return TravelDetails(
                fromPostcode: fromPostcode,
                toPostcode: toPostcode,
                distanceKm: (distance['value'] as int) / 1000.0,
                duration: Duration(seconds: duration['value'] as int),
                mode: mode,
                routeDescription: '${distance['text']} via ${route['summary'] ?? 'hoofdroute'}',
                instructions: instructions,
                calculatedAt: DateTime.now(),
                source: 'google_maps_directions',
              );
            }
          }
        }
        
        // Handle API errors
        final status = data['status'] as String;
        final errorMessage = data['error_message'] as String? ?? 'Unknown directions error';
        
        throw ApiException(
          'Directions request failed: $status - $errorMessage',
          'GoogleMapsDirections',
          response.statusCode,
          response.body,
        );
      } else {
        _recordFailure('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        throw ApiException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'GoogleMapsDirections',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      _recordFailure(e.toString());
      throw ApiException(
        'Directions request failed: $e',
        'GoogleMapsDirections',
      );
    }
  }

  // =========================================================================
  // FALLBACK METHODS (when API is unavailable)
  // =========================================================================

  /// Calculate straight-line distance using Haversine formula (fallback)
  static double calculateHaversineDistance(
    PostcodeCoordinate from,
    PostcodeCoordinate to,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final lat1Rad = from.latitude * (pi / 180);
    final lon1Rad = from.longitude * (pi / 180);
    final lat2Rad = to.latitude * (pi / 180);
    final lon2Rad = to.longitude * (pi / 180);
    
    final dLat = lat2Rad - lat1Rad;
    final dLon = lon2Rad - lon1Rad;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Generate fallback travel details using Haversine distance
  static TravelDetails generateFallbackTravelDetails(
    String fromPostcode,
    String toPostcode,
    PostcodeCoordinate fromCoord,
    PostcodeCoordinate toCoord,
    TransportMode mode,
  ) {
    final straightLineDistance = calculateHaversineDistance(fromCoord, toCoord);
    
    // Estimate actual travel distance and time based on mode
    double distanceMultiplier;
    double speedKmh;
    
    switch (mode) {
      case TransportMode.driving:
        distanceMultiplier = 1.3; // Roads add ~30% to straight-line distance
        speedKmh = 50; // Average speed in Netherlands
        break;
      case TransportMode.bicycling:
        distanceMultiplier = 1.2;
        speedKmh = 20;
        break;
      case TransportMode.walking:
        distanceMultiplier = 1.15;
        speedKmh = 5;
        break;
      case TransportMode.transit:
        distanceMultiplier = 1.5; // Public transport routes are less direct
        speedKmh = 30; // Including waiting times
        break;
    }
    
    final estimatedDistance = straightLineDistance * distanceMultiplier;
    final estimatedDuration = Duration(
      minutes: ((estimatedDistance / speedKmh) * 60).round(),
    );
    
    return TravelDetails(
      fromPostcode: fromPostcode,
      toPostcode: toPostcode,
      distanceKm: estimatedDistance,
      duration: estimatedDuration,
      mode: mode,
      routeDescription: 'Geschatte route (${estimatedDistance.toStringAsFixed(1)}km)',
      calculatedAt: DateTime.now(),
      source: 'fallback_estimate',
    );
  }

  // =========================================================================
  // SERVICE HEALTH AND MONITORING
  // =========================================================================

  /// Get service health information
  static Future<ServiceHealth> getServiceHealth() async {
    final startTime = DateTime.now();
    
    try {
      // Test with a simple geocoding request
      await geocodePostcode('1012AB'); // Amsterdam center
      
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      _serviceStatus = ServiceStatus.active;
      _lastHealthCheck = DateTime.now();
      
      return ServiceHealth(
        status: ServiceStatus.active,
        service: 'GoogleMapsAPI',
        responseTimeMs: responseTime,
        checkedAt: _lastHealthCheck,
      );
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      _serviceStatus = ServiceStatus.down;
      _lastErrorMessage = e.toString();
      _lastHealthCheck = DateTime.now();
      
      return ServiceHealth(
        status: ServiceStatus.down,
        service: 'GoogleMapsAPI',
        responseTimeMs: responseTime,
        errorMessage: e.toString(),
        checkedAt: _lastHealthCheck,
      );
    }
  }

  /// Get API usage statistics
  static Map<String, dynamic> getUsageStatistics() {
    return {
      'requestCount': _requestCount,
      'failureCount': _failureCount,
      'serviceStatus': _serviceStatus.displayName,
      'lastError': _lastErrorMessage,
      'circuitBreakerOpen': _circuitBreakerOpenUntil != null && 
                            DateTime.now().isBefore(_circuitBreakerOpenUntil!),
      'lastHealthCheck': _lastHealthCheck.toIso8601String(),
    };
  }

  // =========================================================================
  // PRIVATE HELPER METHODS
  // =========================================================================

  /// Format postcode for API requests
  static String _formatPostcodeForAPI(String postcode) {
    final cleaned = postcode.replaceAll(' ', '').toUpperCase();
    return '${cleaned.substring(0, 4)} ${cleaned.substring(4)}';
  }

  /// Check and enforce rate limiting
  static Future<void> _checkRateLimit() async {
    final now = DateTime.now();
    
    // Reset request count every minute
    if (now.difference(_requestCountReset).inMinutes >= 1) {
      _requestCount = 0;
      _requestCountReset = now;
    }
    
    // Check per-minute limit
    if (_requestCount >= _maxRequestsPerMinute) {
      final waitTime = 60 - now.difference(_requestCountReset).inSeconds;
      debugPrint('GoogleMapsClient: Rate limit reached, waiting ${waitTime}s');
      await Future.delayed(Duration(seconds: waitTime));
      _requestCount = 0;
      _requestCountReset = DateTime.now();
    }
    
    // Check minimum interval between requests
    final timeSinceLastRequest = now.difference(_lastRequest).inMilliseconds;
    if (timeSinceLastRequest < _minRequestIntervalMs) {
      await Future.delayed(Duration(milliseconds: _minRequestIntervalMs - timeSinceLastRequest));
    }
    
    _lastRequest = DateTime.now();
    _requestCount++;
  }

  /// Check circuit breaker status
  static Future<void> _checkCircuitBreaker() async {
    if (_circuitBreakerOpenUntil != null) {
      if (DateTime.now().isAfter(_circuitBreakerOpenUntil!)) {
        // Reset circuit breaker
        _circuitBreakerOpenUntil = null;
        _failureCount = 0;
        _serviceStatus = ServiceStatus.active;
        debugPrint('GoogleMapsClient: Circuit breaker reset');
      } else {
        throw ApiException(
          'Service temporarily unavailable (circuit breaker open)',
          'GoogleMapsClient',
        );
      }
    }
  }

  /// Record successful API call
  static void _recordSuccess(int responseTime) {
    _failureCount = 0;
    _serviceStatus = responseTime > 5000 ? ServiceStatus.degraded : ServiceStatus.active;
    _lastErrorMessage = null;
  }

  /// Record failed API call
  static void _recordFailure(String error) {
    _failureCount++;
    _lastErrorMessage = error;
    
    if (_failureCount >= _maxFailures) {
      _circuitBreakerOpenUntil = DateTime.now().add(
        Duration(minutes: _circuitBreakerTimeoutMinutes),
      );
      _serviceStatus = ServiceStatus.down;
      debugPrint('GoogleMapsClient: Circuit breaker opened due to $_failureCount failures');
    } else {
      _serviceStatus = ServiceStatus.degraded;
    }
  }
}