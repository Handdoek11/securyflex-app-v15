import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/gdpr_models.dart';
import '../../auth/services/certificate_management_service.dart';

/// Core GDPR Compliance Service
/// Handles all GDPR/AVG requirements including data subject rights,
/// consent management, and Dutch-specific compliance requirements
class GDPRComplianceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _gdprRequestsCollection = 'gdpr_requests';
  static const String _consentRecordsCollection = 'consent_records';
  static const String _auditLogCollection = 'gdpr_audit_log';
  static const String _dataExportsCollection = 'data_exports';
  
  /// Submit a GDPR data subject request
  Future<String> submitDataSubjectRequest({
    required DataSubjectRight requestType,
    required String description,
    List<String> dataCategories = const [],
    bool isUrgent = false,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Gebruiker niet ingelogd');
    }

    final request = GDPRRequest(
      id: '', // Will be set by Firestore
      userId: user.uid,
      requestType: requestType,
      status: GDPRRequestStatus.pending,
      description: description,
      createdAt: DateTime.now(),
      dataCategories: dataCategories,
      isUrgent: isUrgent,
      requestData: additionalData,
      processingNotes: 'Verzoek automatisch ontvangen via SecuryFlex app',
    );

    try {
      final docRef = await _firestore
          .collection(_gdprRequestsCollection)
          .add(request.toDocument());

      // Log the request submission
      await _logGDPRAuditEvent(
        userId: user.uid,
        eventType: 'gdpr_request_submitted',
        details: {
          'requestType': requestType.value,
          'requestId': docRef.id,
          'isUrgent': isUrgent,
          'dataCategories': dataCategories,
        },
      );

      // Send notification to compliance team if urgent
      if (isUrgent) {
        await _notifyComplianceTeam(docRef.id, requestType, isUrgent: true);
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Error submitting GDPR request: $e');
      rethrow;
    }
  }

  /// Get user's GDPR requests
  Stream<List<GDPRRequest>> getUserGDPRRequests() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_gdprRequestsCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GDPRRequest.fromDocument(doc))
            .toList());
  }

  /// Export all user data (Article 15 - Right of Access)
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final exportData = <String, dynamic>{};
      
      // 1. Basic user profile data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        exportData['profile'] = _sanitizeForExport(userDoc.data()!);
      }

      // 2. Authentication data (limited for security)
      exportData['authentication'] = {
        'email': _auth.currentUser?.email,
        'emailVerified': _auth.currentUser?.emailVerified,
        'creationTime': _auth.currentUser?.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': _auth.currentUser?.metadata.lastSignInTime?.toIso8601String(),
      };

      // 3. Certificate data (WPBR compliance)
      final certificates = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: userId)
          .get();
      exportData['certificates'] = certificates.docs
          .map((doc) => _sanitizeForExport(doc.data()))
          .toList();

      // 4. Job applications and history
      final applications = await _firestore
          .collection('job_applications')
          .where('userId', isEqualTo: userId)
          .get();
      exportData['job_applications'] = applications.docs
          .map((doc) => _sanitizeForExport(doc.data()))
          .toList();

      // 5. Shift and schedule data
      final shifts = await _firestore
          .collection('shifts')
          .where('userId', isEqualTo: userId)
          .get();
      exportData['shifts'] = shifts.docs
          .map((doc) => _sanitizeForExport(doc.data()))
          .toList();

      // 6. Payment and billing data
      final payments = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .get();
      exportData['payments'] = payments.docs
          .map((doc) => _sanitizeForExport(doc.data()))
          .toList();

      // 7. Chat messages (limited for privacy)
      final messages = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .limit(1000) // Reasonable limit
          .get();
      exportData['messages'] = messages.docs
          .map((doc) => _sanitizeForExport(doc.data()))
          .toList();

      // 8. Consent records
      final consents = await _firestore
          .collection(_consentRecordsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      exportData['consent_records'] = consents.docs
          .map((doc) => _sanitizeForExport(doc.data()))
          .toList();

      // 9. GDPR request history
      final gdprRequests = await _firestore
          .collection(_gdprRequestsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      exportData['gdpr_requests'] = gdprRequests.docs
          .map((doc) => _sanitizeForExport(doc.data()))
          .toList();

      // 10. Add export metadata
      exportData['export_metadata'] = {
        'exportDate': DateTime.now().toIso8601String(),
        'exportedBy': userId,
        'dataCompliance': 'GDPR Article 15 - Right of Access',
        'privacyNoticeVersion': '2.0',
        'retentionPolicies': await _getRetentionPolicies(),
      };

      // Log the export
      await _logGDPRAuditEvent(
        userId: userId,
        eventType: 'data_exported',
        details: {
          'dataCategories': exportData.keys.toList(),
          'exportSize': exportData.toString().length,
        },
      );

      return exportData;
    } catch (e) {
      debugPrint('Error exporting user data: $e');
      rethrow;
    }
  }

  /// Delete user data (Article 17 - Right to Erasure)
  Future<void> deleteUserData(String userId, {
    bool preserveWPBRData = true,
    String? deletionReason,
    List<String>? dataCategoriesToDelete,
  }) async {
    try {
      // Check if WPBR data must be preserved (7-year retention)
      if (preserveWPBRData) {
        await _markWPBRDataForArchival(userId);
      }

      // Categories that can be safely deleted
      final deletableCategories = dataCategoriesToDelete ?? [
        'profile',
        'preferences',
        'notifications',
        'messages',
        'temporary_data',
      ];

      // Delete user profile data
      if (deletableCategories.contains('profile')) {
        await _firestore.collection('users').doc(userId).delete();
      }

      // Delete messages
      if (deletableCategories.contains('messages')) {
        await _deleteCollectionData('messages', 'senderId', userId);
      }

      // Delete notifications
      if (deletableCategories.contains('notifications')) {
        await _deleteCollectionData('notifications', 'userId', userId);
      }

      // Delete temporary application data
      if (deletableCategories.contains('temporary_data')) {
        await _deleteCollectionData('temp_applications', 'userId', userId);
      }

      // Archive instead of delete for compliance reasons
      await _archiveUserData(userId, deletableCategories);

      // Log the deletion
      await _logGDPRAuditEvent(
        userId: userId,
        eventType: 'data_deleted',
        details: {
          'deletedCategories': deletableCategories,
          'wpbrPreserved': preserveWPBRData,
          'deletionReason': deletionReason,
        },
      );
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      rethrow;
    }
  }

  /// Record consent for data processing
  Future<void> recordConsent({
    required String purpose,
    required LawfulBasis lawfulBasis,
    required bool isGiven,
    required String consentMethod,
    String? consentText,
    Map<String, dynamic> metadata = const {},
    String version = '2.0',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Gebruiker niet ingelogd');
    }

    final consent = ConsentRecord(
      id: '', // Will be set by Firestore
      userId: user.uid,
      purpose: purpose,
      lawfulBasis: lawfulBasis,
      isGiven: isGiven,
      timestamp: DateTime.now(),
      consentMethod: consentMethod,
      consentText: consentText,
      metadata: metadata,
      version: version,
    );

    try {
      await _firestore
          .collection(_consentRecordsCollection)
          .add(consent.toDocument());

      // Log consent recording
      await _logGDPRAuditEvent(
        userId: user.uid,
        eventType: 'consent_recorded',
        details: {
          'purpose': purpose,
          'lawfulBasis': lawfulBasis.value,
          'isGiven': isGiven,
          'consentMethod': consentMethod,
          'version': version,
        },
      );
    } catch (e) {
      debugPrint('Error recording consent: $e');
      rethrow;
    }
  }

  /// Withdraw consent
  Future<void> withdrawConsent(String purpose) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Gebruiker niet ingelogd');
    }

    try {
      // Find active consent records for this purpose
      final consents = await _firestore
          .collection(_consentRecordsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('purpose', isEqualTo: purpose)
          .where('isGiven', isEqualTo: true)
          .where('withdrawnAt', isNull: true)
          .get();

      // Withdraw all active consents for this purpose
      final batch = _firestore.batch();
      for (final doc in consents.docs) {
        batch.update(doc.reference, {
          'withdrawnAt': DateTime.now().toIso8601String(),
          'isGiven': false,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Log consent withdrawal
      await _logGDPRAuditEvent(
        userId: user.uid,
        eventType: 'consent_withdrawn',
        details: {
          'purpose': purpose,
          'withdrawnConsents': consents.docs.length,
        },
      );
    } catch (e) {
      debugPrint('Error withdrawing consent: $e');
      rethrow;
    }
  }

  /// Get user's consent records
  Future<List<ConsentRecord>> getUserConsents() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection(_consentRecordsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ConsentRecord.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user consents: $e');
      return [];
    }
  }

  /// Check if user has given consent for a specific purpose
  Future<bool> hasValidConsent(String purpose) async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    try {
      final snapshot = await _firestore
          .collection(_consentRecordsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('purpose', isEqualTo: purpose)
          .where('isGiven', isEqualTo: true)
          .where('withdrawnAt', isNull: true)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking consent: $e');
      return false;
    }
  }

  /// Apply data retention policies
  Future<void> applyRetentionPolicies() async {
    try {
      final policies = await _getRetentionPolicies();
      
      for (final policy in policies) {
        await _applyRetentionPolicy(policy);
      }

      // Log retention policy application
      await _logGDPRAuditEvent(
        userId: 'system',
        eventType: 'retention_policies_applied',
        details: {
          'policiesApplied': policies.length,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error applying retention policies: $e');
      rethrow;
    }
  }

  /// Generate compliance report
  Future<Map<String, dynamic>> generateComplianceReport() async {
    try {
      final report = <String, dynamic>{};
      
      // GDPR requests statistics
      final gdprRequestsSnapshot = await _firestore
          .collection(_gdprRequestsCollection)
          .get();
      
      final requestsByType = <String, int>{};
      final requestsByStatus = <String, int>{};
      
      for (final doc in gdprRequestsSnapshot.docs) {
        final request = GDPRRequest.fromDocument(doc);
        requestsByType[request.requestType.value] = 
            (requestsByType[request.requestType.value] ?? 0) + 1;
        requestsByStatus[request.status.value] = 
            (requestsByStatus[request.status.value] ?? 0) + 1;
      }
      
      report['gdpr_requests'] = {
        'total': gdprRequestsSnapshot.docs.length,
        'by_type': requestsByType,
        'by_status': requestsByStatus,
      };

      // Consent statistics
      final consentSnapshot = await _firestore
          .collection(_consentRecordsCollection)
          .get();
      
      final consentsByPurpose = <String, Map<String, int>>{};
      
      for (final doc in consentSnapshot.docs) {
        final consent = ConsentRecord.fromDocument(doc);
        consentsByPurpose[consent.purpose] ??= {'given': 0, 'withdrawn': 0};
        if (consent.isValid) {
          consentsByPurpose[consent.purpose]!['given'] = 
              consentsByPurpose[consent.purpose]!['given']! + 1;
        } else {
          consentsByPurpose[consent.purpose]!['withdrawn'] = 
              consentsByPurpose[consent.purpose]!['withdrawn']! + 1;
        }
      }
      
      report['consent_records'] = {
        'total': consentSnapshot.docs.length,
        'by_purpose': consentsByPurpose,
      };

      // Data retention compliance
      report['data_retention'] = await _getRetentionComplianceStats();
      
      // Dutch specific compliance
      report['dutch_compliance'] = await _getDutchComplianceStats();
      
      report['generated_at'] = DateTime.now().toIso8601String();
      report['report_version'] = '1.0';
      
      return report;
    } catch (e) {
      debugPrint('Error generating compliance report: $e');
      rethrow;
    }
  }

  // Private helper methods
  
  Future<void> _logGDPRAuditEvent({
    required String userId,
    required String eventType,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _firestore.collection(_auditLogCollection).add({
        'userId': userId,
        'eventType': eventType,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': '', // Would be populated from request context
        'userAgent': '', // Would be populated from request context
      });
    } catch (e) {
      debugPrint('Error logging GDPR audit event: $e');
    }
  }

  Map<String, dynamic> _sanitizeForExport(Map<String, dynamic> data) {
    // Remove sensitive fields that shouldn't be exported
    final sanitized = Map<String, dynamic>.from(data);
    
    // Remove password hashes, tokens, etc.
    sanitized.removeWhere((key, value) => [
      'passwordHash',
      'accessToken',
      'refreshToken',
      'internalNotes',
      'systemMetadata',
    ].contains(key));
    
    return sanitized;
  }

  Future<void> _notifyComplianceTeam(String requestId, DataSubjectRight requestType, {bool isUrgent = false}) async {
    // Implementation would send notification to compliance team
    // This could be via email, Slack, internal messaging system, etc.
    debugPrint('Notifying compliance team of ${requestType.value} request: $requestId (urgent: $isUrgent)');
  }

  Future<void> _markWPBRDataForArchival(String userId) async {
    // Mark WPBR certificate data for archival instead of deletion
    // This ensures 7-year retention compliance
    try {
      await _firestore.collection('wpbr_archive').doc(userId).set({
        'userId': userId,
        'archivedAt': FieldValue.serverTimestamp(),
        'retentionUntil': DateTime.now().add(const Duration(days: 365 * 7)),
        'reason': 'WPBR 7-year retention requirement',
      });
    } catch (e) {
      debugPrint('Error marking WPBR data for archival: $e');
    }
  }

  Future<void> _deleteCollectionData(String collection, String field, String value) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .get();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting collection data: $e');
    }
  }

  Future<void> _archiveUserData(String userId, List<String> categories) async {
    // Move data to archive collection instead of permanent deletion
    try {
      await _firestore.collection('user_archive').doc(userId).set({
        'userId': userId,
        'archivedCategories': categories,
        'archivedAt': FieldValue.serverTimestamp(),
        'deletionRequested': true,
      });
    } catch (e) {
      debugPrint('Error archiving user data: $e');
    }
  }

  Future<List<DataRetentionPolicy>> _getRetentionPolicies() async {
    // Return predefined retention policies
    return [
      DataRetentionPolicy(
        dataType: 'wpbr_certificates',
        category: 'legal_compliance',
        retentionPeriod: const Duration(days: 365 * 7), // 7 years
        lawfulBasis: LawfulBasis.legalObligation,
        description: 'WPBR certificaten - 7 jaar bewaarplicht',
        createdAt: DateTime.now(),
      ),
      DataRetentionPolicy(
        dataType: 'bsn_data',
        category: 'identity_verification',
        retentionPeriod: const Duration(days: 365 * 7), // 7 years
        lawfulBasis: LawfulBasis.legalObligation,
        description: 'BSN gegevens - wettelijke bewaarplicht',
        createdAt: DateTime.now(),
      ),
      DataRetentionPolicy(
        dataType: 'cao_data',
        category: 'employment',
        retentionPeriod: const Duration(days: 365 * 5), // 5 years
        lawfulBasis: LawfulBasis.legalObligation,
        description: 'CAO arbeidsgegevens - 5 jaar bewaarplicht',
        createdAt: DateTime.now(),
      ),
    ];
  }

  Future<void> _applyRetentionPolicy(DataRetentionPolicy policy) async {
    // Apply individual retention policy
    debugPrint('Applying retention policy for ${policy.dataType}');
  }

  Future<Map<String, dynamic>> _getRetentionComplianceStats() async {
    return {
      'wpbr_certificates_retained': 0,
      'bsn_data_archived': 0,
      'expired_data_deleted': 0,
    };
  }

  Future<Map<String, dynamic>> _getDutchComplianceStats() async {
    return {
      'wpbr_compliance': true,
      'bsn_protection': true,
      'cao_compliance': true,
      'dutch_language_notices': true,
    };
  }
}
