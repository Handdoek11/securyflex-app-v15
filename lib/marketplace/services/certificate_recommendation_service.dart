import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/certificates/certificate_models.dart';
import '../../models/certificates/job_requirements_models.dart';
import '../../models/certificates/matching_result_models.dart';
import 'certificate_matching_service.dart';
import 'certificate_validation_service.dart';

/// Certificate Recommendation Service
/// 
/// Provides intelligent certificate recommendations for career advancement
/// based on:
/// - Current user certificates and job market analysis
/// - Career progression paths in Dutch security industry
/// - ROI analysis for certificate investments
/// - Market demand trends and salary impact
/// - Personalized learning paths and training providers

class CertificateRecommendationService {
  final FirebaseFirestore _firestore;

  // Cache for frequently accessed data
  final Map<String, List<CareerPath>> _careerPathsCache = {};
  final Map<String, MarketAnalysisData> _marketDataCache = {};

  CertificateRecommendationService({
    FirebaseFirestore? firestore,
    CertificateMatchingService? matchingService,
    CertificateValidationService? validationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collections
  CollectionReference get _jobsCollection => _firestore.collection('jobs');
  CollectionReference get _userCertificatesCollection => _firestore.collection('userCertificates');
  CollectionReference get _careerPathsCollection => _firestore.collection('careerPaths');
  CollectionReference get _trainingProvidersCollection => _firestore.collection('trainingProviders');

  /// Get personalized certificate recommendations for user
  Future<PersonalizedRecommendationResult> getPersonalizedRecommendations(
    String userId, {
    RecommendationContext context = RecommendationContext.general,
    int maxRecommendations = 10,
  }) async {
    try {
      // 1. Get user's current certificates
      final userCertificates = await _getUserCertificates(userId);
      final userCertificateIds = userCertificates.map((cert) => cert.certificateId).toList();

      // 2. Analyze job market for recommendation context
      final marketAnalysis = await _analyzeJobMarket(context);

      // 3. Get career paths relevant to user's current certificates
      final careerPaths = await _getRelevantCareerPaths(userCertificateIds, context);

      // 4. Generate recommendations based on multiple factors
      final recommendations = <CertificateRecommendation>[];

      // Critical missing certificates (mandatory for current applications)
      final criticalRecommendations = await _getCriticalCertificateRecommendations(
        userId, userCertificateIds, marketAnalysis
      );
      recommendations.addAll(criticalRecommendations);

      // Career advancement recommendations
      final careerRecommendations = await _getCareerAdvancementRecommendations(
        userCertificateIds, careerPaths, marketAnalysis
      );
      recommendations.addAll(careerRecommendations);

      // Market opportunity recommendations
      final opportunityRecommendations = await _getMarketOpportunityRecommendations(
        userCertificateIds, marketAnalysis
      );
      recommendations.addAll(opportunityRecommendations);

      // Expiring certificate renewal recommendations
      final renewalRecommendations = await _getRenewalRecommendations(userCertificates);
      recommendations.addAll(renewalRecommendations);

      // 5. Score, rank, and filter recommendations
      final rankedRecommendations = _rankRecommendations(
        recommendations, 
        userCertificateIds, 
        marketAnalysis,
        maxRecommendations
      );

      // 6. Add training provider information
      final enrichedRecommendations = await _enrichWithTrainingProviders(rankedRecommendations);

      return PersonalizedRecommendationResult(
        userId: userId,
        context: context,
        recommendations: enrichedRecommendations,
        marketAnalysis: marketAnalysis,
        careerPaths: careerPaths,
        generatedAt: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 30)),
      );

    } catch (e, stackTrace) {
      debugPrint('Error generating recommendations: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return PersonalizedRecommendationResult(
        userId: userId,
        context: context,
        recommendations: [],
        marketAnalysis: MarketAnalysisData.empty(),
        careerPaths: [],
        generatedAt: DateTime.now(),
        error: 'Failed to generate recommendations: ${e.toString()}',
      );
    }
  }

  /// Get user's current certificates
  Future<List<UserCertificate>> _getUserCertificates(String userId) async {
    final snapshot = await _userCertificatesCollection
        .where('userId', isEqualTo: userId)
        .where('isVerified', isEqualTo: true)
        .where('status', whereIn: ['valid', 'expiring_soon'])
        .get();

    return snapshot.docs
        .map((doc) => UserCertificate.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }))
        .toList();
  }

  /// Analyze job market for recommendation context
  Future<MarketAnalysisData> _analyzeJobMarket(RecommendationContext context) async {
    final cacheKey = context.name;
    if (_marketDataCache.containsKey(cacheKey)) {
      final cached = _marketDataCache[cacheKey]!;
      if (cached.generatedAt.isAfter(DateTime.now().subtract(const Duration(hours: 6)))) {
        return cached;
      }
    }

    try {
      // Get recent job postings (last 90 days) for analysis
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      Query jobsQuery = _jobsCollection
          .where('createdAt', isGreaterThan: cutoffDate.toIso8601String())
          .where('status', isEqualTo: 'active');

      // Filter by context if specified
      if (context != RecommendationContext.general) {
        jobsQuery = jobsQuery.where('category', isEqualTo: context.name);
      }

      final snapshot = await jobsQuery.limit(1000).get();
      
      // Analyze certificate requirements across jobs
      final certificateFrequency = <String, CertificateMarketData>{};
      final salaryData = <String, List<double>>{};
      
      for (final doc in snapshot.docs) {
        final jobData = doc.data() as Map<String, dynamic>;
        final requirements = jobData['certificateRequirements'] as List<dynamic>? ?? [];
        final salary = (jobData['salaryMax'] as num?)?.toDouble() ?? 0.0;
        
        for (final req in requirements) {
          final reqMap = req as Map<String, dynamic>;
          final certId = reqMap['certificateId'] as String;
          final priority = RequirementPriority.fromCode(reqMap['priority'] ?? 'optional');
          
          if (!certificateFrequency.containsKey(certId)) {
            certificateFrequency[certId] = CertificateMarketData(
              certificateId: certId,
              demandScore: 0,
              avgSalaryImpact: 0.0,
              jobCount: 0,
              trendDirection: TrendDirection.stable,
            );
          }
          
          final data = certificateFrequency[certId]!;
          certificateFrequency[certId] = data.copyWith(
            demandScore: data.demandScore + priority.weight,
            jobCount: data.jobCount + 1,
          );
          
          // Track salary data
          if (salary > 0) {
            salaryData.putIfAbsent(certId, () => []).add(salary);
          }
        }
      }

      // Calculate average salary impact
      for (final entry in certificateFrequency.entries) {
        final salaries = salaryData[entry.key] ?? [];
        if (salaries.isNotEmpty) {
          final avgSalary = salaries.reduce((a, b) => a + b) / salaries.length;
          certificateFrequency[entry.key] = entry.value.copyWith(
            avgSalaryImpact: avgSalary,
          );
        }
      }

      final marketData = MarketAnalysisData(
        context: context,
        certificateMarketData: certificateFrequency.values.toList(),
        totalJobsAnalyzed: snapshot.docs.length,
        averageSalary: _calculateAverageSalary(snapshot.docs),
        topDemandCertificates: _getTopDemandCertificates(certificateFrequency, 10),
        generatedAt: DateTime.now(),
      );

      _marketDataCache[cacheKey] = marketData;
      return marketData;

    } catch (e) {
      debugPrint('Error analyzing job market: $e');
      return MarketAnalysisData.empty();
    }
  }

  /// Calculate average salary from job documents
  double _calculateAverageSalary(List<QueryDocumentSnapshot> docs) {
    final salaries = <double>[];
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final salaryMax = (data['salaryMax'] as num?)?.toDouble();
      if (salaryMax != null && salaryMax > 0) {
        salaries.add(salaryMax);
      }
    }
    
    return salaries.isEmpty ? 0.0 : salaries.reduce((a, b) => a + b) / salaries.length;
  }

  /// Get top demand certificates
  List<String> _getTopDemandCertificates(Map<String, CertificateMarketData> data, int count) {
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.demandScore.compareTo(a.value.demandScore));
    
    return sortedEntries
        .take(count)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get career paths relevant to user's certificates
  Future<List<CareerPath>> _getRelevantCareerPaths(
    List<String> userCertificateIds, 
    RecommendationContext context
  ) async {
    final cacheKey = '${userCertificateIds.join(',')}_$context';
    if (_careerPathsCache.containsKey(cacheKey)) {
      return _careerPathsCache[cacheKey]!;
    }

    try {
      // Get predefined career paths from Firestore
      Query pathsQuery = _careerPathsCollection.where('isActive', isEqualTo: true);
      
      if (context != RecommendationContext.general) {
        pathsQuery = pathsQuery.where('category', isEqualTo: context.name);
      }

      final snapshot = await pathsQuery.get();
      
      final careerPaths = snapshot.docs
          .map((doc) => CareerPath.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .where((path) => _isPathRelevant(path, userCertificateIds))
          .toList();

      // Add dynamically generated career paths based on certificate registry
      careerPaths.addAll(_generateDynamicCareerPaths(userCertificateIds, context));

      _careerPathsCache[cacheKey] = careerPaths;
      return careerPaths;

    } catch (e) {
      debugPrint('Error getting career paths: $e');
      return _generateDynamicCareerPaths(userCertificateIds, context);
    }
  }

  /// Check if career path is relevant to user's certificates
  bool _isPathRelevant(CareerPath path, List<String> userCertificateIds) {
    // Path is relevant if user has some prerequisites or entry-level certificates
    final hasPrerequisites = path.prerequisites
        .any((prereq) => userCertificateIds.contains(prereq));
    
    final hasEntryLevel = path.milestones.isNotEmpty && 
        userCertificateIds.any((certId) => 
            path.milestones.first.requiredCertificates.contains(certId));

    return hasPrerequisites || hasEntryLevel || userCertificateIds.isEmpty;
  }

  /// Generate dynamic career paths based on certificate registry
  List<CareerPath> _generateDynamicCareerPaths(
    List<String> userCertificateIds, 
    RecommendationContext context
  ) {
    final paths = <CareerPath>[];

    // Basic to Advanced Security Path
    paths.add(CareerPath(
      id: 'basic_to_advanced_security',
      name: 'Basis naar Professionele Beveiliging',
      description: 'Ontwikkel jezelf van basis beveiliger naar professionele beveiligingsspecialist',
      category: 'security',
      estimatedDuration: const Duration(days: 365 * 2), // 2 years
      prerequisites: ['wpbr_a'],
      milestones: [
        CareerMilestone(
          level: 1,
          title: 'Basis Beveiliger',
          requiredCertificates: ['wpbr_a'],
          estimatedSalaryRange: SalaryRange(min: 2200, max: 2800),
          timeToAchieve: const Duration(days: 0),
        ),
        CareerMilestone(
          level: 2,
          title: 'Ervaren Beveiliger',
          requiredCertificates: ['wpbr_a', 'bhv', 'vca_basic'],
          estimatedSalaryRange: SalaryRange(min: 2500, max: 3200),
          timeToAchieve: const Duration(days: 180),
        ),
        CareerMilestone(
          level: 3,
          title: 'Professionele Beveiliger',
          requiredCertificates: ['wpbr_b', 'bhv', 'vca_basic'],
          estimatedSalaryRange: SalaryRange(min: 3000, max: 3800),
          timeToAchieve: const Duration(days: 365),
        ),
        CareerMilestone(
          level: 4,
          title: 'Beveiligingsspecialist',
          requiredCertificates: ['wpbr_b', 'persoonbeveiliging', 'bhv', 'vca_basic'],
          estimatedSalaryRange: SalaryRange(min: 3500, max: 4500),
          timeToAchieve: const Duration(days: 730),
        ),
      ],
    ));

    // Event Security Specialist Path
    paths.add(CareerPath(
      id: 'event_security_specialist',
      name: 'Evenement Beveiligingsspecialist',
      description: 'Specialiseer in evenementen, festivals en crowd control',
      category: 'event_security',
      estimatedDuration: const Duration(days: 365),
      prerequisites: ['wpbr_a'],
      milestones: [
        CareerMilestone(
          level: 1,
          title: 'Evenement Beveiliger',
          requiredCertificates: ['wpbr_a', 'bhv'],
          estimatedSalaryRange: SalaryRange(min: 2400, max: 3000),
          timeToAchieve: const Duration(days: 90),
        ),
        CareerMilestone(
          level: 2,
          title: 'Crowd Control Specialist',
          requiredCertificates: ['wpbr_b', 'bhv', 'ehbo'],
          estimatedSalaryRange: SalaryRange(min: 3000, max: 3600),
          timeToAchieve: const Duration(days: 365),
        ),
      ],
    ));

    return paths;
  }

  /// Get critical certificate recommendations
  Future<List<CertificateRecommendation>> _getCriticalCertificateRecommendations(
    String userId,
    List<String> userCertificateIds,
    MarketAnalysisData marketAnalysis
  ) async {
    final recommendations = <CertificateRecommendation>[];

    // Check if user has mandatory WPBR certificate
    if (!userCertificateIds.contains('wpbr_a') && !userCertificateIds.contains('wpbr_b')) {
      recommendations.add(CertificateRecommendation(
        certificateId: 'wpbr_a',
        priority: RequirementPriority.mandatory,
        potentialScoreImprovement: 50,
        reason: 'WPBR Diploma A is verplicht voor alle beveiligingsfuncties in Nederland',
        estimatedTimeToObtain: const Duration(days: 30),
        estimatedCost: 450.0,
        urgencyScore: 100,
        trainingProviders: ['Politie Nederland', 'ROC Nederland'],
        metadata: {
          'category': 'mandatory',
          'legalRequirement': true,
        },
      ));
    }

    // Check for high-demand certificates user is missing
    for (final certId in marketAnalysis.topDemandCertificates.take(5)) {
      if (!userCertificateIds.contains(certId)) {
        final certificate = CertificateRegistry.getCertificateById(certId);
        if (certificate != null) {
          final marketData = marketAnalysis.getCertificateData(certId);
          final scoreImpact = _calculateScoreImpact(certId, marketData);
          
          recommendations.add(CertificateRecommendation(
            certificateId: certId,
            priority: RequirementPriority.preferred,
            potentialScoreImprovement: scoreImpact,
            reason: 'Hoge vraag in de markt - aanwezig in ${marketData?.jobCount ?? 0} recente vacatures',
            estimatedTimeToObtain: _getEstimatedTimeToObtain(certId),
            estimatedCost: _getEstimatedCost(certId),
            urgencyScore: _calculateUrgencyScore(certId, marketData),
            trainingProviders: await _getTrainingProviders(certId),
            metadata: {
              'category': 'market_demand',
              'demandScore': marketData?.demandScore ?? 0,
              'avgSalaryImpact': marketData?.avgSalaryImpact ?? 0,
            },
          ));
        }
      }
    }

    return recommendations;
  }

  /// Get career advancement recommendations
  Future<List<CertificateRecommendation>> _getCareerAdvancementRecommendations(
    List<String> userCertificateIds,
    List<CareerPath> careerPaths,
    MarketAnalysisData marketAnalysis
  ) async {
    final recommendations = <CertificateRecommendation>[];

    for (final path in careerPaths) {
      final nextMilestone = _getNextMilestone(path, userCertificateIds);
      if (nextMilestone != null) {
        final missingCerts = nextMilestone.requiredCertificates
            .where((certId) => !userCertificateIds.contains(certId))
            .toList();

        for (final certId in missingCerts.take(2)) { // Limit to 2 per path
          final certificate = CertificateRegistry.getCertificateById(certId);
          if (certificate != null) {
            final salaryIncrease = _calculateSalaryIncrease(path, nextMilestone, userCertificateIds);
            
            recommendations.add(CertificateRecommendation(
              certificateId: certId,
              priority: RequirementPriority.preferred,
              potentialScoreImprovement: _calculateScoreImpact(certId, marketAnalysis.getCertificateData(certId)),
              reason: 'Vereist voor ${nextMilestone.title} in carrièrepad "${path.name}"',
              estimatedTimeToObtain: _getEstimatedTimeToObtain(certId),
              estimatedCost: _getEstimatedCost(certId),
              urgencyScore: 60,
              trainingProviders: await _getTrainingProviders(certId),
              metadata: {
                'category': 'career_advancement',
                'careerPath': path.name,
                'milestone': nextMilestone.title,
                'salaryIncrease': salaryIncrease,
              },
            ));
          }
        }
      }
    }

    return recommendations;
  }

  /// Get market opportunity recommendations
  Future<List<CertificateRecommendation>> _getMarketOpportunityRecommendations(
    List<String> userCertificateIds,
    MarketAnalysisData marketAnalysis
  ) async {
    final recommendations = <CertificateRecommendation>[];

    // Look for certificates that have high ROI based on market analysis
    final potentialCerts = CertificateRegistry.getAllCertificates()
        .where((cert) => !userCertificateIds.contains(cert.id))
        .toList();

    for (final cert in potentialCerts) {
      final marketData = marketAnalysis.getCertificateData(cert.id);
      if (marketData != null && marketData.demandScore > 0) {
        final estimatedCost = _getEstimatedCost(cert.id);
        final roi = _calculateROI(marketData, estimatedCost);
        
        if (roi > 0.5) { // Good ROI threshold
          recommendations.add(CertificateRecommendation(
            certificateId: cert.id,
            priority: RequirementPriority.advantageous,
            potentialScoreImprovement: _calculateScoreImpact(cert.id, marketData),
            reason: 'Goede marktmogelijkheden - ROI van ${roi.toStringAsFixed(1)}',
            estimatedTimeToObtain: _getEstimatedTimeToObtain(cert.id),
            estimatedCost: estimatedCost,
            urgencyScore: (roi * 50).round().clamp(0, 100),
            trainingProviders: await _getTrainingProviders(cert.id),
            metadata: {
              'category': 'market_opportunity',
              'roi': roi,
              'demandScore': marketData.demandScore,
            },
          ));
        }
      }
    }

    return recommendations;
  }

  /// Get renewal recommendations for expiring certificates
  Future<List<CertificateRecommendation>> _getRenewalRecommendations(
    List<UserCertificate> userCertificates
  ) async {
    final recommendations = <CertificateRecommendation>[];

    final sixMonthsFromNow = DateTime.now().add(const Duration(days: 180));
    
    for (final userCert in userCertificates) {
      if (userCert.expiryDate.isBefore(sixMonthsFromNow)) {
        final certificate = CertificateRegistry.getCertificateById(userCert.certificateId);
        if (certificate != null) { // All certificates can be renewed
          final daysUntilExpiry = userCert.expiryDate.difference(DateTime.now()).inDays;
          
          recommendations.add(CertificateRecommendation(
            certificateId: userCert.certificateId,
            priority: RequirementPriority.mandatory,
            potentialScoreImprovement: 0, // No improvement, just maintaining
            reason: 'Certificaat verloopt over $daysUntilExpiry dagen - vernieuwing vereist',
            estimatedTimeToObtain: _getRenewalTime(userCert.certificateId),
            estimatedCost: _getRenewalCost(userCert.certificateId),
            urgencyScore: _calculateRenewalUrgency(daysUntilExpiry),
            trainingProviders: await _getTrainingProviders(userCert.certificateId),
            metadata: {
              'category': 'renewal',
              'expiryDate': userCert.expiryDate.toIso8601String(),
              'daysUntilExpiry': daysUntilExpiry,
            },
          ));
        }
      }
    }

    return recommendations;
  }

  /// Rank and filter recommendations
  List<CertificateRecommendation> _rankRecommendations(
    List<CertificateRecommendation> recommendations,
    List<String> userCertificateIds,
    MarketAnalysisData marketAnalysis,
    int maxRecommendations
  ) {
    // Remove duplicates
    final uniqueRecommendations = <String, CertificateRecommendation>{};
    for (final rec in recommendations) {
      final existing = uniqueRecommendations[rec.certificateId];
      if (existing == null || rec.urgencyScore > existing.urgencyScore) {
        uniqueRecommendations[rec.certificateId] = rec;
      }
    }

    // Sort by priority and urgency score
    final sortedRecommendations = uniqueRecommendations.values.toList()
      ..sort((a, b) {
        // Mandatory first
        if (a.priority == RequirementPriority.mandatory && b.priority != RequirementPriority.mandatory) {
          return -1;
        }
        if (b.priority == RequirementPriority.mandatory && a.priority != RequirementPriority.mandatory) {
          return 1;
        }
        
        // Then by urgency score
        return b.urgencyScore.compareTo(a.urgencyScore);
      });

    return sortedRecommendations.take(maxRecommendations).toList();
  }

  /// Enrich recommendations with training provider information
  Future<List<CertificateRecommendation>> _enrichWithTrainingProviders(
    List<CertificateRecommendation> recommendations
  ) async {
    final enrichedRecommendations = <CertificateRecommendation>[];

    for (final rec in recommendations) {
      final providers = await _getDetailedTrainingProviders(rec.certificateId);
      final nextCourse = await _getNextAvailableCourse(rec.certificateId);
      
      enrichedRecommendations.add(CertificateRecommendation(
        certificateId: rec.certificateId,
        priority: rec.priority,
        potentialScoreImprovement: rec.potentialScoreImprovement,
        reason: rec.reason,
        estimatedTimeToObtain: rec.estimatedTimeToObtain,
        estimatedCost: rec.estimatedCost,
        trainingProviders: providers,
        prerequisites: _getPrerequisites(rec.certificateId),
        nextAvailableCourse: nextCourse,
        urgencyScore: rec.urgencyScore,
        metadata: rec.metadata,
      ));
    }

    return enrichedRecommendations;
  }

  /// Helper methods for calculations

  Duration _getEstimatedTimeToObtain(String certificateId) {
    const timeMap = {
      'wpbr_a': Duration(days: 30),
      'wpbr_b': Duration(days: 60),
      'bhv': Duration(days: 1),
      'ehbo': Duration(days: 2),
      'vca_basic': Duration(days: 1),
      'portier': Duration(days: 14),
      'persoonbeveiliging': Duration(days: 90),
      'rijbewijs_b': Duration(days: 90),
    };
    
    return timeMap[certificateId] ?? const Duration(days: 30);
  }

  double _getEstimatedCost(String certificateId) {
    const costMap = {
      'wpbr_a': 450.0,
      'wpbr_b': 750.0,
      'bhv': 150.0,
      'ehbo': 125.0,
      'vca_basic': 85.0,
      'portier': 350.0,
      'persoonbeveiliging': 1200.0,
      'rijbewijs_b': 1500.0,
    };
    
    return costMap[certificateId] ?? 200.0;
  }

  Duration _getRenewalTime(String certificateId) {
    // Renewal typically takes less time
    return Duration(milliseconds: (_getEstimatedTimeToObtain(certificateId).inMilliseconds * 0.5).round());
  }

  double _getRenewalCost(String certificateId) {
    // Renewal typically costs less
    return _getEstimatedCost(certificateId) * 0.7;
  }

  int _calculateScoreImpact(String certificateId, CertificateMarketData? marketData) {
    final certificate = CertificateRegistry.getCertificateById(certificateId);
    if (certificate == null) return 10;
    
    int impact = certificate.matchWeight ~/ 2; // Base impact
    
    if (marketData != null) {
      impact += (marketData.demandScore / 10).round(); // Market demand bonus
    }
    
    return impact.clamp(5, 50);
  }

  int _calculateUrgencyScore(String certificateId, CertificateMarketData? marketData) {
    final certificate = CertificateRegistry.getCertificateById(certificateId);
    if (certificate == null) return 30;
    
    int urgency = certificate.isMandatory ? 80 : 40;
    
    if (marketData != null) {
      urgency += (marketData.demandScore / 20).round();
    }
    
    return urgency.clamp(0, 100);
  }

  int _calculateRenewalUrgency(int daysUntilExpiry) {
    if (daysUntilExpiry <= 7) return 100;
    if (daysUntilExpiry <= 30) return 90;
    if (daysUntilExpiry <= 90) return 70;
    return 50;
  }

  double _calculateROI(CertificateMarketData marketData, double cost) {
    if (cost <= 0) return 0.0;
    
    final monthlyImpact = marketData.avgSalaryImpact / 12; // Monthly salary impact
    final yearlyROI = (monthlyImpact * 12) / cost;
    
    return yearlyROI;
  }

  CareerMilestone? _getNextMilestone(CareerPath path, List<String> userCertificateIds) {
    for (final milestone in path.milestones) {
      final hasAllRequired = milestone.requiredCertificates
          .every((certId) => userCertificateIds.contains(certId));
      
      if (!hasAllRequired) {
        return milestone;
      }
    }
    return null;
  }

  double _calculateSalaryIncrease(CareerPath path, CareerMilestone milestone, List<String> userCertificateIds) {
    // Find current milestone
    CareerMilestone? currentMilestone;
    for (final m in path.milestones) {
      final hasAllRequired = m.requiredCertificates.every((certId) => userCertificateIds.contains(certId));
      if (hasAllRequired) {
        currentMilestone = m;
      } else {
        break;
      }
    }
    
    if (currentMilestone == null) return milestone.estimatedSalaryRange.max;
    
    return milestone.estimatedSalaryRange.max - currentMilestone.estimatedSalaryRange.max;
  }

  Future<List<String>> _getTrainingProviders(String certificateId) async {
    try {
      final snapshot = await _trainingProvidersCollection
          .where('certificatesOffered', arrayContains: certificateId)
          .limit(5)
          .get();

      return snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String)
          .toList();
    } catch (e) {
      return _getDefaultTrainingProviders(certificateId);
    }
  }

  List<String> _getDefaultTrainingProviders(String certificateId) {
    const providerMap = {
      'wpbr_a': ['Politie Nederland', 'ROC Nederland'],
      'wpbr_b': ['Politie Nederland', 'ROC Nederland'],
      'bhv': ['Oranje Kruis', 'Rode Kruis Nederland'],
      'ehbo': ['Rode Kruis Nederland', 'Oranje Kruis'],
      'vca_basic': ['SSVV', 'ROC Nederland'],
      'portier': ['ROC Nederland', 'PBWO'],
      'persoonbeveiliging': ['Politie Nederland', 'Specialized Security Training'],
    };
    
    return providerMap[certificateId] ?? ['ROC Nederland'];
  }

  Future<List<String>> _getDetailedTrainingProviders(String certificateId) async {
    return await _getTrainingProviders(certificateId);
  }

  Future<String?> _getNextAvailableCourse(String certificateId) async {
    // Mock implementation - in production, integrate with training provider APIs
    final nextMonth = DateTime.now().add(const Duration(days: 30));
    return '${nextMonth.day}/${nextMonth.month}/${nextMonth.year}';
  }

  List<String> _getPrerequisites(String certificateId) {
    // Prerequisites removed in optimized model - using simple mapping
    const prerequisiteMap = {
      'wpbr_b': ['wpbr_a'], // WPBR B requires WPBR A
      'persoonbeveiliging': ['wpbr_b'], // Personal protection requires WPBR B
    };
    return prerequisiteMap[certificateId] ?? [];
  }
}

/// Recommendation context for targeted suggestions
enum RecommendationContext {
  general('general', 'Algemeen'),
  security('security', 'Beveiliging'),
  eventSecurity('event_security', 'Evenement Beveiliging'),
  industrialSecurity('industrial_security', 'Industriële Beveiliging'),
  personalProtection('personal_protection', 'Persoonbeveiliging'),
  careerAdvancement('career_advancement', 'Carrière Ontwikkeling');

  const RecommendationContext(this.code, this.dutchName);

  final String code;
  final String dutchName;
}

/// Personalized recommendation result
class PersonalizedRecommendationResult {
  final String userId;
  final RecommendationContext context;
  final List<CertificateRecommendation> recommendations;
  final MarketAnalysisData marketAnalysis;
  final List<CareerPath> careerPaths;
  final DateTime generatedAt;
  final DateTime? validUntil;
  final String? error;

  PersonalizedRecommendationResult({
    required this.userId,
    required this.context,
    required this.recommendations,
    required this.marketAnalysis,
    required this.careerPaths,
    required this.generatedAt,
    this.validUntil,
    this.error,
  });

  /// Get recommendations by category
  List<CertificateRecommendation> getRecommendationsByCategory(String category) {
    return recommendations
        .where((rec) => rec.metadata['category'] == category)
        .toList();
  }

  /// Get critical recommendations (mandatory + high urgency)
  List<CertificateRecommendation> get criticalRecommendations {
    return recommendations
        .where((rec) => rec.priority == RequirementPriority.mandatory || rec.urgencyScore >= 80)
        .toList();
  }

  /// Get quick wins (low effort, high impact)
  List<CertificateRecommendation> get quickWins {
    return recommendations
        .where((rec) => 
            rec.estimatedTimeToObtain != null && 
            rec.estimatedTimeToObtain!.inDays <= 7 &&
            rec.potentialScoreImprovement >= 15)
        .toList();
  }
}

/// Market analysis data
class MarketAnalysisData {
  final RecommendationContext context;
  final List<CertificateMarketData> certificateMarketData;
  final int totalJobsAnalyzed;
  final double averageSalary;
  final List<String> topDemandCertificates;
  final DateTime generatedAt;

  MarketAnalysisData({
    required this.context,
    required this.certificateMarketData,
    required this.totalJobsAnalyzed,
    required this.averageSalary,
    required this.topDemandCertificates,
    required this.generatedAt,
  });

  factory MarketAnalysisData.empty() => MarketAnalysisData(
    context: RecommendationContext.general,
    certificateMarketData: [],
    totalJobsAnalyzed: 0,
    averageSalary: 0.0,
    topDemandCertificates: [],
    generatedAt: DateTime.now(),
  );

  CertificateMarketData? getCertificateData(String certificateId) {
    return certificateMarketData
        .cast<CertificateMarketData?>()
        .firstWhere((data) => data?.certificateId == certificateId, orElse: () => null);
  }
}

/// Market data for individual certificate
class CertificateMarketData {
  final String certificateId;
  final int demandScore;
  final double avgSalaryImpact;
  final int jobCount;
  final TrendDirection trendDirection;

  CertificateMarketData({
    required this.certificateId,
    required this.demandScore,
    required this.avgSalaryImpact,
    required this.jobCount,
    required this.trendDirection,
  });

  CertificateMarketData copyWith({
    String? certificateId,
    int? demandScore,
    double? avgSalaryImpact,
    int? jobCount,
    TrendDirection? trendDirection,
  }) {
    return CertificateMarketData(
      certificateId: certificateId ?? this.certificateId,
      demandScore: demandScore ?? this.demandScore,
      avgSalaryImpact: avgSalaryImpact ?? this.avgSalaryImpact,
      jobCount: jobCount ?? this.jobCount,
      trendDirection: trendDirection ?? this.trendDirection,
    );
  }
}

/// Trend direction
enum TrendDirection { rising, stable, declining }

/// Career path model
class CareerPath {
  final String id;
  final String name;
  final String description;
  final String category;
  final Duration estimatedDuration;
  final List<String> prerequisites;
  final List<CareerMilestone> milestones;

  CareerPath({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.estimatedDuration,
    required this.prerequisites,
    required this.milestones,
  });

  factory CareerPath.fromJson(Map<String, dynamic> json) => CareerPath(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    category: json['category'] ?? '',
    estimatedDuration: Duration(days: json['estimatedDurationDays'] ?? 365),
    prerequisites: List<String>.from(json['prerequisites'] ?? []),
    milestones: (json['milestones'] as List<dynamic>?)
        ?.map((m) => CareerMilestone.fromJson(m))
        .toList() ?? [],
  );
}

/// Career milestone
class CareerMilestone {
  final int level;
  final String title;
  final List<String> requiredCertificates;
  final SalaryRange estimatedSalaryRange;
  final Duration timeToAchieve;

  CareerMilestone({
    required this.level,
    required this.title,
    required this.requiredCertificates,
    required this.estimatedSalaryRange,
    required this.timeToAchieve,
  });

  factory CareerMilestone.fromJson(Map<String, dynamic> json) => CareerMilestone(
    level: json['level'] ?? 1,
    title: json['title'] ?? '',
    requiredCertificates: List<String>.from(json['requiredCertificates'] ?? []),
    estimatedSalaryRange: SalaryRange.fromJson(json['estimatedSalaryRange'] ?? {}),
    timeToAchieve: Duration(days: json['timeToAchieveDays'] ?? 0),
  );
}

/// Salary range
class SalaryRange {
  final double min;
  final double max;

  SalaryRange({required this.min, required this.max});

  factory SalaryRange.fromJson(Map<String, dynamic> json) => SalaryRange(
    min: (json['min'] as num?)?.toDouble() ?? 0.0,
    max: (json['max'] as num?)?.toDouble() ?? 0.0,
  );
}