import '../../core/bloc/base_bloc.dart';

/// Base class for all profile events in SecuryFlex
abstract class ProfileEvent extends BaseEvent {
  const ProfileEvent();
}

/// Initialize profile for current user
class ProfileInitialize extends ProfileEvent {
  final String userId;
  final String userType;
  
  const ProfileInitialize({
    required this.userId,
    required this.userType,
  });
  
  @override
  List<Object> get props => [userId, userType];
  
  @override
  String toString() => 'ProfileInitialize(userId: $userId, userType: $userType)';
}

/// Load profile data
class LoadProfile extends ProfileEvent {
  const LoadProfile();
}

/// Refresh profile data
class RefreshProfile extends ProfileEvent {
  const RefreshProfile();
}

/// Update basic profile information
class UpdateBasicInfo extends ProfileEvent {
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? postalCode;
  final String? city;
  final String? bio;
  final String? profilePhotoUrl;
  
  const UpdateBasicInfo({
    this.name,
    this.email,
    this.phone,
    this.address,
    this.postalCode,
    this.city,
    this.bio,
    this.profilePhotoUrl,
  });
  
  @override
  List<Object?> get props => [name, email, phone, address, postalCode, city, bio, profilePhotoUrl];
  
  @override
  String toString() => 'UpdateBasicInfo(name: $name, email: $email, phone: $phone)';
}

/// Update professional information (for guards)
class UpdateProfessionalInfo extends ProfileEvent {
  final int? experienceYears;
  final List<String>? specializations;
  final List<String>? languages;
  final List<String>? skills;
  final bool? hasDriversLicense;
  
  const UpdateProfessionalInfo({
    this.experienceYears,
    this.specializations,
    this.languages,
    this.skills,
    this.hasDriversLicense,
  });
  
  @override
  List<Object?> get props => [experienceYears, specializations, languages, skills, hasDriversLicense];
  
  @override
  String toString() => 'UpdateProfessionalInfo(experienceYears: $experienceYears, specializations: $specializations)';
}

/// Update company information (for companies)
class UpdateCompanyInfo extends ProfileEvent {
  final String? companyName;
  final String? kvkNumber;
  final String? vatNumber;
  final String? industry;
  final String? website;
  final String? description;
  final int? employeeCount;
  final DateTime? foundedDate;
  
  const UpdateCompanyInfo({
    this.companyName,
    this.kvkNumber,
    this.vatNumber,
    this.industry,
    this.website,
    this.description,
    this.employeeCount,
    this.foundedDate,
  });
  
  @override
  List<Object?> get props => [companyName, kvkNumber, vatNumber, industry, website, description, employeeCount, foundedDate];
  
  @override
  String toString() => 'UpdateCompanyInfo(companyName: $companyName, kvkNumber: $kvkNumber)';
}

/// Add certificate
class AddCertificate extends ProfileEvent {
  final String name;
  final String issuingOrganization;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final String? certificateNumber;
  final String? description;
  
  const AddCertificate({
    required this.name,
    required this.issuingOrganization,
    required this.issueDate,
    this.expiryDate,
    this.certificateNumber,
    this.description,
  });
  
  @override
  List<Object?> get props => [name, issuingOrganization, issueDate, expiryDate, certificateNumber, description];
  
  @override
  String toString() => 'AddCertificate(name: $name, issuingOrganization: $issuingOrganization)';
}

/// Remove certificate
class RemoveCertificate extends ProfileEvent {
  final String certificateId;
  
  const RemoveCertificate(this.certificateId);
  
  @override
  List<Object> get props => [certificateId];
  
  @override
  String toString() => 'RemoveCertificate(certificateId: $certificateId)';
}

/// Update certificate
class UpdateCertificate extends ProfileEvent {
  final String certificateId;
  final String? name;
  final String? issuingOrganization;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? certificateNumber;
  final String? description;
  
  const UpdateCertificate({
    required this.certificateId,
    this.name,
    this.issuingOrganization,
    this.issueDate,
    this.expiryDate,
    this.certificateNumber,
    this.description,
  });
  
  @override
  List<Object?> get props => [certificateId, name, issuingOrganization, issueDate, expiryDate, certificateNumber, description];
  
  @override
  String toString() => 'UpdateCertificate(certificateId: $certificateId, name: $name)';
}

/// Update availability (for guards)
class UpdateAvailability extends ProfileEvent {
  final Map<String, List<String>> availability; // weekday -> time slots
  
  const UpdateAvailability(this.availability);
  
  @override
  List<Object> get props => [availability];
  
  @override
  String toString() => 'UpdateAvailability(availability: $availability)';
}

/// Update profile status
class UpdateProfileStatus extends ProfileEvent {
  final String status; // 'active', 'inactive', 'busy', 'away'
  
  const UpdateProfileStatus(this.status);
  
  @override
  List<Object> get props => [status];
  
  @override
  String toString() => 'UpdateProfileStatus(status: $status)';
}

/// Upload profile photo
class UploadProfilePhoto extends ProfileEvent {
  final String imagePath;
  
  const UploadProfilePhoto(this.imagePath);
  
  @override
  List<Object> get props => [imagePath];
  
  @override
  String toString() => 'UploadProfilePhoto(imagePath: $imagePath)';
}

/// Remove profile photo
class RemoveProfilePhoto extends ProfileEvent {
  const RemoveProfilePhoto();
}

/// Update privacy settings
class UpdatePrivacySettings extends ProfileEvent {
  final bool? profileVisible;
  final bool? contactInfoVisible;
  final bool? availabilityVisible;
  final bool? statisticsVisible;
  
  const UpdatePrivacySettings({
    this.profileVisible,
    this.contactInfoVisible,
    this.availabilityVisible,
    this.statisticsVisible,
  });
  
  @override
  List<Object?> get props => [profileVisible, contactInfoVisible, availabilityVisible, statisticsVisible];
  
  @override
  String toString() => 'UpdatePrivacySettings(profileVisible: $profileVisible, contactInfoVisible: $contactInfoVisible)';
}

/// Verify profile information
class VerifyProfile extends ProfileEvent {
  final String verificationType; // 'identity', 'address', 'certificates'
  final Map<String, dynamic> verificationData;
  
  const VerifyProfile({
    required this.verificationType,
    required this.verificationData,
  });
  
  @override
  List<Object> get props => [verificationType, verificationData];
  
  @override
  String toString() => 'VerifyProfile(verificationType: $verificationType)';
}

/// Calculate profile completeness
class CalculateProfileCompleteness extends ProfileEvent {
  const CalculateProfileCompleteness();
}

/// Export profile data
class ExportProfileData extends ProfileEvent {
  const ExportProfileData();
}

/// Delete profile
class DeleteProfile extends ProfileEvent {
  final String confirmationText;
  
  const DeleteProfile(this.confirmationText);
  
  @override
  List<Object> get props => [confirmationText];
  
  @override
  String toString() => 'DeleteProfile(confirmationText: $confirmationText)';
}
