import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/security_job_data.dart';
import '../../models/location/postcode_models.dart';
import 'postcode_service.dart';

/// Enhanced job location service integrating PostcodeService with job search
/// 
/// Provides location-based job filtering, intelligent matching, and travel
/// optimization for the Dutch security job marketplace.
class EnhancedJobLocationService {
  EnhancedJobLocationService._();
  
  static final EnhancedJobLocationService _instance = EnhancedJobLocationService._();
  static EnhancedJobLocationService get instance => _instance;

  // =========================================================================
  // JOB LOCATION ENHANCEMENT
  // =========================================================================

  /// Enhance job data with accurate location information
  static Future<List<SecurityJobData>> enhanceJobsWithLocationData(
    List<SecurityJobData> jobs,
  ) async {
    final enhancedJobs = <SecurityJobData>[];

    for (final job in jobs) {
      try {
        // Extract postcode from job location
        final postcode = _extractPostcodeFromLocation(job.location);
        
        if (postcode != null && PostcodeService.validateDutchPostcode(postcode)) {
          // Get coordinates for the job
          final coordinate = await PostcodeService.getCoordinates(postcode);
          
          if (coordinate != null) {
            // Create enhanced job with better location info
            final enhancedJob = SecurityJobData(
              jobId: job.jobId,
              jobTitle: job.jobTitle,
              companyName: job.companyName,
              location: _formatLocationWithCity(job.location, coordinate),
              hourlyRate: job.hourlyRate,
              distance: job.distance, // Will be updated in filtering
              companyRating: job.companyRating,
              applicantCount: job.applicantCount,
              duration: job.duration,
              jobType: job.jobType,
              description: job.description,
              companyLogo: job.companyLogo,
              startDate: job.startDate,
              endDate: job.endDate,
              requiredCertificates: job.requiredCertificates,
            );
            
            enhancedJobs.add(enhancedJob);
          } else {
            // Keep original job if location enhancement fails
            enhancedJobs.add(job);
          }
        } else {
          // Keep original job if no valid postcode found
          enhancedJobs.add(job);
        }
      } catch (e) {
        debugPrint('EnhancedJobLocationService: Error enhancing job ${job.jobId}: $e');
        enhancedJobs.add(job); // Keep original on error
      }
    }

    return enhancedJobs;
  }

  /// Filter jobs by distance from user location with accurate travel data
  static Future<List<JobLocationMatch>> findJobsWithinDistance({
    required String userPostcode,
    required List<SecurityJobData> jobs,
    required double maxDistanceKm,
    TransportMode transportMode = TransportMode.driving,
    bool includePublicTransport = true,
    bool sortByDistance = true,
  }) async {
    if (!PostcodeService.validateDutchPostcode(userPostcode)) {
      throw PostcodeException('Ongeldig gebruiker postcode', null, userPostcode);
    }

    final matches = <JobLocationMatch>[];

    // Process jobs in batches for better performance
    const batchSize = 10;
    final batches = <List<SecurityJobData>>[];
    
    for (int i = 0; i < jobs.length; i += batchSize) {
      final end = (i + batchSize < jobs.length) ? i + batchSize : jobs.length;
      batches.add(jobs.sublist(i, end));
    }

    for (final batch in batches) {
      await Future.wait(batch.map((job) async {
        try {
          final jobPostcode = _extractPostcodeFromLocation(job.location);
          
          if (jobPostcode == null || !PostcodeService.validateDutchPostcode(jobPostcode)) {
            return; // Skip jobs without valid postcodes
          }

          // Get comprehensive travel details
          final distanceResult = await PostcodeService.calculateDistanceWithModes(
            userPostcode,
            jobPostcode,
            modes: includePublicTransport 
              ? [TransportMode.driving, TransportMode.transit, TransportMode.bicycling]
              : [transportMode],
          );

          if (distanceResult != null) {
            // Check if job is within distance for any transport mode
            final relevantTravel = distanceResult.travelOptions[transportMode] 
                                ?? distanceResult.fastest;
            
            if (relevantTravel != null && relevantTravel.distanceKm <= maxDistanceKm) {
              matches.add(JobLocationMatch(
                job: job,
                userPostcode: userPostcode,
                jobPostcode: jobPostcode,
                distanceResult: distanceResult,
                primaryTravelMode: transportMode,
                isWithinDistance: true,
                travelScore: _calculateTravelScore(relevantTravel, maxDistanceKm),
              ));
            }
          }
        } catch (e) {
          debugPrint('EnhancedJobLocationService: Error processing job ${job.jobId}: $e');
        }
      }));

      // Small delay between batches to avoid overwhelming the API
      if (batches.indexOf(batch) < batches.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Sort by distance if requested
    if (sortByDistance) {
      matches.sort((a, b) {
        final distanceA = a.distanceResult.travelOptions[transportMode]?.distanceKm 
                       ?? a.distanceResult.fastest?.distanceKm ?? double.infinity;
        final distanceB = b.distanceResult.travelOptions[transportMode]?.distanceKm 
                       ?? b.distanceResult.fastest?.distanceKm ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });
    }

    return matches;
  }

  /// Get optimal travel recommendations for a job
  static Future<JobTravelRecommendation?> getTravelRecommendation({
    required String userPostcode,
    required SecurityJobData job,
    DateTime? arrivalTime,
  }) async {
    final jobPostcode = _extractPostcodeFromLocation(job.location);
    
    if (jobPostcode == null || !PostcodeService.validateDutchPostcode(jobPostcode)) {
      return null;
    }

    try {
      final distanceResult = await PostcodeService.calculateDistanceWithModes(
        userPostcode,
        jobPostcode,
        modes: [TransportMode.driving, TransportMode.transit, TransportMode.bicycling],
      );

      if (distanceResult == null) return null;

      // Analyze all travel options
      final recommendations = <String>[];
      TravelDetails? bestOption;
      double bestScore = 0;

      for (final entry in distanceResult.travelOptions.entries) {
        final mode = entry.key;
        final travel = entry.value;
        
        // Score based on duration, cost, and convenience
        double score = _scoreTravelOption(travel, mode, arrivalTime);
        
        if (score > bestScore) {
          bestScore = score;
          bestOption = travel;
        }

        // Generate specific recommendations
        recommendations.addAll(_generateTravelRecommendations(travel, mode));
      }

      // Add context-specific advice
      if (job.startDate != null) {
        final hour = job.startDate!.hour;
        if (hour >= 7 && hour <= 9) {
          recommendations.add('Let op: dit is tijdens de spits. Plan extra reistijd in.');
        }
        if (hour >= 17 && hour <= 19) {
          recommendations.add('Avondspits: overweeg OV of fiets voor snellere reis.');
        }
      }

      return JobTravelRecommendation(
        job: job,
        userPostcode: userPostcode,
        jobPostcode: jobPostcode,
        distanceResult: distanceResult,
        bestTravelOption: bestOption,
        recommendations: recommendations,
        estimatedCost: _estimateTravelCost(bestOption),
        carbonFootprint: _estimateCarbonFootprint(bestOption),
      );

    } catch (e) {
      debugPrint('EnhancedJobLocationService: Error getting travel recommendation: $e');
      return null;
    }
  }

  /// Find jobs with similar commute patterns
  static Future<List<JobLocationMatch>> findJobsWithSimilarCommutes({
    required String userPostcode,
    required List<SecurityJobData> referenceJobs,
    required List<SecurityJobData> allJobs,
    double similarityThreshold = 0.8,
  }) async {
    final similarJobs = <JobLocationMatch>[];

    // Calculate reference commute patterns
    final referencePatterns = <CommutePattern>[];
    
    for (final refJob in referenceJobs) {
      final pattern = await _analyzeCommutePattern(userPostcode, refJob);
      if (pattern != null) {
        referencePatterns.add(pattern);
      }
    }

    if (referencePatterns.isEmpty) return similarJobs;

    // Find jobs with similar patterns
    for (final job in allJobs) {
      if (referenceJobs.any((ref) => ref.jobId == job.jobId)) {
        continue; // Skip reference jobs
      }

      final jobPattern = await _analyzeCommutePattern(userPostcode, job);
      if (jobPattern == null) continue;

      // Calculate similarity score
      double maxSimilarity = 0;
      for (final refPattern in referencePatterns) {
        final similarity = _calculateCommuteSimilarity(jobPattern, refPattern);
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
        }
      }

      if (maxSimilarity >= similarityThreshold) {
        final jobPostcode = _extractPostcodeFromLocation(job.location)!;
        final distanceResult = await PostcodeService.calculateDistanceWithModes(
          userPostcode,
          jobPostcode,
        );

        if (distanceResult != null) {
          similarJobs.add(JobLocationMatch(
            job: job,
            userPostcode: userPostcode,
            jobPostcode: jobPostcode,
            distanceResult: distanceResult,
            primaryTravelMode: TransportMode.driving,
            isWithinDistance: true,
            travelScore: maxSimilarity,
            similarityScore: maxSimilarity,
          ));
        }
      }
    }

    // Sort by similarity score
    similarJobs.sort((a, b) => b.similarityScore!.compareTo(a.similarityScore!));

    return similarJobs;
  }

  // =========================================================================
  // LOCATION-BASED JOB RECOMMENDATIONS
  // =========================================================================

  /// Generate location-based job recommendations
  static Future<List<JobLocationRecommendation>> generateLocationRecommendations({
    required String userPostcode,
    required List<SecurityJobData> availableJobs,
    required List<String> userCertificates,
    double maxCommuteDistance = 50.0,
    Duration? maxCommuteTime,
    TransportMode preferredTransport = TransportMode.driving,
  }) async {
    final recommendations = <JobLocationRecommendation>[];

    // First, filter jobs by location
    final locationMatches = await findJobsWithinDistance(
      userPostcode: userPostcode,
      jobs: availableJobs,
      maxDistanceKm: maxCommuteDistance,
      transportMode: preferredTransport,
    );

    for (final match in locationMatches.take(50)) { // Limit to top 50 for performance
      try {
        final travelRecommendation = await getTravelRecommendation(
          userPostcode: userPostcode,
          job: match.job,
        );

        if (travelRecommendation?.bestTravelOption != null) {
          // Check commute time constraint
          if (maxCommuteTime != null && 
              travelRecommendation!.bestTravelOption!.duration > maxCommuteTime) {
            continue;
          }

          // Calculate overall recommendation score
          final locationScore = _calculateLocationScore(
            match.distanceResult.travelOptions[preferredTransport]!,
            maxCommuteDistance,
            maxCommuteTime,
          );

          final certificationScore = _calculateCertificationMatch(
            match.job.requiredCertificates,
            userCertificates,
          );

          final overallScore = (locationScore * 0.4) + (certificationScore * 0.6);

          recommendations.add(JobLocationRecommendation(
            job: match.job,
            locationMatch: match,
            travelRecommendation: travelRecommendation!,
            locationScore: locationScore,
            certificationScore: certificationScore,
            overallScore: overallScore,
            reasons: _generateRecommendationReasons(
              match, 
              travelRecommendation, 
              locationScore, 
              certificationScore,
            ),
          ));
        }
      } catch (e) {
        debugPrint('EnhancedJobLocationService: Error generating recommendation for ${match.job.jobId}: $e');
      }
    }

    // Sort by overall score
    recommendations.sort((a, b) => b.overallScore.compareTo(a.overallScore));

    return recommendations.take(25).toList(); // Return top 25 recommendations
  }

  // =========================================================================
  // PRIVATE HELPER METHODS
  // =========================================================================

  /// Extract postcode from location string
  static String? _extractPostcodeFromLocation(String location) {
    final regex = RegExp(r'(\d{4}\s?[A-Z]{2})');
    final match = regex.firstMatch(location);
    return match?.group(1)?.replaceAll(' ', '').toUpperCase();
  }

  /// Format location string with city information
  static String _formatLocationWithCity(String originalLocation, PostcodeCoordinate coordinate) {
    if (coordinate.city != null && !originalLocation.contains(coordinate.city!)) {
      return '$originalLocation, ${coordinate.city}';
    }
    return originalLocation;
  }

  /// Calculate travel score (higher is better)
  static double _calculateTravelScore(TravelDetails travel, double maxDistance) {
    final distanceScore = ((maxDistance - travel.distanceKm) / maxDistance).clamp(0.0, 1.0);
    final timeScore = travel.duration.inMinutes < 30 ? 1.0 
                    : travel.duration.inMinutes < 60 ? 0.7
                    : travel.duration.inMinutes < 90 ? 0.4
                    : 0.1;
    
    return (distanceScore * 0.6) + (timeScore * 0.4);
  }

  /// Score travel option based on multiple factors
  static double _scoreTravelOption(
    TravelDetails travel, 
    TransportMode mode, 
    DateTime? arrivalTime,
  ) {
    double score = 50.0;
    
    // Distance factor (shorter is better)
    if (travel.distanceKm < 10) {
      score += 20;
    } else if (travel.distanceKm < 25) score += 10;
    else if (travel.distanceKm > 50) score -= 10;
    
    // Duration factor (faster is better)
    if (travel.duration.inMinutes < 30) {
      score += 25;
    } else if (travel.duration.inMinutes < 60) score += 10;
    else if (travel.duration.inMinutes > 90) score -= 15;
    
    // Mode-specific bonuses
    switch (mode) {
      case TransportMode.bicycling:
        score += 15; // Environmental and health benefits
        if (travel.distanceKm < 15) score += 10; // Ideal cycling distance
        break;
      case TransportMode.transit:
        score += 10; // Environmental benefits
        if (travel.duration.inMinutes < travel.distanceKm * 2) score += 5; // Good public transport
        break;
      case TransportMode.driving:
        if (travel.duration.inMinutes < travel.distanceKm * 1.5) score += 5; // Good road connections
        break;
      case TransportMode.walking:
        if (travel.distanceKm < 5) {
          score += 20; // Perfect for short distances
        } else {
          score -= 20; // Too far for walking
        }
        break;
    }
    
    return score.clamp(0.0, 100.0);
  }

  /// Generate travel recommendations based on travel details and mode
  static List<String> _generateTravelRecommendations(TravelDetails travel, TransportMode mode) {
    final recommendations = <String>[];
    
    switch (mode) {
      case TransportMode.driving:
        if (travel.duration.inMinutes > 60) {
          recommendations.add('Lange autorit: overweeg carpooling of flexibele werktijden.');
        }
        if (travel.distanceKm < 5) {
          recommendations.add('Korte afstand: fiets of loop voor duurzamer alternatief.');
        }
        recommendations.add('Parkeerkosten: ca. €5-15 per dag in stadscentra.');
        break;
        
      case TransportMode.transit:
        recommendations.add('OV-chipkaart vereist. Kosten: ca. €${(travel.distanceKm * 0.20).toStringAsFixed(2)}.');
        if (travel.duration.inMinutes > travel.distanceKm * 3) {
          recommendations.add('OV duurt lang voor deze afstand. Overweeg auto of fiets.');
        } else {
          recommendations.add('Goede OV-verbinding beschikbaar.');
        }
        break;
        
      case TransportMode.bicycling:
        if (travel.distanceKm > 20) {
          recommendations.add('Lange fietsrit: overweeg e-bike voor comfort.');
        } else {
          recommendations.add('Ideale fietsafstand. Duurzaam en gezond!');
        }
        recommendations.add('Controleer fietsroute op veiligheid en fietspaden.');
        break;
        
      case TransportMode.walking:
        if (travel.distanceKm > 5) {
          recommendations.add('Te ver om te lopen. Kies ander vervoermiddel.');
        } else {
          recommendations.add('Lopende bereikbaar. Perfecte work-life balance!');
        }
        break;
    }
    
    return recommendations;
  }

  /// Analyze commute pattern for job matching
  static Future<CommutePattern?> _analyzeCommutePattern(
    String userPostcode, 
    SecurityJobData job,
  ) async {
    final jobPostcode = _extractPostcodeFromLocation(job.location);
    if (jobPostcode == null) return null;

    try {
      final distanceResult = await PostcodeService.calculateDistanceWithModes(
        userPostcode,
        jobPostcode,
      );

      if (distanceResult == null) return null;

      return CommutePattern(
        distanceKm: distanceResult.driving?.distanceKm ?? 0,
        drivingTime: distanceResult.driving?.duration ?? Duration.zero,
        transitTime: distanceResult.transit?.duration,
        bicyclingTime: distanceResult.bicycling?.duration,
        direction: _calculateDirection(userPostcode, jobPostcode),
        jobType: job.jobType,
        workingHours: job.duration,
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate similarity between commute patterns
  static double _calculateCommuteSimilarity(CommutePattern a, CommutePattern b) {
    double similarity = 0.0;

    // Distance similarity (30%)
    final maxDistance = [a.distanceKm, b.distanceKm].reduce((a, b) => a > b ? a : b);
    if (maxDistance > 0) {
      final distanceDiff = (a.distanceKm - b.distanceKm).abs();
      similarity += (1.0 - (distanceDiff / maxDistance)) * 0.3;
    }

    // Direction similarity (25%)
    final directionDiff = (a.direction - b.direction).abs();
    final normalizedDirectionDiff = directionDiff > 180 ? 360 - directionDiff : directionDiff;
    similarity += (1.0 - (normalizedDirectionDiff / 180)) * 0.25;

    // Time similarity (25%)
    final maxTime = [a.drivingTime.inMinutes, b.drivingTime.inMinutes].reduce((a, b) => a > b ? a : b);
    if (maxTime > 0) {
      final timeDiff = (a.drivingTime.inMinutes - b.drivingTime.inMinutes).abs();
      similarity += (1.0 - (timeDiff / maxTime)) * 0.25;
    }

    // Job type similarity (20%)
    if (a.jobType == b.jobType) {
      similarity += 0.2;
    }

    return similarity.clamp(0.0, 1.0);
  }

  /// Calculate direction between postcodes (in degrees)
  static double _calculateDirection(String fromPostcode, String toPostcode) {
    // This is a simplified calculation - in reality you'd use coordinates
    final fromNumber = int.parse(fromPostcode.substring(0, 4));
    final toNumber = int.parse(toPostcode.substring(0, 4));
    
    // Rough direction based on postcode ranges
    return ((toNumber - fromNumber) % 360).toDouble();
  }

  /// Calculate location score for recommendations
  static double _calculateLocationScore(
    TravelDetails travel, 
    double maxDistance, 
    Duration? maxTime,
  ) {
    double score = 100.0;

    // Distance penalty
    final distanceRatio = travel.distanceKm / maxDistance;
    score -= distanceRatio * 30; // Up to 30 points penalty

    // Time penalty
    if (maxTime != null) {
      final timeRatio = travel.duration.inMinutes / maxTime.inMinutes;
      score -= timeRatio * 25; // Up to 25 points penalty
    }

    // Bonus for very short commutes
    if (travel.distanceKm < 10) score += 15;
    if (travel.duration.inMinutes < 20) score += 10;

    return score.clamp(0.0, 100.0);
  }

  /// Calculate certification match score
  static double _calculateCertificationMatch(
    List<String> requiredCertificates,
    List<String> userCertificates,
  ) {
    if (requiredCertificates.isEmpty) return 100.0;

    int matchCount = 0;
    for (final required in requiredCertificates) {
      if (userCertificates.any((cert) => 
          cert.toLowerCase().contains(required.toLowerCase()) ||
          required.toLowerCase().contains(cert.toLowerCase()))) {
        matchCount++;
      }
    }

    return (matchCount / requiredCertificates.length) * 100.0;
  }

  /// Generate recommendation reasons
  static List<String> _generateRecommendationReasons(
    JobLocationMatch match,
    JobTravelRecommendation travelRec,
    double locationScore,
    double certificationScore,
  ) {
    final reasons = <String>[];

    if (locationScore > 80) {
      reasons.add('Uitstekende locatie (${travelRec.bestTravelOption!.formattedDistance}, ${travelRec.bestTravelOption!.formattedDuration})');
    } else if (locationScore > 60) {
      reasons.add('Goede bereikbaarheid (${travelRec.bestTravelOption!.formattedDistance})');
    }

    if (certificationScore > 90) {
      reasons.add('Perfect certificaat match');
    } else if (certificationScore > 70) {
      reasons.add('Goede certificaat match');
    }

    if (match.job.hourlyRate > 25.0) {
      reasons.add('Aantrekkelijk salaris (€${match.job.hourlyRate.toStringAsFixed(2)}/uur)');
    }

    if (match.job.companyRating > 4.5) {
      reasons.add('Hoogwaardige werkgever (${match.job.companyRating} sterren)');
    }

    return reasons;
  }

  /// Estimate travel cost
  static double? _estimateTravelCost(TravelDetails? travel) {
    if (travel == null) return null;

    switch (travel.mode) {
      case TransportMode.driving:
        // €0.19 per km (2024 rate) + parking
        return (travel.distanceKm * 0.19) + 8.0; // Includes parking estimate
      case TransportMode.transit:
        // Rough OV estimate
        return travel.distanceKm * 0.20;
      case TransportMode.bicycling:
        return 0.0; // Free!
      case TransportMode.walking:
        return 0.0; // Free!
    }
  }

  /// Estimate carbon footprint (kg CO2)
  static double? _estimateCarbonFootprint(TravelDetails? travel) {
    if (travel == null) return null;

    switch (travel.mode) {
      case TransportMode.driving:
        return travel.distanceKm * 0.12; // kg CO2 per km
      case TransportMode.transit:
        return travel.distanceKm * 0.05; // kg CO2 per km (public transport)
      case TransportMode.bicycling:
        return 0.0;
      case TransportMode.walking:
        return 0.0;
    }
  }
}

// =========================================================================
// DATA MODELS
// =========================================================================

/// Represents a job matched with location data
class JobLocationMatch {
  final SecurityJobData job;
  final String userPostcode;
  final String jobPostcode;
  final DistanceCalculationResult distanceResult;
  final TransportMode primaryTravelMode;
  final bool isWithinDistance;
  final double travelScore;
  final double? similarityScore;

  const JobLocationMatch({
    required this.job,
    required this.userPostcode,
    required this.jobPostcode,
    required this.distanceResult,
    required this.primaryTravelMode,
    required this.isWithinDistance,
    required this.travelScore,
    this.similarityScore,
  });
}

/// Travel recommendation for a specific job
class JobTravelRecommendation {
  final SecurityJobData job;
  final String userPostcode;
  final String jobPostcode;
  final DistanceCalculationResult distanceResult;
  final TravelDetails? bestTravelOption;
  final List<String> recommendations;
  final double? estimatedCost;
  final double? carbonFootprint;

  const JobTravelRecommendation({
    required this.job,
    required this.userPostcode,
    required this.jobPostcode,
    required this.distanceResult,
    this.bestTravelOption,
    required this.recommendations,
    this.estimatedCost,
    this.carbonFootprint,
  });
}

/// Comprehensive job recommendation with location analysis
class JobLocationRecommendation {
  final SecurityJobData job;
  final JobLocationMatch locationMatch;
  final JobTravelRecommendation travelRecommendation;
  final double locationScore;
  final double certificationScore;
  final double overallScore;
  final List<String> reasons;

  const JobLocationRecommendation({
    required this.job,
    required this.locationMatch,
    required this.travelRecommendation,
    required this.locationScore,
    required this.certificationScore,
    required this.overallScore,
    required this.reasons,
  });
}

/// Commute pattern analysis
class CommutePattern {
  final double distanceKm;
  final Duration drivingTime;
  final Duration? transitTime;
  final Duration? bicyclingTime;
  final double direction; // In degrees
  final String jobType;
  final int workingHours;

  const CommutePattern({
    required this.distanceKm,
    required this.drivingTime,
    this.transitTime,
    this.bicyclingTime,
    required this.direction,
    required this.jobType,
    required this.workingHours,
  });
}