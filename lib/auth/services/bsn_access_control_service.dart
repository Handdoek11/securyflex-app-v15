import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bsn_security_service.dart';

/// BSN Access Control Service
/// Implements GDPR Article 9 compliant access control for BSN data
/// Features role-based access, purpose limitation, and comprehensive audit trails
class BSNAccessControlService {
  static const String _auditCollection = 'bsn_audit_logs';
  static const String _accessCollection = 'bsn_access_control';
  
  static bool _isInitialized = false;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize BSN access control service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await BSNSecurityService.initialize();
      _isInitialized = true;
      
      await _auditBSNAccess(
        'BSN_ACCESS_CONTROL_INIT', 
        'BSN access control service initialized',
        purpose: 'system_initialization'
      );
      
      debugPrint('BSNAccessControlService initialized successfully');
    } catch (e) {
      throw BSNSecurityException('Failed to initialize BSN access control: $e', 'INIT_FAILED');
    }
  }

  /// Request access to BSN data with purpose and justification
  static Future<BSNAccessResult> requestBSNAccess({
    required String targetUserId,
    required String purpose,
    required String justification,
    required BSNAccessLevel accessLevel,
    String? requestingUserId,
  }) async {
    _ensureInitialized();
    
    try {
      final userId = requestingUserId ?? _auth.currentUser?.uid ?? 'anonymous';
      final requestId = _generateRequestId();
      
      // Validate purpose against allowed purposes
      if (!_isValidPurpose(purpose)) {
        await _auditBSNAccess(
          'BSN_ACCESS_DENIED',
          'Invalid purpose for BSN access: $purpose',
          targetUserId: targetUserId,
          purpose: purpose,
          requestId: requestId
        );
        
        return BSNAccessResult.denied(
          reason: 'Invalid purpose for BSN access',
          requestId: requestId
        );
      }
      
      // Check if user has permission for this access level
      final hasPermission = await _checkUserPermission(userId, accessLevel, purpose);
      if (!hasPermission) {
        await _auditBSNAccess(
          'BSN_ACCESS_DENIED',
          'Insufficient permissions for BSN access',
          targetUserId: targetUserId,
          purpose: purpose,
          requestId: requestId
        );
        
        return BSNAccessResult.denied(
          reason: 'Insufficient permissions for BSN access',
          requestId: requestId
        );
      }
      
      // Log successful access request
      await _auditBSNAccess(
        'BSN_ACCESS_GRANTED',
        'BSN access granted: $justification',
        targetUserId: targetUserId,
        purpose: purpose,
        requestId: requestId
      );
      
      // Store access record for compliance tracking
      await _storeAccessRecord(
        requestId: requestId,
        requestingUserId: userId,
        targetUserId: targetUserId,
        purpose: purpose,
        justification: justification,
        accessLevel: accessLevel,
        expiresAt: DateTime.now().add(const Duration(hours: 24))
      );
      
      return BSNAccessResult.granted(
        requestId: requestId,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        accessLevel: accessLevel
      );
      
    } catch (e) {
      await _auditBSNAccess(
        'BSN_ACCESS_ERROR',
        'BSN access request failed: $e',
        targetUserId: targetUserId,
        purpose: purpose
      );
      
      return BSNAccessResult.error(
        reason: 'Access request failed: $e'
      );
    }
  }

  /// Get BSN data with access control validation
  static Future<String> getSecureBSN({
    required String encryptedBSN,
    required String accessRequestId,
    required BSNDisplayMode displayMode,
    String? userId,
  }) async {
    _ensureInitialized();
    
    try {
      final currentUserId = userId ?? _auth.currentUser?.uid ?? 'anonymous';
      
      // Validate access request
      final accessRecord = await _validateAccessRequest(accessRequestId, currentUserId);
      if (!accessRecord.isValid) {
        await _auditBSNAccess(
          'BSN_ACCESS_VIOLATION',
          'Invalid or expired access request: $accessRequestId',
          purpose: 'data_access_attempt'
        );
        
        throw BSNSecurityException('Access denied: Invalid or expired access request', 'ACCESS_DENIED');
      }
      
      // Decrypt BSN if needed
      final decryptedBSN = BSNSecurityService.isEncryptedBSN(encryptedBSN)
          ? await BSNSecurityService.instance.decryptBSN(encryptedBSN, currentUserId)
          : encryptedBSN;
      
      // Apply display mode
      String result;
      switch (displayMode) {
        case BSNDisplayMode.masked:
          result = BSNSecurityService.maskBSN(decryptedBSN);
          break;
        case BSNDisplayMode.lastFourDigits:
          result = '****${decryptedBSN.length >= 4 ? decryptedBSN.substring(decryptedBSN.length - 4) : '****'}';
          break;
        case BSNDisplayMode.fullEncrypted:
          if (accessRecord.accessLevel == BSNAccessLevel.admin) {
            result = BSNSecurityService.formatBSN(decryptedBSN);
          } else {
            result = BSNSecurityService.maskBSN(decryptedBSN);
          }
          break;
        case BSNDisplayMode.auditOnly:
          result = BSNSecurityService.hashBSNForAudit(decryptedBSN);
          break;
      }
      
      // Audit the data access
      await _auditBSNAccess(
        'BSN_DATA_ACCESS',
        'BSN data accessed in ${displayMode.name} mode',
        targetUserId: accessRecord.targetUserId,
        purpose: accessRecord.purpose,
        requestId: accessRequestId
      );
      
      return result;
      
    } catch (e) {
      await _auditBSNAccess(
        'BSN_DATA_ACCESS_ERROR',
        'BSN data access failed: $e',
        requestId: accessRequestId
      );
      
      throw BSNSecurityException('BSN data access failed: $e', 'DATA_ACCESS_FAILED');
    }
  }

  /// Get audit trail for BSN access (for compliance reporting)
  static Future<List<Map<String, dynamic>>> getAuditTrail({
    String? targetUserId,
    String? purpose,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  }) async {
    _ensureInitialized();
    
    try {
      Query query = _firestore.collection(_auditCollection);
      
      if (targetUserId != null) {
        query = query.where('targetUserId', isEqualTo: targetUserId);
      }
      
      if (purpose != null) {
        query = query.where('purpose', isEqualTo: purpose);
      }
      
      if (fromDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
      }
      
      if (toDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(toDate));
      }
      
      query = query.orderBy('timestamp', descending: true).limit(limit);
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
      
    } catch (e) {
      debugPrint('Failed to get BSN audit trail: $e');
      return [];
    }
  }

  /// Revoke BSN access (for emergency situations)
  static Future<void> revokeBSNAccess(String accessRequestId, String reason) async {
    _ensureInitialized();
    
    try {
      await _firestore.collection(_accessCollection).doc(accessRequestId).update({
        'revoked': true,
        'revokedAt': FieldValue.serverTimestamp(),
        'revokedReason': reason,
        'revokedBy': _auth.currentUser?.uid ?? 'system'
      });
      
      await _auditBSNAccess(
        'BSN_ACCESS_REVOKED',
        'BSN access revoked: $reason',
        requestId: accessRequestId
      );
      
    } catch (e) {
      throw BSNSecurityException('Failed to revoke BSN access: $e', 'REVOKE_FAILED');
    }
  }

  // Private implementation methods
  
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw BSNSecurityException('BSN access control service not initialized', 'NOT_INITIALIZED');
    }
  }

  static String _generateRequestId() {
    return 'bsn_${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser?.uid ?? 'anon'}';
  }

  static bool _isValidPurpose(String purpose) {
    const validPurposes = {
      'certificate_verification',
      'tax_document_generation',
      'invoice_creation',
      'compliance_audit',
      'user_profile_update',
      'legal_requirement',
      'data_migration',
      'system_administration',
    };
    
    return validPurposes.contains(purpose);
  }

  static Future<bool> _checkUserPermission(String userId, BSNAccessLevel accessLevel, String purpose) async {
    try {
      // In a real implementation, check user roles and permissions
      // For now, return true for basic access
      return accessLevel == BSNAccessLevel.basic || 
             accessLevel == BSNAccessLevel.viewer;
    } catch (e) {
      debugPrint('Failed to check user permission: $e');
      return false;
    }
  }

  static Future<void> _storeAccessRecord({
    required String requestId,
    required String requestingUserId,
    required String targetUserId,
    required String purpose,
    required String justification,
    required BSNAccessLevel accessLevel,
    required DateTime expiresAt,
  }) async {
    await _firestore.collection(_accessCollection).doc(requestId).set({
      'requestingUserId': requestingUserId,
      'targetUserId': targetUserId,
      'purpose': purpose,
      'justification': justification,
      'accessLevel': accessLevel.name,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'revoked': false,
    });
  }

  static Future<BSNAccessRecord> _validateAccessRequest(String requestId, String userId) async {
    try {
      final doc = await _firestore.collection(_accessCollection).doc(requestId).get();
      
      if (!doc.exists) {
        return BSNAccessRecord.invalid('Access request not found');
      }
      
      final data = doc.data()!;
      
      if (data['revoked'] == true) {
        return BSNAccessRecord.invalid('Access request has been revoked');
      }
      
      if (data['requestingUserId'] != userId) {
        return BSNAccessRecord.invalid('Access request belongs to different user');
      }
      
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        return BSNAccessRecord.invalid('Access request has expired');
      }
      
      return BSNAccessRecord(
        requestId: requestId,
        requestingUserId: data['requestingUserId'],
        targetUserId: data['targetUserId'],
        purpose: data['purpose'],
        accessLevel: BSNAccessLevel.values.firstWhere(
          (level) => level.name == data['accessLevel'],
          orElse: () => BSNAccessLevel.basic
        ),
        expiresAt: expiresAt,
        isValid: true,
      );
      
    } catch (e) {
      return BSNAccessRecord.invalid('Failed to validate access request: $e');
    }
  }

  static Future<void> _auditBSNAccess(
    String operation,
    String details, {
    String? targetUserId,
    String? purpose,
    String? requestId,
  }) async {
    try {
      final auditEntry = {
        'timestamp': FieldValue.serverTimestamp(),
        'operation': operation,
        'service': 'BSNAccessControlService',
        'details': details,
        'requestingUserId': _auth.currentUser?.uid ?? 'anonymous',
        'targetUserId': targetUserId,
        'purpose': purpose,
        'requestId': requestId,
        'ipAddress': 'unknown', // Would be populated in real implementation
        'userAgent': 'flutter_app',
        'compliance': 'Nederlandse AVG/GDPR Article 9',
      };
      
      // In production, also send to secure audit log service
      await _firestore.collection(_auditCollection).add(auditEntry);
      
      debugPrint('BSN_ACCESS_AUDIT: ${json.encode(auditEntry)}');
    } catch (e) {
      debugPrint('BSN access audit logging failed: $e');
    }
  }
}

/// BSN access levels for role-based access control
enum BSNAccessLevel {
  viewer, // Can see masked BSN only
  basic, // Can see last 4 digits
  admin, // Can see full BSN when justified
  system, // Full system access for automated processes
}

/// BSN display modes for different use cases
enum BSNDisplayMode {
  masked,          // 123****89 
  lastFourDigits,  // ****6789
  fullEncrypted,   // Full BSN for admin with proper justification
  auditOnly,       // Hash only for audit trails
}

/// Result of BSN access request
class BSNAccessResult {
  final bool isGranted;
  final String? requestId;
  final DateTime? expiresAt;
  final BSNAccessLevel? accessLevel;
  final String? reason;
  final String? error;

  BSNAccessResult._({
    required this.isGranted,
    this.requestId,
    this.expiresAt,
    this.accessLevel,
    this.reason,
    this.error,
  });

  factory BSNAccessResult.granted({
    required String requestId,
    required DateTime expiresAt,
    required BSNAccessLevel accessLevel,
  }) {
    return BSNAccessResult._(
      isGranted: true,
      requestId: requestId,
      expiresAt: expiresAt,
      accessLevel: accessLevel,
    );
  }

  factory BSNAccessResult.denied({
    required String reason,
    String? requestId,
  }) {
    return BSNAccessResult._(
      isGranted: false,
      reason: reason,
      requestId: requestId,
    );
  }

  factory BSNAccessResult.error({
    required String reason,
  }) {
    return BSNAccessResult._(
      isGranted: false,
      error: reason,
    );
  }
}

/// BSN access record for validation
class BSNAccessRecord {
  final String requestId;
  final String requestingUserId;
  final String targetUserId;
  final String purpose;
  final BSNAccessLevel accessLevel;
  final DateTime expiresAt;
  final bool isValid;
  final String? invalidReason;

  BSNAccessRecord({
    required this.requestId,
    required this.requestingUserId,
    required this.targetUserId,
    required this.purpose,
    required this.accessLevel,
    required this.expiresAt,
    required this.isValid,
    this.invalidReason,
  });

  factory BSNAccessRecord.invalid(String reason) {
    return BSNAccessRecord(
      requestId: '',
      requestingUserId: '',
      targetUserId: '',
      purpose: '',
      accessLevel: BSNAccessLevel.viewer,
      expiresAt: DateTime.now(),
      isValid: false,
      invalidReason: reason,
    );
  }
}

/// Extension for BSN access level permissions
extension BSNAccessLevelExtension on BSNAccessLevel {
  String get displayName {
    switch (this) {
      case BSNAccessLevel.viewer:
        return 'Viewer';
      case BSNAccessLevel.basic:
        return 'Basic Access';
      case BSNAccessLevel.admin:
        return 'Administrator';
      case BSNAccessLevel.system:
        return 'System';
    }
  }
}