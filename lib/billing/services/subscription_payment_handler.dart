import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/subscription_models.dart';
import '../repository/subscription_repository.dart';
import '../../payments/services/payment_integration_service.dart';
import '../../payments/services/payment_audit_service.dart';
import '../../payments/models/payment_models.dart';
import '../../payments/repository/payment_repository.dart';
import '../../payments/services/sepa_payment_service.dart';
import '../../payments/services/dutch_invoice_service.dart';
import '../../beveiliger_dashboard/services/enhanced_earnings_service.dart';
import '../../schedule/services/payroll_export_service.dart';

/// Specialized handler for subscription payment processing
/// Handles recurring payments, failed payment retries, and dunning management
class SubscriptionPaymentHandler {
  final SubscriptionRepository _repository;
  final PaymentIntegrationService _paymentService;
  final PaymentAuditService _auditService;
  final FirebaseFirestore _firestore;

  static SubscriptionPaymentHandler? _instance;
  static SubscriptionPaymentHandler get instance {
    _instance ??= SubscriptionPaymentHandler(
        repository: SubscriptionRepository(),
        paymentService: _createMockPaymentService(),
        auditService: _createMockAuditService(),
      );
    return _instance!;
  }
  
  static PaymentIntegrationService _createMockPaymentService() {
    // Return a basic instance for now - would be properly configured in production
    throw UnimplementedError('PaymentIntegrationService needs proper factory setup');
  }
  
  static PaymentAuditService _createMockAuditService() {
    // Return a basic instance for now - would be properly configured in production  
    throw UnimplementedError('PaymentAuditService needs proper factory setup');
  }

  SubscriptionPaymentHandler({
    required SubscriptionRepository repository,
    required PaymentIntegrationService paymentService,
    required PaymentAuditService auditService,
    FirebaseFirestore? firestore,
  }) : _repository = repository,
       _paymentService = paymentService,
       _auditService = auditService,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Process recurring payment for a subscription
  Future<PaymentResult> processRecurringPayment(String subscriptionId) async {
    try {
      debugPrint('🔄 Processing recurring payment for subscription: $subscriptionId');
      
      final subscription = await _repository.getSubscription(subscriptionId);
      if (subscription == null) {
        return PaymentResult.error('Subscription not found: $subscriptionId');
      }

      // Validate subscription is eligible for recurring payment
      if (!_isEligibleForRecurringPayment(subscription)) {
        return PaymentResult.error(
          'Subscription not eligible for recurring payment: ${subscription.status.displayName}'
        );
      }

      if (subscription.paymentMethodId == null) {
        return PaymentResult.error('No payment method configured for subscription');
      }

      // Calculate payment amount (with BTW)
      final paymentAmount = subscription.priceWithBTW;

      // Process payment through payment integration service
      final paymentResult = await _paymentService.processSubscriptionPayment(
        subscriptionId: subscriptionId,
        amount: paymentAmount,
        userId: subscription.userId,
        paymentMethodId: subscription.paymentMethodId!,
        description: 'SecuryFlex ${subscription.tier.displayName} - Maandelijks abonnement',
        metadata: {
          'subscription_id': subscriptionId,
          'billing_period': _getCurrentBillingPeriod(),
          'tier': subscription.tier.id,
          'is_recurring': true,
        },
      );

      // Update subscription based on payment result
      if (paymentResult.success) {
        await _handleSuccessfulPayment(subscription, paymentResult);
      } else {
        await _handleFailedPayment(subscription, paymentResult);
      }

      return paymentResult;
    } catch (e) {
      debugPrint('❌ Error processing recurring payment: $e');
      
      await _auditService.logPaymentError(
        type: 'RECURRING_PAYMENT_ERROR',
        error: e.toString(),
        metadata: {'subscription_id': subscriptionId},
      );

      return PaymentResult.error('Failed to process recurring payment: $e');
    }
  }

  /// Handle failed payment with retry logic and dunning management
  Future<void> handleFailedPayment(String subscriptionId, String reason) async {
    try {
      debugPrint('⚠️ Handling failed payment for subscription: $subscriptionId');
      
      final subscription = await _repository.getSubscription(subscriptionId);
      if (subscription == null) return;

      // Increment failure count
      final currentFailures = await _getFailureCount(subscriptionId);
      final newFailureCount = currentFailures + 1;

      await _repository.updateSubscription(subscriptionId, {
        'status': SubscriptionStatus.pastDue.id,
        'lastFailedPaymentAt': Timestamp.now(),
        'lastFailedPaymentError': reason,
        'failureCount': newFailureCount,
        'updatedAt': Timestamp.now(),
      });

      // Schedule retry based on failure count
      await _schedulePaymentRetry(subscriptionId, newFailureCount);

      // Send notification to user
      await _sendPaymentFailureNotification(subscription, reason, newFailureCount);

      // Check if subscription should be canceled due to too many failures
      if (newFailureCount >= 3) {
        await _handleExcessiveFailures(subscriptionId);
      }

      await _auditService.logPaymentError(
        type: 'SUBSCRIPTION_PAYMENT_FAILED',
        error: reason,
        metadata: {
          'subscription_id': subscriptionId,
          'failure_count': newFailureCount,
          'tier': subscription.tier.id,
        },
      );
    } catch (e) {
      debugPrint('❌ Error handling failed payment: $e');
    }
  }

  /// Retry failed payment
  Future<PaymentResult> retryFailedPayment(String subscriptionId) async {
    try {
      debugPrint('🔄 Retrying failed payment for subscription: $subscriptionId');
      
      final subscription = await _repository.getSubscription(subscriptionId);
      if (subscription == null) {
        return PaymentResult.error('Subscription not found');
      }

      if (subscription.status != SubscriptionStatus.pastDue) {
        return PaymentResult.error('Subscription is not in past due status');
      }

      // Attempt payment retry
      final paymentResult = await processRecurringPayment(subscriptionId);
      
      if (paymentResult.success) {
        // Reset failure count on successful retry
        await _repository.updateSubscription(subscriptionId, {
          'failureCount': 0,
          'lastFailedPaymentAt': null,
          'lastFailedPaymentError': null,
        });

        await _sendPaymentSuccessNotification(subscription);
      }

      return paymentResult;
    } catch (e) {
      debugPrint('❌ Error retrying payment: $e');
      return PaymentResult.error('Payment retry failed: $e');
    }
  }

  /// Process batch recurring payments for all due subscriptions
  Future<Map<String, dynamic>> processBatchRecurringPayments() async {
    try {
      debugPrint('🔄 Processing batch recurring payments');
      
      final dueSubscriptions = await _repository.getSubscriptionsDueForPayment();
      
      if (dueSubscriptions.isEmpty) {
        return {
          'total_processed': 0,
          'successful': 0,
          'failed': 0,
          'message': 'No subscriptions due for payment',
        };
      }

      int successCount = 0;
      int failureCount = 0;
      final List<String> failedSubscriptions = [];

      for (final subscription in dueSubscriptions) {
        try {
          final result = await processRecurringPayment(subscription.id);
          
          if (result.success) {
            successCount++;
          } else {
            failureCount++;
            failedSubscriptions.add(subscription.id);
          }
          
          // Add delay between payments to avoid overwhelming payment provider
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          failureCount++;
          failedSubscriptions.add(subscription.id);
          debugPrint('❌ Batch payment failed for ${subscription.id}: $e');
        }
      }

      final result = {
        'total_processed': dueSubscriptions.length,
        'successful': successCount,
        'failed': failureCount,
        'failed_subscriptions': failedSubscriptions,
        'success_rate': successCount / dueSubscriptions.length,
        'processed_at': DateTime.now().toIso8601String(),
      };

      await _auditService.logPaymentRequest(
        type: 'BATCH_RECURRING_PAYMENT',
        status: 'COMPLETED',
        details: result,
      );

      debugPrint('✅ Batch recurring payment completed: $successCount/${dueSubscriptions.length} successful');
      
      return result;
    } catch (e) {
      debugPrint('❌ Error processing batch recurring payments: $e');
      
      await _auditService.logPaymentError(
        type: 'BATCH_RECURRING_PAYMENT_ERROR',
        error: e.toString(),
        metadata: {},
      );

      return {
        'total_processed': 0,
        'successful': 0,
        'failed': 0,
        'error': e.toString(),
      };
    }
  }

  /// Handle dunning management for overdue subscriptions
  Future<void> processDunningManagement() async {
    try {
      debugPrint('📧 Processing dunning management');
      
      final pastDueSubscriptions = await _repository.getSubscriptionsByStatus(
        SubscriptionStatus.pastDue
      );

      for (final subscription in pastDueSubscriptions) {
        final daysPastDue = _getDaysPastDue(subscription);
        final failureCount = await _getFailureCount(subscription.id);

        if (daysPastDue >= 30 && failureCount >= 3) {
          // Cancel subscription after 30 days and 3 failures
          await _cancelOverdueSubscription(subscription.id);
        } else if (daysPastDue >= 14 && failureCount >= 2) {
          // Final warning at 14 days
          await _sendFinalWarningNotification(subscription);
        } else if (daysPastDue >= 7 && failureCount >= 1) {
          // Reminder at 7 days
          await _sendPaymentReminderNotification(subscription);
        }
      }
    } catch (e) {
      debugPrint('❌ Error processing dunning management: $e');
    }
  }

  // Private helper methods

  bool _isEligibleForRecurringPayment(Subscription subscription) {
    return subscription.status == SubscriptionStatus.active &&
           subscription.paymentMethodId != null &&
           !subscription.isExpired;
  }

  Future<void> _handleSuccessfulPayment(Subscription subscription, PaymentResult paymentResult) async {
    final nextPaymentDate = DateTime.now().add(const Duration(days: 30));
    
    await _repository.updateSubscription(subscription.id, {
      'status': SubscriptionStatus.active.id,
      'lastPaymentDate': Timestamp.now(),
      'lastPaymentId': paymentResult.paymentId,
      'nextPaymentDate': Timestamp.fromDate(nextPaymentDate),
      'failureCount': 0,
      'lastFailedPaymentAt': null,
      'lastFailedPaymentError': null,
      'updatedAt': Timestamp.now(),
    });

    await _repository.recordSubscriptionPayment(
      subscriptionId: subscription.id,
      paymentId: paymentResult.paymentId!,
      amount: paymentResult.amount ?? 0.0,
      status: 'completed',
      metadata: paymentResult.metadata,
    );

    debugPrint('✅ Successful payment processed for subscription: ${subscription.id}');
  }

  Future<void> _handleFailedPayment(Subscription subscription, PaymentResult paymentResult) async {
    await handleFailedPayment(subscription.id, paymentResult.error ?? 'Unknown payment error');
  }

  Future<int> _getFailureCount(String subscriptionId) async {
    try {
      final doc = await _firestore.collection('subscriptions').doc(subscriptionId).get();
      if (doc.exists) {
        return doc.data()?['failureCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  int _getDaysPastDue(Subscription subscription) {
    if (subscription.nextPaymentDate == null) return 0;
    return DateTime.now().difference(subscription.nextPaymentDate!).inDays;
  }

  String _getCurrentBillingPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> _schedulePaymentRetry(String subscriptionId, int failureCount) async {
    // Schedule retry based on exponential backoff
    final retryDelays = [1, 3, 7]; // days
    final retryIndex = failureCount - 1;
    
    if (retryIndex < retryDelays.length) {
      final retryDate = DateTime.now().add(Duration(days: retryDelays[retryIndex]));
      
      await _firestore.collection('subscription_retries').add({
        'subscription_id': subscriptionId,
        'scheduled_at': Timestamp.fromDate(retryDate),
        'attempt_number': failureCount,
        'created_at': Timestamp.now(),
        'status': 'scheduled',
      });

      debugPrint('📅 Payment retry scheduled for $subscriptionId on $retryDate');
    }
  }

  Future<void> _sendPaymentFailureNotification(Subscription subscription, String reason, int failureCount) async {
    // This would integrate with your notification service
    debugPrint('📧 Sending payment failure notification for ${subscription.id}');
    
    // TODO: Integrate with notification service
    // await NotificationService.sendPaymentFailureNotification(
    //   userId: subscription.userId,
    //   reason: reason,
    //   failureCount: failureCount,
    // );
  }

  Future<void> _sendPaymentSuccessNotification(Subscription subscription) async {
    // This would integrate with your notification service
    debugPrint('📧 Sending payment success notification for ${subscription.id}');
    
    // TODO: Integrate with notification service
    // await NotificationService.sendPaymentSuccessNotification(
    //   userId: subscription.userId,
    //   subscription: subscription,
    // );
  }

  Future<void> _sendPaymentReminderNotification(Subscription subscription) async {
    debugPrint('📧 Sending payment reminder for ${subscription.id}');
    // TODO: Integrate with notification service
  }

  Future<void> _sendFinalWarningNotification(Subscription subscription) async {
    debugPrint('📧 Sending final warning for ${subscription.id}');
    // TODO: Integrate with notification service
  }

  Future<void> _handleExcessiveFailures(String subscriptionId) async {
    debugPrint('⚠️ Handling excessive failures for subscription: $subscriptionId');
    
    // Don't immediately cancel, but mark for manual review
    await _repository.updateSubscription(subscriptionId, {
      'status': SubscriptionStatus.unpaid.id,
      'needsManualReview': true,
      'excessiveFailuresAt': Timestamp.now(),
    });
  }

  Future<void> _cancelOverdueSubscription(String subscriptionId) async {
    debugPrint('❌ Canceling overdue subscription: $subscriptionId');
    
    await _repository.updateSubscription(subscriptionId, {
      'status': SubscriptionStatus.canceled.id,
      'canceledAt': Timestamp.now(),
      'cancelReason': 'payment_failure_after_dunning',
    });
  }
}