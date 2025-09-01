import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/modern_applications_overview_widget.dart';
import '../bloc/dashboard_state.dart';

/// Applications Review Content Component
/// 
/// Displays application review interface with filtering,
/// bulk operations, and detailed application management.
class ApplicationsReviewContent extends StatelessWidget {
  final bool useDataTables;
  final DashboardState dashboardState;

  const ApplicationsReviewContent({
    super.key,
    required this.useDataTables,
    required this.dashboardState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Applications header
        _buildApplicationsHeader(),
        SizedBox(height: DesignTokens.spacingL),
        
        // Main content
        Container(
          height: 600, // Fixed height for applications content
          child: useDataTables
            ? _buildApplicationsDataTable()
            : _buildApplicationsOverview(),
        ),
      ],
    );
  }

  Widget _buildApplicationsHeader() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sollicitaties Overzicht',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              'Beheer inkomende sollicitaties en kandidaten',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (dashboardState.isMultiSelectMode && dashboardState.selectedItems.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.checklist,
                      color: colorScheme.onPrimaryContainer,
                      size: 18,
                    ),
                    SizedBox(width: DesignTokens.spacingXS),
                    Text(
                      '${dashboardState.selectedItems.length} geselecteerd',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ],
                ),
              ),
            if (dashboardState.isMultiSelectMode && dashboardState.selectedItems.isNotEmpty)
              SizedBox(width: DesignTokens.spacingM),
            OutlinedButton.icon(
              onPressed: () {
                // Toggle filter panel
              },
              icon: Icon(Icons.filter_list),
              label: Text('Filters'),
            ),
            SizedBox(width: DesignTokens.spacingM),
            ElevatedButton.icon(
              onPressed: () {
                // Export applications
              },
              icon: Icon(Icons.download),
              label: Text('Exporteren'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApplicationsOverview() {
    return ModernApplicationsOverviewWidget();
  }

  Widget _buildApplicationsDataTable() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Card(
      color: colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recente Sollicitaties',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Toggle multi-select mode
                  },
                  icon: Icon(Icons.checklist),
                  label: Text('Bulk selectie'),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: dashboardState.isMultiSelectMode,
                  columns: const [
                    DataColumn(label: Text('Naam')),
                    DataColumn(label: Text('Positie')),
                    DataColumn(label: Text('Locatie')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Datum')),
                    DataColumn(label: Text('Acties')),
                  ],
                  rows: List.generate(8, (index) => DataRow(
                    selected: dashboardState.selectedItems.contains('app_$index'),
                    onSelectChanged: dashboardState.isMultiSelectMode ? (selected) {
                      // Handle selection change
                    } : null,
                    cells: [
                      DataCell(Text('Kandidaat ${index + 1}')),
                      DataCell(Text(index % 3 == 0 ? 'Beveiliger' : 'Senior Beveiliger')),
                      DataCell(Text(index % 2 == 0 ? 'Amsterdam' : 'Rotterdam')),
                      DataCell(_buildStatusChip(index % 3)),
                      DataCell(Text('${DateTime.now().subtract(Duration(days: index)).day}/${DateTime.now().month}')),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.visibility, size: 18),
                            onPressed: () {},
                            tooltip: 'Bekijk profiel',
                          ),
                          IconButton(
                            icon: Icon(Icons.check, size: 18),
                            onPressed: () {},
                            tooltip: 'Goedkeuren',
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 18),
                            onPressed: () {},
                            tooltip: 'Afwijzen',
                          ),
                        ],
                      )),
                    ],
                  )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(int statusIndex) {
    final colors = [
      {'color': DesignTokens.colorWarning, 'text': 'In behandeling'},
      {'color': DesignTokens.colorSuccess, 'text': 'Goedgekeurd'},
      {'color': DesignTokens.colorError, 'text': 'Afgewezen'},
    ];
    
    final status = colors[statusIndex];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: (status['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status['text'] as String,
        style: TextStyle(
          color: status['color'] as Color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}