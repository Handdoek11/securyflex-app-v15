import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';
import '../widgets/revenue_metrics_view.dart';
import '../widgets/active_jobs_overview.dart';
import '../../unified_components/modern_applications_overview_widget.dart';
import '../bloc/dashboard_state.dart';

/// Dashboard Overview Content Component
/// 
/// Displays the main dashboard content with metrics, revenue cards,
/// active jobs, and applications overview. This component is optimized
/// for both desktop and data table layouts.
class DashboardOverviewContent extends StatelessWidget {
  final bool useDataTables;
  final DashboardState dashboardState;
  final int columns;

  const DashboardOverviewContent({
    super.key,
    required this.useDataTables,
    required this.dashboardState,
    this.columns = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Metrics grid layout
        _buildMetricsGrid(),
        SizedBox(height: DesignTokens.spacingXL),
        
        // Revenue card
        _buildRevenueCard(),
        SizedBox(height: DesignTokens.spacingL),
        
        // Jobs and applications overview
        useDataTables 
          ? _buildJobsDataTable()
          : _buildActiveJobsList(),
        SizedBox(height: DesignTokens.spacingL),
        useDataTables
          ? _buildApplicationsDataTable()
          : _buildApplicationsOverview(),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      mainAxisSpacing: DesignTokens.spacingM,
      crossAxisSpacing: DesignTokens.spacingM,
      childAspectRatio: 2.5,
      children: [
        _buildMetricCard('Actieve Jobs', '24', Icons.work, DesignTokens.colorInfo),
        _buildMetricCard('Sollicitaties', '142', Icons.people, DesignTokens.colorSuccess),
        _buildMetricCard('Team Members', '18', Icons.groups, DesignTokens.colorWarning),
        _buildMetricCard('Maandelijkse Omzet', '€24.5K', Icons.euro, SecuryFlexTheme.getColorScheme(UserRole.company).primary),
        if (columns > 4) ...[
          _buildMetricCard('Tevredenheid', '94%', Icons.thumb_up, DesignTokens.colorSuccess),
          _buildMetricCard('Response Time', '1.2u', Icons.speed, DesignTokens.colorInfo),
        ],
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeSubtitle,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: SecuryFlexTheme.getColorScheme(UserRole.company).onSurface,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: SecuryFlexTheme.getColorScheme(UserRole.company).onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return RevenueMetricsView();
  }

  Widget _buildActiveJobsList() {
    return ActiveJobsOverview();
  }

  Widget _buildApplicationsOverview() {
    return ModernApplicationsOverviewWidget();
  }

  // Placeholder data table methods - these will be implemented when needed
  Widget _buildJobsDataTable() {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Container(
        height: 400,
        child: Center(
          child: Text(
            'Jobs Data Table\n(To be implemented)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SecuryFlexTheme.getColorScheme(UserRole.company).onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationsDataTable() {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Container(
        height: 400,
        child: Center(
          child: Text(
            'Applications Data Table\n(To be implemented)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SecuryFlexTheme.getColorScheme(UserRole.company).onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}