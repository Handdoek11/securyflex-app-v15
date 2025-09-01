// lib/routing/shell_screens/beveiliger_shell_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../unified_navigation_system.dart';

/// Shell screen for beveiliger navigation with bottom navigation bar
/// Preserves state across tab switches using StatefulShellRoute
class BeveiligerShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  
  const BeveiligerShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<BeveiligerShellScreen> createState() => _BeveiligerShellScreenState();
}

class _BeveiligerShellScreenState extends State<BeveiligerShellScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }
  
  Widget _buildBottomNavigation(BuildContext context) {
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
        ),
        UnifiedNavigationItem(
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today_rounded,
          label: 'Planning',
        ),
        UnifiedNavigationItem(
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble_rounded,
          label: 'Berichten',
          badge: chatUnreadCount > 0 
              ? UnifiedBadge(text: chatUnreadCount.toString()) 
              : null,
        ),
        UnifiedNavigationItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person_rounded,
          label: 'Profiel',
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