import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_theme_system.dart';
// CompanyDashboardTheme import removed - using unified design tokens
import 'package:securyflex_app/company_dashboard/models/business_intelligence_data.dart';
import 'package:securyflex_app/company_dashboard/services/revenue_analytics_service.dart';
import '../../core/responsive/responsive_provider.dart';
import '../../core/responsive/responsive_extensions.dart';

/// Revenue Optimization Widget for advanced revenue tracking and forecasting
/// Provides comprehensive revenue analytics with profit optimization insights
class RevenueOptimizationWidget extends StatefulWidget {
  final AnimationController animationController;
  final Animation<double> animation;

  const RevenueOptimizationWidget({
    super.key,
    required this.animationController,
    required this.animation,
  });

  @override
  State<RevenueOptimizationWidget> createState() =>
      _RevenueOptimizationWidgetState();
}

class _RevenueOptimizationWidgetState extends State<RevenueOptimizationWidget> {
  final String _companyId = 'COMP001';
  Map<String, double>? _projections;
  List<RevenueByServiceType>? _serviceBreakdown;
  Map<String, dynamic>? _costMetrics;
  Map<String, dynamic>? _benchmarks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    try {
      final projections = await RevenueAnalyticsService.instance
          .getRevenueProjections(_companyId);
      final serviceBreakdown = await RevenueAnalyticsService.instance
          .getProfitMarginAnalysis(_companyId);
      final costMetrics = await RevenueAnalyticsService.instance
          .getCostPerAcquisitionMetrics(_companyId);
      final benchmarks = await RevenueAnalyticsService.instance
          .getCompetitionBenchmarks();

      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          _projections = projections;
          _serviceBreakdown = serviceBreakdown;
          _costMetrics = costMetrics;
          _benchmarks = benchmarks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: widget.animation,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - widget.animation.value),
              0.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(DesignTokens.spacingL),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: DesignTokens.revenueGreen,
                        size: DesignTokens.iconSizeL,
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Expanded(
                        child: Text(
                          'Revenue Optimalisatie',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: DesignTokens.fontWeightSemiBold,
                                color: DesignTokens.darkText,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: _loadRevenueData,
                        icon: Icon(
                          Icons.refresh,
                          color: DesignTokens.revenueGreen,
                          size: DesignTokens.iconSizeM,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isLoading)
                  Padding(
                    padding: EdgeInsets.all(DesignTokens.spacingXL),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.revenueGreen,
                      ),
                    ),
                  )
                else ...[
                  // Revenue Projections
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingL,
                    ),
                    child: _buildRevenueProjectionsSection(context),
                  ),

                  SizedBox(height: DesignTokens.spacingL),

                  // Service Type Breakdown
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingL,
                    ),
                    child: _buildServiceBreakdownSection(context),
                  ),

                  SizedBox(height: DesignTokens.spacingL),

                  // Cost Optimization Metrics
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingL,
                    ),
                    child: _buildCostOptimizationSection(context),
                  ),

                  SizedBox(height: DesignTokens.spacingL),

                  // Market Position & Benchmarks
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingL,
                    ),
                    child: _buildMarketBenchmarksSection(context),
                  ),

                  SizedBox(height: DesignTokens.spacingL),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevenueProjectionsSection(BuildContext context) {
    if (_projections == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = context.screenWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 900;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Voorspellingen',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.darkText,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),

            // Responsive layout based on screen size
            if (isMobile)
              // Mobile: Single column layout
              Column(
                children: [
                  _buildProjectionCard(
                    context,
                    '30 Dagen',
                    '€${_projections!['30_days']?.toStringAsFixed(0) ?? '0'}',
                    '${(_projections!['confidence_30']! * 100).toStringAsFixed(0)}% zekerheid',
                    DesignTokens.revenueGreen,
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  _buildProjectionCard(
                    context,
                    '60 Dagen',
                    '€${_projections!['60_days']?.toStringAsFixed(0) ?? '0'}',
                    '${(_projections!['confidence_60']! * 100).toStringAsFixed(0)}% zekerheid',
                    DesignTokens.analyticsBlue,
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  _buildProjectionCard(
                    context,
                    '90 Dagen',
                    '€${_projections!['90_days']?.toStringAsFixed(0) ?? '0'}',
                    '${(_projections!['confidence_90']! * 100).toStringAsFixed(0)}% zekerheid',
                    DesignTokens.companyTeal,
                  ),
                ],
              )
            else if (isTablet)
              // Tablet: 2 cards per row
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildProjectionCard(
                          context,
                          '30 Dagen',
                          '€${_projections!['30_days']?.toStringAsFixed(0) ?? '0'}',
                          '${(_projections!['confidence_30']! * 100).toStringAsFixed(0)}% zekerheid',
                          DesignTokens.revenueGreen,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingM),
                      Expanded(
                        child: _buildProjectionCard(
                          context,
                          '60 Dagen',
                          '€${_projections!['60_days']?.toStringAsFixed(0) ?? '0'}',
                          '${(_projections!['confidence_60']! * 100).toStringAsFixed(0)}% zekerheid',
                          DesignTokens.analyticsBlue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: _buildProjectionCard(
                          context,
                          '90 Dagen',
                          '€${_projections!['90_days']?.toStringAsFixed(0) ?? '0'}',
                          '${(_projections!['confidence_90']! * 100).toStringAsFixed(0)}% zekerheid',
                          DesignTokens.companyTeal,
                        ),
                      ),
                      Expanded(child: SizedBox()), // Empty space for alignment
                    ],
                  ),
                ],
              )
            else
              // Desktop: 3 cards in a row
              Row(
                children: [
                  Expanded(
                    child: _buildProjectionCard(
                      context,
                      '30 Dagen',
                      '€${_projections!['30_days']?.toStringAsFixed(0) ?? '0'}',
                      '${(_projections!['confidence_30']! * 100).toStringAsFixed(0)}% zekerheid',
                      DesignTokens.revenueGreen,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: _buildProjectionCard(
                      context,
                      '60 Dagen',
                      '€${_projections!['60_days']?.toStringAsFixed(0) ?? '0'}',
                      '${(_projections!['confidence_60']! * 100).toStringAsFixed(0)}% zekerheid',
                      DesignTokens.analyticsBlue,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: _buildProjectionCard(
                      context,
                      '90 Dagen',
                      '€${_projections!['90_days']?.toStringAsFixed(0) ?? '0'}',
                      '${(_projections!['confidence_90']! * 100).toStringAsFixed(0)}% zekerheid',
                      DesignTokens.companyTeal,
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildProjectionCard(
    BuildContext context,
    String period,
    String amount,
    String confidence,
    Color color,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = context.screenWidth;
        final isMobile = screenWidth < 600;

        return UnifiedCard.standard(
          userRole: UserRole.company,
          padding: EdgeInsets.all(DesignTokens.spacingM),
          backgroundColor: color.withValues(alpha: 0.1),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: isMobile ? 100 : 120,
              maxHeight: isMobile ? 140 : 160,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  period,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontSize: isMobile ? 11 : 12,
                  ),
                ),
                Flexible(
                  child: Text(
                    amount,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightBold,
                      color: color,
                      fontSize: isMobile ? 16 : 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  confidence,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.8),
                    fontSize: isMobile ? 9 : 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceBreakdownSection(BuildContext context) {
    if (_serviceBreakdown == null || _serviceBreakdown!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Omzet per Service Type',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.darkText,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        ...List.generate(
          _serviceBreakdown!.length,
          (index) => _buildServiceItem(context, _serviceBreakdown![index]),
        ),
      ],
    );
  }

  Widget _buildServiceItem(BuildContext context, RevenueByServiceType service) {
    final colors = [
      DesignTokens.revenueGreen,
      DesignTokens.analyticsBlue,
      DesignTokens.companyTeal,
      DesignTokens.jobOrange,
    ];

    final color = colors[_serviceBreakdown!.indexOf(service) % colors.length];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = context.screenWidth;
        final isMobile = screenWidth < 600;

        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: isMobile ? 40 : 50,
              maxWidth: constraints.maxWidth,
            ),
            child: Row(
              children: [
                Container(
                  width: isMobile
                      ? DesignTokens.spacingXS / 2
                      : DesignTokens.spacingXS,
                  height: isMobile
                      ? DesignTokens.spacingXL + DesignTokens.spacingS
                      : DesignTokens.spacingXL * 2,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
                  ),
                ),
                SizedBox(
                  width: isMobile
                      ? DesignTokens.spacingS
                      : DesignTokens.spacingM,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        service.serviceType,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: DesignTokens.darkText,
                          fontSize: isMobile ? 12 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${service.jobCount} jobs • ${service.percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DesignTokens.lightText,
                          fontSize: isMobile ? 10 : 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '€${service.revenue.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: color,
                    fontSize: isMobile ? 12 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCostOptimizationSection(BuildContext context) {
    if (_costMetrics == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = context.screenWidth;
        final isMobile = screenWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kosten Optimalisatie',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.darkText,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),

            // Responsive layout based on screen size
            if (isMobile)
              // Mobile: Single column layout
              Column(
                children: [
                  _buildCostMetricCard(
                    context,
                    'Kosten per Aanwerving',
                    '€${_costMetrics!['cost_per_guard_hire']?.toStringAsFixed(2) ?? '0'}',
                    Icons.person_add,
                    DesignTokens.jobOrange,
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  _buildCostMetricCard(
                    context,
                    'Levensduurwaarde',
                    '€${_costMetrics!['lifetime_value_guard']?.toStringAsFixed(0) ?? '0'}',
                    Icons.trending_up,
                    DesignTokens.revenueGreen,
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  _buildCostMetricCard(
                    context,
                    'Behoudpercentage',
                    '${_costMetrics!['retention_rate']?.toStringAsFixed(1) ?? '0'}%',
                    Icons.favorite,
                    DesignTokens.successGreen,
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  _buildCostMetricCard(
                    context,
                    'Wervingsefficiëntie',
                    '${_costMetrics!['recruitment_efficiency']?.toStringAsFixed(1) ?? '0'}%',
                    Icons.speed,
                    DesignTokens.analyticsBlue,
                  ),
                ],
              )
            else
              // Tablet and Desktop: 2x2 grid layout
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCostMetricCard(
                          context,
                          'Kosten per Aanwerving',
                          '€${_costMetrics!['cost_per_guard_hire']?.toStringAsFixed(2) ?? '0'}',
                          Icons.person_add,
                          DesignTokens.jobOrange,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingM),
                      Expanded(
                        child: _buildCostMetricCard(
                          context,
                          'Levensduurwaarde',
                          '€${_costMetrics!['lifetime_value_guard']?.toStringAsFixed(0) ?? '0'}',
                          Icons.trending_up,
                          DesignTokens.revenueGreen,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCostMetricCard(
                          context,
                          'Behoudpercentage',
                          '${_costMetrics!['retention_rate']?.toStringAsFixed(1) ?? '0'}%',
                          Icons.favorite,
                          DesignTokens.successGreen,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingM),
                      Expanded(
                        child: _buildCostMetricCard(
                          context,
                          'Wervingsefficiëntie',
                          '${_costMetrics!['recruitment_efficiency']?.toStringAsFixed(1) ?? '0'}%',
                          Icons.speed,
                          DesignTokens.analyticsBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildCostMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = context.screenWidth;
        final isMobile = screenWidth < 600;

        return UnifiedCard.standard(
          userRole: UserRole.company,
          padding: EdgeInsets.all(DesignTokens.spacingM),
          backgroundColor: color.withValues(alpha: 0.1),
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
                      size: isMobile
                          ? DesignTokens.iconSizeS
                          : DesignTokens.iconSizeM,
                      color: color,
                    ),
                    SizedBox(width: DesignTokens.spacingXS),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: DesignTokens.fontWeightMedium,
                          fontSize: isMobile ? 10 : 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightBold,
                      color: color,
                      fontSize: isMobile ? 14 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarketBenchmarksSection(BuildContext context) {
    if (_benchmarks == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = context.screenWidth;
        final isMobile = screenWidth < 600;

        return UnifiedCard.standard(
          userRole: UserRole.company,
          padding: EdgeInsets.all(DesignTokens.spacingM),
          backgroundColor: DesignTokens.companyTeal.withValues(alpha: 0.05),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: isMobile ? 120 : 140,
              maxWidth: constraints.maxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart,
                      color: DesignTokens.companyTeal,
                      size: isMobile
                          ? DesignTokens.iconSizeM
                          : DesignTokens.iconSizeL,
                    ),
                    SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        'Marktpositie & Benchmarks',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: DesignTokens.companyTeal,
                          fontSize: isMobile ? 12 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingM),
                _buildBenchmarkItem(
                  context,
                  'Marktpositie: ${_benchmarks!['market_position']}',
                  Icons.emoji_events,
                  isMobile,
                ),
                SizedBox(height: DesignTokens.spacingS),
                _buildBenchmarkItem(
                  context,
                  'Tarieven: ${_benchmarks!['rate_competitiveness']} (€${_benchmarks!['our_average_rate']} vs €${_benchmarks!['average_hourly_rate_market']})',
                  Icons.euro,
                  isMobile,
                ),
                SizedBox(height: DesignTokens.spacingS),
                _buildBenchmarkItem(
                  context,
                  'Groei: ${_benchmarks!['growth_vs_market']?.toStringAsFixed(1)}% boven marktgemiddelde',
                  Icons.trending_up,
                  isMobile,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenchmarkItem(
    BuildContext context,
    String benchmark,
    IconData icon,
    bool isMobile,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isMobile ? DesignTokens.iconSizeS : DesignTokens.iconSizeM,
          color: DesignTokens.companyTeal,
        ),
        SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Text(
            benchmark,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DesignTokens.darkText,
              fontSize: isMobile ? 10 : 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
