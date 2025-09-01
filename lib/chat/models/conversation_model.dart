import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart';

/// Conversation types in SecuryFlex
enum ConversationType {
  assignment,  // Chat related to a specific job assignment
  direct,      // Direct chat between users
  group,       // Group chat (future feature)
}

/// Participant details in a conversation
class ParticipantDetails {
  final String userId;
  final String userName;
  final String userRole; // 'guard', 'company', 'admin'
  final String? avatarUrl;
  final DateTime joinedAt;
  final bool isActive;
  final DateTime? lastSeen;
  final bool isOnline;

  const ParticipantDetails({
    required this.userId,
    required this.userName,
    required this.userRole,
    this.avatarUrl,
    required this.joinedAt,
    this.isActive = true,
    this.lastSeen,
    this.isOnline = false,
  });

  /// Get Dutch display name for user role
  String getRoleDisplayName() {
    switch (userRole.toLowerCase()) {
      case 'guard':
        return 'Beveiliger';
      case 'company':
        return 'Bedrijf';
      case 'admin':
        return 'Beheerder';
      default:
        return 'Gebruiker';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'avatarUrl': avatarUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isOnline': isOnline,
    };
  }

  factory ParticipantDetails.fromMap(Map<String, dynamic> map) {
    return ParticipantDetails(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? '',
      avatarUrl: map['avatarUrl'],
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      lastSeen: map['lastSeen'] != null ? (map['lastSeen'] as Timestamp).toDate() : null,
      isOnline: map['isOnline'] ?? false,
    );
  }

  ParticipantDetails copyWith({
    String? userId,
    String? userName,
    String? userRole,
    String? avatarUrl,
    DateTime? joinedAt,
    bool? isActive,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return ParticipantDetails(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// Last message preview for conversation list
class LastMessagePreview {
  final String messageId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType messageType;
  final DateTime timestamp;
  final MessageDeliveryStatus deliveryStatus;

  const LastMessagePreview({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.messageType,
    required this.timestamp,
    required this.deliveryStatus,
  });

  /// Get display text for last message with Dutch labels
  String getDisplayText() {
    switch (messageType) {
      case MessageType.text:
        return content;
      case MessageType.image:
        return '📷 Afbeelding';
      case MessageType.file:
        return '📄 Document';
      case MessageType.voice:
        return '🎤 Spraakbericht';
      case MessageType.system:
        return content;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'messageType': messageType.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'deliveryStatus': deliveryStatus.name,
    };
  }

  factory LastMessagePreview.fromMap(Map<String, dynamic> map) {
    return LastMessagePreview(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      messageType: MessageType.values.firstWhere(
        (e) => e.name == map['messageType'],
        orElse: () => MessageType.text,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      deliveryStatus: MessageDeliveryStatus.values.firstWhere(
        (e) => e.name == map['deliveryStatus'],
        orElse: () => MessageDeliveryStatus.sent,
      ),
    );
  }
}

/// Enhanced conversation model with WhatsApp-quality features
class ConversationModel {
  final String conversationId;
  final String title;
  final ConversationType conversationType;
  final Map<String, ParticipantDetails> participants;
  final LastMessagePreview? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignmentId; // SecuryFlex specific - link to job assignment
  final String? assignmentTitle; // For display purposes
  final bool isArchived;
  final bool isMuted;
  final Map<String, int> unreadCounts; // Unread count per user
  final Map<String, bool> typingStatus; // Who is currently typing
  final String? groupAvatarUrl; // For group chats
  final Map<String, dynamic> metadata; // Additional data

  const ConversationModel({
    required this.conversationId,
    required this.title,
    this.conversationType = ConversationType.direct,
    this.participants = const {},
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.assignmentId,
    this.assignmentTitle,
    this.isArchived = false,
    this.isMuted = false,
    this.unreadCounts = const {},
    this.typingStatus = const {},
    this.groupAvatarUrl,
    this.metadata = const {},
  });

  /// Get unread count for specific user
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  /// Check if anyone is typing
  bool get hasTypingUsers {
    return typingStatus.values.any((isTyping) => isTyping);
  }

  /// Get list of users currently typing
  List<String> getTypingUsers() {
    return typingStatus.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get typing indicator text in Dutch
  String getTypingIndicatorText() {
    final typingUsers = getTypingUsers();
    if (typingUsers.isEmpty) return '';
    
    if (typingUsers.length == 1) {
      final user = participants[typingUsers.first];
      return '${user?.userName ?? 'Iemand'} is aan het typen...';
    } else {
      return '${typingUsers.length} personen zijn aan het typen...';
    }
  }

  /// Get conversation display title
  String getDisplayTitle(String currentUserId) {
    if (conversationType == ConversationType.assignment && assignmentTitle != null) {
      return assignmentTitle!;
    }
    
    if (title.isNotEmpty) {
      return title;
    }
    
    // For direct chats, show other participant's name
    final otherParticipants = participants.values
        .where((p) => p.userId != currentUserId && p.isActive)
        .toList();
    
    if (otherParticipants.isNotEmpty) {
      return otherParticipants.first.userName;
    }
    
    return 'Chat';
  }

  /// Get other participant for direct chats
  ParticipantDetails? getOtherParticipant(String currentUserId) {
    if (conversationType != ConversationType.direct) return null;
    
    return participants.values
        .firstWhere(
          (p) => p.userId != currentUserId && p.isActive,
          orElse: () => participants.values.first,
        );
  }

  /// Check if user is online
  bool isUserOnline(String userId) {
    return participants[userId]?.isOnline ?? false;
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'title': title,
      'conversationType': conversationType.name,
      'participants': participants.map((key, value) => MapEntry(key, value.toMap())),
      'lastMessage': lastMessage?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'assignmentId': assignmentId,
      'assignmentTitle': assignmentTitle,
      'isArchived': isArchived,
      'isMuted': isMuted,
      'unreadCounts': unreadCounts,
      'typingStatus': typingStatus,
      'groupAvatarUrl': groupAvatarUrl,
      'metadata': metadata,
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map, String conversationId) {
    return ConversationModel(
      conversationId: conversationId,
      title: map['title'] ?? '',
      conversationType: ConversationType.values.firstWhere(
        (e) => e.name == map['conversationType'],
        orElse: () => ConversationType.direct,
      ),
      participants: (map['participants'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, ParticipantDetails.fromMap(value))),
      lastMessage: map['lastMessage'] != null 
          ? LastMessagePreview.fromMap(map['lastMessage']) 
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      assignmentId: map['assignmentId'],
      assignmentTitle: map['assignmentTitle'],
      isArchived: map['isArchived'] ?? false,
      isMuted: map['isMuted'] ?? false,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      typingStatus: Map<String, bool>.from(map['typingStatus'] ?? {}),
      groupAvatarUrl: map['groupAvatarUrl'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  ConversationModel copyWith({
    String? conversationId,
    String? title,
    ConversationType? conversationType,
    Map<String, ParticipantDetails>? participants,
    LastMessagePreview? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignmentId,
    String? assignmentTitle,
    bool? isArchived,
    bool? isMuted,
    Map<String, int>? unreadCounts,
    Map<String, bool>? typingStatus,
    String? groupAvatarUrl,
    Map<String, dynamic>? metadata,
  }) {
    return ConversationModel(
      conversationId: conversationId ?? this.conversationId,
      title: title ?? this.title,
      conversationType: conversationType ?? this.conversationType,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignmentId: assignmentId ?? this.assignmentId,
      assignmentTitle: assignmentTitle ?? this.assignmentTitle,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      typingStatus: typingStatus ?? this.typingStatus,
      groupAvatarUrl: groupAvatarUrl ?? this.groupAvatarUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}
