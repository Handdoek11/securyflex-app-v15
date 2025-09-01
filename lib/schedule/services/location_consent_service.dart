import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types of location consent required
enum LocationConsentType {
  workVerification,     // Check-in/check-out verification only
  shiftMonitoring,      // Periodic location pings during shifts
  emergencyTracking,    // Emergency response location sharing
  companyMonitoring,    // Real-time location visible to company
}

/// Consent status
enum ConsentStatus {
  notRequested,
  granted,
  denied,
  withdrawn,
  expired,
}

/// Location Consent Management Service - GDPR Article 9 Compliance
/// 
/// Manages explicit consent for special category location data processing
/// as required under Nederlandse AVG (GDPR) for security guards.
/// 
/// Features:
/// - Explicit consent for location tracking
/// - Granular permissions (work verification vs continuous tracking)
/// - Consent withdrawal mechanisms
/// - Audit trail for consent changes
/// - Nederlandse arbeidsrecht compliance
class LocationConsentService {
  static const String _consentKeyPrefix = 'location_consent_';
  static const String _lastConsentUpdate = 'last_consent_update';
  static const Duration _consentValidityPeriod = Duration(days: 365); // Annual renewal

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user has granted specific location consent
  static Future<bool> hasValidConsent(
    String userId,
    LocationConsentType type,
  ) async {
    try {
      final consent = await getConsentStatus(userId, type);
      return consent.status == ConsentStatus.granted && !consent.isExpired;
    } catch (e) {
      print('Error checking location consent: $e');
      return false;
    }
  }

  /// Get detailed consent status for specific type
  static Future<LocationConsent> getConsentStatus(
    String userId,
    LocationConsentType type,
  ) async {
    try {
      final doc = await _firestore
          .collection('location_consent')
          .doc('${userId}_${type.toString().split('.').last}')
          .get();

      if (!doc.exists) {
        return LocationConsent(
          userId: userId,
          consentType: type,
          status: ConsentStatus.notRequested,
          grantedAt: null,
          expiresAt: null,
          lastUpdated: DateTime.now(),
        );
      }

      return LocationConsent.fromFirestore(doc);
    } catch (e) {
      throw LocationConsentException(
        'Toestemming status ophalen mislukt: $e',
        LocationConsentErrorType.statusCheckFailed,
      );
    }
  }

  /// Request explicit consent for location processing
  static Future<LocationConsent> requestConsent(
    String userId, {
    required LocationConsentType consentType,
    required String businessJustification,
    required Map<String, dynamic> userInfo,
    String? specificPurpose,
  }) async {
    try {
      final now = DateTime.now();
      final expiryDate = now.add(_consentValidityPeriod);
      
      final consentRecord = LocationConsent(
        userId: userId,
        consentType: consentType,
        status: ConsentStatus.granted,
        grantedAt: now,
        expiresAt: expiryDate,
        lastUpdated: now,
        businessJustification: businessJustification,
        specificPurpose: specificPurpose,
        userInfo: userInfo,
        consentVersion: '2.0',
        gdprBasis: 'Article 9 - Explicit consent for special category data',
        nederlandseWetBasis: 'Arbeidsrecht - Locatiegegevens werknemer',
      );

      // Store consent in Firestore
      await _firestore
          .collection('location_consent')
          .doc('${userId}_${consentType.toString().split('.').last}')
          .set(consentRecord.toFirestore());

      // Store locally for quick access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        '$_consentKeyPrefix${consentType.toString().split('.').last}', 
        true
      );
      await prefs.setString(_lastConsentUpdate, now.toIso8601String());

      // Create audit log
      await _createConsentAuditLog(userId, consentRecord, 'CONSENT_GRANTED');

      return consentRecord;
    } catch (e) {
      throw LocationConsentException(
        'Toestemming verlenen mislukt: $e',
        LocationConsentErrorType.consentGrantFailed,
      );
    }
  }

  /// Withdraw consent (right to withdraw under GDPR)
  static Future<LocationConsent> withdrawConsent(
    String userId,
    LocationConsentType consentType, {
    required String withdrawalReason,
  }) async {
    try {
      final currentConsent = await getConsentStatus(userId, consentType);
      
      final updatedConsent = currentConsent.copyWith(
        status: ConsentStatus.withdrawn,
        withdrawnAt: DateTime.now(),
        withdrawalReason: withdrawalReason,
        lastUpdated: DateTime.now(),
      );

      // Update consent in Firestore
      await _firestore
          .collection('location_consent')
          .doc('${userId}_${consentType.toString().split('.').last}')
          .update(updatedConsent.toFirestore());

      // Remove from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(
        '$_consentKeyPrefix${consentType.toString().split('.').last}'
      );

      // Create audit log
      await _createConsentAuditLog(userId, updatedConsent, 'CONSENT_WITHDRAWN');

      // Trigger data deletion if required
      if (consentType == LocationConsentType.companyMonitoring ||
          consentType == LocationConsentType.shiftMonitoring) {
        await _scheduleLocationDataDeletion(userId, consentType);
      }

      return updatedConsent;
    } catch (e) {
      throw LocationConsentException(
        'Toestemming intrekken mislukt: $e',
        LocationConsentErrorType.consentWithdrawalFailed,
      );
    }
  }

  /// Check if consent needs renewal
  static Future<List<LocationConsent>> checkConsentRenewal(String userId) async {
    final expiringConsents = <LocationConsent>[];

    for (final type in LocationConsentType.values) {
      try {
        final consent = await getConsentStatus(userId, type);
        
        if (consent.status == ConsentStatus.granted && 
            consent.expiresAt != null) {
          final daysUntilExpiry = consent.expiresAt!
              .difference(DateTime.now())
              .inDays;
          
          // Notify 30 days before expiry
          if (daysUntilExpiry <= 30 && daysUntilExpiry > 0) {
            expiringConsents.add(consent);
          }
        }
      } catch (e) {
        print('Error checking consent renewal for $type: $e');
      }
    }

    return expiringConsents;
  }

  /// Get all consent statuses for user
  static Future<Map<LocationConsentType, LocationConsent>> getAllConsentStatuses(
    String userId,
  ) async {
    final consentMap = <LocationConsentType, LocationConsent>{};

    for (final type in LocationConsentType.values) {
      try {
        consentMap[type] = await getConsentStatus(userId, type);
      } catch (e) {
        print('Error getting consent for $type: $e');
      }
    }

    return consentMap;
  }

  /// Create comprehensive consent dashboard data
  static Future<ConsentDashboard> getConsentDashboard(String userId) async {
    try {
      final allConsents = await getAllConsentStatuses(userId);
      final auditLogs = await getConsentAuditLogs(userId, limit: 50);
      
      return ConsentDashboard(
        userId: userId,
        lastUpdated: DateTime.now(),
        consentStatuses: allConsents,
        recentAuditLogs: auditLogs,
        dataRetentionInfo: {
          'work_verification': '24 hours (raw data), 90 days (verification results)',
          'shift_monitoring': '24 hours (raw data), 90 days (verification results)',
          'emergency_tracking': '24 hours (raw data), 7 days (emergency records)',
          'audit_logs': '7 years (legal requirement)',
        },
        privacyRights: [
          'Recht op informatie (Art. 13-14 AVG)',
          'Recht op inzage (Art. 15 AVG)',
          'Recht op rectificatie (Art. 16 AVG)',
          'Recht op gegevenswissing (Art. 17 AVG)',
          'Recht op beperking verwerking (Art. 18 AVG)',
          'Recht op overdraagbaarheid (Art. 20 AVG)',
          'Recht van bezwaar (Art. 21 AVG)',
        ],
      );
    } catch (e) {
      throw LocationConsentException(
        'Toestemming dashboard ophalen mislukt: $e',
        LocationConsentErrorType.dashboardLoadFailed,
      );
    }
  }

  /// Get consent audit logs for transparency
  static Future<List<ConsentAuditLog>> getConsentAuditLogs(
    String userId, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('location_consent_audit')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ConsentAuditLog.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw LocationConsentException(
        'Audit logs ophalen mislukt: $e',
        LocationConsentErrorType.auditLogFailed,
      );
    }
  }

  /// Validate Nederlandse arbeidsrecht compliance
  static Future<ComplianceStatus> validateArbeidsrechtCompliance(
    String userId,
    String companyId,
  ) async {
    try {
      final violations = <String>[];
      final allConsents = await getAllConsentStatuses(userId);

      // Check if company monitoring requires explicit consent
      final companyConsent = allConsents[LocationConsentType.companyMonitoring];
      if (companyConsent?.status != ConsentStatus.granted) {
        violations.add('Company monitoring zonder expliciete toestemming werknemer');
      }

      // Check if work verification has proper business justification
      final workConsent = allConsents[LocationConsentType.workVerification];
      if (workConsent?.businessJustification?.isEmpty ?? true) {
        violations.add('Work verification zonder rechtmatige bedrijfsgrond');
      }

      // Check consent expiry
      for (final entry in allConsents.entries) {
        final consent = entry.value;
        if (consent.status == ConsentStatus.expired) {
          violations.add('Verlopen toestemming voor ${entry.key.toString().split('.').last}');
        }
      }

      return ComplianceStatus(
        userId: userId,
        companyId: companyId,
        isCompliant: violations.isEmpty,
        violations: violations,
        checkedAt: DateTime.now(),
        nextCheckDue: DateTime.now().add(const Duration(days: 30)),
      );
    } catch (e) {
      throw LocationConsentException(
        'Arbeidsrecht compliance check mislukt: $e',
        LocationConsentErrorType.complianceCheckFailed,
      );
    }
  }

  /// Create consent audit log for transparency
  static Future<void> _createConsentAuditLog(
    String userId,
    LocationConsent consent,
    String action,
  ) async {
    try {
      final auditLog = ConsentAuditLog(
        userId: userId,
        consentType: consent.consentType,
        action: action,
        timestamp: DateTime.now(),
        consentStatus: consent.status,
        details: {
          'consent_version': consent.consentVersion,
          'business_justification': consent.businessJustification,
          'gdpr_basis': consent.gdprBasis,
          'expires_at': consent.expiresAt?.toIso8601String(),
          'withdrawal_reason': consent.withdrawalReason,
        },
        ipAddress: 'mobile_app', // Would capture actual IP in web version
        userAgent: 'SecuryFlex Mobile App',
      );

      await _firestore
          .collection('location_consent_audit')
          .add(auditLog.toFirestore());
    } catch (e) {
      print('Failed to create consent audit log: $e');
      // Don't throw - audit log failure shouldn't block consent operations
    }
  }

  /// Schedule location data deletion when consent is withdrawn
  static Future<void> _scheduleLocationDataDeletion(
    String userId,
    LocationConsentType consentType,
  ) async {
    try {
      await _firestore
          .collection('data_deletion_schedule')
          .add({
        'userId': userId,
        'dataType': 'location_data',
        'consentType': consentType.toString(),
        'scheduledFor': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'reason': 'consent_withdrawn',
        'gdprBasis': 'Article 17 - Right to erasure',
        'status': 'scheduled',
      });
    } catch (e) {
      print('Failed to schedule location data deletion: $e');
    }
  }

  /// Export all consent data for user (GDPR Subject Access Request)
  static Future<Map<String, dynamic>> exportConsentData(String userId) async {
    try {
      final allConsents = await getAllConsentStatuses(userId);
      final auditLogs = await getConsentAuditLogs(userId);

      return {
        'export_timestamp': DateTime.now().toIso8601String(),
        'user_id': userId,
        'consent_statuses': allConsents.map(
          (type, consent) => MapEntry(
            type.toString().split('.').last,
            consent.toJson(),
          ),
        ),
        'audit_trail': auditLogs.map((log) => log.toJson()).toList(),
        'gdpr_info': {
          'legal_basis': 'Article 9 - Explicit consent for special category data',
          'nederlandse_wet': 'Arbeidsrecht - Locatiegegevens werknemer',
          'data_controller': 'SecuryFlex B.V.',
          'privacy_officer': 'privacy@securyflex.nl',
        },
      };
    } catch (e) {
      throw LocationConsentException(
        'Consent data export mislukt: $e',
        LocationConsentErrorType.dataExportFailed,
      );
    }
  }

  /// Delete all consent data for user (GDPR Right to Erasure)
  static Future<void> deleteAllConsentData(String userId) async {
    try {
      // Delete consent records
      for (final type in LocationConsentType.values) {
        await _firestore
            .collection('location_consent')
            .doc('${userId}_${type.toString().split('.').last}')
            .delete();
      }

      // Anonymize audit logs (keep for legal compliance)
      final auditSnapshot = await _firestore
          .collection('location_consent_audit')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in auditSnapshot.docs) {
        batch.update(doc.reference, {
          'userId': 'ANONYMIZED_${DateTime.now().millisecondsSinceEpoch}',
          'anonymized': true,
          'anonymized_at': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      for (final type in LocationConsentType.values) {
        await prefs.remove(
          '$_consentKeyPrefix${type.toString().split('.').last}'
        );
      }
      await prefs.remove(_lastConsentUpdate);

    } catch (e) {
      throw LocationConsentException(
        'Consent data verwijdering mislukt: $e',
        LocationConsentErrorType.dataErasureFailed,
      );
    }
  }
}

/// Location consent record
class LocationConsent {
  final String userId;
  final LocationConsentType consentType;
  final ConsentStatus status;
  final DateTime? grantedAt;
  final DateTime? expiresAt;
  final DateTime? withdrawnAt;
  final DateTime lastUpdated;
  final String? businessJustification;
  final String? specificPurpose;
  final Map<String, dynamic>? userInfo;
  final String? withdrawalReason;
  final String? consentVersion;
  final String? gdprBasis;
  final String? nederlandseWetBasis;

  const LocationConsent({
    required this.userId,
    required this.consentType,
    required this.status,
    this.grantedAt,
    this.expiresAt,
    this.withdrawnAt,
    required this.lastUpdated,
    this.businessJustification,
    this.specificPurpose,
    this.userInfo,
    this.withdrawalReason,
    this.consentVersion,
    this.gdprBasis,
    this.nederlandseWetBasis,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  LocationConsent copyWith({
    ConsentStatus? status,
    DateTime? withdrawnAt,
    String? withdrawalReason,
    DateTime? lastUpdated,
  }) {
    return LocationConsent(
      userId: userId,
      consentType: consentType,
      status: status ?? this.status,
      grantedAt: grantedAt,
      expiresAt: expiresAt,
      withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      businessJustification: businessJustification,
      specificPurpose: specificPurpose,
      userInfo: userInfo,
      withdrawalReason: withdrawalReason ?? this.withdrawalReason,
      consentVersion: consentVersion,
      gdprBasis: gdprBasis,
      nederlandseWetBasis: nederlandseWetBasis,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'consentType': consentType.toString().split('.').last,
    'status': status.toString().split('.').last,
    'grantedAt': grantedAt != null ? Timestamp.fromDate(grantedAt!) : null,
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'withdrawnAt': withdrawnAt != null ? Timestamp.fromDate(withdrawnAt!) : null,
    'lastUpdated': Timestamp.fromDate(lastUpdated),
    'businessJustification': businessJustification,
    'specificPurpose': specificPurpose,
    'userInfo': userInfo,
    'withdrawalReason': withdrawalReason,
    'consentVersion': consentVersion,
    'gdprBasis': gdprBasis,
    'nederlandseWetBasis': nederlandseWetBasis,
  };

  factory LocationConsent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationConsent(
      userId: data['userId'],
      consentType: LocationConsentType.values
          .firstWhere((t) => t.toString().split('.').last == data['consentType']),
      status: ConsentStatus.values
          .firstWhere((s) => s.toString().split('.').last == data['status']),
      grantedAt: data['grantedAt']?.toDate(),
      expiresAt: data['expiresAt']?.toDate(),
      withdrawnAt: data['withdrawnAt']?.toDate(),
      lastUpdated: data['lastUpdated'].toDate(),
      businessJustification: data['businessJustification'],
      specificPurpose: data['specificPurpose'],
      userInfo: data['userInfo'],
      withdrawalReason: data['withdrawalReason'],
      consentVersion: data['consentVersion'],
      gdprBasis: data['gdprBasis'],
      nederlandseWetBasis: data['nederlandseWetBasis'],
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'consentType': consentType.toString().split('.').last,
    'status': status.toString().split('.').last,
    'grantedAt': grantedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'withdrawnAt': withdrawnAt?.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
    'isExpired': isExpired,
    'businessJustification': businessJustification,
    'specificPurpose': specificPurpose,
    'withdrawalReason': withdrawalReason,
    'consentVersion': consentVersion,
    'gdprBasis': gdprBasis,
    'nederlandseWetBasis': nederlandseWetBasis,
  };
}

/// Consent audit log for transparency
class ConsentAuditLog {
  final String userId;
  final LocationConsentType consentType;
  final String action;
  final DateTime timestamp;
  final ConsentStatus consentStatus;
  final Map<String, dynamic> details;
  final String? ipAddress;
  final String? userAgent;

  const ConsentAuditLog({
    required this.userId,
    required this.consentType,
    required this.action,
    required this.timestamp,
    required this.consentStatus,
    required this.details,
    this.ipAddress,
    this.userAgent,
  });

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'consentType': consentType.toString().split('.').last,
    'action': action,
    'timestamp': Timestamp.fromDate(timestamp),
    'consentStatus': consentStatus.toString().split('.').last,
    'details': details,
    'ipAddress': ipAddress,
    'userAgent': userAgent,
  };

  factory ConsentAuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConsentAuditLog(
      userId: data['userId'],
      consentType: LocationConsentType.values
          .firstWhere((t) => t.toString().split('.').last == data['consentType']),
      action: data['action'],
      timestamp: data['timestamp'].toDate(),
      consentStatus: ConsentStatus.values
          .firstWhere((s) => s.toString().split('.').last == data['consentStatus']),
      details: Map<String, dynamic>.from(data['details'] ?? {}),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'consentType': consentType.toString().split('.').last,
    'action': action,
    'timestamp': timestamp.toIso8601String(),
    'consentStatus': consentStatus.toString().split('.').last,
    'details': details,
    'ipAddress': ipAddress,
    'userAgent': userAgent,
  };
}

/// Consent dashboard for user transparency
class ConsentDashboard {
  final String userId;
  final DateTime lastUpdated;
  final Map<LocationConsentType, LocationConsent> consentStatuses;
  final List<ConsentAuditLog> recentAuditLogs;
  final Map<String, String> dataRetentionInfo;
  final List<String> privacyRights;

  const ConsentDashboard({
    required this.userId,
    required this.lastUpdated,
    required this.consentStatuses,
    required this.recentAuditLogs,
    required this.dataRetentionInfo,
    required this.privacyRights,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'lastUpdated': lastUpdated.toIso8601String(),
    'consentStatuses': consentStatuses.map(
      (type, consent) => MapEntry(
        type.toString().split('.').last,
        consent.toJson(),
      ),
    ),
    'recentAuditLogs': recentAuditLogs.map((log) => log.toJson()).toList(),
    'dataRetentionInfo': dataRetentionInfo,
    'privacyRights': privacyRights,
  };
}

/// Arbeidsrecht compliance status
class ComplianceStatus {
  final String userId;
  final String companyId;
  final bool isCompliant;
  final List<String> violations;
  final DateTime checkedAt;
  final DateTime nextCheckDue;

  const ComplianceStatus({
    required this.userId,
    required this.companyId,
    required this.isCompliant,
    required this.violations,
    required this.checkedAt,
    required this.nextCheckDue,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'companyId': companyId,
    'isCompliant': isCompliant,
    'violations': violations,
    'checkedAt': checkedAt.toIso8601String(),
    'nextCheckDue': nextCheckDue.toIso8601String(),
  };
}

/// Location consent exception types
enum LocationConsentErrorType {
  statusCheckFailed,
  consentGrantFailed,
  consentWithdrawalFailed,
  dashboardLoadFailed,
  auditLogFailed,
  complianceCheckFailed,
  dataExportFailed,
  dataErasureFailed,
}

/// Location consent exception
class LocationConsentException implements Exception {
  final String message;
  final LocationConsentErrorType type;

  const LocationConsentException(this.message, this.type);

  @override
  String toString() => 'LocationConsentException: $message';
}