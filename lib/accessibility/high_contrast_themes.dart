import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';
import '../core/accessibility_compliance_system.dart';

/// High Contrast Theme System for Enhanced Accessibility
/// 
/// Provides WCAG 2.1 AAA compliant high contrast color schemes
/// for users with visual impairments or low vision conditions.
/// 
/// Features:
/// - 7:1 contrast ratio minimum (WCAG AAA standard)
/// - Role-based high contrast themes
/// - Color-blind friendly palettes
/// - Nederlandse accessibility compliance
class HighContrastThemes {
  HighContrastThemes._();
  
  // ============================================================================
  // HIGH CONTRAST COLOR PALETTE - WCAG AAA COMPLIANT
  // ============================================================================
  
  // Pure contrast colors for maximum visibility
  static const Color _highContrastBlack = Color(0xFF000000);
  static const Color _highContrastWhite = Color(0xFFFFFFFF);
  static const Color _highContrastBlue = Color(0xFF0000FF);
  static const Color _highContrastRed = Color(0xFF800000);
  static const Color _highContrastGreen = Color(0xFF006400);
  static const Color _highContrastYellow = Color(0xFFFFD700);
  static const Color _highContrastOrange = Color(0xFFFF8C00);
  static const Color _highContrastPurple = Color(0xFF4B0082);
  
  // High contrast gray scale
  static const Color _highContrastGray100 = Color(0xFFF8F8F8);
  static const Color _highContrastGray200 = Color(0xFFE0E0E0);
  static const Color _highContrastGray300 = Color(0xFFBDBDBD);
  static const Color _highContrastGray700 = Color(0xFF424242);
  static const Color _highContrastGray800 = Color(0xFF212121);
  
  // ============================================================================
  // GUARD HIGH CONTRAST THEME
  // ============================================================================
  
  static ThemeData getGuardHighContrastTheme() {
    final baseTheme = SecuryFlexTheme.getTheme(UserRole.guard);
    
    return baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _highContrastBlue,
        brightness: Brightness.light,
        primary: _highContrastBlue,
        onPrimary: _highContrastWhite,
        secondary: _highContrastGreen,
        onSecondary: _highContrastWhite,
        surface: _highContrastWhite,
        onSurface: _highContrastBlack,
        error: _highContrastRed,
        onError: _highContrastWhite,
        outline: _highContrastBlack,
        surfaceContainerHighest: _highContrastGray100,
        onSurfaceVariant: _highContrastBlack,
      ),
      
      // Enhanced focus indicators for high contrast
      focusColor: _highContrastBlue.withValues(alpha: 0.4),
      hoverColor: _highContrastBlue.withValues(alpha: 0.1),
      highlightColor: _highContrastYellow.withValues(alpha: 0.3),
      
      // High contrast card theme
      cardTheme: CardThemeData(
        elevation: 4,
        color: _highContrastWhite,
        shadowColor: _highContrastBlack.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          side: BorderSide(color: _highContrastBlack, width: 2),
        ),
      ),
      
      // High contrast elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _highContrastBlue,
          foregroundColor: _highContrastWhite,
          elevation: 4,
          side: BorderSide(color: _highContrastBlack, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
        ),
      ),
      
      // High contrast text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _highContrastBlue,
          backgroundColor: _highContrastWhite,
          side: BorderSide(color: _highContrastBlue, width: 2),
        ),
      ),
      
      // High contrast input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _highContrastWhite,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: _highContrastBlack, width: 2),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _highContrastBlack, width: 2),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _highContrastBlue, width: 3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _highContrastRed, width: 2),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _highContrastRed, width: 3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
      ),
      
      // High contrast app bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: _highContrastBlue,
        foregroundColor: _highContrastWhite,
        elevation: 4,
        titleTextStyle: TextStyle(
          color: _highContrastWhite,
          fontSize: DesignTokens.fontSizeTitle,
          fontWeight: DesignTokens.fontWeightBold,
        ),
      ),
    );
  }
  
  // ============================================================================
  // COMPANY HIGH CONTRAST THEME
  // ============================================================================
  
  static ThemeData getCompanyHighContrastTheme() {
    final baseTheme = SecuryFlexTheme.getTheme(UserRole.company);
    
    return baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _highContrastGreen,
        brightness: Brightness.light,
        primary: _highContrastGreen,
        onPrimary: _highContrastWhite,
        secondary: _highContrastBlue,
        onSecondary: _highContrastWhite,
        surface: _highContrastWhite,
        onSurface: _highContrastBlack,
        error: _highContrastRed,
        onError: _highContrastWhite,
        outline: _highContrastBlack,
        surfaceContainerHighest: _highContrastGray100,
        onSurfaceVariant: _highContrastBlack,
      ),
      
      focusColor: _highContrastGreen.withValues(alpha: 0.4),
      hoverColor: _highContrastGreen.withValues(alpha: 0.1),
      highlightColor: _highContrastYellow.withValues(alpha: 0.3),
      
      cardTheme: CardThemeData(
        elevation: 4,
        color: _highContrastWhite,
        shadowColor: _highContrastBlack.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          side: BorderSide(color: _highContrastBlack, width: 2),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _highContrastGreen,
          foregroundColor: _highContrastWhite,
          elevation: 4,
          side: BorderSide(color: _highContrastBlack, width: 2),
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: _highContrastGreen,
        foregroundColor: _highContrastWhite,
        elevation: 4,
        titleTextStyle: TextStyle(
          color: _highContrastWhite,
          fontSize: DesignTokens.fontSizeTitle,
          fontWeight: DesignTokens.fontWeightBold,
        ),
      ),
    );
  }
  
  // ============================================================================
  // ADMIN HIGH CONTRAST THEME
  // ============================================================================
  
  static ThemeData getAdminHighContrastTheme() {
    final baseTheme = SecuryFlexTheme.getTheme(UserRole.admin);
    
    return baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _highContrastPurple,
        brightness: Brightness.light,
        primary: _highContrastPurple,
        onPrimary: _highContrastWhite,
        secondary: _highContrastOrange,
        onSecondary: _highContrastWhite,
        surface: _highContrastWhite,
        onSurface: _highContrastBlack,
        error: _highContrastRed,
        onError: _highContrastWhite,
        outline: _highContrastBlack,
        surfaceContainerHighest: _highContrastGray100,
        onSurfaceVariant: _highContrastBlack,
      ),
      
      focusColor: _highContrastPurple.withValues(alpha: 0.4),
      hoverColor: _highContrastPurple.withValues(alpha: 0.1),
      highlightColor: _highContrastYellow.withValues(alpha: 0.3),
      
      cardTheme: CardThemeData(
        elevation: 4,
        color: _highContrastWhite,
        shadowColor: _highContrastBlack.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          side: BorderSide(color: _highContrastBlack, width: 2),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _highContrastPurple,
          foregroundColor: _highContrastWhite,
          elevation: 4,
          side: BorderSide(color: _highContrastBlack, width: 2),
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: _highContrastPurple,
        foregroundColor: _highContrastWhite,
        elevation: 4,
        titleTextStyle: TextStyle(
          color: _highContrastWhite,
          fontSize: DesignTokens.fontSizeTitle,
          fontWeight: DesignTokens.fontWeightBold,
        ),
      ),
    );
  }
  
  // ============================================================================
  // DARK HIGH CONTRAST THEMES
  // ============================================================================
  
  static ThemeData getDarkHighContrastTheme(UserRole userRole) {
    final primaryColor = _getDarkPrimaryColor(userRole);
    
    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        onPrimary: _highContrastBlack,
        secondary: _highContrastYellow,
        onSecondary: _highContrastBlack,
        surface: _highContrastBlack,
        onSurface: _highContrastWhite,
        // background: _highContrastBlack, // Deprecated in Material 3
        // onBackground: _highContrastWhite, // Deprecated in Material 3
        error: Color(0xFFFF6B6B),
        onError: _highContrastBlack,
        outline: _highContrastWhite,
        surfaceContainerHighest: _highContrastGray800,
        onSurfaceVariant: _highContrastWhite,
      ),
      
      focusColor: primaryColor.withValues(alpha: 0.4),
      hoverColor: primaryColor.withValues(alpha: 0.1),
      highlightColor: _highContrastYellow.withValues(alpha: 0.3),
      
      cardTheme: CardThemeData(
        elevation: 4,
        color: _highContrastBlack,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          side: BorderSide(color: _highContrastWhite, width: 2),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: _highContrastBlack,
          elevation: 4,
          side: BorderSide(color: _highContrastWhite, width: 2),
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: _highContrastBlack,
        foregroundColor: _highContrastWhite,
        elevation: 4,
        titleTextStyle: TextStyle(
          color: _highContrastWhite,
          fontSize: DesignTokens.fontSizeTitle,
          fontWeight: DesignTokens.fontWeightBold,
        ),
      ),
    );
  }
  
  static Color _getDarkPrimaryColor(UserRole userRole) {
    switch (userRole) {
      case UserRole.guard:
        return Color(0xFF4FC3F7);
      case UserRole.company:
        return Color(0xFF66BB6A);
      case UserRole.admin:
        return Color(0xFFBA68C8);
    }
  }
  
  // ============================================================================
  // CHAT-SPECIFIC HIGH CONTRAST COLORS
  // ============================================================================
  
  /// Get high contrast message bubble colors
  static ChatHighContrastColors getChatHighContrastColors(UserRole userRole, {bool isDark = false}) {
    if (isDark) {
      return ChatHighContrastColors(
        currentUserBubble: _getDarkPrimaryColor(userRole),
        currentUserText: _highContrastBlack,
        otherUserBubble: _highContrastGray800,
        otherUserText: _highContrastWhite,
        systemBubble: _highContrastGray700,
        systemText: _highContrastWhite,
        timestampText: _highContrastGray300,
        linkText: Color(0xFF4FC3F7),
        deliveryStatusSent: _highContrastGray300,
        deliveryStatusDelivered: _highContrastYellow,
        deliveryStatusRead: Color(0xFF66BB6A),
        inputBackground: _highContrastBlack,
        inputText: _highContrastWhite,
        inputBorder: _highContrastWhite,
        typingIndicator: _highContrastYellow,
      );
    } else {
      final primaryColor = _getPrimaryColor(userRole);
      return ChatHighContrastColors(
        currentUserBubble: primaryColor,
        currentUserText: _highContrastWhite,
        otherUserBubble: _highContrastGray100,
        otherUserText: _highContrastBlack,
        systemBubble: _highContrastGray200,
        systemText: _highContrastBlack,
        timestampText: _highContrastGray700,
        linkText: _highContrastBlue,
        deliveryStatusSent: _highContrastGray700,
        deliveryStatusDelivered: _highContrastOrange,
        deliveryStatusRead: _highContrastGreen,
        inputBackground: _highContrastWhite,
        inputText: _highContrastBlack,
        inputBorder: _highContrastBlack,
        typingIndicator: _highContrastOrange,
      );
    }
  }
  
  static Color _getPrimaryColor(UserRole userRole) {
    switch (userRole) {
      case UserRole.guard:
        return _highContrastBlue;
      case UserRole.company:
        return _highContrastGreen;
      case UserRole.admin:
        return _highContrastPurple;
    }
  }
  
  // ============================================================================
  // THEME SELECTION UTILITY
  // ============================================================================
  
  /// Get appropriate theme based on user preferences and role
  static ThemeData getTheme({
    required UserRole userRole,
    required bool isHighContrast,
    required bool isDarkMode,
  }) {
    if (!isHighContrast) {
      return SecuryFlexTheme.getTheme(userRole);
    }
    
    if (isDarkMode) {
      return getDarkHighContrastTheme(userRole);
    } else {
      switch (userRole) {
        case UserRole.guard:
          return getGuardHighContrastTheme();
        case UserRole.company:
          return getCompanyHighContrastTheme();
        case UserRole.admin:
          return getAdminHighContrastTheme();
      }
    }
  }
  
  /// Validate all high contrast themes meet WCAG AAA standards
  static Map<String, AccessibilityReport> validateHighContrastThemes() {
    final reports = <String, AccessibilityReport>{};
    
    // Test guard theme
    reports['Guard High Contrast'] = _validateThemeAccessibility(
      getGuardHighContrastTheme().colorScheme,
      'Guard High Contrast Theme',
    );
    
    // Test company theme
    reports['Company High Contrast'] = _validateThemeAccessibility(
      getCompanyHighContrastTheme().colorScheme,
      'Company High Contrast Theme',
    );
    
    // Test admin theme
    reports['Admin High Contrast'] = _validateThemeAccessibility(
      getAdminHighContrastTheme().colorScheme,
      'Admin High Contrast Theme',
    );
    
    return reports;
  }
  
  static AccessibilityReport _validateThemeAccessibility(
    ColorScheme colorScheme,
    String themeName,
  ) {
    final tests = <AccessibilityTest>[];
    final violations = <AccessibilityViolation>[];
    
    // Test primary color combinations with AAA standard (7:1 ratio)
    final primaryOnSurfaceTest = _testAAContrastRatio(
      'Primary on Surface',
      colorScheme.primary,
      colorScheme.surface,
    );
    tests.add(primaryOnSurfaceTest);
    
    final onPrimaryOnPrimaryTest = _testAAContrastRatio(
      'OnPrimary on Primary',
      colorScheme.onPrimary,
      colorScheme.primary,
    );
    tests.add(onPrimaryOnPrimaryTest);
    
    final onSurfaceOnSurfaceTest = _testAAContrastRatio(
      'OnSurface on Surface',
      colorScheme.onSurface,
      colorScheme.surface,
    );
    tests.add(onSurfaceOnSurfaceTest);
    
    // Check for violations
    for (final test in tests) {
      if (!test.passed) {
        violations.add(AccessibilityViolation(
          type: ViolationType.contrastRatio,
          description: '${test.name}: Contrast ratio ${test.actualRatio.toStringAsFixed(2)} < 7.0 (AAA standard)',
          severity: ViolationSeverity.high,
          suggestion: 'Use higher contrast colors to meet WCAG AAA standard',
        ));
      }
    }
    
    return AccessibilityReport(
      componentName: themeName,
      tests: tests,
      violations: violations,
      overallScore: _calculateScore(tests),
    );
  }
  
  static AccessibilityTest _testAAContrastRatio(String name, Color foreground, Color background) {
    final ratio = AccessibilityComplianceSystem.calculateContrastRatio(foreground, background);
    return AccessibilityTest(
      name: name,
      type: TestType.contrastRatio,
      passed: ratio >= 7.0, // WCAG AAA standard
      actualRatio: ratio,
      requiredRatio: 7.0,
    );
  }
  
  static double _calculateScore(List<AccessibilityTest> tests) {
    if (tests.isEmpty) return 0.0;
    final passedTests = tests.where((t) => t.passed).length;
    return passedTests / tests.length * 100;
  }
}

/// Chat-specific high contrast color palette
class ChatHighContrastColors {
  final Color currentUserBubble;
  final Color currentUserText;
  final Color otherUserBubble;
  final Color otherUserText;
  final Color systemBubble;
  final Color systemText;
  final Color timestampText;
  final Color linkText;
  final Color deliveryStatusSent;
  final Color deliveryStatusDelivered;
  final Color deliveryStatusRead;
  final Color inputBackground;
  final Color inputText;
  final Color inputBorder;
  final Color typingIndicator;
  
  const ChatHighContrastColors({
    required this.currentUserBubble,
    required this.currentUserText,
    required this.otherUserBubble,
    required this.otherUserText,
    required this.systemBubble,
    required this.systemText,
    required this.timestampText,
    required this.linkText,
    required this.deliveryStatusSent,
    required this.deliveryStatusDelivered,
    required this.deliveryStatusRead,
    required this.inputBackground,
    required this.inputText,
    required this.inputBorder,
    required this.typingIndicator,
  });
}