import 'dart:math' as math;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/time_entry_model.dart';
import '../models/shift_model.dart';
import '../models/leave_request_model.dart';

/// CAOCalculationService for Nederlandse beveiligingssector arbeidsrecht compliance
/// 
/// Features:
/// - CAO Particuliere Beveiliging 2024 compliance
/// - Hourly rate calculations with premiums
/// - Overtime, weekend, and night shift calculations
/// - Holiday pay (vakantiegeld) calculations
/// - Rest period validation
/// - Weekly/monthly hour tracking
/// - Vacation day accrual
class CAOCalculationService {
  
  // CAO 2024 constants for Nederlandse Beveiligingssector
  static const double _minimumHourlyRate = 12.00; // Minimum wage security 2024
  static const double _standardWorkWeek = 40.0; // Standard work hours per week
  static const double _maximumDailyHours = 12.0; // Maximum hours per day
  static const double _maximumWeeklyHours = 60.0; // Maximum hours per week
  static const double _minimumRestPeriod = 11.0; // Minimum rest hours between shifts
  static const double _holidayPayPercentage = 0.08; // 8% vakantiegeld
  static const int _standardVacationDays = 25; // Minimum vacation days per year
  
  // Multipliers for different shift types
  static const double _overtimeMultiplier = 1.5; // 150% for overtime
  static const double _nightShiftMultiplier = 1.3; // 130% for night shifts (22:00-06:00)
  static const double _saturdayMultiplier = 1.5; // 150% for Saturday work
  static const double _sundayMultiplier = 2.0; // 200% for Sunday work
  static const double _holidayMultiplier = 2.0; // 200% for national holidays
  
  CAOCalculationService() {
    tz_data.initializeTimeZones();
  }
  
  /// Get Amsterdam timezone
  tz.Location get _amsterdamTimezone => tz.getLocation('Europe/Amsterdam');

  /// Convert UTC to Amsterdam time
  tz.TZDateTime _toAmsterdamTime(DateTime utcTime) {
    return tz.TZDateTime.from(utcTime, _amsterdamTimezone);
  }

  /// Calculate total earnings for a time entry with CAO compliance
  CAOEarningsResult calculateEarnings({
    required TimeEntry timeEntry,
    required double baseHourlyRate,
    required List<TimeEntry> weeklyTimeEntries,
  }) {
    if (baseHourlyRate < _minimumHourlyRate) {
      throw CAOException(
        'Uurloon (€${baseHourlyRate.toStringAsFixed(2)}) is lager dan CAO minimum (€${_minimumHourlyRate.toStringAsFixed(2)})',
        CAOErrorType.belowMinimumWage,
      );
    }
    
    final startTime = _toAmsterdamTime(timeEntry.checkInTime!);
    final endTime = _toAmsterdamTime(timeEntry.checkOutTime!);
    
    // Calculate work duration excluding breaks
    final totalBreakTime = timeEntry.breaks
        .where((b) => b.endTime != null && !b.isPaid)
        .map((b) => b.actualDuration ?? Duration.zero)
        .fold(Duration.zero, (a, b) => a + b);
    
    final workDuration = endTime.difference(startTime) - totalBreakTime;
    final totalHours = workDuration.inMinutes / 60.0;
    
    // Determine shift type and calculate rates
    final shiftAnalysis = _analyzeShift(startTime, endTime);
    final weeklyHours = _calculateWeeklyHours(weeklyTimeEntries, timeEntry);
    
    // Calculate hours by category
    final regularHours = math.min(totalHours, 8.0);
    final overtimeHours = totalHours > 8.0 ? totalHours - 8.0 : 0.0;
    
    // Calculate earnings by category
    double regularEarnings = 0.0;
    double overtimeEarnings = 0.0;
    double weekendEarnings = 0.0;
    double nightShiftEarnings = 0.0;
    double holidayEarnings = 0.0;
    
    if (shiftAnalysis.isHoliday) {
      holidayEarnings = totalHours * baseHourlyRate * _holidayMultiplier;
    } else if (shiftAnalysis.isWeekend) {
      final multiplier = shiftAnalysis.isSunday ? _sundayMultiplier : _saturdayMultiplier;
      weekendEarnings = totalHours * baseHourlyRate * multiplier;
    } else if (shiftAnalysis.isNightShift) {
      nightShiftEarnings = totalHours * baseHourlyRate * _nightShiftMultiplier;
    } else {
      // Regular weekday shift
      regularEarnings = regularHours * baseHourlyRate;
      if (overtimeHours > 0.0) {
        overtimeEarnings = overtimeHours * baseHourlyRate * _overtimeMultiplier;
      }
    }
    
    final totalEarnings = regularEarnings + overtimeEarnings + weekendEarnings + 
                         nightShiftEarnings + holidayEarnings;
    
    // Calculate holiday pay (8% vakantiegeld)
    final holidayPay = totalEarnings * _holidayPayPercentage;
    
    // Validate CAO compliance
    final compliance = _validateCAOCompliance(
      timeEntry: timeEntry,
      totalHours: totalHours,
      weeklyHours: weeklyHours,
      weeklyTimeEntries: weeklyTimeEntries,
    );
    
    return CAOEarningsResult(
      regularHours: regularHours,
      overtimeHours: overtimeHours,
      weekendHours: shiftAnalysis.isWeekend ? totalHours : 0.0,
      nightShiftHours: shiftAnalysis.isNightShift ? totalHours : 0.0,
      holidayHours: shiftAnalysis.isHoliday ? totalHours : 0.0,
      regularEarnings: regularEarnings,
      overtimeEarnings: overtimeEarnings,
      weekendEarnings: weekendEarnings,
      nightShiftEarnings: nightShiftEarnings,
      holidayEarnings: holidayEarnings,
      totalEarnings: totalEarnings,
      holidayPay: holidayPay,
      totalWithHolidayPay: totalEarnings + holidayPay,
      baseHourlyRate: baseHourlyRate,
      effectiveHourlyRate: totalEarnings / totalHours,
      caoCompliance: compliance,
      shiftAnalysis: shiftAnalysis,
    );
  }

  /// Analyze shift characteristics
  ShiftAnalysis _analyzeShift(tz.TZDateTime startTime, tz.TZDateTime endTime) {
    final startHour = startTime.hour + (startTime.minute / 60.0);
    final endHour = endTime.hour + (endTime.minute / 60.0);
    
    // Check if weekend
    final isWeekend = startTime.weekday > 5; // Saturday = 6, Sunday = 7
    final isSunday = startTime.weekday == 7;
    
    // Check if night shift (22:00 - 06:00)
    final isNightShift = startHour >= 22.0 || endHour <= 6.0 || 
                        (startHour >= 22.0 && endHour <= 24.0) ||
                        (startHour >= 0.0 && endHour <= 6.0);
    
    // Check if national holiday
    final isHoliday = _isNationalHoliday(startTime);
    
    return ShiftAnalysis(
      isWeekend: isWeekend,
      isSunday: isSunday,
      isNightShift: isNightShift && !isWeekend, // Weekend premium takes precedence
      isHoliday: isHoliday,
      startHour: startHour,
      endHour: endHour,
    );
  }

  /// Check if date is a Nederlandse national holiday
  bool _isNationalHoliday(tz.TZDateTime date) {
    final year = date.year;
    final month = date.month;
    final day = date.day;
    
    // Fixed holidays
    final fixedHolidays = [
      DateTime(year, 1, 1),   // Nieuwjaarsdag
      DateTime(year, 4, 27),  // Koningsdag
      DateTime(year, 5, 5),   // Bevrijdingsdag (every 5 years or by special decree)
      DateTime(year, 12, 25), // Eerste Kerstdag
      DateTime(year, 12, 26), // Tweede Kerstdag
    ];
    
    // Check fixed holidays
    final currentDate = DateTime(year, month, day);
    if (fixedHolidays.any((holiday) => 
        holiday.year == currentDate.year && 
        holiday.month == currentDate.month && 
        holiday.day == currentDate.day)) {
      return true;
    }
    
    // Calculate Easter-based holidays
    final easterSunday = _calculateEaster(year);
    final easterMonday = easterSunday.add(const Duration(days: 1));
    final goodFriday = easterSunday.subtract(const Duration(days: 2));
    final ascensionDay = easterSunday.add(const Duration(days: 39));
    final whitMonday = easterSunday.add(const Duration(days: 50));
    
    final easterHolidays = [
      goodFriday,
      easterMonday,
      ascensionDay,
      whitMonday,
    ];
    
    return easterHolidays.any((holiday) => 
        holiday.year == currentDate.year && 
        holiday.month == currentDate.month && 
        holiday.day == currentDate.day);
  }

  /// Calculate Easter Sunday for given year (Gregorian calendar)
  DateTime _calculateEaster(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    
    return DateTime(year, month, day);
  }

  /// Calculate total weekly hours including current time entry
  double _calculateWeeklyHours(List<TimeEntry> weeklyTimeEntries, TimeEntry currentEntry) {
    double totalHours = 0.0;
    
    for (final entry in weeklyTimeEntries) {
      if (entry.id == currentEntry.id) continue; // Don't double count
      
      if (entry.checkInTime != null && entry.checkOutTime != null) {
        final workDuration = entry.checkOutTime!.difference(entry.checkInTime!);
        final breakTime = entry.breaks
            .where((b) => b.endTime != null && !b.isPaid)
            .map((b) => b.actualDuration ?? Duration.zero)
            .fold(Duration.zero, (a, b) => a + b);
        
        final actualWork = workDuration - breakTime;
        totalHours += actualWork.inMinutes / 60.0;
      }
    }
    
    // Add current entry hours
    if (currentEntry.checkInTime != null && currentEntry.checkOutTime != null) {
      final workDuration = currentEntry.checkOutTime!.difference(currentEntry.checkInTime!);
      final breakTime = currentEntry.breaks
          .where((b) => b.endTime != null && !b.isPaid)
          .map((b) => b.actualDuration ?? Duration.zero)
          .fold(Duration.zero, (a, b) => a + b);
      
      final actualWork = workDuration - breakTime;
      totalHours += actualWork.inMinutes / 60.0;
    }
    
    return totalHours;
  }

  /// Validate CAO compliance for time entry
  CAOComplianceResult _validateCAOCompliance({
    required TimeEntry timeEntry,
    required double totalHours,
    required double weeklyHours,
    required List<TimeEntry> weeklyTimeEntries,
  }) {
    final violations = <CAOViolation>[];
    final warnings = <String>[];
    
    // Check maximum daily hours
    if (totalHours > _maximumDailyHours) {
      violations.add(CAOViolation(
        type: CAOViolationType.exceedsMaximumHours,
        description: 'Dienst van ${totalHours.toStringAsFixed(1)} uur overschrijdt CAO maximum van $_maximumDailyHours uur per dag',
        severity: 0.9,
        detectedAt: DateTime.now().toUtc(),
      ));
    }
    
    // Check maximum weekly hours
    if (weeklyHours > _maximumWeeklyHours) {
      violations.add(CAOViolation(
        type: CAOViolationType.exceedsMaximumHours,
        description: 'Weekelijks totaal van ${weeklyHours.toStringAsFixed(1)} uur overschrijdt CAO maximum van $_maximumWeeklyHours uur per week',
        severity: 0.8,
        detectedAt: DateTime.now().toUtc(),
      ));
    }
    
    // Check required breaks
    final requiredBreaks = _calculateRequiredBreaks(totalHours);
    final actualBreaks = timeEntry.breaks.where((b) => b.endTime != null).toList();
    final actualBreakTime = actualBreaks
        .map((b) => b.actualDuration ?? Duration.zero)
        .fold(Duration.zero, (a, b) => a + b);
    
    if (actualBreakTime.inMinutes < requiredBreaks.inMinutes) {
      violations.add(CAOViolation(
        type: CAOViolationType.missingRequiredBreaks,
        description: 'Pauzetijd van ${actualBreakTime.inMinutes} minuten is minder dan CAO vereiste van ${requiredBreaks.inMinutes} minuten',
        severity: 0.7,
        detectedAt: DateTime.now().toUtc(),
      ));
    }
    
    // Check rest period before shift
    final restPeriodBefore = _calculateRestPeriodBefore(timeEntry, weeklyTimeEntries);
    if (restPeriodBefore < _minimumRestPeriod) {
      if (restPeriodBefore < 8.0) {
        violations.add(CAOViolation(
          type: CAOViolationType.insufficientRestPeriod,
          description: 'Rusttijd voor dienst van ${restPeriodBefore.toStringAsFixed(1)} uur is minder dan CAO minimum van $_minimumRestPeriod uur',
          severity: 0.8,
          detectedAt: DateTime.now().toUtc(),
        ));
      } else {
        warnings.add('Rusttijd voor dienst van ${restPeriodBefore.toStringAsFixed(1)} uur is minder dan CAO aanbeveling van $_minimumRestPeriod uur');
      }
    }
    
    return CAOComplianceResult(
      isCompliant: violations.isEmpty,
      violations: violations,
      warnings: warnings,
      totalHours: totalHours,
      weeklyHours: weeklyHours,
      requiredBreaks: requiredBreaks,
      actualBreaks: actualBreakTime,
      restPeriodBefore: restPeriodBefore,
      exceedsDailyLimit: totalHours > _maximumDailyHours,
      exceedsWeeklyLimit: weeklyHours > _maximumWeeklyHours,
    );
  }

  /// Calculate required break time based on work hours
  Duration _calculateRequiredBreaks(double workHours) {
    if (workHours >= 8.0) {
      return const Duration(minutes: 45); // 45 minutes for 8+ hours
    } else if (workHours >= 5.5) {
      return const Duration(minutes: 30); // 30 minutes for 5.5-8 hours
    } else if (workHours >= 4.0) {
      return const Duration(minutes: 15); // 15 minutes for 4-5.5 hours
    }
    return Duration.zero; // No break required for < 4 hours
  }

  /// Calculate rest period before current shift
  double _calculateRestPeriodBefore(TimeEntry currentEntry, List<TimeEntry> weeklyEntries) {
    if (currentEntry.checkInTime == null) return _minimumRestPeriod;
    
    // Find the most recent previous shift
    TimeEntry? previousEntry;
    DateTime? latestEndTime;
    
    for (final entry in weeklyEntries) {
      if (entry.id == currentEntry.id || entry.checkOutTime == null) continue;
      
      if (entry.checkOutTime!.isBefore(currentEntry.checkInTime!) &&
          (latestEndTime == null || entry.checkOutTime!.isAfter(latestEndTime))) {
        previousEntry = entry;
        latestEndTime = entry.checkOutTime;
      }
    }
    
    if (previousEntry?.checkOutTime == null) return _minimumRestPeriod;
    
    final restPeriod = currentEntry.checkInTime!.difference(previousEntry!.checkOutTime!);
    return restPeriod.inMinutes / 60.0;
  }

  /// Calculate vacation day accrual based on worked hours
  VacationAccrualResult calculateVacationAccrual({
    required List<TimeEntry> yearlyTimeEntries,
    required int year,
    required DateTime employmentStartDate,
  }) {
    // Calculate total worked hours in year
    double totalWorkedHours = 0.0;
    for (final entry in yearlyTimeEntries) {
      if (entry.checkInTime != null && entry.checkOutTime != null) {
        final workDuration = entry.checkOutTime!.difference(entry.checkInTime!);
        final breakTime = entry.breaks
            .where((b) => b.endTime != null && !b.isPaid)
            .map((b) => b.actualDuration ?? Duration.zero)
            .fold(Duration.zero, (a, b) => a + b);
        
        final actualWork = workDuration - breakTime;
        totalWorkedHours += actualWork.inMinutes / 60.0;
      }
    }
    
    // Standard full-time is 40 hours/week * 52 weeks = 2080 hours/year
    const double fullTimeYearlyHours = 2080.0;
    final double workRatio = math.min(totalWorkedHours / fullTimeYearlyHours, 1.0);
    
    // Calculate vacation days (minimum 25 days for full-time)
    final double earnedVacationDays = _standardVacationDays * workRatio;
    
    // Pro-rate if employment started during the year
    final employmentStart = DateTime(year, 1, 1);
    final employmentEnd = DateTime(year, 12, 31);
    final actualStart = employmentStartDate.isAfter(employmentStart) ? employmentStartDate : employmentStart;
    
    final daysInYear = employmentEnd.difference(employmentStart).inDays + 1;
    final daysWorked = employmentEnd.difference(actualStart).inDays + 1;
    final proRateRatio = daysWorked / daysInYear;
    
    final finalVacationDays = earnedVacationDays * proRateRatio;
    
    return VacationAccrualResult(
      totalWorkedHours: totalWorkedHours,
      workRatio: workRatio,
      earnedVacationDays: finalVacationDays,
      fullTimeEquivalent: workRatio,
      year: year,
      proRateRatio: proRateRatio,
    );
  }

  /// Calculate holiday pay for a period
  HolidayPayResult calculateHolidayPay({
    required List<TimeEntry> timeEntries,
    required double baseHourlyRate,
  }) {
    double totalEarnings = 0.0;
    double totalHours = 0.0;
    
    for (final entry in timeEntries) {
      final result = calculateEarnings(
        timeEntry: entry,
        baseHourlyRate: baseHourlyRate,
        weeklyTimeEntries: [], // Simplified for holiday pay calculation
      );
      
      totalEarnings += result.totalEarnings;
      totalHours += result.regularHours + result.overtimeHours + 
                   result.weekendHours + result.nightShiftHours + result.holidayHours;
    }
    
    final holidayPay = totalEarnings * _holidayPayPercentage;
    
    return HolidayPayResult(
      totalEarnings: totalEarnings,
      totalHours: totalHours,
      holidayPayAmount: holidayPay,
      holidayPayPercentage: _holidayPayPercentage,
    );
  }
}

/// CAO earnings calculation result
class CAOEarningsResult {
  final double regularHours;
  final double overtimeHours;
  final double weekendHours;
  final double nightShiftHours;
  final double holidayHours;
  final double regularEarnings;
  final double overtimeEarnings;
  final double weekendEarnings;
  final double nightShiftEarnings;
  final double holidayEarnings;
  final double totalEarnings;
  final double holidayPay;
  final double totalWithHolidayPay;
  final double baseHourlyRate;
  final double effectiveHourlyRate;
  final CAOComplianceResult caoCompliance;
  final ShiftAnalysis shiftAnalysis;

  const CAOEarningsResult({
    required this.regularHours,
    required this.overtimeHours,
    required this.weekendHours,
    required this.nightShiftHours,
    required this.holidayHours,
    required this.regularEarnings,
    required this.overtimeEarnings,
    required this.weekendEarnings,
    required this.nightShiftEarnings,
    required this.holidayEarnings,
    required this.totalEarnings,
    required this.holidayPay,
    required this.totalWithHolidayPay,
    required this.baseHourlyRate,
    required this.effectiveHourlyRate,
    required this.caoCompliance,
    required this.shiftAnalysis,
  });
}

/// Shift analysis result
class ShiftAnalysis {
  final bool isWeekend;
  final bool isSunday;
  final bool isNightShift;
  final bool isHoliday;
  final double startHour;
  final double endHour;

  const ShiftAnalysis({
    required this.isWeekend,
    required this.isSunday,
    required this.isNightShift,
    required this.isHoliday,
    required this.startHour,
    required this.endHour,
  });
}

/// CAO compliance result
class CAOComplianceResult {
  final bool isCompliant;
  final List<CAOViolation> violations;
  final List<String> warnings;
  final double totalHours;
  final double weeklyHours;
  final Duration requiredBreaks;
  final Duration actualBreaks;
  final double restPeriodBefore;
  final bool exceedsDailyLimit;
  final bool exceedsWeeklyLimit;

  const CAOComplianceResult({
    required this.isCompliant,
    required this.violations,
    required this.warnings,
    required this.totalHours,
    required this.weeklyHours,
    required this.requiredBreaks,
    required this.actualBreaks,
    required this.restPeriodBefore,
    required this.exceedsDailyLimit,
    required this.exceedsWeeklyLimit,
  });
}

/// Vacation accrual result
class VacationAccrualResult {
  final double totalWorkedHours;
  final double workRatio;
  final double earnedVacationDays;
  final double fullTimeEquivalent;
  final int year;
  final double proRateRatio;

  const VacationAccrualResult({
    required this.totalWorkedHours,
    required this.workRatio,
    required this.earnedVacationDays,
    required this.fullTimeEquivalent,
    required this.year,
    required this.proRateRatio,
  });
}

/// Holiday pay calculation result
class HolidayPayResult {
  final double totalEarnings;
  final double totalHours;
  final double holidayPayAmount;
  final double holidayPayPercentage;

  const HolidayPayResult({
    required this.totalEarnings,
    required this.totalHours,
    required this.holidayPayAmount,
    required this.holidayPayPercentage,
  });
}

/// CAO exception types
enum CAOErrorType {
  belowMinimumWage,
  exceedsMaximumHours,
  insufficientRestPeriod,
  missingRequiredBreaks,
  invalidTimeEntry,
}

/// CAO calculation exception
class CAOException implements Exception {
  final String message;
  final CAOErrorType type;
  
  const CAOException(this.message, this.type);
  
  @override
  String toString() => 'CAOException: $message';
}