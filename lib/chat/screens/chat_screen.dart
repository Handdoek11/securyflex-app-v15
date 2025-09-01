import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../unified_header.dart';
import '../../unified_theme_system.dart';
import '../../unified_design_tokens.dart';

// CompanyDashboardTheme import removed - using unified design tokens
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/unified_message_bubble.dart';
import '../widgets/unified_chat_input.dart';
import '../widgets/unified_typing_indicator.dart';
import '../widgets/assignment_context_widget.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../localization/chat_nl.dart';
import '../../auth/auth_service.dart';

/// WhatsApp-quality individual chat screen with real-time messaging
/// Follows SecuryFlex unified design system patterns
class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  final UserRole userRole;
  final AnimationController? animationController;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.userRole,
    this.animationController,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late ScrollController scrollController;
  late AnimationController messageAnimationController;

  List<MessageModel> messages = [];
  bool isTyping = false;
  MessageReply? replyTo;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();

    // Initialize message animation controller
    messageAnimationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );

    // Load messages for this conversation
    _loadMessages();

    // Select this conversation in the bloc
    context.read<ChatBloc>().add(
      SelectConversation(widget.conversation.conversationId),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    messageAnimationController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    context.read<ChatBloc>().add(
      LoadMessages(widget.conversation.conversationId),
    );
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;

    context.read<ChatBloc>().add(
      SendTextMessage(
        conversationId: widget.conversation.conversationId,
        senderId: AuthService.currentUserType, // Should be actual user ID
        senderName: AuthService.currentUserName,
        content: content.trim(),
        replyTo: replyTo,
      ),
    );

    // Clear reply if set
    if (replyTo != null) {
      setState(() {
        replyTo = null;
      });
    }

    // Scroll to bottom after sending
    _scrollToBottom();
  }

  void _sendFile(String filePath, String fileName, MessageType type) {
    context.read<ChatBloc>().add(
      SendFileMessage(
        conversationId: widget.conversation.conversationId,
        senderId: AuthService.currentUserType, // Should be actual user ID
        senderName: AuthService.currentUserName,
        filePath: filePath,
        fileName: fileName,
        messageType: type,
      ),
    );
    _scrollToBottom();
  }

  void _onTypingChanged(bool typing) {
    if (typing != isTyping) {
      setState(() {
        isTyping = typing;
      });

      if (typing) {
        context.read<ChatBloc>().add(
          StartTyping(
            widget.conversation.conversationId,
            AuthService.currentUserType, // Should be actual user ID
            AuthService.currentUserName,
          ),
        );
      } else {
        context.read<ChatBloc>().add(
          StopTyping(
            widget.conversation.conversationId,
            AuthService.currentUserType, // Should be actual user ID
            AuthService.currentUserName,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0.0,
          duration: DesignTokens.durationMedium,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onMessageLongPress(MessageModel message) {
    // Show message options (reply, copy, delete, etc.)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMessageOptionsSheet(message),
    );
  }

  void _replyToMessage(MessageModel message) {
    setState(() {
      replyTo = MessageReply(
        messageId: message.messageId,
        senderId: message.senderId,
        senderName: message.senderName,
        content: message.content,
        messageType: message.messageType,
      );
    });
    Navigator.pop(context); // Close bottom sheet
  }

  void _cancelReply() {
    setState(() {
      replyTo = null;
    });
  }

  Widget _buildMessageOptionsSheet(MessageModel message) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusXL),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Options
            ListTile(
              leading: Icon(Icons.reply, color: colorScheme.primary),
              title: Text(
                ChatNL.reply,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              onTap: () => _replyToMessage(message),
            ),
            ListTile(
              leading: Icon(Icons.copy, color: colorScheme.onSurface),
              title: Text(
                ChatNL.copy,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              onTap: () {
                // Copy message content to clipboard
                Navigator.pop(context);
              },
            ),
            if (message.senderId == AuthService.currentUserType)
              ListTile(
                leading: Icon(Icons.delete, color: colorScheme.error),
                title: Text(
                  ChatNL.delete,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
                onTap: () {
                  // Delete message
                  Navigator.pop(context);
                },
              ),

            SizedBox(height: DesignTokens.spacingM),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<MessageModel> messages) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    // Check if this is an assignment conversation
    final hasAssignmentContext = widget.conversation.assignmentId != null;
    final totalItems = messages.length + (hasAssignmentContext ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      reverse: true, // Show newest messages at bottom
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Show assignment context at the top (last item in reversed list)
        if (hasAssignmentContext && index == totalItems - 1) {
          return Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
            child: AssignmentContextWidget(
              assignmentId: widget.conversation.assignmentId!,
              userRole: widget.userRole,
              onAssignmentTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(ChatNL.assignmentDetailsComingSoon),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          );
        }

        // Adjust index for messages
        final messageIndex = hasAssignmentContext ? index : index;
        final message = messages[messageIndex];
        final isCurrentUser = message.senderId == AuthService.currentUserType;

        // Show date separator if needed
        bool showDateSeparator = false;
        if (messageIndex == messages.length - 1) {
          showDateSeparator = true;
        } else {
          final nextMessage = messages[messageIndex + 1];
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

        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(message.timestamp),
            Padding(
              padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
              child: UnifiedMessageBubble(
                message: message,
                isCurrentUser: isCurrentUser,
                userRole: widget.userRole,
                onLongPress: () => _onMessageLongPress(message),
                showAvatar:
                    !isCurrentUser &&
                    widget.conversation.conversationType ==
                        ConversationType.group,
                isGroupChat:
                    widget.conversation.conversationType ==
                    ConversationType.group,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return Container(
      margin: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
            child: Text(
              _formatDate(date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return ChatNL.today;
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return ChatNL.yesterday;
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildEmptyState() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: DesignTokens.spacingL),
            Text(
              ChatNL.noMessagesYet,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamily,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              ChatNL.sendFirstMessage,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontFamily: DesignTokens.fontFamily,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Message loading icon
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.message_outlined,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 3),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            ChatNL.loadingMessages,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightMedium,
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Gebruik role-specific dashboard achtergrond
    final backgroundColor = widget.userRole == UserRole.guard
        ? DesignTokens.guardSurface
        : widget.userRole == UserRole.company
        ? SecuryFlexTheme.getColorScheme(UserRole.company).surfaceContainerHighest
        : SecuryFlexTheme.getColorScheme(widget.userRole).surface;

    return Container(
      color: backgroundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child: widget.userRole == UserRole.company
              ? UnifiedHeader.companyGradient(
                  title: widget.conversation.title,
                  showNotifications: false, // No notifications in individual chat
                  leading: HeaderElements.backButton(
                    onPressed: () => Navigator.pop(context),
                    color: DesignTokens.colorWhite,
                  ),
                  actions: [
                    HeaderElements.actionButton(
                      icon: Icons.videocam,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(ChatNL.videoCallFeatureComingSoon),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      color: DesignTokens.colorWhite,
                    ),
                    HeaderElements.actionButton(
                      icon: Icons.call,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(ChatNL.callFeatureComingSoon),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      color: DesignTokens.colorWhite,
                    ),
                    HeaderElements.actionButton(
                      icon: Icons.more_vert,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(ChatNL.chatOptionsComingSoon),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      color: DesignTokens.colorWhite,
                    ),
                  ],
                )
              : UnifiedHeader.simple(
                  title: widget.conversation.title,
                  userRole: widget.userRole,
                  leading: HeaderElements.backButton(
                    onPressed: () => Navigator.pop(context),
                    userRole: widget.userRole,
                  ),
                  actions: [
                    HeaderElements.actionButton(
                      icon: Icons.videocam,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(ChatNL.videoCallFeatureComingSoon),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      userRole: widget.userRole,
                    ),
                    HeaderElements.actionButton(
                      icon: Icons.call,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(ChatNL.callFeatureComingSoon),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      userRole: widget.userRole,
                    ),
                    HeaderElements.actionButton(
                      icon: Icons.more_vert,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(ChatNL.chatOptionsComingSoon),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      userRole: widget.userRole,
                    ),
                  ],
                ),
        ),
        body: Column(
          children: [
            // Assignment context header (compact)
            if (widget.conversation.assignmentId != null)
              AssignmentContextWidget(
                assignmentId: widget.conversation.assignmentId!,
                userRole: widget.userRole,
                isCompact: true,
                onAssignmentTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(ChatNL.assignmentDetailsComingSoon),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is MessagesLoading) {
                    return _buildLoadingState();
                  } else if (state is MessagesLoaded) {
                    return _buildMessagesList(state.messages);
                  } else {
                    return _buildEmptyState();
                  }
                },
              ),
            ),

            // Typing indicator
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is TypingStatusUpdated &&
                    state.typingUsers.isNotEmpty) {
                  return UnifiedTypingIndicator(
                    typingUsers: state.typingUsers,
                    currentUserId:
                        AuthService.currentUserType, // Should be actual user ID
                    userRole: widget.userRole,
                  );
                }
                return SizedBox.shrink();
              },
            ),

            // Chat input
            UnifiedChatInput(
              userRole: widget.userRole,
              onSendMessage: _sendMessage,
              onSendFile: _sendFile,
              onTypingChanged: _onTypingChanged,
              replyTo: replyTo,
              onCancelReply: _cancelReply,
              placeholder: ChatNL.typeMessage,
            ),
          ],
        ),
      ),
    );
  }
}
