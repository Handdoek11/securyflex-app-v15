import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../use_cases/get_conversations_use_case.dart';
import '../use_cases/get_messages_use_case.dart';
import '../use_cases/send_message_use_case.dart';
import 'package:flutter/foundation.dart';
import '../repositories/chat_repository.dart';
import '../repositories/chat_repository_impl.dart';
import '../services/notification_service.dart';
import '../services/presence_service.dart';
import '../services/read_receipt_service.dart';
import '../services/chat_mockup_service.dart';
import '../services/file_attachment_service.dart';
import '../services/message_search_service.dart';
import '../models/message_model.dart';
import '../../core/services/gdpr_compliance_service.dart';

/// BLoC for managing chat state with WhatsApp-quality features
/// Follows SecuryFlex patterns and provides Dutch localization
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversationsUseCase _getConversationsUseCase = GetConversationsUseCase();
  final GetMessagesUseCase _getMessagesUseCase = GetMessagesUseCase();
  final SendMessageUseCase _sendMessageUseCase = SendMessageUseCase();
  final ChatRepository _repository = ChatRepositoryImpl.instance;

  // Stream subscriptions for real-time updates
  StreamSubscription? _conversationsSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;

  // Current state tracking
  String? _currentUserId;

  ChatBloc() : super(const ChatInitial()) {
    // Register event handlers
    on<InitializeChat>(_onInitializeChat);
    on<LoadConversations>(_onLoadConversations);
    on<WatchConversations>(_onWatchConversations);
    on<SelectConversation>(_onSelectConversation);
    on<LoadMessages>(_onLoadMessages);
    on<WatchMessages>(_onWatchMessages);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendFileMessage>(_onSendFileMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<MarkAllMessagesAsRead>(_onMarkAllMessagesAsRead);
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
    on<WatchTypingStatus>(_onWatchTypingStatus);
    on<SearchConversations>(_onSearchConversations);
    on<SearchMessages>(_onSearchMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<RefreshConversations>(_onRefreshConversations);
    on<SyncOfflineMessages>(_onSyncOfflineMessages);
    on<ClearError>(_onClearError);
    on<ResetChat>(_onResetChat);
    
    // Enhanced message operations
    on<EditMessage>(_onEditMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<AddMessageReaction>(_onAddMessageReaction);
    on<RemoveMessageReaction>(_onRemoveMessageReaction);
    on<GetMessageEditHistory>(_onGetMessageEditHistory);
    
    // Enhanced conversation operations
    on<UnarchiveConversation>(_onUnarchiveConversation);
    on<MuteConversation>(_onMuteConversation);
    on<UnmuteConversation>(_onUnmuteConversation);
    
    // Enhanced search operations
    on<SearchMessagesWithFilters>(_onSearchMessagesWithFilters);
    
    // File attachment operations
    on<UploadSecureFile>(_onUploadSecureFile);
    on<DownloadSecureFile>(_onDownloadSecureFile);
    on<DeleteSecureFile>(_onDeleteSecureFile);
    
    // GDPR compliance operations
    on<ExportUserChatData>(_onExportUserChatData);
    on<DeleteUserChatData>(_onDeleteUserChatData);
    on<GetDataRetentionReport>(_onGetDataRetentionReport);
  }

  /// Initialize chat for a user - Using mockup data for testing
  Future<void> _onInitializeChat(InitializeChat event, Emitter<ChatState> emit) async {
    emit(ChatInitializing(event.userId));
    _currentUserId = event.userId;

    try {
      // Add small delay to simulate initialization
      await Future.delayed(const Duration(milliseconds: 500));

      // Use mockup data for testing
      final conversations = ChatMockupService.generateMockConversations();
      final totalUnreadCount = ChatMockupService.getTotalUnreadCount(conversations);

      emit(ChatInitialized(
        userId: event.userId,
        conversations: conversations,
        totalUnreadCount: totalUnreadCount,
      ));

      // Don't start watching for mockup data to avoid conflicts
      // TODO: Re-enable when using real data
      // add(WatchConversations(event.userId));

      // TODO: Replace with real implementation when ready
      // final result = await _getConversationsUseCase.getConversations(event.userId);
      // if (result.isSuccess) {
      //   emit(ChatInitialized(
      //     userId: event.userId,
      //     conversations: result.conversations!,
      //     totalUnreadCount: result.totalUnreadCount,
      //   ));
      //   add(WatchConversations(event.userId));
      // } else {
      //   emit(ChatError(result.message));
      // }
    } catch (e) {
      emit(ChatError('Fout bij initialiseren chat: ${e.toString()}'));
    }
  }

  /// Load conversations (one-time fetch) - Using mockup data for testing
  Future<void> _onLoadConversations(LoadConversations event, Emitter<ChatState> emit) async {
    emit(ConversationsLoading(event.userId));

    try {
      // Add small delay to simulate network request
      await Future.delayed(const Duration(milliseconds: 800));

      // Use mockup data for testing the new dashboard-style layout
      final conversations = ChatMockupService.generateMockConversations();
      final totalUnreadCount = ChatMockupService.getTotalUnreadCount(conversations);

      emit(ConversationsLoaded(
        userId: event.userId,
        conversations: conversations,
        totalUnreadCount: totalUnreadCount,
      ));

      // TODO: Replace with real implementation when ready
      // final result = await _getConversationsUseCase.getConversations(event.userId);
      // if (result.isSuccess) {
      //   emit(ConversationsLoaded(
      //     userId: event.userId,
      //     conversations: result.conversations!,
      //     totalUnreadCount: result.totalUnreadCount,
      //   ));
      // } else {
      //   emit(ChatError(result.message));
      // }
    } catch (e) {
      emit(ChatError('Fout bij laden gesprekken: ${e.toString()}'));
    }
  }

  /// Watch conversations for real-time updates
  Future<void> _onWatchConversations(WatchConversations event, Emitter<ChatState> emit) async {
    await _conversationsSubscription?.cancel();

    _conversationsSubscription = _getConversationsUseCase
        .watchConversations(event.userId)
        .listen(
          (result) {
            if (result.isSuccess) {
              emit(ConversationsLoaded(
                userId: event.userId,
                conversations: result.conversations!,
                totalUnreadCount: result.totalUnreadCount,
              ));
            }
          },
          onError: (error) {
            emit(ChatError('Fout bij real-time updates: ${error.toString()}'));
          },
        );
  }

  /// Select a conversation and load its messages
  Future<void> _onSelectConversation(SelectConversation event, Emitter<ChatState> emit) async {
    emit(ConversationSelected(
      conversationId: event.conversationId,
      isLoadingMessages: true,
    ));

    try {
      // Get conversation details
      final conversation = await _repository.getConversation(event.conversationId);
      
      // Load messages
      final messagesResult = await _getMessagesUseCase.getMessages(event.conversationId);
      
      if (messagesResult.isSuccess) {
        emit(ConversationSelected(
          conversationId: event.conversationId,
          conversation: conversation,
          messages: messagesResult.messages!,
          hasMoreMessages: messagesResult.hasMore,
        ));

        // Start watching messages and typing status
        add(WatchMessages(event.conversationId));
        add(WatchTypingStatus(event.conversationId));
      } else {
        emit(ConversationSelected(
          conversationId: event.conversationId,
          conversation: conversation,
          error: messagesResult.message,
        ));
      }
    } catch (e) {
      emit(ConversationSelected(
        conversationId: event.conversationId,
        error: 'Fout bij laden gesprek: ${e.toString()}',
      ));
    }
  }

  /// Load messages for a conversation
  Future<void> _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) async {
    emit(MessagesLoading(event.conversationId, []));

    try {
      final result = await _getMessagesUseCase.getMessages(
        event.conversationId,
        limit: event.limit,
        lastMessage: event.lastMessage,
      );

      if (result.isSuccess) {
        emit(MessagesLoaded(
          conversationId: event.conversationId,
          messages: result.messages!,
          hasMoreMessages: result.hasMore,
        ));
      } else {
        emit(ChatError(result.message));
      }
    } catch (e) {
      emit(ChatError('Fout bij laden berichten: ${e.toString()}'));
    }
  }

  /// Watch messages for real-time updates
  Future<void> _onWatchMessages(WatchMessages event, Emitter<ChatState> emit) async {
    await _messagesSubscription?.cancel();

    _messagesSubscription = _getMessagesUseCase
        .watchMessages(event.conversationId)
        .listen(
          (result) {
            if (result.isSuccess) {
              final currentState = state;
              if (currentState is ConversationSelected) {
                emit(currentState.copyWith(
                  messages: result.messages!,
                  hasMoreMessages: result.hasMore,
                ));
              }
            }
          },
          onError: (error) {
            emit(ChatError('Fout bij real-time berichten: ${error.toString()}'));
          },
        );
  }

  /// Send a text message
  Future<void> _onSendTextMessage(SendTextMessage event, Emitter<ChatState> emit) async {
    try {
      final result = await _sendMessageUseCase.sendTextMessage(
        conversationId: event.conversationId,
        senderId: event.senderId,
        senderName: event.senderName,
        content: event.content,
        replyTo: event.replyTo,
      );

      if (result.isSuccess) {
        emit(ChatActionSuccess(result.message, actionType: 'sendMessage'));

        // Mark message as sent using read receipt service
        if (result.messageId != null) {
          await ReadReceiptService.instance.markMessageAsSent(
            conversationId: event.conversationId,
            messageId: result.messageId!,
            senderId: event.senderId,
          );
        }

        // Send push notification to conversation participants
        await _sendNotificationToParticipants(
          conversationId: event.conversationId,
          senderName: event.senderName,
          messageContent: event.content,
          messageType: MessageType.text,
        );
      } else {
        emit(ChatError(result.message, failedEvent: event));
      }
    } catch (e) {
      emit(ChatError('Fout bij verzenden bericht: ${e.toString()}', failedEvent: event));
    }
  }

  /// Send a file message
  Future<void> _onSendFileMessage(SendFileMessage event, Emitter<ChatState> emit) async {
    emit(FileUploading(
      conversationId: event.conversationId,
      fileName: event.fileName,
      progress: 0.0,
    ));

    try {
      final result = await _sendMessageUseCase.sendFileMessage(
        conversationId: event.conversationId,
        senderId: event.senderId,
        senderName: event.senderName,
        filePath: event.filePath,
        fileName: event.fileName,
        messageType: event.messageType,
        caption: event.caption,
        onProgress: (progress) {
          emit(FileUploading(
            conversationId: event.conversationId,
            fileName: event.fileName,
            progress: progress,
          ));
        },
      );

      if (result.isSuccess) {
        emit(ChatActionSuccess(result.message, actionType: 'sendFile'));

        // Mark message as sent using read receipt service
        if (result.messageId != null) {
          await ReadReceiptService.instance.markMessageAsSent(
            conversationId: event.conversationId,
            messageId: result.messageId!,
            senderId: event.senderId,
          );
        }

        // Send push notification to conversation participants
        await _sendNotificationToParticipants(
          conversationId: event.conversationId,
          senderName: event.senderName,
          messageContent: event.fileName,
          messageType: event.messageType,
        );
      } else {
        emit(ChatError(result.message, failedEvent: event));
      }
    } catch (e) {
      emit(ChatError('Fout bij verzenden bestand: ${e.toString()}', failedEvent: event));
    }
  }

  /// Mark message as read
  Future<void> _onMarkMessageAsRead(MarkMessageAsRead event, Emitter<ChatState> emit) async {
    try {
      final result = await _getMessagesUseCase.markMessageAsRead(
        event.conversationId,
        event.messageId,
        event.userId,
      );

      if (result.isSuccess) {
        // Also update using read receipt service for enhanced tracking
        await ReadReceiptService.instance.markMessageAsRead(
          conversationId: event.conversationId,
          messageId: event.messageId,
          readerId: event.userId,
        );
      } else {
        emit(ChatError(result.message));
      }
    } catch (e) {
      emit(ChatError('Fout bij markeren als gelezen: ${e.toString()}'));
    }
  }

  /// Mark all messages as read
  Future<void> _onMarkAllMessagesAsRead(MarkAllMessagesAsRead event, Emitter<ChatState> emit) async {
    try {
      final currentState = state;
      if (currentState is ConversationSelected) {
        final result = await _getMessagesUseCase.markAllMessagesAsRead(
          event.conversationId,
          event.userId,
          currentState.messages,
        );

        if (result.isSuccess) {
          emit(ChatActionSuccess(result.message, actionType: 'markAllRead'));

          // Also update using read receipt service for enhanced tracking
          await ReadReceiptService.instance.markAllMessagesAsRead(
            conversationId: event.conversationId,
            readerId: event.userId,
          );
        } else {
          emit(ChatError(result.message));
        }
      }
    } catch (e) {
      emit(ChatError('Fout bij markeren berichten: ${e.toString()}'));
    }
  }

  /// Start typing indicator
  Future<void> _onStartTyping(StartTyping event, Emitter<ChatState> emit) async {
    try {
      // Use both repository and presence service for redundancy
      await _repository.setTypingStatus(
        event.conversationId,
        event.userId,
        event.userName,
        true,
      );

      await PresenceService.instance.setTypingStatus(
        conversationId: event.conversationId,
        isTyping: true,
      );
    } catch (e) {
      // Typing indicators are not critical, so we don't emit error
      debugPrint('Error starting typing indicator: $e');
    }
  }

  /// Stop typing indicator
  Future<void> _onStopTyping(StopTyping event, Emitter<ChatState> emit) async {
    try {
      // Use both repository and presence service for redundancy
      await _repository.setTypingStatus(
        event.conversationId,
        event.userId,
        event.userName,
        false,
      );

      await PresenceService.instance.setTypingStatus(
        conversationId: event.conversationId,
        isTyping: false,
      );
    } catch (e) {
      // Typing indicators are not critical, so we don't emit error
      debugPrint('Error stopping typing indicator: $e');
    }
  }

  /// Watch typing status for real-time indicators
  Future<void> _onWatchTypingStatus(WatchTypingStatus event, Emitter<ChatState> emit) async {
    await _typingSubscription?.cancel();

    _typingSubscription = _repository
        .watchTypingStatus(event.conversationId)
        .listen(
          (typingUsers) {
            final currentState = state;
            if (currentState is ConversationSelected) {
              emit(currentState.copyWith(typingUsers: typingUsers));
            }
          },
          onError: (error) {
            // Typing indicators are not critical, so we don't emit error
          },
        );
  }

  /// Search conversations
  Future<void> _onSearchConversations(SearchConversations event, Emitter<ChatState> emit) async {
    try {
      final result = await _getConversationsUseCase.searchConversations(
        event.userId,
        event.query,
      );

      if (result.isSuccess) {
        emit(SearchResultsLoaded(
          query: event.query,
          conversationResults: result.conversations!,
        ));
      } else {
        emit(ChatError(result.message));
      }
    } catch (e) {
      emit(ChatError('Fout bij zoeken: ${e.toString()}'));
    }
  }

  /// Search messages in current conversation
  Future<void> _onSearchMessages(SearchMessages event, Emitter<ChatState> emit) async {
    try {
      final result = await _getMessagesUseCase.searchMessagesInConversation(
        event.conversationId,
        event.query,
      );

      if (result.isSuccess) {
        emit(SearchResultsLoaded(
          query: event.query,
          messageResults: result.messages!,
        ));
      } else {
        emit(ChatError(result.message));
      }
    } catch (e) {
      emit(ChatError('Fout bij zoeken berichten: ${e.toString()}'));
    }
  }

  /// Load more messages (pagination)
  Future<void> _onLoadMoreMessages(LoadMoreMessages event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is! ConversationSelected || currentState.isLoadingMessages) {
      return;
    }

    emit(currentState.copyWith(isLoadingMessages: true));

    try {
      final lastMessage = currentState.messages.isNotEmpty 
          ? currentState.messages.last 
          : null;

      final result = await _getMessagesUseCase.getMessages(
        event.conversationId,
        lastMessage: lastMessage,
      );

      if (result.isSuccess) {
        final allMessages = [...currentState.messages, ...result.messages!];
        emit(currentState.copyWith(
          messages: allMessages,
          hasMoreMessages: result.hasMore,
          isLoadingMessages: false,
        ));
      } else {
        emit(currentState.copyWith(
          isLoadingMessages: false,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        isLoadingMessages: false,
        error: 'Fout bij laden meer berichten: ${e.toString()}',
      ));
    }
  }

  /// Refresh conversations
  /// Refresh conversations - Using mockup data for testing
  Future<void> _onRefreshConversations(RefreshConversations event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is ConversationsLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    }

    try {
      // Add small delay to simulate network request
      await Future.delayed(const Duration(milliseconds: 600));

      // Use mockup data for testing
      final conversations = ChatMockupService.generateMockConversations();
      final totalUnreadCount = ChatMockupService.getTotalUnreadCount(conversations);

      emit(ConversationsLoaded(
        userId: event.userId,
        conversations: conversations,
        totalUnreadCount: totalUnreadCount,
        isRefreshing: false,
      ));

      // TODO: Replace with real implementation when ready
      // final result = await _getConversationsUseCase.getConversations(event.userId);
      // if (result.isSuccess) {
      //   emit(ConversationsLoaded(
      //     userId: event.userId,
      //     conversations: result.conversations!,
      //     totalUnreadCount: result.totalUnreadCount,
      //     isRefreshing: false,
      //   ));
      // } else {
      //   if (currentState is ConversationsLoaded) {
      //     emit(currentState.copyWith(isRefreshing: false));
      //   }
      //   emit(ChatError(result.message));
      // }
    } catch (e) {
      if (currentState is ConversationsLoaded) {
        emit(currentState.copyWith(isRefreshing: false));
      }
      emit(ChatError('Fout bij verversen: ${e.toString()}'));
    }
  }

  /// Sync offline messages
  Future<void> _onSyncOfflineMessages(SyncOfflineMessages event, Emitter<ChatState> emit) async {
    try {
      final offlineMessages = await _repository.getOfflineMessages();
      
      if (offlineMessages.isNotEmpty) {
        emit(OfflineMessagesSyncing(offlineMessages.length));
        
        final success = await _repository.syncOfflineMessages();
        
        if (success) {
          emit(OfflineMessagesSynced(offlineMessages.length));
        } else {
          emit(ChatError('Fout bij synchroniseren offline berichten'));
        }
      }
    } catch (e) {
      emit(ChatError('Fout bij sync: ${e.toString()}'));
    }
  }

  /// Clear error state
  void _onClearError(ClearError event, Emitter<ChatState> emit) {
    if (_currentUserId != null) {
      add(LoadConversations(_currentUserId!));
    } else {
      emit(const ChatInitial());
    }
  }

  /// Reset chat to initial state
  void _onResetChat(ResetChat event, Emitter<ChatState> emit) {
    _cancelSubscriptions();
    _currentUserId = null;
    emit(const ChatInitial());
  }

  /// Cancel all active subscriptions
  void _cancelSubscriptions() {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
  }

  /// Send push notifications to conversation participants
  Future<void> _sendNotificationToParticipants({
    required String conversationId,
    required String senderName,
    required String messageContent,
    required MessageType messageType,
  }) async {
    try {
      // Get conversation details to find participants
      final conversation = await _repository.getConversation(conversationId);
      if (conversation == null) return;

      // Send notification to each participant except the sender
      for (final participant in conversation.participants.values) {
        if (participant.userId != _currentUserId && participant.isActive) {
          await NotificationService.instance.sendMessageNotification(
            recipientUserId: participant.userId,
            senderName: senderName,
            messageContent: messageContent,
            conversationId: conversationId,
            messageId: DateTime.now().millisecondsSinceEpoch.toString(),
            messageType: messageType,
          );
        }
      }
    } catch (e) {
      // Notification failures shouldn't break the chat flow
      debugPrint('Error sending notifications: $e');
    }
  }

  // Enhanced Message Operations
  
  /// Edit message with Dutch business rule validation
  Future<void> _onEditMessage(EditMessage event, Emitter<ChatState> emit) async {
    try {
      final success = await _repository.editMessage(
        event.conversationId,
        event.messageId,
        event.newContent,
        event.userId,
      );
      
      if (success) {
        emit(ChatActionSuccess(
          'Bericht succesvol bewerkt',
          actionType: 'editMessage',
        ));
      } else {
        emit(ChatError('Kon bericht niet bewerken'));
      }
    } catch (e) {
      emit(ChatError('Fout bij bewerken bericht: ${e.toString()}'));
    }
  }
  
  /// Delete message with audit trail
  Future<void> _onDeleteMessage(DeleteMessage event, Emitter<ChatState> emit) async {
    try {
      final success = await _repository.deleteMessage(
        event.conversationId,
        event.messageId,
        event.userId,
        softDelete: event.softDelete,
      );
      
      if (success) {
        emit(ChatActionSuccess(
          'Bericht succesvol verwijderd',
          actionType: 'deleteMessage',
        ));
      } else {
        emit(ChatError('Kon bericht niet verwijderen'));
      }
    } catch (e) {
      emit(ChatError('Fout bij verwijderen bericht: ${e.toString()}'));
    }
  }
  
  /// Add reaction to message
  Future<void> _onAddMessageReaction(AddMessageReaction event, Emitter<ChatState> emit) async {
    try {
      final success = await _repository.addMessageReaction(
        event.conversationId,
        event.messageId,
        event.reaction,
        event.userId,
      );
      
      if (success) {
        emit(ChatActionSuccess(
          'Reactie toegevoegd',
          actionType: 'addReaction',
        ));
      } else {
        emit(ChatError('Kon reactie niet toevoegen'));
      }
    } catch (e) {
      emit(ChatError('Fout bij toevoegen reactie: ${e.toString()}'));
    }
  }
  
  /// Remove reaction from message
  Future<void> _onRemoveMessageReaction(RemoveMessageReaction event, Emitter<ChatState> emit) async {
    try {
      final success = await _repository.removeMessageReaction(
        event.conversationId,
        event.messageId,
        event.reaction,
        event.userId,
      );
      
      if (success) {
        emit(ChatActionSuccess(
          'Reactie verwijderd',
          actionType: 'removeReaction',
        ));
      } else {
        emit(ChatError('Kon reactie niet verwijderen'));
      }
    } catch (e) {
      emit(ChatError('Fout bij verwijderen reactie: ${e.toString()}'));
    }
  }
  
  /// Get message edit history
  Future<void> _onGetMessageEditHistory(GetMessageEditHistory event, Emitter<ChatState> emit) async {
    try {
      final history = await _repository.getMessageEditHistory(
        event.conversationId,
        event.messageId,
      );
      
      emit(MessageEditHistoryLoaded(
        messageId: event.messageId,
        editHistory: history,
      ));
    } catch (e) {
      emit(ChatError('Fout bij laden bewerkingsgeschiedenis: ${e.toString()}'));
    }
  }
  
  // Enhanced Conversation Operations
  
  /// Unarchive conversation
  Future<void> _onUnarchiveConversation(UnarchiveConversation event, Emitter<ChatState> emit) async {
    try {
      final success = await _repository.unarchiveConversation(
        event.conversationId,
        event.userId,
      );
      
      if (success) {
        emit(ChatActionSuccess(
          'Gesprek uit archief gehaald',
          actionType: 'unarchiveConversation',
        ));
      } else {
        emit(ChatError('Kon gesprek niet uit archief halen'));
      }
    } catch (e) {
      emit(ChatError('Fout bij uit archief halen: ${e.toString()}'));
    }
  }
  
  /// Mute conversation
  Future<void> _onMuteConversation(MuteConversation event, Emitter<ChatState> emit) async {
    try {
      final success = await _repository.muteConversation(
        event.conversationId,
        event.userId,
        until: event.until,
      );
      
      if (success) {
        final message = event.until != null
            ? 'Gesprek gedempt tot ${event.until!.day}/${event.until!.month}'
            : 'Gesprek gedempt';
        emit(ChatActionSuccess(message, actionType: 'muteConversation'));
      } else {
        emit(ChatError('Kon gesprek niet dempen'));
      }
    } catch (e) {
      emit(ChatError('Fout bij dempen gesprek: ${e.toString()}'));
    }
  }
  
  /// Unmute conversation
  Future<void> _onUnmuteConversation(UnmuteConversation event, Emitter<ChatState> emit) async {
    try {
      final success = await _repository.unmuteConversation(
        event.conversationId,
        event.userId,
      );
      
      if (success) {
        emit(ChatActionSuccess(
          'Gesprek niet meer gedempt',
          actionType: 'unmuteConversation',
        ));
      } else {
        emit(ChatError('Kon gesprek niet ontdempen'));
      }
    } catch (e) {
      emit(ChatError('Fout bij ontdempen gesprek: ${e.toString()}'));
    }
  }
  
  // Enhanced Search Operations
  
  /// Search messages with advanced filters and Dutch language support
  Future<void> _onSearchMessagesWithFilters(SearchMessagesWithFilters event, Emitter<ChatState> emit) async {
    emit(MessageSearchLoading(event.query));
    
    try {
      final result = await MessageSearchService.instance.searchMessages(
        query: event.query,
        userId: event.userId,
        conversationId: event.conversationId,
        messageType: event.messageType,
        fromDate: event.fromDate,
        toDate: event.toDate,
        limit: event.limit,
      );
      
      if (result.success) {
        emit(MessageSearchResultsLoaded(
          query: event.query,
          results: result.results,
          totalResults: result.totalResults,
          highlights: result.getHighlights(),
        ));
      } else {
        emit(ChatError(result.error ?? 'Zoeken mislukt'));
      }
    } catch (e) {
      emit(ChatError('Fout bij geavanceerd zoeken: ${e.toString()}'));
    }
  }
  
  // File Attachment Operations
  
  /// Upload file with comprehensive security validation
  Future<void> _onUploadSecureFile(UploadSecureFile event, Emitter<ChatState> emit) async {
    emit(SecureFileUploading(
      conversationId: event.conversationId,
      fileName: event.customFileName ?? 'Bestand',
      progress: 0.0,
    ));
    
    try {
      final result = await FileAttachmentService.instance.uploadSecureFile(
        filePath: event.filePath,
        conversationId: event.conversationId,
        userId: event.userId,
        customFileName: event.customFileName,
        generateThumbnail: event.generateThumbnail,
      );
      
      if (result.success) {
        emit(SecureFileUploaded(
          conversationId: event.conversationId,
          fileName: result.fileName!,
          downloadUrl: result.downloadUrl!,
          thumbnailUrl: result.thumbnailUrl,
        ));
      } else {
        emit(ChatError(result.error ?? 'Bestand uploaden mislukt'));
      }
    } catch (e) {
      emit(ChatError('Fout bij veilig uploaden: ${e.toString()}'));
    }
  }
  
  /// Download file securely
  Future<void> _onDownloadSecureFile(DownloadSecureFile event, Emitter<ChatState> emit) async {
    emit(SecureFileDownloading(event.fileUrl));
    
    try {
      final result = await FileAttachmentService.instance.downloadSecureFile(
        fileUrl: event.fileUrl,
        userId: event.userId,
        localPath: event.localPath,
      );
      
      if (result.success) {
        emit(SecureFileDownloaded(
          fileUrl: event.fileUrl,
          localPath: result.localPath!,
        ));
      } else {
        emit(ChatError(result.error ?? 'Bestand downloaden mislukt'));
      }
    } catch (e) {
      emit(ChatError('Fout bij veilig downloaden: ${e.toString()}'));
    }
  }
  
  /// Delete file securely
  Future<void> _onDeleteSecureFile(DeleteSecureFile event, Emitter<ChatState> emit) async {
    try {
      final success = await FileAttachmentService.instance.deleteSecureFile(
        event.fileUrl,
        event.userId,
      );
      
      if (success) {
        emit(ChatActionSuccess(
          'Bestand veilig verwijderd',
          actionType: 'deleteSecureFile',
        ));
      } else {
        emit(ChatError('Kon bestand niet veilig verwijderen'));
      }
    } catch (e) {
      emit(ChatError('Fout bij veilig verwijderen bestand: ${e.toString()}'));
    }
  }
  
  // GDPR Compliance Operations
  
  /// Export user chat data for GDPR compliance
  Future<void> _onExportUserChatData(ExportUserChatData event, Emitter<ChatState> emit) async {
    emit(GDPRExportInProgress(event.userId, event.format));
    
    try {
      final success = await GDPRComplianceService.instance.exportUserChatData(
        event.userId,
        event.format,
      );
      
      if (success) {
        emit(GDPRExportCompleted(
          userId: event.userId,
          format: event.format,
          message: 'Gegevens succesvol geëxporteerd in ${event.format.toUpperCase()} formaat',
        ));
      } else {
        emit(ChatError('Kon gegevens niet exporteren'));
      }
    } catch (e) {
      emit(ChatError('Fout bij exporteren gegevens: ${e.toString()}'));
    }
  }
  
  /// Delete user chat data (Right to be forgotten)
  Future<void> _onDeleteUserChatData(DeleteUserChatData event, Emitter<ChatState> emit) async {
    emit(GDPRDeletionInProgress(event.userId));
    
    try {
      final success = await GDPRComplianceService.instance.deleteUserChatData(
        event.userId,
      );
      
      if (success) {
        emit(GDPRDeletionCompleted(
          userId: event.userId,
          message: 'Alle chatgegevens succesvol verwijderd (30 dagen bewaarperiode van kracht)',
        ));
      } else {
        emit(ChatError('Kon chatgegevens niet verwijderen'));
      }
    } catch (e) {
      emit(ChatError('Fout bij verwijderen chatgegevens: ${e.toString()}'));
    }
  }
  
  /// Get data retention report
  Future<void> _onGetDataRetentionReport(GetDataRetentionReport event, Emitter<ChatState> emit) async {
    emit(DataRetentionReportLoading(event.userId));
    
    try {
      final report = await GDPRComplianceService.instance.getChatDataRetentionReport(
        event.userId,
      );
      
      emit(DataRetentionReportLoaded(
        userId: event.userId,
        report: report,
      ));
    } catch (e) {
      emit(ChatError('Fout bij laden retentierapport: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
