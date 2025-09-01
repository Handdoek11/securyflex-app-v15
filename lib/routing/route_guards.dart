// lib/routing/route_guards.dart

import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';

import '../auth/auth_service.dart';
import '../unified_theme_system.dart';
import 'app_routes.dart';

/// Authentication and authorization guards for SecuryFlex routing
class RouteGuards {
  /// Main guard function that handles all routing logic
  static FutureOr<String?> globalRedirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    
    debugPrint('RouteGuard: Checking route $location');
    
    // Check feature flags first
    final featureGuard = _checkFeatureFlags(context, state);
    if (featureGuard != null) return featureGuard;
    
    // Check authentication
    final authGuard = _checkAuthentication(context, state);
    if (authGuard != null) return authGuard;
    
    // Check role-based access
    final roleGuard = _checkRoleAccess(context, state);
    if (roleGuard != null) return roleGuard;
    
    // Check terms acceptance
    final termsGuard = _checkTermsAcceptance(context, state);
    if (termsGuard != null) return termsGuard;
    
    return null; // Allow access
  }
  
  /// Check if GoRouter feature is enabled
  static String? _checkFeatureFlags(BuildContext context, GoRouterState state) {
    // Feature flag for gradual rollout - always true for now
    // Future: Set via environment or remote config
    return null; // GoRouter always enabled
  }
  
  /// Check authentication status
  static String? _checkAuthentication(BuildContext context, GoRouterState state) {
    final isLoggedIn = AuthService.isLoggedIn;
    final location = state.matchedLocation;
    
    // Public routes that don't require authentication
    const publicRoutes = [
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      AppRoutes.splash,
      AppRoutes.privacy,
    ];
    
    final isPublicRoute = publicRoutes.any((route) => location.startsWith(route));
    
    if (!isLoggedIn && !isPublicRoute) {
      debugPrint('RouteGuard: User not authenticated, redirecting to login');
      return AppRoutes.login;
    }
    
    // Redirect authenticated users away from auth pages
    if (isLoggedIn && (location == AppRoutes.login || location == AppRoutes.register)) {
      final userType = AuthService.currentUserType.toLowerCase();
      debugPrint('RouteGuard: Authenticated user on auth page, redirecting to dashboard');
      
      return userType == 'company' 
          ? AppRoutes.companyDashboard 
          : AppRoutes.beveiligerDashboard;
    }
    
    return null;
  }
  
  /// Check role-based access control
  static String? _checkRoleAccess(BuildContext context, GoRouterState state) {
    if (!AuthService.isLoggedIn) return null;
    
    final userType = AuthService.currentUserType.toLowerCase();
    final location = state.matchedLocation;
    
    // Check beveiliger-only routes
    if (location.startsWith('/beveiliger') && userType != 'guard') {
      debugPrint('RouteGuard: Non-guard accessing beveiliger route, redirecting');
      return AppRoutes.companyDashboard;
    }
    
    // Check company-only routes
    if (location.startsWith('/company') && userType != 'company') {
      debugPrint('RouteGuard: Non-company accessing company route, redirecting');
      return AppRoutes.beveiligerDashboard;
    }
    
    return null;
  }
  
  /// Check if user has accepted current terms
  static String? _checkTermsAcceptance(BuildContext context, GoRouterState state) {
    if (!AuthService.isLoggedIn) return null;
    
    final location = state.matchedLocation;
    
    // Don't check terms for the terms page itself
    if (location == AppRoutes.termsAcceptance) return null;
    
    final userId = AuthService.currentUserId;
    if (userId.isEmpty) return null;
    
    // 🚨 SECURITY FIX: Implement synchronous terms checking
    // Use cached terms acceptance status for immediate validation
    final hasAcceptedTerms = AuthService.hasAcceptedCurrentTerms(userId);
    
    if (!hasAcceptedTerms) {
      debugPrint('RouteGuard: Terms not accepted, redirecting to terms page');
      return AppRoutes.termsAcceptance;
    }
    
    return null;
  }
  
  /// Get user role enum from string
  static UserRole getUserRole() {
    switch (AuthService.currentUserType.toLowerCase()) {
      case 'company':
        return UserRole.company;
      case 'guard':
      default:
        return UserRole.guard;
    }
  }
  
  /// Validate route parameters
  static bool validateRouteParams(GoRouterState state) {
    final params = state.pathParameters;
    
    // 🚨 SECURITY FIX: Enhanced parameter validation with XSS and injection protection
    for (final entry in params.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Null/empty validation
      if (value.isEmpty) {
        debugPrint('RouteGuard: Empty parameter $key');
        return false;
      }
      
      // Length validation (prevent buffer overflow attacks)
      if (value.length > 100) {
        debugPrint('RouteGuard: Parameter $key too long: ${value.length}');
        return false;
      }
      
      // XSS protection - check for HTML/script injection
      final dangerousPatterns = [
        '<script', '</script', '<iframe', '</iframe',
        'javascript:', 'vbscript:', 'onload=', 'onerror=',
        'alert(', 'document.', 'window.', 'eval(',
        '<img', 'src=', '<svg', '<object', '<embed'
      ];
      
      final lowerValue = value.toLowerCase();
      for (final pattern in dangerousPatterns) {
        if (lowerValue.contains(pattern)) {
          debugPrint('RouteGuard: Potential XSS in parameter $key: $pattern');
          return false;
        }
      }
      
      // SQL injection protection (though using NoSQL)
      final sqlPatterns = [
        'select ', 'insert ', 'update ', 'delete ', 'drop ',
        'union ', 'script ', '/*', '*/', '--', ';--', 
        'exec(', 'sp_', 'xp_'
      ];
      
      for (final pattern in sqlPatterns) {
        if (lowerValue.contains(pattern)) {
          debugPrint('RouteGuard: Potential SQL injection in parameter $key: $pattern');
          return false;
        }
      }
      
      // Path traversal protection
      if (value.contains('..') || value.contains('/.') || value.contains('\\.')) {
        debugPrint('RouteGuard: Potential path traversal in parameter $key');
        return false;
      }
      
      // Format validation based on parameter type
      switch (key) {
        case 'jobId':
        case 'conversationId':
        case 'applicationId':
        case 'userId':
          // Allow only alphanumeric, hyphens, and underscores
          if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
            debugPrint('RouteGuard: Invalid $key format: $value');
            return false;
          }
          break;
          
        case 'email':
          // Basic email format validation
          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
            debugPrint('RouteGuard: Invalid email format: $value');
            return false;
          }
          break;
          
        case 'phone':
          // Dutch phone number format
          if (!RegExp(r'^(\+31|0031|0)[1-9]\d{8}$').hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
            debugPrint('RouteGuard: Invalid phone format: $value');
            return false;
          }
          break;
      }
    }
    
    return true;
  }
  
  /// Get initial route for user based on role
  static String getInitialRouteForUser() {
    if (!AuthService.isLoggedIn) {
      return AppRoutes.login;
    }
    
    final userType = AuthService.currentUserType.toLowerCase();
    return userType == 'company' 
        ? AppRoutes.companyDashboard 
        : AppRoutes.beveiligerDashboard;
  }
  
  /// Check if route requires authentication
  static bool requiresAuthentication(String route) {
    const publicRoutes = [
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      AppRoutes.splash,
      AppRoutes.privacy,
    ];
    
    return !publicRoutes.contains(route);
  }
  
  /// Check if user has necessary certificates for certain actions
  static bool hasRequiredCertificates(List<String> requiredCertificates) {
    // This would check against the user's certificates in AuthService
    // For now, return true as placeholder
    return true;
  }
  
  /// Log navigation for analytics
  static void logNavigation(String from, String to) {
    debugPrint('Navigation: $from -> $to');
    // Here you would integrate with Firebase Analytics or other analytics service
  }
}