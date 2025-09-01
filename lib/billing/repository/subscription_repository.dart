import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/subscription_models.dart';

/// Repository for subscription data access using Firestore
class SubscriptionRepository {
  final FirebaseFirestore _firestore;
  
  static const String _subscriptionsCollection = 'subscriptions';
  static const String _usageRecordsCollection = 'subscription_usage';
  static const String _subscriptionPaymentsCollection = 'subscription_payments';

  SubscriptionRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new subscription
  Future<void> createSubscription(Subscription subscription) async {
    try {
      await _firestore
          .collection(_subscriptionsCollection)
          .doc(subscription.id)
          .set(subscription.toFirestore());
      
      debugPrint('✅ Subscription created: ${subscription.id} for user ${subscription.userId}');
    } catch (e) {
      debugPrint('❌ Error creating subscription: $e');
      rethrow;
    }
  }

  /// Get subscription by ID
  Future<Subscription?> getSubscription(String subscriptionId) async {
    try {
      final doc = await _firestore
          .collection(_subscriptionsCollection)
          .doc(subscriptionId)
          .get();
      
      if (doc.exists) {
        return Subscription.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting subscription $subscriptionId: $e');
      rethrow;
    }
  }

  /// Get active subscription for user
  Future<Subscription?> getActiveSubscriptionForUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_subscriptionsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['active', 'trialing'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return Subscription.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting active subscription for user $userId: $e');
      rethrow;
    }
  }

  /// Get all subscriptions for user
  Future<List<Subscription>> getUserSubscriptions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_subscriptionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Subscription.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting subscriptions for user $userId: $e');
      rethrow;
    }
  }

  /// Stream active subscription for user
  Stream<Subscription?> subscriptionStream(String userId) {
    return _firestore
        .collection(_subscriptionsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'trialing'])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return Subscription.fromFirestore(snapshot.docs.first);
          }
          return null;
        });
  }

  /// Update subscription
  Future<void> updateSubscription(String subscriptionId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      
      await _firestore
          .collection(_subscriptionsCollection)
          .doc(subscriptionId)
          .update(updates);
      
      debugPrint('✅ Subscription updated: $subscriptionId');
    } catch (e) {
      debugPrint('❌ Error updating subscription $subscriptionId: $e');
      rethrow;
    }
  }

  /// Update subscription status
  Future<void> updateSubscriptionStatus(String subscriptionId, SubscriptionStatus status) async {
    try {
      await updateSubscription(subscriptionId, {
        'status': status.id,
      });
    } catch (e) {
      debugPrint('❌ Error updating subscription status: $e');
      rethrow;
    }
  }

  /// Get subscriptions by status
  Future<List<Subscription>> getSubscriptionsByStatus(SubscriptionStatus status) async {
    try {
      final querySnapshot = await _firestore
          .collection(_subscriptionsCollection)
          .where('status', isEqualTo: status.id)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Subscription.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting subscriptions by status ${status.id}: $e');
      rethrow;
    }
  }

  /// Get expiring trials (within days)
  Future<List<Subscription>> getExpiringTrials({int daysAhead = 3}) async {
    try {
      final futureDate = DateTime.now().add(Duration(days: daysAhead));
      
      final querySnapshot = await _firestore
          .collection(_subscriptionsCollection)
          .where('status', isEqualTo: 'trialing')
          .where('trialEndDate', isLessThan: Timestamp.fromDate(futureDate))
          .where('trialEndDate', isGreaterThan: Timestamp.now())
          .get();
      
      return querySnapshot.docs
          .map((doc) => Subscription.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting expiring trials: $e');
      rethrow;
    }
  }

  /// Get subscriptions due for payment
  Future<List<Subscription>> getSubscriptionsDueForPayment() async {
    try {
      final now = DateTime.now();
      
      final querySnapshot = await _firestore
          .collection(_subscriptionsCollection)
          .where('status', isEqualTo: 'active')
          .where('nextPaymentDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();
      
      return querySnapshot.docs
          .map((doc) => Subscription.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting subscriptions due for payment: $e');
      rethrow;
    }
  }

  /// Create usage record for usage-based subscriptions
  Future<void> createUsageRecord(UsageRecord usageRecord) async {
    try {
      await _firestore
          .collection(_usageRecordsCollection)
          .doc(usageRecord.id)
          .set(usageRecord.toFirestore());
      
      debugPrint('✅ Usage record created: ${usageRecord.id}');
    } catch (e) {
      debugPrint('❌ Error creating usage record: $e');
      rethrow;
    }
  }

  /// Get usage records for subscription
  Future<List<UsageRecord>> getUsageRecords({
    required String subscriptionId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_usageRecordsCollection)
          .where('subscriptionId', isEqualTo: subscriptionId);
      
      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      final querySnapshot = await query
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UsageRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting usage records for subscription $subscriptionId: $e');
      rethrow;
    }
  }

  /// Get monthly usage summary
  Future<double> getMonthlyUsageCost({
    required String subscriptionId,
    required DateTime month,
  }) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      
      final usageRecords = await getUsageRecords(
        subscriptionId: subscriptionId,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );
      
      double totalCost = 0.0;
      for (final record in usageRecords) {
        totalCost += record.totalCost;
      }
      
      return totalCost;
    } catch (e) {
      debugPrint('❌ Error getting monthly usage cost: $e');
      rethrow;
    }
  }

  /// Record subscription payment
  Future<void> recordSubscriptionPayment({
    required String subscriptionId,
    required String paymentId,
    required double amount,
    required String status,
    String? invoiceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore
          .collection(_subscriptionPaymentsCollection)
          .doc(paymentId)
          .set({
        'subscriptionId': subscriptionId,
        'paymentId': paymentId,
        'amount': amount,
        'status': status,
        'invoiceId': invoiceId,
        'metadata': metadata ?? {},
        'processedAt': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });
      
      debugPrint('✅ Subscription payment recorded: $paymentId');
    } catch (e) {
      debugPrint('❌ Error recording subscription payment: $e');
      rethrow;
    }
  }

  /// Get payment history for subscription
  Future<List<Map<String, dynamic>>> getPaymentHistory(String subscriptionId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_subscriptionPaymentsCollection)
          .where('subscriptionId', isEqualTo: subscriptionId)
          .orderBy('processedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting payment history for subscription $subscriptionId: $e');
      rethrow;
    }
  }

  /// Delete subscription (soft delete by setting status to canceled)
  Future<void> deleteSubscription(String subscriptionId) async {
    try {
      await updateSubscriptionStatus(subscriptionId, SubscriptionStatus.canceled);
      debugPrint('✅ Subscription soft deleted: $subscriptionId');
    } catch (e) {
      debugPrint('❌ Error deleting subscription $subscriptionId: $e');
      rethrow;
    }
  }

  /// Get subscription analytics data
  Future<Map<String, dynamic>> getSubscriptionAnalytics() async {
    try {
      // Get all active subscriptions
      final activeSubscriptions = await getSubscriptionsByStatus(SubscriptionStatus.active);
      final trialSubscriptions = await getSubscriptionsByStatus(SubscriptionStatus.trialing);
      
      // Calculate MRR (Monthly Recurring Revenue)
      double mrr = 0.0;
      for (final subscription in activeSubscriptions) {
        mrr += subscription.monthlyPrice;
      }
      
      // Group by tier
      final Map<String, int> tierCounts = {};
      for (final subscription in [...activeSubscriptions, ...trialSubscriptions]) {
        tierCounts[subscription.tier.id] = (tierCounts[subscription.tier.id] ?? 0) + 1;
      }
      
      return {
        'totalActiveSubscriptions': activeSubscriptions.length,
        'totalTrialSubscriptions': trialSubscriptions.length,
        'monthlyRecurringRevenue': mrr,
        'averageRevenuePerUser': activeSubscriptions.isNotEmpty ? mrr / activeSubscriptions.length : 0.0,
        'subscriptionsByTier': tierCounts,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting subscription analytics: $e');
      rethrow;
    }
  }

  /// Batch update subscriptions
  Future<void> batchUpdateSubscriptions(List<Map<String, dynamic>> updates) async {
    try {
      final batch = _firestore.batch();
      
      for (final update in updates) {
        final subscriptionRef = _firestore
            .collection(_subscriptionsCollection)
            .doc(update['id']);
        
        final updateData = Map<String, dynamic>.from(update);
        updateData.remove('id');
        updateData['updatedAt'] = Timestamp.now();
        
        batch.update(subscriptionRef, updateData);
      }
      
      await batch.commit();
      debugPrint('✅ Batch updated ${updates.length} subscriptions');
    } catch (e) {
      debugPrint('❌ Error batch updating subscriptions: $e');
      rethrow;
    }
  }

  /// Health check - verify repository connectivity
  Future<bool> healthCheck() async {
    try {
      await _firestore
          .collection(_subscriptionsCollection)
          .limit(1)
          .get();
      return true;
    } catch (e) {
      debugPrint('❌ Subscription repository health check failed: $e');
      return false;
    }
  }
}