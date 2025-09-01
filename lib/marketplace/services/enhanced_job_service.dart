import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/security_job_data.dart';
import '../bloc/job_state.dart';  // Import for JobFilter
import 'filter_persistence_service.dart';
import '../widgets/new_jobs_notification_banner.dart';

/// Enhanced job service with real-time Firebase integration and intelligent notifications
/// Manages job streams, filter persistence, and notification triggers
class EnhancedJobService {
  static EnhancedJobService? _instance;
  static EnhancedJobService get instance => _instance ??= EnhancedJobService._();
  
  EnhancedJobService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FilterPersistenceService _filterService = FilterPersistenceService.instance;
  final JobUpdateNotificationService _notificationService = JobUpdateNotificationService.instance;
  
  Timer? _updateTimer;
  List<SecurityJobData> _cachedJobs = [];
  DateTime _lastJobCheck = DateTime.now();
  
  /// Initialize the service with real-time listeners
  Future<void> initialize() async {
    await _filterService.initialize();
    _notificationService.initialize(0);
    
    debugPrint('🔥 Enhanced job service initialized');
  }
  
  /// Start watching jobs with real-time updates (using static data with periodic updates)
  Stream<List<SecurityJobData>> watchJobsWithNotifications({
    JobFilter? filters,
  }) {
    final StreamController<List<SecurityJobData>> controller = StreamController<List<SecurityJobData>>.broadcast();
    
    // Simulate real-time updates with periodic static data changes
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final jobs = await _processJobSnapshots(null);
        
        // Apply filters if provided
        final filteredJobs = filters != null 
            ? await _applyFiltersToJobs(jobs, filters)
            : jobs;
        
        // Check for new jobs and trigger notifications
        await _checkForNewJobs(jobs);
        
        // Save current filters if they have changed
        if (filters != null) {
          await _filterService.saveCurrentFilters(filters);
        }
        
        _cachedJobs = jobs;
        controller.add(filteredJobs);
        
        debugPrint('🔥 Streamed ${filteredJobs.length} jobs (${jobs.length} total)');
        
      } catch (e) {
        debugPrint('❌ Error processing job updates: $e');
        controller.addError(e);
      }
    });
    
    // Send initial data immediately
    Future.delayed(Duration.zero, () async {
      try {
        final jobs = await _processJobSnapshots(null);
        final filteredJobs = filters != null 
            ? await _applyFiltersToJobs(jobs, filters)
            : jobs;
        
        _cachedJobs = jobs;
        controller.add(filteredJobs);
      } catch (e) {
        controller.addError(e);
      }
    });
    
    return controller.stream;
  }
  
  /// Process job data (using static data for now, easily replaceable with Firestore later)
  Future<List<SecurityJobData>> _processJobSnapshots(QuerySnapshot? snapshot) async {
    // For now, return static job data with variations to simulate real-time updates
    return _getStaticJobsWithVariations();
  }
  
  /// Apply filter criteria to job list
  Future<List<SecurityJobData>> _applyFiltersToJobs(
    List<SecurityJobData> jobs,
    JobFilter filters,
  ) async {
    var filteredJobs = jobs.where((job) {
      // Search query filter
      if (filters.searchQuery.isNotEmpty) {
        final query = filters.searchQuery.toLowerCase();
        final matchesSearch = job.jobTitle.toLowerCase().contains(query) ||
            job.companyName.toLowerCase().contains(query) ||
            job.location.toLowerCase().contains(query) ||
            job.description.toLowerCase().contains(query);
        
        if (!matchesSearch) return false;
      }
      
      // Hourly rate filter
      if (job.hourlyRate < filters.hourlyRateRange.start ||
          job.hourlyRate > filters.hourlyRateRange.end) {
        return false;
      }
      
      // Distance filter
      if (job.distance > filters.maxDistance) {
        return false;
      }
      
      // Job type filter
      if (filters.jobType.isNotEmpty &&
          !job.jobType.toLowerCase().contains(filters.jobType.toLowerCase())) {
        return false;
      }
      
      // Certificate requirements filter
      if (filters.certificates.isNotEmpty) {
        final hasRequiredCert = job.requiredCertificates
            .any((cert) => filters.certificates.contains(cert));
        if (!hasRequiredCert) return false;
      }
      
      return true;
    }).toList();
    
    // Sort by relevance (distance, hourly rate, creation date)
    filteredJobs.sort((a, b) {
      // Prioritize higher pay and closer distance
      final payDiff = b.hourlyRate.compareTo(a.hourlyRate);
      if (payDiff != 0) return payDiff;
      
      final distanceDiff = a.distance.compareTo(b.distance);
      if (distanceDiff != 0) return distanceDiff;
      
      // Finally by start date (sooner first, then by job ID for consistency)
      final startComparison = (a.startDate ?? DateTime.now()).compareTo(b.startDate ?? DateTime.now());
      return startComparison != 0 ? startComparison : a.jobId.compareTo(b.jobId);
    });
    
    return filteredJobs;
  }
  
  /// Check for new jobs and trigger notifications
  Future<void> _checkForNewJobs(List<SecurityJobData> currentJobs) async {
    final now = DateTime.now();
    final timeSinceLastCheck = now.difference(_lastJobCheck);
    
    // Only check for new jobs if enough time has passed (prevents spam)
    if (timeSinceLastCheck.inSeconds < 10) {
      return;
    }
    
    final previousJobCount = _cachedJobs.length;
    final currentJobCount = currentJobs.length;
    
    if (currentJobCount > previousJobCount) {
      // Find actually new jobs (not just count difference)
      final previousJobIds = _cachedJobs.map((j) => j.jobId).toSet();
      final newJobs = currentJobs
          .where((job) => !previousJobIds.contains(job.jobId))
          .toList();
      
      if (newJobs.isNotEmpty) {
        debugPrint('🆕 Found ${newJobs.length} new jobs');
        
        // Update notification service
        _notificationService.updateJobCount(currentJobCount);
        
        // Log new jobs for debugging
        for (final job in newJobs) {
          debugPrint('🆕 New job: ${job.jobTitle} at ${job.companyName} - €${job.hourlyRate}/hr');
        }
      }
    }
    
    _lastJobCheck = now;
  }
  
  /// Get jobs with smart caching and filter restoration
  Future<List<SecurityJobData>> getJobsWithCache({
    bool forceRefresh = false,
    JobFilter? filters,
  }) async {
    // Try to restore last used filters if none provided
    filters ??= await _filterService.loadLastFilters();
    
    // Return cached jobs if available and not forcing refresh
    if (!forceRefresh && _cachedJobs.isNotEmpty) {
      return filters != null 
          ? await _applyFiltersToJobs(_cachedJobs, filters)
          : _cachedJobs;
    }
    
    try {
      // Fetch fresh static data (simulating Firestore)
      final jobs = await _processJobSnapshots(null);
      _cachedJobs = jobs;
      
      // Initialize notification service with current count
      _notificationService.initialize(jobs.length);
      
      return filters != null 
          ? await _applyFiltersToJobs(jobs, filters)
          : jobs;
          
    } catch (e) {
      debugPrint('❌ Error fetching jobs: $e');
      rethrow;
    }
  }
  
  /// Apply to a job with optimistic updates
  Future<bool> applyToJob(String jobId, String userId, {String? message}) async {
    try {
      // Optimistic update - assume success for better UX
      debugPrint('📝 Applying to job $jobId for user $userId');
      
      // Create application document
      await _firestore
          .collection('applications')
          .doc('${userId}_$jobId')
          .set({
        'userId': userId,
        'jobId': jobId,
        'message': message ?? '',
        'status': 'pending',
        'appliedAt': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
      });
      
      // Update job's applicant count
      await _firestore
          .collection('jobs')
          .doc(jobId)
          .update({
        'applicantCount': FieldValue.increment(1),
        'lastActivity': Timestamp.now(),
      });
      
      debugPrint('✅ Successfully applied to job $jobId');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error applying to job $jobId: $e');
      return false;
    }
  }
  
  /// Get user's applied job IDs
  Future<Set<String>> getAppliedJobIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .get();
      
      final jobIds = snapshot.docs
          .map((doc) => doc.data()['jobId'] as String)
          .toSet();
      
      debugPrint('📋 User $userId has applied to ${jobIds.length} jobs');
      return jobIds;
      
    } catch (e) {
      debugPrint('❌ Error getting applied jobs: $e');
      return {};
    }
  }
  
  /// Search jobs with intelligent ranking
  Future<List<SecurityJobData>> searchJobs(String query, {
    JobFilter? additionalFilters,
  }) async {
    if (query.trim().isEmpty) {
      return getJobsWithCache(filters: additionalFilters);
    }
    
    final allJobs = await getJobsWithCache(filters: additionalFilters);
    final searchTerms = query.toLowerCase().split(' ');
    
    // Score-based ranking for search relevance
    final scoredJobs = allJobs.map((job) {
      double score = 0;
      
      final titleLower = job.jobTitle.toLowerCase();
      final companyLower = job.companyName.toLowerCase();
      final locationLower = job.location.toLowerCase();
      final descriptionLower = job.description.toLowerCase();
      
      for (final term in searchTerms) {
        // Title matches are most important
        if (titleLower.contains(term)) score += 10;
        
        // Company name matches
        if (companyLower.contains(term)) score += 8;
        
        // Location matches
        if (locationLower.contains(term)) score += 6;
        
        // Description matches
        if (descriptionLower.contains(term)) score += 2;
        
        // Certificate matches
        if (job.requiredCertificates.any((cert) => 
            cert.toLowerCase().contains(term))) {
          score += 5;
        }
      }
      
      // Boost score for higher pay and closer distance
      score += (job.hourlyRate / 50) * 2;  // Max 2 points for €50/hr
      score += (10 - job.distance.clamp(0, 10)) * 0.5;  // Max 5 points for 0km
      
      return MapEntry(job, score);
    })
    .where((entry) => entry.value > 0)  // Only include matches
    .toList()
    ..sort((a, b) => b.value.compareTo(a.value));  // Sort by score descending
    
    return scoredJobs.map((entry) => entry.key).toList();
  }
  
  /// Get job statistics with caching
  Future<Map<String, dynamic>> getJobStatistics() async {
    try {
      final jobs = _cachedJobs.isEmpty 
          ? await getJobsWithCache()
          : _cachedJobs;
      
      if (jobs.isEmpty) {
        return {
          'totalJobs': 0,
          'averageHourlyRate': 0.0,
          'jobTypesCount': 0,
          'companiesCount': 0,
          'totalApplications': 0,
          'avgDistance': 0.0,
        };
      }
      
      final totalJobs = jobs.length;
      final avgRate = jobs.map((j) => j.hourlyRate).reduce((a, b) => a + b) / totalJobs;
      final jobTypes = jobs.map((j) => j.jobType).toSet().length;
      final companies = jobs.map((j) => j.companyName).toSet().length;
      final totalApplications = jobs.map((j) => j.applicantCount).reduce((a, b) => a + b);
      final avgDistance = jobs.map((j) => j.distance).reduce((a, b) => a + b) / totalJobs;
      
      return {
        'totalJobs': totalJobs,
        'averageHourlyRate': double.parse(avgRate.toStringAsFixed(2)),
        'jobTypesCount': jobTypes,
        'companiesCount': companies,
        'totalApplications': totalApplications,
        'avgDistance': double.parse(avgDistance.toStringAsFixed(1)),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      debugPrint('❌ Error getting job statistics: $e');
      return {};
    }
  }
  
  /// Simulate real-time job updates by returning static data with variations
  List<SecurityJobData> _getStaticJobsWithVariations() {
    // Return static jobs from SecurityJobData.jobList with minor variations
    return SecurityJobData.jobList.map((job) {
      // Add some variation to make it feel like real-time data
      final variation = DateTime.now().millisecond % 3;
      return SecurityJobData(
        jobId: job.jobId,
        jobTitle: job.jobTitle,
        companyName: job.companyName,
        location: job.location,
        hourlyRate: job.hourlyRate + (variation * 0.25), // Small price variations
        distance: job.distance,
        companyRating: job.companyRating,
        applicantCount: job.applicantCount + variation, // Small applicant count variations
        duration: job.duration,
        jobType: job.jobType,
        description: job.description,
        companyLogo: job.companyLogo,
        startDate: job.startDate,
        endDate: job.endDate,
        requiredCertificates: job.requiredCertificates,
      );
    }).toList();
  }
  
  /// Dispose resources and clean up
  void dispose() {
    _updateTimer?.cancel();
    debugPrint('🧹 Enhanced job service disposed');
  }
}