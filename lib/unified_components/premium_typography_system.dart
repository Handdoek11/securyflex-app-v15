import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';
import 'premium_color_system.dart';

/// **Premium Typography System - Professional Hierarchy**
/// 
/// Next-level typography system for security industry trust-building:
/// - Professional font hierarchy optimized for Dutch business context
/// - Security industry-specific text styles with enhanced readability
/// - Role-based typography variations that build authority and trust
/// - Advanced text styling with gradients and sophisticated effects
/// - Accessibility-compliant contrast ratios and responsive scaling
/// 
/// This typography system elevates SecuryFlex from standard text to
/// premium professional communication that builds confidence and trust.

class PremiumTypography {
  PremiumTypography._();

  // ============================================================================
  // ENHANCED DISPLAY HIERARCHY
  // ============================================================================

  /// **Hero Display** - Large impactful headings for hero sections
  static TextStyle heroDisplay(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: _getResponsiveFontSize(context, base: 48.0),
      fontWeight: DesignTokens.fontWeightBold,
      height: 1.1,
      letterSpacing: -0.5,
      color: color ?? _getRoleTextColor(role, isPrimary: true),
    );
  }

  /// **Section Display** - Major section headings with professional authority
  static TextStyle sectionDisplay(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: _getResponsiveFontSize(context, base: 36.0),
      fontWeight: DesignTokens.fontWeightBold,
      height: 1.2,
      letterSpacing: -0.3,
      color: color ?? _getRoleTextColor(role, isPrimary: true),
    );
  }

  /// **Professional Heading** - Primary headings for security industry trust
  static TextStyle professionalHeading(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: _getResponsiveFontSize(context, base: 28.0),
      fontWeight: DesignTokens.fontWeightSemiBold,
      height: 1.3,
      letterSpacing: -0.2,
      color: color ?? _getRoleTextColor(role, isPrimary: true),
    );
  }

  /// **Subheading Professional** - Secondary headings with refined hierarchy
  static TextStyle subheadingProfessional(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: _getResponsiveFontSize(context, base: 22.0),
      fontWeight: DesignTokens.fontWeightSemiBold,
      height: 1.35,
      letterSpacing: -0.1,
      color: color ?? _getRoleTextColor(role, isPrimary: true),
    );
  }

  // ============================================================================
  // BODY TEXT HIERARCHY - ENHANCED READABILITY
  // ============================================================================

  /// **Body Professional** - Primary body text optimized for business content
  static TextStyle bodyProfessional(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: _getResponsiveFontSize(context, base: 16.0),
      fontWeight: DesignTokens.fontWeightRegular,
      height: 1.6,
      letterSpacing: 0.0,
      color: color ?? _getRoleTextColor(role, isPrimary: true),
    );
  }

  /// **Body Emphasis** - Emphasized body text for important information
  static TextStyle bodyEmphasis(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: _getResponsiveFontSize(context, base: 16.0),
      fontWeight: DesignTokens.fontWeightMedium,
      height: 1.6,
      letterSpacing: 0.0,
      color: color ?? _getRoleTextColor(role, isPrimary: true),
    );
  }

  /// **Body Secondary** - Supporting text with reduced visual weight
  static TextStyle bodySecondary(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: _getResponsiveFontSize(context, base: 15.0),
      fontWeight: DesignTokens.fontWeightRegular,
      height: 1.5,
      letterSpacing: 0.0,
      color: color ?? _getRoleTextColor(role, isPrimary: false),
    );
  }

  /// **Body Compact** - Dense text for data-heavy interfaces
  static TextStyle bodyCompact(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: _getResponsiveFontSize(context, base: 14.0),
      fontWeight: DesignTokens.fontWeightRegular,
      height: 1.4,
      letterSpacing: 0.1,
      color: color ?? _getRoleTextColor(role, isPrimary: true),
    );
  }

  // ============================================================================
  // SPECIALIZED SECURITY TYPOGRAPHY
  // ============================================================================

  /// **Security Badge Text** - Typography for status badges and indicators
  static TextStyle securityBadge(BuildContext context, {Color? color, bool isActive = false}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 12.0,
      fontWeight: isActive ? DesignTokens.fontWeightSemiBold : DesignTokens.fontWeightMedium,
      height: 1.3,
      letterSpacing: 0.3,
      color: color ?? (isActive ? DesignTokens.guardPrimary : DesignTokens.guardTextSecondary),
    );
  }

  /// **Financial Display** - Typography for earnings and financial data
  static TextStyle financialDisplay(BuildContext context, {Color? color, bool isLarge = false}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: isLarge ? 28.0 : 20.0,
      fontWeight: DesignTokens.fontWeightBold,
      height: 1.2,
      letterSpacing: -0.2,
      color: color ?? DesignTokens.colorSuccess,
    );
  }

  /// **Metadata Text** - Small supporting text for dates, times, and metadata
  static TextStyle metadata(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 12.0,
      fontWeight: DesignTokens.fontWeightRegular,
      height: 1.4,
      letterSpacing: 0.2,
      color: color ?? _getRoleTextColor(role, isPrimary: false, isMetadata: true),
    );
  }

  /// **Professional Caption** - Enhanced captions with better hierarchy
  static TextStyle professionalCaption(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 13.0,
      fontWeight: DesignTokens.fontWeightMedium,
      height: 1.35,
      letterSpacing: 0.15,
      color: color ?? _getRoleTextColor(role, isPrimary: false),
    );
  }

  // ============================================================================
  // INTERACTIVE ELEMENT TYPOGRAPHY
  // ============================================================================

  /// **Button Primary** - Primary button text with authority
  static TextStyle buttonPrimary(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 16.0,
      fontWeight: DesignTokens.fontWeightSemiBold,
      height: 1.3,
      letterSpacing: 0.1,
      color: color ?? Colors.white,
    );
  }

  /// **Button Secondary** - Secondary button text
  static TextStyle buttonSecondary(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 16.0,
      fontWeight: DesignTokens.fontWeightMedium,
      height: 1.3,
      letterSpacing: 0.1,
      color: color ?? _getRoleTextColor(role, isPrimary: true),
    );
  }

  /// **Link Professional** - Professional links with trust-building styling
  static TextStyle linkProfessional(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 15.0,
      fontWeight: DesignTokens.fontWeightMedium,
      height: 1.4,
      letterSpacing: 0.0,
      color: color ?? _getRoleTextColor(role, isPrimary: true),
      decoration: TextDecoration.underline,
      decorationColor: color ?? _getRoleTextColor(role, isPrimary: true),
    );
  }

  /// **Navigation Text** - Typography for navigation elements
  static TextStyle navigation(BuildContext context, {Color? color, UserRole? role, bool isActive = false}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 14.0,
      fontWeight: isActive ? DesignTokens.fontWeightSemiBold : DesignTokens.fontWeightMedium,
      height: 1.3,
      letterSpacing: 0.1,
      color: color ?? (isActive 
          ? _getRoleTextColor(role, isPrimary: true)
          : _getRoleTextColor(role, isPrimary: false)),
    );
  }

  // ============================================================================
  // PREMIUM ENHANCED TEXT STYLES
  // ============================================================================

  /// **Premium Title with Gradient** - Eye-catching titles with gradient effects
  static Widget premiumGradientTitle(
    BuildContext context,
    String text, {
    UserRole? role,
    LinearGradient? customGradient,
    double? fontSize,
  }) {
    final gradient = customGradient ?? PremiumColors.getRoleGradient(role ?? UserRole.guard);
    
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: fontSize ?? _getResponsiveFontSize(context, base: 32.0),
          fontWeight: DesignTokens.fontWeightBold,
          height: 1.2,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  /// **Trust-Building Professional Text** - Enhanced text with trust elements
  static Widget trustProfessionalText(
    BuildContext context,
    String text, {
    UserRole? role,
    bool showTrustIcon = false,
    IconData? trustIcon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTrustIcon) ...[
          Icon(
            trustIcon ?? Icons.verified_user,
            size: 16,
            color: _getRoleTextColor(role, isPrimary: true),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: bodyProfessional(context, role: role),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // DUTCH LOCALIZATION TYPOGRAPHY
  // ============================================================================

  /// **Dutch Professional Heading** - Optimized for Dutch business language
  static TextStyle dutchProfessionalHeading(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: _getResponsiveFontSize(context, base: 24.0),
      fontWeight: DesignTokens.fontWeightSemiBold,
      height: 1.35, // Optimized for Dutch text length
      letterSpacing: -0.1,
      color: color ?? _getRoleTextColor(role, isPrimary: true),
    );
  }

  /// **Dutch Business Body** - Body text optimized for Dutch business content
  static TextStyle dutchBusinessBody(BuildContext context, {Color? color, UserRole? role}) {
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: _getResponsiveFontSize(context, base: 15.0),
      fontWeight: DesignTokens.fontWeightRegular,
      height: 1.65, // Extra line height for Dutch readability
      letterSpacing: 0.0,
      color: color ?? _getRoleTextColor(role, isPrimary: true),
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get responsive font size based on screen width
  static double _getResponsiveFontSize(BuildContext context, {required double base}) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > DesignTokens.breakpointDesktop) {
      return base * 1.1; // Slightly larger on desktop
    } else if (screenWidth < DesignTokens.breakpointMobile) {
      return base * 0.9; // Slightly smaller on small mobile
    }
    
    return base;
  }

  /// Get role-based text color
  static Color _getRoleTextColor(UserRole? role, {required bool isPrimary, bool isMetadata = false}) {
    if (isMetadata) {
      return DesignTokens.colorGray500;
    }
    
    switch (role) {
      case UserRole.guard:
        return isPrimary ? DesignTokens.guardTextPrimary : DesignTokens.guardTextSecondary;
      case UserRole.company:
        return isPrimary ? DesignTokens.companyTextPrimary : DesignTokens.companyTextSecondary;
      case UserRole.admin:
        return isPrimary ? DesignTokens.adminTextPrimary : DesignTokens.adminTextSecondary;
      case null:
        return isPrimary ? DesignTokens.guardTextPrimary : DesignTokens.guardTextSecondary;
    }
  }
}

/// **Premium Text Theme Extensions**
/// Extended TextTheme for consistent app-wide typography
class PremiumTextTheme {
  static TextTheme create(BuildContext context, {UserRole role = UserRole.guard}) {
    return TextTheme(
      // Display styles
      displayLarge: PremiumTypography.heroDisplay(context, role: role),
      displayMedium: PremiumTypography.sectionDisplay(context, role: role),
      displaySmall: PremiumTypography.professionalHeading(context, role: role),
      
      // Headline styles
      headlineLarge: PremiumTypography.professionalHeading(context, role: role),
      headlineMedium: PremiumTypography.subheadingProfessional(context, role: role),
      headlineSmall: PremiumTypography.dutchProfessionalHeading(context, role: role),
      
      // Title styles
      titleLarge: PremiumTypography.subheadingProfessional(context, role: role),
      titleMedium: PremiumTypography.dutchProfessionalHeading(context, role: role),
      titleSmall: PremiumTypography.bodyEmphasis(context, role: role),
      
      // Body styles
      bodyLarge: PremiumTypography.bodyProfessional(context, role: role),
      bodyMedium: PremiumTypography.dutchBusinessBody(context, role: role),
      bodySmall: PremiumTypography.bodyCompact(context, role: role),
      
      // Label styles
      labelLarge: PremiumTypography.buttonPrimary(context),
      labelMedium: PremiumTypography.buttonSecondary(context, role: role),
      labelSmall: PremiumTypography.professionalCaption(context, role: role),
    );
  }
}

/// **Typography Usage Helper**
/// Utility widget for consistent typography implementation
class PremiumText extends StatelessWidget {
  final String text;
  final PremiumTextStyle style;
  final UserRole? role;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool showGradient;
  final LinearGradient? gradient;

  const PremiumText(
    this.text, {
    super.key,
    required this.style,
    this.role,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.showGradient = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = _getTextStyle(context);
    
    if (showGradient) {
      final effectiveGradient = gradient ?? PremiumColors.getRoleGradient(role ?? UserRole.guard);
      return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => effectiveGradient.createShader(bounds),
        child: Text(
          text,
          style: textStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
      );
    }
    
    return Text(
      text,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextStyle _getTextStyle(BuildContext context) {
    switch (style) {
      case PremiumTextStyle.heroDisplay:
        return PremiumTypography.heroDisplay(context, color: color, role: role);
      case PremiumTextStyle.sectionDisplay:
        return PremiumTypography.sectionDisplay(context, color: color, role: role);
      case PremiumTextStyle.professionalHeading:
        return PremiumTypography.professionalHeading(context, color: color, role: role);
      case PremiumTextStyle.subheadingProfessional:
        return PremiumTypography.subheadingProfessional(context, color: color, role: role);
      case PremiumTextStyle.bodyProfessional:
        return PremiumTypography.bodyProfessional(context, color: color, role: role);
      case PremiumTextStyle.bodyEmphasis:
        return PremiumTypography.bodyEmphasis(context, color: color, role: role);
      case PremiumTextStyle.bodySecondary:
        return PremiumTypography.bodySecondary(context, color: color, role: role);
      case PremiumTextStyle.bodyCompact:
        return PremiumTypography.bodyCompact(context, color: color, role: role);
      case PremiumTextStyle.securityBadge:
        return PremiumTypography.securityBadge(context, color: color);
      case PremiumTextStyle.financialDisplay:
        return PremiumTypography.financialDisplay(context, color: color);
      case PremiumTextStyle.metadata:
        return PremiumTypography.metadata(context, color: color, role: role);
      case PremiumTextStyle.professionalCaption:
        return PremiumTypography.professionalCaption(context, color: color, role: role);
      case PremiumTextStyle.buttonPrimary:
        return PremiumTypography.buttonPrimary(context, color: color);
      case PremiumTextStyle.buttonSecondary:
        return PremiumTypography.buttonSecondary(context, color: color, role: role);
      case PremiumTextStyle.linkProfessional:
        return PremiumTypography.linkProfessional(context, color: color, role: role);
      case PremiumTextStyle.navigation:
        return PremiumTypography.navigation(context, color: color, role: role);
      case PremiumTextStyle.dutchProfessionalHeading:
        return PremiumTypography.dutchProfessionalHeading(context, color: color, role: role);
      case PremiumTextStyle.dutchBusinessBody:
        return PremiumTypography.dutchBusinessBody(context, color: color, role: role);
    }
  }
}

/// Enum for Premium Text Styles
enum PremiumTextStyle {
  heroDisplay,
  sectionDisplay,
  professionalHeading,
  subheadingProfessional,
  bodyProfessional,
  bodyEmphasis,
  bodySecondary,
  bodyCompact,
  securityBadge,
  financialDisplay,
  metadata,
  professionalCaption,
  buttonPrimary,
  buttonSecondary,
  linkProfessional,
  navigation,
  dutchProfessionalHeading,
  dutchBusinessBody,
}