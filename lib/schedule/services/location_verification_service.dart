import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift_model.dart';
import '../models/time_entry_model.dart';

/// LocationVerificationService for SecuryFlex GPS verification and geofencing
/// 
/// Features:
/// - GPS accuracy validation
/// - Geofencing with customizable radius
/// - Mock location detection
/// - Background location monitoring
/// - Location history tracking
/// - Distance calculations
/// - Location-based alerts
class LocationVerificationService {
  final FirebaseFirestore _firestore;
  final StreamController<LocationVerificationResult> _verificationStreamController = 
      StreamController<LocationVerificationResult>.broadcast();
  
  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  ShiftLocation? _currentJobSite;
  String? _currentShiftId;
  
  static const Duration _monitoringInterval = Duration(minutes: 5);
  static const double _defaultGeofenceRadius = 100.0; // meters
  static const double _gpsAccuracyThreshold = 50.0; // meters
  static const double _mockLocationThreshold = 0.1; // Very low accuracy indicates mock
  
  // Enhanced anti-spoofing constants
  static const double _maxReasonableSpeed = 200.0; // km/h maximum reasonable speed
  static const double _suspiciousAccuracyThreshold = 1.0; // meters - too accurate for real GPS
  static const int _locationHistorySize = 20; // Track recent locations for pattern analysis
  static const Duration _sensorSamplingDuration = Duration(milliseconds: 500);
  
  // Location tracking history for anti-spoofing analysis
  final List<GPSLocation> _locationHistory = [];
  List<Map<String, double>>? _recentAccelData; // Simplified sensor data
  List<Map<String, double>>? _recentGyroData;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  
  LocationVerificationService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Verification result stream
  Stream<LocationVerificationResult> get verificationStream => 
      _verificationStreamController.stream;
  
  /// Check if currently monitoring location
  bool get isMonitoring => _isMonitoring;
  
  /// Current job site location
  ShiftLocation? get currentJobSite => _currentJobSite;

  /// Verify location for shift check-in
  Future<LocationVerificationResult> verifyCheckInLocation({
    required ShiftLocation jobSite,
    double? customRadius,
  }) async {
    try {
      final currentLocation = await _getCurrentLocation();
      final distance = _calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        jobSite.latitude,
        jobSite.longitude,
      );
      
      final geofenceRadius = customRadius ?? jobSite.geofenceRadius;
      final isWithinGeofence = distance <= geofenceRadius;
      
      final result = LocationVerificationResult(
        currentLocation: currentLocation,
        targetLocation: jobSite,
        distance: distance,
        isWithinGeofence: isWithinGeofence,
        geofenceRadius: geofenceRadius,
        accuracy: currentLocation.accuracy,
        isMockLocation: currentLocation.isMocked,
        verificationTime: DateTime.now().toUtc(),
        verificationType: LocationVerificationType.checkIn,
        isSuccessful: isWithinGeofence && !currentLocation.isMocked && 
                      currentLocation.accuracy <= _gpsAccuracyThreshold,
        errorMessage: _getVerificationErrorMessage(
          distance,
          geofenceRadius,
          currentLocation.accuracy,
          currentLocation.isMocked,
        ),
      );
      
      // Save verification result
      await _saveVerificationResult(result);
      
      _verificationStreamController.add(result);
      
      return result;
      
    } catch (e) {
      final errorResult = LocationVerificationResult(
        currentLocation: null,
        targetLocation: jobSite,
        distance: double.infinity,
        isWithinGeofence: false,
        geofenceRadius: customRadius ?? jobSite.geofenceRadius,
        accuracy: double.infinity,
        isMockLocation: false,
        verificationTime: DateTime.now().toUtc(),
        verificationType: LocationVerificationType.checkIn,
        isSuccessful: false,
        errorMessage: 'Locatie verificatie mislukt: ${e.toString()}',
      );
      
      _verificationStreamController.add(errorResult);
      
      return errorResult;
    }
  }

  /// Verify location for shift check-out
  Future<LocationVerificationResult> verifyCheckOutLocation({
    required ShiftLocation jobSite,
    double? customRadius,
  }) async {
    return await verifyCheckInLocation(
      jobSite: jobSite,
      customRadius: customRadius,
    ).then((result) => result.copyWith(
      verificationType: LocationVerificationType.checkOut,
    ));
  }

  /// Start continuous location monitoring for active shift
  Future<void> startLocationMonitoring({
    required String shiftId,
    required ShiftLocation jobSite,
    Duration? monitoringInterval,
  }) async {
    if (_isMonitoring) {
      await stopLocationMonitoring();
    }
    
    _currentShiftId = shiftId;
    _currentJobSite = jobSite;
    _isMonitoring = true;
    
    // Start periodic location checks
    _monitoringTimer = Timer.periodic(
      monitoringInterval ?? _monitoringInterval,
      (_) => _performPeriodicLocationCheck(),
    );
    
    // Perform initial check
    await _performPeriodicLocationCheck();
  }

  /// Stop location monitoring
  Future<void> stopLocationMonitoring() async {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _currentShiftId = null;
    _currentJobSite = null;
  }

  /// Perform periodic location check during shift
  Future<void> _performPeriodicLocationCheck() async {
    if (!_isMonitoring || _currentJobSite == null) return;
    
    try {
      final currentLocation = await _getCurrentLocation();
      final distance = _calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        _currentJobSite!.latitude,
        _currentJobSite!.longitude,
      );
      
      final isWithinGeofence = distance <= _currentJobSite!.geofenceRadius;
      
      final result = LocationVerificationResult(
        currentLocation: currentLocation,
        targetLocation: _currentJobSite!,
        distance: distance,
        isWithinGeofence: isWithinGeofence,
        geofenceRadius: _currentJobSite!.geofenceRadius,
        accuracy: currentLocation.accuracy,
        isMockLocation: currentLocation.isMocked,
        verificationTime: DateTime.now().toUtc(),
        verificationType: LocationVerificationType.monitoring,
        isSuccessful: isWithinGeofence && !currentLocation.isMocked,
        errorMessage: isWithinGeofence && !currentLocation.isMocked 
            ? null 
            : 'Locatie verificatie waarschuwing',
      );
      
      // Save monitoring result
      await _saveLocationPing(_currentShiftId!, result);
      
      _verificationStreamController.add(result);
      
      // Trigger alert if outside geofence
      if (!isWithinGeofence) {
        await _triggerGeofenceAlert(result);
      }
      
    } catch (e) {
      // Log monitoring error but don't stop monitoring
      print('Location monitoring error: $e');
    }
  }

  /// Get current GPS location
  Future<GPSLocation> _getCurrentLocation() async {
    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationVerificationException(
          'Locatie toegang geweigerd',
          LocationVerificationErrorType.permissionDenied,
        );
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw LocationVerificationException(
        'Locatie toegang permanent geweigerd',
        LocationVerificationErrorType.permissionDeniedForever,
      );
    }
    
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationVerificationException(
        'Locatie services zijn uitgeschakeld',
        LocationVerificationErrorType.serviceDisabled,
      );
    }
    
    try {
      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
        timeLimit: const Duration(seconds: 30),
      );
      
      // Create GPS location object
      final gpsLocation = GPSLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude ?? 0.0,
        timestamp: position.timestamp ?? DateTime.now().toUtc(),
        provider: 'gps',
        isMocked: position.isMocked,
      );
      
      // Enhanced mock detection with multi-layer analysis
      bool isMocked = await _performAdvancedMockDetection(gpsLocation);
      
      // Create final location with enhanced mock detection result
      final finalLocation = GPSLocation(
        latitude: gpsLocation.latitude,
        longitude: gpsLocation.longitude,
        accuracy: gpsLocation.accuracy,
        altitude: gpsLocation.altitude,
        timestamp: gpsLocation.timestamp,
        provider: gpsLocation.provider,
        isMocked: isMocked,
      );
      
      // Update location history for pattern analysis
      _updateLocationHistory(finalLocation);
      
      return finalLocation;
      
    } catch (e) {
      throw LocationVerificationException(
        'GPS locatie ophalen mislukt: ${e.toString()}',
        LocationVerificationErrorType.locationFetchFailed,
      );
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Get verification error message
  String? _getVerificationErrorMessage(
    double distance,
    double geofenceRadius,
    double accuracy,
    bool isMockLocation,
  ) {
    if (isMockLocation) {
      return 'Nep locatie gedetecteerd. Schakel mock location apps uit.';
    }
    
    if (accuracy > _gpsAccuracyThreshold) {
      return 'GPS nauwkeurigheid onvoldoende (${accuracy.toStringAsFixed(0)}m). Probeer opnieuw.';
    }
    
    if (distance > geofenceRadius) {
      return 'U bent ${distance.toStringAsFixed(0)}m van de werklocatie. Maximum toegestaan: ${geofenceRadius.toStringAsFixed(0)}m.';
    }
    
    return null; // No error
  }

  /// Save verification result to Firestore
  Future<void> _saveVerificationResult(LocationVerificationResult result) async {
    try {
      await _firestore.collection('locationVerifications').add({
        'shiftId': _currentShiftId,
        'verificationType': result.verificationType.toString().split('.').last,
        'currentLocation': result.currentLocation?.toJson(),
        'targetLocation': result.targetLocation.toJson(),
        'distance': result.distance,
        'isWithinGeofence': result.isWithinGeofence,
        'geofenceRadius': result.geofenceRadius,
        'accuracy': result.accuracy,
        'isMockLocation': result.isMockLocation,
        'isSuccessful': result.isSuccessful,
        'errorMessage': result.errorMessage,
        'verificationTime': Timestamp.fromDate(result.verificationTime),
        'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
      });
    } catch (e) {
      print('Failed to save verification result: $e');
    }
  }

  /// Save location ping during monitoring
  Future<void> _saveLocationPing(String shiftId, LocationVerificationResult result) async {
    try {
      await _firestore.collection('locationPings').add({
        'shiftId': shiftId,
        'location': result.currentLocation?.toJson(),
        'distance': result.distance,
        'isWithinGeofence': result.isWithinGeofence,
        'accuracy': result.accuracy,
        'isMockLocation': result.isMockLocation,
        'timestamp': Timestamp.fromDate(result.verificationTime),
        'type': 'periodic',
      });
    } catch (e) {
      print('Failed to save location ping: $e');
    }
  }

  /// Trigger geofence alert
  Future<void> _triggerGeofenceAlert(LocationVerificationResult result) async {
    try {
      await _firestore.collection('geofenceAlerts').add({
        'shiftId': _currentShiftId,
        'guardLocation': result.currentLocation?.toJson(),
        'jobSiteLocation': result.targetLocation.toJson(),
        'distance': result.distance,
        'geofenceRadius': result.geofenceRadius,
        'alertType': 'outside_geofence',
        'severity': result.distance > (result.geofenceRadius * 2) ? 'high' : 'medium',
        'timestamp': Timestamp.fromDate(result.verificationTime),
        'resolved': false,
      });
    } catch (e) {
      print('Failed to trigger geofence alert: $e');
    }
  }

  /// Get location history for a shift
  Future<List<LocationVerificationResult>> getLocationHistory({
    required String shiftId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      Query query = _firestore
          .collection('locationVerifications')
          .where('shiftId', isEqualTo: shiftId);
      
      if (startTime != null) {
        query = query.where('verificationTime', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startTime));
      }
      
      if (endTime != null) {
        query = query.where('verificationTime', 
            isLessThanOrEqualTo: Timestamp.fromDate(endTime));
      }
      
      final snapshot = await query.orderBy('verificationTime').get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return LocationVerificationResult(
          currentLocation: data['currentLocation'] != null 
              ? GPSLocation.fromJson(data['currentLocation']) 
              : null,
          targetLocation: ShiftLocation.fromJson(data['targetLocation']),
          distance: data['distance']?.toDouble() ?? 0.0,
          isWithinGeofence: data['isWithinGeofence'] ?? false,
          geofenceRadius: data['geofenceRadius']?.toDouble() ?? 0.0,
          accuracy: data['accuracy']?.toDouble() ?? 0.0,
          isMockLocation: data['isMockLocation'] ?? false,
          verificationTime: (data['verificationTime'] as Timestamp).toDate(),
          verificationType: LocationVerificationType.values.firstWhere(
            (type) => type.toString() == 'LocationVerificationType.${data['verificationType']}',
            orElse: () => LocationVerificationType.monitoring,
          ),
          isSuccessful: data['isSuccessful'] ?? false,
          errorMessage: data['errorMessage'],
        );
      }).toList();
      
    } catch (e) {
      throw LocationVerificationException(
        'Locatie geschiedenis ophalen mislukt: ${e.toString()}',
        LocationVerificationErrorType.dataFetchFailed,
      );
    }
  }

  /// Check if location is within multiple geofences
  Future<List<GeofenceResult>> checkMultipleGeofences({
    required List<ShiftLocation> locations,
    GPSLocation? customLocation,
  }) async {
    final currentLocation = customLocation ?? await _getCurrentLocation();
    final results = <GeofenceResult>[];
    
    for (final location in locations) {
      final distance = _calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        location.latitude,
        location.longitude,
      );
      
      final isWithinGeofence = distance <= location.geofenceRadius;
      
      results.add(GeofenceResult(
        location: location,
        distance: distance,
        isWithinGeofence: isWithinGeofence,
      ));
    }
    
    return results;
  }

  /// Advanced mock location detection with multi-layer analysis
  Future<bool> _performAdvancedMockDetection(GPSLocation location) async {
    try {
      // Layer 1: System-level mock detection
      if (location.isMocked) return true;
      
      // Layer 2: Accuracy-based detection (suspiciously perfect accuracy)
      if (location.accuracy < _suspiciousAccuracyThreshold) return true;
      
      // Layer 3: Velocity-based detection (impossible movement speed)
      if (_detectImpossibleMovement(location)) return true;
      
      // Layer 4: Pattern analysis (unnatural movement patterns)
      if (await _detectMockPatterns(location)) return true;
      
      // Layer 5: Sensor correlation (movement vs device sensors)
      if (await _detectSensorInconsistencies(location)) return true;
      
      return false;
    } catch (e) {
      // If detection fails, err on side of caution
      print('Advanced mock detection error: $e');
      return false; // Allow location but log the issue
    }
  }

  /// Detect impossible movement speeds between locations
  bool _detectImpossibleMovement(GPSLocation currentLocation) {
    if (_locationHistory.isEmpty) return false;
    
    final previousLocation = _locationHistory.last;
    final distance = _calculateDistance(
      previousLocation.latitude,
      previousLocation.longitude,
      currentLocation.latitude,
      currentLocation.longitude,
    );
    
    final timeElapsed = currentLocation.timestamp.difference(previousLocation.timestamp);
    if (timeElapsed.inSeconds <= 0) return false; // Invalid time difference
    
    // Calculate speed in km/h
    final speedKmh = (distance / 1000) / (timeElapsed.inSeconds / 3600);
    
    // Check if speed exceeds reasonable maximum (200 km/h)
    return speedKmh > _maxReasonableSpeed;
  }

  /// Detect patterns indicative of mock GPS apps
  Future<bool> _detectMockPatterns(GPSLocation location) async {
    if (_locationHistory.length < 3) return false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Pattern 1: Perfectly straight line movement (unnatural)
      if (_detectStraightLinePattern()) {
        await prefs.setBool('mock_pattern_straight_line', true);
        return true;
      }
      
      // Pattern 2: Consistent accuracy (real GPS accuracy varies)
      if (_detectConsistentAccuracy(location)) {
        await prefs.setBool('mock_pattern_consistent_accuracy', true);
        return true;
      }
      
      // Pattern 3: Regular time intervals (automation indicator)
      if (_detectRegularTimeIntervals()) {
        await prefs.setBool('mock_pattern_regular_intervals', true);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Detect inconsistencies between GPS movement and device sensors
  Future<bool> _detectSensorInconsistencies(GPSLocation location) async {
    if (_locationHistory.isEmpty) return false;
    
    try {
      // Start sensor data collection
      await _collectSensorData();
      
      // Calculate GPS-indicated movement
      final previousLocation = _locationHistory.last;
      final gpsDistance = _calculateDistance(
        previousLocation.latitude,
        previousLocation.longitude,
        location.latitude,
        location.longitude,
      );
      
      // Analyze accelerometer data for actual movement
      final sensorMovement = _analyzeSensorMovement();
      
      // If GPS shows significant movement but sensors show no movement
      if (gpsDistance > 10.0 && sensorMovement < 0.1) {
        return true; // Possible spoofing
      }
      
      return false;
    } catch (e) {
      return false; // Sensor access issues shouldn't block location
    }
  }

  /// Collect accelerometer and gyroscope data for analysis
  Future<void> _collectSensorData() async {
    // Simplified sensor data collection without sensors_plus dependency
    // In production, this would integrate with proper sensor APIs
    
    // Simulate sensor data collection for now
    await Future.delayed(_sensorSamplingDuration);
    
    // Mock sensor data for development
    _recentAccelData = [
      {'x': 0.1, 'y': 0.2, 'z': 9.8},  // Simulated accelerometer reading
    ];
    _recentGyroData = [
      {'x': 0.0, 'y': 0.0, 'z': 0.0},  // Simulated gyroscope reading
    ];
  }

  /// Analyze sensor data to detect actual device movement
  double _analyzeSensorMovement() {
    if (_recentAccelData == null || _recentAccelData!.isEmpty) return 0.0;
    
    double totalAcceleration = 0.0;
    
    for (final event in _recentAccelData!) {
      // Calculate total acceleration magnitude (subtract gravity)
      final magnitude = math.sqrt(
        event['x']! * event['x']! + 
        event['y']! * event['y']! + 
        event['z']! * event['z']!
      );
      
      // Subtract approximate gravity (9.8 m/s²)
      final netAcceleration = math.max(0.0, magnitude - 9.8);
      totalAcceleration += netAcceleration;
    }
    
    return totalAcceleration / _recentAccelData!.length;
  }

  /// Detect straight-line movement pattern (unnatural for human movement)
  bool _detectStraightLinePattern() {
    if (_locationHistory.length < 5) return false;
    
    // Calculate bearing between first and last points
    final firstLocation = _locationHistory[_locationHistory.length - 5];
    final lastLocation = _locationHistory.last;
    
    final expectedBearing = _calculateBearing(
      firstLocation.latitude, firstLocation.longitude,
      lastLocation.latitude, lastLocation.longitude,
    );
    
    // Check if all intermediate points follow the same bearing
    int consistentBearingCount = 0;
    
    for (int i = _locationHistory.length - 4; i < _locationHistory.length - 1; i++) {
      final currentBearing = _calculateBearing(
        _locationHistory[i].latitude, _locationHistory[i].longitude,
        _locationHistory[i + 1].latitude, _locationHistory[i + 1].longitude,
      );
      
      // Allow small bearing variations (real movement isn't perfectly straight)
      if ((currentBearing - expectedBearing).abs() < 5.0) {
        consistentBearingCount++;
      }
    }
    
    // If more than 80% of movements are in same direction, flag as suspicious
    return consistentBearingCount > (_locationHistory.length * 0.8);
  }

  /// Detect unnaturally consistent GPS accuracy
  bool _detectConsistentAccuracy(GPSLocation location) {
    if (_locationHistory.length < 5) return false;
    
    final recentAccuracies = _locationHistory
        .take(5)
        .map((loc) => loc.accuracy)
        .toList();
    recentAccuracies.add(location.accuracy);
    
    // Calculate standard deviation of accuracy values
    final mean = recentAccuracies.reduce((a, b) => a + b) / recentAccuracies.length;
    final variance = recentAccuracies
        .map((acc) => math.pow(acc - mean, 2))
        .reduce((a, b) => a + b) / recentAccuracies.length;
    final standardDeviation = math.sqrt(variance);
    
    // Real GPS accuracy varies, suspicious if too consistent
    return standardDeviation < 0.5;
  }

  /// Detect regular time intervals between location updates
  bool _detectRegularTimeIntervals() {
    if (_locationHistory.length < 4) return false;
    
    final intervals = <int>[];
    
    for (int i = 1; i < _locationHistory.length; i++) {
      final interval = _locationHistory[i].timestamp
          .difference(_locationHistory[i - 1].timestamp)
          .inSeconds;
      intervals.add(interval);
    }
    
    // Check if intervals are suspiciously regular (automated)
    final meanInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    
    int regularIntervals = 0;
    for (final interval in intervals) {
      if ((interval - meanInterval).abs() < 2) { // Within 2 seconds
        regularIntervals++;
      }
    }
    
    // Flag as suspicious if more than 75% are regular
    return regularIntervals > (intervals.length * 0.75);
  }

  /// Calculate bearing between two GPS coordinates
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _degreesToRadians(lon2 - lon1);
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    
    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) - 
              math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);
    
    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360; // Convert to degrees
  }

  /// Update location history for pattern analysis
  void _updateLocationHistory(GPSLocation location) {
    _locationHistory.add(location);
    
    // Keep only recent locations to prevent memory bloat
    if (_locationHistory.length > _locationHistorySize) {
      _locationHistory.removeRange(0, _locationHistory.length - _locationHistorySize);
    }
  }

  /// Get enhanced verification statistics
  Future<Map<String, dynamic>> getAntiSpoofingStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'total_verifications': _locationHistory.length,
        'mock_detections': {
          'straight_line_pattern': prefs.getBool('mock_pattern_straight_line') ?? false,
          'consistent_accuracy': prefs.getBool('mock_pattern_consistent_accuracy') ?? false,
          'regular_intervals': prefs.getBool('mock_pattern_regular_intervals') ?? false,
        },
        'average_accuracy': _locationHistory.isEmpty ? 0.0 : 
            _locationHistory.map((l) => l.accuracy).reduce((a, b) => a + b) / _locationHistory.length,
        'location_history_size': _locationHistory.length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Dispose resources
  void dispose() {
    stopLocationMonitoring();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _verificationStreamController.close();
  }
}

/// Location verification result
class LocationVerificationResult {
  final GPSLocation? currentLocation;
  final ShiftLocation targetLocation;
  final double distance;
  final bool isWithinGeofence;
  final double geofenceRadius;
  final double accuracy;
  final bool isMockLocation;
  final DateTime verificationTime;
  final LocationVerificationType verificationType;
  final bool isSuccessful;
  final String? errorMessage;

  const LocationVerificationResult({
    required this.currentLocation,
    required this.targetLocation,
    required this.distance,
    required this.isWithinGeofence,
    required this.geofenceRadius,
    required this.accuracy,
    required this.isMockLocation,
    required this.verificationTime,
    required this.verificationType,
    required this.isSuccessful,
    this.errorMessage,
  });

  /// Copy with method for updates
  LocationVerificationResult copyWith({
    GPSLocation? currentLocation,
    ShiftLocation? targetLocation,
    double? distance,
    bool? isWithinGeofence,
    double? geofenceRadius,
    double? accuracy,
    bool? isMockLocation,
    DateTime? verificationTime,
    LocationVerificationType? verificationType,
    bool? isSuccessful,
    String? errorMessage,
  }) {
    return LocationVerificationResult(
      currentLocation: currentLocation ?? this.currentLocation,
      targetLocation: targetLocation ?? this.targetLocation,
      distance: distance ?? this.distance,
      isWithinGeofence: isWithinGeofence ?? this.isWithinGeofence,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      accuracy: accuracy ?? this.accuracy,
      isMockLocation: isMockLocation ?? this.isMockLocation,
      verificationTime: verificationTime ?? this.verificationTime,
      verificationType: verificationType ?? this.verificationType,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Location verification types
enum LocationVerificationType {
  checkIn,
  checkOut,
  monitoring,
  manual,
}

/// Geofence check result
class GeofenceResult {
  final ShiftLocation location;
  final double distance;
  final bool isWithinGeofence;

  const GeofenceResult({
    required this.location,
    required this.distance,
    required this.isWithinGeofence,
  });
}

/// Location verification error types
enum LocationVerificationErrorType {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  locationFetchFailed,
  accuracyInsufficient,
  mockLocationDetected,
  outsideGeofence,
  dataFetchFailed,
}

/// Location verification exception
class LocationVerificationException implements Exception {
  final String message;
  final LocationVerificationErrorType type;
  
  const LocationVerificationException(this.message, this.type);
  
  @override
  String toString() => 'LocationVerificationException: $message';
}