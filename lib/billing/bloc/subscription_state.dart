import 'package:equatable/equatable.dart';
import '../models/subscription_models.dart';

/// Base subscription state class
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SubscriptionInitial extends SubscriptionState {}

/// Loading state
class SubscriptionLoading extends SubscriptionState {}

/// Subscription data loaded successfully
class SubscriptionLoaded extends SubscriptionState {
  final Subscription? subscription;
  final Map<String, dynamic>? featureAccess;
  final List<Map<String, dynamic>>? billingHistory;
  final Map<String, dynamic>? usageAnalytics;

  const SubscriptionLoaded({
    this.subscription,
    this.featureAccess,
    this.billingHistory,
    this.usageAnalytics,
  });

  @override
  List<Object?> get props => [subscription, featureAccess, billingHistory, usageAnalytics];

  /// Copy with updated data
  SubscriptionLoaded copyWith({
    Subscription? subscription,
    Map<String, dynamic>? featureAccess,
    List<Map<String, dynamic>>? billingHistory,
    Map<String, dynamic>? usageAnalytics,
  }) {
    return SubscriptionLoaded(
      subscription: subscription ?? this.subscription,
      featureAccess: featureAccess ?? this.featureAccess,
      billingHistory: billingHistory ?? this.billingHistory,
      usageAnalytics: usageAnalytics ?? this.usageAnalytics,
    );
  }

  /// Check if user has active subscription
  bool get hasActiveSubscription => 
      subscription != null && subscription!.status.isActive;

  /// Check if subscription is in trial
  bool get isInTrial => 
      subscription != null && subscription!.status == SubscriptionStatus.trialing;

  /// Check if payment is required
  bool get requiresPayment => 
      subscription != null && subscription!.status.requiresPayment;

  /// Get current tier
  SubscriptionTier? get currentTier => subscription?.tier;

  /// Get days remaining in trial
  int? get trialDaysRemaining => subscription?.trialDaysRemaining;

  /// Check if trial is ending soon
  bool get isTrialEndingSoon => subscription?.isTrialEndingSoon ?? false;
}

/// Error state
class SubscriptionError extends SubscriptionState {
  final String message;
  final String? code;

  const SubscriptionError({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Subscription operation in progress
class SubscriptionOperationInProgress extends SubscriptionState {
  final String operation;
  final String? message;

  const SubscriptionOperationInProgress({
    required this.operation,
    this.message,
  });

  @override
  List<Object?> get props => [operation, message];
}

/// Subscription operation successful
class SubscriptionOperationSuccess extends SubscriptionState {
  final String operation;
  final String message;
  final Subscription? subscription;

  const SubscriptionOperationSuccess({
    required this.operation,
    required this.message,
    this.subscription,
  });

  @override
  List<Object?> get props => [operation, message, subscription];
}

/// Billing history loaded
class SubscriptionBillingHistoryLoaded extends SubscriptionState {
  final List<Map<String, dynamic>> billingHistory;

  const SubscriptionBillingHistoryLoaded({
    required this.billingHistory,
  });

  @override
  List<Object?> get props => [billingHistory];
}

/// Usage analytics loaded
class SubscriptionUsageAnalyticsLoaded extends SubscriptionState {
  final Map<String, dynamic> analytics;

  const SubscriptionUsageAnalyticsLoaded({
    required this.analytics,
  });

  @override
  List<Object?> get props => [analytics];
}

/// Feature access data loaded
class SubscriptionFeatureAccessLoaded extends SubscriptionState {
  final Map<String, dynamic> featureAccess;

  const SubscriptionFeatureAccessLoaded({
    required this.featureAccess,
  });

  @override
  List<Object?> get props => [featureAccess];
}

/// Trial started successfully state
class SubscriptionTrialStartedState extends SubscriptionState {
  final Subscription subscription;
  final int trialDays;

  const SubscriptionTrialStartedState({
    required this.subscription,
    required this.trialDays,
  });

  @override
  List<Object?> get props => [subscription, trialDays];
}

/// Payment method updated
class SubscriptionPaymentMethodUpdated extends SubscriptionState {
  final String paymentMethodId;

  const SubscriptionPaymentMethodUpdated({
    required this.paymentMethodId,
  });

  @override
  List<Object?> get props => [paymentMethodId];
}