import 'package:equatable/equatable.dart';

/// Status of dashboard operations
enum DashboardStatus { initial, loading, loaded, error }

/// Company Dashboard BLoC State
class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.selectedNavigationIndex = 0,
    this.isMultiSelectMode = false,
    this.isFilterPanelOpen = false,
    this.isRefreshing = false,
    this.showLiveDashboard = true,
    this.keyboardShortcutsInitialized = false,
    this.selectedItems = const <String>{},
    this.errorMessage,
  });

  final DashboardStatus status;
  final int selectedNavigationIndex;
  final bool isMultiSelectMode;
  final bool isFilterPanelOpen;
  final bool isRefreshing;
  final bool showLiveDashboard;
  final bool keyboardShortcutsInitialized;
  final Set<String> selectedItems;
  final String? errorMessage;

  /// Create copy with updated values
  DashboardState copyWith({
    DashboardStatus? status,
    int? selectedNavigationIndex,
    bool? isMultiSelectMode,
    bool? isFilterPanelOpen,
    bool? isRefreshing,
    bool? showLiveDashboard,
    bool? keyboardShortcutsInitialized,
    Set<String>? selectedItems,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      selectedNavigationIndex: selectedNavigationIndex ?? this.selectedNavigationIndex,
      isMultiSelectMode: isMultiSelectMode ?? this.isMultiSelectMode,
      isFilterPanelOpen: isFilterPanelOpen ?? this.isFilterPanelOpen,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      showLiveDashboard: showLiveDashboard ?? this.showLiveDashboard,
      keyboardShortcutsInitialized: keyboardShortcutsInitialized ?? this.keyboardShortcutsInitialized,
      selectedItems: selectedItems ?? this.selectedItems,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Clear error state
  DashboardState clearError() {
    return copyWith(
      status: DashboardStatus.loaded,
      errorMessage: null,
    );
  }

  /// Set loading state
  DashboardState toLoading() {
    return copyWith(
      status: DashboardStatus.loading,
      isRefreshing: true,
      errorMessage: null,
    );
  }

  /// Set loaded state
  DashboardState toLoaded() {
    return copyWith(
      status: DashboardStatus.loaded,
      isRefreshing: false,
      errorMessage: null,
    );
  }

  /// Set error state
  DashboardState toError(String message) {
    return copyWith(
      status: DashboardStatus.error,
      isRefreshing: false,
      errorMessage: message,
    );
  }

  /// Check if dashboard is in a ready state
  bool get isReady => status == DashboardStatus.loaded;

  /// Check if dashboard is loading
  bool get isLoading => status == DashboardStatus.loading || isRefreshing;

  /// Check if dashboard has error
  bool get hasError => status == DashboardStatus.error;

  /// Get current content view based on navigation index
  String get currentView {
    switch (selectedNavigationIndex) {
      case 0:
        return 'dashboard';
      case 1:
        return 'jobs';
      case 2:
        return 'applications';
      case 3:
        return 'team';
      case 4:
        return 'messages';
      case 5:
        return 'finance';
      case 6:
        return 'omzet';
      case 7:
        return 'performance';
      case 8:
        return 'rapporten';
      default:
        return 'dashboard';
    }
  }

  /// Get navigation labels for feedback
  static const List<String> navigationLabels = [
    'Dashboard',
    'Opdrachten',
    'Sollicitaties',
    'Team',
    'Berichten',
    'Financiën',
    'Omzet',
    'Performance',
    'Rapporten',
  ];

  /// Get current navigation label
  String get currentNavigationLabel {
    if (selectedNavigationIndex < navigationLabels.length) {
      return navigationLabels[selectedNavigationIndex];
    }
    return 'Dashboard';
  }

  @override
  List<Object?> get props => [
        status,
        selectedNavigationIndex,
        isMultiSelectMode,
        isFilterPanelOpen,
        isRefreshing,
        showLiveDashboard,
        keyboardShortcutsInitialized,
        selectedItems,
        errorMessage,
      ];
}