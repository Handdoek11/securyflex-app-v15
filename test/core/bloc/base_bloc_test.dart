import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:securyflex_app/core/bloc/base_bloc.dart';
import 'package:securyflex_app/core/bloc/error_handler.dart';

// Test BLoC implementation for testing base functionality
abstract class TestEvent extends BaseEvent {
  const TestEvent();
}

class TestMessageEvent extends TestEvent {
  final String message;

  const TestMessageEvent(this.message);

  @override
  List<Object> get props => [message];
}

class TestLoadingEvent extends TestEvent {}
class TestErrorEvent extends TestEvent {}
class TestSuccessEvent extends TestEvent {}

abstract class TestState extends BaseState {}

class TestInitial extends TestState {}

class TestLoading extends TestState with LoadingStateMixin {
  @override
  final bool isLoading = true;

  @override
  final String? loadingMessage;

  TestLoading({this.loadingMessage});

  @override
  List<Object?> get props => [loadingMessage];
}

class TestLoaded extends TestState {
  final String data;

  TestLoaded(this.data);

  @override
  List<Object> get props => [data];
}

class TestError extends TestState with ErrorStateMixin {
  @override
  final AppError error;

  TestError(this.error);

  @override
  List<Object> get props => [error];
}

class TestSuccess extends TestState with SuccessStateMixin {
  @override
  final String successMessage;

  TestSuccess(this.successMessage);

  @override
  List<Object> get props => [successMessage];
}

class TestBloc extends BaseBloc<TestEvent, TestState> {
  TestBloc() : super(TestInitial()) {
    on<TestMessageEvent>(_onTestMessageEvent);
    on<TestLoadingEvent>(_onTestLoadingEvent);
    on<TestErrorEvent>(_onTestErrorEvent);
    on<TestSuccessEvent>(_onTestSuccessEvent);
  }

  Future<void> _onTestMessageEvent(TestMessageEvent event, Emitter<TestState> emit) async {
    emit(TestLoaded(event.message));
  }

  Future<void> _onTestLoadingEvent(TestLoadingEvent event, Emitter<TestState> emit) async {
    emit(TestLoading(loadingMessage: 'Test laden...'));
  }

  Future<void> _onTestErrorEvent(TestErrorEvent event, Emitter<TestState> emit) async {
    emit(TestError(AppError(
      code: 'test_error',
      message: 'Test error occurred',
    )));
  }

  Future<void> _onTestSuccessEvent(TestSuccessEvent event, Emitter<TestState> emit) async {
    emit(TestSuccess('Test succesvol voltooid'));
  }
}

void main() {
  group('BaseBloc Tests', () {
    late TestBloc testBloc;

    setUp(() {
      testBloc = TestBloc();
    });

    tearDown(() {
      testBloc.close();
    });

    test('initial state is TestInitial', () {
      expect(testBloc.state, isA<TestInitial>());
    });

    blocTest<TestBloc, TestState>(
      'emits TestLoaded when TestMessageEvent is added',
      build: () => testBloc,
      act: (bloc) => bloc.add(const TestMessageEvent('test message')),
      expect: () => [
        TestLoaded('test message'),
      ],
    );

    blocTest<TestBloc, TestState>(
      'emits TestLoading when TestLoadingEvent is added',
      build: () => testBloc,
      act: (bloc) => bloc.add(TestLoadingEvent()),
      expect: () => [
        TestLoading(loadingMessage: 'Test laden...'),
      ],
    );

    blocTest<TestBloc, TestState>(
      'emits TestError when TestErrorEvent is added',
      build: () => testBloc,
      act: (bloc) => bloc.add(TestErrorEvent()),
      expect: () => [
        isA<TestError>(),
      ],
    );

    blocTest<TestBloc, TestState>(
      'emits TestSuccess when TestSuccessEvent is added',
      build: () => testBloc,
      act: (bloc) => bloc.add(TestSuccessEvent()),
      expect: () => [
        TestSuccess('Test succesvol voltooid'),
      ],
    );

    group('LoadingStateMixin Tests', () {
      test('provides Dutch loading message', () {
        final loadingState = TestLoading();
        expect(loadingState.isLoading, isTrue);
        expect(loadingState.localizedLoadingMessage, equals('Laden...'));
      });

      test('uses custom loading message when provided', () {
        final loadingState = TestLoading(loadingMessage: 'Custom loading...');
        expect(loadingState.localizedLoadingMessage, equals('Custom loading...'));
      });
    });

    group('ErrorStateMixin Tests', () {
      test('provides localized error message', () {
        final errorState = TestError(AppError(
          code: 'network_error',
          message: 'Network failed',
        ));

        expect(errorState.localizedErrorMessage,
               equals('Netwerkfout. Controleer uw internetverbinding.'));
      });
    });

    group('SuccessStateMixin Tests', () {
      test('provides localized success message', () {
        final successState = TestSuccess('Operation completed');
        expect(successState.localizedSuccessMessage,
               equals('Operation completed'));
      });
    });

    group('BlocStatus Tests', () {
      test('BlocStatus enum has correct Dutch descriptions', () {
        expect(BlocStatus.initial.dutchDescription, equals('Initieel'));
        expect(BlocStatus.loading.dutchDescription, equals('Laden'));
        expect(BlocStatus.success.dutchDescription, equals('Succesvol'));
        expect(BlocStatus.error.dutchDescription, equals('Fout'));
      });

      test('BlocStatus boolean getters work correctly', () {
        expect(BlocStatus.initial.isInitial, isTrue);
        expect(BlocStatus.loading.isLoading, isTrue);
        expect(BlocStatus.success.isSuccess, isTrue);
        expect(BlocStatus.error.isError, isTrue);
        
        expect(BlocStatus.initial.isLoading, isFalse);
        expect(BlocStatus.loading.isSuccess, isFalse);
        expect(BlocStatus.success.isError, isFalse);
        expect(BlocStatus.error.isInitial, isFalse);
      });
    });

    group('Common States Tests', () {
      test('CommonLoadingState works correctly', () {
        final loadingState = CommonLoadingState(loadingMessage: 'Loading...');
        expect(loadingState.isLoading, isTrue);
        expect(loadingState.loadingMessage, equals('Loading...'));
        expect(loadingState.localizedLoadingMessage, equals('Loading...'));
      });

      test('CommonErrorState works correctly', () {
        final errorState = CommonErrorState(AppError(
          code: 'test_error',
          message: 'Test error',
        ));
        expect(errorState.error.code, equals('test_error'));
        expect(errorState.localizedErrorMessage, equals('Test error'));
      });

      test('CommonSuccessState works correctly', () {
        final successState = CommonSuccessState('Success!');
        expect(successState.successMessage, equals('Success!'));
        expect(successState.localizedSuccessMessage, equals('Success!'));
      });
    });

    group('Equatable Implementation Tests', () {
      test('BaseEvent equality works correctly', () {
        const event1 = TestMessageEvent('message');
        const event2 = TestMessageEvent('message');
        const event3 = TestMessageEvent('different');

        expect(event1, equals(event2));
        expect(event1, isNot(equals(event3)));
      });

      test('BaseState equality works correctly', () {
        final state1 = TestLoaded('data');
        final state2 = TestLoaded('data');
        final state3 = TestLoaded('different');

        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });

      test('Error states with same error are equal', () {
        final error = AppError(code: 'test', message: 'test');
        final state1 = TestError(error);
        final state2 = TestError(error);

        expect(state1, equals(state2));
      });
    });

    group('toString Implementation Tests', () {
      test('BaseEvent toString returns runtime type', () {
        const event = TestMessageEvent('message');
        expect(event.toString(), equals('TestMessageEvent'));
      });

      test('BaseState toString returns runtime type', () {
        final state = TestLoaded('data');
        expect(state.toString(), equals('TestLoaded'));
      });
    });
  });
}
