import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:securyflex_app/billing/services/feature_access_service.dart';
import 'package:securyflex_app/billing/repository/subscription_repository.dart';
import 'package:securyflex_app/billing/models/subscription_models.dart';
import 'package:securyflex_app/billing/services/subscription_service.dart';

// Mock classes
class MockSubscriptionRepository extends Mock implements SubscriptionRepository {}
class MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  group('FeatureAccessService Tests', () {
    late FeatureAccessService featureAccessService;
    late MockSubscriptionRepository mockRepository;
    late MockSubscriptionService mockSubscriptionService;

    const testUserId = 'test-user-123';

    setUp(() {
      mockRepository = MockSubscriptionRepository();
      mockSubscriptionService = MockSubscriptionService();
      featureAccessService = FeatureAccessService(
        repository: mockRepository,
        subscriptionService: mockSubscriptionService,
      );
    });

    group('hasFeatureAccess', () {
      test('should allow basic features without subscription', () async {
        // Arrange
        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(await featureAccessService.hasFeatureAccess(
          userId: testUserId,
          featureKey: 'profile_management',
        ), isTrue);

        expect(await featureAccessService.hasFeatureAccess(
          userId: testUserId,
          featureKey: 'basic_chat',
        ), isTrue);

        expect(await featureAccessService.hasFeatureAccess(
          userId: testUserId,
          featureKey: 'certificate_management',
        ), isTrue);
      });

      test('should deny premium features without subscription', () async {
        // Arrange
        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(await featureAccessService.hasFeatureAccess(
          userId: testUserId,
          featureKey: 'job_applications',
        ), isFalse);

        expect(await featureAccessService.hasFeatureAccess(
          userId: testUserId,
          featureKey: 'advanced_analytics',
        ), isFalse);

        expect(await featureAccessService.hasFeatureAccess(
          userId: testUserId,
          featureKey: 'team_management',
        ), isFalse);
      });

      test('should allow features for active subscription', () async {
        // Arrange
        final activeSubscription = Subscription(
          id: 'test-subscription',
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

        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => activeSubscription);

        // Act & Assert
        expect(await featureAccessService.hasFeatureAccess(
          userId: testUserId,
          featureKey: 'job_applications',
        ), isTrue);

        expect(await featureAccessService.hasFeatureAccess(
          userId: testUserId,
          featureKey: 'earnings_tracking',
        ), isTrue);
      });

      test('should deny features not available in tier', () async {
        // Arrange
        final zzpSubscription = Subscription(
          id: 'test-subscription',
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

        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => zzpSubscription);

        // Act & Assert - ZZP Guard shouldn't have job posting
        expect(await featureAccessService.hasFeatureAccess(
          userId: testUserId,
          featureKey: 'job_posting',
        ), isFalse);

        expect(await featureAccessService.hasFeatureAccess(
          userId: testUserId,
          featureKey: 'team_management',
        ), isFalse);
      });

      test('should deny features for inactive subscription', () async {
        // Arrange
        final inactiveSubscription = Subscription(
          id: 'test-subscription',
          userId: testUserId,
          tier: SubscriptionTier.zzpGuard,
          status: SubscriptionStatus.canceled,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          monthlyPrice: 4.99,
          currency: 'EUR',
          features: SubscriptionTier.zzpGuard.features,
          limits: SubscriptionTier.zzpGuard.limits,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        );

        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => inactiveSubscription);

        // Act & Assert
        expect(await featureAccessService.hasFeatureAccess(
          userId: testUserId,
          featureKey: 'job_applications',
        ), isFalse);

        // But basic features should still work
        expect(await featureAccessService.hasFeatureAccess(
          userId: testUserId,
          featureKey: 'profile_management',
        ), isTrue);
      });

      test('should handle repository errors gracefully', () async {
        // Arrange
        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(await featureAccessService.hasFeatureAccess(
          userId: testUserId,
          featureKey: 'job_applications',
        ), isFalse);
      });
    });

    group('getFeatureLimits', () {
      test('should return basic limits without subscription', () async {
        // Arrange
        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => null);

        // Act
        final limits = await featureAccessService.getFeatureLimits(testUserId);

        // Assert
        expect(limits['max_applications_per_month'], equals(0));
        expect(limits['max_job_posts'], equals(0));
        expect(limits['max_team_size'], equals(0));
      });

      test('should return subscription limits for active subscription', () async {
        // Arrange
        final activeSubscription = Subscription(
          id: 'test-subscription',
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

        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => activeSubscription);

        // Act
        final limits = await featureAccessService.getFeatureLimits(testUserId);

        // Assert
        expect(limits['max_applications_per_month'], equals(10));
        expect(limits['max_active_applications'], equals(5));
        expect(limits['max_saved_jobs'], equals(50));
      });

      test('should handle repository errors gracefully', () async {
        // Arrange
        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenThrow(Exception('Database error'));

        // Act
        final limits = await featureAccessService.getFeatureLimits(testUserId);

        // Assert
        expect(limits['max_applications_per_month'], equals(0));
        expect(limits['max_job_posts'], equals(0));
      });
    });

    group('Extension Methods', () {
      test('should correctly check job posting access', () async {
        // Arrange - Company subscription
        final companySubscription = Subscription(
          id: 'test-subscription',
          userId: testUserId,
          tier: SubscriptionTier.companyBasic,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          monthlyPrice: 19.99,
          currency: 'EUR',
          features: SubscriptionTier.companyBasic.features,
          limits: SubscriptionTier.companyBasic.limits,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        );

        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => companySubscription);

        // Act & Assert
        expect(await featureAccessService.canPostJobs(testUserId), isTrue);
      });

      test('should correctly check job application access', () async {
        // Arrange - ZZP Guard subscription
        final zzpSubscription = Subscription(
          id: 'test-subscription',
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

        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => zzpSubscription);

        // Act & Assert
        expect(await featureAccessService.canApplyToJobs(testUserId), isTrue);
      });

      test('should correctly check analytics access', () async {
        // Arrange - Professional subscription
        final professionalSubscription = Subscription(
          id: 'test-subscription',
          userId: testUserId,
          tier: SubscriptionTier.companyProfessional,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          monthlyPrice: 39.99,
          currency: 'EUR',
          features: SubscriptionTier.companyProfessional.features,
          limits: SubscriptionTier.companyProfessional.limits,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        );

        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => professionalSubscription);

        // Act & Assert
        expect(await featureAccessService.hasAnalyticsAccess(testUserId), isTrue);
        expect(await featureAccessService.hasAnalyticsAccess(testUserId, advanced: true), isTrue);
      });

      test('should correctly check priority support access', () async {
        // Arrange - Enterprise subscription
        final enterpriseSubscription = Subscription(
          id: 'test-subscription',
          userId: testUserId,
          tier: SubscriptionTier.companyEnterprise,
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          monthlyPrice: 59.99,
          currency: 'EUR',
          features: SubscriptionTier.companyEnterprise.features,
          limits: SubscriptionTier.companyEnterprise.limits,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        );

        when(() => mockRepository.getActiveSubscriptionForUser(testUserId))
            .thenAnswer((_) async => enterpriseSubscription);

        // Act & Assert
        expect(await featureAccessService.hasPrioritySupport(testUserId), isTrue);
      });
    });
  });
}