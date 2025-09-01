import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:securyflex_app/company_dashboard/models/business_intelligence_data.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart' show GuardAvailabilityStatus;

/// Guard performance analytics service for business intelligence
/// Provides comprehensive guard tracking, performance metrics, and optimization
class GuardPerformanceService {
  static GuardPerformanceService? _instance;
  static GuardPerformanceService get instance {
    _instance ??= GuardPerformanceService._();
    return _instance!;
  }

  GuardPerformanceService._();

  // Cache for performance
  List<GuardPerformanceData>? _cachedGuards;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 3);

  // Real-time update streams
  final StreamController<List<GuardPerformanceData>> _guardsStreamController = 
      StreamController<List<GuardPerformanceData>>.broadcast();
  final StreamController<Map<String, GuardAvailabilityStatus>> _availabilityStreamController = 
      StreamController<Map<String, GuardAvailabilityStatus>>.broadcast();

  /// Stream for real-time guard performance updates
  Stream<List<GuardPerformanceData>> get guardsStream => _guardsStreamController.stream;

  /// Stream for real-time guard availability updates
  Stream<Map<String, GuardAvailabilityStatus>> get availabilityStream => _availabilityStreamController.stream;

  /// Get all guards with performance metrics
  Future<List<GuardPerformanceData>> getGuardPerformanceData(String companyId) async {
    // Check cache first
    if (_cachedGuards != null && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!).compareTo(_cacheValidDuration) < 0) {
      return _cachedGuards!;
    }

    await Future.delayed(const Duration(milliseconds: 350)); // Simulate API call

    final guards = _generateGuardPerformanceData(companyId);
    
    // Update cache
    _cachedGuards = guards;
    _lastCacheUpdate = DateTime.now();

    // Emit to stream for real-time updates
    _guardsStreamController.add(guards);

    return guards;
  }

  /// Get top performing guards leaderboard
  Future<List<GuardPerformanceData>> getTopPerformingGuards(String companyId, {int limit = 10}) async {
    final allGuards = await getGuardPerformanceData(companyId);
    
    // Sort by composite performance score
    allGuards.sort((a, b) {
      final scoreA = _calculatePerformanceScore(a);
      final scoreB = _calculatePerformanceScore(b);
      return scoreB.compareTo(scoreA);
    });

    return allGuards.take(limit).toList();
  }

  /// Get guards requiring attention (low performance, compliance issues)
  Future<List<GuardPerformanceData>> getGuardsRequiringAttention(String companyId) async {
    final allGuards = await getGuardPerformanceData(companyId);
    
    return allGuards.where((guard) {
      return guard.reliabilityScore < 70.0 || 
             guard.noShowCount > 2 || 
             guard.rating < 3.5 ||
             !guard.isCurrentlyActive;
    }).toList();
  }

  /// Get real-time guard availability heatmap data
  Future<Map<String, GuardAvailabilityStatus>> getGuardAvailabilityHeatmap(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final guards = await getGuardPerformanceData(companyId);
    final availabilityMap = <String, GuardAvailabilityStatus>{};

    for (final guard in guards) {
      availabilityMap[guard.guardId] = guard.availabilityStatus;
    }

    // Emit to stream for real-time updates
    _availabilityStreamController.add(availabilityMap);

    return availabilityMap;
  }

  /// Get guard utilization statistics
  Future<Map<String, dynamic>> getGuardUtilizationStats(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final guards = await getGuardPerformanceData(companyId);
    
    final totalGuards = guards.length;
    final activeGuards = guards.where((g) => g.isCurrentlyActive).length;
    final availableGuards = guards.where((g) => g.availabilityStatus == GuardAvailabilityStatus.available).length;
    final onDutyGuards = guards.where((g) => g.availabilityStatus == GuardAvailabilityStatus.onDuty).length;

    final averageUtilization = guards.isEmpty ? 0.0 : 
        guards.fold<double>(0.0, (sum, guard) => sum + (guard.jobsThisMonth * 8.0)) / (totalGuards * 160.0) * 100;

    return {
      'total_guards': totalGuards,
      'active_guards': activeGuards,
      'available_guards': availableGuards,
      'on_duty_guards': onDutyGuards,
      'utilization_rate': averageUtilization,
      'average_rating': guards.isEmpty ? 0.0 : guards.fold<double>(0.0, (sum, g) => sum + g.rating) / totalGuards,
      'reliability_score': guards.isEmpty ? 0.0 : guards.fold<double>(0.0, (sum, g) => sum + g.reliabilityScore) / totalGuards,
    };
  }

  /// Get guard performance trends over time
  Future<Map<String, List<double>>> getPerformanceTrends(String guardId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Mock trend data for the last 12 months
    final random = Random();
    final ratingTrend = List.generate(12, (i) => 3.5 + random.nextDouble() * 1.5);
    final reliabilityTrend = List.generate(12, (i) => 70.0 + random.nextDouble() * 25.0);
    final jobsTrend = List.generate(12, (i) => 5 + random.nextInt(10));

    return {
      'rating_trend': ratingTrend,
      'reliability_trend': reliabilityTrend,
      'jobs_trend': jobsTrend.map((e) => e.toDouble()).toList(),
    };
  }

  /// Update guard availability status (for real-time tracking)
  Future<void> updateGuardAvailability(String guardId, GuardAvailabilityStatus status) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      // Update cached data if available
      if (_cachedGuards != null) {
        final guardIndex = _cachedGuards!.indexWhere((g) => g.guardId == guardId);
        if (guardIndex != -1) {
          _cachedGuards![guardIndex] = _cachedGuards![guardIndex].copyWith(
            availabilityStatus: status,
            isCurrentlyActive: status != GuardAvailabilityStatus.unavailable,
          );

          // Emit updated data only if stream is not closed
          if (!_guardsStreamController.isClosed) {
            _guardsStreamController.add(_cachedGuards!);
          }
        }
      }

      if (kDebugMode) {
        developer.log('Guard $guardId availability updated to $status', name: 'GuardPerformanceService', level: 1000);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating guard availability: $e');
      }
    }
  }

  /// Generate mock guard performance data
  List<GuardPerformanceData> _generateGuardPerformanceData(String companyId) {
    final random = Random();
    final guards = <GuardPerformanceData>[];

    final guardNames = [
      'Jan van der Berg',
      'Maria Janssen',
      'Pieter de Vries',
      'Anna Bakker',
      'Tom Visser',
      'Lisa de Jong',
      'Mark Smit',
      'Emma van Dijk',
      'Lars Mulder',
      'Sophie Bos',
      'David Groot',
      'Nina Hendriks',
    ];

    final specializations = [
      'Evenementbeveiliging',
      'Objectbeveiliging',
      'Personenbeveiliging',
      'Winkelbeveiliging',
      'Alarmopvolging',
      'Toegangscontrole',
    ];

    final availabilityStatuses = GuardAvailabilityStatus.values;

    for (int i = 0; i < guardNames.length; i++) {
      final isActive = random.nextBool();
      final rating = 2.5 + random.nextDouble() * 2.5; // 2.5 - 5.0
      final reliability = 60.0 + random.nextDouble() * 35.0; // 60 - 95
      final jobsThisMonth = random.nextInt(15) + 1;
      final totalJobs = jobsThisMonth + random.nextInt(50);

      guards.add(GuardPerformanceData(
        guardId: 'GUARD_${i.toString().padLeft(3, '0')}',
        guardName: guardNames[i],
        rating: rating,
        totalJobsCompleted: totalJobs,
        jobsThisMonth: jobsThisMonth,
        reliabilityScore: reliability,
        clientSatisfactionScore: rating * 0.9, // Slightly lower than rating
        averageResponseTime: 0.5 + random.nextDouble() * 2.0, // 0.5 - 2.5 hours
        revenueGenerated: jobsThisMonth * (150.0 + random.nextDouble() * 100.0),
        noShowCount: random.nextInt(3),
        emergencyResponseCount: random.nextInt(5),
        specializations: [
          specializations[random.nextInt(specializations.length)],
          if (random.nextBool()) specializations[random.nextInt(specializations.length)],
        ],
        lastActiveDate: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        isCurrentlyActive: isActive,
        currentLocation: isActive ? 'Amsterdam Centrum' : '',
        availabilityStatus: isActive
            ? availabilityStatuses[random.nextInt(availabilityStatuses.length - 1)] // Exclude offline
            : GuardAvailabilityStatus.unavailable,
      ));
    }

    return guards;
  }

  /// Calculate composite performance score
  double _calculatePerformanceScore(GuardPerformanceData guard) {
    // Weighted performance score calculation
    final ratingScore = (guard.rating / 5.0) * 30; // 30% weight
    final reliabilityScore = (guard.reliabilityScore / 100.0) * 25; // 25% weight
    final activityScore = (guard.jobsThisMonth / 15.0).clamp(0.0, 1.0) * 20; // 20% weight
    final satisfactionScore = (guard.clientSatisfactionScore / 5.0) * 15; // 15% weight
    final responseScore = (1.0 - (guard.averageResponseTime / 24.0).clamp(0.0, 1.0)) * 10; // 10% weight

    return ratingScore + reliabilityScore + activityScore + satisfactionScore + responseScore;
  }

  /// Start real-time guard monitoring
  void startRealtimeMonitoring(String companyId) {
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        final guards = await getGuardPerformanceData(companyId);
        if (!_guardsStreamController.isClosed) {
          _guardsStreamController.add(guards);
        }

        final availability = await getGuardAvailabilityHeatmap(companyId);
        if (!_availabilityStreamController.isClosed) {
          _availabilityStreamController.add(availability);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error in real-time guard monitoring: $e');
        }
        // Cancel timer if there are persistent errors
        if (e.toString().contains('disposed') || e.toString().contains('closed')) {
          timer.cancel();
        }
      }
    });
  }

  /// Stop real-time monitoring and cleanup
  void dispose() {
    _guardsStreamController.close();
    _availabilityStreamController.close();
  }

  /// Clear cache to force fresh data
  void clearCache() {
    _cachedGuards = null;
    _lastCacheUpdate = null;
  }
}
