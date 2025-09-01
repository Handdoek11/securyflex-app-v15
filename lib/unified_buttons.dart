import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_components/ultra_smooth_animation_system.dart';

/// Unified Button System for SecuryFlex
/// 
/// A comprehensive button system that consolidates all button patterns
/// across different modules while maintaining consistent styling and
/// strategic blue accent integration.

/// Main unified button widget
class UnifiedButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final UnifiedButtonType type;
  final UnifiedButtonSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final bool isSelected;
  final bool isLoading;
  final bool isEnabled;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? elevation;
  final Widget? child;
  final double? width;
  final double? height;

  const UnifiedButton({
    super.key,
    this.text,
    this.icon,
    this.onPressed,
    this.type = UnifiedButtonType.primary,
    this.size = UnifiedButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.isSelected = false,
    this.isLoading = false,
    this.isEnabled = true,
    this.padding,
    this.borderRadius,
    this.elevation,
    this.child,
    this.width,
    this.height,
  });

  /// Factory constructor for primary buttons (main CTAs)
  factory UnifiedButton.primary({
    required String text,
    required VoidCallback onPressed,
    UnifiedButtonSize size = UnifiedButtonSize.medium,
    bool isLoading = false,
    double? width,
    double? borderRadius,
    Color? backgroundColor,
  }) {
    return UnifiedButton(
      text: text,
      onPressed: onPressed,
      type: UnifiedButtonType.primary,
      size: size,
      isLoading: isLoading,
      width: width,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
    );
  }

  /// Factory constructor for secondary buttons (outlined)
  factory UnifiedButton.secondary({
    required String text,
    required VoidCallback onPressed,
    UnifiedButtonSize size = UnifiedButtonSize.medium,
    double? width,
  }) {
    return UnifiedButton(
      text: text,
      onPressed: onPressed,
      type: UnifiedButtonType.secondary,
      size: size,
      width: width,
    );
  }

  /// Factory constructor for text buttons (minimal)
  factory UnifiedButton.text({
    required String text,
    required VoidCallback onPressed,
    UnifiedButtonSize size = UnifiedButtonSize.medium,
  }) {
    return UnifiedButton(
      text: text,
      onPressed: onPressed,
      type: UnifiedButtonType.text,
      size: size,
    );
  }

  /// Factory constructor for category/filter buttons
  factory UnifiedButton.category({
    required String text,
    required VoidCallback onPressed,
    required bool isSelected,
    UnifiedButtonSize size = UnifiedButtonSize.medium,
  }) {
    return UnifiedButton(
      text: text,
      onPressed: onPressed,
      type: UnifiedButtonType.category,
      size: size,
      isSelected: isSelected,
    );
  }

  /// Factory constructor for icon buttons
  factory UnifiedButton.icon({
    required IconData icon,
    required VoidCallback onPressed,
    UnifiedButtonSize size = UnifiedButtonSize.medium,
    Color? color,
  }) {
    return UnifiedButton(
      icon: icon,
      onPressed: onPressed,
      type: UnifiedButtonType.icon,
      size: size,
      foregroundColor: color,
    );
  }

  /// Factory constructor for floating action buttons
  factory UnifiedButton.floating({
    required IconData icon,
    required VoidCallback onPressed,
    UnifiedButtonSize size = UnifiedButtonSize.large,
  }) {
    return UnifiedButton(
      icon: icon,
      onPressed: onPressed,
      type: UnifiedButtonType.floating,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = _getButtonSize();
    final buttonStyle = _getButtonStyle();
    final buttonChild = _getButtonChild();

    Widget button;

    switch (type) {
      case UnifiedButtonType.primary:
        button = FilledButton(
          onPressed: isEnabled && !isLoading ? onPressed : null,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
      case UnifiedButtonType.secondary:
        button = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
      case UnifiedButtonType.text:
        button = TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
      case UnifiedButtonType.category:
        button = _buildCategoryButton();
        break;
      case UnifiedButtonType.icon:
        button = _buildIconButton();
        break;
      case UnifiedButtonType.floating:
        button = _buildFloatingButton();
        break;
    }

    // Remove UltraSmoothSecurityCard wrapper for primary and secondary buttons
    // to improve visibility and reduce animation interference
    if (type == UnifiedButtonType.primary || type == UnifiedButtonType.secondary) {
      return SizedBox(
        width: width,
        height: height ?? buttonSize.height,
        child: button,
      );
    }

    return SizedBox(
      width: width,
      height: height ?? buttonSize.height,
      child: UltraSmoothSecurityCard(
        onTap: onPressed,
        customDuration: const Duration(milliseconds: 150),
        child: button,
      ),
    );
  }

  ButtonSize _getButtonSize() {
    switch (size) {
      case UnifiedButtonSize.small:
        return ButtonSize(
          height: 36.0,
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS, vertical: DesignTokens.spacingXS),
          fontSize: DesignTokens.fontSizeBody,
          iconSize: 16.0,
        );
      case UnifiedButtonSize.medium:
        return ButtonSize(
          height: 48.0,
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM, vertical: DesignTokens.spacingS + 4),
          fontSize: DesignTokens.fontSizeBodyLarge,
          iconSize: 20.0,
        );
      case UnifiedButtonSize.large:
        return ButtonSize(
          height: 56.0,
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL, vertical: DesignTokens.spacingM),
          fontSize: DesignTokens.fontSizeSubtitle,
          iconSize: 24.0,
        );
    }
  }

  ButtonStyle _getButtonStyle() {
    final buttonSize = _getButtonSize();

    switch (type) {
      case UnifiedButtonType.primary:
        return FilledButton.styleFrom(
          // Use darker blue from design system
          backgroundColor: backgroundColor ?? DesignTokens.colorPrimaryBlueDark,
          foregroundColor: foregroundColor ?? DesignTokens.colorWhite,
          padding: padding ?? buttonSize.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? DesignTokens.radiusButton),
          ),
          elevation: elevation ?? DesignTokens.elevationMedium,
          shadowColor: DesignTokens.colorPrimaryBlueDark.withValues(alpha: 0.3),
          disabledBackgroundColor: DesignTokens.colorGray300,
          disabledForegroundColor: DesignTokens.colorGray600,
        );
      case UnifiedButtonType.secondary:
        return OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? DesignTokens.colorWhite,
          foregroundColor: foregroundColor ?? DesignTokens.colorPrimaryBlueDark,
          padding: padding ?? buttonSize.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? DesignTokens.radiusButton),
          ),
          side: BorderSide(
            color: borderColor ?? DesignTokens.colorPrimaryBlueDark,
            width: 2.0,
          ),
          elevation: DesignTokens.elevationLow,
        );
      case UnifiedButtonType.text:
        return TextButton.styleFrom(
          foregroundColor: foregroundColor ?? DesignTokens.colorPrimaryBlueDark,
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS + 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? DesignTokens.radiusS),
          ),
          backgroundColor: DesignTokens.colorPrimaryBlueDark.withValues(alpha: 0.06),
          overlayColor: DesignTokens.colorPrimaryBlueDark.withValues(alpha: 0.12),
          minimumSize: Size(88, 44), // WCAG AA touch target
          textStyle: TextStyle(
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontSize: buttonSize.fontSize,
            decoration: TextDecoration.underline,
            decorationColor: DesignTokens.colorPrimaryBlueDark.withValues(alpha: 0.7),
            decorationThickness: 1.5,
          ),
        );
      default:
        return FilledButton.styleFrom();
    }
  }

  Widget _getButtonChild() {
    if (child != null) return child!;

    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            foregroundColor ?? DesignTokens.colorWhite,
          ),
        ),
      );
    }

    final buttonSize = _getButtonSize();

    if (icon != null && text != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: buttonSize.iconSize),
          SizedBox(width: DesignTokens.spacingS),
          Flexible(
            child: Text(
              text!,
              style: TextStyle(
                fontSize: buttonSize.fontSize,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (icon != null) {
      return Icon(icon, size: buttonSize.iconSize);
    } else if (text != null) {
      return Text(
        text!,
        style: TextStyle(
          fontSize: buttonSize.fontSize,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCategoryButton() {
    final buttonSize = _getButtonSize();

    return Container(
      height: buttonSize.height,
      decoration: BoxDecoration(
        color: isSelected ? DesignTokens.colorPrimaryBlue : DesignTokens.colorWhite,
        borderRadius: BorderRadius.circular(borderRadius ?? DesignTokens.radiusXXL),
        border: Border.all(
          color: borderColor ?? DesignTokens.colorPrimaryBlue,
          width: 1.5,
        ),
        boxShadow: isSelected ? [DesignTokens.shadowLight] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius ?? DesignTokens.radiusXXL),
          onTap: isEnabled ? onPressed : null,
          child: Padding(
            padding: padding ?? buttonSize.padding,
            child: Center(
              child: Text(
                text ?? '',
                style: TextStyle(
                  fontSize: buttonSize.fontSize,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: isSelected ? DesignTokens.colorWhite : DesignTokens.colorPrimaryBlue,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton() {
    final buttonSize = _getButtonSize();

    return SizedBox(
      width: buttonSize.height,
      height: buttonSize.height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
          onTap: isEnabled ? onPressed : null,
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.spacingS),
            child: Icon(
              icon,
              color: foregroundColor ?? DesignTokens.colorGray800,
              size: buttonSize.iconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton() {
    final buttonSize = _getButtonSize();

    return Container(
      width: buttonSize.height,
      height: buttonSize.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? DesignTokens.colorPrimaryBlue,
            (backgroundColor ?? DesignTokens.colorPrimaryBlue).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? DesignTokens.colorPrimaryBlue).withValues(alpha: 0.4),
            offset: const Offset(8.0, 16.0),
            blurRadius: 16.0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(buttonSize.height / 2),
          onTap: isEnabled ? onPressed : null,
          child: Center(
            child: Icon(
              icon,
              color: foregroundColor ?? DesignTokens.colorWhite,
              size: buttonSize.iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

/// Button type enumeration
enum UnifiedButtonType {
  primary,
  secondary,
  text,
  category,
  icon,
  floating,
}

/// Button size enumeration
enum UnifiedButtonSize {
  small,
  medium,
  large,
}

/// Button size configuration
class ButtonSize {
  final double height;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double iconSize;

  const ButtonSize({
    required this.height,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
  });
}
