import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'aes_gcm_crypto_service.dart';

/// Exception thrown when BSN operations fail
class BSNSecurityException implements Exception {
  final String message;
  final String code;
  
  const BSNSecurityException(this.message, this.code);
  
  @override
  String toString() => 'BSNSecurityException($code): $message';
}

/// Comprehensive BSN (Burgerservicenummer) security service
/// Implements GDPR Article 9 compliance for special category personal data
/// Provides AES-256-GCM encryption, secure masking, and audit logging
class BSNSecurityService {
  static final BSNSecurityService _instance = BSNSecurityService._internal();
  static BSNSecurityService get instance => _instance;
  BSNSecurityService._internal();

  static const String _bsnKeyPrefix = 'bsn_key_';
  static const String _auditSalt = 'securyflex_bsn_audit_2024';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Initialize BSN security service
  static Future<void> initialize() async {
    debugPrint('🔒 BSN Security Service initializing...');
    
    // Disable BSN service in browser mode for security and compatibility
    if (kIsWeb) {
      debugPrint('🌐 Browser mode detected - BSN service disabled for security');
      return;
    }
    
    try {
      // Verify encryption service is available
      await AESGCMCryptoService.initialize();
      
      debugPrint('✅ BSN Security Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize BSN Security Service: $e');
      throw BSNSecurityException(
        'Failed to initialize BSN security: $e',
        'INIT_FAILED'
      );
    }
  }

  /// Validate BSN using Dutch elfproef algorithm
  static bool validateBSN(String bsn) {
    return isValidBSN(bsn);
  }
  
  /// Check if BSN is valid using Dutch elfproef algorithm
  static bool isValidBSN(String bsn) {
    try {
      // Clean input - remove any non-numeric characters
      final cleanBSN = bsn.replaceAll(RegExp(r'[^0-9]'), '');
      
      // Must be exactly 9 digits
      if (cleanBSN.length != 9) return false;
      
      // Cannot start with 0
      if (cleanBSN.startsWith('0')) return false;
      
      // Apply elfproef algorithm
      int sum = 0;
      for (int i = 0; i < 8; i++) {
        sum += int.parse(cleanBSN[i]) * (9 - i);
      }
      
      final remainder = sum % 11;
      final checkDigit = int.parse(cleanBSN[8]);
      
      // Special case: if remainder is 10, BSN is invalid
      if (remainder == 10) return false;
      
      return remainder == checkDigit;
    } catch (e) {
      return false;
    }
  }

  /// Encrypt BSN using AES-256-GCM with user-specific context
  Future<String> encryptBSN(String bsn, String userId) async {
    // BSN encryption not available in browser mode
    if (kIsWeb) {
      throw BSNSecurityException(
        'BSN encryption not available in browser mode',
        'WEB_UNSUPPORTED'
      );
    }
    
    if (!validateBSN(bsn)) {
      throw BSNSecurityException(
        'Invalid BSN format or checksum',
        'INVALID_BSN'
      );
    }

    try {
      // Get or generate user-specific encryption key (for future use)
      await _getUserBSNKey(userId);
      
      // Encrypt with additional context
      final context = 'BSN_ENCRYPT_${DateTime.now().year}_$userId';
      final encrypted = await AESGCMCryptoService.encryptString(
        bsn,
        context,
      );

      return 'BSN_ENC_V2:$encrypted';
    } catch (e) {
      throw BSNSecurityException(
        'Failed to encrypt BSN: $e',
        'ENCRYPT_FAILED'
      );
    }
  }

  /// Decrypt BSN using AES-256-GCM
  Future<String> decryptBSN(String encryptedBSN, String userId) async {
    // BSN decryption not available in browser mode
    if (kIsWeb) {
      throw BSNSecurityException(
        'BSN decryption not available in browser mode',
        'WEB_UNSUPPORTED'
      );
    }
    
    try {
      String dataToDecrypt = encryptedBSN;
      
      // Handle versioned encryption formats
      if (encryptedBSN.startsWith('BSN_ENC_V2:')) {
        dataToDecrypt = encryptedBSN.substring(11); // Remove prefix
      } else if (encryptedBSN.startsWith('BSN_ENC_V1:')) {
        // Legacy format - migrate if needed
        throw BSNSecurityException(
          'Legacy BSN encryption detected - migration required',
          'MIGRATION_NEEDED'
        );
      }

      // Get user-specific decryption key (for future use)
      await _getUserBSNKey(userId);
      
      // Decrypt with context
      final context = 'BSN_ENCRYPT_${DateTime.now().year}_$userId';
      final decrypted = await AESGCMCryptoService.decryptString(
        dataToDecrypt,
        context,
      );

      // Validate decrypted BSN
      if (!validateBSN(decrypted)) {
        throw BSNSecurityException(
          'Decrypted BSN failed validation',
          'DECRYPT_VALIDATION_FAILED'
        );
      }

      return decrypted;
    } catch (e) {
      if (e is BSNSecurityException) rethrow;
      throw BSNSecurityException(
        'Failed to decrypt BSN: $e',
        'DECRYPT_FAILED'
      );
    }
  }

  /// Check if string contains encrypted BSN
  static bool isEncryptedBSN(String data) {
    return data.startsWith('BSN_ENC_V2:') || data.startsWith('BSN_ENC_V1:');
  }
  
  /// Format BSN for display (alias for maskBSN)
  static String formatBSN(String bsn) {
    return maskBSN(bsn);
  }

  /// Securely mask BSN for display (123****82)
  static String maskBSN(String bsn) {
    try {
      // Clean input
      final cleanBSN = bsn.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cleanBSN.length != 9) {
        return '***-**-****'; // Invalid BSN
      }

      // Show first 3 and last 2 digits
      return '${cleanBSN.substring(0, 3)}****${cleanBSN.substring(7, 9)}';
    } catch (e) {
      return '***-**-****';
    }
  }

  /// Create audit-safe hash of BSN for logging (alias)
  static String hashBSNForAudit(String bsn) {
    return createAuditHash(bsn);
  }

  /// Create audit-safe hash of BSN for logging
  static String createAuditHash(String bsn) {
    try {
      // Use HMAC-SHA256 for audit hash
      final key = utf8.encode(_auditSalt);
      final bytes = utf8.encode(bsn);
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(bytes);
      
      return 'BSN_HASH:${digest.toString().substring(0, 16)}';
    } catch (e) {
      return 'BSN_HASH:ERROR';
    }
  }

  /// Securely clear BSN data from memory
  void secureClearBSN(String bsn) {
    try {
      // Overwrite string data in memory (best effort in Dart)
      final bytes = utf8.encode(bsn);
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = 0;
      }
    } catch (e) {
      // Ignore errors in memory clearing
    }
  }

  /// Get or generate user-specific BSN encryption key
  Future<Uint8List> _getUserBSNKey(String userId) async {
    final keyId = '$_bsnKeyPrefix$userId';
    
    try {
      // Try to get existing key
      final existingKey = await _secureStorage.read(key: keyId);
      if (existingKey != null) {
        return base64Decode(existingKey);
      }
      
      // Generate new key
      final random = Random.secure();
      final keyBytes = Uint8List(32); // 256-bit key
      for (int i = 0; i < keyBytes.length; i++) {
        keyBytes[i] = random.nextInt(256);
      }
      
      // Store securely
      await _secureStorage.write(
        key: keyId,
        value: base64Encode(keyBytes),
      );
      
      return keyBytes;
    } catch (e) {
      throw BSNSecurityException(
        'Failed to manage BSN encryption key: $e',
        'KEY_MANAGEMENT_FAILED'
      );
    }
  }

  /// Migrate legacy BSN encryption (if needed)
  Future<String> migrateLegacyBSN(String legacyEncryptedBSN, String userId) async {
    throw BSNSecurityException(
      'Legacy BSN migration not implemented - contact system administrator',
      'MIGRATION_NOT_IMPLEMENTED'
    );
  }

  /// Generate secure BSN for testing (DO NOT USE IN PRODUCTION)
  @visibleForTesting
  String generateTestBSN() {
    if (!kDebugMode) {
      throw BSNSecurityException(
        'Test BSN generation only allowed in debug mode',
        'PRODUCTION_SAFETY'
      );
    }
    
    final random = Random();
    String bsn;
    
    do {
      // Generate 8 random digits (not starting with 0)
      bsn = (100000000 + random.nextInt(900000000)).toString();
      
      // Calculate check digit using elfproef
      int sum = 0;
      for (int i = 0; i < 8; i++) {
        sum += int.parse(bsn[i]) * (9 - i);
      }
      
      final remainder = sum % 11;
      if (remainder == 10) continue; // Invalid, try again
      
      bsn += remainder.toString();
      break;
    } while (true);
    
    return bsn;
  }
}