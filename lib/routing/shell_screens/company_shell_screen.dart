// lib/routing/shell_screens/company_shell_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../unified_navigation_system.dart';
import '../../core/responsive/responsive_extensions.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';

/// Shell screen for company navigation with bottom navigation bar
/// Preserves state across tab switches using StatefulShellRoute
class CompanyShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  
  const CompanyShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<CompanyShellScreen> createState() => _CompanyShellScreenState();
}

class _CompanyShellScreenState extends State<CompanyShellScreen> {
  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      // Mobile layout with bottom navigation
      return Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: _buildBottomNavigation(context),
      );
    } else {
      // Desktop/Tablet layout with sidebar navigation
      return Scaffold(
        body: Row(
          children: [
            // Sidebar navigation for desktop/tablet
            _buildDesktopSidebar(context),
            // Main content
            Expanded(
              child: widget.navigationShell,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingL),
            child: Row(
              children: [
                Icon(
                  Icons.business,
                  color: colorScheme.primary,
                  size: 32,
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    'SecuryFlex',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
              children: [
                _buildSidebarItem(
                  context,
                  Icons.dashboard_outlined,
                  Icons.dashboard,
                  'Dashboard',
                  0,
                ),
                _buildSidebarItem(
                  context,
                  Icons.work_outline,
                  Icons.work,
                  'Opdrachten',
                  1,
                ),
                _buildSidebarItem(
                  context,
                  Icons.people_outline,
                  Icons.people,
                  'Team',
                  2,
                ),
                _buildSidebarItem(
                  context,
                  Icons.analytics_outlined,
                  Icons.analytics,
                  'Analyses',
                  3,
                ),
                _buildSidebarItem(
                  context,
                  Icons.business_outlined,
                  Icons.business,
                  'Bedrijf',
                  4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    final isSelected = widget.navigationShell.currentIndex == index;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXS,
      ),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: isSelected
                          ? DesignTokens.fontWeightSemiBold
                          : DesignTokens.fontWeightMedium,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    // Listen to application count
    final applicationCount = 0; // TODO: Implement application count from actual bloc
    
    // Listen to chat unread count
    final chatUnreadCount = 0; // TODO: Implement chat unread count
    
    return UnifiedBottomNavigation(
      selectedIndex: widget.navigationShell.currentIndex,
      onItemSelected: (index) => _onItemTapped(index),
      items: [
        UnifiedNavigationItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: 'Dashboard',
        ),
        UnifiedNavigationItem(
          icon: Icons.work_outline,
          activeIcon: Icons.work_rounded,
          label: 'Opdrachten',
          badge: applicationCount > 0 
              ? UnifiedBadge(text: applicationCount.toString()) 
              : null,
        ),
        UnifiedNavigationItem(
          icon: Icons.people_outline,
          activeIcon: Icons.people_rounded,
          label: 'Team',
        ),
        UnifiedNavigationItem(
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics_rounded,
          label: 'Analyses',
        ),
        UnifiedNavigationItem(
          icon: Icons.business_outlined,
          activeIcon: Icons.business_rounded,
          label: 'Bedrijf',
          badge: chatUnreadCount > 0 
              ? UnifiedBadge(text: chatUnreadCount.toString()) 
              : null,
        ),
      ],
    );
  }
  
  void _onItemTapped(int index) {
    // Use StatefulNavigationShell's built-in navigation
    widget.navigationShell.goBranch(
      index,
      // If tapping current tab, reset to root of that branch
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
  
  @override
  void dispose() {
    // Cleanup if needed
    super.dispose();
  }
}

// UnifiedBadge class moved to unified_navigation_system.dart to avoid duplication