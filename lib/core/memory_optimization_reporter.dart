import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'memory_leak_detector.dart';
import 'animation_controller_monitor.dart';
import 'tab_performance_monitor.dart';
import 'shared_animation_controller.dart';

/// Memory Optimization Reporter
/// 
/// This system generates comprehensive performance reports showing the
/// effectiveness of the tab header optimizations and tracks long-term trends.
/// 
/// **Reporting Capabilities:**
/// - Memory optimization effectiveness analysis
/// - Performance trend tracking
/// - Regression detection reports
/// - Cost-benefit analysis of optimizations
/// - Production-safe monitoring summaries
class MemoryOptimizationReporter {
  static final MemoryOptimizationReporter _instance = MemoryOptimizationReporter._internal();
  factory MemoryOptimizationReporter() => _instance;
  MemoryOptimizationReporter._internal();
  
  static MemoryOptimizationReporter get instance => _instance;
  
  // Historical data for trend analysis
  final List<OptimizationSnapshot> _snapshots = [];
  final List<PerformanceRegression> _regressions = [];
  
  // Report generation settings
  static const int _maxSnapshotsToKeep = 1000;
  static const Duration _snapshotInterval = Duration(minutes: 5);
  
  Timer? _snapshotTimer;
  bool _isTracking = false;
  
  /// Initialize optimization reporting
  void initialize() {
    if (_isTracking) return;
    
    _isTracking = true;
    _startPeriodicSnapshots();
    
    debugPrint('📊 MemoryOptimizationReporter: Performance reporting activated');
    debugPrint('   📸 Snapshot interval: ${_snapshotInterval.inMinutes} minutes');
    debugPrint('   📋 Max snapshots retained: $_maxSnapshotsToKeep');
  }
  
  /// Dispose optimization reporting
  void dispose() {
    _snapshotTimer?.cancel();
    _isTracking = false;
    
    debugPrint('📊 MemoryOptimizationReporter: Reporting system deactivated');
  }
  
  /// Generate comprehensive optimization report
  Future<ComprehensiveOptimizationReport> generateReport() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Collect current performance data
      final memoryReport = MemoryLeakDetector.instance.getOptimizationReport();
      final controllerMetrics = AnimationControllerMonitor.instance.getPerformanceMetrics();
      final tabReport = TabPerformanceMonitor.instance.getOverallPerformanceReport();
      final sharedMetrics = SharedAnimationController.instance.getMetrics();
      
      // Perform leak detection
      final leakAnalysis = await MemoryLeakDetector.instance.detectMemoryLeaks();
      final controllerLeaks = await AnimationControllerMonitor.instance.detectControllerLeaks();
      
      // Analyze trends
      final trendAnalysis = _analyzeTrends();
      final regressionAnalysis = _analyzeRegressions();
      
      // Calculate optimization effectiveness
      final effectiveness = _calculateOverallEffectiveness(
        memoryReport,
        controllerMetrics,
        tabReport,
      );
      
      stopwatch.stop();
      
      final report = ComprehensiveOptimizationReport(
        generatedAt: DateTime.now(),
        reportGenerationTimeMs: stopwatch.elapsedMilliseconds,
        
        // Current state
        memoryOptimizationReport: memoryReport,
        controllerPerformanceMetrics: controllerMetrics,
        tabPerformanceReport: tabReport,
        sharedAnimationMetrics: sharedMetrics,
        
        // Leak detection
        memoryLeakAnalysis: leakAnalysis,
        controllerLeaks: controllerLeaks,
        
        // Trend analysis
        trendAnalysis: trendAnalysis,
        regressionAnalysis: regressionAnalysis,
        
        // Overall assessment
        overallOptimizationEffectiveness: effectiveness,
        optimizationTargetsMet: _checkOptimizationTargets(memoryReport, tabReport),
        
        // Historical data
        totalSnapshots: _snapshots.length,
        trackingDuration: _calculateTrackingDuration(),
      );
      
      developer.log(
        '📊 Generated comprehensive optimization report in ${stopwatch.elapsedMilliseconds}ms',
        name: 'MemoryOptimizationReporter'
      );
      
      return report;
    } catch (e) {
      stopwatch.stop();
      developer.log(
        '🚨 Failed to generate optimization report: $e',
        name: 'MemoryOptimizationReporter'
      );
      
      rethrow;
    }
  }
  
  /// Generate production-safe summary report
  ProductionSummaryReport generateProductionSummary() {
    final memoryReport = MemoryLeakDetector.instance.getOptimizationReport();
    final tabReport = TabPerformanceMonitor.instance.getOverallPerformanceReport();
    final controllerMetrics = AnimationControllerMonitor.instance.getPerformanceMetrics();
    
    return ProductionSummaryReport(
      generatedAt: DateTime.now(),
      optimizationEffectiveness: memoryReport.optimizationEffectiveness,
      memorySavedMB: controllerMetrics.totalMemorySavedMB,
      memoryReductionPercentage: controllerMetrics.memoryReductionPercentage,
      tabPerformanceScore: tabReport.overallOptimizationEffectiveness,
      alertCount: memoryReport.alerts.length,
      violationCount: tabReport.totalViolations,
      trackingDuration: _calculateTrackingDuration(),
    );
  }
  
  /// Record performance regression
  void recordRegression(String component, String description, Map<String, dynamic> context) {
    final regression = PerformanceRegression(
      component: component,
      description: description,
      detectedAt: DateTime.now(),
      context: context,
    );
    
    _regressions.add(regression);
    
    // Keep only last 100 regressions
    if (_regressions.length > 100) {
      _regressions.removeAt(0);
    }
    
    developer.log(
      '🚨 Performance Regression Recorded: $component - $description',
      name: 'MemoryOptimizationReporter'
    );
  }
  
  /// Get historical performance trends
  TrendAnalysis getTrends({Duration? period}) {
    return _analyzeTrends(period: period);
  }
  
  /// Export report data as JSON (for external analysis)
  Map<String, dynamic> exportReportData() {
    return {
      'snapshots': _snapshots.map((s) => s.toMap()).toList(),
      'regressions': _regressions.map((r) => r.toMap()).toList(),
      'generatedAt': DateTime.now().toIso8601String(),
      'trackingDuration': _calculateTrackingDuration().inMinutes,
    };
  }
  
  /// Clear historical data (for testing)
  void clearHistoricalData() {
    _snapshots.clear();
    _regressions.clear();
    
    debugPrint('📊 MemoryOptimizationReporter: Historical data cleared');
  }
  
  // Private methods
  
  void _startPeriodicSnapshots() {
    _snapshotTimer = Timer.periodic(_snapshotInterval, (timer) {
      if (!_isTracking) {
        timer.cancel();
        return;
      }
      
      _takePerformanceSnapshot();
    });
  }
  
  void _takePerformanceSnapshot() {
    try {
      final memoryReport = MemoryLeakDetector.instance.getOptimizationReport();
      final controllerMetrics = AnimationControllerMonitor.instance.getPerformanceMetrics();
      final tabReport = TabPerformanceMonitor.instance.getOverallPerformanceReport();
      
      final snapshot = OptimizationSnapshot(
        timestamp: DateTime.now(),
        memoryOptimizationEffectiveness: memoryReport.optimizationEffectiveness,
        controllerPoolEfficiency: controllerMetrics.controllerPoolEfficiency,
        tabPerformanceScore: tabReport.overallOptimizationEffectiveness,
        memorySavedMB: controllerMetrics.totalMemorySavedMB,
        alertCount: memoryReport.alerts.length,
        violationCount: tabReport.totalViolations,
        activeControllers: memoryReport.controllerMetrics.activeControllers,
      );
      
      _snapshots.add(snapshot);
      
      // Keep only the most recent snapshots
      if (_snapshots.length > _maxSnapshotsToKeep) {
        _snapshots.removeAt(0);
      }
      
      // Check for performance regressions
      _checkForRegressions(snapshot);
      
    } catch (e) {
      developer.log(
        'Error taking performance snapshot: $e',
        name: 'MemoryOptimizationReporter'
      );
    }
  }
  
  void _checkForRegressions(OptimizationSnapshot currentSnapshot) {
    if (_snapshots.length < 10) return; // Need enough data for comparison
    
    final recent = _snapshots.length >= 10 ? _snapshots.sublist(_snapshots.length - 10) : _snapshots;
    final previousAverage = recent.take(5).map((s) => s.memoryOptimizationEffectiveness).reduce((a, b) => a + b) / 5;
    final currentAverage = recent.skip(5).map((s) => s.memoryOptimizationEffectiveness).reduce((a, b) => a + b) / 5;
    
    final regressionThreshold = 0.1; // 10% degradation threshold
    
    if (previousAverage - currentAverage > regressionThreshold) {
      recordRegression(
        'memory_optimization',
        'Memory optimization effectiveness dropped by ${((previousAverage - currentAverage) * 100).toStringAsFixed(1)}%',
        {
          'previousAverage': previousAverage,
          'currentAverage': currentAverage,
          'degradation': previousAverage - currentAverage,
        },
      );
    }
    
    // Check controller performance regression
    final prevControllerEfficiency = recent.take(5).map((s) => s.controllerPoolEfficiency).reduce((a, b) => a + b) / 5;
    final currentControllerEfficiency = recent.skip(5).map((s) => s.controllerPoolEfficiency).reduce((a, b) => a + b) / 5;
    
    if (prevControllerEfficiency - currentControllerEfficiency > regressionThreshold) {
      recordRegression(
        'controller_pool',
        'Controller pool efficiency dropped by ${((prevControllerEfficiency - currentControllerEfficiency) * 100).toStringAsFixed(1)}%',
        {
          'previousEfficiency': prevControllerEfficiency,
          'currentEfficiency': currentControllerEfficiency,
          'degradation': prevControllerEfficiency - currentControllerEfficiency,
        },
      );
    }
  }
  
  TrendAnalysis _analyzeTrends({Duration? period}) {
    final now = DateTime.now();
    final analysisWindow = period ?? Duration(hours: 24);
    
    final relevantSnapshots = _snapshots
        .where((snapshot) => now.difference(snapshot.timestamp) <= analysisWindow)
        .toList();
    
    if (relevantSnapshots.length < 2) {
      return TrendAnalysis(
        period: analysisWindow,
        dataPoints: relevantSnapshots.length,
        memoryTrend: TrendDirection.stable,
        controllerTrend: TrendDirection.stable,
        tabPerformanceTrend: TrendDirection.stable,
        regressionCount: 0,
        improvementDetected: false,
      );
    }
    
    // Calculate trends
    final memoryTrend = _calculateTrendDirection(
      relevantSnapshots.map((s) => s.memoryOptimizationEffectiveness).toList()
    );
    
    final controllerTrend = _calculateTrendDirection(
      relevantSnapshots.map((s) => s.controllerPoolEfficiency).toList()
    );
    
    final tabTrend = _calculateTrendDirection(
      relevantSnapshots.map((s) => s.tabPerformanceScore).toList()
    );
    
    final recentRegressions = _regressions
        .where((r) => now.difference(r.detectedAt) <= analysisWindow)
        .length;
    
    final improvementDetected = memoryTrend == TrendDirection.improving ||
                               controllerTrend == TrendDirection.improving ||
                               tabTrend == TrendDirection.improving;
    
    return TrendAnalysis(
      period: analysisWindow,
      dataPoints: relevantSnapshots.length,
      memoryTrend: memoryTrend,
      controllerTrend: controllerTrend,
      tabPerformanceTrend: tabTrend,
      regressionCount: recentRegressions,
      improvementDetected: improvementDetected,
    );
  }
  
  TrendDirection _calculateTrendDirection(List<double> values) {
    if (values.length < 2) return TrendDirection.stable;
    
    final first = values.take(values.length ~/ 2).reduce((a, b) => a + b) / (values.length ~/ 2);
    final second = values.skip(values.length ~/ 2).reduce((a, b) => a + b) / (values.length - values.length ~/ 2);
    
    final change = second - first;
    
    if (change > 0.05) return TrendDirection.improving;
    if (change < -0.05) return TrendDirection.degrading;
    return TrendDirection.stable;
  }
  
  RegressionAnalysis _analyzeRegressions() {
    final now = DateTime.now();
    final recent = _regressions.where((r) => now.difference(r.detectedAt).inHours <= 24).toList();
    
    final componentFrequency = <String, int>{};
    for (final regression in recent) {
      componentFrequency[regression.component] = (componentFrequency[regression.component] ?? 0) + 1;
    }
    
    final mostProblematicComponent = componentFrequency.isNotEmpty
        ? componentFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null;
    
    return RegressionAnalysis(
      totalRegressions: _regressions.length,
      recentRegressions: recent.length,
      mostProblematicComponent: mostProblematicComponent,
      componentFrequency: componentFrequency,
      analysisTimestamp: now,
    );
  }
  
  double _calculateOverallEffectiveness(
    MemoryOptimizationReport memoryReport,
    ControllerPerformanceMetrics controllerMetrics,
    TabPerformanceReport tabReport,
  ) {
    // Weight different aspects of effectiveness
    const memoryWeight = 0.4;
    const controllerWeight = 0.3;
    const tabWeight = 0.3;
    
    final memoryScore = memoryReport.optimizationEffectiveness;
    final controllerScore = controllerMetrics.controllerPoolEfficiency / 100.0;
    final tabScore = tabReport.overallOptimizationEffectiveness;
    
    return (memoryScore * memoryWeight) + 
           (controllerScore * controllerWeight) + 
           (tabScore * tabWeight);
  }
  
  List<String> _checkOptimizationTargets(
    MemoryOptimizationReport memoryReport,
    TabPerformanceReport tabReport,
  ) {
    final targetsMet = <String>[];
    
    // Check individual screen targets
    for (final entry in memoryReport.currentSnapshots.entries) {
      final screenName = entry.key;
      final snapshot = entry.value;
      final baseline = memoryReport.baselines[screenName];
      
      if (snapshot != null && baseline != null) {
        if (snapshot.memoryUsageMB <= baseline.targetMemoryMB) {
          targetsMet.add('${screenName}_memory_target');
        }
      }
    }
    
    // Check controller optimization targets
    if (memoryReport.controllerMetrics.activeControllers <= 8) {
      targetsMet.add('controller_pool_size');
    }
    
    if (memoryReport.controllerMetrics.memoryReductionPercentage >= 80) {
      targetsMet.add('memory_reduction_target');
    }
    
    // Check performance targets
    if (tabReport.totalViolations == 0) {
      targetsMet.add('zero_performance_violations');
    }
    
    return targetsMet;
  }
  
  Duration _calculateTrackingDuration() {
    if (_snapshots.isEmpty) return Duration.zero;
    
    return DateTime.now().difference(_snapshots.first.timestamp);
  }
}

/// Performance snapshot for trend analysis
class OptimizationSnapshot {
  final DateTime timestamp;
  final double memoryOptimizationEffectiveness;
  final double controllerPoolEfficiency;
  final double tabPerformanceScore;
  final int memorySavedMB;
  final int alertCount;
  final int violationCount;
  final int activeControllers;
  
  const OptimizationSnapshot({
    required this.timestamp,
    required this.memoryOptimizationEffectiveness,
    required this.controllerPoolEfficiency,
    required this.tabPerformanceScore,
    required this.memorySavedMB,
    required this.alertCount,
    required this.violationCount,
    required this.activeControllers,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'memoryOptimizationEffectiveness': memoryOptimizationEffectiveness,
      'controllerPoolEfficiency': controllerPoolEfficiency,
      'tabPerformanceScore': tabPerformanceScore,
      'memorySavedMB': memorySavedMB,
      'alertCount': alertCount,
      'violationCount': violationCount,
      'activeControllers': activeControllers,
    };
  }
}

/// Performance regression event
class PerformanceRegression {
  final String component;
  final String description;
  final DateTime detectedAt;
  final Map<String, dynamic> context;
  
  const PerformanceRegression({
    required this.component,
    required this.description,
    required this.detectedAt,
    required this.context,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'component': component,
      'description': description,
      'detectedAt': detectedAt.toIso8601String(),
      'context': context,
    };
  }
}

/// Comprehensive optimization report
class ComprehensiveOptimizationReport {
  final DateTime generatedAt;
  final int reportGenerationTimeMs;
  
  // Current state
  final MemoryOptimizationReport memoryOptimizationReport;
  final ControllerPerformanceMetrics controllerPerformanceMetrics;
  final TabPerformanceReport tabPerformanceReport;
  final SharedAnimationMetrics sharedAnimationMetrics;
  
  // Leak detection
  final MemoryLeakAnalysis memoryLeakAnalysis;
  final List<ControllerLeak> controllerLeaks;
  
  // Analysis
  final TrendAnalysis trendAnalysis;
  final RegressionAnalysis regressionAnalysis;
  
  // Overall assessment
  final double overallOptimizationEffectiveness;
  final List<String> optimizationTargetsMet;
  
  // Historical data
  final int totalSnapshots;
  final Duration trackingDuration;
  
  const ComprehensiveOptimizationReport({
    required this.generatedAt,
    required this.reportGenerationTimeMs,
    required this.memoryOptimizationReport,
    required this.controllerPerformanceMetrics,
    required this.tabPerformanceReport,
    required this.sharedAnimationMetrics,
    required this.memoryLeakAnalysis,
    required this.controllerLeaks,
    required this.trendAnalysis,
    required this.regressionAnalysis,
    required this.overallOptimizationEffectiveness,
    required this.optimizationTargetsMet,
    required this.totalSnapshots,
    required this.trackingDuration,
  });
  
  @override
  String toString() {
    return 'ComprehensiveOptimizationReport(';
  }
}

/// Production-safe summary report
class ProductionSummaryReport {
  final DateTime generatedAt;
  final double optimizationEffectiveness;
  final int memorySavedMB;
  final double memoryReductionPercentage;
  final double tabPerformanceScore;
  final int alertCount;
  final int violationCount;
  final Duration trackingDuration;
  
  const ProductionSummaryReport({
    required this.generatedAt,
    required this.optimizationEffectiveness,
    required this.memorySavedMB,
    required this.memoryReductionPercentage,
    required this.tabPerformanceScore,
    required this.alertCount,
    required this.violationCount,
    required this.trackingDuration,
  });
  
  @override
  String toString() {
    return 'ProductionSummaryReport(';
  }
}

/// Trend analysis result
class TrendAnalysis {
  final Duration period;
  final int dataPoints;
  final TrendDirection memoryTrend;
  final TrendDirection controllerTrend;
  final TrendDirection tabPerformanceTrend;
  final int regressionCount;
  final bool improvementDetected;
  
  const TrendAnalysis({
    required this.period,
    required this.dataPoints,
    required this.memoryTrend,
    required this.controllerTrend,
    required this.tabPerformanceTrend,
    required this.regressionCount,
    required this.improvementDetected,
  });
}

/// Regression analysis result
class RegressionAnalysis {
  final int totalRegressions;
  final int recentRegressions;
  final String? mostProblematicComponent;
  final Map<String, int> componentFrequency;
  final DateTime analysisTimestamp;
  
  const RegressionAnalysis({
    required this.totalRegressions,
    required this.recentRegressions,
    required this.mostProblematicComponent,
    required this.componentFrequency,
    required this.analysisTimestamp,
  });
}

/// Trend direction
enum TrendDirection {
  improving,
  stable,
  degrading,
}

