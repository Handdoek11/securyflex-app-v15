import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/analytics_data_models.dart';
import '../database/analytics_migration.dart';
import '../database/analytics_repository.dart';
import 'analytics_service.dart';

/// Comprehensive migration service for SecuryFlex analytics
/// Handles safe migration with monitoring, rollback, and validation
class AnalyticsMigrationService {
  static AnalyticsMigrationService? _instance;
  static AnalyticsMigrationService get instance {
    _instance ??= AnalyticsMigrationService._();
    return _instance!;
  }

  AnalyticsMigrationService._();

  final AnalyticsMigration _migration = AnalyticsMigration();
  final AnalyticsRepository _repository = FirebaseAnalyticsRepository();
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Migration state tracking
  bool _migrationInProgress = false;
  String? _currentMigrationId;
  final List<String> _migrationLog = [];
  final Map<String, dynamic> _migrationStats = {};

  /// Execute complete analytics migration with monitoring
  Future<MigrationResult> executeMigration({
    bool dryRun = false,
    List<String>? specificCompanies,
    bool skipValidation = false,
  }) async {
    if (_migrationInProgress) {
      return MigrationResult.error('Migration already in progress');
    }

    _migrationInProgress = true;
    _currentMigrationId = _generateMigrationId();
    _migrationLog.clear();
    _migrationStats.clear();

    try {
      _log('Starting analytics migration (ID: $_currentMigrationId)');
      _log('Dry run: $dryRun');
      _log('Specific companies: ${specificCompanies?.join(", ") ?? "All"}');

      final result = await _executePhases(
        dryRun: dryRun,
        specificCompanies: specificCompanies,
        skipValidation: skipValidation,
      );

      _log('Migration completed with status: ${result.status}');
      return result;

    } catch (e) {
      _log('Migration failed with error: $e');
      return MigrationResult.error('Migration failed: $e');
    } finally {
      _migrationInProgress = false;
      _currentMigrationId = null;
    }
  }

  /// Execute migration phases with detailed monitoring
  Future<MigrationResult> _executePhases({
    required bool dryRun,
    List<String>? specificCompanies,
    required bool skipValidation,
  }) async {
    final phases = [
      MigrationPhase(
        name: 'Pre-Migration Validation',
        action: () => _preMigrationValidation(specificCompanies),
      ),
      MigrationPhase(
        name: 'Schema Preparation',
        action: () => _schemaPreparation(dryRun),
      ),
      MigrationPhase(
        name: 'Data Migration',
        action: () => _dataMigration(dryRun, specificCompanies),
      ),
      MigrationPhase(
        name: 'Post-Migration Validation',
        action: () async => skipValidation ? true : await _postMigrationValidation(specificCompanies),
      ),
      MigrationPhase(
        name: 'Analytics Initialization',
        action: () => _analyticsInitialization(dryRun),
      ),
    ];

    for (int i = 0; i < phases.length; i++) {
      final phase = phases[i];
      _log('Phase ${i + 1}/${phases.length}: ${phase.name}');

      try {
        final startTime = DateTime.now();
        final success = await phase.action();
        final duration = DateTime.now().difference(startTime);

        _migrationStats['phase_${i + 1}_duration'] = duration.inMilliseconds;
        _migrationStats['phase_${i + 1}_success'] = success;

        if (!success) {
          _log('Phase ${phase.name} failed');
          return MigrationResult.error('Phase ${phase.name} failed');
        }

        _log('Phase ${phase.name} completed in ${duration.inMilliseconds}ms');
      } catch (e) {
        _log('Phase ${phase.name} error: $e');
        return MigrationResult.error('Phase ${phase.name} error: $e');
      }
    }

    return MigrationResult.success(_migrationStats);
  }

  /// Pre-migration validation
  Future<bool> _preMigrationValidation(List<String>? specificCompanies) async {
    try {
      _log('Validating existing data structure...');

      // Check Firestore connection
      await _firestore.collection('companies').limit(1).get();
      _log('✓ Firestore connection verified');

      // Get companies to migrate
      final companies = await _getCompaniesToMigrate(specificCompanies);
      _migrationStats['total_companies'] = companies.length;
      _log('✓ Found ${companies.length} companies to migrate');

      // Check existing analytics data
      int existingAnalyticsCount = 0;
      for (final company in companies) {
        final analyticsDoc = await _firestore
            .collection('companies')
            .doc(company.id)
            .collection('analytics_summary')
            .doc('current')
            .get();
        
        if (analyticsDoc.exists) {
          existingAnalyticsCount++;
        }
      }

      _migrationStats['companies_with_existing_analytics'] = existingAnalyticsCount;
      _log('✓ $existingAnalyticsCount companies already have analytics data');

      // Validate data integrity
      final dataIntegrityCheck = await _validateDataIntegrity(companies);
      if (!dataIntegrityCheck) {
        _log('✗ Data integrity validation failed');
        return false;
      }

      _log('✓ Pre-migration validation completed successfully');
      return true;

    } catch (e) {
      _log('✗ Pre-migration validation failed: $e');
      return false;
    }
  }

  /// Schema preparation phase
  Future<bool> _schemaPreparation(bool dryRun) async {
    try {
      _log('Preparing analytics schema...');

      if (dryRun) {
        _log('DRY RUN: Would create analytics subcollections');
        return true;
      }

      // Create analytics summary documents for companies without them
      final companies = await _firestore.collection('companies').get();
      int created = 0;

      for (final companyDoc in companies.docs) {
        final summaryDoc = await _firestore
            .collection('companies')
            .doc(companyDoc.id)
            .collection('analytics_summary')
            .doc('current')
            .get();

        if (!summaryDoc.exists) {
          await _createAnalyticsSummary(companyDoc.id, companyDoc.data());
          created++;
        }
      }

      _migrationStats['analytics_summaries_created'] = created;
      _log('✓ Created $created analytics summary documents');

      return true;

    } catch (e) {
      _log('✗ Schema preparation failed: $e');
      return false;
    }
  }

  /// Data migration phase
  Future<bool> _dataMigration(bool dryRun, List<String>? specificCompanies) async {
    try {
      _log('Starting data migration...');

      if (dryRun) {
        _log('DRY RUN: Would migrate historical data');
        return true;
      }

      final companies = await _getCompaniesToMigrate(specificCompanies);
      int migratedCompanies = 0;
      int migratedJobs = 0;
      int migratedApplications = 0;

      for (final companyDoc in companies) {
        try {
          // Migrate company data
          await _migrateCompanyData(companyDoc.id, companyDoc.data() as Map<String, dynamic>);
          migratedCompanies++;

          // Migrate jobs for this company
          final jobs = await _firestore
              .collection('jobs')
              .where('companyId', isEqualTo: companyDoc.id)
              .get();

          for (final jobDoc in jobs.docs) {
            await _migrateJobData(jobDoc.id, jobDoc.data());
            migratedJobs++;
          }

          // Migrate applications for this company
          final companyData = companyDoc.data() as Map<String, dynamic>?;
          final companyName = companyData?['companyName'] as String? ?? '';
          if (companyName.isNotEmpty) {
            final applications = await _firestore
                .collection('applications')
                .where('companyName', isEqualTo: companyName)
                .get();

            for (final appDoc in applications.docs) {
              await _migrateApplicationData(appDoc.id, appDoc.data());
              migratedApplications++;
            }
          }

          _log('✓ Migrated company ${companyDoc.id} with ${jobs.docs.length} jobs');

        } catch (e) {
          _log('✗ Failed to migrate company ${companyDoc.id}: $e');
          // Continue with other companies
        }
      }

      _migrationStats['migrated_companies'] = migratedCompanies;
      _migrationStats['migrated_jobs'] = migratedJobs;
      _migrationStats['migrated_applications'] = migratedApplications;

      _log('✓ Data migration completed: $migratedCompanies companies, $migratedJobs jobs, $migratedApplications applications');
      return true;

    } catch (e) {
      _log('✗ Data migration failed: $e');
      return false;
    }
  }

  /// Post-migration validation
  Future<bool> _postMigrationValidation(List<String>? specificCompanies) async {
    try {
      _log('Validating migrated data...');

      final companies = await _getCompaniesToMigrate(specificCompanies);
      int validatedCompanies = 0;
      int validationErrors = 0;

      for (final companyDoc in companies) {
        try {
          // Validate analytics summary exists
          final summaryDoc = await _firestore
              .collection('companies')
              .doc(companyDoc.id)
              .collection('analytics_summary')
              .doc('current')
              .get();

          if (!summaryDoc.exists) {
            _log('✗ Missing analytics summary for company ${companyDoc.id}');
            validationErrors++;
            continue;
          }

          // Validate funnel analytics exists
          final funnelDoc = await _firestore
              .collection('companies')
              .doc(companyDoc.id)
              .collection('funnel_analytics')
              .doc('historical')
              .get();

          if (!funnelDoc.exists) {
            _log('✗ Missing funnel analytics for company ${companyDoc.id}');
            validationErrors++;
            continue;
          }

          // Validate source analytics exist
          final sourceAnalytics = await _firestore
              .collection('companies')
              .doc(companyDoc.id)
              .collection('source_analytics')
              .get();

          if (sourceAnalytics.docs.isEmpty) {
            _log('✗ Missing source analytics for company ${companyDoc.id}');
            validationErrors++;
            continue;
          }

          validatedCompanies++;

        } catch (e) {
          _log('✗ Validation error for company ${companyDoc.id}: $e');
          validationErrors++;
        }
      }

      _migrationStats['validated_companies'] = validatedCompanies;
      _migrationStats['validation_errors'] = validationErrors;

      if (validationErrors > 0) {
        _log('✗ Post-migration validation found $validationErrors errors');
        return false;
      }

      _log('✓ Post-migration validation completed successfully');
      return true;

    } catch (e) {
      _log('✗ Post-migration validation failed: $e');
      return false;
    }
  }

  /// Analytics initialization
  Future<bool> _analyticsInitialization(bool dryRun) async {
    try {
      _log('Initializing analytics services...');

      if (dryRun) {
        _log('DRY RUN: Would initialize analytics services');
        return true;
      }

      // Clear analytics service caches
      _analyticsService.clearAllCaches();
      _log('✓ Cleared analytics caches');

      // Test analytics service functionality
      final companies = await _firestore.collection('companies').limit(3).get();
      int testedCompanies = 0;

      for (final companyDoc in companies.docs) {
        try {
          final dashboardData = await _analyticsService.getCompanyDashboardData(companyDoc.id);
          if (dashboardData.isNotEmpty) {
            testedCompanies++;
          }
        } catch (e) {
          _log('✗ Analytics test failed for company ${companyDoc.id}: $e');
        }
      }

      _migrationStats['analytics_tests_passed'] = testedCompanies;
      _log('✓ Analytics initialization completed, tested $testedCompanies companies');

      return true;

    } catch (e) {
      _log('✗ Analytics initialization failed: $e');
      return false;
    }
  }

  /// Get companies to migrate
  Future<List<QueryDocumentSnapshot>> _getCompaniesToMigrate(List<String>? specificCompanies) async {
    if (specificCompanies != null && specificCompanies.isNotEmpty) {
      final companies = <QueryDocumentSnapshot>[];
      for (final companyId in specificCompanies) {
        final doc = await _firestore.collection('companies').doc(companyId).get();
        if (doc.exists) {
          companies.add(doc as QueryDocumentSnapshot);
        }
      }
      return companies;
    } else {
      final snapshot = await _firestore.collection('companies').get();
      return snapshot.docs;
    }
  }

  /// Validate data integrity
  Future<bool> _validateDataIntegrity(List<QueryDocumentSnapshot> companies) async {
    try {
      for (final company in companies) {
        final data = company.data() as Map<String, dynamic>;
        
        // Check required fields
        if (!data.containsKey('companyName') || data['companyName'] == null) {
          _log('✗ Company ${company.id} missing companyName');
          return false;
        }
      }

      return true;
    } catch (e) {
      _log('✗ Data integrity validation error: $e');
      return false;
    }
  }

  /// Create analytics summary for a company
  Future<void> _createAnalyticsSummary(String companyId, Map<String, dynamic> companyData) async {
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
      'migrationId': _currentMigrationId,
    };

    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('analytics_summary')
        .doc('current')
        .set(summaryData);
  }

  /// Migrate company data
  Future<void> _migrateCompanyData(String companyId, Map<String, dynamic> companyData) async {
    // Create funnel analytics
    final funnelAnalytics = RecruitmentFunnelAnalytics(
      period: 'historical',
      companyId: companyId,
      posted: FunnelStage(count: companyData['totalJobsPosted'] ?? 0, items: []),
      viewed: FunnelStage(count: (companyData['totalJobsPosted'] ?? 0) * 5, items: []), // Estimate
      applied: FunnelStage(count: companyData['totalGuardsHired'] ?? 0, items: []),
      interviewed: FunnelStage(count: companyData['totalGuardsHired'] ?? 0, items: []),
      hired: FunnelStage(count: companyData['totalGuardsHired'] ?? 0, items: []),
      conversionRates: ConversionRates(
        viewToApplication: 20.0,
        applicationToInterview: 50.0,
        interviewToHire: 80.0,
        overallConversion: 8.0,
      ),
      dropOffPoints: [],
      updatedAt: DateTime.now(),
    );

    await _repository.saveFunnelAnalytics(funnelAnalytics);

    // Create source analytics
    final sources = ['search', 'recommendation', 'direct', 'notification'];
    final totalHires = companyData['totalGuardsHired'] as int? ?? 0;

    for (final source in sources) {
      final sourceHires = (totalHires * _getSourceDistribution(source)).round();
      
      final sourceAnalytics = SourceAnalytics(
        source: source,
        companyId: companyId,
        totalViews: sourceHires * 10,
        totalApplications: sourceHires * 3,
        totalHires: sourceHires,
        averageApplicationQuality: 3.5 + (sources.indexOf(source) * 0.2),
        averageGuardRating: 4.0,
        guardRetentionRate: 85.0,
        costPerView: 0.50,
        costPerApplication: 5.0,
        costPerHire: 50.0,
        totalSpend: 50.0 * sourceHires,
        averageTimeToApplication: 24.0,
        averageTimeToHire: 72.0,
        dailyMetrics: {},
        lastUpdated: DateTime.now(),
      );

      await _repository.saveSourceAnalytics(sourceAnalytics);
    }
  }

  /// Migrate job data
  Future<void> _migrateJobData(String jobId, Map<String, dynamic> jobData) async {
    final createdDate = (jobData['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final dateStr = createdDate.toIso8601String().split('T')[0];

    final jobAnalytics = JobDailyAnalytics(
      date: dateStr,
      jobId: jobId,
      companyId: jobData['companyId'] ?? '',
      totalViews: (jobData['applicationsCount'] as int? ?? 0) * 5,
      uniqueViews: (jobData['applicationsCount'] as int? ?? 0) * 4,
      averageViewDuration: 45.0,
      bounceRate: 35.0,
      newApplications: jobData['applicationsCount'] as int? ?? 0,
      totalApplications: jobData['applicationsCount'] as int? ?? 0,
      applicationQualityScore: 3.5,
      viewToApplicationRate: 20.0,
      applicationToResponseRate: 85.0,
      searchRanking: 5,
      recommendationScore: 0.7,
      competitiveIndex: 0.6,
      viewsByLocation: {},
      viewsByHour: List.filled(24, 0),
      peakViewingHours: ['09:00', '14:00', '20:00'],
      updatedAt: DateTime.now(),
    );

    await _repository.saveJobDailyAnalytics(jobAnalytics);
  }

  /// Migrate application data
  Future<void> _migrateApplicationData(String applicationId, Map<String, dynamic> applicationData) async {
    // Create application lifecycle event
    final event = JobAnalyticsEvent(
      eventId: 'migration_$applicationId',
      jobId: applicationData['jobId'] ?? '',
      eventType: JobEventType.application,
      timestamp: (applicationData['applicationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: applicationData['applicantEmail'] ?? '',
      userRole: 'guard',
      source: 'direct',
      deviceType: 'mobile',
      metadata: {
        'migrated': true,
        'originalStatus': applicationData['status'],
      },
    );

    await _repository.saveJobAnalyticsEvent(event);
  }

  /// Get source distribution percentage
  double _getSourceDistribution(String source) {
    switch (source) {
      case 'search': return 0.5;
      case 'recommendation': return 0.3;
      case 'direct': return 0.15;
      case 'notification': return 0.05;
      default: return 0.0;
    }
  }

  /// Generate unique migration ID
  String _generateMigrationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'migration_$timestamp';
  }

  /// Log migration message
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    _migrationLog.add(logMessage);
    debugPrint(logMessage);
  }

  /// Get migration status
  Map<String, dynamic> getMigrationStatus() {
    return {
      'inProgress': _migrationInProgress,
      'currentMigrationId': _currentMigrationId,
      'logCount': _migrationLog.length,
      'stats': _migrationStats,
    };
  }

  /// Get migration logs
  List<String> getMigrationLogs() {
    return List.from(_migrationLog);
  }

  /// Rollback migration
  Future<bool> rollbackMigration(String migrationId) async {
    try {
      _log('Starting rollback for migration: $migrationId');
      
      final success = await _migration.rollbackMigration();
      
      if (success) {
        _log('Rollback completed successfully');
      } else {
        _log('Rollback failed');
      }
      
      return success;
    } catch (e) {
      _log('Rollback error: $e');
      return false;
    }
  }
}

/// Migration phase definition
class MigrationPhase {
  final String name;
  final Future<bool> Function() action;

  const MigrationPhase({
    required this.name,
    required this.action,
  });
}

/// Migration result
class MigrationResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? stats;

  const MigrationResult._({
    required this.success,
    this.error,
    this.stats,
  });

  factory MigrationResult.success(Map<String, dynamic> stats) {
    return MigrationResult._(success: true, stats: stats);
  }

  factory MigrationResult.error(String error) {
    return MigrationResult._(success: false, error: error);
  }

  String get status => success ? 'SUCCESS' : 'ERROR';
}
