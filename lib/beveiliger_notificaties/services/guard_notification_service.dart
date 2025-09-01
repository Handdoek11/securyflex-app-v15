import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/auth_service.dart';
import '../../company_dashboard/services/analytics_service.dart';
import '../../company_dashboard/models/analytics_data_models.dart';
import '../../chat/services/notification_service.dart';
import '../../chat/models/message_model.dart';
import '../../marketplace/model/security_job_data.dart';
import '../../beveiliger_profiel/models/specialization.dart';
import '../models/guard_notification.dart';
import '../models/notification_preferences.dart';
import 'notification_preferences_service.dart';
import '../../core/firebase_error_handler.dart';

/// Enhanced guard notification service extending existing NotificationService
/// Provides specialized notifications for security guards including job alerts,
/// shift reminders, payment updates, and certificate expiration warnings
class GuardNotificationService {
  static final GuardNotificationService _instance = GuardNotificationService._internal();
  factory GuardNotificationService() => _instance;
  GuardNotificationService._internal();

  static GuardNotificationService get instance => _instance;

  // Dependencies - using existing services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _baseNotificationService = NotificationService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  final NotificationPreferencesService _preferencesService = NotificationPreferencesService();
  
  // Service state
  bool _isInitialized = false;
  String? _currentUserId;
  
  // Firestore collections
  static const String _notificationsCollection = 'guard_notifications';
  
  // Local caching
  final List<GuardNotification> _notificationCache = [];
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Initialize guard notification service for current user
  /// Integrates with existing NotificationService and Firebase setup
  Future<void> initialize({
    Function(String notificationId, Map<String, dynamic> data)? onNotificationTap,
  }) async {
    if (_isInitialized) return;

    try {
      // Get current user from existing AuthService
      _currentUserId = AuthService.currentUserId;
      if (_currentUserId == null || _currentUserId!.isEmpty) {
        debugPrint('GuardNotificationService: No authenticated user found');
        return;
      }

      // Initialize base notification service if not already done
      await _baseNotificationService.initialize(
        onMessageTap: (conversationId, messageId) {
          // Handle chat notifications through existing service
        },
      );

      // Set up guard-specific notification handlers
      await _setupGuardNotificationHandlers(onNotificationTap);
      
      // Initialize preferences service
      await _preferencesService.initialize();
      
      // Set up Firestore listeners for real-time updates
      _setupFirestoreListeners();
      
      _isInitialized = true;
      // Service initialized - reduce noise in production
      if (kDebugMode) {
        debugPrint('🔔 GuardNotificationService ready');
      }

      // Track initialization in analytics
      await _trackNotificationEvent('guard_notifications_initialized', {
        'user_id': _currentUserId!,
        'timestamp': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      debugPrint('Error initializing GuardNotificationService: $e');
      rethrow;
    }
  }

  /// Send job opportunity notification to guard
  /// Integrates with existing job matching service data
  Future<bool> sendJobAlert({
    required SecurityJobData jobData,
    required List<Specialization> matchingSpecializations,
    String? customMessage,
  }) async {
    if (!_isInitialized || _currentUserId == null) {
      debugPrint('GuardNotificationService not initialized');
      return false;
    }

    try {
      // Create notification using template
      final template = GuardNotificationTemplate.defaultTemplates
          .firstWhere((t) => t.type == GuardNotificationType.jobOpportunity);

      final variables = {
        'jobType': jobData.jobType,
        'hourlyRate': jobData.hourlyRate.toStringAsFixed(2),
        'location': jobData.location,
        'companyName': jobData.companyName,
        'distance': jobData.distance.toStringAsFixed(1),
      };

      final notification = template.generate(
        userId: _currentUserId!,
        variables: variables,
        actionUrl: '/marketplace/job/${jobData.jobId}',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      // Add matching specializations to data
      final enhancedData = Map<String, dynamic>.from(notification.data);
      enhancedData['jobId'] = jobData.jobId;
      enhancedData['matchingSpecializations'] = matchingSpecializations
          .map((s) => s.type.displayName)
          .toList();
      enhancedData['matchScore'] = _calculateMatchScore(jobData, matchingSpecializations);

      final enhancedNotification = notification.copyWith(data: enhancedData);

      // Send notification
      final success = await _sendNotification(enhancedNotification);

      if (success) {
        // Track job alert analytics
        await _trackJobAlertSent(jobData, matchingSpecializations);
      }

      return success;

    } catch (e) {
      debugPrint('Error sending job alert: $e');
      return false;
    }
  }

  /// Send shift reminder notification
  /// Integrates with existing scheduling system
  Future<bool> sendShiftReminder({
    required String shiftId,
    required String companyName,
    required String location,
    required DateTime shiftStartTime,
    Duration reminderBefore = const Duration(hours: 2),
  }) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      final template = GuardNotificationTemplate.defaultTemplates
          .firstWhere((t) => t.type == GuardNotificationType.shiftReminder);

      final timeUntil = _formatTimeUntil(shiftStartTime);
      final variables = {
        'timeUntil': timeUntil,
        'companyName': companyName,
        'location': location,
        'startTime': _formatTime(shiftStartTime),
      };

      final notification = template.generate(
        userId: _currentUserId!,
        variables: variables,
        actionUrl: '/schedule/shift/$shiftId',
        scheduledFor: shiftStartTime.subtract(reminderBefore),
      );

      // Add shift-specific data
      final enhancedData = Map<String, dynamic>.from(notification.data);
      enhancedData['shiftId'] = shiftId;
      enhancedData['shiftStartTime'] = shiftStartTime.toIso8601String();

      final enhancedNotification = notification.copyWith(data: enhancedData);

      return await _sendNotification(enhancedNotification);

    } catch (e) {
      debugPrint('Error sending shift reminder: $e');
      return false;
    }
  }

  /// Send certificate expiry warning
  /// Integrates with existing WPBR certificate management
  Future<bool> sendCertificateExpiryAlert({
    required String certificateType,
    required DateTime expiryDate,
    required String certificateNumber,
  }) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      final template = GuardNotificationTemplate.defaultTemplates
          .firstWhere((t) => t.type == GuardNotificationType.certificateExpiry);

      final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
      final variables = {
        'certificateType': certificateType,
        'daysUntilExpiry': daysUntilExpiry.toString(),
        'expiryDate': _formatDate(expiryDate),
      };

      final notification = template.generate(
        userId: _currentUserId!,
        variables: variables,
        actionUrl: '/profile/certificates',
        expiresAt: expiryDate.add(const Duration(days: 7)), // Valid until 7 days after expiry
      );

      // Add certificate-specific data
      final enhancedData = Map<String, dynamic>.from(notification.data);
      enhancedData['certificateNumber'] = certificateNumber;
      enhancedData['expiryDate'] = expiryDate.toIso8601String();
      enhancedData['daysUntilExpiry'] = daysUntilExpiry;

      final enhancedNotification = notification.copyWith(data: enhancedData);

      return await _sendNotification(enhancedNotification);

    } catch (e) {
      debugPrint('Error sending certificate expiry alert: $e');
      return false;
    }
  }

  /// Send enhanced certificate expiry alert with renewal course suggestions
  /// Integrates with training service for renewal course recommendations
  Future<bool> sendCertificateExpiryAlertWithCourses({
    required String certificateType,
    required DateTime expiryDate,
    required String certificateNumber,
    required int daysUntilExpiry,
    List<Map<String, dynamic>> renewalCourses = const [],
  }) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      // Determine alert urgency and message based on days remaining
      NotificationPriority priority;
      String alertTitle;
      String alertBody;
      
      if (daysUntilExpiry <= 0) {
        priority = NotificationPriority.urgent;
        alertTitle = '$certificateType Certificaat Verlopen';
        alertBody = 'Je $certificateType certificaat is verlopen. Verleng direct om te blijven werken.';
      } else if (daysUntilExpiry <= 7) {
        priority = NotificationPriority.urgent;
        alertTitle = 'Urgent: $certificateType Verloopt Over $daysUntilExpiry Dagen';
        alertBody = 'Je $certificateType certificaat verloopt zeer binnenkort. Boek nu je verlengingscursus!';
      } else if (daysUntilExpiry <= 30) {
        priority = NotificationPriority.high;
        alertTitle = '$certificateType Verloopt Over $daysUntilExpiry Dagen';
        alertBody = 'Plan je $certificateType certificaat verlenging. Verlengingscursussen beschikbaar.';
      } else {
        priority = NotificationPriority.medium;
        alertTitle = '$certificateType Verlenging Plannen';
        alertBody = 'Je $certificateType certificaat verloopt over $daysUntilExpiry dagen. Begin met plannen.';
      }

      // Add course information to body if available
      if (renewalCourses.isNotEmpty) {
        final cheapestCourse = renewalCourses.reduce((a, b) => 
            (a['price'] ?? double.infinity) < (b['price'] ?? double.infinity) ? a : b);
        alertBody += ' Cursussen vanaf €${(cheapestCourse['price'] ?? 0.0).toStringAsFixed(0)}.';
      }

      final notification = GuardNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentUserId!,
        type: GuardNotificationType.certificateExpiry,
        title: alertTitle,
        body: alertBody,
        data: {
          'certificateType': certificateType,
          'certificateNumber': certificateNumber,
          'expiryDate': expiryDate.toIso8601String(),
          'daysUntilExpiry': daysUntilExpiry,
          'renewalCourses': renewalCourses,
          'alertLevel': daysUntilExpiry <= 0 ? 'expired' : 
                      daysUntilExpiry <= 7 ? 'critical' : 
                      daysUntilExpiry <= 30 ? 'warning' : 'notice',
        },
        timestamp: DateTime.now(),
        priority: priority,
        actionUrl: '/profile/certificates',
        expiresAt: daysUntilExpiry <= 0 
            ? DateTime.now().add(const Duration(days: 30)) // Keep expired alerts for 30 days
            : expiryDate.add(const Duration(days: 7)),
        actionButtons: renewalCourses.isNotEmpty 
            ? {'courses': 'Cursussen Bekijken', 'later': 'Later Herinneren'}
            : {'renew': 'Verlengen', 'dismiss': 'Sluiten'},
      );

      final success = await _sendNotification(notification);
      
      if (success) {
        // Track certificate alert analytics
        await _trackCertificateAlert(certificateType, daysUntilExpiry, renewalCourses.length);
      }

      return success;

    } catch (e) {
      debugPrint('Error sending certificate expiry alert with courses: $e');
      return false;
    }
  }

  /// Send payment update notification
  Future<bool> sendPaymentUpdate({
    required String paymentId,
    required double amount,
    required String description,
    required String status, // 'processed', 'pending', 'failed'
  }) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      final notification = GuardNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentUserId!,
        type: GuardNotificationType.paymentUpdate,
        title: 'Betaling ${status == 'processed' ? 'Verwerkt' : status == 'pending' ? 'In Behandeling' : 'Mislukt'}',
        body: '€${amount.toStringAsFixed(2)} - $description',
        data: {
          'paymentId': paymentId,
          'amount': amount.toString(),
          'description': description,
          'status': status,
        },
        timestamp: DateTime.now(),
        priority: status == 'failed' ? NotificationPriority.high : NotificationPriority.medium,
        actionUrl: '/payments/history',
      );

      return await _sendNotification(notification);

    } catch (e) {
      debugPrint('Error sending payment update: $e');
      return false;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      // Update in Firestore
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local cache
      final index = _notificationCache.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notificationCache[index] = _notificationCache[index].copyWith(isRead: true);
      }

      // Track analytics
      await _trackNotificationEvent('notification_read', {
        'notification_id': notificationId,
        'user_id': _currentUserId!,
      });

      return true;

    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Get notification history for current user
  Future<List<GuardNotification>> getNotificationHistory({
    int limit = 50,
    bool useCache = true,
  }) async {
    if (!_isInitialized || _currentUserId == null) return [];

    // Return cached notifications if valid
    if (useCache && _isCacheValid()) {
      return _notificationCache.take(limit).toList();
    }

    try {
      final query = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final notifications = query.docs
          .map((doc) => GuardNotification.fromFirestore(doc))
          .where((n) => !n.isExpired) // Filter out expired notifications
          .toList();

      // Update cache
      _notificationCache.clear();
      _notificationCache.addAll(notifications);
      _lastCacheUpdate = DateTime.now();

      return notifications;

    } catch (e) {
      return await FirebaseErrorHandler.handleFirebaseOperation<List<GuardNotification>>(
        Future.value(<GuardNotification>[]),
        context: 'Getting notification history',
        fallbackValue: [],
        silent: FirebaseErrorHandler.isMissingIndexError(e),
      ) ?? [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    if (!_isInitialized || _currentUserId == null) return 0;

    try {
      final query = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      return query.docs
          .map((doc) => GuardNotification.fromFirestore(doc))
          .where((n) => !n.isExpired)
          .length;

    } catch (e) {
      return await FirebaseErrorHandler.handleFirebaseOperation<int>(
        Future.value(0),
        context: 'Getting unread count',
        fallbackValue: 0,
        silent: FirebaseErrorHandler.isMissingIndexError(e),
      ) ?? 0;
    }
  }

  /// Clear all notifications for user
  Future<bool> clearAllNotifications() async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      final batch = _firestore.batch();
      
      final query = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: _currentUserId)
          .get();

      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Clear cache
      _notificationCache.clear();
      _lastCacheUpdate = null;

      // Track analytics
      await _trackNotificationEvent('notifications_cleared', {
        'user_id': _currentUserId!,
        'count': query.docs.length,
      });

      return true;

    } catch (e) {
      debugPrint('Error clearing notifications: $e');
      return false;
    }
  }

  // Private helper methods

  /// Send notification to Firebase and local with preference checking
  Future<bool> _sendNotification(GuardNotification notification) async {
    try {
      // Check user preferences before sending
      final shouldSend = await _checkNotificationPermission(notification);
      if (!shouldSend) {
        debugPrint('Notification blocked by user preferences: ${notification.title}');
        return false;
      }

      // Save to Firestore
      await _firestore
          .collection(_notificationsCollection)
          .doc(notification.id)
          .set(notification.toFirestore());

      // Send local notification if not scheduled
      if (!notification.isScheduled) {
        await _sendLocalNotification(notification);
      }

      // Update cache
      _notificationCache.insert(0, notification);
      if (_notificationCache.length > 100) {
        _notificationCache.removeLast();
      }

      debugPrint('Guard notification sent successfully: ${notification.title}');
      return true;

    } catch (e) {
      debugPrint('Error sending notification: $e');
      return false;
    }
  }

  /// Check if notification should be sent based on user preferences
  Future<bool> _checkNotificationPermission(GuardNotification notification) async {
    try {
      // Determine category and urgency
      NotificationCategory category;
      bool isUrgent = false;
      
      switch (notification.type) {
        case GuardNotificationType.jobOpportunity:
          category = NotificationCategory.jobOpportunity;
          break;
        case GuardNotificationType.certificateExpiry:
          category = NotificationCategory.certificateExpiry;
          isUrgent = notification.priority == NotificationPriority.urgent;
          break;
        case GuardNotificationType.paymentUpdate:
          category = NotificationCategory.paymentUpdate;
          isUrgent = notification.data['status'] == 'failed';
          break;
        case GuardNotificationType.shiftReminder:
          category = NotificationCategory.jobOpportunity; // Shift reminders are job-related
          break;
        default:
          category = NotificationCategory.systemAlert;
      }
      
      // Check push notification permission
      final shouldSendPush = await _preferencesService.shouldSendNotification(
        category,
        NotificationDeliveryMethod.push,
        isUrgent: isUrgent,
      );
      
      // For now, we only check push notifications
      // Email and in-app notifications would be handled separately
      return shouldSendPush;
      
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      // Default to allowing notifications on error
      return true;
    }
  }

  /// Send local notification using existing service patterns
  Future<void> _sendLocalNotification(GuardNotification notification) async {
    try {
      // Use existing notification service for local delivery
      // This integrates with the existing Flutter Local Notifications setup
      final notificationId = notification.id.hashCode;
      
      await FlutterLocalNotificationsPlugin().show(
        notificationId,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'guard_notifications',
            'Beveiliger Notificaties',
            channelDescription: 'Notificaties voor beveiligers',
            importance: _getAndroidImportance(notification.priority),
            priority: _getAndroidPriority(notification.priority),
            icon: '@drawable/ic_notification',
            color: _parseColor(notification.colorHex) != null 
                ? Color(_parseColor(notification.colorHex)!) 
                : null,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode({
          'type': 'guard_notification',
          'notificationId': notification.id,
          'actionUrl': notification.actionUrl,
          'data': notification.data,
        }),
      );

    } catch (e) {
      debugPrint('Error sending local notification: $e');
    }
  }

  /// Setup Firestore listeners for real-time updates
  void _setupFirestoreListeners() {
    if (_currentUserId == null) return;

    _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      // Update cache with latest notifications
      final latestNotifications = snapshot.docs
          .map((doc) => GuardNotification.fromFirestore(doc))
          .toList();

      // Merge with existing cache
      for (final newNotification in latestNotifications) {
        final existingIndex = _notificationCache.indexWhere((n) => n.id == newNotification.id);
        if (existingIndex != -1) {
          _notificationCache[existingIndex] = newNotification;
        } else {
          _notificationCache.insert(0, newNotification);
        }
      }

      // Keep cache size reasonable
      if (_notificationCache.length > 100) {
        _notificationCache.removeRange(100, _notificationCache.length);
      }

      _lastCacheUpdate = DateTime.now();
    });
  }

  /// Setup guard-specific notification tap handlers
  Future<void> _setupGuardNotificationHandlers(
    Function(String, Map<String, dynamic>)? onNotificationTap,
  ) async {
    // This would integrate with existing notification tap handling in main.dart
    // For now, we store the callback for later use
    if (onNotificationTap != null) {
      // Store callback for use when notifications are tapped
    }
  }

  /// Get current notification preferences status
  String getNotificationStatus() {
    return _preferencesService.getPreferencesSummary();
  }
  
  /// Check if user has notifications enabled
  bool get hasNotificationsEnabled {
    return _preferencesService.hasNotificationsEnabled;
  }
  
  /// Check if quiet hours are currently active
  bool get isQuietHoursActive {
    return _preferencesService.isQuietHoursActive;
  }

  /// Calculate job match score for notification relevance
  int _calculateMatchScore(SecurityJobData jobData, List<Specialization> specializations) {
    // Simple scoring algorithm - could be enhanced
    int score = 0;
    
    for (final spec in specializations) {
      if (spec.matchesJobCategory(jobData.jobType)) {
        score += 20;
        if (spec.skillLevel == SkillLevel.expert) {
          score += 10;
        } else if (spec.skillLevel == SkillLevel.ervaren) {
          score += 5;
        }
      }
    }

    return score.clamp(0, 100);
  }

  /// Track job alert analytics
  Future<void> _trackJobAlertSent(SecurityJobData jobData, List<Specialization> specializations) async {
    await _analyticsService.trackEvent(
      jobId: jobData.jobId,
      eventType: JobEventType.view, // Using existing enum
      userId: _currentUserId!,
      metadata: {
        'event_type': 'job_alert_sent',
        'job_type': jobData.jobType,
        'hourly_rate': jobData.hourlyRate,
        'distance': jobData.distance,
        'matching_specializations': specializations.length,
        'match_score': _calculateMatchScore(jobData, specializations),
      },
    );
  }

  /// Track general notification events
  Future<void> _trackNotificationEvent(String eventType, Map<String, dynamic> metadata) async {
    await _analyticsService.trackEvent(
      jobId: 'guard_notifications',
      eventType: JobEventType.completion, // Using existing enum for completion tracking
      userId: _currentUserId!,
      metadata: {
        'event_type': eventType,
        ...metadata,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track certificate alert analytics for effectiveness measurement
  Future<void> _trackCertificateAlert(
    String certificateType, 
    int daysUntilExpiry, 
    int availableCourses,
  ) async {
    await _analyticsService.trackEvent(
      jobId: 'certificate_alerts',
      eventType: JobEventType.view, // Using existing enum
      userId: _currentUserId!,
      metadata: {
        'event_type': 'certificate_alert_sent',
        'certificate_type': certificateType,
        'days_until_expiry': daysUntilExpiry,
        'alert_level': daysUntilExpiry <= 0 ? 'expired' : 
                      daysUntilExpiry <= 7 ? 'critical' : 
                      daysUntilExpiry <= 30 ? 'warning' : 'notice',
        'available_courses': availableCourses,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': _currentUserId!,
      },
    );
  }

  /// Check if cache is valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  /// Helper methods for formatting
  String _formatTimeUntil(DateTime target) {
    final difference = target.difference(DateTime.now());
    if (difference.inDays > 0) {
      return '${difference.inDays} dagen';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} uur';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuten';
    } else {
      return 'binnenkort';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// Convert notification priority to Android importance
  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Importance.max;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.medium:
        return Importance.defaultImportance;
      case NotificationPriority.low:
        return Importance.low;
    }
  }

  /// Convert notification priority to Android priority
  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Priority.max;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.medium:
        return Priority.defaultPriority;
      case NotificationPriority.low:
        return Priority.low;
    }
  }

  /// Parse hex color string to Color
  int? _parseColor(String hexColor) {
    try {
      return int.parse(hexColor.replaceFirst('#', '0xFF'));
    } catch (e) {
      return null;
    }
  }

  /// Send application accepted notification
  Future<void> sendApplicationAccepted({
    required String guardId,
    required String jobId,
    required String jobTitle,
    required String companyName,
    String? message,
  }) async {
    try {
      final notification = GuardNotification(
        id: _generateNotificationId(),
        userId: guardId,
        title: 'Sollicitatie Geaccepteerd! 🎉',
        body: 'Je sollicitatie voor "$jobTitle" bij $companyName is geaccepteerd.',
        type: GuardNotificationType.applicationAccepted,
        priority: NotificationPriority.high,
        timestamp: DateTime.now(),
        actionUrl: '/job/$jobId',
        data: {
          'jobId': jobId,
          'companyName': companyName,
          'message': message ?? '',
          'action': 'view_job_details',
        },
      );
      
      // Save to Firestore
      await _firestore
          .collection(_notificationsCollection)
          .add(notification.toFirestore());
      
      // Send push notification
      await _baseNotificationService.sendMessageNotification(
        recipientUserId: guardId,
        senderName: companyName,
        messageContent: notification.body,
        conversationId: 'job_notifications',
        messageId: notification.id,
        messageType: MessageType.system,
      );
      
      // Track analytics (simplified - remove complex enum)
      debugPrint('Application accepted notification sent for job $jobId to guard $guardId');
      
    } catch (e) {
      debugPrint('Error sending acceptance notification: $e');
    }
  }

  /// Send application rejected notification
  Future<void> sendApplicationRejected({
    required String guardId,
    required String jobId,
    required String jobTitle,
    required String companyName,
    String? reason,
  }) async {
    try {
      final notification = GuardNotification(
        id: _generateNotificationId(),
        userId: guardId,
        title: 'Sollicitatie Update',
        body: 'Je sollicitatie voor "$jobTitle" bij $companyName is helaas niet geaccepteerd.',
        type: GuardNotificationType.applicationRejected,
        priority: NotificationPriority.medium,
        timestamp: DateTime.now(),
        actionUrl: '/jobs',
        data: {
          'jobId': jobId,
          'companyName': companyName,
          'reason': reason ?? '',
          'action': 'view_other_jobs',
        },
      );
      
      // Save to Firestore
      await _firestore
          .collection(_notificationsCollection)
          .add(notification.toFirestore());
      
      // Send push notification
      await _baseNotificationService.sendMessageNotification(
        recipientUserId: guardId,
        senderName: companyName,
        messageContent: notification.body,
        conversationId: 'job_notifications',
        messageId: notification.id,
        messageType: MessageType.system,
      );
      
      // Track analytics (simplified)
      debugPrint('Application rejected notification sent for job $jobId to guard $guardId');
      
    } catch (e) {
      debugPrint('Error sending rejection notification: $e');
    }
  }

  /// Send job position filled notification
  Future<void> sendJobPositionFilled({
    required String guardId,
    required String jobId,
    required String jobTitle,
  }) async {
    try {
      final notification = GuardNotification(
        id: _generateNotificationId(),
        userId: guardId,
        title: 'Positie Vervuld',
        body: 'De positie voor "$jobTitle" is inmiddels vervuld. Bekijk andere beschikbare opdrachten.',
        type: GuardNotificationType.jobUpdate,
        priority: NotificationPriority.low,
        timestamp: DateTime.now(),
        actionUrl: '/jobs',
        data: {
          'jobId': jobId,
          'action': 'view_available_jobs',
        },
      );
      
      // Save to Firestore
      await _firestore
          .collection(_notificationsCollection)
          .add(notification.toFirestore());
      
      // Send push notification
      await _baseNotificationService.sendMessageNotification(
        recipientUserId: guardId,
        senderName: 'SecuryFlex',
        messageContent: notification.body,
        conversationId: 'job_notifications',
        messageId: notification.id,
        messageType: MessageType.system,
      );
      
      // Track analytics (simplified)
      debugPrint('Job filled notification sent for job $jobId to guard $guardId');
      
    } catch (e) {
      debugPrint('Error sending job filled notification: $e');
    }
  }

  /// Send "New Job Available" alert to matching guards
  /// Triggered automatically when companies post new jobs
  /// Integrates with job matching algoritme for targeted notifications
  Future<bool> sendNewJobAvailableAlert({
    required SecurityJobData jobData,
    String targetAudience = 'all_active_guards',
    String? customMessage,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ GuardNotificationService not initialized for new job alert');
      return false;
    }

    try {
      // Create notification for new job availability
      final notification = GuardNotification(
        id: _generateNotificationId(),
        type: GuardNotificationType.jobOpportunity,
        title: '🆕 Nieuwe Vacature Beschikbaar!',
        body: customMessage ?? 
               '${jobData.jobTitle} in ${jobData.location} - €${jobData.hourlyRate.toStringAsFixed(2)}/uur. '
               'Check nu je aanbevelingen!',
        data: {
          'jobId': jobData.jobId,
          'jobTitle': jobData.jobTitle,
          'companyName': jobData.companyName,
          'location': jobData.location,
          'hourlyRate': jobData.hourlyRate,
          'requiredCertificates': jobData.requiredCertificates,
          'actionType': 'view_job_details',
          'targetAudience': targetAudience,
        },
        userId: 'broadcast', // Broadcast to multiple guards
        timestamp: DateTime.now(),
        priority: NotificationPriority.medium,
        isRead: false,
        actionUrl: '/marketplace/job/${jobData.jobId}',
      );

      // Store notification in Firestore for all guards to see
      await _firestore.collection(_notificationsCollection).add({
        ...notification.toFirestore(),
        'broadcast': true,
        'targetAudience': targetAudience,
        'jobPostedAt': DateTime.now().toIso8601String(),
      });

      // Send push notification via base service (to all active guards)
      // In a real implementation, this would query active guards and send targeted notifications
      await _baseNotificationService.sendMessageNotification(
        recipientUserId: 'broadcast_all_guards',
        senderName: 'SecuryFlex Jobs',
        messageContent: notification.body,
        conversationId: 'job_opportunities',
        messageId: notification.id,
        messageType: MessageType.system,
      );

      // Track analytics for job posting notifications
      await _trackNotificationEvent('new_job_notification_sent', {
        'jobId': jobData.jobId,
        'jobTitle': jobData.jobTitle,
        'hourlyRate': jobData.hourlyRate,
        'targetAudience': targetAudience,
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('📱 New job notification sent for: ${jobData.jobTitle}');
      return true;

    } catch (e) {
      debugPrint('❌ Error sending new job available alert: $e');
      return false;
    }
  }

  /// Generate unique notification ID
  String _generateNotificationId() {
    return 'notif_${DateTime.now().millisecondsSinceEpoch}_${_currentUserId?.substring(0, 8) ?? 'unknown'}';
  }

  /// Cleanup resources
  void dispose() {
    _notificationCache.clear();
    _lastCacheUpdate = null;
    _isInitialized = false;
  }
}