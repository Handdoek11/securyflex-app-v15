import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/company_dashboard/services/smart_pricing_service.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';

/// Comprehensive tests for Smart Pricing Service
/// 
/// Tests cover:
/// - Pricing calculation accuracy
/// - Location-based multipliers
/// - Time-based adjustments
/// - Skills and experience factors
/// - Market demand integration
/// - Confidence scoring
/// - Cache functionality
/// - Edge cases and error handling
void main() {
  group('SmartPricingService Tests', () {
    late SmartPricingService pricingService;

    setUp(() {
      pricingService = SmartPricingService();
      pricingService.clearCache(); // Ensure clean state
    });

    group('Basic Pricing Calculations', () {
      test('should return valid pricing data for standard job', () async {
        final pricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: ['Access Control'],
          requiredCertificates: ['Beveiliger 2'],
          minimumExperience: 2,
          isUrgent: false,
        );

        expect(pricing.recommendedRate, greaterThan(0));
        expect(pricing.marketAverageRate, greaterThan(0));
        expect(pricing.competitiveRate, greaterThan(0));
        expect(pricing.premiumRate, greaterThan(0));
        expect(pricing.confidence, isNotNull);
        expect(pricing.factors, isNotEmpty);
        expect(pricing.demandData, isNotNull);
      });

      test('should apply location multipliers correctly', () async {
        // Test Amsterdam (high cost area)
        final amsterdamPricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );

        // Test smaller city (lower cost area)
        final groningenPricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Groningen',
          postalCode: '9700AA',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );

        // Amsterdam should have higher rates due to location multiplier
        expect(amsterdamPricing.recommendedRate, greaterThan(groningenPricing.recommendedRate));
      });

      test('should apply urgency premium correctly', () async {
        // Test normal job
        final normalPricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Utrecht',
          postalCode: '3500AA',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );

        // Test urgent job
        final urgentPricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Utrecht',
          postalCode: '3500AA',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: true,
        );

        // Urgent job should have higher rate
        expect(urgentPricing.recommendedRate, greaterThan(normalPricing.recommendedRate));
        
        // Should have urgency factor
        final urgencyFactor = urgentPricing.factors.firstWhere(
          (factor) => factor.name.toLowerCase().contains('urgentie'),
          orElse: () => throw Exception('Urgency factor not found'),
        );
        expect(urgencyFactor.impact, greaterThan(0));
      });

      test('should adjust pricing based on skills and experience', () async {
        // Test basic job
        final basicPricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Rotterdam',
          postalCode: '3000AA',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );

        // Test complex job with many requirements
        final complexPricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Rotterdam',
          postalCode: '3000AA',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: ['Access Control', 'CCTV Monitoring', 'Patrol Services'],
          requiredCertificates: ['Beveiliger 2', 'VCA'],
          minimumExperience: 5,
          isUrgent: false,
        );

        // Complex job should have higher rate
        expect(complexPricing.recommendedRate, greaterThan(basicPricing.recommendedRate));
      });
    });

    group('Job Type Pricing', () {
      test('should have different base rates for different job types', () async {
        final startDate = DateTime.now().add(Duration(days: 1));
        final endDate = DateTime.now().add(Duration(days: 2));
        
        final objectPricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Utrecht',
          postalCode: '3500AA',
          startDate: startDate,
          endDate: endDate,
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );

        final eventPricing = await pricingService.getSmartPricing(
          jobType: JobType.evenementbeveiliging,
          location: 'Utrecht',
          postalCode: '3500AA',
          startDate: startDate,
          endDate: endDate,
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );

        final personalPricing = await pricingService.getSmartPricing(
          jobType: JobType.persoonbeveiliging,
          location: 'Utrecht',
          postalCode: '3500AA',
          startDate: startDate,
          endDate: endDate,
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );

        // Personal security should be most expensive
        expect(personalPricing.recommendedRate, greaterThan(eventPricing.recommendedRate));
        expect(eventPricing.recommendedRate, greaterThan(objectPricing.recommendedRate));
      });
    });

    group('Confidence Scoring', () {
      test('should provide appropriate confidence levels', () async {
        final pricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: ['Access Control'],
          requiredCertificates: ['Beveiliger 2'],
          minimumExperience: 2,
          isUrgent: false,
        );

        expect(pricing.confidence, isIn([
          PricingConfidence.low,
          PricingConfidence.medium,
          PricingConfidence.high,
          PricingConfidence.veryHigh,
        ]));
      });
    });

    group('Market Demand Integration', () {
      test('should include market demand data', () async {
        final pricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );

        expect(pricing.demandData.demandScore, greaterThanOrEqualTo(0.0));
        expect(pricing.demandData.demandScore, lessThanOrEqualTo(1.0));
        expect(pricing.demandData.competingJobs, greaterThanOrEqualTo(0));
        expect(pricing.demandData.availableGuards, greaterThanOrEqualTo(0));
        expect(pricing.demandData.supplyDemandRatio, greaterThan(0.0));
        expect(pricing.demandData.peakHours, isNotEmpty);
      });
    });

    group('Pricing Factors', () {
      test('should provide detailed pricing factors', () async {
        final pricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: ['Access Control'],
          requiredCertificates: ['Beveiliger 2'],
          minimumExperience: 2,
          isUrgent: true,
        );

        expect(pricing.factors, isNotEmpty);
        
        // Should have location factor
        expect(pricing.factors.any((f) => f.name.toLowerCase().contains('locatie')), isTrue);
        
        // Should have urgency factor
        expect(pricing.factors.any((f) => f.name.toLowerCase().contains('urgentie')), isTrue);
        
        // Should have skills factor
        expect(pricing.factors.any((f) => f.name.toLowerCase().contains('vaardigheden')), isTrue);
        
        // All factors should have valid impact values
        for (final factor in pricing.factors) {
          expect(factor.impact, isA<double>());
          expect(factor.description, isNotEmpty);
        }
      });
    });

    group('Cache Functionality', () {
      test('should cache pricing results', () async {
        final startTime = DateTime.now();
        
        // First call - should take longer (simulated API call)
        final pricing1 = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );
        
        final firstCallTime = DateTime.now().difference(startTime);
        
        final secondStartTime = DateTime.now();
        
        // Second call with same parameters - should be faster (cached)
        final pricing2 = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );
        
        final secondCallTime = DateTime.now().difference(secondStartTime);
        
        // Results should be identical
        expect(pricing1.recommendedRate, equals(pricing2.recommendedRate));
        expect(pricing1.confidence, equals(pricing2.confidence));
        
        // Second call should be significantly faster
        expect(secondCallTime.inMilliseconds, lessThan(firstCallTime.inMilliseconds));
      });

      test('should clear cache correctly', () async {
        // Make a call to populate cache
        await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );

        // Clear cache
        pricingService.clearCache();

        // Next call should take longer again (not cached)
        final startTime = DateTime.now();
        await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );
        final callTime = DateTime.now().difference(startTime);

        // Should take reasonable time (not instant from cache)
        expect(callTime.inMilliseconds, greaterThan(100));
      });
    });

    group('Pricing Trends', () {
      test('should provide pricing trends data', () async {
        final trends = await pricingService.getPricingTrends(
          JobType.objectbeveiliging,
          'Amsterdam',
        );

        expect(trends, containsPair('recommended_rates', isA<List<double>>()));
        expect(trends, containsPair('market_averages', isA<List<double>>()));
        expect(trends, containsPair('competitive_rates', isA<List<double>>()));

        final recommendedRates = trends['recommended_rates'] as List<double>;
        expect(recommendedRates, hasLength(12)); // 12 months
        expect(recommendedRates.every((rate) => rate > 0), isTrue);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle invalid postal codes gracefully', () async {
        final pricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Unknown City',
          postalCode: 'INVALID',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );

        // Should still return valid pricing (with default multipliers)
        expect(pricing.recommendedRate, greaterThan(0));
        expect(pricing.confidence, isNotNull);
      });

      test('should handle past dates appropriately', () async {
        final pricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          startDate: DateTime.now().subtract(Duration(days: 1)),
          endDate: DateTime.now(),
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          isUrgent: false,
        );

        // Should still return valid pricing
        expect(pricing.recommendedRate, greaterThan(0));
      });

      test('should handle extreme experience requirements', () async {
        final pricing = await pricingService.getSmartPricing(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 20, // Very high experience requirement
          isUrgent: false,
        );

        // Should still return reasonable pricing (capped multipliers)
        expect(pricing.recommendedRate, greaterThan(0));
        expect(pricing.recommendedRate, lessThan(100)); // Reasonable upper bound
      });
    });
  });
}
