import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';

/// User role enumeration for theme selection
enum UserRole {
  guard,    // Security personnel
  company,  // Business owners
  admin,    // Platform administrators
}

/// SecuryFlex Unified Theme System
/// 
/// This class provides a comprehensive theme system that supports role-based
/// theming while maintaining visual consistency across the entire application.
/// 
/// Features:
/// - Role-based color schemes (Guard, Company, Admin)
/// - Consistent typography using design tokens
/// - Unified component styling
/// - Dark/Light mode support (future)
/// 
/// Usage:
/// ```dart
/// // Get theme for specific user role
/// final theme = SecuryFlexTheme.getTheme(UserRole.guard);
/// 
/// // Use in MaterialApp
/// MaterialApp(
///   theme: SecuryFlexTheme.getTheme(currentUserRole),
///   // ...
/// )
/// ```
class SecuryFlexTheme {
  SecuryFlexTheme._(); // Private constructor

  /// Get theme data for specific user role
  static ThemeData getTheme(UserRole role) {
    switch (role) {
      case UserRole.guard:
        return _buildGuardTheme();
      case UserRole.company:
        return _buildCompanyTheme();
      case UserRole.admin:
        return _buildAdminTheme();
    }
  }

  /// Get color scheme for specific user role
  static ColorScheme getColorScheme(UserRole role) {
    switch (role) {
      case UserRole.guard:
        return _guardColorScheme;
      case UserRole.company:
        return _companyColorScheme;
      case UserRole.admin:
        return _adminColorScheme;
    }
  }

  // ============================================================================
  // SHARED TEXT THEME
  // ============================================================================
  
  static TextTheme get _baseTextTheme {
    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeDisplayLarge,
        fontWeight: DesignTokens.fontWeightBold,
        letterSpacing: DesignTokens.letterSpacingTight,
        height: DesignTokens.lineHeightTight,
      ),
      displayMedium: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeDisplay,
        fontWeight: DesignTokens.fontWeightBold,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightTight,
      ),
      displaySmall: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeHeadingLarge,
        fontWeight: DesignTokens.fontWeightSemiBold,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
      ),
      
      // Headline styles
      headlineLarge: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeHeading,
        fontWeight: DesignTokens.fontWeightSemiBold,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
      ),
      headlineMedium: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeTitleLarge,
        fontWeight: DesignTokens.fontWeightSemiBold,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
      ),
      headlineSmall: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeTitle,
        fontWeight: DesignTokens.fontWeightMedium,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
      ),
      
      // Title styles
      titleLarge: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeSubtitle,
        fontWeight: DesignTokens.fontWeightMedium,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
      ),
      titleMedium: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeBodyLarge,
        fontWeight: DesignTokens.fontWeightMedium,
        letterSpacing: DesignTokens.letterSpacingWide,
        height: DesignTokens.lineHeightNormal,
      ),
      titleSmall: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightMedium,
        letterSpacing: DesignTokens.letterSpacingWide,
        height: DesignTokens.lineHeightNormal,
      ),
      
      // Body styles
      bodyLarge: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeBodyLarge,
        fontWeight: DesignTokens.fontWeightRegular,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightRelaxed,
      ),
      bodyMedium: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightRelaxed,
      ),
      bodySmall: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeCaption,
        fontWeight: DesignTokens.fontWeightRegular,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
      ),
      
      // Label styles
      labelLarge: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightMedium,
        letterSpacing: DesignTokens.letterSpacingWide,
        height: DesignTokens.lineHeightNormal,
      ),
      labelMedium: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeCaption,
        fontWeight: DesignTokens.fontWeightMedium,
        letterSpacing: DesignTokens.letterSpacingWide,
        height: DesignTokens.lineHeightNormal,
      ),
      labelSmall: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeCaption,
        fontWeight: DesignTokens.fontWeightMedium,
        letterSpacing: DesignTokens.letterSpacingExtraWide,
        height: DesignTokens.lineHeightNormal,
      ),
    );
  }

  // ============================================================================
  // COLOR SCHEMES
  // ============================================================================
  
  static const ColorScheme _guardColorScheme = ColorScheme.light(
    primary: DesignTokens.guardPrimary,
    onPrimary: DesignTokens.colorWhite,
    primaryContainer: DesignTokens.guardPrimaryLight,
    onPrimaryContainer: DesignTokens.guardTextPrimary,
    secondary: DesignTokens.guardAccent,
    onSecondary: DesignTokens.colorWhite,
    secondaryContainer: DesignTokens.colorSecondaryTealLight,
    onSecondaryContainer: DesignTokens.guardTextPrimary,
    surface: DesignTokens.guardSurface,
    onSurface: DesignTokens.guardTextPrimary,
    surfaceContainer: DesignTokens.guardSurfaceContainer,
    surfaceContainerLow: DesignTokens.guardSurfaceContainerLow,
    surfaceContainerLowest: DesignTokens.guardSurfaceContainerLowest,
    surfaceContainerHigh: DesignTokens.guardSurfaceContainerHigh,
    surfaceContainerHighest: DesignTokens.guardSurfaceContainerHighest,
    onSurfaceVariant: DesignTokens.guardTextSecondary,
    error: DesignTokens.colorError,
    onError: DesignTokens.colorWhite,
    outline: DesignTokens.colorGray300,
    shadow: DesignTokens.colorBlack,
  );
  
  static const ColorScheme _companyColorScheme = ColorScheme.light(
    primary: DesignTokens.companyPrimary,
    onPrimary: DesignTokens.colorWhite,
    primaryContainer: DesignTokens.companyPrimaryLight,
    onPrimaryContainer: DesignTokens.companyTextPrimary,
    secondary: DesignTokens.companyAccent,
    onSecondary: DesignTokens.colorWhite,
    secondaryContainer: DesignTokens.colorPrimaryBlueLight,
    onSecondaryContainer: DesignTokens.companyTextPrimary,
    surface: DesignTokens.colorWhite,
    onSurface: DesignTokens.companyTextPrimary,
    surfaceContainerHighest: DesignTokens.companyBackground,
    onSurfaceVariant: DesignTokens.companyTextSecondary,
    error: DesignTokens.colorError,
    onError: DesignTokens.colorWhite,
    outline: DesignTokens.colorGray300,
    shadow: DesignTokens.colorBlack,
  );
  
  static const ColorScheme _adminColorScheme = ColorScheme.light(
    primary: DesignTokens.adminPrimary,
    onPrimary: DesignTokens.colorWhite,
    primaryContainer: DesignTokens.adminPrimaryLight,
    onPrimaryContainer: DesignTokens.adminTextPrimary,
    secondary: DesignTokens.adminAccent,
    onSecondary: DesignTokens.colorWhite,
    secondaryContainer: DesignTokens.colorWarningLight,
    onSecondaryContainer: DesignTokens.adminTextPrimary,
    surface: DesignTokens.adminSurface,
    onSurface: DesignTokens.adminTextPrimary,
    surfaceContainerHighest: DesignTokens.adminBackground,
    onSurfaceVariant: DesignTokens.adminTextSecondary,
    error: DesignTokens.colorError,
    onError: DesignTokens.colorWhite,
    outline: DesignTokens.colorGray300,
    shadow: DesignTokens.colorBlack,
  );

  // ============================================================================
  // THEME BUILDERS
  // ============================================================================
  
  static ThemeData _buildGuardTheme() {
    return _buildBaseTheme(_guardColorScheme);
  }
  
  static ThemeData _buildCompanyTheme() {
    return _buildBaseTheme(_companyColorScheme);
  }
  
  static ThemeData _buildAdminTheme() {
    return _buildBaseTheme(_adminColorScheme);
  }
  
  static ThemeData _buildBaseTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _baseTextTheme,
      fontFamily: DesignTokens.fontFamily,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: DesignTokens.elevationNone,
        centerTitle: true,
        titleTextStyle: _baseTextTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: DesignTokens.elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        ),
        margin: EdgeInsets.all(DesignTokens.spacingS),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: DesignTokens.elevationMedium,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingButtonPadding,
            vertical: DesignTokens.spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          ),
          textStyle: _baseTextTheme.labelLarge,
        ),
      ),
      
      // Input Decoration Theme - Material 3 Enhanced
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        // Filled variant borders (default for forms)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: EdgeInsets.all(DesignTokens.spacingInputPadding),
        // Material 3 Typography
        labelStyle: _baseTextTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: _baseTextTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        errorStyle: _baseTextTheme.bodySmall?.copyWith(
          color: colorScheme.error,
        ),
      ),
      
      // TabBar Theme - Material 3 compliant
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        indicatorColor: colorScheme.primary,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightSemiBold,
          fontFamily: DesignTokens.fontFamily,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightMedium,
          fontFamily: DesignTokens.fontFamily,
        ),
      ),
      
      // BottomSheet Theme - Material 3 compliant
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusL),
          ),
        ),
        dragHandleColor: colorScheme.onSurfaceVariant,
        dragHandleSize: const Size(32, 4),
      ),
      
      // Scaffold Theme
      scaffoldBackgroundColor: colorScheme.surfaceContainerHighest,
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: DesignTokens.spacingS,
      ),
    );
  }
}
