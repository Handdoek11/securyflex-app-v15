import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:securyflex_app/company_dashboard/services/job_posting_service.dart';
import 'package:securyflex_app/company_dashboard/services/application_review_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// Company Dashboard BLoC for managing dashboard state
class CompanyDashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  CompanyDashboardBloc() : super(const DashboardState()) {
    on<DashboardInitialized>(_onDashboardInitialized);
    on<NavigationChanged>(_onNavigationChanged);
    on<MultiSelectToggled>(_onMultiSelectToggled);
    on<FilterPanelToggled>(_onFilterPanelToggled);
    on<DashboardRefreshed>(_onDashboardRefreshed);
    on<LiveDashboardToggled>(_onLiveDashboardToggled);
    on<KeyboardShortcutsInitialized>(_onKeyboardShortcutsInitialized);
    on<ItemSelectionChanged>(_onItemSelectionChanged);
    on<BulkOperationRequested>(_onBulkOperationRequested);
    on<DataExportRequested>(_onDataExportRequested);
  }

  /// Handle dashboard initialization
  Future<void> _onDashboardInitialized(
    DashboardInitialized event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      emit(state.toLoading());

      // Initialize mock data services
      JobPostingService.initializeMockData();
      ApplicationReviewService.instance.initializeMockData('company_demo');

      // Simulate initialization delay
      await Future.delayed(const Duration(milliseconds: 300));

      emit(state.toLoaded());
    } catch (e) {
      emit(state.toError('Fout bij initialiseren dashboard: ${e.toString()}'));
    }
  }

  /// Handle navigation changes
  void _onNavigationChanged(
    NavigationChanged event,
    Emitter<DashboardState> emit,
  ) {
    // Clear multi-select mode when navigating
    final newState = state.copyWith(
      selectedNavigationIndex: event.selectedIndex,
      isMultiSelectMode: false,
      selectedItems: const <String>{},
      showLiveDashboard: event.selectedIndex == 0, // Only show on dashboard
    );

    emit(newState);

    if (kDebugMode) {
      final label = DashboardState.navigationLabels[event.selectedIndex];
      debugPrint('🧭 Navigation changed to: $label (index: ${event.selectedIndex})');
    }
  }

  /// Handle multi-select mode toggle
  void _onMultiSelectToggled(
    MultiSelectToggled event,
    Emitter<DashboardState> emit,
  ) {
    final newState = state.copyWith(
      isMultiSelectMode: event.isMultiSelectMode,
      selectedItems: event.isMultiSelectMode ? state.selectedItems : const <String>{},
    );

    emit(newState);

    if (kDebugMode) {
      debugPrint('🔲 Multi-select mode: ${event.isMultiSelectMode}');
    }
  }

  /// Handle filter panel toggle
  void _onFilterPanelToggled(
    FilterPanelToggled event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(isFilterPanelOpen: event.isFilterPanelOpen));

    if (kDebugMode) {
      debugPrint('🔍 Filter panel: ${event.isFilterPanelOpen ? 'opened' : 'closed'}');
    }
  }

  /// Handle dashboard refresh
  Future<void> _onDashboardRefreshed(
    DashboardRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      emit(state.toLoading());

      // Simulate data refresh
      await Future.delayed(const Duration(milliseconds: 1500));

      // Re-initialize services with fresh data
      JobPostingService.initializeMockData();
      ApplicationReviewService.instance.initializeMockData('company_demo');

      emit(state.toLoaded());

      if (kDebugMode) {
        debugPrint('🔄 Dashboard refreshed successfully');
      }
    } catch (e) {
      emit(state.toError('Fout bij vernieuwen: ${e.toString()}'));
    }
  }

  /// Handle live dashboard toggle
  void _onLiveDashboardToggled(
    LiveDashboardToggled event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(showLiveDashboard: event.showLiveDashboard));

    if (kDebugMode) {
      debugPrint('📊 Live dashboard: ${event.showLiveDashboard ? 'enabled' : 'disabled'}');
    }
  }

  /// Handle keyboard shortcuts initialization
  void _onKeyboardShortcutsInitialized(
    KeyboardShortcutsInitialized event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(keyboardShortcutsInitialized: true));

    if (kDebugMode) {
      debugPrint('⌨️ Keyboard shortcuts initialized');
    }
  }

  /// Handle item selection changes
  void _onItemSelectionChanged(
    ItemSelectionChanged event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(selectedItems: event.selectedItems));

    if (kDebugMode) {
      debugPrint('✅ Selected items: ${event.selectedItems.length}');
    }
  }

  /// Handle bulk operations
  Future<void> _onBulkOperationRequested(
    BulkOperationRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      emit(state.toLoading());

      // Simulate bulk operation processing
      await Future.delayed(const Duration(milliseconds: 800));

      // Clear selection after operation
      emit(state.copyWith(
        status: DashboardStatus.loaded,
        isRefreshing: false,
        selectedItems: const <String>{},
        isMultiSelectMode: false,
      ));

      if (kDebugMode) {
        debugPrint('📦 Bulk operation completed: ${event.operation} on ${event.selectedItems.length} items');
      }
    } catch (e) {
      emit(state.toError('Fout bij bulk operatie: ${e.toString()}'));
    }
  }

  /// Handle data export requests
  Future<void> _onDataExportRequested(
    DataExportRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      emit(state.toLoading());

      // Simulate export processing
      await Future.delayed(const Duration(milliseconds: 1200));

      emit(state.toLoaded());

      if (kDebugMode) {
        debugPrint('📤 Data export completed: ${event.format.toUpperCase()}');
      }
    } catch (e) {
      emit(state.toError('Fout bij exporteren: ${e.toString()}'));
    }
  }

  /// Convenience method to navigate to specific section
  void navigateTo(int index) {
    if (index >= 0 && index < DashboardState.navigationLabels.length) {
      add(NavigationChanged(index));
    }
  }

  /// Convenience method to toggle multi-select
  void toggleMultiSelect() {
    add(MultiSelectToggled(!state.isMultiSelectMode));
  }

  /// Convenience method to refresh dashboard
  void refresh() {
    add(const DashboardRefreshed());
  }

  /// Convenience method to clear selection
  void clearSelection() {
    add(const ItemSelectionChanged(<String>{}));
  }

  /// Convenience method to select all items (implementation depends on current view)
  void selectAll() {
    // This would be implemented based on current view context
    // For now, just ensure multi-select is enabled
    if (!state.isMultiSelectMode) {
      add(const MultiSelectToggled(true));
    }
  }
}
