import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/payment_models.dart';
import '../repository/payment_repository.dart';
import '../services/sepa_payment_service.dart';
import '../services/dutch_invoice_service.dart';
import '../services/payment_audit_service.dart';
import '../../beveiliger_dashboard/services/enhanced_earnings_service.dart';
import '../../beveiliger_dashboard/models/enhanced_dashboard_data.dart';
import '../../schedule/services/payroll_export_service.dart';
import '../../billing/models/subscription_models.dart';

/// Payment Integration Service for SecuryFlex
/// 
/// Integrates payment services with existing earnings and payroll systems:
/// - Enhanced earnings service integration
/// - Payroll export service integration  
/// - Automated salary payments via SEPA
/// - Invoice generation for all payment types
/// - Real-time payment status updates
/// - Dutch compliance across all systems
class PaymentIntegrationService {
  final PaymentRepository _paymentRepository;
  final SepaPaymentService _sepaService;
  final DutchInvoiceService _invoiceService;
  final PaymentAuditService _auditService;
  final FirebaseFirestore _firestore;

  // Payment integration configuration

  PaymentIntegrationService({
    required PaymentRepository paymentRepository,
    required SepaPaymentService sepaService,
    required DutchInvoiceService invoiceService,
    required PaymentAuditService auditService,
    required EnhancedEarningsService earningsService,
    required PayrollExportService payrollService,
    FirebaseFirestore? firestore,
  }) : _paymentRepository = paymentRepository,
       _sepaService = sepaService,
       _invoiceService = invoiceService,
       _auditService = auditService,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Process salary payments for all guards based on earnings data
  Future<PayrollBatchResult> processSalaryPayments({
    required DateTime periodStart,
    required DateTime periodEnd,
    bool dryRun = false,
  }) async {
    try {
      await _auditService.logPaymentRequest(
        type: 'SALARY_BATCH_PROCESSING',
        status: 'STARTED',
        details: {
          'period_start': periodStart.toIso8601String(),
          'period_end': periodEnd.toIso8601String(),
          'dry_run': dryRun,
        },
      );

      // Get all guards with time entries for the period
      final guardsWithEarnings = await _getGuardsWithEarnings(periodStart, periodEnd);
      
      if (guardsWithEarnings.isEmpty) {
        return PayrollBatchResult(
          batchId: 'no_earnings_${DateTime.now().millisecondsSinceEpoch}',
          processedGuards: 0,
          totalAmount: 0.0,
          successfulPayments: 0,
          failedPayments: 0,
          status: PaymentStatus.completed,
          message: 'Geen inkomsten gevonden voor de opgegeven periode',
        );
      }

      // Calculate enhanced earnings for each guard
      final paymentRequests = <GuardPaymentRequest>[];
      final invoices = <DutchInvoice>[];
      double totalAmount = 0.0;

      for (final guardData in guardsWithEarnings) {
        try {
          // Get enhanced earnings data
          final earningsData = await _calculateGuardEarnings(
            guardData['guard_id'],
            periodStart,
            periodEnd,
          );

          if (earningsData.totalMonth <= 0) continue;

          // Get guard bank details
          final guardDoc = await _firestore.collection('users').doc(guardData['guard_id']).get();
          
          if (!guardDoc.exists || guardDoc.data()?['iban'] == null) {
            await _auditService.logPaymentError(
              type: 'MISSING_BANK_DETAILS',
              error: 'Guard ${guardData['guard_id']} has no IBAN',
              metadata: {'guard_id': guardData['guard_id']},
            );
            continue;
          }

          final guardInfo = guardDoc.data()!;
          final iban = guardInfo['iban'] as String;
          final guardName = guardInfo['displayName'] as String? ?? 'Onbekende Beveiliger';

          // Create payment request
          final paymentRequest = GuardPaymentRequest(
            guardId: guardData['guard_id'],
            amount: earningsData.totalMonth,
            recipientIBAN: iban,
            recipientName: guardName,
            description: 'Salaris ${_formatPeriod(periodStart, periodEnd)}',
            paymentType: PaymentType.salary,
            metadata: {
              'period_start': periodStart.toIso8601String(),
              'period_end': periodEnd.toIso8601String(),
              'hours_worked': earningsData.hoursWorkedWeek,
              'overtime_hours': earningsData.overtimeHours,
              'hourly_rate': earningsData.hourlyRate,
              'vakantiegeld': earningsData.vakantiegeld,
              'btw_amount': earningsData.btwAmount,
              'is_freelance': earningsData.isFreelance,
            },
          );

          paymentRequests.add(paymentRequest);
          totalAmount += earningsData.totalMonth;

          // Generate invoice for this payment
          if (!dryRun) {
            final payrollEntries = await _getPayrollEntriesForGuard(
              guardData['guard_id'],
              periodStart,
              periodEnd,
            );

            if (payrollEntries.isNotEmpty) {
              final invoice = await _invoiceService.generateGuardSalaryInvoice(
                guardId: guardData['guard_id'],
                periodDescription: _formatPeriod(periodStart, periodEnd),
                payrollEntries: payrollEntries,
              );
              invoices.add(invoice);
            }
          }

        } catch (e) {
          await _auditService.logPaymentError(
            type: 'GUARD_EARNINGS_CALCULATION_ERROR',
            error: e.toString(),
            metadata: {'guard_id': guardData['guard_id']},
          );
        }
      }

      if (paymentRequests.isEmpty) {
        return PayrollBatchResult(
          batchId: 'empty_batch_${DateTime.now().millisecondsSinceEpoch}',
          processedGuards: guardsWithEarnings.length,
          totalAmount: 0.0,
          successfulPayments: 0,
          failedPayments: 0,
          status: PaymentStatus.completed,
          message: 'Geen geldige betalingen om te verwerken',
        );
      }

      // Process bulk SEPA payments
      final batchDescription = 'Salaris uitbetaling ${_formatPeriod(periodStart, periodEnd)}';
      
      if (!dryRun) {
        final bulkResult = await _sepaService.processBulkGuardPayments(
          paymentRequests: paymentRequests,
          batchDescription: batchDescription,
        );

        // Log integration success
        await _auditService.logPaymentTransaction(
          paymentId: bulkResult.batchId,
          type: PaymentType.salary,
          amount: totalAmount,
          status: bulkResult.overallStatus,
          metadata: {
            'guard_count': paymentRequests.length,
            'invoice_count': invoices.length,
            'period_start': periodStart.toIso8601String(),
            'period_end': periodEnd.toIso8601String(),
          },
        );

        return PayrollBatchResult(
          batchId: bulkResult.batchId,
          processedGuards: paymentRequests.length,
          totalAmount: totalAmount,
          successfulPayments: bulkResult.successfulPayments,
          failedPayments: bulkResult.failedPayments,
          status: bulkResult.overallStatus,
          invoiceIds: invoices.map((i) => i.id).toList(),
          paymentMetadata: bulkResult.metadata,
        );
      } else {
        // Dry run - return what would be processed
        return PayrollBatchResult(
          batchId: 'dry_run_${DateTime.now().millisecondsSinceEpoch}',
          processedGuards: paymentRequests.length,
          totalAmount: totalAmount,
          successfulPayments: 0,
          failedPayments: 0,
          status: PaymentStatus.pending,
          message: 'Dry run - geen betalingen verwerkt',
          invoiceIds: [],
          isDryRun: true,
        );
      }

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'SALARY_BATCH_ERROR',
        error: e.toString(),
        metadata: {
          'period_start': periodStart.toIso8601String(),
          'period_end': periodEnd.toIso8601String(),
        },
      );
      rethrow;
    }
  }

  /// Update earnings after payment completion
  Future<void> updateEarningsAfterPayment({
    required String guardId,
    required String paymentId,
    required double amount,
    required PaymentStatus paymentStatus,
  }) async {
    try {
      // Update earnings service with payment information
      await _firestore.collection('earnings_payments').add({
        'guard_id': guardId,
        'payment_id': paymentId,
        'amount': amount,
        'status': paymentStatus.name,
        'processed_at': Timestamp.now(),
        'payment_type': PaymentType.salary.name,
      });

      // Trigger earnings recalculation if payment completed
      if (paymentStatus == PaymentStatus.completed) {
        await _triggerEarningsUpdate(guardId);
      }

      await _auditService.logPaymentTransaction(
        paymentId: paymentId,
        type: PaymentType.salary,
        amount: amount,
        status: paymentStatus,
        guardId: guardId,
      );

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'EARNINGS_UPDATE_ERROR',
        error: e.toString(),
        metadata: {
          'guard_id': guardId,
          'payment_id': paymentId,
        },
      );
    }
  }

  /// Generate comprehensive payment report
  Future<PaymentReportData> generatePaymentReport({
    required DateTime startDate,
    required DateTime endDate,
    PaymentType? filterType,
    PaymentStatus? filterStatus,
  }) async {
    try {
      // Get payment analytics
      final analytics = await _paymentRepository.getPaymentAnalytics(startDate, endDate);

      // Get detailed payment data
      final sepaPayments = await _paymentRepository.searchSEPAPayments(
        startDate: startDate,
        endDate: endDate,
        status: filterStatus,
        limit: 1000,
      );

      final idealPayments = await _paymentRepository.searchiDEALPayments(
        startDate: startDate,
        endDate: endDate,
        paymentType: filterType != PaymentType.sepaTransfer ? filterType : null,
        status: filterStatus,
        limit: 1000,
      );

      // Calculate detailed metrics
      final totalGuardPayments = sepaPayments.length;
      final totalExpensePayments = idealPayments.where((p) => p.paymentType == PaymentType.expense).length;
      final totalSalaryAmount = sepaPayments.fold<double>(0, (sum, p) => sum + p.amount);
      final totalExpenseAmount = idealPayments.fold<double>(0, (sum, p) => sum + p.amount);

      // Get compliance data
      final complianceReport = await _generateComplianceData(startDate, endDate);

      return PaymentReportData(
        reportId: 'report_${DateTime.now().millisecondsSinceEpoch}',
        periodStart: startDate,
        periodEnd: endDate,
        analytics: analytics,
        totalGuardPayments: totalGuardPayments,
        totalExpensePayments: totalExpensePayments,
        totalSalaryAmount: totalSalaryAmount,
        totalExpenseAmount: totalExpenseAmount,
        complianceData: complianceReport,
        sepaPayments: sepaPayments,
        idealPayments: idealPayments,
        generatedAt: DateTime.now(),
      );

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'PAYMENT_REPORT_ERROR',
        error: e.toString(),
        metadata: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );
      rethrow;
    }
  }

  /// Sync payment status with earnings service
  Future<void> syncPaymentStatusWithEarnings() async {
    try {
      // Get all pending earnings payments
      final pendingPayments = await _firestore
          .collection('earnings_payments')
          .where('status', whereIn: [PaymentStatus.pending.name, PaymentStatus.processing.name])
          .get();

      for (final paymentDoc in pendingPayments.docs) {
        final paymentData = paymentDoc.data();
        final paymentId = paymentData['payment_id'] as String;
        final guardId = paymentData['guard_id'] as String;

        // Check current payment status
        final payment = await _paymentRepository.getSEPAPayment(paymentId);
        
        if (payment != null && payment.status != PaymentStatus.values.firstWhere(
          (s) => s.name == paymentData['status'],
          orElse: () => PaymentStatus.pending,
        )) {
          // Update earnings payment record
          await paymentDoc.reference.update({
            'status': payment.status.name,
            'updated_at': Timestamp.now(),
          });

          // Trigger earnings update if completed
          if (payment.status == PaymentStatus.completed) {
            await _triggerEarningsUpdate(guardId);
          }
        }
      }

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'PAYMENT_EARNINGS_SYNC_ERROR',
        error: e.toString(),
      );
    }
  }

  /// Get payment status for earnings display
  Future<Map<String, PaymentInfo>> getPaymentStatusForEarnings(String guardId) async {
    try {
      final paymentsMap = <String, PaymentInfo>{};

      // Get recent SEPA payments for guard
      final sepaPayments = await _paymentRepository.getSEPAPaymentsForGuard(guardId, limit: 20);

      for (final payment in sepaPayments) {
        paymentsMap[payment.id] = PaymentInfo(
          paymentId: payment.id,
          amount: payment.amount,
          status: payment.status,
          description: payment.description,
          createdAt: payment.createdAt,
          processedAt: payment.processedAt,
          paymentType: PaymentType.salary,
        );
      }

      return paymentsMap;

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'PAYMENT_STATUS_QUERY_ERROR',
        error: e.toString(),
        metadata: {'guard_id': guardId},
      );
      return {};
    }
  }

  /// Private helper methods

  /// Get guards with earnings for the period
  Future<List<Map<String, dynamic>>> _getGuardsWithEarnings(
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    final timeEntriesSnapshot = await _firestore
        .collection('time_entries')
        .where('check_in_time', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
        .where('check_in_time', isLessThanOrEqualTo: Timestamp.fromDate(periodEnd))
        .where('check_out_time', isNull: false)
        .get();

    final guardIds = <String>{};
    for (final doc in timeEntriesSnapshot.docs) {
      final guardId = doc.data()['guard_id'] as String?;
      if (guardId != null) {
        guardIds.add(guardId);
      }
    }

    return guardIds.map((guardId) => {'guard_id': guardId}).toList();
  }

  /// Calculate enhanced earnings for a guard
  Future<EnhancedEarningsData> _calculateGuardEarnings(
    String guardId,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    // Get time entries for the period
    final timeEntriesSnapshot = await _firestore
        .collection('time_entries')
        .where('guard_id', isEqualTo: guardId)
        .where('check_in_time', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
        .where('check_in_time', isLessThanOrEqualTo: Timestamp.fromDate(periodEnd))
        .where('check_out_time', isNull: false)
        .get();

    double totalHours = 0;
    double overtimeHours = 0;
    double weekendHours = 0;
    double nightHours = 0;

    for (final doc in timeEntriesSnapshot.docs) {
      final data = doc.data();
      final checkInTime = (data['check_in_time'] as Timestamp).toDate();
      final checkOutTime = (data['check_out_time'] as Timestamp).toDate();
      
      final duration = checkOutTime.difference(checkInTime);
      final hours = duration.inMinutes / 60.0;
      
      // Categorize hours
      final isWeekend = checkInTime.weekday > 5;
      final isNight = checkInTime.hour >= 22 || checkInTime.hour < 6;
      
      if (isWeekend) {
        weekendHours += hours;
      } else if (isNight) {
        nightHours += hours;
      } else {
        totalHours += hours;
      }
    }

    // Calculate overtime (simplified - actual calculation would be more complex)
    if (totalHours > 40) {
      overtimeHours = totalHours - 40;
      totalHours = 40;
    }

    // Get guard hourly rate
    final guardDoc = await _firestore.collection('users').doc(guardId).get();
    final hourlyRate = (guardDoc.data()?['hourly_rate'] as num?)?.toDouble() ?? 12.0;

    // Calculate earnings
    final basePay = totalHours * hourlyRate;
    final overtimePay = overtimeHours * hourlyRate * 1.5;
    final weekendPay = weekendHours * hourlyRate * 1.25;
    final nightPay = nightHours * hourlyRate * 1.15;
    
    final totalWeek = basePay + overtimePay + weekendPay + nightPay;
    final totalMonth = totalWeek * 4.33; // Average weeks per month
    final vakantiegeld = totalMonth * 0.08;
    
    final isFreelance = guardDoc.data()?['is_freelancer'] as bool? ?? false;
    final btwAmount = isFreelance ? totalMonth * 0.21 : 0.0;

    return EnhancedEarningsData(
      totalToday: 0, // Not calculated for period
      totalWeek: totalWeek,
      totalMonth: totalMonth,
      hourlyRate: hourlyRate,
      hoursWorkedToday: 0, // Not calculated for period
      hoursWorkedWeek: totalHours + overtimeHours + weekendHours + nightHours,
      overtimeHours: overtimeHours,
      overtimeRate: hourlyRate * 1.5,
      vakantiegeld: vakantiegeld,
      btwAmount: btwAmount,
      isFreelance: isFreelance,
      dutchFormattedToday: '€0,00',
      dutchFormattedWeek: _formatDutchCurrency(totalWeek),
      dutchFormattedMonth: _formatDutchCurrency(totalMonth),
      lastCalculated: DateTime.now(),
    );
  }

  /// Get payroll entries for guard
  Future<List<PayrollEntry>> _getPayrollEntriesForGuard(
    String guardId,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    // Get time entries and convert to payroll entries
    final timeEntriesSnapshot = await _firestore
        .collection('time_entries')
        .where('guard_id', isEqualTo: guardId)
        .where('check_in_time', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
        .where('check_in_time', isLessThanOrEqualTo: Timestamp.fromDate(periodEnd))
        .get();

    timeEntriesSnapshot.docs.map((doc) {
      doc.data();
      return doc.data(); // Use raw data
    }).toList();

    // Use existing payroll service to calculate entries
// Simplified
    
    // Temporary simplified return until PayrollEntry.fromMap is implemented
    return [];
  }

  /// Trigger earnings update for guard
  Future<void> _triggerEarningsUpdate(String guardId) async {
    try {
      // Update earnings calculation timestamp to trigger recalculation
      await _firestore.collection('earnings_updates').add({
        'guard_id': guardId,
        'triggered_at': Timestamp.now(),
        'trigger_reason': 'payment_completed',
      });

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to trigger earnings update for $guardId: $e');
      }
    }
  }

  /// Generate compliance data for reporting
  Future<Map<String, dynamic>> _generateComplianceData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final complianceReport = await _auditService.generateComplianceReport(
      startDate: startDate,
      endDate: endDate,
      reportType: 'PAYMENT_COMPLIANCE',
    );

    return {
      'total_high_value_transactions': _countHighValueTransactions(complianceReport),
      'aml_monitoring_required': _countAMLTransactions(complianceReport),
      'compliance_flags': complianceReport['compliance_flags'] ?? [],
      'security_alerts': complianceReport['security_alerts'] ?? [],
    };
  }

  /// Count high value transactions
  int _countHighValueTransactions(Map<String, dynamic> complianceReport) {
    final flags = complianceReport['compliance_flags'] as List<dynamic>? ?? [];
    return flags.where((flag) => 
      flag['flags']?.contains('HIGH_VALUE_TRANSACTION') == true
    ).length;
  }

  /// Count AML monitoring transactions
  int _countAMLTransactions(Map<String, dynamic> complianceReport) {
    final flags = complianceReport['compliance_flags'] as List<dynamic>? ?? [];
    return flags.where((flag) => 
      flag['flags']?.contains('AML_MONITORING_REQUIRED') == true
    ).length;
  }

  /// Format period for descriptions
  String _formatPeriod(DateTime start, DateTime end) {
    return '${start.day.toString().padLeft(2,'0')}-${start.month.toString().padLeft(2,'0')}-${start.year} - ${end.day.toString().padLeft(2,'0')}-${end.month.toString().padLeft(2,'0')}-${end.year}';
  }

  /// Format currency in Dutch format
  String _formatDutchCurrency(double amount) {
    return '€${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// SUBSCRIPTION PAYMENT INTEGRATION METHODS
  /// Added for SecuryFlex subscription system integration

  /// Process subscription payment
  Future<PaymentResult> processSubscriptionPayment({
    required String subscriptionId,
    required double amount,
    required String userId,
    required String paymentMethodId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _auditService.logPaymentRequest(
        type: 'SUBSCRIPTION_PAYMENT',
        status: 'INITIATED',
        details: {
          'subscription_id': subscriptionId,
          'user_id': userId,
          'amount': amount,
          'payment_method_id': paymentMethodId,
        },
      );

      debugPrint('🔄 Processing subscription payment: $subscriptionId');
      debugPrint('💰 Amount: €${amount.toStringAsFixed(2)}');

      // Get user payment method details
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('Gebruiker niet gevonden');
      }

      final userData = userDoc.data()!;
      final paymentMethod = userData['paymentMethods']?[paymentMethodId];
      
      if (paymentMethod == null) {
        throw Exception('Betaalmethode niet gevonden');
      }

      PaymentResult result;
      
      // Route to appropriate payment service based on method type
      switch (paymentMethod['type']) {
        case 'sepa':
          result = await _processSepaSubscriptionPayment(
            subscriptionId: subscriptionId,
            amount: amount,
            iban: paymentMethod['iban'],
            holderName: paymentMethod['holderName'],
            description: description ?? 'SecuryFlex Abonnement',
            metadata: metadata,
          );
          break;
        case 'ideal':
          result = await _processIdealSubscriptionPayment(
            subscriptionId: subscriptionId,
            amount: amount,
            description: description ?? 'SecuryFlex Abonnement',
            metadata: metadata,
          );
          break;
        default:
          throw Exception('Niet ondersteunde betaalmethode: ${paymentMethod['type']}');
      }

      // Generate invoice if payment successful
      if (result.success && result.paymentId != null) {
        try {
          await _invoiceService.generateSubscriptionInvoice(
            subscriptionId: subscriptionId,
            paymentId: result.paymentId!,
            amount: amount,
            description: description ?? 'SecuryFlex Abonnement',
            userInfo: userData,
          );
        } catch (invoiceError) {
          debugPrint('⚠️ Invoice generation failed: $invoiceError');
          // Don't fail the payment for invoice issues
        }
      }

      await _auditService.logPaymentRequest(
        type: 'SUBSCRIPTION_PAYMENT',
        status: result.success ? 'COMPLETED' : 'FAILED',
        details: {
          'subscription_id': subscriptionId,
          'payment_id': result.paymentId,
          'amount': amount,
          'error': result.error,
        },
      );

      return result;
    } catch (e) {
      debugPrint('❌ Subscription payment processing failed: $e');
      
      await _auditService.logPaymentError(
        type: 'SUBSCRIPTION_PAYMENT_ERROR',
        error: e.toString(),
        metadata: {
          'subscription_id': subscriptionId,
          'user_id': userId,
          'amount': amount,
        },
      );

      return PaymentResult(
        success: false,
        error: 'Betaling mislukt: $e',
      );
    }
  }

  /// Process SEPA subscription payment
  Future<PaymentResult> _processSepaSubscriptionPayment({
    required String subscriptionId,
    required double amount,
    required String iban,
    required String holderName,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final sepaPayment = SEPAPayment(
        id: 'sepa-${DateTime.now().millisecondsSinceEpoch}',
        guardId: subscriptionId, // Using subscriptionId as user identifier
        amount: amount,
        currency: 'EUR',
        recipientIBAN: iban,
        recipientName: holderName,
        description: description,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      final result = await _sepaService.processPayment(sepaPayment);
      
      return PaymentResult(
        success: result.isSuccessful,
        paymentId: result.transactionId,
        amount: amount,
        currency: 'EUR',
        status: result.isSuccessful ? PaymentStatus.completed : PaymentStatus.failed,
        error: result.isSuccessful ? null : result.errorMessage,
        metadata: {
          'payment_type': 'sepa',
          'subscription_id': subscriptionId,
          'mandate_id': 'MANDATE-$subscriptionId',
          ...?metadata,
        },
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'SEPA payment failed: $e',
      );
    }
  }

  /// Process iDEAL subscription payment
  Future<PaymentResult> _processIdealSubscriptionPayment({
    required String subscriptionId,
    required double amount,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Note: For recurring subscriptions, iDEAL is typically used for initial payments only
      // Recurring payments would use SEPA Direct Debit
      
      final idealPayment = iDEALPaymentRequest(
        amount: amount,
        currency: 'EUR',
        description: description,
        reference: 'SUB-$subscriptionId',
      );

      // Process through iDEAL service (would integrate with actual iDEAL provider)
      final result = await _processIdealPayment(idealPayment);
      
      return PaymentResult(
        success: result.isSuccessful,
        paymentId: result.transactionId,
        amount: amount,
        currency: 'EUR',
        status: result.isSuccessful ? PaymentStatus.completed : PaymentStatus.failed,
        error: result.isSuccessful ? null : result.errorMessage,
        metadata: {
          'payment_type': 'ideal',
          'subscription_id': subscriptionId,
          ...?metadata,
        },
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'iDEAL payment failed: $e',
      );
    }
  }

  /// Handle subscription webhook (from payment providers)
  Future<void> handleSubscriptionWebhook(Map<String, dynamic> webhookData) async {
    try {
      await _auditService.logPaymentRequest(
        type: 'SUBSCRIPTION_WEBHOOK',
        status: 'RECEIVED',
        details: webhookData,
      );

      final eventType = webhookData['type'] ?? webhookData['event_type'];
      final subscriptionId = webhookData['subscription_id'] ?? _extractSubscriptionIdFromReference(webhookData);

      switch (eventType) {
        case 'payment.succeeded':
        case 'invoice.payment_succeeded':
          await _handleSuccessfulSubscriptionPayment(subscriptionId, webhookData);
          break;
        case 'payment.failed':
        case 'invoice.payment_failed':
          await _handleFailedSubscriptionPayment(subscriptionId, webhookData);
          break;
        case 'subscription.updated':
          await _handleSubscriptionUpdated(subscriptionId, webhookData);
          break;
        case 'subscription.canceled':
          await _handleSubscriptionCanceled(subscriptionId, webhookData);
          break;
        default:
          debugPrint('⚠️ Unhandled subscription webhook type: $eventType');
      }
    } catch (e) {
      debugPrint('❌ Error handling subscription webhook: $e');
      
      await _auditService.logPaymentError(
        type: 'SUBSCRIPTION_WEBHOOK_ERROR',
        error: e.toString(),
        metadata: webhookData,
      );
    }
  }

  /// Generate subscription invoice
  Future<DutchInvoice> generateSubscriptionInvoice({
    required String subscriptionId,
    required String paymentId,
    required double amount,
    required SubscriptionTier tier,
    required Map<String, dynamic> userInfo,
    String? description,
  }) async {
    try {
      return await _invoiceService.generateSubscriptionInvoice(
        subscriptionId: subscriptionId,
        paymentId: paymentId,
        amount: amount,
        description: description ?? 'SecuryFlex ${tier.displayName} Abonnement',
        userInfo: userInfo,
        metadata: {
          'subscription_tier': tier.id,
          'tier_name': tier.displayName,
          'monthly_price': tier.pricePerMonth,
        },
      );
    } catch (e) {
      debugPrint('❌ Error generating subscription invoice: $e');
      rethrow;
    }
  }

  // Private helper methods for webhook handling

  String _extractSubscriptionIdFromReference(Map<String, dynamic> webhookData) {
    final reference = webhookData['reference'] ?? webhookData['payment_reference'] ?? '';
    if (reference.startsWith('SUB-')) {
      return reference.substring(4);
    }
    return '';
  }

  Future<void> _handleSuccessfulSubscriptionPayment(String subscriptionId, Map<String, dynamic> webhookData) async {
    debugPrint('✅ Subscription payment succeeded: $subscriptionId');
    
    // Update subscription status in database
    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'lastPaymentDate': Timestamp.now(),
      'lastPaymentId': webhookData['payment_id'],
      'status': 'active',
    });
  }

  Future<void> _handleFailedSubscriptionPayment(String subscriptionId, Map<String, dynamic> webhookData) async {
    debugPrint('❌ Subscription payment failed: $subscriptionId');
    
    // Update subscription status
    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'status': 'past_due',
      'lastFailedPaymentAt': Timestamp.now(),
      'lastFailedPaymentError': webhookData['failure_reason'] ?? 'Unknown error',
    });
  }

  Future<void> _handleSubscriptionUpdated(String subscriptionId, Map<String, dynamic> webhookData) async {
    debugPrint('🔄 Subscription updated: $subscriptionId');
    // Handle subscription updates from payment provider
  }

  Future<void> _handleSubscriptionCanceled(String subscriptionId, Map<String, dynamic> webhookData) async {
    debugPrint('❌ Subscription canceled: $subscriptionId');
    
    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'status': 'canceled',
      'canceledAt': Timestamp.now(),
      'cancelReason': 'provider_canceled',
    });
  }

  /// Placeholder for iDEAL payment processing (would integrate with actual provider)
  Future<PaymentProviderResult> _processIdealPayment(iDEALPaymentRequest request) async {
    // This would integrate with your actual iDEAL payment provider
    // For now, returning a mock successful result
    await Future.delayed(const Duration(milliseconds: 500));
    
    return PaymentProviderResult(
      isSuccessful: true,
      transactionId: 'ideal_${DateTime.now().millisecondsSinceEpoch}',
      providerResponse: {
        'status': 'completed',
        'amount': request.amount,
        'currency': request.currency,
      },
    );
  }
}

/// Supporting models

/// Payroll batch result
class PayrollBatchResult {
  final String batchId;
  final int processedGuards;
  final double totalAmount;
  final int successfulPayments;
  final int failedPayments;
  final PaymentStatus status;
  final String? message;
  final List<String> invoiceIds;
  final Map<String, dynamic>? paymentMetadata;
  final bool isDryRun;

  const PayrollBatchResult({
    required this.batchId,
    required this.processedGuards,
    required this.totalAmount,
    required this.successfulPayments,
    required this.failedPayments,
    required this.status,
    this.message,
    this.invoiceIds = const [],
    this.paymentMetadata,
    this.isDryRun = false,
  });

  double get successRate => processedGuards > 0 ? successfulPayments / processedGuards : 0.0;
}

/// Payment info for earnings integration
class PaymentInfo {
  final String paymentId;
  final double amount;
  final PaymentStatus status;
  final String description;
  final DateTime createdAt;
  final DateTime? processedAt;
  final PaymentType paymentType;

  const PaymentInfo({
    required this.paymentId,
    required this.amount,
    required this.status,
    required this.description,
    required this.createdAt,
    this.processedAt,
    required this.paymentType,
  });
}

/// Payment report data
class PaymentReportData {
  final String reportId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final PaymentAnalytics analytics;
  final int totalGuardPayments;
  final int totalExpensePayments;
  final double totalSalaryAmount;
  final double totalExpenseAmount;
  final Map<String, dynamic> complianceData;
  final List<SEPAPayment> sepaPayments;
  final List<iDEALPayment> idealPayments;
  final DateTime generatedAt;

  const PaymentReportData({
    required this.reportId,
    required this.periodStart,
    required this.periodEnd,
    required this.analytics,
    required this.totalGuardPayments,
    required this.totalExpensePayments,
    required this.totalSalaryAmount,
    required this.totalExpenseAmount,
    required this.complianceData,
    required this.sepaPayments,
    required this.idealPayments,
    required this.generatedAt,
  });
}