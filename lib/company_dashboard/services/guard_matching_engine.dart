import 'dart:math';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';
import 'package:securyflex_app/company_dashboard/models/business_intelligence_data.dart';

/// Guard Matching Engine Service
/// 
/// Provides AI-powered guard matching with:
/// - Skill and certification matching
/// - Geographic optimization based on distance
/// - Performance-based recommendations
/// - Availability and scheduling analysis
/// - Cost optimization suggestions
/// - Diversity and inclusion insights
/// 
/// Features:
/// - Match percentage calculation with detailed reasoning
/// - Real-time availability checking
/// - Performance history analysis
/// - Travel time optimization
/// - Client preference matching
/// - Emergency replacement suggestions
class GuardMatchingEngine {
  static final GuardMatchingEngine _instance = GuardMatchingEngine._internal();
  factory GuardMatchingEngine() => _instance;
  GuardMatchingEngine._internal();

  // Cache for guard data and matching results
  final Map<String, List<GuardMatchSuggestion>> _matchingCache = {};
  final Map<String, List<GuardPerformanceData>> _guardsCache = {};
  DateTime? _lastCacheUpdate;
  final Duration _cacheValidDuration = const Duration(minutes: 30);

  /// Get AI-powered guard suggestions for a job
  Future<List<GuardMatchSuggestion>> getGuardSuggestions({
    required JobType jobType,
    required String location,
    required String postalCode,
    required List<String> requiredSkills,
    required List<String> requiredCertificates,
    required int minimumExperience,
    required DateTime startDate,
    required DateTime endDate,
    required double maxHourlyRate,
    String? companyId,
    int maxSuggestions = 10,
  }) async {
    // Create cache key
    final cacheKey = _createCacheKey(
      jobType, location, requiredSkills, requiredCertificates,
      minimumExperience, startDate, endDate, maxHourlyRate,
    );

    // Check cache first
    if (_matchingCache.containsKey(cacheKey) &&
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).compareTo(_cacheValidDuration) < 0) {
      return _matchingCache[cacheKey]!.take(maxSuggestions).toList();
    }

    // Simulate AI processing time
    await Future.delayed(const Duration(milliseconds: 1200));

    // Get available guards
    final availableGuards = await _getAvailableGuards(startDate, endDate);
    
    // Calculate matches for each guard
    final matches = <GuardMatchSuggestion>[];
    
    for (final guard in availableGuards) {
      final matchData = await _calculateGuardMatch(
        guard: guard,
        jobType: jobType,
        location: location,
        postalCode: postalCode,
        requiredSkills: requiredSkills,
        requiredCertificates: requiredCertificates,
        minimumExperience: minimumExperience,
        startDate: startDate,
        endDate: endDate,
        maxHourlyRate: maxHourlyRate,
        companyId: companyId,
      );
      
      if (matchData != null && matchData.matchPercentage >= 30.0) {
        matches.add(matchData);
      }
    }

    // Sort by match percentage (descending) and rating
    matches.sort((a, b) {
      final matchComparison = b.matchPercentage.compareTo(a.matchPercentage);
      if (matchComparison != 0) return matchComparison;
      return b.rating.compareTo(a.rating);
    });

    // Update cache
    _matchingCache[cacheKey] = matches;
    _lastCacheUpdate = DateTime.now();

    return matches.take(maxSuggestions).toList();
  }

  /// Calculate match percentage and details for a specific guard
  Future<GuardMatchSuggestion?> _calculateGuardMatch({
    required GuardPerformanceData guard,
    required JobType jobType,
    required String location,
    required String postalCode,
    required List<String> requiredSkills,
    required List<String> requiredCertificates,
    required int minimumExperience,
    required DateTime startDate,
    required DateTime endDate,
    required double maxHourlyRate,
    String? companyId,
  }) async {
    final matchReasons = <MatchReason>[];
    double totalMatchScore = 0.0;
    double maxPossibleScore = 0.0;

    // 1. Skills matching (30% weight)
    final skillsMatch = _calculateSkillsMatch(guard.specializations, requiredSkills);
    totalMatchScore += skillsMatch.score * 0.30;
    maxPossibleScore += 0.30;
    if (skillsMatch.score > 0) {
      matchReasons.add(MatchReason(
        reason: skillsMatch.reason,
        weight: 0.30,
        type: MatchReasonType.skill,
      ));
    }

    // 2. Experience matching (20% weight)
    final experienceMatch = _calculateExperienceMatch(guard.totalJobsCompleted, minimumExperience);
    totalMatchScore += experienceMatch.score * 0.20;
    maxPossibleScore += 0.20;
    if (experienceMatch.score > 0) {
      matchReasons.add(MatchReason(
        reason: experienceMatch.reason,
        weight: 0.20,
        type: MatchReasonType.experience,
      ));
    }

    // 3. Location/Distance matching (15% weight)
    final distanceKm = await _calculateDistance(guard.guardId, location, postalCode);
    final locationMatch = _calculateLocationMatch(distanceKm);
    totalMatchScore += locationMatch.score * 0.15;
    maxPossibleScore += 0.15;
    if (locationMatch.score > 0) {
      matchReasons.add(MatchReason(
        reason: locationMatch.reason,
        weight: 0.15,
        type: MatchReasonType.location,
      ));
    }

    // 4. Rating/Performance matching (15% weight)
    final ratingMatch = _calculateRatingMatch(guard.rating);
    totalMatchScore += ratingMatch.score * 0.15;
    maxPossibleScore += 0.15;
    if (ratingMatch.score > 0) {
      matchReasons.add(MatchReason(
        reason: ratingMatch.reason,
        weight: 0.15,
        type: MatchReasonType.rating,
      ));
    }

    // 5. Availability matching (10% weight)
    final availabilityMatch = _calculateAvailabilityMatch(guard.availabilityStatus);
    totalMatchScore += availabilityMatch.score * 0.10;
    maxPossibleScore += 0.10;
    if (availabilityMatch.score > 0) {
      matchReasons.add(MatchReason(
        reason: availabilityMatch.reason,
        weight: 0.10,
        type: MatchReasonType.availability,
      ));
    }

    // 6. Cost matching (10% weight)
    final guardRate = _estimateGuardRate(guard);
    final costMatch = _calculateCostMatch(guardRate, maxHourlyRate);
    totalMatchScore += costMatch.score * 0.10;
    maxPossibleScore += 0.10;
    if (costMatch.score > 0) {
      matchReasons.add(MatchReason(
        reason: costMatch.reason,
        weight: 0.10,
        type: MatchReasonType.cost,
      ));
    }

    // Calculate final match percentage
    final matchPercentage = maxPossibleScore > 0 ? (totalMatchScore / maxPossibleScore) * 100 : 0.0;

    // Only return matches above minimum threshold
    if (matchPercentage < 30.0) return null;

    // Get matching skills and certificates
    final matchingSkills = requiredSkills
        .where((skill) => guard.specializations.contains(skill))
        .toList();
    
    // Simulate certificate matching (in real app, this would come from guard profile)
    final matchingCertificates = requiredCertificates
        .where((cert) => _guardHasCertificate(guard.guardId, cert))
        .toList();

    return GuardMatchSuggestion(
      guardId: guard.guardId,
      guardName: guard.guardName,
      matchPercentage: double.parse(matchPercentage.toStringAsFixed(1)),
      rating: guard.rating,
      completedJobs: guard.totalJobsCompleted,
      distanceKm: distanceKm,
      matchingSkills: matchingSkills,
      matchingCertificates: matchingCertificates,
      availability: guard.availabilityStatus,
      hourlyRate: guardRate,
      profileImageUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=${guard.guardId}',
      matchReasons: matchReasons,
    );
  }

  /// Get available guards for the specified time period
  Future<List<GuardPerformanceData>> _getAvailableGuards(DateTime startDate, DateTime endDate) async {
    // Check cache first
    final cacheKey = 'guards_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}';
    if (_guardsCache.containsKey(cacheKey) &&
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).compareTo(_cacheValidDuration) < 0) {
      return _guardsCache[cacheKey]!;
    }

    // Simulate fetching guards from database/API
    await Future.delayed(const Duration(milliseconds: 400));

    // Generate mock guard data (in real app, this would come from database)
    final guards = _generateMockGuards();
    
    // Filter for availability (simplified - in real app, check actual schedules)
    final availableGuards = guards.where((guard) => 
      guard.availabilityStatus == GuardAvailabilityStatus.available ||
      guard.availabilityStatus == GuardAvailabilityStatus.onDuty
    ).toList();

    // Update cache
    _guardsCache[cacheKey] = availableGuards;

    return availableGuards;
  }

  /// Generate mock guard data for demonstration
  List<GuardPerformanceData> _generateMockGuards() {
    final random = Random();
    final guards = <GuardPerformanceData>[];
    
    final guardNames = [
      'Jan van der Berg', 'Maria Janssen', 'Ahmed Hassan', 'Lisa de Vries',
      'Carlos Rodriguez', 'Emma Bakker', 'Mohammed Ali', 'Sophie Mulder',
      'David Johnson', 'Anna Visser', 'Omar Benali', 'Julia Smit',
      'Roberto Silva', 'Fatima El Amrani', 'Tom Hendriks', 'Yasmin Özkan',
    ];

    final specializations = [
      'Objectbeveiliging', 'Evenementbeveiliging', 'Persoonbeveiliging',
      'Mobiele surveillance', 'Receptiebeveiliging', 'Transportbeveiliging',
      'Crowd control', 'VIP beveiliging', 'Retail beveiliging', 'Horeca beveiliging',
    ];

    final availabilityStatuses = [
      GuardAvailabilityStatus.available,
      GuardAvailabilityStatus.available,
      GuardAvailabilityStatus.available,
      GuardAvailabilityStatus.onDuty,
      GuardAvailabilityStatus.busy,
    ];

    for (int i = 0; i < guardNames.length; i++) {
      final rating = 3.0 + random.nextDouble() * 2.0; // 3.0 to 5.0
      final totalJobs = 10 + random.nextInt(200); // 10 to 210
      final jobsThisMonth = random.nextInt(15); // 0 to 15
      final reliability = 70.0 + random.nextDouble() * 30.0; // 70 to 100

      guards.add(GuardPerformanceData(
        guardId: 'GUARD_${i.toString().padLeft(3, '0')}',
        guardName: guardNames[i],
        rating: double.parse(rating.toStringAsFixed(1)),
        totalJobsCompleted: totalJobs,
        jobsThisMonth: jobsThisMonth,
        reliabilityScore: double.parse(reliability.toStringAsFixed(1)),
        clientSatisfactionScore: rating * 0.9,
        averageResponseTime: 0.5 + random.nextDouble() * 2.0,
        revenueGenerated: jobsThisMonth * (150.0 + random.nextDouble() * 100.0),
        noShowCount: random.nextInt(3),
        emergencyResponseCount: random.nextInt(5),
        specializations: [
          specializations[random.nextInt(specializations.length)],
          if (random.nextBool()) specializations[random.nextInt(specializations.length)],
        ],
        availabilityStatus: availabilityStatuses[random.nextInt(availabilityStatuses.length)],
        isCurrentlyActive: random.nextBool(),
        lastActiveDate: DateTime.now().subtract(Duration(days: random.nextInt(30))),

      ));
    }

    return guards;
  }

  /// Calculate skills matching score
  ({double score, String reason}) _calculateSkillsMatch(List<String> guardSkills, List<String> requiredSkills) {
    if (requiredSkills.isEmpty) return (score: 1.0, reason: 'Geen specifieke vaardigheden vereist');
    
    final matchingSkills = requiredSkills.where((skill) => guardSkills.contains(skill)).length;
    final score = matchingSkills / requiredSkills.length;
    
    if (score == 1.0) {
      return (score: score, reason: 'Alle vereiste vaardigheden aanwezig');
    } else if (score >= 0.7) {
      return (score: score, reason: '$matchingSkills van ${requiredSkills.length} vaardigheden');
    } else if (score >= 0.3) {
      return (score: score, reason: 'Gedeeltelijke match: $matchingSkills vaardigheden');
    } else {
      return (score: score, reason: 'Beperkte vaardigheden match');
    }
  }

  /// Calculate experience matching score
  ({double score, String reason}) _calculateExperienceMatch(int guardJobs, int requiredExperience) {
    if (requiredExperience == 0) return (score: 1.0, reason: 'Geen ervaring vereist');
    
    // Estimate years of experience based on completed jobs (rough calculation)
    final estimatedYears = (guardJobs / 50).clamp(0, 10); // Assume 50 jobs per year max
    
    if (estimatedYears >= requiredExperience) {
      return (score: 1.0, reason: '${estimatedYears.toInt()}+ jaar ervaring ($guardJobs opdrachten)');
    } else {
      final score = (estimatedYears / requiredExperience).clamp(0.0, 1.0);
      return (score: score, reason: '${estimatedYears.toInt()} jaar ervaring van $requiredExperience vereist');
    }
  }

  /// Calculate location/distance matching score
  ({double score, String reason}) _calculateLocationMatch(double distanceKm) {
    if (distanceKm <= 10) {
      return (score: 1.0, reason: 'Zeer dichtbij: ${distanceKm.toStringAsFixed(1)} km');
    } else if (distanceKm <= 25) {
      return (score: 0.8, reason: 'Redelijke afstand: ${distanceKm.toStringAsFixed(1)} km');
    } else if (distanceKm <= 50) {
      return (score: 0.6, reason: 'Acceptabele afstand: ${distanceKm.toStringAsFixed(1)} km');
    } else {
      return (score: 0.3, reason: 'Verre afstand: ${distanceKm.toStringAsFixed(1)} km');
    }
  }

  /// Calculate rating/performance matching score
  ({double score, String reason}) _calculateRatingMatch(double rating) {
    if (rating >= 4.5) {
      return (score: 1.0, reason: 'Uitstekende beoordeling: ${rating.toStringAsFixed(1)}/5.0');
    } else if (rating >= 4.0) {
      return (score: 0.9, reason: 'Goede beoordeling: ${rating.toStringAsFixed(1)}/5.0');
    } else if (rating >= 3.5) {
      return (score: 0.7, reason: 'Gemiddelde beoordeling: ${rating.toStringAsFixed(1)}/5.0');
    } else {
      return (score: 0.5, reason: 'Lage beoordeling: ${rating.toStringAsFixed(1)}/5.0');
    }
  }

  /// Calculate availability matching score
  ({double score, String reason}) _calculateAvailabilityMatch(GuardAvailabilityStatus status) {
    switch (status) {
      case GuardAvailabilityStatus.available:
        return (score: 1.0, reason: 'Direct beschikbaar');
      case GuardAvailabilityStatus.onDuty:
        return (score: 0.7, reason: 'Momenteel aan het werk, mogelijk beschikbaar');
      case GuardAvailabilityStatus.busy:
        return (score: 0.3, reason: 'Bezig, beperkte beschikbaarheid');
      case GuardAvailabilityStatus.unavailable:
        return (score: 0.0, reason: 'Niet beschikbaar');
    }
  }

  /// Calculate cost matching score
  ({double score, String reason}) _calculateCostMatch(double guardRate, double maxRate) {
    if (guardRate <= maxRate * 0.8) {
      return (score: 1.0, reason: 'Zeer kosteneffectief: €${guardRate.toStringAsFixed(2)}/uur');
    } else if (guardRate <= maxRate) {
      return (score: 0.8, reason: 'Binnen budget: €${guardRate.toStringAsFixed(2)}/uur');
    } else if (guardRate <= maxRate * 1.1) {
      return (score: 0.5, reason: 'Iets boven budget: €${guardRate.toStringAsFixed(2)}/uur');
    } else {
      return (score: 0.2, reason: 'Boven budget: €${guardRate.toStringAsFixed(2)}/uur');
    }
  }

  /// Calculate distance between guard and job location (simulated)
  Future<double> _calculateDistance(String guardId, String location, String postalCode) async {
    // Simulate distance calculation (in real app, use geocoding API)
    final random = Random(guardId.hashCode);
    return 5.0 + random.nextDouble() * 45.0; // 5 to 50 km
  }

  /// Estimate guard hourly rate based on performance
  double _estimateGuardRate(GuardPerformanceData guard) {
    // Base rate calculation based on experience and rating
    double baseRate = 18.0; // Base rate in EUR
    
    // Experience bonus (based on completed jobs)
    final experienceBonus = (guard.totalJobsCompleted / 100) * 2.0; // Up to €2 per 100 jobs
    
    // Rating bonus
    final ratingBonus = (guard.rating - 3.0) * 1.5; // Up to €3 for 5-star rating
    
    // Reliability bonus
    final reliabilityBonus = (guard.reliabilityScore - 80.0) / 20.0 * 1.0; // Up to €1 for 100% reliability
    
    final totalRate = baseRate + experienceBonus + ratingBonus + reliabilityBonus;
    return double.parse(totalRate.clamp(15.0, 35.0).toStringAsFixed(2));
  }

  /// Check if guard has specific certificate (simulated)
  bool _guardHasCertificate(String guardId, String certificate) {
    // Simulate certificate checking (in real app, check guard's certificate database)
    final random = Random(guardId.hashCode + certificate.hashCode);
    return random.nextDouble() > 0.3; // 70% chance of having any given certificate
  }

  /// Create cache key for matching results
  String _createCacheKey(
    JobType jobType, String location, List<String> skills,
    List<String> certificates, int experience,
    DateTime startDate, DateTime endDate, double maxRate,
  ) {
    return '${jobType.name}_${location}_${skills.join(',')}_'
           '${certificates.join(',')}_${experience}_'
           '${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}_'
           '${maxRate.toStringAsFixed(2)}';
  }

  /// Clear matching cache
  void clearCache() {
    _matchingCache.clear();
    _guardsCache.clear();
    _lastCacheUpdate = null;
  }

  /// Get emergency replacement suggestions for last-minute cancellations
  Future<List<GuardMatchSuggestion>> getEmergencyReplacements({
    required String originalGuardId,
    required JobType jobType,
    required String location,
    required DateTime startDate,
    required double maxHourlyRate,
    int maxSuggestions = 5,
  }) async {
    // Get all available guards
    final availableGuards = await _getAvailableGuards(startDate, startDate.add(const Duration(hours: 8)));
    
    // Filter out the original guard and prioritize by availability and proximity
    final emergencyGuards = availableGuards
        .where((guard) => guard.guardId != originalGuardId)
        .where((guard) => guard.availabilityStatus == GuardAvailabilityStatus.available)
        .toList();

    // Calculate simplified matches for emergency situations
    final matches = <GuardMatchSuggestion>[];
    
    for (final guard in emergencyGuards) {
      final distanceKm = await _calculateDistance(guard.guardId, location, '');
      final guardRate = _estimateGuardRate(guard);
      
      // Prioritize availability and proximity for emergencies
      double emergencyScore = 100.0;
      if (distanceKm > 25) emergencyScore -= 20;
      if (guardRate > maxHourlyRate) emergencyScore -= 15;
      if (guard.rating < 4.0) emergencyScore -= 10;
      
      matches.add(GuardMatchSuggestion(
        guardId: guard.guardId,
        guardName: guard.guardName,
        matchPercentage: emergencyScore.clamp(0, 100),
        rating: guard.rating,
        completedJobs: guard.totalJobsCompleted,
        distanceKm: distanceKm,
        matchingSkills: guard.specializations,
        matchingCertificates: [],
        availability: guard.availabilityStatus,
        hourlyRate: guardRate,
        profileImageUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=${guard.guardId}',
        matchReasons: [
          MatchReason(
            reason: 'Direct beschikbaar voor spoedopdracht',
            weight: 1.0,
            type: MatchReasonType.availability,
          ),
        ],
      ));
    }

    // Sort by emergency score and return top matches
    matches.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
    return matches.take(maxSuggestions).toList();
  }
}
