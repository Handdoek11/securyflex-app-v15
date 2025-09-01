import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/base_bloc.dart';
import '../../core/bloc/error_handler.dart';
import '../../core/utils/bloc_utils.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../repository/job_repository.dart';
import '../repository/static_job_repository.dart';
import '../model/security_job_data.dart';
import 'job_event.dart';
import 'job_state.dart';

/// Job BLoC for SecuryFlex marketplace
/// Manages job listings, filtering, search, and applications with real-time updates
class JobBloc extends BaseBloc<JobEvent, JobState> {
  final JobRepository _repository;
  final AuthBloc? _authBloc;
  StreamSubscription<List<SecurityJobData>>? _jobsSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  
  String _currentUserId = '';
  
  JobBloc({
    JobRepository? repository,
    AuthBloc? authBloc,
  }) : _repository = repository ?? StaticJobRepository(),
        _authBloc = authBloc,
        super(const JobInitial()) {
    
    // Register event handlers with transformers for performance
    on<JobInitialize>(_onInitialize);
    on<LoadJobs>(_onLoadJobs);
    on<WatchJobs>(_onWatchJobs);
    on<RefreshJobs>(_onRefreshJobs);
    on<SearchJobs>(
      _onSearchJobs,
      transformer: BlocUtils.searchTransformer(),
    );
    on<FilterJobs>(
      _onFilterJobs,
      transformer: BlocUtils.debounce(const Duration(milliseconds: 300)),
    );
    on<ApplyToJob>(_onApplyToJob);
    on<RemoveJobApplication>(_onRemoveJobApplication);
    on<LoadAppliedJobs>(_onLoadAppliedJobs);
    on<ClearFilters>(_onClearFilters);
    on<UpdateSearchQuery>(
      _onUpdateSearchQuery,
      transformer: BlocUtils.debounce(const Duration(milliseconds: 300)),
    );
    on<UpdateHourlyRateRange>(_onUpdateHourlyRateRange);
    on<UpdateMaxDistance>(_onUpdateMaxDistance);
    on<UpdateJobType>(_onUpdateJobType);
    on<UpdateCertificates>(_onUpdateCertificates);
    on<LoadJobMetadata>(_onLoadJobMetadata);
    on<GetJobById>(_onGetJobById);
    on<LoadJobStatistics>(_onLoadJobStatistics);
    on<JobsUpdated>(_onJobsUpdated);
    
    // Listen to auth state changes
    _authSubscription = _authBloc?.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _currentUserId = authState.userId;
        add(const LoadAppliedJobs());
      } else {
        _currentUserId = '';
      }
    });
    
    // Set initial user ID if already authenticated
    if (_authBloc?.state is AuthAuthenticated) {
      _currentUserId = (_authBloc!.state as AuthAuthenticated).userId;
    }
  }
  
  /// Initialize job state
  Future<void> _onInitialize(JobInitialize event, Emitter<JobState> emit) async {
    emit(const JobLoading(loadingMessage: 'Opdrachten initialiseren...'));
    
    try {
      // Load initial jobs
      final jobs = await _repository.getJobs();
      final appliedJobs = _currentUserId.isNotEmpty 
          ? await _repository.getAppliedJobs(_currentUserId)
          : <String>[];
      
      emit(JobLoaded(
        allJobs: jobs,
        filteredJobs: jobs,
        filters: const JobFilter(),
        appliedJobIds: appliedJobs.toSet(),
        hasActiveFilters: false,
      ));
      
      // Start watching for real-time updates
      add(const WatchJobs());
      
    } catch (e) {
      emit(JobError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Load jobs
  Future<void> _onLoadJobs(LoadJobs event, Emitter<JobState> emit) async {
    emit(const JobLoading(loadingMessage: 'Opdrachten laden...'));
    
    try {
      final jobs = await _repository.getJobs();
      final appliedJobs = _currentUserId.isNotEmpty 
          ? await _repository.getAppliedJobs(_currentUserId)
          : <String>[];
      
      emit(JobLoaded(
        allJobs: jobs,
        filteredJobs: jobs,
        filters: const JobFilter(),
        appliedJobIds: appliedJobs.toSet(),
        hasActiveFilters: false,
      ));
    } catch (e) {
      emit(JobError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Watch jobs with real-time updates
  Future<void> _onWatchJobs(WatchJobs event, Emitter<JobState> emit) async {
    await _jobsSubscription?.cancel();
    
    _jobsSubscription = _repository.watchJobs().listen(
      (jobs) {
        if (!isClosed) {
          add(JobsUpdated(jobs));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(JobError(ErrorHandler.fromException(error)));
        }
      },
    );
  }
  
  /// Handle jobs updated from stream
  Future<void> _onJobsUpdated(JobsUpdated event, Emitter<JobState> emit) async {
    if (state is JobLoaded) {
      final currentState = state as JobLoaded;
      final jobs = event.jobs.cast<SecurityJobData>();
      
      // Apply current filters to new data
      final filteredJobs = await _applyFilters(jobs, currentState.filters);
      
      emit(currentState.copyWith(
        allJobs: jobs,
        filteredJobs: filteredJobs,
      ));
    }
  }
  
  /// Refresh jobs
  Future<void> _onRefreshJobs(RefreshJobs event, Emitter<JobState> emit) async {
    try {
      await _repository.refreshJobs();
      
      if (state is JobLoaded) {
        final currentState = state as JobLoaded;
        final jobs = await _repository.getJobs();
        final filteredJobs = await _applyFilters(jobs, currentState.filters);
        
        emit(currentState.copyWith(
          allJobs: jobs,
          filteredJobs: filteredJobs,
        ));
      }
    } catch (e) {
      emit(JobError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Search jobs
  Future<void> _onSearchJobs(SearchJobs event, Emitter<JobState> emit) async {
    if (state is JobLoaded) {
      final currentState = state as JobLoaded;
      final newFilters = currentState.filters.copyWith(searchQuery: event.query);
      
      try {
        final filteredJobs = await _applyFilters(currentState.allJobs, newFilters);
        
        emit(currentState.copyWith(
          filteredJobs: filteredJobs,
          filters: newFilters,
          hasActiveFilters: newFilters.hasActiveFilters,
        ));
      } catch (e) {
        emit(JobError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Filter jobs
  Future<void> _onFilterJobs(FilterJobs event, Emitter<JobState> emit) async {
    if (state is JobLoaded) {
      final currentState = state as JobLoaded;
      final newFilters = JobFilter(
        searchQuery: event.searchQuery ?? currentState.filters.searchQuery,
        hourlyRateRange: event.hourlyRateRange ?? currentState.filters.hourlyRateRange,
        maxDistance: event.maxDistance ?? currentState.filters.maxDistance,
        jobType: event.jobType ?? currentState.filters.jobType,
        certificates: event.certificates ?? currentState.filters.certificates,
      );
      
      try {
        final filteredJobs = await _applyFilters(currentState.allJobs, newFilters);
        
        emit(currentState.copyWith(
          filteredJobs: filteredJobs,
          filters: newFilters,
          hasActiveFilters: newFilters.hasActiveFilters,
        ));
      } catch (e) {
        emit(JobError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Apply to job
  Future<void> _onApplyToJob(ApplyToJob event, Emitter<JobState> emit) async {
    if (_currentUserId.isEmpty) {
      emit(JobError(AppError(
        code: 'not_authenticated',
        message: 'User not authenticated',
        category: ErrorCategory.authentication,
      )));
      return;
    }
    
    try {
      final success = await _repository.applyToJob(
        event.jobId,
        _currentUserId,
        message: event.message,
      );
      
      if (success) {
        // Find job title for success message
        String jobTitle = 'Opdracht';
        if (state is JobLoaded) {
          final currentState = state as JobLoaded;
          final job = currentState.allJobs.firstWhere(
            (job) => job.jobId == event.jobId,
            orElse: () => SecurityJobData(
              jobId: event.jobId,
              jobTitle: 'Opdracht',
              companyName: '',
              location: '',
              hourlyRate: 0,
              distance: 0,
              jobType: '',
              requiredCertificates: [],
              description: '',
            ),
          );
          jobTitle = job.jobTitle;
          
          // Update applied jobs
          final newAppliedJobs = Set<String>.from(currentState.appliedJobIds)
            ..add(event.jobId);
          
          emit(currentState.copyWith(appliedJobIds: newAppliedJobs));
        }
        
        emit(JobApplicationSuccess(
          jobId: event.jobId,
          jobTitle: jobTitle,
        ));
      } else {
        emit(JobError(AppError(
          code: 'application_failed',
          message: 'Failed to apply to job',
          category: ErrorCategory.general,
        )));
      }
    } catch (e) {
      emit(JobError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Remove job application
  Future<void> _onRemoveJobApplication(RemoveJobApplication event, Emitter<JobState> emit) async {
    if (_currentUserId.isEmpty) {
      emit(JobError(AppError(
        code: 'not_authenticated',
        message: 'User not authenticated',
        category: ErrorCategory.authentication,
      )));
      return;
    }
    
    try {
      final success = await _repository.removeApplication(event.jobId, _currentUserId);
      
      if (success) {
        // Find job title for success message
        String jobTitle = 'Opdracht';
        if (state is JobLoaded) {
          final currentState = state as JobLoaded;
          final job = currentState.allJobs.firstWhere(
            (job) => job.jobId == event.jobId,
            orElse: () => SecurityJobData(
              jobId: event.jobId,
              jobTitle: 'Opdracht',
              companyName: '',
              location: '',
              hourlyRate: 0,
              distance: 0,
              jobType: '',
              requiredCertificates: [],
              description: '',
            ),
          );
          jobTitle = job.jobTitle;
          
          // Update applied jobs
          final newAppliedJobs = Set<String>.from(currentState.appliedJobIds)
            ..remove(event.jobId);
          
          emit(currentState.copyWith(appliedJobIds: newAppliedJobs));
        }
        
        emit(JobApplicationRemoved(
          jobId: event.jobId,
          jobTitle: jobTitle,
        ));
      } else {
        emit(JobError(AppError(
          code: 'remove_application_failed',
          message: 'Failed to remove application',
          category: ErrorCategory.general,
        )));
      }
    } catch (e) {
      emit(JobError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Load applied jobs
  Future<void> _onLoadAppliedJobs(LoadAppliedJobs event, Emitter<JobState> emit) async {
    if (_currentUserId.isEmpty) return;
    
    try {
      final appliedJobs = await _repository.getAppliedJobs(_currentUserId);
      
      if (state is JobLoaded) {
        final currentState = state as JobLoaded;
        emit(currentState.copyWith(appliedJobIds: appliedJobs.toSet()));
      }
    } catch (e) {
      // Don't emit error for applied jobs loading failure
      debugPrint('Failed to load applied jobs: $e');
    }
  }
  
  /// Clear all filters
  Future<void> _onClearFilters(ClearFilters event, Emitter<JobState> emit) async {
    if (state is JobLoaded) {
      final currentState = state as JobLoaded;
      const newFilters = JobFilter();
      
      emit(currentState.copyWith(
        filteredJobs: currentState.allJobs,
        filters: newFilters,
        hasActiveFilters: false,
      ));
    }
  }
  
  /// Update search query
  Future<void> _onUpdateSearchQuery(UpdateSearchQuery event, Emitter<JobState> emit) async {
    add(SearchJobs(event.query));
  }
  
  /// Update hourly rate range
  Future<void> _onUpdateHourlyRateRange(UpdateHourlyRateRange event, Emitter<JobState> emit) async {
    if (state is JobLoaded) {
      add(FilterJobs(hourlyRateRange: event.range));
    }
  }
  
  /// Update max distance
  Future<void> _onUpdateMaxDistance(UpdateMaxDistance event, Emitter<JobState> emit) async {
    if (state is JobLoaded) {
      add(FilterJobs(maxDistance: event.distance));
    }
  }
  
  /// Update job type
  Future<void> _onUpdateJobType(UpdateJobType event, Emitter<JobState> emit) async {
    if (state is JobLoaded) {
      add(FilterJobs(jobType: event.jobType));
    }
  }
  
  /// Update certificates
  Future<void> _onUpdateCertificates(UpdateCertificates event, Emitter<JobState> emit) async {
    if (state is JobLoaded) {
      add(FilterJobs(certificates: event.certificates));
    }
  }
  
  /// Load job metadata
  Future<void> _onLoadJobMetadata(LoadJobMetadata event, Emitter<JobState> emit) async {
    try {
      final jobTypes = await _repository.getJobTypes();
      final certificates = await _repository.getAvailableCertificates();
      final companies = await _repository.getCompanies();
      final locations = await _repository.getLocations();
      
      emit(JobMetadataLoaded(
        jobTypes: jobTypes,
        certificates: certificates,
        companies: companies,
        locations: locations,
      ));
    } catch (e) {
      emit(JobError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Get job by ID
  Future<void> _onGetJobById(GetJobById event, Emitter<JobState> emit) async {
    try {
      final job = await _repository.getJobById(event.jobId);
      
      if (job != null) {
        // Could emit a specific state for single job, but for now just ensure it's in the list
        if (state is JobLoaded) {
          final currentState = state as JobLoaded;
          if (!currentState.allJobs.any((j) => j.jobId == event.jobId)) {
            final updatedJobs = [...currentState.allJobs, job];
            emit(currentState.copyWith(allJobs: updatedJobs));
          }
        }
      } else {
        emit(JobError(AppError(
          code: 'job_not_found',
          message: 'Job not found',
          category: ErrorCategory.general,
        )));
      }
    } catch (e) {
      emit(JobError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Load job statistics
  Future<void> _onLoadJobStatistics(LoadJobStatistics event, Emitter<JobState> emit) async {
    try {
      final statistics = await _repository.getJobStatistics();
      emit(JobStatisticsLoaded(statistics));
    } catch (e) {
      emit(JobError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Apply filters to job list
  Future<List<SecurityJobData>> _applyFilters(
    List<SecurityJobData> jobs,
    JobFilter filters,
  ) async {
    return await _repository.filterJobs(
      searchQuery: filters.searchQuery.isNotEmpty ? filters.searchQuery : null,
      minHourlyRate: filters.hourlyRateRange.start,
      maxHourlyRate: filters.hourlyRateRange.end,
      maxDistance: filters.maxDistance,
      jobType: filters.jobType.isNotEmpty ? filters.jobType : null,
      requiredCertificates: filters.certificates.isNotEmpty ? filters.certificates : null,
    );
  }
  
  @override
  Future<void> close() {
    _jobsSubscription?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
  
  /// Convenience getters for current state
  bool get isLoaded => state is JobLoaded;
  bool get isLoading => state is JobLoading;
  bool get hasError => state is JobError;
  
  JobLoaded? get currentJobState {
    return state is JobLoaded ? state as JobLoaded : null;
  }
  
  List<SecurityJobData> get allJobs {
    return currentJobState?.allJobs ?? [];
  }
  
  List<SecurityJobData> get filteredJobs {
    return currentJobState?.filteredJobs ?? [];
  }
  
  JobFilter get currentFilters {
    return currentJobState?.filters ?? const JobFilter();
  }
  
  Set<String> get appliedJobIds {
    return currentJobState?.appliedJobIds ?? {};
  }
  
  bool get hasActiveFilters {
    return currentJobState?.hasActiveFilters ?? false;
  }
}
