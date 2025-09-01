import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';
import 'package:securyflex_app/auth/auth_service.dart';

/// Service for managing job data with Firestore backend
/// Replaces the static mockup data with real database operations
class JobDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _jobsCollection = 'jobs';

  /// Get all available jobs for guards
  /// Returns jobs that are active and not expired
  static Future<List<SecurityJobData>> getAvailableJobs({
    String? searchQuery,
    String? jobType,
    double? maxDistance,
    double? minHourlyRate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_jobsCollection)
          .where('status', isEqualTo: 'active')
          .where('endDate', isGreaterThan: DateTime.now())
          .orderBy('endDate')
          .orderBy('createdAt', descending: true);

      if (limit > 0) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      List<SecurityJobData> jobs = snapshot.docs
          .map((doc) => SecurityJobData.fromFirestore({
                ...doc.data() as Map<String, dynamic>,
                'jobId': doc.id,
              }))
          .toList();

      // Apply client-side filters (for complex filtering)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        jobs = jobs.where((job) =>
            job.jobTitle.toLowerCase().contains(searchQuery.toLowerCase()) ||
            job.companyName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            job.location.toLowerCase().contains(searchQuery.toLowerCase()) ||
            job.description.toLowerCase().contains(searchQuery.toLowerCase())).toList();
      }

      if (jobType != null && jobType.isNotEmpty) {
        jobs = jobs.where((job) => job.jobType == jobType).toList();
      }

      if (maxDistance != null) {
        jobs = jobs.where((job) => job.distance <= maxDistance).toList();
      }

      if (minHourlyRate != null) {
        jobs = jobs.where((job) => job.hourlyRate >= minHourlyRate).toList();
      }

      return jobs;
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
      // Fallback to demo data if Firestore fails
      return _getDemoJobs();
    }
  }

  /// Get a specific job by ID
  static Future<SecurityJobData?> getJobById(String jobId) async {
    try {
      final doc = await _firestore.collection(_jobsCollection).doc(jobId).get();
      
      if (doc.exists) {
        return SecurityJobData.fromFirestore({
          ...doc.data()!,
          'jobId': doc.id,
        });
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching job $jobId: $e');
      return null;
    }
  }

  /// Create a new job (for companies)
  static Future<String?> createJob(SecurityJobData jobData) async {
    try {
      final docRef = await _firestore.collection(_jobsCollection).add(jobData.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating job: $e');
      return null;
    }
  }

  /// Update an existing job
  static Future<bool> updateJob(String jobId, SecurityJobData jobData) async {
    try {
      await _firestore.collection(_jobsCollection).doc(jobId).update({
        ...jobData.toFirestore(),
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating job $jobId: $e');
      return false;
    }
  }

  /// Delete a job
  static Future<bool> deleteJob(String jobId) async {
    try {
      await _firestore.collection(_jobsCollection).doc(jobId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting job $jobId: $e');
      return false;
    }
  }

  /// Get jobs posted by current company
  static Future<List<SecurityJobData>> getCompanyJobs() async {
    try {
      final companyId = AuthService.currentUserId;
      if (companyId.isEmpty) return [];

      final snapshot = await _firestore
          .collection(_jobsCollection)
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SecurityJobData.fromFirestore({
                ...doc.data(),
                'jobId': doc.id,
              }))
          .toList();
    } catch (e) {
      debugPrint('Error fetching company jobs: $e');
      return [];
    }
  }

  /// Initialize demo data for development/testing
  static Future<void> initializeDemoData() async {
    try {
      final demoJobs = _getDemoJobs();
      
      for (final job in demoJobs) {
        await _firestore.collection(_jobsCollection).add(job.toFirestore());
      }

      debugPrint('Demo job data initialized successfully');
    } catch (e) {
      debugPrint('Error initializing demo data: $e');
    }
  }

  /// Get demo jobs as fallback
  static List<SecurityJobData> _getDemoJobs() {
    return [
      SecurityJobData(
        jobId: 'demo_001',
        jobTitle: 'Objectbeveiliging Kantoorcomplex',
        companyName: 'Amsterdam Security Partners',
        location: 'Amsterdam Zuidas, 1082 MD',
        hourlyRate: 24.50,
        distance: 2.3,
        companyRating: 4.6,
        applicantCount: 12,
        duration: 8,
        jobType: 'Objectbeveiliging',
        description: 'Beveiliging van modern kantoorcomplex met toegangscontrole en surveillance. Dagdienst van 08:00-16:00 uur. Ervaring met CCTV systemen gewenst.',
        companyLogo: 'assets/hotel/hotel_1.png',
        startDate: DateTime.now().add(Duration(days: 2)),
        endDate: DateTime.now().add(Duration(days: 2, hours: 8)),
        requiredCertificates: ['Beveiligingsdiploma A', 'BHV'],
      ),
      SecurityJobData(
        jobId: 'demo_002',
        jobTitle: 'Evenementbeveiliging Concerthal',
        companyName: 'Rotterdam Event Security',
        location: 'Rotterdam Centrum, 3011 AB',
        hourlyRate: 28.75,
        distance: 4.1,
        companyRating: 4.8,
        applicantCount: 25,
        duration: 6,
        jobType: 'Evenementbeveiliging',
        description: 'Crowd control en toegangscontrole tijdens live concert. Ervaring met grote evenementen vereist. Avonddienst 19:00-01:00 uur.',
        companyLogo: 'assets/hotel/hotel_2.png',
        startDate: DateTime.now().add(Duration(days: 5)),
        endDate: DateTime.now().add(Duration(days: 5, hours: 6)),
        requiredCertificates: ['Beveiligingsdiploma B', 'BHV', 'VCA'],
      ),
      SecurityJobData(
        jobId: 'demo_003',
        jobTitle: 'Winkelbeveiliging Warenhuis',
        companyName: 'Den Haag Retail Security',
        location: 'Den Haag Centrum, 2511 CV',
        hourlyRate: 22.00,
        distance: 1.2,
        companyRating: 4.3,
        applicantCount: 8,
        duration: 9,
        jobType: 'Winkelbeveiliging',
        description: 'Preventieve beveiliging in groot warenhuis. Diefstalpreventie en klantenservice. Flexibele werktijden mogelijk.',
        companyLogo: 'assets/hotel/hotel_3.png',
        startDate: DateTime.now().add(Duration(days: 1)),
        endDate: DateTime.now().add(Duration(days: 1, hours: 9)),
        requiredCertificates: ['Beveiligingsdiploma A'],
      ),
    ];
  }

  /// Check if Firestore is available
  static Future<bool> isFirestoreAvailable() async {
    try {
      await _firestore.collection('test').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }
}
