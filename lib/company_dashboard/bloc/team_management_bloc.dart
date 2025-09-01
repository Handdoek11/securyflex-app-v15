import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../services/team_management_service.dart';
import '../models/team_management_data.dart';

/// BLoC for Company Team Management following SecuryFlex patterns
/// Handles team operations, real-time status tracking, and guard coordination
class TeamManagementBloc
    extends Bloc<TeamManagementEvent, TeamManagementState> {
  final TeamManagementService _teamService;

  TeamManagementBloc({TeamManagementService? teamService})
    : _teamService = teamService ?? TeamManagementService(),
      super(const TeamManagementState()) {
    // Register event handlers
    on<LoadCompanyTeam>(_onLoadCompanyTeam);
    on<RefreshCompanyTeam>(_onRefreshCompanyTeam);
    on<FilterTeamMembers>(_onFilterTeamMembers);
    on<SearchTeamMembers>(_onSearchTeamMembers);
    on<ClearTeamFilters>(_onClearTeamFilters);
  }

  /// Load company team
  Future<void> _onLoadCompanyTeam(
    LoadCompanyTeam event,
    Emitter<TeamManagementState> emit,
  ) async {
    emit(state.copyWith(status: TeamManagementStatus.loading));

    try {
      debugPrint('Loading company team for: ${event.companyId}');

      // Initialize team management and get mock data for now
      await _teamService.initializeTeamManagement(event.companyId);
      final teamStatus = _teamService.generateMockTeamData(event.companyId);

      emit(
        state.copyWith(
          status: TeamManagementStatus.loaded,
          companyId: event.companyId,
          teamStatus: teamStatus,
          lastUpdated: DateTime.now(),
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('Error loading company team: $e');
      emit(
        state.copyWith(
          status: TeamManagementStatus.error,
          errorMessage: 'Fout bij laden van team: ${e.toString()}',
        ),
      );
    }
  }

  /// Refresh company team
  Future<void> _onRefreshCompanyTeam(
    RefreshCompanyTeam event,
    Emitter<TeamManagementState> emit,
  ) async {
    if (state.companyId == null) return;

    emit(state.copyWith(status: TeamManagementStatus.refreshing));

    try {
      final teamStatus = _teamService.generateMockTeamData(state.companyId!);

      emit(
        state.copyWith(
          status: TeamManagementStatus.loaded,
          teamStatus: teamStatus,
          lastUpdated: DateTime.now(),
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('Error refreshing company team: $e');
      emit(
        state.copyWith(
          status: TeamManagementStatus.error,
          errorMessage: 'Fout bij verversen van team: ${e.toString()}',
        ),
      );
    }
  }

  /// Filter team members
  void _onFilterTeamMembers(
    FilterTeamMembers event,
    Emitter<TeamManagementState> emit,
  ) {
    // For now, just store the filters since we're using mock data
    emit(state.copyWith(currentFilters: event));
  }

  /// Search team members
  void _onSearchTeamMembers(
    SearchTeamMembers event,
    Emitter<TeamManagementState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  /// Clear filters
  void _onClearTeamFilters(
    ClearTeamFilters event,
    Emitter<TeamManagementState> emit,
  ) {
    emit(state.copyWith(currentFilters: null, searchQuery: ''));
  }
}

/// Team Management Events
abstract class TeamManagementEvent extends Equatable {
  const TeamManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadCompanyTeam extends TeamManagementEvent {
  final String companyId;

  const LoadCompanyTeam(this.companyId);

  @override
  List<Object?> get props => [companyId];
}

class RefreshCompanyTeam extends TeamManagementEvent {}

class FilterTeamMembers extends TeamManagementEvent {
  final String? status;
  final String? role;
  final String? location;

  const FilterTeamMembers({this.status, this.role, this.location});

  @override
  List<Object?> get props => [status, role, location];
}

class SearchTeamMembers extends TeamManagementEvent {
  final String query;

  const SearchTeamMembers(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearTeamFilters extends TeamManagementEvent {}

/// Team Management Status
enum TeamManagementStatus { initial, loading, loaded, refreshing, error }

/// Team Management State
class TeamManagementState extends Equatable {
  final TeamManagementStatus status;
  final String? companyId;
  final TeamStatusData? teamStatus;
  final FilterTeamMembers? currentFilters;
  final String searchQuery;
  final DateTime? lastUpdated;
  final String? errorMessage;

  const TeamManagementState({
    this.status = TeamManagementStatus.initial,
    this.companyId,
    this.teamStatus,
    this.currentFilters,
    this.searchQuery = '',
    this.lastUpdated,
    this.errorMessage,
  });

  TeamManagementState copyWith({
    TeamManagementStatus? status,
    String? companyId,
    TeamStatusData? teamStatus,
    FilterTeamMembers? currentFilters,
    String? searchQuery,
    DateTime? lastUpdated,
    String? errorMessage,
  }) {
    return TeamManagementState(
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      teamStatus: teamStatus ?? this.teamStatus,
      currentFilters: currentFilters ?? this.currentFilters,
      searchQuery: searchQuery ?? this.searchQuery,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    companyId,
    teamStatus,
    currentFilters,
    searchQuery,
    lastUpdated,
    errorMessage,
  ];

  /// Check if team is loading
  bool get isLoading =>
      status == TeamManagementStatus.loading ||
      status == TeamManagementStatus.refreshing;

  /// Check if team has data
  bool get hasTeamStatus => teamStatus != null;

  /// Check if there are active filters
  bool get hasActiveFilters => currentFilters != null || searchQuery.isNotEmpty;

  /// Get total guards count
  int get totalGuardsCount => teamStatus?.totalGuards ?? 0;

  /// Get available guards count
  int get availableGuardsCount => teamStatus?.availableGuards ?? 0;

  /// Get on duty guards count
  int get onDutyGuardsCount => teamStatus?.onDutyGuards ?? 0;

  /// Get off duty guards count
  int get offDutyGuardsCount => teamStatus?.offDutyGuards ?? 0;
}
