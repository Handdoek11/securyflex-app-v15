import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/location/postcode_models.dart';

/// High-performance location cache service for Dutch postcode operations
/// 
/// Provides persistent caching using SharedPreferences with automatic cleanup,
/// in-memory caching for hot data, and comprehensive cache management.
/// Optimized for Dutch business requirements with 24-hour TTL.
class LocationCache {
  LocationCache._();
  
  static final LocationCache _instance = LocationCache._();
  static LocationCache get instance => _instance;

  // SharedPreferences instance
  static SharedPreferences? _prefs;

  // In-memory cache for hot data (faster access)
  static final Map<String, PostcodeCoordinate> _coordinateMemoryCache = {};
  static final Map<String, TravelDetails> _travelMemoryCache = {};
  static final Map<String, DistanceCalculationResult> _distanceMemoryCache = {};

  // Cache statistics
  static int _totalRequests = 0;
  static int _cacheHits = 0;
  static DateTime _lastCleanup = DateTime.now();

  // Cache keys
  static const String _coordinateCachePrefix = 'postcode_coord_';
  static const String _travelCachePrefix = 'travel_details_';
  static const String _distanceCachePrefix = 'distance_calc_';
  static const String _cacheStatsKey = 'cache_statistics';
  static const String _lastCleanupKey = 'last_cleanup';

  // Cache limits to prevent memory issues
  static const int _maxMemoryCacheSize = 500;
  static const int _maxPersistentCacheSize = 2000;

  /// Initialize the cache service
  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCacheStatistics();
      await _performMaintenanceIfNeeded();
      debugPrint('LocationCache: Initialized successfully');
    } catch (e) {
      debugPrint('LocationCache: Initialization error: $e');
    }
  }

  /// Ensure SharedPreferences is initialized
  static Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // =========================================================================
  // POSTCODE COORDINATE CACHING
  // =========================================================================

  /// Get cached postcode coordinates
  static Future<PostcodeCoordinate?> getPostcodeCoordinates(String postcode) async {
    _totalRequests++;
    
    // Check memory cache first (fastest)
    if (_coordinateMemoryCache.containsKey(postcode)) {
      final cached = _coordinateMemoryCache[postcode]!;
      if (cached.isCacheValid) {
        _cacheHits++;
        return cached;
      } else {
        // Remove expired entry
        _coordinateMemoryCache.remove(postcode);
      }
    }

    // Check persistent cache
    await _ensureInitialized();
    final cacheKey = _coordinateCachePrefix + postcode;
    final cachedJson = _prefs!.getString(cacheKey);
    
    if (cachedJson != null) {
      try {
        final data = json.decode(cachedJson) as Map<String, dynamic>;
        final coordinate = PostcodeCoordinate.fromJson(data);
        
        if (coordinate.isCacheValid) {
          // Add back to memory cache
          _coordinateMemoryCache[postcode] = coordinate;
          _cacheHits++;
          return coordinate;
        } else {
          // Remove expired persistent entry
          await _prefs!.remove(cacheKey);
        }
      } catch (e) {
        debugPrint('LocationCache: Error parsing cached coordinate for $postcode: $e');
        await _prefs!.remove(cacheKey);
      }
    }

    return null;
  }

  /// Cache postcode coordinates
  static Future<void> setPostcodeCoordinates(PostcodeCoordinate coordinate) async {
    try {
      // Add to memory cache
      _coordinateMemoryCache[coordinate.postcode] = coordinate.copyWith(
        cachedAt: DateTime.now(),
        source: coordinate.source ?? 'cache',
      );

      // Limit memory cache size
      if (_coordinateMemoryCache.length > _maxMemoryCacheSize) {
        await _cleanupMemoryCache();
      }

      // Add to persistent cache
      await _ensureInitialized();
      final cacheKey = _coordinateCachePrefix + coordinate.postcode;
      final cachedCoordinate = coordinate.copyWith(
        cachedAt: DateTime.now(),
      );
      await _prefs!.setString(cacheKey, json.encode(cachedCoordinate.toJson()));

      // Check persistent cache size periodically
      if (_totalRequests % 50 == 0) {
        await _cleanupPersistentCacheIfNeeded();
      }
    } catch (e) {
      debugPrint('LocationCache: Error caching coordinate for ${coordinate.postcode}: $e');
    }
  }

  // =========================================================================
  // TRAVEL DETAILS CACHING
  // =========================================================================

  /// Get cached travel details
  static Future<TravelDetails?> getTravelDetails(
    String fromPostcode,
    String toPostcode,
    TransportMode mode,
  ) async {
    _totalRequests++;
    final cacheKey = '${fromPostcode}_${toPostcode}_${mode.apiValue}';
    
    // Check memory cache
    if (_travelMemoryCache.containsKey(cacheKey)) {
      final cached = _travelMemoryCache[cacheKey]!;
      if (cached.isCacheValid) {
        _cacheHits++;
        return cached;
      } else {
        _travelMemoryCache.remove(cacheKey);
      }
    }

    // Check persistent cache
    await _ensureInitialized();
    final persistentKey = _travelCachePrefix + cacheKey;
    final cachedJson = _prefs!.getString(persistentKey);
    
    if (cachedJson != null) {
      try {
        final data = json.decode(cachedJson) as Map<String, dynamic>;
        final travelDetails = TravelDetails.fromJson(data);
        
        if (travelDetails.isCacheValid) {
          _travelMemoryCache[cacheKey] = travelDetails;
          _cacheHits++;
          return travelDetails;
        } else {
          await _prefs!.remove(persistentKey);
        }
      } catch (e) {
        debugPrint('LocationCache: Error parsing cached travel details: $e');
        await _prefs!.remove(persistentKey);
      }
    }

    return null;
  }

  /// Cache travel details
  static Future<void> setTravelDetails(TravelDetails travelDetails) async {
    try {
      final cacheKey = '${travelDetails.fromPostcode}_${travelDetails.toPostcode}_${travelDetails.mode.apiValue}';
      
      // Add to memory cache
      _travelMemoryCache[cacheKey] = travelDetails;

      // Limit memory cache size
      if (_travelMemoryCache.length > _maxMemoryCacheSize) {
        await _cleanupMemoryCache();
      }

      // Add to persistent cache
      await _ensureInitialized();
      final persistentKey = _travelCachePrefix + cacheKey;
      await _prefs!.setString(persistentKey, json.encode(travelDetails.toJson()));
    } catch (e) {
      debugPrint('LocationCache: Error caching travel details: $e');
    }
  }

  // =========================================================================
  // DISTANCE CALCULATION CACHING
  // =========================================================================

  /// Get cached distance calculation result
  static Future<DistanceCalculationResult?> getDistanceCalculation(
    String fromPostcode,
    String toPostcode,
  ) async {
    _totalRequests++;
    final cacheKey = '${fromPostcode}_$toPostcode';
    
    // Check memory cache
    if (_distanceMemoryCache.containsKey(cacheKey)) {
      final cached = _distanceMemoryCache[cacheKey]!;
      // Check if any travel option is still valid
      final hasValidOptions = cached.travelOptions.values.any((travel) => travel.isCacheValid);
      if (hasValidOptions) {
        _cacheHits++;
        return cached;
      } else {
        _distanceMemoryCache.remove(cacheKey);
      }
    }

    // Check persistent cache
    await _ensureInitialized();
    final persistentKey = _distanceCachePrefix + cacheKey;
    final cachedJson = _prefs!.getString(persistentKey);
    
    if (cachedJson != null) {
      try {
        final data = json.decode(cachedJson) as Map<String, dynamic>;
        
        // Reconstruct travel options
        final travelOptionsJson = data['travelOptions'] as Map<String, dynamic>;
        final travelOptions = <TransportMode, TravelDetails>{};
        
        for (final entry in travelOptionsJson.entries) {
          final mode = TransportMode.values.firstWhere((m) => m.apiValue == entry.key);
          final travelDetails = TravelDetails.fromJson(entry.value as Map<String, dynamic>);
          if (travelDetails.isCacheValid) {
            travelOptions[mode] = travelDetails;
          }
        }
        
        if (travelOptions.isNotEmpty) {
          final result = DistanceCalculationResult(
            fromPostcode: data['fromPostcode'] as String,
            toPostcode: data['toPostcode'] as String,
            travelOptions: travelOptions,
            calculatedAt: DateTime.fromMillisecondsSinceEpoch(data['calculatedAt'] as int),
            fromCache: true,
          );
          
          _distanceMemoryCache[cacheKey] = result;
          _cacheHits++;
          return result;
        } else {
          await _prefs!.remove(persistentKey);
        }
      } catch (e) {
        debugPrint('LocationCache: Error parsing cached distance calculation: $e');
        await _prefs!.remove(persistentKey);
      }
    }

    return null;
  }

  /// Cache distance calculation result
  static Future<void> setDistanceCalculation(DistanceCalculationResult result) async {
    try {
      final cacheKey = '${result.fromPostcode}_${result.toPostcode}';
      
      // Add to memory cache
      _distanceMemoryCache[cacheKey] = result;

      // Add to persistent cache
      await _ensureInitialized();
      final persistentKey = _distanceCachePrefix + cacheKey;
      
      // Serialize travel options
      final travelOptionsJson = <String, dynamic>{};
      for (final entry in result.travelOptions.entries) {
        travelOptionsJson[entry.key.apiValue] = entry.value.toJson();
      }
      
      final dataToCache = {
        'fromPostcode': result.fromPostcode,
        'toPostcode': result.toPostcode,
        'travelOptions': travelOptionsJson,
        'calculatedAt': result.calculatedAt.millisecondsSinceEpoch,
      };
      
      await _prefs!.setString(persistentKey, json.encode(dataToCache));
    } catch (e) {
      debugPrint('LocationCache: Error caching distance calculation: $e');
    }
  }

  // =========================================================================
  // CACHE MANAGEMENT
  // =========================================================================

  /// Get cache statistics
  static Future<CacheStatistics> getCacheStatistics() async {
    await _ensureInitialized();
    
    // Count cache entries
    final keys = _prefs!.getKeys();
    final coordinateKeys = keys.where((k) => k.startsWith(_coordinateCachePrefix)).length;
    final travelKeys = keys.where((k) => k.startsWith(_travelCachePrefix)).length;
    final distanceKeys = keys.where((k) => k.startsWith(_distanceCachePrefix)).length;
    final totalPersistent = coordinateKeys + travelKeys + distanceKeys;
    
    // Count memory cache
    final totalMemory = _coordinateMemoryCache.length + _travelMemoryCache.length + _distanceMemoryCache.length;
    
    final hitRatio = _totalRequests > 0 ? (_cacheHits / _totalRequests) * 100 : 0.0;
    
    return CacheStatistics(
      totalEntries: totalPersistent + totalMemory,
      validEntries: totalMemory, // Memory cache only contains valid entries
      expiredEntries: 0, // Expired entries are cleaned up automatically
      hitRatio: hitRatio,
      totalRequests: _totalRequests,
      cacheHits: _cacheHits,
      lastCleanup: _lastCleanup,
    );
  }

  /// Clear all cache data
  static Future<void> clearCache() async {
    try {
      // Clear memory caches
      _coordinateMemoryCache.clear();
      _travelMemoryCache.clear();
      _distanceMemoryCache.clear();
      
      // Clear persistent cache
      await _ensureInitialized();
      final keys = _prefs!.getKeys().where((key) => 
        key.startsWith(_coordinateCachePrefix) ||
        key.startsWith(_travelCachePrefix) ||
        key.startsWith(_distanceCachePrefix)
      ).toList();
      
      for (final key in keys) {
        await _prefs!.remove(key);
      }
      
      // Reset statistics
      _totalRequests = 0;
      _cacheHits = 0;
      _lastCleanup = DateTime.now();
      
      await _saveCacheStatistics();
      
      debugPrint('LocationCache: All cache data cleared');
    } catch (e) {
      debugPrint('LocationCache: Error clearing cache: $e');
    }
  }

  /// Perform cache cleanup - remove expired entries
  static Future<void> cleanupExpiredEntries() async {
    try {
      await _ensureInitialized();
      int removedCount = 0;
      
      // Cleanup persistent cache
      final keys = _prefs!.getKeys().where((key) => 
        key.startsWith(_coordinateCachePrefix) ||
        key.startsWith(_travelCachePrefix) ||
        key.startsWith(_distanceCachePrefix)
      ).toList();
      
      for (final key in keys) {
        final cachedJson = _prefs!.getString(key);
        if (cachedJson != null) {
          try {
            final data = json.decode(cachedJson) as Map<String, dynamic>;
            final cachedAt = data['cachedAt'] != null 
                ? DateTime.fromMillisecondsSinceEpoch(data['cachedAt'] as int)
                : null;
            
            if (cachedAt != null) {
              final hoursDifference = DateTime.now().difference(cachedAt).inHours;
              if (hoursDifference >= 24) {
                await _prefs!.remove(key);
                removedCount++;
              }
            }
          } catch (e) {
            // Remove corrupted cache entries
            await _prefs!.remove(key);
            removedCount++;
          }
        }
      }
      
      // Cleanup memory caches
      _coordinateMemoryCache.removeWhere((key, value) => !value.isCacheValid);
      _travelMemoryCache.removeWhere((key, value) => !value.isCacheValid);
      _distanceMemoryCache.removeWhere((key, value) => 
        !value.travelOptions.values.any((travel) => travel.isCacheValid)
      );
      
      _lastCleanup = DateTime.now();
      await _saveCacheStatistics();
      
      debugPrint('LocationCache: Cleanup completed, removed $removedCount expired entries');
    } catch (e) {
      debugPrint('LocationCache: Error during cache cleanup: $e');
    }
  }

  /// Preload common postcode routes for better performance
  static Future<void> preloadCommonRoutes(List<String> commonPostcodes) async {
    debugPrint('LocationCache: Preloading ${commonPostcodes.length} common postcodes');
    // This method can be extended to preload frequently used routes
    // For now, it's a placeholder for future implementation
  }

  // =========================================================================
  // PRIVATE HELPER METHODS
  // =========================================================================

  /// Cleanup memory caches when they get too large
  static Future<void> _cleanupMemoryCache() async {
    try {
      // Remove oldest entries to stay under limit
      final targetSize = (_maxMemoryCacheSize * 0.8).round();
      
      while (_coordinateMemoryCache.length > targetSize) {
        final oldestKey = _coordinateMemoryCache.keys.first;
        _coordinateMemoryCache.remove(oldestKey);
      }
      
      while (_travelMemoryCache.length > targetSize) {
        final oldestKey = _travelMemoryCache.keys.first;
        _travelMemoryCache.remove(oldestKey);
      }
      
      while (_distanceMemoryCache.length > targetSize) {
        final oldestKey = _distanceMemoryCache.keys.first;
        _distanceMemoryCache.remove(oldestKey);
      }
    } catch (e) {
      debugPrint('LocationCache: Error cleaning up memory cache: $e');
    }
  }

  /// Cleanup persistent cache if it gets too large
  static Future<void> _cleanupPersistentCacheIfNeeded() async {
    try {
      await _ensureInitialized();
      final keys = _prefs!.getKeys().where((key) => 
        key.startsWith(_coordinateCachePrefix) ||
        key.startsWith(_travelCachePrefix) ||
        key.startsWith(_distanceCachePrefix)
      ).toList();
      
      if (keys.length > _maxPersistentCacheSize) {
        // Remove oldest entries first (rough cleanup)
        final keysToRemove = keys.take(keys.length - (_maxPersistentCacheSize ~/ 2));
        for (final key in keysToRemove) {
          await _prefs!.remove(key);
        }
        debugPrint('LocationCache: Cleaned up ${keysToRemove.length} persistent cache entries');
      }
    } catch (e) {
      debugPrint('LocationCache: Error cleaning up persistent cache: $e');
    }
  }

  /// Load cache statistics from storage
  static Future<void> _loadCacheStatistics() async {
    try {
      await _ensureInitialized();
      final statsJson = _prefs!.getString(_cacheStatsKey);
      if (statsJson != null) {
        final stats = json.decode(statsJson) as Map<String, dynamic>;
        _totalRequests = stats['totalRequests'] as int? ?? 0;
        _cacheHits = stats['cacheHits'] as int? ?? 0;
      }
      
      final lastCleanupMs = _prefs!.getInt(_lastCleanupKey);
      if (lastCleanupMs != null) {
        _lastCleanup = DateTime.fromMillisecondsSinceEpoch(lastCleanupMs);
      }
    } catch (e) {
      debugPrint('LocationCache: Error loading cache statistics: $e');
    }
  }

  /// Save cache statistics to storage
  static Future<void> _saveCacheStatistics() async {
    try {
      await _ensureInitialized();
      await _prefs!.setString(_cacheStatsKey, json.encode({
        'totalRequests': _totalRequests,
        'cacheHits': _cacheHits,
      }));
      await _prefs!.setInt(_lastCleanupKey, _lastCleanup.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('LocationCache: Error saving cache statistics: $e');
    }
  }

  /// Perform maintenance if needed (daily cleanup)
  static Future<void> _performMaintenanceIfNeeded() async {
    final now = DateTime.now();
    final hoursSinceCleanup = now.difference(_lastCleanup).inHours;
    
    if (hoursSinceCleanup >= 24) {
      await cleanupExpiredEntries();
    }
  }
}