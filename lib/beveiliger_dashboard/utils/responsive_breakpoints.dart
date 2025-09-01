import 'package:flutter/material.dart';
import '../../core/responsive/responsive_provider.dart';

/// Responsive breakpoints utility for SecuryFlex beveiliger dashboard
/// Provides consistent spacing, font sizes, and layout across different screen sizes
class ResponsiveBreakpoints {
  // Breakpoint definitions
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
  
  /// Get device type based on screen width
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
  
  /// Get responsive padding based on device type
  static EdgeInsets getResponsivePadding(BuildContext context) {
    // Use consistent 16px padding across all device types for UI consistency
    return const EdgeInsets.all(16.0);
  }
  
  /// Get responsive spacing based on device type and base spacing
  static double getResponsiveSpacing(BuildContext context, {required double baseSpacing}) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return baseSpacing;
      case DeviceType.tablet:
        return baseSpacing * 1.25;
      case DeviceType.desktop:
        return baseSpacing * 1.5;
      case DeviceType.largeDesktop:
        return baseSpacing * 1.75;
    }
  }
  
  /// Get responsive font size based on device type and base size
  static double getResponsiveFontSize(BuildContext context, {required double baseSize}) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return baseSize;
      case DeviceType.tablet:
        return baseSize * 1.1;
      case DeviceType.desktop:
        return baseSize * 1.2;
      case DeviceType.largeDesktop:
        return baseSize * 1.3;
    }
  }
  
  /// Get responsive margin based on device type
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0);
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
      case DeviceType.largeDesktop:
        return const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0);
    }
  }
  
  /// Get responsive border radius
  static double getResponsiveBorderRadius(BuildContext context) {
    final deviceType = getDeviceType(context);
    
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
  
  /// Get responsive card elevation
  static double getResponsiveElevation(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 2.0;
      case DeviceType.tablet:
        return 4.0;
      case DeviceType.desktop:
        return 6.0;
      case DeviceType.largeDesktop:
        return 8.0;
    }
  }
  
  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }
  
  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }
  
  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }
  
  /// Get responsive width for cards/containers
  static double getResponsiveCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return width - 32; // Full width minus padding
      case DeviceType.tablet:
        return (width - 64) / 2; // Two columns
      case DeviceType.desktop:
        return (width - 96) / 3; // Three columns
      case DeviceType.largeDesktop:
        return (width - 128) / 4; // Four columns
    }
  }
  
  /// Get grid crossAxisCount based on device type
  static int getGridCrossAxisCount(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 3;
      case DeviceType.largeDesktop:
        return 4;
    }
  }
}