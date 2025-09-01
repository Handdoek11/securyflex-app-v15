import '../model/security_job_data.dart';

/// Abstract repository interface for job operations
/// Provides a clean separation between business logic and data sources
abstract class JobRepository {
  /// Get all available jobs
  Future<List<SecurityJobData>> getJobs();
  
  /// Watch jobs with real-time updates
  Stream<List<SecurityJobData>> watchJobs();
  
  /// Apply to a specific job
  Future<bool> applyToJob(String jobId, String userId, {String? message});
  
  /// Remove job application
  Future<bool> removeApplication(String jobId, String userId);
  
  /// Get applied jobs for a user
  Future<List<String>> getAppliedJobs(String userId);
  
  /// Get application details
  Future<Map<String, dynamic>?> getApplicationDetails(String jobId, String userId);
  
  /// Search jobs by query
  Future<List<SecurityJobData>> searchJobs(String query);
  
  /// Filter jobs by criteria
  Future<List<SecurityJobData>> filterJobs({
    String? searchQuery,
    double? minHourlyRate,
    double? maxHourlyRate,
    double? maxDistance,
    String? jobType,
    List<String>? requiredCertificates,
  });
  
  /// Get job by ID
  Future<SecurityJobData?> getJobById(String jobId);
  
  /// Get job types
  Future<List<String>> getJobTypes();
  
  /// Get available certificates
  Future<List<String>> getAvailableCertificates();
  
  /// Get companies
  Future<List<String>> getCompanies();
  
  /// Get locations
  Future<List<String>> getLocations();
  
  /// Refresh job data
  Future<void> refreshJobs();
  
  /// Get job statistics
  Future<Map<String, dynamic>> getJobStatistics();
}
