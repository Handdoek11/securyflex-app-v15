import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_models.dart';
import '../services/payment_audit_service.dart';

/// Abstract payment repository interface
abstract class PaymentRepository {
  // SEPA Payments
  Future<void> storeSEPAPayment(SEPAPayment payment);
  Future<SEPAPayment?> getSEPAPayment(String paymentId);
  Future<List<SEPAPayment>> getSEPAPaymentsForGuard(String guardId, {int limit = 50});
  Future<List<SEPAPayment>> getBulkSEPAPayments(String batchId);
  Future<void> updateSEPAPaymentStatus(String paymentId, PaymentStatus status, {Map<String, dynamic>? metadata});

  // iDEAL Payments
  Future<void> storeiDEALPayment(iDEALPayment payment);
  Future<iDEALPayment?> getiDEALPayment(String paymentId);
  Future<List<iDEALPayment>> getiDEALPaymentsForUser(String userId, {int limit = 50});
  Future<void> updateiDEALPaymentStatus(String paymentId, PaymentStatus status, {Map<String, dynamic>? metadata});

  // Invoices
  Future<void> storeInvoice(DutchInvoice invoice);
  Future<DutchInvoice?> getInvoice(String invoiceId);
  Future<List<DutchInvoice>> getInvoicesForPeriod(DateTime startDate, DateTime endDate, {PaymentStatus? status, int limit = 100});
  Future<void> updateInvoicePaymentStatus(String invoiceId, PaymentStatus status, {String? paymentReference});

  // Analytics & Reporting
  Future<PaymentAnalytics> getPaymentAnalytics(DateTime startDate, DateTime endDate);
  Future<List<DailyPaymentSummary>> getDailyPaymentSummaries(DateTime startDate, DateTime endDate);
  
  // Search & Filtering
  Future<List<SEPAPayment>> searchSEPAPayments({
    String? guardId,
    String? batchId,
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int limit = 50,
  });
  
  Future<List<iDEALPayment>> searchiDEALPayments({
    String? userId,
    PaymentType? paymentType,
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int limit = 50,
  });

  // Real-time streams
  Stream<PaymentStatusUpdate> getPaymentStatusUpdates(String paymentId);
  Stream<List<SEPAPayment>> watchSEPAPaymentsForGuard(String guardId);
  Stream<List<iDEALPayment>> watchiDEALPaymentsForUser(String userId);
}

/// Firestore implementation of PaymentRepository
class FirestorePaymentRepository implements PaymentRepository {
  final FirebaseFirestore _firestore;
  final PaymentAuditService _auditService;

  FirestorePaymentRepository({
    FirebaseFirestore? firestore,
    PaymentAuditService? auditService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditService = auditService ?? PaymentAuditService();

  // SEPA Payment methods

  @override
  Future<void> storeSEPAPayment(SEPAPayment payment) async {
    try {
      await _firestore.collection('sepa_payments').doc(payment.id).set({
        'id': payment.id,
        'batch_id': payment.batchId,
        'guard_id': payment.guardId,
        'amount': payment.amount,
        'currency': payment.currency,
        'recipient_iban': payment.recipientIBAN,
        'recipient_name': payment.recipientName,
        'description': payment.description,
        'status': payment.status.name,
        'created_at': Timestamp.fromDate(payment.createdAt),
        'processed_at': payment.processedAt != null ? Timestamp.fromDate(payment.processedAt!) : null,
        'transaction_id': payment.transactionId,
        'failure_reason': payment.failureReason,
        'metadata': payment.metadata,
        'updated_at': Timestamp.now(),
      });

      await _auditService.logPaymentTransaction(
        paymentId: payment.id,
        type: PaymentType.sepaTransfer,
        amount: payment.amount,
        status: payment.status,
        guardId: payment.guardId,
      );

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'SEPA_STORAGE_ERROR',
        error: e.toString(),
        metadata: {'payment_id': payment.id},
      );
      rethrow;
    }
  }

  @override
  Future<SEPAPayment?> getSEPAPayment(String paymentId) async {
    try {
      final doc = await _firestore.collection('sepa_payments').doc(paymentId).get();
      
      if (!doc.exists) return null;
      
      return _sepaPaymentFromFirestore(doc);

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'SEPA_RETRIEVAL_ERROR',
        error: e.toString(),
        metadata: {'payment_id': paymentId},
      );
      return null;
    }
  }

  @override
  Future<List<SEPAPayment>> getSEPAPaymentsForGuard(String guardId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('sepa_payments')
          .where('guard_id', isEqualTo: guardId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => _sepaPaymentFromFirestore(doc)).toList();

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'SEPA_GUARD_QUERY_ERROR',
        error: e.toString(),
        metadata: {'guard_id': guardId},
      );
      return [];
    }
  }

  @override
  Future<List<SEPAPayment>> getBulkSEPAPayments(String batchId) async {
    try {
      final snapshot = await _firestore
          .collection('sepa_payments')
          .where('batch_id', isEqualTo: batchId)
          .orderBy('created_at', descending: false)
          .get();

      return snapshot.docs.map((doc) => _sepaPaymentFromFirestore(doc)).toList();

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'BULK_SEPA_QUERY_ERROR',
        error: e.toString(),
        metadata: {'batch_id': batchId},
      );
      return [];
    }
  }

  @override
  Future<void> updateSEPAPaymentStatus(
    String paymentId, 
    PaymentStatus status, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updated_at': Timestamp.now(),
      };

      if (status == PaymentStatus.completed || status == PaymentStatus.failed) {
        updates['processed_at'] = Timestamp.now();
      }

      if (metadata != null) {
        updates['metadata'] = FieldValue.arrayUnion([metadata]);
      }

      await _firestore.collection('sepa_payments').doc(paymentId).update(updates);

      await _auditService.logPaymentTransaction(
        paymentId: paymentId,
        type: PaymentType.sepaTransfer,
        amount: 0, // Amount not available in update context
        status: status,
      );

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'SEPA_STATUS_UPDATE_ERROR',
        error: e.toString(),
        metadata: {'payment_id': paymentId, 'new_status': status.name},
      );
      rethrow;
    }
  }

  // iDEAL Payment methods

  @override
  Future<void> storeiDEALPayment(iDEALPayment payment) async {
    try {
      await _firestore.collection('ideal_payments').doc(payment.id).set({
        'id': payment.id,
        'user_id': payment.userId,
        'amount': payment.amount,
        'currency': payment.currency,
        'description': payment.description,
        'payment_type': payment.paymentType.name,
        'status': payment.status.name,
        'return_url': payment.returnUrl,
        'webhook_url': payment.webhookUrl,
        'checkout_url': payment.checkoutUrl,
        'provider_payment_id': payment.providerPaymentId,
        'selected_bank_bic': payment.selectedBankBIC,
        'created_at': Timestamp.fromDate(payment.createdAt),
        'completed_at': payment.completedAt != null ? Timestamp.fromDate(payment.completedAt!) : null,
        'expires_at': payment.expiresAt != null ? Timestamp.fromDate(payment.expiresAt!) : null,
        'metadata': payment.metadata,
        'updated_at': Timestamp.now(),
      });

      await _auditService.logPaymentTransaction(
        paymentId: payment.id,
        type: payment.paymentType,
        amount: payment.amount,
        status: payment.status,
        userId: payment.userId,
      );

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'IDEAL_STORAGE_ERROR',
        error: e.toString(),
        metadata: {'payment_id': payment.id},
      );
      rethrow;
    }
  }

  @override
  Future<iDEALPayment?> getiDEALPayment(String paymentId) async {
    try {
      final doc = await _firestore.collection('ideal_payments').doc(paymentId).get();
      
      if (!doc.exists) return null;
      
      return _idealPaymentFromFirestore(doc);

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'IDEAL_RETRIEVAL_ERROR',
        error: e.toString(),
        metadata: {'payment_id': paymentId},
      );
      return null;
    }
  }

  @override
  Future<List<iDEALPayment>> getiDEALPaymentsForUser(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('ideal_payments')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => _idealPaymentFromFirestore(doc)).toList();

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'IDEAL_USER_QUERY_ERROR',
        error: e.toString(),
        metadata: {'user_id': userId},
      );
      return [];
    }
  }

  @override
  Future<void> updateiDEALPaymentStatus(
    String paymentId,
    PaymentStatus status, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updated_at': Timestamp.now(),
      };

      if (status == PaymentStatus.completed) {
        updates['completed_at'] = Timestamp.now();
      }

      if (metadata != null) {
        updates.addAll(metadata);
      }

      await _firestore.collection('ideal_payments').doc(paymentId).update(updates);

      await _auditService.logPaymentTransaction(
        paymentId: paymentId,
        type: PaymentType.idealPayment,
        amount: 0, // Amount not available in update context
        status: status,
      );

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'IDEAL_STATUS_UPDATE_ERROR',
        error: e.toString(),
        metadata: {'payment_id': paymentId, 'new_status': status.name},
      );
      rethrow;
    }
  }

  // Invoice methods

  @override
  Future<void> storeInvoice(DutchInvoice invoice) async {
    try {
      await _firestore.collection('invoices').doc(invoice.id).set({
        'id': invoice.id,
        'invoice_number': invoice.invoiceNumber,
        'company_name': invoice.companyName,
        'company_kvk': invoice.companyKvK,
        'company_btw': invoice.companyBTW,
        'company_address': invoice.companyAddress,
        'client_name': invoice.clientName,
        'client_address': invoice.clientAddress,
        'invoice_date': Timestamp.fromDate(invoice.invoiceDate),
        'due_date': Timestamp.fromDate(invoice.dueDate),
        'line_items': invoice.lineItems.map((item) => {
          'description': item.description,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'btw_rate': item.btwRate,
          'total_excl_btw': item.totalExclBTW,
          'btw_amount': item.btwAmount,
          'total_incl_btw': item.totalInclBTW,
        }).toList(),
        'subtotal': invoice.subtotal,
        'btw_amount': invoice.btwAmount,
        'total': invoice.total,
        'currency': invoice.currency,
        'payment_status': invoice.paymentStatus.name,
        'payment_reference': invoice.paymentReference,
        'created_at': Timestamp.fromDate(invoice.createdAt),
        'updated_at': Timestamp.now(),
      });

      await _auditService.logInvoiceGenerated(
        invoiceId: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        amount: invoice.total,
      );

    } catch (e) {
      await _auditService.logInvoiceError(
        type: 'INVOICE_STORAGE_ERROR',
        error: e.toString(),
        metadata: {'invoice_id': invoice.id},
      );
      rethrow;
    }
  }

  @override
  Future<DutchInvoice?> getInvoice(String invoiceId) async {
    try {
      final doc = await _firestore.collection('invoices').doc(invoiceId).get();
      
      if (!doc.exists) return null;
      
      return _invoiceFromFirestore(doc);

    } catch (e) {
      await _auditService.logInvoiceError(
        type: 'INVOICE_RETRIEVAL_ERROR',
        error: e.toString(),
        metadata: {'invoice_id': invoiceId},
      );
      return null;
    }
  }

  @override
  Future<List<DutchInvoice>> getInvoicesForPeriod(
    DateTime startDate,
    DateTime endDate, {
    PaymentStatus? status,
    int limit = 100,
  }) async {
    try {
      var query = _firestore
          .collection('invoices')
          .where('invoice_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('invoice_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('invoice_date', descending: true);

      if (status != null) {
        query = query.where('payment_status', isEqualTo: status.name);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) => _invoiceFromFirestore(doc)).toList();

    } catch (e) {
      await _auditService.logInvoiceError(
        type: 'INVOICE_PERIOD_QUERY_ERROR',
        error: e.toString(),
        metadata: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );
      return [];
    }
  }

  @override
  Future<void> updateInvoicePaymentStatus(
    String invoiceId,
    PaymentStatus status, {
    String? paymentReference,
  }) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).update({
        'payment_status': status.name,
        'payment_reference': paymentReference,
        'updated_at': Timestamp.now(),
      });

      await _auditService.logInvoiceStatusUpdate(
        invoiceId: invoiceId,
        newStatus: status,
        paymentReference: paymentReference,
      );

    } catch (e) {
      await _auditService.logInvoiceError(
        type: 'INVOICE_STATUS_UPDATE_ERROR',
        error: e.toString(),
        metadata: {'invoice_id': invoiceId, 'new_status': status.name},
      );
      rethrow;
    }
  }

  // Analytics methods

  @override
  Future<PaymentAnalytics> getPaymentAnalytics(DateTime startDate, DateTime endDate) async {
    try {
      // Get all payments in the period
      final sepaPayments = await _firestore
          .collection('sepa_payments')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final idealPayments = await _firestore
          .collection('ideal_payments')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Calculate analytics
      double totalVolume = 0;
      int totalTransactions = 0;
      int successfulTransactions = 0;
      int failedTransactions = 0;
      final volumeByType = <PaymentType, double>{};
      final transactionsByStatus = <PaymentStatus, int>{};

      // Process SEPA payments
      for (final doc in sepaPayments.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num).toDouble();
        final status = PaymentStatus.values.firstWhere(
          (s) => s.name == data['status'],
          orElse: () => PaymentStatus.unknown,
        );

        totalVolume += amount;
        totalTransactions++;

        volumeByType[PaymentType.sepaTransfer] = 
            (volumeByType[PaymentType.sepaTransfer] ?? 0) + amount;

        transactionsByStatus[status] = (transactionsByStatus[status] ?? 0) + 1;

        if (status == PaymentStatus.completed) {
          successfulTransactions++;
        } else if (status == PaymentStatus.failed) {
          failedTransactions++;
        }
      }

      // Process iDEAL payments
      for (final doc in idealPayments.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num).toDouble();
        final paymentType = PaymentType.values.firstWhere(
          (t) => t.name == data['payment_type'],
          orElse: () => PaymentType.idealPayment,
        );
        final status = PaymentStatus.values.firstWhere(
          (s) => s.name == data['status'],
          orElse: () => PaymentStatus.unknown,
        );

        totalVolume += amount;
        totalTransactions++;

        volumeByType[paymentType] = (volumeByType[paymentType] ?? 0) + amount;
        transactionsByStatus[status] = (transactionsByStatus[status] ?? 0) + 1;

        if (status == PaymentStatus.completed) {
          successfulTransactions++;
        } else if (status == PaymentStatus.failed) {
          failedTransactions++;
        }
      }

      final successRate = totalTransactions > 0 ? successfulTransactions / totalTransactions : 0.0;
      final averageTransaction = totalTransactions > 0 ? totalVolume / totalTransactions : 0.0;

      // Generate daily summaries
      final dailySummaries = await getDailyPaymentSummaries(startDate, endDate);

      return PaymentAnalytics(
        period: startDate,
        totalVolume: totalVolume,
        totalTransactions: totalTransactions,
        averageTransaction: averageTransaction,
        successfulTransactions: successfulTransactions,
        failedTransactions: failedTransactions,
        successRate: successRate,
        volumeByType: volumeByType,
        transactionsByStatus: transactionsByStatus,
        dailySummaries: dailySummaries,
      );

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'ANALYTICS_GENERATION_ERROR',
        error: e.toString(),
        metadata: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );
      rethrow;
    }
  }

  @override
  Future<List<DailyPaymentSummary>> getDailyPaymentSummaries(DateTime startDate, DateTime endDate) async {
    final dailySummaries = <DailyPaymentSummary>[];
    
    try {
      var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      final endDateNormalized = DateTime(endDate.year, endDate.month, endDate.day);

      while (!currentDate.isAfter(endDateNormalized)) {
        final dayStart = currentDate;
        final dayEnd = currentDate.add(const Duration(days: 1));

        // Get payments for this day
        final sepaSnapshot = await _firestore
            .collection('sepa_payments')
            .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
            .where('created_at', isLessThan: Timestamp.fromDate(dayEnd))
            .get();

        final idealSnapshot = await _firestore
            .collection('ideal_payments')
            .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
            .where('created_at', isLessThan: Timestamp.fromDate(dayEnd))
            .get();

        double volume = 0;
        int transactions = 0;
        int successful = 0;

        // Process SEPA payments
        for (final doc in sepaSnapshot.docs) {
          final data = doc.data();
          final amount = (data['amount'] as num).toDouble();
          final status = data['status'] as String;

          volume += amount;
          transactions++;
          
          if (status == PaymentStatus.completed.name) {
            successful++;
          }
        }

        // Process iDEAL payments
        for (final doc in idealSnapshot.docs) {
          final data = doc.data();
          final amount = (data['amount'] as num).toDouble();
          final status = data['status'] as String;

          volume += amount;
          transactions++;
          
          if (status == PaymentStatus.completed.name) {
            successful++;
          }
        }

        final successRate = transactions > 0 ? successful / transactions : 0.0;

        dailySummaries.add(DailyPaymentSummary(
          date: currentDate,
          volume: volume,
          transactions: transactions,
          successRate: successRate,
        ));

        currentDate = currentDate.add(const Duration(days: 1));
      }

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'DAILY_SUMMARY_ERROR',
        error: e.toString(),
        metadata: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );
    }

    return dailySummaries;
  }

  // Search methods

  @override
  Future<List<SEPAPayment>> searchSEPAPayments({
    String? guardId,
    String? batchId,
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('sepa_payments');

      if (guardId != null) {
        query = query.where('guard_id', isEqualTo: guardId);
      }

      if (batchId != null) {
        query = query.where('batch_id', isEqualTo: batchId);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (startDate != null) {
        query = query.where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (minAmount != null) {
        query = query.where('amount', isGreaterThanOrEqualTo: minAmount);
      }

      if (maxAmount != null) {
        query = query.where('amount', isLessThanOrEqualTo: maxAmount);
      }

      query = query.orderBy('created_at', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => _sepaPaymentFromFirestore(doc)).toList();

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'SEPA_SEARCH_ERROR',
        error: e.toString(),
        metadata: {
          'guard_id': guardId,
          'status': status?.name,
          'min_amount': minAmount,
          'max_amount': maxAmount,
        },
      );
      return [];
    }
  }

  @override
  Future<List<iDEALPayment>> searchiDEALPayments({
    String? userId,
    PaymentType? paymentType,
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('ideal_payments');

      if (userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      }

      if (paymentType != null) {
        query = query.where('payment_type', isEqualTo: paymentType.name);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (startDate != null) {
        query = query.where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (minAmount != null) {
        query = query.where('amount', isGreaterThanOrEqualTo: minAmount);
      }

      if (maxAmount != null) {
        query = query.where('amount', isLessThanOrEqualTo: maxAmount);
      }

      query = query.orderBy('created_at', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => _idealPaymentFromFirestore(doc)).toList();

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'IDEAL_SEARCH_ERROR',
        error: e.toString(),
        metadata: {
          'user_id': userId,
          'payment_type': paymentType?.name,
          'status': status?.name,
          'min_amount': minAmount,
          'max_amount': maxAmount,
        },
      );
      return [];
    }
  }

  // Real-time streams

  @override
  Stream<PaymentStatusUpdate> getPaymentStatusUpdates(String paymentId) {
    return _firestore
        .collection('sepa_payments')
        .doc(paymentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return PaymentStatusUpdate(
          paymentId: paymentId,
          status: PaymentStatus.unknown,
          timestamp: DateTime.now(),
          metadata: {},
        );
      }

      final data = snapshot.data()!;
      return PaymentStatusUpdate(
        paymentId: paymentId,
        status: PaymentStatus.values.firstWhere(
          (s) => s.name == data['status'],
          orElse: () => PaymentStatus.unknown,
        ),
        timestamp: (data['updated_at'] as Timestamp).toDate(),
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      );
    });
  }

  @override
  Stream<List<SEPAPayment>> watchSEPAPaymentsForGuard(String guardId) {
    return _firestore
        .collection('sepa_payments')
        .where('guard_id', isEqualTo: guardId)
        .orderBy('created_at', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _sepaPaymentFromFirestore(doc)).toList());
  }

  @override
  Stream<List<iDEALPayment>> watchiDEALPaymentsForUser(String userId) {
    return _firestore
        .collection('ideal_payments')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _idealPaymentFromFirestore(doc)).toList());
  }

  // Private helper methods

  SEPAPayment _sepaPaymentFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SEPAPayment(
      id: data['id'],
      batchId: data['batch_id'],
      guardId: data['guard_id'],
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'],
      recipientIBAN: data['recipient_iban'],
      recipientName: data['recipient_name'],
      description: data['description'],
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => PaymentStatus.unknown,
      ),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      processedAt: data['processed_at'] != null ? (data['processed_at'] as Timestamp).toDate() : null,
      transactionId: data['transaction_id'],
      failureReason: data['failure_reason'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  iDEALPayment _idealPaymentFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return iDEALPayment(
      id: data['id'],
      userId: data['user_id'],
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'],
      description: data['description'],
      paymentType: PaymentType.values.firstWhere(
        (t) => t.name == data['payment_type'],
        orElse: () => PaymentType.idealPayment,
      ),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => PaymentStatus.unknown,
      ),
      returnUrl: data['return_url'],
      webhookUrl: data['webhook_url'],
      checkoutUrl: data['checkout_url'],
      providerPaymentId: data['provider_payment_id'],
      selectedBankBIC: data['selected_bank_bic'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      completedAt: data['completed_at'] != null ? (data['completed_at'] as Timestamp).toDate() : null,
      expiresAt: data['expires_at'] != null ? (data['expires_at'] as Timestamp).toDate() : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  DutchInvoice _invoiceFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final lineItemsData = data['line_items'] as List<dynamic>;
    final lineItems = lineItemsData.map((item) => InvoiceLineItem(
      description: item['description'],
      quantity: (item['quantity'] as num).toDouble(),
      unitPrice: (item['unit_price'] as num).toDouble(),
      btwRate: (item['btw_rate'] as num).toDouble(),
      totalExclBTW: (item['total_excl_btw'] as num).toDouble(),
      btwAmount: (item['btw_amount'] as num).toDouble(),
      totalInclBTW: (item['total_incl_btw'] as num).toDouble(),
    )).toList();

    return DutchInvoice(
      id: data['id'],
      invoiceNumber: data['invoice_number'],
      companyName: data['company_name'],
      companyKvK: data['company_kvk'],
      companyBTW: data['company_btw'],
      companyAddress: data['company_address'],
      clientName: data['client_name'],
      clientAddress: data['client_address'],
      invoiceDate: (data['invoice_date'] as Timestamp).toDate(),
      dueDate: (data['due_date'] as Timestamp).toDate(),
      lineItems: lineItems,
      subtotal: (data['subtotal'] as num).toDouble(),
      btwAmount: (data['btw_amount'] as num).toDouble(),
      total: (data['total'] as num).toDouble(),
      currency: data['currency'],
      paymentStatus: PaymentStatus.values.firstWhere(
        (s) => s.name == data['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentReference: data['payment_reference'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
}