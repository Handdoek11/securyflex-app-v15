import '../models/conversation_model.dart';
import '../repositories/chat_repository.dart';
import '../repositories/chat_repository_impl.dart';

/// Use case for getting conversations with real-time updates and Dutch localization
/// Provides WhatsApp-quality conversation management
class GetConversationsUseCase {
  final ChatRepository _repository = ChatRepositoryImpl.instance;

  /// Get conversations for a user (one-time fetch)
  Future<ConversationsResult> getConversations(String userId) async {
    try {
      final conversations = await _repository.getConversations(userId);
      
      // Sort conversations by last activity
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      // Calculate total unread count
      final totalUnreadCount = conversations.fold<int>(
        0,
        (sum, conv) => sum + conv.getUnreadCount(userId),
      );

      return ConversationsResult.success(
        conversations: conversations,
        totalUnreadCount: totalUnreadCount,
        message: conversations.isEmpty 
            ? 'Geen gesprekken gevonden' 
            : '${conversations.length} gesprekken geladen',
      );
    } catch (e) {
      return ConversationsResult.failure('Fout bij laden gesprekken: ${e.toString()}');
    }
  }

  /// Watch conversations for real-time updates
  Stream<ConversationsResult> watchConversations(String userId) {
    return _repository.watchConversations(userId).map((conversations) {
      // Sort conversations by last activity
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      // Calculate total unread count
      final totalUnreadCount = conversations.fold<int>(
        0,
        (sum, conv) => sum + conv.getUnreadCount(userId),
      );

      return ConversationsResult.success(
        conversations: conversations,
        totalUnreadCount: totalUnreadCount,
        message: '${conversations.length} gesprekken',
      );
    }).handleError((error) {
      return ConversationsResult.failure('Fout bij real-time updates: ${error.toString()}');
    });
  }

  /// Get active conversations (not archived)
  Future<ConversationsResult> getActiveConversations(String userId) async {
    try {
      final result = await getConversations(userId);
      if (!result.isSuccess) return result;

      final activeConversations = result.conversations!
          .where((conv) => !conv.isArchived)
          .toList();

      return ConversationsResult.success(
        conversations: activeConversations,
        totalUnreadCount: result.totalUnreadCount,
        message: '${activeConversations.length} actieve gesprekken',
      );
    } catch (e) {
      return ConversationsResult.failure('Fout bij laden actieve gesprekken: ${e.toString()}');
    }
  }

  /// Get archived conversations
  Future<ConversationsResult> getArchivedConversations(String userId) async {
    try {
      final result = await getConversations(userId);
      if (!result.isSuccess) return result;

      final archivedConversations = result.conversations!
          .where((conv) => conv.isArchived)
          .toList();

      return ConversationsResult.success(
        conversations: archivedConversations,
        totalUnreadCount: 0, // Archived conversations don't count for unread
        message: '${archivedConversations.length} gearchiveerde gesprekken',
      );
    } catch (e) {
      return ConversationsResult.failure('Fout bij laden gearchiveerde gesprekken: ${e.toString()}');
    }
  }

  /// Get conversations by type (assignment, direct, group)
  Future<ConversationsResult> getConversationsByType(
    String userId,
    ConversationType type,
  ) async {
    try {
      final result = await getConversations(userId);
      if (!result.isSuccess) return result;

      final filteredConversations = result.conversations!
          .where((conv) => conv.conversationType == type)
          .toList();

      final typeDisplayName = _getTypeDisplayName(type);

      return ConversationsResult.success(
        conversations: filteredConversations,
        totalUnreadCount: filteredConversations.fold<int>(
          0,
          (sum, conv) => sum + conv.getUnreadCount(userId),
        ),
        message: '${filteredConversations.length} $typeDisplayName gesprekken',
      );
    } catch (e) {
      return ConversationsResult.failure('Fout bij laden gesprekken: ${e.toString()}');
    }
  }

  /// Search conversations by title or participant name
  Future<ConversationsResult> searchConversations(
    String userId,
    String query,
  ) async {
    try {
      if (query.trim().isEmpty) {
        return getConversations(userId);
      }

      final conversations = await _repository.searchConversations(query, userId);
      
      return ConversationsResult.success(
        conversations: conversations,
        totalUnreadCount: conversations.fold<int>(
          0,
          (sum, conv) => sum + conv.getUnreadCount(userId),
        ),
        message: '${conversations.length} resultaten voor "$query"',
      );
    } catch (e) {
      return ConversationsResult.failure('Fout bij zoeken: ${e.toString()}');
    }
  }

  /// Get conversation statistics for user
  Future<ConversationStats> getConversationStats(String userId) async {
    try {
      final result = await getConversations(userId);
      if (!result.isSuccess) {
        return ConversationStats.empty();
      }

      final conversations = result.conversations!;
      final activeCount = conversations.where((conv) => !conv.isArchived).length;
      final archivedCount = conversations.where((conv) => conv.isArchived).length;
      final assignmentCount = conversations.where((conv) => conv.conversationType == ConversationType.assignment).length;
      final directCount = conversations.where((conv) => conv.conversationType == ConversationType.direct).length;
      final totalUnread = result.totalUnreadCount;

      return ConversationStats(
        totalConversations: conversations.length,
        activeConversations: activeCount,
        archivedConversations: archivedCount,
        assignmentConversations: assignmentCount,
        directConversations: directCount,
        totalUnreadMessages: totalUnread,
      );
    } catch (e) {
      return ConversationStats.empty();
    }
  }

  /// Get Dutch display name for conversation type
  String _getTypeDisplayName(ConversationType type) {
    switch (type) {
      case ConversationType.assignment:
        return 'opdracht';
      case ConversationType.direct:
        return 'directe';
      case ConversationType.group:
        return 'groep';
    }
  }
}

/// Result of getting conversations
class ConversationsResult {
  final bool isSuccess;
  final List<ConversationModel>? conversations;
  final int totalUnreadCount;
  final String message;

  const ConversationsResult._({
    required this.isSuccess,
    this.conversations,
    required this.totalUnreadCount,
    required this.message,
  });

  factory ConversationsResult.success({
    required List<ConversationModel> conversations,
    required int totalUnreadCount,
    required String message,
  }) {
    return ConversationsResult._(
      isSuccess: true,
      conversations: conversations,
      totalUnreadCount: totalUnreadCount,
      message: message,
    );
  }

  factory ConversationsResult.failure(String message) {
    return ConversationsResult._(
      isSuccess: false,
      totalUnreadCount: 0,
      message: message,
    );
  }
}

/// Conversation statistics
class ConversationStats {
  final int totalConversations;
  final int activeConversations;
  final int archivedConversations;
  final int assignmentConversations;
  final int directConversations;
  final int totalUnreadMessages;

  const ConversationStats({
    required this.totalConversations,
    required this.activeConversations,
    required this.archivedConversations,
    required this.assignmentConversations,
    required this.directConversations,
    required this.totalUnreadMessages,
  });

  factory ConversationStats.empty() {
    return const ConversationStats(
      totalConversations: 0,
      activeConversations: 0,
      archivedConversations: 0,
      assignmentConversations: 0,
      directConversations: 0,
      totalUnreadMessages: 0,
    );
  }

  /// Get Dutch summary text
  String getSummaryText() {
    if (totalConversations == 0) {
      return 'Geen gesprekken';
    }

    final parts = <String>[];
    if (activeConversations > 0) {
      parts.add('$activeConversations actief');
    }
    if (archivedConversations > 0) {
      parts.add('$archivedConversations gearchiveerd');
    }
    if (totalUnreadMessages > 0) {
      parts.add('$totalUnreadMessages ongelezen');
    }

    return parts.isEmpty ? '$totalConversations gesprekken' : parts.join(', ');
  }
}
