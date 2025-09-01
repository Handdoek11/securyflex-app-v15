import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/company_dashboard/models/team_management_data.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart'
    show GuardAvailabilityStatus;
import 'package:securyflex_app/company_dashboard/localization/team_management_nl.dart';
import 'package:securyflex_app/company_dashboard/bloc/team_management_bloc.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/routing/app_routes.dart';

/// Team Management screen for companies to manage their security guards
/// Features real-time status tracking, scheduling, and analytics
class TeamManagementScreen extends StatefulWidget {
  final AnimationController? animationController;

  const TeamManagementScreen({super.key, this.animationController});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _loadTeamData() {
    final companyId = AuthService.currentUserId;
    if (companyId.isNotEmpty) {
      context.read<TeamManagementBloc>().add(LoadCompanyTeam(companyId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return BlocProvider(
      create: (context) {
        final bloc = TeamManagementBloc();
        // Load team data when the BLoC is created
        final companyId = AuthService.currentUserId;
        if (companyId.isNotEmpty) {
          bloc.add(LoadCompanyTeam(companyId));
        }
        return bloc;
      },
      child: BlocBuilder<TeamManagementBloc, TeamManagementState>(
        builder: (context, state) {
          return Container(
            color: companyColors.surfaceContainerHighest,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: UnifiedHeader.companyGradient(
                  title: TeamManagementNL.teamManagement,
                  showNotifications: true,
                  onNotificationPressed: () => _navigateToNotifications(),
                ),
              ),
              body: state.isLoading
                  ? _buildLoadingState()
                  : state.status == TeamManagementStatus.error
                  ? _buildErrorState(state.errorMessage)
                  : _buildSectionBasedContent(state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionBasedContent(TeamManagementState state) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeamStatusSection(state),
          SizedBox(height: DesignTokens.spacingXL),
          _buildPlanningSection(state),
          SizedBox(height: DesignTokens.spacingXL),
          _buildAnalyticsSection(state),
        ],
      ),
    );
  }

  void _navigateToNotifications() {
    // Navigate to notifications screen
    context.go(AppRoutes.companyNotifications);
  }

  Widget _buildLoadingState() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Center(
      child: CircularProgressIndicator(color: companyColors.primary),
    );
  }

  Widget _buildErrorState([String? errorMessage]) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: DesignTokens.colorError),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              errorMessage ?? TeamManagementNL.errorLoadingData,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.spacingM),
            ElevatedButton(
              onPressed: _loadTeamData,
              child: Text(TeamManagementNL.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamStatusSection(TeamManagementState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TeamManagementNL.status,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSection,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        _buildTeamOverviewCards(state),
        SizedBox(height: DesignTokens.spacingL),
        _buildCoverageGapsSection(state),
        SizedBox(height: DesignTokens.spacingL),
        _buildGuardStatusList(state),
        SizedBox(height: DesignTokens.spacingL),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildPlanningSection(TeamManagementState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TeamManagementNL.planning,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSection,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        _buildScheduleHeader(),
        SizedBox(height: DesignTokens.spacingL),
        _buildScheduleFilters(),
        SizedBox(height: DesignTokens.spacingL),
        _buildTodaySchedule(),
        SizedBox(height: DesignTokens.spacingL),
        _buildUpcomingShifts(),
        SizedBox(height: DesignTokens.spacingL),
        _buildScheduleActions(),
      ],
    );
  }

  Widget _buildAnalyticsSection(TeamManagementState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TeamManagementNL.analytics,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSection,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        if (state.teamStatus != null) _buildAnalyticsMetrics(state),
      ],
    );
  }

  Widget _buildTeamOverviewCards(TeamManagementState state) {
    final teamStatus = state.teamStatus;
    if (teamStatus == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            TeamManagementNL.totalGuards,
            '${teamStatus.totalGuards}',
            Icons.groups,
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: _buildMetricCard(
            TeamManagementNL.availableGuards,
            '${teamStatus.availableGuards}',
            Icons.check_circle,
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: _buildMetricCard(
            TeamManagementNL.onDutyGuards,
            '${teamStatus.onDutyGuards}',
            Icons.work,
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: _buildMetricCard(
            TeamManagementNL.coverageGaps,
            '${teamStatus.coverageGaps.length}',
            Icons.warning,
            isWarning: teamStatus.coverageGaps.isNotEmpty,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon, {
    bool isWarning = false,
  }) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    final cardColor = isWarning
        ? DesignTokens.colorWarning
        : companyColors.primary;

    return UnifiedCard.compact(
      userRole: UserRole.company,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: cardColor, size: DesignTokens.iconSizeL),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightBold,
              fontSize: DesignTokens.fontSizeHeadline,
              color: cardColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: DesignTokens.fontSizeCaption,
              color: companyColors.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageGapsSection(TeamManagementState state) {
    final teamStatus = state.teamStatus;
    if (teamStatus?.coverageGaps.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TeamManagementNL.coverageGaps,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontSize: DesignTokens.fontSizeSection,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        ...teamStatus!.coverageGaps.map((gap) => _buildCoverageGapCard(gap)),
      ],
    );
  }

  Widget _buildCoverageGapCard(CoverageGap gap) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: UnifiedCard.standard(
        userRole: UserRole.company,
        backgroundColor: DesignTokens.colorWarning.withValues(alpha: 0.1),
        child: Row(
          children: [
            Icon(Icons.warning, color: DesignTokens.colorWarning),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gap.location,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontSize: DesignTokens.fontSizeBody,
                    ),
                  ),
                  Text(
                    '${gap.startTime.hour.toString().padLeft(2, '0')}:${gap.startTime.minute.toString().padLeft(2, '0')} - ${gap.endTime.hour.toString().padLeft(2, '0')}:${gap.endTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeMeta,
                    ),
                  ),
                  if (gap.affectedJobTitles.isNotEmpty)
                    Text(
                      gap.affectedJobTitles.first,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeMeta,
                        color: companyColors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to job posting to resolve gap
                context.go(AppRoutes.companyJobPosting);
              },
              child: Text(TeamManagementNL.newJob),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardStatusList(TeamManagementState state) {
    final teamStatus = state.teamStatus;
    if (teamStatus?.activeGuardLocations.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TeamManagementNL.teamStatusOverview,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontSize: DesignTokens.fontSizeSection,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        ...teamStatus!.activeGuardLocations.map(
          (guard) => _buildGuardStatusCard(guard),
        ),
      ],
    );
  }

  Widget _buildGuardStatusCard(GuardLocationData guard) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    final statusColor = _getStatusColor(guard.status);

    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: UnifiedCard.standard(
        userRole: UserRole.company,
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guard.guardName,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontSize: DesignTokens.fontSizeBody,
                    ),
                  ),
                  if (guard.currentLocation != null)
                    Text(
                      '📍 ${guard.currentLocation}',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeMeta,
                      ),
                    ),
                  if (guard.currentAssignmentTitle != null)
                    Text(
                      guard.currentAssignmentTitle!,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeMeta,
                        color: companyColors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              _getStatusDisplayName(guard.status),
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeMeta,
                color: statusColor,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Refresh team data
              context.read<TeamManagementBloc>().add(RefreshCompanyTeam());
            },
            icon: const Icon(Icons.refresh),
            label: Text(TeamManagementNL.refresh),
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to team management
              context.go(AppRoutes.companyTeamManagement);
            },
            icon: const Icon(Icons.people),
            label: Text(TeamManagementNL.teamBeheer),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsMetrics(TeamManagementState state) {
    final teamStatus = state.teamStatus;
    final metrics = teamStatus!.metrics;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                TeamManagementNL.averageRating,
                metrics.averageRating.toStringAsFixed(1),
                Icons.star,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: _buildMetricCard(
                TeamManagementNL.reliabilityScore,
                '${metrics.reliabilityScore.toStringAsFixed(1)}%',
                Icons.verified,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                TeamManagementNL.responseTime,
                '${metrics.averageResponseTime.toStringAsFixed(0)}m',
                Icons.timer,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: _buildMetricCard(
                TeamManagementNL.revenueGenerated,
                TeamManagementNL.currencyFormat(metrics.revenueThisMonth),
                Icons.euro,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(GuardAvailabilityStatus status) {
    switch (status) {
      case GuardAvailabilityStatus.available:
        return DesignTokens.colorSuccess;
      case GuardAvailabilityStatus.onDuty:
        return DesignTokens.colorInfo;
      case GuardAvailabilityStatus.busy:
        return DesignTokens.colorWarning;
      case GuardAvailabilityStatus.unavailable:
        return DesignTokens.colorError;
    }
  }

  String _getStatusDisplayName(GuardAvailabilityStatus status) {
    switch (status) {
      case GuardAvailabilityStatus.available:
        return TeamManagementNL.available;
      case GuardAvailabilityStatus.onDuty:
        return TeamManagementNL.onDuty;
      case GuardAvailabilityStatus.busy:
        return TeamManagementNL.busy;
      case GuardAvailabilityStatus.unavailable:
        return TeamManagementNL.unavailable;
    }
  }

  Widget _buildScheduleHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          TeamManagementNL.planningAndSchedules,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightBold,
            fontSize: DesignTokens.fontSizeHeadline,
          ),
        ),
        IconButton(
          onPressed: () {
            // Refresh team data
            context.read<TeamManagementBloc>().add(RefreshCompanyTeam());
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildScheduleFilters() {
    return Row(
      children: [
        Expanded(
          child: UnifiedCard.compact(
            userRole: UserRole.company,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: DesignTokens.iconSizeS,
                  color: SecuryFlexTheme.getColorScheme(
                    UserRole.company,
                  ).primary,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  TeamManagementNL.today,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontSize: DesignTokens.fontSizeBody,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: UnifiedCard.compact(
            userRole: UserRole.company,
            backgroundColor: SecuryFlexTheme.getColorScheme(
              UserRole.company,
            ).surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  Icons.view_week,
                  size: DesignTokens.iconSizeS,
                  color: SecuryFlexTheme.getColorScheme(
                    UserRole.company,
                  ).onSurface.withValues(alpha: 0.7),
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  TeamManagementNL.thisWeek,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeBody,
                    color: SecuryFlexTheme.getColorScheme(
                      UserRole.company,
                    ).onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${TeamManagementNL.today} - ${DateTime.now().day}/${DateTime.now().month}',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontSize: DesignTokens.fontSizeSection,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        _buildShiftCard(
          time: '06:00 - 14:00',
          guardName: 'Jan de Vries',
          location: 'Amsterdam Centrum',
          jobType: TeamManagementNL.objectSecurity,
          rating: 4.8,
          status: TeamManagementNL.active,
          statusColor: DesignTokens.colorSuccess,
        ),
        SizedBox(height: DesignTokens.spacingM),
        _buildShiftCard(
          time: '14:00 - 22:00',
          guardName: null, // Coverage gap
          location: 'Rotterdam Zuid',
          jobType: TeamManagementNL.eventSecurity,
          rating: null,
          status: TeamManagementNL.coverageNeeded,
          statusColor: DesignTokens.colorWarning,
          isGap: true,
        ),
        SizedBox(height: DesignTokens.spacingM),
        _buildShiftCard(
          time: '22:00 - 06:00',
          guardName: 'Marie Bakker',
          location: 'Den Haag Noord',
          jobType: TeamManagementNL.nightSecurity,
          rating: 4.6,
          status: TeamManagementNL.scheduled,
          statusColor: DesignTokens.colorInfo,
        ),
      ],
    );
  }

  Widget _buildShiftCard({
    required String time,
    String? guardName,
    required String location,
    required String jobType,
    double? rating,
    required String status,
    required Color statusColor,
    bool isGap = false,
  }) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return UnifiedCard.standard(
      userRole: UserRole.company,
      backgroundColor: isGap
          ? DesignTokens.colorWarning.withValues(alpha: 0.1)
          : companyColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontSize: DesignTokens.fontSizeBody,
                  color: companyColors.primary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeMeta,
                    color: statusColor,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          if (guardName != null) ...[
            Text(
              guardName,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontSize: DesignTokens.fontSizeSection,
              ),
            ),
            if (rating != null) ...[
              SizedBox(height: DesignTokens.spacingXS),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: DesignTokens.iconSizeS,
                    color: DesignTokens.colorWarning,
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightMedium,
                      fontSize: DesignTokens.fontSizeMeta,
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.warning,
                  size: DesignTokens.iconSizeM,
                  color: DesignTokens.colorWarning,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  TeamManagementNL.noGuardAssigned,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeSection,
                    color: DesignTokens.colorWarning,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: DesignTokens.spacingS),
          Text(
            '$jobType • $location',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeBody,
              color: companyColors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (isGap) ...[
            SizedBox(height: DesignTokens.spacingM),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to job posting to find replacement
                context.go(AppRoutes.companyJobPosting);
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text(TeamManagementNL.postNewJob),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.colorWarning,
                foregroundColor: DesignTokens.colorWhite,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingShifts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TeamManagementNL.upcomingShifts,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontSize: DesignTokens.fontSizeSection,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        UnifiedCard.standard(
          userRole: UserRole.company,
          backgroundColor: SecuryFlexTheme.getColorScheme(
            UserRole.company,
          ).surfaceContainerHighest,
          child: Column(
            children: [
              Icon(
                Icons.schedule,
                size: DesignTokens.iconSizeXL,
                color: SecuryFlexTheme.getColorScheme(UserRole.company).primary,
              ),
              SizedBox(height: DesignTokens.spacingS),
              Text(
                TeamManagementNL.loadingTeamData,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeBody,
                  color: SecuryFlexTheme.getColorScheme(
                    UserRole.company,
                  ).onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to job posting
              context.go(AppRoutes.companyJobPosting);
            },
            icon: const Icon(Icons.add),
            label: Text(TeamManagementNL.newJob),
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Refresh data
              context.read<TeamManagementBloc>().add(RefreshCompanyTeam());
            },
            icon: const Icon(Icons.refresh),
            label: Text(TeamManagementNL.refresh),
          ),
        ),
      ],
    );
  }
}
