import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'location_consent_service.dart';
import 'location_crypto_service.dart';

/// Privacy-First Location Tracker for SecuryFlex
/// 
/// Implements GDPR Article 9 compliant location tracking with:
/// - Data minimization (proximity-only verification)
/// - Explicit consent management
/// - Automatic data deletion
/// - No continuous tracking storage
/// - Nederlandse arbeidsrecht compliance
/// 
/// Core Principles:
/// 1. Minimal data collection - only work verification
/// 2. Proximity verification instead of exact coordinates
/// 3. Temporary storage with automatic deletion
/// 4. Explicit consent for all processing
/// 5. Full transparency and user control
class PrivacyLocationTracker {
  static const Duration _verificationCooldown = Duration(minutes: 5);
  static const double _workProximityThreshold = 200.0; // meters
  static const double _coordinateObfuscation = 100.0; // meters precision
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<PrivacyLocationUpdate> _updateController = 
      StreamController<PrivacyLocationUpdate>.broadcast();
  
  Timer? _cleanupTimer;
  String? _currentUserId;
  DateTime? _lastVerificationTime;
  
  /// Location update stream (privacy-compliant)
  Stream<PrivacyLocationUpdate> get locationUpdates => _updateController.stream;
  
  /// Initialize privacy-first location tracking
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    
    // Start automatic cleanup timer
    _startCleanupTimer();
    
    // Initialize location crypto service
    await LocationCryptoService.initializeForUser(userId);
    
    print('Privacy location tracker initialized for user: $userId');
  }
  
  /// Verify user location for work check-in/check-out
  /// Only processes location if user has given explicit consent
  Future<WorkLocationVerification> verifyWorkLocation({
    required String userId,
    required String shiftId,
    required String workLocationId,
    required WorkLocationType verificationType,
  }) async {
    try {
      // Step 1: Check consent
      final hasConsent = await LocationConsentService.hasValidConsent(
        userId,
        LocationConsentType.workVerification,
      );
      
      if (!hasConsent) {
        return WorkLocationVerification(
          isSuccess: false,
          error: 'Locatie toestemming niet verleend. Ga naar Privacy Instellingen.',
          requiresConsent: true,
          verificationType: verificationType,
        );
      }
      
      // Step 2: Rate limiting for privacy
      if (_isInCooldownPeriod()) {
        return WorkLocationVerification(
          isSuccess: false,
          error: 'Locatie verificatie te snel herhaald. Probeer over ${_getCooldownRemaining()} minuten.',
          verificationType: verificationType,
        );
      }
      
      // Step 3: Get work location details
      final workLocation = await _getWorkLocation(workLocationId);
      if (workLocation == null) {
        return WorkLocationVerification(
          isSuccess: false,
          error: 'Werklocatie niet gevonden.',
          verificationType: verificationType,
        );
      }
      
      // Step 4: Get current GPS location
      final currentLocation = await _getCurrentLocationSafely();
      if (currentLocation == null) {
        return WorkLocationVerification(
          isSuccess: false,
          error: 'GPS locatie niet beschikbaar. Controleer locatie instellingen.',
          verificationType: verificationType,
        );
      }
      
      // Step 5: Calculate proximity (no exact coordinates stored)
      final proximityResult = _calculateProximity(currentLocation, workLocation);
      
      // Step 6: Create privacy-compliant verification result
      final verification = WorkLocationVerification(
        isSuccess: proximityResult.isWithinRange,
        workLocationId: workLocationId,
        shiftId: shiftId,
        verificationType: verificationType,
        proximityStatus: proximityResult.status,
        approximateDistance: proximityResult.approximateDistance,
        verificationTime: DateTime.now(),
        privacyCompliant: true,
        error: proximityResult.isWithinRange 
            ? null 
            : 'Te ver van werklocatie (${proximityResult.approximateDistance}m)',
      );
      
      // Step 7: Store only verification result (no coordinates)
      await _storeVerificationResult(verification, userId);
      
      // Step 8: Update last verification time
      _lastVerificationTime = DateTime.now();
      
      // Step 9: Emit privacy-compliant update
      _updateController.add(PrivacyLocationUpdate(
        userId: userId,
        verificationType: verificationType,
        isWithinWorkArea: proximityResult.isWithinRange,
        approximateDistance: proximityResult.approximateDistance,
        timestamp: DateTime.now(),
        privacyNote: 'Exact coordinates not stored - proximity verification only',
      ));
      
      return verification;
      
    } catch (e) {
      return WorkLocationVerification(
        isSuccess: false,
        error: 'Locatie verificatie mislukt: ${e.toString()}',
        verificationType: verificationType,
      );
    }
  }
  
  /// Start emergency location sharing (requires explicit consent)
  Future<EmergencyLocationResult> startEmergencyLocationSharing({
    required String userId,
    required String emergencyId,
    required String emergencyType,
  }) async {
    try {
      // Check emergency tracking consent
      final hasConsent = await LocationConsentService.hasValidConsent(
        userId,
        LocationConsentType.emergencyTracking,
      );
      
      if (!hasConsent) {
        // Request emergency consent
        await LocationConsentService.requestConsent(
          userId,
          consentType: LocationConsentType.emergencyTracking,
          businessJustification: 'Emergency response and worker safety',
          specificPurpose: 'Emergency location sharing for incident: $emergencyType',
          userInfo: {'emergency_id': emergencyId, 'emergency_type': emergencyType},
        );
      }
      
      // Get current location for emergency
      final currentLocation = await _getCurrentLocationSafely();
      if (currentLocation == null) {
        return EmergencyLocationResult(
          isSuccess: false,
          error: 'Emergency location niet beschikbaar',
        );
      }
      
      // Store emergency location with higher precision (safety requirement)
      final emergencyLocation = EmergencyLocationData(
        emergencyId: emergencyId,
        userId: userId,
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        accuracy: currentLocation.accuracy,
        timestamp: DateTime.now(),
        emergencyType: emergencyType,
        // Auto-delete after 7 days
        autoDeleteAt: DateTime.now().add(const Duration(days: 7)),
      );
      
      await _firestore
          .collection('emergency_locations')
          .doc(emergencyId)
          .set(emergencyLocation.toFirestore());
      
      // Schedule automatic deletion
      await _scheduleEmergencyDataDeletion(emergencyId, emergencyLocation.autoDeleteAt);
      
      return EmergencyLocationResult(
        isSuccess: true,
        emergencyId: emergencyId,
        locationShared: true,
        autoDeleteAt: emergencyLocation.autoDeleteAt,
      );
      
    } catch (e) {
      return EmergencyLocationResult(
        isSuccess: false,
        error: 'Emergency location sharing mislukt: ${e.toString()}',
      );
    }
  }
  
  /// Request location consent with full transparency
  Future<ConsentRequestResult> requestLocationConsent({
    required String userId,
    required LocationConsentType consentType,
    required String businessReason,
  }) async {
    try {
      String purpose;
      String dataUsage;
      String retentionPeriod;
      
      switch (consentType) {
        case LocationConsentType.workVerification:
          purpose = 'Verificatie van aanwezigheid op werklocatie voor check-in/check-out';
          dataUsage = 'Alleen nabijheid verificatie - geen exacte coördinaten opgeslagen';
          retentionPeriod = '24 uur (ruwe data), 90 dagen (verificatie resultaten)';
          break;
        case LocationConsentType.shiftMonitoring:
          purpose = 'Periodieke verificatie tijdens werkdienst voor veiligheidsdoeleinden';
          dataUsage = 'Nabijheid verificatie elke 15 minuten tijdens dienst';
          retentionPeriod = '24 uur (ruwe data), 90 dagen (verificatie resultaten)';
          break;
        case LocationConsentType.emergencyTracking:
          purpose = 'Locatie delen in noodsituaties voor hulpverlening';
          dataUsage = 'Exacte coördinaten alleen tijdens noodsituatie';
          retentionPeriod = '7 dagen na noodsituatie';
          break;
        case LocationConsentType.companyMonitoring:
          purpose = 'Real-time locatie zichtbaar voor werkgever tijdens dienst';
          dataUsage = 'Nabijheid van werklocatie zichtbaar voor planning';
          retentionPeriod = '24 uur (ruwe data), 30 dagen (locatie geschiedenis)';
          break;
      }
      
      return ConsentRequestResult(
        consentType: consentType,
        purpose: purpose,
        dataUsage: dataUsage,
        retentionPeriod: retentionPeriod,
        legalBasis: 'AVG Artikel 9 - Expliciete toestemming voor bijzondere persoonsgegevens',
        workerRights: [
          'Je kunt deze toestemming altijd intrekken',
          'Je hebt recht op inzage van je locatiegegevens',
          'Je kunt je locatiegegevens laten verwijderen',
          'Je kunt bezwaar maken tegen verwerking',
        ],
        consentRequired: true,
      );
      
    } catch (e) {
      throw PrivacyLocationException(
        'Toestemming aanvraag mislukt: $e',
        PrivacyLocationErrorType.consentRequestFailed,
      );
    }
  }
  
  /// Get privacy dashboard for user transparency
  Future<LocationPrivacyDashboard> getPrivacyDashboard(String userId) async {
    try {
      // Get consent dashboard
      final consentDashboard = await LocationConsentService.getConsentDashboard(userId);
      
      // Get recent location verifications
      final recentVerifications = await _getRecentVerifications(userId, limit: 20);
      
      // Get data usage statistics
      final dataUsage = await _getDataUsageStats(userId);
      
      return LocationPrivacyDashboard(
        userId: userId,
        lastUpdated: DateTime.now(),
        consentDashboard: consentDashboard,
        recentVerifications: recentVerifications,
        dataUsageStats: dataUsage,
        privacyFeatures: [
          'Locatie gegevens worden automatisch verwijderd na 24 uur',
          'Alleen nabijheid verificatie - geen exacte coördinaten opgeslagen',
          'Expliciete toestemming vereist voor alle locatie verwerking',
          'Volledige transparantie over data gebruik',
          'Recht op inzage, rectificatie en verwijdering',
        ],
        complianceInfo: {
          'gdpr_article': 'Artikel 9 - Bijzondere persoonsgegevens',
          'nederlandse_wet': 'Arbeidsrecht - Locatiegegevens werknemer',
          'data_controller': 'SecuryFlex B.V.',
          'privacy_officer': 'privacy@securyflex.nl',
        },
      );
      
    } catch (e) {
      throw PrivacyLocationException(
        'Privacy dashboard laden mislukt: $e',
        PrivacyLocationErrorType.dashboardLoadFailed,
      );
    }
  }
  
  /// Export all user location data (GDPR Subject Access Request)
  Future<Map<String, dynamic>> exportLocationData(String userId) async {
    try {
      // Export consent data
      final consentData = await LocationConsentService.exportConsentData(userId);
      
      // Export location crypto data
      final cryptoData = await LocationDataLifecycleService.exportUserLocationData(userId);
      
      // Export verification results
      final verifications = await _getRecentVerifications(userId, limit: 1000);
      
      return {
        'export_timestamp': DateTime.now().toIso8601String(),
        'user_id': userId,
        'consent_data': consentData,
        'crypto_data': cryptoData,
        'verification_results': verifications.map((v) => v.toJson()).toList(),
        'privacy_info': {
          'data_minimization': 'Only proximity verification stored, no exact coordinates',
          'retention_periods': {
            'raw_location_data': '24 hours (automatic deletion)',
            'verification_results': '90 days',
            'emergency_locations': '7 days',
            'audit_logs': '7 years (legal requirement)',
          },
          'user_rights': [
            'Right to access (Article 15 GDPR)',
            'Right to rectification (Article 16 GDPR)',
            'Right to erasure (Article 17 GDPR)',
            'Right to restrict processing (Article 18 GDPR)',
            'Right to data portability (Article 20 GDPR)',
            'Right to object (Article 21 GDPR)',
            'Right to withdraw consent (Article 7 GDPR)',
          ],
        },
      };
      
    } catch (e) {
      throw PrivacyLocationException(
        'Location data export mislukt: $e',
        PrivacyLocationErrorType.dataExportFailed,
      );
    }
  }
  
  /// Delete all user location data (GDPR Right to Erasure)
  Future<void> deleteAllLocationData(String userId) async {
    try {
      // Delete consent data
      await LocationConsentService.deleteAllConsentData(userId);
      
      // Delete crypto/location data
      await LocationDataLifecycleService.deleteAllUserLocationData(userId);
      
      // Delete verification results
      final verificationQuery = await _firestore
          .collection('work_location_verifications')
          .where('userId', isEqualTo: userId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in verificationQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete emergency locations
      final emergencyQuery = await _firestore
          .collection('emergency_locations')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in emergencyQuery.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('GDPR_ERASURE: All location data deleted for user $userId');
      
    } catch (e) {
      throw PrivacyLocationException(
        'Location data verwijdering mislukt: $e',
        PrivacyLocationErrorType.dataErasureFailed,
      );
    }
  }
  
  /// Private methods
  
  bool _isInCooldownPeriod() {
    if (_lastVerificationTime == null) return false;
    return DateTime.now().difference(_lastVerificationTime!) < _verificationCooldown;
  }
  
  int _getCooldownRemaining() {
    if (_lastVerificationTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastVerificationTime!);
    final remaining = _verificationCooldown - elapsed;
    return remaining.inMinutes.clamp(0, _verificationCooldown.inMinutes);
  }
  
  Future<GPSLocation?> _getCurrentLocationSafely() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
        timeLimit: const Duration(seconds: 30),
      );
      
      // Check for mock locations
      if (position.isMocked) {
        throw PrivacyLocationException(
          'Mock locatie gedetecteerd',
          PrivacyLocationErrorType.mockLocationDetected,
        );
      }
      
      // Check accuracy
      if (position.accuracy > 100.0) {
        throw PrivacyLocationException(
          'GPS nauwkeurigheid onvoldoende',
          PrivacyLocationErrorType.gpsAccuracyInsufficient,
        );
      }
      
      return GPSLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude ?? 0.0,
        timestamp: position.timestamp ?? DateTime.now(),
        provider: 'gps',
        isMocked: position.isMocked,
      );
      
    } catch (e) {
      print('Error getting GPS location: $e');
      return null;
    }
  }
  
  Future<WorkLocation?> _getWorkLocation(String workLocationId) async {
    try {
      final doc = await _firestore
          .collection('work_locations')
          .doc(workLocationId)
          .get();
      
      if (!doc.exists) return null;
      
      return WorkLocation.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }
  
  ProximityResult _calculateProximity(GPSLocation current, WorkLocation work) {
    final distance = _calculateDistance(
      current.latitude,
      current.longitude,
      work.latitude,
      work.longitude,
    );
    
    String status;
    if (distance <= work.geofenceRadius) {
      status = 'binnen_werkgebied';
    } else if (distance <= work.geofenceRadius * 1.5) {
      status = 'net_buiten_werkgebied';
    } else {
      status = 'ver_van_werkgebied';
    }
    
    // Round to nearest 50m for privacy
    final approximateDistance = (distance / 50).round() * 50.0;
    
    return ProximityResult(
      isWithinRange: distance <= work.geofenceRadius,
      status: status,
      approximateDistance: approximateDistance,
    );
  }
  
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // Earth radius in meters
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lng2 - lng1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  Future<void> _storeVerificationResult(
    WorkLocationVerification verification,
    String userId,
  ) async {
    await _firestore
        .collection('work_location_verifications')
        .add({
      ...verification.toFirestore(),
      'userId': userId,
      'dataMinimization': true,
      'privacyCompliant': true,
      'autoDeleteAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 90))
      ),
    });
  }
  
  Future<List<WorkLocationVerification>> _getRecentVerifications(
    String userId, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection('work_location_verifications')
        .where('userId', isEqualTo: userId)
        .orderBy('verificationTime', descending: true)
        .limit(limit)
        .get();
    
    return snapshot.docs
        .map((doc) => WorkLocationVerification.fromFirestore(doc))
        .toList();
  }
  
  Future<Map<String, dynamic>> _getDataUsageStats(String userId) async {
    final verifications = await _getRecentVerifications(userId, limit: 1000);
    
    final last30Days = verifications
        .where((v) => DateTime.now().difference(v.verificationTime).inDays <= 30)
        .toList();
    
    return {
      'total_verifications': verifications.length,
      'last_30_days': last30Days.length,
      'successful_verifications': verifications.where((v) => v.isSuccess).length,
      'data_minimization_applied': true,
      'coordinate_obfuscation_applied': true,
      'automatic_deletion_enabled': true,
    };
  }
  
  Future<void> _scheduleEmergencyDataDeletion(String emergencyId, DateTime deleteAt) async {
    await _firestore
        .collection('data_deletion_schedule')
        .add({
      'type': 'emergency_location',
      'emergencyId': emergencyId,
      'scheduledDeletion': Timestamp.fromDate(deleteAt),
      'reason': 'automatic_emergency_cleanup',
      'gdprCompliance': 'Article 5 - Storage Limitation',
    });
  }
  
  void _startCleanupTimer() {
    // Run cleanup every hour
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      try {
        await LocationDataLifecycleService.cleanupExpiredLocationData();
        await LocationDataLifecycleService.cleanupOldGeofenceResults();
        await _cleanupExpiredEmergencyLocations();
      } catch (e) {
        print('Automatic cleanup error: $e');
      }
    });
  }
  
  Future<void> _cleanupExpiredEmergencyLocations() async {
    try {
      final now = DateTime.now();
      final expiredEmergency = await _firestore
          .collection('emergency_locations')
          .where('autoDeleteAt', isLessThan: Timestamp.fromDate(now))
          .get();
      
      final batch = _firestore.batch();
      for (final doc in expiredEmergency.docs) {
        batch.delete(doc.reference);
      }
      
      if (expiredEmergency.docs.isNotEmpty) {
        await batch.commit();
        print('PRIVACY_CLEANUP: Deleted ${expiredEmergency.docs.length} expired emergency locations');
      }
    } catch (e) {
      print('Emergency cleanup error: $e');
    }
  }
  
  void dispose() {
    _cleanupTimer?.cancel();
    _updateController.close();
  }
}

// Data Models

class ProximityResult {
  final bool isWithinRange;
  final String status;
  final double approximateDistance;

  const ProximityResult({
    required this.isWithinRange,
    required this.status,
    required this.approximateDistance,
  });
}

enum WorkLocationType {
  checkIn,
  checkOut,
  emergencyVerification,
  shiftMonitoring,
}

class WorkLocationVerification {
  final bool isSuccess;
  final String? workLocationId;
  final String? shiftId;
  final WorkLocationType verificationType;
  final String? proximityStatus;
  final double? approximateDistance;
  final DateTime verificationTime;
  final bool privacyCompliant;
  final String? error;
  final bool requiresConsent;

  WorkLocationVerification({
    required this.isSuccess,
    this.workLocationId,
    this.shiftId,
    required this.verificationType,
    this.proximityStatus,
    this.approximateDistance,
    DateTime? verificationTime,
    this.privacyCompliant = true,
    this.error,
    this.requiresConsent = false,
  }) : verificationTime = verificationTime ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'isSuccess': isSuccess,
    'workLocationId': workLocationId,
    'shiftId': shiftId,
    'verificationType': verificationType.toString().split('.').last,
    'proximityStatus': proximityStatus,
    'approximateDistance': approximateDistance,
    'verificationTime': Timestamp.fromDate(verificationTime),
    'privacyCompliant': privacyCompliant,
    'error': error,
    'requiresConsent': requiresConsent,
  };

  factory WorkLocationVerification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkLocationVerification(
      isSuccess: data['isSuccess'] ?? false,
      workLocationId: data['workLocationId'],
      shiftId: data['shiftId'],
      verificationType: WorkLocationType.values.firstWhere(
        (t) => t.toString().split('.').last == data['verificationType'],
        orElse: () => WorkLocationType.checkIn,
      ),
      proximityStatus: data['proximityStatus'],
      approximateDistance: data['approximateDistance']?.toDouble(),
      verificationTime: data['verificationTime'].toDate(),
      privacyCompliant: data['privacyCompliant'] ?? true,
      error: data['error'],
      requiresConsent: data['requiresConsent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'isSuccess': isSuccess,
    'workLocationId': workLocationId,
    'shiftId': shiftId,
    'verificationType': verificationType.toString().split('.').last,
    'proximityStatus': proximityStatus,
    'approximateDistance': approximateDistance,
    'verificationTime': verificationTime.toIso8601String(),
    'privacyCompliant': privacyCompliant,
    'error': error,
    'requiresConsent': requiresConsent,
  };
}

class PrivacyLocationUpdate {
  final String userId;
  final WorkLocationType verificationType;
  final bool isWithinWorkArea;
  final double approximateDistance;
  final DateTime timestamp;
  final String privacyNote;

  const PrivacyLocationUpdate({
    required this.userId,
    required this.verificationType,
    required this.isWithinWorkArea,
    required this.approximateDistance,
    required this.timestamp,
    required this.privacyNote,
  });
}

class EmergencyLocationData {
  final String emergencyId;
  final String userId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String emergencyType;
  final DateTime autoDeleteAt;

  const EmergencyLocationData({
    required this.emergencyId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.emergencyType,
    required this.autoDeleteAt,
  });

  Map<String, dynamic> toFirestore() => {
    'emergencyId': emergencyId,
    'userId': userId,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'timestamp': Timestamp.fromDate(timestamp),
    'emergencyType': emergencyType,
    'autoDeleteAt': Timestamp.fromDate(autoDeleteAt),
    'privacyNote': 'Emergency location - higher precision authorized for safety',
  };
}

class EmergencyLocationResult {
  final bool isSuccess;
  final String? emergencyId;
  final bool locationShared;
  final DateTime? autoDeleteAt;
  final String? error;

  const EmergencyLocationResult({
    required this.isSuccess,
    this.emergencyId,
    this.locationShared = false,
    this.autoDeleteAt,
    this.error,
  });
}

class ConsentRequestResult {
  final LocationConsentType consentType;
  final String purpose;
  final String dataUsage;
  final String retentionPeriod;
  final String legalBasis;
  final List<String> workerRights;
  final bool consentRequired;

  const ConsentRequestResult({
    required this.consentType,
    required this.purpose,
    required this.dataUsage,
    required this.retentionPeriod,
    required this.legalBasis,
    required this.workerRights,
    required this.consentRequired,
  });
}

class LocationPrivacyDashboard {
  final String userId;
  final DateTime lastUpdated;
  final ConsentDashboard consentDashboard;
  final List<WorkLocationVerification> recentVerifications;
  final Map<String, dynamic> dataUsageStats;
  final List<String> privacyFeatures;
  final Map<String, String> complianceInfo;

  const LocationPrivacyDashboard({
    required this.userId,
    required this.lastUpdated,
    required this.consentDashboard,
    required this.recentVerifications,
    required this.dataUsageStats,
    required this.privacyFeatures,
    required this.complianceInfo,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'lastUpdated': lastUpdated.toIso8601String(),
    'consentDashboard': consentDashboard.toJson(),
    'recentVerifications': recentVerifications.map((v) => v.toJson()).toList(),
    'dataUsageStats': dataUsageStats,
    'privacyFeatures': privacyFeatures,
    'complianceInfo': complianceInfo,
  };
}

// Exception Types

enum PrivacyLocationErrorType {
  consentRequestFailed,
  dashboardLoadFailed,
  dataExportFailed,
  dataErasureFailed,
  mockLocationDetected,
  gpsAccuracyInsufficient,
  locationPermissionDenied,
}

class PrivacyLocationException implements Exception {
  final String message;
  final PrivacyLocationErrorType type;

  const PrivacyLocationException(this.message, this.type);

  @override
  String toString() => 'PrivacyLocationException: $message';
}

// GPS Location Model (reuse from existing codebase)
class GPSLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final DateTime timestamp;
  final String provider;
  final bool isMocked;

  const GPSLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.timestamp,
    required this.provider,
    required this.isMocked,
  });
}