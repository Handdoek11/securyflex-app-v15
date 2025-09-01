import 'package:flutter/foundation.dart';

/// Cost monitoring and alerting system for SecuryFlex analytics
/// Tracks Firestore usage, costs, and provides optimization recommendations
class AnalyticsCostMonitor {
  static AnalyticsCostMonitor? _instance;
  static AnalyticsCostMonitor get instance {
    _instance ??= AnalyticsCostMonitor._();
    return _instance!;
  }

  AnalyticsCostMonitor._();

  // Cost tracking
  final Map<String, OperationCost> _operationCosts = {};
  final List<CostAlert> _costAlerts = [];
  final Map<String, DailyCostSummary> _dailyCosts = {};
  
  // Cost thresholds (in euros)
  static const double dailyCostThreshold = 10.0;
  static const double weeklyCostThreshold = 50.0;
  static const double monthlyCostThreshold = 200.0;
  static const double operationCostThreshold = 0.50;
  
  // Firestore pricing (as of 2024, in euros)
  static const double readCostPer100k = 0.036;
  static const double writeCostPer100k = 0.108;
  static const double deleteCostPer100k = 0.012;
  static const double storageCostPerGB = 0.162; // per month

  /// Track a Firestore operation cost
  void trackOperation({
    required String operationType, // 'read', 'write', 'delete'
    required String collection,
    required int operationCount,
    String? queryType,
    Duration? executionTime,
  }) {
    final cost = _calculateOperationCost(operationType, operationCount);
    final operationKey = '${operationType}_${collection}_${queryType ?? 'standard'}';
    
    final existingCost = _operationCosts[operationKey] ?? OperationCost(
      operationType: operationType,
      collection: collection,
      queryType: queryType,
    );
    
    existingCost.addOperation(operationCount, cost, executionTime);
    _operationCosts[operationKey] = existingCost;
    
    // Update daily summary
    _updateDailyCostSummary(cost, operationType);
    
    // Check for cost alerts
    _checkCostAlerts(operationKey, existingCost);
    
    debugPrint('Analytics cost tracked: $operationType on $collection, count: $operationCount, cost: €${cost.toStringAsFixed(4)}');
  }

  /// Calculate cost for Firestore operations
  double _calculateOperationCost(String operationType, int operationCount) {
    switch (operationType.toLowerCase()) {
      case 'read':
        return (operationCount / 100000) * readCostPer100k;
      case 'write':
        return (operationCount / 100000) * writeCostPer100k;
      case 'delete':
        return (operationCount / 100000) * deleteCostPer100k;
      default:
        return 0.0;
    }
  }

  /// Update daily cost summary
  void _updateDailyCostSummary(double cost, String operationType) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final summary = _dailyCosts[today] ?? DailyCostSummary(date: today);
    
    summary.addCost(cost, operationType);
    _dailyCosts[today] = summary;
  }

  /// Check for cost alerts
  void _checkCostAlerts(String operationKey, OperationCost operationCost) {
    final now = DateTime.now();
    
    // Check daily cost threshold
    final today = now.toIso8601String().split('T')[0];
    final dailySummary = _dailyCosts[today];
    if (dailySummary != null && dailySummary.totalCost > dailyCostThreshold) {
      _addAlert(CostAlert(
        type: AlertType.dailyThreshold,
        message: 'Daily cost threshold exceeded: €${dailySummary.totalCost.toStringAsFixed(2)}',
        threshold: dailyCostThreshold,
        actualValue: dailySummary.totalCost,
        timestamp: now,
      ));
    }
    
    // Check operation cost threshold
    if (operationCost.averageCost > operationCostThreshold) {
      _addAlert(CostAlert(
        type: AlertType.operationThreshold,
        message: 'High cost operation detected: $operationKey (€${operationCost.averageCost.toStringAsFixed(4)} avg)',
        threshold: operationCostThreshold,
        actualValue: operationCost.averageCost,
        timestamp: now,
        operationKey: operationKey,
      ));
    }
    
    // Check for expensive queries
    if (operationCost.operationType == 'read' && operationCost.averageOperationCount > 1000) {
      _addAlert(CostAlert(
        type: AlertType.expensiveQuery,
        message: 'Expensive query detected: $operationKey (${operationCost.averageOperationCount} reads avg)',
        threshold: 1000,
        actualValue: operationCost.averageOperationCount.toDouble(),
        timestamp: now,
        operationKey: operationKey,
      ));
    }
  }

  /// Add cost alert
  void _addAlert(CostAlert alert) {
    // Avoid duplicate alerts within 1 hour
    final recentAlerts = _costAlerts.where((a) => 
      a.type == alert.type && 
      a.operationKey == alert.operationKey &&
      DateTime.now().difference(a.timestamp).inHours < 1
    );
    
    if (recentAlerts.isEmpty) {
      _costAlerts.add(alert);
      debugPrint('COST ALERT: ${alert.message}');
      
      // Keep only recent alerts
      if (_costAlerts.length > 100) {
        _costAlerts.removeRange(0, _costAlerts.length - 100);
      }
    }
  }

  /// Get cost summary for a date range
  CostSummaryReport getCostSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();
    
    double totalCost = 0.0;
    int totalReads = 0;
    int totalWrites = 0;
    int totalDeletes = 0;
    
    final dailySummaries = <DailyCostSummary>[];
    
    for (var date = start; date.isBefore(end) || date.isAtSameMomentAs(end); date = date.add(const Duration(days: 1))) {
      final dateStr = date.toIso8601String().split('T')[0];
      final summary = _dailyCosts[dateStr];
      
      if (summary != null) {
        dailySummaries.add(summary);
        totalCost += summary.totalCost;
        totalReads += summary.totalReads;
        totalWrites += summary.totalWrites;
        totalDeletes += summary.totalDeletes;
      }
    }
    
    // Calculate projections
    final daysInRange = end.difference(start).inDays + 1;
    final avgDailyCost = daysInRange > 0 ? totalCost / daysInRange : 0.0;
    final monthlyProjection = avgDailyCost * 30;
    
    return CostSummaryReport(
      startDate: start,
      endDate: end,
      totalCost: totalCost,
      totalReads: totalReads,
      totalWrites: totalWrites,
      totalDeletes: totalDeletes,
      averageDailyCost: avgDailyCost,
      monthlyProjection: monthlyProjection,
      dailySummaries: dailySummaries,
    );
  }

  /// Get most expensive operations
  List<OperationCost> getMostExpensiveOperations({int limit = 10}) {
    final operations = _operationCosts.values.toList()
      ..sort((a, b) => b.totalCost.compareTo(a.totalCost));
    
    return operations.take(limit).toList();
  }

  /// Get cost optimization recommendations
  List<String> getCostOptimizationRecommendations() {
    final recommendations = <String>[];
    
    // Check for expensive read operations
    final expensiveReads = _operationCosts.values
        .where((op) => op.operationType == 'read' && op.averageOperationCount > 500)
        .toList()
      ..sort((a, b) => b.averageOperationCount.compareTo(a.averageOperationCount));
    
    if (expensiveReads.isNotEmpty) {
      recommendations.add('Optimize queries with high read counts: ${expensiveReads.take(3).map((op) => op.collection).join(", ")}');
    }
    
    // Check for frequent write operations
    final frequentWrites = _operationCosts.values
        .where((op) => op.operationType == 'write' && op.operationCount > 1000)
        .toList()
      ..sort((a, b) => b.operationCount.compareTo(a.operationCount));
    
    if (frequentWrites.isNotEmpty) {
      recommendations.add('Consider batching writes for: ${frequentWrites.take(3).map((op) => op.collection).join(", ")}');
    }
    
    // Check daily cost trend
    final recentDays = _dailyCosts.values
        .where((summary) => DateTime.now().difference(DateTime.parse(summary.date)).inDays <= 7)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    if (recentDays.length >= 2) {
      final latestCost = recentDays.first.totalCost;
      final previousCost = recentDays[1].totalCost;
      
      if (latestCost > previousCost * 1.5) {
        recommendations.add('Daily costs increased significantly. Review recent query changes.');
      }
    }
    
    // Check for missing indexes (high read counts)
    final potentialMissingIndexes = _operationCosts.values
        .where((op) => op.operationType == 'read' && op.averageOperationCount > 100 && op.queryType != 'simple')
        .toList();
    
    if (potentialMissingIndexes.isNotEmpty) {
      recommendations.add('Potential missing indexes detected. Review composite index requirements.');
    }
    
    // Check monthly projection
    final summary = getCostSummary();
    if (summary.monthlyProjection > monthlyCostThreshold) {
      recommendations.add('Monthly cost projection (€${summary.monthlyProjection.toStringAsFixed(2)}) exceeds threshold. Consider optimization.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Cost usage is within optimal ranges. Continue monitoring.');
    }
    
    return recommendations;
  }

  /// Get recent cost alerts
  List<CostAlert> getRecentAlerts({int hours = 24}) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return _costAlerts.where((alert) => alert.timestamp.isAfter(cutoff)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get cost breakdown by collection
  Map<String, double> getCostBreakdownByCollection() {
    final breakdown = <String, double>{};
    
    for (final operation in _operationCosts.values) {
      breakdown[operation.collection] = (breakdown[operation.collection] ?? 0.0) + operation.totalCost;
    }
    
    return Map.fromEntries(
      breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );
  }

  /// Get cost breakdown by operation type
  Map<String, double> getCostBreakdownByOperation() {
    final breakdown = <String, double>{};
    
    for (final operation in _operationCosts.values) {
      breakdown[operation.operationType] = (breakdown[operation.operationType] ?? 0.0) + operation.totalCost;
    }
    
    return breakdown;
  }

  /// Export cost data for analysis
  Map<String, dynamic> exportCostData() {
    return {
      'summary': getCostSummary().toMap(),
      'operations': _operationCosts.values.map((op) => op.toMap()).toList(),
      'alerts': _costAlerts.map((alert) => alert.toMap()).toList(),
      'dailyCosts': _dailyCosts.values.map((summary) => summary.toMap()).toList(),
      'breakdowns': {
        'byCollection': getCostBreakdownByCollection(),
        'byOperation': getCostBreakdownByOperation(),
      },
      'recommendations': getCostOptimizationRecommendations(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Clear cost data
  void clearCostData() {
    _operationCosts.clear();
    _costAlerts.clear();
    _dailyCosts.clear();
  }

  /// Get cost monitoring status
  Map<String, dynamic> getMonitoringStatus() {
    final recentAlerts = getRecentAlerts(hours: 24);
    final summary = getCostSummary(startDate: DateTime.now().subtract(const Duration(days: 7)));
    
    return {
      'isMonitoring': true,
      'trackedOperations': _operationCosts.length,
      'recentAlerts': recentAlerts.length,
      'weeklySpend': summary.totalCost,
      'monthlyProjection': summary.monthlyProjection,
      'alertThresholds': {
        'daily': dailyCostThreshold,
        'weekly': weeklyCostThreshold,
        'monthly': monthlyCostThreshold,
        'operation': operationCostThreshold,
      },
      'lastUpdate': DateTime.now().toIso8601String(),
    };
  }
}

/// Operation cost tracking
class OperationCost {
  final String operationType;
  final String collection;
  final String? queryType;
  
  int operationCount = 0;
  double totalCost = 0.0;
  final List<double> costs = [];
  final List<int> operationCounts = [];
  final List<Duration> executionTimes = [];
  DateTime lastOperation = DateTime.now();

  OperationCost({
    required this.operationType,
    required this.collection,
    this.queryType,
  });

  void addOperation(int count, double cost, Duration? executionTime) {
    operationCount += count;
    totalCost += cost;
    costs.add(cost);
    operationCounts.add(count);
    lastOperation = DateTime.now();
    
    if (executionTime != null) {
      executionTimes.add(executionTime);
    }
    
    // Keep only recent operations
    if (costs.length > 100) {
      costs.removeAt(0);
      operationCounts.removeAt(0);
      if (executionTimes.isNotEmpty) {
        executionTimes.removeAt(0);
      }
    }
  }

  double get averageCost => costs.isNotEmpty ? costs.reduce((a, b) => a + b) / costs.length : 0.0;
  double get averageOperationCount => operationCounts.isNotEmpty ? operationCounts.reduce((a, b) => a + b) / operationCounts.length : 0.0;
  
  Duration get averageExecutionTime {
    if (executionTimes.isEmpty) return Duration.zero;
    final totalMs = executionTimes.fold<int>(0, (total, time) => total + time.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ executionTimes.length);
  }

  Map<String, dynamic> toMap() {
    return {
      'operationType': operationType,
      'collection': collection,
      'queryType': queryType,
      'operationCount': operationCount,
      'totalCost': totalCost,
      'averageCost': averageCost,
      'averageOperationCount': averageOperationCount,
      'averageExecutionTimeMs': averageExecutionTime.inMilliseconds,
      'lastOperation': lastOperation.toIso8601String(),
    };
  }
}

/// Daily cost summary
class DailyCostSummary {
  final String date;
  double totalCost = 0.0;
  int totalReads = 0;
  int totalWrites = 0;
  int totalDeletes = 0;
  final Map<String, double> costByOperation = {};

  DailyCostSummary({required this.date});

  void addCost(double cost, String operationType) {
    totalCost += cost;
    costByOperation[operationType] = (costByOperation[operationType] ?? 0.0) + cost;
    
    switch (operationType.toLowerCase()) {
      case 'read':
        totalReads++;
        break;
      case 'write':
        totalWrites++;
        break;
      case 'delete':
        totalDeletes++;
        break;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalCost': totalCost,
      'totalReads': totalReads,
      'totalWrites': totalWrites,
      'totalDeletes': totalDeletes,
      'costByOperation': costByOperation,
    };
  }
}

/// Cost alert
class CostAlert {
  final AlertType type;
  final String message;
  final double threshold;
  final double actualValue;
  final DateTime timestamp;
  final String? operationKey;

  const CostAlert({
    required this.type,
    required this.message,
    required this.threshold,
    required this.actualValue,
    required this.timestamp,
    this.operationKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'message': message,
      'threshold': threshold,
      'actualValue': actualValue,
      'timestamp': timestamp.toIso8601String(),
      'operationKey': operationKey,
    };
  }
}

/// Alert types
enum AlertType {
  dailyThreshold,
  weeklyThreshold,
  monthlyThreshold,
  operationThreshold,
  expensiveQuery,
}

/// Cost summary report
class CostSummaryReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalCost;
  final int totalReads;
  final int totalWrites;
  final int totalDeletes;
  final double averageDailyCost;
  final double monthlyProjection;
  final List<DailyCostSummary> dailySummaries;

  const CostSummaryReport({
    required this.startDate,
    required this.endDate,
    required this.totalCost,
    required this.totalReads,
    required this.totalWrites,
    required this.totalDeletes,
    required this.averageDailyCost,
    required this.monthlyProjection,
    required this.dailySummaries,
  });

  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalCost': totalCost,
      'totalReads': totalReads,
      'totalWrites': totalWrites,
      'totalDeletes': totalDeletes,
      'averageDailyCost': averageDailyCost,
      'monthlyProjection': monthlyProjection,
      'dailySummaries': dailySummaries.map((s) => s.toMap()).toList(),
    };
  }
}
