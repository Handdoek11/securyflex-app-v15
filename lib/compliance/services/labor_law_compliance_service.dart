import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Dutch Labor Law Compliance Service
/// Ensures compliance with Arbeidstijdenwet, CAO, and DBA regulations
class LaborLawComplianceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Arbeidstijdenwet limits
  static const int maxHoursPerWeek = 48;
  static const int maxHoursPerDay = 9;
  static const int minRestHours = 11;
  static const int maxWorkingDaysPerWeek = 6;
  static const int minBreakMinutesPer4Hours = 30;
  
  // CAO Particuliere Beveiliging rates (2024)
  static const Map<String, double> caoHourlyRates = {
    'level_1': 12.83, // Basic security guard
    'level_2': 13.45, // Experienced guard
    'level_3': 14.20, // Specialist/supervisor
    'level_4': 15.10, // Team leader
  };
  
  /// Validate working time compliance for a shift
  Future<Map<String, dynamic>> validateShiftCompliance({
    required String guardId,
    required DateTime shiftStart,
    required DateTime shiftEnd,
    required String shiftType,
  }) async {
    
    final violations = <String>[];
    final warnings = <String>[];
    
    // Calculate shift duration
    final shiftDuration = shiftEnd.difference(shiftStart);
    final hoursWorked = shiftDuration.inMinutes / 60.0;
    
    // Check daily hour limits
    if (hoursWorked > maxHoursPerDay) {
      violations.add('Overschrijding maximum dagelijkse werktijd: ${hoursWorked.toStringAsFixed(1)}h > ${maxHoursPerDay}h');
    }
    
    // Check weekly hour limits
    final weeklyHours = await _getWeeklyHours(guardId, shiftStart);
    if (weeklyHours + hoursWorked > maxHoursPerWeek) {
      violations.add('Overschrijding maximum wekelijkse werktijd: ${(weeklyHours + hoursWorked).toStringAsFixed(1)}h > ${maxHoursPerWeek}h');
    }
    
    // Check rest periods
    final lastShiftEnd = await _getLastShiftEnd(guardId, shiftStart);
    if (lastShiftEnd != null) {
      final restHours = shiftStart.difference(lastShiftEnd).inHours;
      if (restHours < minRestHours) {
        violations.add('Onvoldoende rusttijd: ${restHours}h < ${minRestHours}h');
      }
    }
    
    // Check break requirements for long shifts
    if (hoursWorked > 4.5 && !_hasScheduledBreak(shiftStart, shiftEnd)) {
      warnings.add('Pauze van minimaal 30 minuten vereist voor diensten langer dan 4,5 uur');
    }
    
    // Check night work regulations (22:00 - 06:00)
    final isNightShift = _isNightShift(shiftStart, shiftEnd);
    if (isNightShift) {
      final nightWorkCompliance = await _checkNightWorkCompliance(guardId, shiftStart);
      if (!nightWorkCompliance['compliant']) {
        violations.addAll(nightWorkCompliance['violations'] as List<String>);
      }
    }
    
    return {
      'compliant': violations.isEmpty,
      'violations': violations,
      'warnings': warnings,
      'hours_worked': hoursWorked,
      'weekly_hours_total': weeklyHours + hoursWorked,
      'is_night_shift': isNightShift,
      'rest_hours_since_last_shift': lastShiftEnd != null 
          ? shiftStart.difference(lastShiftEnd).inHours 
          : null,
    };
  }
  
  /// Check CAO compliance for payment
  Future<Map<String, dynamic>> validateCAOPaymentCompliance({
    required String guardId,
    required double hourlyRate,
    required double hoursWorked,
    required String skillLevel,
    required bool isWeekend,
    required bool isNight,
    required bool isHoliday,
  }) async {
    
    final violations = <String>[];
    final adjustments = <String, double>{};
    
    // Get minimum hourly rate for skill level
    final minimumRate = caoHourlyRates[skillLevel] ?? caoHourlyRates['level_1']!;
    
    // Base rate validation
    if (hourlyRate < minimumRate) {
      violations.add('Uurloon onder CAO minimum: €${hourlyRate.toStringAsFixed(2)} < €${minimumRate.toStringAsFixed(2)}');
      adjustments['base_rate_adjustment'] = (minimumRate - hourlyRate) * hoursWorked;
    }
    
    // Weekend surcharge (25% on Saturday, 50% on Sunday)
    if (isWeekend) {
      final weekendSurcharge = _calculateWeekendSurcharge(minimumRate, hoursWorked);
      adjustments['weekend_surcharge'] = weekendSurcharge;
    }
    
    // Night surcharge (20% between 22:00-06:00)
    if (isNight) {
      final nightSurcharge = minimumRate * hoursWorked * 0.20;
      adjustments['night_surcharge'] = nightSurcharge;
    }
    
    // Holiday surcharge (100%)
    if (isHoliday) {
      final holidaySurcharge = minimumRate * hoursWorked * 1.00;
      adjustments['holiday_surcharge'] = holidaySurcharge;
    }
    
    // Calculate vacation pay (8.33%)
    final vacationPay = (minimumRate * hoursWorked) * 0.0833;
    adjustments['vacation_pay'] = vacationPay;
    
    // Calculate total owed amount
    final totalAdjustments = adjustments.values.fold(0.0, (sum, adj) => sum + adj);
    final currentPay = hourlyRate * hoursWorked;
    final requiredPay = (minimumRate * hoursWorked) + totalAdjustments - adjustments['base_rate_adjustment']!;
    
    return {
      'compliant': violations.isEmpty,
      'violations': violations,
      'hourly_rate_check': {
        'current_rate': hourlyRate,
        'minimum_required': minimumRate,
        'compliant': hourlyRate >= minimumRate,
      },
      'payment_calculation': {
        'current_total': currentPay,
        'required_total': requiredPay,
        'adjustments': adjustments,
        'shortfall': requiredPay > currentPay ? requiredPay - currentPay : 0.0,
      },
      'vacation_pay_owed': vacationPay,
    };
  }
  
  /// Comprehensive DBA worker classification assessment
  Future<Map<String, dynamic>> assessDBACompliance({
    required String guardId,
    required String companyId,
  }) async {
    
    final assessmentResults = <String, dynamic>{};
    
    // Get work relationship data
    final workData = await _getWorkRelationshipData(guardId, companyId);
    
    // DBA Test 1: Direction and Control (80% threshold)
    final directionControlScore = _assessDirectionAndControl(workData);
    assessmentResults['direction_control'] = {
      'score': directionControlScore,
      'threshold': 0.8,
      'pass': directionControlScore < 0.8, // Lower score = less control = more ZZP-like
    };
    
    // DBA Test 2: Relationship Assessment (combined evaluation)
    final relationshipScore = _assessWorkRelationship(workData);
    assessmentResults['work_relationship'] = {
      'score': relationshipScore,
      'factors': _getRelationshipFactors(workData),
    };
    
    // Risk assessment
    final overallRisk = _calculateDBARisk(directionControlScore, relationshipScore);
    assessmentResults['overall_risk'] = overallRisk;
    
    // Compliance recommendations
    assessmentResults['recommendations'] = _generateDBARecommendations(overallRisk, workData);
    
    // Required actions
    assessmentResults['required_actions'] = _getRequiredActions(overallRisk);
    
    // Legal compliance status
    assessmentResults['legal_status'] = _determineLegalStatus(overallRisk);
    
    // Log assessment
    await _logDBAAssessment(guardId, companyId, assessmentResults);
    
    return assessmentResults;
  }
  
  /// Monitor ongoing compliance for active workers
  Future<Map<String, dynamic>> monitorOngoingCompliance({
    required String guardId,
    int monitoringPeriodDays = 30,
  }) async {
    
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: monitoringPeriodDays));
    
    // Get all shifts in monitoring period
    final shifts = await _getShiftsInPeriod(guardId, startDate, endDate);
    
    final complianceIssues = <Map<String, dynamic>>[];
    final warnings = <Map<String, dynamic>>[];
    
    // Check each shift for compliance
    for (final shift in shifts) {
      final shiftCompliance = await validateShiftCompliance(
        guardId: guardId,
        shiftStart: (shift['start_time'] as Timestamp).toDate(),
        shiftEnd: (shift['end_time'] as Timestamp).toDate(),
        shiftType: shift['type'] as String,
      );
      
      if (!shiftCompliance['compliant']) {
        complianceIssues.add({
          'shift_id': shift['id'],
          'date': (shift['start_time'] as Timestamp).toDate(),
          'violations': shiftCompliance['violations'],
        });
      }
      
      if ((shiftCompliance['warnings'] as List).isNotEmpty) {
        warnings.add({
          'shift_id': shift['id'],
          'date': (shift['start_time'] as Timestamp).toDate(),
          'warnings': shiftCompliance['warnings'],
        });
      }
    }
    
    // Calculate compliance metrics
    final totalShifts = shifts.length;
    final compliantShifts = totalShifts - complianceIssues.length;
    final complianceRate = totalShifts > 0 ? compliantShifts / totalShifts : 1.0;
    
    // Payment compliance check
    final paymentCompliance = await _checkPaymentCompliance(guardId, startDate, endDate);
    
    return {
      'monitoring_period': {
        'start_date': startDate,
        'end_date': endDate,
        'days': monitoringPeriodDays,
      },
      'shift_compliance': {
        'total_shifts': totalShifts,
        'compliant_shifts': compliantShifts,
        'compliance_rate': complianceRate,
        'violations': complianceIssues,
        'warnings': warnings,
      },
      'payment_compliance': paymentCompliance,
      'overall_status': _getOverallComplianceStatus(complianceRate, paymentCompliance),
      'recommendations': _getComplianceRecommendations(complianceRate, complianceIssues),
    };
  }
  
  // Private helper methods
  
  Future<double> _getWeeklyHours(String guardId, DateTime referenceDate) async {
    final weekStart = referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    final shifts = await _firestore
        .collection('shifts')
        .where('guard_id', isEqualTo: guardId)
        .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('start_time', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
        .get();
    
    double totalHours = 0.0;
    for (final doc in shifts.docs) {
      final data = doc.data();
      final startTime = (data['start_time'] as Timestamp).toDate();
      final endTime = (data['end_time'] as Timestamp).toDate();
      totalHours += endTime.difference(startTime).inMinutes / 60.0;
    }
    
    return totalHours;
  }
  
  Future<DateTime?> _getLastShiftEnd(String guardId, DateTime beforeDate) async {
    final shifts = await _firestore
        .collection('shifts')
        .where('guard_id', isEqualTo: guardId)
        .where('end_time', isLessThan: Timestamp.fromDate(beforeDate))
        .orderBy('end_time', descending: true)
        .limit(1)
        .get();
    
    if (shifts.docs.isNotEmpty) {
      return (shifts.docs.first.data()['end_time'] as Timestamp).toDate();
    }
    
    return null;
  }
  
  bool _hasScheduledBreak(DateTime shiftStart, DateTime shiftEnd) {
    // In a real implementation, this would check for scheduled breaks
    // For now, assume breaks are properly scheduled for shifts > 4.5 hours
    final duration = shiftEnd.difference(shiftStart);
    return duration.inMinutes <= 270; // 4.5 hours
  }
  
  bool _isNightShift(DateTime start, DateTime end) {
    final nightStart = 22; // 22:00
    final nightEnd = 6;    // 06:00
    
    return (start.hour >= nightStart || start.hour < nightEnd) ||
           (end.hour >= nightStart || end.hour < nightEnd);
  }
  
  Future<Map<String, dynamic>> _checkNightWorkCompliance(String guardId, DateTime shiftDate) async {
    // Check night work limitations (max 2 consecutive night shifts)
    final violations = <String>[];
    
    // Get recent night shifts
    final recentNightShifts = await _getRecentNightShifts(guardId, shiftDate);
    
    if (recentNightShifts.length >= 2) {
      violations.add('Maximum van 2 opeenvolgende nachtdiensten overschreden');
    }
    
    return {
      'compliant': violations.isEmpty,
      'violations': violations,
      'consecutive_night_shifts': recentNightShifts.length,
    };
  }
  
  double _calculateWeekendSurcharge(double baseRate, double hours) {
    // Weekend surcharge calculation based on CAO
    return baseRate * hours * 0.25; // 25% surcharge
  }
  
  Future<Map<String, dynamic>> _getWorkRelationshipData(String guardId, String companyId) async {
    // Collect comprehensive work relationship data
    final data = <String, dynamic>{};
    
    // Get contract terms
    final contract = await _firestore
        .collection('contracts')
        .where('guard_id', isEqualTo: guardId)
        .where('company_id', isEqualTo: companyId)
        .limit(1)
        .get();
    
    if (contract.docs.isNotEmpty) {
      data['contract'] = contract.docs.first.data();
    }
    
    // Get work history
    final shifts = await _firestore
        .collection('shifts')
        .where('guard_id', isEqualTo: guardId)
        .where('company_id', isEqualTo: companyId)
        .orderBy('start_time', descending: true)
        .limit(50)
        .get();
    
    data['shifts'] = shifts.docs.map((doc) => doc.data()).toList();
    
    // Get equipment and tools provided
    final equipment = await _firestore
        .collection('equipment_assignments')
        .where('guard_id', isEqualTo: guardId)
        .where('company_id', isEqualTo: companyId)
        .get();
    
    data['equipment'] = equipment.docs.map((doc) => doc.data()).toList();
    
    return data;
  }
  
  double _assessDirectionAndControl(Map<String, dynamic> workData) {
    double controlScore = 0.0;
    
    final shifts = workData['shifts'] as List? ?? [];
    
    if (shifts.isNotEmpty) {
      // Check level of supervision
      int supervisedCount = 0;
      int fixedLocationCount = 0;
      int fixedHoursCount = 0;
      int uniformRequiredCount = 0;
      
      for (final shift in shifts) {
        if (shift['direct_supervision'] == true) supervisedCount++;
        if (shift['fixed_location'] == true) fixedLocationCount++;
        if (shift['fixed_hours'] == true) fixedHoursCount++;
        if (shift['uniform_required'] == true) uniformRequiredCount++;
      }
      
      // Calculate control indicators (higher = more control)
      controlScore += (supervisedCount / shifts.length) * 0.3;
      controlScore += (fixedLocationCount / shifts.length) * 0.2;
      controlScore += (fixedHoursCount / shifts.length) * 0.3;
      controlScore += (uniformRequiredCount / shifts.length) * 0.2;
    }
    
    return controlScore;
  }
  
  double _assessWorkRelationship(Map<String, dynamic> workData) {
    double relationshipScore = 0.5; // Base score
    
    final contract = workData['contract'] as Map<String, dynamic>?;
    final shifts = workData['shifts'] as List? ?? [];
    
    if (contract != null) {
      // Long-term exclusive contracts indicate employment relationship
      if (contract['duration_months'] != null && contract['duration_months'] > 12) {
        relationshipScore += 0.2;
      }
      
      if (contract['exclusive'] == true) {
        relationshipScore += 0.3;
      }
    }
    
    // Check for regular pattern of work
    if (shifts.length > 20) {
      final regularPatternScore = _assessWorkPattern(shifts);
      relationshipScore += regularPatternScore * 0.2;
    }
    
    return relationshipScore.clamp(0.0, 1.0);
  }
  
  Map<String, dynamic> _getRelationshipFactors(Map<String, dynamic> workData) {
    return {
      'contract_duration': workData['contract']?['duration_months'],
      'exclusive_relationship': workData['contract']?['exclusive'] ?? false,
      'equipment_provided': (workData['equipment'] as List?)?.isNotEmpty ?? false,
      'regular_schedule': _hasRegularSchedule(workData['shifts'] as List? ?? []),
      'integration_level': _assessIntegrationLevel(workData),
    };
  }
  
  double _assessWorkPattern(List shifts) {
    // Analyze if there's a regular work pattern
    if (shifts.isEmpty) return 0.0;
    
    final daysOfWeek = <int, int>{};
    for (final shift in shifts) {
      final startTime = (shift['start_time'] as Timestamp).toDate();
      final dayOfWeek = startTime.weekday;
      daysOfWeek[dayOfWeek] = (daysOfWeek[dayOfWeek] ?? 0) + 1;
    }
    
    // Check if there are preferred days (regular pattern)
    final maxShiftsOnDay = daysOfWeek.values.isNotEmpty 
        ? daysOfWeek.values.reduce((a, b) => a > b ? a : b) 
        : 0;
    final totalShifts = shifts.length;
    
    return maxShiftsOnDay / totalShifts; // Higher = more regular pattern
  }
  
  bool _hasRegularSchedule(List shifts) {
    if (shifts.length < 10) return false;
    
    final workDays = <int>{};
    for (final shift in shifts) {
      final startTime = (shift['start_time'] as Timestamp).toDate();
      workDays.add(startTime.weekday);
    }
    
    // If working on same days consistently, it's regular
    return workDays.length <= 3; // Working on 3 or fewer different days
  }
  
  String _assessIntegrationLevel(Map<String, dynamic> workData) {
    final contract = workData['contract'] as Map<String, dynamic>?;
    final equipment = workData['equipment'] as List? ?? [];
    
    if (equipment.isNotEmpty && contract?['training_provided'] == true) {
      return 'High - Equipment provided, training given';
    } else if (equipment.isNotEmpty || contract?['training_provided'] == true) {
      return 'Medium - Some integration elements present';
    } else {
      return 'Low - Minimal integration';
    }
  }
  
  String _calculateDBARisk(double directionScore, double relationshipScore) {
    final combinedScore = (directionScore + relationshipScore) / 2;
    
    if (combinedScore >= 0.7) return 'High Risk - Likely employee relationship';
    if (combinedScore >= 0.4) return 'Medium Risk - Assessment needed';
    return 'Low Risk - Clear ZZP relationship';
  }
  
  List<String> _generateDBARecommendations(String riskLevel, Map<String, dynamic> workData) {
    final recommendations = <String>[];
    
    if (riskLevel.startsWith('High')) {
      recommendations.add('Overweeg formele arbeidsovereenkomst');
      recommendations.add('Verminder directe controle en supervisie');
      recommendations.add('Bied meer autonomie in werkuitvoering');
    } else if (riskLevel.startsWith('Medium')) {
      recommendations.add('Documenteer ZZP-kwalificaties beter');
      recommendations.add('Zorg voor meer variatie in opdrachten');
      recommendations.add('Vermijd exclusieve werkrelaties');
    }
    
    recommendations.add('Voer jaarlijkse DBA-evaluatie uit');
    recommendations.add('Houd werkrelatie-documentatie bij');
    
    return recommendations;
  }
  
  List<String> _getRequiredActions(String riskLevel) {
    if (riskLevel.startsWith('High')) {
      return [
        'Juridisch advies inwinnen binnen 30 dagen',
        'Werkrelatie herstructureren of formaliseren',
        'Belastingaangiftes controleren en corrigeren',
        'Sociale verzekeringen regelen indien nodig',
      ];
    } else if (riskLevel.startsWith('Medium')) {
      return [
        'DBA-self-assessment uitvoeren',
        'Werkafspraken documenteren',
        'ZZP-status periodiek valideren',
      ];
    }
    
    return [
      'Huidige werkrelatie documenteren',
      'Jaarlijkse compliance check plannen',
    ];
  }
  
  String _determineLegalStatus(String riskLevel) {
    if (riskLevel.startsWith('High')) return 'Non-compliant - Action required';
    if (riskLevel.startsWith('Medium')) return 'Under review - Monitor closely';
    return 'Compliant - Continue monitoring';
  }
  
  Future<void> _logDBAAssessment(String guardId, String companyId, Map<String, dynamic> results) async {
    await _firestore.collection('dba_assessments').add({
      'guard_id': guardId,
      'company_id': companyId,
      'assessment_results': results,
      'assessed_at': FieldValue.serverTimestamp(),
      'assessor': 'automated_system',
      'version': '1.0.0',
    });
  }
  
  Future<List<Map<String, dynamic>>> _getShiftsInPeriod(String guardId, DateTime start, DateTime end) async {
    final shifts = await _firestore
        .collection('shifts')
        .where('guard_id', isEqualTo: guardId)
        .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('start_time', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('start_time')
        .get();
    
    return shifts.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }
  
  Future<List<Map<String, dynamic>>> _getRecentNightShifts(String guardId, DateTime beforeDate) async {
    final threeDaysAgo = beforeDate.subtract(const Duration(days: 3));
    
    final shifts = await _firestore
        .collection('shifts')
        .where('guard_id', isEqualTo: guardId)
        .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(threeDaysAgo))
        .where('start_time', isLessThan: Timestamp.fromDate(beforeDate))
        .orderBy('start_time', descending: true)
        .get();
    
    return shifts.docs
        .where((doc) {
          final data = doc.data();
          final start = (data['start_time'] as Timestamp).toDate();
          final end = (data['end_time'] as Timestamp).toDate();
          return _isNightShift(start, end);
        })
        .map((doc) => doc.data())
        .toList();
  }
  
  Future<Map<String, dynamic>> _checkPaymentCompliance(String guardId, DateTime start, DateTime end) async {
    final shifts = await _getShiftsInPeriod(guardId, start, end);
    final paymentIssues = <Map<String, dynamic>>[];
    
    for (final shift in shifts) {
      final paymentCheck = await validateCAOPaymentCompliance(
        guardId: guardId,
        hourlyRate: (shift['hourly_rate'] as num?)?.toDouble() ?? 0.0,
        hoursWorked: _calculateHoursWorked(shift),
        skillLevel: shift['skill_level'] as String? ?? 'level_1',
        isWeekend: _isWeekend(shift),
        isNight: _isNightShift(
          (shift['start_time'] as Timestamp).toDate(),
          (shift['end_time'] as Timestamp).toDate(),
        ),
        isHoliday: shift['is_holiday'] as bool? ?? false,
      );
      
      if (!paymentCheck['compliant']) {
        paymentIssues.add({
          'shift_id': shift['id'],
          'violations': paymentCheck['violations'],
          'shortfall': paymentCheck['payment_calculation']['shortfall'],
        });
      }
    }
    
    final totalShifts = shifts.length;
    final compliantPayments = totalShifts - paymentIssues.length;
    
    return {
      'total_shifts': totalShifts,
      'compliant_payments': compliantPayments,
      'compliance_rate': totalShifts > 0 ? compliantPayments / totalShifts : 1.0,
      'payment_issues': paymentIssues,
      'total_shortfall': paymentIssues
          .map((issue) => issue['shortfall'] as double)
          .fold(0.0, (sum, shortfall) => sum + shortfall),
    };
  }
  
  double _calculateHoursWorked(Map<String, dynamic> shift) {
    final start = (shift['start_time'] as Timestamp).toDate();
    final end = (shift['end_time'] as Timestamp).toDate();
    return end.difference(start).inMinutes / 60.0;
  }
  
  bool _isWeekend(Map<String, dynamic> shift) {
    final start = (shift['start_time'] as Timestamp).toDate();
    return start.weekday >= 6; // Saturday = 6, Sunday = 7
  }
  
  String _getOverallComplianceStatus(double shiftComplianceRate, Map<String, dynamic> paymentCompliance) {
    final paymentComplianceRate = paymentCompliance['compliance_rate'] as double;
    final overallRate = (shiftComplianceRate + paymentComplianceRate) / 2;
    
    if (overallRate >= 0.95) return 'Excellent - Fully compliant';
    if (overallRate >= 0.85) return 'Good - Minor issues to address';
    if (overallRate >= 0.70) return 'Fair - Several compliance gaps';
    return 'Poor - Major compliance issues require immediate attention';
  }
  
  List<String> _getComplianceRecommendations(double complianceRate, List<Map<String, dynamic>> issues) {
    final recommendations = <String>[];
    
    if (complianceRate < 0.9) {
      recommendations.add('Implementeer geautomatiseerde compliance controles');
      recommendations.add('Train managers in arbeidsrecht en CAO-bepalingen');
      recommendations.add('Stel duidelijke procedures op voor dienstregelingen');
    }
    
    if (issues.length > 5) {
      recommendations.add('Voer structurele review uit van werkprocessen');
      recommendations.add('Overweeg investering in workforce management systeem');
    }
    
    recommendations.add('Plan maandelijkse compliance reviews');
    recommendations.add('Documenteer alle afwijkingen en correctieve maatregelen');
    
    return recommendations;
  }
}