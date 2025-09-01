import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/base_bloc.dart';
import '../../core/bloc/error_handler.dart';
import '../repository/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// Profile BLoC for SecuryFlex
/// Manages user profile data with comprehensive CRUD operations and validation
class ProfileBloc extends BaseBloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;
  Timer? _autoSaveTimer;
  Timer? _updateBatchTimer;
  ProfileState? _pendingState;

  // Singleton instance for better performance
  static ProfileBloc? _instance;
  static ProfileBloc get instance {
    _instance ??= ProfileBloc._internal();
    return _instance!;
  }

  ProfileBloc._internal({
    ProfileRepository? repository,
  }) : _repository = repository ?? ProfileRepository(),
        super(const ProfileInitial()) {
    _setupEventHandlers();
  }

  ProfileBloc({
    ProfileRepository? repository,
  }) : _repository = repository ?? ProfileRepository(),
        super(const ProfileInitial()) {
    _setupEventHandlers();
  }

  void _setupEventHandlers() {
    // Register event handlers
    on<ProfileInitialize>(_onInitialize);
    on<LoadProfile>(_onLoadProfile);
    on<RefreshProfile>(_onRefreshProfile);
    on<UpdateBasicInfo>(_onUpdateBasicInfo);
    on<UpdateProfessionalInfo>(_onUpdateProfessionalInfo);
    on<UpdateCompanyInfo>(_onUpdateCompanyInfo);
    on<AddCertificate>(_onAddCertificate);
    on<RemoveCertificate>(_onRemoveCertificate);
    on<UpdateCertificate>(_onUpdateCertificate);
    on<UpdateAvailability>(_onUpdateAvailability);
    on<UpdateProfileStatus>(_onUpdateProfileStatus);
    on<UploadProfilePhoto>(_onUploadProfilePhoto);
    on<RemoveProfilePhoto>(_onRemoveProfilePhoto);
    on<UpdatePrivacySettings>(_onUpdatePrivacySettings);
    on<VerifyProfile>(_onVerifyProfile);
    on<CalculateProfileCompleteness>(_onCalculateProfileCompleteness);
    on<ExportProfileData>(_onExportProfileData);
    on<DeleteProfile>(_onDeleteProfile);
  }
  
  /// Initialize profile for current user
  Future<void> _onInitialize(ProfileInitialize event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading(loadingMessage: 'Profiel laden...'));

    try {
      final profile = await _repository.loadProfile(event.userId, event.userType);
      emit(profile);

      debugPrint('Profile initialized for user type: ${event.userType}');
    } catch (e) {
      emit(ProfileError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Load profile data
  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(const ProfileLoading(loadingMessage: 'Profiel laden...'));
      
      try {
        final profile = await _repository.loadProfile(currentState.userId, currentState.userType);
        emit(profile);
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Refresh profile data
  Future<void> _onRefreshProfile(RefreshProfile event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      
      try {
        final profile = await _repository.loadProfile(currentState.userId, currentState.userType);
        emit(profile);
        
        debugPrint('Profile refreshed successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Update basic information (optimized)
  Future<void> _onUpdateBasicInfo(UpdateBasicInfo event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      
      try {
        final updates = <String, dynamic>{};
        if (event.name != null) updates['name'] = event.name;
        if (event.email != null) updates['email'] = event.email;
        if (event.phone != null) updates['phone'] = event.phone;
        if (event.address != null) updates['address'] = event.address;
        if (event.postalCode != null) updates['postalCode'] = event.postalCode;
        if (event.city != null) updates['city'] = event.city;
        if (event.bio != null) updates['bio'] = event.bio;
        if (event.profilePhotoUrl != null) updates['profilePhotoUrl'] = event.profilePhotoUrl;
        
        // Only proceed if there are actual updates
        if (updates.isEmpty) return;
        
        final updatedProfileData = await _repository.updateBasicInfo(currentState.profileData, updates);
        
        // Only recalculate completeness if we changed significant fields
        final needsCompletenessUpdate = updates.containsKey('name') || 
                                       updates.containsKey('email') || 
                                       updates.containsKey('phone') ||
                                       updates.containsKey('profilePhotoUrl');
        
        final completeness = needsCompletenessUpdate 
            ? await _calculateCompleteness(updatedProfileData, currentState.userType)
            : currentState.completenessPercentage;
        
        final updatedProfile = currentState.copyWith(
          profileData: updatedProfileData,
          completenessPercentage: completeness,
          hasUnsavedChanges: true,
        );
        
        _emitOptimized(updatedProfile, emit);
        _scheduleAutoSave();
        
        debugPrint('Basic info updated successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Update professional information (for guards) - optimized
  Future<void> _onUpdateProfessionalInfo(UpdateProfessionalInfo event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      
      if (currentState.userType != 'guard') {
        emit(ProfileError(AppError(
          code: 'invalid_user_type',
          message: 'Professional info can only be updated for guards',
          category: ErrorCategory.validation,
        )));
        return;
      }
      
      try {
        final updates = <String, dynamic>{};
        if (event.experienceYears != null) updates['experienceYears'] = event.experienceYears;
        if (event.specializations != null) updates['specializations'] = event.specializations;
        if (event.languages != null) updates['languages'] = event.languages;
        if (event.skills != null) updates['skills'] = event.skills;
        if (event.hasDriversLicense != null) updates['hasDriversLicense'] = event.hasDriversLicense;
        
        // Only proceed if there are actual updates
        if (updates.isEmpty) return;
        
        final updatedProfileData = await _repository.updateProfessionalInfo(currentState.profileData, updates);
        
        // Always recalculate completeness for professional info as it affects guard profile significantly
        final completeness = await _calculateCompleteness(updatedProfileData, currentState.userType);
        
        final updatedProfile = currentState.copyWith(
          profileData: updatedProfileData,
          completenessPercentage: completeness,
          hasUnsavedChanges: true,
        );
        
        _emitOptimized(updatedProfile, emit);
        _scheduleAutoSave();
        
        debugPrint('Professional info updated successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Update company information (for companies) - optimized
  Future<void> _onUpdateCompanyInfo(UpdateCompanyInfo event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      
      if (currentState.userType != 'company') {
        emit(ProfileError(AppError(
          code: 'invalid_user_type',
          message: 'Company info can only be updated for companies',
          category: ErrorCategory.validation,
        )));
        return;
      }
      
      try {
        final updates = <String, dynamic>{};
        if (event.companyName != null) updates['companyName'] = event.companyName;
        if (event.kvkNumber != null) updates['kvkNumber'] = event.kvkNumber;
        if (event.vatNumber != null) updates['vatNumber'] = event.vatNumber;
        if (event.industry != null) updates['industry'] = event.industry;
        if (event.website != null) updates['website'] = event.website;
        if (event.description != null) updates['description'] = event.description;
        if (event.employeeCount != null) updates['employeeCount'] = event.employeeCount;
        if (event.foundedDate != null) updates['foundedDate'] = event.foundedDate;
        
        // Only proceed if there are actual updates
        if (updates.isEmpty) return;
        
        final updatedProfileData = await _repository.updateCompanyInfo(currentState.profileData, updates);
        
        // Only recalculate completeness for significant company fields
        final needsCompletenessUpdate = updates.containsKey('companyName') || 
                                       updates.containsKey('kvkNumber') || 
                                       updates.containsKey('industry') ||
                                       updates.containsKey('description');
        
        final completeness = needsCompletenessUpdate 
            ? await _calculateCompleteness(updatedProfileData, currentState.userType)
            : currentState.completenessPercentage;
        
        final updatedProfile = currentState.copyWith(
          profileData: updatedProfileData,
          completenessPercentage: completeness,
          hasUnsavedChanges: true,
        );
        
        _emitOptimized(updatedProfile, emit);
        _scheduleAutoSave();
        
        debugPrint('Company info updated successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Add certificate
  Future<void> _onAddCertificate(AddCertificate event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      
      try {
        final certificate = Certificate(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: event.name,
          issuingOrganization: event.issuingOrganization,
          issueDate: event.issueDate,
          expiryDate: event.expiryDate,
          certificateNumber: event.certificateNumber,
          description: event.description,
        );
        
        final updatedProfileData = await _repository.addCertificate(currentState.profileData, certificate);
        final completeness = await _calculateCompleteness(updatedProfileData, currentState.userType);
        
        final updatedProfile = currentState.copyWith(
          profileData: updatedProfileData,
          completenessPercentage: completeness,
          hasUnsavedChanges: true,
        );
        
        emit(ProfileUpdateSuccess(
          updatedProfile: updatedProfile,
          updateType: 'certificate',
          successMessage: 'Certificaat "${event.name}" succesvol toegevoegd',
        ));
        
        // Return to loaded state after showing success (optimized)
        Timer(const Duration(milliseconds: 50), () {
          if (!isClosed) {
            emit(updatedProfile);
          }
        });
        
        _scheduleAutoSave();
        
        debugPrint('Certificate added successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Remove certificate
  Future<void> _onRemoveCertificate(RemoveCertificate event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      
      try {
        final updatedProfileData = await _repository.removeCertificate(currentState.profileData, event.certificateId);
        final completeness = await _calculateCompleteness(updatedProfileData, currentState.userType);
        
        final updatedProfile = currentState.copyWith(
          profileData: updatedProfileData,
          completenessPercentage: completeness,
          hasUnsavedChanges: true,
        );
        
        emit(updatedProfile);
        _scheduleAutoSave();
        
        debugPrint('Certificate removed successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Update certificate
  Future<void> _onUpdateCertificate(UpdateCertificate event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      
      try {
        final updates = <String, dynamic>{};
        if (event.name != null) updates['name'] = event.name;
        if (event.issuingOrganization != null) updates['issuingOrganization'] = event.issuingOrganization;
        if (event.issueDate != null) updates['issueDate'] = event.issueDate;
        if (event.expiryDate != null) updates['expiryDate'] = event.expiryDate;
        if (event.certificateNumber != null) updates['certificateNumber'] = event.certificateNumber;
        if (event.description != null) updates['description'] = event.description;
        
        // Only proceed if there are actual updates
        if (updates.isEmpty) return;
        
        final updatedProfileData = await _repository.updateCertificate(currentState.profileData, event.certificateId, updates);
        
        final updatedProfile = currentState.copyWith(
          profileData: updatedProfileData,
          hasUnsavedChanges: true,
        );
        
        _emitOptimized(updatedProfile, emit);
        _scheduleAutoSave();
        
        debugPrint('Certificate updated successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Update availability
  Future<void> _onUpdateAvailability(UpdateAvailability event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      
      try {
        final updatedProfileData = await _repository.updateAvailability(currentState.profileData, event.availability);
        final completeness = await _calculateCompleteness(updatedProfileData, currentState.userType);
        
        final updatedProfile = currentState.copyWith(
          profileData: updatedProfileData,
          completenessPercentage: completeness,
          hasUnsavedChanges: true,
        );
        
        emit(updatedProfile);
        _scheduleAutoSave();
        
        debugPrint('Availability updated successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Update profile status
  Future<void> _onUpdateProfileStatus(UpdateProfileStatus event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      
      try {
        final updatedProfileData = await _repository.updateStatus(currentState.profileData, event.status);
        
        final updatedProfile = currentState.copyWith(
          profileData: updatedProfileData,
          hasUnsavedChanges: true,
        );
        
        emit(ProfileUpdateSuccess(
          updatedProfile: updatedProfile,
          updateType: 'status',
          successMessage: 'Status bijgewerkt naar "${_getStatusDisplayName(event.status)}"',
        ));
        
        // Return to loaded state after showing success (optimized)
        Timer(const Duration(milliseconds: 50), () {
          if (!isClosed) {
            emit(updatedProfile);
          }
        });
        
        _scheduleAutoSave();
        
        debugPrint('Status updated successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }

  /// Upload profile photo
  Future<void> _onUploadProfilePhoto(UploadProfilePhoto event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(const ProfileLoading(loadingMessage: 'Foto uploaden...'));

      try {
        final photoUrl = await _repository.uploadProfilePhoto(event.imagePath);

        final updatedBasicInfo = currentState.profileData.basicInfo.copyWith(
          profilePhotoUrl: photoUrl,
        );

        final updatedProfileData = currentState.profileData.copyWith(
          basicInfo: updatedBasicInfo,
        );

        final completeness = await _calculateCompleteness(updatedProfileData, currentState.userType);

        final updatedProfile = currentState.copyWith(
          profileData: updatedProfileData,
          completenessPercentage: completeness,
          hasUnsavedChanges: true,
        );

        emit(ProfileUpdateSuccess(
          updatedProfile: updatedProfile,
          updateType: 'photo',
          successMessage: 'Profielfoto succesvol bijgewerkt',
        ));

        // Return to loaded state after showing success (optimized)
        Timer(const Duration(milliseconds: 50), () {
          if (!isClosed) {
            emit(updatedProfile);
          }
        });

        _scheduleAutoSave();

        debugPrint('Profile photo uploaded successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }

  /// Remove profile photo
  Future<void> _onRemoveProfilePhoto(RemoveProfilePhoto event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;

      try {
        final updatedBasicInfo = currentState.profileData.basicInfo.copyWith(
          profilePhotoUrl: null,
        );

        final updatedProfileData = currentState.profileData.copyWith(
          basicInfo: updatedBasicInfo,
        );

        final completeness = await _calculateCompleteness(updatedProfileData, currentState.userType);

        final updatedProfile = currentState.copyWith(
          profileData: updatedProfileData,
          completenessPercentage: completeness,
          hasUnsavedChanges: true,
        );

        emit(updatedProfile);
        _scheduleAutoSave();

        debugPrint('Profile photo removed successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }

  /// Update privacy settings
  Future<void> _onUpdatePrivacySettings(UpdatePrivacySettings event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;

      try {
        final updatedPrivacySettings = PrivacySettings(
          profileVisible: event.profileVisible ?? currentState.profileData.privacySettings.profileVisible,
          contactInfoVisible: event.contactInfoVisible ?? currentState.profileData.privacySettings.contactInfoVisible,
          availabilityVisible: event.availabilityVisible ?? currentState.profileData.privacySettings.availabilityVisible,
          statisticsVisible: event.statisticsVisible ?? currentState.profileData.privacySettings.statisticsVisible,
        );

        final updatedProfileData = currentState.profileData.copyWith(
          privacySettings: updatedPrivacySettings,
        );

        final updatedProfile = currentState.copyWith(
          profileData: updatedProfileData,
          hasUnsavedChanges: true,
        );

        emit(updatedProfile);
        _scheduleAutoSave();

        debugPrint('Privacy settings updated successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }

  /// Verify profile information
  Future<void> _onVerifyProfile(VerifyProfile event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(ProfileVerificationInProgress(
        verificationType: event.verificationType,
        loadingMessage: 'Verificatie uitvoeren...',
      ));

      try {
        final verificationResult = await _repository.verifyProfile(
          event.verificationType,
          event.verificationData,
        );

        final updatedVerificationStatus = VerificationStatus(
          identityVerified: event.verificationType == 'identity'
              ? verificationResult.identityVerified
              : currentState.profileData.verificationStatus.identityVerified,
          addressVerified: event.verificationType == 'address'
              ? verificationResult.addressVerified
              : currentState.profileData.verificationStatus.addressVerified,
          certificatesVerified: event.verificationType == 'certificates'
              ? verificationResult.certificatesVerified
              : currentState.profileData.verificationStatus.certificatesVerified,
          lastVerificationDate: verificationResult.lastVerificationDate,
        );

        final updatedProfileData = currentState.profileData.copyWith(
          verificationStatus: updatedVerificationStatus,
        );

        final completeness = await _calculateCompleteness(updatedProfileData, currentState.userType);

        final updatedProfile = currentState.copyWith(
          profileData: updatedProfileData,
          completenessPercentage: completeness,
          hasUnsavedChanges: true,
        );

        emit(ProfileVerificationCompleted(
          verificationType: event.verificationType,
          verificationResult: verificationResult.identityVerified ||
                             verificationResult.addressVerified ||
                             verificationResult.certificatesVerified,
          updatedProfile: updatedProfile,
        ));

        // Return to loaded state after showing success (optimized)
        Timer(const Duration(milliseconds: 50), () {
          if (!isClosed) {
            emit(updatedProfile);
          }
        });

        _scheduleAutoSave();

        debugPrint('Profile verification completed successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }

  /// Calculate profile completeness
  Future<void> _onCalculateProfileCompleteness(CalculateProfileCompleteness event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;

      try {
        final completeness = await _calculateCompleteness(currentState.profileData, currentState.userType);

        final updatedProfile = currentState.copyWith(
          completenessPercentage: completeness,
        );

        emit(updatedProfile);

        debugPrint('Profile completeness calculated: ${completeness.toStringAsFixed(1)}%');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }

  /// Export profile data
  Future<void> _onExportProfileData(ExportProfileData event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(const ProfileLoading(loadingMessage: 'Profielgegevens exporteren...'));

      try {
        final exportData = await _repository.exportProfile(currentState.profileData);

        // In a real app, this would save to a file or share
        final exportPath = '/storage/emulated/0/Download/securyflex_profile_${currentState.userId}.json';

        emit(ProfileDataExported(
          exportPath: exportPath,
          exportedData: exportData,
        ));

        debugPrint('Profile data exported successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }

  /// Delete profile
  Future<void> _onDeleteProfile(DeleteProfile event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;

      // Validate confirmation text
      if (event.confirmationText.toLowerCase() != 'verwijder profiel') {
        emit(ProfileError(AppError(
          code: 'invalid_confirmation',
          message: 'Bevestigingstekst is onjuist',
          category: ErrorCategory.validation,
        )));
        return;
      }

      emit(const ProfileLoading(loadingMessage: 'Profiel verwijderen...'));

      try {
        await _repository.deleteProfile(currentState.userId);
        emit(const ProfileInitial());

        debugPrint('Profile deleted successfully');
      } catch (e) {
        emit(ProfileError(ErrorHandler.fromException(e)));
      }
    }
  }

  /// Schedule auto-save after changes (optimized)
  void _scheduleAutoSave() {
    // Cancel existing timer
    _autoSaveTimer?.cancel();
    
    // Only schedule if we have unsaved changes
    if (state is ProfileLoaded && (state as ProfileLoaded).hasUnsavedChanges) {
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        if (!isClosed && state is ProfileLoaded) {
          final currentState = state as ProfileLoaded;
          if (currentState.hasUnsavedChanges) {
            _saveProfile();
          }
        }
      });
    }
  }

  /// Save profile to repository
  Future<void> _saveProfile() async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;

      try {
        await _repository.saveProfile(currentState);
        debugPrint('Profile auto-saved successfully');
      } catch (e) {
        debugPrint('Auto-save failed: $e');
        // Don't emit error for auto-save failures to avoid disrupting user experience
      }
    }
  }

  /// Calculate profile completeness percentage
  Future<double> _calculateCompleteness(ProfileData profile, String userType) async {
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

  /// Get Dutch display name for status
  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Actief';
      case 'inactive':
        return 'Inactief';
      case 'busy':
        return 'Bezet';
      case 'away':
        return 'Afwezig';
      default:
        return status;
    }
  }

  /// Optimized emit with batching to reduce unnecessary rebuilds
  void _emitOptimized(ProfileState newState, Emitter<ProfileState> emit) {
    // Cancel existing batch timer
    _updateBatchTimer?.cancel();
    
    // Store the pending state
    _pendingState = newState;
    
    // Batch updates to reduce UI rebuilds
    _updateBatchTimer = Timer(const Duration(milliseconds: 16), () { // 60fps
      if (!isClosed && _pendingState != null) {
        emit(_pendingState!);
        _pendingState = null;
      }
    });
  }

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    _updateBatchTimer?.cancel();
    return super.close();
  }

  /// Convenience getters for current profile state
  bool get isLoaded => state is ProfileLoaded;
  bool get isLoading => state is ProfileLoading;
  bool get hasError => state is ProfileError;
  bool get hasUnsavedChanges => isLoaded ? (state as ProfileLoaded).hasUnsavedChanges : false;

  ProfileLoaded? get currentProfile {
    return state is ProfileLoaded ? state as ProfileLoaded : null;
  }

  ProfileData? get profileData {
    return currentProfile?.profileData;
  }

  double get completenessPercentage {
    return currentProfile?.completenessPercentage ?? 0.0;
  }

  String get userType {
    return currentProfile?.userType ?? '';
  }

  String get userId {
    return currentProfile?.userId ?? '';
  }
}
