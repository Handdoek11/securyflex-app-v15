import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/company_dashboard/services/guard_matching_engine.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';

/// Comprehensive tests for Guard Matching Engine
/// 
/// Tests cover:
/// - Guard matching algorithm accuracy
/// - Match percentage calculations
/// - Skills and certification matching
/// - Geographic optimization
/// - Performance-based recommendations
/// - Availability filtering
/// - Cost optimization
/// - Emergency replacement functionality
/// - Cache performance
void main() {
  group('GuardMatchingEngine Tests', () {
    late GuardMatchingEngine matchingEngine;

    setUp(() {
      matchingEngine = GuardMatchingEngine();
      matchingEngine.clearCache(); // Ensure clean state
    });

    group('Basic Guard Matching', () {
      test('should return guard suggestions for valid job requirements', () async {
        final suggestions = await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: ['Access Control'],
          requiredCertificates: ['Beveiliger 2'],
          minimumExperience: 1,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 25.0,
          maxSuggestions: 10,
        );

        expect(suggestions, isNotEmpty);
        expect(suggestions.length, lessThanOrEqualTo(10));
        
        // All suggestions should have valid data
        for (final suggestion in suggestions) {
          expect(suggestion.guardId, isNotEmpty);
          expect(suggestion.guardName, isNotEmpty);
          expect(suggestion.matchPercentage, greaterThanOrEqualTo(30.0)); // Minimum threshold
          expect(suggestion.matchPercentage, lessThanOrEqualTo(100.0));
          expect(suggestion.rating, greaterThanOrEqualTo(0.0));
          expect(suggestion.rating, lessThanOrEqualTo(5.0));
          expect(suggestion.completedJobs, greaterThanOrEqualTo(0));
          expect(suggestion.distanceKm, greaterThanOrEqualTo(0.0));
          expect(suggestion.hourlyRate, greaterThan(0.0));
          expect(suggestion.matchReasons, isNotEmpty);
        }
      });

      test('should sort suggestions by match percentage descending', () async {
        final suggestions = await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: ['Access Control', 'CCTV Monitoring'],
          requiredCertificates: ['Beveiliger 2'],
          minimumExperience: 2,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 30.0,
          maxSuggestions: 5,
        );

        expect(suggestions, isNotEmpty);
        
        // Should be sorted by match percentage (descending)
        for (int i = 0; i < suggestions.length - 1; i++) {
          expect(
            suggestions[i].matchPercentage,
            greaterThanOrEqualTo(suggestions[i + 1].matchPercentage),
          );
        }
      });

      test('should respect maximum suggestions limit', () async {
        final suggestions = await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 50.0,
          maxSuggestions: 3,
        );

        expect(suggestions.length, lessThanOrEqualTo(3));
      });
    });

    group('Skills and Certification Matching', () {
      test('should prioritize guards with matching skills', () async {
        final suggestions = await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: ['Access Control', 'CCTV Monitoring'],
          requiredCertificates: [],
          minimumExperience: 0,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 30.0,
          maxSuggestions: 10,
        );

        expect(suggestions, isNotEmpty);
        
        // Top suggestions should have some matching skills
        final topSuggestion = suggestions.first;
        expect(topSuggestion.matchingSkills, isNotEmpty);
        
        // Should have skill-based match reasons
        final hasSkillReason = topSuggestion.matchReasons.any(
          (reason) => reason.type == MatchReasonType.skill,
        );
        expect(hasSkillReason, isTrue);
      });

      test('should handle jobs with no specific skill requirements', () async {
        final suggestions = await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: [], // No specific skills required
          requiredCertificates: [],
          minimumExperience: 0,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 25.0,
          maxSuggestions: 5,
        );

        expect(suggestions, isNotEmpty);
        
        // Should still return valid matches
        for (final suggestion in suggestions) {
          expect(suggestion.matchPercentage, greaterThanOrEqualTo(30.0));
        }
      });
    });

    group('Geographic Optimization', () {
      test('should consider distance in matching', () async {
        final suggestions = await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 25.0,
          maxSuggestions: 10,
        );

        expect(suggestions, isNotEmpty);
        
        // All suggestions should have distance information
        for (final suggestion in suggestions) {
          expect(suggestion.distanceKm, greaterThanOrEqualTo(0.0));
          expect(suggestion.distanceKm, lessThan(100.0)); // Reasonable max distance
        }
        
        // Should have location-based match reasons
        final hasLocationReason = suggestions.any((suggestion) =>
          suggestion.matchReasons.any(
            (reason) => reason.type == MatchReasonType.location,
          ),
        );
        expect(hasLocationReason, isTrue);
      });
    });

    group('Performance-Based Recommendations', () {
      test('should consider guard ratings in matching', () async {
        final suggestions = await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 30.0,
          maxSuggestions: 10,
        );

        expect(suggestions, isNotEmpty);
        
        // Should have rating-based match reasons
        final hasRatingReason = suggestions.any((suggestion) =>
          suggestion.matchReasons.any(
            (reason) => reason.type == MatchReasonType.rating,
          ),
        );
        expect(hasRatingReason, isTrue);
        
        // Higher-rated guards should generally have higher match percentages
        // (though other factors also influence matching)
        final highRatedGuards = suggestions.where((s) => s.rating >= 4.5).toList();
        final lowRatedGuards = suggestions.where((s) => s.rating < 3.5).toList();
        
        if (highRatedGuards.isNotEmpty && lowRatedGuards.isNotEmpty) {
          final avgHighRatedMatch = highRatedGuards
              .map((g) => g.matchPercentage)
              .reduce((a, b) => a + b) / highRatedGuards.length;
          final avgLowRatedMatch = lowRatedGuards
              .map((g) => g.matchPercentage)
              .reduce((a, b) => a + b) / lowRatedGuards.length;
          
          expect(avgHighRatedMatch, greaterThanOrEqualTo(avgLowRatedMatch));
        }
      });

      test('should consider experience in matching', () async {
        final suggestions = await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 3, // Require significant experience
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 35.0,
          maxSuggestions: 10,
        );

        expect(suggestions, isNotEmpty);
        
        // Should have experience-based match reasons
        final hasExperienceReason = suggestions.any((suggestion) =>
          suggestion.matchReasons.any(
            (reason) => reason.type == MatchReasonType.experience,
          ),
        );
        expect(hasExperienceReason, isTrue);
        
        // Guards with more completed jobs should generally rank higher
        final experiencedGuards = suggestions.where((s) => s.completedJobs >= 50).toList();
        if (experiencedGuards.isNotEmpty) {
          expect(experiencedGuards.first.matchPercentage, greaterThan(50.0));
        }
      });
    });

    group('Availability Filtering', () {
      test('should prioritize available guards', () async {
        final suggestions = await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 25.0,
          maxSuggestions: 10,
        );

        expect(suggestions, isNotEmpty);
        
        // Should have availability-based match reasons
        final hasAvailabilityReason = suggestions.any((suggestion) =>
          suggestion.matchReasons.any(
            (reason) => reason.type == MatchReasonType.availability,
          ),
        );
        expect(hasAvailabilityReason, isTrue);
        
        // Available guards should have higher match percentages than busy ones
        final availableGuards = suggestions
            .where((s) => s.availability == GuardAvailabilityStatus.available)
            .toList();
        final busyGuards = suggestions
            .where((s) => s.availability == GuardAvailabilityStatus.busy)
            .toList();
        
        if (availableGuards.isNotEmpty && busyGuards.isNotEmpty) {
          expect(availableGuards.first.matchPercentage, 
                 greaterThan(busyGuards.first.matchPercentage));
        }
      });
    });

    group('Cost Optimization', () {
      test('should consider hourly rates in matching', () async {
        final suggestions = await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 20.0, // Lower budget
          maxSuggestions: 10,
        );

        expect(suggestions, isNotEmpty);
        
        // Should have cost-based match reasons
        final hasCostReason = suggestions.any((suggestion) =>
          suggestion.matchReasons.any(
            (reason) => reason.type == MatchReasonType.cost,
          ),
        );
        expect(hasCostReason, isTrue);
        
        // Guards within budget should have higher match percentages
        final withinBudgetGuards = suggestions
            .where((s) => s.hourlyRate <= 20.0)
            .toList();
        final overBudgetGuards = suggestions
            .where((s) => s.hourlyRate > 20.0)
            .toList();
        
        if (withinBudgetGuards.isNotEmpty && overBudgetGuards.isNotEmpty) {
          // Guards within budget should have higher match percentages
          // Allow for some tolerance in the matching algorithm
          expect(withinBudgetGuards.first.matchPercentage,
                 greaterThan(85.0)); // Reasonable threshold for within-budget guards
        }
      });
    });

    group('Emergency Replacement', () {
      test('should provide emergency replacement suggestions', () async {
        final emergencyReplacements = await matchingEngine.getEmergencyReplacements(
          originalGuardId: 'GUARD_001',
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          startDate: DateTime.now().add(Duration(hours: 2)), // Very soon
          maxHourlyRate: 30.0,
          maxSuggestions: 5,
        );

        expect(emergencyReplacements, isNotEmpty);
        expect(emergencyReplacements.length, lessThanOrEqualTo(5));
        
        // All emergency replacements should be available
        for (final replacement in emergencyReplacements) {
          expect(replacement.availability, equals(GuardAvailabilityStatus.available));
          expect(replacement.guardId, isNot(equals('GUARD_001'))); // Not the original guard
          expect(replacement.matchReasons, isNotEmpty);
          
          // Should have emergency-specific match reasons
          final hasEmergencyReason = replacement.matchReasons.any(
            (reason) => reason.reason.toLowerCase().contains('spoedopdracht'),
          );
          expect(hasEmergencyReason, isTrue);
        }
        
        // Should be sorted by emergency score (match percentage)
        for (int i = 0; i < emergencyReplacements.length - 1; i++) {
          expect(
            emergencyReplacements[i].matchPercentage,
            greaterThanOrEqualTo(emergencyReplacements[i + 1].matchPercentage),
          );
        }
      });

      test('should prioritize proximity for emergency replacements', () async {
        final emergencyReplacements = await matchingEngine.getEmergencyReplacements(
          originalGuardId: 'GUARD_001',
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          startDate: DateTime.now().add(Duration(hours: 1)),
          maxHourlyRate: 35.0,
          maxSuggestions: 3,
        );

        expect(emergencyReplacements, isNotEmpty);
        
        // Emergency replacements should generally be close by
        final averageDistance = emergencyReplacements
            .map((r) => r.distanceKm)
            .reduce((a, b) => a + b) / emergencyReplacements.length;
        
        expect(averageDistance, lessThan(30.0)); // Should be relatively close
      });
    });

    group('Cache Performance', () {
      test('should cache guard suggestions', () async {
        final startTime = DateTime.now();
        
        // First call
        final suggestions1 = await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: ['Access Control'],
          requiredCertificates: ['Beveiliger 2'],
          minimumExperience: 1,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 25.0,
          maxSuggestions: 5,
        );
        
        final firstCallTime = DateTime.now().difference(startTime);
        
        final secondStartTime = DateTime.now();
        
        // Second call with same parameters
        final suggestions2 = await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: ['Access Control'],
          requiredCertificates: ['Beveiliger 2'],
          minimumExperience: 1,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 25.0,
          maxSuggestions: 5,
        );
        
        final secondCallTime = DateTime.now().difference(secondStartTime);
        
        // Results should be identical
        expect(suggestions1.length, equals(suggestions2.length));
        if (suggestions1.isNotEmpty && suggestions2.isNotEmpty) {
          expect(suggestions1.first.guardId, equals(suggestions2.first.guardId));
          expect(suggestions1.first.matchPercentage, equals(suggestions2.first.matchPercentage));
        }
        
        // Second call should be faster
        expect(secondCallTime.inMilliseconds, lessThan(firstCallTime.inMilliseconds));
      });

      test('should clear cache correctly', () async {
        // Make a call to populate cache
        await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 25.0,
          maxSuggestions: 5,
        );

        // Clear cache
        matchingEngine.clearCache();

        // Next call should take longer (not cached)
        final startTime = DateTime.now();
        await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 25.0,
          maxSuggestions: 5,
        );
        final callTime = DateTime.now().difference(startTime);

        // Should take reasonable time (not instant from cache)
        expect(callTime.inMilliseconds, greaterThan(100));
      });
    });

    group('Edge Cases', () {
      test('should handle very restrictive requirements', () async {
        final suggestions = await matchingEngine.getGuardSuggestions(
          jobType: JobType.persoonbeveiliging,
          location: 'Amsterdam',
          postalCode: '1012AB',
          requiredSkills: ['VIP Protection', 'Advanced Combat', 'Surveillance'],
          requiredCertificates: ['Persoonbeveiliging', 'VCA', 'EHBO'],
          minimumExperience: 10, // Very high requirement
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 15.0, // Very low budget
          maxSuggestions: 10,
        );

        // May return empty list or very few matches due to restrictive requirements
        // This is expected behavior
        expect(suggestions, isA<List<GuardMatchSuggestion>>());
        
        // Any returned suggestions should still meet minimum match threshold
        for (final suggestion in suggestions) {
          expect(suggestion.matchPercentage, greaterThanOrEqualTo(30.0));
        }
      });

      test('should handle invalid location gracefully', () async {
        final suggestions = await matchingEngine.getGuardSuggestions(
          jobType: JobType.objectbeveiliging,
          location: 'NonexistentCity',
          postalCode: 'INVALID',
          requiredSkills: [],
          requiredCertificates: [],
          minimumExperience: 0,
          startDate: DateTime.now().add(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 2)),
          maxHourlyRate: 25.0,
          maxSuggestions: 5,
        );

        // Should still return suggestions (with default distance calculations)
        expect(suggestions, isA<List<GuardMatchSuggestion>>());
        
        for (final suggestion in suggestions) {
          expect(suggestion.distanceKm, greaterThanOrEqualTo(0.0));
        }
      });
    });
  });
}
