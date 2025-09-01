import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/location/postcode_models.dart';
import '../../services/location/location_cache.dart';
import '../../services/location/google_maps_client.dart';

/// Comprehensive Dutch PostcodeService for SecuryFlex security marketplace
/// 
/// Provides production-ready Nederlandse postcode validation, distance calculation,
/// and location services with Google Maps integration, advanced caching,
/// and business intelligence features for the Dutch security job market.
/// 
/// Features:
/// - Strict Dutch postcode validation (1234AB format)
/// - Multi-tier distance calculation (Google Maps + Haversine fallback)
/// - Advanced caching with 24-hour TTL
/// - Rate limiting and API management
/// - Spatial search and location filtering
/// - Business intelligence for job matching
class PostcodeService {
  PostcodeService._();
  
  static final PostcodeService _instance = PostcodeService._();
  static PostcodeService get instance => _instance;
  
  // Configuration
  static bool _isInitialized = false;
  static bool _useMockData = kDebugMode; // Use mock data in debug mode
  
  // Performance monitoring
  static int _totalRequests = 0;
  static int _apiRequests = 0;
  static int _cacheHits = 0;
  static DateTime _lastStatsReset = DateTime.now();
  
  /// Initialize PostcodeService with Google Maps API key
  static Future<void> initialize({String? googleMapsApiKey}) async {
    if (_isInitialized) return;
    
    try {
      // Initialize cache system
      await LocationCache.initialize();
      
      // Initialize Google Maps client if API key provided
      if (googleMapsApiKey != null && googleMapsApiKey.isNotEmpty) {
        GoogleMapsClient.initialize(googleMapsApiKey);
        _useMockData = false;
        debugPrint('PostcodeService: Initialized with Google Maps API');
      } else {
        _useMockData = true;
        debugPrint('PostcodeService: Initialized in mock mode (no API key)');
      }
      
      _isInitialized = true;
      debugPrint('PostcodeService: Initialization completed successfully');
    } catch (e) {
      debugPrint('PostcodeService: Initialization error: $e');
      _useMockData = true; // Fallback to mock mode
    }
  }
  
  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;
  
  /// Check if using mock data
  static bool get isUsingMockData => _useMockData;
  
  // =========================================================================
  // DUTCH POSTCODE VALIDATION
  // =========================================================================
  
  /// Validates Nederlandse postcode format (1234AB) with comprehensive checks
  /// Returns true if postcode follows correct Dutch format
  static bool validateDutchPostcode(String postcode) {
    final result = validatePostcodeDetailed(postcode);
    return result.isValid;
  }
  
  /// Legacy method name for backward compatibility
  static bool isValidDutchPostcode(String postcode) {
    return validateDutchPostcode(postcode);
  }
  
  /// Validate postcode format with detailed error messages and suggestions
  static PostcodeValidationResult validatePostcodeDetailed(String postcode) {
    _totalRequests++;
    
    if (postcode.isEmpty) {
      return PostcodeValidationResult.invalid(
        errorMessage: 'Postcode is verplicht',
        errorCode: 'POSTCODE_EMPTY',
        suggestions: ['Voer een geldige Nederlandse postcode in (bijv. 1234AB)'],
      );
    }
    
    final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();
    
    // Length validation
    if (cleanPostcode.length != 6) {
      final suggestions = <String>[];
      if (cleanPostcode.length < 6) {
        suggestions.add('Postcode is te kort, gebruik formaat 1234AB');
      } else {
        suggestions.add('Postcode is te lang, gebruik formaat 1234AB');
      }
      
      return PostcodeValidationResult.invalid(
        errorMessage: 'Postcode moet 6 tekens bevatten (1234AB)',
        errorCode: 'POSTCODE_INVALID_LENGTH',
        suggestions: suggestions,
      );
    }
    
    // Format validation
    if (!RegExp(r'^[0-9]{4}[A-Z]{2}$').hasMatch(cleanPostcode)) {
      return PostcodeValidationResult.invalid(
        errorMessage: 'Postcode moet bestaan uit 4 cijfers en 2 letters (1234AB)',
        errorCode: 'POSTCODE_INVALID_FORMAT',
        suggestions: ['Gebruik het formaat 1234AB (4 cijfers gevolgd door 2 letters)'],
      );
    }
    
    // First digit cannot be 0
    if (cleanPostcode.startsWith('0')) {
      return PostcodeValidationResult.invalid(
        errorMessage: 'Postcode mag niet beginnen met 0',
        errorCode: 'POSTCODE_INVALID_START',
        suggestions: ['Nederlandse postcodes beginnen met cijfers 1-9'],
      );
    }
    
    // Number range validation (1000-9999)
    final numbers = int.parse(cleanPostcode.substring(0, 4));
    if (numbers < 1000 || numbers > 9999) {
      return PostcodeValidationResult.invalid(
        errorMessage: 'Postcode nummer moet tussen 1000 en 9999 zijn',
        errorCode: 'POSTCODE_INVALID_RANGE',
        suggestions: ['Nederlandse postcodes lopen van 1000AB tot 9999ZZ'],
      );
    }
    
    // Validate letter combinations (some are not used in Netherlands)
    final letters = cleanPostcode.substring(4);
    final invalidCombinations = ['SA', 'SD', 'SS', 'F0', 'G0', 'I0', 'O0', 'Q0', 'U0', 'Y0'];
    if (invalidCombinations.contains(letters)) {
      return PostcodeValidationResult.invalid(
        errorMessage: 'Ongeldige lettercombinatie in postcode',
        errorCode: 'POSTCODE_INVALID_LETTERS',
        suggestions: ['Lettercombinatie "$letters" wordt niet gebruikt in Nederlandse postcodes'],
      );
    }
    
    // Get province for valid postcode
    final province = DutchProvince.fromPostcodeNumber(numbers);
    
    return PostcodeValidationResult.valid(
      cleanPostcode: cleanPostcode,
      formattedPostcode: '${cleanPostcode.substring(0, 4)} ${cleanPostcode.substring(4)}',
      province: province?.displayName ?? 'Onbekend',
    );
  }
  
  /// Formats Nederlandse postcode to standard format (1234 AB)
  /// Returns formatted postcode or original if invalid
  static String formatDutchPostcode(String postcode) {
    final result = validatePostcodeDetailed(postcode);
    return result.isValid ? result.formattedPostcode! : postcode;
  }
  
  /// Cleans Nederlandse postcode by removing spaces and converting to uppercase
  /// Returns clean postcode (1234AB format)
  static String cleanPostcode(String postcode) {
    return postcode.replaceAll(' ', '').toUpperCase();
  }
  
  // =========================================================================
  // COORDINATE SERVICES
  // =========================================================================
  
  /// Get coordinates for a Dutch postcode
  /// Uses Google Maps API with intelligent caching and fallback
  static Future<PostcodeCoordinate?> getCoordinates(String postcode) async {
    if (!_isInitialized) {
      throw PostcodeException('PostcodeService not initialized. Call PostcodeService.initialize() first.');
    }
    
    _totalRequests++;
    
    // Validate postcode first
    final validation = validatePostcodeDetailed(postcode);
    if (!validation.isValid) {
      throw PostcodeException(validation.errorMessage!, validation.errorCode, postcode);
    }
    
    final cleanPostcode = validation.cleanPostcode!;
    
    try {
      // Check cache first
      final cached = await LocationCache.getPostcodeCoordinates(cleanPostcode);
      if (cached != null) {
        _cacheHits++;
        return cached;
      }
      
      // Try Google Maps API if available
      if (!_useMockData && GoogleMapsClient.isInitialized) {
        try {
          _apiRequests++;
          final coordinate = await GoogleMapsClient.geocodePostcode(cleanPostcode);
          
          if (coordinate != null) {
            // Cache the result
            await LocationCache.setPostcodeCoordinates(coordinate);
            return coordinate;
          }
        } catch (e) {
          debugPrint('PostcodeService: Google Maps API error, falling back: $e');
        }
      }
      
      // Fallback to mock coordinates
      final fallbackCoord = _generateApproximateCoordinates(cleanPostcode);
      await LocationCache.setPostcodeCoordinates(fallbackCoord);
      return fallbackCoord;
      
    } catch (e) {
      debugPrint('PostcodeService: Error getting coordinates for $postcode: $e');
      return null;
    }
  }
  
  /// Calculate straight-line distance between two postcodes in kilometers
  /// Fast calculation using Haversine formula
  static Future<double> calculateDistance(String fromPostcode, String toPostcode) async {
    try {
      final fromCoord = await getCoordinates(fromPostcode);
      final toCoord = await getCoordinates(toPostcode);
      
      if (fromCoord == null || toCoord == null) {
        throw DistanceCalculationException(
          'Could not get coordinates for postcodes',
          fromPostcode,
          toPostcode,
        );
      }
      
      return GoogleMapsClient.calculateHaversineDistance(fromCoord, toCoord);
    } catch (e) {
      debugPrint('PostcodeService: Error calculating distance: $e');
      return 0.0;
    }
  }
  
  /// Get comprehensive travel details between two postcodes
  /// Uses Google Maps API for accurate travel time and distance
  static Future<TravelDetails?> getTravelDetails(
    String fromPostcode,
    String toPostcode,
    TransportMode mode,
  ) async {
    if (!_isInitialized) {
      throw PostcodeException('PostcodeService not initialized');
    }
    
    _totalRequests++;
    
    try {
      // Check cache first
      final cached = await LocationCache.getTravelDetails(fromPostcode, toPostcode, mode);
      if (cached != null) {
        _cacheHits++;
        return cached;
      }
      
      // Try Google Maps API if available
      if (!_useMockData && GoogleMapsClient.isInitialized) {
        try {
          _apiRequests++;
          final travelDetails = await GoogleMapsClient.calculateTravelDetails(
            fromPostcode, toPostcode, mode,
          );
          
          if (travelDetails != null) {
            await LocationCache.setTravelDetails(travelDetails);
            return travelDetails;
          }
        } catch (e) {
          debugPrint('PostcodeService: Google Maps API error for travel details: $e');
        }
      }
      
      // Fallback to estimated travel details
      final fromCoord = await getCoordinates(fromPostcode);
      final toCoord = await getCoordinates(toPostcode);
      
      if (fromCoord != null && toCoord != null) {
        final fallbackDetails = GoogleMapsClient.generateFallbackTravelDetails(
          fromPostcode, toPostcode, fromCoord, toCoord, mode,
        );
        await LocationCache.setTravelDetails(fallbackDetails);
        return fallbackDetails;
      }
      
      return null;
    } catch (e) {
      debugPrint('PostcodeService: Error getting travel details: $e');
      return null;
    }
  }
  
  /// Calculate comprehensive distance with multiple transport modes
  static Future<DistanceCalculationResult?> calculateDistanceWithModes(
    String fromPostcode,
    String toPostcode, {
    List<TransportMode>? modes,
  }) async {
    final transportModes = modes ?? [TransportMode.driving, TransportMode.bicycling, TransportMode.transit];
    
    try {
      // Check cache first
      final cached = await LocationCache.getDistanceCalculation(fromPostcode, toPostcode);
      if (cached != null) {
        _cacheHits++;
        return cached;
      }
      
      final travelOptions = <TransportMode, TravelDetails>{};
      
      // Try Google Maps API if available
      if (!_useMockData && GoogleMapsClient.isInitialized) {
        try {
          _apiRequests++;
          final apiResults = await GoogleMapsClient.calculateMultipleTransportModes(
            fromPostcode, toPostcode, transportModes,
          );
          travelOptions.addAll(apiResults);
        } catch (e) {
          debugPrint('PostcodeService: Google Maps API error for multiple modes: $e');
        }
      }
      
      // Fill in missing modes with fallback calculations
      final fromCoord = await getCoordinates(fromPostcode);
      final toCoord = await getCoordinates(toPostcode);
      
      if (fromCoord != null && toCoord != null) {
        for (final mode in transportModes) {
          if (!travelOptions.containsKey(mode)) {
            final fallbackDetails = GoogleMapsClient.generateFallbackTravelDetails(
              fromPostcode, toPostcode, fromCoord, toCoord, mode,
            );
            travelOptions[mode] = fallbackDetails;
          }
        }
      }
      
      if (travelOptions.isNotEmpty) {
        final result = DistanceCalculationResult(
          fromPostcode: fromPostcode,
          toPostcode: toPostcode,
          travelOptions: travelOptions,
          calculatedAt: DateTime.now(),
          fromCache: false,
        );
        
        await LocationCache.setDistanceCalculation(result);
        return result;
      }
      
      return null;
    } catch (e) {
      debugPrint('PostcodeService: Error calculating distance with modes: $e');
      return null;
    }
  }
  
  /// Calculate distance between multiple postcodes (batch processing)
  /// Returns map with postcode as key and distance in km as value
  static Future<Map<String, double>> calculateMultipleDistances(
    String basePostcode,
    List<String> targetPostcodes, {
    TransportMode mode = TransportMode.driving,
  }) async {
    final distances = <String, double>{};
    
    // Validate base postcode
    if (!validateDutchPostcode(basePostcode)) {
      throw PostcodeException('Basis postcode is ongeldig', null, basePostcode);
    }
    
    // Process in batches to avoid overwhelming the API
    const batchSize = 10;
    final batches = <List<String>>[];
    
    for (int i = 0; i < targetPostcodes.length; i += batchSize) {
      final end = (i + batchSize < targetPostcodes.length) ? i + batchSize : targetPostcodes.length;
      batches.add(targetPostcodes.sublist(i, end));
    }
    
    for (final batch in batches) {
      await Future.wait(batch.map((postcode) async {
        if (validateDutchPostcode(postcode)) {
          try {
            final travelDetails = await getTravelDetails(basePostcode, postcode, mode);
            distances[postcode] = travelDetails?.distanceKm ?? double.infinity;
          } catch (e) {
            debugPrint('PostcodeService: Error calculating distance to $postcode: $e');
            distances[postcode] = double.infinity;
          }
        } else {
          distances[postcode] = double.infinity;
        }
      }));
      
      // Add small delay between batches to be kind to the API
      if (batches.indexOf(batch) < batches.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    return distances;
  }
  
  // =========================================================================
  // SPATIAL SEARCH AND FILTERING
  // =========================================================================
  
  /// Find nearby locations within a specified radius
  static Future<List<Location>> findNearbyLocations(
    String postcode,
    double radiusKm, {
    List<Location>? locations,
  }) async {
    final centerCoord = await getCoordinates(postcode);
    if (centerCoord == null) {
      throw PostcodeException('Could not get coordinates for center postcode', null, postcode);
    }
    
    final nearbyLocations = <Location>[];
    final locationsToCheck = locations ?? [];
    
    for (final location in locationsToCheck) {
      final distance = GoogleMapsClient.calculateHaversineDistance(
        centerCoord,
        location.coordinate,
      );
      
      if (distance <= radiusKm) {
        nearbyLocations.add(location);
      }
    }
    
    // Sort by distance
    nearbyLocations.sort((a, b) {
      final distanceA = GoogleMapsClient.calculateHaversineDistance(centerCoord, a.coordinate);
      final distanceB = GoogleMapsClient.calculateHaversineDistance(centerCoord, b.coordinate);
      return distanceA.compareTo(distanceB);
    });
    
    return nearbyLocations;
  }
  
  /// Get postcodes within a radius using grid-based approximation
  static Future<List<String>> getPostcodesInRadius(
    String centerPostcode,
    double radiusKm,
  ) async {
    final centerCoord = await getCoordinates(centerPostcode);
    if (centerCoord == null) {
      return [];
    }
    
    final nearbyPostcodes = <String>[];
    
    // Get center postcode number for efficient range calculation
    final centerNumber = int.parse(centerPostcode.substring(0, 4));
    
    // Calculate approximate postcode range (rough estimation)
    final rangeEstimate = (radiusKm / 5).ceil(); // ~5km per 100 postcode numbers (very rough)
    
    // Generate potential postcodes in the area
    final startRange = (centerNumber - rangeEstimate * 100).clamp(1000, 9999);
    final endRange = (centerNumber + rangeEstimate * 100).clamp(1000, 9999);
    
    // This is a simplified implementation - in production, you'd want a more
    // sophisticated postcode database or use the Google Maps Places API
    for (int num = startRange; num <= endRange; num += 50) {
      final testPostcode = '${num}AB';
      try {
        final testCoord = await getCoordinates(testPostcode);
        if (testCoord != null) {
          final distance = GoogleMapsClient.calculateHaversineDistance(centerCoord, testCoord);
          if (distance <= radiusKm) {
            nearbyPostcodes.add(testPostcode);
          }
        }
      } catch (e) {
        // Skip invalid postcodes
      }
    }
    
    return nearbyPostcodes;
  }
  
  /// Filter postcodes by maximum distance
  static Future<List<String>> filterByDistance(
    String basePostcode,
    List<String> postcodes,
    double maxDistanceKm, {
    TransportMode mode = TransportMode.driving,
  }) async {
    final distances = await calculateMultipleDistances(basePostcode, postcodes, mode: mode);
    
    return distances.entries
        .where((entry) => entry.value <= maxDistanceKm)
        .map((entry) => entry.key)
        .toList()
      ..sort((a, b) => distances[a]!.compareTo(distances[b]!));
  }
  
  // =========================================================================
  // BUSINESS INTELLIGENCE AND ANALYTICS
  // =========================================================================
  
  /// Get service performance statistics
  static Map<String, dynamic> getServiceStatistics() {
    final now = DateTime.now();
    final hoursSinceReset = now.difference(_lastStatsReset).inHours;
    
    final cacheHitRatio = _totalRequests > 0 ? (_cacheHits / _totalRequests) * 100 : 0.0;
    final apiUsageRatio = _totalRequests > 0 ? (_apiRequests / _totalRequests) * 100 : 0.0;
    
    return {
      'isInitialized': _isInitialized,
      'isUsingMockData': _useMockData,
      'totalRequests': _totalRequests,
      'apiRequests': _apiRequests,
      'cacheHits': _cacheHits,
      'cacheHitRatio': '${cacheHitRatio.toStringAsFixed(1)}%',
      'apiUsageRatio': '${apiUsageRatio.toStringAsFixed(1)}%',
      'hoursSinceReset': hoursSinceReset,
      'googleMapsServiceStatus': GoogleMapsClient.serviceStatus.displayName,
      'averageRequestsPerHour': hoursSinceReset > 0 ? (_totalRequests / hoursSinceReset).toStringAsFixed(1) : '0',
    };
  }
  
  /// Get comprehensive service health information
  static Future<Map<String, dynamic>> getServiceHealth() async {
    final stats = getServiceStatistics();
    
    ServiceHealth? googleMapsHealth;
    if (GoogleMapsClient.isInitialized) {
      try {
        googleMapsHealth = await GoogleMapsClient.getServiceHealth();
      } catch (e) {
        debugPrint('PostcodeService: Error checking Google Maps health: $e');
      }
    }
    
    final cacheStats = await LocationCache.getCacheStatistics();
    
    return {
      'service': 'PostcodeService',
      'status': _isInitialized ? 'healthy' : 'not_initialized',
      'statistics': stats,
      'googleMapsHealth': googleMapsHealth?.toString(),
      'cacheStatistics': {
        'totalEntries': cacheStats.totalEntries,
        'hitRatio': '${cacheStats.hitRatio.toStringAsFixed(1)}%',
        'totalRequests': cacheStats.totalRequests,
        'cacheHits': cacheStats.cacheHits,
      },
      'checkedAt': DateTime.now().toIso8601String(),
    };
  }
  
  /// Reset service statistics (useful for monitoring periods)
  static void resetStatistics() {
    _totalRequests = 0;
    _apiRequests = 0;
    _cacheHits = 0;
    _lastStatsReset = DateTime.now();
    debugPrint('PostcodeService: Statistics reset');
  }
  
  // =========================================================================
  // CACHE MANAGEMENT
  // =========================================================================
  
  /// Clear all cached data
  static Future<void> clearCache() async {
    await LocationCache.clearCache();
    resetStatistics();
    debugPrint('PostcodeService: All cache data cleared');
  }
  
  /// Preload common postcode routes for better performance
  static Future<void> preloadCommonRoutes(List<String> commonPostcodes) async {
    debugPrint('PostcodeService: Preloading ${commonPostcodes.length} common postcodes');
    
    for (final postcode in commonPostcodes) {
      if (validateDutchPostcode(postcode)) {
        try {
          await getCoordinates(postcode);
          // Small delay to avoid overwhelming the API
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (e) {
          debugPrint('PostcodeService: Error preloading $postcode: $e');
        }
      }
    }
    
    await LocationCache.preloadCommonRoutes(commonPostcodes);
    debugPrint('PostcodeService: Preloading completed');
  }
  
  /// Perform cache maintenance (cleanup expired entries)
  static Future<void> performMaintenance() async {
    try {
      await LocationCache.cleanupExpiredEntries();
      debugPrint('PostcodeService: Cache maintenance completed');
    } catch (e) {
      debugPrint('PostcodeService: Cache maintenance error: $e');
    }
  }
  
  // =========================================================================
  // LEGACY METHODS (for backward compatibility)
  // =========================================================================
  
  /// Legacy method: Get Nederlandse provinces for postcode ranges
  static String getProvinceForPostcode(String postcode) {
    if (!validateDutchPostcode(postcode)) return 'Onbekend';
    
    final numbers = int.parse(postcode.substring(0, 4));
    final province = DutchProvince.fromPostcodeNumber(numbers);
    return province?.displayName ?? 'Onbekend';
  }
  
  
  /// Legacy method: Get cache size for debugging
  static int getCacheSize() {
    // This now returns a simple estimate - full cache stats available via getCacheStatistics
    return _cacheHits + (_totalRequests - _cacheHits); // Rough estimate
  }
  
  // =========================================================================
  // PRIVATE HELPER METHODS
  // =========================================================================
  
  /// Generate approximate coordinates based on postcode pattern (fallback method)
  /// This is used when Google Maps API is not available
  static PostcodeCoordinate _generateApproximateCoordinates(String postcode) {
    final numbers = int.parse(postcode.substring(0, 4));
    final letters = postcode.substring(4);
    
    // Netherlands approximate bounds
    const double minLat = 50.7;
    const double maxLat = 53.6;
    const double minLon = 3.3;
    const double maxLon = 7.2;
    
    // Improved mapping based on actual Dutch postcode distribution
    // Amsterdam (1000-1299) -> North-West
    // Den Haag/Rotterdam (2000-2999) -> West
    // Utrecht (3000-3999) -> Center
    // Zuid-Holland (4000-4999) -> South-West
    // Noord-Brabant (5000-5999) -> South
    // Limburg (6000-6999) -> South-East
    // Overijssel (7000-7999) -> East
    // Drenthe (8000-8999) -> North-East
    // Groningen/Friesland (9000-9999) -> North
    
    double latitude, longitude;
    
    if (numbers >= 1000 && numbers < 2000) {
      // Noord-Holland region
      latitude = 52.3 + (numbers - 1000) / 2000.0;
      longitude = 4.8 + (letters.codeUnitAt(0) - 65) / 50.0;
    } else if (numbers >= 2000 && numbers < 3000) {
      // Zuid-Holland region
      latitude = 51.9 + (numbers - 2000) / 3000.0;
      longitude = 4.3 + (letters.codeUnitAt(0) - 65) / 40.0;
    } else if (numbers >= 3000 && numbers < 4000) {
      // Utrecht region
      latitude = 52.0 + (numbers - 3000) / 2500.0;
      longitude = 5.1 + (letters.codeUnitAt(0) - 65) / 60.0;
    } else if (numbers >= 5000 && numbers < 6000) {
      // Noord-Brabant region
      latitude = 51.4 + (numbers - 5000) / 4000.0;
      longitude = 5.0 + (letters.codeUnitAt(0) - 65) / 30.0;
    } else {
      // Default mapping for other regions
      final latFactor = (numbers % 3000) / 3000.0;
      final lonFactor = (letters.codeUnitAt(0) - 65) / 25.0;
      latitude = minLat + (maxLat - minLat) * latFactor;
      longitude = minLon + (maxLon - minLon) * lonFactor;
    }
    
    // Get province information
    final province = DutchProvince.fromPostcodeNumber(numbers);
    
    return PostcodeCoordinate(
      postcode: postcode,
      latitude: latitude.clamp(minLat, maxLat),
      longitude: longitude.clamp(minLon, maxLon),
      province: province?.displayName,
      cachedAt: DateTime.now(),
      source: 'fallback_approximation',
    );
  }
  
  
  
}

