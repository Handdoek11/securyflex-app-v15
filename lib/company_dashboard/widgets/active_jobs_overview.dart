import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:intl/intl.dart';

import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';
import 'package:securyflex_app/company_dashboard/services/job_posting_service.dart';
import 'package:securyflex_app/company_dashboard/widgets/skeleton_loader.dart';
import 'package:securyflex_app/company_dashboard/widgets/empty_state.dart';
import 'package:flutter/material.dart';

// ============================================================================
// MOBILE-FIRST ACTIVE JOBS OVERVIEW
// ============================================================================

/// Active jobs overview widget - Simplified for mobile-first design
/// Clean job cards with essential information and 2 action buttons
class ActiveJobsOverview extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final VoidCallback? onViewAllJobs;
  final VoidCallback? onCreateJob;

  const ActiveJobsOverview({
    super.key,
    this.animationController,
    this.animation,
    this.onViewAllJobs,
    this.onCreateJob,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 30 * (1.0 - animation!.value), 0.0),
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              child: Column(
                children: <Widget>[
                    
                    // Jobs list
                    FutureBuilder<List<JobPostingData>>(
                      future: JobPostingService.instance.getActiveJobs(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Column(
                            children: [
                              JobCardSkeleton(userRole: UserRole.company),
                              JobCardSkeleton(userRole: UserRole.company),
                              JobCardSkeleton(userRole: UserRole.company),
                            ],
                          );
                        }

                        final activeJobs = snapshot.data!;

                        if (activeJobs.isEmpty) {
                          return EmptyState.noActiveJobs(
                            onCreateJob: onCreateJob ?? () {},
                            userRole: UserRole.company,
                          );
                        }
                        
                        return Column(
                          children: [
                            ...activeJobs.take(3).map((job) => _buildJobListItem(context, job)),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobListItem(BuildContext context, JobPostingData job) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    final currencyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job title and status
              Row(
                children: [
                  // Job icon
                  Container(
                    padding: EdgeInsets.all(DesignTokens.spacingS),
                    decoration: BoxDecoration(
                      color: companyColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Icon(
                      Icons.work_outline,
                      size: 20,
                      color: companyColors.primary,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingM),

                  // Job title and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: companyColors.onSurface,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: DesignTokens.spacingXS),
                        // Status badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DesignTokens.spacingS,
                            vertical: DesignTokens.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(job.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                          ),
                          child: Text(
                            _getStatusText(job.status),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getStatusColor(job.status),
                              fontWeight: DesignTokens.fontWeightMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: DesignTokens.spacingM),

              // Location and meta info
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: companyColors.onSurfaceVariant,
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Expanded(
                    child: Text(
                      job.location,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: companyColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Hourly rate
                  Text(
                    currencyFormat.format(job.hourlyRate),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: companyColors.primary,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                  Text(
                    '/uur',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: companyColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              SizedBox(height: DesignTokens.spacingM),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _viewJobDetails(context, job),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: companyColors.primary,
                        foregroundColor: companyColors.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                        ),
                      ),
                      child: Text(
                        'Bekijk Details',
                        style: TextStyle(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _contactGuard(context, job),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: companyColors.primary,
                        side: BorderSide(color: companyColors.primary),
                        padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                        ),
                      ),
                      child: Text(
                        'Contact',
                        style: TextStyle(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Divider between jobs
        Divider(
          height: 1,
          thickness: 1,
          color: companyColors.outline.withValues(alpha: 0.1),
        ),
      ],
    );
  }

  /// Get status color for job status
  Color _getStatusColor(JobPostingStatus status) {
    switch (status) {
      case JobPostingStatus.active:
        return DesignTokens.colorSuccess;
      case JobPostingStatus.filled:
        return DesignTokens.colorInfo;
      case JobPostingStatus.expired:
        return DesignTokens.colorWarning;
      case JobPostingStatus.cancelled:
        return DesignTokens.colorError;
      default:
        return DesignTokens.colorGray500;
    }
  }

  /// Get status text for job status
  String _getStatusText(JobPostingStatus status) {
    switch (status) {
      case JobPostingStatus.active:
        return 'Actief';
      case JobPostingStatus.filled:
        return 'Bezet';
      case JobPostingStatus.expired:
        return 'Verlopen';
      case JobPostingStatus.cancelled:
        return 'Geannuleerd';
      default:
        return 'Onbekend';
    }
  }

  /// View job details
  void _viewJobDetails(BuildContext context, JobPostingData job) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bekijk details voor: ${job.title}'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Contact guard for job
  void _contactGuard(BuildContext context, JobPostingData job) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact functie voor: ${job.title}'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
