import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';

/// Floating elements overlay for enhanced chat experience
/// 
/// Features:
/// - Floating date indicators during scroll with smooth animations
/// - Connection status badges with real-time updates
/// - Unread message counter with badge animations
/// - Scroll position indicator for conversation navigation
/// - "New messages" floating action button
/// - Smooth fade transitions and spring physics
/// 
/// This overlay provides contextual information and navigation aids
/// without cluttering the main conversation interface.
class ChatFloatingElements extends StatefulWidget {
  final bool showFloatingDate;
  final DateTime? visibleDate;
  final bool isConnected;
  final bool hasNewMessages;
  final int unreadCount;
  final double scrollPercentage;
  final VoidCallback onScrollToBottom;
  final VoidCallback onMarkAsRead;
  final UserRole userRole;
  final AnimationController connectionAnimation;
  final AnimationController scrollAnimation;

  const ChatFloatingElements({
    super.key,
    required this.showFloatingDate,
    this.visibleDate,
    required this.isConnected,
    required this.hasNewMessages,
    required this.unreadCount,
    required this.scrollPercentage,
    required this.onScrollToBottom,
    required this.onMarkAsRead,
    required this.userRole,
    required this.connectionAnimation,
    required this.scrollAnimation,
  });

  @override
  State<ChatFloatingElements> createState() => _ChatFloatingElementsState();
}

class _ChatFloatingElementsState extends State<ChatFloatingElements>
    with TickerProviderStateMixin {
  
  late AnimationController _dateAnimationController;
  late AnimationController _badgeAnimationController;
  late AnimationController _scrollToBottomController;
  late AnimationController _pulseController;
  
  late Animation<double> _dateOpacityAnimation;
  late Animation<Offset> _dateSlideAnimation;
  late Animation<double> _badgeScaleAnimation;
  late Animation<double> _scrollToBottomAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Date indicator animations
    _dateAnimationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _dateOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dateAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _dateSlideAnimation = Tween<Offset>(
      begin: Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _dateAnimationController,
      curve: Curves.easeOutBack,
    ));

    // Badge animations
    _badgeAnimationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _badgeScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgeAnimationController,
      curve: Curves.elasticOut,
    ));

    // Scroll to bottom FAB animations
    _scrollToBottomController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _scrollToBottomAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scrollToBottomController,
      curve: Curves.easeOutBack,
    ));

    // Pulse animation for attention
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start pulse animation (repeating)
    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ChatFloatingElements oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate date indicator visibility
    if (widget.showFloatingDate != oldWidget.showFloatingDate) {
      if (widget.showFloatingDate) {
        _dateAnimationController.forward();
      } else {
        _dateAnimationController.reverse();
      }
    }
    
    // Animate badge visibility
    if (widget.hasNewMessages != oldWidget.hasNewMessages ||
        widget.unreadCount != oldWidget.unreadCount) {
      if (widget.hasNewMessages && widget.unreadCount > 0) {
        _badgeAnimationController.forward();
      } else {
        _badgeAnimationController.reverse();
      }
    }
    
    // Animate scroll to bottom button
    if (widget.hasNewMessages != oldWidget.hasNewMessages) {
      if (widget.hasNewMessages) {
        _scrollToBottomController.forward();
      } else {
        _scrollToBottomController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _dateAnimationController.dispose();
    _badgeAnimationController.dispose();
    _scrollToBottomController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Stack(
      children: [
        // Floating date indicator
        if (widget.showFloatingDate && widget.visibleDate != null)
          _buildFloatingDate(colorScheme),
        
        // Connection status indicator
        _buildConnectionStatus(colorScheme),
        
        // Scroll position indicator
        _buildScrollPositionIndicator(colorScheme),
        
        // Unread message badge
        if (widget.hasNewMessages && widget.unreadCount > 0)
          _buildUnreadBadge(colorScheme),
        
        // Scroll to bottom FAB
        if (widget.hasNewMessages)
          _buildScrollToBottomFAB(colorScheme),
      ],
    );
  }

  Widget _buildFloatingDate(ColorScheme colorScheme) {
    return Positioned(
      top: DesignTokens.spacingL,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _dateAnimationController,
        builder: (context, child) {
          return SlideTransition(
            position: _dateSlideAnimation,
            child: FadeTransition(
              opacity: _dateOpacityAnimation,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingL,
                    vertical: DesignTokens.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXXL),
                    boxShadow: [
                      DesignTokens.shadowMedium,
                    ],
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _formatFloatingDate(widget.visibleDate!),
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: colorScheme.onSurface,
                      letterSpacing: DesignTokens.letterSpacingWide,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(ColorScheme colorScheme) {
    return Positioned(
      top: DesignTokens.spacingM,
      left: DesignTokens.spacingM,
      child: AnimatedBuilder(
        animation: widget.connectionAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: widget.connectionAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
                vertical: DesignTokens.spacingXS,
              ),
              decoration: BoxDecoration(
                color: widget.isConnected 
                    ? DesignTokens.colorSuccess.withValues(alpha: 0.9)
                    : DesignTokens.colorError.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isConnected ? DesignTokens.colorSuccess : DesignTokens.colorError)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: DesignTokens.colorWhite,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    widget.isConnected ? 'Verbonden' : 'Offline',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: DesignTokens.colorWhite,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrollPositionIndicator(ColorScheme colorScheme) {
    if (widget.scrollPercentage <= 0.1) return SizedBox.shrink();
    
    return Positioned(
      right: DesignTokens.spacingM,
      top: MediaQuery.of(context).size.height * 0.3,
      child: AnimatedBuilder(
        animation: widget.scrollAnimation,
        builder: (context, child) {
          return Container(
            width: 4,
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.topCenter,
              heightFactor: widget.scrollPercentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnreadBadge(ColorScheme colorScheme) {
    return Positioned(
      top: DesignTokens.spacingXL * 2,
      right: DesignTokens.spacingM,
      child: AnimatedBuilder(
        animation: _badgeAnimationController,
        builder: (context, child) {
          return ScaleTransition(
            scale: _badgeScaleAnimation,
            child: GestureDetector(
              onTap: widget.onMarkAsRead,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.unreadCount > 5 ? _pulseAnimation.value : 1.0,
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingS,
                        vertical: DesignTokens.spacingXXS,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DesignTokens.colorWhite,
                          width: 2,
                        ),
                        boxShadow: [
                          DesignTokens.shadowMedium,
                        ],
                      ),
                      child: Text(
                        widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          fontWeight: DesignTokens.fontWeightBold,
                          color: DesignTokens.colorWhite,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrollToBottomFAB(ColorScheme colorScheme) {
    return Positioned(
      bottom: DesignTokens.spacingXXL * 2,
      right: DesignTokens.spacingM,
      child: AnimatedBuilder(
        animation: _scrollToBottomController,
        builder: (context, child) {
          return ScaleTransition(
            scale: _scrollToBottomAnimation,
            child: FloatingActionButton.small(
              onPressed: () {
                widget.onScrollToBottom();
                widget.onMarkAsRead();
              },
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: DesignTokens.iconSizeM,
                  ),
                  if (widget.unreadCount > 0)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.onPrimary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatFloatingDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return 'Vandaag';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return 'Gisteren';
    } else {
      final weekdays = [
        'Zondag', 'Maandag', 'Dinsdag', 'Woensdag', 
        'Donderdag', 'Vrijdag', 'Zaterdag'
      ];
      final months = [
        'jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
        'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
      ];
      
      final daysDiff = today.difference(messageDate).inDays;
      
      if (daysDiff <= 7) {
        return weekdays[date.weekday % 7];
      } else if (date.year == now.year) {
        return '${date.day} ${months[date.month - 1]}';
      } else {
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }
    }
  }
}

/// Floating status badge for quick status updates
class ChatStatusBadge extends StatefulWidget {
  final String status;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;
  final bool isVisible;

  const ChatStatusBadge({
    super.key,
    required this.status,
    required this.backgroundColor,
    required this.textColor,
    this.onTap,
    this.isVisible = true,
  });

  @override
  State<ChatStatusBadge> createState() => _ChatStatusBadgeState();
}

class _ChatStatusBadgeState extends State<ChatStatusBadge>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ChatStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
                vertical: DesignTokens.spacingXS,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                boxShadow: [
                  DesignTokens.shadowLight,
                ],
              ),
              child: Text(
                widget.status,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: widget.textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}