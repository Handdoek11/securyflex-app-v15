import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_buttons.dart';
import '../../unified_theme_system.dart';
import '../services/schedule_service_provider.dart';
import '../navigation/schedule_routes.dart';
import '../architecture/schedule_data_flow.dart';
import '../models/shift_model.dart';
import '../blocs/schedule_bloc.dart';

/// MainAppIntegration - Naadloze integratie met bestaande SecuryFlex app
///
/// Biedt:
/// - Integration helpers voor bestaande schermen
/// - Navigation button creation met role-based theming
/// - Service provider registratie voor app bootstrap
/// - Widget wrappers voor schedule functionaliteit
/// - Performance optimized integration patterns
class MainAppIntegration {
  static const String _logTag = 'MainAppIntegration';

  /// Initialize schedule system in main app
  static Future<bool> initializeScheduleSystem(
    BuildContext context, {
    Map<String, dynamic>? config,
  }) async {
    try {
      debugPrint('$_logTag: Initializing schedule system...');

      final serviceProvider = ScheduleServiceProvider.instance;
      
      await serviceProvider.initialize(
        context: context,
        config: config ?? {
          'enableCalendarSync': false,
          'enablePerformanceMonitoring': true,
          'enableHealthChecks': true,
        },
      );

      debugPrint('$_logTag: Schedule system initialized successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('$_logTag: Schedule system initialization failed: $e');
      debugPrint('$_logTag: Stack trace: $stackTrace');
      return false;
    }
  }

  /// Register schedule services in app bootstrap
  static Future<void> registerScheduleServices(
    BuildContext context, {
    required String? guardId,
    required String? companyId,
    Map<String, dynamic>? additionalConfig,
  }) async {
    try {
      debugPrint('$_logTag: Registering schedule services...');

      // Initialize service provider
      final success = await initializeScheduleSystem(
        context,
        config: {
          'enableCalendarSync': true,
          'enablePerformanceMonitoring': true,
          'enableHealthChecks': true,
          'guardId': guardId,
          'companyId': companyId,
          ...?additionalConfig,
        },
      );

      if (!success) {
        throw StateError('Failed to initialize schedule system');
      }

      // Initialize schedule data if user context is available
      if (guardId != null || companyId != null) {
        await ScheduleDataFlow.initializeSchedule(
          context,
          guardId: guardId,
          companyId: companyId,
          showLoading: false,
        );
      }

      debugPrint('$_logTag: Schedule services registered successfully');
    } catch (e, stackTrace) {
      debugPrint('$_logTag: Schedule service registration failed: $e');
      debugPrint('$_logTag: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Provide schedule BLoC to widget tree
  static Widget provideScheduleBloc({
    required Widget child,
    String? guardId,
    String? companyId,
  }) {
    return Builder(
      builder: (context) {
        try {
          final serviceProvider = ScheduleServiceProvider.instance;
          
          if (!serviceProvider.isInitialized) {
            return _buildInitializationWidget();
          }

          if (!serviceProvider.isHealthy) {
            return _buildServiceUnavailableWidget();
          }

          return serviceProvider.provideBlocToWidget(
            child: child,
            guardId: guardId,
            companyId: companyId,
          );
        } catch (e) {
          debugPrint('$_logTag: Failed to provide schedule BLoC: $e');
          return _buildErrorWidget(e.toString());
        }
      },
    );
  }

  /// Create schedule navigation button for main menu
  static Widget createScheduleNavigationButton({
    required BuildContext context,
    required UserRole userRole,
    String? guardId,
    String? companyId,
    bool showBadge = false,
    String? badgeText,
    VoidCallback? onPressed,
  }) {
    return UnifiedButton(
      text: _getNavigationButtonText(userRole),
      icon: _getNavigationButtonIcon(userRole),
      onPressed: onPressed ?? () => _navigateToSchedule(
        context,
        userRole: userRole,
        guardId: guardId,
        companyId: companyId,
      ),
      type: UnifiedButtonType.primary,
      backgroundColor: _getPrimaryColor(userRole),
      foregroundColor: DesignTokens.colorWhite,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingM,
      ),
      borderRadius: DesignTokens.radiusM,
    );
  }

  /// Create compact schedule widget for dashboard
  static Widget createScheduleDashboardWidget({
    required UserRole userRole,
    String? guardId,
    String? companyId,
    bool showHeader = true,
    VoidCallback? onViewAll,
  }) {
    return Builder(
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: DesignTokens.colorWhite,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            boxShadow: [DesignTokens.shadowMedium],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) _buildDashboardHeader(
                context,
                userRole: userRole,
                onViewAll: onViewAll,
              ),
              _buildDashboardContent(
                context,
                userRole: userRole,
                guardId: guardId,
                companyId: companyId,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Create time clock widget for home screen integration
  static Widget createTimeClockWidget({
    required UserRole userRole,
    required String? guardId,
    bool compact = false,
  }) {
    if (userRole != UserRole.guard || guardId == null) {
      return const SizedBox.shrink();
    }

    return Builder(
      builder: (context) {
        // Using placeholder state for now due to BLoC configuration issues
        final state = ScheduleLoaded(shifts: []);
        return Builder(
          builder: (context) {
            if (state is! ScheduleLoaded) {
              return _buildTimeClockPlaceholder(compact);
            }

            return Container(
              margin: EdgeInsets.all(compact ? DesignTokens.spacingS : DesignTokens.spacingM),
              padding: EdgeInsets.all(compact ? DesignTokens.spacingM : DesignTokens.spacingL),
              decoration: BoxDecoration(
                color: DesignTokens.guardBackground,
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                boxShadow: [DesignTokens.shadowMedium],
              ),
              child: compact ? _buildCompactTimeClock(context, state, guardId) 
                            : _buildFullTimeClock(context, state, guardId),
            );
          },
        );
      },
    );
  }

  /// Create schedule status indicator
  static Widget createScheduleStatusIndicator({
    required UserRole userRole,
    String? guardId,
    String? companyId,
  }) {
    return Builder(
      builder: (context) {
        // Using placeholder state for now due to BLoC configuration issues
        final state = ScheduleLoaded(shifts: []);
        return Builder(
          builder: (context) {
            return _buildStatusIndicator(state, userRole);
          },
        );
      },
    );
  }

  /// Add schedule route to main app router
  static Map<String, WidgetBuilder> getScheduleRoutes() {
    return {
      ScheduleRoutes.scheduleMain: (context) => _buildScheduleMainWithProvider(context),
      ScheduleRoutes.timeTracking: (context) => _buildTimeTrackingWithProvider(context),
      ScheduleRoutes.calendarView: (context) => _buildCalendarWithProvider(context),
      ScheduleRoutes.shiftManagement: (context) => _buildShiftManagementWithProvider(context),
      ScheduleRoutes.leaveRequest: (context) => _buildLeaveRequestWithProvider(context),
    };
  }

  /// Health check for schedule system
  static Future<bool> performScheduleHealthCheck() async {
    try {
      final serviceProvider = ScheduleServiceProvider.instance;
      
      if (!serviceProvider.isInitialized) {
        return false;
      }

      final healthResult = await serviceProvider.performHealthCheck();
      return healthResult.isHealthy;
    } catch (e) {
      debugPrint('$_logTag: Health check failed: $e');
      return false;
    }
  }

  /// Cleanup schedule resources
  static Future<void> cleanupScheduleResources() async {
    try {
      debugPrint('$_logTag: Cleaning up schedule resources...');
      
      final serviceProvider = ScheduleServiceProvider.instance;
      await serviceProvider.dispose();
      
      debugPrint('$_logTag: Schedule resources cleaned up');
    } catch (e) {
      debugPrint('$_logTag: Cleanup failed: $e');
    }
  }

  // Private helper methods
  static Future<void> _navigateToSchedule(
    BuildContext context, {
    required UserRole userRole,
    String? guardId,
    String? companyId,
  }) async {
    try {
      // Ensure schedule system is initialized
      final isHealthy = await performScheduleHealthCheck();
      
      if (!isHealthy) {
        _showInitializationError(context);
        return;
      }

      ScheduleRoutes.navigateToScheduleMain(
        context,
        userRole: userRole,
        guardId: guardId,
        companyId: companyId,
      );
    } catch (e) {
      debugPrint('$_logTag: Navigation to schedule failed: $e');
      _showNavigationError(context, e.toString());
    }
  }

  static Widget _buildDashboardHeader(
    BuildContext context, {
    required UserRole userRole,
    VoidCallback? onViewAll,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: _getPrimaryColor(userRole).withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusL),
          topRight: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: _getPrimaryColor(userRole),
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                _getDashboardTitle(userRole),
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: _getPrimaryColor(userRole),
                ),
              ),
            ],
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'Alles bekijken',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: _getPrimaryColor(userRole),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildDashboardContent(
    BuildContext context, {
    required UserRole userRole,
    String? guardId,
    String? companyId,
  }) {
    // Using placeholder state for now due to BLoC configuration issues
    final state = ScheduleLoaded(shifts: []);
    return Builder(
      builder: (context) {
        if (state is ScheduleLoaded) {
          return _buildUpcomingShiftsPreview(state, userRole);
        }
        return _buildDashboardPlaceholder();
      },
    );
  }

  static Widget _buildUpcomingShiftsPreview(ScheduleLoaded state, UserRole userRole) {
    final upcomingShifts = state.shifts
        .where((shift) => shift.startTime.isAfter(DateTime.now()))
        .take(3)
        .toList();

    if (upcomingShifts.isEmpty) {
      return _buildNoUpcomingShifts(userRole);
    }

    return Column(
      children: upcomingShifts.map((shift) => Container(
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          color: DesignTokens.colorGray50,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: _getStatusColor(shift.status),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.shiftTitle,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: DesignTokens.darkText,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: DesignTokens.fontWeightRegular,
                      color: DesignTokens.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  static Widget _buildCompactTimeClock(BuildContext context, ScheduleLoaded state, String guardId) {
    final activeShift = _getActiveShift(state, guardId);
    final isCheckedIn = _isCurrentlyCheckedIn(state);

    return Column(
      children: [
        Text(
          'Tijd Registratie',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTimeClockButton(
              context,
              icon: isCheckedIn ? Icons.stop_circle : Icons.play_circle_fill,
              label: isCheckedIn ? 'Uitchecken' : 'Inchecken',
              color: isCheckedIn ? DesignTokens.colorError : DesignTokens.colorSuccess,
              onPressed: () => _handleTimeClockAction(
                context,
                isCheckedIn ? TimeClockOperation.checkOut : TimeClockOperation.checkIn,
                guardId,
              ),
              enabled: activeShift != null,
            ),
            if (isCheckedIn) _buildTimeClockButton(
              context,
              icon: Icons.coffee,
              label: 'Pauze',
              color: DesignTokens.colorWarning,
              onPressed: () => _handleTimeClockAction(
                context,
                TimeClockOperation.startBreak,
                guardId,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _buildFullTimeClock(BuildContext context, ScheduleLoaded state, String guardId) {
    return Column(
      children: [
        Text(
          'Tijd Registratie',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingL),
        Text(
          'Volledige tijd registratie beschikbaar in hoofdscherm',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.guardTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spacingL),
        UnifiedButton(
          text: 'Open Tijd Registratie',
          icon: Icons.access_time,
          type: UnifiedButtonType.primary,
          onPressed: () => ScheduleRoutes.navigateToTimeTracking(
            context,
            userRole: UserRole.guard,
            guardId: guardId,
          ),
        ),
      ],
    );
  }

  static Widget _buildTimeClockButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled ? color : DesignTokens.colorGray400,
            foregroundColor: DesignTokens.colorWhite,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(DesignTokens.spacingL),
          ),
          child: Icon(icon, size: DesignTokens.iconSizeL),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightMedium,
            color: enabled ? color : DesignTokens.colorGray400,
          ),
        ),
      ],
    );
  }

  static Widget _buildStatusIndicator(ScheduleState state, UserRole userRole) {
    if (state is ScheduleLoaded) {
      final activeShifts = state.shifts.where((s) => s.status == ShiftStatus.inProgress).length;
      
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        decoration: BoxDecoration(
          color: _getPrimaryColor(userRole).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(color: _getPrimaryColor(userRole).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.work,
              color: _getPrimaryColor(userRole),
              size: DesignTokens.iconSizeS,
            ),
            const SizedBox(width: DesignTokens.spacingS),
            Text(
              '$activeShifts actieve diensten',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightMedium,
                color: _getPrimaryColor(userRole),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  // Placeholder builder methods
  static Widget _buildInitializationWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: DesignTokens.spacingM),
          Text('Diensten initialiseren...'),
        ],
      ),
    );
  }

  static Widget _buildServiceUnavailableWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: DesignTokens.colorError,
            size: 64,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          const Text('Diensten tijdelijk niet beschikbaar'),
        ],
      ),
    );
  }

  static Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bug_report,
            color: DesignTokens.colorError,
            size: 64,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text('Fout: $error'),
        ],
      ),
    );
  }

  // Route builder methods (placeholders)
  static Widget _buildScheduleMainWithProvider(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Schedule Main - Coming Soon')),
    );
  }

  static Widget _buildTimeTrackingWithProvider(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Time Tracking - Coming Soon')),
    );
  }

  static Widget _buildCalendarWithProvider(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Calendar - Coming Soon')),
    );
  }

  static Widget _buildShiftManagementWithProvider(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Shift Management - Coming Soon')),
    );
  }

  static Widget _buildLeaveRequestWithProvider(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Leave Request - Coming Soon')),
    );
  }

  // Helper methods for placeholders and data
  static Widget _buildTimeClockPlaceholder(bool compact) {
    return Container(
      height: compact ? 120 : 200,
      decoration: BoxDecoration(
        color: DesignTokens.colorGray200,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  static Widget _buildTimeClockError(String error, bool compact) {
    return Container(
      height: compact ? 120 : 200,
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: DesignTokens.colorError),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: DesignTokens.colorError,
            size: compact ? DesignTokens.iconSizeM : DesignTokens.iconSizeL,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            compact ? 'Fout' : 'Tijd registratie fout',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: compact ? DesignTokens.fontSizeS : DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.colorError,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildDashboardPlaceholder() {
    return Container(
      height: 150,
      margin: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorGray200,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  static Widget _buildDashboardLoading() {
    return const Padding(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  static Widget _buildDashboardError(String error) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Center(
        child: Text(
          'Fout bij laden van diensten: $error',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.colorError,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static Widget _buildNoUpcomingShifts(UserRole userRole) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            color: DesignTokens.colorGray400,
            size: 48,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Geen komende diensten',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatusLoading() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.colorGray200,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: const SizedBox(
        width: 120,
        height: 20,
      ),
    );
  }

  static Widget _buildStatusError() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: DesignTokens.colorError),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: DesignTokens.colorError,
            size: DesignTokens.iconSizeS,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Text(
            'Status fout',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.colorError,
            ),
          ),
        ],
      ),
    );
  }

  // Error handling methods
  static void _showInitializationError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diensten systeem is niet geïnitialiseerd'),
        backgroundColor: DesignTokens.statusCancelled,
      ),
    );
  }

  static void _showNavigationError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigatie fout: $error'),
        backgroundColor: DesignTokens.statusCancelled,
      ),
    );
  }

  // Time clock action handler
  static Future<void> _handleTimeClockAction(
    BuildContext context,
    TimeClockOperation operation,
    String guardId,
  ) async {
    await ScheduleDataFlow.handleTimeClockOperation(
      context,
      operation,
      guardId: guardId,
    );
  }

  // Utility methods
  static String _getNavigationButtonText(UserRole userRole) {
    switch (userRole) {
      case UserRole.guard:
        return 'Mijn Diensten';
      case UserRole.company:
        return 'Dienstplanning';
      case UserRole.admin:
        return 'Systeem Beheer';
    }
  }

  static IconData _getNavigationButtonIcon(UserRole userRole) {
    switch (userRole) {
      case UserRole.guard:
        return Icons.work;
      case UserRole.company:
        return Icons.calendar_month;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  static String _getDashboardTitle(UserRole userRole) {
    switch (userRole) {
      case UserRole.guard:
        return 'Mijn Diensten';
      case UserRole.company:
        return 'Diensten Overzicht';
      case UserRole.admin:
        return 'Platform Overzicht';
    }
  }

  static Color _getPrimaryColor(UserRole userRole) {
    switch (userRole) {
      case UserRole.guard:
        return DesignTokens.guardPrimary;
      case UserRole.company:
        return DesignTokens.companyPrimary;
      case UserRole.admin:
        return DesignTokens.adminPrimary;
    }
  }

  static Color _getStatusColor(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.draft:
        return DesignTokens.statusDraft;
      case ShiftStatus.published:
        return DesignTokens.statusPending;
      case ShiftStatus.applied:
        return DesignTokens.statusPending;
      case ShiftStatus.confirmed:
        return DesignTokens.statusConfirmed;
      case ShiftStatus.inProgress:
        return DesignTokens.statusInProgress;
      case ShiftStatus.completed:
        return DesignTokens.statusCompleted;
      case ShiftStatus.cancelled:
        return DesignTokens.statusCancelled;
      case ShiftStatus.noShow:
        return DesignTokens.statusCancelled;
      case ShiftStatus.expired:
        return DesignTokens.statusCancelled;
      case ShiftStatus.replacement:
        return DesignTokens.statusPending;
    }
  }

  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static Shift? _getActiveShift(ScheduleLoaded state, String guardId) {
    try {
      return state.shifts.firstWhere(
        (shift) => shift.status == ShiftStatus.inProgress ||
                   (shift.assignedGuardId == guardId &&
                    shift.status == ShiftStatus.confirmed &&
                    shift.startTime.isBefore(DateTime.now()) &&
                    shift.endTime.isAfter(DateTime.now())),
      );
    } catch (e) {
      return null;
    }
  }

  static bool _isCurrentlyCheckedIn(ScheduleLoaded state) {
    return state.currentTimeEntry?.checkInTime != null &&
           state.currentTimeEntry?.checkOutTime == null;
  }
}




// Placeholder model classes
class Shift {
  final String id;
  final String shiftTitle;
  final DateTime startTime;
  final DateTime endTime;
  final ShiftStatus status;
  final String? assignedGuardId;

  const Shift({
    required this.id,
    required this.shiftTitle,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.assignedGuardId,
  });
}

// Placeholder state and BLoC classes
abstract class ScheduleState {}
abstract class ScheduleBloc {}

class ScheduleLoaded extends ScheduleState {
  final List<Shift> shifts;
  final TimeEntry? currentTimeEntry;

  ScheduleLoaded({
    required this.shifts,
    this.currentTimeEntry,
  });
}

class TimeEntry {
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  const TimeEntry({
    this.checkInTime,
    this.checkOutTime,
  });
}