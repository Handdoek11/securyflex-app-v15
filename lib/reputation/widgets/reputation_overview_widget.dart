import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/unified_components.dart';
import '../models/reputation_data.dart';
import '../bloc/reputation_bloc.dart';

/// Reputation overview widget displaying comprehensive reputation metrics
/// 
/// Follows SecuryFlex UnifiedComponents design system
/// Provides role-based theming for guards and companies
/// Displays reputation score with trend indicators and key metrics
class ReputationOverviewWidget extends StatefulWidget {
  final String userId;
  final String userRole;
  final bool showDetailedMetrics;
  final bool showMilestones;
  final VoidCallback? onTap;
  
  const ReputationOverviewWidget({
    super.key,
    required this.userId,
    required this.userRole,
    this.showDetailedMetrics = true,
    this.showMilestones = true,
    this.onTap,
  });

  @override
  State<ReputationOverviewWidget> createState() => _ReputationOverviewWidgetState();
}

class _ReputationOverviewWidgetState extends State<ReputationOverviewWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scoreAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadReputationData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
  }

  void _loadReputationData() {
    context.read<ReputationBloc>().add(LoadReputation(widget.userId, widget.userRole));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReputationBloc, ReputationState>(
      listener: (context, state) {
        if (state is ReputationLoaded) {
          _animationController.forward();
        }
      },
      builder: (context, state) {
        if (state is ReputationLoaded) {
          return _buildReputationWidget(context, state.reputationData);
        } else if (state is ReputationError) {
          return _buildErrorWidget(context, state.error);
        }
        return _buildLoadingWidget(context);
      },
    );
  }

  Widget _buildReputationWidget(BuildContext context, ReputationData reputation) {
    final colorScheme = SecuryFlexTheme.getColorScheme(
      widget.userRole == 'guard' ? UserRole.guard : UserRole.company
    );

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.all(DesignTokens.spacingM),
          child: UnifiedCard.standard(
            backgroundColor: colorScheme.surfaceContainer,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, reputation, colorScheme),
                    SizedBox(height: DesignTokens.spacingL),
                    _buildScoreDisplay(context, reputation, colorScheme),
                    if (widget.showDetailedMetrics) ...[
                      SizedBox(height: DesignTokens.spacingL),
                      _buildMetricsGrid(context, reputation, colorScheme),
                    ],
                    if (widget.showMilestones && reputation.achievedMilestones.isNotEmpty) ...[
                      SizedBox(height: DesignTokens.spacingL),
                      _buildMilestones(context, reputation, colorScheme),
                    ],
                    SizedBox(height: DesignTokens.spacingM),
                    _buildFooter(context, reputation, colorScheme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reputatie Score',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Row(
              children: [
                Text(
                  reputation.reputationLevel.dutchTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: _getReputationLevelColor(reputation.reputationLevel),
                  ),
                ),
                SizedBox(width: DesignTokens.spacingS),
                _buildTrendIndicator(reputation.currentTrend, colorScheme),
              ],
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            widget.userRole == 'guard' ? Icons.security : Icons.business,
            color: colorScheme.primary,
            size: DesignTokens.iconSizeL,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AnimatedBuilder(
                    animation: _scoreAnimation,
                    builder: (context, child) {
                      final animatedScore = (reputation.overallScore * _scoreAnimation.value).round();
                      return Text(
                        '$animatedScore',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.fontWeightBold,
                          color: _getScoreColor(reputation.overallScore),
                          fontSize: 48,
                        ),
                      );
                    },
                  ),
                  Text(
                    '/100',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: DesignTokens.fontFamily,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingXS),
              Text(
                reputation.reputationLevel.dutchDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _buildScoreGauge(reputation.overallScore, colorScheme),
              if (reputation.monthlyScoreChange != 0) ...[
                SizedBox(height: DesignTokens.spacingS),
                _buildScoreChange(reputation.monthlyScoreChange, colorScheme),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreGauge(double score, ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: (score / 100) * _scoreAnimation.value,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
            strokeWidth: 6.0,
          ),
        );
      },
    );
  }

  Widget _buildScoreChange(double change, ColorScheme colorScheme) {
    final isPositive = change > 0;
    final changeColor = isPositive 
        ? DesignTokens.statusCompleted 
        : DesignTokens.colorError;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          color: changeColor,
          size: DesignTokens.iconSizeS,
        ),
        SizedBox(width: DesignTokens.spacingXS),
        Text(
          '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
            color: changeColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(ReputationTrend trend, ColorScheme colorScheme) {
    IconData icon;
    Color color;
    
    switch (trend) {
      case ReputationTrend.improving:
        icon = Icons.trending_up;
        color = DesignTokens.statusCompleted;
        break;
      case ReputationTrend.declining:
        icon = Icons.trending_down;
        color = DesignTokens.colorError;
        break;
      case ReputationTrend.stable:
        icon = Icons.trending_flat;
        color = colorScheme.primary;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingXS,
        vertical: DesignTokens.spacingXXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: DesignTokens.iconSizeXS),
          SizedBox(width: DesignTokens.spacingXXS),
          Text(
            trend.dutchDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              color: color,
              fontSize: DesignTokens.fontSizeCaption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    final metrics = [
      _MetricItem(
        icon: Icons.star_outline,
        label: 'Gem. beoordeling',
        value: reputation.jobCompletionRating.toStringAsFixed(1),
        color: _getRatingColor(reputation.jobCompletionRating),
      ),
      _MetricItem(
        icon: Icons.verified_outlined,
        label: 'Betrouwbaarheid',
        value: '${reputation.reliabilityScore.round()}%',
        color: _getReliabilityColor(reputation.reliabilityScore),
      ),
      _MetricItem(
        icon: Icons.work_outline,
        label: 'Voltooide jobs',
        value: reputation.totalJobsCompleted.toString(),
        color: colorScheme.primary,
      ),
      _MetricItem(
        icon: Icons.repeat,
        label: 'Herhalings %',
        value: '${reputation.repeatClientPercentage.round()}%',
        color: DesignTokens.guardPrimary,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: DesignTokens.spacingS,
      mainAxisSpacing: DesignTokens.spacingS,
      childAspectRatio: 2.8,
      children: metrics.map((metric) => _buildMetricCard(context, metric, colorScheme)).toList(),
    );
  }

  Widget _buildMetricCard(BuildContext context, _MetricItem metric, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                metric.icon,
                color: metric.color,
                size: DesignTokens.iconSizeS,
              ),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                metric.value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: metric.color,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingXXS),
          Text(
            metric.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurfaceVariant,
              fontSize: DesignTokens.fontSizeCaption,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    final recentMilestones = reputation.achievedMilestones.take(3).toList();
    
    if (recentMilestones.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent behaald',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        Wrap(
          spacing: DesignTokens.spacingS,
          runSpacing: DesignTokens.spacingS,
          children: recentMilestones.map((milestone) => _buildMilestoneChip(
            milestone, 
            colorScheme,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildMilestoneChip(ReputationMilestone milestone, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.statusCompleted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: DesignTokens.statusCompleted.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            color: DesignTokens.statusCompleted,
            size: DesignTokens.iconSizeXS,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            milestone.dutchTitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              color: DesignTokens.statusCompleted,
              fontSize: DesignTokens.fontSizeCaption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Laatst bijgewerkt: ${_formatLastUpdated(reputation.lastCalculated)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            color: colorScheme.onSurfaceVariant,
            fontSize: DesignTokens.fontSizeCaption,
          ),
        ),
        if (widget.onTap != null)
          Icon(
            Icons.arrow_forward_ios,
            color: colorScheme.onSurfaceVariant,
            size: DesignTokens.iconSizeXS,
          ),
      ],
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(
      widget.userRole == 'guard' ? UserRole.guard : UserRole.company
    );
    
    return Container(
      margin: EdgeInsets.all(DesignTokens.spacingM),
      child: UnifiedCard.standard(
        backgroundColor: colorScheme.surfaceContainer,
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            children: [
              Row(
                children: [
                  CircularProgressIndicator(
                    color: colorScheme.primary,
                    strokeWidth: 2.0,
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Text(
                    'Reputatie laden...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: DesignTokens.fontFamily,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingL),
              _buildLoadingPlaceholders(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholders(ColorScheme colorScheme) {
    return Column(
      children: [
        // Score placeholder
        Row(
          children: [
            Container(
              width: 120,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
            ),
            const Spacer(),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingL),
        // Metrics grid placeholder
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: DesignTokens.spacingS,
          mainAxisSpacing: DesignTokens.spacingS,
          childAspectRatio: 2.8,
          children: List.generate(4, (index) => Container(
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    final colorScheme = SecuryFlexTheme.getColorScheme(
      widget.userRole == 'guard' ? UserRole.guard : UserRole.company
    );

    return Container(
      margin: EdgeInsets.all(DesignTokens.spacingM),
      child: UnifiedCard.standard(
        backgroundColor: colorScheme.surfaceContainer,
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: DesignTokens.colorError,
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(height: DesignTokens.spacingM),
              Text(
                'Fout bij laden reputatie',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: DesignTokens.spacingS),
              Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: DesignTokens.spacingM),
              UnifiedButton.secondary(
                text: 'Opnieuw proberen',
                onPressed: _loadReputationData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Utility methods

  Color _getScoreColor(double score) {
    if (score >= 90) return DesignTokens.statusCompleted;
    if (score >= 80) return DesignTokens.statusPending;
    if (score >= 70) return DesignTokens.guardPrimary;
    if (score >= 60) return Colors.orange;
    return DesignTokens.colorError;
  }

  Color _getReputationLevelColor(ReputationLevel level) {
    switch (level) {
      case ReputationLevel.exceptional:
        return DesignTokens.statusCompleted;
      case ReputationLevel.excellent:
        return DesignTokens.statusPending;
      case ReputationLevel.good:
        return DesignTokens.guardPrimary;
      case ReputationLevel.average:
        return Colors.orange;
      case ReputationLevel.belowAverage:
      case ReputationLevel.poor:
        return DesignTokens.colorError;
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return DesignTokens.statusCompleted;
    if (rating >= 4.0) return DesignTokens.statusPending;
    if (rating >= 3.5) return DesignTokens.guardPrimary;
    return DesignTokens.colorError;
  }

  Color _getReliabilityColor(double reliability) {
    if (reliability >= 95) return DesignTokens.statusCompleted;
    if (reliability >= 85) return DesignTokens.statusPending;
    if (reliability >= 75) return DesignTokens.guardPrimary;
    return DesignTokens.colorError;
  }

  String _formatLastUpdated(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m geleden';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}u geleden';
    } else {
      return '${difference.inDays}d geleden';
    }
  }
}

/// Internal metric item for grid display
class _MetricItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}