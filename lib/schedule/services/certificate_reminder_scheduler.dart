import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../auth/services/certificate_management_service.dart';
import '../../beveiliger_notificaties/models/certificate_alert.dart';
import '../../beveiliger_notificaties/services/guard_notification_service.dart';
import '../../beveiliger_notificaties/models/guard_notification.dart';
import '../../core/firebase_error_handler.dart';

/// Certificate renewal reminder intervals in days
enum ReminderInterval {
  days30(30, 'warning30', 'medium', '30 dagen'),
  days14(14, 'warning14', 'medium', '14 dagen'),
  days7(7, 'warning7', 'high', '7 dagen'),
  days3(3, 'warning3', 'high', '3 dagen'),
  days1(1, 'warning1', 'urgent', '1 dag');

  const ReminderInterval(this.days, this.alertLevel, this.priority, this.displayName);
  final int days;
  final String alertLevel;
  final String priority;
  final String displayName;
  
  NotificationPriority get notificationPriority {
    switch (priority) {
      case 'urgent': return NotificationPriority.urgent;
      case 'high': return NotificationPriority.high;
      case 'medium': return NotificationPriority.medium;
      default: return NotificationPriority.low;
    }
  }
}

/// Comprehensive certificate renewal reminder scheduling service
/// Integrates with Firebase Cloud Functions and Firestore for persistent scheduling
class CertificateReminderScheduler {
  static final CertificateReminderScheduler _instance = CertificateReminderScheduler._internal();
  factory CertificateReminderScheduler() => _instance;
  CertificateReminderScheduler._internal();

  static CertificateReminderScheduler get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GuardNotificationService _notificationService = GuardNotificationService.instance;
  
  // Collections
  static const String _remindersCollection = 'certificate_reminders';
  static const String _scheduledRemindersCollection = 'scheduled_reminders';
  
  /// Schedule all renewal reminders for a certificate
  /// Creates reminders at 30, 14, 7, 3, and 1 day intervals
  Future<bool> scheduleRenewalReminders({
    required String certificateId,
    required CertificateType certificateType,
    required String certificateNumber,
    required DateTime expiryDate,
    required String userId,
    List<RenewalCourse> renewalCourses = const [],
  }) async {
    try {
      debugPrint('🔔 Scheduling renewal reminders for ${certificateType.code} certificate');
      
      // Validate inputs
      if (certificateId.isEmpty || userId.isEmpty) {
        debugPrint('Invalid inputs for reminder scheduling');
        return false;
      }
      
      // Check if certificate is already expired
      final now = DateTime.now();
      if (expiryDate.isBefore(now)) {
        debugPrint('Certificate already expired, sending immediate notification');
        await _sendExpiredCertificateNotification(
          certificateId, certificateType, certificateNumber, 
          expiryDate, userId, renewalCourses
        );
        return true;
      }
      
      // Cancel any existing reminders for this certificate
      await cancelRenewalReminders(certificateId, userId);
      
      final batch = _firestore.batch();
      int scheduledCount = 0;
      
      // Schedule reminders for each interval
      for (final interval in ReminderInterval.values) {
        final reminderDate = expiryDate.subtract(Duration(days: interval.days));
        
        // Skip if reminder date is in the past
        if (reminderDate.isBefore(now)) {
          debugPrint('Skipping ${interval.displayName} reminder - date is in the past');
          continue;
        }
        
        // Create reminder document
        final reminderDoc = _firestore.collection(_scheduledRemindersCollection).doc();
        final reminderData = {
          'id': reminderDoc.id,
          'userId': userId,
          'certificateId': certificateId,
          'certificateType': certificateType.name,
          'certificateNumber': certificateNumber,
          'expiryDate': Timestamp.fromDate(expiryDate),
          'reminderInterval': interval.name,
          'reminderDate': Timestamp.fromDate(reminderDate),
          'scheduledDate': Timestamp.fromDate(now),
          'status': 'scheduled',
          'priority': interval.priority,
          'alertLevel': interval.alertLevel,
          'renewalCourses': renewalCourses.map((course) => {
            'id': course.id,
            'name': course.name,
            'provider': course.provider,
            'price': course.price,
            'nextStartDate': Timestamp.fromDate(course.nextStartDate),
            'isOnline': course.isOnline,
            'bookingUrl': course.bookingUrl,
          }).toList(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        batch.set(reminderDoc, reminderData);
        scheduledCount++;
        
        debugPrint('🗓 Scheduled ${interval.displayName} reminder for ${_formatDateTime(reminderDate)}');
      }
      
      // Create master reminder tracking document
      final masterReminderDoc = _firestore.collection(_remindersCollection).doc(certificateId);
      final masterData = {
        'certificateId': certificateId,
        'userId': userId,
        'certificateType': certificateType.name,
        'certificateNumber': certificateNumber,
        'expiryDate': Timestamp.fromDate(expiryDate),
        'scheduledRemindersCount': scheduledCount,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': {
          'renewalCoursesCount': renewalCourses.length,
          'schedulingSource': 'dashboard_controller',
        },
      };
      
      batch.set(masterReminderDoc, masterData, SetOptions(merge: true));
      
      // Commit all reminders in a single transaction
      await batch.commit();
      
      debugPrint('✅ Successfully scheduled $scheduledCount reminders for ${certificateType.code} certificate');
      
      // Track scheduling analytics
      await _trackReminderSchedulingAnalytics(
        certificateId, certificateType, scheduledCount, userId
      );
      
      return true;
      
    } catch (e) {
      return await FirebaseErrorHandler.handleFirebaseOperation<bool>(
        Future.value(false),
        context: 'Scheduling certificate reminders',
        fallbackValue: false,
        silent: false,
      ) ?? false;
    }
  }
  
  /// Cancel all reminders for a specific certificate
  Future<bool> cancelRenewalReminders(String certificateId, String userId) async {
    try {
      debugPrint('🚫 Cancelling existing reminders for certificate: $certificateId');
      
      // Find all scheduled reminders for this certificate
      final remindersQuery = await _firestore
          .collection(_scheduledRemindersCollection)
          .where('certificateId', isEqualTo: certificateId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'scheduled')
          .get();
      
      if (remindersQuery.docs.isEmpty) {
        debugPrint('No scheduled reminders found to cancel');
        return true;
      }
      
      final batch = _firestore.batch();
      
      // Mark reminders as cancelled instead of deleting for audit trail
      for (final doc in remindersQuery.docs) {
        batch.update(doc.reference, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Update master reminder document
      final masterDoc = _firestore.collection(_remindersCollection).doc(certificateId);
      batch.update(masterDoc, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      
      debugPrint('✅ Cancelled ${remindersQuery.docs.length} reminders for certificate $certificateId');
      return true;
      
    } catch (e) {
      debugPrint('Error cancelling reminders: $e');
      return false;
    }
  }
  
  /// Process due reminders (called by Firebase Cloud Function or scheduled task)
  Future<void> processDueReminders() async {
    try {
      final now = DateTime.now();
      debugPrint('🔄 Processing due certificate reminders at ${_formatDateTime(now)}');
      
      // Find reminders that are due
      final dueRemindersQuery = await _firestore
          .collection(_scheduledRemindersCollection)
          .where('status', isEqualTo: 'scheduled')
          .where('reminderDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .limit(50) // Process in batches
          .get();
      
      if (dueRemindersQuery.docs.isEmpty) {
        debugPrint('No due reminders found');
        return;
      }
      
      debugPrint('Found ${dueRemindersQuery.docs.length} due reminders to process');
      
      // Process each reminder
      for (final doc in dueRemindersQuery.docs) {
        try {
          await _processIndividualReminder(doc);
        } catch (e) {
          debugPrint('Error processing reminder ${doc.id}: $e');
          // Continue processing other reminders even if one fails
        }
      }
      
    } catch (e) {
      debugPrint('Error processing due reminders: $e');
    }
  }
  
  /// Process a single reminder
  Future<void> _processIndividualReminder(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    
    final certificateType = CertificateType.values.firstWhere(
      (type) => type.name == data['certificateType'],
      orElse: () => CertificateType.wpbr,
    );
    
    final interval = ReminderInterval.values.firstWhere(
      (i) => i.name == data['reminderInterval'],
      orElse: () => ReminderInterval.days7,
    );
    
    final expiryDate = (data['expiryDate'] as Timestamp).toDate();
    final renewalCoursesData = data['renewalCourses'] as List<dynamic>? ?? [];
    
    // Convert renewal courses data
    final renewalCourses = renewalCoursesData.map((courseData) {
      return RenewalCourse(
        id: courseData['id'] ?? '',
        name: courseData['name'] ?? '',
        provider: courseData['provider'] ?? '',
        duration: Duration(hours: 8), // Default
        price: (courseData['price'] ?? 0.0).toDouble(),
        nextStartDate: (courseData['nextStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isOnline: courseData['isOnline'] ?? false,
        bookingUrl: courseData['bookingUrl'],
      );
    }).toList();
    
    // Send reminder notification
    final success = await _sendReminderNotification(
      userId: data['userId'],
      certificateId: data['certificateId'],
      certificateType: certificateType,
      certificateNumber: data['certificateNumber'],
      expiryDate: expiryDate,
      interval: interval,
      renewalCourses: renewalCourses,
    );
    
    // Update reminder status
    await doc.reference.update({
      'status': success ? 'sent' : 'failed',
      'sentAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    debugPrint(success 
        ? '✅ Sent ${interval.displayName} reminder for ${certificateType.code}'
        : '❌ Failed to send ${interval.displayName} reminder for ${certificateType.code}'
    );
  }
  
  /// Send renewal reminder notification
  Future<bool> _sendReminderNotification({
    required String userId,
    required String certificateId,
    required CertificateType certificateType,
    required String certificateNumber,
    required DateTime expiryDate,
    required ReminderInterval interval,
    required List<RenewalCourse> renewalCourses,
  }) async {
    try {
      // Create Dutch reminder message based on interval
      String title;
      String body;
      
      switch (interval) {
        case ReminderInterval.days30:
          title = '${certificateType.code} Certificaat Herinnering';
          body = 'Je ${certificateType.code} certificaat verloopt over 30 dagen op ${_formatDate(expiryDate)}. Plan je verlenging.';
          break;
        case ReminderInterval.days14:
          title = '${certificateType.code} Verlenging Plannen';
          body = 'Je ${certificateType.code} certificaat verloopt over 14 dagen. Tijd om je verlengingscursus te boeken.';
          break;
        case ReminderInterval.days7:
          title = 'Urgent: ${certificateType.code} Verloopt Binnenkort';
          body = 'Let op! Je ${certificateType.code} certificaat verloopt over 7 dagen. Boek nu je cursus!';
          break;
        case ReminderInterval.days3:
          title = 'Kritiek: ${certificateType.code} Verloopt Zeer Binnenkort';
          body = 'Kritieke herinnering: Je ${certificateType.code} certificaat verloopt over slechts 3 dagen!';
          break;
        case ReminderInterval.days1:
          title = 'Laatste Dag: ${certificateType.code} Verloopt Morgen!';
          body = 'Laatste kans! Je ${certificateType.code} certificaat verloopt morgen. Onmiddellijke actie vereist!';
          break;
      }
      
      // Add course information if available
      if (renewalCourses.isNotEmpty) {
        final cheapestCourse = renewalCourses.reduce((a, b) => a.price < b.price ? a : b);
        body += ' Cursussen beschikbaar vanaf €${cheapestCourse.price.toStringAsFixed(0)}.';
      }
      
      // Create and send notification
      final notification = GuardNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: GuardNotificationType.certificateExpiry,
        title: title,
        body: body,
        data: {
          'certificateId': certificateId,
          'certificateType': certificateType.name,
          'certificateNumber': certificateNumber,
          'expiryDate': expiryDate.toIso8601String(),
          'reminderInterval': interval.name,
          'daysUntilExpiry': interval.days,
          'renewalCourses': renewalCourses.map((c) => {
            'id': c.id,
            'name': c.name,
            'provider': c.provider,
            'price': c.price,
            'bookingUrl': c.bookingUrl,
          }).toList(),
          'actionType': 'certificate_renewal_reminder',
        },
        timestamp: DateTime.now(),
        priority: interval.notificationPriority,
        actionUrl: '/profile/certificates',
        actionButtons: renewalCourses.isNotEmpty 
            ? {'courses': 'Cursussen Bekijken', 'later': 'Later Herinneren'}
            : {'renew': 'Verlengen', 'dismiss': 'Sluiten'},
      );
      
      // Send notification through guard notification service
      return await _notificationService.sendCertificateExpiryAlertWithCourses(
        certificateType: certificateType.code,
        expiryDate: expiryDate,
        certificateNumber: certificateNumber,
        daysUntilExpiry: interval.days,
        renewalCourses: renewalCourses.map((course) => {
          'id': course.id,
          'name': course.name,
          'provider': course.provider,
          'price': course.price,
          'nextStartDate': course.nextStartDate.toIso8601String(),
          'isOnline': course.isOnline,
          'bookingUrl': course.bookingUrl,
        }).toList(),
      );
      
    } catch (e) {
      debugPrint('Error sending reminder notification: $e');
      return false;
    }
  }
  
  /// Send immediate notification for expired certificate
  Future<bool> _sendExpiredCertificateNotification(
    String certificateId,
    CertificateType certificateType,
    String certificateNumber,
    DateTime expiryDate,
    String userId,
    List<RenewalCourse> renewalCourses,
  ) async {
    try {
      final daysExpired = DateTime.now().difference(expiryDate).inDays;
      
      return await _notificationService.sendCertificateExpiryAlertWithCourses(
        certificateType: certificateType.code,
        expiryDate: expiryDate,
        certificateNumber: certificateNumber,
        daysUntilExpiry: -daysExpired, // Negative for expired
        renewalCourses: renewalCourses.map((course) => {
          'id': course.id,
          'name': course.name,
          'provider': course.provider,
          'price': course.price,
          'nextStartDate': course.nextStartDate.toIso8601String(),
          'isOnline': course.isOnline,
          'bookingUrl': course.bookingUrl,
        }).toList(),
      );
      
    } catch (e) {
      debugPrint('Error sending expired certificate notification: $e');
      return false;
    }
  }
  
  /// Get reminder status for a certificate
  Future<Map<String, dynamic>?> getReminderStatus(String certificateId, String userId) async {
    try {
      final masterDoc = await _firestore
          .collection(_remindersCollection)
          .doc(certificateId)
          .get();
      
      if (!masterDoc.exists) {
        return null;
      }
      
      final scheduledReminders = await _firestore
          .collection(_scheduledRemindersCollection)
          .where('certificateId', isEqualTo: certificateId)
          .where('userId', isEqualTo: userId)
          .get();
      
      final reminders = scheduledReminders.docs.map((doc) => {
        'id': doc.id,
        'interval': doc.data()['reminderInterval'],
        'reminderDate': doc.data()['reminderDate'],
        'status': doc.data()['status'],
        'sentAt': doc.data()['sentAt'],
      }).toList();
      
      return {
        'certificateId': certificateId,
        'status': masterDoc.data()?['status'],
        'scheduledRemindersCount': masterDoc.data()?['scheduledRemindersCount'],
        'createdAt': masterDoc.data()?['createdAt'],
        'reminders': reminders,
      };
      
    } catch (e) {
      debugPrint('Error getting reminder status: $e');
      return null;
    }
  }
  
  /// Cleanup expired reminder records (maintenance function)
  Future<void> cleanupExpiredReminders() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      
      final expiredQuery = await _firestore
          .collection(_scheduledRemindersCollection)
          .where('status', whereIn: ['sent', 'failed'])
          .where('updatedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(100)
          .get();
      
      if (expiredQuery.docs.isEmpty) return;
      
      final batch = _firestore.batch();
      for (final doc in expiredQuery.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      debugPrint('🧤 Cleaned up ${expiredQuery.docs.length} expired reminder records');
      
    } catch (e) {
      debugPrint('Error during reminder cleanup: $e');
    }
  }
  
  // Helper methods
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatDate(DateTime dateTime) {
    final months = [
      '', 'januari', 'februari', 'maart', 'april', 'mei', 'juni',
      'juli', 'augustus', 'september', 'oktober', 'november', 'december'
    ];
    return '${dateTime.day} ${months[dateTime.month]} ${dateTime.year}';
  }
  
  String _getPriorityColor(ReminderInterval interval) {
    switch (interval) {
      case ReminderInterval.days30:
      case ReminderInterval.days14:
        return '#2196F3'; // Blue
      case ReminderInterval.days7:
        return '#FF9800'; // Orange
      case ReminderInterval.days3:
        return '#FF5722'; // Deep orange
      case ReminderInterval.days1:
        return '#F44336'; // Red
    }
  }
  
  Future<void> _trackReminderSchedulingAnalytics(
    String certificateId,
    CertificateType certificateType,
    int scheduledCount,
    String userId,
  ) async {
    try {
      await _firestore.collection('analytics_events').add({
        'eventType': 'certificate_reminders_scheduled',
        'userId': userId,
        'certificateId': certificateId,
        'certificateType': certificateType.name,
        'scheduledCount': scheduledCount,
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'certificate_reminder_scheduler',
      });
    } catch (e) {
      debugPrint('Error tracking reminder scheduling analytics: $e');
    }
  }
}
