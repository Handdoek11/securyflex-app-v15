import 'package:flutter/foundation.dart';
import 'aes_gcm_crypto_service.dart';
import 'bsn_security_service.dart';

/// DEPRECATED: Enhanced Crypto Service
/// This class is now a wrapper around the new secure crypto services
/// All new implementations should use AESGCMCryptoService and BSNSecurityService directly
@Deprecated('Use AESGCMCryptoService and BSNSecurityService instead')
class EnhancedCryptoService {
  // Migration flag
  
  // Migration flag
  static bool _isInitialized = false;
  
  /// Initialize the enhanced crypto service (deprecated wrapper)
  static Future<void> initialize([String? masterKey]) async {
    if (_isInitialized) return;
    
    try {
      await AESGCMCryptoService.initialize();
      await BSNSecurityService.initialize();
      
      _isInitialized = true;
      debugPrint('Enhanced crypto service initialized (using new secure services)');
    } catch (e) {
      throw SecurityException('Enhanced crypto service initialization failed: $e');
    }
  }
  
  
  /// Encrypt BSN using new secure service
  @Deprecated('Use BSNSecurityService.encryptBSN instead')
  static Future<String> encryptBSN(String bsn) async {
    _ensureInitialized();
    return await BSNSecurityService.instance.encryptBSN(bsn, 'deprecated_user');
  }
  
  /// Decrypt BSN using new secure service
  @Deprecated('Use BSNSecurityService.decryptBSN instead')
  static Future<String> decryptBSN(String encryptedBsn) async {
    _ensureInitialized();
    return await BSNSecurityService.instance.decryptBSN(encryptedBsn, 'deprecated_user');
  }
  
  /// Encrypt document using new secure service
  @Deprecated('Use AESGCMCryptoService.encryptBytes instead')
  static Future<Uint8List> encryptDocument(
    Uint8List content, 
    String documentId, 
    String userId
  ) async {
    _ensureInitialized();
    final context = 'doc_${documentId}_$userId';
    return await AESGCMCryptoService.encryptBytes(content, context);
  }
  
  /// Decrypt document using new secure service
  @Deprecated('Use AESGCMCryptoService.decryptBytes instead')
  static Future<Uint8List> decryptDocument(
    Uint8List encryptedContent, 
    String documentId, 
    String userId
  ) async {
    _ensureInitialized();
    final context = 'doc_${documentId}_$userId';
    return await AESGCMCryptoService.decryptBytes(encryptedContent, context);
  }
  
  /// Generate hash using new secure service
  @Deprecated('Use AESGCMCryptoService.generateSecureHash instead')
  static Future<String> generateSecureHash(String data, {String? salt}) async {
    _ensureInitialized();
    return await AESGCMCryptoService.generateSecureHash(data, 'legacy_context');
  }
  
  /// Verify hash using new secure service
  @Deprecated('Use AESGCMCryptoService.verifySecureHash instead')
  static Future<bool> verifySecureHash(String data, String hashedValue, {String? salt}) async {
    _ensureInitialized();
    return await AESGCMCryptoService.verifySecureHash(data, hashedValue, 'legacy_context');
  }
  
  /// Generate token using new secure service
  @Deprecated('Use AESGCMCryptoService.generateSecureToken instead')
  static String generateSecureToken({int length = 32}) {
    return AESGCMCryptoService.generateSecureToken(length: length);
  }
  
  /// Hash for audit using new secure service
  @Deprecated('Use BSNSecurityService.hashBSNForAudit for BSN data')
  static Future<String> hashForAudit(String sensitiveData) async {
    _ensureInitialized();
    final hash = await AESGCMCryptoService.generateSecureHash(sensitiveData, 'audit_context');
    return hash.substring(0, 16); // Truncated for logs
  }
  
  /// Secure wipe using new secure service
  @Deprecated('Use AESGCMCryptoService.secureWipe instead')
  static void secureWipe(Uint8List buffer) {
    AESGCMCryptoService.secureWipe(buffer);
  }
  
  // Private helper methods
  
  /// Ensure service is initialized
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw SecurityException('Enhanced crypto service not initialized');
    }
  }
  
  // Removed: Legacy validation now handled by BSNSecurityService
  
  /// Rotate keys using new secure service
  @Deprecated('Use AESGCMCryptoService.rotateKeys instead')
  static Future<void> rotateKeys() async {
    _ensureInitialized();
    await AESGCMCryptoService.rotateKeys();
  }
}

/// Security-related exceptions
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => 'ValidationException: $message';
}