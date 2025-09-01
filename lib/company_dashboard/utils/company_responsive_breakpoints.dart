import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../core/responsive/responsive_provider.dart';

/// Enhanced responsive breakpoints for company dashboard
/// Extends beveiliger patterns with business-specific desktop features
class CompanyResponsiveBreakpoints {
  // Enhanced breakpoints for business users
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;  // Extra breakpoint for wide screens
  
  /// Device types including large desktop
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else if (width < desktopBreakpoint) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }
  
  /// Enhanced grid columns for business data
  static int getGridColumns(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return 2;  // 2 columns for metrics
      case DeviceType.tablet:
        return 3;  // 3 columns for better data density
      case DeviceType.desktop:
        return 4;  // 4 columns for desktop
      case DeviceType.largeDesktop:
        return 6;  // 6 columns for ultra-wide screens
    }
  }
  
  /// Data density per card (business metrics)
  static int getDataPointsPerCard(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return 2;  // Minimal data points
      case DeviceType.tablet:
        return 3;  // Medium density
      case DeviceType.desktop:
        return 5;  // Full metrics
      case DeviceType.largeDesktop:
        return 8;  // Extended analytics
    }
  }
  
  /// Navigation style based on screen size
  static NavigationStyle getNavigationStyle(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    if (deviceType == DeviceType.mobile) {
      return NavigationStyle.bottomNav;
    } else if (deviceType == DeviceType.tablet) {
      return NavigationStyle.rail;  // Collapsible side rail
    } else {
      return NavigationStyle.sidebar;  // Full sidebar
    }
  }
  
  /// Desktop-specific features availability
  static bool hasDesktopFeatures(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop || 
           getDeviceType(context) == DeviceType.largeDesktop;
  }
  
  /// Show data tables instead of cards for large screens
  static bool useDataTables(BuildContext context) {
    return getDeviceType(context) == DeviceType.largeDesktop;
  }
  
  /// Multi-select and bulk operations for desktop
  static bool supportsBulkOperations(BuildContext context) {
    return getDeviceType(context) != DeviceType.mobile;
  }
  
  /// Keyboard shortcuts enabled for desktop
  static bool supportsKeyboardShortcuts(BuildContext context) {
    return hasDesktopFeatures(context);
  }
  
  /// Right-click context menus for desktop
  static bool supportsContextMenus(BuildContext context) {
    return hasDesktopFeatures(context);
  }
  
  /// Hover states for desktop interactions
  static bool supportsHoverStates(BuildContext context) {
    return !isMobile(context);
  }
  
  /// Helper methods
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }
  
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }
  
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop ||
           getDeviceType(context) == DeviceType.largeDesktop;
  }
  
  /// Get responsive padding with business density
  static EdgeInsets getResponsivePadding(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return EdgeInsets.all(DesignTokens.spacingM);  // 16px
      case DeviceType.tablet:
        return EdgeInsets.all(DesignTokens.spacingL);  // 24px
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingXL,  // 32px horizontal
          vertical: DesignTokens.spacingL,     // 24px vertical
        );
    }
  }
}

/// Navigation styles for different screen sizes
enum NavigationStyle {
  bottomNav,   // Mobile bottom navigation
  rail,        // Tablet navigation rail
  sidebar,     // Desktop full sidebar
}