import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'adaptive_cache_service.dart';
import '../platform_intelligence/adaptive_ui_service.dart';

/// Platform-aware cache manager that provides high-level caching operations
/// 
/// Adapts caching strategies based on platform characteristics:
/// - Mobile: Aggressive memory management, shorter TTL
/// - Desktop: Extended caching for productivity, longer TTL
/// - Smart prefetching based on user patterns
/// - Category-based cache organization
class PlatformCacheManager {
  static const String _tag = 'PlatformCacheManager';
  static final PlatformCacheManager _instance = PlatformCacheManager._internal();
  static PlatformCacheManager get instance => _instance;
  
  PlatformCacheManager._internal();
  
  bool _isInitialized = false;
  Timer? _prefetchTimer;
  final Map<String, int> _accessPatterns = {};
  
  /// Initialize platform cache manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize adaptive cache service
      await AdaptiveCacheService.instance.initialize();
      
      // Start intelligent prefetching
      _startIntelligentPrefetch();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        developer.log('$_tag: Platform cache manager initialized', name: 'PlatformCache');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to initialize: $e', name: 'PlatformCache');
      }
    }
  }
  
  /// Cache generic shift data with platform optimization
  Future<void> cacheShiftData(List<Map<String, dynamic>> shiftData, {String category = 'general'}) async {
    if (!_isInitialized) return;
    
    try {
      final context = AdaptiveUIService.instance.currentContext;
      final platformType = context?.platformType ?? PlatformType.mobile;
      
      // Determine cache priority and TTL based on platform
      final priority = _getShiftCachePriority(platformType, category);
      final ttl = _getShiftCacheTtl(platformType, category);
      
      // Desktop: Cache individual shifts for granular access
      if (platformType == PlatformType.desktop || platformType == PlatformType.largeDesktop) {
        for (final shift in shiftData) {
          await AdaptiveCacheService.instance.store(
            'shift_${shift['id']}',
            shift,
            customTtl: ttl,
            priority: priority,
          );
        }
      }
      
      // Cache shift list for bulk operations
      await AdaptiveCacheService.instance.store(
        'shifts_$category',
        shiftData,
        customTtl: ttl,
        priority: priority,
      );
      
      _trackAccess('shifts_$category');
      
      if (kDebugMode) {
        developer.log(
          '$_tag: Cached ${shiftData.length} shifts for $category (TTL: ${ttl.inHours}h)',
          name: 'PlatformCache'
        );
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to cache shift data: $e', name: 'PlatformCache');
      }
    }
  }
  
  /// Retrieve cached shift data
  Future<List<Map<String, dynamic>>?> getCachedShiftData(String category) async {
    if (!_isInitialized) return null;
    
    try {
      final shiftsData = await AdaptiveCacheService.instance.retrieve<List<dynamic>>(
        'shifts_$category',
      );
      
      if (shiftsData == null) return null;
      
      _trackAccess('shifts_$category');
      
      return List<Map<String, dynamic>>.from(shiftsData);
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to retrieve shift data: $e', name: 'PlatformCache');
      }
      return null;
    }
  }
  
  /// Cache generic job data with platform optimization
  Future<void> cacheJobData(List<Map<String, dynamic>> jobData, {String category = 'available'}) async {
    if (!_isInitialized) return;
    
    try {
      final context = AdaptiveUIService.instance.currentContext;
      final platformType = context?.platformType ?? PlatformType.mobile;
      
      final priority = _getJobCachePriority(platformType, category);
      final ttl = _getJobCacheTtl(platformType, category);
      
      // Desktop: Cache individual jobs with extended metadata
      if (platformType == PlatformType.desktop || platformType == PlatformType.largeDesktop) {
        // Cache individual jobs with extended metadata
        for (final job in jobData) {
          await AdaptiveCacheService.instance.store(
            'job_${job['id']}',
            job,
            customTtl: ttl,
            priority: priority,
          );
        }
      }
      
      // Cache job list
      await AdaptiveCacheService.instance.store(
        'jobs_$category',
        jobData,
        customTtl: ttl,
        priority: priority,
      );
      
      _trackAccess('jobs_$category');
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to cache job data: $e', name: 'PlatformCache');
      }
    }
  }
  
  /// Retrieve cached job data
  Future<List<Map<String, dynamic>>?> getCachedJobData(String category) async {
    if (!_isInitialized) return null;
    
    try {
      final jobsData = await AdaptiveCacheService.instance.retrieve<List<dynamic>>(
        'jobs_$category',
      );
      
      if (jobsData == null) return null;
      
      _trackAccess('jobs_$category');
      
      return List<Map<String, dynamic>>.from(jobsData);
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to retrieve job data: $e', name: 'PlatformCache');
      }
      return null;
    }
  }
  
  /// Cache user profile data with high priority
  Future<void> cacheUserProfile(String userId, Map<String, dynamic> profileData) async {
    if (!_isInitialized) return;
    
    await AdaptiveCacheService.instance.store(
      'profile_$userId',
      profileData,
      priority: CachePriority.high,
      customTtl: const Duration(hours: 6), // Profiles change less frequently
    );
    
    _trackAccess('profile_$userId');
  }
  
  /// Retrieve cached user profile
  Future<Map<String, dynamic>?> getCachedUserProfile(String userId) async {
    if (!_isInitialized) return null;
    
    _trackAccess('profile_$userId');
    
    return await AdaptiveCacheService.instance.retrieve<Map<String, dynamic>>(
      'profile_$userId',
    );
  }
  
  /// Cache analytics data for desktop users
  Future<void> cacheAnalyticsData(String dataType, Map<String, dynamic> analyticsData) async {
    if (!_isInitialized) return;
    
    final context = AdaptiveUIService.instance.currentContext;
    final platformType = context?.platformType ?? PlatformType.mobile;
    
    // Only cache analytics for desktop platforms
    if (platformType != PlatformType.desktop && platformType != PlatformType.largeDesktop) {
      return;
    }
    
    await AdaptiveCacheService.instance.store(
      'analytics_$dataType',
      analyticsData,
      priority: CachePriority.normal,
      customTtl: const Duration(minutes: 30), // Analytics change frequently
    );
    
    _trackAccess('analytics_$dataType');
  }
  
  /// Get cached analytics data
  Future<Map<String, dynamic>?> getCachedAnalyticsData(String dataType) async {
    if (!_isInitialized) return null;
    
    _trackAccess('analytics_$dataType');
    
    return await AdaptiveCacheService.instance.retrieve<Map<String, dynamic>>(
      'analytics_$dataType',
    );
  }
  
  /// Clear platform-specific caches
  Future<void> clearPlatformCache(PlatformType platformType) async {
    if (!_isInitialized) return;
    
    switch (platformType) {
      case PlatformType.mobile:
        await AdaptiveCacheService.instance.clearByPattern('analytics_');
        break;
      case PlatformType.desktop:
      case PlatformType.largeDesktop:
        // Keep desktop analytics but clear mobile-specific data
        break;
      case PlatformType.tablet:
        // Balanced approach
        break;
    }
  }
  
  /// Start intelligent prefetching based on usage patterns
  void _startIntelligentPrefetch() {
    final context = AdaptiveUIService.instance.currentContext;
    final platformType = context?.platformType ?? PlatformType.mobile;
    
    // Only enable aggressive prefetching on desktop
    if (platformType != PlatformType.desktop && platformType != PlatformType.largeDesktop) {
      return;
    }
    
    _prefetchTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performIntelligentPrefetch();
    });
  }
  
  /// Perform intelligent prefetch based on access patterns
  Future<void> _performIntelligentPrefetch() async {
    if (!_isInitialized) return;
    
    try {
      // Find most accessed categories
      final sortedPatterns = _accessPatterns.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Prefetch top 3 categories
      for (int i = 0; i < 3 && i < sortedPatterns.length; i++) {
        final category = sortedPatterns[i].key;
        
        if (category.startsWith('shifts_')) {
          // Could trigger background refresh of shifts
          if (kDebugMode) {
            developer.log('$_tag: Would prefetch $category', name: 'PlatformCache');
          }
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Error in intelligent prefetch: $e', name: 'PlatformCache');
      }
    }
  }
  
  /// Track access patterns for intelligent caching
  void _trackAccess(String key) {
    _accessPatterns[key] = (_accessPatterns[key] ?? 0) + 1;
  }
  
  /// Get cache priority for shifts based on platform and category
  CachePriority _getShiftCachePriority(PlatformType platformType, String category) {
    if (category == 'active' || category == 'today') {
      return CachePriority.high;
    }
    
    switch (platformType) {
      case PlatformType.mobile:
        return CachePriority.normal;
      case PlatformType.desktop:
      case PlatformType.largeDesktop:
        return CachePriority.normal;
      default:
        return CachePriority.normal;
    }
  }
  
  /// Get cache TTL for shifts based on platform and category
  Duration _getShiftCacheTtl(PlatformType platformType, String category) {
    if (category == 'active') {
      return const Duration(minutes: 15); // Active shifts change quickly
    }
    
    switch (platformType) {
      case PlatformType.mobile:
        return const Duration(hours: 2);
      case PlatformType.desktop:
      case PlatformType.largeDesktop:
        return const Duration(hours: 8);
      default:
        return const Duration(hours: 4);
    }
  }
  
  /// Get cache priority for jobs
  CachePriority _getJobCachePriority(PlatformType platformType, String category) {
    if (category == 'favorites' || category == 'applied') {
      return CachePriority.high;
    }
    
    return CachePriority.normal;
  }
  
  /// Get cache TTL for jobs
  Duration _getJobCacheTtl(PlatformType platformType, String category) {
    if (category == 'available') {
      return const Duration(hours: 1); // Available jobs change frequently
    }
    
    switch (platformType) {
      case PlatformType.mobile:
        return const Duration(hours: 4);
      case PlatformType.desktop:
      case PlatformType.largeDesktop:
        return const Duration(hours: 12);
      default:
        return const Duration(hours: 6);
    }
  }
  
  /// Get cache statistics
  Future<Map<String, dynamic>> getStatistics() async {
    if (!_isInitialized) return {};
    
    final cacheStats = await AdaptiveCacheService.instance.getCacheStats();
    final context = AdaptiveUIService.instance.currentContext;
    
    return {
      'platform': context?.platformType.name ?? 'unknown',
      'total_items': cacheStats.totalItems,
      'memory_usage_mb': cacheStats.memoryUsageMB,
      'usage_percentage': cacheStats.usagePercentage,
      'expired_items': cacheStats.expiredItems,
      'access_patterns': _accessPatterns,
      'is_desktop': context?.platformType == PlatformType.desktop || 
                   context?.platformType == PlatformType.largeDesktop,
    };
  }
  
  /// Dispose cache manager
  void dispose() {
    _prefetchTimer?.cancel();
    AdaptiveCacheService.instance.dispose();
    _isInitialized = false;
  }
}

/// Cache categories for organization
class CacheCategories {
  static const String shiftsActive = 'active';
  static const String shiftsToday = 'today';
  static const String shiftsUpcoming = 'upcoming';
  static const String shiftsPast = 'past';
  
  static const String jobsAvailable = 'available';
  static const String jobsFavorites = 'favorites';
  static const String jobsApplied = 'applied';
  static const String jobsRecommended = 'recommended';
  
  static const String analyticsOverview = 'overview';
  static const String analyticsPerformance = 'performance';
  static const String analyticsTeam = 'team';
}