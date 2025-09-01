import 'package:equatable/equatable.dart';

import '../../shared/utils/dutch_formatting.dart';

/// ZZP Invoice Types for different purposes
enum ZZPInvoiceType {
  serviceInvoice('Dienstenfactuur'),
  expenseInvoice('Onkostenfactuur'),
  quarterlyTaxReport('Kwartaal Belastingrapport'),
  annualTaxSummary('Jaarlijkse Belastingsamenvatting'),
  creditNote('Creditnota');

  const ZZPInvoiceType(this.dutchName);
  final String dutchName;
}

/// ZZP Invoice Line Item Categories
enum ZZPInvoiceLineCategory {
  income('Inkomen'),
  tax('Belasting'),
  deduction('Aftrekpost'),
  expense('Uitgave'),
  equipment('Uitrusting'),
  training('Opleiding');

  const ZZPInvoiceLineCategory(this.dutchName);
  final String dutchName;
}

/// ZZP Invoice Compliance Status
enum ZZPInvoiceComplianceStatus {
  compliant('Compliant'),
  warning('Waarschuwing'),
  nonCompliant('Niet Compliant'),
  underReview('Onder Review');

  const ZZPInvoiceComplianceStatus(this.dutchName);
  final String dutchName;
}

/// Comprehensive ZZP Invoice Data Structure
class ZZPInvoiceData extends Equatable {
  final String invoiceNumber;
  final ZZPInvoiceType invoiceType;
  final String guardId;
  final String? companyId;
  final Map<String, dynamic> guardInfo;
  final Map<String, dynamic>? companyInfo;
  final List<ZZPInvoiceLineItem> lineItems;
  final DateTime issueDate;
  final DateTime dueDate;
  final double btwRate;
  final double subtotal;
  final double btwAmount;
  final double totalAmount;
  final double netAmount;
  final Map<String, dynamic> taxCalculationData;
  final String description;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> complianceInfo;
  final DateTime createdAt;

  const ZZPInvoiceData({
    required this.invoiceNumber,
    required this.invoiceType,
    required this.guardId,
    this.companyId,
    required this.guardInfo,
    this.companyInfo,
    required this.lineItems,
    required this.issueDate,
    required this.dueDate,
    required this.btwRate,
    this.subtotal = 0.0,
    this.btwAmount = 0.0,
    this.totalAmount = 0.0,
    this.netAmount = 0.0,
    required this.taxCalculationData,
    required this.description,
    required this.metadata,
    required this.complianceInfo,
    required this.createdAt,
  });

  String get dutchFormattedTotal => DutchFormatting.formatCurrency(totalAmount);
  String get dutchFormattedSubtotal => DutchFormatting.formatCurrency(subtotal);
  String get dutchFormattedBTW => DutchFormatting.formatCurrency(btwAmount);
  String get dutchFormattedIssueDate => DutchFormatting.formatDate(issueDate);
  String get dutchFormattedDueDate => DutchFormatting.formatDate(dueDate);

  ZZPInvoiceData copyWith({
    double? subtotal,
    double? btwAmount,
    double? totalAmount,
    double? netAmount,
  }) {
    return ZZPInvoiceData(
      invoiceNumber: invoiceNumber,
      invoiceType: invoiceType,
      guardId: guardId,
      companyId: companyId,
      guardInfo: guardInfo,
      companyInfo: companyInfo,
      lineItems: lineItems,
      issueDate: issueDate,
      dueDate: dueDate,
      btwRate: btwRate,
      subtotal: subtotal ?? this.subtotal,
      btwAmount: btwAmount ?? this.btwAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      netAmount: netAmount ?? this.netAmount,
      taxCalculationData: taxCalculationData,
      description: description,
      metadata: metadata,
      complianceInfo: complianceInfo,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    invoiceNumber, invoiceType, guardId, companyId, issueDate,
    dueDate, subtotal, btwAmount, totalAmount, createdAt,
  ];
}

/// ZZP Invoice Line Item with categorization
class ZZPInvoiceLineItem extends Equatable {
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final double btwRate;
  final double btwAmount;
  final ZZPInvoiceLineCategory category;
  final Map<String, dynamic> metadata;

  const ZZPInvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.btwRate,
    required this.btwAmount,
    required this.category,
    this.metadata = const {},
  });

  String get dutchFormattedUnitPrice => DutchFormatting.formatCurrency(unitPrice);
  String get dutchFormattedTotalPrice => DutchFormatting.formatCurrency(totalPrice);
  String get dutchFormattedBTWAmount => DutchFormatting.formatCurrency(btwAmount);
  String get dutchFormattedBTWRate => '${(btwRate * 100).toStringAsFixed(0)}%';

  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'btw_rate': btwRate,
      'btw_amount': btwAmount,
      'category': category.name,
      'metadata': metadata,
    };
  }

  factory ZZPInvoiceLineItem.fromFirestore(Map<String, dynamic> data) {
    return ZZPInvoiceLineItem(
      description: data['description'] as String,
      quantity: (data['quantity'] as num).toDouble(),
      unitPrice: (data['unit_price'] as num).toDouble(),
      totalPrice: (data['total_price'] as num).toDouble(),
      btwRate: (data['btw_rate'] as num).toDouble(),
      btwAmount: (data['btw_amount'] as num).toDouble(),
      category: ZZPInvoiceLineCategory.values.firstWhere(
        (c) => c.name == data['category'],
      ),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
    description, quantity, unitPrice, totalPrice, btwRate, btwAmount, category,
  ];
}

/// ZZP Invoice Calculation Result
class ZZPInvoiceCalculationResult extends Equatable {
  final double subtotal;
  final double btwAmount;
  final double totalAmount;
  final double netAmount;

  const ZZPInvoiceCalculationResult({
    required this.subtotal,
    required this.btwAmount,
    required this.totalAmount,
    required this.netAmount,
  });

  String get dutchFormattedSubtotal => DutchFormatting.formatCurrency(subtotal);
  String get dutchFormattedBTWAmount => DutchFormatting.formatCurrency(btwAmount);
  String get dutchFormattedTotalAmount => DutchFormatting.formatCurrency(totalAmount);
  String get dutchFormattedNetAmount => DutchFormatting.formatCurrency(netAmount);

  @override
  List<Object?> get props => [subtotal, btwAmount, totalAmount, netAmount];
}

/// ZZP Invoice Generation Result
class ZZPInvoiceResult extends Equatable {
  final bool success;
  final String invoiceId;
  final String invoiceNumber;
  final ZZPInvoiceType invoiceType;
  final double totalAmount;
  final double btwAmount;
  final double netAmount;
  final String pdfDownloadUrl;
  final String? xmlDownloadUrl;
  final ZZPInvoiceComplianceStatus complianceStatus;
  final DateTime generatedAt;
  final String dutchFormattedTotal;

  const ZZPInvoiceResult({
    required this.success,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceType,
    required this.totalAmount,
    required this.btwAmount,
    required this.netAmount,
    required this.pdfDownloadUrl,
    this.xmlDownloadUrl,
    required this.complianceStatus,
    required this.generatedAt,
    required this.dutchFormattedTotal,
  });

  String get dutchFormattedBTWAmount => DutchFormatting.formatCurrency(btwAmount);
  String get dutchFormattedNetAmount => DutchFormatting.formatCurrency(netAmount);
  String get dutchFormattedGeneratedAt => DutchFormatting.formatDateTime(generatedAt);

  @override
  List<Object?> get props => [
    success, invoiceId, invoiceNumber, invoiceType, totalAmount,
    btwAmount, netAmount, complianceStatus, generatedAt,
  ];
}

/// ZZP Invoice Summary for reporting
class ZZPInvoiceSummary extends Equatable {
  final String guardId;
  final int year;
  final int? quarter;
  final Map<ZZPInvoiceType, int> invoiceTypeCounts;
  final Map<ZZPInvoiceType, double> invoiceTypeTotals;
  final double totalInvoiceAmount;
  final double totalBTWAmount;
  final double averageInvoiceAmount;
  final List<ZZPMonthlyInvoiceSummary> monthlyBreakdown;
  final DateTime generatedAt;

  const ZZPInvoiceSummary({
    required this.guardId,
    required this.year,
    this.quarter,
    required this.invoiceTypeCounts,
    required this.invoiceTypeTotals,
    required this.totalInvoiceAmount,
    required this.totalBTWAmount,
    required this.averageInvoiceAmount,
    required this.monthlyBreakdown,
    required this.generatedAt,
  });

  String get dutchFormattedTotal => DutchFormatting.formatCurrency(totalInvoiceAmount);
  String get dutchFormattedBTWTotal => DutchFormatting.formatCurrency(totalBTWAmount);
  String get dutchFormattedAverage => DutchFormatting.formatCurrency(averageInvoiceAmount);

  @override
  List<Object?> get props => [
    guardId, year, quarter, totalInvoiceAmount, totalBTWAmount,
    averageInvoiceAmount, generatedAt,
  ];
}

/// Monthly invoice summary for detailed tracking
class ZZPMonthlyInvoiceSummary extends Equatable {
  final int month;
  final int invoiceCount;
  final double totalAmount;
  final double btwAmount;
  final Map<ZZPInvoiceType, int> typeBreakdown;

  const ZZPMonthlyInvoiceSummary({
    required this.month,
    required this.invoiceCount,
    required this.totalAmount,
    required this.btwAmount,
    required this.typeBreakdown,
  });

  String get dutchMonthName {
    const monthNames = [
      'Januari', 'Februari', 'Maart', 'April', 'Mei', 'Juni',
      'Juli', 'Augustus', 'September', 'Oktober', 'November', 'December'
    ];
    return monthNames[month - 1];
  }

  String get dutchFormattedAmount => DutchFormatting.formatCurrency(totalAmount);
  String get dutchFormattedBTW => DutchFormatting.formatCurrency(btwAmount);

  @override
  List<Object?> get props => [month, invoiceCount, totalAmount, btwAmount];
}

/// ZZP Invoice Template for quick invoice generation
class ZZPInvoiceTemplate extends Equatable {
  final String id;
  final String guardId;
  final String templateName;
  final ZZPInvoiceType defaultInvoiceType;
  final List<ZZPInvoiceLineItem> defaultLineItems;
  final String defaultDescription;
  final Map<String, dynamic> defaultMetadata;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ZZPInvoiceTemplate({
    required this.id,
    required this.guardId,
    required this.templateName,
    required this.defaultInvoiceType,
    required this.defaultLineItems,
    required this.defaultDescription,
    required this.defaultMetadata,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id, guardId, templateName, defaultInvoiceType, isActive,
    createdAt, updatedAt,
  ];
}

/// ZZP Invoice Approval Workflow
class ZZPInvoiceApproval extends Equatable {
  final String invoiceId;
  final String guardId;
  final String? companyId;
  final ZZPInvoiceApprovalStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final List<String> requiredDocuments;
  final List<String> providedDocuments;
  final Map<String, dynamic> approvalMetadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ZZPInvoiceApproval({
    required this.invoiceId,
    required this.guardId,
    this.companyId,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.requiredDocuments,
    required this.providedDocuments,
    required this.approvalMetadata,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isApproved => status == ZZPInvoiceApprovalStatus.approved;
  bool get isRejected => status == ZZPInvoiceApprovalStatus.rejected;
  bool get isPending => status == ZZPInvoiceApprovalStatus.pending;

  @override
  List<Object?> get props => [
    invoiceId, guardId, companyId, status, approvedAt,
    createdAt, updatedAt,
  ];
}

/// ZZP Invoice Approval Status
enum ZZPInvoiceApprovalStatus {
  pending('In Behandeling'),
  approved('Goedgekeurd'),
  rejected('Afgekeurd'),
  documentsRequired('Documenten Vereist'),
  underReview('Onder Review');

  const ZZPInvoiceApprovalStatus(this.dutchName);
  final String dutchName;
}

/// ZZP Invoice Payment Status
class ZZPInvoicePaymentStatus extends Equatable {
  final String invoiceId;
  final ZZPPaymentStatus paymentStatus;
  final DateTime? paymentDate;
  final String? paymentReference;
  final String? paymentMethod;
  final double? paidAmount;
  final String? bankAccount;
  final Map<String, dynamic> paymentMetadata;

  const ZZPInvoicePaymentStatus({
    required this.invoiceId,
    required this.paymentStatus,
    this.paymentDate,
    this.paymentReference,
    this.paymentMethod,
    this.paidAmount,
    this.bankAccount,
    required this.paymentMetadata,
  });

  bool get isPaid => paymentStatus == ZZPPaymentStatus.paid;
  bool get isOverdue => paymentStatus == ZZPPaymentStatus.overdue;
  String? get dutchFormattedPaidAmount => 
      paidAmount != null ? DutchFormatting.formatCurrency(paidAmount!) : null;

  @override
  List<Object?> get props => [
    invoiceId, paymentStatus, paymentDate, paymentReference, paidAmount,
  ];
}

/// ZZP Payment Status
enum ZZPPaymentStatus {
  pending('In Behandeling'),
  paid('Betaald'),
  partiallyPaid('Gedeeltelijk Betaald'),
  overdue('Achterstallig'),
  cancelled('Geannuleerd'),
  refunded('Terugbetaald');

  const ZZPPaymentStatus(this.dutchName);
  final String dutchName;
}

/// ZZP Invoice Analytics Data
class ZZPInvoiceAnalytics extends Equatable {
  final String guardId;
  final int analysisYear;
  final double totalRevenue;
  final double totalBTWCollected;
  final double averageInvoiceValue;
  final int totalInvoicesGenerated;
  final Map<String, double> clientBreakdown; // company_id -> total_amount
  final Map<ZZPInvoiceType, double> typeBreakdown;
  final Map<int, double> monthlyTrends; // month -> total_amount
  final double projectedYearEndRevenue;
  final List<ZZPInvoiceInsight> insights;
  final DateTime generatedAt;

  const ZZPInvoiceAnalytics({
    required this.guardId,
    required this.analysisYear,
    required this.totalRevenue,
    required this.totalBTWCollected,
    required this.averageInvoiceValue,
    required this.totalInvoicesGenerated,
    required this.clientBreakdown,
    required this.typeBreakdown,
    required this.monthlyTrends,
    required this.projectedYearEndRevenue,
    required this.insights,
    required this.generatedAt,
  });

  String get dutchFormattedRevenue => DutchFormatting.formatCurrency(totalRevenue);
  String get dutchFormattedBTW => DutchFormatting.formatCurrency(totalBTWCollected);
  String get dutchFormattedAverage => DutchFormatting.formatCurrency(averageInvoiceValue);
  String get dutchFormattedProjected => DutchFormatting.formatCurrency(projectedYearEndRevenue);

  @override
  List<Object?> get props => [
    guardId, analysisYear, totalRevenue, totalBTWCollected,
    averageInvoiceValue, totalInvoicesGenerated, generatedAt,
  ];
}

/// ZZP Invoice Insight for analytics
class ZZPInvoiceInsight extends Equatable {
  final String title;
  final String description;
  final ZZPInsightType type;
  final ZZPInsightPriority priority;
  final double? impactValue;
  final List<String> actionRecommendations;

  const ZZPInvoiceInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.impactValue,
    required this.actionRecommendations,
  });

  String? get dutchFormattedImpact =>
      impactValue != null ? DutchFormatting.formatCurrency(impactValue!) : null;

  @override
  List<Object?> get props => [title, description, type, priority, impactValue];
}

/// ZZP Insight Types
enum ZZPInsightType {
  revenue('Omzet'),
  tax('Belasting'),
  client('Klant'),
  trend('Trend'),
  opportunity('Kans');

  const ZZPInsightType(this.dutchName);
  final String dutchName;
}

/// ZZP Insight Priority
enum ZZPInsightPriority {
  low('Laag'),
  medium('Gemiddeld'),
  high('Hoog'),
  critical('Kritiek');

  const ZZPInsightPriority(this.dutchName);
  final String dutchName;
}

/// Extension for easy Dutch formatting
extension ZZPInvoiceTypeExtension on ZZPInvoiceType {
  String get shortCode {
    switch (this) {
      case ZZPInvoiceType.serviceInvoice:
        return 'SRV';
      case ZZPInvoiceType.expenseInvoice:
        return 'EXP';
      case ZZPInvoiceType.quarterlyTaxReport:
        return 'QTR';
      case ZZPInvoiceType.annualTaxSummary:
        return 'ANN';
      case ZZPInvoiceType.creditNote:
        return 'CRD';
    }
  }

  String get description {
    switch (this) {
      case ZZPInvoiceType.serviceInvoice:
        return 'Factuur voor geleverde beveiligingsdiensten';
      case ZZPInvoiceType.expenseInvoice:
        return 'Factuur voor zakelijke onkosten';
      case ZZPInvoiceType.quarterlyTaxReport:
        return 'Kwartaal belastingrapport voor de Belastingdienst';
      case ZZPInvoiceType.annualTaxSummary:
        return 'Jaarlijkse belastingsamenvatting';
      case ZZPInvoiceType.creditNote:
        return 'Creditnota voor correcties';
    }
  }
}

extension ZZPInvoiceLineItemCategoryExtension on ZZPInvoiceLineCategory {
  String get iconName {
    switch (this) {
      case ZZPInvoiceLineCategory.income:
        return 'attach_money';
      case ZZPInvoiceLineCategory.tax:
        return 'account_balance';
      case ZZPInvoiceLineCategory.deduction:
        return 'remove_circle';
      case ZZPInvoiceLineCategory.expense:
        return 'receipt';
      case ZZPInvoiceLineCategory.equipment:
        return 'build';
      case ZZPInvoiceLineCategory.training:
        return 'school';
    }
  }
}