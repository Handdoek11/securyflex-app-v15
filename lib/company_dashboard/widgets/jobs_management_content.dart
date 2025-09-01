import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../widgets/drag_drop_job_scheduler.dart';
import '../bloc/dashboard_state.dart';

/// Jobs Management Content Component
/// 
/// Displays job management interface with drag-drop scheduler,
/// job creation capabilities, and data table view for desktop users.
class JobsManagementContent extends StatelessWidget {
  final bool useDataTables;
  final DashboardState dashboardState;
  final VoidCallback? onNewJobPressed;

  const JobsManagementContent({
    super.key,
    required this.useDataTables,
    required this.dashboardState,
    this.onNewJobPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Jobs header with action button
        _buildJobsHeader(),
        SizedBox(height: DesignTokens.spacingL),
        
        // Main content - scheduler or data table
        Container(
          height: 800, // Fixed height to prevent unbounded constraints
          child: DragDropJobScheduler(),
        ),
      ],
    );
  }

  Widget _buildJobsHeader() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opdrachten Beheer',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              'Plan, beheer en monitor beveiligingsopdrachten',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                // Show jobs import dialog
              },
              icon: Icon(Icons.upload_file),
              label: Text('Importeren'),
            ),
            SizedBox(width: DesignTokens.spacingM),
            ElevatedButton.icon(
              onPressed: onNewJobPressed,
              icon: Icon(Icons.add),
              label: Text('Nieuwe Opdracht'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}