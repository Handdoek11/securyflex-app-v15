// lib/routing/navigation_service.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../auth/auth_service.dart';
import '../unified_theme_system.dart';

/// Centralized navigation service for GoRouter
/// Provides type-safe navigation methods throughout the app
class NavigationService {
  /// Navigate to login screen
  static void navigateToLogin(BuildContext context) {
    context.go(AppRoutes.login);
  }
  
  /// Navigate to registration screen
  static void navigateToRegister(BuildContext context) {
    context.go(AppRoutes.register);
  }
  
  /// Navigate to appropriate dashboard based on user role
  static void navigateToDashboard(BuildContext context) {
    final userType = AuthService.currentUserType.toLowerCase();
    
    if (userType == 'company') {
      context.go(AppRoutes.companyDashboard);
    } else {
      context.go(AppRoutes.beveiligerDashboard);
    }
  }
  
  /// Navigate to specific beveiliger route
  static void navigateToBeveiligerRoute(BuildContext context, String route) {
    context.go('/beveiliger/$route');
  }
  
  /// Navigate to specific company route
  static void navigateToCompanyRoute(BuildContext context, String route) {
    context.go('/company/$route');
  }
  
  /// Navigate to job details
  static void navigateToJobDetails(BuildContext context, String jobId, {bool isCompany = false}) {
    if (isCompany) {
      context.go('${AppRoutes.companyJobs}/$jobId');
    } else {
      context.go('${AppRoutes.beveiligerJobs}/$jobId');
    }
  }
  
  /// Navigate to chat conversation
  static void navigateToChatConversation(BuildContext context, String conversationId) {
    final userType = AuthService.currentUserType.toLowerCase();
    
    if (userType == 'company') {
      // Companies don't have chat in bottom nav, use direct route
      context.go('/chat/$conversationId');
    } else {
      context.go('${AppRoutes.beveiligerChat}/$conversationId');
    }
  }
  
  /// Navigate to notifications
  static void navigateToNotifications(BuildContext context) {
    context.go('${AppRoutes.beveiligerProfile}/notifications');
  }
  
  /// Navigate to terms acceptance
  static void navigateToTermsAcceptance(BuildContext context, UserRole userRole, String userId) {
    context.go(AppRoutes.termsAcceptance, extra: {
      'userRole': userRole,
      'userId': userId,
    });
  }
  
  /// Navigate to privacy dashboard
  static void navigateToPrivacy(BuildContext context) {
    context.go(AppRoutes.privacy);
  }
  
  /// Pop current route (go back)
  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      // If can't pop, go to dashboard
      navigateToDashboard(context);
    }
  }
  
  /// Replace current route
  static void replaceWith(BuildContext context, String route) {
    context.pushReplacement(route);
  }
  
  /// Push a new route on top of current
  static void push(BuildContext context, String route) {
    context.push(route);
  }
  
  /// Check if can pop
  static bool canGoBack(BuildContext context) {
    return context.canPop();
  }
  
  /// Get current route
  static String getCurrentRoute(BuildContext context) {
    return GoRouterState.of(context).matchedLocation;
  }
  
  /// Navigate with parameters
  static void navigateWithParams(BuildContext context, String route, Map<String, String> params) {
    context.goNamed(route, pathParameters: params);
  }
  
  /// Navigate with query parameters
  static void navigateWithQuery(BuildContext context, String route, Map<String, String> queryParams) {
    context.goNamed(route, queryParameters: queryParams);
  }
}