import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';
import 'package:securyflex_app/company_dashboard/services/job_posting_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Posted jobs overview widget for Company job management
/// Shows all jobs posted by the company with management actions
class PostedJobsOverview extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;

  const PostedJobsOverview({
    super.key,
    this.animationController,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 30 * (1.0 - animation!.value), 0.0),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 24, right: 24, top: 16, bottom: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: companyColors.surface,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: companyColors.shadow.withValues(alpha: 0.2),
                        offset: const Offset(1.1, 1.1),
                        blurRadius: 10.0),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    // Header
                    Padding(
                      padding: EdgeInsets.all(DesignTokens.spacingL),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.work_history,
                            color: companyColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Geplaatste Jobs',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: companyColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          UnifiedButton(
                            text: 'Nieuwe Job',
                            onPressed: () {
                              // TODO: Navigate to job posting form
                            },
                            type: UnifiedButtonType.text,
                            size: UnifiedButtonSize.small,
                            icon: Icons.add,
                          ),
                        ],
                      ),
                    ),
                    
                    // Jobs list
                    FutureBuilder<List<JobPostingData>>(
                      future: JobPostingService.instance.getCompanyJobs('COMP001'),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(DesignTokens.spacingL),
                            child: CircularProgressIndicator(),
                          );
                        }
                        
                        final jobs = snapshot.data!;
                        
                        if (jobs.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.all(DesignTokens.spacingL),
                            child: Column(
                              children: <Widget>[
                                Icon(
                                  Icons.work_off,
                                  color: companyColors.onSurfaceVariant,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Nog geen jobs geplaatst',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: companyColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                UnifiedButton(
                                  text: 'Plaats Eerste Job',
                                  onPressed: () {
                                    // TODO: Navigate to job posting form
                                  },
                                  type: UnifiedButtonType.primary,
                                  size: UnifiedButtonSize.medium,
                                  icon: Icons.add,
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return Column(
                          children: jobs.map((job) => _buildJobCard(context, job)).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobCard(BuildContext context, JobPostingData job) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    final currencyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    
    return UnifiedCard.standard(
      userRole: UserRole.company,
      margin: EdgeInsets.only(
        left: DesignTokens.spacingL,
        right: DesignTokens.spacingL,
        bottom: DesignTokens.spacingM,
      ),
      padding: EdgeInsets.all(DesignTokens.spacingM),
      backgroundColor: companyColors.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Job header
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: companyColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.jobType.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: companyColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: job.status.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  job.status.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: job.status.statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Job metrics
          Row(
            children: <Widget>[
              Icon(
                Icons.location_on,
                color: companyColors.onSurfaceVariant,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                job.location,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: companyColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.euro,
                color: companyColors.onSurfaceVariant,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '${currencyFormat.format(job.hourlyRate)}/u',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: companyColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (job.applicationsCount > 0) ...[
                Icon(
                  Icons.people,
                  color: companyColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${job.applicationsCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: companyColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: <Widget>[
              Expanded(
                child: UnifiedButton(
                  text: 'Bewerken',
                  onPressed: () {
                    // TODO: Navigate to job edit
                  },
                  type: UnifiedButtonType.secondary,
                  size: UnifiedButtonSize.small,
                  icon: Icons.edit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: UnifiedButton(
                  text: 'Sollicitaties',
                  onPressed: job.applicationsCount > 0 ? () {
                    // TODO: Navigate to applications
                  } : null,
                  type: UnifiedButtonType.primary,
                  size: UnifiedButtonSize.small,
                  icon: Icons.people,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
