import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;

/// Platform Intelligence Layer for adaptive UI patterns
/// 
/// Automatically detects and adapts to:
/// - Screen size and orientation changes
/// - Input method preferences (touch vs mouse/keyboard)
/// - User interaction patterns
/// - Performance characteristics
/// - Platform capabilities
class AdaptiveUIService {
  static const String _tag = 'AdaptiveUIService';
  static final AdaptiveUIService _instance = AdaptiveUIService._internal();
  static AdaptiveUIService get instance => _instance;
  
  AdaptiveUIService._internal();
  
  bool _isInitialized = false;
  StreamController<PlatformContext>? _contextStreamController;
  PlatformContext? _currentContext;
  Timer? _contextUpdateTimer;
  
  // Adaptive thresholds
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;
  static const Duration contextUpdateInterval = Duration(milliseconds: 500);
  
  /// Initialize adaptive UI service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _contextStreamController = StreamController<PlatformContext>.broadcast();
      
      // Start context monitoring
      _startContextMonitoring();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        developer.log('$_tag: Adaptive UI service initialized', name: 'AdaptiveUI');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Failed to initialize: $e', name: 'AdaptiveUI');
      }
    }
  }
  
  /// Start monitoring platform context changes
  void _startContextMonitoring() {
    _contextUpdateTimer = Timer.periodic(contextUpdateInterval, (_) {
      _updatePlatformContext();
    });
  }
  
  /// Update current platform context
  void _updatePlatformContext() {
    // This would be called with actual context from widgets
    // For now, we'll use a placeholder implementation
  }
  
  /// Update context from widget
  void updateContext(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final devicePixelRatio = mediaQuery.devicePixelRatio;
    final platformBrightness = mediaQuery.platformBrightness;
    
    final newContext = PlatformContext(
      screenWidth: screenSize.width,
      screenHeight: screenSize.height,
      devicePixelRatio: devicePixelRatio,
      platformBrightness: platformBrightness,
      platformType: _determinePlatformType(screenSize),
      inputType: _determineInputType(screenSize),
      interfaceDensity: _determineInterfaceDensity(screenSize, devicePixelRatio),
      timestamp: DateTime.now(),
    );
    
    if (_shouldUpdateContext(newContext)) {
      _currentContext = newContext;
      _contextStreamController?.add(newContext);
      
      if (kDebugMode) {
        developer.log('$_tag: Context updated - ${newContext.platformType.name} (${newContext.screenWidth.toInt()}x${newContext.screenHeight.toInt()})', 
                     name: 'AdaptiveUI');
      }
    }
  }
  
  /// Determine platform type based on screen characteristics
  PlatformType _determinePlatformType(Size screenSize) {
    if (screenSize.width < mobileBreakpoint) {
      return PlatformType.mobile;
    } else if (screenSize.width < tabletBreakpoint) {
      return PlatformType.tablet;
    } else if (screenSize.width < desktopBreakpoint) {
      return PlatformType.desktop;
    } else {
      return PlatformType.largeDesktop;
    }
  }
  
  /// Determine primary input type
  InputType _determineInputType(Size screenSize) {
    // Simple heuristic: smaller screens are likely touch-first
    if (screenSize.width < tabletBreakpoint) {
      return InputType.touch;
    } else {
      return InputType.mouseKeyboard;
    }
  }
  
  /// Determine optimal interface density
  InterfaceDensity _determineInterfaceDensity(Size screenSize, double devicePixelRatio) {
    final totalPixels = screenSize.width * screenSize.height * devicePixelRatio;
    
    if (totalPixels > 8000000) { // ~4K and above
      return InterfaceDensity.high;
    } else if (totalPixels > 2000000) { // ~1080p+
      return InterfaceDensity.standard;
    } else {
      return InterfaceDensity.compact;
    }
  }
  
  /// Check if context should be updated (debouncing)
  bool _shouldUpdateContext(PlatformContext newContext) {
    if (_currentContext == null) return true;
    
    return _currentContext!.platformType != newContext.platformType ||
           _currentContext!.inputType != newContext.inputType ||
           (_currentContext!.screenWidth - newContext.screenWidth).abs() > 100 ||
           _currentContext!.interfaceDensity != newContext.interfaceDensity;
  }
  
  /// Get current platform context
  PlatformContext? get currentContext => _currentContext;
  
  /// Get platform context stream
  Stream<PlatformContext> get contextStream => 
    _contextStreamController?.stream ?? const Stream.empty();
  
  /// Get adaptive layout configuration
  AdaptiveLayoutConfig getLayoutConfig([PlatformContext? context]) {
    final ctx = context ?? _currentContext;
    if (ctx == null) {
      return AdaptiveLayoutConfig.fallback();
    }
    
    return AdaptiveLayoutConfig.fromContext(ctx);
  }
  
  /// Check if current platform supports specific feature
  bool supportsFeature(AdaptiveFeature feature, [PlatformContext? context]) {
    final ctx = context ?? _currentContext;
    if (ctx == null) return false;
    
    switch (feature) {
      case AdaptiveFeature.dragAndDrop:
        return ctx.inputType == InputType.mouseKeyboard;
      case AdaptiveFeature.keyboardShortcuts:
        return ctx.platformType != PlatformType.mobile;
      case AdaptiveFeature.hoverEffects:
        return ctx.inputType == InputType.mouseKeyboard;
      case AdaptiveFeature.contextMenus:
        return ctx.platformType != PlatformType.mobile;
      case AdaptiveFeature.multiWindow:
        return ctx.platformType == PlatformType.desktop || 
               ctx.platformType == PlatformType.largeDesktop;
      case AdaptiveFeature.hapticFeedback:
        return ctx.platformType == PlatformType.mobile ||
               ctx.platformType == PlatformType.tablet;
      case AdaptiveFeature.gestureNavigation:
        return ctx.inputType == InputType.touch;
      case AdaptiveFeature.precisionPointing:
        return ctx.inputType == InputType.mouseKeyboard;
    }
  }
  
  /// Get optimal animation duration for current platform
  Duration getOptimalAnimationDuration(AnimationSpeed speed, [PlatformContext? context]) {
    final ctx = context ?? _currentContext;
    if (ctx == null) {
      return const Duration(milliseconds: 300);
    }
    
    // Mobile users prefer snappier animations, desktop users prefer smoother ones
    final multiplier = ctx.platformType == PlatformType.mobile ? 0.8 : 1.0;
    
    switch (speed) {
      case AnimationSpeed.fast:
        return Duration(milliseconds: (150 * multiplier).round());
      case AnimationSpeed.standard:
        return Duration(milliseconds: (300 * multiplier).round());
      case AnimationSpeed.slow:
        return Duration(milliseconds: (500 * multiplier).round());
    }
  }
  
  /// Cleanup method
  void dispose() {
    _contextUpdateTimer?.cancel();
    _contextStreamController?.close();
    _isInitialized = false;
  }
  
  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}

/// Platform context information
class PlatformContext {
  final double screenWidth;
  final double screenHeight;
  final double devicePixelRatio;
  final Brightness platformBrightness;
  final PlatformType platformType;
  final InputType inputType;
  final InterfaceDensity interfaceDensity;
  final DateTime timestamp;
  
  const PlatformContext({
    required this.screenWidth,
    required this.screenHeight,
    required this.devicePixelRatio,
    required this.platformBrightness,
    required this.platformType,
    required this.inputType,
    required this.interfaceDensity,
    required this.timestamp,
  });
  
  /// Get aspect ratio
  double get aspectRatio => screenWidth / screenHeight;
  
  /// Check if in landscape orientation
  bool get isLandscape => aspectRatio > 1.0;
  
  /// Get diagonal screen size in inches (approximate)
  double get diagonalInches {
    final diagonalPixels = sqrt(screenWidth * screenWidth + screenHeight * screenHeight);
    return diagonalPixels / devicePixelRatio / 160; // 160 DPI = 1 inch
  }
}

/// Adaptive layout configuration
class AdaptiveLayoutConfig {
  final int gridColumns;
  final double itemSpacing;
  final EdgeInsets contentPadding;
  final double minTouchTarget;
  final bool enableHoverEffects;
  final bool enableKeyboardShortcuts;
  final bool enableDragDrop;
  final NavigationStyle navigationStyle;
  final DataDensity dataDensity;
  
  const AdaptiveLayoutConfig({
    required this.gridColumns,
    required this.itemSpacing,
    required this.contentPadding,
    required this.minTouchTarget,
    required this.enableHoverEffects,
    required this.enableKeyboardShortcuts,
    required this.enableDragDrop,
    required this.navigationStyle,
    required this.dataDensity,
  });
  
  factory AdaptiveLayoutConfig.fromContext(PlatformContext context) {
    switch (context.platformType) {
      case PlatformType.mobile:
        return AdaptiveLayoutConfig(
          gridColumns: 1,
          itemSpacing: 16.0,
          contentPadding: const EdgeInsets.all(16.0),
          minTouchTarget: 48.0,
          enableHoverEffects: false,
          enableKeyboardShortcuts: false,
          enableDragDrop: false,
          navigationStyle: NavigationStyle.bottomTabs,
          dataDensity: DataDensity.comfortable,
        );
        
      case PlatformType.tablet:
        return AdaptiveLayoutConfig(
          gridColumns: 2,
          itemSpacing: 20.0,
          contentPadding: const EdgeInsets.all(20.0),
          minTouchTarget: 44.0,
          enableHoverEffects: true,
          enableKeyboardShortcuts: true,
          enableDragDrop: true,
          navigationStyle: NavigationStyle.sideRail,
          dataDensity: DataDensity.standard,
        );
        
      case PlatformType.desktop:
        return AdaptiveLayoutConfig(
          gridColumns: 3,
          itemSpacing: 24.0,
          contentPadding: const EdgeInsets.all(24.0),
          minTouchTarget: 32.0,
          enableHoverEffects: true,
          enableKeyboardShortcuts: true,
          enableDragDrop: true,
          navigationStyle: NavigationStyle.sidebar,
          dataDensity: DataDensity.compact,
        );
        
      case PlatformType.largeDesktop:
        return AdaptiveLayoutConfig(
          gridColumns: 4,
          itemSpacing: 32.0,
          contentPadding: const EdgeInsets.all(32.0),
          minTouchTarget: 32.0,
          enableHoverEffects: true,
          enableKeyboardShortcuts: true,
          enableDragDrop: true,
          navigationStyle: NavigationStyle.sidebar,
          dataDensity: DataDensity.dense,
        );
    }
  }
  
  factory AdaptiveLayoutConfig.fallback() {
    return AdaptiveLayoutConfig(
      gridColumns: 2,
      itemSpacing: 16.0,
      contentPadding: const EdgeInsets.all(16.0),
      minTouchTarget: 44.0,
      enableHoverEffects: false,
      enableKeyboardShortcuts: false,
      enableDragDrop: false,
      navigationStyle: NavigationStyle.bottomTabs,
      dataDensity: DataDensity.standard,
    );
  }
}

/// Enums for platform characteristics
enum PlatformType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

enum InputType {
  touch,
  mouseKeyboard,
}

enum InterfaceDensity {
  compact,
  standard,
  high,
}

enum AdaptiveFeature {
  dragAndDrop,
  keyboardShortcuts,
  hoverEffects,
  contextMenus,
  multiWindow,
  hapticFeedback,
  gestureNavigation,
  precisionPointing,
}

enum AnimationSpeed {
  fast,
  standard,
  slow,
}

enum NavigationStyle {
  bottomTabs,
  sideRail,
  sidebar,
}

enum DataDensity {
  comfortable,
  standard,
  compact,
  dense,
}