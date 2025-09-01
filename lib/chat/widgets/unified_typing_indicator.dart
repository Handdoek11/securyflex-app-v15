import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../models/typing_status_model.dart';

/// WhatsApp-quality typing indicator with smooth animations
/// Follows SecuryFlex unified design system patterns
class UnifiedTypingIndicator extends StatefulWidget {
  final List<TypingStatusModel> typingUsers;
  final UserRole userRole;
  final String currentUserId;

  const UnifiedTypingIndicator({
    super.key,
    required this.typingUsers,
    required this.userRole,
    required this.currentUserId,
  });

  @override
  State<UnifiedTypingIndicator> createState() => _UnifiedTypingIndicatorState();
}

class _UnifiedTypingIndicatorState extends State<UnifiedTypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    if (widget.typingUsers.isNotEmpty) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(UnifiedTypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.typingUsers.isNotEmpty && oldWidget.typingUsers.isEmpty) {
      _animationController.forward();
    } else if (widget.typingUsers.isEmpty && oldWidget.typingUsers.isNotEmpty) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    final validTypingUsers = widget.typingUsers
        .where((user) => user.userId != widget.currentUserId && user.isValid)
        .toList();

    if (validTypingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingXS,
          ),
          child: Row(
            children: [
              // Avatar for single user typing
              if (validTypingUsers.length == 1)
                _buildTypingAvatar(context, colorScheme, validTypingUsers.first),
              
              // Typing bubble
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(DesignTokens.radiusM),
                    topRight: Radius.circular(DesignTokens.radiusM),
                    bottomRight: Radius.circular(DesignTokens.radiusM),
                    bottomLeft: Radius.circular(DesignTokens.radiusS),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.colorBlack.withValues(alpha: 0.1),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Typing animation dots
                    _buildTypingDots(colorScheme),
                    
                    SizedBox(width: DesignTokens.spacingS),
                    
                    // Typing text
                    Text(
                      _getTypingText(validTypingUsers),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingAvatar(BuildContext context, ColorScheme colorScheme, TypingStatusModel user) {
    return Container(
      margin: EdgeInsets.only(right: DesignTokens.spacingS),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: Text(
          user.userName.isNotEmpty 
              ? user.userName[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingDots(ColorScheme colorScheme) {
    return SizedBox(
      width: 24,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return _TypingDot(
            color: colorScheme.primary,
            delay: Duration(milliseconds: index * 200),
          );
        }),
      ),
    );
  }

  String _getTypingText(List<TypingStatusModel> users) {
    if (users.isEmpty) return '';
    
    if (users.length == 1) {
      return '${users.first.userName} is aan het typen...';
    } else if (users.length == 2) {
      return '${users.first.userName} en ${users.last.userName} zijn aan het typen...';
    } else {
      return '${users.length} personen zijn aan het typen...';
    }
  }
}

/// Individual typing dot with animation
class _TypingDot extends StatefulWidget {
  final Color color;
  final Duration delay;

  const _TypingDot({
    required this.color,
    required this.delay,
  });

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    // Start animation with delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
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
        return Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Typing indicator for conversation list
class ConversationTypingIndicator extends StatelessWidget {
  final List<TypingStatusModel> typingUsers;
  final UserRole userRole;
  final String currentUserId;

  const ConversationTypingIndicator({
    super.key,
    required this.typingUsers,
    required this.userRole,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final validTypingUsers = typingUsers
        .where((user) => user.userId != currentUserId && user.isValid)
        .toList();

    if (validTypingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);

    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              return _TypingDot(
                color: colorScheme.primary,
                delay: Duration(milliseconds: index * 150),
              );
            }),
          ),
        ),
        SizedBox(width: DesignTokens.spacingXS),
        Expanded(
          child: Text(
            _getTypingText(validTypingUsers),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getTypingText(List<TypingStatusModel> users) {
    if (users.isEmpty) return '';
    
    if (users.length == 1) {
      return '${users.first.userName} is aan het typen...';
    } else {
      return '${users.length} personen zijn aan het typen...';
    }
  }
}
