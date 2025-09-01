import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../performance/desktop_analytics_optimizer.dart';

/// Desktop-optimized analytics dashboard for company users
/// 
/// Features:
/// - Multi-column responsive layouts
/// - Keyboard shortcuts for productivity
/// - High-density data visualization
/// - Advanced filtering and search
/// - Professional presentation
class DesktopAnalyticsDashboard extends StatefulWidget {
  final AnimationController? animationController;
  
  const DesktopAnalyticsDashboard({
    super.key,
    this.animationController,
  });
  
  @override
  State<DesktopAnalyticsDashboard> createState() => _DesktopAnalyticsDashboardState();
}

class _DesktopAnalyticsDashboardState extends State<DesktopAnalyticsDashboard> {
  final FocusNode _mainFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedTimeRange = 'Last 30 Days';
  
  @override
  void initState() {
    super.initState();
    _initializeDesktopOptimizations();
  }
  
  Future<void> _initializeDesktopOptimizations() async {
    await DesktopAnalyticsOptimizer.initialize();
    setState(() {});
  }
  
  @override
  void dispose() {
    _mainFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    final gridConfig = DesktopAnalyticsOptimizer.getGridConfiguration(context);
    
    return DesktopAnalyticsOptimizer.optimizeForDesktop(
      Focus(
        focusNode: _mainFocusNode,
        onKeyEvent: _handleKeyboardShortcuts,
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: Column(
            children: [
              _buildDesktopToolbar(colorScheme),
              Expanded(
                child: _buildAnalyticsContent(gridConfig, colorScheme),
              ),
            ],
          ),
        ),
      ),
      enableKeyboardShortcuts: true,
      enableContextMenus: true,
      enableHoverEffects: true,
    );
  }
  
  /// Build desktop toolbar with search, filters, and actions
  Widget _buildDesktopToolbar(ColorScheme colorScheme) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title
          Text(
            'Analytics Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          
          const Spacer(),
          
          // Search bar
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search analytics... (Ctrl+F)',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, 
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Time range selector
          PopupMenuButton<String>(
            initialValue: _selectedTimeRange,
            onSelected: (value) => setState(() => _selectedTimeRange = value),
            itemBuilder: (context) => [
              'Last 7 Days',
              'Last 30 Days', 
              'Last 90 Days',
              'Last Year',
              'Custom Range',
            ].map((range) => PopupMenuItem(
              value: range,
              child: Text(range),
            )).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range, size: 16),
                  const SizedBox(width: 8),
                  Text(_selectedTimeRange),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Export button
          ElevatedButton.icon(
            onPressed: _exportData,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export'),
          ),
          
          const SizedBox(width: 8),
          
          // Refresh button
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh (F5)',
          ),
        ],
      ),
    );
  }
  
  /// Build analytics content with responsive grid
  Widget _buildAnalyticsContent(GridConfiguration gridConfig, ColorScheme colorScheme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }
    
    return SingleChildScrollView(
      padding: gridConfig.padding,
      child: Column(
        children: [
          // Key metrics row
          _buildKeyMetricsRow(gridConfig, colorScheme),
          
          const SizedBox(height: 32),
          
          // Charts and detailed analytics
          _buildAnalyticsGrid(gridConfig, colorScheme),
        ],
      ),
    );
  }
  
  /// Build key metrics summary row
  Widget _buildKeyMetricsRow(GridConfiguration gridConfig, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Jobs', '1,247', '+12%', Icons.work, colorScheme)),
        SizedBox(width: gridConfig.crossAxisSpacing),
        Expanded(child: _buildMetricCard('Applications', '3,891', '+8%', Icons.people, colorScheme)),
        SizedBox(width: gridConfig.crossAxisSpacing),
        Expanded(child: _buildMetricCard('Revenue', '€45,670', '+15%', Icons.euro, colorScheme)),
        SizedBox(width: gridConfig.crossAxisSpacing),
        Expanded(child: _buildMetricCard('Active Guards', '156', '+3%', Icons.security, colorScheme)),
      ],
    );
  }
  
  /// Build metric card
  Widget _buildMetricCard(String title, String value, String change, IconData icon, ColorScheme colorScheme) {
    final isPositive = change.startsWith('+');
    
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: colorScheme.primary),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive 
                    ? DesignTokens.colorSuccess.withValues(alpha: 0.1)
                    : DesignTokens.colorError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive ? DesignTokens.colorSuccess : DesignTokens.colorError,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build analytics grid with charts and data tables
  Widget _buildAnalyticsGrid(GridConfiguration gridConfig, ColorScheme colorScheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: gridConfig.columnCount,
      crossAxisSpacing: gridConfig.crossAxisSpacing,
      mainAxisSpacing: gridConfig.mainAxisSpacing,
      childAspectRatio: gridConfig.childAspectRatio,
      children: [
        _buildChartCard('Job Applications Over Time', Icons.trending_up, colorScheme),
        _buildChartCard('Guard Performance', Icons.bar_chart, colorScheme),
        _buildChartCard('Revenue Breakdown', Icons.pie_chart, colorScheme),
        _buildChartCard('Geographic Distribution', Icons.map, colorScheme),
        _buildDataTableCard('Recent Applications', Icons.table_chart, colorScheme),
        _buildDataTableCard('Top Performing Guards', Icons.star, colorScheme),
      ],
    );
  }
  
  /// Build chart card placeholder
  Widget _buildChartCard(String title, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {}, // TODO: Implement chart actions
                icon: Icon(Icons.more_vert, size: 16),
                tooltip: 'Chart options',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chart will be rendered here',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build data table card placeholder
  Widget _buildDataTableCard(String title, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {}, // TODO: Implement view all
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_rows,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Data table will be rendered here',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Handle keyboard shortcuts
  KeyEventResult _handleKeyboardShortcuts(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed;
      
      // Ctrl+F - Focus search
      if (event.logicalKey == LogicalKeyboardKey.keyF && isControlPressed) {
        _searchController.clear();
        return KeyEventResult.handled;
      }
      
      // Ctrl+R or F5 - Refresh
      if ((event.logicalKey == LogicalKeyboardKey.keyR && isControlPressed) ||
          event.logicalKey == LogicalKeyboardKey.f5) {
        _refreshData();
        return KeyEventResult.handled;
      }
      
      // Ctrl+E - Export
      if (event.logicalKey == LogicalKeyboardKey.keyE && isControlPressed) {
        _exportData();
        return KeyEventResult.handled;
      }
      
      // Escape - Clear search
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _searchController.clear();
        _mainFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
    }
    
    return KeyEventResult.ignored;
  }
  
  /// Export analytics data
  void _exportData() {
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality will be implemented')),
    );
  }
  
  /// Refresh dashboard data
  void _refreshData() {
    setState(() => _isLoading = true);
    
    // Simulate data refresh
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }
}