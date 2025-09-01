import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';
import '../unified_buttons.dart';
import 'unified_dashboard_card.dart';

/// Modern, performance-optimized active jobs widget
/// 
/// This replaces the legacy active_jobs_widget.dart with:
/// - Maximum 3 nesting levels (vs 5+ in legacy)
/// - Consolidated styling via UnifiedDashboardCard
/// - Clean job card layout
/// - Material 3 compliance
/// - Performance-first design
class ModernActiveJobsWidget extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final List<ActiveJob>? jobs;
  final VoidCallback? onViewAll;

  const ModernActiveJobsWidget({
    super.key,
    this.animationController,
    this.animation,
    this.jobs,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final activeJobs = jobs ?? ActiveJob.mockJobs();
    
    return AnimatedBuilder(
      animation: animationController ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        final animationValue = animation?.value ?? 1.0;
        return FadeTransition(
          opacity: animation ?? const AlwaysStoppedAnimation(1.0),
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              20 * (1.0 - animationValue), // Reduced translation distance
              0.0
            ),
            child: UnifiedDashboardCard(
              title: 'Actieve Opdrachten',
              subtitle: '${activeJobs.length} lopende opdrachten',
              userRole: UserRole.guard,
              variant: DashboardCardVariant.standard,
              action: onViewAll != null 
                ? UnifiedButton.text(
                    text: 'Bekijk alles',
                    size: UnifiedButtonSize.small,
                    onPressed: onViewAll!,
                  )
                : null,
              child: activeJobs.isEmpty 
                ? _buildEmptyState(context)
                : _buildJobsList(context, activeJobs),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Column(
      children: [
        Icon(
          Icons.work_outline,
          size: DesignTokens.iconSizeXL,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        SizedBox(height: DesignTokens.spacingM),
        Text(
          'Geen actieve opdrachten',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
            fontSize: DesignTokens.fontSizeBody,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        Text(
          'Zoek naar nieuwe opdrachten in de marketplace',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightRegular,
            fontSize: DesignTokens.fontSizeS,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildJobsList(BuildContext context, List<ActiveJob> jobs) {
    return Column(
      children: jobs.take(3).map((job) => Padding(
        padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
        child: _buildJobCard(context, job),
      )).toList(),
    );
  }

  Widget _buildJobCard(BuildContext context, ActiveJob job) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        fontSize: DesignTokens.fontSizeBody,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      job.company,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightRegular,
                        fontSize: DesignTokens.fontSizeS,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(colorScheme, job.status),
            ],
          ),
          SizedBox(height: DesignTokens.spacingM),
          // Job details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  colorScheme,
                  Icons.schedule,
                  job.schedule,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  colorScheme,
                  Icons.location_on,
                  job.location,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  colorScheme,
                  Icons.euro,
                  job.rate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ColorScheme colorScheme, JobStatus status) {
    Color chipColor;
    String statusText;
    
    switch (status) {
      case JobStatus.active:
        chipColor = DesignTokens.colorSuccess;
        statusText = 'Actief';
        break;
      case JobStatus.pending:
        chipColor = DesignTokens.colorWarning;
        statusText = 'In behandeling';
        break;
      case JobStatus.completed:
        chipColor = DesignTokens.colorInfo;
        statusText = 'Voltooid';
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontWeight: DesignTokens.fontWeightMedium,
          fontSize: DesignTokens.fontSizeXS,
          color: chipColor,
        ),
      ),
    );
  }

  Widget _buildDetailItem(ColorScheme colorScheme, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeS,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        SizedBox(width: DesignTokens.spacingXS),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightRegular,
              fontSize: DesignTokens.fontSizeXS,
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Data model for active jobs
class ActiveJob {
  final String id;
  final String title;
  final String company;
  final String schedule;
  final String location;
  final String rate;
  final JobStatus status;

  const ActiveJob({
    required this.id,
    required this.title,
    required this.company,
    required this.schedule,
    required this.location,
    required this.rate,
    required this.status,
  });

  /// Mock data for development and testing
  static List<ActiveJob> mockJobs() {
    return [
      const ActiveJob(
        id: '1',
        title: 'Beveiliging Winkelcentrum',
        company: 'SecureGuard BV',
        schedule: 'Ma-Vr 09:00-17:00',
        location: 'Amsterdam',
        rate: '€42/u',
        status: JobStatus.active,
      ),
      const ActiveJob(
        id: '2',
        title: 'Evenement Beveiliging',
        company: 'Event Security',
        schedule: 'Za 18:00-02:00',
        location: 'Rotterdam',
        rate: '€45/u',
        status: JobStatus.pending,
      ),
    ];
  }

  /// Create from API response
  factory ActiveJob.fromJson(Map<String, dynamic> json) {
    return ActiveJob(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      schedule: json['schedule'] ?? '',
      location: json['location'] ?? '',
      rate: json['rate'] ?? '',
      status: JobStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => JobStatus.pending,
      ),
    );
  }
}

/// Job status enumeration
enum JobStatus {
  active,
  pending,
  completed,
}
