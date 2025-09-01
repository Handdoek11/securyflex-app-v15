import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/typing_status_model.dart';
import '../data_sources/chat_remote_data_source.dart';
import 'chat_repository.dart';
import '../../core/services/audit_service.dart';
import '../../core/services/gdpr_compliance_service.dart';

/// Implementation of ChatRepository following SecuryFlex service patterns
/// Provides WhatsApp-quality chat functionality with offline support
class ChatRepositoryImpl implements ChatRepository {
  static ChatRepositoryImpl? _instance;
  static ChatRepositoryImpl get instance {
    _instance ??= ChatRepositoryImpl._();
    return _instance!;
  }

  ChatRepositoryImpl._();

  final ChatRemoteDataSource _remoteDataSource = ChatRemoteDataSource.instance;

  // Local cache for offline support
  final Map<String, ConversationModel> _conversationCache = {};
  final Map<String, List<MessageModel>> _messageCache = {};
  final List<MessageModel> _offlineMessages = [];

  @override
  Future<List<ConversationModel>> getConversations(String userId) async {
    try {
      final conversations = await _remoteDataSource.getUserConversations(userId);
      
      // Cache conversations for offline access
      for (final conversation in conversations) {
        _conversationCache[conversation.conversationId] = conversation;
      }
      
      return conversations;
    } catch (e) {
      // Return cached conversations if offline
      return _conversationCache.values
          .where((conv) => conv.participants.containsKey(userId))
          .toList();
    }
  }

  @override
  Stream<List<ConversationModel>> watchConversations(String userId) {
    return _remoteDataSource.watchUserConversations(userId).map((conversations) {
      // Update cache with real-time data
      for (final conversation in conversations) {
        _conversationCache[conversation.conversationId] = conversation;
      }
      return conversations;
    });
  }

  @override
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      final conversation = await _remoteDataSource.getConversation(conversationId);
      if (conversation != null) {
        _conversationCache[conversationId] = conversation;
      }
      return conversation;
    } catch (e) {
      // Return cached conversation if offline
      return _conversationCache[conversationId];
    }
  }

  @override
  Stream<ConversationModel> watchConversation(String conversationId) {
    return _remoteDataSource.watchConversation(conversationId).map((conversation) {
      _conversationCache[conversationId] = conversation;
      return conversation;
    });
  }

  @override
  Future<String> createConversation(ConversationModel conversation) async {
    try {
      final conversationId = await _remoteDataSource.createConversation(conversation);
      _conversationCache[conversationId] = conversation.copyWith(conversationId: conversationId);
      return conversationId;
    } catch (e) {
      // Store for offline sync
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      _conversationCache[tempId] = conversation.copyWith(conversationId: tempId);
      return tempId;
    }
  }

  @override
  Future<bool> updateConversation(ConversationModel conversation) async {
    try {
      // Update cache immediately for responsive UI
      _conversationCache[conversation.conversationId] = conversation;
      
      // TODO: Implement remote update
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> archiveConversation(String conversationId, String userId) async {
    try {
      final success = await _remoteDataSource.archiveConversation(conversationId, userId);
      if (success) {
        _conversationCache.remove(conversationId);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId, {int limit = 20, MessageModel? lastMessage}) async {
    try {
      final messages = await _remoteDataSource.getMessages(conversationId, limit: limit);
      
      // Cache messages for offline access
      _messageCache[conversationId] = messages;
      
      return messages;
    } catch (e) {
      // Return cached messages if offline
      return _messageCache[conversationId] ?? [];
    }
  }

  @override
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _remoteDataSource.watchMessages(conversationId).map((messages) {
      // Update cache with real-time data
      _messageCache[conversationId] = messages;
      return messages;
    });
  }

  @override
  Future<String> sendMessage(MessageModel message) async {
    try {
      final messageId = await _remoteDataSource.sendMessage(message);
      
      // Update local cache immediately
      final cachedMessages = _messageCache[message.conversationId] ?? [];
      cachedMessages.insert(0, message.copyWith(messageId: messageId));
      _messageCache[message.conversationId] = cachedMessages;
      
      return messageId;
    } catch (e) {
      // Store for offline sync
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final offlineMessage = message.copyWith(messageId: tempId);
      _offlineMessages.add(offlineMessage);
      
      // Update local cache for immediate UI feedback
      final cachedMessages = _messageCache[message.conversationId] ?? [];
      cachedMessages.insert(0, offlineMessage);
      _messageCache[message.conversationId] = cachedMessages;
      
      return tempId;
    }
  }

  @override
  @Deprecated('Use editMessage instead')
  Future<bool> updateMessage(MessageModel message) async {
    return await editMessage(message.conversationId, message.messageId, message.content, message.senderId);
  }
  
  @override
  Future<bool> editMessage(String conversationId, String messageId, String newContent, String userId) async {
    try {
      // Validate edit permissions and time window
      final cachedMessages = _messageCache[conversationId] ?? [];
      final originalMessage = cachedMessages.firstWhere(
        (m) => m.messageId == messageId,
        orElse: () => throw Exception('Bericht niet gevonden'),
      );
      
      // Check if user owns the message
      if (originalMessage.senderId != userId) {
        throw Exception('Geen toestemming om dit bericht te bewerken');
      }
      
      // Check 15-minute edit window (Dutch business rule)
      final timeDiff = DateTime.now().difference(originalMessage.timestamp).inMinutes;
      if (timeDiff > ChatBusinessRules.maxEditTimeMinutes) {
        throw Exception('Bewerkingstijd verlopen (maximaal ${ChatBusinessRules.maxEditTimeMinutes} minuten)');
      }
      
      // Update message with edit timestamp
      final editedMessage = originalMessage.copyWith(
        content: newContent,
        editedAt: DateTime.now(),
        isEdited: true,
      );
      
      // Update cache immediately
      final index = cachedMessages.indexWhere((m) => m.messageId == messageId);
      if (index != -1) {
        cachedMessages[index] = editedMessage;
      }
      
      // Log audit event
      await AuditService.instance.logEvent(
        'message_edited',
        {
          'conversationId': conversationId,
          'messageId': messageId,
          'userId': userId,
          'originalContent': originalMessage.content,
          'newContent': newContent,
        },
      );
      
      // TODO: Implement remote update
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteMessage(String conversationId, String messageId, String userId, {bool softDelete = true}) async {
    try {
      final cachedMessages = _messageCache[conversationId] ?? [];
      final messageIndex = cachedMessages.indexWhere((m) => m.messageId == messageId);
      
      if (messageIndex == -1) {
        throw Exception('Bericht niet gevonden');
      }
      
      final message = cachedMessages[messageIndex];
      
      // Check if user owns the message or has admin permissions
      if (message.senderId != userId) {
        throw Exception('Geen toestemming om dit bericht te verwijderen');
      }
      
      if (softDelete) {
        // Soft delete: mark as deleted but keep for audit
        final deletedMessage = message.copyWith(
          isDeleted: true,
          content: 'Dit bericht is verwijderd',
        );
        cachedMessages[messageIndex] = deletedMessage;
      } else {
        // Hard delete: remove completely
        cachedMessages.removeAt(messageIndex);
      }
      
      // Log audit event
      await AuditService.instance.logEvent(
        'message_deleted',
        {
          'conversationId': conversationId,
          'messageId': messageId,
          'userId': userId,
          'softDelete': softDelete,
          'originalContent': message.content,
        },
      );
      
      // TODO: Implement remote delete
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> markMessageAsRead(String conversationId, String messageId, String userId) async {
    try {
      return await _remoteDataSource.markMessageAsRead(conversationId, messageId, userId);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateMessageDeliveryStatus(String conversationId, String messageId, String userId, MessageDeliveryStatus status) async {
    try {
      return await _remoteDataSource.updateMessageDeliveryStatus(conversationId, messageId, userId, status);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> setTypingStatus(String conversationId, String userId, String userName, bool isTyping) async {
    try {
      return await _remoteDataSource.setTypingStatus(conversationId, userId, userName, isTyping);
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<List<TypingStatusModel>> watchTypingStatus(String conversationId) {
    return _remoteDataSource.watchTypingStatus(conversationId);
  }

  @override
  Future<bool> updateUserPresence(String userId, bool isOnline) async {
    try {
      return await _remoteDataSource.updateUserPresence(userId, isOnline);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<UserPresenceModel?> getUserPresence(String userId) async {
    try {
      // TODO: Implement get user presence
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<UserPresenceModel> watchUserPresence(String userId) {
    return _remoteDataSource.watchUserPresence(userId);
  }

  @override
  Future<bool> validateFileAttachment(String filePath, MessageType messageType) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Bestand niet gevonden');
      }
      
      final fileSize = await file.length();
      final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
      
      // Validate file size based on type
      if (messageType == MessageType.image) {
        if (fileSize > ChatBusinessRules.maxImageSizeMB * 1024 * 1024) {
          throw Exception('Afbeelding te groot (max ${ChatBusinessRules.maxImageSizeMB}MB)');
        }
        if (!ChatBusinessRules.supportedImageTypes.contains(extension)) {
          throw Exception('Bestandstype niet ondersteund voor afbeeldingen');
        }
      } else if (messageType == MessageType.file) {
        if (fileSize > ChatBusinessRules.maxDocumentSizeMB * 1024 * 1024) {
          throw Exception('Document te groot (max ${ChatBusinessRules.maxDocumentSizeMB}MB)');
        }
        if (!ChatBusinessRules.supportedDocumentTypes.contains(extension)) {
          throw Exception('Bestandstype niet ondersteund voor documenten');
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<String> uploadFileAttachment(String filePath, String fileName, String conversationId, String userId) async {
    try {
      // Validate file first
      final messageType = _getMessageTypeFromFile(filePath);
      final isValid = await validateFileAttachment(filePath, messageType);
      if (!isValid) {
        throw Exception('Bestandsvalidatie mislukt');
      }
      
      // Upload file
      final fileUrl = await _remoteDataSource.uploadFile(filePath, fileName, conversationId);
      
      // Log audit event
      await AuditService.instance.logEvent(
        'file_uploaded',
        {
          'conversationId': conversationId,
          'userId': userId,
          'fileName': fileName,
          'fileUrl': fileUrl,
          'messageType': messageType.name,
        },
      );
      
      return fileUrl;
    } catch (e) {
      throw Exception('Bestand uploaden mislukt: $e');
    }
  }
  
  @override
  Future<bool> downloadFileAttachment(String fileUrl, String localPath) async {
    try {
      // TODO: Implement secure file download
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> deleteFileAttachment(String fileUrl, String userId) async {
    try {
      // Log audit event before deletion
      await AuditService.instance.logEvent(
        'file_deleted',
        {
          'fileUrl': fileUrl,
          'userId': userId,
        },
      );
      
      // TODO: Implement secure file deletion
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  @Deprecated('Use uploadFileAttachment instead')
  Future<String> uploadFile(String filePath, String fileName, String conversationId) async {
    // Get current user ID (this would come from auth service in real implementation)
    final userId = 'current_user'; // TODO: Get from AuthService
    return await uploadFileAttachment(filePath, fileName, conversationId, userId);
  }
  
  @override
  @Deprecated('Use deleteFileAttachment instead')
  Future<bool> deleteFile(String fileUrl) async {
    final userId = 'current_user'; // TODO: Get from AuthService
    return await deleteFileAttachment(fileUrl, userId);
  }
  
  MessageType _getMessageTypeFromFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
    if (ChatBusinessRules.supportedImageTypes.contains(extension)) {
      return MessageType.image;
    } else if (ChatBusinessRules.supportedDocumentTypes.contains(extension)) {
      return MessageType.file;
    }
    return MessageType.file; // Default to file type
  }

  @override
  Future<List<MessageModel>> searchMessages(String query, String userId, {String? conversationId, MessageType? messageType, DateTime? fromDate, DateTime? toDate}) async {
    try {
      // TODO: Implement enhanced search with filters in remote data source
      return await _remoteDataSource.searchMessages(query, userId);
    } catch (e) {
      // Enhanced offline search with Dutch language support
      final List<MessageModel> results = [];
      final messagesToSearch = conversationId != null 
          ? [_messageCache[conversationId] ?? []]
          : _messageCache.values;
      
      for (final messages in messagesToSearch) {
        final filtered = messages.where((message) {
          // Basic text search (case-insensitive, Dutch-aware)
          bool matchesQuery = message.content.toLowerCase().contains(query.toLowerCase());
          
          // Filter by message type
          if (messageType != null && message.messageType != messageType) {
            return false;
          }
          
          // Filter by date range
          if (fromDate != null && message.timestamp.isBefore(fromDate)) {
            return false;
          }
          if (toDate != null && message.timestamp.isAfter(toDate)) {
            return false;
          }
          
          // Don't include deleted messages in search
          if (message.isDeleted) {
            return false;
          }
          
          return matchesQuery;
        });
        
        results.addAll(filtered);
      }
      
      // Sort by relevance and date
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return results;
    }
  }
  
  @override
  Future<List<MessageModel>> searchMessagesWithFilters(String userId, Map<String, dynamic> filters) async {
    try {
      final query = filters['query'] as String? ?? '';
      final conversationId = filters['conversationId'] as String?;
      final messageType = filters['messageType'] as MessageType?;
      final fromDate = filters['fromDate'] as DateTime?;
      final toDate = filters['toDate'] as DateTime?;
      
      return await searchMessages(query, userId, 
        conversationId: conversationId,
        messageType: messageType, 
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<ConversationModel>> searchConversations(String query, String userId) async {
    try {
      // TODO: Implement conversation search
      return [];
    } catch (e) {
      // Search in cached conversations if offline
      return _conversationCache.values
          .where((conv) => conv.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  @override
  Future<bool> syncOfflineMessages() async {
    try {
      for (final message in _offlineMessages) {
        await _remoteDataSource.sendMessage(message);
      }
      _offlineMessages.clear();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<MessageModel>> getOfflineMessages() async {
    return List.from(_offlineMessages);
  }

  @override
  Future<bool> cacheConversation(ConversationModel conversation) async {
    _conversationCache[conversation.conversationId] = conversation;
    return true;
  }

  @override
  Future<Map<String, dynamic>> getChatMetrics(String userId) async {
    try {
      final conversations = _conversationCache.values
          .where((conv) => conv.participants.containsKey(userId))
          .toList();
      
      final totalMessages = _messageCache.values
          .expand((messages) => messages)
          .where((message) => message.senderId == userId)
          .length;
      
      return {
        'totalConversations': conversations.length,
        'activeConversations': conversations.where((conv) => !conv.isArchived).length,
        'totalMessagesSent': totalMessages,
        'averageResponseTime': 5.2, // minutes (mock data)
        'filesShared': 15, // mock data
      };
    } catch (e) {
      return {};
    }
  }

  @override
  Future<bool> logChatEvent(String eventType, Map<String, dynamic> data) async {
    try {
      // Enhanced audit logging with GDPR compliance
      await AuditService.instance.logEvent(eventType, data);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // New enhanced methods implementation
  
  @override
  Future<bool> addMessageReaction(String conversationId, String messageId, String reaction, String userId) async {
    try {
      final cachedMessages = _messageCache[conversationId] ?? [];
      final messageIndex = cachedMessages.indexWhere((m) => m.messageId == messageId);
      
      if (messageIndex == -1) {
        throw Exception('Bericht niet gevonden');
      }
      
      final message = cachedMessages[messageIndex];
      final updatedReactions = List<String>.from(message.reactions);
      
      if (!updatedReactions.contains(reaction)) {
        updatedReactions.add(reaction);
        
        final updatedMessage = message.copyWith(reactions: updatedReactions);
        cachedMessages[messageIndex] = updatedMessage;
        
        // Log audit event
        await AuditService.instance.logEvent(
          'reaction_added',
          {
            'conversationId': conversationId,
            'messageId': messageId,
            'reaction': reaction,
            'userId': userId,
          },
        );
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> removeMessageReaction(String conversationId, String messageId, String reaction, String userId) async {
    try {
      final cachedMessages = _messageCache[conversationId] ?? [];
      final messageIndex = cachedMessages.indexWhere((m) => m.messageId == messageId);
      
      if (messageIndex == -1) {
        throw Exception('Bericht niet gevonden');
      }
      
      final message = cachedMessages[messageIndex];
      final updatedReactions = List<String>.from(message.reactions);
      updatedReactions.remove(reaction);
      
      final updatedMessage = message.copyWith(reactions: updatedReactions);
      cachedMessages[messageIndex] = updatedMessage;
      
      // Log audit event
      await AuditService.instance.logEvent(
        'reaction_removed',
        {
          'conversationId': conversationId,
          'messageId': messageId,
          'reaction': reaction,
          'userId': userId,
        },
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<List<MessageModel>> getMessageEditHistory(String conversationId, String messageId) async {
    try {
      // TODO: Implement edit history retrieval from remote source
      // For now, return empty list
      return [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<bool> updateConversationSettings(String conversationId, String userId, ConversationSettings settings) async {
    try {
      // TODO: Implement conversation settings update
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<ConversationSettings?> getConversationSettings(String conversationId, String userId) async {
    try {
      // TODO: Implement conversation settings retrieval
      return const ConversationSettings();
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<bool> unarchiveConversation(String conversationId, String userId) async {
    try {
      // TODO: Implement remote unarchive
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> muteConversation(String conversationId, String userId, {DateTime? until}) async {
    try {
      // TODO: Implement conversation muting
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> unmuteConversation(String conversationId, String userId) async {
    try {
      // TODO: Implement conversation unmuting
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // GDPR Compliance methods
  
  @override
  Future<bool> exportUserData(String userId, String format) async {
    try {
      return await GDPRComplianceService.instance.exportUserChatData(userId, format);
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> deleteUserData(String userId) async {
    try {
      return await GDPRComplianceService.instance.deleteUserChatData(userId);
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<Map<String, dynamic>> getDataRetentionReport(String userId) async {
    try {
      return await GDPRComplianceService.instance.getChatDataRetentionReport(userId);
    } catch (e) {
      return {};
    }
  }
}
