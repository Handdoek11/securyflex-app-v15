import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/auth_service.dart';
import '../../company_dashboard/services/analytics_service.dart';
import '../../company_dashboard/models/analytics_data_models.dart';
import '../models/notification_preferences.dart';

/// Comprehensive notification preferences service for SecuryFlex guards
/// 
/// Integrates seamlessly with existing SettingsService patterns while providing
/// guard-specific notification preference management. Uses the same persistence
/// mechanisms as the existing settings system for consistency.
/// 
/// Features:
/// - Integration with existing SettingsRepository for persistence
/// - SharedPreferences storage with Firebase backup
/// - Real-time preference validation and enforcement
/// - Auto-save functionality with debouncing
/// - Analytics tracking for preference changes
/// - Offline-first approach with cloud sync
/// - Migration support for preference schema changes
class NotificationPreferencesService {
  static final NotificationPreferencesService _instance = NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;
  NotificationPreferencesService._internal();

  // Dependencies - using existing services for consistency
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  
  // Service state
  bool _isInitialized = false;
  String? _currentUserId;
  NotificationPreferences? _cachedPreferences;
  DateTime? _lastCacheUpdate;
  Timer? _autoSaveTimer;
  
  // Constants
  static const String _preferencesPrefix = 'guard_notification_';
  static const String _firebaseCollection = 'guard_notification_preferences';
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  static const Duration _autoSaveDelay = Duration(seconds: 2);
  
  /// Initialize service for current authenticated user
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _currentUserId = AuthService.currentUserId;
      if (_currentUserId == null || _currentUserId!.isEmpty) {
        debugPrint('NotificationPreferencesService: No authenticated user found');
        return;
      }

      // Load initial preferences
      await loadPreferences();
      
      _isInitialized = true;
      debugPrint('NotificationPreferencesService initialized for user: $_currentUserId');
      
    } catch (e) {
      debugPrint('Error initializing NotificationPreferencesService: $e');
      rethrow;
    }
  }

  /// Load notification preferences from storage
  /// Uses existing SettingsRepository patterns for consistency
  Future<NotificationPreferences> loadPreferences() async {
    try {
      // Check cache first
      if (_isCacheValid()) {
        return _cachedPreferences!;
      }

      // Load from SharedPreferences first (offline-first approach)
      final prefs = await SharedPreferences.getInstance();
      final localPreferences = await _loadFromSharedPreferences(prefs);
      
      // Update cache
      _cachedPreferences = localPreferences;
      _lastCacheUpdate = DateTime.now();
      
      // Try to sync with Firebase in background (don't block)
      _syncWithFirebaseInBackground();
      
      debugPrint('Notification preferences loaded successfully');
      return localPreferences;
      
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
      
      // Return default preferences on error
      final defaultPreferences = const NotificationPreferences();
      _cachedPreferences = defaultPreferences;
      _lastCacheUpdate = DateTime.now();
      
      return defaultPreferences;
    }
  }

  /// Update notification preferences
  /// Saves locally first, then syncs to Firebase
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      // Validate preferences before saving
      if (!preferences.isValid) {
        throw Exception('Invalid notification preferences');
      }

      // Save to SharedPreferences first
      await _saveToSharedPreferences(preferences);
      
      // Update cache
      _cachedPreferences = preferences;
      _lastCacheUpdate = DateTime.now();
      
      // Sync to Firebase in background
      _syncToFirebaseInBackground(preferences);
      
      // Track analytics
      await _trackPreferenceUpdate(preferences);
      
      debugPrint('Notification preferences updated successfully');
      
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
      rethrow;
    }
  }

  /// Schedule auto-save with debouncing
  /// Prevents excessive saves during rapid preference changes
  void scheduleAutoSave(VoidCallback saveCallback) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      saveCallback();
    });
  }

  /// Check if notification should be sent based on current preferences
  Future<bool> shouldSendNotification(
    NotificationCategory category,
    NotificationDeliveryMethod method, {
    bool isUrgent = false,
  }) async {
    try {
      final preferences = await loadPreferences();
      
      // Check master toggle
      if (!preferences.masterNotificationsEnabled) {
        return false;
      }
      
      // Check quiet hours (unless urgent and allowed)
      if (preferences.isQuietHoursActive) {
        if (!isUrgent || !preferences.quietHoursAllowUrgent) {
          return false;
        }
      }
      
      // Check category-specific preferences
      return preferences.shouldSendNotification(category, method);
      
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      // Default to allowing notifications on error
      return true;
    }
  }

  /// Validate and sanitize preferences before saving
  NotificationPreferences validatePreferences(NotificationPreferences preferences) {
    // Time validation
    int startHour = preferences.quietHoursStartHour.clamp(0, 23);
    int startMinute = preferences.quietHoursStartMinute.clamp(0, 59);
    int endHour = preferences.quietHoursEndHour.clamp(0, 23);
    int endMinute = preferences.quietHoursEndMinute.clamp(0, 59);
    
    // Distance validation
    double maxDistance = preferences.maxDistanceForJobAlerts.clamp(1.0, 200.0);
    
    // Digest hour validation
    int digestHour = preferences.digestHour.clamp(0, 23);
    
    // Return sanitized preferences if needed
    if (startHour != preferences.quietHoursStartHour ||
        startMinute != preferences.quietHoursStartMinute ||
        endHour != preferences.quietHoursEndHour ||
        endMinute != preferences.quietHoursEndMinute ||
        maxDistance != preferences.maxDistanceForJobAlerts ||
        digestHour != preferences.digestHour) {
      
      return preferences.copyWith(
        quietHoursStartHour: startHour,
        quietHoursStartMinute: startMinute,
        quietHoursEndHour: endHour,
        quietHoursEndMinute: endMinute,
        maxDistanceForJobAlerts: maxDistance,
        digestHour: digestHour,
      );
    }
    
    return preferences;
  }

  /// Reset preferences to defaults
  Future<void> resetToDefaults() async {
    try {
      const defaultPreferences = NotificationPreferences();
      await updatePreferences(defaultPreferences);
      
      // Track reset event
      await _analyticsService.trackEvent(
        jobId: 'notification_preferences',
        eventType: JobEventType.completion,
        userId: _currentUserId!,
        metadata: {
          'action': 'reset_to_defaults',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      debugPrint('Notification preferences reset to defaults');
      
    } catch (e) {
      debugPrint('Error resetting notification preferences: $e');
      rethrow;
    }
  }

  /// Export preferences for backup/migration
  Future<Map<String, dynamic>> exportPreferences() async {
    try {
      final preferences = await loadPreferences();
      
      return {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'userId': _currentUserId,
        'preferences': preferences.toMap(),
      };
      
    } catch (e) {
      debugPrint('Error exporting notification preferences: $e');
      rethrow;
    }
  }

  /// Import preferences from backup
  Future<void> importPreferences(Map<String, dynamic> data) async {
    try {
      // Validate import data
      if (!data.containsKey('preferences') || !data.containsKey('version')) {
        throw Exception('Invalid import data format');
      }
      
      final preferencesData = data['preferences'] as Map<String, dynamic>;
      final preferences = NotificationPreferences.fromMap(preferencesData);
      
      // Validate and save
      final validatedPreferences = validatePreferences(preferences);
      await updatePreferences(validatedPreferences);
      
      // Track import event
      await _analyticsService.trackEvent(
        jobId: 'notification_preferences',
        eventType: JobEventType.completion,
        userId: _currentUserId!,
        metadata: {
          'action': 'import_preferences',
          'import_version': data['version'],
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      debugPrint('Notification preferences imported successfully');
      
    } catch (e) {
      debugPrint('Error importing notification preferences: $e');
      rethrow;
    }
  }

  // Private helper methods

  /// Load preferences from SharedPreferences
  Future<NotificationPreferences> _loadFromSharedPreferences(SharedPreferences prefs) async {
    final Map<String, dynamic> preferencesMap = {};
    
    // Load all preference keys
    final keys = prefs.getKeys().where((key) => key.startsWith(_preferencesPrefix));
    
    for (final key in keys) {
      final cleanKey = key.replaceFirst(_preferencesPrefix, '');
      final value = prefs.get(key);
      preferencesMap[cleanKey] = value;
    }
    
    // If no preferences found, return defaults
    if (preferencesMap.isEmpty) {
      return const NotificationPreferences();
    }
    
    return NotificationPreferences.fromMap(preferencesMap);
  }

  /// Save preferences to SharedPreferences
  Future<void> _saveToSharedPreferences(NotificationPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final preferencesMap = preferences.toMap();
    
    // Save all preference values with prefix
    for (final entry in preferencesMap.entries) {
      final key = '$_preferencesPrefix${entry.key}';
      final value = entry.value;
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      }
    }
    
    // Save metadata
    await prefs.setString('${_preferencesPrefix}last_updated', DateTime.now().toIso8601String());
    await prefs.setString('${_preferencesPrefix}user_id', _currentUserId ?? '');
  }

  /// Sync preferences with Firebase in background
  void _syncWithFirebaseInBackground() async {
    if (_currentUserId == null) return;
    
    try {
      final doc = await _firestore
          .collection(_firebaseCollection)
          .doc(_currentUserId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final firebasePreferences = NotificationPreferences.fromMap(data);
        
        // Check if Firebase version is newer
        final localTimestamp = _lastCacheUpdate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final firebaseTimestamp = DateTime.tryParse(data['lastUpdated'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        
        if (firebaseTimestamp.isAfter(localTimestamp)) {
          // Firebase version is newer, update local
          await _saveToSharedPreferences(firebasePreferences);
          _cachedPreferences = firebasePreferences;
          _lastCacheUpdate = DateTime.now();
          
          debugPrint('Synchronized newer preferences from Firebase');
        }
      }
      
    } catch (e) {
      debugPrint('Error syncing with Firebase: $e');
      // Don't throw - this is background sync
    }
  }

  /// Sync preferences to Firebase in background
  void _syncToFirebaseInBackground(NotificationPreferences preferences) async {
    if (_currentUserId == null) return;
    
    try {
      final data = preferences.toMap();
      data['lastUpdated'] = DateTime.now().toIso8601String();
      data['userId'] = _currentUserId!;
      
      await _firestore
          .collection(_firebaseCollection)
          .doc(_currentUserId)
          .set(data, SetOptions(merge: true));
      
      debugPrint('Preferences synced to Firebase');
      
    } catch (e) {
      debugPrint('Error syncing to Firebase: $e');
      // Don't throw - this is background sync
    }
  }

  /// Track preference update in analytics
  Future<void> _trackPreferenceUpdate(NotificationPreferences preferences) async {
    try {
      await _analyticsService.trackEvent(
        jobId: 'notification_preferences',
        eventType: JobEventType.completion,
        userId: _currentUserId!,
        metadata: {
          'action': 'update_preferences',
          'master_enabled': preferences.masterNotificationsEnabled,
          'jobs_enabled': preferences.jobAlertsEnabled,
          'certificates_enabled': preferences.certificateAlertsEnabled,
          'payments_enabled': preferences.paymentAlertsEnabled,
          'system_enabled': preferences.systemAlertsEnabled,
          'quiet_hours_enabled': preferences.quietHoursEnabled,
          'location_based': preferences.locationBasedNotifications,
          'max_distance_km': preferences.maxDistanceForJobAlerts,
          'digest_mode': preferences.digestMode,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
    } catch (e) {
      debugPrint('Error tracking preference update: $e');
      // Don't throw - analytics shouldn't block functionality
    }
  }

  /// Check if cache is valid
  bool _isCacheValid() {
    if (_cachedPreferences == null || _lastCacheUpdate == null) {
      return false;
    }
    
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  /// Clean up resources
  void dispose() {
    _autoSaveTimer?.cancel();
    _cachedPreferences = null;
    _lastCacheUpdate = null;
    _isInitialized = false;
  }

  /// Get current preferences summary for display
  String getPreferencesSummary() {
    if (_cachedPreferences == null) {
      return 'Voorkeuren niet geladen';
    }
    
    return _cachedPreferences!.notificationStatusDescription;
  }

  /// Check if user has any notifications enabled
  bool get hasNotificationsEnabled {
    if (_cachedPreferences == null) return true; // Default to enabled
    
    return _cachedPreferences!.masterNotificationsEnabled &&
           (_cachedPreferences!.jobAlertsEnabled ||
            _cachedPreferences!.certificateAlertsEnabled ||
            _cachedPreferences!.paymentAlertsEnabled ||
            _cachedPreferences!.systemAlertsEnabled);
  }

  /// Get current quiet hours status
  bool get isQuietHoursActive {
    if (_cachedPreferences == null) return false;
    
    return _cachedPreferences!.isQuietHoursActive;
  }

  /// Get notification preferences for external use
  NotificationPreferences? get currentPreferences => _cachedPreferences;
}