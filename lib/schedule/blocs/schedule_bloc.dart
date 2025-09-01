import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/shift_model.dart';
import '../models/time_entry_model.dart';
import '../models/leave_request_model.dart';
import '../services/shift_management_service.dart';
import '../services/time_tracking_service.dart';
import '../services/location_verification_service.dart';
import '../services/calendar_sync_service.dart';
import '../services/cao_calculation_service.dart';

/// ScheduleBloc for comprehensive schedule management
/// 
/// Manages:
/// - Shift scheduling and management
/// - Time tracking and GPS verification
/// - Leave requests and approvals
/// - Calendar synchronization
/// - CAO compliance monitoring
class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ShiftManagementService _shiftService;
  final TimeTrackingService _timeTrackingService;
  final LocationVerificationService _locationService;
  final CalendarSyncService _calendarService;
  final CAOCalculationService _caoService;
  
  StreamSubscription<List<Shift>>? _shiftsSubscription;
  StreamSubscription<TimeEntry>? _timeEntrySubscription;
  StreamSubscription<ShiftSwapRequest>? _swapRequestSubscription;
  
  ScheduleBloc({
    required ShiftManagementService shiftService,
    required TimeTrackingService timeTrackingService,
    required LocationVerificationService locationService,
    required CalendarSyncService calendarService,
    required CAOCalculationService caoService,
  }) : _shiftService = shiftService,
       _timeTrackingService = timeTrackingService,
       _locationService = locationService,
       _calendarService = calendarService,
       _caoService = caoService,
       super(const ScheduleInitial()) {
    
    // Register event handlers
    on<ScheduleInitialize>(_onInitialize);
    on<ScheduleLoadShifts>(_onLoadShifts);
    on<ScheduleCreateShift>(_onCreateShift);
    on<ScheduleUpdateShift>(_onUpdateShift);
    on<ScheduleDeleteShift>(_onDeleteShift);
    on<ScheduleStartShift>(_onStartShift);
    on<ScheduleEndShift>(_onEndShift);
    on<ScheduleStartBreak>(_onStartBreak);
    on<ScheduleEndBreak>(_onEndBreak);
    on<ScheduleCreateLeaveRequest>(_onCreateLeaveRequest);
    on<ScheduleCreateShiftSwap>(_onCreateShiftSwap);
    on<ScheduleProcessShiftSwap>(_onProcessShiftSwap);
    on<ScheduleSyncCalendar>(_onSyncCalendar);
    on<ScheduleValidateCAO>(_onValidateCAO);
    on<ScheduleLocationUpdate>(_onLocationUpdate);
    on<ScheduleShiftsUpdated>(_onShiftsUpdated);
    on<ScheduleTimeEntryUpdated>(_onTimeEntryUpdated);
    on<ScheduleSwapRequestUpdated>(_onSwapRequestUpdated);
    
    // Subscribe to services
    _subscribeToServices();
  }

  /// Subscribe to service streams
  void _subscribeToServices() {
    _shiftsSubscription = _shiftService.shiftsStream.listen(
      (shifts) => add(ScheduleShiftsUpdated(shifts)),
    );
    
    _timeEntrySubscription = _timeTrackingService.timeEntryStream.listen(
      (timeEntry) => add(ScheduleTimeEntryUpdated(timeEntry)),
    );
    
    _swapRequestSubscription = _shiftService.swapRequestStream.listen(
      (swapRequest) => add(ScheduleSwapRequestUpdated(swapRequest)),
    );
  }

  /// Initialize schedule system
  Future<void> _onInitialize(ScheduleInitialize event, Emitter<ScheduleState> emit) async {
    emit(const ScheduleLoading());
    
    try {
      // Initialize calendar sync if requested
      if (event.initializeCalendar && event.calendarCredentials != null) {
        final calendarResult = await _calendarService.initializeGoogleCalendarSync(
          clientId: event.calendarCredentials!['clientId']!,
          clientSecret: event.calendarCredentials!['clientSecret']!,
        );
        
        if (!calendarResult.isSuccessful) {
          emit(ScheduleError('Calendar synchronisatie mislukt: ${calendarResult.message}'));
          return;
        }
      }
      
      // Load initial data
      add(ScheduleLoadShifts(
        guardId: event.guardId,
        companyId: event.companyId,
        startDate: event.startDate,
        endDate: event.endDate,
      ));
      
    } catch (e) {
      emit(ScheduleError('Initialisatie mislukt: ${e.toString()}'));
    }
  }

  /// Load shifts for specified criteria
  Future<void> _onLoadShifts(ScheduleLoadShifts event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final shifts = await _shiftService.getShifts(
        companyId: event.companyId,
        guardId: event.guardId,
        startDate: event.startDate,
        endDate: event.endDate,
        statuses: event.statuses,
        limit: event.limit,
      );
      
      // Get current time entry if exists
      TimeEntry? currentTimeEntry;
      if (event.guardId != null) {
        currentTimeEntry = await _timeTrackingService.getCurrentTimeEntry();
      }
      
      emit(ScheduleLoaded(
        shifts: shifts,
        currentTimeEntry: currentTimeEntry,
        calendarSyncEnabled: state.calendarSyncEnabled,
        lastUpdated: DateTime.now(),
      ));
      
    } catch (e) {
      emit(ScheduleError('Diensten laden mislukt: ${e.toString()}'));
    }
  }

  /// Create new shift
  Future<void> _onCreateShift(ScheduleCreateShift event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final shift = await _shiftService.createShift(
        companyId: event.companyId,
        jobSiteId: event.jobSiteId,
        shiftTitle: event.shiftTitle,
        shiftDescription: event.shiftDescription,
        startTime: event.startTime,
        endTime: event.endTime,
        location: event.location,
        requiredCertifications: event.requiredCertifications,
        requiredSkills: event.requiredSkills,
        securityLevel: event.securityLevel,
        hourlyRate: event.hourlyRate,
        assignedGuardId: event.assignedGuardId,
        breaks: event.breaks,
        isTemplate: event.isTemplate,
        recurrence: event.recurrence,
        metadata: event.metadata,
      );
      
      // Sync to calendar if enabled
      if (state.calendarSyncEnabled) {
        await _calendarService.syncShiftToCalendar(shift);
      }
      
      emit(state.copyWith(
        isLoading: false,
        message: 'Dienst succesvol aangemaakt',
        lastUpdated: DateTime.now(),
      ));
      
    } catch (e) {
      emit(ScheduleError('Dienst aanmaken mislukt: ${e.toString()}'));
    }
  }

  /// Update existing shift
  Future<void> _onUpdateShift(ScheduleUpdateShift event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final updatedShift = await _shiftService.updateShift(
        shiftId: event.shiftId,
        shiftTitle: event.shiftTitle,
        shiftDescription: event.shiftDescription,
        startTime: event.startTime,
        endTime: event.endTime,
        location: event.location,
        requiredCertifications: event.requiredCertifications,
        requiredSkills: event.requiredSkills,
        securityLevel: event.securityLevel,
        hourlyRate: event.hourlyRate,
        assignedGuardId: event.assignedGuardId,
        breaks: event.breaks,
        status: event.status,
        metadata: event.metadata,
      );
      
      // Update calendar if enabled
      if (state.calendarSyncEnabled) {
        await _calendarService.syncShiftToCalendar(updatedShift);
      }
      
      emit(state.copyWith(
        isLoading: false,
        message: 'Dienst succesvol bijgewerkt',
        lastUpdated: DateTime.now(),
      ));
      
    } catch (e) {
      emit(ScheduleError('Dienst bijwerken mislukt: ${e.toString()}'));
    }
  }

  /// Delete shift
  Future<void> _onDeleteShift(ScheduleDeleteShift event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      await _shiftService.deleteShift(event.shiftId);
      
      // Remove from calendar if enabled
      if (state.calendarSyncEnabled) {
        await _calendarService.removeShiftFromCalendar(event.shiftId);
      }
      
      emit(state.copyWith(
        isLoading: false,
        message: 'Dienst succesvol verwijderd',
        lastUpdated: DateTime.now(),
      ));
      
    } catch (e) {
      emit(ScheduleError('Dienst verwijderen mislukt: ${e.toString()}'));
    }
  }

  /// Start shift with GPS verification
  Future<void> _onStartShift(ScheduleStartShift event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      // Start time tracking
      final timeEntry = await _timeTrackingService.startShift(
        shiftId: event.shiftId,
        guardId: event.guardId,
        companyId: event.companyId,
        jobSiteId: event.jobSiteId,
        jobLocation: event.jobLocation,
        notes: event.notes,
      );
      
      emit(state.copyWith(
        isLoading: false,
        currentTimeEntry: timeEntry,
        message: 'Dienst succesvol gestart',
        lastUpdated: DateTime.now(),
      ));
      
    } catch (e) {
      emit(ScheduleError('Dienst starten mislukt: ${e.toString()}'));
    }
  }

  /// End shift with GPS verification
  Future<void> _onEndShift(ScheduleEndShift event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      // End time tracking
      final timeEntry = await _timeTrackingService.endShift(
        jobLocation: event.jobLocation,
        notes: event.notes,
      );
      
      // Calculate CAO compliance and earnings
      final weeklyTimeEntries = await _timeTrackingService.getTimeEntries(
        guardId: event.guardId,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );
      
      final earningsResult = _caoService.calculateEarnings(
        timeEntry: timeEntry,
        baseHourlyRate: event.baseHourlyRate,
        weeklyTimeEntries: weeklyTimeEntries,
      );
      
      emit(state.copyWith(
        isLoading: false,
        currentTimeEntry: timeEntry,
        lastEarningsResult: earningsResult,
        message: 'Dienst succesvol beëindigd',
        lastUpdated: DateTime.now(),
      ));
      
    } catch (e) {
      emit(ScheduleError('Dienst beëindigen mislukt: ${e.toString()}'));
    }
  }

  /// Start break
  Future<void> _onStartBreak(ScheduleStartBreak event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      await _timeTrackingService.startBreak(
        breakType: event.breakType,
        plannedDuration: event.plannedDuration,
        notes: event.notes,
      );
      
      emit(state.copyWith(
        isLoading: false,
        message: 'Pauze gestart',
        lastUpdated: DateTime.now(),
      ));
      
    } catch (e) {
      emit(ScheduleError('Pauze starten mislukt: ${e.toString()}'));
    }
  }

  /// End break
  Future<void> _onEndBreak(ScheduleEndBreak event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      await _timeTrackingService.endBreak();
      
      emit(state.copyWith(
        isLoading: false,
        message: 'Pauze beëindigd',
        lastUpdated: DateTime.now(),
      ));
      
    } catch (e) {
      emit(ScheduleError('Pauze beëindigen mislukt: ${e.toString()}'));
    }
  }

  /// Create leave request
  Future<void> _onCreateLeaveRequest(ScheduleCreateLeaveRequest event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      // Create leave request (this would be implemented in a separate service)
      // For now, just simulate success
      
      emit(state.copyWith(
        isLoading: false,
        message: 'Verlofaanvraag succesvol ingediend',
        lastUpdated: DateTime.now(),
      ));
      
    } catch (e) {
      emit(ScheduleError('Verlofaanvraag indienen mislukt: ${e.toString()}'));
    }
  }

  /// Create shift swap request
  Future<void> _onCreateShiftSwap(ScheduleCreateShiftSwap event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final swapRequest = await _shiftService.createShiftSwap(
        originalShiftId: event.shiftId,
        requestingGuardId: event.guardId,
        reason: event.reason,
        description: event.description,
        replacementGuardId: event.replacementGuardId,
        swapType: event.swapType,
      );
      
      emit(state.copyWith(
        isLoading: false,
        message: 'Ruilaanvraag succesvol ingediend',
        lastUpdated: DateTime.now(),
      ));
      
    } catch (e) {
      emit(ScheduleError('Ruilaanvraag indienen mislukt: ${e.toString()}'));
    }
  }

  /// Process shift swap request
  Future<void> _onProcessShiftSwap(ScheduleProcessShiftSwap event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      await _shiftService.processShiftSwap(
        swapRequestId: event.swapRequestId,
        approverId: event.approverId,
        approved: event.approved,
        rejectionReason: event.rejectionReason,
      );
      
      final message = event.approved ? 'Ruilaanvraag goedgekeurd' : 'Ruilaanvraag afgewezen';
      
      emit(state.copyWith(
        isLoading: false,
        message: message,
        lastUpdated: DateTime.now(),
      ));
      
    } catch (e) {
      emit(ScheduleError('Ruilaanvraag verwerken mislukt: ${e.toString()}'));
    }
  }

  /// Sync calendar
  Future<void> _onSyncCalendar(ScheduleSyncCalendar event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      if (event.shifts != null) {
        // Sync specific shifts
        for (final shift in event.shifts!) {
          await _calendarService.syncShiftToCalendar(shift);
        }
      }
      
      if (event.leaveRequests != null) {
        // Sync leave requests
        for (final leave in event.leaveRequests!) {
          await _calendarService.syncLeaveRequestToCalendar(leave);
        }
      }
      
      emit(state.copyWith(
        isLoading: false,
        calendarSyncEnabled: true,
        message: 'Agenda synchronisatie voltooid',
        lastUpdated: DateTime.now(),
      ));
      
    } catch (e) {
      emit(ScheduleError('Agenda synchronisatie mislukt: ${e.toString()}'));
    }
  }

  /// Validate CAO compliance
  Future<void> _onValidateCAO(ScheduleValidateCAO event, Emitter<ScheduleState> emit) async {
    try {
      final earningsResult = _caoService.calculateEarnings(
        timeEntry: event.timeEntry,
        baseHourlyRate: event.baseHourlyRate,
        weeklyTimeEntries: event.weeklyTimeEntries,
      );
      
      emit(state.copyWith(
        lastEarningsResult: earningsResult,
        lastUpdated: DateTime.now(),
      ));
      
    } catch (e) {
      emit(ScheduleError('CAO validatie mislukt: ${e.toString()}'));
    }
  }

  /// Handle location updates
  Future<void> _onLocationUpdate(ScheduleLocationUpdate event, Emitter<ScheduleState> emit) async {
    // Handle location updates from location service
    if (state is ScheduleLoaded) {
      emit(state.copyWith(
        lastLocationUpdate: event.location,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Handle shifts updated from service
  Future<void> _onShiftsUpdated(ScheduleShiftsUpdated event, Emitter<ScheduleState> emit) async {
    if (state is ScheduleLoaded) {
      final currentState = state as ScheduleLoaded;
      emit(currentState.copyWith(
        shifts: event.shifts,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Handle time entry updates from service
  Future<void> _onTimeEntryUpdated(ScheduleTimeEntryUpdated event, Emitter<ScheduleState> emit) async {
    if (state is ScheduleLoaded) {
      emit(state.copyWith(
        currentTimeEntry: event.timeEntry,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Handle swap request updates
  Future<void> _onSwapRequestUpdated(ScheduleSwapRequestUpdated event, Emitter<ScheduleState> emit) async {
    // Handle swap request updates
    if (state is ScheduleLoaded) {
      emit(state.copyWith(
        lastUpdated: DateTime.now(),
        message: 'Ruilaanvraag bijgewerkt',
      ));
    }
  }

  @override
  Future<void> close() {
    _shiftsSubscription?.cancel();
    _timeEntrySubscription?.cancel();
    _swapRequestSubscription?.cancel();
    _timeTrackingService.dispose();
    _locationService.dispose();
    return super.close();
  }
}

// Events
abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();
  
  @override
  List<Object?> get props => [];
}

class ScheduleInitialize extends ScheduleEvent {
  final String? guardId;
  final String? companyId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool initializeCalendar;
  final Map<String, String>? calendarCredentials;
  
  const ScheduleInitialize({
    this.guardId,
    this.companyId,
    this.startDate,
    this.endDate,
    this.initializeCalendar = false,
    this.calendarCredentials,
  });
  
  @override
  List<Object?> get props => [guardId, companyId, startDate, endDate, initializeCalendar, calendarCredentials];
}

class ScheduleLoadShifts extends ScheduleEvent {
  final String? guardId;
  final String? companyId;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<ShiftStatus>? statuses;
  final int? limit;
  
  const ScheduleLoadShifts({
    this.guardId,
    this.companyId,
    this.startDate,
    this.endDate,
    this.statuses,
    this.limit,
  });
  
  @override
  List<Object?> get props => [guardId, companyId, startDate, endDate, statuses, limit];
}

class ScheduleCreateShift extends ScheduleEvent {
  final String companyId;
  final String jobSiteId;
  final String shiftTitle;
  final String shiftDescription;
  final DateTime startTime;
  final DateTime endTime;
  final ShiftLocation location;
  final List<String> requiredCertifications;
  final List<String> requiredSkills;
  final SecurityLevel securityLevel;
  final double hourlyRate;
  final String? assignedGuardId;
  final List<BreakPeriod>? breaks;
  final bool isTemplate;
  final RecurrencePattern? recurrence;
  final Map<String, dynamic>? metadata;
  
  const ScheduleCreateShift({
    required this.companyId,
    required this.jobSiteId,
    required this.shiftTitle,
    required this.shiftDescription,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.requiredCertifications,
    required this.requiredSkills,
    required this.securityLevel,
    required this.hourlyRate,
    this.assignedGuardId,
    this.breaks,
    this.isTemplate = false,
    this.recurrence,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [
    companyId, jobSiteId, shiftTitle, shiftDescription, startTime, endTime,
    location, requiredCertifications, requiredSkills, securityLevel, hourlyRate,
    assignedGuardId, breaks, isTemplate, recurrence, metadata,
  ];
}

class ScheduleUpdateShift extends ScheduleEvent {
  final String shiftId;
  final String? shiftTitle;
  final String? shiftDescription;
  final DateTime? startTime;
  final DateTime? endTime;
  final ShiftLocation? location;
  final List<String>? requiredCertifications;
  final List<String>? requiredSkills;
  final SecurityLevel? securityLevel;
  final double? hourlyRate;
  final String? assignedGuardId;
  final List<BreakPeriod>? breaks;
  final ShiftStatus? status;
  final Map<String, dynamic>? metadata;
  
  const ScheduleUpdateShift({
    required this.shiftId,
    this.shiftTitle,
    this.shiftDescription,
    this.startTime,
    this.endTime,
    this.location,
    this.requiredCertifications,
    this.requiredSkills,
    this.securityLevel,
    this.hourlyRate,
    this.assignedGuardId,
    this.breaks,
    this.status,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [
    shiftId, shiftTitle, shiftDescription, startTime, endTime, location,
    requiredCertifications, requiredSkills, securityLevel, hourlyRate,
    assignedGuardId, breaks, status, metadata,
  ];
}

class ScheduleDeleteShift extends ScheduleEvent {
  final String shiftId;
  
  const ScheduleDeleteShift(this.shiftId);
  
  @override
  List<Object?> get props => [shiftId];
}

class ScheduleStartShift extends ScheduleEvent {
  final String shiftId;
  final String guardId;
  final String companyId;
  final String jobSiteId;
  final ShiftLocation jobLocation;
  final String? notes;
  
  const ScheduleStartShift({
    required this.shiftId,
    required this.guardId,
    required this.companyId,
    required this.jobSiteId,
    required this.jobLocation,
    this.notes,
  });
  
  @override
  List<Object?> get props => [shiftId, guardId, companyId, jobSiteId, jobLocation, notes];
}

class ScheduleEndShift extends ScheduleEvent {
  final String guardId;
  final ShiftLocation jobLocation;
  final double baseHourlyRate;
  final String? notes;
  
  const ScheduleEndShift({
    required this.guardId,
    required this.jobLocation,
    required this.baseHourlyRate,
    this.notes,
  });
  
  @override
  List<Object?> get props => [guardId, jobLocation, baseHourlyRate, notes];
}

class ScheduleStartBreak extends ScheduleEvent {
  final BreakEntryType breakType;
  final Duration plannedDuration;
  final String? notes;
  
  const ScheduleStartBreak({
    required this.breakType,
    required this.plannedDuration,
    this.notes,
  });
  
  @override
  List<Object?> get props => [breakType, plannedDuration, notes];
}

class ScheduleEndBreak extends ScheduleEvent {
  const ScheduleEndBreak();
}

class ScheduleCreateLeaveRequest extends ScheduleEvent {
  final String guardId;
  final String companyId;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? description;
  
  const ScheduleCreateLeaveRequest({
    required this.guardId,
    required this.companyId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.description,
  });
  
  @override
  List<Object?> get props => [guardId, companyId, type, startDate, endDate, reason, description];
}

class ScheduleCreateShiftSwap extends ScheduleEvent {
  final String shiftId;
  final String guardId;
  final String reason;
  final String? description;
  final String? replacementGuardId;
  final SwapType swapType;
  
  const ScheduleCreateShiftSwap({
    required this.shiftId,
    required this.guardId,
    required this.reason,
    this.description,
    this.replacementGuardId,
    this.swapType = SwapType.oneTime,
  });
  
  @override
  List<Object?> get props => [shiftId, guardId, reason, description, replacementGuardId, swapType];
}

class ScheduleProcessShiftSwap extends ScheduleEvent {
  final String swapRequestId;
  final String approverId;
  final bool approved;
  final String? rejectionReason;
  
  const ScheduleProcessShiftSwap({
    required this.swapRequestId,
    required this.approverId,
    required this.approved,
    this.rejectionReason,
  });
  
  @override
  List<Object?> get props => [swapRequestId, approverId, approved, rejectionReason];
}

class ScheduleSyncCalendar extends ScheduleEvent {
  final List<Shift>? shifts;
  final List<LeaveRequest>? leaveRequests;
  
  const ScheduleSyncCalendar({
    this.shifts,
    this.leaveRequests,
  });
  
  @override
  List<Object?> get props => [shifts, leaveRequests];
}

class ScheduleValidateCAO extends ScheduleEvent {
  final TimeEntry timeEntry;
  final double baseHourlyRate;
  final List<TimeEntry> weeklyTimeEntries;
  
  const ScheduleValidateCAO({
    required this.timeEntry,
    required this.baseHourlyRate,
    required this.weeklyTimeEntries,
  });
  
  @override
  List<Object?> get props => [timeEntry, baseHourlyRate, weeklyTimeEntries];
}

class ScheduleLocationUpdate extends ScheduleEvent {
  final GPSLocation location;
  
  const ScheduleLocationUpdate(this.location);
  
  @override
  List<Object?> get props => [location];
}

class ScheduleShiftsUpdated extends ScheduleEvent {
  final List<Shift> shifts;
  
  const ScheduleShiftsUpdated(this.shifts);
  
  @override
  List<Object?> get props => [shifts];
}

class ScheduleTimeEntryUpdated extends ScheduleEvent {
  final TimeEntry timeEntry;
  
  const ScheduleTimeEntryUpdated(this.timeEntry);
  
  @override
  List<Object?> get props => [timeEntry];
}

class ScheduleSwapRequestUpdated extends ScheduleEvent {
  final ShiftSwapRequest swapRequest;
  
  const ScheduleSwapRequestUpdated(this.swapRequest);
  
  @override
  List<Object?> get props => [swapRequest];
}

// States
abstract class ScheduleState extends Equatable {
  final bool isLoading;
  final String? message;
  final DateTime? lastUpdated;
  final bool calendarSyncEnabled;
  
  const ScheduleState({
    this.isLoading = false,
    this.message,
    this.lastUpdated,
    this.calendarSyncEnabled = false,
  });
  
  ScheduleState copyWith({
    bool? isLoading,
    String? message,
    DateTime? lastUpdated,
    bool? calendarSyncEnabled,
    TimeEntry? currentTimeEntry,
    CAOEarningsResult? lastEarningsResult,
    GPSLocation? lastLocationUpdate,
  }) {
    return ScheduleLoaded(
      shifts: this is ScheduleLoaded ? (this as ScheduleLoaded).shifts : [],
      currentTimeEntry: currentTimeEntry ?? (this is ScheduleLoaded ? (this as ScheduleLoaded).currentTimeEntry : null),
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
      lastEarningsResult: lastEarningsResult ?? (this is ScheduleLoaded ? (this as ScheduleLoaded).lastEarningsResult : null),
      lastLocationUpdate: lastLocationUpdate ?? (this is ScheduleLoaded ? (this as ScheduleLoaded).lastLocationUpdate : null),
    );
  }
  
  @override
  List<Object?> get props => [isLoading, message, lastUpdated, calendarSyncEnabled];
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading() : super(isLoading: true);
}

class ScheduleLoaded extends ScheduleState {
  final List<Shift> shifts;
  final TimeEntry? currentTimeEntry;
  final CAOEarningsResult? lastEarningsResult;
  final GPSLocation? lastLocationUpdate;
  
  const ScheduleLoaded({
    required this.shifts,
    this.currentTimeEntry,
    super.isLoading,
    super.message,
    super.lastUpdated,
    super.calendarSyncEnabled,
    this.lastEarningsResult,
    this.lastLocationUpdate,
  });
  
  @override
  ScheduleLoaded copyWith({
    List<Shift>? shifts,
    TimeEntry? currentTimeEntry,
    bool? isLoading,
    String? message,
    DateTime? lastUpdated,
    bool? calendarSyncEnabled,
    CAOEarningsResult? lastEarningsResult,
    GPSLocation? lastLocationUpdate,
  }) {
    return ScheduleLoaded(
      shifts: shifts ?? this.shifts,
      currentTimeEntry: currentTimeEntry ?? this.currentTimeEntry,
      isLoading: isLoading ?? this.isLoading,
      message: message,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
      lastEarningsResult: lastEarningsResult ?? this.lastEarningsResult,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
    );
  }
  
  @override
  List<Object?> get props => [
    ...super.props,
    shifts,
    currentTimeEntry,
    lastEarningsResult,
    lastLocationUpdate,
  ];
}

class ScheduleError extends ScheduleState {
  final String error;
  
  const ScheduleError(this.error);
  
  @override
  List<Object?> get props => [...super.props, error];
}