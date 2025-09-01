import 'package:cloud_firestore/cloud_firestore.dart';

/// Rater type for job completion ratings
enum RaterType {
  guard,
  company,
}

/// Dutch Security Job Workflow States following Dutch business practices
enum JobWorkflowState {
  /// Job is live and searchable on the marketplace
  posted,
  
  /// Applications have been received from guards
  applied,
  
  /// Company is reviewing applications
  underReview,
  
  /// Application accepted, guard notified, chat created
  accepted,
  
  /// Job is active, guard is working, real-time communication
  inProgress,
  
  /// Job completed, awaiting reviews and payment
  completed,
  
  /// Both parties have rated each other
  rated,
  
  /// Payment has been processed via SEPA
  paid,
  
  /// Workflow complete, archived
  closed,
  
  /// Job was cancelled (with reason)
  cancelled,
}

/// Job Workflow State Extensions for Dutch Localization
extension JobWorkflowStateExtension on JobWorkflowState {
  /// Dutch display name
  String get displayNameNL {
    switch (this) {
      case JobWorkflowState.posted:
        return 'Gepubliceerd';
      case JobWorkflowState.applied:
        return 'Sollicitaties Ontvangen';
      case JobWorkflowState.underReview:
        return 'In Beoordeling';
      case JobWorkflowState.accepted:
        return 'Geaccepteerd';
      case JobWorkflowState.inProgress:
        return 'In Uitvoering';
      case JobWorkflowState.completed:
        return 'Voltooid';
      case JobWorkflowState.rated:
        return 'Beoordeeld';
      case JobWorkflowState.paid:
        return 'Betaald';
      case JobWorkflowState.closed:
        return 'Afgesloten';
      case JobWorkflowState.cancelled:
        return 'Geannuleerd';
    }
  }
  
  /// Status color for UI theming
  String get statusColor {
    switch (this) {
      case JobWorkflowState.posted:
        return '#2196F3'; // Blue
      case JobWorkflowState.applied:
        return '#FF9800'; // Orange
      case JobWorkflowState.underReview:
        return '#9C27B0'; // Purple
      case JobWorkflowState.accepted:
        return '#4CAF50'; // Green
      case JobWorkflowState.inProgress:
        return '#00BCD4'; // Cyan
      case JobWorkflowState.completed:
        return '#8BC34A'; // Light Green
      case JobWorkflowState.rated:
        return '#CDDC39'; // Lime
      case JobWorkflowState.paid:
        return '#4CAF50'; // Green
      case JobWorkflowState.closed:
        return '#9E9E9E'; // Grey
      case JobWorkflowState.cancelled:
        return '#F44336'; // Red
    }
  }
  
  /// Check if state allows user actions
  bool get isActionable {
    return this == JobWorkflowState.applied ||
           this == JobWorkflowState.accepted ||
           this == JobWorkflowState.inProgress ||
           this == JobWorkflowState.completed;
  }
  
  /// Check if workflow is active (not finished)
  bool get isActive {
    return this != JobWorkflowState.closed && 
           this != JobWorkflowState.cancelled;
  }
}

/// Complete Job Workflow Model
class JobWorkflow {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyId;
  final String companyName;
  final String? selectedGuardId;
  final String? selectedGuardName;
  final JobWorkflowState currentState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? conversationId;
  final Map<String, WorkflowTransition> transitions;
  final List<WorkflowNotification> notifications;
  final WorkflowMetadata metadata;
  final ComplianceData complianceData;
  
  const JobWorkflow({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyId,
    required this.companyName,
    this.selectedGuardId,
    this.selectedGuardName,
    required this.currentState,
    required this.createdAt,
    required this.updatedAt,
    this.conversationId,
    required this.transitions,
    required this.notifications,
    required this.metadata,
    required this.complianceData,
  });
  
  /// Create from Firestore document
  factory JobWorkflow.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return JobWorkflow(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      selectedGuardId: data['selectedGuardId'],
      selectedGuardName: data['selectedGuardName'],
      currentState: JobWorkflowState.values.firstWhere(
        (state) => state.toString().split('.').last == data['currentState'],
        orElse: () => JobWorkflowState.posted,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      conversationId: data['conversationId'],
      transitions: _parseTransitions(data['transitions'] ?? {}),
      notifications: _parseNotifications(data['notifications'] ?? []),
      metadata: WorkflowMetadata.fromMap(data['metadata'] ?? {}),
      complianceData: ComplianceData.fromMap(data['complianceData'] ?? {}),
    );
  }
  
  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'companyId': companyId,
      'companyName': companyName,
      'selectedGuardId': selectedGuardId,
      'selectedGuardName': selectedGuardName,
      'currentState': currentState.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'conversationId': conversationId,
      'transitions': _transitionsToMap(transitions),
      'notifications': notifications.map((n) => n.toMap()).toList(),
      'metadata': metadata.toMap(),
      'complianceData': complianceData.toMap(),
    };
  }
  
  /// Create copy with updated fields
  JobWorkflow copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? companyId,
    String? companyName,
    String? selectedGuardId,
    String? selectedGuardName,
    JobWorkflowState? currentState,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? conversationId,
    Map<String, WorkflowTransition>? transitions,
    List<WorkflowNotification>? notifications,
    WorkflowMetadata? metadata,
    ComplianceData? complianceData,
  }) {
    return JobWorkflow(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      selectedGuardId: selectedGuardId ?? this.selectedGuardId,
      selectedGuardName: selectedGuardName ?? this.selectedGuardName,
      currentState: currentState ?? this.currentState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      conversationId: conversationId ?? this.conversationId,
      transitions: transitions ?? this.transitions,
      notifications: notifications ?? this.notifications,
      metadata: metadata ?? this.metadata,
      complianceData: complianceData ?? this.complianceData,
    );
  }
  
  /// Parse transitions from Firestore data
  static Map<String, WorkflowTransition> _parseTransitions(Map<String, dynamic> data) {
    final transitions = <String, WorkflowTransition>{};
    data.forEach((key, value) {
      transitions[key] = WorkflowTransition.fromMap(value);
    });
    return transitions;
  }
  
  /// Parse notifications from Firestore data
  static List<WorkflowNotification> _parseNotifications(List<dynamic> data) {
    return data.map((item) => WorkflowNotification.fromMap(item)).toList();
  }
  
  /// Convert transitions to Firestore map
  static Map<String, dynamic> _transitionsToMap(Map<String, WorkflowTransition> transitions) {
    final result = <String, dynamic>{};
    transitions.forEach((key, value) {
      result[key] = value.toMap();
    });
    return result;
  }
}

/// Workflow State Transition
class WorkflowTransition {
  final JobWorkflowState fromState;
  final JobWorkflowState toState;
  final DateTime transitionedAt;
  final String transitionedBy;
  final String? reason;
  final Map<String, dynamic> metadata;
  
  const WorkflowTransition({
    required this.fromState,
    required this.toState,
    required this.transitionedAt,
    required this.transitionedBy,
    this.reason,
    required this.metadata,
  });
  
  factory WorkflowTransition.fromMap(Map<String, dynamic> data) {
    return WorkflowTransition(
      fromState: JobWorkflowState.values.firstWhere(
        (state) => state.toString().split('.').last == data['fromState'],
      ),
      toState: JobWorkflowState.values.firstWhere(
        (state) => state.toString().split('.').last == data['toState'],
      ),
      transitionedAt: (data['transitionedAt'] as Timestamp).toDate(),
      transitionedBy: data['transitionedBy'] ?? '',
      reason: data['reason'],
      metadata: data['metadata'] ?? {},
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'fromState': fromState.toString().split('.').last,
      'toState': toState.toString().split('.').last,
      'transitionedAt': Timestamp.fromDate(transitionedAt),
      'transitionedBy': transitionedBy,
      'reason': reason,
      'metadata': metadata,
    };
  }
}

/// Workflow Notification
class WorkflowNotification {
  final String id;
  final String recipientId;
  final String recipientRole; // 'guard', 'company'
  final String title;
  final String message;
  final DateTime sentAt;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic> data;
  
  const WorkflowNotification({
    required this.id,
    required this.recipientId,
    required this.recipientRole,
    required this.title,
    required this.message,
    required this.sentAt,
    required this.isRead,
    this.actionUrl,
    required this.data,
  });
  
  factory WorkflowNotification.fromMap(Map<String, dynamic> data) {
    return WorkflowNotification(
      id: data['id'] ?? '',
      recipientId: data['recipientId'] ?? '',
      recipientRole: data['recipientRole'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      actionUrl: data['actionUrl'],
      data: data['data'] ?? {},
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipientId': recipientId,
      'recipientRole': recipientRole,
      'title': title,
      'message': message,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
      'actionUrl': actionUrl,
      'data': data,
    };
  }
}

/// Workflow Metadata
class WorkflowMetadata {
  final double? agreedHourlyRate;
  final int? estimatedHours;
  final DateTime? scheduledStartTime;
  final DateTime? scheduledEndTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final String? location;
  final List<String> requiredCertificates;
  final Map<String, dynamic> customFields;
  
  const WorkflowMetadata({
    this.agreedHourlyRate,
    this.estimatedHours,
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.actualStartTime,
    this.actualEndTime,
    this.location,
    required this.requiredCertificates,
    required this.customFields,
  });
  
  factory WorkflowMetadata.fromMap(Map<String, dynamic> data) {
    return WorkflowMetadata(
      agreedHourlyRate: data['agreedHourlyRate']?.toDouble(),
      estimatedHours: data['estimatedHours'],
      scheduledStartTime: (data['scheduledStartTime'] as Timestamp?)?.toDate(),
      scheduledEndTime: (data['scheduledEndTime'] as Timestamp?)?.toDate(),
      actualStartTime: (data['actualStartTime'] as Timestamp?)?.toDate(),
      actualEndTime: (data['actualEndTime'] as Timestamp?)?.toDate(),
      location: data['location'],
      requiredCertificates: List<String>.from(data['requiredCertificates'] ?? []),
      customFields: data['customFields'] ?? {},
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'agreedHourlyRate': agreedHourlyRate,
      'estimatedHours': estimatedHours,
      'scheduledStartTime': scheduledStartTime != null ? Timestamp.fromDate(scheduledStartTime!) : null,
      'scheduledEndTime': scheduledEndTime != null ? Timestamp.fromDate(scheduledEndTime!) : null,
      'actualStartTime': actualStartTime != null ? Timestamp.fromDate(actualStartTime!) : null,
      'actualEndTime': actualEndTime != null ? Timestamp.fromDate(actualEndTime!) : null,
      'location': location,
      'requiredCertificates': requiredCertificates,
      'customFields': customFields,
    };
  }
}

/// Dutch Business Compliance Data
class ComplianceData {
  final bool kvkVerified;
  final bool wpbrVerified;
  final bool caoCompliant;
  final double btwRate;
  final bool gdprConsentGiven;
  final List<String> auditTrail;
  final Map<String, dynamic> taxData;
  
  const ComplianceData({
    required this.kvkVerified,
    required this.wpbrVerified,
    required this.caoCompliant,
    required this.btwRate,
    required this.gdprConsentGiven,
    required this.auditTrail,
    required this.taxData,
  });
  
  factory ComplianceData.fromMap(Map<String, dynamic> data) {
    return ComplianceData(
      kvkVerified: data['kvkVerified'] ?? false,
      wpbrVerified: data['wpbrVerified'] ?? false,
      caoCompliant: data['caoCompliant'] ?? false,
      btwRate: (data['btwRate'] ?? 0.21).toDouble(),
      gdprConsentGiven: data['gdprConsentGiven'] ?? false,
      auditTrail: List<String>.from(data['auditTrail'] ?? []),
      taxData: data['taxData'] ?? {},
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'kvkVerified': kvkVerified,
      'wpbrVerified': wpbrVerified,
      'caoCompliant': caoCompliant,
      'btwRate': btwRate,
      'gdprConsentGiven': gdprConsentGiven,
      'auditTrail': auditTrail,
      'taxData': taxData,
    };
  }
}

/// Job Review/Rating Model
class JobReview {
  final String id;
  final String workflowId;
  final String reviewerId;
  final String reviewerRole; // 'guard' or 'company'
  final double rating; // 1.0 to 5.0
  final String? comment;
  final List<String> positiveAspects;
  final List<String> improvementAreas;
  final DateTime createdAt;
  final bool isVisible;
  final Map<String, dynamic> metadata;
  
  const JobReview({
    required this.id,
    required this.workflowId,
    required this.reviewerId,
    required this.reviewerRole,
    required this.rating,
    this.comment,
    required this.positiveAspects,
    required this.improvementAreas,
    required this.createdAt,
    required this.isVisible,
    required this.metadata,
  });
  
  factory JobReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return JobReview(
      id: doc.id,
      workflowId: data['workflowId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewerRole: data['reviewerRole'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'],
      positiveAspects: List<String>.from(data['positiveAspects'] ?? []),
      improvementAreas: List<String>.from(data['improvementAreas'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVisible: data['isVisible'] ?? true,
      metadata: data['metadata'] ?? {},
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'workflowId': workflowId,
      'reviewerId': reviewerId,
      'reviewerRole': reviewerRole,
      'rating': rating,
      'comment': comment,
      'positiveAspects': positiveAspects,
      'improvementAreas': improvementAreas,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVisible': isVisible,
      'metadata': metadata,
    };
  }

  /// Create JobReview for job completion rating
  factory JobReview.forJobCompletion({
    required String workflowId,
    required String reviewerId,
    required String reviewerRole,
    required double rating,
    String? comment,
  }) {
    return JobReview(
      id: 'review_${DateTime.now().millisecondsSinceEpoch}',
      workflowId: workflowId,
      reviewerId: reviewerId,
      reviewerRole: reviewerRole,
      rating: rating,
      comment: comment,
      positiveAspects: [],
      improvementAreas: [],
      createdAt: DateTime.now(),
      isVisible: true,
      metadata: {
        'type': 'job_completion',
        'source': 'mobile_app',
      },
    );
  }

  /// Get Dutch rating description following existing patterns from ProfileStatsWidget
  String get dutchRatingDescription {
    if (rating >= 4.5) return 'Uitstekend';
    if (rating >= 4.0) return 'Goed';
    if (rating >= 3.5) return 'Voldoende';
    if (rating >= 2.0) return 'Matig';
    return 'Onvoldoende';
  }

  /// Get rating color following existing patterns from ProfileStatsWidget
  String get ratingColorHex {
    if (rating >= 4.5) return '#4CAF50'; // Green - statusCompleted
    if (rating >= 4.0) return '#FF9800'; // Orange - statusPending
    if (rating >= 3.5) return '#2196F3'; // Blue - guardPrimary
    return '#F44336'; // Red - colorError
  }

  /// Check if this is a job completion rating
  bool get isJobCompletionRating {
    return metadata['type'] == 'job_completion';
  }

  /// Create copy with updated values
  JobReview copyWith({
    String? id,
    String? workflowId,
    String? reviewerId,
    String? reviewerRole,
    double? rating,
    String? comment,
    List<String>? positiveAspects,
    List<String>? improvementAreas,
    DateTime? createdAt,
    bool? isVisible,
    Map<String, dynamic>? metadata,
  }) {
    return JobReview(
      id: id ?? this.id,
      workflowId: workflowId ?? this.workflowId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerRole: reviewerRole ?? this.reviewerRole,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      positiveAspects: positiveAspects ?? this.positiveAspects,
      improvementAreas: improvementAreas ?? this.improvementAreas,
      createdAt: createdAt ?? this.createdAt,
      isVisible: isVisible ?? this.isVisible,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Workflow Events for BLoC Pattern
abstract class WorkflowEvent {}

class InitiateWorkflow extends WorkflowEvent {
  final String jobId;
  final String companyId;
  
  InitiateWorkflow({required this.jobId, required this.companyId});
}

class ProcessApplication extends WorkflowEvent {
  final String workflowId;
  final String applicationId;
  final bool isAccepted;
  final String? reason;
  
  ProcessApplication({
    required this.workflowId,
    required this.applicationId,
    required this.isAccepted,
    this.reason,
  });
}

class StartJob extends WorkflowEvent {
  final String workflowId;
  final String guardId;
  final DateTime startTime;
  
  StartJob({
    required this.workflowId,
    required this.guardId,
    required this.startTime,
  });
}

class CompleteJob extends WorkflowEvent {
  final String workflowId;
  final DateTime completionTime;
  final Map<String, dynamic> completionData;
  
  CompleteJob({
    required this.workflowId,
    required this.completionTime,
    required this.completionData,
  });
}

class SubmitReview extends WorkflowEvent {
  final String workflowId;
  final JobReview review;
  
  SubmitReview({
    required this.workflowId,
    required this.review,
  });
}

class ProcessPayment extends WorkflowEvent {
  final String workflowId;
  final double amount;
  final Map<String, dynamic> paymentData;
  
  ProcessPayment({
    required this.workflowId,
    required this.amount,
    required this.paymentData,
  });
}

class CancelWorkflow extends WorkflowEvent {
  final String workflowId;
  final String reason;
  final String cancelledBy;
  
  CancelWorkflow({
    required this.workflowId,
    required this.reason,
    required this.cancelledBy,
  });
}

class UpdateWorkflowState extends WorkflowEvent {
  final String workflowId;
  final JobWorkflowState newState;
  final String? reason;
  final Map<String, dynamic>? metadata;
  
  UpdateWorkflowState({
    required this.workflowId,
    required this.newState,
    this.reason,
    this.metadata,
  });
}

/// Workflow States for BLoC Pattern
abstract class WorkflowState {}

class WorkflowInitial extends WorkflowState {}

class WorkflowLoading extends WorkflowState {
  final String message;
  WorkflowLoading({required this.message});
}

class WorkflowLoaded extends WorkflowState {
  final JobWorkflow workflow;
  WorkflowLoaded({required this.workflow});
}

class WorkflowUpdated extends WorkflowState {
  final JobWorkflow workflow;
  final String message;
  WorkflowUpdated({required this.workflow, required this.message});
}

class WorkflowError extends WorkflowState {
  final String error;
  final String? details;
  WorkflowError({required this.error, this.details});
}

class WorkflowTransitioned extends WorkflowState {
  final JobWorkflow workflow;
  final JobWorkflowState fromState;
  final JobWorkflowState toState;
  final String message;
  
  WorkflowTransitioned({
    required this.workflow,
    required this.fromState,
    required this.toState,
    required this.message,
  });
}

class WorkflowCompleted extends WorkflowState {
  final JobWorkflow workflow;
  final String message;
  
  WorkflowCompleted({
    required this.workflow,
    required this.message,
  });
}