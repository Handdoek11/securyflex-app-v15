import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../services/analytics_service.dart';
import '../models/analytics_data_models.dart';

/// BLoC for Company Analytics Dashboard following SecuryFlex patterns
/// Handles real-time updates, filtering, and time-range selection
class AnalyticsDashboardBloc extends Bloc<AnalyticsDashboardEvent, AnalyticsDashboardState> {
  final AnalyticsService _analyticsService;
  StreamSubscription? _dataSubscription;

  AnalyticsDashboardBloc({
    AnalyticsService? analyticsService,
  }) : _analyticsService = analyticsService ?? AnalyticsService.instance,
       super(AnalyticsDashboardState()) {
    
    // Register event handlers
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboardData>(_onRefreshDashboardData);
    on<UpdateTimeRange>(_onUpdateTimeRange);
    on<UpdateMetricFilter>(_onUpdateMetricFilter);
    on<UpdateSourceFilter>(_onUpdateSourceFilter);
    on<LoadJobPerformance>(_onLoadJobPerformance);
    on<LoadFunnelInsights>(_onLoadFunnelInsights);
    on<LoadSourceAnalysis>(_onLoadSourceAnalysis);
    on<TriggerAggregation>(_onTriggerAggregation);
    on<ClearCache>(_onClearCache);
  }

  /// Load initial dashboard data
  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<AnalyticsDashboardState> emit,
  ) async {
    emit(state.copyWith(status: AnalyticsDashboardStatus.loading));

    try {
      debugPrint('Loading dashboard data for company: ${event.companyId}');

      // Load main dashboard data
      final dashboardData = await _analyticsService.getCompanyDashboardData(event.companyId);
      
      // Load time series data for the selected range
      final timeSeriesData = await _analyticsService.getTimeSeriesData(
        companyId: event.companyId,
        startDate: state.timeRange.startDate,
        endDate: state.timeRange.endDate,
      );

      emit(state.copyWith(
        status: AnalyticsDashboardStatus.loaded,
        companyId: event.companyId,
        dashboardData: dashboardData,
        timeSeriesData: timeSeriesData,
        lastUpdated: DateTime.now(),
        errorMessage: null,
      ));

    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      emit(state.copyWith(
        status: AnalyticsDashboardStatus.error,
        errorMessage: 'Fout bij laden van dashboard data: ${e.toString()}',
      ));
    }
  }

  /// Refresh dashboard data
  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<AnalyticsDashboardState> emit,
  ) async {
    if (state.companyId == null) return;

    emit(state.copyWith(status: AnalyticsDashboardStatus.refreshing));

    try {
      // Clear cache before refreshing
      _analyticsService.clearAllCaches();

      // Reload dashboard data
      final dashboardData = await _analyticsService.getCompanyDashboardData(state.companyId!);
      
      final timeSeriesData = await _analyticsService.getTimeSeriesData(
        companyId: state.companyId!,
        startDate: state.timeRange.startDate,
        endDate: state.timeRange.endDate,
      );

      emit(state.copyWith(
        status: AnalyticsDashboardStatus.loaded,
        dashboardData: dashboardData,
        timeSeriesData: timeSeriesData,
        lastUpdated: DateTime.now(),
        errorMessage: null,
      ));

    } catch (e) {
      debugPrint('Error refreshing dashboard data: $e');
      emit(state.copyWith(
        status: AnalyticsDashboardStatus.error,
        errorMessage: 'Fout bij verversen van data: ${e.toString()}',
      ));
    }
  }

  /// Update time range filter
  Future<void> _onUpdateTimeRange(
    UpdateTimeRange event,
    Emitter<AnalyticsDashboardState> emit,
  ) async {
    if (state.companyId == null) return;

    emit(state.copyWith(
      timeRange: event.timeRange,
      status: AnalyticsDashboardStatus.loading,
    ));

    try {
      // Load time series data for new range
      final timeSeriesData = await _analyticsService.getTimeSeriesData(
        companyId: state.companyId!,
        startDate: event.timeRange.startDate,
        endDate: event.timeRange.endDate,
      );

      emit(state.copyWith(
        status: AnalyticsDashboardStatus.loaded,
        timeSeriesData: timeSeriesData,
        lastUpdated: DateTime.now(),
      ));

    } catch (e) {
      debugPrint('Error updating time range: $e');
      emit(state.copyWith(
        status: AnalyticsDashboardStatus.error,
        errorMessage: 'Fout bij wijzigen van tijdsperiode: ${e.toString()}',
      ));
    }
  }

  /// Update metric filter
  void _onUpdateMetricFilter(
    UpdateMetricFilter event,
    Emitter<AnalyticsDashboardState> emit,
  ) {
    emit(state.copyWith(selectedMetrics: event.metrics));
  }

  /// Update source filter
  void _onUpdateSourceFilter(
    UpdateSourceFilter event,
    Emitter<AnalyticsDashboardState> emit,
  ) {
    emit(state.copyWith(selectedSources: event.sources));
  }

  /// Load job performance data
  Future<void> _onLoadJobPerformance(
    LoadJobPerformance event,
    Emitter<AnalyticsDashboardState> emit,
  ) async {
    emit(state.copyWith(jobPerformanceLoading: true));

    try {
      final jobPerformance = await _analyticsService.getJobPerformanceAnalytics(event.jobId);
      
      emit(state.copyWith(
        jobPerformanceLoading: false,
        jobPerformanceData: jobPerformance,
      ));

    } catch (e) {
      debugPrint('Error loading job performance: $e');
      emit(state.copyWith(
        jobPerformanceLoading: false,
        errorMessage: 'Fout bij laden van job prestaties: ${e.toString()}',
      ));
    }
  }

  /// Load funnel insights
  Future<void> _onLoadFunnelInsights(
    LoadFunnelInsights event,
    Emitter<AnalyticsDashboardState> emit,
  ) async {
    if (state.companyId == null) return;

    emit(state.copyWith(funnelInsightsLoading: true));

    try {
      final funnelInsights = await _analyticsService.getRecruitmentFunnelInsights(state.companyId!);
      
      emit(state.copyWith(
        funnelInsightsLoading: false,
        funnelInsightsData: funnelInsights,
      ));

    } catch (e) {
      debugPrint('Error loading funnel insights: $e');
      emit(state.copyWith(
        funnelInsightsLoading: false,
        errorMessage: 'Fout bij laden van funnel inzichten: ${e.toString()}',
      ));
    }
  }

  /// Load source analysis
  Future<void> _onLoadSourceAnalysis(
    LoadSourceAnalysis event,
    Emitter<AnalyticsDashboardState> emit,
  ) async {
    if (state.companyId == null) return;

    emit(state.copyWith(sourceAnalysisLoading: true));

    try {
      final sourceAnalysis = await _analyticsService.getSourceEffectivenessAnalysis(state.companyId!);
      
      emit(state.copyWith(
        sourceAnalysisLoading: false,
        sourceAnalysisData: sourceAnalysis,
      ));

    } catch (e) {
      debugPrint('Error loading source analysis: $e');
      emit(state.copyWith(
        sourceAnalysisLoading: false,
        errorMessage: 'Fout bij laden van bron analyse: ${e.toString()}',
      ));
    }
  }

  /// Trigger manual aggregation
  Future<void> _onTriggerAggregation(
    TriggerAggregation event,
    Emitter<AnalyticsDashboardState> emit,
  ) async {
    if (state.companyId == null) return;

    emit(state.copyWith(aggregationInProgress: true));

    try {
      await _analyticsService.triggerAggregation(
        companyId: state.companyId!,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      // Refresh dashboard data after aggregation
      add(RefreshDashboardData());

      emit(state.copyWith(
        aggregationInProgress: false,
        lastAggregation: DateTime.now(),
      ));

    } catch (e) {
      debugPrint('Error triggering aggregation: $e');
      emit(state.copyWith(
        aggregationInProgress: false,
        errorMessage: 'Fout bij data aggregatie: ${e.toString()}',
      ));
    }
  }

  /// Clear cache
  void _onClearCache(
    ClearCache event,
    Emitter<AnalyticsDashboardState> emit,
  ) {
    _analyticsService.clearAllCaches();
    emit(state.copyWith(
      lastUpdated: DateTime.now(),
    ));
  }

  @override
  Future<void> close() {
    _dataSubscription?.cancel();
    return super.close();
  }
}

/// Analytics Dashboard Events
abstract class AnalyticsDashboardEvent extends Equatable {
  const AnalyticsDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends AnalyticsDashboardEvent {
  final String companyId;

  const LoadDashboardData(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class RefreshDashboardData extends AnalyticsDashboardEvent {
  const RefreshDashboardData();
}

class UpdateTimeRange extends AnalyticsDashboardEvent {
  final AnalyticsTimeRange timeRange;

  const UpdateTimeRange(this.timeRange);

  @override
  List<Object> get props => [timeRange];
}

class UpdateMetricFilter extends AnalyticsDashboardEvent {
  final List<String> metrics;

  const UpdateMetricFilter(this.metrics);

  @override
  List<Object> get props => [metrics];
}

class UpdateSourceFilter extends AnalyticsDashboardEvent {
  final List<String> sources;

  const UpdateSourceFilter(this.sources);

  @override
  List<Object> get props => [sources];
}

class LoadJobPerformance extends AnalyticsDashboardEvent {
  final String jobId;

  const LoadJobPerformance(this.jobId);

  @override
  List<Object> get props => [jobId];
}

class LoadFunnelInsights extends AnalyticsDashboardEvent {
  const LoadFunnelInsights();
}

class LoadSourceAnalysis extends AnalyticsDashboardEvent {
  const LoadSourceAnalysis();
}

class TriggerAggregation extends AnalyticsDashboardEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const TriggerAggregation({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class ClearCache extends AnalyticsDashboardEvent {
  const ClearCache();
}

/// Analytics Dashboard State
class AnalyticsDashboardState extends Equatable {
  final AnalyticsDashboardStatus status;
  final String? companyId;
  final Map<String, dynamic>? dashboardData;
  final List<CompanyDailyAnalytics> timeSeriesData;
  final AnalyticsTimeRange timeRange;
  final List<String> selectedMetrics;
  final List<String> selectedSources;
  final Map<String, dynamic>? jobPerformanceData;
  final Map<String, dynamic>? funnelInsightsData;
  final Map<String, dynamic>? sourceAnalysisData;
  final bool jobPerformanceLoading;
  final bool funnelInsightsLoading;
  final bool sourceAnalysisLoading;
  final bool aggregationInProgress;
  final DateTime? lastUpdated;
  final DateTime? lastAggregation;
  final String? errorMessage;

  AnalyticsDashboardState({
    this.status = AnalyticsDashboardStatus.initial,
    this.companyId,
    this.dashboardData,
    this.timeSeriesData = const [],
    AnalyticsTimeRange? timeRange,
    this.selectedMetrics = const ['views', 'applications', 'conversions'],
    this.selectedSources = const [],
    this.jobPerformanceData,
    this.funnelInsightsData,
    this.sourceAnalysisData,
    this.jobPerformanceLoading = false,
    this.funnelInsightsLoading = false,
    this.sourceAnalysisLoading = false,
    this.aggregationInProgress = false,
    this.lastUpdated,
    this.lastAggregation,
    this.errorMessage,
  }) : timeRange = timeRange ?? AnalyticsTimeRange.lastWeek();

  AnalyticsDashboardState copyWith({
    AnalyticsDashboardStatus? status,
    String? companyId,
    Map<String, dynamic>? dashboardData,
    List<CompanyDailyAnalytics>? timeSeriesData,
    AnalyticsTimeRange? timeRange,
    List<String>? selectedMetrics,
    List<String>? selectedSources,
    Map<String, dynamic>? jobPerformanceData,
    Map<String, dynamic>? funnelInsightsData,
    Map<String, dynamic>? sourceAnalysisData,
    bool? jobPerformanceLoading,
    bool? funnelInsightsLoading,
    bool? sourceAnalysisLoading,
    bool? aggregationInProgress,
    DateTime? lastUpdated,
    DateTime? lastAggregation,
    String? errorMessage,
  }) {
    return AnalyticsDashboardState(
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      dashboardData: dashboardData ?? this.dashboardData,
      timeSeriesData: timeSeriesData ?? this.timeSeriesData,
      timeRange: timeRange ?? this.timeRange,
      selectedMetrics: selectedMetrics ?? this.selectedMetrics,
      selectedSources: selectedSources ?? this.selectedSources,
      jobPerformanceData: jobPerformanceData ?? this.jobPerformanceData,
      funnelInsightsData: funnelInsightsData ?? this.funnelInsightsData,
      sourceAnalysisData: sourceAnalysisData ?? this.sourceAnalysisData,
      jobPerformanceLoading: jobPerformanceLoading ?? this.jobPerformanceLoading,
      funnelInsightsLoading: funnelInsightsLoading ?? this.funnelInsightsLoading,
      sourceAnalysisLoading: sourceAnalysisLoading ?? this.sourceAnalysisLoading,
      aggregationInProgress: aggregationInProgress ?? this.aggregationInProgress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastAggregation: lastAggregation ?? this.lastAggregation,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    companyId,
    dashboardData,
    timeSeriesData,
    timeRange,
    selectedMetrics,
    selectedSources,
    jobPerformanceData,
    funnelInsightsData,
    sourceAnalysisData,
    jobPerformanceLoading,
    funnelInsightsLoading,
    sourceAnalysisLoading,
    aggregationInProgress,
    lastUpdated,
    lastAggregation,
    errorMessage,
  ];

  /// Check if dashboard has data
  bool get hasData => dashboardData != null && dashboardData!.isNotEmpty;

  /// Check if any loading is in progress
  bool get isLoading => status == AnalyticsDashboardStatus.loading ||
                       jobPerformanceLoading ||
                       funnelInsightsLoading ||
                       sourceAnalysisLoading ||
                       aggregationInProgress;

  /// Check if data is stale (older than 15 minutes)
  bool get isDataStale {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!).inMinutes > 15;
  }

  /// Get today's metrics from dashboard data
  Map<String, dynamic>? get todayMetrics => dashboardData?['today'];

  /// Get week summary from dashboard data
  Map<String, dynamic>? get weekSummary => dashboardData?['week'];

  /// Get performance indicators from dashboard data
  Map<String, dynamic>? get performanceIndicators => dashboardData?['performance'];

  /// Get filtered time series data based on selected metrics
  List<Map<String, dynamic>> get filteredTimeSeriesData {
    if (timeSeriesData.isEmpty) return [];

    return timeSeriesData.map((analytics) {
      final data = <String, dynamic>{
        'date': analytics.date,
      };

      if (selectedMetrics.contains('views')) {
        data['views'] = analytics.jobViews;
      }
      if (selectedMetrics.contains('applications')) {
        data['applications'] = analytics.totalApplications;
      }
      if (selectedMetrics.contains('conversions')) {
        data['conversionRate'] = analytics.viewToApplicationRate;
      }
      if (selectedMetrics.contains('spend')) {
        data['spend'] = analytics.totalRecruitmentSpend;
      }

      return data;
    }).toList();
  }
}

/// Analytics Dashboard Status
enum AnalyticsDashboardStatus {
  initial,
  loading,
  loaded,
  refreshing,
  error,
}

/// Analytics Time Range
class AnalyticsTimeRange extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  const AnalyticsTimeRange({
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  /// Last week time range
  factory AnalyticsTimeRange.lastWeek() {
    final now = DateTime.now();
    return AnalyticsTimeRange(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
      label: 'Afgelopen week',
    );
  }

  /// Last month time range
  factory AnalyticsTimeRange.lastMonth() {
    final now = DateTime.now();
    return AnalyticsTimeRange(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      label: 'Afgelopen maand',
    );
  }

  /// Last quarter time range
  factory AnalyticsTimeRange.lastQuarter() {
    final now = DateTime.now();
    return AnalyticsTimeRange(
      startDate: now.subtract(const Duration(days: 90)),
      endDate: now,
      label: 'Afgelopen kwartaal',
    );
  }

  /// Custom time range
  factory AnalyticsTimeRange.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return AnalyticsTimeRange(
      startDate: startDate,
      endDate: endDate,
      label: 'Aangepaste periode',
    );
  }

  /// Get duration in days
  int get durationInDays => endDate.difference(startDate).inDays;

  @override
  List<Object> get props => [startDate, endDate, label];

  /// Get predefined ranges
  static final List<AnalyticsTimeRange> predefinedRanges = [
    AnalyticsTimeRange.lastWeek(),
    AnalyticsTimeRange.lastMonth(),
    AnalyticsTimeRange.lastQuarter(),
  ];
}
