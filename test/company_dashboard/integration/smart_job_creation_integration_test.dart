import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/company_dashboard/services/smart_pricing_service.dart';
import 'package:securyflex_app/company_dashboard/services/guard_matching_engine.dart';
import 'package:securyflex_app/company_dashboard/services/job_analytics_service.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';

/// Integration tests for Smart Job Creation workflow
/// 
/// Tests the complete end-to-end workflow of creating a job with AI assistance:
/// 1. Smart pricing recommendations
/// 2. Guard matching suggestions
/// 3. Job performance predictions
/// 4. Complete job creation with all AI data
/// 
/// These tests ensure all services work together correctly and provide
/// a cohesive user experience.
void main() {
  group('Smart Job Creation Integration Tests', () {
    late SmartPricingService pricingService;
    late GuardMatchingEngine matchingEngine;
    late JobAnalyticsService analyticsService;

    setUp(() {
      pricingService = SmartPricingService();
      matchingEngine = GuardMatchingEngine();
      analyticsService = JobAnalyticsService();
      
      // Clear caches for clean test state
      pricingService.clearCache();
      matchingEngine.clearCache();
      analyticsService.clearCache();
    });

    group('Complete Job Creation Workflow', () {
      test('should create job with full AI assistance workflow', () async {
        // Step 1: Define job requirements
        final jobType = JobType.evenementbeveiliging;
        final location = 'Amsterdam';
        final postalCode = '1012AB';
        final startDate = DateTime.now().add(Duration(days: 7));
        final endDate = DateTime.now().add(Duration(days: 8));
        final requiredSkills = ['Crowd Control', 'Customer Service'];
        final requiredCertificates = ['Evenementbeveiliging'];
        final minimumExperience = 2;
        final isUrgent = false;

        // Step 2: Get smart pricing recommendations
        final pricingData = await pricingService.getSmartPricing(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          startDate: startDate,
          endDate: endDate,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          isUrgent: isUrgent,
        );

        expect(pricingData, isNotNull);
        expect(pricingData.recommendedRate, greaterThan(0));
        expect(pricingData.confidence, isNotNull);

        // Step 3: Get guard matching suggestions
        final guardSuggestions = await matchingEngine.getGuardSuggestions(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          startDate: startDate,
          endDate: endDate,
          maxHourlyRate: pricingData.recommendedRate * 1.1, // 10% buffer
          maxSuggestions: 5,
        );

        expect(guardSuggestions, isNotEmpty);
        expect(guardSuggestions.length, lessThanOrEqualTo(5));

        // Step 4: Get job performance predictions
        final predictions = await analyticsService.getJobPredictions(
          jobId: 'temp_job_${DateTime.now().millisecondsSinceEpoch}',
          jobType: jobType,
          location: location,
          hourlyRate: pricingData.recommendedRate,
          requiredSkills: requiredSkills,
          startDate: startDate,
          isUrgent: isUrgent,
        );

        expect(predictions, isNotNull);
        expect(predictions.predictedApplications, greaterThan(0));
        expect(predictions.predictedTimeToFill.inHours, greaterThan(0));
        expect(predictions.predictedHireSuccess, greaterThan(0.0));
        expect(predictions.predictedHireSuccess, lessThanOrEqualTo(1.0));

        // Step 5: Create complete job with all AI data
        final jobData = JobPostingData(
          jobId: 'job_${DateTime.now().millisecondsSinceEpoch}',
          companyId: 'COMP001',
          title: 'Evenementbeveiliging Amsterdam',
          description: 'Ervaren beveiliger gezocht voor evenement in Amsterdam',
          location: location,
          postalCode: postalCode,
          hourlyRate: pricingData.recommendedRate,
          startDate: startDate,
          endDate: endDate,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          status: JobPostingStatus.active,
          createdDate: DateTime.now(),
          isUrgent: isUrgent,
          jobType: jobType,
          // AI-powered data
          smartPricing: pricingData,
          suggestedGuards: guardSuggestions,
          predictions: predictions,
        );

        // Verify complete job data
        expect(jobData.smartPricing, isNotNull);
        expect(jobData.suggestedGuards, isNotEmpty);
        expect(jobData.predictions, isNotNull);
        expect(jobData.hourlyRate, equals(pricingData.recommendedRate));
      });

      test('should handle high-demand scenario correctly', () async {
        // Simulate high-demand scenario (weekend, urgent, premium location)
        final jobType = JobType.persoonbeveiliging;
        final location = 'Amsterdam';
        final postalCode = '1012AB';
        final startDate = DateTime.now().add(Duration(days: 2)); // Weekend
        final endDate = startDate.add(Duration(hours: 8));
        final requiredSkills = ['VIP Protection', 'Advanced Security'];
        final requiredCertificates = ['Persoonbeveiliging', 'VCA'];
        final minimumExperience = 5;
        final isUrgent = true;

        // Get pricing for high-demand scenario
        final pricingData = await pricingService.getSmartPricing(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          startDate: startDate,
          endDate: endDate,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          isUrgent: isUrgent,
        );

        // Should have premium pricing due to high demand factors
        expect(pricingData.recommendedRate, greaterThan(25.0)); // Higher than basic rate
        
        // Should have urgency factor
        final hasUrgencyFactor = pricingData.factors.any(
          (factor) => factor.name.toLowerCase().contains('urgentie'),
        );
        expect(hasUrgencyFactor, isTrue);

        // Get guard suggestions for premium job
        final guardSuggestions = await matchingEngine.getGuardSuggestions(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          startDate: startDate,
          endDate: endDate,
          maxHourlyRate: pricingData.premiumRate, // Use premium rate
          maxSuggestions: 3,
        );

        // May have fewer suggestions due to high requirements
        expect(guardSuggestions, isA<List<GuardMatchSuggestion>>());
        
        // Any suggestions should be high-quality matches
        for (final suggestion in guardSuggestions) {
          expect(suggestion.matchPercentage, greaterThan(50.0));
          expect(suggestion.rating, greaterThan(3.5)); // Higher quality guards
        }

        // Get predictions for premium job
        final predictions = await analyticsService.getJobPredictions(
          jobId: 'premium_job_${DateTime.now().millisecondsSinceEpoch}',
          jobType: jobType,
          location: location,
          hourlyRate: pricingData.recommendedRate,
          requiredSkills: requiredSkills,
          startDate: startDate,
          isUrgent: isUrgent,
        );

        // Premium jobs might have different prediction patterns
        expect(predictions.predictedApplications, greaterThan(0));
        expect(predictions.confidenceScore, greaterThan(0.5));
      });

      test('should optimize for budget-conscious scenario', () async {
        // Simulate budget-conscious scenario
        final jobType = JobType.objectbeveiliging;
        final location = 'Groningen'; // Lower cost area
        final postalCode = '9700AA';
        final startDate = DateTime.now().add(Duration(days: 14)); // Plenty of time
        final endDate = startDate.add(Duration(hours: 8));
        final requiredSkills = ['Access Control']; // Basic requirements
        final requiredCertificates = ['Beveiliger 2'];
        final minimumExperience = 1;
        final isUrgent = false;
        final maxBudget = 20.0; // Budget constraint

        // Get pricing for budget scenario
        final pricingData = await pricingService.getSmartPricing(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          startDate: startDate,
          endDate: endDate,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          isUrgent: isUrgent,
        );

        // Should suggest competitive pricing
        expect(pricingData.competitiveRate, lessThanOrEqualTo(maxBudget));

        // Get guard suggestions within budget
        final guardSuggestions = await matchingEngine.getGuardSuggestions(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          startDate: startDate,
          endDate: endDate,
          maxHourlyRate: maxBudget,
          maxSuggestions: 10,
        );

        // Should have good selection within budget
        expect(guardSuggestions, isNotEmpty);
        
        // All suggestions should be within budget
        for (final suggestion in guardSuggestions) {
          expect(suggestion.hourlyRate, lessThanOrEqualTo(maxBudget * 1.1)); // Small buffer
        }

        // Should have cost-optimized match reasons
        final hasCostOptimization = guardSuggestions.any((suggestion) =>
          suggestion.matchReasons.any(
            (reason) => reason.type == MatchReasonType.cost,
          ),
        );
        expect(hasCostOptimization, isTrue);
      });
    });

    group('Service Integration and Consistency', () {
      test('should maintain data consistency across services', () async {
        final jobType = JobType.evenementbeveiliging;
        final location = 'Rotterdam';
        final postalCode = '3000AA';
        final startDate = DateTime.now().add(Duration(days: 5));
        final endDate = startDate.add(Duration(hours: 6));
        final requiredSkills = ['Crowd Control'];
        final requiredCertificates = ['Evenementbeveiliging'];
        final minimumExperience = 2;

        // Get data from all services
        final pricingData = await pricingService.getSmartPricing(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          startDate: startDate,
          endDate: endDate,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          isUrgent: false,
        );

        final guardSuggestions = await matchingEngine.getGuardSuggestions(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          startDate: startDate,
          endDate: endDate,
          maxHourlyRate: pricingData.recommendedRate,
          maxSuggestions: 5,
        );

        final predictions = await analyticsService.getJobPredictions(
          jobId: 'consistency_test_${DateTime.now().millisecondsSinceEpoch}',
          jobType: jobType,
          location: location,
          hourlyRate: pricingData.recommendedRate,
          requiredSkills: requiredSkills,
          startDate: startDate,
          isUrgent: false,
        );

        // Verify data consistency
        expect(pricingData.recommendedRate, greaterThan(0));
        expect(guardSuggestions, isNotEmpty);
        expect(predictions.predictedApplications, greaterThan(0));

        // Guard suggestions should be compatible with pricing
        final affordableGuards = guardSuggestions
            .where((g) => g.hourlyRate <= pricingData.recommendedRate * 1.1)
            .length;
        expect(affordableGuards, greaterThan(0));

        // Predictions should be realistic
        expect(predictions.predictedTimeToFill.inDays, lessThan(14));
        expect(predictions.confidenceScore, greaterThan(0.3));
      });

      test('should handle service failures gracefully', () async {
        // Test with edge case parameters that might cause issues
        final jobType = JobType.transport;
        final location = 'UnknownCity';
        final postalCode = 'INVALID';
        final startDate = DateTime.now().subtract(Duration(days: 1)); // Past date
        final endDate = startDate.add(Duration(hours: 1));
        final requiredSkills = ['NonexistentSkill'];
        final requiredCertificates = ['InvalidCertificate'];
        final minimumExperience = 50; // Unrealistic requirement

        // Services should handle invalid data gracefully
        final pricingData = await pricingService.getSmartPricing(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          startDate: startDate,
          endDate: endDate,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          isUrgent: false,
        );

        // Should still return valid pricing data
        expect(pricingData.recommendedRate, greaterThan(0));
        expect(pricingData.confidence, isNotNull);

        final guardSuggestions = await matchingEngine.getGuardSuggestions(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          startDate: startDate,
          endDate: endDate,
          maxHourlyRate: pricingData.recommendedRate,
          maxSuggestions: 5,
        );

        // May return empty list due to unrealistic requirements
        expect(guardSuggestions, isA<List<GuardMatchSuggestion>>());

        final predictions = await analyticsService.getJobPredictions(
          jobId: 'edge_case_${DateTime.now().millisecondsSinceEpoch}',
          jobType: jobType,
          location: location,
          hourlyRate: pricingData.recommendedRate,
          requiredSkills: requiredSkills,
          startDate: startDate,
          isUrgent: false,
        );

        // Should still provide predictions
        expect(predictions.predictedApplications, greaterThanOrEqualTo(0));
        expect(predictions.confidenceScore, greaterThanOrEqualTo(0.0));
      });
    });

    group('Performance and Caching Integration', () {
      test('should demonstrate performance benefits of caching', () async {
        final jobType = JobType.objectbeveiliging;
        final location = 'Amsterdam';
        final postalCode = '1012AB';
        final startDate = DateTime.now().add(Duration(days: 3));
        final endDate = startDate.add(Duration(hours: 8));
        final requiredSkills = ['Access Control'];
        final requiredCertificates = ['Beveiliger 2'];
        final minimumExperience = 1;

        // First complete workflow - should populate caches
        final startTime1 = DateTime.now();
        
        final pricingData1 = await pricingService.getSmartPricing(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          startDate: startDate,
          endDate: endDate,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          isUrgent: false,
        );

        final guardSuggestions1 = await matchingEngine.getGuardSuggestions(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          startDate: startDate,
          endDate: endDate,
          maxHourlyRate: pricingData1.recommendedRate,
          maxSuggestions: 5,
        );

        final firstWorkflowTime = DateTime.now().difference(startTime1);

        // Second identical workflow - should use caches
        final startTime2 = DateTime.now();
        
        final pricingData2 = await pricingService.getSmartPricing(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          startDate: startDate,
          endDate: endDate,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          isUrgent: false,
        );

        final guardSuggestions2 = await matchingEngine.getGuardSuggestions(
          jobType: jobType,
          location: location,
          postalCode: postalCode,
          requiredSkills: requiredSkills,
          requiredCertificates: requiredCertificates,
          minimumExperience: minimumExperience,
          startDate: startDate,
          endDate: endDate,
          maxHourlyRate: pricingData2.recommendedRate,
          maxSuggestions: 5,
        );

        final secondWorkflowTime = DateTime.now().difference(startTime2);

        // Results should be identical
        expect(pricingData1.recommendedRate, equals(pricingData2.recommendedRate));
        expect(guardSuggestions1.length, equals(guardSuggestions2.length));

        // Second workflow should be significantly faster
        expect(secondWorkflowTime.inMilliseconds, 
               lessThan(firstWorkflowTime.inMilliseconds));
      });
    });
  });
}
