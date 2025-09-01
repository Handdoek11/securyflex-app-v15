import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
// import '../../unified_components/unified_card_system.dart'; // File not found, using Container instead

/// Loading states and error handling for enhanced chat experience
/// 
/// Features:
/// - Shimmer skeleton loading for message lists
/// - Smooth loading animations with staggered timing
/// - Professional error states with retry functionality  
/// - Empty states with conversation starters
/// - Connection error handling with reconnect options
/// - Performance-optimized skeleton rendering
/// - Role-based theming for all loading states
/// 
/// This comprehensive loading state system provides users with clear
/// feedback and graceful degradation during network issues.
class ChatLoadingStates {
  ChatLoadingStates._(); // Utility class - no instantiation

  /// Build skeleton loading animation for message list
  static Widget buildMessageListSkeleton({
    required UserRole userRole,
    int messageCount = 8,
  }) {
    return _MessageListSkeleton(
      userRole: userRole,
      messageCount: messageCount,
    );
  }

  /// Build error state with retry functionality
  static Widget buildErrorState({
    required String error,
    required VoidCallback onRetry,
    required UserRole userRole,
  }) {
    return _ChatErrorState(
      error: error,
      onRetry: onRetry,
      userRole: userRole,
    );
  }

  /// Build empty state with conversation starters
  static Widget buildEmptyState({
    required UserRole userRole,
  }) {
    return _ChatEmptyState(userRole: userRole);
  }

  /// Build connection error state
  static Widget buildConnectionError({
    required VoidCallback onReconnect,
    required UserRole userRole,
  }) {
    return _ConnectionErrorState(
      onReconnect: onReconnect,
      userRole: userRole,
    );
  }

  /// Build typing indicator skeleton
  static Widget buildTypingSkeleton({
    required UserRole userRole,
  }) {
    return _TypingSkeleton(userRole: userRole);
  }

  /// Build message sending skeleton
  static Widget buildSendingSkeleton({
    required UserRole userRole,
    required bool isCurrentUser,
  }) {
    return _MessageSendingSkeleton(
      userRole: userRole,
      isCurrentUser: isCurrentUser,
    );
  }
}

/// Animated skeleton for message list loading
class _MessageListSkeleton extends StatefulWidget {
  final UserRole userRole;
  final int messageCount;

  const _MessageListSkeleton({
    required this.userRole,
    required this.messageCount,
  });

  @override
  State<_MessageListSkeleton> createState() => _MessageListSkeletonState();
}

class _MessageListSkeletonState extends State<_MessageListSkeleton>
    with TickerProviderStateMixin {
  
  late AnimationController _shimmerController;
  late AnimationController _fadeController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _shimmerController.repeat();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        reverse: true,
        padding: EdgeInsets.all(DesignTokens.spacingM),
        itemCount: widget.messageCount,
        itemBuilder: (context, index) {
          // Stagger animations for realistic loading effect
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 200 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: _buildSkeletonMessage(
                    context,
                    colorScheme,
                    index,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSkeletonMessage(
    BuildContext context,
    ColorScheme colorScheme,
    int index,
  ) {
    final isCurrentUser = index % 3 == 0; // Vary message alignment
    final messageWidths = [0.7, 0.5, 0.8, 0.6]; // Vary message lengths
    final width = MediaQuery.of(context).size.width * 
        messageWidths[index % messageWidths.length];

    return Container(
      margin: EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar placeholder for other users
          if (!isCurrentUser)
            _buildSkeletonAvatar(colorScheme),
          
          // Message bubble skeleton
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Container(
                width: width,
                margin: EdgeInsets.only(
                  left: isCurrentUser ? 0 : DesignTokens.spacingS,
                ),
                child: _buildShimmerContainer(
                  colorScheme,
                  height: 60 + (index % 3) * 20, // Vary heights
                  borderRadius: _getMessageBorderRadius(isCurrentUser),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonAvatar(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(right: DesignTokens.spacingS),
          child: _buildShimmerContainer(
            colorScheme,
            width: 32,
            height: 32,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildShimmerContainer(
    ColorScheme colorScheme, {
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusM),
        gradient: LinearGradient(
          begin: Alignment(-1.0, -0.3),
          end: Alignment(1.0, 0.3),
          colors: [
            colorScheme.surfaceContainerLow,
            colorScheme.surfaceContainerHigh,
            colorScheme.surfaceContainerLow,
          ],
          stops: [
            (_shimmerAnimation.value - 1.0).clamp(0.0, 1.0),
            _shimmerAnimation.value.clamp(0.0, 1.0),
            (_shimmerAnimation.value + 1.0).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }

  BorderRadius _getMessageBorderRadius(bool isCurrentUser) {
    const radius = DesignTokens.radiusM;
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
      bottomLeft: Radius.circular(isCurrentUser ? radius : DesignTokens.radiusS),
      bottomRight: Radius.circular(isCurrentUser ? DesignTokens.radiusS : radius),
    );
  }
}

/// Error state with retry functionality
class _ChatErrorState extends StatefulWidget {
  final String error;
  final VoidCallback onRetry;
  final UserRole userRole;

  const _ChatErrorState({
    required this.error,
    required this.onRetry,
    required this.userRole,
  });

  @override
  State<_ChatErrorState> createState() => _ChatErrorStateState();
}

class _ChatErrorStateState extends State<_ChatErrorState>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: DesignTokens.durationSlow,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.spacingXXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Error icon
                    Container(
                      padding: EdgeInsets.all(DesignTokens.spacingL),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          DesignTokens.shadowMedium,
                        ],
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                    ),
                    
                    SizedBox(height: DesignTokens.spacingXL),
                    
                    // Error title
                    Text(
                      'Kon berichten niet laden',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeTitle,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: DesignTokens.spacingM),
                    
                    // Error message
                    Text(
                      widget.error,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeBody,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: DesignTokens.spacingXL),
                    
                    // Retry button
                    ElevatedButton.icon(
                      onPressed: widget.onRetry,
                      icon: Icon(Icons.refresh),
                      label: Text('Opnieuw proberen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingXL,
                          vertical: DesignTokens.spacingM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                        ),
                      ),
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
}

/// Empty state with conversation starters
class _ChatEmptyState extends StatefulWidget {
  final UserRole userRole;

  const _ChatEmptyState({
    required this.userRole,
  });

  @override
  State<_ChatEmptyState> createState() => _ChatEmptyStateState();
}

class _ChatEmptyStateState extends State<_ChatEmptyState>
    with TickerProviderStateMixin {
  
  late AnimationController _iconController;
  late AnimationController _contentController;
  late Animation<double> _iconAnimation;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();
    
    _iconController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: DesignTokens.durationSlow,
      vsync: this,
    );
    
    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));
    
    _contentAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutBack,
    ));
    
    _iconController.forward();
    
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        _contentController.forward();
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated chat icon
            AnimatedBuilder(
              animation: _iconAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _iconAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(DesignTokens.spacingL),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        DesignTokens.shadowMedium,
                      ],
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: DesignTokens.spacingXL),
            
            // Content with staggered animation
            AnimatedBuilder(
              animation: _contentAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _contentAnimation.value)),
                  child: Opacity(
                    opacity: _contentAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          'Nog geen berichten',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeTitle,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        
                        SizedBox(height: DesignTokens.spacingM),
                        
                        Text(
                          'Begin het gesprek door een bericht te sturen',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeBody,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: DesignTokens.spacingXL),
                        
                        _buildConversationStarters(colorScheme),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationStarters(ColorScheme colorScheme) {
    final starters = [
      {'emoji': '👋', 'text': 'Hallo!'},
      {'emoji': '📋', 'text': 'Over de opdracht...'},
      {'emoji': '📞', 'text': 'Wanneer kunnen we bellen?'},
      {'emoji': '❓', 'text': 'Ik heb een vraag'},
    ];

    return Column(
      children: starters.asMap().entries.map((entry) {
        final index = entry.key;
        final starter = entry.value;
        
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Bericht voorgevuld: ${starter['text']}'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingL,
                        vertical: DesignTokens.spacingM,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          starter['emoji']!,
                          style: TextStyle(fontSize: DesignTokens.fontSizeL),
                        ),
                        SizedBox(width: DesignTokens.spacingM),
                        Expanded(
                          child: Text(
                            starter['text']!,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: DesignTokens.fontSizeBody,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

/// Connection error state
class _ConnectionErrorState extends StatefulWidget {
  final VoidCallback onReconnect;
  final UserRole userRole;

  const _ConnectionErrorState({
    required this.onReconnect,
    required this.userRole,
  });

  @override
  State<_ConnectionErrorState> createState() => _ConnectionErrorStateState();
}

class _ConnectionErrorStateState extends State<_ConnectionErrorState>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing connection icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(DesignTokens.spacingL),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.error.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.wifi_off,
                      size: 64,
                      color: colorScheme.error,
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: DesignTokens.spacingXL),
            
            Text(
              'Verbinding verbroken',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
            
            SizedBox(height: DesignTokens.spacingM),
            
            Text(
              'Controleer je internetverbinding en probeer opnieuw',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: DesignTokens.spacingXL),
            
            ElevatedButton.icon(
              onPressed: widget.onReconnect,
              icon: Icon(Icons.refresh),
              label: Text('Verbinden'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingXL,
                  vertical: DesignTokens.spacingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Typing indicator skeleton
class _TypingSkeleton extends StatefulWidget {
  final UserRole userRole;

  const _TypingSkeleton({required this.userRole});

  @override
  State<_TypingSkeleton> createState() => _TypingSkeletonState();
}

class _TypingSkeletonState extends State<_TypingSkeleton>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: EdgeInsets.only(right: DesignTokens.spacingS),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(
                    alpha: _animation.value,
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Message sending skeleton
class _MessageSendingSkeleton extends StatefulWidget {
  final UserRole userRole;
  final bool isCurrentUser;

  const _MessageSendingSkeleton({
    required this.userRole,
    required this.isCurrentUser,
  });

  @override
  State<_MessageSendingSkeleton> createState() => _MessageSendingSkeletonState();
}

class _MessageSendingSkeletonState extends State<_MessageSendingSkeleton>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXS,
      ),
      child: Row(
        mainAxisAlignment: widget.isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 200,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.isCurrentUser
                      ? colorScheme.primary.withValues(alpha: _animation.value * 0.7)
                      : colorScheme.surfaceContainerHigh.withValues(
                          alpha: _animation.value,
                        ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(DesignTokens.radiusM),
                    topRight: Radius.circular(DesignTokens.radiusM),
                    bottomLeft: Radius.circular(
                      widget.isCurrentUser ? DesignTokens.radiusM : DesignTokens.radiusS,
                    ),
                    bottomRight: Radius.circular(
                      widget.isCurrentUser ? DesignTokens.radiusS : DesignTokens.radiusM,
                    ),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.isCurrentUser
                                ? colorScheme.onPrimary.withValues(alpha: 0.7)
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Text(
                        'Verzenden...',
                        style: TextStyle(
                          color: widget.isCurrentUser
                              ? colorScheme.onPrimary.withValues(alpha: 0.8)
                              : colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: DesignTokens.fontSizeS,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}