import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';

/// Unified Shadow System for SecuryFlex
/// 
/// A comprehensive shadow system that provides consistent elevation
/// and depth across all components in the SecuryFlex application.
/// 
/// This system ensures visual hierarchy and consistency while
/// maintaining the clean, professional aesthetic.

class UnifiedShadows {
  UnifiedShadows._();

  // ============================================================================
  // SHADOW DEFINITIONS - Consistent elevation levels
  // ============================================================================

  /// Light shadow for subtle elevation (1dp)
  /// Use for: Small cards, chips, minor elevated elements
  static const BoxShadow light = BoxShadow(
    color: Color(0x0D000000), // 5% black
    offset: Offset(0, 1),
    blurRadius: 3.0,
    spreadRadius: 0,
  );

  /// Medium shadow for standard elevation (2dp)
  /// Use for: Cards, containers, standard elevated elements
  static const BoxShadow medium = BoxShadow(
    color: Color(0x1A000000), // 10% black
    offset: Offset(0, 2),
    blurRadius: 8.0,
    spreadRadius: 0,
  );

  /// Strong shadow for prominent elevation (4dp)
  /// Use for: Important cards, modals, prominent elements
  static const BoxShadow strong = BoxShadow(
    color: Color(0x26000000), // 15% black
    offset: Offset(0, 4),
    blurRadius: 12.0,
    spreadRadius: 0,
  );

  /// Header shadow for app bars and headers (2dp)
  /// Use for: Headers, app bars, navigation elements
  static const BoxShadow header = BoxShadow(
    color: Color(0x1A000000), // 10% black
    offset: Offset(0, 2),
    blurRadius: 8.0,
    spreadRadius: 0,
  );

  /// Floating shadow for floating action buttons (6dp)
  /// Use for: FABs, floating elements, overlays
  static const BoxShadow floating = BoxShadow(
    color: Color(0x33000000), // 20% black
    offset: Offset(0, 6),
    blurRadius: 16.0,
    spreadRadius: 0,
  );

  /// Modal shadow for dialogs and modals (8dp)
  /// Use for: Dialogs, bottom sheets, overlays
  static const BoxShadow modal = BoxShadow(
    color: Color(0x40000000), // 25% black
    offset: Offset(0, 8),
    blurRadius: 20.0,
    spreadRadius: 0,
  );

  // ============================================================================
  // SHADOW LISTS - Ready-to-use shadow combinations
  // ============================================================================

  /// Light elevation shadow list
  static const List<BoxShadow> lightElevation = [light];

  /// Medium elevation shadow list
  static const List<BoxShadow> mediumElevation = [medium];

  /// Strong elevation shadow list
  static const List<BoxShadow> strongElevation = [strong];

  /// Header elevation shadow list
  static const List<BoxShadow> headerElevation = [header];

  /// Floating elevation shadow list
  static const List<BoxShadow> floatingElevation = [floating];

  /// Modal elevation shadow list
  static const List<BoxShadow> modalElevation = [modal];

  // ============================================================================
  // COLORED SHADOWS - For specific use cases
  // ============================================================================

  /// Blue accent shadow for primary buttons and elements
  static BoxShadow blueAccent({double opacity = 0.3}) {
    return BoxShadow(
      color: DesignTokens.colorPrimaryBlueLight.withValues(alpha: opacity),
      offset: const Offset(0, 4),
      blurRadius: 12.0,
      spreadRadius: 0,
    );
  }

  /// Security blue shadow for security-related elements
  static BoxShadow securityBlue({double opacity = 0.3}) {
    return BoxShadow(
      color: DesignTokens.colorPrimaryBlue.withValues(alpha: opacity),
      offset: const Offset(0, 4),
      blurRadius: 12.0,
      spreadRadius: 0,
    );
  }

  /// Success green shadow for positive actions
  static BoxShadow successGreen({double opacity = 0.3}) {
    return BoxShadow(
      color: DesignTokens.colorSuccess.withValues(alpha: opacity),
      offset: const Offset(0, 4),
      blurRadius: 12.0,
      spreadRadius: 0,
    );
  }

  /// Warning orange shadow for warning elements
  static BoxShadow warningOrange({double opacity = 0.3}) {
    return BoxShadow(
      color: DesignTokens.colorWarning.withValues(alpha: opacity),
      offset: const Offset(0, 4),
      blurRadius: 12.0,
      spreadRadius: 0,
    );
  }

  /// Error red shadow for error states
  static BoxShadow errorRed({double opacity = 0.3}) {
    return BoxShadow(
      color: DesignTokens.colorError.withValues(alpha: opacity),
      offset: const Offset(0, 4),
      blurRadius: 12.0,
      spreadRadius: 0,
    );
  }

  // ============================================================================
  // UTILITY METHODS - Helper functions for common patterns
  // ============================================================================

  /// Get appropriate shadow based on elevation level
  static List<BoxShadow> getElevationShadow(int elevation) {
    switch (elevation) {
      case 1:
        return lightElevation;
      case 2:
        return mediumElevation;
      case 4:
        return strongElevation;
      case 6:
        return floatingElevation;
      case 8:
        return modalElevation;
      default:
        return mediumElevation;
    }
  }

  /// Get shadow for specific component types
  static List<BoxShadow> getComponentShadow(ComponentType type) {
    switch (type) {
      case ComponentType.card:
        return mediumElevation;
      case ComponentType.header:
        return headerElevation;
      case ComponentType.button:
        return lightElevation;
      case ComponentType.fab:
        return floatingElevation;
      case ComponentType.modal:
        return modalElevation;
      case ComponentType.chip:
        return lightElevation;
    }
  }

  /// Create custom shadow with specific parameters
  static BoxShadow custom({
    required Color color,
    required Offset offset,
    required double blurRadius,
    double spreadRadius = 0,
  }) {
    return BoxShadow(
      color: color,
      offset: offset,
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
    );
  }
}

/// Component types for shadow selection
enum ComponentType {
  card,
  header,
  button,
  fab,
  modal,
  chip,
}

/// Shadow elevation levels following Material Design
enum ShadowElevation {
  none(0),
  light(1),
  medium(2),
  strong(4),
  floating(6),
  modal(8);

  const ShadowElevation(this.value);
  final int value;
}
