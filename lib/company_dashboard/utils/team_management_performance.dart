import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance optimization utilities for Team Management features
/// Provides caching, debouncing, and memory management for optimal performance
class TeamManagementPerformance {
  static final TeamManagementPerformance _instance = TeamManagementPerformance._internal();
  factory TeamManagementPerformance() => _instance;
  TeamManagementPerformance._internal();

  // Performance monitoring
  final Map<String, Stopwatch> _performanceTimers = {};
  final Map<String, List<int>> _performanceHistory = {};
  
  // Caching system
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Timer> _cacheExpiryTimers = {};
  
  // Debouncing system
  final Map<String, Timer> _debounceTimers = {};
  
  // Memory management
  final Map<String, StreamSubscription> _activeSubscriptions = {};
  
  // Performance thresholds (in milliseconds)
  static const int _warningThreshold = 100;
  static const int _errorThreshold = 300;
  static const int _defaultCacheExpiry = 30000; // 30 seconds
  static const int _maxCacheSize = 100;

  /// Start performance monitoring for an operation
  void startTimer(String operationName) {
    _performanceTimers[operationName] = Stopwatch()..start();
  }

  /// Stop performance monitoring and log results
  void stopTimer(String operationName) {
    final timer = _performanceTimers[operationName];
    if (timer != null) {
      timer.stop();
      final elapsedMs = timer.elapsedMilliseconds;
      
      // Record performance history
      _performanceHistory.putIfAbsent(operationName, () => []);
      _performanceHistory[operationName]!.add(elapsedMs);
      
      // Keep only last 10 measurements
      if (_performanceHistory[operationName]!.length > 10) {
        _performanceHistory[operationName]!.removeAt(0);
      }
      
      // Log performance warnings
      if (kDebugMode) {
        if (elapsedMs > _errorThreshold) {
          debugPrint('⚠️ PERFORMANCE ERROR: $operationName took ${elapsedMs}ms (>${_errorThreshold}ms)');
        } else if (elapsedMs > _warningThreshold) {
          debugPrint('⚠️ PERFORMANCE WARNING: $operationName took ${elapsedMs}ms (>${_warningThreshold}ms)');
        } else {
          debugPrint('✅ PERFORMANCE OK: $operationName took ${elapsedMs}ms');
        }
      }
      
      _performanceTimers.remove(operationName);
    }
  }

  /// Get average performance for an operation
  double getAveragePerformance(String operationName) {
    final history = _performanceHistory[operationName];
    if (history == null || history.isEmpty) return 0.0;
    
    return history.reduce((a, b) => a + b) / history.length;
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    for (final entry in _performanceHistory.entries) {
      final operationName = entry.key;
      final measurements = entry.value;
      
      if (measurements.isNotEmpty) {
        final average = measurements.reduce((a, b) => a + b) / measurements.length;
        final min = measurements.reduce(math.min);
        final max = measurements.reduce(math.max);
        
        stats[operationName] = {
          'average': average.round(),
          'min': min,
          'max': max,
          'count': measurements.length,
          'status': average > _errorThreshold ? 'error' : 
                   average > _warningThreshold ? 'warning' : 'ok',
        };
      }
    }
    
    return stats;
  }

  /// Cache data with automatic expiry
  void cacheData(String key, dynamic data, {int? expiryMs}) {
    // Clean cache if it's getting too large
    if (_cache.length >= _maxCacheSize) {
      _cleanOldestCacheEntries();
    }
    
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    
    // Set up expiry timer
    _cacheExpiryTimers[key]?.cancel();
    _cacheExpiryTimers[key] = Timer(
      Duration(milliseconds: expiryMs ?? _defaultCacheExpiry),
      () => _expireCache(key),
    );
    
    if (kDebugMode) {
      print('📦 CACHE SET: $key (expires in ${expiryMs ?? _defaultCacheExpiry}ms)');
    }
  }

  /// Get cached data
  T? getCachedData<T>(String key) {
    final data = _cache[key];
    if (data != null) {
      if (kDebugMode) {
        final age = DateTime.now().difference(_cacheTimestamps[key]!).inMilliseconds;
        print('📦 CACHE HIT: $key (age: ${age}ms)');
      }
      return data as T?;
    }
    
    if (kDebugMode) {
      print('📦 CACHE MISS: $key');
    }
    return null;
  }

  /// Check if cache contains key and is not expired
  bool hasCachedData(String key) {
    return _cache.containsKey(key);
  }

  /// Clear specific cache entry
  void clearCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    _cacheExpiryTimers[key]?.cancel();
    _cacheExpiryTimers.remove(key);
    
    if (kDebugMode) {
      print('📦 CACHE CLEARED: $key');
    }
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    
    for (final timer in _cacheExpiryTimers.values) {
      timer.cancel();
    }
    _cacheExpiryTimers.clear();
    
    if (kDebugMode) {
      print('📦 ALL CACHE CLEARED');
    }
  }

  /// Expire cache entry
  void _expireCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    _cacheExpiryTimers.remove(key);
    
    if (kDebugMode) {
      print('📦 CACHE EXPIRED: $key');
    }
  }

  /// Clean oldest cache entries when cache is full
  void _cleanOldestCacheEntries() {
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    // Remove oldest 20% of entries
    final entriesToRemove = (sortedEntries.length * 0.2).ceil();
    for (int i = 0; i < entriesToRemove; i++) {
      final key = sortedEntries[i].key;
      clearCache(key);
    }
    
    if (kDebugMode) {
      print('📦 CACHE CLEANUP: Removed $entriesToRemove old entries');
    }
  }

  /// Debounce function calls
  void debounce(String key, VoidCallback callback, {int delayMs = 300}) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(Duration(milliseconds: delayMs), callback);
  }

  /// Cancel debounced function
  void cancelDebounce(String key) {
    _debounceTimers[key]?.cancel();
    _debounceTimers.remove(key);
  }

  /// Register a stream subscription for automatic cleanup
  void registerSubscription(String key, StreamSubscription subscription) {
    // Cancel existing subscription if any
    _activeSubscriptions[key]?.cancel();
    _activeSubscriptions[key] = subscription;
    
    if (kDebugMode) {
      print('🔄 SUBSCRIPTION REGISTERED: $key');
    }
  }

  /// Cancel and remove a subscription
  void cancelSubscription(String key) {
    _activeSubscriptions[key]?.cancel();
    _activeSubscriptions.remove(key);
    
    if (kDebugMode) {
      print('🔄 SUBSCRIPTION CANCELLED: $key');
    }
  }

  /// Cancel all subscriptions
  void cancelAllSubscriptions() {
    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
    
    if (kDebugMode) {
      print('🔄 ALL SUBSCRIPTIONS CANCELLED');
    }
  }

  /// Optimize widget rebuilds by providing a build optimization wrapper
  static Widget optimizedBuilder({
    required String key,
    required Widget Function() builder,
    Duration cacheDuration = const Duration(seconds: 1),
  }) {
    return _OptimizedBuilder(
      key: ValueKey(key),
      builder: builder,
      cacheDuration: cacheDuration,
    );
  }

  /// Memory usage monitoring
  void logMemoryUsage(String context) {
    if (kDebugMode) {
      // This would require platform-specific implementation
      print('💾 MEMORY CHECK: $context - Cache size: ${_cache.length} entries');
    }
  }

  /// Batch operations for better performance
  Future<List<T>> batchOperation<T>(
    List<Future<T> Function()> operations, {
    int batchSize = 5,
    Duration delay = const Duration(milliseconds: 10),
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize);
      final batchResults = await Future.wait(batch.map((op) => op()));
      results.addAll(batchResults);
      
      // Small delay between batches to prevent overwhelming the system
      if (i + batchSize < operations.length) {
        await Future.delayed(delay);
      }
    }
    
    return results;
  }

  /// Dispose of all resources
  void dispose() {
    // Cancel all timers
    for (final timer in _cacheExpiryTimers.values) {
      timer.cancel();
    }
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    
    // Cancel all subscriptions
    cancelAllSubscriptions();
    
    // Clear all caches
    clearAllCache();
    
    // Clear performance data
    _performanceTimers.clear();
    _performanceHistory.clear();
    
    if (kDebugMode) {
      print('🧹 PERFORMANCE MANAGER DISPOSED');
    }
  }
}

/// Optimized builder widget that caches build results
class _OptimizedBuilder extends StatefulWidget {
  final Widget Function() builder;
  final Duration cacheDuration;

  const _OptimizedBuilder({
    super.key,
    required this.builder,
    required this.cacheDuration,
  });

  @override
  State<_OptimizedBuilder> createState() => _OptimizedBuilderState();
}

class _OptimizedBuilderState extends State<_OptimizedBuilder> {
  Widget? _cachedWidget;
  DateTime? _lastBuild;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    
    if (_cachedWidget == null || 
        _lastBuild == null || 
        now.difference(_lastBuild!).compareTo(widget.cacheDuration) > 0) {
      
      _cachedWidget = widget.builder();
      _lastBuild = now;
      
      if (kDebugMode) {
        print('🔄 OPTIMIZED BUILD: Widget rebuilt');
      }
    }
    
    return _cachedWidget!;
  }
}
