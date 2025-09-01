import 'package:flutter/foundation.dart';
import 'package:securyflex_app/beveiliger_profiel/models/specialization.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';
import 'package:securyflex_app/marketplace/services/certificate_matching_service.dart';
import 'package:securyflex_app/marketplace/services/job_data_service.dart';
import 'package:securyflex_app/company_dashboard/services/analytics_service.dart';
import 'package:securyflex_app/company_dashboard/models/analytics_data_models.dart';
import 'package:securyflex_app/beveiliger_notificaties/services/guard_notification_service.dart';

/// Enhanced Job Matching Service with specialization integration
/// 
/// MANDATORY: Use existing job matching service for all recommendations
/// MANDATORY: Use existing job models and categories
/// Integration with existing recommendation algorithms
/// Enhancement of job recommendations based on profile specializations
class JobMatchingService {
  static JobMatchingService? _instance;
  static JobMatchingService get instance {
    _instance ??= JobMatchingService._();
    return _instance!;
  }

  JobMatchingService._();

  /// Analytics service for tracking user preferences
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  
  /// Guard notification service for job alerts
  final GuardNotificationService _notificationService = GuardNotificationService.instance;

  /// Cache for user preferences and recommendations
  final Map<String, Map<String, dynamic>> _userPreferencesCache = {};
  final Map<String, List<SecurityJobData>> _recommendationsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  /// Cache validity duration
  static const Duration _cacheValidDuration = Duration(minutes: 10);

  /// Update user specializations for enhanced job matching
  /// MANDATORY: Integration with existing recommendation algorithms
  Future<bool> updateUserSpecializations(String userId, List<Specialization> specializations) async {
    try {
      // Convert specializations to preference map
      final preferences = _convertSpecializationsToPreferences(specializations);
      
      // Cache user preferences
      _userPreferencesCache[userId] = {
        'specializations': specializations.map((s) => s.toJson()).toList(),
        'preferences': preferences,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      // Clear existing recommendations to force refresh
      _clearUserRecommendationsCache(userId);
      
      // Track analytics event
      await _analyticsService.trackEvent(
        jobId: 'user_preferences_$userId',
        eventType: JobEventType.userPreferenceUpdated,
        userId: userId,
        metadata: {
          'specializationsCount': specializations.length,
          'skillLevels': _getSkillLevelDistribution(specializations),
          'topSpecializations': specializations.take(3).map((s) => s.type.displayName).toList(),
        },
      );
      
      debugPrint('User specializations updated for enhanced matching: $userId');
      return true;
      
    } catch (e) {
      debugPrint('Error updating user specializations: $e');
      return false;
    }
  }

  /// Get enhanced job recommendations based on user specializations
  /// MANDATORY: Use existing job matching service integration
  Future<List<SecurityJobData>> getEnhancedJobRecommendations({
    required String userId,
    required List<Specialization> specializations,
    required List<String> userCertificates,
    int limit = 20,
    bool useCache = true,
  }) async {
    try {
      // Check cache if enabled
      if (useCache && _isRecommendationsCacheValid(userId)) {
        debugPrint('Returning cached job recommendations for user: $userId');
        return _recommendationsCache[userId] ?? [];
      }

      // Get all available jobs (this would integrate with existing job service)
      final allJobs = await _getAllAvailableJobs();
      
      if (allJobs.isEmpty) {
        debugPrint('No jobs available for matching');
        return [];
      }

      // Score jobs based on user specializations and preferences
      final jobScores = <SecurityJobData, JobMatchScore>{};
      
      for (final job in allJobs) {
        final matchScore = _calculateEnhancedJobMatchScore(
          job: job,
          specializations: specializations,
          userCertificates: userCertificates,
        );
        
        if (matchScore.totalScore >= 30) { // Minimum threshold for recommendations
          jobScores[job] = matchScore;
        }
      }

      // Sort jobs by total score and eligibility
      final sortedJobs = jobScores.entries.toList()
        ..sort((a, b) {
          // Prioritize eligible jobs
          if (a.value.isEligible && !b.value.isEligible) return -1;
          if (!a.value.isEligible && b.value.isEligible) return 1;
          
          // Then sort by total score
          return b.value.totalScore.compareTo(a.value.totalScore);
        });

      final recommendations = sortedJobs
          .map((entry) => entry.key)
          .take(limit)
          .toList();

      // Cache recommendations
      _recommendationsCache[userId] = recommendations;
      _cacheTimestamps[userId] = DateTime.now();

      // Track analytics for recommendation generation
      await _analyticsService.trackEvent(
        jobId: 'recommendations_$userId',
        eventType: JobEventType.recommendationsGenerated,
        userId: userId,
        metadata: {
          'totalJobs': allJobs.length,
          'matchedJobs': jobScores.length,
          'recommendationsCount': recommendations.length,
          'avgMatchScore': jobScores.values
              .map((score) => score.totalScore)
              .reduce((a, b) => a + b) / jobScores.length,
        },
      );

      debugPrint('Generated ${recommendations.length} enhanced job recommendations for user: $userId');
      
      // Send job notification for high-scoring matches
      await _sendJobNotificationsForHighMatches(userId, jobScores, specializations);
      
      return recommendations;
      
    } catch (e) {
      debugPrint('Error generating enhanced job recommendations: $e');
      return [];
    }
  }

  /// Calculate compatibility score between job and user profile
  /// Dutch Security Job Matching Algorithm:
  /// - 40% Certificaten (WPBR, BHV, EHBO, VCA)
  /// - 20% Locatie/Afstand (<50km Nederlandse postcodes)
  /// - 25% Ervaring level (beginnend, ervaren, expert) 
  /// - 15% Beschikbaarheid (schema conflict check)
  JobMatchScore _calculateEnhancedJobMatchScore({
    required SecurityJobData job,
    required List<Specialization> specializations,
    required List<String> userCertificates,
  }) {
    int totalScore = 0;
    int certificateScore = 0;
    int locationScore = 0;
    int experienceScore = 0;
    int availabilityScore = 0;
    bool isEligible = false;

    // 1. Certificate matching (40% weight) - Nederlandse beveiliging certificaten
    if (userCertificates.isNotEmpty && job.requiredCertificates.isNotEmpty) {
      final certificateMatch = CertificateMatchingService.matchCertificates(
        userCertificates,
        job.requiredCertificates,
      );
      
      certificateScore = (certificateMatch.matchScore * 0.40).round();
      isEligible = certificateMatch.isEligible;
      
      // Bonus voor Nederlandse security certificaten
      if (userCertificates.contains('WPBR')) certificateScore += 5;
      if (userCertificates.contains('BHV')) certificateScore += 3;
      if (userCertificates.contains('EHBO')) certificateScore += 3;
      if (userCertificates.contains('VCA')) certificateScore += 2;
      
    } else if (job.requiredCertificates.isEmpty) {
      certificateScore = 40; // Full score if no certificates required
      isEligible = true;
    }

    // 2. Location/Distance scoring (20% weight) - Nederlandse afstanden
    if (job.distance <= 5) {
      locationScore = 20; // Binnen 5km = perfecte score
    } else if (job.distance <= 15) {
      locationScore = 16; // Tot 15km = zeer goed
    } else if (job.distance <= 30) {
      locationScore = 12; // Tot 30km = goed
    } else if (job.distance <= 50) {
      locationScore = 8;  // Tot 50km = acceptabel
    } else {
      locationScore = 2;  // >50km = slecht maar nog wel mogelijk
    }

    // 3. Experience level scoring (25% weight) - Skill level uit specializations
    int bestExperienceScore = 0;
    bool hasSpecializationMatch = false;
    
    for (final specialization in specializations) {
      if (specialization.matchesJobCategory(job.jobType)) {
        hasSpecializationMatch = true;
        int expScore = 0;
        switch (specialization.skillLevel) {
          case SkillLevel.expert:
            expScore = 25; // Expert = volledige 25%
            break;
          case SkillLevel.ervaren:
            expScore = 20; // Ervaren = 20/25
            break;
          case SkillLevel.beginner:
            expScore = 12; // Beginner = 12/25
            break;
        }
        if (expScore > bestExperienceScore) {
          bestExperienceScore = expScore;
        }
      }
    }
    experienceScore = bestExperienceScore;

    // 4. Availability scoring (15% weight) - Schema conflict check
    // Voor nu assumeren we 100% beschikbaarheid - kan later uitgebreid worden
    // met echte schema integration
    availabilityScore = 15; // Default: volledig beschikbaar
    
    // TODO: Implement real availability check:
    // - Check against guard's existing schedules
    // - Check leave requests
    // - Check blackout dates
    // - Check preferred working hours

    // Calculate total score
    totalScore = certificateScore + locationScore + experienceScore + availabilityScore;

    // Apply bonuses and penalties
    if (hasSpecializationMatch && isEligible) {
      totalScore += 5; // Perfect match bonus
    }
    
    if (!hasSpecializationMatch) {
      totalScore = (totalScore * 0.7).round(); // Penalty for no specialization match
    }

    return JobMatchScore(
      totalScore: totalScore.clamp(0, 100),
      certificateScore: certificateScore,
      locationScore: locationScore,
      experienceScore: experienceScore,
      availabilityScore: availabilityScore,
      isEligible: isEligible,
    );
  }

  /// Convert specializations to preference format
  Map<String, dynamic> _convertSpecializationsToPreferences(List<Specialization> specializations) {
    final preferences = <String, dynamic>{};
    
    for (final spec in specializations) {
      preferences[spec.type.displayName] = {
        'skillLevel': spec.skillLevel.name,
        'matchingScore': spec.skillLevel.matchingScore,
        'isActive': spec.isActive,
        'addedAt': spec.addedAt.toIso8601String(),
      };
    }
    
    return preferences;
  }

  /// Get skill level distribution for analytics
  Map<String, int> _getSkillLevelDistribution(List<Specialization> specializations) {
    final distribution = <String, int>{
      'beginner': 0,
      'ervaren': 0,
      'expert': 0,
    };
    
    for (final spec in specializations) {
      distribution[spec.skillLevel.name] = (distribution[spec.skillLevel.name] ?? 0) + 1;
    }
    
    return distribution;
  }

  /// Check if recommendations cache is valid
  bool _isRecommendationsCacheValid(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheValidDuration;
  }

  /// Clear user recommendations cache
  void _clearUserRecommendationsCache(String userId) {
    _recommendationsCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Get all available jobs using existing JobDataService
  Future<List<SecurityJobData>> _getAllAvailableJobs() async {
    try {
      debugPrint('Getting all available jobs for matching...');
      
      // Use existing JobDataService with expanded limit for matching
      final jobs = await JobDataService.getAvailableJobs(
        limit: 200, // Higher limit for better matching results
      );
      
      debugPrint('Retrieved ${jobs.length} jobs for matching analysis');
      return jobs;
      
    } catch (e) {
      debugPrint('Error getting available jobs: $e');
      return [];
    }
  }

  /// Clear all caches
  void clearAllCaches() {
    _userPreferencesCache.clear();
    _recommendationsCache.clear();
    _cacheTimestamps.clear();
    debugPrint('Job matching service caches cleared');
  }

  /// Send job notifications for high-scoring matches
  Future<void> _sendJobNotificationsForHighMatches(
    String userId,
    Map<SecurityJobData, JobMatchScore> jobScores,
    List<Specialization> specializations,
  ) async {
    try {
      // Send notifications for jobs with score >= 70 (high match)
      final highScoringJobs = jobScores.entries
          .where((entry) => entry.value.totalScore >= 70)
          .take(3) // Limit to top 3 to avoid spam
          .toList();

      for (final jobEntry in highScoringJobs) {
        final job = jobEntry.key;
        final score = jobEntry.value;
        
        // Filter specializations that match this job
        final matchingSpecs = specializations
            .where((spec) => spec.matchesJobCategory(job.jobType))
            .toList();

        if (matchingSpecs.isNotEmpty) {
          await _notificationService.sendJobAlert(
            jobData: job,
            matchingSpecializations: matchingSpecs,
            customMessage: 'Match score: ${score.totalScore}% - Perfecte match voor jouw specialisaties!',
          );

          debugPrint('Sent job notification for ${job.jobTitle} to user $userId (score: ${score.totalScore})');
        }
      }

    } catch (e) {
      debugPrint('Error sending job notifications: $e');
    }
  }

  /// Get service statistics
  Map<String, dynamic> getServiceStats() {
    return {
      'userPreferencesCacheSize': _userPreferencesCache.length,
      'recommendationsCacheSize': _recommendationsCache.length,
      'cacheTimestampsSize': _cacheTimestamps.length,
    };
  }
}

/// Job match score breakdown - Nederlandse beveiliging matching algoritme
/// 40% Certificaten + 20% Locatie + 25% Ervaring + 15% Beschikbaarheid = 100%
class JobMatchScore {
  final int totalScore;
  final int certificateScore;    // 40% - Nederlandse security certificaten
  final int locationScore;       // 20% - Afstand in Nederlandse postcodes
  final int experienceScore;     // 25% - Skill level (beginnend/ervaren/expert)
  final int availabilityScore;   // 15% - Beschikbaarheid / schema conflicts
  final bool isEligible;         // Heeft alle vereiste certificaten

  const JobMatchScore({
    required this.totalScore,
    required this.certificateScore,
    required this.locationScore,
    required this.experienceScore,
    required this.availabilityScore,
    required this.isEligible,
  });

  /// Get score breakdown as map
  Map<String, dynamic> toMap() {
    return {
      'totalScore': totalScore,
      'certificateScore': certificateScore,
      'locationScore': locationScore,
      'experienceScore': experienceScore,
      'availabilityScore': availabilityScore,
      'isEligible': isEligible,
      'breakdown': {
        'certificaten': '$certificateScore/40 (${(certificateScore/40*100).toInt()}%)',
        'locatie': '$locationScore/20 (${(locationScore/20*100).toInt()}%)',
        'ervaring': '$experienceScore/25 (${(experienceScore/25*100).toInt()}%)',
        'beschikbaarheid': '$availabilityScore/15 (${(availabilityScore/15*100).toInt()}%)',
      },
    };
  }

  @override
  String toString() => 'JobMatchScore(total: $totalScore, eligible: $isEligible)';
}

