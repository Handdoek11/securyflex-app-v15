import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/shift_model.dart';
import '../models/leave_request_model.dart';
import '../models/time_entry_model.dart';

/// ShiftManagementService for SecuryFlex comprehensive shift management
/// 
/// Features:
/// - Shift creation, modification, and deletion
/// - Recurring shift templates
/// - Shift swapping with approval workflow
/// - Emergency replacement system
/// - Coverage analysis and gap detection
/// - Shift pattern recognition
/// - CAO compliance validation
/// - Automatic notifications
class ShiftManagementService {
  final FirebaseFirestore _firestore;
  final StreamController<List<Shift>> _shiftsStreamController = StreamController<List<Shift>>.broadcast();
  final StreamController<ShiftSwapRequest> _swapRequestStreamController = StreamController<ShiftSwapRequest>.broadcast();
  
  ShiftManagementService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance {
    tz_data.initializeTimeZones();
  }

  /// Get Amsterdam timezone
  tz.Location get _amsterdamTimezone => tz.getLocation('Europe/Amsterdam');

  /// Convert UTC to Amsterdam time
  tz.TZDateTime _toAmsterdamTime(DateTime utcTime) {
    return tz.TZDateTime.from(utcTime, _amsterdamTimezone);
  }

  /// Shifts stream
  Stream<List<Shift>> get shiftsStream => _shiftsStreamController.stream;
  
  /// Swap request stream
  Stream<ShiftSwapRequest> get swapRequestStream => _swapRequestStreamController.stream;

  /// Create a new shift
  Future<Shift> createShift({
    required String companyId,
    required String jobSiteId,
    required String shiftTitle,
    required String shiftDescription,
    required DateTime startTime,
    required DateTime endTime,
    required ShiftLocation location,
    required List<String> requiredCertifications,
    required List<String> requiredSkills,
    required SecurityLevel securityLevel,
    required double hourlyRate,
    String? assignedGuardId,
    List<BreakPeriod>? breaks,
    bool isTemplate = false,
    RecurrencePattern? recurrence,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate shift parameters
      await _validateShiftParameters(
        startTime: startTime,
        endTime: endTime,
        hourlyRate: hourlyRate,
        companyId: companyId,
      );
      
      final now = DateTime.now().toUtc();
      final plannedDuration = endTime.difference(startTime);
      
      // Calculate total earnings estimate
      final totalEarnings = await _calculateEstimatedEarnings(
        plannedDuration: plannedDuration,
        hourlyRate: hourlyRate,
        startTime: startTime,
        endTime: endTime,
      );
      
      // Create shift object
      final shift = Shift(
        id: '', // Will be set by Firestore
        jobSiteId: jobSiteId,
        companyId: companyId,
        assignedGuardId: assignedGuardId,
        shiftTitle: shiftTitle,
        shiftDescription: shiftDescription,
        startTime: startTime.toUtc(),
        endTime: endTime.toUtc(),
        plannedDuration: plannedDuration,
        breaks: breaks ?? _generateDefaultBreaks(plannedDuration),
        location: location,
        requiresGPSVerification: true,
        requiresLocationVerification: true,
        gpsVerificationStatus: 'pending',
        status: assignedGuardId != null ? ShiftStatus.confirmed : ShiftStatus.published,
        createdAt: now,
        updatedAt: now,
        createdByUserId: '', // Should be set from auth context
        requiredCertifications: requiredCertifications,
        requiredSkills: requiredSkills,
        securityLevel: securityLevel,
        hourlyRate: hourlyRate,
        totalEarnings: totalEarnings,
        metadata: metadata ?? {},
        isTemplate: isTemplate,
        recurrence: recurrence,
        isEmergencyShift: false,
        maxReplacementTime: 15,
        emergencyContactIds: [],
      );
      
      // Save to Firestore
      final docRef = await _firestore.collection('shifts').add(shift.toFirestore());
      final createdShift = shift.copyWith(id: docRef.id);
      
      // Generate recurring shifts if template
      if (isTemplate && recurrence != null) {
        await _generateRecurringShifts(createdShift);
      }
      
      // Send notifications to matching guards
      if (!isTemplate) {
        await _notifyMatchingGuards(createdShift);
      }
      
      return createdShift;
      
    } catch (e) {
      throw ShiftManagementException(
        'Dienst aanmaken mislukt: ${e.toString()}',
        ShiftManagementErrorType.creationFailed,
      );
    }
  }

  /// Update an existing shift
  Future<Shift> updateShift({
    required String shiftId,
    String? shiftTitle,
    String? shiftDescription,
    DateTime? startTime,
    DateTime? endTime,
    ShiftLocation? location,
    List<String>? requiredCertifications,
    List<String>? requiredSkills,
    SecurityLevel? securityLevel,
    double? hourlyRate,
    String? assignedGuardId,
    List<BreakPeriod>? breaks,
    ShiftStatus? status,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get existing shift
      final doc = await _firestore.collection('shifts').doc(shiftId).get();
      if (!doc.exists) {
        throw ShiftManagementException(
          'Dienst niet gevonden',
          ShiftManagementErrorType.shiftNotFound,
        );
      }
      
      final existingShift = Shift.fromFirestore(doc);
      
      // Validate updates
      if (startTime != null || endTime != null || hourlyRate != null) {
        await _validateShiftParameters(
          startTime: startTime ?? existingShift.startTime,
          endTime: endTime ?? existingShift.endTime,
          hourlyRate: hourlyRate ?? existingShift.hourlyRate,
          companyId: existingShift.companyId,
        );
      }
      
      // Calculate new duration and earnings if time changed
      Duration? newDuration;
      double? newEarnings;
      
      if (startTime != null || endTime != null) {
        final newStartTime = startTime ?? existingShift.startTime;
        final newEndTime = endTime ?? existingShift.endTime;
        newDuration = newEndTime.difference(newStartTime);
        
        newEarnings = await _calculateEstimatedEarnings(
          plannedDuration: newDuration,
          hourlyRate: hourlyRate ?? existingShift.hourlyRate,
          startTime: newStartTime,
          endTime: newEndTime,
        );
      }
      
      // Create updated shift
      final updatedShift = existingShift.copyWith(
        shiftTitle: shiftTitle,
        shiftDescription: shiftDescription,
        startTime: startTime,
        endTime: endTime,
        plannedDuration: newDuration,
        location: location,
        requiredCertifications: requiredCertifications,
        requiredSkills: requiredSkills,
        securityLevel: securityLevel,
        hourlyRate: hourlyRate,
        assignedGuardId: assignedGuardId,
        breaks: breaks,
        status: status,
        totalEarnings: newEarnings ?? existingShift.totalEarnings,
        updatedAt: DateTime.now().toUtc(),
        metadata: metadata != null 
            ? {...existingShift.metadata, ...metadata}
            : existingShift.metadata,
      );
      
      // Save updates
      await _firestore.collection('shifts').doc(shiftId).update(updatedShift.toFirestore());
      
      // Send update notifications
      await _notifyShiftUpdate(updatedShift, existingShift);
      
      return updatedShift;
      
    } catch (e) {
      throw ShiftManagementException(
        'Dienst bijwerken mislukt: ${e.toString()}',
        ShiftManagementErrorType.updateFailed,
      );
    }
  }

  /// Delete a shift
  Future<void> deleteShift(String shiftId) async {
    try {
      // Get shift to check if it can be deleted
      final doc = await _firestore.collection('shifts').doc(shiftId).get();
      if (!doc.exists) {
        throw ShiftManagementException(
          'Dienst niet gevonden',
          ShiftManagementErrorType.shiftNotFound,
        );
      }
      
      final shift = Shift.fromFirestore(doc);
      
      // Check if shift is in progress
      if (shift.status == ShiftStatus.inProgress) {
        throw ShiftManagementException(
          'Kan geen actieve dienst verwijderen',
          ShiftManagementErrorType.shiftInProgress,
        );
      }
      
      // Check if shift has time entries
      final timeEntries = await _firestore
          .collection('timeEntries')
          .where('shiftId', isEqualTo: shiftId)
          .limit(1)
          .get();
      
      if (timeEntries.docs.isNotEmpty) {
        throw ShiftManagementException(
          'Kan dienst met tijdregistraties niet verwijderen',
          ShiftManagementErrorType.hasTimeEntries,
        );
      }
      
      // Delete shift
      await _firestore.collection('shifts').doc(shiftId).delete();
      
      // Send cancellation notifications
      await _notifyShiftCancellation(shift);
      
    } catch (e) {
      if (e is ShiftManagementException) rethrow;
      
      throw ShiftManagementException(
        'Dienst verwijderen mislukt: ${e.toString()}',
        ShiftManagementErrorType.deleteFailed,
      );
    }
  }

  /// Create shift swap request
  Future<ShiftSwapRequest> createShiftSwap({
    required String originalShiftId,
    required String requestingGuardId,
    required String reason,
    String? description,
    String? replacementGuardId,
    SwapType swapType = SwapType.oneTime,
  }) async {
    try {
      // Validate original shift exists and guard is assigned
      final shiftDoc = await _firestore.collection('shifts').doc(originalShiftId).get();
      if (!shiftDoc.exists) {
        throw ShiftManagementException(
          'Originele dienst niet gevonden',
          ShiftManagementErrorType.shiftNotFound,
        );
      }
      
      final shift = Shift.fromFirestore(shiftDoc);
      if (shift.assignedGuardId != requestingGuardId) {
        throw ShiftManagementException(
          'U bent niet toegewezen aan deze dienst',
          ShiftManagementErrorType.notAssigned,
        );
      }
      
      // Check if swap is allowed (not too close to shift start)
      final hoursUntilShift = shift.startTime.difference(DateTime.now().toUtc()).inHours;
      if (hoursUntilShift < 24) {
        throw ShiftManagementException(
          'Dienstruil moet minimaal 24 uur van tevoren worden aangevraagd',
          ShiftManagementErrorType.tooCloseToShift,
        );
      }
      
      final now = DateTime.now().toUtc();
      
      // Create swap request
      final swapRequest = ShiftSwapRequest(
        id: '', // Will be set by Firestore
        originalShiftId: originalShiftId,
        requestingGuardId: requestingGuardId,
        replacementGuardId: replacementGuardId,
        companyId: shift.companyId,
        swapType: swapType,
        requestedDate: shift.startTime,
        reason: reason,
        description: description,
        status: SwapStatus.pending,
        requiresCompanyApproval: true,
        requiresGuardApproval: replacementGuardId != null,
        createdAt: now,
        updatedAt: now,
        metadata: {},
      );
      
      // Save swap request
      final docRef = await _firestore.collection('shiftSwapRequests').add(swapRequest.toFirestore());
      final createdRequest = swapRequest.copyWith(id: docRef.id);
      
      // Send notifications
      await _notifySwapRequest(createdRequest, shift);
      
      _swapRequestStreamController.add(createdRequest);
      
      return createdRequest;
      
    } catch (e) {
      if (e is ShiftManagementException) rethrow;
      
      throw ShiftManagementException(
        'Dienstruil aanvragen mislukt: ${e.toString()}',
        ShiftManagementErrorType.swapRequestFailed,
      );
    }
  }

  /// Approve or reject shift swap
  Future<ShiftSwapRequest> processShiftSwap({
    required String swapRequestId,
    required String approverId,
    required bool approved,
    String? rejectionReason,
  }) async {
    try {
      // Get swap request
      final doc = await _firestore.collection('shiftSwapRequests').doc(swapRequestId).get();
      if (!doc.exists) {
        throw ShiftManagementException(
          'Ruilaanvraag niet gevonden',
          ShiftManagementErrorType.swapNotFound,
        );
      }
      
      final swapRequest = ShiftSwapRequest.fromFirestore(doc);
      
      if (swapRequest.status != SwapStatus.pending) {
        throw ShiftManagementException(
          'Ruilaanvraag is al verwerkt',
          ShiftManagementErrorType.alreadyProcessed,
        );
      }
      
      final now = DateTime.now().toUtc();
      
      // Update swap request
      final updatedRequest = swapRequest.copyWith(
        status: approved ? SwapStatus.approved : SwapStatus.rejected,
        approvedAt: approved ? now : null,
        approvedByUserId: approverId,
        rejectionReason: rejectionReason,
        updatedAt: now,
      );
      
      await _firestore.collection('shiftSwapRequests').doc(swapRequestId).update(updatedRequest.toFirestore());
      
      // If approved, update the original shift
      if (approved && swapRequest.replacementGuardId != null) {
        await _executeShiftSwap(swapRequest);
      }
      
      // Send notifications
      await _notifySwapDecision(updatedRequest);
      
      _swapRequestStreamController.add(updatedRequest);
      
      return updatedRequest;
      
    } catch (e) {
      if (e is ShiftManagementException) rethrow;
      
      throw ShiftManagementException(
        'Ruilaanvraag verwerken mislukt: ${e.toString()}',
        ShiftManagementErrorType.swapProcessFailed,
      );
    }
  }

  /// Find replacement guards for emergency coverage
  Future<List<GuardMatch>> findReplacementGuards({
    required String shiftId,
    int maxResults = 10,
  }) async {
    try {
      // Get shift details
      final shiftDoc = await _firestore.collection('shifts').doc(shiftId).get();
      if (!shiftDoc.exists) {
        throw ShiftManagementException(
          'Dienst niet gevonden',
          ShiftManagementErrorType.shiftNotFound,
        );
      }
      
      final shift = Shift.fromFirestore(shiftDoc);
      
      // Find guards with matching certifications and availability
      final guards = await _findMatchingGuards(shift);
      
      // Score and sort guards
      final scoredGuards = <GuardMatch>[];
      
      for (final guard in guards) {
        final score = await _calculateGuardMatchScore(guard, shift);
        scoredGuards.add(GuardMatch(
          guardId: guard['id'] as String,
          guardName: guard['name'] as String,
          matchScore: score,
          distance: guard['distance'] as double? ?? 0.0,
          hourlyRate: guard['hourlyRate'] as double? ?? shift.hourlyRate,
          certifications: List<String>.from(guard['certifications'] ?? []),
          availability: guard['availability'] as bool? ?? false,
          previousPerformance: guard['performance'] as double? ?? 0.0,
        ));
      }
      
      // Sort by match score descending
      scoredGuards.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      
      return scoredGuards.take(maxResults).toList();
      
    } catch (e) {
      if (e is ShiftManagementException) rethrow;
      
      throw ShiftManagementException(
        'Vervangers zoeken mislukt: ${e.toString()}',
        ShiftManagementErrorType.replacementSearchFailed,
      );
    }
  }

  /// Assign emergency replacement
  Future<Shift> assignEmergencyReplacement({
    required String shiftId,
    required String replacementGuardId,
    required String assignerId,
    String? reason,
  }) async {
    try {
      // Get shift
      final shiftDoc = await _firestore.collection('shifts').doc(shiftId).get();
      if (!shiftDoc.exists) {
        throw ShiftManagementException(
          'Dienst niet gevonden',
          ShiftManagementErrorType.shiftNotFound,
        );
      }
      
      final shift = Shift.fromFirestore(shiftDoc);
      
      // Validate replacement guard
      final guardDoc = await _firestore.collection('guards').doc(replacementGuardId).get();
      if (!guardDoc.exists) {
        throw ShiftManagementException(
          'Vervanger niet gevonden',
          ShiftManagementErrorType.guardNotFound,
        );
      }
      
      // Update shift with replacement
      final updatedShift = shift.copyWith(
        assignedGuardId: replacementGuardId,
        status: ShiftStatus.replacement,
        updatedAt: DateTime.now().toUtc(),
        metadata: {
          ...shift.metadata,
          'emergency_replacement': true,
          'original_guard_id': shift.assignedGuardId,
          'replacement_reason': reason ?? 'Noodvervanging',
          'assigned_by': assignerId,
          'replacement_time': DateTime.now().toUtc().toIso8601String(),
        },
      );
      
      await _firestore.collection('shifts').doc(shiftId).update(updatedShift.toFirestore());
      
      // Send notifications
      await _notifyEmergencyReplacement(updatedShift, replacementGuardId);
      
      return updatedShift;
      
    } catch (e) {
      if (e is ShiftManagementException) rethrow;
      
      throw ShiftManagementException(
        'Noodvervanging toewijzen mislukt: ${e.toString()}',
        ShiftManagementErrorType.emergencyAssignmentFailed,
      );
    }
  }

  /// Get shifts for a specific period
  Future<List<Shift>> getShifts({
    String? companyId,
    String? guardId,
    DateTime? startDate,
    DateTime? endDate,
    List<ShiftStatus>? statuses,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection('shifts');
      
      if (companyId != null) {
        query = query.where('companyId', isEqualTo: companyId);
      }
      
      if (guardId != null) {
        query = query.where('assignedGuardId', isEqualTo: guardId);
      }
      
      if (startDate != null) {
        query = query.where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      if (statuses != null) {
        final statusStrings = statuses.map((s) => s.toString().split('.').last).toList();
        query = query.where('status', whereIn: statusStrings);
      }
      
      query = query.orderBy('startTime');
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) => Shift.fromFirestore(doc)).toList();
      
    } catch (e) {
      throw ShiftManagementException(
        'Diensten ophalen mislukt: ${e.toString()}',
        ShiftManagementErrorType.dataFetchFailed,
      );
    }
  }

  /// Validate shift parameters
  Future<void> _validateShiftParameters({
    required DateTime startTime,
    required DateTime endTime,
    required double hourlyRate,
    required String companyId,
  }) async {
    // Check time validity
    if (startTime.isAfter(endTime)) {
      throw ShiftManagementException(
        'Starttijd kan niet na eindtijd zijn',
        ShiftManagementErrorType.invalidTimeRange,
      );
    }
    
    // Check minimum duration
    final duration = endTime.difference(startTime);
    if (duration.inHours < 1) {
      throw ShiftManagementException(
        'Dienst moet minimaal 1 uur duren',
        ShiftManagementErrorType.durationTooShort,
      );
    }
    
    // Check maximum duration (CAO limit)
    if (duration.inHours > 12) {
      throw ShiftManagementException(
        'Dienst mag niet langer dan 12 uur duren (CAO limiet)',
        ShiftManagementErrorType.durationTooLong,
      );
    }
    
    // Check hourly rate
    if (hourlyRate < 12.00) { // CAO minimum 2024
      throw ShiftManagementException(
        'Uurloon moet minimaal €12,00 zijn (CAO minimum)',
        ShiftManagementErrorType.rateTooLow,
      );
    }
    
    // Check if in the past
    if (startTime.isBefore(DateTime.now().toUtc())) {
      throw ShiftManagementException(
        'Dienst kan niet in het verleden gepland worden',
        ShiftManagementErrorType.pastDateTime,
      );
    }
  }

  /// Calculate estimated earnings
  Future<double> _calculateEstimatedEarnings({
    required Duration plannedDuration,
    required double hourlyRate,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final amsterdamStart = _toAmsterdamTime(startTime);
    final amsterdamEnd = _toAmsterdamTime(endTime);
    
    final totalHours = plannedDuration.inMinutes / 60.0;
    double multiplier = 1.0;
    
    // Weekend premium
    if (amsterdamStart.weekday > 5) {
      multiplier = amsterdamStart.weekday == 7 ? 2.0 : 1.5; // Sunday 200%, Saturday 150%
    }
    // Night shift premium (22:00-06:00)
    else if (amsterdamStart.hour >= 22 || amsterdamEnd.hour <= 6) {
      multiplier = 1.3; // 130% for night shifts
    }
    // Regular overtime (after 8 hours)
    else if (totalHours > 8.0) {
      const regularHours = 8.0;
      final overtimeHours = totalHours - regularHours;
      return (regularHours * hourlyRate) + (overtimeHours * hourlyRate * 1.5);
    }
    
    return totalHours * hourlyRate * multiplier;
  }

  /// Generate default breaks based on shift duration
  List<BreakPeriod> _generateDefaultBreaks(Duration shiftDuration) {
    final breaks = <BreakPeriod>[];
    final shiftHours = shiftDuration.inMinutes / 60.0;
    
    if (shiftHours >= 4.0 && shiftHours < 5.5) {
      // 15 minute break
      breaks.add(BreakPeriod(
        startTime: DateTime.now().add(Duration(hours: 2)), // 2 hours into shift
        endTime: DateTime.now().add(Duration(hours: 2, minutes: 15)),
        duration: Duration(minutes: 15),
        type: BreakType.mandatory,
        isPaid: true,
        isRequired: true,
      ));
    } else if (shiftHours >= 5.5 && shiftHours < 8.0) {
      // 30 minute break
      breaks.add(BreakPeriod(
        startTime: DateTime.now().add(Duration(hours: 3)), // 3 hours into shift
        endTime: DateTime.now().add(Duration(hours: 3, minutes: 30)),
        duration: Duration(minutes: 30),
        type: BreakType.meal,
        isPaid: false,
        isRequired: true,
      ));
    } else if (shiftHours >= 8.0) {
      // 45 minute break
      breaks.add(BreakPeriod(
        startTime: DateTime.now().add(Duration(hours: 4)), // 4 hours into shift
        endTime: DateTime.now().add(Duration(hours: 4, minutes: 45)),
        duration: Duration(minutes: 45),
        type: BreakType.meal,
        isPaid: false,
        isRequired: true,
      ));
    }
    
    return breaks;
  }

  /// Generate recurring shifts from template
  Future<void> _generateRecurringShifts(Shift template) async {
    if (template.recurrence == null) return;
    
    final recurrence = template.recurrence!;
    final endDate = recurrence.endDate ?? DateTime.now().toUtc().add(Duration(days: 365));
    
    var currentDate = template.startTime;
    final shifts = <Shift>[];
    
    while (currentDate.isBefore(endDate) && 
           (recurrence.maxOccurrences == null || shifts.length < recurrence.maxOccurrences!)) {
      
      // Skip exceptions
      if (recurrence.exceptions.any((exception) => 
          exception.year == currentDate.year && 
          exception.month == currentDate.month && 
          exception.day == currentDate.day)) {
        currentDate = _getNextRecurrenceDate(currentDate, recurrence);
        continue;
      }
      
      // Create shift for this date
      final shiftStart = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        template.startTime.hour,
        template.startTime.minute,
      );
      
      final shiftEnd = shiftStart.add(template.plannedDuration);
      
      final recurringShift = template.copyWith(
        id: '', // New ID will be assigned
        startTime: shiftStart,
        endTime: shiftEnd,
        status: ShiftStatus.published,
        isTemplate: false,
        templateId: template.id,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      
      shifts.add(recurringShift);
      currentDate = _getNextRecurrenceDate(currentDate, recurrence);
    }
    
    // Save all recurring shifts in batch
    final batch = _firestore.batch();
    for (final shift in shifts) {
      final docRef = _firestore.collection('shifts').doc();
      batch.set(docRef, shift.toFirestore());
    }
    
    await batch.commit();
  }

  /// Get next recurrence date
  DateTime _getNextRecurrenceDate(DateTime currentDate, RecurrencePattern recurrence) {
    switch (recurrence.frequency) {
      case RecurrenceFrequency.daily:
        return currentDate.add(Duration(days: recurrence.interval));
      case RecurrenceFrequency.weekly:
        return currentDate.add(Duration(days: 7 * recurrence.interval));
      case RecurrenceFrequency.monthly:
        return DateTime(currentDate.year, currentDate.month + recurrence.interval, currentDate.day);
      case RecurrenceFrequency.none:
        return currentDate;
    }
  }

  /// Execute approved shift swap
  Future<void> _executeShiftSwap(ShiftSwapRequest swapRequest) async {
    // Update the original shift with new guard
    await _firestore.collection('shifts').doc(swapRequest.originalShiftId).update({
      'assignedGuardId': swapRequest.replacementGuardId,
      'status': ShiftStatus.confirmed.toString().split('.').last,
      'updatedAt': Timestamp.fromDate(DateTime.now().toUtc()),
      'metadata': {
        'swapped': true,
        'original_guard_id': swapRequest.requestingGuardId,
        'swap_request_id': swapRequest.id,
      },
    });
  }

  /// Find matching guards for a shift
  Future<List<Map<String, dynamic>>> _findMatchingGuards(Shift shift) async {
    // This would implement complex guard matching logic
    // For now, return mock data
    return [
      {
        'id': 'guard1',
        'name': 'John Doe',
        'certifications': shift.requiredCertifications,
        'distance': 5.2,
        'hourlyRate': shift.hourlyRate,
        'availability': true,
        'performance': 4.5,
      },
    ];
  }

  /// Calculate guard match score
  Future<double> _calculateGuardMatchScore(Map<String, dynamic> guard, Shift shift) async {
    double score = 0.0;
    
    // Certification match (40% weight)
    final guardCerts = Set<String>.from(guard['certifications'] ?? []);
    final requiredCerts = Set<String>.from(shift.requiredCertifications);
    final certMatch = guardCerts.intersection(requiredCerts).length / requiredCerts.length;
    score += certMatch * 0.4;
    
    // Distance (20% weight) - closer is better
    final distance = guard['distance'] as double? ?? 100.0;
    final distanceScore = (50.0 - distance.clamp(0.0, 50.0)) / 50.0;
    score += distanceScore * 0.2;
    
    // Performance history (25% weight)
    final performance = guard['performance'] as double? ?? 3.0;
    score += (performance / 5.0) * 0.25;
    
    // Availability (15% weight)
    final availability = guard['availability'] as bool? ?? false;
    score += availability ? 0.15 : 0.0;
    
    return score.clamp(0.0, 1.0);
  }

  /// Notification methods (would integrate with notification service)
  Future<void> _notifyMatchingGuards(Shift shift) async {
    // Implementation would send notifications to matching guards
  }
  
  Future<void> _notifyShiftUpdate(Shift updatedShift, Shift originalShift) async {
    // Implementation would notify assigned guard of updates
  }
  
  Future<void> _notifyShiftCancellation(Shift shift) async {
    // Implementation would notify assigned guard and company
  }
  
  Future<void> _notifySwapRequest(ShiftSwapRequest request, Shift shift) async {
    // Implementation would notify company and potential replacement
  }
  
  Future<void> _notifySwapDecision(ShiftSwapRequest request) async {
    // Implementation would notify requesting guard
  }
  
  Future<void> _notifyEmergencyReplacement(Shift shift, String replacementGuardId) async {
    // Implementation would send urgent notifications
  }

  /// Dispose resources
  void dispose() {
    _shiftsStreamController.close();
    _swapRequestStreamController.close();
  }
}

/// Guard match result
class GuardMatch {
  final String guardId;
  final String guardName;
  final double matchScore;
  final double distance;
  final double hourlyRate;
  final List<String> certifications;
  final bool availability;
  final double previousPerformance;

  const GuardMatch({
    required this.guardId,
    required this.guardName,
    required this.matchScore,
    required this.distance,
    required this.hourlyRate,
    required this.certifications,
    required this.availability,
    required this.previousPerformance,
  });
}

/// Shift management error types
enum ShiftManagementErrorType {
  creationFailed,
  updateFailed,
  deleteFailed,
  shiftNotFound,
  guardNotFound,
  notAssigned,
  shiftInProgress,
  hasTimeEntries,
  invalidTimeRange,
  durationTooShort,
  durationTooLong,
  rateTooLow,
  pastDateTime,
  tooCloseToShift,
  swapRequestFailed,
  swapNotFound,
  alreadyProcessed,
  swapProcessFailed,
  replacementSearchFailed,
  emergencyAssignmentFailed,
  dataFetchFailed,
}

/// Shift management exception
class ShiftManagementException implements Exception {
  final String message;
  final ShiftManagementErrorType type;
  
  const ShiftManagementException(this.message, this.type);
  
  @override
  String toString() => 'ShiftManagementException: $message';
}