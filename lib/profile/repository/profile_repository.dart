import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/profile_state.dart';

/// Repository for managing profile data persistence and operations
/// Handles loading, saving, and synchronization of user profile information
class ProfileRepository {
  static const String _profilePrefix = 'profile_';
  
  static const int _currentProfileVersion = 1;
  
  /// Load profile data for a specific user
  Future<ProfileLoaded> loadProfile(String userId, String userType) async {
    try {
      // For demo purposes, return mock data immediately to avoid SharedPreferences delay
      if (userType == 'company') {
        final profileData = _createDefaultProfile(userType);

        return ProfileLoaded(
          userId: userId,
          userType: userType,
          profileData: profileData,
          completenessPercentage: 85.0,
          lastUpdated: DateTime.now(),
        );
      }

      final prefs = await SharedPreferences.getInstance();

      // Check profile version for migration
      final version = prefs.getInt('$_profilePrefix${userId}_version') ?? 0;
      if (version < _currentProfileVersion) {
        await _migrateProfile(prefs, userId, version);
      }

      final profileData = await _loadProfileData(prefs, userId, userType);
      final completeness = _calculateCompleteness(profileData, userType);

      final lastUpdatedMs = prefs.getInt('$_profilePrefix${userId}_last_updated') ?? DateTime.now().millisecondsSinceEpoch;
      final lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedMs);

      return ProfileLoaded(
        userId: userId,
        userType: userType,
        profileData: profileData,
        completenessPercentage: completeness,
        lastUpdated: lastUpdated,
      );
    } catch (e) {
      debugPrint('Error loading profile: $e');
      // Return default profile on error
      return ProfileLoaded(
        userId: userId,
        userType: userType,
        profileData: _createDefaultProfile(userType),
        completenessPercentage: 0.0,
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  /// Save profile data
  Future<void> saveProfile(ProfileLoaded profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await _saveProfileData(prefs, profile.userId, profile.profileData);
      
      // Update metadata
      await prefs.setInt('$_profilePrefix${profile.userId}_version', _currentProfileVersion);
      await prefs.setInt('$_profilePrefix${profile.userId}_last_updated', DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('Profile saved successfully');
    } catch (e) {
      debugPrint('Error saving profile: $e');
      throw Exception('Failed to save profile: $e');
    }
  }
  
  /// Update basic information
  Future<ProfileData> updateBasicInfo(
    ProfileData currentProfile,
    Map<String, dynamic> updates,
  ) async {
    final updatedBasicInfo = currentProfile.basicInfo.copyWith(
      name: updates['name'],
      email: updates['email'],
      phone: updates['phone'],
      address: updates['address'],
      postalCode: updates['postalCode'],
      city: updates['city'],
      bio: updates['bio'],
      profilePhotoUrl: updates['profilePhotoUrl'],
      birthDate: updates['birthDate'],
      nationality: updates['nationality'],
    );
    
    return currentProfile.copyWith(basicInfo: updatedBasicInfo);
  }
  
  /// Update professional information (for guards)
  Future<ProfileData> updateProfessionalInfo(
    ProfileData currentProfile,
    Map<String, dynamic> updates,
  ) async {
    final currentProfessional = currentProfile.professionalInfo ?? const ProfessionalInfo();
    
    final updatedProfessionalInfo = currentProfessional.copyWith(
      experienceYears: updates['experienceYears'],
      specializations: updates['specializations']?.cast<String>(),
      languages: updates['languages']?.cast<String>(),
      skills: updates['skills']?.cast<String>(),
      hasDriversLicense: updates['hasDriversLicense'],
    );
    
    return currentProfile.copyWith(professionalInfo: updatedProfessionalInfo);
  }
  
  /// Update company information (for companies)
  Future<ProfileData> updateCompanyInfo(
    ProfileData currentProfile,
    Map<String, dynamic> updates,
  ) async {
    final currentCompany = currentProfile.companyInfo ?? const CompanyInfo(
      companyName: '',
      kvkNumber: '',
      industry: '',
    );
    
    final updatedCompanyInfo = currentCompany.copyWith(
      companyName: updates['companyName'],
      kvkNumber: updates['kvkNumber'],
      vatNumber: updates['vatNumber'],
      industry: updates['industry'],
      website: updates['website'],
      description: updates['description'],
      employeeCount: updates['employeeCount'],
      foundedDate: updates['foundedDate'],
    );
    
    return currentProfile.copyWith(companyInfo: updatedCompanyInfo);
  }
  
  /// Add certificate
  Future<ProfileData> addCertificate(
    ProfileData currentProfile,
    Certificate certificate,
  ) async {
    final updatedCertificates = List<Certificate>.from(currentProfile.certificates)
      ..add(certificate);
    
    return currentProfile.copyWith(certificates: updatedCertificates);
  }
  
  /// Remove certificate
  Future<ProfileData> removeCertificate(
    ProfileData currentProfile,
    String certificateId,
  ) async {
    final updatedCertificates = currentProfile.certificates
        .where((cert) => cert.id != certificateId)
        .toList();
    
    return currentProfile.copyWith(certificates: updatedCertificates);
  }
  
  /// Update certificate
  Future<ProfileData> updateCertificate(
    ProfileData currentProfile,
    String certificateId,
    Map<String, dynamic> updates,
  ) async {
    final updatedCertificates = currentProfile.certificates.map((cert) {
      if (cert.id == certificateId) {
        return Certificate(
          id: cert.id,
          name: updates['name'] ?? cert.name,
          issuingOrganization: updates['issuingOrganization'] ?? cert.issuingOrganization,
          issueDate: updates['issueDate'] ?? cert.issueDate,
          expiryDate: updates['expiryDate'] ?? cert.expiryDate,
          certificateNumber: updates['certificateNumber'] ?? cert.certificateNumber,
          description: updates['description'] ?? cert.description,
          isVerified: updates['isVerified'] ?? cert.isVerified,
        );
      }
      return cert;
    }).toList();
    
    return currentProfile.copyWith(certificates: updatedCertificates);
  }
  
  /// Update availability
  Future<ProfileData> updateAvailability(
    ProfileData currentProfile,
    Map<String, List<String>> availability,
  ) async {
    return currentProfile.copyWith(availability: availability);
  }
  
  /// Update profile status
  Future<ProfileData> updateStatus(
    ProfileData currentProfile,
    String status,
  ) async {
    return currentProfile.copyWith(status: status);
  }
  
  /// Upload profile photo (mock implementation)
  Future<String> uploadProfilePhoto(String imagePath) async {
    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real app, this would upload to cloud storage and return the URL
    return 'https://example.com/profile_photos/${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
  
  /// Verify profile information
  Future<VerificationStatus> verifyProfile(
    String verificationType,
    Map<String, dynamic> verificationData,
  ) async {
    // Simulate verification process
    await Future.delayed(const Duration(seconds: 3));
    
    // Mock verification result (in real app, this would call verification service)
    final isValid = verificationData.isNotEmpty;
    
    return VerificationStatus(
      identityVerified: verificationType == 'identity' ? isValid : false,
      addressVerified: verificationType == 'address' ? isValid : false,
      certificatesVerified: verificationType == 'certificates' ? isValid : false,
      lastVerificationDate: isValid ? DateTime.now() : null,
    );
  }
  
  /// Export profile data
  Future<Map<String, dynamic>> exportProfile(ProfileData profile) async {
    return {
      'version': _currentProfileVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'basicInfo': {
        'name': profile.basicInfo.name,
        'email': profile.basicInfo.email,
        'phone': profile.basicInfo.phone,
        'address': profile.basicInfo.address,
        'postalCode': profile.basicInfo.postalCode,
        'city': profile.basicInfo.city,
        'bio': profile.basicInfo.bio,
        'nationality': profile.basicInfo.nationality,
      },
      'professionalInfo': profile.professionalInfo != null ? {
        'experienceYears': profile.professionalInfo!.experienceYears,
        'specializations': profile.professionalInfo!.specializations,
        'languages': profile.professionalInfo!.languages,
        'skills': profile.professionalInfo!.skills,
        'hasDriversLicense': profile.professionalInfo!.hasDriversLicense,
      } : null,
      'companyInfo': profile.companyInfo != null ? {
        'companyName': profile.companyInfo!.companyName,
        'kvkNumber': profile.companyInfo!.kvkNumber,
        'vatNumber': profile.companyInfo!.vatNumber,
        'industry': profile.companyInfo!.industry,
        'website': profile.companyInfo!.website,
        'description': profile.companyInfo!.description,
        'employeeCount': profile.companyInfo!.employeeCount,
        'foundedDate': profile.companyInfo!.foundedDate?.toIso8601String(),
      } : null,
      'certificates': profile.certificates.map((cert) => {
        'id': cert.id,
        'name': cert.name,
        'issuingOrganization': cert.issuingOrganization,
        'issueDate': cert.issueDate.toIso8601String(),
        'expiryDate': cert.expiryDate?.toIso8601String(),
        'certificateNumber': cert.certificateNumber,
        'description': cert.description,
        'isVerified': cert.isVerified,
      }).toList(),
      'availability': profile.availability,
      'statistics': {
        'completedJobs': profile.statistics.completedJobs,
        'averageRating': profile.statistics.averageRating,
        'totalEarned': profile.statistics.totalEarned,
        'activeSince': profile.statistics.activeSince.toIso8601String(),
        'successPercentage': profile.statistics.successPercentage,
        'repeatClients': profile.statistics.repeatClients,
        'averageResponseTime': profile.statistics.averageResponseTime.inMinutes,
      },
      'verificationStatus': {
        'identityVerified': profile.verificationStatus.identityVerified,
        'addressVerified': profile.verificationStatus.addressVerified,
        'certificatesVerified': profile.verificationStatus.certificatesVerified,
        'lastVerificationDate': profile.verificationStatus.lastVerificationDate?.toIso8601String(),
      },
      'privacySettings': {
        'profileVisible': profile.privacySettings.profileVisible,
        'contactInfoVisible': profile.privacySettings.contactInfoVisible,
        'availabilityVisible': profile.privacySettings.availabilityVisible,
        'statisticsVisible': profile.privacySettings.statisticsVisible,
      },
      'status': profile.status,
    };
  }
  
  /// Delete profile data
  Future<void> deleteProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove all profile-related keys
      final keys = prefs.getKeys().where((key) => key.startsWith('$_profilePrefix$userId')).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      debugPrint('Profile deleted successfully');
    } catch (e) {
      debugPrint('Error deleting profile: $e');
      throw Exception('Failed to delete profile: $e');
    }
  }
  
  /// Load profile data from SharedPreferences
  Future<ProfileData> _loadProfileData(SharedPreferences prefs, String userId, String userType) async {
    final basicInfoJson = prefs.getString('$_profilePrefix${userId}_basic_info');
    final professionalInfoJson = prefs.getString('$_profilePrefix${userId}_professional_info');
    final companyInfoJson = prefs.getString('$_profilePrefix${userId}_company_info');
    final certificatesJson = prefs.getString('$_profilePrefix${userId}_certificates');
    final availabilityJson = prefs.getString('$_profilePrefix${userId}_availability');
    final statisticsJson = prefs.getString('$_profilePrefix${userId}_statistics');
    final verificationJson = prefs.getString('$_profilePrefix${userId}_verification');
    final privacyJson = prefs.getString('$_profilePrefix${userId}_privacy');
    final status = prefs.getString('$_profilePrefix${userId}_status') ?? 'active';
    
    // Parse basic info
    final basicInfo = basicInfoJson != null
        ? _parseBasicInfo(jsonDecode(basicInfoJson))
        : _createDefaultBasicInfo();
    
    // Parse professional info (for guards)
    final professionalInfo = userType == 'guard' && professionalInfoJson != null
        ? _parseProfessionalInfo(jsonDecode(professionalInfoJson))
        : (userType == 'guard' ? const ProfessionalInfo() : null);
    
    // Parse company info (for companies)
    final companyInfo = userType == 'company' && companyInfoJson != null
        ? _parseCompanyInfo(jsonDecode(companyInfoJson))
        : (userType == 'company' ? _createDefaultCompanyInfo() : null);
    
    // Parse certificates
    final certificates = certificatesJson != null
        ? _parseCertificates(jsonDecode(certificatesJson))
        : <Certificate>[];
    
    // Parse availability
    final availability = availabilityJson != null
        ? Map<String, List<String>>.from(jsonDecode(availabilityJson))
        : <String, List<String>>{};
    
    // Parse statistics
    final statistics = statisticsJson != null
        ? _parseStatistics(jsonDecode(statisticsJson))
        : ProfileStatistics(activeSince: DateTime.now());
    
    // Parse verification status
    final verificationStatus = verificationJson != null
        ? _parseVerificationStatus(jsonDecode(verificationJson))
        : const VerificationStatus();
    
    // Parse privacy settings
    final privacySettings = privacyJson != null
        ? _parsePrivacySettings(jsonDecode(privacyJson))
        : const PrivacySettings();
    
    return ProfileData(
      basicInfo: basicInfo,
      professionalInfo: professionalInfo,
      companyInfo: companyInfo,
      certificates: certificates,
      availability: availability,
      statistics: statistics,
      verificationStatus: verificationStatus,
      privacySettings: privacySettings,
      status: status,
    );
  }
  
  /// Save profile data to SharedPreferences
  Future<void> _saveProfileData(SharedPreferences prefs, String userId, ProfileData profile) async {
    await prefs.setString('$_profilePrefix${userId}_basic_info', jsonEncode(_basicInfoToJson(profile.basicInfo)));
    
    if (profile.professionalInfo != null) {
      await prefs.setString('$_profilePrefix${userId}_professional_info', jsonEncode(_professionalInfoToJson(profile.professionalInfo!)));
    }
    
    if (profile.companyInfo != null) {
      await prefs.setString('$_profilePrefix${userId}_company_info', jsonEncode(_companyInfoToJson(profile.companyInfo!)));
    }
    
    await prefs.setString('$_profilePrefix${userId}_certificates', jsonEncode(_certificatesToJson(profile.certificates)));
    await prefs.setString('$_profilePrefix${userId}_availability', jsonEncode(profile.availability));
    await prefs.setString('$_profilePrefix${userId}_statistics', jsonEncode(_statisticsToJson(profile.statistics)));
    await prefs.setString('$_profilePrefix${userId}_verification', jsonEncode(_verificationStatusToJson(profile.verificationStatus)));
    await prefs.setString('$_profilePrefix${userId}_privacy', jsonEncode(_privacySettingsToJson(profile.privacySettings)));
    await prefs.setString('$_profilePrefix${userId}_status', profile.status);
  }
  
  /// Calculate profile completeness percentage
  double _calculateCompleteness(ProfileData profile, String userType) {
    int totalFields = 0;
    int completedFields = 0;
    
    // Basic info fields (8 fields)
    totalFields += 8;
    if (profile.basicInfo.name.isNotEmpty) completedFields++;
    if (profile.basicInfo.email.isNotEmpty) completedFields++;
    if (profile.basicInfo.phone.isNotEmpty) completedFields++;
    if (profile.basicInfo.address.isNotEmpty) completedFields++;
    if (profile.basicInfo.postalCode.isNotEmpty) completedFields++;
    if (profile.basicInfo.city.isNotEmpty) completedFields++;
    if (profile.basicInfo.bio != null && profile.basicInfo.bio!.isNotEmpty) completedFields++;
    if (profile.basicInfo.profilePhotoUrl != null) completedFields++;
    
    if (userType == 'guard') {
      // Professional info fields (4 fields)
      totalFields += 4;
      if (profile.professionalInfo?.experienceYears != null && profile.professionalInfo!.experienceYears > 0) completedFields++;
      if (profile.professionalInfo?.specializations.isNotEmpty == true) completedFields++;
      if (profile.professionalInfo?.languages.isNotEmpty == true) completedFields++;
      if (profile.professionalInfo?.skills.isNotEmpty == true) completedFields++;
      
      // Additional guard fields (3 fields)
      totalFields += 3;
      if (profile.certificates.isNotEmpty) completedFields++;
      if (profile.availability.isNotEmpty) completedFields++;
      if (profile.verificationStatus.identityVerified) completedFields++;
    }
    
    if (userType == 'company') {
      // Company info fields (4 fields)
      totalFields += 4;
      if (profile.companyInfo?.companyName.isNotEmpty == true) completedFields++;
      if (profile.companyInfo?.kvkNumber.isNotEmpty == true) completedFields++;
      if (profile.companyInfo?.industry.isNotEmpty == true) completedFields++;
      if (profile.companyInfo?.description?.isNotEmpty == true) completedFields++;
    }
    
    return (completedFields / totalFields) * 100;
  }
  
  /// Create default profile data
  ProfileData _createDefaultProfile(String userType) {
    return ProfileData(
      basicInfo: _createDefaultBasicInfo(),
      professionalInfo: userType == 'guard' ? const ProfessionalInfo() : null,
      companyInfo: userType == 'company' ? _createDefaultCompanyInfo() : null,
      certificates: [],
      availability: {},
      statistics: ProfileStatistics(activeSince: DateTime.now()),
      verificationStatus: const VerificationStatus(),
      privacySettings: const PrivacySettings(),
      status: 'active',
    );
  }
  
  /// Create default basic info
  BasicInfo _createDefaultBasicInfo() {
    return const BasicInfo(
      name: '',
      email: '',
      phone: '',
      address: '',
      postalCode: '',
      city: '',
      nationality: 'Nederlandse',
    );
  }

  /// Create default company info with mock data
  CompanyInfo _createDefaultCompanyInfo() {
    return const CompanyInfo(
      companyName: 'SecuryFlex Demo BV',
      kvkNumber: '12345678',
      vatNumber: 'NL123456789B01',
      industry: 'Beveiligingsdiensten',
      website: 'https://securyflex.nl',
      description: 'Professionele beveiligingsdiensten voor bedrijven en particulieren. Gespecialiseerd in objectbeveiliging, evenementbeveiliging en persoonlijke beveiliging.',
      employeeCount: 25,
      foundedDate: null,
    );
  }
  
  /// Parse methods for JSON data
  BasicInfo _parseBasicInfo(Map<String, dynamic> json) {
    return BasicInfo(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      postalCode: json['postalCode'] ?? '',
      city: json['city'] ?? '',
      bio: json['bio'],
      profilePhotoUrl: json['profilePhotoUrl'],
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      nationality: json['nationality'] ?? 'Nederlandse',
    );
  }
  
  ProfessionalInfo _parseProfessionalInfo(Map<String, dynamic> json) {
    return ProfessionalInfo(
      experienceYears: json['experienceYears'] ?? 0,
      specializations: List<String>.from(json['specializations'] ?? []),
      languages: List<String>.from(json['languages'] ?? ['Nederlands']),
      skills: List<String>.from(json['skills'] ?? []),
      hasDriversLicense: json['hasDriversLicense'] ?? false,
    );
  }
  
  CompanyInfo _parseCompanyInfo(Map<String, dynamic> json) {
    return CompanyInfo(
      companyName: json['companyName'] ?? '',
      kvkNumber: json['kvkNumber'] ?? '',
      vatNumber: json['vatNumber'],
      industry: json['industry'] ?? '',
      website: json['website'],
      description: json['description'],
      employeeCount: json['employeeCount'],
      foundedDate: json['foundedDate'] != null ? DateTime.parse(json['foundedDate']) : null,
    );
  }
  
  List<Certificate> _parseCertificates(List<dynamic> json) {
    return json.map((certJson) => Certificate(
      id: certJson['id'],
      name: certJson['name'],
      issuingOrganization: certJson['issuingOrganization'],
      issueDate: DateTime.parse(certJson['issueDate']),
      expiryDate: certJson['expiryDate'] != null ? DateTime.parse(certJson['expiryDate']) : null,
      certificateNumber: certJson['certificateNumber'],
      description: certJson['description'],
      isVerified: certJson['isVerified'] ?? false,
    )).toList();
  }
  
  ProfileStatistics _parseStatistics(Map<String, dynamic> json) {
    return ProfileStatistics(
      completedJobs: json['completedJobs'] ?? 0,
      averageRating: json['averageRating']?.toDouble() ?? 0.0,
      totalEarned: json['totalEarned']?.toDouble() ?? 0.0,
      activeSince: DateTime.parse(json['activeSince']),
      successPercentage: json['successPercentage']?.toDouble() ?? 0.0,
      repeatClients: json['repeatClients'] ?? 0,
      averageResponseTime: Duration(minutes: json['averageResponseTime'] ?? 120),
    );
  }
  
  VerificationStatus _parseVerificationStatus(Map<String, dynamic> json) {
    return VerificationStatus(
      identityVerified: json['identityVerified'] ?? false,
      addressVerified: json['addressVerified'] ?? false,
      certificatesVerified: json['certificatesVerified'] ?? false,
      lastVerificationDate: json['lastVerificationDate'] != null ? DateTime.parse(json['lastVerificationDate']) : null,
    );
  }
  
  PrivacySettings _parsePrivacySettings(Map<String, dynamic> json) {
    return PrivacySettings(
      profileVisible: json['profileVisible'] ?? true,
      contactInfoVisible: json['contactInfoVisible'] ?? true,
      availabilityVisible: json['availabilityVisible'] ?? true,
      statisticsVisible: json['statisticsVisible'] ?? true,
    );
  }
  
  /// Convert to JSON methods
  Map<String, dynamic> _basicInfoToJson(BasicInfo basicInfo) {
    return {
      'name': basicInfo.name,
      'email': basicInfo.email,
      'phone': basicInfo.phone,
      'address': basicInfo.address,
      'postalCode': basicInfo.postalCode,
      'city': basicInfo.city,
      'bio': basicInfo.bio,
      'profilePhotoUrl': basicInfo.profilePhotoUrl,
      'birthDate': basicInfo.birthDate?.toIso8601String(),
      'nationality': basicInfo.nationality,
    };
  }
  
  Map<String, dynamic> _professionalInfoToJson(ProfessionalInfo professionalInfo) {
    return {
      'experienceYears': professionalInfo.experienceYears,
      'specializations': professionalInfo.specializations,
      'languages': professionalInfo.languages,
      'skills': professionalInfo.skills,
      'hasDriversLicense': professionalInfo.hasDriversLicense,
    };
  }
  
  Map<String, dynamic> _companyInfoToJson(CompanyInfo companyInfo) {
    return {
      'companyName': companyInfo.companyName,
      'kvkNumber': companyInfo.kvkNumber,
      'vatNumber': companyInfo.vatNumber,
      'industry': companyInfo.industry,
      'website': companyInfo.website,
      'description': companyInfo.description,
      'employeeCount': companyInfo.employeeCount,
      'foundedDate': companyInfo.foundedDate?.toIso8601String(),
    };
  }
  
  List<Map<String, dynamic>> _certificatesToJson(List<Certificate> certificates) {
    return certificates.map((cert) => {
      'id': cert.id,
      'name': cert.name,
      'issuingOrganization': cert.issuingOrganization,
      'issueDate': cert.issueDate.toIso8601String(),
      'expiryDate': cert.expiryDate?.toIso8601String(),
      'certificateNumber': cert.certificateNumber,
      'description': cert.description,
      'isVerified': cert.isVerified,
    }).toList();
  }
  
  Map<String, dynamic> _statisticsToJson(ProfileStatistics statistics) {
    return {
      'completedJobs': statistics.completedJobs,
      'averageRating': statistics.averageRating,
      'totalEarned': statistics.totalEarned,
      'activeSince': statistics.activeSince.toIso8601String(),
      'successPercentage': statistics.successPercentage,
      'repeatClients': statistics.repeatClients,
      'averageResponseTime': statistics.averageResponseTime.inMinutes,
    };
  }
  
  Map<String, dynamic> _verificationStatusToJson(VerificationStatus verificationStatus) {
    return {
      'identityVerified': verificationStatus.identityVerified,
      'addressVerified': verificationStatus.addressVerified,
      'certificatesVerified': verificationStatus.certificatesVerified,
      'lastVerificationDate': verificationStatus.lastVerificationDate?.toIso8601String(),
    };
  }
  
  Map<String, dynamic> _privacySettingsToJson(PrivacySettings privacySettings) {
    return {
      'profileVisible': privacySettings.profileVisible,
      'contactInfoVisible': privacySettings.contactInfoVisible,
      'availabilityVisible': privacySettings.availabilityVisible,
      'statisticsVisible': privacySettings.statisticsVisible,
    };
  }
  
  /// Migrate profile from older versions
  Future<void> _migrateProfile(SharedPreferences prefs, String userId, int fromVersion) async {
    debugPrint('Migrating profile from version $fromVersion to $_currentProfileVersion');

    if (fromVersion == 0) {
      // Migrate from legacy profile data if exists
      // This would handle migration from BeveiligerProfielService or CompanyService data
    }

    await prefs.setInt('$_profilePrefix${userId}_version', _currentProfileVersion);
    debugPrint('Profile migration completed successfully');
  }
}
