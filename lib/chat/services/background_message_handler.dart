import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Background message handler for Firebase Cloud Messaging
/// This function runs in a separate isolate and handles messages when the app is terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed (usually not required in background handler)
  // await Firebase.initializeApp();
  
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
  
  // Handle different message types
  final messageType = message.data['type'] ?? 'message';
  final conversationId = message.data['conversationId'] ?? '';
  final senderId = message.data['senderId'] ?? '';
  final senderName = message.data['senderName'] ?? '';
  
  switch (messageType) {
    case 'message':
      await _handleChatMessage(message, conversationId, senderId, senderName);
      break;
    case 'file':
      await _handleFileMessage(message, conversationId, senderId, senderName);
      break;
    case 'system':
      await _handleSystemMessage(message);
      break;
    case 'typing':
      // Typing indicators don't need background handling
      break;
    default:
      debugPrint('Unknown message type: $messageType');
  }
}

/// Handle chat message in background
Future<void> _handleChatMessage(
  RemoteMessage message,
  String conversationId,
  String senderId,
  String senderName,
) async {
  debugPrint('Processing chat message from $senderName in conversation $conversationId');
  
  // Update local database if needed
  // This could include:
  // - Storing the message locally for offline access
  // - Updating conversation metadata
  // - Incrementing unread count
  
  // For now, we'll just log the message
  final content = message.notification?.body ?? message.data['content'] ?? '';
  debugPrint('Message content: $content');
}

/// Handle file message in background
Future<void> _handleFileMessage(
  RemoteMessage message,
  String conversationId,
  String senderId,
  String senderName,
) async {
  debugPrint('Processing file message from $senderName in conversation $conversationId');
  
  final fileName = message.data['fileName'] ?? 'Bestand';
  final fileType = message.data['fileType'] ?? 'unknown';
  
  debugPrint('File: $fileName (type: $fileType)');
  
  // Handle file-specific background processing
  // This could include:
  // - Pre-downloading files for offline access
  // - Updating file metadata
  // - Virus scanning (if implemented)
}

/// Handle system message in background
Future<void> _handleSystemMessage(RemoteMessage message) async {
  debugPrint('Processing system message');
  
  final systemType = message.data['systemType'] ?? 'general';
  
  switch (systemType) {
    case 'assignment_update':
      await _handleAssignmentUpdate(message);
      break;
    case 'user_verification':
      await _handleUserVerification(message);
      break;
    case 'maintenance':
      await _handleMaintenanceNotification(message);
      break;
    default:
      debugPrint('Unknown system message type: $systemType');
  }
}

/// Handle assignment update notifications
Future<void> _handleAssignmentUpdate(RemoteMessage message) async {
  final assignmentId = message.data['assignmentId'] ?? '';
  final updateType = message.data['updateType'] ?? '';
  
  debugPrint('Assignment update: $updateType for assignment $assignmentId');
  
  // Handle assignment-specific updates
  // This could include:
  // - Updating assignment status
  // - Creating automatic chat conversations
  // - Notifying relevant parties
}

/// Handle user verification notifications
Future<void> _handleUserVerification(RemoteMessage message) async {
  final userId = message.data['userId'] ?? '';
  final verificationType = message.data['verificationType'] ?? '';
  
  debugPrint('User verification: $verificationType for user $userId');
  
  // Handle verification updates
  // This could include:
  // - Updating user status
  // - Enabling/disabling features
  // - Sending confirmation messages
}

/// Handle maintenance notifications
Future<void> _handleMaintenanceNotification(RemoteMessage message) async {
  final maintenanceType = message.data['maintenanceType'] ?? '';
  final scheduledTime = message.data['scheduledTime'] ?? '';
  
  debugPrint('Maintenance notification: $maintenanceType at $scheduledTime');
  
  // Handle maintenance notifications
  // This could include:
  // - Scheduling local reminders
  // - Updating app status
  // - Preparing for offline mode
}

/// Utility function to format Dutch timestamps
String formatDutchTimestamp(DateTime dateTime) {
  final months = [
    'januari', 'februari', 'maart', 'april', 'mei', 'juni',
    'juli', 'augustus', 'september', 'oktober', 'november', 'december'
  ];
  
  final day = dateTime.day;
  final month = months[dateTime.month - 1];
  final year = dateTime.year;
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  
  return '$day $month $year om $hour:$minute';
}

/// Utility function to get Dutch message type description
String getDutchMessageTypeDescription(String messageType) {
  switch (messageType) {
    case 'message':
      return 'Tekstbericht';
    case 'image':
      return 'Afbeelding';
    case 'file':
      return 'Bestand';
    case 'audio':
      return 'Audiobestand';
    case 'video':
      return 'Video';
    case 'system':
      return 'Systeemmelding';
    default:
      return 'Bericht';
  }
}

/// Utility function to determine notification priority
int getNotificationPriority(String messageType, Map<String, dynamic> data) {
  // High priority for urgent messages
  if (messageType == 'system') {
    final systemType = data['systemType'] ?? '';
    if (systemType == 'emergency' || systemType == 'security_alert') {
      return 2; // Max priority
    }
    return 1; // High priority
  }
  
  // Normal priority for chat messages
  if (messageType == 'message' || messageType == 'file') {
    return 0; // Default priority
  }
  
  // Low priority for typing indicators and status updates
  return -1; // Low priority
}

/// Utility function to check if message should be processed
bool shouldProcessMessage(RemoteMessage message) {
  final messageType = message.data['type'] ?? 'message';
  
  // Always process system messages
  if (messageType == 'system') {
    return true;
  }
  
  // Process chat messages and files
  if (messageType == 'message' || messageType == 'file' || 
      messageType == 'image' || messageType == 'audio' || messageType == 'video') {
    return true;
  }
  
  // Skip typing indicators and other real-time updates
  if (messageType == 'typing' || messageType == 'presence') {
    return false;
  }
  
  return true;
}

/// Utility function to extract conversation info
Map<String, String> extractConversationInfo(RemoteMessage message) {
  return {
    'conversationId': message.data['conversationId'] ?? '',
    'conversationTitle': message.data['conversationTitle'] ?? 'Gesprek',
    'senderId': message.data['senderId'] ?? '',
    'senderName': message.data['senderName'] ?? 'Onbekende gebruiker',
    'senderRole': message.data['senderRole'] ?? 'user',
  };
}

/// Utility function to create notification payload
Map<String, dynamic> createNotificationPayload({
  required String conversationId,
  required String messageId,
  required String messageType,
  Map<String, dynamic>? additionalData,
}) {
  final Map<String, dynamic> payload = {
    'conversationId': conversationId,
    'messageId': messageId,
    'type': messageType,
    'timestamp': DateTime.now().toIso8601String(),
  };

  if (additionalData != null) {
    payload.addAll(additionalData);
  }

  return payload;
}
