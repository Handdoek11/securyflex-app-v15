import 'package:equatable/equatable.dart';
import '../../core/bloc/base_bloc.dart';
import '../../core/bloc/error_handler.dart';
import '../../unified_theme_system.dart';

/// Base class for all navigation states in SecuryFlex
abstract class NavigationState extends BaseState {
  const NavigationState();
}

/// Initial navigation state
class NavigationInitial extends NavigationState {
  const NavigationInitial();
}

/// Navigation loading state
class NavigationLoading extends NavigationState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage;
  
  const NavigationLoading({this.loadingMessage});
  
  @override
  List<Object?> get props => [loadingMessage];
  
  @override
  String toString() => 'NavigationLoading(message: $loadingMessage)';
}

/// Navigation ready state with tab management
class NavigationReady extends NavigationState {
  final String userRole;
  final String userId;
  final int currentTabIndex;
  final List<NavigationTabData> tabs;
  final Map<int, int> tabBadgeCounts;
  final List<NavigationHistoryItem> navigationHistory;
  final String? currentScreenName;
  final Map<String, dynamic>? currentScreenArguments;
  final bool isLoading;
  final String? loadingMessage;
  
  const NavigationReady({
    required this.userRole,
    required this.userId,
    required this.currentTabIndex,
    required this.tabs,
    required this.tabBadgeCounts,
    required this.navigationHistory,
    this.currentScreenName,
    this.currentScreenArguments,
    this.isLoading = false,
    this.loadingMessage,
  });
  
  /// Get Dutch role display name
  String get userRoleDisplayName {
    switch (userRole.toLowerCase()) {
      case 'guard':
        return 'Beveiliger';
      case 'company':
        return 'Bedrijf';
      case 'admin':
        return 'Beheerder';
      default:
        return 'Gebruiker';
    }
  }
  
  /// Get current tab data
  NavigationTabData get currentTab {
    if (currentTabIndex >= 0 && currentTabIndex < tabs.length) {
      return tabs[currentTabIndex];
    }
    return tabs.first;
  }
  
  /// Get total badge count across all tabs
  int get totalBadgeCount {
    return tabBadgeCounts.values.fold(0, (total, itemCount) => total + itemCount);
  }
  
  /// Get badge count for specific tab
  int getBadgeCount(int tabIndex) {
    return tabBadgeCounts[tabIndex] ?? 0;
  }
  
  /// Check if tab has badge
  bool hasTabBadge(int tabIndex) {
    return getBadgeCount(tabIndex) > 0;
  }
  
  /// Get navigation breadcrumb in Dutch
  String get navigationBreadcrumb {
    if (navigationHistory.isEmpty) {
      return currentTab.dutchLabel;
    }
    
    final breadcrumbs = navigationHistory
        .map((item) => item.displayName)
        .take(3) // Limit to last 3 items
        .toList();
    
    return breadcrumbs.join(' > ');
  }
  
  /// Check if can navigate back
  bool get canNavigateBack {
    return navigationHistory.isNotEmpty;
  }
  
  /// Get user role enum
  UserRole get userRoleEnum {
    switch (userRole.toLowerCase()) {
      case 'company':
        return UserRole.company;
      case 'admin':
        return UserRole.admin;
      case 'guard':
      default:
        return UserRole.guard;
    }
  }
  
  /// Create a copy with updated properties
  NavigationReady copyWith({
    String? userRole,
    String? userId,
    int? currentTabIndex,
    List<NavigationTabData>? tabs,
    Map<int, int>? tabBadgeCounts,
    List<NavigationHistoryItem>? navigationHistory,
    String? currentScreenName,
    Map<String, dynamic>? currentScreenArguments,
    bool? isLoading,
    String? loadingMessage,
  }) {
    return NavigationReady(
      userRole: userRole ?? this.userRole,
      userId: userId ?? this.userId,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      tabs: tabs ?? this.tabs,
      tabBadgeCounts: tabBadgeCounts ?? this.tabBadgeCounts,
      navigationHistory: navigationHistory ?? this.navigationHistory,
      currentScreenName: currentScreenName ?? this.currentScreenName,
      currentScreenArguments: currentScreenArguments ?? this.currentScreenArguments,
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }
  
  @override
  List<Object?> get props => [
    userRole,
    userId,
    currentTabIndex,
    tabs,
    tabBadgeCounts,
    navigationHistory,
    currentScreenName,
    currentScreenArguments,
    isLoading,
    loadingMessage,
  ];
  
  @override
  String toString() => 'NavigationReady(userRole: $userRole, currentTabIndex: $currentTabIndex, totalBadges: $totalBadgeCount)';
}

/// Navigation error state
class NavigationError extends NavigationState with ErrorStateMixin {
  @override
  final AppError error;
  
  final String? failedScreenName;
  
  const NavigationError({
    required this.error,
    this.failedScreenName,
  });
  
  @override
  List<Object?> get props => [error, failedScreenName];
  
  @override
  String toString() => 'NavigationError(error: ${error.localizedMessage}, failedScreenName: $failedScreenName)';
}

/// Navigation tab data
class NavigationTabData extends Equatable {
  final String key;
  final String dutchLabel;
  final String englishLabel;
  final String iconName;
  final String? activeIconName;
  final String screenName;
  final bool isEnabled;
  final Map<String, dynamic>? defaultArguments;
  
  const NavigationTabData({
    required this.key,
    required this.dutchLabel,
    required this.englishLabel,
    required this.iconName,
    this.activeIconName,
    required this.screenName,
    this.isEnabled = true,
    this.defaultArguments,
  });
  
  /// Get display label (currently Dutch)
  String get displayLabel => dutchLabel;
  
  @override
  List<Object?> get props => [
    key,
    dutchLabel,
    englishLabel,
    iconName,
    activeIconName,
    screenName,
    isEnabled,
    defaultArguments,
  ];
  
  @override
  String toString() => 'NavigationTabData(key: $key, dutchLabel: $dutchLabel, screenName: $screenName)';
}

/// Navigation history item
class NavigationHistoryItem extends Equatable {
  final String screenName;
  final String displayName;
  final Map<String, dynamic>? arguments;
  final DateTime timestamp;
  
  const NavigationHistoryItem({
    required this.screenName,
    required this.displayName,
    this.arguments,
    required this.timestamp,
  });
  
  @override
  List<Object?> get props => [screenName, displayName, arguments, timestamp];
  
  @override
  String toString() => 'NavigationHistoryItem(screenName: $screenName, displayName: $displayName)';
}

/// Navigation configuration for different user roles
class NavigationConfig {
  /// Get tabs for guard role
  static List<NavigationTabData> getGuardTabs() {
    return [
      const NavigationTabData(
        key: 'dashboard',
        dutchLabel: 'Dashboard',
        englishLabel: 'Dashboard',
        iconName: 'dashboard_outlined',
        activeIconName: 'dashboard',
        screenName: 'guard_dashboard',
      ),
      const NavigationTabData(
        key: 'jobs',
        dutchLabel: 'Opdrachten',
        englishLabel: 'Jobs',
        iconName: 'work_outline',
        activeIconName: 'work',
        screenName: 'jobs_screen',
      ),
      const NavigationTabData(
        key: 'chat',
        dutchLabel: 'Chat',
        englishLabel: 'Chat',
        iconName: 'chat_bubble_outline',
        activeIconName: 'chat_bubble',
        screenName: 'chat_screen',
      ),
      const NavigationTabData(
        key: 'planning',
        dutchLabel: 'Planning',
        englishLabel: 'Planning',
        iconName: 'calendar_today_outlined',
        activeIconName: 'calendar_today',
        screenName: 'planning_screen',
      ),
      const NavigationTabData(
        key: 'profile',
        dutchLabel: 'Profiel',
        englishLabel: 'Profile',
        iconName: 'person_outline',
        activeIconName: 'person',
        screenName: 'profile_screen',
      ),
    ];
  }
  
  /// Get tabs for company role - Optimized 4-tab structure
  static List<NavigationTabData> getCompanyTabs() {
    return [
      const NavigationTabData(
        key: 'dashboard',
        dutchLabel: 'Dashboard',
        englishLabel: 'Dashboard',
        iconName: 'dashboard_outlined',
        activeIconName: 'dashboard',
        screenName: 'company_dashboard',
      ),
      const NavigationTabData(
        key: 'jobs',
        dutchLabel: 'Opdrachten',
        englishLabel: 'Jobs',
        iconName: 'work_outline',
        activeIconName: 'work',
        screenName: 'company_jobs_applications',
      ),
      const NavigationTabData(
        key: 'chat',
        dutchLabel: 'Chat',
        englishLabel: 'Chat',
        iconName: 'chat_bubble_outline',
        activeIconName: 'chat_bubble',
        screenName: 'conversations_screen',
      ),
      const NavigationTabData(
        key: 'profile',
        dutchLabel: 'Profiel',
        englishLabel: 'Profile',
        iconName: 'person_outline',
        activeIconName: 'person',
        screenName: 'company_profile_screen',
      ),
    ];
  }
  
  /// Get tabs for admin role
  static List<NavigationTabData> getAdminTabs() {
    return [
      const NavigationTabData(
        key: 'dashboard',
        dutchLabel: 'Dashboard',
        englishLabel: 'Dashboard',
        iconName: 'dashboard_outlined',
        activeIconName: 'dashboard',
        screenName: 'admin_dashboard',
      ),
      const NavigationTabData(
        key: 'users',
        dutchLabel: 'Gebruikers',
        englishLabel: 'Users',
        iconName: 'people_outline',
        activeIconName: 'people',
        screenName: 'users_screen',
      ),
      const NavigationTabData(
        key: 'assignments',
        dutchLabel: 'Opdrachten',
        englishLabel: 'Assignments',
        iconName: 'assignment_outlined',
        activeIconName: 'assignment',
        screenName: 'assignments_screen',
      ),
      const NavigationTabData(
        key: 'analytics',
        dutchLabel: 'Analytics',
        englishLabel: 'Analytics',
        iconName: 'analytics_outlined',
        activeIconName: 'analytics',
        screenName: 'analytics_screen',
      ),
      const NavigationTabData(
        key: 'settings',
        dutchLabel: 'Instellingen',
        englishLabel: 'Settings',
        iconName: 'settings_outlined',
        activeIconName: 'settings',
        screenName: 'settings_screen',
      ),
    ];
  }
  
  /// Get tabs for user role
  static List<NavigationTabData> getTabsForRole(String userRole) {
    switch (userRole.toLowerCase()) {
      case 'company':
        return getCompanyTabs();
      case 'admin':
        return getAdminTabs();
      case 'guard':
      default:
        return getGuardTabs();
    }
  }
}
