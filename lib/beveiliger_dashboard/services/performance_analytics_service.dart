import 'dart:async';
import 'dart:math';
import '../models/performance_analytics.dart';
import '../models/enhanced_dashboard_data.dart';
import '../bloc/beveiliger_dashboard_event.dart';

/// Service for guard performance analytics and insights
class PerformanceAnalyticsService {
  final StreamController<PerformanceAnalytics> _analyticsController = 
      StreamController<PerformanceAnalytics>.broadcast();

  /// Stream for real-time analytics updates
  Stream<PerformanceAnalytics> get analyticsStream => _analyticsController.stream;

  /// Get performance analytics (alias for BLoC compatibility)
  Future<PerformanceAnalytics> getPerformanceAnalytics(
    List<EnhancedShiftData> shifts,
    AnalyticsPeriod period,
  ) async {
    return generateAnalytics(shifts, period);
  }

  /// Generate comprehensive performance analytics
  Future<PerformanceAnalytics> generateAnalytics(
    List<EnhancedShiftData> shifts,
    AnalyticsPeriod period,
  ) async {
    // Simulate analytics processing delay
    await Future.delayed(const Duration(milliseconds: 500));

    final filteredShifts = _filterShiftsByPeriod(shifts, period);
    
    final averageRating = _calculateAverageRating(filteredShifts);
    final completionRate = _calculateCompletionRate(filteredShifts);
    
    return PerformanceAnalytics(
      overallRating: averageRating,
      totalShifts: filteredShifts.length,
      shiftsThisWeek: _getShiftsForPeriod(shifts, AnalyticsPeriod.week).length,
      shiftsThisMonth: _getShiftsForPeriod(shifts, AnalyticsPeriod.month).length,
      completionRate: completionRate,
      averageResponseTime: 5.0 + Random().nextDouble() * 10.0, // Mock response time
      customerSatisfaction: completionRate * 0.8 + Random().nextDouble() * 15.0,
      streakDays: _calculateStreakDays(filteredShifts),
      earningsHistory: _generateEarningsHistory(filteredShifts, period),
      shiftHistory: _generateShiftHistory(filteredShifts, period),
      ratingHistory: _generateRatingHistory(filteredShifts, period),
      performanceMetrics: _generatePerformanceMetrics(filteredShifts),
      lastUpdated: DateTime.now(),
    );
  }

  /// Get shifts for a specific period
  List<EnhancedShiftData> _getShiftsForPeriod(
    List<EnhancedShiftData> shifts,
    AnalyticsPeriod period,
  ) {
    return _filterShiftsByPeriod(shifts, period);
  }

  /// Calculate consecutive successful days
  int _calculateStreakDays(List<EnhancedShiftData> shifts) {
    final completedShifts = shifts
        .where((s) => s.status == ShiftStatus.completed)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Most recent first

    int streak = 0;
    DateTime? lastDate;

    for (final shift in completedShifts) {
      final shiftDate = DateTime(shift.startTime.year, shift.startTime.month, shift.startTime.day);
      
      if (lastDate == null) {
        streak = 1;
        lastDate = shiftDate;
      } else {
        final daysDiff = lastDate.difference(shiftDate).inDays;
        if (daysDiff == 1) {
          streak++;
          lastDate = shiftDate;
        } else if (daysDiff > 1) {
          break; // Streak broken
        }
        // If daysDiff == 0, same day - continue with current streak
      }
    }

    return streak;
  }

  /// Generate earnings history data points
  List<EarningsDataPoint> _generateEarningsHistory(
    List<EnhancedShiftData> shifts,
    AnalyticsPeriod period,
  ) {
    final completedShifts = shifts
        .where((s) => s.status == ShiftStatus.completed)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final data = <EarningsDataPoint>[];
    final groupedEarnings = <DateTime, double>{};

    for (final shift in completedShifts) {
      final key = _getDateKey(shift.startTime, period);
      groupedEarnings[key] = (groupedEarnings[key] ?? 0.0) + shift.totalEarnings;
    }

    for (final entry in groupedEarnings.entries) {
      data.add(EarningsDataPoint(
        date: entry.key,
        amount: entry.value,
        formattedAmount: _formatDutchCurrency(entry.value),
      ));
    }

    return data;
  }

  /// Generate shift history data points
  List<ShiftDataPoint> _generateShiftHistory(
    List<EnhancedShiftData> shifts,
    AnalyticsPeriod period,
  ) {
    final data = <ShiftDataPoint>[];
    final groupedShifts = <DateTime, List<EnhancedShiftData>>{};

    for (final shift in shifts) {
      final key = _getDateKey(shift.startTime, period);
      groupedShifts.putIfAbsent(key, () => []).add(shift);
    }

    for (final entry in groupedShifts.entries) {
      final shiftList = entry.value;
      final completed = shiftList.where((s) => s.status == ShiftStatus.completed).length;
      final total = shiftList.length;
      
      data.add(ShiftDataPoint(
        date: entry.key,
        shiftsCompleted: completed,
        shiftsScheduled: total,
        completionRate: total > 0 ? (completed / total) * 100 : 0,
      ));
    }

    return data;
  }

  /// Generate rating history data points
  List<RatingDataPoint> _generateRatingHistory(
    List<EnhancedShiftData> shifts,
    AnalyticsPeriod period,
  ) {
    final ratedShifts = shifts
        .where((s) => s.rating != null && s.status == ShiftStatus.completed)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final data = <RatingDataPoint>[];
    final groupedRatings = <DateTime, List<double>>{};

    for (final shift in ratedShifts) {
      final key = _getDateKey(shift.startTime, period);
      groupedRatings.putIfAbsent(key, () => []).add(shift.rating!);
    }

    for (final entry in groupedRatings.entries) {
      final ratings = entry.value;
      final avgRating = ratings.fold(0.0, (sum, rating) => sum + rating) / ratings.length;
      
      data.add(RatingDataPoint(
        date: entry.key,
        rating: avgRating,
        totalReviews: ratings.length,
      ));
    }

    return data;
  }

  /// Generate performance metrics map
  Map<String, double> _generatePerformanceMetrics(List<EnhancedShiftData> shifts) {
    final completedShifts = shifts.where((s) => s.status == ShiftStatus.completed).length;
    final totalShifts = shifts.length;
    final avgRating = _calculateAverageRating(shifts);
    final totalEarnings = _calculateTotalEarnings(shifts);
    final totalHours = _calculateTotalHours(shifts);

    return {
      'completion_rate': totalShifts > 0 ? (completedShifts / totalShifts) * 100 : 0,
      'average_rating': avgRating,
      'total_earnings': totalEarnings,
      'total_hours': totalHours,
      'average_hourly_rate': totalHours > 0 ? totalEarnings / totalHours : 0,
      'shifts_per_week': completedShifts / 4.33, // Average weeks per month
    };
  }

  /// Get date key for grouping by period
  DateTime _getDateKey(DateTime date, AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.day:
        return DateTime(date.year, date.month, date.day, date.hour);
      case AnalyticsPeriod.week:
        return DateTime(date.year, date.month, date.day);
      case AnalyticsPeriod.month:
        return DateTime(date.year, date.month, date.day);
      case AnalyticsPeriod.quarter:
      case AnalyticsPeriod.year:
        return DateTime(date.year, date.month, 1);
    }
  }

  /// Format currency in Dutch format
  String _formatDutchCurrency(double amount) {
    final euros = amount.floor();
    final cents = ((amount - euros) * 100).round();
    final euroString = euros.toString();
    
    String formattedEuros = '';
    for (int i = 0; i < euroString.length; i++) {
      if (i > 0 && (euroString.length - i) % 3 == 0) {
        formattedEuros += '.';
      }
      formattedEuros += euroString[i];
    }
    
    return '€$formattedEuros,${cents.toString().padLeft(2, '0')}';
  }

  /// Filter shifts by analytics period
  List<EnhancedShiftData> _filterShiftsByPeriod(
    List<EnhancedShiftData> shifts,
    AnalyticsPeriod period,
  ) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case AnalyticsPeriod.day:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case AnalyticsPeriod.week:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case AnalyticsPeriod.month:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case AnalyticsPeriod.quarter:
        final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
        startDate = DateTime(now.year, quarterStart, 1);
        break;
      case AnalyticsPeriod.year:
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    return shifts.where((shift) => shift.startTime.isAfter(startDate)).toList();
  }

  /// Calculate total hours worked
  double _calculateTotalHours(List<EnhancedShiftData> shifts) {
    return shifts
        .where((s) => s.status == ShiftStatus.completed || s.status == ShiftStatus.inProgress)
        .fold(0.0, (sum, shift) => sum + shift.durationHours);
  }

  /// Calculate total earnings
  double _calculateTotalEarnings(List<EnhancedShiftData> shifts) {
    return shifts
        .where((s) => s.status == ShiftStatus.completed)
        .fold(0.0, (sum, shift) => sum + shift.totalEarnings);
  }

  /// Calculate average rating from completed shifts
  double _calculateAverageRating(List<EnhancedShiftData> shifts) {
    final ratedShifts = shifts
        .where((s) => s.status == ShiftStatus.completed && s.rating != null)
        .toList();

    if (ratedShifts.isEmpty) return 0.0;

    final totalRating = ratedShifts.fold(0.0, (sum, shift) => sum + shift.rating!);
    return totalRating / ratedShifts.length;
  }


  /// Calculate completion rate percentage
  double _calculateCompletionRate(List<EnhancedShiftData> shifts) {
    if (shifts.isEmpty) return 0.0;

    final completedShifts = shifts.where((s) => s.status == ShiftStatus.completed).length;
    return (completedShifts / shifts.length) * 100;
  }




  void dispose() {
    _analyticsController.close();
  }
}