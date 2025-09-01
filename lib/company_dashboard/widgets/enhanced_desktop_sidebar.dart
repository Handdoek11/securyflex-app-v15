import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';

/// Enhanced desktop sidebar with collapsible functionality and advanced features
class EnhancedDesktopSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onNewJob;
  final VoidCallback onEmergency;

  const EnhancedDesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onNewJob,
    required this.onEmergency,
  });

  @override
  State<EnhancedDesktopSidebar> createState() => _EnhancedDesktopSidebarState();
}

class _EnhancedDesktopSidebarState extends State<EnhancedDesktopSidebar> 
    with SingleTickerProviderStateMixin {
  bool _isCollapsed = false;
  bool _isHovering = false;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  
  // Submenu states
  bool _isAnalyticsExpanded = false;
  bool _isSettingsExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _widthAnimation = Tween<double>(
      begin: 280,
      end: 70,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      if (_isCollapsed) {
        _animationController.forward();
        _isAnalyticsExpanded = false;
        _isSettingsExpanded = false;
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedBuilder(
        animation: _widthAnimation,
        builder: (context, child) {
          return Container(
            width: _widthAnimation.value,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              border: Border(
                right: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              boxShadow: _isHovering ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(2, 0),
                ),
              ] : [],
            ),
            child: Column(
              children: [
                _buildHeader(colorScheme),
                Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                _buildQuickActions(colorScheme),
                Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                Flexible(
                  fit: FlexFit.loose,
                  child: _buildNavigationItems(colorScheme),
                ),
                _buildFooter(colorScheme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(_isCollapsed ? 12 : 20),
      child: Row(
        children: [
          Icon(
            Icons.business,
            color: colorScheme.primary,
            size: _isCollapsed ? 28 : 32,
          ),
          if (!_isCollapsed) ...[
            SizedBox(width: 12),
            Flexible(
              fit: FlexFit.loose,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SecuryFlex',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Business Portal',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            icon: Icon(
              _isCollapsed ? Icons.menu_open : Icons.menu,
              size: 20,
            ),
            onPressed: _toggleSidebar,
            tooltip: _isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(_isCollapsed ? 8 : 12),
      child: Column(
        children: [
          _buildQuickActionButton(
            icon: Icons.add_business,
            label: 'Nieuwe Job',
            color: colorScheme.primary,
            onTap: widget.onNewJob,
            isCollapsed: _isCollapsed,
          ),
          SizedBox(height: 8),
          _buildQuickActionButton(
            icon: Icons.emergency,
            label: 'Noodgeval',
            color: DesignTokens.colorError,
            onTap: widget.onEmergency,
            isCollapsed: _isCollapsed,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isCollapsed,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 12 : 16,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              if (!isCollapsed) ...[
                SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItems(ColorScheme colorScheme) {
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildNavItem(
          icon: Icons.dashboard,
          label: 'Dashboard',
          index: 0,
          badge: null,
          colorScheme: colorScheme,
        ),
        _buildNavItem(
          icon: Icons.work,
          label: 'Opdrachten',
          index: 1,
          badge: '12',
          colorScheme: colorScheme,
        ),
        _buildNavItem(
          icon: Icons.people,
          label: 'Sollicitaties',
          index: 2,
          badge: '8',
          colorScheme: colorScheme,
        ),
        _buildNavItem(
          icon: Icons.groups,
          label: 'Team',
          index: 3,
          badge: null,
          colorScheme: colorScheme,
        ),
        _buildNavItem(
          icon: Icons.chat_bubble,
          label: 'Berichten',
          index: 4,
          badge: '3',
          colorScheme: colorScheme,
        ),
        
        // Analytics with submenu
        _buildExpandableNavItem(
          icon: Icons.analytics,
          label: 'Analytics',
          isExpanded: _isAnalyticsExpanded,
          onTap: () {
            if (!_isCollapsed) {
              setState(() {
                _isAnalyticsExpanded = !_isAnalyticsExpanded;
              });
            }
          },
          colorScheme: colorScheme,
          children: _isCollapsed ? [] : [
            _buildSubNavItem('Omzet', Icons.euro, colorScheme, 6),
            _buildSubNavItem('Performance', Icons.trending_up, colorScheme, 7),
            _buildSubNavItem('Rapporten', Icons.description, colorScheme, 8),
          ],
        ),
        
        _buildNavItem(
          icon: Icons.payment,
          label: 'Financiën',
          index: 5,
          badge: null,
          colorScheme: colorScheme,
        ),
        
        Divider(color: colorScheme.outline.withValues(alpha: 0.1)),
        
        // Settings with submenu
        _buildExpandableNavItem(
          icon: Icons.settings,
          label: 'Instellingen',
          isExpanded: _isSettingsExpanded,
          onTap: () {
            if (!_isCollapsed) {
              setState(() {
                _isSettingsExpanded = !_isSettingsExpanded;
              });
            }
          },
          colorScheme: colorScheme,
          children: _isCollapsed ? [] : [
            _buildSubNavItem('Bedrijfsprofiel', Icons.business_center, colorScheme),
            _buildSubNavItem('Gebruikers', Icons.person, colorScheme),
            _buildSubNavItem('Beveiliging', Icons.security, colorScheme),
            _buildSubNavItem('Integraties', Icons.extension, colorScheme),
          ],
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    String? badge,
    required ColorScheme colorScheme,
  }) {
    final isSelected = widget.selectedIndex == index;
    
    return Tooltip(
      message: _isCollapsed ? label : '',
      preferBelow: false,
      child: Material(
        color: isSelected 
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
        child: InkWell(
          onTap: () => widget.onItemSelected(index),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isCollapsed ? 0 : 20,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: _isCollapsed 
                ? MainAxisAlignment.center 
                : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                if (!_isCollapsed) ...[
                  SizedBox(width: 12),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: DesignTokens.colorError,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
                if (_isCollapsed && badge != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: DesignTokens.colorError,
                        shape: BoxShape.circle,
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

  Widget _buildExpandableNavItem({
    required IconData icon,
    required String label,
    required bool isExpanded,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _isCollapsed ? 0 : 20,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: _isCollapsed 
                  ? MainAxisAlignment.center 
                  : MainAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  if (!_isCollapsed) ...[
                    SizedBox(width: 12),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (isExpanded && !_isCollapsed)
          ...children,
      ],
    );
  }

  Widget _buildSubNavItem(String label, IconData icon, ColorScheme colorScheme, [int? index]) {
    final isSelected = index != null && widget.selectedIndex == index;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (index != null) {
            widget.onItemSelected(index);
          } else {
            // Show feedback for submenu navigation without index
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Navigeren naar $label'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.only(left: 52, right: 20, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon, 
                size: 18, 
                color: isSelected 
                  ? colorScheme.primary 
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
              ),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected 
                    ? colorScheme.primary 
                    : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(_isCollapsed ? 12 : 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: _isCollapsed 
          ? MainAxisAlignment.center 
          : MainAxisAlignment.spaceBetween,
        children: [
          if (!_isCollapsed) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SecureGuard BV',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Premium Account',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: Text(
                'SG',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                ),
              ),
            ),
          ] else
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: Text(
                'SG',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}