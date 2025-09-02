import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_buttons.dart';

/// Notification type enumeration for different security alerts
enum NotificationType {
  info,
  warning,
  alert,
}

/// Security notification data model
class SecurityNotification {
  final String title;
  final String description;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  const SecurityNotification({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

/// Recent Notifications Dashboard Card Widget
/// 
/// Displays the 3 most recent security notifications with proper styling
/// following SecuryFlex design rules and unified system patterns.
class RecentNotificationsWidget extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;

  const RecentNotificationsWidget({
    super.key,
    this.animationController,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final guardColorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    final textTheme = Theme.of(context).textTheme;

    // Sample notification data - in real app this would come from a service
    final notifications = _getSampleNotifications();

    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 30 * (1.0 - animation!.value), 0.0),
            child: Padding(
              padding: EdgeInsets.only(
                  left: DesignTokens.spacingL,
                  right: DesignTokens.spacingL,
                  top: DesignTokens.spacingM,
                  bottom: DesignTokens.spacingM + 2), // 18px = 16px + 2px
              child: UnifiedCard(
                variant: UnifiedCardVariant.standard,
                userRole: UserRole.guard,
                margin: EdgeInsets.zero,
                backgroundColor: guardColorScheme.surface,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(DesignTokens.radiusCard),
                    bottomLeft: Radius.circular(DesignTokens.radiusCard),
                    bottomRight: Radius.circular(DesignTokens.radiusCard),
                    topRight: Radius.circular(68.0)), // Preserve unique design element
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Header Section
                    Padding(
                      padding: EdgeInsets.only(
                          top: DesignTokens.spacingM,
                          left: DesignTokens.spacingL,
                          right: DesignTokens.spacingL,
                          bottom: DesignTokens.spacingS),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recente Meldingen',
                            textAlign: TextAlign.left,
                            style: textTheme.titleMedium?.copyWith(
                              fontFamily: DesignTokens.fontFamily,
                              fontWeight: DesignTokens.fontWeightSemiBold,
                              color: guardColorScheme.onSurface,
                            ),
                          ),
                          Icon(
                            Icons.notifications_outlined,
                            size: DesignTokens.iconSizeM,
                            color: guardColorScheme.primary,
                          ),
                        ],
                      ),
                    ),

                    // Notifications List
                    ...notifications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final notification = entry.value;
                      return _buildNotificationItem(
                        context,
                        notification,
                        guardColorScheme,
                        isLast: index == notifications.length - 1,
                      );
                    }),

                    // Divider
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingL,
                          vertical: DesignTokens.spacingS),
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          color: guardColorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
                        ),
                      ),
                    ),

                    // Action Button
                    Padding(
                      padding: EdgeInsets.only(
                          left: DesignTokens.spacingL,
                          right: DesignTokens.spacingL,
                          bottom: DesignTokens.spacingM),
                      child: SizedBox(
                        width: double.infinity,
                        child: UnifiedButton.text(
                          text: 'Bekijk Alle',
                          onPressed: () {
                            // Navigate to notification center
                            context.push('/notifications');
                          },
                          size: UnifiedButtonSize.small,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build individual notification item
  Widget _buildNotificationItem(
    BuildContext context,
    SecurityNotification notification,
    ColorScheme colorScheme,
    {required bool isLast}
  ) {
    final notificationColor = _getNotificationColor(notification.type);
    final notificationIcon = _getNotificationIcon(notification.type);
    
    // Create accessible label for notification
    final typeLabel = notification.type == NotificationType.info ? 'Informatie' :
                     notification.type == NotificationType.warning ? 'Waarschuwing' : 'Alert';
    final accessibilityLabel = '$typeLabel melding: ${notification.title}. ${notification.description}. ${_formatTimeAgo(notification.timestamp)}';

    return Semantics(
      label: accessibilityLabel,
      button: true,
      enabled: true,
      hint: 'Dubbeltik om melding te openen',
      onTap: () {
        // Handle notification tap
      },
      child: Padding(
        padding: EdgeInsets.only(
            left: DesignTokens.spacingL,
            right: DesignTokens.spacingL,
            bottom: isLast ? 0 : DesignTokens.spacingM),
        child: Container(
          // Ensure minimum touch target size (44x44)
          constraints: BoxConstraints(
            minHeight: 44.0,
            minWidth: double.infinity,
          ),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Container(
            margin: EdgeInsets.only(top: DesignTokens.spacingXS),
            child: Icon(
              notificationIcon,
              size: DesignTokens.iconSizeM,
              color: notificationColor,
            ),
          ),
          
          SizedBox(width: DesignTokens.spacingM),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.fontWeightMedium,
                          fontSize: DesignTokens.fontSizeBody,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(notification.timestamp),
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightRegular,
                        fontSize: DesignTokens.fontSizeS,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: DesignTokens.spacingXS),
                
                Text(
                  notification.description,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightRegular,
                    fontSize: DesignTokens.fontSizeS,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                if (!notification.isRead) ...[
                  SizedBox(height: DesignTokens.spacingXS),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        ),
      ),
      ),
    );
  }

  /// Format timestamp to human-readable time ago string
  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Zojuist';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minuten geleden';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} uur geleden';
    } else {
      return '${difference.inDays} dagen geleden';
    }
  }

  /// Get color for notification type
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return DesignTokens.colorInfo;
      case NotificationType.warning:
        return DesignTokens.colorWarning;
      case NotificationType.alert:
        return DesignTokens.colorError;
    }
  }

  /// Get icon for notification type
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.alert:
        return Icons.error_outline;
    }
  }

  /// Format timestamp for display
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}u';
    } else {
      return '${difference.inDays}d';
    }
  }

  /// Sample notification data for demonstration
  List<SecurityNotification> _getSampleNotifications() {
    final now = DateTime.now();
    return [
      SecurityNotification(
        title: 'Nieuwe beveiligingsopdracht',
        description: 'Objectbeveiliging bij Amsterdam Centraal beschikbaar voor morgen 08:00',
        timestamp: now.subtract(Duration(minutes: 15)),
        type: NotificationType.info,
        isRead: false,
      ),
      SecurityNotification(
        title: 'Wijziging in planning',
        description: 'Dienst van 14:00-22:00 bij SecureMax B.V. is verplaatst naar donderdag',
        timestamp: now.subtract(Duration(hours: 2)),
        type: NotificationType.warning,
        isRead: true,
      ),
      SecurityNotification(
        title: 'Urgente oproep',
        description: 'Directe vervanging nodig voor nachtdienst in Rotterdam Haven',
        timestamp: now.subtract(Duration(hours: 4)),
        type: NotificationType.alert,
        isRead: false,
      ),
    ];
  }
}
