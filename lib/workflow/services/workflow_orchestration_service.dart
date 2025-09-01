import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// import '../../core/error/exceptions.dart'; // TODO: Add back when needed
import '../../shared/services/encryption_service.dart';
import '../../services/notification_badge_service.dart';
import '../../marketplace/repository/job_repository.dart';
import '../../marketplace/services/application_service.dart';
import '../../chat/services/auto_chat_service.dart';
import '../../auth/services/kvk_api_service.dart';
// import '../../auth/services/wpbr_verification_service.dart'; // TODO: Implement WPBR service
// import '../../auth/services/security_audit_service.dart'; // TODO: Fix audit service integration
import '../models/job_workflow_models.dart';
import 'job_completion_payment_orchestrator.dart';

/// Central WorkflowOrchestrationService for SecuryFlex
/// Manages complete end-to-end job workflows from posting to payment
/// Implements Dutch business compliance and security requirements
class WorkflowOrchestrationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;
  final NotificationBadgeService _notificationService;
  final JobRepository _jobRepository;
  final ApplicationService _applicationService;
  final KvKApiService _kvkService;
  final dynamic _wpbrService; // TODO: Replace with actual WpbrVerificationService
  // final SecurityAuditService _auditService; // TODO: Fix audit service integration
  final JobCompletionPaymentOrchestrator _paymentOrchestrator;
  final AutoChatService _chatService;

  // Dutch business constants
  static const double _minimumHourlyRate = 12.00; // CAO minimum 2024
  static const double _btwRate = 0.21; // 21% BTW
  static const int _defaultRatingWindowDays = 7;
  static const int _contractExpiryNotificationDays = 30;

  // State machine transitions map
  static final Map<JobWorkflowState, List<JobWorkflowState>> _validTransitions = {
    JobWorkflowState.posted: [JobWorkflowState.applied, JobWorkflowState.cancelled],
    JobWorkflowState.applied: [JobWorkflowState.underReview, JobWorkflowState.cancelled],
    JobWorkflowState.underReview: [JobWorkflowState.accepted, JobWorkflowState.cancelled],
    JobWorkflowState.accepted: [JobWorkflowState.inProgress, JobWorkflowState.cancelled],
    JobWorkflowState.inProgress: [JobWorkflowState.completed, JobWorkflowState.cancelled],
    JobWorkflowState.completed: [JobWorkflowState.rated, JobWorkflowState.cancelled],
    JobWorkflowState.rated: [JobWorkflowState.paid],
    JobWorkflowState.paid: [JobWorkflowState.closed],
    JobWorkflowState.closed: [], // Terminal state
    JobWorkflowState.cancelled: [], // Terminal state
  };

  WorkflowOrchestrationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EncryptionService? encryptionService,
    NotificationBadgeService? notificationService,
    JobRepository? jobRepository,
    ApplicationService? applicationService,
    KvKApiService? kvkService,
    dynamic wpbrService, // TODO: Replace with actual WpbrVerificationService type
    // SecurityAuditService? auditService, // TODO: Fix audit service integration
    JobCompletionPaymentOrchestrator? paymentOrchestrator,
    AutoChatService? chatService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _encryptionService = encryptionService ?? EncryptionService(),
        _notificationService = notificationService ?? NotificationBadgeService.instance,
        _jobRepository = jobRepository ?? _createDefaultJobRepository(),
        _applicationService = applicationService ?? ApplicationService(),
        _kvkService = kvkService ?? KvKApiService(),
        _wpbrService = wpbrService ?? _createMockWpbrService(),
        // _auditService = auditService ?? SecurityAuditService(), // TODO: Fix audit service integration
        _paymentOrchestrator = paymentOrchestrator ?? JobCompletionPaymentOrchestrator(),
        _chatService = chatService ?? AutoChatService();

  // Helper methods for creating default services
  static JobRepository _createDefaultJobRepository() {
    throw UnimplementedError('JobRepository must be provided');
  }

  static dynamic _createMockWpbrService() {
    return MockWpbrService();
  }

  /// Initialize a new job workflow when a job is posted
  Future<WorkflowOrchestrationResult> initiateJobWorkflow({
    required String jobId,
    required String companyId,
    required String jobTitle,
    required double hourlyRate,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate company compliance first
      final complianceResult = await _validateCompanyCompliance(companyId);
      if (!complianceResult.isValid) {
        return WorkflowOrchestrationResult.failure(
          error: 'Company compliance validation failed: ${complianceResult.reason}',
          errorCode: 'COMPLIANCE_FAILED',
        );
      }

      // Validate hourly rate meets CAO minimum
      if (hourlyRate < _minimumHourlyRate) {
        return WorkflowOrchestrationResult.failure(
          error: 'Uurloon €${hourlyRate.toStringAsFixed(2)} voldoet niet aan CAO minimum van €${_minimumHourlyRate.toStringAsFixed(2)}',
          errorCode: 'HOURLY_RATE_TOO_LOW',
        );
      }

      // Create workflow document
      final workflow = JobWorkflow(
        id: jobId,
        jobId: jobId,
        jobTitle: jobTitle,
        companyId: companyId,
        companyName: complianceResult.companyName ?? 'Unknown Company',
        currentState: JobWorkflowState.posted,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        transitions: {},
        notifications: [],
        metadata: WorkflowMetadata(
          agreedHourlyRate: hourlyRate,
          requiredCertificates: metadata?['requiredCertificates'] ?? [],
          customFields: metadata ?? {},
        ),
        complianceData: ComplianceData(
          kvkVerified: complianceResult.kvkVerified,
          wpbrVerified: false, // Will be verified when guard applies
          caoCompliant: hourlyRate >= _minimumHourlyRate,
          btwRate: _btwRate,
          gdprConsentGiven: true,
          auditTrail: ['Workflow initiated'],
          taxData: {'hourlyRate': hourlyRate, 'btwRate': _btwRate},
        ),
      );

      // Store workflow in Firestore
      await _firestore
          .collection('workflows')
          .doc(jobId)
          .set(workflow.toFirestore());

      // Log audit trail
      // TODO: Fix audit logging for workflow initiated event

      // Update notification badges
      await _notificationService.updateJobBadges(newJobs: 1);

      return WorkflowOrchestrationResult.success(
        workflow: workflow,
        message: 'Job workflow geïnitialiseerd voor "$jobTitle"',
      );

    } catch (e) {
      // TODO: Fix audit logging for workflow initiation failure

      return WorkflowOrchestrationResult.failure(
        error: 'Fout bij initialiseren workflow: $e',
        errorCode: 'INITIALIZATION_ERROR',
      );
    }
  }

  /// Process a job application and update workflow state
  Future<WorkflowOrchestrationResult> processJobApplication({
    required String workflowId,
    required String guardId,
    required String guardName,
    required String motivationMessage,
    required Map<String, dynamic> applicationData,
  }) async {
    try {
      // Get existing workflow
      final workflowDoc = await _firestore
          .collection('workflows')
          .doc(workflowId)
          .get();

      if (!workflowDoc.exists) {
        return WorkflowOrchestrationResult.failure(
          error: 'Workflow niet gevonden',
          errorCode: 'WORKFLOW_NOT_FOUND',
        );
      }

      final workflow = JobWorkflow.fromFirestore(workflowDoc);

      // Validate guard compliance
      final guardComplianceResult = await _validateGuardCompliance(guardId);
      if (!guardComplianceResult.isValid) {
        return WorkflowOrchestrationResult.failure(
          error: 'Beveiliger compliance validatie gefaald: ${guardComplianceResult.reason}',
          errorCode: 'GUARD_COMPLIANCE_FAILED',
        );
      }

      // Transition to applied state if currently posted
      if (workflow.currentState == JobWorkflowState.posted) {
        final transitionResult = await _transitionWorkflowState(
          workflow: workflow,
          newState: JobWorkflowState.applied,
          triggeredBy: guardId,
          reason: 'Guard application received',
          metadata: {
            'guardId': guardId,
            'guardName': guardName,
            'applicationData': applicationData,
          },
        );

        if (!transitionResult.isSuccess) {
          return transitionResult;
        }

        // Update workflow with guard information
        final updatedWorkflow = transitionResult.workflow!.copyWith(
          selectedGuardId: guardId,
          selectedGuardName: guardName,
          complianceData: workflow.complianceData.copyWith(
            wpbrVerified: guardComplianceResult.wpbrVerified,
          ),
        );

        await _firestore
            .collection('workflows')
            .doc(workflowId)
            .update(updatedWorkflow.toFirestore());

        // Send notification to company
        await _sendWorkflowNotification(
          recipientId: workflow.companyId,
          recipientRole: 'company',
          title: 'Nieuwe Sollicitatie Ontvangen',
          message: '$guardName heeft gesolliciteerd op "${workflow.jobTitle}"',
          workflowId: workflowId,
          notificationType: WorkflowNotificationType.applicationReceived,
        );

        // Update notification badges
        await _notificationService.updateJobBadges(newApplications: 1);

        // Automatically transition to under review
        return await _transitionWorkflowState(
          workflow: updatedWorkflow,
          newState: JobWorkflowState.underReview,
          triggeredBy: workflow.companyId,
          reason: 'Application under review',
          metadata: {'autoTransition': true},
        );
      }

      return WorkflowOrchestrationResult.failure(
        error: 'Workflow is niet in juiste status voor sollicitatie',
        errorCode: 'INVALID_STATE_FOR_APPLICATION',
      );

    } catch (e) {
      // TODO: Fix audit logging for application processing failure

      return WorkflowOrchestrationResult.failure(
        error: 'Fout bij verwerken sollicitatie: $e',
        errorCode: 'APPLICATION_PROCESSING_ERROR',
      );
    }
  }

  /// Accept an application and create communication thread
  Future<WorkflowOrchestrationResult> acceptApplication({
    required String workflowId,
    required String companyId,
    required String acceptanceMessage,
    DateTime? scheduledStartTime,
    Map<String, dynamic>? contractTerms,
  }) async {
    try {
      final workflow = await _getWorkflow(workflowId);
      if (workflow == null) {
        return WorkflowOrchestrationResult.failure(
          error: 'Workflow niet gevonden',
          errorCode: 'WORKFLOW_NOT_FOUND',
        );
      }

      // Validate state transition
      if (workflow.currentState != JobWorkflowState.underReview) {
        return WorkflowOrchestrationResult.failure(
          error: 'Workflow is niet in status voor acceptatie',
          errorCode: 'INVALID_STATE_FOR_ACCEPTANCE',
        );
      }

      // Transition to accepted state
      final transitionResult = await _transitionWorkflowState(
        workflow: workflow,
        newState: JobWorkflowState.accepted,
        triggeredBy: companyId,
        reason: 'Application accepted by company',
        metadata: {
          'acceptanceMessage': acceptanceMessage,
          'scheduledStartTime': scheduledStartTime?.toIso8601String(),
          'contractTerms': contractTerms,
        },
      );

      if (!transitionResult.isSuccess) {
        return transitionResult;
      }

      final acceptedWorkflow = transitionResult.workflow!;

      // Create communication thread between guard and company
      final chatResult = await _createCommunicationThread(
        workflowId: workflowId,
        guardId: workflow.selectedGuardId!,
        guardName: workflow.selectedGuardName!,
        companyId: companyId,
        companyName: workflow.companyName,
        jobTitle: workflow.jobTitle,
        initialMessage: acceptanceMessage,
      );

      if (!chatResult.isSuccess) {
        // Log warning but don't fail the acceptance
        debugPrint('Warning: Failed to create chat thread: ${chatResult.error}');
      }

      // Update workflow with conversation ID
      final finalWorkflow = acceptedWorkflow.copyWith(
        conversationId: chatResult.conversationId,
        metadata: acceptedWorkflow.metadata.copyWith(
          scheduledStartTime: scheduledStartTime,
          customFields: {
            ...acceptedWorkflow.metadata.customFields,
            'acceptanceMessage': acceptanceMessage,
            if (contractTerms != null) 'contractTerms': contractTerms,
          },
        ),
      );

      await _firestore
          .collection('workflows')
          .doc(workflowId)
          .update(finalWorkflow.toFirestore());

      // Send notifications to guard
      await _sendWorkflowNotification(
        recipientId: workflow.selectedGuardId!,
        recipientRole: 'guard',
        title: 'Sollicitatie Geaccepteerd!',
        message: 'Je sollicitatie voor "${workflow.jobTitle}" is geaccepteerd door ${workflow.companyName}',
        workflowId: workflowId,
        notificationType: WorkflowNotificationType.applicationAccepted,
        actionData: {
          'conversationId': chatResult.conversationId,
          'scheduledStartTime': scheduledStartTime?.toIso8601String(),
        },
      );

      // Update notification badges
      await _notificationService.updateJobBadges(applicationUpdates: 1);

      return WorkflowOrchestrationResult.success(
        workflow: finalWorkflow,
        message: 'Sollicitatie geaccepteerd en communicatie gestart',
      );

    } catch (e) {
      // TODO: Fix audit logging for application acceptance failure

      return WorkflowOrchestrationResult.failure(
        error: 'Fout bij accepteren sollicitatie: $e',
        errorCode: 'ACCEPTANCE_ERROR',
      );
    }
  }

  /// Start job execution (transition to in_progress)
  Future<WorkflowOrchestrationResult> startJobExecution({
    required String workflowId,
    required String guardId,
    required DateTime actualStartTime,
    Map<String, dynamic>? startMetadata,
  }) async {
    try {
      final workflow = await _getWorkflow(workflowId);
      if (workflow == null) {
        return WorkflowOrchestrationResult.failure(
          error: 'Workflow niet gevonden',
          errorCode: 'WORKFLOW_NOT_FOUND',
        );
      }

      // Validate authorization - only assigned guard can start
      if (workflow.selectedGuardId != guardId) {
        return WorkflowOrchestrationResult.failure(
          error: 'Alleen toegewezen beveiliger kan opdracht starten',
          errorCode: 'UNAUTHORIZED_START',
        );
      }

      // Validate state transition
      if (workflow.currentState != JobWorkflowState.accepted) {
        return WorkflowOrchestrationResult.failure(
          error: 'Opdracht is niet gereed voor uitvoering',
          errorCode: 'INVALID_STATE_FOR_START',
        );
      }

      // Transition to in progress
      final transitionResult = await _transitionWorkflowState(
        workflow: workflow,
        newState: JobWorkflowState.inProgress,
        triggeredBy: guardId,
        reason: 'Job execution started by guard',
        metadata: {
          'actualStartTime': actualStartTime.toIso8601String(),
          'startLocation': startMetadata?['location'],
          'startNotes': startMetadata?['notes'],
        },
      );

      if (!transitionResult.isSuccess) {
        return transitionResult;
      }

      // Update workflow metadata with actual start time
      final updatedWorkflow = transitionResult.workflow!.copyWith(
        metadata: workflow.metadata.copyWith(
          actualStartTime: actualStartTime,
          customFields: {
            ...workflow.metadata.customFields,
            'executionStarted': true,
            if (startMetadata != null) ...startMetadata,
          },
        ),
      );

      await _firestore
          .collection('workflows')
          .doc(workflowId)
          .update(updatedWorkflow.toFirestore());

      // Notify company that job has started
      await _sendWorkflowNotification(
        recipientId: workflow.companyId,
        recipientRole: 'company',
        title: 'Opdracht Gestart',
        message: '${workflow.selectedGuardName} heeft de opdracht "${workflow.jobTitle}" gestart',
        workflowId: workflowId,
        notificationType: WorkflowNotificationType.jobStarted,
        actionData: {
          'startTime': actualStartTime.toIso8601String(),
          'guardLocation': startMetadata?['location'],
        },
      );

      return WorkflowOrchestrationResult.success(
        workflow: updatedWorkflow,
        message: 'Opdracht uitvoering gestart',
      );

    } catch (e) {
      // TODO: Fix audit logging for job start failure

      return WorkflowOrchestrationResult.failure(
        error: 'Fout bij starten opdracht: $e',
        errorCode: 'JOB_START_ERROR',
      );
    }
  }

  /// Complete job and initiate payment workflow
  Future<WorkflowOrchestrationResult> completeJobExecution({
    required String workflowId,
    required String guardId,
    required DateTime actualEndTime,
    required double totalHoursWorked,
    Map<String, dynamic>? completionMetadata,
  }) async {
    try {
      final workflow = await _getWorkflow(workflowId);
      if (workflow == null) {
        return WorkflowOrchestrationResult.failure(
          error: 'Workflow niet gevonden',
          errorCode: 'WORKFLOW_NOT_FOUND',
        );
      }

      // Validate authorization
      if (workflow.selectedGuardId != guardId) {
        return WorkflowOrchestrationResult.failure(
          error: 'Alleen toegewezen beveiliger kan opdracht voltooien',
          errorCode: 'UNAUTHORIZED_COMPLETION',
        );
      }

      // Validate state
      if (workflow.currentState != JobWorkflowState.inProgress) {
        return WorkflowOrchestrationResult.failure(
          error: 'Opdracht is niet in uitvoering',
          errorCode: 'INVALID_STATE_FOR_COMPLETION',
        );
      }

      // Validate hours worked
      if (totalHoursWorked <= 0) {
        return WorkflowOrchestrationResult.failure(
          error: 'Totaal gewerkte uren moet groter dan 0 zijn',
          errorCode: 'INVALID_HOURS_WORKED',
        );
      }

      // Create completion request for payment orchestrator
      final completionRequest = JobCompletionRequest(
        jobId: workflowId,
        guardId: guardId,
        companyId: workflow.companyId,
        workPeriod: WorkPeriod(
          startTime: workflow.metadata.actualStartTime!,
          endTime: actualEndTime,
          totalHours: totalHoursWorked,
        ),
        hourlyRate: workflow.metadata.agreedHourlyRate!,
        metadata: completionMetadata,
      );

      // Process job completion through payment orchestrator
      final paymentResult = await _paymentOrchestrator.processJobCompletion(completionRequest);
      if (!paymentResult.isSuccess) {
        return WorkflowOrchestrationResult.failure(
          error: 'Fout bij verwerken betaling: ${paymentResult.message}',
          errorCode: 'PAYMENT_PROCESSING_FAILED',
        );
      }

      // Transition to completed state
      final transitionResult = await _transitionWorkflowState(
        workflow: workflow,
        newState: JobWorkflowState.completed,
        triggeredBy: guardId,
        reason: 'Job completed by guard',
        metadata: {
          'actualEndTime': actualEndTime.toIso8601String(),
          'totalHoursWorked': totalHoursWorked,
          'completionNotes': completionMetadata?['notes'],
          'paymentAmount': paymentResult.totalAmount,
        },
      );

      if (!transitionResult.isSuccess) {
        return transitionResult;
      }

      // Update workflow metadata
      final completedWorkflow = transitionResult.workflow!.copyWith(
        metadata: workflow.metadata.copyWith(
          actualEndTime: actualEndTime,
          customFields: {
            ...workflow.metadata.customFields,
            'totalHoursWorked': totalHoursWorked,
            'paymentAmount': paymentResult.totalAmount,
            'completionMetadata': completionMetadata,
          },
        ),
      );

      await _firestore
          .collection('workflows')
          .doc(workflowId)
          .update(completedWorkflow.toFirestore());

      // Notify company of completion
      await _sendWorkflowNotification(
        recipientId: workflow.companyId,
        recipientRole: 'company',
        title: 'Opdracht Voltooid',
        message: '${workflow.selectedGuardName} heeft "${workflow.jobTitle}" voltooid. Totaal: ${totalHoursWorked.toStringAsFixed(1)} uur',
        workflowId: workflowId,
        notificationType: WorkflowNotificationType.jobCompleted,
        actionData: {
          'endTime': actualEndTime.toIso8601String(),
          'totalHours': totalHoursWorked,
          'paymentAmount': paymentResult.totalAmount,
        },
      );

      return WorkflowOrchestrationResult.success(
        workflow: completedWorkflow,
        message: 'Opdracht voltooid. Betaling wordt verwerkt na beoordelingen.',
      );

    } catch (e) {
      // TODO: Fix audit logging for job completion failure

      return WorkflowOrchestrationResult.failure(
        error: 'Fout bij voltooien opdracht: $e',
        errorCode: 'JOB_COMPLETION_ERROR',
      );
    }
  }

  /// Handle job rating submission and trigger payment if both parties rated
  Future<WorkflowOrchestrationResult> processJobRating({
    required String workflowId,
    required JobReview review,
  }) async {
    try {
      final workflow = await _getWorkflow(workflowId);
      if (workflow == null) {
        return WorkflowOrchestrationResult.failure(
          error: 'Workflow niet gevonden',
          errorCode: 'WORKFLOW_NOT_FOUND',
        );
      }

      // Validate state
      if (workflow.currentState != JobWorkflowState.completed) {
        return WorkflowOrchestrationResult.failure(
          error: 'Opdracht is niet gereed voor beoordeling',
          errorCode: 'INVALID_STATE_FOR_RATING',
        );
      }

      // Submit rating to payment orchestrator (handles payment logic)
      final ratingResult = await _paymentOrchestrator.handleRatingSubmission(
        JobRating(
          id: review.id,
          jobId: workflowId,
          raterId: review.reviewerId,
          raterType: review.reviewerRole == 'guard' ? RaterType.guard : RaterType.company,
          rating: review.rating.round(),
          comments: review.comment,
          createdAt: review.createdAt,
        ),
      );

      if (!ratingResult.isSuccess) {
        return WorkflowOrchestrationResult.failure(
          error: 'Fout bij verwerken beoordeling: ${ratingResult.message}',
          errorCode: 'RATING_PROCESSING_FAILED',
        );
      }

      // If both parties have rated, transition to rated state
      if (ratingResult.paymentTriggered) {
        final transitionResult = await _transitionWorkflowState(
          workflow: workflow,
          newState: JobWorkflowState.rated,
          triggeredBy: review.reviewerId,
          reason: 'Both parties have submitted ratings',
          metadata: {
            'ratingSubmitted': review.reviewerRole,
            'rating': review.rating,
            'paymentTriggered': true,
          },
        );

        if (!transitionResult.isSuccess) {
          return transitionResult;
        }

        return WorkflowOrchestrationResult.success(
          workflow: transitionResult.workflow!,
          message: 'Beoordelingen compleet. Betaling wordt verwerkt.',
        );
      } else {
        // Update workflow with rating info but don't change state yet
        await _firestore
            .collection('workflows')
            .doc(workflowId)
            .update({
          'lastRatingSubmitted': review.reviewerRole,
          'lastRatingDate': Timestamp.fromDate(DateTime.now()),
        });

        return WorkflowOrchestrationResult.success(
          workflow: workflow,
          message: ratingResult.message,
        );
      }

    } catch (e) {
      // TODO: Fix audit logging for rating processing failure

      return WorkflowOrchestrationResult.failure(
        error: 'Fout bij verwerken beoordeling: $e',
        errorCode: 'RATING_ERROR',
      );
    }
  }

  /// Cancel workflow at any stage
  Future<WorkflowOrchestrationResult> cancelWorkflow({
    required String workflowId,
    required String cancelledBy,
    required String reason,
    Map<String, dynamic>? cancellationMetadata,
  }) async {
    try {
      final workflow = await _getWorkflow(workflowId);
      if (workflow == null) {
        return WorkflowOrchestrationResult.failure(
          error: 'Workflow niet gevonden',
          errorCode: 'WORKFLOW_NOT_FOUND',
        );
      }

      // Don't allow cancellation if already in terminal states
      if (workflow.currentState == JobWorkflowState.closed ||
          workflow.currentState == JobWorkflowState.cancelled) {
        return WorkflowOrchestrationResult.failure(
          error: 'Workflow is al afgesloten of geannuleerd',
          errorCode: 'ALREADY_TERMINATED',
        );
      }

      // Transition to cancelled state
      final transitionResult = await _transitionWorkflowState(
        workflow: workflow,
        newState: JobWorkflowState.cancelled,
        triggeredBy: cancelledBy,
        reason: reason,
        metadata: {
          'cancellationReason': reason,
          'previousState': workflow.currentState.toString(),
          if (cancellationMetadata != null) ...cancellationMetadata,
        },
      );

      if (!transitionResult.isSuccess) {
        return transitionResult;
      }

      // Send cancellation notifications
      final recipientId = cancelledBy == workflow.companyId 
          ? workflow.selectedGuardId 
          : workflow.companyId;
      
      if (recipientId != null) {
        await _sendWorkflowNotification(
          recipientId: recipientId,
          recipientRole: cancelledBy == workflow.companyId ? 'guard' : 'company',
          title: 'Opdracht Geannuleerd',
          message: 'Opdracht "${workflow.jobTitle}" is geannuleerd. Reden: $reason',
          workflowId: workflowId,
          notificationType: WorkflowNotificationType.workflowCancelled,
          actionData: {'reason': reason},
        );
      }

      return WorkflowOrchestrationResult.success(
        workflow: transitionResult.workflow!,
        message: 'Workflow geannuleerd',
      );

    } catch (e) {
      // TODO: Fix audit logging for workflow cancellation failure

      return WorkflowOrchestrationResult.failure(
        error: 'Fout bij annuleren workflow: $e',
        errorCode: 'CANCELLATION_ERROR',
      );
    }
  }

  /// Get workflow by ID
  Future<JobWorkflow?> getWorkflow(String workflowId) async {
    return await _getWorkflow(workflowId);
  }

  /// Watch workflow changes
  Stream<JobWorkflow?> watchWorkflow(String workflowId) {
    return _firestore
        .collection('workflows')
        .doc(workflowId)
        .snapshots()
        .map((doc) => doc.exists ? JobWorkflow.fromFirestore(doc) : null)
        .handleError((error) {
      debugPrint('Error watching workflow: $error');
      return null;
    });
  }

  /// Get workflows for user (company or guard)
  Stream<List<JobWorkflow>> watchUserWorkflows({
    required String userId,
    required String userRole,
    List<JobWorkflowState>? states,
  }) {
    Query query = _firestore.collection('workflows');
    
    if (userRole == 'company') {
      query = query.where('companyId', isEqualTo: userId);
    } else if (userRole == 'guard') {
      query = query.where('selectedGuardId', isEqualTo: userId);
    }

    if (states != null && states.isNotEmpty) {
      query = query.where('currentState', whereIn: states.map((s) => s.toString().split('.').last).toList());
    }

    return query
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobWorkflow.fromFirestore(doc))
            .toList())
        .handleError((error) {
      debugPrint('Error watching user workflows: $error');
      return <JobWorkflow>[];
    });
  }

  // Private helper methods

  /// Get workflow from Firestore
  Future<JobWorkflow?> _getWorkflow(String workflowId) async {
    try {
      final doc = await _firestore.collection('workflows').doc(workflowId).get();
      return doc.exists ? JobWorkflow.fromFirestore(doc) : null;
    } catch (e) {
      debugPrint('Error getting workflow: $e');
      return null;
    }
  }

  /// Validate state transition
  bool _isValidTransition(JobWorkflowState from, JobWorkflowState to) {
    final validTransitions = _validTransitions[from] ?? [];
    return validTransitions.contains(to);
  }

  /// Transition workflow state with validation and logging
  Future<WorkflowOrchestrationResult> _transitionWorkflowState({
    required JobWorkflow workflow,
    required JobWorkflowState newState,
    required String triggeredBy,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate transition
      if (!_isValidTransition(workflow.currentState, newState)) {
        return WorkflowOrchestrationResult.failure(
          error: 'Ongeldige status transitie van ${workflow.currentState.displayNameNL} naar ${newState.displayNameNL}',
          errorCode: 'INVALID_TRANSITION',
        );
      }

      // Create transition record
      final transition = WorkflowTransition(
        fromState: workflow.currentState,
        toState: newState,
        transitionedAt: DateTime.now(),
        transitionedBy: triggeredBy,
        reason: reason,
        metadata: metadata ?? {},
      );

      // Update workflow
      final updatedWorkflow = workflow.copyWith(
        currentState: newState,
        updatedAt: DateTime.now(),
        transitions: {
          ...workflow.transitions,
          DateTime.now().millisecondsSinceEpoch.toString(): transition,
        },
      );

      // Save to Firestore
      await _firestore
          .collection('workflows')
          .doc(workflow.id)
          .update(updatedWorkflow.toFirestore());

      // Log audit trail
      // TODO: Fix audit logging for state transition

      return WorkflowOrchestrationResult.success(
        workflow: updatedWorkflow,
        message: 'Status gewijzigd naar ${newState.displayNameNL}',
      );

    } catch (e) {
      return WorkflowOrchestrationResult.failure(
        error: 'Fout bij status transitie: $e',
        errorCode: 'TRANSITION_ERROR',
      );
    }
  }

  /// Validate company compliance (KvK verification)
  Future<ComplianceValidationResult> _validateCompanyCompliance(String companyId) async {
    try {
      // Get company data from Firestore
      final companyDoc = await _firestore.collection('companies').doc(companyId).get();
      if (!companyDoc.exists) {
        return ComplianceValidationResult.invalid('Bedrijf niet gevonden');
      }

      final companyData = companyDoc.data()!;
      final kvkNumber = companyData['kvkNumber'] as String?;
      
      if (kvkNumber == null || kvkNumber.isEmpty) {
        return ComplianceValidationResult.invalid('KvK nummer ontbreekt');
      }

      // Validate KvK number
      try {
        final kvkData = await KvKApiService.validateKvK(kvkNumber);
        if (kvkData == null) {
          return ComplianceValidationResult.invalid('KvK validatie gefaald: geen gegevens ontvangen');
        }

        return ComplianceValidationResult.valid(
          companyName: kvkData.companyName,
          kvkVerified: true,
        );
      } catch (e) {
        return ComplianceValidationResult.invalid('KvK validatie gefaald: $e');
      }

    } catch (e) {
      return ComplianceValidationResult.invalid('Fout bij valideren bedrijf compliance: $e');
    }
  }

  /// Validate guard compliance (WPBR certification)
  Future<ComplianceValidationResult> _validateGuardCompliance(String guardId) async {
    try {
      // Get guard data from Firestore
      final guardDoc = await _firestore.collection('guards').doc(guardId).get();
      if (!guardDoc.exists) {
        return ComplianceValidationResult.invalid('Beveiliger niet gevonden');
      }

      final guardData = guardDoc.data()!;
      final wpbrCertificateId = guardData['wpbrCertificateId'] as String?;
      
      if (wpbrCertificateId == null || wpbrCertificateId.isEmpty) {
        return ComplianceValidationResult.invalid('WPBR certificaat ontbreekt');
      }

      // Validate WPBR certificate
      final wpbrResult = await _wpbrService.verifyCertificate(wpbrCertificateId);
      if (!wpbrResult.isValid) {
        return ComplianceValidationResult.invalid('Ongeldig WPBR certificaat: ${wpbrResult.errorMessage}');
      }

      return ComplianceValidationResult.valid(
        wpbrVerified: true,
      );

    } catch (e) {
      return ComplianceValidationResult.invalid('Fout bij valideren beveiliger compliance: $e');
    }
  }

  /// Create communication thread between guard and company
  Future<ChatCreationResult> _createCommunicationThread({
    required String workflowId,
    required String guardId,
    required String guardName,
    required String companyId,
    required String companyName,
    required String jobTitle,
    required String initialMessage,
  }) async {
    try {
      final conversationId = await _chatService.createWorkflowConversation(
        guardId: guardId,
        guardName: guardName,
        companyId: companyId,
        companyName: companyName,
        jobTitle: jobTitle,
        workflowId: workflowId,
        initialMessage: initialMessage,
      );

      return ChatCreationResult.success(conversationId);

    } catch (e) {
      return ChatCreationResult.failure('Fout bij aanmaken chat: $e');
    }
  }

  /// Send workflow notification to user
  Future<void> _sendWorkflowNotification({
    required String recipientId,
    required String recipientRole,
    required String title,
    required String message,
    required String workflowId,
    required WorkflowNotificationType notificationType,
    Map<String, dynamic>? actionData,
  }) async {
    try {
      final notification = WorkflowNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recipientId: recipientId,
        recipientRole: recipientRole,
        title: title,
        message: message,
        sentAt: DateTime.now(),
        isRead: false,
        actionUrl: '/workflow/$workflowId',
        data: {
          'workflowId': workflowId,
          'notificationType': notificationType.toString(),
          if (actionData != null) ...actionData,
        },
      );

      await _firestore
          .collection('notifications')
          .add(notification.toMap());

    } catch (e) {
      debugPrint('Error sending workflow notification: $e');
    }
  }
}

/// Workflow orchestration result
class WorkflowOrchestrationResult {
  final bool isSuccess;
  final JobWorkflow? workflow;
  final String message;
  final String? error;
  final String? errorCode;

  const WorkflowOrchestrationResult({
    required this.isSuccess,
    this.workflow,
    required this.message,
    this.error,
    this.errorCode,
  });

  factory WorkflowOrchestrationResult.success({
    required JobWorkflow workflow,
    required String message,
  }) {
    return WorkflowOrchestrationResult(
      isSuccess: true,
      workflow: workflow,
      message: message,
    );
  }

  factory WorkflowOrchestrationResult.failure({
    required String error,
    required String errorCode,
  }) {
    return WorkflowOrchestrationResult(
      isSuccess: false,
      message: error,
      error: error,
      errorCode: errorCode,
    );
  }
}

/// Compliance validation result
class ComplianceValidationResult {
  final bool isValid;
  final String? reason;
  final String? companyName;
  final bool kvkVerified;
  final bool wpbrVerified;

  const ComplianceValidationResult({
    required this.isValid,
    this.reason,
    this.companyName,
    this.kvkVerified = false,
    this.wpbrVerified = false,
  });

  factory ComplianceValidationResult.valid({
    String? companyName,
    bool kvkVerified = false,
    bool wpbrVerified = false,
  }) {
    return ComplianceValidationResult(
      isValid: true,
      companyName: companyName,
      kvkVerified: kvkVerified,
      wpbrVerified: wpbrVerified,
    );
  }

  factory ComplianceValidationResult.invalid(String reason) {
    return ComplianceValidationResult(
      isValid: false,
      reason: reason,
    );
  }
}

/// Chat creation result
class ChatCreationResult {
  final bool isSuccess;
  final String? conversationId;
  final String? error;

  const ChatCreationResult({
    required this.isSuccess,
    this.conversationId,
    this.error,
  });

  factory ChatCreationResult.success(String conversationId) {
    return ChatCreationResult(
      isSuccess: true,
      conversationId: conversationId,
    );
  }

  factory ChatCreationResult.failure(String error) {
    return ChatCreationResult(
      isSuccess: false,
      error: error,
    );
  }
}

/// Workflow notification types
enum WorkflowNotificationType {
  applicationReceived,
  applicationAccepted,
  jobStarted,
  jobCompleted,
  workflowCancelled,
  paymentProcessed,
}

/// Workflow audit actions
enum WorkflowAuditAction {
  workflowInitiated,
  stateTransition,
  complianceValidation,
  paymentProcessing,
}

/// Extension methods for ComplianceData
extension ComplianceDataExtension on ComplianceData {
  ComplianceData copyWith({
    bool? kvkVerified,
    bool? wpbrVerified,
    bool? caoCompliant,
    double? btwRate,
    bool? gdprConsentGiven,
    List<String>? auditTrail,
    Map<String, dynamic>? taxData,
  }) {
    return ComplianceData(
      kvkVerified: kvkVerified ?? this.kvkVerified,
      wpbrVerified: wpbrVerified ?? this.wpbrVerified,
      caoCompliant: caoCompliant ?? this.caoCompliant,
      btwRate: btwRate ?? this.btwRate,
      gdprConsentGiven: gdprConsentGiven ?? this.gdprConsentGiven,
      auditTrail: auditTrail ?? this.auditTrail,
      taxData: taxData ?? this.taxData,
    );
  }
}

/// Extension methods for WorkflowMetadata
extension WorkflowMetadataExtension on WorkflowMetadata {
  WorkflowMetadata copyWith({
    double? agreedHourlyRate,
    int? estimatedHours,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    String? location,
    List<String>? requiredCertificates,
    Map<String, dynamic>? customFields,
  }) {
    return WorkflowMetadata(
      agreedHourlyRate: agreedHourlyRate ?? this.agreedHourlyRate,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      location: location ?? this.location,
      requiredCertificates: requiredCertificates ?? this.requiredCertificates,
      customFields: customFields ?? this.customFields,
    );
  }
}

/// Mock WPBR service until real implementation is available
class MockWpbrService {
  Future<bool> validateWpbrCertificate(String guardId) async {
    // Mock implementation - always returns true for testing
    await Future.delayed(Duration(milliseconds: 100));
    return true;
  }
}