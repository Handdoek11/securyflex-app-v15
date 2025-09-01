# 🚀 SecuryFlex BLoC Migration - Implementation Guide

## 📋 Phase 1: Foundation Setup (Days 1-3)

### Step 1.1: Create Base Infrastructure

```bash
# Create directory structure
mkdir -p lib/core/bloc
mkdir -p lib/core/utils
mkdir -p lib/core/repositories
```

**Files to create:**
1. `lib/core/bloc/base_bloc.dart` - Base BLoC class
2. `lib/core/bloc/error_handler.dart` - Unified error handling
3. `lib/core/bloc/bloc_observer.dart` - Global BLoC observer
4. `lib/core/utils/bloc_utils.dart` - Utility functions
5. `lib/core/utils/stream_utils.dart` - Stream helpers

### Step 1.2: Update pubspec.yaml Dependencies

```yaml
dependencies:
  # Existing dependencies...
  flutter_bloc: ^9.1.1  # Already present
  bloc_test: ^9.1.1     # Add for testing
  mocktail: ^1.0.4      # Add for mocking
  equatable: ^2.0.7     # Already present
  
dev_dependencies:
  # Existing dev dependencies...
  bloc_test: ^9.1.1
  mocktail: ^1.0.4
```

### Step 1.3: Setup BLoC Observer

```dart
// lib/core/bloc/bloc_observer.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

class SecuryFlexBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    if (kDebugMode) {
      print('🟢 BLoC Created: ${bloc.runtimeType}');
    }
  }

  @override
  void onTransition(BlocBase bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (kDebugMode) {
      print('🔄 ${bloc.runtimeType}: ${transition.event} -> ${transition.nextState}');
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    print('🔴 BLoC Error in ${bloc.runtimeType}: $error');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    if (kDebugMode) {
      print('🔴 BLoC Closed: ${bloc.runtimeType}');
    }
  }
}
```

### Step 1.4: Update main.dart

```dart
// lib/main.dart - Add BLoC observer
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/bloc/bloc_observer.dart';

void main() {
  // Set BLoC observer
  Bloc.observer = SecuryFlexBlocObserver();
  
  runApp(const SecuryFlexApp());
}
```

## 📋 Phase 2: Authentication Migration (Days 4-8)

### Step 2.1: Create Auth BLoC Structure

```bash
mkdir -p lib/auth/bloc
mkdir -p lib/auth/repository
```

**Implementation Order:**
1. Create `AuthEvent` classes
2. Create `AuthState` classes  
3. Create `AuthRepository` interface
4. Implement `AuthBloc`
5. Create parallel authentication flow
6. Migrate widgets gradually

### Step 2.2: Create AuthRepository Interface

```dart
// lib/auth/repository/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<User?> signInWithEmailAndPassword(String email, String password);
  Future<User?> createUserWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<Map<String, dynamic>?> getUserData(String uid);
  Future<void> updateUserData(String uid, Map<String, dynamic> data);
  Stream<User?> get authStateChanges;
  User? get currentUser;
}

// lib/auth/repository/firebase_auth_repository.dart
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }
  
  // Implement other methods...
}
```

### Step 2.3: Parallel Implementation Strategy

```dart
// lib/auth/auth_wrapper.dart - Transition helper
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_service.dart'; // Legacy
import 'bloc/auth_bloc.dart'; // New

class AuthWrapper extends StatelessWidget {
  final Widget child;
  final bool useBlocAuth; // Feature flag
  
  const AuthWrapper({
    super.key,
    required this.child,
    this.useBlocAuth = false, // Start with false, gradually enable
  });

  @override
  Widget build(BuildContext context) {
    if (useBlocAuth) {
      return BlocProvider(
        create: (context) => AuthBloc()..add(AuthInitialize()),
        child: child,
      );
    } else {
      // Use legacy AuthService
      return child;
    }
  }
}
```

### Step 2.4: Widget Migration Pattern

```dart
// Before (StatefulWidget with AuthService)
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  
  Future<void> _login() async {
    setState(() => _isLoading = true);
    final success = await AuthService.login(email, password);
    setState(() => _isLoading = false);
    // Handle result...
  }
}

// After (BlocBuilder with AuthBloc)
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error.localizedMessage)),
          );
        } else if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        
        return Scaffold(
          body: Column(
            children: [
              // Login form...
              UnifiedButton.primary(
                text: 'Inloggen',
                isLoading: isLoading,
                onPressed: isLoading ? null : () {
                  context.read<AuthBloc>().add(
                    AuthLogin(email: email, password: password),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
```

## 📋 Phase 3: Marketplace Migration (Days 9-14)

### Step 3.1: Create Job Repository

```dart
// lib/marketplace/repository/job_repository.dart
abstract class JobRepository {
  Future<List<SecurityJobData>> getJobs();
  Stream<List<SecurityJobData>> watchJobs();
  Future<bool> applyToJob(String jobId, String? message);
  Future<List<String>> getAppliedJobs(String userId);
}

// lib/marketplace/repository/firebase_job_repository.dart
class FirebaseJobRepository implements JobRepository {
  final FirebaseFirestore _firestore;
  
  FirebaseJobRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Stream<List<SecurityJobData>> watchJobs() {
    return _firestore
        .collection('jobs')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SecurityJobData.fromFirestore(doc))
            .toList());
  }
  
  @override
  Future<bool> applyToJob(String jobId, String? message) async {
    try {
      await _firestore.collection('applications').add({
        'jobId': jobId,
        'userId': AuthService.currentUserId, // Will be from AuthBloc later
        'message': message,
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

### Step 3.2: Gradual Widget Migration

```dart
// lib/marketplace/widgets/job_list_widget.dart
class JobListWidget extends StatelessWidget {
  final bool useBlocState; // Feature flag
  
  const JobListWidget({super.key, this.useBlocState = false});

  @override
  Widget build(BuildContext context) {
    if (useBlocState) {
      return BlocBuilder<JobBloc, JobState>(
        builder: (context, state) {
          if (state is JobLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is JobLoaded) {
            return _buildJobList(state.filteredJobs);
          } else if (state is JobError) {
            return Center(child: Text(state.error.localizedMessage));
          }
          return const SizedBox.shrink();
        },
      );
    } else {
      // Legacy implementation with JobStateManager
      return _buildLegacyJobList();
    }
  }
  
  Widget _buildJobList(List<SecurityJobData> jobs) {
    return ListView.builder(
      itemCount: jobs.length,
      itemBuilder: (context, index) => JobCard(job: jobs[index]),
    );
  }
}
```

## 📋 Testing Strategy Implementation

### Step T.1: Setup Test Infrastructure

```dart
// test/helpers/bloc_test_helpers.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockJobRepository extends Mock implements JobRepository {}

// Helper function for creating test widgets with BLoC providers
Widget createTestWidget(Widget child, {List<BlocProvider>? providers}) {
  return MaterialApp(
    theme: SecuryFlexTheme.getTheme(UserRole.guard),
    home: MultiBlocProvider(
      providers: providers ?? [],
      child: child,
    ),
  );
}
```

### Step T.2: Create Test Templates

```dart
// test/auth/bloc/auth_bloc_test.dart
void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      authBloc = AuthBloc(repository: mockRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    group('AuthLogin', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when login succeeds',
        build: () {
          when(() => mockRepository.signInWithEmailAndPassword(any(), any()))
              .thenAnswer((_) async => mockFirebaseUser);
          when(() => mockRepository.getUserData(any()))
              .thenAnswer((_) async => mockUserData);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLogin(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          const AuthLoading(message: 'Inloggen...'),
          AuthAuthenticated(
            firebaseUser: mockFirebaseUser,
            userId: 'test-uid',
            userType: 'guard',
            userName: 'Test User',
            userData: mockUserData,
          ),
        ],
      );
    });
  });
}
```

## 📊 Migration Progress Tracking

### Daily Checklist Template

```markdown
## Day X Progress Checklist

### Phase X: [Phase Name]

#### Completed ✅
- [ ] Task 1
- [ ] Task 2

#### In Progress 🔄
- [ ] Task 3

#### Blocked ❌
- [ ] Task 4 (Reason: ...)

#### Tests ✅
- [ ] Unit tests passing
- [ ] Widget tests passing
- [ ] Integration tests passing

#### Performance ⚡
- [ ] Memory usage within limits
- [ ] Navigation speed maintained
- [ ] No flutter analyze issues

#### Next Day Plan 📋
1. Complete Task 3
2. Start Task 5
3. Address any blockers
```

## 🚨 Common Pitfalls & Solutions

### Pitfall 1: Memory Leaks
**Problem**: Not disposing BLoC streams properly  
**Solution**: Always override `close()` method

```dart
@override
Future<void> close() {
  _subscription?.cancel();
  _timer?.cancel();
  return super.close();
}
```

### Pitfall 2: State Mutation
**Problem**: Modifying state objects directly  
**Solution**: Use copyWith patterns and immutable objects

### Pitfall 3: Excessive Rebuilds
**Problem**: BlocBuilder rebuilding entire widget tree  
**Solution**: Use BlocSelector for specific state properties

```dart
BlocSelector<JobBloc, JobState, List<SecurityJobData>>(
  selector: (state) => state is JobLoaded ? state.filteredJobs : [],
  builder: (context, jobs) => JobList(jobs: jobs),
)
```

This implementation guide provides step-by-step instructions for migrating SecuryFlex to a unified BLoC architecture while maintaining enterprise-grade quality and Dutch business requirements.
