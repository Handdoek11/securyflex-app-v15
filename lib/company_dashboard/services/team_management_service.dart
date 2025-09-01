import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:securyflex_app/company_dashboard/models/team_management_data.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart' show GuardAvailabilityStatus;

/// Service for managing team operations, real-time status tracking, and guard coordination
/// Provides comprehensive team management functionality for security companies
class TeamManagementService {
  static final TeamManagementService _instance = TeamManagementService._internal();
  factory TeamManagementService() => _instance;
  TeamManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream controllers for real-time updates
  final StreamController<TeamStatusData> _teamStatusController = 
      StreamController<TeamStatusData>.broadcast();
  final StreamController<List<GuardLocationData>> _guardLocationsController = 
      StreamController<List<GuardLocationData>>.broadcast();
  final StreamController<List<CoverageGap>> _coverageGapsController = 
      StreamController<List<CoverageGap>>.broadcast();

  // Cache for performance optimization
  TeamStatusData? _cachedTeamStatus;
  List<GuardLocationData>? _cachedGuardLocations;
  List<CoverageGap>? _cachedCoverageGaps;
  DateTime? _lastCacheUpdate;

  // Stream subscriptions for cleanup
  StreamSubscription<DocumentSnapshot>? _teamStatusSubscription;
  StreamSubscription<QuerySnapshot>? _guardLocationsSubscription;
  StreamSubscription<QuerySnapshot>? _coverageGapsSubscription;

  /// Get real-time team status stream
  Stream<TeamStatusData> get teamStatusStream => _teamStatusController.stream;

  /// Get real-time guard locations stream
  Stream<List<GuardLocationData>> get guardLocationsStream => _guardLocationsController.stream;

  /// Get real-time coverage gaps stream
  Stream<List<CoverageGap>> get coverageGapsStream => _coverageGapsController.stream;

  /// Initialize team management for a company
  Future<void> initializeTeamManagement(String companyId) async {
    try {
      // Start listening to team status updates
      _teamStatusSubscription = _firestore
          .collection('team_status')
          .doc(companyId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final teamStatus = TeamStatusData.fromFirestore(snapshot);
          _cachedTeamStatus = teamStatus;
          _lastCacheUpdate = DateTime.now();
          
          if (!_teamStatusController.isClosed) {
            _teamStatusController.add(teamStatus);
          }
        } else {
          // Create initial team status document
          _createInitialTeamStatus(companyId);
        }
      });

      // Start listening to guard locations
      _guardLocationsSubscription = _firestore
          .collection('guard_locations')
          .where('companyId', isEqualTo: companyId)
          .snapshots()
          .listen((snapshot) {
        final guardLocations = snapshot.docs
            .map((doc) => GuardLocationData.fromFirestore(doc))
            .toList();
        
        _cachedGuardLocations = guardLocations;
        
        if (!_guardLocationsController.isClosed) {
          _guardLocationsController.add(guardLocations);
        }
      });

      // Start listening to coverage gaps
      _coverageGapsSubscription = _firestore
          .collection('coverage_gaps')
          .where('companyId', isEqualTo: companyId)
          .where('isResolved', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        final coverageGaps = snapshot.docs
            .map((doc) => CoverageGap.fromMap(doc.data()))
            .toList();
        
        _cachedCoverageGaps = coverageGaps;
        
        if (!_coverageGapsController.isClosed) {
          _coverageGapsController.add(coverageGaps);
        }
      });

      if (kDebugMode) {
        print('Team management initialized for company: $companyId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing team management: $e');
      }
      rethrow;
    }
  }

  /// Create initial team status document for new companies
  Future<void> _createInitialTeamStatus(String companyId) async {
    try {
      final initialStatus = TeamStatusData(
        companyId: companyId,
        totalGuards: 0,
        availableGuards: 0,
        onDutyGuards: 0,
        offDutyGuards: 0,
        emergencyGuards: 0,
        activeGuardLocations: [],
        coverageGaps: [],
        emergencyStatus: EmergencyStatus.normal,
        lastUpdated: DateTime.now(),
        metrics: const TeamMetrics(),
      );

      await _firestore
          .collection('team_status')
          .doc(companyId)
          .set(initialStatus.toFirestore());

      if (kDebugMode) {
        print('Initial team status created for company: $companyId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating initial team status: $e');
      }
    }
  }

  /// Update guard availability status
  Future<void> updateGuardAvailability(
    String guardId, 
    String companyId,
    GuardAvailabilityStatus status, {
    String? currentAssignment,
    String? currentAssignmentTitle,
    String? currentLocation,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final guardLocationData = GuardLocationData(
        guardId: guardId,
        guardName: await _getGuardName(guardId),
        latitude: latitude,
        longitude: longitude,
        lastUpdate: DateTime.now(),
        status: status,
        currentAssignment: currentAssignment,
        currentAssignmentTitle: currentAssignmentTitle,
        currentLocation: currentLocation,
        isLocationEnabled: latitude != null && longitude != null,
      );

      // Update guard location document
      await _firestore
          .collection('guard_locations')
          .doc(guardId)
          .set({
        ...guardLocationData.toFirestore(),
        'companyId': companyId,
      });

      // Update team status counters
      await _updateTeamStatusCounters(companyId);

      if (kDebugMode) {
        print('Guard $guardId availability updated to $status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating guard availability: $e');
      }
      rethrow;
    }
  }

  /// Update team status counters based on current guard statuses
  Future<void> _updateTeamStatusCounters(String companyId) async {
    try {
      final guardLocationsSnapshot = await _firestore
          .collection('guard_locations')
          .where('companyId', isEqualTo: companyId)
          .get();

      int totalGuards = guardLocationsSnapshot.docs.length;
      int availableGuards = 0;
      int onDutyGuards = 0;
      int offDutyGuards = 0;
      int emergencyGuards = 0;

      for (final doc in guardLocationsSnapshot.docs) {
        final data = doc.data();
        final status = GuardAvailabilityStatus.values.firstWhere(
          (s) => s.name == (data['status'] ?? 'unavailable'),
          orElse: () => GuardAvailabilityStatus.unavailable,
        );

        switch (status) {
          case GuardAvailabilityStatus.available:
            availableGuards++;
            break;
          case GuardAvailabilityStatus.onDuty:
            onDutyGuards++;
            break;
          case GuardAvailabilityStatus.busy:
            onDutyGuards++; // Treat busy as on duty
            break;
          case GuardAvailabilityStatus.unavailable:
            offDutyGuards++;
            break;
        }

        if (data['isEmergency'] == true) {
          emergencyGuards++;
        }
      }

      // Update team status document
      await _firestore
          .collection('team_status')
          .doc(companyId)
          .update({
        'totalGuards': totalGuards,
        'availableGuards': availableGuards,
        'onDutyGuards': onDutyGuards,
        'offDutyGuards': offDutyGuards,
        'emergencyGuards': emergencyGuards,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating team status counters: $e');
      }
    }
  }

  /// Get guard name from user document
  Future<String> _getGuardName(String guardId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(guardId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['name'] ?? 'Unknown Guard';
      }
      return 'Unknown Guard';
    } catch (e) {
      if (kDebugMode) {
        print('Error getting guard name: $e');
      }
      return 'Unknown Guard';
    }
  }

  /// Create a coverage gap alert
  Future<void> createCoverageGap(CoverageGap coverageGap) async {
    try {
      await _firestore
          .collection('coverage_gaps')
          .doc(coverageGap.gapId)
          .set(coverageGap.toMap());

      // Update emergency status if gap is critical
      if (coverageGap.severity == CoverageGapSeverity.critical) {
        await _updateEmergencyStatus(coverageGap.companyId, EmergencyStatus.critical);
      }

      if (kDebugMode) {
        print('Coverage gap created: ${coverageGap.gapId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating coverage gap: $e');
      }
      rethrow;
    }
  }

  /// Resolve a coverage gap
  Future<void> resolveCoverageGap(
    String gapId, 
    String resolvedBy, {
    String? resolutionNotes,
  }) async {
    try {
      await _firestore
          .collection('coverage_gaps')
          .doc(gapId)
          .update({
        'isResolved': true,
        'resolvedAt': Timestamp.fromDate(DateTime.now()),
        'resolvedBy': resolvedBy,
        'resolutionNotes': resolutionNotes,
      });

      if (kDebugMode) {
        print('Coverage gap resolved: $gapId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resolving coverage gap: $e');
      }
      rethrow;
    }
  }

  /// Update emergency status for a company
  Future<void> _updateEmergencyStatus(String companyId, EmergencyStatus status) async {
    try {
      await _firestore
          .collection('team_status')
          .doc(companyId)
          .update({
        'emergencyStatus': status.name,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });

      if (kDebugMode) {
        print('Emergency status updated to $status for company: $companyId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating emergency status: $e');
      }
    }
  }

  /// Get cached team status (for immediate UI updates)
  TeamStatusData? getCachedTeamStatus() => _cachedTeamStatus;

  /// Get cached guard locations (for immediate UI updates)
  List<GuardLocationData>? getCachedGuardLocations() => _cachedGuardLocations;

  /// Get cached coverage gaps (for immediate UI updates)
  List<CoverageGap>? getCachedCoverageGaps() => _cachedCoverageGaps;

  /// Check if cache is fresh (less than 30 seconds old)
  bool get isCacheFresh {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!).inSeconds < 30;
  }

  /// Generate mock data for development and testing
  TeamStatusData generateMockTeamData(String companyId) {
    final random = math.Random();
    final now = DateTime.now();

    // Generate mock guard locations
    final mockGuardNames = [
      'Jan de Vries', 'Marie Bakker', 'Piet Janssen', 'Lisa van der Berg',
      'Tom Hendriks', 'Sarah de Jong', 'Mike van Dijk', 'Emma Visser',
      'Lars Mulder', 'Nina Smit', 'Rick de Boer', 'Lotte Jansen'
    ];

    final mockLocations = [
      'Amsterdam Centrum', 'Rotterdam Zuid', 'Den Haag Noord', 'Utrecht Oost',
      'Eindhoven West', 'Tilburg Centrum', 'Groningen Noord', 'Maastricht Zuid'
    ];

    final guardLocations = List.generate(8, (index) {
      final status = GuardAvailabilityStatus.values[random.nextInt(3)];
      return GuardLocationData(
        guardId: 'guard_${index.toString().padLeft(3, '0')}',
        guardName: mockGuardNames[index],
        latitude: 52.0 + random.nextDouble() * 2.0,
        longitude: 4.0 + random.nextDouble() * 2.0,
        lastUpdate: now.subtract(Duration(minutes: random.nextInt(10))),
        status: status,
        currentAssignment: status == GuardAvailabilityStatus.onDuty ? 'job_${random.nextInt(5)}' : null,
        currentAssignmentTitle: status == GuardAvailabilityStatus.onDuty 
            ? ['Objectbeveiliging', 'Evenementbeveiliging', 'Nachtbeveiliging'][random.nextInt(3)]
            : null,
        currentLocation: mockLocations[random.nextInt(mockLocations.length)],
        isLocationEnabled: true,
      );
    });

    // Generate mock coverage gaps
    final coverageGaps = random.nextBool() ? [
      CoverageGap(
        gapId: 'gap_${random.nextInt(1000)}',
        companyId: companyId,
        startTime: now.add(Duration(hours: random.nextInt(8))),
        endTime: now.add(Duration(hours: 8 + random.nextInt(8))),
        location: mockLocations[random.nextInt(mockLocations.length)],
        postalCode: '${1000 + random.nextInt(9000)}',
        severity: CoverageGapSeverity.values[random.nextInt(4)],
        affectedJobIds: ['job_${random.nextInt(10)}'],
        affectedJobTitles: ['Nachtbeveiliging Kantoor'],
        createdAt: now,
      ),
    ] : <CoverageGap>[];

    // Count statuses
    int availableCount = guardLocations.where((g) => g.status == GuardAvailabilityStatus.available).length;
    int onDutyCount = guardLocations.where((g) => g.status == GuardAvailabilityStatus.onDuty).length;
    int offDutyCount = guardLocations.where((g) => g.status == GuardAvailabilityStatus.unavailable).length;

    return TeamStatusData(
      companyId: companyId,
      totalGuards: guardLocations.length,
      availableGuards: availableCount,
      onDutyGuards: onDutyCount,
      offDutyGuards: offDutyCount,
      emergencyGuards: 0,
      activeGuardLocations: guardLocations,
      coverageGaps: coverageGaps,
      emergencyStatus: coverageGaps.any((gap) => gap.severity == CoverageGapSeverity.critical) 
          ? EmergencyStatus.critical 
          : EmergencyStatus.normal,
      lastUpdated: now,
      metrics: TeamMetrics(
        averageRating: 4.0 + random.nextDouble(),
        reliabilityScore: 85.0 + random.nextDouble() * 15.0,
        averageResponseTime: 5.0 + random.nextDouble() * 20.0,
        clientSatisfactionScore: 4.0 + random.nextDouble(),
        totalJobsCompleted: 100 + random.nextInt(200),
        jobsCompletedThisMonth: 10 + random.nextInt(30),
        revenueGenerated: 20000.0 + random.nextDouble() * 50000.0,
        revenueThisMonth: 5000.0 + random.nextDouble() * 15000.0,
        emergencyResponseCount: random.nextInt(10),
        emergencyResponseTime: 5.0 + random.nextDouble() * 15.0,
      ),
    );
  }

  /// Dispose of resources and close streams
  void dispose() {
    _teamStatusSubscription?.cancel();
    _guardLocationsSubscription?.cancel();
    _coverageGapsSubscription?.cancel();
    
    _teamStatusController.close();
    _guardLocationsController.close();
    _coverageGapsController.close();
    
    if (kDebugMode) {
      print('TeamManagementService disposed');
    }
  }
}
