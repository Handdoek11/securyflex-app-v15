import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';
import '../../unified_buttons.dart';
import '../../unified_status_colors.dart';

/// Assignment context widget for SecuryFlex Chat
/// Shows assignment details and status in chat interface
class AssignmentContextWidget extends StatefulWidget {
  final String assignmentId;
  final UserRole userRole;
  final VoidCallback? onAssignmentTap;
  final bool isCompact;

  const AssignmentContextWidget({
    super.key,
    required this.assignmentId,
    required this.userRole,
    this.onAssignmentTap,
    this.isCompact = false,
  });

  @override
  State<AssignmentContextWidget> createState() => _AssignmentContextWidgetState();
}

class _AssignmentContextWidgetState extends State<AssignmentContextWidget> {
  Map<String, dynamic>? _assignmentData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssignmentData();
  }

  /// Load assignment data from Firestore
  Future<void> _loadAssignmentData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('assignments')
          .doc(widget.assignmentId)
          .get();

      if (mounted) {
        setState(() {
          if (doc.exists) {
            _assignmentData = doc.data();
          } else {
            _error = 'Opdracht niet gevonden';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fout bij laden opdracht: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Format Dutch date
  String _formatDutchDate(DateTime date) {
    final weekdays = ['ma', 'di', 'wo', 'do', 'vr', 'za', 'zo'];
    final months = ['jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
                   'jul', 'aug', 'sep', 'okt', 'nov', 'dec'];
    
    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];
    
    return '$weekday $day $month';
  }

  /// Format Dutch time
  String _formatDutchTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get status color (unified system)
  Color _getStatusColor(String status) {
    return StatusColorHelper.getGenericStatusColor(status);
  }

  /// Get status text in Dutch
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'In behandeling';
      case 'accepted':
        return 'Geaccepteerd';
      case 'started':
        return 'Gestart';
      case 'completed':
        return 'Voltooid';
      case 'cancelled':
        return 'Geannuleerd';
      default:
        return status;
    }
  }

  /// Get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'started':
        return Icons.play_circle_outline;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildCompactView() {
    if (_assignmentData == null) return const SizedBox.shrink();

    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    final title = _assignmentData!['title'] as String? ?? 'Opdracht';
    final status = _assignmentData!['status'] as String? ?? 'unknown';
    final statusColor = _getStatusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.assignment,
            size: DesignTokens.iconSizeM,
            color: colorScheme.primary,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXS,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              _getStatusText(status),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
          if (widget.onAssignmentTap != null) ...[
            SizedBox(width: DesignTokens.spacingS),
            UnifiedButton.icon(
              icon: Icons.open_in_new,
              onPressed: widget.onAssignmentTap!,
              size: UnifiedButtonSize.small,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullView() {
    if (_assignmentData == null) return const SizedBox.shrink();

    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    final title = _assignmentData!['title'] as String? ?? 'Opdracht';
    final description = _assignmentData!['description'] as String? ?? '';
    final location = _assignmentData!['location'] as String? ?? 'Locatie onbekend';
    final status = _assignmentData!['status'] as String? ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    // Parse dates
    DateTime? startDate;
    DateTime? endDate;
    
    if (_assignmentData!['startDate'] != null) {
      if (_assignmentData!['startDate'] is Timestamp) {
        startDate = (_assignmentData!['startDate'] as Timestamp).toDate();
      } else if (_assignmentData!['startDate'] is String) {
        startDate = DateTime.tryParse(_assignmentData!['startDate']);
      }
    }
    
    if (_assignmentData!['endDate'] != null) {
      if (_assignmentData!['endDate'] is Timestamp) {
        endDate = (_assignmentData!['endDate'] as Timestamp).toDate();
      } else if (_assignmentData!['endDate'] is String) {
        endDate = DateTime.tryParse(_assignmentData!['endDate']);
      }
    }

    return UnifiedCard.standard(
      margin: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and status
          Row(
            children: [
              Icon(
                Icons.assignment,
                size: DesignTokens.iconSizeL,
                color: colorScheme.primary,
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Row(
                      children: [
                        Icon(
                          statusIcon,
                          size: DesignTokens.iconSizeS,
                          color: statusColor,
                        ),
                        SizedBox(width: DesignTokens.spacingXS),
                        Text(
                          _getStatusText(status),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: DesignTokens.fontWeightMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.onAssignmentTap != null)
                UnifiedButton.icon(
                  icon: Icons.open_in_new,
                  onPressed: widget.onAssignmentTap!,
                  size: UnifiedButtonSize.small,
                ),
            ],
          ),
          
          if (description.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spacingM),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Assignment details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.location_on,
                  label: 'Locatie',
                  value: location,
                ),
              ),
            ],
          ),
          
          if (startDate != null) ...[
            SizedBox(height: DesignTokens.spacingS),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.schedule,
                    label: 'Start',
                    value: '${_formatDutchDate(startDate)} om ${_formatDutchTime(startDate)}',
                  ),
                ),
                if (endDate != null)
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.schedule,
                      label: 'Eind',
                      value: '${_formatDutchDate(endDate)} om ${_formatDutchTime(endDate)}',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Row(
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeS,
          color: colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Center(
          child: CircularProgressIndicator(
            color: SecuryFlexTheme.getColorScheme(widget.userRole).primary,
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: DesignTokens.statusCancelled,
              size: DesignTokens.iconSizeM,
            ),
            SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.statusCancelled,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return widget.isCompact ? _buildCompactView() : _buildFullView();
  }
}
