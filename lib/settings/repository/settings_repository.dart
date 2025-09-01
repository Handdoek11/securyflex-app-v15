import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/settings_state.dart';

/// Repository for managing settings persistence
/// Handles loading, saving, and synchronization of user settings
class SettingsRepository {
  static const String _notificationPrefix = 'notification_';
  static const String _appPrefix = 'app_';
  static const String _privacyPrefix = 'privacy_';
  static const String _securityPrefix = 'security_';
  static const String _dataUsagePrefix = 'data_usage_';
  static const String _settingsVersionKey = 'settings_version';
  static const String _lastUpdatedKey = 'settings_last_updated';
  
  static const int _currentSettingsVersion = 1;
  
  /// Load all settings from SharedPreferences
  Future<SettingsLoaded> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check settings version for migration
      final version = prefs.getInt(_settingsVersionKey) ?? 0;
      if (version < _currentSettingsVersion) {
        await _migrateSettings(prefs, version);
      }
      
      final notificationSettings = await _loadNotificationSettings(prefs);
      final appPreferences = await _loadAppPreferences(prefs);
      final privacySettings = await _loadPrivacySettings(prefs);
      final securitySettings = await _loadSecuritySettings(prefs);
      final dataUsageSettings = await _loadDataUsageSettings(prefs);
      
      final lastUpdatedMs = prefs.getInt(_lastUpdatedKey) ?? DateTime.now().millisecondsSinceEpoch;
      final lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedMs);
      
      return SettingsLoaded(
        notificationSettings: notificationSettings,
        appPreferences: appPreferences,
        privacySettings: privacySettings,
        securitySettings: securitySettings,
        dataUsageSettings: dataUsageSettings,
        lastUpdated: lastUpdated,
      );
    } catch (e) {
      debugPrint('Error loading settings: $e');
      // Return default settings on error
      return SettingsLoaded(
        notificationSettings: const NotificationSettings(),
        appPreferences: const AppPreferences(),
        privacySettings: const PrivacySettings(),
        securitySettings: const SecuritySettings(),
        dataUsageSettings: const DataUsageSettings(),
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  /// Save all settings to SharedPreferences
  Future<void> saveSettings(SettingsLoaded settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await _saveNotificationSettings(prefs, settings.notificationSettings);
      await _saveAppPreferences(prefs, settings.appPreferences);
      await _savePrivacySettings(prefs, settings.privacySettings);
      await _saveSecuritySettings(prefs, settings.securitySettings);
      await _saveDataUsageSettings(prefs, settings.dataUsageSettings);
      
      // Update metadata
      await prefs.setInt(_settingsVersionKey, _currentSettingsVersion);
      await prefs.setInt(_lastUpdatedKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('Settings saved successfully');
    } catch (e) {
      debugPrint('Error saving settings: $e');
      throw Exception('Failed to save settings: $e');
    }
  }
  
  /// Reset all settings to defaults
  Future<void> resetSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove all settings keys
      final keys = prefs.getKeys().where((key) => 
        key.startsWith(_notificationPrefix) ||
        key.startsWith(_appPrefix) ||
        key.startsWith(_privacyPrefix) ||
        key.startsWith(_securityPrefix) ||
        key.startsWith(_dataUsagePrefix) ||
        key == _settingsVersionKey ||
        key == _lastUpdatedKey
      ).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      debugPrint('Settings reset to defaults');
    } catch (e) {
      debugPrint('Error resetting settings: $e');
      throw Exception('Failed to reset settings: $e');
    }
  }
  
  /// Export settings to JSON
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      final settings = await loadSettings();
      
      return {
        'version': _currentSettingsVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'notifications': {
          'notificationsEnabled': settings.notificationSettings.notificationsEnabled,
          'messageNotifications': settings.notificationSettings.messageNotifications,
          'fileNotifications': settings.notificationSettings.fileNotifications,
          'systemNotifications': settings.notificationSettings.systemNotifications,
          'soundEnabled': settings.notificationSettings.soundEnabled,
          'vibrationEnabled': settings.notificationSettings.vibrationEnabled,
          'showPreview': settings.notificationSettings.showPreview,
          'quietHoursEnabled': settings.notificationSettings.quietHoursEnabled,
          'quietHoursStartHour': settings.notificationSettings.quietHoursStartHour,
          'quietHoursStartMinute': settings.notificationSettings.quietHoursStartMinute,
          'quietHoursEndHour': settings.notificationSettings.quietHoursEndHour,
          'quietHoursEndMinute': settings.notificationSettings.quietHoursEndMinute,
        },
        'app': {
          'language': settings.appPreferences.language,
          'theme': settings.appPreferences.theme,
          'darkMode': settings.appPreferences.darkMode,
          'autoSync': settings.appPreferences.autoSync,
          'offlineMode': settings.appPreferences.offlineMode,
          'syncInterval': settings.appPreferences.syncInterval,
        },
        'privacy': {
          'readReceipts': settings.privacySettings.readReceipts,
          'typingIndicators': settings.privacySettings.typingIndicators,
          'lastSeenVisible': settings.privacySettings.lastSeenVisible,
          'profilePhotoVisible': settings.privacySettings.profilePhotoVisible,
          'statusVisible': settings.privacySettings.statusVisible,
          'analyticsEnabled': settings.privacySettings.analyticsEnabled,
          'crashReportsEnabled': settings.privacySettings.crashReportsEnabled,
        },
        'security': {
          'biometricEnabled': settings.securitySettings.biometricEnabled,
          'pinEnabled': settings.securitySettings.pinEnabled,
          'autoLockEnabled': settings.securitySettings.autoLockEnabled,
          'autoLockTimeout': settings.securitySettings.autoLockTimeout,
          'screenCaptureBlocked': settings.securitySettings.screenCaptureBlocked,
        },
        'dataUsage': {
          'wifiOnlyDownloads': settings.dataUsageSettings.wifiOnlyDownloads,
          'autoDownloadImages': settings.dataUsageSettings.autoDownloadImages,
          'autoDownloadVideos': settings.dataUsageSettings.autoDownloadVideos,
          'autoDownloadDocuments': settings.dataUsageSettings.autoDownloadDocuments,
          'maxFileSize': settings.dataUsageSettings.maxFileSize,
          'compressImages': settings.dataUsageSettings.compressImages,
          'lowDataMode': settings.dataUsageSettings.lowDataMode,
        },
      };
    } catch (e) {
      debugPrint('Error exporting settings: $e');
      throw Exception('Failed to export settings: $e');
    }
  }
  
  /// Import settings from JSON
  Future<SettingsLoaded> importSettings(Map<String, dynamic> data) async {
    try {
      // Validate import data
      if (!data.containsKey('version') || !data.containsKey('notifications')) {
        throw Exception('Invalid settings data format');
      }
      
      final notifications = data['notifications'] as Map<String, dynamic>;
      final app = data['app'] as Map<String, dynamic>? ?? {};
      final privacy = data['privacy'] as Map<String, dynamic>? ?? {};
      final security = data['security'] as Map<String, dynamic>? ?? {};
      final dataUsage = data['dataUsage'] as Map<String, dynamic>? ?? {};
      
      final notificationSettings = NotificationSettings(
        notificationsEnabled: notifications['notificationsEnabled'] ?? true,
        messageNotifications: notifications['messageNotifications'] ?? true,
        fileNotifications: notifications['fileNotifications'] ?? true,
        systemNotifications: notifications['systemNotifications'] ?? true,
        soundEnabled: notifications['soundEnabled'] ?? true,
        vibrationEnabled: notifications['vibrationEnabled'] ?? true,
        showPreview: notifications['showPreview'] ?? true,
        quietHoursEnabled: notifications['quietHoursEnabled'] ?? false,
        quietHoursStartHour: notifications['quietHoursStartHour'] ?? 22,
        quietHoursStartMinute: notifications['quietHoursStartMinute'] ?? 0,
        quietHoursEndHour: notifications['quietHoursEndHour'] ?? 8,
        quietHoursEndMinute: notifications['quietHoursEndMinute'] ?? 0,
      );
      
      final appPreferences = AppPreferences(
        language: app['language'] ?? 'nl',
        theme: app['theme'] ?? 'system',
        darkMode: app['darkMode'] ?? false,
        autoSync: app['autoSync'] ?? true,
        offlineMode: app['offlineMode'] ?? false,
        syncInterval: app['syncInterval'] ?? 300,
      );
      
      final privacySettings = PrivacySettings(
        readReceipts: privacy['readReceipts'] ?? true,
        typingIndicators: privacy['typingIndicators'] ?? true,
        lastSeenVisible: privacy['lastSeenVisible'] ?? true,
        profilePhotoVisible: privacy['profilePhotoVisible'] ?? true,
        statusVisible: privacy['statusVisible'] ?? true,
        analyticsEnabled: privacy['analyticsEnabled'] ?? true,
        crashReportsEnabled: privacy['crashReportsEnabled'] ?? true,
      );
      
      final securitySettings = SecuritySettings(
        biometricEnabled: security['biometricEnabled'] ?? false,
        pinEnabled: security['pinEnabled'] ?? false,
        autoLockEnabled: security['autoLockEnabled'] ?? false,
        autoLockTimeout: security['autoLockTimeout'] ?? 300,
        screenCaptureBlocked: security['screenCaptureBlocked'] ?? false,
      );
      
      final dataUsageSettings = DataUsageSettings(
        wifiOnlyDownloads: dataUsage['wifiOnlyDownloads'] ?? false,
        autoDownloadImages: dataUsage['autoDownloadImages'] ?? true,
        autoDownloadVideos: dataUsage['autoDownloadVideos'] ?? false,
        autoDownloadDocuments: dataUsage['autoDownloadDocuments'] ?? true,
        maxFileSize: dataUsage['maxFileSize'] ?? 10485760,
        compressImages: dataUsage['compressImages'] ?? true,
        lowDataMode: dataUsage['lowDataMode'] ?? false,
      );
      
      final importedSettings = SettingsLoaded(
        notificationSettings: notificationSettings,
        appPreferences: appPreferences,
        privacySettings: privacySettings,
        securitySettings: securitySettings,
        dataUsageSettings: dataUsageSettings,
        lastUpdated: DateTime.now(),
      );
      
      // Save imported settings
      await saveSettings(importedSettings);
      
      return importedSettings;
    } catch (e) {
      debugPrint('Error importing settings: $e');
      throw Exception('Failed to import settings: $e');
    }
  }
  
  /// Load notification settings
  Future<NotificationSettings> _loadNotificationSettings(SharedPreferences prefs) async {
    return NotificationSettings(
      notificationsEnabled: prefs.getBool('${_notificationPrefix}enabled') ?? true,
      messageNotifications: prefs.getBool('${_notificationPrefix}message') ?? true,
      fileNotifications: prefs.getBool('${_notificationPrefix}file') ?? true,
      systemNotifications: prefs.getBool('${_notificationPrefix}system') ?? true,
      soundEnabled: prefs.getBool('${_notificationPrefix}sound') ?? true,
      vibrationEnabled: prefs.getBool('${_notificationPrefix}vibration') ?? true,
      showPreview: prefs.getBool('${_notificationPrefix}preview') ?? true,
      quietHoursEnabled: prefs.getBool('${_notificationPrefix}quiet_hours') ?? false,
      quietHoursStartHour: prefs.getInt('${_notificationPrefix}quiet_start_hour') ?? 22,
      quietHoursStartMinute: prefs.getInt('${_notificationPrefix}quiet_start_minute') ?? 0,
      quietHoursEndHour: prefs.getInt('${_notificationPrefix}quiet_end_hour') ?? 8,
      quietHoursEndMinute: prefs.getInt('${_notificationPrefix}quiet_end_minute') ?? 0,
    );
  }
  
  /// Save notification settings
  Future<void> _saveNotificationSettings(SharedPreferences prefs, NotificationSettings settings) async {
    await prefs.setBool('${_notificationPrefix}enabled', settings.notificationsEnabled);
    await prefs.setBool('${_notificationPrefix}message', settings.messageNotifications);
    await prefs.setBool('${_notificationPrefix}file', settings.fileNotifications);
    await prefs.setBool('${_notificationPrefix}system', settings.systemNotifications);
    await prefs.setBool('${_notificationPrefix}sound', settings.soundEnabled);
    await prefs.setBool('${_notificationPrefix}vibration', settings.vibrationEnabled);
    await prefs.setBool('${_notificationPrefix}preview', settings.showPreview);
    await prefs.setBool('${_notificationPrefix}quiet_hours', settings.quietHoursEnabled);
    await prefs.setInt('${_notificationPrefix}quiet_start_hour', settings.quietHoursStartHour);
    await prefs.setInt('${_notificationPrefix}quiet_start_minute', settings.quietHoursStartMinute);
    await prefs.setInt('${_notificationPrefix}quiet_end_hour', settings.quietHoursEndHour);
    await prefs.setInt('${_notificationPrefix}quiet_end_minute', settings.quietHoursEndMinute);
  }
  
  /// Load app preferences
  Future<AppPreferences> _loadAppPreferences(SharedPreferences prefs) async {
    return AppPreferences(
      language: prefs.getString('${_appPrefix}language') ?? 'nl',
      theme: prefs.getString('${_appPrefix}theme') ?? 'system',
      darkMode: prefs.getBool('${_appPrefix}dark_mode') ?? false,
      autoSync: prefs.getBool('${_appPrefix}auto_sync') ?? true,
      offlineMode: prefs.getBool('${_appPrefix}offline_mode') ?? false,
      syncInterval: prefs.getInt('${_appPrefix}sync_interval') ?? 300,
    );
  }
  
  /// Save app preferences
  Future<void> _saveAppPreferences(SharedPreferences prefs, AppPreferences settings) async {
    await prefs.setString('${_appPrefix}language', settings.language);
    await prefs.setString('${_appPrefix}theme', settings.theme);
    await prefs.setBool('${_appPrefix}dark_mode', settings.darkMode);
    await prefs.setBool('${_appPrefix}auto_sync', settings.autoSync);
    await prefs.setBool('${_appPrefix}offline_mode', settings.offlineMode);
    await prefs.setInt('${_appPrefix}sync_interval', settings.syncInterval);
  }
  
  /// Load privacy settings
  Future<PrivacySettings> _loadPrivacySettings(SharedPreferences prefs) async {
    return PrivacySettings(
      readReceipts: prefs.getBool('${_privacyPrefix}read_receipts') ?? true,
      typingIndicators: prefs.getBool('${_privacyPrefix}typing_indicators') ?? true,
      lastSeenVisible: prefs.getBool('${_privacyPrefix}last_seen') ?? true,
      profilePhotoVisible: prefs.getBool('${_privacyPrefix}profile_photo') ?? true,
      statusVisible: prefs.getBool('${_privacyPrefix}status') ?? true,
      analyticsEnabled: prefs.getBool('${_privacyPrefix}analytics') ?? true,
      crashReportsEnabled: prefs.getBool('${_privacyPrefix}crash_reports') ?? true,
    );
  }
  
  /// Save privacy settings
  Future<void> _savePrivacySettings(SharedPreferences prefs, PrivacySettings settings) async {
    await prefs.setBool('${_privacyPrefix}read_receipts', settings.readReceipts);
    await prefs.setBool('${_privacyPrefix}typing_indicators', settings.typingIndicators);
    await prefs.setBool('${_privacyPrefix}last_seen', settings.lastSeenVisible);
    await prefs.setBool('${_privacyPrefix}profile_photo', settings.profilePhotoVisible);
    await prefs.setBool('${_privacyPrefix}status', settings.statusVisible);
    await prefs.setBool('${_privacyPrefix}analytics', settings.analyticsEnabled);
    await prefs.setBool('${_privacyPrefix}crash_reports', settings.crashReportsEnabled);
  }
  
  /// Load security settings
  Future<SecuritySettings> _loadSecuritySettings(SharedPreferences prefs) async {
    return SecuritySettings(
      biometricEnabled: prefs.getBool('${_securityPrefix}biometric') ?? false,
      pinEnabled: prefs.getBool('${_securityPrefix}pin') ?? false,
      pinCode: prefs.getString('${_securityPrefix}pin_code'),
      autoLockEnabled: prefs.getBool('${_securityPrefix}auto_lock') ?? false,
      autoLockTimeout: prefs.getInt('${_securityPrefix}auto_lock_timeout') ?? 300,
      screenCaptureBlocked: prefs.getBool('${_securityPrefix}screen_capture_blocked') ?? false,
    );
  }
  
  /// Save security settings
  Future<void> _saveSecuritySettings(SharedPreferences prefs, SecuritySettings settings) async {
    await prefs.setBool('${_securityPrefix}biometric', settings.biometricEnabled);
    await prefs.setBool('${_securityPrefix}pin', settings.pinEnabled);
    if (settings.pinCode != null) {
      await prefs.setString('${_securityPrefix}pin_code', settings.pinCode!);
    }
    await prefs.setBool('${_securityPrefix}auto_lock', settings.autoLockEnabled);
    await prefs.setInt('${_securityPrefix}auto_lock_timeout', settings.autoLockTimeout);
    await prefs.setBool('${_securityPrefix}screen_capture_blocked', settings.screenCaptureBlocked);
  }
  
  /// Load data usage settings
  Future<DataUsageSettings> _loadDataUsageSettings(SharedPreferences prefs) async {
    return DataUsageSettings(
      wifiOnlyDownloads: prefs.getBool('${_dataUsagePrefix}wifi_only') ?? false,
      autoDownloadImages: prefs.getBool('${_dataUsagePrefix}auto_images') ?? true,
      autoDownloadVideos: prefs.getBool('${_dataUsagePrefix}auto_videos') ?? false,
      autoDownloadDocuments: prefs.getBool('${_dataUsagePrefix}auto_documents') ?? true,
      maxFileSize: prefs.getInt('${_dataUsagePrefix}max_file_size') ?? 10485760,
      compressImages: prefs.getBool('${_dataUsagePrefix}compress_images') ?? true,
      lowDataMode: prefs.getBool('${_dataUsagePrefix}low_data_mode') ?? false,
    );
  }
  
  /// Save data usage settings
  Future<void> _saveDataUsageSettings(SharedPreferences prefs, DataUsageSettings settings) async {
    await prefs.setBool('${_dataUsagePrefix}wifi_only', settings.wifiOnlyDownloads);
    await prefs.setBool('${_dataUsagePrefix}auto_images', settings.autoDownloadImages);
    await prefs.setBool('${_dataUsagePrefix}auto_videos', settings.autoDownloadVideos);
    await prefs.setBool('${_dataUsagePrefix}auto_documents', settings.autoDownloadDocuments);
    await prefs.setInt('${_dataUsagePrefix}max_file_size', settings.maxFileSize);
    await prefs.setBool('${_dataUsagePrefix}compress_images', settings.compressImages);
    await prefs.setBool('${_dataUsagePrefix}low_data_mode', settings.lowDataMode);
  }
  
  /// Migrate settings from older versions
  Future<void> _migrateSettings(SharedPreferences prefs, int fromVersion) async {
    debugPrint('Migrating settings from version $fromVersion to $_currentSettingsVersion');
    
    if (fromVersion == 0) {
      // Migrate from legacy notification settings
      final legacyKeys = [
        'notifications_enabled',
        'message_notifications',
        'file_notifications',
        'system_notifications',
        'sound_enabled',
        'vibration_enabled',
        'show_preview',
        'quiet_hours_enabled',
        'quiet_hours_start_hour',
        'quiet_hours_start_minute',
        'quiet_hours_end_hour',
        'quiet_hours_end_minute',
      ];
      
      for (final key in legacyKeys) {
        final value = prefs.get(key);
        if (value != null) {
          final newKey = '$_notificationPrefix${key.replaceAll('notifications_', '').replaceAll('quiet_hours_', 'quiet_')}';
          if (value is bool) {
            await prefs.setBool(newKey, value);
          } else if (value is int) {
            await prefs.setInt(newKey, value);
          }
          await prefs.remove(key);
        }
      }
    }
    
    await prefs.setInt(_settingsVersionKey, _currentSettingsVersion);
    debugPrint('Settings migration completed');
  }
}
