import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';
import '../unified_card_system.dart';

/// Modern, performance-optimized dashboard card
/// 
/// This is the foundation card for all dashboard widgets.
/// Designed with maximum 3 nesting levels and consolidated styling.
/// 
/// Features:
/// - Performance-first architecture (max 3 levels)
/// - Consolidated padding and margins
/// - Role-based theming
/// - Material 3 compliance
/// - Future glassmorphism ready
class UnifiedDashboardCard extends StatelessWidget {
  /// Card title
  final String? title;
  
  /// Card subtitle
  final String? subtitle;
  
  /// Main content widget
  final Widget child;
  
  /// User role for theming
  final UserRole userRole;
  
  /// Card variant
  final DashboardCardVariant variant;
  
  /// Custom padding (overrides default)
  final EdgeInsets? padding;
  
  /// Custom margin (overrides default)
  final EdgeInsets? margin;
  
  /// Action button
  final Widget? action;
  
  /// Tap callback
  final VoidCallback? onTap;
  
  /// Loading state
  final bool isLoading;
  
  /// Error state
  final String? errorMessage;

  const UnifiedDashboardCard({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    required this.userRole,
    this.variant = DashboardCardVariant.standard,
    this.padding,
    this.margin,
    this.action,
    this.onTap,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    
    // Handle error state
    if (errorMessage != null) {
      return _buildErrorCard(colorScheme);
    }
    
    // Handle loading state
    if (isLoading) {
      return _buildLoadingCard(colorScheme);
    }
    
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      userRole: userRole,
      margin: margin ?? _getDefaultMargin(),
      padding: padding ?? _getDefaultPadding(),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header section (if title provided)
          if (title != null) _buildHeader(colorScheme),
          // Content section
          child,
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title!,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontSize: DesignTokens.fontSizeBodyLarge,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightRegular,
                      fontSize: DesignTokens.fontSizeBody,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }

  Widget _buildErrorCard(ColorScheme colorScheme) {
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      userRole: userRole,
      margin: margin ?? _getDefaultMargin(),
      padding: padding ?? _getDefaultPadding(),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: DesignTokens.colorError,
            size: DesignTokens.iconSizeL,
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Fout bij laden',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontSize: DesignTokens.fontSizeBody,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            errorMessage!,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightRegular,
              fontSize: DesignTokens.fontSizeS,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(ColorScheme colorScheme) {
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      userRole: userRole,
      margin: margin ?? _getDefaultMargin(),
      padding: padding ?? _getDefaultPadding(),
      child: Column(
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 2.0,
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Laden...',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightRegular,
              fontSize: DesignTokens.fontSizeBody,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  EdgeInsets _getDefaultMargin() {
    switch (variant) {
      case DashboardCardVariant.compact:
        return EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        );
      case DashboardCardVariant.standard:
        return EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingL,
          vertical: DesignTokens.spacingM,
        );
      case DashboardCardVariant.featured:
        return EdgeInsets.all(DesignTokens.spacingL);
    }
  }

  EdgeInsets _getDefaultPadding() {
    switch (variant) {
      case DashboardCardVariant.compact:
        return EdgeInsets.all(DesignTokens.spacingM);
      case DashboardCardVariant.standard:
        return EdgeInsets.all(DesignTokens.spacingL);
      case DashboardCardVariant.featured:
        return EdgeInsets.all(DesignTokens.spacingXL);
    }
  }
}

/// Dashboard card variants
enum DashboardCardVariant {
  /// Compact card for dense layouts
  compact,
  /// Standard card for most use cases
  standard,
  /// Featured card for important content
  featured,
}

/// Factory methods for common dashboard cards
extension UnifiedDashboardCardFactory on UnifiedDashboardCard {
  /// Create a stats card
  static UnifiedDashboardCard stats({
    required String title,
    required String value,
    required UserRole userRole,
    String? subtitle,
    Widget? icon,
    VoidCallback? onTap,
  }) {
    return UnifiedDashboardCard(
      title: title,
      subtitle: subtitle,
      userRole: userRole,
      variant: DashboardCardVariant.compact,
      onTap: onTap,
      child: Row(
        children: [
          if (icon != null) ...[
            icon,
            SizedBox(width: DesignTokens.spacingM),
          ],
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightBold,
                fontSize: DesignTokens.fontSizeDisplay,
                color: SecuryFlexTheme.getColorScheme(userRole).primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Create an action card
  static UnifiedDashboardCard action({
    required String title,
    required Widget child,
    required UserRole userRole,
    String? subtitle,
    Widget? action,
    VoidCallback? onTap,
  }) {
    return UnifiedDashboardCard(
      title: title,
      subtitle: subtitle,
      userRole: userRole,
      variant: DashboardCardVariant.standard,
      action: action,
      onTap: onTap,
      child: child,
    );
  }
}
