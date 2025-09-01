import 'dart:async';
import '../models/compliance_status.dart';
import '../models/enhanced_dashboard_data.dart';

/// Service for monitoring CAO arbeidsrecht compliance in real-time
class ComplianceMonitoringService {
  final StreamController<ComplianceStatus> _complianceController = 
      StreamController<ComplianceStatus>.broadcast();

  /// Stream for real-time compliance updates
  Stream<ComplianceStatus> get complianceStream => _complianceController.stream;

  /// Monitor compliance status with Dutch arbeidsrecht rules
  Future<ComplianceStatus> getCurrentComplianceStatus(List<EnhancedShiftData> shifts) async {
    // Simulate compliance check delay
    await Future.delayed(const Duration(milliseconds: 200));

    final violations = <ComplianceViolation>[];
    final warnings = <ComplianceViolation>[];

    // Check weekly hour limits (CAO: max 48 hours per week)
    final weeklyHours = _calculateWeeklyHours(shifts);
    if (weeklyHours > 48) {
      violations.add(ComplianceViolation(
        id: 'weekly_hours_${DateTime.now().millisecondsSinceEpoch}',
        type: ComplianceViolationType.excessiveHours,
        dutchDescription: 'Overschrijding maximum werkuren per week (${weeklyHours.toStringAsFixed(1)} > 48 uur)',
        dutchRecommendation: 'Plan rustperioden of annuleer extra diensten',
        severity: ComplianceSeverity.high,
        detectedAt: DateTime.now(),
        additionalData: {'weeklyHours': weeklyHours, 'maxHours': 48},
      ));
    } else if (weeklyHours > 40) {
      warnings.add(ComplianceViolation(
        id: 'overtime_${DateTime.now().millisecondsSinceEpoch}',
        type: ComplianceViolationType.unauthorizedOvertime,
        dutchDescription: 'Overwerk gedetecteerd (${weeklyHours.toStringAsFixed(1)} > 40 uur)',
        dutchRecommendation: 'Monitor overwerk tarieven (150% na 40u, 200% na 48u)',
        severity: ComplianceSeverity.medium,
        detectedAt: DateTime.now(),
        additionalData: {'weeklyHours': weeklyHours, 'overtimeHours': weeklyHours - 40},
      ));
    }

    // Check rest periods (CAO: minimum 11 hours between shifts)
    for (int i = 0; i < shifts.length - 1; i++) {
      final currentShift = shifts[i];
      final nextShift = shifts[i + 1];
      
      final restHours = nextShift.startTime.difference(currentShift.endTime).inHours;
      if (restHours < 11) {
        violations.add(ComplianceViolation(
          id: 'rest_${currentShift.id}_${nextShift.id}',
          type: ComplianceViolationType.insufficientRest,
          dutchDescription: 'Onvoldoende rusttijd tussen diensten ($restHours < 11 uur)',
          dutchRecommendation: 'Herplan diensten om 11 uur rust te garanderen',
          severity: ComplianceSeverity.high,
          detectedAt: DateTime.now(),
          additionalData: {'restHours': restHours, 'requiredHours': 11},
        ));
      }
    }

    // Check night work limits (max 10 hours, min 8 hours rest)
    for (final shift in shifts) {
      if (_isNightShift(shift)) {
        if (shift.durationHours > 10) {
          violations.add(ComplianceViolation(
            id: 'night_work_${shift.id}',
            type: ComplianceViolationType.excessiveHours,
            dutchDescription: 'Nachtdienst te lang (${shift.durationHours.toStringAsFixed(1)} > 10 uur)',
            dutchRecommendation: 'Verkort nachtdienst tot maximaal 10 uur',
            severity: ComplianceSeverity.high,
            detectedAt: DateTime.now(),
            additionalData: {'shiftHours': shift.durationHours, 'maxNightHours': 10},
          ));
        }
      }
    }

    // Check minimum wage compliance
    for (final shift in shifts) {
      const dutchMinimumWage = 12.0; // €12.00/hour for security work (2024)
      if (shift.hourlyRate < dutchMinimumWage) {
        violations.add(ComplianceViolation(
          id: 'min_wage_${shift.id}',
          type: ComplianceViolationType.excessiveHours, // Using existing enum value
          dutchDescription: 'Uurloon onder minimum (€${shift.hourlyRate.toStringAsFixed(2)} < €$dutchMinimumWage)',
          dutchRecommendation: 'Verhoog uurloon naar minimaal €$dutchMinimumWage',
          severity: ComplianceSeverity.critical,
          detectedAt: DateTime.now(),
          additionalData: {'currentRate': shift.hourlyRate, 'minimumWage': dutchMinimumWage},
        ));
      }
    }

    final status = ComplianceStatus(
      hasViolations: violations.isNotEmpty,
      violations: [...violations, ...warnings],
      weeklyHours: weeklyHours,
      maxWeeklyHours: 48.0,
      restPeriod: const Duration(hours: 11),
      minRestPeriod: const Duration(hours: 11),
      wpbrValid: true, // This would be checked elsewhere
      healthCertificateValid: true, // This would be checked elsewhere
      lastUpdated: DateTime.now(),
    );

    _complianceController.add(status);
    return status;
  }

  /// Start real-time compliance monitoring
  void startRealTimeMonitoring(Stream<List<EnhancedShiftData>> shiftsStream) {
    shiftsStream.listen((shifts) async {
      final status = await getCurrentComplianceStatus(shifts);
      _complianceController.add(status);
    });
  }

  /// Calculate total weekly hours
  double _calculateWeeklyHours(List<EnhancedShiftData> shifts) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return shifts
        .where((shift) => shift.startTime.isAfter(weekStart))
        .where((shift) => shift.status == ShiftStatus.completed || shift.status == ShiftStatus.inProgress)
        .fold(0.0, (sum, shift) => sum + shift.durationHours);
  }

  /// Check if shift is during night hours (22:00 - 06:00)
  bool _isNightShift(EnhancedShiftData shift) {
    final startHour = shift.startTime.hour;
    final endHour = shift.endTime.hour;
    
    // Night shift: starts after 22:00 or ends before 06:00
    return startHour >= 22 || endHour <= 6 || 
           (startHour < 6 && endHour > startHour); // Overnight shifts
  }


  void dispose() {
    _complianceController.close();
  }
}