import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/subscription_models.dart';
import '../repository/subscription_repository.dart';
import 'subscription_service.dart';
import '../../payments/services/payment_audit_service.dart';

/// Trial period management service for SecuryFlex subscriptions
/// Handles trial creation, monitoring, expiration, and conversion
class TrialManagerService {
  final SubscriptionRepository _repository;
  final SubscriptionService _subscriptionService;
  final PaymentAuditService _auditService;
  final FirebaseFirestore _firestore;

  // Trial periods by tier
  static const Map<SubscriptionTier, int> _trialPeriods = {
    SubscriptionTier.zzpGuard: 30,        // 30 days for ZZP guards
    SubscriptionTier.companyBasic: 14,    // 14 days for companies
    SubscriptionTier.companyProfessional: 14,
    SubscriptionTier.companyEnterprise: 14,
    SubscriptionTier.clientUsage: 0,      // No trial for usage-based
  };

  static TrialManagerService? _instance;
  static TrialManagerService get instance {
    _instance ??= TrialManagerService(
      repository: SubscriptionRepository(),
      subscriptionService: SubscriptionService.instance,
      auditService: PaymentAuditService(),
    );
    return _instance!;
  }

  TrialManagerService({
    required SubscriptionRepository repository,
    required SubscriptionService subscriptionService,
    required PaymentAuditService auditService,
    FirebaseFirestore? firestore,
  }) : _repository = repository,
       _subscriptionService = subscriptionService,
       _auditService = auditService,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Start trial for user
  Future<SubscriptionResult> startTrial({
    required String userId,
    required SubscriptionTier tier,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('🆓 Starting trial for user $userId, tier: ${tier.displayName}');
      
      // Check if user is eligible for trial
      final isEligible = await _isEligibleForTrial(userId, tier);
      if (!isEligible.success) {
        return isEligible;
      }

      // Get trial period for tier
      final trialDays = _trialPeriods[tier] ?? 0;
      if (trialDays == 0) {
        return SubscriptionResult.error('Trial not available for tier: ${tier.displayName}');
      }

      // Create subscription with trial status
      final subscriptionResult = await _subscriptionService.createSubscription(
        userId: userId,
        tier: tier,
        startTrial: true,
        metadata: {
          'trial_days': trialDays,
          'trial_started_at': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );

      if (subscriptionResult.success && subscriptionResult.subscription != null) {
        // Schedule trial expiration reminder
        await _scheduleTrialReminders(subscriptionResult.subscription!);
        
        // Record trial start
        await _recordTrialStart(subscriptionResult.subscription!);
        
        // Send welcome notification
        await _sendTrialWelcomeNotification(subscriptionResult.subscription!);
      }

      return subscriptionResult;
    } catch (e) {
      debugPrint('❌ Error starting trial: $e');
      
      await _auditService.logPaymentError(
        type: 'TRIAL_START_ERROR',
        error: e.toString(),
        metadata: {
          'user_id': userId,
          'tier': tier.id,
        },
      );

      return SubscriptionResult.error('Failed to start trial: $e');
    }
  }

  /// Check if user is eligible for trial
  Future<SubscriptionResult> _isEligibleForTrial(String userId, SubscriptionTier tier) async {
    try {
      // Check if user already had a trial for this tier
      final hadTrial = await _hasUserHadTrial(userId, tier);
      if (hadTrial) {
        return SubscriptionResult.error(
          'Je hebt al een gratis proefperiode gehad voor ${tier.displayName}'
        );
      }

      // Check if user already has an active subscription
      final activeSubscription = await _repository.getActiveSubscriptionForUser(userId);
      if (activeSubscription != null) {
        return SubscriptionResult.error(
          'Je hebt al een actief abonnement: ${activeSubscription.tier.displayName}'
        );
      }

      // Check user account status
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return SubscriptionResult.error('Gebruikersaccount niet gevonden');
      }

      final userData = userDoc.data()!;
      final accountStatus = userData['accountStatus'] ?? 'active';
      
      if (accountStatus != 'active') {
        return SubscriptionResult.error('Account moet actief zijn om een proefperiode te starten');
      }

      // Additional validation for company tiers
      if (tier.id.startsWith('company')) {
        final kvkNumber = userData['kvkNumber'];
        if (kvkNumber == null || kvkNumber.isEmpty) {
          return SubscriptionResult.error('KvK nummer vereist voor bedrijf abonnementen');
        }
      }

      return SubscriptionResult.success(
        Subscription(
          id: '',
          userId: userId,
          tier: tier,
          status: SubscriptionStatus.trialing,
          startDate: DateTime.now(),
          monthlyPrice: tier.pricePerMonth,
          currency: 'EUR',
          features: tier.features,
          limits: tier.limits,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return SubscriptionResult.error('Error checking trial eligibility: $e');
    }
  }

  /// Check if user has had a trial before
  Future<bool> _hasUserHadTrial(String userId, SubscriptionTier tier) async {
    try {
      final trialHistory = await _firestore
          .collection('trial_history')
          .where('user_id', isEqualTo: userId)
          .where('tier', isEqualTo: tier.id)
          .get();
      
      return trialHistory.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking trial history: $e');
      return false;
    }
  }

  /// Get expiring trials (within specified days)
  Future<List<Subscription>> getExpiringTrials({int daysAhead = 3}) async {
    try {
      return await _repository.getExpiringTrials(daysAhead: daysAhead);
    } catch (e) {
      debugPrint('❌ Error getting expiring trials: $e');
      return [];
    }
  }

  /// Process trial expiration for all expired trials
  Future<Map<String, dynamic>> processTrialExpirations() async {
    try {
      debugPrint('⏰ Processing trial expirations');
      
      // Get expired trials
      final expiredTrials = await _getExpiredTrials();
      
      if (expiredTrials.isEmpty) {
        return {
          'processed_count': 0,
          'expired_count': 0,
          'converted_count': 0,
          'message': 'No expired trials found',
        };
      }

      int expiredCount = 0;
      int convertedCount = 0;

      for (final subscription in expiredTrials) {
        try {
          // Check if user has set up payment method during trial
          final hasPaymentMethod = await _hasValidPaymentMethod(subscription.userId);
          
          if (hasPaymentMethod) {
            // Attempt to convert trial to paid
            final conversionResult = await _convertTrialToPaid(subscription);
            if (conversionResult.success) {
              convertedCount++;
              continue;
            }
          }
          
          // Expire the trial
          await _expireTrial(subscription);
          expiredCount++;
          
        } catch (e) {
          debugPrint('❌ Error processing trial ${subscription.id}: $e');
        }
      }

      final result = {
        'processed_count': expiredTrials.length,
        'expired_count': expiredCount,
        'converted_count': convertedCount,
        'conversion_rate': convertedCount / expiredTrials.length,
        'processed_at': DateTime.now().toIso8601String(),
      };

      await _auditService.logPaymentRequest(
        type: 'TRIAL_EXPIRATION_BATCH',
        status: 'COMPLETED',
        details: result,
      );

      debugPrint('✅ Trial expiration processing completed: $convertedCount converted, $expiredCount expired');
      
      return result;
    } catch (e) {
      debugPrint('❌ Error processing trial expirations: $e');
      return {
        'processed_count': 0,
        'expired_count': 0,
        'converted_count': 0,
        'error': e.toString(),
      };
    }
  }

  /// Convert trial to paid subscription
  Future<SubscriptionResult> convertTrialToPaid({
    required String subscriptionId,
    required String paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('💳 Converting trial to paid: $subscriptionId');
      
      final result = await _subscriptionService.convertTrialToPaid(
        subscriptionId: subscriptionId,
        paymentMethodId: paymentMethodId,
      );

      if (result.success && result.subscription != null) {
        await _recordTrialConversion(result.subscription!, metadata);
        await _sendTrialConversionNotification(result.subscription!);
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error converting trial: $e');
      return SubscriptionResult.error('Failed to convert trial: $e');
    }
  }

  /// Get trial analytics and insights
  Future<Map<String, dynamic>> getTrialAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Get trial history for period
      final trialHistoryQuery = await _firestore
          .collection('trial_history')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final trials = trialHistoryQuery.docs;
      final conversions = trials.where((doc) => doc.data()['converted'] == true).toList();

      // Group by tier
      final trialsByTier = <String, int>{};
      final conversionsByTier = <String, int>{};

      for (final doc in trials) {
        final tier = doc.data()['tier'] as String;
        trialsByTier[tier] = (trialsByTier[tier] ?? 0) + 1;
      }

      for (final doc in conversions) {
        final tier = doc.data()['tier'] as String;
        conversionsByTier[tier] = (conversionsByTier[tier] ?? 0) + 1;
      }

      return {
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
        'total_trials': trials.length,
        'total_conversions': conversions.length,
        'overall_conversion_rate': trials.isNotEmpty ? conversions.length / trials.length : 0.0,
        'trials_by_tier': trialsByTier,
        'conversions_by_tier': conversionsByTier,
        'conversion_rates_by_tier': trialsByTier.map((tier, trialCount) {
          final conversionCount = conversionsByTier[tier] ?? 0;
          return MapEntry(tier, trialCount > 0 ? conversionCount / trialCount : 0.0);
        }),
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting trial analytics: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  // Private helper methods

  Future<List<Subscription>> _getExpiredTrials() async {
    try {
      final now = DateTime.now();
      final trialSubscriptions = await _repository.getSubscriptionsByStatus(
        SubscriptionStatus.trialing
      );

      return trialSubscriptions.where((subscription) {
        return subscription.trialEndDate != null &&
               now.isAfter(subscription.trialEndDate!);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting expired trials: $e');
      return [];
    }
  }

  Future<bool> _hasValidPaymentMethod(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final paymentMethods = userDoc.data()?['paymentMethods'] as Map<String, dynamic>?;
      return paymentMethods != null && paymentMethods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<SubscriptionResult> _convertTrialToPaid(Subscription subscription) async {
    try {
      // Get user's default payment method
      final userDoc = await _firestore.collection('users').doc(subscription.userId).get();
      final paymentMethods = userDoc.data()?['paymentMethods'] as Map<String, dynamic>?;
      
      if (paymentMethods == null || paymentMethods.isEmpty) {
        return SubscriptionResult.error('No payment method available');
      }

      // Use first available payment method
      final paymentMethodId = paymentMethods.keys.first;
      
      return await convertTrialToPaid(
        subscriptionId: subscription.id,
        paymentMethodId: paymentMethodId,
        metadata: {'auto_converted': true},
      );
    } catch (e) {
      return SubscriptionResult.error('Auto-conversion failed: $e');
    }
  }

  Future<void> _expireTrial(Subscription subscription) async {
    await _subscriptionService.handleTrialExpiration(subscription.id);
    await _sendTrialExpiredNotification(subscription);
  }

  Future<void> _scheduleTrialReminders(Subscription subscription) async {
    if (subscription.trialEndDate == null) return;

    // Schedule reminders at 7 days, 3 days, and 1 day before expiration
    final reminderDays = [7, 3, 1];
    
    for (final days in reminderDays) {
      final reminderDate = subscription.trialEndDate!.subtract(Duration(days: days));
      
      if (reminderDate.isAfter(DateTime.now())) {
        await _firestore.collection('trial_reminders').add({
          'subscription_id': subscription.id,
          'user_id': subscription.userId,
          'reminder_date': Timestamp.fromDate(reminderDate),
          'days_before_expiration': days,
          'status': 'scheduled',
          'created_at': Timestamp.now(),
        });
      }
    }
  }

  Future<void> _recordTrialStart(Subscription subscription) async {
    await _firestore.collection('trial_history').add({
      'user_id': subscription.userId,
      'subscription_id': subscription.id,
      'tier': subscription.tier.id,
      'start_date': Timestamp.fromDate(subscription.startDate),
      'trial_end_date': subscription.trialEndDate != null 
          ? Timestamp.fromDate(subscription.trialEndDate!) 
          : null,
      'status': 'started',
      'converted': false,
      'created_at': Timestamp.now(),
    });
  }

  Future<void> _recordTrialConversion(Subscription subscription, Map<String, dynamic>? metadata) async {
    // Update trial history
    final trialHistoryQuery = await _firestore
        .collection('trial_history')
        .where('subscription_id', isEqualTo: subscription.id)
        .get();

    for (final doc in trialHistoryQuery.docs) {
      await doc.reference.update({
        'converted': true,
        'conversion_date': Timestamp.now(),
        'metadata': metadata ?? {},
      });
    }
  }

  // Notification methods (would integrate with actual notification service)
  
  Future<void> _sendTrialWelcomeNotification(Subscription subscription) async {
    debugPrint('📧 Sending trial welcome notification for ${subscription.id}');
    // TODO: Integrate with notification service
  }

  Future<void> _sendTrialConversionNotification(Subscription subscription) async {
    debugPrint('📧 Sending trial conversion notification for ${subscription.id}');
    // TODO: Integrate with notification service
  }

  Future<void> _sendTrialExpiredNotification(Subscription subscription) async {
    debugPrint('📧 Sending trial expired notification for ${subscription.id}');
    // TODO: Integrate with notification service
  }
}