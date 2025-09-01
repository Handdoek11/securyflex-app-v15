import 'package:flutter/material.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';
import 'package:securyflex_app/marketplace/services/job_data_service.dart';
// Mock service import removed - using real JobDataService now

/// Job state manager following template's simple state pattern
/// Adapted from hotel_booking state management approach
class JobStateManager {
  // Following template pattern: simple static data lists
  static List<SecurityJobData> _allJobs = [];
  static List<SecurityJobData> _filteredJobs = [];
  static bool _isLoading = false;
  static String? _errorMessage;
  
  // Filter state variables (following template's filter screen pattern)
  static RangeValues _hourlyRateRange = const RangeValues(15, 50);
  static double _maxDistance = 10.0;
  static String _selectedJobType = '';
  static List<String> _selectedCertificates = [];
  static String _searchQuery = '';
  
  // Application state (following template's simple approach)
  static final Set<String> _appliedJobs = <String>{};
  static final Map<String, DateTime> _applicationDates = {};
  
  // Getters following template pattern
  static List<SecurityJobData> get allJobs => _allJobs;
  static List<SecurityJobData> get filteredJobs => _filteredJobs;
  static RangeValues get hourlyRateRange => _hourlyRateRange;
  static double get maxDistance => _maxDistance;
  static String get selectedJobType => _selectedJobType;
  static List<String> get selectedCertificates => _selectedCertificates;
  static String get searchQuery => _searchQuery;
  static Set<String> get appliedJobs => _appliedJobs;
  static bool get isLoading => _isLoading;
  static String? get errorMessage => _errorMessage;

  /// Load jobs from Firestore or fallback to comprehensive mock data
  static Future<void> loadJobs() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      // Try to load from Firestore first
      final jobs = await JobDataService.getAvailableJobs();
      
      // Use real Firestore jobs, fallback to demo data if needed
      if (jobs.isEmpty) {
        // Initialize some demo data if Firestore is empty
        await JobDataService.initializeDemoData();
        _allJobs = await JobDataService.getAvailableJobs();
        
        // If still empty, use static fallback
        if (_allJobs.isEmpty) {
          _allJobs = SecurityJobData.jobList;
        }
      } else {
        _allJobs = jobs;
      }
      
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Fout bij laden van jobs: $e';
      // Fallback to demo data initialization and static data
      try {
        await JobDataService.initializeDemoData();
        _allJobs = await JobDataService.getAvailableJobs();
        if (_allJobs.isEmpty) {
          _allJobs = SecurityJobData.jobList;
        }
        _applyFilters();
      } catch (demoError) {
        // Ultimate fallback to basic demo data
        _allJobs = SecurityJobData.jobList;
        _applyFilters();
      }
    } finally {
      _isLoading = false;
    }
  }
  
  /// Update search query and filter jobs (following template's setState pattern)
  static void updateSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }
  
  /// Update hourly rate range filter (following template's RangeValues pattern)
  static void updateHourlyRateRange(RangeValues range) {
    _hourlyRateRange = range;
    _applyFilters();
  }
  
  /// Update distance filter (following template's double value pattern)
  static void updateMaxDistance(double distance) {
    _maxDistance = distance;
    _applyFilters();
  }
  
  /// Update job type filter (following template's string selection pattern)
  static void updateJobType(String jobType) {
    _selectedJobType = jobType;
    _applyFilters();
  }
  
  /// Update certificate filters (following template's list selection pattern)
  static void updateCertificates(List<String> certificates) {
    _selectedCertificates = certificates;
    _applyFilters();
  }
  
  /// Add certificate to filter (following template's list manipulation)
  static void addCertificate(String certificate) {
    if (!_selectedCertificates.contains(certificate)) {
      _selectedCertificates.add(certificate);
      _applyFilters();
    }
  }
  
  /// Remove certificate from filter (following template's list manipulation)
  static void removeCertificate(String certificate) {
    _selectedCertificates.remove(certificate);
    _applyFilters();
  }
  
  /// Clear all filters (following template's reset pattern)
  static void clearFilters() {
    _hourlyRateRange = const RangeValues(15, 50);
    _maxDistance = 10.0;
    _selectedJobType = '';
    _selectedCertificates.clear();
    _searchQuery = '';
    _applyFilters();
  }
  
  /// Apply all filters (following template's filtering approach)
  static void _applyFilters() {
    _filteredJobs = _allJobs.where((job) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!job.jobTitle.toLowerCase().contains(query) &&
            !job.companyName.toLowerCase().contains(query) &&
            !job.location.toLowerCase().contains(query) &&
            !job.jobType.toLowerCase().contains(query) &&
            !job.description.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Hourly rate filter
      if (job.hourlyRate < _hourlyRateRange.start || 
          job.hourlyRate > _hourlyRateRange.end) {
        return false;
      }
      
      // Distance filter
      if (job.distance > _maxDistance) {
        return false;
      }
      
      // Job type filter
      if (_selectedJobType.isNotEmpty && job.jobType != _selectedJobType) {
        return false;
      }
      
      // Certificate filter
      if (_selectedCertificates.isNotEmpty) {
        bool hasRequiredCertificate = false;
        for (String cert in _selectedCertificates) {
          if (job.requiredCertificates.contains(cert)) {
            hasRequiredCertificate = true;
            break;
          }
        }
        if (!hasRequiredCertificate) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
  
  /// Add job application (following template's simple state update)
  static void addApplication(String jobId) {
    _appliedJobs.add(jobId);
    _applicationDates[jobId] = DateTime.now();
  }
  
  /// Remove job application (following template's simple state update)
  static void removeApplication(String jobId) {
    _appliedJobs.remove(jobId);
    _applicationDates.remove(jobId);
  }
  
  /// Check if applied to job (following template's simple check pattern)
  static bool hasAppliedToJob(String jobId) {
    return _appliedJobs.contains(jobId);
  }
  
  /// Get application date (following template's simple getter pattern)
  static DateTime? getApplicationDate(String jobId) {
    return _applicationDates[jobId];
  }
  
  /// Get applied jobs count (following template's simple calculation)
  static int getAppliedJobsCount() {
    return _appliedJobs.length;
  }
  
  /// Get available job types (following template's static data approach)
  static List<String> getAvailableJobTypes() {
    return _allJobs.map((job) => job.jobType).toSet().toList()..sort();
  }
  
  /// Get available certificates (following template's static data approach)
  static List<String> getAvailableCertificates() {
    final Set<String> certificates = {};
    for (var job in _allJobs) {
      certificates.addAll(job.requiredCertificates);
    }
    return certificates.toList()..sort();
  }
  
  /// Get filter summary (following template's summary pattern)
  static String getFilterSummary() {
    List<String> filters = [];
    
    if (_searchQuery.isNotEmpty) {
      filters.add('Zoekterm: "$_searchQuery"');
    }
    
    if (_hourlyRateRange.start > 15 || _hourlyRateRange.end < 50) {
      filters.add('Tarief: €${_hourlyRateRange.start.round()}-€${_hourlyRateRange.end.round()}');
    }
    
    if (_maxDistance < 10) {
      filters.add('Afstand: max ${_maxDistance.round()}km');
    }
    
    if (_selectedJobType.isNotEmpty) {
      filters.add('Type: $_selectedJobType');
    }
    
    if (_selectedCertificates.isNotEmpty) {
      filters.add('Certificaten: ${_selectedCertificates.length}');
    }
    
    return filters.isEmpty ? 'Geen filters actief' : filters.join(', ');
  }
  
  /// Reset all state (following template's reset pattern)
  static void reset() {
    _filteredJobs = _allJobs;
    clearFilters();
    _appliedJobs.clear();
    _applicationDates.clear();
  }
  
  /// Refresh data (following template's data refresh pattern)
  static Future<void> refreshData() async {
    await loadJobs();
  }

  /// Initialize demo data for JobDiscoveryTab
  /// Ensures comprehensive Dutch security jobs are available in Firestore
  static Future<void> initializeDemoData() async {
    try {
      // Initialize demo data in Firestore
      await JobDataService.initializeDemoData();
      
      // Update state with real jobs from Firestore
      await loadJobs();
      
      debugPrint('JobStateManager: Initialized ${_allJobs.length} demo jobs in Firestore for JobDiscoveryTab');
    } catch (e) {
      debugPrint('JobStateManager: Error initializing demo data: $e');
      _errorMessage = 'Fout bij initialiseren van demo data: $e';
    }
  }

  /// Get jobs by category for filtering
  static List<SecurityJobData> getJobsByCategory(String category) {
    return _allJobs.where((job) => job.jobType == category).toList();
  }

  /// Get urgent jobs (starting within next 3 days)
  static List<SecurityJobData> getUrgentJobs() {
    final urgentThreshold = DateTime.now().add(const Duration(days: 3));
    return _filteredJobs
        .where((job) => job.startDate?.isBefore(urgentThreshold) ?? false)
        .toList()
      ..sort((a, b) => (a.startDate ?? DateTime.now())
          .compareTo(b.startDate ?? DateTime.now()));
  }

  /// Get high-paying jobs (above €28/hour)
  static List<SecurityJobData> getHighPayingJobs() {
    return _filteredJobs
        .where((job) => job.hourlyRate >= 28.0)
        .toList()
      ..sort((a, b) => b.hourlyRate.compareTo(a.hourlyRate));
  }

  /// Get jobs near user location (within 5km)
  static List<SecurityJobData> getNearbyJobs() {
    return _filteredJobs
        .where((job) => job.distance <= 5.0)
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
  }

  /// Get weekend and part-time jobs
  static List<SecurityJobData> getFlexibleJobs() {
    return _filteredJobs
        .where((job) => 
            job.duration <= 8 || 
            job.jobTitle.toLowerCase().contains('weekend') ||
            job.description.toLowerCase().contains('weekend') ||
            job.description.toLowerCase().contains('flexibel'))
        .toList();
  }

  /// Get night shift jobs
  static List<SecurityJobData> getNightJobs() {
    return _filteredJobs
        .where((job) =>
            job.jobTitle.toLowerCase().contains('nacht') ||
            job.description.toLowerCase().contains('nacht') ||
            job.duration >= 10) // Assume longer shifts are night shifts
        .toList();
  }

  /// Get jobs by company type (major vs local security companies)
  static Map<String, List<SecurityJobData>> getJobsByCompanyType() {
    final majorCompanies = ['G4S Nederland', 'Trigion Beveiliging', 'Facilicom Security'];
    final majorJobs = <SecurityJobData>[];
    final localJobs = <SecurityJobData>[];

    for (final job in _filteredJobs) {
      if (majorCompanies.contains(job.companyName)) {
        majorJobs.add(job);
      } else {
        localJobs.add(job);
      }
    }

    return {
      'major': majorJobs,
      'local': localJobs,
    };
  }

  /// Get comprehensive job statistics for analytics
  static Map<String, dynamic> getJobStatistics() {
    if (_allJobs.isEmpty) return {};

    final jobTypes = <String, int>{};
    final certificates = <String, int>{};
    final companies = <String, int>{};
    final locations = <String, int>{};
    
    double totalSalary = 0;
    double totalDistance = 0;
    double totalRating = 0;
    int totalApplicants = 0;

    for (final job in _allJobs) {
      // Job type distribution
      jobTypes[job.jobType] = (jobTypes[job.jobType] ?? 0) + 1;
      
      // Certificate requirements
      for (final cert in job.requiredCertificates) {
        certificates[cert] = (certificates[cert] ?? 0) + 1;
      }
      
      // Company distribution
      companies[job.companyName] = (companies[job.companyName] ?? 0) + 1;
      
      // Location distribution (city names)
      final location = job.location.split(',').first.trim();
      locations[location] = (locations[location] ?? 0) + 1;
      
      totalSalary += job.hourlyRate;
      totalDistance += job.distance;
      totalRating += job.companyRating;
      totalApplicants += job.applicantCount;
    }

    return {
      'totalJobs': _allJobs.length,
      'filteredJobs': _filteredJobs.length,
      'averageSalary': totalSalary / _allJobs.length,
      'averageDistance': totalDistance / _allJobs.length,
      'averageRating': totalRating / _allJobs.length,
      'averageApplicants': totalApplicants / _allJobs.length,
      'salaryRange': {
        'min': _allJobs.map((j) => j.hourlyRate).reduce((a, b) => a < b ? a : b),
        'max': _allJobs.map((j) => j.hourlyRate).reduce((a, b) => a > b ? a : b),
      },
      'jobTypeDistribution': jobTypes,
      'certificateRequirements': certificates,
      'companyDistribution': companies,
      'locationCoverage': locations,
      'urgentJobs': getUrgentJobs().length,
      'highPayingJobs': getHighPayingJobs().length,
      'nearbyJobs': getNearbyJobs().length,
      'flexibleJobs': getFlexibleJobs().length,
      'nightJobs': getNightJobs().length,
    };
  }
}
