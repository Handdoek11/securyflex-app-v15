import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// TimeEntry Model for SecuryFlex GPS-verified time tracking
/// 
/// Compliant with Nederlandse CAO arbeidsrecht requirements.
/// All timestamps in UTC, converted to Europe/Amsterdam for display.
class TimeEntry extends Equatable {
  final String id;
  final String shiftId;
  final String guardId;
  final String companyId;
  final String jobSiteId;
  
  // Time tracking
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final Duration? actualWorkDuration;
  final Duration? plannedWorkDuration;
  final List<BreakEntry> breaks;
  
  // GPS verification
  final GPSLocation? checkInLocation;
  final GPSLocation? checkOutLocation;
  final bool checkInVerified;
  final bool checkOutVerified;
  final List<LocationPing> locationPings; // Periodic location checks
  
  // CAO compliance
  final TimeEntryStatus status;
  final double regularHours;
  final double overtimeHours;
  final double weekendHours;
  final double nightHours;
  final CAOCompliance caoCompliance;
  
  // Verification and approval
  final bool guardApproved;
  final bool companyApproved;
  final DateTime? guardApprovedAt;
  final DateTime? companyApprovedAt;
  final String? approvalNotes;
  final List<String> discrepancies;
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;
  final List<TimeEntryPhoto> photos; // Check-in/out photos
  final String? notes;

  const TimeEntry({
    required this.id,
    required this.shiftId,
    required this.guardId,
    required this.companyId,
    required this.jobSiteId,
    this.checkInTime,
    this.checkOutTime,
    this.actualWorkDuration,
    this.plannedWorkDuration,
    required this.breaks,
    this.checkInLocation,
    this.checkOutLocation,
    required this.checkInVerified,
    required this.checkOutVerified,
    required this.locationPings,
    required this.status,
    required this.regularHours,
    required this.overtimeHours,
    required this.weekendHours,
    required this.nightHours,
    required this.caoCompliance,
    required this.guardApproved,
    required this.companyApproved,
    this.guardApprovedAt,
    this.companyApprovedAt,
    this.approvalNotes,
    required this.discrepancies,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
    required this.photos,
    this.notes,
  });

  /// Create TimeEntry from Firestore document
  factory TimeEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TimeEntry(
      id: doc.id,
      shiftId: data['shiftId'] ?? '',
      guardId: data['guardId'] ?? '',
      companyId: data['companyId'] ?? '',
      jobSiteId: data['jobSiteId'] ?? '',
      checkInTime: data['checkInTime'] != null 
          ? (data['checkInTime'] as Timestamp).toDate() 
          : null,
      checkOutTime: data['checkOutTime'] != null 
          ? (data['checkOutTime'] as Timestamp).toDate() 
          : null,
      actualWorkDuration: data['actualWorkDurationMinutes'] != null
          ? Duration(minutes: data['actualWorkDurationMinutes'])
          : null,
      plannedWorkDuration: data['plannedWorkDurationMinutes'] != null
          ? Duration(minutes: data['plannedWorkDurationMinutes'])
          : null,
      breaks: (data['breaks'] as List<dynamic>? ?? [])
          .map((e) => BreakEntry.fromJson(e))
          .toList(),
      checkInLocation: data['checkInLocation'] != null
          ? GPSLocation.fromJson(data['checkInLocation'])
          : null,
      checkOutLocation: data['checkOutLocation'] != null
          ? GPSLocation.fromJson(data['checkOutLocation'])
          : null,
      checkInVerified: data['checkInVerified'] ?? false,
      checkOutVerified: data['checkOutVerified'] ?? false,
      locationPings: (data['locationPings'] as List<dynamic>? ?? [])
          .map((e) => LocationPing.fromJson(e))
          .toList(),
      status: TimeEntryStatus.values.firstWhere(
        (s) => s.toString() == 'TimeEntryStatus.${data['status']}',
        orElse: () => TimeEntryStatus.draft,
      ),
      regularHours: data['regularHours']?.toDouble() ?? 0.0,
      overtimeHours: data['overtimeHours']?.toDouble() ?? 0.0,
      weekendHours: data['weekendHours']?.toDouble() ?? 0.0,
      nightHours: data['nightHours']?.toDouble() ?? 0.0,
      caoCompliance: CAOCompliance.fromJson(data['caoCompliance'] ?? {}),
      guardApproved: data['guardApproved'] ?? false,
      companyApproved: data['companyApproved'] ?? false,
      guardApprovedAt: data['guardApprovedAt'] != null
          ? (data['guardApprovedAt'] as Timestamp).toDate()
          : null,
      companyApprovedAt: data['companyApprovedAt'] != null
          ? (data['companyApprovedAt'] as Timestamp).toDate()
          : null,
      approvalNotes: data['approvalNotes'],
      discrepancies: List<String>.from(data['discrepancies'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      photos: (data['photos'] as List<dynamic>? ?? [])
          .map((e) => TimeEntryPhoto.fromJson(e))
          .toList(),
      notes: data['notes'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'shiftId': shiftId,
      'guardId': guardId,
      'companyId': companyId,
      'jobSiteId': jobSiteId,
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'actualWorkDurationMinutes': actualWorkDuration?.inMinutes,
      'plannedWorkDurationMinutes': plannedWorkDuration?.inMinutes,
      'breaks': breaks.map((e) => e.toJson()).toList(),
      'checkInLocation': checkInLocation?.toJson(),
      'checkOutLocation': checkOutLocation?.toJson(),
      'checkInVerified': checkInVerified,
      'checkOutVerified': checkOutVerified,
      'locationPings': locationPings.map((e) => e.toJson()).toList(),
      'status': status.toString().split('.').last,
      'regularHours': regularHours,
      'overtimeHours': overtimeHours,
      'weekendHours': weekendHours,
      'nightHours': nightHours,
      'caoCompliance': caoCompliance.toJson(),
      'guardApproved': guardApproved,
      'companyApproved': companyApproved,
      'guardApprovedAt': guardApprovedAt != null ? Timestamp.fromDate(guardApprovedAt!) : null,
      'companyApprovedAt': companyApprovedAt != null ? Timestamp.fromDate(companyApprovedAt!) : null,
      'approvalNotes': approvalNotes,
      'discrepancies': discrepancies,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
      'photos': photos.map((e) => e.toJson()).toList(),
      'notes': notes,
    };
  }

  /// Calculate total hours worked
  double get totalHours => regularHours + overtimeHours + weekendHours + nightHours;

  /// Check if time entry is complete
  bool get isComplete => checkInTime != null && checkOutTime != null && checkInVerified && checkOutVerified;

  /// Check if CAO compliant
  bool get isCAOCompliant => caoCompliance.isCompliant;

  /// Get total work duration
  Duration getTotalWorkDuration() {
    if (checkInTime != null && checkOutTime != null) {
      return checkOutTime!.difference(checkInTime!);
    }
    return actualWorkDuration ?? Duration.zero;
  }

  TimeEntry copyWith({
    String? id,
    String? shiftId,
    String? guardId,
    String? companyId,
    String? jobSiteId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    Duration? actualWorkDuration,
    Duration? plannedWorkDuration,
    List<BreakEntry>? breaks,
    GPSLocation? checkInLocation,
    GPSLocation? checkOutLocation,
    bool? checkInVerified,
    bool? checkOutVerified,
    List<LocationPing>? locationPings,
    TimeEntryStatus? status,
    double? regularHours,
    double? overtimeHours,
    double? weekendHours,
    double? nightHours,
    CAOCompliance? caoCompliance,
    bool? guardApproved,
    bool? companyApproved,
    DateTime? guardApprovedAt,
    DateTime? companyApprovedAt,
    String? approvalNotes,
    List<String>? discrepancies,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<TimeEntryPhoto>? photos,
    String? notes,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      guardId: guardId ?? this.guardId,
      companyId: companyId ?? this.companyId,
      jobSiteId: jobSiteId ?? this.jobSiteId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      actualWorkDuration: actualWorkDuration ?? this.actualWorkDuration,
      plannedWorkDuration: plannedWorkDuration ?? this.plannedWorkDuration,
      breaks: breaks ?? this.breaks,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      checkInVerified: checkInVerified ?? this.checkInVerified,
      checkOutVerified: checkOutVerified ?? this.checkOutVerified,
      locationPings: locationPings ?? this.locationPings,
      status: status ?? this.status,
      regularHours: regularHours ?? this.regularHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      weekendHours: weekendHours ?? this.weekendHours,
      nightHours: nightHours ?? this.nightHours,
      caoCompliance: caoCompliance ?? this.caoCompliance,
      guardApproved: guardApproved ?? this.guardApproved,
      companyApproved: companyApproved ?? this.companyApproved,
      guardApprovedAt: guardApprovedAt ?? this.guardApprovedAt,
      companyApprovedAt: companyApprovedAt ?? this.companyApprovedAt,
      approvalNotes: approvalNotes ?? this.approvalNotes,
      discrepancies: discrepancies ?? this.discrepancies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      photos: photos ?? this.photos,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        shiftId,
        guardId,
        companyId,
        jobSiteId,
        checkInTime,
        checkOutTime,
        actualWorkDuration,
        plannedWorkDuration,
        breaks,
        checkInLocation,
        checkOutLocation,
        checkInVerified,
        checkOutVerified,
        locationPings,
        status,
        regularHours,
        overtimeHours,
        weekendHours,
        nightHours,
        caoCompliance,
        guardApproved,
        companyApproved,
        guardApprovedAt,
        companyApprovedAt,
        approvalNotes,
        discrepancies,
        createdAt,
        updatedAt,
        metadata,
        photos,
        notes,
      ];
}

/// Time entry statuses
enum TimeEntryStatus {
  draft,
  checkedIn,
  onBreak,
  checkedOut,
  pendingApproval,
  approved,
  rejected,
  disputed,
}

/// GPS location with verification data
class GPSLocation extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracy; // meters
  final double altitude;
  final DateTime timestamp;
  final String provider; // GPS, network, passive
  final bool isMocked; // Mock location detection

  const GPSLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.timestamp,
    required this.provider,
    required this.isMocked,
  });

  factory GPSLocation.fromJson(Map<String, dynamic> json) {
    return GPSLocation(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      accuracy: json['accuracy']?.toDouble() ?? 0.0,
      altitude: json['altitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp']),
      provider: json['provider'] ?? 'unknown',
      isMocked: json['isMocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'timestamp': timestamp.toIso8601String(),
      'provider': provider,
      'isMocked': isMocked,
    };
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        accuracy,
        altitude,
        timestamp,
        provider,
        isMocked,
      ];
}

/// Periodic location ping for verification
class LocationPing extends Equatable {
  final GPSLocation location;
  final LocationPingType type;
  final double distanceFromSite; // meters
  final bool isWithinGeofence;

  const LocationPing({
    required this.location,
    required this.type,
    required this.distanceFromSite,
    required this.isWithinGeofence,
  });

  factory LocationPing.fromJson(Map<String, dynamic> json) {
    return LocationPing(
      location: GPSLocation.fromJson(json['location']),
      type: LocationPingType.values.firstWhere(
        (t) => t.toString() == 'LocationPingType.${json['type']}',
        orElse: () => LocationPingType.periodic,
      ),
      distanceFromSite: json['distanceFromSite']?.toDouble() ?? 0.0,
      isWithinGeofence: json['isWithinGeofence'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location.toJson(),
      'type': type.toString().split('.').last,
      'distanceFromSite': distanceFromSite,
      'isWithinGeofence': isWithinGeofence,
    };
  }

  @override
  List<Object?> get props => [
        location,
        type,
        distanceFromSite,
        isWithinGeofence,
      ];
}

/// Location ping types
enum LocationPingType {
  periodic,   // Regular location check
  triggered,  // Manual location check
  alarm,      // Out of geofence alarm
}

/// Break entry with GPS verification
class BreakEntry extends Equatable {
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? actualDuration;
  final Duration plannedDuration;
  final BreakEntryType type;
  final bool isPaid;
  final GPSLocation? startLocation;
  final GPSLocation? endLocation;
  final bool isVerified;

  const BreakEntry({
    required this.startTime,
    this.endTime,
    this.actualDuration,
    required this.plannedDuration,
    required this.type,
    required this.isPaid,
    this.startLocation,
    this.endLocation,
    required this.isVerified,
  });

  factory BreakEntry.fromJson(Map<String, dynamic> json) {
    return BreakEntry(
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      actualDuration: json['actualDurationMinutes'] != null
          ? Duration(minutes: json['actualDurationMinutes'])
          : null,
      plannedDuration: Duration(minutes: json['plannedDurationMinutes']),
      type: BreakEntryType.values.firstWhere(
        (t) => t.toString() == 'BreakEntryType.${json['type']}',
        orElse: () => BreakEntryType.mandatory,
      ),
      isPaid: json['isPaid'] ?? false,
      startLocation: json['startLocation'] != null
          ? GPSLocation.fromJson(json['startLocation'])
          : null,
      endLocation: json['endLocation'] != null
          ? GPSLocation.fromJson(json['endLocation'])
          : null,
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'actualDurationMinutes': actualDuration?.inMinutes,
      'plannedDurationMinutes': plannedDuration.inMinutes,
      'type': type.toString().split('.').last,
      'isPaid': isPaid,
      'startLocation': startLocation?.toJson(),
      'endLocation': endLocation?.toJson(),
      'isVerified': isVerified,
    };
  }

  @override
  List<Object?> get props => [
        startTime,
        endTime,
        actualDuration,
        plannedDuration,
        type,
        isPaid,
        startLocation,
        endLocation,
        isVerified,
      ];
}

/// Break entry types
enum BreakEntryType {
  mandatory,  // Verplichte pauze
  meal,       // Maaltijd pauze
  rest,       // Rust pauze
  emergency,  // Nood pauze
  voluntary,  // Vrijwillige pauze
}

/// CAO compliance tracking
class CAOCompliance extends Equatable {
  final bool isCompliant;
  final List<CAOViolation> violations;
  final double restPeriodBefore; // hours before shift
  final double restPeriodAfter;  // hours after shift
  final bool hasRequiredBreaks;
  final double weeklyHours;
  final bool exceedsWeeklyLimit;
  final bool exceedsDailyLimit;

  const CAOCompliance({
    required this.isCompliant,
    required this.violations,
    required this.restPeriodBefore,
    required this.restPeriodAfter,
    required this.hasRequiredBreaks,
    required this.weeklyHours,
    required this.exceedsWeeklyLimit,
    required this.exceedsDailyLimit,
  });

  factory CAOCompliance.fromJson(Map<String, dynamic> json) {
    return CAOCompliance(
      isCompliant: json['isCompliant'] ?? true,
      violations: (json['violations'] as List<dynamic>? ?? [])
          .map((e) => CAOViolation.fromJson(e))
          .toList(),
      restPeriodBefore: json['restPeriodBefore']?.toDouble() ?? 0.0,
      restPeriodAfter: json['restPeriodAfter']?.toDouble() ?? 0.0,
      hasRequiredBreaks: json['hasRequiredBreaks'] ?? true,
      weeklyHours: json['weeklyHours']?.toDouble() ?? 0.0,
      exceedsWeeklyLimit: json['exceedsWeeklyLimit'] ?? false,
      exceedsDailyLimit: json['exceedsDailyLimit'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCompliant': isCompliant,
      'violations': violations.map((e) => e.toJson()).toList(),
      'restPeriodBefore': restPeriodBefore,
      'restPeriodAfter': restPeriodAfter,
      'hasRequiredBreaks': hasRequiredBreaks,
      'weeklyHours': weeklyHours,
      'exceedsWeeklyLimit': exceedsWeeklyLimit,
      'exceedsDailyLimit': exceedsDailyLimit,
    };
  }

  @override
  List<Object?> get props => [
        isCompliant,
        violations,
        restPeriodBefore,
        restPeriodAfter,
        hasRequiredBreaks,
        weeklyHours,
        exceedsWeeklyLimit,
        exceedsDailyLimit,
      ];
}

/// CAO violation tracking
class CAOViolation extends Equatable {
  final CAOViolationType type;
  final String description;
  final double severity; // 0.0 - 1.0
  final DateTime detectedAt;
  final String? resolution;

  const CAOViolation({
    required this.type,
    required this.description,
    required this.severity,
    required this.detectedAt,
    this.resolution,
  });

  factory CAOViolation.fromJson(Map<String, dynamic> json) {
    return CAOViolation(
      type: CAOViolationType.values.firstWhere(
        (t) => t.toString() == 'CAOViolationType.${json['type']}',
        orElse: () => CAOViolationType.other,
      ),
      description: json['description'] ?? '',
      severity: json['severity']?.toDouble() ?? 0.0,
      detectedAt: DateTime.parse(json['detectedAt']),
      resolution: json['resolution'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'description': description,
      'severity': severity,
      'detectedAt': detectedAt.toIso8601String(),
      'resolution': resolution,
    };
  }

  @override
  List<Object?> get props => [
        type,
        description,
        severity,
        detectedAt,
        resolution,
      ];
}

/// CAO violation types
enum CAOViolationType {
  insufficientRestPeriod,
  missingRequiredBreaks,
  exceedsMaximumHours,
  exceedsWeeklyLimit,
  underpaid,
  other,
}

/// Photo attachment for time entries
class TimeEntryPhoto extends Equatable {
  final String id;
  final String url;
  final String filename;
  final PhotoType type;
  final DateTime timestamp;
  final GPSLocation? location;
  final Map<String, dynamic> metadata;

  const TimeEntryPhoto({
    required this.id,
    required this.url,
    required this.filename,
    required this.type,
    required this.timestamp,
    this.location,
    required this.metadata,
  });

  factory TimeEntryPhoto.fromJson(Map<String, dynamic> json) {
    return TimeEntryPhoto(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      filename: json['filename'] ?? '',
      type: PhotoType.values.firstWhere(
        (t) => t.toString() == 'PhotoType.${json['type']}',
        orElse: () => PhotoType.checkIn,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'] != null
          ? GPSLocation.fromJson(json['location'])
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'location': location?.toJson(),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        url,
        filename,
        type,
        timestamp,
        location,
        metadata,
      ];
}

/// Photo types for time entries
enum PhotoType {
  checkIn,
  checkOut,
  breakStart,
  breakEnd,
  incident,
  evidence,
}