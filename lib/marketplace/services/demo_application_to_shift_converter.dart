import 'package:flutter/material.dart';
import '../../beveiliger_agenda/models/shift_data.dart';
import '../../auth/auth_service.dart';

/// Demo version of Application to Shift Converter
/// 
/// This service provides a working demonstration of how accepted job applications
/// are converted to active shifts, using mock data and simplified logic.
class DemoApplicationToShiftConverter {
  static final DemoApplicationToShiftConverter _instance = DemoApplicationToShiftConverter._internal();
  factory DemoApplicationToShiftConverter() => _instance;
  DemoApplicationToShiftConverter._internal();

  /// Mock list of active shifts created from accepted applications
  final List<ShiftData> _activeShifts = [];

  /// Get all active shifts for current guard
  Future<List<ShiftData>> getActiveShifts() async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 300));
    
    // If no active shifts yet, create some demo data
    if (_activeShifts.isEmpty) {
      _createDemoActiveShifts();
    }
    
    return List.from(_activeShifts);
  }

  /// Create demo active shifts (simulating converted applications)
  void _createDemoActiveShifts() {
    final now = DateTime.now();
    
    _activeShifts.addAll([
      ShiftData(
        id: 'active_1',
        title: 'Kantoor Beveiliging Amsterdam',
        description: 'Dagdienst kantoorcomplex in Amsterdam Centrum. Toegangscontrole en surveillance.',
        location: 'Amsterdam Centrum',
        address: 'Damrak 75, 1012 LP Amsterdam',
        startTime: DateTime(now.year, now.month, now.day + 2, 8, 0),
        endTime: DateTime(now.year, now.month, now.day + 2, 17, 0),
        hourlyRate: 18.50,
        shiftType: ShiftType.office,
        status: ShiftStatus.confirmed,
        companyName: 'SecureOffice BV',
        companyId: 'comp_001',
        contactPerson: 'Jan van der Berg',
        contactPhone: '+31 6 12345678',
        specialRequirements: ['VCA certificaat', 'Eigen vervoer'],
        isUrgent: false,
        isPremium: true,
        jobId: 'job_001',
        applicationId: 'app_001',
        guardId: AuthService.currentUserId,
        guardName: AuthService.currentUserName,
        requirements: ['VCA certificaat', 'Beveiligingsdiploma'],
        certificatesRequired: ['VCA', 'Beveiliging A'],
        totalEarnings: 18.50 * 9, // 9 hours
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        updatedAt: DateTime.now(),
        metadata: {
          'source': 'job_application',
          'original_job_id': 'job_001',
          'application_id': 'app_001',
          'conversion_date': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
          'company_response': 'Gefeliciteerd! Je bent geselecteerd voor deze functie.',
        },
      ),
      
      ShiftData(
        id: 'active_2', 
        title: 'Winkel Beveiliging Rotterdam',
        description: 'Weekend dienst winkelcentrum. Surveillance en klantenservice.',
        location: 'Rotterdam Zuid',
        address: 'Zuidplein 40, 3083 AA Rotterdam',
        startTime: DateTime(now.year, now.month, now.day + 5, 10, 0),
        endTime: DateTime(now.year, now.month, now.day + 5, 18, 0),
        hourlyRate: 17.25,
        shiftType: ShiftType.retail,
        status: ShiftStatus.accepted,
        companyName: 'RetailSecure Nederland',
        companyId: 'comp_002',
        contactPerson: 'Lisa de Vries',
        contactPhone: '+31 6 87654321',
        specialRequirements: ['Klantgerichte instelling', 'Flexibele werktijden'],
        isUrgent: true,
        isPremium: false,
        jobId: 'job_002',
        applicationId: 'app_002', 
        guardId: AuthService.currentUserId,
        guardName: AuthService.currentUserName,
        requirements: ['Beveiligingsdiploma', 'Klantgerichtheid'],
        certificatesRequired: ['Beveiliging A'],
        totalEarnings: 17.25 * 8, // 8 hours
        createdAt: DateTime.now().subtract(Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(Duration(hours: 2)),
        metadata: {
          'source': 'job_application',
          'original_job_id': 'job_002',
          'application_id': 'app_002',
          'conversion_date': DateTime.now().subtract(Duration(hours: 6)).toIso8601String(),
          'company_response': 'We zijn onder de indruk van je ervaring. Welkom bij ons team!',
        },
      ),
      
      ShiftData(
        id: 'active_3',
        title: 'Evenement Beveiliging Den Haag', 
        description: 'Beveiliging corporate evenement. Toegangscontrole en crowd management.',
        location: 'Den Haag Centrum',
        address: 'World Forum, Churchillplein 10, 2517 JW Den Haag',
        startTime: DateTime(now.year, now.month, now.day + 10, 18, 0),
        endTime: DateTime(now.year, now.month, now.day + 10, 23, 30),
        hourlyRate: 22.00,
        shiftType: ShiftType.event,
        status: ShiftStatus.confirmed,
        companyName: 'EventSecure Pro',
        companyId: 'comp_003',
        contactPerson: 'Mark Janssen',
        contactPhone: '+31 6 11223344',
        specialRequirements: ['Ervaring met evenementen', 'Representatief uiterlijk'],
        isUrgent: false,
        isPremium: true,
        jobId: 'job_003',
        applicationId: 'app_003',
        guardId: AuthService.currentUserId,
        guardName: AuthService.currentUserName,
        requirements: ['Evenement ervaring', 'Beveiligingsdiploma', 'Eerste hulp'],
        certificatesRequired: ['Beveiliging A', 'Evenement Beveiliging'],
        totalEarnings: 22.00 * 5.5, // 5.5 hours
        createdAt: DateTime.now().subtract(Duration(days: 3)),
        updatedAt: DateTime.now().subtract(Duration(hours: 12)),
        metadata: {
          'source': 'job_application',
          'original_job_id': 'job_003',
          'application_id': 'app_003',
          'conversion_date': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
          'company_response': 'Perfect profiel voor ons evenement. Kijken uit naar de samenwerking!',
        },
      ),
    ]);
    
    debugPrint('✅ Created ${_activeShifts.length} demo active shifts');
  }

  /// Add a new active shift (simulating a newly accepted application)
  Future<ShiftData> addActiveShift({
    required String jobTitle,
    required String companyName,
    required String location,
    required DateTime startTime,
    required DateTime endTime,
    required double hourlyRate,
    required ShiftType shiftType,
  }) async {
    final now = DateTime.now();
    final newShift = ShiftData(
      id: 'active_${now.millisecondsSinceEpoch}',
      title: jobTitle,
      description: 'Nieuw geaccepteerde opdracht: $jobTitle',
      location: location,
      address: '$location, Nederland',
      startTime: startTime,
      endTime: endTime,
      hourlyRate: hourlyRate,
      shiftType: shiftType,
      status: ShiftStatus.accepted,
      companyName: companyName,
      companyId: 'comp_${now.millisecondsSinceEpoch}',
      contactPerson: 'Contactpersoon',
      contactPhone: '+31 6 12345678',
      specialRequirements: ['Te bespreken'],
      isUrgent: false,
      isPremium: hourlyRate > 20.00,
      jobId: 'job_${now.millisecondsSinceEpoch}',
      applicationId: 'app_${now.millisecondsSinceEpoch}',
      guardId: AuthService.currentUserId,
      guardName: AuthService.currentUserName,
      requirements: ['Beveiligingsdiploma'],
      certificatesRequired: ['Beveiliging A'],
      totalEarnings: hourlyRate * endTime.difference(startTime).inMinutes / 60,
      createdAt: now,
      updatedAt: now,
      metadata: {
        'source': 'job_application',
        'conversion_date': now.toIso8601String(),
        'company_response': 'Je sollicitatie is geaccepteerd!',
      },
    );
    
    _activeShifts.insert(0, newShift); // Add to beginning for recency
    debugPrint('✅ Added new active shift: ${newShift.title}');
    
    return newShift;
  }

  /// Remove an active shift (for demo purposes)
  Future<void> removeActiveShift(String shiftId) async {
    _activeShifts.removeWhere((shift) => shift.id == shiftId);
    debugPrint('🗑️ Removed active shift: $shiftId');
  }

  /// Get shift by application ID (demo version)
  Future<ShiftData?> getShiftByApplicationId(String applicationId) async {
    await Future.delayed(Duration(milliseconds: 100));
    
    try {
      return _activeShifts.firstWhere(
        (shift) => shift.applicationId == applicationId,
      );
    } catch (e) {
      return null; // Not found
    }
  }

  /// Check if application has been converted (demo version)
  Future<bool> hasBeenConverted(String applicationId) async {
    final shift = await getShiftByApplicationId(applicationId);
    return shift != null;
  }

  /// Simulate accepting a new application and converting it to shift
  Future<ShiftData?> simulateApplicationAcceptance({
    required String applicationId,
    required String jobTitle,
    required String companyName,
    required String location,
    required double hourlyRate,
    ShiftType shiftType = ShiftType.office,
  }) async {
    debugPrint('🎯 Simulating application acceptance for: $jobTitle');
    
    // Simulate processing delay
    await Future.delayed(Duration(milliseconds: 500));
    
    // Create shift with realistic future date
    final now = DateTime.now();
    final startDate = now.add(Duration(days: 3 + (applicationId.hashCode % 10)));
    final endDate = startDate.add(Duration(hours: 8));
    
    final newShift = await addActiveShift(
      jobTitle: jobTitle,
      companyName: companyName,
      location: location,
      startTime: startDate,
      endTime: endDate,
      hourlyRate: hourlyRate,
      shiftType: shiftType,
    );
    
    // Update metadata to track original application
    final updatedShift = ShiftData(
      id: newShift.id,
      title: newShift.title,
      description: newShift.description,
      location: newShift.location,
      address: newShift.address,
      startTime: newShift.startTime,
      endTime: newShift.endTime,
      hourlyRate: newShift.hourlyRate,
      shiftType: newShift.shiftType,
      status: newShift.status,
      companyName: newShift.companyName,
      companyId: newShift.companyId,
      contactPerson: newShift.contactPerson,
      contactPhone: newShift.contactPhone,
      specialRequirements: newShift.specialRequirements,
      isUrgent: newShift.isUrgent,
      isPremium: newShift.isPremium,
      jobId: newShift.jobId,
      applicationId: applicationId, // Link to original application
      guardId: newShift.guardId,
      guardName: newShift.guardName,
      requirements: newShift.requirements,
      certificatesRequired: newShift.certificatesRequired,
      totalEarnings: newShift.totalEarnings,
      createdAt: newShift.createdAt,
      updatedAt: DateTime.now(),
      metadata: {
        ...newShift.metadata,
        'application_id': applicationId,
        'simulated_acceptance': true,
      },
    );
    
    // Replace in list
    final index = _activeShifts.indexWhere((s) => s.id == newShift.id);
    if (index != -1) {
      _activeShifts[index] = updatedShift;
    }
    
    debugPrint('✅ Successfully converted application $applicationId to active shift');
    return updatedShift;
  }

  /// Get statistics for demo purposes
  Map<String, dynamic> getStats() {
    final totalShifts = _activeShifts.length;
    final totalEarnings = _activeShifts.fold<double>(0, (sum, shift) => sum + shift.totalEarnings);
    final urgentShifts = _activeShifts.where((s) => s.isUrgent).length;
    final premiumShifts = _activeShifts.where((s) => s.isPremium).length;
    
    return {
      'total_active_shifts': totalShifts,
      'total_projected_earnings': totalEarnings,
      'urgent_shifts': urgentShifts,
      'premium_shifts': premiumShifts,
      'next_shift': _activeShifts.isNotEmpty 
          ? _activeShifts.reduce((a, b) => a.startTime.isBefore(b.startTime) ? a : b)
          : null,
    };
  }

  /// Clear all demo data (for testing)
  void clearDemoData() {
    _activeShifts.clear();
    debugPrint('🧹 Cleared all demo active shifts');
  }
}