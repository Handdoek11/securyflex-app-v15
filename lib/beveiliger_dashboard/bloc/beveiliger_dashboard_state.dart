import 'package:equatable/equatable.dart';
import '../models/enhanced_dashboard_data.dart';
import '../models/compliance_status.dart';
import '../models/emergency_incident.dart';

/// Base class for all Beveiliger Dashboard states
abstract class BeveiligerDashboardState extends Equatable {
  const BeveiligerDashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BeveiligerDashboardInitial extends BeveiligerDashboardState {
  const BeveiligerDashboardInitial();
}

/// Loading state
class BeveiligerDashboardLoading extends BeveiligerDashboardState {
  const BeveiligerDashboardLoading();
}

/// Loaded state with dashboard data
class BeveiligerDashboardLoaded extends BeveiligerDashboardState {
  final EnhancedDashboardData data;
  final bool isRealTimeActive;
  final bool isRefreshing;
  final String? error;
  final String? successMessage;

  const BeveiligerDashboardLoaded({
    required this.data,
    required this.isRealTimeActive,
    this.isRefreshing = false,
    this.error,
    this.successMessage,
  });

  BeveiligerDashboardLoaded copyWith({
    EnhancedDashboardData? data,
    bool? isRealTimeActive,
    bool? isRefreshing,
    String? error,
    String? successMessage,
  }) {
    return BeveiligerDashboardLoaded(
      data: data ?? this.data,
      isRealTimeActive: isRealTimeActive ?? this.isRealTimeActive,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
    data,
    isRealTimeActive,
    isRefreshing,
    error,
    successMessage,
  ];
}

/// Error state
class BeveiligerDashboardError extends BeveiligerDashboardState {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  const BeveiligerDashboardError({
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, error, stackTrace];
}

/// Compliance alert state
class BeveiligerDashboardComplianceAlert extends BeveiligerDashboardState {
  final EnhancedDashboardData data;
  final List<ComplianceViolation> violations;
  final bool isRealTimeActive;

  const BeveiligerDashboardComplianceAlert({
    required this.data,
    required this.violations,
    required this.isRealTimeActive,
  });

  @override
  List<Object> get props => [data, violations, isRealTimeActive];
}

/// Emergency mode state
class BeveiligerDashboardEmergencyMode extends BeveiligerDashboardState {
  final EnhancedDashboardData data;
  final EmergencyIncident incident;
  final bool isRealTimeActive;

  const BeveiligerDashboardEmergencyMode({
    required this.data,
    required this.incident,
    required this.isRealTimeActive,
  });

  @override
  List<Object> get props => [data, incident, isRealTimeActive];
}

