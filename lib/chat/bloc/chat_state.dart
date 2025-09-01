import 'package:equatable/equatable.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/typing_status_model.dart';
import '../services/message_search_service.dart';
import 'chat_event.dart';

/// Base class for all chat states
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Initial state when chat is not yet initialized
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// General loading state for chat operations
class ChatLoading extends ChatState {
  final String? message;

  const ChatLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// State when chat is being initialized
class ChatInitializing extends ChatState {
  final String userId;

  const ChatInitializing(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// State when chat is successfully initialized
class ChatInitialized extends ChatState {
  final String userId;
  final List<ConversationModel> conversations;
  final int totalUnreadCount;

  const ChatInitialized({
    required this.userId,
    required this.conversations,
    required this.totalUnreadCount,
  });

  @override
  List<Object?> get props => [userId, conversations, totalUnreadCount];
}

/// State when conversations are being loaded
class ConversationsLoading extends ChatState {
  final String userId;

  const ConversationsLoading(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// State when conversations are successfully loaded
class ConversationsLoaded extends ChatState {
  final String userId;
  final List<ConversationModel> conversations;
  final int totalUnreadCount;
  final bool isRefreshing;

  const ConversationsLoaded({
    required this.userId,
    required this.conversations,
    required this.totalUnreadCount,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [userId, conversations, totalUnreadCount, isRefreshing];

  ConversationsLoaded copyWith({
    String? userId,
    List<ConversationModel>? conversations,
    int? totalUnreadCount,
    bool? isRefreshing,
  }) {
    return ConversationsLoaded(
      userId: userId ?? this.userId,
      conversations: conversations ?? this.conversations,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// State when a specific conversation is selected and messages are being loaded
class ConversationSelected extends ChatState {
  final String conversationId;
  final ConversationModel? conversation;
  final List<MessageModel> messages;
  final bool isLoadingMessages;
  final bool hasMoreMessages;
  final List<TypingStatusModel> typingUsers;
  final String? error;

  const ConversationSelected({
    required this.conversationId,
    this.conversation,
    this.messages = const [],
    this.isLoadingMessages = false,
    this.hasMoreMessages = true,
    this.typingUsers = const [],
    this.error,
  });

  @override
  List<Object?> get props => [
    conversationId,
    conversation,
    messages,
    isLoadingMessages,
    hasMoreMessages,
    typingUsers,
    error,
  ];

  ConversationSelected copyWith({
    String? conversationId,
    ConversationModel? conversation,
    List<MessageModel>? messages,
    bool? isLoadingMessages,
    bool? hasMoreMessages,
    List<TypingStatusModel>? typingUsers,
    String? error,
  }) {
    return ConversationSelected(
      conversationId: conversationId ?? this.conversationId,
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      typingUsers: typingUsers ?? this.typingUsers,
      error: error,
    );
  }
}

/// State when messages are being loaded for a conversation
class MessagesLoading extends ChatState {
  final String conversationId;
  final List<MessageModel> existingMessages;

  const MessagesLoading(this.conversationId, this.existingMessages);

  @override
  List<Object?> get props => [conversationId, existingMessages];
}

/// State when messages are successfully loaded
class MessagesLoaded extends ChatState {
  final String conversationId;
  final List<MessageModel> messages;
  final bool hasMoreMessages;
  final List<TypingStatusModel> typingUsers;

  const MessagesLoaded({
    required this.conversationId,
    required this.messages,
    this.hasMoreMessages = true,
    this.typingUsers = const [],
  });

  @override
  List<Object?> get props => [conversationId, messages, hasMoreMessages, typingUsers];

  MessagesLoaded copyWith({
    String? conversationId,
    List<MessageModel>? messages,
    bool? hasMoreMessages,
    List<TypingStatusModel>? typingUsers,
  }) {
    return MessagesLoaded(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }
}

/// State when a message is being sent
class MessageSending extends ChatState {
  final String conversationId;
  final MessageModel message;
  final List<MessageModel> existingMessages;

  const MessageSending({
    required this.conversationId,
    required this.message,
    required this.existingMessages,
  });

  @override
  List<Object?> get props => [conversationId, message, existingMessages];
}

/// State when a message is successfully sent
class MessageSent extends ChatState {
  final String conversationId;
  final String messageId;
  final List<MessageModel> messages;

  const MessageSent({
    required this.conversationId,
    required this.messageId,
    required this.messages,
  });

  @override
  List<Object?> get props => [conversationId, messageId, messages];
}

/// State when a file is being uploaded
class FileUploading extends ChatState {
  final String conversationId;
  final String fileName;
  final double progress;

  const FileUploading({
    required this.conversationId,
    required this.fileName,
    required this.progress,
  });

  @override
  List<Object?> get props => [conversationId, fileName, progress];
}

/// State when a file is successfully uploaded
class FileUploaded extends ChatState {
  final String conversationId;
  final String fileName;
  final String fileUrl;

  const FileUploaded({
    required this.conversationId,
    required this.fileName,
    required this.fileUrl,
  });

  @override
  List<Object?> get props => [conversationId, fileName, fileUrl];
}

/// State when typing status is updated
class TypingStatusUpdated extends ChatState {
  final String conversationId;
  final List<TypingStatusModel> typingUsers;

  const TypingStatusUpdated({
    required this.conversationId,
    required this.typingUsers,
  });

  @override
  List<Object?> get props => [conversationId, typingUsers];
}

/// State when user presence is updated
class UserPresenceUpdated extends ChatState {
  final String userId;
  final bool isOnline;
  final DateTime lastSeen;

  const UserPresenceUpdated({
    required this.userId,
    required this.isOnline,
    required this.lastSeen,
  });

  @override
  List<Object?> get props => [userId, isOnline, lastSeen];
}

/// State when search results are available
class SearchResultsLoaded extends ChatState {
  final String query;
  final List<ConversationModel> conversationResults;
  final List<MessageModel> messageResults;

  const SearchResultsLoaded({
    required this.query,
    this.conversationResults = const [],
    this.messageResults = const [],
  });

  @override
  List<Object?> get props => [query, conversationResults, messageResults];
}

/// State when offline messages are being synced
class OfflineMessagesSyncing extends ChatState {
  final int pendingMessagesCount;

  const OfflineMessagesSyncing(this.pendingMessagesCount);

  @override
  List<Object?> get props => [pendingMessagesCount];
}

/// State when offline messages are successfully synced
class OfflineMessagesSynced extends ChatState {
  final int syncedMessagesCount;

  const OfflineMessagesSynced(this.syncedMessagesCount);

  @override
  List<Object?> get props => [syncedMessagesCount];
}

/// State when chat is in offline mode
class ChatOffline extends ChatState {
  final List<ConversationModel> cachedConversations;
  final List<MessageModel> pendingMessages;

  const ChatOffline({
    this.cachedConversations = const [],
    this.pendingMessages = const [],
  });

  @override
  List<Object?> get props => [cachedConversations, pendingMessages];
}

/// State when an action is successful
class ChatActionSuccess extends ChatState {
  final String message;
  final String? actionType;

  const ChatActionSuccess(this.message, {this.actionType});

  @override
  List<Object?> get props => [message, actionType];
}

/// State when an error occurs
class ChatError extends ChatState {
  final String message;
  final String? errorCode;
  final ChatEvent? failedEvent;

  const ChatError(this.message, {this.errorCode, this.failedEvent});

  @override
  List<Object?> get props => [message, errorCode, failedEvent];
}

/// State when loading more messages (pagination)
class LoadingMoreMessages extends ChatState {
  final String conversationId;
  final List<MessageModel> existingMessages;

  const LoadingMoreMessages(this.conversationId, this.existingMessages);

  @override
  List<Object?> get props => [conversationId, existingMessages];
}

// Enhanced Message States

/// State when message edit history is loaded
class MessageEditHistoryLoaded extends ChatState {
  final String messageId;
  final List<MessageModel> editHistory;

  const MessageEditHistoryLoaded({
    required this.messageId,
    required this.editHistory,
  });

  @override
  List<Object?> get props => [messageId, editHistory];
}

// Enhanced Search States

/// State when message search is in progress
class MessageSearchLoading extends ChatState {
  final String query;

  const MessageSearchLoading(this.query);

  @override
  List<Object?> get props => [query];
}

/// State when message search results are loaded with highlights
class MessageSearchResultsLoaded extends ChatState {
  final String query;
  final List<MessageModel> results;
  final int totalResults;
  final List<SearchHighlight> highlights;

  const MessageSearchResultsLoaded({
    required this.query,
    required this.results,
    required this.totalResults,
    required this.highlights,
  });

  @override
  List<Object?> get props => [query, results, totalResults, highlights];
}

// Enhanced File Attachment States

/// State when secure file is being uploaded
class SecureFileUploading extends ChatState {
  final String conversationId;
  final String fileName;
  final double progress;

  const SecureFileUploading({
    required this.conversationId,
    required this.fileName,
    required this.progress,
  });

  @override
  List<Object?> get props => [conversationId, fileName, progress];
}

/// State when secure file is successfully uploaded
class SecureFileUploaded extends ChatState {
  final String conversationId;
  final String fileName;
  final String downloadUrl;
  final String? thumbnailUrl;

  const SecureFileUploaded({
    required this.conversationId,
    required this.fileName,
    required this.downloadUrl,
    this.thumbnailUrl,
  });

  @override
  List<Object?> get props => [conversationId, fileName, downloadUrl, thumbnailUrl];
}

/// State when secure file is being downloaded
class SecureFileDownloading extends ChatState {
  final String fileUrl;

  const SecureFileDownloading(this.fileUrl);

  @override
  List<Object?> get props => [fileUrl];
}

/// State when secure file is successfully downloaded
class SecureFileDownloaded extends ChatState {
  final String fileUrl;
  final String localPath;

  const SecureFileDownloaded({
    required this.fileUrl,
    required this.localPath,
  });

  @override
  List<Object?> get props => [fileUrl, localPath];
}

// GDPR Compliance States

/// State when GDPR data export is in progress
class GDPRExportInProgress extends ChatState {
  final String userId;
  final String format;

  const GDPRExportInProgress(this.userId, this.format);

  @override
  List<Object?> get props => [userId, format];
}

/// State when GDPR data export is completed
class GDPRExportCompleted extends ChatState {
  final String userId;
  final String format;
  final String message;

  const GDPRExportCompleted({
    required this.userId,
    required this.format,
    required this.message,
  });

  @override
  List<Object?> get props => [userId, format, message];
}

/// State when GDPR data deletion is in progress
class GDPRDeletionInProgress extends ChatState {
  final String userId;

  const GDPRDeletionInProgress(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// State when GDPR data deletion is completed
class GDPRDeletionCompleted extends ChatState {
  final String userId;
  final String message;

  const GDPRDeletionCompleted({
    required this.userId,
    required this.message,
  });

  @override
  List<Object?> get props => [userId, message];
}

/// State when data retention report is being loaded
class DataRetentionReportLoading extends ChatState {
  final String userId;

  const DataRetentionReportLoading(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// State when data retention report is loaded
class DataRetentionReportLoaded extends ChatState {
  final String userId;
  final Map<String, dynamic> report;

  const DataRetentionReportLoaded({
    required this.userId,
    required this.report,
  });

  @override
  List<Object?> get props => [userId, report];
}
