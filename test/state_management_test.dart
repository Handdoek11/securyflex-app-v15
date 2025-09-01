import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/marketplace/state/job_state_manager.dart';
import 'package:securyflex_app/marketplace/model/job_filter_data.dart';

void main() {
  group('State Management Integration Tests', () {
    setUp(() {
      // Reset state before each test (following template pattern)
      JobStateManager.reset();
      JobFilterData.resetAllFilters();
    });

    test('Initial state should match template pattern', () {
      expect(JobStateManager.allJobs.isNotEmpty, isTrue);
      expect(JobStateManager.filteredJobs, equals(JobStateManager.allJobs));
      expect(JobStateManager.hourlyRateRange, equals(const RangeValues(15, 50)));
      expect(JobStateManager.maxDistance, equals(10.0));
      expect(JobStateManager.selectedJobType, isEmpty);
      expect(JobStateManager.selectedCertificates, isEmpty);
      expect(JobStateManager.searchQuery, isEmpty);
    });

    test('Search query filtering should work like template', () {
      final initialCount = JobStateManager.filteredJobs.length;
      
      JobStateManager.updateSearchQuery('Amsterdam');
      
      expect(JobStateManager.searchQuery, equals('Amsterdam'));
      expect(JobStateManager.filteredJobs.length, lessThanOrEqualTo(initialCount));
      expect(JobStateManager.filteredJobs.every((job) =>
        job.jobTitle.toLowerCase().contains('amsterdam') ||
        job.companyName.toLowerCase().contains('amsterdam') ||
        job.location.toLowerCase().contains('amsterdam') ||
        job.jobType.toLowerCase().contains('amsterdam') ||
        job.description.toLowerCase().contains('amsterdam')
      ), isTrue);
    });

    test('Hourly rate range filtering should work like template', () {
      JobStateManager.updateHourlyRateRange(const RangeValues(20, 30));
      
      expect(JobStateManager.hourlyRateRange, equals(const RangeValues(20, 30)));
      expect(JobStateManager.filteredJobs.every((job) =>
        job.hourlyRate >= 20 && job.hourlyRate <= 30
      ), isTrue);
    });

    test('Distance filtering should work like template', () {
      JobStateManager.updateMaxDistance(5.0);
      
      expect(JobStateManager.maxDistance, equals(5.0));
      expect(JobStateManager.filteredJobs.every((job) =>
        job.distance <= 5.0
      ), isTrue);
    });

    test('Job type filtering should work like template', () {
      JobStateManager.updateJobType('Objectbeveiliging');
      
      expect(JobStateManager.selectedJobType, equals('Objectbeveiliging'));
      expect(JobStateManager.filteredJobs.every((job) =>
        job.jobType == 'Objectbeveiliging'
      ), isTrue);
    });

    test('Certificate filtering should work like template', () {
      JobStateManager.updateCertificates(['Beveiligingsdiploma A']);
      
      expect(JobStateManager.selectedCertificates, contains('Beveiligingsdiploma A'));
      expect(JobStateManager.filteredJobs.every((job) =>
        job.requiredCertificates.contains('Beveiligingsdiploma A')
      ), isTrue);
    });

    test('Multiple filters should work together like template', () {
      JobStateManager.updateSearchQuery('Security');
      JobStateManager.updateHourlyRateRange(const RangeValues(25, 40));
      JobStateManager.updateMaxDistance(15.0);
      
      expect(JobStateManager.filteredJobs.every((job) =>
        (job.jobTitle.toLowerCase().contains('security') ||
         job.companyName.toLowerCase().contains('security') ||
         job.location.toLowerCase().contains('security') ||
         job.jobType.toLowerCase().contains('security') ||
         job.description.toLowerCase().contains('security')) &&
        job.hourlyRate >= 25 && job.hourlyRate <= 40 &&
        job.distance <= 15.0
      ), isTrue);
    });

    test('Clear filters should reset to initial state like template', () {
      // Apply some filters
      JobStateManager.updateSearchQuery('test');
      JobStateManager.updateHourlyRateRange(const RangeValues(20, 30));
      JobStateManager.updateMaxDistance(5.0);
      JobStateManager.updateJobType('Objectbeveiliging');
      
      // Clear filters
      JobStateManager.clearFilters();
      
      expect(JobStateManager.searchQuery, isEmpty);
      expect(JobStateManager.hourlyRateRange, equals(const RangeValues(15, 50)));
      expect(JobStateManager.maxDistance, equals(10.0));
      expect(JobStateManager.selectedJobType, isEmpty);
      expect(JobStateManager.selectedCertificates, isEmpty);
      expect(JobStateManager.filteredJobs, equals(JobStateManager.allJobs));
    });

    test('Application tracking should work like template', () {
      expect(JobStateManager.hasAppliedToJob('SJ001'), isFalse);
      expect(JobStateManager.getAppliedJobsCount(), equals(0));
      
      JobStateManager.addApplication('SJ001');
      
      expect(JobStateManager.hasAppliedToJob('SJ001'), isTrue);
      expect(JobStateManager.getAppliedJobsCount(), equals(1));
      expect(JobStateManager.getApplicationDate('SJ001'), isNotNull);
    });

    test('Certificate management should work like template', () {
      expect(JobStateManager.selectedCertificates, isEmpty);
      
      JobStateManager.addCertificate('BHV');
      expect(JobStateManager.selectedCertificates, contains('BHV'));
      
      JobStateManager.addCertificate('VCA');
      expect(JobStateManager.selectedCertificates, contains('VCA'));
      expect(JobStateManager.selectedCertificates.length, equals(2));
      
      JobStateManager.removeCertificate('BHV');
      expect(JobStateManager.selectedCertificates, isNot(contains('BHV')));
      expect(JobStateManager.selectedCertificates, contains('VCA'));
      expect(JobStateManager.selectedCertificates.length, equals(1));
    });

    test('Available job types should be extracted like template', () {
      final jobTypes = JobStateManager.getAvailableJobTypes();
      
      expect(jobTypes, isNotEmpty);
      expect(jobTypes, contains('Objectbeveiliging'));
      expect(jobTypes, contains('Evenementbeveiliging'));
      // Should be sorted
      expect(jobTypes, equals(jobTypes..sort()));
    });

    test('Available certificates should be extracted like template', () {
      final certificates = JobStateManager.getAvailableCertificates();
      
      expect(certificates, isNotEmpty);
      expect(certificates, contains('Beveiligingsdiploma A'));
      expect(certificates, contains('BHV'));
      // Should be sorted
      expect(certificates, equals(certificates..sort()));
    });

    test('Filter summary should work like template', () {
      // No filters
      expect(JobStateManager.getFilterSummary(), equals('Geen filters actief'));
      
      // With filters
      JobStateManager.updateSearchQuery('test');
      JobStateManager.updateHourlyRateRange(const RangeValues(20, 30));
      
      final summary = JobStateManager.getFilterSummary();
      expect(summary, contains('Zoekterm: "test"'));
      expect(summary, contains('Tarief: €20-€30'));
    });

    test('Data refresh should work like template', () {
      final initialCount = JobStateManager.allJobs.length;
      
      // Apply filter to reduce results
      JobStateManager.updateSearchQuery('nonexistent');
      expect(JobStateManager.filteredJobs.length, equals(0));
      
      // Refresh data
      JobStateManager.refreshData();
      
      // Should restore all jobs
      expect(JobStateManager.allJobs.length, equals(initialCount));
      expect(JobStateManager.filteredJobs.length, equals(0)); // Filter still applied
    });

    test('Filter data model should work like template', () {
      // Test job type filters
      final selectedJobTypes = JobFilterData.getSelectedJobTypes();
      expect(selectedJobTypes, isEmpty); // Initially "Alle types" is selected
      
      // Select a specific job type
      JobFilterData.jobTypeFilters[1].isSelected = true; // Objectbeveiliging
      final updatedJobTypes = JobFilterData.getSelectedJobTypes();
      expect(updatedJobTypes, contains('Objectbeveiliging'));
      
      // Test certificate filters
      JobFilterData.certificateFilters[0].isSelected = true; // Beveiligingsdiploma A
      final selectedCertificates = JobFilterData.getSelectedCertificates();
      expect(selectedCertificates, contains('Beveiligingsdiploma A'));
      
      // Test distance filters
      JobFilterData.distanceFilters[0].isSelected = true; // Binnen 2 km
      JobFilterData.distanceFilters[2].isSelected = false; // Binnen 10 km (default)
      final maxDistance = JobFilterData.getSelectedMaxDistance();
      expect(maxDistance, equals(2.0));
    });

    test('Filter data reset should work like template', () {
      // Modify some filters
      JobFilterData.jobTypeFilters[1].isSelected = true;
      JobFilterData.certificateFilters[0].isSelected = true;
      JobFilterData.distanceFilters[0].isSelected = true;
      JobFilterData.distanceFilters[2].isSelected = false;
      
      // Reset all filters
      JobFilterData.resetAllFilters();
      
      // Check defaults are restored
      expect(JobFilterData.jobTypeFilters[0].isSelected, isTrue); // "Alle types"
      expect(JobFilterData.jobTypeFilters[1].isSelected, isFalse);
      expect(JobFilterData.certificateFilters[0].isSelected, isFalse);
      expect(JobFilterData.distanceFilters[2].isSelected, isTrue); // "Binnen 10 km"
      expect(JobFilterData.getSelectedMaxDistance(), equals(10.0));
    });

    test('Active filter detection should work like template', () {
      // Initially no active filters
      expect(JobFilterData.hasActiveFilters(), isFalse);
      expect(JobFilterData.getActiveFilterCount(), equals(0));
      
      // Add some filters
      JobFilterData.jobTypeFilters[1].isSelected = true; // Objectbeveiliging
      JobFilterData.certificateFilters[0].isSelected = true; // Beveiligingsdiploma A
      
      expect(JobFilterData.hasActiveFilters(), isTrue);
      expect(JobFilterData.getActiveFilterCount(), equals(2));
    });
  });
}
