import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../services/application_review_service.dart' as app_service;

/// BLoC for Company Application Review following SecuryFlex patterns
/// Handles application review operations, filtering, and real-time updates
class ApplicationReviewBloc
    extends Bloc<ApplicationReviewEvent, ApplicationReviewState> {
  final app_service.ApplicationReviewService _applicationService;

  ApplicationReviewBloc({
    app_service.ApplicationReviewService? applicationService,
  }) : _applicationService =
           applicationService ?? app_service.ApplicationReviewService.instance,
       super(const ApplicationReviewState()) {
    // Register event handlers
    on<LoadCompanyApplications>(_onLoadCompanyApplications);
    on<RefreshCompanyApplications>(_onRefreshCompanyApplications);
    on<AcceptApplication>(_onAcceptApplication);
    on<RejectApplication>(_onRejectApplication);
    on<FilterApplications>(_onFilterApplications);
    on<SearchApplications>(_onSearchApplications);
    on<ClearApplicationFilters>(_onClearApplicationFilters);
    on<LoadApplicationStats>(_onLoadApplicationStats);
    on<LoadJobApplications>(_onLoadJobApplications);
    on<BulkAcceptApplications>(_onBulkAcceptApplications);
    on<BulkRejectApplications>(_onBulkRejectApplications);
  }

  /// Load company applications
  Future<void> _onLoadCompanyApplications(
    LoadCompanyApplications event,
    Emitter<ApplicationReviewState> emit,
  ) async {
    emit(state.copyWith(status: ApplicationReviewStatus.loading));

    try {
      debugPrint('Loading company applications for: ${event.companyId}');

      final applications = await _applicationService.getCompanyApplications(
        event.companyId,
      );
      final stats = await _applicationService.getApplicationStats(
        event.companyId,
      );

      emit(
        state.copyWith(
          status: ApplicationReviewStatus.loaded,
          companyId: event.companyId,
          applications: applications,
          filteredApplications: applications,
          applicationStats: stats,
          lastUpdated: DateTime.now(),
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('Error loading company applications: $e');
      emit(
        state.copyWith(
          status: ApplicationReviewStatus.error,
          errorMessage: 'Fout bij laden van sollicitaties: ${e.toString()}',
        ),
      );
    }
  }

  /// Refresh company applications
  Future<void> _onRefreshCompanyApplications(
    RefreshCompanyApplications event,
    Emitter<ApplicationReviewState> emit,
  ) async {
    if (state.companyId == null) return;

    emit(state.copyWith(status: ApplicationReviewStatus.refreshing));

    try {
      final applications = await _applicationService.getCompanyApplications(
        state.companyId!,
      );
      final stats = await _applicationService.getApplicationStats(
        state.companyId!,
      );

      emit(
        state.copyWith(
          status: ApplicationReviewStatus.loaded,
          applications: applications,
          filteredApplications: applications,
          applicationStats: stats,
          lastUpdated: DateTime.now(),
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('Error refreshing company applications: $e');
      emit(
        state.copyWith(
          status: ApplicationReviewStatus.error,
          errorMessage: 'Fout bij verversen van sollicitaties: ${e.toString()}',
        ),
      );
    }
  }

  /// Accept application
  Future<void> _onAcceptApplication(
    AcceptApplication event,
    Emitter<ApplicationReviewState> emit,
  ) async {
    emit(state.copyWith(status: ApplicationReviewStatus.accepting));

    try {
      final success = await _applicationService.acceptApplication(
        event.applicationId,
        message: event.message,
      );

      if (success) {
        // Reload applications to get updated data
        add(RefreshCompanyApplications());

        emit(state.copyWith(status: ApplicationReviewStatus.accepted));
      } else {
        emit(
          state.copyWith(
            status: ApplicationReviewStatus.error,
            errorMessage: 'Fout bij accepteren van sollicitatie',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error accepting application: $e');
      emit(
        state.copyWith(
          status: ApplicationReviewStatus.error,
          errorMessage: 'Fout bij accepteren van sollicitatie: ${e.toString()}',
        ),
      );
    }
  }

  /// Reject application
  Future<void> _onRejectApplication(
    RejectApplication event,
    Emitter<ApplicationReviewState> emit,
  ) async {
    emit(state.copyWith(status: ApplicationReviewStatus.rejecting));

    try {
      final success = await _applicationService.rejectApplication(
        event.applicationId,
        reason: event.reason,
      );

      if (success) {
        // Reload applications to get updated data
        add(RefreshCompanyApplications());

        emit(state.copyWith(status: ApplicationReviewStatus.rejected));
      } else {
        emit(
          state.copyWith(
            status: ApplicationReviewStatus.error,
            errorMessage: 'Fout bij afwijzen van sollicitatie',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting application: $e');
      emit(
        state.copyWith(
          status: ApplicationReviewStatus.error,
          errorMessage: 'Fout bij afwijzen van sollicitatie: ${e.toString()}',
        ),
      );
    }
  }

  /// Load applications for specific job
  Future<void> _onLoadJobApplications(
    LoadJobApplications event,
    Emitter<ApplicationReviewState> emit,
  ) async {
    emit(state.copyWith(status: ApplicationReviewStatus.loading));

    try {
      final applications = await _applicationService.getJobApplications(
        event.jobId,
      );

      emit(
        state.copyWith(
          status: ApplicationReviewStatus.loaded,
          applications: applications,
          filteredApplications: applications,
          selectedJobId: event.jobId,
          lastUpdated: DateTime.now(),
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('Error loading job applications: $e');
      emit(
        state.copyWith(
          status: ApplicationReviewStatus.error,
          errorMessage: 'Fout bij laden van job sollicitaties: ${e.toString()}',
        ),
      );
    }
  }

  /// Filter applications
  void _onFilterApplications(
    FilterApplications event,
    Emitter<ApplicationReviewState> emit,
  ) {
    final filteredApplications = state.applications.where((app) {
      // Status filter
      if (event.status != null && app.status.name != event.status) {
        return false;
      }

      // Job filter
      if (event.jobId != null && app.jobId != event.jobId) {
        return false;
      }

      // Date range filter
      if (event.startDate != null &&
          app.applicationDate.isBefore(event.startDate!)) {
        return false;
      }
      if (event.endDate != null &&
          app.applicationDate.isAfter(event.endDate!)) {
        return false;
      }

      return true;
    }).toList();

    emit(
      state.copyWith(
        filteredApplications: filteredApplications,
        currentFilters: event,
      ),
    );
  }

  /// Search applications
  void _onSearchApplications(
    SearchApplications event,
    Emitter<ApplicationReviewState> emit,
  ) {
    if (event.query.isEmpty) {
      emit(
        state.copyWith(
          filteredApplications: state.applications,
          searchQuery: '',
        ),
      );
      return;
    }

    final searchQuery = event.query.toLowerCase();
    final searchResults = state.applications.where((app) {
      return app.guardName.toLowerCase().contains(searchQuery) ||
          app.guardEmail.toLowerCase().contains(searchQuery) ||
          app.motivationMessage.toLowerCase().contains(searchQuery);
    }).toList();

    emit(
      state.copyWith(
        filteredApplications: searchResults,
        searchQuery: event.query,
      ),
    );
  }

  /// Clear filters
  void _onClearApplicationFilters(
    ClearApplicationFilters event,
    Emitter<ApplicationReviewState> emit,
  ) {
    emit(
      state.copyWith(
        filteredApplications: state.applications,
        currentFilters: null,
        searchQuery: '',
      ),
    );
  }

  /// Load application statistics
  Future<void> _onLoadApplicationStats(
    LoadApplicationStats event,
    Emitter<ApplicationReviewState> emit,
  ) async {
    if (state.companyId == null) return;

    try {
      final stats = await _applicationService.getApplicationStats(
        state.companyId!,
      );

      emit(
        state.copyWith(applicationStats: stats, lastUpdated: DateTime.now()),
      );
    } catch (e) {
      debugPrint('Error loading application stats: $e');
      emit(
        state.copyWith(
          errorMessage:
              'Fout bij laden van sollicitatie statistieken: ${e.toString()}',
        ),
      );
    }
  }
  
  /// Handle bulk accept applications (MVP: Creates individual 1-on-1 chats)
  Future<void> _onBulkAcceptApplications(
    BulkAcceptApplications event,
    Emitter<ApplicationReviewState> emit,
  ) async {
    emit(state.copyWith(status: ApplicationReviewStatus.accepting));

    try {
      debugPrint('Processing bulk accept: ${event.applicationIds.length} applications');

      final result = await _applicationService.bulkAcceptApplications(
        companyId: event.companyId,
        companyName: event.companyName,
        applicationIds: event.applicationIds,
        jobId: event.jobId,
        jobTitle: event.jobTitle,
        jobLocation: event.jobLocation,
        jobStartDate: event.jobStartDate,
        acceptanceMessage: event.acceptanceMessage,
      );

      if (result.success) {
        // Reload applications to get updated data
        add(RefreshCompanyApplications());

        emit(state.copyWith(
          status: ApplicationReviewStatus.accepted,
          bulkOperationResult: result,
        ));

        debugPrint(
          'Bulk accept completed: ${result.successCount} successful, '
          '${result.createdConversationIds.length} individual chats created',
        );
      } else {
        emit(state.copyWith(
          status: ApplicationReviewStatus.error,
          errorMessage: result.displayMessage,
          bulkOperationResult: result,
        ));
      }
    } catch (e) {
      debugPrint('Error in bulk accept applications: $e');
      emit(state.copyWith(
        status: ApplicationReviewStatus.error,
        errorMessage: 'Fout bij bulk accepteren: ${e.toString()}',
      ));
    }
  }

  /// Handle bulk reject applications
  Future<void> _onBulkRejectApplications(
    BulkRejectApplications event,
    Emitter<ApplicationReviewState> emit,
  ) async {
    emit(state.copyWith(status: ApplicationReviewStatus.rejecting));

    try {
      debugPrint('Processing bulk reject: ${event.applicationIds.length} applications');

      final result = await _applicationService.bulkRejectApplications(
        applicationIds: event.applicationIds,
        rejectionReason: event.rejectionReason,
        personalizedReasons: event.personalizedReasons,
      );

      if (result.success) {
        // Reload applications to get updated data
        add(RefreshCompanyApplications());

        emit(state.copyWith(
          status: ApplicationReviewStatus.rejected,
          bulkOperationResult: result,
        ));

        debugPrint('Bulk reject completed: ${result.successCount} successful');
      } else {
        emit(state.copyWith(
          status: ApplicationReviewStatus.error,
          errorMessage: result.displayMessage,
          bulkOperationResult: result,
        ));
      }
    } catch (e) {
      debugPrint('Error in bulk reject applications: $e');
      emit(state.copyWith(
        status: ApplicationReviewStatus.error,
        errorMessage: 'Fout bij bulk afwijzen: ${e.toString()}',
      ));
    }
  }
}

/// Application Review Events
abstract class ApplicationReviewEvent extends Equatable {
  const ApplicationReviewEvent();

  @override
  List<Object?> get props => [];
}

class LoadCompanyApplications extends ApplicationReviewEvent {
  final String companyId;

  const LoadCompanyApplications(this.companyId);

  @override
  List<Object?> get props => [companyId];
}

class RefreshCompanyApplications extends ApplicationReviewEvent {}

class AcceptApplication extends ApplicationReviewEvent {
  final String applicationId;
  final String? message;

  const AcceptApplication(this.applicationId, {this.message});

  @override
  List<Object?> get props => [applicationId, message];
}

class RejectApplication extends ApplicationReviewEvent {
  final String applicationId;
  final String? reason;

  const RejectApplication(this.applicationId, {this.reason});

  @override
  List<Object?> get props => [applicationId, reason];
}

class LoadJobApplications extends ApplicationReviewEvent {
  final String jobId;

  const LoadJobApplications(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

class FilterApplications extends ApplicationReviewEvent {
  final String? status;
  final String? jobId;
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterApplications({
    this.status,
    this.jobId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [status, jobId, startDate, endDate];
}

class SearchApplications extends ApplicationReviewEvent {
  final String query;

  const SearchApplications(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearApplicationFilters extends ApplicationReviewEvent {}

class LoadApplicationStats extends ApplicationReviewEvent {}

/// Bulk accept applications event (MVP: Creates individual 1-on-1 chats)
class BulkAcceptApplications extends ApplicationReviewEvent {
  final String companyId;
  final String companyName;
  final List<String> applicationIds;
  final String jobId;
  final String jobTitle;
  final String jobLocation;
  final DateTime jobStartDate;
  final String? acceptanceMessage;

  const BulkAcceptApplications({
    required this.companyId,
    required this.companyName,
    required this.applicationIds,
    required this.jobId,
    required this.jobTitle,
    required this.jobLocation,
    required this.jobStartDate,
    this.acceptanceMessage,
  });

  @override
  List<Object?> get props => [
        companyId,
        companyName,
        applicationIds,
        jobId,
        jobTitle,
        jobLocation,
        jobStartDate,
        acceptanceMessage,
      ];
}

/// Bulk reject applications event
class BulkRejectApplications extends ApplicationReviewEvent {
  final List<String> applicationIds;
  final String rejectionReason;
  final Map<String, String>? personalizedReasons;

  const BulkRejectApplications({
    required this.applicationIds,
    required this.rejectionReason,
    this.personalizedReasons,
  });

  @override
  List<Object?> get props => [applicationIds, rejectionReason, personalizedReasons];
}

/// Application Review Status
enum ApplicationReviewStatus {
  initial,
  loading,
  loaded,
  refreshing,
  accepting,
  accepted,
  rejecting,
  rejected,
  error,
}

/// Application Review State
class ApplicationReviewState extends Equatable {
  final ApplicationReviewStatus status;
  final String? companyId;
  final String? selectedJobId;
  final List<app_service.ApplicationReviewData> applications;
  final List<app_service.ApplicationReviewData> filteredApplications;
  final Map<String, dynamic>? applicationStats;
  final FilterApplications? currentFilters;
  final String searchQuery;
  final DateTime? lastUpdated;
  final String? errorMessage;
  final app_service.BulkApplicationResult? bulkOperationResult;

  const ApplicationReviewState({
    this.status = ApplicationReviewStatus.initial,
    this.companyId,
    this.selectedJobId,
    this.applications = const [],
    this.filteredApplications = const [],
    this.applicationStats,
    this.currentFilters,
    this.searchQuery = '',
    this.lastUpdated,
    this.errorMessage,
    this.bulkOperationResult,
  });

  ApplicationReviewState copyWith({
    ApplicationReviewStatus? status,
    String? companyId,
    String? selectedJobId,
    List<app_service.ApplicationReviewData>? applications,
    List<app_service.ApplicationReviewData>? filteredApplications,
    Map<String, dynamic>? applicationStats,
    FilterApplications? currentFilters,
    String? searchQuery,
    DateTime? lastUpdated,
    String? errorMessage,
    app_service.BulkApplicationResult? bulkOperationResult,
  }) {
    return ApplicationReviewState(
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      selectedJobId: selectedJobId ?? this.selectedJobId,
      applications: applications ?? this.applications,
      filteredApplications: filteredApplications ?? this.filteredApplications,
      applicationStats: applicationStats ?? this.applicationStats,
      currentFilters: currentFilters ?? this.currentFilters,
      searchQuery: searchQuery ?? this.searchQuery,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage,
      bulkOperationResult: bulkOperationResult,
    );
  }

  @override
  List<Object?> get props => [
    status,
    companyId,
    selectedJobId,
    applications,
    filteredApplications,
    applicationStats,
    currentFilters,
    searchQuery,
    lastUpdated,
    errorMessage,
    bulkOperationResult,
  ];

  /// Check if applications are loading
  bool get isLoading =>
      status == ApplicationReviewStatus.loading ||
      status == ApplicationReviewStatus.refreshing ||
      status == ApplicationReviewStatus.accepting ||
      status == ApplicationReviewStatus.rejecting;

  /// Check if applications have data
  bool get hasApplications => applications.isNotEmpty;

  /// Check if filtered applications have data
  bool get hasFilteredApplications => filteredApplications.isNotEmpty;

  /// Check if there are active filters
  bool get hasActiveFilters => currentFilters != null || searchQuery.isNotEmpty;

  /// Get pending applications count
  int get pendingApplicationsCount => applications
      .where((app) => app.status == app_service.ApplicationReviewStatus.pending)
      .length;

  /// Get accepted applications count
  int get acceptedApplicationsCount => applications
      .where(
        (app) => app.status == app_service.ApplicationReviewStatus.accepted,
      )
      .length;

  /// Get rejected applications count
  int get rejectedApplicationsCount => applications
      .where(
        (app) => app.status == app_service.ApplicationReviewStatus.rejected,
      )
      .length;
}
