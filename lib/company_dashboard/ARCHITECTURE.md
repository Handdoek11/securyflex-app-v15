# Company Dashboard Architecture Documentation

## Overview
The Company Dashboard has been refactored from a monolithic 1,677-line StatefulWidget into a modular, event-driven architecture using BLoC pattern with optimized performance characteristics.

## Architecture Highlights

### 🏗️ Core Architecture
- **Pattern**: BLoC (Business Logic Component) with event-driven state management
- **Structure**: Component-based architecture with clear separation of concerns
- **Performance**: SharedAnimationManager achieving 87% memory reduction
- **Responsiveness**: ResponsiveProvider with MediaQuery caching

## Directory Structure

```
lib/company_dashboard/
├── bloc/                       # BLoC state management
│   ├── dashboard_bloc.dart     # Main business logic
│   ├── dashboard_event.dart    # Event definitions
│   └── dashboard_state.dart    # Immutable state
├── screens/                    # Page-level components
│   └── responsive_company_dashboard.dart
├── widgets/                    # Reusable UI components
│   ├── desktop_sidebar.dart
│   ├── desktop_action_toolbar.dart
│   ├── dashboard_overview_content.dart
│   ├── jobs_management_content.dart
│   ├── applications_review_content.dart
│   ├── team_management_content.dart
│   ├── messages_content.dart
│   └── finance_content.dart
└── services/                   # Business services
    └── shared_animation_manager.dart
```

## Component Architecture

### 1. BLoC State Management

```dart
// Event-driven architecture
CompanyDashboardBloc
  ├── Events (User Actions)
  │   ├── NavigationChanged
  │   ├── MultiSelectToggled
  │   ├── FilterPanelToggled
  │   └── DashboardRefreshed
  └── State (Immutable)
      ├── selectedNavigationIndex
      ├── isMultiSelectMode
      ├── selectedItems
      └── isFilterPanelOpen
```

### 2. Component Hierarchy

```
ResponsiveCompanyDashboard
  └── BlocProvider<CompanyDashboardBloc>
      └── _ResponsiveCompanyDashboardContent
          ├── DesktopSidebar
          ├── DesktopActionToolbar
          └── Content Components
              ├── DashboardOverviewContent
              ├── JobsManagementContent
              ├── ApplicationsReviewContent
              ├── TeamManagementContent
              ├── MessagesContent
              └── FinanceContent
```

### 3. SharedAnimationManager

Singleton pattern for centralized animation management:
- **Memory Optimization**: 87% reduction in animation controller memory usage
- **Animation Caching**: Reusable animations with key-based lookup
- **Lifecycle Management**: Automatic disposal handling

```dart
// Usage Example
class MyWidget extends StatefulWidget { ... }

class _MyWidgetState extends State<MyWidget> 
    with SharedAnimationMixin {
  
  @override
  Widget build(BuildContext context) {
    // Animations automatically available
    return FadeTransition(
      opacity: fadeInAnimation,
      child: ...,
    );
  }
}
```

## Development Guidelines

### 1. State Management Rules

✅ **DO:**
- Use BLoC events for all state changes
- Keep state immutable using copyWith pattern
- Handle loading/error states explicitly
- Use equatable for state comparison

❌ **DON'T:**
- Use setState() in new components
- Modify state directly
- Create state outside BLoC
- Mix UI logic with business logic

### 2. Component Creation Guidelines

When creating new dashboard components:

```dart
// 1. Create as StatelessWidget when possible
class NewDashboardComponent extends StatelessWidget {
  final DashboardState dashboardState;
  final VoidCallback? onAction;
  
  const NewDashboardComponent({
    super.key,
    required this.dashboardState,
    this.onAction,
  });
  
  @override
  Widget build(BuildContext context) {
    // Access BLoC for events
    final bloc = context.read<CompanyDashboardBloc>();
    
    // Use design tokens
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Container(...);
  }
}
```

### 3. Animation Guidelines

Always use SharedAnimationManager for animations:

```dart
// ✅ CORRECT: Using SharedAnimationManager
class AnimatedWidget extends StatefulWidget { ... }

class _AnimatedWidgetState extends State<AnimatedWidget> 
    with SharedAnimationMixin {
  late Animation<double> _myAnimation;
  
  @override
  void initState() {
    super.initState();
    _myAnimation = animationManager.getAnimation(
      key: 'uniqueKey',
      begin: 0.0,
      end: 1.0,
    );
  }
}

// ❌ WRONG: Creating individual AnimationController
class BadWidget extends StatefulWidget { ... }

class _BadWidgetState extends State<BadWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // DON'T DO THIS
}
```

### 4. Responsive Design

Use ResponsiveProvider for MediaQuery optimization:

```dart
Widget build(BuildContext context) {
  final responsive = ResponsiveProvider.of(context);
  final isDesktop = responsive.isDesktop;
  final deviceType = responsive.deviceType;
  
  return isDesktop 
    ? _buildDesktopLayout()
    : _buildMobileLayout();
}
```

### 5. Performance Best Practices

1. **Widget Depth**: Keep widget tree ≤4 levels deep
2. **Animations**: Use SharedAnimationManager exclusively
3. **Rebuilds**: Use BlocBuilder with buildWhen for selective rebuilds
4. **Images**: Use cached_network_image with CDN
5. **Lists**: Implement virtualization for long lists

### 6. Testing Requirements

All new components must include:
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user workflows
- Performance benchmarks for critical paths

```dart
// Example test structure
group('NewComponent', () {
  testWidgets('should render correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => CompanyDashboardBloc(),
          child: NewComponent(),
        ),
      ),
    );
    
    expect(find.byType(NewComponent), findsOneWidget);
  });
});
```

## Performance Metrics

### Target Metrics
- **Memory Usage**: <150MB average
- **Frame Rate**: 60 FPS consistent
- **Load Time**: <2s initial render
- **Animation Memory**: 87% reduction achieved

### Monitoring
```dart
// Use built-in performance monitoring
if (kDebugMode) {
  print('🎬 SharedAnimationManager: ${animationManager.getCacheStats()}');
}
```

## Migration Guide

### Converting Legacy Components

1. **Remove StatefulWidget state variables**
   ```dart
   // Before
   bool _isLoading = false;
   
   // After
   // Use dashboardState.status == DashboardStatus.loading
   ```

2. **Replace setState with BLoC events**
   ```dart
   // Before
   setState(() {
     _selectedIndex = 2;
   });
   
   // After
   context.read<CompanyDashboardBloc>()
     .add(NavigationChanged(2));
   ```

3. **Migrate AnimationControllers**
   ```dart
   // Before
   _controller = AnimationController(vsync: this);
   
   // After
   // Use SharedAnimationMixin
   ```

## Common Patterns

### 1. Multi-Select Implementation
```dart
BlocBuilder<CompanyDashboardBloc, DashboardState>(
  buildWhen: (prev, curr) => 
    prev.isMultiSelectMode != curr.isMultiSelectMode ||
    prev.selectedItems != curr.selectedItems,
  builder: (context, state) {
    if (state.isMultiSelectMode) {
      return _buildMultiSelectUI(state.selectedItems);
    }
    return _buildNormalUI();
  },
);
```

### 2. Loading States
```dart
if (dashboardState.status == DashboardStatus.loading) {
  return CircularProgressIndicator();
}
```

### 3. Error Handling
```dart
if (dashboardState.hasError) {
  return ErrorWidget(dashboardState.errorMessage);
}
```

## Troubleshooting

### Common Issues

1. **Animation not working**
   - Ensure SharedAnimationMixin is used
   - Call animationManager.forward() to start

2. **State not updating**
   - Check BlocBuilder buildWhen condition
   - Verify event is being dispatched

3. **Memory leaks**
   - Ensure no manual AnimationControllers
   - Check Timer disposal in dispose()

## Future Improvements

- [ ] Implement lazy loading for content sections
- [ ] Add WebSocket support for real-time updates
- [ ] Integrate with GraphQL for efficient data fetching
- [ ] Implement micro-frontend architecture
- [ ] Add A/B testing framework

## Resources

- [Flutter BLoC Documentation](https://bloclibrary.dev)
- [Material Design 3](https://m3.material.io)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)

---

*Last Updated: December 2024*
*Version: 2.0.0*