import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import 'auto_chat_service.dart';
import 'notification_service.dart';

/// Assignment integration service for SecuryFlex Chat
/// Handles assignment-related chat automation and notifications
class AssignmentIntegrationService {
  static final AssignmentIntegrationService _instance = AssignmentIntegrationService._internal();
  factory AssignmentIntegrationService() => _instance;
  AssignmentIntegrationService._internal();

  static AssignmentIntegrationService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _assignmentSubscription;
  
  bool _isInitialized = false;

  /// Initialize assignment integration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Start watching for assignment status changes
      _startAssignmentWatcher();
      
      _isInitialized = true;
      debugPrint('AssignmentIntegrationService initialized');
    } catch (e) {
      debugPrint('Error initializing AssignmentIntegrationService: $e');
    }
  }

  /// Start watching assignment status changes
  void _startAssignmentWatcher() {
    _assignmentSubscription?.cancel();
    
    // Watch for assignment status changes
    _assignmentSubscription = _firestore
        .collection('assignments')
        .where('status', whereIn: ['accepted', 'started', 'completed', 'cancelled'])
        .snapshots()
        .listen(
          _handleAssignmentChanges,
          onError: (error) {
            debugPrint('Error watching assignments: $error');
          },
        );
  }

  /// Handle assignment status changes
  Future<void> _handleAssignmentChanges(QuerySnapshot snapshot) async {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
        final data = change.doc.data() as Map<String, dynamic>;
        final assignmentId = change.doc.id;
        final status = data['status'] as String?;
        final previousStatus = data['previousStatus'] as String?;
        
        // Only process if status actually changed
        if (status != null && status != previousStatus) {
          await _processAssignmentStatusChange(assignmentId, data, status, previousStatus);
        }
      }
    }
  }

  /// Process assignment status change
  Future<void> _processAssignmentStatusChange(
    String assignmentId,
    Map<String, dynamic> assignmentData,
    String newStatus,
    String? previousStatus,
  ) async {
    try {
      debugPrint('Processing assignment status change: $assignmentId -> $newStatus');

      switch (newStatus.toLowerCase()) {
        case 'accepted':
          await _handleAssignmentAccepted(assignmentId, assignmentData);
          break;
        case 'started':
          await _handleAssignmentStarted(assignmentId, assignmentData);
          break;
        case 'completed':
          await _handleAssignmentCompleted(assignmentId, assignmentData);
          break;
        case 'cancelled':
          await _handleAssignmentCancelled(assignmentId, assignmentData);
          break;
      }
    } catch (e) {
      debugPrint('Error processing assignment status change: $e');
    }
  }

  /// Handle assignment accepted
  Future<void> _handleAssignmentAccepted(String assignmentId, Map<String, dynamic> data) async {
    try {
      // Check if conversation already exists
      final existingConversation = await AutoChatService.instance.getConversationForAssignment(assignmentId);
      if (existingConversation != null) {
        debugPrint('Conversation already exists for assignment: $assignmentId');
        return;
      }

      // Extract assignment details
      final title = data['title'] as String? ?? 'Beveiligingsopdracht';
      final guardId = data['guardId'] as String? ?? '';
      final guardName = data['guardName'] as String? ?? 'Beveiliger';
      final companyId = data['companyId'] as String? ?? '';
      final companyName = data['companyName'] as String? ?? 'Bedrijf';
      final location = data['location'] as String? ?? 'Locatie onbekend';
      
      // Parse assignment date
      DateTime assignmentDate = DateTime.now();
      if (data['startDate'] != null) {
        if (data['startDate'] is Timestamp) {
          assignmentDate = (data['startDate'] as Timestamp).toDate();
        } else if (data['startDate'] is String) {
          assignmentDate = DateTime.tryParse(data['startDate']) ?? DateTime.now();
        }
      }

      // Create auto-chat conversation
      final conversationId = await AutoChatService.instance.createAssignmentConversation(
        assignmentId: assignmentId,
        assignmentTitle: title,
        guardId: guardId,
        guardName: guardName,
        companyId: companyId,
        companyName: companyName,
        assignmentDate: assignmentDate,
        assignmentLocation: location,
      );

      if (conversationId != null) {
        // Send notifications to participants
        await _sendAssignmentNotifications(
          guardId: guardId,
          companyId: companyId,
          assignmentTitle: title,
          conversationId: conversationId,
          notificationType: 'assignment_accepted',
        );
        
        debugPrint('Auto-chat created for accepted assignment: $assignmentId');
      }
    } catch (e) {
      debugPrint('Error handling assignment accepted: $e');
    }
  }

  /// Handle assignment started
  Future<void> _handleAssignmentStarted(String assignmentId, Map<String, dynamic> data) async {
    try {
      final conversationId = await AutoChatService.instance.getConversationForAssignment(assignmentId);
      if (conversationId == null) return;

      final updatedBy = data['updatedBy'] as String? ?? 'Systeem';
      
      await AutoChatService.instance.sendAssignmentStatusUpdate(
        conversationId: conversationId,
        status: 'started',
        updatedBy: updatedBy,
      );
      
      debugPrint('Assignment started notification sent: $assignmentId');
    } catch (e) {
      debugPrint('Error handling assignment started: $e');
    }
  }

  /// Handle assignment completed
  Future<void> _handleAssignmentCompleted(String assignmentId, Map<String, dynamic> data) async {
    try {
      final conversationId = await AutoChatService.instance.getConversationForAssignment(assignmentId);
      if (conversationId == null) return;

      final updatedBy = data['updatedBy'] as String? ?? 'Systeem';
      
      await AutoChatService.instance.sendAssignmentStatusUpdate(
        conversationId: conversationId,
        status: 'completed',
        updatedBy: updatedBy,
      );
      
      // Archive conversation after a delay
      Timer(const Duration(hours: 24), () {
        AutoChatService.instance.archiveAssignmentConversation(conversationId);
      });
      
      debugPrint('Assignment completed notification sent: $assignmentId');
    } catch (e) {
      debugPrint('Error handling assignment completed: $e');
    }
  }

  /// Handle assignment cancelled
  Future<void> _handleAssignmentCancelled(String assignmentId, Map<String, dynamic> data) async {
    try {
      final conversationId = await AutoChatService.instance.getConversationForAssignment(assignmentId);
      if (conversationId == null) return;

      final updatedBy = data['updatedBy'] as String? ?? 'Systeem';
      final reason = data['cancellationReason'] as String?;
      
      await AutoChatService.instance.sendAssignmentStatusUpdate(
        conversationId: conversationId,
        status: 'cancelled',
        updatedBy: updatedBy,
        reason: reason,
      );
      
      // Archive conversation immediately
      await AutoChatService.instance.archiveAssignmentConversation(conversationId);
      
      debugPrint('Assignment cancelled notification sent: $assignmentId');
    } catch (e) {
      debugPrint('Error handling assignment cancelled: $e');
    }
  }

  /// Send assignment-related notifications
  Future<void> _sendAssignmentNotifications({
    required String guardId,
    required String companyId,
    required String assignmentTitle,
    required String conversationId,
    required String notificationType,
  }) async {
    try {
      String body;

      switch (notificationType) {
        case 'assignment_accepted':
          body = 'Chat aangemaakt voor "$assignmentTitle"';
          break;
        case 'assignment_started':
          body = 'De opdracht "$assignmentTitle" is gestart';
          break;
        case 'assignment_completed':
          body = 'De opdracht "$assignmentTitle" is voltooid';
          break;
        case 'assignment_cancelled':
          body = 'De opdracht "$assignmentTitle" is geannuleerd';
          break;
        default:
          body = 'Er is een update voor "$assignmentTitle"';
      }

      // Send notification to guard
      await NotificationService.instance.sendMessageNotification(
        recipientUserId: guardId,
        senderName: 'SecuryFlex Systeem',
        messageContent: body,
        conversationId: conversationId,
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        messageType: MessageType.system,
      );

      // Send notification to company
      await NotificationService.instance.sendMessageNotification(
        recipientUserId: companyId,
        senderName: 'SecuryFlex Systeem',
        messageContent: body,
        conversationId: conversationId,
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        messageType: MessageType.system,
      );
    } catch (e) {
      debugPrint('Error sending assignment notifications: $e');
    }
  }

  /// Schedule assignment reminders
  Future<void> scheduleAssignmentReminders(String assignmentId) async {
    try {
      final assignmentDoc = await _firestore.collection('assignments').doc(assignmentId).get();
      if (!assignmentDoc.exists) return;

      final data = assignmentDoc.data()!;
      final startDate = (data['startDate'] as Timestamp?)?.toDate();
      if (startDate == null) return;

      final conversationId = await AutoChatService.instance.getConversationForAssignment(assignmentId);
      if (conversationId == null) return;

      final title = data['title'] as String? ?? 'Beveiligingsopdracht';
      final location = data['location'] as String? ?? 'Locatie onbekend';
      final now = DateTime.now();

      // Schedule reminders at different intervals
      final reminderTimes = [
        Duration(days: 1),   // 24 hours before
        Duration(hours: 4),  // 4 hours before
        Duration(hours: 1),  // 1 hour before
      ];

      for (final reminderTime in reminderTimes) {
        final reminderDate = startDate.subtract(reminderTime);
        
        if (reminderDate.isAfter(now)) {
          final delay = reminderDate.difference(now);
          
          Timer(delay, () {
            AutoChatService.instance.sendAssignmentReminder(
              conversationId: conversationId,
              assignmentTitle: title,
              assignmentDate: startDate,
              assignmentLocation: location,
              hoursUntilStart: reminderTime.inHours,
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error scheduling assignment reminders: $e');
    }
  }

  /// Get assignment chat statistics
  Future<Map<String, dynamic>> getAssignmentChatStats() async {
    try {
      final assignmentChats = await _firestore
          .collection('conversations')
          .where('conversationType', isEqualTo: 'assignment')
          .get();

      final activeChats = assignmentChats.docs.where((doc) {
        final data = doc.data();
        return data['isArchived'] != true;
      }).length;

      final archivedChats = assignmentChats.docs.where((doc) {
        final data = doc.data();
        return data['isArchived'] == true;
      }).length;

      return {
        'totalAssignmentChats': assignmentChats.docs.length,
        'activeChats': activeChats,
        'archivedChats': archivedChats,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting assignment chat stats: $e');
      return {};
    }
  }

  /// Dispose resources
  void dispose() {
    _assignmentSubscription?.cancel();
    _isInitialized = false;
    debugPrint('AssignmentIntegrationService disposed');
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
