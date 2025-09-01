import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import 'input_field_animations.dart';

/// Premium animated send button with multiple states and smooth transitions
/// Includes press feedback, rotation animation, loading states, and haptic feedback
class AnimatedSendButton extends StatefulWidget {
  /// User role for theming
  final UserRole userRole;
  
  /// Whether the button is enabled (has text to send)
  final bool isEnabled;
  
  /// Whether the button is in sending state
  final bool isSending;
  
  /// Callback when button is pressed
  final VoidCallback? onPressed;
  
  /// Custom icon (defaults to send icon)
  final IconData? icon;
  
  /// Button size (defaults to 48x48)
  final double size;
  
  /// Whether to show loading indicator when sending
  final bool showLoadingIndicator;
  
  /// Custom tooltip text
  final String? tooltip;

  const AnimatedSendButton({
    super.key,
    required this.userRole,
    required this.isEnabled,
    this.isSending = false,
    this.onPressed,
    this.icon,
    this.size = 48.0,
    this.showLoadingIndicator = true,
    this.tooltip,
  });

  @override
  State<AnimatedSendButton> createState() => _AnimatedSendButtonState();
}

class _AnimatedSendButtonState extends State<AnimatedSendButton>
    with TickerProviderStateMixin, AnimationLifecycleMixin {
  
  // Animation controllers
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _colorController;
  late AnimationController _loadingController;
  
  // Animations
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _loadingAnimation;
  
  // State tracking
  bool _isPressed = false;
  bool _wasEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _wasEnabled = widget.isEnabled;
  }

  void _initializeAnimations() {
    // Scale animation for press feedback
    _scaleController = InputFieldAnimations.createButtonPressController(this);
    registerController(_scaleController);
    _scaleAnimation = InputFieldAnimations.createScaleAnimation(_scaleController);
    
    // Rotation animation for send action
    _rotationController = InputFieldAnimations.createSendRotationController(this);
    registerController(_rotationController);
    _rotationAnimation = InputFieldAnimations.createRotationAnimation(_rotationController);
    
    // Color animation for enabled/disabled states
    _colorController = InputFieldAnimations.createFocusController(this);
    registerController(_colorController);
    _setupColorAnimation();
    
    // Loading animation for sending state
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    registerController(_loadingController);
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.linear),
    );
    
    // Start loading animation if initially sending
    if (widget.isSending) {
      _loadingController.repeat();
    }
  }
  
  void _setupColorAnimation() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    _colorAnimation = InputFieldAnimations.createColorAnimation(
      _colorController,
      colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
      colorScheme.primary,
    );
  }

  @override
  void didUpdateWidget(AnimatedSendButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle enabled state changes
    if (widget.isEnabled != oldWidget.isEnabled) {
      _handleEnabledStateChange();
    }
    
    // Handle sending state changes
    if (widget.isSending != oldWidget.isSending) {
      _handleSendingStateChange();
    }
    
    // Handle role changes (for theming)
    if (widget.userRole != oldWidget.userRole) {
      _setupColorAnimation();
    }
  }
  
  void _handleEnabledStateChange() {
    if (widget.isEnabled && !_wasEnabled) {
      // Button became enabled - animate to active color
      _colorController.forward();
    } else if (!widget.isEnabled && _wasEnabled) {
      // Button became disabled - animate to inactive color
      _colorController.reverse();
    }
    _wasEnabled = widget.isEnabled;
  }
  
  void _handleSendingStateChange() {
    if (widget.isSending) {
      // Start sending animation
      _rotationController.forward();
      if (widget.showLoadingIndicator) {
        _loadingController.repeat();
      }
    } else {
      // Stop sending animation
      _rotationController.reverse();
      _loadingController.stop();
      _loadingController.reset();
    }
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isSending) {
      setState(() {
        _isPressed = true;
      });
      _scaleController.forward();
      InputFieldAnimations.lightHaptic();
    }
  }
  
  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }
  
  void _handleTapCancel() {
    _handleTapEnd();
  }
  
  void _handleTapEnd() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _scaleController.reverse();
    }
  }
  
  void _handleTap() {
    if (widget.isEnabled && !widget.isSending) {
      InputFieldAnimations.sendHaptic();
      widget.onPressed?.call();
    }
  }

  Color _getButtonColor() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    if (widget.isSending) {
      return colorScheme.primary.withValues(alpha: 0.8);
    } else if (widget.isEnabled) {
      return _colorAnimation.value ?? colorScheme.primary;
    } else {
      return colorScheme.onSurfaceVariant.withValues(alpha: 0.3);
    }
  }
  
  Color _getIconColor() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    if (widget.isSending) {
      return colorScheme.onPrimary.withValues(alpha: 0.8);
    } else if (widget.isEnabled) {
      return colorScheme.onPrimary;
    } else {
      return colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    }
  }
  
  Widget _buildButtonContent() {
    if (widget.isSending && widget.showLoadingIndicator) {
      return AnimatedBuilder(
        animation: _loadingAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Loading indicator
              SizedBox(
                width: DesignTokens.iconSizeL,
                height: DesignTokens.iconSizeL,
                child: CircularProgressIndicator(
                  value: null,
                  strokeWidth: 2.0,
                  color: _getIconColor(),
                ),
              ),
              // Optional icon overlay
              if (widget.icon != null)
                Icon(
                  widget.icon,
                  color: _getIconColor().withValues(alpha: 0.5),
                  size: DesignTokens.iconSizeS,
                ),
            ],
          );
        },
      );
    } else {
      return AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159, // Convert to radians
            child: Icon(
              widget.icon ?? Icons.send,
              color: _getIconColor(),
              size: DesignTokens.iconSizeL,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return InputFieldAnimations.createOptimizedAnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _getButtonColor(),
              borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
              boxShadow: widget.isEnabled && !widget.isSending
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 8.0,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
                onTap: _handleTap,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                splashColor: colorScheme.onPrimary.withValues(alpha: 0.2),
                highlightColor: colorScheme.onPrimary.withValues(alpha: 0.1),
                child: Center(
                  child: _buildButtonContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Simplified send button for basic use cases
class SimpleSendButton extends StatelessWidget {
  final UserRole userRole;
  final bool isEnabled;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double size;

  const SimpleSendButton({
    super.key,
    required this.userRole,
    required this.isEnabled,
    this.onPressed,
    this.icon,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSendButton(
      userRole: userRole,
      isEnabled: isEnabled,
      onPressed: onPressed,
      icon: icon,
      size: size,
      showLoadingIndicator: false,
    );
  }
}

/// Send button with custom styling options
class CustomAnimatedSendButton extends StatelessWidget {
  final UserRole userRole;
  final bool isEnabled;
  final bool isSending;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? padding;

  const CustomAnimatedSendButton({
    super.key,
    required this.userRole,
    required this.isEnabled,
    this.isSending = false,
    this.onPressed,
    this.icon,
    this.size = 48.0,
    this.backgroundColor,
    this.iconColor,
    this.shadows,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: AnimatedSendButton(
        userRole: userRole,
        isEnabled: isEnabled,
        isSending: isSending,
        onPressed: onPressed,
        icon: icon,
        size: size,
      ),
    );
  }
}