import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'memory_leak_detector.dart';
import 'animation_controller_monitor.dart';
import 'tab_performance_monitor.dart';

/// Performance Debug Overlay for Real-Time Monitoring
/// 
/// This overlay provides real-time debugging information about:
/// - Memory usage per screen (Dashboard, Jobs, Planning)
/// - Animation controller pool status
/// - Tab switching performance metrics
/// - Memory leak alerts
/// - Optimization effectiveness indicators
/// 
/// **Debug Mode Only:** This overlay only appears in debug builds
/// and has zero impact on production performance.
class PerformanceDebugOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;
  
  const PerformanceDebugOverlay({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });
  
  @override
  State<PerformanceDebugOverlay> createState() => _PerformanceDebugOverlayState();
}

class _PerformanceDebugOverlayState extends State<PerformanceDebugOverlay> {
  Timer? _updateTimer;
  bool _isVisible = false;
  DebugOverlayMode _mode = DebugOverlayMode.compact;
  
  // Performance data
  MemoryOptimizationReport? _memoryReport;
  ControllerPerformanceMetrics? _controllerMetrics;
  TabPerformanceReport? _tabReport;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.enabled && kDebugMode) {
      _startPerformanceTracking();
    }
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !kDebugMode) {
      return widget.child;
    }
    
    return Stack(
      children: [
        widget.child,
        if (_isVisible) _buildDebugOverlay(),
        _buildToggleButton(),
      ],
    );
  }
  
  void _startPerformanceTracking() {
    // Update performance data every 2 seconds
    _updateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      _updatePerformanceData();
    });
  }
  
  void _updatePerformanceData() async {
    try {
      final memoryReport = MemoryLeakDetector.instance.getOptimizationReport();
      final controllerMetrics = AnimationControllerMonitor.instance.getPerformanceMetrics();
      final tabReport = TabPerformanceMonitor.instance.getOverallPerformanceReport();
      
      if (mounted) {
        setState(() {
          _memoryReport = memoryReport;
          _controllerMetrics = controllerMetrics;
          _tabReport = tabReport;
        });
      }
    } catch (e) {
      debugPrint('Error updating performance data: $e');
    }
  }
  
  Widget _buildDebugOverlay() {
    return Positioned(
      top: 100,
      left: 8,
      right: 8,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(8),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        children: [
          Icon(Icons.bug_report, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'SecuryFlex Performance Monitor',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Spacer(),
          _buildModeToggle(),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _isVisible = false),
            child: Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModeToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = _mode == DebugOverlayMode.compact 
              ? DebugOverlayMode.detailed 
              : DebugOverlayMode.compact;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _mode == DebugOverlayMode.compact ? 'Compact' : 'Detailed',
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    if (_memoryReport == null || _controllerMetrics == null || _tabReport == null) {
      return Center(
        child: Text(
          'Loading performance data...',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMemorySection(),
        _buildDivider(),
        _buildControllerSection(),
        _buildDivider(),
        _buildTabPerformanceSection(),
        if (_memoryReport!.alerts.isNotEmpty) ...[
          _buildDivider(),
          _buildAlertsSection(),
        ],
      ],
    );
  }
  
  Widget _buildMemorySection() {
    final report = _memoryReport!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📊 Memory Optimization'),
        SizedBox(height: 4),
        _buildMetricRow(
          'Optimization Effectiveness',
          '${(report.optimizationEffectiveness * 100).toStringAsFixed(1)}%',
          report.optimizationEffectiveness > 0.8 ? Colors.green : Colors.orange,
        ),
        for (final entry in report.currentSnapshots.entries)
          if (entry.value != null)
            _buildMemoryMetric(
              entry.key,
              entry.value!.memoryUsageMB,
              report.baselines[entry.key]?.targetMemoryMB ?? 0,
              report.baselines[entry.key]?.thresholdMemoryMB ?? 0,
            ),
      ],
    );
  }
  
  Widget _buildControllerSection() {
    final metrics = _controllerMetrics!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🎬 Animation Controllers'),
        SizedBox(height: 4),
        _buildMetricRow(
          'Memory Saved',
          '${metrics.totalMemorySavedMB}MB (${metrics.memoryReductionPercentage.toStringAsFixed(1)}%)',
          metrics.memoryReductionPercentage > 50 ? Colors.green : Colors.orange,
        ),
        _buildMetricRow(
          'Pool Efficiency',
          '${metrics.controllerPoolEfficiency.toStringAsFixed(1)}%',
          metrics.controllerPoolEfficiency > 80 ? Colors.green : Colors.orange,
        ),
        _buildMetricRow(
          'Disposal Success',
          '${metrics.disposalSuccessRate.toStringAsFixed(1)}%',
          metrics.disposalSuccessRate > 95 ? Colors.green : Colors.red,
        ),
        if (_mode == DebugOverlayMode.detailed) ...[
          _buildMetricRow(
            'Average Lifetime',
            '${metrics.averageControllerLifetime.inSeconds}s',
            Colors.blue,
          ),
          _buildMetricRow(
            'Leak Count',
            '${metrics.leakCount}',
            metrics.leakCount == 0 ? Colors.green : Colors.red,
          ),
        ],
      ],
    );
  }
  
  Widget _buildTabPerformanceSection() {
    final report = _tabReport!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🔄 Tab Performance'),
        SizedBox(height: 4),
        _buildMetricRow(
          'Overall Effectiveness',
          '${(report.overallOptimizationEffectiveness * 100).toStringAsFixed(1)}%',
          report.overallOptimizationEffectiveness > 0.8 ? Colors.green : Colors.orange,
        ),
        _buildMetricRow(
          'Total Violations',
          '${report.totalViolations}',
          report.totalViolations == 0 ? Colors.green : Colors.red,
        ),
        if (report.currentActiveTab != null)
          _buildMetricRow(
            'Active Tab',
            report.currentActiveTab!,
            Colors.blue,
          ),
        if (_mode == DebugOverlayMode.detailed)
          for (final entry in report.tabAnalyses.entries)
            _buildTabAnalysis(entry.key, entry.value),
      ],
    );
  }
  
  Widget _buildTabAnalysis(String tabName, TabPerformanceAnalysis analysis) {
    return Container(
      margin: EdgeInsets.only(top: 4),
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tabName.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${analysis.currentMemoryUsageMB}/${analysis.targetMemoryMB}MB',
                  style: TextStyle(
                    color: analysis.isOptimizationEffective ? Colors.green : Colors.orange,
                    fontSize: 10,
                  ),
                ),
              ),
              Text(
                'Build: ${analysis.averageBuildTimeMs.toStringAsFixed(1)}ms',
                style: TextStyle(color: Colors.blue, fontSize: 10),
              ),
            ],
          ),
          if (analysis.violations.isNotEmpty)
            Text(
              'Violations: ${analysis.violations.length}',
              style: TextStyle(color: Colors.red, fontSize: 10),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAlertsSection() {
    final alerts = _memoryReport!.alerts;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🚨 Active Alerts (${alerts.length})'),
        SizedBox(height: 4),
        for (final alert in alerts.take(5)) // Show only last 5 alerts
          Container(
            margin: EdgeInsets.only(bottom: 4),
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.shade900,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.type.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  alert.message,
                  style: TextStyle(color: Colors.white, fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatTimestamp(alert.timestamp),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 9),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildToggleButton() {
    return Positioned(
      top: 50,
      right: 8,
      child: GestureDetector(
        onTap: () => setState(() => _isVisible = !_isVisible),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isVisible ? Colors.green : Colors.grey.shade800,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green, width: 1),
          ),
          child: Icon(
            Icons.analytics,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.green.shade300,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }
  
  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMemoryMetric(String screenName, int currentMB, int targetMB, int thresholdMB) {
    final isOptimal = currentMB <= targetMB;
    final isWithinThreshold = currentMB <= thresholdMB;
    final color = isOptimal 
        ? Colors.green 
        : isWithinThreshold 
            ? Colors.orange 
            : Colors.red;
    
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              screenName.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  '${currentMB}MB',
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  ' / ${targetMB}MB',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (currentMB / thresholdMB).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: Colors.grey.shade600,
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Debug overlay display modes
enum DebugOverlayMode {
  compact,
  detailed,
}

/// Widget mixin for automatic performance tracking
mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  late String _widgetName;
  late Stopwatch _buildStopwatch;
  
  @override
  void initState() {
    super.initState();
    _widgetName = T.toString();
    _buildStopwatch = Stopwatch();
    
    // Record widget activation for tab monitoring
    if (_widgetName.toLowerCase().contains('dashboard')) {
      TabPerformanceMonitor.instance.recordTabActivated('dashboard');
    } else if (_widgetName.toLowerCase().contains('jobs')) {
      TabPerformanceMonitor.instance.recordTabActivated('jobs');
    } else if (_widgetName.toLowerCase().contains('planning')) {
      TabPerformanceMonitor.instance.recordTabActivated('planning');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    _buildStopwatch.reset();
    _buildStopwatch.start();
    
    final widget = buildWithPerformanceTracking(context);
    
    _buildStopwatch.stop();
    
    // Record build performance
    final buildTimeMs = _buildStopwatch.elapsedMilliseconds;
    String tabName = 'unknown';
    if (_widgetName.toLowerCase().contains('dashboard')) {
      tabName = 'dashboard';
    } else if (_widgetName.toLowerCase().contains('jobs')) {
      tabName = 'jobs';
    } else if (_widgetName.toLowerCase().contains('planning')) {
      tabName = 'planning';
    }
    
    if (tabName != 'unknown') {
      TabPerformanceMonitor.instance.recordTabBuild(
        tabName,
        buildTimeMs,
        {'widgetName': _widgetName},
      );
    }
    
    return widget;
  }
  
  @override
  void dispose() {
    // Record widget deactivation
    if (_widgetName.toLowerCase().contains('dashboard')) {
      TabPerformanceMonitor.instance.recordTabDeactivated('dashboard');
    } else if (_widgetName.toLowerCase().contains('jobs')) {
      TabPerformanceMonitor.instance.recordTabDeactivated('jobs');
    } else if (_widgetName.toLowerCase().contains('planning')) {
      TabPerformanceMonitor.instance.recordTabDeactivated('planning');
    }
    
    super.dispose();
  }
  
  /// Override this instead of build()
  Widget buildWithPerformanceTracking(BuildContext context);
}