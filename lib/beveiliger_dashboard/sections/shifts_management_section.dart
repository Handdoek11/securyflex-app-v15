import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/premium_typography_system.dart';
import '../../unified_components/premium_glass_system.dart';
import '../models/enhanced_dashboard_data.dart' as dashboard_models;

/// Shifts management section for guards dashboard
/// 
/// Features:
/// - Current shifts display with status indicators
/// - Dutch localization for shift statuses
/// - Premium typography and glass system integration
/// - Horizontal scrolling layout for better UX
/// - Maximum 5 shifts displayed for dashboard overview
/// 
/// Uses PremiumTypography and PremiumGlassContainer for consistent styling
class ShiftsManagementSection extends StatelessWidget {
  final List<dashboard_models.EnhancedShiftData> shifts;

  const ShiftsManagementSection({
    super.key,
    required this.shifts,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 ShiftsManagementSection: shifts count=${shifts.length}');
    
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with horizontal padding to align with other content
        Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.spacingM,
            right: DesignTokens.spacingM,
            bottom: DesignTokens.spacingM,
          ),
          child: Text(
              'Huidige diensten',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          
          // Horizontal scrolling premium glass cards
          SizedBox(
            height: 140,
            child: shifts.isEmpty 
                ? _buildEmptyShiftsState(context, colorScheme)
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: shifts.take(5).length,
                    itemBuilder: (context, index) {
                      final shift = shifts[index];
                      return Container(
                        width: screenWidth * 0.75, // 75% of screen width
                        margin: EdgeInsets.only(
                          right: index == shifts.take(5).length - 1 ? 0 : DesignTokens.spacingM,
                        ),
                        child: _buildPremiumShiftCard(context, shift, colorScheme),
                      );
                    },
                  ),
          ),
        ],
      );
  }

  Widget _buildEmptyShiftsState(BuildContext context, ColorScheme colorScheme) {
    return PremiumGlassContainer(
      intensity: GlassIntensity.subtle,
      elevation: GlassElevation.surface,
      tintColor: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 32,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              'Geen actieve diensten',
              style: PremiumTypography.bodySecondary(
                context,
                role: UserRole.guard,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumShiftCard(BuildContext context, dashboard_models.EnhancedShiftData shift, ColorScheme colorScheme) {
    final statusColor = _getStatusColor(shift.status);
    final statusIcon = _getStatusIcon(shift.status);
    
    return PremiumGlassContainer(
      intensity: GlassIntensity.standard,
      elevation: GlassElevation.floating,
      tintColor: statusColor,
      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      padding: EdgeInsets.all(DesignTokens.spacingM),
      enableTrustBorder: true,
      onTap: () {
        // Navigate to shift details
        Navigator.pushNamed(
          context, 
          '/shift-details', 
          arguments: {'shiftId': shift.id, 'shift': shift}
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Professional status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 10,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      shift.dutchStatusText,
                      style: PremiumTypography.securityBadge(
                        context,
                        color: Colors.white,
                        isActive: true,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
          
          // Content with professional typography
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  shift.title,
                  style: PremiumTypography.bodyEmphasis(
                    context,
                    role: UserRole.guard,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  shift.companyName,
                  style: PremiumTypography.bodySecondary(
                    context,
                    role: UserRole.guard,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Footer: Time with professional styling
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 12,
                color: colorScheme.primary,
              ),
              SizedBox(width: 4),
              Text(
                shift.dutchTimeRange,
                style: PremiumTypography.professionalCaption(
                  context,
                  color: colorScheme.primary,
                  role: UserRole.guard,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(dashboard_models.ShiftStatus status) {
    switch (status) {
      case dashboard_models.ShiftStatus.inProgress:
        return DesignTokens.colorSuccess;
      case dashboard_models.ShiftStatus.confirmed:
        return DesignTokens.colorInfo;
      case dashboard_models.ShiftStatus.pending:
        return DesignTokens.colorWarning;
      case dashboard_models.ShiftStatus.completed:
        return DesignTokens.guardPrimary;
      case dashboard_models.ShiftStatus.cancelled:
        return DesignTokens.colorError;
    }
  }
  
  IconData _getStatusIcon(dashboard_models.ShiftStatus status) {
    switch (status) {
      case dashboard_models.ShiftStatus.inProgress:
        return Icons.play_circle_outline;
      case dashboard_models.ShiftStatus.confirmed:
        return Icons.check_circle_outline;
      case dashboard_models.ShiftStatus.pending:
        return Icons.hourglass_empty;
      case dashboard_models.ShiftStatus.completed:
        return Icons.done_all;
      case dashboard_models.ShiftStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}