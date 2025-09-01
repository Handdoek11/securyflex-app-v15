import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/typing_status_model.dart';

/// Remote data source for chat operations using Firebase
/// Implements WhatsApp-quality real-time messaging with offline support
class ChatRemoteDataSource {
  static ChatRemoteDataSource? _instance;
  static ChatRemoteDataSource get instance {
    _instance ??= ChatRemoteDataSource._();
    return _instance!;
  }

  ChatRemoteDataSource._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  CollectionReference get _conversationsRef => _firestore.collection('conversations');
  CollectionReference get _usersRef => _firestore.collection('users');

  /// Get conversations for a user with real-time updates
  Stream<List<ConversationModel>> watchUserConversations(String userId) {
    return _conversationsRef
        .where('participants.$userId.isActive', isEqualTo: true)
        .where('isArchived', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConversationModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Get conversations for a user (one-time fetch)
  Future<List<ConversationModel>> getUserConversations(String userId) async {
    final snapshot = await _conversationsRef
        .where('participants.$userId.isActive', isEqualTo: true)
        .where('isArchived', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => ConversationModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// Get single conversation with real-time updates
  Stream<ConversationModel> watchConversation(String conversationId) {
    return _conversationsRef
        .doc(conversationId)
        .snapshots()
        .map((doc) => ConversationModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id));
  }

  /// Get messages for a conversation with pagination
  Future<List<MessageModel>> getMessages(String conversationId,
      {int limit = 20, DocumentSnapshot? lastDocument}) async {
    Query query = _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => MessageModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// Watch messages for real-time updates
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(
                doc.data(), doc.id))
            .toList());
  }

  /// Send a message with delivery tracking
  Future<String> sendMessage(MessageModel message) async {
    final messageRef = _conversationsRef
        .doc(message.conversationId)
        .collection('messages')
        .doc();

    final messageData = message.copyWith(messageId: messageRef.id);

    // Use batch write for atomic operations
    final batch = _firestore.batch();

    // Add message
    batch.set(messageRef, messageData.toMap());

    // Update conversation last message and timestamp
    final conversationRef = _conversationsRef.doc(message.conversationId);
    batch.update(conversationRef, {
      'lastMessage': LastMessagePreview(
        messageId: messageRef.id,
        senderId: message.senderId,
        senderName: message.senderName,
        content: message.content,
        messageType: message.messageType,
        timestamp: message.timestamp,
        deliveryStatus: MessageDeliveryStatus.sent,
      ).toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
    return messageRef.id;
  }

  /// Update message delivery status
  Future<bool> updateMessageDeliveryStatus(String conversationId,
      String messageId, String userId, MessageDeliveryStatus status) async {
    try {
      final messageRef = _conversationsRef
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);

      await messageRef.update({
        'deliveryStatus.$userId': UserDeliveryStatus(
          userId: userId,
          status: status,
          timestamp: DateTime.now(),
        ).toMap(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark message as read
  Future<bool> markMessageAsRead(
      String conversationId, String messageId, String userId) async {
    try {
      final messageRef = _conversationsRef
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);

      await messageRef.update({
        'readStatus.$userId': Timestamp.fromDate(DateTime.now()),
      });

      // Update delivery status to read
      await updateMessageDeliveryStatus(
          conversationId, messageId, userId, MessageDeliveryStatus.read);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create a new conversation
  Future<String> createConversation(ConversationModel conversation) async {
    final conversationRef = _conversationsRef.doc();
    final conversationData = conversation.copyWith(
      conversationId: conversationRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await conversationRef.set(conversationData.toMap());
    return conversationRef.id;
  }

  /// Update typing status with auto-cleanup
  Future<bool> setTypingStatus(String conversationId, String userId,
      String userName, bool isTyping) async {
    try {
      final typingRef = _conversationsRef
          .doc(conversationId)
          .collection('typing')
          .doc(userId);

      if (isTyping) {
        await typingRef.set(TypingStatusModel(
          userId: userId,
          userName: userName,
          conversationId: conversationId,
          isTyping: true,
          timestamp: DateTime.now(),
        ).toMap());

        // Auto-cleanup after 10 seconds
        Timer(const Duration(seconds: 10), () async {
          await typingRef.delete();
        });
      } else {
        await typingRef.delete();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Watch typing status for real-time indicators
  Stream<List<TypingStatusModel>> watchTypingStatus(String conversationId) {
    return _conversationsRef
        .doc(conversationId)
        .collection('typing')
        .where('isTyping', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TypingStatusModel.fromMap(
                doc.data()))
            .where((typing) => typing.isValid) // Filter out expired typing status
            .toList());
  }

  /// Upload file to Firebase Storage
  Future<String> uploadFile(
      String filePath, String fileName, String conversationId) async {
    final file = File(filePath);
    final storageRef = _storage
        .ref()
        .child('chat-files')
        .child(conversationId)
        .child(fileName);

    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Update user presence
  Future<bool> updateUserPresence(String userId, bool isOnline) async {
    try {
      await _usersRef.doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Watch user presence
  Stream<UserPresenceModel> watchUserPresence(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return UserPresenceModel.fromMap(data);
    });
  }

  /// Search messages across conversations
  Future<List<MessageModel>> searchMessages(String query, String userId) async {
    // Note: This is a simplified search. In production, you'd use
    // Algolia or Elasticsearch for better full-text search
    final conversations = await _conversationsRef
        .where('participants.$userId.isActive', isEqualTo: true)
        .get();

    final List<MessageModel> results = [];

    for (final conversationDoc in conversations.docs) {
      final messagesSnapshot = await conversationDoc.reference
          .collection('messages')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThan: '$query\uf8ff')
          .limit(10)
          .get();

      results.addAll(messagesSnapshot.docs.map((doc) =>
          MessageModel.fromMap(doc.data(), doc.id)));
    }

    return results;
  }

  /// Get conversation by ID
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      final doc = await _conversationsRef.doc(conversationId).get();
      if (doc.exists) {
        return ConversationModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Archive conversation
  Future<bool> archiveConversation(String conversationId, String userId) async {
    try {
      await _conversationsRef.doc(conversationId).update({
        'participants.$userId.isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
