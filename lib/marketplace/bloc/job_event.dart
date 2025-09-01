import 'package:flutter/material.dart';
import '../../core/bloc/base_bloc.dart';

/// Base class for all job-related events in SecuryFlex marketplace
abstract class JobEvent extends BaseEvent {
  const JobEvent();
}

/// Initialize job state and load initial data
class JobInitialize extends JobEvent {
  const JobInitialize();
}

/// Load all jobs
class LoadJobs extends JobEvent {
  const LoadJobs();
}

/// Watch jobs with real-time updates
class WatchJobs extends JobEvent {
  const WatchJobs();
}

/// Refresh job data
class RefreshJobs extends JobEvent {
  const RefreshJobs();
}

/// Search jobs by query with debouncing
class SearchJobs extends JobEvent {
  final String query;
  
  const SearchJobs(this.query);
  
  @override
  List<Object> get props => [query];
  
  @override
  String toString() => 'SearchJobs(query: $query)';
}

/// Filter jobs by multiple criteria
class FilterJobs extends JobEvent {
  final String? searchQuery;
  final RangeValues? hourlyRateRange;
  final double? maxDistance;
  final String? jobType;
  final List<String>? certificates;
  
  const FilterJobs({
    this.searchQuery,
    this.hourlyRateRange,
    this.maxDistance,
    this.jobType,
    this.certificates,
  });
  
  @override
  List<Object?> get props => [searchQuery, hourlyRateRange, maxDistance, jobType, certificates];
  
  @override
  String toString() => 'FilterJobs(searchQuery: $searchQuery, hourlyRateRange: $hourlyRateRange, maxDistance: $maxDistance, jobType: $jobType, certificates: $certificates)';
}

/// Apply to a specific job
class ApplyToJob extends JobEvent {
  final String jobId;
  final String? message;
  
  const ApplyToJob({
    required this.jobId,
    this.message,
  });
  
  @override
  List<Object?> get props => [jobId, message];
  
  @override
  String toString() => 'ApplyToJob(jobId: $jobId, message: $message)';
}

/// Remove job application
class RemoveJobApplication extends JobEvent {
  final String jobId;
  
  const RemoveJobApplication(this.jobId);
  
  @override
  List<Object> get props => [jobId];
  
  @override
  String toString() => 'RemoveJobApplication(jobId: $jobId)';
}

/// Load applied jobs for current user
class LoadAppliedJobs extends JobEvent {
  const LoadAppliedJobs();
}

/// Clear all filters
class ClearFilters extends JobEvent {
  const ClearFilters();
}

/// Update search query (for real-time search)
class UpdateSearchQuery extends JobEvent {
  final String query;
  
  const UpdateSearchQuery(this.query);
  
  @override
  List<Object> get props => [query];
  
  @override
  String toString() => 'UpdateSearchQuery(query: $query)';
}

/// Update hourly rate range filter
class UpdateHourlyRateRange extends JobEvent {
  final RangeValues range;
  
  const UpdateHourlyRateRange(this.range);
  
  @override
  List<Object> get props => [range];
  
  @override
  String toString() => 'UpdateHourlyRateRange(range: $range)';
}

/// Update maximum distance filter
class UpdateMaxDistance extends JobEvent {
  final double distance;
  
  const UpdateMaxDistance(this.distance);
  
  @override
  List<Object> get props => [distance];
  
  @override
  String toString() => 'UpdateMaxDistance(distance: $distance)';
}

/// Update job type filter
class UpdateJobType extends JobEvent {
  final String jobType;
  
  const UpdateJobType(this.jobType);
  
  @override
  List<Object> get props => [jobType];
  
  @override
  String toString() => 'UpdateJobType(jobType: $jobType)';
}

/// Update certificates filter
class UpdateCertificates extends JobEvent {
  final List<String> certificates;
  
  const UpdateCertificates(this.certificates);
  
  @override
  List<Object> get props => [certificates];
  
  @override
  String toString() => 'UpdateCertificates(certificates: $certificates)';
}

/// Load job metadata (types, certificates, etc.)
class LoadJobMetadata extends JobEvent {
  const LoadJobMetadata();
}

/// Get job by ID
class GetJobById extends JobEvent {
  final String jobId;
  
  const GetJobById(this.jobId);
  
  @override
  List<Object> get props => [jobId];
  
  @override
  String toString() => 'GetJobById(jobId: $jobId)';
}

/// Load job statistics
class LoadJobStatistics extends JobEvent {
  const LoadJobStatistics();
}

/// Jobs updated (from real-time stream)
class JobsUpdated extends JobEvent {
  final List<dynamic> jobs; // Using dynamic to avoid import issues
  
  const JobsUpdated(this.jobs);
  
  @override
  List<Object> get props => [jobs];
  
  @override
  String toString() => 'JobsUpdated(jobsCount: ${jobs.length})';
}
