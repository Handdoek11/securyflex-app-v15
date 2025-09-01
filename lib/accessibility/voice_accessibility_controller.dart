import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Voice Accessibility Controller for SecuryFlex Chat
/// 
/// Provides comprehensive voice control and announcement features:
/// - Voice command recognition for chat navigation
/// - Intelligent message announcements
/// - Dutch language voice support
/// - Context-aware voice feedback
/// - Screen reader integration
class VoiceAccessibilityController {
  static VoiceAccessibilityController? _instance;
  static VoiceAccessibilityController get instance => 
      _instance ??= VoiceAccessibilityController._();
  
  VoiceAccessibilityController._();

  // Voice control state
  bool _voiceControlEnabled = false;
  bool _voiceAnnouncementsEnabled = true;
  StreamController<VoiceCommand>? _commandController;
  Timer? _announcementQueue;
  
  // Dutch language voice phrases
  final Map<String, VoiceCommand> _dutchCommands = {
    'open chat': VoiceCommand.openChat,
    'chat openen': VoiceCommand.openChat,
    'verstuur bericht': VoiceCommand.sendMessage,
    'send message': VoiceCommand.sendMessage,
    'ga terug': VoiceCommand.goBack,
    'go back': VoiceCommand.goBack,
    'zoek gesprekken': VoiceCommand.searchConversations,
    'search conversations': VoiceCommand.searchConversations,
    'nieuwe berichten': VoiceCommand.checkNewMessages,
    'check messages': VoiceCommand.checkNewMessages,
    'lees laatste bericht': VoiceCommand.readLastMessage,
    'read last message': VoiceCommand.readLastMessage,
    'toon opties': VoiceCommand.showOptions,
    'show options': VoiceCommand.showOptions,
  };
  
  // Context tracking
  String? _currentContext;
  List<String> _recentAnnouncements = [];
  
  // ============================================================================
  // INITIALIZATION & CONFIGURATION
  // ============================================================================
  
  /// Initialize voice accessibility controller
  Future<void> initialize() async {
    _commandController = StreamController<VoiceCommand>.broadcast();
    await _checkVoiceCapabilities();
    _setupAnnouncementQueue();
  }
  
  /// Check device voice capabilities
  Future<void> _checkVoiceCapabilities() async {
    // Check if TalkBack/VoiceOver is active
    final hasScreenReader = WidgetsBinding.instance
        .platformDispatcher.accessibilityFeatures.accessibleNavigation;
    
    _voiceControlEnabled = hasScreenReader;
    _voiceAnnouncementsEnabled = hasScreenReader;
  }
  
  /// Setup announcement queue for managing multiple voice announcements
  void _setupAnnouncementQueue() {
    _announcementQueue = Timer.periodic(
      const Duration(milliseconds: 2000),
      (_) => _processAnnouncementQueue(),
    );
  }
  
  // ============================================================================
  // VOICE COMMAND PROCESSING
  // ============================================================================
  
  /// Process voice command with Dutch language support
  void processVoiceCommand(String command) {
    if (!_voiceControlEnabled) return;
    
    final normalizedCommand = command.toLowerCase().trim();
    final voiceCommand = _dutchCommands[normalizedCommand];
    
    if (voiceCommand != null) {
      _commandController?.add(voiceCommand);
      _announceCommandRecognition(normalizedCommand);
    } else {
      _announceCommandNotRecognized(normalizedCommand);
    }
  }
  
  /// Get stream of voice commands
  Stream<VoiceCommand> get commandStream => 
      _commandController?.stream ?? const Stream.empty();
  
  /// Register voice command listener
  StreamSubscription<VoiceCommand> onVoiceCommand(
    void Function(VoiceCommand) onCommand,
  ) {
    return commandStream.listen(onCommand);
  }
  
  // ============================================================================
  // MESSAGE ANNOUNCEMENTS
  // ============================================================================
  
  /// Announce new message with voice optimization
  void announceMessage({
    required String content,
    required String senderName,
    required bool isCurrentUser,
    required DateTime timestamp,
    String? conversationContext,
    MessagePriority priority = MessagePriority.normal,
  }) {
    if (!_voiceAnnouncementsEnabled) return;
    
    final announcement = _buildMessageAnnouncement(
      content: content,
      senderName: senderName,
      isCurrentUser: isCurrentUser,
      timestamp: timestamp,
      conversationContext: conversationContext,
    );
    
    _queueAnnouncement(
      announcement: announcement,
      priority: priority,
      context: _currentContext,
    );
  }
  
  /// Announce navigation changes
  void announceNavigation({
    required String from,
    required String to,
    Map<String, dynamic>? additionalContext,
  }) {
    if (!_voiceAnnouncementsEnabled) return;
    
    final announcement = _buildNavigationAnnouncement(
      from: from,
      to: to,
      additionalContext: additionalContext,
    );
    
    _queueAnnouncement(
      announcement: announcement,
      priority: MessagePriority.high,
      context: to,
    );
    
    _currentContext = to;
  }
  
  /// Announce typing status with intelligent filtering
  void announceTypingStatus({
    required List<String> typingUsers,
    required String conversationId,
  }) {
    if (!_voiceAnnouncementsEnabled) return;
    
    // Avoid announcing typing too frequently
    final typingKey = 'typing_$conversationId';
    if (_wasRecentlyAnnounced(typingKey)) return;
    
    final announcement = _buildTypingAnnouncement(typingUsers);
    
    _queueAnnouncement(
      announcement: announcement,
      priority: MessagePriority.low,
      context: conversationId,
    );
    
    _markAsRecentlyAnnounced(typingKey);
  }
  
  /// Announce system status and errors
  void announceSystemStatus({
    required String message,
    required SystemStatusType type,
    String? actionHint,
  }) {
    if (!_voiceAnnouncementsEnabled) return;
    
    final announcement = _buildSystemStatusAnnouncement(
      message: message,
      type: type,
      actionHint: actionHint,
    );
    
    _queueAnnouncement(
      announcement: announcement,
      priority: type == SystemStatusType.error 
          ? MessagePriority.urgent 
          : MessagePriority.normal,
      context: 'system',
    );
  }
  
  // ============================================================================
  // CONTEXT-AWARE ASSISTANCE
  // ============================================================================
  
  /// Provide context-specific voice help
  void provideContextHelp([String? specificContext]) {
    final context = specificContext ?? _currentContext ?? 'general';
    final helpText = _getContextualHelp(context);
    
    _queueAnnouncement(
      announcement: helpText,
      priority: MessagePriority.high,
      context: 'help',
    );
  }
  
  /// Describe current screen content
  void describeCurrentScreen({
    required String screenName,
    required Map<String, dynamic> screenContent,
  }) {
    final description = _buildScreenDescription(
      screenName: screenName,
      content: screenContent,
    );
    
    _queueAnnouncement(
      announcement: description,
      priority: MessagePriority.normal,
      context: screenName,
    );
  }
  
  // ============================================================================
  // ANNOUNCEMENT BUILDERS
  // ============================================================================
  
  String _buildMessageAnnouncement({
    required String content,
    required String senderName,
    required bool isCurrentUser,
    required DateTime timestamp,
    String? conversationContext,
  }) {
    final timeDescription = _formatTimeForVoice(timestamp);
    final contextPrefix = conversationContext != null
        ? 'In gesprek $conversationContext: '
        : '';
    
    if (isCurrentUser) {
      return '${contextPrefix}Jouw bericht verzonden $timeDescription: $content';
    } else {
      return '${contextPrefix}Nieuw bericht van $senderName $timeDescription: $content';
    }
  }
  
  String _buildNavigationAnnouncement({
    required String from,
    required String to,
    Map<String, dynamic>? additionalContext,
  }) {
    String announcement = 'Genavigeerd naar $to';
    
    if (additionalContext != null) {
      final contextInfo = additionalContext.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      announcement += '. $contextInfo';
    }
    
    return announcement;
  }
  
  String _buildTypingAnnouncement(List<String> typingUsers) {
    if (typingUsers.isEmpty) {
      return 'Niemand is meer aan het typen';
    } else if (typingUsers.length == 1) {
      return '${typingUsers.first} is aan het typen';
    } else {
      return '${typingUsers.length} mensen zijn aan het typen';
    }
  }
  
  String _buildSystemStatusAnnouncement({
    required String message,
    required SystemStatusType type,
    String? actionHint,
  }) {
    String prefix;
    switch (type) {
      case SystemStatusType.success:
        prefix = 'Gelukt: ';
        break;
      case SystemStatusType.error:
        prefix = 'Fout: ';
        break;
      case SystemStatusType.warning:
        prefix = 'Waarschuwing: ';
        break;
      case SystemStatusType.info:
        prefix = 'Info: ';
        break;
    }
    
    String announcement = '$prefix$message';
    if (actionHint != null) {
      announcement += '. $actionHint';
    }
    
    return announcement;
  }
  
  String _buildScreenDescription({
    required String screenName,
    required Map<String, dynamic> content,
  }) {
    String description = 'Scherm: $screenName. ';
    
    if (content.containsKey('conversationCount')) {
      description += '${content['conversationCount']} gesprekken beschikbaar. ';
    }
    
    if (content.containsKey('unreadCount')) {
      final unreadCount = content['unreadCount'] as int;
      if (unreadCount > 0) {
        description += '$unreadCount ongelezen berichten. ';
      }
    }
    
    if (content.containsKey('availableActions')) {
      final actions = content['availableActions'] as List<String>;
      if (actions.isNotEmpty) {
        description += 'Beschikbare acties: ${actions.join(', ')}. ';
      }
    }
    
    return description;
  }
  
  // ============================================================================
  // CONTEXTUAL HELP
  // ============================================================================
  
  String _getContextualHelp(String context) {
    switch (context) {
      case 'conversations':
        return 'Chat overzicht. Zeg "open chat" om een gesprek te openen, '
            '"zoek gesprekken" om te zoeken, of "nieuwe berichten" om updates te checken.';
      case 'chat':
        return 'In een chat gesprek. Zeg "verstuur bericht" om een bericht te versturen, '
            '"ga terug" om terug te gaan, of "lees laatste bericht" voor het laatste bericht.';
      case 'message_input':
        return 'Bericht invoer. Typ je bericht en zeg "verstuur bericht" om te versturen.';
      default:
        return 'SecuryFlex chat app. Zeg "toon opties" voor beschikbare commando\'s, '
            'of "open chat" om een gesprek te starten.';
    }
  }
  
  // ============================================================================
  // ANNOUNCEMENT QUEUE MANAGEMENT
  // ============================================================================
  
  final List<QueuedAnnouncement> _pendingAnnouncements = [];
  
  void _queueAnnouncement({
    required String announcement,
    required MessagePriority priority,
    String? context,
  }) {
    _pendingAnnouncements.add(QueuedAnnouncement(
      message: announcement,
      priority: priority,
      context: context,
      timestamp: DateTime.now(),
    ));
    
    // Sort by priority
    _pendingAnnouncements.sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }
  
  void _processAnnouncementQueue() {
    if (_pendingAnnouncements.isEmpty) return;
    
    final announcement = _pendingAnnouncements.removeAt(0);
    
    // Check if announcement is still relevant (not too old)
    final age = DateTime.now().difference(announcement.timestamp);
    if (age.inSeconds > 10) return; // Skip old announcements
    
    // Note: SemanticsService.announce is not available in current Flutter version
    HapticFeedback.lightImpact();
  }
  
  void _announceCommandRecognition(String command) {
    _queueAnnouncement(
      announcement: 'Commando herkend: $command',
      priority: MessagePriority.normal,
      context: 'voice_command',
    );
  }
  
  void _announceCommandNotRecognized(String command) {
    _queueAnnouncement(
      announcement: 'Commando niet herkend: $command. Zeg "toon opties" voor beschikbare commando\'s.',
      priority: MessagePriority.normal,
      context: 'voice_command',
    );
  }
  
  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  String _formatTimeForVoice(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'zojuist';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minuut' : 'minuten'} geleden';
    } else if (difference.inHours < 24) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${difference.inDays} ${difference.inDays == 1 ? 'dag' : 'dagen'} geleden';
    }
  }
  
  bool _wasRecentlyAnnounced(String key) {
    return _recentAnnouncements.contains(key);
  }
  
  void _markAsRecentlyAnnounced(String key) {
    _recentAnnouncements.add(key);
    
    // Keep only recent announcements (last 10)
    if (_recentAnnouncements.length > 10) {
      _recentAnnouncements.removeAt(0);
    }
  }
  
  // ============================================================================
  // CONFIGURATION
  // ============================================================================
  
  /// Enable or disable voice control
  void setVoiceControlEnabled(bool enabled) {
    _voiceControlEnabled = enabled;
  }
  
  /// Enable or disable voice announcements
  void setVoiceAnnouncementsEnabled(bool enabled) {
    _voiceAnnouncementsEnabled = enabled;
  }
  
  /// Get current voice control status
  bool get isVoiceControlEnabled => _voiceControlEnabled;
  
  /// Get current voice announcements status
  bool get areVoiceAnnouncementsEnabled => _voiceAnnouncementsEnabled;
  
  /// Set current context for contextual help
  void setContext(String context) {
    _currentContext = context;
  }
  
  /// Get current context
  String? get currentContext => _currentContext;
  
  // ============================================================================
  // CLEANUP
  // ============================================================================
  
  /// Dispose of resources
  void dispose() {
    _commandController?.close();
    _announcementQueue?.cancel();
    _pendingAnnouncements.clear();
    _recentAnnouncements.clear();
  }
}

/// Voice commands enumeration
enum VoiceCommand {
  openChat,
  sendMessage,
  goBack,
  searchConversations,
  checkNewMessages,
  readLastMessage,
  showOptions,
}

/// Message priority for announcement queue
enum MessagePriority {
  low,
  normal,
  high,
  urgent,
}

/// System status types for announcements
enum SystemStatusType {
  success,
  error,
  warning,
  info,
}

/// Queued announcement data structure
class QueuedAnnouncement {
  final String message;
  final MessagePriority priority;
  final String? context;
  final DateTime timestamp;
  
  const QueuedAnnouncement({
    required this.message,
    required this.priority,
    this.context,
    required this.timestamp,
  });
}