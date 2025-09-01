import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../beveiliger_dashboard/services/enhanced_earnings_service.dart';
import '../../beveiliger_dashboard/models/enhanced_dashboard_data.dart';
import '../services/payment_service.dart';
import '../models/payment_models.dart';

/// Payment Events
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

/// Load payment history
class LoadPaymentHistory extends PaymentEvent {
  final String guardId;
  final PaymentType? typeFilter;
  final PaymentStatus? statusFilter;

  const LoadPaymentHistory({
    required this.guardId,
    this.typeFilter,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [guardId, typeFilter, statusFilter];
}

/// Process salary payment using existing earnings
class ProcessSalaryPayment extends PaymentEvent {
  final String guardId;
  final String recipientIBAN;
  final PaymentMethod method;
  final String? companyId;
  final bool includeVakantiegeld;

  const ProcessSalaryPayment({
    required this.guardId,
    required this.recipientIBAN,
    this.method = PaymentMethod.sepa,
    this.companyId,
    this.includeVakantiegeld = true,
  });

  @override
  List<Object?> get props => [guardId, recipientIBAN, method, companyId, includeVakantiegeld];
}

/// Process expense reimbursement
class ProcessExpenseReimbursement extends PaymentEvent {
  final String guardId;
  final double amount;
  final String description;
  final String? companyId;
  final Map<String, dynamic> metadata;

  const ProcessExpenseReimbursement({
    required this.guardId,
    required this.amount,
    required this.description,
    this.companyId,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [guardId, amount, description, companyId, metadata];
}

/// Calculate payment amount
class CalculatePaymentAmount extends PaymentEvent {
  final String guardId;
  final PaymentType type;
  final bool includeVakantiegeld;
  final bool applyBTWDeduction;

  const CalculatePaymentAmount({
    required this.guardId,
    required this.type,
    this.includeVakantiegeld = true,
    this.applyBTWDeduction = false,
  });

  @override
  List<Object?> get props => [guardId, type, includeVakantiegeld, applyBTWDeduction];
}

/// Load specific payment
class LoadPayment extends PaymentEvent {
  final String paymentId;

  const LoadPayment(this.paymentId);

  @override
  List<Object> get props => [paymentId];
}

/// Update payment status (from webhook)
class UpdatePaymentStatus extends PaymentEvent {
  final String paymentId;
  final PaymentStatus newStatus;
  final Map<String, dynamic>? additionalData;

  const UpdatePaymentStatus({
    required this.paymentId,
    required this.newStatus,
    this.additionalData,
  });

  @override
  List<Object?> get props => [paymentId, newStatus, additionalData];
}

/// Retry failed payment
class RetryPayment extends PaymentEvent {
  final String paymentId;

  const RetryPayment(this.paymentId);

  @override
  List<Object> get props => [paymentId];
}

/// Watch real-time payments
class WatchPayments extends PaymentEvent {
  final String guardId;
  final PaymentStatus? statusFilter;

  const WatchPayments({
    required this.guardId,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [guardId, statusFilter];
}

/// Payment States
abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

/// Loading state with Dutch message
class PaymentLoading extends PaymentState {
  final String? message;

  const PaymentLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Payment history loaded
class PaymentHistoryLoaded extends PaymentState {
  final List<PaymentTransaction> payments;
  final PaymentType? appliedTypeFilter;
  final PaymentStatus? appliedStatusFilter;

  const PaymentHistoryLoaded({
    required this.payments,
    this.appliedTypeFilter,
    this.appliedStatusFilter,
  });

  @override
  List<Object?> get props => [payments, appliedTypeFilter, appliedStatusFilter];
}

/// Payment calculation completed
class PaymentCalculationCompleted extends PaymentState {
  final PaymentCalculationResult calculation;
  final EnhancedEarningsData relatedEarnings;

  const PaymentCalculationCompleted({
    required this.calculation,
    required this.relatedEarnings,
  });

  @override
  List<Object> get props => [calculation, relatedEarnings];
}

/// Payment processing in progress
class PaymentProcessing extends PaymentState {
  final PaymentTransaction payment;
  final String dutchStatusMessage;

  const PaymentProcessing({
    required this.payment,
    required this.dutchStatusMessage,
  });

  @override
  List<Object> get props => [payment, dutchStatusMessage];
}

/// Payment completed successfully
class PaymentSuccess extends PaymentState {
  final PaymentTransaction payment;
  final String successMessage;
  final InvoiceDocument? generatedInvoice;

  const PaymentSuccess({
    required this.payment,
    required this.successMessage,
    this.generatedInvoice,
  });

  @override
  List<Object?> get props => [payment, successMessage, generatedInvoice];
}

/// Payment failed with error details
class PaymentError extends PaymentState {
  final String errorMessage;
  final PaymentErrorType errorType;
  final String? details;
  final PaymentTransaction? failedPayment;
  final bool canRetry;

  const PaymentError({
    required this.errorMessage,
    required this.errorType,
    this.details,
    this.failedPayment,
    this.canRetry = false,
  });

  @override
  List<Object?> get props => [errorMessage, errorType, details, failedPayment, canRetry];
}

/// Single payment loaded
class PaymentLoaded extends PaymentState {
  final PaymentTransaction payment;

  const PaymentLoaded(this.payment);

  @override
  List<Object> get props => [payment];
}

/// Real-time payments stream active
class PaymentsWatching extends PaymentState {
  final List<PaymentTransaction> currentPayments;
  final PaymentStatus? statusFilter;

  const PaymentsWatching({
    required this.currentPayments,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [currentPayments, statusFilter];
}

/// Payment BLoC implementation
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService _paymentService;
  final EnhancedEarningsService _earningsService;
  // final FirebaseAuth _auth; // TODO: Use for authentication
  
  StreamSubscription<List<PaymentTransaction>>? _paymentsSubscription;

  PaymentBloc({
    required PaymentService paymentService,
    required EnhancedEarningsService earningsService,
    FirebaseAuth? auth,
  }) : _paymentService = paymentService,
       _earningsService = earningsService,
       // _auth = auth ?? FirebaseAuth.instance, // TODO: Use for authentication
       super(const PaymentInitial()) {

    // Register event handlers
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
    on<ProcessSalaryPayment>(_onProcessSalaryPayment);
    on<ProcessExpenseReimbursement>(_onProcessExpenseReimbursement);
    on<CalculatePaymentAmount>(_onCalculatePaymentAmount);
    on<LoadPayment>(_onLoadPayment);
    on<UpdatePaymentStatus>(_onUpdatePaymentStatus);
    on<RetryPayment>(_onRetryPayment);
    on<WatchPayments>(_onWatchPayments);
  }

  /// Load payment history with filtering
  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistory event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Betalingsgeschiedenis laden...'));

    try {
      final payments = await _paymentService.getPaymentHistory(
        guardId: event.guardId,
        filterType: event.typeFilter,
        filterStatus: event.statusFilter,
      );

      emit(PaymentHistoryLoaded(
        payments: payments,
        appliedTypeFilter: event.typeFilter,
        appliedStatusFilter: event.statusFilter,
      ));

    } catch (e) {
      emit(PaymentError(
        errorMessage: _getLocalizedErrorMessage(e),
        errorType: _getErrorType(e),
        details: e.toString(),
        canRetry: true,
      ));
    }
  }

  /// Process salary payment using existing earnings data
  Future<void> _onProcessSalaryPayment(
    ProcessSalaryPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Salaris uitbetaling voorbereiden...'));

    try {
      // First calculate the payment to show user the details
      final calculation = await _paymentService.calculatePaymentAmount(
        guardId: event.guardId,
        type: PaymentType.salaryPayment,
        includeVakantiegeld: event.includeVakantiegeld,
      );

      // Get current earnings for context
      final earnings = await _earningsService.getEnhancedEarningsData();

      emit(PaymentCalculationCompleted(
        calculation: calculation,
        relatedEarnings: earnings,
      ));

      // Now process the actual payment
      emit(PaymentProcessing(
        payment: PaymentTransaction.fromEarningsData(
          guardId: event.guardId,
          earnings: earnings,
          type: PaymentType.salaryPayment,
          method: event.method,
          recipientIBAN: event.recipientIBAN,
          companyId: event.companyId,
        ),
        dutchStatusMessage: _getPaymentProcessingMessage(event.method),
      ));

      final payment = await _paymentService.processSalaryPayment(
        guardId: event.guardId,
        recipientIBAN: event.recipientIBAN,
        method: event.method,
        companyId: event.companyId,
        includeVakantiegeld: event.includeVakantiegeld,
      );

      emit(PaymentSuccess(
        payment: payment,
        successMessage: 'Salaris uitbetaling succesvol verwerkt: ${payment.dutchFormattedAmount}',
      ));

    } catch (e) {
      final error = e as PaymentException;
      emit(PaymentError(
        errorMessage: error.message,
        errorType: error.type,
        details: error.details,
        canRetry: _canRetryPayment(error.type),
      ));
    }
  }

  /// Process expense reimbursement
  Future<void> _onProcessExpenseReimbursement(
    ProcessExpenseReimbursement event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Onkosten vergoeding verwerken...'));

    try {
      final payment = await _paymentService.processExpenseReimbursement(
        guardId: event.guardId,
        amount: event.amount,
        description: event.description,
        companyId: event.companyId,
        metadata: event.metadata,
      );

      emit(PaymentProcessing(
        payment: payment,
        dutchStatusMessage: 'iDEAL betaling wordt verwerkt...',
      ));

      // Simulate payment completion (in real app, this would come from webhook)
      await Future.delayed(const Duration(seconds: 3));

      final completedPayment = payment.copyWith(
        status: PaymentStatus.completed,
        completedAt: DateTime.now(),
      );

      emit(PaymentSuccess(
        payment: completedPayment,
        successMessage: 'Onkosten vergoeding succesvol verwerkt: €${event.amount.toStringAsFixed(2)}',
      ));

    } catch (e) {
      final error = e as PaymentException;
      emit(PaymentError(
        errorMessage: error.message,
        errorType: error.type,
        canRetry: true,
      ));
    }
  }

  /// Calculate payment amount based on current earnings
  Future<void> _onCalculatePaymentAmount(
    CalculatePaymentAmount event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Betalingsbedrag berekenen...'));

    try {
      final calculation = await _paymentService.calculatePaymentAmount(
        guardId: event.guardId,
        type: event.type,
        includeVakantiegeld: event.includeVakantiegeld,
        applyBTWDeduction: event.applyBTWDeduction,
      );

      final earnings = await _earningsService.getEnhancedEarningsData();

      emit(PaymentCalculationCompleted(
        calculation: calculation,
        relatedEarnings: earnings,
      ));

    } catch (e) {
      emit(PaymentError(
        errorMessage: _getLocalizedErrorMessage(e),
        errorType: _getErrorType(e),
        canRetry: true,
      ));
    }
  }

  /// Load specific payment by ID
  Future<void> _onLoadPayment(
    LoadPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Betaling details laden...'));

    try {
      final payment = await _paymentService.getPayment(event.paymentId);
      
      if (payment != null) {
        emit(PaymentLoaded(payment));
      } else {
        emit(const PaymentError(
          errorMessage: 'Betaling niet gevonden',
          errorType: PaymentErrorType.networkError,
        ));
      }

    } catch (e) {
      emit(PaymentError(
        errorMessage: _getLocalizedErrorMessage(e),
        errorType: _getErrorType(e),
      ));
    }
  }

  /// Update payment status (typically from webhook)
  Future<void> _onUpdatePaymentStatus(
    UpdatePaymentStatus event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final payment = await _paymentService.getPayment(event.paymentId);
      
      if (payment != null) {
        final updatedPayment = payment.copyWith(
          status: event.newStatus,
          auditTrail: {
            ...payment.auditTrail,
            'statusUpdated': DateTime.now().toIso8601String(),
            'previousStatus': payment.status.name,
            'newStatus': event.newStatus.name,
            'updateSource': 'webhook',
            if (event.additionalData != null) ...event.additionalData!,
          },
        );

        if (event.newStatus == PaymentStatus.completed) {
          emit(PaymentSuccess(
            payment: updatedPayment,
            successMessage: 'Betaling succesvol voltooid: ${updatedPayment.dutchFormattedAmount}',
          ));
        } else if (event.newStatus == PaymentStatus.failed) {
          emit(PaymentError(
            errorMessage: 'Betaling mislukt',
            errorType: PaymentErrorType.paymentDeclined,
            failedPayment: updatedPayment,
            canRetry: true,
          ));
        } else {
          emit(PaymentProcessing(
            payment: updatedPayment,
            dutchStatusMessage: _getStatusMessage(event.newStatus),
          ));
        }
      }

    } catch (e) {
      emit(PaymentError(
        errorMessage: _getLocalizedErrorMessage(e),
        errorType: _getErrorType(e),
      ));
    }
  }

  /// Retry failed payment
  Future<void> _onRetryPayment(
    RetryPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Betaling opnieuw proberen...'));

    try {
      final payment = await _paymentService.getPayment(event.paymentId);
      
      if (payment == null) {
        emit(const PaymentError(
          errorMessage: 'Betaling niet gevonden voor opnieuw proberen',
          errorType: PaymentErrorType.networkError,
        ));
        return;
      }

      if (payment.retryCount >= 3) {
        emit(PaymentError(
          errorMessage: 'Maximum aantal pogingen bereikt voor betaling ${payment.reference}',
          errorType: PaymentErrorType.systemMaintenance,
          failedPayment: payment,
        ));
        return;
      }

      // Process retry based on original payment type
      if (payment.type == PaymentType.salaryPayment) {
        add(ProcessSalaryPayment(
          guardId: payment.guardId,
          recipientIBAN: payment.recipientIBAN!,
          method: payment.method,
          companyId: payment.companyId,
        ));
      } else if (payment.type == PaymentType.expenseReimbursement) {
        add(ProcessExpenseReimbursement(
          guardId: payment.guardId,
          amount: payment.grossAmount,
          description: payment.description,
          companyId: payment.companyId,
        ));
      }

    } catch (e) {
      emit(PaymentError(
        errorMessage: _getLocalizedErrorMessage(e),
        errorType: _getErrorType(e),
      ));
    }
  }

  /// Watch payments in real-time
  Future<void> _onWatchPayments(
    WatchPayments event,
    Emitter<PaymentState> emit,
  ) async {
    await _paymentsSubscription?.cancel();

    _paymentsSubscription = _paymentService.watchPayments(
      guardId: event.guardId,
      statusFilter: event.statusFilter,
    ).listen(
      (payments) {
        add(WatchPayments(
          guardId: event.guardId,
          statusFilter: event.statusFilter,
        ));
        emit(PaymentsWatching(
          currentPayments: payments,
          statusFilter: event.statusFilter,
        ));
      },
      onError: (error) {
        emit(PaymentError(
          errorMessage: 'Real-time betalingen stream mislukt: ${error.toString()}',
          errorType: PaymentErrorType.networkError,
        ));
      },
    );

    emit(PaymentsWatching(
      currentPayments: const [],
      statusFilter: event.statusFilter,
    ));
  }

  /// Get localized Dutch error message
  String _getLocalizedErrorMessage(dynamic error) {
    if (error is PaymentException) {
      return error.message;
    }
    
    switch (error.runtimeType.toString()) {
      case 'TimeoutException':
        return 'Verbindingstime-out. Probeer opnieuw.';
      case 'SocketException':
        return 'Geen internetverbinding. Controleer uw verbinding.';
      case 'FormatException':
        return 'Ongeldige gegevens ontvangen. Probeer opnieuw.';
      default:
        return 'Er is een onbekende fout opgetreden. Neem contact op met ondersteuning.';
    }
  }

  /// Get payment error type from exception
  PaymentErrorType _getErrorType(dynamic error) {
    if (error is PaymentException) {
      return error.type;
    }
    return PaymentErrorType.networkError;
  }

  /// Get payment processing message based on method
  String _getPaymentProcessingMessage(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.sepa:
        return 'SEPA overboeking wordt verwerkt...';
      case PaymentMethod.ideal:
        return 'iDEAL betaling wordt verwerkt...';
      case PaymentMethod.bankTransfer:
        return 'Bankoverschrijving wordt verwerkt...';
      default:
        return 'Betaling wordt verwerkt...';
    }
  }

  /// Get status message in Dutch
  String _getStatusMessage(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Betaling wacht op verwerking';
      case PaymentStatus.processing:
        return 'Betaling wordt verwerkt';
      case PaymentStatus.completed:
        return 'Betaling succesvol voltooid';
      case PaymentStatus.failed:
        return 'Betaling mislukt';
      case PaymentStatus.cancelled:
        return 'Betaling geannuleerd';
      case PaymentStatus.refunded:
        return 'Betaling terugbetaald';
      case PaymentStatus.notFound:
        return 'Betaling niet gevonden';
      case PaymentStatus.error:
        return 'Fout opgetreden';
      case PaymentStatus.unknown:
        return 'Onbekende status';
    }
  }

  /// Check if payment error can be retried
  bool _canRetryPayment(PaymentErrorType errorType) {
    switch (errorType) {
      case PaymentErrorType.networkError:
      case PaymentErrorType.bankUnavailable:
      case PaymentErrorType.systemMaintenance:
        return true;
      case PaymentErrorType.invalidIBAN:
      case PaymentErrorType.fraudSuspected:
      case PaymentErrorType.complianceViolation:
        return false;
      default:
        return true;
    }
  }

  @override
  Future<void> close() {
    _paymentsSubscription?.cancel();
    _paymentService.dispose();
    return super.close();
  }
}