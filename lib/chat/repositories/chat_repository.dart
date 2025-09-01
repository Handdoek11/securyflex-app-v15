import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/typing_status_model.dart';

/// Dutch business rules for chat functionality
class ChatBusinessRules {
  /// Maximum edit time window (15 minutes as per Dutch business standards)
  static const int maxEditTimeMinutes = 15;
  
  /// Maximum file size for attachments (10MB for images, 100MB for documents)
  static const int maxImageSizeMB = 10;
  static const int maxDocumentSizeMB = 100;
  
  /// Supported file types
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> supportedDocumentTypes = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'];
}

/// Enhanced conversation settings
class ConversationSettings {
  final bool muteNotifications;
  final DateTime? muteUntil;
  final bool readReceipts;
  final bool typingIndicators;
  final int messageRetentionDays;
  
  const ConversationSettings({
    this.muteNotifications = false,
    this.muteUntil,
    this.readReceipts = true,
    this.typingIndicators = true,
    this.messageRetentionDays = 365, // 1 year default
  });
}

/// Abstract repository interface for chat functionality
/// Defines the contract for chat data operations with WhatsApp-quality features
abstract class ChatRepository {
  // Enhanced conversation operations
  Future<List<ConversationModel>> getConversations(String userId);
  Future<ConversationModel?> getConversation(String conversationId);
  Future<String> createConversation(ConversationModel conversation);
  Future<bool> updateConversation(ConversationModel conversation);
  Future<bool> updateConversationSettings(String conversationId, String userId, ConversationSettings settings);
  Future<ConversationSettings?> getConversationSettings(String conversationId, String userId);
  Future<bool> archiveConversation(String conversationId, String userId);
  Future<bool> unarchiveConversation(String conversationId, String userId);
  Future<bool> muteConversation(String conversationId, String userId, {DateTime? until});
  Future<bool> unmuteConversation(String conversationId, String userId);
  Stream<List<ConversationModel>> watchConversations(String userId);
  Stream<ConversationModel> watchConversation(String conversationId);

  // Enhanced message operations with Dutch business rules
  Future<List<MessageModel>> getMessages(String conversationId, {int limit = 20, MessageModel? lastMessage});
  Future<String> sendMessage(MessageModel message);
  Future<bool> editMessage(String conversationId, String messageId, String newContent, String userId);
  Future<bool> deleteMessage(String conversationId, String messageId, String userId, {bool softDelete = true});
  Future<bool> addMessageReaction(String conversationId, String messageId, String reaction, String userId);
  Future<bool> removeMessageReaction(String conversationId, String messageId, String reaction, String userId);
  Future<List<MessageModel>> getMessageEditHistory(String conversationId, String messageId);
  Future<bool> markMessageAsRead(String conversationId, String messageId, String userId);
  Future<bool> updateMessageDeliveryStatus(String conversationId, String messageId, String userId, MessageDeliveryStatus status);
  Stream<List<MessageModel>> watchMessages(String conversationId);
  
  // Legacy message operations (for backward compatibility)
  @Deprecated('Use editMessage instead')
  Future<bool> updateMessage(MessageModel message);

  // Typing indicators
  Future<bool> setTypingStatus(String conversationId, String userId, String userName, bool isTyping);
  Stream<List<TypingStatusModel>> watchTypingStatus(String conversationId);

  // User presence
  Future<bool> updateUserPresence(String userId, bool isOnline);
  Future<UserPresenceModel?> getUserPresence(String userId);
  Stream<UserPresenceModel> watchUserPresence(String userId);

  // Enhanced file operations with Dutch business rules
  Future<String> uploadFileAttachment(String filePath, String fileName, String conversationId, String userId);
  Future<bool> downloadFileAttachment(String fileUrl, String localPath);
  Future<bool> deleteFileAttachment(String fileUrl, String userId);
  Future<bool> validateFileAttachment(String filePath, MessageType messageType);
  
  // Legacy file operations (deprecated)
  @Deprecated('Use uploadFileAttachment instead')
  Future<String> uploadFile(String filePath, String fileName, String conversationId);
  @Deprecated('Use deleteFileAttachment instead')
  Future<bool> deleteFile(String fileUrl);

  // Enhanced search operations with Dutch language support
  Future<List<MessageModel>> searchMessages(String query, String userId, {String? conversationId, MessageType? messageType, DateTime? fromDate, DateTime? toDate});
  Future<List<ConversationModel>> searchConversations(String query, String userId);
  Future<List<MessageModel>> searchMessagesWithFilters(String userId, Map<String, dynamic> filters);

  // Offline support
  Future<bool> syncOfflineMessages();
  Future<List<MessageModel>> getOfflineMessages();
  Future<bool> cacheConversation(ConversationModel conversation);

  // Enhanced analytics and GDPR compliance
  Future<Map<String, dynamic>> getChatMetrics(String userId);
  Future<bool> logChatEvent(String eventType, Map<String, dynamic> data);
  Future<bool> exportUserData(String userId, String format); // GDPR compliance
  Future<bool> deleteUserData(String userId); // GDPR right to be forgotten
  Future<Map<String, dynamic>> getDataRetentionReport(String userId);
}
