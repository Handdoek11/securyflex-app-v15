import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/belastingdienst_models.dart';
import '../../shared/utils/dutch_formatting.dart';

/// ZZP (Zelfstandige Zonder Personeel) Tax Service
/// Handles tax obligations for freelance security guards on the platform
class ZZPTaxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ZZP tax brackets for 2024
  static const Map<String, Map<String, dynamic>> incomeTaxBrackets = {
    'bracket_1': {'min': 0, 'max': 37149, 'rate': 0.3693}, // 36.93%
    'bracket_2': {'min': 37150, 'max': 75518, 'rate': 0.3693}, // 36.93% 
    'bracket_3': {'min': 75519, 'max': double.infinity, 'rate': 0.495}, // 49.5%
  };
  
  // ZZP deductions
  static const double zelfstandigenaftrek2024 = 6070; // €6,070 for 2024
  static const double startersaftrek = 2123; // Additional €2,123 for first 3 years
  static const double mkbWinstvrijstelling = 0.14; // 14% profit exemption
  
  /// Calculate annual ZZP tax obligation
  Future<BelastingdienstAnnualReturn> calculateZZPAnnualTax({
    required String guardId,
    required int taxYear,
    required double totalIncome,
    required double businessExpenses,
    required bool isStartup, // First 3 years of business
    required int businessStartYear,
  }) async {
    
    // Calculate deductions
    final zelfstandigenaftrekAmount = _calculateZelfstandigenaftrek(
      totalIncome: totalIncome,
      isStartup: isStartup,
      businessStartYear: businessStartYear,
      taxYear: taxYear,
    );
    
    final mkbDeduction = _calculateMKBWinstvrijstelling(totalIncome - businessExpenses);
    
    final totalDeductions = businessExpenses + zelfstandigenaftrekAmount + mkbDeduction;
    final taxableIncome = (totalIncome - totalDeductions).clamp(0.0, double.infinity);
    
    // Calculate income tax
    final incomeTaxOwed = _calculateIncomeTax(taxableIncome);
    
    // Get quarterly breakdown
    final quarterlyBreakdown = await _getQuarterlyIncomeBreakdown(guardId, taxYear);
    
    // Get professional expenses breakdown
    final professionalExpenses = await _getProfessionalExpenses(guardId, taxYear);
    
    return BelastingdienstAnnualReturn(
      guardId: guardId,
      taxYear: taxYear,
      bsn: await _getEncryptedBSN(guardId), // Encrypted BSN
      totalAnnualIncome: totalIncome,
      totalDeductions: totalDeductions,
      taxableIncome: taxableIncome,
      incomeTaxOwed: incomeTaxOwed,
      zelfstandigenaftrek: zelfstandigenaftrekAmount,
      quarterlyBreakdown: quarterlyBreakdown,
      professionalExpenses: professionalExpenses,
      otherIncome: 0.0, // Would include other sources if applicable
      submissionDate: DateTime.now(),
    );
  }
  
  /// Validate ZZP status according to DBA (Deregulering Beoordeling Arbeidsrelaties)
  Future<Map<String, dynamic>> validateZZPStatus({
    required String guardId,
    required String companyId,
  }) async {
    final validationResults = <String, dynamic>{};
    
    // Get guard's work patterns
    final workHistory = await _getGuardWorkHistory(guardId);
    
    // DBA Criteria 1: Risk bearing (risico dragen)
    final riskBearingScore = _assessRiskBearing(workHistory);
    validationResults['risk_bearing'] = riskBearingScore;
    
    // DBA Criteria 2: Decision making authority (zeggenschap)
    final decisionMakingScore = _assessDecisionMaking(workHistory);
    validationResults['decision_making'] = decisionMakingScore;
    
    // DBA Criteria 3: Personal work performance (persoonlijke werkzaamheden)
    final personalWorkScore = _assessPersonalWork(workHistory, guardId);
    validationResults['personal_work'] = personalWorkScore;
    
    // Calculate overall ZZP validity
    final overallScore = (riskBearingScore + decisionMakingScore + personalWorkScore) / 3;
    validationResults['overall_score'] = overallScore;
    validationResults['is_valid_zzp'] = overallScore >= 0.7; // 70% threshold
    
    // Risk assessment
    validationResults['compliance_risk'] = _assessZZPComplianceRisk(overallScore, workHistory);
    
    // Recommendations
    validationResults['recommendations'] = _generateZZPRecommendations(overallScore, workHistory);
    
    // Log validation
    await _logZZPValidation(guardId, companyId, validationResults);
    
    return validationResults;
  }
  
  /// Calculate minimum wage compliance for ZZP
  Future<Map<String, dynamic>> checkMinimumWageCompliance({
    required String guardId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    
    // Get current minimum wage (2024: €12.83/hour for 21+)
    const minimumWagePerHour = 12.83;
    
    // Get guard's work hours and earnings
    final workData = await _getGuardWorkData(guardId, periodStart, periodEnd);
    final totalHours = workData['total_hours'] as double;
    final totalEarnings = workData['total_earnings'] as double;
    
    final effectiveHourlyRate = totalHours > 0 ? totalEarnings / totalHours : 0.0;
    final minimumEarningsRequired = totalHours * minimumWagePerHour;
    
    final isCompliant = effectiveHourlyRate >= minimumWagePerHour;
    final shortfall = isCompliant ? 0.0 : minimumEarningsRequired - totalEarnings;
    
    return {
      'is_compliant': isCompliant,
      'effective_hourly_rate': effectiveHourlyRate,
      'minimum_wage_required': minimumWagePerHour,
      'total_hours': totalHours,
      'total_earnings': totalEarnings,
      'minimum_earnings_required': minimumEarningsRequired,
      'shortfall': shortfall,
      'compliance_percentage': (effectiveHourlyRate / minimumWagePerHour * 100).clamp(0, 100),
    };
  }
  
  /// Calculate vakantiegeld (holiday pay) obligations
  Future<Map<String, double>> calculateVakantiegeld({
    required String guardId,
    required int year,
  }) async {
    
    // Vakantiegeld is 8.33% of annual earnings for ZZP
    const vakantiegeldPercentage = 0.0833;
    
    final annualEarnings = await _getAnnualEarnings(guardId, year);
    final vakantiegeldAmount = annualEarnings * vakantiegeldPercentage;
    
    // Check if already paid out
    final paidOut = await _getVakantiegeldPaidOut(guardId, year);
    final remainingOwed = vakantiegeldAmount - paidOut;
    
    return {
      'annual_earnings': annualEarnings,
      'vakantiegeld_rate': vakantiegeldPercentage,
      'vakantiegeld_total': vakantiegeldAmount,
      'already_paid': paidOut,
      'remaining_owed': remainingOwed,
    };
  }
  
  /// Generate tax advice for ZZP guards
  Future<Map<String, dynamic>> generateZZPTaxAdvice({
    required String guardId,
    required double projectedIncome,
  }) async {
    
    final advice = <String, dynamic>{};
    
    // Tax planning recommendations
    advice['tax_planning'] = _generateTaxPlanningAdvice(projectedIncome);
    
    // Deduction optimization
    advice['deduction_optimization'] = _generateDeductionAdvice(projectedIncome);
    
    // Quarterly payment recommendations
    advice['quarterly_payments'] = _calculateQuarterlyPaymentAdvice(projectedIncome);
    
    // Business expense tracking recommendations
    advice['expense_tracking'] = _getExpenseTrackingAdvice();
    
    // Pension planning for ZZP
    advice['pension_advice'] = _getPensionAdvice(projectedIncome);
    
    return advice;
  }
  
  // Private helper methods
  
  double _calculateZelfstandigenaftrek({
    required double totalIncome,
    required bool isStartup,
    required int businessStartYear,
    required int taxYear,
  }) {
    double aftrek = zelfstandigenaftrek2024;
    
    // Add starter's deduction if applicable (first 3 years)
    if (isStartup && (taxYear - businessStartYear) < 3) {
      aftrek += startersaftrek;
    }
    
    // Reduce if income is above certain threshold
    if (totalIncome > 60000) {
      final reduction = (totalIncome - 60000) * 0.05;
      aftrek = (aftrek - reduction).clamp(0.0, aftrek);
    }
    
    return aftrek;
  }
  
  double _calculateMKBWinstvrijstelling(double profit) {
    return profit > 0 ? profit * mkbWinstvrijstelling : 0.0;
  }
  
  double _calculateIncomeTax(double taxableIncome) {
    double tax = 0.0;
    double remainingIncome = taxableIncome;
    
    for (final bracket in incomeTaxBrackets.values) {
      final min = bracket['min'] as double;
      final max = bracket['max'] as double;
      final rate = bracket['rate'] as double;
      
      if (remainingIncome <= 0) break;
      
      final bracketIncome = (remainingIncome + min > max) 
          ? max - min 
          : remainingIncome;
      
      tax += bracketIncome * rate;
      remainingIncome -= bracketIncome;
    }
    
    return tax;
  }
  
  Future<List<Map<String, dynamic>>> _getQuarterlyIncomeBreakdown(String guardId, int year) async {
    final quarters = <Map<String, dynamic>>[];
    
    for (int quarter = 1; quarter <= 4; quarter++) {
      final start = DateTime(year, (quarter - 1) * 3 + 1, 1);
      final end = DateTime(year, quarter * 3 + 1, 0);
      
      final earnings = await _getGuardEarnings(guardId, start, end);
      quarters.add({
        'quarter': quarter,
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
        'gross_income': earnings['gross'] ?? 0.0,
        'net_income': earnings['net'] ?? 0.0,
        'hours_worked': earnings['hours'] ?? 0.0,
      });
    }
    
    return quarters;
  }
  
  Future<Map<String, dynamic>> _getProfessionalExpenses(String guardId, int year) async {
    final expenses = await _firestore
        .collection('professional_expenses')
        .where('guard_id', isEqualTo: guardId)
        .where('year', isEqualTo: year)
        .get();
    
    final expensesByCategory = <String, double>{};
    double totalExpenses = 0.0;
    
    for (final doc in expenses.docs) {
      final data = doc.data();
      final category = data['category'] as String;
      final amount = (data['amount'] as num).toDouble();
      
      expensesByCategory[category] = (expensesByCategory[category] ?? 0.0) + amount;
      totalExpenses += amount;
    }
    
    return {
      'total_expenses': totalExpenses,
      'by_category': expensesByCategory,
      'deductible_percentage': 1.0, // 100% deductible for business expenses
    };
  }
  
  Future<String> _getEncryptedBSN(String guardId) async {
    final userDoc = await _firestore.collection('users').doc(guardId).get();
    return userDoc.data()?['encrypted_bsn'] ?? '';
  }
  
  // ZZP Validation Methods
  
  Future<Map<String, dynamic>> _getGuardWorkHistory(String guardId) async {
    final history = await _firestore
        .collection('shifts')
        .where('guard_id', isEqualTo: guardId)
        .orderBy('start_time', descending: true)
        .limit(100)
        .get();
    
    return {
      'total_shifts': history.docs.length,
      'shifts': history.docs.map((doc) => doc.data()).toList(),
    };
  }
  
  double _assessRiskBearing(Map<String, dynamic> workHistory) {
    // Assess if guard bears financial risk
    // Higher score = more ZZP-like
    double score = 0.5; // Base score
    
    final shifts = workHistory['shifts'] as List;
    
    // Check for equipment ownership
    int ownEquipmentCount = 0;
    // Check for liability insurance
    int hasInsuranceCount = 0;
    // Check for variable income
    int variableIncomeCount = 0;
    
    for (final shift in shifts) {
      if (shift['equipment_provided_by_guard'] == true) ownEquipmentCount++;
      if (shift['guard_has_insurance'] == true) hasInsuranceCount++;
      if (shift['payment_type'] == 'per_project') variableIncomeCount++;
    }
    
    score += (ownEquipmentCount / shifts.length) * 0.3;
    score += (hasInsuranceCount / shifts.length) * 0.2;
    score += (variableIncomeCount / shifts.length) * 0.2;
    
    return score.clamp(0.0, 1.0);
  }
  
  double _assessDecisionMaking(Map<String, dynamic> workHistory) {
    // Assess level of autonomy and decision-making
    double score = 0.5;
    
    final shifts = workHistory['shifts'] as List;
    
    int autonomousDecisionCount = 0;
    int flexibleScheduleCount = 0;
    int clientInteractionCount = 0;
    
    for (final shift in shifts) {
      if (shift['autonomous_decisions'] == true) autonomousDecisionCount++;
      if (shift['flexible_schedule'] == true) flexibleScheduleCount++;
      if (shift['direct_client_interaction'] == true) clientInteractionCount++;
    }
    
    score += (autonomousDecisionCount / shifts.length) * 0.3;
    score += (flexibleScheduleCount / shifts.length) * 0.3;
    score += (clientInteractionCount / shifts.length) * 0.2;
    
    return score.clamp(0.0, 1.0);
  }
  
  double _assessPersonalWork(Map<String, dynamic> workHistory, String guardId) {
    // Assess if work is done personally vs delegation
    // ZZP should do work personally
    double score = 1.0; // Start high, reduce if delegation found
    
    final shifts = workHistory['shifts'] as List;
    
    int delegatedWorkCount = 0;
    int substituteUsedCount = 0;
    
    for (final shift in shifts) {
      if (shift['work_delegated'] == true) delegatedWorkCount++;
      if (shift['substitute_used'] == true) substituteUsedCount++;
    }
    
    score -= (delegatedWorkCount / shifts.length) * 0.5;
    score -= (substituteUsedCount / shifts.length) * 0.3;
    
    return score.clamp(0.0, 1.0);
  }
  
  String _assessZZPComplianceRisk(double overallScore, Map<String, dynamic> workHistory) {
    if (overallScore >= 0.8) return 'Low Risk - Clear ZZP status';
    if (overallScore >= 0.6) return 'Medium Risk - Review recommended';
    return 'High Risk - Potential employee classification';
  }
  
  List<String> _generateZZPRecommendations(double overallScore, Map<String, dynamic> workHistory) {
    final recommendations = <String>[];
    
    if (overallScore < 0.7) {
      recommendations.add('Verhoog autonomie bij werkzaamheden');
      recommendations.add('Zorg voor eigen materiaal en verzekeringen');
      recommendations.add('Diversifieer klantenbestand');
      recommendations.add('Documenteer bedrijfsrisico\'s');
    }
    
    recommendations.add('Houd financiële administratie bij');
    recommendations.add('Overweeg pensioenopbouw');
    recommendations.add('Plan kwartaal betalingen');
    
    return recommendations;
  }
  
  Future<void> _logZZPValidation(String guardId, String companyId, Map<String, dynamic> results) async {
    await _firestore.collection('zzp_validations').add({
      'guard_id': guardId,
      'company_id': companyId,
      'validation_results': results,
      'validated_at': FieldValue.serverTimestamp(),
      'validator_version': '1.0.0',
    });
  }
  
  Future<Map<String, dynamic>> _getGuardWorkData(String guardId, DateTime start, DateTime end) async {
    final shifts = await _firestore
        .collection('shifts')
        .where('guard_id', isEqualTo: guardId)
        .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('start_time', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    
    double totalHours = 0.0;
    double totalEarnings = 0.0;
    
    for (final doc in shifts.docs) {
      final data = doc.data();
      totalHours += (data['duration_hours'] as num?)?.toDouble() ?? 0.0;
      totalEarnings += (data['payment_amount'] as num?)?.toDouble() ?? 0.0;
    }
    
    return {
      'total_hours': totalHours,
      'total_earnings': totalEarnings,
    };
  }
  
  Future<double> _getAnnualEarnings(String guardId, int year) async {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31);
    
    final workData = await _getGuardWorkData(guardId, start, end);
    return workData['total_earnings'] as double;
  }
  
  Future<double> _getVakantiegeldPaidOut(String guardId, int year) async {
    final payments = await _firestore
        .collection('vakantiegeld_payments')
        .where('guard_id', isEqualTo: guardId)
        .where('year', isEqualTo: year)
        .get();
    
    double totalPaid = 0.0;
    for (final doc in payments.docs) {
      totalPaid += (doc.data()['amount'] as num).toDouble();
    }
    
    return totalPaid;
  }
  
  Future<Map<String, dynamic>> _getGuardEarnings(String guardId, DateTime start, DateTime end) async {
    final workData = await _getGuardWorkData(guardId, start, end);
    return {
      'gross': workData['total_earnings'],
      'net': workData['total_earnings']! * 0.7, // Rough estimate after taxes
      'hours': workData['total_hours'],
    };
  }
  
  Map<String, dynamic> _generateTaxPlanningAdvice(double projectedIncome) {
    final estimatedTax = _calculateIncomeTax(projectedIncome - zelfstandigenaftrek2024);
    
    return {
      'projected_income': projectedIncome,
      'estimated_tax': estimatedTax,
      'quarterly_payment_suggestion': estimatedTax / 4,
      'advice': 'Plan kwartaalbetalingen om boetes te voorkomen',
    };
  }
  
  Map<String, dynamic> _generateDeductionAdvice(double projectedIncome) {
    return {
      'zelfstandigenaftrek': zelfstandigenaftrek2024,
      'mkb_winstvrijstelling': projectedIncome * mkbWinstvrijstelling,
      'deductible_expenses': [
        'Werkkleding en uitrusting',
        'Telefoon- en internetkosten',
        'Reiskosten',
        'Verzekeringen',
        'Administratiekosten',
        'Cursussen en certificaten',
      ],
    };
  }
  
  Map<String, dynamic> _calculateQuarterlyPaymentAdvice(double projectedIncome) {
    final annualTax = _calculateIncomeTax(projectedIncome - zelfstandigenaftrek2024);
    final quarterlyAmount = annualTax / 4;
    
    return {
      'annual_tax_estimate': annualTax,
      'quarterly_amount': quarterlyAmount,
      'payment_dates': [
        'Kwartaal 1: 31 mei',
        'Kwartaal 2: 31 augustus', 
        'Kwartaal 3: 30 november',
        'Kwartaal 4: 28 februari (volgend jaar)',
      ],
    };
  }
  
  List<String> _getExpenseTrackingAdvice() {
    return [
      'Bewaar alle bonnetjes en facturen',
      'Gebruik aparte bankrekening voor bedrijf',
      'Registreer kilometers voor reiskosten',
      'Documenteer zakelijke telefoongesprekken',
      'Houd bij welk percentage thuiskantoor zakelijk is',
    ];
  }
  
  Map<String, dynamic> _getPensionAdvice(double projectedIncome) {
    final recommendedPensionContribution = projectedIncome * 0.15; // 15% recommendation
    
    return {
      'recommended_contribution': recommendedPensionContribution,
      'tax_benefit': recommendedPensionContribution * 0.37, // Rough tax benefit
      'advice': 'Als ZZP\'er bouw je geen AOW op via werkgever - zorg voor eigen pensioen',
      'options': [
        'Lijfrente via bank of verzekeraar',
        'Pensioensparen met fiscaal voordeel',
        'FOR (Fiscaal Oldedagsreserve)',
      ],
    };
  }
}