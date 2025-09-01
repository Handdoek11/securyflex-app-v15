import '../../core/bloc/base_bloc.dart';

/// Base class for all settings events in SecuryFlex
abstract class SettingsEvent extends BaseEvent {
  const SettingsEvent();
}

/// Initialize settings and load from storage
class SettingsInitialize extends SettingsEvent {
  const SettingsInitialize();
}

/// Load settings from storage
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

/// Save all settings to storage
class SaveSettings extends SettingsEvent {
  const SaveSettings();
}

/// Reset settings to defaults
class ResetSettings extends SettingsEvent {
  const ResetSettings();
}

/// Update notification settings
class UpdateNotificationSettings extends SettingsEvent {
  final bool? notificationsEnabled;
  final bool? messageNotifications;
  final bool? fileNotifications;
  final bool? systemNotifications;
  final bool? soundEnabled;
  final bool? vibrationEnabled;
  final bool? showPreview;
  
  const UpdateNotificationSettings({
    this.notificationsEnabled,
    this.messageNotifications,
    this.fileNotifications,
    this.systemNotifications,
    this.soundEnabled,
    this.vibrationEnabled,
    this.showPreview,
  });
  
  @override
  List<Object?> get props => [
    notificationsEnabled,
    messageNotifications,
    fileNotifications,
    systemNotifications,
    soundEnabled,
    vibrationEnabled,
    showPreview,
  ];
  
  @override
  String toString() => 'UpdateNotificationSettings(notificationsEnabled: $notificationsEnabled, messageNotifications: $messageNotifications, fileNotifications: $fileNotifications, systemNotifications: $systemNotifications, soundEnabled: $soundEnabled, vibrationEnabled: $vibrationEnabled, showPreview: $showPreview)';
}

/// Update quiet hours settings
class UpdateQuietHours extends SettingsEvent {
  final bool? quietHoursEnabled;
  final int? startHour;
  final int? startMinute;
  final int? endHour;
  final int? endMinute;
  
  const UpdateQuietHours({
    this.quietHoursEnabled,
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
  });
  
  @override
  List<Object?> get props => [quietHoursEnabled, startHour, startMinute, endHour, endMinute];
  
  @override
  String toString() => 'UpdateQuietHours(quietHoursEnabled: $quietHoursEnabled, startHour: $startHour, startMinute: $startMinute, endHour: $endHour, endMinute: $endMinute)';
}

/// Update app preferences
class UpdateAppPreferences extends SettingsEvent {
  final String? language;
  final String? theme;
  final bool? darkMode;
  final bool? autoSync;
  final bool? offlineMode;
  final int? syncInterval;
  
  const UpdateAppPreferences({
    this.language,
    this.theme,
    this.darkMode,
    this.autoSync,
    this.offlineMode,
    this.syncInterval,
  });
  
  @override
  List<Object?> get props => [language, theme, darkMode, autoSync, offlineMode, syncInterval];
  
  @override
  String toString() => 'UpdateAppPreferences(language: $language, theme: $theme, darkMode: $darkMode, autoSync: $autoSync, offlineMode: $offlineMode, syncInterval: $syncInterval)';
}

/// Update privacy settings
class UpdatePrivacySettings extends SettingsEvent {
  final bool? readReceipts;
  final bool? typingIndicators;
  final bool? lastSeenVisible;
  final bool? profilePhotoVisible;
  final bool? statusVisible;
  final bool? analyticsEnabled;
  final bool? crashReportsEnabled;
  
  const UpdatePrivacySettings({
    this.readReceipts,
    this.typingIndicators,
    this.lastSeenVisible,
    this.profilePhotoVisible,
    this.statusVisible,
    this.analyticsEnabled,
    this.crashReportsEnabled,
  });
  
  @override
  List<Object?> get props => [
    readReceipts,
    typingIndicators,
    lastSeenVisible,
    profilePhotoVisible,
    statusVisible,
    analyticsEnabled,
    crashReportsEnabled,
  ];
  
  @override
  String toString() => 'UpdatePrivacySettings(readReceipts: $readReceipts, typingIndicators: $typingIndicators, lastSeenVisible: $lastSeenVisible, profilePhotoVisible: $profilePhotoVisible, statusVisible: $statusVisible, analyticsEnabled: $analyticsEnabled, crashReportsEnabled: $crashReportsEnabled)';
}

/// Update security settings
class UpdateSecuritySettings extends SettingsEvent {
  final bool? biometricEnabled;
  final bool? pinEnabled;
  final String? pinCode;
  final bool? autoLockEnabled;
  final int? autoLockTimeout;
  final bool? screenCaptureBlocked;
  
  const UpdateSecuritySettings({
    this.biometricEnabled,
    this.pinEnabled,
    this.pinCode,
    this.autoLockEnabled,
    this.autoLockTimeout,
    this.screenCaptureBlocked,
  });
  
  @override
  List<Object?> get props => [
    biometricEnabled,
    pinEnabled,
    pinCode,
    autoLockEnabled,
    autoLockTimeout,
    screenCaptureBlocked,
  ];
  
  @override
  String toString() => 'UpdateSecuritySettings(biometricEnabled: $biometricEnabled, pinEnabled: $pinEnabled, autoLockEnabled: $autoLockEnabled, autoLockTimeout: $autoLockTimeout, screenCaptureBlocked: $screenCaptureBlocked)';
}

/// Update data usage settings
class UpdateDataUsageSettings extends SettingsEvent {
  final bool? wifiOnlyDownloads;
  final bool? autoDownloadImages;
  final bool? autoDownloadVideos;
  final bool? autoDownloadDocuments;
  final int? maxFileSize;
  final bool? compressImages;
  final bool? lowDataMode;
  
  const UpdateDataUsageSettings({
    this.wifiOnlyDownloads,
    this.autoDownloadImages,
    this.autoDownloadVideos,
    this.autoDownloadDocuments,
    this.maxFileSize,
    this.compressImages,
    this.lowDataMode,
  });
  
  @override
  List<Object?> get props => [
    wifiOnlyDownloads,
    autoDownloadImages,
    autoDownloadVideos,
    autoDownloadDocuments,
    maxFileSize,
    compressImages,
    lowDataMode,
  ];
  
  @override
  String toString() => 'UpdateDataUsageSettings(wifiOnlyDownloads: $wifiOnlyDownloads, autoDownloadImages: $autoDownloadImages, autoDownloadVideos: $autoDownloadVideos, autoDownloadDocuments: $autoDownloadDocuments, maxFileSize: $maxFileSize, compressImages: $compressImages, lowDataMode: $lowDataMode)';
}

/// Export settings data
class ExportSettings extends SettingsEvent {
  const ExportSettings();
}

/// Import settings data
class ImportSettings extends SettingsEvent {
  final Map<String, dynamic> settingsData;
  
  const ImportSettings(this.settingsData);
  
  @override
  List<Object> get props => [settingsData];
  
  @override
  String toString() => 'ImportSettings(settingsData: $settingsData)';
}

/// Clear all settings data
class ClearAllSettings extends SettingsEvent {
  const ClearAllSettings();
}

/// Validate settings integrity
class ValidateSettings extends SettingsEvent {
  const ValidateSettings();
}
