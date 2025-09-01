import 'package:cloud_firestore/cloud_firestore.dart';

/// Guard notification types for SecuryFlex platform
enum GuardNotificationType {
  jobOpportunity,      // New job matches based on specializations
  shiftReminder,       // Upcoming shift reminders
  paymentUpdate,       // Payment processed/received
  certificateExpiry,   // WPBR/certificate expiring soon
  emergencyAlert,      // Urgent security alerts
  systemUpdate,        // App updates and maintenance
  profileUpdate,       // Profile completion reminders
  applicationAccepted, // Job application accepted
  applicationRejected, // Job application rejected
  jobUpdate,          // General job status updates
}

/// Notification priority levels
enum NotificationPriority {
  low,        // Profile updates, tips
  medium,     // Job opportunities, reminders
  high,       // Shift reminders, payments
  urgent,     // Emergency alerts, critical updates
}

/// Guard notification delivery status
enum NotificationDeliveryStatus {
  pending,    // Scheduled but not sent
  sent,       // Sent to Firebase
  delivered,  // Delivered to device
  read,       // Opened by user
  failed,     // Failed to deliver
  expired,    // Expired before delivery
}

/// Individual guard notification model
/// Following existing Firebase and chat patterns from message_model.dart
class GuardNotification {
  final String id;
  final String userId;
  final GuardNotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final DateTime? scheduledFor;
  final NotificationPriority priority;
  final NotificationDeliveryStatus deliveryStatus;
  final bool isRead;
  final bool isPinned;
  final DateTime? expiresAt;
  final String? actionUrl;
  final String? imageUrl;
  final Map<String, String>? actionButtons;

  const GuardNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.timestamp,
    this.scheduledFor,
    required this.priority,
    this.deliveryStatus = NotificationDeliveryStatus.pending,
    this.isRead = false,
    this.isPinned = false,
    this.expiresAt,
    this.actionUrl,
    this.imageUrl,
    this.actionButtons,
  });

  /// Create from Firestore document
  factory GuardNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GuardNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: GuardNotificationType.values.firstWhere(
        (t) => t.toString().split('.').last == data['type'],
        orElse: () => GuardNotificationType.systemUpdate,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledFor: (data['scheduledFor'] as Timestamp?)?.toDate(),
      priority: NotificationPriority.values.firstWhere(
        (p) => p.toString().split('.').last == data['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      deliveryStatus: NotificationDeliveryStatus.values.firstWhere(
        (s) => s.toString().split('.').last == data['deliveryStatus'],
        orElse: () => NotificationDeliveryStatus.pending,
      ),
      isRead: data['isRead'] ?? false,
      isPinned: data['isPinned'] ?? false,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      actionUrl: data['actionUrl'],
      imageUrl: data['imageUrl'],
      actionButtons: data['actionButtons'] != null 
          ? Map<String, String>.from(data['actionButtons'])
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'body': body,
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
      'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
      'priority': priority.toString().split('.').last,
      'deliveryStatus': deliveryStatus.toString().split('.').last,
      'isRead': isRead,
      'isPinned': isPinned,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
      'actionButtons': actionButtons,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create copy with updates
  GuardNotification copyWith({
    String? id,
    String? userId,
    GuardNotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    DateTime? scheduledFor,
    NotificationPriority? priority,
    NotificationDeliveryStatus? deliveryStatus,
    bool? isRead,
    bool? isPinned,
    DateTime? expiresAt,
    String? actionUrl,
    String? imageUrl,
    Map<String, String>? actionButtons,
  }) {
    return GuardNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      priority: priority ?? this.priority,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      isRead: isRead ?? this.isRead,
      isPinned: isPinned ?? this.isPinned,
      expiresAt: expiresAt ?? this.expiresAt,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      actionButtons: actionButtons ?? this.actionButtons,
    );
  }

  /// Get Dutch localized title based on type
  String get localizedTitle {
    switch (type) {
      case GuardNotificationType.jobOpportunity:
        return 'Nieuwe Klus Beschikbaar';
      case GuardNotificationType.shiftReminder:
        return 'Dienst Herinnering';
      case GuardNotificationType.paymentUpdate:
        return 'Betaling Verwerkt';
      case GuardNotificationType.certificateExpiry:
        return 'Certificaat Verloopt Binnenkort';
      case GuardNotificationType.emergencyAlert:
        return 'Noodmelding';
      case GuardNotificationType.systemUpdate:
        return 'Systeem Update';
      case GuardNotificationType.profileUpdate:
        return 'Profiel Update';
      case GuardNotificationType.applicationAccepted:
        return 'Sollicitatie Geaccepteerd';
      case GuardNotificationType.applicationRejected:
        return 'Sollicitatie Update';
      case GuardNotificationType.jobUpdate:
        return 'Klus Update';
    }
  }

  /// Get notification icon based on type
  String get iconName {
    switch (type) {
      case GuardNotificationType.jobOpportunity:
        return 'work';
      case GuardNotificationType.shiftReminder:
        return 'schedule';
      case GuardNotificationType.paymentUpdate:
        return 'payments';
      case GuardNotificationType.certificateExpiry:
        return 'badge';
      case GuardNotificationType.emergencyAlert:
        return 'warning';
      case GuardNotificationType.systemUpdate:
        return 'update';
      case GuardNotificationType.profileUpdate:
        return 'person';
      case GuardNotificationType.applicationAccepted:
        return 'check_circle';
      case GuardNotificationType.applicationRejected:
        return 'info';
      case GuardNotificationType.jobUpdate:
        return 'work';
    }
  }

  /// Get notification color hex code
  String get colorHex {
    switch (priority) {
      case NotificationPriority.urgent:
        return '#FF5252'; // Red for urgent
      case NotificationPriority.high:
        return '#FF9800'; // Orange for high
      case NotificationPriority.medium:
        return '#2196F3'; // Blue for medium
      case NotificationPriority.low:
        return '#4CAF50'; // Green for low
    }
  }

  /// Check if notification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if notification is scheduled for future
  bool get isScheduled {
    if (scheduledFor == null) return false;
    return DateTime.now().isBefore(scheduledFor!);
  }

  /// Get time remaining until expiry (Dutch formatted)
  String? get timeUntilExpiry {
    if (expiresAt == null) return null;
    
    final difference = expiresAt!.difference(DateTime.now());
    if (difference.isNegative) return 'Verlopen';
    
    if (difference.inDays > 0) {
      return '${difference.inDays} dagen resterend';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} uur resterend';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuten resterend';
    } else {
      return 'Verloopt binnenkort';
    }
  }

  @override
  String toString() => 'GuardNotification(id: $id, type: $type, title: $title, isRead: $isRead)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuardNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Notification template for common guard notifications
class GuardNotificationTemplate {
  final GuardNotificationType type;
  final String titleTemplate;
  final String bodyTemplate;
  final NotificationPriority priority;
  final Duration? defaultExpiry;
  final Map<String, String>? defaultActions;

  const GuardNotificationTemplate({
    required this.type,
    required this.titleTemplate,
    required this.bodyTemplate,
    required this.priority,
    this.defaultExpiry,
    this.defaultActions,
  });

  /// Built-in Dutch templates for common notifications
  static const List<GuardNotificationTemplate> defaultTemplates = [
    GuardNotificationTemplate(
      type: GuardNotificationType.jobOpportunity,
      titleTemplate: 'Nieuwe {jobType} klus - €{hourlyRate}/uur',
      bodyTemplate: 'Een nieuwe {jobType} klus in {location} past perfect bij jouw specialisaties. Reageer snel!',
      priority: NotificationPriority.high,
      defaultExpiry: Duration(hours: 24),
      defaultActions: {'view': 'Bekijken', 'apply': 'Reageren'},
    ),
    GuardNotificationTemplate(
      type: GuardNotificationType.shiftReminder,
      titleTemplate: 'Dienst begint over {timeUntil}',
      bodyTemplate: 'Je dienst bij {companyName} in {location} begint om {startTime}. Vergeet niet in te checken!',
      priority: NotificationPriority.high,
      defaultExpiry: Duration(hours: 2),
      defaultActions: {'checkin': 'Inchecken', 'details': 'Details'},
    ),
    GuardNotificationTemplate(
      type: GuardNotificationType.certificateExpiry,
      titleTemplate: 'WPBR certificaat verloopt over {daysUntilExpiry} dagen',
      bodyTemplate: 'Verleng je WPBR certificaat om klussen te blijven accepteren.',
      priority: NotificationPriority.medium,
      defaultExpiry: Duration(days: 30),
      defaultActions: {'renew': 'Verlengen', 'remind': 'Herinner Later'},
    ),
  ];

  /// Generate notification from template with variables
  GuardNotification generate({
    required String userId,
    required Map<String, String> variables,
    String? actionUrl,
    DateTime? scheduledFor,
    DateTime? expiresAt,
  }) {
    String title = titleTemplate;
    String body = bodyTemplate;
    
    // Replace variables in template
    variables.forEach((key, value) {
      title = title.replaceAll('{$key}', value);
      body = body.replaceAll('{$key}', value);
    });

    return GuardNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: variables,
      timestamp: DateTime.now(),
      scheduledFor: scheduledFor,
      priority: priority,
      expiresAt: expiresAt ?? (defaultExpiry != null 
          ? DateTime.now().add(defaultExpiry!) 
          : null),
      actionUrl: actionUrl,
      actionButtons: defaultActions,
    );
  }
}