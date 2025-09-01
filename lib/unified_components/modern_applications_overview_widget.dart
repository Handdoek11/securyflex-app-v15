import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';
import '../unified_buttons.dart';
import '../unified_card_system.dart';

/// Mobile-first applications overview widget
///
/// Simplified design with:
/// - UnifiedCard.compact for metrics (no CircleAvatar)
/// - Clean application cards with 2 action buttons
/// - Mobile-optimized spacing and touch targets
/// - Wireframe-compliant layout
/// - Performance-first design
class ModernApplicationsOverviewWidget extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final ApplicationsData? data;
  final VoidCallback? onViewAll;
  final VoidCallback? onReviewPending;

  const ModernApplicationsOverviewWidget({
    super.key,
    this.animationController,
    this.animation,
    this.data,
    this.onViewAll,
    this.onReviewPending,
  });

  @override
  Widget build(BuildContext context) {
    final applicationsData = data ?? ApplicationsData.mock();

    // Temporarily disable animation to debug content visibility
    return Column(
              children: [
                  // Action buttons row at the top
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (applicationsData.pendingCount > 0 && onReviewPending != null) ...[
                        UnifiedButton.primary(
                          text: 'Beoordelen',
                          size: UnifiedButtonSize.small,
                          onPressed: onReviewPending!,
                        ),
                        SizedBox(width: DesignTokens.spacingS),
                      ],
                      if (onViewAll != null)
                        UnifiedButton.text(
                          text: 'Bekijk alles',
                          size: UnifiedButtonSize.small,
                          onPressed: onViewAll!,
                        ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingM),

                  // Applications summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          applicationsData.pendingCount.toString(),
                          'In behandeling',
                          Icons.hourglass_empty,
                          DesignTokens.colorWarning,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingM),
                      Expanded(
                        child: _buildSummaryCard(
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
                        child: _buildSummaryCard(
                          context,
                          applicationsData.rejectedCount.toString(),
                          'Afgewezen',
                          Icons.cancel,
                          DesignTokens.colorError,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingM),
                      Expanded(
                        child: _buildSummaryCard(
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

  Widget _buildSummaryCard(BuildContext context, String count, String label, IconData icon, Color color) {
    return UnifiedCard.compact(
      userRole: UserRole.company,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simple icon without CircleAvatar
          Icon(
            icon,
            size: DesignTokens.iconSizeL,
            color: color,
          ),
          SizedBox(height: DesignTokens.spacingS),
          // Value with mobile-optimized typography
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
          // Label with mobile-friendly text
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

  Widget _buildApplicationItem(BuildContext context, RecentApplication application) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);

    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Application header with icon and info
          Row(
            children: [
              // Simple person icon instead of CircleAvatar
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

              // Guard name and job info
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

              // Time ago
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

          // Mobile-first action buttons
          Row(
            children: [
              Expanded(
                child: UnifiedButton.primary(
                  text: 'Bekijk Profiel',
                  size: UnifiedButtonSize.small,
                  onPressed: () => _viewProfile(context, application),
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: UnifiedButton.secondary(
                  text: 'Contact',
                  size: UnifiedButtonSize.small,
                  onPressed: () => _contactApplicant(context, application),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// View applicant profile
  void _viewProfile(BuildContext context, RecentApplication application) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bekijk profiel van: ${application.guardName}'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Contact applicant
  void _contactApplicant(BuildContext context, RecentApplication application) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact met: ${application.guardName}'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Data model for applications overview
class ApplicationsData {
  final int pendingCount;
  final int acceptedCount;
  final int rejectedCount;
  final int totalCount;
  final List<RecentApplication> recentApplications;

  const ApplicationsData({
    required this.pendingCount,
    required this.acceptedCount,
    required this.rejectedCount,
    required this.totalCount,
    required this.recentApplications,
  });

  /// Mock data for development and testing
  factory ApplicationsData.mock() {
    return ApplicationsData(
      pendingCount: 5,
      acceptedCount: 12,
      rejectedCount: 3,
      totalCount: 20,
      recentApplications: [
        const RecentApplication(
          guardName: 'Jan de Vries',
          jobTitle: 'Winkelcentrum Beveiliging',
          timeAgo: '2u geleden',
        ),
        const RecentApplication(
          guardName: 'Maria Janssen',
          jobTitle: 'Evenement Security',
          timeAgo: '4u geleden',
        ),
        const RecentApplication(
          guardName: 'Peter van Dam',
          jobTitle: 'Kantoor Beveiliging',
          timeAgo: '1d geleden',
        ),
      ],
    );
  }

  /// Create from API response
  factory ApplicationsData.fromJson(Map<String, dynamic> json) {
    return ApplicationsData(
      pendingCount: json['pendingCount'] ?? 0,
      acceptedCount: json['acceptedCount'] ?? 0,
      rejectedCount: json['rejectedCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      recentApplications: (json['recentApplications'] as List<dynamic>?)
          ?.map((item) => RecentApplication.fromJson(item))
          .toList() ?? [],
    );
  }
}

/// Data model for recent applications
class RecentApplication {
  final String guardName;
  final String jobTitle;
  final String timeAgo;

  const RecentApplication({
    required this.guardName,
    required this.jobTitle,
    required this.timeAgo,
  });

  /// Create from API response
  factory RecentApplication.fromJson(Map<String, dynamic> json) {
    return RecentApplication(
      guardName: json['guardName'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      timeAgo: json['timeAgo'] ?? '',
    );
  }
}
