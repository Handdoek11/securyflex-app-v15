import 'package:flutter/material.dart';
import 'responsive_provider.dart';
import 'responsive_performance_monitor.dart';

/// Convenient extension methods for accessing responsive configuration
extension ResponsiveExtension on BuildContext {
  /// Get cached responsive configuration
  ResponsiveConfig get responsive {
    // Record performance improvement
    ResponsivePerformanceMonitor.instance.recordMediaQueryCallSaved();
    return ResponsiveProvider.of(this);
  }

  /// Device type shortcuts
  DeviceType get deviceType => responsive.deviceType;
  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
  bool get isLargeDesktop => deviceType == DeviceType.largeDesktop;

  /// Screen dimensions (cached)
  double get screenWidth => responsive.screenWidth;
  double get screenHeight => responsive.screenHeight;

  /// Responsive spacing (cached)
  EdgeInsets get responsivePadding => responsive.responsivePadding;
  EdgeInsets get responsiveMargin => responsive.responsiveMargin;

  /// Grid configuration (cached)
  int get gridColumns => responsive.gridColumns;

  /// Typography (cached)
  double get responsiveFontSize => responsive.fontSize;

  /// Feature support (cached)
  bool get supportsKeyboardShortcuts => responsive.supportsKeyboardShortcuts;
  bool get supportsBulkOperations => responsive.supportsBulkOperations;
  bool get supportsHoverEffects => responsive.supportsHoverEffects;

  /// Responsive breakpoint helpers
  bool get isMobileBreakpoint => screenWidth < UnifiedResponsiveBreakpoints.mobileBreakpoint;
  bool get isTabletBreakpoint => screenWidth >= UnifiedResponsiveBreakpoints.mobileBreakpoint && 
                                screenWidth < UnifiedResponsiveBreakpoints.tabletBreakpoint;
  bool get isDesktopBreakpoint => screenWidth >= UnifiedResponsiveBreakpoints.tabletBreakpoint;

  /// Conditional responsive values
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Responsive spacing multipliers
  double get spacingMultiplier {
    switch (deviceType) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.2;
      case DeviceType.desktop:
        return 1.4;
      case DeviceType.largeDesktop:
        return 1.6;
    }
  }

  /// Responsive animation durations
  Duration get responsiveAnimationDuration {
    switch (deviceType) {
      case DeviceType.mobile:
        return const Duration(milliseconds: 200); // Fast for mobile
      case DeviceType.tablet:
        return const Duration(milliseconds: 250); // Medium for tablet
      case DeviceType.desktop:
        return const Duration(milliseconds: 300); // Smooth for desktop
      case DeviceType.largeDesktop:
        return const Duration(milliseconds: 350); // Premium for large desktop
    }
  }

  /// Responsive border radius
  double get responsiveBorderRadius {
    switch (deviceType) {
      case DeviceType.mobile:
        return 8.0;
      case DeviceType.tablet:
        return 12.0;
      case DeviceType.desktop:
        return 16.0;
      case DeviceType.largeDesktop:
        return 20.0;
    }
  }

  /// Safe area aware responsive padding
  EdgeInsets get safeAreaResponsivePadding {
    final mediaQuery = MediaQuery.of(this);
    final safePadding = mediaQuery.padding;
    final basePadding = responsivePadding;
    
    return EdgeInsets.only(
      left: basePadding.left + safePadding.left,
      top: basePadding.top + safePadding.top,
      right: basePadding.right + safePadding.right,
      bottom: basePadding.bottom + safePadding.bottom,
    );
  }
}

/// Extension for responsive widgets and layouts
extension ResponsiveWidgetExtension on Widget {
  /// Wrap widget with responsive provider if not already provided
  Widget withResponsive({Duration debounceTime = const Duration(milliseconds: 100)}) {
    return ResponsiveWrapper(
      debounceTime: debounceTime,
      child: this,
    );
  }

  /// Apply responsive padding to any widget
  Widget withResponsivePadding(BuildContext context) {
    return Padding(
      padding: context.responsivePadding,
      child: this,
    );
  }

  /// Apply responsive margin to any widget  
  Widget withResponsiveMargin(BuildContext context) {
    return Container(
      margin: context.responsiveMargin,
      child: this,
    );
  }

  /// Show widget only on specific device types
  Widget showOnlyOn({
    bool mobile = true,
    bool tablet = true,
    bool desktop = true,
    bool largeDesktop = true,
  }) {
    return Builder(
      builder: (context) {
        final shouldShow = context.responsiveValue<bool>(
          mobile: mobile,
          tablet: tablet,
          desktop: desktop,
          largeDesktop: largeDesktop,
        );
        
        return shouldShow ? this : const SizedBox.shrink();
      },
    );
  }
}

/// Responsive breakpoint utilities
class ResponsiveUtils {
  /// Get appropriate child aspect ratio for device
  static double getChildAspectRatio(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 1.4; // Taller cards for mobile
      case DeviceType.tablet:
        return 1.6; // Medium cards for tablet
      case DeviceType.desktop:
        return 1.8; // Wider cards for desktop
      case DeviceType.largeDesktop:
        return 2.0; // Wide cards for large desktop
    }
  }

  /// Get appropriate cross axis spacing for grids
  static double getCrossAxisSpacing(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 12.0;
      case DeviceType.tablet:
        return 16.0;
      case DeviceType.desktop:
        return 20.0;
      case DeviceType.largeDesktop:
        return 24.0;
    }
  }

  /// Get appropriate main axis spacing for grids
  static double getMainAxisSpacing(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 12.0;
      case DeviceType.tablet:
        return 16.0;
      case DeviceType.desktop:
        return 20.0;
      case DeviceType.largeDesktop:
        return 24.0;
    }
  }

  /// Get responsive icon size
  static double getIconSize(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 24.0;
      case DeviceType.tablet:
        return 26.0;
      case DeviceType.desktop:
        return 28.0;
      case DeviceType.largeDesktop:
        return 32.0;
    }
  }

  /// Get responsive button height
  static double getButtonHeight(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 48.0; // Touch-friendly minimum
      case DeviceType.tablet:
        return 52.0;
      case DeviceType.desktop:
        return 40.0; // Mouse precision allows smaller targets
      case DeviceType.largeDesktop:
        return 44.0;
    }
  }
}