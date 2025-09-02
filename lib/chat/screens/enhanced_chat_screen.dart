import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../unified_header.dart';
import '../../unified_theme_system.dart';
import '../../unified_design_tokens.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/unified_chat_input.dart';
import '../widgets/unified_typing_indicator.dart';
import '../widgets/assignment_context_widget.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../localization/chat_nl.dart';
import '../../auth/auth_service.dart';
import 'chat_message_list.dart';
import 'floating_elements.dart';
import 'scroll_physics.dart';
import 'loading_states.dart';
import 'package:go_router/go_router.dart';

/// Enhanced chat screen with modern visual hierarchy and premium conversation experience
/// 
/// Features:
/// - Smart message spacing and grouping for optimal readability
/// - Floating elements (date indicators, scroll position, connection status)
/// - Custom scroll physics with momentum control and spring effects
/// - Skeleton loading states and smooth error handling
/// - Role-based theming with professional Dutch business aesthetics
/// - Accessibility-compliant design with screen reader support
/// - Performance-optimized rendering with efficient ListView management
/// 
/// This enhanced chat screen exceeds modern messaging standards while maintaining
/// SecuryFlex design consistency and enterprise-grade functionality.
class EnhancedChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  final UserRole userRole;
  final AnimationController? animationController;

  const EnhancedChatScreen({
    super.key,
    required this.conversation,
    required this.userRole,
    this.animationController,
  });

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers for smooth transitions
  late AnimationController _messageAnimationController;
  late AnimationController _headerOpacityController;
  late AnimationController _scrollPositionController;
  late AnimationController _connectionStatusController;
  
  // Scroll management
  late ScrollController _scrollController;
  late ChatScrollPhysics _scrollPhysics;
  
  // Chat state
  List<MessageModel> messages = [];
  bool isTyping = false;
  MessageReply? replyTo;
  bool isScrolledToBottom = true;
  bool showFloatingDate = false;
  DateTime? visibleDate;
  
  // Connection state
  bool isConnected = true;
  bool hasNewMessages = false;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeScrollManagement();
    _loadMessages();
    _setupListeners();
  }

  void _initializeControllers() {
    _messageAnimationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _headerOpacityController = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );
    
    _scrollPositionController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _connectionStatusController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    // Start with full opacity
    _headerOpacityController.forward();
    _connectionStatusController.forward();
  }

  void _initializeScrollManagement() {
    _scrollController = ScrollController();
    _scrollPhysics = ChatScrollPhysics(
      springConstant: 200.0,
      dampingRatio: 0.8,
      momentumRetention: 0.92,
    );
    
    // Listen for scroll changes
    _scrollController.addListener(_onScroll);
  }

  void _setupListeners() {
    // Select this conversation in the bloc
    context.read<ChatBloc>().add(
      SelectConversation(widget.conversation.conversationId),
    );
  }

  @override
  void dispose() {
    _messageAnimationController.dispose();
    _headerOpacityController.dispose();
    _scrollPositionController.dispose();
    _connectionStatusController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final scrollOffset = _scrollController.offset;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    
    // Update header opacity based on scroll
    final opacity = (1.0 - (scrollOffset / 100.0)).clamp(0.0, 1.0);
    if (_headerOpacityController.value != opacity) {
      _headerOpacityController.animateTo(opacity);
    }
    
    // Check if scrolled to bottom
    final wasAtBottom = isScrolledToBottom;
    isScrolledToBottom = scrollOffset <= 50.0;
    
    if (wasAtBottom != isScrolledToBottom) {
      setState(() {});
      
      if (isScrolledToBottom && hasNewMessages) {
        _markMessagesAsRead();
      }
    }
    
    // Update floating date visibility
    _updateFloatingDate(scrollOffset);
    
    // Update scroll position indicator
    final scrollPercentage = maxScrollExtent > 0 ? scrollOffset / maxScrollExtent : 0.0;
    _scrollPositionController.animateTo(scrollPercentage.clamp(0.0, 1.0));
  }

  void _updateFloatingDate(double scrollOffset) {
    // Calculate which date should be shown based on scroll position
    if (messages.isEmpty) return;
    
    // Logic to determine visible date based on scroll position
    final middleIndex = ((scrollOffset / 80.0).round()).clamp(0, messages.length - 1);
    final messageDate = messages[middleIndex].timestamp;
    final today = DateTime.now();
    final messageDay = DateTime(messageDate.year, messageDate.month, messageDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    
    DateTime? newVisibleDate;
    if (!messageDay.isAtSameMomentAs(todayDay)) {
      newVisibleDate = messageDay;
    }
    
    if (newVisibleDate != visibleDate) {
      setState(() {
        visibleDate = newVisibleDate;
        showFloatingDate = visibleDate != null;
      });
    }
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
        senderId: AuthService.currentUserType, 
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

    // Smooth scroll to bottom after sending
    _smoothScrollToBottom();
  }

  void _sendFile(String filePath, String fileName, MessageType type) {
    context.read<ChatBloc>().add(
      SendFileMessage(
        conversationId: widget.conversation.conversationId,
        senderId: AuthService.currentUserType,
        senderName: AuthService.currentUserName,
        filePath: filePath,
        fileName: fileName,
        messageType: type,
      ),
    );
    _smoothScrollToBottom();
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
            AuthService.currentUserType,
            AuthService.currentUserName,
          ),
        );
      } else {
        context.read<ChatBloc>().add(
          StopTyping(
            widget.conversation.conversationId,
            AuthService.currentUserType,
            AuthService.currentUserName,
          ),
        );
      }
    }
  }

  void _smoothScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: DesignTokens.durationMedium,
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _jumpToMessage(String messageId) {
    // Find message index and scroll to it with smooth animation
    final messageIndex = messages.indexWhere((msg) => msg.messageId == messageId);
    if (messageIndex != -1) {
      final targetOffset = messageIndex * 80.0; // Approximate message height
      _scrollController.animateTo(
        targetOffset,
        duration: DesignTokens.durationMedium,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _markMessagesAsRead() {
    setState(() {
      hasNewMessages = false;
      unreadCount = 0;
    });
    
    // TODO: Mark messages as read in the backend
    // context.read<ChatBloc>().add(
    //   MarkMessagesAsRead(widget.conversation.conversationId),
    // );
  }


  void _onMessageLongPress(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
    context.pop();
  }

  void _cancelReply() {
    setState(() {
      replyTo = null;
    });
  }

  Widget _buildMessageOptionsSheet(MessageModel message) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return AnimatedContainer(
      duration: DesignTokens.durationMedium,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusXL),
        ),
        boxShadow: [
          DesignTokens.shadowHeavy,
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced handle bar with animation
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Message preview
            Container(
              margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
              padding: EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(height: DesignTokens.spacingL),

            // Action options
            _buildActionTile(
              icon: Icons.reply,
              title: ChatNL.reply,
              onTap: () => _replyToMessage(message),
              colorScheme: colorScheme,
            ),
            _buildActionTile(
              icon: Icons.copy,
              title: ChatNL.copy,
              onTap: () {
                // Copy message content
                context.pop();
              },
              colorScheme: colorScheme,
            ),
            _buildActionTile(
              icon: Icons.forward,
              title: 'Doorsturen',
              onTap: () {
                // Forward message
                context.pop();
              },
              colorScheme: colorScheme,
            ),
            if (message.senderId == AuthService.currentUserType)
              _buildActionTile(
                icon: Icons.delete,
                title: ChatNL.delete,
                onTap: () {
                  context.pop();
                  _showDeleteConfirmation(message);
                },
                colorScheme: colorScheme,
                isDestructive: true,
              ),

            SizedBox(height: DesignTokens.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? colorScheme.error : colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightMedium,
          color: isDestructive ? colorScheme.error : colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
    );
  }

  void _showDeleteConfirmation(MessageModel message) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bericht verwijderen?'),
        content: Text('Dit bericht wordt permanent verwijderd.'),
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              // Delete message
            },
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            child: Text('Verwijderen'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return AnimatedBuilder(
      animation: _headerOpacityController,
      builder: (context, child) {
        final opacity = _headerOpacityController.value;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getHeaderColor().withValues(alpha: opacity),
                _getHeaderColor().withValues(alpha: opacity * 0.8),
              ],
            ),
          ),
          child: widget.userRole == UserRole.company
              ? UnifiedHeader.companyGradient(
                  title: widget.conversation.title,
                  showNotifications: false,
                  leading: HeaderElements.backButton(
                    onPressed: () => context.pop(),
                    color: DesignTokens.colorWhite,
                  ),
                  actions: _buildHeaderActions(),
                )
              : UnifiedHeader.simple(
                  title: widget.conversation.title,
                  userRole: widget.userRole,
                  leading: HeaderElements.backButton(
                    onPressed: () => context.pop(),
                    userRole: widget.userRole,
                  ),
                  actions: _buildHeaderActions(),
                ),
        );
      },
    );
  }

  Color _getHeaderColor() {
    switch (widget.userRole) {
      case UserRole.guard:
        return DesignTokens.guardPrimary;
      case UserRole.company:
        return DesignTokens.companyPrimary;
      case UserRole.admin:
        return DesignTokens.adminPrimary;
    }
  }

  List<Widget> _buildHeaderActions() {
    final color = widget.userRole == UserRole.company 
        ? DesignTokens.colorWhite 
        : null;
    
    return [
      HeaderElements.actionButton(
        icon: Icons.videocam,
        onPressed: () => _showFeatureComingSoon('Videogesprek'),
        color: color,
        userRole: widget.userRole,
      ),
      HeaderElements.actionButton(
        icon: Icons.call,
        onPressed: () => _showFeatureComingSoon('Bellen'),
        color: color,
        userRole: widget.userRole,
      ),
      HeaderElements.actionButton(
        icon: Icons.more_vert,
        onPressed: () => _showChatOptions(),
        color: color,
        userRole: widget.userRole,
      ),
    ];
  }

  void _showFeatureComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature functie komt binnenkort beschikbaar'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
      ),
    );
  }

  void _showChatOptions() {
    // Show chat options modal
    _showFeatureComingSoon('Chat opties');
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();

    return Container(
      color: backgroundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child: _buildEnhancedHeader(),
        ),
        body: Stack(
          children: [
            // Main chat content
            Column(
              children: [
                // Assignment context header (compact)
                if (widget.conversation.assignmentId != null)
                  AssignmentContextWidget(
                    assignmentId: widget.conversation.assignmentId!,
                    userRole: widget.userRole,
                    isCompact: true,
                    onAssignmentTap: () => _showFeatureComingSoon('Opdracht details'),
                  ),

                // Enhanced message list
                Expanded(
                  child: BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state is MessagesLoading) {
                        return ChatLoadingStates.buildMessageListSkeleton(
                          userRole: widget.userRole,
                        );
                      } else if (state is MessagesLoaded) {
                        messages = state.messages;
                        return ChatMessageList(
                          messages: messages,
                          conversation: widget.conversation,
                          userRole: widget.userRole,
                          scrollController: _scrollController,
                          scrollPhysics: _scrollPhysics,
                          onMessageLongPress: _onMessageLongPress,
                          onJumpToMessage: _jumpToMessage,
                          animationController: _messageAnimationController,
                        );
                      } else if (state.toString().contains('Error')) {
                        return ChatLoadingStates.buildErrorState(
                          error: 'Chat error occurred',
                          onRetry: _loadMessages,
                          userRole: widget.userRole,
                        );
                      } else {
                        return ChatLoadingStates.buildEmptyState(
                          userRole: widget.userRole,
                        );
                      }
                    },
                  ),
                ),

                // Enhanced typing indicator
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state is TypingStatusUpdated &&
                        state.typingUsers.isNotEmpty) {
                      return UnifiedTypingIndicator(
                        typingUsers: state.typingUsers,
                        currentUserId: AuthService.currentUserType,
                        userRole: widget.userRole,
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),

                // Enhanced chat input
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

            // Floating elements overlay
            Positioned.fill(
              child: ChatFloatingElements(
                showFloatingDate: showFloatingDate,
                visibleDate: visibleDate,
                isConnected: isConnected,
                hasNewMessages: hasNewMessages,
                unreadCount: unreadCount,
                scrollPercentage: _scrollPositionController.value,
                onScrollToBottom: _smoothScrollToBottom,
                onMarkAsRead: _markMessagesAsRead,
                userRole: widget.userRole,
                connectionAnimation: _connectionStatusController,
                scrollAnimation: _scrollPositionController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (widget.userRole) {
      case UserRole.guard:
        return DesignTokens.guardBackground;
      case UserRole.company:
        return DesignTokens.companyBackground;
      case UserRole.admin:
        return DesignTokens.adminBackground;
    }
  }
}