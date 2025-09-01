import 'package:equatable/equatable.dart';

/// Payment status enumeration for all payment types
enum PaymentStatus {
  pending('Wachtend'),
  processing('Verwerking'),
  awaitingBank('Wacht op bank'),
  completed('Voltooid'),
  failed('Mislukt'),
  cancelled('Geannuleerd'),
  expired('Verlopen'),
  refunded('Terugbetaald'),
  partiallyRefunded('Gedeeltelijk terugbetaald'),
  unknown('Onbekend');

  const PaymentStatus(this.dutchLabel);
  final String dutchLabel;
}

/// Payment type enumeration
enum PaymentType {
  sepaTransfer('SEPA Overschrijving'),
  idealPayment('iDEAL Betaling'),
  expense('Onkostenvergoeding'),
  deposit('Waarborgsom'),
  salary('Salaris'),
  overtime('Overuren'),
  bonus('Bonus'),
  refund('Terugbetaling');

  const PaymentType(this.dutchLabel);
  final String dutchLabel;
}

/// Payment error codes
enum PaymentErrorCode {
  invalidAmount,
  invalidIBAN,
  invalidRecipientName,
  invalidDescription,
  invalidReturnUrl,
  bulkLimitExceeded,
  amountLimitExceeded,
  monthlyLimitExceeded,
  guardNotFound,
  paymentNotFound,
  missingBankDetails,
  paymentCreationFailed,
  bankSelectionFailed,
  unsupportedBank,
  refundAmountTooHigh,
  refundCreationFailed,
  invalidWebhookSignature,
  paymentExpired,
  insufficientFunds,
  networkError,
  serverError,
}

/// Refund status enumeration
enum RefundStatus {
  pending('Wachtend'),
  processing('Verwerking'),
  completed('Voltooid'),
  failed('Mislukt'),
  unknown('Onbekend');

  const RefundStatus(this.dutchLabel);
  final String dutchLabel;
}

/// Base payment exception class
class PaymentException implements Exception {
  final String message;
  final PaymentErrorCode errorCode;
  final Map<String, dynamic>? metadata;

  const PaymentException(
    this.message,
    this.errorCode, [
    this.metadata,
  ]);

  @override
  String toString() => 'PaymentException: $message (${errorCode.name})';
}

/// SEPA Payment model
class SEPAPayment extends Equatable {
  final String id;
  final String? batchId;
  final String guardId;
  final double amount;
  final String currency;
  final String recipientIBAN;
  final String recipientName;
  final String description;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? transactionId;
  final String? failureReason;
  final Map<String, dynamic> metadata;

  const SEPAPayment({
    required this.id,
    this.batchId,
    required this.guardId,
    required this.amount,
    required this.currency,
    required this.recipientIBAN,
    required this.recipientName,
    required this.description,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.transactionId,
    this.failureReason,
    required this.metadata,
  });

  SEPAPayment copyWith({
    String? id,
    String? batchId,
    String? guardId,
    double? amount,
    String? currency,
    String? recipientIBAN,
    String? recipientName,
    String? description,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
    String? transactionId,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) {
    return SEPAPayment(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      guardId: guardId ?? this.guardId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      recipientIBAN: recipientIBAN ?? this.recipientIBAN,
      recipientName: recipientName ?? this.recipientName,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      transactionId: transactionId ?? this.transactionId,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        batchId,
        guardId,
        amount,
        currency,
        recipientIBAN,
        recipientName,
        description,
        status,
        createdAt,
        processedAt,
        transactionId,
        failureReason,
        metadata,
      ];
}

/// iDEAL Payment model
class iDEALPayment extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String description;
  final PaymentType paymentType;
  final PaymentStatus status;
  final String returnUrl;
  final String webhookUrl;
  final String? checkoutUrl;
  final String? providerPaymentId;
  final String? selectedBankBIC;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  const iDEALPayment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.description,
    required this.paymentType,
    required this.status,
    required this.returnUrl,
    required this.webhookUrl,
    this.checkoutUrl,
    this.providerPaymentId,
    this.selectedBankBIC,
    required this.createdAt,
    this.completedAt,
    this.expiresAt,
    required this.metadata,
  });

  iDEALPayment copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    String? description,
    PaymentType? paymentType,
    PaymentStatus? status,
    String? returnUrl,
    String? webhookUrl,
    String? checkoutUrl,
    String? providerPaymentId,
    String? selectedBankBIC,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return iDEALPayment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      paymentType: paymentType ?? this.paymentType,
      status: status ?? this.status,
      returnUrl: returnUrl ?? this.returnUrl,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      providerPaymentId: providerPaymentId ?? this.providerPaymentId,
      selectedBankBIC: selectedBankBIC ?? this.selectedBankBIC,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        currency,
        description,
        paymentType,
        status,
        returnUrl,
        webhookUrl,
        checkoutUrl,
        providerPaymentId,
        selectedBankBIC,
        createdAt,
        completedAt,
        expiresAt,
        metadata,
      ];
}

/// Guard payment request for bulk processing
class GuardPaymentRequest extends Equatable {
  final String guardId;
  final double amount;
  final String recipientIBAN;
  final String recipientName;
  final String description;
  final PaymentType paymentType;
  final Map<String, dynamic> metadata;

  const GuardPaymentRequest({
    required this.guardId,
    required this.amount,
    required this.recipientIBAN,
    required this.recipientName,
    required this.description,
    required this.paymentType,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
        guardId,
        amount,
        recipientIBAN,
        recipientName,
        description,
        paymentType,
        metadata,
      ];
}

/// Payment result model
class PaymentResult extends Equatable {
  final String? paymentId;
  final PaymentStatus? status;
  final DateTime? processingTime;
  final String? transactionId;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final bool success;
  final double? amount;
  final String? currency;
  final String? error;

  const PaymentResult({
    this.paymentId,
    this.status,
    this.processingTime,
    this.transactionId,
    this.errorMessage,
    this.metadata,
    this.success = false,
    this.amount,
    this.currency,
    this.error,
  });

  factory PaymentResult.success({
    required String paymentId,
    required double amount,
    String currency = 'EUR',
    PaymentStatus status = PaymentStatus.completed,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      success: true,
      paymentId: paymentId,
      amount: amount,
      currency: currency,
      status: status,
      metadata: metadata ?? {},
      processingTime: DateTime.now(),
    );
  }

  factory PaymentResult.error(String error, {Map<String, dynamic>? metadata}) {
    return PaymentResult(
      success: false,
      error: error,
      errorMessage: error,
      metadata: metadata ?? {},
      processingTime: DateTime.now(),
    );
  }

  bool get isSuccessful => success && (status == PaymentStatus.completed || status == null);
  bool get isFailed => !success || status == PaymentStatus.failed;
  bool get isPending => status == PaymentStatus.pending || status == PaymentStatus.processing;

  @override
  List<Object?> get props => [
        paymentId,
        status,
        processingTime,
        transactionId,
        errorMessage,
        metadata,
        success,
        amount,
        currency,
        error,
      ];
}

/// Bulk payment result model
class BulkPaymentResult extends Equatable {
  final String batchId;
  final PaymentStatus overallStatus;
  final List<PaymentResult> individualResults;
  final DateTime processingTime;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  const BulkPaymentResult({
    required this.batchId,
    required this.overallStatus,
    required this.individualResults,
    required this.processingTime,
    this.errorMessage,
    required this.metadata,
  });

  int get totalPayments => individualResults.length;
  int get successfulPayments => individualResults.where((r) => r.isSuccessful).length;
  int get failedPayments => individualResults.where((r) => r.isFailed).length;
  double get successRate => totalPayments > 0 ? successfulPayments / totalPayments : 0.0;

  @override
  List<Object?> get props => [
        batchId,
        overallStatus,
        individualResults,
        processingTime,
        errorMessage,
        metadata,
      ];
}

/// iDEAL payment result model
class iDEALPaymentResult extends Equatable {
  final String paymentId;
  final String? providerPaymentId;
  final String? checkoutUrl;
  final PaymentStatus status;
  final DateTime? expiresAt;
  final String? qrCodeUrl;
  final iDEALBank? selectedBank;
  final String? errorMessage;

  const iDEALPaymentResult({
    required this.paymentId,
    this.providerPaymentId,
    this.checkoutUrl,
    required this.status,
    this.expiresAt,
    this.qrCodeUrl,
    this.selectedBank,
    this.errorMessage,
  });

  bool get isSuccessful => status == PaymentStatus.completed;
  bool get requiresBankSelection => status == PaymentStatus.pending && checkoutUrl != null;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  List<Object?> get props => [
        paymentId,
        providerPaymentId,
        checkoutUrl,
        status,
        expiresAt,
        qrCodeUrl,
        selectedBank,
        errorMessage,
      ];
}

/// Dutch bank model for iDEAL
class iDEALBank extends Equatable {
  final String bic;
  final String name;
  final String? logoUrl;
  final String countryCode;

  const iDEALBank({
    required this.bic,
    required this.name,
    this.logoUrl,
    required this.countryCode,
  });

  @override
  List<Object?> get props => [bic, name, logoUrl, countryCode];
}

/// Refund result model
class RefundResult extends Equatable {
  final String refundId;
  final String? providerRefundId;
  final RefundStatus status;
  final double amount;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? errorMessage;

  const RefundResult({
    required this.refundId,
    this.providerRefundId,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.processedAt,
    this.errorMessage,
  });

  bool get isSuccessful => status == RefundStatus.completed;
  bool get isFailed => status == RefundStatus.failed;
  bool get isPending => status == RefundStatus.pending || status == RefundStatus.processing;

  @override
  List<Object?> get props => [
        refundId,
        providerRefundId,
        status,
        amount,
        createdAt,
        processedAt,
        errorMessage,
      ];
}

/// Payment status update model for real-time updates
class PaymentStatusUpdate extends Equatable {
  final String paymentId;
  final PaymentStatus status;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PaymentStatusUpdate({
    required this.paymentId,
    required this.status,
    required this.timestamp,
    required this.metadata,
  });

  @override
  List<Object?> get props => [paymentId, status, timestamp, metadata];
}


/// Payment provider result for integration
class PaymentProviderResult extends Equatable {
  final bool isSuccessful;
  final String? transactionId;
  final String? errorMessage;
  final Map<String, dynamic>? providerResponse;
  final DateTime processedAt;

  PaymentProviderResult({
    required this.isSuccessful,
    this.transactionId,
    this.errorMessage,
    this.providerResponse,
    DateTime? processedAt,
  }) : processedAt = processedAt ?? DateTime.now();

  @override
  List<Object?> get props => [
    isSuccessful,
    transactionId,
    errorMessage,
    providerResponse,
    processedAt,
  ];
}

/// SEPA Payment Request model
class SEPAPaymentRequest extends Equatable {
  final double amount;
  final String currency;
  final String recipientIBAN;
  final String recipientName;
  final String description;
  final String reference;
  final String mandateId;

  const SEPAPaymentRequest({
    required this.amount,
    required this.currency,
    required this.recipientIBAN,
    required this.recipientName,
    required this.description,
    required this.reference,
    required this.mandateId,
  });

  @override
  List<Object?> get props => [
    amount,
    currency,
    recipientIBAN,
    recipientName,
    description,
    reference,
    mandateId,
  ];
}

/// iDEAL Payment Request model
class iDEALPaymentRequest extends Equatable {
  final double amount;
  final String currency;
  final String description;
  final String reference;

  const iDEALPaymentRequest({
    required this.amount,
    required this.currency,
    required this.description,
    required this.reference,
  });

  @override
  List<Object?> get props => [
    amount,
    currency,
    description,
    reference,
  ];
}

/// Invoice model for Dutch tax compliance
class DutchInvoice extends Equatable {
  final String id;
  final String invoiceNumber;
  final String companyName;
  final String companyKvK;
  final String companyBTW;
  final String companyAddress;
  final String clientName;
  final String clientAddress;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<InvoiceLineItem> lineItems;
  final double subtotal;
  final double btwAmount;
  final double total;
  final String currency;
  final PaymentStatus paymentStatus;
  final String? paymentReference;
  final DateTime createdAt;

  const DutchInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.companyName,
    required this.companyKvK,
    required this.companyBTW,
    required this.companyAddress,
    required this.clientName,
    required this.clientAddress,
    required this.invoiceDate,
    required this.dueDate,
    required this.lineItems,
    required this.subtotal,
    required this.btwAmount,
    required this.total,
    required this.currency,
    required this.paymentStatus,
    this.paymentReference,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        companyName,
        companyKvK,
        companyBTW,
        companyAddress,
        clientName,
        clientAddress,
        invoiceDate,
        dueDate,
        lineItems,
        subtotal,
        btwAmount,
        total,
        currency,
        paymentStatus,
        paymentReference,
        createdAt,
      ];
}

/// Invoice line item model
class InvoiceLineItem extends Equatable {
  final String description;
  final double quantity;
  final double unitPrice;
  final double btwRate;
  final double totalExclBTW;
  final double btwAmount;
  final double totalInclBTW;

  const InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.btwRate,
    required this.totalExclBTW,
    required this.btwAmount,
    required this.totalInclBTW,
  });

  @override
  List<Object?> get props => [
        description,
        quantity,
        unitPrice,
        btwRate,
        totalExclBTW,
        btwAmount,
        totalInclBTW,
      ];
}

/// Payment analytics data model
class PaymentAnalytics extends Equatable {
  final DateTime period;
  final double totalVolume;
  final int totalTransactions;
  final double averageTransaction;
  final int successfulTransactions;
  final int failedTransactions;
  final double successRate;
  final Map<PaymentType, double> volumeByType;
  final Map<PaymentStatus, int> transactionsByStatus;
  final List<DailyPaymentSummary> dailySummaries;

  const PaymentAnalytics({
    required this.period,
    required this.totalVolume,
    required this.totalTransactions,
    required this.averageTransaction,
    required this.successfulTransactions,
    required this.failedTransactions,
    required this.successRate,
    required this.volumeByType,
    required this.transactionsByStatus,
    required this.dailySummaries,
  });

  @override
  List<Object?> get props => [
        period,
        totalVolume,
        totalTransactions,
        averageTransaction,
        successfulTransactions,
        failedTransactions,
        successRate,
        volumeByType,
        transactionsByStatus,
        dailySummaries,
      ];
}

/// Daily payment summary for analytics
class DailyPaymentSummary extends Equatable {
  final DateTime date;
  final double volume;
  final int transactions;
  final double successRate;

  const DailyPaymentSummary({
    required this.date,
    required this.volume,
    required this.transactions,
    required this.successRate,
  });

  @override
  List<Object?> get props => [date, volume, transactions, successRate];
}