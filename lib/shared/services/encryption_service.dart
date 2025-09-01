import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/aes_gcm_crypto_service.dart';

/// Service for encrypting and decrypting sensitive data
/// Implements AES-256-GCM encryption for PII and payment data
/// Uses secure key management and Nederlandse AVG/GDPR compliance
class EncryptionService {
  // Encryption contexts for different data types
  static const String _paymentContext = 'payment_transaction_data';
  static const String _piiContext = 'personal_identification_info';
  static const String _generalContext = 'general_sensitive_data';
  
  // Service initialization
  static bool _isInitialized = false;

  /// Initialize the encryption service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    await AESGCMCryptoService.initialize();
    _isInitialized = true;
  }
  
  /// Ensure service is initialized
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw EncryptionException('EncryptionService not initialized - call initialize() first');
    }
  }

  /// Encrypt sensitive string data using AES-256-GCM
  Future<String> encrypt(String plaintext, {String? context}) async {
    _ensureInitialized();
    
    try {
      final encryptionContext = context ?? _generalContext;
      return await AESGCMCryptoService.encryptString(plaintext, encryptionContext);
    } catch (e) {
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }

  /// Decrypt encrypted string data using AES-256-GCM
  Future<String> decrypt(String encryptedData, {String? context}) async {
    _ensureInitialized();
    
    try {
      final encryptionContext = context ?? _generalContext;
      return await AESGCMCryptoService.decryptString(encryptedData, encryptionContext);
    } catch (e) {
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }

  /// Encrypt payment transaction data
  Future<Map<String, dynamic>> encryptPaymentData(dynamic paymentTransaction) async {
    // Convert payment transaction to map first
    Map<String, dynamic> data;
    if (paymentTransaction is Map<String, dynamic>) {
      data = paymentTransaction;
    } else {
      // Assume it has a toJson method
      data = (paymentTransaction as dynamic).toJson();
    }
    
    final encryptedData = <String, dynamic>{};
    
    // Fields that need encryption
    const sensitiveFields = [
      'recipientIBAN',
      'recipientName', 
      'amount',
      'netAmount',
      'description',
      'transactionReference',
    ];
    
    for (final entry in data.entries) {
      if (sensitiveFields.contains(entry.key)) {
        encryptedData['encrypted_${entry.key}'] = await encrypt(entry.value.toString(), context: _paymentContext);
      } else {
        encryptedData[entry.key] = entry.value;
      }
    }
    
    // Add encryption metadata
    encryptedData['encryption_version'] = '1.0';
    encryptedData['encrypted_at'] = FieldValue.serverTimestamp();
    
    return encryptedData;
  }

  /// Decrypt payment transaction data
  Future<Map<String, dynamic>> decryptPaymentData(Map<String, dynamic> encryptedData) async {
    final decryptedData = <String, dynamic>{};
    
    for (final entry in encryptedData.entries) {
      if (entry.key.startsWith('encrypted_')) {
        final originalKey = entry.key.substring('encrypted_'.length);
        decryptedData[originalKey] = await decrypt(entry.value as String, context: _paymentContext);
      } else if (!entry.key.startsWith('encryption_') && entry.key != 'encrypted_at') {
        decryptedData[entry.key] = entry.value;
      }
    }
    
    return decryptedData;
  }

  /// Hash password with salt using secure service
  Future<String> hashPassword(String password) async {
    _ensureInitialized();
    return await AESGCMCryptoService.generateSecureHash(password, 'password_hashing');
  }

  /// Verify password against hash using secure service
  Future<bool> verifyPassword(String password, String hashedPassword) async {
    _ensureInitialized();
    try {
      return await AESGCMCryptoService.verifySecureHash(password, hashedPassword, 'password_hashing');
    } catch (e) {
      return false;
    }
  }

  /// Generate secure random token
  String generateSecureToken({int length = 32}) {
    return AESGCMCryptoService.generateSecureToken(length: length);
  }

  /// Generate IBAN masking for logging (GDPR compliance)
  String maskIBAN(String iban) {
    if (iban.length < 8) return iban;
    return iban.substring(0, 4) + '*' * (iban.length - 8) + iban.substring(iban.length - 4);
  }

  // Removed: All legacy XOR encryption methods replaced with secure AES-256-GCM
  // Key derivation, encryption/decryption now handled by AESGCMCryptoService
}

/// Exception thrown when encryption/decryption operations fail
class EncryptionException implements Exception {
  final String message;
  
  const EncryptionException(this.message);
  
  @override
  String toString() => 'EncryptionException: $message';
}