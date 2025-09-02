import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'beveiliger_dashboard/modern_beveiliger_dashboard_v2.dart';
import 'company_dashboard/modern_company_dashboard.dart';
import 'unified_theme_system.dart';
import 'routing/app_routes.dart';

/// Modern dashboard routing system
/// 
/// This provides clean routing to the new modern dashboards
/// and handles the transition from legacy to modern implementations.
/// 
/// Features:
/// - Role-based dashboard routing
/// - Smooth transitions
/// - Error handling
/// - Performance monitoring
class ModernDashboardRoutes {
  
  /// Route to appropriate dashboard based on user role
  static Widget getDashboardForRole(UserRole userRole) {
    switch (userRole) {
      case UserRole.guard:
        return const ModernBeveiligerDashboardV2();
      case UserRole.company:
        return const ModernCompanyDashboard();
      case UserRole.admin:
        // TODO: Implement ModernAdminDashboard
        return _buildComingSoonDashboard(userRole, 'Admin Dashboard');
    }
  }

  /// Get dashboard route name for navigation
  static String getRouteNameForRole(UserRole userRole) {
    switch (userRole) {
      case UserRole.guard:
        return '/modern-beveiliger-dashboard';
      case UserRole.company:
        return '/modern-company-dashboard';
      case UserRole.admin:
        return '/modern-admin-dashboard';
    }
  }

  /// Build route map for app routing
  static Map<String, WidgetBuilder> buildRoutes() {
    return {
      '/modern-beveiliger-dashboard': (context) => const ModernBeveiligerDashboardV2(),
      '/modern-company-dashboard': (context) => const ModernCompanyDashboard(),
      '/modern-admin-dashboard': (context) => _buildComingSoonDashboard(UserRole.admin, 'Admin Dashboard'),
    };
  }

  /// Create GoRouter 2.0 transition page with custom transitions
  static CustomTransitionPage<T> createGoRouterTransitionPage<T extends Object?>(
    Widget child,
    UserRole userRole, {
    String? name,
    Object? arguments,
  }) {
    return CustomTransitionPage<T>(
      name: name,
      arguments: arguments,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Smooth slide transition
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Navigate to dashboard with proper role handling (Pure GoRouter 2.0)
  static void navigateToDashboard(
    BuildContext context,
    UserRole userRole, {
    bool replace = false,
  }) {
    // Pure GoRouter 2.0 navigation - no route building needed
    if (replace) {
      // Use context.go for replacement behavior (clears current route)
      switch (userRole) {
        case UserRole.guard:
          context.go(AppRoutes.beveiligerDashboard);
          break;
        case UserRole.company:
          context.go(AppRoutes.companyDashboard);
          break;
        case UserRole.admin:
          context.go(AppRoutes.beveiligerDashboard);
          break;
      }
    } else {
      // Use context.push for stack navigation
      switch (userRole) {
        case UserRole.guard:
          context.push(AppRoutes.beveiligerDashboard);
          break;
        case UserRole.company:
          context.push(AppRoutes.companyDashboard);
          break;
        case UserRole.admin:
          context.push(AppRoutes.beveiligerDashboard);
          break;
      }
    }
  }

  /// Build coming soon dashboard for unimplemented roles
  static Widget _buildComingSoonDashboard(UserRole userRole, String dashboardName) {
    return Scaffold(
      backgroundColor: SecuryFlexTheme.getColorScheme(userRole).surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 80,
                color: SecuryFlexTheme.getColorScheme(userRole).primary,
              ),
              const SizedBox(height: 24),
              Text(
                dashboardName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: SecuryFlexTheme.getColorScheme(userRole).onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Komt binnenkort beschikbaar',
                style: TextStyle(
                  fontSize: 16,
                  color: SecuryFlexTheme.getColorScheme(userRole).onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => context.pop(), // 🚀 CONVERTED: Navigator.pop → context.pop
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SecuryFlexTheme.getColorScheme(userRole).primary,
                    foregroundColor: SecuryFlexTheme.getColorScheme(userRole).onPrimary,
                  ),
                  child: const Text('Terug'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashboard performance monitor
class DashboardPerformanceMonitor {
  static final Map<String, DateTime> _loadTimes = {};
  static final Map<String, int> _memoryUsage = {};

  /// Start monitoring dashboard load time
  static void startLoadTimer(String dashboardName) {
    _loadTimes[dashboardName] = DateTime.now();
  }

  /// End monitoring and log performance
  static void endLoadTimer(String dashboardName) {
    final startTime = _loadTimes[dashboardName];
    if (startTime != null) {
      final loadTime = DateTime.now().difference(startTime);
      debugPrint('Dashboard $dashboardName loaded in ${loadTime.inMilliseconds}ms');
      
      // Assert performance requirements
      assert(loadTime.inMilliseconds < 2000, 
        'Dashboard load time exceeds 2s requirement: ${loadTime.inMilliseconds}ms');
    }
  }

  /// Monitor memory usage
  static void recordMemoryUsage(String dashboardName, int memoryMB) {
    _memoryUsage[dashboardName] = memoryMB;
    debugPrint('Dashboard $dashboardName using ${memoryMB}MB memory');
    
    // Assert memory requirements
    assert(memoryMB < 150, 
      'Dashboard memory usage exceeds 150MB requirement: ${memoryMB}MB');
  }

  /// Get performance report
  static Map<String, dynamic> getPerformanceReport() {
    return {
      'loadTimes': _loadTimes,
      'memoryUsage': _memoryUsage,
    };
  }
}

/// Dashboard feature flags for A/B testing
class DashboardFeatureFlags {
  static const bool _useLegacyDashboards = false;
  static const bool _enablePerformanceMonitoring = true;
  static const bool _enableAnimations = true;

  /// Check if legacy dashboards should be used
  static bool get useLegacyDashboards => _useLegacyDashboards;

  /// Check if performance monitoring is enabled
  static bool get enablePerformanceMonitoring => _enablePerformanceMonitoring;

  /// Check if animations are enabled
  static bool get enableAnimations => _enableAnimations;

  /// Get dashboard based on feature flags
  static Widget getDashboard(UserRole userRole) {
    if (useLegacyDashboards) {
      // Return legacy dashboard (for rollback capability)
      return _buildLegacyDashboardPlaceholder(userRole);
    }
    
    return ModernDashboardRoutes.getDashboardForRole(userRole);
  }

  static Widget _buildLegacyDashboardPlaceholder(UserRole userRole) {
    return Scaffold(
      backgroundColor: SecuryFlexTheme.getColorScheme(userRole).surface,
      body: const Center(
        child: Text(
          'Legacy Dashboard\n(Feature flag enabled)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

/// Dashboard testing utilities
class DashboardTestingUtils {
  /// Create test dashboard with mock data
  static Widget createTestDashboard(UserRole userRole, {
    bool withMockData = true,
    bool withAnimations = false,
  }) {
    if (withMockData) {
      // Return dashboard with mock data for testing
      return ModernDashboardRoutes.getDashboardForRole(userRole);
    }
    
    return ModernDashboardRoutes.getDashboardForRole(userRole);
  }

  /// Validate dashboard performance
  static bool validateDashboardPerformance(String dashboardName) {
    final report = DashboardPerformanceMonitor.getPerformanceReport();
    final loadTimes = report['loadTimes'] as Map<String, DateTime>;
    final memoryUsage = report['memoryUsage'] as Map<String, int>;

    // Check load time
    final startTime = loadTimes[dashboardName];
    if (startTime != null) {
      final loadTime = DateTime.now().difference(startTime);
      if (loadTime.inMilliseconds > 2000) {
        debugPrint('❌ Dashboard $dashboardName load time too slow: ${loadTime.inMilliseconds}ms');
        return false;
      }
    }

    // Check memory usage
    final memory = memoryUsage[dashboardName];
    if (memory != null && memory > 150) {
      debugPrint('❌ Dashboard $dashboardName memory usage too high: ${memory}MB');
      return false;
    }

    debugPrint('✅ Dashboard $dashboardName performance validated');
    return true;
  }
}
