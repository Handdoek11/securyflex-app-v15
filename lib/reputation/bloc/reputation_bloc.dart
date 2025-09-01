import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../models/reputation_data.dart';
import '../services/reputation_calculation_service.dart';

/// BLoC for managing reputation state and events
/// 
/// Handles reputation loading, calculation, and updates
/// Integrates with existing SecuryFlex BLoC patterns
/// Provides error handling and loading states
class ReputationBloc extends Bloc<ReputationEvent, ReputationState> {
  final ReputationCalculationService _reputationService;

  ReputationBloc({
    ReputationCalculationService? reputationService,
  }) : _reputationService = reputationService ?? ReputationCalculationService.instance,
       super(ReputationInitial()) {
    
    on<LoadReputation>(_onLoadReputation);
    on<RecalculateReputation>(_onRecalculateReputation);
    on<UpdateReputationAfterJob>(_onUpdateReputationAfterJob);
    on<ClearReputationCache>(_onClearReputationCache);
    on<RefreshReputation>(_onRefreshReputation);
  }

  /// Load reputation data with caching support
  Future<void> _onLoadReputation(
    LoadReputation event,
    Emitter<ReputationState> emit,
  ) async {
    try {
      emit(ReputationLoading());

      if (kDebugMode) {
        print('[ReputationBloc] Loading reputation for user: ${event.userId} (${event.userRole})');
      }

      final reputationData = await _reputationService.getReputation(
        event.userId,
        event.userRole,
        useCache: event.useCache,
      );

      emit(ReputationLoaded(reputationData));

      if (kDebugMode) {
        print('[ReputationBloc] Reputation loaded successfully: ${reputationData.overallScore.round()}/100');
      }
    } catch (error) {
      if (kDebugMode) {
        print('[ReputationBloc] Error loading reputation: $error');
      }
      emit(ReputationError('Er is een fout opgetreden bij het laden van de reputatie: ${error.toString()}'));
    }
  }

  /// Recalculate reputation from scratch
  Future<void> _onRecalculateReputation(
    RecalculateReputation event,
    Emitter<ReputationState> emit,
  ) async {
    try {
      emit(ReputationCalculating());

      if (kDebugMode) {
        print('[ReputationBloc] Recalculating reputation for user: ${event.userId} (${event.userRole})');
      }

      final reputationData = await _reputationService.calculateReputation(
        event.userId,
        event.userRole,
      );

      emit(ReputationLoaded(reputationData));

      if (kDebugMode) {
        print('[ReputationBloc] Reputation recalculated successfully: ${reputationData.overallScore.round()}/100');
      }
    } catch (error) {
      if (kDebugMode) {
        print('[ReputationBloc] Error recalculating reputation: $error');
      }
      emit(ReputationError('Er is een fout opgetreden bij het herberekenen van de reputatie: ${error.toString()}'));
    }
  }

  /// Update reputation after job completion
  Future<void> _onUpdateReputationAfterJob(
    UpdateReputationAfterJob event,
    Emitter<ReputationState> emit,
  ) async {
    try {
      // Don't change state to loading for job updates to avoid UI flicker
      if (kDebugMode) {
        print('[ReputationBloc] Updating reputation after job: ${event.workflowId}');
      }

      await _reputationService.updateReputationAfterJob(
        userId: event.userId,
        userRole: event.userRole,
        workflowId: event.workflowId,
        jobCompleted: event.jobCompleted,
        newRating: event.newRating,
      );

      // Reload reputation with updated data
      final reputationData = await _reputationService.getReputation(
        event.userId,
        event.userRole,
        useCache: false, // Force fresh data after update
      );

      emit(ReputationLoaded(reputationData));

      if (kDebugMode) {
        print('[ReputationBloc] Reputation updated after job completion');
      }
    } catch (error) {
      if (kDebugMode) {
        print('[ReputationBloc] Error updating reputation after job: $error');
      }
      // Emit error but don't completely fail - reputation updates can be retried
      emit(ReputationUpdateError('Reputatie update mislukt: ${error.toString()}'));
    }
  }

  /// Clear reputation cache
  Future<void> _onClearReputationCache(
    ClearReputationCache event,
    Emitter<ReputationState> emit,
  ) async {
    try {
      if (kDebugMode) {
        print('[ReputationBloc] Clearing reputation cache');
      }

      _reputationService.invalidateCache();
      
      // If we have a current loaded state, mark it as potentially stale
      if (state is ReputationLoaded) {
        final currentData = (state as ReputationLoaded).reputationData;
        emit(ReputationCacheCleared(currentData));
      } else {
        emit(ReputationCacheCleared(null));
      }

      if (kDebugMode) {
        print('[ReputationBloc] Reputation cache cleared');
      }
    } catch (error) {
      if (kDebugMode) {
        print('[ReputationBloc] Error clearing reputation cache: $error');
      }
      emit(ReputationError('Fout bij het wissen van de cache: ${error.toString()}'));
    }
  }

  /// Refresh reputation data
  Future<void> _onRefreshReputation(
    RefreshReputation event,
    Emitter<ReputationState> emit,
  ) async {
    try {
      if (kDebugMode) {
        print('[ReputationBloc] Refreshing reputation for user: ${event.userId} (${event.userRole})');
      }

      // Clear cache first
      _reputationService.invalidateCache();
      
      // Show refreshing state without losing current data
      if (state is ReputationLoaded) {
        emit(ReputationRefreshing((state as ReputationLoaded).reputationData));
      } else {
        emit(ReputationLoading());
      }

      final reputationData = await _reputationService.getReputation(
        event.userId,
        event.userRole,
        useCache: false,
      );

      emit(ReputationLoaded(reputationData));

      if (kDebugMode) {
        print('[ReputationBloc] Reputation refreshed successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        print('[ReputationBloc] Error refreshing reputation: $error');
      }
      emit(ReputationError('Er is een fout opgetreden bij het vernieuwen van de reputatie: ${error.toString()}'));
    }
  }
}

/// Base reputation event
abstract class ReputationEvent {}

/// Load reputation for a user
class LoadReputation extends ReputationEvent {
  final String userId;
  final String userRole;
  final bool useCache;

  LoadReputation(
    this.userId,
    this.userRole, {
    this.useCache = true,
  });

  @override
  String toString() => 'LoadReputation(userId: $userId, userRole: $userRole, useCache: $useCache)';
}

/// Recalculate reputation from scratch
class RecalculateReputation extends ReputationEvent {
  final String userId;
  final String userRole;

  RecalculateReputation(this.userId, this.userRole);

  @override
  String toString() => 'RecalculateReputation(userId: $userId, userRole: $userRole)';
}

/// Update reputation after job completion
class UpdateReputationAfterJob extends ReputationEvent {
  final String userId;
  final String userRole;
  final String workflowId;
  final bool jobCompleted;
  final double? newRating;

  UpdateReputationAfterJob({
    required this.userId,
    required this.userRole,
    required this.workflowId,
    required this.jobCompleted,
    this.newRating,
  });

  @override
  String toString() => 'UpdateReputationAfterJob(userId: $userId, workflowId: $workflowId, completed: $jobCompleted)';
}

/// Clear reputation cache
class ClearReputationCache extends ReputationEvent {
  @override
  String toString() => 'ClearReputationCache()';
}

/// Refresh reputation data
class RefreshReputation extends ReputationEvent {
  final String userId;
  final String userRole;

  RefreshReputation(this.userId, this.userRole);

  @override
  String toString() => 'RefreshReputation(userId: $userId, userRole: $userRole)';
}

/// Base reputation state
abstract class ReputationState {}

/// Initial reputation state
class ReputationInitial extends ReputationState {
  @override
  String toString() => 'ReputationInitial()';
}

/// Loading reputation data
class ReputationLoading extends ReputationState {
  @override
  String toString() => 'ReputationLoading()';
}

/// Calculating reputation (more intensive than loading)
class ReputationCalculating extends ReputationState {
  @override
  String toString() => 'ReputationCalculating()';
}

/// Refreshing reputation while maintaining current data
class ReputationRefreshing extends ReputationState {
  final ReputationData currentData;

  ReputationRefreshing(this.currentData);

  @override
  String toString() => 'ReputationRefreshing(currentScore: ${currentData.overallScore.round()})';
}

/// Reputation data loaded successfully
class ReputationLoaded extends ReputationState {
  final ReputationData reputationData;

  ReputationLoaded(this.reputationData);

  @override
  String toString() => 'ReputationLoaded(score: ${reputationData.overallScore.round()}/100)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReputationLoaded &&
          runtimeType == other.runtimeType &&
          reputationData.userId == other.reputationData.userId &&
          reputationData.overallScore == other.reputationData.overallScore;

  @override
  int get hashCode => reputationData.userId.hashCode ^ reputationData.overallScore.hashCode;
}

/// Cache cleared successfully
class ReputationCacheCleared extends ReputationState {
  final ReputationData? lastKnownData;

  ReputationCacheCleared(this.lastKnownData);

  @override
  String toString() => 'ReputationCacheCleared()';
}

/// Error loading or calculating reputation
class ReputationError extends ReputationState {
  final String error;

  ReputationError(this.error);

  @override
  String toString() => 'ReputationError(error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReputationError &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// Error updating reputation after job (non-critical)
class ReputationUpdateError extends ReputationState {
  final String error;

  ReputationUpdateError(this.error);

  @override
  String toString() => 'ReputationUpdateError(error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReputationUpdateError &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}