import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../repository/job_repository.dart';
import '../model/security_job_data.dart';
import '../services/certificate_matching_service.dart';

/// Firebase-backed JobRepository implementation
/// 
/// Provides comprehensive Firebase Firestore integration for job data management
/// with real-time updates, advanced filtering, and Nederlandse business compliance.
/// Implements caching, error handling, and offline support.
class FirebaseJobRepository implements JobRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _jobsCollection = 'jobs';
  static const String _applicationsCollection = 'applications';
  
  // Cache for performance optimization
  static List<SecurityJobData>? _cachedJobs;
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  
  // Stream controllers for real-time updates
  
  @override
  Future<List<SecurityJobData>> getJobs() async {
    try {
      // Return cached jobs if still valid
      if (_isCacheValid()) {
        return _cachedJobs!;
      }
      
      // Fetch jobs from Firestore
      final querySnapshot = await _firestore
          .collection(_jobsCollection)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();
      
      final jobs = querySnapshot.docs
          .map((doc) => _jobFromFirestore(doc))
          .where((job) => job != null)
          .cast<SecurityJobData>()
          .toList();
      
      // Update cache
      _cachedJobs = jobs;
      _lastCacheUpdate = DateTime.now();
      
      return jobs;
      
    } catch (e) {
      debugPrint('Error fetching jobs from Firebase: $e');
      
      // Fallback to static data if Firebase fails
      if (_cachedJobs != null) {
        return _cachedJobs!;
      }
      
      return SecurityJobData.jobList;
    }
  }
  
  @override
  Stream<List<SecurityJobData>> watchJobs() {
    try {
      return _firestore
          .collection(_jobsCollection)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            final jobs = snapshot.docs
                .map((doc) => _jobFromFirestore(doc))
                .where((job) => job != null)
                .cast<SecurityJobData>()
                .toList();
            
            // Update cache
            _cachedJobs = jobs;
            _lastCacheUpdate = DateTime.now();
            
            return jobs;
          })
          .handleError((error) {
            debugPrint('Error watching jobs: $error');
            // Return cached data or static data on error
            return _cachedJobs ?? SecurityJobData.jobList;
          });
          
    } catch (e) {
      debugPrint('Error setting up job stream: $e');
      
      // Return a stream with cached or static data
      return Stream.value(_cachedJobs ?? SecurityJobData.jobList);
    }
  }
  
  @override
  Future<bool> applyToJob(String jobId, String userId, {String? message}) async {
    try {
      // Check if already applied
      final existingApplication = await _firestore
          .collection(_applicationsCollection)
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (existingApplication.docs.isNotEmpty) {
        debugPrint('User $userId already applied to job $jobId');
        return false;
      }
      
      // Create new application
      await _firestore
          .collection(_applicationsCollection)
          .add({
        'jobId': jobId,
        'userId': userId,
        'message': message ?? '',
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update job application count
      await _firestore
          .collection(_jobsCollection)
          .doc(jobId)
          .update({
        'applicantCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
      
    } catch (e) {
      debugPrint('Error applying to job: $e');
      return false;
    }
  }
  
  @override
  Future<bool> removeApplication(String jobId, String userId) async {
    try {
      // Find the application
      final applicationQuery = await _firestore
          .collection(_applicationsCollection)
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (applicationQuery.docs.isEmpty) {
        return false;
      }
      
      // Delete the application
      await applicationQuery.docs.first.reference.delete();
      
      // Update job application count
      await _firestore
          .collection(_jobsCollection)
          .doc(jobId)
          .update({
        'applicantCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
      
    } catch (e) {
      debugPrint('Error removing application: $e');
      return false;
    }
  }
  
  @override
  Future<List<String>> getAppliedJobs(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_applicationsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data()['jobId'] as String? ?? '')
          .where((jobId) => jobId.isNotEmpty)
          .toList();
          
    } catch (e) {
      debugPrint('Error getting applied jobs: $e');
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getApplicationDetails(String jobId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_applicationsCollection)
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      
      return null;
      
    } catch (e) {
      debugPrint('Error getting application details: $e');
      return null;
    }
  }
  
  @override
  Future<List<SecurityJobData>> searchJobs(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getJobs();
      }
      
      // Firestore doesn't support full-text search well, so we'll do client-side filtering
      final allJobs = await getJobs();
      
      return allJobs.where((job) {
        final searchableText = [
          job.jobTitle,
          job.companyName,
          job.location,
          job.jobType,
          job.description,
          ...job.requiredCertificates,
        ].join(' ').toLowerCase();
        
        final searchTerms = query.toLowerCase().split(' ');
        return searchTerms.every((term) => searchableText.contains(term));
      }).toList();
      
    } catch (e) {
      debugPrint('Error searching jobs: $e');
      return [];
    }
  }
  
  @override
  Future<List<SecurityJobData>> filterJobs({
    String? searchQuery,
    double? minHourlyRate,
    double? maxHourlyRate,
    double? maxDistance,
    String? jobType,
    List<String>? requiredCertificates,
  }) async {
    try {
      // Start with all jobs
      var jobs = await getJobs();
      
      // Apply text search
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        jobs = await searchJobs(searchQuery);
      }
      
      // Apply filters
      jobs = jobs.where((job) {
        // Salary filter
        if (minHourlyRate != null && job.hourlyRate < minHourlyRate) return false;
        if (maxHourlyRate != null && job.hourlyRate > maxHourlyRate) return false;
        
        // Distance filter (simplified - would need user location)
        if (maxDistance != null && job.distance > maxDistance) return false;
        
        // Job type filter
        if (jobType != null && jobType.isNotEmpty) {
          if (!job.jobType.toLowerCase().contains(jobType.toLowerCase())) return false;
        }
        
        // Certificate requirements filter
        if (requiredCertificates != null && requiredCertificates.isNotEmpty) {
          final hasRequiredCerts = requiredCertificates.every((cert) =>
              job.requiredCertificates.any((jobCert) =>
                  jobCert.toLowerCase().contains(cert.toLowerCase())));
          if (!hasRequiredCerts) return false;
        }
        
        return true;
      }).toList();
      
      return jobs;
      
    } catch (e) {
      debugPrint('Error filtering jobs: $e');
      return [];
    }
  }
  
  @override
  Future<SecurityJobData?> getJobById(String jobId) async {
    try {
      final doc = await _firestore
          .collection(_jobsCollection)
          .doc(jobId)
          .get();
      
      if (doc.exists) {
        return _jobFromFirestore(doc);
      }
      
      return null;
      
    } catch (e) {
      debugPrint('Error getting job by ID: $e');
      
      // Fallback to searching in static data
      try {
        return SecurityJobData.jobList.firstWhere((job) => job.jobId == jobId);
      } catch (_) {
        return null;
      }
    }
  }
  
  @override
  Future<List<String>> getJobTypes() async {
    try {
      // Use cached jobs if available, otherwise fetch
      final jobs = _cachedJobs ?? await getJobs();
      
      final jobTypes = jobs
          .map((job) => job.jobType)
          .where((type) => type.isNotEmpty)
          .toSet()
          .toList();
      
      jobTypes.sort();
      return jobTypes;
      
    } catch (e) {
      debugPrint('Error getting job types: $e');
      return [
        'Objectbeveiliging',
        'Evenementbeveiliging',
        'Winkelbeveiliging',
        'Persoonbeveiliging',
        'Portier',
      ];
    }
  }
  
  @override
  Future<List<String>> getAvailableCertificates() async {
    try {
      // Get all recognized certificates from the matching service
      return CertificateMatchingService.getAllRecognizedCertificates()
          .map((cert) => cert.name)
          .toList();
          
    } catch (e) {
      debugPrint('Error getting available certificates: $e');
      return [
        'WPBR Diploma A',
        'WPBR Diploma B',
        'BHV Certificaat',
        'VCA Certificaat',
        'Portier Diploma',
      ];
    }
  }
  
  @override
  Future<List<String>> getCompanies() async {
    try {
      final jobs = _cachedJobs ?? await getJobs();
      
      final companies = jobs
          .map((job) => job.companyName)
          .where((company) => company.isNotEmpty)
          .toSet()
          .toList();
      
      companies.sort();
      return companies;
      
    } catch (e) {
      debugPrint('Error getting companies: $e');
      return [];
    }
  }
  
  @override
  Future<List<String>> getLocations() async {
    try {
      final jobs = _cachedJobs ?? await getJobs();
      
      final locations = jobs
          .map((job) => job.location)
          .where((location) => location.isNotEmpty)
          .toSet()
          .toList();
      
      locations.sort();
      return locations;
      
    } catch (e) {
      debugPrint('Error getting locations: $e');
      return [];
    }
  }
  
  @override
  Future<void> refreshJobs() async {
    try {
      // Clear cache to force fresh data
      _cachedJobs = null;
      _lastCacheUpdate = null;
      
      // Fetch fresh data
      await getJobs();
      
    } catch (e) {
      debugPrint('Error refreshing jobs: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getJobStatistics() async {
    try {
      final jobs = await getJobs();
      
      if (jobs.isEmpty) {
        return {
          'totalJobs': 0,
          'averageHourlyRate': 0.0,
          'jobTypesCount': 0,
          'companiesCount': 0,
          'averageDistance': 0.0,
          'averageRating': 0.0,
        };
      }
      
      final totalJobs = jobs.length;
      final averageHourlyRate = jobs
          .map((job) => job.hourlyRate)
          .reduce((a, b) => a + b) / totalJobs;
      
      final jobTypes = jobs.map((job) => job.jobType).toSet();
      final companies = jobs.map((job) => job.companyName).toSet();
      
      final averageDistance = jobs
          .map((job) => job.distance)
          .reduce((a, b) => a + b) / totalJobs;
      
      final averageRating = jobs
          .map((job) => job.companyRating)
          .reduce((a, b) => a + b) / totalJobs;
      
      return {
        'totalJobs': totalJobs,
        'averageHourlyRate': averageHourlyRate,
        'jobTypesCount': jobTypes.length,
        'companiesCount': companies.length,
        'averageDistance': averageDistance,
        'averageRating': averageRating,
        'salaryRange': {
          'min': jobs.map((job) => job.hourlyRate).reduce((a, b) => a < b ? a : b),
          'max': jobs.map((job) => job.hourlyRate).reduce((a, b) => a > b ? a : b),
        },
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      debugPrint('Error getting job statistics: $e');
      return {};
    }
  }
  
  /// Convert Firestore document to SecurityJobData
  static SecurityJobData? _jobFromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;
      
      return SecurityJobData(
        jobId: doc.id,
        jobTitle: data['jobTitle'] ?? '',
        companyName: data['companyName'] ?? '',
        location: data['location'] ?? '',
        hourlyRate: (data['hourlyRate'] ?? 0.0).toDouble(),
        distance: (data['distance'] ?? 0.0).toDouble(),
        companyRating: (data['companyRating'] ?? 0.0).toDouble(),
        applicantCount: data['applicantCount'] ?? 0,
        duration: data['duration'] ?? 8,
        jobType: data['jobType'] ?? '',
        description: data['description'] ?? '',
        companyLogo: data['companyLogo'] ?? 'assets/hotel/hotel_1.png',
        startDate: (data['startDate'] as Timestamp?)?.toDate(),
        endDate: (data['endDate'] as Timestamp?)?.toDate(),
        requiredCertificates: List<String>.from(data['requiredCertificates'] ?? []),
      );
      
    } catch (e) {
      debugPrint('Error converting Firestore document to SecurityJobData: $e');
      return null;
    }
  }
  
  /// Convert SecurityJobData to Firestore document
  static Map<String, dynamic> _jobToFirestore(SecurityJobData job) {
    return {
      'jobTitle': job.jobTitle,
      'companyName': job.companyName,
      'location': job.location,
      'hourlyRate': job.hourlyRate,
      'distance': job.distance,
      'companyRating': job.companyRating,
      'applicantCount': job.applicantCount,
      'duration': job.duration,
      'jobType': job.jobType,
      'description': job.description,
      'companyLogo': job.companyLogo,
      'startDate': job.startDate != null ? Timestamp.fromDate(job.startDate!) : null,
      'endDate': job.endDate != null ? Timestamp.fromDate(job.endDate!) : null,
      'requiredCertificates': job.requiredCertificates,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
  
  /// Check if cached data is still valid
  static bool _isCacheValid() {
    if (_cachedJobs == null || _lastCacheUpdate == null) return false;
    
    final now = DateTime.now();
    return now.difference(_lastCacheUpdate!).compareTo(_cacheValidDuration) < 0;
  }
  
  /// Create or update a job (for admin use)
  Future<bool> createJob(SecurityJobData job) async {
    try {
      if (job.jobId.isEmpty) {
        // Create new job
        await _firestore
            .collection(_jobsCollection)
            .add(_jobToFirestore(job));
      } else {
        // Update existing job
        await _firestore
            .collection(_jobsCollection)
            .doc(job.jobId)
            .set(_jobToFirestore(job), SetOptions(merge: true));
      }
      
      // Invalidate cache
      _cachedJobs = null;
      _lastCacheUpdate = null;
      
      return true;
      
    } catch (e) {
      debugPrint('Error creating/updating job: $e');
      return false;
    }
  }
  
  /// Delete a job (for admin use)
  Future<bool> deleteJob(String jobId) async {
    try {
      await _firestore
          .collection(_jobsCollection)
          .doc(jobId)
          .update({'status': 'deleted'});
      
      // Invalidate cache
      _cachedJobs = null;
      _lastCacheUpdate = null;
      
      return true;
      
    } catch (e) {
      debugPrint('Error deleting job: $e');
      return false;
    }
  }
  
  /// Get job applications for a specific job (for company use)
  Future<List<Map<String, dynamic>>> getJobApplications(String jobId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_applicationsCollection)
          .where('jobId', isEqualTo: jobId)
          .orderBy('appliedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
          
    } catch (e) {
      debugPrint('Error getting job applications: $e');
      return [];
    }
  }
  
  /// Update application status (for company use)
  Future<bool> updateApplicationStatus(String applicationId, String status) async {
    try {
      await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
      
    } catch (e) {
      debugPrint('Error updating application status: $e');
      return false;
    }
  }
  
  /// Clear all cached data
  static void clearCache() {
    _cachedJobs = null;
    _lastCacheUpdate = null;
  }
}