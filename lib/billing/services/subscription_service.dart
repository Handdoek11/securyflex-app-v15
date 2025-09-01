import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/subscription_models.dart';
import '../repository/subscription_repository.dart';
import '../../payments/services/payment_integration_service.dart';
import '../../payments/services/dutch_invoice_service.dart';
import '../../payments/models/payment_models.dart';
import '../../payments/repository/payment_repository.dart';
import '../../payments/services/sepa_payment_service.dart';
import '../../payments/services/payment_audit_service.dart';
import '../../beveiliger_dashboard/services/enhanced_earnings_service.dart';
import '../../schedule/services/payroll_export_service.dart';
import '../../auth/auth_service.dart';

/// Core subscription management service for SecuryFlex
/// Handles subscription creation, updates, trials, and integrates with payment systems
class SubscriptionService {
  final SubscriptionRepository _repository;
  final PaymentIntegrationService _paymentService;
  final DutchInvoiceService _invoiceService;

  static SubscriptionService? _instance;
  static SubscriptionService get instance {
    if (_instance == null) {
      // Create minimal instance for development
      // In production, proper dependency injection would be used
      _instance = SubscriptionService(
        repository: SubscriptionRepository(),
        paymentService: _createMockPaymentService(),
        invoiceService: _createMockInvoiceService(),
      );
    }
    return _instance!;
  }
  
  static PaymentIntegrationService _createMockPaymentService() {
    // Create mock services for development
    final paymentRepo = FirestorePaymentRepository();
    final sepaService = SepaPaymentService();
    final invoiceService = DutchInvoiceService();
    final auditService = PaymentAuditService();
    final earningsService = EnhancedEarningsService.instance;
    final payrollService = PayrollExportService();
    
    return PaymentIntegrationService(
      paymentRepository: paymentRepo,
      sepaService: sepaService,
      invoiceService: invoiceService,
      auditService: auditService,
      earningsService: earningsService,
      payrollService: payrollService,
    );
  }
  
  static DutchInvoiceService _createMockInvoiceService() {
    return DutchInvoiceService();
  }

  SubscriptionService({
    required SubscriptionRepository repository,
    required PaymentIntegrationService paymentService,
    required DutchInvoiceService invoiceService,
  }) : _repository = repository,
       _paymentService = paymentService,
       _invoiceService = invoiceService;

  /// Create a new subscription for a user
  Future<SubscriptionResult> createSubscription({
    required String userId,
    required SubscriptionTier tier,
    bool startTrial = false,
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('🔄 Creating subscription for user $userId with tier ${tier.displayName}');
      
      // Check if user already has an active subscription
      final existingSubscription = await _repository.getActiveSubscriptionForUser(userId);
      if (existingSubscription != null) {
        return SubscriptionResult.error(
          'Gebruiker heeft al een actief abonnement: ${existingSubscription.tier.displayName}'
        );
      }

      // Generate unique subscription ID
      final subscriptionId = 'sub_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      // Determine trial settings
      DateTime? trialEndDate;
      SubscriptionStatus initialStatus;
      
      if (startTrial && tier == SubscriptionTier.zzpGuard) {
        trialEndDate = now.add(const Duration(days: 30));
        initialStatus = SubscriptionStatus.trialing;
      } else if (startTrial && tier.id.startsWith('company')) {
        trialEndDate = now.add(const Duration(days: 14)); // Shorter trial for companies
        initialStatus = SubscriptionStatus.trialing;
      } else {
        initialStatus = SubscriptionStatus.incomplete; // Requires payment setup
      }

      // Get user info for Dutch compliance
      final userInfo = await _getUserComplianceInfo(userId);

      // Calculate next payment date
      DateTime? nextPaymentDate;
      if (initialStatus == SubscriptionStatus.trialing) {
        nextPaymentDate = trialEndDate;
      } else if (initialStatus == SubscriptionStatus.active) {
        nextPaymentDate = DateTime(now.year, now.month + 1, now.day);
      }

      // Create subscription object
      final subscription = Subscription(
        id: subscriptionId,
        userId: userId,
        tier: tier,
        status: initialStatus,
        startDate: now,
        trialEndDate: trialEndDate,
        monthlyPrice: tier.pricePerMonth,
        currency: 'EUR',
        features: tier.features,
        limits: tier.limits,
        createdAt: now,
        updatedAt: now,
        isBtwExempt: userInfo['isBtwExempt'] ?? false,
        btwRate: 0.21,
        btwNumber: userInfo['btwNumber'],
        companyName: userInfo['companyName'],
        kvkNumber: userInfo['kvkNumber'],
        paymentMethodId: paymentMethodId,
        nextPaymentDate: nextPaymentDate,
      );

      // Save to database
      await _repository.createSubscription(subscription);

      // If not a trial, process initial payment
      if (initialStatus != SubscriptionStatus.trialing && paymentMethodId != null) {
        final paymentResult = await _processInitialPayment(subscription, paymentMethodId);
        if (!paymentResult.success) {
          // Clean up failed subscription
          await _repository.deleteSubscription(subscriptionId);
          return SubscriptionResult.error(paymentResult.error ?? 'Payment failed');
        }
      }

      debugPrint('✅ Subscription created successfully: $subscriptionId');
      
      return SubscriptionResult.success(
        subscription,
        metadata: {
          'trial_started': startTrial,
          'trial_end_date': trialEndDate?.toIso8601String(),
          'initial_status': initialStatus.id,
        },
      );
    } catch (e) {
      debugPrint('❌ Error creating subscription: $e');
      return SubscriptionResult.error('Fout bij aanmaken abonnement: $e');
    }
  }

  /// Get active subscription for user
  Future<Subscription?> getActiveSubscription(String userId) async {
    try {
      return await _repository.getActiveSubscriptionForUser(userId);
    } catch (e) {
      debugPrint('❌ Error getting active subscription: $e');
      return null;
    }
  }

  /// Get all subscriptions for user
  Future<List<Subscription>> getUserSubscriptions(String userId) async {
    try {
      return await _repository.getUserSubscriptions(userId);
    } catch (e) {
      debugPrint('❌ Error getting user subscriptions: $e');
      return [];
    }
  }

  /// Stream active subscription for user
  Stream<Subscription?> subscriptionStream(String userId) {
    return _repository.subscriptionStream(userId);
  }

  /// Upgrade subscription to higher tier
  Future<SubscriptionResult> upgradeSubscription({
    required String subscriptionId,
    required SubscriptionTier newTier,
    String? paymentMethodId,
    bool prorated = true,
  }) async {
    try {
      debugPrint('🔄 Upgrading subscription $subscriptionId to ${newTier.displayName}');
      
      final subscription = await _repository.getSubscription(subscriptionId);
      if (subscription == null) {
        return SubscriptionResult.error('Abonnement niet gevonden');
      }

      if (!subscription.status.isActive) {
        return SubscriptionResult.error('Kan alleen actieve abonnementen upgraden');
      }

      // Calculate prorated amount if applicable
      double proratedAmount = 0.0;
      if (prorated && subscription.nextPaymentDate != null) {
        proratedAmount = _calculateProratedAmount(
          subscription,
          newTier,
          subscription.nextPaymentDate!,
        );
      }

      // Update subscription
      final updatedSubscription = subscription.copyWith(
        tier: newTier,
        monthlyPrice: newTier.pricePerMonth,
        features: newTier.features,
        limits: newTier.limits,
        updatedAt: DateTime.now(),
      );

      await _repository.updateSubscription(subscriptionId, updatedSubscription.toFirestore());

      // Process prorated payment if needed
      if (proratedAmount > 0 && paymentMethodId != null) {
        await _processUpgradePayment(updatedSubscription, proratedAmount, paymentMethodId);
      }

      debugPrint('✅ Subscription upgraded successfully: $subscriptionId');
      
      return SubscriptionResult.success(
        updatedSubscription,
        metadata: {
          'prorated_amount': proratedAmount,
          'upgrade_date': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('❌ Error upgrading subscription: $e');
      return SubscriptionResult.error('Fout bij upgraden abonnement: $e');
    }
  }

  /// Cancel subscription
  Future<SubscriptionResult> cancelSubscription({
    required String subscriptionId,
    DateTime? endDate,
    String? reason,
    bool immediate = false,
  }) async {
    try {
      debugPrint('🔄 Canceling subscription $subscriptionId');
      
      final subscription = await _repository.getSubscription(subscriptionId);
      if (subscription == null) {
        return SubscriptionResult.error('Abonnement niet gevonden');
      }

      final now = DateTime.now();
      final cancelEndDate = immediate ? now : (endDate ?? subscription.nextPaymentDate ?? now);

      await _repository.updateSubscription(subscriptionId, {
        'status': SubscriptionStatus.canceled.id,
        'endDate': Timestamp.fromDate(cancelEndDate),
        'canceledAt': Timestamp.fromDate(now),
        'cancelReason': reason,
      });

      debugPrint('✅ Subscription canceled: $subscriptionId');
      
      final updatedSubscription = subscription.copyWith(
        status: SubscriptionStatus.canceled,
        endDate: cancelEndDate,
        updatedAt: now,
      );

      return SubscriptionResult.success(
        updatedSubscription,
        metadata: {
          'canceled_at': now.toIso8601String(),
          'cancel_reason': reason,
          'immediate': immediate,
        },
      );
    } catch (e) {
      debugPrint('❌ Error canceling subscription: $e');
      return SubscriptionResult.error('Fout bij annuleren abonnement: $e');
    }
  }

  /// Convert trial to paid subscription
  Future<SubscriptionResult> convertTrialToPaid({
    required String subscriptionId,
    required String paymentMethodId,
  }) async {
    try {
      debugPrint('🔄 Converting trial to paid: $subscriptionId');
      
      final subscription = await _repository.getSubscription(subscriptionId);
      if (subscription == null) {
        return SubscriptionResult.error('Abonnement niet gevonden');
      }

      if (subscription.status != SubscriptionStatus.trialing) {
        return SubscriptionResult.error('Alleen proefabonnementen kunnen worden geconverteerd');
      }

      // Process initial payment
      final paymentResult = await _processInitialPayment(subscription, paymentMethodId);
      if (!paymentResult.success) {
        return SubscriptionResult.error(paymentResult.error ?? 'Betaling mislukt');
      }

      // Update subscription to active
      final now = DateTime.now();
      final nextPaymentDate = DateTime(now.year, now.month + 1, now.day);

      await _repository.updateSubscription(subscriptionId, {
        'status': SubscriptionStatus.active.id,
        'paymentMethodId': paymentMethodId,
        'nextPaymentDate': Timestamp.fromDate(nextPaymentDate),
        'trialConvertedAt': Timestamp.fromDate(now),
      });

      debugPrint('✅ Trial converted to paid subscription: $subscriptionId');
      
      final updatedSubscription = subscription.copyWith(
        status: SubscriptionStatus.active,
        paymentMethodId: paymentMethodId,
        nextPaymentDate: nextPaymentDate,
        updatedAt: now,
      );

      return SubscriptionResult.success(
        updatedSubscription,
        metadata: {
          'converted_at': now.toIso8601String(),
          'payment_method_id': paymentMethodId,
        },
      );
    } catch (e) {
      debugPrint('❌ Error converting trial: $e');
      return SubscriptionResult.error('Fout bij converteren proefabonnement: $e');
    }
  }

  /// Process recurring payment for subscription
  Future<bool> processRecurringPayment(String subscriptionId) async {
    try {
      debugPrint('🔄 Processing recurring payment for: $subscriptionId');
      
      final subscription = await _repository.getSubscription(subscriptionId);
      if (subscription == null) {
        debugPrint('❌ Subscription not found for recurring payment: $subscriptionId');
        return false;
      }

      if (subscription.status != SubscriptionStatus.active || subscription.paymentMethodId == null) {
        debugPrint('❌ Subscription not eligible for recurring payment: $subscriptionId');
        return false;
      }

      // Process payment through existing payment service
      final paymentResult = await _processSubscriptionPayment(subscription);
      
      if (paymentResult.success) {
        // Update next payment date
        final nextPaymentDate = DateTime.now().add(const Duration(days: 30));
        await _repository.updateSubscription(subscriptionId, {
          'lastPaymentDate': Timestamp.now(),
          'nextPaymentDate': Timestamp.fromDate(nextPaymentDate),
          'lastPaymentId': paymentResult.metadata?['payment_id'],
        });

        debugPrint('✅ Recurring payment processed: $subscriptionId');
        return true;
      } else {
        // Handle failed payment
        await _handleFailedPayment(subscriptionId, paymentResult.error ?? 'Unknown error');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error processing recurring payment: $e');
      return false;
    }
  }

  /// Handle expired trials
  Future<void> handleTrialExpiration(String subscriptionId) async {
    try {
      debugPrint('🔄 Handling trial expiration for: $subscriptionId');
      
      final subscription = await _repository.getSubscription(subscriptionId);
      if (subscription == null) return;

      if (subscription.status != SubscriptionStatus.trialing) {
        debugPrint('⚠️ Subscription is not in trial status: $subscriptionId');
        return;
      }

      // Check if trial has actually expired
      if (subscription.trialEndDate == null || DateTime.now().isBefore(subscription.trialEndDate!)) {
        debugPrint('⚠️ Trial has not expired yet: $subscriptionId');
        return;
      }

      // Update status to expired
      await _repository.updateSubscription(subscriptionId, {
        'status': SubscriptionStatus.expired.id,
        'trialExpiredAt': Timestamp.now(),
      });

      debugPrint('✅ Trial marked as expired: $subscriptionId');
    } catch (e) {
      debugPrint('❌ Error handling trial expiration: $e');
    }
  }

  /// Get expiring trials
  Future<List<Subscription>> getExpiringTrials({int daysAhead = 3}) async {
    try {
      return await _repository.getExpiringTrials(daysAhead: daysAhead);
    } catch (e) {
      debugPrint('❌ Error getting expiring trials: $e');
      return [];
    }
  }

  /// Record usage for usage-based subscriptions
  Future<bool> recordUsage({
    required String subscriptionId,
    required String usageType,
    required double quantity,
    required double unitPrice,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final totalCost = quantity * unitPrice;
      final usageRecord = UsageRecord(
        id: 'usage_${subscriptionId}_${DateTime.now().millisecondsSinceEpoch}',
        subscriptionId: subscriptionId,
        userId: '', // Will be filled from subscription
        date: DateTime.now(),
        usageType: usageType,
        quantity: quantity,
        unitPrice: unitPrice,
        totalCost: totalCost,
        metadata: metadata ?? {},
        createdAt: DateTime.now(),
      );

      await _repository.createUsageRecord(usageRecord);
      debugPrint('✅ Usage recorded: ${usageRecord.id}');
      
      return true;
    } catch (e) {
      debugPrint('❌ Error recording usage: $e');
      return false;
    }
  }

  /// Get subscription analytics
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      return await _repository.getSubscriptionAnalytics();
    } catch (e) {
      debugPrint('❌ Error getting analytics: $e');
      return {};
    }
  }

  // Private helper methods

  /// Get user compliance information for Dutch regulations
  Future<Map<String, dynamic>> _getUserComplianceInfo(String userId) async {
    try {
      // Get user document from auth service
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        return {};
      }

      final userData = userDoc.data()!;
      
      return {
        'companyName': userData['companyName'],
        'kvkNumber': userData['kvkNumber'],
        'btwNumber': userData['btwNumber'],
        'isBtwExempt': userData['isBtwExempt'] ?? false,
      };
    } catch (e) {
      debugPrint('❌ Error getting user compliance info: $e');
      return {};
    }
  }

  /// Process initial payment for new subscription
  Future<SubscriptionResult> _processInitialPayment(Subscription subscription, String paymentMethodId) async {
    try {
      debugPrint('🔄 Processing initial payment for subscription: ${subscription.id}');
      
      final amount = subscription.priceWithBTW;
      
      // Use existing payment integration service
      final paymentResult = await _processSubscriptionPayment(subscription);
      
      if (paymentResult.success) {
        // Record payment
        await _repository.recordSubscriptionPayment(
          subscriptionId: subscription.id,
          paymentId: paymentResult.metadata?['payment_id'] ?? '',
          amount: amount,
          status: 'completed',
          metadata: {
            'type': 'initial_payment',
            'tier': subscription.tier.id,
          },
        );

        return SubscriptionResult.success(subscription);
      } else {
        return SubscriptionResult.error(paymentResult.error ?? 'Payment failed');
      }
    } catch (e) {
      debugPrint('❌ Error processing initial payment: $e');
      return SubscriptionResult.error('Payment processing error: $e');
    }
  }

  /// Process subscription payment using existing payment service
  Future<SubscriptionResult> _processSubscriptionPayment(Subscription subscription) async {
    try {
      // This would integrate with the existing PaymentIntegrationService
      // For now, we'll simulate a successful payment
      // In real implementation, this would call the actual payment processor
      
      debugPrint('💰 Processing payment for subscription: ${subscription.id}');
      debugPrint('💰 Amount: €${subscription.priceWithBTW.toStringAsFixed(2)}');
      
      // Simulate payment processing delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Generate mock payment ID
      final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      
      return SubscriptionResult.success(
        subscription,
        metadata: {
          'payment_id': paymentId,
          'amount': subscription.priceWithBTW,
          'currency': 'EUR',
          'processed_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      return SubscriptionResult.error('Payment processing failed: $e');
    }
  }

  /// Process upgrade payment
  Future<void> _processUpgradePayment(Subscription subscription, double amount, String paymentMethodId) async {
    // Implementation for prorated upgrade payments
    debugPrint('💰 Processing upgrade payment: €${amount.toStringAsFixed(2)}');
  }

  /// Calculate prorated amount for tier changes
  double _calculateProratedAmount(Subscription subscription, SubscriptionTier newTier, DateTime nextPaymentDate) {
    final now = DateTime.now();
    final daysRemaining = nextPaymentDate.difference(now).inDays;
    final totalDaysInMonth = 30;
    
    final currentTierDailyRate = subscription.monthlyPrice / totalDaysInMonth;
    final newTierDailyRate = newTier.pricePerMonth / totalDaysInMonth;
    
    final proratedAmount = (newTierDailyRate - currentTierDailyRate) * daysRemaining;
    
    return proratedAmount > 0 ? proratedAmount : 0.0;
  }

  /// Handle failed payment
  Future<void> _handleFailedPayment(String subscriptionId, String error) async {
    try {
      debugPrint('⚠️ Handling failed payment for: $subscriptionId - $error');
      
      await _repository.updateSubscription(subscriptionId, {
        'status': SubscriptionStatus.pastDue.id,
        'lastFailedPaymentAt': Timestamp.now(),
        'lastFailedPaymentError': error,
      });
    } catch (e) {
      debugPrint('❌ Error handling failed payment: $e');
    }
  }

  /// Get billing history for user
  Future<List<Map<String, dynamic>>> getBillingHistory(String userId) async {
    try {
      // TODO: Replace with actual payment history from payment service
      // For now, return mock data
      return [
        {
          'id': 'invoice_001',
          'date': DateTime.now().subtract(const Duration(days: 30)),
          'amount': 4.99,
          'status': 'paid',
          'description': 'ZZP Beveiliger - Maandelijks abonnement',
          'invoice_url': null,
        },
        {
          'id': 'invoice_002',
          'date': DateTime.now().subtract(const Duration(days: 60)),
          'amount': 4.99,
          'status': 'paid',
          'description': 'ZZP Beveiliger - Maandelijks abonnement',
          'invoice_url': null,
        },
      ];
    } catch (e) {
      debugPrint('❌ Error getting billing history: $e');
      return [];
    }
  }

  /// Start trial for user (wrapper around createSubscription)
  Future<SubscriptionResult> startTrial({
    required String userId,
    required SubscriptionTier tier,
  }) async {
    try {
      if (!tier.hasTrialPeriod) {
        return SubscriptionResult.error('Geen proefperiode beschikbaar voor ${tier.displayName}');
      }

      // Check if user already has subscription
      final existingSubscription = await getActiveSubscription(userId);
      if (existingSubscription != null) {
        return SubscriptionResult.error('Gebruiker heeft al een actief abonnement');
      }

      // Create trial subscription
      final now = DateTime.now();
      final trialSubscription = Subscription(
        id: 'sub_${now.millisecondsSinceEpoch}_${userId.hashCode}',
        userId: userId,
        tier: tier,
        status: SubscriptionStatus.trialing,
        startDate: now,
        trialEndDate: now.add(const Duration(days: 30)), // 30-day trial
        monthlyPrice: tier.pricePerMonth,
        currency: 'EUR',
        features: tier.features,
        limits: tier.limits,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.createSubscription(trialSubscription);
      return SubscriptionResult.success(trialSubscription);
    } catch (e) {
      debugPrint('❌ Error starting trial: $e');
      return SubscriptionResult.error('Fout bij starten proefperiode: $e');
    }
  }

  /// Resume canceled subscription
  Future<SubscriptionResult> resumeSubscription({
    required String subscriptionId,
  }) async {
    try {
      final subscription = await _repository.getSubscription(subscriptionId);
      if (subscription == null) {
        return SubscriptionResult.error('Abonnement niet gevonden');
      }

      if (subscription.status != SubscriptionStatus.canceled) {
        return SubscriptionResult.error('Alleen geannuleerde abonnementen kunnen worden hervat');
      }

      await _repository.updateSubscription(subscriptionId, {
        'status': SubscriptionStatus.active.id,
        'endDate': null, // Remove end date
        'resumedAt': Timestamp.now(),
      });

      final resumedSubscription = subscription.copyWith(
        status: SubscriptionStatus.active,
        endDate: null,
        updatedAt: DateTime.now(),
      );

      return SubscriptionResult.success(resumedSubscription);
    } catch (e) {
      debugPrint('❌ Error resuming subscription: $e');
      return SubscriptionResult.error('Fout bij hervatten abonnement: $e');
    }
  }

  /// Update payment method for subscription
  Future<bool> updatePaymentMethod({
    required String subscriptionId,
    required String paymentMethodId,
  }) async {
    try {
      final subscription = await _repository.getSubscription(subscriptionId);
      if (subscription == null) {
        debugPrint('❌ Subscription not found: $subscriptionId');
        return false;
      }

      await _repository.updateSubscription(subscriptionId, {
        'paymentMethodId': paymentMethodId,
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Payment method updated for subscription: $subscriptionId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating payment method: $e');
      return false;
    }
  }
}