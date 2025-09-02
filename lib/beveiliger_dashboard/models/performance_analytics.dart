import 'package:equatable/equatable.dart';

/// Performance analytics for beveiliger dashboard
class PerformanceAnalytics extends Equatable {
  final double overallRating;           // Overall rating (1-5 stars)
  final int totalShifts;               // Total completed shifts
  final int shiftsThisWeek;            // Shifts completed this week
  final int shiftsThisMonth;           // Shifts completed this month
  final double completionRate;         // Shift completion percentage
  final double averageResponseTime;    // Average response time in minutes
  final double customerSatisfaction;   // Customer satisfaction score
  final int streakDays;               // Consecutive successful days
  final List<EarningsDataPoint> earningsHistory; // Earnings over time
  final List<ShiftDataPoint> shiftHistory;       // Shift performance over time
  final List<RatingDataPoint> ratingHistory;     // Rating progression over time
  final Map<String, double> performanceMetrics;  // Key performance indicators
  final DateTime lastUpdated;

  const PerformanceAnalytics({
    required this.overallRating,
    required this.totalShifts,
    required this.shiftsThisWeek,
    required this.shiftsThisMonth,
    required this.completionRate,
    required this.averageResponseTime,
    required this.customerSatisfaction,
    required this.streakDays,
    required this.earningsHistory,
    required this.shiftHistory,
    required this.ratingHistory,
    required this.performanceMetrics,
    required this.lastUpdated,
  });

  /// Get Dutch performance summary
  String get dutchPerformanceSummary {
    if (overallRating >= 4.5 && completionRate >= 95) {
      return 'Uitstekende prestaties - topbeveiliging!';
    } else if (overallRating >= 4.0 && completionRate >= 90) {
      return 'Goede prestaties - blijf zo doorgaan!';
    } else if (overallRating >= 3.5 && completionRate >= 85) {
      return 'Gemiddelde prestaties - ruimte voor verbetering';
    } else {
      return 'Prestaties verbeteren - focus op kwaliteit';
    }
  }

  /// Get performance trend
  PerformanceTrend get performanceTrend {
    if (ratingHistory.length < 2) return PerformanceTrend.stable;
    
    final recent = ratingHistory.takeLast(3);
    final older = ratingHistory.takeLast(6).take(3);
    
    final recentAvg = recent.fold(0.0, (sum, point) => sum + point.rating) / recent.length;
    final olderAvg = older.fold(0.0, (sum, point) => sum + point.rating) / older.length;
    
    if (recentAvg > olderAvg + 0.2) return PerformanceTrend.improving;
    if (recentAvg < olderAvg - 0.2) return PerformanceTrend.declining;
    return PerformanceTrend.stable;
  }

  /// Get Dutch trend description
  String get dutchTrendDescription {
    switch (performanceTrend) {
      case PerformanceTrend.improving:
        return 'Prestaties verbeteren - geweldig werk! 📈';
      case PerformanceTrend.declining:
        return 'Prestaties dalen - focus op kwaliteit 📉';
      case PerformanceTrend.stable:
        return 'Stabiele prestaties - consistente kwaliteit 📊';
    }
  }

  /// Get key performance indicators formatted for Dutch display
  Map<String, String> get dutchFormattedKPIs {
    return {
      'Gemiddelde beoordeling': '${overallRating.toStringAsFixed(1)} ⭐',
      'Voltooiingspercentage': '${completionRate.toStringAsFixed(0)}%',
      'Reactietijd': '${averageResponseTime.toStringAsFixed(0)} min',
      'Klanttevredenheid': '${customerSatisfaction.toStringAsFixed(0)}%',
      'Succesvolle dagen achtereen': '$streakDays dagen',
      'Diensten deze week': '$shiftsThisWeek',
      'Diensten deze maand': '$shiftsThisMonth',
    };
  }

  PerformanceAnalytics copyWith({
    double? overallRating,
    int? totalShifts,
    int? shiftsThisWeek,
    int? shiftsThisMonth,
    double? completionRate,
    double? averageResponseTime,
    double? customerSatisfaction,
    int? streakDays,
    List<EarningsDataPoint>? earningsHistory,
    List<ShiftDataPoint>? shiftHistory,
    List<RatingDataPoint>? ratingHistory,
    Map<String, double>? performanceMetrics,
    DateTime? lastUpdated,
  }) {
    return PerformanceAnalytics(
      overallRating: overallRating ?? this.overallRating,
      totalShifts: totalShifts ?? this.totalShifts,
      shiftsThisWeek: shiftsThisWeek ?? this.shiftsThisWeek,
      shiftsThisMonth: shiftsThisMonth ?? this.shiftsThisMonth,
      completionRate: completionRate ?? this.completionRate,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      customerSatisfaction: customerSatisfaction ?? this.customerSatisfaction,
      streakDays: streakDays ?? this.streakDays,
      earningsHistory: earningsHistory ?? this.earningsHistory,
      shiftHistory: shiftHistory ?? this.shiftHistory,
      ratingHistory: ratingHistory ?? this.ratingHistory,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// JSON serialization
  factory PerformanceAnalytics.fromJson(Map<String, dynamic> json) {
    return PerformanceAnalytics(
      overallRating: (json['overallRating'] as num).toDouble(),
      totalShifts: json['totalShifts'] as int,
      shiftsThisWeek: json['shiftsThisWeek'] as int,
      shiftsThisMonth: json['shiftsThisMonth'] as int,
      completionRate: (json['completionRate'] as num).toDouble(),
      averageResponseTime: (json['averageResponseTime'] as num).toDouble(),
      customerSatisfaction: (json['customerSatisfaction'] as num).toDouble(),
      streakDays: json['streakDays'] as int,
      earningsHistory: (json['earningsHistory'] as List<dynamic>)
          .map((data) => EarningsDataPoint.fromJson(data as Map<String, dynamic>))
          .toList(),
      shiftHistory: (json['shiftHistory'] as List<dynamic>)
          .map((data) => ShiftDataPoint.fromJson(data as Map<String, dynamic>))
          .toList(),
      ratingHistory: (json['ratingHistory'] as List<dynamic>)
          .map((data) => RatingDataPoint.fromJson(data as Map<String, dynamic>))
          .toList(),
      performanceMetrics: Map<String, double>.from(json['performanceMetrics'] ?? {}),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallRating': overallRating,
      'totalShifts': totalShifts,
      'shiftsThisWeek': shiftsThisWeek,
      'shiftsThisMonth': shiftsThisMonth,
      'completionRate': completionRate,
      'averageResponseTime': averageResponseTime,
      'customerSatisfaction': customerSatisfaction,
      'streakDays': streakDays,
      'earningsHistory': earningsHistory.map((data) => data.toJson()).toList(),
      'shiftHistory': shiftHistory.map((data) => data.toJson()).toList(),
      'ratingHistory': ratingHistory.map((data) => data.toJson()).toList(),
      'performanceMetrics': performanceMetrics,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object> get props => [
    overallRating,
    totalShifts,
    shiftsThisWeek,
    shiftsThisMonth,
    completionRate,
    averageResponseTime,
    customerSatisfaction,
    streakDays,
    earningsHistory,
    shiftHistory,
    ratingHistory,
    performanceMetrics,
    lastUpdated,
  ];
}

/// Data point for earnings chart
class EarningsDataPoint extends Equatable {
  final DateTime date;
  final double amount;
  final String formattedAmount; // €1.234,56 format

  const EarningsDataPoint({
    required this.date,
    required this.amount,
    required this.formattedAmount,
  });

  /// JSON serialization
  factory EarningsDataPoint.fromJson(Map<String, dynamic> json) {
    return EarningsDataPoint(
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      amount: (json['amount'] as num).toDouble(),
      formattedAmount: json['formattedAmount'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.millisecondsSinceEpoch,
      'amount': amount,
      'formattedAmount': formattedAmount,
    };
  }

  @override
  List<Object> get props => [date, amount, formattedAmount];
}

/// Data point for shift performance chart
class ShiftDataPoint extends Equatable {
  final DateTime date;
  final int shiftsCompleted;
  final int shiftsScheduled;
  final double completionRate;

  const ShiftDataPoint({
    required this.date,
    required this.shiftsCompleted,
    required this.shiftsScheduled,
    required this.completionRate,
  });

  /// JSON serialization
  factory ShiftDataPoint.fromJson(Map<String, dynamic> json) {
    return ShiftDataPoint(
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      shiftsCompleted: json['shiftsCompleted'] as int,
      shiftsScheduled: json['shiftsScheduled'] as int,
      completionRate: (json['completionRate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.millisecondsSinceEpoch,
      'shiftsCompleted': shiftsCompleted,
      'shiftsScheduled': shiftsScheduled,
      'completionRate': completionRate,
    };
  }

  @override
  List<Object> get props => [date, shiftsCompleted, shiftsScheduled, completionRate];
}

/// Data point for rating progression chart
class RatingDataPoint extends Equatable {
  final DateTime date;
  final double rating;
  final int totalReviews;

  const RatingDataPoint({
    required this.date,
    required this.rating,
    required this.totalReviews,
  });

  /// JSON serialization
  factory RatingDataPoint.fromJson(Map<String, dynamic> json) {
    return RatingDataPoint(
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      rating: (json['rating'] as num).toDouble(),
      totalReviews: json['totalReviews'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.millisecondsSinceEpoch,
      'rating': rating,
      'totalReviews': totalReviews,
    };
  }

  @override
  List<Object> get props => [date, rating, totalReviews];
}

/// Performance trend enum
enum PerformanceTrend {
  improving,
  stable,
  declining,
}

/// Extension for list operations
extension ListExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}