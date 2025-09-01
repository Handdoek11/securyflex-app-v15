import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/reputation_data.dart';

/// Comprehensive reputation calculation service for SecuryFlex platform
/// 
/// Calculates and maintains reputation scores for both guards and companies
/// Integrates with existing rating, profile, and workflow systems
/// Follows Dutch business logic and CAO arbeidsrecht compliance
class ReputationCalculationService {
  static final ReputationCalculationService _instance = ReputationCalculationService._internal();
  factory ReputationCalculationService() => _instance;
  ReputationCalculationService._internal();

  static ReputationCalculationService get instance => _instance;

  /// Firebase services
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  
  /// Cache for reputation calculations
  final Map<String, ReputationData> _reputationCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheDuration = Duration(hours: 1); // Cache for 1 hour

  /// Calculate comprehensive reputation score for a user
  /// 
  /// Uses weighted algorithm based on Dutch security industry standards:
  /// - Job completion rating: 25%
  /// - Reliability metrics: 20%
  /// - Client feedback: 20%
  /// - Compliance & certifications: 15%
  /// - Experience multiplier: 10%
  /// - Specialization performance: 10%
  Future<ReputationData> calculateReputation(String userId, String userRole) async {
    try {
      if (kDebugMode) {
        print('[ReputationCalculationService] Calculating reputation for user: $userId ($userRole)');
      }

      // Load base metrics from various sources
      final baseMetrics = await _loadBaseMetrics(userId, userRole);
      final ratingMetrics = await _loadRatingMetrics(userId, userRole);
      final reliabilityMetrics = await _loadReliabilityMetrics(userId, userRole);
      final complianceMetrics = await _loadComplianceMetrics(userId, userRole);
      final experienceMetrics = await _loadExperienceMetrics(userId, userRole);
      final specializationMetrics = await _loadSpecializationMetrics(userId, userRole);

      // Calculate individual score components
      final jobCompletionScore = _calculateJobCompletionScore(ratingMetrics);
      final reliabilityScore = _calculateReliabilityScore(reliabilityMetrics);
      final clientFeedbackScore = _calculateClientFeedbackScore(ratingMetrics);
      final complianceScore = _calculateComplianceScore(complianceMetrics);
      final experienceMultiplier = _calculateExperienceMultiplier(experienceMetrics);

      // Calculate weighted overall score
      final overallScore = _calculateWeightedOverallScore(
        jobCompletionScore,
        reliabilityScore,
        clientFeedbackScore,
        complianceScore,
        experienceMultiplier,
        specializationMetrics,
      );

      // Calculate trends and milestones
      final currentTrend = await _calculateReputationTrend(userId, overallScore);
      final achievedMilestones = _calculateAchievedMilestones(baseMetrics);

      // Create comprehensive reputation data
      final reputation = ReputationData(
        userId: userId,
        userRole: userRole,
        lastCalculated: DateTime.now(),
        firstJobDate: baseMetrics['firstJobDate'] ?? DateTime.now(),
        overallScore: overallScore.clamp(0.0, 100.0),
        jobCompletionRating: jobCompletionScore,
        reliabilityScore: reliabilityScore,
        clientFeedbackScore: clientFeedbackScore,
        complianceScore: complianceScore,
        experienceMultiplier: experienceMultiplier,
        totalJobsCompleted: baseMetrics['totalJobsCompleted'] ?? 0,
        totalJobsCancelled: baseMetrics['totalJobsCancelled'] ?? 0,
        noShowCount: reliabilityMetrics['noShowCount'] ?? 0,
        lateArrivalCount: reliabilityMetrics['lateArrivalCount'] ?? 0,
        earlyCompletionCount: reliabilityMetrics['earlyCompletionCount'] ?? 0,
        averageResponseTime: reliabilityMetrics['averageResponseTime'] ?? 24.0,
        positiveReviewCount: ratingMetrics['positiveReviewCount'] ?? 0,
        neutralReviewCount: ratingMetrics['neutralReviewCount'] ?? 0,
        negativeReviewCount: ratingMetrics['negativeReviewCount'] ?? 0,
        repeatClientPercentage: ratingMetrics['repeatClientPercentage'] ?? 0.0,
        recommendationRate: ratingMetrics['recommendationRate'] ?? 0.0,
        wpbrCertified: complianceMetrics['wpbrCertified'] ?? false,
        kvkVerified: complianceMetrics['kvkVerified'] ?? false,
        activeCertificateCount: complianceMetrics['activeCertificateCount'] ?? 0,
        lastCertificateUpdate: complianceMetrics['lastCertificateUpdate'],
        complianceViolationCount: complianceMetrics['complianceViolationCount'] ?? 0,
        monthlyScoreChange: await _calculateMonthlyScoreChange(userId),
        quarterlyScoreChange: await _calculateQuarterlyScoreChange(userId),
        currentTrend: currentTrend,
        achievedMilestones: achievedMilestones,
        specializationScores: Map<String, double>.from(specializationMetrics['scores'] ?? {}),
        topSpecialization: specializationMetrics['topSpecialization'],
        averageHourlyRate: baseMetrics['averageHourlyRate'] ?? 0.0,
      );

      // Cache the result
      _reputationCache[userId] = reputation;
      _lastCacheUpdate = DateTime.now();

      // Store in Firestore for persistence
      await _storeReputationData(reputation);

      if (kDebugMode) {
        print('[ReputationCalculationService] Calculated reputation score: ${reputation.overallScore.round()}/100');
      }

      return reputation;
    } catch (e) {
      if (kDebugMode) {
        print('[ReputationCalculationService] Error calculating reputation: $e');
      }
      
      // Return initial reputation on error
      return ReputationData.initial(userId: userId, userRole: userRole);
    }
  }

  /// Get reputation data with caching support
  Future<ReputationData> getReputation(String userId, String userRole, {bool useCache = true}) async {
    try {
      // Check cache first
      if (useCache && 
          _reputationCache.containsKey(userId) && 
          _isCacheValid()) {
        return _reputationCache[userId]!;
      }

      // Try to load from Firestore
      final doc = await _firestore
          .collection('reputation_data')
          .doc(userId)
          .get();

      if (doc.exists) {
        final reputation = ReputationData.fromFirestore(doc);
        
        // Check if data is stale (older than 24 hours)
        final hoursSinceCalculation = DateTime.now().difference(reputation.lastCalculated).inHours;
        
        if (hoursSinceCalculation < 24) {
          _reputationCache[userId] = reputation;
          return reputation;
        }
      }

      // Recalculate if no valid cached or stored data
      return await calculateReputation(userId, userRole);
    } catch (e) {
      if (kDebugMode) {
        print('[ReputationCalculationService] Error loading reputation: $e');
      }
      return ReputationData.initial(userId: userId, userRole: userRole);
    }
  }

  /// Update reputation after job completion
  Future<void> updateReputationAfterJob({
    required String userId,
    required String userRole,
    required String workflowId,
    required bool jobCompleted,
    double? newRating,
  }) async {
    try {
      if (kDebugMode) {
        print('[ReputationCalculationService] Updating reputation after job: $workflowId');
      }

      // Trigger reputation recalculation
      await calculateReputation(userId, userRole);
      
      // Check for new milestones
      final reputation = await getReputation(userId, userRole, useCache: false);
      await _checkAndAwardMilestones(reputation);
      
    } catch (e) {
      if (kDebugMode) {
        print('[ReputationCalculationService] Error updating reputation after job: $e');
      }
    }
  }

  /// Private calculation methods

  Future<Map<String, dynamic>> _loadBaseMetrics(String userId, String userRole) async {
    try {
      // Load from job_workflows collection
      final workflowQuery = await _firestore
          .collection('job_workflows')
          .where('${userRole}Id', isEqualTo: userId)
          .get();

      final workflows = workflowQuery.docs;
      final completedJobs = workflows.where((w) => w.data()['currentState'] == 'completed').length;
      final cancelledJobs = workflows.where((w) => w.data()['currentState'] == 'cancelled').length;
      
      // Calculate first job date
      DateTime? firstJobDate;
      if (workflows.isNotEmpty) {
        final sortedWorkflows = workflows
          ..sort((a, b) => (a.data()['createdAt'] as Timestamp)
              .compareTo(b.data()['createdAt'] as Timestamp));
        firstJobDate = (sortedWorkflows.first.data()['createdAt'] as Timestamp).toDate();
      }

      // Load average hourly rate
      double averageHourlyRate = 0.0;
      if (completedJobs > 0) {
        final rateSum = workflows
            .where((w) => w.data()['currentState'] == 'completed')
            .fold<double>(0.0, (sum, w) => sum + (w.data()['hourlyRate'] as num? ?? 0.0).toDouble());
        averageHourlyRate = rateSum / completedJobs;
      }

      return {
        'totalJobsCompleted': completedJobs,
        'totalJobsCancelled': cancelledJobs,
        'firstJobDate': firstJobDate ?? DateTime.now(),
        'averageHourlyRate': averageHourlyRate,
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ReputationCalculationService] Error loading base metrics: $e');
      }
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadRatingMetrics(String userId, String userRole) async {
    try {
      final ratingsQuery = await _firestore
          .collection('job_reviews')
          .where('reviewerId', isEqualTo: userId)
          .where('reviewerRole', isEqualTo: userRole)
          .get();

      final ratings = ratingsQuery.docs
          .map((doc) => doc.data())
          .where((data) => data['rating'] != null)
          .toList();

      if (ratings.isEmpty) {
        return {
          'positiveReviewCount': 0,
          'neutralReviewCount': 0,
          'negativeReviewCount': 0,
          'averageRating': 0.0,
          'repeatClientPercentage': 0.0,
          'recommendationRate': 0.0,
        };
      }

      final positiveCount = ratings.where((r) => (r['rating'] as num) >= 4.0).length;
      final neutralCount = ratings.where((r) => (r['rating'] as num) >= 3.0 && (r['rating'] as num) < 4.0).length;
      final negativeCount = ratings.where((r) => (r['rating'] as num) < 3.0).length;
      
      final averageRating = ratings.fold<double>(0.0, (sum, r) => sum + (r['rating'] as num).toDouble()) / ratings.length;
      
      // Calculate repeat client percentage (simplified)
      final clientIds = ratings.map((r) => r['clientId']).toSet();
      final totalInteractions = ratings.length;
      final uniqueClients = clientIds.length;
      final repeatClientPercentage = uniqueClients > 0 
          ? ((totalInteractions - uniqueClients) / totalInteractions) * 100
          : 0.0;

      // Calculate recommendation rate based on 4+ star ratings
      final recommendationRate = ratings.isNotEmpty 
          ? (positiveCount / ratings.length) * 100
          : 0.0;

      return {
        'positiveReviewCount': positiveCount,
        'neutralReviewCount': neutralCount,
        'negativeReviewCount': negativeCount,
        'averageRating': averageRating,
        'repeatClientPercentage': repeatClientPercentage.clamp(0.0, 100.0),
        'recommendationRate': recommendationRate.clamp(0.0, 100.0),
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ReputationCalculationService] Error loading rating metrics: $e');
      }
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadReliabilityMetrics(String userId, String userRole) async {
    try {
      // Load from workflow status tracking
      final workflowQuery = await _firestore
          .collection('job_workflows')
          .where('${userRole}Id', isEqualTo: userId)
          .get();

      int noShowCount = 0;
      int lateArrivalCount = 0;
      int earlyCompletionCount = 0;
      double totalResponseTime = 0.0;
      int responseCount = 0;

      for (final doc in workflowQuery.docs) {
        final data = doc.data();
        
        // Count no-shows (cancelled by guard without valid reason)
        if (data['currentState'] == 'cancelled' && data['cancelledBy'] == userId) {
          final cancelReason = data['cancellationReason'] as String?;
          if (cancelReason == null || 
              !['illness', 'emergency', 'force_majeure'].contains(cancelReason)) {
            noShowCount++;
          }
        }

        // Count late arrivals (from status updates)
        final statusUpdates = data['statusUpdates'] as List<dynamic>? ?? [];
        for (final update in statusUpdates) {
          if (update['status'] == 'late_arrival') {
            lateArrivalCount++;
          }
          if (update['status'] == 'early_completion') {
            earlyCompletionCount++;
          }
        }

        // Calculate average response time
        final appliedAt = data['${userRole}AppliedAt'] as Timestamp?;
        final createdAt = data['createdAt'] as Timestamp?;
        if (appliedAt != null && createdAt != null) {
          final responseTimeHours = appliedAt.toDate().difference(createdAt.toDate()).inHours.toDouble();
          totalResponseTime += responseTimeHours;
          responseCount++;
        }
      }

      final averageResponseTime = responseCount > 0 ? totalResponseTime / responseCount : 24.0;

      return {
        'noShowCount': noShowCount,
        'lateArrivalCount': lateArrivalCount,
        'earlyCompletionCount': earlyCompletionCount,
        'averageResponseTime': averageResponseTime,
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ReputationCalculationService] Error loading reliability metrics: $e');
      }
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadComplianceMetrics(String userId, String userRole) async {
    try {
      // Load user profile for compliance data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return {};
      }

      final userData = userDoc.data()!;
      
      final wpbrCertified = userData['wpbrCertified'] as bool? ?? false;
      final kvkVerified = userData['kvkVerified'] as bool? ?? false;
      
      // Count active certificates
      final certificates = userData['certificates'] as List<dynamic>? ?? [];
      final activeCertificates = certificates.where((cert) {
        final expiryDate = cert['expiryDate'] as Timestamp?;
        return expiryDate == null || expiryDate.toDate().isAfter(DateTime.now());
      }).length;

      // Get last certificate update
      DateTime? lastCertificateUpdate;
      if (certificates.isNotEmpty) {
        final sortedCerts = certificates
          ..sort((a, b) => (b['updatedAt'] as Timestamp? ?? Timestamp.now())
              .compareTo(a['updatedAt'] as Timestamp? ?? Timestamp.now()));
        lastCertificateUpdate = (sortedCerts.first['updatedAt'] as Timestamp).toDate();
      }

      // Load compliance violations (from admin actions)
      final violationsQuery = await _firestore
          .collection('compliance_violations')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      return {
        'wpbrCertified': wpbrCertified,
        'kvkVerified': kvkVerified,
        'activeCertificateCount': activeCertificates,
        'lastCertificateUpdate': lastCertificateUpdate,
        'complianceViolationCount': violationsQuery.docs.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ReputationCalculationService] Error loading compliance metrics: $e');
      }
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadExperienceMetrics(String userId, String userRole) async {
    try {
      final workflowQuery = await _firestore
          .collection('job_workflows')
          .where('${userRole}Id', isEqualTo: userId)
          .where('currentState', isEqualTo: 'completed')
          .get();

      final totalHours = workflowQuery.docs.fold<double>(0.0, (sum, doc) {
        final duration = doc.data()['plannedDurationHours'] as num? ?? 0;
        return sum + duration.toDouble();
      });

      final monthsActive = workflowQuery.docs.isNotEmpty
          ? DateTime.now().difference(
              (workflowQuery.docs.first.data()['createdAt'] as Timestamp).toDate()
            ).inDays / 30.0
          : 0.0;

      return {
        'totalHoursWorked': totalHours,
        'monthsActive': monthsActive,
        'totalJobsCompleted': workflowQuery.docs.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ReputationCalculationService] Error loading experience metrics: $e');
      }
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadSpecializationMetrics(String userId, String userRole) async {
    try {
      final workflowQuery = await _firestore
          .collection('job_workflows')
          .where('${userRole}Id', isEqualTo: userId)
          .get();

      final specializationScores = <String, List<double>>{};

      for (final doc in workflowQuery.docs) {
        final data = doc.data();
        final specialization = data['requiredSpecialization'] as String?;
        final rating = data['finalRating'] as num?;

        if (specialization != null && rating != null) {
          specializationScores.putIfAbsent(specialization, () => []);
          specializationScores[specialization]!.add(rating.toDouble());
        }
      }

      final avgScores = <String, double>{};
      String? topSpecialization;
      double highestScore = 0.0;

      for (final entry in specializationScores.entries) {
        final avgScore = entry.value.reduce((a, b) => a + b) / entry.value.length;
        avgScores[entry.key] = avgScore;
        
        if (avgScore > highestScore) {
          highestScore = avgScore;
          topSpecialization = entry.key;
        }
      }

      return {
        'scores': avgScores,
        'topSpecialization': topSpecialization,
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ReputationCalculationService] Error loading specialization metrics: $e');
      }
      return {};
    }
  }

  /// Score calculation methods

  double _calculateJobCompletionScore(Map<String, dynamic> ratingMetrics) {
    final averageRating = ratingMetrics['averageRating'] as double? ?? 0.0;
    
    if (averageRating == 0.0) return 50.0; // Neutral score for no ratings
    
    // Convert 1-5 star rating to 0-100 score
    return ((averageRating - 1.0) / 4.0) * 100.0;
  }

  double _calculateReliabilityScore(Map<String, dynamic> reliabilityMetrics) {
    final noShowCount = reliabilityMetrics['noShowCount'] as int? ?? 0;
    final lateArrivalCount = reliabilityMetrics['lateArrivalCount'] as int? ?? 0;
    final averageResponseTime = reliabilityMetrics['averageResponseTime'] as double? ?? 24.0;
    
    double score = 100.0;
    
    // Penalty for no-shows (severe in Dutch security industry)
    score -= noShowCount * 15.0; // -15 points per no-show
    
    // Penalty for late arrivals
    score -= lateArrivalCount * 5.0; // -5 points per late arrival
    
    // Penalty for slow response times (over 24 hours)
    if (averageResponseTime > 24.0) {
      score -= (averageResponseTime - 24.0) * 2.0; // -2 points per hour over 24h
    }
    
    return score.clamp(0.0, 100.0);
  }

  double _calculateClientFeedbackScore(Map<String, dynamic> ratingMetrics) {
    final positiveCount = ratingMetrics['positiveReviewCount'] as int? ?? 0;
    final neutralCount = ratingMetrics['neutralReviewCount'] as int? ?? 0;
    final negativeCount = ratingMetrics['negativeReviewCount'] as int? ?? 0;
    final recommendationRate = ratingMetrics['recommendationRate'] as double? ?? 0.0;
    
    final totalReviews = positiveCount + neutralCount + negativeCount;
    
    if (totalReviews == 0) return 50.0; // Neutral score for no reviews
    
    // Weight positive reviews more heavily
    final weightedScore = (positiveCount * 100 + neutralCount * 70 + negativeCount * 30) / totalReviews;
    
    // Boost score based on recommendation rate
    final boostedScore = weightedScore + (recommendationRate - 50.0) * 0.2;
    
    return boostedScore.clamp(0.0, 100.0);
  }

  double _calculateComplianceScore(Map<String, dynamic> complianceMetrics) {
    final wpbrCertified = complianceMetrics['wpbrCertified'] as bool? ?? false;
    final kvkVerified = complianceMetrics['kvkVerified'] as bool? ?? false;
    final activeCertificateCount = complianceMetrics['activeCertificateCount'] as int? ?? 0;
    final violationCount = complianceMetrics['complianceViolationCount'] as int? ?? 0;
    
    double score = 0.0;
    
    // Base certification scores
    if (wpbrCertified) score += 50.0; // WPBR is mandatory for guards
    if (kvkVerified) score += 30.0; // KvK verification
    
    // Additional certificates
    score += min(activeCertificateCount * 5.0, 20.0); // Up to +20 for multiple certificates
    
    // Penalty for violations
    score -= violationCount * 20.0; // -20 points per violation
    
    return score.clamp(0.0, 100.0);
  }

  double _calculateExperienceMultiplier(Map<String, dynamic> experienceMetrics) {
    final totalHoursWorked = experienceMetrics['totalHoursWorked'] as double? ?? 0.0;
    final monthsActive = experienceMetrics['monthsActive'] as double? ?? 0.0;
    final totalJobsCompleted = experienceMetrics['totalJobsCompleted'] as int? ?? 0;
    
    // Base multiplier
    double multiplier = 1.0;
    
    // Hours worked boost (up to +20%)
    if (totalHoursWorked > 2000) {
      multiplier += 0.20; // Expert level
    } else if (totalHoursWorked > 1000) {
      multiplier += 0.15; // Experienced
    } else if (totalHoursWorked > 200) {
      multiplier += 0.10; // Intermediate
    }
    
    // Tenure boost (up to +10%)
    if (monthsActive > 24) {
      multiplier += 0.10; // 2+ years
    } else if (monthsActive > 12) {
      multiplier += 0.05; // 1+ year
    }
    
    // Job count boost (up to +5%)
    if (totalJobsCompleted > 100) {
      multiplier += 0.05;
    } else if (totalJobsCompleted > 50) {
      multiplier += 0.03;
    }
    
    return multiplier.clamp(0.8, 1.35); // Allow slight penalty for new users, cap at +35%
  }

  double _calculateWeightedOverallScore(
    double jobCompletionScore,
    double reliabilityScore,
    double clientFeedbackScore,
    double complianceScore,
    double experienceMultiplier,
    Map<String, dynamic> specializationMetrics,
  ) {
    // Weights based on Dutch security industry importance
    const jobCompletionWeight = 0.25;
    const reliabilityWeight = 0.20;
    const clientFeedbackWeight = 0.20;
    const complianceWeight = 0.15;
    const specializationWeight = 0.10;
    const experienceWeight = 0.10;
    
    // Calculate base weighted score
    double baseScore = 
        (jobCompletionScore * jobCompletionWeight) +
        (reliabilityScore * reliabilityWeight) +
        (clientFeedbackScore * clientFeedbackWeight) +
        (complianceScore * complianceWeight);
    
    // Add specialization bonus
    final specializationScores = specializationMetrics['scores'] as Map<String, double>? ?? {};
    if (specializationScores.isNotEmpty) {
      final avgSpecializationScore = specializationScores.values
          .fold<double>(0.0, (sum, score) => sum + score) / specializationScores.length;
      baseScore += (avgSpecializationScore / 5.0 * 100.0) * specializationWeight;
    } else {
      baseScore += 50.0 * specializationWeight; // Neutral specialization score
    }
    
    // Add experience component
    baseScore += ((experienceMultiplier - 1.0) * 100.0) * experienceWeight;
    
    // Apply experience multiplier to final score
    final finalScore = baseScore * experienceMultiplier;
    
    return finalScore.clamp(0.0, 100.0);
  }

  Future<ReputationTrend> _calculateReputationTrend(String userId, double currentScore) async {
    try {
      // Load historical scores from last 3 months
      final historicalQuery = await _firestore
          .collection('reputation_data')
          .doc(userId)
          .collection('history')
          .where('calculatedAt', isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 90))))
          .orderBy('calculatedAt', descending: true)
          .limit(10)
          .get();

      if (historicalQuery.docs.isEmpty) {
        return ReputationTrend.stable;
      }

      final historicalScores = historicalQuery.docs
          .map((doc) => (doc.data()['overallScore'] as num).toDouble())
          .toList();

      if (historicalScores.length < 2) {
        return ReputationTrend.stable;
      }

      // Calculate trend using linear regression (simplified)
      final recentAverage = historicalScores.take(3).fold<double>(0.0, (sum, score) => sum + score) / 3;
      final olderAverage = historicalScores.skip(3).take(3).fold<double>(0.0, (sum, score) => sum + score) / 3;

      final difference = recentAverage - olderAverage;

      if (difference > 2.0) {
        return ReputationTrend.improving;
      } else if (difference < -2.0) {
        return ReputationTrend.declining;
      } else {
        return ReputationTrend.stable;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ReputationCalculationService] Error calculating trend: $e');
      }
      return ReputationTrend.stable;
    }
  }

  List<ReputationMilestone> _calculateAchievedMilestones(Map<String, dynamic> baseMetrics) {
    final achievements = <ReputationMilestone>[];
    
    // Create temporary reputation data for milestone checking
    final tempReputation = ReputationData.initial(userId: '', userRole: '').copyWith(
      totalJobsCompleted: baseMetrics['totalJobsCompleted'] ?? 0,
    );

    for (final milestone in ReputationMilestone.values) {
      if (milestone.isEligible(tempReputation)) {
        achievements.add(milestone);
      }
    }

    return achievements;
  }

  Future<double> _calculateMonthlyScoreChange(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final historicalQuery = await _firestore
          .collection('reputation_data')
          .doc(userId)
          .collection('history')
          .where('calculatedAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('calculatedAt', descending: true)
          .limit(2)
          .get();

      if (historicalQuery.docs.length < 2) return 0.0;

      final currentScore = (historicalQuery.docs.first.data()['overallScore'] as num).toDouble();
      final oldScore = (historicalQuery.docs.last.data()['overallScore'] as num).toDouble();

      return currentScore - oldScore;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _calculateQuarterlyScoreChange(String userId) async {
    try {
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
      
      final historicalQuery = await _firestore
          .collection('reputation_data')
          .doc(userId)
          .collection('history')
          .where('calculatedAt', isGreaterThan: Timestamp.fromDate(ninetyDaysAgo))
          .orderBy('calculatedAt', descending: true)
          .limit(2)
          .get();

      if (historicalQuery.docs.length < 2) return 0.0;

      final currentScore = (historicalQuery.docs.first.data()['overallScore'] as num).toDouble();
      final oldScore = (historicalQuery.docs.last.data()['overallScore'] as num).toDouble();

      return currentScore - oldScore;
    } catch (e) {
      return 0.0;
    }
  }

  /// Utility methods

  Future<void> _storeReputationData(ReputationData reputation) async {
    try {
      final batch = _firestore.batch();
      
      // Store current reputation
      final reputationRef = _firestore.collection('reputation_data').doc(reputation.userId);
      batch.set(reputationRef, reputation.toFirestore());
      
      // Store historical record
      final historyRef = reputationRef.collection('history').doc();
      batch.set(historyRef, {
        ...reputation.toFirestore(),
        'calculatedAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('[ReputationCalculationService] Error storing reputation data: $e');
      }
    }
  }

  Future<void> _checkAndAwardMilestones(ReputationData reputation) async {
    try {
      final newMilestones = <ReputationMilestone>[];
      
      for (final milestone in ReputationMilestone.values) {
        if (!reputation.achievedMilestones.contains(milestone) && 
            milestone.isEligible(reputation)) {
          newMilestones.add(milestone);
        }
      }
      
      if (newMilestones.isNotEmpty) {
        // Award new milestones
        await _firestore.collection('reputation_data').doc(reputation.userId).update({
          'achievedMilestones': FieldValue.arrayUnion(
              newMilestones.map((m) => m.name).toList()),
        });
        
        // Create milestone achievement records
        for (final milestone in newMilestones) {
          await _firestore.collection('milestone_achievements').add({
            'userId': reputation.userId,
            'milestone': milestone.name,
            'achievedAt': FieldValue.serverTimestamp(),
            'title': milestone.dutchTitle,
            'description': milestone.dutchDescription,
          });
        }
        
        if (kDebugMode) {
          print('[ReputationCalculationService] Awarded ${newMilestones.length} new milestones');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ReputationCalculationService] Error checking milestones: $e');
      }
    }
  }

  bool _isCacheValid() {
    return _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration;
  }

  void invalidateCache() {
    _reputationCache.clear();
    _lastCacheUpdate = null;
  }
}