// Navigation Helper - Provides compatibility between Navigator and GoRouter
// This helps the app work while we migrate from Navigator to GoRouter

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Extension to add safe navigation methods to BuildContext
extension NavigationHelper on BuildContext {
  /// Safe pop that checks if we can pop
  void safePop([dynamic result]) {
    if (canPop()) {
      pop(result);
    } else {
      // If we can't pop, go to login as fallback
      go('/login');
    }
  }
  
  /// Navigate to login and clear stack
  void navigateToLogin() {
    go('/login');
  }
  
  /// Navigate to beveiliger dashboard
  void navigateToBeveiligerDashboard() {
    go('/beveiliger/dashboard');
  }
  
  /// Navigate to company dashboard  
  void navigateToCompanyDashboard() {
    go('/company/dashboard');
  }
  
  /// Navigate to registration
  void navigateToRegistration() {
    go('/register');
  }
  
  /// Navigate to job details
  void navigateToJobDetails(String jobId) {
    push('/beveiliger/jobs/$jobId');
  }
  
  /// Navigate to schedule
  void navigateToSchedule() {
    go('/beveiliger/schedule');
  }
  
  /// Navigate to chat
  void navigateToChat() {
    go('/beveiliger/chat');
  }
  
  /// Navigate to profile
  void navigateToProfile() {
    go('/beveiliger/profile');
  }
  
  /// Navigate to notifications
  void navigateToNotifications() {
    push('/beveiliger/profile/notifications');
  }
  
  /// Check if we're on a specific route
  bool isOnRoute(String route) {
    final currentRoute = GoRouterState.of(this).uri.toString();
    return currentRoute == route;
  }
  
  /// Get current route
  String get currentRoute => GoRouterState.of(this).uri.toString();
}

/// Helper class for migrating from Navigator to GoRouter
class NavigationMigrationHelper {
  /// Replace Navigator.pop with this
  static void pop(BuildContext context, [dynamic result]) {
    if (context.canPop()) {
      context.pop(result);
    }
  }
  
  /// Replace Navigator.push with this
  static Future<T?> push<T>(BuildContext context, String route) async {
    return context.push<T>(route);
  }
  
  /// Replace Navigator.pushReplacement with this
  static void pushReplacement(BuildContext context, String route) {
    context.go(route);
  }
  
  /// Replace Navigator.pushAndRemoveUntil with this
  static void pushAndRemoveUntil(BuildContext context, String route) {
    context.go(route);
  }
  
  /// Replace Navigator.pushNamed with this
  static Future<T?> pushNamed<T>(BuildContext context, String route, {Object? arguments}) async {
    // Convert old arguments to query parameters if needed
    if (arguments != null && arguments is Map<String, dynamic>) {
      final queryParams = arguments.map((key, value) => MapEntry(key, value.toString()));
      final uri = Uri(path: route, queryParameters: queryParams);
      return context.push<T>(uri.toString());
    }
    return context.push<T>(route);
  }
  
  /// Check if can pop
  static bool canPop(BuildContext context) {
    return context.canPop();
  }
}

/// Widget wrapper to handle Navigator calls in legacy code
class NavigatorCompatibilityWrapper extends StatelessWidget {
  final Widget child;
  
  const NavigatorCompatibilityWrapper({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    // This wrapper can intercept Navigator calls and redirect to GoRouter
    return child;
  }
}