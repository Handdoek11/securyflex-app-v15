import 'package:cloud_firestore/cloud_firestore.dart';

/// WhatsApp-quality message delivery status
enum MessageDeliveryStatus {
  sending,    // Message being sent (no tick)
  sent,       // Message sent to server (single tick ✓)
  delivered,  // Message delivered to recipient (double tick ✓✓)
  read,       // Message read by recipient (blue tick)
  failed,     // Message failed to send
}

/// Message types supported in SecuryFlex chat
enum MessageType {
  text,       // Regular text message
  image,      // Image attachment
  file,       // Document/file attachment
  voice,      // Voice message
  system,     // System messages (assignment updates, etc.)
}

/// Individual message delivery status per user
class UserDeliveryStatus {
  final String userId;
  final MessageDeliveryStatus status;
  final DateTime timestamp;

  const UserDeliveryStatus({
    required this.userId,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory UserDeliveryStatus.fromMap(Map<String, dynamic> map) {
    return UserDeliveryStatus(
      userId: map['userId'] ?? '',
      status: MessageDeliveryStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageDeliveryStatus.sent,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

/// File attachment data for messages
class MessageAttachment {
  final String fileName;
  final String fileUrl;
  final String? thumbnailUrl;
  final int fileSize;
  final String mimeType;

  const MessageAttachment({
    required this.fileName,
    required this.fileUrl,
    this.thumbnailUrl,
    required this.fileSize,
    required this.mimeType,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileSize': fileSize,
      'mimeType': mimeType,
    };
  }

  factory MessageAttachment.fromMap(Map<String, dynamic> map) {
    return MessageAttachment(
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      fileSize: map['fileSize'] ?? 0,
      mimeType: map['mimeType'] ?? '',
    );
  }
}

/// Reply reference for message threading
class MessageReply {
  final String messageId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType messageType;

  const MessageReply({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.messageType,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'messageType': messageType.name,
    };
  }

  factory MessageReply.fromMap(Map<String, dynamic> map) {
    return MessageReply(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      messageType: MessageType.values.firstWhere(
        (e) => e.name == map['messageType'],
        orElse: () => MessageType.text,
      ),
    );
  }
}

/// Enhanced message model with WhatsApp-quality features
class MessageModel {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType messageType;
  final DateTime timestamp;
  final DateTime? editedAt;
  final bool isEdited;
  final MessageAttachment? attachment;
  final MessageReply? replyTo;
  final Map<String, UserDeliveryStatus> deliveryStatus;
  final Map<String, DateTime> readStatus;
  final List<String> reactions;
  final bool isDeleted;

  const MessageModel({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.messageType = MessageType.text,
    required this.timestamp,
    this.editedAt,
    this.isEdited = false,
    this.attachment,
    this.replyTo,
    this.deliveryStatus = const {},
    this.readStatus = const {},
    this.reactions = const [],
    this.isDeleted = false,
  });

  /// Get overall delivery status for the message
  MessageDeliveryStatus getOverallDeliveryStatus() {
    if (deliveryStatus.isEmpty) return MessageDeliveryStatus.sending;
    
    final statuses = deliveryStatus.values.map((e) => e.status).toList();
    
    if (statuses.any((s) => s == MessageDeliveryStatus.read)) {
      return MessageDeliveryStatus.read;
    } else if (statuses.every((s) => s == MessageDeliveryStatus.delivered || s == MessageDeliveryStatus.read)) {
      return MessageDeliveryStatus.delivered;
    } else if (statuses.any((s) => s == MessageDeliveryStatus.sent || s == MessageDeliveryStatus.delivered)) {
      return MessageDeliveryStatus.sent;
    } else {
      return MessageDeliveryStatus.sending;
    }
  }

  /// Check if message is read by specific user
  bool isReadByUser(String userId) {
    return readStatus.containsKey(userId);
  }

  /// Get Dutch display text for message type
  String getTypeDisplayText() {
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
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'messageType': messageType.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isEdited': isEdited,
      'attachment': attachment?.toMap(),
      'replyTo': replyTo?.toMap(),
      'deliveryStatus': deliveryStatus.map((key, value) => MapEntry(key, value.toMap())),
      'readStatus': readStatus.map((key, value) => MapEntry(key, Timestamp.fromDate(value))),
      'reactions': reactions,
      'isDeleted': isDeleted,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String messageId) {
    return MessageModel(
      messageId: messageId,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      messageType: MessageType.values.firstWhere(
        (e) => e.name == map['messageType'],
        orElse: () => MessageType.text,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      editedAt: map['editedAt'] != null ? (map['editedAt'] as Timestamp).toDate() : null,
      isEdited: map['isEdited'] ?? false,
      attachment: map['attachment'] != null ? MessageAttachment.fromMap(map['attachment']) : null,
      replyTo: map['replyTo'] != null ? MessageReply.fromMap(map['replyTo']) : null,
      deliveryStatus: (map['deliveryStatus'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, UserDeliveryStatus.fromMap(value))),
      readStatus: (map['readStatus'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as Timestamp).toDate())),
      reactions: List<String>.from(map['reactions'] ?? []),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  MessageModel copyWith({
    String? messageId,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? messageType,
    DateTime? timestamp,
    DateTime? editedAt,
    bool? isEdited,
    MessageAttachment? attachment,
    MessageReply? replyTo,
    Map<String, UserDeliveryStatus>? deliveryStatus,
    Map<String, DateTime>? readStatus,
    List<String>? reactions,
    bool? isDeleted,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      editedAt: editedAt ?? this.editedAt,
      isEdited: isEdited ?? this.isEdited,
      attachment: attachment ?? this.attachment,
      replyTo: replyTo ?? this.replyTo,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      readStatus: readStatus ?? this.readStatus,
      reactions: reactions ?? this.reactions,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
