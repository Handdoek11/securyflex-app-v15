import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/certificate_management_service.dart';

/// Alert types following the 90/60/30/7/1 day schedule
enum AlertType {
  warning90('90 dagen waarschuwing'),
  warning60('60 dagen waarschuwing'),
  warning30('30 dagen waarschuwing'),
  warning7('7 dagen waarschuwing'),
  warning1('1 dag waarschuwing'),
  expired('Certificaat verlopen');

  const AlertType(this.displayName);
  final String displayName;

  /// Get alert urgency level for UI styling
  int get urgencyLevel {
    switch (this) {
      case AlertType.warning90:
        return 1;
      case AlertType.warning60:
        return 2;
      case AlertType.warning30:
        return 3;
      case AlertType.warning7:
        return 4;
      case AlertType.warning1:
        return 5;
      case AlertType.expired:
        return 6;
    }
  }

  /// Get alert color hex for notifications
  String get colorHex {
    switch (this) {
      case AlertType.warning90:
      case AlertType.warning60:
        return '#2196F3'; // Blue - early warning
      case AlertType.warning30:
        return '#FF9800'; // Orange - moderate urgency
      case AlertType.warning7:
        return '#FF5722'; // Deep orange - high urgency
      case AlertType.warning1:
      case AlertType.expired:
        return '#F44336'; // Red - critical/expired
    }
  }

  /// Get appropriate Dutch message for alert type
  String getAlertMessage(String certificateType, int daysRemaining) {
    switch (this) {
      case AlertType.warning90:
        return 'Je $certificateType certificaat verloopt over $daysRemaining dagen. Plan je verlenging.';
      case AlertType.warning60:
        return 'Je $certificateType certificaat verloopt over $daysRemaining dagen. Boek nu je verlengingscursus.';
      case AlertType.warning30:
        return 'Urgent: Je $certificateType certificaat verloopt over $daysRemaining dagen!';
      case AlertType.warning7:
        return 'Kritiek: Je $certificateType certificaat verloopt over $daysRemaining dagen!';
      case AlertType.warning1:
        return 'Laatste dag: Je $certificateType certificaat verloopt morgen!';
      case AlertType.expired:
        return 'Je $certificateType certificaat is verlopen. Verleng direct om te blijven werken.';
    }
  }
}

/// Renewal course recommendation for certificate alerts
class RenewalCourse {
  final String id;
  final String name;
  final String provider;
  final Duration duration;
  final double price;
  final DateTime nextStartDate;
  final bool isOnline;
  final String? description;
  final String? bookingUrl;
  final Map<String, dynamic> metadata;

  const RenewalCourse({
    required this.id,
    required this.name,
    required this.provider,
    required this.duration,
    required this.price,
    required this.nextStartDate,
    required this.isOnline,
    this.description,
    this.bookingUrl,
    this.metadata = const {},
  });

  /// Create from Firestore document
  factory RenewalCourse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return RenewalCourse(
      id: doc.id,
      name: data['name'] ?? '',
      provider: data['provider'] ?? '',
      duration: Duration(hours: data['durationHours'] ?? 8),
      price: (data['price'] ?? 0.0).toDouble(),
      nextStartDate: (data['nextStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: data['isOnline'] ?? false,
      description: data['description'],
      bookingUrl: data['bookingUrl'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'provider': provider,
      'durationHours': duration.inHours,
      'price': price,
      'nextStartDate': Timestamp.fromDate(nextStartDate),
      'isOnline': isOnline,
      'description': description,
      'bookingUrl': bookingUrl,
      'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Get formatted price in Dutch format
  String get formattedPrice => '€${price.toStringAsFixed(2)}';

  /// Get duration in Dutch format
  String get formattedDuration {
    if (duration.inHours < 24) {
      return '${duration.inHours} uur';
    } else {
      final days = duration.inDays;
      return '$days dag${days > 1 ? 'en' : ''}';
    }
  }

  /// Get formatted start date in Dutch format
  String get formattedStartDate {
    final months = [
      '', 'januari', 'februari', 'maart', 'april', 'mei', 'juni',
      'juli', 'augustus', 'september', 'oktober', 'november', 'december'
    ];
    
    return '${nextStartDate.day} ${months[nextStartDate.month]} ${nextStartDate.year}';
  }

  /// Check if course is starting soon (within 7 days)
  bool get isStartingSoon {
    final difference = nextStartDate.difference(DateTime.now());
    return difference.inDays <= 7 && difference.inDays >= 0;
  }
}

/// Certificate alert model following existing Firebase patterns
/// Integrates with existing certificate data and notification systems
class CertificateAlert {
  final String id;
  final String userId;
  final String certificateId;
  final CertificateType certificateType;
  final String certificateNumber;
  final AlertType alertType;
  final DateTime alertDate;
  final DateTime certificateExpiryDate;
  final int daysUntilExpiry;
  final bool sent;
  final DateTime? sentAt;
  final bool actionTaken;
  final DateTime? actionTakenAt;
  final List<RenewalCourse> renewalCourses;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CertificateAlert({
    required this.id,
    required this.userId,
    required this.certificateId,
    required this.certificateType,
    required this.certificateNumber,
    required this.alertType,
    required this.alertDate,
    required this.certificateExpiryDate,
    required this.daysUntilExpiry,
    this.sent = false,
    this.sentAt,
    this.actionTaken = false,
    this.actionTakenAt,
    this.renewalCourses = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create expiry warning alert for certificate
  factory CertificateAlert.createExpiryWarning(
    CertificateData certificate,
    AlertType alertType,
    int daysUntilExpiry,
    List<RenewalCourse> renewalCourses,
  ) {
    return CertificateAlert(
      id: '', // Will be set by Firestore
      userId: '', // Will be set by calling service
      certificateId: certificate.id,
      certificateType: certificate.type,
      certificateNumber: certificate.number,
      alertType: alertType,
      alertDate: DateTime.now(),
      certificateExpiryDate: certificate.expirationDate,
      daysUntilExpiry: daysUntilExpiry,
      renewalCourses: renewalCourses,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: {
        'certificate_holder': certificate.holderName,
        'issuing_authority': certificate.issuingAuthority,
        'alert_trigger': 'daily_check',
      },
    );
  }

  /// Create expired certificate alert
  factory CertificateAlert.createExpiredAlert(CertificateData certificate) {
    return CertificateAlert(
      id: '',
      userId: '',
      certificateId: certificate.id,
      certificateType: certificate.type,
      certificateNumber: certificate.number,
      alertType: AlertType.expired,
      alertDate: DateTime.now(),
      certificateExpiryDate: certificate.expirationDate,
      daysUntilExpiry: certificate.daysUntilExpiration, // Will be negative
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: {
        'certificate_holder': certificate.holderName,
        'issuing_authority': certificate.issuingAuthority,
        'expired_since_days': (-certificate.daysUntilExpiration).abs(),
        'alert_trigger': 'expired_check',
      },
    );
  }

  /// Create from Firestore document
  factory CertificateAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse renewal courses
    final coursesData = data['renewalCourses'] as List<dynamic>? ?? [];
    final renewalCourses = coursesData
        .map((courseData) => RenewalCourse(
              id: courseData['id'] ?? '',
              name: courseData['name'] ?? '',
              provider: courseData['provider'] ?? '',
              duration: Duration(hours: courseData['durationHours'] ?? 8),
              price: (courseData['price'] ?? 0.0).toDouble(),
              nextStartDate: (courseData['nextStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isOnline: courseData['isOnline'] ?? false,
              description: courseData['description'],
              bookingUrl: courseData['bookingUrl'],
              metadata: Map<String, dynamic>.from(courseData['metadata'] ?? {}),
            ))
        .toList();
    
    return CertificateAlert(
      id: doc.id,
      userId: data['userId'] ?? '',
      certificateId: data['certificateId'] ?? '',
      certificateType: CertificateType.values.firstWhere(
        (type) => type.name == data['certificateType'],
        orElse: () => CertificateType.wpbr,
      ),
      certificateNumber: data['certificateNumber'] ?? '',
      alertType: AlertType.values.firstWhere(
        (type) => type.name == data['alertType'],
        orElse: () => AlertType.warning30,
      ),
      alertDate: (data['alertDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      certificateExpiryDate: (data['certificateExpiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      daysUntilExpiry: data['daysUntilExpiry'] ?? 0,
      sent: data['sent'] ?? false,
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      actionTaken: data['actionTaken'] ?? false,
      actionTakenAt: (data['actionTakenAt'] as Timestamp?)?.toDate(),
      renewalCourses: renewalCourses,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'certificateId': certificateId,
      'certificateType': certificateType.name,
      'certificateNumber': certificateNumber,
      'alertType': alertType.name,
      'alertDate': Timestamp.fromDate(alertDate),
      'certificateExpiryDate': Timestamp.fromDate(certificateExpiryDate),
      'daysUntilExpiry': daysUntilExpiry,
      'sent': sent,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'actionTaken': actionTaken,
      'actionTakenAt': actionTakenAt != null ? Timestamp.fromDate(actionTakenAt!) : null,
      'renewalCourses': renewalCourses
          .map((course) => {
                'id': course.id,
                'name': course.name,
                'provider': course.provider,
                'durationHours': course.duration.inHours,
                'price': course.price,
                'nextStartDate': Timestamp.fromDate(course.nextStartDate),
                'isOnline': course.isOnline,
                'description': course.description,
                'bookingUrl': course.bookingUrl,
                'metadata': course.metadata,
              })
          .toList(),
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create copy with updates
  CertificateAlert copyWith({
    String? id,
    String? userId,
    bool? sent,
    DateTime? sentAt,
    bool? actionTaken,
    DateTime? actionTakenAt,
    List<RenewalCourse>? renewalCourses,
    Map<String, dynamic>? metadata,
  }) {
    return CertificateAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      certificateId: certificateId,
      certificateType: certificateType,
      certificateNumber: certificateNumber,
      alertType: alertType,
      alertDate: alertDate,
      certificateExpiryDate: certificateExpiryDate,
      daysUntilExpiry: daysUntilExpiry,
      sent: sent ?? this.sent,
      sentAt: sentAt ?? this.sentAt,
      actionTaken: actionTaken ?? this.actionTaken,
      actionTakenAt: actionTakenAt ?? this.actionTakenAt,
      renewalCourses: renewalCourses ?? this.renewalCourses,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Get localized alert title
  String get alertTitle {
    if (alertType == AlertType.expired) {
      return '${certificateType.code} Certificaat Verlopen';
    } else {
      return '${certificateType.code} Certificaat Verloopt Binnenkort';
    }
  }

  /// Get detailed alert message
  String get alertMessage {
    return alertType.getAlertMessage(certificateType.code, daysUntilExpiry.abs());
  }

  /// Get urgency level for UI styling (1-6, 6 being most urgent)
  int get urgencyLevel => alertType.urgencyLevel;

  /// Check if alert is critical (7 days or less, or expired)
  bool get isCritical {
    return alertType == AlertType.warning7 || 
           alertType == AlertType.warning1 || 
           alertType == AlertType.expired;
  }

  /// Check if certificate is expired
  bool get isExpired => alertType == AlertType.expired;

  /// Get formatted expiry date in Dutch
  String get formattedExpiryDate {
    final months = [
      '', 'januari', 'februari', 'maart', 'april', 'mei', 'juni',
      'juli', 'augustus', 'september', 'oktober', 'november', 'december'
    ];
    
    return '${certificateExpiryDate.day} ${months[certificateExpiryDate.month]} ${certificateExpiryDate.year}';
  }

  /// Get time until expiry in Dutch format
  String get timeUntilExpiryText {
    if (isExpired) {
      final daysSinceExpired = (-daysUntilExpiry).abs();
      return 'Verlopen $daysSinceExpired dagen geleden';
    }
    
    if (daysUntilExpiry == 1) {
      return 'Verloopt morgen';
    } else if (daysUntilExpiry == 0) {
      return 'Verloopt vandaag';
    } else {
      return 'Verloopt over $daysUntilExpiry dagen';
    }
  }

  /// Get recommended courses summary
  String get renewalCourseSummary {
    if (renewalCourses.isEmpty) {
      return 'Geen verlengingscursussen beschikbaar';
    }
    
    if (renewalCourses.length == 1) {
      final course = renewalCourses.first;
      return '${course.name} - ${course.formattedPrice}';
    }
    
    final cheapest = renewalCourses.reduce((a, b) => a.price < b.price ? a : b);
    return '${renewalCourses.length} cursussen beschikbaar vanaf ${cheapest.formattedPrice}';
  }

  /// Check if any renewal courses are starting soon
  bool get hasUrgentCourses {
    return renewalCourses.any((course) => course.isStartingSoon);
  }

  @override
  String toString() => 'CertificateAlert(id: $id, type: $certificateType, alert: $alertType, days: $daysUntilExpiry)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CertificateAlert &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}