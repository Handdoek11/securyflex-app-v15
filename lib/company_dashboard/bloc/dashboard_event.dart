import 'package:equatable/equatable.dart';

/// Events for Company Dashboard BLoC
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize dashboard with default settings
class DashboardInitialized extends DashboardEvent {
  const DashboardInitialized();
}

/// Navigate to different section of dashboard
class NavigationChanged extends DashboardEvent {
  final int selectedIndex;

  const NavigationChanged(this.selectedIndex);

  @override
  List<Object?> get props => [selectedIndex];
}

/// Toggle multi-select mode for bulk operations
class MultiSelectToggled extends DashboardEvent {
  final bool isMultiSelectMode;

  const MultiSelectToggled(this.isMultiSelectMode);

  @override
  List<Object?> get props => [isMultiSelectMode];
}

/// Toggle filter panel visibility
class FilterPanelToggled extends DashboardEvent {
  final bool isFilterPanelOpen;

  const FilterPanelToggled(this.isFilterPanelOpen);

  @override
  List<Object?> get props => [isFilterPanelOpen];
}

/// Refresh dashboard data
class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}

/// Toggle live dashboard visibility in right sidebar
class LiveDashboardToggled extends DashboardEvent {
  final bool showLiveDashboard;

  const LiveDashboardToggled(this.showLiveDashboard);

  @override
  List<Object?> get props => [showLiveDashboard];
}

/// Handle keyboard shortcuts initialization
class KeyboardShortcutsInitialized extends DashboardEvent {
  const KeyboardShortcutsInitialized();
}

/// Add/remove items from selection
class ItemSelectionChanged extends DashboardEvent {
  final Set<String> selectedItems;

  const ItemSelectionChanged(this.selectedItems);

  @override
  List<Object?> get props => [selectedItems];
}

/// Handle bulk operations
class BulkOperationRequested extends DashboardEvent {
  final String operation; // 'edit', 'delete', 'archive'
  final Set<String> selectedItems;

  const BulkOperationRequested(this.operation, this.selectedItems);

  @override
  List<Object?> get props => [operation, selectedItems];
}

/// Export data in different formats
class DataExportRequested extends DashboardEvent {
  final String format; // 'csv', 'excel', 'pdf', 'json'

  const DataExportRequested(this.format);

  @override
  List<Object?> get props => [format];
}