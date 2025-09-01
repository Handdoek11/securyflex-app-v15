import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/analytics_data_models.dart';

import 'analytics_firestore_schema.dart';
import 'analytics_repository.dart';

/// Analytics schema migration utility
/// Handles migration from existing schema to new analytics structure
/// Provides safe migration with rollback capabilities
class AnalyticsMigration {
  final FirebaseFirestore _firestore;
  final AnalyticsRepository _analyticsRepository;
  
  AnalyticsMigration({
    FirebaseFirestore? firestore,
    AnalyticsRepository? analyticsRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _analyticsRepository = analyticsRepository ?? FirebaseAnalyticsRepository();

  /// Execute complete migration in phases
  Future<bool> executeMigration() async {
    try {
      debugPrint('Starting analytics schema migration...');
      
      // Phase 1: Create analytics summary documents
      await _migratePhase1();
      
      // Phase 2: Backfill historical data
      await _migratePhase2();
      
      // Phase 3: Validate migration
      final isValid = await _validateMigration();
      
      if (isValid) {
        debugPrint('Analytics migration completed successfully');
        return true;
      } else {
        debugPrint('Analytics migration validation failed');
        return false;
      }
    } catch (e) {
      debugPrint('Analytics migration failed: $e');
      return false;
    }
  }

  /// Phase 1: Create analytics summary documents for existing companies
  Future<void> _migratePhase1() async {
    debugPrint('Phase 1: Creating analytics summary documents...');
    
    final companies = await _firestore.collection('companies').get();
    
    for (final companyDoc in companies.docs) {
      final companyData = companyDoc.data();
      final companyId = companyDoc.id;
      
      // Create analytics summary document
      final summaryData = {
        'companyId': companyId,
        'totalJobsPosted': companyData['totalJobsPosted'] ?? 0,
        'activeJobs': companyData['activeJobs'] ?? 0,
        'completedJobs': companyData['completedJobs'] ?? 0,
        'totalSpent': companyData['totalSpent'] ?? 0.0,
        'totalGuardsHired': companyData['totalGuardsHired'] ?? 0,
        'averageJobValue': companyData['averageJobValue'] ?? 0.0,
        'averageRating': companyData['averageRating'] ?? 0.0,
        'lastUpdated': Timestamp.now(),
        'migrationVersion': '1.0.0',
      };
      
      await AnalyticsFirestoreSchema
          .getCompanyAnalyticsSummary(companyId)
          .set(summaryData);
      
      debugPrint('Created analytics summary for company: $companyId');
    }
  }

  /// Phase 2: Backfill historical analytics data
  Future<void> _migratePhase2() async {
    debugPrint('Phase 2: Backfilling historical analytics data...');
    
    // Migrate application data to funnel analytics
    await _migrateApplicationsToFunnelData();
    
    // Migrate job data to job analytics
    await _migrateJobsToAnalytics();
    
    // Create initial source analytics
    await _createInitialSourceAnalytics();
  }

  /// Migrate existing applications to funnel analytics
  Future<void> _migrateApplicationsToFunnelData() async {
    debugPrint('Migrating applications to funnel analytics...');
    
    final applications = await _firestore.collection('applications').get();
    final Map<String, Map<String, int>> companyFunnelData = {};
    
    for (final appDoc in applications.docs) {
      final appData = appDoc.data();
      final companyName = appData['companyName'] as String? ?? '';
      
      // Find company ID by name (this is a simplified approach)
      final companyId = await _findCompanyIdByName(companyName);
      if (companyId == null) continue;
      
      if (!companyFunnelData.containsKey(companyId)) {
        companyFunnelData[companyId] = {
          'totalApplications': 0,
          'acceptedApplications': 0,
          'rejectedApplications': 0,
          'pendingApplications': 0,
        };
      }
      
      companyFunnelData[companyId]!['totalApplications'] = 
          (companyFunnelData[companyId]!['totalApplications'] ?? 0) + 1;
      
      final status = appData['status'] as String? ?? 'pending';
      switch (status) {
        case 'accepted':
          companyFunnelData[companyId]!['acceptedApplications'] = 
              (companyFunnelData[companyId]!['acceptedApplications'] ?? 0) + 1;
          break;
        case 'rejected':
          companyFunnelData[companyId]!['rejectedApplications'] = 
              (companyFunnelData[companyId]!['rejectedApplications'] ?? 0) + 1;
          break;
        default:
          companyFunnelData[companyId]!['pendingApplications'] = 
              (companyFunnelData[companyId]!['pendingApplications'] ?? 0) + 1;
      }
    }
    
    // Create funnel analytics documents
    for (final entry in companyFunnelData.entries) {
      final companyId = entry.key;
      final data = entry.value;
      
      final funnelAnalytics = RecruitmentFunnelAnalytics(
        period: 'historical',
        companyId: companyId,
        posted: FunnelStage(
          count: data['totalApplications'] ?? 0,
          items: [],
        ),
        viewed: FunnelStage(
          count: (data['totalApplications'] ?? 0) * 3, // Estimate 3x views
          items: [],
        ),
        applied: FunnelStage(
          count: data['totalApplications'] ?? 0,
          items: [],
        ),
        interviewed: FunnelStage(
          count: (data['acceptedApplications'] ?? 0) + (data['rejectedApplications'] ?? 0),
          items: [],
        ),
        hired: FunnelStage(
          count: data['acceptedApplications'] ?? 0,
          items: [],
        ),
        conversionRates: ConversionRates(
          viewToApplication: _calculateRate(data['totalApplications'] ?? 0, (data['totalApplications'] ?? 0) * 3),
          applicationToInterview: _calculateRate((data['acceptedApplications'] ?? 0) + (data['rejectedApplications'] ?? 0), data['totalApplications'] ?? 0),
          interviewToHire: _calculateRate(data['acceptedApplications'] ?? 0, (data['acceptedApplications'] ?? 0) + (data['rejectedApplications'] ?? 0)),
          overallConversion: _calculateRate(data['acceptedApplications'] ?? 0, (data['totalApplications'] ?? 0) * 3),
        ),
        dropOffPoints: [],
        updatedAt: DateTime.now(),
      );
      
      await _analyticsRepository.saveFunnelAnalytics(funnelAnalytics);
      debugPrint('Created funnel analytics for company: $companyId');
    }
  }

  /// Migrate existing jobs to job analytics
  Future<void> _migrateJobsToAnalytics() async {
    debugPrint('Migrating jobs to analytics...');
    
    final jobs = await _firestore.collection('jobs').get();
    
    for (final jobDoc in jobs.docs) {
      final jobData = jobDoc.data();
      final jobId = jobDoc.id;
      final companyId = jobData['companyId'] as String? ?? '';
      
      // Create sample job daily analytics for the creation date
      final createdDate = (jobData['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      final dateStr = createdDate.toIso8601String().split('T')[0];
      
      final jobAnalytics = JobDailyAnalytics(
        date: dateStr,
        jobId: jobId,
        companyId: companyId,
        totalViews: (jobData['applicationsCount'] as int? ?? 0) * 5, // Estimate 5x views per application
        uniqueViews: (jobData['applicationsCount'] as int? ?? 0) * 4, // Estimate 4x unique views
        averageViewDuration: 45.0, // 45 seconds average
        bounceRate: 35.0, // 35% bounce rate
        newApplications: jobData['applicationsCount'] as int? ?? 0,
        totalApplications: jobData['applicationsCount'] as int? ?? 0,
        applicationQualityScore: 3.5, // Default quality score
        viewToApplicationRate: 20.0, // 20% conversion rate
        applicationToResponseRate: 85.0, // 85% response rate
        searchRanking: 5, // Average ranking
        recommendationScore: 0.7, // 70% recommendation score
        competitiveIndex: 0.6, // 60% competitive index
        viewsByLocation: {}, // Empty for historical data
        viewsByHour: List.filled(24, 0), // Empty hourly data
        peakViewingHours: ['09:00', '14:00', '20:00'], // Default peak hours
        updatedAt: DateTime.now(),
      );
      
      await _analyticsRepository.saveJobDailyAnalytics(jobAnalytics);
      debugPrint('Created job analytics for job: $jobId');
    }
  }

  /// Create initial source analytics
  Future<void> _createInitialSourceAnalytics() async {
    debugPrint('Creating initial source analytics...');
    
    final companies = await _firestore.collection('companies').get();
    final sources = ['search', 'recommendation', 'direct', 'notification'];
    
    for (final companyDoc in companies.docs) {
      final companyId = companyDoc.id;
      final companyData = companyDoc.data();
      final totalHires = companyData['totalGuardsHired'] as int? ?? 0;
      
      for (final source in sources) {
        // Distribute hires across sources with realistic proportions
        int sourceHires;
        switch (source) {
          case 'search':
            sourceHires = (totalHires * 0.5).round(); // 50% from search
            break;
          case 'recommendation':
            sourceHires = (totalHires * 0.3).round(); // 30% from recommendations
            break;
          case 'direct':
            sourceHires = (totalHires * 0.15).round(); // 15% direct
            break;
          default:
            sourceHires = (totalHires * 0.05).round(); // 5% notifications
        }
        
        final sourceAnalytics = SourceAnalytics(
          source: source,
          companyId: companyId,
          totalViews: sourceHires * 10, // Estimate 10x views per hire
          totalApplications: sourceHires * 3, // Estimate 3x applications per hire
          totalHires: sourceHires,
          averageApplicationQuality: 3.5 + (sources.indexOf(source) * 0.2), // Vary by source
          averageGuardRating: 4.0 + (sources.indexOf(source) * 0.1),
          guardRetentionRate: 80.0 + (sources.indexOf(source) * 2),
          costPerView: 0.50 + (sources.indexOf(source) * 0.10), // €0.50-0.80 per view
          costPerApplication: 5.0 + (sources.indexOf(source) * 2), // €5-11 per application
          costPerHire: 50.0 + (sources.indexOf(source) * 20), // €50-110 per hire
          totalSpend: (50.0 + (sources.indexOf(source) * 20)) * sourceHires,
          averageTimeToApplication: 24.0 - (sources.indexOf(source) * 4), // 24-12 hours
          averageTimeToHire: 72.0 - (sources.indexOf(source) * 8), // 72-48 hours
          dailyMetrics: {}, // Empty for historical data
          lastUpdated: DateTime.now(),
        );
        
        await _analyticsRepository.saveSourceAnalytics(sourceAnalytics);
        debugPrint('Created source analytics for company $companyId, source: $source');
      }
    }
  }

  /// Phase 3: Validate migration
  Future<bool> _validateMigration() async {
    debugPrint('Phase 3: Validating migration...');
    
    try {
      final companies = await _firestore.collection('companies').limit(5).get();
      
      for (final companyDoc in companies.docs) {
        final companyId = companyDoc.id;
        
        // Check analytics summary exists
        final summary = await AnalyticsFirestoreSchema
            .getCompanyAnalyticsSummary(companyId)
            .get();
        
        if (!summary.exists) {
          debugPrint('Missing analytics summary for company: $companyId');
          return false;
        }
        
        // Check funnel analytics exists
        final funnel = await _analyticsRepository.getFunnelAnalytics(companyId, 'historical');
        if (funnel == null) {
          debugPrint('Missing funnel analytics for company: $companyId');
          return false;
        }
        
        // Check source analytics exists
        final sources = await _analyticsRepository.getAllSourceAnalytics(companyId);
        if (sources.isEmpty) {
          debugPrint('Missing source analytics for company: $companyId');
          return false;
        }
      }
      
      debugPrint('Migration validation successful');
      return true;
    } catch (e) {
      debugPrint('Migration validation failed: $e');
      return false;
    }
  }

  /// Helper method to find company ID by name
  Future<String?> _findCompanyIdByName(String companyName) async {
    if (companyName.isEmpty) return null;
    
    try {
      final query = await _firestore
          .collection('companies')
          .where('companyName', isEqualTo: companyName)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }
    } catch (e) {
      debugPrint('Error finding company by name: $e');
    }
    
    return null;
  }

  /// Helper method to calculate percentage rate
  double _calculateRate(int numerator, int denominator) {
    if (denominator == 0) return 0.0;
    return (numerator / denominator) * 100;
  }

  /// Rollback migration (emergency use only)
  Future<bool> rollbackMigration() async {
    debugPrint('Rolling back analytics migration...');
    
    try {
      final companies = await _firestore.collection('companies').get();
      
      for (final companyDoc in companies.docs) {
        final companyId = companyDoc.id;
        
        // Delete analytics subcollections
        await _deleteCollection(AnalyticsFirestoreSchema.getCompanyAnalyticsDaily(companyId));
        await _deleteCollection(AnalyticsFirestoreSchema.getCompanyAnalyticsWeekly(companyId));
        await _deleteCollection(AnalyticsFirestoreSchema.getCompanyAnalyticsMonthly(companyId));
        await _deleteCollection(AnalyticsFirestoreSchema.getCompanyFunnelAnalytics(companyId));
        await _deleteCollection(AnalyticsFirestoreSchema.getCompanySourceAnalytics(companyId));
        
        // Delete analytics summary
        await AnalyticsFirestoreSchema.getCompanyAnalyticsSummary(companyId).delete();
      }
      
      debugPrint('Migration rollback completed');
      return true;
    } catch (e) {
      debugPrint('Migration rollback failed: $e');
      return false;
    }
  }

  /// Helper method to delete a collection
  Future<void> _deleteCollection(CollectionReference collection) async {
    final batch = _firestore.batch();
    final docs = await collection.get();
    
    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}
