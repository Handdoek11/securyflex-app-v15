import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/base_bloc.dart';
import '../../core/bloc/error_handler.dart';
import '../repository/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// Settings BLoC for SecuryFlex
/// Manages all application settings with persistence and validation
class SettingsBloc extends BaseBloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;
  Timer? _autoSaveTimer;
  
  SettingsBloc({
    SettingsRepository? repository,
  }) : _repository = repository ?? SettingsRepository(),
        super(const SettingsInitial()) {
    
    // Register event handlers
    on<SettingsInitialize>(_onInitialize);
    on<LoadSettings>(_onLoadSettings);
    on<SaveSettings>(_onSaveSettings);
    on<ResetSettings>(_onResetSettings);
    on<UpdateNotificationSettings>(_onUpdateNotificationSettings);
    on<UpdateQuietHours>(_onUpdateQuietHours);
    on<UpdateAppPreferences>(_onUpdateAppPreferences);
    on<UpdatePrivacySettings>(_onUpdatePrivacySettings);
    on<UpdateSecuritySettings>(_onUpdateSecuritySettings);
    on<UpdateDataUsageSettings>(_onUpdateDataUsageSettings);
    on<ExportSettings>(_onExportSettings);
    on<ImportSettings>(_onImportSettings);
    on<ClearAllSettings>(_onClearAllSettings);
    on<ValidateSettings>(_onValidateSettings);
  }
  
  /// Initialize settings
  Future<void> _onInitialize(SettingsInitialize event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading(loadingMessage: 'Instellingen laden...'));
    
    try {
      final settings = await _repository.loadSettings();
      emit(settings);
      
      debugPrint('Settings initialized successfully');
    } catch (e) {
      emit(SettingsError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Load settings from storage
  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading(loadingMessage: 'Instellingen laden...'));
    
    try {
      final settings = await _repository.loadSettings();
      emit(settings);
    } catch (e) {
      emit(SettingsError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Save settings to storage
  Future<void> _onSaveSettings(SaveSettings event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      
      try {
        await _repository.saveSettings(currentState);
        
        final updatedSettings = currentState.copyWith(
          hasUnsavedChanges: false,
          lastUpdated: DateTime.now(),
        );
        
        emit(SettingsSaved(updatedSettings: updatedSettings));
        
        // Return to loaded state after showing success
        await Future.delayed(const Duration(milliseconds: 100));
        if (!isClosed) {
          emit(updatedSettings);
        }
      } catch (e) {
        emit(SettingsError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Reset settings to defaults
  Future<void> _onResetSettings(ResetSettings event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading(loadingMessage: 'Instellingen resetten...'));
    
    try {
      await _repository.resetSettings();
      
      // Load default settings
      final defaultSettings = SettingsLoaded(
        notificationSettings: const NotificationSettings(),
        appPreferences: const AppPreferences(),
        privacySettings: const PrivacySettings(),
        securitySettings: const SecuritySettings(),
        dataUsageSettings: const DataUsageSettings(),
        lastUpdated: DateTime.now(),
      );
      
      await _repository.saveSettings(defaultSettings);
      emit(defaultSettings);
      
      debugPrint('Settings reset to defaults');
    } catch (e) {
      emit(SettingsError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Update notification settings
  Future<void> _onUpdateNotificationSettings(UpdateNotificationSettings event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      
      final updatedNotificationSettings = currentState.notificationSettings.copyWith(
        notificationsEnabled: event.notificationsEnabled,
        messageNotifications: event.messageNotifications,
        fileNotifications: event.fileNotifications,
        systemNotifications: event.systemNotifications,
        soundEnabled: event.soundEnabled,
        vibrationEnabled: event.vibrationEnabled,
        showPreview: event.showPreview,
      );
      
      final updatedSettings = currentState.copyWith(
        notificationSettings: updatedNotificationSettings,
        hasUnsavedChanges: true,
      );
      
      emit(updatedSettings);
      _scheduleAutoSave();
    }
  }
  
  /// Update quiet hours settings
  Future<void> _onUpdateQuietHours(UpdateQuietHours event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      
      final updatedNotificationSettings = currentState.notificationSettings.copyWith(
        quietHoursEnabled: event.quietHoursEnabled,
        quietHoursStartHour: event.startHour,
        quietHoursStartMinute: event.startMinute,
        quietHoursEndHour: event.endHour,
        quietHoursEndMinute: event.endMinute,
      );
      
      final updatedSettings = currentState.copyWith(
        notificationSettings: updatedNotificationSettings,
        hasUnsavedChanges: true,
      );
      
      emit(updatedSettings);
      _scheduleAutoSave();
    }
  }
  
  /// Update app preferences
  Future<void> _onUpdateAppPreferences(UpdateAppPreferences event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      
      final updatedAppPreferences = currentState.appPreferences.copyWith(
        language: event.language,
        theme: event.theme,
        darkMode: event.darkMode,
        autoSync: event.autoSync,
        offlineMode: event.offlineMode,
        syncInterval: event.syncInterval,
      );
      
      final updatedSettings = currentState.copyWith(
        appPreferences: updatedAppPreferences,
        hasUnsavedChanges: true,
      );
      
      emit(updatedSettings);
      _scheduleAutoSave();
    }
  }
  
  /// Update privacy settings
  Future<void> _onUpdatePrivacySettings(UpdatePrivacySettings event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      
      final updatedPrivacySettings = currentState.privacySettings.copyWith(
        readReceipts: event.readReceipts,
        typingIndicators: event.typingIndicators,
        lastSeenVisible: event.lastSeenVisible,
        profilePhotoVisible: event.profilePhotoVisible,
        statusVisible: event.statusVisible,
        analyticsEnabled: event.analyticsEnabled,
        crashReportsEnabled: event.crashReportsEnabled,
      );
      
      final updatedSettings = currentState.copyWith(
        privacySettings: updatedPrivacySettings,
        hasUnsavedChanges: true,
      );
      
      emit(updatedSettings);
      _scheduleAutoSave();
    }
  }
  
  /// Update security settings
  Future<void> _onUpdateSecuritySettings(UpdateSecuritySettings event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      
      final updatedSecuritySettings = currentState.securitySettings.copyWith(
        biometricEnabled: event.biometricEnabled,
        pinEnabled: event.pinEnabled,
        pinCode: event.pinCode,
        autoLockEnabled: event.autoLockEnabled,
        autoLockTimeout: event.autoLockTimeout,
        screenCaptureBlocked: event.screenCaptureBlocked,
      );
      
      final updatedSettings = currentState.copyWith(
        securitySettings: updatedSecuritySettings,
        hasUnsavedChanges: true,
      );
      
      emit(updatedSettings);
      _scheduleAutoSave();
    }
  }
  
  /// Update data usage settings
  Future<void> _onUpdateDataUsageSettings(UpdateDataUsageSettings event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      
      final updatedDataUsageSettings = currentState.dataUsageSettings.copyWith(
        wifiOnlyDownloads: event.wifiOnlyDownloads,
        autoDownloadImages: event.autoDownloadImages,
        autoDownloadVideos: event.autoDownloadVideos,
        autoDownloadDocuments: event.autoDownloadDocuments,
        maxFileSize: event.maxFileSize,
        compressImages: event.compressImages,
        lowDataMode: event.lowDataMode,
      );
      
      final updatedSettings = currentState.copyWith(
        dataUsageSettings: updatedDataUsageSettings,
        hasUnsavedChanges: true,
      );
      
      emit(updatedSettings);
      _scheduleAutoSave();
    }
  }
  
  /// Export settings
  Future<void> _onExportSettings(ExportSettings event, Emitter<SettingsState> emit) async {
    try {
      final exportData = await _repository.exportSettings();
      
      // In a real app, this would save to a file or share
      final exportPath = '/storage/emulated/0/Download/securyflex_settings.json';
      
      emit(SettingsExported(
        exportPath: exportPath,
        exportedData: exportData,
      ));
      
      debugPrint('Settings exported to $exportPath');
    } catch (e) {
      emit(SettingsError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Import settings
  Future<void> _onImportSettings(ImportSettings event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading(loadingMessage: 'Instellingen importeren...'));
    
    try {
      final importedSettings = await _repository.importSettings(event.settingsData);
      
      emit(SettingsImported(
        importedSettings: importedSettings,
        importedCount: _countImportedSettings(event.settingsData),
      ));
      
      // Return to loaded state after showing success
      await Future.delayed(const Duration(milliseconds: 100));
      if (!isClosed) {
        emit(importedSettings);
      }
      
      debugPrint('Settings imported successfully');
    } catch (e) {
      emit(SettingsError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Clear all settings
  Future<void> _onClearAllSettings(ClearAllSettings event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading(loadingMessage: 'Alle instellingen wissen...'));
    
    try {
      await _repository.resetSettings();
      emit(const SettingsInitial());
      
      debugPrint('All settings cleared');
    } catch (e) {
      emit(SettingsError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Validate settings integrity
  Future<void> _onValidateSettings(ValidateSettings event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      
      try {
        // Validate settings integrity
        _validateNotificationSettings(currentState.notificationSettings);
        _validateAppPreferences(currentState.appPreferences);
        _validateSecuritySettings(currentState.securitySettings);
        _validateDataUsageSettings(currentState.dataUsageSettings);
        
        debugPrint('Settings validation passed');
      } catch (e) {
        emit(SettingsError(AppError(
          code: 'settings_validation_failed',
          message: 'Settings validation failed: $e',
          category: ErrorCategory.validation,
        )));
      }
    }
  }
  
  /// Schedule auto-save after changes
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (!isClosed && state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        if (currentState.hasUnsavedChanges) {
          add(const SaveSettings());
        }
      }
    });
  }
  
  /// Count imported settings
  int _countImportedSettings(Map<String, dynamic> data) {
    int count = 0;
    if (data.containsKey('notifications')) count++;
    if (data.containsKey('app')) count++;
    if (data.containsKey('privacy')) count++;
    if (data.containsKey('security')) count++;
    if (data.containsKey('dataUsage')) count++;
    return count;
  }
  
  /// Validate notification settings
  void _validateNotificationSettings(NotificationSettings settings) {
    if (settings.quietHoursStartHour < 0 || settings.quietHoursStartHour > 23) {
      throw Exception('Invalid quiet hours start hour');
    }
    if (settings.quietHoursEndHour < 0 || settings.quietHoursEndHour > 23) {
      throw Exception('Invalid quiet hours end hour');
    }
    if (settings.quietHoursStartMinute < 0 || settings.quietHoursStartMinute > 59) {
      throw Exception('Invalid quiet hours start minute');
    }
    if (settings.quietHoursEndMinute < 0 || settings.quietHoursEndMinute > 59) {
      throw Exception('Invalid quiet hours end minute');
    }
  }
  
  /// Validate app preferences
  void _validateAppPreferences(AppPreferences preferences) {
    if (!['nl', 'en'].contains(preferences.language)) {
      throw Exception('Invalid language setting');
    }
    if (!['system', 'light', 'dark'].contains(preferences.theme)) {
      throw Exception('Invalid theme setting');
    }
    if (preferences.syncInterval < 60 || preferences.syncInterval > 3600) {
      throw Exception('Invalid sync interval');
    }
  }
  
  /// Validate security settings
  void _validateSecuritySettings(SecuritySettings settings) {
    if (settings.autoLockTimeout < 30 || settings.autoLockTimeout > 3600) {
      throw Exception('Invalid auto lock timeout');
    }
    if (settings.pinEnabled && (settings.pinCode == null || settings.pinCode!.length < 4)) {
      throw Exception('PIN code must be at least 4 characters');
    }
  }
  
  /// Validate data usage settings
  void _validateDataUsageSettings(DataUsageSettings settings) {
    if (settings.maxFileSize < 1024 || settings.maxFileSize > 104857600) { // 1KB to 100MB
      throw Exception('Invalid max file size');
    }
  }
  
  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    return super.close();
  }
  
  /// Convenience getters for current settings state
  bool get isLoaded => state is SettingsLoaded;
  bool get isLoading => state is SettingsLoading;
  bool get hasError => state is SettingsError;
  bool get hasUnsavedChanges => isLoaded ? (state as SettingsLoaded).hasUnsavedChanges : false;
  
  SettingsLoaded? get currentSettings {
    return state is SettingsLoaded ? state as SettingsLoaded : null;
  }
  
  NotificationSettings get notificationSettings {
    return currentSettings?.notificationSettings ?? const NotificationSettings();
  }
  
  AppPreferences get appPreferences {
    return currentSettings?.appPreferences ?? const AppPreferences();
  }
  
  PrivacySettings get privacySettings {
    return currentSettings?.privacySettings ?? const PrivacySettings();
  }
  
  SecuritySettings get securitySettings {
    return currentSettings?.securitySettings ?? const SecuritySettings();
  }
  
  DataUsageSettings get dataUsageSettings {
    return currentSettings?.dataUsageSettings ?? const DataUsageSettings();
  }
}
