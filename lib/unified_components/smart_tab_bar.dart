import 'dart:async';
import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'smart_badge_overlay.dart';
import '../services/notification_badge_service.dart';

/// TabBar size variants following Material Design 3 specifications
enum TabBarSize {
  /// Standard 48dp height - Material Design 3 default
  standard,
  /// Compact 40dp height for dense layouts
  compact,
  /// Large 56dp height for desktop/large screens  
  large,
}

/// Smart Tab Bar with Badge Integration
/// Provides enhanced TabBar with real-time badge notifications
/// Integrates with NotificationBadgeService for automatic updates
/// Supports accessibility and different badge types
/// Now optimized with Material Design 3 compliant sizing
class SmartTabBar extends StatefulWidget implements PreferredSizeWidget {
  const SmartTabBar({
    super.key,
    required this.tabs,
    required this.controller,
    this.userRole = UserRole.guard,
    this.onTap,
    this.isScrollable = false,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.indicatorWeight = 3.0,
    this.enableBadges = true,
    this.size = TabBarSize.standard,
  });

  final List<SmartTab> tabs;
  final TabController controller;
  final UserRole userRole;
  final ValueChanged<int>? onTap;
  final bool isScrollable;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final double indicatorWeight;
  final bool enableBadges;
  final TabBarSize size;

  @override
  Size get preferredSize {
    switch (size) {
      case TabBarSize.standard:
        return const Size.fromHeight(DesignTokens.tabBarHeight);
      case TabBarSize.compact:
        return const Size.fromHeight(DesignTokens.tabBarHeightCompact);
      case TabBarSize.large:
        return const Size.fromHeight(DesignTokens.tabBarHeightLarge);
    }
  }

  @override
  State<SmartTabBar> createState() => _SmartTabBarState();
}

class _SmartTabBarState extends State<SmartTabBar> {
  final NotificationBadgeService _badgeService = NotificationBadgeService.instance;
  StreamSubscription? _badgeSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.enableBadges) {
      _initializeBadges();
    }
  }

  @override
  void dispose() {
    _badgeSubscription?.cancel();
    super.dispose();
  }

  void _initializeBadges() {
    // Listen to badge updates with proper disposal
    _badgeSubscription = _badgeService.badgeStream.listen((badges) {
      if (mounted) {
        setState(() {
          // Badge updates trigger rebuild
        });
      }
    });
  }

  /// Get text style for selected tabs based on TabBar size
  TextStyle _getSelectedLabelStyle() {
    switch (widget.size) {
      case TabBarSize.compact:
        return TextStyle(
          fontSize: DesignTokens.fontSizeCaption,  // 12sp for compact
          fontWeight: DesignTokens.fontWeightSemiBold,
          fontFamily: DesignTokens.fontFamily,
          height: 1.2, // Tighter line height for compact
        );
      case TabBarSize.standard:
        return TextStyle(
          fontSize: DesignTokens.fontSizeBody,     // 14sp for standard  
          fontWeight: DesignTokens.fontWeightSemiBold,
          fontFamily: DesignTokens.fontFamily,
          height: 1.3,
        );
      case TabBarSize.large:
        return TextStyle(
          fontSize: DesignTokens.fontSizeBodyLarge, // 16sp for large
          fontWeight: DesignTokens.fontWeightSemiBold,
          fontFamily: DesignTokens.fontFamily,
          height: 1.4,
        );
    }
  }

  /// Get text style for unselected tabs based on TabBar size
  TextStyle _getUnselectedLabelStyle() {
    switch (widget.size) {
      case TabBarSize.compact:
        return TextStyle(
          fontSize: DesignTokens.fontSizeCaption,  // 12sp for compact
          fontWeight: DesignTokens.fontWeightMedium,
          fontFamily: DesignTokens.fontFamily,
          height: 1.2,
        );
      case TabBarSize.standard:
        return TextStyle(
          fontSize: DesignTokens.fontSizeBody,     // 14sp for standard
          fontWeight: DesignTokens.fontWeightMedium,
          fontFamily: DesignTokens.fontFamily,
          height: 1.3,
        );
      case TabBarSize.large:
        return TextStyle(
          fontSize: DesignTokens.fontSizeBodyLarge, // 16sp for large
          fontWeight: DesignTokens.fontWeightMedium,
          fontFamily: DesignTokens.fontFamily,
          height: 1.4,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,  // Fully transparent to show gradient
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: TabBar(
          controller: widget.controller,
          tabs: _buildTabsWithBadges(),
          onTap: widget.onTap,
          isScrollable: widget.isScrollable,
          labelColor: widget.labelColor ?? colorScheme.primary,
          unselectedLabelColor: widget.unselectedLabelColor ?? colorScheme.onSurfaceVariant,
          indicatorColor: widget.indicatorColor ?? colorScheme.primary,
          indicatorWeight: widget.indicatorWeight,
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          labelStyle: widget.labelStyle ?? _getSelectedLabelStyle(),
          unselectedLabelStyle: widget.unselectedLabelStyle ?? _getUnselectedLabelStyle(),
        ),
      ),
    );
  }

  List<Widget> _buildTabsWithBadges() {
    return widget.tabs.map((smartTab) {
      if (!widget.enableBadges || smartTab.badgeIdentifier == null) {
        return Tab(
          text: smartTab.text,
          icon: smartTab.icon,
          child: smartTab.child,
        );
      }

      final badgeCount = _badgeService.getTabBadgeCount(smartTab.badgeIdentifier!);
      final badgeType = badgeCount > 0 
          ? _badgeService.getTabBadgeType(smartTab.badgeIdentifier!)
          : BadgeType.info;

      return Tab(
        child: SmartBadgeOverlay(
          badgeCount: badgeCount,
          badgeType: badgeType,
          showBadge: badgeCount > 0,
          accessibilityLabel: '${smartTab.text}, $badgeCount nieuwe meldingen',
          child: smartTab.child ?? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (smartTab.icon != null) ...[
                smartTab.icon!,
                if (smartTab.text != null) SizedBox(width: DesignTokens.spacingXS),
              ],
              if (smartTab.text != null)
                Flexible(
                  child: Text(
                    smartTab.text!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

/// Smart Tab Data Model
class SmartTab {
  final String? text;
  final Widget? icon;
  final Widget? child;
  final String? badgeIdentifier;
  final VoidCallback? onBadgeTap;

  const SmartTab({
    this.text,
    this.icon,
    this.child,
    this.badgeIdentifier,
    this.onBadgeTap,
  }) : assert(text != null || icon != null || child != null,
             'At least one of text, icon, or child must be provided');

  /// Create a text-only tab
  factory SmartTab.text(
    String text, {
    String? badgeIdentifier,
    VoidCallback? onBadgeTap,
  }) {
    return SmartTab(
      text: text,
      badgeIdentifier: badgeIdentifier,
      onBadgeTap: onBadgeTap,
    );
  }

  /// Create an icon-only tab
  factory SmartTab.icon(
    Widget icon, {
    String? badgeIdentifier,
    VoidCallback? onBadgeTap,
  }) {
    return SmartTab(
      icon: icon,
      badgeIdentifier: badgeIdentifier,
      onBadgeTap: onBadgeTap,
    );
  }

  /// Create a tab with both text and icon
  factory SmartTab.textIcon(
    String text,
    Widget icon, {
    String? badgeIdentifier,
    VoidCallback? onBadgeTap,
  }) {
    return SmartTab(
      text: text,
      icon: icon,
      badgeIdentifier: badgeIdentifier,
      onBadgeTap: onBadgeTap,
    );
  }

  /// Create a custom tab with child widget
  factory SmartTab.custom(
    Widget child, {
    String? badgeIdentifier,
    VoidCallback? onBadgeTap,
  }) {
    return SmartTab(
      child: child,
      badgeIdentifier: badgeIdentifier,
      onBadgeTap: onBadgeTap,
    );
  }
}

/// Responsive TabBar that automatically chooses size based on device
class ResponsiveSmartTabBar extends StatelessWidget {
  final List<SmartTab> tabs;
  final TabController controller;
  final UserRole userRole;
  final ValueChanged<int>? onTap;
  final bool isScrollable;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final double indicatorWeight;
  final bool enableBadges;

  const ResponsiveSmartTabBar({
    super.key,
    required this.tabs,
    required this.controller,
    this.userRole = UserRole.guard,
    this.onTap,
    this.isScrollable = false,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.indicatorWeight = 3.0,
    this.enableBadges = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tabSize = _determineTabSize(screenWidth);
    
    return SmartTabBar(
      tabs: tabs,
      controller: controller,
      userRole: userRole,
      onTap: onTap,
      isScrollable: isScrollable,
      indicatorColor: indicatorColor,
      labelColor: labelColor,
      unselectedLabelColor: unselectedLabelColor,
      labelStyle: labelStyle,
      unselectedLabelStyle: unselectedLabelStyle,
      indicatorWeight: indicatorWeight,
      enableBadges: enableBadges,
      size: tabSize,
    );
  }
  
  TabBarSize _determineTabSize(double screenWidth) {
    if (screenWidth < 600) return TabBarSize.standard;    // Mobile - use standard instead of compact for accessibility
    if (screenWidth < 1200) return TabBarSize.standard;  // Tablet - standard
    return TabBarSize.large;                             // Desktop - large
  }
}

/// Smart Tab Bar Helper
class SmartTabBarHelper {
  /// Create tabs for Jobs screen
  static List<SmartTab> createJobsTabs() {
    return [
      SmartTab.text(
        'Beschikbaar',
        badgeIdentifier: 'jobs',
      ),
      SmartTab.text(
        'Sollicitaties',
        badgeIdentifier: 'applications',
      ),
      SmartTab.text(
        'Actief',
        badgeIdentifier: 'active',
      ),
      SmartTab.text(
        'Geschiedenis',
        badgeIdentifier: 'history',
      ),
    ];
  }

  /// Create tabs for Planning screen
  static List<SmartTab> createPlanningTabs() {
    return [
      SmartTab.text(
        'Diensten',
        badgeIdentifier: 'planning',
      ),
      SmartTab.text(
        'Beschikbaar',
        badgeIdentifier: 'planning',
      ),
      SmartTab.text(
        'Urenregistratie',
        badgeIdentifier: 'timesheet',
      ),
    ];
  }

  /// Create tabs for Company dashboard
  static List<SmartTab> createCompanyTabs() {
    return [
      SmartTab.text(
        'Dashboard',
      ),
      SmartTab.text(
        'Jobs',
        badgeIdentifier: 'jobs',
      ),
      SmartTab.text(
        'Sollicitaties',
        badgeIdentifier: 'jobs',
      ),
      SmartTab.text(
        'Berichten',
        badgeIdentifier: 'chat',
      ),
    ];
  }

  /// Update job-related badges
  static Future<void> updateJobBadges({
    int newApplications = 0,
    int applicationUpdates = 0,
    int newJobs = 0,
  }) async {
    await NotificationBadgeService.instance.updateJobBadges(
      newApplications: newApplications,
      applicationUpdates: applicationUpdates,
      newJobs: newJobs,
    );
  }

  /// Update planning-related badges
  static Future<void> updatePlanningBadges({
    int upcomingShifts = 0,
    int scheduleConflicts = 0,
    int shiftChanges = 0,
  }) async {
    await NotificationBadgeService.instance.updatePlanningBadges(
      upcomingShifts: upcomingShifts,
      scheduleConflicts: scheduleConflicts,
      shiftChanges: shiftChanges,
    );
  }

  /// Clear badges for a specific tab
  static Future<void> clearTabBadges(String tabIdentifier) async {
    switch (tabIdentifier) {
      case 'jobs':
        await NotificationBadgeService.instance.clearBadge(BadgeIdentifiers.newApplications);
        await NotificationBadgeService.instance.clearBadge(BadgeIdentifiers.applicationUpdates);
        await NotificationBadgeService.instance.clearBadge(BadgeIdentifiers.newJobs);
        break;
      case 'planning':
        await NotificationBadgeService.instance.clearBadge(BadgeIdentifiers.upcomingShifts);
        await NotificationBadgeService.instance.clearBadge(BadgeIdentifiers.scheduleConflicts);
        await NotificationBadgeService.instance.clearBadge(BadgeIdentifiers.shiftChanges);
        break;
      case 'timesheet':
        await NotificationBadgeService.instance.clearBadge(BadgeIdentifiers.pendingApprovals);
        await NotificationBadgeService.instance.clearBadge(BadgeIdentifiers.missedClockOuts);
        break;
    }
  }
}
