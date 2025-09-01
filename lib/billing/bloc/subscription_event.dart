import 'package:equatable/equatable.dart';
import '../models/subscription_models.dart';

/// Base subscription event class
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Load subscription data for user
class SubscriptionLoad extends SubscriptionEvent {
  final String userId;

  const SubscriptionLoad({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Refresh subscription data
class SubscriptionRefresh extends SubscriptionEvent {
  final String userId;

  const SubscriptionRefresh({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Upgrade subscription to new tier
class SubscriptionUpgrade extends SubscriptionEvent {
  final String userId;
  final SubscriptionTier newTier;
  final String? paymentMethodId;

  const SubscriptionUpgrade({
    required this.userId,
    required this.newTier,
    this.paymentMethodId,
  });

  @override
  List<Object?> get props => [userId, newTier, paymentMethodId];
}

/// Cancel subscription
class SubscriptionCancel extends SubscriptionEvent {
  final String subscriptionId;
  final String reason;

  const SubscriptionCancel({
    required this.subscriptionId,
    required this.reason,
  });

  @override
  List<Object?> get props => [subscriptionId, reason];
}

/// Resume canceled subscription
class SubscriptionResume extends SubscriptionEvent {
  final String subscriptionId;

  const SubscriptionResume({required this.subscriptionId});

  @override
  List<Object?> get props => [subscriptionId];
}

/// Update payment method
class SubscriptionPaymentMethodUpdate extends SubscriptionEvent {
  final String subscriptionId;
  final String paymentMethodId;

  const SubscriptionPaymentMethodUpdate({
    required this.subscriptionId,
    required this.paymentMethodId,
  });

  @override
  List<Object?> get props => [subscriptionId, paymentMethodId];
}

/// Load billing history
class SubscriptionBillingHistoryLoad extends SubscriptionEvent {
  final String userId;

  const SubscriptionBillingHistoryLoad({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Load usage analytics
class SubscriptionUsageAnalyticsLoad extends SubscriptionEvent {
  final String userId;

  const SubscriptionUsageAnalyticsLoad({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Load feature access summary
class SubscriptionFeatureAccessLoad extends SubscriptionEvent {
  final String userId;

  const SubscriptionFeatureAccessLoad({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Trial started event
class SubscriptionTrialStarted extends SubscriptionEvent {
  final String userId;
  final SubscriptionTier tier;

  const SubscriptionTrialStarted({
    required this.userId,
    required this.tier,
  });

  @override
  List<Object?> get props => [userId, tier];
}

/// Payment failed event
class SubscriptionPaymentFailed extends SubscriptionEvent {
  final String subscriptionId;
  final String error;

  const SubscriptionPaymentFailed({
    required this.subscriptionId,
    required this.error,
  });

  @override
  List<Object?> get props => [subscriptionId, error];
}