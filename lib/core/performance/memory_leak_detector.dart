import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// SecuryFlex Memory Leak Detector
/// 
/// Detects and prevents common memory leaks in the SecuryFlex application
/// to ensure optimal performance and stability.
class MemoryLeakDetector {
  static final MemoryLeakDetector _instance = MemoryLeakDetector._internal();
  factory MemoryLeakDetector() => _instance;
  MemoryLeakDetector._internal();

  final Map<String, List<WeakReference<Object>>> _trackedObjects = {};
  final Map<String, int> _leakCounts = {};
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  /// Start memory leak monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    if (kDebugMode) {
      _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _checkForLeaks();
      });
      
      developer.log('Memory leak monitoring started', name: 'MemoryLeakDetector');
    }
  }

  /// Stop memory leak monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    
    if (kDebugMode) {
      developer.log('Memory leak monitoring stopped', name: 'MemoryLeakDetector');
    }
  }

  /// Track an object for potential memory leaks
  void trackObject(Object object, String category) {
    if (!kDebugMode) return;
    
    _trackedObjects.putIfAbsent(category, () => []);
    _trackedObjects[category]!.add(WeakReference(object));
  }

  /// Check for memory leaks
  void _checkForLeaks() {
    if (!kDebugMode) return;

    for (final entry in _trackedObjects.entries) {
      final category = entry.key;
      final references = entry.value;
      
      // Remove dead references
      references.removeWhere((ref) => ref.target == null);
      
      // Check for potential leaks
      final activeCount = references.length;
      if (activeCount > _getLeakThreshold(category)) {
        _leakCounts[category] = (_leakCounts[category] ?? 0) + 1;
        
        developer.log(
          'Potential memory leak detected: $category has $activeCount active objects',
          name: 'MemoryLeakDetector',
          level: 900, // Warning level
        );
      }
    }
  }

  /// Get leak threshold for different object categories
  int _getLeakThreshold(String category) {
    switch (category) {
      case 'AnimationController':
        return 10; // Max 10 animation controllers
      case 'StreamSubscription':
        return 20; // Max 20 stream subscriptions
      case 'Timer':
        return 5; // Max 5 timers
      case 'ScrollController':
        return 15; // Max 15 scroll controllers
      default:
        return 50; // Default threshold
    }
  }

  /// Get memory leak report
  Map<String, dynamic> getLeakReport() {
    final report = <String, dynamic>{};
    
    for (final entry in _trackedObjects.entries) {
      final category = entry.key;
      final activeCount = entry.value.where((ref) => ref.target != null).length;
      
      report[category] = {
        'active_objects': activeCount,
        'leak_count': _leakCounts[category] ?? 0,
        'threshold': _getLeakThreshold(category),
        'status': activeCount > _getLeakThreshold(category) ? 'WARNING' : 'OK',
      };
    }
    
    return report;
  }

  /// Clear all tracking data
  void clearTracking() {
    _trackedObjects.clear();
    _leakCounts.clear();
  }

  void dispose() {
    stopMonitoring();
    clearTracking();
  }
}

/// Mixin for automatic memory leak detection
mixin MemoryLeakDetectionMixin<T extends StatefulWidget> on State<T> {
  final MemoryLeakDetector _detector = MemoryLeakDetector();
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  final List<AnimationController> _animationControllers = [];
  final List<ScrollController> _scrollControllers = [];

  @override
  void initState() {
    super.initState();
    
    if (kDebugMode) {
      _detector.trackObject(this, 'StatefulWidget');
    }
  }

  /// Register a stream subscription for automatic cleanup
  void registerSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
    
    if (kDebugMode) {
      _detector.trackObject(subscription, 'StreamSubscription');
    }
  }

  /// Register a timer for automatic cleanup
  void registerTimer(Timer timer) {
    _timers.add(timer);
    
    if (kDebugMode) {
      _detector.trackObject(timer, 'Timer');
    }
  }

  /// Register an animation controller for automatic cleanup
  void registerAnimationController(AnimationController controller) {
    _animationControllers.add(controller);
    
    if (kDebugMode) {
      _detector.trackObject(controller, 'AnimationController');
    }
  }

  /// Register a scroll controller for automatic cleanup
  void registerScrollController(ScrollController controller) {
    _scrollControllers.add(controller);
    
    if (kDebugMode) {
      _detector.trackObject(controller, 'ScrollController');
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Cancel all timers
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    // Dispose all animation controllers
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers.clear();

    // Dispose all scroll controllers
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    _scrollControllers.clear();

    super.dispose();
  }
}

/// Widget wrapper for memory leak detection
class MemoryLeakDetectionWrapper extends StatefulWidget {
  final Widget child;
  final String widgetName;

  const MemoryLeakDetectionWrapper({
    super.key,
    required this.child,
    required this.widgetName,
  });

  @override
  State<MemoryLeakDetectionWrapper> createState() => _MemoryLeakDetectionWrapperState();
}

class _MemoryLeakDetectionWrapperState extends State<MemoryLeakDetectionWrapper>
    with MemoryLeakDetectionMixin {

  @override
  void initState() {
    super.initState();
    
    if (kDebugMode) {
      developer.log('Widget created: ${widget.widgetName}', name: 'MemoryLeakDetector');
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      developer.log('Widget disposed: ${widget.widgetName}', name: 'MemoryLeakDetector');
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension for easy memory leak detection
extension MemoryLeakDetectionExtension on State {
  /// Wrap a widget with memory leak detection
  Widget wrapWithMemoryDetection(Widget child, String name) {
    if (!kDebugMode) return child;
    
    return MemoryLeakDetectionWrapper(
      widgetName: name,
      child: child,
    );
  }
}
