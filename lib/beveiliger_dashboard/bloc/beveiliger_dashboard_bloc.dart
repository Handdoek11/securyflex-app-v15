import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'beveiliger_dashboard_event.dart';
import 'beveiliger_dashboard_state.dart';
import '../services/enhanced_earnings_service.dart';
import '../services/enhanced_shift_service.dart';
import '../services/compliance_monitoring_service.dart';
import '../services/weather_integration_service.dart';
import '../services/performance_analytics_service.dart';
import '../models/enhanced_dashboard_data.dart';
import '../models/compliance_status.dart';
import '../models/weather_data.dart';
import '../models/performance_analytics.dart';

/// Enhanced BLoC for Beveiliger Dashboard with comprehensive real-time features
/// 
/// Features:
/// - Real-time earnings tracking with Dutch formatting (€1.234,56)
/// - Live earnings counter during active shifts
/// - CAO arbeidsrecht compliance monitoring
/// - Weather integration for outdoor shifts
/// - Performance analytics with trend visualization
/// - Dutch business logic (BTW, vakantiegeld, overtime calculations)
class BeveiligerDashboardBloc extends Bloc<BeveiligerDashboardEvent, BeveiligerDashboardState> {
  final EnhancedEarningsService _earningsService;
  final EnhancedShiftService _shiftService;
  final ComplianceMonitoringService _complianceService;
  final WeatherIntegrationService _weatherService;
  final PerformanceAnalyticsService _analyticsService;

  // Real-time subscriptions
  StreamSubscription<EnhancedEarningsData>? _earningsSubscription;
  StreamSubscription<List<EnhancedShiftData>>? _shiftsSubscription;
  StreamSubscription<ComplianceStatus>? _complianceSubscription;
  StreamSubscription<WeatherData>? _weatherSubscription;

  // Timers for real-time updates
  Timer? _realTimeEarningsTimer;
  Timer? _complianceCheckTimer;
  
  // Debouncing for stream updates to prevent double loading
  Timer? _earningsDebounceTimer;
  Timer? _shiftsDebounceTimer;
  Timer? _complianceDebounceTimer;
  Timer? _weatherDebounceTimer;
  
  // Loading state management to prevent concurrent operations
  bool _isCurrentlyLoading = false;

  BeveiligerDashboardBloc({
    required EnhancedEarningsService earningsService,
    required EnhancedShiftService shiftService,
    required ComplianceMonitoringService complianceService,
    required WeatherIntegrationService weatherService,
    required PerformanceAnalyticsService analyticsService,
  }) : _earningsService = earningsService,
       _shiftService = shiftService,
       _complianceService = complianceService,
       _weatherService = weatherService,
       _analyticsService = analyticsService,
       super(const BeveiligerDashboardInitial()) {
    
    // Register event handlers
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboardData>(_onRefreshDashboardData);
    on<StartRealTimeEarningsTracking>(_onStartRealTimeEarningsTracking);
    on<StopRealTimeEarningsTracking>(_onStopRealTimeEarningsTracking);
    on<UpdateEarningsData>(_onUpdateEarningsData);
    on<UpdateShiftStatus>(_onUpdateShiftStatus);
    on<UpdateComplianceStatus>(_onUpdateComplianceStatus);
    on<UpdateWeatherData>(_onUpdateWeatherData);
    on<LoadPerformanceAnalytics>(_onLoadPerformanceAnalytics);
    on<HandleEmergencyIncident>(_onHandleEmergencyIncident);
    on<ToggleAvailabilityStatus>(_onToggleAvailabilityStatus);
  }

  /// Load initial dashboard data with comprehensive error handling
  Future<void> _onLoadDashboardData(
    LoadDashboardData event, 
    Emitter<BeveiligerDashboardState> emit,
  ) async {
    // Prevent concurrent loading operations
    if (_isCurrentlyLoading) {
      developer.log('Dashboard already loading, skipping duplicate request', name: 'BeveiligerDashboard');
      return;
    }
    
    _isCurrentlyLoading = true;
    emit(const BeveiligerDashboardLoading());

    try {
      // Load all dashboard data in parallel for optimal performance
      // Get shift data first
      final shiftsData = await _shiftService.getTodaysShifts();
      
      final results = await Future.wait([
        _earningsService.getEnhancedEarningsData(),
        Future.value(shiftsData),
        _complianceService.getCurrentComplianceStatus(shiftsData),
        _weatherService.getCurrentWeatherForShifts(52.3676, 4.9041), // Amsterdam coordinates as default
        _analyticsService.getPerformanceAnalytics(shiftsData, AnalyticsPeriod.week),
      ]);

      final earningsData = results[0] as EnhancedEarningsData;
      final shifts = results[1] as List<EnhancedShiftData>;
      final complianceStatus = results[2] as ComplianceStatus;
      final weatherData = results[3] as WeatherData?;
      final performanceData = results[4] as PerformanceAnalytics;

      // Create comprehensive dashboard data
      final dashboardData = EnhancedDashboardData(
        earnings: earningsData,
        shifts: shifts,
        compliance: complianceStatus,
        weather: weatherData,
        performance: performanceData,
        lastUpdated: DateTime.now(),
      );

      emit(BeveiligerDashboardLoaded(
        data: dashboardData,
        isRealTimeActive: false,
      ));

      // Auto-start real-time tracking if user is currently working
      final hasActiveShift = shiftsData.any((shift) => shift.status == ShiftStatus.inProgress);
      if (hasActiveShift) {
        add(const StartRealTimeEarningsTracking());
      }

      // Start real-time subscriptions for data updates
      _startRealTimeSubscriptions();

    } catch (error, stackTrace) {
      emit(BeveiligerDashboardError(
        message: _getLocalizedErrorMessage(error),
        error: error,
        stackTrace: stackTrace,
      ));
    } finally {
      _isCurrentlyLoading = false;
    }
  }

  /// Refresh dashboard data while maintaining state
  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<BeveiligerDashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is BeveiligerDashboardLoaded) {
      // Prevent concurrent refresh operations
      if (_isCurrentlyLoading) {
        developer.log('Dashboard already loading, skipping refresh request', name: 'BeveiligerDashboard');
        return;
      }
      
      _isCurrentlyLoading = true;
      emit(currentState.copyWith(isRefreshing: true));
      
      try {
        // Refresh data directly without triggering LoadDashboardData to avoid double loading
        final shiftsData = await _shiftService.getTodaysShifts();
        
        final results = await Future.wait([
          _earningsService.getEnhancedEarningsData(),
          Future.value(shiftsData),
          _complianceService.getCurrentComplianceStatus(shiftsData),
          _weatherService.getCurrentWeatherForShifts(52.3676, 4.9041),
          _analyticsService.getPerformanceAnalytics(shiftsData, AnalyticsPeriod.week),
        ]);

        final earningsData = results[0] as EnhancedEarningsData;
        final shifts = results[1] as List<EnhancedShiftData>;
        final complianceStatus = results[2] as ComplianceStatus;
        final weatherData = results[3] as WeatherData?;
        final performanceData = results[4] as PerformanceAnalytics;

        final refreshedData = EnhancedDashboardData(
          earnings: earningsData,
          shifts: shifts,
          compliance: complianceStatus,
          weather: weatherData,
          performance: performanceData,
          lastUpdated: DateTime.now(),
        );

        emit(currentState.copyWith(
          data: refreshedData,
          isRefreshing: false,
          error: null,
        ));

      } catch (error) {
        emit(currentState.copyWith(
          isRefreshing: false,
          error: _getLocalizedErrorMessage(error),
        ));
      } finally {
        _isCurrentlyLoading = false;
      }
    } else {
      // If not loaded, perform initial load
      add(const LoadDashboardData());
    }
  }

  /// Start real-time earnings tracking during active shifts
  Future<void> _onStartRealTimeEarningsTracking(
    StartRealTimeEarningsTracking event,
    Emitter<BeveiligerDashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is BeveiligerDashboardLoaded) {
      // Update state to show real-time tracking is active
      emit(currentState.copyWith(isRealTimeActive: true));

      // Start real-time earnings timer (updates every 30 seconds)
      _realTimeEarningsTimer?.cancel();
      _realTimeEarningsTimer = Timer.periodic(
        const Duration(seconds: 30),
        (timer) => add(const UpdateEarningsData()),
      );

      // Start compliance monitoring (checks every 5 minutes)
      _complianceCheckTimer?.cancel();
      _complianceCheckTimer = Timer.periodic(
        const Duration(minutes: 5),
        (timer) => add(const UpdateComplianceStatus()),
      );
    }
  }

  /// Stop real-time earnings tracking
  Future<void> _onStopRealTimeEarningsTracking(
    StopRealTimeEarningsTracking event,
    Emitter<BeveiligerDashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is BeveiligerDashboardLoaded) {
      emit(currentState.copyWith(isRealTimeActive: false));

      // Cancel timers
      _realTimeEarningsTimer?.cancel();
      _complianceCheckTimer?.cancel();
    }
  }

  /// Update earnings data with real-time calculations
  Future<void> _onUpdateEarningsData(
    UpdateEarningsData event,
    Emitter<BeveiligerDashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is BeveiligerDashboardLoaded) {
      try {
        final updatedEarnings = await _earningsService.getEnhancedEarningsData();
        
        final updatedData = currentState.data.copyWith(
          earnings: updatedEarnings,
          lastUpdated: DateTime.now(),
        );

        emit(currentState.copyWith(data: updatedData));
      } catch (error) {
        // Don't emit error state for real-time updates, just log
        developer.log('Error updating earnings data: $error', name: 'BeveiligerDashboard', level: 1000);
      }
    }
  }

  /// Update shift status and trigger related calculations
  Future<void> _onUpdateShiftStatus(
    UpdateShiftStatus event,
    Emitter<BeveiligerDashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is BeveiligerDashboardLoaded) {
      try {
        // Update shift status
        await _shiftService.updateShiftStatus(event.shiftId, event.newStatus);
        
        // Get updated shifts data
        final updatedShifts = await _shiftService.getTodaysShifts();
        
        // Recalculate earnings based on new shift status
        final updatedEarnings = await _earningsService.getEnhancedEarningsData();
        
        final updatedData = currentState.data.copyWith(
          shifts: updatedShifts,
          earnings: updatedEarnings,
          lastUpdated: DateTime.now(),
        );

        emit(currentState.copyWith(data: updatedData));

        // Auto-start/stop real-time tracking based on active shifts
        final hasActiveShift = updatedShifts.any((shift) => shift.status == ShiftStatus.inProgress);
        if (hasActiveShift && !currentState.isRealTimeActive) {
          add(const StartRealTimeEarningsTracking());
        } else if (!hasActiveShift && currentState.isRealTimeActive) {
          add(const StopRealTimeEarningsTracking());
        }

      } catch (error) {
        emit(currentState.copyWith(
          error: 'Fout bij bijwerken van shift status: ${_getLocalizedErrorMessage(error)}',
        ));
      }
    }
  }

  /// Update compliance status with Dutch arbeidsrecht validation
  Future<void> _onUpdateComplianceStatus(
    UpdateComplianceStatus event,
    Emitter<BeveiligerDashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is BeveiligerDashboardLoaded) {
      try {
        final updatedCompliance = await _complianceService.getCurrentComplianceStatus(currentState.data.shifts);
        
        final updatedData = currentState.data.copyWith(
          compliance: updatedCompliance,
          lastUpdated: DateTime.now(),
        );

        emit(currentState.copyWith(data: updatedData));

        // Emit compliance alerts if needed
        if (updatedCompliance.hasViolations) {
          emit(BeveiligerDashboardComplianceAlert(
            data: updatedData,
            violations: updatedCompliance.violations,
            isRealTimeActive: currentState.isRealTimeActive,
          ));
        }

      } catch (error) {
        developer.log('Error updating compliance status: $error', name: 'BeveiligerDashboard', level: 1000);
      }
    }
  }

  /// Update weather data for outdoor shifts
  Future<void> _onUpdateWeatherData(
    UpdateWeatherData event,
    Emitter<BeveiligerDashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is BeveiligerDashboardLoaded) {
      try {
        final updatedWeather = await _weatherService.getCurrentWeatherForShifts(52.3676, 4.9041);
        
        final updatedData = currentState.data.copyWith(
          weather: updatedWeather,
          lastUpdated: DateTime.now(),
        );

        emit(currentState.copyWith(data: updatedData));

      } catch (error) {
        developer.log('Error updating weather data: $error', name: 'BeveiligerDashboard', level: 1000);
      }
    }
  }

  /// Load performance analytics with chart data
  Future<void> _onLoadPerformanceAnalytics(
    LoadPerformanceAnalytics event,
    Emitter<BeveiligerDashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is BeveiligerDashboardLoaded) {
      try {
        final analytics = await _analyticsService.getPerformanceAnalytics(
          currentState.data.shifts,
          event.period,
        );
        
        final updatedData = currentState.data.copyWith(
          performance: analytics,
          lastUpdated: DateTime.now(),
        );

        emit(currentState.copyWith(data: updatedData));

      } catch (error) {
        emit(currentState.copyWith(
          error: 'Fout bij laden van prestatie analytics: ${_getLocalizedErrorMessage(error)}',
        ));
      }
    }
  }

  /// Handle emergency incident reporting
  Future<void> _onHandleEmergencyIncident(
    HandleEmergencyIncident event,
    Emitter<BeveiligerDashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is BeveiligerDashboardLoaded) {
      emit(BeveiligerDashboardEmergencyMode(
        data: currentState.data,
        incident: event.incident,
        isRealTimeActive: currentState.isRealTimeActive,
      ));

      try {
        // Process emergency incident
        await _shiftService.reportEmergencyIncident(event.incident);
        
        // Return to normal mode after incident is reported
        emit(currentState.copyWith(
          successMessage: 'Incident succesvol gerapporteerd',
        ));

      } catch (error) {
        emit(currentState.copyWith(
          error: 'Fout bij rapporteren van incident: ${_getLocalizedErrorMessage(error)}',
        ));
      }
    }
  }

  /// Toggle availability status for accepting new shifts
  Future<void> _onToggleAvailabilityStatus(
    ToggleAvailabilityStatus event,
    Emitter<BeveiligerDashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is BeveiligerDashboardLoaded) {
      try {
        await _shiftService.updateAvailabilityStatus(event.isAvailable);
        
        // Update shifts data to reflect availability change
        final updatedShifts = await _shiftService.getTodaysShifts();
        
        final updatedData = currentState.data.copyWith(
          shifts: updatedShifts,
          lastUpdated: DateTime.now(),
        );

        emit(currentState.copyWith(
          data: updatedData,
          successMessage: event.isAvailable 
            ? 'Je bent nu beschikbaar voor nieuwe opdrachten'
            : 'Je bent niet meer beschikbaar voor nieuwe opdrachten',
        ));

      } catch (error) {
        emit(currentState.copyWith(
          error: 'Fout bij bijwerken van beschikbaarheid: ${_getLocalizedErrorMessage(error)}',
        ));
      }
    }
  }

  /// Start real-time subscriptions for data updates with debouncing
  void _startRealTimeSubscriptions() {
    // Earnings updates with debouncing (500ms delay)
    _earningsSubscription?.cancel();
    _earningsSubscription = _earningsService.earningsStream.listen(
      (earnings) {
        _earningsDebounceTimer?.cancel();
        _earningsDebounceTimer = Timer(const Duration(milliseconds: 500), () {
          add(const UpdateEarningsData());
        });
      },
      onError: (error) => developer.log('Earnings stream error: $error', name: 'BeveiligerDashboard', level: 1000),
    );

    // Shift updates with debouncing (1 second delay)
    _shiftsSubscription?.cancel();
    _shiftsSubscription = _shiftService.shiftsStream.listen(
      (shifts) {
        _shiftsDebounceTimer?.cancel();
        _shiftsDebounceTimer = Timer(const Duration(seconds: 1), () {
          // Use a more specific update rather than triggering full shift update
          add(const RefreshDashboardData());
        });
      },
      onError: (error) => developer.log('Shifts stream error: $error', name: 'BeveiligerDashboard', level: 1000),
    );

    // Compliance updates with debouncing (2 second delay)
    _complianceSubscription?.cancel();
    _complianceSubscription = _complianceService.complianceStream.listen(
      (compliance) {
        _complianceDebounceTimer?.cancel();
        _complianceDebounceTimer = Timer(const Duration(seconds: 2), () {
          add(const UpdateComplianceStatus());
        });
      },
      onError: (error) => developer.log('Compliance stream error: $error', name: 'BeveiligerDashboard', level: 1000),
    );

    // Weather updates with longer debouncing (5 second delay)
    _weatherSubscription?.cancel();
    _weatherSubscription = _weatherService.weatherStream.listen(
      (weather) {
        _weatherDebounceTimer?.cancel();
        _weatherDebounceTimer = Timer(const Duration(seconds: 5), () {
          add(const UpdateWeatherData());
        });
      },
      onError: (error) => developer.log('Weather stream error: $error', name: 'BeveiligerDashboard', level: 1000),
    );
  }

  /// Get localized error message for Dutch users
  String _getLocalizedErrorMessage(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Netwerkverbinding probleem. Controleer je internetverbinding.';
    } else if (error.toString().contains('timeout')) {
      return 'Verzoek duurde te lang. Probeer het opnieuw.';
    } else if (error.toString().contains('permission')) {
      return 'Geen toegang tot gevraagde gegevens.';
    } else {
      return 'Er is een onverwachte fout opgetreden. Probeer het later opnieuw.';
    }
  }

  @override
  Future<void> close() {
    // Cancel all subscriptions and timers
    _earningsSubscription?.cancel();
    _shiftsSubscription?.cancel();
    _complianceSubscription?.cancel();
    _weatherSubscription?.cancel();
    _realTimeEarningsTimer?.cancel();
    _complianceCheckTimer?.cancel();
    
    // Cancel debounce timers to prevent memory leaks
    _earningsDebounceTimer?.cancel();
    _shiftsDebounceTimer?.cancel();
    _complianceDebounceTimer?.cancel();
    _weatherDebounceTimer?.cancel();
    
    return super.close();
  }
}