/// 🎯 **GUARD SPACING UTILITIES - 2025 FLUTTER BEST PRACTICES**
/// 
/// Semantic spacing components for SecuryFlex Guards application
/// Implements ULTRATHINK multi-agent optimization recommendations
/// 
/// Features:
/// - Const constructors for optimal performance
/// - Semantic naming for better code readability
/// - Design token compliance for consistency
/// - Responsive spacing patterns for adaptive UX
/// - Accessibility-aware spacing adjustments

import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';

/// 🏗️ **GUARD SPACING UTILITY CLASS**
/// 
/// Provides semantic, performance-optimized spacing widgets
/// for the Guards (Beveiliger) application modules.
/// 
/// Usage Examples:
/// ```dart
/// // Dashboard bottom spacing
/// GuardSpacing.dashboardBottom,
/// 
/// // Section gaps
/// GuardSpacing.sectionGap,
/// 
/// // Item spacing
/// GuardSpacing.itemSpacing,
/// 
/// // Responsive spacing
/// GuardSpacing.responsiveBottom(context),
/// ```
class GuardSpacing {
  // Private constructor to prevent instantiation
  GuardSpacing._();

  /// 📱 **SEMANTIC SPACING CONSTANTS**
  
  /// Bottom spacing for dashboard content (24px)
  /// Used at the end of scrollable dashboard content
  static const Widget dashboardBottom = SizedBox(height: DesignTokens.spacingL);
  
  /// Gap between major dashboard sections (16px)
  /// Used between dashboard cards and sections
  static const Widget sectionGap = SizedBox(height: DesignTokens.spacingM);
  
  /// Spacing between list items (8px)
  /// Used between notification items, certificate items, etc.
  static const Widget itemSpacing = SizedBox(height: DesignTokens.spacingS);
  
  /// Small spacing for compact layouts (4px)
  /// Used in dense information displays
  static const Widget compactSpacing = const SizedBox(height: DesignTokens.spacingXS);
  
  /// Large spacing for major separations (32px)
  /// Used between major content blocks
  static const Widget majorSeparation = const SizedBox(height: DesignTokens.spacingXL);

  /// 📐 **HORIZONTAL SPACING CONSTANTS**
  
  /// Standard horizontal spacing (16px)
  static const Widget horizontalGap = const SizedBox(width: DesignTokens.spacingM);
  
  /// Small horizontal spacing (8px)
  static const Widget horizontalSmall = const SizedBox(width: DesignTokens.spacingS);
  
  /// Large horizontal spacing (24px)
  static const Widget horizontalLarge = const SizedBox(width: DesignTokens.spacingL);

  /// 📱 **RESPONSIVE SPACING METHODS**
  
  /// Responsive bottom spacing that adapts to screen size
  /// 
  /// Returns:
  /// - 36px on large screens (>1024px width)
  /// - 30px on tablets (768-1024px width)  
  /// - 24px on mobile (<768px width)
  static Widget responsiveBottom(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 1024) {
      // Large screens (desktop)
      return const SizedBox(height: DesignTokens.spacingXL * 1.125); // 36px
    } else if (screenWidth > 768) {
      // Tablets
      return const SizedBox(height: DesignTokens.spacingL * 1.25); // 30px
    } else {
      // Mobile
      return dashboardBottom; // 24px
    }
  }
  
  /// Responsive section gap that adapts to screen size
  /// 
  /// Returns:
  /// - 24px on large screens
  /// - 20px on tablets
  /// - 16px on mobile
  static Widget responsiveSectionGap(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 1024) {
      return const SizedBox(height: DesignTokens.spacingL); // 24px
    } else if (screenWidth > 768) {
      return const SizedBox(height: DesignTokens.spacingM * 1.25); // 20px
    } else {
      return sectionGap; // 16px
    }
  }

  /// ♿ **ACCESSIBILITY-AWARE SPACING**
  
  /// Spacing that adjusts based on user's text scale factor
  /// Ensures adequate spacing for users with larger text sizes
  static Widget accessibleBottom(BuildContext context) {
    final textScaler = MediaQuery.of(context).textScaler;
    final textScaleFactor = textScaler.scale(1.0);
    
    // Adjust spacing based on text scale (max 1.5x increase)
    final adjustmentFactor = 1 + ((textScaleFactor - 1) * 0.5).clamp(0.0, 0.5);
    final adjustedHeight = DesignTokens.spacingL * adjustmentFactor;
    
    return SizedBox(height: adjustedHeight);
  }
  
  /// Touch-friendly spacing for interactive elements
  /// Ensures minimum 44px spacing for accessibility compliance
  static Widget touchFriendlyGap(BuildContext context) {
    const minTouchSpacing = 44.0;
    final currentSpacing = DesignTokens.spacingL;
    
    return SizedBox(height: currentSpacing < minTouchSpacing ? minTouchSpacing : currentSpacing);
  }

  /// 🎨 **CONTEXTUAL SPACING METHODS**
  
  /// Spacing for error states and alerts
  static const Widget errorSpacing = const SizedBox(height: DesignTokens.spacingM);
  
  /// Spacing for loading states
  static const Widget loadingSpacing = const SizedBox(height: DesignTokens.spacingS);
  
  /// Spacing for form elements
  static const Widget formFieldSpacing = const SizedBox(height: DesignTokens.spacingM);
  
  /// Spacing for button groups
  static const Widget buttonGroupSpacing = const SizedBox(height: DesignTokens.spacingS);

  /// 🔧 **UTILITY METHODS**
  
  /// Create custom spacing with design token validation
  /// 
  /// Ensures spacing values align with design system
  static Widget custom(double height) {
    // Validate against design tokens
    const validSpacings = [
      DesignTokens.spacingXS,  // 4px
      DesignTokens.spacingS,   // 8px
      DesignTokens.spacingM,   // 16px
      DesignTokens.spacingL,   // 24px
      DesignTokens.spacingXL,  // 32px
    ];
    
    // Find closest valid spacing
    double closestSpacing = validSpacings.reduce((a, b) => 
        (a - height).abs() < (b - height).abs() ? a : b);
    
    // Warn in debug mode if spacing doesn't match design tokens
    assert(() {
      if (height != closestSpacing) {
        debugPrint('⚠️ GuardSpacing: Custom spacing $height doesn\'t match design tokens. '
                  'Consider using $closestSpacing instead.');
      }
      return true;
    }());
    
    return SizedBox(height: height);
  }
  
  /// Create horizontal custom spacing
  static Widget customHorizontal(double width) {
    return SizedBox(width: width);
  }

  /// 📊 **PERFORMANCE MONITORING**
  
  /// Track spacing usage for performance optimization
  static void trackSpacingUsage(String spacingType) {
    assert(() {
      debugPrint('📊 GuardSpacing: Using $spacingType spacing');
      return true;
    }());
  }
}

/// 🎯 **SPACING TYPE ENUM**
/// 
/// Defines semantic spacing types for better code organization
enum GuardSpacingType {
  dashboardBottom,
  sectionGap,
  itemSpacing,
  compactSpacing,
  majorSeparation,
  horizontalGap,
  horizontalSmall,
  horizontalLarge,
  errorSpacing,
  loadingSpacing,
  formFieldSpacing,
  buttonGroupSpacing,
}

/// 🏗️ **SPACING BUILDER EXTENSION**
/// 
/// Extension methods for easier spacing usage
extension GuardSpacingExtension on GuardSpacingType {
  Widget get widget {
    switch (this) {
      case GuardSpacingType.dashboardBottom:
        return GuardSpacing.dashboardBottom;
      case GuardSpacingType.sectionGap:
        return GuardSpacing.sectionGap;
      case GuardSpacingType.itemSpacing:
        return GuardSpacing.itemSpacing;
      case GuardSpacingType.compactSpacing:
        return GuardSpacing.compactSpacing;
      case GuardSpacingType.majorSeparation:
        return GuardSpacing.majorSeparation;
      case GuardSpacingType.horizontalGap:
        return GuardSpacing.horizontalGap;
      case GuardSpacingType.horizontalSmall:
        return GuardSpacing.horizontalSmall;
      case GuardSpacingType.horizontalLarge:
        return GuardSpacing.horizontalLarge;
      case GuardSpacingType.errorSpacing:
        return GuardSpacing.errorSpacing;
      case GuardSpacingType.loadingSpacing:
        return GuardSpacing.loadingSpacing;
      case GuardSpacingType.formFieldSpacing:
        return GuardSpacing.formFieldSpacing;
      case GuardSpacingType.buttonGroupSpacing:
        return GuardSpacing.buttonGroupSpacing;
    }
  }
}

/// 📱 **ADAPTIVE SPACING WIDGET**
/// 
/// Advanced spacing widget that adapts to context
class AdaptiveGuardSpacing extends StatelessWidget {
  final GuardSpacingType type;
  final bool enableAccessibility;
  final bool enableResponsive;
  
  const AdaptiveGuardSpacing({
    super.key,
    required this.type,
    this.enableAccessibility = true,
    this.enableResponsive = true,
  });
  
  /// Named constructor for dashboard bottom spacing
  const AdaptiveGuardSpacing.dashboardBottom({
    super.key,
    this.enableAccessibility = true,
    this.enableResponsive = true,
  }) : type = GuardSpacingType.dashboardBottom;
  
  @override
  Widget build(BuildContext context) {
    Widget spacing = type.widget;
    
    // Apply responsive adjustments
    if (enableResponsive && type == GuardSpacingType.dashboardBottom) {
      spacing = GuardSpacing.responsiveBottom(context);
    } else if (enableResponsive && type == GuardSpacingType.sectionGap) {
      spacing = GuardSpacing.responsiveSectionGap(context);
    }
    
    // Apply accessibility adjustments
    if (enableAccessibility && type == GuardSpacingType.dashboardBottom) {
      spacing = GuardSpacing.accessibleBottom(context);
    }
    
    return spacing;
  }
}

/// 🎯 **USAGE EXAMPLES**
/// 
/// ```dart
/// // Basic usage
/// GuardSpacing.dashboardBottom,
/// 
/// // Responsive usage
/// GuardSpacing.responsiveBottom(context),
/// 
/// // Accessibility-aware usage
/// GuardSpacing.accessibleBottom(context),
/// 
/// // Adaptive widget usage
/// const AdaptiveGuardSpacing.dashboardBottom(),
/// 
/// // Extension usage
/// GuardSpacingType.sectionGap.widget,
/// ```
