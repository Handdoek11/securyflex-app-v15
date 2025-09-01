import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_components/smart_tab_bar.dart';
import 'package:securyflex_app/unified_components/unified_background_service.dart';
import 'package:securyflex_app/services/notification_badge_service.dart';
import 'package:securyflex_app/unified_components/smart_badge_overlay.dart';
import 'package:securyflex_app/beveiliger_notificaties/services/guard_notification_service.dart';
import 'package:securyflex_app/beveiliger_notificaties/screens/notification_center_screen.dart';
import 'package:securyflex_app/beveiliger_notificaties/bloc/notification_center_bloc.dart';

import '../tabs/shifts_tab.dart';
import '../tabs/availability_tab.dart';
import '../tabs/timesheet_tab.dart';

/// Main Planning screen with TabBar navigation
/// Replaces complex planning_main_screen.dart with clean TabBar interface
/// Integrates ShiftsTab, AvailabilityTab, and TimesheetTab
/// Significantly reduces cognitive load with simplified navigation
/// Follows SecuryFlex unified design system and Dutch localization
class PlanningTabScreen extends StatefulWidget {
  const PlanningTabScreen({
    super.key,
    this.animationController,
    this.initialTabIndex = 0,
    this.selectedShiftId,
  });

  final AnimationController? animationController;
  final int initialTabIndex;
  final String? selectedShiftId; // For cross-tab navigation context

  @override
  State<PlanningTabScreen> createState() => _PlanningTabScreenState();
}

class _PlanningTabScreenState extends State<PlanningTabScreen>
    with TickerProviderStateMixin {
  // Animation and scroll controllers
  Animation<double>? topBarAnimation;
  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;
  late AnimationController _sharedAnimationController;

  // Tab management
  late TabController _tabController;
  late int _currentTabIndex;

  // Shared state for cross-tab navigation
// Shared shift status
  final NotificationBadgeService _badgeService =
      NotificationBadgeService.instance;
  final GuardNotificationService _notificationService = GuardNotificationService.instance;
  
  // Notification state
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();

    // Initialize shared animation controller
    _sharedAnimationController = widget.animationController ?? 
        AnimationController(
          duration: Duration(milliseconds: 600),
          vsync: this,
        );

    // Initialize tab controller
    _currentTabIndex = widget.initialTabIndex;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _currentTabIndex,
    );

    // Listen to tab changes
    _tabController.addListener(_handleTabChange);

    // Initialize animation
    topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sharedAnimationController,
        curve: const Interval(0, 0.5, curve: Curves.fastOutSlowIn),
      ),
    );

    // Start the animation if this is a newly created controller
    if (widget.animationController == null) {
      _sharedAnimationController.forward();
    }

    // Add scroll listener for header opacity animation
    scrollController.addListener(_handleScroll);

    // Initialize badge service
    _badgeService.initialize();

    // Simulate some initial badge data for demonstration
    _initializeDemoBadges();
    
    // Load notification count
    _loadUnreadNotificationCount();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    scrollController.dispose();
    
    // Only dispose if we created the controller
    if (widget.animationController == null) {
      _sharedAnimationController.dispose();
    }
    
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  // Performance optimization: Throttled scroll listener
  void _handleScroll() {
    final offset = scrollController.offset;
    double newOpacity;

    if (offset >= DesignTokens.spacingL) {
      newOpacity = 1.0;
    } else if (offset <= 0) {
      newOpacity = 0.0;
    } else {
      newOpacity = offset / DesignTokens.spacingL;
    }

    // Only setState if opacity actually changed (reduces rebuilds)
    if ((newOpacity - topBarOpacity).abs() > 0.01) {
      setState(() {
        topBarOpacity = newOpacity;
      });
    }
  }

  // Cross-tab navigation methods
  void _onShiftSelected(String shiftId) {
    // Could navigate to shift details screen here
  }

  void _onShiftStatusChanged(bool isOnShift) {
    setState(() {
    });
    // Update other tabs about shift status change
  }

  void _onAvailabilityChanged(Map<String, dynamic> availability) {
    // Handle availability updates that might affect shift scheduling
    // This could trigger notifications or updates to other systems
  }

  void _initializeDemoBadges() {
    // Simulate some initial badge data for demonstration
    Future.delayed(Duration(seconds: 3), () {
      _badgeService.updatePlanningBadges(
        upcomingShifts: 2,
        scheduleConflicts: 1,
        shiftChanges: 0,
      );

      _badgeService.updateTimesheetBadges(
        pendingApprovals: 1,
        missedClockOuts: 0,
      );
    });
  }

  /// Load unread notification count
  void _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Navigate to notification center
  void _navigateToNotificationCenter() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (context) => NotificationCenterBloc(),
        child: const Dialog(
          child: SizedBox(
            width: 400,
            height: 600,
            child: NotificationCenterScreen(),
          ),
        ),
      ),
    );
    
    // Refresh notification count after dialog closes
    _loadUnreadNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    // Unified background pattern matching Dashboard, Jobs, and Chat
    return SafeArea(
      child: UnifiedBackgroundService.guardMeshGradient(
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Column(
            children: [
              // Header
              UnifiedHeader.animated(
                title: 'Planning',
                animationController: _sharedAnimationController,
                scrollController: scrollController,
                enableScrollAnimation: true,
                userRole: UserRole.guard,
                titleAlignment: TextAlign.left,
                actions: [
                  SmartBadgeOverlay(
                    badgeCount: _unreadNotificationCount,
                    child: HeaderElements.actionButton(
                      icon: Icons.notifications_outlined,
                      onPressed: _navigateToNotificationCenter,
                      userRole: UserRole.guard,
                    ),
                  ),
                ],
              ),
              // Tab Bar
              _buildTabBar(),
              // Tab Content
              Expanded(child: _buildTabBarView()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    // SmartTabBar already handles its own background and border
    return SmartTabBar(
      controller: _tabController,
      userRole: UserRole.guard,
      tabs: SmartTabBarHelper.createPlanningTabs(),
      size: TabBarSize.compact,  // Smaller text size for consistency
      onTap: (index) {
        // Clear badges when user views the tab
        switch (index) {
          case 0: // Shifts tab
            SmartTabBarHelper.clearTabBadges('planning');
            break;
          case 2: // Timesheet tab
            SmartTabBarHelper.clearTabBadges('timesheet');
            break;
        }
      },
    );
  }



  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Shifts tab content
        ShiftsTab(
          animationController: _sharedAnimationController,
          onShiftSelected: _onShiftSelected,
        ),

        // Availability tab content
        AvailabilityTab(
          animationController: _sharedAnimationController,
          onAvailabilityChanged: _onAvailabilityChanged,
        ),

        // Timesheet tab content
        TimesheetTab(
          animationController: _sharedAnimationController,
          onShiftStatusChanged: _onShiftStatusChanged,
        ),
      ],
    );
  }
}
