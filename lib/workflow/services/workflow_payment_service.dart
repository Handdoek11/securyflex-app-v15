import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../shared/services/encryption_service.dart';
import '../models/job_workflow_models.dart';

/// Service managing workflow state transitions with payment integration
/// Coordinates between job workflow states and payment processing
class WorkflowPaymentService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;

  // State transition mapping
  static const Map<JobWorkflowState, List<JobWorkflowState>> _allowedTransitions = {
    JobWorkflowState.posted: [JobWorkflowState.applied],
    JobWorkflowState.applied: [JobWorkflowState.underReview],
    JobWorkflowState.underReview: [JobWorkflowState.accepted, JobWorkflowState.posted], // rejected → repost
    JobWorkflowState.accepted: [JobWorkflowState.inProgress],
    JobWorkflowState.inProgress: [JobWorkflowState.completed],
    JobWorkflowState.completed: [JobWorkflowState.rated],
    JobWorkflowState.rated: [JobWorkflowState.paid],
    JobWorkflowState.paid: [JobWorkflowState.closed],
    JobWorkflowState.closed: [], // Terminal state
  };

  WorkflowPaymentService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EncryptionService? encryptionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _encryptionService = encryptionService ?? EncryptionService();

  /// Get real-time workflow status stream for a job
  Stream<JobWorkflowState> getWorkflowStatusStream(String jobId) {
    return _firestore
        .collection('job_workflows')
        .doc(jobId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return JobWorkflowState.posted; // Default state
      }
      
      final data = doc.data()!;
      final statusString = data['current_status'] as String;
      return JobWorkflowState.values.firstWhere(
        (status) => status.toString().split('.').last == statusString,
        orElse: () => JobWorkflowState.posted,
      );
    });
  }

  /// Update workflow status with validation and audit trail
  Future<WorkflowUpdateResult> updateWorkflowStatus(
    String jobId,
    JobWorkflowState newState, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 1. Get current workflow state
      final currentState = await _getCurrentWorkflowState(jobId);
      
      // 2. Validate state transition
      final transitionResult = _validateStateTransition(currentState, newState);
      if (!transitionResult.isValid) {
        return WorkflowUpdateResult.failed(
          reason: transitionResult.reason!,
          errorCode: 'INVALID_TRANSITION',
        );
      }

      // 3. Update workflow status with audit trail
      final batch = _firestore.batch();
      
      // Update main workflow document
      final workflowDoc = _firestore.collection('job_workflows').doc(jobId);
      batch.set(workflowDoc, {
        'job_id': jobId,
        'current_status': newState.toString().split('.').last,
        'previous_status': currentState.toString().split('.').last,
        'updated_at': Timestamp.now(),
        'updated_by': _auth.currentUser?.uid,
        'metadata': metadata ?? {},
      }, SetOptions(merge: true));

      // Add transition to audit trail
      final auditDoc = _firestore.collection('workflow_transitions').doc();
      batch.set(auditDoc, {
        'job_id': jobId,
        'from_status': currentState.toString().split('.').last,
        'to_status': newState.toString().split('.').last,
        'transitioned_by': _auth.currentUser?.uid,
        'transition_time': Timestamp.now(),
        'metadata': metadata ?? {},
      });

      // Update job document with new workflow status
      final jobDoc = _firestore.collection('jobs').doc(jobId);
      batch.update(jobDoc, {
        'workflow_status': newState.toString().split('.').last,
        'status_updated_at': Timestamp.now(),
      });

      await batch.commit();

      await _logWorkflowTransition(jobId, currentState, newState, metadata);

      return WorkflowUpdateResult.success(
        previousState: currentState,
        newState: newState,
        message: 'Workflow status bijgewerkt naar ${_getStateDutchLabel(newState)}',
      );

    } catch (e) {
      await _logWorkflowError(jobId, 'UPDATE_WORKFLOW_STATUS', e);
      return WorkflowUpdateResult.failed(
        reason: 'Fout bij bijwerken workflow status: $e',
        errorCode: 'UPDATE_ERROR',
      );
    }
  }

  /// Trigger payment processing for a completed job
  Future<PaymentTriggerResult> triggerPaymentProcess(String jobId) async {
    try {
      // 1. Verify job is in correct state for payment
      final currentState = await _getCurrentWorkflowState(jobId);
      if (currentState != JobWorkflowState.rated) {
        return PaymentTriggerResult.failed(
          reason: 'Job moet beoordeeld zijn voor betaling. Huidige status: ${_getStateDutchLabel(currentState)}',
        );
      }

      // 2. Check payment prerequisites
      final prerequisiteCheck = await _checkPaymentPrerequisites(jobId);
      if (!prerequisiteCheck.isValid) {
        return PaymentTriggerResult.failed(
          reason: prerequisiteCheck.reason!,
        );
      }

      // 3. Update status to payment processing
      await updateWorkflowStatus(
        jobId,
        JobWorkflowState.paid,
        metadata: {
          'payment_triggered': true,
          'payment_trigger_time': Timestamp.now().toDate().toIso8601String(),
        },
      );

      // 4. Create payment processing record
      await _createPaymentProcessingRecord(jobId);

      await _logWorkflowAction(
        'PAYMENT_PROCESSING_TRIGGERED',
        jobId,
        {'triggered_by': _auth.currentUser?.uid},
      );

      return PaymentTriggerResult.success(
        message: 'Betaling verwerking gestart voor job $jobId',
        paymentTriggered: true,
      );

    } catch (e) {
      await _logWorkflowError(jobId, 'TRIGGER_PAYMENT_PROCESS', e);
      return PaymentTriggerResult.failed(
        reason: 'Fout bij starten betaling: $e',
      );
    }
  }

  /// Get comprehensive workflow status including payment information
  Future<WorkflowStatusInfo> getWorkflowStatusInfo(String jobId) async {
    try {
      final workflowDoc = await _firestore
          .collection('job_workflows')
          .doc(jobId)
          .get();

      if (!workflowDoc.exists) {
        return WorkflowStatusInfo.notFound(jobId);
      }

      final workflowData = workflowDoc.data()!;
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobData = jobDoc.exists ? jobDoc.data()! : <String, dynamic>{};

      // Get payment information if applicable
      PaymentInfo? paymentInfo;
      final currentStatus = JobWorkflowState.values.firstWhere(
        (status) => status.toString().split('.').last == workflowData['current_status'],
        orElse: () => JobWorkflowState.posted,
      );

      if ([JobWorkflowState.paid, JobWorkflowState.closed].contains(currentStatus)) {
        paymentInfo = await _getPaymentInfo(jobId);
      }

      // Get rating information if applicable
      RatingInfo? ratingInfo;
      if ([
        JobWorkflowState.rated,
        JobWorkflowState.paid,
        JobWorkflowState.closed,
      ].contains(currentStatus)) {
        ratingInfo = await _getRatingInfo(jobId);
      }

      return WorkflowStatusInfo.success(
        jobId: jobId,
        currentStatus: currentStatus,
        previousStatus: JobWorkflowState.values.firstWhere(
          (status) => status.toString().split('.').last == (workflowData['previous_status'] ?? 'posted'),
          orElse: () => JobWorkflowState.posted,
        ),
        lastUpdated: (workflowData['updated_at'] as Timestamp).toDate(),
        guardId: jobData['assigned_guard_id'] as String?,
        companyId: jobData['company_id'] as String?,
        paymentInfo: paymentInfo,
        ratingInfo: ratingInfo,
        canTransitionTo: _getAllowedTransitions(currentStatus),
      );

    } catch (e) {
      await _logWorkflowError(jobId, 'GET_WORKFLOW_STATUS_INFO', e);
      return WorkflowStatusInfo.error(jobId, 'Fout bij ophalen workflow informatie: $e');
    }
  }

  /// Get workflow history for audit purposes
  Future<List<WorkflowTransition>> getWorkflowHistory(String jobId) async {
    try {
      final transitionsQuery = await _firestore
          .collection('workflow_transitions')
          .where('job_id', isEqualTo: jobId)
          .orderBy('transition_time', descending: false)
          .get();

      return transitionsQuery.docs.map((doc) {
        final data = doc.data();
        return WorkflowTransition(
          id: doc.id,
          jobId: jobId,
          fromStatus: JobWorkflowState.values.firstWhere(
            (status) => status.toString().split('.').last == data['from_status'],
            orElse: () => JobWorkflowState.posted,
          ),
          toStatus: JobWorkflowState.values.firstWhere(
            (status) => status.toString().split('.').last == data['to_status'],
            orElse: () => JobWorkflowState.posted,
          ),
          transitionedBy: data['transitioned_by'] as String?,
          transitionTime: (data['transition_time'] as Timestamp).toDate(),
          metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        );
      }).toList();

    } catch (e) {
      await _logWorkflowError(jobId, 'GET_WORKFLOW_HISTORY', e);
      return [];
    }
  }

  /// Get current workflow state from Firestore
  Future<JobWorkflowState> _getCurrentWorkflowState(String jobId) async {
    final doc = await _firestore.collection('job_workflows').doc(jobId).get();
    
    if (!doc.exists) {
      return JobWorkflowState.posted; // Default for new jobs
    }

    final statusString = doc.data()!['current_status'] as String;
    return JobWorkflowState.values.firstWhere(
      (status) => status.toString().split('.').last == statusString,
      orElse: () => JobWorkflowState.posted,
    );
  }

  /// Validate if state transition is allowed
  WorkflowTransitionValidation _validateStateTransition(
    JobWorkflowState from,
    JobWorkflowState to,
  ) {
    final allowedTransitions = _allowedTransitions[from] ?? [];
    
    if (allowedTransitions.contains(to)) {
      return WorkflowTransitionValidation.valid();
    } else {
      return WorkflowTransitionValidation.invalid(
        'Transitie van ${_getStateDutchLabel(from)} naar ${_getStateDutchLabel(to)} is niet toegestaan',
      );
    }
  }

  /// Check payment prerequisites before triggering payment
  Future<PaymentPrerequisiteCheck> _checkPaymentPrerequisites(String jobId) async {
    try {
      // 1. Check if both parties have rated
      final ratingDoc = await _firestore
          .collection('job_ratings_required')
          .doc(jobId)
          .get();

      if (!ratingDoc.exists) {
        return PaymentPrerequisiteCheck.invalid('Geen beoordeling vereisten gevonden');
      }

      final ratingData = ratingDoc.data()!;
      if (!(ratingData['guard_rated'] == true && ratingData['company_rated'] == true)) {
        return PaymentPrerequisiteCheck.invalid('Beide partijen moeten een beoordeling hebben gegeven');
      }

      // 2. Check if job completion data exists
      final completionDoc = await _firestore
          .collection('job_completions')
          .doc(jobId)
          .get();

      if (!completionDoc.exists) {
        return PaymentPrerequisiteCheck.invalid('Job voltooiing gegevens niet gevonden');
      }

      // 3. Check if guard has valid IBAN
      final completionData = completionDoc.data()!; // Simplified - no decryption needed
      final guardId = completionData['guard_id'] as String;
      
      final guardDoc = await _firestore.collection('users').doc(guardId).get();
      if (!guardDoc.exists || guardDoc.data()?['iban'] == null) {
        return PaymentPrerequisiteCheck.invalid('Beveiliger heeft geen geldig IBAN geregistreerd');
      }

      return PaymentPrerequisiteCheck.valid();

    } catch (e) {
      return PaymentPrerequisiteCheck.invalid('Fout bij controleren betalings voorwaarden: $e');
    }
  }

  /// Create payment processing record
  Future<void> _createPaymentProcessingRecord(String jobId) async {
    await _firestore.collection('payment_processing').doc(jobId).set({
      'job_id': jobId,
      'status': 'initiated',
      'initiated_at': Timestamp.now(),
      'initiated_by': _auth.currentUser?.uid,
      'processing_steps': {
        'workflow_status_updated': true,
        'invoice_generated': false,
        'payment_initiated': false,
        'payment_completed': false,
      },
    });
  }

  /// Get payment information for workflow status
  Future<PaymentInfo?> _getPaymentInfo(String jobId) async {
    try {
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (!jobDoc.exists) return null;

      final jobData = jobDoc.data()!;
      final paymentId = jobData['payment_id'] as String?;
      final invoiceId = jobData['invoice_id'] as String?;

      if (paymentId == null) return null;

      return PaymentInfo(
        paymentId: paymentId,
        invoiceId: invoiceId,
        paymentStatus: jobData['payment_status'] as String?,
        invoiceUrl: jobData['invoice_url'] as String?,
        paymentProcessedAt: jobData['payment_processed_at'] != null
            ? (jobData['payment_processed_at'] as Timestamp).toDate()
            : null,
      );

    } catch (e) {
      return null;
    }
  }

  /// Get rating information for workflow status
  Future<RatingInfo?> _getRatingInfo(String jobId) async {
    try {
      final ratingRequiredDoc = await _firestore
          .collection('job_ratings_required')
          .doc(jobId)
          .get();

      if (!ratingRequiredDoc.exists) return null;

      final ratingData = ratingRequiredDoc.data()!;
      
      return RatingInfo(
        guardRated: ratingData['guard_rated'] as bool? ?? false,
        companyRated: ratingData['company_rated'] as bool? ?? false,
        ratingDeadline: ratingData['rating_deadline'] != null
            ? (ratingData['rating_deadline'] as Timestamp).toDate()
            : null,
        lastUpdated: ratingData['last_updated'] != null
            ? (ratingData['last_updated'] as Timestamp).toDate()
            : null,
      );

    } catch (e) {
      return null;
    }
  }

  /// Get allowed transitions from current state
  List<JobWorkflowState> _getAllowedTransitions(JobWorkflowState currentState) {
    return _allowedTransitions[currentState] ?? [];
  }

  /// Get Dutch label for workflow state
  String _getStateDutchLabel(JobWorkflowState state) {
    switch (state) {
      case JobWorkflowState.posted:
        return 'Geplaatst';
      case JobWorkflowState.applied:
        return 'Aangemeld';
      case JobWorkflowState.underReview:
        return 'Onder beoordeling';
      case JobWorkflowState.accepted:
        return 'Geaccepteerd';
      case JobWorkflowState.inProgress:
        return 'Bezig';
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

  /// Get current workflow state for a job
  Future<JobWorkflowState> getCurrentWorkflowState(String jobId) async {
    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();
      if (!doc.exists) {
        throw Exception('Job not found: $jobId');
      }
      
      final data = doc.data()!;
      final stateString = data['workflow_status'] as String? ?? 'posted';
      
      return JobWorkflowState.values.firstWhere(
        (state) => state.toString().split('.').last == stateString,
        orElse: () => JobWorkflowState.posted,
      );
    } catch (e) {
      throw Exception('Failed to get workflow state for job $jobId: $e');
    }
  }

  /// Log workflow transitions for audit trail
  Future<void> _logWorkflowTransition(
    String jobId,
    JobWorkflowState fromState,
    JobWorkflowState toState,
    Map<String, dynamic>? metadata,
  ) async {
    await _firestore.collection('workflow_audit_log').add({
      'action': 'STATUS_TRANSITION',
      'job_id': jobId,
      'from_status': fromState.toString().split('.').last,
      'to_status': toState.toString().split('.').last,
      'user_id': _auth.currentUser?.uid,
      'timestamp': Timestamp.now(),
      'metadata': metadata ?? {},
    });
  }

  /// Log workflow actions for audit trail
  Future<void> _logWorkflowAction(
    String action,
    String jobId,
    Map<String, dynamic> metadata,
  ) async {
    await _firestore.collection('workflow_audit_log').add({
      'action': action,
      'job_id': jobId,
      'user_id': _auth.currentUser?.uid,
      'timestamp': Timestamp.now(),
      'metadata': metadata,
    });
  }

  /// Log workflow errors
  Future<void> _logWorkflowError(
    String jobId,
    String operation,
    dynamic error,
  ) async {
    await _firestore.collection('workflow_error_log').add({
      'job_id': jobId,
      'operation': operation,
      'error': error.toString(),
      'user_id': _auth.currentUser?.uid,
      'timestamp': Timestamp.now(),
    });
  }
}

/// Workflow update result
class WorkflowUpdateResult {
  final bool isSuccess;
  final JobWorkflowState? previousState;
  final JobWorkflowState? newState;
  final String message;
  final String? errorCode;

  const WorkflowUpdateResult({
    required this.isSuccess,
    this.previousState,
    this.newState,
    required this.message,
    this.errorCode,
  });

  factory WorkflowUpdateResult.success({
    required JobWorkflowState previousState,
    required JobWorkflowState newState,
    required String message,
  }) {
    return WorkflowUpdateResult(
      isSuccess: true,
      previousState: previousState,
      newState: newState,
      message: message,
    );
  }

  factory WorkflowUpdateResult.failed({
    required String reason,
    required String errorCode,
  }) {
    return WorkflowUpdateResult(
      isSuccess: false,
      message: reason,
      errorCode: errorCode,
    );
  }
}

/// Payment trigger result from workflow service
class PaymentTriggerResult {
  final bool isSuccess;
  final String message;
  final bool paymentTriggered;

  const PaymentTriggerResult({
    required this.isSuccess,
    required this.message,
    required this.paymentTriggered,
  });

  factory PaymentTriggerResult.success({
    required String message,
    required bool paymentTriggered,
  }) {
    return PaymentTriggerResult(
      isSuccess: true,
      message: message,
      paymentTriggered: paymentTriggered,
    );
  }

  factory PaymentTriggerResult.failed({
    required String reason,
  }) {
    return PaymentTriggerResult(
      isSuccess: false,
      message: reason,
      paymentTriggered: false,
    );
  }
}

/// Workflow transition validation result
class WorkflowTransitionValidation {
  final bool isValid;
  final String? reason;

  const WorkflowTransitionValidation({
    required this.isValid,
    this.reason,
  });

  factory WorkflowTransitionValidation.valid() {
    return const WorkflowTransitionValidation(isValid: true);
  }

  factory WorkflowTransitionValidation.invalid(String reason) {
    return WorkflowTransitionValidation(isValid: false, reason: reason);
  }
}

/// Payment prerequisite check result
class PaymentPrerequisiteCheck {
  final bool isValid;
  final String? reason;

  const PaymentPrerequisiteCheck({
    required this.isValid,
    this.reason,
  });

  factory PaymentPrerequisiteCheck.valid() {
    return const PaymentPrerequisiteCheck(isValid: true);
  }

  factory PaymentPrerequisiteCheck.invalid(String reason) {
    return PaymentPrerequisiteCheck(isValid: false, reason: reason);
  }
}

/// Comprehensive workflow status information
class WorkflowStatusInfo {
  final String jobId;
  final JobWorkflowState? currentStatus;
  final JobWorkflowState? previousStatus;
  final DateTime? lastUpdated;
  final String? guardId;
  final String? companyId;
  final PaymentInfo? paymentInfo;
  final RatingInfo? ratingInfo;
  final List<JobWorkflowState> canTransitionTo;
  final bool isError;
  final String? errorMessage;

  const WorkflowStatusInfo({
    required this.jobId,
    this.currentStatus,
    this.previousStatus,
    this.lastUpdated,
    this.guardId,
    this.companyId,
    this.paymentInfo,
    this.ratingInfo,
    this.canTransitionTo = const [],
    this.isError = false,
    this.errorMessage,
  });

  factory WorkflowStatusInfo.success({
    required String jobId,
    required JobWorkflowState currentStatus,
    JobWorkflowState? previousStatus,
    DateTime? lastUpdated,
    String? guardId,
    String? companyId,
    PaymentInfo? paymentInfo,
    RatingInfo? ratingInfo,
    List<JobWorkflowState> canTransitionTo = const [],
  }) {
    return WorkflowStatusInfo(
      jobId: jobId,
      currentStatus: currentStatus,
      previousStatus: previousStatus,
      lastUpdated: lastUpdated,
      guardId: guardId,
      companyId: companyId,
      paymentInfo: paymentInfo,
      ratingInfo: ratingInfo,
      canTransitionTo: canTransitionTo,
    );
  }

  factory WorkflowStatusInfo.notFound(String jobId) {
    return WorkflowStatusInfo(
      jobId: jobId,
      isError: true,
      errorMessage: 'Workflow niet gevonden',
    );
  }

  factory WorkflowStatusInfo.error(String jobId, String errorMessage) {
    return WorkflowStatusInfo(
      jobId: jobId,
      isError: true,
      errorMessage: errorMessage,
    );
  }
}

/// Payment information for workflow status
class PaymentInfo {
  final String paymentId;
  final String? invoiceId;
  final String? paymentStatus;
  final String? invoiceUrl;
  final DateTime? paymentProcessedAt;

  const PaymentInfo({
    required this.paymentId,
    this.invoiceId,
    this.paymentStatus,
    this.invoiceUrl,
    this.paymentProcessedAt,
  });
}

/// Rating information for workflow status
class RatingInfo {
  final bool guardRated;
  final bool companyRated;
  final DateTime? ratingDeadline;
  final DateTime? lastUpdated;

  const RatingInfo({
    required this.guardRated,
    required this.companyRated,
    this.ratingDeadline,
    this.lastUpdated,
  });

  bool get bothRated => guardRated && companyRated;
  bool get isOverdue => ratingDeadline != null && DateTime.now().isAfter(ratingDeadline!);
}

/// Workflow transition record
class WorkflowTransition {
  final String id;
  final String jobId;
  final JobWorkflowState fromStatus;
  final JobWorkflowState toStatus;
  final String? transitionedBy;
  final DateTime transitionTime;
  final Map<String, dynamic> metadata;

  const WorkflowTransition({
    required this.id,
    required this.jobId,
    required this.fromStatus,
    required this.toStatus,
    this.transitionedBy,
    required this.transitionTime,
    this.metadata = const {},
  });
}