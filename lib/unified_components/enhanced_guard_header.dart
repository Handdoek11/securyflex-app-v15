import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';

/// Enhanced Guard Header Component for SecuryFlex
/// 
/// A visually enhanced header specifically for guard-side screens with:
/// - Subtle gradient backgrounds
/// - Animated notification bells with pulse effects
/// - Micro-animations for action buttons
/// - Enhanced typography with shadows
/// - Performance-optimized animations
class EnhancedGuardHeader extends StatefulWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onNotificationPressed;
  final int notificationCount;
  final bool enableGradientBackground;
  final bool enableMicroAnimations;
  final ScrollController? scrollController;

  const EnhancedGuardHeader({
    super.key,
    required this.title,
    this.actions,
    this.onNotificationPressed,
    this.notificationCount = 0,
    this.enableGradientBackground = true,
    this.enableMicroAnimations = true,
    this.scrollController,
  });

  @override
  State<EnhancedGuardHeader> createState() => _EnhancedGuardHeaderState();
}

class _EnhancedGuardHeaderState extends State<EnhancedGuardHeader>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseAnimationController;
  late AnimationController _bellAnimationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bellAnimation;
  
  double _scrollOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    // EXTREME Pulse animation voor notification badge
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800), // Sneller
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.bounceInOut, // Bounce effect
    ));

    // EXTREME Bell shake animation
    _bellAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400), // Langer
      vsync: this,
    );
    _bellAnimation = Tween<double>(
      begin: -0.3,
      end: 0.3, // Veel meer movement
    ).animate(CurvedAnimation(
      parent: _bellAnimationController,
      curve: Curves.elasticOut,
    ));

    // Start pulse animation if there are notifications
    if (widget.notificationCount > 0) {
      _pulseAnimationController.repeat(reverse: true);
    }
  }

  void _setupScrollListener() {
    widget.scrollController?.addListener(_onScroll);
  }

  void _onScroll() {
    if (widget.scrollController == null) return;
    
    final scrollOffset = widget.scrollController!.offset;
    final newOpacity = (1.0 - (scrollOffset / 100)).clamp(0.7, 1.0);
    
    if (_scrollOpacity != newOpacity) {
      setState(() {
        _scrollOpacity = newOpacity;
      });
    }
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _bellAnimationController.dispose();
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // VEEL GROTERE HEIGHT voor meer visual impact
      height: (AppBar().preferredSize.height * 1.8) + MediaQuery.of(context).padding.top,
      decoration: _buildHeaderDecoration(),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
          child: Row(
            children: [
              // Enhanced title with gradient text
              Expanded(
                child: _buildEnhancedTitle(),
              ),
              
              // Enhanced actions
              ...(_buildEnhancedActions()),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildHeaderDecoration() {
    if (!widget.enableGradientBackground) {
      return BoxDecoration(
        color: DesignTokens.guardPrimary.withValues(alpha: _scrollOpacity),
      );
    }

    // DRASTISCHE GRADIENT - zeer zichtbare verandering
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DesignTokens.guardPrimary,
          const Color(0xFF0F2A5A), // Veel donkerder blauw
          const Color(0xFF1E40AF), // Bright blauw accent
          DesignTokens.colorSecondaryTeal.withValues(alpha: 0.3),
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ),
      // Shadow voor meer depth
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ],
    );
  }

  Widget _buildEnhancedTitle() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _scrollOpacity,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          widget.title,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeHeading, // GROTER font
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.colorGray800,
            fontFamily: DesignTokens.fontFamily,
            letterSpacing: 1.2, // Meer letter spacing
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6), // Donkere shadow
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
              Shadow(
                color: DesignTokens.colorSecondaryTeal.withValues(alpha: 0.3),
                offset: const Offset(0, 0),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEnhancedActions() {
    List<Widget> actions = [];

    // Enhanced notification bell
    if (widget.onNotificationPressed != null) {
      actions.add(_buildEnhancedNotificationBell());
    }

    // Add custom actions with enhancements
    if (widget.actions != null) {
      for (var action in widget.actions!) {
        actions.add(_enhanceActionWidget(action));
      }
    }

    return actions;
  }

  Widget _buildEnhancedNotificationBell() {
    return Padding(
      padding: EdgeInsets.only(left: DesignTokens.spacingS),
      child: AnimatedBuilder(
        animation: _bellAnimationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _bellAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
                onTap: () {
                  _bellAnimationController.forward().then((_) {
                    _bellAnimationController.reverse();
                  });
                  widget.onNotificationPressed?.call();
                },
                child: Container(
                  padding: EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    // DRAMATIC gradient background
                    gradient: LinearGradient(
                      colors: [
                        DesignTokens.colorGray800.withValues(alpha: 0.2),
                        DesignTokens.colorSecondaryTeal.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
                    border: Border.all(
                      color: DesignTokens.colorGray800.withValues(alpha: 0.4),
                      width: 2, // Dikker border
                    ),
                    // Extreme shadow
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Enhanced notification icon
                      Icon(
                        widget.notificationCount > 0 
                            ? Icons.notifications 
                            : Icons.notifications_outlined,
                        color: DesignTokens.colorGray800,
                        size: DesignTokens.iconSizeM,
                      ),
                      
                      // Enhanced badge with pulse animation
                      if (widget.notificationCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: _buildPulsatingBadge(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPulsatingBadge() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        // EXTREME scaling effect - veel meer zichtbaar
        final scale = 1.0 + (_pulseAnimation.value * 0.8);
        final glowIntensity = _pulseAnimation.value;
        
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.notificationCount > 9 
                  ? DesignTokens.spacingS
                  : DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              // Gradient background voor badge
              gradient: LinearGradient(
                colors: [
                  DesignTokens.colorError,
                  const Color(0xFFFF1744), // Bright red
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
              border: Border.all(
                color: DesignTokens.colorGray800,
                width: 3, // Dikker border
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.colorError.withValues(alpha: 0.8),
                  blurRadius: 12 + (glowIntensity * 8), // Variabele glow
                  spreadRadius: 2 + (glowIntensity * 3),
                ),
                // Extra glow effect
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.4 * glowIntensity),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minWidth: 28, // Groter
              minHeight: 28,
            ),
            child: Center(
              child: Text(
                widget.notificationCount > 99 ? '99+' : widget.notificationCount.toString(),
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS, // Groter font
                  fontWeight: DesignTokens.fontWeightBold,
                  color: DesignTokens.colorGray800,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _enhanceActionWidget(Widget action) {
    if (!widget.enableMicroAnimations) return action;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 150),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: EdgeInsets.only(left: DesignTokens.spacingS),
            child: action,
          ),
        );
      },
    );
  }
}