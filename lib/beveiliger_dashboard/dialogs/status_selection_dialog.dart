import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/shared/models/guard_status.dart';

/// Status Selection Dialog for Guards
/// Allows quick status changes from the dashboard
/// Follows SecuryFlex unified design system patterns
class StatusSelectionDialog extends StatefulWidget {
  final GuardStatus currentStatus;
  final Function(GuardStatus)? onStatusChanged;

  const StatusSelectionDialog({
    super.key,
    required this.currentStatus,
    this.onStatusChanged,
  });

  @override
  State<StatusSelectionDialog> createState() => _StatusSelectionDialogState();
}

class _StatusSelectionDialogState extends State<StatusSelectionDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  GuardStatus? _selectedStatus;
  bool _isUpdating = false;
  String _errorMessage = '';

  // Available status options for guards (excluding 'geschorst' as that's admin-only)
  final List<GuardStatus> _availableStatuses = [
    GuardStatus.beschikbaar,
    GuardStatus.bezet,
    GuardStatus.nietBeschikbaar,
    GuardStatus.offline,
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              boxShadow: [DesignTokens.shadowHeavy],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(colorScheme),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildStatusOptions(colorScheme),
                        if (_errorMessage.isNotEmpty) ...[
                          SizedBox(height: DesignTokens.spacingM),
                          _buildErrorMessage(colorScheme),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildActionButtons(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusL),
          topRight: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_pin_circle,
            color: colorScheme.onPrimaryContainer,
            size: DesignTokens.iconSizeM,
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Wijzigen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  'Kies je huidige beschikbaarheidsstatus',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.close,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOptions(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Beschikbare Statussen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          ..._availableStatuses.map((status) => _buildStatusOption(status, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildStatusOption(GuardStatus status, ColorScheme colorScheme) {
    final isSelected = _selectedStatus == status;
    final isCurrent = widget.currentStatus == status;
    
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          onTap: _isUpdating ? null : () {
            setState(() {
              _selectedStatus = status;
              _errorMessage = '';
            });
          },
          child: Container(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: isSelected 
                    ? status.color 
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected 
                  ? status.color.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(DesignTokens.spacingS),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Icon(
                    status.icon,
                    color: status.color,
                    size: DesignTokens.iconSizeM,
                  ),
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              status.displayName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: DesignTokens.fontWeightSemiBold,
                                color: isSelected ? status.color : null,
                              ),
                            ),
                          ),
                          if (isCurrent) ...[
                            SizedBox(width: DesignTokens.spacingS),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: DesignTokens.spacingS,
                                vertical: DesignTokens.spacingXS,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                              ),
                              child: Text(
                                'Huidig',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: DesignTokens.fontWeightMedium,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: DesignTokens.spacingXS),
                      Text(
                        _getStatusDescription(status),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: status.color,
                    size: DesignTokens.iconSizeM,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.colorError.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: DesignTokens.colorError,
            size: DesignTokens.iconSizeS,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    final hasChanges = _selectedStatus != widget.currentStatus;
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: UnifiedButton.secondary(
              text: 'Annuleren',
              onPressed: _isUpdating ? () {} : () => context.pop(),
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: UnifiedButton.primary(
              text: _isUpdating ? 'Bijwerken...' : 'Wijzigen',
              onPressed: (hasChanges && !_isUpdating) ? () => _handleStatusUpdate() : () {},
              isLoading: _isUpdating,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(GuardStatus status) {
    switch (status) {
      case GuardStatus.beschikbaar:
        return 'Je bent beschikbaar voor nieuwe opdrachten';
      case GuardStatus.bezet:
        return 'Je bent momenteel bezig met een opdracht';
      case GuardStatus.nietBeschikbaar:
        return 'Je bent tijdelijk niet beschikbaar';
      case GuardStatus.offline:
        return 'Je bent offline en niet zichtbaar voor bedrijven';
      case GuardStatus.actief:
        return 'Je profiel is actief en zichtbaar';
      case GuardStatus.geschorst:
        return 'Je account is geschorst';
    }
  }

  Future<void> _handleStatusUpdate() async {
    if (_selectedStatus == null || _selectedStatus == widget.currentStatus) {
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = '';
    });

    try {
      // TODO: Replace with proper status service once beveiliger_profiel module is rebuilt
      final success = true; // Mock success for now
      
      if (success && mounted) {
        // Call the callback if provided
        widget.onStatusChanged?.call(_selectedStatus!);
        
        // Show success message and close dialog
        context.pop(_selectedStatus);
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Status kon niet worden bijgewerkt. Probeer het opnieuw.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Er is een fout opgetreden. Probeer het opnieuw.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}

/// Helper function to show the status selection dialog
Future<GuardStatus?> showStatusSelectionDialog({
  required BuildContext context,
  required GuardStatus currentStatus,
  Function(GuardStatus)? onStatusChanged,
}) {
  return showDialog<GuardStatus>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatusSelectionDialog(
      currentStatus: currentStatus,
      onStatusChanged: onStatusChanged,
    ),
  );
}
