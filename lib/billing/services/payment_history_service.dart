import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/error/exceptions.dart';
import '../../shared/utils/dutch_formatting.dart';
import '../../shared/services/encryption_service.dart';
import '../models/payment_models.dart';

/// Payment history tracking service for SecuryFlex
/// Provides comprehensive payment analytics and monitoring
class PaymentHistoryService {
  final FirebaseFirestore _firestore;
  final EncryptionService _encryptionService;

  // Stream controllers for real-time updates
  final StreamController<List<PaymentTransaction>> _paymentHistoryController = 
      StreamController<List<PaymentTransaction>>.broadcast();
  final StreamController<PaymentAnalytics> _analyticsController = 
      StreamController<PaymentAnalytics>.broadcast();

  PaymentHistoryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EncryptionService? encryptionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _encryptionService = encryptionService ?? EncryptionService();

  /// Get payment history stream for real-time updates
  Stream<List<PaymentTransaction>> getPaymentHistoryStream({
    String? guardId,
    String? companyId,
    PaymentType? type,
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    Query query = _firestore.collection('payments');

    // Apply filters
    if (guardId != null) {
      query = query.where('guard_id', isEqualTo: guardId);
    }
    if (companyId != null) {
      query = query.where('company_id', isEqualTo: companyId);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (startDate != null) {
      query = query.where('created_at', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('created_at', isLessThanOrEqualTo: endDate);
    }

    query = query.orderBy('created_at', descending: true).limit(limit);

    return query.snapshots().asyncMap((snapshot) async {
      final payments = <PaymentTransaction>[];
      
      for (final doc in snapshot.docs) {
        try {
          final encryptedData = doc.data() as Map<String, dynamic>;
          final decryptedData = await _encryptionService.decryptPaymentData(encryptedData);
          final payment = _paymentFromMap(decryptedData);
          payments.add(payment);
        } catch (e) {
          // Log decryption error but continue processing other payments
          await _logDecryptionError(doc.id, e);
        }
      }
      
      return payments;
    });
  }

  /// Get payment analytics for dashboard
  Future<PaymentAnalytics> getPaymentAnalytics({
    String? guardId,
    String? companyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final analyticsStartDate = startDate ?? DateTime(now.year, now.month - 11, 1); // Last 12 months
      final analyticsEndDate = endDate ?? now;

      // Get all payments in the period
      final payments = await _getPaymentsInPeriod(
        guardId: guardId,
        companyId: companyId,
        startDate: analyticsStartDate,
        endDate: analyticsEndDate,
      );

      // Calculate analytics
      final analytics = _calculateAnalytics(payments, analyticsStartDate, analyticsEndDate);
      
      // Cache analytics for performance
      await _cacheAnalytics(guardId, companyId, analytics);
      
      return analytics;
    } catch (e) {
      throw BusinessLogicException(
        'Failed to calculate payment analytics: ${e.toString()}',
        errorCode: 'ANALYTICS_ERROR',
      );
    }
  }

  /// Get monthly payment summary
  Future<List<MonthlyPaymentSummary>> getMonthlyPaymentSummary({
    String? guardId,
    String? companyId,
    int months = 12,
  }) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months, 1);
    
    final payments = await _getPaymentsInPeriod(
      guardId: guardId,
      companyId: companyId,
      startDate: startDate,
      endDate: now,
    );

    // Group payments by month
    final monthlyGroups = <String, List<PaymentTransaction>>{};
    
    for (final payment in payments) {
      final monthKey = '${payment.createdAt.year}-${payment.createdAt.month.toString().padLeft(2, '0')}';
      monthlyGroups.putIfAbsent(monthKey, () => []).add(payment);
    }

    // Create monthly summaries
    final summaries = <MonthlyPaymentSummary>[];
    
    for (int i = 0; i < months; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final monthPayments = monthlyGroups[monthKey] ?? [];
      
      summaries.add(_calculateMonthlySummary(date, monthPayments));
    }

    return summaries.reversed.toList(); // Return chronologically
  }

  /// Get payment status distribution
  Future<Map<PaymentStatus, int>> getPaymentStatusDistribution({
    String? guardId,
    String? companyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final payments = await _getPaymentsInPeriod(
      guardId: guardId,
      companyId: companyId,
      startDate: startDate,
      endDate: endDate,
    );

    final distribution = <PaymentStatus, int>{};
    
    for (final status in PaymentStatus.values) {
      distribution[status] = 0;
    }

    for (final payment in payments) {
      distribution[payment.status] = (distribution[payment.status] ?? 0) + 1;
    }

    return distribution;
  }

  /// Get payment type breakdown
  Future<Map<PaymentType, PaymentTypeAnalytics>> getPaymentTypeBreakdown({
    String? guardId,
    String? companyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final payments = await _getPaymentsInPeriod(
      guardId: guardId,
      companyId: companyId,
      startDate: startDate,
      endDate: endDate,
    );

    final breakdown = <PaymentType, PaymentTypeAnalytics>{};

    for (final type in PaymentType.values) {
      final typePayments = payments.where((p) => p.type == type).toList();
      
      if (typePayments.isNotEmpty) {
        breakdown[type] = PaymentTypeAnalytics(
          type: type,
          totalCount: typePayments.length,
          totalAmount: typePayments.fold(0.0, (total, p) => total + p.amount),
          averageAmount: typePayments.fold(0.0, (total, p) => total + p.amount) / typePayments.length,
          successRate: typePayments.where((p) => p.status == PaymentStatus.completed).length / typePayments.length,
          lastPaymentDate: typePayments.map((p) => p.createdAt).reduce((a, b) => a.isAfter(b) ? a : b),
        );
      }
    }

    return breakdown;
  }

  /// Get failed payments analysis
  Future<List<FailedPaymentAnalysis>> getFailedPaymentsAnalysis({
    String? guardId,
    String? companyId,
    int limit = 20,
  }) async {
    Query query = _firestore.collection('payments')
        .where('status', isEqualTo: PaymentStatus.failed.name)
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (guardId != null) {
      query = query.where('guard_id', isEqualTo: guardId);
    }
    if (companyId != null) {
      query = query.where('company_id', isEqualTo: companyId);
    }

    final snapshot = await query.get();
    final failedPayments = <FailedPaymentAnalysis>[];

    for (final doc in snapshot.docs) {
      try {
        final encryptedData = doc.data() as Map<String, dynamic>;
        final decryptedData = await _encryptionService.decryptPaymentData(encryptedData);
        
        // Get error details from audit logs
        final errorDetails = await _getPaymentErrorDetails(decryptedData['id']);
        
        failedPayments.add(FailedPaymentAnalysis(
          paymentId: decryptedData['id'],
          guardId: decryptedData['guard_id'],
          companyId: decryptedData['company_id'],
          amount: (decryptedData['amount'] as num).toDouble(),
          type: PaymentType.values.firstWhere((t) => t.name == decryptedData['type']),
          failedAt: (decryptedData['created_at'] as Timestamp).toDate(),
          errorCode: errorDetails['error_code'] ?? 'UNKNOWN_ERROR',
          errorMessage: errorDetails['error_message'] ?? 'No error details available',
          retryCount: decryptedData['retry_count'] ?? 0,
          canRetry: _canRetryPayment(errorDetails['error_code']),
        ));
      } catch (e) {
        await _logDecryptionError(doc.id, e);
      }
    }

    return failedPayments;
  }

  /// Get payment performance metrics
  Future<PaymentPerformanceMetrics> getPaymentPerformanceMetrics({
    String? guardId,
    String? companyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final payments = await _getPaymentsInPeriod(
      guardId: guardId,
      companyId: companyId,
      startDate: startDate,
      endDate: endDate,
    );

    if (payments.isEmpty) {
      return PaymentPerformanceMetrics.empty();
    }

    final completedPayments = payments.where((p) => p.status == PaymentStatus.completed).toList();
    final failedPayments = payments.where((p) => p.status == PaymentStatus.failed).toList();
    
    // Calculate processing times for completed payments
    final processingTimes = completedPayments
        .where((p) => p.processedAt != null)
        .map((p) => p.processedAt!.difference(p.createdAt).inMinutes)
        .toList();

    return PaymentPerformanceMetrics(
      totalPayments: payments.length,
      successRate: completedPayments.length / payments.length,
      failureRate: failedPayments.length / payments.length,
      averageProcessingTimeMinutes: processingTimes.isNotEmpty 
          ? processingTimes.reduce((a, b) => a + b) / processingTimes.length 
          : 0,
      medianProcessingTimeMinutes: processingTimes.isNotEmpty 
          ? _calculateMedian(processingTimes) 
          : 0,
      totalVolume: payments.fold(0.0, (total, p) => total + p.amount),
      averagePaymentAmount: payments.fold(0.0, (total, p) => total + p.amount) / payments.length,
      largestPayment: payments.map((p) => p.amount).reduce((a, b) => a > b ? a : b),
      smallestPayment: payments.map((p) => p.amount).reduce((a, b) => a < b ? a : b),
      mostCommonFailureReason: _getMostCommonFailureReason(failedPayments),
    );
  }

  /// Export payment history to CSV
  Future<String> exportPaymentHistoryCSV({
    String? guardId,
    String? companyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final payments = await _getPaymentsInPeriod(
      guardId: guardId,
      companyId: companyId,
      startDate: startDate,
      endDate: endDate,
    );

    final csvLines = <String>[];
    
    // CSV Header
    csvLines.add([
      'Datum',
      'Factuurnummer',
      'Beveiliger ID',
      'Bedrijf ID',
      'Type',
      'Methode',
      'Status',
      'Bruto Bedrag',
      'Netto Bedrag',
      'BTW Bedrag',
      'Vakantiegeld',
      'Pensioenaftrek',
      'Omschrijving',
    ].join(','));

    // Data rows
    for (final payment in payments) {
      csvLines.add([
        DutchFormatting.formatDate(payment.createdAt),
        payment.reference,
        payment.guardId,
        payment.companyId ?? '',
        payment.type.dutchName,
        payment.method.dutchName,
        payment.status.dutchName,
        payment.amount.toStringAsFixed(2),
        payment.netAmount.toStringAsFixed(2),
        payment.btwAmount.toStringAsFixed(2),
        payment.vakantiegeldAmount.toStringAsFixed(2),
        payment.pensionDeduction.toStringAsFixed(2),
        '"${payment.description}"',
      ].join(','));
    }

    return csvLines.join('\n');
  }

  /// Get payments in a specific period
  Future<List<PaymentTransaction>> _getPaymentsInPeriod({
    String? guardId,
    String? companyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _firestore.collection('payments');

    if (guardId != null) {
      query = query.where('guard_id', isEqualTo: guardId);
    }
    if (companyId != null) {
      query = query.where('company_id', isEqualTo: companyId);
    }
    if (startDate != null) {
      query = query.where('created_at', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('created_at', isLessThanOrEqualTo: endDate);
    }

    query = query.orderBy('created_at', descending: true);

    final snapshot = await query.get();
    final payments = <PaymentTransaction>[];

    for (final doc in snapshot.docs) {
      try {
        final encryptedData = doc.data() as Map<String, dynamic>;
        final decryptedData = await _encryptionService.decryptPaymentData(encryptedData);
        payments.add(_paymentFromMap(decryptedData));
      } catch (e) {
        await _logDecryptionError(doc.id, e);
      }
    }

    return payments;
  }

  /// Calculate comprehensive payment analytics
  PaymentAnalytics _calculateAnalytics(
    List<PaymentTransaction> payments,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (payments.isEmpty) {
      return PaymentAnalytics.empty(startDate, endDate);
    }

    final completedPayments = payments.where((p) => p.status == PaymentStatus.completed).toList();
    final pendingPayments = payments.where((p) => p.status == PaymentStatus.pending).toList();
    final failedPayments = payments.where((p) => p.status == PaymentStatus.failed).toList();

    // Calculate totals
    final totalVolume = payments.fold(0.0, (total, p) => total + p.amount);
    final completedVolume = completedPayments.fold(0.0, (total, p) => total + p.amount);
    final pendingVolume = pendingPayments.fold(0.0, (total, p) => total + p.amount);

    // Calculate BTW and tax totals
    final totalBTW = payments.fold(0.0, (total, p) => total + p.btwAmount);
    final totalVakantiegeld = payments.fold(0.0, (total, p) => total + p.vakantiegeldAmount);
    final totalPension = payments.fold(0.0, (total, p) => total + p.pensionDeduction);

    // Calculate growth rate (comparing to previous period)
    final periodDays = endDate.difference(startDate).inDays;
    final previousStartDate = startDate.subtract(Duration(days: periodDays));
    final previousPayments = payments.where((p) => 
        p.createdAt.isAfter(previousStartDate) && p.createdAt.isBefore(startDate)).toList();
    final previousVolume = previousPayments.fold(0.0, (total, p) => total + p.amount);
    final growthRate = previousVolume > 0 ? (totalVolume - previousVolume) / previousVolume : 0.0;

    return PaymentAnalytics(
      startDate: startDate,
      endDate: endDate,
      totalPayments: payments.length,
      totalVolume: totalVolume,
      completedPayments: completedPayments.length,
      completedVolume: completedVolume,
      pendingPayments: pendingPayments.length,
      pendingVolume: pendingVolume,
      failedPayments: failedPayments.length,
      successRate: payments.isNotEmpty ? completedPayments.length / payments.length : 0.0,
      averagePaymentAmount: totalVolume / payments.length,
      totalBTWAmount: totalBTW,
      totalVakantiegeldAmount: totalVakantiegeld,
      totalPensionDeduction: totalPension,
      growthRate: growthRate,
      dutchFormattedTotalVolume: DutchFormatting.formatCurrency(totalVolume),
      dutchFormattedCompletedVolume: DutchFormatting.formatCurrency(completedVolume),
      dutchFormattedPendingVolume: DutchFormatting.formatCurrency(pendingVolume),
    );
  }

  /// Calculate monthly summary
  MonthlyPaymentSummary _calculateMonthlySummary(
    DateTime month,
    List<PaymentTransaction> payments,
  ) {
    final totalAmount = payments.fold(0.0, (total, p) => total + p.amount);
    final completedPayments = payments.where((p) => p.status == PaymentStatus.completed).toList();
    final completedAmount = completedPayments.fold(0.0, (total, p) => total + p.amount);

    return MonthlyPaymentSummary(
      month: month,
      totalPayments: payments.length,
      totalAmount: totalAmount,
      completedPayments: completedPayments.length,
      completedAmount: completedAmount,
      averagePaymentAmount: payments.isNotEmpty ? totalAmount / payments.length : 0.0,
      successRate: payments.isNotEmpty ? completedPayments.length / payments.length : 0.0,
      dutchFormattedTotal: DutchFormatting.formatCurrency(totalAmount),
      dutchFormattedCompleted: DutchFormatting.formatCurrency(completedAmount),
      monthName: DutchFormatting.getMonthName(month.month),
    );
  }

  /// Convert Firestore map to PaymentTransaction
  PaymentTransaction _paymentFromMap(Map<String, dynamic> data) {
    return PaymentTransaction(
      id: data['id'],
      guardId: data['guard_id'],
      companyId: data['company_id'],
      type: PaymentType.values.firstWhere((t) => t.name == data['type']),
      method: PaymentMethod.values.firstWhere((m) => m.name == data['method']),
      status: PaymentStatus.values.firstWhere((s) => s.name == data['status']),
      amount: (data['amount'] as num).toDouble(),
      grossAmount: (data['gross_amount'] as num).toDouble(),
      netAmount: (data['net_amount'] as num).toDouble(),
      btwAmount: (data['btw_amount'] as num).toDouble(),
      vakantiegeldAmount: (data['vakantiegeld_amount'] as num).toDouble(),
      pensionDeduction: (data['pension_deduction'] as num).toDouble(),
      inkomstenbelastingAmount: (data['inkomstenbelasting_amount'] as num?)?.toDouble() ?? 0.0,
      dutchFormattedAmount: data['dutch_formatted_amount'],
      reference: data['reference'],
      description: data['description'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      processedAt: data['processed_at'] != null ? 
          (data['processed_at'] as Timestamp).toDate() : null,
      completedAt: data['completed_at'] != null ? 
          (data['completed_at'] as Timestamp).toDate() : null,
      executionDate: data['execution_date'] != null ?
          (data['execution_date'] as Timestamp).toDate() : null,
      recipientIBAN: data['recipient_iban'],
      recipientName: data['recipient_name'],
      transactionReference: data['transaction_reference'],
    );
  }

  /// Get payment error details from audit logs
  Future<Map<String, dynamic>> _getPaymentErrorDetails(String paymentId) async {
    final snapshot = await _firestore
        .collection('payment_errors')
        .where('payment_id', isEqualTo: paymentId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }

    return {'error_code': 'UNKNOWN_ERROR', 'error_message': 'No error details available'};
  }

  /// Check if a payment can be retried based on error code
  bool _canRetryPayment(String? errorCode) {
    const retryableErrors = [
      'NETWORK_ERROR',
      'BANK_UNAVAILABLE',
      'TEMPORARY_ERROR',
      'RATE_LIMITED',
    ];
    
    return errorCode != null && retryableErrors.contains(errorCode);
  }

  /// Calculate median value
  double _calculateMedian(List<int> values) {
    values.sort();
    final middle = values.length ~/ 2;
    
    if (values.length % 2 == 0) {
      return (values[middle - 1] + values[middle]) / 2.0;
    } else {
      return values[middle].toDouble();
    }
  }

  /// Get most common failure reason
  String _getMostCommonFailureReason(List<PaymentTransaction> failedPayments) {
    if (failedPayments.isEmpty) return 'No failures';
    
    // This would typically analyze error messages to find common patterns
    // For now, return a placeholder
    return 'Insufficient funds';
  }

  /// Cache analytics for performance
  Future<void> _cacheAnalytics(String? guardId, String? companyId, PaymentAnalytics analytics) async {
    final cacheKey = 'analytics_${guardId ?? 'all'}_${companyId ?? 'all'}';
    
    await _firestore.collection('analytics_cache').doc(cacheKey).set({
      'data': analytics.toJson(),
      'cached_at': FieldValue.serverTimestamp(),
      'expires_at': DateTime.now().add(const Duration(hours: 1)),
    });
  }

  /// Log decryption errors
  Future<void> _logDecryptionError(String documentId, dynamic error) async {
    await _firestore.collection('decryption_errors').add({
      'document_id': documentId,
      'error_message': error.toString(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void dispose() {
    _paymentHistoryController.close();
    _analyticsController.close();
  }
}

/// Payment analytics data structure
class PaymentAnalytics {
  final DateTime startDate;
  final DateTime endDate;
  final int totalPayments;
  final double totalVolume;
  final int completedPayments;
  final double completedVolume;
  final int pendingPayments;
  final double pendingVolume;
  final int failedPayments;
  final double successRate;
  final double averagePaymentAmount;
  final double totalBTWAmount;
  final double totalVakantiegeldAmount;
  final double totalPensionDeduction;
  final double growthRate;
  final String dutchFormattedTotalVolume;
  final String dutchFormattedCompletedVolume;
  final String dutchFormattedPendingVolume;

  const PaymentAnalytics({
    required this.startDate,
    required this.endDate,
    required this.totalPayments,
    required this.totalVolume,
    required this.completedPayments,
    required this.completedVolume,
    required this.pendingPayments,
    required this.pendingVolume,
    required this.failedPayments,
    required this.successRate,
    required this.averagePaymentAmount,
    required this.totalBTWAmount,
    required this.totalVakantiegeldAmount,
    required this.totalPensionDeduction,
    required this.growthRate,
    required this.dutchFormattedTotalVolume,
    required this.dutchFormattedCompletedVolume,
    required this.dutchFormattedPendingVolume,
  });

  factory PaymentAnalytics.empty(DateTime startDate, DateTime endDate) {
    return PaymentAnalytics(
      startDate: startDate,
      endDate: endDate,
      totalPayments: 0,
      totalVolume: 0.0,
      completedPayments: 0,
      completedVolume: 0.0,
      pendingPayments: 0,
      pendingVolume: 0.0,
      failedPayments: 0,
      successRate: 0.0,
      averagePaymentAmount: 0.0,
      totalBTWAmount: 0.0,
      totalVakantiegeldAmount: 0.0,
      totalPensionDeduction: 0.0,
      growthRate: 0.0,
      dutchFormattedTotalVolume: '€0,00',
      dutchFormattedCompletedVolume: '€0,00',
      dutchFormattedPendingVolume: '€0,00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_payments': totalPayments,
      'total_volume': totalVolume,
      'completed_payments': completedPayments,
      'completed_volume': completedVolume,
      'pending_payments': pendingPayments,
      'pending_volume': pendingVolume,
      'failed_payments': failedPayments,
      'success_rate': successRate,
      'average_payment_amount': averagePaymentAmount,
      'total_btw_amount': totalBTWAmount,
      'total_vakantiegeld_amount': totalVakantiegeldAmount,
      'total_pension_deduction': totalPensionDeduction,
      'growth_rate': growthRate,
    };
  }
}

/// Monthly payment summary
class MonthlyPaymentSummary {
  final DateTime month;
  final int totalPayments;
  final double totalAmount;
  final int completedPayments;
  final double completedAmount;
  final double averagePaymentAmount;
  final double successRate;
  final String dutchFormattedTotal;
  final String dutchFormattedCompleted;
  final String monthName;

  const MonthlyPaymentSummary({
    required this.month,
    required this.totalPayments,
    required this.totalAmount,
    required this.completedPayments,
    required this.completedAmount,
    required this.averagePaymentAmount,
    required this.successRate,
    required this.dutchFormattedTotal,
    required this.dutchFormattedCompleted,
    required this.monthName,
  });
}

/// Payment type analytics
class PaymentTypeAnalytics {
  final PaymentType type;
  final int totalCount;
  final double totalAmount;
  final double averageAmount;
  final double successRate;
  final DateTime lastPaymentDate;

  const PaymentTypeAnalytics({
    required this.type,
    required this.totalCount,
    required this.totalAmount,
    required this.averageAmount,
    required this.successRate,
    required this.lastPaymentDate,
  });
}

/// Failed payment analysis
class FailedPaymentAnalysis {
  final String paymentId;
  final String guardId;
  final String companyId;
  final double amount;
  final PaymentType type;
  final DateTime failedAt;
  final String errorCode;
  final String errorMessage;
  final int retryCount;
  final bool canRetry;

  const FailedPaymentAnalysis({
    required this.paymentId,
    required this.guardId,
    required this.companyId,
    required this.amount,
    required this.type,
    required this.failedAt,
    required this.errorCode,
    required this.errorMessage,
    required this.retryCount,
    required this.canRetry,
  });
}

/// Payment performance metrics
class PaymentPerformanceMetrics {
  final int totalPayments;
  final double successRate;
  final double failureRate;
  final double averageProcessingTimeMinutes;
  final double medianProcessingTimeMinutes;
  final double totalVolume;
  final double averagePaymentAmount;
  final double largestPayment;
  final double smallestPayment;
  final String mostCommonFailureReason;

  const PaymentPerformanceMetrics({
    required this.totalPayments,
    required this.successRate,
    required this.failureRate,
    required this.averageProcessingTimeMinutes,
    required this.medianProcessingTimeMinutes,
    required this.totalVolume,
    required this.averagePaymentAmount,
    required this.largestPayment,
    required this.smallestPayment,
    required this.mostCommonFailureReason,
  });

  factory PaymentPerformanceMetrics.empty() {
    return const PaymentPerformanceMetrics(
      totalPayments: 0,
      successRate: 0.0,
      failureRate: 0.0,
      averageProcessingTimeMinutes: 0.0,
      medianProcessingTimeMinutes: 0.0,
      totalVolume: 0.0,
      averagePaymentAmount: 0.0,
      largestPayment: 0.0,
      smallestPayment: 0.0,
      mostCommonFailureReason: 'No failures',
    );
  }
}