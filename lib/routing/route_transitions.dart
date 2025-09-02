// lib/routing/route_transitions.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

/// Custom route transitions for GoRouter
class RouteTransitions {
  /// Slide transition from right to left (iOS style)
  static CustomTransitionPage slideTransition({
    required Widget child,
    required String name,
  }) {
    return CustomTransitionPage(
      name: name,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Fade transition
  static CustomTransitionPage fadeTransition({
    required Widget child,
    required String name,
  }) {
    return CustomTransitionPage(
      name: name,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  /// Scale transition (for modals)
  static CustomTransitionPage scaleTransition({
    required Widget child,
    required String name,
  }) {
    return CustomTransitionPage(
      name: name,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.95;
        const end = 1.0;
        const curve = Curves.easeOutBack;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// Slide up transition (for bottom sheets)
  static CustomTransitionPage slideUpTransition({
    required Widget child,
    required String name,
  }) {
    return CustomTransitionPage(
      name: name,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// No transition (instant)
  static NoTransitionPage noTransition({
    required Widget child,
    required String name,
  }) {
    return NoTransitionPage(
      name: name,
      child: child,
    );
  }

  /// Premium glassmorphic auth transition - elegant slide with blur effect
  static CustomTransitionPage authGlassTransition({
    required Widget child,
    required String name,
    AuthTransitionDirection direction = AuthTransitionDirection.forward,
  }) {
    return CustomTransitionPage(
      name: name,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideBegin = direction == AuthTransitionDirection.forward 
            ? const Offset(1.2, 0.0)  // From right
            : const Offset(-1.2, 0.0); // From left
        const slideEnd = Offset.zero;
        
        // Premium easing curve for premium feel
        const curve = Curves.easeOutQuint;

        // Slide animation
        final slideTween = Tween(begin: slideBegin, end: slideEnd)
            .chain(CurveTween(curve: curve));

        // Scale animation for depth
        final scaleTween = Tween(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: curve));

        // Opacity animation
        final opacityTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: curve));

        // Blur animation for glassmorphic effect
        final blurTween = Tween(begin: 20.0, end: 0.0)
            .chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(slideTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: FadeTransition(
              opacity: animation.drive(opacityTween),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: animation.drive(blurTween).value,
                      sigmaY: animation.drive(blurTween).value,
                    ),
                    child: child!,
                  );
                },
                child: child,
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 450),
    );
  }

  /// Progressive step transition - smooth flow between registration steps
  static CustomTransitionPage progressiveStepTransition({
    required Widget child,
    required String name,
    ProgressDirection direction = ProgressDirection.next,
  }) {
    return CustomTransitionPage(
      name: name,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Different animations based on direction
        late Offset slideBegin;
        late Offset slideEnd;
        
        switch (direction) {
          case ProgressDirection.next:
            slideBegin = const Offset(0.8, 0.0);
            slideEnd = Offset.zero;
            break;
          case ProgressDirection.previous:
            slideBegin = const Offset(-0.8, 0.0);
            slideEnd = Offset.zero;
            break;
        }

        // Smooth progressive curve
        const curve = Curves.easeOutCubic;

        // Multi-layered animation for premium feel
        final slideTween = Tween(begin: slideBegin, end: slideEnd)
            .chain(CurveTween(curve: curve));

        final scaleTween = Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: curve));

        final opacityTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        // Subtle rotation for dynamic feel
        final rotationTween = Tween(begin: direction == ProgressDirection.next ? 0.005 : -0.005, end: 0.0)
            .chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(slideTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: RotationTransition(
              turns: animation.drive(rotationTween),
              child: FadeTransition(
                opacity: animation.drive(opacityTween),
                child: child,
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Success completion animation - celebratory transition
  static CustomTransitionPage successCompletionTransition({
    required Widget child,
    required String name,
  }) {
    return CustomTransitionPage(
      name: name,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Bouncy success animation
        const curve = Curves.elasticOut;
        
        final scaleTween = Tween(begin: 0.5, end: 1.0)
            .chain(CurveTween(curve: curve));

        final opacityTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        // Subtle bounce rotation
        final rotationTween = Tween(begin: 0.05, end: 0.0)
            .chain(CurveTween(curve: curve));

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: RotationTransition(
            turns: animation.drive(rotationTween),
            child: FadeTransition(
              opacity: animation.drive(opacityTween),
              child: child,
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 800),
    );
  }

  /// Morphing glassmorphic transition - perfect for auth flow
  static CustomTransitionPage morphingGlassTransition({
    required Widget child,
    required String name,
  }) {
    return CustomTransitionPage(
      name: name,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Complex morphing animation
        const curve = Curves.easeInOutQuart;
        
        // Scale with overshoot for premium feel
        final scaleTween = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.8, end: 1.05),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.05, end: 1.0),
            weight: 40,
          ),
        ]).chain(CurveTween(curve: curve));

        // Opacity with soft ease
        final opacityTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        // Blur morphing for glassmorphic effect
        final blurTween = Tween(begin: 25.0, end: 0.0)
            .chain(CurveTween(curve: curve));

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(opacityTween),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: animation.drive(blurTween).value * 0.5,
                    sigmaY: animation.drive(blurTween).value * 0.5,
                  ),
                  child: child!,
                );
              },
              child: child,
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 750),
    );
  }
}

/// Direction for auth transitions
enum AuthTransitionDirection {
  forward,
  backward,
}

/// Direction for progressive step transitions
enum ProgressDirection {
  next,
  previous,
}