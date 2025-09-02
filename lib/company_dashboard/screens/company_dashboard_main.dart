import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/company_dashboard/screens/company_notifications_screen.dart';

import 'package:securyflex_app/company_dashboard/widgets/active_jobs_overview.dart';
import 'package:securyflex_app/unified_components/modern_applications_overview_widget.dart';
import 'package:securyflex_app/company_dashboard/widgets/revenue_metrics_view.dart';

import 'package:securyflex_app/company_dashboard/services/job_posting_service.dart';
import 'package:securyflex_app/company_dashboard/services/application_review_service.dart';
import 'package:securyflex_app/routing/app_routes.dart';

// Billing integration
import 'package:securyflex_app/billing/widgets/subscription_status_widget.dart';
import 'package:securyflex_app/billing/screens/subscription_upgrade_screen.dart';
import 'package:securyflex_app/auth/auth_service.dart';


import 'package:securyflex_app/company_dashboard/screens/job_posting_form_screen.dart';
import 'package:securyflex_app/company_dashboard/utils/company_layout_tokens.dart';


import 'package:flutter/material.dart';
import '../../core/responsive/responsive_provider.dart';
import '../../core/responsive/responsive_extensions.dart';
import 'package:intl/intl.dart';

// ============================================================================
// MOBILE-FIRST DASHBOARD - CLEAN WIREFRAME IMPLEMENTATION
// ============================================================================

/// Main Company dashboard screen following beveiliger_dashboard_main.dart pattern
/// with Company theming and Company-specific widgets
class CompanyDashboardMain extends StatefulWidget {
  const CompanyDashboardMain({super.key, this.animationController});

  final AnimationController? animationController;

  @override
  State<CompanyDashboardMain> createState() => _CompanyDashboardMainState();
}

class _CompanyDashboardMainState extends State<CompanyDashboardMain>
    with TickerProviderStateMixin {
  Animation<double>? topBarAnimation;
  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;

  @override
  void initState() {
    topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: widget.animationController!,
            curve: Interval(0, 0.5, curve: Curves.fastOutSlowIn)));

    // Add scroll listener for header opacity animation
    scrollController.addListener(() {
      if (scrollController.offset >= CompanyLayoutTokens.scrollThreshold) {
        if (topBarOpacity != 1.0) {
          setState(() {
            topBarOpacity = 1.0;
          });
        }
      } else if (scrollController.offset <= CompanyLayoutTokens.scrollThreshold &&
          scrollController.offset >= 0) {
        if (topBarOpacity != scrollController.offset / CompanyLayoutTokens.scrollThreshold) {
          setState(() {
            topBarOpacity = scrollController.offset / CompanyLayoutTokens.scrollThreshold;
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

    // Initialize mock data for Company services
    JobPostingService.initializeMockData();
    ApplicationReviewService.instance.initializeMockData('company_demo');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Container(
      color: companyColors.surfaceContainerHighest,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child: _buildAppBarUI(),
        ),
        body: Column(
          children: [
            // Simple welcome section
            _buildWelcomeSection(),
            // Main dashboard content
            Expanded(child: _buildDashboardContent()),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // MOBILE-FIRST DASHBOARD SECTIONS
  // ============================================================================



  /// Simple welcome section
  Widget _buildWelcomeSection() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welkom terug!',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSection,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  'Beheer je beveiligingsopdrachten',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    color: DesignTokens.colorGray600,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Main dashboard content with sections
  Widget _buildDashboardContent() {
    return FutureBuilder<bool>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        } else {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(
              bottom: 62 + context.safeAreaResponsivePadding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2x2 Metrics Grid Section
                _buildMetricsSection(),

                // Featured Revenue Card Section
                _buildRevenueSection(),

                // Subscription status section
                _buildSubscriptionSection(),

                // Active Jobs List Section
                _buildActiveJobsSection(),

                // Applications Summary Section
                _buildApplicationsSection(),

                // 2x1 Quick Actions Grid Section
                _buildQuickActionsSection(),
              ],
            ),
          );
        }
      },
    );
  }

  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    return true;
  }

  // ============================================================================
  // DASHBOARD SECTIONS
  // ============================================================================

  /// 2x2 Metrics Grid Section
  Widget _buildMetricsSection() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    final currencyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');

    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overzicht',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSection,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          // 2x2 Grid
          Row(
            children: [
              Expanded(
                child: UnifiedCard.compact(
                  userRole: UserRole.company,
                  child: _buildMetricItem(
                    icon: Icons.work,
                    value: '5',
                    label: 'Actieve Jobs',
                    color: companyColors.primary,
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: UnifiedCard.compact(
                  userRole: UserRole.company,
                  child: _buildMetricItem(
                    icon: Icons.people,
                    value: '12',
                    label: 'Sollicitaties',
                    color: companyColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingM),
          Row(
            children: [
              Expanded(
                child: UnifiedCard.compact(
                  userRole: UserRole.company,
                  child: _buildMetricItem(
                    icon: Icons.euro,
                    value: currencyFormat.format(2100),
                    label: 'Deze Maand',
                    color: DesignTokens.colorSuccess,
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: UnifiedCard.compact(
                  userRole: UserRole.company,
                  child: _buildMetricItem(
                    icon: Icons.trending_up,
                    value: '+15%',
                    label: 'Groei',
                    color: DesignTokens.colorSuccess,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Featured Revenue Card Section
  Widget _buildRevenueSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financiën',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSection,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          UnifiedCard.featured(
            userRole: UserRole.company,
            gradientColors: [
              DesignTokens.colorSuccess,
              DesignTokens.colorSuccessLight,
            ],
            child: RevenueMetricsView(
              animation: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: widget.animationController!,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
              animationController: widget.animationController!,
            ),
          ),
        ],
      ),
    );
  }

  /// Active Jobs List Section
  Widget _buildActiveJobsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'Actieve Jobs',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSection,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          UnifiedCard.standard(
            userRole: UserRole.company,
            child: ActiveJobsOverview(
              animation: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: widget.animationController!,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
              animationController: widget.animationController!,
              onViewAllJobs: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ga naar de "Opdrachten" tab onderaan voor alle jobs'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Applications Summary Section
  Widget _buildApplicationsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'Sollicitaties',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSection,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          UnifiedCard.standard(
            userRole: UserRole.company,
            child: ModernApplicationsOverviewWidget(
              animation: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: widget.animationController!,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
              animationController: widget.animationController!,
            ),
          ),
        ],
      ),
    );
  }

  /// 2x1 Quick Actions Grid Section
  Widget _buildQuickActionsSection() {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Snelle Acties',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSection,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          Row(
            children: [
              Expanded(
                child: UnifiedCard.standard(
                  userRole: UserRole.company,
                  isClickable: true,
                  onTap: () => _navigateToJobPosting(),
                  child: _buildQuickActionItem(
                    icon: Icons.add_business,
                    title: 'Nieuwe Job',
                    subtitle: 'Plaats opdracht',
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: UnifiedCard.standard(
                  userRole: UserRole.company,
                  isClickable: true,
                  onTap: () => _navigateToApplicationsScreen(),
                  child: _buildQuickActionItem(
                    icon: Icons.people_outline,
                    title: 'Kandidaten',
                    subtitle: 'Bekijk sollicitaties',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Build metric item for compact cards
  Widget _buildMetricItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: DesignTokens.iconSizeL,
        ),
        SizedBox(height: DesignTokens.spacingS),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: DesignTokens.fontWeightBold,
            fontSize: DesignTokens.fontSizeSection,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: DesignTokens.colorGray600,
            fontWeight: DesignTokens.fontWeightMedium,
            fontSize: DesignTokens.fontSizeCaption,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
      ],
    );
  }

  /// Build quick action item
  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeXL,
            color: DesignTokens.colorPrimaryBlue,
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            title,
            style: TextStyle(
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontSize: DesignTokens.fontSizeBody,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DesignTokens.colorGray600,
              fontSize: DesignTokens.fontSizeCaption,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  /// Company gradient header UI
  Widget _buildAppBarUI() {
    return UnifiedHeader.companyGradient(
      title: 'Dashboard',
      showNotifications: true,
      onNotificationPressed: () => _navigateToNotifications(),
    );
  }

  // ============================================================================
  // NAVIGATION METHODS
  // ============================================================================

  void _navigateToNotifications() {
    context.go(AppRoutes.companyNotifications);
  }

  void _navigateToJobPosting() {
    context.go(AppRoutes.companyJobPosting);
  }

  void _navigateToApplicationsScreen() {
    // Navigate to applications tab or screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ga naar de "Sollicitaties" tab onderaan'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Build subscription status section
  Widget _buildSubscriptionSection() {
    final userId = AuthService.currentUserId;
    if (userId.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: SubscriptionStatusWidget(
        userId: userId,
        showDetails: false, // Compact view for dashboard
        onUpgradePressed: () => _navigateToSubscriptionUpgrade(),
      ),
    );
  }

  /// Navigate to subscription upgrade screen
  void _navigateToSubscriptionUpgrade() {
    final userId = AuthService.currentUserId;
    context.push('/subscription-upgrade');
    // Original: context.push('/route-placeholder') => SubscriptionUpgradeScreen(
    //       userId: userId.isNotEmpty ? userId : null,
    //     ),
    //   ),
    // );
  }
}
   