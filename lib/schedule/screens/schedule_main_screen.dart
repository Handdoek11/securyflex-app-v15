import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../unified_design_tokens.dart';
import '../../unified_header.dart';
import '../../unified_theme_system.dart' as UnifiedTheme;
import '../../unified_components/smart_tab_bar.dart';
import '../../unified_components/unified_background_service.dart';
import '../blocs/schedule_bloc.dart';
import '../widgets/time_clock_widget.dart' as TimeClock;
import '../widgets/calendar/shift_calendar_widget.dart';
import '../widgets/time_tracking/gps_status_indicator.dart' as GPS;
import '../models/shift_model.dart';
import '../models/time_entry_model.dart';

/// ScheduleMainScreen - Hoofdscherm voor dienstplanning
///
/// Features:
/// - Role-based tabbed interface (Guard/Company/Admin)
/// - Integration met bestaande TimeClockWidget
/// - Quick action buttons en status displays
/// - Nederlandse localization
/// - Performance optimized widgets
/// - Mobile-first responsive design
class ScheduleMainScreen extends StatefulWidget {
  final UnifiedTheme.UserRole userRole;
  final String? guardId;
  final String? companyId;

  const ScheduleMainScreen({
    super.key,
    required this.userRole,
    this.guardId,
    this.companyId,
  });

  @override
  State<ScheduleMainScreen> createState() => _ScheduleMainScreenState();
}

class _ScheduleMainScreenState extends State<ScheduleMainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;
  
  /// Convert unified UserRole to GPS widget UserRole  
  GPS.UserRole _convertGPSUserRole(UnifiedTheme.UserRole role) {
    switch (role) {
      case UnifiedTheme.UserRole.guard:
        return GPS.UserRole.guard;
      case UnifiedTheme.UserRole.company:
        return GPS.UserRole.company;
      case UnifiedTheme.UserRole.admin:
        return GPS.UserRole.admin;
    }
  }
  
  /// Convert unified UserRole to TimeClock widget UserRole
  TimeClock.UserRole _convertTimeClockUserRole(UnifiedTheme.UserRole role) {
    switch (role) {
      case UnifiedTheme.UserRole.guard:
        return TimeClock.UserRole.guard;
      case UnifiedTheme.UserRole.company:
        return TimeClock.UserRole.company;
      case UnifiedTheme.UserRole.admin:
        return TimeClock.UserRole.admin;
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
    
    // Add scroll listener for header opacity animation
    scrollController.addListener(() {
      if (!mounted) return;
      
      if (scrollController.offset >= DesignTokens.spacingL) {
        if (topBarOpacity != 1.0) {
          setState(() {
            topBarOpacity = 1.0;
          });
        }
      } else if (scrollController.offset <= DesignTokens.spacingL &&
          scrollController.offset >= 0) {
        if (topBarOpacity != scrollController.offset / DesignTokens.spacingL) {
          setState(() {
            topBarOpacity = scrollController.offset / DesignTokens.spacingL;
          });
        }
      } else if (scrollController.offset <= 0) {
        if (topBarOpacity != 0.0) {
          setState(() {
            topBarOpacity = 0.0;
          });
        }
      }
    });
    
    _initializeTabs();
    _initializeScheduleData();
  }

  void _initializeTabs() {
    final tabCount = _getTabsForRole().length;
    _tabController = TabController(
      length: tabCount,
      vsync: this,
    );
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
        });
      }
    });
  }

  void _initializeScheduleData() {
    // Initialize schedule data based on user role
    final scheduleBloc = context.read<ScheduleBloc>();
    
    scheduleBloc.add(ScheduleInitialize(
      guardId: widget.guardId,
      companyId: widget.companyId,
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 30)),
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: UnifiedBackgroundService.guardMeshGradient(
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(),
              Expanded(
                child: _buildTabBarView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return UnifiedHeader.animated(
      title: 'Planning',
      animationController: _animationController,
      scrollController: scrollController,
      enableScrollAnimation: true,
      userRole: widget.userRole,
      titleAlignment: TextAlign.left,
      actions: [
        _buildNotificationButton(),
        _buildMoreOptionsButton(),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = _getTabsForRole();
    
    // SmartTabBar already handles its own background and border styling
    return SmartTabBar(
      controller: _tabController,
      userRole: widget.userRole,
      tabs: tabs.map((tab) => SmartTab.textIcon(
        tab.label,
        Icon(tab.icon, size: DesignTokens.iconSizeM),
        badgeIdentifier: 'schedule_${tab.type.toString()}',
      )).toList(),
      size: TabBarSize.compact,  // Same as Jobs page for consistency
      onTap: (index) {
        // Handle tab tap if needed
      },
    );
  }

  Widget _buildTabBarView() {
    final tabs = _getTabsForRole();
    
    return TabBarView(
      controller: _tabController,
      children: tabs.map((tab) {
        switch (tab.type) {
          case ScheduleTabType.overview:
            return _buildOverviewTab();
          case ScheduleTabType.timeTracking:
            return _buildTimeTrackingTab();
          case ScheduleTabType.calendar:
            return _buildCalendarTab();
          case ScheduleTabType.shifts:
            return _buildShiftsTab();
          case ScheduleTabType.management:
            return _buildManagementTab();
          case ScheduleTabType.analytics:
            return _buildAnalyticsTab();
        }
      }).toList(),
    );
  }

  Widget _buildOverviewTab() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickStats(state),
                const SizedBox(height: DesignTokens.spacingL),
                _buildQuickActions(),
                const SizedBox(height: DesignTokens.spacingL),
                if (widget.userRole == UnifiedTheme.UserRole.guard) ...[
                  _buildTimeClockSection(state),
                  const SizedBox(height: DesignTokens.spacingL),
                ],
                _buildUpcomingShifts(state),
                const SizedBox(height: DesignTokens.spacingL),
                _buildRecentActivity(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeTrackingTab() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            children: [
              if (state is ScheduleLoaded && state.lastLocationUpdate != null)
                GPS.GPSStatusIndicator(
                  status: GPS.GPSStatusType.verified,
                  userRole: _convertGPSUserRole(widget.userRole),
                  accuracy: state.lastLocationUpdate!.accuracy,
                  locationName: 'Werk locatie',
                ),
              const SizedBox(height: DesignTokens.spacingL),
              TimeClock.UnifiedTimeClockWidget(
                userRole: _convertTimeClockUserRole(widget.userRole),
                activeShift: _getActiveShift(state),
                currentTimeEntry: _getCurrentTimeEntry(state),
                onCheckIn: _handleCheckIn,
                onCheckOut: _handleCheckOut,
                onStartBreak: _handleStartBreak,
                onEndBreak: _handleEndBreak,
              ),
              const SizedBox(height: DesignTokens.spacingL),
              _buildTimeTrackingHistory(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarTab() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final shifts = state is ScheduleLoaded ? state.shifts : <Shift>[];
        
        return Column(
          children: [
            _buildCalendarControls(),
            Expanded(
              child: ShiftCalendarWidget(
                shifts: shifts,
                timeEntries: const [],
                userRole: widget.userRole,
                initialDate: DateTime.now(),
                onShiftTapped: _handleShiftTap,
                onDateSelected: _handleDateSelected,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShiftsTab() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildShiftsFilter(),
            Expanded(
              child: _buildShiftsList(state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildManagementTab() {
    // Only visible for company and admin roles
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            children: [
              _buildManagementActions(),
              const SizedBox(height: DesignTokens.spacingL),
              _buildShiftManagementCards(),
              const SizedBox(height: DesignTokens.spacingL),
              _buildStaffingOverview(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    // Only visible for admin role
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            children: [
              _buildAnalyticsCards(),
              const SizedBox(height: DesignTokens.spacingL),
              _buildPerformanceCharts(),
              const SizedBox(height: DesignTokens.spacingL),
              _buildComplianceMetrics(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(ScheduleState state) {
    if (state is! ScheduleLoaded) {
      return _buildLoadingStats();
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Actieve Diensten',
            value: state.shifts.where((s) => s.status == ShiftStatus.inProgress).length.toString(),
            icon: Icons.work,
            color: DesignTokens.colorSuccess,
          ),
        ),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: _buildStatCard(
            title: 'Deze Week',
            value: _getWeeklyShiftCount(state.shifts).toString(),
            icon: Icons.calendar_today,
            color: DesignTokens.colorInfo,
          ),
        ),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: _buildStatCard(
            title: 'Vandaag',
            value: _getTodayShiftCount(state.shifts).toString(),
            icon: Icons.today,
            color: DesignTokens.colorWarning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: DesignTokens.iconSizeL,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeXXL,
              fontWeight: DesignTokens.fontWeightBold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: _getTextSecondaryColor(),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Row(
      children: List.generate(3, (index) => Expanded(
        child: Container(
          margin: EdgeInsets.only(
            right: index < 2 ? DesignTokens.spacingM : 0,
          ),
          height: 100,
          decoration: BoxDecoration(
            color: DesignTokens.colorGray200,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(_getPrimaryColor()),
              strokeWidth: 2,
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Snelle Acties',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightBold,
            color: _getTextPrimaryColor(),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    final actions = _getQuickActionsForRole();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: DesignTokens.spacingM,
        mainAxisSpacing: DesignTokens.spacingM,
        childAspectRatio: 2.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionButton(action);
      },
    );
  }

  Widget _buildActionButton(QuickAction action) {
    return ElevatedButton(
      onPressed: action.onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: action.color.withValues(alpha: 0.1),
        foregroundColor: action.color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          side: BorderSide(color: action.color.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, size: DesignTokens.iconSizeM),
          const SizedBox(width: DesignTokens.spacingS),
          Flexible(
            child: Text(
              action.label,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeClockSection(ScheduleState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tijd Registratie',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightBold,
            color: _getTextPrimaryColor(),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        TimeClock.UnifiedTimeClockWidget(
          userRole: _convertTimeClockUserRole(widget.userRole),
          activeShift: _getActiveShift(state),
          currentTimeEntry: _getCurrentTimeEntry(state),
          onCheckIn: _handleCheckIn,
          onCheckOut: _handleCheckOut,
          onStartBreak: _handleStartBreak,
          onEndBreak: _handleEndBreak,
        ),
      ],
    );
  }

  Widget _buildUpcomingShifts(ScheduleState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Komende Diensten',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeL,
                fontWeight: DesignTokens.fontWeightBold,
                color: _getTextPrimaryColor(),
              ),
            ),
            TextButton(
              onPressed: () {
                _tabController.animateTo(2); // Calendar tab
              },
              child: Text(
                'Alles bekijken',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: _getPrimaryColor(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingM),
        _buildUpcomingShiftsList(state),
      ],
    );
  }

  Widget _buildUpcomingShiftsList(ScheduleState state) {
    if (state is! ScheduleLoaded) {
      return _buildLoadingList();
    }

    final upcomingShifts = state.shifts
        .where((shift) => shift.startTime.isAfter(DateTime.now()))
        .take(3)
        .toList();

    if (upcomingShifts.isEmpty) {
      return _buildEmptyUpcomingShifts();
    }

    return Column(
      children: upcomingShifts.map((shift) => _buildShiftCard(shift)).toList(),
    );
  }

  Widget _buildShiftCard(Shift shift) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingS),
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorWhite,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: DesignTokens.colorGray200),
        boxShadow: [DesignTokens.shadowLight],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
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
                    color: _getTextPrimaryColor(),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXS),
                Text(
                  '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightRegular,
                    color: _getTextSecondaryColor(),
                  ),
                ),
                Text(
                  shift.location.address,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightRegular,
                    color: _getTextSecondaryColor(),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: _getTextSecondaryColor(),
            size: DesignTokens.iconSizeM,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(ScheduleState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recente Activiteit',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightBold,
            color: _getTextPrimaryColor(),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        _buildActivityList(),
      ],
    );
  }

  Widget _buildActivityList() {
    // Mock activity data - would come from service
    final activities = [
      'Dienst voltooid: Winkelcentrum Beveiliging',
      'Pauze genomen: 15 minuten',
      'Ingecheckt: Kantoor Amsterdam',
    ];

    return Column(
      children: activities.map((activity) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        margin: const EdgeInsets.only(bottom: DesignTokens.spacingS),
        decoration: BoxDecoration(
          color: DesignTokens.colorGray50,
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: DesignTokens.colorSuccess,
              size: DesignTokens.iconSizeS,
            ),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                activity,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightRegular,
                  color: _getTextSecondaryColor(),
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  // Additional build methods for other tabs
  Widget _buildTimeTrackingHistory(ScheduleState state) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorWhite,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        boxShadow: [DesignTokens.shadowLight],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Geschiedenis',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightBold,
              color: _getTextPrimaryColor(),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Tijd registratie geschiedenis komt hier...',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: _getTextSecondaryColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarControls() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: _getPrimaryColor().withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: _getPrimaryColor().withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatMonth(DateTime.now()),
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightBold,
              color: _getTextPrimaryColor(),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.chevron_left,
                  color: _getPrimaryColor(),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.today,
                  color: _getPrimaryColor(),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.chevron_right,
                  color: _getPrimaryColor(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftsFilter() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorWhite,
        boxShadow: [DesignTokens.shadowLight],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Zoek diensten...',
                prefixIcon: Icon(
                  Icons.search,
                  color: _getPrimaryColor(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  borderSide: BorderSide(color: DesignTokens.colorGray300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  borderSide: BorderSide(color: DesignTokens.colorGray300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  borderSide: BorderSide(color: _getPrimaryColor(), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          IconButton(
            onPressed: () {
              // Show filter dialog
            },
            icon: Icon(
              Icons.filter_list,
              color: _getPrimaryColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftsList(ScheduleState state) {
    if (state is! ScheduleLoaded) {
      return _buildLoadingList();
    }

    if (state.shifts.isEmpty) {
      return _buildEmptyShiftsList();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      itemCount: state.shifts.length,
      itemBuilder: (context, index) {
        final shift = state.shifts[index];
        return _buildDetailedShiftCard(shift);
      },
    );
  }

  Widget _buildDetailedShiftCard(Shift shift) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingM),
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorWhite,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        boxShadow: [DesignTokens.shadowMedium],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  shift.shiftTitle,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeL,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: _getTextPrimaryColor(),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(shift.status),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  _getStatusText(shift.status),
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeXS,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: DesignTokens.colorWhite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: _getTextSecondaryColor(),
                size: DesignTokens.iconSizeS,
              ),
              const SizedBox(width: DesignTokens.spacingXS),
              Text(
                '${_formatDateTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightRegular,
                  color: _getTextSecondaryColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingXS),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: _getTextSecondaryColor(),
                size: DesignTokens.iconSizeS,
              ),
              const SizedBox(width: DesignTokens.spacingXS),
              Expanded(
                child: Text(
                  shift.location.address,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightRegular,
                    color: _getTextSecondaryColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _handleShiftTap(shift),
                icon: Icon(
                  Icons.visibility,
                  size: DesignTokens.iconSizeS,
                ),
                label: const Text('Details'),
                style: TextButton.styleFrom(
                  foregroundColor: _getPrimaryColor(),
                ),
              ),
              if (_canEditShift(shift)) ...[
                const SizedBox(width: DesignTokens.spacingS),
                TextButton.icon(
                  onPressed: () => _handleEditShift(shift),
                  icon: Icon(
                    Icons.edit,
                    size: DesignTokens.iconSizeS,
                  ),
                  label: const Text('Bewerken'),
                  style: TextButton.styleFrom(
                    foregroundColor: _getPrimaryColor(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Management and Analytics tab builders (simplified)
  Widget _buildManagementActions() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorWhite,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        boxShadow: [DesignTokens.shadowLight],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Beheer Acties',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightBold,
              color: _getTextPrimaryColor(),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Dienstbeheer functionaliteit komt hier...',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: _getTextSecondaryColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftManagementCards() {
    return const SizedBox.shrink(); // Placeholder
  }

  Widget _buildStaffingOverview(ScheduleState state) {
    return const SizedBox.shrink(); // Placeholder
  }

  Widget _buildAnalyticsCards() {
    return const SizedBox.shrink(); // Placeholder
  }

  Widget _buildPerformanceCharts() {
    return const SizedBox.shrink(); // Placeholder
  }

  Widget _buildComplianceMetrics(ScheduleState state) {
    return const SizedBox.shrink(); // Placeholder
  }

  Widget _buildEmptyUpcomingShifts() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: DesignTokens.colorGray50,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
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
              color: _getTextSecondaryColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyShiftsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_off,
            color: DesignTokens.colorGray400,
            size: 64,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          Text(
            'Geen diensten gevonden',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightBold,
              color: _getTextSecondaryColor(),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          if (widget.userRole == UnifiedTheme.UserRole.company) ...[
            ElevatedButton.icon(
              onPressed: () {
                context.push('/schedule/shift-management');
              },
              icon: const Icon(Icons.add),
              label: const Text('Nieuwe Dienst'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getPrimaryColor(),
                foregroundColor: _getOnPrimaryColor(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: DesignTokens.spacingM),
          height: 120,
          decoration: BoxDecoration(
            color: DesignTokens.colorGray200,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
        );
      },
    );
  }

  Widget _buildNotificationButton() {
    return HeaderElements.actionButton(
      icon: Icons.notifications_outlined,
      onPressed: () {
        // Show notifications
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Meldingen functionaliteit komt binnenkort'),
            backgroundColor: _getPrimaryColor(),
          ),
        );
      },
      color: _getOnPrimaryColor(),
      userRole: widget.userRole,
    );
  }

  Widget _buildMoreOptionsButton() {
    return HeaderElements.actionButton(
      icon: Icons.more_vert,
      onPressed: () {
        _showMoreOptionsMenu();
      },
      color: _getOnPrimaryColor(),
      userRole: widget.userRole,
    );
  }

  Widget? _buildFloatingActionButton() {
    if (widget.userRole != UnifiedTheme.UserRole.company) return null;

    return FloatingActionButton(
      onPressed: () {
        context.push('/schedule/shift-management');
      },
      backgroundColor: _getPrimaryColor(),
      foregroundColor: _getOnPrimaryColor(),
      elevation: 6.0,
      focusElevation: 8.0,
      hoverElevation: 8.0,
      highlightElevation: 12.0,
      shape: const CircleBorder(),
      child: const Icon(Icons.add),
    );
  }

  // Event Handlers
  void _showMoreOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Instellingen'),
              onTap: () {
                context.pop();
                // Navigate to settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help'),
              onTap: () {
                context.pop();
                // Show help
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Feedback'),
              onTap: () {
                context.pop();
                // Show feedback form
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final scheduleBloc = context.read<ScheduleBloc>();
    scheduleBloc.add(ScheduleLoadShifts(
      guardId: widget.guardId,
      companyId: widget.companyId,
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 30)),
    ));
    
    // Wait a bit for the data to load
    await Future.delayed(const Duration(seconds: 1));
  }

  void _handleCheckIn(String notes) {
    if (widget.guardId == null) return;
    
    final scheduleBloc = context.read<ScheduleBloc>();
    final activeShift = _getActiveShift(scheduleBloc.state);
    
    if (activeShift != null) {
      scheduleBloc.add(ScheduleStartShift(
        shiftId: activeShift.id,
        guardId: widget.guardId!,
        companyId: activeShift.companyId,
        jobSiteId: activeShift.jobSiteId,
        jobLocation: activeShift.location,
        notes: notes,
      ));
    }
  }

  void _handleCheckOut(String notes) {
    if (widget.guardId == null) return;
    
    final scheduleBloc = context.read<ScheduleBloc>();
    final activeShift = _getActiveShift(scheduleBloc.state);
    
    if (activeShift != null) {
      scheduleBloc.add(ScheduleEndShift(
        guardId: widget.guardId!,
        jobLocation: activeShift.location,
        baseHourlyRate: activeShift.hourlyRate,
        notes: notes,
      ));
    }
  }

  void _handleStartBreak(BreakEntryType type, Duration duration) {
    final scheduleBloc = context.read<ScheduleBloc>();
    scheduleBloc.add(ScheduleStartBreak(
      breakType: type,
      plannedDuration: duration,
    ));
  }

  void _handleEndBreak() {
    final scheduleBloc = context.read<ScheduleBloc>();
    scheduleBloc.add(const ScheduleEndBreak());
  }

  void _handleShiftTap(Shift shift) {
    context.push('/schedule/shift-details/${shift.id}');
    // Original: Navigator.pushNamed(
    //   context,
    //   ScheduleRoutes.shiftDetails,
    //   arguments: {
    //     'shiftId': shift.id,
    //     'userRole': widget.userRole,
    //   },
    // );
  }

  void _handleEditShift(Shift shift) {
    context.push('/schedule/edit-shift/${shift.id}');
    // Original: Navigator.pushNamed(
    //   context,
    //   ScheduleRoutes.editShift,
    //   arguments: {
    //     'shiftId': shift.id,
    //     'userRole': widget.userRole,
    //   },
    // );
  }

  void _handleDateSelected(DateTime date) {
    // Handle calendar date selection
  }

  // Helper methods
  List<ScheduleTab> _getTabsForRole() {
    switch (widget.userRole) {
      case UnifiedTheme.UserRole.guard:
        return [
          ScheduleTab(
            type: ScheduleTabType.overview,
            label: 'Overzicht',
            icon: Icons.dashboard,
          ),
          ScheduleTab(
            type: ScheduleTabType.timeTracking,
            label: 'Tijd',
            icon: Icons.access_time,
          ),
          ScheduleTab(
            type: ScheduleTabType.calendar,
            label: 'Kalender',
            icon: Icons.calendar_month,
          ),
          ScheduleTab(
            type: ScheduleTabType.shifts,
            label: 'Diensten',
            icon: Icons.work,
          ),
        ];
      case UnifiedTheme.UserRole.company:
        return [
          ScheduleTab(
            type: ScheduleTabType.overview,
            label: 'Overzicht',
            icon: Icons.dashboard,
          ),
          ScheduleTab(
            type: ScheduleTabType.calendar,
            label: 'Kalender',
            icon: Icons.calendar_month,
          ),
          ScheduleTab(
            type: ScheduleTabType.shifts,
            label: 'Diensten',
            icon: Icons.work,
          ),
          ScheduleTab(
            type: ScheduleTabType.management,
            label: 'Beheer',
            icon: Icons.settings,
          ),
        ];
      case UnifiedTheme.UserRole.admin:
        return [
          ScheduleTab(
            type: ScheduleTabType.overview,
            label: 'Overzicht',
            icon: Icons.dashboard,
          ),
          ScheduleTab(
            type: ScheduleTabType.calendar,
            label: 'Kalender',
            icon: Icons.calendar_month,
          ),
          ScheduleTab(
            type: ScheduleTabType.shifts,
            label: 'Diensten',
            icon: Icons.work,
          ),
          ScheduleTab(
            type: ScheduleTabType.management,
            label: 'Beheer',
            icon: Icons.settings,
          ),
          ScheduleTab(
            type: ScheduleTabType.analytics,
            label: 'Analytics',
            icon: Icons.analytics,
          ),
        ];
    }
  }

  List<QuickAction> _getQuickActionsForRole() {
    final baseActions = <QuickAction>[
      QuickAction(
        label: 'Kalender',
        icon: Icons.calendar_month,
        color: DesignTokens.colorInfo,
        onTap: () => _tabController.animateTo(2),
      ),
    ];

    switch (widget.userRole) {
      case UnifiedTheme.UserRole.guard:
        return [
          ...baseActions,
          QuickAction(
            label: 'Tijd Registratie',
            icon: Icons.access_time,
            color: DesignTokens.colorSuccess,
            onTap: () => _tabController.animateTo(1),
          ),
          QuickAction(
            label: 'Verlof Aanvragen',
            icon: Icons.event_busy,
            color: DesignTokens.colorWarning,
            onTap: () {
              context.push('/schedule/calendar');
            },
          ),
          QuickAction(
            label: 'Dienst Ruilen',
            icon: Icons.swap_horiz,
            color: DesignTokens.colorSecondaryTeal,
            onTap: () {
              // Show shift swap dialog
            },
          ),
        ];
      case UnifiedTheme.UserRole.company:
        return [
          ...baseActions,
          QuickAction(
            label: 'Nieuwe Dienst',
            icon: Icons.add_circle,
            color: DesignTokens.colorSuccess,
            onTap: () {
              context.push('/schedule/shift-management'); // userRole: widget.userRole, companyId: widget.companyId
            },
          ),
          QuickAction(
            label: 'Personeel',
            icon: Icons.people,
            color: DesignTokens.colorWarning,
            onTap: () => _tabController.animateTo(3),
          ),
          QuickAction(
            label: 'Rapporten',
            icon: Icons.assessment,
            color: DesignTokens.colorInfo,
            onTap: () {
              // Navigate to reports
            },
          ),
        ];
      case UnifiedTheme.UserRole.admin:
        return [
          ...baseActions,
          QuickAction(
            label: 'Gebruikers',
            icon: Icons.admin_panel_settings,
            color: DesignTokens.colorWarning,
            onTap: () => _tabController.animateTo(3),
          ),
          QuickAction(
            label: 'Analytics',
            icon: Icons.analytics,
            color: DesignTokens.colorSuccess,
            onTap: () => _tabController.animateTo(4),
          ),
          QuickAction(
            label: 'Systeem',
            icon: Icons.settings_system_daydream,
            color: DesignTokens.colorError,
            onTap: () {
              // Navigate to system settings
            },
          ),
        ];
    }
  }

  String _getHeaderTitle() {
    switch (widget.userRole) {
      case UnifiedTheme.UserRole.guard:
        return 'Mijn Diensten';
      case UnifiedTheme.UserRole.company:
        return 'Dienstplanning';
      case UnifiedTheme.UserRole.admin:
        return 'Systeem Beheer';
    }
  }

  Color _getBackgroundColor() {
    switch (widget.userRole) {
      case UnifiedTheme.UserRole.guard:
        return DesignTokens.guardBackground;
      case UnifiedTheme.UserRole.company:
        return DesignTokens.companyBackground;
      case UnifiedTheme.UserRole.admin:
        return DesignTokens.adminBackground;
    }
  }

  Color _getPrimaryColor() {
    switch (widget.userRole) {
      case UnifiedTheme.UserRole.guard:
        return DesignTokens.guardPrimary;
      case UnifiedTheme.UserRole.company:
        return DesignTokens.companyPrimary;
      case UnifiedTheme.UserRole.admin:
        return DesignTokens.adminPrimary;
    }
  }

  Color _getOnPrimaryColor() {
    return DesignTokens.colorWhite;
  }

  Color _getTextPrimaryColor() {
    switch (widget.userRole) {
      case UnifiedTheme.UserRole.guard:
        return DesignTokens.guardTextPrimary;
      case UnifiedTheme.UserRole.company:
        return DesignTokens.companyTextPrimary;
      case UnifiedTheme.UserRole.admin:
        return DesignTokens.adminTextPrimary;
    }
  }

  Color _getTextSecondaryColor() {
    switch (widget.userRole) {
      case UnifiedTheme.UserRole.guard:
        return DesignTokens.guardTextSecondary;
      case UnifiedTheme.UserRole.company:
        return DesignTokens.companyTextSecondary;
      case UnifiedTheme.UserRole.admin:
        return DesignTokens.adminTextSecondary;
    }
  }

  Color _getStatusColor(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.draft:
        return DesignTokens.statusDraft;
      case ShiftStatus.published:
        return DesignTokens.statusPending;
      case ShiftStatus.confirmed:
        return DesignTokens.statusConfirmed;
      case ShiftStatus.inProgress:
        return DesignTokens.statusInProgress;
      case ShiftStatus.completed:
        return DesignTokens.statusCompleted;
      case ShiftStatus.cancelled:
        return DesignTokens.statusCancelled;
      default:
        return DesignTokens.colorGray500;
    }
  }

  String _getStatusText(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.draft:
        return 'Concept';
      case ShiftStatus.published:
        return 'Gepubliceerd';
      case ShiftStatus.confirmed:
        return 'Bevestigd';
      case ShiftStatus.inProgress:
        return 'Actief';
      case ShiftStatus.completed:
        return 'Voltooid';
      case ShiftStatus.cancelled:
        return 'Geannuleerd';
      default:
        return 'Onbekend';
    }
  }

  Shift? _getActiveShift(ScheduleState state) {
    if (state is! ScheduleLoaded) return null;
    
    try {
      return state.shifts.firstWhere(
        (shift) => shift.status == ShiftStatus.inProgress ||
                   (shift.assignedGuardId == widget.guardId &&
                    shift.status == ShiftStatus.confirmed &&
                    shift.startTime.isBefore(DateTime.now()) &&
                    shift.endTime.isAfter(DateTime.now())),
      );
    } catch (e) {
      return null;
    }
  }

  TimeEntry? _getCurrentTimeEntry(ScheduleState state) {
    if (state is! ScheduleLoaded) return null;
    return state.currentTimeEntry;
  }

  int _getWeeklyShiftCount(List<Shift> shifts) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    return shifts.where((shift) =>
        shift.startTime.isAfter(weekStart) &&
        shift.startTime.isBefore(weekEnd)).length;
  }

  int _getTodayShiftCount(List<Shift> shifts) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return shifts.where((shift) =>
        shift.startTime.isAfter(startOfDay) &&
        shift.startTime.isBefore(endOfDay)).length;
  }

  bool _canEditShift(Shift shift) {
    return widget.userRole == UnifiedTheme.UserRole.company ||
           widget.userRole == UnifiedTheme.UserRole.admin ||
           (widget.userRole == UnifiedTheme.UserRole.guard &&
            shift.assignedGuardId == widget.guardId &&
            shift.status == ShiftStatus.confirmed);
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      '', 'jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
      'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
    ];
    
    return '${dateTime.day} ${months[dateTime.month]} ${_formatTime(dateTime)}';
  }

  String _formatMonth(DateTime dateTime) {
    const months = [
      '', 'Januari', 'Februari', 'Maart', 'April', 'Mei', 'Juni',
      'Juli', 'Augustus', 'September', 'Oktober', 'November', 'December'
    ];
    
    return '${months[dateTime.month]} ${dateTime.year}';
  }
}

// Data models for tabs and actions
class ScheduleTab {
  final ScheduleTabType type;
  final String label;
  final IconData icon;

  const ScheduleTab({
    required this.type,
    required this.label,
    required this.icon,
  });
}

enum ScheduleTabType {
  overview,
  timeTracking,
  calendar,
  shifts,
  management,
  analytics,
}

class QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
