import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/auth_service.dart';
import '../models/message_model.dart';

/// Enterprise-grade push notification service for SecuryFlex Chat
/// Handles Firebase Cloud Messaging, local notifications, and Dutch localization
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  String? _fcmToken;
  Function(String conversationId, String messageId)? _onMessageTap;
  Function(String conversationId)? _onConversationTap;

  /// Initialize notification service with Dutch localization
  Future<void> initialize({
    Function(String conversationId, String messageId)? onMessageTap,
    Function(String conversationId)? onConversationTap,
  }) async {
    if (_isInitialized) return;

    _onMessageTap = onMessageTap;
    _onConversationTap = onConversationTap;

    try {
      // Request notification permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Get FCM token
      await _getFCMToken();
      
      // Set up message handlers
      _setupMessageHandlers();
      
      // Save token to Firestore
      await _saveTokenToFirestore();
      
      _isInitialized = true;
      // Reduce initialization logging noise
      if (kDebugMode) {
        debugPrint('💬 NotificationService ready');
      }
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permissions');
    } else {
      debugPrint('User declined or has not accepted notification permissions');
    }
  }

  /// Create platform-safe vibration pattern
  Int64List? _createVibrationPattern(List<int> pattern) {
    if (kIsWeb) return null;
    try {
      return Int64List.fromList(pattern);
    } catch (e) {
      debugPrint('Error creating vibration pattern: $e');
      return null;
    }
  }

  /// Initialize local notifications with Dutch settings
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for different message types
  Future<void> _createNotificationChannels() async {
    // Only create channels on non-web platforms
    if (kIsWeb) return;
    
    final messageChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chatberichten',
      description: 'Notificaties voor nieuwe chatberichten',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      vibrationPattern: _createVibrationPattern([0, 250, 250, 250]),
    );

    final fileChannel = AndroidNotificationChannel(
      'file_sharing',
      'Bestandsdeling',
      description: 'Notificaties voor gedeelde bestanden',
      importance: Importance.defaultImportance,
      enableVibration: true,
    );

    final systemChannel = AndroidNotificationChannel(
      'system_updates',
      'Systeemupdates',
      description: 'Belangrijke systeemupdates en meldingen',
      importance: Importance.max,
      enableVibration: true,
      vibrationPattern: _createVibrationPattern([0, 500, 250, 500]),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(messageChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(fileChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(systemChannel);
  }

  /// Get FCM token for this device
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToFirestore();
      });
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Save FCM token to Firestore for server-side messaging
  Future<void> _saveTokenToFirestore() async {
    if (_fcmToken == null || !AuthService.isLoggedIn) return;

    try {
      final userId = AuthService.currentUserType; // Should be actual user ID
      final userRole = AuthService.currentUserType.toLowerCase();
      
      await FirebaseFirestore.instance
          .collection('notification_tokens')
          .doc('${userId}_${_fcmToken!.substring(0, 10)}')
          .set({
        'userId': userId,
        'userRole': userRole,
        'token': _fcmToken,
        'platform': defaultTargetPlatform.name,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));
      
      debugPrint('FCM token saved to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Set up Firebase message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);
    
    // Handle app launch from notification
    _handleAppLaunchFromNotification();
  }

  /// Handle messages received while app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    
    final data = message.data;
    final notification = message.notification;
    
    if (notification != null && data.isNotEmpty) {
      await _showLocalNotification(
        title: notification.title ?? 'Nieuw bericht',
        body: notification.body ?? 'Je hebt een nieuw bericht ontvangen',
        data: data,
      );
    }
  }

  /// Handle notification tap when app is in background
  Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    debugPrint('Notification tapped from background: ${message.messageId}');
    _navigateFromNotification(message.data);
  }

  /// Handle app launch from notification
  Future<void> _handleAppLaunchFromNotification() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from notification: ${initialMessage.messageId}');
      _navigateFromNotification(initialMessage.data);
    }
  }

  /// Show local notification with Dutch content
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final messageType = data['type'] ?? 'message';
    final conversationId = data['conversationId'] ?? '';
    final messageId = data['messageId'] ?? '';
    
    String channelId;
    String channelName;
    Importance importance;
    
    switch (messageType) {
      case 'file':
        channelId = 'file_sharing';
        channelName = 'Bestandsdeling';
        importance = Importance.defaultImportance;
        break;
      case 'system':
        channelId = 'system_updates';
        channelName = 'Systeemupdates';
        importance = Importance.max;
        break;
      default:
        channelId = 'chat_messages';
        channelName = 'Chatberichten';
        importance = Importance.high;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: Priority.high,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'SecuryFlex',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: jsonEncode({
        'conversationId': conversationId,
        'messageId': messageId,
        'type': messageType,
      }),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _navigateFromNotification(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Navigate to appropriate screen based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    final conversationId = data['conversationId'] as String?;
    final messageId = data['messageId'] as String?;
    
    if (conversationId != null) {
      if (messageId != null && _onMessageTap != null) {
        _onMessageTap!(conversationId, messageId);
      } else if (_onConversationTap != null) {
        _onConversationTap!(conversationId);
      }
    }
  }

  /// Send notification for new message
  Future<void> sendMessageNotification({
    required String recipientUserId,
    required String senderName,
    required String messageContent,
    required String conversationId,
    required String messageId,
    required MessageType messageType,
  }) async {
    try {
      // Get recipient's FCM tokens
      final tokens = await _getRecipientTokens(recipientUserId);
      
      if (tokens.isEmpty) {
        debugPrint('No FCM tokens found for user: $recipientUserId');
        return;
      }

      // Prepare notification content in Dutch
      final title = _getNotificationTitle(senderName, messageType);
      final body = _getNotificationBody(messageContent, messageType);
      
      // Send to each token
      for (final token in tokens) {
        await _sendNotificationToToken(
          token: token,
          title: title,
          body: body,
          data: {
            'type': 'message',
            'conversationId': conversationId,
            'messageId': messageId,
            'senderId': AuthService.currentUserType,
            'senderName': senderName,
          },
        );
      }
    } catch (e) {
      debugPrint('Error sending message notification: $e');
    }
  }

  /// Get FCM tokens for a specific user
  Future<List<String>> _getRecipientTokens(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notification_tokens')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data()['token'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error getting recipient tokens: $e');
      return [];
    }
  }

  /// Send notification to specific FCM token
  Future<void> _sendNotificationToToken({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // This would typically be done server-side using Firebase Admin SDK
    // For now, we'll use the local notification system
    await _showLocalNotification(
      title: title,
      body: body,
      data: data,
    );
  }

  /// Get localized notification title
  String _getNotificationTitle(String senderName, MessageType messageType) {
    switch (messageType) {
      case MessageType.image:
        return '$senderName heeft een afbeelding gestuurd';
      case MessageType.file:
        return '$senderName heeft een bestand gestuurd';
      case MessageType.voice:
        return '$senderName heeft een spraakbericht gestuurd';
      case MessageType.system:
        return 'Systeemmelding';
      default:
        return 'Nieuw bericht van $senderName';
    }
  }

  /// Get localized notification body
  String _getNotificationBody(String content, MessageType messageType) {
    switch (messageType) {
      case MessageType.image:
        return '📷 Afbeelding';
      case MessageType.file:
        return '📎 $content';
      case MessageType.voice:
        return '🎵 Spraakbericht';
      case MessageType.system:
        return '⚙️ $content';
      default:
        return content.length > 100 ? '${content.substring(0, 100)}...' : content;
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Clear notifications for specific conversation
  Future<void> clearConversationNotifications(String conversationId) async {
    // This would require tracking notification IDs by conversation
    // For now, we'll clear all notifications
    await clearAllNotifications();
  }

  /// Update notification badge count
  Future<void> updateBadgeCount(int count) async {
    // This would be implemented with a badge plugin
    debugPrint('Badge count updated to: $count');
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}
