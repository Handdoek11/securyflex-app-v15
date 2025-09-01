import '../../core/bloc/base_bloc.dart';

/// Base class for all navigation events in SecuryFlex
abstract class NavigationEvent extends BaseEvent {
  const NavigationEvent();
}

/// Initialize navigation for a specific user role
class NavigationInitialize extends NavigationEvent {
  final String userRole;
  final String userId;
  
  const NavigationInitialize({
    required this.userRole,
    required this.userId,
  });
  
  @override
  List<Object> get props => [userRole, userId];
  
  @override
  String toString() => 'NavigationInitialize(userRole: $userRole, userId: $userId)';
}

/// Navigate to a specific tab
class NavigateToTab extends NavigationEvent {
  final int tabIndex;
  final String? tabName;
  
  const NavigateToTab({
    required this.tabIndex,
    this.tabName,
  });
  
  @override
  List<Object?> get props => [tabIndex, tabName];
  
  @override
  String toString() => 'NavigateToTab(tabIndex: $tabIndex, tabName: $tabName)';
}

/// Navigate to a specific screen
class NavigateToScreen extends NavigationEvent {
  final String screenName;
  final Map<String, dynamic>? arguments;
  final bool replaceCurrentRoute;
  
  const NavigateToScreen({
    required this.screenName,
    this.arguments,
    this.replaceCurrentRoute = false,
  });
  
  @override
  List<Object?> get props => [screenName, arguments, replaceCurrentRoute];
  
  @override
  String toString() => 'NavigateToScreen(screenName: $screenName, arguments: $arguments, replaceCurrentRoute: $replaceCurrentRoute)';
}

/// Navigate back to previous screen
class NavigateBack extends NavigationEvent {
  final dynamic result;
  
  const NavigateBack({this.result});
  
  @override
  List<Object?> get props => [result];
  
  @override
  String toString() => 'NavigateBack(result: $result)';
}

/// Update badge count for a specific tab
class UpdateTabBadge extends NavigationEvent {
  final int tabIndex;
  final int badgeCount;
  final String? badgeText;
  
  const UpdateTabBadge({
    required this.tabIndex,
    required this.badgeCount,
    this.badgeText,
  });
  
  @override
  List<Object?> get props => [tabIndex, badgeCount, badgeText];
  
  @override
  String toString() => 'UpdateTabBadge(tabIndex: $tabIndex, badgeCount: $badgeCount, badgeText: $badgeText)';
}

/// Update navigation history
class UpdateNavigationHistory extends NavigationEvent {
  final String screenName;
  final Map<String, dynamic>? arguments;
  
  const UpdateNavigationHistory({
    required this.screenName,
    this.arguments,
  });
  
  @override
  List<Object?> get props => [screenName, arguments];
  
  @override
  String toString() => 'UpdateNavigationHistory(screenName: $screenName, arguments: $arguments)';
}

/// Clear navigation history
class ClearNavigationHistory extends NavigationEvent {
  const ClearNavigationHistory();
}

/// Set navigation loading state
class SetNavigationLoading extends NavigationEvent {
  final bool isLoading;
  final String? loadingMessage;
  
  const SetNavigationLoading({
    required this.isLoading,
    this.loadingMessage,
  });
  
  @override
  List<Object?> get props => [isLoading, loadingMessage];
  
  @override
  String toString() => 'SetNavigationLoading(isLoading: $isLoading, loadingMessage: $loadingMessage)';
}

/// Handle deep link navigation
class HandleDeepLink extends NavigationEvent {
  final String deepLink;
  final Map<String, dynamic>? parameters;
  
  const HandleDeepLink({
    required this.deepLink,
    this.parameters,
  });
  
  @override
  List<Object?> get props => [deepLink, parameters];
  
  @override
  String toString() => 'HandleDeepLink(deepLink: $deepLink, parameters: $parameters)';
}

/// Update notification badges
class UpdateNotificationBadges extends NavigationEvent {
  final Map<String, int> badgeCounts;
  
  const UpdateNotificationBadges(this.badgeCounts);
  
  @override
  List<Object> get props => [badgeCounts];
  
  @override
  String toString() => 'UpdateNotificationBadges(badgeCounts: $badgeCounts)';
}

/// Reset navigation to initial state
class ResetNavigation extends NavigationEvent {
  const ResetNavigation();
}

/// Update user role and rebuild navigation
class UpdateUserRole extends NavigationEvent {
  final String newUserRole;
  final String userId;
  
  const UpdateUserRole({
    required this.newUserRole,
    required this.userId,
  });
  
  @override
  List<Object> get props => [newUserRole, userId];
  
  @override
  String toString() => 'UpdateUserRole(newUserRole: $newUserRole, userId: $userId)';
}

/// Handle navigation error
class NavigationErrorOccurred extends NavigationEvent {
  final String error;
  final String? screenName;

  const NavigationErrorOccurred({
    required this.error,
    this.screenName,
  });

  @override
  List<Object?> get props => [error, screenName];

  @override
  String toString() => 'NavigationErrorOccurred(error: $error, screenName: $screenName)';
}
