import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_header.dart';
import '../../unified_card_system.dart';
import '../../unified_components/modern_applications_overview_widget.dart';
import '../utils/company_responsive_breakpoints.dart' hide DeviceType;
import '../../core/responsive/responsive_provider.dart';
import '../../core/responsive/responsive_extensions.dart';
import '../widgets/active_jobs_overview.dart';
import '../widgets/revenue_metrics_view.dart';
import '../../routing/app_routes.dart';
import '../widgets/enhanced_desktop_sidebar.dart';
import '../widgets/live_dashboard_stats.dart';
import '../widgets/drag_drop_job_scheduler.dart';
import '../widgets/advanced_filter_panel.dart';
import '../widgets/dashboard_overview_content.dart';
import '../widgets/jobs_management_content.dart';
import '../widgets/applications_review_content.dart';
import '../widgets/team_management_content.dart';
import '../widgets/messages_content.dart';
import '../widgets/finance_content.dart';
import '../widgets/desktop_action_toolbar.dart';
import '../widgets/analytics_content.dart';
import '../widgets/omzet_content.dart';
import '../widgets/performance_content.dart';
import '../widgets/rapporten_content.dart';
import '../services/job_posting_service.dart';
import '../services/application_review_service.dart';
import 'job_posting_form_screen.dart';
import '../bloc/bloc.dart';

/// Responsive Company Dashboard Wrapper with BLoC Provider
class ResponsiveCompanyDashboard extends StatelessWidget {
  final AnimationController? animationController;

  const ResponsiveCompanyDashboard({
    super.key,
    this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CompanyDashboardBloc(),
      child: _ResponsiveCompanyDashboardContent(
        animationController: animationController,
      ),
    );
  }
}

/// Responsive Company Dashboard Content
/// Combines beveiliger responsive patterns with business desktop features
class _ResponsiveCompanyDashboardContent extends StatefulWidget {
  final AnimationController? animationController;

  const _ResponsiveCompanyDashboardContent({
    super.key,
    this.animationController,
  });

  @override
  State<_ResponsiveCompanyDashboardContent> createState() => _ResponsiveCompanyDashboardState();
}

class _ResponsiveCompanyDashboardState extends State<_ResponsiveCompanyDashboardContent>
    with TickerProviderStateMixin {
  
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  
  // Controllers that remain local to widget
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  
  // Local state for keyboard shortcuts (hardware specific)
  bool _keyboardShortcutsInitialized = false;
  
  // Bulk operations local state (can be migrated later)
  final List<String> _bulkSelectedJobs = [];
  final List<String> _bulkSelectedApplications = [];

  @override
  void initState() {
    super.initState();
    _animationController = widget.animationController ?? AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
    
    // Initialize dashboard via BLoC
    context.read<CompanyDashboardBloc>().add(const DashboardInitialized());
    
    // Don't check for keyboard shortcuts in initState - will do in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Now it's safe to check MediaQuery
    // Only initialize once to avoid multiple handlers
    if (!_keyboardShortcutsInitialized && 
        CompanyResponsiveBreakpoints.supportsKeyboardShortcuts(context)) {
      _setupKeyboardShortcuts();
      _keyboardShortcutsInitialized = true;
      
      // Notify BLoC that keyboard shortcuts are initialized
      context.read<CompanyDashboardBloc>().add(const KeyboardShortcutsInitialized());
    }
  }

  void _setupKeyboardShortcuts() {
    // Keyboard shortcuts for desktop users
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final dashboardBloc = context.read<CompanyDashboardBloc>();
      final dashboardState = dashboardBloc.state;
      
      // Ctrl/Cmd + N: New job
      if (HardwareKeyboard.instance.isControlPressed && 
          event.logicalKey == LogicalKeyboardKey.keyN) {
        _navigateToJobPosting();
        return true;
      }
      // Ctrl/Cmd + A: Select all (in multi-select mode)
      if (HardwareKeyboard.instance.isControlPressed && 
          event.logicalKey == LogicalKeyboardKey.keyA) {
        if (dashboardState.isMultiSelectMode) {
          dashboardBloc.selectAll();
          return true;
        }
      }
      // Ctrl/Cmd + K: Focus search
      if (HardwareKeyboard.instance.isControlPressed && 
          event.logicalKey == LogicalKeyboardKey.keyK) {
        _focusSearch();
        return true;
      }
      // F5: Refresh
      if (event.logicalKey == LogicalKeyboardKey.f5) {
        dashboardBloc.refresh();
        return true;
      }
      // Escape: Cancel multi-select or close filter panel
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (dashboardState.isMultiSelectMode) {
          dashboardBloc.add(const MultiSelectToggled(false));
          return true;
        }
        if (dashboardState.isFilterPanelOpen) {
          dashboardBloc.add(const FilterPanelToggled(false));
          return true;
        }
      }
    }
    return false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    if (widget.animationController == null) {
      _animationController.dispose();
    }
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = context.deviceType;
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return BlocBuilder<CompanyDashboardBloc, DashboardState>(
      builder: (context, dashboardState) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: colorScheme.surface,
          body: _buildResponsiveLayout(deviceType, dashboardState),
          // Only show FAB on mobile
          floatingActionButton: deviceType == DeviceType.mobile ? _buildMobileFAB() : null,
          // Add drawer for mobile navigation enhancement
          drawer: deviceType == DeviceType.mobile ? _buildMobileDrawer() : null,
        );
      },
    );
  }

  Widget _buildResponsiveLayout(DeviceType deviceType, DashboardState dashboardState) {
    // Show loading state
    if (dashboardState.isLoading) {
      return _buildLoadingState();
    }
    
    // Show error state
    if (dashboardState.hasError) {
      return _buildErrorState(dashboardState.errorMessage ?? 'Onbekende fout');
    }
    
    switch (deviceType) {
      case DeviceType.mobile:
        return _buildMobileLayout(dashboardState);
      case DeviceType.tablet:
        return _buildTabletLayout(dashboardState);
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return _buildDesktopLayout(deviceType, dashboardState);
    }
  }

  // ============================================================================
  // LOADING AND ERROR STATES
  // ============================================================================
  
  Widget _buildLoadingState() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'Dashboard laden...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(String errorMessage) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: DesignTokens.colorError,
            ),
            SizedBox(height: DesignTokens.spacingL),
            Text(
              'Er is een fout opgetreden',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: DesignTokens.fontSizeBody,
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            ElevatedButton.icon(
              onPressed: () {
                context.read<CompanyDashboardBloc>().refresh();
              },
              icon: Icon(Icons.refresh),
              label: Text('Opnieuw proberen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // MOBILE LAYOUT (Original pattern from beveiliger)
  // ============================================================================
  Widget _buildMobileLayout(DashboardState dashboardState) {
    return SafeArea(
      child: Column(
        children: [
          UnifiedHeader.companyGradient(
            title: 'Dashboard',
            showNotifications: true,
            onNotificationPressed: () {},
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: CompanyResponsiveBreakpoints.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  SizedBox(height: DesignTokens.spacingL),
                  _buildMetricsGrid(columns: 2),
                  SizedBox(height: DesignTokens.spacingL),
                  _buildRevenueCard(),
                  SizedBox(height: DesignTokens.spacingL),
                  _buildActiveJobsList(),
                  SizedBox(height: DesignTokens.spacingL),
                  _buildApplicationsOverview(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TABLET LAYOUT (Navigation rail + content)
  // ============================================================================
  Widget _buildTabletLayout(DashboardState dashboardState) {
    return SafeArea(
      child: Row(
        children: [
          // Collapsible navigation rail
          NavigationRail(
            selectedIndex: dashboardState.selectedNavigationIndex,
            onDestinationSelected: (index) {
              context.read<CompanyDashboardBloc>().add(NavigationChanged(index));
            },
            labelType: NavigationRailLabelType.selected,
            backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.company).surfaceContainer,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.work_outline),
                selectedIcon: Icon(Icons.work),
                label: Text('Jobs'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Sollicitaties'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: Text('Team'),
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: CompanyResponsiveBreakpoints.getResponsivePadding(context),
                    child: Column(
                      children: [
                        _buildMetricsGrid(columns: 3),
                        SizedBox(height: DesignTokens.spacingL),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildActiveJobsList()),
                            SizedBox(width: DesignTokens.spacingL),
                            Expanded(child: _buildApplicationsOverview()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT (Full sidebar + rich content + action toolbar)
  // ============================================================================
  Widget _buildDesktopLayout(DeviceType deviceType, DashboardState dashboardState) {
    final useDataTables = CompanyResponsiveBreakpoints.useDataTables(context);
    final columns = deviceType == DeviceType.largeDesktop ? 6 : 4;
    
    return SafeArea(
      child: Row(
        children: [
          // Full sidebar navigation
          _buildDesktopSidebar(dashboardState),
          // Main content area
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(),
                _buildDesktopActionToolbar(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: CompanyResponsiveBreakpoints.getResponsivePadding(context),
                    child: Column(
                      children: [
                        // Metrics in grid layout
                        _buildMetricsGrid(columns: columns),
                        SizedBox(height: DesignTokens.spacingXL),
                        
                        // Advanced filter panel with presets
                        if (dashboardState.isFilterPanelOpen)
                          AdvancedFilterPanel(
                            onFiltersChanged: (filters) {
                              // Handle filter changes
                              // TODO: Apply filters to data
                            },
                            onExport: () {
                              // Handle export
                              _handleDataExport();
                            },
                          ),
                        
                        // Main content area with sidebar
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main content (70%)
                            Expanded(
                              flex: 7,
                              child: _buildMainContent(useDataTables, dashboardState),
                            ),
                            SizedBox(width: DesignTokens.spacingL),
                            // Right sidebar (30%)
                            Expanded(
                              flex: 3,
                              child: _buildDesktopRightSidebar(dashboardState),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MAIN CONTENT SWITCHING
  // ============================================================================
  
  Widget _buildMainContent(bool useDataTables, DashboardState dashboardState) {
    if (kDebugMode) {
      debugPrint('🔄 Building main content for index: ${dashboardState.selectedNavigationIndex} (${dashboardState.currentView})');
    }
    
    final deviceType = context.deviceType;
    final columns = deviceType == DeviceType.largeDesktop ? 6 : 4;
    
    switch (dashboardState.selectedNavigationIndex) {
      case 0: // Dashboard
        return DashboardOverviewContent(
          useDataTables: useDataTables,
          dashboardState: dashboardState,
          columns: columns,
        );
      case 1: // Opdrachten/Jobs
        return JobsManagementContent(
          useDataTables: useDataTables,
          dashboardState: dashboardState,
          onNewJobPressed: _navigateToJobPosting,
        );
      case 2: // Sollicitaties/Applications
        return ApplicationsReviewContent(
          useDataTables: useDataTables,
          dashboardState: dashboardState,
        );
      case 3: // Team
        return const TeamManagementContent();
      case 4: // Berichten/Messages
        return const MessagesContent();
      case 5: // Financiën/Finance
        return const FinanceContent();
      case 6: // Omzet (Revenue)
        return OmzetContent(
          dashboardState: dashboardState,
        );
      case 7: // Performance
        return PerformanceContent(
          dashboardState: dashboardState,
        );
      case 8: // Rapporten (Reports)
        return RapportenContent(
          dashboardState: dashboardState,
        );
      default:
        // For any Analytics-related navigation, show the general Analytics page
        if (dashboardState.selectedNavigationIndex >= 6 && dashboardState.selectedNavigationIndex <= 8) {
          return AnalyticsContent(
            dashboardState: dashboardState,
          );
        }
        return DashboardOverviewContent(
          useDataTables: useDataTables,
          dashboardState: dashboardState,
          columns: columns,
        );
    }
  }
  
  Widget _buildDashboardContent(bool useDataTables, DashboardState dashboardState) {
    return Column(
      children: [
        _buildRevenueCard(isDesktop: true),
        SizedBox(height: DesignTokens.spacingL),
        useDataTables 
          ? _buildJobsDataTable(dashboardState)
          : _buildActiveJobsList(isDesktop: true),
        SizedBox(height: DesignTokens.spacingL),
        useDataTables
          ? _buildApplicationsDataTable(dashboardState)
          : _buildApplicationsOverview(isDesktop: true),
      ],
    );
  }
  
  Widget _buildJobsContent(bool useDataTables, DashboardState dashboardState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Jobs header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Opdrachten Beheer',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _navigateToJobPosting,
              icon: Icon(Icons.add),
              label: Text('Nieuwe Opdracht'),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingL),
        // Show drag-drop scheduler or data table with constrained height
        SizedBox(
          height: 800, // Fixed height to prevent unbounded constraints
          child: DragDropJobScheduler(),
        ),
      ],
    );
  }
  
  Widget _buildApplicationsContent(bool useDataTables, DashboardState dashboardState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sollicitaties Overzicht',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightBold,
          ),
        ),
        SizedBox(height: DesignTokens.spacingL),
        SizedBox(
          height: 600, // Fixed height for applications content
          child: useDataTables
            ? _buildApplicationsDataTable(dashboardState)
            : _buildApplicationsOverview(isDesktop: true),
        ),
      ],
    );
  }
  
  Widget _buildTeamContent() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Team Beheer',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightBold,
          ),
        ),
        SizedBox(height: DesignTokens.spacingL),
        SizedBox(
          height: 500, // Fixed height for team content
          child: UnifiedCard.standard(
            userRole: UserRole.company,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups, size: 64, color: colorScheme.primary),
                  SizedBox(height: DesignTokens.spacingL),
                  Text(
                    'Team Beheer',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeSubtitle,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  Text(
                    'Hier kun je je beveiligingsteam beheren,\nprestaties monitoren en schema\'s plannen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMessagesContent() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Berichten & Communicatie',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightBold,
          ),
        ),
        SizedBox(height: DesignTokens.spacingL),
        SizedBox(
          height: 500, // Fixed height for messages content
          child: UnifiedCard.standard(
            userRole: UserRole.company,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble, size: 64, color: colorScheme.primary),
                  SizedBox(height: DesignTokens.spacingL),
                  Text(
                    'Berichten',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeSubtitle,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  Text(
                    'Communiceer direct met je beveiligingsteam,\nontvang updates en deel belangrijke informatie.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFinanceContent() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Financiën & Facturatie',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightBold,
          ),
        ),
        SizedBox(height: DesignTokens.spacingL),
        // Revenue card for finance view
        _buildRevenueCard(isDesktop: true),
        SizedBox(height: DesignTokens.spacingL),
        SizedBox(
          height: 400, // Fixed height for finance content
          child: UnifiedCard.standard(
            userRole: UserRole.company,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 64, color: colorScheme.primary),
                  SizedBox(height: DesignTokens.spacingL),
                  Text(
                    'Financieel Overzicht',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeSubtitle,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  Text(
                    'Bekijk je omzet, beheer facturen\nen krijg inzicht in je financiële prestaties.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // DESKTOP-SPECIFIC COMPONENTS
  // ============================================================================
  
  Widget _buildDesktopSidebar(DashboardState dashboardState) {
    // Use the new enhanced collapsible sidebar
    return EnhancedDesktopSidebar(
      selectedIndex: dashboardState.selectedNavigationIndex,
      onItemSelected: (index) {
        // Update navigation via BLoC
        context.read<CompanyDashboardBloc>().add(NavigationChanged(index));
        
        // Show feedback for navigation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigatie naar ${dashboardState.currentNavigationLabel}'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      onNewJob: _navigateToJobPosting,
      onEmergency: _handleEmergencyAction,
    );
  }
  
  Widget _buildDesktopSidebarOld() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Company logo/brand
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingL),
            child: Row(
              children: [
                Icon(
                  Icons.business,
                  color: colorScheme.primary,
                  size: 32,
                ),
                SizedBox(width: DesignTokens.spacingM),
                Text(
                  'SecuryFlex',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
              children: [
                _buildSidebarItem(Icons.dashboard, 'Dashboard', true),
                _buildSidebarItem(Icons.work, 'Opdrachten', false),
                _buildSidebarItem(Icons.people, 'Sollicitaties', false, badge: '12'),
                _buildSidebarItem(Icons.groups, 'Team', false),
                _buildSidebarItem(Icons.analytics, 'Analytics', false),
                _buildSidebarItem(Icons.payment, 'Financiën', false),
                Divider(),
                _buildSidebarItem(Icons.settings, 'Instellingen', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, bool isActive, {String? badge}) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: isActive ? DesignTokens.fontWeightSemiBold : DesignTokens.fontWeightRegular,
        ),
      ),
      trailing: badge != null ? Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          badge,
          style: TextStyle(
            color: colorScheme.onError,
            fontSize: DesignTokens.fontSizeCaption,
          ),
        ),
      ) : null,
      selected: isActive,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      onTap: () {
        // Handle sidebar navigation for old sidebar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigeren naar $label'),
            duration: Duration(seconds: 1),
          ),
        );
      },
    );
  }

  Widget _buildDesktopActionToolbar() {
    return DesktopActionToolbar(
      onNewJobPressed: _navigateToJobPosting,
      onBulkImportPressed: () {
        // Handle bulk import
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk import functionaliteit komt binnenkort'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      onExportSelected: _handleExport,
      onEmergencyPressed: _handleEmergencyAction,
    );
  }

  Widget _buildActionToolbarContent(DashboardState dashboardState) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Primary actions
          ElevatedButton.icon(
            onPressed: _navigateToJobPosting,
            icon: Icon(Icons.add),
            label: Text('Nieuwe Job'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.upload_file),
            label: Text('Bulk Import'),
          ),
          SizedBox(width: DesignTokens.spacingM),
          if (dashboardState.isMultiSelectMode) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
                vertical: DesignTokens.spacingS,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checklist, 
                    color: colorScheme.onPrimaryContainer,
                    size: 18,
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    '${dashboardState.selectedItems.length} geselecteerd',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  InkWell(
                    onTap: () {
                      context.read<CompanyDashboardBloc>().add(const MultiSelectToggled(false));
                      context.read<CompanyDashboardBloc>().add(const ItemSelectionChanged(<String>{}));
                    },
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    child: Padding(
                      padding: EdgeInsets.all(DesignTokens.spacingXS),
                      child: Icon(
                        Icons.close,
                        color: colorScheme.onPrimaryContainer,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            // Bulk actions when items are selected
            if (dashboardState.selectedItems.isNotEmpty) ...[
              OutlinedButton.icon(
                onPressed: () => _showBulkActionsMenu(dashboardState),
                icon: Icon(Icons.more_horiz),
                label: Text('Bulk acties'),
              ),
              SizedBox(width: DesignTokens.spacingM),
            ],
          ],
          Spacer(),
          // Secondary actions with enhanced functionality
          if (dashboardState.isRefreshing)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => context.read<CompanyDashboardBloc>().add(const DashboardRefreshed()),
              tooltip: 'Vernieuwen (F5)',
            ),
          IconButton(
            icon: Icon(
              dashboardState.isFilterPanelOpen ? Icons.filter_list : Icons.filter_list_outlined,
              color: dashboardState.isFilterPanelOpen ? colorScheme.primary : null,
            ),
            onPressed: () => context.read<CompanyDashboardBloc>().add(FilterPanelToggled(!dashboardState.isFilterPanelOpen)),
            tooltip: 'Filters',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.download),
            tooltip: 'Exporteren',
            onSelected: _handleExport,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 18),
                    SizedBox(width: DesignTokens.spacingS),
                    Text('Export naar CSV'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.description, size: 18),
                    SizedBox(width: DesignTokens.spacingS),
                    Text('Export naar Excel'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 18),
                    SizedBox(width: DesignTokens.spacingS),
                    Text('Export naar PDF'),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: DesignTokens.spacingM),
          // Emergency action
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: DesignTokens.colorError),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.emergency, color: DesignTokens.colorError),
              label: Text('Noodgeval', style: TextStyle(color: DesignTokens.colorError)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRightSidebar(DashboardState dashboardState) {
    // Use the new live dashboard stats widget for real-time updates
    if (dashboardState.showLiveDashboard) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: LiveDashboardStats(),
      );
    }
    
    // Fallback to static stats (can be removed once live dashboard is fully integrated)
    return Column(
      children: [
        // Quick stats
        UnifiedCard.standard(
          userRole: UserRole.company,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vandaag',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeSubtitle,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
              SizedBox(height: DesignTokens.spacingM),
              _buildQuickStat('Nieuwe sollicitaties', '8'),
              _buildQuickStat('Actieve guards', '24'),
              _buildQuickStat('Openstaande shifts', '3'),
              _buildQuickStat('Response rate', '94%'),
            ],
          ),
        ),
        SizedBox(height: DesignTokens.spacingL),
        // Recent activity
        UnifiedCard.standard(
          userRole: UserRole.company,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recente Activiteit',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeSubtitle,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
              SizedBox(height: DesignTokens.spacingM),
              _buildActivityItem('Jan de Vries solliciteerde', '5 min'),
              _buildActivityItem('Shift #2451 geaccepteerd', '12 min'),
              _buildActivityItem('Nieuwe beoordeling ontvangen', '1 uur'),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // DATA TABLES FOR LARGE SCREENS
  // ============================================================================
  
  Widget _buildJobsDataTable(DashboardState dashboardState) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actieve Opdrachten',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeSubtitle,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  context.read<CompanyDashboardBloc>().add(MultiSelectToggled(!dashboardState.isMultiSelectMode));
                },
                icon: Icon(Icons.checklist),
                label: Text('Bulk selectie'),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingM),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: dashboardState.isMultiSelectMode,
              columns: const [
                DataColumn(label: Text('Job ID')),
                DataColumn(label: Text('Titel')),
                DataColumn(label: Text('Locatie')),
                DataColumn(label: Text('Datum')),
                DataColumn(label: Text('Guards')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Acties')),
              ],
              rows: List.generate(5, (index) => DataRow(
                selected: dashboardState.selectedItems.contains('job_$index'),
                onSelectChanged: dashboardState.isMultiSelectMode ? (selected) {
                  final newSelectedItems = Set<String>.from(dashboardState.selectedItems);
                  if (selected ?? false) {
                    newSelectedItems.add('job_$index');
                  } else {
                    newSelectedItems.remove('job_$index');
                  }
                  context.read<CompanyDashboardBloc>().add(ItemSelectionChanged(newSelectedItems));
                } : null,
                cells: [
                  DataCell(Text('#${2451 + index}')),
                  DataCell(Text('Beveiliging Centrum')),
                  DataCell(Text('Amsterdam')),
                  DataCell(Text('28 Jan')),
                  DataCell(Text('3/5')),
                  DataCell(Chip(
                    label: Text('Actief'),
                    backgroundColor: DesignTokens.statusConfirmed.withValues(alpha: 0.2),
                  )),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, size: 18),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.more_vert, size: 18),
                        onPressed: () {},
                      ),
                    ],
                  )),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsDataTable(DashboardState dashboardState) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recente Sollicitaties',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSubtitle,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Naam')),
                DataColumn(label: Text('Job')),
                DataColumn(label: Text('Ervaring')),
                DataColumn(label: Text('Certificaten')),
                DataColumn(label: Text('Score')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Acties')),
              ],
              rows: List.generate(3, (index) => DataRow(
                cells: [
                  DataCell(Text('Jan de Vries')),
                  DataCell(Text('Centrum Beveiliging')),
                  DataCell(Text('5 jaar')),
                  DataCell(Text('WPBR, BHV')),
                  DataCell(Row(
                    children: List.generate(5, (i) => Icon(
                      Icons.star,
                      size: 14,
                      color: i < 4 ? DesignTokens.colorWarning : DesignTokens.colorGray400,
                    )),
                  )),
                  DataCell(Chip(
                    label: Text('Nieuw'),
                    backgroundColor: DesignTokens.colorInfo.withValues(alpha: 0.2),
                  )),
                  DataCell(Row(
                    children: [
                      TextButton(
                        child: Text('Accepteer'),
                        onPressed: () {},
                      ),
                      TextButton(
                        child: Text('Weiger'),
                        onPressed: () {},
                      ),
                    ],
                  )),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SHARED COMPONENTS (Adapt based on screen size)
  // ============================================================================
  
  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Goedemorgen';
    } else if (hour < 18) {
      greeting = 'Goedemiddag';
    } else {
      greeting = 'Goedenavond';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, SecureGuard BV',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightBold,
            color: SecuryFlexTheme.getColorScheme(UserRole.company).primary,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          DateFormat('EEEE d MMMM yyyy', 'nl_NL').format(now),
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: SecuryFlexTheme.getColorScheme(UserRole.company).onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Row(
        children: [
          Expanded(child: _buildWelcomeSection()),
          // Search bar for desktop
          if (CompanyResponsiveBreakpoints.isDesktop(context)) ...[
            SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Zoeken... (Ctrl+K)',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                  ),
                  filled: true,
                ),
              ),
            ),
            SizedBox(width: DesignTokens.spacingL),
          ],
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
          CircleAvatar(
            child: Text('SG'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid({required int columns}) {
    final metrics = [
      {'icon': Icons.work, 'value': '12', 'label': 'Actieve Jobs', 'color': DesignTokens.colorInfo},
      {'icon': Icons.people, 'value': '45', 'label': 'Sollicitaties', 'color': DesignTokens.colorSuccess},
      {'icon': Icons.euro, 'value': '€5.2K', 'label': 'Deze Week', 'color': DesignTokens.colorWarning},
      {'icon': Icons.trending_up, 'value': '+23%', 'label': 'Groei', 'color': DesignTokens.colorSuccess},
      {'icon': Icons.star, 'value': '4.8', 'label': 'Rating', 'color': DesignTokens.colorWarning},
      {'icon': Icons.security, 'value': '98%', 'label': 'Compliance', 'color': DesignTokens.colorInfo},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: DesignTokens.spacingM,
        mainAxisSpacing: DesignTokens.spacingM,
        // Adjusted aspect ratio to accommodate extended info on desktop
        childAspectRatio: columns > 4 ? 1.3 : 1.1, // Slightly taller cards
      ),
      itemCount: columns > 4 ? metrics.length : 4,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return UnifiedCard.compact(
          userRole: UserRole.company,
          child: _buildMetricCard(
            icon: metric['icon'] as IconData,
            value: metric['value'] as String,
            label: metric['label'] as String,
            color: metric['color'] as Color,
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final showExtendedInfo = CompanyResponsiveBreakpoints.hasDesktopFeatures(context);

    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Only take needed space
        children: [
          Icon(icon, color: color, size: showExtendedInfo ? 28 : 24), // Slightly smaller icon on desktop
          SizedBox(height: showExtendedInfo ? DesignTokens.spacingXS : DesignTokens.spacingS), // Reduced spacing on desktop
          Flexible( // Allow text to shrink if needed
            child: Text(
              value,
              style: TextStyle(
                fontSize: showExtendedInfo ? DesignTokens.fontSizeSubtitle : DesignTokens.fontSizeSubtitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS), // Consistent small spacing
          Flexible( // Allow label to shrink if needed
            child: Text(
              label,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: DesignTokens.colorGray600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2, // Allow label to wrap to 2 lines if needed
            ),
          ),
          if (showExtendedInfo) ...[
            SizedBox(height: DesignTokens.spacingXS),
            Flexible( // Allow extended info to shrink
              child: Text(
                'vs vorige week',
                style: TextStyle(
                  fontSize: 9, // Slightly smaller font
                  color: DesignTokens.colorGray500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRevenueCard({bool isDesktop = false}) {
    return UnifiedCard.featured(
      userRole: UserRole.company,
      gradientColors: [DesignTokens.colorSuccess, DesignTokens.colorSuccessLight],
      child: RevenueMetricsView(
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(_animationController),
        animationController: _animationController,
      ),
    );
  }

  Widget _buildActiveJobsList({bool isDesktop = false}) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: ActiveJobsOverview(
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(_animationController),
        animationController: _animationController,
        onViewAllJobs: () {},
      ),
    );
  }

  Widget _buildApplicationsOverview({bool isDesktop = false}) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: ModernApplicationsOverviewWidget(
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(_animationController),
        animationController: _animationController,
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, [Color? color]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: SecuryFlexTheme.getColorScheme(UserRole.company).onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: color ?? DesignTokens.colorInfo,
              fontSize: DesignTokens.fontSizeCaption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String text, String time, [IconData? icon]) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingXS),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Icon(
                icon,
                size: 14,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            SizedBox(width: DesignTokens.spacingS),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Build quick action button for desktop sidebar
  Widget _buildQuickActionButton(String text, IconData icon, VoidCallback onPressed) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          padding: EdgeInsets.symmetric(
            vertical: DesignTokens.spacingS,
            horizontal: DesignTokens.spacingM,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFAB() {
    return FloatingActionButton(
      onPressed: _navigateToJobPosting,
      backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.company).primary,
      child: Icon(Icons.add),
    );
  }

  void _navigateToJobPosting() {
    context.go(AppRoutes.companyJobPosting);
  }
  
  void _handleEmergencyAction() {
    // Show emergency action dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: DesignTokens.colorError),
            SizedBox(width: 8),
            Text('Noodgeval Actie'),
          ],
        ),
        content: Text('Direct een noodshift aanmaken voor onmiddellijke dekking?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              // TODO: Create emergency shift
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Noodshift wordt aangemaakt...'),
                  backgroundColor: DesignTokens.colorError,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.colorError,
            ),
            child: Text('Noodshift Aanmaken'),
          ),
        ],
      ),
    );
  }
  
  void _handleDataExport() {
    // Show export dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Data Exporteren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.table_chart),
              title: Text('CSV Export'),
              subtitle: Text('Spreadsheet-compatible format'),
              onTap: () {
                context.pop();
                _exportToCSV();
              },
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('PDF Rapport'),
              subtitle: Text('Formatted report with charts'),
              onTap: () {
                context.pop();
                _exportToPDF();
              },
            ),
            ListTile(
              leading: Icon(Icons.code),
              title: Text('JSON Export'),
              subtitle: Text('Raw data for integration'),
              onTap: () {
                context.pop();
                _exportToJSON();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Annuleren'),
          ),
        ],
      ),
    );
  }
  
  void _exportToCSV() {
    // TODO: Implement CSV export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV export gestart...'),
        backgroundColor: DesignTokens.colorSuccess,
      ),
    );
  }
  
  void _exportToPDF() {
    // TODO: Implement PDF export  
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF rapport wordt gegenereerd...'),
        backgroundColor: DesignTokens.colorInfo,
      ),
    );
  }
  
  void _exportToJSON() {
    // TODO: Implement JSON export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('JSON data wordt geëxporteerd...'),
        backgroundColor: DesignTokens.colorInfo,
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS FOR ENHANCED FUNCTIONALITY
  // ============================================================================

  /// Select all items in multi-select mode
  void _selectAllItems() {
    // Implementation would depend on current view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alle items geselecteerd'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Focus search field (Ctrl+K)
  void _focusSearch() {
    if (CompanyResponsiveBreakpoints.isDesktop(context)) {
      FocusScope.of(context).requestFocus(FocusNode());
      // In a real implementation, you'd focus the search text field
    }
  }

  /// Refresh all data (F5)
  void _refreshData() {
    // Now handled by BLoC
    context.read<CompanyDashboardBloc>().refresh();
  }

  /// Toggle filter panel
  void _toggleFilterPanel() {
    final currentState = context.read<CompanyDashboardBloc>().state;
    context.read<CompanyDashboardBloc>().add(FilterPanelToggled(!currentState.isFilterPanelOpen));
  }

  /// Perform search with query
  void _performSearch(String query) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Zoeken naar: "$query"'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Handle export functionality
  void _handleExport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporteren naar ${format.toUpperCase()}...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Show bulk actions menu
  void _showBulkActionsMenu(DashboardState dashboardState) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulk Acties (${dashboardState.selectedItems.length} items)',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSubtitle,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            ListTile(
              leading: Icon(Icons.edit, color: DesignTokens.colorInfo),
              title: Text('Bewerk geselecteerde'),
              onTap: () {
                context.pop();
                _performBulkEdit(dashboardState);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: DesignTokens.colorError),
              title: Text('Verwijder geselecteerde'),
              onTap: () {
                context.pop();
                _performBulkDelete(dashboardState);
              },
            ),
            ListTile(
              leading: Icon(Icons.archive, color: DesignTokens.colorWarning),
              title: Text('Archiveer geselecteerde'),
              onTap: () {
                context.pop();
                _performBulkArchive();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Perform bulk edit
  void _performBulkEdit(DashboardState dashboardState) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bulk bewerken van ${dashboardState.selectedItems.length} items'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Perform bulk delete
  void _performBulkDelete(DashboardState dashboardState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bevestig verwijdering'),
        content: Text('Weet je zeker dat je ${dashboardState.selectedItems.length} items wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              context.read<CompanyDashboardBloc>().add(const MultiSelectToggled(false));
              context.read<CompanyDashboardBloc>().add(const ItemSelectionChanged(<String>{}));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Items verwijderd'),
                  backgroundColor: DesignTokens.colorSuccess,
                ),
              );
            },
            child: Text('Verwijderen'),
          ),
        ],
      ),
    );
  }

  /// Perform bulk archive
  void _performBulkArchive() {
    context.read<CompanyDashboardBloc>().add(const MultiSelectToggled(false));
    context.read<CompanyDashboardBloc>().add(const ItemSelectionChanged(<String>{}));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Items gearchiveerd'),
        backgroundColor: DesignTokens.colorSuccess,
      ),
    );
  }

  /// Build mobile drawer for enhanced navigation
  Widget _buildMobileDrawer() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.business,
                  color: colorScheme.onPrimary,
                  size: 32,
                ),
                SizedBox(height: DesignTokens.spacingM),
                Text(
                  'SecuryFlex',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: DesignTokens.fontSizeTitle,
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
                Text(
                  'Company Dashboard',
                  style: TextStyle(
                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
                    fontSize: DesignTokens.fontSizeBody,
                  ),
                ),
              ],
            ),
          ),
          ...[ 
            {'icon': Icons.dashboard, 'title': 'Dashboard', 'route': '/'},
            {'icon': Icons.work, 'title': 'Opdrachten', 'route': '/jobs'},
            {'icon': Icons.people, 'title': 'Sollicitaties', 'route': '/applications'},
            {'icon': Icons.groups, 'title': 'Team', 'route': '/team'},
            {'icon': Icons.analytics, 'title': 'Analytics', 'route': '/analytics'},
            {'icon': Icons.account_balance_wallet, 'title': 'Financiën', 'route': '/finance'},
          ].map((item) => ListTile(
            leading: Icon(item['icon'] as IconData),
            title: Text(item['title'] as String),
            onTap: () {
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navigeren naar ${item['title']}'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          )),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Instellingen'),
            onTap: () {
              context.pop();
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
            onTap: () {
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  /// Build filter panel for desktop
  Widget _buildFilterPanel() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Container(
      margin: EdgeInsets.only(
        left: DesignTokens.spacingXL,
        right: DesignTokens.spacingXL,
        bottom: DesignTokens.spacingL,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          'Filters & Sortering',
          style: TextStyle(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: EdgeInsets.all(DesignTokens.spacingL),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      ),
                    ),
                    items: ['Alle', 'Actief', 'Inactief', 'Afgerond']
                        .map((String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (value) {},
                  ),
                ),
                SizedBox(width: DesignTokens.spacingL),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Datum',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      ),
                    ),
                    items: ['Alle', 'Vandaag', 'Deze week', 'Deze maand']
                        .map((String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (value) {},
                  ),
                ),
                SizedBox(width: DesignTokens.spacingL),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Sorteren op',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      ),
                    ),
                    items: ['Datum', 'Naam', 'Status', 'Prioriteit']
                        .map((String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}