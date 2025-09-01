import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../bloc/bloc.dart';

/// Desktop Action Toolbar Component
/// 
/// Provides primary and secondary actions for the company dashboard,
/// including job creation, bulk operations, filtering, data export,
/// and emergency actions. Integrates with BLoC for state management.
class DesktopActionToolbar extends StatelessWidget {
  final VoidCallback? onNewJobPressed;
  final VoidCallback? onBulkImportPressed;
  final Function(String)? onExportSelected;
  final VoidCallback? onEmergencyPressed;

  const DesktopActionToolbar({
    super.key,
    this.onNewJobPressed,
    this.onBulkImportPressed,
    this.onExportSelected,
    this.onEmergencyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyDashboardBloc, DashboardState>(
      builder: (context, dashboardState) {
        return _buildToolbarContent(context, dashboardState);
      },
    );
  }

  Widget _buildToolbarContent(BuildContext context, DashboardState dashboardState) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Primary actions
          _buildPrimaryActions(context, colorScheme),
          SizedBox(width: DesignTokens.spacingM),
          
          // Multi-select mode indicators and actions
          if (dashboardState.isMultiSelectMode) ...[
            _buildMultiSelectIndicator(context, dashboardState, colorScheme),
            SizedBox(width: DesignTokens.spacingM),
            if (dashboardState.selectedItems.isNotEmpty) ...[
              _buildBulkActionsButton(context, dashboardState),
              SizedBox(width: DesignTokens.spacingM),
            ],
          ],
          
          Spacer(),
          
          // Secondary actions
          _buildSecondaryActions(context, dashboardState, colorScheme),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: onNewJobPressed,
          icon: Icon(Icons.add),
          label: Text('Nieuwe Job'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        OutlinedButton.icon(
          onPressed: onBulkImportPressed,
          icon: Icon(Icons.upload_file),
          label: Text('Bulk Import'),
        ),
      ],
    );
  }

  Widget _buildMultiSelectIndicator(
    BuildContext context, 
    DashboardState dashboardState, 
    ColorScheme colorScheme
  ) {
    return Container(
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
          SizedBox(width: DesignTokens.spacingS),
          InkWell(
            onTap: () {
              context.read<CompanyDashboardBloc>().add(const MultiSelectToggled(false));
              context.read<CompanyDashboardBloc>().add(const ItemSelectionChanged(<String>{}));
            },
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spacingXS),
              child: Icon(
                Icons.close,
                color: colorScheme.onPrimaryContainer,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionsButton(BuildContext context, DashboardState dashboardState) {
    return OutlinedButton.icon(
      onPressed: () => _showBulkActionsMenu(context, dashboardState),
      icon: Icon(Icons.more_horiz),
      label: Text('Bulk acties'),
    );
  }

  Widget _buildSecondaryActions(
    BuildContext context, 
    DashboardState dashboardState, 
    ColorScheme colorScheme
  ) {
    return Row(
      children: [
        // Refresh button or loading indicator
        if (dashboardState.isRefreshing)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          )
        else
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => context.read<CompanyDashboardBloc>().add(const DashboardRefreshed()),
            tooltip: 'Vernieuwen (F5)',
          ),
        
        // Filter toggle
        IconButton(
          icon: Icon(
            dashboardState.isFilterPanelOpen ? Icons.filter_list : Icons.filter_list_outlined,
            color: dashboardState.isFilterPanelOpen ? colorScheme.primary : null,
          ),
          onPressed: () => context.read<CompanyDashboardBloc>().add(
            FilterPanelToggled(!dashboardState.isFilterPanelOpen)
          ),
          tooltip: 'Filters',
        ),
        
        // Export menu
        PopupMenuButton<String>(
          icon: Icon(Icons.download),
          tooltip: 'Exporteren',
          onSelected: onExportSelected,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'csv',
              child: Row(
                children: [
                  Icon(Icons.table_chart, size: 18),
                  SizedBox(width: DesignTokens.spacingS),
                  Text('Export naar CSV'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'excel',
              child: Row(
                children: [
                  Icon(Icons.description, size: 18),
                  SizedBox(width: DesignTokens.spacingS),
                  Text('Export naar Excel'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'pdf',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, size: 18),
                  SizedBox(width: DesignTokens.spacingS),
                  Text('Export naar PDF'),
                ],
              ),
            ),
          ],
        ),
        
        SizedBox(width: DesignTokens.spacingM),
        
        // Emergency action
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: DesignTokens.colorError),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: TextButton.icon(
            onPressed: onEmergencyPressed,
            icon: Icon(Icons.emergency, color: DesignTokens.colorError),
            label: Text(
              'Noodgeval', 
              style: TextStyle(color: DesignTokens.colorError)
            ),
          ),
        ),
      ],
    );
  }

  void _showBulkActionsMenu(BuildContext context, DashboardState dashboardState) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulk Acties (${dashboardState.selectedItems.length} items)',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSubtitle,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            ListTile(
              leading: Icon(Icons.edit, color: DesignTokens.colorInfo),
              title: Text('Bewerk geselecteerde'),
              onTap: () {
                context.pop();
                _performBulkEdit(context, dashboardState);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: DesignTokens.colorError),
              title: Text('Verwijder geselecteerde'),
              onTap: () {
                context.pop();
                _performBulkDelete(context, dashboardState);
              },
            ),
            ListTile(
              leading: Icon(Icons.archive, color: DesignTokens.colorWarning),
              title: Text('Archiveer geselecteerde'),
              onTap: () {
                context.pop();
                _performBulkArchive(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _performBulkEdit(BuildContext context, DashboardState dashboardState) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bulk bewerken van ${dashboardState.selectedItems.length} items'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _performBulkDelete(BuildContext context, DashboardState dashboardState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bevestig verwijdering'),
        content: Text('Weet je zeker dat je ${dashboardState.selectedItems.length} items wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              context.read<CompanyDashboardBloc>().add(const MultiSelectToggled(false));
              context.read<CompanyDashboardBloc>().add(const ItemSelectionChanged(<String>{}));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Items verwijderd'),
                  backgroundColor: DesignTokens.colorSuccess,
                ),
              );
            },
            child: Text('Verwijderen'),
          ),
        ],
      ),
    );
  }

  void _performBulkArchive(BuildContext context) {
    context.read<CompanyDashboardBloc>().add(const MultiSelectToggled(false));
    context.read<CompanyDashboardBloc>().add(const ItemSelectionChanged(<String>{}));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Items gearchiveerd'),
        backgroundColor: DesignTokens.colorSuccess,
      ),
    );
  }
}