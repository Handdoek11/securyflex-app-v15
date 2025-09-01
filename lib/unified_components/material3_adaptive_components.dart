import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';
import 'premium_color_system.dart';
import 'premium_typography_system.dart';

/// **Material Design 3 Adaptive Components for SecuryFlex**
/// 
/// Premium Material 3 components optimized for security industry:
/// - Adaptive Material 3 design language with SecuryFlex branding
/// - Professional security-focused component variants
/// - Role-based Material 3 theming and color schemes
/// - Trust-building component behaviors and interactions
/// - Responsive adaptive layouts for all screen sizes
/// 
/// These components bring Material 3 innovation to SecuryFlex while
/// maintaining the premium security industry aesthetic and functionality.

// ============================================================================
// MATERIAL 3 ADAPTIVE CARDS
// ============================================================================

/// **Premium Material 3 Adaptive Card**
/// Modern Material 3 card with SecuryFlex premium styling
class M3AdaptiveCard extends StatelessWidget {
  final Widget child;
  final UserRole? role;
  final M3CardVariant variant;
  final VoidCallback? onTap;
  final bool isEnabled;
  final double? elevation;
  final EdgeInsets? padding;

  const M3AdaptiveCard({
    super.key,
    required this.child,
    this.role,
    this.variant = M3CardVariant.filled,
    this.onTap,
    this.isEnabled = true,
    this.elevation,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getAdaptiveColorScheme(role);
    final effectiveElevation = elevation ?? _getVariantElevation();
    final effectivePadding = padding ?? const EdgeInsets.all(16);

    return Card(
      elevation: effectiveElevation,
      surfaceTintColor: _getSurfaceTint(colorScheme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: _getVariantBorder(colorScheme),
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: Container(
          padding: effectivePadding,
          decoration: _getVariantDecoration(colorScheme),
          child: child,
        ),
      ),
    );
  }

  ColorScheme _getAdaptiveColorScheme(UserRole? role) {
    switch (role) {
      case UserRole.guard:
        return ColorScheme.fromSeed(
          seedColor: DesignTokens.guardPrimary,
          brightness: Brightness.light,
        );
      case UserRole.company:
        return ColorScheme.fromSeed(
          seedColor: DesignTokens.companyPrimary,
          brightness: Brightness.light,
        );
      case UserRole.admin:
        return ColorScheme.fromSeed(
          seedColor: DesignTokens.adminPrimary,
          brightness: Brightness.light,
        );
      default:
        return ColorScheme.fromSeed(
          seedColor: DesignTokens.guardPrimary,
          brightness: Brightness.light,
        );
    }
  }

  double _getVariantElevation() {
    switch (variant) {
      case M3CardVariant.filled:
        return 0;
      case M3CardVariant.elevated:
        return 1;
      case M3CardVariant.outlined:
        return 0;
    }
  }

  Color? _getSurfaceTint(ColorScheme colorScheme) {
    return variant == M3CardVariant.elevated ? colorScheme.primary : null;
  }

  BorderSide _getVariantBorder(ColorScheme colorScheme) {
    return variant == M3CardVariant.outlined
        ? BorderSide(color: colorScheme.outline, width: 1)
        : BorderSide.none;
  }

  BoxDecoration? _getVariantDecoration(ColorScheme colorScheme) {
    switch (variant) {
      case M3CardVariant.filled:
        return BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        );
      case M3CardVariant.elevated:
        return BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        );
      case M3CardVariant.outlined:
        return BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        );
    }
  }
}

/// **Security Status Material 3 Card**
/// Specialized card for security status information
class M3SecurityStatusCard extends StatelessWidget {
  final String title;
  final String status;
  final IconData icon;
  final UserRole? role;
  final bool isActive;
  final VoidCallback? onTap;

  const M3SecurityStatusCard({
    super.key,
    required this.title,
    required this.status,
    required this.icon,
    this.role,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isActive ? DesignTokens.colorSuccess : DesignTokens.colorWarning;
    
    return M3AdaptiveCard(
      role: role,
      variant: isActive ? M3CardVariant.filled : M3CardVariant.outlined,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumText(
                      title,
                      style: PremiumTextStyle.bodyEmphasis,
                      role: role,
                    ),
                    const SizedBox(height: 2),
                    PremiumText(
                      status,
                      style: PremiumTextStyle.professionalCaption,
                      color: statusColor,
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MATERIAL 3 ADAPTIVE BUTTONS
// ============================================================================

/// **Premium Material 3 Adaptive Button**
/// Modern Material 3 button variants with SecuryFlex styling
class M3AdaptiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final M3ButtonVariant variant;
  final UserRole? role;
  final bool isLoading;

  const M3AdaptiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = M3ButtonVariant.filled,
    this.role,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getAdaptiveColorScheme(role);
    
    if (isLoading) {
      return _buildLoadingButton(context, colorScheme);
    }

    switch (variant) {
      case M3ButtonVariant.filled:
        return _buildFilledButton(context, colorScheme);
      case M3ButtonVariant.filledTonal:
        return _buildFilledTonalButton(context, colorScheme);
      case M3ButtonVariant.outlined:
        return _buildOutlinedButton(context, colorScheme);
      case M3ButtonVariant.text:
        return _buildTextButton(context, colorScheme);
    }
  }

  ColorScheme _getAdaptiveColorScheme(UserRole? role) {
    switch (role) {
      case UserRole.guard:
        return ColorScheme.fromSeed(seedColor: DesignTokens.guardPrimary);
      case UserRole.company:
        return ColorScheme.fromSeed(seedColor: DesignTokens.companyPrimary);
      case UserRole.admin:
        return ColorScheme.fromSeed(seedColor: DesignTokens.adminPrimary);
      default:
        return ColorScheme.fromSeed(seedColor: DesignTokens.guardPrimary);
    }
  }

  Widget _buildFilledButton(BuildContext context, ColorScheme colorScheme) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(text),
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        textStyle: PremiumTypography.buttonPrimary(context),
      ),
    );
  }

  Widget _buildFilledTonalButton(BuildContext context, ColorScheme colorScheme) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(text),
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, ColorScheme colorScheme) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outline),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
      ),
    );
  }

  Widget _buildTextButton(BuildContext context, ColorScheme colorScheme) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(text),
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
      ),
    );
  }

  Widget _buildLoadingButton(BuildContext context, ColorScheme colorScheme) {
    return FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(color: colorScheme.onPrimary),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MATERIAL 3 ADAPTIVE NAVIGATION
// ============================================================================

/// **Premium Material 3 Navigation Rail**
/// Adaptive navigation rail for larger screens
class M3AdaptiveNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<M3NavigationDestination> destinations;
  final UserRole? role;
  final bool isExtended;

  const M3AdaptiveNavigationRail({
    super.key,
    required this.selectedIndex,
    this.onDestinationSelected,
    required this.destinations,
    this.role,
    this.isExtended = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getAdaptiveColorScheme(role);
    
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: isExtended,
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      selectedIconTheme: IconThemeData(color: colorScheme.onSecondaryContainer),
      selectedLabelTextStyle: PremiumTypography.navigation(
        context,
        role: role,
        isActive: true,
      ),
      unselectedLabelTextStyle: PremiumTypography.navigation(
        context,
        role: role,
        isActive: false,
      ),
      destinations: destinations.map((dest) => NavigationRailDestination(
        icon: Icon(dest.icon),
        selectedIcon: Icon(dest.selectedIcon ?? dest.icon),
        label: Text(dest.label),
      )).toList(),
    );
  }

  ColorScheme _getAdaptiveColorScheme(UserRole? role) {
    switch (role) {
      case UserRole.guard:
        return ColorScheme.fromSeed(seedColor: DesignTokens.guardPrimary);
      case UserRole.company:
        return ColorScheme.fromSeed(seedColor: DesignTokens.companyPrimary);
      case UserRole.admin:
        return ColorScheme.fromSeed(seedColor: DesignTokens.adminPrimary);
      default:
        return ColorScheme.fromSeed(seedColor: DesignTokens.guardPrimary);
    }
  }
}

/// **Premium Material 3 Bottom Navigation Bar**
/// Adaptive bottom navigation for mobile screens
class M3AdaptiveBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<M3NavigationDestination> destinations;
  final UserRole? role;

  const M3AdaptiveBottomNavigation({
    super.key,
    required this.selectedIndex,
    this.onDestinationSelected,
    required this.destinations,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getAdaptiveColorScheme(role);
    
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      destinations: destinations.map((dest) => NavigationDestination(
        icon: Icon(dest.icon),
        selectedIcon: Icon(dest.selectedIcon ?? dest.icon),
        label: dest.label,
      )).toList(),
    );
  }

  ColorScheme _getAdaptiveColorScheme(UserRole? role) {
    switch (role) {
      case UserRole.guard:
        return ColorScheme.fromSeed(seedColor: DesignTokens.guardPrimary);
      case UserRole.company:
        return ColorScheme.fromSeed(seedColor: DesignTokens.companyPrimary);
      case UserRole.admin:
        return ColorScheme.fromSeed(seedColor: DesignTokens.adminPrimary);
      default:
        return ColorScheme.fromSeed(seedColor: DesignTokens.guardPrimary);
    }
  }
}

// ============================================================================
// MATERIAL 3 ADAPTIVE INPUTS
// ============================================================================

/// **Premium Material 3 Text Field**
/// Modern Material 3 text input with SecuryFlex styling
class M3AdaptiveTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final bool isPassword;
  final bool isEnabled;
  final int? maxLines;
  final UserRole? role;

  const M3AdaptiveTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.isPassword = false,
    this.isEnabled = true,
    this.maxLines = 1,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getAdaptiveColorScheme(role);
    
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      obscureText: isPassword,
      enabled: isEnabled,
      maxLines: maxLines,
      style: PremiumTypography.bodyProfessional(context, role: role),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null 
            ? IconButton(
                icon: Icon(suffixIcon),
                onPressed: onSuffixIconTap,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
    );
  }

  ColorScheme _getAdaptiveColorScheme(UserRole? role) {
    switch (role) {
      case UserRole.guard:
        return ColorScheme.fromSeed(seedColor: DesignTokens.guardPrimary);
      case UserRole.company:
        return ColorScheme.fromSeed(seedColor: DesignTokens.companyPrimary);
      case UserRole.admin:
        return ColorScheme.fromSeed(seedColor: DesignTokens.adminPrimary);
      default:
        return ColorScheme.fromSeed(seedColor: DesignTokens.guardPrimary);
    }
  }
}

// ============================================================================
// MATERIAL 3 ADAPTIVE DIALOGS
// ============================================================================

/// **Premium Material 3 Dialog**
/// Modern Material 3 dialog with SecuryFlex styling
class M3AdaptiveDialog extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? contentWidget;
  final List<M3DialogAction> actions;
  final UserRole? role;
  final IconData? icon;

  const M3AdaptiveDialog({
    super.key,
    required this.title,
    this.content,
    this.contentWidget,
    required this.actions,
    this.role,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getAdaptiveColorScheme(role);
    
    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: PremiumText(
              title,
              style: PremiumTextStyle.subheadingProfessional,
              role: role,
            ),
          ),
        ],
      ),
      content: contentWidget ?? (content != null 
          ? PremiumText(
              content!,
              style: PremiumTextStyle.bodyProfessional,
              role: role,
            )
          : null),
      actions: actions.map((action) => M3AdaptiveButton(
        text: action.text,
        onPressed: action.onPressed,
        variant: action.isPrimary ? M3ButtonVariant.filled : M3ButtonVariant.text,
        role: role,
      )).toList(),
    );
  }

  ColorScheme _getAdaptiveColorScheme(UserRole? role) {
    switch (role) {
      case UserRole.guard:
        return ColorScheme.fromSeed(seedColor: DesignTokens.guardPrimary);
      case UserRole.company:
        return ColorScheme.fromSeed(seedColor: DesignTokens.companyPrimary);
      case UserRole.admin:
        return ColorScheme.fromSeed(seedColor: DesignTokens.adminPrimary);
      default:
        return ColorScheme.fromSeed(seedColor: DesignTokens.guardPrimary);
    }
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? content,
    Widget? contentWidget,
    required List<M3DialogAction> actions,
    UserRole? role,
    IconData? icon,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => M3AdaptiveDialog(
        title: title,
        content: content,
        contentWidget: contentWidget,
        actions: actions,
        role: role,
        icon: icon,
      ),
    );
  }
}

// ============================================================================
// SUPPORTING CLASSES AND ENUMS
// ============================================================================

/// Material 3 Card Variants
enum M3CardVariant { filled, elevated, outlined }

/// Material 3 Button Variants
enum M3ButtonVariant { filled, filledTonal, outlined, text }

/// Navigation destination data class
class M3NavigationDestination {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;

  const M3NavigationDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });
}

/// Dialog action data class
class M3DialogAction {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const M3DialogAction({
    required this.text,
    this.onPressed,
    this.isPrimary = false,
  });
}