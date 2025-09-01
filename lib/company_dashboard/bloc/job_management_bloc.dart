import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../services/job_posting_service.dart';
import '../models/job_posting_data.dart';

/// BLoC for Company Job Management following SecuryFlex patterns
/// Handles job CRUD operations, filtering, and real-time updates
class JobManagementBloc extends Bloc<JobManagementEvent, JobManagementState> {
  final JobPostingService _jobService;

  JobManagementBloc({JobPostingService? jobService})
    : _jobService = jobService ?? JobPostingService.instance,
      super(const JobManagementState()) {
    // Register event handlers
    on<LoadCompanyJobs>(_onLoadCompanyJobs);
    on<RefreshCompanyJobs>(_onRefreshCompanyJobs);
    on<CreateJob>(_onCreateJob);
    on<UpdateJob>(_onUpdateJob);
    on<DeleteJob>(_onDeleteJob);
    on<FilterJobs>(_onFilterJobs);
    on<SearchJobs>(_onSearchJobs);
    on<ClearJobFilters>(_onClearJobFilters);
    on<LoadJobStats>(_onLoadJobStats);
  }

  /// Load company jobs
  Future<void> _onLoadCompanyJobs(
    LoadCompanyJobs event,
    Emitter<JobManagementState> emit,
  ) async {
    emit(state.copyWith(status: JobManagementStatus.loading));

    try {
      debugPrint('Loading company jobs for: ${event.companyId}');

      final jobs = await _jobService.getCompanyJobs(event.companyId);
      final stats = await JobPostingService.getCompanyJobStats();

      emit(
        state.copyWith(
          status: JobManagementStatus.loaded,
          companyId: event.companyId,
          jobs: jobs,
          filteredJobs: jobs,
          jobStats: stats,
          lastUpdated: DateTime.now(),
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('Error loading company jobs: $e');
      emit(
        state.copyWith(
          status: JobManagementStatus.error,
          errorMessage: 'Fout bij laden van jobs: ${e.toString()}',
        ),
      );
    }
  }

  /// Refresh company jobs
  Future<void> _onRefreshCompanyJobs(
    RefreshCompanyJobs event,
    Emitter<JobManagementState> emit,
  ) async {
    if (state.companyId == null) return;

    emit(state.copyWith(status: JobManagementStatus.refreshing));

    try {
      final jobs = await _jobService.getCompanyJobs(state.companyId);
      final stats = await JobPostingService.getCompanyJobStats();

      emit(
        state.copyWith(
          status: JobManagementStatus.loaded,
          jobs: jobs,
          filteredJobs: jobs,
          jobStats: stats,
          lastUpdated: DateTime.now(),
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('Error refreshing company jobs: $e');
      emit(
        state.copyWith(
          status: JobManagementStatus.error,
          errorMessage: 'Fout bij verversen van jobs: ${e.toString()}',
        ),
      );
    }
  }

  /// Create new job
  Future<void> _onCreateJob(
    CreateJob event,
    Emitter<JobManagementState> emit,
  ) async {
    emit(state.copyWith(status: JobManagementStatus.creating));

    try {
      await _jobService.createJob(event.jobData);

      // Reload jobs to get the new job
      add(RefreshCompanyJobs());

      emit(state.copyWith(status: JobManagementStatus.created));
    } catch (e) {
      debugPrint('Error creating job: $e');
      emit(
        state.copyWith(
          status: JobManagementStatus.error,
          errorMessage: 'Fout bij aanmaken van job: ${e.toString()}',
        ),
      );
    }
  }

  /// Update existing job
  Future<void> _onUpdateJob(
    UpdateJob event,
    Emitter<JobManagementState> emit,
  ) async {
    emit(state.copyWith(status: JobManagementStatus.updating));

    try {
      await _jobService.updateJob(event.jobData);

      // Reload jobs to get updated data
      add(RefreshCompanyJobs());

      emit(state.copyWith(status: JobManagementStatus.updated));
    } catch (e) {
      debugPrint('Error updating job: $e');
      emit(
        state.copyWith(
          status: JobManagementStatus.error,
          errorMessage: 'Fout bij bijwerken van job: ${e.toString()}',
        ),
      );
    }
  }

  /// Delete job
  Future<void> _onDeleteJob(
    DeleteJob event,
    Emitter<JobManagementState> emit,
  ) async {
    emit(state.copyWith(status: JobManagementStatus.deleting));

    try {
      await _jobService.deleteJob(event.jobId);

      // Reload jobs to get updated data
      add(RefreshCompanyJobs());

      emit(state.copyWith(status: JobManagementStatus.deleted));
    } catch (e) {
      debugPrint('Error deleting job: $e');
      emit(
        state.copyWith(
          status: JobManagementStatus.error,
          errorMessage: 'Fout bij verwijderen van job: ${e.toString()}',
        ),
      );
    }
  }

  /// Filter jobs
  void _onFilterJobs(FilterJobs event, Emitter<JobManagementState> emit) {
    final filteredJobs = state.jobs.where((job) {
      // Status filter
      if (event.status != null && job.status != event.status) {
        return false;
      }

      // Job type filter
      if (event.jobType != null && job.jobType != event.jobType) {
        return false;
      }

      // Date range filter
      if (event.startDate != null && job.startDate.isBefore(event.startDate!)) {
        return false;
      }
      if (event.endDate != null && job.endDate.isAfter(event.endDate!)) {
        return false;
      }

      return true;
    }).toList();

    emit(state.copyWith(filteredJobs: filteredJobs, currentFilters: event));
  }

  /// Search jobs
  void _onSearchJobs(SearchJobs event, Emitter<JobManagementState> emit) {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredJobs: state.jobs, searchQuery: ''));
      return;
    }

    final searchQuery = event.query.toLowerCase();
    final searchResults = state.jobs.where((job) {
      return job.title.toLowerCase().contains(searchQuery) ||
          job.description.toLowerCase().contains(searchQuery) ||
          job.location.toLowerCase().contains(searchQuery);
    }).toList();

    emit(state.copyWith(filteredJobs: searchResults, searchQuery: event.query));
  }

  /// Clear filters
  void _onClearJobFilters(
    ClearJobFilters event,
    Emitter<JobManagementState> emit,
  ) {
    emit(
      state.copyWith(
        filteredJobs: state.jobs,
        currentFilters: null,
        searchQuery: '',
      ),
    );
  }

  /// Load job statistics
  Future<void> _onLoadJobStats(
    LoadJobStats event,
    Emitter<JobManagementState> emit,
  ) async {
    try {
      final stats = await JobPostingService.getCompanyJobStats();

      emit(state.copyWith(jobStats: stats, lastUpdated: DateTime.now()));
    } catch (e) {
      debugPrint('Error loading job stats: $e');
      emit(
        state.copyWith(
          errorMessage: 'Fout bij laden van job statistieken: ${e.toString()}',
        ),
      );
    }
  }
}

/// Job Management Events
abstract class JobManagementEvent extends Equatable {
  const JobManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadCompanyJobs extends JobManagementEvent {
  final String companyId;

  const LoadCompanyJobs(this.companyId);

  @override
  List<Object?> get props => [companyId];
}

class RefreshCompanyJobs extends JobManagementEvent {}

class CreateJob extends JobManagementEvent {
  final JobPostingData jobData;

  const CreateJob(this.jobData);

  @override
  List<Object?> get props => [jobData];
}

class UpdateJob extends JobManagementEvent {
  final JobPostingData jobData;

  const UpdateJob(this.jobData);

  @override
  List<Object?> get props => [jobData];
}

class DeleteJob extends JobManagementEvent {
  final String jobId;

  const DeleteJob(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

class FilterJobs extends JobManagementEvent {
  final JobPostingStatus? status;
  final JobType? jobType;
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterJobs({this.status, this.jobType, this.startDate, this.endDate});

  @override
  List<Object?> get props => [status, jobType, startDate, endDate];
}

class SearchJobs extends JobManagementEvent {
  final String query;

  const SearchJobs(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearJobFilters extends JobManagementEvent {}

class LoadJobStats extends JobManagementEvent {}

/// Job Management Status
enum JobManagementStatus {
  initial,
  loading,
  loaded,
  refreshing,
  creating,
  created,
  updating,
  updated,
  deleting,
  deleted,
  error,
}

/// Job Management State
class JobManagementState extends Equatable {
  final JobManagementStatus status;
  final String? companyId;
  final List<JobPostingData> jobs;
  final List<JobPostingData> filteredJobs;
  final Map<String, dynamic>? jobStats;
  final FilterJobs? currentFilters;
  final String searchQuery;
  final String? lastCreatedJobId;
  final DateTime? lastUpdated;
  final String? errorMessage;

  const JobManagementState({
    this.status = JobManagementStatus.initial,
    this.companyId,
    this.jobs = const [],
    this.filteredJobs = const [],
    this.jobStats,
    this.currentFilters,
    this.searchQuery = '',
    this.lastCreatedJobId,
    this.lastUpdated,
    this.errorMessage,
  });

  JobManagementState copyWith({
    JobManagementStatus? status,
    String? companyId,
    List<JobPostingData>? jobs,
    List<JobPostingData>? filteredJobs,
    Map<String, dynamic>? jobStats,
    FilterJobs? currentFilters,
    String? searchQuery,
    String? lastCreatedJobId,
    DateTime? lastUpdated,
    String? errorMessage,
  }) {
    return JobManagementState(
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      jobs: jobs ?? this.jobs,
      filteredJobs: filteredJobs ?? this.filteredJobs,
      jobStats: jobStats ?? this.jobStats,
      currentFilters: currentFilters ?? this.currentFilters,
      searchQuery: searchQuery ?? this.searchQuery,
      lastCreatedJobId: lastCreatedJobId ?? this.lastCreatedJobId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    companyId,
    jobs,
    filteredJobs,
    jobStats,
    currentFilters,
    searchQuery,
    lastCreatedJobId,
    lastUpdated,
    errorMessage,
  ];

  /// Check if jobs are loading
  bool get isLoading =>
      status == JobManagementStatus.loading ||
      status == JobManagementStatus.refreshing ||
      status == JobManagementStatus.creating ||
      status == JobManagementStatus.updating ||
      status == JobManagementStatus.deleting;

  /// Check if jobs have data
  bool get hasJobs => jobs.isNotEmpty;

  /// Check if filtered jobs have data
  bool get hasFilteredJobs => filteredJobs.isNotEmpty;

  /// Check if there are active filters
  bool get hasActiveFilters => currentFilters != null || searchQuery.isNotEmpty;

  /// Get active jobs count
  int get activeJobsCount =>
      jobs.where((job) => job.status == JobPostingStatus.active).length;

  /// Get draft jobs count
  int get draftJobsCount =>
      jobs.where((job) => job.status == JobPostingStatus.draft).length;

  /// Get completed jobs count
  int get completedJobsCount =>
      jobs.where((job) => job.status == JobPostingStatus.completed).length;
}
