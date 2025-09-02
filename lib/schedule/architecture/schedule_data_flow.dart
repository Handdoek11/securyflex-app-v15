import 'dart:async';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../unified_design_tokens.dart';
import '../blocs/schedule_bloc.dart';
import '../services/schedule_service_provider.dart';
import '../models/shift_model.dart';
import '../models/time_entry_model.dart';
import 'package:go_router/go_router.dart';

/// ScheduleDataFlow - Event dispatching en state management patterns
///
/// Biedt gestandaardiseerde patronen voor:
/// - Event dispatching naar ScheduleBloc
/// - State listening en error handling
/// - Performance optimized state management
/// - Nederlandse error messages
/// - Loading state management
/// - Progress tracking
class ScheduleDataFlow {
  static const String _logTag = 'ScheduleDataFlow';

  /// Event dispatcher with error handling
  static void dispatchEvent(BuildContext context, ScheduleEvent event) {
    try {
      debugPrint('$_logTag: Dispatching event: ${event.runtimeType}');
      
      final scheduleBloc = BlocProvider.of<ScheduleBloc>(context);
      scheduleBloc.add(event);
      
      // Track event for analytics
      _trackEvent(event);
    } catch (e, stackTrace) {
      debugPrint('$_logTag: Failed to dispatch event: $e');
      debugPrint('$_logTag: Stack trace: $stackTrace');
      
      // Show user-friendly error
      _showEventError(context, e.toString());
    }
  }

  /// Safe event dispatcher with validation
  static Future<bool> dispatchEventSafely(
    BuildContext context,
    ScheduleEvent event, {
    bool showProgress = true,
    String? progressMessage,
  }) async {
    try {
      if (showProgress && context.mounted) {
        _showProgressDialog(context, progressMessage ?? 'Bezig...');
      }

      final scheduleBloc = BlocProvider.of<ScheduleBloc>(context);
      
      // Validate event before dispatch
      if (!_validateEvent(event)) {
        throw ArgumentError('Invalid event: ${event.runtimeType}');
      }

      scheduleBloc.add(event);
      _trackEvent(event);

      // Wait for state change
      await _waitForStateChange(scheduleBloc);

      if (showProgress && context.mounted) {
        context.pop(); // Close progress dialog
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('$_logTag: Safe dispatch failed: $e');
      debugPrint('$_logTag: Stack trace: $stackTrace');

      if (showProgress && context.mounted) {
        context.pop(); // Close progress dialog
      }

      if (context.mounted) {
        _showEventError(context, e.toString());
      }

      return false;
    }
  }

  /// BlocBuilder with error handling pattern
  static Widget buildWithErrorHandling<T extends BlocBase<S>, S>({
    required BlocWidgetBuilder<S> builder,
    BlocBuilderCondition<S>? buildWhen,
    required Widget Function(String error) errorBuilder,
    Widget? loadingWidget,
    T? bloc,
  }) {
    return BlocBuilder<T, S>(
      bloc: bloc,
      buildWhen: buildWhen,
      builder: (context, state) {
        try {
          // Handle error states
          if (state is ScheduleError) {
            return errorBuilder((state as ScheduleError).error);
          }

          // Handle loading states
          if (state is ScheduleLoading && loadingWidget != null) {
            return loadingWidget;
          }

          return builder(context, state);
        } catch (e, stackTrace) {
          debugPrint('$_logTag: Builder error: $e');
          debugPrint('$_logTag: Stack trace: $stackTrace');
          
          return _buildErrorWidget(
            'Er is een onverwachte fout opgetreden',
            details: e.toString(),
          );
        }
      },
    );
  }

  /// BlocListener with comprehensive error handling
  static Widget listenWithErrorHandling<T extends BlocBase<S>, S>({
    required Widget child,
    required BlocWidgetListener<S> listener,
    BlocListenerCondition<S>? listenWhen,
    T? bloc,
  }) {
    return BlocListener<T, S>(
      bloc: bloc,
      listenWhen: listenWhen,
      listener: (context, state) {
        try {
          // Handle error states automatically
          if (state is ScheduleError) {
            _handleStateError(context, state as ScheduleError);
            return;
          }

          // Handle success notifications
          if (state is ScheduleLoaded) {
            _handleSuccessState(context, state as ScheduleLoaded);
          }

          // Call custom listener
          listener(context, state);
        } catch (e, stackTrace) {
          debugPrint('$_logTag: Listener error: $e');
          debugPrint('$_logTag: Stack trace: $stackTrace');
          
          if (context.mounted) {
            _showError(
              context,
              'Fout bij verwerken van update',
              details: e.toString(),
            );
          }
        }
      },
      child: child,
    );
  }

  /// BlocConsumer with full error handling
  static Widget consumeWithErrorHandling<T extends BlocBase<S>, S>({
    required BlocWidgetBuilder<S> builder,
    required BlocWidgetListener<S> listener,
    BlocBuilderCondition<S>? buildWhen,
    BlocListenerCondition<S>? listenWhen,
    T? bloc,
    Widget? loadingWidget,
  }) {
    return BlocConsumer<T, S>(
      bloc: bloc,
      buildWhen: buildWhen,
      listenWhen: listenWhen,
      listener: (context, state) {
        try {
          // Handle error states
          if (state is ScheduleError) {
            _handleStateError(context, state as ScheduleError);
            return;
          }

          // Handle success states
          if (state is ScheduleLoaded) {
            _handleSuccessState(context, state as ScheduleLoaded);
          }

          // Call custom listener
          listener(context, state);
        } catch (e, stackTrace) {
          debugPrint('$_logTag: Consumer listener error: $e');
          debugPrint('$_logTag: Stack trace: $stackTrace');
        }
      },
      builder: (context, state) {
        try {
          // Handle error states
          if (state is ScheduleError) {
            return _buildErrorWidget(
              (state as ScheduleError).error,
            );
          }

          // Handle loading states
          if (state is ScheduleLoading && loadingWidget != null) {
            return loadingWidget;
          }

          return builder(context, state);
        } catch (e, stackTrace) {
          debugPrint('$_logTag: Consumer builder error: $e');
          debugPrint('$_logTag: Stack trace: $stackTrace');
          
          return _buildErrorWidget(
            'Er is een onverwachte fout opgetreden',
            details: e.toString(),
          );
        }
      },
    );
  }

  /// Refresh data pattern
  static Future<void> refreshData(
    BuildContext context, {
    String? guardId,
    String? companyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('$_logTag: Refreshing schedule data...');

      final scheduleBloc = BlocProvider.of<ScheduleBloc>(context);
      
      scheduleBloc.add(ScheduleLoadShifts(
        guardId: guardId,
        companyId: companyId,
        startDate: startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        endDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
      ));

      // Also refresh location if needed
      if (guardId != null) {
        scheduleBloc.add(ScheduleLocationUpdate(
          GPSLocation(
            latitude: 0.0, // This would be actual GPS coordinates
            longitude: 0.0,
            accuracy: 5.0,
            altitude: 0.0,
            timestamp: DateTime.now(),
            provider: 'network',
            isMocked: false,
          ),
        ));
      }

      debugPrint('$_logTag: Data refresh initiated');
    } catch (e, stackTrace) {
      debugPrint('$_logTag: Data refresh failed: $e');
      debugPrint('$_logTag: Stack trace: $stackTrace');
      
      if (context.mounted) {
        _showError(
          context,
          'Kon gegevens niet verversen',
          details: e.toString(),
        );
      }
    }
  }

  /// Initialize schedule data with error handling
  static Future<bool> initializeSchedule(
    BuildContext context, {
    required String? guardId,
    required String? companyId,
    bool showLoading = true,
  }) async {
    try {
      debugPrint('$_logTag: Initializing schedule for guardId: $guardId, companyId: $companyId');

      final serviceProvider = ScheduleServiceProvider.instance;
      
      // Check if service provider is healthy
      if (!serviceProvider.isHealthy) {
        throw StateError('Schedule service is not healthy');
      }

      final scheduleBloc = serviceProvider.getScheduleBloc();

      if (showLoading) {
        _showProgressDialog(context, 'Diensten laden...');
      }

      // Initialize with comprehensive data loading
      scheduleBloc.add(ScheduleInitialize(
        guardId: guardId,
        companyId: companyId,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 30)),
      ));

      // Wait for initialization to complete
      await _waitForStateChange(scheduleBloc, timeout: const Duration(seconds: 10));

      if (showLoading && context.mounted) {
        context.pop();
      }

      debugPrint('$_logTag: Schedule initialization completed');
      return true;

    } catch (e, stackTrace) {
      debugPrint('$_logTag: Schedule initialization failed: $e');
      debugPrint('$_logTag: Stack trace: $stackTrace');

      if (showLoading && context.mounted) {
        context.pop();
      }

      if (context.mounted) {
        _showError(
          context,
          'Kon diensten niet laden',
          details: e.toString(),
        );
      }

      return false;
    }
  }

  /// Handle time clock operations
  static Future<bool> handleTimeClockOperation(
    BuildContext context,
    TimeClockOperation operation, {
    required String? guardId,
    String? notes,
    BreakEntryType? breakType,
    Duration? breakDuration,
  }) async {
    if (guardId == null) {
      _showError(context, 'Geen geldige gebruiker gevonden');
      return false;
    }

    try {
      debugPrint('$_logTag: Handling time clock operation: $operation');
      
      final scheduleBloc = BlocProvider.of<ScheduleBloc>(context);
      final currentState = scheduleBloc.state;

      ScheduleEvent? event;

      switch (operation) {
        case TimeClockOperation.checkIn:
          final activeShift = _getActiveShift(currentState, guardId);
          if (activeShift == null) {
            _showError(context, 'Geen actieve dienst gevonden om in te checken');
            return false;
          }
          
          event = ScheduleStartShift(
            shiftId: activeShift.id,
            guardId: guardId,
            companyId: activeShift.companyId,
            jobSiteId: activeShift.jobSiteId,
            jobLocation: activeShift.location,
            notes: notes ?? '',
          );
          break;

        case TimeClockOperation.checkOut:
          final activeShift = _getActiveShift(currentState, guardId);
          if (activeShift == null) {
            _showError(context, 'Geen actieve dienst gevonden om uit te checken');
            return false;
          }
          
          event = ScheduleEndShift(
            guardId: guardId,
            jobLocation: activeShift.location,
            baseHourlyRate: activeShift.hourlyRate,
            notes: notes ?? '',
          );
          break;

        case TimeClockOperation.startBreak:
          if (breakType == null || breakDuration == null) {
            _showError(context, 'Pauze type en duur zijn vereist');
            return false;
          }
          
          event = ScheduleStartBreak(
            breakType: breakType,
            plannedDuration: breakDuration,
          );
          break;

        case TimeClockOperation.endBreak:
          event = const ScheduleEndBreak();
          break;
      }

      if (event != null) {
        return await dispatchEventSafely(
          context,
          event,
          showProgress: true,
          progressMessage: _getOperationProgressMessage(operation),
        );
      }

      return false;

    } catch (e, stackTrace) {
      debugPrint('$_logTag: Time clock operation failed: $e');
      debugPrint('$_logTag: Stack trace: $stackTrace');
      
      if (context.mounted) {
        _showError(
          context,
          'Tijd registratie operatie mislukt',
          details: e.toString(),
        );
      }

      return false;
    }
  }

  /// Batch event dispatcher for multiple operations
  static Future<bool> dispatchBatchEvents(
    BuildContext context,
    List<ScheduleEvent> events, {
    String? progressMessage,
    bool showProgress = true,
  }) async {
    try {
      debugPrint('$_logTag: Dispatching batch of ${events.length} events');

      if (showProgress) {
        _showProgressDialog(
          context,
          progressMessage ?? 'Meerdere acties uitvoeren...',
        );
      }

      final scheduleBloc = BlocProvider.of<ScheduleBloc>(context);
      
      for (int i = 0; i < events.length; i++) {
        final event = events[i];
        debugPrint('$_logTag: Dispatching batch event ${i + 1}/${events.length}: ${event.runtimeType}');
        
        if (!_validateEvent(event)) {
          throw ArgumentError('Invalid event in batch: ${event.runtimeType}');
        }

        scheduleBloc.add(event);
        _trackEvent(event);

        // Small delay between events to prevent overwhelming
        if (i < events.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Wait for final state change
      await _waitForStateChange(scheduleBloc);

      if (showProgress && context.mounted) {
        context.pop();
      }

      debugPrint('$_logTag: Batch dispatch completed successfully');
      return true;

    } catch (e, stackTrace) {
      debugPrint('$_logTag: Batch dispatch failed: $e');
      debugPrint('$_logTag: Stack trace: $stackTrace');

      if (showProgress && context.mounted) {
        context.pop();
      }

      if (context.mounted) {
        _showError(
          context,
          'Batch operatie mislukt',
          details: e.toString(),
        );
      }

      return false;
    }
  }

  // Private helper methods
  static bool _validateEvent(ScheduleEvent event) {
    // Basic validation - can be extended
    return event is ScheduleEvent;
  }

  static void _trackEvent(ScheduleEvent event) {
    // Track events for analytics - placeholder
    debugPrint('$_logTag: Event tracked: ${event.runtimeType}');
  }

  static Future<void> _waitForStateChange(
    ScheduleBloc bloc, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = Completer<void>();
    late StreamSubscription subscription;

    subscription = bloc.stream.listen((state) {
      if (state is! ScheduleLoading) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    // Set timeout
    Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('State change timeout'));
      }
    });

    return completer.future;
  }

  static void _showProgressDialog(BuildContext context, String message) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(DesignTokens.guardPrimary),
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: DesignTokens.fontWeightRegular,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showEventError(BuildContext context, String error) {
    if (!context.mounted) return;

    _showError(
      context,
      'Event verwerking mislukt',
      details: error,
    );
  }

  static void _handleStateError(BuildContext context, ScheduleError state) {
    if (!context.mounted) return;

    _showError(
      context,
      state.error,
    );
  }

  static void _handleSuccessState(BuildContext context, ScheduleLoaded state) {
    // Handle success notifications if needed
    debugPrint('$_logTag: Success state handled: ${state.shifts.length} shifts loaded');
  }

  static void _showError(
    BuildContext context,
    String message, {
    String? details,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: DesignTokens.colorError,
              size: DesignTokens.iconSizeM,
            ),
            const SizedBox(width: DesignTokens.spacingS),
            Text(
              'Fout',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeL,
                fontWeight: DesignTokens.fontWeightBold,
                color: DesignTokens.colorError,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightRegular,
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: DesignTokens.spacingM),
              Text(
                'Details:',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                details,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightRegular,
                  color: DesignTokens.mutedText,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Sluiten',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.guardPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildErrorWidget(String message, {String? details}) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: DesignTokens.colorError,
            size: 64,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          Text(
            message,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.colorError,
            ),
            textAlign: TextAlign.center,
          ),
          if (details != null) ...[
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              details,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightRegular,
                color: DesignTokens.mutedText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  static Shift? _getActiveShift(ScheduleState state, String guardId) {
    if (state is! ScheduleLoaded) return null;
    
    try {
      return state.shifts.firstWhere(
        (shift) => shift.status == ShiftStatus.inProgress ||
                   (shift.assignedGuardId == guardId &&
                    shift.status == ShiftStatus.confirmed &&
                    shift.startTime.isBefore(DateTime.now()) &&
                    shift.endTime.isAfter(DateTime.now())),
      );
    } catch (e) {
      return null;
    }
  }

  static String _getOperationProgressMessage(TimeClockOperation operation) {
    switch (operation) {
      case TimeClockOperation.checkIn:
        return 'Inchecken...';
      case TimeClockOperation.checkOut:
        return 'Uitchecken...';
      case TimeClockOperation.startBreak:
        return 'Pauze starten...';
      case TimeClockOperation.endBreak:
        return 'Pauze beëindigen...';
    }
  }
}

/// Time clock operation types
enum TimeClockOperation {
  checkIn,
  checkOut,
  startBreak,
  endBreak,
}

