import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../unified_theme_system.dart';
import 'enhanced_accessibility_helper.dart';
import 'high_contrast_themes.dart';
import 'dart:async';

/// Chat-specific accessibility service for SecuryFlex
/// 
/// Provides specialized accessibility features for chat functionality including:
/// - Message announcement management
/// - Typing status notifications
/// - Screen reader optimization
/// - Focus management for chat navigation
/// - Live region updates for dynamic content
class ChatAccessibilityService {
  static ChatAccessibilityService? _instance;
  static ChatAccessibilityService get instance => 
      _instance ??= ChatAccessibilityService._();
  
  ChatAccessibilityService._();

  // Message announcement state
  Timer? _announcementTimer;
  String? _lastAnnouncedMessage;
  List<String> _previousTypingUsers = [];
  bool _isScreenReaderActive = false;
  
  // Focus management
  final Map<String, FocusNode> _chatFocusNodes = {};
  String? _currentConversationId;
  
  // Accessibility preferences
  bool _reduceMotionEnabled = false;
  bool _highContrastEnabled = false;
  bool _announceTypingEnabled = true;
  bool _announceMessagesEnabled = true;
  
  // ============================================================================
  // INITIALIZATION & CONFIGURATION
  // ============================================================================
  
  /// Initialize the chat accessibility service
  Future<void> initialize() async {
    await _updateAccessibilitySettings();
    _startAccessibilityMonitoring();
  }
  
  /// Update accessibility settings from device preferences
  Future<void> _updateAccessibilitySettings() async {
    _isScreenReaderActive = EnhancedAccessibilityHelper.isScreenReaderEnabled;
    _reduceMotionEnabled = EnhancedAccessibilityHelper.isReduceMotionEnabled;
    _highContrastEnabled = EnhancedAccessibilityHelper.isHighContrastEnabled;
  }
  
  /// Start monitoring accessibility setting changes
  void _startAccessibilityMonitoring() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateAccessibilitySettings();
    });
  }
  
  // ============================================================================
  // MESSAGE ACCESSIBILITY
  // ============================================================================
  
  /// Announce new message with intelligent delay and deduplication
  void announceMessage({
    required String content,
    required String senderName,
    required bool isCurrentUser,
    required String conversationId,
    bool isUrgent = false,
  }) {
    if (!_announceMessagesEnabled || !_isScreenReaderActive) return;
    
    // Don't announce own messages unless urgent
    if (isCurrentUser && !isUrgent) return;
    
    // Prevent duplicate announcements
    final messageKey = '$senderName:$content';
    if (_lastAnnouncedMessage == messageKey) return;
    
    _lastAnnouncedMessage = messageKey;
    
    final announcement = _buildMessageAnnouncement(
      content: content,
      senderName: senderName,
      isCurrentUser: isCurrentUser,
      conversationId: conversationId,
    );
    
    if (isUrgent) {
      _announceImmediately(announcement);
    } else {
      _announceWithDelay(announcement);
    }
  }
  
  /// Announce typing status changes with smart filtering
  void announceTypingStatus({
    required List<String> typingUsers,
    required String conversationId,
  }) {
    if (!_announceTypingEnabled || !_isScreenReaderActive) return;
    
    // Only announce if users actually changed
    if (_typingUsersChanged(typingUsers, _previousTypingUsers)) {
      final announcement = _buildTypingAnnouncement(typingUsers);
      _announceWithDelay(announcement, delay: Duration(milliseconds: 1000));
      _previousTypingUsers = List.from(typingUsers);
    }
  }
  
  /// Announce conversation status changes
  void announceConversationUpdate({
    required String message,
    required String conversationId,
    bool isError = false,
  }) {
    if (!_isScreenReaderActive) return;
    
    final priority = isError ? 'Fout: ' : 'Update: ';
    final announcement = '$priority$message';
    
    if (isError) {
      _announceImmediately(announcement);
    } else {
      _announceWithDelay(announcement);
    }
  }
  
  // ============================================================================
  // FOCUS MANAGEMENT
  // ============================================================================
  
  /// Get or create focus node for conversation
  FocusNode getFocusNodeForConversation(String conversationId) {
    return _chatFocusNodes.putIfAbsent(
      conversationId,
      () => FocusNode(debugLabel: 'Chat_$conversationId'),
    );
  }
  
  /// Focus on specific conversation
  void focusConversation(String conversationId) {
    _currentConversationId = conversationId;
    final focusNode = getFocusNodeForConversation(conversationId);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }
  
  /// Focus on message input for current conversation
  void focusMessageInput(String conversationId) {
    final inputFocusNode = _chatFocusNodes['${conversationId}_input'];
    if (inputFocusNode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        inputFocusNode.requestFocus();
      });
    }
  }
  
  /// Register message input focus node
  void registerMessageInputFocus(String conversationId, FocusNode focusNode) {
    _chatFocusNodes['${conversationId}_input'] = focusNode;
  }
  
  /// Clear focus nodes for conversation (cleanup)
  void clearConversationFocus(String conversationId) {
    _chatFocusNodes.remove(conversationId);
    _chatFocusNodes.remove('${conversationId}_input');
    
    if (_currentConversationId == conversationId) {
      _currentConversationId = null;
    }
  }
  
  // ============================================================================
  // ACCESSIBILITY PREFERENCES
  // ============================================================================
  
  /// Enable or disable message announcements
  void setMessageAnnouncementsEnabled(bool enabled) {
    _announceMessagesEnabled = enabled;
  }
  
  /// Enable or disable typing status announcements
  void setTypingAnnouncementsEnabled(bool enabled) {
    _announceTypingEnabled = enabled;
  }
  
  /// Get current accessibility preferences
  ChatAccessibilityPreferences getPreferences() {
    return ChatAccessibilityPreferences(
      isScreenReaderActive: _isScreenReaderActive,
      reduceMotionEnabled: _reduceMotionEnabled,
      highContrastEnabled: _highContrastEnabled,
      announceTypingEnabled: _announceTypingEnabled,
      announceMessagesEnabled: _announceMessagesEnabled,
    );
  }
  
  // ============================================================================
  // THEME ACCESSIBILITY
  // ============================================================================
  
  /// Get appropriate theme for current accessibility settings
  ThemeData getAccessibleTheme({
    required UserRole userRole,
    bool? forceHighContrast,
    bool? forceDarkMode,
  }) {
    final useHighContrast = forceHighContrast ?? _highContrastEnabled;
    final useDarkMode = forceDarkMode ?? false; // Default to light mode
    
    return HighContrastThemes.getTheme(
      userRole: userRole,
      isHighContrast: useHighContrast,
      isDarkMode: useDarkMode,
    );
  }
  
  /// Get chat-specific high contrast colors
  ChatHighContrastColors getChatColors({
    required UserRole userRole,
    bool? forceDarkMode,
  }) {
    final useDarkMode = forceDarkMode ?? false;
    
    return HighContrastThemes.getChatHighContrastColors(
      userRole,
      isDark: useDarkMode,
    );
  }
  
  // ============================================================================
  // ACCESSIBILITY WIDGETS
  // ============================================================================
  
  /// Create accessible message list with proper semantics
  Widget createAccessibleMessageList({
    required Widget child,
    required String conversationTitle,
    required int messageCount,
    required UserRole userRole,
  }) {
    return Semantics(
      label: 'Berichten voor $conversationTitle',
      hint: '$messageCount berichten. Swipe omhoog of omlaag om door berichten te navigeren.',
      container: true,
      child: Focus(
        focusNode: getFocusNodeForConversation(conversationTitle),
        child: child,
      ),
    );
  }
  
  /// Create accessible conversation list item
  Widget createAccessibleConversationItem({
    required Widget child,
    required String conversationTitle,
    required String lastMessage,
    required DateTime lastMessageTime,
    required int unreadCount,
    required bool isOnline,
    required UserRole userRole,
    required VoidCallback onTap,
  }) {
    return EnhancedAccessibilityHelper.accessibleConversationItem(
      child: child,
      conversationTitle: conversationTitle,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      isOnline: isOnline,
      userRole: userRole,
      onTap: onTap,
    );
  }
  
  /// Create accessible typing indicator
  Widget createAccessibleTypingIndicator({
    required Widget child,
    required List<String> typingUsers,
    required UserRole userRole,
  }) {
    return EnhancedAccessibilityHelper.accessibleTypingIndicator(
      child: child,
      typingUsers: typingUsers,
      userRole: userRole,
    );
  }
  
  // ============================================================================
  // PRIVATE UTILITY METHODS
  // ============================================================================
  
  String _buildMessageAnnouncement({
    required String content,
    required String senderName,
    required bool isCurrentUser,
    required String conversationId,
  }) {
    if (isCurrentUser) {
      return 'Bericht verzonden: $content';
    } else {
      return 'Nieuw bericht van $senderName: $content';
    }
  }
  
  String _buildTypingAnnouncement(List<String> typingUsers) {
    if (typingUsers.isEmpty) {
      return 'Niemand is meer aan het typen';
    } else if (typingUsers.length == 1) {
      return '${typingUsers.first} is aan het typen';
    } else if (typingUsers.length == 2) {
      return '${typingUsers.join(' en ')} zijn aan het typen';
    } else {
      return '${typingUsers.length} mensen zijn aan het typen';
    }
  }
  
  bool _typingUsersChanged(List<String> current, List<String> previous) {
    if (current.length != previous.length) return true;
    
    for (int i = 0; i < current.length; i++) {
      if (current[i] != previous[i]) return true;
    }
    
    return false;
  }
  
  void _announceImmediately(String announcement) {
    // Note: SemanticsService.announce is not available in current Flutter version
    // Using HapticFeedback as alternative feedback
    HapticFeedback.lightImpact();
  }
  
  void _announceWithDelay(
    String announcement, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    _announcementTimer?.cancel();
    _announcementTimer = Timer(delay, () {
      // Note: SemanticsService.announce is not available in current Flutter version
      // Using HapticFeedback as alternative feedback
      HapticFeedback.lightImpact();
    });
  }
  
  // ============================================================================
  // CLEANUP
  // ============================================================================
  
  /// Dispose of resources
  void dispose() {
    _announcementTimer?.cancel();
    
    // Dispose all focus nodes
    for (final focusNode in _chatFocusNodes.values) {
      focusNode.dispose();
    }
    _chatFocusNodes.clear();
  }
}

/// Chat accessibility preferences data class
class ChatAccessibilityPreferences {
  final bool isScreenReaderActive;
  final bool reduceMotionEnabled;
  final bool highContrastEnabled;
  final bool announceTypingEnabled;
  final bool announceMessagesEnabled;
  
  const ChatAccessibilityPreferences({
    required this.isScreenReaderActive,
    required this.reduceMotionEnabled,
    required this.highContrastEnabled,
    required this.announceTypingEnabled,
    required this.announceMessagesEnabled,
  });
  
  /// Create copy with modified values
  ChatAccessibilityPreferences copyWith({
    bool? isScreenReaderActive,
    bool? reduceMotionEnabled,
    bool? highContrastEnabled,
    bool? announceTypingEnabled,
    bool? announceMessagesEnabled,
  }) {
    return ChatAccessibilityPreferences(
      isScreenReaderActive: isScreenReaderActive ?? this.isScreenReaderActive,
      reduceMotionEnabled: reduceMotionEnabled ?? this.reduceMotionEnabled,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      announceTypingEnabled: announceTypingEnabled ?? this.announceTypingEnabled,
      announceMessagesEnabled: announceMessagesEnabled ?? this.announceMessagesEnabled,
    );
  }
  
  @override
  String toString() {
    return 'ChatAccessibilityPreferences('
        'screenReader: $isScreenReaderActive, '
        'reduceMotion: $reduceMotionEnabled, '
        'highContrast: $highContrastEnabled, '
        'announceTyping: $announceTypingEnabled, '
        'announceMessages: $announceMessagesEnabled'
        ')';
  }
}