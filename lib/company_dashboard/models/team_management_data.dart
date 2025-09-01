import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart' show GuardAvailabilityStatus;

/// Team status overview data for real-time dashboard
class TeamStatusData {
  final String companyId;
  final int totalGuards;
  final int availableGuards;
  final int onDutyGuards;
  final int offDutyGuards;
  final int emergencyGuards;
  final List<GuardLocationData> activeGuardLocations;
  final List<CoverageGap> coverageGaps;
  final EmergencyStatus emergencyStatus;
  final DateTime lastUpdated;
  final TeamMetrics metrics;

  const TeamStatusData({
    required this.companyId,
    this.totalGuards = 0,
    this.availableGuards = 0,
    this.onDutyGuards = 0,
    this.offDutyGuards = 0,
    this.emergencyGuards = 0,
    this.activeGuardLocations = const [],
    this.coverageGaps = const [],
    this.emergencyStatus = EmergencyStatus.normal,
    required this.lastUpdated,
    required this.metrics,
  });

  /// Create from Firestore document
  factory TeamStatusData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamStatusData(
      companyId: doc.id,
      totalGuards: data['totalGuards'] ?? 0,
      availableGuards: data['availableGuards'] ?? 0,
      onDutyGuards: data['onDutyGuards'] ?? 0,
      offDutyGuards: data['offDutyGuards'] ?? 0,
      emergencyGuards: data['emergencyGuards'] ?? 0,
      activeGuardLocations: (data['activeGuardLocations'] as List<dynamic>?)
          ?.map((item) => GuardLocationData.fromMap(item))
          .toList() ?? [],
      coverageGaps: (data['coverageGaps'] as List<dynamic>?)
          ?.map((item) => CoverageGap.fromMap(item))
          .toList() ?? [],
      emergencyStatus: EmergencyStatus.values.firstWhere(
        (status) => status.name == (data['emergencyStatus'] ?? 'normal'),
        orElse: () => EmergencyStatus.normal,
      ),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      metrics: TeamMetrics.fromMap(data['metrics'] ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'totalGuards': totalGuards,
      'availableGuards': availableGuards,
      'onDutyGuards': onDutyGuards,
      'offDutyGuards': offDutyGuards,
      'emergencyGuards': emergencyGuards,
      'activeGuardLocations': activeGuardLocations.map((loc) => loc.toMap()).toList(),
      'coverageGaps': coverageGaps.map((gap) => gap.toMap()).toList(),
      'emergencyStatus': emergencyStatus.name,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'metrics': metrics.toMap(),
    };
  }

  TeamStatusData copyWith({
    String? companyId,
    int? totalGuards,
    int? availableGuards,
    int? onDutyGuards,
    int? offDutyGuards,
    int? emergencyGuards,
    List<GuardLocationData>? activeGuardLocations,
    List<CoverageGap>? coverageGaps,
    EmergencyStatus? emergencyStatus,
    DateTime? lastUpdated,
    TeamMetrics? metrics,
  }) {
    return TeamStatusData(
      companyId: companyId ?? this.companyId,
      totalGuards: totalGuards ?? this.totalGuards,
      availableGuards: availableGuards ?? this.availableGuards,
      onDutyGuards: onDutyGuards ?? this.onDutyGuards,
      offDutyGuards: offDutyGuards ?? this.offDutyGuards,
      emergencyGuards: emergencyGuards ?? this.emergencyGuards,
      activeGuardLocations: activeGuardLocations ?? this.activeGuardLocations,
      coverageGaps: coverageGaps ?? this.coverageGaps,
      emergencyStatus: emergencyStatus ?? this.emergencyStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metrics: metrics ?? this.metrics,
    );
  }
}

/// Guard location and status data for real-time tracking
class GuardLocationData {
  final String guardId;
  final String guardName;
  final String? guardAvatarUrl;
  final double? latitude;
  final double? longitude;
  final DateTime lastUpdate;
  final GuardAvailabilityStatus status;
  final String? currentAssignment;
  final String? currentAssignmentTitle;
  final String? currentLocation;
  final bool isEmergency;
  final double? batteryLevel;
  final bool isLocationEnabled;
  
  // Privacy-compliant fields (added for GDPR compliance)
  final String? proximityStatus; // e.g., 'at_work_location', 'near_work_location', 'away_from_work'
  final double? approximateDistance; // Rounded to nearest 100m for privacy

  const GuardLocationData({
    required this.guardId,
    required this.guardName,
    this.guardAvatarUrl,
    this.latitude,
    this.longitude,
    required this.lastUpdate,
    this.status = GuardAvailabilityStatus.unavailable,
    this.currentAssignment,
    this.currentAssignmentTitle,
    this.currentLocation,
    this.isEmergency = false,
    this.batteryLevel,
    this.isLocationEnabled = false,
    this.proximityStatus,
    this.approximateDistance,
  });

  /// Create from Firestore document
  factory GuardLocationData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GuardLocationData.fromMap(data);
  }

  /// Create from Map
  factory GuardLocationData.fromMap(Map<String, dynamic> data) {
    return GuardLocationData(
      guardId: data['guardId'] ?? '',
      guardName: data['guardName'] ?? '',
      guardAvatarUrl: data['guardAvatarUrl'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      lastUpdate: data['lastUpdate'] is Timestamp 
          ? (data['lastUpdate'] as Timestamp).toDate()
          : DateTime.now(),
      status: GuardAvailabilityStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'unavailable'),
        orElse: () => GuardAvailabilityStatus.unavailable,
      ),
      currentAssignment: data['currentAssignment'],
      currentAssignmentTitle: data['currentAssignmentTitle'],
      currentLocation: data['currentLocation'],
      isEmergency: data['isEmergency'] ?? false,
      batteryLevel: data['batteryLevel']?.toDouble(),
      isLocationEnabled: data['isLocationEnabled'] ?? false,
      proximityStatus: data['proximityStatus'],
      approximateDistance: data['approximateDistance']?.toDouble(),
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'guardId': guardId,
      'guardName': guardName,
      'guardAvatarUrl': guardAvatarUrl,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdate': Timestamp.fromDate(lastUpdate),
      'status': status.name,
      'currentAssignment': currentAssignment,
      'currentAssignmentTitle': currentAssignmentTitle,
      'currentLocation': currentLocation,
      'isEmergency': isEmergency,
      'batteryLevel': batteryLevel,
      'isLocationEnabled': isLocationEnabled,
      'proximityStatus': proximityStatus,
      'approximateDistance': approximateDistance,
    };
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => toMap();

  GuardLocationData copyWith({
    String? guardId,
    String? guardName,
    String? guardAvatarUrl,
    double? latitude,
    double? longitude,
    DateTime? lastUpdate,
    GuardAvailabilityStatus? status,
    String? currentAssignment,
    String? currentAssignmentTitle,
    String? currentLocation,
    bool? isEmergency,
    double? batteryLevel,
    bool? isLocationEnabled,
    String? proximityStatus,
    double? approximateDistance,
  }) {
    return GuardLocationData(
      guardId: guardId ?? this.guardId,
      guardName: guardName ?? this.guardName,
      guardAvatarUrl: guardAvatarUrl ?? this.guardAvatarUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      status: status ?? this.status,
      currentAssignment: currentAssignment ?? this.currentAssignment,
      currentAssignmentTitle: currentAssignmentTitle ?? this.currentAssignmentTitle,
      currentLocation: currentLocation ?? this.currentLocation,
      isEmergency: isEmergency ?? this.isEmergency,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      proximityStatus: proximityStatus ?? this.proximityStatus,
      approximateDistance: approximateDistance ?? this.approximateDistance,
    );
  }
}

/// Coverage gap data for scheduling and emergency management
class CoverageGap {
  final String gapId;
  final String companyId;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String postalCode;
  final CoverageGapSeverity severity;
  final List<String> affectedJobIds;
  final List<String> affectedJobTitles;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNotes;
  final List<String> suggestedReplacements;
  final DateTime createdAt;

  const CoverageGap({
    required this.gapId,
    required this.companyId,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.postalCode,
    this.severity = CoverageGapSeverity.medium,
    this.affectedJobIds = const [],
    this.affectedJobTitles = const [],
    this.isResolved = false,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
    this.suggestedReplacements = const [],
    required this.createdAt,
  });

  /// Create from Map
  factory CoverageGap.fromMap(Map<String, dynamic> data) {
    return CoverageGap(
      gapId: data['gapId'] ?? '',
      companyId: data['companyId'] ?? '',
      startTime: data['startTime'] is Timestamp 
          ? (data['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: data['endTime'] is Timestamp 
          ? (data['endTime'] as Timestamp).toDate()
          : DateTime.now(),
      location: data['location'] ?? '',
      postalCode: data['postalCode'] ?? '',
      severity: CoverageGapSeverity.values.firstWhere(
        (s) => s.name == (data['severity'] ?? 'medium'),
        orElse: () => CoverageGapSeverity.medium,
      ),
      affectedJobIds: List<String>.from(data['affectedJobIds'] ?? []),
      affectedJobTitles: List<String>.from(data['affectedJobTitles'] ?? []),
      isResolved: data['isResolved'] ?? false,
      resolvedAt: data['resolvedAt'] is Timestamp 
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      resolvedBy: data['resolvedBy'],
      resolutionNotes: data['resolutionNotes'],
      suggestedReplacements: List<String>.from(data['suggestedReplacements'] ?? []),
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'gapId': gapId,
      'companyId': companyId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'postalCode': postalCode,
      'severity': severity.name,
      'affectedJobIds': affectedJobIds,
      'affectedJobTitles': affectedJobTitles,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'resolutionNotes': resolutionNotes,
      'suggestedReplacements': suggestedReplacements,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Team metrics for analytics and performance tracking
class TeamMetrics {
  final double averageRating;
  final double reliabilityScore;
  final double averageResponseTime; // minutes
  final double clientSatisfactionScore;
  final int totalJobsCompleted;
  final int jobsCompletedThisMonth;
  final double revenueGenerated;
  final double revenueThisMonth;
  final int emergencyResponseCount;
  final double emergencyResponseTime; // minutes

  const TeamMetrics({
    this.averageRating = 0.0,
    this.reliabilityScore = 0.0,
    this.averageResponseTime = 0.0,
    this.clientSatisfactionScore = 0.0,
    this.totalJobsCompleted = 0,
    this.jobsCompletedThisMonth = 0,
    this.revenueGenerated = 0.0,
    this.revenueThisMonth = 0.0,
    this.emergencyResponseCount = 0,
    this.emergencyResponseTime = 0.0,
  });

  factory TeamMetrics.fromMap(Map<String, dynamic> data) {
    return TeamMetrics(
      averageRating: data['averageRating']?.toDouble() ?? 0.0,
      reliabilityScore: data['reliabilityScore']?.toDouble() ?? 0.0,
      averageResponseTime: data['averageResponseTime']?.toDouble() ?? 0.0,
      clientSatisfactionScore: data['clientSatisfactionScore']?.toDouble() ?? 0.0,
      totalJobsCompleted: data['totalJobsCompleted'] ?? 0,
      jobsCompletedThisMonth: data['jobsCompletedThisMonth'] ?? 0,
      revenueGenerated: data['revenueGenerated']?.toDouble() ?? 0.0,
      revenueThisMonth: data['revenueThisMonth']?.toDouble() ?? 0.0,
      emergencyResponseCount: data['emergencyResponseCount'] ?? 0,
      emergencyResponseTime: data['emergencyResponseTime']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averageRating': averageRating,
      'reliabilityScore': reliabilityScore,
      'averageResponseTime': averageResponseTime,
      'clientSatisfactionScore': clientSatisfactionScore,
      'totalJobsCompleted': totalJobsCompleted,
      'jobsCompletedThisMonth': jobsCompletedThisMonth,
      'revenueGenerated': revenueGenerated,
      'revenueThisMonth': revenueThisMonth,
      'emergencyResponseCount': emergencyResponseCount,
      'emergencyResponseTime': emergencyResponseTime,
    };
  }
}

/// Emergency status levels for team management
enum EmergencyStatus {
  normal,
  warning,
  critical,
  emergency,
}

/// Coverage gap severity levels
enum CoverageGapSeverity {
  low,
  medium,
  high,
  critical,
}

/// Extension methods for emergency status
extension EmergencyStatusExtension on EmergencyStatus {
  String get displayName {
    switch (this) {
      case EmergencyStatus.normal:
        return 'Normaal';
      case EmergencyStatus.warning:
        return 'Waarschuwing';
      case EmergencyStatus.critical:
        return 'Kritiek';
      case EmergencyStatus.emergency:
        return 'Noodgeval';
    }
  }

  String get description {
    switch (this) {
      case EmergencyStatus.normal:
        return 'Alle systemen operationeel';
      case EmergencyStatus.warning:
        return 'Aandacht vereist';
      case EmergencyStatus.critical:
        return 'Onmiddellijke actie nodig';
      case EmergencyStatus.emergency:
        return 'Noodsituatie actief';
    }
  }
}

/// Extension methods for coverage gap severity
extension CoverageGapSeverityExtension on CoverageGapSeverity {
  String get displayName {
    switch (this) {
      case CoverageGapSeverity.low:
        return 'Laag';
      case CoverageGapSeverity.medium:
        return 'Gemiddeld';
      case CoverageGapSeverity.high:
        return 'Hoog';
      case CoverageGapSeverity.critical:
        return 'Kritiek';
    }
  }

  String get description {
    switch (this) {
      case CoverageGapSeverity.low:
        return 'Minimale impact op service';
      case CoverageGapSeverity.medium:
        return 'Matige impact op service';
      case CoverageGapSeverity.high:
        return 'Significante impact op service';
      case CoverageGapSeverity.critical:
        return 'Kritieke impact op service';
    }
  }
}
