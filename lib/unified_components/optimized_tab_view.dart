import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';

/// Optimized Tab View with Lazy Loading and Memory Management
/// Implements efficient tab content loading and caching strategies
/// Reduces rebuild frequencies and optimizes scroll controller sharing
class OptimizedTabView extends StatefulWidget {
  const OptimizedTabView({
    super.key,
    required this.controller,
    required this.children,
    this.physics,
    this.dragStartBehavior = DragStartBehavior.start,
    this.viewportFraction = 1.0,
    this.clipBehavior = Clip.hardEdge,
    this.enableLazyLoading = true,
    this.cacheExtent = 1,
    this.onPageChanged,
    this.scrollDirection = Axis.horizontal,
  });

  final TabController controller;
  final List<Widget> children;
  final ScrollPhysics? physics;
  final DragStartBehavior dragStartBehavior;
  final double viewportFraction;
  final Clip clipBehavior;
  final bool enableLazyLoading;
  final int cacheExtent;
  final ValueChanged<int>? onPageChanged;
  final Axis scrollDirection;

  @override
  State<OptimizedTabView> createState() => _OptimizedTabViewState();
}

class _OptimizedTabViewState extends State<OptimizedTabView> {
  late PageController _pageController;
  late ScrollController _sharedScrollController;
  
  // Lazy loading state
  final Set<int> _loadedPages = {};
  final Map<int, Widget> _pageCache = {};
  final Map<int, DateTime> _pageLastAccessed = {};
  
  // Performance tracking
  final Map<int, Stopwatch> _pageLoadTimers = {};
  Timer? _memoryCleanupTimer;
  
  // Scroll optimization
  Timer? _scrollDebounceTimer;
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _startMemoryManagement();
    
    // Load initial page
    _loadPage(widget.controller.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sharedScrollController.dispose();
    _memoryCleanupTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    super.dispose();
  }

  void _initializeControllers() {
    _pageController = PageController(
      initialPage: widget.controller.index,
      viewportFraction: widget.viewportFraction,
    );
    
    _sharedScrollController = ScrollController();
    
    // Listen to tab controller changes
    widget.controller.addListener(_handleTabControllerChange);
    
    // Listen to page controller changes
    _pageController.addListener(_handlePageControllerChange);
    
    // Optimize scroll listening with debouncing
    _sharedScrollController.addListener(_handleScrollChange);
  }

  void _handleTabControllerChange() {
    if (widget.controller.indexIsChanging) {
      final newIndex = widget.controller.index;
      
      // Animate to new page
      _pageController.animateToPage(
        newIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Load new page content
      _loadPage(newIndex);
      
      // Preload adjacent pages
      _preloadAdjacentPages(newIndex);
    }
  }

  void _handlePageControllerChange() {
    if (!_pageController.hasClients) return;
    
    final page = _pageController.page;
    if (page != null) {
      final currentIndex = page.round();
      
      // Update tab controller if needed
      if (currentIndex != widget.controller.index) {
        widget.controller.animateTo(currentIndex);
      }
      
      // Notify parent
      widget.onPageChanged?.call(currentIndex);
    }
  }

  void _handleScrollChange() {
    // Debounce scroll events to reduce rebuild frequency
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(Duration(milliseconds: 16), () {
      final currentOffset = _sharedScrollController.offset;
      
      // Only trigger rebuild if scroll offset changed significantly
      if ((currentOffset - _lastScrollOffset).abs() > 1.0) {
        _lastScrollOffset = currentOffset;
        
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void _loadPage(int index) {
    if (_loadedPages.contains(index) || index < 0 || index >= widget.children.length) {
      return;
    }
    
    _pageLoadTimers[index] = Stopwatch()..start();
    
    // Mark as loaded and update access time
    _loadedPages.add(index);
    _pageLastAccessed[index] = DateTime.now();
    
    // Cache the page content if lazy loading is enabled
    if (widget.enableLazyLoading) {
      _pageCache[index] = widget.children[index];
    }
    
    _pageLoadTimers[index]?.stop();
  }

  void _preloadAdjacentPages(int currentIndex) {
    if (!widget.enableLazyLoading) return;
    
    // Preload pages within cache extent
    for (int i = 1; i <= widget.cacheExtent; i++) {
      final prevIndex = currentIndex - i;
      final nextIndex = currentIndex + i;
      
      if (prevIndex >= 0) {
        _loadPage(prevIndex);
      }
      
      if (nextIndex < widget.children.length) {
        _loadPage(nextIndex);
      }
    }
  }

  void _startMemoryManagement() {
    _memoryCleanupTimer = Timer.periodic(Duration(minutes: 2), (_) {
      _cleanupMemory();
    });
  }

  void _cleanupMemory() {
    final now = DateTime.now();
    final currentIndex = widget.controller.index;
    final pagesToRemove = <int>[];
    
    for (final entry in _pageLastAccessed.entries) {
      final index = entry.key;
      final lastAccessed = entry.value;
      
      // Don't remove current page or pages within cache extent
      if (index == currentIndex || 
          (index - currentIndex).abs() <= widget.cacheExtent) {
        continue;
      }
      
      // Remove pages not accessed in the last 5 minutes
      if (now.difference(lastAccessed).inMinutes > 5) {
        pagesToRemove.add(index);
      }
    }
    
    for (final index in pagesToRemove) {
      _loadedPages.remove(index);
      _pageCache.remove(index);
      _pageLastAccessed.remove(index);
      _pageLoadTimers.remove(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      physics: widget.physics,
      dragStartBehavior: widget.dragStartBehavior,
      clipBehavior: widget.clipBehavior,
      scrollDirection: widget.scrollDirection,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return _buildPage(index);
      },
    );
  }

  Widget _buildPage(int index) {
    if (!widget.enableLazyLoading) {
      return widget.children[index];
    }
    
    // Check if page should be loaded
    final currentIndex = widget.controller.index;
    final distance = (index - currentIndex).abs();
    
    if (distance <= widget.cacheExtent || _loadedPages.contains(index)) {
      // Load and cache the page
      if (!_loadedPages.contains(index)) {
        _loadPage(index);
      }
      
      return _pageCache[index] ?? widget.children[index];
    }
    
    // Return placeholder for distant pages
    return _buildPlaceholder(index);
  }

  Widget _buildPlaceholder(int index) {
    return Builder(
      builder: (context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Inhoud laden...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DesignTokens.colorGray600,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ],
        ),
      )),
    );
  }
}

/// Shared Scroll Controller Manager
/// Optimizes scroll controller sharing across tabs to reduce memory usage
class SharedScrollControllerManager {
  static final SharedScrollControllerManager _instance = 
      SharedScrollControllerManager._internal();
  
  factory SharedScrollControllerManager() => _instance;
  SharedScrollControllerManager._internal();

  final Map<String, ScrollController> _controllers = {};
  final Map<String, int> _usageCount = {};
  final Map<String, Timer> _cleanupTimers = {};

  /// Get or create a shared scroll controller
  ScrollController getController(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = ScrollController();
      _usageCount[key] = 0;
    }
    
    _usageCount[key] = (_usageCount[key] ?? 0) + 1;
    _cancelCleanupTimer(key);
    
    return _controllers[key]!;
  }

  /// Release a shared scroll controller
  void releaseController(String key) {
    final currentUsage = _usageCount[key] ?? 0;
    if (currentUsage > 0) {
      _usageCount[key] = currentUsage - 1;
      
      // Schedule cleanup if no longer in use
      if (_usageCount[key] == 0) {
        _scheduleCleanup(key);
      }
    }
  }

  void _scheduleCleanup(String key) {
    _cleanupTimers[key] = Timer(Duration(minutes: 5), () {
      if ((_usageCount[key] ?? 0) == 0) {
        _controllers[key]?.dispose();
        _controllers.remove(key);
        _usageCount.remove(key);
        _cleanupTimers.remove(key);
      }
    });
  }

  void _cancelCleanupTimer(String key) {
    _cleanupTimers[key]?.cancel();
    _cleanupTimers.remove(key);
  }

  /// Force cleanup of all unused controllers
  void cleanup() {
    final keysToRemove = <String>[];
    
    for (final entry in _usageCount.entries) {
      if (entry.value == 0) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
      _usageCount.remove(key);
      _cleanupTimers[key]?.cancel();
      _cleanupTimers.remove(key);
    }
  }
}

/// Optimized Tab Content Wrapper
/// Provides automatic scroll controller management and performance optimization
class OptimizedTabContent extends StatefulWidget {
  const OptimizedTabContent({
    super.key,
    required this.child,
    required this.tabKey,
    this.enableScrollOptimization = true,
  });

  final Widget child;
  final String tabKey;
  final bool enableScrollOptimization;

  @override
  State<OptimizedTabContent> createState() => _OptimizedTabContentState();
}

class _OptimizedTabContentState extends State<OptimizedTabContent>
    with AutomaticKeepAliveClientMixin {
  
  late ScrollController _scrollController;
  final SharedScrollControllerManager _scrollManager = 
      SharedScrollControllerManager();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    if (widget.enableScrollOptimization) {
      _scrollController = _scrollManager.getController(widget.tabKey);
    }
  }

  @override
  void dispose() {
    if (widget.enableScrollOptimization) {
      _scrollManager.releaseController(widget.tabKey);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (widget.enableScrollOptimization) {
      return PrimaryScrollController(
        controller: _scrollController,
        child: widget.child,
      );
    }
    
    return widget.child;
  }
}
