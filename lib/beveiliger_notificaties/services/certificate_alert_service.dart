import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/certificate_management_service.dart';
import '../../company_dashboard/services/analytics_service.dart';
import '../../company_dashboard/models/analytics_data_models.dart';
import 'guard_notification_service.dart';
import '../models/certificate_alert.dart';

/// Comprehensive certificate expiration alert service for SecuryFlex
/// 
/// Features:
/// - Daily background monitoring of all certificate types (WPBR, VCA, BHV, EHBO)
/// - Multi-stage alerts: 90, 60, 30, 7, and 1 day before expiry + expired
/// - Integration with existing WPBR verification service and certificate management
/// - Training course recommendations for certificate renewal
/// - Dutch business compliance with CAO arbeidsrecht requirements
/// - Analytics tracking for alert effectiveness and renewal rates
class CertificateAlertService {
  static final CertificateAlertService _instance = CertificateAlertService._internal();
  factory CertificateAlertService() => _instance;
  CertificateAlertService._internal();

  static CertificateAlertService get instance => _instance;

  // Dependencies - using existing services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GuardNotificationService _notificationService = GuardNotificationService.instance;
  final CertificateManagementService _certificateService = CertificateManagementService();
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  // Service state
  bool _isInitialized = false;
  Timer? _dailyCheckTimer;
  
  // Collections
  static const String _alertsCollection = 'certificate_alerts';
  static const String _alertHistoryCollection = 'certificate_alert_history';
  
  // Alert schedule configuration (days before expiry)
  static const List<int> _alertSchedule = [90, 60, 30, 7, 1];
  static const Duration _dailyCheckInterval = Duration(hours: 24);

  /// Initialize certificate alert service
  /// Integrates with existing background task patterns from time_tracking_service.dart
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize dependencies
      await _notificationService.initialize();
      await _certificateService.initialize();
      
      // Schedule daily certificate expiry checks
      await _scheduleDailyChecks();
      
      // Clean up old alerts
      await _cleanupExpiredAlerts();
      
      _isInitialized = true;
      // Reduce log verbosity for cleaner output
      if (kDebugMode) {
        debugPrint('📜 CertificateAlertService ready');
      }

      // Track initialization
      await _trackAnalyticsEvent('certificate_alert_service_initialized', {
        'timestamp': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      debugPrint('Error initializing CertificateAlertService: $e');
      rethrow;
    }
  }

  /// Schedule daily certificate expiry checks using existing background patterns
  Future<void> _scheduleDailyChecks() async {
    // Cancel existing timer if any
    _dailyCheckTimer?.cancel();
    
    // Schedule next check for midnight
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);
    
    // Initial check after delay to midnight, then daily
    Timer(timeUntilMidnight, () {
      _performDailyCheck();
      _dailyCheckTimer = Timer.periodic(_dailyCheckInterval, (_) {
        _performDailyCheck();
      });
    });
    
    debugPrint('Daily certificate checks scheduled for midnight');
  }

  /// Perform daily certificate expiry check for all users
  /// Integrates with existing certificate verification and management systems
  Future<void> _performDailyCheck() async {
    if (!_isInitialized) return;
    
    try {
      debugPrint('Starting daily certificate expiry check');
      
      // Get all users with certificates
      final usersWithCertificates = await _getUsersWithCertificates();
      
      int totalChecked = 0;
      int alertsSent = 0;
      
      for (final userId in usersWithCertificates) {
        try {
          final alertsSentForUser = await _checkUserCertificates(userId);
          alertsSent += alertsSentForUser;
          totalChecked++;
        } catch (e) {
          debugPrint('Error checking user certificates: $e');
        }
      }
      
      // Track daily check completion
      await _trackAnalyticsEvent('daily_certificate_check_completed', {
        'users_checked': totalChecked,
        'alerts_sent': alertsSent,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      debugPrint('Daily certificate check completed: $totalChecked users, $alertsSent alerts');
      
    } catch (e) {
      debugPrint('Error in daily certificate check: $e');
    }
  }

  /// Get all users who have certificates
  Future<List<String>> _getUsersWithCertificates() async {
    try {
      final snapshot = await _firestore.collection('user_certificates').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error fetching users with certificates: $e');
      return [];
    }
  }

  /// Check certificates for a specific user and send alerts if needed
  Future<int> _checkUserCertificates(String userId) async {
    int alertsSent = 0;
    
    try {
      // Get all certificates for the user using existing service
      final certificates = await _certificateService.getUserCertificates(userId);
      
      for (final certificate in certificates) {
        final alert = await _shouldSendAlert(certificate);
        if (alert != null) {
          final success = await _sendCertificateAlert(userId, certificate, alert);
          if (success) {
            alertsSent++;
            await _recordAlertSent(userId, certificate.id, alert.alertType);
          }
        }
      }
      
    } catch (e) {
      debugPrint('Error checking certificates for user $userId: $e');
    }
    
    return alertsSent;
  }

  /// Determine if an alert should be sent for a certificate
  Future<CertificateAlert?> _shouldSendAlert(CertificateData certificate) async {
    try {
      final daysUntilExpiry = certificate.daysUntilExpiration;
      
      // Check if certificate is already expired
      if (certificate.isExpired) {
        final hasExpiredAlert = await _hasAlertBeenSent(certificate.id, AlertType.expired);
        if (!hasExpiredAlert) {
          return CertificateAlert.createExpiredAlert(certificate);
        }
        return null;
      }
      
      // Check each alert threshold
      for (final days in _alertSchedule) {
        if (daysUntilExpiry <= days && daysUntilExpiry > (days - 1)) {
          final alertType = _getAlertTypeForDays(days);
          final hasAlertBeenSent = await _hasAlertBeenSent(certificate.id, alertType);
          
          if (!hasAlertBeenSent) {
            return CertificateAlert.createExpiryWarning(
              certificate, 
              alertType, 
              days,
              await _getRenewalCourses(certificate.type),
            );
          }
        }
      }
      
      return null;
      
    } catch (e) {
      debugPrint('Error checking alert for certificate ${certificate.id}: $e');
      return null;
    }
  }

  /// Check if an alert has already been sent for a certificate
  Future<bool> _hasAlertBeenSent(String certificateId, AlertType alertType) async {
    try {
      final query = await _firestore
          .collection(_alertsCollection)
          .where('certificateId', isEqualTo: certificateId)
          .where('alertType', isEqualTo: alertType.name)
          .where('sent', isEqualTo: true)
          .get();
          
      return query.docs.isNotEmpty;
      
    } catch (e) {
      debugPrint('Error checking alert history: $e');
      return false; // Default to false to allow alert sending
    }
  }

  /// Send certificate expiration alert using existing notification service
  Future<bool> _sendCertificateAlert(
    String userId,
    CertificateData certificate,
    CertificateAlert alert,
  ) async {
    try {
      // Send notification using existing GuardNotificationService
      final success = await _notificationService.sendCertificateExpiryAlert(
        certificateType: certificate.type.code,
        expiryDate: certificate.expirationDate,
        certificateNumber: certificate.number,
      );
      
      if (success && alert.renewalCourses.isNotEmpty) {
        // Send follow-up notification with renewal course suggestions
        await _sendRenewalCourseSuggestion(userId, certificate, alert.renewalCourses);
      }
      
      return success;
      
    } catch (e) {
      debugPrint('Error sending certificate alert: $e');
      return false;
    }
  }

  /// Send renewal course suggestion notification
  Future<void> _sendRenewalCourseSuggestion(
    String userId,
    CertificateData certificate,
    List<RenewalCourse> courses,
  ) async {
    try {
      // Format course suggestions for notification
      final courseNames = courses.take(3).map((c) => c.name).join(', ');
      
      await _notificationService.sendPaymentUpdate(
        paymentId: 'renewal_suggestion',
        amount: 0.0,
        description: 'Verlengingscursussen beschikbaar: $courseNames',
        status: 'info',
      );
      
    } catch (e) {
      debugPrint('Error sending renewal course suggestion: $e');
    }
  }

  /// Record that an alert has been sent
  Future<void> _recordAlertSent(String userId, String certificateId, AlertType alertType) async {
    try {
      final alertRecord = {
        'userId': userId,
        'certificateId': certificateId,
        'alertType': alertType.name,
        'sent': true,
        'sentAt': Timestamp.fromDate(DateTime.now()),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };
      
      await _firestore.collection(_alertsCollection).add(alertRecord);
      
      // Also add to history for analytics
      await _firestore.collection(_alertHistoryCollection).add({
        ...alertRecord,
        'actionTaken': false,
        'certificateRenewed': false,
      });
      
    } catch (e) {
      debugPrint('Error recording alert sent: $e');
    }
  }

  /// Get renewal courses for a certificate type
  /// In a full implementation, this would query the training courses collection
  Future<List<RenewalCourse>> _getRenewalCourses(CertificateType type) async {
    try {
      // Mock implementation - in reality would query training courses
      switch (type) {
        case CertificateType.wpbr:
          return [
            RenewalCourse(
              id: 'wpbr_renewal_001',
              name: 'WPBR Herhalingscursus Particuliere Beveiliging',
              provider: 'Beveiligingsacademie Nederland',
              duration: Duration(hours: 16),
              price: 395.0,
              nextStartDate: DateTime.now().add(Duration(days: 14)),
              isOnline: false,
            ),
            RenewalCourse(
              id: 'wpbr_renewal_002',
              name: 'WPBR Update Training Online',
              provider: 'E-Learning Beveiliging',
              duration: Duration(hours: 8),
              price: 295.0,
              nextStartDate: DateTime.now().add(Duration(days: 3)),
              isOnline: true,
            ),
          ];
        case CertificateType.vca:
          return [
            RenewalCourse(
              id: 'vca_renewal_001',
              name: 'VCA Herhalingscursus Basis',
              provider: 'VCA Training Center',
              duration: Duration(hours: 4),
              price: 125.0,
              nextStartDate: DateTime.now().add(Duration(days: 7)),
              isOnline: false,
            ),
          ];
        case CertificateType.bhv:
          return [
            RenewalCourse(
              id: 'bhv_renewal_001',
              name: 'BHV Herhalingstraining',
              provider: 'Arbo Training Solutions',
              duration: Duration(hours: 4),
              price: 89.0,
              nextStartDate: DateTime.now().add(Duration(days: 5)),
              isOnline: false,
            ),
          ];
        case CertificateType.ehbo:
          return [
            RenewalCourse(
              id: 'ehbo_renewal_001',
              name: 'EHBO Herhalingscursus',
              provider: 'Rode Kruis Nederland',
              duration: Duration(hours: 4),
              price: 65.0,
              nextStartDate: DateTime.now().add(Duration(days: 10)),
              isOnline: false,
            ),
          ];
      }
    } catch (e) {
      debugPrint('Error fetching renewal courses: $e');
      return [];
    }
  }

  /// Get alert type based on days until expiry
  AlertType _getAlertTypeForDays(int days) {
    switch (days) {
      case 90:
        return AlertType.warning90;
      case 60:
        return AlertType.warning60;
      case 30:
        return AlertType.warning30;
      case 7:
        return AlertType.warning7;
      case 1:
        return AlertType.warning1;
      default:
        return AlertType.warning30;
    }
  }

  /// Get certificates expiring within specified days for dashboard display
  Future<List<CertificateData>> getExpiringCertificates(String userId, {int days = 30}) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      return await CertificateManagementService.getExpiringCertificates(userId);
      
    } catch (e) {
      debugPrint('Error getting expiring certificates: $e');
      return [];
    }
  }

  /// Get certificate alerts for a user
  Future<List<CertificateAlert>> getUserCertificateAlerts(String userId) async {
    try {
      final query = await _firestore
          .collection(_alertsCollection)
          .where('userId', isEqualTo: userId)
          .where('sent', isEqualTo: true)
          .orderBy('sentAt', descending: true)
          .limit(10)
          .get();
          
      final alerts = <CertificateAlert>[];
      for (final doc in query.docs) {
        try {
          final alert = CertificateAlert.fromFirestore(doc);
          alerts.add(alert);
        } catch (e) {
          debugPrint('Error parsing alert document: $e');
        }
      }
      
      return alerts;
      
    } catch (e) {
      debugPrint('Error getting user certificate alerts: $e');
      return [];
    }
  }

  /// Mark certificate as renewed to stop alerts
  Future<void> markCertificateRenewed(String certificateId, DateTime newExpiryDate) async {
    try {
      // Update certificate in the management system
      await _certificateService.updateCertificate(certificateId, {
        'expirationDate': Timestamp.fromDate(newExpiryDate),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // Mark related alerts as resolved
      final alertsQuery = await _firestore
          .collection(_alertsCollection)
          .where('certificateId', isEqualTo: certificateId)
          .get();
          
      final batch = _firestore.batch();
      for (final doc in alertsQuery.docs) {
        batch.update(doc.reference, {
          'resolved': true,
          'resolvedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();
      
      // Track renewal
      await _trackAnalyticsEvent('certificate_renewed', {
        'certificate_id': certificateId,
        'new_expiry_date': newExpiryDate.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      debugPrint('Error marking certificate as renewed: $e');
    }
  }

  /// Clean up expired alerts and old history
  Future<void> _cleanupExpiredAlerts() async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: 90));
      
      // Clean up old alerts
      final oldAlerts = await _firestore
          .collection(_alertsCollection)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();
          
      final batch = _firestore.batch();
      for (final doc in oldAlerts.docs) {
        batch.delete(doc.reference);
      }
      
      if (oldAlerts.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('Cleaned up ${oldAlerts.docs.length} old certificate alerts');
      }
      
    } catch (e) {
      debugPrint('Error cleaning up expired alerts: $e');
    }
  }

  /// Track analytics events for certificate alerts
  Future<void> _trackAnalyticsEvent(String eventType, Map<String, dynamic> data) async {
    try {
      await _analyticsService.trackEvent(
        jobId: 'certificate_alerts',
        eventType: JobEventType.completion,
        userId: data['userId']?.toString() ?? 'system',
        metadata: {
          'event_type': eventType,
          ...data,
          'service': 'CertificateAlertService',
          'version': '1.0.0',
        },
      );
    } catch (e) {
      debugPrint('Error tracking analytics event: $e');
    }
  }

  /// Get certificate alert statistics for admin dashboard
  Future<Map<String, dynamic>> getAlertStatistics({DateTime? startDate, DateTime? endDate}) async {
    try {
      final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      final alertsQuery = await _firestore
          .collection(_alertHistoryCollection)
          .where('sentAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('sentAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
          
      final totalAlerts = alertsQuery.docs.length;
      final actionTaken = alertsQuery.docs.where((doc) => doc.data()['actionTaken'] == true).length;
      final certificatesRenewed = alertsQuery.docs.where((doc) => doc.data()['certificateRenewed'] == true).length;
      
      // Calculate effectiveness rate
      final effectivenessRate = totalAlerts > 0 ? (certificatesRenewed / totalAlerts * 100) : 0.0;
      
      return {
        'total_alerts_sent': totalAlerts,
        'action_taken_count': actionTaken,
        'certificates_renewed': certificatesRenewed,
        'effectiveness_rate': effectivenessRate.toStringAsFixed(1),
        'period_start': start.toIso8601String(),
        'period_end': end.toIso8601String(),
      };
      
    } catch (e) {
      debugPrint('Error getting alert statistics: $e');
      return {
        'total_alerts_sent': 0,
        'action_taken_count': 0,
        'certificates_renewed': 0,
        'effectiveness_rate': '0.0',
        'error': e.toString(),
      };
    }
  }

  /// Dispose service and clean up resources
  void dispose() {
    _dailyCheckTimer?.cancel();
    _isInitialized = false;
    debugPrint('CertificateAlertService disposed');
  }
}