import 'package:cloud_firestore/cloud_firestore.dart';

/// Real-time typing status model for WhatsApp-quality typing indicators
class TypingStatusModel {
  final String userId;
  final String userName;
  final String conversationId;
  final bool isTyping;
  final DateTime timestamp;

  const TypingStatusModel({
    required this.userId,
    required this.userName,
    required this.conversationId,
    required this.isTyping,
    required this.timestamp,
  });

  /// Check if typing status is still valid (within 10 seconds)
  bool get isValid {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inSeconds <= 10;
  }

  /// Get Dutch typing indicator text
  String getTypingText() {
    if (!isTyping || !isValid) return '';
    return '$userName is aan het typen...';
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'conversationId': conversationId,
      'isTyping': isTyping,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory TypingStatusModel.fromMap(Map<String, dynamic> map) {
    return TypingStatusModel(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      conversationId: map['conversationId'] ?? '',
      isTyping: map['isTyping'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  TypingStatusModel copyWith({
    String? userId,
    String? userName,
    String? conversationId,
    bool? isTyping,
    DateTime? timestamp,
  }) {
    return TypingStatusModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      conversationId: conversationId ?? this.conversationId,
      isTyping: isTyping ?? this.isTyping,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TypingStatusModel &&
        other.userId == userId &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    return userId.hashCode ^ conversationId.hashCode;
  }
}

/// User presence model for online/offline status
class UserPresenceModel {
  final String userId;
  final bool isOnline;
  final DateTime lastSeen;
  final String? deviceInfo;

  const UserPresenceModel({
    required this.userId,
    required this.isOnline,
    required this.lastSeen,
    this.deviceInfo,
  });

  /// Get Dutch last seen text
  String getLastSeenText() {
    if (isOnline) return 'Online';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Zojuist online';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minuten geleden online';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} uur geleden online';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dagen geleden online';
    } else {
      return 'Lang geleden online';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'deviceInfo': deviceInfo,
    };
  }

  factory UserPresenceModel.fromMap(Map<String, dynamic> map) {
    return UserPresenceModel(
      userId: map['userId'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp).toDate(),
      deviceInfo: map['deviceInfo'],
    );
  }

  UserPresenceModel copyWith({
    String? userId,
    bool? isOnline,
    DateTime? lastSeen,
    String? deviceInfo,
  }) {
    return UserPresenceModel(
      userId: userId ?? this.userId,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPresenceModel && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
