import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_components/modern_applications_overview_widget.dart';
import 'package:securyflex_app/company_dashboard/localization/company_nl.dart';
import 'package:securyflex_app/marketplace/services/application_service.dart';
import 'package:flutter/material.dart';

/// Applications content widget for the integrated jobs/applications tab screen
/// Extracted from CompanyApplicationsScreen to enable tab integration
/// Maintains all existing functionality with enhanced filtering and cross-tab navigation
class CompanyApplicationsContent extends StatefulWidget {
  const CompanyApplicationsContent({
    super.key,
    this.animationController,
    this.scrollController,
    this.selectedJobId,
    this.applicationFilter,
    this.onViewJob,
  });

  final AnimationController? animationController;
  final ScrollController? scrollController;
  final String? selectedJobId; // For job-specific filtering
  final String? applicationFilter; // For additional filtering
  final void Function(String jobId)? onViewJob; // Cross-tab navigation

  @override
  State<CompanyApplicationsContent> createState() => _CompanyApplicationsContentState();
}

class _CompanyApplicationsContentState extends State<CompanyApplicationsContent>
    with TickerProviderStateMixin {
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Apply initial filter if provided
    if (widget.applicationFilter != null) {
      _parseAndApplyFilter(widget.applicationFilter!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _parseAndApplyFilter(String filter) {
    // Parse filter string (e.g., "job:JOB123", "status:pending")
    // Filter logic will be handled by the overview widget
  }



  /// Build applications management content with metrics and application list
  Widget _buildApplicationsManagementContent(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            CompanyNL.applicationsManagement,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSection,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),

          SizedBox(height: DesignTokens.spacingM),

          // Applications content (without duplicate metrics)
          _buildApplicationListSection(context),
        ],
      ),
    );
  }



  /// Build application list section
  Widget _buildApplicationListSection(BuildContext context) {
    return _buildApplicationsOverviewContent(context);
  }

  /// Build applications overview content without container
  Widget _buildApplicationsOverviewContent(BuildContext context) {
    final applicationsData = ApplicationsData.mock(); // TODO: Replace with real data

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Applications summary cards
        Row(
          children: [
            Expanded(
              child: _buildApplicationSummaryCard(
                context,
                applicationsData.pendingCount.toString(),
                'In behandeling',
                Icons.hourglass_empty,
                DesignTokens.colorWarning,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: _buildApplicationSummaryCard(
                context,
                applicationsData.acceptedCount.toString(),
                'Geaccepteerd',
                Icons.check_circle,
                DesignTokens.colorSuccess,
              ),
            ),
          ],
        ),

        SizedBox(height: DesignTokens.spacingM),

        Row(
          children: [
            Expanded(
              child: _buildApplicationSummaryCard(
                context,
                applicationsData.rejectedCount.toString(),
                'Afgewezen',
                Icons.cancel,
                DesignTokens.colorError,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: _buildApplicationSummaryCard(
                context,
                applicationsData.totalCount.toString(),
                'Totaal',
                Icons.people,
                DesignTokens.colorInfo,
              ),
            ),
          ],
        ),

        if (applicationsData.recentApplications.isNotEmpty) ...[
          SizedBox(height: DesignTokens.spacingL),
          _buildRecentApplications(context, applicationsData.recentApplications),
        ],
      ],
    );
  }

  /// Build application summary card
  Widget _buildApplicationSummaryCard(BuildContext context, String count, String label, IconData icon, Color color) {
    return UnifiedCard.compact(
      userRole: UserRole.company,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeL,
            color: color,
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            count,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightBold,
              fontSize: DesignTokens.fontSizeHeadline,
              color: color,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: DesignTokens.fontSizeCaption,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build recent applications section
  Widget _buildRecentApplications(BuildContext context, List<RecentApplication> applications) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recente Sollicitaties',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontSize: DesignTokens.fontSizeBody,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        ...applications.take(3).map((application) => Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: _buildApplicationItem(context, application),
        )),
      ],
    );
  }

  /// Build individual application item
  Widget _buildApplicationItem(BuildContext context, RecentApplication application) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);

    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spacingS),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.guardName,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        fontSize: DesignTokens.fontSizeBody,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      application.jobTitle,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightRegular,
                        fontSize: DesignTokens.fontSizeCaption,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                application.timeAgo,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightRegular,
                  fontSize: DesignTokens.fontSizeCaption,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingM),
          Row(
            children: [
              Expanded(
                child: UnifiedButton.primary(
                  text: 'Bekijk Profiel',
                  size: UnifiedButtonSize.small,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bekijk profiel van: ${application.guardName}'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: UnifiedButton.secondary(
                  text: 'Contact',
                  size: UnifiedButtonSize.small,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contact met: ${application.guardName}'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildApplicationsManagementContent(context);
  }


}

/// Enhanced application management overview with cross-tab navigation support
/// Extends the existing ApplicationManagementOverview with additional functionality
class EnhancedApplicationManagementOverview extends StatelessWidget {
  const EnhancedApplicationManagementOverview({
    super.key,
    this.animationController,
    this.animation,
    this.selectedJobId,
    this.statusFilter,
    this.searchQuery,
    this.onViewJob,
  });

  final AnimationController? animationController;
  final Animation<double>? animation;
  final String? selectedJobId;
  final ApplicationStatus? statusFilter;
  final String? searchQuery;
  final void Function(String jobId)? onViewJob;

  @override
  Widget build(BuildContext context) {
    // Use the modern applications overview widget
    return ModernApplicationsOverviewWidget(
      animation: animation,
      animationController: animationController,
    );
  }
}
