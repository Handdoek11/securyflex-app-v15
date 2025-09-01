import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../auth_service.dart';

/// SVPB Diploma verification status (Stichting Vakexamens Particuliere Beveiligingsorganisaties)
enum SVPBDiplomaStatus {
  pending,
  verified,
  rejected,
  expired,
  suspended,
  unknown,
}

extension SVPBDiplomaStatusExtension on SVPBDiplomaStatus {
  String get displayName {
    switch (this) {
      case SVPBDiplomaStatus.pending:
        return 'In behandeling';
      case SVPBDiplomaStatus.verified:
        return 'Geverifieerd';
      case SVPBDiplomaStatus.rejected:
        return 'Afgekeurd';
      case SVPBDiplomaStatus.expired:
        return 'Verlopen';
      case SVPBDiplomaStatus.suspended:
        return 'Geschorst';
      case SVPBDiplomaStatus.unknown:
        return 'Onbekend';
    }
  }

  bool get isValid {
    return this == SVPBDiplomaStatus.verified;
  }

  bool get allowsWork {
    return this == SVPBDiplomaStatus.verified;
  }
}

/// SVPB Diploma types (KvK requirement - basic security diploma from SVPB)
enum SVPBDiplomaType {
  beveiliger,
  coordinator,
  havenbeveiliging,
  luchtvaartbeveiliging,
  other,
}

extension SVPBDiplomaTypeExtension on SVPBDiplomaType {
  String get displayName {
    switch (this) {
      case SVPBDiplomaType.beveiliger:
        return 'Beveiliger Diploma';
      case SVPBDiplomaType.coordinator:
        return 'Coördinator Beveiliging';
      case SVPBDiplomaType.havenbeveiliging:
        return 'Havenbeveiliging';
      case SVPBDiplomaType.luchtvaartbeveiliging:
        return 'Luchtvaartbeveiliging';
      case SVPBDiplomaType.other:
        return 'Overig';
    }
  }

  bool get isBasicRequired {
    return this == SVPBDiplomaType.beveiliger;
  }
}

/// SVPB Diploma data model (KvK 2025 requirement)
class SVPBDiplomaData {
  final String diplomaNumber;
  final String holderName;
  final String holderBsn; // Burgerservicenummer (privacy protected)
  final DateTime issueDate;
  final DateTime expirationDate;
  final SVPBDiplomaStatus status;
  final SVPBDiplomaType diplomaType;
  final String issuingInstitution;
  final List<String> specializations;
  final String? documentUrl;
  final Map<String, dynamic>? additionalData;

  const SVPBDiplomaData({
    required this.diplomaNumber,
    required this.holderName,
    this.holderBsn = '',
    required this.issueDate,
    required this.expirationDate,
    required this.status,
    required this.diplomaType,
    required this.issuingInstitution,
    this.specializations = const [],
    this.documentUrl,
    this.additionalData,
  });

  factory SVPBDiplomaData.fromJson(Map<String, dynamic> json) {
    return SVPBDiplomaData(
      diplomaNumber: json['diplomaNumber']?.toString() ?? '',
      holderName: json['holderName']?.toString() ?? '',
      holderBsn: json['holderBsn']?.toString() ?? '',
      issueDate: DateTime.tryParse(json['issueDate']?.toString() ?? '') ?? DateTime.now(),
      expirationDate: DateTime.tryParse(json['expirationDate']?.toString() ?? '') ?? DateTime.now(),
      status: _parseStatus(json['status']?.toString()),
      diplomaType: _parseDiplomaType(json['diplomaType']?.toString()),
      issuingInstitution: json['issuingInstitution']?.toString() ?? 'SVPB',
      specializations: List<String>.from(json['specializations'] ?? []),
      documentUrl: json['documentUrl']?.toString(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diplomaNumber': diplomaNumber,
      'holderName': holderName,
      'holderBsn': holderBsn.isNotEmpty ? '***masked***' : '', // Privacy protection
      'issueDate': issueDate.toIso8601String(),
      'expirationDate': expirationDate.toIso8601String(),
      'status': status.name,
      'diplomaType': diplomaType.name,
      'issuingInstitution': issuingInstitution,
      'specializations': specializations,
      'documentUrl': documentUrl,
      'additionalData': additionalData,
    };
  }

  static SVPBDiplomaStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
      case 'geldig':
        return SVPBDiplomaStatus.verified;
      case 'pending':
      case 'in_behandeling':
        return SVPBDiplomaStatus.pending;
      case 'rejected':
      case 'afgekeurd':
        return SVPBDiplomaStatus.rejected;
      case 'expired':
      case 'verlopen':
        return SVPBDiplomaStatus.expired;
      case 'suspended':
      case 'geschorst':
        return SVPBDiplomaStatus.suspended;
      default:
        return SVPBDiplomaStatus.unknown;
    }
  }

  static SVPBDiplomaType _parseDiplomaType(String? type) {
    switch (type?.toLowerCase()) {
      case 'beveiliger':
        return SVPBDiplomaType.beveiliger;
      case 'coordinator':
      case 'coördinator':
        return SVPBDiplomaType.coordinator;
      case 'havenbeveiliging':
        return SVPBDiplomaType.havenbeveiliging;
      case 'luchtvaartbeveiliging':
        return SVPBDiplomaType.luchtvaartbeveiliging;
      default:
        return SVPBDiplomaType.other;
    }
  }

  /// Check if diploma is currently valid (not expired)
  bool get isCurrentlyValid {
    return status.isValid && DateTime.now().isBefore(expirationDate);
  }

  /// Get specializations description for display
  String get specializationsDescription {
    if (specializations.isEmpty) {
      return 'Algemene beveiliging';
    }
    return specializations.join(', ');
  }

  /// Check if diploma expires within given days
  bool expiresWithin(int days) {
    final checkDate = DateTime.now().add(Duration(days: days));
    return expirationDate.isBefore(checkDate);
  }
}

/// SVPB Diploma verification result
class SVPBDiplomaVerificationResult {
  final bool isSuccess;
  final String message;
  final SVPBDiplomaData? data;
  final String? errorCode;

  const SVPBDiplomaVerificationResult._({
    required this.isSuccess,
    required this.message,
    this.data,
    this.errorCode,
  });

  factory SVPBDiplomaVerificationResult.success(
    String message, 
    SVPBDiplomaData data
  ) {
    return SVPBDiplomaVerificationResult._(
      isSuccess: true,
      message: message,
      data: data,
    );
  }

  factory SVPBDiplomaVerificationResult.error(
    String message, 
    [String? errorCode]
  ) {
    return SVPBDiplomaVerificationResult._(
      isSuccess: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

/// SVPB Diploma verification exception
class SVPBDiplomaVerificationException implements Exception {
  final String message;
  final String? code;

  const SVPBDiplomaVerificationException(this.message, [this.code]);

  @override
  String toString() => 'SVPBDiplomaVerificationException: $message';
}

/// SVPB Diploma Verification Service
/// 
/// Handles verification of SVPB security diplomas as required by KvK 2025
/// Since SVPB doesn't provide public API (only V:base web interface), this service provides:
/// - Format validation
/// - Mock verification for development
/// - Manual verification workflow support
/// - Future V:base integration readiness
class SVPBDiplomaVerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verify SVPB diploma number
  /// 
  /// Since SVPB only provides V:base web interface, this currently:
  /// 1. Validates format (SVPB-XXXXXX)
  /// 2. Checks against local cache/manual verifications
  /// 3. Returns mock data for development
  /// 4. Supports future V:base integration
  static Future<SVPBDiplomaVerificationResult> verifyDiploma(
    String diplomaNumber, {
    File? diplomaDocument,
  }) async {
    try {
      // Input validation
      if (diplomaNumber.isEmpty) {
        return SVPBDiplomaVerificationResult.error(
          'SVPB diploma nummer is verplicht',
          'EMPTY_DIPLOMA_NUMBER',
        );
      }

      // Format validation
      final validation = AuthService.validateSVPBDiplomaDetailed(diplomaNumber);
      if (!validation.isValid) {
        return SVPBDiplomaVerificationResult.error(
          validation.errorMessage,
          'INVALID_FORMAT',
        );
      }

      // Check local cache first (manual verifications)
      final cachedResult = await _checkLocalCache(diplomaNumber);
      if (cachedResult != null) {
        return cachedResult;
      }

      // Since no V:base API available, provide mock verification for development
      if (kDebugMode) {
        return await _mockVerification(diplomaNumber);
      }

      // In production, direct to manual verification process
      return await _initiateManualVerification(diplomaNumber, diplomaDocument);

    } catch (e) {
      return SVPBDiplomaVerificationResult.error(
        'Verificatie mislukt: ${e.toString()}',
        'VERIFICATION_ERROR',
      );
    }
  }

  /// Check locally cached/manually verified SVPB diploma data
  static Future<SVPBDiplomaVerificationResult?> _checkLocalCache(
    String diplomaNumber
  ) async {
    try {
      final doc = await _firestore
          .collection('svpb_diploma_verifications')
          .doc(diplomaNumber)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = SVPBDiplomaData.fromJson(doc.data()!);
        return SVPBDiplomaVerificationResult.success(
          'SVPB diploma gevonden in lokale database',
          data,
        );
      }

      return null;
    } catch (e) {
      // Return null to continue with other verification methods
      return null;
    }
  }

  /// Mock verification for development/testing
  static Future<SVPBDiplomaVerificationResult> _mockVerification(
    String diplomaNumber
  ) async {
    // Simulate V:base lookup delay
    await Future.delayed(const Duration(seconds: 1));

    final mockData = SVPBDiplomaData(
      diplomaNumber: diplomaNumber,
      holderName: 'Jan van der Berg',
      issueDate: DateTime.now().subtract(const Duration(days: 1095)), // 3 years ago
      expirationDate: DateTime.now().add(const Duration(days: 1825)), // 5 years validity
      status: SVPBDiplomaStatus.verified,
      diplomaType: SVPBDiplomaType.beveiliger,
      issuingInstitution: 'SVPB (Mock)',
      specializations: ['Algemene beveiliging', 'Toegangscontrole'],
    );

    return SVPBDiplomaVerificationResult.success(
      'Mock SVPB diploma verificatie succesvol (development mode)',
      mockData,
    );
  }

  /// Initiate manual verification process (V:base lookup required)
  static Future<SVPBDiplomaVerificationResult> _initiateManualVerification(
    String diplomaNumber,
    File? diplomaDocument,
  ) async {
    // Store for manual V:base verification
    await _firestore
        .collection('manual_verifications')
        .doc('svpb_diploma_$diplomaNumber')
        .set({
      'type': 'svpb_diploma',
      'diplomaNumber': diplomaNumber,
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'pending_vbase_check',
      'documentUrl': diplomaDocument?.path,
      'instructions': 'Admin moet diploma handmatig verifiëren via V:base website (svpb.nl)',
    });

    return SVPBDiplomaVerificationResult.error(
      'SVPB diploma verificatie ingediend voor handmatige V:base controle. '
      'U ontvangt binnen 1-2 werkdagen een statusupdate.',
      'MANUAL_VBASE_VERIFICATION_REQUIRED',
    );
  }

  /// Store manual V:base verification result (for admin use)
  static Future<void> storeManualVerificationResult(
    String diplomaNumber,
    SVPBDiplomaData verificationData,
  ) async {
    await _firestore
        .collection('svpb_diploma_verifications')
        .doc(diplomaNumber)
        .set(verificationData.toJson());
  }

  /// Get all manual verification requests (for admin dashboard)
  static Future<List<Map<String, dynamic>>> getPendingManualVerifications() async {
    final query = await _firestore
        .collection('manual_verifications')
        .where('type', isEqualTo: 'svpb_diploma')
        .where('status', isEqualTo: 'pending_vbase_check')
        .orderBy('requestedAt', descending: true)
        .get();

    return query.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Validate SVPB diploma number format
  static bool isValidSVPBDiplomaFormat(String diplomaNumber) {
    if (diplomaNumber.isEmpty) return false;
    final cleaned = diplomaNumber.toUpperCase();
    // SVPB uses format like SVPB-123456 or similar
    return RegExp(r'^SVPB-\d{6}$').hasMatch(cleaned);
  }
}