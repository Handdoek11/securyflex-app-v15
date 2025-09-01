import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../unified_header.dart';
import '../../unified_theme_system.dart';
import '../../unified_design_tokens.dart';
import '../../unified_card_system.dart';
import '../../unified_buttons.dart';
import '../../unified_components/unified_background_service.dart';
import '../bloc/notification_center_bloc.dart';
import '../models/guard_notification.dart';
import '../widgets/notification_item_widget.dart';
import '../widgets/notification_filter_widget.dart';
import 'notification_preferences_screen.dart';
import '../../routing/app_routes.dart';

/// Comprehensive notification center for SecuryFlex guards
/// 
/// Features:
/// - Categorized notifications (Jobs, Certificaten, Betalingen, Systeem)
/// - Pull-to-refresh with loading states
/// - Mark all as read functionality
/// - Empty state handling with guidance
/// - Integration with GuardNotificationService
/// - Full unified design system integration
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late ScrollController _scrollController;
  
  // Filter state
  GuardNotificationType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    _scrollController = ScrollController();
    _animationController.forward();
  }

  void _loadNotifications() {
    context.read<NotificationCenterBloc>().add(const LoadNotifications());
  }

  Future<void> _refreshNotifications() async {
    context.read<NotificationCenterBloc>().add(const RefreshNotifications());
    // Add delay for better UX
    await Future.delayed(DesignTokens.durationMedium);
  }

  void _onFilterChanged(GuardNotificationType? filter) {
    setState(() {
      _selectedFilter = filter;
    });
    context.read<NotificationCenterBloc>().add(FilterNotifications(filter));
  }

  void _markAllAsRead() {
    context.read<NotificationCenterBloc>().add(const MarkAllAsRead());
    _showSnackBar('Alle notificaties gemarkeerd als gelezen');
  }

  void _onNotificationTap(GuardNotification notification) {
    // Mark as read when tapped
    if (!notification.isRead) {
      context.read<NotificationCenterBloc>().add(
        MarkAsRead(notification.id),
      );
    }

    // Navigate to action URL if available
    if (notification.actionUrl != null) {
      _navigateToActionUrl(notification.actionUrl!);
    }
  }

  void _onNotificationDelete(String notificationId) {
    context.read<NotificationCenterBloc>().add(
      DeleteNotification(notificationId),
    );
    _showSnackBar('Notificatie verwijderd');
  }

  void _navigateToActionUrl(String actionUrl) {
    // Parse and navigate to action URL
    if (actionUrl.startsWith('/marketplace/job/')) {
      // Navigate to job details
      final jobId = actionUrl.split('/').last;
      context.go('${AppRoutes.beveiligerJobs}/$jobId');
    } else if (actionUrl.startsWith('/schedule/shift/')) {
      // Navigate to schedule/planning
      context.go(AppRoutes.beveiligerSchedule);
    } else if (actionUrl == '/profile/certificates') {
      // Navigate to certificates
      context.go(AppRoutes.beveiligerCertificates);
    } else if (actionUrl == '/payments/history') {
      // Navigate to profile (no separate payments route yet)
      context.go(AppRoutes.beveiligerProfile);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            color: DesignTokens.colorWhite,
          ),
        ),
        backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        margin: EdgeInsets.all(DesignTokens.spacingM),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SecuryFlexTheme.getColorScheme(UserRole.guard);

    return SafeArea(
      child: UnifiedBackgroundService.guardMeshGradient(
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
            UnifiedHeader.simple(
              title: 'Notificaties',
              userRole: UserRole.guard,
              titleAlignment: TextAlign.center,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: SecuryFlexTheme.getColorScheme(UserRole.guard).onSurface,
                ),
                onPressed: () => context.pop(),
              ),
          actions: [
            // Settings/Preferences button - always visible
            HeaderElements.actionButton(
              icon: Icons.settings,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationPreferencesScreen(),
                ),
              ),
              userRole: UserRole.guard,
            ),
            
            // Mark all as read button - only when there are unread notifications
            BlocBuilder<NotificationCenterBloc, NotificationCenterState>(
              builder: (context, state) {
                final hasUnreadNotifications = state is NotificationCenterLoaded && 
                    state.notifications.any((n) => !n.isRead);
                
                if (!hasUnreadNotifications) {
                  return const SizedBox.shrink();
                }

                return HeaderElements.actionButton(
                  icon: Icons.done_all,
                  onPressed: _markAllAsRead,
                  userRole: UserRole.guard,
                );
              },
            ),
          ],
        ),
            // Filter Section
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              child: NotificationFilterWidget(
                selectedFilter: _selectedFilter,
                onFilterChanged: _onFilterChanged,
                userRole: UserRole.guard,
              ),
            ),
            
            // Notifications List
            Expanded(
              child: BlocBuilder<NotificationCenterBloc, NotificationCenterState>(
                builder: (context, state) {
                  if (state is NotificationCenterLoading) {
                    return _buildLoadingState();
                  } else if (state is NotificationCenterLoaded) {
                    return _buildNotificationsList(state.notifications, state.unreadCount);
                  } else if (state is NotificationCenterError) {
                    return _buildErrorState(state.message);
                  }
                  return _buildInitialState();
                },
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 3.0,
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'Notificaties laden...',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeBody,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 64,
            color: SecuryFlexTheme.getColorScheme(UserRole.guard).onSurfaceVariant,
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'Notificaties laden...',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeBody,
              color: SecuryFlexTheme.getColorScheme(UserRole.guard).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: DesignTokens.colorError,
            ),
            SizedBox(height: DesignTokens.spacingL),
            Text(
              'Fout bij laden notificaties',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.colorError,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            UnifiedButton.primary(
              text: 'Opnieuw proberen',
              onPressed: _loadNotifications,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<GuardNotification> notifications, int unreadCount) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            itemCount: notifications.length + (_shouldShowUnreadHeader(notifications) ? 1 : 0),
            itemBuilder: (context, index) {
              // Show unread header if needed
              if (_shouldShowUnreadHeader(notifications) && index == 0) {
                return _buildUnreadHeader(unreadCount);
              }

              final notificationIndex = _shouldShowUnreadHeader(notifications) ? index - 1 : index;
              final notification = notifications[notificationIndex];
              
              return FadeTransition(
                opacity: Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (notificationIndex * 0.1).clamp(0.0, 1.0),
                    ((notificationIndex * 0.1) + 0.3).clamp(0.0, 1.0),
                    curve: Curves.easeOut,
                  ),
                )),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (notificationIndex * 0.1).clamp(0.0, 1.0),
                      ((notificationIndex * 0.1) + 0.3).clamp(0.0, 1.0),
                      curve: Curves.easeOut,
                    ),
                  )),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
                    child: NotificationItemWidget(
                      notification: notification,
                      onTap: () => _onNotificationTap(notification),
                      onDelete: () => _onNotificationDelete(notification.id),
                      userRole: UserRole.guard,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    final hasFilter = _selectedFilter != null;
    
    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spacingXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasFilter ? Icons.filter_list_off : Icons.notifications_none,
                    size: 80,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: DesignTokens.spacingL),
                  Text(
                    hasFilter 
                        ? 'Geen notificaties voor dit filter'
                        : 'Nog geen notificaties',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamily,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Text(
                    hasFilter 
                        ? 'Probeer een ander filter of wis alle filters om alle notificaties te zien.'
                        : 'Je krijgt hier meldingen over nieuwe klussen, betalingen, certificaten en belangrijke updates.',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontFamily: DesignTokens.fontFamily,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (hasFilter) ...[
                    SizedBox(height: DesignTokens.spacingL),
                    UnifiedButton.secondary(
                      text: 'Alle filters wissen',
                      onPressed: () => _onFilterChanged(null),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadHeader(int unreadCount) {
    if (unreadCount == 0) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: UnifiedCard.compact(
        userRole: UserRole.guard,
        backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.guard).primaryContainer,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingXS),
              decoration: BoxDecoration(
                color: SecuryFlexTheme.getColorScheme(UserRole.guard).primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
              ),
              child: Icon(
                Icons.circle,
                size: DesignTokens.iconSizeS,
                color: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$unreadCount ongelezen ${unreadCount == 1 ? 'notificatie' : 'notificaties'}',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightMedium,
                      fontFamily: DesignTokens.fontFamily,
                      color: SecuryFlexTheme.getColorScheme(UserRole.guard).onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Tik op notificaties om ze te markeren als gelezen',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamily,
                      color: SecuryFlexTheme.getColorScheme(UserRole.guard).onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            UnifiedButton.text(
              text: 'Alle lezen',
              onPressed: _markAllAsRead,
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowUnreadHeader(List<GuardNotification> notifications) {
    return notifications.any((n) => !n.isRead) && _selectedFilter == null;
  }
}