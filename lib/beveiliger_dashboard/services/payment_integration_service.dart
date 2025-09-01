import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../workflow/services/job_completion_payment_orchestrator.dart';
import '../../workflow/services/workflow_payment_service.dart';
import '../../workflow/models/job_workflow_models.dart';
import '../../unified_components/modern_payment_status_widget.dart';
import '../../payments/services/payment_integration_service.dart';
import '../../billing/services/payment_service.dart';
import 'payment_status_service.dart';

/// Integration service to connect payment orchestrator with dashboard
class DashboardPaymentIntegrationService {
  final PaymentService? _paymentService;
  final FirebaseFirestore _firestore;
  final WorkflowPaymentService? _workflowService;

  DashboardPaymentIntegrationService({
    JobCompletionPaymentOrchestrator? orchestrator,
    WorkflowPaymentService? workflowService,
    PaymentIntegrationService? paymentIntegrationService,
    PaymentService? paymentService,
    FirebaseFirestore? firestore,
  }) : _workflowService = workflowService,
       _paymentService = paymentService,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get payment status data for dashboard display
  Future<PaymentStatusData> getPaymentStatusData(String guardId) async {
    try {
      // Get pending payments from payment integration service
      final pendingPayments = await _getPendingPayments(guardId);
      final monthlyTotal = await _getMonthlyTotal(guardId);
      final recentPayments = await _getRecentPayments(guardId);
      final pendingCompletions = await _getPendingCompletions(guardId);
      
      return PaymentStatusData(
        pendingPayments: pendingPayments,
        monthlyTotal: monthlyTotal,
        recentPayments: recentPayments,
        pendingCompletions: pendingCompletions,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading payment data, using real PaymentStatusService: $e');
      }
      // Fallback to real PaymentStatusService instead of mock data
      return await PaymentStatusService.getPaymentStatus(guardId);
    }
  }

  /// Check if there are any jobs waiting for completion
  Future<bool> hasJobsWaitingForCompletion(String guardId) async {
    try {
      if (_workflowService != null) {
        // Use workflow service to check for pending completions
        final pendingCompletions = await _getPendingCompletions(guardId);
        return pendingCompletions.isNotEmpty;
      }
      
      // Fallback: check time entries that need completion
      final pendingTimeEntries = await _firestore
          .collection('time_entries')
          .where('guard_id', isEqualTo: guardId)
          .where('status', isEqualTo: 'completed_pending_payment')
          .limit(1)
          .get();
      
      return pendingTimeEntries.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking pending completions: $e');
      }
      return false;
    }
  }

  /// Get payment workflow status for a specific job
  Future<JobCompletionStatus?> getJobWorkflowStatus(String jobId) async {
    try {
      if (_workflowService != null) {
        final state = await _workflowService.getCurrentWorkflowState(jobId);
        return _mapWorkflowStateToStatus(jobId, state);
      }
      
      // Fallback: check job status from time entries
      final timeEntryDoc = await _firestore
          .collection('time_entries')
          .where('job_id', isEqualTo: jobId)
          .orderBy('check_in_time', descending: true)
          .limit(1)
          .get();
      
      if (timeEntryDoc.docs.isNotEmpty) {
        final data = timeEntryDoc.docs.first.data();
        final status = data['status'] as String? ?? 'unknown';
        
        return JobCompletionStatus(
          jobId: jobId,
          title: data['job_title'] as String? ?? 'Opdracht',
          state: _mapStringToWorkflowState(status),
          estimatedPayout: (data['estimated_payout'] as num?)?.toDouble() ?? 0.0,
          completedAt: (data['check_out_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting job workflow status: $e');
      }
      return null;
    }
  }

  /// Get pending payments for guard
  Future<double> _getPendingPayments(String guardId) async {
    try {
      if (_paymentService != null) {
        // Query pending SEPA payments
        final pendingPayments = await _firestore
            .collection('sepa_payments')
            .where('guardId', isEqualTo: guardId)
            .where('status', whereIn: ['pending', 'processing'])
            .get();
        
        double total = 0.0;
        for (final doc in pendingPayments.docs) {
          final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
          total += amount;
        }
        return total;
      }
      
      // Fallback: check earnings_payments collection
      final pendingEarnings = await _firestore
          .collection('earnings_payments')
          .where('guard_id', isEqualTo: guardId)
          .where('status', whereIn: ['pending', 'processing'])
          .get();
      
      double total = 0.0;
      for (final doc in pendingEarnings.docs) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        total += amount;
      }
      return total;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting pending payments: $e');
      }
      return 0.0;
    }
  }

  /// Calculate monthly total for guard
  Future<double> _getMonthlyTotal(String guardId) async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      
      // Query completed payments for this month
      final completedPayments = await _firestore
          .collection('sepa_payments')
          .where('guardId', isEqualTo: guardId)
          .where('status', isEqualTo: 'completed')
          .where('processedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('processedAt', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
          .get();
      
      double total = 0.0;
      for (final doc in completedPayments.docs) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        total += amount;
      }
      return total;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating monthly total: $e');
      }
      return 0.0;
    }
  }

  /// Get recent payments for guard
  Future<List<RecentPayment>> _getRecentPayments(String guardId) async {
    try {
      final recentPayments = await _firestore
          .collection('sepa_payments')
          .where('guardId', isEqualTo: guardId)
          .where('status', isEqualTo: 'completed')
          .orderBy('processedAt', descending: true)
          .limit(5)
          .get();
      
      return recentPayments.docs.map((doc) {
        final data = doc.data();
        return RecentPayment(
          id: doc.id,
          jobTitle: data['description'] as String? ?? 'Betaling',
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          paidDate: (data['processedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: _mapStringToPaymentStatus(data['status'] as String? ?? 'completed'),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting recent payments: $e');
      }
      return [];
    }
  }

  /// Get jobs waiting for completion or rating
  Future<List<JobCompletionStatus>> _getPendingCompletions(String guardId) async {
    try {
      // Query time entries that need completion
      final pendingCompletions = await _firestore
          .collection('time_entries')
          .where('guard_id', isEqualTo: guardId)
          .where('status', whereIn: ['completed_pending_payment', 'awaiting_rating', 'payment_processing'])
          .orderBy('check_out_time', descending: true)
          .limit(10)
          .get();
      
      return pendingCompletions.docs.map((doc) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'unknown';
        
        return JobCompletionStatus(
          jobId: doc.id,
          title: data['job_title'] as String? ?? 'Opdracht',
          state: _mapStringToWorkflowState(status),
          estimatedPayout: (data['estimated_payout'] as num?)?.toDouble() ?? 0.0,
          completedAt: (data['check_out_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting pending completions: $e');
      }
      return [];
    }
  }

  /// Map workflow state to dashboard status
  JobCompletionStatus _mapWorkflowStateToStatus(String jobId, JobWorkflowState state) {
    return JobCompletionStatus(
      jobId: jobId,
      title: 'Opdracht $jobId',
      state: state,
      estimatedPayout: 0.0,
      completedAt: DateTime.now(),
    );
  }

  /// Map string status to workflow state
  JobWorkflowState _mapStringToWorkflowState(String status) {
    switch (status) {
      case 'completed_pending_payment':
        return JobWorkflowState.completed;
      case 'awaiting_rating':
        return JobWorkflowState.completed; // Use existing state
      case 'payment_processing':
        return JobWorkflowState.rated; // Payment is being processed after rating
      case 'paid':
        return JobWorkflowState.paid;
      default:
        return JobWorkflowState.inProgress; // Default to in progress instead of 'active'
    }
  }

  /// Map string status to PaymentStatus enum
  PaymentStatus _mapStringToPaymentStatus(String status) {
    switch (status) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.completed; // Default to completed for safety
    }
  }
}