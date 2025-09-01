import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/base_bloc.dart';
import '../../core/bloc/error_handler.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

/// Navigation BLoC for SecuryFlex
/// Manages navigation state, tab switching, and navigation history with role-based configuration
class NavigationBloc extends BaseBloc<NavigationEvent, NavigationState> {
  final AuthBloc? _authBloc;
  StreamSubscription<AuthState>? _authSubscription;
  
  NavigationBloc({
    AuthBloc? authBloc,
  }) : _authBloc = authBloc,
        super(const NavigationInitial()) {
    
    // Register event handlers
    on<NavigationInitialize>(_onInitialize);
    on<NavigateToTab>(_onNavigateToTab);
    on<NavigateToScreen>(_onNavigateToScreen);
    on<NavigateBack>(_onNavigateBack);
    on<UpdateTabBadge>(_onUpdateTabBadge);
    on<UpdateNavigationHistory>(_onUpdateNavigationHistory);
    on<ClearNavigationHistory>(_onClearNavigationHistory);
    on<SetNavigationLoading>(_onSetNavigationLoading);
    on<HandleDeepLink>(_onHandleDeepLink);
    on<UpdateNotificationBadges>(_onUpdateNotificationBadges);
    on<ResetNavigation>(_onResetNavigation);
    on<UpdateUserRole>(_onUpdateUserRole);
    on<NavigationErrorOccurred>(_onNavigationError);
    
    // Listen to auth state changes
    _authSubscription = _authBloc?.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        add(NavigationInitialize(
          userRole: authState.userType,
          userId: authState.userId,
        ));
      } else if (authState is AuthUnauthenticated) {
        add(const ResetNavigation());
      }
    });
    
    // Initialize if already authenticated
    if (_authBloc?.state is AuthAuthenticated) {
      final authState = _authBloc!.state as AuthAuthenticated;
      add(NavigationInitialize(
        userRole: authState.userType,
        userId: authState.userId,
      ));
    }
  }
  
  /// Initialize navigation for user role
  Future<void> _onInitialize(NavigationInitialize event, Emitter<NavigationState> emit) async {
    emit(const NavigationLoading(loadingMessage: 'Navigatie initialiseren...'));
    
    try {
      final tabs = NavigationConfig.getTabsForRole(event.userRole);
      
      emit(NavigationReady(
        userRole: event.userRole,
        userId: event.userId,
        currentTabIndex: 0,
        tabs: tabs,
        tabBadgeCounts: {},
        navigationHistory: [],
        currentScreenName: tabs.first.screenName,
        currentScreenArguments: tabs.first.defaultArguments,
      ));
      
      debugPrint('Navigation initialized for ${event.userRole} with ${tabs.length} tabs');
    } catch (e) {
      emit(NavigationError(
        error: ErrorHandler.fromException(e),
      ));
    }
  }
  
  /// Navigate to specific tab
  Future<void> _onNavigateToTab(NavigateToTab event, Emitter<NavigationState> emit) async {
    if (state is NavigationReady) {
      final currentState = state as NavigationReady;
      
      if (event.tabIndex < 0 || event.tabIndex >= currentState.tabs.length) {
        emit(NavigationError(
          error: AppError(
            code: 'invalid_tab_index',
            message: 'Invalid tab index: ${event.tabIndex}',
            category: ErrorCategory.general,
          ),
        ));
        return;
      }
      
      final selectedTab = currentState.tabs[event.tabIndex];
      
      if (!selectedTab.isEnabled) {
        emit(NavigationError(
          error: AppError(
            code: 'tab_disabled',
            message: 'Tab is disabled: ${selectedTab.dutchLabel}',
            category: ErrorCategory.general,
          ),
        ));
        return;
      }
      
      // Clear navigation history when switching tabs
      emit(currentState.copyWith(
        currentTabIndex: event.tabIndex,
        currentScreenName: selectedTab.screenName,
        currentScreenArguments: selectedTab.defaultArguments,
        navigationHistory: [],
      ));
      
      debugPrint('Navigated to tab: ${selectedTab.dutchLabel} (${event.tabIndex})');
    }
  }
  
  /// Navigate to specific screen
  Future<void> _onNavigateToScreen(NavigateToScreen event, Emitter<NavigationState> emit) async {
    if (state is NavigationReady) {
      final currentState = state as NavigationReady;
      
      try {
        List<NavigationHistoryItem> newHistory = List.from(currentState.navigationHistory);
        
        // Add current screen to history if not replacing
        if (!event.replaceCurrentRoute && currentState.currentScreenName != null) {
          final currentTab = currentState.currentTab;
          newHistory.add(NavigationHistoryItem(
            screenName: currentState.currentScreenName!,
            displayName: currentTab.dutchLabel,
            arguments: currentState.currentScreenArguments,
            timestamp: DateTime.now(),
          ));
          
          // Limit history to last 10 items
          if (newHistory.length > 10) {
            newHistory = newHistory.sublist(newHistory.length - 10);
          }
        }
        
        emit(currentState.copyWith(
          currentScreenName: event.screenName,
          currentScreenArguments: event.arguments,
          navigationHistory: newHistory,
        ));
        
        debugPrint('Navigated to screen: ${event.screenName}');
      } catch (e) {
        emit(NavigationError(
          error: ErrorHandler.fromException(e),
          failedScreenName: event.screenName,
        ));
      }
    }
  }
  
  /// Navigate back to previous screen
  Future<void> _onNavigateBack(NavigateBack event, Emitter<NavigationState> emit) async {
    if (state is NavigationReady) {
      final currentState = state as NavigationReady;
      
      if (currentState.navigationHistory.isEmpty) {
        // No history, stay on current tab
        return;
      }
      
      try {
        final previousItem = currentState.navigationHistory.last;
        final newHistory = List<NavigationHistoryItem>.from(currentState.navigationHistory)
          ..removeLast();
        
        emit(currentState.copyWith(
          currentScreenName: previousItem.screenName,
          currentScreenArguments: previousItem.arguments,
          navigationHistory: newHistory,
        ));
        
        debugPrint('Navigated back to: ${previousItem.displayName}');
      } catch (e) {
        emit(NavigationError(
          error: ErrorHandler.fromException(e),
        ));
      }
    }
  }
  
  /// Update badge count for specific tab
  Future<void> _onUpdateTabBadge(UpdateTabBadge event, Emitter<NavigationState> emit) async {
    if (state is NavigationReady) {
      final currentState = state as NavigationReady;
      
      final newBadgeCounts = Map<int, int>.from(currentState.tabBadgeCounts);
      
      if (event.badgeCount > 0) {
        newBadgeCounts[event.tabIndex] = event.badgeCount;
      } else {
        newBadgeCounts.remove(event.tabIndex);
      }
      
      emit(currentState.copyWith(tabBadgeCounts: newBadgeCounts));
      
      debugPrint('Updated badge for tab ${event.tabIndex}: ${event.badgeCount}');
    }
  }
  
  /// Update navigation history
  Future<void> _onUpdateNavigationHistory(UpdateNavigationHistory event, Emitter<NavigationState> emit) async {
    if (state is NavigationReady) {
      final currentState = state as NavigationReady;
      
      final newHistory = List<NavigationHistoryItem>.from(currentState.navigationHistory);
      newHistory.add(NavigationHistoryItem(
        screenName: event.screenName,
        displayName: event.screenName, // Could be improved with proper display names
        arguments: event.arguments,
        timestamp: DateTime.now(),
      ));
      
      // Limit history
      if (newHistory.length > 10) {
        newHistory.removeAt(0);
      }
      
      emit(currentState.copyWith(navigationHistory: newHistory));
    }
  }
  
  /// Clear navigation history
  Future<void> _onClearNavigationHistory(ClearNavigationHistory event, Emitter<NavigationState> emit) async {
    if (state is NavigationReady) {
      final currentState = state as NavigationReady;
      emit(currentState.copyWith(navigationHistory: []));
      debugPrint('Navigation history cleared');
    }
  }
  
  /// Set navigation loading state
  Future<void> _onSetNavigationLoading(SetNavigationLoading event, Emitter<NavigationState> emit) async {
    if (state is NavigationReady) {
      final currentState = state as NavigationReady;
      emit(currentState.copyWith(
        isLoading: event.isLoading,
        loadingMessage: event.loadingMessage,
      ));
    } else if (event.isLoading) {
      emit(NavigationLoading(loadingMessage: event.loadingMessage));
    }
  }
  
  /// Handle deep link navigation
  Future<void> _onHandleDeepLink(HandleDeepLink event, Emitter<NavigationState> emit) async {
    try {
      // Parse deep link and extract screen name and parameters
      final uri = Uri.parse(event.deepLink);

      // Extract screen name from host (for securyflex://screen_name format)
      String screenName = 'dashboard';
      if (uri.host.isNotEmpty) {
        screenName = uri.host;
      } else if (uri.pathSegments.isNotEmpty) {
        screenName = uri.pathSegments.first;
      }

      final parameters = Map<String, dynamic>.from(uri.queryParameters);

      // Add any additional parameters
      if (event.parameters != null) {
        parameters.addAll(event.parameters!);
      }

      add(NavigateToScreen(
        screenName: screenName,
        arguments: parameters,
        replaceCurrentRoute: true,
      ));

      debugPrint('Handled deep link: ${event.deepLink} -> $screenName');
    } catch (e) {
      emit(NavigationError(
        error: ErrorHandler.fromException(e),
      ));
    }
  }
  
  /// Update notification badges
  Future<void> _onUpdateNotificationBadges(UpdateNotificationBadges event, Emitter<NavigationState> emit) async {
    if (state is NavigationReady) {
      final currentState = state as NavigationReady;
      
      final newBadgeCounts = Map<int, int>.from(currentState.tabBadgeCounts);
      
      // Update badges based on notification types
      event.badgeCounts.forEach((notificationType, count) {
        int? tabIndex;
        
        switch (notificationType) {
          case 'chat':
          case 'message':
            tabIndex = _findTabIndex(currentState.tabs, 'chat');
            break;
          case 'job':
          case 'assignment':
            tabIndex = _findTabIndex(currentState.tabs, 'jobs') ?? 
                      _findTabIndex(currentState.tabs, 'assignments');
            break;
          case 'planning':
            tabIndex = _findTabIndex(currentState.tabs, 'planning');
            break;
        }
        
        if (tabIndex != null) {
          if (count > 0) {
            newBadgeCounts[tabIndex] = (newBadgeCounts[tabIndex] ?? 0) + count;
          }
        }
      });
      
      emit(currentState.copyWith(tabBadgeCounts: newBadgeCounts));
      
      debugPrint('Updated notification badges: ${event.badgeCounts}');
    }
  }
  
  /// Reset navigation to initial state
  Future<void> _onResetNavigation(ResetNavigation event, Emitter<NavigationState> emit) async {
    emit(const NavigationInitial());
    debugPrint('Navigation reset');
  }
  
  /// Update user role and rebuild navigation
  Future<void> _onUpdateUserRole(UpdateUserRole event, Emitter<NavigationState> emit) async {
    add(NavigationInitialize(
      userRole: event.newUserRole,
      userId: event.userId,
    ));
  }
  
  /// Handle navigation error
  Future<void> _onNavigationError(NavigationErrorOccurred event, Emitter<NavigationState> emit) async {
    emit(NavigationError(
      error: AppError(
        code: 'navigation_error',
        message: event.error,
        category: ErrorCategory.general,
      ),
      failedScreenName: event.screenName,
    ));
  }
  
  /// Find tab index by key
  int? _findTabIndex(List<NavigationTabData> tabs, String key) {
    for (int i = 0; i < tabs.length; i++) {
      if (tabs[i].key == key) {
        return i;
      }
    }
    return null;
  }
  
  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
  
  /// Convenience getters for current navigation state
  bool get isReady => state is NavigationReady;
  bool get isLoading => state is NavigationLoading || (state is NavigationReady && (state as NavigationReady).isLoading);
  bool get hasError => state is NavigationError;
  
  NavigationReady? get currentNavigationState {
    return state is NavigationReady ? state as NavigationReady : null;
  }
  
  int get currentTabIndex {
    return currentNavigationState?.currentTabIndex ?? 0;
  }
  
  List<NavigationTabData> get tabs {
    return currentNavigationState?.tabs ?? [];
  }
  
  Map<int, int> get tabBadgeCounts {
    return currentNavigationState?.tabBadgeCounts ?? {};
  }
  
  String get userRole {
    return currentNavigationState?.userRole ?? '';
  }
  
  bool get canNavigateBack {
    return currentNavigationState?.canNavigateBack ?? false;
  }
  
  int get totalBadgeCount {
    return currentNavigationState?.totalBadgeCount ?? 0;
  }
}
