import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:securyflex_app/core/bloc/base_bloc.dart';
import 'package:securyflex_app/core/bloc/error_handler.dart';
import 'package:securyflex_app/beveiliger_profiel/models/beveiliger_profiel_data.dart';
import 'package:securyflex_app/beveiliger_profiel/services/beveiliger_profiel_service.dart';

// Events
abstract class ProfielEditEvent extends BaseEvent {
  const ProfielEditEvent();
}

class StartEdit extends ProfielEditEvent {
  final BeveiligerProfielData profileData;
  
  const StartEdit(this.profileData);
  
  @override
  List<Object> get props => [profileData];
}

class UpdateField extends ProfielEditEvent {
  final String fieldName;
  final dynamic value;
  
  const UpdateField(this.fieldName, this.value);
  
  @override
  List<Object?> get props => [fieldName, value];
}

class SaveProfile extends ProfielEditEvent {
  final BeveiligerProfielData profileData;
  
  const SaveProfile(this.profileData);
  
  @override
  List<Object> get props => [profileData];
}

class UploadImage extends ProfielEditEvent {
  final File imageFile;
  
  const UploadImage(this.imageFile);
  
  @override
  List<Object> get props => [imageFile];
}

class CancelEdit extends ProfielEditEvent {
  const CancelEdit();
}

// States
abstract class ProfielEditState extends BaseState {
  const ProfielEditState();
}

class EditInitial extends ProfielEditState {
  const EditInitial();
}

class EditInProgress extends ProfielEditState {
  final BeveiligerProfielData originalData;
  final BeveiligerProfielData currentData;
  final Map<String, dynamic> changedFields;
  final bool hasUnsavedChanges;
  
  const EditInProgress({
    required this.originalData,
    required this.currentData,
    required this.changedFields,
    required this.hasUnsavedChanges,
  });
  
  @override
  List<Object> get props => [originalData, currentData, changedFields, hasUnsavedChanges];
  
  EditInProgress copyWith({
    BeveiligerProfielData? originalData,
    BeveiligerProfielData? currentData,
    Map<String, dynamic>? changedFields,
    bool? hasUnsavedChanges,
  }) {
    return EditInProgress(
      originalData: originalData ?? this.originalData,
      currentData: currentData ?? this.currentData,
      changedFields: changedFields ?? this.changedFields,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

class EditLoading extends ProfielEditState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage;
  
  const EditLoading({this.loadingMessage});
  
  @override
  List<Object?> get props => [loadingMessage];
}

class EditSuccess extends ProfielEditState with SuccessStateMixin {
  final BeveiligerProfielData updatedData;
  
  @override
  final String successMessage;
  
  const EditSuccess({
    required this.updatedData,
    this.successMessage = 'Profiel succesvol bijgewerkt',
  });
  
  @override
  List<Object> get props => [updatedData, successMessage];
}

class ImageUploading extends ProfielEditState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String loadingMessage = 'Afbeelding uploaden...';
  
  const ImageUploading();
  
  @override
  List<Object> get props => [loadingMessage];
}

class ImageUploaded extends ProfielEditState with SuccessStateMixin {
  final String imageUrl;
  
  @override
  final String successMessage;
  
  const ImageUploaded({
    required this.imageUrl,
    this.successMessage = 'Afbeelding succesvol geüpload',
  });
  
  @override
  List<Object> get props => [imageUrl, successMessage];
}

class EditError extends ProfielEditState with ErrorStateMixin {
  @override
  final AppError error;
  
  const EditError(this.error);
  
  @override
  List<Object> get props => [error];
}

// BLoC
class ProfielEditBloc extends BaseBloc<ProfielEditEvent, ProfielEditState> {
  final BeveiligerProfielService _profielService;
  
  ProfielEditBloc({
    BeveiligerProfielService? profielService,
  }) : _profielService = profielService ?? BeveiligerProfielService.instance,
       super(const EditInitial()) {
    
    on<StartEdit>(_onStartEdit);
    on<UpdateField>(_onUpdateField);
    on<SaveProfile>(_onSaveProfile);
    on<UploadImage>(_onUploadImage);
    on<CancelEdit>(_onCancelEdit);
  }
  
  void _onStartEdit(
    StartEdit event,
    Emitter<ProfielEditState> emit,
  ) {
    emit(EditInProgress(
      originalData: event.profileData,
      currentData: event.profileData,
      changedFields: {},
      hasUnsavedChanges: false,
    ));
  }
  
  void _onUpdateField(
    UpdateField event,
    Emitter<ProfielEditState> emit,
  ) {
    if (state is! EditInProgress) return;
    
    final currentState = state as EditInProgress;
    final updatedChangedFields = Map<String, dynamic>.from(currentState.changedFields);
    updatedChangedFields[event.fieldName] = event.value;
    
    // Create updated profile data based on field name
    BeveiligerProfielData updatedData;
    switch (event.fieldName) {
      case 'name':
        updatedData = currentState.currentData.copyWith(name: event.value as String);
        break;
      case 'email':
        updatedData = currentState.currentData.copyWith(email: event.value as String);
        break;
      case 'phone':
        updatedData = currentState.currentData.copyWith(phone: event.value as String?);
        break;
      case 'bio':
        updatedData = currentState.currentData.copyWith(bio: event.value as String?);
        break;
      case 'kvkNumber':
        updatedData = currentState.currentData.copyWith(kvkNumber: event.value as String?);
        break;
      case 'postalCode':
        updatedData = currentState.currentData.copyWith(postalCode: event.value as String?);
        break;
      case 'wpbrNumber':
        updatedData = currentState.currentData.copyWith(wpbrNumber: event.value as String?);
        break;
      case 'specialisaties':
        updatedData = currentState.currentData.copyWith(specialisaties: event.value as List<String>);
        break;
      case 'certificaten':
        updatedData = currentState.currentData.copyWith(certificaten: event.value as List<String>);
        break;
      case 'profileImageUrl':
        updatedData = currentState.currentData.copyWith(profileImageUrl: event.value as String?);
        break;
      default:
        return; // Unknown field, ignore
    }
    
    emit(currentState.copyWith(
      currentData: updatedData,
      changedFields: updatedChangedFields,
      hasUnsavedChanges: true,
    ));
  }
  
  Future<void> _onSaveProfile(
    SaveProfile event,
    Emitter<ProfielEditState> emit,
  ) async {
    try {
      emit(const EditLoading(loadingMessage: 'Profiel opslaan...'));
      
      // Validate profile data
      if (!event.profileData.isValid) {
        final errors = event.profileData.validationErrors;
        emit(EditError(AppError(
          code: 'validation_failed',
          message: 'Profielgegevens zijn ongeldig',
          details: errors.join('\n'),
          category: ErrorCategory.validation,
          severity: ErrorSeverity.medium,
        )));
        return;
      }
      
      // Update profile via service
      final success = await _profielService.updateProfile(event.profileData);
      
      if (success) {
        emit(EditSuccess(updatedData: event.profileData));
      } else {
        emit(EditError(AppError(
          code: 'profile_update_failed',
          message: 'Profiel bijwerken mislukt',
          details: 'Het profiel kon niet worden opgeslagen. Probeer opnieuw.',
          category: ErrorCategory.service,
          severity: ErrorSeverity.medium,
        )));
      }
      
    } catch (e) {
      emit(EditError(AppError.fromException(e)));
    }
  }
  
  Future<void> _onUploadImage(
    UploadImage event,
    Emitter<ProfielEditState> emit,
  ) async {
    try {
      emit(const ImageUploading());
      
      // Handle empty file (removal)
      if (event.imageFile.path.isEmpty) {
        emit(const ImageUploaded(
          imageUrl: '',
          successMessage: 'Profielfoto verwijderd',
        ));
        return;
      }
      
      // Upload image via service
      final imageUrl = await _profielService.uploadProfileImage(event.imageFile);
      
      if (imageUrl != null) {
        emit(ImageUploaded(imageUrl: imageUrl));
      } else {
        emit(EditError(AppError(
          code: 'image_upload_failed',
          message: 'Afbeelding uploaden mislukt',
          details: 'De afbeelding kon niet worden geüpload. Controleer de bestandsgrootte en -type.',
          category: ErrorCategory.service,
          severity: ErrorSeverity.medium,
        )));
      }
      
    } catch (e) {
      emit(EditError(AppError.fromException(e)));
    }
  }
  
  void _onCancelEdit(
    CancelEdit event,
    Emitter<ProfielEditState> emit,
  ) {
    emit(const EditInitial());
  }
  
  /// Check if there are unsaved changes
  bool get hasUnsavedChanges {
    if (state is EditInProgress) {
      return (state as EditInProgress).hasUnsavedChanges;
    }
    return false;
  }
  
  /// Get current profile data being edited
  BeveiligerProfielData? get currentProfileData {
    if (state is EditInProgress) {
      return (state as EditInProgress).currentData;
    }
    return null;
  }
  
  /// Get original profile data
  BeveiligerProfielData? get originalProfileData {
    if (state is EditInProgress) {
      return (state as EditInProgress).originalData;
    }
    return null;
  }
  
  /// Get changed fields map
  Map<String, dynamic> get changedFields {
    if (state is EditInProgress) {
      return (state as EditInProgress).changedFields;
    }
    return {};
  }
}