import 'package:flutter/foundation.dart';
import 'mock_job_data_service.dart';
import 'job_search_service.dart';

/// Demo file showing how to use MockJobDataService
/// 
/// This demonstrates the comprehensive Dutch security job market
/// simulation with realistic data for testing and development.
class MockJobDataDemo {
  
  /// Demonstrate basic MockJobDataService usage
  static Future<void> demonstrateBasicUsage() async {
    debugPrint('=== MockJobDataService Basic Usage Demo ===\n');
    
    // Enable mock data
    MockJobDataService.setUseMockData(true);
    
    // Get all available jobs
    final allJobs = await MockJobDataService.getAllMockJobs();
    debugPrint('✅ Generated ${allJobs.length} Dutch security jobs');
    
    // Show first few jobs as examples
    debugPrint('\n📋 Sample Jobs:');
    for (int i = 0; i < 3; i++) {
      final job = allJobs[i];
      debugPrint('${i + 1}. ${job.jobTitle}');
      debugPrint('   Company: ${job.companyName}');
      debugPrint('   Location: ${job.location}');
      debugPrint('   Rate: €${job.hourlyRate.toStringAsFixed(2)}/hour');
      debugPrint('   Certificates: ${job.requiredCertificates.join(', ')}');
      debugPrint('   Type: ${job.jobType}');
      debugPrint('');
    }
  }
  
  /// Demonstrate job filtering capabilities
  static Future<void> demonstrateFiltering() async {
    debugPrint('=== MockJobDataService Filtering Demo ===\n');
    
    // Filter by certificates
    final wpbrJobs = await MockJobDataService.getJobsByCertificateRequirements(['WPBR']);
    debugPrint('🎓 Jobs requiring only WPBR: ${wpbrJobs.length}');
    
    // Filter by salary
    final highPayJobs = await MockJobDataService.getHighPayingJobs(threshold: 25.0);
    debugPrint('💰 High-paying jobs (€25+/hour): ${highPayJobs.length}');
    
    // Filter by location (mock distance-based filtering)
    final nearbyJobs = await MockJobDataService.getJobsByLocation('1012AB', maxDistanceKm: 10.0);
    debugPrint('📍 Jobs within 10km: ${nearbyJobs.length}');
    
    // Urgent jobs
    final urgentJobs = await MockJobDataService.getUrgentJobs();
    debugPrint('⚡ Urgent jobs (starting soon): ${urgentJobs.length}');
    
    // Weekend jobs
    final weekendJobs = await MockJobDataService.getWeekendJobs();
    debugPrint('🌅 Weekend jobs: ${weekendJobs.length}');
    
    // Night shifts
    final nightJobs = await MockJobDataService.getNightJobs();
    debugPrint('🌙 Night shift jobs: ${nightJobs.length}');
    
    // Entry-level jobs
    final entryJobs = await MockJobDataService.getEntryLevelJobs();
    debugPrint('🥇 Entry-level jobs: ${entryJobs.length}');
    
    debugPrint('');
  }
  
  /// Demonstrate job market analytics
  static Future<void> demonstrateAnalytics() async {
    debugPrint('=== MockJobDataService Analytics Demo ===\n');
    
    final stats = MockJobDataService.getMockDataStats();
    
    debugPrint('📊 Job Market Analytics:');
    debugPrint('   Total Jobs: ${stats['totalJobs']}');
    debugPrint('   Average Salary: €${(stats['averageSalary'] as double).toStringAsFixed(2)}/hour');
    
    final salaryRange = stats['salaryRange'] as Map<String, double>;
    debugPrint('   Salary Range: €${salaryRange['min']!.toStringAsFixed(2)} - €${salaryRange['max']!.toStringAsFixed(2)}');
    
    final jobTypes = stats['jobTypeDistribution'] as Map<String, int>;
    debugPrint('   Job Type Distribution:');
    jobTypes.forEach((type, count) {
      debugPrint('     $type: $count jobs');
    });
    
    final certificates = stats['certificateRequirements'] as Map<String, int>;
    debugPrint('   Certificate Requirements:');
    certificates.forEach((cert, count) {
      debugPrint('     $cert: $count jobs');
    });
    
    final companies = stats['topCompanies'] as List<String>;
    debugPrint('   Companies: ${companies.length} total');
    debugPrint('   Locations Covered: ${stats['locationCoverage']} cities');
    
    debugPrint('');
  }
  
  /// Demonstrate JobSearchService integration
  static Future<void> demonstrateJobSearchIntegration() async {
    debugPrint('=== JobSearchService Integration Demo ===\n');
    
    // Enable mock data in JobSearchService
    JobSearchService.setUseMockData(true);
    
    // Perform a search
    final searchResult = await JobSearchService.searchJobs(
      searchQuery: 'beveiliging',
      minSalary: 20.0,
      maxSalary: 35.0,
    );
    
    debugPrint('🔍 Search Results:');
    debugPrint('   Query: "beveiliging" with salary €20-€35/hour');
    debugPrint('   Found: ${searchResult.totalCount} matching jobs');
    debugPrint('   Top matches:');
    
    for (int i = 0; i < 3 && i < searchResult.matches.length; i++) {
      final match = searchResult.matches[i];
      debugPrint('     ${i + 1}. ${match.job.jobTitle}');
      debugPrint('        Rate: €${match.job.hourlyRate.toStringAsFixed(2)}/hour');
      debugPrint('        Relevance: ${match.relevanceScore.toStringAsFixed(1)}/100');
      debugPrint('        Reasons: ${match.matchReasons.join(', ')}');
    }
    
    // Use specialized search methods
    final certificateJobs = await JobSearchService.searchJobsByCertificates(['WPBR', 'VCA']);
    debugPrint('\n🎓 Certificate-based search (WPBR + VCA): ${certificateJobs.length} jobs');
    
    final highPayJobs = await JobSearchService.getHighPayingJobs(minSalary: 28.0);
    debugPrint('💰 High-paying search (€28+/hour): ${highPayJobs.length} jobs');
    
    debugPrint('');
  }
  
  /// Demonstrate specific Dutch security sector features
  static Future<void> demonstrateDutchSecurityFeatures() async {
    debugPrint('=== Dutch Security Sector Features Demo ===\n');
    
    final allJobs = await MockJobDataService.getAllMockJobs();
    
    // Major Dutch security companies
    final companies = allJobs.map((j) => j.companyName).toSet();
    debugPrint('🏢 Major Dutch Security Companies:');
    for (var company in companies) {
      final jobCount = allJobs.where((j) => j.companyName == company).length;
      debugPrint('   $company: $jobCount jobs');
    }
    
    // Geographic distribution
    debugPrint('\n🗺️ Geographic Distribution:');
    final regions = <String, int>{};
    for (final job in allJobs) {
      final city = job.location.split(',').first.trim();
      final region = city.split(' ').first; // Extract main city name
      regions[region] = (regions[region] ?? 0) + 1;
    }
    regions.forEach((region, count) {
      debugPrint('   $region: $count jobs');
    });
    
    // Dutch certificate requirements
    debugPrint('\n📜 Dutch Security Certificates:');
    final certStats = <String, int>{};
    for (final job in allJobs) {
      for (final cert in job.requiredCertificates) {
        certStats[cert] = (certStats[cert] ?? 0) + 1;
      }
    }
    certStats.forEach((cert, count) {
      final percentage = (count / allJobs.length * 100).round();
      debugPrint('   $cert: $count jobs ($percentage%)');
    });
    
    // Salary distribution by job type
    debugPrint('\n💶 Salary by Job Type:');
    final jobTypeGroups = <String, List<double>>{};
    for (final job in allJobs) {
      jobTypeGroups.putIfAbsent(job.jobType, () => []).add(job.hourlyRate);
    }
    jobTypeGroups.forEach((type, salaries) {
      final avg = salaries.reduce((a, b) => a + b) / salaries.length;
      final min = salaries.reduce((a, b) => a < b ? a : b);
      final max = salaries.reduce((a, b) => a > b ? a : b);
      debugPrint('   $type: €${avg.toStringAsFixed(2)}/hour (€${min.toStringAsFixed(2)}-€${max.toStringAsFixed(2)})');
    });
    
    debugPrint('');
  }
  
  /// Demonstrate mock data extension methods
  static Future<void> demonstrateExtensionMethods() async {
    debugPrint('=== Mock Data Extensions Demo ===\n');
    
    final jobs = await MockJobDataService.getAllMockJobs();
    final sampleJob = jobs.first;
    
    debugPrint('📝 Extension Methods for: ${sampleJob.jobTitle}');
    debugPrint('   Is Mock Job: ${sampleJob.isMockJob}');
    debugPrint('   Mock Category: ${sampleJob.mockCategory}');
    debugPrint('   Salary Tier: ${sampleJob.salaryTier}');
    debugPrint('   Entry-Level Friendly: ${sampleJob.isEntryLevelFriendly}');
    
    // Show distribution of salary tiers
    debugPrint('\n💰 Salary Tier Distribution:');
    final tierCounts = <String, int>{};
    for (final job in jobs) {
      final tier = job.salaryTier.split(' ').first; // Get tier name
      tierCounts[tier] = (tierCounts[tier] ?? 0) + 1;
    }
    tierCounts.forEach((tier, count) {
      debugPrint('   $tier: $count jobs');
    });
    
    debugPrint('');
  }
  
  /// Run complete demonstration
  static Future<void> runCompleteDemo() async {
    debugPrint('🇳🇱 SECURYFLEX MOCK JOB DATA SERVICE DEMO 🇳🇱');
    debugPrint('Realistic Dutch Security Sector Job Market Simulation\n');
    
    await demonstrateBasicUsage();
    await demonstrateFiltering();
    await demonstrateAnalytics();
    await demonstrateJobSearchIntegration();
    await demonstrateDutchSecurityFeatures();
    await demonstrateExtensionMethods();
    
    debugPrint('✅ Demo completed successfully!');
    debugPrint('The MockJobDataService provides 20 comprehensive Dutch security jobs');
    debugPrint('with realistic company data, geographic distribution, certificates,');
    debugPrint('and salary ranges for testing and development purposes.\n');
  }
}

/// Quick demo function that can be called from main() during development
Future<void> runMockJobDemo() async {
  await MockJobDataDemo.runCompleteDemo();
}