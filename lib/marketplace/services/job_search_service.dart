import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

import '../model/security_job_data.dart';
import 'postcode_service.dart';
import 'certificate_matching_service.dart';
import 'job_data_service.dart';

/// JobSearchService voor geavanceerde job zoek- en filterfunctionaliteit
/// 
/// Provides comprehensive job search capabilities including Nederlandse postcode
/// radius filtering, salary filtering (€15-€35/hour), certificate matching,
/// and relevance scoring for the Dutch security marketplace.
class JobSearchService {
  JobSearchService._();
  
  static final JobSearchService _instance = JobSearchService._();
  static JobSearchService get instance => _instance;
  
  // Cache for search results to improve performance
  static final Map<String, JobSearchResult> _searchCache = {};
  
  /// Search jobs with comprehensive filtering and scoring
  static Future<JobSearchResult> searchJobs({
    String? searchQuery,
    String? userPostcode,
    double? maxDistanceKm,
    double? minSalary,
    double? maxSalary,
    List<String>? jobTypes,
    List<String>? requiredCertificates,
    List<String>? userCertificates,
    String? companyName,
    DateTime? earliestStartDate,
    DateTime? latestStartDate,
    int? maxDurationHours,
    List<SecurityJobData>? jobsToSearch,
    JobSortOption sortBy = JobSortOption.relevance,
    bool sortAscending = false,
  }) async {
    try {
      // Use provided jobs or load from JobDataService or fallback to default job list
      List<SecurityJobData> jobs;
      if (jobsToSearch != null) {
        jobs = jobsToSearch;
      } else {
        jobs = await JobDataService.getAvailableJobs();
        if (jobs.isEmpty) {
          jobs = SecurityJobData.jobList;
        }
      }
      
      // Create cache key for performance
      final cacheKey = _createCacheKey({
        'query': searchQuery,
        'postcode': userPostcode,
        'distance': maxDistanceKm,
        'minSalary': minSalary,
        'maxSalary': maxSalary,
        'jobTypes': jobTypes,
        'certificates': requiredCertificates,
        'userCertificates': userCertificates,
        'company': companyName,
        'startDate': earliestStartDate,
        'endDate': latestStartDate,
        'duration': maxDurationHours,
        'sortBy': sortBy,
        'sortAsc': sortAscending,
      });
      
      // Check cache first
      if (_searchCache.containsKey(cacheKey)) {
        final cachedResult = _searchCache[cacheKey]!;
        if (cachedResult.isExpired == false) {
          return cachedResult;
        }
      }
      
      // Apply filters
      List<JobSearchMatch> filteredJobs = [];
      
      for (final job in jobs) {
        final match = await _evaluateJobMatch(
          job: job,
          searchQuery: searchQuery,
          userPostcode: userPostcode,
          maxDistanceKm: maxDistanceKm,
          minSalary: minSalary,
          maxSalary: maxSalary,
          jobTypes: jobTypes,
          requiredCertificates: requiredCertificates,
          userCertificates: userCertificates,
          companyName: companyName,
          earliestStartDate: earliestStartDate,
          latestStartDate: latestStartDate,
          maxDurationHours: maxDurationHours,
        );
        
        if (match != null) {
          filteredJobs.add(match);
        }
      }
      
      // Sort results
      _sortJobResults(filteredJobs, sortBy, sortAscending);
      
      // Create search result
      final result = JobSearchResult(
        matches: filteredJobs,
        totalCount: filteredJobs.length,
        searchQuery: searchQuery,
        appliedFilters: JobSearchFilters(
          userPostcode: userPostcode,
          maxDistanceKm: maxDistanceKm,
          minSalary: minSalary,
          maxSalary: maxSalary,
          jobTypes: jobTypes,
          requiredCertificates: requiredCertificates,
          userCertificates: userCertificates,
          companyName: companyName,
          earliestStartDate: earliestStartDate,
          latestStartDate: latestStartDate,
          maxDurationHours: maxDurationHours,
        ),
        sortBy: sortBy,
        sortAscending: sortAscending,
        searchTimeMs: DateTime.now().millisecondsSinceEpoch,
      );
      
      // Cache the result for 5 minutes
      _searchCache[cacheKey] = result;
      
      return result;
      
    } catch (e) {
      debugPrint('Error in job search: $e');
      return JobSearchResult.empty();
    }
  }
  
  /// Quick search jobs by query only
  static Future<List<SecurityJobData>> quickSearch(
    String query, {
    List<SecurityJobData>? jobsToSearch,
    int maxResults = 50,
  }) async {
    final result = await searchJobs(
      searchQuery: query,
      jobsToSearch: jobsToSearch,
    );
    
    return result.matches
        .take(maxResults)
        .map((match) => match.job)
        .toList();
  }
  
  /// Search jobs near a specific postcode
  static Future<List<SecurityJobData>> searchJobsNearPostcode(
    String postcode, {
    double maxDistanceKm = 25.0,
    List<SecurityJobData>? jobsToSearch,
  }) async {
    final result = await searchJobs(
      userPostcode: postcode,
      maxDistanceKm: maxDistanceKm,
      jobsToSearch: jobsToSearch,
      sortBy: JobSortOption.distance,
    );
    
    return result.matches.map((match) => match.job).toList();
  }
  
  /// Search jobs by salary range
  static Future<List<SecurityJobData>> searchJobsBySalary(
    double minSalary,
    double maxSalary, {
    List<SecurityJobData>? jobsToSearch,
  }) async {
    final result = await searchJobs(
      minSalary: minSalary,
      maxSalary: maxSalary,
      jobsToSearch: jobsToSearch,
      sortBy: JobSortOption.salary,
      sortAscending: false, // Highest salary first
    );
    
    return result.matches.map((match) => match.job).toList();
  }
  
  /// Find jobs matching user's certificates
  static Future<List<JobSearchMatch>> findJobsMatchingCertificates(
    List<String> userCertificates, {
    List<SecurityJobData>? jobsToSearch,
  }) async {
    final result = await searchJobs(
      userCertificates: userCertificates,
      jobsToSearch: jobsToSearch,
      sortBy: JobSortOption.certificateMatch,
    );
    
    return result.matches;
  }
  
  /// Get job recommendations based on user profile
  static Future<List<JobRecommendation>> getJobRecommendations({
    required String userPostcode,
    required List<String> userCertificates,
    double preferredMinSalary = 18.0,
    double maxDistanceKm = 30.0,
    List<String>? preferredJobTypes,
    List<SecurityJobData>? jobsToSearch,
  }) async {
    final result = await searchJobs(
      userPostcode: userPostcode,
      userCertificates: userCertificates,
      minSalary: preferredMinSalary,
      maxDistanceKm: maxDistanceKm,
      jobTypes: preferredJobTypes,
      jobsToSearch: jobsToSearch,
      sortBy: JobSortOption.relevance,
    );
    
    return result.matches.map((match) => JobRecommendation(
      job: match.job,
      relevanceScore: match.relevanceScore,
      certificateMatch: match.certificateMatch,
      distanceKm: match.distanceKm,
      salaryMatch: match.salaryMatch,
      recommendations: match.certificateMatch?.recommendations ?? [],
    )).toList();
  }
  
  /// Evaluate if a job matches search criteria
  static Future<JobSearchMatch?> _evaluateJobMatch({
    required SecurityJobData job,
    String? searchQuery,
    String? userPostcode,
    double? maxDistanceKm,
    double? minSalary,
    double? maxSalary,
    List<String>? jobTypes,
    List<String>? requiredCertificates,
    List<String>? userCertificates,
    String? companyName,
    DateTime? earliestStartDate,
    DateTime? latestStartDate,
    int? maxDurationHours,
  }) async {
    try {
      // Text search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        if (!_matchesSearchQuery(job, searchQuery)) {
          return null;
        }
      }
      
      // Distance filter
      double? distance;
      if (userPostcode != null && maxDistanceKm != null) {
        // Extract postcode from job location (simplified)
        final jobPostcode = _extractPostcodeFromLocation(job.location);
        if (jobPostcode != null && PostcodeService.isValidDutchPostcode(jobPostcode)) {
          distance = await PostcodeService.calculateDistance(userPostcode, jobPostcode);
          if (distance > maxDistanceKm) {
            return null;
          }
        }
      }
      
      // Salary filters
      if (minSalary != null && job.hourlyRate < minSalary) {
        return null;
      }
      if (maxSalary != null && job.hourlyRate > maxSalary) {
        return null;
      }
      
      // Job type filter
      if (jobTypes != null && jobTypes.isNotEmpty) {
        if (!jobTypes.any((type) => job.jobType.toLowerCase().contains(type.toLowerCase()))) {
          return null;
        }
      }
      
      // Company filter
      if (companyName != null && companyName.isNotEmpty) {
        if (!job.companyName.toLowerCase().contains(companyName.toLowerCase())) {
          return null;
        }
      }
      
      // Date filters
      if (earliestStartDate != null && job.startDate != null) {
        if (job.startDate!.isBefore(earliestStartDate)) {
          return null;
        }
      }
      if (latestStartDate != null && job.startDate != null) {
        if (job.startDate!.isAfter(latestStartDate)) {
          return null;
        }
      }
      
      // Duration filter
      if (maxDurationHours != null && job.duration > maxDurationHours) {
        return null;
      }
      
      // Certificate matching
      CertificateMatchResult? certificateMatch;
      if (userCertificates != null && userCertificates.isNotEmpty) {
        certificateMatch = CertificateMatchingService.matchCertificates(
          userCertificates,
          job.requiredCertificates,
        );
        
        // If specific certificates are required, only show matching jobs
        if (requiredCertificates != null && requiredCertificates.isNotEmpty) {
          if (!certificateMatch.isEligible) {
            return null;
          }
        }
      }
      
      // Calculate relevance score
      final relevanceScore = _calculateRelevanceScore(
        job: job,
        searchQuery: searchQuery,
        certificateMatch: certificateMatch,
        distance: distance,
        userPostcode: userPostcode,
        maxDistanceKm: maxDistanceKm,
      );
      
      return JobSearchMatch(
        job: job,
        relevanceScore: relevanceScore,
        certificateMatch: certificateMatch,
        distanceKm: distance,
        salaryMatch: _calculateSalaryMatch(job.hourlyRate, minSalary, maxSalary),
        matchReasons: _getMatchReasons(job, searchQuery, certificateMatch),
      );
      
    } catch (e) {
      debugPrint('Error evaluating job match for ${job.jobId}: $e');
      return null;
    }
  }
  
  /// Check if job matches search query
  static bool _matchesSearchQuery(SecurityJobData job, String query) {
    final searchTerms = query.toLowerCase().split(' ');
    final searchableText = [
      job.jobTitle,
      job.companyName,
      job.location,
      job.jobType,
      job.description,
      ...job.requiredCertificates,
    ].join(' ').toLowerCase();
    
    return searchTerms.every((term) => searchableText.contains(term));
  }
  
  /// Extract postcode from location string (simplified)
  static String? _extractPostcodeFromLocation(String location) {
    final regex = RegExp(r'(\d{4}\s?[A-Z]{2})');
    final match = regex.firstMatch(location);
    return match?.group(1);
  }
  
  /// Calculate relevance score for job match
  static double _calculateRelevanceScore({
    required SecurityJobData job,
    String? searchQuery,
    CertificateMatchResult? certificateMatch,
    double? distance,
    String? userPostcode,
    double? maxDistanceKm,
  }) {
    double score = 50.0; // Base score
    
    // Text relevance
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final titleMatch = job.jobTitle.toLowerCase().contains(searchQuery.toLowerCase());
      if (titleMatch) score += 30.0;
      
      final companyMatch = job.companyName.toLowerCase().contains(searchQuery.toLowerCase());
      if (companyMatch) score += 10.0;
      
      final descriptionMatch = job.description.toLowerCase().contains(searchQuery.toLowerCase());
      if (descriptionMatch) score += 15.0;
    }
    
    // Certificate match scoring
    if (certificateMatch != null) {
      score += certificateMatch.matchScore * 0.3; // Scale to 30 points max
    }
    
    // Distance scoring (closer is better)
    if (distance != null && maxDistanceKm != null) {
      final distanceScore = ((maxDistanceKm - distance) / maxDistanceKm) * 20.0;
      score += distanceScore.clamp(0.0, 20.0);
    }
    
    // Salary attractiveness (higher hourly rate gets bonus)
    if (job.hourlyRate > 25.0) {
      score += ((job.hourlyRate - 25.0) / 10.0) * 10.0; // Up to 10 points bonus
    }
    
    // Company rating bonus
    if (job.companyRating > 4.0) {
      score += (job.companyRating - 4.0) * 5.0; // Up to 5 points bonus
    }
    
    // Recency bonus (jobs starting soon get priority)
    if (job.startDate != null) {
      final daysUntilStart = job.startDate!.difference(DateTime.now()).inDays;
      if (daysUntilStart >= 0 && daysUntilStart <= 7) {
        score += 5.0; // Jobs starting within a week get bonus
      }
    }
    
    return score.clamp(0.0, 100.0);
  }
  
  /// Calculate salary match score
  static double _calculateSalaryMatch(double jobSalary, double? minSalary, double? maxSalary) {
    if (minSalary == null && maxSalary == null) return 50.0;
    
    double score = 50.0;
    
    if (minSalary != null && jobSalary >= minSalary) {
      score += 25.0;
    }
    
    if (maxSalary != null && jobSalary <= maxSalary) {
      score += 25.0;
    }
    
    return score;
  }
  
  /// Get reasons why job matched search criteria
  static List<String> _getMatchReasons(
    SecurityJobData job,
    String? searchQuery,
    CertificateMatchResult? certificateMatch,
  ) {
    final reasons = <String>[];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (job.jobTitle.toLowerCase().contains(searchQuery.toLowerCase())) {
        reasons.add('Titel komt overeen met zoekopdracht');
      }
      if (job.companyName.toLowerCase().contains(searchQuery.toLowerCase())) {
        reasons.add('Bedrijfsnaam komt overeen');
      }
    }
    
    if (certificateMatch != null) {
      if (certificateMatch.isEligible) {
        reasons.add('Je bent gekwalificeerd voor deze functie');
      }
      if (certificateMatch.matchScore > 80) {
        reasons.add('Uitstekende certificaat match');
      }
    }
    
    if (job.hourlyRate > 25.0) {
      reasons.add('Aantrekkelijk uurloon (€${job.hourlyRate.toStringAsFixed(2)})');
    }
    
    if (job.companyRating > 4.5) {
      reasons.add('Hoogwaardige werkgever (${job.companyRating.toStringAsFixed(1)} sterren)');
    }
    
    return reasons;
  }
  
  /// Sort job search results
  static void _sortJobResults(
    List<JobSearchMatch> matches,
    JobSortOption sortBy,
    bool ascending,
  ) {
    matches.sort((a, b) {
      int comparison = 0;
      
      switch (sortBy) {
        case JobSortOption.relevance:
          comparison = b.relevanceScore.compareTo(a.relevanceScore);
          break;
        case JobSortOption.salary:
          comparison = a.job.hourlyRate.compareTo(b.job.hourlyRate);
          break;
        case JobSortOption.distance:
          final distanceA = a.distanceKm ?? double.infinity;
          final distanceB = b.distanceKm ?? double.infinity;
          comparison = distanceA.compareTo(distanceB);
          break;
        case JobSortOption.startDate:
          final dateA = a.job.startDate ?? DateTime(2099);
          final dateB = b.job.startDate ?? DateTime(2099);
          comparison = dateA.compareTo(dateB);
          break;
        case JobSortOption.companyRating:
          comparison = a.job.companyRating.compareTo(b.job.companyRating);
          break;
        case JobSortOption.certificateMatch:
          final scoreA = a.certificateMatch?.matchScore ?? 0;
          final scoreB = b.certificateMatch?.matchScore ?? 0;
          comparison = scoreA.compareTo(scoreB);
          break;
      }
      
      return ascending ? comparison : -comparison;
    });
  }
  
  /// Create cache key for search parameters
  static String _createCacheKey(Map<String, dynamic> params) {
    return params.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}:${entry.value}')
        .join('|');
  }
  
  /// Clear search cache
  static void clearCache() {
    _searchCache.clear();
  }
  
  /// Get cache size for debugging
  static int getCacheSize() {
    return _searchCache.length;
  }

  // =========================================================================
  // MOCK DATA SERVICE INTEGRATION
  // =========================================================================

  /// Enable or disable real data usage (deprecated - using real data by default now)
  @deprecated
  static void setUseMockData(bool useMock) {
    clearCache(); // Clear search cache when switching data sources
    debugPrint('JobSearchService: Always using real data from Firestore now');
  }

  /// Check if mock data is currently being used (always false now)
  @deprecated
  static bool get isUsingMockData => false;

  /// Get jobs by certificate requirements using real data
  static Future<List<SecurityJobData>> searchJobsByCertificates(
    List<String> userCertificates,
  ) async {
    final result = await searchJobs(userCertificates: userCertificates);
    return result.matches.map((match) => match.job).toList();
  }

  /// Get urgent jobs (starting soon)
  static Future<List<SecurityJobData>> getUrgentJobs() async {
    // Use regular search with date filter
    final urgentDate = DateTime.now().add(const Duration(days: 3));
    final result = await searchJobs(
      latestStartDate: urgentDate,
      sortBy: JobSortOption.startDate,
    );
    return result.matches.map((match) => match.job).toList();
  }

  /// Get high-paying jobs
  static Future<List<SecurityJobData>> getHighPayingJobs({
    double minSalary = 28.0,
  }) async {
    // Use regular search
    final result = await searchJobs(
      minSalary: minSalary,
      sortBy: JobSortOption.salary,
      sortAscending: false,
    );
    return result.matches.map((match) => match.job).toList();
  }

  /// Get weekend jobs
  static Future<List<SecurityJobData>> getWeekendJobs() async {
    // Use regular search
    final result = await searchJobs(searchQuery: 'weekend');
    return result.matches.map((match) => match.job).toList();
  }

  /// Get night shift jobs
  static Future<List<SecurityJobData>> getNightJobs() async {
    // Use regular search
    final result = await searchJobs(searchQuery: 'nacht');
    return result.matches.map((match) => match.job).toList();
  }

  /// Get entry-level jobs suitable for new guards
  static Future<List<SecurityJobData>> getEntryLevelJobs() async {
    // Use regular search with basic filters
    final result = await searchJobs(
      maxSalary: 22.0,
      requiredCertificates: ['WPBR'],
    );
    return result.matches.map((match) => match.job).toList();
  }

  /// Get comprehensive job market analytics
  static Future<Map<String, dynamic>> getJobMarketAnalytics() async {
    try {
      final jobs = await JobDataService.getAvailableJobs();
      if (jobs.isEmpty) {
        return {
          'dataSource': 'real',
          'isUsingMockData': false,
          'totalJobs': 0,
          'searchCacheSize': _searchCache.length,
          'error': 'No jobs available',
        };
      }
      
      return {
        'dataSource': 'real',
        'isUsingMockData': false,
        'totalJobs': jobs.length,
        'averageSalary': jobs
            .map((j) => j.hourlyRate)
            .reduce((a, b) => a + b) / jobs.length,
        'searchCacheSize': _searchCache.length,
        'jobTypes': jobs.map((j) => j.jobType).toSet().toList(),
        'locations': jobs.map((j) => j.location.split(',').first.trim()).toSet().toList(),
      };
    } catch (e) {
      return {
        'dataSource': 'real',
        'isUsingMockData': false,
        'totalJobs': 0,
        'searchCacheSize': _searchCache.length,
        'error': e.toString(),
      };
    }
  }

  /// Refresh job data (clears cache for fresh data fetch)
  static Future<void> refreshJobData() async {
    clearCache();
    debugPrint('JobSearchService: Cache cleared for real data refresh');
  }

  /// Get job by ID (works with real data)
  static Future<SecurityJobData?> getJobById(String jobId) async {
    // Use JobDataService for real data lookup
    try {
      return await JobDataService.getJobById(jobId);
    } catch (e) {
      // Fallback to searching in static list
      try {
        return SecurityJobData.jobList.firstWhere((job) => job.jobId == jobId);
      } catch (e2) {
        return null;
      }
    }
  }

  /// Simulate job data changes (deprecated - using real data now)
  @deprecated
  static Future<void> simulateDataChanges() async {
    clearCache(); // Clear search cache
    debugPrint('JobSearchService: Data simulation deprecated - using real Firestore data');
  }
}

/// Job search result container
class JobSearchResult extends Equatable {
  final List<JobSearchMatch> matches;
  final int totalCount;
  final String? searchQuery;
  final JobSearchFilters appliedFilters;
  final JobSortOption sortBy;
  final bool sortAscending;
  final int searchTimeMs;
  
  const JobSearchResult({
    required this.matches,
    required this.totalCount,
    this.searchQuery,
    required this.appliedFilters,
    required this.sortBy,
    required this.sortAscending,
    required this.searchTimeMs,
  });
  
  factory JobSearchResult.empty() {
    return JobSearchResult(
      matches: [],
      totalCount: 0,
      appliedFilters: const JobSearchFilters(),
      sortBy: JobSortOption.relevance,
      sortAscending: false,
      searchTimeMs: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  bool get isEmpty => matches.isEmpty;
  bool get isNotEmpty => matches.isNotEmpty;
  
  /// Check if cache result is expired (5 minutes)
  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - searchTimeMs) > 300000; // 5 minutes
  }
  
  @override
  List<Object?> get props => [
    matches,
    totalCount,
    searchQuery,
    appliedFilters,
    sortBy,
    sortAscending,
    searchTimeMs,
  ];
}

/// Individual job search match with scoring
class JobSearchMatch extends Equatable {
  final SecurityJobData job;
  final double relevanceScore;
  final CertificateMatchResult? certificateMatch;
  final double? distanceKm;
  final double salaryMatch;
  final List<String> matchReasons;
  
  const JobSearchMatch({
    required this.job,
    required this.relevanceScore,
    this.certificateMatch,
    this.distanceKm,
    required this.salaryMatch,
    required this.matchReasons,
  });
  
  @override
  List<Object?> get props => [
    job,
    relevanceScore,
    certificateMatch,
    distanceKm,
    salaryMatch,
    matchReasons,
  ];
}

/// Job search filters
class JobSearchFilters extends Equatable {
  final String? userPostcode;
  final double? maxDistanceKm;
  final double? minSalary;
  final double? maxSalary;
  final List<String>? jobTypes;
  final List<String>? requiredCertificates;
  final List<String>? userCertificates;
  final String? companyName;
  final DateTime? earliestStartDate;
  final DateTime? latestStartDate;
  final int? maxDurationHours;
  
  const JobSearchFilters({
    this.userPostcode,
    this.maxDistanceKm,
    this.minSalary,
    this.maxSalary,
    this.jobTypes,
    this.requiredCertificates,
    this.userCertificates,
    this.companyName,
    this.earliestStartDate,
    this.latestStartDate,
    this.maxDurationHours,
  });
  
  bool get hasActiveFilters {
    return userPostcode != null ||
           maxDistanceKm != null ||
           minSalary != null ||
           maxSalary != null ||
           (jobTypes != null && jobTypes!.isNotEmpty) ||
           (requiredCertificates != null && requiredCertificates!.isNotEmpty) ||
           companyName != null ||
           earliestStartDate != null ||
           latestStartDate != null ||
           maxDurationHours != null;
  }
  
  @override
  List<Object?> get props => [
    userPostcode,
    maxDistanceKm,
    minSalary,
    maxSalary,
    jobTypes,
    requiredCertificates,
    userCertificates,
    companyName,
    earliestStartDate,
    latestStartDate,
    maxDurationHours,
  ];
}

/// Job recommendation with detailed analysis
class JobRecommendation extends Equatable {
  final SecurityJobData job;
  final double relevanceScore;
  final CertificateMatchResult? certificateMatch;
  final double? distanceKm;
  final double salaryMatch;
  final List<String> recommendations;
  
  const JobRecommendation({
    required this.job,
    required this.relevanceScore,
    this.certificateMatch,
    this.distanceKm,
    required this.salaryMatch,
    required this.recommendations,
  });
  
  @override
  List<Object?> get props => [
    job,
    relevanceScore,
    certificateMatch,
    distanceKm,
    salaryMatch,
    recommendations,
  ];
}

/// Job sort options
enum JobSortOption {
  relevance,
  salary,
  distance,
  startDate,
  companyRating,
  certificateMatch,
}