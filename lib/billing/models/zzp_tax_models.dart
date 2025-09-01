import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/utils/dutch_formatting.dart';

/// ZZP Tax Profile for maintaining user tax information
class ZZPTaxProfile extends Equatable {
  final String guardId;
  final bool isBTWRegistered;
  final String? btwNumber;
  final DateTime? btwRegistrationDate;
  final DateTime? lastBTWReporting;
  final bool hasProperDocumentation;
  final Map<String, double> annualDeductionLimits;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ZZPTaxProfile({
    required this.guardId,
    required this.isBTWRegistered,
    this.btwNumber,
    this.btwRegistrationDate,
    this.lastBTWReporting,
    required this.hasProperDocumentation,
    required this.annualDeductionLimits,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ZZPTaxProfile.createDefault(String guardId) {
    return ZZPTaxProfile(
      guardId: guardId,
      isBTWRegistered: false,
      hasProperDocumentation: false,
      annualDeductionLimits: {
        'security_equipment': 2500.0,
        'training_costs': 5000.0,
        'home_office': 2000.0,
        'transportation': 99999.0, // No limit on transportation
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory ZZPTaxProfile.fromFirestore(Map<String, dynamic> data) {
    return ZZPTaxProfile(
      guardId: data['guard_id'] as String,
      isBTWRegistered: data['is_btw_registered'] as bool? ?? false,
      btwNumber: data['btw_number'] as String?,
      btwRegistrationDate: data['btw_registration_date'] != null
          ? (data['btw_registration_date'] as Timestamp).toDate()
          : null,
      lastBTWReporting: data['last_btw_reporting'] != null
          ? (data['last_btw_reporting'] as Timestamp).toDate()
          : null,
      hasProperDocumentation: data['has_proper_documentation'] as bool? ?? false,
      annualDeductionLimits: Map<String, double>.from(
        data['annual_deduction_limits'] as Map? ?? {}
      ),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'guard_id': guardId,
      'is_btw_registered': isBTWRegistered,
      'btw_number': btwNumber,
      'btw_registration_date': btwRegistrationDate != null
          ? Timestamp.fromDate(btwRegistrationDate!)
          : null,
      'last_btw_reporting': lastBTWReporting != null
          ? Timestamp.fromDate(lastBTWReporting!)
          : null,
      'has_proper_documentation': hasProperDocumentation,
      'annual_deduction_limits': annualDeductionLimits,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
    guardId, isBTWRegistered, btwNumber, hasProperDocumentation,
    createdAt, updatedAt,
  ];
}

/// Comprehensive ZZP tax calculation result
class ZZPTaxCalculationResult extends Equatable {
  final String guardId;
  final ZZPCalculationPeriod period;
  final DateTime calculatedAt;
  final double grossIncome;
  final double annualProjectedIncome;
  final ZZPIncomeTaxCalculation incomeTaxCalculation;
  final ZZPBTWCalculation btwCalculation;
  final ZZPDeductionsBreakdown deductionsBreakdown;
  final ZZPNetIncomeCalculation netIncomeCalculation;
  final List<ZZPTaxOptimizationRecommendation> optimizationRecommendations;
  final ZZPComplianceStatus complianceStatus;
  final bool quarterlyReportingRequired;
  final ZZPRiskAssessment riskAssessment;

  const ZZPTaxCalculationResult({
    required this.guardId,
    required this.period,
    required this.calculatedAt,
    required this.grossIncome,
    required this.annualProjectedIncome,
    required this.incomeTaxCalculation,
    required this.btwCalculation,
    required this.deductionsBreakdown,
    required this.netIncomeCalculation,
    required this.optimizationRecommendations,
    required this.complianceStatus,
    required this.quarterlyReportingRequired,
    required this.riskAssessment,
  });

  String get dutchFormattedGrossIncome => DutchFormatting.formatCurrency(grossIncome);
  String get dutchFormattedNetIncome => netIncomeCalculation.dutchFormattedNet;
  String get dutchFormattedAnnualProjection => DutchFormatting.formatCurrency(annualProjectedIncome);

  Map<String, dynamic> toFirestore() {
    return {
      'guard_id': guardId,
      'period': period.name,
      'calculated_at': Timestamp.fromDate(calculatedAt),
      'gross_income': grossIncome,
      'annual_projected_income': annualProjectedIncome,
      'income_tax_calculation': incomeTaxCalculation.toFirestore(),
      'btw_calculation': btwCalculation.toFirestore(),
      'deductions_breakdown': deductionsBreakdown.toFirestore(),
      'net_income_calculation': netIncomeCalculation.toFirestore(),
      'optimization_recommendations': optimizationRecommendations
          .map((rec) => rec.toFirestore())
          .toList(),
      'compliance_status': complianceStatus.toFirestore(),
      'quarterly_reporting_required': quarterlyReportingRequired,
      'risk_assessment': riskAssessment.toFirestore(),
    };
  }

  @override
  List<Object?> get props => [
    guardId, period, calculatedAt, grossIncome, annualProjectedIncome,
    quarterlyReportingRequired,
  ];
}

/// Income tax calculation with progressive brackets
class ZZPIncomeTaxCalculation extends Equatable {
  final double grossIncome;
  final double taxableIncome;
  final double totalTaxBeforeDeductions;
  final double zelfstandigenaftrek;
  final double effectiveIncomeTax;
  final double effectiveRate;
  final List<ZZPTaxBracketCalculation> bracketBreakdown;
  final DateTime calculatedAt;

  const ZZPIncomeTaxCalculation({
    required this.grossIncome,
    required this.taxableIncome,
    required this.totalTaxBeforeDeductions,
    required this.zelfstandigenaftrek,
    required this.effectiveIncomeTax,
    required this.effectiveRate,
    required this.bracketBreakdown,
    required this.calculatedAt,
  });

  String get dutchFormattedTax => DutchFormatting.formatCurrency(effectiveIncomeTax);
  String get dutchFormattedDeduction => DutchFormatting.formatCurrency(zelfstandigenaftrek);
  String get dutchFormattedRate => '${(effectiveRate * 100).toStringAsFixed(1)}%';

  Map<String, dynamic> toFirestore() {
    return {
      'gross_income': grossIncome,
      'taxable_income': taxableIncome,
      'total_tax_before_deductions': totalTaxBeforeDeductions,
      'zelfstandigenaftrek': zelfstandigenaftrek,
      'effective_income_tax': effectiveIncomeTax,
      'effective_rate': effectiveRate,
      'bracket_breakdown': bracketBreakdown.map((b) => b.toFirestore()).toList(),
      'calculated_at': Timestamp.fromDate(calculatedAt),
    };
  }

  @override
  List<Object?> get props => [
    grossIncome, taxableIncome, effectiveIncomeTax, effectiveRate,
  ];
}

/// Tax bracket calculation details
class ZZPTaxBracketCalculation extends Equatable {
  final double minIncome;
  final double maxIncome;
  final double rate;
  final double taxableIncome;
  final double calculatedTax;

  const ZZPTaxBracketCalculation({
    required this.minIncome,
    required this.maxIncome,
    required this.rate,
    required this.taxableIncome,
    required this.calculatedTax,
  });

  String get dutchFormattedRange => 
      '${DutchFormatting.formatCurrency(minIncome)} - ${DutchFormatting.formatCurrency(maxIncome)}';
  String get dutchFormattedRate => '${(rate * 100).toStringAsFixed(2)}%';
  String get dutchFormattedTax => DutchFormatting.formatCurrency(calculatedTax);

  Map<String, dynamic> toFirestore() {
    return {
      'min_income': minIncome,
      'max_income': maxIncome,
      'rate': rate,
      'taxable_income': taxableIncome,
      'calculated_tax': calculatedTax,
    };
  }

  @override
  List<Object?> get props => [minIncome, maxIncome, rate, taxableIncome, calculatedTax];
}

/// BTW calculation with threshold management
class ZZPBTWCalculation extends Equatable {
  final double grossIncome;
  final double annualProjectedIncome;
  final double btwThreshold;
  final bool exceedsThreshold;
  final bool registrationRequired;
  final bool currentRegistrationStatus;
  final double applicableRate;
  final double btwAmount;
  final double quarterlyBTWDue;
  final double historicalBTWYTD;
  final DateTime nextReportingDeadline;
  final DateTime calculatedAt;

  const ZZPBTWCalculation({
    required this.grossIncome,
    required this.annualProjectedIncome,
    required this.btwThreshold,
    required this.exceedsThreshold,
    required this.registrationRequired,
    required this.currentRegistrationStatus,
    required this.applicableRate,
    required this.btwAmount,
    required this.quarterlyBTWDue,
    required this.historicalBTWYTD,
    required this.nextReportingDeadline,
    required this.calculatedAt,
  });

  String get dutchFormattedBTW => DutchFormatting.formatCurrency(btwAmount);
  String get dutchFormattedQuarterly => DutchFormatting.formatCurrency(quarterlyBTWDue);
  String get dutchFormattedThreshold => DutchFormatting.formatCurrency(btwThreshold);
  String get dutchFormattedRate => '${(applicableRate * 100).toStringAsFixed(0)}%';

  Map<String, dynamic> toFirestore() {
    return {
      'gross_income': grossIncome,
      'annual_projected_income': annualProjectedIncome,
      'btw_threshold': btwThreshold,
      'exceeds_threshold': exceedsThreshold,
      'registration_required': registrationRequired,
      'current_registration_status': currentRegistrationStatus,
      'applicable_rate': applicableRate,
      'btw_amount': btwAmount,
      'quarterly_btw_due': quarterlyBTWDue,
      'historical_btw_ytd': historicalBTWYTD,
      'next_reporting_deadline': Timestamp.fromDate(nextReportingDeadline),
      'calculated_at': Timestamp.fromDate(calculatedAt),
    };
  }

  @override
  List<Object?> get props => [
    grossIncome, btwAmount, exceedsThreshold, registrationRequired,
    nextReportingDeadline,
  ];
}

/// Deductions breakdown with validation
class ZZPDeductionsBreakdown extends Equatable {
  final Map<ZZPDeductionCategory, double> validatedDeductions;
  final Map<ZZPDeductionCategory, double> rejectedDeductions;
  final double totalValidatedAmount;
  final double totalRejectedAmount;
  final List<String> validationWarnings;
  final List<String> optimizationSuggestions;
  final DateTime calculatedAt;

  const ZZPDeductionsBreakdown({
    required this.validatedDeductions,
    required this.rejectedDeductions,
    required this.totalValidatedAmount,
    required this.totalRejectedAmount,
    required this.validationWarnings,
    required this.optimizationSuggestions,
    required this.calculatedAt,
  });

  String get dutchFormattedValidated => DutchFormatting.formatCurrency(totalValidatedAmount);
  String get dutchFormattedRejected => DutchFormatting.formatCurrency(totalRejectedAmount);

  Map<String, dynamic> toFirestore() {
    return {
      'validated_deductions': validatedDeductions.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'rejected_deductions': rejectedDeductions.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'total_validated_amount': totalValidatedAmount,
      'total_rejected_amount': totalRejectedAmount,
      'validation_warnings': validationWarnings,
      'optimization_suggestions': optimizationSuggestions,
      'calculated_at': Timestamp.fromDate(calculatedAt),
    };
  }

  @override
  List<Object?> get props => [
    totalValidatedAmount, totalRejectedAmount, validationWarnings,
  ];
}

/// Final net income calculation
class ZZPNetIncomeCalculation extends Equatable {
  final double grossIncome;
  final double totalTaxes;
  final double incomeTaxAmount;
  final double btwAmount;
  final double totalDeductions;
  final double netIncomeBeforeDeductions;
  final double finalNetIncome;
  final double effectiveTaxRate;
  final String dutchFormattedNet;
  final DateTime calculatedAt;

  const ZZPNetIncomeCalculation({
    required this.grossIncome,
    required this.totalTaxes,
    required this.incomeTaxAmount,
    required this.btwAmount,
    required this.totalDeductions,
    required this.netIncomeBeforeDeductions,
    required this.finalNetIncome,
    required this.effectiveTaxRate,
    required this.dutchFormattedNet,
    required this.calculatedAt,
  });

  String get dutchFormattedTaxes => DutchFormatting.formatCurrency(totalTaxes);
  String get dutchFormattedDeductions => DutchFormatting.formatCurrency(totalDeductions);
  String get dutchFormattedEffectiveRate => '${(effectiveTaxRate * 100).toStringAsFixed(1)}%';

  Map<String, dynamic> toFirestore() {
    return {
      'gross_income': grossIncome,
      'total_taxes': totalTaxes,
      'income_tax_amount': incomeTaxAmount,
      'btw_amount': btwAmount,
      'total_deductions': totalDeductions,
      'net_income_before_deductions': netIncomeBeforeDeductions,
      'final_net_income': finalNetIncome,
      'effective_tax_rate': effectiveTaxRate,
      'dutch_formatted_net': dutchFormattedNet,
      'calculated_at': Timestamp.fromDate(calculatedAt),
    };
  }

  @override
  List<Object?> get props => [
    grossIncome, totalTaxes, finalNetIncome, effectiveTaxRate,
  ];
}

/// Tax optimization recommendation
class ZZPTaxOptimizationRecommendation extends Equatable {
  final ZZPOptimizationCategory category;
  final String title;
  final String description;
  final double potentialSavings;
  final ZZPOptimizationPriority priority;
  final bool actionRequired;
  final DateTime? deadline;
  final List<String> implementationSteps;

  const ZZPTaxOptimizationRecommendation({
    required this.category,
    required this.title,
    required this.description,
    required this.potentialSavings,
    required this.priority,
    required this.actionRequired,
    this.deadline,
    required this.implementationSteps,
  });

  String get dutchFormattedSavings => DutchFormatting.formatCurrency(potentialSavings);

  Map<String, dynamic> toFirestore() {
    return {
      'category': category.name,
      'title': title,
      'description': description,
      'potential_savings': potentialSavings,
      'priority': priority.name,
      'action_required': actionRequired,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'implementation_steps': implementationSteps,
    };
  }

  @override
  List<Object?> get props => [
    category, title, potentialSavings, priority, actionRequired, deadline,
  ];
}

/// Compliance status tracking
class ZZPComplianceStatus extends Equatable {
  final ZZPComplianceLevel level;
  final DateTime lastAssessed;
  final List<String> complianceIssues;
  final List<String> warnings;
  final DateTime nextReviewDate;
  final double overallScore;

  const ZZPComplianceStatus({
    required this.level,
    required this.lastAssessed,
    required this.complianceIssues,
    required this.warnings,
    required this.nextReviewDate,
    required this.overallScore,
  });

  String get dutchComplianceLevel {
    switch (level) {
      case ZZPComplianceLevel.compliant:
        return 'Compliant';
      case ZZPComplianceLevel.warning:
        return 'Waarschuwing';
      case ZZPComplianceLevel.nonCompliant:
        return 'Niet Compliant';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'level': level.name,
      'last_assessed': Timestamp.fromDate(lastAssessed),
      'compliance_issues': complianceIssues,
      'warnings': warnings,
      'next_review_date': Timestamp.fromDate(nextReviewDate),
      'overall_score': overallScore,
    };
  }

  @override
  List<Object?> get props => [
    level, lastAssessed, complianceIssues, warnings, overallScore,
  ];
}

/// Risk assessment for ZZP tax situation
class ZZPRiskAssessment extends Equatable {
  final String guardId;
  final double totalRiskScore;
  final ZZPRiskLevel riskLevel;
  final Map<String, double> riskFactors;
  final List<String> recommendedActions;
  final DateTime nextAssessmentDate;
  final DateTime assessedAt;

  const ZZPRiskAssessment({
    required this.guardId,
    required this.totalRiskScore,
    required this.riskLevel,
    required this.riskFactors,
    required this.recommendedActions,
    required this.nextAssessmentDate,
    required this.assessedAt,
  });

  String get dutchRiskLevel {
    switch (riskLevel) {
      case ZZPRiskLevel.low:
        return 'Laag Risico';
      case ZZPRiskLevel.medium:
        return 'Gemiddeld Risico';
      case ZZPRiskLevel.high:
        return 'Hoog Risico';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'guard_id': guardId,
      'total_risk_score': totalRiskScore,
      'risk_level': riskLevel.name,
      'risk_factors': riskFactors,
      'recommended_actions': recommendedActions,
      'next_assessment_date': Timestamp.fromDate(nextAssessmentDate),
      'assessed_at': Timestamp.fromDate(assessedAt),
    };
  }

  @override
  List<Object?> get props => [
    guardId, totalRiskScore, riskLevel, nextAssessmentDate, assessedAt,
  ];
}

// Enums from the main service file
enum ZZPCalculationPeriod {
  weekly,
  monthly,
  quarterly,
  annually,
}

enum ZZPDeductionCategory {
  securityEquipment,
  professionalTraining,
  transportation,
  homeOffice,
  businessExpenses,
  professionalInsurance,
  marketingCosts,
}

enum ZZPOptimizationCategory {
  btwManagement,
  deductionOptimization,
  incomeSmoothing,
  timingOptimization,
}

enum ZZPOptimizationPriority {
  low,
  medium,
  high,
  urgent,
}

enum ZZPComplianceLevel {
  compliant,
  warning,
  nonCompliant,
}

enum ZZPRiskLevel {
  low,
  medium,
  high,
}