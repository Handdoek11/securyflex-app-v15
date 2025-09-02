// lib/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import existing screens
import '../auth/enhanced_glassmorphic_login_screen.dart';
import '../auth/registration_screen.dart';
import '../auth/screens/progressive_registration_screen.dart';
import '../legal/screens/terms_acceptance_screen.dart';
import '../beveiliger_dashboard/beveiliger_dashboard_home.dart';
import '../company_dashboard/company_dashboard_home.dart';
import '../marketplace/screens/jobs_tab_screen.dart';
import '../schedule/screens/schedule_main_screen.dart';
import '../chat/screens/conversations_screen.dart';
import '../chat/screens/chat_screen.dart';
import '../chat/models/conversation_model.dart';
import '../chat/bloc/chat_bloc.dart';
import '../beveiliger_profiel/screens/beveiliger_profiel_screen.dart';
import '../beveiliger_dashboard/screens/my_applications_screen.dart';
import '../beveiliger_profiel/screens/certificate_add_screen.dart';
import '../company_dashboard/screens/responsive_company_dashboard.dart';
import '../company_dashboard/screens/team_management_screen.dart';
import '../company_dashboard/screens/company_profile_screen.dart';
import '../privacy/screens/privacy_dashboard_screen.dart';
import '../unified_theme_system.dart';

// Import routing components
import 'app_routes.dart';
import 'route_guards.dart';
import 'job_route_handler.dart';
import 'route_transitions.dart';
import 'shell_screens/beveiliger_shell_screen.dart';
import 'shell_screens/company_shell_screen.dart';

// Import BLoCs
import '../beveiliger_dashboard/bloc/beveiliger_dashboard_bloc.dart';
import '../beveiliger_dashboard/bloc/beveiliger_dashboard_event.dart';
import '../beveiliger_dashboard/services/enhanced_earnings_service.dart';
import '../beveiliger_dashboard/services/enhanced_shift_service.dart';
import '../beveiliger_dashboard/services/compliance_monitoring_service.dart';
import '../beveiliger_dashboard/services/weather_integration_service.dart';
import '../beveiliger_dashboard/services/performance_analytics_service.dart';
import '../beveiliger_profiel/bloc/beveiliger_profiel_bloc.dart';
import '../marketplace/bloc/job_bloc.dart';
import '../marketplace/bloc/job_event.dart';
import '../schedule/services/schedule_service_provider.dart';

/// Main router configuration for SecuryFlex
class AppRouter {
  // Navigator keys for state preservation
  static final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final _beveiligerShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'beveiligerShell');
  static final _companyShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'companyShell');
  
  static GoRouter? _router;
  static GoRouter get router {
    if (_router == null) {
      throw StateError('AppRouter not initialized. Call AppRouter.initialize() first.');
    }
    return _router!;
  }
  
  /// Initialize the router
  static void initialize() {
    if (_router != null) {
      // Already initialized
      return;
    }
    _router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.login,
      debugLogDiagnostics: true,
      redirect: RouteGuards.globalRedirect,
      errorBuilder: (context, state) => _buildErrorScreen(context, state),
      routes: [
        // Authentication routes with premium glassmorphic animations
        GoRoute(
          path: AppRoutes.login,
          name: RouteNames.login,
          pageBuilder: (context, state) => RouteTransitions.morphingGlassTransition(
            child: const EnhancedGlassmorphicLoginScreen(),
            name: RouteNames.login,
          ),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: RouteNames.register,
          pageBuilder: (context, state) => RouteTransitions.authGlassTransition(
            child: const RegistrationScreen(),
            name: RouteNames.register,
            direction: AuthTransitionDirection.forward,
          ),
        ),
        // Progressive registration routes with smooth step transitions
        GoRoute(
          path: '/register/progressive',
          name: 'progressive_register',
          pageBuilder: (context, state) => RouteTransitions.authGlassTransition(
            child: const ProgressiveRegistrationScreen(step: 'welcome'),
            name: 'progressive_register',
            direction: AuthTransitionDirection.forward,
          ),
        ),
        // Guard registration flow
        GoRoute(
          path: '/register/guard/:step',
          name: 'guard_register_step',
          pageBuilder: (context, state) {
            final step = state.pathParameters['step'] ?? 'welcome';
            return RouteTransitions.progressiveStepTransition(
              child: ProgressiveRegistrationScreen(step: step),
              name: 'guard_register_step',
              direction: ProgressDirection.next,
            );
          },
        ),
        // Company registration flow  
        GoRoute(
          path: '/register/company/:step',
          name: 'company_register_step',
          pageBuilder: (context, state) {
            final step = state.pathParameters['step'] ?? 'welcome';
            return RouteTransitions.progressiveStepTransition(
              child: ProgressiveRegistrationScreen(step: step),
              name: 'company_register_step',
              direction: ProgressDirection.next,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.termsAcceptance,
          name: RouteNames.termsAcceptance,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return TermsAcceptanceScreen(
              userRole: extra?['userRole'] ?? UserRole.guard,
              userId: extra?['userId'] ?? '',
              onAccepted: () {
                final role = extra?['userRole'] ?? UserRole.guard;
                context.go(role == UserRole.company 
                    ? AppRoutes.companyDashboard 
                    : AppRoutes.beveiligerDashboard);
              },
            );
          },
        ),
        
        // 🚀 CONSOLIDATED: Single role-based StatefulShellRoute for both Guard and Company users
        StatefulShellRoute.indexedStack(
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state, navigationShell) {
            // 🎯 DYNAMIC ROLE SELECTION: Choose shell screen based on user role
            final userRole = RouteGuards.getUserRole();
            
            return MultiBlocProvider(
              providers: _getRoleBlocProviders(userRole),
              child: _getRoleShellScreen(userRole, navigationShell),
            );
          },
          branches: _getRoleShellBranches(),
        ),
        
        // Additional routes outside shell navigation
        GoRoute(
          path: AppRoutes.beveiligerCertificates,
          name: RouteNames.beveiligerCertificates,
          builder: (context, state) => const CertificateAddScreen(
            userId: 'current-user-id', // TODO: Get from AuthService
            userRole: UserRole.guard,
          ),
        ),
        GoRoute(
          path: AppRoutes.beveiligerApplications,
          name: RouteNames.beveiligerApplications,
          builder: (context, state) => const MyApplicationsScreen(),
        ),
        
        // 🗑️ REMOVED: Company Shell Route - now consolidated into role-based shell above
        // All company routes are now handled by _getRoleShellBranches() method
        // Review and workflow routes
        GoRoute(
          path: '/review/submit',
          name: 'review_submit',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return Scaffold(
              appBar: AppBar(title: const Text('Review indienen')),
              body: Center(
                child: Text('Review screen - workflowId: ${extra?['workflowId']}, jobId: ${extra?['jobId']}'),
              ),
            );
          },
        ),
        
        // Schedule management routes
        GoRoute(
          path: '/schedule/shift-details/:shiftId',
          name: 'shift_details',
          builder: (context, state) {
            final shiftId = state.pathParameters['shiftId']!;
            return Scaffold(
              appBar: AppBar(title: const Text('Shift details')),
              body: Center(child: Text('Shift details - ID: $shiftId')),
            );
          },
        ),
        GoRoute(
          path: '/schedule/edit-shift/:shiftId',
          name: 'shift_edit',
          builder: (context, state) {
            final shiftId = state.pathParameters['shiftId']!;
            return Scaffold(
              appBar: AppBar(title: const Text('Shift bewerken')),
              body: Center(child: Text('Edit shift - ID: $shiftId')),
            );
          },
        ),
        
        // Notification and subscription routes
        GoRoute(
          path: '/notifications',
          name: 'notification_center',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Notificaties')),
            body: const Center(child: Text('Notification center - TODO: Implement')),
          ),
        ),
        GoRoute(
          path: AppRoutes.notificationPreferences,
          name: RouteNames.notificationPreferences,
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Notificatie voorkeuren')),
            body: const Center(child: Text('Notification preferences - TODO: Implement')),
          ),
        ),
        GoRoute(
          path: '/beveiliger/favorites',
          name: 'favorites',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Favorieten')),
            body: const Center(child: Text('Favorites screen - TODO: Implement')),
          ),
        ),
        
        // File preview route
        GoRoute(
          path: '/chat/file-preview/:fileId',
          name: 'file_preview',
          builder: (context, state) {
            final fileId = state.pathParameters['fileId']!;
            final extra = state.extra as Map<String, dynamic>?;
            return Scaffold(
              appBar: AppBar(title: Text(extra?['fileName'] ?? 'File Preview')),
              body: Center(child: Text('File preview - ID: $fileId')),
            );
          },
        ),
        
        // Company job management routes
        GoRoute(
          path: '/company/jobs/create',
          name: 'company_job_create',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Vacature aanmaken')),
            body: const Center(child: Text('Job creation form - TODO: Implement')),
          ),
        ),
        GoRoute(
          path: '/company/jobs/:jobId/edit',
          name: 'company_job_edit',
          builder: (context, state) {
            final jobId = state.pathParameters['jobId']!;
            return Scaffold(
              appBar: AppBar(title: const Text('Vacature bewerken')),
              body: Center(child: Text('Job edit form - Job ID: $jobId')),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.subscriptionManagement,
          name: RouteNames.subscriptionManagement,
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Abonnement beheer')),
            body: const Center(child: Text('Subscription management - TODO: Implement')),
          ),
        ),
        GoRoute(
          path: AppRoutes.subscriptionUpgrade,
          name: RouteNames.subscriptionUpgrade,
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Abonnement upgraden')),
            body: const Center(child: Text('Subscription upgrade - TODO: Implement')),
          ),
        ),
        
        // Demo and test routes
        GoRoute(
          path: '/demo/application-review',
          name: 'demo_application_review',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Sollicitatie beoordelen (Demo)')),
            body: const Center(child: Text('Application review demo - TODO: Implement')),
          ),
        ),
        
        // Schedule management routes (additional)
        GoRoute(
          path: '/schedule/shift-management',
          name: 'shift_management',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Shift beheer')),
            body: const Center(child: Text('Shift management - TODO: Implement')),
          ),
        ),
        GoRoute(
          path: '/schedule/calendar',
          name: 'schedule_calendar',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Planning kalender')),
            body: const Center(child: Text('Schedule calendar - TODO: Implement')),
          ),
        ),
        
        // Shared routes
        GoRoute(
          path: AppRoutes.privacy,
          name: RouteNames.privacy,
          builder: (context, state) => const PrivacyDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.help,
          name: RouteNames.help,
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Help & Support')),
            body: const Center(child: Text('Help screen - TODO: Implement')),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: RouteNames.settings,
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Instellingen')),
            body: const Center(child: Text('Settings screen - TODO: Implement')),
          ),
        ),
        
        // Error routes
        GoRoute(
          path: AppRoutes.notFound,
          name: RouteNames.notFound,
          builder: (context, state) => _buildNotFoundScreen(context),
        ),
      ],
    );
  }
  
  /// Build error screen
  static Widget _buildErrorScreen(BuildContext context, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Er is een fout opgetreden',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Onbekende fout',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Terug naar login'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build not found screen
  static Widget _buildNotFoundScreen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Pagina niet gevonden',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteGuards.getInitialRouteForUser()),
              child: const Text('Terug naar dashboard'),
            ),
          ],
        ),
      ),
    );
  }
  
  // 🚀 CONSOLIDATION HELPERS: Role-based routing configuration
  
  /// Get BLoC providers based on user role
  static List<BlocProvider> _getRoleBlocProviders(UserRole userRole) {
    switch (userRole) {
      case UserRole.guard:
        return [
          BlocProvider(
            create: (context) => BeveiligerDashboardBloc(
              earningsService: EnhancedEarningsService(),
              shiftService: EnhancedShiftService(),
              complianceService: ComplianceMonitoringService(),
              weatherService: WeatherIntegrationService(),
              analyticsService: PerformanceAnalyticsService(),
            )..add(const LoadDashboardData()),
          ),
          BlocProvider(
            create: (context) => ChatBloc(),
          ),
          BlocProvider(
            create: (context) => BeveiligerProfielBloc(),
          ),
          BlocProvider(
            create: (context) => JobBloc()..add(LoadJobs()),
          ),
        ];
        
      case UserRole.company:
        return [
          BlocProvider(
            create: (context) => ChatBloc(),
          ),
          // Add more company-specific BLoCs as needed
        ];
        
      case UserRole.admin:
        // Admin uses guard interface for now
        return _getRoleBlocProviders(UserRole.guard);
    }
  }
  
  /// Get shell screen based on user role
  static Widget _getRoleShellScreen(UserRole userRole, StatefulNavigationShell navigationShell) {
    switch (userRole) {
      case UserRole.guard:
      case UserRole.admin: // Admin uses guard interface
        return BeveiligerShellScreen(navigationShell: navigationShell);
        
      case UserRole.company:
        return CompanyShellScreen(navigationShell: navigationShell);
    }
  }
  
  /// Get shell branches based on user role
  static List<StatefulShellBranch> _getRoleShellBranches() {
    // For now, return both sets of branches
    // TODO: Make this role-specific for better performance
    return [
      // Guard branches
      StatefulShellBranch(
        navigatorKey: _beveiligerShellNavigatorKey,
        routes: [
          GoRoute(
            path: AppRoutes.beveiligerDashboard,
            name: RouteNames.beveiligerDashboard,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final fromRegistration = extra?['fromRegistration'] == true;
              
              if (fromRegistration) {
                return RouteTransitions.successCompletionTransition(
                  child: const BeveiligerDashboardHome(),
                  name: RouteNames.beveiligerDashboard,
                );
              }
              
              return NoTransitionPage(
                child: const BeveiligerDashboardHome(),
              );
            },
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.beveiligerJobs,
            name: RouteNames.beveiligerJobs,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const JobsTabScreen(),
            ),
            routes: [
              GoRoute(
                path: ':jobId',
                name: RouteNames.beveiligerJobDetails,
                builder: (context, state) {
                  final jobId = state.pathParameters['jobId']!;
                  return JobRouteHandler.loadJobDetailsScreen(jobId);
                },
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.beveiligerSchedule,
            name: RouteNames.beveiligerSchedule,
            pageBuilder: (context, state) => NoTransitionPage(
              child: _buildScheduleScreenWithProvider(),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.beveiligerChat,
            name: RouteNames.beveiligerChat,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const ConversationsScreen(
                userRole: UserRole.guard,
              ),
            ),
            routes: [
              GoRoute(
                path: ':conversationId',
                name: RouteNames.beveiligerChatConversation,
                builder: (context, state) {
                  final conversationId = state.pathParameters['conversationId']!;
                  // TODO: Load conversation from repository
                  // For now, create a placeholder conversation
                  final conversation = ConversationModel(
                    conversationId: conversationId,
                    title: 'Chat',
                    participants: {},
                    lastMessage: null,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  return ChatScreen(
                    conversation: conversation,
                    userRole: UserRole.guard,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.beveiligerProfile,
            name: RouteNames.beveiligerProfile,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const BeveiligerProfielScreen(),
            ),
          ),
        ],
      ),
      
      // Company branches  
      StatefulShellBranch(
        navigatorKey: _companyShellNavigatorKey,
        routes: [
          GoRoute(
            path: AppRoutes.companyDashboard,
            name: RouteNames.companyDashboard,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final fromRegistration = extra?['fromRegistration'] == true;
              
              if (fromRegistration) {
                return RouteTransitions.successCompletionTransition(
                  child: const CompanyDashboardHome(),
                  name: RouteNames.companyDashboard,
                );
              }
              
              return NoTransitionPage(
                child: const CompanyDashboardHome(),
              );
            },
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.companyJobs,
            name: RouteNames.companyJobs,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const ResponsiveCompanyDashboard(),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.companyTeam,
            name: RouteNames.companyTeam,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const TeamManagementScreen(),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.companyAnalytics,
            name: RouteNames.companyAnalytics,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const Scaffold(
                body: Center(child: Text('Analytics Dashboard')),
              ),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.companyProfile,
            name: RouteNames.companyProfile,
            pageBuilder: (context, state) => NoTransitionPage(
              child: const CompanyProfileScreen(),
            ),
          ),
        ],
      ),
    ];
  }

  /// Build ScheduleMainScreen with proper BLoC provider
  static Widget _buildScheduleScreenWithProvider() {
    return FutureBuilder<bool>(
      future: _initializeScheduleServiceProvider(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data != true) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Fout bij laden planning module'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _initializeScheduleServiceProvider(),
                    child: const Text('Opnieuw proberen'),
                  ),
                ],
              ),
            ),
          );
        }

        // Provide ScheduleBloc to the widget tree
        return ScheduleServiceProvider.instance.provideBlocToWidget(
          child: const ScheduleMainScreen(
            userRole: UserRole.guard,
          ),
        );
      },
    );
  }

  /// Initialize ScheduleServiceProvider if not already initialized
  static Future<bool> _initializeScheduleServiceProvider() async {
    try {
      if (!ScheduleServiceProvider.instance.isInitialized) {
        // We need a BuildContext for initialization, but we don't have one here
        // So we'll use a workaround - the context will be available when the screen is built
        await ScheduleServiceProvider.instance.initialize(
          context: _rootNavigatorKey.currentContext!,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Failed to initialize ScheduleServiceProvider: $e');
      return false;
    }
  }
}