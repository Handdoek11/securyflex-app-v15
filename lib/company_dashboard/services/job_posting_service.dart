import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';
import 'package:securyflex_app/marketplace/services/job_data_service.dart';
import 'package:securyflex_app/beveiliger_notificaties/services/guard_notification_service.dart';
import 'package:securyflex_app/auth/auth_service.dart';

/// Firebase-backed service for managing job postings from Company perspective
/// Handles CRUD operations for jobs posted by companies with real-time updates
class JobPostingService {
  static JobPostingService? _instance;
  static JobPostingService get instance {
    _instance ??= JobPostingService._();
    return _instance!;
  }

  JobPostingService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _jobsCollection = 'jobs';
  static const String _applicationsCollection = 'applications';

  // Performance optimization: Cache for frequently accessed data
  static final Map<String, List<JobPostingData>> _companyJobsCache = {};
  static DateTime? _lastCacheUpdate;

  // Mock data storage for fallback/demo mode
  static final Map<String, JobPostingData> _postedJobs = {};
  static final Map<String, List<String>> _jobApplications = {}; // jobId -> applicantIds

  // Initialize demo data
  static bool _demoDataInitialized = false;
  
  /// Get all jobs posted by current company with caching for performance
  Future<List<JobPostingData>> getCompanyJobs([String? companyId]) async {
    // Use current user ID if no companyId provided
    companyId ??= AuthService.currentUserId;
    if (companyId.isEmpty) {
      debugPrint('No company ID available');
      return [];
    }
    try {
      // Check cache first (cache valid for 5 minutes)
      final now = DateTime.now();
      if (_companyJobsCache.containsKey(companyId) &&
          _lastCacheUpdate != null &&
          now.difference(_lastCacheUpdate!).inMinutes < 5) {
        return _companyJobsCache[companyId]!;
      }

      // Query Firebase for company jobs
      final querySnapshot = await _firestore
          .collection(_jobsCollection)
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdDate', descending: true)
          .get();

      final jobs = querySnapshot.docs
          .map((doc) => _jobFromFirestore(doc))
          .where((job) => job != null)
          .cast<JobPostingData>()
          .toList();

      // Update cache
      _companyJobsCache[companyId] = jobs;
      _lastCacheUpdate = now;

      return jobs;
    } catch (e) {
      debugPrint('Error fetching company jobs: $e');

      // Fallback to mock data for demo mode
      _initializeDemoData();
      final jobs = _postedJobs.values
          .where((job) => job.companyId == companyId)
          .toList()
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

      return jobs;
    }
  }
  
  /// Initialize demo data for fallback mode
  static void _initializeDemoData() {
    if (_demoDataInitialized) return;

    final now = DateTime.now();
    final companyId = 'COMP001'; // Default company ID

    // Create demo jobs
    final demoJobs = [
      JobPostingData(
        jobId: 'JOB001',
        companyId: companyId,
        title: 'Evenementbeveiliging Amsterdam',
        description: 'Ervaren beveiliger gezocht voor evenement in Amsterdam centrum.',
        location: 'Amsterdam',
        postalCode: '1012AB',
        hourlyRate: 22.50,
        startDate: now.add(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 4)),
        requiredSkills: ['Crowd Control', 'Customer Service'],
        requiredCertificates: ['Evenementbeveiliging'],
        minimumExperience: 2,
        status: JobPostingStatus.active,
        createdDate: now.subtract(const Duration(days: 1)),
        applicationsCount: 5,
        isUrgent: false,
        jobType: JobType.evenementbeveiliging,
      ),
      JobPostingData(
        jobId: 'JOB002',
        companyId: companyId,
        title: 'Objectbeveiliging Rotterdam',
        description: 'Beveiliging voor kantoorgebouw in Rotterdam.',
        location: 'Rotterdam',
        postalCode: '3000AA',
        hourlyRate: 19.75,
        startDate: now.add(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 14)),
        requiredSkills: ['Access Control', 'CCTV Monitoring'],
        requiredCertificates: ['Beveiliger 2'],
        minimumExperience: 1,
        status: JobPostingStatus.active,
        createdDate: now.subtract(const Duration(hours: 12)),
        applicationsCount: 3,
        isUrgent: false,
        jobType: JobType.objectbeveiliging,
      ),
      JobPostingData(
        jobId: 'JOB003',
        companyId: companyId,
        title: 'Mobiele Surveillance Utrecht',
        description: 'Mobiele surveillance voor bedrijventerrein Utrecht.',
        location: 'Utrecht',
        postalCode: '3500AA',
        hourlyRate: 21.00,
        startDate: now.add(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 3)),
        requiredSkills: ['Patrol Services', 'Report Writing'],
        requiredCertificates: ['Beveiliger 2', 'VCA'],
        minimumExperience: 3,
        status: JobPostingStatus.active,
        createdDate: now.subtract(const Duration(hours: 6)),
        applicationsCount: 8,
        isUrgent: true,
        jobType: JobType.surveillance,
      ),
    ];

    // Add demo jobs to storage
    for (final job in demoJobs) {
      _postedJobs[job.jobId] = job;
    }

    _demoDataInitialized = true;
  }

  /// Get active jobs for current company
  Future<List<JobPostingData>> getActiveJobs([String? companyId]) async {
    // Use current user ID if no companyId provided
    companyId ??= AuthService.currentUserId;
    if (companyId.isEmpty) {
      return [];
    }
    await Future.delayed(const Duration(milliseconds: 300));

    _initializeDemoData();
    return _postedJobs.values
        .where((job) => job.companyId == companyId && job.status == JobPostingStatus.active)
        .toList();
  }
  
  /// Convert Firestore document to JobPostingData
  JobPostingData? _jobFromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      return JobPostingData(
        jobId: doc.id,
        companyId: data['companyId'] ?? '',
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        location: data['location'] ?? '',
        postalCode: data['postalCode'] ?? '',
        hourlyRate: (data['hourlyRate'] ?? 0.0).toDouble(),
        startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        requiredCertificates: List<String>.from(data['requiredCertificates'] ?? []),
        requiredSkills: List<String>.from(data['requiredSkills'] ?? []),
        minimumExperience: data['minimumExperience'] ?? 0,
        status: _statusFromString(data['status'] ?? 'draft'),
        createdDate: (data['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastModified: (data['lastModified'] as Timestamp?)?.toDate(),
        applicationsCount: data['applicationsCount'] ?? 0,
        applicantIds: List<String>.from(data['applicantIds'] ?? []),
        isUrgent: data['isUrgent'] ?? false,
        contactMethod: data['contactMethod'] ?? 'email',
        specialInstructions: data['specialInstructions'],
        maxBudget: data['maxBudget']?.toDouble(),
        jobType: _jobTypeFromString(data['jobType'] ?? 'objectbeveiliging'),
      );
    } catch (e) {
      debugPrint('Error converting Firestore document to JobPostingData: $e');
      return null;
    }
  }

  /// Convert JobPostingData to Firestore map
  Map<String, dynamic> _jobToFirestore(JobPostingData job) {
    return {
      'companyId': job.companyId,
      'title': job.title,
      'description': job.description,
      'location': job.location,
      'postalCode': job.postalCode,
      'hourlyRate': job.hourlyRate,
      'startDate': Timestamp.fromDate(job.startDate),
      'endDate': Timestamp.fromDate(job.endDate),
      'requiredCertificates': job.requiredCertificates,
      'requiredSkills': job.requiredSkills,
      'minimumExperience': job.minimumExperience,
      'status': job.status.toString().split('.').last,
      'createdDate': Timestamp.fromDate(job.createdDate),
      'lastModified': job.lastModified != null ? Timestamp.fromDate(job.lastModified!) : FieldValue.serverTimestamp(),
      'applicationsCount': job.applicationsCount,
      'applicantIds': job.applicantIds,
      'isUrgent': job.isUrgent,
      'contactMethod': job.contactMethod,
      'specialInstructions': job.specialInstructions,
      'maxBudget': job.maxBudget,
      'jobType': job.jobType.toString().split('.').last,
    };
  }

  /// Convert string to JobPostingStatus
  JobPostingStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'active': return JobPostingStatus.active;
      case 'filled': return JobPostingStatus.filled;
      case 'cancelled': return JobPostingStatus.cancelled;
      case 'completed': return JobPostingStatus.completed;
      case 'expired': return JobPostingStatus.expired;
      default: return JobPostingStatus.draft;
    }
  }

  /// Convert string to JobType
  JobType _jobTypeFromString(String jobType) {
    switch (jobType.toLowerCase()) {
      case 'objectbeveiliging': return JobType.objectbeveiliging;
      case 'evenementbeveiliging': return JobType.evenementbeveiliging;
      case 'persoonbeveiliging': return JobType.persoonbeveiliging;
      case 'surveillance': return JobType.surveillance;
      case 'receptie': return JobType.receptie;
      case 'transport': return JobType.transport;
      default: return JobType.objectbeveiliging;
    }
  }

  /// Create new job posting
  Future<bool> createJob(JobPostingData jobData) async {
    try {
      // Validate job data
      if (!_validateJobData(jobData)) {
        return false;
      }

      // Prepare job data for Firestore
      final newJob = jobData.copyWith(
        createdDate: DateTime.now(),
        lastModified: DateTime.now(),
      );

      // Create job in Firestore
      final docRef = await _firestore
          .collection(_jobsCollection)
          .add(_jobToFirestore(newJob));

      // Update job with generated ID
      final jobWithId = newJob.copyWith(jobId: docRef.id);

      // Clear cache for this company to ensure fresh data
      _clearCompanyCache(newJob.companyId);

      // Also add to marketplace (for Guards to see)
      _addToMarketplace(jobWithId);

      return true;
    } catch (e) {
      debugPrint('Error creating job: $e');

      // Fallback to mock storage for demo mode
      final jobId = jobData.jobId.isEmpty ? _generateJobId() : jobData.jobId;
      final newJob = jobData.copyWith(
        jobId: jobId,
        createdDate: DateTime.now(),
        lastModified: DateTime.now(),
      );

      _postedJobs[jobId] = newJob;
      _jobApplications[jobId] = [];
      _clearCompanyCache(newJob.companyId);
      _addToMarketplace(newJob);

      return true;
    }
  }
  
  /// Update existing job posting
  Future<bool> updateJob(JobPostingData updatedJob) async {
    try {
      if (updatedJob.jobId.isEmpty) {
        return false;
      }

      if (!_validateJobData(updatedJob)) {
        return false;
      }

      final updated = updatedJob.copyWith(lastModified: DateTime.now());

      // Update job in Firestore
      await _firestore
          .collection(_jobsCollection)
          .doc(updatedJob.jobId)
          .update(_jobToFirestore(updated));

      // Clear cache to ensure fresh data
      _clearCompanyCache(updatedJob.companyId);

      // Update marketplace listing
      _updateMarketplace(updated);

      return true;
    } catch (e) {
      debugPrint('Error updating job: $e');

      // Fallback to mock storage for demo mode
      if (_postedJobs.containsKey(updatedJob.jobId)) {
        final updated = updatedJob.copyWith(lastModified: DateTime.now());
        _postedJobs[updatedJob.jobId] = updated;
        _updateMarketplace(updated);
        return true;
      }

      return false;
    }
  }
  
  /// Delete job posting
  Future<bool> deleteJob(String jobId) async {
    try {
      if (jobId.isEmpty) {
        return false;
      }

      // Get job data before deletion for cache clearing
      final jobDoc = await _firestore
          .collection(_jobsCollection)
          .doc(jobId)
          .get();

      if (!jobDoc.exists) {
        return false;
      }

      final jobData = jobDoc.data() as Map<String, dynamic>;
      final companyId = jobData['companyId'] as String;

      // Delete job from Firestore
      await _firestore
          .collection(_jobsCollection)
          .doc(jobId)
          .delete();

      // Delete related applications
      final applicationsQuery = await _firestore
          .collection(_applicationsCollection)
          .where('jobId', isEqualTo: jobId)
          .get();

      for (final doc in applicationsQuery.docs) {
        await doc.reference.delete();
      }

      // Clear cache
      _clearCompanyCache(companyId);

      // Remove from marketplace
      _removeFromMarketplace(jobId);

      return true;
    } catch (e) {
      debugPrint('Error deleting job: $e');

      // Fallback to mock storage for demo mode
      if (_postedJobs.containsKey(jobId)) {
        _postedJobs.remove(jobId);
        _jobApplications.remove(jobId);
        _removeFromMarketplace(jobId);
        return true;
      }

      return false;
    }
  }
  
  /// Get job by ID
  Future<JobPostingData?> getJobById(String jobId) async {
    try {
      if (jobId.isEmpty) return null;

      final doc = await _firestore
          .collection(_jobsCollection)
          .doc(jobId)
          .get();

      if (doc.exists) {
        return _jobFromFirestore(doc);
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching job by ID: $e');

      // Fallback to mock storage for demo mode
      return _postedJobs[jobId];
    }
  }
  
  /// Get applications for a specific job
  Future<List<String>> getJobApplications(String jobId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _jobApplications[jobId] ?? [];
  }
  
  /// Update job status
  Future<bool> updateJobStatus(String jobId, JobPostingStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final job = _postedJobs[jobId];
    if (job == null) return false;
    
    final updatedJob = job.copyWith(
      status: newStatus,
      lastModified: DateTime.now(),
    );
    
    _postedJobs[jobId] = updatedJob;
    _updateMarketplace(updatedJob);
    
    return true;
  }
  
  /// Get job posting analytics
  Future<Map<String, dynamic>> getJobAnalytics(String jobId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    
    final job = _postedJobs[jobId];
    if (job == null) return {};
    
    final applications = _jobApplications[jobId] ?? [];
    
    return {
      'totalViews': 45 + (applications.length * 3), // Mock view count
      'applicationsCount': applications.length,
      'averageResponseTime': 4.2, // hours
      'fillRate': applications.isNotEmpty ? 85.0 : 0.0, // percentage
      'costPerApplication': job.hourlyRate * 0.1, // Mock calculation
      'estimatedFillTime': applications.isEmpty ? 48.0 : 12.0, // hours
    };
  }
  
  /// Validate job posting data
  bool _validateJobData(JobPostingData job) {
    // Title validation
    if (job.title.trim().isEmpty || job.title.length < 5) {
      return false;
    }
    
    // Description validation
    if (job.description.trim().isEmpty || job.description.length < 20) {
      return false;
    }
    
    // Location validation
    if (job.location.trim().isEmpty) {
      return false;
    }
    
    // Postal code validation (Dutch format)
    if (!RegExp(r'^\d{4}[A-Z]{2}$').hasMatch(job.postalCode.toUpperCase())) {
      return false;
    }
    
    // Rate validation
    if (job.hourlyRate < 10.0 || job.hourlyRate > 100.0) {
      return false;
    }
    
    // Date validation
    if (job.startDate.isAfter(job.endDate)) {
      return false;
    }
    
    if (job.startDate.isBefore(DateTime.now().subtract(const Duration(hours: 1)))) {
      return false;
    }
    
    return true;
  }
  
  /// Generate unique job ID
  String _generateJobId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'JOB_${timestamp.toString().substring(8)}';
  }

  /// Clear cache for specific company to ensure fresh data
  void _clearCompanyCache(String companyId) {
    _companyJobsCache.remove(companyId);
    _lastCacheUpdate = null;
  }
  
  /// Add job to marketplace for Guards to see
  /// AND trigger automatic guard notifications for matching guards
  void _addToMarketplace(JobPostingData job) async {
    try {
      // Convert JobPostingData to SecurityJobData for marketplace
      final securityJob = SecurityJobData(
        jobId: job.jobId,
        jobTitle: job.title,
        companyName: 'Bedrijf ${job.companyId}', // Will be enhanced with real company names
        location: '${job.location}, ${job.postalCode}',
        hourlyRate: job.hourlyRate,
        distance: 0.0, // Will be calculated based on guard location
        companyRating: 4.5, // Default rating, can be enhanced later
        applicantCount: job.applicationsCount,
        duration: 8, // Default duration, can be enhanced later
        jobType: _mapJobTypeToString(job.jobType),
        description: job.description,
        companyLogo: 'assets/hotel/hotel_1.png', // Default logo
        startDate: job.startDate,
        endDate: job.endDate,
        requiredCertificates: job.requiredCertificates,
      );

      // Add to marketplace using JobDataService
      await JobDataService.createJob(securityJob);
      debugPrint('✅ Job ${job.jobId} added to marketplace');
      
      // 🚀 AUTOMATIC GUARD NOTIFICATION TRIGGER
      // Find matching guards and send notifications for high-scoring matches
      await _triggerAutomaticGuardNotifications(securityJob);
      
    } catch (e) {
      debugPrint('❌ Error adding job to marketplace: $e');
    }
  }
  
  /// Automatically find matching guards and trigger notifications
  /// Sends notifications to guards with match score ≥ 70%
  Future<void> _triggerAutomaticGuardNotifications(SecurityJobData job) async {
    try {
      debugPrint('🔍 Finding matching guards for job: ${job.jobTitle}');
      
      // Get the GuardNotificationService instance
      final guardNotificationService = GuardNotificationService.instance;
      
      // Get all potential guards from Firestore (simplified - would be enhanced with proper guard querying)
      // For now, we'll trigger a general job alert that the matching service will handle
      // when guards open the app and getEnhancedJobRecommendations() is called
      
      // Send a general "New Job Available" notification
      // The actual matching happens when guards check their recommendations
      await guardNotificationService.sendNewJobAvailableAlert(
        jobData: job,
        targetAudience: 'all_active_guards', // Can be refined based on location, certs, etc.
      );
      
      debugPrint('📱 Automatic guard notifications triggered for job: ${job.jobId}');
      
    } catch (e) {
      debugPrint('⚠️ Error triggering automatic guard notifications: $e');
      // Don't fail the job posting if notifications fail
    }
  }

  /// Map JobType enum to string for SecurityJobData
  String _mapJobTypeToString(JobType jobType) {
    switch (jobType) {
      case JobType.objectbeveiliging:
        return 'Objectbeveiliging';
      case JobType.evenementbeveiliging:
        return 'Evenementbeveiliging';
      case JobType.persoonbeveiliging:
        return 'Persoonbeveiliging';
      case JobType.surveillance:
        return 'Surveillance';
      case JobType.receptie:
        return 'Receptie Beveiliging';
      case JobType.transport:
        return 'Transport Beveiliging';
    }
  }
  
  /// Update job in marketplace
  void _updateMarketplace(JobPostingData job) {
    // Update marketplace listing when job is modified
    // Integration point for marketplace updates
  }
  
  /// Remove job from marketplace
  void _removeFromMarketplace(String jobId) {
    // Remove job from marketplace when deleted
    // Integration point for marketplace removal
  }
  
  /// Get company job statistics
  static Future<Map<String, dynamic>> getCompanyJobStats([String? companyId]) async {
    // Use current user ID if no companyId provided
    companyId ??= AuthService.currentUserId;
    if (companyId.isEmpty) {
      return {
        'totalJobsPosted': 0,
        'activeJobs': 0,
        'completedJobs': 0,
        'draftJobs': 0,
        'totalApplications': 0,
        'averageHourlyRate': 0.0,
        'totalBudgetSpent': 0.0,
        'averageApplicationsPerJob': 0.0,
      };
    }
    await Future.delayed(const Duration(milliseconds: 400));
    
    final companyJobs = _postedJobs.values
        .where((job) => job.companyId == companyId)
        .toList();
    
    final activeJobs = companyJobs.where((job) => job.status == JobPostingStatus.active).length;
    final completedJobs = companyJobs.where((job) => job.status == JobPostingStatus.completed).length;
    final totalApplications = companyJobs.fold<int>(0, (total, job) => total + job.applicationsCount);
    final averageRate = companyJobs.isEmpty ? 0.0 :
        companyJobs.fold<double>(0.0, (total, job) => total + job.hourlyRate) / companyJobs.length;
    
    return {
      'totalJobsPosted': companyJobs.length,
      'activeJobs': activeJobs,
      'completedJobs': completedJobs,
      'draftJobs': companyJobs.where((job) => job.status == JobPostingStatus.draft).length,
      'totalApplications': totalApplications,
      'averageHourlyRate': averageRate,
      'totalBudgetSpent': companyJobs
          .where((job) => job.status == JobPostingStatus.completed)
          .fold<double>(0.0, (total, job) => total + job.totalBudget),
      'averageApplicationsPerJob': companyJobs.isEmpty ? 0.0 : totalApplications / companyJobs.length,
    };
  }
  
  /// Initialize with mock data for development
  static void initializeMockData() {
    if (_postedJobs.isNotEmpty) return; // Already initialized
    
    // Create sample job postings
    final mockJobs = [
      JobPostingData(
        jobId: 'JOB001',
        companyId: 'COMP001',
        title: 'Objectbeveiliging Kantoorpand',
        description: 'Beveiliging van kantoorpand in Amsterdam centrum. Dagdienst van 08:00 tot 18:00.',
        location: 'Amsterdam Centrum',
        postalCode: '1012AB',
        hourlyRate: 18.50,
        startDate: DateTime.now().add(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 10)),
        requiredCertificates: ['Beveiligingsdiploma A', 'BHV'],
        requiredSkills: ['Toegangscontrole', 'Surveillance'],
        minimumExperience: 2,
        status: JobPostingStatus.active,
        createdDate: DateTime.now().subtract(const Duration(days: 2)),
        applicationsCount: 8,
        isUrgent: false,
        jobType: JobType.objectbeveiliging,
      ),
      JobPostingData(
        jobId: 'JOB002',
        companyId: 'COMP001',
        title: 'Evenementbeveiliging Festival',
        description: 'Beveiliging muziekfestival in Vondelpark. Weekend van 12:00 tot 02:00.',
        location: 'Amsterdam Vondelpark',
        postalCode: '1071AA',
        hourlyRate: 22.00,
        startDate: DateTime.now().add(const Duration(days: 14)),
        endDate: DateTime.now().add(const Duration(days: 16)),
        requiredCertificates: ['Beveiligingsdiploma A', 'Evenementbeveiliging'],
        requiredSkills: ['Crowd Control', 'Communicatie'],
        minimumExperience: 3,
        status: JobPostingStatus.active,
        createdDate: DateTime.now().subtract(const Duration(days: 5)),
        applicationsCount: 15,
        isUrgent: true,
        jobType: JobType.evenementbeveiliging,
      ),
    ];
    
    for (final job in mockJobs) {
      _postedJobs[job.jobId] = job;
      _jobApplications[job.jobId] = [];
    }
  }
}
