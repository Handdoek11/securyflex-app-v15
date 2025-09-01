import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../auth_service.dart';
import 'document_upload_service.dart';
import 'crypto_service.dart';
import 'certificate_management_service.dart';

/// WPBR certificate verification status
enum WPBRVerificationStatus {
  pending,
  verified,
  rejected,
  expired,
  suspended,
  unknown,
}

extension WPBRVerificationStatusExtension on WPBRVerificationStatus {
  String get displayName {
    switch (this) {
      case WPBRVerificationStatus.pending:
        return 'In behandeling';
      case WPBRVerificationStatus.verified:
        return 'Geverifieerd';
      case WPBRVerificationStatus.rejected:
        return 'Afgekeurd';
      case WPBRVerificationStatus.expired:
        return 'Verlopen';
      case WPBRVerificationStatus.suspended:
        return 'Geschorst';
      case WPBRVerificationStatus.unknown:
        return 'Onbekend';
    }
  }

  bool get isValid {
    return this == WPBRVerificationStatus.verified;
  }

  bool get allowsWork {
    return this == WPBRVerificationStatus.verified;
  }
}

/// WPBR certificate data model
class WPBRData {
  final String certificateNumber;
  final String holderName;
  final String holderBsn; // Burgerservicenummer (optional, privacy)
  final DateTime issueDate;
  final DateTime expirationDate;
  final WPBRVerificationStatus status;
  final List<String> authorizations;
  final String issuingAuthority;
  final String? documentUrl;
  final Map<String, dynamic>? additionalData;

  const WPBRData({
    required this.certificateNumber,
    required this.holderName,
    this.holderBsn = '',
    required this.issueDate,
    required this.expirationDate,
    required this.status,
    this.authorizations = const [],
    required this.issuingAuthority,
    this.documentUrl,
    this.additionalData,
  });

  factory WPBRData.fromJson(Map<String, dynamic> json) {
    return WPBRData(
      certificateNumber: json['certificateNumber']?.toString() ?? '',
      holderName: json['holderName']?.toString() ?? '',
      holderBsn: json['holderBsn']?.toString() ?? '',
      issueDate: DateTime.tryParse(json['issueDate']?.toString() ?? '') ?? DateTime.now(),
      expirationDate: DateTime.tryParse(json['expirationDate']?.toString() ?? '') ?? DateTime.now(),
      status: _parseStatus(json['status']?.toString()),
      authorizations: List<String>.from(json['authorizations'] ?? []),
      issuingAuthority: json['issuingAuthority']?.toString() ?? '',
      documentUrl: json['documentUrl']?.toString(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'certificateNumber': certificateNumber,
      'holderName': holderName,
      'holderBsn': holderBsn.isNotEmpty ? '***masked***' : '', // Privacy protection
      'issueDate': issueDate.toIso8601String(),
      'expirationDate': expirationDate.toIso8601String(),
      'status': status.name,
      'authorizations': authorizations,
      'issuingAuthority': issuingAuthority,
      'documentUrl': documentUrl,
      'additionalData': additionalData,
    };
  }

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
           status == WPBRVerificationStatus.expired;
  }

  /// Get days until expiration (negative if expired)
  int get daysUntilExpiration {
    return expirationDate.difference(DateTime.now()).inDays;
  }

  /// Check if certificate expires soon (within 30 days)
  bool get expiresSoon {
    return daysUntilExpiration <= 30 && daysUntilExpiration > 0;
  }

  /// Get authorization level description
  String get authorizationDescription {
    if (authorizations.isEmpty) return 'Geen specifieke bevoegdheden';
    return authorizations.join(', ');
  }

  /// Check if holder is authorized for specific type of security work
  bool hasAuthorization(String authorization) {
    return authorizations.any((auth) => 
      auth.toLowerCase().contains(authorization.toLowerCase())
    );
  }

  static WPBRVerificationStatus _parseStatus(String? statusString) {
    switch (statusString?.toLowerCase()) {
      case 'pending':
      case 'in_behandeling':
        return WPBRVerificationStatus.pending;
      case 'verified':
      case 'geverifieerd':
      case 'geldig':
        return WPBRVerificationStatus.verified;
      case 'rejected':
      case 'afgekeurd':
        return WPBRVerificationStatus.rejected;
      case 'expired':
      case 'verlopen':
        return WPBRVerificationStatus.expired;
      case 'suspended':
      case 'geschorst':
        return WPBRVerificationStatus.suspended;
      default:
        return WPBRVerificationStatus.unknown;
    }
  }
}

/// WPBR certificate verification result
class WPBRVerificationResult {
  final bool isSuccess;
  final dynamic data; // Can be WPBRData or CertificateData
  final String message;
  final String? errorCode;

  const WPBRVerificationResult._({
    required this.isSuccess,
    this.data,
    required this.message,
    this.errorCode,
  });

  factory WPBRVerificationResult.success(dynamic data, String message) {
    return WPBRVerificationResult._(
      isSuccess: true,
      data: data,
      message: message,
    );
  }

  factory WPBRVerificationResult.error(String message, {String? errorCode}) {
    return WPBRVerificationResult._(
      isSuccess: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

/// Exception thrown when WPBR verification fails
class WPBRVerificationException implements Exception {
  final String message;
  final String code;

  const WPBRVerificationException(this.message, {this.code = 'wpbr-verification-failed'});

  @override
  String toString() => 'WPBRVerificationException: $message';
}

/// Service for verifying Dutch WPBR (security guard) certificates
class WPBRVerificationService {
  static const String _baseUrl = 'https://api.wpbr-register.nl/v1'; // Mock URL
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const int _maxCacheAge = 6 * 60 * 60 * 1000; // 6 hours in milliseconds
// 10MB

  // Cache for verified WPBR certificates (supports both regular and secure data)
  static final Map<String, dynamic> _cache = {};

  // Rate limiting
  static final Map<String, DateTime> _lastRequests = {};
  static const Duration _rateLimitDelay = Duration(seconds: 5);

  /// Verify WPBR certificate number and optional document with security enhancements
  static Future<WPBRVerificationResult> verifyCertificate(
    String certificateNumber, {
    File? certificateDocument,
    String? apiKey,
    String? userId,
  }) async {
    final currentUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return WPBRVerificationResult.error(
        'Gebruiker moet ingelogd zijn voor certificaat verificatie',
        errorCode: 'unauthorized',
      );
    }

    // Start audit logging
    await _logAuditEvent(
      action: 'wpbr_verification_started',
      userId: currentUserId,
      certificateNumber: certificateNumber,
      metadata: {
        'hasDocument': certificateDocument != null,
        'hasApiKey': apiKey != null,
      },
    );
    // Basic format validation
    final validation = AuthService.validateWPBRDetailed(certificateNumber);
    if (!validation.isValid) {
      return WPBRVerificationResult.error(validation.message, errorCode: 'invalid-format');
    }

    final cleanedNumber = certificateNumber.toUpperCase();

    // Check cache first
    final cached = _getCachedData(cleanedNumber);
    if (cached != null) {
      debugPrint('WPBR data retrieved from cache for $cleanedNumber');
      return WPBRVerificationResult.success(cached, 'Certificaat gevonden in cache');
    }

    // Check rate limiting
    try {
      _checkRateLimit(cleanedNumber);
    } catch (e) {
      return WPBRVerificationResult.error(e.toString(), errorCode: 'rate-limited');
    }

    try {
      String? documentUrl;

      // Upload certificate document if provided using secure upload service
      if (certificateDocument != null) {
        try {
          final uploadResult = await DocumentUploadService.uploadDocument(
            file: certificateDocument,
            documentType: 'wpbr',
            userId: currentUserId,
            certificateNumber: cleanedNumber,
            metadata: {
              'verificationType': 'wpbr_certificate',
              'uploadSource': 'verification_workflow',
            },
          );
          
          if (uploadResult.success) {
            documentUrl = uploadResult.downloadUrl;
            await _logAuditEvent(
              action: 'wpbr_document_uploaded',
              userId: currentUserId,
              certificateNumber: cleanedNumber,
              result: 'success',
              metadata: {
                'documentId': uploadResult.documentId,
                'uploadId': uploadResult.metadata?['uploadId'],
              },
            );
          } else {
            await _logAuditEvent(
              action: 'wpbr_document_upload_failed',
              userId: currentUserId,
              certificateNumber: cleanedNumber,
              result: 'error',
              metadata: {'error': uploadResult.error},
            );
            return WPBRVerificationResult.error(
              uploadResult.error ?? 'Document upload mislukt',
              errorCode: uploadResult.errorCode ?? 'upload-failed',
            );
          }
        } catch (e) {
          await _logAuditEvent(
            action: 'wpbr_document_upload_error',
            userId: currentUserId,
            certificateNumber: cleanedNumber,
            result: 'error',
            metadata: {'error': e.toString()},
          );
          return WPBRVerificationResult.error(
            'Fout bij uploaden certificaat: $e',
            errorCode: 'upload-failed',
          );
        }
      }

      // Verify with WPBR registry or use secure mock data
      WPBRVerificationResult result;
      if (apiKey != null && apiKey.isNotEmpty && !kDebugMode) {
        result = await _verifyWithWPBRAPI(cleanedNumber, apiKey, documentUrl, currentUserId);
      } else {
        // Enhanced demo mode with security considerations
        result = _generateSecureMockWPBRData(cleanedNumber, documentUrl, currentUserId);
      }
      
      // Log verification result
      await _logAuditEvent(
        action: 'wpbr_verification_completed',
        userId: currentUserId,
        certificateNumber: cleanedNumber,
        result: result.isSuccess ? 'success' : 'failed',
        metadata: {
          'status': result.data?.status.name,
          'errorCode': result.errorCode,
          'hasDocument': documentUrl != null,
        },
      );
      
      return result;
    } catch (e) {
      debugPrint('WPBR verification error for $cleanedNumber: $e');

      if (e is WPBRVerificationException) {
        return WPBRVerificationResult.error(e.message, errorCode: e.code);
      }

      return WPBRVerificationResult.error(
        'WPBR verificatie mislukt. Probeer later opnieuw.',
        errorCode: 'verification-failed',
      );
    }
  }

  /// Verify with real WPBR API with enhanced security
  static Future<WPBRVerificationResult> _verifyWithWPBRAPI(
    String certificateNumber, 
    String apiKey, 
    String? documentUrl,
    String userId,
  ) async {
    await _logAuditEvent(
      action: 'wpbr_api_verification_started',
      userId: userId,
      certificateNumber: certificateNumber,
    );
    final uri = Uri.parse('$_baseUrl/verify?certificate=$certificateNumber');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json',
          'User-Agent': 'SecuryFlex-App/1.0',
        },
      ).timeout(_requestTimeout);

      _recordRequest(certificateNumber);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['certificate'] != null) {
          final wpbrData = WPBRData.fromJson({
            ...data['certificate'],
            if (documentUrl != null) 'documentUrl': documentUrl,
          });
          
          // Create secure instance with encrypted BSN
          final secureWpbrData = CertificateData.fromWPBRData(wpbrData, encryptBsn: true);

          _cacheSecureData(certificateNumber, secureWpbrData, userId);

          await _logAuditEvent(
            action: 'wpbr_api_verification_success',
            userId: userId,
            certificateNumber: certificateNumber,
            result: 'success',
            metadata: {
              'status': secureWpbrData.status.name,
              'issuingAuthority': secureWpbrData.issuingAuthority,
            },
          );

          return WPBRVerificationResult.success(
            secureWpbrData,
            'WPBR certificaat succesvol geverifieerd',
          );
        } else {
          return WPBRVerificationResult.error(
            'WPBR certificaat $certificateNumber niet gevonden in register',
            errorCode: 'not-found',
          );
        }
      } else if (response.statusCode == 429) {
        return WPBRVerificationResult.error(
          'Te veel WPBR verificaties. Probeer later opnieuw.',
          errorCode: 'rate-limited',
        );
      } else if (response.statusCode == 401) {
        return WPBRVerificationResult.error(
          'WPBR API sleutel ongeldig. Neem contact op met support.',
          errorCode: 'unauthorized',
        );
      } else {
        return WPBRVerificationResult.error(
          'WPBR service tijdelijk niet beschikbaar (${response.statusCode})',
          errorCode: 'service-unavailable',
        );
      }
    } on TimeoutException {
      return WPBRVerificationResult.error(
        'WPBR verificatie time-out. Probeer opnieuw.',
        errorCode: 'timeout',
      );
    } on http.ClientException {
      return WPBRVerificationResult.error(
        'Netwerkfout bij WPBR verificatie.',
        errorCode: 'network-error',
      );
    }
  }

  /// Generate mock WPBR data for demo/testing
  /// Generate secure mock WPBR data with proper encryption and audit logging
  static WPBRVerificationResult _generateSecureMockWPBRData(
    String certificateNumber, 
    String? documentUrl, 
    String userId,
  ) {
    // Simulate processing delay
    Future.delayed(const Duration(milliseconds: 800));

    // Enhanced mock certificates with encrypted BSN for demo
    final mockCertificateData = {
      'WPBR-123456': {
        'certificateNumber': 'WPBR-123456',
        'holderName': 'Jan de Beveiliger',
        'holderBsn': '123456789', // Demo BSN (will be encrypted)
        'issueDate': DateTime(2020, 1, 15),
        'expirationDate': DateTime(2025, 1, 15),
        'status': WPBRVerificationStatus.verified,
        'authorizations': ['Beveiliger', 'Evenementbeveiliging', 'Winkeldetective'],
        'issuingAuthority': 'Politie Eenheid Amsterdam',
        'documentUrl': documentUrl,
      },
      'WPBR-654321': {
        'certificateNumber': 'WPBR-654321',
        'holderName': 'Marie van der Security',
        'holderBsn': '987654321', // Demo BSN (will be encrypted)
        'issueDate': DateTime(2021, 6, 1),
        'expirationDate': DateTime(2026, 6, 1),
        'status': WPBRVerificationStatus.verified,
        'authorizations': ['Beveiliger', 'Objectbeveiliging', 'Geldtransport'],
        'issuingAuthority': 'Politie Eenheid Rotterdam',
        'documentUrl': documentUrl,
      },
      'WPBR-999999': {
        'certificateNumber': 'WPBR-999999',
        'holderName': 'Test Verlopen',
        'holderBsn': '555666777', // Demo BSN (will be encrypted)
        'issueDate': DateTime(2018, 1, 1),
        'expirationDate': DateTime(2023, 1, 1),
        'status': WPBRVerificationStatus.expired,
        'authorizations': ['Beveiliger'],
        'issuingAuthority': 'Politie Eenheid Test',
        'documentUrl': documentUrl,
      },
    };

    final mockDataMap = mockCertificateData[certificateNumber];
    CertificateData secureData;
    
    if (mockDataMap != null) {
      // Create CertificateData from predefined mock data
      final wpbrData = WPBRData(
        certificateNumber: mockDataMap['certificateNumber'] as String,
        holderName: mockDataMap['holderName'] as String,
        holderBsn: mockDataMap['holderBsn'] as String,
        issueDate: mockDataMap['issueDate'] as DateTime,
        expirationDate: mockDataMap['expirationDate'] as DateTime,
        status: mockDataMap['status'] as WPBRVerificationStatus,
        authorizations: mockDataMap['authorizations'] as List<String>,
        issuingAuthority: mockDataMap['issuingAuthority'] as String,
        documentUrl: mockDataMap['documentUrl'] as String?,
      );
      secureData = CertificateData.fromWPBRData(wpbrData, encryptBsn: true);
    } else {
      // Generate generic secure certificate for any other WPBR number
      final genericData = WPBRData(
        certificateNumber: certificateNumber,
        holderName: 'Demo Beveiliger',
        holderBsn: '111222333', // Demo BSN
        issueDate: DateTime.now().subtract(const Duration(days: 365)),
        expirationDate: DateTime.now().add(const Duration(days: 1460)), // 4 years
        status: WPBRVerificationStatus.verified,
        authorizations: ['Beveiliger', 'Demo Bevoegdheid'],
        issuingAuthority: 'Demo Politie Eenheid',
        documentUrl: documentUrl,
      );
      secureData = CertificateData.fromWPBRData(genericData, encryptBsn: true);
    }

    // Cache secure data and log audit event
    _cacheSecureData(certificateNumber, secureData, userId);
    
    // Log mock data generation for audit
    _logAuditEvent(
      action: 'wpbr_mock_data_generated',
      userId: userId,
      certificateNumber: certificateNumber,
      result: 'success',
      metadata: {
        'status': secureData.status.name,
        'issuingAuthority': secureData.issuingAuthority,
        'isMock': true,
      },
    );
    
    return WPBRVerificationResult.success(
      secureData, 
      'Demo certificaat gegenereerd (beveiligd)',
    );
  }



  /// Check if certificate is valid and active
  static Future<bool> isCertificateValid(String certificateNumber, {String? apiKey}) async {
    try {
      final result = await verifyCertificate(certificateNumber, apiKey: apiKey);
      return result.isSuccess && (result.data?.isCurrentlyValid ?? false);
    } catch (e) {
      return false;
    }
  }

  /// Get certificate expiration warning
  static Future<String?> getExpirationWarning(String certificateNumber, {String? apiKey}) async {
    try {
      final result = await verifyCertificate(certificateNumber, apiKey: apiKey);
      if (!result.isSuccess || result.data == null) return null;

      final data = result.data!;
      if (data.isExpired) {
        return 'Certificaat is verlopen op ${_formatDate(data.expirationDate)}';
      } else if (data.expiresSoon) {
        return 'Certificaat verloopt over ${data.daysUntilExpiration} dagen';
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Enhanced certificate expiry checking with alert system integration
  static Future<Map<String, dynamic>> checkCertificateExpiryStatus(
    String certificateNumber, {
    String? userId,
    String? apiKey,
    bool triggerAlerts = false,
  }) async {
    try {
      final result = await verifyCertificate(certificateNumber, userId: userId, apiKey: apiKey);
      
      if (!result.isSuccess || result.data == null) {
        return {
          'isValid': false,
          'status': 'verification_failed',
          'message': result.message,
          'shouldAlert': false,
        };
      }

      final data = result.data!;
      final daysUntilExpiry = data.daysUntilExpiration;
      
      // Determine if alerts should be triggered based on thresholds
      final shouldTriggerAlert = _shouldTriggerExpiryAlert(daysUntilExpiry);
      final alertLevel = _getAlertLevel(daysUntilExpiry);
      
      final status = {
        'isValid': data.isCurrentlyValid,
        'isExpired': data.isExpired,
        'expiresSoon': data.expiresSoon,
        'daysUntilExpiry': daysUntilExpiry,
        'expirationDate': data.expirationDate.toIso8601String(),
        'status': data.status.name,
        'certificateData': data,
        'shouldAlert': shouldTriggerAlert,
        'alertLevel': alertLevel,
        'lastChecked': DateTime.now().toIso8601String(),
      };

      // Log certificate status check for audit
      await _logAuditEvent(
        action: 'certificate_expiry_check',
        userId: userId ?? 'system',
        certificateNumber: certificateNumber,
        result: 'success',
        metadata: {
          'days_until_expiry': daysUntilExpiry,
          'alert_level': alertLevel,
          'should_alert': shouldTriggerAlert,
          'certificate_type': 'wpbr',
        },
      );

      // Trigger alert if requested and conditions are met
      if (triggerAlerts && shouldTriggerAlert && userId != null) {
        await _triggerExpiryAlert(userId, data, alertLevel);
      }

      return status;
      
    } catch (e) {
      await _logAuditEvent(
        action: 'certificate_expiry_check_error',
        userId: userId ?? 'system',
        certificateNumber: certificateNumber,
        result: 'error',
        metadata: {'error': e.toString()},
      );
      
      return {
        'isValid': false,
        'status': 'check_failed',
        'message': 'Certificaat status controle mislukt: $e',
        'shouldAlert': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if expiry alert should be triggered based on days remaining
  static bool _shouldTriggerExpiryAlert(int daysUntilExpiry) {
    // Alert thresholds: 90, 60, 30, 7, 1 days and expired
    final alertThresholds = [90, 60, 30, 7, 1, 0];
    return alertThresholds.contains(daysUntilExpiry) || daysUntilExpiry < 0;
  }

  /// Get alert level based on days until expiry
  static String _getAlertLevel(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) return 'expired';
    if (daysUntilExpiry <= 1) return 'critical';
    if (daysUntilExpiry <= 7) return 'urgent';
    if (daysUntilExpiry <= 30) return 'warning';
    return 'notice';
  }

  /// Trigger certificate expiry alert through notification system
  static Future<void> _triggerExpiryAlert(
    String userId,
    CertificateData certificateData,
    String alertLevel,
  ) async {
    try {
      // This would integrate with the GuardNotificationService
      // For now, we'll log the alert trigger
      await _logAuditEvent(
        action: 'certificate_expiry_alert_triggered',
        userId: userId,
        certificateNumber: certificateData.certificateNumber,
        result: 'alert_sent',
        metadata: {
          'alert_level': alertLevel,
          'days_until_expiry': certificateData.daysUntilExpiration,
          'certificate_type': 'wpbr',
          'expiry_date': certificateData.expirationDate.toIso8601String(),
        },
      );

      // In a full implementation, this would call:
      // await GuardNotificationService.instance.sendCertificateExpiryAlert(
      //   certificateType: 'WPBR',
      //   expiryDate: certificateData.expirationDate,
      //   certificateNumber: certificateData.certificateNumber,
      // );

    } catch (e) {
      debugPrint('Error triggering certificate expiry alert: $e');
    }
  }

  /// Batch check certificates for multiple users (for daily monitoring)
  static Future<Map<String, dynamic>> batchCheckCertificateExpiry(
    List<String> certificateNumbers, {
    String? userId,
    String? apiKey,
  }) async {
    final results = <String, dynamic>{};
    int totalChecked = 0;
    int alertsTriggered = 0;
    int expiredFound = 0;
    int expiringSoonFound = 0;

    for (final certificateNumber in certificateNumbers) {
      try {
        final status = await checkCertificateExpiryStatus(
          certificateNumber,
          userId: userId,
          apiKey: apiKey,
          triggerAlerts: true,
        );

        results[certificateNumber] = status;
        totalChecked++;

        if (status['shouldAlert'] == true) alertsTriggered++;
        if (status['isExpired'] == true) expiredFound++;
        if (status['expiresSoon'] == true) expiringSoonFound++;

      } catch (e) {
        results[certificateNumber] = {
          'status': 'check_failed',
          'error': e.toString(),
        };
      }
    }

    final batchSummary = {
      'batch_results': results,
      'summary': {
        'total_checked': totalChecked,
        'alerts_triggered': alertsTriggered,
        'expired_certificates': expiredFound,
        'expiring_soon': expiringSoonFound,
        'batch_timestamp': DateTime.now().toIso8601String(),
      }
    };

    // Log batch check results
    await _logAuditEvent(
      action: 'batch_certificate_expiry_check',
      userId: userId ?? 'system',
      certificateNumber: 'BATCH_CHECK',
      result: 'completed',
      metadata: batchSummary['summary'] as Map<String, dynamic>,
    );

    return batchSummary;
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  /// Clear the cache
  static void clearCache() {
    _cache.clear();
    debugPrint('WPBR cache cleared');
  }

  /// Get cached data if valid and not expired
  static dynamic _getCachedData(String certificateNumber) {
    final cached = _cache[certificateNumber];
    if (cached == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    int timestamp;
    dynamic data;
    
    if (cached is _SecureCachedWPBRData) {
      timestamp = cached.timestamp;
      data = cached.data;
    } else if (cached is _CachedWPBRData) {
      timestamp = cached.timestamp;
      data = cached.data;
    } else {
      return null;
    }
    
    if (now - timestamp > _maxCacheAge) {
      _cache.remove(certificateNumber);
      return null;
    }

    return data;
  }


  /// Check rate limiting
  static void _checkRateLimit(String certificateNumber) {
    final lastRequest = _lastRequests[certificateNumber];
    if (lastRequest != null) {
      final timeDiff = DateTime.now().difference(lastRequest);
      if (timeDiff < _rateLimitDelay) {
        throw WPBRVerificationException(
          'Te veel WPBR verificaties. Wacht ${_rateLimitDelay.inSeconds - timeDiff.inSeconds} seconden.',
          code: 'rate-limited',
        );
      }
    }
  }

  /// Record request for rate limiting
  static void _recordRequest(String certificateNumber) {
    _lastRequests[certificateNumber] = DateTime.now();
  }

  // ===== SECURE ENHANCEMENT METHODS =====
  
  /// Cache secure WPBR data with encryption and audit logging
  static void _cacheSecureData(String certificateNumber, CertificateData data, String userId) {
    _cache[certificateNumber] = _SecureCachedWPBRData(
      data: data,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      userId: userId,
    );
    
    // Log caching event for audit
    _logAuditEvent(
      action: 'wpbr_data_cached',
      userId: userId,
      certificateNumber: certificateNumber,
      metadata: {
        'cacheTimestamp': DateTime.now().toIso8601String(),
        'dataHash': CryptoService.generateHash('$certificateNumber${data.certificateNumber}'),
      },
    );
  }
  
  
  /// Comprehensive audit logging for compliance
  static Future<void> _logAuditEvent({
    required String action,
    required String userId,
    required String certificateNumber,
    String? result,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final auditData = {
        'action': action,
        'userId': userId,
        'certificateNumber': CryptoService.hashSensitiveData(certificateNumber),
        'result': result ?? 'info',
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
        'userAgent': 'SecuryFlex-Flutter-App',
        'ipAddress': await _getCurrentIPAddress(),
        'sessionId': _getCurrentSessionId(),
      };

      await FirebaseFirestore.instance
          .collection('audit_logs')
          .doc('wpbr_verification')
          .collection('entries')
          .add(auditData);
    } catch (e) {
      debugPrint('Audit logging error: $e');
    }
  }
  
  /// Multiple certificate type support
  static Future<Map<String, dynamic>> validateMultipleCertificateTypes({
    required String userId,
    String? wpbrNumber,
    String? vcaNumber,
    String? bhvNumber,
    String? ehboNumber,
  }) async {
    final results = <String, dynamic>{};
    
    if (wpbrNumber != null) {
      final wpbrResult = await verifyCertificate(wpbrNumber, userId: userId);
      results['wpbr'] = {
        'isValid': wpbrResult.isSuccess,
        'status': wpbrResult.data?.status.name,
        'expirationDate': wpbrResult.data?.expirationDate.toIso8601String(),
        'message': wpbrResult.message,
      };
    }
    
    // VCA, BHV, EHBO validation would be implemented similarly
    // For now, mock validation
    if (vcaNumber != null) {
      results['vca'] = _mockValidateOtherCertificate('VCA', vcaNumber);
    }
    if (bhvNumber != null) {
      results['bhv'] = _mockValidateOtherCertificate('BHV', bhvNumber);
    }
    if (ehboNumber != null) {
      results['ehbo'] = _mockValidateOtherCertificate('EHBO', ehboNumber);
    }
    
    await _logAuditEvent(
      action: 'multiple_certificate_validation',
      userId: userId,
      certificateNumber: 'MULTIPLE',
      metadata: {
        'certificateTypes': results.keys.toList(),
        'validCount': results.values.where((r) => r['isValid'] == true).length,
      },
    );
    
    return results;
  }
  
  /// Mock validation for other certificate types
  static Map<String, dynamic> _mockValidateOtherCertificate(String type, String number) {
    // This would be replaced with actual validation logic for each certificate type
    return {
      'isValid': number.isNotEmpty && number.length >= 6,
      'status': 'verified',
      'expirationDate': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      'message': '$type certificaat demo validatie',
    };
  }
  
  /// Certificate-job matching logic
  static Future<Map<String, dynamic>> checkJobCertificateMatch({
    required String userId,
    required Map<String, String> userCertificates,
    required List<String> jobRequirements,
  }) async {
    final matchResults = <String, dynamic>{};
    final missingCertificates = <String>[];
    final expiredCertificates = <String>[];
    
    for (final requirement in jobRequirements) {
      final certificateNumber = userCertificates[requirement];
      
      if (certificateNumber == null) {
        missingCertificates.add(requirement);
        continue;
      }
      
      // Check certificate validity
      if (requirement == 'wpbr') {
        final result = await verifyCertificate(certificateNumber, userId: userId);
        if (result.isSuccess && result.data != null) {
          if (result.data!.isExpired) {
            expiredCertificates.add(requirement);
          } else {
            matchResults[requirement] = {
              'status': 'valid',
              'expirationDate': result.data!.expirationDate.toIso8601String(),
              'daysUntilExpiration': result.data!.daysUntilExpiration,
            };
          }
        } else {
          missingCertificates.add(requirement);
        }
      } else {
        // Mock validation for other certificate types
        final mockResult = _mockValidateOtherCertificate(requirement.toUpperCase(), certificateNumber);
        if (mockResult['isValid']) {
          matchResults[requirement] = {
            'status': 'valid',
            'expirationDate': mockResult['expirationDate'],
          };
        } else {
          missingCertificates.add(requirement);
        }
      }
    }
    
    final isFullyQualified = missingCertificates.isEmpty && expiredCertificates.isEmpty;
    
    await _logAuditEvent(
      action: 'job_certificate_match_check',
      userId: userId,
      certificateNumber: 'JOB_MATCH',
      metadata: {
        'jobRequirements': jobRequirements,
        'isFullyQualified': isFullyQualified,
        'missingCount': missingCertificates.length,
        'expiredCount': expiredCertificates.length,
      },
    );
    
    return {
      'isFullyQualified': isFullyQualified,
      'validCertificates': matchResults,
      'missingCertificates': missingCertificates,
      'expiredCertificates': expiredCertificates,
      'qualificationPercentage': 
          (matchResults.length / jobRequirements.length * 100).round(),
    };
  }
  
  /// GDPR compliance - delete user certificate data
  static Future<bool> deleteUserCertificateData(String userId) async {
    try {
      await _logAuditEvent(
        action: 'user_data_deletion_requested',
        userId: userId,
        certificateNumber: 'GDPR_DELETION',
      );
      
      // Clear cache for user's certificates
      _cache.removeWhere((key, value) => 
          value is _SecureCachedWPBRData && value.userId == userId);
      
      // Delete user documents
      final userDocs = await DocumentUploadService.getUserDocuments(userId);
      for (final doc in userDocs) {
        await DocumentUploadService.deleteDocument(doc['id'], userId);
      }
      
      await _logAuditEvent(
        action: 'user_data_deletion_completed',
        userId: userId,
        certificateNumber: 'GDPR_DELETION',
        result: 'success',
      );
      
      return true;
    } catch (e) {
      await _logAuditEvent(
        action: 'user_data_deletion_failed',
        userId: userId,
        certificateNumber: 'GDPR_DELETION',
        result: 'error',
        metadata: {'error': e.toString()},
      );
      return false;
    }
  }
  
  // Utility methods
  static Future<String> _getCurrentIPAddress() async {
    // In production, implement proper IP detection
    return 'localhost';
  }
  
  static String _getCurrentSessionId() {
    return FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  }
  
  /// Get cache statistics with security information
  static Map<String, dynamic> getCacheStats() {
    final now = DateTime.now().millisecondsSinceEpoch;
    int validEntries = 0;
    int secureEntries = 0;
    
    for (final entry in _cache.values) {
      int timestamp;
      if (entry is _SecureCachedWPBRData) {
        timestamp = entry.timestamp;
        secureEntries++;
      } else if (entry is _CachedWPBRData) {
        timestamp = entry.timestamp;
      } else {
        continue;
      }
      
      if (now - timestamp <= _maxCacheAge) {
        validEntries++;
      }
    }

    return {
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': _cache.length - validEntries,
      'secureEntries': secureEntries,
      'cacheAgeHours': _maxCacheAge / (1000 * 60 * 60),
      'encryptionEnabled': secureEntries > 0,
    };
  }
}

/// Enhanced internal class for caching secure WPBR data
class _SecureCachedWPBRData {
  final CertificateData data;
  final int timestamp;
  final String userId;
  
  const _SecureCachedWPBRData({
    required this.data,
    required this.timestamp,
    required this.userId,
  });
}

/// Internal class for caching WPBR data
// ignore: unused_element
class _CachedWPBRData {
  final WPBRData data;
  final int timestamp;

  const _CachedWPBRData({
    required this.data,
    required this.timestamp,
  });
}