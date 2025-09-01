# PostcodeService - Comprehensive Dutch Location Services

## Overview

The PostcodeService provides production-ready Nederlandse postcode validation, distance calculation, and location services for the SecuryFlex security job marketplace. It integrates with Google Maps APIs while providing intelligent fallbacks and caching for optimal performance.

## Features

### Core Functionality
- ✅ **Strict Dutch Postcode Validation** - Validates 1234AB format with business rules
- ✅ **Multi-tier Distance Calculation** - Google Maps API with Haversine fallback
- ✅ **Advanced Caching System** - 24-hour TTL with SharedPreferences
- ✅ **Rate Limiting & API Management** - Production-ready request handling
- ✅ **Spatial Search & Filtering** - Location-based job matching
- ✅ **Business Intelligence** - Performance monitoring and analytics

### Dutch Business Compliance
- ✅ **Provincial Mapping** - Accurate province identification
- ✅ **Transport Mode Support** - Car, OV, bicycle, walking
- ✅ **Cost Estimation** - Dutch transport cost calculations
- ✅ **Carbon Footprint** - Environmental impact tracking

## Quick Start

### 1. Installation

Add dependencies to `pubspec.yaml`:

```yaml
dependencies:
  google_maps_flutter: ^2.10.0
  geolocator: ^13.0.2
  shared_preferences: ^2.3.4
  http: ^1.2.2
```

### 2. Initialization

```dart
import 'package:securyflex_app/marketplace/services/postcode_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with Google Maps API key (production)
  await PostcodeService.initialize(
    googleMapsApiKey: 'YOUR_GOOGLE_MAPS_API_KEY',
  );
  
  // Or initialize without API key (development/mock mode)
  await PostcodeService.initialize();
  
  runApp(MyApp());
}
```

### 3. Basic Usage

```dart
// Validate Dutch postcodes
final isValid = PostcodeService.validateDutchPostcode('1012AB');
final validationResult = PostcodeService.validatePostcodeDetailed('1012AB');

// Get coordinates
final coordinate = await PostcodeService.getCoordinates('1012AB');
print('Location: ${coordinate?.latitude}, ${coordinate?.longitude}');

// Calculate distance
final distance = await PostcodeService.calculateDistance('1012AB', '2511CV');
print('Distance: ${distance.toStringAsFixed(1)}km');

// Get travel details
final travelDetails = await PostcodeService.getTravelDetails(
  '1012AB', '2511CV', TransportMode.driving
);
print('Travel: ${travelDetails?.formattedDistance} in ${travelDetails?.formattedDuration}');
```

## API Reference

### Core Methods

#### `PostcodeService.initialize({String? googleMapsApiKey})`
Initializes the service with optional Google Maps integration.

#### `PostcodeService.validateDutchPostcode(String postcode) → bool`
Quick validation of Dutch postcode format.

#### `PostcodeService.validatePostcodeDetailed(String postcode) → PostcodeValidationResult`
Comprehensive validation with detailed error messages and suggestions.

#### `PostcodeService.getCoordinates(String postcode) → Future<PostcodeCoordinate?>`
Get latitude/longitude coordinates for a Dutch postcode.

#### `PostcodeService.calculateDistance(String from, String to) → Future<double>`
Calculate straight-line distance between postcodes in kilometers.

#### `PostcodeService.getTravelDetails(String from, String to, TransportMode mode) → Future<TravelDetails?>`
Get comprehensive travel information including distance, time, and route details.

### Advanced Methods

#### `PostcodeService.calculateDistanceWithModes(String from, String to, {List<TransportMode>? modes}) → Future<DistanceCalculationResult?>`
Calculate travel details for multiple transport modes simultaneously.

#### `PostcodeService.findNearbyLocations(String postcode, double radiusKm, {List<Location>? locations}) → Future<List<Location>>`
Find locations within a specified radius of a postcode.

#### `PostcodeService.filterByDistance(String basePostcode, List<String> postcodes, double maxDistanceKm) → Future<List<String>>`
Filter and sort postcodes by distance from a base location.

#### `PostcodeService.getPostcodesInRadius(String centerPostcode, double radiusKm) → Future<List<String>>`
Get postcodes within a radius using grid-based approximation.

### Service Management

#### `PostcodeService.getServiceStatistics() → Map<String, dynamic>`
Get performance statistics including cache hit rates and API usage.

#### `PostcodeService.getServiceHealth() → Future<Map<String, dynamic>>`
Get comprehensive service health information.

#### `PostcodeService.clearCache() → Future<void>`
Clear all cached data.

#### `PostcodeService.preloadCommonRoutes(List<String> commonPostcodes) → Future<void>`
Preload coordinates for frequently used postcodes.

## Transport Modes

```dart
enum TransportMode {
  driving,    // Car/motorcycle
  walking,    // On foot
  bicycling,  // Bicycle
  transit,    // Public transport (OV)
}
```

### Transport Mode Features

| Mode | Distance Accuracy | Time Accuracy | Cost Calculation | Dutch Optimization |
|------|------------------|---------------|------------------|-------------------|
| `driving` | ✅ Google Maps | ✅ Real traffic | ✅ Fuel + parking | ✅ Dutch roads |
| `transit` | ✅ Google Maps | ✅ OV schedules | ✅ OV-chipkaart | ✅ GVB/NS/Arriva |
| `bicycling` | ✅ Google Maps | ✅ Cycle routes | ✅ Free | ✅ Dutch bike paths |
| `walking` | ✅ Google Maps | ✅ Pedestrian | ✅ Free | ✅ Dutch sidewalks |

## Business Logic Integration

### Job Location Filtering

```dart
import 'package:securyflex_app/marketplace/services/enhanced_job_location_service.dart';

// Find jobs within commuting distance
final jobMatches = await EnhancedJobLocationService.findJobsWithinDistance(
  userPostcode: '1012AB',
  jobs: availableJobs,
  maxDistanceKm: 50.0,
  transportMode: TransportMode.driving,
);

// Get travel recommendations
final travelRec = await EnhancedJobLocationService.getTravelRecommendation(
  userPostcode: '1012AB',
  job: selectedJob,
);

// Generate location-based recommendations
final recommendations = await EnhancedJobLocationService.generateLocationRecommendations(
  userPostcode: '1012AB',
  availableJobs: allJobs,
  userCertificates: ['WPBR', 'BHV'],
  maxCommuteDistance: 40.0,
);
```

### Guard Profile Location Setup

```dart
// Validate guard's home postcode
final validation = PostcodeService.validatePostcodeDetailed(userInput);
if (!validation.isValid) {
  showError(validation.errorMessage!);
  showSuggestions(validation.suggestions!);
} else {
  // Store validated postcode
  final cleanPostcode = validation.cleanPostcode!;
  final province = validation.province!;
}
```

### Company Job Posting

```dart
// Validate company location
final companyPostcode = '2511CV'; // Den Haag
final coordinate = await PostcodeService.getCoordinates(companyPostcode);

// Calculate coverage area
final nearbyPostcodes = await PostcodeService.getPostcodesInRadius(
  companyPostcode,
  25.0, // 25km radius
);

// Estimate commute attractiveness
for (final guardPostcode in potentialGuardLocations) {
  final travelDetails = await PostcodeService.getTravelDetails(
    guardPostcode,
    companyPostcode,
    TransportMode.driving,
  );
  
  if (travelDetails != null && travelDetails.duration.inMinutes < 60) {
    // Good commute - attractive to guards
  }
}
```

## Error Handling

### Exception Types

```dart
// Postcode validation errors
try {
  final coord = await PostcodeService.getCoordinates('invalid');
} on PostcodeException catch (e) {
  print('Postcode error: ${e.message}');
  print('Error code: ${e.code}');
  print('Postcode: ${e.postcode}');
}

// Distance calculation errors
try {
  final distance = await PostcodeService.calculateDistance('1012AB', '2511CV');
} on DistanceCalculationException catch (e) {
  print('Distance error: ${e.message}');
  print('Route: ${e.fromPostcode} → ${e.toPostcode}');
}

// API errors
try {
  final details = await PostcodeService.getTravelDetails('1012AB', '2511CV', TransportMode.driving);
} on ApiException catch (e) {
  print('API error [${e.service}]: ${e.message}');
  print('Status code: ${e.statusCode}');
}
```

### Graceful Degradation

The service automatically falls back to mock data when:
- Google Maps API is not configured
- API quota is exceeded
- Network connectivity issues occur
- API service is temporarily unavailable

## Performance Optimization

### Caching Strategy

```dart
// Cache statistics
final stats = await PostcodeService.getServiceStatistics();
print('Cache hit ratio: ${stats['cacheHitRatio']}');
print('Total requests: ${stats['totalRequests']}');

// Manual cache management
await PostcodeService.clearCache();           // Clear all cache
await PostcodeService.performMaintenance();   // Cleanup expired entries
await PostcodeService.preloadCommonRoutes([  // Preload frequently used postcodes
  '1012AB', '2511CV', '3511LN'
]);
```

### Batch Processing

```dart
// Efficient multiple distance calculation
final distances = await PostcodeService.calculateMultipleDistances(
  '1012AB',                                    // Base postcode
  ['2511CV', '3511LN', '5038EA', '6823HX'],   // Target postcodes
);

// Results are automatically sorted by distance
distances.forEach((postcode, distance) {
  print('$postcode: ${distance.toStringAsFixed(1)}km');
});
```

### Rate Limiting

The service automatically handles:
- **50 requests per minute** maximum
- **100ms minimum interval** between requests
- **Circuit breaker** after 5 consecutive failures
- **Exponential backoff** on API errors

## Testing

### Unit Tests

```dart
// Run comprehensive test suite
flutter test test/services/location/postcode_service_test.dart

// Test specific functionality
flutter test test/services/location/postcode_service_test.dart --name "Dutch Postcode Validation"
```

### Mock Data

```dart
// Enable mock mode for testing
await PostcodeService.initialize(); // No API key = mock mode

// Check if using mock data
if (PostcodeService.isUsingMockData) {
  print('Running in mock mode');
}
```

## Configuration

### Environment Setup

```dart
// Development
await PostcodeService.initialize(); // Uses mock data

// Staging
await PostcodeService.initialize(
  googleMapsApiKey: 'staging_api_key',
);

// Production
await PostcodeService.initialize(
  googleMapsApiKey: Platform.environment['GOOGLE_MAPS_API_KEY'],
);
```

### Location Config

```dart
import 'package:securyflex_app/services/location/location_config.dart';

// Load configuration
await LocationConfig.loadFromEnvironment();

// Validate setup
final issues = LocationConfig.validateConfiguration();
if (issues.isNotEmpty) {
  print('Configuration issues: ${issues.join(', ')}');
}

// Get production recommendations
final recommendations = LocationConfig.getProductionRecommendations();
print('Security recommendations: ${recommendations['security']}');
```

## Production Deployment

### Security Checklist

- [ ] Store Google Maps API key in secure environment variables
- [ ] Enable API key restrictions (HTTP referrers for web, bundle ID for mobile)
- [ ] Set up API quota monitoring and alerts
- [ ] Implement request logging for audit trails
- [ ] Enable HTTPS-only for all API requests

### Performance Checklist

- [ ] Monitor cache hit rates (target: >70%)
- [ ] Set up API response time monitoring
- [ ] Configure CDN for static location data
- [ ] Implement request queuing for high load
- [ ] Test with production data volumes

### Business Checklist

- [ ] Validate all postcodes work correctly
- [ ] Test transport cost calculations
- [ ] Verify province mappings
- [ ] Ensure GDPR compliance for location data
- [ ] Test fallback scenarios

## Cost Optimization

### Google Maps API Usage

```dart
// Monitor API usage
final stats = PostcodeService.getServiceStatistics();
final apiUsageRatio = stats['apiUsageRatio']; // Percentage of requests hitting API

// Optimize with caching
if (double.parse(apiUsageRatio.replaceAll('%', '')) > 30) {
  // Consider preloading more common routes
  await PostcodeService.preloadCommonRoutes(mostUsedPostcodes);
}
```

### Estimated Costs (Google Maps APIs)

- **Geocoding**: $5 per 1000 requests
- **Distance Matrix**: $10 per 1000 requests  
- **Directions**: $5 per 1000 requests

**With 70% cache hit rate:**
- 10,000 daily requests = ~3,000 API calls = ~$15/day
- Caching saves ~$35/day (70% reduction)

## Support and Troubleshooting

### Common Issues

#### "PostcodeService not initialized"
```dart
// Ensure initialization before use
await PostcodeService.initialize(googleMapsApiKey: 'your_key');
```

#### "Invalid postcode format"
```dart
// Use detailed validation for better error messages
final result = PostcodeService.validatePostcodeDetailed(userInput);
if (!result.isValid) {
  showError(result.errorMessage!);
  showSuggestions(result.suggestions!);
}
```

#### "API quota exceeded"
```dart
// Monitor usage and implement caching
final health = await PostcodeService.getServiceHealth();
print('Service status: ${health['status']}');
```

### Debug Information

```dart
// Enable debug logging
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  final stats = PostcodeService.getServiceStatistics();
  final health = await PostcodeService.getServiceHealth();
  
  print('=== PostcodeService Debug Info ===');
  print('Statistics: $stats');
  print('Health: $health');
  print('===================================');
}
```

## Roadmap

### Planned Features
- [ ] **PostcodeNL API Integration** - Alternative to Google Maps
- [ ] **Offline Mode** - Full offline postcode database
- [ ] **ML Route Optimization** - AI-powered travel recommendations
- [ ] **Real-time Traffic** - Dynamic travel time updates
- [ ] **Multi-language Support** - English localization

### Performance Improvements
- [ ] **GraphQL Integration** - More efficient data fetching
- [ ] **WebAssembly Calculations** - Faster distance calculations
- [ ] **Edge Caching** - CDN-based coordinate caching
- [ ] **Background Sync** - Proactive cache updates

## License

This implementation is part of the SecuryFlex platform and follows the project's licensing terms.

---

*For technical support, contact the SecuryFlex development team or create an issue in the project repository.*