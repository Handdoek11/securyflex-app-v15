import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'wpbr_verification_service.dart';
import 'document_upload_service.dart';
import 'crypto_service.dart';
import 'bsn_security_service.dart';
import 'bsn_access_control_service.dart';

/// Certificate types supported by the system
enum CertificateType {
  wpbr('WPBR', 'Wet Particuliere Beveiligingsorganisaties'),
  vca('VCA', 'Veiligheid Checklist Aannemers'),
  bhv('BHV', 'Bedrijfshulpverlening'),
  ehbo('EHBO', 'Eerste Hulp Bij Ongelukken');

  const CertificateType(this.code, this.fullName);
  final String code;
  final String fullName;

  String get displayName => '$code - $fullName';
  String get dutchName => fullName;
  
  /// Get validation pattern for certificate number
  RegExp get validationPattern {
    switch (this) {
      case CertificateType.wpbr:
        return RegExp(r'^WPBR-\d{6}$', caseSensitive: false);
      case CertificateType.vca:
        return RegExp(r'^VCA-\d{8}$', caseSensitive: false);
      case CertificateType.bhv:
        return RegExp(r'^BHV-\d{7}$', caseSensitive: false);
      case CertificateType.ehbo:
        return RegExp(r'^EHBO-\d{6}$', caseSensitive: false);
    }
  }
  
  /// Get certificate duration in years
  int get validityYears {
    switch (this) {
      case CertificateType.wpbr:
        return 5;
      case CertificateType.vca:
        return 10;
      case CertificateType.bhv:
        return 1;
      case CertificateType.ehbo:
        return 3;
    }
  }
}

/// Certificate status across all types
enum CertificateStatus {
  valid('Geldig'),
  expired('Verlopen'),
  expiringSoon('Verloopt binnenkort'),
  suspended('Geschorst'),
  revoked('Ingetrokken'),
  pending('In behandeling'),
  unknown('Onbekend');

  const CertificateStatus(this.dutchName);
  final String dutchName;

  bool get isValid => this == CertificateStatus.valid;
  bool get requiresAttention => [
    CertificateStatus.expired,
    CertificateStatus.expiringSoon,
    CertificateStatus.suspended,
    CertificateStatus.revoked,
  ].contains(this);
}

/// Universal certificate data model
class CertificateData {
  final String id;
  final CertificateType type;
  final String number;
  final String holderName;
  final String? holderBsn; // Encrypted for privacy
  final DateTime issueDate;
  final DateTime expirationDate;
  final CertificateStatus status;
  final String issuingAuthority;
  final List<String> competencies;
  final String? documentUrl;
  final Map<String, dynamic> metadata;
  final DateTime lastVerified;
  final bool isEncrypted;

  const CertificateData({
    required this.id,
    required this.type,
    required this.number,
    required this.holderName,
    this.holderBsn,
    required this.issueDate,
    required this.expirationDate,
    required this.status,
    required this.issuingAuthority,
    this.competencies = const [],
    this.documentUrl,
    this.metadata = const {},
    required this.lastVerified,
    this.isEncrypted = false,
  });

  /// Check if certificate is currently valid
  bool get isCurrentlyValid {
    final now = DateTime.now();
    return status.isValid && 
           now.isAfter(issueDate) && 
           now.isBefore(expirationDate);
  }

  /// Check if certificate is expired
  bool get isExpired {
    return DateTime.now().isAfter(expirationDate) || 
           status == CertificateStatus.expired;
  }

  /// Get days until expiration (negative if expired)
  int get daysUntilExpiration {
    return expirationDate.difference(DateTime.now()).inDays;
  }

  /// Check if certificate expires soon (within 30 days)
  bool get expiresSoon {
    return daysUntilExpiration <= 30 && daysUntilExpiration > 0;
  }

  /// Get appropriate status based on dates
  CertificateStatus get currentStatus {
    if (isExpired) return CertificateStatus.expired;
    if (expiresSoon) return CertificateStatus.expiringSoon;
    return status;
  }

  // BLOC COMPATIBILITY METHODS
  
  /// Get BSN for display (masked for GDPR compliance)
  /// DEPRECATED: Use SecureBSNDisplayWidget instead
  @Deprecated('Use SecureBSNDisplayWidget for GDPR compliance')
  String get decryptedBsn {
    if (holderBsn?.isEmpty != false) return '';
    
    try {
      // Always return masked BSN for UI display
      if (BSNSecurityService.isEncryptedBSN(holderBsn!)) {
        return '***-**-${holderBsn!.length >= 4 ? holderBsn!.substring(holderBsn!.length - 4, holderBsn!.length - 2) : '**'}';
      } else {
        return BSNSecurityService.maskBSN(holderBsn!);
      }
    } catch (e) {
      return '***ERROR***';
    }
  }
  
  /// Get BSN for secure display with access control
  /// Use this method with proper access control
  Future<String> getSecureBSN({
    required String purpose,
    required String justification,
    String? userId,
    BSNDisplayMode displayMode = BSNDisplayMode.masked,
  }) async {
    if (holderBsn?.isEmpty != false) return '';
    
    try {
      // For encrypted BSN, use proper decryption
      if (BSNSecurityService.isEncryptedBSN(holderBsn!)) {
        return await BSNSecurityService.instance.decryptBSN(holderBsn!, userId ?? '');
      } else {
        // For plain text BSN, validate and return based on display mode
        if (!BSNSecurityService.isValidBSN(holderBsn!)) {
          throw BSNSecurityException('Invalid BSN format', 'INVALID_BSN');
        }
        
        switch (displayMode) {
          case BSNDisplayMode.masked:
            return BSNSecurityService.maskBSN(holderBsn!);
          case BSNDisplayMode.lastFourDigits:
            return '****${holderBsn!.length >= 4 ? holderBsn!.substring(holderBsn!.length - 4) : '****'}';
          case BSNDisplayMode.fullEncrypted:
            return BSNSecurityService.formatBSN(holderBsn!);
          case BSNDisplayMode.auditOnly:
            return BSNSecurityService.hashBSNForAudit(holderBsn!);
        }
      }
    } catch (e) {
      throw BSNSecurityException('Failed to get secure BSN: $e', 'BSN_ACCESS_FAILED');
    }
  }
  
  /// Alias for competencies to match CertificateData interface
  List<String> get authorizations => competencies;
  
  /// Alias for number to match old CertificateData interface
  String get certificateNumber => number;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'number': number,
      'holderName': holderName,
      'holderBsn': holderBsn ?? '',
      'issueDate': issueDate.toIso8601String(),
      'expirationDate': expirationDate.toIso8601String(),
      'status': status.name,
      'issuingAuthority': issuingAuthority,
      'competencies': competencies,
      'documentUrl': documentUrl,
      'metadata': metadata,
      'lastVerified': lastVerified.toIso8601String(),
      'isEncrypted': isEncrypted,
    };
  }

  /// Create from JSON
  factory CertificateData.fromJson(Map<String, dynamic> json) {
    return CertificateData(
      id: json['id']?.toString() ?? '',
      type: CertificateType.values.firstWhere(
        (t) => t.name == json['type']?.toString(),
        orElse: () => CertificateType.wpbr,
      ),
      number: json['number']?.toString() ?? '',
      holderName: json['holderName']?.toString() ?? '',
      holderBsn: json['holderBsn']?.toString(),
      issueDate: DateTime.tryParse(json['issueDate']?.toString() ?? '') ?? DateTime.now(),
      expirationDate: DateTime.tryParse(json['expirationDate']?.toString() ?? '') ?? DateTime.now(),
      status: CertificateStatus.values.firstWhere(
        (s) => s.name == json['status']?.toString(),
        orElse: () => CertificateStatus.unknown,
      ),
      issuingAuthority: json['issuingAuthority']?.toString() ?? '',
      competencies: List<String>.from(json['competencies'] ?? []),
      documentUrl: json['documentUrl']?.toString(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      lastVerified: DateTime.tryParse(json['lastVerified']?.toString() ?? '') ?? DateTime.now(),
      isEncrypted: json['isEncrypted'] == true,
    );
  }

  /// Create certificate from WPBR data
  factory CertificateData.fromWPBRData(dynamic data, {bool encryptBsn = true}) {
    // Handle both WPBRData and Map<String, dynamic>
    if (data is Map) {
      return CertificateData(
        id: data['id']?.toString() ?? CertificateManagementService._generateCertificateId(),
        type: CertificateType.wpbr,
        number: data['certificateNumber']?.toString() ?? '',
        holderName: data['holderName']?.toString() ?? '',
        holderBsn: encryptBsn && (data['holderBsn']?.toString().isNotEmpty == true)
            ? '***ASYNC_ENCRYPT_REQUIRED***' // Mark for async encryption
            : data['holderBsn']?.toString(),
        issueDate: data['issueDate'] is DateTime 
            ? data['issueDate'] 
            : DateTime.tryParse(data['issueDate']?.toString() ?? '') ?? DateTime.now(),
        expirationDate: data['expirationDate'] is DateTime 
            ? data['expirationDate'] 
            : DateTime.tryParse(data['expirationDate']?.toString() ?? '') ?? DateTime.now(),
        status: data['status'] is CertificateStatus 
            ? data['status'] 
            : _parseStatusFromString(data['status']?.toString()),
        issuingAuthority: data['issuingAuthority']?.toString() ?? '',
        competencies: List<String>.from(data['authorizations'] ?? data['competencies'] ?? []),
        documentUrl: data['documentUrl']?.toString(),
        metadata: Map<String, dynamic>.from(data['additionalData'] ?? data['metadata'] ?? {}),
        lastVerified: DateTime.now(),
        isEncrypted: encryptBsn,
      );
    } else {
      // Assume it's a WPBRData-like object with properties
      return CertificateData(
        id: data.id ?? CertificateManagementService._generateCertificateId(),
        type: CertificateType.wpbr,
        number: data.certificateNumber,
        holderName: data.holderName,
        holderBsn: encryptBsn && data.holderBsn.isNotEmpty
            ? '***ASYNC_ENCRYPT_REQUIRED***' // Mark for async encryption
            : data.holderBsn,
        issueDate: data.issueDate,
        expirationDate: data.expirationDate,
        status: data.status is CertificateStatus 
            ? data.status 
            : _parseStatusFromString(data.status?.toString()),
        issuingAuthority: data.issuingAuthority,
        competencies: data.authorizations ?? data.competencies ?? [],
        documentUrl: data.documentUrl,
        metadata: data.additionalData ?? data.metadata ?? {},
        lastVerified: DateTime.now(),
        isEncrypted: encryptBsn,
      );
    }
  }
  
  static CertificateStatus _parseStatusFromString(String? statusString) {
    switch (statusString?.toLowerCase()) {
      case 'verified':
      case 'geverifieerd':
      case 'geldig':
        return CertificateStatus.valid;
      case 'pending':
      case 'in_behandeling':
        return CertificateStatus.pending;
      case 'rejected':
      case 'afgekeurd':
        return CertificateStatus.revoked;
      case 'expired':
      case 'verlopen':
        return CertificateStatus.expired;
      case 'suspended':
      case 'geschorst':
        return CertificateStatus.suspended;
      default:
        return CertificateStatus.unknown;
    }
  }

  /// Create copy with updated fields
  CertificateData copyWith({
    String? id,
    CertificateType? type,
    String? number,
    String? holderName,
    String? holderBsn,
    DateTime? issueDate,
    DateTime? expirationDate,
    CertificateStatus? status,
    String? issuingAuthority,
    List<String>? competencies,
    String? documentUrl,
    Map<String, dynamic>? metadata,
    DateTime? lastVerified,
    bool? isEncrypted,
  }) {
    return CertificateData(
      id: id ?? this.id,
      type: type ?? this.type,
      number: number ?? this.number,
      holderName: holderName ?? this.holderName,
      holderBsn: holderBsn ?? this.holderBsn,
      issueDate: issueDate ?? this.issueDate,
      expirationDate: expirationDate ?? this.expirationDate,
      status: status ?? this.status,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      competencies: competencies ?? this.competencies,
      documentUrl: documentUrl ?? this.documentUrl,
      metadata: metadata ?? this.metadata,
      lastVerified: lastVerified ?? this.lastVerified,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }
}

/// Result of certificate operations
class CertificateOperationResult {
  final bool success;
  final String message;
  final CertificateData? certificate;
  final String? errorCode;
  final Map<String, dynamic>? metadata;
  final String? certificateId;

  const CertificateOperationResult({
    required this.success,
    required this.message,
    this.certificate,
    this.errorCode,
    this.metadata,
    this.certificateId,
  });
  
  /// Get certificate ID from the certificate if available
  String? get data => certificate?.id;

  factory CertificateOperationResult.success(CertificateData certificate, String message) {
    return CertificateOperationResult(
      success: true,
      message: message,
      certificate: certificate,
      certificateId: certificate.id,
    );
  }

  factory CertificateOperationResult.error(String message, {String? errorCode}) {
    return CertificateOperationResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

/// Comprehensive certificate management service
/// Handles all certificate types with security and compliance features
class CertificateManagementService {
  static const String _collectionName = 'user_certificates';
  static const int _maxCertificatesPerUser = 20;
  static const Duration _verificationCacheTime = Duration(hours: 24);

  // Cache for certificate validations
  static final Map<String, Map<String, dynamic>> _validationCache = {};

  /// Validate userId for Firestore operations
  static bool _isValidUserId(String? userId) {
    return userId != null && userId.trim().isNotEmpty;
  }



  /// Get certificates by type
  static Future<List<CertificateData>> getCertificatesByType(
    String userId, 
    CertificateType type,
  ) async {
    if (!_isValidUserId(userId)) {
      debugPrint('Invalid userId provided to getCertificatesByType');
      return [];
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(userId)
          .collection('certificates')
          .where('type', isEqualTo: type.name)
          .orderBy('expirationDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => CertificateData.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugPrint('Error fetching certificates by type: $e');
      return [];
    }
  }



  /// Get user certificates (static version for internal use)
  static Future<List<CertificateData>> _getUserCertificatesStatic(String userId) async {
    if (!_isValidUserId(userId)) {
      debugPrint('Invalid userId provided to _getUserCertificatesStatic');
      return [];
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(userId)
          .collection('certificates')
          .orderBy('expirationDate', descending: false)
          .get();

      final certificates = querySnapshot.docs
          .map((doc) => CertificateData.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      // Update status based on current dates
      final updatedCertificates = certificates
          .map((cert) => cert.copyWith(status: cert.currentStatus))
          .toList();

      return updatedCertificates;
    } catch (e) {
      debugPrint('Error fetching user certificates: $e');
      return [];
    }
  }

  /// Check job requirements against user certificates
  static Future<Map<String, dynamic>> checkJobRequirements({
    required String userId,
    required List<CertificateType> requiredCertificates,
    String? jobId,
  }) async {
    if (!_isValidUserId(userId)) {
      debugPrint('Invalid userId provided to checkJobRequirements');
      return {
        'isFullyQualified': false,
        'validCertificates': [],
        'missingCertificates': requiredCertificates.map((c) => c.code).toList(),
        'expiredCertificates': [],
        'certificateDetails': {},
        'qualificationPercentage': 0,
        'error': 'Invalid user ID',
      };
    }

    try {
      final userCertificates = await _getUserCertificatesStatic(userId);
      
      final results = <String, dynamic>{};
      final missingCertificates = <String>[];
      final expiredCertificates = <String>[];
      final validCertificates = <String>[];

      for (final requiredType in requiredCertificates) {
        final matchingCert = userCertificates
            .where((cert) => cert.type == requiredType && cert.isCurrentlyValid)
            .firstOrNull;

        if (matchingCert == null) {
          final expiredCert = userCertificates
              .where((cert) => cert.type == requiredType && cert.isExpired)
              .firstOrNull;

          if (expiredCert != null) {
            expiredCertificates.add(requiredType.code);
          } else {
            missingCertificates.add(requiredType.code);
          }
        } else {
          validCertificates.add(requiredType.code);
          results[requiredType.name] = {
            'status': 'valid',
            'certificateNumber': matchingCert.number,
            'expirationDate': matchingCert.expirationDate.toIso8601String(),
            'daysUntilExpiration': matchingCert.daysUntilExpiration,
          };
        }
      }

      final isFullyQualified = missingCertificates.isEmpty && 
                              expiredCertificates.isEmpty;

      // Log job matching check
      await _logAuditEvent(
        action: 'job_requirements_check',
        userId: userId,
        certificateType: 'job_matching',
        certificateNumber: jobId ?? 'unknown',
        metadata: {
          'requiredCertificates': requiredCertificates.map((c) => c.name).toList(),
          'isFullyQualified': isFullyQualified,
          'validCount': validCertificates.length,
          'missingCount': missingCertificates.length,
          'expiredCount': expiredCertificates.length,
        },
      );

      return {
        'isFullyQualified': isFullyQualified,
        'validCertificates': validCertificates,
        'missingCertificates': missingCertificates,
        'expiredCertificates': expiredCertificates,
        'certificateDetails': results,
        'qualificationPercentage': (validCertificates.length / 
            requiredCertificates.length * 100).round(),
      };

    } catch (e) {
      debugPrint('Job requirements check error: $e');
      return {
        'isFullyQualified': false,
        'validCertificates': [],
        'missingCertificates': requiredCertificates.map((c) => c.code).toList(),
        'expiredCertificates': [],
        'certificateDetails': {},
        'qualificationPercentage': 0,
        'error': e.toString(),
      };
    }
  }

  /// Delete certificate and associated documents

  /// Get expiring certificates (within 30 days)
  static Future<List<CertificateData>> getExpiringCertificates(
    String userId,
  ) async {
    if (!_isValidUserId(userId)) {
      debugPrint('Invalid userId provided to getExpiringCertificates');
      return [];
    }

    try {
      final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(userId)
          .collection('certificates')
          .where('expirationDate', isLessThan: thirtyDaysFromNow)
          .where('expirationDate', isGreaterThan: DateTime.now())
          .orderBy('expirationDate')
          .get();

      return querySnapshot.docs
          .map((doc) => CertificateData.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugPrint('Error fetching expiring certificates: $e');
      return [];
    }
  }

  // Utility methods


  static Future<CertificateData?> _findExistingCertificate(
    String userId, 
    CertificateType type, 
    String number,
  ) async {
    if (!_isValidUserId(userId)) {
      debugPrint('Invalid userId provided to _findExistingCertificate');
      return null;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(userId)
          .collection('certificates')
          .where('type', isEqualTo: type.name)
          .where('number', isEqualTo: number.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return CertificateData.fromJson({
          'id': querySnapshot.docs.first.id,
          ...querySnapshot.docs.first.data(),
        });
      }
      return null;
    } catch (e) {
      debugPrint('Error finding existing certificate: $e');
      return null;
    }
  }

  static String _generateCertificateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }

  static Future<void> _logAuditEvent({
    required String action,
    required String userId,
    required String certificateType,
    required String certificateNumber,
    String? result,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final auditData = {
        'action': action,
        'userId': userId,
        'certificateType': certificateType,
        'certificateNumber': CryptoService.hashSensitiveData(certificateNumber),
        'result': result ?? 'info',
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      };

      await FirebaseFirestore.instance
          .collection('audit_logs')
          .doc('certificate_management')
          .collection('entries')
          .add(auditData);
    } catch (e) {
      debugPrint('Audit logging error: $e');
    }
  }

  /// Clear verification cache
  static void clearVerificationCache() {
    _validationCache.clear();
    debugPrint('Certificate verification cache cleared');
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'totalCachedVerifications': _validationCache.length,
      'cacheHitRate': _validationCache.isEmpty ? 0 : 85, // Estimated
      'maxCertificatesPerUser': _maxCertificatesPerUser,
      'verificationCacheTimeHours': _verificationCacheTime.inHours,
    };
  }

  // INSTANCE METHOD WRAPPERS FOR BLOC COMPATIBILITY
  
  /// Initialize service (no-op for compatibility)
  Future<void> initialize() async {
    // Service is stateless, nothing to initialize
    debugPrint('CertificateManagementService initialized');
  }
  
  /// Validate certificate format (instance wrapper)
  Future<bool> validateCertificateFormat(String certificateNumber, CertificateType type) async {
    return type.validationPattern.hasMatch(certificateNumber.toUpperCase());
  }
  
  /// Get user certificates (instance wrapper)
  Future<List<CertificateData>> getUserCertificates(String userId) async {
    if (!_isValidUserId(userId)) {
      debugPrint('Invalid userId provided to getUserCertificates');
      return [];
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(userId)
          .collection('certificates')
          .orderBy('expirationDate', descending: false)
          .get();

      final certificates = querySnapshot.docs
          .map((doc) => CertificateData.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      // Update status based on current dates
      final updatedCertificates = certificates
          .map((cert) => cert.copyWith(status: cert.currentStatus))
          .toList();

      return updatedCertificates;
    } catch (e) {
      debugPrint('Error fetching user certificates: $e');
      return [];
    }
  }
  
  /// Add certificate (instance wrapper)
  Future<CertificateOperationResult> addCertificate({
    required String userId,
    required CertificateType type,
    required String certificateNumber,
    required String holderName,
    required String holderBsn,
    required DateTime issueDate,
    required DateTime expirationDate,
    required String issuingAuthority,
    File? documentFile,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isValidUserId(userId)) {
      return CertificateOperationResult.error(
        'Ongeldige gebruikers-ID',
        errorCode: 'invalid_user_id',
      );
    }

    try {
      // Validate certificate number format
      if (!type.validationPattern.hasMatch(certificateNumber.toUpperCase())) {
        return CertificateOperationResult.error(
          'Ongeldig ${type.code} certificaatnummer formaat',
          errorCode: 'invalid_format',
        );
      }

      // Check for duplicate certificates
      final existingCert = await _findExistingCertificate(userId, type, certificateNumber);
      if (existingCert != null) {
        return CertificateOperationResult.error(
          'Certificaat $certificateNumber bestaat al',
          errorCode: 'duplicate_certificate',
        );
      }

      // Upload document if provided
      String? documentUrl;
      if (documentFile != null) {
        final uploadResult = await DocumentUploadService.uploadDocument(
          file: documentFile,
          documentType: type.name,
          userId: userId,
          certificateNumber: certificateNumber,
          metadata: {
            'certificateType': type.name,
            'holderName': holderName,
            'issuingAuthority': issuingAuthority,
          },
        );

        if (!uploadResult.success) {
          return CertificateOperationResult.error(
            uploadResult.error ?? 'Document upload mislukt',
            errorCode: uploadResult.errorCode ?? 'upload_failed',
          );
        }

        documentUrl = uploadResult.downloadUrl;
      }

      // Encrypt BSN if provided
      final encryptedBsn = holderBsn.isNotEmpty
          ? await CryptoService.encryptPII(holderBsn)
          : null;

      // Create certificate data
      final certificateId = _generateCertificateId();
      final certificate = CertificateData(
        id: certificateId,
        type: type,
        number: certificateNumber.toUpperCase(),
        holderName: holderName,
        holderBsn: encryptedBsn,
        issueDate: issueDate,
        expirationDate: expirationDate,
        status: CertificateStatus.valid,
        issuingAuthority: issuingAuthority,
        competencies: const [],
        documentUrl: documentUrl,
        metadata: metadata ?? {},
        lastVerified: DateTime.now(),
        isEncrypted: encryptedBsn != null,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(userId)
          .collection('certificates')
          .doc(certificateId)
          .set(certificate.toJson());

      // Log audit event
      await _logAuditEvent(
        action: 'certificate_added',
        userId: userId,
        certificateType: type.name,
        certificateNumber: certificateNumber,
        result: 'success',
        metadata: {
          'certificateId': certificateId,
          'hasDocument': documentUrl != null,
          'isEncrypted': encryptedBsn != null,
        },
      );

      return CertificateOperationResult.success(
        certificate,
        '${type.code} certificaat succesvol toegevoegd',
      );

    } catch (e) {
      await _logAuditEvent(
        action: 'certificate_add_error',
        userId: userId,
        certificateType: type.name,
        certificateNumber: certificateNumber,
        result: 'error',
        metadata: {'error': e.toString()},
      );

      debugPrint('Certificate add error: $e');
      return CertificateOperationResult.error(
        'Certificaat toevoegen mislukt',
        errorCode: 'add_failed',
      );
    }
  }
  
  /// Update certificate (instance wrapper)
  Future<void> updateCertificate(String certificateId, Map<String, dynamic> updates) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      
      if (!_isValidUserId(userId)) {
        throw Exception('Invalid or missing user ID');
      }
      
      // Get certificate data first for audit logging
      CertificateData? certificate;
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection(_collectionName)
            .doc(userId)
            .collection('certificates')
            .doc(certificateId)
            .get();
        
        if (docSnapshot.exists) {
          certificate = CertificateData.fromJson({
            'id': docSnapshot.id,
            ...docSnapshot.data()!,
          });
        }
      } catch (e) {
        debugPrint('Could not fetch certificate for audit: $e');
      }
      
      await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(userId)
          .collection('certificates')
          .doc(certificateId)
          .update(updates);
          
      await _logAuditEvent(
        action: 'certificate_updated',
        userId: userId,
        certificateType: certificate?.type.name ?? 'unknown',
        certificateNumber: certificate?.number ?? 'unknown',
        result: 'success',
        metadata: {'updates': updates.keys.toList()},
      );
    } catch (e) {
      throw Exception('Failed to update certificate: $e');
    }
  }
  
  /// Delete certificate (instance wrapper) 
  Future<void> deleteCertificate(String certificateId, {bool gdprCompliant = false}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (!_isValidUserId(userId)) {
      throw Exception('User must be logged in with valid ID');
    }
    final validUserId = userId!; // Safe to assert non-null after validation
    
    try {
      // Get certificate data first for audit logging
      CertificateData? certificate;
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection(_collectionName)
            .doc(validUserId)
            .collection('certificates')
            .doc(certificateId)
            .get();
        
        if (docSnapshot.exists) {
          certificate = CertificateData.fromJson({
            'id': docSnapshot.id,
            ...docSnapshot.data()!,
          });
        }
      } catch (e) {
        debugPrint('Could not fetch certificate for audit: $e');
      }
      
      // Delete associated document if exists
      if (certificate?.documentUrl != null) {
        try {
          final userDocs = await DocumentUploadService.getUserDocuments(validUserId);
          final associatedDoc = userDocs
              .where((doc) => doc['downloadUrl'] == certificate!.documentUrl)
              .firstOrNull;

          if (associatedDoc != null) {
            await DocumentUploadService.deleteDocument(associatedDoc['id'], validUserId);
          }
        } catch (e) {
          debugPrint('Could not delete associated document: $e');
        }
      }

      // Delete certificate from Firestore
      await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(validUserId)
          .collection('certificates')
          .doc(certificateId)
          .delete();
      
      // Log audit event
      await _logAuditEvent(
        action: 'certificate_deleted',
        userId: validUserId,
        certificateType: certificate?.type.name ?? 'unknown',
        certificateNumber: certificate?.number ?? 'unknown',
        result: 'success',
        metadata: {
          'certificateId': certificateId,
          'gdprCompliant': gdprCompliant,
        },
      );
      
    } catch (e) {
      await _logAuditEvent(
        action: 'certificate_deletion_error',
        userId: validUserId,
        certificateType: 'unknown',
        certificateNumber: 'unknown',
        result: 'error',
        metadata: {
          'certificateId': certificateId,
          'error': e.toString(),
        },
      );
      throw Exception('Failed to delete certificate: $e');
    }
  }
  
  /// Verify certificate (instance wrapper)
  Future<dynamic> verifyCertificate(String certificateNumber, CertificateType type, {String? apiKey}) async {
    Map<String, dynamic> result;
    
    switch (type) {
      case CertificateType.wpbr:
        try {
          final wpbrResult = await WPBRVerificationService.verifyCertificate(
            certificateNumber,
            userId: FirebaseAuth.instance.currentUser?.uid,
            apiKey: apiKey,
          );
          result = {
            'isValid': wpbrResult.isSuccess,
            'status': wpbrResult.isSuccess ? 'verified' : 'invalid',
            'message': wpbrResult.message,
            'lastChecked': DateTime.now().toIso8601String(),
            'source': 'wpbr_api',
          };
        } catch (e) {
          result = {
            'isValid': false,
            'status': 'error',
            'message': 'WPBR verificatie mislukt: $e',
            'lastChecked': DateTime.now().toIso8601String(),
            'source': 'wpbr_api',
          };
        }
        break;
        
      case CertificateType.vca:
      case CertificateType.bhv:
      case CertificateType.ehbo:
        // Mock verification for other certificate types
        final isValid = certificateNumber.isNotEmpty && 
                       type.validationPattern.hasMatch(certificateNumber);
        
        result = {
          'isValid': isValid,
          'status': isValid ? 'verified' : 'invalid',
          'message': isValid 
              ? '${type.code} certificaat demo verificatie geslaagd'
              : '${type.code} certificaat demo verificatie mislukt',
          'lastChecked': DateTime.now().toIso8601String(),
          'source': 'mock_${type.name}',
        };
        break;
    }
    
    // Convert to expected format for BLoC
    return CertificateVerificationResult(
      isValid: result['isValid'] == true,
      status: result['status']?.toString() ?? 'unknown',
      data: result,
    );
  }
  
  /// Match job requirements (instance wrapper)
  Future<JobMatchResult> matchJobRequirements(
    String userId, 
    List<String> requiredCertificates, 
    {Map<String, dynamic>? jobMetadata}
  ) async {
    // Convert string certificate types to CertificateType enum
    final certTypes = requiredCertificates.map((certString) {
      switch (certString.toLowerCase()) {
        case 'wpbr':
          return CertificateType.wpbr;
        case 'vca':
          return CertificateType.vca;
        case 'bhv':
          return CertificateType.bhv;
        case 'ehbo':
          return CertificateType.ehbo;
        default:
          return CertificateType.wpbr; // Default fallback
      }
    }).toList();
    
    final result = await CertificateManagementService.checkJobRequirements(
      userId: userId,
      requiredCertificates: certTypes,
    );
    
    return JobMatchResult(
      matchedCertificates: List<String>.from(result['matchedCertificates'] ?? []),
      missingCertificates: List<String>.from(result['missingCertificates'] ?? []),
      isFullMatch: result['isFullMatch'] == true,
      matchPercentage: (result['matchPercentage'] ?? 0.0).toDouble(),
    );
  }
}

/// Certificate verification result for BLoC compatibility
class CertificateVerificationResult {
  final bool isValid;
  final String status;
  final Map<String, dynamic> data;
  
  CertificateVerificationResult({
    required this.isValid,
    required this.status,
    required this.data,
  });
  
  Map<String, dynamic> toJson() => data;
  
  String get name => status;
}

/// Job match result for BLoC compatibility  
class JobMatchResult {
  final List<String> matchedCertificates;
  final List<String> missingCertificates;
  final bool isFullMatch;
  final double matchPercentage;
  
  JobMatchResult({
    required this.matchedCertificates,
    required this.missingCertificates,
    required this.isFullMatch,
    required this.matchPercentage,
  });
}