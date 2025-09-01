import 'package:flutter/material.dart';
import 'memory_leak_monitoring_system.dart';
import 'tab_performance_monitor.dart';
import 'performance_debug_overlay.dart';

/// Example usage of the Memory Leak Monitoring System
/// 
/// This file demonstrates how to integrate the monitoring system
/// into your widgets and get performance reports.
class MonitoringSystemExample extends StatefulWidget {
  const MonitoringSystemExample({super.key});
  
  @override
  State<MonitoringSystemExample> createState() => _MonitoringSystemExampleState();
}

class _MonitoringSystemExampleState extends State<MonitoringSystemExample> 
    with PerformanceTrackingMixin {
  
  String _statusText = 'Initializing monitoring system...';
  bool _monitoringInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeMonitoring();
  }
  
  Future<void> _initializeMonitoring() async {
    try {
      // Initialize the complete monitoring system
      await MemoryLeakMonitoringSystem.instance.initialize();
      
      if (mounted) {
        setState(() {
          _statusText = 'Monitoring system initialized successfully!';
          _monitoringInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Failed to initialize monitoring: $e';
        });
      }
    }
  }
  
  Future<void> _getSystemStatus() async {
    if (!_monitoringInitialized) return;
    
    try {
      final status = await MemoryLeakMonitoringSystem.instance.getSystemStatus();
      
      if (mounted) {
        setState(() {
          _statusText = 'System Status:\n' +
              'Health: ${status.healthStatus.toString().split('.').last.toUpperCase()}\n' +
              'Dashboard Memory: ${status.dashboardMemoryMB}MB\n' +
              'Jobs Memory: ${status.jobsMemoryMB}MB\n' +
              'Planning Memory: ${status.planningMemoryMB}MB\n' +
              'Active Controllers: ${status.activeControllers}\n' +
              'Memory Saved: ${status.memorySavedMB}MB (${status.memoryReductionPercentage.toStringAsFixed(1)}%)\n' +
              'Memory Leaks: ${status.memoryLeaksDetected}\n' +
              'Controller Leaks: ${status.controllerLeaksDetected}\n' +
              'Active Alerts: ${status.activeAlerts}\n' +
              'Status Check: ${status.statusCheckTimeMs}ms';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Error getting status: $e';
        });
      }
    }
  }
  
  Future<void> _generateReport() async {
    if (!_monitoringInitialized) return;
    
    try {
      setState(() => _statusText = 'Generating comprehensive report...');
      
      final report = await MemoryLeakMonitoringSystem.instance.generateReport();
      
      if (mounted) {
        setState(() {
          _statusText = 'Comprehensive Report:\n' +
              'Overall Effectiveness: ${(report.overallOptimizationEffectiveness * 100).toStringAsFixed(1)}%\n' +
              'Memory Leaks Detected: ${report.memoryLeakAnalysis.leaksDetected.length}\n' +
              'Controller Leaks: ${report.controllerLeaks.length}\n' +
              'Recent Regressions: ${report.regressionAnalysis.recentRegressions}\n' +
              'Targets Met: ${report.optimizationTargetsMet.length}/7\n' +
              'Tracking Duration: ${report.trackingDuration.inMinutes}min\n' +
              'Report Generation: ${report.reportGenerationTimeMs}ms';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Error generating report: $e';
        });
      }
    }
  }
  
  void _simulateTabSwitch(String tabName) {
    // Simulate tab activation for monitoring
    TabPerformanceMonitor.instance.recordTabActivated(tabName);
    
    setState(() {
      _statusText = 'Simulated switch to $tabName tab';
    });
  }
  
  @override
  Widget buildWithPerformanceTracking(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Leak Monitoring Example'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        elevation: 1.0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2.0,
              surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monitoring System Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      constraints: BoxConstraints(minHeight: 200),
                      child: SingleChildScrollView(
                        child: Text(
                          _statusText,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Monitoring Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _monitoringInitialized ? _getSystemStatus : null,
                  icon: Icon(Icons.health_and_safety),
                  label: Text('Get Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _monitoringInitialized ? _generateReport : null,
                  icon: Icon(Icons.assessment),
                  label: Text('Generate Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Tab Simulation (for testing)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _simulateTabSwitch('dashboard'),
                  child: Text('Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _simulateTabSwitch('jobs'),
                  child: Text('Jobs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _simulateTabSwitch('planning'),
                  child: Text('Planning'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            Spacer(),
            Card(
              elevation: 2.0,
              surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Optimization Targets',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Dashboard: 40MB target (50MB alert)\n'
                      '• Jobs: 10MB target (15MB alert)\n'
                      '• Planning: 25MB target (30MB alert)\n'
                      '• Animation Controllers: ≤8 active\n'
                      '• Tab Switching: <100ms\n'
                      '• Memory Reduction: ≥80%\n'
                      '• Leak Detection: <1000ms',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}