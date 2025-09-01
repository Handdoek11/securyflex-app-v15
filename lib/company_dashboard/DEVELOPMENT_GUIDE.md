# Company Dashboard Development Guide

## Quick Start

### Prerequisites
- Flutter 3.16+ installed
- Firebase project configured
- `.env` file with Firebase credentials

### Running the Dashboard
```bash
# Install dependencies
flutter pub get

# Run with environment variables
flutter run --dart-define-from-file=.env

# Run tests
flutter test test/company_dashboard/
```

## Code Standards

### 1. File Organization

```dart
// Standard import order
import 'dart:async';                        // Dart SDK
import 'package:flutter/material.dart';     // Flutter
import 'package:flutter_bloc/flutter_bloc.dart'; // Third-party packages
import '../../unified_design_tokens.dart';  // Project imports (absolute)
import '../bloc/bloc.dart';                 // Feature imports (relative)
```

### 2. Widget Structure

```dart
/// Documentation comment explaining widget purpose
class MyWidget extends StatelessWidget {
  // Required parameters first
  final String title;
  final DashboardState state;
  
  // Optional parameters with defaults
  final VoidCallback? onTap;
  final Color? backgroundColor;
  
  const MyWidget({
    super.key,
    required this.title,
    required this.state,
    this.onTap,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    // Logic here
  }
}
```

### 3. BLoC Event Naming

```dart
// Events should be past tense verbs
class JobCreated extends DashboardEvent { }
class FilterApplied extends DashboardEvent { }
class NavigationChanged extends DashboardEvent { }

// NOT: CreateJob, ApplyFilter, ChangeNavigation
```

### 4. State Management Patterns

```dart
// Always use copyWith for state updates
emit(state.copyWith(
  status: DashboardStatus.loading,
  selectedItems: {...state.selectedItems, newItem},
));

// Never modify state directly
// BAD: state.selectedItems.add(newItem);
```

## Common Tasks

### Adding a New Dashboard Section

1. **Create the content widget:**
```dart
// lib/company_dashboard/widgets/new_section_content.dart
class NewSectionContent extends StatelessWidget {
  final DashboardState dashboardState;
  
  const NewSectionContent({
    super.key,
    required this.dashboardState,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: // Your content here
    );
  }
}
```

2. **Add navigation item:**
```dart
// In desktop_sidebar.dart
_buildNavigationItem(
  icon: Icons.new_icon,
  label: 'New Section',
  index: 7, // Next available index
  isSelected: dashboardState.selectedNavigationIndex == 7,
),
```

3. **Update content switching:**
```dart
// In responsive_company_dashboard.dart
case 7:
  return NewSectionContent(
    dashboardState: dashboardState,
  );
```

### Adding Animations

Always use SharedAnimationManager:

```dart
class AnimatedCard extends StatefulWidget {
  const AnimatedCard({super.key});
  
  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> 
    with SharedAnimationMixin {
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: fadeInAnimation.value,
          child: Card(
            child: child,
          ),
        );
      },
      child: _buildCardContent(),
    );
  }
  
  Widget _buildCardContent() {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Text('Animated content'),
    );
  }
}
```

### Handling Multi-Select

```dart
// Enable multi-select mode
context.read<CompanyDashboardBloc>().add(
  const MultiSelectToggled(true)
);

// Select/deselect items
context.read<CompanyDashboardBloc>().add(
  ItemSelectionChanged({...selectedIds, newId})
);

// Clear selection
context.read<CompanyDashboardBloc>().add(
  const ItemSelectionChanged(<String>{})
);
```

### Adding Filters

```dart
// Dispatch filter event
context.read<CompanyDashboardBloc>().add(
  FiltersApplied({
    'status': 'active',
    'dateRange': DateTimeRange(start, end),
    'location': 'Amsterdam',
  })
);

// Access filters in widget
BlocBuilder<CompanyDashboardBloc, DashboardState>(
  buildWhen: (prev, curr) => prev.filters != curr.filters,
  builder: (context, state) {
    final activeFilters = state.filters;
    // Apply filters to data
  },
);
```

## Testing Guidelines

### 1. Unit Tests

```dart
group('CompanyDashboardBloc', () {
  late CompanyDashboardBloc bloc;
  
  setUp(() {
    bloc = CompanyDashboardBloc();
  });
  
  tearDown(() {
    bloc.close();
  });
  
  test('initial state is correct', () {
    expect(bloc.state, equals(const DashboardState()));
  });
  
  blocTest<CompanyDashboardBloc, DashboardState>(
    'emits loading then success when data loaded',
    build: () => bloc,
    act: (bloc) => bloc.add(const DashboardRefreshed()),
    expect: () => [
      const DashboardState(status: DashboardStatus.loading),
      const DashboardState(status: DashboardStatus.success),
    ],
  );
});
```

### 2. Widget Tests

```dart
testWidgets('renders correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => CompanyDashboardBloc(),
        child: const MyWidget(
          title: 'Test',
          state: DashboardState(),
        ),
      ),
    ),
  );
  
  expect(find.text('Test'), findsOneWidget);
});
```

### 3. Integration Tests

```dart
testWidgets('navigation flow works', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Navigate to jobs
  await tester.tap(find.text('Jobs'));
  await tester.pumpAndSettle();
  
  expect(find.byType(JobsManagementContent), findsOneWidget);
});
```

## Performance Optimization

### 1. Use Selective Rebuilds

```dart
BlocBuilder<CompanyDashboardBloc, DashboardState>(
  // Only rebuild when specific fields change
  buildWhen: (previous, current) => 
    previous.selectedItems != current.selectedItems,
  builder: (context, state) {
    return _buildContent(state.selectedItems);
  },
);
```

### 2. Implement Lazy Loading

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    // Items built on demand
    return ListTile(title: Text(items[index]));
  },
);
```

### 3. Cache Expensive Computations

```dart
final _cache = <String, dynamic>{};

dynamic getExpensiveData(String key) {
  return _cache[key] ??= _computeExpensiveData(key);
}
```

## Debugging Tips

### 1. BLoC State Debugging

```dart
// Add logging to BLoC
class CompanyDashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  CompanyDashboardBloc() : super(const DashboardState()) {
    on<NavigationChanged>((event, emit) {
      if (kDebugMode) {
        print('Navigation changed to: ${event.index}');
      }
      emit(state.copyWith(selectedNavigationIndex: event.index));
    });
  }
}
```

### 2. Animation Debugging

```dart
// Check animation cache
if (kDebugMode) {
  final stats = SharedAnimationManager.instance.getCacheStats();
  print('Animation cache: $stats');
}
```

### 3. Performance Monitoring

```dart
// Wrap expensive operations
final stopwatch = Stopwatch()..start();
await expensiveOperation();
if (kDebugMode) {
  print('Operation took: ${stopwatch.elapsedMilliseconds}ms');
}
```

## Common Pitfalls to Avoid

### ❌ DON'T

1. **Create AnimationControllers directly**
   ```dart
   // WRONG
   _controller = AnimationController(vsync: this);
   ```

2. **Use setState in new components**
   ```dart
   // WRONG
   setState(() {
     _isLoading = true;
   });
   ```

3. **Forget to dispose resources**
   ```dart
   // WRONG - Missing disposal
   Timer? _timer;
   // No dispose method
   ```

4. **Mix business logic with UI**
   ```dart
   // WRONG
   Widget build(context) {
     final data = FirebaseFirestore.instance.collection('jobs').get();
     // ...
   }
   ```

### ✅ DO

1. **Use SharedAnimationManager**
   ```dart
   // CORRECT
   with SharedAnimationMixin
   ```

2. **Use BLoC for state**
   ```dart
   // CORRECT
   context.read<CompanyDashboardBloc>().add(LoadData());
   ```

3. **Properly dispose resources**
   ```dart
   // CORRECT
   @override
   void dispose() {
     _timer?.cancel();
     super.dispose();
   }
   ```

4. **Separate concerns**
   ```dart
   // CORRECT - Use services/repositories
   final data = await jobRepository.getJobs();
   ```

## Getting Help

### Resources
- Architecture documentation: `ARCHITECTURE.md`
- Design tokens: `lib/unified_design_tokens.dart`
- Theme system: `lib/unified_theme_system.dart`

### Contact
- Technical Lead: Check CLAUDE.md for project guidelines
- Code Reviews: Submit PR with tests and documentation

## Version History

- **v2.0.0** - Complete BLoC refactoring with SharedAnimationManager
- **v1.5.0** - Component extraction and modularization
- **v1.0.0** - Initial dashboard implementation

---

*Keep this guide updated as patterns evolve*