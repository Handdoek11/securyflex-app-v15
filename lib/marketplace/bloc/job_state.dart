import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../core/bloc/base_bloc.dart';
import '../../core/bloc/error_handler.dart';
import '../model/security_job_data.dart';

/// Base class for all job-related states in SecuryFlex marketplace
abstract class JobState extends BaseState {
  const JobState();
}

/// Initial job state
class JobInitial extends JobState {
  const JobInitial();
}

/// Job operation in progress
class JobLoading extends JobState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage;
  
  const JobLoading({this.loadingMessage});
  
  @override
  List<Object?> get props => [loadingMessage];
  
  @override
  String toString() => 'JobLoading(message: $loadingMessage)';
}

/// Jobs loaded successfully with filtering capabilities
class JobLoaded extends JobState {
  final List<SecurityJobData> allJobs;
  final List<SecurityJobData> filteredJobs;
  final JobFilter filters;
  final Set<String> appliedJobIds;
  final bool hasActiveFilters;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? statistics;
  
  const JobLoaded({
    required this.allJobs,
    required this.filteredJobs,
    required this.filters,
    required this.appliedJobIds,
    required this.hasActiveFilters,
    this.metadata,
    this.statistics,
  });
  
  /// Get Dutch status message based on current state
  String get statusMessage {
    if (filteredJobs.isEmpty && hasActiveFilters) {
      return 'Geen opdrachten gevonden met huidige filters';
    } else if (filteredJobs.isEmpty) {
      return 'Geen opdrachten beschikbaar';
    } else if (hasActiveFilters) {
      return '${filteredJobs.length} van ${allJobs.length} opdrachten';
    } else {
      return '${filteredJobs.length} opdrachten beschikbaar';
    }
  }
  
  /// Get filter summary in Dutch
  String get filterSummary {
    final List<String> filterParts = [];
    
    if (filters.searchQuery.isNotEmpty) {
      filterParts.add('Zoekterm: "${filters.searchQuery}"');
    }
    
    if (filters.hourlyRateRange.start > 15 || filters.hourlyRateRange.end < 50) {
      filterParts.add('Tarief: €${filters.hourlyRateRange.start.round()}-€${filters.hourlyRateRange.end.round()}');
    }
    
    if (filters.maxDistance < 10) {
      filterParts.add('Afstand: max ${filters.maxDistance.round()}km');
    }
    
    if (filters.jobType.isNotEmpty) {
      filterParts.add('Type: ${filters.jobType}');
    }
    
    if (filters.certificates.isNotEmpty) {
      filterParts.add('Certificaten: ${filters.certificates.length}');
    }
    
    return filterParts.isEmpty ? 'Geen filters actief' : filterParts.join(', ');
  }
  
  /// Check if user has applied to a specific job
  bool hasAppliedToJob(String jobId) {
    return appliedJobIds.contains(jobId);
  }
  
  /// Get applied jobs count
  int get appliedJobsCount => appliedJobIds.length;
  
  /// Create a copy with updated properties
  JobLoaded copyWith({
    List<SecurityJobData>? allJobs,
    List<SecurityJobData>? filteredJobs,
    JobFilter? filters,
    Set<String>? appliedJobIds,
    bool? hasActiveFilters,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? statistics,
  }) {
    return JobLoaded(
      allJobs: allJobs ?? this.allJobs,
      filteredJobs: filteredJobs ?? this.filteredJobs,
      filters: filters ?? this.filters,
      appliedJobIds: appliedJobIds ?? this.appliedJobIds,
      hasActiveFilters: hasActiveFilters ?? this.hasActiveFilters,
      metadata: metadata ?? this.metadata,
      statistics: statistics ?? this.statistics,
    );
  }
  
  @override
  List<Object?> get props => [
    allJobs,
    filteredJobs,
    filters,
    appliedJobIds,
    hasActiveFilters,
    metadata,
    statistics,
  ];
  
  @override
  String toString() => 'JobLoaded(allJobs: ${allJobs.length}, filteredJobs: ${filteredJobs.length}, hasActiveFilters: $hasActiveFilters)';
}

/// Job operation error
class JobError extends JobState with ErrorStateMixin {
  @override
  final AppError error;
  
  const JobError(this.error);
  
  @override
  List<Object> get props => [error];
  
  @override
  String toString() => 'JobError(error: ${error.localizedMessage})';
}

/// Job application successful
class JobApplicationSuccess extends JobState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final String jobId;
  final String jobTitle;
  
  const JobApplicationSuccess({
    required this.jobId,
    required this.jobTitle,
    this.successMessage = 'Sollicitatie succesvol verzonden!',
  });
  
  @override
  String get localizedSuccessMessage {
    return 'Sollicitatie voor "$jobTitle" succesvol verzonden!';
  }
  
  @override
  List<Object> get props => [jobId, jobTitle, successMessage];
  
  @override
  String toString() => 'JobApplicationSuccess(jobId: $jobId, jobTitle: $jobTitle)';
}

/// Job application removed successfully
class JobApplicationRemoved extends JobState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final String jobId;
  final String jobTitle;
  
  const JobApplicationRemoved({
    required this.jobId,
    required this.jobTitle,
    this.successMessage = 'Sollicitatie succesvol ingetrokken',
  });
  
  @override
  String get localizedSuccessMessage {
    return 'Sollicitatie voor "$jobTitle" succesvol ingetrokken';
  }
  
  @override
  List<Object> get props => [jobId, jobTitle, successMessage];
  
  @override
  String toString() => 'JobApplicationRemoved(jobId: $jobId, jobTitle: $jobTitle)';
}

/// Job metadata loaded (types, certificates, etc.)
class JobMetadataLoaded extends JobState {
  final List<String> jobTypes;
  final List<String> certificates;
  final List<String> companies;
  final List<String> locations;
  
  const JobMetadataLoaded({
    required this.jobTypes,
    required this.certificates,
    required this.companies,
    required this.locations,
  });
  
  @override
  List<Object> get props => [jobTypes, certificates, companies, locations];
  
  @override
  String toString() => 'JobMetadataLoaded(jobTypes: ${jobTypes.length}, certificates: ${certificates.length})';
}

/// Job statistics loaded
class JobStatisticsLoaded extends JobState {
  final Map<String, dynamic> statistics;
  
  const JobStatisticsLoaded(this.statistics);
  
  /// Get formatted statistics in Dutch
  String get formattedStatistics {
    final totalJobs = statistics['totalJobs'] ?? 0;
    final avgRate = statistics['averageHourlyRate'] ?? 0.0;
    final jobTypesCount = statistics['jobTypesCount'] ?? 0;
    final companiesCount = statistics['companiesCount'] ?? 0;
    
    return 'Totaal: $totalJobs opdrachten, '
           'Gemiddeld tarief: €${avgRate.toStringAsFixed(2)}/uur, '
           'Types: $jobTypesCount, '
           'Bedrijven: $companiesCount';
  }
  
  @override
  List<Object> get props => [statistics];
  
  @override
  String toString() => 'JobStatisticsLoaded(statistics: $statistics)';
}

/// Job filter data class
class JobFilter extends Equatable {
  final String searchQuery;
  final RangeValues hourlyRateRange;
  final double maxDistance;
  final String jobType;
  final List<String> certificates;
  
  const JobFilter({
    this.searchQuery = '',
    this.hourlyRateRange = const RangeValues(15, 50),
    this.maxDistance = 10.0,
    this.jobType = '',
    this.certificates = const [],
  });
  
  /// Check if any filters are active
  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
           hourlyRateRange != const RangeValues(15, 50) ||
           maxDistance != 10.0 ||
           jobType.isNotEmpty ||
           certificates.isNotEmpty;
  }
  
  /// Create a copy with updated properties
  JobFilter copyWith({
    String? searchQuery,
    RangeValues? hourlyRateRange,
    double? maxDistance,
    String? jobType,
    List<String>? certificates,
  }) {
    return JobFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      hourlyRateRange: hourlyRateRange ?? this.hourlyRateRange,
      maxDistance: maxDistance ?? this.maxDistance,
      jobType: jobType ?? this.jobType,
      certificates: certificates ?? this.certificates,
    );
  }
  
  /// Clear all filters
  JobFilter clear() {
    return const JobFilter();
  }
  
  @override
  List<Object> get props => [searchQuery, hourlyRateRange, maxDistance, jobType, certificates];
  
  @override
  String toString() => 'JobFilter(searchQuery: $searchQuery, hourlyRateRange: $hourlyRateRange, maxDistance: $maxDistance, jobType: $jobType, certificates: $certificates)';
}
