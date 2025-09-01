import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';

/// Smart Badge Overlay Component
/// Provides visual indicators for pending items and time-sensitive updates
/// Supports different badge types with accessibility features
/// Integrates with existing notification systems for real-time updates
class SmartBadgeOverlay extends StatefulWidget {
  const SmartBadgeOverlay({
    super.key,
    required this.child,
    this.badgeCount = 0,
    this.badgeType = BadgeType.info,
    this.showBadge = true,
    this.maxCount = 99,
    this.position = BadgePosition.topRight,
    this.animate = true,
    this.onBadgeTap,
    this.customBadgeContent,
    this.accessibilityLabel,
  });

  final Widget child;
  final int badgeCount;
  final BadgeType badgeType;
  final bool showBadge;
  final int maxCount;
  final BadgePosition position;
  final bool animate;
  final VoidCallback? onBadgeTap;
  final Widget? customBadgeContent;
  final String? accessibilityLabel;

  @override
  State<SmartBadgeOverlay> createState() => _SmartBadgeOverlayState();
}

class _SmartBadgeOverlayState extends State<SmartBadgeOverlay>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.showBadge && widget.badgeCount > 0) {
      _animationController.forward();
      
      // Start pulse animation for urgent badges
      if (widget.badgeType == BadgeType.urgent) {
        _startPulseAnimation();
      }
    }
  }

  void _startPulseAnimation() {
    _animationController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SmartBadgeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.showBadge && widget.badgeCount > 0) {
      if (oldWidget.badgeCount == 0 || !oldWidget.showBadge) {
        // Badge appeared
        _animationController.forward();
        
        if (widget.badgeType == BadgeType.urgent) {
          _startPulseAnimation();
        }
      } else if (widget.badgeType == BadgeType.urgent && oldWidget.badgeType != BadgeType.urgent) {
        // Badge became urgent
        _startPulseAnimation();
      }
    } else {
      // Badge disappeared
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (widget.showBadge && (widget.badgeCount > 0 || widget.customBadgeContent != null))
          _buildBadge(),
      ],
    );
  }

  Widget _buildBadge() {
    final badgePosition = _getBadgePosition();
    
    return Positioned(
      top: badgePosition.top,
      right: badgePosition.right,
      left: badgePosition.left,
      bottom: badgePosition.bottom,
      child: widget.animate
          ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.badgeType == BadgeType.urgent 
                      ? _pulseAnimation.value 
                      : _scaleAnimation.value,
                  child: _buildBadgeContent(),
                );
              },
            )
          : _buildBadgeContent(),
    );
  }

  Widget _buildBadgeContent() {
    if (widget.customBadgeContent != null) {
      return widget.customBadgeContent!;
    }

    final badgeColors = widget.badgeType.colors;
    final displayCount = widget.badgeCount > widget.maxCount 
        ? '${widget.maxCount}+' 
        : widget.badgeCount.toString();

    return GestureDetector(
      onTap: widget.onBadgeTap,
      child: Semantics(
        label: widget.accessibilityLabel ?? 
               '${widget.badgeCount} ${_getBadgeSemanticLabel()}',
        child: Container(
          constraints: BoxConstraints(
            minWidth: 20,
            minHeight: 20,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.badgeCount > 9 ? DesignTokens.spacingXS : 0,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: badgeColors.backgroundColor,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
            border: Border.all(
              color: DesignTokens.colorWhite,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: badgeColors.backgroundColor.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            displayCount,
            style: TextStyle(
              color: badgeColors.textColor,
              fontSize: DesignTokens.fontSizeXS,
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: DesignTokens.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  BadgePositionData _getBadgePosition() {
    switch (widget.position) {
      case BadgePosition.topRight:
        return BadgePositionData(top: -8, right: -8);
      case BadgePosition.topLeft:
        return BadgePositionData(top: -8, left: -8);
      case BadgePosition.bottomRight:
        return BadgePositionData(bottom: -8, right: -8);
      case BadgePosition.bottomLeft:
        return BadgePositionData(bottom: -8, left: -8);
    }
  }

  String _getBadgeSemanticLabel() {
    switch (widget.badgeType) {
      case BadgeType.urgent:
        return 'urgente meldingen';
      case BadgeType.info:
        return 'nieuwe meldingen';
      case BadgeType.success:
        return 'voltooide items';
      case BadgeType.warning:
        return 'waarschuwingen';
    }
  }
}

/// Badge Type Enumeration
enum BadgeType {
  urgent,
  info,
  success,
  warning;

  BadgeColors get colors {
    switch (this) {
      case BadgeType.urgent:
        return BadgeColors(
          backgroundColor: Color(0xFFE53E3E), // Red
          textColor: DesignTokens.colorWhite,
        );
      case BadgeType.info:
        return BadgeColors(
          backgroundColor: Color(0xFF3182CE), // Blue
          textColor: DesignTokens.colorWhite,
        );
      case BadgeType.success:
        return BadgeColors(
          backgroundColor: Color(0xFF38A169), // Green
          textColor: DesignTokens.colorWhite,
        );
      case BadgeType.warning:
        return BadgeColors(
          backgroundColor: Color(0xFFD69E2E), // Orange
          textColor: DesignTokens.colorWhite,
        );
    }
  }
}

/// Badge Position Enumeration
enum BadgePosition {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
}

/// Badge Colors Data Class
class BadgeColors {
  final Color backgroundColor;
  final Color textColor;

  const BadgeColors({
    required this.backgroundColor,
    required this.textColor,
  });
}

/// Badge Position Data Class
class BadgePositionData {
  final double? top;
  final double? right;
  final double? left;
  final double? bottom;

  const BadgePositionData({
    this.top,
    this.right,
    this.left,
    this.bottom,
  });
}
