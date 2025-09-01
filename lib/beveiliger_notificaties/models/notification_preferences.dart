import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Comprehensive notification preferences model for SecuryFlex guards
/// Integrates with existing SettingsService patterns for preference storage
/// 
/// Features:
/// - Granular per-category notification controls (Jobs, Certificates, Payments, System)
/// - Multiple delivery methods per category (push, email, in-app)
/// - Quiet hours support with start/end time configuration
/// - Guard-specific business logic compliance
/// - Integration with existing Dutch localization patterns
class NotificationPreferences extends Equatable {
  // Master notification toggle
  final bool masterNotificationsEnabled;
  
  // Job-related notifications
  final bool jobAlertsEnabled;
  final bool jobAlertsPush;
  final bool jobAlertsEmail;
  final bool jobAlertsInApp;
  final bool jobMatchNotifications;
  final bool shiftReminders;
  final bool emergencyJobAlerts;
  
  // Certificate-related notifications
  final bool certificateAlertsEnabled;
  final bool certificateAlertsPush;
  final bool certificateAlertsEmail;
  final bool certificateAlertsInApp;
  final bool wpbrExpiryAlerts;
  final bool renewalCourseNotifications;
  
  // Payment-related notifications
  final bool paymentAlertsEnabled;
  final bool paymentAlertsPush;
  final bool paymentAlertsEmail;
  final bool paymentAlertsInApp;
  final bool paymentCompletedNotifications;
  final bool invoiceNotifications;
  final bool payrollUpdates;
  
  // System-related notifications
  final bool systemAlertsEnabled;
  final bool systemAlertsPush;
  final bool systemAlertsEmail;
  final bool systemAlertsInApp;
  final bool securityAlerts;
  final bool maintenanceNotifications;
  final bool appUpdates;
  
  // Notification behavior settings
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool showPreview;
  final bool ledNotifications;
  
  // Quiet hours configuration
  final bool quietHoursEnabled;
  final int quietHoursStartHour;
  final int quietHoursStartMinute;
  final int quietHoursEndHour;
  final int quietHoursEndMinute;
  final bool quietHoursAllowUrgent; // Allow urgent notifications during quiet hours
  
  // Frequency settings
  final NotificationFrequency jobAlertFrequency;
  final NotificationFrequency certificateAlertFrequency;
  final bool digestMode; // Bundle non-urgent notifications
  final int digestHour; // Hour to send digest (0-23)
  
  // Advanced settings
  final bool locationBasedNotifications;
  final double maxDistanceForJobAlerts; // km
  final List<String> mutedCompanies; // Company IDs to mute notifications from
  final List<String> preferredJobTypes; // Only get alerts for preferred job types
  
  const NotificationPreferences({
    // Master toggle
    this.masterNotificationsEnabled = true,
    
    // Job notifications defaults
    this.jobAlertsEnabled = true,
    this.jobAlertsPush = true,
    this.jobAlertsEmail = false,
    this.jobAlertsInApp = true,
    this.jobMatchNotifications = true,
    this.shiftReminders = true,
    this.emergencyJobAlerts = true,
    
    // Certificate notifications defaults
    this.certificateAlertsEnabled = true,
    this.certificateAlertsPush = true,
    this.certificateAlertsEmail = true, // Important for WPBR compliance
    this.certificateAlertsInApp = true,
    this.wpbrExpiryAlerts = true,
    this.renewalCourseNotifications = true,
    
    // Payment notifications defaults
    this.paymentAlertsEnabled = true,
    this.paymentAlertsPush = true,
    this.paymentAlertsEmail = true, // Important for financial records
    this.paymentAlertsInApp = true,
    this.paymentCompletedNotifications = true,
    this.invoiceNotifications = true,
    this.payrollUpdates = true,
    
    // System notifications defaults
    this.systemAlertsEnabled = true,
    this.systemAlertsPush = true,
    this.systemAlertsEmail = false,
    this.systemAlertsInApp = true,
    this.securityAlerts = true,
    this.maintenanceNotifications = false,
    this.appUpdates = true,
    
    // Behavior defaults
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.showPreview = true,
    this.ledNotifications = false,
    
    // Quiet hours defaults (22:00 - 08:00)
    this.quietHoursEnabled = false,
    this.quietHoursStartHour = 22,
    this.quietHoursStartMinute = 0,
    this.quietHoursEndHour = 8,
    this.quietHoursEndMinute = 0,
    this.quietHoursAllowUrgent = true,
    
    // Frequency defaults
    this.jobAlertFrequency = NotificationFrequency.immediately,
    this.certificateAlertFrequency = NotificationFrequency.immediately,
    this.digestMode = false,
    this.digestHour = 9, // 9:00 AM
    
    // Advanced defaults
    this.locationBasedNotifications = true,
    this.maxDistanceForJobAlerts = 25.0, // 25km default
    this.mutedCompanies = const [],
    this.preferredJobTypes = const [],
  });

  /// Create copy with updated properties
  NotificationPreferences copyWith({
    bool? masterNotificationsEnabled,
    bool? jobAlertsEnabled,
    bool? jobAlertsPush,
    bool? jobAlertsEmail,
    bool? jobAlertsInApp,
    bool? jobMatchNotifications,
    bool? shiftReminders,
    bool? emergencyJobAlerts,
    bool? certificateAlertsEnabled,
    bool? certificateAlertsPush,
    bool? certificateAlertsEmail,
    bool? certificateAlertsInApp,
    bool? wpbrExpiryAlerts,
    bool? renewalCourseNotifications,
    bool? paymentAlertsEnabled,
    bool? paymentAlertsPush,
    bool? paymentAlertsEmail,
    bool? paymentAlertsInApp,
    bool? paymentCompletedNotifications,
    bool? invoiceNotifications,
    bool? payrollUpdates,
    bool? systemAlertsEnabled,
    bool? systemAlertsPush,
    bool? systemAlertsEmail,
    bool? systemAlertsInApp,
    bool? securityAlerts,
    bool? maintenanceNotifications,
    bool? appUpdates,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? showPreview,
    bool? ledNotifications,
    bool? quietHoursEnabled,
    int? quietHoursStartHour,
    int? quietHoursStartMinute,
    int? quietHoursEndHour,
    int? quietHoursEndMinute,
    bool? quietHoursAllowUrgent,
    NotificationFrequency? jobAlertFrequency,
    NotificationFrequency? certificateAlertFrequency,
    bool? digestMode,
    int? digestHour,
    bool? locationBasedNotifications,
    double? maxDistanceForJobAlerts,
    List<String>? mutedCompanies,
    List<String>? preferredJobTypes,
  }) {
    return NotificationPreferences(
      masterNotificationsEnabled: masterNotificationsEnabled ?? this.masterNotificationsEnabled,
      jobAlertsEnabled: jobAlertsEnabled ?? this.jobAlertsEnabled,
      jobAlertsPush: jobAlertsPush ?? this.jobAlertsPush,
      jobAlertsEmail: jobAlertsEmail ?? this.jobAlertsEmail,
      jobAlertsInApp: jobAlertsInApp ?? this.jobAlertsInApp,
      jobMatchNotifications: jobMatchNotifications ?? this.jobMatchNotifications,
      shiftReminders: shiftReminders ?? this.shiftReminders,
      emergencyJobAlerts: emergencyJobAlerts ?? this.emergencyJobAlerts,
      certificateAlertsEnabled: certificateAlertsEnabled ?? this.certificateAlertsEnabled,
      certificateAlertsPush: certificateAlertsPush ?? this.certificateAlertsPush,
      certificateAlertsEmail: certificateAlertsEmail ?? this.certificateAlertsEmail,
      certificateAlertsInApp: certificateAlertsInApp ?? this.certificateAlertsInApp,
      wpbrExpiryAlerts: wpbrExpiryAlerts ?? this.wpbrExpiryAlerts,
      renewalCourseNotifications: renewalCourseNotifications ?? this.renewalCourseNotifications,
      paymentAlertsEnabled: paymentAlertsEnabled ?? this.paymentAlertsEnabled,
      paymentAlertsPush: paymentAlertsPush ?? this.paymentAlertsPush,
      paymentAlertsEmail: paymentAlertsEmail ?? this.paymentAlertsEmail,
      paymentAlertsInApp: paymentAlertsInApp ?? this.paymentAlertsInApp,
      paymentCompletedNotifications: paymentCompletedNotifications ?? this.paymentCompletedNotifications,
      invoiceNotifications: invoiceNotifications ?? this.invoiceNotifications,
      payrollUpdates: payrollUpdates ?? this.payrollUpdates,
      systemAlertsEnabled: systemAlertsEnabled ?? this.systemAlertsEnabled,
      systemAlertsPush: systemAlertsPush ?? this.systemAlertsPush,
      systemAlertsEmail: systemAlertsEmail ?? this.systemAlertsEmail,
      systemAlertsInApp: systemAlertsInApp ?? this.systemAlertsInApp,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      maintenanceNotifications: maintenanceNotifications ?? this.maintenanceNotifications,
      appUpdates: appUpdates ?? this.appUpdates,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      showPreview: showPreview ?? this.showPreview,
      ledNotifications: ledNotifications ?? this.ledNotifications,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
      quietHoursStartMinute: quietHoursStartMinute ?? this.quietHoursStartMinute,
      quietHoursEndHour: quietHoursEndHour ?? this.quietHoursEndHour,
      quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
      quietHoursAllowUrgent: quietHoursAllowUrgent ?? this.quietHoursAllowUrgent,
      jobAlertFrequency: jobAlertFrequency ?? this.jobAlertFrequency,
      certificateAlertFrequency: certificateAlertFrequency ?? this.certificateAlertFrequency,
      digestMode: digestMode ?? this.digestMode,
      digestHour: digestHour ?? this.digestHour,
      locationBasedNotifications: locationBasedNotifications ?? this.locationBasedNotifications,
      maxDistanceForJobAlerts: maxDistanceForJobAlerts ?? this.maxDistanceForJobAlerts,
      mutedCompanies: mutedCompanies ?? this.mutedCompanies,
      preferredJobTypes: preferredJobTypes ?? this.preferredJobTypes,
    );
  }

  /// Check if quiet hours are currently active
  bool get isQuietHoursActive {
    if (!quietHoursEnabled) return false;
    
    final now = TimeOfDay.now();
    final start = TimeOfDay(
      hour: quietHoursStartHour,
      minute: quietHoursStartMinute,
    );
    final end = TimeOfDay(
      hour: quietHoursEndHour,
      minute: quietHoursEndMinute,
    );
    
    // Convert to minutes for easier comparison
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    // Handle overnight quiet hours (e.g., 22:00 to 08:00)
    if (startMinutes > endMinutes) {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    } else {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
  }

  /// Check if a specific notification should be sent based on preferences
  bool shouldSendNotification(NotificationCategory category, NotificationDeliveryMethod method) {
    // Check master toggle first
    if (!masterNotificationsEnabled) return false;
    
    // Check category-specific settings
    switch (category) {
      case NotificationCategory.jobOpportunity:
        if (!jobAlertsEnabled) return false;
        switch (method) {
          case NotificationDeliveryMethod.push:
            return jobAlertsPush;
          case NotificationDeliveryMethod.email:
            return jobAlertsEmail;
          case NotificationDeliveryMethod.inApp:
            return jobAlertsInApp;
        }
      case NotificationCategory.certificateExpiry:
        if (!certificateAlertsEnabled) return false;
        switch (method) {
          case NotificationDeliveryMethod.push:
            return certificateAlertsPush;
          case NotificationDeliveryMethod.email:
            return certificateAlertsEmail;
          case NotificationDeliveryMethod.inApp:
            return certificateAlertsInApp;
        }
      case NotificationCategory.paymentUpdate:
        if (!paymentAlertsEnabled) return false;
        switch (method) {
          case NotificationDeliveryMethod.push:
            return paymentAlertsPush;
          case NotificationDeliveryMethod.email:
            return paymentAlertsEmail;
          case NotificationDeliveryMethod.inApp:
            return paymentAlertsInApp;
        }
      case NotificationCategory.systemAlert:
        if (!systemAlertsEnabled) return false;
        switch (method) {
          case NotificationDeliveryMethod.push:
            return systemAlertsPush;
          case NotificationDeliveryMethod.email:
            return systemAlertsEmail;
          case NotificationDeliveryMethod.inApp:
            return systemAlertsInApp;
        }
    }
  }

  /// Get Dutch description of current notification status
  String get notificationStatusDescription {
    if (!masterNotificationsEnabled) {
      return 'Alle notificaties uitgeschakeld';
    }
    
    final enabledCategories = <String>[];
    if (jobAlertsEnabled) enabledCategories.add('Jobs');
    if (certificateAlertsEnabled) enabledCategories.add('Certificaten');
    if (paymentAlertsEnabled) enabledCategories.add('Betalingen');
    if (systemAlertsEnabled) enabledCategories.add('Systeem');
    
    if (enabledCategories.isEmpty) {
      return 'Geen notificaties ingeschakeld';
    }
    
    if (isQuietHoursActive) {
      return '${enabledCategories.join(', ')} - Stille uren actief';
    }
    
    return '${enabledCategories.join(', ')} ingeschakeld';
  }

  /// Get formatted quiet hours string for display
  String get quietHoursDisplayText {
    if (!quietHoursEnabled) return 'Uitgeschakeld';
    
    final start = '${quietHoursStartHour.toString().padLeft(2, '0')}:${quietHoursStartMinute.toString().padLeft(2, '0')}';
    final end = '${quietHoursEndHour.toString().padLeft(2, '0')}:${quietHoursEndMinute.toString().padLeft(2, '0')}';
    
    return '$start - $end';
  }

  /// Validate settings integrity
  bool get isValid {
    // Time validation
    if (quietHoursStartHour < 0 || quietHoursStartHour > 23) return false;
    if (quietHoursEndHour < 0 || quietHoursEndHour > 23) return false;
    if (quietHoursStartMinute < 0 || quietHoursStartMinute > 59) return false;
    if (quietHoursEndMinute < 0 || quietHoursEndMinute > 59) return false;
    
    // Digest hour validation
    if (digestHour < 0 || digestHour > 23) return false;
    
    // Distance validation
    if (maxDistanceForJobAlerts < 0 || maxDistanceForJobAlerts > 200) return false; // Max 200km
    
    return true;
  }

  /// Convert to Map for storage in SharedPreferences/Firestore
  Map<String, dynamic> toMap() {
    return {
      'masterNotificationsEnabled': masterNotificationsEnabled,
      'jobAlertsEnabled': jobAlertsEnabled,
      'jobAlertsPush': jobAlertsPush,
      'jobAlertsEmail': jobAlertsEmail,
      'jobAlertsInApp': jobAlertsInApp,
      'jobMatchNotifications': jobMatchNotifications,
      'shiftReminders': shiftReminders,
      'emergencyJobAlerts': emergencyJobAlerts,
      'certificateAlertsEnabled': certificateAlertsEnabled,
      'certificateAlertsPush': certificateAlertsPush,
      'certificateAlertsEmail': certificateAlertsEmail,
      'certificateAlertsInApp': certificateAlertsInApp,
      'wpbrExpiryAlerts': wpbrExpiryAlerts,
      'renewalCourseNotifications': renewalCourseNotifications,
      'paymentAlertsEnabled': paymentAlertsEnabled,
      'paymentAlertsPush': paymentAlertsPush,
      'paymentAlertsEmail': paymentAlertsEmail,
      'paymentAlertsInApp': paymentAlertsInApp,
      'paymentCompletedNotifications': paymentCompletedNotifications,
      'invoiceNotifications': invoiceNotifications,
      'payrollUpdates': payrollUpdates,
      'systemAlertsEnabled': systemAlertsEnabled,
      'systemAlertsPush': systemAlertsPush,
      'systemAlertsEmail': systemAlertsEmail,
      'systemAlertsInApp': systemAlertsInApp,
      'securityAlerts': securityAlerts,
      'maintenanceNotifications': maintenanceNotifications,
      'appUpdates': appUpdates,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'showPreview': showPreview,
      'ledNotifications': ledNotifications,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStartHour': quietHoursStartHour,
      'quietHoursStartMinute': quietHoursStartMinute,
      'quietHoursEndHour': quietHoursEndHour,
      'quietHoursEndMinute': quietHoursEndMinute,
      'quietHoursAllowUrgent': quietHoursAllowUrgent,
      'jobAlertFrequency': jobAlertFrequency.name,
      'certificateAlertFrequency': certificateAlertFrequency.name,
      'digestMode': digestMode,
      'digestHour': digestHour,
      'locationBasedNotifications': locationBasedNotifications,
      'maxDistanceForJobAlerts': maxDistanceForJobAlerts,
      'mutedCompanies': mutedCompanies,
      'preferredJobTypes': preferredJobTypes,
    };
  }

  /// Create from Map (from SharedPreferences/Firestore)
  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      masterNotificationsEnabled: map['masterNotificationsEnabled'] ?? true,
      jobAlertsEnabled: map['jobAlertsEnabled'] ?? true,
      jobAlertsPush: map['jobAlertsPush'] ?? true,
      jobAlertsEmail: map['jobAlertsEmail'] ?? false,
      jobAlertsInApp: map['jobAlertsInApp'] ?? true,
      jobMatchNotifications: map['jobMatchNotifications'] ?? true,
      shiftReminders: map['shiftReminders'] ?? true,
      emergencyJobAlerts: map['emergencyJobAlerts'] ?? true,
      certificateAlertsEnabled: map['certificateAlertsEnabled'] ?? true,
      certificateAlertsPush: map['certificateAlertsPush'] ?? true,
      certificateAlertsEmail: map['certificateAlertsEmail'] ?? true,
      certificateAlertsInApp: map['certificateAlertsInApp'] ?? true,
      wpbrExpiryAlerts: map['wpbrExpiryAlerts'] ?? true,
      renewalCourseNotifications: map['renewalCourseNotifications'] ?? true,
      paymentAlertsEnabled: map['paymentAlertsEnabled'] ?? true,
      paymentAlertsPush: map['paymentAlertsPush'] ?? true,
      paymentAlertsEmail: map['paymentAlertsEmail'] ?? true,
      paymentAlertsInApp: map['paymentAlertsInApp'] ?? true,
      paymentCompletedNotifications: map['paymentCompletedNotifications'] ?? true,
      invoiceNotifications: map['invoiceNotifications'] ?? true,
      payrollUpdates: map['payrollUpdates'] ?? true,
      systemAlertsEnabled: map['systemAlertsEnabled'] ?? true,
      systemAlertsPush: map['systemAlertsPush'] ?? true,
      systemAlertsEmail: map['systemAlertsEmail'] ?? false,
      systemAlertsInApp: map['systemAlertsInApp'] ?? true,
      securityAlerts: map['securityAlerts'] ?? true,
      maintenanceNotifications: map['maintenanceNotifications'] ?? false,
      appUpdates: map['appUpdates'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      showPreview: map['showPreview'] ?? true,
      ledNotifications: map['ledNotifications'] ?? false,
      quietHoursEnabled: map['quietHoursEnabled'] ?? false,
      quietHoursStartHour: map['quietHoursStartHour'] ?? 22,
      quietHoursStartMinute: map['quietHoursStartMinute'] ?? 0,
      quietHoursEndHour: map['quietHoursEndHour'] ?? 8,
      quietHoursEndMinute: map['quietHoursEndMinute'] ?? 0,
      quietHoursAllowUrgent: map['quietHoursAllowUrgent'] ?? true,
      jobAlertFrequency: NotificationFrequency.values.firstWhere(
        (e) => e.name == map['jobAlertFrequency'],
        orElse: () => NotificationFrequency.immediately,
      ),
      certificateAlertFrequency: NotificationFrequency.values.firstWhere(
        (e) => e.name == map['certificateAlertFrequency'],
        orElse: () => NotificationFrequency.immediately,
      ),
      digestMode: map['digestMode'] ?? false,
      digestHour: map['digestHour'] ?? 9,
      locationBasedNotifications: map['locationBasedNotifications'] ?? true,
      maxDistanceForJobAlerts: (map['maxDistanceForJobAlerts'] ?? 25.0).toDouble(),
      mutedCompanies: List<String>.from(map['mutedCompanies'] ?? []),
      preferredJobTypes: List<String>.from(map['preferredJobTypes'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
    masterNotificationsEnabled,
    jobAlertsEnabled,
    jobAlertsPush,
    jobAlertsEmail,
    jobAlertsInApp,
    jobMatchNotifications,
    shiftReminders,
    emergencyJobAlerts,
    certificateAlertsEnabled,
    certificateAlertsPush,
    certificateAlertsEmail,
    certificateAlertsInApp,
    wpbrExpiryAlerts,
    renewalCourseNotifications,
    paymentAlertsEnabled,
    paymentAlertsPush,
    paymentAlertsEmail,
    paymentAlertsInApp,
    paymentCompletedNotifications,
    invoiceNotifications,
    payrollUpdates,
    systemAlertsEnabled,
    systemAlertsPush,
    systemAlertsEmail,
    systemAlertsInApp,
    securityAlerts,
    maintenanceNotifications,
    appUpdates,
    soundEnabled,
    vibrationEnabled,
    showPreview,
    ledNotifications,
    quietHoursEnabled,
    quietHoursStartHour,
    quietHoursStartMinute,
    quietHoursEndHour,
    quietHoursEndMinute,
    quietHoursAllowUrgent,
    jobAlertFrequency,
    certificateAlertFrequency,
    digestMode,
    digestHour,
    locationBasedNotifications,
    maxDistanceForJobAlerts,
    mutedCompanies,
    preferredJobTypes,
  ];

  @override
  String toString() {
    return 'NotificationPreferences('
        'master: $masterNotificationsEnabled, '
        'jobs: $jobAlertsEnabled, '
        'certs: $certificateAlertsEnabled, '
        'payments: $paymentAlertsEnabled, '
        'system: $systemAlertsEnabled, '
        'quietHours: $quietHoursEnabled'
        ')';
  }
}

/// Notification frequency options for digest mode
enum NotificationFrequency {
  immediately('Onmiddellijk'),
  hourly('Elk uur'),
  daily('Dagelijks'),
  weekly('Wekelijks');

  const NotificationFrequency(this.displayName);
  final String displayName;
}

/// Notification categories for preference management
enum NotificationCategory {
  jobOpportunity,
  certificateExpiry,
  paymentUpdate,
  systemAlert,
}

/// Notification delivery methods
enum NotificationDeliveryMethod {
  push,
  email,
  inApp,
}