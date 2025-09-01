import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Comprehensive Shift Model for SecuryFlex Schedule Management
/// 
/// Supports Nederlandse CAO requirements, GPS tracking, and role-based access.
/// All timestamps are stored in UTC and converted to Europe/Amsterdam for display.
class Shift extends Equatable {
  final String id;
  final String jobSiteId;
  final String companyId;
  final String? assignedGuardId;
  final String shiftTitle;
  final String shiftDescription;
  
  // Time and Duration
  final DateTime startTime; // UTC timestamp
  final DateTime endTime; // UTC timestamp
  final Duration plannedDuration;
  final Duration? actualDuration;
  final List<BreakPeriod> breaks;
  
  // Location and GPS
  final ShiftLocation location;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final bool requiresGPSVerification;
  final bool requiresLocationVerification;
  final String gpsVerificationStatus;
  
  // Status and State
  final ShiftStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdByUserId;
  final String? lastModifiedByUserId;
  
  // Requirements and Skills
  final List<String> requiredCertifications;
  final List<String> requiredSkills;
  final SecurityLevel securityLevel;
  
  // Compensation and CAO
  final double hourlyRate; // Base rate in euros
  final double? overtimeMultiplier; // CAO overtime multiplier
  final double? weekendMultiplier; // CAO weekend multiplier  
  final double? nightShiftMultiplier; // CAO night shift multiplier
  final double totalEarnings; // Calculated total including CAO rates
  
  // Metadata
  final Map<String, dynamic> metadata;
  final bool isTemplate;
  final String? templateId;
  final RecurrencePattern? recurrence;
  
  // Emergency and Coverage
  final bool isEmergencyShift;
  final int maxReplacementTime; // Minutes before escalation
  final List<String> emergencyContactIds;
  
  const Shift({
    required this.id,
    required this.jobSiteId,
    required this.companyId,
    this.assignedGuardId,
    required this.shiftTitle,
    required this.shiftDescription,
    required this.startTime,
    required this.endTime,
    required this.plannedDuration,
    this.actualDuration,
    required this.breaks,
    required this.location,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    required this.requiresGPSVerification,
    required this.requiresLocationVerification,
    required this.gpsVerificationStatus,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByUserId,
    this.lastModifiedByUserId,
    required this.requiredCertifications,
    required this.requiredSkills,
    required this.securityLevel,
    required this.hourlyRate,
    this.overtimeMultiplier,
    this.weekendMultiplier,
    this.nightShiftMultiplier,
    required this.totalEarnings,
    required this.metadata,
    required this.isTemplate,
    this.templateId,
    this.recurrence,
    required this.isEmergencyShift,
    required this.maxReplacementTime,
    required this.emergencyContactIds,
  });

  /// Create Shift from Firestore document
  factory Shift.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Shift(
      id: doc.id,
      jobSiteId: data['jobSiteId'] ?? '',
      companyId: data['companyId'] ?? '',
      assignedGuardId: data['assignedGuardId'],
      shiftTitle: data['shiftTitle'] ?? '',
      shiftDescription: data['shiftDescription'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      plannedDuration: Duration(minutes: data['plannedDurationMinutes'] ?? 0),
      actualDuration: data['actualDurationMinutes'] != null 
          ? Duration(minutes: data['actualDurationMinutes']) 
          : null,
      breaks: (data['breaks'] as List<dynamic>? ?? [])
          .map((e) => BreakPeriod.fromJson(e))
          .toList(),
      location: ShiftLocation.fromJson(data['location'] ?? {}),
      checkInLatitude: data['checkInLatitude']?.toDouble(),
      checkInLongitude: data['checkInLongitude']?.toDouble(),
      checkOutLatitude: data['checkOutLatitude']?.toDouble(),
      checkOutLongitude: data['checkOutLongitude']?.toDouble(),
      requiresGPSVerification: data['requiresGPSVerification'] ?? true,
      requiresLocationVerification: data['requiresLocationVerification'] ?? true,
      gpsVerificationStatus: data['gpsVerificationStatus'] ?? 'pending',
      status: ShiftStatus.values.firstWhere(
        (s) => s.toString() == 'ShiftStatus.${data['status']}',
        orElse: () => ShiftStatus.draft,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdByUserId: data['createdByUserId'] ?? '',
      lastModifiedByUserId: data['lastModifiedByUserId'],
      requiredCertifications: List<String>.from(data['requiredCertifications'] ?? []),
      requiredSkills: List<String>.from(data['requiredSkills'] ?? []),
      securityLevel: SecurityLevel.values.firstWhere(
        (s) => s.toString() == 'SecurityLevel.${data['securityLevel']}',
        orElse: () => SecurityLevel.basic,
      ),
      hourlyRate: data['hourlyRate']?.toDouble() ?? 0.0,
      overtimeMultiplier: data['overtimeMultiplier']?.toDouble(),
      weekendMultiplier: data['weekendMultiplier']?.toDouble(),
      nightShiftMultiplier: data['nightShiftMultiplier']?.toDouble(),
      totalEarnings: data['totalEarnings']?.toDouble() ?? 0.0,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      isTemplate: data['isTemplate'] ?? false,
      templateId: data['templateId'],
      recurrence: data['recurrence'] != null 
          ? RecurrencePattern.fromJson(data['recurrence']) 
          : null,
      isEmergencyShift: data['isEmergencyShift'] ?? false,
      maxReplacementTime: data['maxReplacementTime'] ?? 15,
      emergencyContactIds: List<String>.from(data['emergencyContactIds'] ?? []),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'jobSiteId': jobSiteId,
      'companyId': companyId,
      'assignedGuardId': assignedGuardId,
      'shiftTitle': shiftTitle,
      'shiftDescription': shiftDescription,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'plannedDurationMinutes': plannedDuration.inMinutes,
      'actualDurationMinutes': actualDuration?.inMinutes,
      'breaks': breaks.map((e) => e.toJson()).toList(),
      'location': location.toJson(),
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'requiresGPSVerification': requiresGPSVerification,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdByUserId': createdByUserId,
      'lastModifiedByUserId': lastModifiedByUserId,
      'requiredCertifications': requiredCertifications,
      'requiredSkills': requiredSkills,
      'securityLevel': securityLevel.toString().split('.').last,
      'hourlyRate': hourlyRate,
      'overtimeMultiplier': overtimeMultiplier,
      'weekendMultiplier': weekendMultiplier,
      'nightShiftMultiplier': nightShiftMultiplier,
      'totalEarnings': totalEarnings,
      'metadata': metadata,
      'isTemplate': isTemplate,
      'templateId': templateId,
      'recurrence': recurrence?.toJson(),
      'isEmergencyShift': isEmergencyShift,
      'maxReplacementTime': maxReplacementTime,
      'emergencyContactIds': emergencyContactIds,
    };
  }

  /// Copy with method for updates
  Shift copyWith({
    String? id,
    String? jobSiteId,
    String? companyId,
    String? assignedGuardId,
    String? shiftTitle,
    String? shiftDescription,
    DateTime? startTime,
    DateTime? endTime,
    Duration? plannedDuration,
    Duration? actualDuration,
    List<BreakPeriod>? breaks,
    ShiftLocation? location,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    bool? requiresGPSVerification,
    bool? requiresLocationVerification,
    String? gpsVerificationStatus,
    ShiftStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByUserId,
    String? lastModifiedByUserId,
    List<String>? requiredCertifications,
    List<String>? requiredSkills,
    SecurityLevel? securityLevel,
    double? hourlyRate,
    double? overtimeMultiplier,
    double? weekendMultiplier,
    double? nightShiftMultiplier,
    double? totalEarnings,
    Map<String, dynamic>? metadata,
    bool? isTemplate,
    String? templateId,
    RecurrencePattern? recurrence,
    bool? isEmergencyShift,
    int? maxReplacementTime,
    List<String>? emergencyContactIds,
  }) {
    return Shift(
      id: id ?? this.id,
      jobSiteId: jobSiteId ?? this.jobSiteId,
      companyId: companyId ?? this.companyId,
      assignedGuardId: assignedGuardId ?? this.assignedGuardId,
      shiftTitle: shiftTitle ?? this.shiftTitle,
      shiftDescription: shiftDescription ?? this.shiftDescription,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      breaks: breaks ?? this.breaks,
      location: location ?? this.location,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      requiresGPSVerification: requiresGPSVerification ?? this.requiresGPSVerification,
      requiresLocationVerification: requiresLocationVerification ?? this.requiresLocationVerification,
      gpsVerificationStatus: gpsVerificationStatus ?? this.gpsVerificationStatus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      lastModifiedByUserId: lastModifiedByUserId ?? this.lastModifiedByUserId,
      requiredCertifications: requiredCertifications ?? this.requiredCertifications,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      securityLevel: securityLevel ?? this.securityLevel,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
      weekendMultiplier: weekendMultiplier ?? this.weekendMultiplier,
      nightShiftMultiplier: nightShiftMultiplier ?? this.nightShiftMultiplier,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      metadata: metadata ?? this.metadata,
      isTemplate: isTemplate ?? this.isTemplate,
      templateId: templateId ?? this.templateId,
      recurrence: recurrence ?? this.recurrence,
      isEmergencyShift: isEmergencyShift ?? this.isEmergencyShift,
      maxReplacementTime: maxReplacementTime ?? this.maxReplacementTime,
      emergencyContactIds: emergencyContactIds ?? this.emergencyContactIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        jobSiteId,
        companyId,
        assignedGuardId,
        shiftTitle,
        shiftDescription,
        startTime,
        endTime,
        plannedDuration,
        actualDuration,
        breaks,
        location,
        checkInLatitude,
        checkInLongitude,
        checkOutLatitude,
        checkOutLongitude,
        requiresGPSVerification,
        status,
        createdAt,
        updatedAt,
        createdByUserId,
        lastModifiedByUserId,
        requiredCertifications,
        requiredSkills,
        securityLevel,
        hourlyRate,
        overtimeMultiplier,
        weekendMultiplier,
        nightShiftMultiplier,
        totalEarnings,
        metadata,
        isTemplate,
        templateId,
        recurrence,
        isEmergencyShift,
        maxReplacementTime,
        emergencyContactIds,
      ];
}

/// Nederlandse CAO-compliant shift statuses
enum ShiftStatus {
  draft,
  published,
  applied,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
  expired,
  replacement,
}

/// Security levels according to Nederlandse beveiligingssector
enum SecurityLevel {
  basic,      // Basis beveiliging
  enhanced,   // Verhoogde beveiliging  
  critical,   // Kritieke beveiliging
  vip,        // VIP beveiliging
  event,      // Evenement beveiliging
}

/// Shift location with geofencing capabilities
class ShiftLocation extends Equatable {
  final String address;
  final String city;
  final String postalCode;
  final String country;
  final double latitude;
  final double longitude;
  final double geofenceRadius; // meters
  final String locationNotes;
  final List<String> landmarks;

  const ShiftLocation({
    required this.address,
    required this.city,
    required this.postalCode,
    this.country = 'Nederland',
    required this.latitude,
    required this.longitude,
    this.geofenceRadius = 100.0,
    this.locationNotes = '',
    this.landmarks = const [],
  });

  factory ShiftLocation.fromJson(Map<String, dynamic> json) {
    return ShiftLocation(
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      postalCode: json['postalCode'] ?? '',
      country: json['country'] ?? 'Nederland',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      geofenceRadius: json['geofenceRadius']?.toDouble() ?? 100.0,
      locationNotes: json['locationNotes'] ?? '',
      landmarks: List<String>.from(json['landmarks'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'geofenceRadius': geofenceRadius,
      'locationNotes': locationNotes,
      'landmarks': landmarks,
    };
  }

  @override
  List<Object?> get props => [
        address,
        city,
        postalCode,
        country,
        latitude,
        longitude,
        geofenceRadius,
        locationNotes,
        landmarks,
      ];
}

/// Break period with CAO compliance tracking
class BreakPeriod extends Equatable {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final BreakType type;
  final bool isPaid;
  final bool isRequired; // CAO required break
  final String notes;

  const BreakPeriod({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.type,
    required this.isPaid,
    required this.isRequired,
    this.notes = '',
  });

  factory BreakPeriod.fromJson(Map<String, dynamic> json) {
    return BreakPeriod(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      duration: Duration(minutes: json['durationMinutes']),
      type: BreakType.values.firstWhere(
        (t) => t.toString() == 'BreakType.${json['type']}',
        orElse: () => BreakType.mandatory,
      ),
      isPaid: json['isPaid'] ?? false,
      isRequired: json['isRequired'] ?? true,
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': duration.inMinutes,
      'type': type.toString().split('.').last,
      'isPaid': isPaid,
      'isRequired': isRequired,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        startTime,
        endTime,
        duration,
        type,
        isPaid,
        isRequired,
        notes,
      ];
}

/// CAO-compliant break types
enum BreakType {
  mandatory,    // Verplichte pauze
  meal,         // Maaltijd pauze
  rest,         // Rust pauze
  emergency,    // Nood pauze
}

/// Recurrence pattern for shift templates
class RecurrencePattern extends Equatable {
  final RecurrenceFrequency frequency;
  final int interval; // Every X weeks/days
  final List<int> daysOfWeek; // 1=Monday, 7=Sunday
  final DateTime? endDate;
  final int? maxOccurrences;
  final List<DateTime> exceptions; // Dates to skip

  const RecurrencePattern({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek = const [],
    this.endDate,
    this.maxOccurrences,
    this.exceptions = const [],
  });

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) {
    return RecurrencePattern(
      frequency: RecurrenceFrequency.values.firstWhere(
        (f) => f.toString() == 'RecurrenceFrequency.${json['frequency']}',
        orElse: () => RecurrenceFrequency.none,
      ),
      interval: json['interval'] ?? 1,
      daysOfWeek: List<int>.from(json['daysOfWeek'] ?? []),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      maxOccurrences: json['maxOccurrences'],
      exceptions: (json['exceptions'] as List<dynamic>? ?? [])
          .map((e) => DateTime.parse(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.toString().split('.').last,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'exceptions': exceptions.map((e) => e.toIso8601String()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        frequency,
        interval,
        daysOfWeek,
        endDate,
        maxOccurrences,
        exceptions,
      ];
}

/// Recurrence frequency options
enum RecurrenceFrequency {
  none,
  daily,
  weekly,
  monthly,
}