import 'dart:math';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';

/// Smart Pricing Engine Service
/// 
/// Provides AI-powered pricing recommendations based on:
/// - Location and postal code analysis
/// - Time and date factors (peak hours, weekends, holidays)
/// - Skill requirements and experience levels
/// - Market demand and supply data
/// - Competitor analysis
/// - Historical performance data
/// 
/// Features:
/// - Dynamic rate calculations with confidence scoring
/// - Market positioning analysis
/// - Demand forecasting
/// - Competitive pricing insights
/// - Seasonal trend analysis
class SmartPricingService {
  static final SmartPricingService _instance = SmartPricingService._internal();
  factory SmartPricingService() => _instance;
  SmartPricingService._internal();

  // Cache for pricing data
  final Map<String, SmartPricingData> _pricingCache = {};
  DateTime? _lastCacheUpdate;
  final Duration _cacheValidDuration = const Duration(hours: 1);

  // Base rates for different job types (in EUR per hour)
  static const Map<JobType, double> _baseRates = {
    JobType.objectbeveiliging: 18.50,
    JobType.evenementbeveiliging: 22.00,
    JobType.persoonbeveiliging: 28.00,
    JobType.surveillance: 20.00,
    JobType.receptie: 16.50,
    JobType.transport: 24.00,
  };

  // Location multipliers for Dutch regions
  static const Map<String, double> _locationMultipliers = {
    'Amsterdam': 1.25,
    'Rotterdam': 1.15,
    'Den Haag': 1.20,
    'Utrecht': 1.18,
    'Eindhoven': 1.10,
    'Tilburg': 1.05,
    'Groningen': 1.00,
    'Almere': 1.08,
    'Breda': 1.05,
    'Nijmegen': 1.03,
  };

  /// Get smart pricing recommendations for a job
  Future<SmartPricingData> getSmartPricing({
    required JobType jobType,
    required String location,
    required String postalCode,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> requiredSkills,
    required List<String> requiredCertificates,
    required int minimumExperience,
    bool isUrgent = false,
  }) async {
    // Create cache key
    final cacheKey = _createCacheKey(
      jobType, location, postalCode, startDate, endDate,
      requiredSkills, requiredCertificates, minimumExperience, isUrgent,
    );

    // Check cache first
    if (_pricingCache.containsKey(cacheKey) &&
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).compareTo(_cacheValidDuration) < 0) {
      return _pricingCache[cacheKey]!;
    }

    // Simulate API processing time
    await Future.delayed(const Duration(milliseconds: 800));

    // Calculate smart pricing
    final pricingData = await _calculateSmartPricing(
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

    // Update cache
    _pricingCache[cacheKey] = pricingData;
    _lastCacheUpdate = DateTime.now();

    return pricingData;
  }

  /// Calculate smart pricing based on multiple factors
  Future<SmartPricingData> _calculateSmartPricing({
    required JobType jobType,
    required String location,
    required String postalCode,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> requiredSkills,
    required List<String> requiredCertificates,
    required int minimumExperience,
    required bool isUrgent,
  }) async {

    
    // Get base rate for job type
    final baseRate = _baseRates[jobType] ?? 20.0;
    
    // Calculate all pricing factors
    final factors = <PricingFactor>[];
    double adjustedRate = baseRate;

    // 1. Location factor
    final locationMultiplier = _getLocationMultiplier(location, postalCode);
    adjustedRate *= locationMultiplier;
    factors.add(PricingFactor(
      name: 'Locatie',
      impact: (locationMultiplier - 1.0),
      description: 'Prijsaanpassing voor $location regio',
    ));

    // 2. Time and date factors
    final timeMultiplier = _getTimeMultiplier(startDate, endDate);
    adjustedRate *= timeMultiplier;
    factors.add(PricingFactor(
      name: 'Tijd & Datum',
      impact: (timeMultiplier - 1.0),
      description: _getTimeDescription(startDate, endDate),
    ));

    // 3. Skills and experience factor
    final skillsMultiplier = _getSkillsMultiplier(requiredSkills, requiredCertificates, minimumExperience);
    adjustedRate *= skillsMultiplier;
    factors.add(PricingFactor(
      name: 'Vaardigheden & Ervaring',
      impact: (skillsMultiplier - 1.0),
      description: 'Aanpassing voor ${requiredSkills.length} vaardigheden en $minimumExperience jaar ervaring',
    ));

    // 4. Urgency factor
    if (isUrgent) {
      const urgencyMultiplier = 1.15;
      adjustedRate *= urgencyMultiplier;
      factors.add(PricingFactor(
        name: 'Urgentie',
        impact: (urgencyMultiplier - 1.0),
        description: 'Spoedtoeslag voor urgente opdrachten',
      ));
    }

    // 5. Market demand factor (simulated)
    final demandData = await _getMarketDemandData(location, jobType, startDate);
    final demandMultiplier = 0.9 + (demandData.demandScore * 0.3); // 0.9 to 1.2
    adjustedRate *= demandMultiplier;
    factors.add(PricingFactor(
      name: 'Marktdemand',
      impact: (demandMultiplier - 1.0),
      description: 'Aanpassing op basis van vraag en aanbod',
    ));

    // Calculate different rate tiers
    final recommendedRate = adjustedRate;
    final marketAverageRate = baseRate * 1.05; // Slightly above base
    final competitiveRate = recommendedRate * 0.95; // 5% below recommended
    final premiumRate = recommendedRate * 1.15; // 15% above recommended

    // Determine confidence level
    final confidence = _calculateConfidence(factors, demandData);

    return SmartPricingData(
      recommendedRate: double.parse(recommendedRate.toStringAsFixed(2)),
      marketAverageRate: double.parse(marketAverageRate.toStringAsFixed(2)),
      competitiveRate: double.parse(competitiveRate.toStringAsFixed(2)),
      premiumRate: double.parse(premiumRate.toStringAsFixed(2)),
      confidence: confidence,
      factors: factors,
      demandData: demandData,
      calculatedAt: DateTime.now(),
    );
  }

  /// Get location-based pricing multiplier
  double _getLocationMultiplier(String location, String postalCode) {
    // Check for exact city match
    for (final city in _locationMultipliers.keys) {
      if (location.toLowerCase().contains(city.toLowerCase())) {
        return _locationMultipliers[city]!;
      }
    }

    // Analyze postal code for region-based pricing
    if (postalCode.isNotEmpty && postalCode.length >= 4) {
      final postalPrefix = postalCode.substring(0, 2);
      switch (postalPrefix) {
        case '10': // Amsterdam area
          return 1.25;
        case '30': // Utrecht area
          return 1.18;
        case '20': // Haarlem area
          return 1.15;
        case '25': // Den Haag area
          return 1.20;
        case '31': // Rotterdam area
          return 1.15;
        default:
          return 1.0; // Default multiplier
      }
    }

    return 1.0; // Default multiplier
  }

  /// Get time-based pricing multiplier
  double _getTimeMultiplier(DateTime startDate, DateTime endDate) {
    double multiplier = 1.0;

    // Weekend premium
    if (startDate.weekday >= 6) { // Saturday or Sunday
      multiplier *= 1.2;
    }

    // Evening/night premium (after 18:00 or before 06:00)
    if (startDate.hour >= 18 || startDate.hour < 6) {
      multiplier *= 1.15;
    }

    // Holiday premium (simplified - check for common Dutch holidays)
    if (_isDutchHoliday(startDate)) {
      multiplier *= 1.3;
    }

    // Long duration discount (more than 8 hours)
    final duration = endDate.difference(startDate);
    if (duration.inHours > 8) {
      multiplier *= 0.95; // 5% discount for long shifts
    }

    return multiplier;
  }

  /// Get skills and experience multiplier
  double _getSkillsMultiplier(List<String> skills, List<String> certificates, int experience) {
    double multiplier = 1.0;

    // Experience premium
    multiplier += (experience * 0.02); // 2% per year of experience

    // Skills premium
    multiplier += (skills.length * 0.03); // 3% per required skill

    // Certificate premium
    multiplier += (certificates.length * 0.05); // 5% per required certificate

    // Cap the multiplier at reasonable levels
    return multiplier.clamp(1.0, 1.5);
  }

  /// Get market demand data (simulated)
  Future<MarketDemandData> _getMarketDemandData(String location, JobType jobType, DateTime startDate) async {
    final random = Random();
    
    return MarketDemandData(
      demandScore: 0.3 + random.nextDouble() * 0.7, // 0.3 to 1.0
      competingJobs: 5 + random.nextInt(15), // 5 to 20
      availableGuards: 20 + random.nextInt(30), // 20 to 50
      supplyDemandRatio: 0.5 + random.nextDouble() * 1.0, // 0.5 to 1.5
      peakHours: ['18:00-22:00', '22:00-06:00'],
    );
  }

  /// Calculate confidence level for pricing recommendation
  PricingConfidence _calculateConfidence(List<PricingFactor> factors, MarketDemandData demandData) {
    // Calculate confidence based on data quality and market conditions
    double confidenceScore = 0.7; // Base confidence

    // Adjust based on demand data quality
    if (demandData.supplyDemandRatio > 0.8 && demandData.supplyDemandRatio < 1.2) {
      confidenceScore += 0.2; // Balanced market increases confidence
    }

    // Adjust based on number of factors considered
    confidenceScore += (factors.length * 0.02);

    // Convert to enum
    if (confidenceScore >= 0.9) return PricingConfidence.veryHigh;
    if (confidenceScore >= 0.8) return PricingConfidence.high;
    if (confidenceScore >= 0.6) return PricingConfidence.medium;
    return PricingConfidence.low;
  }

  /// Check if date is a Dutch holiday (simplified)
  bool _isDutchHoliday(DateTime date) {
    // Simplified holiday check - in real implementation, use proper holiday calculation
    final month = date.month;
    final day = date.day;
    
    // New Year's Day
    if (month == 1 && day == 1) return true;
    // King's Day
    if (month == 4 && day == 27) return true;
    // Christmas
    if (month == 12 && (day == 25 || day == 26)) return true;
    
    return false;
  }

  /// Get time description for pricing factor
  String _getTimeDescription(DateTime startDate, DateTime endDate) {
    final isWeekend = startDate.weekday >= 6;
    final isEvening = startDate.hour >= 18 || startDate.hour < 6;
    final isHoliday = _isDutchHoliday(startDate);
    
    if (isHoliday) return 'Feestdagtoeslag toegepast';
    if (isWeekend && isEvening) return 'Weekend- en avondtoeslag';
    if (isWeekend) return 'Weekendtoeslag toegepast';
    if (isEvening) return 'Avond/nachttoeslag toegepast';
    return 'Standaard tariefperiode';
  }

  /// Create cache key for pricing data
  String _createCacheKey(
    JobType jobType, String location, String postalCode,
    DateTime startDate, DateTime endDate,
    List<String> skills, List<String> certificates,
    int experience, bool isUrgent,
  ) {
    return '${jobType.name}_${location}_${postalCode}_'
           '${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}_'
           '${skills.join(',')}_${certificates.join(',')}_'
           '${experience}_$isUrgent';
  }

  /// Clear pricing cache
  void clearCache() {
    _pricingCache.clear();
    _lastCacheUpdate = null;
  }

  /// Get pricing trends for analytics
  Future<Map<String, List<double>>> getPricingTrends(JobType jobType, String location) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final random = Random();
    final baseRate = _baseRates[jobType] ?? 20.0;
    
    // Generate 12 months of pricing trend data
    final trends = List.generate(12, (index) {
      final seasonalFactor = 0.9 + (0.2 * sin((index / 12) * 2 * pi)); // Seasonal variation
      final marketFactor = 0.95 + (random.nextDouble() * 0.1); // Market variation
      return baseRate * seasonalFactor * marketFactor;
    });

    return {
      'recommended_rates': trends,
      'market_averages': trends.map((rate) => rate * 1.05).toList(),
      'competitive_rates': trends.map((rate) => rate * 0.95).toList(),
    };
  }
}
