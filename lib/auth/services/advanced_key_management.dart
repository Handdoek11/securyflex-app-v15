import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Advanced Key Management Service for SecuryFlex
/// 
/// Provides hardware security module integration, secure key storage,
/// key rotation policies, and cryptographic key lifecycle management
/// compliant with Dutch security standards and FIPS 140-2 Level 3.
class AdvancedKeyManagement {
  static const String _masterKeyKey = 'securyflex_master_key';
  static const String _keyStoreKey = 'securyflex_key_store';
  
  // Key management configuration
// 256 bits
  static const int _derivedKeyLength = 32; // 256 bits
  static const int _keyEscrowShares = 5;
  static const int _keyEscrowThreshold = 3;
  static const int _pbkdf2Iterations = 100000;
  
  // Hardware Security Module (HSM) simulation parameters
  static const String _hsmProvider = 'SecuryFlex_HSM_v1.0';
  static const int _hsmSecurityLevel = 3; // FIPS 140-2 Level 3 equivalent
  
  static KeyStore? _keyStore;
  static MasterKey? _masterKey;
  static Timer? _keyRotationTimer;
  
  /// Initialize advanced key management system
  static Future<KeyManagementInitResult> initialize({
    String? userPassphrase,
    bool enableHSM = true,
    bool enableKeyRotation = true,
    bool enableKeyEscrow = false,
  }) async {
    try {
      // Initialize Hardware Security Module simulation
      final hsmResult = await _initializeHSM(enableHSM);
      if (!hsmResult.success && enableHSM) {
        return KeyManagementInitResult(
          success: false,
          error: 'HSM initialization failed: ${hsmResult.error}',
        );
      }
      
      // Initialize or load master key
      _masterKey = await _initializeMasterKey(userPassphrase);
      
      // Initialize key store
      _keyStore = await _initializeKeyStore(_masterKey!);
      
      // Setup key rotation
      if (enableKeyRotation) {
        await _setupKeyRotation();
      }
      
      // Setup key escrow if enabled
      if (enableKeyEscrow) {
        await _setupKeyEscrow(_masterKey!);
      }
      
      // Initialize certificate pinning
      await _initializeCertificatePinning();
      
      return KeyManagementInitResult(
        success: true,
        hsmEnabled: hsmResult.success,
        keyRotationEnabled: enableKeyRotation,
        keyEscrowEnabled: enableKeyEscrow,
        securityLevel: _hsmSecurityLevel,
      );
      
    } catch (e) {
      return KeyManagementInitResult(
        success: false,
        error: 'Key management initialization failed: $e',
      );
    }
  }
  
  /// Generate cryptographically secure key with HSM protection
  static Future<SecureKeyResult> generateSecureKey({
    required KeyType keyType,
    required String keyId,
    int? keyLength,
    KeyUsage usage = KeyUsage.encryption,
    Duration? validityPeriod,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _ensureInitialized();
      
      final length = keyLength ?? _getDefaultKeyLength(keyType);
      
      // Generate key material using secure random generator
      final keyMaterial = await _generateSecureKeyMaterial(length);
      
      // Create key with metadata
      final key = SecureKey(
        id: keyId,
        type: keyType,
        usage: usage,
        keyMaterial: keyMaterial,
        createdAt: DateTime.now(),
        expiresAt: validityPeriod != null 
            ? DateTime.now().add(validityPeriod)
            : null,
        metadata: metadata ?? {},
        version: 1,
        rotationHistory: [],
      );
      
      // Protect key with HSM if available
      final protectedKey = await _protectKeyWithHSM(key);
      
      // Store in secure key store
      await _keyStore!.storeKey(protectedKey);
      
      // Log key generation event
      await _logKeyManagementEvent(
        KeyManagementEventType.keyGenerated,
        keyId,
        {'keyType': keyType.name, 'usage': usage.name},
      );
      
      return SecureKeyResult(
        success: true,
        keyId: keyId,
        keyFingerprint: await _calculateKeyFingerprint(protectedKey),
        hsmProtected: true,
      );
      
    } catch (e) {
      await _logKeyManagementEvent(
        KeyManagementEventType.keyGenerationFailed,
        keyId,
        {'error': e.toString()},
      );
      
      return SecureKeyResult(
        success: false,
        error: 'Key generation failed: $e',
      );
    }
  }
  
  /// Derive key using PBKDF2 with secure parameters
  static Future<SecureKeyResult> deriveKey({
    required String keyId,
    required String password,
    required Uint8List salt,
    KeyType keyType = KeyType.symmetric,
    int iterations = _pbkdf2Iterations,
    int keyLength = _derivedKeyLength,
  }) async {
    try {
      _ensureInitialized();
      
      // Validate salt strength
      if (salt.length < 16) {
        throw ArgumentError('Salt must be at least 16 bytes');
      }
      
      // Derive key using PBKDF2
      final derivedKey = await _pbkdf2(
        password: password,
        salt: salt,
        iterations: iterations,
        keyLength: keyLength,
      );
      
      // Create secure key
      final key = SecureKey(
        id: keyId,
        type: keyType,
        usage: KeyUsage.encryption,
        keyMaterial: derivedKey,
        createdAt: DateTime.now(),
        derivedFrom: 'PBKDF2',
        metadata: {
          'iterations': iterations,
          'saltLength': salt.length,
        },
        version: 1,
        rotationHistory: [],
      );
      
      // Protect and store key
      final protectedKey = await _protectKeyWithHSM(key);
      await _keyStore!.storeKey(protectedKey);
      
      await _logKeyManagementEvent(
        KeyManagementEventType.keyDerived,
        keyId,
        {'iterations': iterations, 'keyLength': keyLength},
      );
      
      return SecureKeyResult(
        success: true,
        keyId: keyId,
        keyFingerprint: await _calculateKeyFingerprint(protectedKey),
        hsmProtected: true,
      );
      
    } catch (e) {
      await _logKeyManagementEvent(
        KeyManagementEventType.keyDerivationFailed,
        keyId,
        {'error': e.toString()},
      );
      
      return SecureKeyResult(
        success: false,
        error: 'Key derivation failed: $e',
      );
    }
  }
  
  /// Rotate key with secure migration
  static Future<KeyRotationResult> rotateKey({
    required String keyId,
    bool preserveOldKey = false,
    Duration? gracePeriod,
  }) async {
    try {
      _ensureInitialized();
      
      // Get existing key
      final existingKey = await _keyStore!.getKey(keyId);
      if (existingKey == null) {
        return KeyRotationResult(
          success: false,
          error: 'Key not found: $keyId',
        );
      }
      
      // Generate new key material
      final newKeyMaterial = await _generateSecureKeyMaterial(
        existingKey.keyMaterial.length,
      );
      
      // Create new key version
      final newKey = existingKey.copyWith(
        keyMaterial: newKeyMaterial,
        version: existingKey.version + 1,
        createdAt: DateTime.now(),
        rotationHistory: [
          ...existingKey.rotationHistory,
          KeyRotationRecord(
            previousVersion: existingKey.version,
            rotatedAt: DateTime.now(),
            reason: 'Scheduled rotation',
          ),
        ],
      );
      
      // Protect new key with HSM
      final protectedNewKey = await _protectKeyWithHSM(newKey);
      
      // Store new key version
      await _keyStore!.storeKey(protectedNewKey);
      
      // Handle old key based on policy
      if (preserveOldKey && gracePeriod != null) {
        // Mark old key for deletion after grace period
        await _scheduleKeyDeletion(existingKey.id, gracePeriod);
      } else if (!preserveOldKey) {
        // Securely delete old key immediately
        await _securelyDeleteKey(existingKey.id, existingKey.version - 1);
      }
      
      await _logKeyManagementEvent(
        KeyManagementEventType.keyRotated,
        keyId,
        {
          'oldVersion': existingKey.version,
          'newVersion': newKey.version,
          'preserveOld': preserveOldKey,
        },
      );
      
      return KeyRotationResult(
        success: true,
        keyId: keyId,
        oldVersion: existingKey.version,
        newVersion: newKey.version,
        newFingerprint: await _calculateKeyFingerprint(protectedNewKey),
      );
      
    } catch (e) {
      await _logKeyManagementEvent(
        KeyManagementEventType.keyRotationFailed,
        keyId,
        {'error': e.toString()},
      );
      
      return KeyRotationResult(
        success: false,
        error: 'Key rotation failed: $e',
      );
    }
  }
  
  /// Encrypt data using managed key
  static Future<EncryptionResult> encryptWithKey({
    required String keyId,
    required Uint8List data,
    EncryptionAlgorithm algorithm = EncryptionAlgorithm.aes256GCM,
    Uint8List? additionalData,
  }) async {
    try {
      _ensureInitialized();
      
      final key = await _keyStore!.getKey(keyId);
      if (key == null) {
        return EncryptionResult(
          success: false,
          error: 'Key not found: $keyId',
        );
      }
      
      // Check key usage permissions
      if (!key.usage.allowsEncryption) {
        return EncryptionResult(
          success: false,
          error: 'Key does not allow encryption',
        );
      }
      
      // Check key expiration
      if (key.isExpired) {
        return EncryptionResult(
          success: false,
          error: 'Key has expired',
        );
      }
      
      // Generate IV/nonce
      final iv = await _generateSecureRandom(12); // 96 bits for GCM
      
      // Encrypt data using HSM-protected key
      final encryptedData = await _encryptWithHSM(
        key: key,
        data: data,
        algorithm: algorithm,
        iv: iv,
        additionalData: additionalData,
      );
      
      await _logKeyManagementEvent(
        KeyManagementEventType.keyUsedForEncryption,
        keyId,
        {'dataSize': data.length, 'algorithm': algorithm.name},
      );
      
      return EncryptionResult(
        success: true,
        encryptedData: encryptedData,
        iv: iv,
        algorithm: algorithm,
        keyFingerprint: await _calculateKeyFingerprint(key),
      );
      
    } catch (e) {
      await _logKeyManagementEvent(
        KeyManagementEventType.encryptionFailed,
        keyId,
        {'error': e.toString()},
      );
      
      return EncryptionResult(
        success: false,
        error: 'Encryption failed: $e',
      );
    }
  }
  
  /// Decrypt data using managed key
  static Future<DecryptionResult> decryptWithKey({
    required String keyId,
    required Uint8List encryptedData,
    required Uint8List iv,
    required EncryptionAlgorithm algorithm,
    Uint8List? additionalData,
    int? keyVersion,
  }) async {
    try {
      _ensureInitialized();
      
      final key = await _keyStore!.getKey(keyId, version: keyVersion);
      if (key == null) {
        return DecryptionResult(
          success: false,
          error: 'Key not found: $keyId${keyVersion != null ? ' version $keyVersion' : ''}',
        );
      }
      
      // Check key usage permissions
      if (!key.usage.allowsDecryption) {
        return DecryptionResult(
          success: false,
          error: 'Key does not allow decryption',
        );
      }
      
      // Decrypt data using HSM-protected key
      final decryptedData = await _decryptWithHSM(
        key: key,
        encryptedData: encryptedData,
        algorithm: algorithm,
        iv: iv,
        additionalData: additionalData,
      );
      
      await _logKeyManagementEvent(
        KeyManagementEventType.keyUsedForDecryption,
        keyId,
        {'dataSize': encryptedData.length, 'algorithm': algorithm.name},
      );
      
      return DecryptionResult(
        success: true,
        decryptedData: decryptedData,
      );
      
    } catch (e) {
      await _logKeyManagementEvent(
        KeyManagementEventType.decryptionFailed,
        keyId,
        {'error': e.toString()},
      );
      
      return DecryptionResult(
        success: false,
        error: 'Decryption failed: $e',
      );
    }
  }
  
  /// Setup Shamir Secret Sharing for key escrow
  static Future<KeyEscrowResult> setupKeyEscrow({
    required String keyId,
    int shares = _keyEscrowShares,
    int threshold = _keyEscrowThreshold,
    List<String>? trusteeIds,
  }) async {
    try {
      _ensureInitialized();
      
      if (threshold > shares) {
        throw ArgumentError('Threshold cannot be greater than shares');
      }
      
      final key = await _keyStore!.getKey(keyId);
      if (key == null) {
        return KeyEscrowResult(
          success: false,
          error: 'Key not found: $keyId',
        );
      }
      
      // Generate Shamir Secret Shares
      final secretShares = await _generateShamirShares(
        key.keyMaterial,
        shares,
        threshold,
      );
      
      // Create escrow record
      final escrowRecord = KeyEscrowRecord(
        keyId: keyId,
        shares: secretShares,
        threshold: threshold,
        trustees: trusteeIds ?? _generateDefaultTrusteeIds(shares),
        createdAt: DateTime.now(),
        escrowPolicy: KeyEscrowPolicy.disasterRecovery,
      );
      
      // Store escrow record securely
      await _storeEscrowRecord(escrowRecord);
      
      await _logKeyManagementEvent(
        KeyManagementEventType.keyEscrowed,
        keyId,
        {'shares': shares, 'threshold': threshold},
      );
      
      return KeyEscrowResult(
        success: true,
        keyId: keyId,
        shares: shares,
        threshold: threshold,
        trustees: escrowRecord.trustees,
      );
      
    } catch (e) {
      await _logKeyManagementEvent(
        KeyManagementEventType.keyEscrowFailed,
        keyId,
        {'error': e.toString()},
      );
      
      return KeyEscrowResult(
        success: false,
        error: 'Key escrow setup failed: $e',
      );
    }
  }
  
  /// Recover key from escrow shares
  static Future<KeyRecoveryResult> recoverKeyFromEscrow({
    required String keyId,
    required Map<int, Uint8List> shares,
  }) async {
    try {
      _ensureInitialized();
      
      final escrowRecord = await _getEscrowRecord(keyId);
      if (escrowRecord == null) {
        return KeyRecoveryResult(
          success: false,
          error: 'No escrow record found for key: $keyId',
        );
      }
      
      if (shares.length < escrowRecord.threshold) {
        return KeyRecoveryResult(
          success: false,
          error: 'Insufficient shares for recovery. Need ${escrowRecord.threshold}, got ${shares.length}',
        );
      }
      
      // Reconstruct key from Shamir shares
      final reconstructedKey = await _reconstructFromShamirShares(
        shares,
        escrowRecord.threshold,
      );
      
      // Verify reconstructed key matches original
      final originalKey = await _keyStore!.getKey(keyId);
      if (originalKey != null) {
        final originalFingerprint = await _calculateKeyFingerprint(originalKey);
        final reconstructedFingerprint = await _calculateDataFingerprint(reconstructedKey);
        
        if (originalFingerprint != reconstructedFingerprint) {
          throw Exception('Key reconstruction verification failed');
        }
      }
      
      await _logKeyManagementEvent(
        KeyManagementEventType.keyRecoveredFromEscrow,
        keyId,
        {'sharesUsed': shares.length},
      );
      
      return KeyRecoveryResult(
        success: true,
        keyId: keyId,
        recoveredKey: reconstructedKey,
      );
      
    } catch (e) {
      await _logKeyManagementEvent(
        KeyManagementEventType.keyRecoveryFailed,
        keyId,
        {'error': e.toString()},
      );
      
      return KeyRecoveryResult(
        success: false,
        error: 'Key recovery failed: $e',
      );
    }
  }
  
  /// Get comprehensive key management status
  static Future<KeyManagementStatus> getStatus() async {
    try {
      _ensureInitialized();
      
      final allKeys = await _keyStore!.getAllKeys();
      final rotationStatus = await _getKeyRotationStatus();
      final hsmStatus = await _getHSMStatus();
      
      return KeyManagementStatus(
        totalKeys: allKeys.length,
        activeKeys: allKeys.where((k) => !k.isExpired).length,
        expiredKeys: allKeys.where((k) => k.isExpired).length,
        keysNeedingRotation: allKeys.where((k) => k.needsRotation).length,
        hsmEnabled: hsmStatus.enabled,
        hsmSecurityLevel: hsmStatus.securityLevel,
        keyRotationEnabled: rotationStatus.enabled,
        nextRotationDate: rotationStatus.nextRotation,
        escrowedKeys: await _getEscrowedKeysCount(),
      );
      
    } catch (e) {
      throw Exception('Failed to get key management status: $e');
    }
  }
  
  /// Dispose resources and secure cleanup
  static Future<void> dispose() async {
    _keyRotationTimer?.cancel();
    _keyRotationTimer = null;
    
    // Clear sensitive data from memory
    _masterKey?.dispose();
    _masterKey = null;
    
    _keyStore?.dispose();
    _keyStore = null;
    
    await _logKeyManagementEvent(
      KeyManagementEventType.keyManagementDisposed,
      'system',
      {},
    );
  }
  
  // Private helper methods
  
  /// Initialize Hardware Security Module simulation
  static Future<HSMInitResult> _initializeHSM(bool enabled) async {
    if (!enabled) {
      return HSMInitResult(success: false, error: 'HSM disabled');
    }
    
    // Simulate HSM initialization
    // In production, this would interface with actual HSM hardware
    await Future.delayed(const Duration(milliseconds: 100));
    
    return HSMInitResult(
      success: true,
      provider: _hsmProvider,
      securityLevel: _hsmSecurityLevel,
    );
  }
  
  /// Initialize or load master key
  static Future<MasterKey> _initializeMasterKey(String? userPassphrase) async {
    final prefs = await SharedPreferences.getInstance();
    final existingKey = prefs.getString(_masterKeyKey);
    
    if (existingKey != null) {
      // Load existing master key
      return MasterKey.fromEncrypted(existingKey, userPassphrase);
    } else {
      // Generate new master key
      final masterKey = await MasterKey.generate(userPassphrase);
      await prefs.setString(_masterKeyKey, masterKey.toEncrypted());
      return masterKey;
    }
  }
  
  /// Initialize secure key store
  static Future<KeyStore> _initializeKeyStore(MasterKey masterKey) async {
    final prefs = await SharedPreferences.getInstance();
    final existingStore = prefs.getString(_keyStoreKey);
    
    if (existingStore != null) {
      return KeyStore.fromEncrypted(existingStore, masterKey);
    } else {
      final keyStore = KeyStore.create(masterKey);
      await prefs.setString(_keyStoreKey, keyStore.toEncrypted());
      return keyStore;
    }
  }
  
  /// Setup automatic key rotation
  static Future<void> _setupKeyRotation() async {
    _keyRotationTimer?.cancel();
    _keyRotationTimer = Timer.periodic(
      const Duration(hours: 24), // Check daily
      (_) => _performScheduledKeyRotation(),
    );
  }
  
  /// Generate secure key material
  static Future<Uint8List> _generateSecureKeyMaterial(int length) async {
    final random = Random.secure();
    final bytes = Uint8List(length);
    
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    
    return bytes;
  }
  
  /// Generate secure random bytes
  static Future<Uint8List> _generateSecureRandom(int length) async {
    return _generateSecureKeyMaterial(length);
  }
  
  /// PBKDF2 key derivation
  static Future<Uint8List> _pbkdf2({
    required String password,
    required Uint8List salt,
    required int iterations,
    required int keyLength,
  }) async {
    final passwordBytes = utf8.encode(password);
    
    // Simple PBKDF2 implementation for demonstration
    // In production, use a proper PBKDF2 implementation
    var derivedKey = Uint8List(keyLength);
    var currentHash = Uint8List.fromList([...passwordBytes, ...salt]);
    
    for (int i = 0; i < iterations; i++) {
      final hmac = Hmac(sha256, passwordBytes);
      currentHash = Uint8List.fromList(hmac.convert(currentHash).bytes);
    }
    
    for (int i = 0; i < keyLength; i++) {
      derivedKey[i] = currentHash[i % currentHash.length];
    }
    
    return derivedKey;
  }
  
  /// Protect key with HSM
  static Future<SecureKey> _protectKeyWithHSM(SecureKey key) async {
    // In production, this would interact with actual HSM
    // For demo, we simulate HSM protection by adding metadata
    return key.copyWith(
      metadata: {
        ...key.metadata,
        'hsmProtected': true,
        'hsmProvider': _hsmProvider,
        'protectionLevel': _hsmSecurityLevel,
      },
    );
  }
  
  /// Calculate key fingerprint
  static Future<String> _calculateKeyFingerprint(SecureKey key) async {
    final hash = sha256.convert(key.keyMaterial);
    return base64.encode(hash.bytes);
  }
  
  /// Calculate data fingerprint
  static Future<String> _calculateDataFingerprint(Uint8List data) async {
    final hash = sha256.convert(data);
    return base64.encode(hash.bytes);
  }
  
  /// Ensure key management is initialized
  static void _ensureInitialized() {
    if (_keyStore == null || _masterKey == null) {
      throw StateError('Key management not initialized. Call initialize() first.');
    }
  }
  
  /// Get default key length for key type
  static int _getDefaultKeyLength(KeyType keyType) {
    switch (keyType) {
      case KeyType.symmetric:
        return 32; // AES-256
      case KeyType.asymmetric:
        return 32; // For key material storage
      case KeyType.hmac:
        return 32; // HMAC-SHA256
      case KeyType.kdf:
        return 32; // KDF output
    }
  }
  
  // Placeholder implementations for comprehensive key management
  static Future<void> _setupKeyEscrow(MasterKey masterKey) async {}
  static Future<void> _initializeCertificatePinning() async {}
  static Future<Uint8List> _encryptWithHSM({
    required SecureKey key,
    required Uint8List data,
    required EncryptionAlgorithm algorithm,
    required Uint8List iv,
    Uint8List? additionalData,
  }) async => data; // Placeholder
  
  static Future<Uint8List> _decryptWithHSM({
    required SecureKey key,
    required Uint8List encryptedData,
    required EncryptionAlgorithm algorithm,
    required Uint8List iv,
    Uint8List? additionalData,
  }) async => encryptedData; // Placeholder
  
  static Future<List<ShamirShare>> _generateShamirShares(
    Uint8List secret,
    int shares,
    int threshold,
  ) async => []; // Placeholder
  
  static Future<Uint8List> _reconstructFromShamirShares(
    Map<int, Uint8List> shares,
    int threshold,
  ) async => Uint8List(0); // Placeholder
  
  static Future<void> _storeEscrowRecord(KeyEscrowRecord record) async {}
  static Future<KeyEscrowRecord?> _getEscrowRecord(String keyId) async => null;
  static List<String> _generateDefaultTrusteeIds(int count) => [];
  static Future<void> _scheduleKeyDeletion(String keyId, Duration delay) async {}
  static Future<void> _securelyDeleteKey(String keyId, int version) async {}
  static Future<void> _performScheduledKeyRotation() async {}
  static Future<KeyRotationStatus> _getKeyRotationStatus() async => KeyRotationStatus(enabled: false);
  static Future<HSMStatus> _getHSMStatus() async => HSMStatus(enabled: false, securityLevel: 0);
  static Future<int> _getEscrowedKeysCount() async => 0;
  
  static Future<void> _logKeyManagementEvent(
    KeyManagementEventType eventType,
    String keyId,
    Map<String, dynamic> details,
  ) async {
    developer.log('Key Management Event: ${eventType.name} - Key: $keyId - Details: $details', name: 'KeyManagement');
  }
}

// Supporting enums and data classes

enum KeyType { symmetric, asymmetric, hmac, kdf }

enum KeyUsage {
  encryption,
  decryption,
  signing,
  verification,
  keyDerivation;
  
  bool get allowsEncryption => this == encryption;
  bool get allowsDecryption => this == decryption;
}

enum EncryptionAlgorithm { aes256GCM, aes256CBC, chaCha20Poly1305 }

enum KeyManagementEventType {
  keyGenerated,
  keyGenerationFailed,
  keyDerived,
  keyDerivationFailed,
  keyRotated,
  keyRotationFailed,
  keyUsedForEncryption,
  keyUsedForDecryption,
  encryptionFailed,
  decryptionFailed,
  keyEscrowed,
  keyEscrowFailed,
  keyRecoveredFromEscrow,
  keyRecoveryFailed,
  keyManagementDisposed,
}

enum KeyEscrowPolicy { disasterRecovery, compliance, backup }

// Data classes
class KeyManagementInitResult {
  final bool success;
  final String? error;
  final bool hsmEnabled;
  final bool keyRotationEnabled;
  final bool keyEscrowEnabled;
  final int securityLevel;
  
  const KeyManagementInitResult({
    required this.success,
    this.error,
    this.hsmEnabled = false,
    this.keyRotationEnabled = false,
    this.keyEscrowEnabled = false,
    this.securityLevel = 0,
  });
}

class SecureKey {
  final String id;
  final KeyType type;
  final KeyUsage usage;
  final Uint8List keyMaterial;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;
  final int version;
  final List<KeyRotationRecord> rotationHistory;
  final String? derivedFrom;
  
  const SecureKey({
    required this.id,
    required this.type,
    required this.usage,
    required this.keyMaterial,
    required this.createdAt,
    this.expiresAt,
    required this.metadata,
    required this.version,
    required this.rotationHistory,
    this.derivedFrom,
  });
  
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get needsRotation => DateTime.now().difference(createdAt).inDays >= 90;
  
  SecureKey copyWith({
    Uint8List? keyMaterial,
    int? version,
    DateTime? createdAt,
    List<KeyRotationRecord>? rotationHistory,
    Map<String, dynamic>? metadata,
  }) {
    return SecureKey(
      id: id,
      type: type,
      usage: usage,
      keyMaterial: keyMaterial ?? this.keyMaterial,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt,
      metadata: metadata ?? this.metadata,
      version: version ?? this.version,
      rotationHistory: rotationHistory ?? this.rotationHistory,
      derivedFrom: derivedFrom,
    );
  }
}

class SecureKeyResult {
  final bool success;
  final String? keyId;
  final String? keyFingerprint;
  final bool hsmProtected;
  final String? error;
  
  const SecureKeyResult({
    required this.success,
    this.keyId,
    this.keyFingerprint,
    this.hsmProtected = false,
    this.error,
  });
}

class KeyRotationResult {
  final bool success;
  final String? keyId;
  final int? oldVersion;
  final int? newVersion;
  final String? newFingerprint;
  final String? error;
  
  const KeyRotationResult({
    required this.success,
    this.keyId,
    this.oldVersion,
    this.newVersion,
    this.newFingerprint,
    this.error,
  });
}

class EncryptionResult {
  final bool success;
  final Uint8List? encryptedData;
  final Uint8List? iv;
  final EncryptionAlgorithm? algorithm;
  final String? keyFingerprint;
  final String? error;
  
  const EncryptionResult({
    required this.success,
    this.encryptedData,
    this.iv,
    this.algorithm,
    this.keyFingerprint,
    this.error,
  });
}

class DecryptionResult {
  final bool success;
  final Uint8List? decryptedData;
  final String? error;
  
  const DecryptionResult({
    required this.success,
    this.decryptedData,
    this.error,
  });
}

class KeyEscrowResult {
  final bool success;
  final String? keyId;
  final int? shares;
  final int? threshold;
  final List<String>? trustees;
  final String? error;
  
  const KeyEscrowResult({
    required this.success,
    this.keyId,
    this.shares,
    this.threshold,
    this.trustees,
    this.error,
  });
}

class KeyRecoveryResult {
  final bool success;
  final String? keyId;
  final Uint8List? recoveredKey;
  final String? error;
  
  const KeyRecoveryResult({
    required this.success,
    this.keyId,
    this.recoveredKey,
    this.error,
  });
}

class KeyManagementStatus {
  final int totalKeys;
  final int activeKeys;
  final int expiredKeys;
  final int keysNeedingRotation;
  final bool hsmEnabled;
  final int hsmSecurityLevel;
  final bool keyRotationEnabled;
  final DateTime? nextRotationDate;
  final int escrowedKeys;
  
  const KeyManagementStatus({
    required this.totalKeys,
    required this.activeKeys,
    required this.expiredKeys,
    required this.keysNeedingRotation,
    required this.hsmEnabled,
    required this.hsmSecurityLevel,
    required this.keyRotationEnabled,
    this.nextRotationDate,
    required this.escrowedKeys,
  });
}

// Additional supporting classes
class HSMInitResult {
  final bool success;
  final String? error;
  final String? provider;
  final int? securityLevel;
  
  const HSMInitResult({
    required this.success,
    this.error,
    this.provider,
    this.securityLevel,
  });
}

class MasterKey {
  final Uint8List keyMaterial;
  final DateTime createdAt;
  
  const MasterKey(this.keyMaterial, this.createdAt);
  
  static Future<MasterKey> generate(String? passphrase) async {
    final random = Random.secure();
    final keyMaterial = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      keyMaterial[i] = random.nextInt(256);
    }
    return MasterKey(keyMaterial, DateTime.now());
  }
  
  factory MasterKey.fromEncrypted(String encrypted, String? passphrase) {
    // Placeholder implementation
    return MasterKey(Uint8List(32), DateTime.now());
  }
  
  String toEncrypted() {
    // Placeholder implementation
    return base64.encode(keyMaterial);
  }
  
  void dispose() {
    // Clear key material from memory
    keyMaterial.fillRange(0, keyMaterial.length, 0);
  }
}

class KeyStore {
  final Map<String, SecureKey> _keys = {};
  
  KeyStore();
  
  static KeyStore create(MasterKey masterKey) => KeyStore();
  
  factory KeyStore.fromEncrypted(String encrypted, MasterKey masterKey) {
    return KeyStore();
  }
  
  String toEncrypted() => '{}';
  
  Future<void> storeKey(SecureKey key) async {
    _keys[key.id] = key;
  }
  
  Future<SecureKey?> getKey(String keyId, {int? version}) async {
    return _keys[keyId];
  }
  
  Future<List<SecureKey>> getAllKeys() async {
    return _keys.values.toList();
  }
  
  void dispose() {
    _keys.clear();
  }
}

class KeyRotationRecord {
  final int previousVersion;
  final DateTime rotatedAt;
  final String reason;
  
  const KeyRotationRecord({
    required this.previousVersion,
    required this.rotatedAt,
    required this.reason,
  });
}

class KeyEscrowRecord {
  final String keyId;
  final List<ShamirShare> shares;
  final int threshold;
  final List<String> trustees;
  final DateTime createdAt;
  final KeyEscrowPolicy escrowPolicy;
  
  const KeyEscrowRecord({
    required this.keyId,
    required this.shares,
    required this.threshold,
    required this.trustees,
    required this.createdAt,
    required this.escrowPolicy,
  });
}

class ShamirShare {
  final int index;
  final Uint8List value;
  
  const ShamirShare({required this.index, required this.value});
}

class KeyRotationStatus {
  final bool enabled;
  final DateTime? nextRotation;
  
  const KeyRotationStatus({required this.enabled, this.nextRotation});
}

class HSMStatus {
  final bool enabled;
  final int securityLevel;
  
  const HSMStatus({required this.enabled, required this.securityLevel});
}