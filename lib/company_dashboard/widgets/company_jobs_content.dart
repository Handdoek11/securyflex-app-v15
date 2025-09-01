import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_buttons.dart';

import 'package:securyflex_app/company_dashboard/screens/job_posting_form_screen.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';
import 'package:securyflex_app/company_dashboard/services/job_posting_service.dart';
import 'package:securyflex_app/company_dashboard/localization/company_nl.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/responsive/responsive_provider.dart';
import '../../core/responsive/responsive_extensions.dart';

/// Jobs content widget for the integrated jobs/applications tab screen
/// Extracted from CompanyJobsScreen to enable tab integration
/// Maintains all existing functionality with cross-tab navigation support
class CompanyJobsContent extends StatefulWidget {
  const CompanyJobsContent({
    super.key,
    this.animationController,
    this.scrollController,
    this.selectedJobId,
    this.onViewApplications,
  });

  final AnimationController? animationController;
  final ScrollController? scrollController;
  final String? selectedJobId; // For highlighting specific job
  final void Function(String jobId)? onViewApplications; // Cross-tab navigation

  @override
  State<CompanyJobsContent> createState() => _CompanyJobsContentState();
}

class _CompanyJobsContentState extends State<CompanyJobsContent>
    with TickerProviderStateMixin {
  
  List<Widget> listViews = <Widget>[];

  @override
  void initState() {
    super.initState();
    _addAllListData();
  }

  @override
  void didUpdateWidget(CompanyJobsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuild if selected job changes
    if (oldWidget.selectedJobId != widget.selectedJobId) {
      _addAllListData();
    }
  }

  void _addAllListData() {
    listViews.clear();
    const int count = 3; // Number of widgets

    // Jobs section title removed - using UnifiedHeader instead

    // Job management overview with cross-tab navigation
    listViews.add(
      _buildJobManagementCard(
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: widget.animationController!,
            curve: Interval(
              (1 / count) * 1, 
              1.0, 
              curve: Curves.fastOutSlowIn,
            ),
          ),
        ),
        animationController: widget.animationController!,
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _getData(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        } else {
          return ListView.builder(
            controller: widget.scrollController,
            padding: EdgeInsets.only(
              top: DesignTokens.spacingL,
              bottom: 62 + context.safeAreaResponsivePadding.bottom,
            ),
            itemCount: listViews.length,
            scrollDirection: Axis.vertical,
            itemBuilder: (BuildContext context, int index) {
              widget.animationController?.forward();
              return listViews[index];
            },
          );
        }
      },
    );
  }

  /// Build job management card following Dashboard pattern
  Widget _buildJobManagementCard({
    required Animation<double> animation,
    required AnimationController animationController,
  }) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0, 
              30 * (1.0 - animation.value), 
              0.0,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingL,
                vertical: DesignTokens.spacingS,
              ),
              child: EnhancedJobManagementOverview(
                animation: animation,
                animationController: animationController,
                selectedJobId: widget.selectedJobId,
                onViewApplications: widget.onViewApplications,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Enhanced job management overview with cross-tab navigation support
/// Extends the existing JobManagementOverview with additional functionality
class EnhancedJobManagementOverview extends StatelessWidget {
  const EnhancedJobManagementOverview({
    super.key,
    this.animationController,
    this.animation,
    this.selectedJobId,
    this.onViewApplications,
  });

  final AnimationController? animationController;
  final Animation<double>? animation;
  final String? selectedJobId;
  final void Function(String jobId)? onViewApplications;

  @override
  Widget build(BuildContext context) {
    return EnhancedJobManagementWidget(
      animation: animation,
      animationController: animationController,
      selectedJobId: selectedJobId,
      onViewApplications: onViewApplications,
    );
  }
}

/// Mobile-first job management widget
/// Simplified design with clean metrics and job cards
class EnhancedJobManagementWidget extends StatelessWidget {
  const EnhancedJobManagementWidget({
    super.key,
    this.animationController,
    this.animation,
    this.selectedJobId,
    this.onViewApplications,
  });

  final AnimationController? animationController;
  final Animation<double>? animation;
  final String? selectedJobId;
  final void Function(String jobId)? onViewApplications;

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
            child: _buildJobManagementContent(context),
          ),
        );
      },
    );
  }

  /// Build job management content with metrics and job list
  Widget _buildJobManagementContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            CompanyNL.jobManagement,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSection,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),

          SizedBox(height: DesignTokens.spacingM),

          // Job metrics section
          _buildJobMetricsSection(context),

          SizedBox(height: DesignTokens.spacingL),

          // Job list section
          _buildJobListSection(context),
        ],
      ),
    );
  }

  /// Build job metrics section with UnifiedCard.compact
  Widget _buildJobMetricsSection(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: JobPostingService.getCompanyJobStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final stats = snapshot.data!;

        return Column(
          children: [

            // Metrics grid
            Row(
              children: [
                Expanded(
                  child: UnifiedCard.compact(
                    userRole: UserRole.company,
                    child: _buildMetricContent(
                      context,
                      CompanyNL.totalJobsPosted,
                      stats['totalJobsPosted'].toString(),
                      Icons.work_outline,
                      DesignTokens.colorInfo,
                    ),
                  ),
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: UnifiedCard.compact(
                    userRole: UserRole.company,
                    child: _buildMetricContent(
                      context,
                      CompanyNL.activeJobs,
                      stats['activeJobs'].toString(),
                      Icons.schedule,
                      DesignTokens.statusInProgress,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: DesignTokens.spacingM),

            Row(
              children: [
                Expanded(
                  child: UnifiedCard.compact(
                    userRole: UserRole.company,
                    child: _buildMetricContent(
                      context,
                      CompanyNL.completedJobs,
                      stats['completedJobs'].toString(),
                      Icons.check_circle_outline,
                      DesignTokens.statusCompleted,
                    ),
                  ),
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: UnifiedCard.compact(
                    userRole: UserRole.company,
                    child: _buildMetricContent(
                      context,
                      CompanyNL.totalApplicationsReceived,
                      stats['totalApplications'].toString(),
                      Icons.people_outline,
                      DesignTokens.colorWarning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Build metric content for UnifiedCard.compact
  Widget _buildMetricContent(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: color,
          size: DesignTokens.iconSizeL,
        ),
        SizedBox(height: DesignTokens.spacingS),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: DesignTokens.fontWeightBold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: DesignTokens.fontFamily,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build job list section
  Widget _buildJobListSection(BuildContext context) {
    return FutureBuilder<List<JobPostingData>>(
      future: JobPostingService.instance.getCompanyJobs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final jobs = snapshot.data!;
        if (jobs.isEmpty) {
          return _buildEmptyJobsState(context);
        }

        return Column(
          children: jobs.map((job) => Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
            child: UnifiedCard.standard(
              userRole: UserRole.company,
              child: _buildJobCardContent(context, job),
            ),
          )).toList(),
        );
      },
    );
  }

  /// Build job card content for UnifiedCard.standard
  Widget _buildJobCardContent(BuildContext context, JobPostingData job) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    final currencyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');

    return Column(
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
                      fontFamily: DesignTokens.fontFamily,
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
                        fontFamily: DesignTokens.fontFamily,
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
                  fontFamily: DesignTokens.fontFamily,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              currencyFormat.format(job.hourlyRate),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: companyColors.primary,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ],
        ),

        SizedBox(height: DesignTokens.spacingM),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: UnifiedButton.secondary(
                text: CompanyNL.editJob,
                onPressed: () => _navigateToJobEdit(context, job),
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: UnifiedButton.primary(
                text: CompanyNL.applications,
                onPressed: () {
                  if (onViewApplications != null) {
                    onViewApplications!(job.jobId);
                  }
                },
              ),
            ),
          ],
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



  /// Build empty jobs state
  Widget _buildEmptyJobsState(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: companyColors.onSurfaceVariant,
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'Geen actieve opdrachten',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: companyColors.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Plaats je eerste opdracht om te beginnen',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: companyColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: DesignTokens.spacingL),
          UnifiedButton.primary(
            text: 'Nieuwe Job',
            onPressed: () => _navigateToJobCreation(context),
          ),
        ],
      ),
    );
  }

  /// Navigate to job creation
  void _navigateToJobCreation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobPostingFormScreen(),
      ),
    );
  }

  /// Navigate to job edit
  void _navigateToJobEdit(BuildContext context, JobPostingData job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobPostingFormScreen(existingJob: job),
      ),
    );
  }
}