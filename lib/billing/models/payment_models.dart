import 'package:equatable/equatable.dart';
import '../../beveiliger_dashboard/models/enhanced_dashboard_data.dart';

/// Payment system models for SecuryFlex Dutch financial transactions
/// Integrates seamlessly with existing EnhancedEarningsData

/// Payment frequency for recurring payments
enum PaymentFrequency {
  weekly('Wekelijks'),
  biweekly('Tweewekelijks'),
  monthly('Maandelijks'),
  quarterly('Kwartaal');

  const PaymentFrequency(this.dutchName);
  final String dutchName;
}

/// Payment transaction types in Dutch security marketplace
enum PaymentType {
  salary('Salaris Uitbetaling'),
  salaryPayment('Salaris Uitbetaling'),
  overtimePayment('Overuren Betaling'),
  bonusPayment('Bonus Uitbetaling'),
  expenseReimbursement('Onkosten Vergoeding'),
  holidayPayment('Vakantiegeld Uitbetaling'),
  penaltyDeduction('Boete Inhouding'),
  advancePayment('Voorschot Betaling'),
  deposit('Borg Betaling');

  const PaymentType(this.dutchName);
  final String dutchName;
}

/// Payment status with Dutch localization
enum PaymentStatus {
  pending('In Behandeling'),
  processing('Verwerken'),
  completed('Voltooid'),
  failed('Mislukt'),
  cancelled('Geannuleerd'),
  refunded('Terugbetaald'),
  notFound('Niet Gevonden'),
  error('Fout'),
  unknown('Onbekend');

  const PaymentStatus(this.dutchName);
  final String dutchName;
}

/// Payment methods available in Dutch marketplace
enum PaymentMethod {
  sepa('SEPA Overboeking'),
  ideal('iDEAL'),
  bankTransfer('Bankoverschrijving'),
  cash('Contant');

  const PaymentMethod(this.dutchName);
  final String dutchName;
}

/// Invoice types per Dutch tax law
enum InvoiceType {
  salaryInvoice('Salarisstrook'),
  serviceInvoice('Dienstenfactuur'),
  expenseInvoice('Onkostenfactuur'),
  creditNote('Creditnota');

  const InvoiceType(this.dutchName);
  final String dutchName;
}

/// Main payment transaction model integrating with existing earnings
class PaymentTransaction extends Equatable {
  final String id;
  final String guardId;
  final String? companyId;
  final PaymentType type;
  final PaymentMethod method;
  final PaymentStatus status;
  
  // Financial amounts with Dutch formatting
  final double amount;                // Total amount (for backward compatibility)
  final double grossAmount;           // Bruto bedrag
  final double netAmount;             // Netto bedrag
  final double btwAmount;             // BTW 21%
  final double vakantiegeldAmount;    // Vakantiegeld 8%
  final double pensionDeduction;      // Pensioenpremie
  final double inkomstenbelastingAmount; // Income tax
  final String dutchFormattedAmount;  // €1.234,56 format
  final String? dutchFormattedNetAmount; // Net amount formatted
  
  // Integration with existing earnings system
  final String? relatedEarningsId;   // Links to EnhancedEarningsData
  final String? payrollEntryId;      // Links to existing PayrollEntry
  
  // Payment processing details
  final String reference;            // Payment reference
  final String description;          // Dutch description
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final DateTime? executionDate;     // When payment should be executed
  
  // Dutch banking details
  final String? recipientIBAN;       // NL IBAN format
  final String? recipientName;
  final String? paymentReference;    // Structured reference
  final String? transactionReference; // End-to-end reference
  
  // Compliance and audit
  final bool isCAOCompliant;         // CAO arbeidsrecht compliance
  final Map<String, dynamic> complianceData;
  final Map<String, dynamic> auditTrail;
  
  // Error handling
  final String? errorMessage;
  final int retryCount;

  const PaymentTransaction({
    required this.id,
    required this.guardId,
    this.companyId,
    required this.type,
    required this.method,
    required this.status,
    required this.amount,
    required this.grossAmount,
    required this.netAmount,
    required this.btwAmount,
    required this.vakantiegeldAmount,
    required this.pensionDeduction,
    required this.inkomstenbelastingAmount,
    required this.dutchFormattedAmount,
    this.dutchFormattedNetAmount,
    this.relatedEarningsId,
    this.payrollEntryId,
    required this.reference,
    required this.description,
    required this.createdAt,
    this.processedAt,
    this.completedAt,
    this.executionDate,
    this.recipientIBAN,
    this.recipientName,
    this.paymentReference,
    this.transactionReference,
    this.isCAOCompliant = true,
    this.complianceData = const {},
    this.auditTrail = const {},
    this.errorMessage,
    this.retryCount = 0,
  });

  /// Create payment from existing earnings data
  factory PaymentTransaction.fromEarningsData({
    required String guardId,
    required EnhancedEarningsData earnings,
    required PaymentType type,
    required PaymentMethod method,
    String? recipientIBAN,
    String? companyId,
  }) {
    final now = DateTime.now();
    final paymentId = 'pay_${guardId}_${now.millisecondsSinceEpoch}';
    
    return PaymentTransaction(
      id: paymentId,
      guardId: guardId,
      companyId: companyId,
      type: type,
      method: method,
      status: PaymentStatus.pending,
      amount: earnings.totalWeek,
      grossAmount: earnings.totalWeek,
      netAmount: earnings.totalWeek + earnings.vakantiegeld - earnings.btwAmount,
      btwAmount: earnings.btwAmount,
      vakantiegeldAmount: earnings.vakantiegeld,
      pensionDeduction: earnings.totalWeek * 0.055, // 5.5% pension
      inkomstenbelastingAmount: earnings.totalWeek * 0.20, // Rough income tax
      dutchFormattedAmount: earnings.dutchFormattedWeek,
      reference: 'SecuryFlex-${type.name}-${now.millisecondsSinceEpoch}',
      description: 'Salaris periode ${_formatPeriod(now)}',
      createdAt: now,
      recipientIBAN: recipientIBAN,
      recipientName: 'Beveiliger ${guardId.substring(0, 8)}',
      // isCAOCompliant: earnings.isOvertimeCompliant, // Remove this line since it's not in constructor
      complianceData: {
        'hourlyRate': earnings.hourlyRate,
        'hoursWorked': earnings.hoursWorkedWeek,
        'overtimeHours': earnings.overtimeHours,
        'overtimeRate': earnings.overtimeRate,
        'caoCompliant': earnings.isOvertimeCompliant,
      },
      auditTrail: {
        'createdFrom': 'earnings_data',
        'earningsLastCalculated': earnings.lastCalculated.toIso8601String(),
        'paymentCreated': now.toIso8601String(),
      },
    );
  }

  static String _formatPeriod(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}';
  }

  /// Calculate total cost including employer contributions
  double get totalEmployerCost {
    return grossAmount + vakantiegeldAmount + pensionDeduction + (grossAmount * 0.20); // Social security
  }

  /// Get Dutch formatted total cost
  String get dutchFormattedEmployerCost {
    return _formatDutchCurrency(totalEmployerCost);
  }

  /// Check if payment needs urgent processing
  bool get isUrgent {
    if (type == PaymentType.salaryPayment && status == PaymentStatus.pending) {
      final daysSinceCreated = DateTime.now().difference(createdAt).inDays;
      return daysSinceCreated > 7; // CAO requirement: salary within 7 days
    }
    return false;
  }

  /// Get payment status color for UI
  String get statusColorHex {
    switch (status) {
      case PaymentStatus.completed:
        return '#10B981'; // Green
      case PaymentStatus.processing:
        return '#F59E0B'; // Yellow
      case PaymentStatus.failed:
        return '#EF4444'; // Red
      case PaymentStatus.cancelled:
        return '#6B7280'; // Gray
      case PaymentStatus.refunded:
        return '#8B5CF6'; // Purple
      default:
        return '#3B82F6'; // Blue
    }
  }

  String _formatDutchCurrency(double amount) {
    final euros = amount.floor();
    final cents = ((amount - euros) * 100).round();
    final euroString = euros.toString();
    
    // Add thousand separators (Dutch uses dots)
    String formattedEuros = '';
    for (int i = 0; i < euroString.length; i++) {
      if (i > 0 && (euroString.length - i) % 3 == 0) {
        formattedEuros += '.';
      }
      formattedEuros += euroString[i];
    }
    
    return '€$formattedEuros,${cents.toString().padLeft(2, '0')}';
  }

  PaymentTransaction copyWith({
    String? id,
    PaymentStatus? status,
    DateTime? processedAt,
    DateTime? completedAt,
    String? errorMessage,
    int? retryCount,
    Map<String, dynamic>? auditTrail,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      guardId: guardId,
      companyId: companyId,
      type: type,
      method: method,
      status: status ?? this.status,
      amount: amount,
      grossAmount: grossAmount,
      netAmount: netAmount,
      btwAmount: btwAmount,
      vakantiegeldAmount: vakantiegeldAmount,
      pensionDeduction: pensionDeduction,
      inkomstenbelastingAmount: inkomstenbelastingAmount,
      dutchFormattedAmount: dutchFormattedAmount,
      relatedEarningsId: relatedEarningsId,
      payrollEntryId: payrollEntryId,
      reference: reference,
      description: description,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      recipientIBAN: recipientIBAN,
      recipientName: recipientName,
      paymentReference: paymentReference,
      isCAOCompliant: isCAOCompliant,
      complianceData: complianceData,
      auditTrail: auditTrail ?? this.auditTrail,
      errorMessage: errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  List<Object?> get props => [
    id, guardId, companyId, type, method, status,
    grossAmount, netAmount, btwAmount, vakantiegeldAmount,
    pensionDeduction, createdAt, processedAt, completedAt,
    recipientIBAN, reference, retryCount,
  ];
}

/// Dutch compliant invoice document
class InvoiceDocument extends Equatable {
  final String invoiceNumber;        // Sequential per Dutch tax law
  final String guardId;
  final String? companyId;
  final InvoiceType type;
  final DateTime issueDate;          // Factuurdatum
  final DateTime dueDate;            // Vervaldatum (30 days standard)
  
  // Financial breakdown
  final double subtotal;             // Subtotaal
  final double btwAmount;            // BTW 21%
  final double totalAmount;          // Totaalbedrag
  final String dutchFormattedTotal;  // €1.234,56
  
  // Dutch tax compliance
  final String kvkNumber;            // KvK nummer
  final String btwNumber;            // BTW nummer
  final bool btwReverseCharge;       // BTW verlegd naar afnemer
  
  // Invoice lines
  final List<InvoiceLineItem> lineItems;
  
  // Payment details
  final String paymentIBAN;          // Bank IBAN for payment
  final String paymentReference;     // Payment reference
  final String paymentInstructions;  // Dutch payment instructions
  
  // Integration with existing system
  final String? relatedPaymentId;    // Links to PaymentTransaction
  final String? payrollExportId;     // Links to existing payroll export
  
  // Compliance
  final Map<String, dynamic> complianceData;
  final DateTime createdAt;

  const InvoiceDocument({
    required this.invoiceNumber,
    required this.guardId,
    this.companyId,
    required this.type,
    required this.issueDate,
    required this.dueDate,
    required this.subtotal,
    required this.btwAmount,
    required this.totalAmount,
    required this.dutchFormattedTotal,
    required this.kvkNumber,
    required this.btwNumber,
    this.btwReverseCharge = false,
    required this.lineItems,
    required this.paymentIBAN,
    required this.paymentReference,
    required this.paymentInstructions,
    this.relatedPaymentId,
    this.payrollExportId,
    this.complianceData = const {},
    required this.createdAt,
  });

  /// Check if invoice is overdue
  bool get isOverdue => DateTime.now().isAfter(dueDate);

  /// Days until/past due date
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  @override
  List<Object?> get props => [
    invoiceNumber, guardId, companyId, type,
    subtotal, btwAmount, totalAmount,
    issueDate, dueDate, createdAt,
  ];
}

/// Invoice line item for detailed breakdown
class InvoiceLineItem extends Equatable {
  final String description;         // Dutch description
  final double quantity;            // Hours or quantity
  final String unit;                // 'uur', 'stuks', etc.
  final double unitPrice;           // Price per unit
  final double lineTotal;           // Total for this line
  final double btwRate;             // BTW rate (0.21 for 21%)
  final String dutchFormattedTotal; // €1.234,56

  const InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.lineTotal,
    required this.btwRate,
    required this.dutchFormattedTotal,
  });

  @override
  List<Object> get props => [
    description, quantity, unit, unitPrice, lineTotal, btwRate,
  ];
}

/// Financial goal tracking for guards
class FinancialGoal extends Equatable {
  final String id;
  final String guardId;
  final GoalType type;
  final String title;                // Dutch goal title
  final String description;          // Dutch description
  final double targetAmount;         // Target in euros
  final double currentAmount;        // Current progress
  final DateTime deadline;
  final DateTime createdAt;
  
  // Dutch formatting
  final String dutchFormattedTarget;
  final String dutchFormattedCurrent;
  
  // Goal configuration
  final bool isActive;
  final Map<String, dynamic> settings;

  const FinancialGoal({
    required this.id,
    required this.guardId,
    required this.type,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.createdAt,
    required this.dutchFormattedTarget,
    required this.dutchFormattedCurrent,
    this.isActive = true,
    this.settings = const {},
  });

  /// Calculate goal progress percentage
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  /// Check if goal is achieved
  bool get isAchieved => currentAmount >= targetAmount;

  /// Days remaining to deadline
  int get daysRemaining => deadline.difference(DateTime.now()).inDays;

  /// Check if goal is overdue
  bool get isOverdue => DateTime.now().isAfter(deadline) && !isAchieved;

  @override
  List<Object> get props => [
    id, guardId, type, targetAmount, currentAmount,
    deadline, createdAt, isActive,
  ];
}

/// Financial goal types
enum GoalType {
  monthlySavings('Maandelijks Sparen'),
  incomeTarget('Verdiensten Doel'),
  emergencyFund('Noodfonds'),
  equipmentSavings('Uitrusting Sparen'),
  educationSavings('Opleiding Sparen'),
  vacationSavings('Vakantie Sparen');

  const GoalType(this.dutchName);
  final String dutchName;
}

/// SEPA payment request for Dutch banking
class SEPAPaymentRequest extends Equatable {
  final String paymentId;
  final String debtorIBAN;           // Sender IBAN (company)
  final String creditorIBAN;         // Recipient IBAN (guard)
  final String creditorName;         // Recipient name
  final double amount;               // Amount in euros
  final String currency;             // EUR
  final String reference;            // Payment reference
  final String remittanceInfo;       // Additional info
  final DateTime executionDate;      // When to execute
  final SEPAUrgency urgency;         // Normal or high priority

  const SEPAPaymentRequest({
    required this.paymentId,
    required this.debtorIBAN,
    required this.creditorIBAN,
    required this.creditorName,
    required this.amount,
    this.currency = 'EUR',
    required this.reference,
    required this.remittanceInfo,
    required this.executionDate,
    this.urgency = SEPAUrgency.normal,
  });

  @override
  List<Object> get props => [
    paymentId, debtorIBAN, creditorIBAN, amount,
    reference, executionDate, urgency,
  ];
}

/// SEPA payment urgency
enum SEPAUrgency {
  normal('NORM'),
  high('HIGH');

  const SEPAUrgency(this.code);
  final String code;
}

/// iDEAL payment request for Dutch banking
class IdealPaymentRequest extends Equatable {
  final String paymentId;
  final String merchantId;           // iDEAL merchant ID
  final String subId;                // Sub merchant ID
  final double amount;               // Amount in cents
  final String currency;             // EUR
  final String description;          // Dutch description
  final String returnUrl;            // Success return URL
  final String callbackUrl;          // Webhook callback URL
  final String? bankId;              // Selected bank (optional)
  final Map<String, dynamic> metadata; // Additional data

  const IdealPaymentRequest({
    required this.paymentId,
    required this.merchantId,
    required this.subId,
    required this.amount,
    this.currency = 'EUR',
    required this.description,
    required this.returnUrl,
    required this.callbackUrl,
    this.bankId,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
    paymentId, merchantId, amount, description,
    returnUrl, callbackUrl, bankId,
  ];
}

/// Payment calculation result
class PaymentCalculationResult extends Equatable {
  final double grossAmount;          // Gross earnings
  final double netAmount;            // Net after deductions
  final double btwAmount;            // BTW 21%
  final double vakantiegeld;         // Holiday allowance 8%
  final double pensionDeduction;     // Pension contribution
  final double socialSecurityCost;   // Employer social security
  final double totalEmployerCost;    // Total cost to employer
  final String dutchFormattedNet;    // €1.234,56
  final bool isCAOCompliant;         // CAO compliance
  final Map<String, dynamic> breakdown; // Detailed breakdown

  const PaymentCalculationResult({
    required this.grossAmount,
    required this.netAmount,
    required this.btwAmount,
    required this.vakantiegeld,
    required this.pensionDeduction,
    required this.socialSecurityCost,
    required this.totalEmployerCost,
    required this.dutchFormattedNet,
    required this.isCAOCompliant,
    this.breakdown = const {},
  });

  @override
  List<Object> get props => [
    grossAmount, netAmount, btwAmount, vakantiegeld,
    pensionDeduction, totalEmployerCost, isCAOCompliant,
  ];
}

/// Payment system exceptions
enum PaymentErrorType {
  invalidIBAN,
  insufficientFunds,
  paymentDeclined,
  networkError,
  complianceViolation,
  bankUnavailable,
  invalidAmount,
  fraudSuspected,
  systemMaintenance,
}

/// Dutch compliance data for payment transactions
class ComplianceData {
  final double btwPercentage;
  final double vakantiegeldPercentage;
  final bool withholdingTaxApplied;
  final bool caoCompliant;
  final String gdprConsentId;
  final DateTime? lastAuditDate;
  final Map<String, dynamic>? additionalData;

  const ComplianceData({
    required this.btwPercentage,
    required this.vakantiegeldPercentage,
    required this.withholdingTaxApplied,
    required this.caoCompliant,
    required this.gdprConsentId,
    this.lastAuditDate,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'btw_percentage': btwPercentage,
      'vakantiegeld_percentage': vakantiegeldPercentage,
      'withholding_tax_applied': withholdingTaxApplied,
      'cao_compliant': caoCompliant,
      'gdpr_consent_id': gdprConsentId,
      'last_audit_date': lastAuditDate?.toIso8601String(),
      'additional_data': additionalData,
    };
  }

  factory ComplianceData.fromJson(Map<String, dynamic> json) {
    return ComplianceData(
      btwPercentage: (json['btw_percentage'] as num).toDouble(),
      vakantiegeldPercentage: (json['vakantiegeld_percentage'] as num).toDouble(),
      withholdingTaxApplied: json['withholding_tax_applied'] as bool,
      caoCompliant: json['cao_compliant'] as bool,
      gdprConsentId: json['gdpr_consent_id'] as String,
      lastAuditDate: json['last_audit_date'] != null
          ? DateTime.parse(json['last_audit_date'] as String)
          : null,
      additionalData: json['additional_data'] as Map<String, dynamic>?,
    );
  }
}

/// Payment system exception
class PaymentException implements Exception {
  final String message;
  final PaymentErrorType type;
  final String? details;
  final Map<String, dynamic>? context;

  const PaymentException({
    required this.message,
    required this.type,
    this.details,
    this.context,
  });

  @override
  String toString() => 'PaymentException ($type): $message';
}