import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../services/job_completion_payment_orchestrator.dart';
import '../services/workflow_payment_service.dart';
import '../services/job_completion_rating_service.dart';
import '../models/job_workflow_models.dart';

// Events
abstract class JobCompletionEvent extends Equatable {
  const JobCompletionEvent();

  @override
  List<Object?> get props => [];
}

class JobCompletionInitiate extends JobCompletionEvent {
  final String jobId;
  final String guardId;
  final String companyId;
  final WorkPeriod workPeriod;
  final double hourlyRate;

  const JobCompletionInitiate({
    required this.jobId,
    required this.guardId,
    required this.companyId,
    required this.workPeriod,
    required this.hourlyRate,
  });

  @override
  List<Object?> get props => [jobId, guardId, companyId, workPeriod, hourlyRate];
}

class JobRatingSubmit extends JobCompletionEvent {
  final String jobId;
  final String raterId;
  final RaterType raterType;
  final int rating;
  final String? comments;

  const JobRatingSubmit({
    required this.jobId,
    required this.raterId,
    required this.raterType,
    required this.rating,
    this.comments,
  });

  @override
  List<Object?> get props => [jobId, raterId, raterType, rating, comments];
}

class PaymentStatusCheck extends JobCompletionEvent {
  final String jobId;

  const PaymentStatusCheck({required this.jobId});

  @override
  List<Object?> get props => [jobId];
}

// States
abstract class JobCompletionState extends Equatable {
  const JobCompletionState();

  @override
  List<Object?> get props => [];
}

class JobCompletionInitial extends JobCompletionState {}

class JobCompletionLoading extends JobCompletionState {}

class JobCompletionInProgress extends JobCompletionState {
  final String jobId;
  final JobWorkflowState currentState;
  final double? totalAmount;

  const JobCompletionInProgress({
    required this.jobId,
    required this.currentState,
    this.totalAmount,
  });

  @override
  List<Object?> get props => [jobId, currentState, totalAmount];
}

class JobCompletionCompleted extends JobCompletionState {
  final String jobId;
  final double totalAmount;
  final String paymentId;

  const JobCompletionCompleted({
    required this.jobId,
    required this.totalAmount,
    required this.paymentId,
  });

  @override
  List<Object?> get props => [jobId, totalAmount, paymentId];
}

class JobCompletionError extends JobCompletionState {
  final String message;
  final String? errorCode;

  const JobCompletionError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

// WorkflowPaymentStatus class
class WorkflowPaymentStatus {
  final String jobId;
  final JobWorkflowState state;
  final bool isPaid;
  final String? paymentId;
  final double? amount;

  const WorkflowPaymentStatus({
    required this.jobId,
    required this.state,
    required this.isPaid,
    this.paymentId,
    this.amount,
  });
}

// BLoC Implementation
class JobCompletionBloc extends Bloc<JobCompletionEvent, JobCompletionState> {
  final JobCompletionPaymentOrchestrator _orchestrator;
  final WorkflowPaymentService _workflowService;
  final JobCompletionRatingService _ratingService;

  JobCompletionBloc({
    JobCompletionPaymentOrchestrator? orchestrator,
    WorkflowPaymentService? workflowService,
    JobCompletionRatingService? ratingService,
  })  : _orchestrator = orchestrator ?? JobCompletionPaymentOrchestrator(),
        _workflowService = workflowService ?? WorkflowPaymentService(),
        _ratingService = ratingService ?? JobCompletionRatingService.instance,
        super(JobCompletionInitial()) {
    
    on<JobCompletionInitiate>(_onJobCompletionInitiate);
    on<JobRatingSubmit>(_onJobRatingSubmit);
    on<PaymentStatusCheck>(_onPaymentStatusCheck);
  }

  void logInfo(String message) {
    if (kDebugMode) {
      print('[JobCompletionBloc] INFO: $message');
    }
  }

  void logError(String message, [Object? error]) {
    if (kDebugMode) {
      print('[JobCompletionBloc] ERROR: $message');
      if (error != null) print('Error details: $error');
    }
  }

  Future<void> _onJobCompletionInitiate(
    JobCompletionInitiate event,
    Emitter<JobCompletionState> emit,
  ) async {
    try {
      logInfo('Initiating job completion for job ${event.jobId}');
      emit(JobCompletionLoading());

      final request = JobCompletionRequest(
        jobId: event.jobId,
        guardId: event.guardId,
        companyId: event.companyId,
        workPeriod: event.workPeriod,
        hourlyRate: event.hourlyRate,
      );

      final result = await _orchestrator.processJobCompletion(request);

      if (result.isSuccess) {
        logInfo('Job completion successful: ${result.message}');
        emit(JobCompletionCompleted(
          jobId: result.jobId ?? event.jobId,
          totalAmount: result.totalAmount ?? 0.0,
          paymentId: result.jobId ?? 'unknown',
        ));
      } else {
        logError('Job completion failed: ${result.message}');
        emit(JobCompletionError(
          message: result.message,
          errorCode: result.errorCode,
        ));
      }
    } catch (e) {
      logError('Exception during job completion', e);
      emit(JobCompletionError(
        message: 'Er is een fout opgetreden bij het voltooien van de opdracht: $e',
        errorCode: 'COMPLETION_EXCEPTION',
      ));
    }
  }

  Future<void> _onJobRatingSubmit(
    JobRatingSubmit event,
    Emitter<JobCompletionState> emit,
  ) async {
    try {
      logInfo('Submitting rating for job ${event.jobId}');
      
      // Convert RaterType to string for service
      final raterRole = event.raterType == RaterType.guard ? 'guard' : 'company';
      
      // Submit rating using the new rating service
      final result = await _ratingService.submitJobCompletionRating(
        workflowId: 'workflow_${event.jobId}', // This should come from the workflow
        jobId: event.jobId,
        raterId: event.raterId,
        raterRole: raterRole,
        rating: event.rating.toDouble(),
        comments: event.comments,
      );
      
      if (result.isSuccess) {
        logInfo('Rating submitted successfully with ID: ${result.reviewId}');
        
        // Check if both parties have rated
        final bothRated = await _ratingService.areBothPartiesRated('workflow_${event.jobId}');
        
        emit(JobCompletionInProgress(
          jobId: event.jobId,
          currentState: bothRated ? JobWorkflowState.rated : JobWorkflowState.completed,
        ));
      } else {
        logError('Rating submission failed: ${result.errorMessage}');
        emit(JobCompletionError(
          message: result.errorMessage ?? 'Fout bij het indienen van beoordeling',
          errorCode: 'RATING_FAILED',
        ));
      }
    } catch (e) {
      logError('Exception during rating submission', e);
      emit(JobCompletionError(
        message: 'Fout bij het indienen van beoordeling: $e',
        errorCode: 'RATING_EXCEPTION',
      ));
    }
  }

  Future<void> _onPaymentStatusCheck(
    PaymentStatusCheck event,
    Emitter<JobCompletionState> emit,
  ) async {
    try {
      logInfo('Checking payment status for job ${event.jobId}');
      
      // Use workflow service to get current state
      final currentState = await _workflowService.getCurrentWorkflowState(event.jobId);
      
      emit(JobCompletionInProgress(
        jobId: event.jobId,
        currentState: currentState,
      ));
    } catch (e) {
      logError('Exception during payment status check', e);
      emit(JobCompletionError(
        message: 'Fout bij het controleren van betalingsstatus: $e',
        errorCode: 'STATUS_CHECK_EXCEPTION',
      ));
    }
  }

  @override
  Future<void> close() {
    logInfo('JobCompletionBloc closing');
    return super.close();
  }
}