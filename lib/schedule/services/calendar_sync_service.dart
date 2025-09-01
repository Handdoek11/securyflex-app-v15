import 'dart:async';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/shift_model.dart';
import '../models/leave_request_model.dart';

/// CalendarSyncService for SecuryFlex Google/Apple Calendar integration
/// 
/// Features:
/// - Google Calendar two-way sync
/// - Apple Calendar (iCal) export
/// - Automatic shift reminders
/// - Conflict detection
/// - Leave request calendar blocking
/// - Dutch timezone handling
/// - Privacy-compliant event creation
class CalendarSyncService {
  auth.AuthClient? _authClient;
  calendar.CalendarApi? _calendarApi;
  String? _calendarId;
  
  static const String _calendarName = 'SecuryFlex Diensten';
  static const String _scopeCalendar = calendar.CalendarApi.calendarScope;
  static const Duration _reminderTime = Duration(hours: 1);
  
  CalendarSyncService() {
    tz_data.initializeTimeZones();
  }

  /// Get Amsterdam timezone
  tz.Location get _amsterdamTimezone => tz.getLocation('Europe/Amsterdam');

  /// Convert UTC to Amsterdam time
  tz.TZDateTime _toAmsterdamTime(DateTime utcTime) {
    return tz.TZDateTime.from(utcTime, _amsterdamTimezone);
  }

  /// Initialize calendar sync with Google OAuth
  Future<CalendarSyncResult> initializeGoogleCalendarSync({
    required String clientId,
    required String clientSecret,
    List<String> scopes = const [_scopeCalendar],
  }) async {
    try {
      // Check if already authenticated
      final prefs = await SharedPreferences.getInstance();
      final savedCredentials = prefs.getString('google_calendar_credentials');
      
      if (savedCredentials != null) {
        // Try to restore existing credentials
        try {
          await _restoreCredentials(savedCredentials);
          if (await _testConnection()) {
            return CalendarSyncResult(
              isSuccessful: true,
              message: 'Google Agenda synchronisatie hersteld',
              provider: CalendarProvider.google,
            );
          }
        } catch (e) {
          // Credentials expired, need to re-authenticate
          print('Stored credentials expired: $e');
        }
      }
      
      // Create credentials
      final clientCredentials = auth.ClientId(clientId, clientSecret);
      
      // Authenticate
      _authClient = await auth.clientViaUserConsent(
        clientCredentials,
        scopes,
        _userPrompt,
      );
      
      if (_authClient == null) {
        return CalendarSyncResult(
          isSuccessful: false,
          message: 'Google authenticatie mislukt',
          provider: CalendarProvider.google,
        );
      }
      
      // Initialize Calendar API
      _calendarApi = calendar.CalendarApi(_authClient!);
      
      // Create or find SecuryFlex calendar
      await _setupSecuryFlexCalendar();
      
      // Save credentials
      await _saveCredentials();
      
      return CalendarSyncResult(
        isSuccessful: true,
        message: 'Google Agenda synchronisatie geactiveerd',
        provider: CalendarProvider.google,
        calendarId: _calendarId,
      );
      
    } catch (e) {
      return CalendarSyncResult(
        isSuccessful: false,
        message: 'Google Agenda synchronisatie mislukt: ${e.toString()}',
        provider: CalendarProvider.google,
        error: e.toString(),
      );
    }
  }

  /// Sync shift to Google Calendar
  Future<CalendarSyncResult> syncShiftToCalendar(Shift shift) async {
    if (_calendarApi == null || _calendarId == null) {
      return CalendarSyncResult(
        isSuccessful: false,
        message: 'Calendar niet geïnitialiseerd',
        provider: CalendarProvider.google,
      );
    }
    
    try {
      // Convert times to Amsterdam timezone
      final startTime = _toAmsterdamTime(shift.startTime);
      final endTime = _toAmsterdamTime(shift.endTime);
      
      // Create calendar event
      final event = calendar.Event()
        ..id = 'securyflex_shift_${shift.id}'
        ..summary = shift.shiftTitle
        ..description = _buildShiftDescription(shift)
        ..location = _buildLocationString(shift.location)
        ..start = calendar.EventDateTime()
        ..end = calendar.EventDateTime();
      
      // Set event times
      event.start!.dateTime = startTime;
      event.start!.timeZone = 'Europe/Amsterdam';
      event.end!.dateTime = endTime;
      event.end!.timeZone = 'Europe/Amsterdam';
      
      // Add reminder
      event.reminders = calendar.EventReminders()
        ..useDefault = false
        ..overrides = [
          calendar.EventReminder()
            ..method = 'popup'
            ..minutes = _reminderTime.inMinutes,
          calendar.EventReminder()
            ..method = 'email'
            ..minutes = _reminderTime.inMinutes,
        ];
      
      // Set privacy level
      event.visibility = 'private';
      
      // Add shift-specific metadata
      event.extendedProperties = calendar.EventExtendedProperties()
        ..private = {
          'securyflex_shift_id': shift.id,
          'securyflex_company_id': shift.companyId,
          'securyflex_job_site_id': shift.jobSiteId,
          'securyflex_security_level': shift.securityLevel.toString(),
          'securyflex_hourly_rate': shift.hourlyRate.toString(),
        };
      
      // Create or update event
      try {
        // Try to get existing event first
        final existingEvent = await _calendarApi!.events.get(_calendarId!, event.id!);
        
        // Update existing event
        await _calendarApi!.events.update(existingEvent, _calendarId!, event.id!);
        
        return CalendarSyncResult(
          isSuccessful: true,
          message: 'Dienst bijgewerkt in agenda',
          provider: CalendarProvider.google,
          eventId: event.id,
        );
        
      } catch (e) {
        // Event doesn't exist, create new one
        final createdEvent = await _calendarApi!.events.insert(event, _calendarId!);
        
        return CalendarSyncResult(
          isSuccessful: true,
          message: 'Dienst toegevoegd aan agenda',
          provider: CalendarProvider.google,
          eventId: createdEvent.id,
        );
      }
      
    } catch (e) {
      return CalendarSyncResult(
        isSuccessful: false,
        message: 'Dienst synchronisatie mislukt: ${e.toString()}',
        provider: CalendarProvider.google,
        error: e.toString(),
      );
    }
  }

  /// Remove shift from calendar
  Future<CalendarSyncResult> removeShiftFromCalendar(String shiftId) async {
    if (_calendarApi == null || _calendarId == null) {
      return CalendarSyncResult(
        isSuccessful: false,
        message: 'Calendar niet geïnitialiseerd',
        provider: CalendarProvider.google,
      );
    }
    
    try {
      final eventId = 'securyflex_shift_$shiftId';
      await _calendarApi!.events.delete(_calendarId!, eventId);
      
      return CalendarSyncResult(
        isSuccessful: true,
        message: 'Dienst verwijderd uit agenda',
        provider: CalendarProvider.google,
        eventId: eventId,
      );
      
    } catch (e) {
      return CalendarSyncResult(
        isSuccessful: false,
        message: 'Dienst verwijderen mislukt: ${e.toString()}',
        provider: CalendarProvider.google,
        error: e.toString(),
      );
    }
  }

  /// Sync leave request to calendar
  Future<CalendarSyncResult> syncLeaveRequestToCalendar(LeaveRequest leaveRequest) async {
    if (_calendarApi == null || _calendarId == null) {
      return CalendarSyncResult(
        isSuccessful: false,
        message: 'Calendar niet geïnitialiseerd',
        provider: CalendarProvider.google,
      );
    }
    
    try {
      // Convert times to Amsterdam timezone
      final startTime = _toAmsterdamTime(leaveRequest.startDate);
      final endTime = _toAmsterdamTime(leaveRequest.endDate);
      
      // Create all-day event for leave
      final event = calendar.Event()
        ..id = 'securyflex_leave_${leaveRequest.id}'
        ..summary = _getLeaveTypeName(leaveRequest.type)
        ..description = _buildLeaveDescription(leaveRequest)
        ..start = calendar.EventDateTime()
        ..end = calendar.EventDateTime();
      
      // Set as all-day event
      event.start!.date = DateTime(startTime.year, startTime.month, startTime.day);
      event.end!.date = DateTime(endTime.year, endTime.month, endTime.day + 1); // End date is exclusive
      
      // Set as busy (blocks other events)
      event.transparency = 'opaque';
      event.visibility = 'private';
      
      // Set color based on leave type
      event.colorId = _getLeaveColorId(leaveRequest.type);
      
      // Add leave-specific metadata
      event.extendedProperties = calendar.EventExtendedProperties()
        ..private = {
          'securyflex_leave_id': leaveRequest.id,
          'securyflex_leave_type': leaveRequest.type.toString(),
          'securyflex_guard_id': leaveRequest.guardId,
          'securyflex_company_id': leaveRequest.companyId,
          'securyflex_status': leaveRequest.status.toString(),
        };
      
      // Create or update event
      try {
        final existingEvent = await _calendarApi!.events.get(_calendarId!, event.id!);
        await _calendarApi!.events.update(existingEvent, _calendarId!, event.id!);
        
        return CalendarSyncResult(
          isSuccessful: true,
          message: 'Verlof bijgewerkt in agenda',
          provider: CalendarProvider.google,
          eventId: event.id,
        );
        
      } catch (e) {
        final createdEvent = await _calendarApi!.events.insert(event, _calendarId!);
        
        return CalendarSyncResult(
          isSuccessful: true,
          message: 'Verlof toegevoegd aan agenda',
          provider: CalendarProvider.google,
          eventId: createdEvent.id,
        );
      }
      
    } catch (e) {
      return CalendarSyncResult(
        isSuccessful: false,
        message: 'Verlof synchronisatie mislukt: ${e.toString()}',
        provider: CalendarProvider.google,
        error: e.toString(),
      );
    }
  }

  /// Check for calendar conflicts
  Future<List<CalendarConflict>> checkForConflicts({
    required DateTime startTime,
    required DateTime endTime,
    String? excludeShiftId,
  }) async {
    if (_calendarApi == null || _calendarId == null) {
      return [];
    }
    
    try {
      // Get events in time range
      final events = await _calendarApi!.events.list(
        _calendarId!,
        timeMin: startTime,
        timeMax: endTime,
        singleEvents: true,
        orderBy: 'startTime',
      );
      
      final conflicts = <CalendarConflict>[];
      
      for (final event in events.items ?? []) {
        // Skip if this is the same shift we're checking
        final shiftId = event.extendedProperties?.private?['securyflex_shift_id'];
        if (shiftId == excludeShiftId) continue;
        
        // Check for overlap
        final eventStart = event.start?.dateTime ?? DateTime.parse(event.start!.date.toString());
        final eventEnd = event.end?.dateTime ?? DateTime.parse(event.end!.date.toString());
        
        if (_hasOverlap(startTime, endTime, eventStart, eventEnd)) {
          conflicts.add(CalendarConflict(
            eventId: event.id ?? '',
            eventTitle: event.summary ?? 'Onbekende afspraak',
            eventStart: eventStart,
            eventEnd: eventEnd,
            conflictType: _determineConflictType(event),
            description: event.description,
          ));
        }
      }
      
      return conflicts;
      
    } catch (e) {
      print('Failed to check calendar conflicts: $e');
      return [];
    }
  }

  /// Generate iCal export for shifts
  Future<String> generateICalExport({
    required List<Shift> shifts,
    required String guardName,
  }) async {
    final buffer = StringBuffer();
    
    // iCal header
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//SecuryFlex//SecuryFlex Schedule//NL');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('X-WR-CALNAME:SecuryFlex Diensten - $guardName');
    buffer.writeln('X-WR-TIMEZONE:Europe/Amsterdam');
    
    // Add timezone information
    _addTimezoneInfo(buffer);
    
    // Add shifts as events
    for (final shift in shifts) {
      _addShiftToIcal(buffer, shift);
    }
    
    // iCal footer
    buffer.writeln('END:VCALENDAR');
    
    return buffer.toString();
  }

  /// Add timezone info to iCal
  void _addTimezoneInfo(StringBuffer buffer) {
    buffer.writeln('BEGIN:VTIMEZONE');
    buffer.writeln('TZID:Europe/Amsterdam');
    buffer.writeln('BEGIN:STANDARD');
    buffer.writeln('DTSTART:20231029T030000');
    buffer.writeln('RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10');
    buffer.writeln('TZNAME:CET');
    buffer.writeln('TZOFFSETFROM:+0200');
    buffer.writeln('TZOFFSETTO:+0100');
    buffer.writeln('END:STANDARD');
    buffer.writeln('BEGIN:DAYLIGHT');
    buffer.writeln('DTSTART:20240331T020000');
    buffer.writeln('RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=3');
    buffer.writeln('TZNAME:CEST');
    buffer.writeln('TZOFFSETFROM:+0100');
    buffer.writeln('TZOFFSETTO:+0200');
    buffer.writeln('END:DAYLIGHT');
    buffer.writeln('END:VTIMEZONE');
  }

  /// Add shift to iCal export
  void _addShiftToIcal(StringBuffer buffer, Shift shift) {
    final startTime = _toAmsterdamTime(shift.startTime);
    final endTime = _toAmsterdamTime(shift.endTime);
    final now = DateTime.now().toUtc();
    
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('UID:securyflex-shift-${shift.id}@securyflex.nl');
    buffer.writeln('DTSTAMP:${_formatICalDateTime(now)}');
    buffer.writeln('DTSTART;TZID=Europe/Amsterdam:${_formatICalDateTime(startTime)}');
    buffer.writeln('DTEND;TZID=Europe/Amsterdam:${_formatICalDateTime(endTime)}');
    buffer.writeln('SUMMARY:${_escapeICalText(shift.shiftTitle)}');
    buffer.writeln('DESCRIPTION:${_escapeICalText(_buildShiftDescription(shift))}');
    buffer.writeln('LOCATION:${_escapeICalText(_buildLocationString(shift.location))}');
    buffer.writeln('CLASS:PRIVATE');
    buffer.writeln('STATUS:CONFIRMED');
    
    // Add reminder
    buffer.writeln('BEGIN:VALARM');
    buffer.writeln('ACTION:DISPLAY');
    buffer.writeln('TRIGGER:-PT1H');
    buffer.writeln('DESCRIPTION:SecuryFlex dienst herinnering');
    buffer.writeln('END:VALARM');
    
    buffer.writeln('END:VEVENT');
  }

  /// Format DateTime for iCal
  String _formatICalDateTime(DateTime dateTime) {
    return '${dateTime.toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.')[0]}Z';
  }

  /// Escape text for iCal
  String _escapeICalText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;')
        .replaceAll('\n', '\\n');
  }

  /// Build shift description
  String _buildShiftDescription(Shift shift) {
    final buffer = StringBuffer();
    buffer.writeln('SecuryFlex Beveiligingsdienst');
    buffer.writeln('');
    buffer.writeln('Dienst: ${shift.shiftTitle}');
    buffer.writeln('Beschrijving: ${shift.shiftDescription}');
    buffer.writeln('Beveiligingsniveau: ${_getSecurityLevelName(shift.securityLevel)}');
    buffer.writeln('Uurloon: €${shift.hourlyRate.toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('Vereiste certificaten:');
    for (final cert in shift.requiredCertifications) {
      buffer.writeln('• $cert');
    }
    buffer.writeln('');
    buffer.writeln('Dit is een SecuryFlex dienst.');
    
    return buffer.toString();
  }

  /// Build leave description
  String _buildLeaveDescription(LeaveRequest leave) {
    final buffer = StringBuffer();
    buffer.writeln('${_getLeaveTypeName(leave.type)}');
    buffer.writeln('');
    buffer.writeln('Reden: ${leave.reason}');
    if (leave.description != null && leave.description!.isNotEmpty) {
      buffer.writeln('Beschrijving: ${leave.description}');
    }
    buffer.writeln('Dagen: ${leave.totalDays}');
    buffer.writeln('Status: ${_getLeaveStatusName(leave.status)}');
    
    return buffer.toString();
  }

  /// Build location string
  String _buildLocationString(ShiftLocation location) {
    return '${location.address}, ${location.city} ${location.postalCode}';
  }

  /// Get leave type name in Dutch
  String _getLeaveTypeName(LeaveType type) {
    switch (type) {
      case LeaveType.vacation: return 'Vakantieverlof';
      case LeaveType.sickLeave: return 'Ziekteverlof';
      case LeaveType.maternityLeave: return 'Zwangerschapsverlof';
      case LeaveType.paternityLeave: return 'Vaderschapsverlof';
      case LeaveType.parentalLeave: return 'Ouderschapsverlof';
      case LeaveType.personalLeave: return 'Persoonlijk verlof';
      case LeaveType.bereavementLeave: return 'Rouwverlof';
      case LeaveType.emergencyLeave: return 'Calamiteitenverlof';
      case LeaveType.studyLeave: return 'Studieverlof';
      case LeaveType.unpaidLeave: return 'Onbetaald verlof';
      case LeaveType.compensationLeave: return 'Compensatieverlof';
    }
  }

  /// Get leave status name in Dutch
  String _getLeaveStatusName(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending: return 'In behandeling';
      case LeaveStatus.approved: return 'Goedgekeurd';
      case LeaveStatus.rejected: return 'Afgewezen';
      case LeaveStatus.cancelled: return 'Geannuleerd';
      case LeaveStatus.withdrawn: return 'Ingetrokken';
      case LeaveStatus.expired: return 'Verlopen';
      case LeaveStatus.partiallyApproved: return 'Gedeeltelijk goedgekeurd';
    }
  }

  /// Get security level name in Dutch
  String _getSecurityLevelName(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.basic: return 'Basis beveiliging';
      case SecurityLevel.enhanced: return 'Verhoogde beveiliging';
      case SecurityLevel.critical: return 'Kritieke beveiliging';
      case SecurityLevel.vip: return 'VIP beveiliging';
      case SecurityLevel.event: return 'Evenement beveiliging';
    }
  }

  /// Get leave color ID for Google Calendar
  String _getLeaveColorId(LeaveType type) {
    switch (type) {
      case LeaveType.vacation: return '2'; // Green
      case LeaveType.sickLeave: return '4'; // Red
      case LeaveType.maternityLeave: 
      case LeaveType.paternityLeave: 
      case LeaveType.parentalLeave: return '5'; // Yellow
      case LeaveType.emergencyLeave: return '11'; // Red
      default: return '8'; // Gray
    }
  }

  /// Setup SecuryFlex calendar
  Future<void> _setupSecuryFlexCalendar() async {
    try {
      // Try to find existing SecuryFlex calendar
      final calendarList = await _calendarApi!.calendarList.list();
      
      for (final calendarListEntry in calendarList.items ?? []) {
        if (calendarListEntry.summary == _calendarName) {
          _calendarId = calendarListEntry.id;
          return;
        }
      }
      
      // Create new calendar
      final newCalendar = calendar.Calendar()
        ..summary = _calendarName
        ..description = 'SecuryFlex beveiligingsdiensten en verlofaanvragen'
        ..timeZone = 'Europe/Amsterdam';
      
      final createdCalendar = await _calendarApi!.calendars.insert(newCalendar);
      _calendarId = createdCalendar.id;
      
    } catch (e) {
      print('Failed to setup SecuryFlex calendar: $e');
      throw Exception('Calendar setup mislukt: $e');
    }
  }

  /// Check if two time periods overlap
  bool _hasOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  /// Determine conflict type
  ConflictType _determineConflictType(calendar.Event event) {
    final shiftId = event.extendedProperties?.private?['securyflex_shift_id'];
    final leaveId = event.extendedProperties?.private?['securyflex_leave_id'];
    
    if (shiftId != null) return ConflictType.shift;
    if (leaveId != null) return ConflictType.leave;
    return ConflictType.other;
  }

  /// User prompt for OAuth
  void _userPrompt(String url) {
    print('Open this URL in your browser: $url');
    print('After authorization, the application will continue...');
  }

  /// Test connection to Google Calendar
  Future<bool> _testConnection() async {
    try {
      if (_calendarApi == null) return false;
      await _calendarApi!.calendarList.list();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Save credentials to local storage
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // In a real implementation, you would securely serialize the auth client
      await prefs.setString('google_calendar_credentials', 'encrypted_credentials');
    } catch (e) {
      print('Failed to save credentials: $e');
    }
  }

  /// Restore credentials from local storage
  Future<void> _restoreCredentials(String credentials) async {
    // In a real implementation, you would deserialize and restore the auth client
    throw Exception('Credentials restoration not implemented');
  }

  /// Disconnect calendar sync
  Future<void> disconnect() async {
    _authClient = null;
    _calendarApi = null;
    _calendarId = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('google_calendar_credentials');
  }
}

/// Calendar sync result
class CalendarSyncResult {
  final bool isSuccessful;
  final String message;
  final CalendarProvider provider;
  final String? calendarId;
  final String? eventId;
  final String? error;

  const CalendarSyncResult({
    required this.isSuccessful,
    required this.message,
    required this.provider,
    this.calendarId,
    this.eventId,
    this.error,
  });
}

/// Calendar providers
enum CalendarProvider {
  google,
  apple,
  outlook,
}

/// Calendar conflict
class CalendarConflict {
  final String eventId;
  final String eventTitle;
  final DateTime eventStart;
  final DateTime eventEnd;
  final ConflictType conflictType;
  final String? description;

  const CalendarConflict({
    required this.eventId,
    required this.eventTitle,
    required this.eventStart,
    required this.eventEnd,
    required this.conflictType,
    this.description,
  });
}

/// Conflict types
enum ConflictType {
  shift,
  leave,
  other,
}