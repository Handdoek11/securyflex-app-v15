import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:securyflex_app/company_dashboard/models/business_intelligence_data.dart';

/// Client satisfaction analytics service for business intelligence
/// Provides comprehensive client feedback tracking, NPS monitoring, and retention analysis
class ClientSatisfactionService {
  static ClientSatisfactionService? _instance;
  static ClientSatisfactionService get instance {
    _instance ??= ClientSatisfactionService._();
    return _instance!;
  }

  ClientSatisfactionService._();

  // Cache for performance
  List<ClientSatisfactionData>? _cachedClients;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 10);

  // Real-time update stream
  final StreamController<List<ClientSatisfactionData>> _clientsStreamController = 
      StreamController<List<ClientSatisfactionData>>.broadcast();

  /// Stream for real-time client satisfaction updates
  Stream<List<ClientSatisfactionData>> get clientsStream => _clientsStreamController.stream;

  /// Get all client satisfaction data
  Future<List<ClientSatisfactionData>> getClientSatisfactionData(String companyId) async {
    // Check cache first
    if (_cachedClients != null && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!).compareTo(_cacheValidDuration) < 0) {
      return _cachedClients!;
    }

    await Future.delayed(const Duration(milliseconds: 400)); // Simulate API call

    final clients = _generateClientSatisfactionData(companyId);
    
    // Update cache
    _cachedClients = clients;
    _lastCacheUpdate = DateTime.now();

    // Emit to stream for real-time updates
    _clientsStreamController.add(clients);

    return clients;
  }

  /// Get overall Net Promoter Score
  Future<double> getOverallNPS(String companyId) async {
    final clients = await getClientSatisfactionData(companyId);
    
    if (clients.isEmpty) return 0.0;

    final totalNPS = clients.fold<double>(0.0, (sum, client) => sum + client.netPromoterScore);
    return totalNPS / clients.length;
  }

  /// Get clients at risk of churning
  Future<List<ClientSatisfactionData>> getClientsAtRisk(String companyId) async {
    final clients = await getClientSatisfactionData(companyId);
    
    return clients.where((client) {
      return client.riskLevel == ClientRiskLevel.high || 
             client.riskLevel == ClientRiskLevel.critical ||
             client.retentionProbability < 60.0 ||
             client.averageRating < 3.0;
    }).toList()
      ..sort((a, b) => a.retentionProbability.compareTo(b.retentionProbability));
  }

  /// Get client satisfaction trends over time
  Future<Map<String, List<double>>> getSatisfactionTrends(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock trend data for the last 12 months
    final random = Random();
    final npsTrend = List.generate(12, (i) => -10 + random.nextDouble() * 80); // -10 to 70
    final ratingTrend = List.generate(12, (i) => 3.0 + random.nextDouble() * 2.0); // 3.0 to 5.0
    final retentionTrend = List.generate(12, (i) => 70.0 + random.nextDouble() * 25.0); // 70 to 95

    return {
      'nps_trend': npsTrend,
      'rating_trend': ratingTrend,
      'retention_trend': retentionTrend,
    };
  }

  /// Get common feedback themes analysis
  Future<Map<String, dynamic>> getFeedbackThemes(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 250));

    return {
      'top_complaints': [
        {'theme': 'Communicatie', 'count': 8, 'percentage': 23.5},
        {'theme': 'Punctualiteit', 'count': 6, 'percentage': 17.6},
        {'theme': 'Professionaliteit', 'count': 4, 'percentage': 11.8},
        {'theme': 'Flexibiliteit', 'count': 3, 'percentage': 8.8},
      ],
      'top_praises': [
        {'theme': 'Betrouwbaarheid', 'count': 15, 'percentage': 35.7},
        {'theme': 'Kwaliteit', 'count': 12, 'percentage': 28.6},
        {'theme': 'Vriendelijkheid', 'count': 8, 'percentage': 19.0},
        {'theme': 'Snelle respons', 'count': 7, 'percentage': 16.7},
      ],
      'sentiment_analysis': {
        'positive': 68.5,
        'neutral': 22.1,
        'negative': 9.4,
      },
    };
  }

  /// Get client retention analysis
  Future<Map<String, dynamic>> getRetentionAnalysis(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final clients = await getClientSatisfactionData(companyId);
    
    final totalClients = clients.length;
    final lowRisk = clients.where((c) => c.riskLevel == ClientRiskLevel.low).length;
    final mediumRisk = clients.where((c) => c.riskLevel == ClientRiskLevel.medium).length;
    final highRisk = clients.where((c) => c.riskLevel == ClientRiskLevel.high).length;
    final criticalRisk = clients.where((c) => c.riskLevel == ClientRiskLevel.critical).length;

    final averageRetention = clients.isEmpty ? 0.0 :
        clients.fold<double>(0.0, (sum, c) => sum + c.retentionProbability) / totalClients;

    return {
      'total_clients': totalClients,
      'retention_distribution': {
        'low_risk': lowRisk,
        'medium_risk': mediumRisk,
        'high_risk': highRisk,
        'critical_risk': criticalRisk,
      },
      'average_retention_probability': averageRetention,
      'churn_risk_percentage': ((highRisk + criticalRisk) / totalClients * 100),
      'estimated_revenue_at_risk': _calculateRevenueAtRisk(clients),
      'recommended_actions': _getRetentionRecommendations(clients),
    };
  }

  /// Get client satisfaction benchmarks
  Future<Map<String, dynamic>> getSatisfactionBenchmarks() async {
    await Future.delayed(const Duration(milliseconds: 200));

    return {
      'industry_average_nps': 42.0,
      'our_nps': 58.5,
      'nps_percentile': 78, // Top 22%
      'industry_average_rating': 4.1,
      'our_average_rating': 4.3,
      'industry_retention_rate': 82.5,
      'our_retention_rate': 87.2,
      'benchmark_status': 'Above Average',
    };
  }

  /// Generate mock client satisfaction data
  List<ClientSatisfactionData> _generateClientSatisfactionData(String companyId) {
    final random = Random();
    final clients = <ClientSatisfactionData>[];

    final clientNames = [
      'Retail Group Nederland',
      'Amsterdam Events BV',
      'Security Solutions Ltd',
      'Metro Shopping Center',
      'Corporate Office Park',
      'Festival Productions',
      'Hotel Chain Amsterdam',
      'Banking Services NL',
      'Healthcare Facilities',
      'Educational Institute',
    ];

    final commonComplaints = [
      'Communicatie kan beter',
      'Soms te laat',
      'Meer flexibiliteit gewenst',
      'Rapportage onduidelijk',
    ];

    final commonPraises = [
      'Zeer betrouwbaar',
      'Professionele aanpak',
      'Goede communicatie',
      'Flexibel en meedenkend',
      'Snelle respons',
    ];

    for (int i = 0; i < clientNames.length; i++) {
      final nps = -20 + random.nextDouble() * 90; // -20 to 70
      final rating = 2.5 + random.nextDouble() * 2.5; // 2.5 to 5.0
      final feedbackCount = 5 + random.nextInt(20);
      final positiveReviews = (feedbackCount * (0.4 + random.nextDouble() * 0.5)).round();
      final negativeReviews = (feedbackCount * (0.1 + random.nextDouble() * 0.2)).round();
      final neutralReviews = feedbackCount - positiveReviews - negativeReviews;

      // Calculate retention probability based on rating and NPS
      final retentionBase = ((rating / 5.0) * 50) + ((nps + 100) / 200 * 50);
      final retention = (retentionBase + random.nextDouble() * 20 - 10).clamp(0.0, 100.0);

      // Determine risk level
      ClientRiskLevel riskLevel;
      if (retention > 80) {
        riskLevel = ClientRiskLevel.low;
      } else if (retention > 60) {
        riskLevel = ClientRiskLevel.medium;
      } else if (retention > 40) {
        riskLevel = ClientRiskLevel.high;
      } else {
        riskLevel = ClientRiskLevel.critical;
      }

      clients.add(ClientSatisfactionData(
        clientId: 'CLIENT_${i.toString().padLeft(3, '0')}',
        clientName: clientNames[i],
        netPromoterScore: nps,
        averageRating: rating,
        totalFeedbackCount: feedbackCount,
        positiveReviews: positiveReviews,
        neutralReviews: neutralReviews,
        negativeReviews: negativeReviews,
        retentionProbability: retention,
        commonComplaints: commonComplaints.take(random.nextInt(3) + 1).toList(),
        commonPraises: commonPraises.take(random.nextInt(3) + 1).toList(),
        lastFeedbackDate: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        responseTime: 2.0 + random.nextDouble() * 10.0, // 2-12 hours
        totalJobsCompleted: 10 + random.nextInt(50),
        totalSpent: 5000.0 + random.nextDouble() * 20000.0,
        riskLevel: riskLevel,
      ));
    }

    return clients;
  }

  /// Calculate revenue at risk from potential churn
  double _calculateRevenueAtRisk(List<ClientSatisfactionData> clients) {
    return clients
        .where((c) => c.riskLevel == ClientRiskLevel.high || c.riskLevel == ClientRiskLevel.critical)
        .fold<double>(0.0, (sum, c) => sum + (c.totalSpent * 0.3)); // 30% of annual spend
  }

  /// Get retention recommendations based on client data
  List<String> _getRetentionRecommendations(List<ClientSatisfactionData> clients) {
    final recommendations = <String>[];
    
    final highRiskClients = clients.where((c) => c.riskLevel == ClientRiskLevel.high).length;
    final criticalRiskClients = clients.where((c) => c.riskLevel == ClientRiskLevel.critical).length;

    if (criticalRiskClients > 0) {
      recommendations.add('Onmiddellijk contact opnemen met $criticalRiskClients kritieke klanten');
    }
    
    if (highRiskClients > 0) {
      recommendations.add('Persoonlijke gesprekken plannen met $highRiskClients hoog-risico klanten');
    }

    recommendations.addAll([
      'Verbeter communicatie en rapportage',
      'Implementeer proactieve klantenservice',
      'Organiseer klantentevredenheidsonderzoek',
      'Ontwikkel loyaliteitsprogramma',
    ]);

    return recommendations;
  }

  /// Start real-time client satisfaction monitoring
  void startRealtimeMonitoring(String companyId) {
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        final clients = await getClientSatisfactionData(companyId);
        if (!_clientsStreamController.isClosed) {
          _clientsStreamController.add(clients);
        }
      } catch (e) {
        if (kDebugMode) {
          developer.log('Error in real-time client satisfaction monitoring: $e', name: 'ClientSatisfactionService', level: 1000);
        }
        // Cancel timer if there are persistent errors
        if (e.toString().contains('disposed') || e.toString().contains('closed')) {
          timer.cancel();
        }
      }
    });
  }

  /// Stop real-time monitoring and cleanup
  void dispose() {
    _clientsStreamController.close();
  }

  /// Clear cache to force fresh data
  void clearCache() {
    _cachedClients = null;
    _lastCacheUpdate = null;
  }
}
