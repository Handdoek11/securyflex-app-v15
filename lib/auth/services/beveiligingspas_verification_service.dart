import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../auth_service.dart';

/// Beveiligingspas verification status (3-year validity as per KvK requirements)
enum BeveiligingspaStatus {
  pending,
  verified,
  rejected,
  expired,
  suspended,
  unknown,
}

extension BeveiligingspaStatusExtension on BeveiligingspaStatus {
  String get displayName {
    switch (this) {
      case BeveiligingspaStatus.pending:
        return 'In behandeling';
      case BeveiligingspaStatus.verified:
        return 'Geldig';
      case BeveiligingspaStatus.rejected:
        return 'Afgekeurd';
      case BeveiligingspaStatus.expired:
        return 'Verlopen';
      case BeveiligingspaStatus.suspended:
        return 'Geschorst';
      case BeveiligingspaStatus.unknown:
        return 'Onbekend';
    }
  }

  bool get isValid {
    return this == BeveiligingspaStatus.verified;
  }

  bool get allowsWork {
    return this == BeveiligingspaStatus.verified;
  }
}

/// Beveiligingspas data model (KvK 2025 requirement - 3 year validity)
class BeveiligingspaData {
  final String pasNumber;
  final String holderName;
  final String holderBsn; // Burgerservicenummer (privacy protected)
  final DateTime issueDate;
  final DateTime expirationDate;
  final BeveiligingspaStatus status;
  final String issuingAuthority;
  final List<String> authorizations;
  final String? documentUrl;
  final Map<String, dynamic>? additionalData;

  const BeveiligingspaData({
    required this.pasNumber,
    required this.holderName,
    this.holderBsn = '',
    required this.issueDate,
    required this.expirationDate,
    required this.status,
    required this.issuingAuthority,
    this.authorizations = const [],
    this.documentUrl,
    this.additionalData,
  });

  factory BeveiligingspaData.fromJson(Map<String, dynamic> json) {
    return BeveiligingspaData(
      pasNumber: json['pasNumber']?.toString() ?? '',
      holderName: json['holderName']?.toString() ?? '',
      holderBsn: json['holderBsn']?.toString() ?? '',
      issueDate: DateTime.tryParse(json['issueDate']?.toString() ?? '') ?? DateTime.now(),
      expirationDate: DateTime.tryParse(json['expirationDate']?.toString() ?? '') ?? DateTime.now(),
      status: _parseStatus(json['status']?.toString()),
      issuingAuthority: json['issuingAuthority']?.toString() ?? 'Justis',
      authorizations: List<String>.from(json['authorizations'] ?? []),
      documentUrl: json['documentUrl']?.toString(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pasNumber': pasNumber,
      'holderName': holderName,
      'holderBsn': holderBsn.isNotEmpty ? '***masked***' : '', // Privacy protection
      'issueDate': issueDate.toIso8601String(),
      'expirationDate': expirationDate.toIso8601String(),
      'status': status.name,
      'issuingAuthority': issuingAuthority,
      'authorizations': authorizations,
      'documentUrl': documentUrl,
      'additionalData': additionalData,
    };
  }

  static BeveiligingspaStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
      case 'geldig':
        return BeveiligingspaStatus.verified;
      case 'pending':
      case 'in_behandeling':
        return BeveiligingspaStatus.pending;
      case 'rejected':
      case 'afgekeurd':
        return BeveiligingspaStatus.rejected;
      case 'expired':
      case 'verlopen':
        return BeveiligingspaStatus.expired;
      case 'suspended':
      case 'geschorst':
        return BeveiligingspaStatus.suspended;
      default:
        return BeveiligingspaStatus.unknown;
    }
  }

  /// Check if beveiligingspas is currently valid (not expired)
  bool get isCurrentlyValid {
    return status.isValid && DateTime.now().isBefore(expirationDate);
  }

  /// Get authorization description for display
  String get authorizationDescription {
    if (authorizations.isEmpty) {
      return 'Algemene beveiliging';
    }
    return authorizations.join(', ');
  }

  /// Check if pas expires within given days
  bool expiresWithin(int days) {
    final checkDate = DateTime.now().add(Duration(days: days));
    return expirationDate.isBefore(checkDate);
  }
}

/// Beveiligingspas verification result
class BeveiligingspaVerificationResult {
  final bool isSuccess;
  final String message;
  final BeveiligingspaData? data;
  final String? errorCode;

  const BeveiligingspaVerificationResult._({
    required this.isSuccess,
    required this.message,
    this.data,
    this.errorCode,
  });

  factory BeveiligingspaVerificationResult.success(
    String message, 
    BeveiligingspaData data
  ) {
    return BeveiligingspaVerificationResult._(
      isSuccess: true,
      message: message,
      data: data,
    );
  }

  factory BeveiligingspaVerificationResult.error(
    String message, 
    [String? errorCode]
  ) {
    return BeveiligingspaVerificationResult._(
      isSuccess: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

/// Beveiligingspas verification exception
class BeveiligingspaVerificationException implements Exception {
  final String message;
  final String? code;

  const BeveiligingspaVerificationException(this.message, [this.code]);

  @override
  String toString() => 'BeveiligingspaVerificationException: $message';
}

/// Beveiligingspas Verification Service
/// 
/// Handles verification of Dutch security passes (beveiligingspas) as required by KvK 2025
/// Since no official Justis API is available, this service provides:
/// - Format validation
/// - Mock verification for development
/// - Manual verification workflow support
/// - Future API integration readiness
class BeveiligingspaVerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verify beveiligingspas number
  /// 
  /// Since Justis doesn't provide public API, this currently:
  /// 1. Validates format (7 digits)
  /// 2. Checks against local cache/manual verifications
  /// 3. Returns mock data for development
  /// 4. Supports future API integration
  static Future<BeveiligingspaVerificationResult> verifyPasNumber(
    String pasNumber, {
    File? documentFile,
  }) async {
    try {
      // Input validation
      if (pasNumber.isEmpty) {
        return BeveiligingspaVerificationResult.error(
          'Beveiligingspas nummer is verplicht',
          'EMPTY_PAS_NUMBER',
        );
      }

      // Format validation
      final validation = AuthService.validateBeveiligingspaDetailed(pasNumber);
      if (!validation.isValid) {
        return BeveiligingspaVerificationResult.error(
          validation.errorMessage,
          'INVALID_FORMAT',
        );
      }

      // Check local cache first (manual verifications)
      final cachedResult = await _checkLocalCache(pasNumber);
      if (cachedResult != null) {
        return cachedResult;
      }

      // Since no official API available, provide mock verification for development
      if (kDebugMode) {
        return await _mockVerification(pasNumber);
      }

      // In production, direct to manual verification process
      return await _initiateManualVerification(pasNumber, documentFile);

    } catch (e) {
      return BeveiligingspaVerificationResult.error(
        'Verificatie mislukt: ${e.toString()}',
        'VERIFICATION_ERROR',
      );
    }
  }

  /// Check locally cached/manually verified beveiligingspas data
  static Future<BeveiligingspaVerificationResult?> _checkLocalCache(
    String pasNumber
  ) async {
    try {
      final doc = await _firestore
          .collection('beveiligingspas_verifications')
          .doc(pasNumber)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = BeveiligingspaData.fromJson(doc.data()!);
        return BeveiligingspaVerificationResult.success(
          'Beveiligingspas gevonden in lokale database',
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
  static Future<BeveiligingspaVerificationResult> _mockVerification(
    String pasNumber
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    final mockData = BeveiligingspaData(
      pasNumber: pasNumber,
      holderName: 'Jan van der Berg',
      issueDate: DateTime.now().subtract(const Duration(days: 365)),
      expirationDate: DateTime.now().add(const Duration(days: 730)), // 2 years remaining
      status: BeveiligingspaStatus.verified,
      issuingAuthority: 'Justis (Mock)',
      authorizations: ['Algemene beveiliging', 'Toegangscontrole'],
    );

    return BeveiligingspaVerificationResult.success(
      'Mock verificatie succesvol (development mode)',
      mockData,
    );
  }

  /// Initiate manual verification process
  static Future<BeveiligingspaVerificationResult> _initiateManualVerification(
    String pasNumber,
    File? documentFile,
  ) async {
    // Store for manual review
    await _firestore
        .collection('manual_verifications')
        .doc('beveiligingspas_$pasNumber')
        .set({
      'type': 'beveiligingspas',
      'pasNumber': pasNumber,
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'pending_manual_review',
      'documentUrl': documentFile?.path,
    });

    return BeveiligingspaVerificationResult.error(
      'Beveiligingspas verificatie ingediend voor handmatige controle. '
      'U ontvangt binnen 1-2 werkdagen een statusupdate.',
      'MANUAL_VERIFICATION_REQUIRED',
    );
  }

  /// Store manual verification result (for admin use)
  static Future<void> storeManualVerificationResult(
    String pasNumber,
    BeveiligingspaData verificationData,
  ) async {
    await _firestore
        .collection('beveiligingspas_verifications')
        .doc(pasNumber)
        .set(verificationData.toJson());
  }

  /// Get all manual verification requests (for admin dashboard)
  static Future<List<Map<String, dynamic>>> getPendingManualVerifications() async {
    final query = await _firestore
        .collection('manual_verifications')
        .where('type', isEqualTo: 'beveiligingspas')
        .where('status', isEqualTo: 'pending_manual_review')
        .orderBy('requestedAt', descending: true)
        .get();

    return query.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }
}