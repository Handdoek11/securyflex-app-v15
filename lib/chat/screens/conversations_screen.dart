import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import '../../unified_header.dart';
import '../../unified_theme_system.dart';
import '../../unified_design_tokens.dart';
import '../../unified_components/unified_background_service.dart';
// BeveiligerDashboardTheme import removed - using unified design tokens
// CompanyDashboardTheme import removed - using unified design tokens
import '../../unified_buttons.dart';

import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../models/conversation_model.dart';
import '../../auth/auth_service.dart';
import '../../unified_components/smart_badge_overlay.dart';
import '../../beveiliger_notificaties/services/guard_notification_service.dart';
import '../../beveiliger_notificaties/screens/notification_center_screen.dart';
import '../../beveiliger_notificaties/bloc/notification_center_bloc.dart';

import '../localization/chat_nl.dart';

/// WhatsApp-quality conversations list screen with search and role-based theming
/// Follows SecuryFlex unified design system patterns
class ConversationsScreen extends StatefulWidget {
  final AnimationController? animationController;
  final UserRole userRole;

  const ConversationsScreen({
    super.key,
    this.animationController,
    required this.userRole,
  });

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with TickerProviderStateMixin {
  late ScrollController scrollController;
  late TextEditingController searchController;
  late AnimationController searchAnimationController;
  late Animation<double> searchAnimation;

  bool isSearchActive = false;
  String searchQuery = '';
  List<ConversationModel> filteredConversations = [];
  
  // Notification state
  final GuardNotificationService _notificationService = GuardNotificationService.instance;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    debugPrint("ConversationsScreen loaded for ${widget.userRole}");
    scrollController = ScrollController();
    searchController = TextEditingController();

    // Initialize search animation
    searchAnimationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: searchAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize chat and load conversations
    _initializeChat();
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    searchAnimationController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    final currentUserId =
        AuthService.currentUserType; // This should be actual user ID
    context.read<ChatBloc>().add(InitializeChat(currentUserId));
    context.read<ChatBloc>().add(LoadConversations(currentUserId));
    
    // Load notification count for guards only
    if (widget.userRole == UserRole.guard) {
      _loadUnreadNotificationCount();
    }
  }

  Future<void> _refreshConversations() async {
    final currentUserId = AuthService.currentUserType;
    context.read<ChatBloc>().add(LoadConversations(currentUserId));
    // Add small delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Load unread notification count for guards
  void _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Navigate to notification center for guards
  void _navigateToNotificationCenter() {
    context.go('/beveiliger/profile/notifications');
    // Note: GoRouter doesn't provide return values like Navigator.push
    // If needed, use GoRouter redirect logic or state management instead
  }

  void _toggleSearch() {
    setState(() {
      isSearchActive = !isSearchActive;
      if (isSearchActive) {
        searchAnimationController.forward();
      } else {
        searchAnimationController.reverse();
        searchController.clear();
        searchQuery = '';
        _filterConversations([]);
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
    // Filter conversations based on search query
    final state = context.read<ChatBloc>().state;
    if (state is ConversationsLoaded) {
      _filterConversations(state.conversations);
    }
  }

  void _filterConversations(List<ConversationModel> conversations) {
    if (searchQuery.isEmpty) {
      filteredConversations = conversations;
    } else {
      filteredConversations = conversations.where((conversation) {
        final titleMatch = conversation.title.toLowerCase().contains(
          searchQuery.toLowerCase(),
        );
        final lastMessageMatch =
            conversation.lastMessage?.content.toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ??
            false;
        return titleMatch || lastMessageMatch;
      }).toList();
    }
  }


  Widget _buildSearchBar() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return AnimatedBuilder(
      animation: searchAnimation,
      builder: (context, child) {
        return Container(
          height: searchAnimation.value * 60,
          margin: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          child: Opacity(
            opacity: searchAnimation.value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: ChatNL.searchConversations,
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                              onPressed: () {
                                searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      filled: false, // No fill, using glassmorphism background
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingM,
                        vertical: DesignTokens.spacingS,
                      ),
                    ),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: DesignTokens.fontSizeBody,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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
              searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.chat_bubble_outline,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: DesignTokens.spacingL),
            Text(
              searchQuery.isNotEmpty
                  ? ChatNL.noConversationsFound
                  : ChatNL.noConversationsYet,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamily,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              searchQuery.isNotEmpty
                  ? ChatNL.tryDifferentSearch
                  : ChatNL.conversationsAutoCreated,
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
          // Chat icon with subtle animation
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 1000),
            tween: Tween(begin: 0.8, end: 1.0),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: EdgeInsets.all(DesignTokens.spacingL),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: DesignTokens.spacingL),
          CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 3),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            ChatNL.loadingConversations,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightMedium,
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            ChatNL.loadingPleaseWait,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            SizedBox(height: DesignTokens.spacingL),
            Text(
              ChatNL.errorLoadingConversations,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightMedium,
                fontFamily: DesignTokens.fontFamily,
                color: colorScheme.error,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              error,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontFamily: DesignTokens.fontFamily,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.spacingL),
            UnifiedButton.primary(
              text: ChatNL.tryAgain,
              onPressed: _initializeChat,
            ),
          ],
        ),
      ),
    );
  }




  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return ChatNL.now;
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}${ChatNL.minutesAgo}';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}${ChatNL.hoursAgo}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${ChatNL.daysAgo}';
    } else {
      return '${(difference.inDays / 7).floor()}${ChatNL.weeksAgo}';
    }
  }




  Widget _buildEmptyConversationsContent() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingXL),
      child: Column(
        children: [
          Icon(
            searchQuery.isNotEmpty
                ? Icons.search_off
                : Icons.chat_bubble_outline,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            searchQuery.isNotEmpty
                ? ChatNL.noConversationsFound
                : ChatNL.noConversationsYet,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            searchQuery.isNotEmpty
                ? ChatNL.tryDifferentSearch
                : ChatNL.conversationsAutoCreated,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build modern mobile-first chat layout
  Widget _buildDashboardStyleLayout(List<ConversationModel> conversations) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return RefreshIndicator(
      onRefresh: _refreshConversations,
      color: colorScheme.primary,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM, // Smaller padding for mobile
          vertical: DesignTokens.spacingS,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mobile-optimized header
            _buildMobileHeader(conversations),
            
            SizedBox(height: DesignTokens.spacingM),

            // Mobile-optimized conversation list
            _buildMobileConversationsList(conversations),

            SizedBox(height: DesignTokens.spacingL),
          ],
        ),
      ),
    );
  }

  /// Get appropriate icon for conversation type with professional context
  IconData _getConversationIcon(ConversationModel conversation) {
    switch (conversation.conversationType) {
      case ConversationType.assignment:
        return Icons.business_center; // Professional briefcase for job-related chats
      case ConversationType.group:
        return Icons.groups_2; // Team chat icon
      case ConversationType.direct:
        return Icons.account_circle_outlined; }
  }
  
  /// Handle opening a conversation
  void _openConversation(ConversationModel conversation) {
    final userType = widget.userRole == UserRole.guard ? 'beveiliger' : 'company';
    context.go('/$userType/chat/${conversation.conversationId}');
  }
  

  /// Mobile-optimized header with condensed stats
  Widget _buildMobileHeader(List<ConversationModel> conversations) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    final unreadCount = conversations.fold<int>(
      0,
      (sum, conv) => sum + conv.getUnreadCount(AuthService.currentUserType),
    );
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXS),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),  // Matching Jobs and Dashboard
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,  // Consistent with other components
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ChatNL.workConversations,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeTitle,
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  conversations.length == 1 
                    ? '${conversations.length} actief gesprek'
                    : '${conversations.length} actieve gesprekken',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontFamily: DesignTokens.fontFamily,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  ChatNL.jobConversationContext,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamily,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXS,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.colorError,
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              ),
              child: Text(
                '$unreadCount',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeCaption,
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: DesignTokens.colorWhite,
                ),
              ),
            ),
        ],
      ),
        ),
      ),
    );
  }
  
  /// Mobile-optimized conversations list with compact cards
  Widget _buildMobileConversationsList(List<ConversationModel> conversations) {
    final displayConversations = searchQuery.isNotEmpty
        ? filteredConversations
        : conversations;

    if (displayConversations.isEmpty) {
      return _buildEmptyConversationsContent();
    }

    return Column(
      children: displayConversations
          .map((conversation) => _buildMobileConversationCard(conversation))
          .toList(),
    );
  }
  
  /// Mobile-optimized conversation card with compact design
  Widget _buildMobileConversationCard(ConversationModel conversation) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    final unreadCount = conversation.getUnreadCount(AuthService.currentUserType);
    final hasUnread = unreadCount > 0;
    final lastMessage = conversation.lastMessage;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingXS,
        vertical: DesignTokens.spacingXS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          onTap: () => _openConversation(conversation),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: EdgeInsets.all(DesignTokens.spacingM),
                decoration: BoxDecoration(
                  color: hasUnread 
                      ? Colors.white.withValues(alpha: 0.25)  // More opaque for unread
                      : Colors.white.withValues(alpha: 0.18), // Matching other components
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(
                    color: hasUnread 
                        ? colorScheme.primary.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.25),
                    width: 1.5,  // Consistent border width
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Icon(
                    _getConversationIcon(conversation),
                    color: colorScheme.primary,
                    size: DesignTokens.iconSizeM,
                  ),
                ),
                SizedBox(width: DesignTokens.spacingM),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.title,
                              style: TextStyle(
                                fontSize: DesignTokens.fontSizeBody,
                                fontFamily: DesignTokens.fontFamily,
                                fontWeight: hasUnread 
                                    ? DesignTokens.fontWeightBold
                                    : DesignTokens.fontWeightMedium,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread)
                            Container(
                              margin: EdgeInsets.only(left: DesignTokens.spacingXS),
                              padding: EdgeInsets.symmetric(
                                horizontal: DesignTokens.spacingXS,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DesignTokens.colorError,
                                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: TextStyle(
                                  fontSize: DesignTokens.fontSizeCaption,
                                  fontFamily: DesignTokens.fontFamily,
                                  fontWeight: DesignTokens.fontWeightBold,
                                  color: DesignTokens.colorWhite,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (lastMessage != null) ...[
                        SizedBox(height: DesignTokens.spacingXS),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMessage.content,
                                style: TextStyle(
                                  fontSize: DesignTokens.fontSizeCaption,
                                  fontFamily: DesignTokens.fontFamily,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: DesignTokens.spacingXS),
                            Text(
                              _formatTimeAgo(lastMessage.timestamp),
                              style: TextStyle(
                                fontSize: DesignTokens.fontSizeCaption,
                                fontFamily: DesignTokens.fontFamily,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Unified background pattern matching Dashboard and Jobs
    return SafeArea(
      child: widget.userRole == UserRole.guard 
        ? UnifiedBackgroundService.guardMeshGradient(
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  // Header
                  widget.animationController != null
                      ? UnifiedHeader.animated(
                          title: ChatNL.chat,
                          animationController: widget.animationController!,
                          scrollController: scrollController,
                          enableScrollAnimation: true,
                          userRole: widget.userRole,
                          titleAlignment: TextAlign.left,
                          actions: [
                      // Search button first
                      HeaderElements.actionButton(
                        icon: isSearchActive ? Icons.close : Icons.search,
                        onPressed: _toggleSearch,
                        userRole: widget.userRole,
                      ),
                      // Notification bell last (rightmost)
                      SmartBadgeOverlay(
                        badgeCount: _unreadNotificationCount,
                        child: HeaderElements.actionButton(
                          icon: Icons.notifications_outlined,
                          onPressed: _navigateToNotificationCenter,
                          userRole: widget.userRole,
                        ),
                      ),
                    ],
                  )
                      : UnifiedHeader(
                          title: ChatNL.chat,
                          userRole: widget.userRole,
                          titleAlignment: TextAlign.left,
                          actions: [
                      // Search button first
                      HeaderElements.actionButton(
                        icon: isSearchActive ? Icons.close : Icons.search,
                        onPressed: _toggleSearch,
                        userRole: widget.userRole,
                      ),
                      // Notification icon
                      SmartBadgeOverlay(
                        badgeCount: _unreadNotificationCount,
                        child: HeaderElements.actionButton(
                          icon: Icons.notifications_outlined,
                          onPressed: _navigateToNotificationCenter,
                          userRole: widget.userRole,
                        ),
                      ),
                    ],
                  ),
                  // Search bar
                  if (isSearchActive) _buildSearchBar(),
                  // Content
                  Expanded(
                    child: BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        if (state is ChatLoading) {
                          return _buildLoadingState();
                        } else if (state is ConversationsLoaded) {
                          if (searchQuery.isNotEmpty) {
                            _filterConversations(state.conversations);
                          }
                          return _buildDashboardStyleLayout(state.conversations);
                        } else if (state is ChatError) {
                          return _buildErrorState(state.message);
                        } else {
                          return _buildEmptyState();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        // Company version - use Scaffold for now as company doesn't have mesh gradient
        : Scaffold(
            backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.company).surface,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.companyGradient(
                title: ChatNL.chat,
                showNotifications: true,
                actions: [
                  HeaderElements.actionButton(
                    icon: isSearchActive ? Icons.close : Icons.search,
                    onPressed: _toggleSearch,
                    color: DesignTokens.colorWhite,
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                // Search bar
                if (isSearchActive) _buildSearchBar(),
                // Content
                Expanded(
                  child: BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state is ChatLoading) {
                        return _buildLoadingState();
                      } else if (state is ConversationsLoaded) {
                        if (searchQuery.isNotEmpty) {
                          _filterConversations(state.conversations);
                        }
                        return _buildDashboardStyleLayout(state.conversations);
                      } else if (state is ChatError) {
                        return _buildErrorState(state.message);
                      } else {
                        return _buildEmptyState();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }


}
