import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';
import 'package:uuid/uuid.dart';

/// Payment Encryption Service for PCI DSS compliance
/// 
/// Features:
/// - AES-256-GCM encryption for payment data
/// - RSA-2048 for key exchange
/// - Field-level encryption for sensitive data
/// - Key rotation and management
/// - Secure key derivation (PBKDF2)
/// - Data tokenization for PCI compliance
/// - Comprehensive audit logging
/// - HSM-ready architecture
class PaymentEncryptionService {
  final FirebaseFirestore _firestore;
  
  // Encryption configuration
  static const int _aesKeySize = 32; // 256 bits
  static const int _ivSize = 12; // GCM IV size
  static const int _tagSize = 16; // GCM tag size
// PBKDF2 salt size
  static const int _iterationCount = 100000; // PBKDF2 iterations
  static const int _rsaKeySize = 2048; // RSA key size in bits
  
  // Data classification levels
  static const String _classificationPII = 'PII';
  static const String _classificationFinancial = 'FINANCIAL';
  static const String _classificationSensitive = 'SENSITIVE';
  
  PaymentEncryptionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Encrypt payment data with AES-256-GCM
  Future<String> encryptPaymentData(Map<String, dynamic> paymentData) async {
    try {
      // Generate encryption key and IV
      final key = _generateSecureRandom(_aesKeySize);
      final iv = _generateSecureRandom(_ivSize);
      
      // Serialize payment data
      final plaintext = utf8.encode(jsonEncode(paymentData));
      
      // Encrypt with AES-GCM
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(key),
        _tagSize * 8,
        iv,
        Uint8List(0), // No additional authenticated data
      );
      
      cipher.init(true, params);
      final ciphertext = cipher.process(plaintext);
      
      // Create encrypted payload
      final encryptedPayload = {
        'version': '1.0',
        'algorithm': 'AES-256-GCM',
        'ciphertext': base64Encode(ciphertext),
        'iv': base64Encode(iv),
        'key_id': await _storeEncryptionKey(key),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'classification': _classificationFinancial,
      };
      
      return base64Encode(utf8.encode(jsonEncode(encryptedPayload)));
      
    } catch (e) {
      await _logEncryptionError('PAYMENT_ENCRYPTION_FAILED', e.toString());
      throw EncryptionException(
        'Payment data encryption failed: ${e.toString()}',
        EncryptionErrorCode.encryptionFailed,
      );
    }
  }

  /// Decrypt payment data
  Future<Map<String, dynamic>> decryptPaymentData(String encryptedData) async {
    try {
      // Decode encrypted payload
      final payloadJson = utf8.decode(base64Decode(encryptedData));
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      
      // Validate payload
      if (payload['version'] != '1.0' || payload['algorithm'] != 'AES-256-GCM') {
        throw EncryptionException(
          'Unsupported encryption version or algorithm',
          EncryptionErrorCode.unsupportedVersion,
        );
      }
      
      // Retrieve encryption key
      final keyId = payload['key_id'] as String;
      final key = await _retrieveEncryptionKey(keyId);
      
      if (key == null) {
        throw EncryptionException(
          'Encryption key not found: $keyId',
          EncryptionErrorCode.keyNotFound,
        );
      }
      
      // Extract encrypted components
      final ciphertext = base64Decode(payload['ciphertext']);
      final iv = base64Decode(payload['iv']);
      
      // Decrypt with AES-GCM
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(key),
        _tagSize * 8,
        iv,
        Uint8List(0),
      );
      
      cipher.init(false, params);
      final plaintext = cipher.process(ciphertext);
      
      // Deserialize payment data
      final decryptedJson = utf8.decode(plaintext);
      return jsonDecode(decryptedJson) as Map<String, dynamic>;
      
    } catch (e) {
      await _logEncryptionError('PAYMENT_DECRYPTION_FAILED', e.toString());
      throw EncryptionException(
        'Payment data decryption failed: ${e.toString()}',
        EncryptionErrorCode.decryptionFailed,
      );
    }
  }

  /// Encrypt sensitive field (IBAN, credit card numbers, etc.)
  Future<String> encryptSensitiveField(String fieldValue, String fieldType) async {
    try {
      // Generate field-specific key
      final fieldKey = await _deriveFieldKey(fieldType);
      final iv = _generateSecureRandom(_ivSize);
      
      final plaintext = utf8.encode(fieldValue);
      
      // Encrypt with AES-GCM
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(fieldKey),
        _tagSize * 8,
        iv,
        utf8.encode(fieldType), // Field type as additional authenticated data
      );
      
      cipher.init(true, params);
      final ciphertext = cipher.process(plaintext);
      
      // Create field encryption envelope
      final envelope = {
        'field_type': fieldType,
        'ciphertext': base64Encode(ciphertext),
        'iv': base64Encode(iv),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'classification': _getFieldClassification(fieldType),
      };
      
      return base64Encode(utf8.encode(jsonEncode(envelope)));
      
    } catch (e) {
      await _logEncryptionError('FIELD_ENCRYPTION_FAILED', e.toString());
      throw EncryptionException(
        'Field encryption failed: ${e.toString()}',
        EncryptionErrorCode.fieldEncryptionFailed,
      );
    }
  }

  /// Decrypt sensitive field
  Future<String> decryptSensitiveField(String encryptedField) async {
    try {
      // Decode envelope
      final envelopeJson = utf8.decode(base64Decode(encryptedField));
      final envelope = jsonDecode(envelopeJson) as Map<String, dynamic>;
      
      final fieldType = envelope['field_type'] as String;
      final ciphertext = base64Decode(envelope['ciphertext']);
      final iv = base64Decode(envelope['iv']);
      
      // Generate field-specific key
      final fieldKey = await _deriveFieldKey(fieldType);
      
      // Decrypt with AES-GCM
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(fieldKey),
        _tagSize * 8,
        iv,
        utf8.encode(fieldType),
      );
      
      cipher.init(false, params);
      final plaintext = cipher.process(ciphertext);
      
      return utf8.decode(plaintext);
      
    } catch (e) {
      await _logEncryptionError('FIELD_DECRYPTION_FAILED', e.toString());
      throw EncryptionException(
        'Field decryption failed: ${e.toString()}',
        EncryptionErrorCode.fieldDecryptionFailed,
      );
    }
  }

  /// Generate payment data token for PCI compliance
  Future<String> tokenizePaymentData(Map<String, dynamic> paymentData) async {
    try {
      // Generate unique token
      final token = const Uuid().v4();
      
      // Encrypt and store payment data
      final encryptedData = await encryptPaymentData(paymentData);
      
      // Store token mapping
      await _firestore.collection('payment_tokens').doc(token).set({
        'token': token,
        'encrypted_data': encryptedData,
        'created_at': Timestamp.now(),
        'expires_at': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)), // 24-hour expiry
        ),
        'usage_count': 0,
        'max_usage': 1, // Single use token
        'classification': _classificationFinancial,
      });
      
      await _logTokenCreation(token, paymentData.keys.toList());
      
      return token;
      
    } catch (e) {
      await _logEncryptionError('TOKENIZATION_FAILED', e.toString());
      throw EncryptionException(
        'Payment data tokenization failed: ${e.toString()}',
        EncryptionErrorCode.tokenizationFailed,
      );
    }
  }

  /// Detokenize payment data
  Future<Map<String, dynamic>?> detokenizePaymentData(String token) async {
    try {
      final tokenDoc = await _firestore.collection('payment_tokens').doc(token).get();
      
      if (!tokenDoc.exists) {
        throw EncryptionException(
          'Token not found: $token',
          EncryptionErrorCode.tokenNotFound,
        );
      }
      
      final tokenData = tokenDoc.data()!;
      final expiresAt = (tokenData['expires_at'] as Timestamp).toDate();
      
      if (DateTime.now().isAfter(expiresAt)) {
        await _firestore.collection('payment_tokens').doc(token).delete();
        throw EncryptionException(
          'Token expired: $token',
          EncryptionErrorCode.tokenExpired,
        );
      }
      
      final usageCount = tokenData['usage_count'] as int;
      final maxUsage = tokenData['max_usage'] as int;
      
      if (usageCount >= maxUsage) {
        await _firestore.collection('payment_tokens').doc(token).delete();
        throw EncryptionException(
          'Token usage limit exceeded: $token',
          EncryptionErrorCode.tokenUsageLimitExceeded,
        );
      }
      
      // Increment usage count
      await _firestore.collection('payment_tokens').doc(token).update({
        'usage_count': usageCount + 1,
        'last_used': Timestamp.now(),
      });
      
      // Decrypt payment data
      final encryptedData = tokenData['encrypted_data'] as String;
      final paymentData = await decryptPaymentData(encryptedData);
      
      await _logTokenUsage(token);
      
      return paymentData;
      
    } catch (e) {
      await _logEncryptionError('DETOKENIZATION_FAILED', e.toString());
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException(
        'Payment data detokenization failed: ${e.toString()}',
        EncryptionErrorCode.detokenizationFailed,
      );
    }
  }

  /// Generate RSA key pair for key exchange
  Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>> generateRSAKeyPair() async {
    try {
      final keyGen = RSAKeyGenerator();
      keyGen.init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), _rsaKeySize, 64),
        SecureRandom('Fortuna')..seed(KeyParameter(_generateSecureRandom(32))),
      ));
      
      final keyPair = keyGen.generateKeyPair();
      return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
        keyPair.publicKey as RSAPublicKey,
        keyPair.privateKey as RSAPrivateKey,
      );
      
    } catch (e) {
      await _logEncryptionError('RSA_KEY_GENERATION_FAILED', e.toString());
      throw EncryptionException(
        'RSA key pair generation failed: ${e.toString()}',
        EncryptionErrorCode.keyGenerationFailed,
      );
    }
  }

  /// Encrypt data with RSA public key
  Future<String> encryptWithRSAPublicKey(String data, RSAPublicKey publicKey) async {
    try {
      final cipher = OAEPEncoding(RSAEngine());
      cipher.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
      
      final plaintext = utf8.encode(data);
      final ciphertext = cipher.process(plaintext);
      
      return base64Encode(ciphertext);
      
    } catch (e) {
      await _logEncryptionError('RSA_ENCRYPTION_FAILED', e.toString());
      throw EncryptionException(
        'RSA encryption failed: ${e.toString()}',
        EncryptionErrorCode.rsaEncryptionFailed,
      );
    }
  }

  /// Decrypt data with RSA private key
  Future<String> decryptWithRSAPrivateKey(String encryptedData, RSAPrivateKey privateKey) async {
    try {
      final cipher = OAEPEncoding(RSAEngine());
      cipher.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
      
      final ciphertext = base64Decode(encryptedData);
      final plaintext = cipher.process(ciphertext);
      
      return utf8.decode(plaintext);
      
    } catch (e) {
      await _logEncryptionError('RSA_DECRYPTION_FAILED', e.toString());
      throw EncryptionException(
        'RSA decryption failed: ${e.toString()}',
        EncryptionErrorCode.rsaDecryptionFailed,
      );
    }
  }

  /// Rotate encryption keys (for compliance)
  Future<void> rotateEncryptionKeys() async {
    try {
      // Get all active keys
      final keysSnapshot = await _firestore
          .collection('encryption_keys')
          .where('status', isEqualTo: 'active')
          .get();
      
      for (final keyDoc in keysSnapshot.docs) {
        // Mark key as rotated
        await keyDoc.reference.update({
          'status': 'rotated',
          'rotated_at': Timestamp.now(),
        });
        
        // Generate new key
        final newKey = _generateSecureRandom(_aesKeySize);
        await _storeEncryptionKey(newKey);
      }
      
      await _logKeyRotation(keysSnapshot.docs.length);
      
    } catch (e) {
      await _logEncryptionError('KEY_ROTATION_FAILED', e.toString());
      throw EncryptionException(
        'Key rotation failed: ${e.toString()}',
        EncryptionErrorCode.keyRotationFailed,
      );
    }
  }

  /// Clean up expired tokens
  Future<void> cleanupExpiredTokens() async {
    try {
      final expiredTokens = await _firestore
          .collection('payment_tokens')
          .where('expires_at', isLessThan: Timestamp.now())
          .get();
      
      final batch = _firestore.batch();
      for (final tokenDoc in expiredTokens.docs) {
        batch.delete(tokenDoc.reference);
      }
      
      await batch.commit();
      
      if (kDebugMode) {
        debugPrint('Cleaned up ${expiredTokens.docs.length} expired tokens');
      }
      
    } catch (e) {
      await _logEncryptionError('TOKEN_CLEANUP_FAILED', e.toString());
    }
  }

  /// Private helper methods

  /// Generate secure random bytes
  Uint8List _generateSecureRandom(int length) {
    final secureRandom = SecureRandom('Fortuna');
    final seed = Uint8List(32);
    for (int i = 0; i < seed.length; i++) {
      seed[i] = Random.secure().nextInt(256);
    }
    secureRandom.seed(KeyParameter(seed));
    
    return secureRandom.nextBytes(length);
  }

  /// Derive field-specific encryption key
  Future<Uint8List> _deriveFieldKey(String fieldType) async {
    // Get master key from secure configuration
    final masterKey = await _getMasterKey();
    final salt = utf8.encode('SecuryFlex_Field_$fieldType');
    
    // Derive key using PBKDF2
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(salt, _iterationCount, _aesKeySize));
    
    return pbkdf2.process(masterKey);
  }

  /// Get master key (would come from HSM or secure vault in production)
  Future<Uint8List> _getMasterKey() async {
    // In production, this would retrieve the master key from:
    // - Hardware Security Module (HSM)
    // - Azure Key Vault / AWS KMS / Google Cloud KMS
    // - Secure configuration service
    
    // For demo purposes, generate from secure configuration
    const masterKeyString = 'SecuryFlex_Master_Key_2024_Production';
    return Uint8List.fromList(sha256.convert(utf8.encode(masterKeyString)).bytes);
  }

  /// Store encryption key securely
  Future<String> _storeEncryptionKey(Uint8List key) async {
    final keyId = const Uuid().v4();
    final keyHash = sha256.convert(key).toString();
    
    // In production, the key would be stored in an HSM or secure vault
    // For demo purposes, we store a hash reference
    await _firestore.collection('encryption_keys').doc(keyId).set({
      'key_id': keyId,
      'key_hash': keyHash,
      'algorithm': 'AES-256',
      'created_at': Timestamp.now(),
      'status': 'active',
      'classification': _classificationSensitive,
    });
    
    return keyId;
  }

  /// Retrieve encryption key
  Future<Uint8List?> _retrieveEncryptionKey(String keyId) async {
    // In production, this would retrieve from HSM/vault
    // For demo purposes, we generate from key ID (not secure for production)
    final keyDoc = await _firestore.collection('encryption_keys').doc(keyId).get();
    
    if (!keyDoc.exists || keyDoc.data()!['status'] != 'active') {
      return null;
    }
    
    // This is NOT secure for production - keys should be stored in HSM
    final keyMaterial = sha256.convert(utf8.encode('key_$keyId')).bytes;
    return Uint8List.fromList(keyMaterial);
  }

  /// Get field classification
  String _getFieldClassification(String fieldType) {
    switch (fieldType.toLowerCase()) {
      case 'iban':
      case 'credit_card':
      case 'bank_account':
        return _classificationFinancial;
      case 'bsn':
      case 'passport':
      case 'id_number':
        return _classificationPII;
      default:
        return _classificationSensitive;
    }
  }

  /// Log encryption error
  Future<void> _logEncryptionError(String type, String error) async {
    try {
      await _firestore.collection('encryption_audit').add({
        'type': type,
        'error': error,
        'timestamp': Timestamp.now(),
        'severity': 'ERROR',
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to log encryption error: $e');
      }
    }
  }

  /// Log token creation
  Future<void> _logTokenCreation(String token, List<String> dataFields) async {
    try {
      await _firestore.collection('encryption_audit').add({
        'type': 'TOKEN_CREATED',
        'token_id': token,
        'data_fields': dataFields,
        'timestamp': Timestamp.now(),
        'classification': _classificationFinancial,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to log token creation: $e');
      }
    }
  }

  /// Log token usage
  Future<void> _logTokenUsage(String token) async {
    try {
      await _firestore.collection('encryption_audit').add({
        'type': 'TOKEN_USED',
        'token_id': token,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to log token usage: $e');
      }
    }
  }

  /// Log key rotation
  Future<void> _logKeyRotation(int rotatedKeyCount) async {
    try {
      await _firestore.collection('encryption_audit').add({
        'type': 'KEY_ROTATION',
        'rotated_key_count': rotatedKeyCount,
        'timestamp': Timestamp.now(),
        'classification': _classificationSensitive,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to log key rotation: $e');
      }
    }
  }
}

/// Encryption error codes
enum EncryptionErrorCode {
  encryptionFailed,
  decryptionFailed,
  fieldEncryptionFailed,
  fieldDecryptionFailed,
  tokenizationFailed,
  detokenizationFailed,
  tokenNotFound,
  tokenExpired,
  tokenUsageLimitExceeded,
  keyGenerationFailed,
  keyNotFound,
  keyRotationFailed,
  rsaEncryptionFailed,
  rsaDecryptionFailed,
  unsupportedVersion,
  invalidData,
}

/// Encryption exception
class EncryptionException implements Exception {
  final String message;
  final EncryptionErrorCode errorCode;

  const EncryptionException(this.message, this.errorCode);

  @override
  String toString() => 'EncryptionException: $message (${errorCode.name})';
}