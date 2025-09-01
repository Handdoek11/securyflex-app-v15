import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/subscription_models.dart';
import '../repository/subscription_repository.dart';
import 'subscription_service.dart';

/// Feature access control service for subscription-based features
/// Controls access to features based on subscription tiers and usage limits
class FeatureAccessService {
  final SubscriptionRepository _repository;
  final SubscriptionService _subscriptionService;
  final FirebaseFirestore _firestore;

  // Cache for subscription data to avoid repeated database calls
  final Map<String, Subscription?> _subscriptionCache = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};

  static FeatureAccessService? _instance;
  static FeatureAccessService get instance {
    _instance ??= FeatureAccessService(
      repository: SubscriptionRepository(),
      subscriptionService: SubscriptionService.instance,
    );
    return _instance!;
  }

  FeatureAccessService({
    required SubscriptionRepository repository,
    required SubscriptionService subscriptionService,
    FirebaseFirestore? firestore,
  }) : _repository = repository,
       _subscriptionService = subscriptionService,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Check if user has access to a specific feature
  Future<bool> hasFeatureAccess({
    required String userId,
    required String featureKey,
    Map<String, dynamic>? context,
  }) async {
    try {
      final subscription = await _getUserSubscriptionCached(userId);
      
      if (subscription == null) {
        // No subscription - only allow basic features
        return _isBasicFeature(featureKey);
      }

      // Check if subscription is active
      if (!subscription.status.isActive) {
        return _isBasicFeature(featureKey);
      }

      // Check feature availability for this tier
      final hasFeature = subscription.features[featureKey] ?? false;
      if (!hasFeature) {
        return false;
      }

      // Check usage limits if applicable
      final withinLimits = await _checkUsageLimits(
        userId: userId,
        subscription: subscription,
        featureKey: featureKey,
        context: context,
      );

      return withinLimits;
    } catch (e) {
      debugPrint('❌ Error checking feature access: $e');
      // Default to deny access on error for security
      return false;
    }
  }

  /// Get feature limits for a user's subscription
  Future<Map<String, int?>> getFeatureLimits(String userId) async {
    try {
      final subscription = await _getUserSubscriptionCached(userId);
      
      if (subscription == null) {
        return _getBasicFeatureLimits();
      }

      return subscription.limits;
    } catch (e) {
      debugPrint('❌ Error getting feature limits: $e');
      return _getBasicFeatureLimits();
    }
  }

  /// Check usage against limits for a specific feature
  Future<FeatureUsageStatus> checkFeatureUsage({
    required String userId,
    required String featureKey,
    Map<String, dynamic>? context,
  }) async {
    try {
      final subscription = await _getUserSubscriptionCached(userId);
      
      if (subscription == null) {
        return FeatureUsageStatus(
          hasAccess: _isBasicFeature(featureKey),
          currentUsage: 0,
          limit: null,
          remainingUsage: null,
          resetDate: null,
          upgradeRequired: true,
        );
      }

      final hasAccess = subscription.features[featureKey] ?? false;
      final limit = subscription.limits[_getUsageLimitKey(featureKey)];
      
      if (!hasAccess) {
        return FeatureUsageStatus(
          hasAccess: false,
          currentUsage: 0,
          limit: limit,
          remainingUsage: null,
          resetDate: null,
          upgradeRequired: true,
        );
      }

      // Get current usage
      final currentUsage = await _getCurrentUsage(userId, featureKey, context);
      final remainingUsage = limit != null ? (limit - currentUsage) : null;

      return FeatureUsageStatus(
        hasAccess: hasAccess && (limit == null || currentUsage < limit),
        currentUsage: currentUsage,
        limit: limit,
        remainingUsage: remainingUsage,
        resetDate: _getUsageResetDate(),
        upgradeRequired: hasAccess && limit != null && currentUsage >= limit,
      );
    } catch (e) {
      debugPrint('❌ Error checking feature usage: $e');
      return FeatureUsageStatus(
        hasAccess: false,
        currentUsage: 0,
        limit: null,
        remainingUsage: null,
        resetDate: null,
        upgradeRequired: true,
      );
    }
  }

  /// Record feature usage
  Future<bool> recordFeatureUsage({
    required String userId,
    required String featureKey,
    int quantity = 1,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final subscription = await _getUserSubscriptionCached(userId);
      
      if (subscription == null) {
        debugPrint('⚠️ No subscription found for usage recording: $userId');
        return false;
      }

      // Record usage in Firestore
      await _firestore.collection('feature_usage').add({
        'user_id': userId,
        'subscription_id': subscription.id,
        'feature_key': featureKey,
        'quantity': quantity,
        'tier': subscription.tier.id,
        'timestamp': Timestamp.now(),
        'month': DateTime.now().month,
        'year': DateTime.now().year,
        'metadata': metadata ?? {},
      });

      // Clear cache to ensure fresh data on next access
      _clearUserCache(userId);

      debugPrint('📊 Feature usage recorded: $userId -> $featureKey ($quantity)');
      return true;
    } catch (e) {
      debugPrint('❌ Error recording feature usage: $e');
      return false;
    }
  }

  /// Get detailed feature access summary for user
  Future<Map<String, dynamic>> getFeatureAccessSummary(String userId) async {
    try {
      final subscription = await _getUserSubscriptionCached(userId);
      
      if (subscription == null) {
        return {
          'has_subscription': false,
          'tier': null,
          'status': null,
          'features': _getBasicFeaturesSummary(),
          'upgrade_available': true,
        };
      }

      final featureSummary = <String, dynamic>{};
      
      // Check each feature
      for (final feature in _getAllFeatureKeys()) {
        final usage = await checkFeatureUsage(
          userId: userId,
          featureKey: feature,
        );
        
        featureSummary[feature] = {
          'has_access': usage.hasAccess,
          'current_usage': usage.currentUsage,
          'limit': usage.limit,
          'remaining': usage.remainingUsage,
          'upgrade_required': usage.upgradeRequired,
        };
      }

      return {
        'has_subscription': true,
        'tier': subscription.tier.id,
        'tier_name': subscription.tier.displayName,
        'status': subscription.status.id,
        'features': featureSummary,
        'trial_days_remaining': subscription.trialDaysRemaining,
        'next_payment_date': subscription.nextPaymentDate?.toIso8601String(),
        'upgrade_available': _hasUpgradeOptions(subscription.tier),
      };
    } catch (e) {
      debugPrint('❌ Error getting feature access summary: $e');
      return {
        'error': e.toString(),
        'has_subscription': false,
      };
    }
  }

  /// Clear cache for specific user
  void clearUserCache(String userId) {
    _clearUserCache(userId);
  }

  /// Clear all caches
  void clearAllCaches() {
    _subscriptionCache.clear();
    _cacheTimestamps.clear();
  }

  // Private helper methods

  Future<Subscription?> _getUserSubscriptionCached(String userId) async {
    // Check cache first
    final cacheKey = userId;
    final timestamp = _cacheTimestamps[cacheKey];
    
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < _cacheExpiration &&
        _subscriptionCache.containsKey(cacheKey)) {
      return _subscriptionCache[cacheKey];
    }

    // Fetch from database
    final subscription = await _repository.getActiveSubscriptionForUser(userId);
    
    // Update cache
    _subscriptionCache[cacheKey] = subscription;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    return subscription;
  }

  void _clearUserCache(String userId) {
    _subscriptionCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  Future<bool> _checkUsageLimits({
    required String userId,
    required Subscription subscription,
    required String featureKey,
    Map<String, dynamic>? context,
  }) async {
    final limitKey = _getUsageLimitKey(featureKey);
    final limit = subscription.limits[limitKey];
    
    if (limit == null) {
      // No limit set - unlimited usage
      return true;
    }

    final currentUsage = await _getCurrentUsage(userId, featureKey, context);
    return currentUsage < limit;
  }

  Future<int> _getCurrentUsage(String userId, String featureKey, Map<String, dynamic>? context) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      final usageQuery = await _firestore
          .collection('feature_usage')
          .where('user_id', isEqualTo: userId)
          .where('feature_key', isEqualTo: featureKey)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      int totalUsage = 0;
      for (final doc in usageQuery.docs) {
        totalUsage += (doc.data()['quantity'] as int? ?? 1);
      }

      return totalUsage;
    } catch (e) {
      debugPrint('❌ Error getting current usage: $e');
      return 0;
    }
  }

  String _getUsageLimitKey(String featureKey) {
    // Map feature keys to limit keys
    switch (featureKey) {
      case 'job_applications':
        return 'max_applications_per_month';
      case 'job_posting':
        return 'max_job_posts';
      case 'team_management':
        return 'max_team_size';
      default:
        return 'max_${featureKey}_per_month';
    }
  }

  DateTime _getUsageResetDate() {
    final now = DateTime.now();
    // Reset on first day of next month
    return DateTime(now.year, now.month + 1, 1);
  }

  bool _isBasicFeature(String featureKey) {
    // Features available without subscription
    const basicFeatures = {
      'profile_management',
      'basic_chat',
      'certificate_management',
    };
    
    return basicFeatures.contains(featureKey);
  }

  Map<String, int?> _getBasicFeatureLimits() {
    return {
      'max_applications_per_month': 0,
      'max_job_posts': 0,
      'max_team_size': 0,
      'max_active_jobs': 0,
    };
  }

  Map<String, dynamic> _getBasicFeaturesSummary() {
    return {
      'profile_management': {'has_access': true, 'limit': null},
      'basic_chat': {'has_access': true, 'limit': null},
      'certificate_management': {'has_access': true, 'limit': null},
      'job_applications': {'has_access': false, 'limit': 0},
      'job_posting': {'has_access': false, 'limit': 0},
      'advanced_analytics': {'has_access': false, 'limit': 0},
      'team_management': {'has_access': false, 'limit': 0},
      'priority_support': {'has_access': false, 'limit': 0},
    };
  }

  List<String> _getAllFeatureKeys() {
    return [
      'job_applications',
      'job_posting',
      'basic_chat',
      'certificate_management',
      'earnings_tracking',
      'shift_tracking',
      'profile_management',
      'basic_analytics',
      'advanced_analytics',
      'team_management',
      'bulk_application_processing',
      'priority_support',
      'api_access',
      'white_label',
      'custom_integrations',
      'dedicated_support',
    ];
  }

  bool _hasUpgradeOptions(SubscriptionTier currentTier) {
    switch (currentTier) {
      case SubscriptionTier.zzpGuard:
        return false; // No upgrade path for individual guards
      case SubscriptionTier.companyBasic:
        return true; // Can upgrade to Professional or Enterprise
      case SubscriptionTier.companyProfessional:
        return true; // Can upgrade to Enterprise
      case SubscriptionTier.companyEnterprise:
        return false; // Already highest tier
      case SubscriptionTier.clientUsage:
        return false; // Different model
    }
  }
}

/// Feature usage status information
class FeatureUsageStatus {
  final bool hasAccess;
  final int currentUsage;
  final int? limit;
  final int? remainingUsage;
  final DateTime? resetDate;
  final bool upgradeRequired;

  const FeatureUsageStatus({
    required this.hasAccess,
    required this.currentUsage,
    required this.limit,
    required this.remainingUsage,
    required this.resetDate,
    required this.upgradeRequired,
  });

  bool get isAtLimit => limit != null && currentUsage >= limit!;
  bool get isNearLimit => limit != null && remainingUsage != null && remainingUsage! <= 2;

  @override
  String toString() {
    return 'FeatureUsageStatus(hasAccess: $hasAccess, usage: $currentUsage/$limit, remaining: $remainingUsage)';
  }
}

/// Exception thrown when feature access is denied
class FeatureAccessDeniedException implements Exception {
  final String message;
  final String featureKey;
  final String? upgradeUrl;

  const FeatureAccessDeniedException({
    required this.message,
    required this.featureKey,
    this.upgradeUrl,
  });

  @override
  String toString() => 'FeatureAccessDeniedException: $message (feature: $featureKey)';
}

/// Feature access helper methods for common checks
extension FeatureAccessExtensions on FeatureAccessService {
  /// Check if user can post jobs
  Future<bool> canPostJobs(String userId) async {
    return await hasFeatureAccess(userId: userId, featureKey: 'job_posting');
  }

  /// Check if user can apply to jobs
  Future<bool> canApplyToJobs(String userId) async {
    return await hasFeatureAccess(userId: userId, featureKey: 'job_applications');
  }

  /// Check if user has access to analytics
  Future<bool> hasAnalyticsAccess(String userId, {bool advanced = false}) async {
    final featureKey = advanced ? 'advanced_analytics' : 'basic_analytics';
    return await hasFeatureAccess(userId: userId, featureKey: featureKey);
  }

  /// Check if user has priority support
  Future<bool> hasPrioritySupport(String userId) async {
    return await hasFeatureAccess(userId: userId, featureKey: 'priority_support');
  }

  /// Check team management access with size limit
  Future<bool> canManageTeam(String userId, int currentTeamSize) async {
    final usage = await checkFeatureUsage(
      userId: userId,
      featureKey: 'team_management',
      context: {'current_team_size': currentTeamSize},
    );
    
    return usage.hasAccess && (usage.limit == null || currentTeamSize < usage.limit!);
  }

  /// Get detailed usage analytics for dashboard
  Future<Map<String, dynamic>> getDetailedUsageAnalytics(String userId) async {
    try {
      final subscription = await _repository.getActiveSubscriptionForUser(userId);
      if (subscription == null) {
        return {
          'features': {},
          'usage_summary': {},
          'period': 'current_month',
        };
      }

      // Get feature usage for key features
      final keyFeatures = ['job_applications', 'job_posting', 'team_management'];
      final Map<String, dynamic> features = {};

      for (final featureKey in keyFeatures) {
        final usage = await checkFeatureUsage(
          userId: userId,
          featureKey: featureKey,
          context: {},
        );
        
        features[featureKey] = {
          'has_access': usage.hasAccess,
          'current_usage': usage.currentUsage,
          'limit': usage.limit,
          'remaining': usage.remainingUsage,
        };
      }

      return {
        'features': features,
        'usage_summary': {
          'total_features_used': features.values
              .where((f) => f['current_usage'] > 0)
              .length,
          'features_at_limit': features.values
              .where((f) => f['limit'] != null && f['remaining'] == 0)
              .length,
        },
        'period': 'current_month',
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting detailed usage analytics: $e');
      return {
        'features': {},
        'usage_summary': {},
        'period': 'current_month',
        'error': e.toString(),
      };
    }
  }
}