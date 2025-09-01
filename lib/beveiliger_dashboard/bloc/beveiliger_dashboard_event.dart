import 'package:equatable/equatable.dart';
import '../models/enhanced_dashboard_data.dart';
import '../models/emergency_incident.dart';

/// Base class for all BDM (Beveiliger Dashboard) events
abstract class BeveiligerDashboardEvent extends Equatable {
  const BeveiligerDashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Load initial dashboard data
class LoadDashboardData extends BeveiligerDashboardEvent {
  const LoadDashboardData();
}

/// Refresh dashboard data
class RefreshDashboardData extends BeveiligerDashboardEvent {
  const RefreshDashboardData();
}

/// Start real-time earnings tracking during active shifts
class StartRealTimeEarningsTracking extends BeveiligerDashboardEvent {
  const StartRealTimeEarningsTracking();
}

/// Stop real-time earnings tracking
class StopRealTimeEarningsTracking extends BeveiligerDashboardEvent {
  const StopRealTimeEarningsTracking();
}

/// Update earnings data (triggered by real-time updates)
class UpdateEarningsData extends BeveiligerDashboardEvent {
  const UpdateEarningsData();
}

/// Update shift status
class UpdateShiftStatus extends BeveiligerDashboardEvent {
  final String shiftId;
  final ShiftStatus newStatus;

  const UpdateShiftStatus(this.shiftId, this.newStatus);

  @override
  List<Object> get props => [shiftId, newStatus];
}

/// Update compliance status
class UpdateComplianceStatus extends BeveiligerDashboardEvent {
  const UpdateComplianceStatus();
}

/// Update weather data
class UpdateWeatherData extends BeveiligerDashboardEvent {
  const UpdateWeatherData();
}

/// Load performance analytics
class LoadPerformanceAnalytics extends BeveiligerDashboardEvent {
  final AnalyticsPeriod period;

  const LoadPerformanceAnalytics({
    required this.period,
  });

  @override
  List<Object> get props => [period];
}

/// Handle emergency incident
class HandleEmergencyIncident extends BeveiligerDashboardEvent {
  final EmergencyIncident incident;

  const HandleEmergencyIncident({
    required this.incident,
  });

  @override
  List<Object> get props => [incident];
}

/// Toggle availability status
class ToggleAvailabilityStatus extends BeveiligerDashboardEvent {
  final bool isAvailable;

  const ToggleAvailabilityStatus({
    required this.isAvailable,
  });

  @override
  List<Object> get props => [isAvailable];
}


/// Analytics period enum  
enum AnalyticsPeriod {
  day,
  week,
  month,
  quarter,
  year,
}

