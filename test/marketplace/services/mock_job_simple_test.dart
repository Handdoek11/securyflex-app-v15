import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/marketplace/services/mock_job_data_service.dart';

/// Simple test to verify MockJobDataService basic functionality
void main() {
  group('MockJobDataService Basic Tests', () {
    setUp(() {
      MockJobDataService.setUseMockData(true);
      MockJobDataService.clearCache();
    });

    test('should generate 20 mock jobs', () async {
      final jobs = await MockJobDataService.getAllMockJobs();
      
      expect(jobs.length, equals(20));
      
      // Basic validation
      for (final job in jobs) {
        expect(job.jobId, isNotEmpty);
        expect(job.jobTitle, isNotEmpty);
        expect(job.companyName, isNotEmpty);
        expect(job.location, isNotEmpty);
        expect(job.hourlyRate, greaterThan(0));
      }
      
      print('✅ Generated ${jobs.length} Dutch security jobs successfully');
    });

    test('should have proper job categories', () async {
      final jobs = await MockJobDataService.getAllMockJobs();
      final categories = jobs.map((j) => j.jobType).toSet();
      
      expect(categories.contains('Objectbeveiliging'), isTrue);
      expect(categories.contains('Evenementbeveiliging'), isTrue);
      
      print('✅ Job categories: ${categories.toList()}');
    });

    test('should have realistic salary ranges', () async {
      final jobs = await MockJobDataService.getAllMockJobs();
      
      final minSalary = jobs.map((j) => j.hourlyRate).reduce((a, b) => a < b ? a : b);
      final maxSalary = jobs.map((j) => j.hourlyRate).reduce((a, b) => a > b ? a : b);
      final avgSalary = jobs.map((j) => j.hourlyRate).reduce((a, b) => a + b) / jobs.length;
      
      expect(minSalary, greaterThanOrEqualTo(15.0));
      expect(maxSalary, lessThanOrEqualTo(45.0));
      expect(avgSalary, greaterThan(20.0));
      
      print('✅ Salary range: €${minSalary.toStringAsFixed(2)} - €${maxSalary.toStringAsFixed(2)} (avg: €${avgSalary.toStringAsFixed(2)})');
    });

    test('should include Dutch companies', () async {
      final jobs = await MockJobDataService.getAllMockJobs();
      final companies = jobs.map((j) => j.companyName).toSet();
      
      expect(companies.any((c) => c.contains('G4S')), isTrue);
      expect(companies.any((c) => c.contains('Trigion')), isTrue);
      
      print('✅ Companies: ${companies.toList()}');
    });

    test('should filter by certificates', () async {
      final matchingJobs = await MockJobDataService.getJobsByCertificateRequirements(['WPBR']);
      
      expect(matchingJobs, isNotEmpty);
      
      for (final job in matchingJobs) {
        final hasWPBR = job.requiredCertificates.any((cert) => cert.contains('WPBR'));
        expect(hasWPBR || job.requiredCertificates.isEmpty, isTrue);
      }
      
      print('✅ Found ${matchingJobs.length} jobs matching WPBR certificate');
    });

    test('should provide analytics', () async {
      // Ensure we have jobs loaded first
      await MockJobDataService.getAllMockJobs();
      
      final stats = MockJobDataService.getMockDataStats();
      
      expect(stats['totalJobs'], equals(20));
      expect(stats['averageSalary'], greaterThan(15.0));
      expect(stats['jobTypeDistribution'], isA<Map<String, int>>());
      
      print('✅ Analytics: ${stats}');
    });
  });
}