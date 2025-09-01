import 'package:equatable/equatable.dart';
import 'compliance_status.dart';
import 'weather_data.dart';
import 'performance_analytics.dart';

/// Enhanced dashboard data model containing all dashboard information
class EnhancedDashboardData extends Equatable {
  final EnhancedEarningsData earnings;
  final List<EnhancedShiftData> shifts;
  final ComplianceStatus compliance;
  final WeatherData? weather;
  final PerformanceAnalytics performance;
  final DateTime lastUpdated;

  const EnhancedDashboardData({
    required this.earnings,
    required this.shifts,
    required this.compliance,
    this.weather,
    required this.performance,
    required this.lastUpdated,
  });

  EnhancedDashboardData copyWith({
    EnhancedEarningsData? earnings,
    List<EnhancedShiftData>? shifts,
    ComplianceStatus? compliance,
    WeatherData? weather,
    PerformanceAnalytics? performance,
    DateTime? lastUpdated,
  }) {
    return EnhancedDashboardData(
      earnings: earnings ?? this.earnings,
      shifts: shifts ?? this.shifts,
      compliance: compliance ?? this.compliance,
      weather: weather ?? this.weather,
      performance: performance ?? this.performance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    earnings,
    shifts,
    compliance,
    weather,
    performance,
    lastUpdated,
  ];
}

/// Enhanced earnings data with Dutch formatting and CAO calculations
class EnhancedEarningsData extends Equatable {
  final double totalToday;              // Total earnings today
  final double totalWeek;               // Total earnings this week
  final double totalMonth;              // Total earnings this month
  final double hourlyRate;              // Current hourly rate
  final double hoursWorkedToday;        // Hours worked today
  final double hoursWorkedWeek;         // Hours worked this week
  final double overtimeHours;           // Overtime hours this week
  final double overtimeRate;            // Overtime rate (150% or 200%)
  final double vakantiegeld;            // Holiday allowance (8%)
  final double btwAmount;               // BTW amount (21% for freelance)
  final bool isFreelance;               // Is freelance or employed
  final String dutchFormattedToday;     // €1.234,56 format for today
  final String dutchFormattedWeek;      // €1.234,56 format for week
  final String dutchFormattedMonth;     // €1.234,56 format for month
  final DateTime lastCalculated;

  const EnhancedEarningsData({
    required this.totalToday,
    required this.totalWeek,
    required this.totalMonth,
    required this.hourlyRate,
    required this.hoursWorkedToday,
    required this.hoursWorkedWeek,
    required this.overtimeHours,
    required this.overtimeRate,
    required this.vakantiegeld,
    required this.btwAmount,
    required this.isFreelance,
    required this.dutchFormattedToday,
    required this.dutchFormattedWeek,
    required this.dutchFormattedMonth,
    required this.lastCalculated,
  });

  /// Check if overtime rate is CAO compliant
  bool get isOvertimeCompliant {
    if (hoursWorkedWeek <= 40) return true;
    if (hoursWorkedWeek <= 48 && overtimeRate >= hourlyRate * 1.5) return true;
    if (hoursWorkedWeek > 48 && overtimeRate >= hourlyRate * 2.0) return true;
    return false;
  }

  /// Get Dutch earnings summary
  String get dutchEarningsSummary {
    if (hoursWorkedToday == 0) {
      return 'Nog geen verdiensten vandaag';
    } else if (overtimeHours > 0) {
      return 'Vandaag: $dutchFormattedToday (incl. ${overtimeHours.toStringAsFixed(1)}u overwerk)';
    } else {
      return 'Vandaag: $dutchFormattedToday (${hoursWorkedToday.toStringAsFixed(1)}u gewerkt)';
    }
  }

  EnhancedEarningsData copyWith({
    double? totalToday,
    double? totalWeek,
    double? totalMonth,
    double? hourlyRate,
    double? hoursWorkedToday,
    double? hoursWorkedWeek,
    double? overtimeHours,
    double? overtimeRate,
    double? vakantiegeld,
    double? btwAmount,
    bool? isFreelance,
    String? dutchFormattedToday,
    String? dutchFormattedWeek,
    String? dutchFormattedMonth,
    DateTime? lastCalculated,
  }) {
    return EnhancedEarningsData(
      totalToday: totalToday ?? this.totalToday,
      totalWeek: totalWeek ?? this.totalWeek,
      totalMonth: totalMonth ?? this.totalMonth,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      hoursWorkedToday: hoursWorkedToday ?? this.hoursWorkedToday,
      hoursWorkedWeek: hoursWorkedWeek ?? this.hoursWorkedWeek,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      vakantiegeld: vakantiegeld ?? this.vakantiegeld,
      btwAmount: btwAmount ?? this.btwAmount,
      isFreelance: isFreelance ?? this.isFreelance,
      dutchFormattedToday: dutchFormattedToday ?? this.dutchFormattedToday,
      dutchFormattedWeek: dutchFormattedWeek ?? this.dutchFormattedWeek,
      dutchFormattedMonth: dutchFormattedMonth ?? this.dutchFormattedMonth,
      lastCalculated: lastCalculated ?? this.lastCalculated,
    );
  }

  @override
  List<Object> get props => [
    totalToday,
    totalWeek,
    totalMonth,
    hourlyRate,
    hoursWorkedToday,
    hoursWorkedWeek,
    overtimeHours,
    overtimeRate,
    vakantiegeld,
    btwAmount,
    isFreelance,
    dutchFormattedToday,
    dutchFormattedWeek,
    dutchFormattedMonth,
    lastCalculated,
  ];
}

/// Enhanced shift data with detailed information
class EnhancedShiftData extends Equatable {
  final String id;
  final String title;
  final String companyName;
  final String companyId;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String address;
  final double? latitude;
  final double? longitude;
  final double hourlyRate;
  final ShiftStatus status;
  final ShiftType type;
  final String? specialInstructions;
  final List<String> requiredCertifications;
  final bool isOutdoor;
  final bool requiresUniform;
  final bool emergencyResponse;
  final double? rating;            // Rating from company after completion
  final String? feedback;          // Feedback from company
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String dutchStatusText;    // Dutch status description

  const EnhancedShiftData({
    required this.id,
    required this.title,
    required this.companyName,
    required this.companyId,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.address,
    this.latitude,
    this.longitude,
    required this.hourlyRate,
    required this.status,
    required this.type,
    this.specialInstructions,
    required this.requiredCertifications,
    required this.isOutdoor,
    required this.requiresUniform,
    required this.emergencyResponse,
    this.rating,
    this.feedback,
    this.checkedInAt,
    this.checkedOutAt,
    required this.dutchStatusText,
  });

  /// Get shift duration in hours
  double get durationHours {
    return endTime.difference(startTime).inMinutes / 60.0;
  }

  /// Check if shift is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == ShiftStatus.inProgress && 
           now.isAfter(startTime) && 
           now.isBefore(endTime);
  }

  /// Get Dutch formatted time range
  String get dutchTimeRange {
    final startFormatted = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endFormatted = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startFormatted - $endFormatted';
  }

  /// Get total earnings for this shift
  double get totalEarnings {
    return durationHours * hourlyRate;
  }

  /// Get Dutch formatted earnings
  String get dutchFormattedEarnings {
    final formatter = _createDutchCurrencyFormatter();
    return formatter.format(totalEarnings);
  }

  EnhancedShiftData copyWith({
    String? id,
    String? title,
    String? companyName,
    String? companyId,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    double? hourlyRate,
    ShiftStatus? status,
    ShiftType? type,
    String? specialInstructions,
    List<String>? requiredCertifications,
    bool? isOutdoor,
    bool? requiresUniform,
    bool? emergencyResponse,
    double? rating,
    String? feedback,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
    String? dutchStatusText,
  }) {
    return EnhancedShiftData(
      id: id ?? this.id,
      title: title ?? this.title,
      companyName: companyName ?? this.companyName,
      companyId: companyId ?? this.companyId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      status: status ?? this.status,
      type: type ?? this.type,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      requiredCertifications: requiredCertifications ?? this.requiredCertifications,
      isOutdoor: isOutdoor ?? this.isOutdoor,
      requiresUniform: requiresUniform ?? this.requiresUniform,
      emergencyResponse: emergencyResponse ?? this.emergencyResponse,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      dutchStatusText: dutchStatusText ?? this.dutchStatusText,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    companyName,
    companyId,
    startTime,
    endTime,
    location,
    address,
    latitude,
    longitude,
    hourlyRate,
    status,
    type,
    specialInstructions,
    requiredCertifications,
    isOutdoor,
    requiresUniform,
    emergencyResponse,
    rating,
    feedback,
    checkedInAt,
    checkedOutAt,
    dutchStatusText,
  ];
}

/// Shift status enum
enum ShiftStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
}

/// Shift type enum
enum ShiftType {
  regular,        // Reguliere beveiliging
  event,          // Evenementbeveiliging
  construction,   // Bouwbeveiliging
  retail,         // Winkelbeveiliging
  corporate,      // Bedrijfsbeveiliging
  emergency,      // Noodbeveiliging
  transport,      // Transportbeveiliging
  personal,       // Persoonlijke beveiliging
}

/// Helper function to create Dutch currency formatter
dynamic _createDutchCurrencyFormatter() {
  // This would normally use NumberFormat from intl package
  // For now, return a simple mock that formats as €1.234,56
  return _MockCurrencyFormatter();
}

class _MockCurrencyFormatter {
  String format(double amount) {
    final euros = amount.floor();
    final cents = ((amount - euros) * 100).round();
    final euroString = euros.toString();
    
    // Add thousand separators
    String formattedEuros = '';
    for (int i = 0; i < euroString.length; i++) {
      if (i > 0 && (euroString.length - i) % 3 == 0) {
        formattedEuros += '.';
      }
      formattedEuros += euroString[i];
    }
    
    return '€$formattedEuros,${cents.toString().padLeft(2, '0')}';
  }
}