import 'package:flutter/material.dart';
import 'dart:async';
import '../../unified_design_tokens.dart';
import 'responsive_performance_monitor.dart';

/// Device types for responsive design
enum DeviceType {
  mobile,
  tablet, 
  desktop,
  largeDesktop,
}

/// Responsive configuration data cached for performance
class ResponsiveConfig {
  final DeviceType deviceType;
  final double screenWidth;
  final double screenHeight;
  final EdgeInsets responsivePadding;
  final EdgeInsets responsiveMargin;
  final int gridColumns;
  final double fontSize;
  final bool supportsKeyboardShortcuts;
  final bool supportsBulkOperations;
  final bool supportsHoverEffects;

  const ResponsiveConfig({
    required this.deviceType,
    required this.screenWidth,
    required this.screenHeight,
    required this.responsivePadding,
    required this.responsiveMargin,
    required this.gridColumns,
    required this.fontSize,
    required this.supportsKeyboardShortcuts,
    required this.supportsBulkOperations,
    required this.supportsHoverEffects,
  });

  /// Create responsive configuration from MediaQuery data
  factory ResponsiveConfig.fromMediaQuery(MediaQueryData mediaQuery) {
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    final deviceType = _getDeviceType(width);

    return ResponsiveConfig(
      deviceType: deviceType,
      screenWidth: width,
      screenHeight: height,
      responsivePadding: _getResponsivePadding(deviceType),
      responsiveMargin: _getResponsiveMargin(deviceType),
      gridColumns: _getGridColumns(deviceType),
      fontSize: _getBaseFontSize(deviceType),
      supportsKeyboardShortcuts: deviceType == DeviceType.desktop || deviceType == DeviceType.largeDesktop,
      supportsBulkOperations: width >= UnifiedResponsiveBreakpoints.tabletBreakpoint,
      supportsHoverEffects: deviceType != DeviceType.mobile,
    );
  }

  static DeviceType _getDeviceType(double width) {
    if (width < UnifiedResponsiveBreakpoints.mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < UnifiedResponsiveBreakpoints.tabletBreakpoint) {
      return DeviceType.tablet;
    } else if (width < UnifiedResponsiveBreakpoints.desktopBreakpoint) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }

  static EdgeInsets _getResponsivePadding(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(DesignTokens.spacingM);
      case DeviceType.tablet:
        return const EdgeInsets.all(DesignTokens.spacingL);
      case DeviceType.desktop:
        return const EdgeInsets.all(DesignTokens.spacingXL);
      case DeviceType.largeDesktop:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingXXL,
          vertical: DesignTokens.spacingXL,
        );
    }
  }

  static EdgeInsets _getResponsiveMargin(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(DesignTokens.spacingS);
      case DeviceType.tablet:
        return const EdgeInsets.all(DesignTokens.spacingM);
      case DeviceType.desktop:
        return const EdgeInsets.all(DesignTokens.spacingL);
      case DeviceType.largeDesktop:
        return const EdgeInsets.all(DesignTokens.spacingXL);
    }
  }

  static int _getGridColumns(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 2;
      case DeviceType.tablet:
        return 3;
      case DeviceType.desktop:
        return 4;
      case DeviceType.largeDesktop:
        return 6;
    }
  }

  static double _getBaseFontSize(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return DesignTokens.fontSizeBody;
      case DeviceType.tablet:
        return DesignTokens.fontSizeBody * 1.1;
      case DeviceType.desktop:
        return DesignTokens.fontSizeBody * 1.2;
      case DeviceType.largeDesktop:
        return DesignTokens.fontSizeBody * 1.3;
    }
  }
}

/// Unified responsive breakpoints for entire app
class UnifiedResponsiveBreakpoints {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// Get device type from width (cached version)
  static DeviceType getDeviceType(double width) {
    return ResponsiveConfig._getDeviceType(width);
  }

  /// Check if device supports keyboard shortcuts
  static bool supportsKeyboardShortcuts(DeviceType deviceType) {
    return deviceType == DeviceType.desktop || deviceType == DeviceType.largeDesktop;
  }

  /// Check if device supports bulk operations
  static bool supportsBulkOperations(DeviceType deviceType) {
    return deviceType != DeviceType.mobile;
  }

  /// Check if device supports hover effects
  static bool supportsHoverEffects(DeviceType deviceType) {
    return deviceType != DeviceType.mobile;
  }
}

/// High-performance responsive provider with caching and debouncing
class ResponsiveProvider extends InheritedWidget {
  final ResponsiveConfig config;

  const ResponsiveProvider({
    super.key,
    required this.config,
    required super.child,
  });

  /// Get cached responsive configuration
  static ResponsiveConfig of(BuildContext context) {
    final ResponsiveProvider? result = context.dependOnInheritedWidgetOfExactType<ResponsiveProvider>();
    assert(result != null, 'No ResponsiveProvider found in context');
    return result!.config;
  }

  /// Get responsive configuration without dependency (for one-time reads)
  static ResponsiveConfig? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ResponsiveProvider>()?.config;
  }

  @override
  bool updateShouldNotify(ResponsiveProvider oldWidget) {
    // Only notify if device type changes (major layout change)
    // Prevents excessive rebuilds for minor size changes
    return config.deviceType != oldWidget.config.deviceType ||
           (config.screenWidth - oldWidget.config.screenWidth).abs() > 50; // Debounce threshold
  }
}

/// Widget that provides responsive configuration with debounced updates
class ResponsiveWrapper extends StatefulWidget {
  final Widget child;
  final Duration debounceTime;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.debounceTime = const Duration(milliseconds: 100),
  });

  @override
  State<ResponsiveWrapper> createState() => _ResponsiveWrapperState();
}

class _ResponsiveWrapperState extends State<ResponsiveWrapper> {
  ResponsiveConfig? _config;
  Timer? _debounceTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateConfig();
  }

  void _updateConfig() {
    final mediaQuery = MediaQuery.of(context);
    final newConfig = ResponsiveConfig.fromMediaQuery(mediaQuery);

    // Debounce updates to prevent excessive rebuilds
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceTime, () {
      if (mounted && (_config == null || _shouldUpdateConfig(newConfig))) {
        // Record prevented rebuild if this is a debounced update
        if (_config != null) {
          ResponsivePerformanceMonitor.instance.recordWidgetRebuildPrevented();
        }
        setState(() {
          _config = newConfig;
        });
      }
    });
  }

  bool _shouldUpdateConfig(ResponsiveConfig newConfig) {
    if (_config == null) return true;
    
    // Only update for significant changes
    return _config!.deviceType != newConfig.deviceType ||
           (_config!.screenWidth - newConfig.screenWidth).abs() > 50;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_config == null) {
      // Initial load - create config immediately
      _config = ResponsiveConfig.fromMediaQuery(MediaQuery.of(context));
    }

    return ResponsiveProvider(
      config: _config!,
      child: widget.child,
    );
  }
}