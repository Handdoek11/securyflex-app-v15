import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/premium_typography_system.dart';
import '../../unified_components/premium_glass_system.dart';
import '../../beveiliger_notificaties/models/guard_notification.dart';

/// Notifications summary section for guards dashboard
/// 
/// Features:
/// - Recent notifications display (max 3 notifications)
/// - Unread count indicator with security badge styling
/// - Professional notification hierarchy and typography
/// - Premium glass container with trust-building design
/// - Navigation to full notification center
/// 
/// Uses PremiumTypography for consistent text hierarchy and
/// PremiumGlassContainer for professional appearance
class NotificationsSummarySection extends StatelessWidget {
  final List<GuardNotification> recentNotifications;
  final int unreadCount;
  final bool isLoading;
  final VoidCallback onNavigateToNotificationCenter;

  const NotificationsSummarySection({
    super.key,
    required this.recentNotifications,
    required this.unreadCount,
    required this.isLoading,
    required this.onNavigateToNotificationCenter,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 NotificationsSummarySection: loading=$isLoading, notifications=${recentNotifications.length}, unread=$unreadCount');
    
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Container(
      margin: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title outside the container (same style as other sections)
          Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notificaties',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeTitle,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.colorError,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeCaption,
                        fontWeight: DesignTokens.fontWeightBold,
                        color: Colors.white,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Premium glass content section
          PremiumGlassContainer(
            intensity: GlassIntensity.standard,
            elevation: GlassElevation.floating,
            tintColor: unreadCount > 0 ? DesignTokens.colorError : DesignTokens.guardPrimary,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            enableTrustBorder: true,
            child: isLoading
                ? _buildLoadingState()
                : recentNotifications.isNotEmpty
                    ? _buildNotificationsList(context)
                    : _buildNoNotifications(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Container(
      height: 80,
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: DesignTokens.guardPrimary,
        ),
      ),
    );
  }
  
  Widget _buildNoNotifications(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingXL),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            size: 32,
            color: SecuryFlexTheme.getColorScheme(UserRole.guard).onSurfaceVariant.withValues(alpha: 0.6),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Geen nieuwe notificaties',
            style: PremiumTypography.bodySecondary(
              context,
              role: UserRole.guard,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationsList(BuildContext context) {
    return Column(
      children: [
        ...recentNotifications.take(3).map((notification) => 
          _buildProfessionalNotificationItem(context, notification)
        ),
        
        // Professional "show all" button
        InkWell(
          onTap: onNavigateToNotificationCenter,
          child: Container(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bekijk alle notificaties',
                  style: PremiumTypography.professionalCaption(
                    context,
                    color: DesignTokens.guardPrimary,
                    role: UserRole.guard,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: DesignTokens.guardPrimary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildProfessionalNotificationItem(BuildContext context, GuardNotification notification) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Professional unread indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: notification.isRead 
                  ? Colors.transparent 
                  : DesignTokens.guardPrimary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: DesignTokens.spacingS),
          
          // Content with professional typography
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: notification.isRead
                      ? PremiumTypography.bodySecondary(
                          context,
                          role: UserRole.guard,
                        )
                      : PremiumTypography.bodyEmphasis(
                          context,
                          role: UserRole.guard,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notification.body.isNotEmpty)
                  Text(
                    notification.body,
                    style: PremiumTypography.metadata(
                      context,
                      role: UserRole.guard,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          
          // Professional timestamp
          Text(
            _getRelativeTime(notification.timestamp),
            style: PremiumTypography.metadata(
              context,
              role: UserRole.guard,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'nu';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}u';
    } else {
      return '${difference.inDays}d';
    }
  }
}