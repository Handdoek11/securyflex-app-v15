import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:securyflex_app/company_dashboard/models/team_management_data.dart';

/// Emergency alert types for different scenarios
enum EmergencyAlertType {
  guardEmergency,
  coverageGap,
  systemAlert,
  clientEmergency,
  equipmentFailure,
}

/// Emergency alert data model
class EmergencyAlert {
  final String alertId;
  final String companyId;
  final EmergencyAlertType alertType;
  final CoverageGapSeverity severity;
  final String title;
  final String description;
  final String? guardId;
  final String? jobId;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final bool isResolved;
  final List<String> notifiedGuards;
  final List<String> respondingGuards;
  final Map<String, dynamic> metadata;

  const EmergencyAlert({
    required this.alertId,
    required this.companyId,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.description,
    this.guardId,
    this.jobId,
    this.location,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.isResolved = false,
    this.notifiedGuards = const [],
    this.respondingGuards = const [],
    this.metadata = const {},
  });

  factory EmergencyAlert.fromMap(Map<String, dynamic> data) {
    return EmergencyAlert(
      alertId: data['alertId'] ?? '',
      companyId: data['companyId'] ?? '',
      alertType: EmergencyAlertType.values.firstWhere(
        (type) => type.name == (data['alertType'] ?? 'systemAlert'),
        orElse: () => EmergencyAlertType.systemAlert,
      ),
      severity: CoverageGapSeverity.values.firstWhere(
        (sev) => sev.name == (data['severity'] ?? 'medium'),
        orElse: () => CoverageGapSeverity.medium,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      guardId: data['guardId'],
      jobId: data['jobId'],
      location: data['location'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      resolvedAt: data['resolvedAt'] is Timestamp 
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      resolvedBy: data['resolvedBy'],
      isResolved: data['isResolved'] ?? false,
      notifiedGuards: List<String>.from(data['notifiedGuards'] ?? []),
      respondingGuards: List<String>.from(data['respondingGuards'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'companyId': companyId,
      'alertType': alertType.name,
      'severity': severity.name,
      'title': title,
      'description': description,
      'guardId': guardId,
      'jobId': jobId,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'isResolved': isResolved,
      'notifiedGuards': notifiedGuards,
      'respondingGuards': respondingGuards,
      'metadata': metadata,
    };
  }
}

/// Service for managing emergency situations and critical alerts
/// Provides emergency response coordination and escalation protocols
class EmergencyManagementService {
  static final EmergencyManagementService _instance = EmergencyManagementService._internal();
  factory EmergencyManagementService() => _instance;
  EmergencyManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream controllers for real-time emergency updates
  final StreamController<List<EmergencyAlert>> _emergencyAlertsController = 
      StreamController<List<EmergencyAlert>>.broadcast();
  final StreamController<EmergencyAlert> _newEmergencyController = 
      StreamController<EmergencyAlert>.broadcast();

  // Emergency management state
  StreamSubscription<QuerySnapshot>? _alertsSubscription;
  Timer? _escalationTimer;
  
  String? _currentCompanyId;
  final Map<String, Timer> _responseTimers = {};

  /// Get stream of emergency alerts for a company
  Stream<List<EmergencyAlert>> get emergencyAlertsStream => _emergencyAlertsController.stream;

  /// Get stream of new emergency alerts
  Stream<EmergencyAlert> get newEmergencyStream => _newEmergencyController.stream;

  /// Initialize emergency management for a company
  Future<void> initializeEmergencyManagement(String companyId) async {
    try {
      _currentCompanyId = companyId;

      // Start listening to emergency alerts
      _alertsSubscription = _firestore
          .collection('emergency_alerts')
          .where('companyId', isEqualTo: companyId)
          .where('isResolved', isEqualTo: false)
          .orderBy('severity', descending: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        final alerts = snapshot.docs
            .map((doc) => EmergencyAlert.fromMap(doc.data()))
            .toList();
        
        if (!_emergencyAlertsController.isClosed) {
          _emergencyAlertsController.add(alerts);
        }

        // Check for new alerts that need immediate attention
        for (final alert in alerts) {
          if (alert.severity == CoverageGapSeverity.critical) {
            _handleCriticalAlert(alert);
          }
        }
      });

      // Set up escalation timer (check every 2 minutes)
      _escalationTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
        _checkForEscalation();
      });

      if (kDebugMode) {
        developer.log('Emergency management initialized for company: $companyId', name: 'EmergencyManagementService', level: 1000);
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error initializing emergency management: $e', name: 'EmergencyManagementService', level: 1000);
      }
    }
  }

  /// Trigger an emergency alert
  Future<String> triggerEmergencyAlert({
    required EmergencyAlertType alertType,
    required CoverageGapSeverity severity,
    required String title,
    required String description,
    String? guardId,
    String? jobId,
    String? location,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_currentCompanyId == null) {
        throw Exception('Company ID not set');
      }

      final alertId = 'alert_${DateTime.now().millisecondsSinceEpoch}';
      
      final alert = EmergencyAlert(
        alertId: alertId,
        companyId: _currentCompanyId!,
        alertType: alertType,
        severity: severity,
        title: title,
        description: description,
        guardId: guardId,
        jobId: jobId,
        location: location,
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      // Save to Firestore
      await _firestore
          .collection('emergency_alerts')
          .doc(alertId)
          .set(alert.toMap());

      // Notify available guards
      await _notifyAvailableGuards(alert);

      // Set up response timer for escalation
      _setResponseTimer(alert);

      // Emit new emergency alert
      if (!_newEmergencyController.isClosed) {
        _newEmergencyController.add(alert);
      }

      if (kDebugMode) {
        developer.log('Emergency alert triggered: $alertId (${severity.name})', name: 'EmergencyManagementService', level: 1000);
      }

      return alertId;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error triggering emergency alert: $e', name: 'EmergencyManagementService', level: 1000);
      }
      rethrow;
    }
  }

  /// Handle critical alerts with immediate response
  Future<void> _handleCriticalAlert(EmergencyAlert alert) async {
    try {
      // For critical alerts, notify all available guards immediately
      await _notifyAllAvailableGuards(alert);
      
      // Update team emergency status
      await _updateTeamEmergencyStatus(EmergencyStatus.critical);

      if (kDebugMode) {
        print('Critical alert handled: ${alert.alertId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling critical alert: $e');
      }
    }
  }

  /// Notify available guards about an emergency
  Future<void> _notifyAvailableGuards(EmergencyAlert alert) async {
    try {
      // Get available guards near the emergency location
      final availableGuards = await _getAvailableGuardsNearLocation(
        alert.latitude ?? 0.0,
        alert.longitude ?? 0.0,
        radiusKm: alert.severity == CoverageGapSeverity.critical ? 50.0 : 25.0,
      );

      final guardIds = availableGuards.map((guard) => guard.guardId).toList();

      // Update alert with notified guards
      await _firestore
          .collection('emergency_alerts')
          .doc(alert.alertId)
          .update({
        'notifiedGuards': guardIds,
      });

      // TODO: Send push notifications to guards
      // This would integrate with your notification service

      if (kDebugMode) {
        print('Notified ${guardIds.length} guards about emergency: ${alert.alertId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error notifying guards: $e');
      }
    }
  }

  /// Notify all available guards (for critical emergencies)
  Future<void> _notifyAllAvailableGuards(EmergencyAlert alert) async {
    try {
      final guardSnapshot = await _firestore
          .collection('guard_locations')
          .where('companyId', isEqualTo: _currentCompanyId)
          .where('status', isEqualTo: 'available')
          .get();

      final guardIds = guardSnapshot.docs.map((doc) => doc.id).toList();

      await _firestore
          .collection('emergency_alerts')
          .doc(alert.alertId)
          .update({
        'notifiedGuards': guardIds,
      });

      if (kDebugMode) {
        print('Notified all ${guardIds.length} available guards about critical emergency');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error notifying all guards: $e');
      }
    }
  }

  /// Get available guards near a location
  Future<List<GuardLocationData>> _getAvailableGuardsNearLocation(
    double latitude,
    double longitude, {
    double radiusKm = 25.0,
  }) async {
    try {
      final guardSnapshot = await _firestore
          .collection('guard_locations')
          .where('companyId', isEqualTo: _currentCompanyId)
          .where('status', isEqualTo: 'available')
          .where('isLocationEnabled', isEqualTo: true)
          .get();

      final nearbyGuards = <GuardLocationData>[];
      
      for (final doc in guardSnapshot.docs) {
        final guard = GuardLocationData.fromFirestore(doc);
        if (guard.latitude != null && guard.longitude != null) {
          final distance = _calculateDistance(
            latitude, longitude,
            guard.latitude!, guard.longitude!,
          );
          
          if (distance <= radiusKm) {
            nearbyGuards.add(guard);
          }
        }
      }

      // Sort by distance
      nearbyGuards.sort((a, b) {
        final distanceA = _calculateDistance(latitude, longitude, a.latitude!, a.longitude!);
        final distanceB = _calculateDistance(latitude, longitude, b.latitude!, b.longitude!);
        return distanceA.compareTo(distanceB);
      });

      return nearbyGuards;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting nearby guards: $e');
      }
      return [];
    }
  }

  /// Calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    
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

  /// Set response timer for escalation
  void _setResponseTimer(EmergencyAlert alert) {
    final responseTimeLimit = switch (alert.severity) {
      CoverageGapSeverity.critical => const Duration(minutes: 5),
      CoverageGapSeverity.high => const Duration(minutes: 10),
      CoverageGapSeverity.medium => const Duration(minutes: 20),
      CoverageGapSeverity.low => const Duration(minutes: 30),
    };

    _responseTimers[alert.alertId] = Timer(responseTimeLimit, () {
      _escalateAlert(alert.alertId);
    });
  }

  /// Escalate an alert if no response received
  Future<void> _escalateAlert(String alertId) async {
    try {
      final alertDoc = await _firestore
          .collection('emergency_alerts')
          .doc(alertId)
          .get();

      if (!alertDoc.exists) return;

      final alert = EmergencyAlert.fromMap(alertDoc.data() as Map<String, dynamic>);
      
      if (alert.isResolved || alert.respondingGuards.isNotEmpty) {
        return; // Already resolved or has responders
      }

      // Escalate severity
      final newSeverity = switch (alert.severity) {
        CoverageGapSeverity.low => CoverageGapSeverity.medium,
        CoverageGapSeverity.medium => CoverageGapSeverity.high,
        CoverageGapSeverity.high => CoverageGapSeverity.critical,
        CoverageGapSeverity.critical => CoverageGapSeverity.critical, // Already max
      };

      await _firestore
          .collection('emergency_alerts')
          .doc(alertId)
          .update({
        'severity': newSeverity.name,
        'metadata.escalated': true,
        'metadata.escalatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Notify more guards if escalated to critical
      if (newSeverity == CoverageGapSeverity.critical) {
        await _notifyAllAvailableGuards(alert);
      }

      if (kDebugMode) {
        print('Alert escalated: $alertId -> ${newSeverity.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error escalating alert: $e');
      }
    }
  }

  /// Check for alerts that need escalation
  Future<void> _checkForEscalation() async {
    try {
      final now = DateTime.now();
      final alertsSnapshot = await _firestore
          .collection('emergency_alerts')
          .where('companyId', isEqualTo: _currentCompanyId)
          .where('isResolved', isEqualTo: false)
          .get();

      for (final doc in alertsSnapshot.docs) {
        final alert = EmergencyAlert.fromMap(doc.data());
        final timeSinceCreated = now.difference(alert.createdAt);
        
        // Check if alert needs escalation based on time and lack of response
        final shouldEscalate = switch (alert.severity) {
          CoverageGapSeverity.low => timeSinceCreated.inMinutes > 30,
          CoverageGapSeverity.medium => timeSinceCreated.inMinutes > 20,
          CoverageGapSeverity.high => timeSinceCreated.inMinutes > 10,
          CoverageGapSeverity.critical => timeSinceCreated.inMinutes > 5,
        };

        if (shouldEscalate && alert.respondingGuards.isEmpty) {
          await _escalateAlert(alert.alertId);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for escalation: $e');
      }
    }
  }

  /// Guard responds to an emergency alert
  Future<void> respondToEmergency(String alertId, String guardId) async {
    try {
      await _firestore
          .collection('emergency_alerts')
          .doc(alertId)
          .update({
        'respondingGuards': FieldValue.arrayUnion([guardId]),
        'metadata.responseTime': Timestamp.fromDate(DateTime.now()),
      });

      // Cancel response timer since we have a responder
      _responseTimers[alertId]?.cancel();
      _responseTimers.remove(alertId);

      if (kDebugMode) {
        print('Guard $guardId responded to emergency: $alertId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error recording emergency response: $e');
      }
      rethrow;
    }
  }

  /// Resolve an emergency alert
  Future<void> resolveEmergencyAlert(
    String alertId, 
    String resolvedBy, {
    String? resolutionNotes,
  }) async {
    try {
      await _firestore
          .collection('emergency_alerts')
          .doc(alertId)
          .update({
        'isResolved': true,
        'resolvedAt': Timestamp.fromDate(DateTime.now()),
        'resolvedBy': resolvedBy,
        'metadata.resolutionNotes': resolutionNotes,
      });

      // Cancel any pending timers
      _responseTimers[alertId]?.cancel();
      _responseTimers.remove(alertId);

      // Check if we can downgrade team emergency status
      await _checkAndUpdateEmergencyStatus();

      if (kDebugMode) {
        print('Emergency alert resolved: $alertId by $resolvedBy');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resolving emergency alert: $e');
      }
      rethrow;
    }
  }

  /// Update team emergency status
  Future<void> _updateTeamEmergencyStatus(EmergencyStatus status) async {
    try {
      await _firestore
          .collection('team_status')
          .doc(_currentCompanyId)
          .update({
        'emergencyStatus': status.name,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating team emergency status: $e');
      }
    }
  }

  /// Check and update emergency status based on active alerts
  Future<void> _checkAndUpdateEmergencyStatus() async {
    try {
      final alertsSnapshot = await _firestore
          .collection('emergency_alerts')
          .where('companyId', isEqualTo: _currentCompanyId)
          .where('isResolved', isEqualTo: false)
          .get();

      if (alertsSnapshot.docs.isEmpty) {
        await _updateTeamEmergencyStatus(EmergencyStatus.normal);
        return;
      }

      // Determine highest severity
      var highestSeverity = CoverageGapSeverity.low;
      for (final doc in alertsSnapshot.docs) {
        final alert = EmergencyAlert.fromMap(doc.data());
        if (alert.severity.index > highestSeverity.index) {
          highestSeverity = alert.severity;
        }
      }

      final emergencyStatus = switch (highestSeverity) {
        CoverageGapSeverity.low => EmergencyStatus.normal,
        CoverageGapSeverity.medium => EmergencyStatus.warning,
        CoverageGapSeverity.high => EmergencyStatus.critical,
        CoverageGapSeverity.critical => EmergencyStatus.emergency,
      };

      await _updateTeamEmergencyStatus(emergencyStatus);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking emergency status: $e');
      }
    }
  }

  /// Dispose of resources and close streams
  void dispose() {
    _alertsSubscription?.cancel();
    _escalationTimer?.cancel();
    
    // Cancel all response timers
    for (final timer in _responseTimers.values) {
      timer.cancel();
    }
    _responseTimers.clear();
    
    _emergencyAlertsController.close();
    _newEmergencyController.close();
    
    if (kDebugMode) {
      print('EmergencyManagementService disposed');
    }
  }
}
