import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'error_handler.dart';

/// Base BLoC class for SecuryFlex with unified error handling and Dutch localization
/// Provides common functionality for all BLoCs in the application
abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  BaseBloc(super.initialState);
  
  @override
  void onError(Object error, StackTrace stackTrace) {
    ErrorHandler.handleBlocError(this, error, stackTrace);
    super.onError(error, stackTrace);
  }
  
  @override
  void onTransition(Transition<Event, State> transition) {
    super.onTransition(transition);
    
    // Debug logging in development
    if (kDebugMode) {
      debugPrint('🔄 $runtimeType: ${transition.event.runtimeType} -> ${transition.nextState.runtimeType}');
    }
    
    // Track analytics in production
    if (kReleaseMode) {
      _trackBlocEvent(transition.event.runtimeType.toString());
    }
  }
  
  /// Track BLoC events for analytics
  void _trackBlocEvent(String eventName) {
    // TODO: Implement Firebase Analytics tracking
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'bloc_event',
    //   parameters: {
    //     'bloc_name': runtimeType.toString(),
    //     'event_name': eventName,
    //     'timestamp': DateTime.now().millisecondsSinceEpoch,
    //   },
    // );
  }
}

/// Base event class for all BLoC events in SecuryFlex
/// Provides Equatable implementation for efficient state comparison
abstract class BaseEvent extends Equatable {
  const BaseEvent();
  
  @override
  List<Object?> get props => [];
  
  @override
  String toString() => runtimeType.toString();
}

/// Base state class for all BLoC states in SecuryFlex
/// Provides Equatable implementation for efficient state comparison
abstract class BaseState extends Equatable {
  const BaseState();
  
  @override
  List<Object?> get props => [];
  
  @override
  String toString() => runtimeType.toString();
}

/// Loading state mixin for consistent loading state implementation
mixin LoadingStateMixin on BaseState {
  bool get isLoading;
  String? get loadingMessage;
  
  /// Dutch loading message based on context
  String get localizedLoadingMessage {
    if (loadingMessage != null) return loadingMessage!;
    
    // Default Dutch loading messages based on state type
    final stateType = runtimeType.toString().toLowerCase();
    if (stateType.contains('auth')) return 'Authenticatie...';
    if (stateType.contains('job')) return 'Jobs laden...';
    if (stateType.contains('profile')) return 'Profiel laden...';
    if (stateType.contains('planning')) return 'Planning laden...';
    
    return 'Laden...';
  }
}

/// Error state mixin for consistent error state implementation
mixin ErrorStateMixin on BaseState {
  AppError get error;
  
  /// Get localized error message in Dutch
  String get localizedErrorMessage => error.localizedMessage;
}

/// Success state mixin for consistent success state implementation
mixin SuccessStateMixin on BaseState {
  String get successMessage;
  
  /// Dutch success message based on context
  String get localizedSuccessMessage {
    final stateType = runtimeType.toString().toLowerCase();
    if (stateType.contains('auth')) return 'Succesvol ingelogd';
    if (stateType.contains('job')) return 'Opdracht succesvol verwerkt';
    if (stateType.contains('profile')) return 'Profiel succesvol bijgewerkt';
    if (stateType.contains('application')) return 'Sollicitatie succesvol verzonden';
    
    return successMessage;
  }
}

/// Common loading state for all BLoCs
class CommonLoadingState extends BaseState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage;
  
  const CommonLoadingState({this.loadingMessage});
  
  @override
  List<Object?> get props => [loadingMessage];
}

/// Common error state for all BLoCs
class CommonErrorState extends BaseState with ErrorStateMixin {
  @override
  final AppError error;
  
  const CommonErrorState(this.error);
  
  @override
  List<Object> get props => [error];
}

/// Common success state for all BLoCs
class CommonSuccessState extends BaseState with SuccessStateMixin {
  @override
  final String successMessage;
  
  const CommonSuccessState(this.successMessage);
  
  @override
  List<Object> get props => [successMessage];
}

/// BLoC status enum for tracking BLoC lifecycle
enum BlocStatus {
  initial,
  loading,
  success,
  error,
}

/// Extension for BLoC status with Dutch descriptions
extension BlocStatusExtension on BlocStatus {
  String get dutchDescription {
    switch (this) {
      case BlocStatus.initial:
        return 'Initieel';
      case BlocStatus.loading:
        return 'Laden';
      case BlocStatus.success:
        return 'Succesvol';
      case BlocStatus.error:
        return 'Fout';
    }
  }
  
  bool get isLoading => this == BlocStatus.loading;
  bool get isSuccess => this == BlocStatus.success;
  bool get isError => this == BlocStatus.error;
  bool get isInitial => this == BlocStatus.initial;
}
