import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../unified_components/modern_payment_status_widget.dart';
import '../../workflow/models/job_workflow_models.dart';

/// Real payment status service to replace mock data fallbacks
/// 
/// Provides actual payment status data from Firestore instead of mock data
class PaymentStatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _paymentsCollection = 'payments';
  static const String _jobsCollection = 'jobs';

  /// Get real payment status data for the guard
  static Future<PaymentStatusData> getPaymentStatus(String guardId) async {
    try {
      // Get pending payments
      final pendingPayments = await _getPendingPayments(guardId);
      
      // Get monthly total
      final monthlyTotal = await _getMonthlyTotal(guardId);
      
      // Get recent payments
      final recentPayments = await _getRecentPayments(guardId);
      
      // Get pending job completions
      final pendingCompletions = await _getPendingJobCompletions(guardId);
      
      return PaymentStatusData(
        pendingPayments: pendingPayments,
        monthlyTotal: monthlyTotal,
        recentPayments: recentPayments,
        pendingCompletions: pendingCompletions,
      );
      
    } catch (e) {
      debugPrint('PaymentStatusService error: $e');
      // Return empty data instead of mock data
      return PaymentStatusData(
        pendingPayments: 0.0,
        monthlyTotal: 0.0,
        recentPayments: [],
        pendingCompletions: [],
      );
    }
  }

  /// Get total amount of pending payments for the guard
  static Future<double> _getPendingPayments(String guardId) async {
    try {
      final snapshot = await _firestore
          .collection(_paymentsCollection)
          .where('guardId', isEqualTo: guardId)
          .where('status', isEqualTo: 'pending')
          .get();

      double total = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        total += amount;
      }

      return total;
    } catch (e) {
      debugPrint('Error getting pending payments: $e');
      return 0.0;
    }
  }

  /// Get total payments for current month
  static Future<double> _getMonthlyTotal(String guardId) async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);

      final snapshot = await _firestore
          .collection(_paymentsCollection)
          .where('guardId', isEqualTo: guardId)
          .where('status', isEqualTo: 'completed')
          .where('paidDate', isGreaterThanOrEqualTo: monthStart)
          .where('paidDate', isLessThan: monthEnd)
          .get();

      double total = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        total += amount;
      }

      return total;
    } catch (e) {
      debugPrint('Error getting monthly total: $e');
      return 0.0;
    }
  }

  /// Get recent payments (last 10)
  static Future<List<RecentPayment>> _getRecentPayments(String guardId) async {
    try {
      final snapshot = await _firestore
          .collection(_paymentsCollection)
          .where('guardId', isEqualTo: guardId)
          .where('status', isEqualTo: 'completed')
          .orderBy('paidDate', descending: true)
          .limit(10)
          .get();

      final payments = <RecentPayment>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        try {
          payments.add(RecentPayment(
            id: doc.id,
            jobTitle: data['jobTitle'] as String? ?? 'Onbekende opdracht',
            amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
            paidDate: (data['paidDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: _parsePaymentStatus(data['status'] as String?),
          ));
        } catch (e) {
          debugPrint('Error parsing recent payment ${doc.id}: $e');
        }
      }

      return payments;
    } catch (e) {
      debugPrint('Error getting recent payments: $e');
      return [];
    }
  }

  /// Get pending job completions that need payment processing
  static Future<List<JobCompletionStatus>> _getPendingJobCompletions(String guardId) async {
    try {
      final snapshot = await _firestore
          .collection(_jobsCollection)
          .where('assignedGuardId', isEqualTo: guardId)
          .where('status', isEqualTo: 'completed')
          .where('paymentStatus', isEqualTo: 'pending')
          .orderBy('completedAt', descending: true)
          .limit(5)
          .get();

      final completions = <JobCompletionStatus>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        try {
          completions.add(JobCompletionStatus(
            jobId: doc.id,
            title: data['title'] as String? ?? 'Onbekende opdracht',
            state: _parseJobWorkflowState(data['workflowState'] as String?),
            estimatedPayout: (data['estimatedPayout'] as num?)?.toDouble() ?? 0.0,
            completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        } catch (e) {
          debugPrint('Error parsing job completion ${doc.id}: $e');
        }
      }

      return completions;
    } catch (e) {
      debugPrint('Error getting pending job completions: $e');
      return [];
    }
  }

  /// Parse payment status from string
  static PaymentStatus _parsePaymentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }

  /// Parse job workflow state from string
  static JobWorkflowState _parseJobWorkflowState(String? state) {
    switch (state?.toLowerCase()) {
      case 'posted':
        return JobWorkflowState.posted;
      case 'applied':
        return JobWorkflowState.applied;
      case 'underreview':
      case 'under_review':
        return JobWorkflowState.underReview;
      case 'accepted':
        return JobWorkflowState.accepted;
      case 'inprogress':
      case 'in_progress':
        return JobWorkflowState.inProgress;
      case 'completed':
        return JobWorkflowState.completed;
      case 'rated':
        return JobWorkflowState.rated;
      case 'paid':
        return JobWorkflowState.paid;
      case 'closed':
        return JobWorkflowState.closed;
      case 'cancelled':
        return JobWorkflowState.cancelled;
      default:
        return JobWorkflowState.completed;
    }
  }

  /// Initialize some demo payment data for development
  static Future<void> initializeDemoData(String guardId) async {
    try {
      // Check if demo data already exists
      final existingPayments = await _firestore
          .collection(_paymentsCollection)
          .where('guardId', isEqualTo: guardId)
          .limit(1)
          .get();

      if (existingPayments.docs.isNotEmpty) {
        debugPrint('Demo payment data already exists');
        return;
      }

      // Create demo payments
      final demoPayments = [
        {
          'guardId': guardId,
          'jobTitle': 'Avonddienst Winkelcentrum',
          'amount': 124.00,
          'status': 'completed',
          'paidDate': DateTime.now().subtract(const Duration(days: 2)),
          'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        },
        {
          'guardId': guardId,
          'jobTitle': 'Nachtdienst Kantoorcomplex',
          'amount': 186.50,
          'status': 'completed',
          'paidDate': DateTime.now().subtract(const Duration(days: 5)),
          'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        },
        {
          'guardId': guardId,
          'jobTitle': 'Evenementbeveiliging Concert',
          'amount': 142.75,
          'status': 'pending',
          'createdAt': DateTime.now().subtract(const Duration(hours: 6)),
        },
      ];

      // Add demo payments to Firestore
      for (final payment in demoPayments) {
        await _firestore.collection(_paymentsCollection).add(payment);
      }

      // Create demo job completions
      final demoJobs = [
        {
          'assignedGuardId': guardId,
          'title': 'Weekend Beveiliging Museum',
          'status': 'completed',
          'paymentStatus': 'pending',
          'estimatedPayout': 96.80,
          'workflowState': 'completed',
          'completedAt': DateTime.now().subtract(const Duration(hours: 2)),
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        },
        {
          'assignedGuardId': guardId,
          'title': 'Retailbeveiliging Vrijdag',
          'status': 'completed',
          'paymentStatus': 'pending',
          'estimatedPayout': 118.40,
          'workflowState': 'completed',
          'completedAt': DateTime.now().subtract(const Duration(hours: 8)),
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        },
      ];

      // Add demo job completions to Firestore
      for (final job in demoJobs) {
        await _firestore.collection(_jobsCollection).add(job);
      }

      debugPrint('Demo payment data initialized for guard $guardId');
    } catch (e) {
      debugPrint('Error initializing demo payment data: $e');
    }
  }

  /// Get comprehensive payment statistics
  static Future<Map<String, dynamic>> getPaymentStatistics(String guardId) async {
    try {
      final allPayments = await _firestore
          .collection(_paymentsCollection)
          .where('guardId', isEqualTo: guardId)
          .get();

      final completedPayments = allPayments.docs
          .where((doc) => (doc.data()['status'] as String?) == 'completed')
          .toList();

      final pendingPayments = allPayments.docs
          .where((doc) => (doc.data()['status'] as String?) == 'pending')
          .toList();

      double totalEarnings = 0.0;
      double pendingAmount = 0.0;

      for (final doc in completedPayments) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        totalEarnings += amount;
      }

      for (final doc in pendingPayments) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        pendingAmount += amount;
      }

      return {
        'totalPayments': allPayments.docs.length,
        'completedPayments': completedPayments.length,
        'pendingPayments': pendingPayments.length,
        'totalEarnings': totalEarnings,
        'pendingAmount': pendingAmount,
        'averagePayment': completedPayments.isNotEmpty
            ? totalEarnings / completedPayments.length
            : 0.0,
      };
    } catch (e) {
      debugPrint('Error getting payment statistics: $e');
      return {
        'totalPayments': 0,
        'completedPayments': 0,
        'pendingPayments': 0,
        'totalEarnings': 0.0,
        'pendingAmount': 0.0,
        'averagePayment': 0.0,
        'error': e.toString(),
      };
    }
  }
}