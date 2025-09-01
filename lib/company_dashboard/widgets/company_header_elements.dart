import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../unified_design_tokens.dart';
import '../../unified_header.dart';
import '../../unified_theme_system.dart';

/// Standardized header elements for company screens
/// Provides consistent date display and action buttons across all company headers
class CompanyHeaderElements {
  
  /// Build standardized date display for company headers
  /// Shows current date in Dutch format (dd MMM) with calendar icon
  static Widget buildDateDisplay(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: DesignTokens.iconSizeS,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Text(
            DateFormat('dd MMM', 'nl_NL').format(DateTime.now()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Build standardized notification button with badge for unread count
  static Widget buildNotificationButton({
    required BuildContext context,
    required VoidCallback onPressed,
    int unreadCount = 0,
  }) {
    return Stack(
      children: [
        HeaderElements.actionButton(
          icon: Icons.notifications_outlined,
          onPressed: onPressed,
          userRole: UserRole.company,
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: EdgeInsets.all(DesignTokens.spacingXS),
              decoration: BoxDecoration(
                color: DesignTokens.colorError,
                borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: TextStyle(
                  color: DesignTokens.colorWhite,
                  fontSize: DesignTokens.fontSizeXS,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// Build standardized profile button for company headers
  static Widget buildProfileButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return HeaderElements.actionButton(
      icon: Icons.account_circle,
      onPressed: onPressed,
      userRole: UserRole.company,
    );
  }

  /// Build standardized back button for company headers
  static Widget buildBackButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return HeaderElements.actionButton(
      icon: Icons.arrow_back,
      onPressed: onPressed,
      userRole: UserRole.company,
    );
  }

  /// Build standardized search button for company headers
  static Widget buildSearchButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return HeaderElements.actionButton(
      icon: Icons.search,
      onPressed: onPressed,
      userRole: UserRole.company,
    );
  }

  /// Build standardized filter button for company headers
  static Widget buildFilterButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return HeaderElements.actionButton(
      icon: Icons.filter_list_outlined,
      onPressed: onPressed,
      userRole: UserRole.company,
    );
  }

  /// Build standardized analytics button for company headers
  static Widget buildAnalyticsButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return HeaderElements.actionButton(
      icon: Icons.analytics_outlined,
      onPressed: onPressed,
      userRole: UserRole.company,
    );
  }

  /// Build standardized add button for company headers
  static Widget buildAddButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return HeaderElements.actionButton(
      icon: Icons.add_circle_outline,
      onPressed: onPressed,
      userRole: UserRole.company,
    );
  }

  /// Build standardized help button for company headers
  static Widget buildHelpButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return HeaderElements.actionButton(
      icon: Icons.help_outline,
      onPressed: onPressed,
      userRole: UserRole.company,
    );
  }

  /// Build standardized logout button for company headers
  static Widget buildLogoutButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return HeaderElements.actionButton(
      icon: Icons.logout,
      onPressed: onPressed,
      userRole: UserRole.company,
    );
  }

  /// Build standardized mark all read button for notifications
  static Widget buildMarkAllReadButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return HeaderElements.actionButton(
      icon: Icons.mark_email_read,
      onPressed: onPressed,
      userRole: UserRole.company,
    );
  }
}
