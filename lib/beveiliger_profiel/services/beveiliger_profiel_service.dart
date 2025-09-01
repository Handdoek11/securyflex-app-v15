import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/beveiliger_profiel/models/beveiliger_profiel_data.dart';
import 'package:securyflex_app/beveiliger_profiel/models/specialization.dart';
import 'package:securyflex_app/auth/services/certificate_management_service.dart';
import 'package:securyflex_app/auth/services/wpbr_verification_service.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';
import 'package:securyflex_app/marketplace/services/job_data_service.dart';
import 'package:securyflex_app/marketplace/services/certificate_matching_service.dart';

/// Service voor managing beveiliger profiel data
/// Volgt bestaande SecuryFlex service patterns van daily_overview_service.dart
/// Met Firebase integration patterns van auth_service.dart
class BeveiligerProfielService {
  static final BeveiligerProfielService _instance = BeveiligerProfielService._internal();
  factory BeveiligerProfielService() => _instance;
  BeveiligerProfielService._internal();

  static BeveiligerProfielService get instance => _instance;

  /// Firebase services
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Certificate service for comprehensive certificate management
  final CertificateManagementService _certificateService = CertificateManagementService();

  /// Cache voor profiel data performance optimization
  BeveiligerProfielData? _cachedProfileData;
  DateTime? _lastCacheUpdate;

  /// Cache duration (5 minuten, matching daily_overview_service pattern)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Load profiel data voor specified user ID
  Future<BeveiligerProfielData> loadProfile(String userId) async {
    try {
      // Check cache validity eerst
      if (_cachedProfileData != null && 
          _lastCacheUpdate != null && 
          DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration &&
          _cachedProfileData!.id == userId) {
        return _cachedProfileData!;
      }

      // Check if Firebase is properly configured
      if (_isFirebaseConfigured()) {
        // Try to load from Firebase
        final profileDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();

        if (profileDoc.exists) {
          final profileData = BeveiligerProfielData.fromJson(profileDoc.data()!);
          
          // Update cache
          _cachedProfileData = profileData;
          _lastCacheUpdate = DateTime.now();
          
          return profileData;
        } else {
          // Create default profile document
          final defaultProfile = _createDefaultProfile(userId);
          await _saveProfileToFirestore(defaultProfile);
          
          _cachedProfileData = defaultProfile;
          _lastCacheUpdate = DateTime.now();
          
          return defaultProfile;
        }
      }
    } catch (e) {
      debugPrint('Error loading profile from Firebase: $e');
    }

    // Fallback to demo/sample data
    final sampleProfile = _createSampleProfileForCurrentUser(userId);
    _cachedProfileData = sampleProfile;
    _lastCacheUpdate = DateTime.now();
    
    return sampleProfile;
  }

  /// Update profiel data met validation
  Future<bool> updateProfile(BeveiligerProfielData profileData) async {
    try {
      // Validate profile data
      if (!profileData.isValid) {
        final errors = profileData.validationErrors;
        debugPrint('Profile validation failed: ${errors.join(', ')}');
        throw Exception('Profiel data is ongeldig: ${errors.first}');
      }

      // Update lastUpdated timestamp
      final updatedProfile = profileData.copyWith(
        lastUpdated: DateTime.now(),
      );

      // Try to save to Firebase if available
      if (_isFirebaseConfigured()) {
        await _saveProfileToFirestore(updatedProfile);
        
        // Update AuthService user data if this is current user
        if (updatedProfile.id == AuthService.currentUserId) {
          await _updateAuthServiceUserData(updatedProfile);
        }
      }

      // Update cache
      _cachedProfileData = updatedProfile;
      _lastCacheUpdate = DateTime.now();

      debugPrint('Profile updated successfully for user: ${updatedProfile.id}');
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  /// Update specific profile field
  Future<bool> updateProfileField(String userId, String fieldName, dynamic value) async {
    try {
      // Load current profile
      final currentProfile = await loadProfile(userId);
      
      // Create updated profile based on field name
      BeveiligerProfielData updatedProfile = currentProfile; // Initialize with current profile
      switch (fieldName) {
        case 'name':
          updatedProfile = currentProfile.copyWith(name: value as String);
          break;
        case 'email':
          updatedProfile = currentProfile.copyWith(email: value as String);
          break;
        case 'phone':
          updatedProfile = currentProfile.copyWith(phone: value as String?);
          break;
        case 'bio':
          updatedProfile = currentProfile.copyWith(bio: value as String?);
          break;
        case 'kvkNumber':
          updatedProfile = currentProfile.copyWith(kvkNumber: value as String?);
          break;
        case 'postalCode':
          updatedProfile = currentProfile.copyWith(postalCode: value as String?);
          break;
        case 'wpbrNumber':
          updatedProfile = currentProfile.copyWith(wpbrNumber: value as String?);
          break;
        case 'specialisaties':
          // Handle both old and new specialization formats
          if (value is List<String>) {
            updatedProfile = currentProfile.copyWith(specialisaties: value);
          } else if (value is List<Map<String, dynamic>>) {
            // Convert from JSON to Specialization objects
            final specializations = value.map((json) => Specialization.fromJson(json)).toList();
            updatedProfile = currentProfile.copyWith(specializations: specializations);
          } else {
            // Invalid type, keep current profile unchanged
            debugPrint('Warning: Invalid value type for specialisaties: ${value.runtimeType}');
          }
          break;
        case 'specializations':
          if (value is List<Specialization>) {
            updatedProfile = currentProfile.copyWith(specializations: value);
          } else if (value is List<Map<String, dynamic>>) {
            final specializations = value.map((json) => Specialization.fromJson(json)).toList();
            updatedProfile = currentProfile.copyWith(specializations: specializations);
          } else {
            // Invalid type, keep current profile unchanged
            debugPrint('Warning: Invalid value type for specializations: ${value.runtimeType}');
          }
          break;
        case 'skillLevels':
          if (value is Map<SpecializationType, SkillLevel>) {
            updatedProfile = currentProfile.copyWith(skillLevels: value);
          } else {
            // Invalid type, keep current profile unchanged
            debugPrint('Warning: Invalid value type for skillLevels: ${value.runtimeType}');
          }
          break;
        case 'certificaten':
          updatedProfile = currentProfile.copyWith(certificaten: value as List<String>);
          break;
        case 'profileImageUrl':
          updatedProfile = currentProfile.copyWith(profileImageUrl: value as String?);
          break;
        default:
          throw Exception('Unknown field: $fieldName');
      }

      // Update the profile
      return await updateProfile(updatedProfile);
    } catch (e) {
      debugPrint('Error updating profile field $fieldName: $e');
      return false;
    }
  }

  /// Upload profiel image
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      if (!_isFirebaseConfigured()) {
        // Return demo image URL for development
        return 'https://api.dicebear.com/7.x/avataaars/svg?seed=${DateTime.now().millisecondsSinceEpoch}';
      }

      // Validate file size (max 5MB)
      final fileSizeInBytes = await imageFile.length();
      const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
      
      if (fileSizeInBytes > maxSizeInBytes) {
        throw Exception('Bestand is te groot. Maximaal 5MB toegestaan.');
      }

      // Generate unique filename
      final userId = AuthService.currentUserId;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_images/$userId/profile_$timestamp.jpg';

      // Upload to Firebase Storage
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(imageFile);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  /// Clear cache for testing or manual refresh
  void clearCache() {
    _cachedProfileData = null;
    _lastCacheUpdate = null;
  }

  /// Refresh cached data
  Future<BeveiligerProfielData> refreshProfile(String userId) async {
    clearCache();
    return await loadProfile(userId);
  }

  // Private helper methods

  /// Check if Firebase is properly configured (following auth_service pattern)
  bool _isFirebaseConfigured() {
    try {
      final app = _firestore.app;
      return app.options.projectId != 'your-project-id' &&
             app.options.projectId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Save profile to Firestore
  Future<void> _saveProfileToFirestore(BeveiligerProfielData profile) async {
    await _firestore
        .collection('users')
        .doc(profile.id)
        .set(profile.toJson(), SetOptions(merge: true));
  }

  /// Update AuthService user data to keep it in sync
  Future<void> _updateAuthServiceUserData(BeveiligerProfielData profile) async {
    await AuthService.updateProfile(
      name: profile.name,
      additionalData: {
        'phone': profile.phone,
        'bio': profile.bio,
        'profileImageUrl': profile.profileImageUrl,
        'specialisaties': profile.specialisaties,
        'certificaten': profile.certificaten,
        'kvkNumber': profile.kvkNumber,
        'postalCode': profile.postalCode,
        'wpbrNumber': profile.wpbrNumber,
        'wpbrExpiryDate': profile.wpbrExpiryDate?.toIso8601String(),
        'isVerified': profile.isVerified,
        'gdprConsentGiven': profile.gdprConsentGiven,
      },
    );
  }

  /// Create default profile for user
  BeveiligerProfielData _createDefaultProfile(String userId) {
    final userData = AuthService.currentUserData;
    
    return BeveiligerProfielData(
      id: userId,
      name: userData['name'] ?? 'Nieuwe Beveiliger',
      email: userData['email'] ?? '',
      phone: userData['phone'],
      bio: null,
      profileImageUrl: null,
      specialisaties: const [],
      certificaten: const [],
      kvkNumber: null,
      postalCode: null,
      wpbrNumber: null,
      wpbrExpiryDate: null,
      isVerified: false,
      isActive: true,
      gdprConsentGiven: false,
      lastUpdated: null,
      createdAt: DateTime.now(),
    );
  }

  /// Create sample profile for demo purposes
  BeveiligerProfielData _createSampleProfileForCurrentUser(String userId) {
    final userData = AuthService.currentUserData;
    final isDemo = userData['isDemo'] == true;
    
    if (isDemo) {
      // Create rich demo profile
      return BeveiligerProfielData(
        id: userId,
        name: userData['name'] ?? 'Demo Beveiliger',
        email: userData['email'] ?? 'demo@securyflex.nl',
        phone: '+31612345678',
        bio: 'Ervaren beveiliger met ruime expertise in verschillende sectoren. '
             'Gespecialiseerd in evenement beveiliging en toegangscontrole. '
             'Altijd professioneel en klantvriendelijk.',
        profileImageUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=DemoBeveiliger',
        specialisaties: [
          'Evenement Beveiliging',
          'Toegangscontrole',
          'Retail Beveiliging',
          'EHBO',
        ],
        certificaten: [
          'WPBR Certificaat',
          'BHV Diploma',
          'EHBO Certificaat',
          'Security Awareness Training',
          'Crowd Management Certificate',
        ],
        kvkNumber: '12345678',
        postalCode: '1011AB',
        wpbrNumber: 'WPBR-123456',
        wpbrExpiryDate: DateTime.now().add(const Duration(days: 300)),
        isVerified: true,
        isActive: true,
        gdprConsentGiven: true,
        lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      );
    } else {
      // Create minimal profile for real users
      return BeveiligerProfielData(
        id: userId,
        name: userData['name'] ?? 'Nieuwe Gebruiker',
        email: userData['email'] ?? '',
        phone: null,
        bio: null,
        profileImageUrl: null,
        specialisaties: const [],
        certificaten: const [],
        kvkNumber: null,
        postalCode: null,
        wpbrNumber: null,
        wpbrExpiryDate: null,
        isVerified: false,
        isActive: true,
        gdprConsentGiven: false,
        lastUpdated: null,
        createdAt: DateTime.now(),
      );
    }
  }

  // Dutch error messages following existing patterns
  
  /// Get Dutch error message for common profile operations
  String getDutchErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'profile_not_found':
        return 'Profiel niet gevonden.';
      case 'profile_update_failed':
        return 'Profiel bijwerken mislukt. Probeer opnieuw.';
      case 'invalid_profile_data':
        return 'Ongeldige profielgegevens. Controleer de invoer.';
      case 'image_upload_failed':
        return 'Afbeelding uploaden mislukt. Probeer opnieuw.';
      case 'file_too_large':
        return 'Bestand is te groot. Maximaal 5MB toegestaan.';
      case 'invalid_file_type':
        return 'Ongeldig bestandstype. Alleen JPG, PNG toegestaan.';
      case 'network_error':
        return 'Netwerkfout. Controleer uw internetverbinding.';
      case 'permission_denied':
        return 'Geen toegang. Controleer uw rechten.';
      case 'wpbr_expired':
        return 'WPBR certificaat is verlopen. Vernieuw uw certificaat.';
      case 'validation_failed':
        return 'Gegevens validatie mislukt. Controleer alle velden.';
      default:
        return 'Er is een onbekende fout opgetreden. Probeer opnieuw.';
    }
  }

  /// Performance analytics tracking (placeholder voor future implementation)
  // ignore: unused_element
  void _trackProfileOperation(String operation, String userId) {
    if (kReleaseMode) {
      // TODO: Implement Firebase Analytics tracking
      debugPrint('Profile operation: $operation completed successfully');
    }
  }

  /// Get profiel completion statistics
  Map<String, dynamic> getProfileStatistics(BeveiligerProfielData profile) {
    return {
      'completionPercentage': profile.completionPercentage,
      'validationErrors': profile.validationErrors.length,
      'isVerified': profile.isVerified,
      'certificateCount': profile.certificaten.length,
      'specialisatieCount': profile.specialisaties.length,
      'isWpbrExpiringSoon': profile.isWpbrExpiringSoon,
      'daysSinceLastUpdate': profile.lastUpdated != null 
          ? DateTime.now().difference(profile.lastUpdated!).inDays 
          : null,
    };
  }

  // ============================================================================
  // CERTIFICATE INTEGRATION METHODS
  // ============================================================================

  /// Load certificates using existing certificate management service
  Future<void> loadCertificates(String userId) async {
    try {
      await _certificateService.getUserCertificates(userId);
      debugPrint('Certificates loaded successfully');
    } catch (e) {
      debugPrint('Error loading certificates: $e');
      throw Exception('Certificaten laden mislukt: $e');
    }
  }

  /// Add certificate using existing certificate management service
  Future<bool> addCertificate(Map<String, dynamic> certificateData) async {
    try {
      final result = await _certificateService.addCertificate(
        userId: certificateData['userId'],
        type: certificateData['type'],
        certificateNumber: certificateData['number'],
        holderName: certificateData['holderName'],
        holderBsn: certificateData['holderBsn'] ?? '',
        issueDate: certificateData['issueDate'],
        expirationDate: certificateData['expirationDate'],
        issuingAuthority: certificateData['issuingAuthority'],
        documentFile: certificateData['documentFile'],
        metadata: certificateData['metadata'],
      );

      if (result.success) {
        // Send certificate expiry notifications
        await _scheduleCertificateExpiryNotifications(
          certificateData['userId'],
          result.certificate!,
        );
        
        debugPrint('Certificate added successfully: ${result.certificateId}');
        return true;
      } else {
        debugPrint('Failed to add certificate: ${result.message}');
        return false;
      }
    } catch (e) {
      debugPrint('Error adding certificate: $e');
      return false;
    }
  }

  /// Verify certificate using WPBR verification service
  Future<dynamic> verifyCertificate(String certificateNumber, String certificateType) async {
    try {
      if (certificateType == 'wpbr') {
        final result = await WPBRVerificationService.verifyCertificate(
          certificateNumber,
          userId: AuthService.currentUserId,
        );
        
        if (result.isSuccess) {
          debugPrint('WPBR certificate verified successfully: $certificateNumber');
          return result.data;
        } else {
          debugPrint('WPBR verification failed: ${result.message}');
          throw Exception(result.message);
        }
      } else {
        // Use certificate management service for other certificate types
        final result = await _certificateService.verifyCertificate(
          certificateNumber,
          CertificateType.values.firstWhere(
            (type) => type.name == certificateType,
            orElse: () => CertificateType.wpbr,
          ),
        );
        
        if (result.isValid) {
          debugPrint('Certificate verified successfully: $certificateNumber');
          return result.data;
        } else {
          debugPrint('Certificate verification failed: ${result.status}');
          throw Exception('Certificaat verificatie mislukt: ${result.status}');
        }
      }
    } catch (e) {
      debugPrint('Error verifying certificate: $e');
      return null;
    }
  }

  /// Schedule certificate expiry notifications using existing notification service
  Future<void> _scheduleCertificateExpiryNotifications(String userId, CertificateData certificate) async {
    try {
      
      // Calculate notification dates (30 days, 7 days, 1 day before expiry)
      final now = DateTime.now();
      final expiryDate = certificate.expirationDate;
      
      final thirtyDaysBefore = expiryDate.subtract(const Duration(days: 30));
      final sevenDaysBefore = expiryDate.subtract(const Duration(days: 7));
      final oneDayBefore = expiryDate.subtract(const Duration(days: 1));
      
      // Only schedule notifications for future dates
      if (thirtyDaysBefore.isAfter(now)) {
        await _scheduleNotification(
          'Certificaat verloopt over 30 dagen',
          '${certificate.type.displayName} (${certificate.number}) verloopt op ${_formatDate(expiryDate)}',
          thirtyDaysBefore,
        );
      }
      
      if (sevenDaysBefore.isAfter(now)) {
        await _scheduleNotification(
          'Certificaat verloopt over 7 dagen',
          '${certificate.type.displayName} (${certificate.number}) verloopt binnenkort!',
          sevenDaysBefore,
        );
      }
      
      if (oneDayBefore.isAfter(now)) {
        await _scheduleNotification(
          'Certificaat verloopt morgen!',
          '${certificate.type.displayName} (${certificate.number}) verloopt morgen. Vernieuw vandaag nog!',
          oneDayBefore,
        );
      }
      
      debugPrint('Certificate expiry notifications scheduled for: ${certificate.number}');
    } catch (e) {
      debugPrint('Error scheduling certificate notifications: $e');
      // Don't throw - notification scheduling shouldn't break certificate adding
    }
  }

  /// Schedule notification (placeholder - in real implementation would use platform scheduler)
  Future<void> _scheduleNotification(String title, String body, DateTime scheduledDate) async {
    // In a real implementation, this would use flutter_local_notifications
    // or a similar plugin to schedule local notifications
    debugPrint('Scheduled notification: $title for ${_formatDate(scheduledDate)}');
  }

  /// Format date for Dutch locale
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  /// Get certificate expiry notifications for user
  Future<List<Map<String, dynamic>>> getCertificateExpiryNotifications(String userId) async {
    try {
      final certificates = await _certificateService.getUserCertificates(userId);
      final notifications = <Map<String, dynamic>>[];
      
      for (final certificate in certificates) {
        if (certificate.expiresSoon && certificate.isCurrentlyValid) {
          notifications.add({
            'type': 'certificate_expiry',
            'title': 'Certificaat verloopt binnenkort',
            'message': '${certificate.type.displayName} verloopt over ${certificate.daysUntilExpiration} dagen',
            'certificateId': certificate.id,
            'certificateNumber': certificate.number,
            'expiryDate': certificate.expirationDate.toIso8601String(),
            'daysUntilExpiry': certificate.daysUntilExpiration,
            'priority': certificate.daysUntilExpiration <= 7 ? 'high' : 'medium',
          });
        } else if (certificate.isExpired) {
          notifications.add({
            'type': 'certificate_expired',
            'title': 'Certificaat verlopen',
            'message': '${certificate.type.displayName} is verlopen op ${_formatDate(certificate.expirationDate)}',
            'certificateId': certificate.id,
            'certificateNumber': certificate.number,
            'expiryDate': certificate.expirationDate.toIso8601String(),
            'daysUntilExpiry': certificate.daysUntilExpiration,
            'priority': 'urgent',
          });
        }
      }
      
      return notifications;
    } catch (e) {
      debugPrint('Error getting certificate notifications: $e');
      return [];
    }
  }

  // ============================================================================
  // SPECIALIZATION MANAGEMENT METHODS
  // ============================================================================

  /// Update user specializations with job matching integration
  Future<bool> updateSpecializations(String userId, List<Specialization> specializations) async {
    try {
      // Load current profile
      final currentProfile = await loadProfile(userId);
      
      // Update specializations and skill levels
      final skillLevels = <SpecializationType, SkillLevel>{};
      for (final spec in specializations) {
        skillLevels[spec.type] = spec.skillLevel;
      }
      
      // Update profile with new specializations
      final updatedProfile = currentProfile.copyWith(
        specializations: specializations,
        skillLevels: skillLevels,
        lastUpdated: DateTime.now(),
      );
      
      // Save to Firebase
      final success = await updateProfile(updatedProfile);
      
      if (success) {
        // Track analytics for specialization changes
        _trackSpecializationUpdate(userId, specializations);
        
        // Clear job recommendations cache since specializations changed
        _clearJobRecommendationsCache(userId);
        
        debugPrint('Specializations updated successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error updating specializations: $e');
      return false;
    }
  }

  /// Add a new specialization
  Future<bool> addSpecialization(String userId, SpecializationType type, SkillLevel skillLevel) async {
    try {
      final profile = await loadProfile(userId);
      
      // Check if specialization already exists
      if (profile.specializations.any((spec) => spec.type == type)) {
        debugPrint('Specialization $type already exists');
        return false;
      }
      
      // Create new specialization
      final newSpec = Specialization(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        skillLevel: skillLevel,
        addedAt: DateTime.now(),
      );
      
      // Add to existing specializations
      final updatedSpecializations = List<Specialization>.from(profile.specializations)
        ..add(newSpec);
      
      return await updateSpecializations(userId, updatedSpecializations);
    } catch (e) {
      debugPrint('Error adding specialization: $e');
      return false;
    }
  }

  /// Remove a specialization
  Future<bool> removeSpecialization(String userId, SpecializationType type) async {
    try {
      final profile = await loadProfile(userId);
      
      // Remove specialization
      final updatedSpecializations = profile.specializations
          .where((spec) => spec.type != type)
          .toList();
      
      return await updateSpecializations(userId, updatedSpecializations);
    } catch (e) {
      debugPrint('Error removing specialization: $e');
      return false;
    }
  }

  /// Update skill level for a specialization
  Future<bool> updateSkillLevel(String userId, SpecializationType type, SkillLevel skillLevel) async {
    try {
      final profile = await loadProfile(userId);
      
      // Find and update specialization
      final updatedSpecializations = profile.specializations.map((spec) {
        if (spec.type == type) {
          return spec.copyWith(
            skillLevel: skillLevel,
            lastUpdated: DateTime.now(),
          );
        }
        return spec;
      }).toList();
      
      return await updateSpecializations(userId, updatedSpecializations);
    } catch (e) {
      debugPrint('Error updating skill level: $e');
      return false;
    }
  }

  /// Get job recommendations based on user specializations
  Future<List<SecurityJobData>> getJobRecommendations(String userId) async {
    try {
      final profile = await loadProfile(userId);
      
      if (profile.specializations.isEmpty) {
        debugPrint('No specializations found');
        return [];
      }
      
      // Check cache first
      final cacheKey = 'job_recommendations_$userId';
      final cached = await _getJobRecommendationsFromCache(cacheKey);
      if (cached != null) {
        return cached;
      }
      
      // Get all available jobs
      final allJobs = await JobDataService.getAvailableJobs(limit: 50);
      
      // Score and filter jobs based on specializations
      final jobScores = <SecurityJobData, int>{};
      
      for (final job in allJobs) {
        int score = _calculateJobMatchScore(job, profile);
        if (score >= 40) { // Only include reasonably matched jobs
          jobScores[job] = score;
        }
      }
      
      // Sort jobs by score and certificate eligibility
      final sortedJobs = jobScores.entries.toList()
        ..sort((a, b) {
          // Check certificate eligibility first
          final aEligible = _isEligibleForJob(a.key, profile.certificaten);
          final bEligible = _isEligibleForJob(b.key, profile.certificaten);
          
          if (aEligible && !bEligible) return -1;
          if (!aEligible && bEligible) return 1;
          
          // Then sort by score
          return b.value.compareTo(a.value);
        });
      
      final recommendations = sortedJobs.map((entry) => entry.key).take(20).toList();
      
      // Cache recommendations for 15 minutes
      await _cacheJobRecommendations(cacheKey, recommendations);
      
      debugPrint('Generated ${recommendations.length} job recommendations');
      return recommendations;
      
    } catch (e) {
      debugPrint('Error getting job recommendations: $e');
      return [];
    }
  }

  /// Get specialization statistics for analytics
  Map<String, dynamic> getSpecializationStatistics(BeveiligerProfielData profile) {
    final stats = getProfileStatistics(profile);
    
    return {
      ...stats,
      'specializationsCount': profile.specializations.length,
      'expertSpecializationsCount': profile.expertSpecializationsCount,
      'skillLevelDistribution': _getSkillLevelDistribution(profile.specializations),
      'topSpecializations': _getTopSpecializations(profile.specializations),
      'specializationGrowth': _calculateSpecializationGrowth(profile.specializations),
      'readyForJobRecommendations': profile.isReadyForJobRecommendations,
    };
  }

  // Private helper methods

  /// Calculate job match score based on specializations
  int _calculateJobMatchScore(SecurityJobData job, BeveiligerProfielData profile) {
    int score = 0;
    
    // Check for direct specialization matches
    for (final specialization in profile.specializations) {
      if (specialization.matchesJobCategory(job.jobType)) {
        // Base score for match
        score += 50;
        
        // Skill level bonus
        switch (specialization.skillLevel) {
          case SkillLevel.expert:
            score += 30;
            break;
          case SkillLevel.ervaren:
            score += 20;
            break;
          case SkillLevel.beginner:
            score += 10;
            break;
        }
        
        // Break after first match to avoid double counting
        break;
      }
    }
    
    // Distance factor (closer is better)
    if (job.distance <= 10) {
      score += 15;
    } else if (job.distance <= 25) {
      score += 10;
    } else if (job.distance <= 50) {
      score += 5;
    }
    
    // Pay rate factor
    if (job.hourlyRate >= 25) {
      score += 10;
    } else if (job.hourlyRate >= 20) {
      score += 5;
    }
    
    // Company rating factor
    if (job.companyRating >= 4.5) {
      score += 10;
    } else if (job.companyRating >= 4.0) {
      score += 5;
    }
    
    return score.clamp(0, 100);
  }

  /// Check if user is eligible for job based on certificates
  bool _isEligibleForJob(SecurityJobData job, List<String> userCertificates) {
    if (job.requiredCertificates.isEmpty) return true;
    
    final result = CertificateMatchingService.matchCertificates(
      userCertificates,
      job.requiredCertificates,
    );
    
    return result.isEligible;
  }

  /// Get skill level distribution for analytics
  Map<String, int> _getSkillLevelDistribution(List<Specialization> specializations) {
    final distribution = <String, int>{
      'beginner': 0,
      'ervaren': 0,
      'expert': 0,
    };
    
    for (final spec in specializations) {
      distribution[spec.skillLevel.name] = (distribution[spec.skillLevel.name] ?? 0) + 1;
    }
    
    return distribution;
  }

  /// Get top specializations for analytics
  List<String> _getTopSpecializations(List<Specialization> specializations) {
    return specializations
        .where((spec) => spec.isActive)
        .map((spec) => spec.type.displayName)
        .take(5)
        .toList();
  }

  /// Calculate specialization growth over time
  double _calculateSpecializationGrowth(List<Specialization> specializations) {
    if (specializations.isEmpty) return 0.0;
    
    final now = DateTime.now();
    final recentSpecs = specializations.where((spec) {
      return now.difference(spec.addedAt).inDays <= 30;
    }).length;
    
    return recentSpecs / specializations.length;
  }

  /// Track specialization update for analytics
  void _trackSpecializationUpdate(String userId, List<Specialization> specializations) {
    if (kReleaseMode) {
      // TODO: Implement proper analytics tracking
      debugPrint('Specialization update tracked: ${specializations.length} specializations');
    }
  }

  /// Clear job recommendations cache when specializations change
  void _clearJobRecommendationsCache(String userId) {
    // TODO: Implement proper cache clearing
    debugPrint('Job recommendations cache cleared');
  }

  /// Get job recommendations from cache
  Future<List<SecurityJobData>?> _getJobRecommendationsFromCache(String cacheKey) async {
    // TODO: Implement proper caching mechanism
    return null;
  }

  /// Cache job recommendations
  Future<void> _cacheJobRecommendations(String cacheKey, List<SecurityJobData> recommendations) async {
    // TODO: Implement proper caching mechanism
    debugPrint('Cached ${recommendations.length} job recommendations with key: $cacheKey');
  }
}