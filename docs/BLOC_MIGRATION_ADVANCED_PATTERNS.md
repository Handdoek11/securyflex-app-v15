# 🚀 SecuryFlex BLoC Migration - Advanced Patterns & Optimization

## 🔄 Cross-BLoC Communication Patterns

### Pattern 1: Event Bus Architecture

```dart
// lib/core/events/app_event_bus.dart
import 'dart:async';

abstract class AppEvent {
  const AppEvent();
}

class UserLoggedIn extends AppEvent {
  final String userId;
  final String userType;
  
  const UserLoggedIn({required this.userId, required this.userType});
}

class JobApplicationSubmitted extends AppEvent {
  final String jobId;
  final String userId;
  
  const JobApplicationSubmitted({required this.jobId, required this.userId});
}

class ProfileUpdated extends AppEvent {
  final String userId;
  final Map<String, dynamic> updates;
  
  const ProfileUpdated({required this.userId, required this.updates});
}

class AppEventBus {
  static final _instance = AppEventBus._internal();
  factory AppEventBus() => _instance;
  AppEventBus._internal();
  
  final StreamController<AppEvent> _controller = StreamController.broadcast();
  
  Stream<T> on<T extends AppEvent>() => 
      _controller.stream.where((event) => event is T).cast<T>();
  
  void fire(AppEvent event) => _controller.add(event);
  
  void dispose() => _controller.close();
}
```

### Pattern 2: BLoC-to-BLoC Communication

```dart
// lib/auth/bloc/auth_bloc.dart - Enhanced with event bus
class AuthBloc extends BaseBloc<AuthEvent, AuthState> {
  final AppEventBus _eventBus = AppEventBus();
  
  Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    // ... existing login logic
    
    if (state is AuthAuthenticated) {
      final authState = state as AuthAuthenticated;
      
      // Fire cross-BLoC event
      _eventBus.fire(UserLoggedIn(
        userId: authState.userId,
        userType: authState.userType,
      ));
    }
  }
}

// lib/marketplace/bloc/job_bloc.dart - Listening to auth events
class JobBloc extends BaseBloc<JobEvent, JobState> {
  final AppEventBus _eventBus = AppEventBus();
  StreamSubscription? _authEventSubscription;
  
  JobBloc(JobRepository repository) : super(JobInitial()) {
    // Listen to authentication events
    _authEventSubscription = _eventBus.on<UserLoggedIn>().listen((event) {
      // Reload jobs for the authenticated user
      add(LoadJobs());
    });
    
    // Listen to profile updates
    _eventBus.on<ProfileUpdated>().listen((event) {
      // Refresh user-specific job data
      add(RefreshUserJobs(event.userId));
    });
  }
  
  @override
  Future<void> close() {
    _authEventSubscription?.cancel();
    return super.close();
  }
}
```

### Pattern 3: Repository-Level Communication

```dart
// lib/core/repositories/base_repository.dart
abstract class BaseRepository {
  final AppEventBus _eventBus = AppEventBus();
  
  void fireEvent(AppEvent event) => _eventBus.fire(event);
  Stream<T> listenToEvent<T extends AppEvent>() => _eventBus.on<T>();
}

// lib/marketplace/repository/firebase_job_repository.dart
class FirebaseJobRepository extends BaseRepository implements JobRepository {
  @override
  Future<bool> applyToJob(String jobId, String? message) async {
    try {
      // ... application logic
      
      // Fire event for other BLoCs to react
      fireEvent(JobApplicationSubmitted(
        jobId: jobId,
        userId: AuthService.currentUserId,
      ));
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

## ⚡ Performance Optimization Patterns

### Pattern 1: Selective State Updates with BlocSelector

```dart
// Instead of rebuilding entire widget tree
BlocBuilder<JobBloc, JobState>(
  builder: (context, state) {
    if (state is JobLoaded) {
      return Column(
        children: [
          JobCounter(count: state.filteredJobs.length), // Rebuilds unnecessarily
          JobList(jobs: state.filteredJobs),            // Rebuilds unnecessarily
          FilterSummary(filters: state.filters),        // Rebuilds unnecessarily
        ],
      );
    }
    return const SizedBox.shrink();
  },
)

// Use BlocSelector for specific state properties
Column(
  children: [
    BlocSelector<JobBloc, JobState, int>(
      selector: (state) => state is JobLoaded ? state.filteredJobs.length : 0,
      builder: (context, count) => JobCounter(count: count),
    ),
    BlocSelector<JobBloc, JobState, List<SecurityJobData>>(
      selector: (state) => state is JobLoaded ? state.filteredJobs : [],
      builder: (context, jobs) => JobList(jobs: jobs),
    ),
    BlocSelector<JobBloc, JobState, JobFilter>(
      selector: (state) => state is JobLoaded ? state.filters : const JobFilter(),
      builder: (context, filters) => FilterSummary(filters: filters),
    ),
  ],
)
```

### Pattern 2: Debounced Search Implementation

```dart
// lib/core/utils/debouncer.dart
class Debouncer {
  final int milliseconds;
  Timer? _timer;
  
  Debouncer({required this.milliseconds});
  
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
  
  void dispose() {
    _timer?.cancel();
  }
}

// lib/marketplace/bloc/job_bloc.dart - Debounced search
class JobBloc extends BaseBloc<JobEvent, JobState> {
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);
  
  JobBloc(JobRepository repository) : super(JobInitial()) {
    on<SearchJobs>(_onSearchJobs);
  }
  
  Future<void> _onSearchJobs(SearchJobs event, Emitter<JobState> emit) async {
    // Debounce search to avoid excessive API calls
    _searchDebouncer.run(() {
      add(FilterJobs(searchQuery: event.query));
    });
  }
  
  @override
  Future<void> close() {
    _searchDebouncer.dispose();
    return super.close();
  }
}
```

### Pattern 3: Stream Optimization with RxDart

```dart
// pubspec.yaml
dependencies:
  rxdart: ^0.28.0

// lib/marketplace/bloc/job_bloc.dart - Enhanced with RxDart
import 'package:rxdart/rxdart.dart';

class JobBloc extends BaseBloc<JobEvent, JobState> {
  final JobRepository _repository;
  StreamSubscription? _jobsSubscription;
  
  JobBloc(this._repository) : super(JobInitial()) {
    on<SearchJobs>(
      _onSearchJobs,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .distinct()
          .switchMap(mapper),
    );
    
    on<FilterJobs>(
      _onFilterJobs,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 150))
          .switchMap(mapper),
    );
  }
  
  Future<void> _onWatchJobs(WatchJobs event, Emitter<JobState> emit) async {
    await _jobsSubscription?.cancel();
    
    _jobsSubscription = _repository
        .watchJobs()
        .distinct() // Avoid duplicate emissions
        .listen(
          (jobs) => add(JobsUpdated(jobs)),
          onError: (error) => add(JobError(ErrorHandler.fromException(error))),
        );
  }
}
```

### Pattern 4: Memory-Efficient List Management

```dart
// lib/marketplace/widgets/job_list_widget.dart
class JobListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<JobBloc, JobState, List<SecurityJobData>>(
      selector: (state) => state is JobLoaded ? state.filteredJobs : [],
      builder: (context, jobs) {
        if (jobs.isEmpty) {
          return const EmptyJobsWidget();
        }
        
        // Use ListView.builder for memory efficiency with large lists
        return ListView.builder(
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            
            // Use const constructors where possible
            return JobCard(
              key: ValueKey(job.jobId), // Stable keys for performance
              job: job,
            );
          },
          // Add caching for better performance
          cacheExtent: 1000, // Cache 1000 pixels ahead
        );
      },
    );
  }
}
```

## 🔄 Real-time Data Synchronization

### Pattern 1: Firebase Stream Integration

```dart
// lib/marketplace/repository/firebase_job_repository.dart
class FirebaseJobRepository implements JobRepository {
  final FirebaseFirestore _firestore;
  final StreamController<List<SecurityJobData>> _jobsController = 
      StreamController<List<SecurityJobData>>.broadcast();
  
  StreamSubscription? _firestoreSubscription;
  
  @override
  Stream<List<SecurityJobData>> watchJobs() {
    _firestoreSubscription?.cancel();
    
    _firestoreSubscription = _firestore
        .collection('jobs')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SecurityJobData.fromFirestore(doc))
            .toList())
        .listen(
          (jobs) => _jobsController.add(jobs),
          onError: (error) => _jobsController.addError(error),
        );
    
    return _jobsController.stream;
  }
  
  void dispose() {
    _firestoreSubscription?.cancel();
    _jobsController.close();
  }
}
```

### Pattern 2: Offline-First Architecture

```dart
// lib/core/repositories/offline_repository.dart
abstract class OfflineRepository<T> {
  Future<List<T>> getCachedData();
  Future<void> cacheData(List<T> data);
  Future<List<T>> getRemoteData();
  Stream<List<T>> watchData();
}

// lib/marketplace/repository/offline_job_repository.dart
class OfflineJobRepository implements JobRepository {
  final FirebaseJobRepository _remoteRepository;
  final LocalJobRepository _localRepository;
  final ConnectivityService _connectivity;
  
  OfflineJobRepository({
    required FirebaseJobRepository remoteRepository,
    required LocalJobRepository localRepository,
    required ConnectivityService connectivity,
  }) : _remoteRepository = remoteRepository,
       _localRepository = localRepository,
       _connectivity = connectivity;
  
  @override
  Stream<List<SecurityJobData>> watchJobs() async* {
    // Always start with cached data
    final cachedJobs = await _localRepository.getJobs();
    yield cachedJobs;
    
    // If online, get fresh data and update cache
    if (await _connectivity.isConnected) {
      try {
        await for (final remoteJobs in _remoteRepository.watchJobs()) {
          await _localRepository.cacheJobs(remoteJobs);
          yield remoteJobs;
        }
      } catch (e) {
        // Fall back to cached data on error
        yield cachedJobs;
      }
    }
  }
}
```

## 🧪 Advanced Testing Patterns

### Pattern 1: BLoC Integration Testing

```dart
// test/integration/job_application_flow_test.dart
void main() {
  group('Job Application Flow Integration', () {
    late AuthBloc authBloc;
    late JobBloc jobBloc;
    late MockAuthRepository mockAuthRepo;
    late MockJobRepository mockJobRepo;
    
    setUp(() {
      mockAuthRepo = MockAuthRepository();
      mockJobRepo = MockJobRepository();
      authBloc = AuthBloc(repository: mockAuthRepo);
      jobBloc = JobBloc(repository: mockJobRepo);
    });
    
    testWidgets('complete job application flow', (tester) async {
      // Setup mocks
      when(() => mockAuthRepo.signInWithEmailAndPassword(any(), any()))
          .thenAnswer((_) async => mockUser);
      when(() => mockJobRepo.applyToJob(any(), any()))
          .thenAnswer((_) async => true);
      
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: authBloc),
            BlocProvider.value(value: jobBloc),
          ],
          child: const MaterialApp(home: JobApplicationScreen()),
        ),
      );
      
      // Test login
      authBloc.add(const AuthLogin(email: 'test@test.com', password: 'password'));
      await tester.pump();
      
      // Verify authenticated state
      expect(authBloc.state, isA<AuthAuthenticated>());
      
      // Test job application
      jobBloc.add(const ApplyToJob(jobId: 'SJ001'));
      await tester.pump();
      
      // Verify application success
      expect(jobBloc.state, isA<JobApplicationSuccess>());
    });
  });
}
```

### Pattern 2: Performance Testing

```dart
// test/performance/bloc_performance_test.dart
void main() {
  group('BLoC Performance Tests', () {
    test('JobBloc handles 1000 filter events efficiently', () async {
      final repository = MockJobRepository();
      final bloc = JobBloc(repository);
      final stopwatch = Stopwatch()..start();
      
      // Simulate rapid filter changes
      for (int i = 0; i < 1000; i++) {
        bloc.add(FilterJobs(searchQuery: 'query$i'));
      }
      
      // Wait for all events to process
      await Future.delayed(const Duration(seconds: 2));
      
      stopwatch.stop();
      
      // Should handle 1000 events in under 2 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      
      bloc.close();
    });
    
    test('Memory usage remains stable during stream operations', () async {
      final repository = MockJobRepository();
      final bloc = JobBloc(repository);
      
      // Monitor memory usage
      final initialMemory = ProcessInfo.currentRss;
      
      // Simulate continuous data updates
      for (int i = 0; i < 100; i++) {
        bloc.add(JobsUpdated(generateMockJobs(100)));
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      final finalMemory = ProcessInfo.currentRss;
      final memoryIncrease = finalMemory - initialMemory;
      
      // Memory increase should be reasonable (< 50MB)
      expect(memoryIncrease, lessThan(50 * 1024 * 1024));
      
      bloc.close();
    });
  });
}
```

## 📊 Monitoring & Analytics

### Pattern 1: BLoC Analytics

```dart
// lib/core/analytics/bloc_analytics.dart
class BlocAnalytics {
  static void trackBlocEvent(String blocName, String eventName) {
    // Send to analytics service
    FirebaseAnalytics.instance.logEvent(
      name: 'bloc_event',
      parameters: {
        'bloc_name': blocName,
        'event_name': eventName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  static void trackBlocError(String blocName, String error) {
    FirebaseCrashlytics.instance.recordError(
      'BLoC Error in $blocName: $error',
      null,
      fatal: false,
    );
  }
}

// Enhanced BaseBloc with analytics
abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  BaseBloc(super.initialState);
  
  @override
  void onTransition(Transition<Event, State> transition) {
    super.onTransition(transition);
    
    // Track important events
    BlocAnalytics.trackBlocEvent(
      runtimeType.toString(),
      transition.event.runtimeType.toString(),
    );
  }
  
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    BlocAnalytics.trackBlocError(bloc.runtimeType.toString(), error.toString());
    super.onError(bloc, error, stackTrace);
  }
}
```

This advanced patterns guide provides enterprise-grade solutions for cross-BLoC communication, performance optimization, real-time synchronization, and comprehensive testing strategies for the SecuryFlex BLoC migration.
