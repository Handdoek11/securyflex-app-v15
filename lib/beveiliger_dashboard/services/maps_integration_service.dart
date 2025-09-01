import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
// import '../../shared/services/location_service.dart';

/// Service for integrating maps functionality in beveiliger dashboard
/// Handles location tracking, route calculation, and map interactions
class MapsIntegrationService {
  static MapsIntegrationService? _instance;
  static MapsIntegrationService get instance {
    _instance ??= MapsIntegrationService._();
    return _instance!;
  }
  
  MapsIntegrationService._();
  
  // Location tracking
  StreamSubscription<Position>? _locationSubscription;
  Position? _currentPosition;
  
  // Service status
  bool _isInitialized = false;
  bool _isTrackingLocation = false;
  
  /// Initialize the maps integration service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Check location permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          debugPrint('MapsIntegrationService: Location permission denied');
          return false;
        }
      }
      
      _isInitialized = true;
      debugPrint('MapsIntegrationService: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('MapsIntegrationService: Initialization failed: $e');
      return false;
    }
  }
  
  /// Start location tracking
  Future<bool> startLocationTracking() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isTrackingLocation) return true;
    
    try {
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        (Position position) {
          _currentPosition = position;
          _onLocationUpdate(position);
        },
        onError: (error) {
          debugPrint('MapsIntegrationService: Location tracking error: $error');
        },
      );
      
      _isTrackingLocation = true;
      debugPrint('MapsIntegrationService: Location tracking started');
      return true;
    } catch (e) {
      debugPrint('MapsIntegrationService: Failed to start location tracking: $e');
      return false;
    }
  }
  
  /// Stop location tracking
  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTrackingLocation = false;
    debugPrint('MapsIntegrationService: Location tracking stopped');
  }
  
  /// Get current location
  Future<Position?> getCurrentLocation() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final position = await Geolocator.getCurrentPosition();
      _currentPosition = position;
      return position;
    } catch (e) {
      debugPrint('MapsIntegrationService: Failed to get current location: $e');
      return null;
    }
  }
  
  /// Calculate distance between two points
  double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
  
  /// Calculate distance from current location to target
  double? calculateDistanceFromCurrent({
    required double targetLat,
    required double targetLng,
  }) {
    if (_currentPosition == null) return null;
    
    return calculateDistance(
      startLat: _currentPosition!.latitude,
      startLng: _currentPosition!.longitude,
      endLat: targetLat,
      endLng: targetLng,
    );
  }
  
  /// Generate maps URL for navigation
  String generateNavigationUrl({
    required double destinationLat,
    required double destinationLng,
    String? destinationName,
  }) {
    // Google Maps navigation URL
    final encodedName = destinationName != null 
        ? Uri.encodeComponent(destinationName)
        : '';
    
    if (destinationName != null) {
      return 'https://www.google.com/maps/dir/?api=1&destination=$encodedName&destination_place_id=$destinationLat,$destinationLng';
    } else {
      return 'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng';
    }
  }
  
  /// Generate maps URL for location preview
  String generateLocationPreviewUrl({
    required double lat,
    required double lng,
    int zoom = 15,
  }) {
    return 'https://www.google.com/maps/@$lat,$lng,${zoom}z';
  }
  
  /// Check if location is within geofence
  bool isWithinGeofence({
    required double centerLat,
    required double centerLng,
    required double radiusMeters,
    Position? position,
  }) {
    final currentPos = position ?? _currentPosition;
    if (currentPos == null) return false;
    
    final distance = calculateDistance(
      startLat: currentPos.latitude,
      startLng: currentPos.longitude,
      endLat: centerLat,
      endLng: centerLng,
    );
    
    return distance <= radiusMeters;
  }
  
  /// Format coordinates for display
  String formatCoordinates(double lat, double lng, {int precision = 6}) {
    return '${lat.toStringAsFixed(precision)}, ${lng.toStringAsFixed(precision)}';
  }
  
  /// Convert meters to human readable distance
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }
  
  /// Handle location updates
  void _onLocationUpdate(Position position) {
    // This can be used for real-time updates
    // Can notify listeners, update UI, check geofences, etc.
    debugPrint('MapsIntegrationService: Location updated: ${position.latitude}, ${position.longitude}');
  }
  
  /// Get readable address from coordinates using reverse geocoding
  Future<String?> getAddressFromCoordinates({
    required double lat,
    required double lng,
  }) async {
    try {
      debugPrint('MapsIntegrationService: Reverse geocoding for $lat, $lng');
      
      // Use Flutter geocoding package for reverse geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Build Dutch-style address format
        final addressParts = <String>[];
        
        // Street and number
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        
        // Postal code and city (Dutch format: 1234 AB Amsterdam)
        final postalCode = place.postalCode;
        final locality = place.locality ?? place.subAdministrativeArea;
        
        if (postalCode != null && locality != null) {
          addressParts.add('$postalCode $locality');
        } else if (locality != null) {
          addressParts.add(locality);
        }
        
        // Country (only if not Netherlands)
        if (place.country != null && 
            place.country != 'Netherlands' && 
            place.country != 'Nederland') {
          addressParts.add(place.country!);
        }
        
        if (addressParts.isNotEmpty) {
          final address = addressParts.join(', ');
          debugPrint('MapsIntegrationService: Geocoded address: $address');
          return address;
        }
      }
      
      // Fallback to coordinates if geocoding fails
      debugPrint('MapsIntegrationService: No geocoding results, using coordinates');
      return 'Locatie: ${formatCoordinates(lat, lng)}';
      
    } catch (e) {
      debugPrint('MapsIntegrationService: Geocoding error: $e');
      // Fallback to coordinates on error
      return 'Locatie: ${formatCoordinates(lat, lng)}';
    }
  }
  
  /// Get travel time estimate using routing service with fallback
  Future<Duration?> getTravelTimeEstimate({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String transportMode = 'driving', // driving, walking, cycling, transit
  }) async {
    try {
      debugPrint('MapsIntegrationService: Getting travel time from $startLat,$startLng to $endLat,$endLng');
      
      // Try OpenRouteService first (free tier available)
      final routeTime = await _getOpenRouteServiceTime(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        transportMode: transportMode,
      );
      
      if (routeTime != null) {
        debugPrint('MapsIntegrationService: Got route time: ${routeTime.inMinutes} minutes');
        return routeTime;
      }
      
      // Fallback to improved distance-based calculation
      debugPrint('MapsIntegrationService: Using fallback travel time calculation');
      return _calculateEstimatedTravelTime(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        transportMode: transportMode,
      );
      
    } catch (e) {
      debugPrint('MapsIntegrationService: Travel time estimation error: $e');
      
      // Fallback calculation
      return _calculateEstimatedTravelTime(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        transportMode: transportMode,
      );
    }
  }
  
  /// Get travel time from OpenRouteService API
  Future<Duration?> _getOpenRouteServiceTime({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String transportMode,
  }) async {
    try {
      // Note: In production, you would need to get an API key from OpenRouteService
      // For now, we'll simulate the API call structure
      
      // Map transport modes to ORS profiles
      switch (transportMode.toLowerCase()) {
        case 'walking':
          break;
        case 'cycling':
          break;
        case 'transit':
// Fallback to driving for transit
          break;
        case 'driving':
        default:
          break;
      }
      
      // In a real implementation, you would make this API call:
      /*
      final url = 'https://api.openrouteservice.org/v2/directions/$profile';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'YOUR_API_KEY',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'coordinates': [[startLng, startLat], [endLng, endLat]],
          'elevation': false,
          'instructions': false,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final duration = data['routes'][0]['summary']['duration'];
        return Duration(seconds: duration.round());
      }
      */
      
      // For now, return null to trigger fallback
      return null;
      
    } catch (e) {
      debugPrint('MapsIntegrationService: OpenRouteService API error: $e');
      return null;
    }
  }
  
  /// Improved fallback travel time calculation based on transport mode and terrain
  Duration _calculateEstimatedTravelTime({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String transportMode,
  }) {
    final distance = calculateDistance(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
    
    // Base speed estimates in km/h for Netherlands
    double averageSpeed;
    switch (transportMode.toLowerCase()) {
      case 'walking':
        averageSpeed = 5.0; // 5 km/h average walking speed
        break;
      case 'cycling':
        averageSpeed = 18.0; // 18 km/h average cycling speed in Netherlands
        break;
      case 'transit':
        averageSpeed = 25.0; // Public transport with stops and transfers
        break;
      case 'driving':
      default:
        // Adjust speed based on likely road types in Netherlands
        if (distance < 5000) { // < 5km - likely urban
          averageSpeed = 35.0; // Urban driving with traffic lights
        } else if (distance < 20000) { // 5-20km - suburban
          averageSpeed = 50.0; // Mix of urban and rural roads
        } else { // > 20km - likely highway
          averageSpeed = 80.0; // Highway driving
        }
        break;
    }
    
    // Add time buffer for real-world conditions (traffic, stops, etc.)
    final baseTimeHours = distance / 1000 / averageSpeed;
    final bufferMultiplier = transportMode == 'driving' ? 1.3 : 1.2; // 30% buffer for driving, 20% for others
    final estimatedTimeHours = baseTimeHours * bufferMultiplier;
    
    return Duration(minutes: (estimatedTimeHours * 60).round().clamp(1, 999));
  }
  
  /// Get coordinates from address (forward geocoding)
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      debugPrint('MapsIntegrationService: Forward geocoding for: $address');
      
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        final coordinates = {
          'latitude': location.latitude,
          'longitude': location.longitude,
        };
        
        debugPrint('MapsIntegrationService: Geocoded to: ${location.latitude}, ${location.longitude}');
        return coordinates;
      }
      
      return null;
    } catch (e) {
      debugPrint('MapsIntegrationService: Forward geocoding error: $e');
      return null;
    }
  }
  
  /// Search for places by name with location bias
  Future<List<Map<String, dynamic>>> searchPlaces({
    required String query,
    double? biasLat,
    double? biasLng,
    int limit = 5,
  }) async {
    try {
      debugPrint('MapsIntegrationService: Searching places for: $query');
      
      // Add location bias to query for Netherlands
      String searchQuery = query;
      if (!query.toLowerCase().contains('nederland') && 
          !query.toLowerCase().contains('netherlands')) {
        searchQuery = '$query, Nederland';
      }
      
      List<Location> locations = await locationFromAddress(searchQuery);
      
      final results = <Map<String, dynamic>>[];
      
      for (int i = 0; i < locations.length && i < limit; i++) {
        final location = locations[i];
        
        // Get address for this location
        final address = await getAddressFromCoordinates(
          lat: location.latitude,
          lng: location.longitude,
        );
        
        results.add({
          'latitude': location.latitude,
          'longitude': location.longitude,
          'address': address ?? 'Onbekende locatie',
          'distance': biasLat != null && biasLng != null
              ? calculateDistance(
                  startLat: biasLat,
                  startLng: biasLng,
                  endLat: location.latitude,
                  endLng: location.longitude,
                )
              : null,
        });
      }
      
      // Sort by distance if bias location provided
      if (biasLat != null && biasLng != null) {
        results.sort((a, b) {
          final distanceA = a['distance'] as double?;
          final distanceB = b['distance'] as double?;
          if (distanceA == null || distanceB == null) return 0;
          return distanceA.compareTo(distanceB);
        });
      }
      
      debugPrint('MapsIntegrationService: Found ${results.length} places');
      return results;
      
    } catch (e) {
      debugPrint('MapsIntegrationService: Place search error: $e');
      return [];
    }
  }
  
  /// Validate Dutch postal code format
  bool isValidDutchPostalCode(String postalCode) {
    // Dutch postal code format: 1234 AB or 1234AB
    final cleanCode = postalCode.replaceAll(' ', '').toUpperCase();
    final regex = RegExp(r'^\d{4}[A-Z]{2}$');
    return regex.hasMatch(cleanCode);
  }
  
  /// Format Dutch postal code to standard format (1234 AB)
  String formatDutchPostalCode(String postalCode) {
    final cleanCode = postalCode.replaceAll(' ', '').toUpperCase();
    if (cleanCode.length == 6) {
      return '${cleanCode.substring(0, 4)} ${cleanCode.substring(4, 6)}';
    }
    return postalCode;
  }
  
  /// Get service statistics
  Map<String, dynamic> getServiceStats() {
    return {
      'initialized': _isInitialized,
      'tracking_location': _isTrackingLocation,
      'has_current_position': _currentPosition != null,
      'current_coordinates': _currentPosition != null
          ? formatCoordinates(_currentPosition!.latitude, _currentPosition!.longitude)
          : null,
    };
  }
  
  /// Dispose and cleanup
  void dispose() {
    stopLocationTracking();
    _isInitialized = false;
    _currentPosition = null;
  }
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isTrackingLocation => _isTrackingLocation;
  Position? get currentPosition => _currentPosition;
}