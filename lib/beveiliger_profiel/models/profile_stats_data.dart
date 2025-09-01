/// Profile statistics data model integrated with performance analytics
/// 
/// Consolidates user profile metrics with existing dashboard analytics
/// Provides Dutch-formatted data for profile statistics display
class ProfileStatsData {
  final DateTime memberSinceDate;
  final int totalJobsCompleted;
  final int totalHoursWorked;
  final int certificatesCount;
  final double averageRating;
  final double completionRate;
  final double averageHourlyRate;
  final double monthlyEarnings;
  final int activeSpecializations;
  final double repeatJobPercentage;
  final DateTime lastUpdated;
  
  const ProfileStatsData({
    required this.memberSinceDate,
    required this.totalJobsCompleted,
    required this.totalHoursWorked,
    required this.certificatesCount,
    required this.averageRating,
    required this.completionRate,
    required this.averageHourlyRate,
    required this.monthlyEarnings,
    required this.activeSpecializations,
    required this.repeatJobPercentage,
    required this.lastUpdated,
  });

  /// Factory constructor for empty/initial state
  factory ProfileStatsData.empty() {
    return ProfileStatsData(
      memberSinceDate: DateTime.now(),
      totalJobsCompleted: 0,
      totalHoursWorked: 0,
      certificatesCount: 0,
      averageRating: 0.0,
      completionRate: 0.0,
      averageHourlyRate: 0.0,
      monthlyEarnings: 0.0,
      activeSpecializations: 0,
      repeatJobPercentage: 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create copy with updated values
  ProfileStatsData copyWith({
    DateTime? memberSinceDate,
    int? totalJobsCompleted,
    int? totalHoursWorked,
    int? certificatesCount,
    double? averageRating,
    double? completionRate,
    double? averageHourlyRate,
    double? monthlyEarnings,
    int? activeSpecializations,
    double? repeatJobPercentage,
    DateTime? lastUpdated,
  }) {
    return ProfileStatsData(
      memberSinceDate: memberSinceDate ?? this.memberSinceDate,
      totalJobsCompleted: totalJobsCompleted ?? this.totalJobsCompleted,
      totalHoursWorked: totalHoursWorked ?? this.totalHoursWorked,
      certificatesCount: certificatesCount ?? this.certificatesCount,
      averageRating: averageRating ?? this.averageRating,
      completionRate: completionRate ?? this.completionRate,
      averageHourlyRate: averageHourlyRate ?? this.averageHourlyRate,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      activeSpecializations: activeSpecializations ?? this.activeSpecializations,
      repeatJobPercentage: repeatJobPercentage ?? this.repeatJobPercentage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Convert to JSON for persistence/API calls
  Map<String, dynamic> toJson() {
    return {
      'memberSinceDate': memberSinceDate.toIso8601String(),
      'totalJobsCompleted': totalJobsCompleted,
      'totalHoursWorked': totalHoursWorked,
      'certificatesCount': certificatesCount,
      'averageRating': averageRating,
      'completionRate': completionRate,
      'averageHourlyRate': averageHourlyRate,
      'monthlyEarnings': monthlyEarnings,
      'activeSpecializations': activeSpecializations,
      'repeatJobPercentage': repeatJobPercentage,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ProfileStatsData.fromJson(Map<String, dynamic> json) {
    return ProfileStatsData(
      memberSinceDate: DateTime.parse(json['memberSinceDate'] as String),
      totalJobsCompleted: json['totalJobsCompleted'] as int,
      totalHoursWorked: json['totalHoursWorked'] as int,
      certificatesCount: json['certificatesCount'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      completionRate: (json['completionRate'] as num).toDouble(),
      averageHourlyRate: (json['averageHourlyRate'] as num).toDouble(),
      monthlyEarnings: (json['monthlyEarnings'] as num).toDouble(),
      activeSpecializations: json['activeSpecializations'] as int,
      repeatJobPercentage: (json['repeatJobPercentage'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// Get Dutch-formatted monthly earnings
  String get dutchFormattedMonthlyEarnings {
    final euros = monthlyEarnings.floor();
    final cents = ((monthlyEarnings - euros) * 100).round();
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

  /// Get Dutch-formatted hourly rate
  String get dutchFormattedHourlyRate {
    return '€${averageHourlyRate.toStringAsFixed(2)}';
  }

  /// Get experience level based on hours worked
  ExperienceLevel get experienceLevel {
    if (totalHoursWorked >= 2000) {
      return ExperienceLevel.expert; // 2000+ hours (1+ year full-time)
    } else if (totalHoursWorked >= 1000) {
      return ExperienceLevel.experienced; // 1000+ hours (6 months full-time)
    } else if (totalHoursWorked >= 200) {
      return ExperienceLevel.intermediate; // 200+ hours (5 weeks full-time)
    } else {
      return ExperienceLevel.beginner; // Less than 200 hours
    }
  }

  /// Get performance rating category
  PerformanceCategory get performanceCategory {
    if (averageRating >= 4.5 && completionRate >= 95) {
      return PerformanceCategory.excellent;
    } else if (averageRating >= 4.0 && completionRate >= 85) {
      return PerformanceCategory.good;
    } else if (averageRating >= 3.5 && completionRate >= 75) {
      return PerformanceCategory.satisfactory;
    } else {
      return PerformanceCategory.needsImprovement;
    }
  }

  /// Calculate total earnings based on hours and hourly rate
  double get estimatedTotalEarnings => totalHoursWorked * averageHourlyRate;

  /// Get career milestone information
  CareerMilestone get currentMilestone {
    if (totalJobsCompleted >= 100) {
      return CareerMilestone.centurion; // 100+ jobs completed
    } else if (totalJobsCompleted >= 50) {
      return CareerMilestone.veteran; // 50+ jobs completed
    } else if (totalJobsCompleted >= 20) {
      return CareerMilestone.experienced; // 20+ jobs completed
    } else if (totalJobsCompleted >= 10) {
      return CareerMilestone.established; // 10+ jobs completed
    } else if (totalJobsCompleted >= 5) {
      return CareerMilestone.developing; // 5+ jobs completed
    } else {
      return CareerMilestone.newbie; // Less than 5 jobs
    }
  }

  /// Check if user qualifies for premium features
  bool get qualifiesForPremiumFeatures {
    return averageRating >= 4.0 && 
           completionRate >= 80 && 
           totalJobsCompleted >= 10;
  }

  /// Get reliability score (0-100)
  int get reliabilityScore {
    double score = 0.0;
    
    // Completion rate contributes 40%
    score += completionRate * 0.4;
    
    // Average rating contributes 30% (scaled to 0-100)
    score += (averageRating / 5.0) * 100 * 0.3;
    
    // Repeat job percentage contributes 20%
    score += repeatJobPercentage * 0.2;
    
    // Experience bonus contributes 10%
    final experienceBonus = (totalJobsCompleted.clamp(0, 50) / 50) * 100 * 0.1;
    score += experienceBonus;
    
    return score.round().clamp(0, 100);
  }

  /// Get performance trend based on recent metrics
  PerformanceTrend get performanceTrend {
    // This would typically compare with historical data
    // For now, we'll use current metrics to estimate trend
    if (completionRate >= 90 && averageRating >= 4.5) {
      return PerformanceTrend.improving;
    } else if (completionRate >= 80 && averageRating >= 4.0) {
      return PerformanceTrend.stable;
    } else {
      return PerformanceTrend.declining;
    }
  }
}

/// Experience level enumeration
enum ExperienceLevel {
  beginner,
  intermediate,
  experienced,
  expert;

  String get dutchDescription {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Gemiddeld';
      case ExperienceLevel.experienced:
        return 'Ervaren';
      case ExperienceLevel.expert:
        return 'Expert';
    }
  }

  int get minimumHours {
    switch (this) {
      case ExperienceLevel.beginner:
        return 0;
      case ExperienceLevel.intermediate:
        return 200;
      case ExperienceLevel.experienced:
        return 1000;
      case ExperienceLevel.expert:
        return 2000;
    }
  }
}

/// Performance category enumeration
enum PerformanceCategory {
  needsImprovement,
  satisfactory,
  good,
  excellent;

  String get dutchDescription {
    switch (this) {
      case PerformanceCategory.needsImprovement:
        return 'Kan beter';
      case PerformanceCategory.satisfactory:
        return 'Voldoende';
      case PerformanceCategory.good:
        return 'Goed';
      case PerformanceCategory.excellent:
        return 'Uitstekend';
    }
  }

  String get dutchAdvice {
    switch (this) {
      case PerformanceCategory.needsImprovement:
        return 'Focus op het verbeteren van je beoordelingen en voltooiingspercentage.';
      case PerformanceCategory.satisfactory:
        return 'Je doet het goed! Probeer je beoordelingen te verbeteren.';
      case PerformanceCategory.good:
        return 'Sterke prestaties! Behoud dit niveau.';
      case PerformanceCategory.excellent:
        return 'Uitstekend werk! Je bent een topbeveiliger.';
    }
  }
}

/// Career milestone enumeration
enum CareerMilestone {
  newbie,
  developing,
  established,
  experienced,
  veteran,
  centurion;

  String get dutchTitle {
    switch (this) {
      case CareerMilestone.newbie:
        return 'Nieuwkomer';
      case CareerMilestone.developing:
        return 'In ontwikkeling';
      case CareerMilestone.established:
        return 'Gevestigd';
      case CareerMilestone.experienced:
        return 'Ervaren beveiliger';
      case CareerMilestone.veteran:
        return 'Veteraan';
      case CareerMilestone.centurion:
        return 'Centurion (100+)';
    }
  }

  String get dutchDescription {
    switch (this) {
      case CareerMilestone.newbie:
        return 'Je bent net begonnen met beveiligingswerk';
      case CareerMilestone.developing:
        return 'Je bouwt ervaring op';
      case CareerMilestone.established:
        return 'Je hebt een solide basis gelegd';
      case CareerMilestone.experienced:
        return 'Je bent een ervaren beveiliger';
      case CareerMilestone.veteran:
        return 'Je bent een veteraan in de beveiliging';
      case CareerMilestone.centurion:
        return 'Je hebt meer dan 100 opdrachten voltooid!';
    }
  }

  int get requiredJobs {
    switch (this) {
      case CareerMilestone.newbie:
        return 0;
      case CareerMilestone.developing:
        return 5;
      case CareerMilestone.established:
        return 10;
      case CareerMilestone.experienced:
        return 20;
      case CareerMilestone.veteran:
        return 50;
      case CareerMilestone.centurion:
        return 100;
    }
  }
}

/// Performance trend enumeration
enum PerformanceTrend {
  declining,
  stable,
  improving;

  String get dutchDescription {
    switch (this) {
      case PerformanceTrend.declining:
        return 'Dalend';
      case PerformanceTrend.stable:
        return 'Stabiel';
      case PerformanceTrend.improving:
        return 'Stijgend';
    }
  }

  String get dutchAdvice {
    switch (this) {
      case PerformanceTrend.declining:
        return 'Focus op het verbeteren van je prestaties';
      case PerformanceTrend.stable:
        return 'Behoud je goede prestaties';
      case PerformanceTrend.improving:
        return 'Blijf zo doorgaan!';
    }
  }
}