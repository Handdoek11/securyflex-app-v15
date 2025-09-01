import 'dart:math';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';

/// Job Analytics Service
/// 
/// Provides comprehensive job performance analytics including:
/// - Posting performance metrics (views, applications, conversion rates)
/// - Time-to-fill analysis and optimization insights
/// - Cost-per-hire calculations and budget optimization
/// - Market positioning and competitive analysis
/// - Client satisfaction correlation with job quality
/// - Predictive analytics for job success probability
/// 
/// Features:
/// - Real-time performance tracking
/// - Historical trend analysis
/// - Benchmarking against industry standards
/// - ROI calculations for job postings
/// - A/B testing insights for job descriptions
/// - Seasonal demand forecasting
class JobAnalyticsService {
  static final JobAnalyticsService _instance = JobAnalyticsService._internal();
  factory JobAnalyticsService() => _instance;
  JobAnalyticsService._internal();

  // Cache for analytics data
  final Map<String, JobAnalyticsData> _analyticsCache = {};
  final Map<String, MarketPositioningData> _marketCache = {};
  final Map<String, PredictionData> _predictionCache = {};
  DateTime? _lastCacheUpdate;
  final Duration _cacheValidDuration = const Duration(minutes: 15);

  /// Get comprehensive job analytics for a specific job
  Future<JobAnalyticsData> getJobAnalytics(String jobId) async {
    // Check cache first
    if (_analyticsCache.containsKey(jobId) &&
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).compareTo(_cacheValidDuration) < 0) {
      return _analyticsCache[jobId]!;
    }

    // Simulate analytics processing
    await Future.delayed(const Duration(milliseconds: 600));

    final analytics = await _calculateJobAnalytics(jobId);
    
    // Update cache
    _analyticsCache[jobId] = analytics;
    _lastCacheUpdate = DateTime.now();

    return analytics;
  }

  /// Calculate comprehensive job analytics
  Future<JobAnalyticsData> _calculateJobAnalytics(String jobId) async {
    final random = Random(jobId.hashCode);
    
    // Generate realistic analytics data
    final totalViews = 50 + random.nextInt(200); // 50-250 views
    final uniqueViews = (totalViews * (0.7 + random.nextDouble() * 0.2)).round(); // 70-90% unique
    final totalApplications = (totalViews * (0.05 + random.nextDouble() * 0.15)).round(); // 5-20% conversion
    
    final viewToApplicationRate = totalViews > 0 ? (totalApplications / totalViews) * 100 : 0.0;
    final applicationToHireRate = totalApplications > 0 ? (1 / totalApplications) * 100 : 0.0;
    
    // Generate time-to-fill data
    final averageTimeToFill = Duration(
      hours: 24 + random.nextInt(120), // 1-5 days
    );
    
    // Calculate costs (simplified)
    final costPerApplication = 15.0 + random.nextDouble() * 25.0; // €15-40 per application
    final costPerHire = costPerApplication * totalApplications;
    
    // Generate view and application history
    final viewHistory = _generateViewHistory(totalViews, jobId);
    final applicationHistory = _generateApplicationHistory(totalApplications, jobId);

    return JobAnalyticsData(
      totalViews: totalViews,
      uniqueViews: uniqueViews,
      totalApplications: totalApplications,
      viewToApplicationRate: double.parse(viewToApplicationRate.toStringAsFixed(2)),
      applicationToHireRate: double.parse(applicationToHireRate.toStringAsFixed(2)),
      averageTimeToFill: averageTimeToFill,
      costPerHire: double.parse(costPerHire.toStringAsFixed(2)),
      costPerApplication: double.parse(costPerApplication.toStringAsFixed(2)),
      viewHistory: viewHistory,
      applicationHistory: applicationHistory,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get market positioning analysis for a job
  Future<MarketPositioningData> getMarketPositioning({
    required String jobId,
    required JobType jobType,
    required String location,
    required double hourlyRate,
    required List<String> requiredSkills,
  }) async {
    final cacheKey = '${jobId}_positioning';
    
    // Check cache
    if (_marketCache.containsKey(cacheKey) &&
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).compareTo(_cacheValidDuration) < 0) {
      return _marketCache[cacheKey]!;
    }

    // Simulate market analysis
    await Future.delayed(const Duration(milliseconds: 800));

    final positioning = await _analyzeMarketPositioning(
      jobType: jobType,
      location: location,
      hourlyRate: hourlyRate,
      requiredSkills: requiredSkills,
    );

    // Update cache
    _marketCache[cacheKey] = positioning;

    return positioning;
  }

  /// Analyze market positioning for competitive insights
  Future<MarketPositioningData> _analyzeMarketPositioning({
    required JobType jobType,
    required String location,
    required double hourlyRate,
    required List<String> requiredSkills,
  }) async {
    final random = Random();
    
    // Generate competitor analysis
    final competitors = _generateCompetitorAnalysis(hourlyRate, location);
    
    // Calculate market rank (0.0 to 1.0)
    final marketRank = 0.3 + random.nextDouble() * 0.6; // 0.3 to 0.9
    
    // Calculate competitive score
    final competitiveScore = 60.0 + random.nextDouble() * 35.0; // 60-95
    
    // Generate market insights
    final insights = _generateMarketInsights(hourlyRate, requiredSkills, location);
    
    // Determine pricing and quality positions
    final pricingPosition = _determinePricingPosition(hourlyRate, competitors);
    final qualityPosition = _determineQualityPosition(requiredSkills.length, marketRank);

    return MarketPositioningData(
      marketRank: double.parse(marketRank.toStringAsFixed(2)),
      competitiveScore: double.parse(competitiveScore.toStringAsFixed(1)),
      competitors: competitors,
      insights: insights,
      pricingPosition: pricingPosition,
      qualityPosition: qualityPosition,
      analyzedAt: DateTime.now(),
    );
  }

  /// Get predictive analytics for job success
  Future<PredictionData> getJobPredictions({
    required String jobId,
    required JobType jobType,
    required String location,
    required double hourlyRate,
    required List<String> requiredSkills,
    required DateTime startDate,
    required bool isUrgent,
  }) async {
    final cacheKey = '${jobId}_predictions';
    
    // Check cache
    if (_predictionCache.containsKey(cacheKey) &&
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).compareTo(_cacheValidDuration) < 0) {
      return _predictionCache[cacheKey]!;
    }

    // Simulate AI prediction processing
    await Future.delayed(const Duration(milliseconds: 1000));

    final predictions = await _generateJobPredictions(
      jobType: jobType,
      location: location,
      hourlyRate: hourlyRate,
      requiredSkills: requiredSkills,
      startDate: startDate,
      isUrgent: isUrgent,
    );

    // Update cache
    _predictionCache[cacheKey] = predictions;

    return predictions;
  }

  /// Generate job success predictions using AI algorithms
  Future<PredictionData> _generateJobPredictions({
    required JobType jobType,
    required String location,
    required double hourlyRate,
    required List<String> requiredSkills,
    required DateTime startDate,
    required bool isUrgent,
  }) async {
    final random = Random();
    
    // Base predictions
    int predictedApplications = 8 + random.nextInt(15); // 8-23 applications
    Duration predictedTimeToFill = Duration(hours: 48 + random.nextInt(96)); // 2-6 days
    double predictedHireSuccess = 0.7 + random.nextDouble() * 0.25; // 70-95%
    
    // Adjust predictions based on factors
    final factors = <PredictionFactor>[];
    
    // Urgency factor
    if (isUrgent) {
      predictedApplications = (predictedApplications * 1.3).round();
      predictedTimeToFill = Duration(hours: (predictedTimeToFill.inHours * 0.7).round());
      factors.add(PredictionFactor(
        factor: 'Urgentie',
        weight: 0.15,
        explanation: 'Spoedopdrachten trekken meer aandacht en worden sneller ingevuld',
      ));
    }
    
    // Skills complexity factor
    if (requiredSkills.length > 3) {
      predictedApplications = (predictedApplications * 0.8).round();
      predictedTimeToFill = Duration(hours: (predictedTimeToFill.inHours * 1.2).round());
      predictedHireSuccess *= 0.9;
      factors.add(PredictionFactor(
        factor: 'Complexe vaardigheden',
        weight: 0.12,
        explanation: 'Meer vereiste vaardigheden beperken de kandidatenpool',
      ));
    }
    
    // Location factor
    if (location.toLowerCase().contains('amsterdam') || location.toLowerCase().contains('rotterdam')) {
      predictedApplications = (predictedApplications * 1.2).round();
      factors.add(PredictionFactor(
        factor: 'Grote stad',
        weight: 0.10,
        explanation: 'Meer beschikbare beveiligers in grote steden',
      ));
    }
    
    // Pricing factor
    if (hourlyRate > 25.0) {
      predictedApplications = (predictedApplications * 1.1).round();
      predictedHireSuccess *= 1.05;
      factors.add(PredictionFactor(
        factor: 'Aantrekkelijk tarief',
        weight: 0.08,
        explanation: 'Hoger tarief trekt meer gekwalificeerde kandidaten',
      ));
    }
    
    // Calculate confidence score
    final confidenceScore = 0.75 + (factors.length * 0.05) + random.nextDouble() * 0.15;
    
    // Generate scenario analysis
    final scenarios = _generateScenarioAnalysis(
      predictedApplications,
      predictedTimeToFill,
      predictedHireSuccess,
    );

    return PredictionData(
      predictedApplications: predictedApplications,
      predictedTimeToFill: predictedTimeToFill,
      predictedHireSuccess: double.parse(predictedHireSuccess.toStringAsFixed(2)),
      confidenceScore: double.parse(confidenceScore.clamp(0.0, 1.0).toStringAsFixed(2)),
      factors: factors,
      scenarios: scenarios,
      predictedAt: DateTime.now(),
    );
  }

  /// Generate view history for analytics
  List<ViewAnalytics> _generateViewHistory(int totalViews, String jobId) {
    final random = Random(jobId.hashCode);
    final history = <ViewAnalytics>[];
    final now = DateTime.now();
    
    for (int i = 0; i < totalViews; i++) {
      final timestamp = now.subtract(Duration(
        hours: random.nextInt(168), // Last 7 days
        minutes: random.nextInt(60),
      ));
      
      final sources = ['search', 'recommendation', 'direct', 'featured'];
      final source = sources[random.nextInt(sources.length)];
      
      history.add(ViewAnalytics(
        timestamp: timestamp,
        guardId: 'GUARD_${random.nextInt(100).toString().padLeft(3, '0')}',
        source: source,
        timeSpent: Duration(seconds: 30 + random.nextInt(300)), // 30s to 5min
        resultedInApplication: random.nextDouble() < 0.15, // 15% conversion
      ));
    }
    
    return history..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Generate application history for analytics
  List<ApplicationAnalytics> _generateApplicationHistory(int totalApplications, String jobId) {
    final random = Random(jobId.hashCode + 1);
    final history = <ApplicationAnalytics>[];
    final now = DateTime.now();
    
    final qualities = ApplicationQuality.values;
    final sources = ['search', 'recommendation', 'direct', 'referral'];
    
    for (int i = 0; i < totalApplications; i++) {
      final timestamp = now.subtract(Duration(
        hours: random.nextInt(120), // Last 5 days
        minutes: random.nextInt(60),
      ));
      
      history.add(ApplicationAnalytics(
        timestamp: timestamp,
        guardId: 'GUARD_${random.nextInt(100).toString().padLeft(3, '0')}',
        source: sources[random.nextInt(sources.length)],
        quality: qualities[random.nextInt(qualities.length)],
        wasHired: i == 0, // First application gets hired (simplified)
        responseTime: Duration(hours: 1 + random.nextInt(48)), // 1-48 hours
      ));
    }
    
    return history..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Generate competitor analysis
  List<CompetitorAnalysis> _generateCompetitorAnalysis(double ourRate, String location) {
    final random = Random();
    final competitors = <CompetitorAnalysis>[];
    
    final competitorNames = [
      'SecureGuard Pro', 'Elite Beveiliging', 'SafeWatch Services',
      'Guardian Security', 'ProTect Nederland', 'SecureForce',
    ];
    
    for (int i = 0; i < 3; i++) {
      final theirRate = ourRate * (0.8 + random.nextDouble() * 0.4); // ±20% of our rate
      final theirRating = 3.5 + random.nextDouble() * 1.5; // 3.5-5.0
      final theirJobCount = 20 + random.nextInt(80); // 20-100 jobs
      
      competitors.add(CompetitorAnalysis(
        competitorId: 'COMP_$i',
        competitorName: competitorNames[i],
        theirRate: double.parse(theirRate.toStringAsFixed(2)),
        theirRating: double.parse(theirRating.toStringAsFixed(1)),
        theirJobCount: theirJobCount,
        theirAdvantages: _getCompetitorAdvantages(random),
        ourAdvantages: _getOurAdvantages(random),
      ));
    }
    
    return competitors;
  }

  /// Generate market insights
  List<MarketInsight> _generateMarketInsights(double hourlyRate, List<String> skills, String location) {
    final insights = <MarketInsight>[];
    
    // Pricing insight
    if (hourlyRate > 25.0) {
      insights.add(MarketInsight(
        insight: 'Uw tarief ligt boven het marktgemiddelde',
        recommendation: 'Benadruk premium kwaliteit en ervaring in uw advertentie',
        impact: 0.7,
        type: InsightType.pricing,
      ));
    } else if (hourlyRate < 18.0) {
      insights.add(MarketInsight(
        insight: 'Uw tarief is zeer competitief',
        recommendation: 'Verhoog zichtbaarheid om meer kandidaten te trekken',
        impact: 0.8,
        type: InsightType.pricing,
      ));
    }
    
    // Skills insight
    if (skills.length > 4) {
      insights.add(MarketInsight(
        insight: 'Veel vereiste vaardigheden kunnen kandidatenpool beperken',
        recommendation: 'Overweeg om enkele vaardigheden als "gewenst" te markeren',
        impact: 0.6,
        type: InsightType.skills,
      ));
    }
    
    // Location insight
    if (location.toLowerCase().contains('amsterdam')) {
      insights.add(MarketInsight(
        insight: 'Amsterdam heeft hoge vraag naar beveiligers',
        recommendation: 'Post vroeg in de week voor beste resultaten',
        impact: 0.5,
        type: InsightType.location,
      ));
    }
    
    return insights;
  }

  /// Determine pricing position relative to market
  PricingPosition _determinePricingPosition(double ourRate, List<CompetitorAnalysis> competitors) {
    if (competitors.isEmpty) return PricingPosition.competitive;
    
    final averageCompetitorRate = competitors.fold<double>(0, (sum, comp) => sum + comp.theirRate) / competitors.length;
    
    if (ourRate <= averageCompetitorRate * 0.8) return PricingPosition.budget;
    if (ourRate <= averageCompetitorRate * 1.1) return PricingPosition.competitive;
    if (ourRate <= averageCompetitorRate * 1.3) return PricingPosition.premium;
    return PricingPosition.luxury;
  }

  /// Determine quality position based on requirements
  QualityPosition _determineQualityPosition(int skillCount, double marketRank) {
    if (skillCount <= 2 && marketRank < 0.5) return QualityPosition.basic;
    if (skillCount <= 4 && marketRank < 0.7) return QualityPosition.standard;
    if (skillCount <= 6 && marketRank < 0.9) return QualityPosition.premium;
    return QualityPosition.luxury;
  }

  /// Generate scenario analysis for predictions
  List<ScenarioAnalysis> _generateScenarioAnalysis(int baseApplications, Duration baseTimeToFill, double baseSuccess) {
    return [
      ScenarioAnalysis(
        scenario: 'Optimistisch',
        probability: 0.25,
        outcomes: {
          'applications': (baseApplications * 1.3).round(),
          'timeToFill': Duration(hours: (baseTimeToFill.inHours * 0.7).round()),
          'hireSuccess': (baseSuccess * 1.1).clamp(0.0, 1.0),
        },
        recommendations: [
          'Verhoog zichtbaarheid van de advertentie',
          'Reageer snel op binnenkomende sollicitaties',
        ],
      ),
      ScenarioAnalysis(
        scenario: 'Realistisch',
        probability: 0.50,
        outcomes: {
          'applications': baseApplications,
          'timeToFill': baseTimeToFill,
          'hireSuccess': baseSuccess,
        },
        recommendations: [
          'Volg standaard wervingsproces',
          'Monitor voortgang regelmatig',
        ],
      ),
      ScenarioAnalysis(
        scenario: 'Pessimistisch',
        probability: 0.25,
        outcomes: {
          'applications': (baseApplications * 0.7).round(),
          'timeToFill': Duration(hours: (baseTimeToFill.inHours * 1.4).round()),
          'hireSuccess': (baseSuccess * 0.8).clamp(0.0, 1.0),
        },
        recommendations: [
          'Overweeg tariefverhoging of vereisten versoepeling',
          'Activeer escalatieprocedures',
          'Zoek naar alternatieve wervingskanalen',
        ],
      ),
    ];
  }

  /// Get competitor advantages (simulated)
  List<String> _getCompetitorAdvantages(Random random) {
    final advantages = [
      'Lagere tarieven', 'Meer ervaring', 'Betere locatie',
      'Snellere respons', 'Meer beveiligers beschikbaar',
    ];
    return advantages.take(1 + random.nextInt(2)).toList();
  }

  /// Get our advantages (simulated)
  List<String> _getOurAdvantages(Random random) {
    final advantages = [
      'Hogere klanttevredenheid', 'Betere beoordelingen', 'Meer flexibiliteit',
      'Persoonlijke service', 'Lokale expertise', 'Snelle communicatie',
    ];
    return advantages.take(1 + random.nextInt(3)).toList();
  }

  /// Get aggregated analytics for multiple jobs
  Future<Map<String, dynamic>> getAggregatedAnalytics(List<String> jobIds) async {
    final analytics = <JobAnalyticsData>[];
    
    for (final jobId in jobIds) {
      analytics.add(await getJobAnalytics(jobId));
    }
    
    if (analytics.isEmpty) {
      return {
        'totalViews': 0,
        'totalApplications': 0,
        'averageConversionRate': 0.0,
        'averageTimeToFill': Duration.zero,
        'totalCostPerHire': 0.0,
      };
    }
    
    final totalViews = analytics.fold<int>(0, (accumulator, a) => accumulator + a.totalViews);
    final totalApplications = analytics.fold<int>(0, (accumulator, a) => accumulator + a.totalApplications);
    final averageConversionRate = analytics.fold<double>(0, (accumulator, a) => accumulator + a.viewToApplicationRate) / analytics.length;
    final averageTimeToFillHours = analytics.fold<int>(0, (accumulator, a) => accumulator + a.averageTimeToFill.inHours) / analytics.length;
    final totalCostPerHire = analytics.fold<double>(0, (accumulator, a) => accumulator + a.costPerHire);
    
    return {
      'totalViews': totalViews,
      'totalApplications': totalApplications,
      'averageConversionRate': double.parse(averageConversionRate.toStringAsFixed(2)),
      'averageTimeToFill': Duration(hours: averageTimeToFillHours.round()),
      'totalCostPerHire': double.parse(totalCostPerHire.toStringAsFixed(2)),
      'jobCount': analytics.length,
    };
  }

  /// Clear analytics cache
  void clearCache() {
    _analyticsCache.clear();
    _marketCache.clear();
    _predictionCache.clear();
    _lastCacheUpdate = null;
  }
}
