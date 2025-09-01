import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'shared_animation_controller.dart';
import 'memory_leak_detector.dart';

/// Animation Controller Lifecycle Monitoring System
/// 
/// This system tracks the lifecycle of all animation controllers in the optimized
/// tab header system, ensuring proper disposal and detecting abandoned controllers.
/// 
/// **Monitoring Targets:**
/// - SharedAnimationController pool efficiency
/// - Controller creation/disposal patterns
/// - Abandoned or undisposed controllers
/// - Animation memory footprint per screen
/// 
/// **Performance Requirements:**
/// - Controller pool size: 6-8 shared controllers (down from 25+)
/// - Memory per controller: ~12MB average
/// - Disposal verification: 100% success rate
/// - Leak detection: < 1 second response time
class AnimationControllerMonitor {
  static final AnimationControllerMonitor _instance = AnimationControllerMonitor._internal();
  factory AnimationControllerMonitor() => _instance;
  AnimationControllerMonitor._internal();
  
  static AnimationControllerMonitor get instance => _instance;
  
  // Controller tracking state
  final Map<String, ControllerLifecycleData> _controllerLifecycles = {};
  final Map<String, DateTime> _controllerCreationTimes = {};
  final Map<String, DateTime> _controllerDisposalTimes = {};
  final List<ControllerLeakEvent> _leakEvents = [];
  
  // Monitoring timers
  Timer? _lifecycleMonitorTimer;
  Timer? _leakDetectionTimer;
  
  // Configuration
  static const int _maxExpectedControllers = 8;
  static const Duration _controllerTimeout = Duration(minutes: 5);
  static const Duration _monitoringInterval = Duration(seconds: 10);
  
  bool _isMonitoring = false;
  
  /// Initialize controller monitoring
  void initialize() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _startLifecycleMonitoring();
    _startLeakDetection();
    
    debugPrint('🎬 AnimationControllerMonitor: Controller lifecycle monitoring activated');
    debugPrint('   📊 Max expected controllers: $_maxExpectedControllers');
    debugPrint('   📊 Controller timeout: ${_controllerTimeout.inMinutes} minutes');
  }
  
  /// Dispose controller monitoring
  void dispose() {
    _lifecycleMonitorTimer?.cancel();
    _leakDetectionTimer?.cancel();
    _isMonitoring = false;
    
    debugPrint('🎬 AnimationControllerMonitor: Monitoring system deactivated');
  }
  
  /// Record controller creation event
  void recordControllerCreated(String controllerId, String context) {
    final now = DateTime.now();
    
    _controllerCreationTimes[controllerId] = now;
    _controllerLifecycles[controllerId] = ControllerLifecycleData(
      controllerId: controllerId,
      context: context,
      createdAt: now,
      isDisposed: false,
    );
    
    developer.log(
      '🎬 Controller created: $controllerId (context: $context)',
      name: 'AnimationControllerMonitor'
    );
    
    _checkControllerPoolSize();
  }
  
  /// Record controller disposal event
  void recordControllerDisposed(String controllerId) {
    final now = DateTime.now();
    
    _controllerDisposalTimes[controllerId] = now;
    
    final lifecycle = _controllerLifecycles[controllerId];
    if (lifecycle != null) {
      _controllerLifecycles[controllerId] = lifecycle.copyWith(
        disposedAt: now,
        isDisposed: true,
      );
      
      final lifetime = now.difference(lifecycle.createdAt);
      developer.log(
        '🎬 Controller disposed: $controllerId (lifetime: ${lifetime.inSeconds}s)',
        name: 'AnimationControllerMonitor'
      );
    } else {
      // Controller was disposed but never recorded as created
      _recordLeakEvent(
        ControllerLeakType.unknownDisposal,
        'Controller $controllerId was disposed but creation was not recorded',
        {'controllerId': controllerId},
      );
    }
  }
  
  /// Get controller lifecycle analysis
  ControllerLifecycleAnalysis getLifecycleAnalysis() {
    final now = DateTime.now();
    final sharedMetrics = SharedAnimationController.instance.getMetrics();
    
    final activeControllers = _controllerLifecycles.values
        .where((lifecycle) => !lifecycle.isDisposed)
        .length;
    
    final abandonedControllers = _controllerLifecycles.values
        .where((lifecycle) => 
            !lifecycle.isDisposed && 
            now.difference(lifecycle.createdAt) > _controllerTimeout)
        .toList();
    
    final averageLifetime = _calculateAverageLifetime();
    final disposalRate = _calculateDisposalRate();
    
    return ControllerLifecycleAnalysis(
      activeControllers: activeControllers,
      sharedControllers: sharedMetrics.activeControllers,
      abandonedControllers: abandonedControllers.length,
      totalControllersCreated: _controllerLifecycles.length,
      averageLifetimeSeconds: averageLifetime?.inSeconds ?? 0,
      disposalSuccessRate: disposalRate,
      memoryOptimizationEffective: sharedMetrics.activeControllers <= _maxExpectedControllers,
      leakEvents: List.from(_leakEvents),
      analysisTimestamp: now,
    );
  }
  
  /// Detect controller leaks
  Future<List<ControllerLeak>> detectControllerLeaks() async {
    final stopwatch = Stopwatch()..start();
    final leaks = <ControllerLeak>[];
    
    try {
      // Check for abandoned controllers
      final abandonedLeaks = _detectAbandonedControllers();
      leaks.addAll(abandonedLeaks);
      
      // Check pool size violations
      final poolLeaks = _detectPoolSizeViolations();
      leaks.addAll(poolLeaks);
      
      // Check disposal patterns
      final disposalLeaks = _detectDisposalPatternIssues();
      leaks.addAll(disposalLeaks);
      
      stopwatch.stop();
      
      // Log performance
      if (stopwatch.elapsedMilliseconds > 500) {
        developer.log(
          '⚠️ Controller leak detection took ${stopwatch.elapsedMilliseconds}ms (target: <500ms)',
          name: 'AnimationControllerMonitor'
        );
      }
      
      return leaks;
    } catch (e) {
      stopwatch.stop();
      developer.log(
        '🚨 Controller leak detection failed: $e',
        name: 'AnimationControllerMonitor'
      );
      return [];
    }
  }
  
  /// Get controller performance metrics
  ControllerPerformanceMetrics getPerformanceMetrics() {
    final sharedMetrics = SharedAnimationController.instance.getMetrics();
    final analysis = getLifecycleAnalysis();
    
    return ControllerPerformanceMetrics(
      totalMemorySavedMB: sharedMetrics.memorySavedMB,
      memoryReductionPercentage: sharedMetrics.memoryReductionPercentage,
      controllerPoolEfficiency: _calculatePoolEfficiency(),
      averageControllerLifetime: Duration(seconds: analysis.averageLifetimeSeconds),
      disposalSuccessRate: analysis.disposalSuccessRate,
      leakCount: analysis.leakEvents.length,
      optimizationTargetMet: sharedMetrics.activeControllers <= _maxExpectedControllers,
    );
  }
  
  /// Clear monitoring data (for testing)
  void clearMonitoringData() {
    _controllerLifecycles.clear();
    _controllerCreationTimes.clear();
    _controllerDisposalTimes.clear();
    _leakEvents.clear();
    
    debugPrint('🎬 AnimationControllerMonitor: Monitoring data cleared');
  }
  
  // Private methods
  
  void _startLifecycleMonitoring() {
    _lifecycleMonitorTimer = Timer.periodic(_monitoringInterval, (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      
      _performLifecycleCheck();
    });
  }
  
  void _startLeakDetection() {
    _leakDetectionTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      
      detectControllerLeaks().then((leaks) {
        if (leaks.isNotEmpty) {
          for (final leak in leaks) {
            _recordLeakEvent(
              leak.type,
              leak.description,
              leak.context,
            );
          }
        }
      });
    });
  }
  
  void _performLifecycleCheck() {
    final analysis = getLifecycleAnalysis();
    
    developer.log(
      '🎬 Lifecycle Check: ${analysis.activeControllers} active, '
      '${analysis.sharedControllers} shared, '
      '${analysis.abandonedControllers} abandoned, '
      '${analysis.disposalSuccessRate.toStringAsFixed(1)}% disposal rate',
      name: 'AnimationControllerMonitor'
    );
    
    // Check for performance issues
    if (analysis.sharedControllers > _maxExpectedControllers) {
      _recordLeakEvent(
        ControllerLeakType.poolSizeViolation,
        'Too many shared controllers: ${analysis.sharedControllers} (max: $_maxExpectedControllers)',
        {'activeControllers': analysis.sharedControllers, 'maxExpected': _maxExpectedControllers},
      );
    }
    
    if (analysis.abandonedControllers > 0) {
      _recordLeakEvent(
        ControllerLeakType.abandonedController,
        '${analysis.abandonedControllers} controllers abandoned for >${_controllerTimeout.inMinutes} minutes',
        {'abandonedCount': analysis.abandonedControllers},
      );
    }
  }
  
  void _checkControllerPoolSize() {
    final sharedMetrics = SharedAnimationController.instance.getMetrics();
    
    if (sharedMetrics.activeControllers > _maxExpectedControllers) {
      developer.log(
        '⚠️ Controller pool size warning: ${sharedMetrics.activeControllers} active (target: ≤$_maxExpectedControllers)',
        name: 'AnimationControllerMonitor'
      );
    }
  }
  
  List<ControllerLeak> _detectAbandonedControllers() {
    final now = DateTime.now();
    final leaks = <ControllerLeak>[];
    
    for (final lifecycle in _controllerLifecycles.values) {
      if (!lifecycle.isDisposed && now.difference(lifecycle.createdAt) > _controllerTimeout) {
        leaks.add(ControllerLeak(
          type: ControllerLeakType.abandonedController,
          description: 'Controller ${lifecycle.controllerId} abandoned for ${now.difference(lifecycle.createdAt).inMinutes} minutes',
          severity: ControllerLeakSeverity.high,
          controllerId: lifecycle.controllerId,
          context: {
            'createdAt': lifecycle.createdAt.toIso8601String(),
            'minutesAbandoned': now.difference(lifecycle.createdAt).inMinutes,
            'originalContext': lifecycle.context,
          },
        ));
      }
    }
    
    return leaks;
  }
  
  List<ControllerLeak> _detectPoolSizeViolations() {
    final leaks = <ControllerLeak>[];
    final sharedMetrics = SharedAnimationController.instance.getMetrics();
    
    if (sharedMetrics.activeControllers > _maxExpectedControllers) {
      leaks.add(ControllerLeak(
        type: ControllerLeakType.poolSizeViolation,
        description: 'Controller pool size exceeded: ${sharedMetrics.activeControllers} active (max: $_maxExpectedControllers)',
        severity: sharedMetrics.activeControllers > _maxExpectedControllers * 2 
            ? ControllerLeakSeverity.critical 
            : ControllerLeakSeverity.medium,
        controllerId: 'shared_pool',
        context: {
          'activeControllers': sharedMetrics.activeControllers,
          'maxExpected': _maxExpectedControllers,
          'totalCreated': sharedMetrics.totalControllersCreated,
          'memorySaved': sharedMetrics.memorySavedMB,
        },
      ));
    }
    
    return leaks;
  }
  
  List<ControllerLeak> _detectDisposalPatternIssues() {
    final leaks = <ControllerLeak>[];
    final disposalRate = _calculateDisposalRate();
    
    // Alert if disposal rate is below 95%
    if (disposalRate < 95.0) {
      leaks.add(ControllerLeak(
        type: ControllerLeakType.disposalFailure,
        description: 'Low controller disposal rate: ${disposalRate.toStringAsFixed(1)}% (target: ≥95%)',
        severity: disposalRate < 80.0 ? ControllerLeakSeverity.critical : ControllerLeakSeverity.high,
        controllerId: 'disposal_pattern',
        context: {
          'disposalRate': disposalRate,
          'totalControllers': _controllerLifecycles.length,
          'undisposedCount': _controllerLifecycles.values.where((l) => !l.isDisposed).length,
        },
      ));
    }
    
    return leaks;
  }
  
  Duration? _calculateAverageLifetime() {
    final disposedLifecycles = _controllerLifecycles.values
        .where((lifecycle) => lifecycle.isDisposed && lifecycle.disposedAt != null)
        .toList();
    
    if (disposedLifecycles.isEmpty) return null;
    
    final totalMs = disposedLifecycles
        .map((lifecycle) => lifecycle.disposedAt!.difference(lifecycle.createdAt).inMilliseconds)
        .reduce((a, b) => a + b);
    
    return Duration(milliseconds: totalMs ~/ disposedLifecycles.length);
  }
  
  double _calculateDisposalRate() {
    if (_controllerLifecycles.isEmpty) return 100.0;
    
    final disposedCount = _controllerLifecycles.values
        .where((lifecycle) => lifecycle.isDisposed)
        .length;
    
    return (disposedCount / _controllerLifecycles.length) * 100.0;
  }
  
  double _calculatePoolEfficiency() {
    final sharedMetrics = SharedAnimationController.instance.getMetrics();
    
    if (sharedMetrics.totalControllersCreated == 0) return 100.0;
    
    // Efficiency = (total - active) / total * 100
    // Higher efficiency means more sharing (fewer active controllers)
    return ((sharedMetrics.totalControllersCreated - sharedMetrics.activeControllers) / 
            sharedMetrics.totalControllersCreated) * 100.0;
  }
  
  void _recordLeakEvent(ControllerLeakType type, String description, Map<String, dynamic> context) {
    final event = ControllerLeakEvent(
      type: type,
      description: description,
      timestamp: DateTime.now(),
      context: context,
    );
    
    _leakEvents.add(event);
    
    // Keep only last 50 events
    if (_leakEvents.length > 50) {
      _leakEvents.removeAt(0);
    }
    
    // Log event
    developer.log('🚨 Controller Leak Event: $description', name: 'AnimationControllerMonitor');
    
    // Report to memory leak detector
    MemoryLeakDetector.instance.recordMemorySnapshot(
      'controller_system',
      SharedAnimationController.instance.getMetrics().activeControllers * 12, // ~12MB per controller
      {'leakEvent': event.toMap()},
    );
  }
}

/// Controller lifecycle data
class ControllerLifecycleData {
  final String controllerId;
  final String context;
  final DateTime createdAt;
  final DateTime? disposedAt;
  final bool isDisposed;
  
  const ControllerLifecycleData({
    required this.controllerId,
    required this.context,
    required this.createdAt,
    this.disposedAt,
    required this.isDisposed,
  });
  
  ControllerLifecycleData copyWith({
    String? controllerId,
    String? context,
    DateTime? createdAt,
    DateTime? disposedAt,
    bool? isDisposed,
  }) {
    return ControllerLifecycleData(
      controllerId: controllerId ?? this.controllerId,
      context: context ?? this.context,
      createdAt: createdAt ?? this.createdAt,
      disposedAt: disposedAt ?? this.disposedAt,
      isDisposed: isDisposed ?? this.isDisposed,
    );
  }
}

/// Controller lifecycle analysis result
class ControllerLifecycleAnalysis {
  final int activeControllers;
  final int sharedControllers;
  final int abandonedControllers;
  final int totalControllersCreated;
  final int averageLifetimeSeconds;
  final double disposalSuccessRate;
  final bool memoryOptimizationEffective;
  final List<ControllerLeakEvent> leakEvents;
  final DateTime analysisTimestamp;
  
  const ControllerLifecycleAnalysis({
    required this.activeControllers,
    required this.sharedControllers,
    required this.abandonedControllers,
    required this.totalControllersCreated,
    required this.averageLifetimeSeconds,
    required this.disposalSuccessRate,
    required this.memoryOptimizationEffective,
    required this.leakEvents,
    required this.analysisTimestamp,
  });
  
  @override
  String toString() {
    return 'ControllerLifecycleAnalysis('
           'active: $activeControllers, '
           'shared: $sharedControllers, '
           'abandoned: $abandonedControllers, '
           'disposal: ${disposalSuccessRate.toStringAsFixed(1)}%'
           ')';
  }
}

/// Controller performance metrics
class ControllerPerformanceMetrics {
  final int totalMemorySavedMB;
  final double memoryReductionPercentage;
  final double controllerPoolEfficiency;
  final Duration averageControllerLifetime;
  final double disposalSuccessRate;
  final int leakCount;
  final bool optimizationTargetMet;
  
  const ControllerPerformanceMetrics({
    required this.totalMemorySavedMB,
    required this.memoryReductionPercentage,
    required this.controllerPoolEfficiency,
    required this.averageControllerLifetime,
    required this.disposalSuccessRate,
    required this.leakCount,
    required this.optimizationTargetMet,
  });
  
  @override
  String toString() {
    return 'ControllerPerformanceMetrics('
           'memorySaved: ${totalMemorySavedMB}MB (${memoryReductionPercentage.toStringAsFixed(1)}%), '
           'efficiency: ${controllerPoolEfficiency.toStringAsFixed(1)}%, '
           'disposal: ${disposalSuccessRate.toStringAsFixed(1)}%, '
           'leaks: $leakCount'
           ')';
  }
}

/// Controller leak detection
class ControllerLeak {
  final ControllerLeakType type;
  final String description;
  final ControllerLeakSeverity severity;
  final String controllerId;
  final Map<String, dynamic> context;
  
  const ControllerLeak({
    required this.type,
    required this.description,
    required this.severity,
    required this.controllerId,
    required this.context,
  });
}

/// Controller leak event
class ControllerLeakEvent {
  final ControllerLeakType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  
  const ControllerLeakEvent({
    required this.type,
    required this.description,
    required this.timestamp,
    required this.context,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
    };
  }
}

/// Types of controller leaks
enum ControllerLeakType {
  abandonedController,
  poolSizeViolation,
  disposalFailure,
  unknownDisposal,
  memoryGrowth,
}

/// Controller leak severity
enum ControllerLeakSeverity {
  low,
  medium,
  high,
  critical,
}