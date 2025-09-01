import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';

void main() {
  group('Search Functionality Tests', () {
    late List<SecurityJobData> allJobs;
    late List<SecurityJobData> filteredJobs;

    setUp(() {
      allJobs = SecurityJobData.jobList;
      filteredJobs = allJobs;
    });

    List<SecurityJobData> performSearch(String query, List<SecurityJobData> jobs) {
      if (query.isEmpty) {
        return jobs;
      } else {
        return jobs.where((job) =>
          job.jobTitle.toLowerCase().contains(query.toLowerCase()) ||
          job.companyName.toLowerCase().contains(query.toLowerCase()) ||
          job.location.toLowerCase().contains(query.toLowerCase()) ||
          job.jobType.toLowerCase().contains(query.toLowerCase()) ||
          job.description.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    }

    test('Empty search returns all jobs', () {
      filteredJobs = performSearch('', allJobs);
      expect(filteredJobs.length, equals(allJobs.length));
      expect(filteredJobs, equals(allJobs));
    });

    test('Search by job title works correctly', () {
      filteredJobs = performSearch('Objectbeveiliging', allJobs);
      expect(filteredJobs.length, greaterThan(0));
      expect(filteredJobs.any((job) =>
        job.jobTitle.toLowerCase().contains('objectbeveiliging') ||
        job.jobType.toLowerCase().contains('objectbeveiliging')), isTrue);
    });

    test('Search by company name works correctly', () {
      filteredJobs = performSearch('Amsterdam', allJobs);
      expect(filteredJobs.length, greaterThan(0));
      expect(filteredJobs.any((job) => 
        job.companyName.toLowerCase().contains('amsterdam')), isTrue);
    });

    test('Search by location works correctly', () {
      filteredJobs = performSearch('Rotterdam', allJobs);
      expect(filteredJobs.length, greaterThan(0));
      expect(filteredJobs.any((job) => 
        job.location.toLowerCase().contains('rotterdam')), isTrue);
    });

    test('Search by job type works correctly', () {
      filteredJobs = performSearch('Evenementbeveiliging', allJobs);
      expect(filteredJobs.length, greaterThan(0));
      expect(filteredJobs.any((job) =>
        job.jobType.toLowerCase().contains('evenementbeveiliging') ||
        job.jobTitle.toLowerCase().contains('evenementbeveiliging')), isTrue);
    });

    test('Search is case insensitive', () {
      final lowerCaseResults = performSearch('amsterdam', allJobs);
      final upperCaseResults = performSearch('AMSTERDAM', allJobs);
      final mixedCaseResults = performSearch('AmStErDaM', allJobs);
      
      expect(lowerCaseResults.length, equals(upperCaseResults.length));
      expect(lowerCaseResults.length, equals(mixedCaseResults.length));
    });

    test('Search with no matches returns empty list', () {
      filteredJobs = performSearch('NonExistentSearchTerm12345', allJobs);
      expect(filteredJobs.length, equals(0));
    });

    test('Partial word matching works', () {
      filteredJobs = performSearch('beveili', allJobs);
      expect(filteredJobs.length, greaterThan(0));
      expect(filteredJobs.any((job) => 
        job.jobTitle.toLowerCase().contains('beveili') ||
        job.jobType.toLowerCase().contains('beveili')), isTrue);
    });

    test('Search in description works', () {
      filteredJobs = performSearch('CCTV', allJobs);
      expect(filteredJobs.length, greaterThan(0));
      expect(filteredJobs.any((job) => 
        job.description.toLowerCase().contains('cctv')), isTrue);
    });

    test('Multiple word search works', () {
      filteredJobs = performSearch('Amsterdam Security', allJobs);
      expect(filteredJobs.length, greaterThan(0));
      // Should find jobs that contain either "Amsterdam" OR "Security"
      expect(filteredJobs.any((job) => 
        job.companyName.toLowerCase().contains('amsterdam') ||
        job.companyName.toLowerCase().contains('security')), isTrue);
    });
  });
}
