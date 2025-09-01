import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../widgets/unified_message_bubble.dart';
import '../widgets/assignment_context_widget.dart';
import '../localization/chat_nl.dart';
import '../../auth/auth_service.dart';
import 'scroll_physics.dart';

/// Enhanced message list with smart grouping, optimal spacing, and premium visual hierarchy
/// 
/// Features:
/// - Smart message grouping by sender and timestamp
/// - Adaptive spacing for conversation flow
/// - Smooth animations and scroll physics
/// - Date separators with floating indicators
/// - Performance-optimized ListView with efficient rendering
/// - Avatar management for group conversations
/// - Message threading and context preservation
/// 
/// This component implements modern chat UX patterns inspired by WhatsApp, Telegram,
/// and iMessage while maintaining SecuryFlex professional aesthetics.
class ChatMessageList extends StatefulWidget {
  final List<MessageModel> messages;
  final ConversationModel conversation;
  final UserRole userRole;
  final ScrollController scrollController;
  final ChatScrollPhysics scrollPhysics;
  final Function(MessageModel) onMessageLongPress;
  final Function(String) onJumpToMessage;
  final AnimationController animationController;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.conversation,
    required this.userRole,
    required this.scrollController,
    required this.scrollPhysics,
    required this.onMessageLongPress,
    required this.onJumpToMessage,
    required this.animationController,
  });

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  final Map<String, AnimationController> _messageAnimations = {};

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: DesignTokens.durationSlow,
      vsync: this,
    );
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // Initialize message animations
    _initializeMessageAnimations();
  }

  void _initializeMessageAnimations() {
    for (int i = 0; i < widget.messages.length; i++) {
      final messageId = widget.messages[i].messageId;
      _messageAnimations[messageId] = AnimationController(
        duration: Duration(milliseconds: 200 + (i * 50)), // Staggered timing
        vsync: this,
      );
    }
    
    // Start staggered animations
    _startStaggeredAnimations();
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _messageAnimations.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        final controllers = _messageAnimations.values.toList();
        if (i < controllers.length) {
          controllers[i].forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle new messages with animation
    if (widget.messages.length > oldWidget.messages.length) {
      _handleNewMessages(oldWidget.messages);
    }
  }

  void _handleNewMessages(List<MessageModel> oldMessages) {
    final newMessages = widget.messages
        .where((msg) => !oldMessages.any((old) => old.messageId == msg.messageId))
        .toList();
    
    for (final message in newMessages) {
      if (!_messageAnimations.containsKey(message.messageId)) {
        _messageAnimations[message.messageId] = AnimationController(
          duration: DesignTokens.durationMedium,
          vsync: this,
        );
        
        // Animate new message in
        _messageAnimations[message.messageId]!.forward();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    for (final controller in _messageAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeController.value,
          child: _buildMessageList(),
        );
      },
    );
  }

  Widget _buildMessageList() {
    final totalItems = widget.messages.length + 
        (widget.conversation.assignmentId != null ? 1 : 0);

    return ListView.builder(
      controller: widget.scrollController,
      physics: widget.scrollPhysics,
      reverse: true, // Show newest messages at bottom
      padding: EdgeInsets.only(
        left: DesignTokens.spacingM,
        right: DesignTokens.spacingM,
        top: DesignTokens.spacingL,
        bottom: DesignTokens.spacingM,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Show assignment context at the top (last item in reversed list)
        if (widget.conversation.assignmentId != null && index == totalItems - 1) {
          return _buildAssignmentContext();
        }

        // Adjust index for messages
        final messageIndex = widget.conversation.assignmentId != null ? index : index;
        final message = widget.messages[messageIndex];

        return _buildMessageItem(context, messageIndex, message);
      },
    );
  }

  Widget _buildAssignmentContext() {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingL),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, -0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _slideController,
          curve: Curves.easeOutCubic,
        )),
        child: AssignmentContextWidget(
          assignmentId: widget.conversation.assignmentId!,
          userRole: widget.userRole,
          onAssignmentTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ChatNL.assignmentDetailsComingSoon),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, int messageIndex, MessageModel message) {
    final isCurrentUser = message.senderId == AuthService.currentUserType;
    final grouping = _calculateMessageGrouping(messageIndex, message);
    final spacing = _calculateMessageSpacing(messageIndex, message, grouping);
    
    return AnimatedBuilder(
      animation: _messageAnimations[message.messageId] ?? _fadeController,
      builder: (context, child) {
        final animation = _messageAnimations[message.messageId] ?? _fadeController;
        
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(isCurrentUser ? 1.0 : -1.0, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: FadeTransition(
            opacity: animation,
            child: _buildMessageWithSpacing(
              context, 
              messageIndex, 
              message, 
              grouping, 
              spacing
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageWithSpacing(
    BuildContext context,
    int messageIndex,
    MessageModel message,
    MessageGrouping grouping,
    MessageSpacing spacing,
  ) {
    final isCurrentUser = message.senderId == AuthService.currentUserType;
    
    return Column(
      children: [
        // Date separator
        if (spacing.showDateSeparator)
          _buildDateSeparator(message.timestamp),
        
        // Time gap indicator (for gaps > 1 hour)
        if (spacing.showTimeGap)
          _buildTimeGapIndicator(spacing.timeGap!),
        
        // Main message container
        Container(
          margin: EdgeInsets.only(
            top: spacing.topSpacing,
            bottom: spacing.bottomSpacing,
          ),
          child: _buildEnhancedMessageBubble(
            message, 
            isCurrentUser, 
            grouping
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedMessageBubble(
    MessageModel message, 
    bool isCurrentUser, 
    MessageGrouping grouping
  ) {
    return UnifiedMessageBubble(
      message: message,
      isCurrentUser: isCurrentUser,
      userRole: widget.userRole,
      onLongPress: () => widget.onMessageLongPress(message),
      showAvatar: grouping.showAvatar,
      showTimestamp: grouping.showTimestamp,
      isGroupChat: widget.conversation.conversationType == ConversationType.group,
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return Container(
      margin: EdgeInsets.symmetric(vertical: DesignTokens.spacingL),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXXL),
              boxShadow: [
                DesignTokens.shadowLight,
              ],
            ),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightMedium,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: DesignTokens.letterSpacingWide,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeGapIndicator(Duration timeGap) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    String gapText;
    
    if (timeGap.inHours >= 1) {
      gapText = '${timeGap.inHours} uur geleden';
    } else {
      gapText = '${timeGap.inMinutes} minuten geleden';
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingXS,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Text(
            gapText,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeController,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spacingXXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated chat icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 1200),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
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
                  
                  // Welcome text
                  Text(
                    ChatNL.noMessagesYet,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  
                  SizedBox(height: DesignTokens.spacingM),
                  
                  Text(
                    ChatNL.sendFirstMessage,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: DesignTokens.spacingXL),
                  
                  // Conversation starter suggestions
                  _buildConversationStarters(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationStarters() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    final starters = [
      '👋 Hallo!',
      '📋 Over de opdracht...',
      '📞 Wanneer kunnen we bellen?',
      '❓ Ik heb een vraag',
    ];

    return Column(
      children: starters.map((starter) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: OutlinedButton(
            onPressed: () {
              // Pre-fill input with starter text
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bericht voorgevuld: $starter'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
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
            child: Text(
              starter,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: DesignTokens.fontSizeBody,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Message grouping logic
  MessageGrouping _calculateMessageGrouping(int messageIndex, MessageModel message) {
    final isCurrentUser = message.senderId == AuthService.currentUserType;
    final isFirst = messageIndex == widget.messages.length - 1;
    final isLast = messageIndex == 0;
    
    bool showAvatar = true;
    bool showTimestamp = true;
    bool isGroupStart = true;
    bool isGroupEnd = true;

    if (!isFirst) {
      final nextMessage = widget.messages[messageIndex + 1];
      final timeDiff = message.timestamp.difference(nextMessage.timestamp);
      
      // Group messages from same sender within 5 minutes
      if (message.senderId == nextMessage.senderId && 
          timeDiff.inMinutes <= 5) {
        isGroupStart = false;
        showTimestamp = false;
      }
    }

    if (!isLast) {
      final prevMessage = widget.messages[messageIndex - 1];
      final timeDiff = prevMessage.timestamp.difference(message.timestamp);
      
      // Group messages from same sender within 5 minutes
      if (message.senderId == prevMessage.senderId && 
          timeDiff.inMinutes <= 5) {
        isGroupEnd = false;
        if (!isCurrentUser) {
          showAvatar = false;
        }
      }
    }

    return MessageGrouping(
      showAvatar: showAvatar,
      showTimestamp: showTimestamp,
      isGroupStart: isGroupStart,
      isGroupEnd: isGroupEnd,
    );
  }

  // Message spacing calculation
  MessageSpacing _calculateMessageSpacing(
    int messageIndex, 
    MessageModel message, 
    MessageGrouping grouping
  ) {
    double topSpacing = DesignTokens.spacingXS;
    double bottomSpacing = DesignTokens.spacingXS;
    bool showDateSeparator = false;
    bool showTimeGap = false;
    Duration? timeGap;

    // Date separator logic
    if (messageIndex == widget.messages.length - 1) {
      showDateSeparator = true;
    } else {
      final nextMessage = widget.messages[messageIndex + 1];
      final currentDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );
      final nextDate = DateTime(
        nextMessage.timestamp.year,
        nextMessage.timestamp.month,
        nextMessage.timestamp.day,
      );
      showDateSeparator = !currentDate.isAtSameMomentAs(nextDate);
    }

    // Time gap logic
    if (messageIndex < widget.messages.length - 1) {
      final nextMessage = widget.messages[messageIndex + 1];
      final timeDiff = message.timestamp.difference(nextMessage.timestamp);
      
      if (timeDiff.inHours >= 1) {
        showTimeGap = true;
        timeGap = timeDiff;
        topSpacing = DesignTokens.spacingM;
      }
    }

    // Group spacing adjustments
    if (!grouping.isGroupStart) {
      topSpacing = DesignTokens.spacingXXS; // Tighter spacing for grouped messages
    }
    
    if (!grouping.isGroupEnd) {
      bottomSpacing = DesignTokens.spacingXXS;
    }

    // Breathing room after groups
    if (grouping.isGroupEnd && messageIndex > 0) {
      bottomSpacing = DesignTokens.spacingM;
    }

    return MessageSpacing(
      topSpacing: topSpacing,
      bottomSpacing: bottomSpacing,
      showDateSeparator: showDateSeparator,
      showTimeGap: showTimeGap,
      timeGap: timeGap,
    );
  }

  String _formatDate(DateTime date) {
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
        'januari', 'februari', 'maart', 'april', 'mei', 'juni',
        'juli', 'augustus', 'september', 'oktober', 'november', 'december'
      ];
      
      final daysDiff = today.difference(messageDate).inDays;
      
      if (daysDiff <= 7) {
        return weekdays[date.weekday % 7];
      } else {
        return '${date.day} ${months[date.month - 1]}';
      }
    }
  }
}

/// Message grouping configuration
class MessageGrouping {
  final bool showAvatar;
  final bool showTimestamp;
  final bool isGroupStart;
  final bool isGroupEnd;

  const MessageGrouping({
    required this.showAvatar,
    required this.showTimestamp,
    required this.isGroupStart,
    required this.isGroupEnd,
  });
}

/// Message spacing configuration
class MessageSpacing {
  final double topSpacing;
  final double bottomSpacing;
  final bool showDateSeparator;
  final bool showTimeGap;
  final Duration? timeGap;

  const MessageSpacing({
    required this.topSpacing,
    required this.bottomSpacing,
    required this.showDateSeparator,
    required this.showTimeGap,
    this.timeGap,
  });
}