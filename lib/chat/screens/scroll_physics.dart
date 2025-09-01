import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../unified_design_tokens.dart';

/// Custom scroll physics for enhanced chat experience
/// 
/// Features:
/// - Natural momentum scrolling with customizable retention
/// - Spring physics for smooth bounce effects
/// - Optimized deceleration curves for chat context
/// - Enhanced overscroll behavior for pull-to-refresh
/// - Performance-optimized physics calculations
/// - Configurable spring constants and damping ratios
/// 
/// This physics implementation provides a premium scrolling experience
/// that feels natural and responsive, similar to modern messaging apps.
class ChatScrollPhysics extends ScrollPhysics {
  /// Spring constant for bounce effects (higher = stiffer spring)
  final double springConstant;
  
  /// Damping ratio for spring oscillations (0.0-1.0, higher = less bouncy)
  final double dampingRatio;
  
  /// Momentum retention factor (0.0-1.0, higher = longer momentum)
  final double momentumRetention;
  
  /// Minimum velocity threshold for momentum scrolling
  final double minimumVelocity;
  
  /// Maximum velocity cap to prevent excessive scrolling
  final double maximumVelocity;
  
  /// Enhanced friction for natural deceleration
  final double frictionCoefficient;

  const ChatScrollPhysics({
    super.parent,
    this.springConstant = 100.0,
    this.dampingRatio = 0.8,
    this.momentumRetention = 0.92,
    this.minimumVelocity = 50.0,
    this.maximumVelocity = 8000.0,
    this.frictionCoefficient = 0.015,
  });

  @override
  ChatScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ChatScrollPhysics(
      parent: buildParent(ancestor),
      springConstant: springConstant,
      dampingRatio: dampingRatio,
      momentumRetention: momentumRetention,
      minimumVelocity: minimumVelocity,
      maximumVelocity: maximumVelocity,
      frictionCoefficient: frictionCoefficient,
    );
  }

  @override
  SpringDescription get spring => SpringDescription(
    mass: 1.0,
    stiffness: springConstant,
    damping: dampingRatio * 2.0 * math.sqrt(springConstant * 1.0),
  );

  @override
  double get minFlingVelocity => minimumVelocity;

  @override
  double get maxFlingVelocity => maximumVelocity;

  @override
  Tolerance get tolerance => Tolerance(
    velocity: 1.0, // Lower tolerance for smoother animations
    distance: 0.5,
  );

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = this.tolerance;
    
    // Enhanced velocity clamping
    velocity = velocity.clamp(-maximumVelocity, maximumVelocity);
    
    // Apply momentum retention
    velocity *= momentumRetention;
    
    // Skip simulation if velocity is too low
    if (velocity.abs() < tolerance.velocity) {
      return null;
    }

    // Handle overscroll with spring physics
    if (position.outOfRange) {
      double end;
      if (position.pixels > position.maxScrollExtent) {
        end = position.maxScrollExtent;
      } else {
        end = position.minScrollExtent;
      }

      return ScrollSpringSimulation(
        spring,
        position.pixels,
        end,
        velocity,
        tolerance: tolerance,
      );
    }

    // Normal scrolling with enhanced friction simulation
    return EnhancedFrictionSimulation(
      frictionCoefficient,
      position.pixels,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  double carriedMomentum(double existingVelocity) {
    // Enhanced momentum carrying for smoother interactions
    return existingVelocity * momentumRetention;
  }

  @override
  double get dragStartDistanceMotionThreshold {
    // Reduced threshold for more responsive drag start
    return 3.5;
  }

  @override
  bool recommendDeferredLoading(
    double velocity,
    ScrollMetrics metrics,
    BuildContext context,
  ) {
    // Defer loading when scrolling fast to maintain performance
    return velocity.abs() > 2000.0;
  }
}

/// Enhanced friction simulation with customizable deceleration curves
class EnhancedFrictionSimulation extends Simulation {
  final double _drag;
  final double _position;
  final double _velocity;

  EnhancedFrictionSimulation(
    double drag,
    double position,
    double velocity, {
    super.tolerance,
  })  : _drag = drag,
        _position = position,
        _velocity = velocity;

  @override
  double x(double time) {
    if (_velocity == 0.0) return _position;
    
    final double exponential = math.exp(-_drag * time);
    return _position + _velocity * exponential / _drag;
  }

  @override
  double dx(double time) {
    if (_velocity == 0.0) return 0.0;
    
    return _velocity * math.exp(-_drag * time);
  }

  @override
  bool isDone(double time) {
    return dx(time).abs() < tolerance.velocity;
  }

  @override
  String toString() {
    return 'EnhancedFrictionSimulation(drag: $_drag, position: $_position, velocity: $_velocity)';
  }
}

/// Smooth spring simulation for overscroll behavior
class SmoothSpringSimulation extends Simulation {
  final SpringDescription _spring;
  final double _start;
  final double _end;
  final double _velocity;

  SmoothSpringSimulation(
    SpringDescription spring,
    double start,
    double end,
    double velocity, {
    super.tolerance,
  })  : _spring = spring,
        _start = start,
        _end = end,
        _velocity = velocity;

  @override
  double x(double time) {
    return _end + (_start - _end) * (_velocity * time + 1.0) * math.exp(-_spring.damping * time);
  }

  @override
  double dx(double time) {
    final double exponential = math.exp(-_spring.damping * time);
    return (_start - _end) * (_velocity - _spring.damping * (_velocity * time + 1.0)) * exponential;
  }

  @override
  bool isDone(double time) {
    return (x(time) - _end).abs() < tolerance.distance &&
           dx(time).abs() < tolerance.velocity;
  }
}

/// Custom scroll behavior for enhanced chat scrolling
class ChatScrollBehavior extends ScrollBehavior {
  /// Whether to enable momentum on all platforms
  final bool enableMomentumOnAllPlatforms;
  
  /// Custom physics configuration
  final ChatScrollPhysics? customPhysics;

  const ChatScrollBehavior({
    this.enableMomentumOnAllPlatforms = true,
    this.customPhysics,
  });

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    final physics = customPhysics ?? ChatScrollPhysics();
    
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return physics.applyTo(const BouncingScrollPhysics());
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        if (enableMomentumOnAllPlatforms) {
          return physics.applyTo(const BouncingScrollPhysics());
        }
        return physics.applyTo(const ClampingScrollPhysics());
    }
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Enhanced scrollbar with chat-specific styling
    switch (getPlatform(context)) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return Scrollbar(
          controller: details.controller,
          thickness: 8.0,
          radius: Radius.circular(DesignTokens.radiusS),
          thumbVisibility: false,
          trackVisibility: false,
          child: child,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return child;
    }
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Custom overscroll indicator with chat theming
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (notification) {
        // Custom overscroll handling
        return false;
      },
      child: child,
    );
  }
}

/// Scroll position manager for chat-specific behaviors
class ChatScrollController extends ScrollController {
  /// Whether to auto-scroll to bottom for new messages
  bool autoScrollToBottom;
  
  /// Threshold for considering "at bottom"
  final double bottomThreshold;
  
  /// Animation duration for auto-scroll
  final Duration autoScrollDuration;
  
  /// Animation curve for auto-scroll
  final Curve autoScrollCurve;

  ChatScrollController({
    this.autoScrollToBottom = true,
    this.bottomThreshold = 100.0,
    this.autoScrollDuration = const Duration(milliseconds: 300),
    this.autoScrollCurve = Curves.easeOutCubic,
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  /// Check if scroll position is at bottom
  bool get isAtBottom {
    if (!hasClients) return true;
    return offset <= bottomThreshold;
  }

  /// Check if scroll position is at top
  bool get isAtTop {
    if (!hasClients) return false;
    return offset >= position.maxScrollExtent - bottomThreshold;
  }

  /// Smoothly scroll to bottom
  Future<void> scrollToBottom({
    Duration? duration,
    Curve? curve,
  }) {
    if (!hasClients) return Future.value();
    
    return animateTo(
      0.0,
      duration: duration ?? autoScrollDuration,
      curve: curve ?? autoScrollCurve,
    );
  }

  /// Smoothly scroll to top
  Future<void> scrollToTop({
    Duration? duration,
    Curve? curve,
  }) {
    if (!hasClients) return Future.value();
    
    return animateTo(
      position.maxScrollExtent,
      duration: duration ?? autoScrollDuration,
      curve: curve ?? autoScrollCurve,
    );
  }

  /// Scroll to specific message with smooth animation
  Future<void> scrollToMessage(
    int messageIndex, {
    double messageHeight = 80.0,
    Duration? duration,
    Curve? curve,
  }) {
    if (!hasClients) return Future.value();
    
    final targetOffset = (messageIndex * messageHeight).clamp(
      0.0,
      position.maxScrollExtent,
    );
    
    return animateTo(
      targetOffset,
      duration: duration ?? autoScrollDuration,
      curve: curve ?? Curves.easeInOutCubic,
    );
  }

  /// Jump to bottom instantly (for initial load)
  void jumpToBottom() {
    if (hasClients) {
      jumpTo(0.0);
    }
  }

  /// Jump to top instantly
  void jumpToTop() {
    if (hasClients) {
      jumpTo(position.maxScrollExtent);
    }
  }
}

/// Scroll metrics extensions for chat-specific calculations
extension ChatScrollMetrics on ScrollMetrics {
  /// Get scroll percentage (0.0 at bottom, 1.0 at top)
  double get scrollPercentage {
    if (maxScrollExtent <= 0) return 0.0;
    return (pixels / maxScrollExtent).clamp(0.0, 1.0);
  }

  /// Get reverse scroll percentage (1.0 at bottom, 0.0 at top)
  double get reverseScrollPercentage {
    return 1.0 - scrollPercentage;
  }

  /// Check if scrolled past threshold
  bool isScrolledPast(double threshold) {
    return pixels > threshold;
  }

  /// Get visible message range based on item height
  ({int startIndex, int endIndex}) getVisibleMessageRange(
    double itemHeight,
    int totalItems,
  ) {
    final viewportHeight = viewportDimension;
    final startIndex = ((maxScrollExtent - pixels - viewportHeight) / itemHeight)
        .floor()
        .clamp(0, totalItems - 1);
    final endIndex = ((maxScrollExtent - pixels) / itemHeight)
        .ceil()
        .clamp(0, totalItems);
    
    return (startIndex: startIndex, endIndex: endIndex);
  }
}