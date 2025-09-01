import 'package:equatable/equatable.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

/// Base class for all chat events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

// Conversation Events
class LoadConversations extends ChatEvent {
  final String userId;

  const LoadConversations(this.userId);

  @override
  List<Object?> get props => [userId];
}

class WatchConversations extends ChatEvent {
  final String userId;

  const WatchConversations(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SelectConversation extends ChatEvent {
  final String conversationId;

  const SelectConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class CreateConversation extends ChatEvent {
  final ConversationModel conversation;

  const CreateConversation(this.conversation);

  @override
  List<Object?> get props => [conversation];
}

class ArchiveConversation extends ChatEvent {
  final String conversationId;
  final String userId;

  const ArchiveConversation(this.conversationId, this.userId);

  @override
  List<Object?> get props => [conversationId, userId];
}

class UnarchiveConversation extends ChatEvent {
  final String conversationId;
  final String userId;

  const UnarchiveConversation(this.conversationId, this.userId);

  @override
  List<Object?> get props => [conversationId, userId];
}

class MuteConversation extends ChatEvent {
  final String conversationId;
  final String userId;
  final DateTime? until;

  const MuteConversation(this.conversationId, this.userId, {this.until});

  @override
  List<Object?> get props => [conversationId, userId, until];
}

class UnmuteConversation extends ChatEvent {
  final String conversationId;
  final String userId;

  const UnmuteConversation(this.conversationId, this.userId);

  @override
  List<Object?> get props => [conversationId, userId];
}

class SearchConversations extends ChatEvent {
  final String query;
  final String userId;

  const SearchConversations(this.query, this.userId);

  @override
  List<Object?> get props => [query, userId];
}

// Message Events
class LoadMessages extends ChatEvent {
  final String conversationId;
  final int limit;
  final MessageModel? lastMessage;

  const LoadMessages(
    this.conversationId, {
    this.limit = 20,
    this.lastMessage,
  });

  @override
  List<Object?> get props => [conversationId, limit, lastMessage];
}

class WatchMessages extends ChatEvent {
  final String conversationId;

  const WatchMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendTextMessage extends ChatEvent {
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageReply? replyTo;

  const SendTextMessage({
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.replyTo,
  });

  @override
  List<Object?> get props => [conversationId, senderId, senderName, content, replyTo];
}

class SendFileMessage extends ChatEvent {
  final String conversationId;
  final String senderId;
  final String senderName;
  final String filePath;
  final String fileName;
  final MessageType messageType;
  final String? caption;

  const SendFileMessage({
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.filePath,
    required this.fileName,
    required this.messageType,
    this.caption,
  });

  @override
  List<Object?> get props => [
    conversationId,
    senderId,
    senderName,
    filePath,
    fileName,
    messageType,
    caption,
  ];
}

class MarkMessageAsRead extends ChatEvent {
  final String conversationId;
  final String messageId;
  final String userId;

  const MarkMessageAsRead(this.conversationId, this.messageId, this.userId);

  @override
  List<Object?> get props => [conversationId, messageId, userId];
}

class MarkAllMessagesAsRead extends ChatEvent {
  final String conversationId;
  final String userId;

  const MarkAllMessagesAsRead(this.conversationId, this.userId);

  @override
  List<Object?> get props => [conversationId, userId];
}

class UpdateMessageDeliveryStatus extends ChatEvent {
  final String conversationId;
  final String messageId;
  final String userId;
  final MessageDeliveryStatus status;

  const UpdateMessageDeliveryStatus(
    this.conversationId,
    this.messageId,
    this.userId,
    this.status,
  );

  @override
  List<Object?> get props => [conversationId, messageId, userId, status];
}

class SearchMessages extends ChatEvent {
  final String conversationId;
  final String query;

  const SearchMessages(this.conversationId, this.query);

  @override
  List<Object?> get props => [conversationId, query];
}

// Enhanced Message Events
class EditMessage extends ChatEvent {
  final String conversationId;
  final String messageId;
  final String newContent;
  final String userId;

  const EditMessage({
    required this.conversationId,
    required this.messageId,
    required this.newContent,
    required this.userId,
  });

  @override
  List<Object?> get props => [conversationId, messageId, newContent, userId];
}

class DeleteMessage extends ChatEvent {
  final String conversationId;
  final String messageId;
  final String userId;
  final bool softDelete;

  const DeleteMessage({
    required this.conversationId,
    required this.messageId,
    required this.userId,
    this.softDelete = true,
  });

  @override
  List<Object?> get props => [conversationId, messageId, userId, softDelete];
}

class AddMessageReaction extends ChatEvent {
  final String conversationId;
  final String messageId;
  final String reaction;
  final String userId;

  const AddMessageReaction({
    required this.conversationId,
    required this.messageId,
    required this.reaction,
    required this.userId,
  });

  @override
  List<Object?> get props => [conversationId, messageId, reaction, userId];
}

class RemoveMessageReaction extends ChatEvent {
  final String conversationId;
  final String messageId;
  final String reaction;
  final String userId;

  const RemoveMessageReaction({
    required this.conversationId,
    required this.messageId,
    required this.reaction,
    required this.userId,
  });

  @override
  List<Object?> get props => [conversationId, messageId, reaction, userId];
}

class GetMessageEditHistory extends ChatEvent {
  final String conversationId;
  final String messageId;

  const GetMessageEditHistory({
    required this.conversationId,
    required this.messageId,
  });

  @override
  List<Object?> get props => [conversationId, messageId];
}

// Enhanced Search Events
class SearchMessagesWithFilters extends ChatEvent {
  final String userId;
  final String query;
  final String? conversationId;
  final MessageType? messageType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int limit;

  const SearchMessagesWithFilters({
    required this.userId,
    required this.query,
    this.conversationId,
    this.messageType,
    this.fromDate,
    this.toDate,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [
        userId,
        query,
        conversationId,
        messageType,
        fromDate,
        toDate,
        limit,
      ];
}

// File Attachment Events
class UploadSecureFile extends ChatEvent {
  final String conversationId;
  final String userId;
  final String filePath;
  final String? customFileName;
  final bool generateThumbnail;

  const UploadSecureFile({
    required this.conversationId,
    required this.userId,
    required this.filePath,
    this.customFileName,
    this.generateThumbnail = true,
  });

  @override
  List<Object?> get props => [
        conversationId,
        userId,
        filePath,
        customFileName,
        generateThumbnail,
      ];
}

class DownloadSecureFile extends ChatEvent {
  final String fileUrl;
  final String userId;
  final String localPath;

  const DownloadSecureFile({
    required this.fileUrl,
    required this.userId,
    required this.localPath,
  });

  @override
  List<Object?> get props => [fileUrl, userId, localPath];
}

class DeleteSecureFile extends ChatEvent {
  final String fileUrl;
  final String userId;

  const DeleteSecureFile({
    required this.fileUrl,
    required this.userId,
  });

  @override
  List<Object?> get props => [fileUrl, userId];
}

// GDPR Compliance Events
class ExportUserChatData extends ChatEvent {
  final String userId;
  final String format; // JSON, CSV, PDF

  const ExportUserChatData({
    required this.userId,
    required this.format,
  });

  @override
  List<Object?> get props => [userId, format];
}

class DeleteUserChatData extends ChatEvent {
  final String userId;

  const DeleteUserChatData(this.userId);

  @override
  List<Object?> get props => [userId];
}

class GetDataRetentionReport extends ChatEvent {
  final String userId;

  const GetDataRetentionReport(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Typing Events
class StartTyping extends ChatEvent {
  final String conversationId;
  final String userId;
  final String userName;

  const StartTyping(this.conversationId, this.userId, this.userName);

  @override
  List<Object?> get props => [conversationId, userId, userName];
}

class StopTyping extends ChatEvent {
  final String conversationId;
  final String userId;
  final String userName;

  const StopTyping(this.conversationId, this.userId, this.userName);

  @override
  List<Object?> get props => [conversationId, userId, userName];
}

class WatchTypingStatus extends ChatEvent {
  final String conversationId;

  const WatchTypingStatus(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

// User Presence Events
class UpdateUserPresence extends ChatEvent {
  final String userId;
  final bool isOnline;

  const UpdateUserPresence(this.userId, this.isOnline);

  @override
  List<Object?> get props => [userId, isOnline];
}

class WatchUserPresence extends ChatEvent {
  final String userId;

  const WatchUserPresence(this.userId);

  @override
  List<Object?> get props => [userId];
}

// File Upload Events
class UploadFile extends ChatEvent {
  final String filePath;
  final String fileName;
  final String conversationId;

  const UploadFile(this.filePath, this.fileName, this.conversationId);

  @override
  List<Object?> get props => [filePath, fileName, conversationId];
}

// Error and Retry Events
class RetryFailedAction extends ChatEvent {
  final ChatEvent originalEvent;

  const RetryFailedAction(this.originalEvent);

  @override
  List<Object?> get props => [originalEvent];
}

class ClearError extends ChatEvent {
  const ClearError();
}

// Offline Support Events
class SyncOfflineMessages extends ChatEvent {
  const SyncOfflineMessages();
}

class EnableOfflineMode extends ChatEvent {
  const EnableOfflineMode();
}

class DisableOfflineMode extends ChatEvent {
  const DisableOfflineMode();
}

// Chat Initialization Events
class InitializeChat extends ChatEvent {
  final String userId;

  const InitializeChat(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ResetChat extends ChatEvent {
  const ResetChat();
}

// Pagination Events
class LoadMoreMessages extends ChatEvent {
  final String conversationId;

  const LoadMoreMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class RefreshConversations extends ChatEvent {
  final String userId;

  const RefreshConversations(this.userId);

  @override
  List<Object?> get props => [userId];
}
