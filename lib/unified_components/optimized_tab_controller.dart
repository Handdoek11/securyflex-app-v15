import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:securyflex_app/unified_design_tokens.dart';

/// Optimized Tab Controller for Production Use
/// Provides lazy loading, performance monitoring, and memory optimization
/// Implements caching strategies and reduced rebuild frequencies
class OptimizedTabController extends StatefulWidget {
  const OptimizedTabController({
    super.key,
    required this.tabs,
    required this.tabBuilder,
    this.initialIndex = 0,
    this.animationController,
    this.enableLazyLoading = true,
    this.enablePerformanceMonitoring = kDebugMode,
    this.cacheExtent = 1,
    this.preloadDistance = 1,
    this.onTabChanged,
    this.onPerformanceMetric,
  });

  final List<OptimizedTab> tabs;
  final Widget Function(BuildContext context, int index, OptimizedTab tab) tabBuilder;
  final int initialIndex;
  final AnimationController? animationController;
  final bool enableLazyLoading;
  final bool enablePerformanceMonitoring;
  final int cacheExtent; // Number of tabs to keep in memory
  final int preloadDistance; // Distance to preload tabs
  final ValueChanged<int>? onTabChanged;
  final ValueChanged<PerformanceMetric>? onPerformanceMetric;

  @override
  State<OptimizedTabController> createState() => _OptimizedTabControllerState();
}

class _OptimizedTabControllerState extends State<OptimizedTabController>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late PerformanceMonitor _performanceMonitor;
  
  // Tab content caching
  final Map<int, Widget> _tabCache = {};
  final Map<int, DateTime> _tabLastAccessed = {};
  
  // Performance tracking
  final Map<int, Stopwatch> _tabSwitchTimers = {};
  Timer? _cacheCleanupTimer;
  
  // Animation optimization
  late AnimationController _sharedAnimationController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializePerformanceMonitoring();
    _startCacheCleanup();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.dispose();
    _sharedAnimationController.dispose();
    _cacheCleanupTimer?.cancel();
    _performanceMonitor.dispose();
    super.dispose();
  }

  void _initializeController() {
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    
    _tabController.addListener(_handleTabChange);
    
    // Initialize shared animation controller
    _sharedAnimationController = widget.animationController ?? 
        AnimationController(
          duration: Duration(milliseconds: 300),
          vsync: this,
        );
  }

  void _initializePerformanceMonitoring() {
    _performanceMonitor = PerformanceMonitor(
      enabled: widget.enablePerformanceMonitoring,
      onMetric: widget.onPerformanceMetric,
    );
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      final newIndex = _tabController.index;
      
      // Start performance timer
      _tabSwitchTimers[newIndex] = Stopwatch()..start();
      
      // Preload adjacent tabs
      _preloadAdjacentTabs(newIndex);
      
      // Update last accessed time
      _tabLastAccessed[newIndex] = DateTime.now();
      
      // Notify parent
      widget.onTabChanged?.call(newIndex);
      
      // Trigger haptic feedback
      HapticFeedback.selectionClick();
      
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _preloadAdjacentTabs(int currentIndex) {
    if (!widget.enableLazyLoading) return;
    
    for (int i = 1; i <= widget.preloadDistance; i++) {
      // Preload previous tabs
      final prevIndex = currentIndex - i;
      if (prevIndex >= 0 && !_tabCache.containsKey(prevIndex)) {
        _loadTabContent(prevIndex);
      }
      
      // Preload next tabs
      final nextIndex = currentIndex + i;
      if (nextIndex < widget.tabs.length && !_tabCache.containsKey(nextIndex)) {
        _loadTabContent(nextIndex);
      }
    }
  }

  Widget _loadTabContent(int index) {
    if (_tabCache.containsKey(index)) {
      return _tabCache[index]!;
    }
    
    final stopwatch = Stopwatch()..start();
    
    final content = widget.tabBuilder(context, index, widget.tabs[index]);
    
    stopwatch.stop();
    _performanceMonitor.recordTabLoad(index, stopwatch.elapsedMilliseconds);
    
    if (widget.enableLazyLoading) {
      _tabCache[index] = content;
      _tabLastAccessed[index] = DateTime.now();
    }
    
    return content;
  }

  void _startCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _cleanupCache();
    });
  }

  void _cleanupCache() {
    if (_isDisposed) return;
    
    final now = DateTime.now();
    final currentIndex = _tabController.index;
    final keysToRemove = <int>[];
    
    for (final entry in _tabLastAccessed.entries) {
      final index = entry.key;
      final lastAccessed = entry.value;
      
      // Don't remove current tab or tabs within cache extent
      if (index == currentIndex || 
          (index - currentIndex).abs() <= widget.cacheExtent) {
        continue;
      }
      
      // Remove tabs not accessed in the last 10 minutes
      if (now.difference(lastAccessed).inMinutes > 10) {
        keysToRemove.add(index);
      }
    }
    
    for (final key in keysToRemove) {
      _tabCache.remove(key);
      _tabLastAccessed.remove(key);
    }
    
    _performanceMonitor.recordCacheCleanup(keysToRemove.length);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: _buildTabBarView(),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      tabs: widget.tabs.map((tab) => Tab(
        text: tab.title,
        icon: tab.icon,
      )).toList(),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(widget.tabs.length, (index) {
        if (widget.enableLazyLoading) {
          return _buildLazyTab(index);
        } else {
          return _loadTabContent(index);
        }
      }),
    );
  }

  Widget _buildLazyTab(int index) {
    return Builder(
      builder: (context) {
        // Only build content for visible and adjacent tabs
        final currentIndex = _tabController.index;
        final distance = (index - currentIndex).abs();
        
        if (distance <= widget.preloadDistance || _tabCache.containsKey(index)) {
          return _loadTabContent(index);
        }
        
        // Show loading placeholder for distant tabs
        return _buildLoadingPlaceholder();
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: DesignTokens.spacingM),
          Text('Inhoud laden...'),
        ],
      ),
    );
  }
}

/// Optimized Tab Data Model
class OptimizedTab {
  final String title;
  final Widget? icon;
  final String? badgeIdentifier;
  final Map<String, dynamic>? metadata;

  const OptimizedTab({
    required this.title,
    this.icon,
    this.badgeIdentifier,
    this.metadata,
  });
}

/// Performance Monitoring System
class PerformanceMonitor {
  final bool enabled;
  final ValueChanged<PerformanceMetric>? onMetric;
  
  final List<PerformanceMetric> _metrics = [];
  Timer? _reportTimer;

  PerformanceMonitor({
    required this.enabled,
    this.onMetric,
  }) {
    if (enabled) {
      _startReporting();
    }
  }

  void recordTabLoad(int tabIndex, int loadTimeMs) {
    if (!enabled) return;
    
    final metric = PerformanceMetric(
      type: MetricType.tabLoad,
      tabIndex: tabIndex,
      value: loadTimeMs.toDouble(),
      timestamp: DateTime.now(),
    );
    
    _metrics.add(metric);
    onMetric?.call(metric);
  }

  void recordTabSwitch(int fromIndex, int toIndex, int switchTimeMs) {
    if (!enabled) return;
    
    final metric = PerformanceMetric(
      type: MetricType.tabSwitch,
      tabIndex: toIndex,
      value: switchTimeMs.toDouble(),
      timestamp: DateTime.now(),
      metadata: {'fromIndex': fromIndex},
    );
    
    _metrics.add(metric);
    onMetric?.call(metric);
  }

  void recordCacheCleanup(int itemsRemoved) {
    if (!enabled) return;
    
    final metric = PerformanceMetric(
      type: MetricType.cacheCleanup,
      value: itemsRemoved.toDouble(),
      timestamp: DateTime.now(),
    );
    
    _metrics.add(metric);
    onMetric?.call(metric);
  }

  void _startReporting() {
    _reportTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _generateReport();
    });
  }

  void _generateReport() {
    if (_metrics.isEmpty) return;
    
    final report = PerformanceReport.fromMetrics(_metrics);
    debugPrint('TabBar Performance Report: ${report.summary}');
    
    // Clear old metrics
    _metrics.clear();
  }

  void dispose() {
    _reportTimer?.cancel();
  }
}

/// Performance Metric Data Model
class PerformanceMetric {
  final MetricType type;
  final int? tabIndex;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const PerformanceMetric({
    required this.type,
    this.tabIndex,
    required this.value,
    required this.timestamp,
    this.metadata,
  });
}

/// Metric Types
enum MetricType {
  tabLoad,
  tabSwitch,
  cacheCleanup,
  memoryUsage,
}

/// Performance Report
class PerformanceReport {
  final double averageTabLoadTime;
  final double averageTabSwitchTime;
  final int totalCacheCleanups;
  final String summary;

  const PerformanceReport({
    required this.averageTabLoadTime,
    required this.averageTabSwitchTime,
    required this.totalCacheCleanups,
    required this.summary,
  });

  factory PerformanceReport.fromMetrics(List<PerformanceMetric> metrics) {
    final loadTimes = metrics
        .where((m) => m.type == MetricType.tabLoad)
        .map((m) => m.value)
        .toList();
    
    final switchTimes = metrics
        .where((m) => m.type == MetricType.tabSwitch)
        .map((m) => m.value)
        .toList();
    
    final cleanups = metrics
        .where((m) => m.type == MetricType.cacheCleanup)
        .length;
    
    final avgLoad = loadTimes.isEmpty ? 0.0 : 
        loadTimes.reduce((a, b) => a + b) / loadTimes.length;
    
    final avgSwitch = switchTimes.isEmpty ? 0.0 : 
        switchTimes.reduce((a, b) => a + b) / switchTimes.length;
    
    return PerformanceReport(
      averageTabLoadTime: avgLoad,
      averageTabSwitchTime: avgSwitch,
      totalCacheCleanups: cleanups,
      summary: 'Load: ${avgLoad.toStringAsFixed(1)}ms, '
               'Switch: ${avgSwitch.toStringAsFixed(1)}ms, '
               'Cleanups: $cleanups',
    );
  }
}
