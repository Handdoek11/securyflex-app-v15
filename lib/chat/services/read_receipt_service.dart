import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../../unified_design_tokens.dart';

/// WhatsApp-style read receipt service for SecuryFlex Chat
/// Manages message delivery status with single/double/blue tick system
class ReadReceiptService {
  static final ReadReceiptService _instance = ReadReceiptService._internal();
  factory ReadReceiptService() => _instance;
  ReadReceiptService._internal();

  static ReadReceiptService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  


  /// Mark message as sent (single tick ✓)
  Future<void> markMessageAsSent({
    required String conversationId,
    required String messageId,
    required String senderId,
  }) async {
    try {
      await _updateMessageDeliveryStatus(
        conversationId: conversationId,
        messageId: messageId,
        userId: senderId,
        status: MessageDeliveryStatus.sent,
      );
      
      debugPrint('Message marked as sent: $messageId');
    } catch (e) {
      debugPrint('Error marking message as sent: $e');
    }
  }

  /// Mark message as delivered (double tick ✓✓)
  Future<void> markMessageAsDelivered({
    required String conversationId,
    required String messageId,
    required String recipientId,
  }) async {
    try {
      await _updateMessageDeliveryStatus(
        conversationId: conversationId,
        messageId: messageId,
        userId: recipientId,
        status: MessageDeliveryStatus.delivered,
      );
      
      debugPrint('Message marked as delivered: $messageId for user: $recipientId');
    } catch (e) {
      debugPrint('Error marking message as delivered: $e');
    }
  }

  /// Mark message as read (blue tick ✓✓)
  Future<void> markMessageAsRead({
    required String conversationId,
    required String messageId,
    required String readerId,
  }) async {
    try {
      await _updateMessageDeliveryStatus(
        conversationId: conversationId,
        messageId: messageId,
        userId: readerId,
        status: MessageDeliveryStatus.read,
      );
      
      debugPrint('Message marked as read: $messageId by user: $readerId');
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// Mark multiple messages as read (batch operation)
  Future<void> markMessagesAsRead({
    required String conversationId,
    required List<String> messageIds,
    required String readerId,
  }) async {
    if (messageIds.isEmpty) return;

    try {
      final batch = _firestore.batch();
      
      for (final messageId in messageIds) {
        final messageRef = _firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .doc(messageId);
        
        batch.update(messageRef, {
          'deliveryStatus.$readerId': {
            'userId': readerId,
            'status': MessageDeliveryStatus.read.name,
            'timestamp': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      debugPrint('Batch marked ${messageIds.length} messages as read by user: $readerId');
    } catch (e) {
      debugPrint('Error batch marking messages as read: $e');
    }
  }

  /// Mark all messages in conversation as read
  Future<void> markAllMessagesAsRead({
    required String conversationId,
    required String readerId,
  }) async {
    try {
      // Get unread messages for this user
      final unreadMessages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: readerId)
          .orderBy('senderId')
          .orderBy('createdAt', descending: true)
          .limit(50) // Limit to recent messages for performance
          .get();
      
      if (unreadMessages.docs.isEmpty) return;
      
      final messageIds = <String>[];
      for (final doc in unreadMessages.docs) {
        final data = doc.data();
        final deliveryStatus = data['deliveryStatus'] as Map<String, dynamic>? ?? {};
        final userStatus = deliveryStatus[readerId] as Map<String, dynamic>?;
        
        // Only mark as read if not already read
        if (userStatus == null || userStatus['status'] != MessageDeliveryStatus.read.name) {
          messageIds.add(doc.id);
        }
      }
      
      if (messageIds.isNotEmpty) {
        await markMessagesAsRead(
          conversationId: conversationId,
          messageIds: messageIds,
          readerId: readerId,
        );
      }
    } catch (e) {
      debugPrint('Error marking all messages as read: $e');
    }
  }

  /// Update message delivery status
  Future<void> _updateMessageDeliveryStatus({
    required String conversationId,
    required String messageId,
    required String userId,
    required MessageDeliveryStatus status,
  }) async {
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);
    
    await messageRef.update({
      'deliveryStatus.$userId': {
        'userId': userId,
        'status': status.name,
        'timestamp': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Auto-mark messages as delivered when user comes online
  Future<void> markMessagesAsDeliveredForUser({
    required String conversationId,
    required String userId,
  }) async {
    try {
      // Get recent messages not yet delivered to this user
      final undeliveredMessages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .orderBy('senderId')
          .orderBy('createdAt', descending: true)
          .limit(20) // Recent messages only
          .get();
      
      final batch = _firestore.batch();
      int updateCount = 0;
      
      for (final doc in undeliveredMessages.docs) {
        final data = doc.data();
        final deliveryStatus = data['deliveryStatus'] as Map<String, dynamic>? ?? {};
        final userStatus = deliveryStatus[userId] as Map<String, dynamic>?;
        
        // Mark as delivered if not already delivered or read
        if (userStatus == null || 
            (userStatus['status'] != MessageDeliveryStatus.delivered.name &&
             userStatus['status'] != MessageDeliveryStatus.read.name)) {
          
          batch.update(doc.reference, {
            'deliveryStatus.$userId': {
              'userId': userId,
              'status': MessageDeliveryStatus.delivered.name,
              'timestamp': FieldValue.serverTimestamp(),
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });
          updateCount++;
        }
      }
      
      if (updateCount > 0) {
        await batch.commit();
        debugPrint('Auto-marked $updateCount messages as delivered for user: $userId');
      }
    } catch (e) {
      debugPrint('Error auto-marking messages as delivered: $e');
    }
  }

  /// Get read receipt icon for message status
  Widget getReadReceiptIcon(MessageDeliveryStatus status, {Color? color}) {
    final iconColor = color ?? Colors.grey;
    
    switch (status) {
      case MessageDeliveryStatus.sending:
        return Icon(
          Icons.schedule,
          size: 16,
          color: iconColor.withValues(alpha: 0.6),
        );
      case MessageDeliveryStatus.sent:
        return Icon(
          Icons.check,
          size: 16,
          color: iconColor,
        );
      case MessageDeliveryStatus.delivered:
        return Stack(
          children: [
            Icon(
              Icons.check,
              size: 16,
              color: iconColor,
            ),
            Positioned(
              left: 4,
              child: Icon(
                Icons.check,
                size: 16,
                color: iconColor,
              ),
            ),
          ],
        );
      case MessageDeliveryStatus.read:
        return Stack(
          children: [
            Icon(
              Icons.check,
              size: 16,
              color: DesignTokens.statusAccepted,
            ),
            Positioned(
              left: 4,
              child: Icon(
                Icons.check,
                size: 16,
                color: DesignTokens.statusAccepted,
              ),
            ),
          ],
        );
      case MessageDeliveryStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 16,
          color: DesignTokens.statusCancelled,
        );
    }
  }

  /// Get read receipt text in Dutch
  String getReadReceiptText(MessageDeliveryStatus status) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return 'Verzenden...';
      case MessageDeliveryStatus.sent:
        return 'Verzonden';
      case MessageDeliveryStatus.delivered:
        return 'Bezorgd';
      case MessageDeliveryStatus.read:
        return 'Gelezen';
      case MessageDeliveryStatus.failed:
        return 'Mislukt';
    }
  }

  /// Get detailed read receipt info for message
  String getDetailedReadReceiptInfo(MessageModel message) {
    final deliveryStatus = message.deliveryStatus;
    if (deliveryStatus.isEmpty) {
      return 'Geen bezorgingsinformatie beschikbaar';
    }
    
    final info = <String>[];
    
    for (final userStatus in deliveryStatus.values) {
      final statusText = getReadReceiptText(userStatus.status);
      final timeText = _formatTimestamp(userStatus.timestamp);
      info.add('${userStatus.userId}: $statusText om $timeText');
    }
    
    return info.join('\n');
  }

  /// Format timestamp for read receipts
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'net';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m geleden';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['ma', 'di', 'wo', 'do', 'vr', 'za', 'zo'];
      return '${weekdays[timestamp.weekday - 1]} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Watch read receipts for a conversation
  Stream<Map<String, MessageDeliveryStatus>> watchConversationReadReceipts(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final readReceipts = <String, MessageDeliveryStatus>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final messageId = doc.id;
        
        // Get overall delivery status for this message
        final deliveryStatus = data['deliveryStatus'] as Map<String, dynamic>? ?? {};
        final statuses = deliveryStatus.values
            .map((status) => MessageDeliveryStatus.values.firstWhere(
                  (e) => e.name == status['status'],
                  orElse: () => MessageDeliveryStatus.sent,
                ))
            .toList();
        
        // Determine overall status
        MessageDeliveryStatus overallStatus = MessageDeliveryStatus.sending;
        if (statuses.any((s) => s == MessageDeliveryStatus.read)) {
          overallStatus = MessageDeliveryStatus.read;
        } else if (statuses.every((s) => s == MessageDeliveryStatus.delivered || s == MessageDeliveryStatus.read)) {
          overallStatus = MessageDeliveryStatus.delivered;
        } else if (statuses.any((s) => s == MessageDeliveryStatus.sent || s == MessageDeliveryStatus.delivered)) {
          overallStatus = MessageDeliveryStatus.sent;
        }
        
        readReceipts[messageId] = overallStatus;
      }
      
      return readReceipts;
    });
  }

  /// Dispose resources
  void dispose() {
    debugPrint('ReadReceiptService disposed');
  }
}
