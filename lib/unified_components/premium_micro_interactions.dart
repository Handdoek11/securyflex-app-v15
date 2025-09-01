import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../unified_design_tokens.dart';
import 'premium_color_system.dart';

/// **Premium Micro-Interactions System**
/// 
/// Next-level micro-interactions for security industry trust-building:
/// - Security-specific feedback animations that build confidence
/// - Trust-building visual confirmations for critical actions
/// - Professional haptic feedback patterns for enhanced UX
/// - Subtle pulsing and breathing effects for status indicators
/// - Smooth state transitions that communicate system reliability
/// 
/// These micro-interactions elevate user confidence from good to exceptional
/// through carefully crafted feedback that reinforces security and trust.

// ============================================================================
// SECURITY STATUS MICRO-INTERACTIONS
// ============================================================================

/// **Security Shield Pulse Animation**
/// Animated shield icon that pulses for active security monitoring
class SecurityShieldPulse extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  const SecurityShieldPulse({
    super.key,
    this.isActive = true,
    this.color = DesignTokens.guardPrimary,
    this.size = 24.0,
    this.onTap,
  });

  @override
  State<SecurityShieldPulse> createState() => _SecurityShieldPulseState();
}

class _SecurityShieldPulseState extends State<SecurityShieldPulse>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shieldController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _shieldController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _shieldController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SecurityShieldPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shieldController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      _shieldController.forward().then((_) {
        _shieldController.reverse();
      });
      
      // 2025 Enhanced Security Haptic Pattern
      _performSecurityHapticSequence();
      
      widget.onTap!();
    }
  }

  /// **2025 Security Haptic Pattern** - Sophisticated feedback for trust-building
  Future<void> _performSecurityHapticSequence() async {
    // Initial confirmation tap
    await HapticFeedback.lightImpact();
    
    // Brief pause
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Security verification pattern (mimics heartbeat for trust)
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
    
    // Completion confirmation
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring effect for active security
              if (widget.isActive)
                Container(
                  width: widget.size * _pulseAnimation.value,
                  height: widget.size * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(alpha: 
                        0.3 * (1 - (_pulseAnimation.value - 1) / 0.3)),
                      width: 2,
                    ),
                  ),
                ),
              
              // Main shield icon
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    gradient: PremiumColors.securityShieldGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.security,
                    color: Colors.white,
                    size: widget.size * 0.6,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// **Trust-Building Status Indicator**
/// Animated status badge that builds confidence through smooth transitions
class TrustStatusIndicator extends StatefulWidget {
  final String status;
  final bool isAnimated;
  final Duration animationDuration;

  const TrustStatusIndicator({
    super.key,
    required this.status,
    this.isAnimated = true,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<TrustStatusIndicator> createState() => _TrustStatusIndicatorState();
}

class _TrustStatusIndicatorState extends State<TrustStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _displayStatus = '';
  Color _statusColor = DesignTokens.guardPrimary;
  IconData _statusIcon = Icons.check_circle;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _updateStatusProperties();
    
    if (widget.isAnimated) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TrustStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      _updateStatusProperties();
      if (widget.isAnimated) {
        _controller.reset();
        _controller.forward();
      }
    }
  }

  void _updateStatusProperties() {
    _displayStatus = _getDisplayText(widget.status);
    _statusColor = _getStatusColor(widget.status);
    _statusIcon = _getStatusIcon(widget.status);
  }

  String _getDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'verified': return 'Geverifieerd';
      case 'pending': return 'In behandeling';
      case 'approved': return 'Goedgekeurd';
      case 'active': return 'Actief';
      case 'secure': return 'Beveiligd';
      case 'online': return 'Online';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
      case 'active':
      case 'secure':
        return DesignTokens.colorSuccess;
      case 'pending':
        return DesignTokens.colorWarning;
      case 'online':
        return DesignTokens.guardPrimary;
      default:
        return DesignTokens.guardTextSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
        return Icons.verified_user;
      case 'secure':
        return Icons.security;
      case 'active':
        return Icons.radio_button_checked;
      case 'pending':
        return Icons.schedule;
      case 'online':
        return Icons.wifi;
      default:
        return Icons.info;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _statusColor.withValues(alpha: 0.1),
                _statusColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _statusIcon,
                size: 14,
                color: _statusColor,
              ),
              const SizedBox(width: 6),
              Text(
                _displayStatus,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: _statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// INTERACTION FEEDBACK MICRO-ANIMATIONS
// ============================================================================

/// **Premium Button with Trust-Building Feedback**
/// Enhanced button with sophisticated micro-interactions
class PremiumInteractiveButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isLoading;
  final bool showSuccessAnimation;

  const PremiumInteractiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.isLoading = false,
    this.showSuccessAnimation = false,
  });

  @override
  State<PremiumInteractiveButton> createState() => _PremiumInteractiveButtonState();
}

class _PremiumInteractiveButtonState extends State<PremiumInteractiveButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late AnimationController _successController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _successAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(PremiumInteractiveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showSuccessAnimation != oldWidget.showSuccessAnimation && 
        widget.showSuccessAnimation) {
      _successController.forward();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    _rippleController.forward().then((_) => _rippleController.reset());
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTap() {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.mediumImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isPrimary ? DesignTokens.guardPrimary : DesignTokens.guardTextSecondary;
    
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _handleTapDown : null,
      onTapUp: widget.onPressed != null ? _handleTapUp : null,
      onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _rippleAnimation, _successAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: widget.isPrimary 
                        ? PremiumColors.trustGradientPrimary
                        : null,
                    color: widget.isPrimary 
                        ? null 
                        : (_isPressed ? primaryColor.withValues(alpha: 0.1) : Colors.transparent),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: widget.isPrimary ? 0.0 : 0.3),
                      width: widget.isPrimary ? 0 : 1,
                    ),
                    boxShadow: widget.isPrimary ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isPrimary ? Colors.white : primaryColor,
                            ),
                          ),
                        )
                      else if (widget.showSuccessAnimation)
                        Transform.scale(
                          scale: _successAnimation.value,
                          child: Icon(
                            Icons.check,
                            color: widget.isPrimary ? Colors.white : DesignTokens.colorSuccess,
                            size: 20,
                          ),
                        )
                      else if (widget.icon != null)
                        Icon(
                          widget.icon,
                          color: widget.isPrimary ? Colors.white : primaryColor,
                          size: 20,
                        ),

                      if ((widget.icon != null || widget.isLoading || widget.showSuccessAnimation) 
                          && widget.text.isNotEmpty)
                        const SizedBox(width: 8),

                      if (widget.text.isNotEmpty)
                        Text(
                          widget.text,
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: DesignTokens.fontSizeBody,
                            fontWeight: DesignTokens.fontWeightMedium,
                            color: widget.isPrimary ? Colors.white : primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Ripple effect
                if (_rippleAnimation.value > 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                        color: (widget.isPrimary ? Colors.white : primaryColor)
                            .withValues(alpha: 0.2 * (1 - _rippleAnimation.value)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// BREATHING AND PULSE ANIMATIONS
// ============================================================================

/// **Breathing Connection Indicator**
/// Subtle breathing animation for connection status
class BreathingConnectionStatus extends StatefulWidget {
  final bool isConnected;
  final String label;
  final double size;

  const BreathingConnectionStatus({
    super.key,
    this.isConnected = true,
    this.label = 'Verbonden',
    this.size = 16.0,
  });

  @override
  State<BreathingConnectionStatus> createState() => _BreathingConnectionStatusState();
}

class _BreathingConnectionStatusState extends State<BreathingConnectionStatus>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isConnected) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BreathingConnectionStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isConnected 
        ? DesignTokens.colorSuccess 
        : DesignTokens.colorError;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: widget.isConnected ? _animation.value : 1.0,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: widget.isConnected ? [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4 * _animation.value),
                      blurRadius: 6 * _animation.value,
                      spreadRadius: 2 * _animation.value,
                    ),
                  ] : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeCaption,
                fontWeight: DesignTokens.fontWeightMedium,
                color: statusColor,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// **Fluid Morphing Card** - 2025 trend for organic shape transformations
class FluidMorphingCard extends StatefulWidget {
  final Widget child;
  final bool isExpanded;
  final VoidCallback? onTap;
  final Duration morphDuration;

  const FluidMorphingCard({
    super.key,
    required this.child,
    this.isExpanded = false,
    this.onTap,
    this.morphDuration = const Duration(milliseconds: 800),
  });

  @override
  State<FluidMorphingCard> createState() => _FluidMorphingCardState();
}

class _FluidMorphingCardState extends State<FluidMorphingCard>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late AnimationController _glowController;
  late Animation<double> _borderRadiusAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    _morphController = AnimationController(
      duration: widget.morphDuration,
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Fluid border radius morphing
    _borderRadiusAnimation = Tween<double>(
      begin: 12.0,
      end: 24.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.elasticOut,
    ));

    // Dynamic elevation changes
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeOutCubic,
    ));

    // Subtle glow effect
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Color morphing
    _colorAnimation = ColorTween(
      begin: DesignTokens.guardBackground,
      end: DesignTokens.guardPrimary.withValues(alpha: 0.05),
    ).animate(_morphController);

    if (widget.isExpanded) {
      _morphController.forward();
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FluidMorphingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _morphController.forward();
        _glowController.repeat(reverse: true);
      } else {
        _morphController.reverse();
        _glowController.stop();
      }
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_morphController, _glowController]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.guardPrimary.withValues(alpha: 0.1 * _glowAnimation.value),
                  blurRadius: 20 * _glowAnimation.value,
                  offset: Offset(0, 4 * _elevationAnimation.value),
                  spreadRadius: 2 * _glowAnimation.value,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10 * _elevationAnimation.value,
                  offset: Offset(0, 2 * _elevationAnimation.value),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 10.0 + (5.0 * _morphController.value),
                  sigmaY: 10.0 + (5.0 * _morphController.value),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.2 + (0.1 * _morphController.value)),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(
                      color: DesignTokens.guardPrimary.withValues(alpha: 0.1 + (0.2 * _morphController.value)),
                      width: 1.0 + _morphController.value,
                    ),
                    borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0 + (8.0 * _morphController.value)),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// **Professional Loading Spinner with Trust Elements**
/// Enhanced loading indicator that builds confidence during wait times
class PremiumSecurityLoader extends StatefulWidget {
  final String message;
  final double size;

  const PremiumSecurityLoader({
    super.key,
    this.message = 'Beveiliging controleren...',
    this.size = 50.0,
  });

  @override
  State<PremiumSecurityLoader> createState() => _PremiumSecurityLoaderState();
}

class _PremiumSecurityLoaderState extends State<PremiumSecurityLoader>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(_rotationController);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    gradient: PremiumColors.trustGradientPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security,
                    color: Colors.white,
                    size: widget.size * 0.5,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          widget.message,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.guardTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}