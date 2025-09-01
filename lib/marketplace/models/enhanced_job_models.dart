import 'package:equatable/equatable.dart';
import '../services/certificate_matching_service.dart';

/// Enhanced job application model with Nederlandse fields and compliance
class JobApplicationEnhanced extends Equatable {
  final String id;
  final String jobId;
  final String userId;
  final String userFullName;
  final String userEmail;
  final String userPhone;
  final String userPostcode;
  final List<String> userCertificates;
  final String motivationLetter;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? lastUpdated;
  final List<ApplicationStatusHistory> statusHistory;
  final String? companyResponse;
  final CertificateMatchResult? certificateMatch;
  final Map<String, dynamic> additionalData;
  final ApplicationPriority priority;
  final bool isUrgent;
  final String? withdrawalReason;
  final DateTime? expectedStartDate;
  final int? expectedDurationHours;
  
  const JobApplicationEnhanced({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.userFullName,
    required this.userEmail,
    required this.userPhone,
    required this.userPostcode,
    required this.userCertificates,
    required this.motivationLetter,
    required this.status,
    required this.appliedAt,
    this.lastUpdated,
    this.statusHistory = const [],
    this.companyResponse,
    this.certificateMatch,
    this.additionalData = const {},
    this.priority = ApplicationPriority.normal,
    this.isUrgent = false,
    this.withdrawalReason,
    this.expectedStartDate,
    this.expectedDurationHours,
  });
  
  /// Get Dutch status description
  String get statusDescriptionNL {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Wacht op beoordeling';
      case ApplicationStatus.accepted:
        return 'Geaccepteerd door werkgever';
      case ApplicationStatus.rejected:
        return 'Afgewezen door werkgever';
      case ApplicationStatus.confirmed:
        return 'Bevestigd door beveiliger';
      case ApplicationStatus.withdrawn:
        return 'Ingetrokken door beveiliger';
      case ApplicationStatus.inProgress:
        return 'Opdracht in uitvoering';
      case ApplicationStatus.completed:
        return 'Opdracht voltooid';
    }
  }
  
  /// Get priority description in Dutch
  String get priorityDescriptionNL {
    switch (priority) {
      case ApplicationPriority.low:
        return 'Lage prioriteit';
      case ApplicationPriority.normal:
        return 'Normale prioriteit';
      case ApplicationPriority.high:
        return 'Hoge prioriteit';
      case ApplicationPriority.urgent:
        return 'Spoedeisend';
    }
  }
  
  /// Check if application can be withdrawn
  bool get canBeWithdrawn {
    return status == ApplicationStatus.pending || 
           status == ApplicationStatus.accepted;
  }
  
  /// Get days since application
  int get daysSinceApplication {
    return DateTime.now().difference(appliedAt).inDays;
  }
  
  /// Check if application is expired (older than 30 days without response)
  bool get isExpired {
    if (status != ApplicationStatus.pending) return false;
    return daysSinceApplication > 30;
  }
  
  /// Get certificate match score if available
  int get certificateMatchScore {
    return certificateMatch?.matchScore ?? 0;
  }
  
  /// Check if user is qualified based on certificates
  bool get isQualified {
    return certificateMatch?.isEligible ?? false;
  }
  
  @override
  List<Object?> get props => [
    id,
    jobId,
    userId,
    userFullName,
    userEmail,
    userPhone,
    userPostcode,
    userCertificates,
    motivationLetter,
    status,
    appliedAt,
    lastUpdated,
    statusHistory,
    companyResponse,
    certificateMatch,
    additionalData,
    priority,
    isUrgent,
    withdrawalReason,
    expectedStartDate,
    expectedDurationHours,
  ];
  
  /// Copy with updated values
  JobApplicationEnhanced copyWith({
    String? id,
    String? jobId,
    String? userId,
    String? userFullName,
    String? userEmail,
    String? userPhone,
    String? userPostcode,
    List<String>? userCertificates,
    String? motivationLetter,
    ApplicationStatus? status,
    DateTime? appliedAt,
    DateTime? lastUpdated,
    List<ApplicationStatusHistory>? statusHistory,
    String? companyResponse,
    CertificateMatchResult? certificateMatch,
    Map<String, dynamic>? additionalData,
    ApplicationPriority? priority,
    bool? isUrgent,
    String? withdrawalReason,
    DateTime? expectedStartDate,
    int? expectedDurationHours,
  }) {
    return JobApplicationEnhanced(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      userFullName: userFullName ?? this.userFullName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      userPostcode: userPostcode ?? this.userPostcode,
      userCertificates: userCertificates ?? this.userCertificates,
      motivationLetter: motivationLetter ?? this.motivationLetter,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      statusHistory: statusHistory ?? this.statusHistory,
      companyResponse: companyResponse ?? this.companyResponse,
      certificateMatch: certificateMatch ?? this.certificateMatch,
      additionalData: additionalData ?? this.additionalData,
      priority: priority ?? this.priority,
      isUrgent: isUrgent ?? this.isUrgent,
      withdrawalReason: withdrawalReason ?? this.withdrawalReason,
      expectedStartDate: expectedStartDate ?? this.expectedStartDate,
      expectedDurationHours: expectedDurationHours ?? this.expectedDurationHours,
    );
  }
  
  /// Convert to map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'userId': userId,
      'userFullName': userFullName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userPostcode': userPostcode,
      'userCertificates': userCertificates,
      'motivationLetter': motivationLetter,
      'status': status.name,
      'appliedAt': appliedAt.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'statusHistory': statusHistory.map((h) => h.toMap()).toList(),
      'companyResponse': companyResponse,
      'additionalData': additionalData,
      'priority': priority.name,
      'isUrgent': isUrgent,
      'withdrawalReason': withdrawalReason,
      'expectedStartDate': expectedStartDate?.toIso8601String(),
      'expectedDurationHours': expectedDurationHours,
    };
  }
  
  /// Create from Firestore map
  factory JobApplicationEnhanced.fromFirestore(Map<String, dynamic> data, String id) {
    return JobApplicationEnhanced(
      id: id,
      jobId: data['jobId'] ?? '',
      userId: data['userId'] ?? '',
      userFullName: data['userFullName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhone: data['userPhone'] ?? '',
      userPostcode: data['userPostcode'] ?? '',
      userCertificates: List<String>.from(data['userCertificates'] ?? []),
      motivationLetter: data['motivationLetter'] ?? '',
      status: ApplicationStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ApplicationStatus.pending,
      ),
      appliedAt: DateTime.tryParse(data['appliedAt'] ?? '') ?? DateTime.now(),
      lastUpdated: data['lastUpdated'] != null 
          ? DateTime.tryParse(data['lastUpdated']) 
          : null,
      statusHistory: (data['statusHistory'] as List? ?? [])
          .map((h) => ApplicationStatusHistory.fromMap(h))
          .toList(),
      companyResponse: data['companyResponse'],
      additionalData: Map<String, dynamic>.from(data['additionalData'] ?? {}),
      priority: ApplicationPriority.values.firstWhere(
        (p) => p.name == data['priority'],
        orElse: () => ApplicationPriority.normal,
      ),
      isUrgent: data['isUrgent'] ?? false,
      withdrawalReason: data['withdrawalReason'],
      expectedStartDate: data['expectedStartDate'] != null 
          ? DateTime.tryParse(data['expectedStartDate']) 
          : null,
      expectedDurationHours: data['expectedDurationHours'],
    );
  }
}

/// Enhanced favorite job model with categorization
class FavoriteJobEnhanced extends Equatable {
  final String id;
  final String jobId;
  final String userId;
  final DateTime addedAt;
  final FavoriteCategory category;
  final List<String> tags;
  final String? notes;
  final bool isNotificationEnabled;
  final DateTime? remindAt;
  final int priority;
  final Map<String, dynamic> metadata;
  
  const FavoriteJobEnhanced({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.addedAt,
    this.category = FavoriteCategory.general,
    this.tags = const [],
    this.notes,
    this.isNotificationEnabled = true,
    this.remindAt,
    this.priority = 0,
    this.metadata = const {},
  });
  
  /// Get category description in Dutch
  String get categoryDescriptionNL {
    switch (category) {
      case FavoriteCategory.general:
        return 'Algemeen';
      case FavoriteCategory.urgent:
        return 'Spoedeisend';
      case FavoriteCategory.highPay:
        return 'Goed betaald';
      case FavoriteCategory.nearLocation:
        return 'Dichtbij';
      case FavoriteCategory.preferredCompany:
        return 'Favoriete werkgever';
      case FavoriteCategory.goodMatch:
        return 'Goede match';
      case FavoriteCategory.toApplyLater:
        return 'Later solliciteren';
    }
  }
  
  /// Check if reminder is active
  bool get hasActiveReminder {
    return remindAt != null && remindAt!.isAfter(DateTime.now());
  }
  
  /// Get days until reminder
  int? get daysUntilReminder {
    if (remindAt == null) return null;
    final difference = remindAt!.difference(DateTime.now()).inDays;
    return difference > 0 ? difference : null;
  }
  
  @override
  List<Object?> get props => [
    id,
    jobId,
    userId,
    addedAt,
    category,
    tags,
    notes,
    isNotificationEnabled,
    remindAt,
    priority,
    metadata,
  ];
  
  /// Copy with updated values
  FavoriteJobEnhanced copyWith({
    String? id,
    String? jobId,
    String? userId,
    DateTime? addedAt,
    FavoriteCategory? category,
    List<String>? tags,
    String? notes,
    bool? isNotificationEnabled,
    DateTime? remindAt,
    int? priority,
    Map<String, dynamic>? metadata,
  }) {
    return FavoriteJobEnhanced(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      addedAt: addedAt ?? this.addedAt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      remindAt: remindAt ?? this.remindAt,
      priority: priority ?? this.priority,
      metadata: metadata ?? this.metadata,
    );
  }
  
  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'userId': userId,
      'addedAt': addedAt.toIso8601String(),
      'category': category.name,
      'tags': tags,
      'notes': notes,
      'isNotificationEnabled': isNotificationEnabled,
      'remindAt': remindAt?.toIso8601String(),
      'priority': priority,
      'metadata': metadata,
    };
  }
  
  /// Create from map
  factory FavoriteJobEnhanced.fromMap(Map<String, dynamic> data, String id) {
    return FavoriteJobEnhanced(
      id: id,
      jobId: data['jobId'] ?? '',
      userId: data['userId'] ?? '',
      addedAt: DateTime.tryParse(data['addedAt'] ?? '') ?? DateTime.now(),
      category: FavoriteCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => FavoriteCategory.general,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      notes: data['notes'],
      isNotificationEnabled: data['isNotificationEnabled'] ?? true,
      remindAt: data['remindAt'] != null 
          ? DateTime.tryParse(data['remindAt']) 
          : null,
      priority: data['priority'] ?? 0,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
}

/// Application status history for audit trail
class ApplicationStatusHistory extends Equatable {
  final ApplicationStatus fromStatus;
  final ApplicationStatus toStatus;
  final DateTime changedAt;
  final String changedBy;
  final String? reason;
  final String? notes;
  
  const ApplicationStatusHistory({
    required this.fromStatus,
    required this.toStatus,
    required this.changedAt,
    required this.changedBy,
    this.reason,
    this.notes,
  });
  
  /// Get change description in Dutch
  String get changeDescriptionNL {
    switch (toStatus) {
      case ApplicationStatus.accepted:
        return 'Sollicitatie geaccepteerd door werkgever';
      case ApplicationStatus.rejected:
        return 'Sollicitatie afgewezen door werkgever';
      case ApplicationStatus.confirmed:
        return 'Sollicitatie bevestigd door beveiliger';
      case ApplicationStatus.withdrawn:
        return 'Sollicitatie ingetrokken door beveiliger';
      case ApplicationStatus.inProgress:
        return 'Opdracht gestart';
      case ApplicationStatus.completed:
        return 'Opdracht voltooid';
      case ApplicationStatus.pending:
        return 'Status teruggezet naar in behandeling';
    }
  }
  
  @override
  List<Object?> get props => [
    fromStatus,
    toStatus,
    changedAt,
    changedBy,
    reason,
    notes,
  ];
  
  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'fromStatus': fromStatus.name,
      'toStatus': toStatus.name,
      'changedAt': changedAt.toIso8601String(),
      'changedBy': changedBy,
      'reason': reason,
      'notes': notes,
    };
  }
  
  /// Create from map
  factory ApplicationStatusHistory.fromMap(Map<String, dynamic> data) {
    return ApplicationStatusHistory(
      fromStatus: ApplicationStatus.values.firstWhere(
        (s) => s.name == data['fromStatus'],
        orElse: () => ApplicationStatus.pending,
      ),
      toStatus: ApplicationStatus.values.firstWhere(
        (s) => s.name == data['toStatus'],
        orElse: () => ApplicationStatus.pending,
      ),
      changedAt: DateTime.tryParse(data['changedAt'] ?? '') ?? DateTime.now(),
      changedBy: data['changedBy'] ?? '',
      reason: data['reason'],
      notes: data['notes'],
    );
  }
}

/// Enhanced user profile for job matching
class UserProfileEnhanced extends Equatable {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String postcode;
  final List<String> certificates;
  final List<String> preferredJobTypes;
  final double preferredMinSalary;
  final double preferredMaxSalary;
  final double maxTravelDistance;
  final List<String> preferredCompanies;
  final bool isAvailableWeekdays;
  final bool isAvailableWeekends;
  final bool isAvailableNights;
  final DateTime? availableFrom;
  final String? bio;
  final Map<String, dynamic> preferences;
  final DateTime? lastUpdated;
  
  const UserProfileEnhanced({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.postcode,
    this.certificates = const [],
    this.preferredJobTypes = const [],
    this.preferredMinSalary = 18.0,
    this.preferredMaxSalary = 35.0,
    this.maxTravelDistance = 25.0,
    this.preferredCompanies = const [],
    this.isAvailableWeekdays = true,
    this.isAvailableWeekends = true,
    this.isAvailableNights = false,
    this.availableFrom,
    this.bio,
    this.preferences = const {},
    this.lastUpdated,
  });
  
  /// Check if profile is complete for job matching
  bool get isComplete {
    return fullName.isNotEmpty &&
           email.isNotEmpty &&
           phone.isNotEmpty &&
           postcode.isNotEmpty &&
           certificates.isNotEmpty;
  }
  
  /// Get completion percentage
  double get completionPercentage {
    int completed = 0;
    int total = 10;
    
    if (fullName.isNotEmpty) completed++;
    if (email.isNotEmpty) completed++;
    if (phone.isNotEmpty) completed++;
    if (postcode.isNotEmpty) completed++;
    if (certificates.isNotEmpty) completed++;
    if (preferredJobTypes.isNotEmpty) completed++;
    if (bio != null && bio!.isNotEmpty) completed++;
    if (availableFrom != null) completed++;
    if (isAvailableWeekdays || isAvailableWeekends) completed++;
    if (preferredMinSalary > 0) completed++;
    
    return (completed / total) * 100;
  }
  
  @override
  List<Object?> get props => [
    userId,
    fullName,
    email,
    phone,
    postcode,
    certificates,
    preferredJobTypes,
    preferredMinSalary,
    preferredMaxSalary,
    maxTravelDistance,
    preferredCompanies,
    isAvailableWeekdays,
    isAvailableWeekends,
    isAvailableNights,
    availableFrom,
    bio,
    preferences,
    lastUpdated,
  ];
}

/// Application status enum
enum ApplicationStatus {
  pending,
  accepted,
  rejected,
  confirmed,
  withdrawn,
  inProgress,
  completed,
}

/// Application priority enum
enum ApplicationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Favorite job category enum
enum FavoriteCategory {
  general,
  urgent,
  highPay,
  nearLocation,
  preferredCompany,
  goodMatch,
  toApplyLater,
}