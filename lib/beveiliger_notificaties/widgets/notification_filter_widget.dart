import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../models/guard_notification.dart';

/// Notification filter widget with chip-based category selection
/// 
/// Features:
/// - Category-based filtering (Jobs, Certificaten, Betalingen, Systeem)
/// - Chip-style selectable filters with guard theming
/// - "Alle" option to clear filters
/// - Scrollable horizontal layout for mobile
/// - Visual feedback for active selections
/// - Integration with existing filter patterns from marketplace
class NotificationFilterWidget extends StatelessWidget {
  final GuardNotificationType? selectedFilter;
  final Function(GuardNotificationType?) onFilterChanged;
  final UserRole userRole;

  const NotificationFilterWidget({
    super.key,
    this.selectedFilter,
    required this.onFilterChanged,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter label
        Text(
          'Filter notificaties',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightMedium,
            fontFamily: DesignTokens.fontFamily,
            color: colorScheme.onSurface,
          ),
        ),
        
        SizedBox(height: DesignTokens.spacingS),
        
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // "Alle" chip
              _buildFilterChip(
                context,
                colorScheme,
                label: 'Alle',
                isSelected: selectedFilter == null,
                onTap: () => onFilterChanged(null),
                icon: Icons.notifications_outlined,
              ),
              
              SizedBox(width: DesignTokens.spacingS),
              
              // Job opportunities filter
              _buildFilterChip(
                context,
                colorScheme,
                label: 'Jobs',
                isSelected: selectedFilter == GuardNotificationType.jobOpportunity,
                onTap: () => onFilterChanged(GuardNotificationType.jobOpportunity),
                icon: Icons.work_outline,
                color: DesignTokens.guardPrimary,
              ),
              
              SizedBox(width: DesignTokens.spacingS),
              
              // Certificates filter
              _buildFilterChip(
                context,
                colorScheme,
                label: 'Certificaten',
                isSelected: selectedFilter == GuardNotificationType.certificateExpiry,
                onTap: () => onFilterChanged(GuardNotificationType.certificateExpiry),
                icon: Icons.badge_outlined,
                color: DesignTokens.colorWarning,
              ),
              
              SizedBox(width: DesignTokens.spacingS),
              
              // Payments filter
              _buildFilterChip(
                context,
                colorScheme,
                label: 'Betalingen',
                isSelected: selectedFilter == GuardNotificationType.paymentUpdate,
                onTap: () => onFilterChanged(GuardNotificationType.paymentUpdate),
                icon: Icons.payment_outlined,
                color: DesignTokens.colorSuccess,
              ),
              
              SizedBox(width: DesignTokens.spacingS),
              
              // System updates filter
              _buildFilterChip(
                context,
                colorScheme,
                label: 'Systeem',
                isSelected: selectedFilter == GuardNotificationType.systemUpdate,
                onTap: () => onFilterChanged(GuardNotificationType.systemUpdate),
                icon: Icons.system_update_outlined,
                color: DesignTokens.colorInfo,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    ColorScheme colorScheme, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    Color? color,
  }) {
    final chipColor = color ?? colorScheme.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXXL),
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? chipColor
                : chipColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXXL),
            border: Border.all(
              color: isSelected 
                  ? chipColor
                  : chipColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: chipColor.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: DesignTokens.iconSizeS,
                color: isSelected 
                    ? DesignTokens.colorWhite 
                    : chipColor,
              ),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                label,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: isSelected 
                      ? DesignTokens.fontWeightSemiBold 
                      : DesignTokens.fontWeightMedium,
                  fontFamily: DesignTokens.fontFamily,
                  color: isSelected 
                      ? DesignTokens.colorWhite 
                      : chipColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}