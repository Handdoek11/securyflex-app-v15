import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/security_job_data.dart';
import 'job_repository.dart';

/// Static implementation of JobRepository
/// Uses the existing SecurityJobData.jobList for data
/// Simulates real-time updates and provides comprehensive job operations
class StaticJobRepository implements JobRepository {
  static final Map<String, Set<String>> _userApplications = {};
  static final Map<String, Map<String, dynamic>> _applicationDetails = {};
  
  final StreamController<List<SecurityJobData>> _jobsController = 
      StreamController<List<SecurityJobData>>.broadcast();
  
  Timer? _refreshTimer;
  
  StaticJobRepository() {
    // Simulate periodic data updates
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _jobsController.add(SecurityJobData.jobList);
    });
  }

  @override
  Future<List<SecurityJobData>> getJobs() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(SecurityJobData.jobList);
  }

  @override
  Stream<List<SecurityJobData>> watchJobs() {
    // Emit initial data
    _jobsController.add(SecurityJobData.jobList);
    return _jobsController.stream;
  }

  @override
  Future<bool> applyToJob(String jobId, String userId, {String? message}) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if job exists
      SecurityJobData.jobList.firstWhere(
        (job) => job.jobId == jobId,
        orElse: () => throw Exception('Job not found'),
      );
      
      // Check if already applied
      if (_userApplications[userId]?.contains(jobId) == true) {
        throw Exception('Already applied to this job');
      }
      
      // Add application
      _userApplications.putIfAbsent(userId, () => <String>{}).add(jobId);
      _applicationDetails['${userId}_$jobId'] = {
        'jobId': jobId,
        'userId': userId,
        'message': message,
        'appliedAt': DateTime.now(),
        'status': 'pending',
      };
      
      debugPrint('Applied to job: $jobId for user: $userId');
      return true;
    } catch (e) {
      debugPrint('Application failed: $e');
      return false;
    }
  }

  @override
  Future<bool> removeApplication(String jobId, String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      _userApplications[userId]?.remove(jobId);
      _applicationDetails.remove('${userId}_$jobId');
      
      debugPrint('Removed application: $jobId for user: $userId');
      return true;
    } catch (e) {
      debugPrint('Remove application failed: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getAppliedJobs(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_userApplications[userId] ?? <String>{});
  }

  @override
  Future<Map<String, dynamic>?> getApplicationDetails(String jobId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _applicationDetails['${userId}_$jobId'];
  }

  @override
  Future<List<SecurityJobData>> searchJobs(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (query.isEmpty) return SecurityJobData.jobList;
    
    final lowerQuery = query.toLowerCase();
    return SecurityJobData.jobList.where((job) {
      return job.jobTitle.toLowerCase().contains(lowerQuery) ||
             job.companyName.toLowerCase().contains(lowerQuery) ||
             job.location.toLowerCase().contains(lowerQuery) ||
             job.jobType.toLowerCase().contains(lowerQuery) ||
             job.description.toLowerCase().contains(lowerQuery);
    }).toList();
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
    await Future.delayed(const Duration(milliseconds: 300));
    
    return SecurityJobData.jobList.where((job) {
      // Search query filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!job.jobTitle.toLowerCase().contains(query) &&
            !job.companyName.toLowerCase().contains(query) &&
            !job.location.toLowerCase().contains(query) &&
            !job.jobType.toLowerCase().contains(query) &&
            !job.description.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Hourly rate filter
      if (minHourlyRate != null && job.hourlyRate < minHourlyRate) {
        return false;
      }
      if (maxHourlyRate != null && job.hourlyRate > maxHourlyRate) {
        return false;
      }
      
      // Distance filter
      if (maxDistance != null && job.distance > maxDistance) {
        return false;
      }
      
      // Job type filter
      if (jobType != null && jobType.isNotEmpty && job.jobType != jobType) {
        return false;
      }
      
      // Certificate filter
      if (requiredCertificates != null && requiredCertificates.isNotEmpty) {
        bool hasRequiredCertificate = false;
        for (String cert in requiredCertificates) {
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

  @override
  Future<SecurityJobData?> getJobById(String jobId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    try {
      return SecurityJobData.jobList.firstWhere((job) => job.jobId == jobId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<String>> getJobTypes() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final types = SecurityJobData.jobList
        .map((job) => job.jobType)
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList();
    types.sort();
    return types;
  }

  @override
  Future<List<String>> getAvailableCertificates() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final certificates = <String>{};
    for (final job in SecurityJobData.jobList) {
      certificates.addAll(job.requiredCertificates);
    }
    final list = certificates.toList();
    list.sort();
    return list;
  }

  @override
  Future<List<String>> getCompanies() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final companies = SecurityJobData.jobList
        .map((job) => job.companyName)
        .where((company) => company.isNotEmpty)
        .toSet()
        .toList();
    companies.sort();
    return companies;
  }

  @override
  Future<List<String>> getLocations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final locations = SecurityJobData.jobList
        .map((job) => job.location)
        .where((location) => location.isNotEmpty)
        .toSet()
        .toList();
    locations.sort();
    return locations;
  }

  @override
  Future<void> refreshJobs() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate data refresh
    _jobsController.add(SecurityJobData.jobList);
    debugPrint('Jobs refreshed');
  }

  @override
  Future<Map<String, dynamic>> getJobStatistics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final jobs = SecurityJobData.jobList;
    final totalJobs = jobs.length;
    final avgHourlyRate = jobs.fold<double>(0, (sum, job) => sum + job.hourlyRate) / totalJobs;
    final jobTypes = await getJobTypes();
    final companies = await getCompanies();
    
    return {
      'totalJobs': totalJobs,
      'averageHourlyRate': avgHourlyRate,
      'jobTypesCount': jobTypes.length,
      'companiesCount': companies.length,
      'lastUpdated': DateTime.now(),
    };
  }
  
  void dispose() {
    _refreshTimer?.cancel();
    _jobsController.close();
  }
}
