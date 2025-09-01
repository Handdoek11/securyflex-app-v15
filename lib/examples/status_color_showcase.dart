import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';
import '../unified_card_system.dart';
import '../unified_status_colors.dart';
import '../unified_header.dart';
import '../beveiliger_agenda/models/shift_data.dart';
import '../company_dashboard/models/job_posting_data.dart';

/// 🎨 **Status Color System Showcase**
/// 
/// This screen demonstrates the unified status color system in action,
/// showing how the Planning page's visual richness is now consistent
/// across the entire SecuryFlex app.
/// 
/// **Key Features Demonstrated:**
/// - Unified status colors across different contexts
/// - Status-aware card components
/// - Dutch localization integration
/// - Role-based theming compatibility
/// - Visual hierarchy through color coding
class StatusColorShowcase extends StatelessWidget {
  final UserRole userRole;

  const StatusColorShowcase({
    super.key,
    this.userRole = UserRole.guard,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SecuryFlexTheme.getColorScheme(userRole).surface,
      body: Column(
        children: [
          UnifiedHeader.simple(
            title: 'Status Color System',
            userRole: userRole,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Shift Status Colors'),
                  _buildShiftStatusExamples(),
                  SizedBox(height: DesignTokens.spacingXL),
                  
                  _buildSectionTitle('Job Posting Status Colors'),
                  _buildJobPostingStatusExamples(),
                  SizedBox(height: DesignTokens.spacingXL),
                  
                  _buildSectionTitle('Priority Indicators'),
                  _buildPriorityExamples(),
                  SizedBox(height: DesignTokens.spacingXL),
                  
                  _buildSectionTitle('Availability Status'),
                  _buildAvailabilityExamples(),
                  SizedBox(height: DesignTokens.spacingXL),
                  
                  _buildSectionTitle('Before vs After Comparison'),
                  _buildComparisonExamples(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: Text(
        title,
        style: TextStyle(
          fontSize: DesignTokens.fontSizeTitleLarge,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.colorPrimaryBlue,
        ),
      ),
    );
  }

  Widget _buildShiftStatusExamples() {
    final shiftStatuses = [
      ShiftStatus.pending,
      ShiftStatus.accepted,
      ShiftStatus.confirmed,
      ShiftStatus.inProgress,
      ShiftStatus.completed,
      ShiftStatus.cancelled,
    ];

    return Column(
      children: shiftStatuses.map((status) {
        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: UnifiedCard.standard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator row
                Row(
                  children: [
                    Icon(
                      StatusColorHelper.getShiftStatusIcon(status),
                      size: 16,
                      color: StatusColorHelper.getShiftStatusColor(status),
                    ),
                    SizedBox(width: DesignTokens.spacingXS),
                    Text(
                      StatusColorHelper.getShiftStatusText(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: StatusColorHelper.getShiftStatusColor(status),
                      ),
                    ),
                    Spacer(),
                    // Status color indicator dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: StatusColorHelper.getShiftStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingS),
                // Main content
                Padding(
                  padding: EdgeInsets.all(DesignTokens.spacingM),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kantoor Beveiliging',
                          style: TextStyle(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: DesignTokens.spacingXS),
                        Text(
                          'Amsterdam Centrum • €18.50/uur',
                          style: TextStyle(
                            color: DesignTokens.colorGray600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingS,
                      vertical: DesignTokens.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: StatusColorHelper.getShiftStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Text(
                      StatusColorHelper.getShiftStatusText(status),
                      style: TextStyle(
                        color: StatusColorHelper.getShiftStatusColor(status),
                        fontWeight: DesignTokens.fontWeightMedium,
                        fontSize: 12,
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
      }).toList(),
    );
  }

  Widget _buildJobPostingStatusExamples() {
    final jobStatuses = [
      JobPostingStatus.draft,
      JobPostingStatus.active,
      JobPostingStatus.filled,
      JobPostingStatus.completed,
      JobPostingStatus.expired,
      JobPostingStatus.cancelled,
    ];

    return Column(
      children: jobStatuses.map((status) {
        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: UnifiedCard.standard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator row
                Row(
                  children: [
                    Text(
                      status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: StatusColorHelper.getJobPostingStatusColor(status),
                      ),
                    ),
                    Spacer(),
                    // Status color indicator dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: StatusColorHelper.getJobPostingStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingS),
                // Main content
                Padding(
                  padding: EdgeInsets.all(DesignTokens.spacingM),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Beveiliger Gezocht',
                              style: TextStyle(
                                fontWeight: DesignTokens.fontWeightSemiBold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: DesignTokens.spacingXS),
                            Text(
                              'Rotterdam • 3 kandidaten',
                              style: TextStyle(
                                color: DesignTokens.colorGray600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriorityExamples() {
    final priorities = ['low', 'medium', 'high', 'urgent'];
    final priorityLabels = ['Laag', 'Middel', 'Hoog', 'Spoed'];

    return Column(
      children: List.generate(priorities.length, (index) {
        final priority = priorities[index];
        final label = priorityLabels[index];
        
        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: UnifiedCard.standard(
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: StatusColorHelper.getPriorityColor(priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: Text(
                      '$label Prioriteit',
                      style: TextStyle(
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ),
                  Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: StatusColorHelper.getPriorityColor(priority),
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAvailabilityExamples() {
    final availabilities = ['beschikbaar', 'bezet', 'offline'];
    final icons = [Icons.check_circle, Icons.schedule, Icons.offline_bolt];

    return Column(
      children: List.generate(availabilities.length, (index) {
        final availability = availabilities[index];
        final icon = icons[index];
        
        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: UnifiedCard.standard(
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: StatusColorHelper.getAvailabilityColor(availability),
                    size: 20,
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: Text(
                      'Jan de Beveiliger',
                      style: TextStyle(
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingS,
                      vertical: DesignTokens.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: StatusColorHelper.getAvailabilityColor(availability).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Text(
                      availability.toUpperCase(),
                      style: TextStyle(
                        color: StatusColorHelper.getAvailabilityColor(availability),
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildComparisonExamples() {
    return Column(
      children: [
        // Before example
        Text(
          '❌ BEFORE: Inconsistent Colors',
          style: TextStyle(
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.colorError,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: DesignTokens.colorGray100,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Text(
            'DesignTokens.statusPending, DesignTokens.statusAccepted, DesignTokens.colorSuccess, BeveiligerDashboardTheme.securityBlue',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: DesignTokens.colorGray700,
            ),
          ),
        ),
        SizedBox(height: DesignTokens.spacingL),
        
        // After example
        Text(
          '✅ AFTER: Unified System',
          style: TextStyle(
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.colorSuccess,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Text(
            'StatusColorHelper.getShiftStatusColor(status)\nDesignTokens.statusPending\nDesignTokens.statusConfirmed',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: DesignTokens.colorSuccess,
            ),
          ),
        ),
      ],
    );
  }
}
