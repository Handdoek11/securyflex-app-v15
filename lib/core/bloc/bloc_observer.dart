import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

/// Global BLoC observer for SecuryFlex application
/// Provides comprehensive logging, analytics, and debugging capabilities
class SecuryFlexBlocObserver extends BlocObserver {
  /// Track BLoC creation for memory management monitoring
  final Set<String> _activeBloCs = <String>{};
  
  /// Performance tracking for BLoC operations
  final Map<String, DateTime> _transitionStartTimes = <String, DateTime>{};
  
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    
    final blocName = bloc.runtimeType.toString();
    _activeBloCs.add(blocName);
    
    if (kDebugMode) {
      debugPrint('🟢 BLoC Created: $blocName (Active: ${_activeBloCs.length})');
    }
    
    // Track BLoC creation in analytics
    _trackBlocLifecycle('created', blocName);
  }

  @override
  void onTransition(BlocBase bloc, Transition transition) {
    // Call super with proper type casting for flutter_bloc compatibility
    if (bloc is Bloc) {
      super.onTransition(bloc, transition);
    }

    final blocName = bloc.runtimeType.toString();
    final eventName = transition.event.runtimeType.toString();
    final stateName = transition.nextState.runtimeType.toString();

    // Track transition start time for performance monitoring
    final transitionKey = '$blocName-$eventName';
    _transitionStartTimes[transitionKey] = DateTime.now();

    if (kDebugMode) {
      debugPrint('🔄 $blocName: $eventName -> $stateName');

      // Log detailed transition info for important BLoCs
      if (_isImportantBloc(blocName)) {
        debugPrint('   📋 Current State: ${transition.currentState.runtimeType}');
        debugPrint('   📋 Event: $transition.event');
        debugPrint('   📋 Next State: $transition.nextState');
      }
    }

    // Track transition performance
    _trackTransitionPerformance(blocName, eventName);

    // Track important state changes in analytics
    if (kReleaseMode && _isImportantTransition(blocName, eventName)) {
      _trackBlocTransition(blocName, eventName, stateName);
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    
    final blocName = bloc.runtimeType.toString();
    
    // Always log errors
    debugPrint('🔴 BLoC Error in $blocName: $error');
    
    if (kDebugMode) {
      debugPrint('🔴 StackTrace: $stackTrace');
    }
    
    // Track error in analytics
    _trackBlocError(blocName, error.toString());
    
    // Alert for critical BLoC errors
    if (_isCriticalBloc(blocName)) {
      debugPrint('🚨 CRITICAL BLoC ERROR in $blocName: $error');
    }
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    
    final blocName = bloc.runtimeType.toString();
    _activeBloCs.remove(blocName);
    
    if (kDebugMode) {
      debugPrint('🔴 BLoC Closed: $blocName (Active: ${_activeBloCs.length})');
    }
    
    // Track BLoC disposal in analytics
    _trackBlocLifecycle('closed', blocName);
    
    // Clean up performance tracking
    _transitionStartTimes.removeWhere((key, value) => key.startsWith(blocName));
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    
    if (kDebugMode && _isImportantBloc(bloc.runtimeType.toString())) {
      debugPrint('🔄 ${bloc.runtimeType} Change: ${change.currentState.runtimeType} -> ${change.nextState.runtimeType}');
    }
  }

  /// Check if BLoC is important for detailed logging
  bool _isImportantBloc(String blocName) {
    return blocName.contains('Auth') || 
           blocName.contains('Job') || 
           blocName.contains('Chat') ||
           blocName.contains('Profile');
  }

  /// Check if BLoC is critical for error alerting
  bool _isCriticalBloc(String blocName) {
    return blocName.contains('Auth') || 
           blocName.contains('Payment') ||
           blocName.contains('Security');
  }

  /// Check if transition is important for analytics
  bool _isImportantTransition(String blocName, String eventName) {
    // Track authentication events
    if (blocName.contains('Auth')) {
      return eventName.contains('Login') || 
             eventName.contains('Logout') || 
             eventName.contains('Register');
    }
    
    // Track job application events
    if (blocName.contains('Job')) {
      return eventName.contains('Apply') || 
             eventName.contains('Filter') ||
             eventName.contains('Search');
    }
    
    // Track chat events
    if (blocName.contains('Chat')) {
      return eventName.contains('Send') || 
             eventName.contains('Receive');
    }
    
    return false;
  }

  /// Track transition performance and log slow operations
  void _trackTransitionPerformance(String blocName, String eventName) {
    final transitionKey = '$blocName-$eventName';
    final startTime = _transitionStartTimes[transitionKey];
    
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      
      // Log slow transitions in debug mode
      if (kDebugMode && duration.inMilliseconds > 100) {
        debugPrint('⚠️  Slow transition in $blocName: $eventName took ${duration.inMilliseconds}ms');
      }
      
      // Track performance in analytics for production
      if (kReleaseMode && duration.inMilliseconds > 500) {
        _trackSlowTransition(blocName, eventName, duration.inMilliseconds);
      }
      
      // Clean up
      _transitionStartTimes.remove(transitionKey);
    }
  }

  /// Get current active BLoCs count for memory monitoring
  int get activeBlocsCount => _activeBloCs.length;

  /// Get list of currently active BLoCs
  Set<String> get activeBloCs => Set.unmodifiable(_activeBloCs);

  /// Print memory usage summary
  void printMemorySummary() {
    if (kDebugMode) {
      debugPrint('📊 BLoC Memory Summary:');
      debugPrint('   Active BLoCs: ${_activeBloCs.length}');
      debugPrint('   Active Transitions: ${_transitionStartTimes.length}');
      debugPrint('   BLoCs: ${_activeBloCs.join(', ')}');
    }
  }

  /// Track BLoC lifecycle events (placeholder for analytics)
  void _trackBlocLifecycle(String event, String blocName) {
    // TODO: Implement Firebase Analytics tracking
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'bloc_lifecycle',
    //   parameters: {
    //     'event': event,
    //     'bloc_name': blocName,
    //     'timestamp': DateTime.now().millisecondsSinceEpoch,
    //     'active_blocs_count': _activeBloCs.length,
    //   },
    // );
  }

  /// Track BLoC transitions (placeholder for analytics)
  void _trackBlocTransition(String blocName, String eventName, String stateName) {
    // TODO: Implement Firebase Analytics tracking
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'bloc_transition',
    //   parameters: {
    //     'bloc_name': blocName,
    //     'event_name': eventName,
    //     'state_name': stateName,
    //     'timestamp': DateTime.now().millisecondsSinceEpoch,
    //   },
    // );
  }

  /// Track BLoC errors (placeholder for analytics)
  void _trackBlocError(String blocName, String error) {
    // TODO: Implement Firebase Crashlytics tracking
    // FirebaseCrashlytics.instance.recordError(
    //   'BLoC Error in $blocName',
    //   null,
    //   fatal: false,
    //   information: [
    //     'BLoC: $blocName',
    //     'Error: $error',
    //     'Timestamp: ${DateTime.now()}',
    //     'Active BLoCs: ${_activeBloCs.length}',
    //   ],
    // );
  }

  /// Track slow transitions (placeholder for analytics)
  void _trackSlowTransition(String blocName, String eventName, int durationMs) {
    // TODO: Implement performance tracking
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'slow_bloc_transition',
    //   parameters: {
    //     'bloc_name': blocName,
    //     'event_name': eventName,
    //     'duration_ms': durationMs,
    //     'timestamp': DateTime.now().millisecondsSinceEpoch,
    //   },
    // );
  }
}
