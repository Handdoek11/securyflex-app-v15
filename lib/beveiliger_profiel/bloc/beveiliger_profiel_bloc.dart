import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:securyflex_app/core/bloc/base_bloc.dart';
import 'package:securyflex_app/core/bloc/error_handler.dart';
import 'package:securyflex_app/beveiliger_profiel/models/beveiliger_profiel_data.dart';
import 'package:securyflex_app/beveiliger_profiel/services/beveiliger_profiel_service.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/beveiliger_profiel/models/profile_completion_data.dart';
import 'package:securyflex_app/beveiliger_profiel/models/profile_stats_data.dart';
import 'package:securyflex_app/beveiliger_profiel/services/profile_completion_service.dart';

// Events
abstract class BeveiligerProfielEvent extends BaseEvent {
  const BeveiligerProfielEvent();
}

class LoadProfile extends BeveiligerProfielEvent {
  final String? userId;
  
  const LoadProfile({this.userId});
  
  @override
  List<Object?> get props => [userId];
}

class UpdateProfile extends BeveiligerProfielEvent {
  final BeveiligerProfielData profileData;
  
  const UpdateProfile(this.profileData);
  
  @override
  List<Object> get props => [profileData];
}

class UploadProfileImage extends BeveiligerProfielEvent {
  final File imageFile;
  
  const UploadProfileImage(this.imageFile);
  
  @override
  List<Object> get props => [imageFile];
}

class RefreshProfile extends BeveiligerProfielEvent {
  final String? userId;
  
  const RefreshProfile({this.userId});
  
  @override
  List<Object?> get props => [userId];
}

// Certificate-related events
class LoadCertificates extends BeveiligerProfielEvent {
  final String userId;
  
  const LoadCertificates(this.userId);
  
  @override
  List<Object> get props => [userId];
}

class AddCertificate extends BeveiligerProfielEvent {
  final Map<String, dynamic> certificateData;
  
  const AddCertificate(this.certificateData);
  
  @override
  List<Object> get props => [certificateData];
}

class VerifyCertificate extends BeveiligerProfielEvent {
  final String certificateNumber;
  final String certificateType;
  
  const VerifyCertificate({
    required this.certificateNumber,
    required this.certificateType,
  });
  
  @override
  List<Object> get props => [certificateNumber, certificateType];
}

// Profile completion events
class LoadProfileCompletion extends BeveiligerProfielEvent {
  final String userId;
  
  const LoadProfileCompletion(this.userId);
  
  @override
  List<Object> get props => [userId];
}

class LoadProfileStats extends BeveiligerProfielEvent {
  final String userId;
  
  const LoadProfileStats(this.userId);
  
  @override
  List<Object> get props => [userId];
}

class NavigateToProfileSection extends BeveiligerProfielEvent {
  final ProfileElementType elementType;
  
  const NavigateToProfileSection(this.elementType);
  
  @override
  List<Object> get props => [elementType];
}

class TrackCompletionMilestone extends BeveiligerProfielEvent {
  final String userId;
  final ProfileCompletionMilestone milestone;
  
  const TrackCompletionMilestone(this.userId, this.milestone);
  
  @override
  List<Object> get props => [userId, milestone];
}

// States
abstract class BeveiligerProfielState extends BaseState {
  const BeveiligerProfielState();
}

class ProfielInitial extends BeveiligerProfielState {
  const ProfielInitial();
}

class ProfielLoading extends BeveiligerProfielState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage;
  
  const ProfielLoading({this.loadingMessage});
  
  @override
  List<Object?> get props => [loadingMessage];
}

class ProfielLoaded extends BeveiligerProfielState {
  final BeveiligerProfielData profileData;
  final Map<String, dynamic> statistics;
  
  const ProfielLoaded({
    required this.profileData,
    required this.statistics,
  });
  
  @override
  List<Object> get props => [profileData, statistics];
}

class BeveiligerProfielLoaded extends BeveiligerProfielState {
  final BeveiligerProfielData profileData;
  final Map<String, dynamic> statistics;
  final ProfileCompletionData? profileCompletionData;
  final ProfileStatsData? profileStatsData;
  
  const BeveiligerProfielLoaded({
    required this.profileData,
    required this.statistics,
    this.profileCompletionData,
    this.profileStatsData,
  });
  
  BeveiligerProfielLoaded copyWith({
    BeveiligerProfielData? profileData,
    Map<String, dynamic>? statistics,
    ProfileCompletionData? profileCompletionData,
    ProfileStatsData? profileStatsData,
  }) {
    return BeveiligerProfielLoaded(
      profileData: profileData ?? this.profileData,
      statistics: statistics ?? this.statistics,
      profileCompletionData: profileCompletionData ?? this.profileCompletionData,
      profileStatsData: profileStatsData ?? this.profileStatsData,
    );
  }
  
  @override
  List<Object?> get props => [profileData, statistics, profileCompletionData, profileStatsData];
}

class ProfielUpdated extends BeveiligerProfielState with SuccessStateMixin {
  final BeveiligerProfielData profileData;
  
  @override
  final String successMessage;
  
  const ProfielUpdated({
    required this.profileData,
    this.successMessage = 'Profiel succesvol bijgewerkt',
  });
  
  @override
  List<Object> get props => [profileData, successMessage];
}

class ProfielImageUploaded extends BeveiligerProfielState with SuccessStateMixin {
  final String imageUrl;
  final BeveiligerProfielData updatedProfileData;
  
  @override
  final String successMessage;
  
  const ProfielImageUploaded({
    required this.imageUrl,
    required this.updatedProfileData,
    this.successMessage = 'Profielfoto succesvol geüpload',
  });
  
  @override
  List<Object> get props => [imageUrl, updatedProfileData, successMessage];
}

class ProfielError extends BeveiligerProfielState with ErrorStateMixin {
  @override
  final AppError error;
  
  const ProfielError(this.error);
  
  @override
  List<Object> get props => [error];
}

// BLoC
class BeveiligerProfielBloc extends BaseBloc<BeveiligerProfielEvent, BeveiligerProfielState> {
  final BeveiligerProfielService _profielService;
  final ProfileCompletionService _completionService;
  
  BeveiligerProfielBloc({
    BeveiligerProfielService? profielService,
    ProfileCompletionService? completionService,
  }) : _profielService = profielService ?? BeveiligerProfielService.instance,
       _completionService = completionService ?? ProfileCompletionService.instance,
       super(const ProfielInitial()) {
    
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UploadProfileImage>(_onUploadProfileImage);
    on<RefreshProfile>(_onRefreshProfile);
    
    // Certificate event handlers
    on<LoadCertificates>(_onLoadCertificates);
    on<AddCertificate>(_onAddCertificate);
    on<VerifyCertificate>(_onVerifyCertificate);
    
    // Profile completion event handlers
    on<LoadProfileCompletion>(_onLoadProfileCompletion);
    on<LoadProfileStats>(_onLoadProfileStats);
    on<NavigateToProfileSection>(_onNavigateToProfileSection);
    on<TrackCompletionMilestone>(_onTrackCompletionMilestone);
  }
  
  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<BeveiligerProfielState> emit,
  ) async {
    try {
      emit(const ProfielLoading(loadingMessage: 'Profiel laden...'));
      
      // Use provided userId or current logged in user
      final userId = event.userId ?? AuthService.currentUserId;
      
      if (userId.isEmpty) {
        emit(ProfielError(AppError(
          code: 'no_user',
          message: 'Geen gebruiker ingelogd',
          category: ErrorCategory.authentication,
          severity: ErrorSeverity.high,
        )));
        return;
      }
      
      // Load profile data
      final profileData = await _profielService.loadProfile(userId);
      
      // Get profile statistics
      final statistics = _profielService.getProfileStatistics(profileData);
      
      emit(ProfielLoaded(
        profileData: profileData,
        statistics: statistics,
      ));
      
    } catch (e) {
      emit(ProfielError(AppError.fromException(e)));
    }
  }
  
  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<BeveiligerProfielState> emit,
  ) async {
    try {
      emit(const ProfielLoading(loadingMessage: 'Profiel bijwerken...'));
      
      // Validate profile data
      if (!event.profileData.isValid) {
        final errors = event.profileData.validationErrors;
        emit(ProfielError(AppError(
          code: 'validation_failed',
          message: 'Profiel validatie mislukt',
          details: errors.join('\n'),
          category: ErrorCategory.validation,
          severity: ErrorSeverity.medium,
        )));
        return;
      }
      
      // Update profile
      final success = await _profielService.updateProfile(event.profileData);
      
      if (success) {
        // Get updated statistics
        final statistics = _profielService.getProfileStatistics(event.profileData);
        
        emit(ProfielUpdated(profileData: event.profileData));
        
        // Emit loaded state with updated data
        emit(ProfielLoaded(
          profileData: event.profileData,
          statistics: statistics,
        ));
      } else {
        emit(ProfielError(AppError(
          code: 'profile_update_failed',
          message: 'Profiel bijwerken mislukt',
          category: ErrorCategory.service,
          severity: ErrorSeverity.medium,
        )));
      }
      
    } catch (e) {
      emit(ProfielError(AppError.fromException(e)));
    }
  }
  
  Future<void> _onUploadProfileImage(
    UploadProfileImage event,
    Emitter<BeveiligerProfielState> emit,
  ) async {
    try {
      emit(const ProfielLoading(loadingMessage: 'Afbeelding uploaden...'));
      
      // Get current profile data
      if (state is! ProfielLoaded) {
        emit(ProfielError(AppError(
          code: 'profile_not_loaded',
          message: 'Profiel niet geladen. Laad eerst het profiel.',
          category: ErrorCategory.service,
          severity: ErrorSeverity.medium,
        )));
        return;
      }
      
      final currentProfileData = (state as ProfielLoaded).profileData;
      
      // Upload image
      final imageUrl = await _profielService.uploadProfileImage(event.imageFile);
      
      if (imageUrl != null) {
        // Update profile with new image URL
        final updatedProfileData = currentProfileData.copyWith(
          profileImageUrl: imageUrl,
          lastUpdated: DateTime.now(),
        );
        
        // Save updated profile
        final success = await _profielService.updateProfile(updatedProfileData);
        
        if (success) {
          emit(ProfielImageUploaded(
            imageUrl: imageUrl,
            updatedProfileData: updatedProfileData,
          ));
          
          // Get updated statistics and emit loaded state
          final statistics = _profielService.getProfileStatistics(updatedProfileData);
          
          emit(ProfielLoaded(
            profileData: updatedProfileData,
            statistics: statistics,
          ));
        } else {
          emit(ProfielError(AppError(
            code: 'profile_update_failed',
            message: 'Profiel bijwerken na afbeelding upload mislukt',
            category: ErrorCategory.service,
            severity: ErrorSeverity.medium,
          )));
        }
      } else {
        emit(ProfielError(AppError(
          code: 'image_upload_failed',
          message: 'Afbeelding uploaden mislukt',
          category: ErrorCategory.service,
          severity: ErrorSeverity.medium,
        )));
      }
      
    } catch (e) {
      emit(ProfielError(AppError.fromException(e)));
    }
  }
  
  Future<void> _onRefreshProfile(
    RefreshProfile event,
    Emitter<BeveiligerProfielState> emit,
  ) async {
    try {
      emit(const ProfielLoading(loadingMessage: 'Profiel verversen...'));
      
      // Use provided userId or current logged in user
      final userId = event.userId ?? AuthService.currentUserId;
      
      if (userId.isEmpty) {
        emit(ProfielError(AppError(
          code: 'no_user',
          message: 'Geen gebruiker ingelogd',
          category: ErrorCategory.authentication,
          severity: ErrorSeverity.high,
        )));
        return;
      }
      
      // Refresh profile data (clears cache)
      final profileData = await _profielService.refreshProfile(userId);
      
      // Get fresh statistics
      final statistics = _profielService.getProfileStatistics(profileData);
      
      emit(ProfielLoaded(
        profileData: profileData,
        statistics: statistics,
      ));
      
    } catch (e) {
      emit(ProfielError(AppError.fromException(e)));
    }
  }

  Future<void> _onLoadCertificates(
    LoadCertificates event,
    Emitter<BeveiligerProfielState> emit,
  ) async {
    try {
      emit(const ProfielLoading(loadingMessage: 'Certificaten laden...'));
      
      // Load certificates via service
      await _profielService.loadCertificates(event.userId);
      
      // Reload profile to refresh statistics
      final profileData = await _profielService.loadProfile(event.userId);
      final statistics = _profielService.getProfileStatistics(profileData);
      
      emit(ProfielLoaded(
        profileData: profileData,
        statistics: statistics,
      ));
      
    } catch (e) {
      emit(ProfielError(AppError.fromException(e)));
    }
  }
  
  Future<void> _onAddCertificate(
    AddCertificate event,
    Emitter<BeveiligerProfielState> emit,
  ) async {
    try {
      emit(const ProfielLoading(loadingMessage: 'Certificaat toevoegen...'));
      
      final success = await _profielService.addCertificate(event.certificateData);
      
      if (success) {
        // Reload profile to show updated certificates
        final userId = event.certificateData['userId'] as String;
        final profileData = await _profielService.loadProfile(userId);
        final statistics = _profielService.getProfileStatistics(profileData);
        
        emit(ProfielLoaded(
          profileData: profileData,
          statistics: statistics,
        ));
        
        // Emit success state
        emit(ProfielUpdated(
          profileData: profileData,
          successMessage: 'Certificaat succesvol toegevoegd',
        ));
      } else {
        emit(ProfielError(AppError(
          code: 'certificate_add_failed',
          message: 'Certificaat toevoegen mislukt',
          category: ErrorCategory.service,
          severity: ErrorSeverity.medium,
        )));
      }
      
    } catch (e) {
      emit(ProfielError(AppError.fromException(e)));
    }
  }
  
  Future<void> _onVerifyCertificate(
    VerifyCertificate event,
    Emitter<BeveiligerProfielState> emit,
  ) async {
    try {
      emit(const ProfielLoading(loadingMessage: 'Certificaat verificeren...'));
      
      final result = await _profielService.verifyCertificate(
        event.certificateNumber,
        event.certificateType,
      );
      
      if (result != null) {
        // Certificate verification successful
        // Current state will be maintained, verification message shown in UI
      } else {
        emit(ProfielError(AppError(
          code: 'certificate_verification_failed',
          message: 'Certificaat verificatie mislukt',
          category: ErrorCategory.service,
          severity: ErrorSeverity.medium,
        )));
      }
      
    } catch (e) {
      emit(ProfielError(AppError.fromException(e)));
    }
  }

  Future<void> _onLoadProfileCompletion(
    LoadProfileCompletion event,
    Emitter<BeveiligerProfielState> emit,
  ) async {
    try {
      final completionData = await _completionService.calculateCompletionPercentage(event.userId);
      
      if (state is BeveiligerProfielLoaded) {
        final currentState = state as BeveiligerProfielLoaded;
        emit(currentState.copyWith(profileCompletionData: completionData));
      } else if (state is ProfielLoaded) {
        final currentState = state as ProfielLoaded;
        emit(BeveiligerProfielLoaded(
          profileData: currentState.profileData,
          statistics: currentState.statistics,
          profileCompletionData: completionData,
        ));
      }
    } catch (e) {
      emit(ProfielError(AppError.fromException(e)));
    }
  }

  Future<void> _onLoadProfileStats(
    LoadProfileStats event,
    Emitter<BeveiligerProfielState> emit,
  ) async {
    try {
      final statsData = await _completionService.getProfileStats(event.userId);
      
      if (state is BeveiligerProfielLoaded) {
        final currentState = state as BeveiligerProfielLoaded;
        emit(currentState.copyWith(profileStatsData: statsData));
      } else if (state is ProfielLoaded) {
        final currentState = state as ProfielLoaded;
        emit(BeveiligerProfielLoaded(
          profileData: currentState.profileData,
          statistics: currentState.statistics,
          profileStatsData: statsData,
        ));
      }
    } catch (e) {
      emit(ProfielError(AppError.fromException(e)));
    }
  }

  Future<void> _onNavigateToProfileSection(
    NavigateToProfileSection event,
    Emitter<BeveiligerProfielState> emit,
  ) async {
    try {
      // This would typically trigger navigation to the appropriate profile section
      // For now, we'll just track the analytics event
      final userId = AuthService.currentUserId;
      if (userId.isNotEmpty) {
        await _completionService.trackQuickActionUsed(userId, event.elementType);
      }
      
      // Could emit a navigation state or handle navigation differently
      // For now, maintain current state
    } catch (e) {
      emit(ProfielError(AppError.fromException(e)));
    }
  }

  Future<void> _onTrackCompletionMilestone(
    TrackCompletionMilestone event,
    Emitter<BeveiligerProfielState> emit,
  ) async {
    try {
      await _completionService.trackCompletionMilestone(event.userId, event.milestone);
      
      // Reload completion data to reflect any updates
      final completionData = await _completionService.calculateCompletionPercentage(event.userId);
      
      if (state is BeveiligerProfielLoaded) {
        final currentState = state as BeveiligerProfielLoaded;
        emit(currentState.copyWith(profileCompletionData: completionData));
      }
    } catch (e) {
      emit(ProfielError(AppError.fromException(e)));
    }
  }
}