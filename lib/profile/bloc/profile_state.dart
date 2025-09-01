import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/bloc/base_bloc.dart';
import '../../core/bloc/error_handler.dart';
import '../../unified_design_tokens.dart';

/// Base class for all profile states in SecuryFlex
abstract class ProfileState extends BaseState {
  const ProfileState();
}

/// Initial profile state
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Profile loading state
class ProfileLoading extends ProfileState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage;
  
  const ProfileLoading({this.loadingMessage});
  
  @override
  List<Object?> get props => [loadingMessage];
  
  @override
  String toString() => 'ProfileLoading(message: $loadingMessage)';
}

/// Profile loaded successfully
class ProfileLoaded extends ProfileState {
  final String userId;
  final String userType;
  final ProfileData profileData;
  final double completenessPercentage;
  final bool hasUnsavedChanges;
  final DateTime lastUpdated;
  
  const ProfileLoaded({
    required this.userId,
    required this.userType,
    required this.profileData,
    required this.completenessPercentage,
    this.hasUnsavedChanges = false,
    required this.lastUpdated,
  });
  
  /// Get Dutch role display name
  String get userRoleDisplayName {
    switch (userType.toLowerCase()) {
      case 'guard':
        return 'Beveiliger';
      case 'company':
        return 'Bedrijf';
      case 'admin':
        return 'Beheerder';
      default:
        return 'Gebruiker';
    }
  }
  
  /// Get profile completeness status in Dutch
  String get completenessStatus {
    if (completenessPercentage >= 90) {
      return 'Profiel compleet';
    } else if (completenessPercentage >= 70) {
      return 'Bijna compleet';
    } else if (completenessPercentage >= 50) {
      return 'Gedeeltelijk ingevuld';
    } else {
      return 'Profiel incompleet';
    }
  }
  
  /// Get profile status color
  Color get completenessColor {
    if (completenessPercentage >= 90) {
      return DesignTokens.statusConfirmed;
    } else if (completenessPercentage >= 70) {
      return DesignTokens.statusPending;
    } else {
      return DesignTokens.statusCancelled;
    }
  }
  
  /// Get missing profile fields in Dutch
  List<String> get missingFields {
    final missing = <String>[];
    
    if (profileData.basicInfo.name.isEmpty) missing.add('Naam');
    if (profileData.basicInfo.email.isEmpty) missing.add('E-mailadres');
    if (profileData.basicInfo.phone.isEmpty) missing.add('Telefoonnummer');
    if (profileData.basicInfo.address.isEmpty) missing.add('Adres');
    if (profileData.basicInfo.bio == null || profileData.basicInfo.bio!.isEmpty) missing.add('Biografie');
    if (profileData.basicInfo.profilePhotoUrl == null) missing.add('Profielfoto');
    
    if (userType == 'guard') {
      if (profileData.professionalInfo?.specializations.isEmpty == true) missing.add('Specialisaties');
      if (profileData.certificates.isEmpty) missing.add('Certificaten');
      if (profileData.availability.isEmpty) missing.add('Beschikbaarheid');
    }
    
    if (userType == 'company') {
      if (profileData.companyInfo?.kvkNumber.isEmpty == true) missing.add('KvK-nummer');
      if (profileData.companyInfo?.industry.isEmpty == true) missing.add('Branche');
    }
    
    return missing;
  }
  
  /// Check if profile is verified
  bool get isVerified {
    return profileData.verificationStatus.identityVerified &&
           profileData.verificationStatus.addressVerified;
  }
  
  /// Get verification status in Dutch
  String get verificationStatus {
    if (isVerified) {
      return 'Geverifieerd';
    } else if (profileData.verificationStatus.identityVerified) {
      return 'Gedeeltelijk geverifieerd';
    } else {
      return 'Niet geverifieerd';
    }
  }
  
  /// Create a copy with updated properties
  ProfileLoaded copyWith({
    String? userId,
    String? userType,
    ProfileData? profileData,
    double? completenessPercentage,
    bool? hasUnsavedChanges,
    DateTime? lastUpdated,
  }) {
    return ProfileLoaded(
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      profileData: profileData ?? this.profileData,
      completenessPercentage: completenessPercentage ?? this.completenessPercentage,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  @override
  List<Object> get props => [
    userId,
    userType,
    profileData,
    completenessPercentage,
    hasUnsavedChanges,
    lastUpdated,
  ];
  
  @override
  String toString() => 'ProfileLoaded(userType: $userType, completeness: ${completenessPercentage.toStringAsFixed(1)}%, hasUnsavedChanges: $hasUnsavedChanges)';
}

/// Profile update successful
class ProfileUpdateSuccess extends ProfileState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final ProfileLoaded updatedProfile;
  final String updateType;
  
  const ProfileUpdateSuccess({
    required this.updatedProfile,
    required this.updateType,
    this.successMessage = 'Profiel succesvol bijgewerkt',
  });
  
  @override
  String get localizedSuccessMessage {
    switch (updateType) {
      case 'basic_info':
        return 'Basisgegevens succesvol bijgewerkt';
      case 'professional_info':
        return 'Professionele gegevens succesvol bijgewerkt';
      case 'company_info':
        return 'Bedrijfsgegevens succesvol bijgewerkt';
      case 'certificate':
        return 'Certificaat succesvol toegevoegd';
      case 'photo':
        return 'Profielfoto succesvol bijgewerkt';
      case 'availability':
        return 'Beschikbaarheid succesvol bijgewerkt';
      case 'status':
        return 'Status succesvol bijgewerkt';
      default:
        return successMessage;
    }
  }
  
  @override
  List<Object> get props => [updatedProfile, updateType, successMessage];
  
  @override
  String toString() => 'ProfileUpdateSuccess(updateType: $updateType, message: $successMessage)';
}

/// Profile error state
class ProfileError extends ProfileState with ErrorStateMixin {
  @override
  final AppError error;
  
  const ProfileError(this.error);
  
  @override
  List<Object> get props => [error];
  
  @override
  String toString() => 'ProfileError(error: ${error.localizedMessage})';
}

/// Profile verification in progress
class ProfileVerificationInProgress extends ProfileState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage;
  
  final String verificationType;
  
  const ProfileVerificationInProgress({
    required this.verificationType,
    this.loadingMessage,
  });
  
  @override
  List<Object?> get props => [verificationType, loadingMessage];
  
  @override
  String toString() => 'ProfileVerificationInProgress(verificationType: $verificationType)';
}

/// Profile verification completed
class ProfileVerificationCompleted extends ProfileState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final String verificationType;
  final bool verificationResult;
  final ProfileLoaded updatedProfile;
  
  const ProfileVerificationCompleted({
    required this.verificationType,
    required this.verificationResult,
    required this.updatedProfile,
    this.successMessage = 'Verificatie voltooid',
  });
  
  @override
  String get localizedSuccessMessage {
    if (verificationResult) {
      switch (verificationType) {
        case 'identity':
          return 'Identiteit succesvol geverifieerd';
        case 'address':
          return 'Adres succesvol geverifieerd';
        case 'certificates':
          return 'Certificaten succesvol geverifieerd';
        default:
          return 'Verificatie succesvol voltooid';
      }
    } else {
      return 'Verificatie mislukt - controleer uw gegevens';
    }
  }
  
  @override
  List<Object> get props => [verificationType, verificationResult, updatedProfile, successMessage];
  
  @override
  String toString() => 'ProfileVerificationCompleted(verificationType: $verificationType, result: $verificationResult)';
}

/// Profile data exported
class ProfileDataExported extends ProfileState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final String exportPath;
  final Map<String, dynamic> exportedData;
  
  const ProfileDataExported({
    required this.exportPath,
    required this.exportedData,
    this.successMessage = 'Profielgegevens geëxporteerd',
  });
  
  @override
  String get localizedSuccessMessage => 'Profielgegevens geëxporteerd naar $exportPath';
  
  @override
  List<Object> get props => [exportPath, exportedData, successMessage];
  
  @override
  String toString() => 'ProfileDataExported(exportPath: $exportPath)';
}

/// Profile data classes
class ProfileData extends Equatable {
  final BasicInfo basicInfo;
  final ProfessionalInfo? professionalInfo;
  final CompanyInfo? companyInfo;
  final List<Certificate> certificates;
  final Map<String, List<String>> availability;
  final ProfileStatistics statistics;
  final VerificationStatus verificationStatus;
  final PrivacySettings privacySettings;
  final String status;
  
  const ProfileData({
    required this.basicInfo,
    this.professionalInfo,
    this.companyInfo,
    this.certificates = const [],
    this.availability = const {},
    required this.statistics,
    required this.verificationStatus,
    required this.privacySettings,
    this.status = 'active',
  });
  
  ProfileData copyWith({
    BasicInfo? basicInfo,
    ProfessionalInfo? professionalInfo,
    CompanyInfo? companyInfo,
    List<Certificate>? certificates,
    Map<String, List<String>>? availability,
    ProfileStatistics? statistics,
    VerificationStatus? verificationStatus,
    PrivacySettings? privacySettings,
    String? status,
  }) {
    return ProfileData(
      basicInfo: basicInfo ?? this.basicInfo,
      professionalInfo: professionalInfo ?? this.professionalInfo,
      companyInfo: companyInfo ?? this.companyInfo,
      certificates: certificates ?? this.certificates,
      availability: availability ?? this.availability,
      statistics: statistics ?? this.statistics,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      privacySettings: privacySettings ?? this.privacySettings,
      status: status ?? this.status,
    );
  }
  
  @override
  List<Object?> get props => [
    basicInfo,
    professionalInfo,
    companyInfo,
    certificates,
    availability,
    statistics,
    verificationStatus,
    privacySettings,
    status,
  ];
}

class BasicInfo extends Equatable {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String postalCode;
  final String city;
  final String? bio;
  final String? profilePhotoUrl;
  final DateTime? birthDate;
  final String nationality;
  
  const BasicInfo({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.postalCode,
    required this.city,
    this.bio,
    this.profilePhotoUrl,
    this.birthDate,
    this.nationality = 'Nederlandse',
  });
  
  BasicInfo copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? postalCode,
    String? city,
    String? bio,
    String? profilePhotoUrl,
    DateTime? birthDate,
    String? nationality,
  }) {
    return BasicInfo(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      birthDate: birthDate ?? this.birthDate,
      nationality: nationality ?? this.nationality,
    );
  }
  
  @override
  List<Object?> get props => [name, email, phone, address, postalCode, city, bio, profilePhotoUrl, birthDate, nationality];
}

class ProfessionalInfo extends Equatable {
  final int experienceYears;
  final List<String> specializations;
  final List<String> languages;
  final List<String> skills;
  final bool hasDriversLicense;
  
  const ProfessionalInfo({
    this.experienceYears = 0,
    this.specializations = const [],
    this.languages = const ['Nederlands'],
    this.skills = const [],
    this.hasDriversLicense = false,
  });
  
  ProfessionalInfo copyWith({
    int? experienceYears,
    List<String>? specializations,
    List<String>? languages,
    List<String>? skills,
    bool? hasDriversLicense,
  }) {
    return ProfessionalInfo(
      experienceYears: experienceYears ?? this.experienceYears,
      specializations: specializations ?? this.specializations,
      languages: languages ?? this.languages,
      skills: skills ?? this.skills,
      hasDriversLicense: hasDriversLicense ?? this.hasDriversLicense,
    );
  }
  
  @override
  List<Object> get props => [experienceYears, specializations, languages, skills, hasDriversLicense];
}

class CompanyInfo extends Equatable {
  final String companyName;
  final String kvkNumber;
  final String? vatNumber;
  final String industry;
  final String? website;
  final String? description;
  final int? employeeCount;
  final DateTime? foundedDate;
  
  const CompanyInfo({
    required this.companyName,
    required this.kvkNumber,
    this.vatNumber,
    required this.industry,
    this.website,
    this.description,
    this.employeeCount,
    this.foundedDate,
  });
  
  CompanyInfo copyWith({
    String? companyName,
    String? kvkNumber,
    String? vatNumber,
    String? industry,
    String? website,
    String? description,
    int? employeeCount,
    DateTime? foundedDate,
  }) {
    return CompanyInfo(
      companyName: companyName ?? this.companyName,
      kvkNumber: kvkNumber ?? this.kvkNumber,
      vatNumber: vatNumber ?? this.vatNumber,
      industry: industry ?? this.industry,
      website: website ?? this.website,
      description: description ?? this.description,
      employeeCount: employeeCount ?? this.employeeCount,
      foundedDate: foundedDate ?? this.foundedDate,
    );
  }
  
  @override
  List<Object?> get props => [companyName, kvkNumber, vatNumber, industry, website, description, employeeCount, foundedDate];
}

class Certificate extends Equatable {
  final String id;
  final String name;
  final String issuingOrganization;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final String? certificateNumber;
  final String? description;
  final bool isVerified;
  
  const Certificate({
    required this.id,
    required this.name,
    required this.issuingOrganization,
    required this.issueDate,
    this.expiryDate,
    this.certificateNumber,
    this.description,
    this.isVerified = false,
  });
  
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }
  
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }
  
  @override
  List<Object?> get props => [id, name, issuingOrganization, issueDate, expiryDate, certificateNumber, description, isVerified];
}

class ProfileStatistics extends Equatable {
  final int completedJobs;
  final double averageRating;
  final double totalEarned;
  final DateTime activeSince;
  final double successPercentage;
  final int repeatClients;
  final Duration averageResponseTime;
  
  const ProfileStatistics({
    this.completedJobs = 0,
    this.averageRating = 0.0,
    this.totalEarned = 0.0,
    required this.activeSince,
    this.successPercentage = 0.0,
    this.repeatClients = 0,
    this.averageResponseTime = const Duration(hours: 2),
  });
  
  @override
  List<Object> get props => [completedJobs, averageRating, totalEarned, activeSince, successPercentage, repeatClients, averageResponseTime];
}

class VerificationStatus extends Equatable {
  final bool identityVerified;
  final bool addressVerified;
  final bool certificatesVerified;
  final DateTime? lastVerificationDate;
  
  const VerificationStatus({
    this.identityVerified = false,
    this.addressVerified = false,
    this.certificatesVerified = false,
    this.lastVerificationDate,
  });
  
  @override
  List<Object?> get props => [identityVerified, addressVerified, certificatesVerified, lastVerificationDate];
}

class PrivacySettings extends Equatable {
  final bool profileVisible;
  final bool contactInfoVisible;
  final bool availabilityVisible;
  final bool statisticsVisible;
  
  const PrivacySettings({
    this.profileVisible = true,
    this.contactInfoVisible = true,
    this.availabilityVisible = true,
    this.statisticsVisible = true,
  });
  
  @override
  List<Object> get props => [profileVisible, contactInfoVisible, availabilityVisible, statisticsVisible];
}
