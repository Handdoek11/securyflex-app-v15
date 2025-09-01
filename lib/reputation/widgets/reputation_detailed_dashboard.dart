import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/unified_components.dart';
import '../models/reputation_data.dart';
import '../bloc/reputation_bloc.dart';

/// Detailed reputation dashboard showing comprehensive metrics and insights
/// 
/// Provides in-depth analysis of reputation components
/// Includes trend analysis, performance breakdown, and improvement suggestions
/// Follows SecuryFlex UnifiedComponents design system
class ReputationDetailedDashboard extends StatefulWidget {
  final String userId;
  final String userRole;
  
  const ReputationDetailedDashboard({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<ReputationDetailedDashboard> createState() => _ReputationDetailedDashboardState();
}

class _ReputationDetailedDashboardState extends State<ReputationDetailedDashboard>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _animationController;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAnimations();
    _loadReputationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _barAnimations = List.generate(5, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          0.5 + (index * 0.1),
          curve: Curves.easeOutCubic,
        ),
      ));
    });
  }

  void _loadReputationData() {
    context.read<ReputationBloc>().add(LoadReputation(widget.userId, widget.userRole));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(
      widget.userRole == 'guard' ? UserRole.guard : UserRole.company
    );

    return BlocConsumer<ReputationBloc, ReputationState>(
      listener: (context, state) {
        if (state is ReputationLoaded) {
          _animationController.forward();
        }
      },
      builder: (context, state) {
        if (state is ReputationLoaded) {
          return _buildDashboard(context, state.reputationData, colorScheme);
        } else if (state is ReputationError) {
          return _buildErrorWidget(context, state.error, colorScheme);
        }
        return _buildLoadingWidget(context, colorScheme);
      },
    );
  }

  Widget _buildDashboard(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildTabBar(colorScheme),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, reputation, colorScheme),
              _buildMetricsTab(context, reputation, colorScheme),
              _buildImprovementTab(context, reputation, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.all(DesignTokens.spacingM),
      child: UnifiedCard.standard(
        backgroundColor: colorScheme.surfaceContainer,
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          labelStyle: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
          tabs: const [
            Tab(text: 'Overzicht'),
            Tab(text: 'Metrics'),
            Tab(text: 'Verbeteren'),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScoreBreakdown(context, reputation, colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildTrendAnalysis(context, reputation, colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildComplianceStatus(context, reputation, colorScheme),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    final breakdownItems = [
      _BreakdownItem(
        title: 'Opdracht voltooiing',
        score: reputation.jobCompletionRating,
        maxScore: 5.0,
        weight: 25,
        color: DesignTokens.statusCompleted,
      ),
      _BreakdownItem(
        title: 'Betrouwbaarheid',
        score: reputation.reliabilityScore,
        maxScore: 100.0,
        weight: 20,
        color: DesignTokens.statusPending,
      ),
      _BreakdownItem(
        title: 'Klantfeedback',
        score: reputation.clientFeedbackScore,
        maxScore: 100.0,
        weight: 20,
        color: DesignTokens.guardPrimary,
      ),
      _BreakdownItem(
        title: 'Compliance',
        score: reputation.complianceScore,
        maxScore: 100.0,
        weight: 15,
        color: Colors.purple,
      ),
      _BreakdownItem(
        title: 'Ervaring',
        score: (reputation.experienceMultiplier - 1.0) * 100,
        maxScore: 35.0,
        weight: 20,
        color: Colors.orange,
      ),
    ];

    return UnifiedCard.standard(
      backgroundColor: colorScheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score samenstelling',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            ...breakdownItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
                child: _buildBreakdownBar(context, item, _barAnimations[index], colorScheme),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownBar(BuildContext context, _BreakdownItem item, Animation<double> animation, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${item.title} (${item.weight}%)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightMedium,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              '${(item.score / item.maxScore * 100).round()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightBold,
                color: item.color,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingS),
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: (item.score / item.maxScore) * animation.value,
              backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
              minHeight: 8,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    return UnifiedCard.standard(
      backgroundColor: colorScheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Trend analyse',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            _buildTrendCard(
              'Deze maand',
              reputation.monthlyScoreChange,
              reputation.currentTrend.dutchDescription,
              colorScheme,
            ),
            SizedBox(height: DesignTokens.spacingS),
            _buildTrendCard(
              'Dit kwartaal',
              reputation.quarterlyScoreChange,
              reputation.currentTrend.dutchAdvice,
              colorScheme,
            ),
            SizedBox(height: DesignTokens.spacingM),
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: _getTrendColor(reputation.currentTrend).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: _getTrendColor(reputation.currentTrend).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getTrendIcon(reputation.currentTrend),
                    color: _getTrendColor(reputation.currentTrend),
                    size: DesignTokens.iconSizeS,
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      reputation.currentTrend.dutchAdvice,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: DesignTokens.fontFamily,
                        color: _getTrendColor(reputation.currentTrend),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(String period, double change, String description, ColorScheme colorScheme) {
    final isPositive = change > 0;
    final changeColor = isPositive 
        ? DesignTokens.statusCompleted 
        : change < 0 
            ? DesignTokens.colorError 
            : colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                period,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : change < 0 ? Icons.trending_down : Icons.trending_flat,
                color: changeColor,
                size: DesignTokens.iconSizeS,
              ),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: changeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceStatus(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    final complianceItems = [
      _ComplianceItem(
        title: 'WPBR Certificering',
        isCompliant: reputation.wpbrCertified,
        description: reputation.wpbrCertified ? 'Geldig certificaat' : 'Certificaat vereist',
        isApplicable: widget.userRole == 'guard',
      ),
      _ComplianceItem(
        title: 'KvK Verificatie',
        isCompliant: reputation.kvkVerified,
        description: reputation.kvkVerified ? 'Geverifieerd bedrijf' : 'Verificatie vereist',
        isApplicable: widget.userRole == 'company',
      ),
      _ComplianceItem(
        title: 'CAO Naleving',
        isCompliant: reputation.isReliableByCAOStandards,
        description: reputation.isReliableByCAOStandards 
            ? 'Voldoet aan CAO normen' 
            : 'Verbetering nodig',
        isApplicable: true,
      ),
      _ComplianceItem(
        title: 'Geen overtredingen',
        isCompliant: reputation.complianceViolationCount == 0,
        description: reputation.complianceViolationCount == 0
            ? 'Schone staat van dienst'
            : '${reputation.complianceViolationCount} overtredingen',
        isApplicable: true,
      ),
    ];

    final applicableItems = complianceItems.where((item) => item.isApplicable).toList();

    return UnifiedCard.standard(
      backgroundColor: colorScheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Compliance status',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            ...applicableItems.map((item) => _buildComplianceItem(context, item, colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceItem(BuildContext context, _ComplianceItem item, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingXS),
            decoration: BoxDecoration(
              color: (item.isCompliant ? DesignTokens.statusCompleted : DesignTokens.colorError)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Icon(
              item.isCompliant ? Icons.check_circle : Icons.error,
              color: item.isCompliant ? DesignTokens.statusCompleted : DesignTokens.colorError,
              size: DesignTokens.iconSizeS,
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsTab(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        children: [
          _buildPerformanceMetrics(context, reputation, colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildSpecializationMetrics(context, reputation, colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildMilestoneProgress(context, reputation, colorScheme),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    final metrics = [
      ['Totale jobs', reputation.totalJobsCompleted.toString()],
      ['Voltooiingspercentage', '${reputation.completionRate.toStringAsFixed(1)}%'],
      ['Gemiddelde responstijd', '${reputation.averageResponseTime.toStringAsFixed(1)}u'],
      ['Positieve reviews', '${reputation.positiveReviewPercentage.toStringAsFixed(1)}%'],
      ['Herhalende klanten', '${reputation.repeatClientPercentage.toStringAsFixed(1)}%'],
      ['Jaren ervaring', reputation.yearsOfExperience.toStringAsFixed(1)],
    ];

    return UnifiedCard.standard(
      backgroundColor: colorScheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prestatiemetrics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: DesignTokens.spacingM,
              mainAxisSpacing: DesignTokens.spacingM,
              childAspectRatio: 2.5,
              children: metrics.map((metric) => _buildMetricTile(
                context,
                metric[0],
                metric[1],
                colorScheme,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, String label, String value, ColorScheme colorScheme) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationMetrics(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    if (reputation.specializationScores.isEmpty) {
      return const SizedBox.shrink();
    }

    return UnifiedCard.standard(
      backgroundColor: colorScheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specialisatie scores',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            ...reputation.specializationScores.entries.map((entry) {
              final isTop = entry.key == reputation.topSpecialization;
              return _buildSpecializationBar(context, entry.key, entry.value, isTop, colorScheme);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecializationBar(BuildContext context, String specialization, double score, bool isTop, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    specialization,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (isTop) ...[
                    SizedBox(width: DesignTokens.spacingS),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingXS,
                        vertical: DesignTokens.spacingXXS,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.statusCompleted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Text(
                        'TOP',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: DesignTokens.fontFamily,
                          color: DesignTokens.statusCompleted,
                          fontSize: DesignTokens.fontSizeCaption,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '${(score / 5.0 * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          LinearProgressIndicator(
            value: score / 5.0,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isTop ? DesignTokens.statusCompleted : colorScheme.primary,
            ),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneProgress(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    final allMilestones = ReputationMilestone.values;
    final nextMilestone = reputation.nextMilestone;

    return UnifiedCard.standard(
      backgroundColor: colorScheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Mijlpalen (${reputation.achievedMilestones.length}/${allMilestones.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            if (nextMilestone != null) ...[
              Container(
                padding: EdgeInsets.all(DesignTokens.spacingM),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag,
                      color: colorScheme.primary,
                      size: DesignTokens.iconSizeS,
                    ),
                    SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Volgende mijlpaal: ${nextMilestone.dutchTitle}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: DesignTokens.fontFamily,
                              fontWeight: DesignTokens.fontWeightMedium,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            nextMilestone.dutchDescription,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: DesignTokens.fontFamily,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: DesignTokens.spacingM),
            ],
            Wrap(
              spacing: DesignTokens.spacingS,
              runSpacing: DesignTokens.spacingS,
              children: allMilestones.map((milestone) {
                final isAchieved = reputation.achievedMilestones.contains(milestone);
                return _buildMilestoneChip(milestone, isAchieved, colorScheme);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneChip(ReputationMilestone milestone, bool isAchieved, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: isAchieved 
            ? DesignTokens.statusCompleted.withValues(alpha: 0.1)
            : colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: isAchieved 
              ? DesignTokens.statusCompleted.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAchieved ? Icons.emoji_events : Icons.emoji_events_outlined,
            color: isAchieved ? DesignTokens.statusCompleted : colorScheme.onSurfaceVariant,
            size: DesignTokens.iconSizeXS,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            milestone.dutchTitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              color: isAchieved ? DesignTokens.statusCompleted : colorScheme.onSurfaceVariant,
              fontSize: DesignTokens.fontSizeCaption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementTab(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        children: [
          _buildImprovementSuggestions(context, reputation, colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildGoalSetting(context, reputation, colorScheme),
        ],
      ),
    );
  }

  Widget _buildImprovementSuggestions(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    final suggestions = _generateImprovementSuggestions(reputation);

    return UnifiedCard.standard(
      backgroundColor: colorScheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Verbetertips',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            ...suggestions.map((suggestion) => _buildSuggestionCard(context, suggestion, colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(BuildContext context, _ImprovementSuggestion suggestion, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingM),
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingXS),
            decoration: BoxDecoration(
              color: suggestion.priority.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Icon(
              suggestion.icon,
              color: suggestion.priority.color,
              size: DesignTokens.iconSizeS,
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      suggestion.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(width: DesignTokens.spacingS),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingXS,
                        vertical: DesignTokens.spacingXXS,
                      ),
                      decoration: BoxDecoration(
                        color: suggestion.priority.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Text(
                        suggestion.priority.dutchLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: DesignTokens.fontFamily,
                          color: suggestion.priority.color,
                          fontSize: DesignTokens.fontSizeCaption,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingS),
                Text(
                  suggestion.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSetting(BuildContext context, ReputationData reputation, ColorScheme colorScheme) {
    final currentScore = reputation.overallScore.round();
    final nextTier = _getNextScoreTier(currentScore);

    return UnifiedCard.standard(
      backgroundColor: colorScheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Doelen stellen',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.1),
                    colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Volgende niveau: ${nextTier.level.dutchTitle}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Text(
                    'Nog ${nextTier.pointsNeeded} punten nodig',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: DesignTokens.fontFamily,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  LinearProgressIndicator(
                    value: currentScore / nextTier.targetScore,
                    backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    minHeight: 8,
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Text(
                    '$currentScore / ${nextTier.targetScore} punten',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: DesignTokens.fontFamily,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context, ColorScheme colorScheme) {
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: DesignTokens.colorError,
            size: DesignTokens.iconSizeXL,
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'Fout bij laden dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spacingL),
          UnifiedButton.primary(
            text: 'Opnieuw proberen',
            onPressed: _loadReputationData,
          ),
        ],
      ),
    );
  }

  // Utility methods

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

  IconData _getTrendIcon(ReputationTrend trend) {
    switch (trend) {
      case ReputationTrend.improving:
        return Icons.trending_up;
      case ReputationTrend.declining:
        return Icons.trending_down;
      case ReputationTrend.stable:
        return Icons.trending_flat;
    }
  }

  List<_ImprovementSuggestion> _generateImprovementSuggestions(ReputationData reputation) {
    final suggestions = <_ImprovementSuggestion>[];

    if (reputation.jobCompletionRating < 4.0) {
      suggestions.add(_ImprovementSuggestion(
        title: 'Verbeter klantbeoordeling',
        description: 'Focus op uitstekende service om hogere beoordelingen te krijgen',
        icon: Icons.star_outline,
        priority: _ImprovementPriority.high,
      ));
    }

    if (reputation.reliabilityScore < 90) {
      suggestions.add(_ImprovementSuggestion(
        title: 'Verhoog betrouwbaarheid',
        description: 'Kom altijd op tijd en zeg opdrachten niet af zonder geldige reden',
        icon: Icons.schedule,
        priority: _ImprovementPriority.high,
      ));
    }

    if (!reputation.wpbrCertified && widget.userRole == 'guard') {
      suggestions.add(_ImprovementSuggestion(
        title: 'Behaal WPBR certificering',
        description: 'WPBR certificering is verplicht voor premium opdrachten',
        icon: Icons.verified,
        priority: _ImprovementPriority.critical,
      ));
    }

    if (reputation.repeatClientPercentage < 30) {
      suggestions.add(_ImprovementSuggestion(
        title: 'Bouw klantrelaties op',
        description: 'Focus op het opbouwen van langetermijn relaties met klanten',
        icon: Icons.people,
        priority: _ImprovementPriority.medium,
      ));
    }

    if (reputation.averageResponseTime > 24) {
      suggestions.add(_ImprovementSuggestion(
        title: 'Reageer sneller op opdrachten',
        description: 'Probeer binnen 12 uur te reageren op nieuwe opdrachten',
        icon: Icons.speed,
        priority: _ImprovementPriority.medium,
      ));
    }

    return suggestions;
  }

  _ScoreTier _getNextScoreTier(int currentScore) {
    final tiers = [
      _ScoreTier(ReputationLevel.average, 60),
      _ScoreTier(ReputationLevel.good, 70),
      _ScoreTier(ReputationLevel.excellent, 80),
      _ScoreTier(ReputationLevel.exceptional, 90),
    ];

    for (final tier in tiers) {
      if (currentScore < tier.targetScore) {
        return _ScoreTier(tier.level, tier.targetScore, tier.targetScore - currentScore);
      }
    }

    return _ScoreTier(ReputationLevel.exceptional, 100, 0);
  }
}

// Helper classes

class _BreakdownItem {
  final String title;
  final double score;
  final double maxScore;
  final int weight;
  final Color color;

  _BreakdownItem({
    required this.title,
    required this.score,
    required this.maxScore,
    required this.weight,
    required this.color,
  });
}

class _ComplianceItem {
  final String title;
  final bool isCompliant;
  final String description;
  final bool isApplicable;

  _ComplianceItem({
    required this.title,
    required this.isCompliant,
    required this.description,
    required this.isApplicable,
  });
}

class _ImprovementSuggestion {
  final String title;
  final String description;
  final IconData icon;
  final _ImprovementPriority priority;

  _ImprovementSuggestion({
    required this.title,
    required this.description,
    required this.icon,
    required this.priority,
  });
}

enum _ImprovementPriority {
  low,
  medium,
  high,
  critical;

  String get dutchLabel {
    switch (this) {
      case _ImprovementPriority.low:
        return 'Laag';
      case _ImprovementPriority.medium:
        return 'Gemiddeld';
      case _ImprovementPriority.high:
        return 'Hoog';
      case _ImprovementPriority.critical:
        return 'Kritiek';
    }
  }

  Color get color {
    switch (this) {
      case _ImprovementPriority.low:
        return Colors.grey;
      case _ImprovementPriority.medium:
        return Colors.orange;
      case _ImprovementPriority.high:
        return Colors.red;
      case _ImprovementPriority.critical:
        return const Color(0xFF8B0000); // Dark red
    }
  }
}

class _ScoreTier {
  final ReputationLevel level;
  final int targetScore;
  final int pointsNeeded;

  _ScoreTier(this.level, this.targetScore, [this.pointsNeeded = 0]);
}