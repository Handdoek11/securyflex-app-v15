import 'package:flutter/material.dart';

/// SecuryFlex Enhanced Design Tokens V2 - Production Ready
/// 
/// Complete design token system with backward compatibility and all properties
/// required by the existing codebase. Optimized for performance, accessibility, 
/// and consistency across all SecuryFlex applications.
class DesignTokens {
  DesignTokens._(); // Private constructor to prevent instantiation

  // ============================================================================
  // VERSION & MIGRATION MANAGEMENT
  // ============================================================================
  
  static const String version = '2.0.0';
  static const String migrationGuideUrl = 'https://docs.securyflex.nl/design-tokens/v2-migration';
  
  // Removed unused field _enableNewSpacingSystem
  // TODO: Implement mobile-optimized spacing system if needed

  // ============================================================================
  // TYPOGRAPHY SYSTEM - Consolidated & Optimized
  // ============================================================================

  /// Primary font family - Standardized to Work Sans for optimal Dutch readability
  /// Work Sans provides superior screen readability, accessibility compliance,
  /// and cultural alignment with Dutch design preferences
  static const String fontFamily = 'WorkSans';

  /// Legacy font family support (deprecated but maintained for compatibility)
  @Deprecated('Use fontFamily instead. Will be removed in v3.0.0')
  static const String fontFamilyPrimary = 'WorkSans';
  @Deprecated('Use fontFamily instead. Will be removed in v3.0.0')
  static const String fontFamilySecondary = 'WorkSans';

  /// Font weight scale - Optimized for web fonts
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  /// Mobile-optimized font size scale with responsive support
  static const double fontSizeXS = 10.0;
  static const double fontSizeS = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSizeXXL = 20.0;

  // Semantic font sizes with responsive scaling
  static const double fontSizeCaption = 12.0;
  static const double fontSizeMeta = 14.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeBodyLarge = 16.0;
  static const double fontSizeSubtitle = 18.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeTitleLarge = 22.0;
  static const double fontSizeHeading = 24.0;
  static const double fontSizeHeadingLarge = 28.0;
  static const double fontSizeDisplay = 32.0;
  static const double fontSizeDisplayLarge = 36.0;

  // Section-specific font sizes
  static const double fontSizeSection = 20.0;
  static const double fontSizeHeadline = 28.0;

  /// Line height multipliers optimized for mobile readability
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;

  /// Letter spacing values
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingExtraWide = 1.0;

  // ============================================================================
  // COLOR SYSTEM - WCAG 2.1 AA Compliant
  // ============================================================================

  // Base Colors
  static const Color colorWhite = Color(0xFFFFFFFF);
  static const Color colorBlack = Color(0xFF000000);

  // Gray Scale - Optimized for accessibility
  static const Color colorGray50 = Color(0xFFFAFAFA);
  static const Color colorGray100 = Color(0xFFF5F5F5);
  static const Color colorGray200 = Color(0xFFE5E5E5);
  static const Color colorGray300 = Color(0xFFD4D4D4);
  static const Color colorGray400 = Color(0xFFA3A3A3);
  static const Color colorGray500 = Color(0xFF737373);
  static const Color colorGray600 = Color(0xFF525252);
  static const Color colorGray700 = Color(0xFF404040);
  static const Color colorGray800 = Color(0xFF262626);
  static const Color colorGray900 = Color(0xFF171717);

  // Primary Brand Colors
  static const Color colorPrimaryBlue = Color(0xFF1E3A8A);
  static const Color colorPrimaryBlueLight = Color(0xFF3B82F6);
  static const Color colorPrimaryBlueDark = Color(0xFF1E40AF);

  // Secondary Brand Colors
  static const Color colorSecondaryTeal = Color(0xFF54D3C2);
  static const Color colorSecondaryTealLight = Color(0xFF7DD3FC);
  static const Color colorSecondaryTealDark = Color(0xFF0891B2);

  // Semantic Colors - WCAG 2.1 AA Compliant
  static const Color colorSuccess = Color(0xFF10B981);
  static const Color colorSuccessLight = Color(0xFF34D399);
  static const Color colorSuccessDark = Color(0xFF059669);

  static const Color colorWarning = Color(0xFFF59E0B);
  static const Color colorWarningLight = Color(0xFFFBBF24);
  static const Color colorWarningDark = Color(0xFFD97706);

  static const Color colorError = Color(0xFFEF4444);
  static const Color colorErrorLight = Color(0xFFF87171);
  static const Color colorErrorDark = Color(0xFFDC2626);

  static const Color colorInfo = Color(0xFF3B82F6);
  static const Color colorInfoLight = Color(0xFF60A5FA);
  static const Color colorInfoDark = Color(0xFF2563EB);

  // Text Colors
  static const Color darkText = Color(0xFF17262A);
  static const Color lightText = Color(0xFFFFFFFF);
  static const Color mutedText = Color(0xFF4A6572);

  // Status Color System - Enhanced for SecuryFlex
  static const Color statusPending = colorWarning;
  static const Color statusAccepted = colorInfo;
  static const Color statusConfirmed = colorSuccess;
  static const Color statusInProgress = colorPrimaryBlue;
  static const Color statusCompleted = colorSuccessLight;
  static const Color statusCancelled = colorError;
  static const Color statusDraft = colorGray500;
  static const Color statusExpired = colorWarningLight;
  static const Color statusPaused = colorGray600;
  static const Color statusArchived = colorGray400;

  // Priority Colors
  static const Color priorityLow = colorGray500;
  static const Color priorityMedium = colorWarning;
  static const Color priorityHigh = colorError;
  static const Color priorityUrgent = Color(0xFFDC2626);

  // Role-based Colors
  static const Color guardPrimary = colorPrimaryBlue;
  static const Color guardPrimaryLight = colorPrimaryBlueLight;
  static const Color guardAccent = colorSecondaryTeal;
  static const Color guardBackground = Color(0xFFF2F3F8);
  static const Color guardSurface = colorWhite;
  static const Color guardTextPrimary = Color(0xFF17262A);
  static const Color guardTextSecondary = Color(0xFF4A6572);

  // Material 3 Surface Container System - Guard Role
  static const Color guardSurfaceContainer = Color(0xFFF5F7FA);          // Subtle blue-grey for cards
  static const Color guardSurfaceContainerLow = Color(0xFFF0F3F8);       // Light blue-grey for elevated elements
  static const Color guardSurfaceContainerLowest = Color(0xFFF8F9FB);    // Barely tinted for background
  static const Color guardSurfaceContainerHigh = Color(0xFFEDF1F5);      // Medium blue-grey for alerts
  static const Color guardSurfaceContainerHighest = Color(0xFFE8ECF2);   // Strong blue-grey for modals

  static const Color companyPrimary = Color(0xFF475569);      // Professional slate blue
  static const Color companyPrimaryLight = Color(0xFF64748B);  // Lighter slate for containers  
  static const Color companyAccent = Color(0xFF334155);        // Darker slate for accents
  static const Color companyTeal = colorSecondaryTeal; // Alias for backward compatibility
  static const Color companyBackground = Color(0xFFF8FAFC);    // Clean slate-tinted background
  
  // Additional color aliases for backward compatibility
  static const Color revenueGreen = colorSuccess;
  static const Color analyticsBlue = colorInfo;
  static const Color jobOrange = colorWarning;
  static const Color successGreen = colorSuccess;
  static const Color companyTextPrimary = Color(0xFF17262A);
  static const Color companyTextSecondary = Color(0xFF4A6572);

  static const Color adminPrimary = Color(0xFF2D3748);
  static const Color adminPrimaryLight = Color(0xFF4A5568);
  static const Color adminAccent = colorWarning;
  static const Color adminBackground = Color(0xFFF7FAFC);
  static const Color adminSurface = colorWhite;
  static const Color adminTextPrimary = Color(0xFF1A202C);
  static const Color adminTextSecondary = Color(0xFF4A5568);

  // ============================================================================
  // SPACING SYSTEM - Mobile-First with Compatibility Layer
  // ============================================================================

  // Spacing system - const values for compile-time constants
  static const double spacingXXS = 2.0;
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0; // Fixed to current value for const compatibility
  static const double spacingL = 24.0; // Fixed to current value for const compatibility
  static const double spacingXL = 32.0; // Fixed to current value for const compatibility
  static const double spacingXXL = 40.0; // Fixed to current value for const compatibility  
  static const double spacingXXXL = 48.0;

  // Legacy spacing values (deprecated but maintained for compatibility)
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingExtraLarge = 32.0;

  // Component-specific spacing - const for compile-time usage
  static const double spacingCardPadding = spacingM;
  static const double spacingButtonPadding = spacingM;
  static const double spacingInputPadding = spacingM;
  static const double spacingHeaderPadding = spacingS;
  static const double spacingSectionSpacing = spacingL;

  // ============================================================================
  // TABBAR SYSTEM - Material Design 3 Compliant Heights
  // ============================================================================
  
  /// Standard TabBar height - Material Design 3 specification (48dp)
  static const double tabBarHeight = 48.0;
  
  /// Compact TabBar height for dense layouts (40dp)
  static const double tabBarHeightCompact = 40.0;
  
  /// Large TabBar height for desktop/large screens (56dp)
  static const double tabBarHeightLarge = 56.0;
  
  /// Tab indicator height (active tab underline)
  static const double tabIndicatorHeight = 3.0;
  
  /// Horizontal padding within tabs
  static const double tabPadding = spacingM;
  
  /// Minimum tab width for proper touch targets
  static const double tabMinWidth = 90.0;
  
  /// Icon size within tabs
  static const double tabIconSize = 24.0;

  // ============================================================================
  // ICON SIZE SYSTEM
  // ============================================================================

  static const double iconSizeXS = 12.0;
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 20.0;
  static const double iconSizeL = 24.0;
  static const double iconSizeXL = 32.0;
  static const double iconSizeXXL = 40.0;

  // ============================================================================
  // BORDER RADIUS SYSTEM
  // ============================================================================

  static const double radiusNone = 0.0;
  static const double radiusXS = 2.0;
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 20.0;
  static const double radiusXXXL = 24.0;
  static const double radiusCircular = 32.0;
  static const double radiusFull = 9999.0;

  // Component-specific radius
  static const double radiusCard = radiusM;
  static const double radiusButton = radiusL;
  static const double radiusInput = radiusM;
  static const double radiusModal = radiusXL;

  // ============================================================================
  // SHADOW SYSTEM - Performance Optimized
  // ============================================================================

  static const BoxShadow shadowLight = BoxShadow(
    color: Color(0x0A000000),
    offset: Offset(0, 1),
    blurRadius: 2.0,
    spreadRadius: 0,
  );

  static const BoxShadow shadowMedium = BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 2),
    blurRadius: 8.0,
    spreadRadius: 0,
  );

  static const BoxShadow shadowHeavy = BoxShadow(
    color: Color(0x26000000),
    offset: Offset(0, 4),
    blurRadius: 16.0,
    spreadRadius: 0,
  );

  static const BoxShadow shadowExtraHeavy = BoxShadow(
    color: Color(0x33000000),
    offset: Offset(0, 8),
    blurRadius: 24.0,
    spreadRadius: 0,
  );

  // ============================================================================
  // ELEVATION SYSTEM - Material 3 Compliant
  // ============================================================================

  static const double elevationNone = 0.0;
  static const double elevationLow = 1.0;
  static const double elevationMedium = 3.0;
  static const double elevationHigh = 6.0;
  static const double elevationExtraHigh = 8.0;

  // Material 3 Elevation Levels
  static const double elevationLevel0 = 0.0;
  static const double elevationLevel1 = 1.0;
  static const double elevationLevel3 = 3.0;
  static const double elevationLevel6 = 6.0;
  static const double elevationLevel8 = 8.0;
  static const double elevationLevel12 = 12.0;

  // Surface Tint Alpha Values for Material 3
  static const double surfaceTintAlphaLevel1 = 0.05;  // Standard content cards
  static const double surfaceTintAlphaLevel3 = 0.08;  // Important notifications
  static const double surfaceTintAlphaLevel6 = 0.11;  // Urgent alerts
  static const double surfaceTintAlphaLevel8 = 0.14;  // Modal dialogs
  static const double surfaceTintAlphaLevel12 = 0.17; // Maximum elevation

  // ============================================================================
  // OPACITY SYSTEM
  // ============================================================================

  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.60;
  static const double opacityHigh = 0.87;
  static const double opacityFull = 1.0;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationExtraSlow = Duration(milliseconds: 800);

  // ============================================================================
  // BREAKPOINTS
  // ============================================================================

  static const double breakpointMobile = 480.0;
  static const double breakpointTablet = 768.0;
  static const double breakpointDesktop = 1024.0;
  static const double breakpointLargeDesktop = 1440.0;

  // ============================================================================
  // ACCESSIBILITY HELPERS
  // ============================================================================
  
  /// Get contrast-compliant text color for given background
  static Color getAccessibleTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? colorBlack : colorWhite;
  }
  
  /// Check if color combination meets WCAG 2.1 AA requirements
  static bool isAccessible(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    
    final lighterLuminance = [foregroundLuminance, backgroundLuminance].reduce((a, b) => a > b ? a : b);
    final darkerLuminance = [foregroundLuminance, backgroundLuminance].reduce((a, b) => a < b ? a : b);
    
    final contrastRatio = (lighterLuminance + 0.05) / (darkerLuminance + 0.05);
    return contrastRatio >= 4.5; // WCAG 2.1 AA requirement
  }

  // ============================================================================
  // VALIDATION & DEBUGGING
  // ============================================================================
  
  /// Validate all design tokens for consistency
  static Map<String, List<String>> validate() {
    final issues = <String, List<String>>{};
    
    // Validate color accessibility
    final colorIssues = <String>[];
    if (!isAccessible(guardTextPrimary, guardBackground)) {
      colorIssues.add('Guard text on background fails accessibility check');
    }
    if (!isAccessible(companyTextPrimary, companyBackground)) {
      colorIssues.add('Company text on background fails accessibility check');
    }
    if (!isAccessible(adminTextPrimary, adminBackground)) {
      colorIssues.add('Admin text on background fails accessibility check');
    }
    
    if (colorIssues.isNotEmpty) issues['colors'] = colorIssues;
    
    return issues;
  }

  /// Get migration recommendations for current usage
  static List<String> getMigrationRecommendations() {
    return [
      'Replace all Colors.* references with DesignTokens equivalents',
      'Update font family references to use single fontFamily constant',
      'Enable new spacing system by setting _enableNewSpacingSystem to true',
      'Run accessibility validation on all color combinations',
      'Update deprecated token references before v3.0.0',
    ];
  }
}

/// Design Token Usage Analytics
class DesignTokenAnalytics {
  static final Map<String, int> _usageCount = {};
  
  /// Track token usage for analytics
  static void trackUsage(String tokenName) {
    _usageCount[tokenName] = (_usageCount[tokenName] ?? 0) + 1;
  }
  
  /// Get usage statistics
  static Map<String, int> getUsageStats() => Map.from(_usageCount);
  
  /// Get most used tokens
  static List<MapEntry<String, int>> getTopUsedTokens([int limit = 10]) {
    final sorted = _usageCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }
}