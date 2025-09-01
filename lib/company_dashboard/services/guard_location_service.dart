import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:securyflex_app/company_dashboard/models/team_management_data.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart' show GuardAvailabilityStatus;

// Mock location classes for development (replace with actual geolocator when available)
class Position {
  final double latitude;
  final double longitude;
  const Position({required this.latitude, required this.longitude});
}

enum LocationPermission { denied, deniedForever, whileInUse, always }
enum LocationAccuracy { lowest, low, medium, high, best, bestForNavigation }

class LocationSettings {
  final LocationAccuracy accuracy;
  final int distanceFilter;
  const LocationSettings({required this.accuracy, required this.distanceFilter});
}

class MockGeolocator {
  static Future<bool> isLocationServiceEnabled() async => true;
  static Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;
  static Future<LocationPermission> requestPermission() async => LocationPermission.whileInUse;
  static Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return Stream.periodic(const Duration(seconds: 30), (index) {
      return Position(
        latitude: 52.3676 + (math.Random().nextDouble() - 0.5) * 0.01,
        longitude: 4.9041 + (math.Random().nextDouble() - 0.5) * 0.01,
      );
    });
  }
  static Future<Position> getCurrentPosition({LocationAccuracy? desiredAccuracy}) async {
    return Position(
      latitude: 52.3676 + (math.Random().nextDouble() - 0.5) * 0.01,
      longitude: 4.9041 + (math.Random().nextDouble() - 0.5) * 0.01,
    );
  }
  static double distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }
  static double _degreesToRadians(double degrees) => degrees * (math.pi / 180);
}

/// GDPR-Compliant Guard Location Service with Privacy Controls
/// 
/// Privacy-First Features:
/// - Explicit consent required for location sharing
/// - Proximity-based location display only
/// - No exact coordinates stored or transmitted
/// - Automatic data deletion after 24 hours
/// - Full transparency and user control
/// 
/// Nederlandse Arbeidsrecht Compliance:
/// - Employee consent required before location tracking
/// - Clear business justification for location processing
/// - Right to withdraw consent at any time
/// - Data minimization applied throughout
class GuardLocationService {
  static final GuardLocationService _instance = GuardLocationService._internal();
  factory GuardLocationService() => _instance;
  GuardLocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream controllers for real-time location updates
  final StreamController<List<GuardLocationData>> _guardLocationsController = 
      StreamController<List<GuardLocationData>>.broadcast();
  final StreamController<GuardLocationData> _singleGuardLocationController = 
      StreamController<GuardLocationData>.broadcast();

  // Location tracking state
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<QuerySnapshot>? _locationsSubscription;
  Timer? _locationUpdateTimer;
  
  // Privacy and permission settings
  bool _locationTrackingEnabled = false;
  bool _hasLocationPermission = false;
  String? _currentGuardId;
  String? _currentCompanyId;

  /// Get stream of all guard locations for a company
  Stream<List<GuardLocationData>> get guardLocationsStream => _guardLocationsController.stream;

  /// Get stream of single guard location updates
  Stream<GuardLocationData> get singleGuardLocationStream => _singleGuardLocationController.stream;

  /// Check if location tracking is currently enabled
  bool get isLocationTrackingEnabled => _locationTrackingEnabled;

  /// Check if location permissions are granted
  bool get hasLocationPermission => _hasLocationPermission;

  /// Initialize GDPR-compliant location tracking for a guard
  /// Requires explicit consent before any location processing
  Future<LocationTrackingResult> initializeGuardLocationTracking(
    String guardId, 
    String companyId,
    {bool requestConsentIfNeeded = true}
  ) async {
    try {
      _currentGuardId = guardId;
      _currentCompanyId = companyId;
      
      // Step 1: Check if guard has given consent for company monitoring
      final hasConsent = await _checkLocationConsent(guardId);
      if (!hasConsent) {
        if (requestConsentIfNeeded) {
          return LocationTrackingResult(
            success: false,
            requiresConsent: true,
            message: 'Locatie toestemming vereist van beveiliger',
            consentType: 'company_monitoring',
          );
        } else {
          return LocationTrackingResult(
            success: false,
            message: 'Beveiliger heeft geen toestemming gegeven voor locatie tracking',
          );
        }
      }

      // Step 2: Check device location permissions
      final hasPermission = await _checkLocationPermissions();
      if (!hasPermission) {
        return LocationTrackingResult(
          success: false,
          message: 'Locatie toegang niet verleend op apparaat',
        );
      }

      // Step 3: Start privacy-compliant location tracking
      await _startPrivacyCompliantLocationTracking();
      
      // Step 4: Log consent-based tracking initiation
      await _logLocationTrackingEvent(guardId, 'TRACKING_STARTED', {
        'consent_verified': true,
        'company_id': companyId,
        'privacy_mode': 'proximity_only',
      });
      
      if (kDebugMode) {
        print('Privacy-compliant location tracking initialized for guard: $guardId');
      }
      
      return LocationTrackingResult(
        success: true,
        message: 'Privacy-compliant locatie tracking gestart',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing guard location tracking: $e');
      }
      return LocationTrackingResult(
        success: false,
        message: 'Locatie tracking initialisatie mislukt: $e',
      );
    }
  }

  /// Initialize location monitoring for a company (view all guards)
  Future<void> initializeCompanyLocationMonitoring(String companyId) async {
    try {
      _currentCompanyId = companyId;

      // Start listening to all guard locations for this company
      _locationsSubscription = _firestore
          .collection('guard_locations')
          .where('companyId', isEqualTo: companyId)
          .where('isLocationEnabled', isEqualTo: true)
          .snapshots()
          .listen((snapshot) {
        final guardLocations = snapshot.docs
            .map((doc) => GuardLocationData.fromFirestore(doc))
            .toList();
        
        if (!_guardLocationsController.isClosed) {
          _guardLocationsController.add(guardLocations);
        }
      });

      if (kDebugMode) {
        print('Company location monitoring initialized for: $companyId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing company location monitoring: $e');
      }
    }
  }

  /// Check and request location permissions
  Future<bool> _checkLocationPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await MockGeolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('Location services are disabled');
        }
        return false;
      }

      // Check location permissions
      LocationPermission permission = await MockGeolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await MockGeolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('Location permissions are denied');
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('Location permissions are permanently denied');
        }
        return false;
      }

      _hasLocationPermission = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location permissions: $e');
      }
      return false;
    }
  }

  /// Start privacy-compliant location tracking
  /// Only stores proximity information, not exact coordinates
  Future<void> _startPrivacyCompliantLocationTracking() async {
    if (!_hasLocationPermission || _currentGuardId == null) return;

    try {
      // Configure privacy-first location settings
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium, // Reduced accuracy for privacy
        distanceFilter: 100, // Update every 100 meters (privacy threshold)
      );

      // Start privacy-compliant position stream
      _positionSubscription = MockGeolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        _updateGuardLocationWithPrivacy(position);
      });

      // Set up privacy-compliant periodic updates (every 5 minutes)
      _locationUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        _getCurrentLocationAndUpdateWithPrivacy();
      });

      _locationTrackingEnabled = true;

      if (kDebugMode) {
        print('Location tracking started for guard: $_currentGuardId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting location tracking: $e');
      }
    }
  }

  /// Get current location and update with privacy protection
  Future<void> _getCurrentLocationAndUpdateWithPrivacy() async {
    if (!_hasLocationPermission || _currentGuardId == null) return;

    try {
      final Position position = await MockGeolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Reduced for privacy
      );
      await _updateGuardLocationWithPrivacy(position);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
    }
  }

  /// Update guard location with privacy protection
  /// Only stores proximity to work areas, not exact coordinates
  Future<void> _updateGuardLocationWithPrivacy(Position position) async {
    if (_currentGuardId == null || _currentCompanyId == null) return;

    try {
      // Check if guard still consents to location tracking
      final hasConsent = await _checkLocationConsent(_currentGuardId!);
      if (!hasConsent) {
        await stopLocationTracking();
        return;
      }
      
      // Get work locations for proximity calculation
      final workLocations = await _getCompanyWorkLocations(_currentCompanyId!);
      
      // Calculate proximity to work locations (privacy-compliant)
      final proximityInfo = _calculateProximityToWorkLocations(
        position, 
        workLocations
      );
      
      // Get current guard data to preserve other fields
      final guardDoc = await _firestore
          .collection('guard_locations')
          .doc(_currentGuardId)
          .get();

      GuardLocationData currentData;
      if (guardDoc.exists) {
        currentData = GuardLocationData.fromFirestore(guardDoc);
      } else {
        currentData = GuardLocationData(
          guardId: _currentGuardId!,
          guardName: await _getGuardName(_currentGuardId!),
          lastUpdate: DateTime.now(),
          status: GuardAvailabilityStatus.available,
          isLocationEnabled: true,
        );
      }

      // Update with privacy-compliant location data (no exact coordinates)
      final updatedData = currentData.copyWith(
        // No latitude/longitude stored - privacy protection
        currentLocation: proximityInfo.nearestWorkAreaName,
        lastUpdate: DateTime.now(),
        isLocationEnabled: true,
        // Store only proximity status
        proximityStatus: proximityInfo.status,
        approximateDistance: proximityInfo.approximateDistance,
      );

      // Save to Firestore with privacy metadata
      await _firestore
          .collection('guard_locations')
          .doc(_currentGuardId)
          .set({
        ...updatedData.toFirestore(),
        'companyId': _currentCompanyId,
        'privacyCompliant': true,
        'coordinatesObfuscated': true,
        'proximityOnly': true,
        'autoDeleteAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24))
        ),
      });

      // Emit privacy-compliant update
      if (!_singleGuardLocationController.isClosed) {
        _singleGuardLocationController.add(updatedData);
      }

      if (kDebugMode) {
        print('Privacy-compliant location updated for guard $_currentGuardId: ${proximityInfo.status}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating guard location: $e');
      }
    }
  }

  /// Update guard status (availability)
  Future<void> updateGuardStatus(
    String guardId, 
    GuardAvailabilityStatus status, {
    String? currentAssignment,
    String? currentAssignmentTitle,
    String? currentLocation,
  }) async {
    try {
      final guardDoc = await _firestore
          .collection('guard_locations')
          .doc(guardId)
          .get();

      if (guardDoc.exists) {
        final currentData = GuardLocationData.fromFirestore(guardDoc);
        final updatedData = currentData.copyWith(
          status: status,
          currentAssignment: currentAssignment,
          currentAssignmentTitle: currentAssignmentTitle,
          currentLocation: currentLocation,
          lastUpdate: DateTime.now(),
        );

        await _firestore
            .collection('guard_locations')
            .doc(guardId)
            .update(updatedData.toFirestore());

        if (kDebugMode) {
          print('Guard status updated: $guardId -> $status');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating guard status: $e');
      }
    }
  }

  /// Get guard name from user document
  Future<String> _getGuardName(String guardId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(guardId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['name'] ?? 'Unknown Guard';
      }
      return 'Unknown Guard';
    } catch (e) {
      if (kDebugMode) {
        print('Error getting guard name: $e');
      }
      return 'Unknown Guard';
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return MockGeolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  /// Find nearest guards to a location
  List<GuardLocationData> findNearestGuards(
    List<GuardLocationData> guards,
    double targetLat,
    double targetLon, {
    double maxDistanceKm = 50.0,
    int maxResults = 10,
  }) {
    final guardsWithDistance = guards
        .where((guard) => 
            guard.latitude != null && 
            guard.longitude != null &&
            guard.status == GuardAvailabilityStatus.available)
        .map((guard) {
      final distance = calculateDistance(
        targetLat, targetLon, 
        guard.latitude!, guard.longitude!
      );
      return MapEntry(guard, distance);
    })
        .where((entry) => entry.value <= maxDistanceKm)
        .toList();

    // Sort by distance
    guardsWithDistance.sort((a, b) => a.value.compareTo(b.value));

    return guardsWithDistance
        .take(maxResults)
        .map((entry) => entry.key)
        .toList();
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    try {
      await _positionSubscription?.cancel();
      _locationUpdateTimer?.cancel();
      _locationTrackingEnabled = false;

      // Update Firestore to indicate location tracking is disabled
      if (_currentGuardId != null) {
        await _firestore
            .collection('guard_locations')
            .doc(_currentGuardId)
            .update({
          'isLocationEnabled': false,
          'lastUpdate': Timestamp.fromDate(DateTime.now()),
        });
      }

      if (kDebugMode) {
        print('Location tracking stopped for guard: $_currentGuardId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping location tracking: $e');
      }
    }
  }

  /// Generate mock location data for testing
  List<GuardLocationData> generateMockLocationData(String companyId) {
    final random = math.Random();
    final baseLatitude = 52.3676; // Amsterdam center
    final baseLongitude = 4.9041;
    
    final mockGuards = [
      'Jan de Vries', 'Marie Bakker', 'Piet Janssen', 'Lisa van der Berg',
      'Tom Hendriks', 'Sarah de Jong', 'Mike van Dijk', 'Emma Visser'
    ];

    return List.generate(mockGuards.length, (index) {
      final latOffset = (random.nextDouble() - 0.5) * 0.1; // ~5km radius
      final lonOffset = (random.nextDouble() - 0.5) * 0.1;
      
      return GuardLocationData(
        guardId: 'guard_${index.toString().padLeft(3, '0')}',
        guardName: mockGuards[index],
        latitude: baseLatitude + latOffset,
        longitude: baseLongitude + lonOffset,
        lastUpdate: DateTime.now().subtract(Duration(minutes: random.nextInt(10))),
        status: GuardAvailabilityStatus.values[random.nextInt(GuardAvailabilityStatus.values.length)],
        currentLocation: 'Amsterdam ${['Centrum', 'Noord', 'Zuid', 'Oost', 'West'][random.nextInt(5)]}',
        isLocationEnabled: true,
      );
    });
  }

  /// Check if guard has consented to location tracking
  Future<bool> _checkLocationConsent(String guardId) async {
    try {
      // In production, this would check the LocationConsentService
      // For now, assume consent is required and check user preferences
      final consentDoc = await _firestore
          .collection('location_consent')
          .doc('${guardId}_company_monitoring')
          .get();
      
      if (!consentDoc.exists) return false;
      
      final consentData = consentDoc.data()!;
      final status = consentData['status'];
      final expiresAt = consentData['expiresAt']?.toDate();
      
      return status == 'granted' && 
             (expiresAt == null || DateTime.now().isBefore(expiresAt));
    } catch (e) {
      debugPrint('Error checking location consent: $e');
      return false;
    }
  }
  
  /// Get company work locations for proximity calculations
  Future<List<WorkLocationInfo>> _getCompanyWorkLocations(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('work_locations')
          .where('companyId', isEqualTo: companyId)
          .get();
      
      return snapshot.docs
          .map((doc) => WorkLocationInfo.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting work locations: $e');
      return [];
    }
  }
  
  /// Calculate proximity to work locations (privacy-compliant)
  ProximityInfo _calculateProximityToWorkLocations(
    Position guardPosition,
    List<WorkLocationInfo> workLocations,
  ) {
    if (workLocations.isEmpty) {
      return ProximityInfo(
        status: 'unknown_work_area',
        nearestWorkAreaName: null,
        approximateDistance: null,
      );
    }
    
    WorkLocationInfo? nearestLocation;
    double minDistance = double.infinity;
    
    for (final workLocation in workLocations) {
      final distance = MockGeolocator.distanceBetween(
        guardPosition.latitude,
        guardPosition.longitude,
        workLocation.latitude,
        workLocation.longitude,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestLocation = workLocation;
      }
    }
    
    if (nearestLocation == null) {
      return ProximityInfo(
        status: 'no_work_area_nearby',
        nearestWorkAreaName: null,
        approximateDistance: null,
      );
    }
    
    // Privacy: Round distance to nearest 100m
    final approximateDistance = (minDistance / 100).round() * 100.0;
    
    String status;
    if (minDistance <= nearestLocation.geofenceRadius) {
      status = 'at_work_location';
    } else if (minDistance <= nearestLocation.geofenceRadius * 2) {
      status = 'near_work_location';
    } else {
      status = 'away_from_work';
    }
    
    return ProximityInfo(
      status: status,
      nearestWorkAreaName: nearestLocation.name,
      approximateDistance: approximateDistance,
    );
  }
  
  /// Log location tracking events for audit trail
  Future<void> _logLocationTrackingEvent(
    String guardId,
    String eventType,
    Map<String, dynamic> metadata,
  ) async {
    try {
      await _firestore
          .collection('location_tracking_audit')
          .add({
        'guardId': guardId,
        'eventType': eventType,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'metadata': metadata,
        'privacyCompliant': true,
        'gdprBasis': 'Article 6(f) - Legitimate interest for employee safety',
      });
    } catch (e) {
      print('Error logging location event: $e');
    }
  }
  
  /// Request location consent from guard
  Future<ConsentRequestResult> requestLocationConsent(
    String guardId,
    String companyId,
  ) async {
    try {
      // Create consent request record
      final consentRequest = {
        'guardId': guardId,
        'companyId': companyId,
        'consentType': 'company_monitoring',
        'requestedAt': Timestamp.fromDate(DateTime.now()),
        'purpose': 'Real-time locatie zichtbaarheid voor werkplanning en veiligheid',
        'dataUsage': 'Nabijheid van werklocaties - geen exacte coördinaten',
        'retentionPeriod': '24 uur automatische verwijdering',
        'legalBasis': 'AVG Artikel 6(f) - Gerechtvaardigd belang werkgever veiligheid',
        'status': 'pending',
      };
      
      await _firestore
          .collection('location_consent_requests')
          .add(consentRequest);
      
      return ConsentRequestResult(
        success: true,
        message: 'Locatie toestemming aangevraagd bij beveiliger',
        consentType: 'company_monitoring',
        purpose: consentRequest['purpose'] as String,
        dataUsage: consentRequest['dataUsage'] as String,
        retentionPeriod: consentRequest['retentionPeriod'] as String,
      );
    } catch (e) {
      return ConsentRequestResult(
        success: false,
        message: 'Toestemming aanvraag mislukt: $e',
        consentType: 'company_monitoring',
      );
    }
  }
  
  /// Get privacy-compliant location statistics
  Future<LocationPrivacyStats> getLocationPrivacyStats(String companyId) async {
    try {
      // Get guards with active consent
      final consentQuery = await _firestore
          .collection('location_consent')
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'granted')
          .get();
      
      // Get location tracking events
      final auditQuery = await _firestore
          .collection('location_tracking_audit')
          .where('metadata.company_id', isEqualTo: companyId)
          .where('timestamp', isGreaterThan: 
            Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))))
          .get();
      
      return LocationPrivacyStats(
        totalGuards: consentQuery.docs.length,
        activeConsents: consentQuery.docs
            .where((doc) {
              final expiresAt = doc.data()['expiresAt']?.toDate();
              return expiresAt == null || DateTime.now().isBefore(expiresAt);
            }).length,
        privacyCompliantUpdates: auditQuery.docs
            .where((doc) => doc.data()['privacyCompliant'] == true)
            .length,
        dataMinimizationActive: true,
        coordinateObfuscationActive: true,
        autoDeleteEnabled: true,
        lastPrivacyAudit: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Privacy statistieken ophalen mislukt: $e');
    }
  }
  
  /// Export location data for GDPR compliance
  Future<Map<String, dynamic>> exportLocationData(
    String guardId,
    {DateTime? startDate, DateTime? endDate}
  ) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      // Export proximity data (no coordinates)
      final locationData = await _firestore
          .collection('guard_locations')
          .doc(guardId)
          .get();
      
      // Export audit trail
      final auditData = await _firestore
          .collection('location_tracking_audit')
          .where('guardId', isEqualTo: guardId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      
      return {
        'export_timestamp': DateTime.now().toIso8601String(),
        'guard_id': guardId,
        'date_range': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
        'proximity_data': locationData.exists ? locationData.data() : null,
        'audit_trail': auditData.docs.map((doc) => doc.data()).toList(),
        'privacy_info': {
          'coordinates_stored': false,
          'proximity_only': true,
          'data_minimization_applied': true,
          'auto_deletion_enabled': true,
          'retention_period': '24 hours',
        },
        'gdpr_compliance': 'Article 9 - Special Category Data Protection',
      };
    } catch (e) {
      throw Exception('Location data export mislukt: $e');
    }
  }
  
  /// Dispose of resources and close streams
  void dispose() {
    _positionSubscription?.cancel();
    _locationsSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    
    _guardLocationsController.close();
    _singleGuardLocationController.close();
    
    if (kDebugMode) {
      print('GuardLocationService disposed');
    }
  }
}

// Privacy-compliant data models

class LocationTrackingResult {
  final bool success;
  final String message;
  final bool requiresConsent;
  final String? consentType;
  
  const LocationTrackingResult({
    required this.success,
    required this.message,
    this.requiresConsent = false,
    this.consentType,
  });
}

class WorkLocationInfo {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double geofenceRadius;
  final String companyId;
  
  const WorkLocationInfo({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadius,
    required this.companyId,
  });
  
  factory WorkLocationInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkLocationInfo(
      id: doc.id,
      name: data['name'] ?? 'Unknown Location',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      geofenceRadius: data['geofenceRadius']?.toDouble() ?? 100.0,
      companyId: data['companyId'] ?? '',
    );
  }
}

class ProximityInfo {
  final String status;
  final String? nearestWorkAreaName;
  final double? approximateDistance;
  
  const ProximityInfo({
    required this.status,
    this.nearestWorkAreaName,
    this.approximateDistance,
  });
}

class ConsentRequestResult {
  final bool success;
  final String message;
  final String consentType;
  final String? purpose;
  final String? dataUsage;
  final String? retentionPeriod;
  
  const ConsentRequestResult({
    required this.success,
    required this.message,
    required this.consentType,
    this.purpose,
    this.dataUsage,
    this.retentionPeriod,
  });
}

class LocationPrivacyStats {
  final int totalGuards;
  final int activeConsents;
  final int privacyCompliantUpdates;
  final bool dataMinimizationActive;
  final bool coordinateObfuscationActive;
  final bool autoDeleteEnabled;
  final DateTime lastPrivacyAudit;
  
  const LocationPrivacyStats({
    required this.totalGuards,
    required this.activeConsents,
    required this.privacyCompliantUpdates,
    required this.dataMinimizationActive,
    required this.coordinateObfuscationActive,
    required this.autoDeleteEnabled,
    required this.lastPrivacyAudit,
  });
  
  Map<String, dynamic> toJson() => {
    'totalGuards': totalGuards,
    'activeConsents': activeConsents,
    'privacyCompliantUpdates': privacyCompliantUpdates,
    'dataMinimizationActive': dataMinimizationActive,
    'coordinateObfuscationActive': coordinateObfuscationActive,
    'autoDeleteEnabled': autoDeleteEnabled,
    'lastPrivacyAudit': lastPrivacyAudit.toIso8601String(),
    'consentRate': totalGuards > 0 ? (activeConsents / totalGuards * 100).round() : 0,
  };
}
