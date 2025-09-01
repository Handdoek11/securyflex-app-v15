// lib/routing/route_transitions.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
}