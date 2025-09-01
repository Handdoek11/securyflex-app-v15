import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/time_entry_model.dart';
import '../models/shift_model.dart';

/// PayrollExportService for SecuryFlex CAO-compliant payroll processing
/// 
/// Features:
/// - CSV/Excel export with Dutch payroll system compatibility
/// - CAO arbeidsrecht compliant calculations
/// - Automated overtime/weekend/night shift calculations
/// - BTW 21% calculations for freelance security work
/// - Integration with Dutch payroll systems (AFAS, Exact, Nmbrs)
/// - Vakantiegeld (holiday pay) calculations at 8%
/// - Pensioenpremie calculations
class PayrollExportService {
  final FirebaseFirestore _firestore;
  
  // CAO Security 2024 rates
  static const double _baseSalaryPerHour = 12.00; // €12.00/hour minimum
  static const double _overtimeRate = 1.5; // 150% after 40h/week
  static const double _doubleOvertimeRate = 2.0; // 200% after 48h/week
  static const double _weekendSurcharge = 1.25; // 25% weekend surcharge
  static const double _nightSurcharge = 1.15; // 15% night surcharge (22:00-06:00)
  static const double _holidayPayPercentage = 0.08; // 8% vakantiegeld
  static const double _pensionContribution = 0.055; // 5.5% pension contribution
  static const double _btwRate = 0.21; // 21% BTW for freelance work
  
  // Work time limits per CAO
  static const Duration _maxDailyHours = Duration(hours: 12);
  static const Duration _regularWeeklyHours = Duration(hours: 40);
  static const Duration _maxWeeklyHours = Duration(hours: 48);
  
  PayrollExportService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    tz_data.initializeTimeZones();
  }

  /// Get Amsterdam timezone for Dutch payroll calculations
  tz.Location get _amsterdamTimezone => tz.getLocation('Europe/Amsterdam');

  /// Convert UTC to Amsterdam time for payroll calculations
  tz.TZDateTime _toAmsterdamTime(DateTime utcTime) {
    return tz.TZDateTime.from(utcTime, _amsterdamTimezone);
  }

  /// Export time entries to CSV for payroll processing
  Future<File> exportToCSV({
    required List<TimeEntry> timeEntries,
    required String periodDescription,
    PayrollFormat format = PayrollFormat.standard,
  }) async {
    try {
      final payrollData = await _calculatePayrollData(timeEntries);
      final csvData = _generateCSVData(payrollData, periodDescription, format);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'payroll_${_sanitizeFileName(periodDescription)}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      
      // Convert to CSV format
      String csv = const ListToCsvConverter().convert(csvData);
      
      await file.writeAsString(csv, encoding: utf8);
      
      // Log export for audit trail
      await _logPayrollExport(timeEntries, file.path, format);
      
      return file;
      
    } catch (e) {
      throw PayrollExportException(
        'Payroll export mislukt: ${e.toString()}',
        PayrollExportErrorType.exportFailed,
      );
    }
  }

  /// Calculate comprehensive payroll data with CAO compliance
  Future<List<PayrollEntry>> _calculatePayrollData(List<TimeEntry> timeEntries) async {
    final Map<String, List<TimeEntry>> entriesByGuard = {};
    
    // Group entries by guard ID
    for (final entry in timeEntries) {
      if (!entriesByGuard.containsKey(entry.guardId)) {
        entriesByGuard[entry.guardId] = [];
      }
      entriesByGuard[entry.guardId]!.add(entry);
    }
    
    final payrollEntries = <PayrollEntry>[];
    
    // Calculate payroll for each guard
    for (final guardId in entriesByGuard.keys) {
      final guardEntries = entriesByGuard[guardId]!;
      final payrollEntry = await _calculateGuardPayroll(guardId, guardEntries);
      payrollEntries.add(payrollEntry);
    }
    
    return payrollEntries;
  }

  /// Calculate comprehensive payroll data for a single guard
  Future<PayrollEntry> _calculateGuardPayroll(String guardId, List<TimeEntry> entries) async {
    // Sort entries by date for weekly calculations
    entries.sort((a, b) => a.checkInTime!.compareTo(b.checkInTime!));
    
    // Get guard information
    final guardInfo = await _getGuardInfo(guardId);
    
    // Initialize totals
    double totalRegularHours = 0.0;
    double totalOvertimeHours = 0.0;
    double totalDoubleOvertimeHours = 0.0;
    double totalWeekendHours = 0.0;
    double totalNightHours = 0.0;
    double totalBreakDeductions = 0.0;
    
    // Group by week for overtime calculations
    final Map<String, List<TimeEntry>> entriesByWeek = _groupEntriesByWeek(entries);
    
    for (final weekEntries in entriesByWeek.values) {
      final weeklyHours = _calculateWeeklyHours(weekEntries);
      
      totalRegularHours += weeklyHours.regular;
      totalOvertimeHours += weeklyHours.overtime;
      totalDoubleOvertimeHours += weeklyHours.doubleOvertime;
      totalWeekendHours += weeklyHours.weekend;
      totalNightHours += weeklyHours.night;
      totalBreakDeductions += weeklyHours.unpaidBreaks;
    }
    
    // Calculate base pay
    final basePay = totalRegularHours * guardInfo.hourlyRate;
    
    // Calculate overtime pay
    final overtimePay = totalOvertimeHours * guardInfo.hourlyRate * _overtimeRate;
    final doubleOvertimePay = totalDoubleOvertimeHours * guardInfo.hourlyRate * _doubleOvertimeRate;
    
    // Calculate surcharges
    final weekendPay = totalWeekendHours * guardInfo.hourlyRate * (_weekendSurcharge - 1.0);
    final nightPay = totalNightHours * guardInfo.hourlyRate * (_nightSurcharge - 1.0);
    
    // Calculate gross pay
    final grossPay = basePay + overtimePay + doubleOvertimePay + weekendPay + nightPay;
    
    // Calculate holiday pay (vakantiegeld)
    final holidayPay = grossPay * _holidayPayPercentage;
    
    // Calculate pension contribution
    final pensionContribution = grossPay * _pensionContribution;
    
    // Calculate BTW if applicable (freelancer)
    final btw = guardInfo.isFreelancer ? grossPay * _btwRate : 0.0;
    
    // Calculate net pay (simplified - real payroll includes taxes, social security)
    final netPay = grossPay - pensionContribution;
    
    return PayrollEntry(
      guardId: guardId,
      guardName: guardInfo.name,
      guardEmail: guardInfo.email,
      employmentType: guardInfo.employmentType,
      regularHours: totalRegularHours,
      overtimeHours: totalOvertimeHours,
      doubleOvertimeHours: totalDoubleOvertimeHours,
      weekendHours: totalWeekendHours,
      nightHours: totalNightHours,
      hourlyRate: guardInfo.hourlyRate,
      basePay: basePay,
      overtimePay: overtimePay,
      doubleOvertimePay: doubleOvertimePay,
      weekendPay: weekendPay,
      nightPay: nightPay,
      grossPay: grossPay,
      holidayPay: holidayPay,
      pensionContribution: pensionContribution,
      btw: btw,
      netPay: netPay,
      totalShifts: entries.length,
      caoCompliant: _checkCAOCompliance(entries),
      calculationDate: DateTime.now(),
    );
  }

  /// Group time entries by calendar week
  Map<String, List<TimeEntry>> _groupEntriesByWeek(List<TimeEntry> entries) {
    final Map<String, List<TimeEntry>> entriesByWeek = {};
    
    for (final entry in entries) {
      if (entry.checkInTime == null) continue;
      
      final amsterdamTime = _toAmsterdamTime(entry.checkInTime!);
      final weekKey = '${amsterdamTime.year}-W${_getWeekOfYear(amsterdamTime)}';
      
      if (!entriesByWeek.containsKey(weekKey)) {
        entriesByWeek[weekKey] = [];
      }
      entriesByWeek[weekKey]!.add(entry);
    }
    
    return entriesByWeek;
  }

  /// Calculate hours breakdown for a single week with CAO compliance
  WeeklyHours _calculateWeeklyHours(List<TimeEntry> weekEntries) {
    double totalHours = 0.0;
    double weekendHours = 0.0;
    double nightHours = 0.0;
    double unpaidBreaks = 0.0;
    
    for (final entry in weekEntries) {
      if (entry.checkInTime == null || entry.checkOutTime == null) continue;
      
      final checkInAmsterdam = _toAmsterdamTime(entry.checkInTime!);
      final checkOutAmsterdam = _toAmsterdamTime(entry.checkOutTime!);
      
      // Calculate work duration excluding unpaid breaks
      Duration workDuration = entry.actualWorkDuration ?? entry.checkOutTime!.difference(entry.checkInTime!);
      double hoursWorked = workDuration.inMinutes / 60.0;
      
      // Check if weekend work
      bool isWeekend = checkInAmsterdam.weekday > 5; // Saturday = 6, Sunday = 7
      
      // Check if night work (22:00 - 06:00)
      bool isNightWork = _isNightWork(checkInAmsterdam, checkOutAmsterdam);
      
      if (isWeekend) {
        weekendHours += hoursWorked;
      } else if (isNightWork) {
        nightHours += hoursWorked;
      } else {
        totalHours += hoursWorked;
      }
      
      // Calculate unpaid break time
      unpaidBreaks += _calculateUnpaidBreakTime(entry);
    }
    
    // Calculate overtime based on weekly totals
    double regularHours = math.min(totalHours, 40.0);
    double overtimeHours = math.max(0.0, math.min(totalHours - 40.0, 8.0)); // Hours 41-48
    double doubleOvertimeHours = math.max(0.0, totalHours - 48.0); // Hours 49+
    
    return WeeklyHours(
      regular: regularHours,
      overtime: overtimeHours,
      doubleOvertime: doubleOvertimeHours,
      weekend: weekendHours,
      night: nightHours,
      unpaidBreaks: unpaidBreaks,
    );
  }

  /// Check if work period includes night hours (22:00 - 06:00)
  bool _isNightWork(tz.TZDateTime checkIn, tz.TZDateTime checkOut) {
    final nightStart = DateTime(checkIn.year, checkIn.month, checkIn.day, 22, 0);
    final nightEnd = DateTime(checkIn.year, checkIn.month, checkIn.day + 1, 6, 0);
    
    return (checkIn.hour >= 22 || checkIn.hour < 6) || 
           (checkOut.hour >= 22 || checkOut.hour < 6) ||
           (checkIn.isBefore(nightStart) && checkOut.isAfter(nightEnd));
  }

  /// Calculate unpaid break time per CAO rules
  double _calculateUnpaidBreakTime(TimeEntry entry) {
    double unpaidBreaks = 0.0;
    
    for (final breakEntry in entry.breaks) {
      if (breakEntry.endTime != null && !breakEntry.isPaid) {
        unpaidBreaks += (breakEntry.actualDuration?.inMinutes ?? 0) / 60.0;
      }
    }
    
    return unpaidBreaks;
  }

  /// Get ISO week number
  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Generate CSV data based on format type
  List<List<String>> _generateCSVData(
    List<PayrollEntry> payrollData, 
    String periodDescription,
    PayrollFormat format,
  ) {
    switch (format) {
      case PayrollFormat.standard:
        return _generateStandardCSV(payrollData, periodDescription);
      case PayrollFormat.afas:
        return _generateAFASCSV(payrollData, periodDescription);
      case PayrollFormat.exact:
        return _generateExactCSV(payrollData, periodDescription);
      case PayrollFormat.nmbrs:
        return _generateNmbrsCSV(payrollData, periodDescription);
    }
  }

  /// Generate standard CSV format
  List<List<String>> _generateStandardCSV(List<PayrollEntry> payrollData, String period) {
    final data = <List<String>>[];
    
    // Header
    data.add([
      'Periode',
      'Medewerker ID',
      'Naam',
      'Email',
      'Type Dienstverband',
      'Normale Uren',
      'Overuren (150%)',
      'Dubbele Overuren (200%)',
      'Weekend Uren',
      'Nacht Uren',
      'Uurloon (€)',
      'Basis Loon (€)',
      'Overuren Toeslag (€)',
      'Weekend Toeslag (€)',
      'Nacht Toeslag (€)',
      'Bruto Loon (€)',
      'Vakantiegeld 8% (€)',
      'Pensioenpremie (€)',
      'BTW 21% (€)',
      'Netto Loon (€)',
      'Totaal Diensten',
      'CAO Compliant',
      'Berekening Datum'
    ]);
    
    // Data rows
    for (final entry in payrollData) {
      data.add([
        period,
        entry.guardId,
        entry.guardName,
        entry.guardEmail,
        entry.employmentType.dutchName,
        entry.regularHours.toStringAsFixed(2),
        entry.overtimeHours.toStringAsFixed(2),
        entry.doubleOvertimeHours.toStringAsFixed(2),
        entry.weekendHours.toStringAsFixed(2),
        entry.nightHours.toStringAsFixed(2),
        entry.hourlyRate.toStringAsFixed(2),
        entry.basePay.toStringAsFixed(2),
        entry.overtimePay.toStringAsFixed(2),
        entry.weekendPay.toStringAsFixed(2),
        entry.nightPay.toStringAsFixed(2),
        entry.grossPay.toStringAsFixed(2),
        entry.holidayPay.toStringAsFixed(2),
        entry.pensionContribution.toStringAsFixed(2),
        entry.btw.toStringAsFixed(2),
        entry.netPay.toStringAsFixed(2),
        entry.totalShifts.toString(),
        entry.caoCompliant ? 'Ja' : 'Nee',
        DateFormat('yyyy-MM-dd').format(entry.calculationDate),
      ]);
    }
    
    return data;
  }

  /// Generate AFAS-compatible CSV format
  List<List<String>> _generateAFASCSV(List<PayrollEntry> payrollData, String period) {
    // AFAS-specific format implementation
    // This would be customized for AFAS OnLine payroll import format
    return _generateStandardCSV(payrollData, period); // Placeholder
  }

  /// Generate Exact Online-compatible CSV format
  List<List<String>> _generateExactCSV(List<PayrollEntry> payrollData, String period) {
    // Exact Online-specific format implementation
    return _generateStandardCSV(payrollData, period); // Placeholder
  }

  /// Generate Nmbrs-compatible CSV format
  List<List<String>> _generateNmbrsCSV(List<PayrollEntry> payrollData, String period) {
    // Nmbrs-specific format implementation
    return _generateStandardCSV(payrollData, period); // Placeholder
  }

  /// Get guard information for payroll calculations
  Future<GuardInfo> _getGuardInfo(String guardId) async {
    try {
      final doc = await _firestore.collection('users').doc(guardId).get();
      
      if (!doc.exists) {
        throw PayrollExportException(
          'Guard informatie niet gevonden: $guardId',
          PayrollExportErrorType.guardNotFound,
        );
      }
      
      final data = doc.data()!;
      
      return GuardInfo(
        id: guardId,
        name: data['displayName'] ?? 'Onbekend',
        email: data['email'] ?? '',
        hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? _baseSalaryPerHour,
        employmentType: EmploymentType.values.firstWhere(
          (type) => type.name == (data['employmentType'] ?? 'employee'),
          orElse: () => EmploymentType.employee,
        ),
        isFreelancer: data['isFreelancer'] ?? false,
      );
      
    } catch (e) {
      throw PayrollExportException(
        'Guard informatie ophalen mislukt: ${e.toString()}',
        PayrollExportErrorType.dataFetchFailed,
      );
    }
  }

  /// Check CAO compliance for time entries
  bool _checkCAOCompliance(List<TimeEntry> entries) {
    for (final entry in entries) {
      if (!entry.caoCompliance.isCompliant) {
        return false;
      }
    }
    return true;
  }

  /// Log payroll export for audit trail
  Future<void> _logPayrollExport(
    List<TimeEntry> timeEntries,
    String filePath,
    PayrollFormat format,
  ) async {
    try {
      await _firestore.collection('payrollExports').add({
        'exportDate': Timestamp.now(),
        'filePath': filePath,
        'format': format.name,
        'entryCount': timeEntries.length,
        'guardIds': timeEntries.map((e) => e.guardId).toSet().toList(),
        'periodStart': timeEntries.isEmpty ? null : 
            Timestamp.fromDate(timeEntries.map((e) => e.checkInTime!).reduce((a, b) => a.isBefore(b) ? a : b)),
        'periodEnd': timeEntries.isEmpty ? null :
            Timestamp.fromDate(timeEntries.map((e) => e.checkOutTime!).reduce((a, b) => a.isAfter(b) ? a : b)),
      });
    } catch (e) {
      print('Failed to log payroll export: $e');
    }
  }

  /// Sanitize filename for file system compatibility
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(' ', '_')
        .toLowerCase();
  }

  /// Schedule automatic payroll export
  Future<void> scheduleAutomaticExport({
    required String guardId,
    required ExportSchedule schedule,
    PayrollFormat format = PayrollFormat.standard,
  }) async {
    try {
      await _firestore.collection('payrollSchedules').add({
        'guardId': guardId,
        'schedule': schedule.name,
        'format': format.name,
        'createdAt': Timestamp.now(),
        'enabled': true,
        'lastExport': null,
        'nextExport': _calculateNextExportDate(schedule),
      });
    } catch (e) {
      throw PayrollExportException(
        'Automatische export inplannen mislukt: ${e.toString()}',
        PayrollExportErrorType.scheduleSetupFailed,
      );
    }
  }

  /// Calculate next export date based on schedule
  DateTime _calculateNextExportDate(ExportSchedule schedule) {
    final now = DateTime.now();
    
    switch (schedule) {
      case ExportSchedule.weekly:
        return now.add(const Duration(days: 7));
      case ExportSchedule.biweekly:
        return now.add(const Duration(days: 14));
      case ExportSchedule.monthly:
        return DateTime(now.year, now.month + 1, 1);
      case ExportSchedule.quarterly:
        return DateTime(now.year, now.month + 3, 1);
    }
  }
}

// Supporting data models and enums

/// Payroll export formats for Dutch payroll systems
enum PayrollFormat {
  standard('Standaard CSV'),
  afas('AFAS OnLine'),
  exact('Exact Online'),
  nmbrs('Nmbrs');
  
  const PayrollFormat(this.displayName);
  final String displayName;
}

/// Employment types per Dutch labor law
enum EmploymentType {
  employee('Werknemer'),
  freelancer('Freelancer/ZZP'),
  intern('Stagiair'),
  temp('Uitzendkracht');
  
  const EmploymentType(this.dutchName);
  final String dutchName;
}

/// Export schedule options
enum ExportSchedule {
  weekly('Wekelijks'),
  biweekly('Tweewekelijks'),
  monthly('Maandelijks'),
  quarterly('Per kwartaal');
  
  const ExportSchedule(this.dutchName);
  final String dutchName;
}

/// Payroll entry for a single guard
class PayrollEntry {
  final String guardId;
  final String guardName;
  final String guardEmail;
  final EmploymentType employmentType;
  final double regularHours;
  final double overtimeHours;
  final double doubleOvertimeHours;
  final double weekendHours;
  final double nightHours;
  final double hourlyRate;
  final double basePay;
  final double overtimePay;
  final double doubleOvertimePay;
  final double weekendPay;
  final double nightPay;
  final double grossPay;
  final double holidayPay;
  final double pensionContribution;
  final double btw;
  final double netPay;
  final int totalShifts;
  final bool caoCompliant;
  final DateTime calculationDate;

  const PayrollEntry({
    required this.guardId,
    required this.guardName,
    required this.guardEmail,
    required this.employmentType,
    required this.regularHours,
    required this.overtimeHours,
    required this.doubleOvertimeHours,
    required this.weekendHours,
    required this.nightHours,
    required this.hourlyRate,
    required this.basePay,
    required this.overtimePay,
    required this.doubleOvertimePay,
    required this.weekendPay,
    required this.nightPay,
    required this.grossPay,
    required this.holidayPay,
    required this.pensionContribution,
    required this.btw,
    required this.netPay,
    required this.totalShifts,
    required this.caoCompliant,
    required this.calculationDate,
  });
}

/// Weekly hours breakdown
class WeeklyHours {
  final double regular;
  final double overtime;
  final double doubleOvertime;
  final double weekend;
  final double night;
  final double unpaidBreaks;

  const WeeklyHours({
    required this.regular,
    required this.overtime,
    required this.doubleOvertime,
    required this.weekend,
    required this.night,
    required this.unpaidBreaks,
  });
}

/// Guard information for payroll calculations
class GuardInfo {
  final String id;
  final String name;
  final String email;
  final double hourlyRate;
  final EmploymentType employmentType;
  final bool isFreelancer;

  const GuardInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.hourlyRate,
    required this.employmentType,
    required this.isFreelancer,
  });
}

/// Payroll export error types
enum PayrollExportErrorType {
  exportFailed,
  guardNotFound,
  dataFetchFailed,
  scheduleSetupFailed,
  invalidTimeEntries,
  calculationError,
}

/// Payroll export exception
class PayrollExportException implements Exception {
  final String message;
  final PayrollExportErrorType type;
  
  const PayrollExportException(this.message, this.type);
  
  @override
  String toString() => 'PayrollExportException: $message';
}