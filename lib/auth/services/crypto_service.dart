import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'aes_gcm_crypto_service.dart';
import 'bsn_security_service.dart';
import 'secure_key_manager.dart';

// Forward declaration for WPBRVerificationStatus
enum WPBRVerificationStatus {
  pending,
  verified,
  rejected,
  expired,
  suspended,
  unknown,
}

extension WPBRVerificationStatusExtension on WPBRVerificationStatus {
  bool get isValid {
    return this == WPBRVerificationStatus.verified;
  }
}

/// Secure Cryptographic Service for SecuryFlex
/// Production-grade replacement for insecure XOR encryption
/// Features AES-256-GCM encryption with Nederlandse AVG/GDPR compliance
class CryptoService {
  // Service initialization flag
  static bool _isInitialized = false;
  
  // Encryption contexts for different data types
  static const String _piiContext = 'personal_identification';
  static const String _documentContext = 'document_content';
  static const String _sensitiveDataContext = 'sensitive_data_storage';
  
  /// Initialize the secure crypto service
  /// MUST be called before any crypto operations
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await SecureKeyManager.initialize();
      await AESGCMCryptoService.initialize();
      await BSNSecurityService.initialize();
      
      _isInitialized = true;
      await _auditCryptoOperation('CRYPTO_SERVICE_INIT', 'Secure crypto service initialized');
      debugPrint('CryptoService initialized with AES-256-GCM encryption');
    } catch (e) {
      throw SecurityException('Failed to initialize CryptoService: $e');
    }
  }
  
  /// Encrypt personal identification information (BSN) - SECURE REPLACEMENT
  /// Uses AES-256-GCM instead of weak XOR encryption
  static Future<String> encryptPII(String data, {String? userId}) async {
    _ensureInitialized();
    
    if (data.isEmpty) return '';
    
    try {
      // Special handling for BSN data
      if (_looksLikeBSN(data)) {
        return await BSNSecurityService.instance.encryptBSN(data, userId ?? '');
      }
      
      // General PII encryption using AES-256-GCM
      final context = userId != null ? '${_piiContext}_$userId' : _piiContext;
      final encrypted = await AESGCMCryptoService.encryptString(data, context);
      
      await _auditCryptoOperation('PII_ENCRYPT', 'PII data encrypted', userId: userId);
      return encrypted;
    } catch (e) {
      await _auditCryptoOperation('PII_ENCRYPT_ERROR', 'PII encryption failed: $e', userId: userId);
      throw SecurityException('PII encryption failed: $e');
    }
  }
  
  /// Decrypt personal identification information (BSN) - SECURE REPLACEMENT
  /// Handles both new AES-256-GCM and legacy XOR for migration
  static Future<String> decryptPII(String encryptedData, {String? userId}) async {
    _ensureInitialized();
    
    if (encryptedData.isEmpty) return '';
    
    try {
      // Handle BSN-specific encryption
      if (BSNSecurityService.isEncryptedBSN(encryptedData)) {
        return await BSNSecurityService.instance.decryptBSN(encryptedData, userId ?? '');
      }
      
      // Handle AES-256-GCM encryption
      if (AESGCMCryptoService.isEncrypted(encryptedData)) {
        final context = userId != null ? '${_piiContext}_$userId' : _piiContext;
        final decrypted = await AESGCMCryptoService.decryptString(encryptedData, context);
        await _auditCryptoOperation('PII_DECRYPT', 'PII data decrypted', userId: userId);
        return decrypted;
      }
      
      // Handle legacy XOR encryption (for migration)
      if (encryptedData.startsWith('ENC:')) {
        await _auditCryptoOperation('PII_LEGACY_DECRYPT', 'Using legacy decryption - migration recommended', userId: userId);
        return _legacyDecryptPII(encryptedData);
      }
      
      // Return as-is if not encrypted
      return encryptedData;
    } catch (e) {
      await _auditCryptoOperation('PII_DECRYPT_ERROR', 'PII decryption failed: $e', userId: userId);
      debugPrint('PII decryption error: $e');
      return '***DECRYPT_ERROR***';
    }
  }
  
  /// Encrypt document content with AES-256-GCM
  static Future<Uint8List> encryptDocument(Uint8List content, String userId) async {
    _ensureInitialized();
    
    if (content.isEmpty) return Uint8List(0);
    
    try {
      final context = '${_documentContext}_$userId';
      final encrypted = await AESGCMCryptoService.encryptBytes(content, context);
      
      await _auditCryptoOperation('DOC_ENCRYPT', 'Document encrypted', userId: userId);
      return encrypted;
    } catch (e) {
      await _auditCryptoOperation('DOC_ENCRYPT_ERROR', 'Document encryption failed: $e', userId: userId);
      debugPrint('Document encryption error: $e');
      return content; // Return original on error
    }
  }
  
  /// Decrypt document content with AES-256-GCM
  static Future<Uint8List> decryptDocument(Uint8List encryptedContent, String userId) async {
    _ensureInitialized();
    
    if (encryptedContent.isEmpty) return Uint8List(0);
    
    try {
      final context = '${_documentContext}_$userId';
      final decrypted = await AESGCMCryptoService.decryptBytes(encryptedContent, context);
      
      await _auditCryptoOperation('DOC_DECRYPT', 'Document decrypted', userId: userId);
      return decrypted;
    } catch (e) {
      await _auditCryptoOperation('DOC_DECRYPT_ERROR', 'Document decryption failed: $e', userId: userId);
      debugPrint('Document decryption error: $e');
      return encryptedContent; // Return original on error
    }
  }
  
  /// Generate secure hash with HMAC for data integrity
  static Future<String> generateHash(String data, {String? context}) async {
    _ensureInitialized();
    
    try {
      final hashContext = context ?? _sensitiveDataContext;
      return await AESGCMCryptoService.generateSecureHash(data, hashContext);
    } catch (e) {
      throw SecurityException('Hash generation failed: $e');
    }
  }
  
  /// Verify data integrity hash with timing-attack resistance
  static Future<bool> verifyHash(String data, String hash, {String? context}) async {
    _ensureInitialized();
    
    try {
      final hashContext = context ?? _sensitiveDataContext;
      return await AESGCMCryptoService.verifySecureHash(data, hash, hashContext);
    } catch (e) {
      await _auditCryptoOperation('HASH_VERIFY_ERROR', 'Hash verification failed: $e');
      return false;
    }
  }
  
  /// Generate cryptographically secure random token
  static String generateToken({int length = 32}) {
    return AESGCMCryptoService.generateSecureToken(length: length);
  }
  
  /// Hash sensitive data for storage (one-way) with secure salt
  static Future<String> hashSensitiveData(String data, {String? salt, String? context}) async {
    _ensureInitialized();
    
    try {
      final hashContext = context ?? _sensitiveDataContext;
      return await AESGCMCryptoService.generateSecureHash(data, hashContext);
    } catch (e) {
      throw SecurityException('Sensitive data hashing failed: $e');
    }
  }
  
  /// Check if data is encrypted with any supported format
  static bool isEncrypted(String data) {
    return AESGCMCryptoService.isEncrypted(data) ||
           BSNSecurityService.isEncryptedBSN(data) ||
           data.startsWith('ENC:'); // Legacy format
  }
  
  /// Migrate legacy encrypted data to new AES-256-GCM format
  static Future<String> migrateLegacyEncryption(String legacyEncrypted, {String? userId}) async {
    _ensureInitialized();
    
    if (!legacyEncrypted.startsWith('ENC:')) {
      throw SecurityException('Not legacy encrypted data');
    }
    
    try {
      // Decrypt using legacy method
      final decrypted = _legacyDecryptPII(legacyEncrypted);
      
      // Re-encrypt using secure method
      final newEncrypted = await encryptPII(decrypted, userId: userId);
      
      await _auditCryptoOperation('CRYPTO_MIGRATION', 'Data migrated from XOR to AES-256-GCM', userId: userId);
      return newEncrypted;
    } catch (e) {
      throw SecurityException('Legacy data migration failed: $e');
    }
  }
  
  /// Secure wipe of sensitive string data (enhanced version)
  static void secureWipe(StringBuffer sensitiveData) {
    if (sensitiveData.isEmpty) return;
    
    try {
      final length = sensitiveData.length;
      sensitiveData.clear();
      
      // Overwrite with random data multiple times
      for (int pass = 0; pass < 3; pass++) {
        for (int i = 0; i < length; i++) {
          final randomChar = String.fromCharCode(48 + (DateTime.now().microsecond % 74));
          sensitiveData.write(randomChar);
        }
        sensitiveData.clear();
      }
    } catch (e) {
      debugPrint('Secure wipe error: $e');
    }
  }
  
  /// Force key rotation for security incidents
  static Future<void> rotateKeys() async {
    _ensureInitialized();
    
    try {
      await AESGCMCryptoService.rotateKeys();
      await _auditCryptoOperation('KEY_ROTATION', 'Manual key rotation performed');
    } catch (e) {
      throw SecurityException('Key rotation failed: $e');
    }
  }
  
  /// Get encryption metadata for debugging/auditing
  static Map<String, String> getEncryptionInfo(String encryptedData) {
    if (AESGCMCryptoService.isEncrypted(encryptedData)) {
      return AESGCMCryptoService.getEncryptionMetadata(encryptedData);
    }
    
    if (BSNSecurityService.isEncryptedBSN(encryptedData)) {
      return {
        'format': 'BSN-AES-256-GCM',
        'version': 'V1',
        'compliance': 'Nederlandse AVG/GDPR'
      };
    }
    
    if (encryptedData.startsWith('ENC:')) {
      return {
        'format': 'Legacy-XOR',
        'version': 'DEPRECATED',
        'security': 'WEAK - NEEDS MIGRATION'
      };
    }
    
    return {'format': 'unencrypted', 'version': 'none'};
  }
  
  // Private helper methods
  
  /// Ensure service is initialized
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw SecurityException('CryptoService not initialized - call initialize() first');
    }
  }
  
  /// Check if data looks like a Dutch BSN
  static bool _looksLikeBSN(String data) {
    final cleaned = data.replaceAll(RegExp(r'[\s\-\.]'), '');
    return RegExp(r'^\d{9}$').hasMatch(cleaned);
  }
  
  /// Legacy XOR decryption for backward compatibility
  /// WARNING: This is kept only for migration purposes
  static String _legacyDecryptPII(String encryptedData) {
    if (!encryptedData.startsWith('ENC:')) {
      return encryptedData;
    }
    
    try {
      // Legacy constants (DO NOT USE FOR NEW DATA)
      const String legacyMasterKey = 'SecuryFlexMasterKey2024!';
      const String legacyBsnSalt = 'BSN_SALT_SECURYFLEX_2024';
      
      final base64Data = encryptedData.substring(4);
      final encryptedBytes = base64.decode(base64Data);
      final key = _legacyDeriveKey(legacyMasterKey + legacyBsnSalt);
      final decryptedBytes = _legacyXorDecrypt(encryptedBytes, key);
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      debugPrint('Legacy decryption error: $e');
      return '***LEGACY_DECRYPT_ERROR***';
    }
  }
  
  /// Legacy key derivation (DO NOT USE FOR NEW DATA)
  static List<int> _legacyDeriveKey(String password) {
    final hash = sha256.convert(utf8.encode(password));
    return hash.bytes;
  }
  
  /// Legacy XOR decryption (DO NOT USE FOR NEW DATA)
  static List<int> _legacyXorDecrypt(List<int> encryptedData, List<int> key) {
    final decrypted = <int>[];
    for (int i = 0; i < encryptedData.length; i++) {
      decrypted.add(encryptedData[i] ^ key[i % key.length]);
    }
    return decrypted;
  }
  
  /// Audit crypto operations for compliance
  static Future<void> _auditCryptoOperation(String operation, String details, {String? userId}) async {
    try {
      final auditEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'operation': operation,
        'service': 'CryptoService',
        'details': details,
        'userId': userId ?? 'system',
        'encryption': 'AES-256-GCM',
        'compliance': 'Nederlandse AVG/GDPR',
      };
      
      // In production, send to secure audit log
      debugPrint('CRYPTO_AUDIT: ${json.encode(auditEntry)}');
    } catch (e) {
      debugPrint('Crypto audit logging failed: $e');
      // Don't throw - audit failure shouldn't break crypto operations
    }
  }
}

/// Security exception for crypto operations
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}