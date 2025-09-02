import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';

/// Card variant enumeration - Simplified for mobile-first design
enum UnifiedCardVariant {
  /// Compact card for metrics display with minimal padding
  compact,
  /// Standard card for regular content with mobile-optimized padding
  standard,
  /// Featured card with gradient support for revenue and highlights
  featured,
}

/// Unified Card Component for SecuryFlex - Mobile-First Design
///
/// A streamlined card component optimized for mobile touch interactions
/// with 3 essential variants for different use cases.
///
/// Features:
/// - Mobile-optimized spacing and touch targets
/// - 3 essential variants: compact, standard, featured
/// - Role-based color theming
/// - Gradient support for featured cards
/// - Accessibility support
/// - Custom content support
class UnifiedCard extends StatelessWidget {
  /// Card variant determines the styling
  final UnifiedCardVariant variant;
  
  /// Child widget to display inside the card
  final Widget child;
  
  /// Custom padding override
  final EdgeInsetsGeometry? padding;
  
  /// Custom margin override
  final EdgeInsetsGeometry? margin;
  
  /// Custom background color override
  final Color? backgroundColor;
  
  /// Custom border radius override
  final BorderRadius? borderRadius;
  
  /// Custom elevation override
  final double? elevation;
  
  /// Whether the card should be clickable
  final bool isClickable;
  
  /// Callback for card tap
  final VoidCallback? onTap;
  
  /// User role for theming
  final UserRole? userRole;
  
  /// Custom width
  final double? width;
  
  /// Custom height
  final double? height;
  
  /// Gradient colors (for featured variant)
  final List<Color>? gradientColors;

  const UnifiedCard({
    super.key,
    this.variant = UnifiedCardVariant.standard,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.elevation,
    this.isClickable = false,
    this.onTap,
    this.userRole,
    this.width,
    this.height,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getColorScheme(context);

    final cardDecoration = _getCardDecoration(context, colorScheme);
    final cardPadding = padding ?? _getVariantPadding();
    final cardMargin = margin ?? EdgeInsets.all(DesignTokens.spacingS);

    Widget cardContent = Container(
      width: width,
      height: height,
      margin: cardMargin,
      decoration: cardDecoration,
      child: Padding(
        padding: cardPadding,
        child: _buildCardContent(),
      ),
    );

    // Add interaction if clickable
    if (isClickable && onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusCard),
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  /// Get mobile-optimized padding based on variant
  EdgeInsetsGeometry _getVariantPadding() {
    switch (variant) {
      case UnifiedCardVariant.compact:
        return EdgeInsets.all(DesignTokens.spacingM); // 12px for metrics
      case UnifiedCardVariant.standard:
        return EdgeInsets.all(DesignTokens.spacingL); // 16px for content
      case UnifiedCardVariant.featured:
        return EdgeInsets.all(DesignTokens.spacingL); // 16px for featured content
    }
  }

  /// Build card content - simplified for mobile-first design
  Widget _buildCardContent() {
    return child;
  }

  /// Get the appropriate color scheme based on user role
  ColorScheme _getColorScheme(BuildContext context) {
    if (userRole != null) {
      return SecuryFlexTheme.getColorScheme(userRole!);
    }
    return Theme.of(context).colorScheme;
  }

  /// Get card decoration based on variant and theme - Mobile-optimized
  BoxDecoration _getCardDecoration(BuildContext context, ColorScheme colorScheme) {
    switch (variant) {
      case UnifiedCardVariant.compact:
        return BoxDecoration(
          color: backgroundColor ?? colorScheme.surface,
          borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusCard),
          boxShadow: [DesignTokens.shadowLight],
        );

      case UnifiedCardVariant.standard:
        return BoxDecoration(
          color: backgroundColor ?? colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusCard),
          boxShadow: [DesignTokens.shadowMedium],
        );

      case UnifiedCardVariant.featured:
        final colors = gradientColors ?? [
          colorScheme.primary,
          colorScheme.primary.withValues(alpha: 0.8),
        ];
        return BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusCard),
          boxShadow: [
            DesignTokens.shadowMedium.copyWith(
              color: colors.first.withValues(alpha: 0.3),
            ),
          ],
        );
    }
  }

  /// Static factory method for compact cards - optimized for metrics display
  static UnifiedCard compact({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    bool isClickable = false,
    VoidCallback? onTap,
    UserRole? userRole,
  }) {
    return UnifiedCard(
      variant: UnifiedCardVariant.compact,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      isClickable: isClickable,
      onTap: onTap,
      userRole: userRole,
      child: child,
    );
  }

  /// Static factory method for standard cards - mobile-optimized for regular content
  static UnifiedCard standard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    bool isClickable = false,
    VoidCallback? onTap,
    UserRole? userRole,
  }) {
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      isClickable: isClickable,
      onTap: onTap,
      userRole: userRole,
      child: child,
    );
  }

  /// Static factory method for featured cards - supports gradient backgrounds for revenue cards
  static UnifiedCard featured({
    required Widget child,
    List<Color>? gradientColors,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool isClickable = false,
    VoidCallback? onTap,
    UserRole? userRole,
  }) {
    return UnifiedCard(
      variant: UnifiedCardVariant.featured,
      padding: padding,
      margin: margin,
      gradientColors: gradientColors,
      isClickable: isClickable,
      onTap: onTap,
      userRole: userRole,
      child: child,
    );
  }
}
