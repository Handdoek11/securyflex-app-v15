import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/bloc/base_bloc.dart';
import '../../core/bloc/error_handler.dart';

/// Base class for all settings states in SecuryFlex
abstract class SettingsState extends BaseState {
  const SettingsState();
}

/// Initial settings state
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Settings loading state
class SettingsLoading extends SettingsState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage;
  
  const SettingsLoading({this.loadingMessage});
  
  @override
  List<Object?> get props => [loadingMessage];
  
  @override
  String toString() => 'SettingsLoading(message: $loadingMessage)';
}

/// Settings loaded successfully
class SettingsLoaded extends SettingsState {
  final NotificationSettings notificationSettings;
  final AppPreferences appPreferences;
  final PrivacySettings privacySettings;
  final SecuritySettings securitySettings;
  final DataUsageSettings dataUsageSettings;
  final DateTime lastUpdated;
  final bool hasUnsavedChanges;
  
  const SettingsLoaded({
    required this.notificationSettings,
    required this.appPreferences,
    required this.privacySettings,
    required this.securitySettings,
    required this.dataUsageSettings,
    required this.lastUpdated,
    this.hasUnsavedChanges = false,
  });
  
  /// Get Dutch summary of current settings
  String get settingsSummary {
    final List<String> summaryParts = [];
    
    if (!notificationSettings.notificationsEnabled) {
      summaryParts.add('Notificaties uitgeschakeld');
    } else {
      summaryParts.add('Notificaties ingeschakeld');
    }
    
    if (notificationSettings.quietHoursEnabled) {
      summaryParts.add('Stille uren actief');
    }
    
    if (securitySettings.biometricEnabled) {
      summaryParts.add('Biometrische beveiliging');
    }
    
    if (privacySettings.analyticsEnabled) {
      summaryParts.add('Analytics ingeschakeld');
    }
    
    return summaryParts.join(', ');
  }
  
  /// Check if quiet hours are currently active
  bool get isQuietHoursActive {
    if (!notificationSettings.quietHoursEnabled) return false;
    
    final now = TimeOfDay.now();
    final start = TimeOfDay(
      hour: notificationSettings.quietHoursStartHour,
      minute: notificationSettings.quietHoursStartMinute,
    );
    final end = TimeOfDay(
      hour: notificationSettings.quietHoursEndHour,
      minute: notificationSettings.quietHoursEndMinute,
    );
    
    // Handle overnight quiet hours (e.g., 22:00 to 08:00)
    if (start.hour > end.hour) {
      return now.hour >= start.hour || now.hour < end.hour;
    } else {
      return now.hour >= start.hour && now.hour < end.hour;
    }
  }
  
  /// Get notification status in Dutch
  String get notificationStatus {
    if (!notificationSettings.notificationsEnabled) {
      return 'Uitgeschakeld';
    } else if (isQuietHoursActive) {
      return 'Stille uren actief';
    } else {
      return 'Ingeschakeld';
    }
  }
  
  /// Create a copy with updated properties
  SettingsLoaded copyWith({
    NotificationSettings? notificationSettings,
    AppPreferences? appPreferences,
    PrivacySettings? privacySettings,
    SecuritySettings? securitySettings,
    DataUsageSettings? dataUsageSettings,
    DateTime? lastUpdated,
    bool? hasUnsavedChanges,
  }) {
    return SettingsLoaded(
      notificationSettings: notificationSettings ?? this.notificationSettings,
      appPreferences: appPreferences ?? this.appPreferences,
      privacySettings: privacySettings ?? this.privacySettings,
      securitySettings: securitySettings ?? this.securitySettings,
      dataUsageSettings: dataUsageSettings ?? this.dataUsageSettings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
  
  @override
  List<Object> get props => [
    notificationSettings,
    appPreferences,
    privacySettings,
    securitySettings,
    dataUsageSettings,
    lastUpdated,
    hasUnsavedChanges,
  ];
  
  @override
  String toString() => 'SettingsLoaded(hasUnsavedChanges: $hasUnsavedChanges, lastUpdated: $lastUpdated)';
}

/// Settings save successful
class SettingsSaved extends SettingsState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final SettingsLoaded updatedSettings;
  
  const SettingsSaved({
    required this.updatedSettings,
    this.successMessage = 'Instellingen opgeslagen',
  });
  
  @override
  String get localizedSuccessMessage => successMessage;
  
  @override
  List<Object> get props => [updatedSettings, successMessage];
  
  @override
  String toString() => 'SettingsSaved(message: $successMessage)';
}

/// Settings error state
class SettingsError extends SettingsState with ErrorStateMixin {
  @override
  final AppError error;
  
  const SettingsError(this.error);
  
  @override
  List<Object> get props => [error];
  
  @override
  String toString() => 'SettingsError(error: ${error.localizedMessage})';
}

/// Settings exported successfully
class SettingsExported extends SettingsState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final String exportPath;
  final Map<String, dynamic> exportedData;
  
  const SettingsExported({
    required this.exportPath,
    required this.exportedData,
    this.successMessage = 'Instellingen geëxporteerd',
  });
  
  @override
  String get localizedSuccessMessage => 'Instellingen geëxporteerd naar $exportPath';
  
  @override
  List<Object> get props => [exportPath, exportedData, successMessage];
  
  @override
  String toString() => 'SettingsExported(exportPath: $exportPath)';
}

/// Settings imported successfully
class SettingsImported extends SettingsState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final SettingsLoaded importedSettings;
  final int importedCount;
  
  const SettingsImported({
    required this.importedSettings,
    required this.importedCount,
    this.successMessage = 'Instellingen geïmporteerd',
  });
  
  @override
  String get localizedSuccessMessage => '$importedCount instellingen succesvol geïmporteerd';
  
  @override
  List<Object> get props => [importedSettings, importedCount, successMessage];
  
  @override
  String toString() => 'SettingsImported(importedCount: $importedCount)';
}

/// Notification settings data class
class NotificationSettings extends Equatable {
  final bool notificationsEnabled;
  final bool messageNotifications;
  final bool fileNotifications;
  final bool systemNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool showPreview;
  final bool quietHoursEnabled;
  final int quietHoursStartHour;
  final int quietHoursStartMinute;
  final int quietHoursEndHour;
  final int quietHoursEndMinute;
  
  const NotificationSettings({
    this.notificationsEnabled = true,
    this.messageNotifications = true,
    this.fileNotifications = true,
    this.systemNotifications = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.showPreview = true,
    this.quietHoursEnabled = false,
    this.quietHoursStartHour = 22,
    this.quietHoursStartMinute = 0,
    this.quietHoursEndHour = 8,
    this.quietHoursEndMinute = 0,
  });
  
  NotificationSettings copyWith({
    bool? notificationsEnabled,
    bool? messageNotifications,
    bool? fileNotifications,
    bool? systemNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? showPreview,
    bool? quietHoursEnabled,
    int? quietHoursStartHour,
    int? quietHoursStartMinute,
    int? quietHoursEndHour,
    int? quietHoursEndMinute,
  }) {
    return NotificationSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      fileNotifications: fileNotifications ?? this.fileNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      showPreview: showPreview ?? this.showPreview,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
      quietHoursStartMinute: quietHoursStartMinute ?? this.quietHoursStartMinute,
      quietHoursEndHour: quietHoursEndHour ?? this.quietHoursEndHour,
      quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
    );
  }
  
  @override
  List<Object> get props => [
    notificationsEnabled,
    messageNotifications,
    fileNotifications,
    systemNotifications,
    soundEnabled,
    vibrationEnabled,
    showPreview,
    quietHoursEnabled,
    quietHoursStartHour,
    quietHoursStartMinute,
    quietHoursEndHour,
    quietHoursEndMinute,
  ];
}

/// App preferences data class
class AppPreferences extends Equatable {
  final String language;
  final String theme;
  final bool darkMode;
  final bool autoSync;
  final bool offlineMode;
  final int syncInterval;
  
  const AppPreferences({
    this.language = 'nl',
    this.theme = 'system',
    this.darkMode = false,
    this.autoSync = true,
    this.offlineMode = false,
    this.syncInterval = 300, // 5 minutes
  });
  
  AppPreferences copyWith({
    String? language,
    String? theme,
    bool? darkMode,
    bool? autoSync,
    bool? offlineMode,
    int? syncInterval,
  }) {
    return AppPreferences(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      darkMode: darkMode ?? this.darkMode,
      autoSync: autoSync ?? this.autoSync,
      offlineMode: offlineMode ?? this.offlineMode,
      syncInterval: syncInterval ?? this.syncInterval,
    );
  }
  
  @override
  List<Object> get props => [language, theme, darkMode, autoSync, offlineMode, syncInterval];
}

/// Privacy settings data class
class PrivacySettings extends Equatable {
  final bool readReceipts;
  final bool typingIndicators;
  final bool lastSeenVisible;
  final bool profilePhotoVisible;
  final bool statusVisible;
  final bool analyticsEnabled;
  final bool crashReportsEnabled;
  
  const PrivacySettings({
    this.readReceipts = true,
    this.typingIndicators = true,
    this.lastSeenVisible = true,
    this.profilePhotoVisible = true,
    this.statusVisible = true,
    this.analyticsEnabled = true,
    this.crashReportsEnabled = true,
  });
  
  PrivacySettings copyWith({
    bool? readReceipts,
    bool? typingIndicators,
    bool? lastSeenVisible,
    bool? profilePhotoVisible,
    bool? statusVisible,
    bool? analyticsEnabled,
    bool? crashReportsEnabled,
  }) {
    return PrivacySettings(
      readReceipts: readReceipts ?? this.readReceipts,
      typingIndicators: typingIndicators ?? this.typingIndicators,
      lastSeenVisible: lastSeenVisible ?? this.lastSeenVisible,
      profilePhotoVisible: profilePhotoVisible ?? this.profilePhotoVisible,
      statusVisible: statusVisible ?? this.statusVisible,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      crashReportsEnabled: crashReportsEnabled ?? this.crashReportsEnabled,
    );
  }
  
  @override
  List<Object> get props => [
    readReceipts,
    typingIndicators,
    lastSeenVisible,
    profilePhotoVisible,
    statusVisible,
    analyticsEnabled,
    crashReportsEnabled,
  ];
}

/// Security settings data class
class SecuritySettings extends Equatable {
  final bool biometricEnabled;
  final bool pinEnabled;
  final String? pinCode;
  final bool autoLockEnabled;
  final int autoLockTimeout;
  final bool screenCaptureBlocked;
  
  const SecuritySettings({
    this.biometricEnabled = false,
    this.pinEnabled = false,
    this.pinCode,
    this.autoLockEnabled = false,
    this.autoLockTimeout = 300, // 5 minutes
    this.screenCaptureBlocked = false,
  });
  
  SecuritySettings copyWith({
    bool? biometricEnabled,
    bool? pinEnabled,
    String? pinCode,
    bool? autoLockEnabled,
    int? autoLockTimeout,
    bool? screenCaptureBlocked,
  }) {
    return SecuritySettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pinCode: pinCode ?? this.pinCode,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      screenCaptureBlocked: screenCaptureBlocked ?? this.screenCaptureBlocked,
    );
  }
  
  @override
  List<Object?> get props => [
    biometricEnabled,
    pinEnabled,
    pinCode,
    autoLockEnabled,
    autoLockTimeout,
    screenCaptureBlocked,
  ];
}

/// Data usage settings data class
class DataUsageSettings extends Equatable {
  final bool wifiOnlyDownloads;
  final bool autoDownloadImages;
  final bool autoDownloadVideos;
  final bool autoDownloadDocuments;
  final int maxFileSize;
  final bool compressImages;
  final bool lowDataMode;
  
  const DataUsageSettings({
    this.wifiOnlyDownloads = false,
    this.autoDownloadImages = true,
    this.autoDownloadVideos = false,
    this.autoDownloadDocuments = true,
    this.maxFileSize = 10485760, // 10MB
    this.compressImages = true,
    this.lowDataMode = false,
  });
  
  DataUsageSettings copyWith({
    bool? wifiOnlyDownloads,
    bool? autoDownloadImages,
    bool? autoDownloadVideos,
    bool? autoDownloadDocuments,
    int? maxFileSize,
    bool? compressImages,
    bool? lowDataMode,
  }) {
    return DataUsageSettings(
      wifiOnlyDownloads: wifiOnlyDownloads ?? this.wifiOnlyDownloads,
      autoDownloadImages: autoDownloadImages ?? this.autoDownloadImages,
      autoDownloadVideos: autoDownloadVideos ?? this.autoDownloadVideos,
      autoDownloadDocuments: autoDownloadDocuments ?? this.autoDownloadDocuments,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      compressImages: compressImages ?? this.compressImages,
      lowDataMode: lowDataMode ?? this.lowDataMode,
    );
  }
  
  @override
  List<Object> get props => [
    wifiOnlyDownloads,
    autoDownloadImages,
    autoDownloadVideos,
    autoDownloadDocuments,
    maxFileSize,
    compressImages,
    lowDataMode,
  ];
}
