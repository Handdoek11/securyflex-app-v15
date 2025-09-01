import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'dart:math' as dart_math;

/// Accessibility helper utilities for SecuryFlex app
/// Provides consistent accessibility implementations across all widgets
class AccessibilityHelper {
  
  /// Minimum touch target size according to WCAG guidelines
  static const double minTouchTargetSize = 44.0;
  
  /// High contrast color ratios for better accessibility
  static const double minContrastRatio = 4.5; // WCAG AA standard
  static const double enhancedContrastRatio = 7.0; // WCAG AAA standard
  
  /// Create accessible button wrapper with proper semantics
  static Widget accessibleButton({
    required Widget child,
    required String label,
    required VoidCallback? onPressed,
    String? hint,
    bool enabled = true,
    bool loading = false,
    double? minWidth,
    double? minHeight,
  }) {
    return Semantics(
      label: loading ? '$label wordt geladen' : label,
      button: true,
      enabled: enabled && !loading,
      hint: hint ?? 'Dubbeltik om $label te activeren',
      child: Container(
        constraints: BoxConstraints(
          minWidth: minWidth ?? minTouchTargetSize,
          minHeight: minHeight ?? minTouchTargetSize,
        ),
        child: child,
      ),
    );
  }
  
  /// Create accessible card wrapper with proper semantics
  static Widget accessibleCard({
    required Widget child,
    required String label,
    VoidCallback? onTap,
    String? hint,
    bool enabled = true,
  }) {
    return Semantics(
      label: label,
      button: onTap != null,
      enabled: enabled,
      hint: hint ?? (onTap != null ? 'Dubbeltik om te openen' : null),
      onTap: onTap,
      child: child,
    );
  }
  
  /// Create accessible text with proper contrast
  static Widget accessibleText({
    required String text,
    TextStyle? style,
    Color? backgroundColor,
    bool highContrast = false,
    TextAlign? textAlign,
  }) {
    return Semantics(
      label: text,
      readOnly: true,
      child: Text(
        text,
        style: style?.copyWith(
          // Ensure minimum font size for readability
          fontSize: (style.fontSize ?? DesignTokens.fontSizeBody) < 14
              ? 14
              : style.fontSize,
        ),
        textAlign: textAlign,
      ),
    );
  }
  
  /// Create accessible icon with semantic label
  static Widget accessibleIcon({
    required IconData icon,
    required String semanticLabel,
    Color? color,
    double? size,
  }) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Icon(
        icon,
        color: color,
        size: size ?? DesignTokens.iconSizeM,
      ),
    );
  }
  
  /// Create accessible input field with proper labels
  static Widget accessibleTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Semantics(
      label: label,
      textField: true,
      hint: hint,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          // Ensure proper contrast for input fields
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
        ),
      ),
    );
  }
  
  /// Format currency for screen readers
  static String formatCurrencyForScreenReader(double amount) {
    final euros = amount.floor();
    final cents = ((amount - euros) * 100).round();
    
    if (cents == 0) {
      return '$euros euro';
    } else {
      return '$euros euro en $cents cent';
    }
  }
  
  /// Format time duration for screen readers
  static String formatDurationForScreenReader(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours == 0) {
      return minutes == 1 ? '1 minuut' : '$minutes minuten';
    } else if (minutes == 0) {
      return hours == 1 ? '1 uur' : '$hours uur';
    } else {
      final hourText = hours == 1 ? '1 uur' : '$hours uur';
      final minuteText = minutes == 1 ? '1 minuut' : '$minutes minuten';
      return '$hourText en $minuteText';
    }
  }
  
  /// Format date for screen readers
  static String formatDateForScreenReader(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'vandaag';
    } else if (difference.inDays == 1) {
      return 'gisteren';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dagen geleden';
    } else {
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    }
  }
  
  /// Get Dutch month name
  static String _getMonthName(int month) {
    const months = [
      'januari', 'februari', 'maart', 'april', 'mei', 'juni',
      'juli', 'augustus', 'september', 'oktober', 'november', 'december'
    ];
    return months[month - 1];
  }
  
  /// Check if color contrast meets WCAG standards
  static bool hasGoodContrast(Color foreground, Color background, {bool enhanced = false}) {
    final ratio = _calculateContrastRatio(foreground, background);
    return enhanced ? ratio >= enhancedContrastRatio : ratio >= minContrastRatio;
  }
  
  /// Calculate color contrast ratio
  static double _calculateContrastRatio(Color color1, Color color2) {
    final lum1 = _getLuminance(color1);
    final lum2 = _getLuminance(color2);
    final brightest = lum1 > lum2 ? lum1 : lum2;
    final darkest = lum1 > lum2 ? lum2 : lum1;
    return (brightest + 0.05) / (darkest + 0.05);
  }
  
  /// Get relative luminance of a color
  static double _getLuminance(Color color) {
    final r = _getLinearRGB((color.r * 255.0).round() / 255.0);
    final g = _getLinearRGB((color.g * 255.0).round() / 255.0);
    final b = _getLinearRGB((color.b * 255.0).round() / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
  
  /// Convert sRGB to linear RGB
  static double _getLinearRGB(double value) {
    if (value <= 0.03928) {
      return value / 12.92;
    } else {
      return ((value + 0.055) / 1.055).pow(2.4);
    }
  }
  
  /// Create focus-aware widget for keyboard navigation
  static Widget focusableWidget({
    required Widget child,
    required VoidCallback? onPressed,
    String? semanticLabel,
    bool autofocus = false,
  }) {
    return Focus(
      autofocus: autofocus,
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return Container(
            decoration: hasFocus ? BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ) : null,
            child: Semantics(
              label: semanticLabel,
              focusable: true,
              focused: hasFocus,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Extension to add pow method for double
extension DoubleExtension on double {
  double pow(double exponent) {
    return dart_math.pow(this, exponent).toDouble();
  }
}
