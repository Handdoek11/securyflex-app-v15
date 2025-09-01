import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';

/// **Premium Color System - Professional Gradient Palette**
/// 
/// Enhanced color system with strategic gradients for trust-building:
/// - Professional blue gradients for security industry credibility
/// - Role-based gradient hierarchies for clear visual organization  
/// - Trust-building color psychology with warm accent integration
/// - Premium depth effects through layered gradient compositions
/// - Accessibility-compliant contrast ratios maintained
/// 
/// This system elevates SecuryFlex from standard colors to premium
/// visual architecture that builds user confidence and trust.

class PremiumColors {
  PremiumColors._();

  // ============================================================================
  // PROFESSIONAL BLUE GRADIENT SYSTEM
  // ============================================================================

  /// **Primary Trust Gradient** - Deep blue professional authority
  /// Used for: Headers, primary actions, security indicators
  static const LinearGradient trustGradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E40AF), // Deep professional blue
      Color(0xFF1E3A8A), // Slightly deeper for depth
      Color(0xFF1D4ED8), // Bright accent for energy
    ],
    stops: [0.0, 0.6, 1.0],
  );

  /// **Secondary Trust Gradient** - Lighter professional tones
  /// Used for: Cards, sections, elevated surfaces
  static const LinearGradient trustGradientSecondary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF3B82F6), // Bright professional blue
      Color(0xFF2563EB), // Standard professional blue
      Color(0xFF1D4ED8), // Deep accent blue
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// **Subtle Trust Gradient** - Light backgrounds and surfaces
  /// Used for: Background sections, subtle containers
  static const LinearGradient trustGradientSubtle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF1F5F9), // Very light blue-gray
      Color(0xFFE2E8F0), // Light blue-gray
      Color(0xFFCBD5E1), // Subtle blue-gray
    ],
    stops: [0.0, 0.7, 1.0],
  );

  // ============================================================================
  // SUCCESS & EARNINGS GRADIENTS
  // ============================================================================

  /// **Earnings Success Gradient** - Financial growth and achievement
  /// Used for: Earnings cards, success states, positive metrics
  static const LinearGradient earningsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981), // Success green
      Color(0xFF059669), // Deeper success green
      Color(0xFF047857), // Rich success green
    ],
    stops: [0.0, 0.6, 1.0],
  );

  /// **Achievement Gradient** - Subtle success indicators
  /// Used for: Completion badges, positive status indicators
  static const LinearGradient achievementGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF34D399), // Light success
      Color(0xFF10B981), // Standard success
      Color(0xFF059669), // Deep success
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ============================================================================
  // WARNING & ATTENTION GRADIENTS
  // ============================================================================

  /// **Professional Warning Gradient** - Attention without alarm
  /// Used for: Important notices, pending actions, certificates expiring
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFBBF24), // Light warning
      Color(0xFFF59E0B), // Standard warning
      Color(0xFFD97706), // Deep warning
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ============================================================================
  // ROLE-BASED GRADIENT SYSTEMS
  // ============================================================================

  /// **Guard Role Primary Gradient** - Professional security authority
  static const LinearGradient guardPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      DesignTokens.guardPrimary,
      Color(0xFF1E40AF),
      DesignTokens.guardPrimaryLight,
    ],
    stops: [0.0, 0.6, 1.0],
  );

  /// **Guard Role Background Gradient** - Subtle professional backdrop
  static const LinearGradient guardBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFAFBFF), // Very light blue-white
      DesignTokens.guardBackground,
      Color(0xFFE8EBF7), // Light blue-gray
    ],
    stops: [0.0, 0.7, 1.0],
  );

  /// **Company Role Primary Gradient** - Business growth and opportunity
  static const LinearGradient companyPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      DesignTokens.companyPrimary,
      Color(0xFF0891B2),
      DesignTokens.companyPrimaryLight,
    ],
    stops: [0.0, 0.6, 1.0],
  );

  // ============================================================================
  // PREMIUM GLASSMORPHISM GRADIENTS
  // ============================================================================

  /// **Glass Surface Gradient** - Premium glassmorphism effect
  /// Used with BackdropFilter for advanced glass effects
  static const LinearGradient glassSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x40FFFFFF), // 25% white
      Color(0x20FFFFFF), // 12% white
      Color(0x10FFFFFF), // 6% white
      Color(0x30FFFFFF), // 18% white
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  /// **Premium Glass Overlay** - Top-tier glassmorphic surface
  static const LinearGradient glassOverlayPremium = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x60FFFFFF), // 37% white for premium highlight
      Color(0x20FFFFFF), // 12% white for mid-tone
      Color(0x10FFFFFF), // 6% white for depth
      Color(0x40FFFFFF), // 25% white for rich base
    ],
    stops: [0.0, 0.2, 0.6, 1.0],
  );

  // ============================================================================
  // TRUST-BUILDING ACCENT GRADIENTS
  // ============================================================================

  /// **Professional Authority Gradient** - Subtle teal accent for reliability
  /// Used for: Secondary actions, supportive information, company elements
  static const LinearGradient authorityGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF7DD3FC), // Light sky blue
      DesignTokens.colorSecondaryTeal,
      Color(0xFF0891B2), // Deep teal
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// **Warm Trust Gradient** - Subtle warm accents for human connection
  /// Used sparingly for: Personal elements, user feedback, completion states
  static const LinearGradient warmTrustGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFDDD6FE), // Very light purple
      Color(0xFFC7D2FE), // Light blue-purple
      Color(0xFFA5B4FC), // Soft purple-blue
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ============================================================================
  // SPECIALIZED SECURITY GRADIENTS
  // ============================================================================

  /// **Security Shield Gradient** - Protection and safety emphasis
  /// Used for: Security features, protection indicators, safety alerts
  static const LinearGradient securityShieldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E3A8A), // Deep security blue
      Color(0xFF1E40AF), // Professional authority
      Color(0xFF3730A3), // Rich security purple-blue
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// **Emergency Action Gradient** - Critical but controlled urgency
  /// Used for: Emergency buttons, critical alerts, immediate actions needed
  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF87171), // Light emergency red
      DesignTokens.colorError,
      Color(0xFFDC2626), // Deep emergency red
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ============================================================================
  // 2025 DYNAMIC COLOR PSYCHOLOGY SYSTEM
  // ============================================================================

  /// **Context-Aware Color Adaptation** - 2025 trend for dynamic color psychology
  static LinearGradient getContextualGradient({
    required String context,
    required TimeOfDay currentTime,
    double stressLevel = 0.5, // 0.0 = calm, 1.0 = high stress
  }) {
    // Morning energy gradients (6-12)
    if (currentTime.hour >= 6 && currentTime.hour < 12) {
      switch (context) {
        case 'security_alert':
          return stressLevel > 0.7 ? emergencyGradient : warningGradient;
        case 'earnings':
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF10B981), // Fresh morning green
              Color(0xFF059669),
              Color(0xFF34D399), // Energetic highlight
            ],
            stops: [0.0, 0.5, 1.0],
          );
        default:
          return trustGradientPrimary;
      }
    }
    // Afternoon focus gradients (12-18)
    else if (currentTime.hour >= 12 && currentTime.hour < 18) {
      return context == 'security_alert' && stressLevel > 0.6
        ? emergencyGradient
        : trustGradientSecondary;
    }
    // Evening calm gradients (18-22)
    else if (currentTime.hour >= 18 && currentTime.hour < 22) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4C1D95), // Evening purple-blue
          Color(0xFF3730A3),
          Color(0xFF1E3A8A), // Deep security blue
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
    // Night security gradients (22-6)
    else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1E3A8A), // Deep night security
          Color(0xFF1E1B4B), // Dark professional
          Color(0xFF312E81), // Rich night blue
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
  }

  /// **Biometric Response Colors** - Colors that respond to user engagement
  static Color getBiometricResponseColor({
    required double engagementLevel, // 0.0-1.0
    required UserRole role,
  }) {
    final baseColor = _getRoleBorderColor(role).withAlpha(255);
    
    // High engagement = warmer, more energetic
    if (engagementLevel > 0.8) {
      return Color.lerp(baseColor, Color(0xFF10B981), 0.3)!; // Add success energy
    }
    // Medium engagement = standard
    else if (engagementLevel > 0.4) {
      return baseColor;
    }
    // Low engagement = cooler, more calming
    else {
      return Color.lerp(baseColor, Color(0xFF64748B), 0.2)!; // Add calm gray
    }
  }

  // ============================================================================
  // UTILITY METHODS FOR DYNAMIC GRADIENTS
  // ============================================================================

  /// Create role-based gradient dynamically
  static LinearGradient getRoleGradient(UserRole role, {bool isLight = false}) {
    switch (role) {
      case UserRole.guard:
        return isLight ? guardBackgroundGradient : guardPrimaryGradient;
      case UserRole.company:
        return companyPrimaryGradient;
      case UserRole.admin:
        return trustGradientPrimary; // Admin uses primary trust gradient
    }
  }

  /// Create status-based gradient dynamically  
  static LinearGradient getStatusGradient(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'confirmed':
        return earningsGradient;
      case 'warning':
      case 'pending':
      case 'expiring':
        return warningGradient;
      case 'emergency':
      case 'urgent':
      case 'critical':
        return emergencyGradient;
      default:
        return trustGradientSecondary;
    }
  }

  /// Create glass gradient with custom opacity
  static LinearGradient createCustomGlassGradient(double opacity) {
    final clampedOpacity = opacity.clamp(0.0, 1.0);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.fromRGBO(255, 255, 255, clampedOpacity * 0.4),
        Color.fromRGBO(255, 255, 255, clampedOpacity * 0.2),
        Color.fromRGBO(255, 255, 255, clampedOpacity * 0.1),
        Color.fromRGBO(255, 255, 255, clampedOpacity * 0.3),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
  }

  // ============================================================================
  // PREMIUM CONTAINER DECORATION HELPERS
  // ============================================================================

  /// Create premium glass container decoration
  static BoxDecoration createPremiumGlassDecoration({
    BorderRadius? borderRadius,
    Color? borderColor,
    double borderWidth = 1.0,
    LinearGradient? customGradient,
  }) {
    return BoxDecoration(
      gradient: customGradient ?? glassSurfaceGradient,
      borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusL),
      border: borderColor != null 
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
          spreadRadius: -2,
        ),
      ],
    );
  }

  /// Create trust-building card decoration with role-based styling
  static BoxDecoration createTrustCardDecoration(UserRole role, {bool isElevated = false}) {
    return BoxDecoration(
      gradient: getRoleGradient(role, isLight: true),
      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      border: Border.all(
        color: _getRoleBorderColor(role),
        width: 1.0,
      ),
      boxShadow: isElevated ? [
        BoxShadow(
          color: _getRoleBorderColor(role).withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ] : [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static Color _getRoleBorderColor(UserRole role) {
    switch (role) {
      case UserRole.guard:
        return DesignTokens.guardPrimary.withValues(alpha: 0.2);
      case UserRole.company:
        return DesignTokens.companyPrimary.withValues(alpha: 0.2);
      case UserRole.admin:
        return DesignTokens.adminPrimary.withValues(alpha: 0.2);
    }
  }
}


/// **Premium Gradient Text Widget**
/// Applies premium gradients to text for enhanced visual hierarchy
class PremiumGradientText extends StatelessWidget {
  final String text;
  final LinearGradient gradient;
  final TextStyle? style;
  final TextAlign? textAlign;

  const PremiumGradientText({
    super.key,
    required this.text,
    required this.gradient,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}