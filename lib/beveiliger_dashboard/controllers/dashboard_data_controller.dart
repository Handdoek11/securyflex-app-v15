import 'dart:async';
import 'package:flutter/material.dart';
import '../../auth/auth_service.dart';
import '../../auth/services/certificate_management_service.dart';
import '../../beveiliger_profiel/services/profile_completion_service.dart';
import '../../beveiliger_profiel/models/profile_completion_data.dart';
import '../../beveiliger_notificaties/services/guard_notification_service.dart';
import '../../beveiliger_notificaties/models/certificate_alert.dart';
import '../../beveiliger_notificaties/models/guard_notification.dart';
import '../../schedule/services/certificate_reminder_scheduler.dart';
import '../../core/caching/platform_cache_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages all data operations for the Beveiliger Dashboard
/// 
/// This controller extracts data logic from the main dashboard,
/// handling profile completion, certificates, and notifications.
class DashboardDataController {
  // Services
  final GuardNotificationService _notificationService = GuardNotificationService.instance;
  final PlatformCacheManager _cacheManager = PlatformCacheManager.instance;
  
  // Data state
  ProfileCompletionData? profileCompletion;
  List<CertificateData> expiringCertificates = [];
  List<CertificateAlert> certificateAlerts = [];
  List<GuardNotification> recentNotifications = [];
  int unreadNotificationCount = 0;
  
  // Loading states
  bool loadingCertificateAlerts = false;
  bool loadingNotifications = false;
  
  // Debounce timer
  Timer? _debounceTimer;
  
  /// Load profile completion data with smart caching
  Future<void> loadProfileCompletion() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId.isEmpty) {
        debugPrint('Cannot load profile completion: User ID is empty');
        return;
      }
      
      // Try to load from cache first
      final cachedProfile = await _cacheManager.getCachedUserProfile(userId);
      if (cachedProfile != null) {
        try {
          profileCompletion = ProfileCompletionData.fromJson(cachedProfile);
          debugPrint('✅ Profile completion loaded from cache: ${profileCompletion!.completionPercentage}%');
          return;
        } catch (e) {
          debugPrint('Cache data invalid, loading fresh: $e');
        }
      }
      
      // Load fresh data
      final completionData = await ProfileCompletionService.instance
          .calculateCompletionPercentage(userId);
      
      profileCompletion = completionData;
      
      // Cache the fresh data
      await _cacheManager.cacheUserProfile(userId, completionData.toJson());
      
      debugPrint('✅ Profile completion loaded fresh: ${completionData.completionPercentage}%');
    } catch (e) {
      debugPrint('Error loading profile completion data: $e');
    }
  }
  
  /// Load certificate alerts
  Future<void> loadCertificateAlerts() async {
    loadingCertificateAlerts = true;
    
    try {
      final userId = AuthService.currentUserId;
      if (userId.isEmpty) {
        debugPrint('Cannot load certificates: User ID is empty');
        return;
      }
      
      // Load expiring certificates - this is a static method
      final expiringCerts = await CertificateManagementService
          .getExpiringCertificates(userId);
      
      // Generate alerts from expiring certificates
      final now = DateTime.now();
      final alerts = expiringCerts.map((cert) {
        final daysUntilExpiry = cert.expirationDate.difference(now).inDays;
        AlertType alertType;
        
        if (daysUntilExpiry <= 1) {
          alertType = AlertType.warning1;
        } else if (daysUntilExpiry <= 7) {
          alertType = AlertType.warning7;
        } else if (daysUntilExpiry <= 30) {
          alertType = AlertType.warning30;
        } else if (daysUntilExpiry <= 60) {
          alertType = AlertType.warning60;
        } else {
          alertType = AlertType.warning90;
        }
        
        return CertificateAlert(
          id: 'alert_${cert.id}',
          userId: userId,
          certificateId: cert.id,
          certificateType: cert.type,
          certificateNumber: cert.number,
          alertType: alertType,
          alertDate: now,
          certificateExpiryDate: cert.expirationDate,
          daysUntilExpiry: daysUntilExpiry,
          renewalCourses: [],
          metadata: {},
          createdAt: now,
          updatedAt: now,
        );
      }).toList();
      
      expiringCertificates = expiringCerts;
      certificateAlerts = alerts;
      
      debugPrint('✅ Certificate alerts loaded: ${alerts.length} alerts, ${expiringCerts.length} expiring');
    } catch (e) {
      debugPrint('Error loading certificate alerts: $e');
    } finally {
      loadingCertificateAlerts = false;
    }
  }
  
  /// Load notification summary
  Future<void> loadNotificationSummary() async {
    loadingNotifications = true;
    
    try {
      final userId = AuthService.currentUserId;
      if (userId.isEmpty) {
        debugPrint('Cannot load notifications: User ID is empty');
        return;
      }
      
      // Load recent notifications
      final notifications = await _notificationService
          .getNotificationHistory(limit: 5);
      
      // Count unread
      final unreadCount = await _notificationService
          .getUnreadCount();
      
      recentNotifications = notifications;
      unreadNotificationCount = unreadCount;
      
      debugPrint('✅ Notifications loaded: ${notifications.length} recent, $unreadCount unread');
    } catch (e) {
      debugPrint('Error loading notification summary: $e');
    } finally {
      loadingNotifications = false;
    }
  }
  
  /// Load all dashboard data
  Future<void> loadAllData() async {
    await Future.wait([
      loadProfileCompletion(),
      loadCertificateAlerts(),
      loadNotificationSummary(),
    ]);
  }
  
  /// Refresh all data
  Future<void> refreshData() async {
    await loadAllData();
  }
  
  /// Dismiss certificate alert
  void dismissAlert(String alertId) {
    certificateAlerts.removeWhere((alert) => alert.id == alertId);
    debugPrint('Certificate alert dismissed: $alertId');
  }
  
  /// Schedule renewal reminder
  Future<void> scheduleRenewalReminder(CertificateAlert alert) async {
    try {
      debugPrint('Scheduling renewal reminder for certificate: ${alert.certificateId}');
      
      final userId = AuthService.currentUserId;
      if (userId.isEmpty) {
        debugPrint('Cannot schedule reminder: User ID is empty');
        return;
      }
      
      // Schedule multiple reminders at different intervals
      final scheduler = CertificateReminderScheduler.instance;
      
      await scheduler.scheduleRenewalReminders(
        certificateId: alert.certificateId,
        certificateType: alert.certificateType,
        certificateNumber: alert.certificateNumber,
        expiryDate: alert.certificateExpiryDate,
        userId: userId,
        renewalCourses: alert.renewalCourses,
      );
      
      debugPrint('✅ Renewal reminders scheduled successfully for ${alert.certificateType.code} certificate');
      
      // Track analytics for reminder scheduling
      await _trackReminderScheduled(alert);
      
    } catch (e) {
      debugPrint('Error scheduling renewal reminder: $e');
    }
  }
  
  /// Track reminder scheduling for analytics
  Future<void> _trackReminderScheduled(CertificateAlert alert) async {
    try {
      await FirebaseFirestore.instance
          .collection('analytics_events')
          .add({
        'userId': AuthService.currentUserId,
        'eventType': 'certificate_reminder_scheduled',
        'certificateType': alert.certificateType.name,
        'daysUntilExpiry': alert.daysUntilExpiry,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': {
          'certificateId': alert.certificateId,
          'alertType': alert.alertType.name,
          'hasRenewalCourses': alert.renewalCourses.isNotEmpty,
        },
      });
    } catch (e) {
      debugPrint('Error tracking reminder scheduled: $e');
    }
  }
  
  /// Clean up resources
  void dispose() {
    _debounceTimer?.cancel();
  }
}