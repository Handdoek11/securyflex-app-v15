import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../services/keyboard_shortcuts_service.dart';

/// Bulk operations toolbar for company dashboard
/// 
/// Provides efficient bulk operations with keyboard shortcuts:
/// - Multi-selection support
/// - Bulk approve/reject applications
/// - Bulk job status updates
/// - Bulk export operations
/// - Professional keyboard shortcuts
class BulkOperationsToolbar extends StatefulWidget {
  final List<String> selectedItems;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;
  final VoidCallback? onBulkApprove;
  final VoidCallback? onBulkReject;
  final VoidCallback? onBulkDelete;
  final VoidCallback? onBulkExport;
  final VoidCallback? onBulkUpdate;
  final String itemType; // 'applications', 'jobs', 'guards', etc.
  final int totalItemsCount;
  
  const BulkOperationsToolbar({
    super.key,
    required this.selectedItems,
    this.onSelectAll,
    this.onDeselectAll,
    this.onBulkApprove,
    this.onBulkReject,
    this.onBulkDelete,
    this.onBulkExport,
    this.onBulkUpdate,
    this.itemType = 'items',
    required this.totalItemsCount,
  });
  
  @override
  State<BulkOperationsToolbar> createState() => _BulkOperationsToolbarState();
}

class _BulkOperationsToolbarState extends State<BulkOperationsToolbar> 
    with KeyboardShortcutMixin {
  
  @override
  void initState() {
    super.initState();
    _registerKeyboardShortcuts();
  }
  
  void _registerKeyboardShortcuts() {
    // Register bulk operation shortcuts
    registerShortcut('Ctrl+A', _selectAll);
    registerShortcut('Ctrl+Shift+A', _deselectAll);
    registerShortcut('Delete', _bulkDelete);
    registerShortcut('Ctrl+E', _bulkExport);
    registerShortcut('Ctrl+Shift+Y', _bulkApprove);
    registerShortcut('Ctrl+Shift+N', _bulkReject);
  }
  
  void _selectAll() {
    if (widget.onSelectAll != null) {
      widget.onSelectAll!();
    }
  }
  
  void _deselectAll() {
    if (widget.onDeselectAll != null) {
      widget.onDeselectAll!();
    }
  }
  
  void _bulkDelete() {
    if (widget.selectedItems.isNotEmpty && widget.onBulkDelete != null) {
      _showConfirmationDialog(
        title: 'Delete ${widget.selectedItems.length} ${widget.itemType}',
        message: 'Are you sure you want to delete the selected ${widget.itemType}? This action cannot be undone.',
        onConfirm: widget.onBulkDelete!,
        confirmText: 'Delete',
        isDestructive: true,
      );
    }
  }
  
  void _bulkExport() {
    if (widget.onBulkExport != null) {
      widget.onBulkExport!();
    }
  }
  
  void _bulkApprove() {
    if (widget.selectedItems.isNotEmpty && widget.onBulkApprove != null) {
      widget.onBulkApprove!();
    }
  }
  
  void _bulkReject() {
    if (widget.selectedItems.isNotEmpty && widget.onBulkReject != null) {
      _showConfirmationDialog(
        title: 'Reject ${widget.selectedItems.length} ${widget.itemType}',
        message: 'Are you sure you want to reject the selected ${widget.itemType}?',
        onConfirm: widget.onBulkReject!,
        confirmText: 'Reject',
        isDestructive: false,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    final hasSelection = widget.selectedItems.isNotEmpty;
    final isAllSelected = widget.selectedItems.length == widget.totalItemsCount;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: hasSelection ? 80 : 0,
      child: hasSelection ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border(
            top: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Selection info
            Icon(
              Icons.check_circle,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              '${widget.selectedItems.length} ${widget.itemType} selected',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(width: 24),
            
            // Select all/deselect all
            TextButton.icon(
              onPressed: isAllSelected ? _deselectAll : _selectAll,
              icon: Icon(
                isAllSelected ? Icons.deselect : Icons.select_all,
                size: 16,
              ),
              label: Text(isAllSelected ? 'Deselect All' : 'Select All'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            ),
            
            const Spacer(),
            
            // Bulk actions
            Row(
              children: [
                // Approve action
                if (widget.onBulkApprove != null)
                  _buildBulkActionButton(
                    icon: Icons.check,
                    label: 'Approve',
                    onPressed: _bulkApprove,
                    tooltip: 'Approve selected (Ctrl+Shift+Y)',
                    colorScheme: colorScheme,
                    isPositive: true,
                  ),
                
                // Reject action
                if (widget.onBulkReject != null) ...[
                  const SizedBox(width: 8),
                  _buildBulkActionButton(
                    icon: Icons.close,
                    label: 'Reject',
                    onPressed: _bulkReject,
                    tooltip: 'Reject selected (Ctrl+Shift+N)',
                    colorScheme: colorScheme,
                    isNegative: true,
                  ),
                ],
                
                // Update action
                if (widget.onBulkUpdate != null) ...[
                  const SizedBox(width: 8),
                  _buildBulkActionButton(
                    icon: Icons.edit,
                    label: 'Update',
                    onPressed: widget.onBulkUpdate,
                    tooltip: 'Update selected',
                    colorScheme: colorScheme,
                  ),
                ],
                
                // Export action
                if (widget.onBulkExport != null) ...[
                  const SizedBox(width: 8),
                  _buildBulkActionButton(
                    icon: Icons.download,
                    label: 'Export',
                    onPressed: _bulkExport,
                    tooltip: 'Export selected (Ctrl+E)',
                    colorScheme: colorScheme,
                  ),
                ],
                
                // Delete action
                if (widget.onBulkDelete != null) ...[
                  const SizedBox(width: 8),
                  _buildBulkActionButton(
                    icon: Icons.delete,
                    label: 'Delete',
                    onPressed: _bulkDelete,
                    tooltip: 'Delete selected (Delete key)',
                    colorScheme: colorScheme,
                    isDestructive: true,
                  ),
                ],
              ],
            ),
          ],
        ),
      ) : null,
    );
  }
  
  Widget _buildBulkActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required String tooltip,
    required ColorScheme colorScheme,
    bool isPositive = false,
    bool isNegative = false,
    bool isDestructive = false,
  }) {
    Color buttonColor;
    Color textColor;
    
    if (isDestructive) {
      buttonColor = DesignTokens.colorError;
      textColor = DesignTokens.colorWhite;
    } else if (isPositive) {
      buttonColor = DesignTokens.colorSuccess;
      textColor = DesignTokens.colorWhite;
    } else if (isNegative) {
      buttonColor = DesignTokens.colorWarning;
      textColor = DesignTokens.colorWhite;
    } else {
      buttonColor = colorScheme.primary;
      textColor = DesignTokens.colorWhite;
    }
    
    return Tooltip(
      message: tooltip,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  void _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required String confirmText,
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive 
                  ? DesignTokens.colorError 
                  : DesignTokens.companyPrimary,
              foregroundColor: DesignTokens.colorWhite,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

/// Extension for adding bulk operations to lists
extension BulkOperationsList<T> on List<T> {
  /// Apply bulk operation to selected items
  List<T> applyBulkOperation(
    List<String> selectedIds, 
    String Function(T) idExtractor,
    T Function(T) operation,
  ) {
    return map((item) {
      if (selectedIds.contains(idExtractor(item))) {
        return operation(item);
      }
      return item;
    }).toList();
  }
  
  /// Remove selected items from list
  List<T> removeBulkItems(
    List<String> selectedIds,
    String Function(T) idExtractor,
  ) {
    return where((item) => !selectedIds.contains(idExtractor(item))).toList();
  }
  
  /// Get selected items from list
  List<T> getSelectedItems(
    List<String> selectedIds,
    String Function(T) idExtractor,
  ) {
    return where((item) => selectedIds.contains(idExtractor(item))).toList();
  }
}