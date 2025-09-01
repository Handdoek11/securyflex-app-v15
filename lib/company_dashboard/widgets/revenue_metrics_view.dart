import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_card_system.dart';

import 'package:securyflex_app/unified_status_colors.dart';
import 'package:securyflex_app/company_dashboard/services/company_service.dart';
import 'package:securyflex_app/company_dashboard/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Revenue metrics widget for Company dashboard
/// Following EarningsCardWidget pattern with Company financial metrics
class RevenueMetricsView extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;

  const RevenueMetricsView({
    super.key,
    this.animationController,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    final currencyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    
    Widget content = Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: FutureBuilder<Map<String, dynamic>>(
        future: CompanyService.instance.getCompanyMetrics(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Padding(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              child: Column(
                          children: [
                            // Main metric skeleton
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SkeletonLoader.text(width: 150, userRole: UserRole.company),
                                      SizedBox(height: DesignTokens.spacingXS),
                                      SkeletonLoader.text(width: 100, height: 32, userRole: UserRole.company),
                                    ],
                                  ),
                                ),
                                SkeletonLoader.circle(size: DesignTokens.iconSizeXL, userRole: UserRole.company),
                              ],
                            ),
                            SizedBox(height: DesignTokens.spacingM),
                            // Metrics row skeleton
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      SkeletonLoader.text(width: 60, height: 20, userRole: UserRole.company),
                                      SizedBox(height: DesignTokens.spacingXS),
                                      SkeletonLoader.text(width: 80, height: 12, userRole: UserRole.company),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      SkeletonLoader.text(width: 40, height: 20, userRole: UserRole.company),
                                      SizedBox(height: DesignTokens.spacingXS),
                                      SkeletonLoader.text(width: 90, height: 12, userRole: UserRole.company),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      SkeletonLoader.text(width: 30, height: 20, userRole: UserRole.company),
                                      SizedBox(height: DesignTokens.spacingXS),
                                      SkeletonLoader.text(width: 70, height: 12, userRole: UserRole.company),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                ],
              ),
            );
          }
          
          final metrics = snapshot.data!;
                    
          return Column(
                      children: <Widget>[
                        // Header with main metric
                        Padding(
                          padding: EdgeInsets.only(
                            left: DesignTokens.spacingL,
                            right: DesignTokens.spacingL,
                            top: DesignTokens.spacingL,
                            bottom: DesignTokens.spacingM,
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Maandelijkse Uitgaven',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: companyColors.onSurfaceVariant,
                                        fontWeight: DesignTokens.fontWeightMedium,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: DesignTokens.spacingXS),
                                      child: Text(
                                        currencyFormat.format(metrics['monthlySpent']),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: companyColors.primary,
                                          fontWeight: DesignTokens.fontWeightBold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  focusColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  splashColor: companyColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                                  onTap: () {
                                    // TODO: Navigate to financial details
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(DesignTokens.spacingXS),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      color: companyColors.primary,
                                      size: DesignTokens.iconSizeS,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        
                        // Metrics grid
                        Padding(
                          padding: EdgeInsets.only(
                            left: DesignTokens.spacingL,
                            right: DesignTokens.spacingL,
                            top: DesignTokens.spacingXS,
                            bottom: DesignTokens.spacingM,
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      '${metrics['activeJobs']} jobs',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: companyColors.onSurface,
                                        fontWeight: DesignTokens.fontWeightSemiBold,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: DesignTokens.spacingXS),
                                      child: Text(
                                        'Actieve Jobs',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: companyColors.onSurfaceVariant,
                                          fontWeight: DesignTokens.fontWeightMedium,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      '${metrics['pendingApplications']}',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: StatusColorHelper.getGenericStatusColor('wachtend'),
                                        fontWeight: DesignTokens.fontWeightSemiBold,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: DesignTokens.spacingXS),
                                      child: Text(
                                        'Te Beoordelen',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: companyColors.onSurfaceVariant,
                                          fontWeight: DesignTokens.fontWeightMedium,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      '${metrics['totalGuardsHired']}',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: StatusColorHelper.getGenericStatusColor('voltooid'),
                                        fontWeight: DesignTokens.fontWeightSemiBold,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: DesignTokens.spacingXS),
                                      child: Text(
                                        'Beveiligers',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: companyColors.onSurfaceVariant,
                                          fontWeight: DesignTokens.fontWeightMedium,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Performance indicator
                        Padding(
                          padding: EdgeInsets.only(
                            left: DesignTokens.spacingM,
                            right: DesignTokens.spacingM,
                            bottom: DesignTokens.spacingM,
                          ),
                          child: UnifiedCard.standard(
                            userRole: UserRole.company,
                            padding: EdgeInsets.all(DesignTokens.spacingM),
                            backgroundColor: companyColors.primaryContainer,
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.trending_up,
                                color: companyColors.onPrimaryContainer,
                                size: DesignTokens.iconSizeM,
                              ),
                              SizedBox(width: DesignTokens.spacingS + DesignTokens.spacingXS), // 12px
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Bedrijfsprestaties',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: companyColors.onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Rating: ${metrics['companyRating'].toStringAsFixed(1)}/5.0 • ${metrics['repeatHireRate'].toStringAsFixed(0)}% herhalingen',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: companyColors.onPrimaryContainer.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
            ],
          );
        },
      ),
    );
    
    // Wrap with animations if provided
    if (animationController != null && animation != null) {
      return AnimatedBuilder(
        animation: animationController!,
        builder: (BuildContext context, Widget? child) {
          return FadeTransition(
            opacity: animation!,
            child: Transform(
              transform: Matrix4.translationValues(
                  0.0, 30 * (1.0 - animation!.value), 0.0),
              child: content,
            ),
          );
        },
      );
    }
    
    return content;
  }
}
