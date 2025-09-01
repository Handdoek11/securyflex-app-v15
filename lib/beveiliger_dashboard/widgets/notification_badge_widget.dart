import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import '../../core/shared_animation_controller.dart';

/// Notification Badge Widget for the dashboard app bar
/// 
/// Features:
/// - Badge count display for unread notifications
/// - Different notification types (messages, alerts, updates)
/// - Dutch notification descriptions
/// - Visual priority indicators
/// - Tap to open notification center
/// - Real-time updates with animation
/// - Accessibility support
class NotificationBadgeWidget extends StatefulWidget {
  final int unreadCount;
  final VoidCallback? onTap;
  final bool hasHighPriority;

  const NotificationBadgeWidget({
    super.key,
    this.unreadCount = 3, // Mock data for demo
    this.onTap,
    this.hasHighPriority = false,
  });

  @override
  State<NotificationBadgeWidget> createState() => _NotificationBadgeWidgetState();
}

class _NotificationBadgeWidgetState extends State<NotificationBadgeWidget>
    with TickerProviderStateMixin {
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    // Use shared animation controllers
    
    
    _pulseAnimation = SharedAnimationController.instance.getAnimation<double>(
      SharedControllerKeys.badgePulse,
      1.0,
      1.2,
      curve: Curves.easeInOut,
    );
    
    _bounceAnimation = SharedAnimationController.instance.getAnimation<double>(
      SharedControllerKeys.badgeBounce,
      1.0,
      1.1,
      curve: Curves.elasticOut,
    );
    
    // Start animations if there are notifications
    if (widget.unreadCount > 0) {
      if (widget.hasHighPriority) {
        SharedAnimationController.instance.startAnimation(SharedControllerKeys.badgePulse, mode: AnimationMode.repeatReverse);
      }
    }
    
    debugPrint('🔧 NotificationBadge: Using shared animation controllers');
  }

  @override
  void didUpdateWidget(NotificationBadgeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger bounce animation when count increases
    if (widget.unreadCount > oldWidget.unreadCount) {
      SharedAnimationController.instance.resetAnimation(SharedControllerKeys.badgeBounce);
      SharedAnimationController.instance.startAnimation(SharedControllerKeys.badgeBounce);
    }
    
    // Handle priority animation
    if (widget.hasHighPriority != oldWidget.hasHighPriority) {
      if (widget.hasHighPriority) {
        SharedAnimationController.instance.startAnimation(SharedControllerKeys.badgePulse, mode: AnimationMode.repeatReverse);
      } else {
        SharedAnimationController.instance.stopAnimation(SharedControllerKeys.badgePulse);
        SharedAnimationController.instance.resetAnimation(SharedControllerKeys.badgePulse);
      }
    }
  }

  @override
  void dispose() {
    // Release shared controllers
    SharedAnimationController.instance.releaseController(SharedControllerKeys.badgePulse, 'badge_pulse');
    SharedAnimationController.instance.releaseController(SharedControllerKeys.badgeBounce, 'badge_bounce');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _bounceAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.hasHighPriority 
              ? _pulseAnimation.value 
              : _bounceAnimation.value,
          child: Stack(
            children: [
              // Notification bell icon
              IconButton(
                onPressed: widget.onTap ?? _showNotificationPanel,
                icon: Icon(
                  widget.unreadCount > 0 
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: widget.unreadCount > 0 
                      ? colorScheme.primary 
                      : colorScheme.onSurfaceVariant,
                  size: DesignTokens.iconSizeL,
                ),
                tooltip: widget.unreadCount > 0 
                    ? '${widget.unreadCount} nieuwe notificaties'
                    : 'Geen nieuwe notificaties',
              ),
              
              // Badge count
              if (widget.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    decoration: BoxDecoration(
                      color: widget.hasHighPriority 
                          ? DesignTokens.colorError 
                          : DesignTokens.colorWarning,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: DesignTokens.colorWhite,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightBold,
                        fontSize: DesignTokens.fontSizeCaption,
                        color: DesignTokens.colorWhite,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => const NotificationPanelWidget(),
    );
  }
}

/// Notification Panel Widget that shows in a bottom sheet
class NotificationPanelWidget extends StatelessWidget {
  const NotificationPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Material(
      elevation: DesignTokens.elevationLevel6,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.primary.withValues(alpha: DesignTokens.surfaceTintAlphaLevel6),
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radiusXL),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeL,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Notificaties',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontSize: DesignTokens.fontSizeTitleLarge,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Sluiten'),
                ),
              ],
            ),
          ),
          
          // Notifications list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
              children: [
                _buildNotificationItem(
                  colorScheme,
                  'Nieuwe shift beschikbaar',
                  'Avonddienst bij Schiphol Airport - €18/uur',
                  Icons.work,
                  DesignTokens.colorSuccess,
                  '5 min geleden',
                  isHighPriority: false,
                ),
                
                _buildNotificationItem(
                  colorScheme,
                  'Compliance waarschuwing',
                  'Je hebt deze week al 44 uur gewerkt',
                  Icons.warning,
                  DesignTokens.colorWarning,
                  '1 uur geleden',
                  isHighPriority: true,
                ),
                
                _buildNotificationItem(
                  colorScheme,
                  'Beoordeling ontvangen',
                  'ABC Security heeft je 5 sterren gegeven!',
                  Icons.star,
                  DesignTokens.colorSuccess,
                  '2 uur geleden',
                  isHighPriority: false,
                ),
                
                _buildNotificationItem(
                  colorScheme,
                  'Certificaat verloopt binnenkort',
                  'Je WPBR certificaat verloopt over 30 dagen',
                  Icons.card_membership,
                  DesignTokens.colorError,
                  '1 dag geleden',
                  isHighPriority: true,
                ),
                
                _buildNotificationItem(
                  colorScheme,
                  'Betaling verwerkt',
                  'Salaris week 33 is overgemaakt (€674,50)',
                  Icons.payments,
                  DesignTokens.colorSuccess,
                  '2 dagen geleden',
                  isHighPriority: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    ColorScheme colorScheme,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    String time, {
    bool isHighPriority = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingM),
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: isHighPriority 
            ? iconColor.withValues(alpha: 0.05)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: isHighPriority 
            ? Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: DesignTokens.iconSizeL,
            ),
          ),
          
          const SizedBox(width: DesignTokens.spacingM),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontSize: DesignTokens.fontSizeBody,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isHighPriority) ...[
                      const SizedBox(width: DesignTokens.spacingS),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: iconColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: DesignTokens.spacingXS),
                
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightRegular,
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                
                const SizedBox(height: DesignTokens.spacingXS),
                
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightRegular,
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}