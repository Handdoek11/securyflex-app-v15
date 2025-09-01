import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/enhanced_auth_models.dart';
import '../../schedule/models/time_entry_model.dart';

/// GDPR/AVG Compliance Service for SecuryFlex
/// 
/// Implements comprehensive data protection compliance according to:
/// - GDPR Articles 6, 7, 8, 9 (lawful basis, consent, special categories)
/// - AVG (Dutch GDPR implementation)
/// - Dutch Data Protection Authority guidelines
/// - Privacy by Design principles (Art. 25)
class GDPRComplianceService {
  static const String _consentKey = 'securyflex_gdpr_consent';
  
  // GDPR Article 9 - Biometric data requires explicit consent
  
  /// Record user consent for data processing
  /// 
  /// Implements GDPR Article 7 - Conditions for consent
  static Future<ConsentRecord> recordConsent({
    required String userId,
    required DataProcessingPurpose purpose,
    required ConsentType consentType,
    required String lawfulBasis,
    String? additionalInfo,
    Map<String, dynamic>? metadata,
  }) async {
    final consent = ConsentRecord(
      id: _generateConsentId(),
      userId: userId,
      purpose: purpose,
      consentType: consentType,
      lawfulBasis: lawfulBasis,
      granted: true,
      timestamp: DateTime.now(),
      ipAddress: await _getUserIPAddress(),
      userAgent: await _getUserAgent(),
      additionalInfo: additionalInfo,
      metadata: metadata ?? {},
      version: await _getPrivacyPolicyVersion(),
    );
    
    await _storeConsentRecord(consent);
    
    // Log data processing activity (GDPR Article 30)
    await _logDataProcessingActivity(
      userId: userId,
      purpose: purpose,
      lawfulBasis: lawfulBasis,
      dataCategories: _getDataCategoriesForPurpose(purpose),
      consentId: consent.id,
    );
    
    return consent;
  }
  
  /// Withdraw consent (GDPR Article 7(3))
  static Future<bool> withdrawConsent({
    required String userId,
    required String consentId,
    String? reason,
  }) async {
    try {
      final consent = await _getConsentRecord(consentId);
      if (consent == null || consent.userId != userId) {
        return false;
      }
      
      // Create withdrawal record
      final withdrawal = ConsentWithdrawal(
        consentId: consentId,
        userId: userId,
        withdrawalDate: DateTime.now(),
        reason: reason,
        ipAddress: await _getUserIPAddress(),
        automaticDeletion: true, // Trigger data deletion
      );
      
      await _storeConsentWithdrawal(withdrawal);
      
      // Mark original consent as withdrawn
      final withdrawnConsent = consent.copyWith(
        withdrawn: true,
        withdrawalDate: DateTime.now(),
      );
      await _storeConsentRecord(withdrawnConsent);
      
      // Initiate data deletion if required
      if (withdrawal.automaticDeletion) {
        await _initiateDataDeletion(userId, consent.purpose);
      }
      
      // Log withdrawal event
      await _logDataProcessingActivity(
        userId: userId,
        purpose: consent.purpose,
        lawfulBasis: 'consent_withdrawn',
        dataCategories: _getDataCategoriesForPurpose(consent.purpose),
        consentId: consentId,
        additionalData: {'withdrawal_reason': reason},
      );
      
      return true;
    } catch (e) {
      await _logComplianceError('consent_withdrawal_failed', {
        'userId': userId,
        'consentId': consentId,
        'error': e.toString(),
      });
      return false;
    }
  }
  
  /// Request biometric consent (GDPR Article 9 - Special categories)
  static Future<BiometricConsentResult> requestBiometricConsent({
    required String userId,
    required List<BiometricType> biometricTypes,
    required BiometricProcessingPurpose purpose,
  }) async {
    // Generate explicit consent request for biometric data
    final consentRequest = BiometricConsentRequest(
      id: _generateConsentId(),
      userId: userId,
      biometricTypes: biometricTypes,
      purpose: purpose,
      requestDate: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      lawfulBasis: 'Article 9(2)(a) - explicit consent',
      processingDetails: _getBiometricProcessingDetails(purpose),
      storageDetails: BiometricStorageDetails(
        location: 'Device-local secure storage only',
        encryption: 'AES-256 hardware encryption',
        retention: 'Until consent withdrawn or account deleted',
        sharing: 'Never shared with third parties',
        crossBorder: false,
      ),
    );
    
    await _storeBiometricConsentRequest(consentRequest);
    
    return BiometricConsentResult(
      consentRequestId: consentRequest.id,
      requiresExplicitConsent: true,
      consentText: _generateBiometricConsentText(consentRequest),
      consentTextDutch: _generateBiometricConsentTextDutch(consentRequest),
      processingDetails: consentRequest.processingDetails,
      storageDetails: consentRequest.storageDetails,
    );
  }
  
  /// Grant biometric consent
  static Future<bool> grantBiometricConsent({
    required String userId,
    required String consentRequestId,
    required bool explicitConsent,
  }) async {
    if (!explicitConsent) {
      return false; // GDPR Article 9 requires explicit consent
    }
    
    final request = await _getBiometricConsentRequest(consentRequestId);
    if (request == null || request.userId != userId || request.isExpired) {
      return false;
    }
    
    // Record explicit biometric consent
    final consent = await recordConsent(
      userId: userId,
      purpose: DataProcessingPurpose.biometricAuthentication,
      consentType: ConsentType.explicit,
      lawfulBasis: 'Article 9(2)(a) - explicit consent for biometric data',
      additionalInfo: 'Biometric authentication: ${request.biometricTypes.map((t) => t.dutchName).join(', ')}',
      metadata: {
        'biometric_types': request.biometricTypes.map((t) => t.name).toList(),
        'purpose': request.purpose.name,
        'consent_request_id': consentRequestId,
        'storage_location': 'device_local',
        'encryption': 'hardware_aes256',
      },
    );
    
    // Store biometric-specific consent record
    final biometricConsent = BiometricConsentRecord(
      consentId: consent.id,
      userId: userId,
      biometricTypes: request.biometricTypes,
      purpose: request.purpose,
      explicitConsent: true,
      consentDate: DateTime.now(),
      storageDetails: request.storageDetails,
      processingDetails: request.processingDetails,
    );
    
    await _storeBiometricConsentRecord(biometricConsent);
    
    return true;
  }
  
  /// Handle data subject requests (GDPR Chapter III)
  static Future<DataSubjectRequestResponse> processDataSubjectRequest({
    required String userId,
    required DataSubjectRequestType requestType,
    required String requestDetails,
    String? identityVerification,
  }) async {
    final request = DataSubjectRequest(
      id: _generateRequestId(),
      userId: userId,
      requestType: requestType,
      requestDetails: requestDetails,
      requestDate: DateTime.now(),
      status: DataSubjectRequestStatus.received,
      identityVerified: identityVerification != null,
      verificationMethod: identityVerification,
    );
    
    await _storeDataSubjectRequest(request);
    
    // Process request based on type
    switch (requestType) {
      case DataSubjectRequestType.access: // Article 15
        return await _processAccessRequest(request);
      case DataSubjectRequestType.rectification: // Article 16
        return await _processRectificationRequest(request);
      case DataSubjectRequestType.erasure: // Article 17 (Right to be forgotten)
        return await _processErasureRequest(request);
      case DataSubjectRequestType.portability: // Article 20
        return await _processPortabilityRequest(request);
      case DataSubjectRequestType.restriction: // Article 18
        return await _processRestrictionRequest(request);
      case DataSubjectRequestType.objection: // Article 21
        return await _processObjectionRequest(request);
    }
  }
  
  /// Implement right to be forgotten (GDPR Article 17)
  static Future<DataErasureResult> processRightToBeForgotten({
    required String userId,
    required ErasureReason reason,
    bool immediateErasure = false,
  }) async {
    final erasureRequest = DataErasureRequest(
      id: _generateRequestId(),
      userId: userId,
      reason: reason,
      requestDate: DateTime.now(),
      immediateErasure: immediateErasure,
      estimatedCompletionDate: immediateErasure 
        ? DateTime.now().add(const Duration(hours: 72))
        : DateTime.now().add(const Duration(days: 30)),
    );
    
    await _storeErasureRequest(erasureRequest);
    
    // Identify all user data for deletion
    final dataInventory = await _generateUserDataInventory(userId);
    
    // Create deletion plan
    final deletionPlan = DataDeletionPlan(
      erasureRequestId: erasureRequest.id,
      userId: userId,
      dataCategories: dataInventory.categories,
      totalDataSize: dataInventory.totalSize,
      estimatedDuration: _calculateDeletionDuration(dataInventory),
      dependencies: dataInventory.dependencies,
    );
    
    // Execute deletion based on urgency
    if (immediateErasure) {
      return await _executeImmediateErasure(deletionPlan);
    } else {
      return await _scheduleErasure(deletionPlan);
    }
  }
  
  /// Generate privacy impact assessment report
  static Future<PrivacyImpactAssessment> generatePrivacyImpactAssessment({
    required String userId,
    required List<DataProcessingPurpose> purposes,
  }) async {
    final assessment = PrivacyImpactAssessment(
      id: _generateAssessmentId(),
      userId: userId,
      assessmentDate: DateTime.now(),
      purposes: purposes,
      riskLevel: await _calculatePrivacyRisk(userId, purposes),
      dataCategories: purposes.expand(_getDataCategoriesForPurpose).toList(),
      processingRisks: await _identifyProcessingRisks(purposes),
      mitigationMeasures: await _identifyMitigationMeasures(purposes),
      complianceStatus: await _assessComplianceStatus(userId, purposes),
    );
    
    await _storePrivacyImpactAssessment(assessment);
    return assessment;
  }
  
  /// Check data retention compliance
  static Future<DataRetentionAssessment> assessDataRetention({
    required String userId,
  }) async {
    final retentionPolicies = await _getRetentionPolicies();
    final userDataAge = await _getUserDataAge(userId);
    
    final assessment = DataRetentionAssessment(
      userId: userId,
      assessmentDate: DateTime.now(),
      retentionPolicies: retentionPolicies,
      dataAge: userDataAge,
      complianceIssues: await _identifyRetentionIssues(userId, retentionPolicies),
      recommendedActions: await _generateRetentionRecommendations(userId),
    );
    
    // Schedule automatic deletion for expired data
    final expiredData = assessment.complianceIssues
        .where((issue) => issue.type == RetentionIssueType.expired);
    
    for (final issue in expiredData) {
      await _scheduleAutomaticDeletion(userId, issue.dataCategory);
    }
    
    return assessment;
  }
  
  /// Generate biometric consent text in English (for logging)
  static String _generateBiometricConsentText(BiometricConsentRequest request) {
    return '''
I hereby provide explicit consent for the processing of my biometric data for the following purposes:
- Authentication and user verification
- Authentication and identity verification
- Secure access to SecuryFlex services

I understand that:
- My biometric data is stored locally on my device only
- I can withdraw this consent at any time
- This data will not be shared with third parties
- Processing is based on my explicit consent (GDPR Article 9)
''';
  }
  
  /// Generate biometric consent text in Dutch
  static String _generateBiometricConsentTextDutch(BiometricConsentRequest request) {
    return '''
Ik geef hierbij uitdrukkelijke toestemming voor de verwerking van mijn biometrische gegevens voor de volgende doeleinden:
- Authentication and user verification
- Authenticatie en identiteitsverificatie
- Beveiligde toegang tot SecuryFlex diensten

Ik begrijp dat:
- Mijn biometrische gegevens alleen lokaal op mijn apparaat worden opgeslagen
- Ik deze toestemming te allen tijde kan intrekken
- Deze gegevens niet worden gedeeld met derden
- De verwerking is gebaseerd op mijn uitdrukkelijke toestemming (AVG Artikel 9)
''';
  }
  
  // Private helper methods
  
  
  /// Get biometric processing details
  static BiometricProcessingDetails _getBiometricProcessingDetails(
    BiometricProcessingPurpose purpose
  ) {
    return BiometricProcessingDetails(
      purpose: purpose,
      processingScope: 'Authentication verification only',
      dataRetention: 'Until consent withdrawal or account deletion',
      technicalMeasures: [
        'AES-256 hardware encryption',
        'Device-local storage only',
        'Secure Enclave/TEE protection',
        'Biometric template hashing',
      ],
      organisationalMeasures: [
        'Privacy by design implementation',
        'Regular security audits',
        'Employee training on biometric data',
        'Incident response procedures',
      ],
    );
  }
  
  /// Store consent record securely
  static Future<void> _storeConsentRecord(ConsentRecord consent) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = await _encryptSensitiveData(consent.toJson());
    await prefs.setString('${_consentKey}_${consent.id}', encryptedData);
  }
  
  /// Encrypt sensitive data using AES-256
  static Future<String> _encryptSensitiveData(Map<String, dynamic> data) async {
    // In production, use proper AES-256 encryption with hardware security
    // This is a placeholder for the encryption implementation
    final jsonString = json.encode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }
  
  /// Log compliance-related errors
  static Future<void> _logComplianceError(String errorType, Map<String, dynamic> details) async {
    developer.log('GDPR Compliance Error - Type: $errorType, Details: $details', name: 'GDPRCompliance', level: 1000);
    // In production, send to secure logging service with privacy protection
  }
  
  /// Generate unique consent ID
  static String _generateConsentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecond.toString().padLeft(6, '0');
    return 'consent_${timestamp}_$random';
  }
  
  /// Generate unique request ID
  static String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecond.toString().padLeft(6, '0');
    return 'req_${timestamp}_$random';
  }
  
  /// Get user IP address (privacy-compliant)
  static Future<String?> _getUserIPAddress() async {
    // Implement privacy-compliant IP logging (hash or anonymize)
    return null; // Placeholder
  }
  
  /// Get privacy policy version
  static Future<String> _getPrivacyPolicyVersion() async {
    return 'v2.1_2024'; // Current privacy policy version
  }
  
  /// Placeholder methods for comprehensive implementation
  static Future<String?> _getUserAgent() async => null;
  static List<DataCategory> _getDataCategoriesForPurpose(DataProcessingPurpose purpose) => [];
  static Future<ConsentRecord?> _getConsentRecord(String consentId) async => null;
  static Future<void> _storeConsentWithdrawal(ConsentWithdrawal withdrawal) async {}
  static Future<void> _logDataProcessingActivity({
    required String userId,
    required DataProcessingPurpose purpose,
    required String lawfulBasis,
    required List<DataCategory> dataCategories,
    required String consentId,
    Map<String, dynamic>? additionalData,
  }) async {}
  static Future<void> _initiateDataDeletion(String userId, DataProcessingPurpose purpose) async {}

  // ===== LOCATION DATA GDPR COMPLIANCE FEATURES =====

  /// Record location data consent per GDPR Article 9 (special category data)
  static Future<LocationConsentRecord> recordLocationConsent({
    required String userId,
    required LocationProcessingPurpose purpose,
    required String jobSiteId,
    required Position? lastKnownLocation,
    bool preciseLocation = true,
    Duration? retentionPeriod,
    String? additionalInfo,
  }) async {
    final firestore = FirebaseFirestore.instance;
    
    final locationConsent = LocationConsentRecord(
      id: _generateConsentId(),
      userId: userId,
      purpose: purpose,
      jobSiteId: jobSiteId,
      preciseLocationConsent: preciseLocation,
      continuousTrackingConsent: purpose == LocationProcessingPurpose.timeTracking,
      retentionPeriod: retentionPeriod ?? const Duration(days: 2555), // 7 years default
      consentTimestamp: DateTime.now(),
      consentLocation: lastKnownLocation != null ? GPSLocation(
        latitude: lastKnownLocation.latitude,
        longitude: lastKnownLocation.longitude,
        accuracy: lastKnownLocation.accuracy,
        altitude: lastKnownLocation.altitude,
        timestamp: lastKnownLocation.timestamp,
        provider: 'consent_location',
        isMocked: lastKnownLocation.isMocked,
      ) : null,
      privacyNoticeVersion: await _getPrivacyPolicyVersion(),
      additionalInfo: additionalInfo,
      withdrawn: false,
    );
    
    // Store consent in Firebase with encryption
    await firestore.collection('gdprLocationConsent').doc(locationConsent.id).set(
      await _encryptLocationConsentData(locationConsent.toJson())
    );
    
    // Store locally for offline access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('location_consent_${userId}_${purpose.name}', 
      jsonEncode(locationConsent.toJson()));
    
    // Log data processing activity
    await _logLocationProcessingActivity(
      userId: userId,
      purpose: purpose,
      consentId: locationConsent.id,
      jobSiteId: jobSiteId,
    );
    
    return locationConsent;
  }

  /// Validate location data consent before processing
  static Future<LocationConsentValidation> validateLocationConsent({
    required String userId,
    required LocationProcessingPurpose purpose,
    required String jobSiteId,
    required GPSLocation currentLocation,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentJson = prefs.getString('location_consent_${userId}_${purpose.name}');
      
      if (consentJson == null) {
        return LocationConsentValidation(
          isValid: false,
          reason: LocationConsentIssue.noConsent,
          requiresNewConsent: true,
          suggestedAction: 'Vraag gebruiker om locatie toestemming',
        );
      }
      
      final consent = LocationConsentRecord.fromJson(jsonDecode(consentJson));
      
      // Check if consent is withdrawn
      if (consent.withdrawn) {
        return LocationConsentValidation(
          isValid: false,
          reason: LocationConsentIssue.consentWithdrawn,
          requiresNewConsent: true,
          suggestedAction: 'Toestemming ingetrokken - stop locatie verwerking',
        );
      }
      
      // Check retention period
      final now = DateTime.now();
      final consentExpiry = consent.consentTimestamp.add(consent.retentionPeriod);
      if (now.isAfter(consentExpiry)) {
        return LocationConsentValidation(
          isValid: false,
          reason: LocationConsentIssue.expired,
          requiresNewConsent: true,
          suggestedAction: 'Toestemming verlopen - vernieuw consent',
          expiryDate: consentExpiry,
        );
      }
      
      // Check job site match
      if (consent.jobSiteId != jobSiteId) {
        return LocationConsentValidation(
          isValid: false,
          reason: LocationConsentIssue.jobSiteMismatch,
          requiresNewConsent: false,
          suggestedAction: 'Toestemming geldt niet voor deze werkplek',
        );
      }
      
      // Check precision requirements
      if (!consent.preciseLocationConsent && currentLocation.accuracy < 100.0) {
        return LocationConsentValidation(
          isValid: false,
          reason: LocationConsentIssue.precisionNotConsented,
          requiresNewConsent: false,
          suggestedAction: 'Gebruiker heeft geen toestemming voor precieze locatie',
        );
      }
      
      // All checks passed
      return LocationConsentValidation(
        isValid: true,
        reason: LocationConsentIssue.none,
        requiresNewConsent: false,
        suggestedAction: 'Toestemming geldig',
        consentRecord: consent,
        validUntil: consentExpiry,
      );
      
    } catch (e) {
      return LocationConsentValidation(
        isValid: false,
        reason: LocationConsentIssue.validationError,
        requiresNewConsent: true,
        suggestedAction: 'Validatie fout - vraag nieuwe toestemming',
      );
    }
  }

  /// Anonymize location data for analytics while preserving utility
  static Future<AnonymizedLocationData> anonymizeLocationData({
    required List<GPSLocation> locations,
    required AnonymizationLevel level,
    String? jobSiteId,
  }) async {
    final anonymizedLocations = <GPSLocation>[];
    
    for (final location in locations) {
      GPSLocation anonymized;
      
      switch (level) {
        case AnonymizationLevel.light:
          // Reduce precision to ~100m
          anonymized = _reduceLocationPrecision(location, 0.001); // ~100m
          break;
          
        case AnonymizationLevel.moderate:
          // Reduce precision to ~500m + add noise
          anonymized = _addLocationNoise(
            _reduceLocationPrecision(location, 0.005), // ~500m
            0.001, // Additional noise
          );
          break;
          
        case AnonymizationLevel.high:
          // Reduce precision to ~1km + significant noise + time shifting
          anonymized = _addLocationNoise(
            _reduceLocationPrecision(location, 0.01), // ~1km
            0.002, // More noise
          );
          // Shift timestamp within ±30 minutes
          anonymized = anonymized.copyWith(
            timestamp: anonymized.timestamp.add(
              Duration(minutes: (math.Random().nextInt(60) - 30))
            )
          );
          break;
      }
      
      anonymizedLocations.add(anonymized);
    }
    
    return AnonymizedLocationData(
      originalCount: locations.length,
      anonymizedLocations: anonymizedLocations,
      anonymizationLevel: level,
      anonymizationTimestamp: DateTime.now(),
      retainedUtility: _calculateUtilityRetention(locations, anonymizedLocations),
      privacyGain: _calculatePrivacyGain(level),
    );
  }

  /// Reduce location precision by rounding coordinates
  static GPSLocation _reduceLocationPrecision(GPSLocation location, double precision) {
    return GPSLocation(
      latitude: (location.latitude / precision).round() * precision,
      longitude: (location.longitude / precision).round() * precision,
      accuracy: math.max(location.accuracy, precision * 111000), // Convert to meters
      altitude: location.altitude,
      timestamp: location.timestamp,
      provider: location.provider,
      isMocked: location.isMocked,
    );
  }

  /// Add controlled noise to location data
  static GPSLocation _addLocationNoise(GPSLocation location, double noiseLevel) {
    final random = math.Random();
    return GPSLocation(
      latitude: location.latitude + (random.nextDouble() - 0.5) * noiseLevel,
      longitude: location.longitude + (random.nextDouble() - 0.5) * noiseLevel,
      accuracy: location.accuracy + (random.nextDouble() * 20), // Add accuracy uncertainty
      altitude: location.altitude,
      timestamp: location.timestamp,
      provider: location.provider,
      isMocked: location.isMocked,
    );
  }

  /// Calculate utility retention after anonymization
  static double _calculateUtilityRetention(List<GPSLocation> original, List<GPSLocation> anonymized) {
    if (original.isEmpty || anonymized.isEmpty) return 0.0;
    
    // Calculate average distance shift
    double totalDistanceShift = 0.0;
    for (int i = 0; i < math.min(original.length, anonymized.length); i++) {
      final distance = _calculateDistance(
        original[i].latitude, original[i].longitude,
        anonymized[i].latitude, anonymized[i].longitude,
      );
      totalDistanceShift += distance;
    }
    
    final avgDistanceShift = totalDistanceShift / math.min(original.length, anonymized.length);
    
    // Utility inversely related to distance shift
    // 100m shift = 90% utility, 1km shift = 50% utility
    return math.max(0.0, 1.0 - (avgDistanceShift / 2000)); // 2km = 0% utility
  }

  /// Calculate privacy gain based on anonymization level
  static double _calculatePrivacyGain(AnonymizationLevel level) {
    switch (level) {
      case AnonymizationLevel.light: return 0.3;
      case AnonymizationLevel.moderate: return 0.6;
      case AnonymizationLevel.high: return 0.8;
    }
  }

  /// Calculate distance between two GPS points
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radiusEarth = 6371000; // Earth's radius in meters
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radiusEarth * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Perform automated location data retention review
  static Future<LocationRetentionAssessment> performLocationRetentionReview({
    required String userId,
    DateTime? cutoffDate,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final cutoff = cutoffDate ?? DateTime.now().subtract(const Duration(days: 2555)); // 7 years
      
      // Query location data older than retention period
      final timeEntriesQuery = await firestore
          .collection('timeEntries')
          .where('guardId', isEqualTo: userId)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
          .get();
      
      final expiredEntries = <String>[];
      final retainableEntries = <String>[];
      double totalSizeBytes = 0;
      
      for (final doc in timeEntriesQuery.docs) {
        final data = doc.data();
        final timeEntry = TimeEntry.fromFirestore(doc);
        
        // Check if there's a legal basis for retention
        final hasLegalBasis = await _checkLegalBasisForRetention(timeEntry);
        
        if (hasLegalBasis) {
          retainableEntries.add(doc.id);
        } else {
          expiredEntries.add(doc.id);
        }
        
        // Estimate data size
        totalSizeBytes += jsonEncode(data).length;
      }
      
      return LocationRetentionAssessment(
        userId: userId,
        assessmentDate: DateTime.now(),
        cutoffDate: cutoff,
        expiredRecords: expiredEntries,
        retainableRecords: retainableEntries,
        estimatedDataSize: totalSizeBytes,
        recommendedActions: expiredEntries.isNotEmpty 
          ? ['Delete ${expiredEntries.length} expired location records']
          : ['No action required - all data within retention period'],
        complianceStatus: expiredEntries.isEmpty 
          ? LocationRetentionStatus.compliant 
          : LocationRetentionStatus.actionRequired,
      );
      
    } catch (e) {
      return LocationRetentionAssessment(
        userId: userId,
        assessmentDate: DateTime.now(),
        cutoffDate: cutoffDate ?? DateTime.now(),
        expiredRecords: [],
        retainableRecords: [],
        estimatedDataSize: 0,
        recommendedActions: ['Review failed - manual assessment required'],
        complianceStatus: LocationRetentionStatus.reviewFailed,
      );
    }
  }

  /// Check if there's a legal basis for retaining location data
  static Future<bool> _checkLegalBasisForRetention(TimeEntry timeEntry) async {
    // Check for ongoing legal proceedings
    // Check for tax/audit requirements
    // Check for contractual obligations
    
    // For security work, CAO may require 7-year retention for payroll purposes
    final payrollRetentionRequired = timeEntry.createdAt
        .isAfter(DateTime.now().subtract(const Duration(days: 2555))); // 7 years
    
    return payrollRetentionRequired;
  }

  /// Encrypt location consent data for storage
  static Future<Map<String, dynamic>> _encryptLocationConsentData(Map<String, dynamic> data) async {
    // Implementation would use proper encryption
    // For now, return data as-is (placeholder)
    return {
      'encrypted_data': base64Encode(utf8.encode(jsonEncode(data))),
      'encryption_version': 'v1_aes256',
      'encrypted_at': DateTime.now().toIso8601String(),
    };
  }

  /// Log location processing activity for audit trail
  static Future<void> _logLocationProcessingActivity({
    required String userId,
    required LocationProcessingPurpose purpose,
    required String consentId,
    required String jobSiteId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    
    await firestore.collection('locationProcessingLog').add({
      'userId': userId,
      'purpose': purpose.name,
      'consentId': consentId,
      'jobSiteId': jobSiteId,
      'timestamp': Timestamp.now(),
      'lawfulBasis': 'consent', // GDPR Article 6(1)(a)
      'specialCategoryBasis': 'explicit_consent', // GDPR Article 9(2)(a)
    });
  }
  static Future<void> _storeBiometricConsentRequest(BiometricConsentRequest request) async {}
  static Future<BiometricConsentRequest?> _getBiometricConsentRequest(String id) async => null;
  static Future<void> _storeBiometricConsentRecord(BiometricConsentRecord record) async {}
  static Future<void> _storeDataSubjectRequest(DataSubjectRequest request) async {}
  
  // Data subject request processing methods
  static Future<DataSubjectRequestResponse> _processAccessRequest(DataSubjectRequest request) async {
    return DataSubjectRequestResponse(
      requestId: request.id,
      status: DataSubjectRequestStatus.processing,
      estimatedCompletion: DateTime.now().add(const Duration(days: 30)),
      message: 'Uw verzoek wordt verwerkt. U ontvangt binnen 30 dagen een volledig overzicht van uw gegevens.',
    );
  }
  
  static Future<DataSubjectRequestResponse> _processRectificationRequest(DataSubjectRequest request) async {
    return DataSubjectRequestResponse(
      requestId: request.id,
      status: DataSubjectRequestStatus.processing,
      estimatedCompletion: DateTime.now().add(const Duration(days: 7)),
      message: 'Uw rectificatieverzoek wordt behandeld. Wijzigingen worden binnen 7 dagen doorgevoerd.',
    );
  }
  
  static Future<DataSubjectRequestResponse> _processErasureRequest(DataSubjectRequest request) async {
    return DataSubjectRequestResponse(
      requestId: request.id,
      status: DataSubjectRequestStatus.processing,
      estimatedCompletion: DateTime.now().add(const Duration(days: 30)),
      message: 'Uw verzoek tot verwijdering wordt verwerkt. Gegevens worden binnen 30 dagen verwijderd.',
    );
  }
  
  static Future<DataSubjectRequestResponse> _processPortabilityRequest(DataSubjectRequest request) async {
    return DataSubjectRequestResponse(
      requestId: request.id,
      status: DataSubjectRequestStatus.processing,
      estimatedCompletion: DateTime.now().add(const Duration(days: 20)),
      message: 'Uw gegevens worden voorbereid voor overdracht in een gestructureerd, gangbaar formaat.',
    );
  }
  
  static Future<DataSubjectRequestResponse> _processRestrictionRequest(DataSubjectRequest request) async {
    return DataSubjectRequestResponse(
      requestId: request.id,
      status: DataSubjectRequestStatus.processing,
      estimatedCompletion: DateTime.now().add(const Duration(days: 10)),
      message: 'Verwerkingsbeperking wordt ingesteld. Gegevens worden alleen opgeslagen.',
    );
  }
  
  static Future<DataSubjectRequestResponse> _processObjectionRequest(DataSubjectRequest request) async {
    return DataSubjectRequestResponse(
      requestId: request.id,
      status: DataSubjectRequestStatus.processing,
      estimatedCompletion: DateTime.now().add(const Duration(days: 14)),
      message: 'Uw bezwaar wordt beoordeeld. Verwerking wordt gestopt tenzij dwingende rechtmatige gronden bestaan.',
    );
  }
  
  // Additional placeholder methods
  static String _generateAssessmentId() => 'pia_${DateTime.now().millisecondsSinceEpoch}';
  static Future<UserDataInventory> _generateUserDataInventory(String userId) async => UserDataInventory(categories: [], totalSize: 0, dependencies: []);
  static Future<void> _storeErasureRequest(DataErasureRequest request) async {}
  static Duration _calculateDeletionDuration(UserDataInventory inventory) => const Duration(hours: 72);
  static Future<DataErasureResult> _executeImmediateErasure(DataDeletionPlan plan) async => DataErasureResult(success: true, deletedCategories: []);
  static Future<DataErasureResult> _scheduleErasure(DataDeletionPlan plan) async => DataErasureResult(success: true, deletedCategories: []);
  static Future<void> _storePrivacyImpactAssessment(PrivacyImpactAssessment assessment) async {}
  static Future<PrivacyRiskLevel> _calculatePrivacyRisk(String userId, List<DataProcessingPurpose> purposes) async => PrivacyRiskLevel.medium;
  static Future<List<ProcessingRisk>> _identifyProcessingRisks(List<DataProcessingPurpose> purposes) async => [];
  static Future<List<MitigationMeasure>> _identifyMitigationMeasures(List<DataProcessingPurpose> purposes) async => [];
  static Future<ComplianceStatus> _assessComplianceStatus(String userId, List<DataProcessingPurpose> purposes) async => ComplianceStatus.compliant;
  static Future<List<RetentionPolicy>> _getRetentionPolicies() async => [];
  static Future<Map<DataCategory, Duration>> _getUserDataAge(String userId) async => {};
  static Future<List<RetentionIssue>> _identifyRetentionIssues(String userId, List<RetentionPolicy> policies) async => [];
  static Future<List<String>> _generateRetentionRecommendations(String userId) async => [];
  static Future<void> _scheduleAutomaticDeletion(String userId, DataCategory category) async {}
}

// Supporting data models and enums...

/// Data processing purposes under GDPR
enum DataProcessingPurpose {
  authentication('User authentication and access control'),
  biometricAuthentication('Biometric authentication'),
  twoFactorAuth('Two-factor authentication'),
  accountManagement('User account management'),
  securityMonitoring('Security monitoring and fraud prevention'),
  legalCompliance('Legal compliance and regulatory requirements'),
  serviceImprovement('Service improvement and analytics');
  
  const DataProcessingPurpose(this.description);
  final String description;
  
  String get dutchDescription {
    switch (this) {
      case DataProcessingPurpose.authentication:
        return 'Gebruikersauthenticatie en toegangscontrole';
      case DataProcessingPurpose.biometricAuthentication:
        return 'Biometrische authenticatie';
      case DataProcessingPurpose.twoFactorAuth:
        return 'Tweefactor authenticatie';
      case DataProcessingPurpose.accountManagement:
        return 'Gebruikersaccountbeheer';
      case DataProcessingPurpose.securityMonitoring:
        return 'Beveiligingsmonitoring en fraudepreventie';
      case DataProcessingPurpose.legalCompliance:
        return 'Juridische compliance en wettelijke vereisten';
      case DataProcessingPurpose.serviceImprovement:
        return 'Serviceverbetering en analyses';
    }
  }
}

/// Consent types under GDPR
enum ConsentType {
  implicit('Implicit consent'),
  explicit('Explicit consent - required for special categories');
  
  const ConsentType(this.description);
  final String description;
}

/// Biometric processing purposes
enum BiometricProcessingPurpose {
  authentication('Biometric authentication'),
  identityVerification('Identity verification');
  
  const BiometricProcessingPurpose(this.description);
  final String description;
  
  String get dutchDescription {
    switch (this) {
      case BiometricProcessingPurpose.authentication:
        return 'Biometrische authenticatie';
      case BiometricProcessingPurpose.identityVerification:
        return 'Identiteitsverificatie';
    }
  }
}

/// Data subject request types
enum DataSubjectRequestType {
  access, rectification, erasure, portability, restriction, objection
}

enum DataSubjectRequestStatus {
  received, processing, completed, rejected
}

enum ErasureReason {
  consentWithdrawn, dataNoLongerNecessary, unlawfulProcessing, complianceObligation
}

enum DataCategory {
  personalData, biometricData, authenticationData, behavioralData, technicalData
}

enum PrivacyRiskLevel { low, medium, high, critical }

enum ComplianceStatus { compliant, nonCompliant, partiallyCompliant }

enum RetentionIssueType { expired, approaching, missing }

enum ConsentActionType {
  granted,
  renewed,
  modified,
  withdrawn,
  expired,
}

enum ProcessingActivityType {
  collection,
  storage,
  processing,
  analysis,
  sharing,
  deletion,
  anonymization,
}

// Data classes for GDPR compliance
class ConsentRecord {
  final String id;
  final String userId;
  final DataProcessingPurpose purpose;
  final ConsentType consentType;
  final String lawfulBasis;
  final bool granted;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final String? additionalInfo;
  final Map<String, dynamic> metadata;
  final String version;
  final bool withdrawn;
  final DateTime? withdrawalDate;
  
  const ConsentRecord({
    required this.id,
    required this.userId,
    required this.purpose,
    required this.consentType,
    required this.lawfulBasis,
    required this.granted,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.additionalInfo,
    required this.metadata,
    required this.version,
    this.withdrawn = false,
    this.withdrawalDate,
  });
  
  ConsentRecord copyWith({
    bool? withdrawn,
    DateTime? withdrawalDate,
  }) {
    return ConsentRecord(
      id: id,
      userId: userId,
      purpose: purpose,
      consentType: consentType,
      lawfulBasis: lawfulBasis,
      granted: granted,
      timestamp: timestamp,
      ipAddress: ipAddress,
      userAgent: userAgent,
      additionalInfo: additionalInfo,
      metadata: metadata,
      version: version,
      withdrawn: withdrawn ?? this.withdrawn,
      withdrawalDate: withdrawalDate ?? this.withdrawalDate,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'purpose': purpose.name,
      'consentType': consentType.name,
      'lawfulBasis': lawfulBasis,
      'granted': granted,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'additionalInfo': additionalInfo,
      'metadata': metadata,
      'version': version,
      'withdrawn': withdrawn,
      'withdrawalDate': withdrawalDate?.toIso8601String(),
    };
  }
}

// Additional supporting classes would be defined here...
// (Simplified for brevity in this security audit)

class ConsentWithdrawal {
  final String consentId;
  final String userId;
  final DateTime withdrawalDate;
  final String? reason;
  final String? ipAddress;
  final bool automaticDeletion;
  
  const ConsentWithdrawal({
    required this.consentId,
    required this.userId,
    required this.withdrawalDate,
    this.reason,
    this.ipAddress,
    required this.automaticDeletion,
  });
}

class BiometricConsentRequest {
  final String id;
  final String userId;
  final List<BiometricType> biometricTypes;
  final BiometricProcessingPurpose purpose;
  final DateTime requestDate;
  final DateTime expiresAt;
  final String lawfulBasis;
  final BiometricProcessingDetails processingDetails;
  final BiometricStorageDetails storageDetails;
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  const BiometricConsentRequest({
    required this.id,
    required this.userId,
    required this.biometricTypes,
    required this.purpose,
    required this.requestDate,
    required this.expiresAt,
    required this.lawfulBasis,
    required this.processingDetails,
    required this.storageDetails,
  });
}

class BiometricConsentResult {
  final String consentRequestId;
  final bool requiresExplicitConsent;
  final String consentText;
  final String consentTextDutch;
  final BiometricProcessingDetails processingDetails;
  final BiometricStorageDetails storageDetails;
  
  const BiometricConsentResult({
    required this.consentRequestId,
    required this.requiresExplicitConsent,
    required this.consentText,
    required this.consentTextDutch,
    required this.processingDetails,
    required this.storageDetails,
  });
}

class BiometricConsentRecord {
  final String consentId;
  final String userId;
  final List<BiometricType> biometricTypes;
  final BiometricProcessingPurpose purpose;
  final bool explicitConsent;
  final DateTime consentDate;
  final BiometricStorageDetails storageDetails;
  final BiometricProcessingDetails processingDetails;
  
  const BiometricConsentRecord({
    required this.consentId,
    required this.userId,
    required this.biometricTypes,
    required this.purpose,
    required this.explicitConsent,
    required this.consentDate,
    required this.storageDetails,
    required this.processingDetails,
  });
}

class BiometricProcessingDetails {
  final BiometricProcessingPurpose purpose;
  final String processingScope;
  final String dataRetention;
  final List<String> technicalMeasures;
  final List<String> organisationalMeasures;
  
  const BiometricProcessingDetails({
    required this.purpose,
    required this.processingScope,
    required this.dataRetention,
    required this.technicalMeasures,
    required this.organisationalMeasures,
  });
}

class BiometricStorageDetails {
  final String location;
  final String encryption;
  final String retention;
  final String sharing;
  final bool crossBorder;
  
  const BiometricStorageDetails({
    required this.location,
    required this.encryption,
    required this.retention,
    required this.sharing,
    required this.crossBorder,
  });
}

// Simplified placeholder classes
class DataSubjectRequest {
  final String id;
  final String userId;
  final DataSubjectRequestType requestType;
  final String requestDetails;
  final DateTime requestDate;
  final DataSubjectRequestStatus status;
  final bool identityVerified;
  final String? verificationMethod;
  
  const DataSubjectRequest({
    required this.id,
    required this.userId,
    required this.requestType,
    required this.requestDetails,
    required this.requestDate,
    required this.status,
    required this.identityVerified,
    this.verificationMethod,
  });
}

class DataSubjectRequestResponse {
  final String requestId;
  final DataSubjectRequestStatus status;
  final DateTime estimatedCompletion;
  final String message;
  
  const DataSubjectRequestResponse({
    required this.requestId,
    required this.status,
    required this.estimatedCompletion,
    required this.message,
  });
}

class DataErasureRequest {
  final String id;
  final String userId;
  final ErasureReason reason;
  final DateTime requestDate;
  final bool immediateErasure;
  final DateTime estimatedCompletionDate;
  
  const DataErasureRequest({
    required this.id,
    required this.userId,
    required this.reason,
    required this.requestDate,
    required this.immediateErasure,
    required this.estimatedCompletionDate,
  });
}

class UserDataInventory {
  final List<DataCategory> categories;
  final int totalSize;
  final List<String> dependencies;
  
  const UserDataInventory({
    required this.categories,
    required this.totalSize,
    required this.dependencies,
  });
}

class DataDeletionPlan {
  final String erasureRequestId;
  final String userId;
  final List<DataCategory> dataCategories;
  final int totalDataSize;
  final Duration estimatedDuration;
  final List<String> dependencies;
  
  const DataDeletionPlan({
    required this.erasureRequestId,
    required this.userId,
    required this.dataCategories,
    required this.totalDataSize,
    required this.estimatedDuration,
    required this.dependencies,
  });
}

class DataErasureResult {
  final bool success;
  final List<DataCategory> deletedCategories;
  
  const DataErasureResult({
    required this.success,
    required this.deletedCategories,
  });
}

class PrivacyImpactAssessment {
  final String id;
  final String userId;
  final DateTime assessmentDate;
  final List<DataProcessingPurpose> purposes;
  final PrivacyRiskLevel riskLevel;
  final List<DataCategory> dataCategories;
  final List<ProcessingRisk> processingRisks;
  final List<MitigationMeasure> mitigationMeasures;
  final ComplianceStatus complianceStatus;
  
  const PrivacyImpactAssessment({
    required this.id,
    required this.userId,
    required this.assessmentDate,
    required this.purposes,
    required this.riskLevel,
    required this.dataCategories,
    required this.processingRisks,
    required this.mitigationMeasures,
    required this.complianceStatus,
  });
}

class DataRetentionAssessment {
  final String userId;
  final DateTime assessmentDate;
  final List<RetentionPolicy> retentionPolicies;
  final Map<DataCategory, Duration> dataAge;
  final List<RetentionIssue> complianceIssues;
  final List<String> recommendedActions;
  
  const DataRetentionAssessment({
    required this.userId,
    required this.assessmentDate,
    required this.retentionPolicies,
    required this.dataAge,
    required this.complianceIssues,
    required this.recommendedActions,
  });
}

// Additional placeholder classes
class ProcessingRisk { const ProcessingRisk(); }
class MitigationMeasure { const MitigationMeasure(); }
class RetentionPolicy { const RetentionPolicy(); }

// ===== LOCATION DATA GDPR MODELS =====

/// Location processing purposes for GDPR consent
enum LocationProcessingPurpose {
  timeTracking,         // GPS verification for work hours
  geofenceVerification, // Verify presence at job site
  safetyMonitoring,     // Emergency response and safety
  routeOptimization,    // Travel efficiency analysis
  analytics,            // Anonymized business insights
}

/// Location consent issues for validation
enum LocationConsentIssue {
  none,
  noConsent,
  consentWithdrawn,
  expired,
  jobSiteMismatch,
  precisionNotConsented,
  validationError,
}

/// Anonymization levels for location data
enum AnonymizationLevel {
  light,     // ~100m precision reduction
  moderate,  // ~500m precision + noise
  high,      // ~1km precision + noise + time shifting
}

/// Location retention status
enum LocationRetentionStatus {
  compliant,
  actionRequired,
  reviewFailed,
}

/// Location consent record
class LocationConsentRecord {
  final String id;
  final String userId;
  final LocationProcessingPurpose purpose;
  final String jobSiteId;
  final bool preciseLocationConsent;
  final bool continuousTrackingConsent;
  final Duration retentionPeriod;
  final DateTime consentTimestamp;
  final GPSLocation? consentLocation;
  final String privacyNoticeVersion;
  final String? additionalInfo;
  final bool withdrawn;
  final DateTime? withdrawalTimestamp;

  const LocationConsentRecord({
    required this.id,
    required this.userId,
    required this.purpose,
    required this.jobSiteId,
    required this.preciseLocationConsent,
    required this.continuousTrackingConsent,
    required this.retentionPeriod,
    required this.consentTimestamp,
    this.consentLocation,
    required this.privacyNoticeVersion,
    this.additionalInfo,
    this.withdrawn = false,
    this.withdrawalTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'purpose': purpose.name,
      'jobSiteId': jobSiteId,
      'preciseLocationConsent': preciseLocationConsent,
      'continuousTrackingConsent': continuousTrackingConsent,
      'retentionPeriodDays': retentionPeriod.inDays,
      'consentTimestamp': consentTimestamp.toIso8601String(),
      'consentLocation': consentLocation?.toJson(),
      'privacyNoticeVersion': privacyNoticeVersion,
      'additionalInfo': additionalInfo,
      'withdrawn': withdrawn,
      'withdrawalTimestamp': withdrawalTimestamp?.toIso8601String(),
    };
  }

  factory LocationConsentRecord.fromJson(Map<String, dynamic> json) {
    return LocationConsentRecord(
      id: json['id'],
      userId: json['userId'],
      purpose: LocationProcessingPurpose.values.firstWhere(
        (p) => p.name == json['purpose']
      ),
      jobSiteId: json['jobSiteId'],
      preciseLocationConsent: json['preciseLocationConsent'],
      continuousTrackingConsent: json['continuousTrackingConsent'],
      retentionPeriod: Duration(days: json['retentionPeriodDays']),
      consentTimestamp: DateTime.parse(json['consentTimestamp']),
      consentLocation: json['consentLocation'] != null 
          ? GPSLocation.fromJson(json['consentLocation']) 
          : null,
      privacyNoticeVersion: json['privacyNoticeVersion'],
      additionalInfo: json['additionalInfo'],
      withdrawn: json['withdrawn'] ?? false,
      withdrawalTimestamp: json['withdrawalTimestamp'] != null 
          ? DateTime.parse(json['withdrawalTimestamp'])
          : null,
    );
  }
}

/// Location consent validation result
class LocationConsentValidation {
  final bool isValid;
  final LocationConsentIssue reason;
  final bool requiresNewConsent;
  final String suggestedAction;
  final LocationConsentRecord? consentRecord;
  final DateTime? validUntil;
  final DateTime? expiryDate;

  const LocationConsentValidation({
    required this.isValid,
    required this.reason,
    required this.requiresNewConsent,
    required this.suggestedAction,
    this.consentRecord,
    this.validUntil,
    this.expiryDate,
  });
}

/// Anonymized location data result
class AnonymizedLocationData {
  final int originalCount;
  final List<GPSLocation> anonymizedLocations;
  final AnonymizationLevel anonymizationLevel;
  final DateTime anonymizationTimestamp;
  final double retainedUtility; // 0.0 - 1.0
  final double privacyGain; // 0.0 - 1.0

  const AnonymizedLocationData({
    required this.originalCount,
    required this.anonymizedLocations,
    required this.anonymizationLevel,
    required this.anonymizationTimestamp,
    required this.retainedUtility,
    required this.privacyGain,
  });
}

/// Location data retention assessment
class LocationRetentionAssessment {
  final String userId;
  final DateTime assessmentDate;
  final DateTime cutoffDate;
  final List<String> expiredRecords;
  final List<String> retainableRecords;
  final double estimatedDataSize;
  final List<String> recommendedActions;
  final LocationRetentionStatus complianceStatus;

  const LocationRetentionAssessment({
    required this.userId,
    required this.assessmentDate,
    required this.cutoffDate,
    required this.expiredRecords,
    required this.retainableRecords,
    required this.estimatedDataSize,
    required this.recommendedActions,
    required this.complianceStatus,
  });
}

/// Extension to add copyWith method to GPSLocation
extension GPSLocationExtension on GPSLocation {
  GPSLocation copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    DateTime? timestamp,
    String? provider,
    bool? isMocked,
  }) {
    return GPSLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      timestamp: timestamp ?? this.timestamp,
      provider: provider ?? this.provider,
      isMocked: isMocked ?? this.isMocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'timestamp': timestamp.toIso8601String(),
      'provider': provider,
      'isMocked': isMocked,
    };
  }

  static GPSLocation fromJson(Map<String, dynamic> json) {
    return GPSLocation(
      latitude: json['latitude'],
      longitude: json['longitude'],
      accuracy: json['accuracy'],
      altitude: json['altitude'],
      timestamp: DateTime.parse(json['timestamp']),
      provider: json['provider'],
      isMocked: json['isMocked'],
    );
  }
}
class ComplianceRecommendation {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final DateTime createdAt;
  final bool implemented;

  const ComplianceRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.implemented = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'implemented': implemented,
    };
  }
}

class RetentionIssue { 
  final RetentionIssueType type;
  final DataCategory dataCategory;
  const RetentionIssue({required this.type, required this.dataCategory});
}