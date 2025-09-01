import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/company_dashboard/localization/company_nl.dart';
import 'package:securyflex_app/company_dashboard/widgets/company_jobs_content.dart';
import 'package:securyflex_app/company_dashboard/widgets/company_applications_content.dart';
import 'package:securyflex_app/company_dashboard/widgets/recruitment_analytics_view.dart';
import 'package:securyflex_app/company_dashboard/services/job_posting_service.dart';
import 'package:securyflex_app/company_dashboard/services/application_review_service.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:flutter/material.dart';

/// Combined Jobs and Applications screen with TabBar integration
/// Eliminates context loss between jobs and applications management
/// Following Dutch localization and unified design system standards
class CompanyJobsApplicationsTabScreen extends StatefulWidget {
  const CompanyJobsApplicationsTabScreen({
    super.key, 
    this.animationController,
    this.initialTabIndex = 0,
    this.selectedJobId,
  });

  final AnimationController? animationController;
  final int initialTabIndex;
  final String? selectedJobId; // For cross-tab navigation context

  @override
  State<CompanyJobsApplicationsTabScreen> createState() => _CompanyJobsApplicationsTabScreenState();
}

class _CompanyJobsApplicationsTabScreenState extends State<CompanyJobsApplicationsTabScreen>
    with TickerProviderStateMixin {
  
  // Animation and scroll controllers
  Animation<double>? topBarAnimation;
  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;
  
  // Tab management
  late TabController _tabController;
  late int _currentTabIndex;
  
  // Shared state for cross-tab navigation
  String? _selectedJobId;
  String? _applicationFilter;

  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller
    _currentTabIndex = widget.initialTabIndex;
    _selectedJobId = widget.selectedJobId;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _currentTabIndex,
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

    // Initialize mock data
    JobPostingService.initializeMockData();
    ApplicationReviewService.instance.initializeMockData('company_demo');
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  void _handleScroll() {
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

  /// Navigate to specific tab with context
  void _navigateToTab(int tabIndex, {String? jobId, String? filter}) {
    setState(() {
      _selectedJobId = jobId;
      _applicationFilter = filter;
    });
    
    _tabController.animateTo(tabIndex);
  }

  /// Handle cross-tab navigation from jobs to applications
  void _onViewApplications(String jobId) {
    _navigateToTab(1, jobId: jobId, filter: 'job:$jobId');
  }

  /// Handle navigation from applications back to jobs
  void _onViewJob(String jobId) {
    _navigateToTab(0, jobId: jobId);
  }

  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Scaffold(
      backgroundColor: companyColors.surfaceContainerHighest,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 46), // Optimized height to prevent overflow
        child: _buildStandardAppBarWithTabs(),
      ),
      body: _buildTabBarView(),
    );
  }

  Widget _buildStandardAppBarWithTabs() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return UnifiedHeader.companyGradient(
      title: 'Opdrachten & Sollicitaties',
      showNotifications: true,
      onNotificationPressed: () => _navigateToNotifications(),
      tabBar: Material(
        color: companyColors.surface,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: companyColors.surface,
            border: Border(
              bottom: BorderSide(
                color: companyColors.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: companyColors.primary,
            unselectedLabelColor: companyColors.onSurfaceVariant,
            indicatorColor: companyColors.primary,
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
            ),
            unselectedLabelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: DesignTokens.fontWeightMedium,
              fontFamily: DesignTokens.fontFamily,
            ),
            tabs: [
              Tab(text: CompanyNL.jobManagement),
              Tab(text: CompanyNL.applicationsManagement),
              Tab(text: CompanyNL.analytics),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Jobs tab content
        CompanyJobsContent(
          animationController: widget.animationController,
          scrollController: scrollController,
          selectedJobId: _selectedJobId,
          onViewApplications: _onViewApplications,
        ),

        // Applications tab content
        CompanyApplicationsContent(
          animationController: widget.animationController,
          scrollController: scrollController,
          selectedJobId: _selectedJobId,
          applicationFilter: _applicationFilter,
          onViewJob: _onViewJob,
        ),

        // Analytics tab content
        _buildAnalyticsTabContent(),
      ],
    );
  }

  /// Build Analytics tab content
  Widget _buildAnalyticsTabContent() {
    return RecruitmentAnalyticsView(
      companyId: _getCurrentCompanyId(),
      animationController: widget.animationController,
      scrollController: scrollController,
    );
  }

  /// Get current company ID from authenticated user
  String _getCurrentCompanyId() {
    // In demo mode, use a default company ID
    // In production, this would get the company ID from the authenticated user
    if (AuthService.isLoggedIn && AuthService.currentUserType == 'company') {
      // For demo purposes, use a consistent company ID
      // In production, this would be stored in user profile
      return 'COMP001';
    }
    return 'COMP001'; // Fallback
  }

  /// Navigate to notifications screen
  void _navigateToNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificaties - Binnenkort beschikbaar'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
