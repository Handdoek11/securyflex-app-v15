import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../models/job_workflow_models.dart';
import '../services/workflow_orchestration_service.dart';
import '../../core/bloc/base_bloc.dart';

/// WorkflowOrchestrationBloc manages workflow state transitions and business logic
/// Implements comprehensive error handling and state management for SecuryFlex workflows
class WorkflowOrchestrationBloc extends BaseBloc<WorkflowOrchestrationEvent, WorkflowOrchestrationState> {
  final WorkflowOrchestrationService _orchestrationService;
  
  // Stream subscriptions for real-time updates
  StreamSubscription<JobWorkflow?>? _workflowSubscription;
  StreamSubscription<List<JobWorkflow>>? _userWorkflowsSubscription;

  WorkflowOrchestrationBloc({
    required WorkflowOrchestrationService orchestrationService,
  })  : _orchestrationService = orchestrationService,
        super(WorkflowOrchestrationInitial()) {
    
    // Register event handlers
    on<InitiateJobWorkflow>(_onInitiateJobWorkflow);
    on<ProcessJobApplication>(_onProcessJobApplication);
    on<AcceptJobApplication>(_onAcceptJobApplication);
    on<StartJobExecution>(_onStartJobExecution);
    on<CompleteJobExecution>(_onCompleteJobExecution);
    on<SubmitJobRating>(_onSubmitJobRating);
    on<CancelWorkflow>(_onCancelWorkflow);
    on<LoadWorkflow>(_onLoadWorkflow);
    on<WatchWorkflow>(_onWatchWorkflow);
    on<LoadUserWorkflows>(_onLoadUserWorkflows);
    on<WatchUserWorkflows>(_onWatchUserWorkflows);
    on<WorkflowUpdated>(_onWorkflowUpdated);
    on<WorkflowsUpdated>(_onWorkflowsUpdated);
    on<StopWatchingWorkflow>(_onStopWatchingWorkflow);
    on<StopWatchingUserWorkflows>(_onStopWatchingUserWorkflows);
  }

  /// Initiate a new job workflow when job is posted
  Future<void> _onInitiateJobWorkflow(
    InitiateJobWorkflow event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    emit(WorkflowOrchestrationLoading(message: 'Initialiseren workflow...'));

    try {
      final result = await _orchestrationService.initiateJobWorkflow(
        jobId: event.jobId,
        companyId: event.companyId,
        jobTitle: event.jobTitle,
        hourlyRate: event.hourlyRate,
        metadata: event.metadata,
      );

      if (result.isSuccess) {
        emit(WorkflowOrchestrationSuccess(
          workflow: result.workflow!,
          message: result.message,
        ));
      } else {
        emit(WorkflowOrchestrationError(
          error: result.error!,
          errorCode: result.errorCode,
        ));
      }
    } catch (e) {
      emit(WorkflowOrchestrationError(
        error: 'Onverwachte fout bij initialiseren workflow: $e',
        errorCode: 'UNEXPECTED_ERROR',
      ));
    }
  }

  /// Process job application from guard
  Future<void> _onProcessJobApplication(
    ProcessJobApplication event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    emit(WorkflowOrchestrationLoading(message: 'Verwerken sollicitatie...'));

    try {
      final result = await _orchestrationService.processJobApplication(
        workflowId: event.workflowId,
        guardId: event.guardId,
        guardName: event.guardName,
        motivationMessage: event.motivationMessage,
        applicationData: event.applicationData,
      );

      if (result.isSuccess) {
        emit(WorkflowOrchestrationSuccess(
          workflow: result.workflow!,
          message: result.message,
        ));
      } else {
        emit(WorkflowOrchestrationError(
          error: result.error!,
          errorCode: result.errorCode,
        ));
      }
    } catch (e) {
      emit(WorkflowOrchestrationError(
        error: 'Onverwachte fout bij verwerken sollicitatie: $e',
        errorCode: 'UNEXPECTED_ERROR',
      ));
    }
  }

  /// Accept job application and create communication channel
  Future<void> _onAcceptJobApplication(
    AcceptJobApplication event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    emit(WorkflowOrchestrationLoading(message: 'Accepteren sollicitatie...'));

    try {
      final result = await _orchestrationService.acceptApplication(
        workflowId: event.workflowId,
        companyId: event.companyId,
        acceptanceMessage: event.acceptanceMessage,
        scheduledStartTime: event.scheduledStartTime,
        contractTerms: event.contractTerms,
      );

      if (result.isSuccess) {
        emit(WorkflowOrchestrationSuccess(
          workflow: result.workflow!,
          message: result.message,
        ));
      } else {
        emit(WorkflowOrchestrationError(
          error: result.error!,
          errorCode: result.errorCode,
        ));
      }
    } catch (e) {
      emit(WorkflowOrchestrationError(
        error: 'Onverwachte fout bij accepteren sollicitatie: $e',
        errorCode: 'UNEXPECTED_ERROR',
      ));
    }
  }

  /// Start job execution
  Future<void> _onStartJobExecution(
    StartJobExecution event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    emit(WorkflowOrchestrationLoading(message: 'Starten opdracht uitvoering...'));

    try {
      final result = await _orchestrationService.startJobExecution(
        workflowId: event.workflowId,
        guardId: event.guardId,
        actualStartTime: event.actualStartTime,
        startMetadata: event.startMetadata,
      );

      if (result.isSuccess) {
        emit(WorkflowOrchestrationSuccess(
          workflow: result.workflow!,
          message: result.message,
        ));
      } else {
        emit(WorkflowOrchestrationError(
          error: result.error!,
          errorCode: result.errorCode,
        ));
      }
    } catch (e) {
      emit(WorkflowOrchestrationError(
        error: 'Onverwachte fout bij starten uitvoering: $e',
        errorCode: 'UNEXPECTED_ERROR',
      ));
    }
  }

  /// Complete job execution and initiate payment
  Future<void> _onCompleteJobExecution(
    CompleteJobExecution event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    emit(WorkflowOrchestrationLoading(message: 'Voltooien opdracht uitvoering...'));

    try {
      final result = await _orchestrationService.completeJobExecution(
        workflowId: event.workflowId,
        guardId: event.guardId,
        actualEndTime: event.actualEndTime,
        totalHoursWorked: event.totalHoursWorked,
        completionMetadata: event.completionMetadata,
      );

      if (result.isSuccess) {
        emit(WorkflowOrchestrationSuccess(
          workflow: result.workflow!,
          message: result.message,
        ));
      } else {
        emit(WorkflowOrchestrationError(
          error: result.error!,
          errorCode: result.errorCode,
        ));
      }
    } catch (e) {
      emit(WorkflowOrchestrationError(
        error: 'Onverwachte fout bij voltooien uitvoering: $e',
        errorCode: 'UNEXPECTED_ERROR',
      ));
    }
  }

  /// Submit job rating
  Future<void> _onSubmitJobRating(
    SubmitJobRating event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    emit(WorkflowOrchestrationLoading(message: 'Indienen beoordeling...'));

    try {
      final result = await _orchestrationService.processJobRating(
        workflowId: event.workflowId,
        review: event.review,
      );

      if (result.isSuccess) {
        emit(WorkflowOrchestrationSuccess(
          workflow: result.workflow!,
          message: result.message,
        ));
      } else {
        emit(WorkflowOrchestrationError(
          error: result.error!,
          errorCode: result.errorCode,
        ));
      }
    } catch (e) {
      emit(WorkflowOrchestrationError(
        error: 'Onverwachte fout bij indienen beoordeling: $e',
        errorCode: 'UNEXPECTED_ERROR',
      ));
    }
  }

  /// Cancel workflow
  Future<void> _onCancelWorkflow(
    CancelWorkflow event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    emit(WorkflowOrchestrationLoading(message: 'Annuleren workflow...'));

    try {
      final result = await _orchestrationService.cancelWorkflow(
        workflowId: event.workflowId,
        cancelledBy: event.cancelledBy,
        reason: event.reason,
        cancellationMetadata: event.cancellationMetadata,
      );

      if (result.isSuccess) {
        emit(WorkflowOrchestrationSuccess(
          workflow: result.workflow!,
          message: result.message,
        ));
      } else {
        emit(WorkflowOrchestrationError(
          error: result.error!,
          errorCode: result.errorCode,
        ));
      }
    } catch (e) {
      emit(WorkflowOrchestrationError(
        error: 'Onverwachte fout bij annuleren workflow: $e',
        errorCode: 'UNEXPECTED_ERROR',
      ));
    }
  }

  /// Load single workflow
  Future<void> _onLoadWorkflow(
    LoadWorkflow event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    emit(WorkflowOrchestrationLoading(message: 'Laden workflow...'));

    try {
      final workflow = await _orchestrationService.getWorkflow(event.workflowId);
      
      if (workflow != null) {
        emit(WorkflowOrchestrationLoaded(workflow: workflow));
      } else {
        emit(WorkflowOrchestrationError(
          error: 'Workflow niet gevonden',
          errorCode: 'WORKFLOW_NOT_FOUND',
        ));
      }
    } catch (e) {
      emit(WorkflowOrchestrationError(
        error: 'Fout bij laden workflow: $e',
        errorCode: 'LOAD_ERROR',
      ));
    }
  }

  /// Start watching single workflow for real-time updates
  Future<void> _onWatchWorkflow(
    WatchWorkflow event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    // Cancel existing subscription
    await _workflowSubscription?.cancel();
    
    emit(WorkflowOrchestrationLoading(message: 'Starten real-time updates...'));

    try {
      _workflowSubscription = _orchestrationService
          .watchWorkflow(event.workflowId)
          .listen(
        (workflow) {
          if (workflow != null) {
            add(WorkflowUpdated(workflow: workflow));
          } else {
            add(LoadWorkflow(workflowId: event.workflowId));
          }
        },
        onError: (error) {
          add(WorkflowUpdated(workflow: null)); // Will trigger error state
        },
      );

    } catch (e) {
      emit(WorkflowOrchestrationError(
        error: 'Fout bij starten real-time updates: $e',
        errorCode: 'WATCH_ERROR',
      ));
    }
  }

  /// Handle workflow update from stream
  Future<void> _onWorkflowUpdated(
    WorkflowUpdated event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    if (event.workflow != null) {
      emit(WorkflowOrchestrationLoaded(workflow: event.workflow!));
    } else {
      emit(WorkflowOrchestrationError(
        error: 'Workflow stream update gefaald',
        errorCode: 'STREAM_UPDATE_FAILED',
      ));
    }
  }

  /// Load user workflows
  Future<void> _onLoadUserWorkflows(
    LoadUserWorkflows event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    emit(WorkflowOrchestrationLoading(message: 'Laden workflows...'));

    try {
      // For one-time load, we'll get the first emission from the stream
      final workflows = await _orchestrationService
          .watchUserWorkflows(
            userId: event.userId,
            userRole: event.userRole,
            states: event.states,
          )
          .first;

      emit(WorkflowOrchestrationMultipleLoaded(workflows: workflows));

    } catch (e) {
      emit(WorkflowOrchestrationError(
        error: 'Fout bij laden workflows: $e',
        errorCode: 'LOAD_WORKFLOWS_ERROR',
      ));
    }
  }

  /// Start watching user workflows for real-time updates
  Future<void> _onWatchUserWorkflows(
    WatchUserWorkflows event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    // Cancel existing subscription
    await _userWorkflowsSubscription?.cancel();
    
    emit(WorkflowOrchestrationLoading(message: 'Starten real-time workflow updates...'));

    try {
      _userWorkflowsSubscription = _orchestrationService
          .watchUserWorkflows(
            userId: event.userId,
            userRole: event.userRole,
            states: event.states,
          )
          .listen(
        (workflows) {
          add(WorkflowsUpdated(workflows: workflows));
        },
        onError: (error) {
          add(WorkflowsUpdated(workflows: [])); // Will maintain current state or show empty
        },
      );

    } catch (e) {
      emit(WorkflowOrchestrationError(
        error: 'Fout bij starten real-time workflow updates: $e',
        errorCode: 'WATCH_WORKFLOWS_ERROR',
      ));
    }
  }

  /// Handle workflows update from stream
  Future<void> _onWorkflowsUpdated(
    WorkflowsUpdated event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    emit(WorkflowOrchestrationMultipleLoaded(workflows: event.workflows));
  }

  /// Stop watching single workflow
  Future<void> _onStopWatchingWorkflow(
    StopWatchingWorkflow event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    await _workflowSubscription?.cancel();
    _workflowSubscription = null;
    
    // Emit current state without real-time updates
    if (state is WorkflowOrchestrationLoaded) {
      final currentState = state as WorkflowOrchestrationLoaded;
      emit(WorkflowOrchestrationLoaded(workflow: currentState.workflow));
    }
  }

  /// Stop watching user workflows
  Future<void> _onStopWatchingUserWorkflows(
    StopWatchingUserWorkflows event,
    Emitter<WorkflowOrchestrationState> emit,
  ) async {
    await _userWorkflowsSubscription?.cancel();
    _userWorkflowsSubscription = null;
    
    // Emit current state without real-time updates
    if (state is WorkflowOrchestrationMultipleLoaded) {
      final currentState = state as WorkflowOrchestrationMultipleLoaded;
      emit(WorkflowOrchestrationMultipleLoaded(workflows: currentState.workflows));
    }
  }

  @override
  Future<void> close() async {
    await _workflowSubscription?.cancel();
    await _userWorkflowsSubscription?.cancel();
    return super.close();
  }
}

/// Workflow orchestration events
abstract class WorkflowOrchestrationEvent {}

/// Initiate new job workflow
class InitiateJobWorkflow extends WorkflowOrchestrationEvent {
  final String jobId;
  final String companyId;
  final String jobTitle;
  final double hourlyRate;
  final Map<String, dynamic>? metadata;

  InitiateJobWorkflow({
    required this.jobId,
    required this.companyId,
    required this.jobTitle,
    required this.hourlyRate,
    this.metadata,
  });
}

/// Process job application from guard
class ProcessJobApplication extends WorkflowOrchestrationEvent {
  final String workflowId;
  final String guardId;
  final String guardName;
  final String motivationMessage;
  final Map<String, dynamic> applicationData;

  ProcessJobApplication({
    required this.workflowId,
    required this.guardId,
    required this.guardName,
    required this.motivationMessage,
    required this.applicationData,
  });
}

/// Accept job application
class AcceptJobApplication extends WorkflowOrchestrationEvent {
  final String workflowId;
  final String companyId;
  final String acceptanceMessage;
  final DateTime? scheduledStartTime;
  final Map<String, dynamic>? contractTerms;

  AcceptJobApplication({
    required this.workflowId,
    required this.companyId,
    required this.acceptanceMessage,
    this.scheduledStartTime,
    this.contractTerms,
  });
}

/// Start job execution
class StartJobExecution extends WorkflowOrchestrationEvent {
  final String workflowId;
  final String guardId;
  final DateTime actualStartTime;
  final Map<String, dynamic>? startMetadata;

  StartJobExecution({
    required this.workflowId,
    required this.guardId,
    required this.actualStartTime,
    this.startMetadata,
  });
}

/// Complete job execution
class CompleteJobExecution extends WorkflowOrchestrationEvent {
  final String workflowId;
  final String guardId;
  final DateTime actualEndTime;
  final double totalHoursWorked;
  final Map<String, dynamic>? completionMetadata;

  CompleteJobExecution({
    required this.workflowId,
    required this.guardId,
    required this.actualEndTime,
    required this.totalHoursWorked,
    this.completionMetadata,
  });
}

/// Submit job rating
class SubmitJobRating extends WorkflowOrchestrationEvent {
  final String workflowId;
  final JobReview review;

  SubmitJobRating({
    required this.workflowId,
    required this.review,
  });
}

/// Cancel workflow
class CancelWorkflow extends WorkflowOrchestrationEvent {
  final String workflowId;
  final String cancelledBy;
  final String reason;
  final Map<String, dynamic>? cancellationMetadata;

  CancelWorkflow({
    required this.workflowId,
    required this.cancelledBy,
    required this.reason,
    this.cancellationMetadata,
  });
}

/// Load single workflow
class LoadWorkflow extends WorkflowOrchestrationEvent {
  final String workflowId;

  LoadWorkflow({required this.workflowId});
}

/// Watch single workflow for real-time updates
class WatchWorkflow extends WorkflowOrchestrationEvent {
  final String workflowId;

  WatchWorkflow({required this.workflowId});
}

/// Internal event for workflow updates
class WorkflowUpdated extends WorkflowOrchestrationEvent {
  final JobWorkflow? workflow;

  WorkflowUpdated({required this.workflow});
}

/// Load user workflows
class LoadUserWorkflows extends WorkflowOrchestrationEvent {
  final String userId;
  final String userRole;
  final List<JobWorkflowState>? states;

  LoadUserWorkflows({
    required this.userId,
    required this.userRole,
    this.states,
  });
}

/// Watch user workflows for real-time updates
class WatchUserWorkflows extends WorkflowOrchestrationEvent {
  final String userId;
  final String userRole;
  final List<JobWorkflowState>? states;

  WatchUserWorkflows({
    required this.userId,
    required this.userRole,
    this.states,
  });
}

/// Internal event for workflows updates
class WorkflowsUpdated extends WorkflowOrchestrationEvent {
  final List<JobWorkflow> workflows;

  WorkflowsUpdated({required this.workflows});
}

/// Stop watching single workflow
class StopWatchingWorkflow extends WorkflowOrchestrationEvent {}

/// Stop watching user workflows
class StopWatchingUserWorkflows extends WorkflowOrchestrationEvent {}

/// Workflow orchestration states
abstract class WorkflowOrchestrationState {}

/// Initial state
class WorkflowOrchestrationInitial extends WorkflowOrchestrationState {}

/// Loading state
class WorkflowOrchestrationLoading extends WorkflowOrchestrationState {
  final String message;

  WorkflowOrchestrationLoading({required this.message});
}

/// Success state for single workflow operations
class WorkflowOrchestrationSuccess extends WorkflowOrchestrationState {
  final JobWorkflow workflow;
  final String message;

  WorkflowOrchestrationSuccess({
    required this.workflow,
    required this.message,
  });
}

/// Single workflow loaded state
class WorkflowOrchestrationLoaded extends WorkflowOrchestrationState {
  final JobWorkflow workflow;

  WorkflowOrchestrationLoaded({required this.workflow});
}

/// Multiple workflows loaded state
class WorkflowOrchestrationMultipleLoaded extends WorkflowOrchestrationState {
  final List<JobWorkflow> workflows;

  WorkflowOrchestrationMultipleLoaded({required this.workflows});
}

/// Error state
class WorkflowOrchestrationError extends WorkflowOrchestrationState {
  final String error;
  final String? errorCode;
  final Map<String, dynamic>? errorMetadata;

  WorkflowOrchestrationError({
    required this.error,
    this.errorCode,
    this.errorMetadata,
  });
}

/// State extension methods for easy access
extension WorkflowOrchestrationStateX on WorkflowOrchestrationState {
  /// Check if state is loading
  bool get isLoading => this is WorkflowOrchestrationLoading;
  
  /// Check if state is error
  bool get isError => this is WorkflowOrchestrationError;
  
  /// Check if state has workflow data
  bool get hasWorkflow => this is WorkflowOrchestrationLoaded || this is WorkflowOrchestrationSuccess;
  
  /// Check if state has multiple workflows
  bool get hasWorkflows => this is WorkflowOrchestrationMultipleLoaded;
  
  /// Get workflow if available
  JobWorkflow? get workflow {
    if (this is WorkflowOrchestrationLoaded) {
      return (this as WorkflowOrchestrationLoaded).workflow;
    } else if (this is WorkflowOrchestrationSuccess) {
      return (this as WorkflowOrchestrationSuccess).workflow;
    }
    return null;
  }
  
  /// Get workflows if available
  List<JobWorkflow>? get workflows {
    if (this is WorkflowOrchestrationMultipleLoaded) {
      return (this as WorkflowOrchestrationMultipleLoaded).workflows;
    }
    return null;
  }
  
  /// Get error message if in error state
  String? get errorMessage {
    if (this is WorkflowOrchestrationError) {
      return (this as WorkflowOrchestrationError).error;
    }
    return null;
  }
  
  /// Get loading message if in loading state
  String? get loadingMessage {
    if (this is WorkflowOrchestrationLoading) {
      return (this as WorkflowOrchestrationLoading).message;
    }
    return null;
  }
}