import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:securyflex_app/company_dashboard/models/business_intelligence_data.dart';

/// Revenue analytics service for business intelligence
/// Provides comprehensive revenue tracking, forecasting, and optimization
class RevenueAnalyticsService {
  static RevenueAnalyticsService? _instance;
  static RevenueAnalyticsService get instance {
    _instance ??= RevenueAnalyticsService._();
    return _instance!;
  }

  RevenueAnalyticsService._();

  // Cache for performance
  RevenueAnalyticsData? _cachedData;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Real-time update stream
  final StreamController<RevenueAnalyticsData> _revenueStreamController = 
      StreamController<RevenueAnalyticsData>.broadcast();

  /// Stream for real-time revenue updates
  Stream<RevenueAnalyticsData> get revenueStream => _revenueStreamController.stream;

  /// Get comprehensive revenue analytics data
  Future<RevenueAnalyticsData> getRevenueAnalytics(String companyId) async {
    // Check cache first
    if (_cachedData != null && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!).compareTo(_cacheValidDuration) < 0) {
      return _cachedData!;
    }

    await Future.delayed(const Duration(milliseconds: 400)); // Simulate API call

    // Generate comprehensive revenue data
    final data = _generateRevenueAnalytics(companyId);
    
    // Update cache
    _cachedData = data;
    _lastCacheUpdate = DateTime.now();

    // Emit to stream for real-time updates
    _revenueStreamController.add(data);

    return data;
  }

  /// Generate 30/60/90-day revenue projections
  Future<Map<String, double>> getRevenueProjections(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final currentRevenue = 15750.0; // Mock current monthly revenue
    final growthRate = 0.12; // 12% monthly growth

    return {
      '30_days': currentRevenue * (1 + growthRate),
      '60_days': currentRevenue * (1 + growthRate * 2),
      '90_days': currentRevenue * (1 + growthRate * 3),
      'confidence_30': 0.85, // 85% confidence
      'confidence_60': 0.72, // 72% confidence
      'confidence_90': 0.58, // 58% confidence
    };
  }

  /// Get profit margin analysis by service type
  Future<List<RevenueByServiceType>> getProfitMarginAnalysis(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      const RevenueByServiceType(
        serviceType: 'Evenementbeveiliging',
        revenue: 8500.0,
        percentage: 54.0,
        jobCount: 12,
      ),
      const RevenueByServiceType(
        serviceType: 'Objectbeveiliging',
        revenue: 4200.0,
        percentage: 26.7,
        jobCount: 8,
      ),
      const RevenueByServiceType(
        serviceType: 'Personenbeveiliging',
        revenue: 2100.0,
        percentage: 13.3,
        jobCount: 3,
      ),
      const RevenueByServiceType(
        serviceType: 'Winkelbeveiliging',
        revenue: 950.0,
        percentage: 6.0,
        jobCount: 5,
      ),
    ];
  }

  /// Get seasonal demand patterns for forecasting
  Future<List<SeasonalTrendData>> getSeasonalTrends() async {
    await Future.delayed(const Duration(milliseconds: 250));

    return [
      const SeasonalTrendData(
        period: 'Q1 (Jan-Mar)',
        demandMultiplier: 0.85,
        popularServices: ['Objectbeveiliging', 'Winkelbeveiliging'],
      ),
      const SeasonalTrendData(
        period: 'Q2 (Apr-Jun)',
        demandMultiplier: 1.15,
        popularServices: ['Evenementbeveiliging', 'Personenbeveiliging'],
      ),
      const SeasonalTrendData(
        period: 'Q3 (Jul-Sep)',
        demandMultiplier: 1.35,
        popularServices: ['Evenementbeveiliging', 'Objectbeveiliging'],
      ),
      const SeasonalTrendData(
        period: 'Q4 (Oct-Dec)',
        demandMultiplier: 1.25,
        popularServices: ['Winkelbeveiliging', 'Evenementbeveiliging'],
      ),
    ];
  }

  /// Get cost-per-acquisition metrics
  Future<Map<String, dynamic>> getCostPerAcquisitionMetrics(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return {
      'cost_per_guard_hire': 125.50,
      'cost_per_client_acquisition': 450.75,
      'average_time_to_hire': 3.2, // days
      'recruitment_efficiency': 78.5, // percentage
      'retention_rate': 85.2, // percentage
      'lifetime_value_guard': 2850.0,
      'lifetime_value_client': 12500.0,
    };
  }

  /// Get competition benchmarking data
  Future<Map<String, dynamic>> getCompetitionBenchmarks() async {
    await Future.delayed(const Duration(milliseconds: 350));

    return {
      'market_position': 'Top 15%',
      'average_hourly_rate_market': 18.50,
      'our_average_rate': 19.25,
      'rate_competitiveness': 'Above Average',
      'market_share_estimate': 3.2, // percentage
      'growth_vs_market': 15.5, // percentage above market growth
      'client_satisfaction_vs_market': 8.5, // percentage above market average
    };
  }

  /// Generate mock revenue analytics data
  RevenueAnalyticsData _generateRevenueAnalytics(String companyId) {
    final random = Random();
    final now = DateTime.now();

    // Generate historical data
    final revenueHistory = <MonthlyRevenueData>[];
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final baseRevenue = 12000.0 + (i * 500); // Growing trend
      final revenue = baseRevenue + (random.nextDouble() * 2000 - 1000);
      final profit = revenue * 0.25; // 25% profit margin
      final jobs = 15 + random.nextInt(10);

      revenueHistory.add(MonthlyRevenueData(
        month: month,
        revenue: revenue,
        profit: profit,
        jobsCompleted: jobs,
      ));
    }

    return RevenueAnalyticsData(
      currentMonthRevenue: 15750.0,
      previousMonthRevenue: 14200.0,
      monthlyGrowthRate: 10.9,
      projectedRevenue30Days: 17640.0,
      projectedRevenue60Days: 19756.0,
      projectedRevenue90Days: 22127.0,
      averageJobValue: 875.0,
      profitMargin: 24.5,
      costPerAcquisition: 125.50,
      lifetimeValue: 2850.0,
      revenueHistory: revenueHistory,
      revenueByService: [
        const RevenueByServiceType(
          serviceType: 'Evenementbeveiliging',
          revenue: 8500.0,
          percentage: 54.0,
          jobCount: 12,
        ),
        const RevenueByServiceType(
          serviceType: 'Objectbeveiliging',
          revenue: 4200.0,
          percentage: 26.7,
          jobCount: 8,
        ),
      ],
      seasonalTrends: [
        const SeasonalTrendData(
          period: 'Zomer',
          demandMultiplier: 1.35,
          popularServices: ['Evenementbeveiliging'],
        ),
      ],
      lastUpdated: now,
    );
  }

  /// Start real-time revenue monitoring
  void startRealtimeMonitoring(String companyId) {
    Timer.periodic(const Duration(minutes: 2), (timer) async {
      try {
        final data = await getRevenueAnalytics(companyId);
        _revenueStreamController.add(data);
      } catch (e) {
        if (kDebugMode) {
          print('Error in real-time revenue monitoring: $e');
        }
      }
    });
  }

  /// Stop real-time monitoring and cleanup
  void dispose() {
    _revenueStreamController.close();
  }

  /// Clear cache to force fresh data
  void clearCache() {
    _cachedData = null;
    _lastCacheUpdate = null;
  }

  /// Format currency for Dutch locale
  static String formatCurrency(double amount) {
    return '€${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Format percentage for Dutch locale
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1).replaceAll('.', ',')}%';
  }
}
