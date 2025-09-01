import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/utils/dutch_formatting.dart';
import '../../auth/services/bsn_security_service.dart';

/// Belastingdienst submission types
enum BelastingdienstSubmissionType {
  btwQuarterly('BTW Kwartaal Aangifte'),
  annualIncome('Jaarangifte Inkomstenbelasting'),
  corrections('Correctie Aangifte');

  const BelastingdienstSubmissionType(this.dutchName);
  final String dutchName;
}

/// Processing status from Belastingdienst
enum BelastingdienstProcessingStatus {
  submitted('Ingediend'),
  received('Ontvangen'),
  processing('In Behandeling'),
  validated('Gevalideerd'),
  processed('Verwerkt'),
  completed('Afgerond'),
  rejected('Afgewezen'),
  requiresAttention('Vereist Aandacht');

  const BelastingdienstProcessingStatus(this.dutchName);
  final String dutchName;
}

/// Declaration type for BTW submissions
enum BelastingdienstDeclarationType {
  quarterly('Kwartaal'),
  monthly('Maandelijks'),
  annual('Jaarlijks');

  const BelastingdienstDeclarationType(this.dutchName);
  final String dutchName;
}

/// BTW Return data structure for Belastingdienst API
class BelastingdienstBTWReturn extends Equatable {
  final String btwNumber;
  final int year;
  final int quarter;
  final String declarationPeriod;
  final double grossRevenue;
  final double btwOwed;
  final double inputBTWDeducted;
  final double netBTWOwed;
  final double previousPeriodCarryOver;
  final double quarterlyTurnover;
  final double servicesRendered;
  final double goodsSupplied;
  final DateTime submissionDate;
  final BelastingdienstDeclarationType declarationType;

  const BelastingdienstBTWReturn({
    required this.btwNumber,
    required this.year,
    required this.quarter,
    required this.declarationPeriod,
    required this.grossRevenue,
    required this.btwOwed,
    required this.inputBTWDeducted,
    required this.netBTWOwed,
    required this.previousPeriodCarryOver,
    required this.quarterlyTurnover,
    required this.servicesRendered,
    required this.goodsSupplied,
    required this.submissionDate,
    required this.declarationType,
  });

  String get dutchFormattedRevenue => DutchFormatting.formatCurrency(grossRevenue);
  String get dutchFormattedBTWOwed => DutchFormatting.formatCurrency(btwOwed);
  String get dutchFormattedNetBTW => DutchFormatting.formatCurrency(netBTWOwed);

  /// Convert to API format expected by Belastingdienst
  Map<String, dynamic> toApiFormat() {
    return {
      'btwNummer': btwNumber,
      'aangiftejaar': year,
      'aangiftekwartaal': quarter,
      'aangifteperiode': declarationPeriod,
      'omzetGegevens': {
        'brutoOmzet': grossRevenue,
        'dienstverleningBinnenland': servicesRendered,
        'goederenLeveringBinnenland': goodsSupplied,
        'totaalOmzet': quarterlyTurnover,
      },
      'btwBerekening': {
        'verschuldigdeBtw': btwOwed,
        'voorbetaaldeBtw': inputBTWDeducted,
        'saldoVorigPeriode': previousPeriodCarryOver,
        'teBetalen': netBTWOwed,
      },
      'aangifteDatum': submissionDate.toIso8601String(),
      'aangifteType': declarationType.name,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'btw_number': btwNumber,
      'year': year,
      'quarter': quarter,
      'declaration_period': declarationPeriod,
      'gross_revenue': grossRevenue,
      'btw_owed': btwOwed,
      'input_btw_deducted': inputBTWDeducted,
      'net_btw_owed': netBTWOwed,
      'previous_period_carryover': previousPeriodCarryOver,
      'quarterly_turnover': quarterlyTurnover,
      'services_rendered': servicesRendered,
      'goods_supplied': goodsSupplied,
      'submission_date': Timestamp.fromDate(submissionDate),
      'declaration_type': declarationType.name,
    };
  }

  factory BelastingdienstBTWReturn.fromFirestore(Map<String, dynamic> data) {
    return BelastingdienstBTWReturn(
      btwNumber: data['btw_number'] as String,
      year: data['year'] as int,
      quarter: data['quarter'] as int,
      declarationPeriod: data['declaration_period'] as String,
      grossRevenue: (data['gross_revenue'] as num).toDouble(),
      btwOwed: (data['btw_owed'] as num).toDouble(),
      inputBTWDeducted: (data['input_btw_deducted'] as num).toDouble(),
      netBTWOwed: (data['net_btw_owed'] as num).toDouble(),
      previousPeriodCarryOver: (data['previous_period_carryover'] as num).toDouble(),
      quarterlyTurnover: (data['quarterly_turnover'] as num).toDouble(),
      servicesRendered: (data['services_rendered'] as num).toDouble(),
      goodsSupplied: (data['goods_supplied'] as num).toDouble(),
      submissionDate: (data['submission_date'] as Timestamp).toDate(),
      declarationType: BelastingdienstDeclarationType.values.firstWhere(
        (type) => type.name == data['declaration_type'],
      ),
    );
  }

  @override
  List<Object?> get props => [
    btwNumber, year, quarter, grossRevenue, btwOwed, netBTWOwed, submissionDate,
  ];
}

/// Annual Income Tax Return data structure for Belastingdienst API
class BelastingdienstAnnualReturn extends Equatable {
  final String guardId;
  final int taxYear;
  final String bsn; // Encrypted BSN - use getBSNForDisplay() for UI
  final double totalAnnualIncome;
  final double totalDeductions;
  final double taxableIncome;
  final double incomeTaxOwed;
  final double zelfstandigenaftrek;
  final List<Map<String, dynamic>> quarterlyBreakdown;
  final Map<String, dynamic> professionalExpenses;
  final double otherIncome;
  final DateTime submissionDate;

  const BelastingdienstAnnualReturn({
    required this.guardId,
    required this.taxYear,
    required this.bsn,
    required this.totalAnnualIncome,
    required this.totalDeductions,
    required this.taxableIncome,
    required this.incomeTaxOwed,
    required this.zelfstandigenaftrek,
    required this.quarterlyBreakdown,
    required this.professionalExpenses,
    required this.otherIncome,
    required this.submissionDate,
  });

  String get dutchFormattedIncome => DutchFormatting.formatCurrency(totalAnnualIncome);
  String get dutchFormattedDeductions => DutchFormatting.formatCurrency(totalDeductions);
  String get dutchFormattedTaxOwed => DutchFormatting.formatCurrency(incomeTaxOwed);

  /// Get BSN for display purposes (masked)
  String getBSNForDisplay() {
    try {
      if (BSNSecurityService.isEncryptedBSN(bsn)) {
        // Return masked version for display
        return '***-**-${bsn.substring(bsn.length - 2)}';
      } else {
        return BSNSecurityService.maskBSN(bsn);
      }
    } catch (e) {
      return '***ERROR***';
    }
  }
  
  /// Convert to API format expected by Belastingdienst
  /// WARNING: Only use for actual API submission to Belastingdienst
  Future<Map<String, dynamic>> toApiFormat() async {
    // For API submission, decrypt BSN for actual submission
    final decryptedBSN = BSNSecurityService.isEncryptedBSN(bsn) 
        ? await BSNSecurityService.instance.decryptBSN(bsn, guardId)
        : bsn;
        
    // Audit BSN access for tax submission
    BSNSecurityService.hashBSNForAudit(bsn);
        
    return {
      'burgerservicenummer': decryptedBSN, // Only for API submission!
      'belastingjaar': taxYear,
      'inkomstenGegevens': {
        'totaalJaarinkomen': totalAnnualIncome,
        'totaalAftrekposten': totalDeductions,
        'belastbaarInkomen': taxableIncome,
        'andereInkomsten': otherIncome,
      },
      'belastingBerekening': {
        'verschuldigdeInkomstenbelasting': incomeTaxOwed,
        'zelfstandigenaftrek': zelfstandigenaftrek,
      },
      'kwartaalOverzicht': quarterlyBreakdown,
      'bedrijfskosten': professionalExpenses,
      'aangifteDatum': submissionDate.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'guard_id': guardId,
      'tax_year': taxYear,
      'bsn': bsn, // Keep encrypted BSN in Firestore
      'total_annual_income': totalAnnualIncome,
      'total_deductions': totalDeductions,
      'taxable_income': taxableIncome,
      'income_tax_owed': incomeTaxOwed,
      'zelfstandigenaftrek': zelfstandigenaftrek,
      'quarterly_breakdown': quarterlyBreakdown,
      'professional_expenses': professionalExpenses,
      'other_income': otherIncome,
      'submission_date': Timestamp.fromDate(submissionDate),
    };
  }

  @override
  List<Object?> get props => [
    guardId, taxYear, bsn, totalAnnualIncome, totalDeductions,
    incomeTaxOwed, submissionDate,
  ];
}

/// API credentials for Belastingdienst integration
class BelastingdienstApiCredentials extends Equatable {
  final String clientId;
  final String clientSecret;
  final String environment; // 'sandbox', 'production'
  final DateTime expiresAt;
  final Map<String, String> additionalParams;

  const BelastingdienstApiCredentials({
    required this.clientId,
    required this.clientSecret,
    required this.environment,
    required this.expiresAt,
    this.additionalParams = const {},
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isProduction => environment == 'production';

  factory BelastingdienstApiCredentials.fromEncryptedData(Map<String, dynamic> data) {
    return BelastingdienstApiCredentials(
      clientId: data['client_id'] as String,
      clientSecret: data['client_secret'] as String,
      environment: data['environment'] as String,
      expiresAt: DateTime.parse(data['expires_at'] as String),
      additionalParams: Map<String, String>.from(data['additional_params'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [clientId, environment, expiresAt];
}

/// API response from Belastingdienst
class BelastingdienstApiResponse extends Equatable {
  final String submissionId;
  final String referenceNumber;
  final BelastingdienstProcessingStatus processingStatus;
  final DateTime submittedAt;
  final Duration estimatedProcessingTime;
  final Map<String, dynamic> additionalData;

  const BelastingdienstApiResponse({
    required this.submissionId,
    required this.referenceNumber,
    required this.processingStatus,
    required this.submittedAt,
    required this.estimatedProcessingTime,
    this.additionalData = const {},
  });

  String get dutchFormattedSubmittedAt => DutchFormatting.formatDateTime(submittedAt);
  String get estimatedCompletionTime => 
      DutchFormatting.formatDateTime(submittedAt.add(estimatedProcessingTime));

  factory BelastingdienstApiResponse.fromApiResponse(Map<String, dynamic> data) {
    return BelastingdienstApiResponse(
      submissionId: data['inzendingId'] as String,
      referenceNumber: data['referentienummer'] as String,
      processingStatus: BelastingdienstProcessingStatus.values.firstWhere(
        (status) => status.name == (data['verwerkingsstatus'] as String).toLowerCase(),
        orElse: () => BelastingdienstProcessingStatus.submitted,
      ),
      submittedAt: DateTime.parse(data['ingediendOp'] as String),
      estimatedProcessingTime: Duration(
        hours: (data['verwachteTijdUren'] as num?)?.toInt() ?? 24,
      ),
      additionalData: Map<String, dynamic>.from(data['aanvullendeGegevens'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'submission_id': submissionId,
      'reference_number': referenceNumber,
      'processing_status': processingStatus.name,
      'submitted_at': Timestamp.fromDate(submittedAt),
      'estimated_processing_hours': estimatedProcessingTime.inHours,
      'additional_data': additionalData,
    };
  }

  @override
  List<Object?> get props => [
    submissionId, referenceNumber, processingStatus, submittedAt,
  ];
}

/// Submission result returned to the client
class BelastingdienstSubmissionResult extends Equatable {
  final bool success;
  final String submissionId;
  final String referenceNumber;
  final BelastingdienstSubmissionType submissionType;
  final DateTime submittedAt;
  final BelastingdienstProcessingStatus processingStatus;
  final String receiptUrl;
  final Duration estimatedProcessingTime;
  final List<String> nextSteps;

  const BelastingdienstSubmissionResult({
    required this.success,
    required this.submissionId,
    required this.referenceNumber,
    required this.submissionType,
    required this.submittedAt,
    required this.processingStatus,
    required this.receiptUrl,
    required this.estimatedProcessingTime,
    required this.nextSteps,
  });

  String get dutchFormattedSubmittedAt => DutchFormatting.formatDateTime(submittedAt);
  String get estimatedCompletionTime => 
      DutchFormatting.formatDateTime(submittedAt.add(estimatedProcessingTime));

  @override
  List<Object?> get props => [
    success, submissionId, referenceNumber, submissionType,
    processingStatus, submittedAt,
  ];
}

/// Status result from checking submission status
class BelastingdienstStatusResult extends Equatable {
  final String submissionId;
  final BelastingdienstProcessingStatus status;
  final DateTime lastUpdated;
  final String? statusMessage;
  final Map<String, dynamic> statusDetails;
  final bool hasStatusChanged;

  const BelastingdienstStatusResult({
    required this.submissionId,
    required this.status,
    required this.lastUpdated,
    this.statusMessage,
    this.statusDetails = const {},
    this.hasStatusChanged = false,
  });

  String get dutchFormattedLastUpdated => DutchFormatting.formatDateTime(lastUpdated);

  factory BelastingdienstStatusResult.fromApiResponse(Map<String, dynamic> data) {
    return BelastingdienstStatusResult(
      submissionId: data['inzendingId'] as String,
      status: BelastingdienstProcessingStatus.values.firstWhere(
        (status) => status.name == (data['status'] as String).toLowerCase(),
        orElse: () => BelastingdienstProcessingStatus.processing,
      ),
      lastUpdated: DateTime.parse(data['laatstBijgewerkt'] as String),
      statusMessage: data['statusBericht'] as String?,
      statusDetails: Map<String, dynamic>.from(data['statusDetails'] ?? {}),
      hasStatusChanged: data['statusGewijzigd'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'submission_id': submissionId,
      'status': status.name,
      'last_updated': Timestamp.fromDate(lastUpdated),
      'status_message': statusMessage,
      'status_details': statusDetails,
      'has_status_changed': hasStatusChanged,
    };
  }

  @override
  List<Object?> get props => [submissionId, status, lastUpdated, hasStatusChanged];
}

/// Assessment result from Belastingdienst
class BelastingdienstAssessmentResult extends Equatable {
  final String submissionId;
  final DateTime assessmentDate;
  final double assessmentAmount;
  final double refundAmount;
  final double additionalTaxOwed;
  final String assessmentDocumentUrl;
  final Map<String, String> paymentInstructions;
  final DateTime? appealDeadline;

  const BelastingdienstAssessmentResult({
    required this.submissionId,
    required this.assessmentDate,
    required this.assessmentAmount,
    required this.refundAmount,
    required this.additionalTaxOwed,
    required this.assessmentDocumentUrl,
    required this.paymentInstructions,
    this.appealDeadline,
  });

  String get dutchFormattedAssessmentDate => DutchFormatting.formatDate(assessmentDate);
  String get dutchFormattedAssessmentAmount => DutchFormatting.formatCurrency(assessmentAmount);
  String get dutchFormattedRefundAmount => DutchFormatting.formatCurrency(refundAmount);
  String get dutchFormattedAdditionalTax => DutchFormatting.formatCurrency(additionalTaxOwed);
  String? get dutchFormattedAppealDeadline => 
      appealDeadline != null ? DutchFormatting.formatDate(appealDeadline!) : null;

  bool get hasRefund => refundAmount > 0;
  bool get hasAdditionalTax => additionalTaxOwed > 0;
  bool get canAppeal => appealDeadline != null && DateTime.now().isBefore(appealDeadline!);

  @override
  List<Object?> get props => [
    submissionId, assessmentDate, assessmentAmount, refundAmount,
    additionalTaxOwed, appealDeadline,
  ];
}

/// Assessment API response from Belastingdienst
class BelastingdienstAssessmentApiResponse extends Equatable {
  final String submissionId;
  final DateTime assessmentDate;
  final double assessmentAmount;
  final double refundAmount;
  final double additionalTaxOwed;
  final List<int> assessmentDocument; // PDF bytes
  final Map<String, String> paymentInstructions;
  final DateTime? appealDeadline;
  final DateTime? paymentDueDate;

  const BelastingdienstAssessmentApiResponse({
    required this.submissionId,
    required this.assessmentDate,
    required this.assessmentAmount,
    required this.refundAmount,
    required this.additionalTaxOwed,
    required this.assessmentDocument,
    required this.paymentInstructions,
    this.appealDeadline,
    this.paymentDueDate,
  });

  factory BelastingdienstAssessmentApiResponse.fromApiResponse(Map<String, dynamic> data) {
    return BelastingdienstAssessmentApiResponse(
      submissionId: data['inzendingId'] as String,
      assessmentDate: DateTime.parse(data['uitslagDatum'] as String),
      assessmentAmount: (data['uitslagBedrag'] as num).toDouble(),
      refundAmount: (data['teruggaafBedrag'] as num).toDouble(),
      additionalTaxOwed: (data['nabetaling'] as num).toDouble(),
      assessmentDocument: List<int>.from(data['uitslagDocument']),
      paymentInstructions: Map<String, String>.from(data['betalingsinstructies'] ?? {}),
      appealDeadline: data['bezwaarTermijn'] != null 
          ? DateTime.parse(data['bezwaarTermijn'] as String)
          : null,
      paymentDueDate: data['betalingTermijn'] != null
          ? DateTime.parse(data['betalingTermijn'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    submissionId, assessmentDate, assessmentAmount, refundAmount,
    additionalTaxOwed, appealDeadline, paymentDueDate,
  ];
}

/// Validation result for submission data
class BelastingdienstValidationResult extends Equatable {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const BelastingdienstValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  int get totalIssues => errors.length + warnings.length;

  @override
  List<Object?> get props => [isValid, errors, warnings];
}

/// Receipt for submission confirmation
class BelastingdienstReceipt extends Equatable {
  final String submissionId;
  final String downloadUrl;
  final DateTime generatedAt;

  const BelastingdienstReceipt({
    required this.submissionId,
    required this.downloadUrl,
    required this.generatedAt,
  });

  String get dutchFormattedGeneratedAt => DutchFormatting.formatDateTime(generatedAt);

  @override
  List<Object?> get props => [submissionId, downloadUrl, generatedAt];
}

/// Integration status and health monitoring
class BelastingdienstIntegrationStatus extends Equatable {
  final String guardId;
  final bool isConfigured;
  final bool credentialsValid;
  final DateTime? lastSuccessfulSubmission;
  final List<String> configurationIssues;
  final Map<BelastingdienstSubmissionType, int> submissionCounts;
  final DateTime lastChecked;

  const BelastingdienstIntegrationStatus({
    required this.guardId,
    required this.isConfigured,
    required this.credentialsValid,
    this.lastSuccessfulSubmission,
    required this.configurationIssues,
    required this.submissionCounts,
    required this.lastChecked,
  });

  String get dutchFormattedLastChecked => DutchFormatting.formatDateTime(lastChecked);
  String? get dutchFormattedLastSubmission => 
      lastSuccessfulSubmission != null 
          ? DutchFormatting.formatDateTime(lastSuccessfulSubmission!)
          : null;

  bool get isHealthy => isConfigured && credentialsValid && configurationIssues.isEmpty;
  
  int get totalSubmissions => submissionCounts.values
      .fold(0, (total, itemCount) => total + itemCount);

  @override
  List<Object?> get props => [
    guardId, isConfigured, credentialsValid, lastSuccessfulSubmission,
    lastChecked,
  ];
}

// Extensions for better Dutch localization
extension BelastingdienstSubmissionTypeExtension on BelastingdienstSubmissionType {
  String get description {
    switch (this) {
      case BelastingdienstSubmissionType.btwQuarterly:
        return 'Kwartaal BTW aangifte voor omzetbelasting';
      case BelastingdienstSubmissionType.annualIncome:
        return 'Jaarlijkse aangifte inkomstenbelasting voor ZZP';
      case BelastingdienstSubmissionType.corrections:
        return 'Correctie op eerder ingediende aangifte';
    }
  }

  String get iconName {
    switch (this) {
      case BelastingdienstSubmissionType.btwQuarterly:
        return 'account_balance';
      case BelastingdienstSubmissionType.annualIncome:
        return 'assignment';
      case BelastingdienstSubmissionType.corrections:
        return 'edit';
    }
  }
}

extension BelastingdienstProcessingStatusExtension on BelastingdienstProcessingStatus {
  String get colorHex {
    switch (this) {
      case BelastingdienstProcessingStatus.submitted:
        return '#3B82F6'; // Blue
      case BelastingdienstProcessingStatus.received:
        return '#6366F1'; // Indigo
      case BelastingdienstProcessingStatus.processing:
        return '#F59E0B'; // Yellow
      case BelastingdienstProcessingStatus.validated:
        return '#8B5CF6'; // Purple
      case BelastingdienstProcessingStatus.processed:
        return '#06B6D4'; // Cyan
      case BelastingdienstProcessingStatus.completed:
        return '#10B981'; // Green
      case BelastingdienstProcessingStatus.rejected:
        return '#EF4444'; // Red
      case BelastingdienstProcessingStatus.requiresAttention:
        return '#F97316'; // Orange
    }
  }

  bool get isCompleted => this == BelastingdienstProcessingStatus.completed;
  bool get isError => this == BelastingdienstProcessingStatus.rejected;
  bool get needsAction => this == BelastingdienstProcessingStatus.requiresAttention;
}