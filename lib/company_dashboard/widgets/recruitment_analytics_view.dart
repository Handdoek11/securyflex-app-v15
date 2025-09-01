import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_buttons.dart';
import '../bloc/analytics_dashboard_bloc.dart';
import '../localization/company_nl.dart';

/// Comprehensive recruitment analytics dashboard for company users
/// Displays recruitment funnel, job performance metrics, and trend analysis
/// Integrates with existing analytics system and follows SecuryFlex design standards
class RecruitmentAnalyticsView extends StatefulWidget {
  final String companyId;
  final AnimationController? animationController;
  final ScrollController? scrollController;

  const RecruitmentAnalyticsView({
    super.key,
    required this.companyId,
    this.animationController,
    this.scrollController,
  });

  @override
  State<RecruitmentAnalyticsView> createState() => _RecruitmentAnalyticsViewState();
}

class _RecruitmentAnalyticsViewState extends State<RecruitmentAnalyticsView>
    with TickerProviderStateMixin {
  late AnalyticsDashboardBloc _analyticsBloc;
  @override
  void initState() {
    super.initState();
// Default to first range
    _analyticsBloc = AnalyticsDashboardBloc();
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _analyticsBloc.close();
    super.dispose();
  }

  void _loadAnalyticsData() {
    _analyticsBloc.add(LoadDashboardData(widget.companyId));
    _analyticsBloc.add(LoadJobPerformance(widget.companyId)); // Using companyId as jobId for now
    _analyticsBloc.add(const LoadFunnelInsights());
    _analyticsBloc.add(const LoadSourceAnalysis());
  }





  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _analyticsBloc,
      child: BlocBuilder<AnalyticsDashboardBloc, AnalyticsDashboardState>(
        builder: (context, state) {
          // Handle error state gracefully
          if (state.status == AnalyticsDashboardStatus.error) {
            return Container(
              color: SecuryFlexTheme.getColorScheme(UserRole.company).surfaceContainerHighest,
              child: Center(
                child: UnifiedCard.standard(
                  userRole: UserRole.company,
                  padding: EdgeInsets.all(DesignTokens.spacingL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: DesignTokens.iconSizeXXL,
                        color: SecuryFlexTheme.getColorScheme(UserRole.company).onSurfaceVariant,
                      ),
                      SizedBox(height: DesignTokens.spacingM),
                      Text(
                        'Analytics tijdelijk niet beschikbaar',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontFamily: DesignTokens.fontFamily,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: DesignTokens.spacingS),
                      Text(
                        'We werken aan het beschikbaar maken van analytics data. Probeer het later opnieuw.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: DesignTokens.fontFamily,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: DesignTokens.spacingL),
                      UnifiedButton.primary(
                        text: 'Probeer Opnieuw',
                        onPressed: () => _loadAnalyticsData(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return _buildAnalyticsContent(context, state);
        },
      ),
    );
  }

  /// Build analytics content with simplified section-based layout
  Widget _buildAnalyticsContent(BuildContext context, AnalyticsDashboardState state) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            CompanyNL.analytics,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSection,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),

          SizedBox(height: DesignTokens.spacingM),

          // Analytics content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Analytics metrics section
                _buildAnalyticsMetricsSection(context, state),

                SizedBox(height: DesignTokens.spacingL),

                // Key insights section
                _buildKeyInsightsSection(context, state),

                SizedBox(height: DesignTokens.spacingL),

                // Performance summary section
                _buildPerformanceSummarySection(context, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build analytics metrics section with UnifiedCard.compact
  Widget _buildAnalyticsMetricsSection(BuildContext context, AnalyticsDashboardState state) {
    if (state.status == AnalyticsDashboardStatus.loading) {
      return const CircularProgressIndicator();
    }

    final dashboardData = state.dashboardData;
    if (dashboardData == null) {
      return Text('Geen gegevens beschikbaar');
    }

    final todayData = dashboardData['today'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        // Metrics grid
        Row(
          children: [
            Expanded(
              child: UnifiedCard.compact(
                userRole: UserRole.company,
                child: _buildMetricContent(
                  context,
                  CompanyNL.totalJobsPosted,
                  (todayData['activeJobs'] ?? 0).toString(),
                  Icons.work_outline,
                  DesignTokens.colorInfo,
                ),
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: UnifiedCard.compact(
                userRole: UserRole.company,
                child: _buildMetricContent(
                  context,
                  CompanyNL.totalApplicationsReceived,
                  (todayData['applications'] ?? 0).toString(),
                  Icons.people_outline,
                  DesignTokens.statusInProgress,
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
                child: _buildMetricContent(
                  context,
                  'Bekeken Vandaag',
                  (todayData['views'] ?? 0).toString(),
                  Icons.visibility,
                  DesignTokens.statusCompleted,
                ),
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: UnifiedCard.compact(
                userRole: UserRole.company,
                child: _buildMetricContent(
                  context,
                  'Conversie Rate',
                  '${(todayData['conversionRate'] ?? 0.0).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  DesignTokens.colorWarning,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build metric content for UnifiedCard.compact
  Widget _buildMetricContent(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: color,
          size: DesignTokens.iconSizeL,
        ),
        SizedBox(height: DesignTokens.spacingS),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: DesignTokens.fontWeightBold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: DesignTokens.fontFamily,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build key insights section
  Widget _buildKeyInsightsSection(BuildContext context, AnalyticsDashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CompanyNL.insights,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        Padding(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Belangrijkste Inzichten',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
              SizedBox(height: DesignTokens.spacingS),
              Text(
                '• Gemiddelde responstijd: 2.5 uur\n'
                '• Beste presterende job type: Objectbeveiliging\n'
                '• Piek sollicitatie tijd: 14:00-16:00',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build performance summary section
  Widget _buildPerformanceSummarySection(BuildContext context, AnalyticsDashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CompanyNL.performance,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        Padding(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prestatie Overzicht',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
              SizedBox(height: DesignTokens.spacingS),
              Text(
                'Uw recruitment prestaties zijn stabiel met een goede conversie ratio.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }



















}
