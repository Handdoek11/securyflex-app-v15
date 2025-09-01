import '../models/message_model.dart';
import '../repositories/chat_repository.dart';
import '../repositories/chat_repository_impl.dart';

/// Use case for getting messages with pagination and real-time updates
/// Provides WhatsApp-quality message management with Dutch localization
class GetMessagesUseCase {
  final ChatRepository _repository = ChatRepositoryImpl.instance;

  /// Get messages for a conversation (one-time fetch with pagination)
  Future<MessagesResult> getMessages(
    String conversationId, {
    int limit = 20,
    MessageModel? lastMessage,
  }) async {
    try {
      final messages = await _repository.getMessages(
        conversationId,
        limit: limit,
        lastMessage: lastMessage,
      );

      // Sort messages by timestamp (newest first for display)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return MessagesResult.success(
        messages: messages,
        hasMore: messages.length == limit,
        message: messages.isEmpty 
            ? 'Geen berichten gevonden' 
            : '${messages.length} berichten geladen',
      );
    } catch (e) {
      return MessagesResult.failure('Fout bij laden berichten: ${e.toString()}');
    }
  }

  /// Watch messages for real-time updates
  Stream<MessagesResult> watchMessages(String conversationId) {
    return _repository.watchMessages(conversationId).map((messages) {
      // Sort messages by timestamp (newest first)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return MessagesResult.success(
        messages: messages,
        hasMore: false, // Real-time stream doesn't support pagination
        message: '${messages.length} berichten',
      );
    }).handleError((error) {
      return MessagesResult.failure('Fout bij real-time updates: ${error.toString()}');
    });
  }

  /// Mark message as read and update delivery status
  Future<MessageActionResult> markMessageAsRead(
    String conversationId,
    String messageId,
    String userId,
  ) async {
    try {
      final success = await _repository.markMessageAsRead(conversationId, messageId, userId);
      
      if (success) {
        return MessageActionResult.success('Bericht gemarkeerd als gelezen');
      } else {
        return MessageActionResult.failure('Fout bij markeren als gelezen');
      }
    } catch (e) {
      return MessageActionResult.failure('Fout: ${e.toString()}');
    }
  }

  /// Mark all messages in conversation as read
  Future<MessageActionResult> markAllMessagesAsRead(
    String conversationId,
    String userId,
    List<MessageModel> messages,
  ) async {
    try {
      int successCount = 0;
      
      for (final message in messages) {
        if (message.senderId != userId && !message.isReadByUser(userId)) {
          final success = await _repository.markMessageAsRead(
            conversationId,
            message.messageId,
            userId,
          );
          if (success) successCount++;
        }
      }

      return MessageActionResult.success(
        '$successCount berichten gemarkeerd als gelezen',
      );
    } catch (e) {
      return MessageActionResult.failure('Fout bij markeren berichten: ${e.toString()}');
    }
  }

  /// Update message delivery status
  Future<MessageActionResult> updateDeliveryStatus(
    String conversationId,
    String messageId,
    String userId,
    MessageDeliveryStatus status,
  ) async {
    try {
      final success = await _repository.updateMessageDeliveryStatus(
        conversationId,
        messageId,
        userId,
        status,
      );

      if (success) {
        final statusText = _getDeliveryStatusText(status);
        return MessageActionResult.success('Status bijgewerkt naar $statusText');
      } else {
        return MessageActionResult.failure('Fout bij bijwerken status');
      }
    } catch (e) {
      return MessageActionResult.failure('Fout: ${e.toString()}');
    }
  }

  /// Search messages in conversation
  Future<MessagesResult> searchMessagesInConversation(
    String conversationId,
    String query,
  ) async {
    try {
      if (query.trim().isEmpty) {
        return getMessages(conversationId);
      }

      // Get all messages first (in a real app, this would be server-side search)
      final allMessagesResult = await getMessages(conversationId, limit: 1000);
      if (!allMessagesResult.isSuccess) {
        return allMessagesResult;
      }

      // Filter messages by query
      final filteredMessages = allMessagesResult.messages!
          .where((message) => 
              message.content.toLowerCase().contains(query.toLowerCase()) ||
              message.senderName.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return MessagesResult.success(
        messages: filteredMessages,
        hasMore: false,
        message: '${filteredMessages.length} resultaten voor "$query"',
      );
    } catch (e) {
      return MessagesResult.failure('Fout bij zoeken: ${e.toString()}');
    }
  }

  /// Get message statistics for conversation
  Future<MessageStats> getMessageStats(String conversationId, String userId) async {
    try {
      final result = await getMessages(conversationId, limit: 1000);
      if (!result.isSuccess) {
        return MessageStats.empty();
      }

      final messages = result.messages!;
      final sentByUser = messages.where((m) => m.senderId == userId).length;
      final receivedByUser = messages.where((m) => m.senderId != userId).length;
      final unreadMessages = messages.where((m) => 
          m.senderId != userId && !m.isReadByUser(userId)).length;
      final filesShared = messages.where((m) => m.attachment != null).length;
      final imagesShared = messages.where((m) => m.messageType == MessageType.image).length;

      return MessageStats(
        totalMessages: messages.length,
        sentByUser: sentByUser,
        receivedByUser: receivedByUser,
        unreadMessages: unreadMessages,
        filesShared: filesShared,
        imagesShared: imagesShared,
      );
    } catch (e) {
      return MessageStats.empty();
    }
  }

  /// Get Dutch text for delivery status
  String _getDeliveryStatusText(MessageDeliveryStatus status) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return 'verzenden';
      case MessageDeliveryStatus.sent:
        return 'verzonden';
      case MessageDeliveryStatus.delivered:
        return 'afgeleverd';
      case MessageDeliveryStatus.read:
        return 'gelezen';
      case MessageDeliveryStatus.failed:
        return 'mislukt';
    }
  }
}

/// Result of getting messages
class MessagesResult {
  final bool isSuccess;
  final List<MessageModel>? messages;
  final bool hasMore;
  final String message;

  const MessagesResult._({
    required this.isSuccess,
    this.messages,
    required this.hasMore,
    required this.message,
  });

  factory MessagesResult.success({
    required List<MessageModel> messages,
    required bool hasMore,
    required String message,
  }) {
    return MessagesResult._(
      isSuccess: true,
      messages: messages,
      hasMore: hasMore,
      message: message,
    );
  }

  factory MessagesResult.failure(String message) {
    return MessagesResult._(
      isSuccess: false,
      hasMore: false,
      message: message,
    );
  }
}

/// Result of message actions (mark as read, update status, etc.)
class MessageActionResult {
  final bool isSuccess;
  final String message;

  const MessageActionResult._({
    required this.isSuccess,
    required this.message,
  });

  factory MessageActionResult.success(String message) {
    return MessageActionResult._(
      isSuccess: true,
      message: message,
    );
  }

  factory MessageActionResult.failure(String message) {
    return MessageActionResult._(
      isSuccess: false,
      message: message,
    );
  }
}

/// Message statistics
class MessageStats {
  final int totalMessages;
  final int sentByUser;
  final int receivedByUser;
  final int unreadMessages;
  final int filesShared;
  final int imagesShared;

  const MessageStats({
    required this.totalMessages,
    required this.sentByUser,
    required this.receivedByUser,
    required this.unreadMessages,
    required this.filesShared,
    required this.imagesShared,
  });

  factory MessageStats.empty() {
    return const MessageStats(
      totalMessages: 0,
      sentByUser: 0,
      receivedByUser: 0,
      unreadMessages: 0,
      filesShared: 0,
      imagesShared: 0,
    );
  }

  /// Get Dutch summary text
  String getSummaryText() {
    if (totalMessages == 0) {
      return 'Geen berichten';
    }

    final parts = <String>[];
    parts.add('$totalMessages berichten');
    if (unreadMessages > 0) {
      parts.add('$unreadMessages ongelezen');
    }
    if (filesShared > 0) {
      parts.add('$filesShared bestanden');
    }

    return parts.join(', ');
  }
}
