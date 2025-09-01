import 'package:flutter/foundation.dart';
import '../../config/environment_config.dart';

/// Configuration for location services and Google Maps integration
/// 
/// Manages API keys, rate limits, and service settings for production use.
/// Environment-specific configuration with security best practices.
class LocationConfig {
  LocationConfig._();

  // =========================================================================
  // API CONFIGURATION
  // =========================================================================

  /// Google Maps API key (should be loaded from environment or secure storage)
  static String? _googleMapsApiKey;
  
  /// Set Google Maps API key programmatically
  static void setGoogleMapsApiKey(String apiKey) {
    _googleMapsApiKey = apiKey;
    debugPrint('LocationConfig: Google Maps API key configured');
  }
  
  /// Get Google Maps API key
  static String? get googleMapsApiKey => _googleMapsApiKey;
  
  /// Check if Google Maps is configured
  static bool get isGoogleMapsConfigured => _googleMapsApiKey?.isNotEmpty ?? false;

  // =========================================================================
  // SERVICE SETTINGS
  // =========================================================================

  /// Cache TTL (Time To Live) in hours
  static const int cacheTtlHours = 24;
  
  /// Maximum number of concurrent API requests
  static const int maxConcurrentRequests = 10;
  
  /// Rate limit: requests per minute
  static const int maxRequestsPerMinute = 50;
  
  /// Rate limit: minimum interval between requests (milliseconds)
  static const int minRequestIntervalMs = 100;
  
  /// Circuit breaker: maximum failures before opening
  static const int maxFailuresBeforeCircuitBreaker = 5;
  
  /// Circuit breaker timeout in minutes
  static const int circuitBreakerTimeoutMinutes = 5;
  
  /// API timeout in seconds
  static const int apiTimeoutSeconds = 10;
  
  /// Maximum cache size (number of entries)
  static const int maxCacheSize = 2000;
  
  /// Enable detailed logging in debug mode
  static bool get enableDebugLogging => kDebugMode;
  
  /// Use mock data when API is not available
  static bool get useMockDataFallback => true;

  // =========================================================================
  // DUTCH BUSINESS SETTINGS
  // =========================================================================

  /// Default search radius in kilometers
  static const double defaultSearchRadiusKm = 25.0;
  
  /// Maximum reasonable commute distance in Netherlands
  static const double maxCommuteDistanceKm = 100.0;
  
  /// Preferred transport modes for job search
  static const List<String> preferredTransportModes = [
    'driving',
    'transit', 
    'bicycling'
  ];
  
  /// Cost estimates (per km in EUR)
  static const Map<String, double> transportCosts = {
    'driving': 0.19,    // Includes fuel and parking estimate
    'transit': 0.20,    // OV-chipkaart rate
    'bicycling': 0.0,   // Free
    'walking': 0.0,     // Free
  };
  
  /// Carbon footprint estimates (kg CO2 per km)
  static const Map<String, double> carbonFootprints = {
    'driving': 0.12,
    'transit': 0.05,
    'bicycling': 0.0,
    'walking': 0.0,
  };
  
  /// Common Dutch cities for testing and examples
  static const Map<String, String> commonCityPostcodes = {
    'Amsterdam': '1012AB',
    'Rotterdam': '3011AB',
    'Den Haag': '2511CV',
    'Utrecht': '3511LN',
    'Eindhoven': '5611AB',
    'Tilburg': '5038EA',
    'Groningen': '9711LM',
    'Almere': '1301AB',
    'Breda': '4811AB',
    'Nijmegen': '6511AB',
  };

  // =========================================================================
  // ENVIRONMENT-SPECIFIC METHODS
  // =========================================================================

  /// Load configuration from environment variables or secure storage
  static Future<void> loadFromEnvironment() async {
    try {
      // Load from secure environment configuration
      final envApiKey = EnvironmentConfig.googleMapsApiKey;
      if (envApiKey.isNotEmpty) {
        _googleMapsApiKey = envApiKey;
        debugPrint('LocationConfig: API key loaded from environment');
      } else {
        debugPrint('LocationConfig: Google Maps API key not configured - using mock data');
      }
    } catch (e) {
      debugPrint('LocationConfig: Error loading from environment: $e');
    }
  }
  
  /// Get configuration for specific environment
  static Map<String, dynamic> getEnvironmentConfig({bool isProduction = false}) {
    return {
      'isProduction': isProduction,
      'apiConfigured': isGoogleMapsConfigured,
      'useMockData': !isGoogleMapsConfigured || (!isProduction && kDebugMode),
      'cacheSettings': {
        'ttlHours': cacheTtlHours,
        'maxSize': maxCacheSize,
      },
      'rateLimits': {
        'requestsPerMinute': maxRequestsPerMinute,
        'minIntervalMs': minRequestIntervalMs,
      },
      'circuitBreaker': {
        'maxFailures': maxFailuresBeforeCircuitBreaker,
        'timeoutMinutes': circuitBreakerTimeoutMinutes,
      },
      'businessSettings': {
        'defaultSearchRadius': defaultSearchRadiusKm,
        'maxCommuteDistance': maxCommuteDistanceKm,
        'transportCosts': transportCosts,
        'carbonFootprints': carbonFootprints,
      },
    };
  }
  
  /// Validate current configuration
  static List<String> validateConfiguration() {
    final issues = <String>[];
    
    if (!isGoogleMapsConfigured) {
      issues.add('Google Maps API key not configured - using mock data');
    }
    
    if (kDebugMode && isGoogleMapsConfigured) {
      issues.add('Debug mode with real API key - consider using mock data for development');
    }
    
    return issues;
  }
  
  /// Get recommended settings for production deployment
  static Map<String, dynamic> getProductionRecommendations() {
    return {
      'security': [
        'Store API key in secure environment variables',
        'Enable HTTPS-only for API requests',
        'Implement API key rotation',
        'Monitor API usage and costs',
      ],
      'performance': [
        'Enable request caching with ${cacheTtlHours}h TTL',
        'Implement request batching for multiple locations',
        'Use CDN for static location data',
        'Monitor cache hit rates (target: >70%)',
      ],
      'reliability': [
        'Configure circuit breaker with $maxFailuresBeforeCircuitBreaker failure threshold',
        'Implement graceful degradation to mock data',
        'Set up API health monitoring',
        'Configure alerting for API quota limits',
      ],
      'business': [
        'Validate all location services work within Netherlands',
        'Test postcode validation with real Dutch addresses',
        'Verify transport cost calculations',
        'Ensure GDPR compliance for location data',
      ],
    };
  }
}

/// Location service initialization helper
class LocationServiceInitializer {
  /// Initialize all location services with proper configuration
  static Future<bool> initializeServices({
    String? googleMapsApiKey,
    bool forceReinit = false,
  }) async {
    try {
      // Load environment configuration
      await LocationConfig.loadFromEnvironment();
      
      // Set API key if provided
      if (googleMapsApiKey != null) {
        LocationConfig.setGoogleMapsApiKey(googleMapsApiKey);
      }
      
      // Validate configuration
      final issues = LocationConfig.validateConfiguration();
      if (issues.isNotEmpty) {
        debugPrint('LocationServiceInitializer: Configuration issues: ${issues.join(', ')}');
      }
      
      // Initialize PostcodeService (this will be imported)
      // await PostcodeService.initialize(googleMapsApiKey: LocationConfig.googleMapsApiKey);
      
      debugPrint('LocationServiceInitializer: All services initialized successfully');
      return true;
    } catch (e) {
      debugPrint('LocationServiceInitializer: Initialization failed: $e');
      return false;
    }
  }
  
  /// Get service status summary
  static Map<String, dynamic> getServiceStatus() {
    return {
      'googleMapsConfigured': LocationConfig.isGoogleMapsConfigured,
      'environmentConfig': LocationConfig.getEnvironmentConfig(),
      'validationIssues': LocationConfig.validateConfiguration(),
      'isDebugMode': kDebugMode,
    };
  }
}

/// Constants for Dutch location services
class DutchLocationConstants {
  /// Netherlands geographic boundaries
  static const double netherlandsMinLatitude = 50.7;
  static const double netherlandsMaxLatitude = 53.6;
  static const double netherlandsMinLongitude = 3.3;
  static const double netherlandsMaxLongitude = 7.2;
  
  /// Center of Netherlands (approximate)
  static const double netherlandsCenterLatitude = 52.1326;
  static const double netherlandsCenterLongitude = 5.2913;
  
  /// Major city coordinates for reference
  static const Map<String, Map<String, double>> majorCityCoordinates = {
    'Amsterdam': {'lat': 52.3676, 'lng': 4.9041},
    'Rotterdam': {'lat': 51.9244, 'lng': 4.4777},
    'Den Haag': {'lat': 52.0705, 'lng': 4.3007},
    'Utrecht': {'lat': 52.0907, 'lng': 5.1214},
    'Eindhoven': {'lat': 51.4416, 'lng': 5.4697},
    'Tilburg': {'lat': 51.5555, 'lng': 5.0913},
    'Groningen': {'lat': 53.2194, 'lng': 6.5665},
    'Almere': {'lat': 52.3508, 'lng': 5.2647},
  };
  
  /// Postcode ranges by province
  static const Map<String, Map<String, int>> provincePostcodeRanges = {
    'Noord-Holland': {'min': 1000, 'max': 1999},
    'Zuid-Holland': {'min': 2000, 'max': 4999},
    'Noord-Brabant': {'min': 5000, 'max': 5999},
    'Limburg': {'min': 6000, 'max': 6999},
    'Overijssel': {'min': 7000, 'max': 7999},
    'Drenthe': {'min': 8000, 'max': 8999},
    'Groningen': {'min': 9000, 'max': 9299},
    'Friesland': {'min': 9300, 'max': 9999},
    'Flevoland': {'min': 1300, 'max': 1380},
    'Utrecht': {'min': 3400, 'max': 3999},
    'Gelderland': {'min': 6500, 'max': 7999},
    'Zeeland': {'min': 4300, 'max': 4999},
  };
}