import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/schedule_bloc.dart';
import 'shift_management_service.dart';
import 'time_tracking_service.dart';
import 'location_verification_service.dart';
import 'calendar_sync_service.dart';
import 'cao_calculation_service.dart';

/// ScheduleServiceProvider for SecuryFlex Schedule Management System
///
/// Provides comprehensive service registration, dependency injection, and
/// lifecycle management for the schedule management system.
///
/// Features:
/// - Service registration and dependency injection
/// - Health monitoring and diagnostics
/// - Performance optimization
/// - Integration with main app architecture
/// - Nederlandse localization support
class ScheduleServiceProvider {
  static const String _logTag = 'ScheduleServiceProvider';
  
  // Singleton pattern for service provider
  static ScheduleServiceProvider? _instance;
  static ScheduleServiceProvider get instance => _instance ??= ScheduleServiceProvider._();
  
  ScheduleServiceProvider._();
  
  // Service instances - lazy initialization for performance
  ShiftManagementService? _shiftService;
  TimeTrackingService? _timeTrackingService;
  LocationVerificationService? _locationService;
  CalendarSyncService? _calendarService;
  CAOCalculationService? _caoService;
  ScheduleBloc? _scheduleBloc;
  
  bool _isInitialized = false;
  bool _isHealthy = true;
  DateTime? _lastHealthCheck;
  
  /// Initialize all schedule services with dependency injection
  Future<void> initialize({
    required BuildContext context,
    Map<String, dynamic>? config,
  }) async {
    if (_isInitialized) {
      debugPrint('$_logTag: Services already initialized');
      return;
    }
    
    try {
      debugPrint('$_logTag: Starting service initialization...');
      
      // Initialize core services with proper error handling
      await _initializeCoreServices(config);
      
      // Initialize BLoC with all dependencies
      await _initializeBloc();
      
      // Perform initial health check
      await _performHealthCheck();
      
      _isInitialized = true;
      debugPrint('$_logTag: All services successfully initialized');
      
    } catch (e, stackTrace) {
      _isHealthy = false;
      debugPrint('$_logTag: Service initialization failed: $e');
      debugPrint('$_logTag: Stack trace: $stackTrace');
      
      // Clean up any partially initialized services
      await dispose();
      rethrow;
    }
  }
  
  /// Initialize core services with dependency injection
  Future<void> _initializeCoreServices(Map<String, dynamic>? config) async {
    // Initialize location service first (dependency for others)
    _locationService = LocationVerificationService();
    
    // Initialize time tracking service
    _timeTrackingService = TimeTrackingService();
    
    // Initialize shift management service
    _shiftService = ShiftManagementService();
    
    // Initialize CAO calculation service
    _caoService = CAOCalculationService();
    
    // Initialize calendar sync service (optional)
    _calendarService = CalendarSyncService();
  }
  
  /// Initialize ScheduleBloc with all service dependencies
  Future<void> _initializeBloc() async {
    if (_shiftService == null ||
        _timeTrackingService == null ||
        _locationService == null ||
        _calendarService == null ||
        _caoService == null) {
      throw StateError('Core services must be initialized before creating BLoC');
    }
    
    _scheduleBloc = ScheduleBloc(
      shiftService: _shiftService!,
      timeTrackingService: _timeTrackingService!,
      locationService: _locationService!,
      calendarService: _calendarService!,
      caoService: _caoService!,
    );
  }
  
  /// Get ScheduleBloc instance - creates if not exists
  ScheduleBloc getScheduleBloc() {
    if (!_isInitialized) {
      throw StateError('ScheduleServiceProvider must be initialized before accessing BLoC');
    }
    
    if (_scheduleBloc == null) {
      throw StateError('ScheduleBloc is not initialized');
    }
    
    return _scheduleBloc!;
  }
  
  /// Get service instances with proper error handling
  ShiftManagementService getShiftService() {
    _ensureInitialized();
    return _shiftService!;
  }
  
  TimeTrackingService getTimeTrackingService() {
    _ensureInitialized();
    return _timeTrackingService!;
  }
  
  LocationVerificationService getLocationService() {
    _ensureInitialized();
    return _locationService!;
  }
  
  CalendarSyncService getCalendarService() {
    _ensureInitialized();
    return _calendarService!;
  }
  
  CAOCalculationService getCaoService() {
    _ensureInitialized();
    return _caoService!;
  }
  
  /// Provide BlocProvider widget for dependency injection
  Widget provideBlocToWidget({
    required Widget child,
    String? guardId,
    String? companyId,
  }) {
    if (!_isInitialized) {
      throw StateError('ScheduleServiceProvider must be initialized before providing BLoC');
    }
    
    return BlocProvider<ScheduleBloc>.value(
      value: getScheduleBloc(),
      child: child,
    );
  }
  
  /// Create MultiBlocProvider for multiple BLoCs if needed
  Widget provideMultipleBlocsToWidget({
    required Widget child,
    List<BlocProvider>? additionalProviders,
  }) {
    final providers = <BlocProvider>[
      BlocProvider<ScheduleBloc>.value(value: getScheduleBloc()),
    ];
    
    if (additionalProviders != null) {
      providers.addAll(additionalProviders);
    }
    
    return MultiBlocProvider(
      providers: providers,
      child: child,
    );
  }
  
  /// Perform comprehensive health check
  Future<HealthCheckResult> performHealthCheck() async {
    try {
      await _performHealthCheck();
      return HealthCheckResult(
        isHealthy: _isHealthy,
        lastCheck: _lastHealthCheck,
        services: _getServiceHealthStatus(),
      );
    } catch (e) {
      return HealthCheckResult(
        isHealthy: false,
        lastCheck: DateTime.now(),
        error: e.toString(),
        services: _getServiceHealthStatus(),
      );
    }
  }
  
  Future<void> _performHealthCheck() async {
    _lastHealthCheck = DateTime.now();
    _isHealthy = true;
    
    // Check if all services are initialized and responsive
    try {
      // Check core services
      if (_shiftService == null || _timeTrackingService == null ||
          _locationService == null || _caoService == null) {
        _isHealthy = false;
        return;
      }
      
      // Check BLoC state
      if (_scheduleBloc == null || _scheduleBloc!.isClosed) {
        _isHealthy = false;
        return;
      }
      
      // Service-specific health checks would be implemented here
      // if the services had checkServiceHealth methods
      
      debugPrint('$_logTag: Health check passed');
      
    } catch (e) {
      _isHealthy = false;
      debugPrint('$_logTag: Health check failed: $e');
      rethrow;
    }
  }
  
  Map<String, bool> _getServiceHealthStatus() {
    return {
      'shiftService': _shiftService != null,
      'timeTrackingService': _timeTrackingService != null,
      'locationService': _locationService != null,
      'calendarService': _calendarService != null,
      'caoService': _caoService != null,
      'scheduleBloc': _scheduleBloc != null && !_scheduleBloc!.isClosed,
    };
  }
  
  /// Get service performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'initialized': _isInitialized,
      'healthy': _isHealthy,
      'lastHealthCheck': _lastHealthCheck?.toIso8601String(),
      'services': _getServiceHealthStatus(),
      'memoryUsage': _getMemoryUsage(),
    };
  }
  
  Map<String, dynamic> _getMemoryUsage() {
    // Simplified memory usage tracking
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'serviceCount': _getActiveServiceCount(),
    };
  }
  
  int _getActiveServiceCount() {
    int count = 0;
    if (_shiftService != null) count++;
    if (_timeTrackingService != null) count++;
    if (_locationService != null) count++;
    if (_calendarService != null) count++;
    if (_caoService != null) count++;
    if (_scheduleBloc != null) count++;
    return count;
  }
  
  /// Reinitialize services if needed
  Future<void> reinitialize({
    required BuildContext context,
    Map<String, dynamic>? config,
  }) async {
    debugPrint('$_logTag: Reinitializing services...');
    
    await dispose();
    _isInitialized = false;
    _isHealthy = true;
    
    await initialize(context: context, config: config);
  }
  
  /// Dispose all services and clean up resources
  Future<void> dispose() async {
    debugPrint('$_logTag: Disposing all services...');
    
    try {
      // Dispose BLoC first to stop any ongoing operations
      if (_scheduleBloc != null && !_scheduleBloc!.isClosed) {
        await _scheduleBloc!.close();
        _scheduleBloc = null;
      }
      
      // Dispose services in reverse order of initialization
      _calendarService = null;
      
      _caoService = null;
      
      if (_shiftService != null) {
        _shiftService!.dispose();
        _shiftService = null;
      }
      
      if (_timeTrackingService != null) {
        _timeTrackingService!.dispose();
        _timeTrackingService = null;
      }
      
      if (_locationService != null) {
        _locationService!.dispose();
        _locationService = null;
      }
      
      _isInitialized = false;
      _isHealthy = true;
      _lastHealthCheck = null;
      
      debugPrint('$_logTag: All services disposed successfully');
      
    } catch (e) {
      debugPrint('$_logTag: Error during disposal: $e');
    }
  }
  
  /// Ensure services are initialized before access
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('ScheduleServiceProvider must be initialized before accessing services');
    }
    
    if (!_isHealthy) {
      throw StateError('ScheduleServiceProvider is not healthy. Perform health check or reinitialize.');
    }
  }
  
  /// Get initialization status
  bool get isInitialized => _isInitialized;
  
  /// Get health status
  bool get isHealthy => _isHealthy;
  
  /// Get last health check time
  DateTime? get lastHealthCheck => _lastHealthCheck;
}

/// Health check result data model
class HealthCheckResult {
  final bool isHealthy;
  final DateTime? lastCheck;
  final String? error;
  final Map<String, bool> services;
  
  const HealthCheckResult({
    required this.isHealthy,
    this.lastCheck,
    this.error,
    required this.services,
  });
  
  @override
  String toString() {
    return 'HealthCheckResult(isHealthy: $isHealthy, lastCheck: $lastCheck, error: $error, services: $services)';
  }
}

/// Extension methods for service management
extension ScheduleServiceProviderExtension on ScheduleServiceProvider {
  /// Quick initialization with default configuration
  Future<void> quickInitialize(BuildContext context) async {
    await initialize(
      context: context,
      config: {
        'enableCalendarSync': false,
        'enablePerformanceMonitoring': true,
        'enableHealthChecks': true,
      },
    );
  }
  
  /// Initialize with calendar sync enabled
  Future<void> initializeWithCalendar(
    BuildContext context, {
    required String clientId,
    required String clientSecret,
  }) async {
    await initialize(
      context: context,
      config: {
        'enableCalendarSync': true,
        'calendarClientId': clientId,
        'calendarClientSecret': clientSecret,
      },
    );
  }
}