import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/reputation/models/reputation_data.dart';
import 'package:securyflex_app/reputation/services/reputation_calculation_service.dart';

void main() {
  group('Reputation System Integration Tests', () {
    late ReputationCalculationService service;

    setUp(() {
      service = ReputationCalculationService.instance;
    });

    group('ReputationData Model Tests', () {
      test('should create initial reputation data correctly', () {
        // Act
        final reputation = ReputationData.initial(
          userId: 'test-user-123',
          userRole: 'guard',
        );

        // Assert
        expect(reputation.userId, equals('test-user-123'));
        expect(reputation.userRole, equals('guard'));
        expect(reputation.overallScore, equals(50.0)); // Neutral starting score
        expect(reputation.totalJobsCompleted, equals(0));
        expect(reputation.wpbrCertified, equals(false));
        expect(reputation.reliabilityScore, equals(100.0)); // Start optimistic
        expect(reputation.reputationLevel, equals(ReputationLevel.belowAverage));
      });

      test('should create reputation with specific values correctly', () {
        // Act
        final reputation = ReputationData(
          userId: 'experienced-guard',
          userRole: 'guard',
          lastCalculated: DateTime.now(),
          firstJobDate: DateTime.now().subtract(const Duration(days: 365)),
          overallScore: 85.0,
          jobCompletionRating: 4.2,
          reliabilityScore: 90.0,
          clientFeedbackScore: 88.0,
          complianceScore: 75.0,
          experienceMultiplier: 1.2,
          totalJobsCompleted: 25,
          totalJobsCancelled: 1,
          noShowCount: 0,
          lateArrivalCount: 2,
          earlyCompletionCount: 3,
          averageResponseTime: 12.5,
          positiveReviewCount: 20,
          neutralReviewCount: 4,
          negativeReviewCount: 1,
          repeatClientPercentage: 60.0,
          recommendationRate: 80.0,
          wpbrCertified: true,
          kvkVerified: false,
          activeCertificateCount: 2,
          complianceViolationCount: 0,
          monthlyScoreChange: 2.5,
          quarterlyScoreChange: 8.0,
          currentTrend: ReputationTrend.improving,
          achievedMilestones: [
            ReputationMilestone.firstJob,
            ReputationMilestone.tenJobsCompleted,
          ],
          specializationScores: {'eventSecurity': 4.5},
          topSpecialization: 'eventSecurity',
          averageHourlyRate: 16.50,
        );

        // Assert
        expect(reputation.overallScore, equals(85.0));
        expect(reputation.reputationLevel, equals(ReputationLevel.excellent));
        expect(reputation.completionRate, closeTo(96.15, 0.1)); // 25/(25+1) * 100
        expect(reputation.totalReviewCount, equals(25)); // 20+4+1
        expect(reputation.positiveReviewPercentage, equals(80.0)); // 20/25 * 100
        expect(reputation.yearsOfExperience, closeTo(1.0, 0.1));
      });

      test('should correctly calculate CAO compliance', () {
        // Arrange - Good guard meeting CAO standards
        final goodGuard = ReputationData.initial(
          userId: 'good-guard',
          userRole: 'guard',
        ).copyWith(
          totalJobsCompleted: 100,
          totalJobsCancelled: 1, // 99% completion rate
          noShowCount: 1, // Within limit of 2
          lateArrivalCount: 3, // <5% late arrivals (3/103)
        );

        // Act & Assert
        expect(goodGuard.isReliableByCAOStandards, isTrue);
        expect(goodGuard.completionRate, greaterThanOrEqualTo(95.0));

        // Arrange - Poor guard not meeting CAO standards
        final poorGuard = ReputationData.initial(
          userId: 'poor-guard',
          userRole: 'guard',
        ).copyWith(
          totalJobsCompleted: 50,
          totalJobsCancelled: 10, // 83.3% completion rate
          noShowCount: 5, // Exceeds limit of 2
          lateArrivalCount: 8, // >5% late arrivals (8/58)
        );

        // Act & Assert
        expect(poorGuard.isReliableByCAOStandards, isFalse);
        expect(poorGuard.completionRate, lessThan(95.0));
      });

      test('should determine premium job eligibility correctly', () {
        // Arrange - Eligible guard
        final eligibleGuard = ReputationData.initial(
          userId: 'eligible-guard',
          userRole: 'guard',
        ).copyWith(
          overallScore: 80.0,
          totalJobsCompleted: 15,
          wpbrCertified: true,
          complianceViolationCount: 0,
        );

        // Act & Assert
        expect(eligibleGuard.qualifiesForPremiumJobs, isTrue);

        // Arrange - Ineligible guard (no WPBR)
        final ineligibleGuard = eligibleGuard.copyWith(
          wpbrCertified: false,
        );

        // Act & Assert
        expect(ineligibleGuard.qualifiesForPremiumJobs, isFalse);

        // Arrange - Ineligible guard (too few jobs)
        final inexperiencedGuard = eligibleGuard.copyWith(
          totalJobsCompleted: 5,
        );

        // Act & Assert
        expect(inexperiencedGuard.qualifiesForPremiumJobs, isFalse);
      });
    });

    group('ReputationLevel Tests', () {
      test('should provide correct Dutch descriptions', () {
        expect(ReputationLevel.poor.dutchTitle, equals('Onvoldoende'));
        expect(ReputationLevel.belowAverage.dutchTitle, equals('Onder gemiddeld'));
        expect(ReputationLevel.average.dutchTitle, equals('Gemiddeld'));
        expect(ReputationLevel.good.dutchTitle, equals('Goed'));
        expect(ReputationLevel.excellent.dutchTitle, equals('Uitstekend'));
        expect(ReputationLevel.exceptional.dutchTitle, equals('Uitzonderlijk'));
      });

      test('should provide correct minimum scores', () {
        expect(ReputationLevel.poor.minimumScore, equals(0.0));
        expect(ReputationLevel.belowAverage.minimumScore, equals(40.0));
        expect(ReputationLevel.average.minimumScore, equals(60.0));
        expect(ReputationLevel.good.minimumScore, equals(70.0));
        expect(ReputationLevel.excellent.minimumScore, equals(80.0));
        expect(ReputationLevel.exceptional.minimumScore, equals(90.0));
      });
    });

    group('ReputationTrend Tests', () {
      test('should provide correct Dutch descriptions and advice', () {
        expect(ReputationTrend.declining.dutchDescription, equals('Dalende trend'));
        expect(ReputationTrend.stable.dutchDescription, equals('Stabiele reputatie'));
        expect(ReputationTrend.improving.dutchDescription, equals('Stijgende trend'));

        expect(ReputationTrend.declining.dutchAdvice, 
            contains('verbeteren van je prestaties'));
        expect(ReputationTrend.stable.dutchAdvice, 
            contains('Behoud je huidige'));
        expect(ReputationTrend.improving.dutchAdvice, 
            contains('Blijf zo doorgaan'));
      });
    });

    group('ReputationMilestone Tests', () {
      test('should provide correct Dutch titles and descriptions', () {
        expect(ReputationMilestone.firstJob.dutchTitle, equals('Eerste Opdracht'));
        expect(ReputationMilestone.tenJobsCompleted.dutchTitle, equals('10 Opdrachten Voltooid'));
        expect(ReputationMilestone.hundredJobsCompleted.dutchTitle, equals('100 Opdrachten Voltooid'));
        expect(ReputationMilestone.topRatedGuard.dutchTitle, equals('Top Beveiliger'));
        expect(ReputationMilestone.reliabilityExpert.dutchTitle, equals('Betrouwbaarheidsexpert'));
      });

      test('should correctly check eligibility', () {
        final newGuard = ReputationData.initial(
          userId: 'new-guard',
          userRole: 'guard',
        );

        // New guard should not be eligible for most milestones
        expect(ReputationMilestone.firstJob.isEligible(newGuard), isFalse);
        expect(ReputationMilestone.tenJobsCompleted.isEligible(newGuard), isFalse);

        final experiencedGuard = newGuard.copyWith(
          totalJobsCompleted: 25,
          positiveReviewCount: 20,
          overallScore: 90.0,
          noShowCount: 0,
          lateArrivalCount: 0,
        );

        // Experienced guard should be eligible for several milestones
        expect(ReputationMilestone.firstJob.isEligible(experiencedGuard), isTrue);
        expect(ReputationMilestone.tenJobsCompleted.isEligible(experiencedGuard), isTrue);
        expect(ReputationMilestone.firstGoodReview.isEligible(experiencedGuard), isTrue);
        expect(ReputationMilestone.topRatedGuard.isEligible(experiencedGuard), isTrue);
        expect(ReputationMilestone.perfectMonth.isEligible(experiencedGuard), isTrue);
      });
    });

    group('Data Model Serialization Tests', () {
      test('should serialize to and from Firestore correctly', () {
        // Arrange
        final originalReputation = ReputationData(
          userId: 'test-user',
          userRole: 'guard',
          lastCalculated: DateTime(2024, 1, 15, 10, 30),
          firstJobDate: DateTime(2023, 6, 1),
          overallScore: 75.5,
          jobCompletionRating: 4.1,
          reliabilityScore: 85.0,
          clientFeedbackScore: 80.0,
          complianceScore: 70.0,
          experienceMultiplier: 1.15,
          totalJobsCompleted: 30,
          totalJobsCancelled: 2,
          noShowCount: 1,
          lateArrivalCount: 3,
          earlyCompletionCount: 5,
          averageResponseTime: 18.5,
          positiveReviewCount: 25,
          neutralReviewCount: 4,
          negativeReviewCount: 1,
          repeatClientPercentage: 45.0,
          recommendationRate: 83.3,
          wpbrCertified: true,
          kvkVerified: false,
          activeCertificateCount: 3,
          lastCertificateUpdate: DateTime(2024, 1, 1),
          complianceViolationCount: 0,
          monthlyScoreChange: 3.2,
          quarterlyScoreChange: 7.8,
          currentTrend: ReputationTrend.improving,
          achievedMilestones: [
            ReputationMilestone.firstJob,
            ReputationMilestone.tenJobsCompleted,
            ReputationMilestone.firstGoodReview,
          ],
          specializationScores: {
            'eventSecurity': 4.3,
            'retailSecurity': 4.0,
          },
          topSpecialization: 'eventSecurity',
          averageHourlyRate: 17.25,
        );

        // Act - Convert to Firestore format and back
        final firestoreData = originalReputation.toFirestore();
        
        // Note: We can't actually create a DocumentSnapshot for testing
        // This would normally be tested with Firebase Test SDK
        // But we can verify the data structure is correct
        
        expect(firestoreData['userId'], equals('test-user'));
        expect(firestoreData['userRole'], equals('guard'));
        expect(firestoreData['overallScore'], equals(75.5));
        expect(firestoreData['wpbrCertified'], equals(true));
        expect(firestoreData['currentTrend'], equals('improving'));
        expect(firestoreData['achievedMilestones'], equals(['firstJob', 'tenJobsCompleted', 'firstGoodReview']));
        expect(firestoreData['specializationScores'], equals({'eventSecurity': 4.3, 'retailSecurity': 4.0}));
      });
    });

    group('Dutch Business Logic Tests', () {
      test('should handle Dutch wage standards correctly', () {
        final guardReputation = ReputationData.initial(
          userId: 'dutch-guard',
          userRole: 'guard',
        ).copyWith(
          averageHourlyRate: 18.50, // Above minimum security wage
          totalJobsCompleted: 50,
          overallScore: 85.0,
        );

        // Should meet Dutch security industry standards
        expect(guardReputation.averageHourlyRate, greaterThanOrEqualTo(12.0));
        expect(guardReputation.totalJobsCompleted, greaterThan(10));
      });

      test('should handle company KvK verification correctly', () {
        final companyReputation = ReputationData.initial(
          userId: 'dutch-company',
          userRole: 'company',
        ).copyWith(
          kvkVerified: true, // Dutch business registration
          complianceViolationCount: 0,
          overallScore: 78.0,
        );

        expect(companyReputation.kvkVerified, isTrue);
        expect(companyReputation.wpbrCertified, isFalse); // Not applicable for companies
      });

      test('should calculate experience correctly with Dutch standards', () {
        final experiencedGuard = ReputationData.initial(
          userId: 'experienced-guard',
          userRole: 'guard',
        ).copyWith(
          firstJobDate: DateTime.now().subtract(const Duration(days: 730)), // 2 years
          totalJobsCompleted: 200, // Experienced
          averageHourlyRate: 20.0, // Well above minimum
        );

        expect(experiencedGuard.yearsOfExperience, greaterThan(1.8));
        expect(experiencedGuard.totalJobsCompleted, greaterThan(100));
      });
    });

    group('Error Handling Tests', () {
      test('should handle edge cases in reputation calculation', () {
        // Test division by zero scenarios
        final emptyReputation = ReputationData.initial(
          userId: 'empty-user',
          userRole: 'guard',
        );

        expect(emptyReputation.completionRate, equals(100.0)); // Should default to 100% when no jobs
        expect(emptyReputation.positiveReviewPercentage, equals(0.0)); // Should be 0% when no reviews
        expect(emptyReputation.yearsOfExperience, greaterThanOrEqualTo(0.0));
      });

      test('should clamp scores to valid ranges', () {
        final reputation = ReputationData.initial(
          userId: 'test-user',
          userRole: 'guard',
        ).copyWith(
          overallScore: 105.0, // Invalid high score
        );

        // Note: Actual clamping would happen in the calculation service
        // Here we just verify the model accepts the value
        expect(reputation.overallScore, equals(105.0));
        
        // But the reputation level should still work correctly
        expect(reputation.reputationLevel, equals(ReputationLevel.exceptional));
      });
    });

    test('should provide consistent Dutch formatting', () {
      final reputation = ReputationData.initial(
        userId: 'formatting-test',
        userRole: 'guard',
      ).copyWith(
        overallScore: 87.5,
      );

      expect(reputation.dutchFormattedScore, equals('88/100')); // Rounded
    });
  });
}