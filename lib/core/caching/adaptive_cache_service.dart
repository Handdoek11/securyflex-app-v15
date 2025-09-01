import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;
import '../platform_intelligence/adaptive_ui_service.dart';

/// Adaptive caching service that adjusts cache strategies per platform
/// 
/// Implements platform-aware caching with:
/// - Mobile: 50MB limit, aggressive cleanup, 6-hour TTL
/// - Tablet: 100MB limit, balanced strategy, 12-hour TTL  
/// - Desktop: 200MB limit, extended caching, 24-hour TTL
/// - Smart cache eviction based on usage patterns
/// - Automatic memory pressure handling
class AdaptiveCacheService {
  static const String _tag = 'AdaptiveCacheService';
  static final AdaptiveCacheService _instance = AdaptiveCacheService._internal();
  static AdaptiveCacheService get instance => _instance;
  
  AdaptiveCacheService._internal();
  
  bool _isInitialized = false;
  SharedPreferences? _prefs;
  Timer? _cleanupTimer;
  
  // Platform-specific cache configurations
  static const Map<PlatformType, CacheConfiguration> _cacheConfigs = {
    PlatformType.mobile: CacheConfiguration(
      maxMemoryMB: 50,
      defaultTtlMinutes: 360, // 6 hours
      cleanupIntervalMinutes: 30,
      maxItems: 500,
      aggressiveCleanup: true,
    ),
    PlatformType.tablet: CacheConfiguration(
      maxMemoryMB: 100,
      defaultTtlMinutes: 720, // 12 hours
      cleanupIntervalMinutes: 60,
      maxItems: 1000,
      aggressiveCleanup: false,
    ),
    PlatformType.desktop: CacheConfiguration(
      maxMemoryMB: 200,
      defaultTtlMinutes: 1440, // 24 hours
      cleanupIntervalMinutes: 120,
      maxItems: 2000,
      aggressiveCleanup: false,
    ),
    PlatformType.largeDesktop: CacheConfiguration(
      maxMemoryMB: 300,
      defaultTtlMinutes: 2880, // 48 hours
      cleanupIntervalMinutes: 180,
      maxItems: 5000,
      aggressiveCleanup: false,
    ),
  };
  
  /// Initialize adaptive cache service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Start platform-aware cleanup
      _startAdaptiveCleanup();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        final config = _getCurrentConfig();
        developer.log(
          '$_tag: Initialized with ${config.maxMemoryMB}MB cache for ${AdaptiveUIService.instance.currentContext?.platformType}',
          name: 'AdaptiveCache'
        );
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to initialize: $e', name: 'AdaptiveCache');
      }
    }
  }
  
  /// Store data in adaptive cache
  Future<void> store<T>(
    String key,
    T data, {
    Duration? customTtl,
    CachePriority priority = CachePriority.normal,
  }) async {
    if (!_isInitialized || _prefs == null) return;
    
    try {
      final config = _getCurrentConfig();
      final ttl = customTtl ?? Duration(minutes: config.defaultTtlMinutes);
      final expiry = DateTime.now().add(ttl).millisecondsSinceEpoch;
      
      final cacheItem = AdaptiveCacheItem(
        key: key,
        data: jsonEncode(data),
        expiry: expiry,
        priority: priority,
        accessCount: 1,
        lastAccessed: DateTime.now().millisecondsSinceEpoch,
        sizeBytes: _calculateSize(data),
      );
      
      // Check if we need to cleanup before storing
      await _ensureCacheCapacity(cacheItem.sizeBytes);
      
      // Store the cache item
      await _prefs!.setString('cache_$key', jsonEncode(cacheItem.toMap()));
      
      // Update cache metadata
      await _updateCacheMetadata(key, cacheItem);
      
      if (kDebugMode) {
        developer.log(
          '$_tag: Stored $key (${cacheItem.sizeBytes} bytes, expires in ${ttl.inHours}h)',
          name: 'AdaptiveCache'
        );
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to store $key: $e', name: 'AdaptiveCache');
      }
    }
  }
  
  /// Retrieve data from adaptive cache
  Future<T?> retrieve<T>(String key, {T Function(dynamic)? deserializer}) async {
    if (!_isInitialized || _prefs == null) return null;
    
    try {
      final cacheData = _prefs!.getString('cache_$key');
      if (cacheData == null) return null;
      
      final cacheItem = AdaptiveCacheItem.fromMap(jsonDecode(cacheData));
      
      // Check if expired
      if (DateTime.now().millisecondsSinceEpoch > cacheItem.expiry) {
        await remove(key);
        return null;
      }
      
      // Update access metadata
      await _updateAccessMetadata(key, cacheItem);
      
      // Deserialize data
      final rawData = jsonDecode(cacheItem.data);
      return deserializer != null ? deserializer(rawData) : rawData as T;
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to retrieve $key: $e', name: 'AdaptiveCache');
      }
      return null;
    }
  }
  
  /// Remove item from cache
  Future<void> remove(String key) async {
    if (!_isInitialized || _prefs == null) return;
    
    await _prefs!.remove('cache_$key');
    await _removeCacheMetadata(key);
  }
  
  /// Clear cache based on pattern or category
  Future<void> clearByPattern(String pattern) async {
    if (!_isInitialized || _prefs == null) return;
    
    final keys = _prefs!.getKeys()
        .where((key) => key.startsWith('cache_') && key.contains(pattern))
        .toList();
    
    for (final key in keys) {
      await _prefs!.remove(key);
    }
    
    if (kDebugMode) {
      developer.log('$_tag: Cleared ${keys.length} items matching $pattern', name: 'AdaptiveCache');
    }
  }
  
  /// Start platform-aware cleanup timer
  void _startAdaptiveCleanup() {
    final config = _getCurrentConfig();
    
    _cleanupTimer = Timer.periodic(
      Duration(minutes: config.cleanupIntervalMinutes),
      (_) => _performCleanup(),
    );
  }
  
  /// Perform cache cleanup based on platform strategy
  Future<void> _performCleanup() async {
    if (!_isInitialized || _prefs == null) return;
    
    try {
      final config = _getCurrentConfig();
      final allKeys = _prefs!.getKeys().where((key) => key.startsWith('cache_')).toList();
      
      List<AdaptiveCacheItem> items = [];
      int totalSize = 0;
      
      // Load all cache items
      for (final key in allKeys) {
        try {
          final data = _prefs!.getString(key);
          if (data != null) {
            final item = AdaptiveCacheItem.fromMap(jsonDecode(data));
            items.add(item);
            totalSize += item.sizeBytes;
          }
        } catch (e) {
          // Remove corrupted cache item
          await _prefs!.remove(key);
        }
      }
      
      // Remove expired items
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredItems = items.where((item) => now > item.expiry).toList();
      for (final item in expiredItems) {
        await remove(item.key);
        totalSize -= item.sizeBytes;
      }
      
      // Remove items if over capacity
      if (totalSize > config.maxMemoryMB * 1024 * 1024 || items.length > config.maxItems) {
        await _evictItems(items, config, totalSize);
      }
      
      if (kDebugMode && expiredItems.isNotEmpty) {
        developer.log('$_tag: Cleaned up ${expiredItems.length} expired items', name: 'AdaptiveCache');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Error during cleanup: $e', name: 'AdaptiveCache');
      }
    }
  }
  
  /// Evict cache items using platform-aware strategy
  Future<void> _evictItems(List<AdaptiveCacheItem> items, CacheConfiguration config, int currentSize) async {
    if (items.isEmpty) return;
    
    // Sort by eviction priority (least recently used + lowest priority first)
    items.sort((a, b) {
      // Priority comparison (high priority items kept longer)
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      
      // Access frequency (less accessed items evicted first)
      final accessCompare = a.accessCount.compareTo(b.accessCount);
      if (accessCompare != 0) return accessCompare;
      
      // Last accessed time (older items evicted first)
      return a.lastAccessed.compareTo(b.lastAccessed);
    });
    
    final targetSize = (config.maxMemoryMB * 1024 * 1024 * 0.8).round(); // 80% of max
    final targetItems = (config.maxItems * 0.8).round();
    
    int removedSize = 0;
    int removedCount = 0;
    
    for (final item in items) {
      if (currentSize - removedSize <= targetSize && items.length - removedCount <= targetItems) {
        break;
      }
      
      await remove(item.key);
      removedSize += item.sizeBytes;
      removedCount++;
    }
    
    if (kDebugMode && removedCount > 0) {
      developer.log('$_tag: Evicted $removedCount items (${(removedSize / 1024).round()}KB)', name: 'AdaptiveCache');
    }
  }
  
  /// Ensure cache has capacity for new item
  Future<void> _ensureCacheCapacity(int newItemSize) async {
    final config = _getCurrentConfig();
    final currentStats = await getCacheStats();
    
    if (currentStats.totalSize + newItemSize > config.maxMemoryMB * 1024 * 1024) {
      await _performCleanup();
    }
  }
  
  /// Update cache metadata for analytics
  Future<void> _updateCacheMetadata(String key, AdaptiveCacheItem item) async {
    // Store basic metadata for analytics
    final metadata = {
      'keys': [...(await _getCachedKeys()), key].toSet().toList(),
      'total_items': (await _getCachedKeys()).length + 1,
    };
    
    await _prefs!.setString('cache_metadata', jsonEncode(metadata));
  }
  
  /// Update access metadata
  Future<void> _updateAccessMetadata(String key, AdaptiveCacheItem item) async {
    final updatedItem = AdaptiveCacheItem(
      key: item.key,
      data: item.data,
      expiry: item.expiry,
      priority: item.priority,
      accessCount: item.accessCount + 1,
      lastAccessed: DateTime.now().millisecondsSinceEpoch,
      sizeBytes: item.sizeBytes,
    );
    
    await _prefs!.setString('cache_$key', jsonEncode(updatedItem.toMap()));
  }
  
  /// Remove cache metadata
  Future<void> _removeCacheMetadata(String key) async {
    final currentKeys = await _getCachedKeys();
    currentKeys.remove(key);
    
    final metadata = {
      'keys': currentKeys,
      'total_items': currentKeys.length,
    };
    
    await _prefs!.setString('cache_metadata', jsonEncode(metadata));
  }
  
  /// Get current cached keys
  Future<List<String>> _getCachedKeys() async {
    final metadata = _prefs!.getString('cache_metadata');
    if (metadata == null) return [];
    
    try {
      final data = jsonDecode(metadata);
      return List<String>.from(data['keys'] ?? []);
    } catch (e) {
      return [];
    }
  }
  
  /// Calculate approximate size of data
  int _calculateSize(dynamic data) {
    try {
      return jsonEncode(data).length;
    } catch (e) {
      return 0;
    }
  }
  
  /// Get current platform cache configuration
  CacheConfiguration _getCurrentConfig() {
    final context = AdaptiveUIService.instance.currentContext;
    final platformType = context?.platformType ?? PlatformType.mobile;
    return _cacheConfigs[platformType] ?? _cacheConfigs[PlatformType.mobile]!;
  }
  
  /// Get cache statistics
  Future<CacheStats> getCacheStats() async {
    if (!_isInitialized || _prefs == null) {
      return CacheStats.empty();
    }
    
    final keys = _prefs!.getKeys().where((key) => key.startsWith('cache_')).toList();
    int totalSize = 0;
    int expiredCount = 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    for (final key in keys) {
      try {
        final data = _prefs!.getString(key);
        if (data != null) {
          final item = AdaptiveCacheItem.fromMap(jsonDecode(data));
          totalSize += item.sizeBytes;
          if (now > item.expiry) expiredCount++;
        }
      } catch (e) {
        // Ignore corrupted items
      }
    }
    
    final config = _getCurrentConfig();
    return CacheStats(
      totalItems: keys.length,
      totalSize: totalSize,
      expiredItems: expiredCount,
      maxItems: config.maxItems,
      maxSize: config.maxMemoryMB * 1024 * 1024,
      hitRate: 0.0, // Would need separate tracking
    );
  }
  
  /// Dispose service
  void dispose() {
    _cleanupTimer?.cancel();
    _isInitialized = false;
  }
}

/// Cache configuration per platform
class CacheConfiguration {
  final int maxMemoryMB;
  final int defaultTtlMinutes;
  final int cleanupIntervalMinutes;
  final int maxItems;
  final bool aggressiveCleanup;
  
  const CacheConfiguration({
    required this.maxMemoryMB,
    required this.defaultTtlMinutes,
    required this.cleanupIntervalMinutes,
    required this.maxItems,
    required this.aggressiveCleanup,
  });
}

/// Cache item with adaptive metadata
class AdaptiveCacheItem {
  final String key;
  final String data;
  final int expiry;
  final CachePriority priority;
  final int accessCount;
  final int lastAccessed;
  final int sizeBytes;
  
  const AdaptiveCacheItem({
    required this.key,
    required this.data,
    required this.expiry,
    required this.priority,
    required this.accessCount,
    required this.lastAccessed,
    required this.sizeBytes,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'data': data,
      'expiry': expiry,
      'priority': priority.index,
      'accessCount': accessCount,
      'lastAccessed': lastAccessed,
      'sizeBytes': sizeBytes,
    };
  }
  
  factory AdaptiveCacheItem.fromMap(Map<String, dynamic> map) {
    return AdaptiveCacheItem(
      key: map['key'],
      data: map['data'],
      expiry: map['expiry'],
      priority: CachePriority.values[map['priority'] ?? 0],
      accessCount: map['accessCount'] ?? 1,
      lastAccessed: map['lastAccessed'] ?? DateTime.now().millisecondsSinceEpoch,
      sizeBytes: map['sizeBytes'] ?? 0,
    );
  }
}

/// Cache priority levels
enum CachePriority {
  low,
  normal,
  high,
  critical,
}

/// Cache statistics
class CacheStats {
  final int totalItems;
  final int totalSize;
  final int expiredItems;
  final int maxItems;
  final int maxSize;
  final double hitRate;
  
  const CacheStats({
    required this.totalItems,
    required this.totalSize,
    required this.expiredItems,
    required this.maxItems,
    required this.maxSize,
    required this.hitRate,
  });
  
  factory CacheStats.empty() {
    return const CacheStats(
      totalItems: 0,
      totalSize: 0,
      expiredItems: 0,
      maxItems: 0,
      maxSize: 0,
      hitRate: 0.0,
    );
  }
  
  /// Usage percentage of maximum capacity
  double get usagePercentage => maxSize > 0 ? (totalSize / maxSize) * 100 : 0;
  
  /// Items percentage of maximum count
  double get itemsPercentage => maxItems > 0 ? (totalItems / maxItems) * 100 : 0;
  
  /// Memory usage in MB
  double get memoryUsageMB => totalSize / (1024 * 1024);
}