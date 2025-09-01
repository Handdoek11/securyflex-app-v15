import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/enhanced_dashboard_data.dart';
import '../models/emergency_incident.dart';

/// Enhanced shift service with real-time tracking and Dutch arbeidsrecht compliance
class EnhancedShiftService {
  final StreamController<List<EnhancedShiftData>> _shiftsController = 
      StreamController<List<EnhancedShiftData>>.broadcast();

  /// Stream for real-time shift updates
  Stream<List<EnhancedShiftData>> get shiftsStream => _shiftsController.stream;

  /// Get today's shifts with enhanced information
  Future<List<EnhancedShiftData>> getTodaysShifts() async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 200));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Mock shifts for demonstration
    return [
      EnhancedShiftData(
        id: 'shift_001',
        title: 'Winkelbeveiliging Centrum',
        companyName: 'Security Solutions BV',
        companyId: 'company_001',
        startTime: today.add(const Duration(hours: 9)),
        endTime: today.add(const Duration(hours: 17)),
        location: 'Amsterdam Centrum',
        address: 'Kalverstraat 123, 1012 AB Amsterdam',
        latitude: 52.3676,
        longitude: 4.9041,
        hourlyRate: 18.50,
        status: ShiftStatus.inProgress,
        type: ShiftType.retail,
        specialInstructions: 'Extra alertheid tijdens spitsuren. Let op zakkenrollers.',
        requiredCertifications: ['WPBR', 'BHV'],
        isOutdoor: false,
        requiresUniform: true,
        emergencyResponse: true,
        rating: 4.8,
        feedback: 'Professionele beveiliger, vriendelijk naar klanten.',
        checkedInAt: today.add(const Duration(hours: 9, minutes: 2)),
        dutchStatusText: 'Bezig - inchecked om 09:02',
      ),
      EnhancedShiftData(
        id: 'shift_002',
        title: 'Evenementbeveiliging Concert',
        companyName: 'Events & Security',
        companyId: 'company_002',
        startTime: today.add(const Duration(hours: 19)),
        endTime: today.add(const Duration(hours: 24)),
        location: 'Ziggo Dome',
        address: 'De Passage 100, 1101 AX Amsterdam',
        latitude: 52.3147,
        longitude: 4.9412,
        hourlyRate: 22.00,
        status: ShiftStatus.confirmed,
        type: ShiftType.event,
        specialInstructions: 'Crowd control en bag checks. Max 500 bezoekers per ingang.',
        requiredCertifications: ['WPBR', 'Crowd Control'],
        isOutdoor: true,
        requiresUniform: true,
        emergencyResponse: true,
        dutchStatusText: 'Bevestigd - start om 19:00',
      ),
      EnhancedShiftData(
        id: 'shift_003',
        title: 'Bouwplaatsbeveiliging',
        companyName: 'Bouw & Veiligheid NL',
        companyId: 'company_003',
        startTime: today.add(const Duration(days: 1, hours: 6)),
        endTime: today.add(const Duration(days: 1, hours: 14)),
        location: 'Almere Poort',
        address: 'Bouwterrein Fase 3, 1315 AB Almere',
        latitude: 52.3888,
        longitude: 5.3063,
        hourlyRate: 16.75,
        status: ShiftStatus.pending,
        type: ShiftType.construction,
        specialInstructions: 'Toegangscontrole en rondgang elke 2 uur. Helm verplicht.',
        requiredCertifications: ['WPBR', 'VCA'],
        isOutdoor: true,
        requiresUniform: true,
        emergencyResponse: false,
        dutchStatusText: 'In behandeling - wacht op bevestiging',
      ),
    ];
  }

  /// Update shift status
  Future<void> updateShiftStatus(String shiftId, ShiftStatus newStatus) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 150));
    
    // In production, this would update the shift status in Firebase
    if (kDebugMode) debugPrint('Shift $shiftId status updated to: ${newStatus.name}');
    
    // Emit updated shifts list
    final updatedShifts = await getTodaysShifts();
    _shiftsController.add(updatedShifts);
  }

  /// Report emergency incident during shift
  Future<void> reportEmergencyIncident(EmergencyIncident incident) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // In production, this would:
    // 1. Create incident record in Firebase
    // 2. Notify relevant parties (company, emergency services if needed)
    // 3. Update shift status to reflect incident
    
    if (kDebugMode) debugPrint('Emergency incident reported: ${incident.type} - ${incident.description}');
  }

  /// Update availability status for accepting new shifts
  Future<void> updateAvailabilityStatus(bool isAvailable) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    // In production, this would update user's availability in Firebase
    if (kDebugMode) debugPrint('Availability status updated: ${isAvailable ? "Available" : "Not available"}');
  }

  /// Check in to shift with GPS validation
  Future<bool> checkInToShift(String shiftId, double latitude, double longitude) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 250));
    
    // In production, this would:
    // 1. Validate GPS location against shift location
    // 2. Update shift status to in_progress
    // 3. Start time tracking
    // 4. Send notification to company
    
    final shifts = await getTodaysShifts();
    final shift = shifts.firstWhere((s) => s.id == shiftId);
    
    // Simple distance check (in production, use proper geolocation library)
    final distance = _calculateDistance(
      shift.latitude ?? 0, 
      shift.longitude ?? 0, 
      latitude, 
      longitude
    );
    
    // Allow check-in within 100 meters of shift location
    return distance < 0.1; // 100 meters
  }

  /// Check out from shift
  Future<bool> checkOutFromShift(String shiftId) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    // In production, this would:
    // 1. Update shift status to completed
    // 2. Calculate total hours and earnings
    // 3. Send completion notification to company
    // 4. Request rating/feedback
    
    return true;
  }

  /// Get shifts for performance analytics
  Future<List<EnhancedShiftData>> getShiftsForPeriod(
    DateTime startDate, 
    DateTime endDate
  ) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Mock historical data for analytics
    final shifts = <EnhancedShiftData>[];
    final random = Random();
    
    for (int i = 0; i < 20; i++) {
      final shiftDate = startDate.add(Duration(days: random.nextInt(30)));
      if (shiftDate.isBefore(endDate)) {
        shifts.add(_createMockShift(shiftDate, 'shift_${i + 100}'));
      }
    }
    
    return shifts;
  }

  /// Validate shift compliance with Dutch arbeidsrecht
  Future<List<String>> validateShiftCompliance(List<EnhancedShiftData> shifts) async {
    final violations = <String>[];
    
    // Check weekly hour limits (CAO: max 48 hours per week)
    final weeklyHours = shifts
        .where((s) => s.status == ShiftStatus.completed || s.status == ShiftStatus.inProgress)
        .fold(0.0, (sum, shift) => sum + shift.durationHours);
    
    if (weeklyHours > 48) {
      violations.add('Overschrijding maximum werkuren per week (${weeklyHours.toStringAsFixed(1)} > 48 uur)');
    }
    
    // Check rest periods (CAO: minimum 11 hours between shifts)
    for (int i = 0; i < shifts.length - 1; i++) {
      final currentShift = shifts[i];
      final nextShift = shifts[i + 1];
      
      final restHours = nextShift.startTime.difference(currentShift.endTime).inHours;
      if (restHours < 11) {
        violations.add('Onvoldoende rusttijd tussen diensten ($restHours < 11 uur)');
      }
    }
    
    return violations;
  }

  /// Calculate distance between two coordinates (simplified)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simplified distance calculation - in production use proper geolocation library
    final latDiff = lat1 - lat2;
    final lonDiff = lon1 - lon2;
    return sqrt(latDiff * latDiff + lonDiff * lonDiff) * 111; // Approximate km
  }

  /// Create mock shift for testing
  EnhancedShiftData _createMockShift(DateTime date, String id) {
    final random = Random();
    final types = ShiftType.values;
    final statuses = [ShiftStatus.completed, ShiftStatus.cancelled];
    
    return EnhancedShiftData(
      id: id,
      title: 'Mock Shift ${random.nextInt(100)}',
      companyName: 'Mock Company ${random.nextInt(10)}',
      companyId: 'company_${random.nextInt(100)}',
      startTime: date.add(Duration(hours: 8 + random.nextInt(8))),
      endTime: date.add(Duration(hours: 16 + random.nextInt(8))),
      location: 'Mock Location',
      address: 'Mock Address ${random.nextInt(100)}',
      hourlyRate: 15.0 + random.nextDouble() * 10,
      status: statuses[random.nextInt(statuses.length)],
      type: types[random.nextInt(types.length)],
      requiredCertifications: ['WPBR'],
      isOutdoor: random.nextBool(),
      requiresUniform: true,
      emergencyResponse: random.nextBool(),
      rating: 3.0 + random.nextDouble() * 2, // 3.0 - 5.0
      dutchStatusText: 'Mock status',
    );
  }

  void dispose() {
    _shiftsController.close();
  }
}