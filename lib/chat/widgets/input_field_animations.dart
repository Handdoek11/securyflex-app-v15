import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../unified_design_tokens.dart';

/// Animation utilities for chat input field components
/// Provides reusable animation controllers, curves, and physics for consistent UX
class InputFieldAnimations {
  InputFieldAnimations._(); // Private constructor

  // ============================================================================
  // ANIMATION CURVES - Natural Feel
  // ============================================================================
  
  /// Natural ease out curve for smooth UI transitions
  static const Curve easeOutCubic = Curves.easeOutCubic;
  
  /// Bounce effect for button press feedback
  static const Curve elasticOut = Curves.elasticOut;
  
  /// Quick snap animation for immediate feedback
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  
  /// Spring physics for natural movement
  static const SpringDescription springPhysics = SpringDescription(
    mass: 1.0,
    stiffness: 500.0,
    damping: 30.0,
  );

  // ============================================================================
  // ANIMATION DURATIONS - Performance Optimized
  // ============================================================================
  
  /// Quick animations for immediate feedback (150ms)
  static const Duration fast = DesignTokens.durationFast;
  
  /// Standard animations for most transitions (300ms)
  static const Duration medium = DesignTokens.durationMedium;
  
  /// Slower animations for complex transitions (500ms)
  static const Duration slow = DesignTokens.durationSlow;
  
  /// Button press feedback duration (100ms)
  static const Duration buttonPress = Duration(milliseconds: 100);

  // ============================================================================
  // SCALE ANIMATION VALUES
  // ============================================================================
  
  /// Button press scale factor for tactile feedback
  static const double buttonPressScale = 0.95;
  
  /// Normal button scale
  static const double buttonNormalScale = 1.0;
  
  /// Attachment menu expand scale
  static const double menuExpandScale = 1.0;
  
  /// Attachment menu collapsed scale
  static const double menuCollapsedScale = 0.0;

  // ============================================================================
  // ROTATION ANIMATION VALUES
  // ============================================================================
  
  /// Full rotation for send button animation
  static const double fullRotation = 1.0; // 360 degrees
  
  /// Half rotation for intermediate states
  static const double halfRotation = 0.5; // 180 degrees
  
  /// No rotation (initial state)
  static const double noRotation = 0.0; // 0 degrees

  // ============================================================================
  // OPACITY VALUES FOR SMOOTH TRANSITIONS
  // ============================================================================
  
  static const double opacityVisible = DesignTokens.opacityFull;
  static const double opacityHidden = 0.0;
  static const double opacityDisabled = DesignTokens.opacityDisabled;
  static const double opacityMedium = DesignTokens.opacityMedium;

  // ============================================================================
  // SLIDE ANIMATION VALUES
  // ============================================================================
  
  /// Attachment menu slide in from bottom
  static const Offset slideFromBottom = Offset(0.0, 1.0);
  
  /// Normal position (no offset)
  static const Offset slideNormal = Offset.zero;
  
  /// Slide up for floating effect
  static const Offset slideUp = Offset(0.0, -0.1);

  // ============================================================================
  // FOCUS GLOW ANIMATION VALUES
  // ============================================================================
  
  /// Focus glow spread radius
  static const double glowSpread = 0.0;
  
  /// Focus glow blur radius
  static const double glowBlur = 8.0;
  
  /// Focus glow offset
  static const Offset glowOffset = Offset.zero;
  
  /// Focus glow opacity
  static const double glowOpacity = 0.3;

  // ============================================================================
  // REUSABLE ANIMATION CONTROLLERS
  // ============================================================================
  
  /// Creates a controller for button press animations
  static AnimationController createButtonPressController(TickerProvider vsync) {
    return AnimationController(
      duration: buttonPress,
      vsync: vsync,
    );
  }
  
  /// Creates a controller for send button rotation
  static AnimationController createSendRotationController(TickerProvider vsync) {
    return AnimationController(
      duration: medium,
      vsync: vsync,
    );
  }
  
  /// Creates a controller for attachment menu slide animation
  static AnimationController createMenuSlideController(TickerProvider vsync) {
    return AnimationController(
      duration: medium,
      vsync: vsync,
    );
  }
  
  /// Creates a controller for input field focus animations
  static AnimationController createFocusController(TickerProvider vsync) {
    return AnimationController(
      duration: fast,
      vsync: vsync,
    );
  }

  // ============================================================================
  // ANIMATION BUILDERS
  // ============================================================================
  
  /// Creates a scale animation with bounce effect
  static Animation<double> createScaleAnimation(
    AnimationController controller, {
    double begin = buttonPressScale,
    double end = buttonNormalScale,
    Curve curve = easeOutCubic,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
  
  /// Creates a rotation animation for send button
  static Animation<double> createRotationAnimation(
    AnimationController controller, {
    double begin = noRotation,
    double end = fullRotation,
    Curve curve = easeOutCubic,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
  
  /// Creates a slide animation for attachment menu
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = slideFromBottom,
    Offset end = slideNormal,
    Curve curve = easeOutCubic,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
  
  /// Creates an opacity animation for fade effects
  static Animation<double> createOpacityAnimation(
    AnimationController controller, {
    double begin = opacityHidden,
    double end = opacityVisible,
    Curve curve = easeOutCubic,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
  
  /// Creates a color animation for focus glow effect
  static Animation<Color?> createColorAnimation(
    AnimationController controller,
    Color beginColor,
    Color endColor, {
    Curve curve = easeOutCubic,
  }) {
    return ColorTween(
      begin: beginColor,
      end: endColor,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  // ============================================================================
  // HAPTIC FEEDBACK UTILITIES
  // ============================================================================
  
  /// Light haptic feedback for button taps
  static void lightHaptic() {
    HapticFeedback.lightImpact();
  }
  
  /// Medium haptic feedback for important actions
  static void mediumHaptic() {
    HapticFeedback.mediumImpact();
  }
  
  /// Selection haptic feedback for menu selections
  static void selectionHaptic() {
    HapticFeedback.selectionClick();
  }
  
  /// Heavy haptic feedback for send action
  static void sendHaptic() {
    HapticFeedback.heavyImpact();
  }

  // ============================================================================
  // STAGGERED ANIMATION HELPERS
  // ============================================================================
  
  /// Creates staggered animation for multiple items
  static List<Animation<double>> createStaggeredAnimations(
    AnimationController controller,
    int itemCount, {
    double staggerDelay = 0.1,
    Curve curve = easeOutCubic,
  }) {
    final animations = <Animation<double>>[];
    
    for (int i = 0; i < itemCount; i++) {
      final start = (i * staggerDelay).clamp(0.0, 1.0);
      final end = (start + (1.0 - start)).clamp(0.0, 1.0);
      
      animations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(start, end, curve: curve),
          ),
        ),
      );
    }
    
    return animations;
  }

  // ============================================================================
  // PERFORMANCE UTILITIES
  // ============================================================================
  
  /// Disposes multiple animation controllers safely
  static void disposeControllers(List<AnimationController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
  
  /// Creates a performance-optimized AnimatedBuilder
  static Widget createOptimizedAnimatedBuilder({
    required Animation<dynamic> animation,
    required Widget Function(BuildContext, Widget?) builder,
    Widget? child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

/// Mixin for components that need animation lifecycle management
mixin AnimationLifecycleMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  List<AnimationController> _controllers = [];
  
  /// Register an animation controller for automatic disposal
  void registerController(AnimationController controller) {
    _controllers.add(controller);
  }
  
  @override
  void dispose() {
    InputFieldAnimations.disposeControllers(_controllers);
    super.dispose();
  }
}