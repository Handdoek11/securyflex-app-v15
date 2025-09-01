import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';
import 'shared_animation_controller.dart';
import 'dart:async';

/// Animation Performance Monitor Widget
/// 
/// Provides real-time monitoring of the shared animation controller system
/// and displays performance metrics for optimization verification.
class AnimationPerformanceMonitor extends StatefulWidget {
  final bool showInDebug;
  final Widget child;
  
  const AnimationPerformanceMonitor({
    super.key,
    required this.child,
    this.showInDebug = true,
  });
  
  @override
  State<AnimationPerformanceMonitor> createState() => _AnimationPerformanceMonitorState();
}

class _AnimationPerformanceMonitorState extends State<AnimationPerformanceMonitor> {
  Timer? _updateTimer;
  SharedAnimationMetrics _metrics = const SharedAnimationMetrics(
    totalControllersCreated: 0,
    activeControllers: 0,
    totalSubscriptions: 0,
    memorySavedMB: 0,
    memoryReductionPercentage: 0.0,
  );
  bool _showOverlay = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.showInDebug) {
      // Update metrics every 2 seconds
      _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) {
          setState(() {
            _metrics = SharedAnimationController.instance.getMetrics();
          });
        }
      });
    }
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        if (widget.showInDebug && _showOverlay)
          _buildPerformanceOverlay(context),
          
        if (widget.showInDebug)
          _buildToggleButton(context),
      ],
    );
  }
  
  Widget _buildToggleButton(BuildContext context) {
    return Positioned(
      top: 100,
      right: 16,
      child: GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DesignTokens.colorInfo,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _showOverlay ? Icons.close : Icons.analytics,
            color: DesignTokens.colorWhite,
            size: 16,
          ),
        ),
      ),
    );
  }
  
  Widget _buildPerformanceOverlay(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Positioned(
      top: 140,
      right: 16,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DesignTokens.colorInfo.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: DesignTokens.colorInfo,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Animation Performance',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontSize: DesignTokens.fontSizeBody,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            _buildMetricRow(
              'Controllers Created',
              '${_metrics.totalControllersCreated}',
              colorScheme,
            ),
            
            _buildMetricRow(
              'Active Controllers',
              '${_metrics.activeControllers}',
              colorScheme,
              highlight: _metrics.activeControllers <= 8,
            ),
            
            _buildMetricRow(
              'Total Subscriptions',
              '${_metrics.totalSubscriptions}',
              colorScheme,
            ),
            
            _buildMetricRow(
              'Memory Saved',
              '${_metrics.memorySavedMB}MB',
              colorScheme,
              highlight: _metrics.memorySavedMB > 100,
            ),
            
            _buildMetricRow(
              'Memory Reduction',
              '${_metrics.memoryReductionPercentage.toStringAsFixed(1)}%',
              colorScheme,
              highlight: _metrics.memoryReductionPercentage > 70,
            ),
            
            const SizedBox(height: 8),
            
            _buildPerformanceIndicator(colorScheme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricRow(
    String label,
    String value,
    ColorScheme colorScheme, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightRegular,
              fontSize: DesignTokens.fontSizeCaption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: highlight ? 6 : 0,
              vertical: highlight ? 2 : 0,
            ),
            decoration: highlight 
                ? BoxDecoration(
                    color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontSize: DesignTokens.fontSizeCaption,
                color: highlight 
                    ? DesignTokens.colorSuccess
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceIndicator(ColorScheme colorScheme) {
    final isOptimized = _metrics.memoryReductionPercentage > 70;
    final status = isOptimized ? 'OPTIMIZED' : 'OPTIMIZING';
    final statusColor = isOptimized ? DesignTokens.colorSuccess : DesignTokens.colorWarning;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOptimized ? Icons.check_circle : Icons.hourglass_empty,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightBold,
              fontSize: DesignTokens.fontSizeCaption,
              color: statusColor,
              letterSpacing: 0.5,
            ),
          ),
          if (isOptimized) ...[
            const Spacer(),
            Icon(
              Icons.trending_up,
              color: statusColor,
              size: 14,
            ),
          ]
        ],
      ),
    );
  }
}

/// Extension to show performance metrics in debug console
extension AnimationPerformanceLogging on SharedAnimationController {
  /// Log current performance metrics to debug console
  void logPerformanceStatus() {
    final metrics = getMetrics();
    
    debugPrint('\n📊 ANIMATION PERFORMANCE STATUS 📊');
    debugPrint('=====================================');
    debugPrint('📋 Controllers Created: ${metrics.totalControllersCreated}');
    debugPrint('⚙️ Active Controllers: ${metrics.activeControllers}');
    debugPrint('🔗 Total Subscriptions: ${metrics.totalSubscriptions}');
    debugPrint('💾 Memory Saved: ${metrics.memorySavedMB}MB');
    debugPrint('📈 Memory Reduction: ${metrics.memoryReductionPercentage.toStringAsFixed(1)}%');
    
    if (metrics.memoryReductionPercentage > 70) {
      debugPrint('✅ OPTIMIZATION TARGET ACHIEVED!');
    } else if (metrics.memoryReductionPercentage > 40) {
      debugPrint('🔶 OPTIMIZATION IN PROGRESS...');
    } else {
      debugPrint('🔴 OPTIMIZATION NEEDED');
    }
    
    debugPrint('=====================================\n');
  }
}
