import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Service for generating realistic mockup chat data for testing
/// This helps demonstrate the new dashboard-style chat layout
class ChatMockupService {
  static const String _currentUserId = 'guard';
  static const String _currentUserName = 'Jan de Beveiliger';

  /// Generate realistic conversation mockup data
  static List<ConversationModel> generateMockConversations() {
    final now = DateTime.now();
    
    return [
      // Recent active conversation with unread messages
      ConversationModel(
        conversationId: 'conv_001',
        title: 'Winkelcentrum Beveiliging',
        conversationType: ConversationType.assignment,
        participants: {
          _currentUserId: ParticipantDetails(
            userId: _currentUserId,
            userName: _currentUserName,
            userRole: 'guard',
            joinedAt: now.subtract(Duration(days: 2)),
            isOnline: true,
          ),
          'company_001': ParticipantDetails(
            userId: 'company_001',
            userName: 'SecureMax B.V.',
            userRole: 'company',
            joinedAt: now.subtract(Duration(days: 2)),
            isOnline: false,
            lastSeen: now.subtract(Duration(minutes: 15)),
          ),
        },
        lastMessage: LastMessagePreview(
          messageId: 'msg_latest_001',
          senderId: 'company_001',
          senderName: 'SecureMax B.V.',
          content: 'Dienst begint om 22:00. Locatie: hoofdingang winkelcentrum.',
          messageType: MessageType.text,
          timestamp: now.subtract(Duration(minutes: 5)),
          deliveryStatus: MessageDeliveryStatus.delivered,
        ),
        createdAt: now.subtract(Duration(days: 2)),
        updatedAt: now.subtract(Duration(minutes: 5)),
        assignmentId: 'assignment_001',
        assignmentTitle: 'Nachtdienst Winkelcentrum',
        unreadCounts: {_currentUserId: 2},
      ),

      // Assignment conversation with recent activity
      ConversationModel(
        conversationId: 'conv_002',
        title: 'Ziggo Dome Concert',
        conversationType: ConversationType.assignment,
        participants: {
          _currentUserId: ParticipantDetails(
            userId: _currentUserId,
            userName: _currentUserName,
            userRole: 'guard',
            joinedAt: now.subtract(Duration(days: 1)),
            isOnline: true,
          ),
          'company_002': ParticipantDetails(
            userId: 'company_002',
            userName: 'EventSafe Nederland',
            userRole: 'company',
            joinedAt: now.subtract(Duration(days: 1)),
            isOnline: true,
          ),
        },
        lastMessage: LastMessagePreview(
          messageId: 'msg_latest_002',
          senderId: _currentUserId,
          senderName: _currentUserName,
          content: 'Ben aangekomen bij de locatie. Alles in orde.',
          messageType: MessageType.text,
          timestamp: now.subtract(Duration(hours: 1)),
          deliveryStatus: MessageDeliveryStatus.read,
        ),
        createdAt: now.subtract(Duration(days: 1)),
        updatedAt: now.subtract(Duration(hours: 1)),
        assignmentId: 'assignment_002',
        assignmentTitle: 'Concert Beveiliging',
        unreadCounts: {},
      ),

      // Direct conversation with colleague
      ConversationModel(
        conversationId: 'conv_003',
        title: 'Piet van der Berg',
        conversationType: ConversationType.direct,
        participants: {
          _currentUserId: ParticipantDetails(
            userId: _currentUserId,
            userName: _currentUserName,
            userRole: 'guard',
            joinedAt: now.subtract(Duration(days: 5)),
            isOnline: true,
          ),
          'guard_002': ParticipantDetails(
            userId: 'guard_002',
            userName: 'Piet van der Berg',
            userRole: 'guard',
            joinedAt: now.subtract(Duration(days: 5)),
            isOnline: false,
            lastSeen: now.subtract(Duration(hours: 3)),
          ),
        },
        lastMessage: LastMessagePreview(
          messageId: 'msg_latest_003',
          senderId: 'guard_002',
          senderName: 'Piet van der Berg',
          content: 'Heb je die nieuwe planning al gezien? Volgende week hebben we samen dienst.',
          messageType: MessageType.text,
          timestamp: now.subtract(Duration(hours: 3)),
          deliveryStatus: MessageDeliveryStatus.delivered,
        ),
        createdAt: now.subtract(Duration(days: 5)),
        updatedAt: now.subtract(Duration(hours: 3)),
        unreadCounts: {_currentUserId: 1},
      ),

      // Older conversation with file attachment
      ConversationModel(
        conversationId: 'conv_004',
        title: 'ABN AMRO Kantoorbeveiliging',
        conversationType: ConversationType.assignment,
        participants: {
          _currentUserId: ParticipantDetails(
            userId: _currentUserId,
            userName: _currentUserName,
            userRole: 'guard',
            joinedAt: now.subtract(Duration(days: 7)),
            isOnline: true,
          ),
          'company_003': ParticipantDetails(
            userId: 'company_003',
            userName: 'ABN AMRO Facilities',
            userRole: 'company',
            joinedAt: now.subtract(Duration(days: 7)),
            isOnline: false,
            lastSeen: now.subtract(Duration(days: 1)),
          ),
        },
        lastMessage: LastMessagePreview(
          messageId: 'msg_latest_004',
          senderId: 'company_003',
          senderName: 'ABN AMRO Facilities',
          content: '📄 Nieuwe veiligheidsprotocollen.pdf',
          messageType: MessageType.file,
          timestamp: now.subtract(Duration(days: 1)),
          deliveryStatus: MessageDeliveryStatus.read,
        ),
        createdAt: now.subtract(Duration(days: 7)),
        updatedAt: now.subtract(Duration(days: 1)),
        assignmentId: 'assignment_003',
        assignmentTitle: 'Dagdienst Kantoor',
        unreadCounts: {},
      ),

      // Group conversation (future feature preview)
      ConversationModel(
        conversationId: 'conv_005',
        title: 'Team Amsterdam Noord',
        conversationType: ConversationType.group,
        participants: {
          _currentUserId: ParticipantDetails(
            userId: _currentUserId,
            userName: _currentUserName,
            userRole: 'guard',
            joinedAt: now.subtract(Duration(days: 10)),
            isOnline: true,
          ),
          'guard_003': ParticipantDetails(
            userId: 'guard_003',
            userName: 'Maria Jansen',
            userRole: 'guard',
            joinedAt: now.subtract(Duration(days: 10)),
            isOnline: true,
          ),
          'guard_004': ParticipantDetails(
            userId: 'guard_004',
            userName: 'Ahmed Hassan',
            userRole: 'guard',
            joinedAt: now.subtract(Duration(days: 8)),
            isOnline: false,
            lastSeen: now.subtract(Duration(hours: 6)),
          ),
        },
        lastMessage: LastMessagePreview(
          messageId: 'msg_latest_005',
          senderId: 'guard_003',
          senderName: 'Maria Jansen',
          content: 'Wie kan er morgen de vroege dienst overnemen?',
          messageType: MessageType.text,
          timestamp: now.subtract(Duration(hours: 6)),
          deliveryStatus: MessageDeliveryStatus.delivered,
        ),
        createdAt: now.subtract(Duration(days: 10)),
        updatedAt: now.subtract(Duration(hours: 6)),
        unreadCounts: {},
        typingStatus: {'guard_004': true}, // Someone is typing
      ),

      // Conversation with image
      ConversationModel(
        conversationId: 'conv_006',
        title: 'De Bijenkorf Winkelbeveiliging',
        conversationType: ConversationType.assignment,
        participants: {
          _currentUserId: ParticipantDetails(
            userId: _currentUserId,
            userName: _currentUserName,
            userRole: 'guard',
            joinedAt: now.subtract(Duration(days: 3)),
            isOnline: true,
          ),
          'company_004': ParticipantDetails(
            userId: 'company_004',
            userName: 'De Bijenkorf Security',
            userRole: 'company',
            joinedAt: now.subtract(Duration(days: 3)),
            isOnline: false,
            lastSeen: now.subtract(Duration(hours: 8)),
          ),
        },
        lastMessage: LastMessagePreview(
          messageId: 'msg_latest_006',
          senderId: _currentUserId,
          senderName: _currentUserName,
          content: '📷 Incident rapport - verdachte persoon',
          messageType: MessageType.image,
          timestamp: now.subtract(Duration(hours: 8)),
          deliveryStatus: MessageDeliveryStatus.read,
        ),
        createdAt: now.subtract(Duration(days: 3)),
        updatedAt: now.subtract(Duration(hours: 8)),
        assignmentId: 'assignment_004',
        assignmentTitle: 'Weekend Winkelbeveiliging',
        unreadCounts: {},
      ),
    ];
  }

  /// Get total unread count across all conversations
  static int getTotalUnreadCount(List<ConversationModel> conversations) {
    return conversations.fold<int>(0, (sum, conv) => 
        sum + conv.getUnreadCount(_currentUserId));
  }

  /// Get conversations with typing indicators
  static List<ConversationModel> getConversationsWithTyping(List<ConversationModel> conversations) {
    return conversations.where((conv) => conv.hasTypingUsers).toList();
  }
}
