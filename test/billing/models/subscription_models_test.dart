import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/billing/models/subscription_models.dart';

void main() {
  group('Subscription Models Tests', () {
    group('SubscriptionTier', () {
      test('should have correct pricing for all tiers', () {
        expect(SubscriptionTier.zzpGuard.pricePerMonth, equals(4.99));
        expect(SubscriptionTier.companyBasic.pricePerMonth, equals(19.99));
        expect(SubscriptionTier.companyProfessional.pricePerMonth, equals(39.99));
        expect(SubscriptionTier.companyEnterprise.pricePerMonth, equals(59.99));
        expect(SubscriptionTier.clientUsage.pricePerMonth, equals(2.99));
      });

      test('should calculate BTW correctly', () {
        final zzpGuardPriceWithBTW = SubscriptionTier.zzpGuard.priceWithBTW;
        expect(zzpGuardPriceWithBTW, closeTo(6.04, 0.01)); // 4.99 * 1.21
        
        final companyBasicPriceWithBTW = SubscriptionTier.companyBasic.priceWithBTW;
        expect(companyBasicPriceWithBTW, closeTo(24.19, 0.01)); // 19.99 * 1.21
      });

      test('should return correct tier from ID', () {
        expect(SubscriptionTier.fromId('zzp_guard'), equals(SubscriptionTier.zzpGuard));
        expect(SubscriptionTier.fromId('company_basic'), equals(SubscriptionTier.companyBasic));
        expect(SubscriptionTier.fromId('company_professional'), equals(SubscriptionTier.companyProfessional));
        expect(SubscriptionTier.fromId('company_enterprise'), equals(SubscriptionTier.companyEnterprise));
        expect(SubscriptionTier.fromId('client_usage'), equals(SubscriptionTier.clientUsage));
      });

      test('should return default tier for unknown ID', () {
        expect(SubscriptionTier.fromId('unknown_tier'), equals(SubscriptionTier.zzpGuard));
      });

      test('should have trial period only for ZZP Guard', () {
        expect(SubscriptionTier.zzpGuard.hasTrialPeriod, isTrue);
        expect(SubscriptionTier.companyBasic.hasTrialPeriod, isFalse);
        expect(SubscriptionTier.companyProfessional.hasTrialPeriod, isFalse);
        expect(SubscriptionTier.companyEnterprise.hasTrialPeriod, isFalse);
        expect(SubscriptionTier.clientUsage.hasTrialPeriod, isFalse);
      });

      test('should have correct features for ZZP Guard', () {
        final features = SubscriptionTier.zzpGuard.features;
        expect(features['job_applications'], isTrue);
        expect(features['basic_chat'], isTrue);
        expect(features['certificate_management'], isTrue);
        expect(features['earnings_tracking'], isTrue);
        expect(features['job_posting'], isFalse);
        expect(features['team_management'], isFalse);
        expect(features['advanced_analytics'], isFalse);
      });

      test('should have correct features for Company Basic', () {
        final features = SubscriptionTier.companyBasic.features;
        expect(features['job_posting'], isTrue);
        expect(features['team_management'], isTrue);
        expect(features['basic_analytics'], isTrue);
        expect(features['job_applications'], isFalse);
        expect(features['advanced_analytics'], isFalse);
        expect(features['api_access'], isFalse);
      });

      test('should have correct limits for ZZP Guard', () {
        final limits = SubscriptionTier.zzpGuard.limits;
        expect(limits['max_applications_per_month'], equals(10));
        expect(limits['max_active_applications'], equals(5));
        expect(limits['max_saved_jobs'], equals(50));
      });

      test('should have correct limits for Company Basic', () {
        final limits = SubscriptionTier.companyBasic.limits;
        expect(limits['max_job_posts'], equals(50));
        expect(limits['max_team_size'], equals(5));
        expect(limits['max_active_jobs'], equals(10));
      });

      test('should have unlimited limits for Enterprise', () {
        final limits = SubscriptionTier.companyEnterprise.limits;
        expect(limits['max_job_posts'], isNull);
        expect(limits['max_team_size'], isNull);
        expect(limits['max_active_jobs'], isNull);
      });
    });

    group('SubscriptionStatus', () {
      test('should return correct status from ID', () {
        expect(SubscriptionStatus.fromId('active'), equals(SubscriptionStatus.active));
        expect(SubscriptionStatus.fromId('trialing'), equals(SubscriptionStatus.trialing));
        expect(SubscriptionStatus.fromId('canceled'), equals(SubscriptionStatus.canceled));
        expect(SubscriptionStatus.fromId('past_due'), equals(SubscriptionStatus.pastDue));
        expect(SubscriptionStatus.fromId('expired'), equals(SubscriptionStatus.expired));
      });

      test('should return default status for unknown ID', () {
        expect(SubscriptionStatus.fromId('unknown_status'), equals(SubscriptionStatus.incomplete));
      });

      test('should identify active statuses correctly', () {
        expect(SubscriptionStatus.active.isActive, isTrue);
        expect(SubscriptionStatus.trialing.isActive, isTrue);
        expect(SubscriptionStatus.canceled.isActive, isFalse);
        expect(SubscriptionStatus.expired.isActive, isFalse);
        expect(SubscriptionStatus.pastDue.isActive, isFalse);
      });

      test('should identify payment required statuses correctly', () {
        expect(SubscriptionStatus.pastDue.requiresPayment, isTrue);
        expect(SubscriptionStatus.unpaid.requiresPayment, isTrue);
        expect(SubscriptionStatus.active.requiresPayment, isFalse);
        expect(SubscriptionStatus.trialing.requiresPayment, isFalse);
        expect(SubscriptionStatus.canceled.requiresPayment, isFalse);
      });
    });

    group('Subscription', () {
      late Subscription testSubscription;

      setUp(() {
        testSubscription = Subscription(
          id: 'test-sub-123',
          userId: 'test-user-456',
          tier: SubscriptionTier.zzpGuard,
          status: SubscriptionStatus.active,
          startDate: DateTime(2023, 1, 1),
          monthlyPrice: 4.99,
          currency: 'EUR',
          features: SubscriptionTier.zzpGuard.features,
          limits: SubscriptionTier.zzpGuard.limits,
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 15),
        );
      });

      test('should calculate BTW price correctly', () {
        expect(testSubscription.priceWithBTW, closeTo(6.04, 0.01));
      });

      test('should handle BTW exempt subscriptions', () {
        final exemptSubscription = testSubscription.copyWith(
          isBtwExempt: true,
          monthlyPrice: 10.00,
        );
        expect(exemptSubscription.priceWithBTW, equals(10.00));
      });

      test('should calculate trial days remaining correctly', () {
        final now = DateTime.now();
        final trialSubscription = testSubscription.copyWith(
          trialEndDate: now.add(const Duration(days: 15)),
        );
        expect(trialSubscription.trialDaysRemaining, equals(15));
      });

      test('should return 0 for expired trial', () {
        final now = DateTime.now();
        final expiredTrialSubscription = testSubscription.copyWith(
          trialEndDate: now.subtract(const Duration(days: 5)),
        );
        expect(expiredTrialSubscription.trialDaysRemaining, equals(0));
      });

      test('should return null for no trial', () {
        expect(testSubscription.trialDaysRemaining, isNull);
      });

      test('should identify trial ending soon correctly', () {
        final now = DateTime.now();
        final soonEndingTrial = testSubscription.copyWith(
          trialEndDate: now.add(const Duration(days: 2)),
        );
        expect(soonEndingTrial.isTrialEndingSoon, isTrue);

        final notEndingSoonTrial = testSubscription.copyWith(
          trialEndDate: now.add(const Duration(days: 10)),
        );
        expect(notEndingSoonTrial.isTrialEndingSoon, isFalse);
      });

      test('should identify expired subscriptions correctly', () {
        final now = DateTime.now();
        final expiredSubscription = testSubscription.copyWith(
          endDate: now.subtract(const Duration(days: 5)),
        );
        expect(expiredSubscription.isExpired, isTrue);

        final activeSubscription = testSubscription.copyWith(
          endDate: now.add(const Duration(days: 5)),
        );
        expect(activeSubscription.isExpired, isFalse);
      });

      test('should copy with updated fields correctly', () {
        final updatedSubscription = testSubscription.copyWith(
          tier: SubscriptionTier.companyBasic,
          status: SubscriptionStatus.pastDue,
          monthlyPrice: 19.99,
        );

        expect(updatedSubscription.id, equals(testSubscription.id));
        expect(updatedSubscription.userId, equals(testSubscription.userId));
        expect(updatedSubscription.tier, equals(SubscriptionTier.companyBasic));
        expect(updatedSubscription.status, equals(SubscriptionStatus.pastDue));
        expect(updatedSubscription.monthlyPrice, equals(19.99));
        expect(updatedSubscription.createdAt, equals(testSubscription.createdAt));
        expect(updatedSubscription.updatedAt, isNot(equals(testSubscription.updatedAt)));
      });

      test('should have correct string representation', () {
        final stringRep = testSubscription.toString();
        expect(stringRep, contains('test-sub-123'));
        expect(stringRep, contains('test-user-456'));
        expect(stringRep, contains('ZZP Beveiliger'));
        expect(stringRep, contains('Actief'));
      });
    });

    group('SubscriptionResult', () {
      test('should create successful result correctly', () {
        final subscription = Subscription(
          id: 'test-sub',
          userId: 'test-user',
          tier: SubscriptionTier.zzpGuard,
          status: SubscriptionStatus.active,
          startDate: DateTime.now(),
          monthlyPrice: 4.99,
          currency: 'EUR',
          features: {},
          limits: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = SubscriptionResult.success(subscription);
        expect(result.success, isTrue);
        expect(result.error, isNull);
        expect(result.subscription, equals(subscription));
      });

      test('should create error result correctly', () {
        final result = SubscriptionResult.error('Test error message');
        expect(result.success, isFalse);
        expect(result.error, equals('Test error message'));
        expect(result.subscription, isNull);
      });
    });

    group('SubscriptionChangeRequest', () {
      test('should create change request with correct defaults', () {
        final request = SubscriptionChangeRequest(
          subscriptionId: 'test-sub-123',
          newTier: SubscriptionTier.companyBasic,
          reason: 'User requested upgrade',
        );

        expect(request.subscriptionId, equals('test-sub-123'));
        expect(request.newTier, equals(SubscriptionTier.companyBasic));
        expect(request.reason, equals('User requested upgrade'));
        expect(request.prorated, isTrue); // Default value
        expect(request.effectiveDate, isNull);
      });

      test('should create change request with custom values', () {
        final effectiveDate = DateTime.now().add(const Duration(days: 7));
        final request = SubscriptionChangeRequest(
          subscriptionId: 'test-sub-123',
          newTier: SubscriptionTier.companyProfessional,
          reason: 'Scheduled upgrade',
          effectiveDate: effectiveDate,
          prorated: false,
        );

        expect(request.effectiveDate, equals(effectiveDate));
        expect(request.prorated, isFalse);
      });
    });
  });
}