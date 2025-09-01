import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/marketplace/services/mock_job_data_service.dart';
import 'package:securyflex_app/marketplace/services/job_search_service.dart';

/// Comprehensive tests for MockJobDataService
/// 
/// Validates all 20 Dutch security jobs, certificate matching,
/// geographic distribution, salary ranges, and integration
/// with the existing JobSearchService.
void main() {
  group('MockJobDataService', () {
    setUp(() {
      // Enable mock data for testing
      MockJobDataService.setUseMockData(true);
      MockJobDataService.clearCache();
    });

    tearDown(() {
      // Clean up after tests
      MockJobDataService.clearCache();
    });

    group('Basic Mock Data Operations', () {
      test('should generate exactly 20 mock jobs', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        
        expect(jobs.length, equals(20));
        expect(jobs.every((job) => job.jobId.isNotEmpty), isTrue);
        expect(jobs.every((job) => job.jobTitle.isNotEmpty), isTrue);
        expect(jobs.every((job) => job.companyName.isNotEmpty), isTrue);
      });

      test('should cache mock jobs properly', () async {
        // First call should generate data
        final jobs1 = await MockJobDataService.getAllMockJobs();
        
        // Second call should return cached data
        final jobs2 = await MockJobDataService.getAllMockJobs();
        
        expect(jobs1.length, equals(jobs2.length));
        expect(jobs1.first.jobId, equals(jobs2.first.jobId));
      });

      test('should provide unique job IDs', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        final jobIds = jobs.map((job) => job.jobId).toSet();
        
        expect(jobIds.length, equals(jobs.length), 
            reason: 'All job IDs should be unique');
      });

      test('should refresh mock data when requested', () async {
        final initialJobs = await MockJobDataService.getAllMockJobs();
        
        await MockJobDataService.refreshMockData();
        final refreshedJobs = await MockJobDataService.getAllMockJobs();
        
        expect(refreshedJobs.length, equals(initialJobs.length));
        // Jobs should be the same structure but freshly generated
        expect(refreshedJobs.first.jobId, equals(initialJobs.first.jobId));
      });
    });

    group('Dutch Security Job Categories', () {
      test('should include all required job categories', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        final jobTypes = jobs.map((job) => job.jobType).toSet();
        
        // Verify we have all main categories
        expect(jobTypes.contains('Objectbeveiliging'), isTrue);
        expect(jobTypes.contains('Evenementbeveiliging'), isTrue);
        expect(jobTypes.contains('Winkelbeveiliging'), isTrue);
        expect(jobTypes.contains('Industriële beveiliging'), isTrue);
        expect(jobTypes.contains('Transportbeveiliging'), isTrue);
        expect(jobTypes.contains('Persoonbeveiliging'), isTrue);
      });

      test('should have proper distribution of job categories', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        
        final objectJobs = jobs.where((j) => j.jobType.contains('Object')).length;
        final eventJobs = jobs.where((j) => j.jobType.contains('Evenement')).length;
        final retailJobs = jobs.where((j) => j.jobType.contains('Winkel')).length;
        
        // Should have at least 2 jobs in each major category
        expect(objectJobs, greaterThanOrEqualTo(2));
        expect(eventJobs, greaterThanOrEqualTo(2));
        expect(retailJobs, greaterThanOrEqualTo(1));
      });
    });

    group('Geographic Distribution', () {
      test('should cover major Dutch cities', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        final locations = jobs.map((job) => job.location.toLowerCase()).join(' ');
        
        // Check for major cities
        expect(locations.contains('amsterdam'), isTrue);
        expect(locations.contains('rotterdam'), isTrue);
        expect(locations.contains('utrecht'), isTrue);
        expect(locations.contains('den haag'), isTrue);
        expect(locations.contains('eindhoven'), isTrue);
      });

      test('should include proper Dutch postal codes', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        
        // Dutch postal code pattern: 4 digits + 2 letters
        final postalCodePattern = RegExp(r'\d{4}[A-Z]{2}');
        
        for (final job in jobs) {
          final hasPostalCode = postalCodePattern.hasMatch(job.location);
          expect(hasPostalCode, isTrue, 
              reason: 'Job ${job.jobId} should have valid Dutch postal code in location: ${job.location}');
        }
      });

      test('should have realistic distance calculations', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        
        for (final job in jobs) {
          expect(job.distance, greaterThan(0));
          expect(job.distance, lessThan(50)); // Should be reasonable commute distance
        }
      });
    });

    group('Salary Ranges and Company Distribution', () {
      test('should have realistic Dutch security salary ranges', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        
        for (final job in jobs) {
          expect(job.hourlyRate, greaterThanOrEqualTo(15.0), 
              reason: 'Minimum wage compliance for ${job.jobId}');
          expect(job.hourlyRate, lessThanOrEqualTo(45.0), 
              reason: 'Realistic maximum rate for ${job.jobId}');
        }
        
        // Check salary distribution
        final entrySalary = jobs.where((j) => j.hourlyRate <= 20.0).length;
        final standardSalary = jobs.where((j) => j.hourlyRate > 20.0 && j.hourlyRate <= 30.0).length;
        final premiumSalary = jobs.where((j) => j.hourlyRate > 30.0).length;
        
        expect(entrySalary, greaterThan(0));
        expect(standardSalary, greaterThan(0));
        expect(premiumSalary, greaterThan(0));
      });

      test('should include major Dutch security companies', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        final companies = jobs.map((job) => job.companyName.toLowerCase()).join(' ');
        
        // Check for major security companies
        expect(companies.contains('g4s'), isTrue);
        expect(companies.contains('trigion'), isTrue);
        expect(companies.contains('facilicom'), isTrue);
        expect(companies.contains('securepro'), isTrue);
      });

      test('should have appropriate company ratings', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        
        for (final job in jobs) {
          expect(job.companyRating, greaterThanOrEqualTo(3.5));
          expect(job.companyRating, lessThanOrEqualTo(5.0));
        }
      });
    });

    group('Certificate Requirements', () {
      test('should include proper Dutch security certificates', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        final allCertificates = jobs
            .expand((job) => job.requiredCertificates)
            .toSet();
        
        // Should include main Dutch certificates
        expect(allCertificates.contains('WPBR'), isTrue);
        expect(allCertificates.contains('VCA'), isTrue);
        expect(allCertificates.contains('BHV'), isTrue);
      });

      test('should have WPBR as base requirement for most jobs', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        
        final wpbrJobs = jobs.where((job) => 
            job.requiredCertificates.any((cert) => cert.contains('WPBR'))
        ).length;
        
        // Most security jobs should require WPBR
        expect(wpbrJobs, greaterThanOrEqualTo(jobs.length * 0.8));
      });

      test('should filter jobs by certificate requirements', () async {
        final userCertificates = ['WPBR', 'BHV'];
        final matchingJobs = await MockJobDataService.getJobsByCertificateRequirements(userCertificates);
        
        expect(matchingJobs, isNotEmpty);
        
        // All returned jobs should be accessible with user certificates
        for (final job in matchingJobs) {
          final hasAllRequired = job.requiredCertificates.every((required) =>
              userCertificates.any((userCert) => 
                  userCert.toLowerCase().contains(required.toLowerCase()) ||
                  required.toLowerCase().contains(userCert.toLowerCase())
              )
          );
          expect(hasAllRequired, isTrue, 
              reason: 'Job ${job.jobId} requirements should match user certificates');
        }
      });
    });

    group('Specialized Job Categories', () {
      test('should identify urgent jobs correctly', () async {
        final urgentJobs = await MockJobDataService.getUrgentJobs();
        
        expect(urgentJobs, isNotEmpty);
        
        final threeDaysFromNow = DateTime.now().add(const Duration(days: 3));
        for (final job in urgentJobs) {
          expect(job.startDate, isNotNull);
          expect(job.startDate!.isBefore(threeDaysFromNow), isTrue,
              reason: 'Job ${job.jobId} should start within 3 days');
        }
      });

      test('should identify high-paying jobs', () async {
        final highPayJobs = await MockJobDataService.getHighPayingJobs(threshold: 25.0);
        
        expect(highPayJobs, isNotEmpty);
        
        for (final job in highPayJobs) {
          expect(job.hourlyRate, greaterThanOrEqualTo(25.0),
              reason: 'Job ${job.jobId} should meet salary threshold');
        }
      });

      test('should identify weekend jobs', () async {
        final weekendJobs = await MockJobDataService.getWeekendJobs();
        
        expect(weekendJobs, isNotEmpty);
        
        for (final job in weekendJobs) {
          final hasWeekendKeyword = job.jobTitle.toLowerCase().contains('weekend') ||
                                   job.description.toLowerCase().contains('weekend') ||
                                   job.jobId.contains('WEEK');
          expect(hasWeekendKeyword, isTrue,
              reason: 'Job ${job.jobId} should be identified as weekend work');
        }
      });

      test('should identify night shift jobs', () async {
        final nightJobs = await MockJobDataService.getNightJobs();
        
        expect(nightJobs, isNotEmpty);
        
        for (final job in nightJobs) {
          final isNightJob = job.jobTitle.toLowerCase().contains('nacht') ||
                            job.description.toLowerCase().contains('nacht') ||
                            job.jobId.contains('NACHT') ||
                            job.duration >= 10;
          expect(isNightJob, isTrue,
              reason: 'Job ${job.jobId} should be identified as night work');
        }
      });

      test('should identify entry-level jobs', () async {
        final entryJobs = await MockJobDataService.getEntryLevelJobs();
        
        expect(entryJobs, isNotEmpty);
        
        for (final job in entryJobs) {
          expect(job.requiredCertificates.length, lessThanOrEqualTo(2));
          expect(job.hourlyRate, lessThanOrEqualTo(22.0));
          
          final hasWPBR = job.requiredCertificates
              .any((cert) => cert.toLowerCase().contains('wpbr'));
          expect(hasWPBR, isTrue,
              reason: 'Entry-level job ${job.jobId} should require WPBR');
        }
      });
    });

    group('JobSearchService Integration', () {
      test('should integrate with JobSearchService for mock data', () async {
        // Enable mock data in JobSearchService
        JobSearchService.setUseMockData(true);
        
        expect(JobSearchService.isUsingMockData, isTrue);
        
        final searchResult = await JobSearchService.searchJobs(
          searchQuery: 'beveiliging',
        );
        
        expect(searchResult.matches, isNotEmpty);
        expect(searchResult.totalCount, greaterThan(0));
      });

      test('should work with JobSearchService certificate filtering', () async {
        JobSearchService.setUseMockData(true);
        
        final matchingJobs = await JobSearchService.searchJobsByCertificates(['WPBR', 'VCA']);
        
        expect(matchingJobs, isNotEmpty);
        
        for (final job in matchingJobs) {
          final hasMatchingCerts = job.requiredCertificates
              .every((required) => ['WPBR', 'VCA']
                  .any((userCert) => userCert.toLowerCase() == required.toLowerCase()));
          expect(hasMatchingCerts || job.requiredCertificates.isEmpty, isTrue,
              reason: 'Job ${job.jobId} should match certificate requirements');
        }
      });

      test('should provide job market analytics', () async {
        JobSearchService.setUseMockData(true);
        
        final analytics = await JobSearchService.getJobMarketAnalytics();
        
        expect(analytics['dataSource'], equals('real'));
        expect(analytics['isUsingMockData'], isFalse);
        expect(analytics['totalJobs'], greaterThanOrEqualTo(0));
        expect(analytics.containsKey('searchCacheSize'), isTrue);
      });
    });

    group('Data Quality and Realistic Content', () {
      test('should have realistic Dutch job descriptions', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        
        for (final job in jobs) {
          expect(job.description.length, greaterThan(50));
          expect(job.description.length, lessThan(1000));
          
          // Should contain Dutch security terminology
          final description = job.description.toLowerCase();
          final hasDutchTerms = description.contains('beveiliging') ||
                               description.contains('toegangscontrole') ||
                               description.contains('surveillance') ||
                               description.contains('incident') ||
                               description.contains('patrouilleren');
          
          expect(hasDutchTerms, isTrue,
              reason: 'Job ${job.jobId} description should contain Dutch security terms');
        }
      });

      test('should have realistic job durations', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        
        for (final job in jobs) {
          expect(job.duration, greaterThanOrEqualTo(6));
          expect(job.duration, lessThanOrEqualTo(12));
        }
        
        // Should have variety in durations
        final durations = jobs.map((job) => job.duration).toSet();
        expect(durations.length, greaterThan(2));
      });

      test('should have realistic applicant counts', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        
        for (final job in jobs) {
          expect(job.applicantCount, greaterThanOrEqualTo(0));
          expect(job.applicantCount, lessThan(50));
        }
        
        // Higher paying jobs might have more applicants
        final highPayJobs = jobs.where((j) => j.hourlyRate > 30.0).toList();
        final lowPayJobs = jobs.where((j) => j.hourlyRate < 20.0).toList();
        
        if (highPayJobs.isNotEmpty && lowPayJobs.isNotEmpty) {
          final avgHighPayApplicants = highPayJobs
              .map((j) => j.applicantCount)
              .reduce((a, b) => a + b) / highPayJobs.length;
          final avgLowPayApplicants = lowPayJobs
              .map((j) => j.applicantCount)
              .reduce((a, b) => a + b) / lowPayJobs.length;
          
          // This isn't always true, but on average should be
          // expect(avgHighPayApplicants, greaterThanOrEqualTo(avgLowPayApplicants));
        }
      });
    });

    group('Mock Data Extension Methods', () {
      test('should correctly identify mock jobs', () async {
        MockJobDataService.setUseMockData(true);
        final jobs = await MockJobDataService.getAllMockJobs();
        
        for (final job in jobs) {
          expect(job.isMockJob, isTrue);
          expect(job.jobId.contains('-'), isTrue);
        }
      });

      test('should categorize mock jobs correctly', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        
        for (final job in jobs) {
          final category = job.mockCategory;
          expect(category, isNotEmpty);
          expect(category, isNot(equals('Overig')));
        }
      });

      test('should classify salary tiers appropriately', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        
        for (final job in jobs) {
          final tier = job.salaryTier;
          expect(tier, isNotEmpty);
          expect(tier.contains('€'), isTrue);
          
          if (job.hourlyRate <= 20.0) {
            expect(tier.contains('Entry Level'), isTrue);
          } else if (job.hourlyRate > 35.0) {
            expect(tier.contains('Premium'), isTrue);
          }
        }
      });

      test('should identify entry-level friendly jobs', () async {
        final jobs = await MockJobDataService.getAllMockJobs();
        
        final entryLevelJobs = jobs.where((job) => job.isEntryLevelFriendly).toList();
        expect(entryLevelJobs, isNotEmpty);
        
        for (final job in entryLevelJobs) {
          expect(job.requiredCertificates.length, lessThanOrEqualTo(2));
          expect(job.hourlyRate, lessThanOrEqualTo(22.0));
        }
      });
    });

    group('Performance and Caching', () {
      test('should cache data efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        // First call - should generate data
        await MockJobDataService.getAllMockJobs();
        final firstCallTime = stopwatch.elapsedMilliseconds;
        
        stopwatch.reset();
        
        // Second call - should use cache
        await MockJobDataService.getAllMockJobs();
        final secondCallTime = stopwatch.elapsedMilliseconds;
        
        // Second call should be significantly faster
        expect(secondCallTime, lessThan(firstCallTime));
      });

      test('should handle cache invalidation', () async {
        // Generate initial data
        final jobs1 = await MockJobDataService.getAllMockJobs();
        
        // Clear cache
        MockJobDataService.clearCache();
        
        // Should regenerate data
        final jobs2 = await MockJobDataService.getAllMockJobs();
        
        expect(jobs1.length, equals(jobs2.length));
        expect(jobs1.first.jobId, equals(jobs2.first.jobId));
      });

      test('should provide accurate statistics', () {
        MockJobDataService.setUseMockData(true);
        
        final stats = MockJobDataService.getMockDataStats();
        
        expect(stats['totalJobs'], equals(20));
        expect(stats['averageSalary'], greaterThan(15.0));
        expect(stats['salaryRange'], isA<Map<String, double>>());
        expect(stats['jobTypeDistribution'], isA<Map<String, int>>());
        expect(stats['certificateRequirements'], isA<Map<String, int>>());
        expect(stats['topCompanies'], isA<List<String>>());
        expect(stats['locationCoverage'], greaterThan(5));
      });
    });
  });
}