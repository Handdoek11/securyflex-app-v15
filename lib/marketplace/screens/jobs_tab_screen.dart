import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_components/smart_tab_bar.dart';
import 'package:securyflex_app/services/notification_badge_service.dart';
// BeveiligerDashboardTheme import removed - using unified design tokens
import 'package:securyflex_app/marketplace/tabs/job_discovery_tab.dart';
import 'package:securyflex_app/marketplace/tabs/applications_tab.dart';
import 'package:securyflex_app/marketplace/tabs/active_jobs_tab.dart';
import 'package:securyflex_app/marketplace/tabs/job_history_tab.dart';
import 'package:securyflex_app/marketplace/services/favorites_service.dart';
import 'package:securyflex_app/marketplace/screens/favorites_screen.dart';
import 'package:securyflex_app/unified_components/smart_badge_overlay.dart';
import 'package:securyflex_app/beveiliger_notificaties/services/guard_notification_service.dart';
import 'package:securyflex_app/beveiliger_notificaties/screens/notification_center_screen.dart';
import 'package:securyflex_app/beveiliger_notificaties/bloc/notification_center_bloc.dart';
import 'package:securyflex_app/unified_components/unified_background_service.dart';

/// Main Jobs screen with TabBar navigation
/// Integrates JobDiscoveryTab, ApplicationsTab, and JobHistoryTab
/// Follows SecuryFlex unified design system and Dutch localization
/// Provides cross-tab navigation and context sharing
class JobsTabScreen extends StatefulWidget {
  const JobsTabScreen({
    super.key,
    this.animationController,
    this.initialTabIndex = 0,
    this.selectedJobId,
  });

  final AnimationController? animationController;
  final int initialTabIndex;
  final String? selectedJobId; // For cross-tab navigation context

  @override
  State<JobsTabScreen> createState() => _JobsTabScreenState();
}

class _JobsTabScreenState extends State<JobsTabScreen>
    with TickerProviderStateMixin {
  // Animation and scroll controllers
  Animation<double>? topBarAnimation;
  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;

  // Tab management
  late TabController _tabController;
  late int _currentTabIndex;
  late AnimationController _localAnimationController;

  // Shared state for cross-tab navigation
  final FavoritesService _favoritesService = FavoritesService();
  final NotificationBadgeService _badgeService =
      NotificationBadgeService.instance;
  final GuardNotificationService _notificationService = GuardNotificationService.instance;
  
  // Notification state
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();

    // Initialize tab controller
    _currentTabIndex = widget.initialTabIndex;
    _tabController = TabController(
      length: 4,  // Updated for 4 tabs (Beschikbaar, Sollicitaties, Actief, Geschiedenis)
      vsync: this,
      initialIndex: _currentTabIndex,
    );

    // Initialize local animation controller if widget's is null
    _localAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Listen to tab changes
    _tabController.addListener(_handleTabChange);

    // Initialize animation
    if (widget.animationController != null) {
      topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: widget.animationController!,
          curve: const Interval(0, 0.5, curve: Curves.fastOutSlowIn),
        ),
      );
    }

    // Add scroll listener for header opacity animation
    scrollController.addListener(_handleScroll);

    // Initialize favorites service
    _favoritesService.initialize();

    // Initialize badge service
    _badgeService.initialize();

    // Simulate some initial badge data for demonstration
    _initializeDemoBadges();
    _loadUnreadNotificationCount();
  }

  @override
  void dispose() {
    // Stop listening to tab changes first
    _tabController.removeListener(_handleTabChange);
    
    // Services are singletons - no disposal needed
    
    // Dispose controllers
    _tabController.dispose();
    _localAnimationController.dispose();
    scrollController.dispose();
    
    super.dispose();
  }

  void _handleTabChange() {
    if (!mounted) return;
    
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  void _handleScroll() {
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
  }

  // Cross-tab navigation methods
  void _onJobSelected(String jobId) {
    if (jobId.isEmpty) {
      // Switch to Jobs Discovery tab
      _tabController.animateTo(0);
    } else {
      // Could navigate to job details screen here
    }
  }

  void _initializeDemoBadges() {
    // Simulate some initial badge data for demonstration
    Future.delayed(Duration(seconds: 2), () {
      _badgeService.updateJobBadges(
        newApplications: 3,
        applicationUpdates: 1,
        newJobs: 5,
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
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
          create: (context) => NotificationCenterBloc(),
          child: const NotificationCenterScreen(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.fastOutSlowIn;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    
    // Refresh notification count when returning
    if (result != null) {
      _loadUnreadNotificationCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    SecuryFlexTheme.getColorScheme(UserRole.guard);

    return SafeArea(
      child: UnifiedBackgroundService.guardMeshGradient(
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              // ✅ FIXED: Updated to use proper animationController parameter
              widget.animationController != null
                  ? UnifiedHeader.animated(
                      title: 'Jobs',
                      animationController: widget.animationController ?? _localAnimationController,
                      scrollController: scrollController,
                      enableScrollAnimation: true,
                      userRole: UserRole.guard,
                      titleAlignment: TextAlign.left,
                      actions: [
                  // Favorites button
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: _favoritesService.favoriteJobIds,
                    builder: (context, favoriteIds, child) {
                      return HeaderElements.actionButton(
                        icon: favoriteIds.isEmpty
                            ? Icons.favorite_border
                            : Icons.favorite,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FavoritesScreen(),
                            ),
                          );
                        },
                        userRole: UserRole.guard,
                      );
                    },
                  ),
                  // Notification bell with badge
                  SmartBadgeOverlay(
                    badgeCount: _unreadNotificationCount,
                    child: HeaderElements.actionButton(
                      icon: Icons.notifications_outlined,
                      onPressed: _navigateToNotificationCenter,
                      userRole: UserRole.guard,
                    ),
                  ),
                ],
              )
                  : UnifiedHeader(
                      title: 'Jobs',
                      userRole: UserRole.guard,
                      titleAlignment: TextAlign.left,
                      actions: [
                  // Favorites button
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: _favoritesService.favoriteJobIds,
                    builder: (context, favoriteIds, child) {
                      return HeaderElements.actionButton(
                        icon: favoriteIds.isEmpty
                            ? Icons.favorite_border
                            : Icons.favorite,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FavoritesScreen(),
                            ),
                          );
                        },
                        userRole: UserRole.guard,
                      );
                    },
                  ),
                  // Notification bell with badge
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
              _buildTabBar(),
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
      tabs: SmartTabBarHelper.createJobsTabs(),
      size: TabBarSize.compact,  // Smaller text size for consistency
      onTap: (index) {
        // Clear badges when user views the tab
        if (index == 1) {
          // Applications tab - clear application-related badges
          SmartTabBarHelper.clearTabBadges('jobs');
        }
      },
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Jobs Discovery tab content
        JobDiscoveryTab(
          animationController: widget.animationController ?? _localAnimationController
        ),

        // Applications tab content
        ApplicationsTab(
          animationController: widget.animationController ?? _localAnimationController,
          onJobSelected: _onJobSelected,
        ),

        // Active Jobs tab content
        ActiveJobsTab(
          animationController: widget.animationController ?? _localAnimationController,
        ),

        // Job History tab content
        JobHistoryTab(
          animationController: widget.animationController ?? _localAnimationController,
          onJobSelected: _onJobSelected,
        ),
      ],
    );
  }
}
