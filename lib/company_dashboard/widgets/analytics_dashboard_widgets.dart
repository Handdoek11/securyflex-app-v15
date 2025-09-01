import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_buttons.dart';
import '../bloc/analytics_dashboard_bloc.dart';
import '../../core/responsive/responsive_provider.dart';
import '../../core/responsive/responsive_extensions.dart';
import '../../routing/app_routes.dart';

/// Analytics Dashboard Overview Widget
/// Displays key metrics and performance indicators
class AnalyticsDashboardOverview extends StatelessWidget {
  final String companyId;

  const AnalyticsDashboardOverview({
    super.key,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsDashboardBloc, AnalyticsDashboardState>(
      builder: (context, state) {
        if (state.status == AnalyticsDashboardStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state.status == AnalyticsDashboardStatus.error) {
          return UnifiedCard.standard(
            userRole: UserRole.company,
            padding: EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: DesignTokens.iconSizeXL,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  Text(
                    'Fout bij laden van analytics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Text(
                    state.errorMessage ?? 'Onbekende fout opgetreden',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  UnifiedButton.secondary(
                    text: 'Opnieuw proberen',
                    onPressed: () {
                      context.read<AnalyticsDashboardBloc>().add(
                        RefreshDashboardData(),
                      );
                    },
                  ),
                ],
              ),
          );
        }

        if (!state.hasData) {
          return const AnalyticsEmptyState();
        }

        return Column(
          children: [
            // Key Metrics Row
            AnalyticsMetricsRow(
              todayMetrics: state.todayMetrics,
              changes: state.dashboardData?['changes'],
            ),
            
            SizedBox(height: DesignTokens.spacingL),
            
            // Performance Indicators
            AnalyticsPerformanceIndicators(
              performance: state.performanceIndicators,
            ),
            
            SizedBox(height: DesignTokens.spacingL),
            
            // Time Series Chart
            AnalyticsTimeSeriesChart(
              data: state.filteredTimeSeriesData,
              timeRange: state.timeRange,
            ),
            
            SizedBox(height: DesignTokens.spacingL),
            
            // Quick Actions
            AnalyticsQuickActions(
              companyId: companyId,
              isDataStale: state.isDataStale,
              lastUpdated: state.lastUpdated,
            ),
          ],
        );
      },
    );
  }
}

/// Analytics Metrics Row
/// Displays key metrics with trend indicators
class AnalyticsMetricsRow extends StatelessWidget {
  final Map<String, dynamic>? todayMetrics;
  final Map<String, dynamic>? changes;

  const AnalyticsMetricsRow({
    super.key,
    this.todayMetrics,
    this.changes,
  });

  @override
  Widget build(BuildContext context) {
    if (todayMetrics == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = context.screenWidth;
        final isMobile = screenWidth < 600;

        if (isMobile) {
          // Mobile: 2x2 grid layout
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AnalyticsMetricCard(
                      title: 'Bekeken',
                      value: todayMetrics!['views']?.toString() ?? '0',
                      change: changes?['views']?.toDouble(),
                      icon: Icons.visibility,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: AnalyticsMetricCard(
                      title: 'Sollicitaties',
                      value: todayMetrics!['applications']?.toString() ?? '0',
                      change: changes?['applications']?.toDouble(),
                      icon: Icons.person_add,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingM),
              Row(
                children: [
                  Expanded(
                    child: AnalyticsMetricCard(
                      title: 'Conversie',
                      value: '${todayMetrics!['conversionRate']?.toStringAsFixed(1) ?? '0.0'}%',
                      change: null, // Conversion rate change calculated differently
                      icon: Icons.trending_up,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: AnalyticsMetricCard(
                      title: 'Uitgaven',
                      value: '€${todayMetrics!['spend']?.toStringAsFixed(0) ?? '0'}',
                      change: null,
                      icon: Icons.euro,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Desktop/Tablet: Single row layout
          return Row(
            children: [
              Expanded(
                child: AnalyticsMetricCard(
                  title: 'Bekeken',
                  value: todayMetrics!['views']?.toString() ?? '0',
                  change: changes?['views']?.toDouble(),
                  icon: Icons.visibility,
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: AnalyticsMetricCard(
                  title: 'Sollicitaties',
                  value: todayMetrics!['applications']?.toString() ?? '0',
                  change: changes?['applications']?.toDouble(),
                  icon: Icons.person_add,
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: AnalyticsMetricCard(
                  title: 'Conversie',
                  value: '${todayMetrics!['conversionRate']?.toStringAsFixed(1) ?? '0.0'}%',
                  change: null, // Conversion rate change calculated differently
                  icon: Icons.trending_up,
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: AnalyticsMetricCard(
                  title: 'Uitgaven',
                  value: '€${todayMetrics!['spend']?.toStringAsFixed(0) ?? '0'}',
                  change: null,
                  icon: Icons.euro,
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

/// Individual Metric Card
class AnalyticsMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final double? change;
  final IconData icon;

  const AnalyticsMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.change,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = context.screenWidth;
        final isMobile = screenWidth < 600;

        return UnifiedCard.standard(
          userRole: UserRole.company,
          padding: EdgeInsets.all(isMobile ? DesignTokens.spacingS : DesignTokens.spacingM),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: isMobile ? 80 : 100,
              maxHeight: isMobile ? 120 : 140,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: isMobile ? DesignTokens.iconSizeS : DesignTokens.iconSizeM,
                  color: companyColors.primary,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            if (change != null) ...[
              SizedBox(height: DesignTokens.spacingXS),
              Row(
                children: [
                  Icon(
                    change! > 0 ? Icons.arrow_upward :
                    change! < 0 ? Icons.arrow_downward : Icons.remove,
                    size: isMobile ? DesignTokens.iconSizeXS : DesignTokens.iconSizeS,
                    color: change! > 0 ? DesignTokens.statusConfirmed :
                           change! < 0 ? DesignTokens.statusCancelled : Colors.grey,
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    '${change!.abs().toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: change! > 0 ? DesignTokens.statusConfirmed : 
                             change! < 0 ? DesignTokens.statusCancelled : Colors.grey,
                      fontWeight: DesignTokens.fontWeightMedium,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ],
              ),
            ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Performance Indicators Widget
class AnalyticsPerformanceIndicators extends StatelessWidget {
  final Map<String, dynamic>? performance;

  const AnalyticsPerformanceIndicators({
    super.key,
    this.performance,
  });

  @override
  Widget build(BuildContext context) {
    if (performance == null) return const SizedBox.shrink();

    return UnifiedCard.standard(
      userRole: UserRole.company,
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prestatie Indicatoren',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Row(
              children: [
                Expanded(
                  child: AnalyticsProgressIndicator(
                    label: 'Efficiëntie',
                    value: performance!['efficiency']?.toDouble() ?? 0.0,
                    maxValue: 100.0,
                    color: DesignTokens.statusAccepted,
                  ),
                ),
                SizedBox(width: DesignTokens.spacingL),
                Expanded(
                  child: AnalyticsProgressIndicator(
                    label: 'Kwaliteit',
                    value: (performance!['qualityScore']?.toDouble() ?? 0.0) * 20, // Scale to 100
                    maxValue: 100.0,
                    color: DesignTokens.statusConfirmed,
                  ),
                ),
                SizedBox(width: DesignTokens.spacingL),
                Expanded(
                  child: AnalyticsProgressIndicator(
                    label: 'Retentie',
                    value: performance!['retentionRate']?.toDouble() ?? 0.0,
                    maxValue: 100.0,
                    color: DesignTokens.statusPending,
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

/// Progress Indicator for Analytics
class AnalyticsProgressIndicator extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  const AnalyticsProgressIndicator({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingS),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }
}

/// Empty State Widget
class AnalyticsEmptyState extends StatelessWidget {
  const AnalyticsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      padding: EdgeInsets.all(DesignTokens.spacingXL),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: DesignTokens.iconSizeXXL,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: DesignTokens.spacingL),
            Text(
              'Geen Analytics Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Er zijn nog geen analytics gegevens beschikbaar. '
              'Post je eerste opdracht om data te verzamelen.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: DesignTokens.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.spacingL),
            UnifiedButton.primary(
              text: 'Nieuwe Opdracht Plaatsen',
              onPressed: () {
                // Navigate to job posting
                context.go(AppRoutes.companyJobPosting);
              },
            ),
          ],
        ),
    );
  }
}

/// Time Series Chart Widget
class AnalyticsTimeSeriesChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final AnalyticsTimeRange timeRange;

  const AnalyticsTimeSeriesChart({
    super.key,
    required this.data,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trend Analyse',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
                Text(
                  timeRange.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = context.screenWidth;
                final isMobile = screenWidth < 600;
                final chartHeight = isMobile ? 180.0 : 200.0;

                if (data.isEmpty) {
                  return SizedBox(
                    height: chartHeight,
                    child: Center(
                    child: Text(
                      'Geen data beschikbaar voor geselecteerde periode',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    ),
                  );
                } else {
                  return SizedBox(
                    height: chartHeight,
                    child: AnalyticsSimpleChart(data: data),
                  );
                }
              },
            ),
          ],
        ),
    );
  }
}

/// Simple Chart Implementation (placeholder for actual chart library)
class AnalyticsSimpleChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const AnalyticsSimpleChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // This is a simplified chart representation
    // In a real implementation, you would use a chart library like fl_chart
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: DesignTokens.iconSizeXL,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Chart Visualisatie',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              '${data.length} datapunten',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick Actions Widget
class AnalyticsQuickActions extends StatelessWidget {
  final String companyId;
  final bool isDataStale;
  final DateTime? lastUpdated;

  const AnalyticsQuickActions({
    super.key,
    required this.companyId,
    required this.isDataStale,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Snelle Acties',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: DesignTokens.iconSizeS),
                      SizedBox(width: DesignTokens.spacingXS),
                      Expanded(
                        child: UnifiedButton.secondary(
                          text: 'Ververs Data',
                          onPressed: () {
                            context.read<AnalyticsDashboardBloc>().add(
                              RefreshDashboardData(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics, size: DesignTokens.iconSizeS),
                      SizedBox(width: DesignTokens.spacingXS),
                      Expanded(
                        child: UnifiedButton.secondary(
                          text: 'Funnel Analyse',
                          onPressed: () {
                            context.read<AnalyticsDashboardBloc>().add(
                              LoadFunnelInsights(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.source_outlined, size: DesignTokens.iconSizeS),
                      SizedBox(width: DesignTokens.spacingXS),
                      Expanded(
                        child: UnifiedButton.secondary(
                          text: 'Bron Analyse',
                          onPressed: () {
                            context.read<AnalyticsDashboardBloc>().add(
                              LoadSourceAnalysis(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isDataStale) ...[
              SizedBox(height: DesignTokens.spacingM),
              UnifiedCard.standard(
                userRole: UserRole.company,
                padding: EdgeInsets.all(DesignTokens.spacingM),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: DesignTokens.iconSizeM,
                    ),
                    SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        'Data is verouderd. Ververs voor de laatste gegevens.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (lastUpdated != null) ...[
              SizedBox(height: DesignTokens.spacingS),
              Text(
                'Laatst bijgewerkt: ${_formatDateTime(lastUpdated!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
          ],
        ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Zojuist';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minuten geleden';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} uur geleden';
    } else {
      return '${difference.inDays} dagen geleden';
    }
  }
}
