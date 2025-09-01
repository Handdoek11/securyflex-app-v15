import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';

/// Modern, performance-optimized business intelligence widget
/// 
/// This replaces the legacy business_analytics_widget.dart with:
/// - Maximum 3 nesting levels (vs 5+ in legacy)
/// - Consolidated styling via UnifiedDashboardCard
/// - Clean metrics display
/// - Material 3 compliance
/// - Performance-first design
class ModernBusinessIntelligenceWidget extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final BusinessIntelligenceData? data;
  final VoidCallback? onViewDetails;

  const ModernBusinessIntelligenceWidget({
    super.key,
    this.animationController,
    this.animation,
    this.data,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final biData = data ?? BusinessIntelligenceData.mock();
    
    // Temporarily replace UnifiedDashboardCard with simple Container for debugging
    return Container(
      margin: EdgeInsets.all(DesignTokens.spacingM),
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: DesignTokens.statusConfirmed.withValues(alpha: 0.1),
        border: Border.all(color: DesignTokens.statusConfirmed, width: 2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Intelligence',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: DesignTokens.statusConfirmed,
            ),
          ),
          Text(
            'Prestatie overzicht deze maand',
            style: TextStyle(
              fontSize: 14,
              color: DesignTokens.statusConfirmed.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: DesignTokens.spacingL),

          // Key metrics row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    color: DesignTokens.statusAccepted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.euro, color: DesignTokens.statusAccepted, size: 24),
                      SizedBox(height: DesignTokens.spacingS),
                      Text(
                        biData.totalRevenue,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: DesignTokens.statusAccepted,
                        ),
                      ),
                      Text(
                        'Totale Omzet',
                        style: TextStyle(
                          fontSize: 12,
                          color: DesignTokens.statusAccepted.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.work, color: Colors.purple, size: 24),
                      SizedBox(height: DesignTokens.spacingS),
                      Text(
                        biData.activeJobs,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.purple,
                        ),
                      ),
                      Text(
                        'Actieve Opdrachten',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingM),

          // Secondary metrics row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.people, color: Colors.teal, size: 24),
                      SizedBox(height: DesignTokens.spacingS),
                      Text(
                        biData.totalGuards,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.teal,
                        ),
                      ),
                      Text(
                        'Beveiligers',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 24),
                      SizedBox(height: DesignTokens.spacingS),
                      Text(
                        biData.satisfaction,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.amber,
                        ),
                      ),
                      Text(
                        'Tevredenheid',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Column(
                children: [
                  // Key metrics row
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard(context, biData.totalRevenue, 'Totale Omzet', Icons.euro, MetricType.revenue)),
                      SizedBox(width: DesignTokens.spacingM),
                      Expanded(child: _buildMetricCard(context, biData.activeJobs, 'Actieve Opdrachten', Icons.work, MetricType.jobs)),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  // Secondary metrics row
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard(context, biData.totalGuards, 'Beveiligers', Icons.people, MetricType.guards)),
                      SizedBox(width: DesignTokens.spacingM),
                      Expanded(child: _buildMetricCard(context, biData.satisfaction, 'Tevredenheid', Icons.star, MetricType.satisfaction)),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingL),
                  // Growth indicator
                  _buildGrowthIndicator(context, biData),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String value, String label, IconData icon, MetricType type) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    final metricColor = _getMetricColor(type);
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: metricColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeM,
            color: metricColor,
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightBold,
              fontSize: DesignTokens.fontSizeBodyLarge,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: DesignTokens.fontSizeS,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthIndicator(BuildContext context, BusinessIntelligenceData data) {
    final isPositive = data.growthPercentage.startsWith('+');
    final growthColor = isPositive ? DesignTokens.colorSuccess : DesignTokens.colorError;
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: growthColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: growthColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: growthColor,
            size: DesignTokens.iconSizeM,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Text(
            '${data.growthPercentage} groei t.o.v. vorige maand',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontSize: DesignTokens.fontSizeBody,
              color: growthColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMetricColor(MetricType type) {
    switch (type) {
      case MetricType.revenue:
        return DesignTokens.colorSuccess;
      case MetricType.jobs:
        return DesignTokens.colorInfo;
      case MetricType.guards:
        return DesignTokens.colorWarning;
      case MetricType.satisfaction:
        return DesignTokens.colorSuccess;
    }
  }
}

/// Data model for business intelligence
class BusinessIntelligenceData {
  final String totalRevenue;
  final String activeJobs;
  final String totalGuards;
  final String satisfaction;
  final String growthPercentage;

  const BusinessIntelligenceData({
    required this.totalRevenue,
    required this.activeJobs,
    required this.totalGuards,
    required this.satisfaction,
    required this.growthPercentage,
  });

  /// Mock data for development and testing
  factory BusinessIntelligenceData.mock() {
    return const BusinessIntelligenceData(
      totalRevenue: '€45.280',
      activeJobs: '12',
      totalGuards: '28',
      satisfaction: '4.7 ⭐',
      growthPercentage: '+15%',
    );
  }

  /// Create from API response
  factory BusinessIntelligenceData.fromJson(Map<String, dynamic> json) {
    return BusinessIntelligenceData(
      totalRevenue: json['totalRevenue'] ?? '€0',
      activeJobs: json['activeJobs']?.toString() ?? '0',
      totalGuards: json['totalGuards']?.toString() ?? '0',
      satisfaction: json['satisfaction'] ?? '0.0 ⭐',
      growthPercentage: json['growthPercentage'] ?? '0%',
    );
  }
}

/// Metric type enumeration
enum MetricType {
  revenue,
  jobs,
  guards,
  satisfaction,
}
