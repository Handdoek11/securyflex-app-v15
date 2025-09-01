import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../unified_header.dart';
import '../../unified_theme_system.dart';
import '../../unified_design_tokens.dart';
import '../../unified_card_system.dart';
import '../widgets/company_header_elements.dart';

/// Company notifications screen showing job applications, system updates, and alerts
/// Follows SecuryFlex unified design system patterns
class CompanyNotificationsScreen extends StatefulWidget {
  final AnimationController? animationController;

  const CompanyNotificationsScreen({
    super.key,
    this.animationController,
  });

  @override
  State<CompanyNotificationsScreen> createState() => _CompanyNotificationsScreenState();
}

class _CompanyNotificationsScreenState extends State<CompanyNotificationsScreen>
    with TickerProviderStateMixin {
  late ScrollController scrollController;
  late AnimationController _localAnimationController;
  
  List<CompanyNotification> notifications = [];
  bool isLoading = true;
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    _localAnimationController = widget.animationController ?? 
        AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    scrollController.dispose();
    if (widget.animationController == null) {
      _localAnimationController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    setState(() {
      notifications = _generateMockNotifications();
      isLoading = false;
    });
    
    _localAnimationController.forward();
  }

  List<CompanyNotification> _generateMockNotifications() {
    final now = DateTime.now();
    return [
      CompanyNotification(
        id: '1',
        type: NotificationType.application,
        title: 'Nieuwe sollicitatie',
        message: 'Jan de Vries heeft gesolliciteerd op "Beveiliging Winkelcentrum"',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: false,
        priority: NotificationPriority.high,
        actionData: {'jobId': 'job_1', 'applicantId': 'user_1'},
      ),
      CompanyNotification(
        id: '2',
        type: NotificationType.jobUpdate,
        title: 'Job verlopen',
        message: 'De job "Evenementbeveiliging Concert" is verlopen zonder sollicitaties',
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: false,
        priority: NotificationPriority.medium,
        actionData: {'jobId': 'job_2'},
      ),
      CompanyNotification(
        id: '3',
        type: NotificationType.system,
        title: 'Systeem update',
        message: 'Nieuwe functies beschikbaar in het bedrijvendashboard',
        timestamp: now.subtract(const Duration(hours: 4)),
        isRead: true,
        priority: NotificationPriority.low,
      ),
      CompanyNotification(
        id: '4',
        type: NotificationType.application,
        title: 'Sollicitatie ingetrokken',
        message: 'Maria Janssen heeft haar sollicitatie ingetrokken voor "Kantoorbeveiliging"',
        timestamp: now.subtract(const Duration(hours: 6)),
        isRead: true,
        priority: NotificationPriority.medium,
        actionData: {'jobId': 'job_3', 'applicantId': 'user_2'},
      ),
      CompanyNotification(
        id: '5',
        type: NotificationType.payment,
        title: 'Betaling verwerkt',
        message: 'Betaling van €450,00 voor opdracht "Winkelbeveiliging" is verwerkt',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
        priority: NotificationPriority.low,
        actionData: {'amount': 450.00, 'jobId': 'job_4'},
      ),
    ];
  }

  /// Standardized animated header for company notifications screen
  Widget getAppBarUI() {
    return UnifiedHeader.animated(
      title: 'Notificaties',
      animationController: _localAnimationController,
      scrollController: scrollController,
      enableScrollAnimation: true,
      userRole: UserRole.company,
      titleAlignment: TextAlign.center,
      actions: [
        CompanyHeaderElements.buildBackButton(
          context: context,
          onPressed: () => context.pop(),
        ),
        CompanyHeaderElements.buildDateDisplay(context),
        CompanyHeaderElements.buildMarkAllReadButton(
          context: context,
          onPressed: _markAllAsRead,
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Container(
      color: companyColors.surfaceContainerHighest,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child: getAppBarUI(),
        ),
        body: Column(
          children: [
            _buildFilterTabs(),
            Expanded(
              child: isLoading ? _buildLoadingState() : _buildNotificationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Container(
      decoration: BoxDecoration(
        color: companyColors.surface,
        border: Border(
          bottom: BorderSide(
            color: companyColors.outline.withValues(alpha: 0.2),
            width: DesignTokens.spacingXS / 4,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
      child: Row(
        children: [
          _buildFilterTab('all', 'Alle', notifications.length),
          _buildFilterTab('unread', 'Ongelezen', notifications.where((n) => !n.isRead).length),
          _buildFilterTab('applications', 'Sollicitaties', 
              notifications.where((n) => n.type == NotificationType.application).length),
        ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label, int count) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    final isSelected = selectedFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filter;
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: DesignTokens.spacingS),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: isSelected ? Border.all(color: companyColors.primary, width: DesignTokens.spacingXS / 4) : null,
        ),
        child: UnifiedCard.standard(
          userRole: UserRole.company,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          backgroundColor: isSelected ? companyColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? companyColors.primary : companyColors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: DesignTokens.spacingXS),
              UnifiedCard.standard(
                userRole: UserRole.company,
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingXS,
                  vertical: DesignTokens.spacingXS / 2,
                ),
                backgroundColor: isSelected ? companyColors.primary : companyColors.outline,
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? companyColors.onPrimary : companyColors.onSurface,
                    fontSize: DesignTokens.fontSizeXS,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Notificaties laden...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    final filteredNotifications = _getFilteredNotifications();
    
    if (filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.all(DesignTokens.spacingM),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return _buildNotificationCard(notification, index);
        },
      ),
    );
  }

  List<CompanyNotification> _getFilteredNotifications() {
    switch (selectedFilter) {
      case 'unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'applications':
        return notifications.where((n) => n.type == NotificationType.application).toList();
      default:
        return notifications;
    }
  }

  Widget _buildEmptyState() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: companyColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Geen notificaties',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: companyColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Je bent helemaal bij!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: companyColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(CompanyNotification notification, int index) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return AnimatedBuilder(
      animation: _localAnimationController,
      builder: (context, child) {
        final animationValue = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _localAnimationController,
            curve: Interval(
              (index * 0.1).clamp(0.0, 1.0),
              ((index * 0.1) + 0.2).clamp(0.0, 1.0),
              curve: Curves.fastOutSlowIn,
            ),
          ),
        ).value;

        return Transform(
          transform: Matrix4.translationValues(0.0, 30 * (1.0 - animationValue), 0.0),
          child: Opacity(
            opacity: animationValue,
            child: Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
              child: UnifiedCard.standard(
                userRole: UserRole.company,
                isClickable: true,
                onTap: () => _handleNotificationTap(notification),
                child: Padding(
                  padding: EdgeInsets.all(DesignTokens.spacingM),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNotificationIcon(notification.type, notification.priority),
                      SizedBox(width: DesignTokens.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: notification.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      color: notification.isRead
                                          ? companyColors.onSurface
                                          : companyColors.primary,
                                    ),
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    width: DesignTokens.spacingS,
                                    height: DesignTokens.spacingS,
                                    decoration: BoxDecoration(
                                      color: companyColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: DesignTokens.spacingXS),
                            Text(
                              notification.message,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: companyColors.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: DesignTokens.spacingS),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: companyColors.onSurfaceVariant,
                                ),
                                SizedBox(width: DesignTokens.spacingXS),
                                Text(
                                  _formatTimestamp(notification.timestamp),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: companyColors.onSurfaceVariant,
                                  ),
                                ),
                                if (notification.priority == NotificationPriority.high ||
                                    notification.priority == NotificationPriority.urgent) ...[
                                  SizedBox(width: DesignTokens.spacingS),
                                  UnifiedCard.standard(
                                    userRole: UserRole.company,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: DesignTokens.spacingXS,
                                      vertical: DesignTokens.spacingXS / 2,
                                    ),
                                    backgroundColor: notification.priority == NotificationPriority.urgent
                                        ? DesignTokens.colorError
                                        : DesignTokens.colorWarning,
                                    child: Text(
                                      notification.priority == NotificationPriority.urgent
                                          ? 'URGENT'
                                          : 'BELANGRIJK',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: DesignTokens.colorWhite,
                                        fontSize: DesignTokens.fontSizeXS,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationIcon(NotificationType type, NotificationPriority priority) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    switch (type) {
      case NotificationType.application:
        iconData = Icons.person_add;
        iconColor = DesignTokens.colorSuccess;
        backgroundColor = DesignTokens.colorSuccess.withValues(alpha: 0.1);
        break;
      case NotificationType.jobUpdate:
        iconData = Icons.work;
        iconColor = companyColors.primary;
        backgroundColor = companyColors.primary.withValues(alpha: 0.1);
        break;
      case NotificationType.system:
        iconData = Icons.system_update;
        iconColor = DesignTokens.colorInfo;
        backgroundColor = DesignTokens.colorInfo.withValues(alpha: 0.1);
        break;
      case NotificationType.payment:
        iconData = Icons.euro;
        iconColor = DesignTokens.colorSuccess;
        backgroundColor = DesignTokens.colorSuccess.withValues(alpha: 0.1);
        break;
      case NotificationType.message:
        iconData = Icons.message;
        iconColor = companyColors.secondary;
        backgroundColor = companyColors.secondary.withValues(alpha: 0.1);
        break;
    }

    // Override colors for urgent notifications
    if (priority == NotificationPriority.urgent) {
      iconColor = DesignTokens.colorError;
      backgroundColor = DesignTokens.colorError.withValues(alpha: 0.1);
    }

    return UnifiedCard.standard(
      userRole: UserRole.company,
      padding: EdgeInsets.all(DesignTokens.spacingS),
      backgroundColor: backgroundColor,
      child: Icon(
        iconData,
        color: iconColor,
        size: DesignTokens.iconSizeM,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Nu';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m geleden';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}u geleden';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d geleden';
    } else {
      return DateFormat('dd MMM', 'nl_NL').format(timestamp);
    }
  }

  void _handleNotificationTap(CompanyNotification notification) {
    // Mark as read
    if (!notification.isRead) {
      setState(() {
        notification.isRead = true;
      });
    }

    // Handle different notification types
    switch (notification.type) {
      case NotificationType.application:
        _handleApplicationNotification(notification);
        break;
      case NotificationType.jobUpdate:
        _handleJobUpdateNotification(notification);
        break;
      case NotificationType.payment:
        _handlePaymentNotification(notification);
        break;
      default:
        _showNotificationDetails(notification);
    }
  }

  void _handleApplicationNotification(CompanyNotification notification) {
    // TODO: Navigate to application details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigatie naar sollicitatie details komt binnenkort'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleJobUpdateNotification(CompanyNotification notification) {
    // TODO: Navigate to job details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigatie naar job details komt binnenkort'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handlePaymentNotification(CompanyNotification notification) {
    // TODO: Navigate to payment details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigatie naar betalingsoverzicht komt binnenkort'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showNotificationDetails(CompanyNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alle notificaties gemarkeerd als gelezen'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Data models for notifications
enum NotificationType {
  application,
  jobUpdate,
  system,
  payment,
  message,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

class CompanyNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final NotificationPriority priority;
  final Map<String, dynamic>? actionData;

  CompanyNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.priority = NotificationPriority.medium,
    this.actionData,
  });
}
