import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/unified_components.dart';
import '../bloc/beveiliger_profiel_bloc.dart';
import '../models/profile_stats_data.dart';
import '../../reputation/widgets/reputation_score_widget.dart';
import '../../reputation/bloc/reputation_bloc.dart';

/// Profile statistics widget with performance analytics integration
/// 
/// Shows key profile metrics integrated with existing dashboard analytics
/// Uses PerformanceAnalyticsService for data consistency
/// Follows SecuryFlex unified design system patterns
class ProfileStatsWidget extends StatefulWidget {
  final String userId;
  final String userRole;
  final bool showDetailedStats;
  final bool showReputationIntegration;
  final VoidCallback? onStatsTap;
  final VoidCallback? onReputationTap;
  
  const ProfileStatsWidget({
    super.key,
    required this.userId,
    required this.userRole,
    this.showDetailedStats = false,
    this.showReputationIntegration = true,
    this.onStatsTap,
    this.onReputationTap,
  });

  @override
  State<ProfileStatsWidget> createState() => _ProfileStatsWidgetState();
}

class _ProfileStatsWidgetState extends State<ProfileStatsWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProfileStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  void _loadProfileStats() {
    context.read<BeveiligerProfielBloc>().add(LoadProfileStats(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BeveiligerProfielBloc, BeveiligerProfielState>(
      builder: (context, state) {
        if (state is BeveiligerProfielLoaded && state.profileStatsData != null) {
          return _buildStatsWidget(context, state.profileStatsData!);
        }
        return _buildLoadingWidget(context);
      },
    );
  }

  Widget _buildStatsWidget(BuildContext context, ProfileStatsData statsData) {
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
              onTap: widget.onStatsTap,
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, statsData, colorScheme),
                    if (widget.showReputationIntegration) ...[
                      SizedBox(height: DesignTokens.spacingM),
                      _buildReputationIntegration(context, colorScheme),
                    ],
                    SizedBox(height: DesignTokens.spacingM),
                    _buildStatsGrid(context, statsData, colorScheme),
                    if (widget.showDetailedStats) ...[
                      SizedBox(height: DesignTokens.spacingL),
                      _buildDetailedStats(context, statsData, colorScheme),
                    ],
                    SizedBox(height: DesignTokens.spacingM),
                    _buildLastUpdated(context, statsData, colorScheme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
                    'Statistieken laden...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: DesignTokens.fontFamily,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingM),
              _buildLoadingGrid(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid(BuildContext context, ColorScheme colorScheme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: DesignTokens.spacingS,
      mainAxisSpacing: DesignTokens.spacingS,
      childAspectRatio: 2.5,
      children: List.generate(4, (index) =>
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 12,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
              ),
              SizedBox(height: DesignTokens.spacingS),
              Container(
                width: 60,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProfileStatsData statsData, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profiel statistieken',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              'Lid sinds ${_formatMemberSince(statsData.memberSinceDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: DesignTokens.spacingXS,
          ),
          decoration: BoxDecoration(
            color: _getRatingColor(statsData.averageRating).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                color: _getRatingColor(statsData.averageRating),
                size: DesignTokens.iconSizeS,
              ),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                statsData.averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: _getRatingColor(statsData.averageRating),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, ProfileStatsData statsData, ColorScheme colorScheme) {
    final stats = [
      StatItem(
        icon: Icons.work_outline,
        value: statsData.totalJobsCompleted.toString(),
        label: 'Opdrachten voltooid',
        color: DesignTokens.statusCompleted,
      ),
      StatItem(
        icon: Icons.schedule_outlined,
        value: '${statsData.totalHoursWorked.round()}u',
        label: 'Uren gewerkt',
        color: colorScheme.primary,
      ),
      StatItem(
        icon: Icons.verified_outlined,
        value: statsData.certificatesCount.toString(),
        label: 'Certificaten',
        color: DesignTokens.guardPrimary,
      ),
      StatItem(
        icon: Icons.trending_up_outlined,
        value: '${statsData.completionRate.round()}%',
        label: 'Voltooiingspercentage',
        color: _getCompletionRateColor(statsData.completionRate),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: DesignTokens.spacingS,
      mainAxisSpacing: DesignTokens.spacingS,
      childAspectRatio: 2.5,
      children: stats.map((stat) => _buildStatCard(context, stat, colorScheme)).toList(),
    );
  }

  Widget _buildStatCard(BuildContext context, StatItem stat, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
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
                stat.icon,
                color: stat.color,
                size: DesignTokens.iconSizeS,
              ),
              SizedBox(width: DesignTokens.spacingXS),
              Flexible(
                child: Text(
                  stat.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: stat.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            stat.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(BuildContext context, ProfileStatsData statsData, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gedetailleerde statistieken',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        _buildDetailedStatRow(
          context, 
          'Gemiddeld uurloon', 
          '€${statsData.averageHourlyRate.toStringAsFixed(2)}', 
          colorScheme,
        ),
        _buildDetailedStatRow(
          context, 
          'Deze maand verdiend', 
          '€${statsData.monthlyEarnings.toStringAsFixed(2)}', 
          colorScheme,
        ),
        _buildDetailedStatRow(
          context, 
          'Actieve specialisaties', 
          statsData.activeSpecializations.toString(), 
          colorScheme,
        ),
        _buildDetailedStatRow(
          context, 
          'Herhaalopdrachten', 
          '${statsData.repeatJobPercentage.round()}%', 
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildDetailedStatRow(BuildContext context, String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReputationIntegration(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: colorScheme.primary,
                    size: DesignTokens.iconSizeS,
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Text(
                    'Reputatie Score',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (widget.onReputationTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.onSurfaceVariant,
                  size: DesignTokens.iconSizeXS,
                ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          InkWell(
            onTap: widget.onReputationTap,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            child: BlocProvider(
              create: (context) => ReputationBloc(),
              child: ReputationScoreWidget(
                userId: widget.userId,
                userRole: widget.userRole,
                style: ReputationScoreStyle.detailed,
                showTrendIndicator: true,
                showLevelBadge: true,
                isInteractive: widget.onReputationTap != null,
                onTap: widget.onReputationTap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(BuildContext context, ProfileStatsData statsData, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.refresh,
          color: colorScheme.onSurfaceVariant,
          size: DesignTokens.iconSizeXS,
        ),
        SizedBox(width: DesignTokens.spacingXS),
        Text(
          'Laatst bijgewerkt: ${_formatLastUpdated(statsData.lastUpdated)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            color: colorScheme.onSurfaceVariant,
            fontSize: DesignTokens.fontSizeCaption,
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return DesignTokens.statusCompleted;
    if (rating >= 4.0) return DesignTokens.statusPending;
    if (rating >= 3.5) return DesignTokens.guardPrimary;
    return DesignTokens.colorError;
  }

  Color _getCompletionRateColor(double rate) {
    if (rate >= 90) return DesignTokens.statusCompleted;
    if (rate >= 80) return DesignTokens.statusPending;
    if (rate >= 70) return DesignTokens.guardPrimary;
    return DesignTokens.colorError;
  }

  String _formatMemberSince(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '$years jaar';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '$months maanden';
    } else {
      return '${difference.inDays} dagen';
    }
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

/// Stat item for grid display
class StatItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  
  const StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}