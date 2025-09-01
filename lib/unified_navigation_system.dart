import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_components/premium_glass_system.dart';

/// Navigation item data
class UnifiedNavigationItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final Widget? badge;
  final VoidCallback? onTap;

  const UnifiedNavigationItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.badge,
    this.onTap,
  });
}

/// Bottom navigation bar variant enumeration
enum UnifiedBottomNavVariant {
  /// Standard bottom navigation with labels
  standard,
  /// Compact bottom navigation without labels
  compact,
  /// Floating bottom navigation with rounded corners
  floating,
}

/// Unified Bottom Navigation Component for SecuryFlex
/// 
/// A standardized bottom navigation component that provides consistent
/// styling and behavior across all modules while supporting different
/// variants and role-based theming.
/// 
/// Features:
/// - Consistent styling using DesignTokens
/// - Multiple navigation variants
/// - Role-based color theming
/// - Badge support for notifications
/// - Smooth animations
/// - Accessibility compliance
class UnifiedBottomNavigation extends StatelessWidget {
  /// Navigation variant determines the styling
  final UnifiedBottomNavVariant variant;
  
  /// List of navigation items
  final List<UnifiedNavigationItem> items;
  
  /// Currently selected index
  final int selectedIndex;
  
  /// Callback when item is selected
  final void Function(int index)? onItemSelected;
  
  /// User role for theming
  final UserRole? userRole;
  
  /// Custom background color
  final Color? backgroundColor;
  
  /// Custom elevation
  final double? elevation;
  
  /// Whether to show labels
  final bool showLabels;

  const UnifiedBottomNavigation({
    super.key,
    this.variant = UnifiedBottomNavVariant.standard,
    required this.items,
    required this.selectedIndex,
    this.onItemSelected,
    this.userRole,
    this.backgroundColor,
    this.elevation,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = _getColorScheme(context);
    
    switch (variant) {
      case UnifiedBottomNavVariant.standard:
        return _buildStandardNavigation(context, theme, colorScheme);
      case UnifiedBottomNavVariant.compact:
        return _buildCompactNavigation(context, theme, colorScheme);
      case UnifiedBottomNavVariant.floating:
        return _buildFloatingNavigation(context, theme, colorScheme);
    }
  }

  /// Get the appropriate color scheme based on user role
  ColorScheme _getColorScheme(BuildContext context) {
    if (userRole != null) {
      return SecuryFlexTheme.getColorScheme(userRole!);
    }
    return Theme.of(context).colorScheme;
  }

  Widget _buildStandardNavigation(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    // Glass effect based on role
    final isGuard = userRole == UserRole.guard;
    final tintColor = backgroundColor ?? colorScheme.primary;
    
    return PremiumGlassContainer(
      intensity: isGuard ? GlassIntensity.subtle : GlassIntensity.standard,
      elevation: GlassElevation.floating,
      tintColor: tintColor,
      enableTrustBorder: true,
      borderRadius: BorderRadius.zero,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Container(
          height: 70,  // Reduced from 80 to 70
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,  // Reduced horizontal padding
            vertical: DesignTokens.spacingXS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == selectedIndex;
              
              return Expanded(
                child: _buildNavigationItem(
                  context,
                  theme,
                  colorScheme,
                  item,
                  isSelected,
                  index,
                  showLabels: showLabels,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactNavigation(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    // Consistent glass effect
    final isGuard = userRole == UserRole.guard;
    final glassColor = isGuard 
        ? colorScheme.primary.withValues(alpha: 0.02)
        : backgroundColor ?? colorScheme.surface;
    
    return Container(
      decoration: BoxDecoration(
        color: glassColor,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 56,  // Compact height
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: DesignTokens.spacingXS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == selectedIndex;
              
              return _buildNavigationItem(
                context,
                theme,
                colorScheme,
                item,
                isSelected,
                index,
                showLabels: false,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavigation(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    // Glass effect for floating variant
    final isGuard = userRole == UserRole.guard;
    final glassColor = isGuard 
        ? colorScheme.primary.withValues(alpha: 0.03)  // Slightly more visible for floating
        : backgroundColor ?? colorScheme.surface;
    
    return Positioned(
      bottom: DesignTokens.spacingM,
      left: DesignTokens.spacingM,
      right: DesignTokens.spacingM,
      child: Container(
        decoration: BoxDecoration(
          color: glassColor,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          height: 65,  // Consistent with standard height
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == selectedIndex;
              
              return _buildNavigationItem(
                context,
                theme,
                colorScheme,
                item,
                isSelected,
                index,
                showLabels: false,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    UnifiedNavigationItem item,
    bool isSelected,
    int index, {
    required bool showLabels,
  }) {
    final iconColor = isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final textColor = isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        onTap: () {
          onItemSelected?.call(index);
          item.onTap?.call();
        },
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          // Ensure minimum 48x48 touch target
          constraints: BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: DesignTokens.spacingS,  // Increased from spacingXS
          ),
          decoration: BoxDecoration(
            // Subtle background for active state
            color: isSelected 
                ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Animated scale for active state
                  AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: DesignTokens.durationFast,
                    child: AnimatedSwitcher(
                      duration: DesignTokens.durationFast,
                      child: Icon(
                        isSelected && item.activeIcon != null ? item.activeIcon! : item.icon,
                        key: ValueKey(isSelected),
                        color: iconColor,
                        size: 24,  // Increased for better touch target
                      ),
                    ),
                  ),
                  if (item.badge != null)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: DesignTokens.colorError,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
              if (showLabels) ...[
                SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: DesignTokens.durationFast,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,  // Slightly larger for better readability
                    fontWeight: isSelected
                        ? DesignTokens.fontWeightMedium  // Less bold for subtlety
                        : DesignTokens.fontWeightRegular,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Static factory method for standard bottom navigation
  static UnifiedBottomNavigation standard({
    required List<UnifiedNavigationItem> items,
    required int selectedIndex,
    void Function(int index)? onItemSelected,
    UserRole? userRole,
    bool showLabels = true,
  }) {
    return UnifiedBottomNavigation(
      variant: UnifiedBottomNavVariant.standard,
      items: items,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      userRole: userRole,
      showLabels: showLabels,
    );
  }

  /// Static factory method for compact bottom navigation
  static UnifiedBottomNavigation compact({
    required List<UnifiedNavigationItem> items,
    required int selectedIndex,
    void Function(int index)? onItemSelected,
    UserRole? userRole,
  }) {
    return UnifiedBottomNavigation(
      variant: UnifiedBottomNavVariant.compact,
      items: items,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      userRole: userRole,
      showLabels: false,
    );
  }

  /// Static factory method for floating bottom navigation
  static UnifiedBottomNavigation floating({
    required List<UnifiedNavigationItem> items,
    required int selectedIndex,
    void Function(int index)? onItemSelected,
    UserRole? userRole,
  }) {
    return UnifiedBottomNavigation(
      variant: UnifiedBottomNavVariant.floating,
      items: items,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      userRole: userRole,
      showLabels: false,
    );
  }
}

/// Unified Badge Component for navigation items
class UnifiedBadge extends StatelessWidget {
  final String? text;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showDot;

  const UnifiedBadge({
    super.key,
    this.text,
    this.backgroundColor,
    this.textColor,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (showDot && (text == null || text!.isEmpty)) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.error,
          shape: BoxShape.circle,
        ),
      );
    }
    
    if (text == null || text!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingXS,
        vertical: DesignTokens.spacingXXS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.error,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        text!,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor ?? colorScheme.onError,
          fontSize: 10,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
