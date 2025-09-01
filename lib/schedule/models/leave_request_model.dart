import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// LeaveRequest Model for Nederlandse verlof management
/// 
/// Compliant with Nederlandse arbeidsrecht and CAO requirements.
/// Supports vacation days, sick leave, and other leave types.
class LeaveRequest extends Equatable {
  final String id;
  final String guardId;
  final String companyId;
  final String? managerId;
  
  // Leave details
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final double totalHours;
  final String reason;
  final String? description;
  
  // Status and approval
  final LeaveStatus status;
  final DateTime? approvedAt;
  final String? approvedByUserId;
  final String? rejectionReason;
  final DateTime? respondedAt;
  final List<String> approvalWorkflow;
  
  // Medical leave specific
  final String? medicalCertificateUrl;
  final DateTime? doctorVisitDate;
  final bool requiresMedicalCertificate;
  
  // Vacation balance
  final double availableVacationDays;
  final double usedVacationDays;
  final double remainingVacationDays;
  final int vacationYear;
  
  // Emergency and coverage
  final bool isEmergencyLeave;
  final String? emergencyContactInfo;
  final List<String> coverageArrangements;
  final List<String> affectedShiftIds;
  
  // CAO compliance
  final CAOLeaveCompliance caoCompliance;
  final Map<String, dynamic> leaveEntitlements;
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;
  final List<String> attachmentUrls;
  final String? notes;

  const LeaveRequest({
    required this.id,
    required this.guardId,
    required this.companyId,
    this.managerId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.totalHours,
    required this.reason,
    this.description,
    required this.status,
    this.approvedAt,
    this.approvedByUserId,
    this.rejectionReason,
    this.respondedAt,
    required this.approvalWorkflow,
    this.medicalCertificateUrl,
    this.doctorVisitDate,
    required this.requiresMedicalCertificate,
    required this.availableVacationDays,
    required this.usedVacationDays,
    required this.remainingVacationDays,
    required this.vacationYear,
    required this.isEmergencyLeave,
    this.emergencyContactInfo,
    required this.coverageArrangements,
    required this.affectedShiftIds,
    required this.caoCompliance,
    required this.leaveEntitlements,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
    required this.attachmentUrls,
    this.notes,
  });

  /// Create LeaveRequest from Firestore document
  factory LeaveRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return LeaveRequest(
      id: doc.id,
      guardId: data['guardId'] ?? '',
      companyId: data['companyId'] ?? '',
      managerId: data['managerId'],
      type: LeaveType.values.firstWhere(
        (t) => t.toString() == 'LeaveType.${data['type']}',
        orElse: () => LeaveType.vacation,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalDays: data['totalDays'] ?? 0,
      totalHours: data['totalHours']?.toDouble() ?? 0.0,
      reason: data['reason'] ?? '',
      description: data['description'],
      status: LeaveStatus.values.firstWhere(
        (s) => s.toString() == 'LeaveStatus.${data['status']}',
        orElse: () => LeaveStatus.pending,
      ),
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      approvedByUserId: data['approvedByUserId'],
      rejectionReason: data['rejectionReason'],
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      approvalWorkflow: List<String>.from(data['approvalWorkflow'] ?? []),
      medicalCertificateUrl: data['medicalCertificateUrl'],
      doctorVisitDate: data['doctorVisitDate'] != null
          ? (data['doctorVisitDate'] as Timestamp).toDate()
          : null,
      requiresMedicalCertificate: data['requiresMedicalCertificate'] ?? false,
      availableVacationDays: data['availableVacationDays']?.toDouble() ?? 0.0,
      usedVacationDays: data['usedVacationDays']?.toDouble() ?? 0.0,
      remainingVacationDays: data['remainingVacationDays']?.toDouble() ?? 0.0,
      vacationYear: data['vacationYear'] ?? DateTime.now().year,
      isEmergencyLeave: data['isEmergencyLeave'] ?? false,
      emergencyContactInfo: data['emergencyContactInfo'],
      coverageArrangements: List<String>.from(data['coverageArrangements'] ?? []),
      affectedShiftIds: List<String>.from(data['affectedShiftIds'] ?? []),
      caoCompliance: CAOLeaveCompliance.fromJson(data['caoCompliance'] ?? {}),
      leaveEntitlements: Map<String, dynamic>.from(data['leaveEntitlements'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      notes: data['notes'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'guardId': guardId,
      'companyId': companyId,
      'managerId': managerId,
      'type': type.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalDays': totalDays,
      'totalHours': totalHours,
      'reason': reason,
      'description': description,
      'status': status.toString().split('.').last,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedByUserId': approvedByUserId,
      'rejectionReason': rejectionReason,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'approvalWorkflow': approvalWorkflow,
      'medicalCertificateUrl': medicalCertificateUrl,
      'doctorVisitDate': doctorVisitDate != null ? Timestamp.fromDate(doctorVisitDate!) : null,
      'requiresMedicalCertificate': requiresMedicalCertificate,
      'availableVacationDays': availableVacationDays,
      'usedVacationDays': usedVacationDays,
      'remainingVacationDays': remainingVacationDays,
      'vacationYear': vacationYear,
      'isEmergencyLeave': isEmergencyLeave,
      'emergencyContactInfo': emergencyContactInfo,
      'coverageArrangements': coverageArrangements,
      'affectedShiftIds': affectedShiftIds,
      'caoCompliance': caoCompliance.toJson(),
      'leaveEntitlements': leaveEntitlements,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
      'attachmentUrls': attachmentUrls,
      'notes': notes,
    };
  }

  /// Calculate duration in business days (excluding weekends)
  int get businessDays {
    int days = 0;
    DateTime current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (current.weekday < 6) { // Monday = 1, Sunday = 7
        days++;
      }
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  /// Check if leave request overlaps with another period
  bool overlapsWith(DateTime otherStart, DateTime otherEnd) {
    return startDate.isBefore(otherEnd) && endDate.isAfter(otherStart);
  }

  @override
  List<Object?> get props => [
        id,
        guardId,
        companyId,
        managerId,
        type,
        startDate,
        endDate,
        totalDays,
        totalHours,
        reason,
        description,
        status,
        approvedAt,
        approvedByUserId,
        rejectionReason,
        respondedAt,
        approvalWorkflow,
        medicalCertificateUrl,
        doctorVisitDate,
        requiresMedicalCertificate,
        availableVacationDays,
        usedVacationDays,
        remainingVacationDays,
        vacationYear,
        isEmergencyLeave,
        emergencyContactInfo,
        coverageArrangements,
        affectedShiftIds,
        caoCompliance,
        leaveEntitlements,
        createdAt,
        updatedAt,
        metadata,
        attachmentUrls,
        notes,
      ];
}

/// Nederlandse leave types
enum LeaveType {
  vacation,        // Vakantieverlof
  sickLeave,       // Ziekteverlof
  maternityLeave,  // Zwangerschapsverlof
  paternityLeave,  // Vaderschapsverlof
  parentalLeave,   // Ouderschapsverlof
  personalLeave,   // Persoonlijk verlof
  bereavementLeave, // Rouwverlof
  emergencyLeave,  // Calamiteitenverlof
  studyLeave,      // Studieverlof
  unpaidLeave,     // Onbetaald verlof
  compensationLeave, // Compensatieverlof
}

/// Leave request statuses
enum LeaveStatus {
  pending,
  approved,
  rejected,
  cancelled,
  withdrawn,
  expired,
  partiallyApproved,
}

/// CAO leave compliance tracking
class CAOLeaveCompliance extends Equatable {
  final bool isCompliant;
  final List<String> warnings;
  final List<String> violations;
  final double entitlementUsed; // Percentage of entitlement used
  final bool exceedsAnnualLimit;
  final bool meetsNoticePeriod;
  final int noticeDaysProvided;
  final int minimumNoticeDays;
  final bool hasValidDocumentation;

  const CAOLeaveCompliance({
    required this.isCompliant,
    required this.warnings,
    required this.violations,
    required this.entitlementUsed,
    required this.exceedsAnnualLimit,
    required this.meetsNoticePeriod,
    required this.noticeDaysProvided,
    required this.minimumNoticeDays,
    required this.hasValidDocumentation,
  });

  factory CAOLeaveCompliance.fromJson(Map<String, dynamic> json) {
    return CAOLeaveCompliance(
      isCompliant: json['isCompliant'] ?? true,
      warnings: List<String>.from(json['warnings'] ?? []),
      violations: List<String>.from(json['violations'] ?? []),
      entitlementUsed: json['entitlementUsed']?.toDouble() ?? 0.0,
      exceedsAnnualLimit: json['exceedsAnnualLimit'] ?? false,
      meetsNoticePeriod: json['meetsNoticePeriod'] ?? true,
      noticeDaysProvided: json['noticeDaysProvided'] ?? 0,
      minimumNoticeDays: json['minimumNoticeDays'] ?? 0,
      hasValidDocumentation: json['hasValidDocumentation'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCompliant': isCompliant,
      'warnings': warnings,
      'violations': violations,
      'entitlementUsed': entitlementUsed,
      'exceedsAnnualLimit': exceedsAnnualLimit,
      'meetsNoticePeriod': meetsNoticePeriod,
      'noticeDaysProvided': noticeDaysProvided,
      'minimumNoticeDays': minimumNoticeDays,
      'hasValidDocumentation': hasValidDocumentation,
    };
  }

  @override
  List<Object?> get props => [
        isCompliant,
        warnings,
        violations,
        entitlementUsed,
        exceedsAnnualLimit,
        meetsNoticePeriod,
        noticeDaysProvided,
        minimumNoticeDays,
        hasValidDocumentation,
      ];
}

/// Shift swap request model
class ShiftSwapRequest extends Equatable {
  final String id;
  final String originalShiftId;
  final String requestingGuardId;
  final String? replacementGuardId;
  final String companyId;
  
  // Swap details
  final SwapType swapType;
  final DateTime requestedDate;
  final String reason;
  final String? description;
  
  // Status and approval
  final SwapStatus status;
  final DateTime? approvedAt;
  final String? approvedByUserId;
  final String? rejectionReason;
  
  // Replacement details
  final String? replacementShiftId;
  final DateTime? swapDate;
  final bool requiresCompanyApproval;
  final bool requiresGuardApproval;
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const ShiftSwapRequest({
    required this.id,
    required this.originalShiftId,
    required this.requestingGuardId,
    this.replacementGuardId,
    required this.companyId,
    required this.swapType,
    required this.requestedDate,
    required this.reason,
    this.description,
    required this.status,
    this.approvedAt,
    this.approvedByUserId,
    this.rejectionReason,
    this.replacementShiftId,
    this.swapDate,
    required this.requiresCompanyApproval,
    required this.requiresGuardApproval,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
  });

  factory ShiftSwapRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ShiftSwapRequest(
      id: doc.id,
      originalShiftId: data['originalShiftId'] ?? '',
      requestingGuardId: data['requestingGuardId'] ?? '',
      replacementGuardId: data['replacementGuardId'],
      companyId: data['companyId'] ?? '',
      swapType: SwapType.values.firstWhere(
        (t) => t.toString() == 'SwapType.${data['swapType']}',
        orElse: () => SwapType.oneTime,
      ),
      requestedDate: (data['requestedDate'] as Timestamp).toDate(),
      reason: data['reason'] ?? '',
      description: data['description'],
      status: SwapStatus.values.firstWhere(
        (s) => s.toString() == 'SwapStatus.${data['status']}',
        orElse: () => SwapStatus.pending,
      ),
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      approvedByUserId: data['approvedByUserId'],
      rejectionReason: data['rejectionReason'],
      replacementShiftId: data['replacementShiftId'],
      swapDate: data['swapDate'] != null
          ? (data['swapDate'] as Timestamp).toDate()
          : null,
      requiresCompanyApproval: data['requiresCompanyApproval'] ?? true,
      requiresGuardApproval: data['requiresGuardApproval'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'originalShiftId': originalShiftId,
      'requestingGuardId': requestingGuardId,
      'replacementGuardId': replacementGuardId,
      'companyId': companyId,
      'swapType': swapType.toString().split('.').last,
      'requestedDate': Timestamp.fromDate(requestedDate),
      'reason': reason,
      'description': description,
      'status': status.toString().split('.').last,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedByUserId': approvedByUserId,
      'rejectionReason': rejectionReason,
      'replacementShiftId': replacementShiftId,
      'swapDate': swapDate != null ? Timestamp.fromDate(swapDate!) : null,
      'requiresCompanyApproval': requiresCompanyApproval,
      'requiresGuardApproval': requiresGuardApproval,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  ShiftSwapRequest copyWith({
    String? id,
    String? originalShiftId,
    String? requestingGuardId,
    String? replacementGuardId,
    String? companyId,
    SwapType? swapType,
    DateTime? requestedDate,
    String? reason,
    String? description,
    SwapStatus? status,
    DateTime? approvedAt,
    String? approvedByUserId,
    String? rejectionReason,
    String? replacementShiftId,
    DateTime? swapDate,
    bool? requiresCompanyApproval,
    bool? requiresGuardApproval,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ShiftSwapRequest(
      id: id ?? this.id,
      originalShiftId: originalShiftId ?? this.originalShiftId,
      requestingGuardId: requestingGuardId ?? this.requestingGuardId,
      replacementGuardId: replacementGuardId ?? this.replacementGuardId,
      companyId: companyId ?? this.companyId,
      swapType: swapType ?? this.swapType,
      requestedDate: requestedDate ?? this.requestedDate,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedByUserId: approvedByUserId ?? this.approvedByUserId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      replacementShiftId: replacementShiftId ?? this.replacementShiftId,
      swapDate: swapDate ?? this.swapDate,
      requiresCompanyApproval: requiresCompanyApproval ?? this.requiresCompanyApproval,
      requiresGuardApproval: requiresGuardApproval ?? this.requiresGuardApproval,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        originalShiftId,
        requestingGuardId,
        replacementGuardId,
        companyId,
        swapType,
        requestedDate,
        reason,
        description,
        status,
        approvedAt,
        approvedByUserId,
        rejectionReason,
        replacementShiftId,
        swapDate,
        requiresCompanyApproval,
        requiresGuardApproval,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Shift swap types
enum SwapType {
  oneTime,      // Eenmalige ruil
  recurring,    // Terugkerende ruil
  permanent,    // Permanente ruil
}

/// Swap request statuses
enum SwapStatus {
  pending,
  approved,
  rejected,
  cancelled,
  completed,
  expired,
}

/// Overtime record model
class OvertimeRecord extends Equatable {
  final String id;
  final String guardId;
  final String companyId;
  final String shiftId;
  final String timeEntryId;
  
  // Overtime details
  final DateTime overtimeDate;
  final double regularHours;
  final double overtimeHours;
  final OvertimeType overtimeType;
  final double overtimeRate; // Multiplier (1.5, 2.0, etc.)
  final double baseHourlyRate;
  final double totalOvertimePay;
  
  // CAO compliance
  final bool isCAOCompliant;
  final String? caoViolationReason;
  final bool preApproved;
  final bool requiresApproval;
  
  // Approval
  final OvertimeStatus status;
  final DateTime? approvedAt;
  final String? approvedByUserId;
  final String? rejectionReason;
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const OvertimeRecord({
    required this.id,
    required this.guardId,
    required this.companyId,
    required this.shiftId,
    required this.timeEntryId,
    required this.overtimeDate,
    required this.regularHours,
    required this.overtimeHours,
    required this.overtimeType,
    required this.overtimeRate,
    required this.baseHourlyRate,
    required this.totalOvertimePay,
    required this.isCAOCompliant,
    this.caoViolationReason,
    required this.preApproved,
    required this.requiresApproval,
    required this.status,
    this.approvedAt,
    this.approvedByUserId,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
  });

  factory OvertimeRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return OvertimeRecord(
      id: doc.id,
      guardId: data['guardId'] ?? '',
      companyId: data['companyId'] ?? '',
      shiftId: data['shiftId'] ?? '',
      timeEntryId: data['timeEntryId'] ?? '',
      overtimeDate: (data['overtimeDate'] as Timestamp).toDate(),
      regularHours: data['regularHours']?.toDouble() ?? 0.0,
      overtimeHours: data['overtimeHours']?.toDouble() ?? 0.0,
      overtimeType: OvertimeType.values.firstWhere(
        (t) => t.toString() == 'OvertimeType.${data['overtimeType']}',
        orElse: () => OvertimeType.daily,
      ),
      overtimeRate: data['overtimeRate']?.toDouble() ?? 1.5,
      baseHourlyRate: data['baseHourlyRate']?.toDouble() ?? 0.0,
      totalOvertimePay: data['totalOvertimePay']?.toDouble() ?? 0.0,
      isCAOCompliant: data['isCAOCompliant'] ?? true,
      caoViolationReason: data['caoViolationReason'],
      preApproved: data['preApproved'] ?? false,
      requiresApproval: data['requiresApproval'] ?? true,
      status: OvertimeStatus.values.firstWhere(
        (s) => s.toString() == 'OvertimeStatus.${data['status']}',
        orElse: () => OvertimeStatus.pending,
      ),
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      approvedByUserId: data['approvedByUserId'],
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'guardId': guardId,
      'companyId': companyId,
      'shiftId': shiftId,
      'timeEntryId': timeEntryId,
      'overtimeDate': Timestamp.fromDate(overtimeDate),
      'regularHours': regularHours,
      'overtimeHours': overtimeHours,
      'overtimeType': overtimeType.toString().split('.').last,
      'overtimeRate': overtimeRate,
      'baseHourlyRate': baseHourlyRate,
      'totalOvertimePay': totalOvertimePay,
      'isCAOCompliant': isCAOCompliant,
      'caoViolationReason': caoViolationReason,
      'preApproved': preApproved,
      'requiresApproval': requiresApproval,
      'status': status.toString().split('.').last,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedByUserId': approvedByUserId,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        guardId,
        companyId,
        shiftId,
        timeEntryId,
        overtimeDate,
        regularHours,
        overtimeHours,
        overtimeType,
        overtimeRate,
        baseHourlyRate,
        totalOvertimePay,
        isCAOCompliant,
        caoViolationReason,
        preApproved,
        requiresApproval,
        status,
        approvedAt,
        approvedByUserId,
        rejectionReason,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Overtime types
enum OvertimeType {
  daily,      // Dagelijks overwerk
  weekly,     // Wekelijks overwerk
  weekend,    // Weekendwerk
  night,      // Nachtwerk
  holiday,    // Feestdagwerk
}

/// Overtime approval statuses
enum OvertimeStatus {
  pending,
  approved,
  rejected,
  cancelled,
  paid,
}