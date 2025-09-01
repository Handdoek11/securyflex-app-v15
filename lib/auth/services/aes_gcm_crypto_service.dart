import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' hide Key;
import 'package:flutter/foundation.dart' hide Key;
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'secure_key_manager.dart';

/// Production-grade AES-256-GCM Encryption Service
/// Implements authenticated encryption with integrity verification
/// Complies with Nederlandse AVG/GDPR requirements for sensitive data
class AESGCMCryptoService {
  // Encryption parameters
  static const int _nonceLength = 12; // 96 bits for GCM (recommended)
  static const int _tagLength = 16; // 128 bits authentication tag
  static const String _encryptionPrefix = 'AES256_GCM_V1';
  
  // Initialize flag
  static bool _isInitialized = false;
  
  /// Initialize the crypto service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await SecureKeyManager.initialize();
      
      // Verify crypto capabilities
      await _verifyCryptoCapabilities();
      
      _isInitialized = true;
      await _auditCryptoOperation('CRYPTO_INIT', 'AES-GCM service initialized');
      debugPrint('AESGCMCryptoService initialized successfully');
    } catch (e) {
      throw SecurityException('Failed to initialize AES-GCM service: $e');
    }
  }
  
  /// Encrypt data with AES-256-GCM
  static Future<String> encryptString(String plaintext, String context) async {
    _ensureInitialized();
    
    if (plaintext.isEmpty) return '';
    
    try {
      final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
      final encryptedBytes = await encryptBytes(plaintextBytes, context);
      
      // Return base64 encoded with versioned prefix
      return '$_encryptionPrefix:${base64.encode(encryptedBytes)}';
    } catch (e) {
      await _auditCryptoOperation('ENCRYPT_ERROR', 'Encryption failed for context $context: $e');
      throw SecurityException('String encryption failed: $e');
    }
  }
  
  /// Decrypt string with AES-256-GCM
  static Future<String> decryptString(String encryptedData, String context) async {
    _ensureInitialized();
    
    if (encryptedData.isEmpty) return '';
    
    try {
      // Handle different encryption formats for backward compatibility
      if (!encryptedData.contains(':')) {
        throw SecurityException('Invalid encryption format - missing version prefix');
      }
      
      final colonIndex = encryptedData.indexOf(':');
      if (colonIndex == -1) {
        throw SecurityException('Invalid encryption format - missing version prefix');
      }
      
      final version = encryptedData.substring(0, colonIndex);
      final data = encryptedData.substring(colonIndex + 1);
      
      if (version != _encryptionPrefix) {
        throw SecurityException('Unsupported encryption version: $version');
      }
      
      final encryptedBytes = base64.decode(data);
      final decryptedBytes = await decryptBytes(encryptedBytes, context);
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      await _auditCryptoOperation('DECRYPT_ERROR', 'Decryption failed for context $context: $e');
      throw SecurityException('String decryption failed: $e');
    }
  }
  
  /// Encrypt bytes with AES-256-GCM
  static Future<Uint8List> encryptBytes(Uint8List plaintext, String context) async {
    _ensureInitialized();
    
    if (plaintext.isEmpty) return Uint8List(0);
    
    try {
      // Get context-specific encryption key
      final key = await SecureKeyManager.getEncryptionKey(context);
      
      // Generate cryptographically secure nonce
      final nonce = _generateSecureNonce();
      
      // Create AES-GCM cipher
      final aesKey = encrypt_lib.Key(key);
      final cipher = Encrypter(AES(aesKey, mode: AESMode.gcm));
      
      // Encrypt with authentication
      final encrypted = cipher.encryptBytes(plaintext, iv: IV(nonce));
      
      // Combine nonce + ciphertext + tag
      final result = Uint8List(_nonceLength + encrypted.bytes.length);
      result.setRange(0, _nonceLength, nonce);
      result.setRange(_nonceLength, result.length, encrypted.bytes);
      
      await _auditCryptoOperation('ENCRYPT_SUCCESS', 'Data encrypted for context: $context');
      return result;
    } catch (e) {
      await _auditCryptoOperation('ENCRYPT_ERROR', 'Byte encryption failed for context $context: $e');
      throw SecurityException('Byte encryption failed: $e');
    }
  }
  
  /// Decrypt bytes with AES-256-GCM and verify integrity
  static Future<Uint8List> decryptBytes(Uint8List encryptedData, String context) async {
    _ensureInitialized();
    
    if (encryptedData.isEmpty) return Uint8List(0);
    
    try {
      if (encryptedData.length < _nonceLength + _tagLength) {
        throw SecurityException('Encrypted data too short - possible corruption');
      }
      
      // Extract components
      final nonce = encryptedData.sublist(0, _nonceLength);
      final ciphertext = encryptedData.sublist(_nonceLength);
      
      // Get context-specific decryption key
      final key = await SecureKeyManager.getEncryptionKey(context);
      
      // Create AES-GCM cipher
      final aesKey = encrypt_lib.Key(key);
      final cipher = Encrypter(AES(aesKey, mode: AESMode.gcm));
      
      // Decrypt and verify authentication tag
      final encrypted = Encrypted(ciphertext);
      final decrypted = cipher.decryptBytes(encrypted, iv: IV(nonce));
      
      await _auditCryptoOperation('DECRYPT_SUCCESS', 'Data decrypted for context: $context');
      return Uint8List.fromList(decrypted);
    } catch (e) {
      await _auditCryptoOperation('DECRYPT_ERROR', 'Byte decryption failed for context $context: $e');
      throw SecurityException('Byte decryption failed: $e');
    }
  }
  
  /// Generate secure hash with HMAC for integrity verification
  static Future<String> generateSecureHash(String data, String context) async {
    _ensureInitialized();
    
    try {
      final signingKey = await SecureKeyManager.getSigningKey(context);
      final hmac = Hmac(sha256, signingKey);
      final digest = hmac.convert(utf8.encode(data));
      
      return base64.encode(digest.bytes);
    } catch (e) {
      throw SecurityException('Hash generation failed: $e');
    }
  }
  
  /// Verify secure hash with timing-attack resistance
  static Future<bool> verifySecureHash(String data, String hash, String context) async {
    _ensureInitialized();
    
    try {
      final expectedHash = await generateSecureHash(data, context);
      return _constantTimeEquals(hash, expectedHash);
    } catch (e) {
      await _auditCryptoOperation('HASH_VERIFY_ERROR', 'Hash verification failed: $e');
      return false;
    }
  }
  
  /// Generate cryptographically secure token
  static String generateSecureToken({int length = 32}) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Url.encode(bytes);
  }
  
  /// Check if data is encrypted with our format
  static bool isEncrypted(String data) {
    return data.startsWith('$_encryptionPrefix:');
  }
  
  /// Get encryption metadata (version, etc.)
  static Map<String, String> getEncryptionMetadata(String encryptedData) {
    if (!encryptedData.contains(':')) {
      return {'format': 'unknown', 'version': 'unknown'};
    }
    
    final colonIndex = encryptedData.indexOf(':');
    final version = encryptedData.substring(0, colonIndex);
    
    return {
      'format': 'AES-256-GCM',
      'version': version,
      'prefix': _encryptionPrefix,
    };
  }
  
  /// Secure memory wipe for sensitive data
  static void secureWipe(Uint8List buffer) {
    if (buffer.isEmpty) return;
    
    final random = Random.secure();
    // Overwrite with random data 3 times
    for (int pass = 0; pass < 3; pass++) {
      for (int i = 0; i < buffer.length; i++) {
        buffer[i] = random.nextInt(256);
      }
    }
    // Final overwrite with zeros
    buffer.fillRange(0, buffer.length, 0);
  }
  
  /// Force key rotation (for security incidents)
  static Future<void> rotateKeys() async {
    _ensureInitialized();
    await SecureKeyManager.rotateKeys();
    await _auditCryptoOperation('KEY_ROTATION', 'Crypto keys rotated');
  }
  
  // Private implementation methods
  
  /// Ensure service is initialized
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw SecurityException('AES-GCM service not initialized');
    }
  }
  
  /// Generate cryptographically secure nonce for GCM
  static Uint8List _generateSecureNonce() {
    return SecureKeyManager.generateSecureRandom(_nonceLength);
  }
  
  /// Verify crypto capabilities with test vectors
  static Future<void> _verifyCryptoCapabilities() async {
    try {
      const testPlaintext = 'SecuryFlex_Crypto_Test_Vector_2024';
      const testContext = 'capability_test';
      
      // Test encryption/decryption round trip
      final encrypted = await encryptString(testPlaintext, testContext);
      final decrypted = await decryptString(encrypted, testContext);
      
      if (decrypted != testPlaintext) {
        throw SecurityException('Crypto capability verification failed - round trip test');
      }
      
      // Test hash generation and verification
      final hash = await generateSecureHash(testPlaintext, testContext);
      final hashValid = await verifySecureHash(testPlaintext, hash, testContext);
      
      if (!hashValid) {
        throw SecurityException('Crypto capability verification failed - hash test');
      }
      
      debugPrint('Crypto capabilities verified successfully');
    } catch (e) {
      throw SecurityException('Crypto capability verification failed: $e');
    }
  }
  
  /// Constant-time string comparison to prevent timing attacks
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
  
  /// Audit crypto operations for compliance
  static Future<void> _auditCryptoOperation(String operation, String details) async {
    try {
      final auditEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'operation': operation,
        'service': 'AESGCMCryptoService',
        'details': details,
        'encryption': 'AES-256-GCM',
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