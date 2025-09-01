import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../unified_card_system.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/smart_badge_overlay.dart';
import '../models/guard_notification.dart';

/// Individual notification item widget with swipe actions and unified design
/// 
/// Features:
/// - Unified card design with role-based theming
/// - Smart badge for unread notifications
/// - Icon system for notification types
/// - Swipe-to-delete functionality
/// - Color coding by notification priority
/// - Accessibility support
/// - Dutch localization
class NotificationItemWidget extends StatefulWidget {
  final GuardNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final UserRole userRole;
  final bool showSwipeActions;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
    required this.userRole,
    this.showSwipeActions = true,
  });

  @override
  State<NotificationItemWidget> createState() => _NotificationItemWidgetState();
}

class _NotificationItemWidgetState extends State<NotificationItemWidget>
    with SingleTickerProviderStateMixin {

  late AnimationController _swipeController;
  late Animation<Offset> _slideAnimation;
  
  bool _isSwipeInProgress = false;
  double _swipeProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _swipeController = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ));
  }

  void _handleSwipeStart(DragStartDetails details) {
    if (!widget.showSwipeActions) return;
    _isSwipeInProgress = true;
  }

  void _handleSwipeUpdate(DragUpdateDetails details) {
    if (!widget.showSwipeActions || !_isSwipeInProgress) return;
    
    final progress = (details.delta.dx / context.size!.width).clamp(-1.0, 0.0);
    setState(() {
      _swipeProgress = (_swipeProgress + progress).clamp(-1.0, 0.0);
    });
  }

  void _handleSwipeEnd(DragEndDetails details) {
    if (!widget.showSwipeActions || !_isSwipeInProgress) return;
    
    _isSwipeInProgress = false;
    
    if (_swipeProgress < -0.3) {
      // Complete swipe to delete
      _swipeController.forward().then((_) {
        widget.onDelete();
      });
    } else {
      // Snap back
      setState(() {
        _swipeProgress = 0.0;
      });
    }
  }

  IconData _getNotificationIcon() {
    switch (widget.notification.type) {
      case GuardNotificationType.jobOpportunity:
        return Icons.work_outline;
      case GuardNotificationType.shiftReminder:
        return Icons.schedule_outlined;
      case GuardNotificationType.paymentUpdate:
        return Icons.payment_outlined;
      case GuardNotificationType.certificateExpiry:
        return Icons.badge_outlined;
      case GuardNotificationType.emergencyAlert:
        return Icons.warning_outlined;
      case GuardNotificationType.systemUpdate:
        return Icons.system_update_outlined;
      case GuardNotificationType.profileUpdate:
        return Icons.person_outline;
      case GuardNotificationType.applicationAccepted:
        return Icons.check_circle_outline;
      case GuardNotificationType.applicationRejected:
        return Icons.info_outline;
      case GuardNotificationType.jobUpdate:
        return Icons.work_history_outlined;
    }
  }

  Color _getNotificationColor() {
    switch (widget.notification.priority) {
      case NotificationPriority.urgent:
        return DesignTokens.colorError;
      case NotificationPriority.high:
        return DesignTokens.colorWarning;
      case NotificationPriority.medium:
        return DesignTokens.guardPrimary;
      case NotificationPriority.low:
        return DesignTokens.colorSuccess;
    }
  }

  Color _getTypeColor() {
    switch (widget.notification.type) {
      case GuardNotificationType.jobOpportunity:
        return DesignTokens.guardPrimary;
      case GuardNotificationType.shiftReminder:
        return DesignTokens.colorInfo;
      case GuardNotificationType.paymentUpdate:
        return DesignTokens.colorSuccess;
      case GuardNotificationType.certificateExpiry:
        return DesignTokens.colorWarning;
      case GuardNotificationType.emergencyAlert:
        return DesignTokens.colorError;
      case GuardNotificationType.systemUpdate:
        return DesignTokens.colorInfo;
      case GuardNotificationType.profileUpdate:
        return DesignTokens.guardPrimary;
      case GuardNotificationType.applicationAccepted:
        return DesignTokens.colorSuccess;
      case GuardNotificationType.applicationRejected:
        return DesignTokens.colorWarning;
      case GuardNotificationType.jobUpdate:
        return DesignTokens.colorInfo;
    }
  }

  String _getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(widget.notification.timestamp);

    if (difference.inMinutes < 1) {
      return 'Nu';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m geleden';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}u geleden';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d geleden';
    } else {
      final date = widget.notification.timestamp;
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    Widget notificationCard = UnifiedCard.standard(
      userRole: widget.userRole,
      isClickable: true,
      onTap: widget.onTap,
      backgroundColor: widget.notification.isRead 
          ? colorScheme.surface
          : colorScheme.surfaceContainer,
      child: _buildNotificationContent(colorScheme),
    );

    // Add unread badge for unread notifications
    if (!widget.notification.isRead) {
      notificationCard = SmartBadgeOverlay(
        badgeCount: 1,
        badgeType: _getBadgeType(),
        position: BadgePosition.topRight,
        animate: true,
        child: notificationCard,
      );
    }

    // Add swipe functionality if enabled
    if (widget.showSwipeActions) {
      return _buildSwipeableCard(notificationCard);
    }

    return notificationCard;
  }

  Widget _buildNotificationContent(ColorScheme colorScheme) {
    final notificationColor = _getTypeColor();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon with color indicator
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: notificationColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            _getNotificationIcon(),
            color: notificationColor,
            size: DesignTokens.iconSizeM,
          ),
        ),
        
        SizedBox(width: DesignTokens.spacingM),
        
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and timestamp row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.notification.title,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: widget.notification.isRead 
                            ? DesignTokens.fontWeightMedium 
                            : DesignTokens.fontWeightSemiBold,
                        fontFamily: DesignTokens.fontFamily,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  SizedBox(width: DesignTokens.spacingS),
                  
                  // Timestamp
                  Text(
                    _getRelativeTime(),
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamily,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: DesignTokens.spacingXS),
              
              // Body text
              Text(
                widget.notification.body,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  fontFamily: DesignTokens.fontFamily,
                  color: widget.notification.isRead 
                      ? colorScheme.onSurfaceVariant 
                      : colorScheme.onSurface,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Priority indicator for urgent notifications
              if (widget.notification.priority == NotificationPriority.urgent) ...[
                SizedBox(height: DesignTokens.spacingS),
                _buildUrgentIndicator(colorScheme),
              ],
              
              // Expiry indicator if notification expires soon
              if (widget.notification.expiresAt != null && 
                  !widget.notification.isExpired) ...[
                SizedBox(height: DesignTokens.spacingS),
                _buildExpiryIndicator(colorScheme),
              ],
              
              // Action buttons if available
              if (widget.notification.actionButtons != null &&
                  widget.notification.actionButtons!.isNotEmpty) ...[
                SizedBox(height: DesignTokens.spacingM),
                _buildActionButtons(colorScheme),
              ],
            ],
          ),
        ),
        
        // Read status indicator
        if (!widget.notification.isRead)
          Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.only(left: DesignTokens.spacingS, top: 4),
            decoration: BoxDecoration(
              color: _getNotificationColor(),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _buildUrgentIndicator(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: DesignTokens.colorError.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.priority_high,
            size: DesignTokens.iconSizeXS,
            color: DesignTokens.colorError,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            'Urgent',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightMedium,
              fontFamily: DesignTokens.fontFamily,
              color: DesignTokens.colorError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryIndicator(ColorScheme colorScheme) {
    final timeUntilExpiry = widget.notification.timeUntilExpiry;
    if (timeUntilExpiry == null) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule_outlined,
          size: DesignTokens.iconSizeXS,
          color: DesignTokens.colorWarning,
        ),
        SizedBox(width: DesignTokens.spacingXS),
        Text(
          timeUntilExpiry,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            fontFamily: DesignTokens.fontFamily,
            color: DesignTokens.colorWarning,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    final actions = widget.notification.actionButtons!;
    
    return Row(
      children: actions.entries.take(2).map((entry) {
        final isFirst = actions.entries.first.key == entry.key;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: isFirst ? DesignTokens.spacingS : 0,
            ),
            child: OutlinedButton(
              onPressed: () => _handleActionTap(entry.key),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeCaption,
                  fontFamily: DesignTokens.fontFamily,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSwipeableCard(Widget card) {
    return GestureDetector(
      onPanStart: _handleSwipeStart,
      onPanUpdate: _handleSwipeUpdate,
      onPanEnd: _handleSwipeEnd,
      child: Stack(
        children: [
          // Delete action background
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: DesignTokens.spacingL),
              decoration: BoxDecoration(
                color: DesignTokens.colorError,
                borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: DesignTokens.colorWhite,
                    size: DesignTokens.iconSizeM,
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Text(
                    'Verwijder',
                    style: TextStyle(
                      color: DesignTokens.colorWhite,
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightMedium,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main card with slide animation
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_swipeProgress * MediaQuery.of(context).size.width, 0),
                child: card,
              );
            },
          ),
        ],
      ),
    );
  }

  BadgeType _getBadgeType() {
    switch (widget.notification.priority) {
      case NotificationPriority.urgent:
        return BadgeType.urgent;
      case NotificationPriority.high:
        return BadgeType.warning;
      case NotificationPriority.medium:
        return BadgeType.info;
      case NotificationPriority.low:
        return BadgeType.success;
    }
  }

  void _handleActionTap(String actionKey) {
    // Handle different action types
    switch (actionKey) {
      case 'view':
      case 'details':
      case 'checkin':
        widget.onTap();
        break;
      case 'apply':
      case 'renew':
      case 'courses':
        widget.onTap();
        break;
      case 'dismiss':
        widget.onDelete();
        break;
      case 'remind':
      case 'later':
        // TODO: Implement snooze functionality
        _showSnoozeDialog();
        break;
      default:
        widget.onTap();
    }
  }

  void _showSnoozeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Herinnering instellen',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        content: Text(
          'Wanneer wil je opnieuw herinnerd worden?',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Annuleren',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              // TODO: Implement 1 hour snooze
            },
            child: Text(
              '1 uur',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              // TODO: Implement 1 day snooze
            },
            child: Text(
              '1 dag',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}