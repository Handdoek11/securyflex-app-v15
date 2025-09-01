import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../unified_components/smart_badge_overlay.dart';

/// Notification Badge Service
/// Manages badge states, real-time updates, and persistence across app sessions
/// Integrates with existing notification systems for time-sensitive security work
/// Provides centralized badge management for all tabs and components
class NotificationBadgeService {
  static final NotificationBadgeService _instance = NotificationBadgeService._internal();
  factory NotificationBadgeService() => _instance;
  NotificationBadgeService._internal();

  static NotificationBadgeService get instance => _instance;

  // Badge state management
  final Map<String, BadgeData> _badges = {};
  final StreamController<Map<String, BadgeData>> _badgeController = 
      StreamController<Map<String, BadgeData>>.broadcast();

  // Persistence
  static const String _badgeStorageKey = 'notification_badges';
  SharedPreferences? _prefs;

  // Getters
  Stream<Map<String, BadgeData>> get badgeStream => _badgeController.stream;
  Map<String, BadgeData> get currentBadges => Map.unmodifiable(_badges);

  /// Initialize the badge service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPersistedBadges();
      debugPrint('NotificationBadgeService initialized');
    } catch (e) {
      debugPrint('Error initializing NotificationBadgeService: $e');
    }
  }

  /// Update badge for a specific identifier
  Future<void> updateBadge({
    required String identifier,
    required int count,
    BadgeType type = BadgeType.info,
    String? customMessage,
    DateTime? lastUpdated,
  }) async {
    final badgeData = BadgeData(
      identifier: identifier,
      count: count,
      type: type,
      customMessage: customMessage,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );

    _badges[identifier] = badgeData;
    _badgeController.add(Map.from(_badges));
    
    await _persistBadges();
    
    debugPrint('Updated badge for $identifier: count=$count, type=$type');
  }

  /// Clear badge for a specific identifier
  Future<void> clearBadge(String identifier) async {
    _badges.remove(identifier);
    _badgeController.add(Map.from(_badges));
    
    await _persistBadges();
    
    debugPrint('Cleared badge for $identifier');
  }

  /// Clear all badges
  Future<void> clearAllBadges() async {
    _badges.clear();
    _badgeController.add(Map.from(_badges));
    
    await _persistBadges();
    
    debugPrint('Cleared all badges');
  }

  /// Get badge data for a specific identifier
  BadgeData? getBadge(String identifier) {
    return _badges[identifier];
  }

  /// Get badge count for a specific identifier
  int getBadgeCount(String identifier) {
    return _badges[identifier]?.count ?? 0;
  }

  /// Get total badge count across all identifiers
  int getTotalBadgeCount() {
    return _badges.values.fold(0, (sum, badge) => sum + badge.count);
  }

  /// Update job-related badges
  Future<void> updateJobBadges({
    int newApplications = 0,
    int applicationUpdates = 0,
    int newJobs = 0,
  }) async {
    if (newApplications > 0) {
      await updateBadge(
        identifier: BadgeIdentifiers.newApplications,
        count: newApplications,
        type: BadgeType.info,
        customMessage: 'Nieuwe sollicitaties beschikbaar',
      );
    }

    if (applicationUpdates > 0) {
      await updateBadge(
        identifier: BadgeIdentifiers.applicationUpdates,
        count: applicationUpdates,
        type: BadgeType.success,
        customMessage: 'Status updates voor sollicitaties',
      );
    }

    if (newJobs > 0) {
      await updateBadge(
        identifier: BadgeIdentifiers.newJobs,
        count: newJobs,
        type: BadgeType.info,
        customMessage: 'Nieuwe jobs beschikbaar',
      );
    }
  }

  /// Update planning-related badges
  Future<void> updatePlanningBadges({
    int upcomingShifts = 0,
    int scheduleConflicts = 0,
    int shiftChanges = 0,
  }) async {
    if (upcomingShifts > 0) {
      await updateBadge(
        identifier: BadgeIdentifiers.upcomingShifts,
        count: upcomingShifts,
        type: BadgeType.warning,
        customMessage: 'Aankomende diensten binnen 2 uur',
      );
    }

    if (scheduleConflicts > 0) {
      await updateBadge(
        identifier: BadgeIdentifiers.scheduleConflicts,
        count: scheduleConflicts,
        type: BadgeType.urgent,
        customMessage: 'Rooster conflicten gedetecteerd',
      );
    }

    if (shiftChanges > 0) {
      await updateBadge(
        identifier: BadgeIdentifiers.shiftChanges,
        count: shiftChanges,
        type: BadgeType.warning,
        customMessage: 'Wijzigingen in je rooster',
      );
    }
  }

  /// Update timesheet-related badges
  Future<void> updateTimesheetBadges({
    int pendingApprovals = 0,
    int missedClockOuts = 0,
  }) async {
    if (pendingApprovals > 0) {
      await updateBadge(
        identifier: BadgeIdentifiers.pendingApprovals,
        count: pendingApprovals,
        type: BadgeType.info,
        customMessage: 'Urenstaten wachten op goedkeuring',
      );
    }

    if (missedClockOuts > 0) {
      await updateBadge(
        identifier: BadgeIdentifiers.missedClockOuts,
        count: missedClockOuts,
        type: BadgeType.urgent,
        customMessage: 'Vergeten uit te klokken',
      );
    }
  }

  /// Get combined badge count for a tab
  int getTabBadgeCount(String tabIdentifier) {
    switch (tabIdentifier) {
      case 'jobs':
        return getBadgeCount(BadgeIdentifiers.newApplications) +
               getBadgeCount(BadgeIdentifiers.applicationUpdates) +
               getBadgeCount(BadgeIdentifiers.newJobs);
      
      case 'planning':
        return getBadgeCount(BadgeIdentifiers.upcomingShifts) +
               getBadgeCount(BadgeIdentifiers.scheduleConflicts) +
               getBadgeCount(BadgeIdentifiers.shiftChanges);
      
      case 'timesheet':
        return getBadgeCount(BadgeIdentifiers.pendingApprovals) +
               getBadgeCount(BadgeIdentifiers.missedClockOuts);
      
      default:
        return 0;
    }
  }

  /// Get most urgent badge type for a tab
  BadgeType getTabBadgeType(String tabIdentifier) {
    final badges = <BadgeData>[];
    
    switch (tabIdentifier) {
      case 'jobs':
        badges.addAll([
          getBadge(BadgeIdentifiers.newApplications),
          getBadge(BadgeIdentifiers.applicationUpdates),
          getBadge(BadgeIdentifiers.newJobs),
        ].where((badge) => badge != null).cast<BadgeData>());
        break;
      
      case 'planning':
        badges.addAll([
          getBadge(BadgeIdentifiers.upcomingShifts),
          getBadge(BadgeIdentifiers.scheduleConflicts),
          getBadge(BadgeIdentifiers.shiftChanges),
        ].where((badge) => badge != null).cast<BadgeData>());
        break;
      
      case 'timesheet':
        badges.addAll([
          getBadge(BadgeIdentifiers.pendingApprovals),
          getBadge(BadgeIdentifiers.missedClockOuts),
        ].where((badge) => badge != null).cast<BadgeData>());
        break;
    }

    // Return most urgent type
    if (badges.any((badge) => badge.type == BadgeType.urgent)) {
      return BadgeType.urgent;
    } else if (badges.any((badge) => badge.type == BadgeType.warning)) {
      return BadgeType.warning;
    } else if (badges.any((badge) => badge.type == BadgeType.success)) {
      return BadgeType.success;
    } else {
      return BadgeType.info;
    }
  }

  /// Load persisted badges from storage
  Future<void> _loadPersistedBadges() async {
    try {
      final badgeJson = _prefs?.getString(_badgeStorageKey);
      if (badgeJson != null) {
        final badgeMap = jsonDecode(badgeJson) as Map<String, dynamic>;
        
        for (final entry in badgeMap.entries) {
          final badgeData = BadgeData.fromJson(entry.value);
          
          // Only restore badges that are less than 24 hours old
          if (DateTime.now().difference(badgeData.lastUpdated).inHours < 24) {
            _badges[entry.key] = badgeData;
          }
        }
        
        _badgeController.add(Map.from(_badges));
        debugPrint('Loaded ${_badges.length} persisted badges');
      }
    } catch (e) {
      debugPrint('Error loading persisted badges: $e');
    }
  }

  /// Persist badges to storage
  Future<void> _persistBadges() async {
    try {
      final badgeMap = <String, dynamic>{};
      for (final entry in _badges.entries) {
        badgeMap[entry.key] = entry.value.toJson();
      }
      
      await _prefs?.setString(_badgeStorageKey, jsonEncode(badgeMap));
    } catch (e) {
      debugPrint('Error persisting badges: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _badgeController.close();
  }
}

/// Badge Data Model
class BadgeData {
  final String identifier;
  final int count;
  final BadgeType type;
  final String? customMessage;
  final DateTime lastUpdated;

  const BadgeData({
    required this.identifier,
    required this.count,
    required this.type,
    this.customMessage,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'count': count,
      'type': type.name,
      'customMessage': customMessage,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory BadgeData.fromJson(Map<String, dynamic> json) {
    return BadgeData(
      identifier: json['identifier'] as String,
      count: json['count'] as int,
      type: BadgeType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => BadgeType.info,
      ),
      customMessage: json['customMessage'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  BadgeData copyWith({
    String? identifier,
    int? count,
    BadgeType? type,
    String? customMessage,
    DateTime? lastUpdated,
  }) {
    return BadgeData(
      identifier: identifier ?? this.identifier,
      count: count ?? this.count,
      type: type ?? this.type,
      customMessage: customMessage ?? this.customMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Badge Identifiers Constants
class BadgeIdentifiers {
  // Job-related badges
  static const String newApplications = 'new_applications';
  static const String applicationUpdates = 'application_updates';
  static const String newJobs = 'new_jobs';

  // Planning-related badges
  static const String upcomingShifts = 'upcoming_shifts';
  static const String scheduleConflicts = 'schedule_conflicts';
  static const String shiftChanges = 'shift_changes';

  // Timesheet-related badges
  static const String pendingApprovals = 'pending_approvals';
  static const String missedClockOuts = 'missed_clock_outs';

  // Chat-related badges
  static const String unreadMessages = 'unread_messages';
  static const String urgentMessages = 'urgent_messages';

  // General badges
  static const String systemNotifications = 'system_notifications';
  static const String profileUpdates = 'profile_updates';
}
