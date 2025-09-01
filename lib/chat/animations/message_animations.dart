import 'package:flutter/material.dart';

/// Reusable animation utilities for chat messages
/// Provides consistent animations across the chat system
class MessageAnimations {
  MessageAnimations._();

  // ============================================================================
  // SPRING PHYSICS CONFIGURATIONS
  // ============================================================================
  
  /// Light spring physics for subtle interactions
  static const SpringDescription lightSpring = SpringDescription(
    mass: 1.0,
    stiffness: 170.0,
    damping: 26.0,
  );
  
  /// Medium spring physics for standard interactions
  static const SpringDescription mediumSpring = SpringDescription(
    mass: 1.0,
    stiffness: 150.0,
    damping: 20.0,
  );
  
  /// Heavy spring physics for prominent interactions
  static const SpringDescription heavySpring = SpringDescription(
    mass: 1.5,
    stiffness: 120.0,
    damping: 15.0,
  );

  // ============================================================================
  // ANIMATION CURVES
  // ============================================================================
  
  /// Entrance animation curve
  static const Curve entranceCurve = Curves.easeOutBack;
  
  /// Exit animation curve
  static const Curve exitCurve = Curves.easeInBack;
  
  /// Scale animation curve
  static const Curve scaleCurve = Curves.easeInOut;
  
  /// Status change curve
  static const Curve statusCurve = Curves.elasticOut;
  
  /// Selection animation curve
  static const Curve selectionCurve = Curves.bounceOut;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================
  
  /// Fast animation duration for immediate feedback
  static const Duration fastDuration = Duration(milliseconds: 150);
  
  /// Standard animation duration for most interactions
  static const Duration standardDuration = Duration(milliseconds: 300);
  
  /// Slow animation duration for complex animations
  static const Duration slowDuration = Duration(milliseconds: 600);
  
  /// Entrance animation duration
  static const Duration entranceDuration = Duration(milliseconds: 800);

  // ============================================================================
  // ANIMATION BUILDERS
  // ============================================================================
  
  /// Create a scale animation controller
  static AnimationController createScaleController(TickerProvider vsync) {
    return AnimationController(
      duration: fastDuration,
      vsync: vsync,
    );
  }
  
  /// Create an entrance animation controller
  static AnimationController createEntranceController(TickerProvider vsync) {
    return AnimationController(
      duration: entranceDuration,
      vsync: vsync,
    );
  }
  
  /// Create a status animation controller
  static AnimationController createStatusController(TickerProvider vsync) {
    return AnimationController(
      duration: standardDuration,
      vsync: vsync,
    );
  }

  // ============================================================================
  // ANIMATION TWEENS
  // ============================================================================
  
  /// Scale animation tween
  static Tween<double> get scaleTween => Tween<double>(
    begin: 1.0,
    end: 0.96,
  );
  
  /// Entrance scale tween
  static Tween<double> get entranceScaleTween => Tween<double>(
    begin: 0.0,
    end: 1.0,
  );
  
  /// Entrance slide tween for sent messages
  static Tween<Offset> get sentMessageSlideTween => Tween<Offset>(
    begin: const Offset(0.3, 0),
    end: Offset.zero,
  );
  
  /// Entrance slide tween for received messages
  static Tween<Offset> get receivedMessageSlideTween => Tween<Offset>(
    begin: const Offset(-0.3, 0),
    end: Offset.zero,
  );
  
  /// Status indicator scale tween
  static Tween<double> get statusScaleTween => Tween<double>(
    begin: 0.0,
    end: 1.0,
  );
  
  /// Selection animation tween
  static Tween<double> get selectionTween => Tween<double>(
    begin: 1.0,
    end: 1.02,
  );

  // ============================================================================
  // PRESET ANIMATIONS
  // ============================================================================
  
  /// Create a complete entrance animation set
  static Map<String, Animation<double>> createEntranceAnimations({
    required AnimationController controller,
    required bool isSentMessage,
  }) {
    return {
      'scale': entranceScaleTween.animate(CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.8, curve: entranceCurve),
      )),
      'fade': Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      )),
    };
  }
  
  /// Create press animation
  static Animation<double> createPressAnimation(AnimationController controller) {
    return scaleTween.animate(CurvedAnimation(
      parent: controller,
      curve: scaleCurve,
    ));
  }
  
  /// Create status change animation
  static Animation<double> createStatusAnimation(AnimationController controller) {
    return statusScaleTween.animate(CurvedAnimation(
      parent: controller,
      curve: statusCurve,
    ));
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  /// Start entrance animation with delay
  static void startEntranceAnimation(
    AnimationController controller, {
    Duration delay = Duration.zero,
  }) async {
    await Future.delayed(delay);
    if (controller.isAnimating) return;
    controller.forward();
  }
  
  /// Animate status change
  static void animateStatusChange(AnimationController controller) {
    controller.reset();
    controller.forward();
  }
  
  /// Animate selection state
  static void animateSelection(
    AnimationController controller, {
    required bool isSelected,
  }) {
    if (isSelected) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }
  
  /// Create staggered animation delay
  static Duration getStaggeredDelay(int index, {
    Duration baseDelay = const Duration(milliseconds: 50),
  }) {
    return Duration(milliseconds: baseDelay.inMilliseconds * index);
  }

  // ============================================================================
  // ANIMATION PRESETS
  // ============================================================================
  
  /// Get animation configuration for message type
  static AnimationConfig getConfigForMessageType(MessageType messageType) {
    switch (messageType) {
      case MessageType.text:
        return const AnimationConfig(
          duration: standardDuration,
          curve: entranceCurve,
          stagger: Duration(milliseconds: 30),
        );
      case MessageType.image:
        return const AnimationConfig(
          duration: slowDuration,
          curve: Curves.easeOutQuart,
          stagger: Duration(milliseconds: 100),
        );
      case MessageType.file:
        return const AnimationConfig(
          duration: standardDuration,
          curve: Curves.easeOutCubic,
          stagger: Duration(milliseconds: 50),
        );
      case MessageType.voice:
        return const AnimationConfig(
          duration: slowDuration,
          curve: Curves.elasticOut,
          stagger: Duration(milliseconds: 80),
        );
      case MessageType.system:
        return const AnimationConfig(
          duration: fastDuration,
          curve: Curves.easeOut,
          stagger: Duration(milliseconds: 20),
        );
    }
  }
}

/// Message types for animation configuration
enum MessageType {
  text,
  image,
  file,
  voice,
  system,
}

/// Animation configuration class
class AnimationConfig {
  final Duration duration;
  final Curve curve;
  final Duration stagger;

  const AnimationConfig({
    required this.duration,
    required this.curve,
    required this.stagger,
  });
}

/// Typing indicator animation utilities
class TypingAnimations {
  TypingAnimations._();

  /// Create typing dots animation
  static List<AnimationController> createDotsControllers(
    TickerProvider vsync,
    int dotCount,
  ) {
    return List.generate(dotCount, (index) => AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    ));
  }

  /// Create dot animation with stagger
  static Animation<double> createDotAnimation(
    AnimationController controller,
    int index,
  ) {
    return Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  /// Start typing animation sequence
  static void startTypingSequence(List<AnimationController> controllers) async {
    while (controllers.first.isAnimating || controllers.first.status == AnimationStatus.forward) {
      for (int i = 0; i < controllers.length; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!controllers[i].isDismissed) {
          controllers[i].forward().then((_) {
            if (!controllers[i].isDismissed) {
              controllers[i].reverse();
            }
          });
        }
      }
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  /// Stop typing animation
  static void stopTypingSequence(List<AnimationController> controllers) {
    for (final controller in controllers) {
      if (!controller.isDismissed) {
        controller.stop();
        controller.reset();
      }
    }
  }
}

/// Custom animation transitions for chat
class ChatTransitions {
  ChatTransitions._();

  /// Slide and fade transition
  static Widget slideAndFade({
    required Widget child,
    required Animation<double> animation,
    required bool fromRight,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: fromRight ? const Offset(0.3, 0) : const Offset(-0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  /// Scale and fade transition
  static Widget scaleAndFade({
    required Widget child,
    required Animation<double> animation,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  /// Elastic scale transition
  static Widget elasticScale({
    required Widget child,
    required Animation<double> animation,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
      )),
      child: child,
    );
  }
}