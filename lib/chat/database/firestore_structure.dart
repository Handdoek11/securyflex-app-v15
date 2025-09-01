/// Firestore Database Structure for SecuryFlex Chat System
/// 
/// This file documents the WhatsApp-quality database structure
/// designed for optimal performance, real-time updates, and scalability.
library;

class FirestoreCollections {
  // Root collections
  static const String conversations = 'conversations';
  static const String users = 'users';
  static const String assignments = 'assignments';
  
  // Subcollections
  static const String messages = 'messages';
  static const String typing = 'typing';
  static const String presence = 'presence';
  
  // Indexes needed for optimal performance
  static const List<String> requiredIndexes = [
    'conversations: participants (array), updatedAt (desc)',
    'messages: conversationId (asc), timestamp (desc)',
    'messages: senderId (asc), timestamp (desc)',
    'typing: conversationId (asc), timestamp (desc)',
    'users: isOnline (asc), lastSeen (desc)',
  ];
}

/// Database structure documentation
/// 
/// /conversations/{conversationId}
/// ├── conversationId: String
/// ├── title: String
/// ├── conversationType: String ('assignment', 'direct', 'group')
/// ├── participants: Map&lt;String, ParticipantData&gt;
/// │   ├── {userId}: {
/// │   │   ├── userId: String
/// │   │   ├── userName: String
/// │   │   ├── userRole: String ('guard', 'company', 'admin')
/// │   │   ├── avatarUrl: String?
/// │   │   ├── joinedAt: Timestamp
/// │   │   ├── isActive: Boolean
/// │   │   ├── lastSeen: Timestamp?
/// │   │   └── isOnline: Boolean
/// │   │   }
/// ├── lastMessage: {
/// │   ├── messageId: String
/// │   ├── senderId: String
/// │   ├── senderName: String
/// │   ├── content: String
/// │   ├── messageType: String
/// │   ├── timestamp: Timestamp
/// │   └── deliveryStatus: String
/// │   }
/// ├── createdAt: Timestamp
/// ├── updatedAt: Timestamp
/// ├── assignmentId: String? (SecuryFlex specific)
/// ├── assignmentTitle: String? (for display)
/// ├── isArchived: Boolean
/// ├── isMuted: Boolean
/// ├── unreadCounts: Map&lt;String, Number&gt;
/// ├── typingStatus: Map&lt;String, Boolean&gt;
/// ├── groupAvatarUrl: String? (for group chats)
/// └── metadata: Map&lt;String, Any&gt;
/// 
/// /conversations/{conversationId}/messages/{messageId}
/// ├── messageId: String
/// ├── conversationId: String
/// ├── senderId: String
/// ├── senderName: String
/// ├── content: String
/// ├── messageType: String ('text', 'image', 'file', 'voice', 'system')
/// ├── timestamp: Timestamp
/// ├── editedAt: Timestamp?
/// ├── isEdited: Boolean
/// ├── attachment: {
/// │   ├── fileName: String
/// │   ├── fileUrl: String
/// │   ├── thumbnailUrl: String?
/// │   ├── fileSize: Number
/// │   └── mimeType: String
/// │   }?
/// ├── replyTo: {
/// │   ├── messageId: String
/// │   ├── senderId: String
/// │   ├── senderName: String
/// │   ├── content: String
/// │   └── messageType: String
/// │   }?
/// ├── deliveryStatus: Map<String, {
/// │   ├── userId: String
/// │   ├── status: String ('sending', 'sent', 'delivered', 'read', 'failed')
/// │   └── timestamp: Timestamp
/// │   }>
/// ├── readStatus: Map&lt;String, Timestamp&gt;
/// ├── reactions: Array&lt;String&gt;
/// └── isDeleted: Boolean
/// 
/// /conversations/{conversationId}/typing/{userId}
/// ├── userId: String
/// ├── userName: String
/// ├── conversationId: String
/// ├── isTyping: Boolean
/// └── timestamp: Timestamp (TTL: 10 seconds)
/// 
/// /users/{userId}
/// ├── userId: String
/// ├── userName: String
/// ├── userRole: String
/// ├── email: String
/// ├── avatarUrl: String?
/// ├── fcmTokens: Array&lt;String&gt;
/// ├── isOnline: Boolean
/// ├── lastSeen: Timestamp
/// ├── preferences: {
/// │   ├── notifications: Boolean
/// │   ├── readReceipts: Boolean
/// │   ├── typingIndicators: Boolean
/// │   └── language: String ('nl')
/// │   }
/// └── metadata: Map&lt;String, Any&gt;
/// 
/// /assignments/{assignmentId}
/// ├── assignmentId: String
/// ├── jobId: String
/// ├── companyId: String
/// ├── guardId: String
/// ├── title: String
/// ├── status: String
/// ├── conversationId: String? (auto-created when assignment accepted)
/// ├── createdAt: Timestamp
/// └── updatedAt: Timestamp

class FirestoreQueries {
  /// Common query patterns for optimal performance
  
  // Get conversations for a user (ordered by last activity)
  static String getUserConversations(String userId) {
    return '''
    conversations
      .where('participants.$userId.isActive', '==', true)
      .where('isArchived', '==', false)
      .orderBy('updatedAt', 'desc')
      .limit(50)
    ''';
  }
  
  // Get messages for a conversation (paginated)
  static String getConversationMessages(String conversationId, {int limit = 20}) {
    return '''
    conversations/$conversationId/messages
      .orderBy('timestamp', 'desc')
      .limit($limit)
    ''';
  }
  
  // Get typing status for a conversation
  static String getTypingStatus(String conversationId) {
    return '''
    conversations/$conversationId/typing
      .where('isTyping', '==', true)
      .where('timestamp', '>', now - 10 seconds)
    ''';
  }
  
  // Get unread messages count
  static String getUnreadMessages(String conversationId, String userId, DateTime lastReadTime) {
    return '''
    conversations/$conversationId/messages
      .where('timestamp', '>', lastReadTime)
      .where('senderId', '!=', userId)
      .count()
    ''';
  }
}

class FirestoreIndexes {
  /// Required composite indexes for optimal query performance
  
  static const List<Map<String, dynamic>> requiredIndexes = [
    {
      'collection': 'conversations',
      'fields': [
        {'field': 'participants.{userId}.isActive', 'order': 'asc'},
        {'field': 'isArchived', 'order': 'asc'},
        {'field': 'updatedAt', 'order': 'desc'},
      ],
    },
    {
      'collection': 'conversations/{conversationId}/messages',
      'fields': [
        {'field': 'conversationId', 'order': 'asc'},
        {'field': 'timestamp', 'order': 'desc'},
      ],
    },
    {
      'collection': 'conversations/{conversationId}/messages',
      'fields': [
        {'field': 'senderId', 'order': 'asc'},
        {'field': 'timestamp', 'order': 'desc'},
      ],
    },
    {
      'collection': 'conversations/{conversationId}/typing',
      'fields': [
        {'field': 'conversationId', 'order': 'asc'},
        {'field': 'isTyping', 'order': 'asc'},
        {'field': 'timestamp', 'order': 'desc'},
      ],
    },
    {
      'collection': 'users',
      'fields': [
        {'field': 'isOnline', 'order': 'asc'},
        {'field': 'lastSeen', 'order': 'desc'},
      ],
    },
  ];
}

class FirestoreTTL {
  /// Time-to-live configurations for automatic cleanup
  
  // Typing status expires after 10 seconds
  static const int typingStatusTTL = 10;
  
  // Old messages can be archived after 1 year
  static const int messageArchiveTTL = 365 * 24 * 60 * 60; // 1 year in seconds
  
  // Deleted messages are permanently removed after 30 days
  static const int deletedMessageTTL = 30 * 24 * 60 * 60; // 30 days in seconds
  
  // User presence updates expire after 5 minutes
  static const int presenceUpdateTTL = 5 * 60; // 5 minutes in seconds
}

class FirestoreOptimizations {
  /// Performance optimization strategies
  
  static const List<String> optimizationTips = [
    '1. Use subcollections for messages to avoid document size limits',
    '2. Implement message pagination with cursor-based queries',
    '3. Cache conversation list locally for offline support',
    '4. Use Firestore listeners only for active conversations',
    '5. Implement typing indicator cleanup with TTL',
    '6. Batch write operations for better performance',
    '7. Use compound queries with proper indexing',
    '8. Implement message delivery confirmation system',
    '9. Cache user presence data to reduce reads',
    '10. Use Firebase Storage for file attachments',
  ];
}
