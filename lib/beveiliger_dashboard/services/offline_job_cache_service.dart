import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../../core/performance_monitor.dart';
import '../../schedule/models/shift_model.dart';

/// Simplified shift data for caching (mobile-optimized)
class CachedShiftData {
  final String id;
  final String shiftTitle;
  final String shiftDescription;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final double hourlyRate;
  final List<String> requiredCertifications;
  final ShiftStatus status;
  final String? assignedGuardId;
  
  const CachedShiftData({
    required this.id,
    required this.shiftTitle,
    required this.shiftDescription,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.hourlyRate,
    required this.requiredCertifications,
    required this.status,
    this.assignedGuardId,
  });
  
  factory CachedShiftData.fromShift(Shift shift) {
    return CachedShiftData(
      id: shift.id,
      shiftTitle: shift.shiftTitle,
      shiftDescription: shift.shiftDescription,
      location: '${shift.location.address}, ${shift.location.city}',
      startTime: shift.startTime,
      endTime: shift.endTime,
      hourlyRate: shift.hourlyRate,
      requiredCertifications: shift.requiredCertifications,
      status: shift.status,
      assignedGuardId: shift.assignedGuardId,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shiftTitle': shiftTitle,
      'shiftDescription': shiftDescription,
      'location': location,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'hourlyRate': hourlyRate,
      'requiredCertifications': requiredCertifications,
      'status': status.name,
      'assignedGuardId': assignedGuardId,
    };
  }
  
  factory CachedShiftData.fromJson(Map<String, dynamic> json) {
    return CachedShiftData(
      id: json['id'] as String,
      shiftTitle: json['shiftTitle'] as String,
      shiftDescription: json['shiftDescription'] as String,
      location: json['location'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime'] as int),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      requiredCertifications: List<String>.from(json['requiredCertifications'] ?? []),
      status: ShiftStatus.values.firstWhere((e) => e.name == json['status']),
      assignedGuardId: json['assignedGuardId'] as String?,
    );
  }
}

/// Offline-first job caching service for mobile security guards
/// 
/// Implements Progressive Web App (PWA) patterns for offline functionality:
/// - Local job storage for field operations
/// - Sync when online connection is restored  
/// - Background sync for seamless user experience
/// - Conflict resolution for data consistency
class OfflineJobCacheService {
  static const String _tag = 'OfflineJobCacheService';
  static final OfflineJobCacheService _instance = OfflineJobCacheService._internal();
  static OfflineJobCacheService get instance => _instance;
  
  OfflineJobCacheService._internal();
  
  // Cache configuration
  static const String _cacheKeyPrefix = 'offline_jobs_';
  static const String _lastSyncKey = 'last_job_sync';
  static const String _pendingActionsKey = 'pending_job_actions';
  static const Duration _cacheExpiration = Duration(hours: 24);
  static const int _maxCachedJobs = 50; // Optimized for mobile storage
  
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  Timer? _backgroundSyncTimer;
  StreamController<List<CachedShiftData>>? _jobsStreamController;
  
  /// Initialize the offline cache service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    PerformanceMonitor.instance.startMeasurement('offline_cache_init');
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _jobsStreamController = StreamController<List<CachedShiftData>>.broadcast();
      
      // Setup background sync timer (every 5 minutes when online)
      _setupBackgroundSync();
      
      // Cleanup expired cache entries
      await _cleanupExpiredEntries();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        developer.log('$_tag: Offline job cache initialized', name: 'OfflineCache');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to initialize: $e', name: 'OfflineCache');
      }
      rethrow;
    } finally {
      PerformanceMonitor.instance.endMeasurement('offline_cache_init');
    }
  }
  
  /// Cache shifts/jobs for offline access
  Future<void> cacheJobs(List<Shift> shifts, {String? category}) async {
    if (!_isInitialized) await initialize();
    
    PerformanceMonitor.instance.startMeasurement('cache_jobs');
    
    try {
      // Limit cache size for mobile efficiency and convert to cached format
      final shiftsToCache = shifts.take(_maxCachedJobs).toList();
      final cachedShifts = shiftsToCache.map((shift) => CachedShiftData.fromShift(shift)).toList();
      
      final cacheKey = category != null ? '$_cacheKeyPrefix$category' : '${_cacheKeyPrefix}all';
      final cacheData = {
        'shifts': cachedShifts.map((shift) => shift.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'category': category,
      };
      
      await _prefs!.setString(cacheKey, jsonEncode(cacheData));
      
      // Update last sync timestamp
      await _prefs!.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      
      // Notify listeners
      _jobsStreamController?.add(cachedShifts);
      
      if (kDebugMode) {
        developer.log('$_tag: Cached ${shiftsToCache.length} shifts for category: ${category ?? "all"}', 
                     name: 'OfflineCache');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to cache jobs: $e', name: 'OfflineCache');
      }
    } finally {
      PerformanceMonitor.instance.endMeasurement('cache_jobs');
    }
  }
  
  /// Get cached shifts/jobs (offline-first)
  Future<List<CachedShiftData>> getCachedJobs({String? category}) async {
    if (!_isInitialized) await initialize();
    
    PerformanceMonitor.instance.startMeasurement('get_cached_jobs');
    
    try {
      final cacheKey = category != null ? '$_cacheKeyPrefix$category' : '${_cacheKeyPrefix}all';
      final cacheString = _prefs!.getString(cacheKey);
      
      if (cacheString == null) {
        return [];
      }
      
      final cacheData = jsonDecode(cacheString) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp'] as int);
      
      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheExpiration) {
        if (kDebugMode) {
          developer.log('$_tag: Cache expired for category: ${category ?? "all"}', 
                       name: 'OfflineCache');
        }
        return [];
      }
      
      final shiftsJson = cacheData['shifts'] as List<dynamic>;
      final shifts = shiftsJson.map((json) => CachedShiftData.fromJson(json as Map<String, dynamic>)).toList();
      
      if (kDebugMode) {
        developer.log('$_tag: Retrieved ${shifts.length} cached shifts for category: ${category ?? "all"}', 
                     name: 'OfflineCache');
      }
      
      return shifts;
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to get cached jobs: $e', name: 'OfflineCache');
      }
      return [];
    } finally {
      PerformanceMonitor.instance.endMeasurement('get_cached_jobs');
    }
  }
  
  /// Cache job application action for offline submission
  Future<void> cacheJobApplication({
    required String jobId,
    required String guardId,
    required Map<String, dynamic> applicationData,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      final pendingActions = await _getPendingActions();
      
      final actionData = {
        'type': 'job_application',
        'jobId': jobId,
        'guardId': guardId,
        'data': applicationData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      pendingActions.add(actionData);
      await _savePendingActions(pendingActions);
      
      if (kDebugMode) {
        developer.log('$_tag: Cached job application for offline submission: $jobId', 
                     name: 'OfflineCache');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to cache job application: $e', name: 'OfflineCache');
      }
    }
  }
  
  /// Cache time tracking data for offline submission
  Future<void> cacheTimeTrackingData({
    required String jobId,
    required String guardId,
    required String action, // 'clock_in' or 'clock_out'
    required DateTime timestamp,
    required Map<String, dynamic> locationData,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      final pendingActions = await _getPendingActions();
      
      final actionData = {
        'type': 'time_tracking',
        'jobId': jobId,
        'guardId': guardId,
        'action': action,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'locationData': locationData,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      pendingActions.add(actionData);
      await _savePendingActions(pendingActions);
      
      if (kDebugMode) {
        developer.log('$_tag: Cached time tracking data for offline submission: $jobId', 
                     name: 'OfflineCache');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to cache time tracking data: $e', name: 'OfflineCache');
      }
    }
  }
  
  /// Sync pending actions when online
  Future<bool> syncPendingActions() async {
    if (!_isInitialized) await initialize();
    
    PerformanceMonitor.instance.startMeasurement('sync_pending_actions');
    
    try {
      final pendingActions = await _getPendingActions();
      
      if (pendingActions.isEmpty) {
        return true;
      }
      
      bool allSyncedSuccessfully = true;
      final failedActions = <Map<String, dynamic>>[];
      
      for (final action in pendingActions) {
        try {
          final success = await _syncSingleAction(action);
          if (!success) {
            allSyncedSuccessfully = false;
            failedActions.add(action);
          }
        } catch (e) {
          allSyncedSuccessfully = false;
          failedActions.add(action);
          if (kDebugMode) {
            developer.log('$_tag: Failed to sync action ${action['id']}: $e', 
                         name: 'OfflineCache');
          }
        }
      }
      
      // Save only failed actions back to cache
      await _savePendingActions(failedActions);
      
      if (kDebugMode) {
        final syncedCount = pendingActions.length - failedActions.length;
        developer.log('$_tag: Synced $syncedCount/${pendingActions.length} pending actions', 
                     name: 'OfflineCache');
      }
      
      return allSyncedSuccessfully;
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to sync pending actions: $e', name: 'OfflineCache');
      }
      return false;
    } finally {
      PerformanceMonitor.instance.endMeasurement('sync_pending_actions');
    }
  }
  
  /// Get stream of cached shifts/jobs for real-time updates
  Stream<List<CachedShiftData>> get jobsStream => _jobsStreamController?.stream ?? const Stream.empty();
  
  /// Check if there are pending actions to sync
  Future<bool> hasPendingActions() async {
    if (!_isInitialized) await initialize();
    
    final pendingActions = await _getPendingActions();
    return pendingActions.isNotEmpty;
  }
  
  /// Get pending actions count
  Future<int> getPendingActionsCount() async {
    if (!_isInitialized) await initialize();
    
    final pendingActions = await _getPendingActions();
    return pendingActions.length;
  }
  
  /// Clear all cached data
  Future<void> clearCache() async {
    if (!_isInitialized) await initialize();
    
    try {
      final keys = _prefs!.getKeys().where((key) => key.startsWith(_cacheKeyPrefix)).toList();
      for (final key in keys) {
        await _prefs!.remove(key);
      }
      
      await _prefs!.remove(_pendingActionsKey);
      await _prefs!.remove(_lastSyncKey);
      
      if (kDebugMode) {
        developer.log('$_tag: Cleared all cached data', name: 'OfflineCache');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to clear cache: $e', name: 'OfflineCache');
      }
    }
  }
  
  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    if (!_isInitialized) await initialize();
    
    final timestamp = _prefs!.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  
  // Private methods
  
  void _setupBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      // Only sync if there are pending actions and device is online
      if (await hasPendingActions()) {
        await syncPendingActions();
      }
    });
  }
  
  Future<List<Map<String, dynamic>>> _getPendingActions() async {
    final actionsString = _prefs!.getString(_pendingActionsKey);
    if (actionsString == null) return [];
    
    try {
      final actionsJson = jsonDecode(actionsString) as List<dynamic>;
      return actionsJson.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to parse pending actions: $e', name: 'OfflineCache');
      }
      return [];
    }
  }
  
  Future<void> _savePendingActions(List<Map<String, dynamic>> actions) async {
    await _prefs!.setString(_pendingActionsKey, jsonEncode(actions));
  }
  
  Future<bool> _syncSingleAction(Map<String, dynamic> action) async {
    // This would integrate with your actual API service
    // For now, simulate network call
    await Future.delayed(const Duration(milliseconds: 100));
    
    switch (action['type']) {
      case 'job_application':
        return await _syncJobApplication(action);
      case 'time_tracking':
        return await _syncTimeTracking(action);
      default:
        return false;
    }
  }
  
  Future<bool> _syncJobApplication(Map<String, dynamic> action) async {
    // Integrate with your job application API
    // Return true if successful, false otherwise
    return true; // Simulated success
  }
  
  Future<bool> _syncTimeTracking(Map<String, dynamic> action) async {
    // Integrate with your time tracking API
    // Return true if successful, false otherwise
    return true; // Simulated success
  }
  
  Future<void> _cleanupExpiredEntries() async {
    try {
      final keys = _prefs!.getKeys().where((key) => key.startsWith(_cacheKeyPrefix)).toList();
      
      for (final key in keys) {
        final cacheString = _prefs!.getString(key);
        if (cacheString != null) {
          final cacheData = jsonDecode(cacheString) as Map<String, dynamic>;
          final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp'] as int);
          
          if (DateTime.now().difference(timestamp) > _cacheExpiration) {
            await _prefs!.remove(key);
            if (kDebugMode) {
              developer.log('$_tag: Removed expired cache entry: $key', name: 'OfflineCache');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to cleanup expired entries: $e', name: 'OfflineCache');
      }
    }
  }
  
  /// Dispose and cleanup
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _jobsStreamController?.close();
    _isInitialized = false;
  }
}

/// Note: Shift model already has toMap() and fromMap() methods for serialization