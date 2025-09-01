import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/unified_components.dart';
import '../models/reputation_data.dart';
import '../bloc/reputation_bloc.dart';

/// Compact reputation score widget for integration with existing profile systems
/// 
/// Shows reputation score in a compact format suitable for:
/// - Profile headers and cards
/// - Job application displays
/// - Dashboard summaries
/// - List item overlays
/// 
/// Follows SecuryFlex UnifiedComponents design system
class ReputationScoreWidget extends StatefulWidget {
  final String userId;
  final String userRole;
  final ReputationScoreStyle style;
  final bool showTrendIndicator;
  final bool showLevelBadge;
  final bool isInteractive;
  final VoidCallback? onTap;
  
  const ReputationScoreWidget({
    super.key,
    required this.userId,
    required this.userRole,
    this.style = ReputationScoreStyle.standard,
    this.showTrendIndicator = true,
    this.showLevelBadge = true,
    this.isInteractive = false,
    this.onTap,
  });

  @override
  State<ReputationScoreWidget> createState() => _ReputationScoreWidgetState();
}

class _ReputationScoreWidgetState extends State<ReputationScoreWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
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
          return _buildScoreWidget(context, state.reputationData);
        } else if (state is ReputationError) {
          return _buildErrorWidget(context);
        }
        return _buildLoadingWidget(context);
      },
    );
  }

  Widget _buildScoreWidget(BuildContext context, ReputationData reputation) {
    final colorScheme = SecuryFlexTheme.getColorScheme(
      widget.userRole == 'guard' ? UserRole.guard : UserRole.company
    );

    Widget scoreContent = _buildScoreContent(context, reputation, colorScheme);

    if (widget.isInteractive && widget.onTap != null) {
      scoreContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(_getRadius()),
          child: scoreContent,
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: scoreContent,
      ),
    );
  }

  Widget _buildScoreContent(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    switch (widget.style) {
      case ReputationScoreStyle.compact:
        return _buildCompactScore(context, reputation, colorScheme);
      case ReputationScoreStyle.standard:
        return _buildStandardScore(context, reputation, colorScheme);
      case ReputationScoreStyle.detailed:
        return _buildDetailedScore(context, reputation, colorScheme);
      case ReputationScoreStyle.badge:
        return _buildBadgeScore(context, reputation, colorScheme);
      case ReputationScoreStyle.minimal:
        return _buildMinimalScore(context, reputation, colorScheme);
    }
  }

  Widget _buildCompactScore(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: _getScoreColor(reputation.overallScore).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: _getScoreColor(reputation.overallScore).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: _getScoreColor(reputation.overallScore),
            size: DesignTokens.iconSizeXS,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            '${reputation.overallScore.round()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightBold,
              color: _getScoreColor(reputation.overallScore),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardScore(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${reputation.overallScore.round()}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: _getScoreColor(reputation.overallScore),
                ),
              ),
              Text(
                '/100',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (widget.showTrendIndicator) ...[
                SizedBox(width: DesignTokens.spacingS),
                _buildTrendIcon(reputation.currentTrend),
              ],
            ],
          ),
          if (widget.showLevelBadge) ...[
            SizedBox(height: DesignTokens.spacingXS),
            _buildLevelBadge(reputation.reputationLevel, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedScore(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reputatie',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: DesignTokens.fontFamily,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${reputation.overallScore.round()}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.fontWeightBold,
                          color: _getScoreColor(reputation.overallScore),
                        ),
                      ),
                      Text(
                        '/100',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: DesignTokens.fontFamily,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.showTrendIndicator)
                _buildTrendIndicatorDetailed(reputation, colorScheme),
            ],
          ),
          if (widget.showLevelBadge) ...[
            SizedBox(height: DesignTokens.spacingS),
            Row(
              children: [
                _buildLevelBadge(reputation.reputationLevel, colorScheme),
                SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: LinearProgressIndicator(
                    value: reputation.overallScore / 100,
                    backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(reputation.overallScore)),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: DesignTokens.spacingS),
          Text(
            '${reputation.totalJobsCompleted} opdrachten • ${reputation.completionRate.round()}% voltooid',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeScore(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getScoreColor(reputation.overallScore),
            _getScoreColor(reputation.overallScore).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor(reputation.overallScore).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: DesignTokens.iconSizeS,
              ),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                '${reputation.overallScore.round()}/100',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (widget.showLevelBadge) ...[
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              reputation.reputationLevel.dutchTitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: DesignTokens.fontSizeCaption,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinimalScore(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getScoreColor(reputation.overallScore),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: DesignTokens.spacingXS),
        Text(
          '${reputation.overallScore.round()}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        if (widget.showTrendIndicator) ...[
          SizedBox(width: DesignTokens.spacingXS),
          Icon(
            _getTrendIconData(reputation.currentTrend),
            color: _getTrendColor(reputation.currentTrend),
            size: DesignTokens.iconSizeXS,
          ),
        ],
      ],
    );
  }

  Widget _buildTrendIcon(ReputationTrend trend) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingXXS),
      decoration: BoxDecoration(
        color: _getTrendColor(trend).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getTrendIconData(trend),
        color: _getTrendColor(trend),
        size: DesignTokens.iconSizeXS,
      ),
    );
  }

  Widget _buildTrendIndicatorDetailed(ReputationData reputation, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: _getTrendColor(reputation.currentTrend).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: _getTrendColor(reputation.currentTrend).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTrendIconData(reputation.currentTrend),
            color: _getTrendColor(reputation.currentTrend),
            size: DesignTokens.iconSizeXS,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            reputation.monthlyScoreChange > 0 
                ? '+${reputation.monthlyScoreChange.toStringAsFixed(1)}'
                : reputation.monthlyScoreChange.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              color: _getTrendColor(reputation.currentTrend),
              fontSize: DesignTokens.fontSizeCaption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(ReputationLevel level, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXXS,
      ),
      decoration: BoxDecoration(
        color: _getReputationLevelColor(level).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: _getReputationLevelColor(level).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        level.dutchTitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: DesignTokens.fontFamily,
          color: _getReputationLevelColor(level),
          fontSize: DesignTokens.fontSizeCaption,
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(
      widget.userRole == 'guard' ? UserRole.guard : UserRole.company
    );

    switch (widget.style) {
      case ReputationScoreStyle.compact:
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: DesignTokens.spacingXS,
          ),
          decoration: BoxDecoration(
            color: colorScheme.outline.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: DesignTokens.iconSizeXS,
                height: DesignTokens.iconSizeXS,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                '--',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      case ReputationScoreStyle.minimal:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(width: DesignTokens.spacingXS),
            Text(
              '--',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      default:
        return Container(
          padding: EdgeInsets.all(DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(_getRadius()),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              if (widget.style == ReputationScoreStyle.detailed) ...[
                SizedBox(height: DesignTokens.spacingS),
                Text(
                  'Laden...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }

  Widget _buildErrorWidget(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(
      widget.userRole == 'guard' ? UserRole.guard : UserRole.company
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: DesignTokens.colorError.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: DesignTokens.colorError,
            size: DesignTokens.iconSizeXS,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            'Fout',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              color: DesignTokens.colorError,
              fontSize: DesignTokens.fontSizeCaption,
            ),
          ),
        ],
      ),
    );
  }

  // Utility methods

  double _getRadius() {
    switch (widget.style) {
      case ReputationScoreStyle.compact:
      case ReputationScoreStyle.minimal:
        return DesignTokens.radiusS;
      case ReputationScoreStyle.standard:
        return DesignTokens.radiusM;
      case ReputationScoreStyle.detailed:
      case ReputationScoreStyle.badge:
        return DesignTokens.radiusL;
    }
  }

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

  Color _getTrendColor(ReputationTrend trend) {
    switch (trend) {
      case ReputationTrend.improving:
        return DesignTokens.statusCompleted;
      case ReputationTrend.declining:
        return DesignTokens.colorError;
      case ReputationTrend.stable:
        return DesignTokens.statusPending;
    }
  }

  IconData _getTrendIconData(ReputationTrend trend) {
    switch (trend) {
      case ReputationTrend.improving:
        return Icons.trending_up;
      case ReputationTrend.declining:
        return Icons.trending_down;
      case ReputationTrend.stable:
        return Icons.trending_flat;
    }
  }
}

/// Reputation score display styles
enum ReputationScoreStyle {
  /// Very compact display for tight spaces
  compact,
  
  /// Standard display with score and optional badges
  standard,
  
  /// Detailed display with metrics and progress
  detailed,
  
  /// Premium badge-style display
  badge,
  
  /// Minimal indicator for lists
  minimal,
}