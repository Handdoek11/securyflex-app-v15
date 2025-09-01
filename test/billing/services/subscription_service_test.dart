import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:securyflex_app/billing/services/subscription_service.dart';
import 'package:securyflex_app/billing/repository/subscription_repository.dart';
import 'package:securyflex_app/billing/models/subscription_models.dart';
import 'package:securyflex_app/payments/services/payment_integration_service.dart';
import 'package:securyflex_app/payments/services/dutch_invoice_service.dart';

// Mock classes
class MockSubscriptionRepository extends Mock implements SubscriptionRepository {}
class MockPaymentIntegrationService extends Mock implements PaymentIntegrationService {}
class MockDutchInvoiceService extends Mock implements DutchInvoiceService {}

void main() {
  group('SubscriptionService Tests', () {
    late SubscriptionService subscriptionService;
    late MockSubscriptionRepository mockRepository;
    late MockPaymentIntegrationService mockPaymentService;
    late MockDutchInvoiceService mockInvoiceService;

    const testUserId = 'test-user-123';
    const testSubscriptionId = 'test-subscription-456';

    final testSubscription = Subscription(
      id: testSubscriptionId,
      userId: testUserId,
      tier: SubscriptionTier.zzpGuard,
      status: SubscriptionStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      monthlyPrice: 4.99,
      currency: 'EUR',
      features: SubscriptionTier.zzpGuard.features,
      limits: SubscriptionTier.zzpGuard.limits,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      mockRepository = MockSubscriptionRepository();
      mockPaymentService = MockPaymentIntegrationService();
      mockInvoiceService = MockDutchInvoiceService();

      subscriptionService = SubscriptionService(
        repository: mockRepository,
        paymentService: mockPaymentService,
        invoiceService: mockInvoiceService,
      );

      // Register fallback values
      registerFallbackValue(testSubscription);
      registerFallbackValue(SubscriptionTier.zzpGuard);
    });

    group('getActiveSubscription', () {
      test('should return subscription when user has active subscription', () async {
        // Arrange
        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => testSubscription);

        // Act
        final result = await subscriptionService.getActiveSubscription(testUserId);

        // Assert
        expect(result, equals(testSubscription));
        verify(() => mockRepository.getActiveSubscriptionForUser(testUserId)).called(1);
      });

      test('should return null when user has no active subscription', () async {
        // Arrange
        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => null);

        // Act
        final result = await subscriptionService.getActiveSubscription(testUserId);

        // Assert
        expect(result, isNull);
        verify(() => mockRepository.getActiveSubscriptionForUser(testUserId)).called(1);
      });

      test('should handle repository errors gracefully', () async {
        // Arrange
        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await subscriptionService.getActiveSubscription(testUserId);

        // Assert
        expect(result, isNull);
        verify(() => mockRepository.getActiveSubscriptionForUser(testUserId)).called(1);
      });
    });

    group('createSubscription', () {
      test('should create subscription successfully with payment method', () async {
        // Arrange
        when(() => mockRepository.createSubscription(any()))
            .thenAnswer((_) async => testSubscription);

        // Act
        final result = await subscriptionService.createSubscription(
          userId: testUserId,
          tier: SubscriptionTier.zzpGuard,
          paymentMethodId: 'pm_test123',
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.subscription, equals(testSubscription));
        verify(() => mockRepository.createSubscription(any())).called(1);
      });

      test('should create subscription successfully without payment method', () async {
        // Arrange
        when(() => mockRepository.createSubscription(any()))
            .thenAnswer((_) async => testSubscription);

        // Act
        final result = await subscriptionService.createSubscription(
          userId: testUserId,
          tier: SubscriptionTier.zzpGuard,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.subscription, equals(testSubscription));
        verify(() => mockRepository.createSubscription(any())).called(1);
      });

      test('should handle creation errors', () async {
        // Arrange
        when(() => mockRepository.createSubscription(any()))
            .thenThrow(Exception('Creation failed'));

        // Act
        final result = await subscriptionService.createSubscription(
          userId: testUserId,
          tier: SubscriptionTier.zzpGuard,
          paymentMethodId: 'pm_test123',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Creation failed'));
        verify(() => mockRepository.createSubscription(any())).called(1);
      });
    });

    group('upgradeSubscription', () {
      test('should upgrade subscription successfully', () async {
        // Arrange
        when(() => mockRepository.getSubscription(testSubscriptionId))
            .thenAnswer((_) async => testSubscription);
        when(() => mockRepository.updateSubscription(any(), any()))
            .thenAnswer((_) async {});

        // Act
        final result = await subscriptionService.upgradeSubscription(
          subscriptionId: testSubscriptionId,
          newTier: SubscriptionTier.companyBasic,
        );

        // Assert
        expect(result.success, isTrue);
        verify(() => mockRepository.getSubscription(testSubscriptionId)).called(1);
        verify(() => mockRepository.updateSubscription(any(), any())).called(1);
      });

      test('should fail when subscription not found', () async {
        // Arrange
        when(() => mockRepository.getSubscription('non-existent-subscription'))
            .thenAnswer((_) async => null);

        // Act
        final result = await subscriptionService.upgradeSubscription(
          subscriptionId: 'non-existent-subscription',
          newTier: SubscriptionTier.companyBasic,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Abonnement niet gevonden'));
        verify(() => mockRepository.getSubscription('non-existent-subscription')).called(1);
      });
    });

    group('startTrial', () {
      test('should start trial successfully for eligible tier', () async {
        // Arrange
        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => null);
        when(() => mockRepository.createSubscription(any()))
            .thenAnswer((_) async => testSubscription.copyWith(
              status: SubscriptionStatus.trialing,
              trialEndDate: DateTime.now().add(const Duration(days: 30)),
            ));

        // Act
        final result = await subscriptionService.startTrial(
          userId: testUserId,
          tier: SubscriptionTier.zzpGuard,
        );

        // Assert
        expect(result.success, isTrue);
        verify(() => mockRepository.getActiveSubscriptionForUser(testUserId)).called(1);
        verify(() => mockRepository.createSubscription(any())).called(1);
      });

      test('should fail for tier without trial period', () async {
        // Act
        final result = await subscriptionService.startTrial(
          userId: testUserId,
          tier: SubscriptionTier.companyBasic,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Geen proefperiode beschikbaar'));
      });

      test('should fail when user already has active subscription', () async {
        // Arrange
        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => testSubscription);

        // Act
        final result = await subscriptionService.startTrial(
          userId: testUserId,
          tier: SubscriptionTier.zzpGuard,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Gebruiker heeft al een actief abonnement'));
        verify(() => mockRepository.getActiveSubscriptionForUser(testUserId)).called(1);
      });
    });

    group('cancelSubscription', () {
      test('should cancel subscription successfully', () async {
        // Arrange
        when(() => mockRepository.getSubscription(testSubscriptionId))
            .thenAnswer((_) async => testSubscription);
        when(() => mockRepository.updateSubscription(any(), any()))
            .thenAnswer((_) async {});

        // Act
        final result = await subscriptionService.cancelSubscription(
          subscriptionId: testSubscriptionId,
          reason: 'User requested',
        );

        // Assert
        expect(result.success, isTrue);
        verify(() => mockRepository.getSubscription(testSubscriptionId)).called(1);
        verify(() => mockRepository.updateSubscription(any(), any())).called(1);
      });

      test('should fail when subscription not found', () async {
        // Arrange
        when(() => mockRepository.getSubscription(testSubscriptionId))
            .thenAnswer((_) async => null);

        // Act
        final result = await subscriptionService.cancelSubscription(
          subscriptionId: testSubscriptionId,
          reason: 'User requested',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Abonnement niet gevonden'));
        verify(() => mockRepository.getSubscription(testSubscriptionId)).called(1);
      });
    });

    group('getBillingHistory', () {
      test('should return billing history successfully', () async {
        // Act
        final result = await subscriptionService.getBillingHistory(testUserId);

        // Assert
        expect(result, isNotEmpty);
        expect(result.first['id'], equals('invoice_001'));
        expect(result.first['amount'], equals(4.99));
        expect(result.first['status'], equals('paid'));
      });

      test('should handle errors gracefully', () async {
        // This test verifies the service handles errors in getBillingHistory
        // Since it's currently returning mock data, we test the mock behavior
        final result = await subscriptionService.getBillingHistory('invalid-user');
        
        // Should still return mock data for now
        expect(result, isNotEmpty);
      });
    });

    group('updatePaymentMethod', () {
      test('should update payment method successfully', () async {
        // Arrange
        when(() => mockRepository.getSubscription(testSubscriptionId))
            .thenAnswer((_) async => testSubscription);
        when(() => mockRepository.updateSubscription(any(), any()))
            .thenAnswer((_) async {});

        // Act
        final result = await subscriptionService.updatePaymentMethod(
          subscriptionId: testSubscriptionId,
          paymentMethodId: 'pm_new123',
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockRepository.getSubscription(testSubscriptionId)).called(1);
        verify(() => mockRepository.updateSubscription(any(), any())).called(1);
      });

      test('should fail when subscription not found', () async {
        // Arrange
        when(() => mockRepository.getSubscription(testSubscriptionId))
            .thenAnswer((_) async => null);

        // Act
        final result = await subscriptionService.updatePaymentMethod(
          subscriptionId: testSubscriptionId,
          paymentMethodId: 'pm_new123',
        );

        // Assert
        expect(result, isFalse);
        verify(() => mockRepository.getSubscription(testSubscriptionId)).called(1);
      });
    });

    group('resumeSubscription', () {
      test('should resume canceled subscription successfully', () async {
        // Arrange
        final canceledSubscription = testSubscription.copyWith(
          status: SubscriptionStatus.canceled,
          endDate: DateTime.now().add(const Duration(days: 5)),
        );

        when(() => mockRepository.getSubscription(testSubscriptionId))
            .thenAnswer((_) async => canceledSubscription);
        when(() => mockRepository.updateSubscription(any(), any()))
            .thenAnswer((_) async {});

        // Act
        final result = await subscriptionService.resumeSubscription(
          subscriptionId: testSubscriptionId,
        );

        // Assert
        expect(result.success, isTrue);
        verify(() => mockRepository.getSubscription(testSubscriptionId)).called(1);
        verify(() => mockRepository.updateSubscription(any(), any())).called(1);
      });

      test('should fail when subscription not found', () async {
        // Arrange
        when(() => mockRepository.getSubscription(testSubscriptionId))
            .thenAnswer((_) async => null);

        // Act
        final result = await subscriptionService.resumeSubscription(
          subscriptionId: testSubscriptionId,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Abonnement niet gevonden'));
      });

      test('should fail when subscription is not canceled', () async {
        // Arrange
        when(() => mockRepository.getSubscription(testSubscriptionId))
            .thenAnswer((_) async => testSubscription); // Active subscription

        // Act
        final result = await subscriptionService.resumeSubscription(
          subscriptionId: testSubscriptionId,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Alleen geannuleerde abonnementen kunnen worden hervat'));
      });
    });
  });
}