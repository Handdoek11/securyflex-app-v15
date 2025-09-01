import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Utility functions for BLoC operations in SecuryFlex
class BlocUtils {
  /// Debounce transformer for search and filter operations
  /// Prevents excessive API calls during rapid user input
  static EventTransformer<T> debounce<T>(Duration duration) {
    return (events, mapper) {
      return events.debounceTime(duration).switchMap(mapper);
    };
  }

  /// Throttle transformer for rate-limiting events
  /// Useful for preventing spam clicks or rapid fire events
  static EventTransformer<T> throttle<T>(Duration duration) {
    return (events, mapper) {
      return events.throttleTime(duration).switchMap(mapper);
    };
  }

  /// Distinct transformer to prevent duplicate events
  /// Useful for preventing unnecessary state updates
  static EventTransformer<T> distinct<T>() {
    return (events, mapper) {
      return events.distinct().switchMap(mapper);
    };
  }

  /// Combined transformer for search operations
  /// Debounces, makes distinct, and switches to latest
  static EventTransformer<T> searchTransformer<T>({
    Duration debounceTime = const Duration(milliseconds: 300),
  }) {
    return (events, mapper) {
      return events
          .debounceTime(debounceTime)
          .distinct()
          .switchMap(mapper);
    };
  }

  /// Check if a BLoC is in loading state
  static bool isLoading(BlocBase bloc) {
    final state = bloc.state;
    return state.toString().toLowerCase().contains('loading') ||
           (state is Map && state['isLoading'] == true);
  }

  /// Check if a BLoC has an error state
  static bool hasError(BlocBase bloc) {
    final state = bloc.state;
    return state.toString().toLowerCase().contains('error') ||
           (state is Map && state['error'] != null);
  }

  /// Get error message from BLoC state
  static String? getErrorMessage(BlocBase bloc) {
    final state = bloc.state;
    
    // Check if state has error property
    if (state is Map && state['error'] != null) {
      return state['error'].toString();
    }
    
    // Check if state has localizedErrorMessage method
    try {
      final dynamic stateObj = state;
      if (stateObj.localizedErrorMessage != null) {
        return stateObj.localizedErrorMessage as String;
      }
    } catch (e) {
      // Ignore if method doesn't exist
    }
    
    return null;
  }

  /// Safe BLoC event dispatch with error handling
  static void safeAdd<T, S>(Bloc<T, S> bloc, T event) {
    try {
      if (!bloc.isClosed) {
        bloc.add(event);
      }
    } catch (e) {
      debugPrint('Error adding event to BLoC: $e');
    }
  }

  /// Wait for specific state with timeout
  static Future<S?> waitForState<S>(
    BlocBase<S> bloc,
    bool Function(S state) predicate, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final completer = Completer<S?>();
    late StreamSubscription subscription;

    // Set up timeout
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    // Listen for state changes
    subscription = bloc.stream.listen((state) {
      if (predicate(state) && !completer.isCompleted) {
        timer.cancel();
        subscription.cancel();
        completer.complete(state);
      }
    });

    // Check current state first
    if (predicate(bloc.state) && !completer.isCompleted) {
      timer.cancel();
      subscription.cancel();
      completer.complete(bloc.state);
    }

    final result = await completer.future;
    
    // Cleanup
    timer.cancel();
    subscription.cancel();
    
    return result;
  }

  /// Create a BLoC listener that automatically disposes
  static StreamSubscription<S> createListener<S>(
    Stream<S> stream,
    void Function(S state) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: false,
    );
  }

  /// Batch multiple BLoC events with delay
  static Future<void> batchEvents<T, S>(
    Bloc<T, S> bloc,
    List<T> events, {
    Duration delay = const Duration(milliseconds: 50),
  }) async {
    for (final event in events) {
      if (!bloc.isClosed) {
        bloc.add(event);
        if (delay.inMilliseconds > 0) {
          await Future.delayed(delay);
        }
      }
    }
  }

  /// Create a disposable timer for BLoC operations
  static Timer createDisposableTimer(
    Duration duration,
    VoidCallback callback,
  ) {
    return Timer(duration, callback);
  }

  /// Create a periodic timer for BLoC operations
  static Timer createPeriodicTimer(
    Duration period,
    void Function(Timer timer) callback,
  ) {
    return Timer.periodic(period, callback);
  }
}

/// Extension methods for RxDart-like operations on streams
extension StreamExtensions<T> on Stream<T> {
  /// Debounce stream emissions
  Stream<T> debounceTime(Duration duration) {
    StreamController<T>? controller;
    Timer? timer;
    late StreamSubscription<T> subscription;

    controller = StreamController<T>(
      onListen: () {
        subscription = listen(
          (data) {
            timer?.cancel();
            timer = Timer(duration, () {
              controller?.add(data);
            });
          },
          onError: controller?.addError,
          onDone: () {
            timer?.cancel();
            controller?.close();
          },
        );
      },
      onCancel: () {
        timer?.cancel();
        subscription.cancel();
      },
    );

    return controller.stream;
  }

  /// Throttle stream emissions
  Stream<T> throttleTime(Duration duration) {
    StreamController<T>? controller;
    Timer? timer;
    late StreamSubscription<T> subscription;
    bool isThrottled = false;

    controller = StreamController<T>(
      onListen: () {
        subscription = listen(
          (data) {
            if (!isThrottled) {
              controller?.add(data);
              isThrottled = true;
              timer = Timer(duration, () {
                isThrottled = false;
              });
            }
          },
          onError: controller?.addError,
          onDone: () {
            timer?.cancel();
            controller?.close();
          },
        );
      },
      onCancel: () {
        timer?.cancel();
        subscription.cancel();
      },
    );

    return controller.stream;
  }

  /// Switch to latest stream
  Stream<S> switchMap<S>(Stream<S> Function(T value) mapper) {
    StreamController<S>? controller;
    StreamSubscription<T>? outerSubscription;
    StreamSubscription<S>? innerSubscription;

    controller = StreamController<S>(
      onListen: () {
        outerSubscription = listen(
          (data) {
            innerSubscription?.cancel();
            innerSubscription = mapper(data).listen(
              controller?.add,
              onError: controller?.addError,
            );
          },
          onError: controller?.addError,
          onDone: () {
            innerSubscription?.cancel();
            controller?.close();
          },
        );
      },
      onCancel: () {
        outerSubscription?.cancel();
        innerSubscription?.cancel();
      },
    );

    return controller.stream;
  }
}

/// Debouncer utility class for manual debouncing
class Debouncer {
  final Duration duration;
  Timer? _timer;

  Debouncer({required this.duration});

  /// Execute callback after debounce duration
  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(duration, callback);
  }

  /// Cancel pending execution
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose the debouncer
  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler utility class for manual throttling
class Throttler {
  final Duration duration;
  Timer? _timer;
  bool _isThrottled = false;

  Throttler({required this.duration});

  /// Execute callback if not throttled
  void call(VoidCallback callback) {
    if (!_isThrottled) {
      callback();
      _isThrottled = true;
      _timer = Timer(duration, () {
        _isThrottled = false;
      });
    }
  }

  /// Cancel throttling
  void cancel() {
    _timer?.cancel();
    _isThrottled = false;
  }

  /// Dispose the throttler
  void dispose() {
    _timer?.cancel();
  }
}
