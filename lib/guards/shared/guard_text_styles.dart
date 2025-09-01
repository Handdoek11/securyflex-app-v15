import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';

/// Standardized text styles for guard screens
/// 
/// This class provides consistent typography across all guard-facing
/// screens in SecuryFlex, ensuring professional appearance and
/// brand consistency. All styles use DesignTokens for maintainability.
/// 
/// Usage:
/// ```dart
/// Text('Job Title', style: GuardTextStyles.jobTitle(context))
/// Text('Company name', style: GuardTextStyles.jobCompany(context))
/// ```
class GuardTextStyles {
  // Private constructor to prevent instantiation
  GuardTextStyles._();

  /// Get color scheme for guard role
  static ColorScheme _getColorScheme(BuildContext context) {
    return SecuryFlexTheme.getColorScheme(UserRole.guard);
  }

  /// Job title text style - primary heading for job cards
  static TextStyle jobTitle(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeBodyLarge,    // Moderate size
    fontWeight: DesignTokens.fontWeightSemiBold, // Moderate weight
    color: _getColorScheme(context).onSurface,
    height: 1.3,
  );

  /// Company name text style - secondary information
  static TextStyle jobCompany(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeCaption,      // Smaller size
    fontWeight: DesignTokens.fontWeightRegular,  // Regular weight
    color: _getColorScheme(context).onSurfaceVariant,
    height: 1.3,
  );

  /// Job location text style - location and distance information
  static TextStyle jobLocation(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeCaption,      // Smaller like company
    fontWeight: DesignTokens.fontWeightRegular,
    color: _getColorScheme(context).onSurfaceVariant,
    height: 1.3,
  );

  /// Job rating text style - for review counts and ratings
  static TextStyle jobRating(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeBody,
    fontWeight: DesignTokens.fontWeightRegular,
    color: DesignTokens.colorGray700,
    height: 1.4,
  );

  /// Job salary text style - prominent salary display
  static TextStyle jobSalary(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeBodyLarge,    // Smaller size
    fontWeight: DesignTokens.fontWeightSemiBold, // Moderate weight
    color: _getColorScheme(context).primary,     // Primary color
    height: 1.2,
  );

  /// Job salary unit text style - "/per uur" text
  static TextStyle jobSalaryUnit(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeCaption,      // Smaller size
    fontWeight: DesignTokens.fontWeightRegular,
    color: _getColorScheme(context).onSurfaceVariant,  // Semantic color
    height: 1.3,
  );

  /// Status badge text style - for application status badges
  static TextStyle statusBadge(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeCaption,
    fontWeight: DesignTokens.fontWeightSemiBold,
    color: DesignTokens.colorWhite,
    height: 1.2,
  );

  /// Dashboard heading text style - for section headers
  static TextStyle dashboardHeading(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeTitleLarge,
    fontWeight: DesignTokens.fontWeightBold,
    color: _getColorScheme(context).onSurface,
    height: 1.2,
  );

  /// Dashboard subheading text style - for subsection headers
  static TextStyle dashboardSubheading(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeTitle,
    fontWeight: DesignTokens.fontWeightSemiBold,
    color: _getColorScheme(context).onSurface,
    height: 1.3,
  );

  /// Body text style - for general content
  static TextStyle bodyText(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeBody,
    fontWeight: DesignTokens.fontWeightRegular,
    color: _getColorScheme(context).onSurface,
    height: 1.4,
  );

  /// Caption text style - for small, secondary information
  static TextStyle caption(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeCaption,
    fontWeight: DesignTokens.fontWeightRegular,
    color: DesignTokens.colorGray600,
    height: 1.3,
  );

  /// Button text style - for button labels
  static TextStyle button(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeBody,
    fontWeight: DesignTokens.fontWeightSemiBold,
    color: DesignTokens.colorWhite,
    height: 1.2,
  );

  /// Tab text style - for tab navigation
  static TextStyle tab(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeBody,
    fontWeight: DesignTokens.fontWeightMedium,
    color: _getColorScheme(context).onSurface,
    height: 1.2,
  );

  /// Notification text style - for notification content
  static TextStyle notification(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeBody,
    fontWeight: DesignTokens.fontWeightRegular,
    color: _getColorScheme(context).onSurface,
    height: 1.4,
  );

  /// Error text style - for error messages
  static TextStyle error(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeBody,
    fontWeight: DesignTokens.fontWeightMedium,
    color: DesignTokens.colorError,
    height: 1.4,
  );

  /// Success text style - for success messages
  static TextStyle success(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeBody,
    fontWeight: DesignTokens.fontWeightMedium,
    color: DesignTokens.statusCompleted,
    height: 1.4,
  );

  /// Warning text style - for warning messages
  static TextStyle warning(BuildContext context) => TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: DesignTokens.fontSizeBody,
    fontWeight: DesignTokens.fontWeightMedium,
    color: DesignTokens.colorWarning,
    height: 1.4,
  );
}