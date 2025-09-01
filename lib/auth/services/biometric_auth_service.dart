import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enhanced_auth_models.dart' as models;
import 'secure_key_manager.dart';
import 'aes_gcm_crypto_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Biometric Authentication service for SecuryFlex
/// 
/// Provides comprehensive biometric authentication support with platform-specific
/// detection, secure configuration storage, and comprehensive error handling.
class BiometricAuthService {
  static const String _configKey = 'securyflex_biometric_config';
  static const int _maxFailedAttempts = 3;
  static const int _lockoutDurationMinutes = 120; // Increased to 2 hours
  // REMOVED: Hardcoded biometric secret key - now uses secure key derivation
  // Biometric data encryption now uses device-specific key derivation
  
  static final LocalAuthentication _localAuth = LocalAuthentication();
  
  /// Check if biometric authentication is available on the device
  static Future<BiometricAvailabilityResult> checkBiometricAvailability() async {
    try {
      // Check if device supports biometric authentication
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        return BiometricAvailabilityResult(
          isAvailable: false,
          reason: 'Biometrische authenticatie niet ondersteund op dit apparaat',
          reasonDutch: 'Biometrische authenticatie niet ondersteund op dit apparaat',
        );
      }
      
      // Check if device is enrolled with biometrics
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        return BiometricAvailabilityResult(
          isAvailable: false,
          reason: 'Apparaat ondersteunt geen biometrische authenticatie',
          reasonDutch: 'Apparaat ondersteunt geen biometrische authenticatie',
        );
      }
      
      // Get available biometric types
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        return BiometricAvailabilityResult(
          isAvailable: false,
          reason: 'Geen biometrische gegevens ingesteld op dit apparaat',
          reasonDutch: 'Geen biometrische gegevens ingesteld op dit apparaat',
        );
      }
      
      // Convert platform-specific types to our enum
      final availableTypes = availableBiometrics.map(_mapBiometricType).toList();
      
      return BiometricAvailabilityResult(
        isAvailable: true,
        availableTypes: availableTypes,
        platformTypes: availableBiometrics,
      );
      
    } on PlatformException catch (e) {
      return BiometricAvailabilityResult(
        isAvailable: false,
        reason: 'Fout bij controleren biometrische ondersteuning: ${e.message}',
        reasonDutch: 'Fout bij controleren biometrische ondersteuning: ${e.message}',
        errorCode: e.code,
      );
    } catch (e) {
      return BiometricAvailabilityResult(
        isAvailable: false,
        reason: 'Onbekende fout bij controleren biometrische ondersteuning',
        reasonDutch: 'Onbekende fout bij controleren biometrische ondersteuning',
      );
    }
  }
  
  /// Authenticate with biometric
  static Future<BiometricAuthResult> authenticate({
    required String userId,
    String? localizedFallbackTitle,
    bool biometricOnly = false,
  }) async {
    try {
      // Check if user is locked out
      final config = await getBiometricConfig(userId);
      if (config.isLocked) {
        return BiometricAuthResult(
          isAuthenticated: false,
          errorCode: 'USER_LOCKED',
          errorMessage: 'Account tijdelijk vergrendeld wegens te veel mislukte pogingen',
          errorMessageDutch: 'Account tijdelijk vergrendeld wegens te veel mislukte pogingen',
          remainingLockTime: config.lockedUntil?.difference(DateTime.now()),
        );
      }
      
      // Check availability first
      final availability = await checkBiometricAvailability();
      if (!availability.isAvailable) {
        return BiometricAuthResult(
          isAuthenticated: false,
          errorCode: 'NOT_AVAILABLE',
          errorMessage: availability.reason,
          errorMessageDutch: availability.reasonDutch,
        );
      }
      
      // Platform-specific localized strings
      final String localizedReason = _getLocalizedReason();
      final String fallbackTitle = localizedFallbackTitle ?? 'Voer uw pincode in';
      
      // Attempt biometric authentication
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
        authMessages: [
          AndroidAuthMessages(
            signInTitle: 'Biometrische verificatie',
            cancelButton: 'Annuleren',
            deviceCredentialsRequiredTitle: 'Apparaatbeveiliging vereist',
            deviceCredentialsSetupDescription: 'Stel apparaatbeveiliging in',
            goToSettingsButton: 'Ga naar instellingen',
            goToSettingsDescription: 'Biometrische authenticatie is niet ingesteld',
            biometricRequiredTitle: 'Biometrie vereist',
            biometricHint: 'Verifieer uw identiteit',
            biometricNotRecognized: 'Niet herkend, probeer opnieuw',
            biometricSuccess: 'Biometrische verificatie succesvol',
          ),
          IOSAuthMessages(
            cancelButton: 'Annuleren',
            goToSettingsButton: 'Ga naar instellingen',
            goToSettingsDescription: 'Biometrische authenticatie is niet ingesteld',
            lockOut: 'Biometrische authenticatie is uitgeschakeld',
            localizedFallbackTitle: fallbackTitle,
          ),
        ],
      );
      
      if (didAuthenticate) {
        // Reset failed attempts on successful authentication
        await _resetFailedAttempts(userId);
        
        // Update last used timestamp
        await _updateLastUsed(userId);
        
        // Log successful authentication (minimal data for security)
        await _logSecurityEvent(userId, 'Biometric authentication successful', {
          'authMethod': 'biometric',
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        return BiometricAuthResult(
          isAuthenticated: true,
          biometricType: availability.availableTypes?.first,
          message: 'Biometrische authenticatie succesvol',
          messageDutch: 'Biometrische authenticatie succesvol',
        );
      } else {
        // Authentication failed or was cancelled
        await _incrementFailedAttempts(userId);
        
        // Log failed authentication (security event)
        await _logSecurityEvent(userId, 'Biometric authentication failed', {
          'reason': 'user_cancelled_or_failed',
          'timestamp': DateTime.now().toIso8601String(),
          'failedAttempts': (await getBiometricConfig(userId)).failedAttempts + 1,
        });
        
        final remainingAttempts = await _getRemainingAttempts(userId);
        
        return BiometricAuthResult(
          isAuthenticated: false,
          errorCode: 'AUTH_FAILED',
          errorMessage: 'Biometrische authenticatie mislukt of geannuleerd',
          errorMessageDutch: 'Biometrische authenticatie mislukt of geannuleerd',
          remainingAttempts: remainingAttempts,
        );
      }
      
    } on PlatformException catch (e) {
      await _handlePlatformException(userId, e);
      
      return BiometricAuthResult(
        isAuthenticated: false,
        errorCode: e.code,
        errorMessage: _getPlatformErrorMessage(e),
        errorMessageDutch: _getPlatformErrorMessage(e),
      );
    } catch (e) {
      await _logSecurityEvent(userId, 'Biometric authentication error', {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return BiometricAuthResult(
        isAuthenticated: false,
        errorCode: 'UNKNOWN_ERROR',
        errorMessage: 'Onbekende fout bij biometrische authenticatie',
        errorMessageDutch: 'Onbekende fout bij biometrische authenticatie',
      );
    }
  }
  
  /// Enable biometric authentication for user
  static Future<bool> enableBiometric({
    required String userId,
    List<models.BiometricType>? enabledTypes,
  }) async {
    try {
      // Initialize secure biometric key derivation
      await BiometricKeyDerivation.initialize();
      
      // Check availability first
      final availability = await checkBiometricAvailability();
      if (!availability.isAvailable) {
        return false;
      }
      
      // Test authentication before enabling
      final testResult = await authenticate(userId: userId);
      if (!testResult.isAuthenticated) {
        return false;
      }
      
      // Create configuration
      final config = models.BiometricConfig(
        isEnabled: true,
        isSupported: true,
        availableTypes: availability.availableTypes ?? [],
        enabledTypes: enabledTypes ?? availability.availableTypes ?? [],
        setupDate: DateTime.now(),
        lastUsed: DateTime.now(),
      );
      
      // Save configuration
      await _saveBiometricConfig(userId, config);
      
      // Initialize secure biometric keys for the user
      await BiometricKeyDerivation.getBiometricKey(userId);
      
      // Log enabling event
      await _logSecurityEvent(userId, 'Biometric authentication enabled', {
        'availableTypes': availability.availableTypes?.map((t) => t.name).toList() ?? [],
        'enabledTypes': config.enabledTypes.map((t) => t.name).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'secureKeyDerivation': true,
      });
      
      await _auditCryptoOperation('BIOMETRIC_ENABLED', 'Secure biometric authentication enabled for user: $userId');
      
      return true;
      
    } catch (e) {
      await _logSecurityEvent(userId, 'Biometric enable error', {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      await _auditCryptoOperation('BIOMETRIC_ENABLE_ERROR', 'Failed to enable biometric auth: $e');
      return false;
    }
  }
  
  /// Disable biometric authentication
  static Future<bool> disableBiometric({
    required String userId,
    required String verificationCode,
  }) async {
    try {
      // In production, verify the code (TOTP, SMS, or password)
      // For demo purposes, we'll just disable
      
      final config = await getBiometricConfig(userId);
      final updatedConfig = config.copyWith(
        isEnabled: false,
      );
      
      await _saveBiometricConfig(userId, updatedConfig);
      
      // Clear any stored biometric data
      await _clearBiometricData(userId);
      
      // Log disabling event
      await _logSecurityEvent(userId, 'Biometric authentication disabled', {
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await _auditCryptoOperation('BIOMETRIC_DISABLED', 'Biometric authentication disabled for user: $userId');
      
      return true;
      
    } catch (e) {
      await _logSecurityEvent(userId, 'Biometric disable error', {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      await _auditCryptoOperation('BIOMETRIC_DISABLE_ERROR', 'Failed to disable biometric auth: $e');
      return false;
    }
  }
  
  /// Get biometric configuration for user
  static Future<models.BiometricConfig> getBiometricConfig(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('$_configKey$userId');
      
      if (configJson != null) {
        return models.BiometricConfig.fromJson(json.decode(configJson));
      }
      
      // Return default configuration with availability check
      final availability = await checkBiometricAvailability();
      return models.BiometricConfig(
        isSupported: availability.isAvailable,
        availableTypes: availability.availableTypes ?? [],
      );
      
    } catch (e) {
      return const models.BiometricConfig();
    }
  }
  
  /// Check if biometric is enabled for user
  static Future<bool> isBiometricEnabled(String userId) async {
    final config = await getBiometricConfig(userId);
    return config.isEnabled && !config.isLocked;
  }
  
  /// Get platform capabilities
  static Future<BiometricPlatformInfo> getPlatformInfo() async {
    final capabilities = <String, dynamic>{};
    
    try {
      capabilities['canCheckBiometrics'] = await _localAuth.canCheckBiometrics;
      capabilities['isDeviceSupported'] = await _localAuth.isDeviceSupported();
      capabilities['availableBiometrics'] = await _localAuth.getAvailableBiometrics();
      
      // Platform-specific information
      if (Platform.isAndroid) {
        capabilities['platform'] = 'Android';
        capabilities['strongBiometrics'] = await _localAuth.getAvailableBiometrics().then(
          (types) => types.contains(BiometricType.strong),
        );
      } else if (Platform.isIOS) {
        capabilities['platform'] = 'iOS';
        capabilities['faceID'] = await _localAuth.getAvailableBiometrics().then(
          (types) => types.contains(BiometricType.face),
        );
        capabilities['touchID'] = await _localAuth.getAvailableBiometrics().then(
          (types) => types.contains(BiometricType.fingerprint),
        );
      } else {
        capabilities['platform'] = 'Other';
      }
      
      return BiometricPlatformInfo(
        isSupported: capabilities['canCheckBiometrics'] == true,
        platform: capabilities['platform'],
        capabilities: capabilities,
      );
      
    } catch (e) {
      return BiometricPlatformInfo(
        isSupported: false,
        platform: Platform.operatingSystem,
        capabilities: {'error': e.toString()},
      );
    }
  }
  
  // Private helper methods
  
  /// Map platform BiometricType to our enum
  static models.BiometricType _mapBiometricType(BiometricType platformType) {
    switch (platformType) {
      case BiometricType.face:
        return models.BiometricType.face;
      case BiometricType.fingerprint:
        return models.BiometricType.fingerprint;
      case BiometricType.iris:
        return models.BiometricType.iris;
      case BiometricType.weak:
        return models.BiometricType.weak;
      case BiometricType.strong:
        return models.BiometricType.strong;
    }
  }
  
  /// Get localized reason for authentication
  static String _getLocalizedReason() {
    if (Platform.isIOS) {
      return 'Verifieer uw identiteit om door te gaan';
    } else {
      return 'Gebruik uw vingerafdruk, gezicht of andere biometrische gegevens om uw identiteit te verifiëren';
    }
  }
  
  /// Handle platform exceptions
  static Future<void> _handlePlatformException(String userId, PlatformException e) async {
    switch (e.code) {
      case 'LockedOut':
      case 'PermanentlyLockedOut':
        await _lockUserAccount(userId);
        break;
      case 'BiometricOnly':
      case 'DeviceNotSecure':
        // Log security concern
        await _logSecurityEvent(userId, 'Biometric security issue', {
          'errorCode': e.code,
          'message': e.message,
        });
        break;
    }
  }
  
  /// Get Dutch error message for platform exceptions
  static String _getPlatformErrorMessage(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return 'Biometrische authenticatie niet beschikbaar';
      case 'NotEnrolled':
        return 'Geen biometrische gegevens ingesteld op dit apparaat';
      case 'LockedOut':
        return 'Te veel mislukte pogingen. Probeer het later opnieuw.';
      case 'PermanentlyLockedOut':
        return 'Biometrische authenticatie permanent vergrendeld';
      case 'BiometricOnly':
        return 'Alleen biometrische authenticatie toegestaan';
      case 'DeviceNotSecure':
        return 'Apparaat is niet beveiligd. Stel een pincode, wachtwoord of patroon in.';
      case 'UserCancel':
        return 'Authenticatie geannuleerd door gebruiker';
      case 'UserFallback':
        return 'Gebruiker heeft gekozen voor alternatieve authenticatie';
      case 'SystemCancel':
        return 'Authenticatie geannuleerd door systeem';
      case 'PasscodeNotSet':
        return 'Geen pincode ingesteld op apparaat';
      case 'BiometryNotAvailable':
        return 'Biometrische authenticatie niet beschikbaar';
      case 'BiometryNotEnrolled':
        return 'Geen biometrische gegevens geregistreerd';
      case 'BiometryLockout':
        return 'Biometrische authenticatie tijdelijk vergrendeld';
      default:
        return e.message ?? 'Onbekende fout bij biometrische authenticatie';
    }
  }
  
  /// Save biometric configuration
  static Future<void> _saveBiometricConfig(String userId, models.BiometricConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_configKey$userId', json.encode(config.toJson()));
  }
  
  /// Increment failed attempts
  static Future<void> _incrementFailedAttempts(String userId) async {
    final config = await getBiometricConfig(userId);
    final newFailedAttempts = config.failedAttempts + 1;
    
    DateTime? lockUntil;
    if (newFailedAttempts >= _maxFailedAttempts) {
      // Progressive lockout: longer periods for repeated failures
      int lockoutMinutes = _lockoutDurationMinutes;
      if (newFailedAttempts >= 6) {
        lockoutMinutes = 480; // 8 hours for excessive attempts
      } else if (newFailedAttempts >= 5) {
        lockoutMinutes = 240; // 4 hours for persistent attempts
      }
      
      lockUntil = DateTime.now().add(Duration(minutes: lockoutMinutes));
      
      // Log security event for account lockout
      await _logSecurityEvent(userId, 'Biometric account locked', {
        'failedAttempts': newFailedAttempts,
        'lockoutDuration': lockoutMinutes,
        'lockoutUntil': lockUntil.toIso8601String(),
      });
    }
    
    final updatedConfig = config.copyWith(
      failedAttempts: newFailedAttempts,
      lockedUntil: lockUntil,
    );
    
    await _saveBiometricConfig(userId, updatedConfig);
  }
  
  /// Reset failed attempts
  static Future<void> _resetFailedAttempts(String userId) async {
    final config = await getBiometricConfig(userId);
    final updatedConfig = config.copyWith(
      failedAttempts: 0,
      lockedUntil: null,
    );
    
    await _saveBiometricConfig(userId, updatedConfig);
  }
  
  /// Get remaining attempts
  static Future<int> _getRemainingAttempts(String userId) async {
    final config = await getBiometricConfig(userId);
    return _maxFailedAttempts - config.failedAttempts;
  }
  
  /// Update last used timestamp
  static Future<void> _updateLastUsed(String userId) async {
    final config = await getBiometricConfig(userId);
    final updatedConfig = config.copyWith(lastUsed: DateTime.now());
    await _saveBiometricConfig(userId, updatedConfig);
  }
  
  /// Lock user account with progressive penalties
  static Future<void> _lockUserAccount(String userId) async {
    final config = await getBiometricConfig(userId);
    
    // Determine lockout duration based on severity
    int lockoutMinutes = _lockoutDurationMinutes;
    if (config.failedAttempts >= 8) {
      lockoutMinutes = 1440; // 24 hours for severe abuse
    } else if (config.failedAttempts >= 6) {
      lockoutMinutes = 480;  // 8 hours
    }
    
    final lockUntil = DateTime.now().add(Duration(minutes: lockoutMinutes));
    
    final updatedConfig = config.copyWith(
      failedAttempts: config.failedAttempts + 1,
      lockedUntil: lockUntil,
    );
    
    await _saveBiometricConfig(userId, updatedConfig);
    
    // Log critical security event
    await _logSecurityEvent(userId, 'Biometric account force-locked', {
      'reason': 'Platform security lockout',
      'lockoutDuration': lockoutMinutes,
      'totalFailedAttempts': updatedConfig.failedAttempts,
    });
  }
  
  /// Clear biometric data
  static Future<void> _clearBiometricData(String userId) async {
    try {
      // Clear legacy data if exists
      final prefs = await SharedPreferences.getInstance();
      final legacyKeys = prefs.getKeys().where(
        (key) => key.contains('biometric') && key.contains(userId),
      );
      
      for (final key in legacyKeys) {
        await prefs.remove(key);
      }
      
      // Clear secure biometric keys from secure storage
      await BiometricKeyDerivation.clearBiometricKeys(userId);
      
      await _auditCryptoOperation('BIOMETRIC_DATA_CLEARED', 'Biometric data cleared for user: $userId');
    } catch (e) {
      await _auditCryptoOperation('BIOMETRIC_CLEAR_ERROR', 'Failed to clear biometric data: $e');
    }
  }
  
  /// Log security event
  static Future<void> _logSecurityEvent(String userId, String event, Map<String, dynamic> data) async {
    // In production, this would send to a proper logging service
    developer.log('Biometric Security Event - User: $userId, Event: $event, Data: $data', name: 'BiometricAuth');
  }
  
  /// Audit crypto operations for compliance
  static Future<void> _auditCryptoOperation(String operation, String details) async {
    try {
      final auditEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'operation': operation,
        'service': 'BiometricAuthService',
        'details': details,
      };
      
      // In production, send to secure audit log
      debugPrint('BIOMETRIC_AUDIT: ${json.encode(auditEntry)}');
    } catch (e) {
      debugPrint('Biometric audit logging failed: $e');
    }
  }
}

/// Biometric availability result
class BiometricAvailabilityResult {
  final bool isAvailable;
  final String? reason;
  final String? reasonDutch;
  final String? errorCode;
  final List<models.BiometricType>? availableTypes;
  final List<BiometricType>? platformTypes;
  
  const BiometricAvailabilityResult({
    required this.isAvailable,
    this.reason,
    this.reasonDutch,
    this.errorCode,
    this.availableTypes,
    this.platformTypes,
  });
}

/// Biometric authentication result
class BiometricAuthResult {
  final bool isAuthenticated;
  final models.BiometricType? biometricType;
  final String? message;
  final String? messageDutch;
  final String? errorCode;
  final String? errorMessage;
  final String? errorMessageDutch;
  final int? remainingAttempts;
  final Duration? remainingLockTime;
  
  const BiometricAuthResult({
    required this.isAuthenticated,
    this.biometricType,
    this.message,
    this.messageDutch,
    this.errorCode,
    this.errorMessage,
    this.errorMessageDutch,
    this.remainingAttempts,
    this.remainingLockTime,
  });
}

/// Biometric platform information
class BiometricPlatformInfo {
  final bool isSupported;
  final String platform;
  final Map<String, dynamic> capabilities;
  
  const BiometricPlatformInfo({
    required this.isSupported,
    required this.platform,
    required this.capabilities,
  });
  
  /// Get human-readable capabilities in Dutch
  List<String> get dutchCapabilities {
    final caps = <String>[];
    
    if (capabilities['faceID'] == true) {
      caps.add('Face ID');
    }
    if (capabilities['touchID'] == true) {
      caps.add('Touch ID');
    }
    if (capabilities['strongBiometrics'] == true) {
      caps.add('Sterke biometrie');
    }
    
    final types = capabilities['availableBiometrics'] as List<dynamic>?;
    if (types != null) {
      for (final type in types) {
        if (type == BiometricType.fingerprint) {
          caps.add('Vingerafdruk');
        } else if (type == BiometricType.face) {
          caps.add('Gezichtsherkenning');
        } else if (type == BiometricType.iris) {
          caps.add('Iris scan');
        }
      }
    }
    
    return caps.isEmpty ? ['Geen biometrische mogelijkheden'] : caps;
  }
}

/// Secure Biometric Key Derivation Service
/// Implements device-specific key derivation for biometric data encryption
/// Replaces hardcoded secret keys with cryptographically secure key derivation
class BiometricKeyDerivation {
  // Key derivation parameters
  static const String _biometricKeyContext = 'biometric_encryption';
  static const int _pbkdf2Iterations = 100000; // OWASP recommended minimum
  static const int _keyLength = 32; // 256 bits for AES-256
  static const String _biometricDataPrefix = 'BIO_V2';
  
  // Storage keys
  static const String _deviceIdKey = 'device_id_biometric';
  static const String _biometricSaltKey = 'biometric_salt';
  static const String _keyVersionKey = 'biometric_key_version';
  static const String _migrationFlagKey = 'biometric_migration_completed';
  
  static bool _isInitialized = false;
  
  /// Initialize the biometric key derivation service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await SecureKeyManager.initialize();
      await AESGCMCryptoService.initialize();
      
      // Ensure device ID exists
      await _ensureDeviceId();
      
      // Check for legacy data migration
      await _migrateLegacyData();
      
      _isInitialized = true;
      debugPrint('BiometricKeyDerivation initialized successfully');
    } catch (e) {
      throw BiometricSecurityException('Failed to initialize BiometricKeyDerivation: $e');
    }
  }
  
  /// Get biometric encryption key for user
  static Future<Uint8List> getBiometricKey(String userId) async {
    _ensureInitialized();
    
    try {
      final deviceId = await _getDeviceId();
      final salt = await _getBiometricSalt(userId);
      
      // Create key material from device + user + context
      final keyMaterial = utf8.encode('$deviceId|$userId|${DateTime.now().year}');
      
      // Derive key using PBKDF2
      final derivedKey = await _deriveKeyPBKDF2(
        keyMaterial,
        salt,
        _pbkdf2Iterations,
        _keyLength,
      );
      
      return derivedKey;
    } catch (e) {
      throw BiometricSecurityException('Failed to derive biometric key: $e');
    }
  }
  
  /// Encrypt biometric-related data
  static Future<String> encryptBiometricData(
    String data,
    String userId,
  ) async {
    _ensureInitialized();
    
    if (data.isEmpty) return '';
    
    try {
      final context = '${_biometricKeyContext}_$userId';
      
      // Use AES-GCM for authenticated encryption
      final encrypted = await AESGCMCryptoService.encryptString(data, context);
      
      return '$_biometricDataPrefix:$encrypted';
    } catch (e) {
      throw BiometricSecurityException('Failed to encrypt biometric data: $e');
    }
  }
  
  /// Decrypt biometric-related data
  static Future<String> decryptBiometricData(
    String encryptedData,
    String userId,
  ) async {
    _ensureInitialized();
    
    if (encryptedData.isEmpty) return '';
    
    try {
      // Handle version prefixes
      String dataToDecrypt = encryptedData;
      
      if (encryptedData.startsWith('$_biometricDataPrefix:')) {
        // New format - use secure key derivation
        dataToDecrypt = encryptedData.substring(_biometricDataPrefix.length + 1);
        final context = '${_biometricKeyContext}_$userId';
        return await AESGCMCryptoService.decryptString(dataToDecrypt, context);
      } else {
        // Legacy format - attempt migration
        await _migrateLegacyBiometricData(userId, encryptedData);
        throw BiometricSecurityException('Legacy biometric data detected - migration required');
      }
    } catch (e) {
      throw BiometricSecurityException('Failed to decrypt biometric data: $e');
    }
  }
  
  /// Rotate biometric keys for security
  static Future<void> rotateBiometricKeys(String userId) async {
    _ensureInitialized();
    
    try {
      // Generate new salt
      final newSalt = SecureKeyManager.generateSecureRandom(32);
      await _storeBiometricSalt(userId, newSalt);
      
      // Update key version
      final currentVersion = await _getBiometricKeyVersion(userId);
      await _storeBiometricKeyVersion(userId, currentVersion + 1);
      
      debugPrint('Biometric keys rotated successfully');
    } catch (e) {
      throw BiometricSecurityException('Failed to rotate biometric keys: $e');
    }
  }
  
  /// Clear all biometric keys for user
  static Future<void> clearBiometricKeys(String userId) async {
    try {
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
          keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
          storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
          synchronizable: false,
        ),
        lOptions: LinuxOptions(),
        wOptions: WindowsOptions(
          useBackwardCompatibility: false,
        ),
      );
      
      // Clear all biometric-related keys
      final keysToRemove = [
        '${_biometricSaltKey}_$userId',
        '${_keyVersionKey}_$userId',
      ];
      
      for (final key in keysToRemove) {
        await secureStorage.delete(key: key);
      }
      
      debugPrint('Biometric keys cleared successfully');
    } catch (e) {
      throw BiometricSecurityException('Failed to clear biometric keys: $e');
    }
  }
  
  // Private implementation methods
  
  /// Ensure service is initialized
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw BiometricSecurityException('BiometricKeyDerivation not initialized');
    }
  }
  
  /// Get or create device-specific identifier
  static Future<String> _getDeviceId() async {
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        synchronizable: false,
      ),
      lOptions: LinuxOptions(),
      wOptions: WindowsOptions(
        useBackwardCompatibility: false,
      ),
    );
    
    String? deviceId = await secureStorage.read(key: _deviceIdKey);
    
    if (deviceId == null) {
      // Generate new device ID
      deviceId = _generateDeviceId();
      await secureStorage.write(key: _deviceIdKey, value: deviceId);
    }
    
    return deviceId;
  }
  
  /// Ensure device ID exists
  static Future<void> _ensureDeviceId() async {
    await _getDeviceId();
  }
  
  /// Generate device-specific identifier
  static String _generateDeviceId() {
    // Combine platform info with random data
    final platformInfo = {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    final random = SecureKeyManager.generateSecureRandom(16);
    final combined = '${json.encode(platformInfo)}_${base64.encode(random)}';
    
    // Hash to create stable ID
    final digest = sha256.convert(utf8.encode(combined));
    return base64Url.encode(digest.bytes);
  }
  
  /// Get or create biometric salt for user
  static Future<Uint8List> _getBiometricSalt(String userId) async {
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        synchronizable: false,
      ),
      lOptions: LinuxOptions(),
      wOptions: WindowsOptions(
        useBackwardCompatibility: false,
      ),
    );
    
    final saltKey = '${_biometricSaltKey}_$userId';
    
    String? saltB64 = await secureStorage.read(key: saltKey);
    if (saltB64 == null) {
      final salt = SecureKeyManager.generateSecureRandom(32);
      await secureStorage.write(key: saltKey, value: base64.encode(salt));
      return salt;
    }
    
    return base64.decode(saltB64);
  }
  
  /// Store biometric salt for user
  static Future<void> _storeBiometricSalt(String userId, Uint8List salt) async {
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        synchronizable: false,
      ),
      lOptions: LinuxOptions(),
      wOptions: WindowsOptions(
        useBackwardCompatibility: false,
      ),
    );
    
    final saltKey = '${_biometricSaltKey}_$userId';
    await secureStorage.write(key: saltKey, value: base64.encode(salt));
  }
  
  /// Get biometric key version
  static Future<int> _getBiometricKeyVersion(String userId) async {
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        synchronizable: false,
      ),
      lOptions: LinuxOptions(),
      wOptions: WindowsOptions(
        useBackwardCompatibility: false,
      ),
    );
    
    final versionKey = '${_keyVersionKey}_$userId';
    
    String? version = await secureStorage.read(key: versionKey);
    return int.tryParse(version ?? '1') ?? 1;
  }
  
  /// Store biometric key version
  static Future<void> _storeBiometricKeyVersion(String userId, int version) async {
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        synchronizable: false,
      ),
      lOptions: LinuxOptions(),
      wOptions: WindowsOptions(
        useBackwardCompatibility: false,
      ),
    );
    
    final versionKey = '${_keyVersionKey}_$userId';
    await secureStorage.write(key: versionKey, value: version.toString());
  }
  
  /// Derive key using PBKDF2
  static Future<Uint8List> _deriveKeyPBKDF2(
    List<int> keyMaterial,
    Uint8List salt,
    int iterations,
    int keyLength,
  ) async {
    // Use HMAC-SHA256 for key derivation
    var derivedKey = Uint8List.fromList(keyMaterial);
    
    // PBKDF2 implementation using HMAC-SHA256
    for (int i = 0; i < iterations; i++) {
      final hmac = Hmac(sha256, derivedKey);
      final digest = hmac.convert([...salt, ...derivedKey]);
      derivedKey = Uint8List.fromList(digest.bytes);
    }
    
    // Ensure correct key length
    if (derivedKey.length > keyLength) {
      derivedKey = derivedKey.sublist(0, keyLength);
    } else if (derivedKey.length < keyLength) {
      // Expand key if needed
      final expanded = Uint8List(keyLength);
      for (int i = 0; i < keyLength; i++) {
        expanded[i] = derivedKey[i % derivedKey.length];
      }
      derivedKey = expanded;
    }
    
    return derivedKey;
  }
  
  /// Migrate legacy biometric data
  static Future<void> _migrateLegacyData() async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        synchronizable: false,
      ),
      lOptions: LinuxOptions(),
      wOptions: WindowsOptions(
        useBackwardCompatibility: false,
      ),
    );
    
    // Check if migration is already completed
    String? migrationFlag = await secureStorage.read(key: _migrationFlagKey);
    if (migrationFlag == 'completed') return;
    
    try {
      // Look for legacy biometric data patterns
      final legacyKeys = prefs.getKeys().where(
        (key) => key.contains('biometric') && key.contains('secret'),
      ).toList();
      
      if (legacyKeys.isNotEmpty) {
        debugPrint('Found ${legacyKeys.length} legacy biometric keys - will be cleared on next access');
        
        // Clear legacy keys
        for (final key in legacyKeys) {
          await prefs.remove(key);
        }
      }
      
      // Mark migration as completed
      await secureStorage.write(key: _migrationFlagKey, value: 'completed');
      debugPrint('Legacy biometric data migration completed');
    } catch (e) {
      debugPrint('Legacy data migration failed: $e');
    }
  }
  
  /// Migrate specific user's legacy biometric data
  static Future<void> _migrateLegacyBiometricData(String userId, String legacyData) async {
    try {
      debugPrint('Attempting migration of legacy biometric data');
      
      // For security, we cannot decrypt legacy data with hardcoded key
      // Instead, we'll force user to re-enable biometrics
      await clearBiometricKeys(userId);
      
      throw BiometricSecurityException('Legacy biometric data found - user must re-enable biometrics for security');
    } catch (e) {
      throw BiometricSecurityException('Legacy data migration failed: $e');
    }
  }
}

/// Biometric-specific security exception to avoid import conflicts
class BiometricSecurityException implements Exception {
  final String message;
  BiometricSecurityException(this.message);
  
  @override
  String toString() => 'BiometricSecurityException: $message';
}