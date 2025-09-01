import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/payment_models.dart';
import '../repository/payment_repository.dart';
import '../services/ideal_payment_service.dart';
import '../services/sepa_payment_service.dart';
import '../services/dutch_invoice_service.dart';
import '../services/payment_audit_service.dart';

// Payment Events
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

// SEPA Payment Events
class ProcessSEPAPayment extends PaymentEvent {
  final String guardId;
  final double amount;
  final String recipientIBAN;
  final String recipientName;
  final String description;
  final Map<String, dynamic>? metadata;

  const ProcessSEPAPayment({
    required this.guardId,
    required this.amount,
    required this.recipientIBAN,
    required this.recipientName,
    required this.description,
    this.metadata,
  });

  @override
  List<Object?> get props => [guardId, amount, recipientIBAN, recipientName, description, metadata];
}

class ProcessBulkSEPAPayments extends PaymentEvent {
  final List<GuardPaymentRequest> paymentRequests;
  final String batchDescription;

  const ProcessBulkSEPAPayments({
    required this.paymentRequests,
    required this.batchDescription,
  });

  @override
  List<Object?> get props => [paymentRequests, batchDescription];
}

// iDEAL Payment Events
class CreateiDEALPayment extends PaymentEvent {
  final String userId;
  final double amount;
  final String description;
  final PaymentType paymentType;
  final String returnUrl;
  final String webhookUrl;
  final Map<String, dynamic>? metadata;

  const CreateiDEALPayment({
    required this.userId,
    required this.amount,
    required this.description,
    required this.paymentType,
    required this.returnUrl,
    required this.webhookUrl,
    this.metadata,
  });

  @override
  List<Object?> get props => [userId, amount, description, paymentType, returnUrl, webhookUrl, metadata];
}

class ProcessiDEALPaymentWithBank extends PaymentEvent {
  final String paymentId;
  final String bankBIC;

  const ProcessiDEALPaymentWithBank({
    required this.paymentId,
    required this.bankBIC,
  });

  @override
  List<Object?> get props => [paymentId, bankBIC];
}

class GetiDEALBanks extends PaymentEvent {
  const GetiDEALBanks();
}

// Invoice Events
class GenerateGuardInvoice extends PaymentEvent {
  final String guardId;
  final String periodDescription;
  final List<dynamic> payrollEntries;

  const GenerateGuardInvoice({
    required this.guardId,
    required this.periodDescription,
    required this.payrollEntries,
  });

  @override
  List<Object?> get props => [guardId, periodDescription, payrollEntries];
}

class GenerateExpenseInvoice extends PaymentEvent {
  final String companyId;
  final String description;
  final List<dynamic> expenses;

  const GenerateExpenseInvoice({
    required this.companyId,
    required this.description,
    required this.expenses,
  });

  @override
  List<Object?> get props => [companyId, description, expenses];
}

class GenerateInvoicePDF extends PaymentEvent {
  final DutchInvoice invoice;

  const GenerateInvoicePDF({
    required this.invoice,
  });

  @override
  List<Object?> get props => [invoice];
}

// Query Events
class LoadSEPAPaymentsForGuard extends PaymentEvent {
  final String guardId;
  final int limit;

  const LoadSEPAPaymentsForGuard({
    required this.guardId,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [guardId, limit];
}

class LoadiDEALPaymentsForUser extends PaymentEvent {
  final String userId;
  final int limit;

  const LoadiDEALPaymentsForUser({
    required this.userId,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [userId, limit];
}

class LoadPaymentAnalytics extends PaymentEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadPaymentAnalytics({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class SearchPayments extends PaymentEvent {
  final PaymentSearchCriteria criteria;

  const SearchPayments({
    required this.criteria,
  });

  @override
  List<Object?> get props => [criteria];
}

class RefreshPayments extends PaymentEvent {
  const RefreshPayments();
}

class ClearPaymentError extends PaymentEvent {
  const ClearPaymentError();
}

// Refund Events
class CreateRefund extends PaymentEvent {
  final String paymentId;
  final double amount;
  final String description;
  final Map<String, dynamic>? metadata;

  const CreateRefund({
    required this.paymentId,
    required this.amount,
    required this.description,
    this.metadata,
  });

  @override
  List<Object?> get props => [paymentId, amount, description, metadata];
}

// Payment States
abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  final String? operationType;
  final String? message;

  const PaymentLoading({
    this.operationType,
    this.message,
  });

  @override
  List<Object?> get props => [operationType, message];
}

class PaymentSuccess extends PaymentState {
  final String message;
  final dynamic result;
  final String? operationType;

  const PaymentSuccess({
    required this.message,
    this.result,
    this.operationType,
  });

  @override
  List<Object?> get props => [message, result, operationType];
}

class PaymentError extends PaymentState {
  final String error;
  final String? operationType;
  final PaymentErrorCode? errorCode;

  const PaymentError({
    required this.error,
    this.operationType,
    this.errorCode,
  });

  @override
  List<Object?> get props => [error, operationType, errorCode];
}

// Specific success states
class SEPAPaymentCreated extends PaymentState {
  final PaymentResult result;

  const SEPAPaymentCreated({
    required this.result,
  });

  @override
  List<Object?> get props => [result];
}

class BulkSEPAPaymentCreated extends PaymentState {
  final BulkPaymentResult result;

  const BulkSEPAPaymentCreated({
    required this.result,
  });

  @override
  List<Object?> get props => [result];
}

class iDEALPaymentCreated extends PaymentState {
  final iDEALPaymentResult result;

  const iDEALPaymentCreated({
    required this.result,
  });

  @override
  List<Object?> get props => [result];
}

class iDEALBanksLoaded extends PaymentState {
  final List<iDEALBank> banks;

  const iDEALBanksLoaded({
    required this.banks,
  });

  @override
  List<Object?> get props => [banks];
}

class InvoiceGenerated extends PaymentState {
  final DutchInvoice invoice;

  const InvoiceGenerated({
    required this.invoice,
  });

  @override
  List<Object?> get props => [invoice];
}

class InvoicePDFGenerated extends PaymentState {
  final String filePath;
  final DutchInvoice invoice;

  const InvoicePDFGenerated({
    required this.filePath,
    required this.invoice,
  });

  @override
  List<Object?> get props => [filePath, invoice];
}

class PaymentsLoaded extends PaymentState {
  final List<dynamic> payments;
  final PaymentType paymentType;

  const PaymentsLoaded({
    required this.payments,
    required this.paymentType,
  });

  @override
  List<Object?> get props => [payments, paymentType];
}

class PaymentAnalyticsLoaded extends PaymentState {
  final PaymentAnalytics analytics;

  const PaymentAnalyticsLoaded({
    required this.analytics,
  });

  @override
  List<Object?> get props => [analytics];
}

class RefundCreated extends PaymentState {
  final RefundResult result;

  const RefundCreated({
    required this.result,
  });

  @override
  List<Object?> get props => [result];
}

// Payment BLoC
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;
  final iDEALPaymentService _idealService;
  final SepaPaymentService _sepaService;
  final DutchInvoiceService _invoiceService;
  final PaymentAuditService _auditService;

  PaymentBloc({
    required PaymentRepository paymentRepository,
    required iDEALPaymentService idealService,
    required SepaPaymentService sepaService,
    required DutchInvoiceService invoiceService,
    required PaymentAuditService auditService,
  }) : _paymentRepository = paymentRepository,
       _idealService = idealService,
       _sepaService = sepaService,
       _invoiceService = invoiceService,
       _auditService = auditService,
       super(const PaymentInitial()) {
    
    // SEPA Payment handlers
    on<ProcessSEPAPayment>(_onProcessSEPAPayment);
    on<ProcessBulkSEPAPayments>(_onProcessBulkSEPAPayments);
    
    // iDEAL Payment handlers
    on<CreateiDEALPayment>(_onCreateiDEALPayment);
    on<ProcessiDEALPaymentWithBank>(_onProcessiDEALPaymentWithBank);
    on<GetiDEALBanks>(_onGetiDEALBanks);
    
    // Invoice handlers
    on<GenerateGuardInvoice>(_onGenerateGuardInvoice);
    on<GenerateExpenseInvoice>(_onGenerateExpenseInvoice);
    on<GenerateInvoicePDF>(_onGenerateInvoicePDF);
    
    // Query handlers
    on<LoadSEPAPaymentsForGuard>(_onLoadSEPAPaymentsForGuard);
    on<LoadiDEALPaymentsForUser>(_onLoadiDEALPaymentsForUser);
    on<LoadPaymentAnalytics>(_onLoadPaymentAnalytics);
    on<SearchPayments>(_onSearchPayments);
    
    // Utility handlers
    on<RefreshPayments>(_onRefreshPayments);
    on<ClearPaymentError>(_onClearPaymentError);
    on<CreateRefund>(_onCreateRefund);
  }

  // SEPA Payment handlers

  Future<void> _onProcessSEPAPayment(
    ProcessSEPAPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(
      operationType: 'SEPA_PAYMENT',
      message: 'SEPA betaling wordt verwerkt...',
    ));

    try {
      final result = await _sepaService.processGuardPayment(
        guardId: event.guardId,
        amount: event.amount,
        currency: 'EUR',
        recipientIBAN: event.recipientIBAN,
        recipientName: event.recipientName,
        description: event.description,
        metadata: event.metadata,
      );

      emit(SEPAPaymentCreated(result: result));

    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      final errorCode = _getErrorCode(e);
      
      await _auditService.logPaymentError(
        type: 'SEPA_PAYMENT_BLOC_ERROR',
        error: errorMessage,
        metadata: {
          'guard_id': event.guardId,
          'amount': event.amount,
        },
      );

      emit(PaymentError(
        error: errorMessage,
        operationType: 'SEPA_PAYMENT',
        errorCode: errorCode,
      ));
    }
  }

  Future<void> _onProcessBulkSEPAPayments(
    ProcessBulkSEPAPayments event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(
      operationType: 'BULK_SEPA_PAYMENT',
      message: 'Bulk SEPA betalingen worden verwerkt...',
    ));

    try {
      final result = await _sepaService.processBulkGuardPayments(
        paymentRequests: event.paymentRequests,
        batchDescription: event.batchDescription,
      );

      emit(BulkSEPAPaymentCreated(result: result));

    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      
      await _auditService.logPaymentError(
        type: 'BULK_SEPA_PAYMENT_BLOC_ERROR',
        error: errorMessage,
        metadata: {
          'payment_count': event.paymentRequests.length,
          'batch_description': event.batchDescription,
        },
      );

      emit(PaymentError(
        error: errorMessage,
        operationType: 'BULK_SEPA_PAYMENT',
      ));
    }
  }

  // iDEAL Payment handlers

  Future<void> _onCreateiDEALPayment(
    CreateiDEALPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(
      operationType: 'IDEAL_PAYMENT',
      message: 'iDEAL betaling wordt aangemaakt...',
    ));

    try {
      final result = await _idealService.createPayment(
        userId: event.userId,
        amount: event.amount,
        description: event.description,
        returnUrl: event.returnUrl,
        webhookUrl: event.webhookUrl,
        paymentType: event.paymentType,
        metadata: event.metadata,
      );

      emit(iDEALPaymentCreated(result: result));

    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      
      await _auditService.logPaymentError(
        type: 'IDEAL_PAYMENT_BLOC_ERROR',
        error: errorMessage,
        metadata: {
          'user_id': event.userId,
          'amount': event.amount,
        },
      );

      emit(PaymentError(
        error: errorMessage,
        operationType: 'IDEAL_PAYMENT',
      ));
    }
  }

  Future<void> _onProcessiDEALPaymentWithBank(
    ProcessiDEALPaymentWithBank event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(
      operationType: 'IDEAL_BANK_SELECTION',
      message: 'Bank selectie wordt verwerkt...',
    ));

    try {
      final result = await _idealService.processPaymentWithBank(
        paymentId: event.paymentId,
        bankBIC: event.bankBIC,
      );

      emit(iDEALPaymentCreated(result: result));

    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      
      emit(PaymentError(
        error: errorMessage,
        operationType: 'IDEAL_BANK_SELECTION',
      ));
    }
  }

  Future<void> _onGetiDEALBanks(
    GetiDEALBanks event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(
      operationType: 'IDEAL_BANKS',
      message: 'Beschikbare banken laden...',
    ));

    try {
      final banks = await _idealService.getAvailableBanks();
      emit(iDEALBanksLoaded(banks: banks));

    } catch (e) {
      emit(PaymentError(
        error: 'Kon beschikbare banken niet laden: ${e.toString()}',
        operationType: 'IDEAL_BANKS',
      ));
    }
  }

  // Invoice handlers

  Future<void> _onGenerateGuardInvoice(
    GenerateGuardInvoice event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(
      operationType: 'INVOICE_GENERATION',
      message: 'Factuur wordt gegenereerd...',
    ));

    try {
      final invoice = await _invoiceService.generateGuardSalaryInvoice(
        guardId: event.guardId,
        periodDescription: event.periodDescription,
        payrollEntries: event.payrollEntries.cast(),
      );

      emit(InvoiceGenerated(invoice: invoice));

    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      
      await _auditService.logInvoiceError(
        type: 'INVOICE_GENERATION_BLOC_ERROR',
        error: errorMessage,
        metadata: {
          'guard_id': event.guardId,
          'period': event.periodDescription,
        },
      );

      emit(PaymentError(
        error: errorMessage,
        operationType: 'INVOICE_GENERATION',
      ));
    }
  }

  Future<void> _onGenerateExpenseInvoice(
    GenerateExpenseInvoice event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(
      operationType: 'EXPENSE_INVOICE',
      message: 'Onkostenfactuur wordt gegenereerd...',
    ));

    try {
      final invoice = await _invoiceService.generateExpenseInvoice(
        companyId: event.companyId,
        description: event.description,
        expenses: event.expenses.cast(),
      );

      emit(InvoiceGenerated(invoice: invoice));

    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      
      emit(PaymentError(
        error: errorMessage,
        operationType: 'EXPENSE_INVOICE',
      ));
    }
  }

  Future<void> _onGenerateInvoicePDF(
    GenerateInvoicePDF event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(
      operationType: 'PDF_GENERATION',
      message: 'PDF wordt gegenereerd...',
    ));

    try {
      final file = await _invoiceService.generateInvoicePDF(event.invoice);

      emit(InvoicePDFGenerated(
        filePath: file.path,
        invoice: event.invoice,
      ));

    } catch (e) {
      emit(PaymentError(
        error: 'PDF generatie mislukt: ${e.toString()}',
        operationType: 'PDF_GENERATION',
      ));
    }
  }

  // Query handlers

  Future<void> _onLoadSEPAPaymentsForGuard(
    LoadSEPAPaymentsForGuard event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(
      operationType: 'LOAD_SEPA_PAYMENTS',
      message: 'SEPA betalingen laden...',
    ));

    try {
      final payments = await _paymentRepository.getSEPAPaymentsForGuard(
        event.guardId,
        limit: event.limit,
      );

      emit(PaymentsLoaded(
        payments: payments,
        paymentType: PaymentType.sepaTransfer,
      ));

    } catch (e) {
      emit(PaymentError(
        error: 'Kon SEPA betalingen niet laden: ${e.toString()}',
        operationType: 'LOAD_SEPA_PAYMENTS',
      ));
    }
  }

  Future<void> _onLoadiDEALPaymentsForUser(
    LoadiDEALPaymentsForUser event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(
      operationType: 'LOAD_IDEAL_PAYMENTS',
      message: 'iDEAL betalingen laden...',
    ));

    try {
      final payments = await _paymentRepository.getiDEALPaymentsForUser(
        event.userId,
        limit: event.limit,
      );

      emit(PaymentsLoaded(
        payments: payments,
        paymentType: PaymentType.idealPayment,
      ));

    } catch (e) {
      emit(PaymentError(
        error: 'Kon iDEAL betalingen niet laden: ${e.toString()}',
        operationType: 'LOAD_IDEAL_PAYMENTS',
      ));
    }
  }

  Future<void> _onLoadPaymentAnalytics(
    LoadPaymentAnalytics event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(
      operationType: 'LOAD_ANALYTICS',
      message: 'Betalingsanalyses laden...',
    ));

    try {
      final analytics = await _paymentRepository.getPaymentAnalytics(
        event.startDate,
        event.endDate,
      );

      emit(PaymentAnalyticsLoaded(analytics: analytics));

    } catch (e) {
      emit(PaymentError(
        error: 'Kon analyses niet laden: ${e.toString()}',
        operationType: 'LOAD_ANALYTICS',
      ));
    }
  }

  Future<void> _onSearchPayments(
    SearchPayments event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(
      operationType: 'SEARCH_PAYMENTS',
      message: 'Betalingen zoeken...',
    ));

    try {
      List<dynamic> payments = [];
      
      if (event.criteria.paymentType == PaymentType.sepaTransfer) {
        payments = await _paymentRepository.searchSEPAPayments(
          guardId: event.criteria.userId,
          status: event.criteria.status,
          startDate: event.criteria.startDate,
          endDate: event.criteria.endDate,
          minAmount: event.criteria.minAmount,
          maxAmount: event.criteria.maxAmount,
          limit: event.criteria.limit,
        );
      } else {
        payments = await _paymentRepository.searchiDEALPayments(
          userId: event.criteria.userId,
          paymentType: event.criteria.paymentType,
          status: event.criteria.status,
          startDate: event.criteria.startDate,
          endDate: event.criteria.endDate,
          minAmount: event.criteria.minAmount,
          maxAmount: event.criteria.maxAmount,
          limit: event.criteria.limit,
        );
      }

      emit(PaymentsLoaded(
        payments: payments,
        paymentType: event.criteria.paymentType ?? PaymentType.idealPayment,
      ));

    } catch (e) {
      emit(PaymentError(
        error: 'Zoeken mislukt: ${e.toString()}',
        operationType: 'SEARCH_PAYMENTS',
      ));
    }
  }

  Future<void> _onCreateRefund(
    CreateRefund event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(
      operationType: 'CREATE_REFUND',
      message: 'Terugbetaling wordt verwerkt...',
    ));

    try {
      final result = await _idealService.createRefund(
        paymentId: event.paymentId,
        amount: event.amount,
        description: event.description,
        metadata: event.metadata,
      );

      emit(RefundCreated(result: result));

    } catch (e) {
      emit(PaymentError(
        error: 'Terugbetaling mislukt: ${e.toString()}',
        operationType: 'CREATE_REFUND',
      ));
    }
  }

  // Utility handlers

  Future<void> _onRefreshPayments(
    RefreshPayments event,
    Emitter<PaymentState> emit,
  ) async {
    // Refresh current state if it contains payments
    if (state is PaymentsLoaded) {
      emit(const PaymentLoading(message: 'Betalingen verversen...'));
      // Could reload the same data or implement specific refresh logic
      emit(const PaymentInitial());
    }
  }

  Future<void> _onClearPaymentError(
    ClearPaymentError event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentInitial());
  }

  // Helper methods

  String _getErrorMessage(dynamic error) {
    if (error is PaymentException) {
      return error.message;
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    } else {
      return error.toString();
    }
  }

  PaymentErrorCode? _getErrorCode(dynamic error) {
    if (error is PaymentException) {
      return error.errorCode;
    }
    return null;
  }
}

// Payment search criteria
class PaymentSearchCriteria extends Equatable {
  final String? userId;
  final PaymentType? paymentType;
  final PaymentStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final int limit;

  const PaymentSearchCriteria({
    this.userId,
    this.paymentType,
    this.status,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [
        userId,
        paymentType,
        status,
        startDate,
        endDate,
        minAmount,
        maxAmount,
        limit,
      ];
}