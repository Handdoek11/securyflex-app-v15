import 'package:flutter/material.dart';

/// Unified Components System for SecuryFlex
/// 
/// This file provides a single import point for all unified components,
/// ensuring consistent usage across the entire application.
/// 
/// Usage:
/// ```dart
/// import 'package:securyflex_app/core/unified_components.dart';
/// 
/// // All components are available:
/// UnifiedHeader.simple(title: 'Dashboard'),
/// UnifiedButton.primary(text: 'Opslaan', onPressed: () {}),
/// UnifiedCard.standard(child: Text('Content')),
/// UnifiedInput.email(label: 'E-mailadres'),
/// UnifiedDialog.showAlert(...),
/// ```

// Core design system
export '../unified_design_tokens.dart';
export '../unified_theme_system.dart';

// Core components
export '../unified_header.dart';
export '../unified_buttons.dart';
export '../unified_card_system.dart';
export '../unified_input_system.dart';
export '../unified_dialog_system.dart';

// Additional unified systems
export '../unified_status_colors.dart';
export '../unified_shadows.dart';
export '../unified_navigation_system.dart';

// Specialized components from unified_components directory
export '../unified_components/unified_dashboard_card.dart';
export '../unified_components/consistent_card_layout.dart';
export '../unified_components/smart_tab_bar.dart';
export '../unified_components/optimized_tab_controller.dart';
export '../unified_components/expandable_text.dart';

/// Unified Components Library Information
class UnifiedComponents {
  static const String version = '2.0.0';
  static const String description = 'SecuryFlex Unified Components System';
  
  /// Get list of all available components
  static List<String> get availableComponents => [
    'UnifiedHeader',
    'UnifiedButton',
    'UnifiedCard',
    'UnifiedInput',
    'UnifiedDialog',
    'UnifiedDashboardCard',
    'ConsistentCardLayout',
    'SmartTabBar',
    'OptimizedTabController',
    'ExpandableText',
  ];
  
  /// Component usage guidelines
  static Map<String, String> get usageGuidelines => {
    'UnifiedHeader': 'Use for all app bar headers with role-based theming',
    'UnifiedButton': 'Use for all interactive buttons with consistent styling',
    'UnifiedCard': 'Use for all content containers with proper elevation',
    'UnifiedInput': 'Use for all form inputs with validation support',
    'UnifiedDialog': 'Use for all modal dialogs with proper responsive behavior',
  };
  
  /// Component migration checklist
  static List<String> get migrationChecklist => [
    'Replace all AppBar widgets with UnifiedHeader',
    'Replace all ElevatedButton/TextButton widgets with UnifiedButton',
    'Replace all Card widgets with UnifiedCard',
    'Replace all TextFormField widgets with UnifiedInput',
    'Replace all showDialog calls with UnifiedDialog.show',
    'Update all hardcoded colors to use DesignTokens',
    'Apply role-based theming to all components',
  ];
}

/// Component validation utilities
class UnifiedComponentValidator {
  /// Validate that all components in a widget tree use unified components
  static bool validateWidgetTree(Widget widget) {
    // TODO: Implement widget tree validation
    // This would recursively check if any non-unified components are used
    return true;
  }
  
  /// Get recommendations for component usage improvements
  static List<String> getRecommendations(Widget widget) {
    // TODO: Implement recommendation engine
    // This would analyze component usage and suggest improvements
    return [];
  }
}

/// Development utilities for unified components
class UnifiedComponentDev {
  /// Enable debug mode for component development
  static bool debugMode = false;
  
  /// Log component usage for analytics
  static void logComponentUsage(String componentName, Map<String, dynamic> props) {
    if (debugMode) {
      print('UnifiedComponent: $componentName used with props: $props');
    }
  }
  
  /// Validate component props at development time
  static bool validateProps(String componentName, Map<String, dynamic> props) {
    // TODO: Implement prop validation
    return true;
  }
}