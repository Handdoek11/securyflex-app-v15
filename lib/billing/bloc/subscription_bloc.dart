import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../services/subscription_service.dart';
import '../services/feature_access_service.dart';
import '../repository/subscription_repository.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

/// BLoC for managing subscription state and operations
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionService _subscriptionService;
  final FeatureAccessService _featureAccessService;
  final SubscriptionRepository _repository;

  StreamSubscription? _subscriptionStreamSubscription;

  SubscriptionBloc({
    SubscriptionService? subscriptionService,
    FeatureAccessService? featureAccessService,
    SubscriptionRepository? repository,
  })  : _subscriptionService = subscriptionService ?? SubscriptionService.instance,
        _featureAccessService = featureAccessService ?? FeatureAccessService.instance,
        _repository = repository ?? SubscriptionRepository(),
        super(SubscriptionInitial()) {
    
    // Register event handlers
    on<SubscriptionLoad>(_onSubscriptionLoad);
    on<SubscriptionRefresh>(_onSubscriptionRefresh);
    on<SubscriptionUpgrade>(_onSubscriptionUpgrade);
    on<SubscriptionCancel>(_onSubscriptionCancel);
    on<SubscriptionResume>(_onSubscriptionResume);
    on<SubscriptionPaymentMethodUpdate>(_onPaymentMethodUpdate);
    on<SubscriptionBillingHistoryLoad>(_onBillingHistoryLoad);
    on<SubscriptionUsageAnalyticsLoad>(_onUsageAnalyticsLoad);
    on<SubscriptionFeatureAccessLoad>(_onFeatureAccessLoad);
    on<SubscriptionTrialStarted>(_onTrialStarted);
    on<SubscriptionPaymentFailed>(_onPaymentFailed);
  }

  /// Load subscription data for user
  Future<void> _onSubscriptionLoad(
    SubscriptionLoad event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());

    try {
      // Load subscription data
      final subscription = await _repository.getActiveSubscriptionForUser(event.userId);
      
      // Load feature access summary
      final featureAccess = await _featureAccessService.getFeatureAccessSummary(event.userId);

      emit(SubscriptionLoaded(
        subscription: subscription,
        featureAccess: featureAccess,
      ));

      // Set up real-time subscription updates
      await _subscriptionStreamSubscription?.cancel();
      _subscriptionStreamSubscription = _repository.subscriptionStream(event.userId).listen(
        (updatedSubscription) {
          if (!isClosed) {
            add(SubscriptionRefresh(userId: event.userId));
          }
        },
        onError: (error) {
          if (!isClosed) {
            emit(SubscriptionError(message: 'Subscription stream error: $error'));
          }
        },
      );
    } catch (e) {
      debugPrint('❌ Error loading subscription: $e');
      emit(SubscriptionError(
        message: 'Abonnement kan niet worden geladen',
        code: 'LOAD_ERROR',
      ));
    }
  }

  /// Refresh subscription data
  Future<void> _onSubscriptionRefresh(
    SubscriptionRefresh event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final subscription = await _repository.getActiveSubscriptionForUser(event.userId);
      final featureAccess = await _featureAccessService.getFeatureAccessSummary(event.userId);

      if (state is SubscriptionLoaded) {
        final currentState = state as SubscriptionLoaded;
        emit(currentState.copyWith(
          subscription: subscription,
          featureAccess: featureAccess,
        ));
      } else {
        emit(SubscriptionLoaded(
          subscription: subscription,
          featureAccess: featureAccess,
        ));
      }
    } catch (e) {
      debugPrint('❌ Error refreshing subscription: $e');
      emit(SubscriptionError(
        message: 'Abonnement kan niet worden vernieuwd',
        code: 'REFRESH_ERROR',
      ));
    }
  }

  /// Upgrade subscription to new tier
  Future<void> _onSubscriptionUpgrade(
    SubscriptionUpgrade event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(const SubscriptionOperationInProgress(
      operation: 'upgrade',
      message: 'Abonnement upgraden...',
    ));

    try {
      // First, get the user's active subscription
      final currentSubscription = await _repository.getActiveSubscriptionForUser(event.userId);
      if (currentSubscription == null) {
        emit(SubscriptionError(
          message: 'Geen actief abonnement gevonden',
          code: 'NO_SUBSCRIPTION',
        ));
        return;
      }

      final result = await _subscriptionService.upgradeSubscription(
        subscriptionId: currentSubscription.id,
        newTier: event.newTier,
        paymentMethodId: event.paymentMethodId,
      );

      if (result.success && result.subscription != null) {
        emit(SubscriptionOperationSuccess(
          operation: 'upgrade',
          message: 'Abonnement succesvol geüpgraded naar ${event.newTier.displayName}',
          subscription: result.subscription,
        ));
        
        // Refresh data
        add(SubscriptionRefresh(userId: event.userId));
      } else {
        emit(SubscriptionError(
          message: result.error ?? 'Upgrade mislukt',
          code: 'UPGRADE_ERROR',
        ));
      }
    } catch (e) {
      debugPrint('❌ Error upgrading subscription: $e');
      emit(SubscriptionError(
        message: 'Upgrade mislukt: ${e.toString()}',
        code: 'UPGRADE_ERROR',
      ));
    }
  }

  /// Cancel subscription
  Future<void> _onSubscriptionCancel(
    SubscriptionCancel event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(const SubscriptionOperationInProgress(
      operation: 'cancel',
      message: 'Abonnement opzeggen...',
    ));

    try {
      final result = await _subscriptionService.cancelSubscription(
        subscriptionId: event.subscriptionId,
        reason: event.reason,
      );

      if (result.success) {
        emit(const SubscriptionOperationSuccess(
          operation: 'cancel',
          message: 'Abonnement succesvol opgezegd',
        ));
        
        // Get user ID from current subscription for refresh
        if (state is SubscriptionLoaded) {
          final currentState = state as SubscriptionLoaded;
          if (currentState.subscription != null) {
            add(SubscriptionRefresh(userId: currentState.subscription!.userId));
          }
        }
      } else {
        emit(SubscriptionError(
          message: result.error ?? 'Opzegging mislukt',
          code: 'CANCEL_ERROR',
        ));
      }
    } catch (e) {
      debugPrint('❌ Error canceling subscription: $e');
      emit(SubscriptionError(
        message: 'Opzegging mislukt: ${e.toString()}',
        code: 'CANCEL_ERROR',
      ));
    }
  }

  /// Resume canceled subscription
  Future<void> _onSubscriptionResume(
    SubscriptionResume event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(const SubscriptionOperationInProgress(
      operation: 'resume',
      message: 'Abonnement hervatten...',
    ));

    try {
      // For now, emit success - this would need actual payment service integration
      emit(const SubscriptionOperationSuccess(
        operation: 'resume',
        message: 'Abonnement succesvol hervat',
      ));
      
      // Get user ID from current subscription for refresh
      if (state is SubscriptionLoaded) {
        final currentState = state as SubscriptionLoaded;
        if (currentState.subscription != null) {
          add(SubscriptionRefresh(userId: currentState.subscription!.userId));
        }
      }
    } catch (e) {
      debugPrint('❌ Error resuming subscription: $e');
      emit(SubscriptionError(
        message: 'Hervatten mislukt: ${e.toString()}',
        code: 'RESUME_ERROR',
      ));
    }
  }

  /// Update payment method
  Future<void> _onPaymentMethodUpdate(
    SubscriptionPaymentMethodUpdate event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(const SubscriptionOperationInProgress(
      operation: 'payment_method_update',
      message: 'Betaalmethode bijwerken...',
    ));

    try {
      // For now, emit success - this would need actual payment service integration
      emit(SubscriptionPaymentMethodUpdated(
        paymentMethodId: event.paymentMethodId,
      ));
      
      // Get user ID from current subscription for refresh
      if (state is SubscriptionLoaded) {
        final currentState = state as SubscriptionLoaded;
        if (currentState.subscription != null) {
          add(SubscriptionRefresh(userId: currentState.subscription!.userId));
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating payment method: $e');
      emit(SubscriptionError(
        message: 'Betaalmethode bijwerken mislukt: ${e.toString()}',
        code: 'PAYMENT_METHOD_ERROR',
      ));
    }
  }

  /// Load billing history
  Future<void> _onBillingHistoryLoad(
    SubscriptionBillingHistoryLoad event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final billingHistory = await _subscriptionService.getBillingHistory(event.userId);
      
      if (state is SubscriptionLoaded) {
        final currentState = state as SubscriptionLoaded;
        emit(currentState.copyWith(billingHistory: billingHistory));
      } else {
        emit(SubscriptionBillingHistoryLoaded(billingHistory: billingHistory));
      }
    } catch (e) {
      debugPrint('❌ Error loading billing history: $e');
      emit(SubscriptionError(
        message: 'Factuurgeschiedenis kan niet worden geladen',
        code: 'BILLING_HISTORY_ERROR',
      ));
    }
  }

  /// Load usage analytics
  Future<void> _onUsageAnalyticsLoad(
    SubscriptionUsageAnalyticsLoad event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final analytics = await _featureAccessService.getDetailedUsageAnalytics(event.userId);
      
      if (state is SubscriptionLoaded) {
        final currentState = state as SubscriptionLoaded;
        emit(currentState.copyWith(usageAnalytics: analytics));
      } else {
        emit(SubscriptionUsageAnalyticsLoaded(analytics: analytics));
      }
    } catch (e) {
      debugPrint('❌ Error loading usage analytics: $e');
      emit(SubscriptionError(
        message: 'Gebruiksanalytics kunnen niet worden geladen',
        code: 'USAGE_ANALYTICS_ERROR',
      ));
    }
  }

  /// Load feature access data
  Future<void> _onFeatureAccessLoad(
    SubscriptionFeatureAccessLoad event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final featureAccess = await _featureAccessService.getFeatureAccessSummary(event.userId);
      
      if (state is SubscriptionLoaded) {
        final currentState = state as SubscriptionLoaded;
        emit(currentState.copyWith(featureAccess: featureAccess));
      } else {
        emit(SubscriptionFeatureAccessLoaded(featureAccess: featureAccess));
      }
    } catch (e) {
      debugPrint('❌ Error loading feature access: $e');
      emit(SubscriptionError(
        message: 'Functietoegang kan niet worden geladen',
        code: 'FEATURE_ACCESS_ERROR',
      ));
    }
  }

  /// Handle trial started
  Future<void> _onTrialStarted(
    SubscriptionTrialStarted event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final result = await _subscriptionService.createSubscription(
        userId: event.userId,
        tier: event.tier,
      );

      if (result.success && result.subscription != null) {
        final trialDays = result.subscription!.trialDaysRemaining ?? 30;
        emit(SubscriptionTrialStartedState(
          subscription: result.subscription!,
          trialDays: trialDays,
        ));
        
        // Refresh data
        add(SubscriptionRefresh(userId: event.userId));
      } else {
        emit(SubscriptionError(
          message: result.error ?? 'Proefperiode kan niet worden gestart',
          code: 'TRIAL_START_ERROR',
        ));
      }
    } catch (e) {
      debugPrint('❌ Error starting trial: $e');
      emit(SubscriptionError(
        message: 'Proefperiode starten mislukt: ${e.toString()}',
        code: 'TRIAL_START_ERROR',
      ));
    }
  }

  /// Handle payment failed
  Future<void> _onPaymentFailed(
    SubscriptionPaymentFailed event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionError(
      message: 'Betaling mislukt: ${event.error}',
      code: 'PAYMENT_FAILED',
    ));
    
    // Get user ID from current subscription for refresh to update status
    if (state is SubscriptionLoaded) {
      final currentState = state as SubscriptionLoaded;
      if (currentState.subscription != null) {
        add(SubscriptionRefresh(userId: currentState.subscription!.userId));
      }
    }
  }

  @override
  Future<void> close() async {
    await _subscriptionStreamSubscription?.cancel();
    return super.close();
  }
}