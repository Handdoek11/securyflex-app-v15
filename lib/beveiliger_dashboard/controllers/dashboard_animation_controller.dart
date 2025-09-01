import 'package:flutter/material.dart';
import '../../core/shared_animation_controller.dart';

/// Manages all animations for the Beveiliger Dashboard
/// 
/// This controller extracts animation logic from the main dashboard,
/// reducing complexity and improving maintainability.
class DashboardAnimationController {
  late AnimationController mainController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  
  final TickerProvider vsync;
  final AnimationController? providedController;
  
  DashboardAnimationController({
    required this.vsync,
    this.providedController,
  });
  
  void initialize() {
    // Use provided controller or create shared one
    if (providedController != null) {
      mainController = providedController!;
      debugPrint('🔧 Dashboard: Using provided animation controller');
    } else {
      mainController = SharedAnimationController.instance.getController(
        SharedControllerKeys.dashboardPulse,
        'dashboard_main',
        vsync,
        duration: const Duration(milliseconds: 600),
      );
      debugPrint('🔧 Dashboard: Using shared animation controller');
    }
    
    // Initialize animations
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: mainController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: mainController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));
    
    // Start animation
    mainController.forward();
  }
  
  void dispose() {
    if (providedController == null) {
      SharedAnimationController.instance.releaseController(
        'dashboard_main',
        SharedControllerKeys.dashboardPulse,
      );
    }
  }
  
  // Getters for animations
  AnimationController get controller => mainController;
  Animation<double> get fade => fadeAnimation;
  Animation<Offset> get slide => slideAnimation;
}