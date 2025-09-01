import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/utils/dutch_formatting.dart';
import 'zzp_tax_models.dart';

/// Comprehensive ZZP compliance assessment result
class ZZPComplianceAssessment extends Equatable {
  final String guardId;
  final int assessmentYear;
  final DateTime assessmentDate;
  final ZZPComplianceLevel overallComplianceStatus;
  final double overallComplianceScore;
  final ZZPBTWComplianceResult btwCompliance;
  final ZZPDeductionsComplianceResult deductionsCompliance;
  final ZZPDocumentationComplianceResult documentationCompliance;
  final ZZPReportingComplianceResult reportingCompliance;
  final ZZPRiskAssessment riskAssessment;
  final List<ZZPComplianceRecommendation> recommendations;
  final DateTime nextReviewDate;

  const ZZPComplianceAssessment({
    required this.guardId,
    required this.assessmentYear,
    required this.assessmentDate,
    required this.overallComplianceStatus,
    required this.overallComplianceScore,
    required this.btwCompliance,
    required this.deductionsCompliance,
    required this.documentationCompliance,
    required this.reportingCompliance,
    required this.riskAssessment,
    required this.recommendations,
    required this.nextReviewDate,
  });

  String get dutchFormattedScore => '${overallComplianceScore.toStringAsFixed(1)}%';
  String get dutchFormattedAssessmentDate => DutchFormatting.formatDate(assessmentDate);
  String get dutchFormattedNextReview => DutchFormatting.formatDate(nextReviewDate);

  int get urgentRecommendationsCount => recommendations
      .where((r) => r.priority == ZZPCompliancePriority.urgent)
      .length;

  int get highPriorityRecommendationsCount => recommendations
      .where((r) => r.priority == ZZPCompliancePriority.high)
      .length;

  Map<String, dynamic> toFirestore() {
    return {
      'guard_id': guardId,
      'assessment_year': assessmentYear,
      'assessment_date': Timestamp.fromDate(assessmentDate),
      'overall_compliance_status': overallComplianceStatus.name,
      'overall_compliance_score': overallComplianceScore,
      'btw_compliance': btwCompliance.toFirestore(),
      'deductions_compliance': deductionsCompliance.toFirestore(),
      'documentation_compliance': documentationCompliance.toFirestore(),
      'reporting_compliance': reportingCompliance.toFirestore(),
      'risk_assessment': riskAssessment.toFirestore(),
      'recommendations': recommendations.map((r) => r.toFirestore()).toList(),
      'next_review_date': Timestamp.fromDate(nextReviewDate),
    };
  }

  @override
  List<Object?> get props => [
    guardId, assessmentYear, assessmentDate, overallComplianceStatus,
    overallComplianceScore, nextReviewDate,
  ];
}

/// BTW compliance assessment result
class ZZPBTWComplianceResult extends Equatable {
  final bool registrationRequired;
  final bool currentlyRegistered;
  final DateTime? lastReportingDate;
  final ZZPComplianceLevel complianceLevel;
  final List<String> complianceIssues;
  final List<String> warnings;
  final DateTime nextReportingDeadline;
  final double annualIncomeForBTW;

  const ZZPBTWComplianceResult({
    required this.registrationRequired,
    required this.currentlyRegistered,
    this.lastReportingDate,
    required this.complianceLevel,
    required this.complianceIssues,
    required this.warnings,
    required this.nextReportingDeadline,
    required this.annualIncomeForBTW,
  });

  String get dutchFormattedIncome => DutchFormatting.formatCurrency(annualIncomeForBTW);
  String get dutchFormattedDeadline => DutchFormatting.formatDate(nextReportingDeadline);
  String? get dutchFormattedLastReporting => 
      lastReportingDate != null ? DutchFormatting.formatDate(lastReportingDate!) : null;

  bool get isCompliant => complianceLevel == ZZPComplianceLevel.compliant;
  bool get hasIssues => complianceIssues.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  Map<String, dynamic> toFirestore() {
    return {
      'registration_required': registrationRequired,
      'currently_registered': currentlyRegistered,
      'last_reporting_date': lastReportingDate != null 
          ? Timestamp.fromDate(lastReportingDate!)
          : null,
      'compliance_level': complianceLevel.name,
      'compliance_issues': complianceIssues,
      'warnings': warnings,
      'next_reporting_deadline': Timestamp.fromDate(nextReportingDeadline),
      'annual_income_for_btw': annualIncomeForBTW,
    };
  }

  @override
  List<Object?> get props => [
    registrationRequired, currentlyRegistered, complianceLevel,
    nextReportingDeadline, annualIncomeForBTW,
  ];
}

/// Deductions compliance assessment result
class ZZPDeductionsComplianceResult extends Equatable {
  final double totalDeductions;
  final double deductionToIncomeRatio;
  final ZZPComplianceLevel complianceLevel;
  final List<String> complianceIssues;
  final List<String> warnings;
  final Map<ZZPDeductionCategory, double> categoryBreakdown;
  final bool exceedsLimits;

  const ZZPDeductionsComplianceResult({
    required this.totalDeductions,
    required this.deductionToIncomeRatio,
    required this.complianceLevel,
    required this.complianceIssues,
    required this.warnings,
    required this.categoryBreakdown,
    required this.exceedsLimits,
  });

  String get dutchFormattedDeductions => DutchFormatting.formatCurrency(totalDeductions);
  String get dutchFormattedRatio => '${(deductionToIncomeRatio * 100).toStringAsFixed(1)}%';

  bool get isCompliant => complianceLevel == ZZPComplianceLevel.compliant;
  bool get hasIssues => complianceIssues.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  Map<String, dynamic> toFirestore() {
    return {
      'total_deductions': totalDeductions,
      'deduction_to_income_ratio': deductionToIncomeRatio,
      'compliance_level': complianceLevel.name,
      'compliance_issues': complianceIssues,
      'warnings': warnings,
      'category_breakdown': categoryBreakdown.map((k, v) => MapEntry(k.name, v)),
      'exceeds_limits': exceedsLimits,
    };
  }

  @override
  List<Object?> get props => [
    totalDeductions, deductionToIncomeRatio, complianceLevel, exceedsLimits,
  ];
}

/// Documentation compliance assessment result
class ZZPDocumentationComplianceResult extends Equatable {
  final ZZPComplianceLevel complianceLevel;
  final List<String> complianceIssues;
  final List<String> warnings;
  final DocumentationAssessment invoiceDocumentation;
  final DocumentationAssessment deductionDocumentation;
  final DocumentationAssessment contractDocumentation;
  final double overallDocumentationScore;

  const ZZPDocumentationComplianceResult({
    required this.complianceLevel,
    required this.complianceIssues,
    required this.warnings,
    required this.invoiceDocumentation,
    required this.deductionDocumentation,
    required this.contractDocumentation,
    required this.overallDocumentationScore,
  });

  String get dutchFormattedScore => '${overallDocumentationScore.toStringAsFixed(1)}%';
  bool get isCompliant => complianceLevel == ZZPComplianceLevel.compliant;
  bool get hasIssues => complianceIssues.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  Map<String, dynamic> toFirestore() {
    return {
      'compliance_level': complianceLevel.name,
      'compliance_issues': complianceIssues,
      'warnings': warnings,
      'invoice_documentation': invoiceDocumentation.toFirestore(),
      'deduction_documentation': deductionDocumentation.toFirestore(),
      'contract_documentation': contractDocumentation.toFirestore(),
      'overall_documentation_score': overallDocumentationScore,
    };
  }

  @override
  List<Object?> get props => [
    complianceLevel, overallDocumentationScore,
    invoiceDocumentation, deductionDocumentation, contractDocumentation,
  ];
}

/// Reporting compliance assessment result
class ZZPReportingComplianceResult extends Equatable {
  final ZZPComplianceLevel complianceLevel;
  final List<String> complianceIssues;
  final List<String> warnings;
  final bool annualFilingStatus;
  final List<QuarterlyFilingStatus> quarterlyFilingStatus;
  final List<ReportingPenalty> reportingPenalties;

  const ZZPReportingComplianceResult({
    required this.complianceLevel,
    required this.complianceIssues,
    required this.warnings,
    required this.annualFilingStatus,
    required this.quarterlyFilingStatus,
    required this.reportingPenalties,
  });

  bool get isCompliant => complianceLevel == ZZPComplianceLevel.compliant;
  bool get hasIssues => complianceIssues.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasOutstandingFilings => quarterlyFilingStatus.any((q) => !q.filed);
  bool get hasPenalties => reportingPenalties.isNotEmpty;

  Map<String, dynamic> toFirestore() {
    return {
      'compliance_level': complianceLevel.name,
      'compliance_issues': complianceIssues,
      'warnings': warnings,
      'annual_filing_status': annualFilingStatus,
      'quarterly_filing_status': quarterlyFilingStatus.map((q) => q.toFirestore()).toList(),
      'reporting_penalties': reportingPenalties.map((p) => p.toFirestore()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    complianceLevel, annualFilingStatus, quarterlyFilingStatus, reportingPenalties,
  ];
}

/// Documentation assessment for specific document type
class DocumentationAssessment extends Equatable {
  final bool isAdequate;
  final List<String> issues;
  final List<String> warnings;
  final double completenessScore;

  const DocumentationAssessment({
    required this.isAdequate,
    required this.issues,
    required this.warnings,
    required this.completenessScore,
  });

  String get dutchFormattedScore => '${completenessScore.toStringAsFixed(1)}%';

  Map<String, dynamic> toFirestore() {
    return {
      'is_adequate': isAdequate,
      'issues': issues,
      'warnings': warnings,
      'completeness_score': completenessScore,
    };
  }

  @override
  List<Object?> get props => [isAdequate, completenessScore, issues, warnings];
}

/// Quarterly filing status tracking
class QuarterlyFilingStatus extends Equatable {
  final int quarter;
  final bool filed;
  final DateTime dueDate;
  final DateTime? filedDate;
  final bool isLate;

  const QuarterlyFilingStatus({
    required this.quarter,
    required this.filed,
    required this.dueDate,
    this.filedDate,
    this.isLate = false,
  });

  String get dutchQuarterName => 'Q$quarter';
  String get dutchFormattedDueDate => DutchFormatting.formatDate(dueDate);
  String? get dutchFormattedFiledDate => 
      filedDate != null ? DutchFormatting.formatDate(filedDate!) : null;

  bool get isOverdue => !filed && DateTime.now().isAfter(dueDate);

  Map<String, dynamic> toFirestore() {
    return {
      'quarter': quarter,
      'filed': filed,
      'due_date': Timestamp.fromDate(dueDate),
      'filed_date': filedDate != null ? Timestamp.fromDate(filedDate!) : null,
      'is_late': isLate,
    };
  }

  @override
  List<Object?> get props => [quarter, filed, dueDate, filedDate, isLate];
}

/// Reporting penalty tracking
class ReportingPenalty extends Equatable {
  final String penaltyId;
  final String description;
  final double amount;
  final DateTime assessedDate;
  final bool isPaid;
  final DateTime? paidDate;

  const ReportingPenalty({
    required this.penaltyId,
    required this.description,
    required this.amount,
    required this.assessedDate,
    required this.isPaid,
    this.paidDate,
  });

  String get dutchFormattedAmount => DutchFormatting.formatCurrency(amount);
  String get dutchFormattedAssessedDate => DutchFormatting.formatDate(assessedDate);
  String? get dutchFormattedPaidDate => 
      paidDate != null ? DutchFormatting.formatDate(paidDate!) : null;

  Map<String, dynamic> toFirestore() {
    return {
      'penalty_id': penaltyId,
      'description': description,
      'amount': amount,
      'assessed_date': Timestamp.fromDate(assessedDate),
      'is_paid': isPaid,
      'paid_date': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
    };
  }

  @override
  List<Object?> get props => [penaltyId, amount, assessedDate, isPaid, paidDate];
}

/// Compliance recommendation with actionable items
class ZZPComplianceRecommendation extends Equatable {
  final ZZPComplianceCategory category;
  final ZZPCompliancePriority priority;
  final String title;
  final String description;
  final List<String> actionItems;
  final DateTime deadline;
  final Duration estimatedTimeToComplete;
  final bool legalRequirement;

  const ZZPComplianceRecommendation({
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    required this.actionItems,
    required this.deadline,
    required this.estimatedTimeToComplete,
    required this.legalRequirement,
  });

  String get dutchFormattedDeadline => DutchFormatting.formatDate(deadline);
  String get dutchFormattedEstimatedTime => 
      '${estimatedTimeToComplete.inHours} uren';

  int get daysUntilDeadline => deadline.difference(DateTime.now()).inDays;
  bool get isOverdue => DateTime.now().isAfter(deadline);
  bool get isUrgent => daysUntilDeadline <= 7;

  Map<String, dynamic> toFirestore() {
    return {
      'category': category.name,
      'priority': priority.name,
      'title': title,
      'description': description,
      'action_items': actionItems,
      'deadline': Timestamp.fromDate(deadline),
      'estimated_time_hours': estimatedTimeToComplete.inHours,
      'legal_requirement': legalRequirement,
    };
  }

  @override
  List<Object?> get props => [
    category, priority, title, deadline, legalRequirement,
  ];
}

/// Compliance monitoring alert
class ZZPComplianceAlert extends Equatable {
  final String alertId;
  final String guardId;
  final ZZPAlertType alertType;
  final ZZPAlertSeverity severity;
  final String title;
  final String message;
  final Map<String, dynamic> alertData;
  final DateTime triggeredAt;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  const ZZPComplianceAlert({
    required this.alertId,
    required this.guardId,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    required this.alertData,
    required this.triggeredAt,
    required this.isResolved,
    this.resolvedAt,
    this.resolutionNotes,
  });

  String get dutchFormattedTriggeredAt => DutchFormatting.formatDateTime(triggeredAt);
  String? get dutchFormattedResolvedAt => 
      resolvedAt != null ? DutchFormatting.formatDateTime(resolvedAt!) : null;

  Duration get ageOfAlert => DateTime.now().difference(triggeredAt);
  int get daysOpen => ageOfAlert.inDays;

  @override
  List<Object?> get props => [
    alertId, guardId, alertType, severity, triggeredAt, isResolved,
  ];
}

/// Compliance monitoring dashboard data
class ZZPComplianceDashboard extends Equatable {
  final String guardId;
  final DateTime generatedAt;
  final ZZPComplianceLevel currentComplianceLevel;
  final double currentComplianceScore;
  final List<ZZPComplianceAlert> activeAlerts;
  final List<ZZPComplianceRecommendation> pendingRecommendations;
  final Map<ZZPComplianceCategory, ZZPComplianceLevel> categoryStatus;
  final List<ZZPComplianceMetric> metrics;
  final DateTime nextAssessmentDue;

  const ZZPComplianceDashboard({
    required this.guardId,
    required this.generatedAt,
    required this.currentComplianceLevel,
    required this.currentComplianceScore,
    required this.activeAlerts,
    required this.pendingRecommendations,
    required this.categoryStatus,
    required this.metrics,
    required this.nextAssessmentDue,
  });

  String get dutchFormattedScore => '${currentComplianceScore.toStringAsFixed(1)}%';
  String get dutchFormattedNextAssessment => DutchFormatting.formatDate(nextAssessmentDue);

  int get criticalAlertsCount => activeAlerts
      .where((alert) => alert.severity == ZZPAlertSeverity.critical)
      .length;

  int get urgentRecommendationsCount => pendingRecommendations
      .where((rec) => rec.priority == ZZPCompliancePriority.urgent)
      .length;

  @override
  List<Object?> get props => [
    guardId, generatedAt, currentComplianceLevel, currentComplianceScore,
    nextAssessmentDue,
  ];
}

/// Compliance metric for tracking
class ZZPComplianceMetric extends Equatable {
  final String metricName;
  final double currentValue;
  final double targetValue;
  final String unit;
  final ZZPMetricTrend trend;
  final DateTime lastUpdated;

  const ZZPComplianceMetric({
    required this.metricName,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.trend,
    required this.lastUpdated,
  });

  double get progressPercentage => 
      targetValue > 0 ? (currentValue / targetValue * 100).clamp(0, 100) : 0.0;

  String get dutchFormattedProgress => '${progressPercentage.toStringAsFixed(0)}%';
  String get dutchFormattedLastUpdated => DutchFormatting.formatDate(lastUpdated);

  bool get isOnTarget => currentValue >= targetValue;
  bool get needsAttention => progressPercentage < 80.0;

  @override
  List<Object?> get props => [
    metricName, currentValue, targetValue, trend, lastUpdated,
  ];
}

// Enums for compliance system
enum ZZPComplianceCategory {
  btw('BTW'),
  deductions('Aftrekposten'),
  documentation('Documentatie'),
  reporting('Aangifte'),
  riskManagement('Risicobeheer'),
  planning('Planning');

  const ZZPComplianceCategory(this.dutchName);
  final String dutchName;
}

enum ZZPCompliancePriority {
  low('Laag'),
  medium('Gemiddeld'),
  high('Hoog'),
  urgent('Urgent');

  const ZZPCompliancePriority(this.dutchName);
  final String dutchName;
}

enum ZZPAlertType {
  btwThresholdExceeded('BTW Drempel Overschreden'),
  missingReporting('Aangifte Ontbreekt'),
  highRiskProfile('Hoog Risicoprofiel'),
  documentationIncomplete('Documentatie Onvolledig'),
  deadlineApproaching('Deadline Nadert'),
  complianceViolation('Compliance Overtreding');

  const ZZPAlertType(this.dutchName);
  final String dutchName;
}

enum ZZPAlertSeverity {
  info('Informatie'),
  warning('Waarschuwing'),
  error('Fout'),
  critical('Kritiek');

  const ZZPAlertSeverity(this.dutchName);
  final String dutchName;
}

enum ZZPMetricTrend {
  improving('Verbeterend'),
  stable('Stabiel'),
  declining('Achteruitgaand'),
  unknown('Onbekend');

  const ZZPMetricTrend(this.dutchName);
  final String dutchName;
}

// Extensions for better Dutch localization
extension ZZPComplianceCategoryExtension on ZZPComplianceCategory {
  String get iconName {
    switch (this) {
      case ZZPComplianceCategory.btw:
        return 'account_balance';
      case ZZPComplianceCategory.deductions:
        return 'receipt_long';
      case ZZPComplianceCategory.documentation:
        return 'folder';
      case ZZPComplianceCategory.reporting:
        return 'assignment';
      case ZZPComplianceCategory.riskManagement:
        return 'security';
      case ZZPComplianceCategory.planning:
        return 'event';
    }
  }

  String get description {
    switch (this) {
      case ZZPComplianceCategory.btw:
        return 'BTW registratie en aangiftes';
      case ZZPComplianceCategory.deductions:
        return 'Aftrekposten en limieten';
      case ZZPComplianceCategory.documentation:
        return 'Documentatie en administratie';
      case ZZPComplianceCategory.reporting:
        return 'Belastingaangiftes en rapportages';
      case ZZPComplianceCategory.riskManagement:
        return 'Risicobeheer en compliance';
      case ZZPComplianceCategory.planning:
        return 'Belastingplanning en optimalisatie';
    }
  }
}

extension ZZPCompliancePriorityExtension on ZZPCompliancePriority {
  String get colorHex {
    switch (this) {
      case ZZPCompliancePriority.low:
        return '#10B981'; // Green
      case ZZPCompliancePriority.medium:
        return '#F59E0B'; // Yellow
      case ZZPCompliancePriority.high:
        return '#EF4444'; // Red
      case ZZPCompliancePriority.urgent:
        return '#DC2626'; // Dark red
    }
  }
}

extension ZZPAlertSeverityExtension on ZZPAlertSeverity {
  String get colorHex {
    switch (this) {
      case ZZPAlertSeverity.info:
        return '#3B82F6'; // Blue
      case ZZPAlertSeverity.warning:
        return '#F59E0B'; // Yellow
      case ZZPAlertSeverity.error:
        return '#EF4444'; // Red
      case ZZPAlertSeverity.critical:
        return '#DC2626'; // Dark red
    }
  }
}

// Import the deduction category from the deduction models to avoid conflicts
typedef ZZPDeductionCategory = dynamic; // This will be properly imported