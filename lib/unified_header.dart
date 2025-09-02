import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_components/premium_glass_system.dart';
import 'package:securyflex_app/unified_components/ultra_smooth_animation_system.dart';

/// Header type enumeration
enum UnifiedHeaderType {
  /// Simple header with title and optional actions
  simple,
  /// Animated header with scroll-based animations
  animated,
  /// Custom content header for unique layouts
  custom,
  /// Multi-line header with title and subtitle
  multiLine,
  /// Company gradient header with teal to navy gradient
  companyGradient,
}

/// Enhanced Unified Header Component for SecuryFlex
/// 
/// A comprehensive header component that consolidates all header patterns
/// across different modules while maintaining their unique functionality.
/// Now uses the unified design token system for consistency.
/// 
/// Features:
/// - Consistent styling using DesignTokens
/// - Role-based color theming
/// - Smooth animations and transitions
/// - Responsive design support
/// - Accessibility compliance
class UnifiedHeader extends StatefulWidget {
  /// Header type determines the styling and behavior
  final UnifiedHeaderType type;
  
  /// Main title text
  final String? title;
  
  /// Subtitle text (for multi-line headers)
  final String? subtitle;
  
  /// Leading widget (usually back button or menu)
  final Widget? leading;
  
  /// Action widgets on the right side
  final List<Widget>? actions;
  
  /// Custom content widget (overrides title/subtitle)
  final Widget? customContent;
  
  /// Background color override
  final Color? backgroundColor;
  
  /// Whether to show shadow
  final bool showShadow;
  
  /// Animation controller for animated headers
  final AnimationController? animationController;
  
  /// Scroll controller for scroll-based animations
  final ScrollController? scrollController;
  
  /// Custom border radius
  final BorderRadius? borderRadius;
  
  /// Custom padding
  final EdgeInsetsGeometry? padding;
  
  /// Height override
  final double? height;
  
  /// Whether this header should be transparent
  final bool isTransparent;
  
  /// User role for theming
  final UserRole? userRole;
  
  /// Whether to enable scroll-based opacity animation
  final bool enableScrollAnimation;
  
  /// Scroll threshold for opacity animation
  final double scrollThreshold;

  /// Text alignment for title (default is center)
  final TextAlign titleAlignment;

  /// Whether to enable responsive font sizing for smaller screens
  final bool enableResponsiveFontSize;

  /// Optional TabBar widget for company gradient headers
  final Widget? tabBar;

  const UnifiedHeader({
    super.key,
    this.type = UnifiedHeaderType.simple,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.customContent,
    this.backgroundColor,
    this.showShadow = true,
    this.animationController,
    this.scrollController,
    this.borderRadius,
    this.padding,
    this.height,
    this.isTransparent = false,
    this.userRole,
    this.enableScrollAnimation = false,
    this.scrollThreshold = 24.0,
    this.titleAlignment = TextAlign.center,
    this.enableResponsiveFontSize = true,
    this.tabBar,
  });

  @override
  State<UnifiedHeader> createState() => _UnifiedHeaderState();

  /// Static factory method for simple headers
  static UnifiedHeader simple({
    required String title,
    Widget? leading,
    List<Widget>? actions,
    Color? backgroundColor,
    bool showShadow = true,
    UserRole? userRole,
    TextAlign titleAlignment = TextAlign.center,
    bool enableResponsiveFontSize = true,
  }) {
    return UnifiedHeader(
      type: UnifiedHeaderType.simple,
      title: title,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor,
      showShadow: showShadow,
      userRole: userRole,
      titleAlignment: titleAlignment,
      enableResponsiveFontSize: enableResponsiveFontSize,
    );
  }
  
  /// Static factory method for animated headers
  static UnifiedHeader animated({
    required String title,
    required AnimationController animationController,
    Widget? leading,
    List<Widget>? actions,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    UserRole? userRole,
    ScrollController? scrollController,
    bool enableScrollAnimation = true,
    TextAlign titleAlignment = TextAlign.center,
    bool enableResponsiveFontSize = true,
  }) {
    return UnifiedHeader(
      type: UnifiedHeaderType.animated,
      title: title,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor,
      animationController: animationController,
      borderRadius: borderRadius,
      userRole: userRole,
      scrollController: scrollController,
      enableScrollAnimation: enableScrollAnimation,
      titleAlignment: titleAlignment,
      enableResponsiveFontSize: enableResponsiveFontSize,
    );
  }
  
  /// Static factory method for custom content headers
  static UnifiedHeader custom({
    required Widget customContent,
    Color? backgroundColor,
    bool showShadow = false,
    EdgeInsetsGeometry? padding,
    UserRole? userRole,
  }) {
    return UnifiedHeader(
      type: UnifiedHeaderType.custom,
      customContent: customContent,
      backgroundColor: backgroundColor,
      showShadow: showShadow,
      padding: padding,
      userRole: userRole,
    );
  }
  
  /// Static factory method for multi-line headers
  static UnifiedHeader multiLine({
    required String title,
    required String subtitle,
    Widget? leading,
    List<Widget>? actions,
    Color? backgroundColor,
    bool showShadow = true,
    UserRole? userRole,
    bool enableResponsiveFontSize = true,
  }) {
    return UnifiedHeader(
      type: UnifiedHeaderType.multiLine,
      title: title,
      subtitle: subtitle,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor,
      showShadow: showShadow,
      userRole: userRole,
      enableResponsiveFontSize: enableResponsiveFontSize,
    );
  }

  /// Static factory method for company gradient headers
  static UnifiedHeader companyGradient({
    required String title,
    List<Widget>? actions,
    Widget? tabBar,
    bool showNotifications = true,
    VoidCallback? onNotificationPressed,
    Widget? leading,
    EdgeInsetsGeometry? padding,
    double? height,
    bool enableResponsiveFontSize = true,
  }) {
    // Build default actions with notifications if enabled
    List<Widget> defaultActions = [];
    if (showNotifications) {
      defaultActions.add(
        HeaderElements.actionButton(
          icon: Icons.notifications_outlined,
          onPressed: onNotificationPressed ?? () {
            // Default notification action - can be overridden
          },
          color: DesignTokens.colorWhite,
        ),
      );
    }
    if (actions != null) {
      defaultActions.addAll(actions);
    }

    return UnifiedHeader(
      type: UnifiedHeaderType.companyGradient,
      title: title,
      leading: leading,
      actions: defaultActions.isNotEmpty ? defaultActions : null,
      tabBar: tabBar,
      padding: padding,
      height: height,
      userRole: UserRole.company,
      enableResponsiveFontSize: enableResponsiveFontSize,
      showShadow: false, // Gradient headers don't need shadows
    );
  }
}

class _UnifiedHeaderState extends State<UnifiedHeader> {
  double _scrollOpacity = 0.0;
  Animation<double>? _topBarAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    if (widget.animationController != null) {
      _topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: widget.animationController!,
          curve: const Interval(0, 0.5, curve: Curves.fastOutSlowIn),
        ),
      );
    }
  }

  void _setupScrollListener() {
    if (widget.enableScrollAnimation && widget.scrollController != null) {
      widget.scrollController!.addListener(_onScroll);
    }
  }

  void _onScroll() {
    if (!widget.enableScrollAnimation || widget.scrollController == null) return;
    
    final offset = widget.scrollController!.offset;
    final threshold = widget.scrollThreshold;
    
    double newOpacity;
    if (offset >= threshold) {
      newOpacity = 1.0;
    } else if (offset <= 0) {
      newOpacity = 0.0;
    } else {
      newOpacity = offset / threshold;
    }
    
    if (_scrollOpacity != newOpacity) {
      setState(() {
        _scrollOpacity = newOpacity;
      });
    }
  }

  @override
  void dispose() {
    if (widget.enableScrollAnimation && widget.scrollController != null) {
      widget.scrollController!.removeListener(_onScroll);
    }
    super.dispose();
  }

  /// Get glass intensity based on scroll position and user role
  GlassIntensity _getGlassIntensity() {
    if (widget.userRole == UserRole.guard) {
      return _scrollOpacity > 0.5 ? GlassIntensity.standard : GlassIntensity.subtle;
    }
    return GlassIntensity.standard;
  }
  
  /// Get glass elevation based on scroll position
  GlassElevation _getGlassElevation() {
    return _scrollOpacity > 0.3 ? GlassElevation.floating : GlassElevation.surface;
  }

  /// Get the appropriate color scheme based on user role
  ColorScheme _getColorScheme(BuildContext context) {
    if (widget.userRole != null) {
      return SecuryFlexTheme.getColorScheme(widget.userRole!);
    }
    return Theme.of(context).colorScheme;
  }

  /// Get responsive font size based on screen width
  double _getResponsiveFontSize(BuildContext context) {
    if (!widget.enableResponsiveFontSize) {
      return DesignTokens.fontSizeTitleLarge;
    }

    final screenWidth = MediaQuery.of(context).size.width;

    // For smaller phones (width < 360), use smaller font
    if (screenWidth < 360) {
      return DesignTokens.fontSizeTitle; // 20.0 instead of 22.0
    }

    // For very small phones (width < 320), use even smaller font
    if (screenWidth < 320) {
      return DesignTokens.fontSizeSubtitle; // 18.0
    }

    return DesignTokens.fontSizeTitleLarge; // Default 22.0
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case UnifiedHeaderType.simple:
        return _buildSimpleHeader(context);
      case UnifiedHeaderType.animated:
        return _buildAnimatedHeader(context);
      case UnifiedHeaderType.custom:
        return _buildCustomHeader(context);
      case UnifiedHeaderType.multiLine:
        return _buildMultiLineHeader(context);
      case UnifiedHeaderType.companyGradient:
        return _buildCompanyGradientHeader(context);
    }
  }

  Widget _buildSimpleHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = _getColorScheme(context);

    return PremiumGlassContainer(
      intensity: _getGlassIntensity(),
      elevation: _getGlassElevation(),
      tintColor: widget.backgroundColor ?? colorScheme.primary,
      enableTrustBorder: widget.showShadow,
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      height: widget.height ?? (AppBar().preferredSize.height + MediaQuery.of(context).padding.top),
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Padding(
          padding: widget.padding ?? EdgeInsets.symmetric(horizontal: DesignTokens.spacingHeaderPadding),
          child: widget.titleAlignment == TextAlign.center
              ? Stack(
                  children: [
                    // Leading widget aligned to the left
                    if (widget.leading != null)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: widget.leading!,
                      ),
                    // Title centered in the available space
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppBar().preferredSize.height + DesignTokens.spacingM,
                        ),
                        child: Text(
                          widget.title ?? '',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            fontSize: _getResponsiveFontSize(context),
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Actions aligned to the right
                    if (widget.actions != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.actions!,
                        ),
                      ),
                  ],
                )
              : Row(
                  children: [
                    if (widget.leading != null) widget.leading!,
                    Expanded(
                      child: Container(
                        alignment: widget.titleAlignment == TextAlign.left
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Text(
                          widget.title ?? '',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            fontSize: _getResponsiveFontSize(context),
                            color: colorScheme.onSurface,
                          ),
                          textAlign: widget.titleAlignment,
                        ),
                      ),
                    ),
                    if (widget.actions != null) ...widget.actions!,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(BuildContext context) {
    if (widget.animationController == null) {
      return _buildSimpleHeader(context);
    }

    final theme = Theme.of(context);
    final colorScheme = _getColorScheme(context);

    return AnimatedBuilder(
      animation: widget.animationController!,
      builder: (BuildContext context, Widget? child) {
        final animation = _topBarAnimation ?? Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: widget.animationController!,
            curve: Curves.fastOutSlowIn,
          ),
        );

        final topBarOpacity = animation.value;
        final scrollOpacity = widget.enableScrollAnimation ? _scrollOpacity : 1.0;
        final finalOpacity = topBarOpacity * scrollOpacity;

        return FadeTransition(
          opacity: animation,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - animation.value),
              0.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: widget.userRole == UserRole.guard 
                    ? colorScheme.primary.withValues(alpha: 0.02 * finalOpacity * _scrollOpacity)
                    : (widget.backgroundColor ?? colorScheme.surface).withValues(alpha: finalOpacity),
                borderRadius: widget.borderRadius ?? const BorderRadius.only(
                  bottomLeft: Radius.circular(DesignTokens.radiusXL),
                ),
                boxShadow: widget.showShadow && _scrollOpacity > 0 ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05 * finalOpacity * _scrollOpacity),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ] : null,
              ),
              child: SafeArea(
                child: Padding(
                  padding: widget.padding ?? EdgeInsets.only(
                    top: DesignTokens.spacingS,
                    left: DesignTokens.spacingM + 2,
                    right: DesignTokens.spacingM + 2,
                  ),
                  child: Row(
                    children: [
                      if (widget.leading != null) widget.leading!,
                      Expanded(
                        child: Container(
                          alignment: widget.titleAlignment == TextAlign.left
                              ? Alignment.centerLeft
                              : widget.titleAlignment == TextAlign.right
                                  ? Alignment.centerRight
                                  : Alignment.center,
                          child: Text(
                            widget.title ?? '',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: DesignTokens.fontWeightSemiBold,
                              fontSize: _getResponsiveFontSize(context),
                              color: colorScheme.onSurface,
                            ),
                            textAlign: widget.titleAlignment,
                          ),
                        ),
                      ),
                      if (widget.actions != null) ...widget.actions!,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      decoration: widget.showShadow ? _getHeaderDecoration(context) : null,
      child: SafeArea(
        child: Padding(
          padding: widget.padding ?? EdgeInsets.only(
            top: DesignTokens.spacingS,
            left: DesignTokens.spacingM + 2,
            right: DesignTokens.spacingM + 2,
          ),
          child: widget.customContent ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildMultiLineHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = _getColorScheme(context);

    return Container(
      height: widget.height ?? (AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
      decoration: _getHeaderDecoration(context),
      child: SafeArea(
        child: Padding(
          padding: widget.padding ?? EdgeInsets.symmetric(horizontal: DesignTokens.spacingHeaderPadding),
          child: Row(
            children: [
              if (widget.leading != null) widget.leading!,
              Expanded(
                child: Container(
                  alignment: widget.titleAlignment == TextAlign.left
                      ? Alignment.centerLeft
                      : widget.titleAlignment == TextAlign.right
                          ? Alignment.centerRight
                          : Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: widget.titleAlignment == TextAlign.left
                        ? CrossAxisAlignment.start
                        : widget.titleAlignment == TextAlign.right
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.title ?? '',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontSize: _getResponsiveFontSize(context),
                          color: colorScheme.onSurface,
                        ),
                        textAlign: widget.titleAlignment,
                      ),
                      if (widget.subtitle != null) ...[
                        SizedBox(height: DesignTokens.spacingXS),
                        Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (widget.actions != null) ...widget.actions!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyGradientHeader(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    // Calculate header height - include TabBar height if present
    double headerHeight = widget.height ?? (AppBar().preferredSize.height + mediaQuery.padding.top);
    if (widget.tabBar != null) {
      headerHeight += 48.0; // Standard TabBar height
    }

    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF008080), // Teal
            DesignTokens.colorPrimaryBlue, // Navy
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Main header content
            Container(
              height: AppBar().preferredSize.height,
              padding: widget.padding ?? EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
              child: Row(
                children: [
                  if (widget.leading != null) widget.leading!,
                  Expanded(
                    child: Text(
                      widget.title ?? '',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        fontSize: _getResponsiveFontSize(context),
                        color: DesignTokens.colorWhite,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                      textAlign: TextAlign.left, // Company headers use left alignment
                    ),
                  ),
                  if (widget.actions != null) ...widget.actions!,
                ],
              ),
            ),
            // Optional TabBar
            if (widget.tabBar != null)
              SizedBox(
                height: 48.0,
                child: widget.tabBar!,
              ),
          ],
        ),
      ),
    );
  }

  /// Get header decoration with shadow and gradient
  BoxDecoration _getHeaderDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colorScheme.surface,
          colorScheme.surface.withValues(alpha: 0.95),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );
  }
}

/// Helper widgets for common header elements
class HeaderElements {
  /// Standard back button with consistent styling
  static Widget backButton({
    VoidCallback? onPressed,
    Color? color,
    double? size,
    UserRole? userRole,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = userRole != null
            ? SecuryFlexTheme.getColorScheme(userRole)
            : Theme.of(context).colorScheme;

        return Container(
          alignment: Alignment.centerLeft,
          width: (size ?? 40) + AppBar().preferredSize.height,
          height: AppBar().preferredSize.height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
              onTap: onPressed ?? () => Navigator.of(context).pop(),
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.spacingS),
                child: Icon(
                  Icons.arrow_back,
                  color: color ?? colorScheme.onSurface,
                  size: size ?? 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Standard action button for headers
  static Widget actionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    double? size,
    UserRole? userRole,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = userRole != null
            ? SecuryFlexTheme.getColorScheme(userRole)
            : Theme.of(context).colorScheme;

        return SizedBox(
          width: AppBar().preferredSize.height,
          height: AppBar().preferredSize.height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
              onTap: onPressed,
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.spacingS),
                child: Icon(
                  icon,
                  color: color ?? colorScheme.onSurface,
                  size: size ?? 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Menu button for headers
  static Widget menuButton({
    VoidCallback? onPressed,
    Color? color,
    double? size,
    UserRole? userRole,
  }) {
    return actionButton(
      icon: Icons.menu,
      onPressed: onPressed ?? () {},
      color: color,
      size: size,
      userRole: userRole,
    );
  }

  /// Search button for headers
  static Widget searchButton({
    VoidCallback? onPressed,
    Color? color,
    double? size,
    UserRole? userRole,
  }) {
    return actionButton(
      icon: Icons.search,
      onPressed: onPressed ?? () {},
      color: color,
      size: size,
      userRole: userRole,
    );
  }

  /// More options button for headers
  static Widget moreButton({
    VoidCallback? onPressed,
    Color? color,
    double? size,
    UserRole? userRole,
  }) {
    return actionButton(
      icon: Icons.more_vert,
      onPressed: onPressed ?? () {},
      color: color,
      size: size,
      userRole: userRole,
    );
  }
}
