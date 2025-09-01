import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:securyflex_app/company_dashboard/models/team_management_data.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';

/// Service for detecting and managing coverage gaps in security operations
/// Provides automatic gap detection, severity assessment, and resolution tracking
class CoverageGapService {
  static final CoverageGapService _instance = CoverageGapService._internal();
  factory CoverageGapService() => _instance;
  CoverageGapService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream controllers for real-time gap updates
  final StreamController<List<CoverageGap>> _coverageGapsController = 
      StreamController<List<CoverageGap>>.broadcast();
  final StreamController<CoverageGap> _newGapController = 
      StreamController<CoverageGap>.broadcast();

  // Gap detection state
  StreamSubscription<QuerySnapshot>? _gapsSubscription;
  StreamSubscription<QuerySnapshot>? _jobsSubscription;
  Timer? _gapDetectionTimer;
  
  String? _currentCompanyId;
  List<JobPostingData> _activeJobs = [];
  List<GuardLocationData> _availableGuards = [];

  /// Get stream of coverage gaps for a company
  Stream<List<CoverageGap>> get coverageGapsStream => _coverageGapsController.stream;

  /// Get stream of new coverage gap alerts
  Stream<CoverageGap> get newGapStream => _newGapController.stream;

  /// Initialize coverage gap monitoring for a company
  Future<void> initializeCoverageGapMonitoring(String companyId) async {
    try {
      _currentCompanyId = companyId;

      // Start listening to coverage gaps
      _gapsSubscription = _firestore
          .collection('coverage_gaps')
          .where('companyId', isEqualTo: companyId)
          .where('isResolved', isEqualTo: false)
          .orderBy('severity', descending: true)
          .orderBy('startTime')
          .snapshots()
          .listen((snapshot) {
        final coverageGaps = snapshot.docs
            .map((doc) => CoverageGap.fromMap(doc.data()))
            .toList();
        
        if (!_coverageGapsController.isClosed) {
          _coverageGapsController.add(coverageGaps);
        }
      });

      // Start listening to active jobs for gap detection
      _jobsSubscription = _firestore
          .collection('jobs')
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .listen((snapshot) {
        _activeJobs = snapshot.docs
            .map((doc) => JobPostingData.fromFirestore(doc.data()))
            .toList();
        
        // Trigger gap detection when jobs change
        _detectCoverageGaps();
      });

      // Set up periodic gap detection (every 5 minutes)
      _gapDetectionTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        _detectCoverageGaps();
      });

      if (kDebugMode) {
        developer.log('Coverage gap monitoring initialized for company: $companyId', name: 'CoverageGapService', level: 1000);
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error initializing coverage gap monitoring: $e', name: 'CoverageGapService', level: 1000);
      }
    }
  }

  /// Detect coverage gaps based on job requirements and guard availability
  Future<void> _detectCoverageGaps() async {
    if (_currentCompanyId == null) return;

    try {
      // Get current guard availability
      final guardSnapshot = await _firestore
          .collection('guard_locations')
          .where('companyId', isEqualTo: _currentCompanyId)
          .get();

      _availableGuards = guardSnapshot.docs
          .map((doc) => GuardLocationData.fromFirestore(doc))
          .toList();

      // Analyze each active job for coverage gaps
      for (final job in _activeJobs) {
        await _analyzeJobCoverage(job);
      }

      // Detect time-based coverage gaps
      await _detectTimeBasedGaps();

      if (kDebugMode) {
        developer.log('Coverage gap detection completed for ${_activeJobs.length} jobs', name: 'CoverageGapService', level: 1000);
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error detecting coverage gaps: $e', name: 'CoverageGapService', level: 1000);
      }
    }
  }

  /// Analyze coverage for a specific job
  Future<void> _analyzeJobCoverage(JobPostingData job) async {
    try {
      // Check if job has adequate guard coverage
      final requiredGuards = job.numberOfGuards ?? 1;
      final assignedGuards = _getAssignedGuards(job.id);
      final availableNearbyGuards = _getNearbyAvailableGuards(
        job.latitude ?? 0.0, 
        job.longitude ?? 0.0,
        radiusKm: 25.0,
      );

      // Determine if there's a coverage gap
      final shortfall = requiredGuards - assignedGuards.length;
      if (shortfall > 0) {
        final severity = _calculateGapSeverity(
          shortfall: shortfall,
          totalRequired: requiredGuards,
          availableNearby: availableNearbyGuards.length,
          jobUrgency: job.urgency ?? JobUrgency.medium,
          timeUntilStart: job.startDate.difference(DateTime.now()).inHours,
        );

        // Create coverage gap if it doesn't already exist
        await _createCoverageGapIfNeeded(
          job: job,
          shortfall: shortfall,
          severity: severity,
          availableReplacements: availableNearbyGuards,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error analyzing job coverage for ${job.id}: $e', name: 'CoverageGapService', level: 1000);
      }
    }
  }

  /// Get guards assigned to a specific job
  List<GuardLocationData> _getAssignedGuards(String jobId) {
    return _availableGuards
        .where((guard) => guard.currentAssignment == jobId)
        .toList();
  }

  /// Get available guards near a location
  List<GuardLocationData> _getNearbyAvailableGuards(
    double latitude, 
    double longitude, {
    double radiusKm = 25.0,
  }) {
    return _availableGuards
        .where((guard) => 
            guard.status == GuardAvailabilityStatus.available &&
            guard.latitude != null &&
            guard.longitude != null &&
            _calculateDistance(
              latitude, longitude,
              guard.latitude!, guard.longitude!
            ) <= radiusKm)
        .toList();
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Calculate coverage gap severity
  CoverageGapSeverity _calculateGapSeverity({
    required int shortfall,
    required int totalRequired,
    required int availableNearby,
    required JobUrgency jobUrgency,
    required int timeUntilStart,
  }) {
    // Base severity on shortfall percentage
    final shortfallPercentage = (shortfall / totalRequired) * 100;
    
    // Adjust for job urgency
    final urgencyMultiplier = switch (jobUrgency) {
      JobUrgency.low => 0.5,
      JobUrgency.medium => 1.0,
      JobUrgency.high => 1.5,
      JobUrgency.urgent => 2.0,
    };

    // Adjust for time until start
    final timeMultiplier = switch (timeUntilStart) {
      < 2 => 2.0,   // Less than 2 hours
      < 8 => 1.5,   // Less than 8 hours
      < 24 => 1.0,  // Less than 24 hours
      _ => 0.7,     // More than 24 hours
    };

    // Adjust for available replacements
    final availabilityMultiplier = availableNearby == 0 ? 1.5 : 
                                  availableNearby < shortfall ? 1.2 : 1.0;

    final severityScore = shortfallPercentage * urgencyMultiplier * 
                         timeMultiplier * availabilityMultiplier;

    return switch (severityScore) {
      >= 150 => CoverageGapSeverity.critical,
      >= 100 => CoverageGapSeverity.high,
      >= 50 => CoverageGapSeverity.medium,
      _ => CoverageGapSeverity.low,
    };
  }

  /// Create coverage gap if it doesn't already exist
  Future<void> _createCoverageGapIfNeeded({
    required JobPostingData job,
    required int shortfall,
    required CoverageGapSeverity severity,
    required List<GuardLocationData> availableReplacements,
  }) async {
    try {
      final gapId = 'gap_${job.id}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Check if similar gap already exists
      final existingGaps = await _firestore
          .collection('coverage_gaps')
          .where('companyId', isEqualTo: _currentCompanyId)
          .where('affectedJobIds', arrayContains: job.id)
          .where('isResolved', isEqualTo: false)
          .get();

      if (existingGaps.docs.isNotEmpty) {
        // Update existing gap if severity changed
        final existingGap = CoverageGap.fromMap(
          existingGaps.docs.first.data()
        );
        
        if (existingGap.severity != severity) {
          await _firestore
              .collection('coverage_gaps')
              .doc(existingGaps.docs.first.id)
              .update({
            'severity': severity.name,
            'suggestedReplacements': availableReplacements
                .map((guard) => guard.guardId)
                .toList(),
          });
        }
        return;
      }

      // Create new coverage gap
      final coverageGap = CoverageGap(
        gapId: gapId,
        companyId: _currentCompanyId!,
        startTime: job.startDate,
        endTime: job.endDate,
        location: job.location,
        postalCode: job.postalCode,
        severity: severity,
        affectedJobIds: [job.id],
        affectedJobTitles: [job.title],
        suggestedReplacements: availableReplacements
            .take(5) // Limit to top 5 suggestions
            .map((guard) => guard.guardId)
            .toList(),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('coverage_gaps')
          .doc(gapId)
          .set(coverageGap.toMap());

      // Emit new gap alert
      if (!_newGapController.isClosed) {
        _newGapController.add(coverageGap);
      }

      if (kDebugMode) {
        developer.log('Coverage gap created: $gapId (${severity.name})', name: 'CoverageGapService', level: 1000);
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error creating coverage gap: $e', name: 'CoverageGapService', level: 1000);
      }
    }
  }

  /// Detect time-based coverage gaps (shifts without guards)
  Future<void> _detectTimeBasedGaps() async {
    try {
      final now = DateTime.now();
      final next24Hours = now.add(const Duration(hours: 24));

      // Check for upcoming shifts without adequate coverage
      final upcomingJobs = _activeJobs
          .where((job) =>
              job.startDate.isAfter(now) &&
              job.startDate.isBefore(next24Hours))
          .toList();

      for (final job in upcomingJobs) {
        final assignedGuards = _getAssignedGuards(job.id);
        final requiredGuards = job.numberOfGuards ?? 1;
        
        if (assignedGuards.length < requiredGuards) {
          await _analyzeJobCoverage(job);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error detecting time-based gaps: $e', name: 'CoverageGapService', level: 1000);
      }
    }
  }

  /// Resolve a coverage gap
  Future<void> resolveCoverageGap(
    String gapId, 
    String resolvedBy, {
    String? resolutionNotes,
    List<String>? assignedGuards,
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
        'assignedGuards': assignedGuards ?? [],
      });

      if (kDebugMode) {
        developer.log('Coverage gap resolved: $gapId by $resolvedBy', name: 'CoverageGapService', level: 1000);
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error resolving coverage gap: $e', name: 'CoverageGapService', level: 1000);
      }
      rethrow;
    }
  }

  /// Get coverage gap statistics for a company
  Future<Map<String, dynamic>> getCoverageGapStatistics(String companyId) async {
    try {
      final gapsSnapshot = await _firestore
          .collection('coverage_gaps')
          .where('companyId', isEqualTo: companyId)
          .get();

      final allGaps = gapsSnapshot.docs
          .map((doc) => CoverageGap.fromMap(doc.data()))
          .toList();

      final activeGaps = allGaps.where((gap) => !gap.isResolved).toList();
      final resolvedGaps = allGaps.where((gap) => gap.isResolved).toList();

      final criticalGaps = activeGaps
          .where((gap) => gap.severity == CoverageGapSeverity.critical)
          .length;

      final averageResolutionTime = resolvedGaps.isNotEmpty
          ? resolvedGaps
              .where((gap) => gap.resolvedAt != null)
              .map((gap) => gap.resolvedAt!.difference(gap.createdAt).inMinutes)
              .reduce((a, b) => a + b) / resolvedGaps.length
          : 0.0;

      return {
        'totalGaps': allGaps.length,
        'activeGaps': activeGaps.length,
        'resolvedGaps': resolvedGaps.length,
        'criticalGaps': criticalGaps,
        'averageResolutionTimeMinutes': averageResolutionTime,
        'resolutionRate': allGaps.isNotEmpty 
            ? (resolvedGaps.length / allGaps.length) * 100 
            : 0.0,
      };
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error getting coverage gap statistics: $e', name: 'CoverageGapService', level: 1000);
      }
      return {};
    }
  }

  /// Generate mock coverage gaps for testing
  List<CoverageGap> generateMockCoverageGaps(String companyId) {
    final random = math.Random();
    final now = DateTime.now();
    
    final mockLocations = [
      'Amsterdam Centrum', 'Rotterdam Zuid', 'Den Haag Noord', 
      'Utrecht Oost', 'Eindhoven West'
    ];
    
    final mockJobTitles = [
      'Nachtbeveiliging Kantoor', 'Evenementbeveiliging', 'Objectbeveiliging',
      'Winkelbeveiliging', 'Bouwplaatsbeveiliging'
    ];

    return List.generate(random.nextInt(3) + 1, (index) {
      final startTime = now.add(Duration(hours: random.nextInt(48)));
      final severity = CoverageGapSeverity.values[random.nextInt(4)];
      
      return CoverageGap(
        gapId: 'gap_${companyId}_${index}_${now.millisecondsSinceEpoch}',
        companyId: companyId,
        startTime: startTime,
        endTime: startTime.add(Duration(hours: 4 + random.nextInt(8))),
        location: mockLocations[random.nextInt(mockLocations.length)],
        postalCode: '${1000 + random.nextInt(9000)}',
        severity: severity,
        affectedJobIds: ['job_${random.nextInt(100)}'],
        affectedJobTitles: [mockJobTitles[random.nextInt(mockJobTitles.length)]],
        suggestedReplacements: List.generate(
          random.nextInt(3) + 1, 
          (i) => 'guard_${random.nextInt(50).toString().padLeft(3, '0')}'
        ),
        createdAt: now.subtract(Duration(minutes: random.nextInt(120))),
      );
    });
  }

  /// Dispose of resources and close streams
  void dispose() {
    _gapsSubscription?.cancel();
    _jobsSubscription?.cancel();
    _gapDetectionTimer?.cancel();
    
    _coverageGapsController.close();
    _newGapController.close();
    
    if (kDebugMode) {
      developer.log('CoverageGapService disposed', name: 'CoverageGapService', level: 1000);
    }
  }
}
