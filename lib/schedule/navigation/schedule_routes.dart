import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../services/schedule_service_provider.dart';
import '../screens/schedule_main_screen.dart';
import '../screens/shift_management_screen.dart';
import '../screens/time_tracking_screen.dart';
import '../screens/leave_request_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/shift_details_screen.dart';
import '../screens/create_shift_screen.dart';
import '../screens/edit_shift_screen.dart';
import '../screens/swap_shift_screen.dart';

/// ScheduleRoutes - Route definitions with role-based access control
///
/// Provides secure navigation between schedule screens with proper
/// authentication and authorization checks.
///
/// Features:
/// - Role-based access control (Guard/Company/Admin)
/// - Route protection and authentication
/// - Nederlandse localization for all route names
/// - Performance optimized route generation
/// - Deep linking support
class ScheduleRoutes {
  static const String _logTag = 'ScheduleRoutes';
  
  // Route definitions with Nederlandse names
  static const String scheduleMain = '/diensten';
  static const String shiftManagement = '/diensten/beheer';
  static const String timeTracking = '/diensten/tijd-registratie';
  static const String leaveRequest = '/diensten/verlof-aanvragen';
  static const String calendarView = '/diensten/kalender';
  static const String shiftDetails = '/diensten/details';
  static const String createShift = '/diensten/nieuw';
  static const String editShift = '/diensten/bewerken';
  static const String swapShift = '/diensten/ruilen';
  
  /// Generate routes with proper service provider integration
  static Route<dynamic> generateRoute(RouteSettings settings) {
    debugPrint('$_logTag: Navigating to ${settings.name}');
    
    // Extract arguments safely
    final arguments = settings.arguments as Map<String, dynamic>?;
    
    try {
      switch (settings.name) {
        case scheduleMain:
          return _createProtectedRoute(
            settings: settings,
            builder: (_) => _wrapWithServiceProvider(
              child: ScheduleMainScreen(
                userRole: arguments?['userRole'] ?? UserRole.guard,
                guardId: arguments?['guardId'],
                companyId: arguments?['companyId'],
              ),
            ),
            requiredRoles: [UserRole.guard, UserRole.company, UserRole.admin],
          );
        
        case shiftManagement:
          return _createProtectedRoute(
            settings: settings,
            builder: (_) => _wrapWithServiceProvider(
              child: const ShiftManagementScreen(),
            ),
            requiredRoles: [UserRole.company, UserRole.admin],
          );
        
        case timeTracking:
          return _createProtectedRoute(
            settings: settings,
            builder: (_) => _wrapWithServiceProvider(
              child: const TimeTrackingScreen(),
            ),
            requiredRoles: [UserRole.guard, UserRole.company, UserRole.admin],
          );
        
        case leaveRequest:
          return _createProtectedRoute(
            settings: settings,
            builder: (_) => _wrapWithServiceProvider(
              child: const LeaveRequestScreen(),
            ),
            requiredRoles: [UserRole.guard, UserRole.company, UserRole.admin],
          );
        
        case calendarView:
          return _createProtectedRoute(
            settings: settings,
            builder: (_) => _wrapWithServiceProvider(
              child: const ScheduleCalendarScreen(),
            ),
            requiredRoles: [UserRole.guard, UserRole.company, UserRole.admin],
          );
        
        case shiftDetails:
          return _createProtectedRoute(
            settings: settings,
            builder: (_) => _wrapWithServiceProvider(
              child: ShiftDetailsScreen(
                shiftId: arguments?['shiftId'] ?? '',
                userRole: arguments?['userRole'] ?? UserRole.guard,
              ),
            ),
            requiredRoles: [UserRole.guard, UserRole.company, UserRole.admin],
          );
        
        case createShift:
          return _createProtectedRoute(
            settings: settings,
            builder: (_) => _wrapWithServiceProvider(
              child: CreateShiftScreen(
                userRole: UserRole.company,
                companyId: arguments?['companyId'] ?? '',
              ),
            ),
            requiredRoles: [UserRole.company, UserRole.admin],
          );
        
        case editShift:
          return _createProtectedRoute(
            settings: settings,
            builder: (_) => _wrapWithServiceProvider(
              child: EditShiftScreen(
                shiftId: arguments?['shiftId'] ?? '',
                userRole: arguments?['userRole'] ?? UserRole.company,
              ),
            ),
            requiredRoles: [UserRole.company, UserRole.admin],
          );
        
        case swapShift:
          return _createProtectedRoute(
            settings: settings,
            builder: (_) => _wrapWithServiceProvider(
              child: SwapShiftScreen(
                shiftId: arguments?['shiftId'] ?? '',
                userRole: UserRole.guard,
                guardId: arguments?['guardId'] ?? '',
              ),
            ),
            requiredRoles: [UserRole.guard],
          );
        
        default:
          return _createErrorRoute(settings.name ?? 'unknown');
      }
    } catch (e, stackTrace) {
      debugPrint('$_logTag: Error generating route: $e');
      debugPrint('$_logTag: Stack trace: $stackTrace');
      return _createErrorRoute(settings.name ?? 'error', error: e.toString());
    }
  }
  
  /// Create protected route with authentication and authorization
  static Route<dynamic> _createProtectedRoute({
    required RouteSettings settings,
    required Widget Function(BuildContext) builder,
    required List<UserRole> requiredRoles,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      builder: (context) => _buildProtectedScreen(
        context: context,
        builder: builder,
        requiredRoles: requiredRoles,
      ),
    );
  }
  
  /// Build protected screen with authentication checks
  static Widget _buildProtectedScreen({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    required List<UserRole> requiredRoles,
  }) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Check authentication status
        if (state is! AuthAuthenticated) {
          return _buildAuthenticationRequired(context);
        }
        
        // Check role authorization
        final userRole = _getUserRoleFromType(state.userType);
        if (!_hasRequiredRole(userRole, requiredRoles)) {
          return _buildUnauthorizedAccess(
            context,
            userRole: userRole,
            requiredRoles: requiredRoles,
          );
        }
        
        // User is authenticated and authorized
        return builder(context);
      },
    );
  }
  
  /// Wrap screen with service provider
  static Widget _wrapWithServiceProvider({required Widget child}) {
    return Builder(
      builder: (context) {
        try {
          final serviceProvider = ScheduleServiceProvider.instance;
          
          if (!serviceProvider.isInitialized) {
            return _buildServiceInitializationScreen();
          }
          
          if (!serviceProvider.isHealthy) {
            return _buildServiceUnavailableScreen(context);
          }
          
          return serviceProvider.provideBlocToWidget(child: child);
        } catch (e) {
          debugPrint('$_logTag: Service provider error: $e');
          return _buildServiceErrorScreen(context, error: e.toString());
        }
      },
    );
  }
  
  /// Convert userType string to UserRole enum
  static UserRole _getUserRoleFromType(String userType) {
    switch (userType.toLowerCase()) {
      case 'guard':
        return UserRole.guard;
      case 'company':
        return UserRole.company;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.guard; // Default fallback
    }
  }
  
  /// Check if user has required role
  static bool _hasRequiredRole(UserRole userRole, List<UserRole> requiredRoles) {
    return requiredRoles.contains(userRole);
  }
  
  /// Build authentication required screen
  static Widget _buildAuthenticationRequired(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.colorGray50,
      body: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: DesignTokens.colorError,
                ),
                const SizedBox(height: DesignTokens.spacingL),
                Text(
                  'Authenticatie vereist',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeHeading,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: DesignTokens.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingM),
                Text(
                  'U moet ingelogd zijn om deze pagina te bekijken.',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightRegular,
                    color: DesignTokens.mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingXL),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to login using GoRouter
                    context.go('/login');
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Inloggen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.guardPrimary,
                    foregroundColor: DesignTokens.colorWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingXL,
                      vertical: DesignTokens.spacingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Build unauthorized access screen
  static Widget _buildUnauthorizedAccess(
    BuildContext context, {
    required UserRole userRole,
    required List<UserRole> requiredRoles,
  }) {
    return Scaffold(
      backgroundColor: DesignTokens.colorGray50,
      appBar: AppBar(
        title: const Text('Geen toegang'),
        backgroundColor: DesignTokens.colorError,
        foregroundColor: DesignTokens.colorWhite,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block,
                  size: 64,
                  color: DesignTokens.colorError,
                ),
                const SizedBox(height: DesignTokens.spacingL),
                Text(
                  'Geen toegang',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeHeading,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: DesignTokens.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingM),
                Text(
                  'U heeft geen toegang tot deze functie.\n'
                  'Huidige rol: ${_getRoleDisplayName(userRole)}\n'
                  'Vereiste rollen: ${requiredRoles.map(_getRoleDisplayName).join(', ')}',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightRegular,
                    color: DesignTokens.mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingXL),
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Terug'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.colorGray600,
                    foregroundColor: DesignTokens.colorWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Build service initialization screen
  static Widget _buildServiceInitializationScreen() {
    return Scaffold(
      backgroundColor: DesignTokens.colorGray50,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(DesignTokens.guardPrimary),
                strokeWidth: 3,
              ),
              const SizedBox(height: DesignTokens.spacingL),
              Text(
                'Diensten initialiseren...',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.darkText,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingM),
              Text(
                'Even geduld, we maken alles gereed.',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: DesignTokens.fontWeightRegular,
                  color: DesignTokens.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build service unavailable screen
  static Widget _buildServiceUnavailableScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.colorGray50,
      body: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: DesignTokens.colorWarning,
                ),
                const SizedBox(height: DesignTokens.spacingL),
                Text(
                  'Service tijdelijk niet beschikbaar',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeHeading,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: DesignTokens.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Er is een probleem met de dienstplanning service. Probeer het later opnieuw.',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightRegular,
                    color: DesignTokens.mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingXL),
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Probeer opnieuw'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.colorWarning,
                    foregroundColor: DesignTokens.colorWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Build service error screen
  static Widget _buildServiceErrorScreen(BuildContext context, {required String error}) {
    return Scaffold(
      backgroundColor: DesignTokens.colorGray50,
      appBar: AppBar(
        title: const Text('Service Error'),
        backgroundColor: DesignTokens.colorError,
        foregroundColor: DesignTokens.colorWhite,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bug_report,
                  size: 64,
                  color: DesignTokens.colorError,
                ),
                const SizedBox(height: DesignTokens.spacingL),
                Text(
                  'Service fout',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeHeading,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: DesignTokens.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Er is een onverwachte fout opgetreden:\n$error',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightRegular,
                    color: DesignTokens.mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingXL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Terug'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.colorGray600,
                        foregroundColor: DesignTokens.colorWhite,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingM),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Report error
                        debugPrint('$_logTag: User reported error: $error');
                      },
                      icon: const Icon(Icons.report_problem),
                      label: const Text('Rapporteer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.colorError,
                        foregroundColor: DesignTokens.colorWhite,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Create error route for unknown routes
  static Route<dynamic> _createErrorRoute(String routeName, {String? error}) {
    return MaterialPageRoute<dynamic>(
      builder: (context) => Scaffold(
        backgroundColor: DesignTokens.colorGray50,
        appBar: AppBar(
          title: const Text('Route niet gevonden'),
          backgroundColor: DesignTokens.colorError,
          foregroundColor: DesignTokens.colorWhite,
        ),
        body: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spacingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: DesignTokens.colorError,
                  ),
                  const SizedBox(height: DesignTokens.spacingL),
                  Text(
                    'Pagina niet gevonden',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeHeading,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: DesignTokens.darkText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spacingM),
                  Text(
                    'De route "$routeName" bestaat niet.',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightRegular,
                      color: DesignTokens.mutedText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: DesignTokens.spacingS),
                    Text(
                      'Fout: $error',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: DesignTokens.fontWeightRegular,
                        color: DesignTokens.colorError,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: DesignTokens.spacingXL),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/beveiliger/dashboard'),
                    icon: const Icon(Icons.home),
                    label: const Text('Naar hoofdmenu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.guardPrimary,
                      foregroundColor: DesignTokens.colorWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Get display name for user role
  static String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.guard:
        return 'Beveiliger';
      case UserRole.company:
        return 'Bedrijf';
      case UserRole.admin:
        return 'Beheerder';
    }
  }
  
  /// Navigation helper methods
  static void navigateToScheduleMain(
    BuildContext context, {
    required UserRole userRole,
    String? guardId,
    String? companyId,
  }) {
    // Use GoRouter navigation to schedule
    if (userRole == UserRole.guard) {
      context.go('/beveiliger/schedule');
    } else {
      context.go('/company/schedule'); // TODO: Add company schedule route if needed
    }
  }
  
  static void navigateToTimeTracking(
    BuildContext context, {
    required UserRole userRole,
    String? guardId,
  }) {
    // Use GoRouter navigation - time tracking is part of schedule
    if (userRole == UserRole.guard) {
      context.go('/beveiliger/schedule');
    }
  }
  
  static void navigateToShiftManagement(
    BuildContext context, {
    required UserRole userRole,
    String? companyId,
  }) {
    // Use GoRouter navigation - shift management is part of schedule
    if (userRole == UserRole.guard) {
      context.go('/beveiliger/schedule');
    } else {
      context.go('/company/schedule'); // TODO: Add company schedule route if needed  
    }
  }
  
  static void navigateToCalendar(
    BuildContext context, {
    required UserRole userRole,
    String? guardId,
    String? companyId,
    CalendarViewMode viewMode = CalendarViewMode.month,
  }) {
    // Use GoRouter navigation - calendar is part of schedule
    if (userRole == UserRole.guard) {
      context.go('/beveiliger/schedule');
    } else {
      context.go('/company/schedule'); // TODO: Add company schedule route if needed
    }
  }
}

/// Calendar view modes
enum CalendarViewMode {
  day,
  week,
  month,
}
