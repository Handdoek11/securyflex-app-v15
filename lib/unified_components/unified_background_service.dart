import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';

/// Unified Background Service for SecuryFlex Guard Interface
/// 
/// Centralizes all background logic to ensure consistency across the application.
/// Provides theme-aware, role-based, and performance-optimized backgrounds.
/// 
/// Version: 1.0.0
/// Author: SecuryFlex Development Team
/// Last Updated: August 2025
class UnifiedBackgroundService {
  // Private constructor to prevent instantiation
  UnifiedBackgroundService._();
  
  // ============================================================================
  // STANDARDIZED ALPHA VALUES
  // ============================================================================
  
  /// Ultra subtle transparency
  static const double alphaUltraSubtle = 0.02;
  
  /// Subtle transparency for overlays
  static const double alphaSubtle = 0.05;
  
  /// Light transparency for containers
  static const double alphaLight = 0.10;
  
  /// Medium transparency for elevated surfaces
  static const double alphaMedium = 0.30;
  
  /// Strong transparency for modals
  static const double alphaStrong = 0.70;
  
  /// Near solid transparency
  static const double alphaSolid = 0.90;
  
  /// Completely opaque
  static const double alphaOpaque = 1.00;
  
  // Glass-specific alpha values
  static const double glassUltraSubtle = 0.70;
  static const double glassSubtle = 0.85;
  static const double glassStandard = 0.90;
  static const double glassPremium = 0.95;
  
  // ============================================================================
  // PERFORMANCE DETECTION
  // ============================================================================
  
  /// Get device performance tier based on pixel ratio
  static PerformanceTier getPerformanceTier(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    if (pixelRatio >= 3.0) {
      return PerformanceTier.high;
    } else if (pixelRatio >= 2.0) {
      return PerformanceTier.medium;
    } else {
      return PerformanceTier.low;
    }
  }
  
  // ============================================================================
  // SCAFFOLD BACKGROUNDS
  // ============================================================================
  
  /// Primary scaffold background for main screens
  static Color scaffold({
    required BuildContext context,
    UserRole role = UserRole.guard,
    bool isDark = false,
  }) {
    if (isDark) {
      // Future dark mode support
      return const Color(0xFF121212);
    }
    
    // Light mode backgrounds based on role
    switch (role) {
      case UserRole.guard:
        // Premium gradient background voor beveiligers
        return const Color(0xFFF5F7FA); // Zachte blauw-grijze tint voor professionele uitstraling
      case UserRole.company:
        return DesignTokens.companyBackground; // #F6F6F6
      case UserRole.admin:
        return DesignTokens.adminBackground; // #F7FAFC
    }
  }
  
  // ============================================================================
  // CONTAINER BACKGROUNDS
  // ============================================================================
  
  /// Container backgrounds for cards and panels
  static Color container({
    required BuildContext context,
    UserRole role = UserRole.guard,
    double opacity = 1.0,
    bool elevated = false,
  }) {
    final baseColor = _getSurfaceColor(role);
    
    if (elevated) {
      return baseColor;
    }
    
    return opacity < 1.0 
        ? baseColor.withValues(alpha: opacity)
        : baseColor;
  }
  
  /// Get surface color based on role
  static Color _getSurfaceColor(UserRole role) {
    switch (role) {
      case UserRole.guard:
        return DesignTokens.guardSurface; // #FFFFFF
      case UserRole.company:
        return DesignTokens.colorWhite; // #FFFFFF
      case UserRole.admin:
        return DesignTokens.adminSurface; // #FFFFFF
    }
  }
  
  // ============================================================================
  // GLASS MORPHISM BACKGROUNDS
  // ============================================================================
  
  /// Create glass morphism container
  static Widget glass({
    required BuildContext context,
    required Widget child,
    UserRole role = UserRole.guard,
    GlassIntensity intensity = GlassIntensity.standard,
    double borderRadius = 16.0,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    final performanceTier = getPerformanceTier(context);
    final config = _getGlassConfig(intensity, performanceTier);
    
    // Fallback to solid on low performance devices
    if (performanceTier == PerformanceTier.low && intensity == GlassIntensity.premium) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          color: container(context: context, role: role, opacity: config.opacity),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: _getRoleColor(role).withValues(alpha: alphaLight),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
    }
    
    // Glass morphism implementation
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: config.blurStrength,
            sigmaY: config.blurStrength,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: config.highlightOpacity),
                  Colors.white.withValues(alpha: config.opacity),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: _getRoleColor(role).withValues(alpha: alphaLight),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Get glass configuration based on intensity and performance
  static _GlassConfig _getGlassConfig(GlassIntensity intensity, PerformanceTier performance) {
    switch (intensity) {
      case GlassIntensity.subtle:
        return _GlassConfig(
          blurStrength: performance == PerformanceTier.high ? 6.0 : 4.0,
          opacity: glassUltraSubtle,
          highlightOpacity: 0.15,
        );
      case GlassIntensity.standard:
        return _GlassConfig(
          blurStrength: performance == PerformanceTier.high ? 10.0 : 8.0,
          opacity: glassSubtle,
          highlightOpacity: 0.20,
        );
      case GlassIntensity.premium:
        return _GlassConfig(
          blurStrength: performance == PerformanceTier.high ? 15.0 : 12.0,
          opacity: glassPremium,
          highlightOpacity: 0.25,
        );
    }
  }
  
  // ============================================================================
  // GRADIENT BACKGROUNDS
  // ============================================================================
  
  /// Create gradient background
  static BoxDecoration gradient({
    required BuildContext context,
    UserRole role = UserRole.guard,
    GradientType type = GradientType.primary,
    double borderRadius = 16.0,
  }) {
    final colors = _getGradientColors(role, type);
    
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }
  
  /// Get gradient colors based on role and type
  static List<Color> _getGradientColors(UserRole role, GradientType type) {
    final roleColor = _getRoleColor(role);
    
    switch (type) {
      case GradientType.primary:
        return [
          roleColor.withValues(alpha: alphaLight),
          roleColor.withValues(alpha: alphaSubtle),
        ];
      case GradientType.accent:
        return [
          _getAccentColor(role).withValues(alpha: alphaLight),
          _getAccentColor(role).withValues(alpha: alphaSubtle),
        ];
      case GradientType.subtle:
        return [
          Colors.white.withValues(alpha: glassPremium),
          Colors.white.withValues(alpha: glassStandard),
        ];
    }
  }
  
  // ============================================================================
  // ADAPTIVE BACKGROUNDS
  // ============================================================================
  
  /// Adaptive background that selects best option based on performance
  static Widget adaptive({
    required BuildContext context,
    required Widget child,
    UserRole role = UserRole.guard,
    BackgroundType preferredType = BackgroundType.glass,
    double borderRadius = 16.0,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    final performanceTier = getPerformanceTier(context);
    
    // Low performance - use solid colors
    if (performanceTier == PerformanceTier.low) {
      return Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: container(context: context, role: role),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: _getRoleColor(role).withValues(alpha: alphaSubtle),
            width: 1,
          ),
        ),
        child: child,
      );
    }
    
    // Medium/High performance - use preferred type
    switch (preferredType) {
      case BackgroundType.solid:
        return Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: container(context: context, role: role),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        );
        
      case BackgroundType.gradient:
        return Container(
          margin: margin,
          padding: padding,
          decoration: gradient(
            context: context,
            role: role,
            borderRadius: borderRadius,
          ),
          child: child,
        );
        
      case BackgroundType.glass:
        return glass(
          context: context,
          child: child,
          role: role,
          intensity: performanceTier == PerformanceTier.high 
              ? GlassIntensity.premium 
              : GlassIntensity.standard,
          borderRadius: borderRadius,
          padding: padding,
          margin: margin,
        );
    }
  }
  
  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  /// Get role-specific primary color
  static Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.guard:
        return DesignTokens.guardPrimary;
      case UserRole.company:
        return DesignTokens.companyPrimary;
      case UserRole.admin:
        return DesignTokens.adminPrimary;
    }
  }
  
  /// Get role-specific accent color
  static Color _getAccentColor(UserRole role) {
    switch (role) {
      case UserRole.guard:
        return DesignTokens.guardAccent;
      case UserRole.company:
        return DesignTokens.companyAccent;
      case UserRole.admin:
        return DesignTokens.adminAccent;
    }
  }
  
  /// Create consistent card decoration
  static BoxDecoration cardDecoration({
    required BuildContext context,
    UserRole role = UserRole.guard,
    bool isElevated = false,
    double borderRadius = 16.0,
  }) {
    return BoxDecoration(
      color: container(
        context: context,
        role: role,
        elevated: isElevated,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isElevated
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: _getRoleColor(role).withValues(alpha: alphaSubtle),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }
  
  /// Surface background for dialogs and modals
  static Color surface({
    required BuildContext context,
    UserRole role = UserRole.guard,
    bool elevated = true,
  }) {
    return elevated 
        ? _getSurfaceColor(role)
        : container(context: context, role: role, opacity: alphaSolid);
  }
  
  /// Overlay background for bottom sheets and drawers
  static Color overlay({
    required BuildContext context,
    double opacity = alphaMedium,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return isDark 
        ? Colors.black.withValues(alpha: opacity + 0.2)
        : Colors.black.withValues(alpha: opacity);
  }

  /// Premium gradient background voor guard dashboard
  static Widget guardPremiumBackground({
    required Widget child,
    bool enableGradient = true,
  }) {
    if (!enableGradient) {
      return Container(
        color: const Color(0xFFF5F7FA),
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF5F7FA), // Zachte blauw-grijs
            const Color(0xFFE8ECF2), // Iets donkerder blauw-grijs
            const Color(0xFFF0F3F8), // Lichtere variant
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtiele pattern overlay voor extra diepte
          Positioned.fill(
            child: CustomPaint(
              painter: _SubtlePatternPainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }

  /// Mesh gradient background voor moderne, stoerdere uitstraling
  static Widget guardMeshGradient({
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        // Basis gradient met verhoogde navy intensiteit
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.8,
          colors: [
            DesignTokens.guardPrimary.withValues(alpha: 0.10), // Verhoogd van 0.05 naar 0.10
            const Color(0xFFEDF1F5), // Iets donkerder basis
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          // Secundaire gradient voor diepte
          gradient: RadialGradient(
            center: Alignment.bottomLeft,
            radius: 1.8,
            colors: [
              DesignTokens.guardAccent.withValues(alpha: 0.06), // Verhoogd van 0.03 naar 0.06
              Colors.transparent,
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            // Tertiary gradient voor stoere steel accent
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF475569).withValues(alpha: 0.02), // Steel grey accent
                Colors.transparent,
                const Color(0xFF1E293B).withValues(alpha: 0.03), // Donkere authoritative accent
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: child,
        ),
      ),
    );
  }

}

/// Subtiele pattern painter voor achtergrond
class _SubtlePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Teken subtiele cirkels voor diepte
    for (double x = 0; x < size.width; x += 100) {
      for (double y = 0; y < size.height; y += 100) {
        canvas.drawCircle(
          Offset(x + 50, y + 50),
          30,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// SUPPORTING TYPES
// ============================================================================

/// Performance tier for device capabilities
enum PerformanceTier {
  low,    // Budget devices
  medium, // Mid-range devices
  high,   // High-end devices
}

/// Glass morphism intensity levels
enum GlassIntensity {
  subtle,   // Battery conscious
  standard, // Default professional
  premium,  // High-end experience
}

/// Background type options
enum BackgroundType {
  solid,    // Flat color
  gradient, // Linear gradient
  glass,    // Glass morphism
}

/// Gradient type options
enum GradientType {
  primary, // Primary color gradient
  accent,  // Accent color gradient
  subtle,  // Subtle white gradient
}

/// Internal glass configuration
class _GlassConfig {
  final double blurStrength;
  final double opacity;
  final double highlightOpacity;
  
  const _GlassConfig({
    required this.blurStrength,
    required this.opacity,
    required this.highlightOpacity,
  });
}