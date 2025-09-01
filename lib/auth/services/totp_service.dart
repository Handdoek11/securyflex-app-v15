import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:otp/otp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enhanced_auth_models.dart';

/// TOTP (Time-based One-Time Password) service for SecuryFlex
/// 
/// Provides secure TOTP generation, validation, and backup code management
/// with encrypted storage and comprehensive audit logging.
class TOTPService {
  static const String _keyPrefix = 'securyflex_totp_';
  static const String _backupCodesKey = 'securyflex_backup_codes';
  static const String _configKey = 'securyflex_2fa_config';
  static const int _totpDigits = 6;
  static const int _totpPeriod = 30; // seconds
  static const int _totpWindow = 1; // Allow 1 period before/after
  static const int _maxFailedAttempts = 3;
  static const int _lockoutDurationMinutes = 15;
  
  /// Generate a new TOTP secret for a user
  static Future<String> generateSecret(String userId) async {
    final random = Random.secure();
    final bytes = Uint8List(20); // 160 bits for good entropy
    
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    
    // Convert to base32 for TOTP compatibility
    final secret = _base32Encode(bytes);
    
    // Store encrypted secret
    await _storeEncryptedSecret(userId, secret);
    
    // Log security event
    await _logSecurityEvent(userId, 'TOTP secret generated', {
      'secretLength': secret.length,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return secret;
  }
  
  /// Get QR code data for authenticator app setup
  static Future<String> getQRCodeData({
    required String userId,
    required String userEmail,
    required String secret,
    String issuer = 'SecuryFlex',
  }) async {
    final encodedIssuer = Uri.encodeComponent(issuer);
    final encodedAccount = Uri.encodeComponent('$issuer:$userEmail');
    final encodedSecret = Uri.encodeComponent(secret);
    
    return 'otpauth://totp/$encodedAccount?secret=$encodedSecret&issuer=$encodedIssuer&digits=$_totpDigits&period=$_totpPeriod';
  }
  
  /// Verify a TOTP code
  static Future<TOTPVerificationResult> verifyTOTP(
    String userId,
    String code, {
    DateTime? timestamp,
  }) async {
    final config = await getTwoFactorConfig(userId);
    
    // Check if user is locked out
    if (config.isLocked) {
      return TOTPVerificationResult(
        isValid: false,
        errorCode: 'ACCOUNT_LOCKED',
        errorMessage: 'Account tijdelijk vergrendeld wegens te veel mislukte pogingen',
        remainingLockTime: config.lockTimeRemaining,
      );
    }
    
    final secret = await _getEncryptedSecret(userId);
    if (secret == null) {
      return TOTPVerificationResult(
        isValid: false,
        errorCode: 'NO_SECRET',
        errorMessage: 'TOTP nog niet ingesteld voor deze gebruiker',
      );
    }
    
    try {
      final now = timestamp ?? DateTime.now();
      final currentTimeStep = now.millisecondsSinceEpoch ~/ 1000 ~/ _totpPeriod;
      
      // Check current time and adjacent windows for clock drift tolerance
      for (int window = -_totpWindow; window <= _totpWindow; window++) {
        final timeStep = currentTimeStep + window;
        final expectedCode = OTP.generateTOTPCodeString(
          secret,
          timeStep * _totpPeriod * 1000, // Convert to milliseconds
          length: _totpDigits,
          interval: _totpPeriod,
          algorithm: Algorithm.SHA1,
        );
        
        if (code == expectedCode) {
          // Check for replay attacks
          if (await _isCodeRecentlyUsed(userId, code, timeStep)) {
            return TOTPVerificationResult(
              isValid: false,
              errorCode: 'REPLAY_ATTACK',
              errorMessage: 'Deze code is al recent gebruikt',
            );
          }
          
          // Mark code as used
          await _markCodeAsUsed(userId, code, timeStep);
          
          // Reset failed attempts on successful verification
          await _resetFailedAttempts(userId);
          
          // Log successful verification
          await _logSecurityEvent(userId, 'TOTP verification successful', {
            'window': window,
            'timestamp': now.toIso8601String(),
          });
          
          return TOTPVerificationResult(
            isValid: true,
            timeWindow: window,
            nextCodeIn: _totpPeriod - (now.second % _totpPeriod),
          );
        }
      }
      
      // Code verification failed - increment failed attempts
      await _incrementFailedAttempts(userId);
      
      // Log failed verification
      await _logSecurityEvent(userId, 'TOTP verification failed', {
        'code': _obfuscateCode(code),
        'timestamp': now.toIso8601String(),
      });
      
      return TOTPVerificationResult(
        isValid: false,
        errorCode: 'INVALID_CODE',
        errorMessage: 'Ongeldige verificatiecode',
        remainingAttempts: await _getRemainingAttempts(userId),
      );
      
    } catch (e) {
      await _logSecurityEvent(userId, 'TOTP verification error', {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return TOTPVerificationResult(
        isValid: false,
        errorCode: 'VERIFICATION_ERROR',
        errorMessage: 'Fout bij verificatie van code',
      );
    }
  }
  
  /// Generate backup recovery codes
  static Future<List<BackupCode>> generateBackupCodes(
    String userId, {
    int count = 10,
  }) async {
    final codes = <BackupCode>[];
    
    for (int i = 0; i < count; i++) {
      codes.add(BackupCode.generate());
    }
    
    // Store encrypted backup codes
    await _storeBackupCodes(userId, codes);
    
    // Log backup code generation
    await _logSecurityEvent(userId, 'Backup codes generated', {
      'count': count,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return codes;
  }
  
  /// Verify backup code
  static Future<BackupCodeVerificationResult> verifyBackupCode(
    String userId,
    String code,
  ) async {
    final codes = await _getBackupCodes(userId);
    
    for (int i = 0; i < codes.length; i++) {
      final backupCode = codes[i];
      
      if (!backupCode.isUsed && backupCode.verify(code)) {
        // Mark code as used
        codes[i] = backupCode.markAsUsed();
        
        // Update stored codes
        await _storeBackupCodes(userId, codes);
        
        // Reset failed attempts
        await _resetFailedAttempts(userId);
        
        // Log successful backup code usage
        await _logSecurityEvent(userId, 'Backup code used successfully', {
          'remainingCodes': codes.where((c) => !c.isUsed).length,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        return BackupCodeVerificationResult(
          isValid: true,
          remainingCodes: codes.where((c) => !c.isUsed).length,
        );
      }
    }
    
    // Invalid or used code
    await _incrementFailedAttempts(userId);
    
    await _logSecurityEvent(userId, 'Invalid backup code used', {
      'code': _obfuscateCode(code),
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return BackupCodeVerificationResult(
      isValid: false,
      errorCode: 'INVALID_BACKUP_CODE',
      errorMessage: 'Ongeldige of al gebruikte backup code',
      remainingAttempts: await _getRemainingAttempts(userId),
    );
  }
  
  /// Get current two-factor configuration
  static Future<TwoFactorUserConfig> getTwoFactorConfig(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('$_configKey$userId');
    
    if (configJson != null) {
      final config = TwoFactorUserConfig.fromJson(json.decode(configJson));
      return config;
    }
    
    return const TwoFactorUserConfig();
  }
  
  /// Enable TOTP for user
  static Future<void> enableTOTP(String userId) async {
    final config = await getTwoFactorConfig(userId);
    final updatedConfig = config.copyWith(
      isTotpEnabled: true,
      setupDate: DateTime.now(),
    );
    
    await _saveConfig(userId, updatedConfig);
    
    await _logSecurityEvent(userId, 'TOTP enabled', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Disable TOTP for user (requires backup verification)
  static Future<bool> disableTOTP(String userId, String verificationCode) async {
    // Verify current TOTP or backup code before disabling
    final totpResult = await verifyTOTP(userId, verificationCode);
    if (!totpResult.isValid) {
      final backupResult = await verifyBackupCode(userId, verificationCode);
      if (!backupResult.isValid) {
        return false;
      }
    }
    
    // Remove TOTP configuration
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$userId');
    await prefs.remove('$_backupCodesKey$userId');
    await prefs.remove('$_configKey$userId');
    
    await _logSecurityEvent(userId, 'TOTP disabled', {
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return true;
  }
  
  /// Get backup codes status
  static Future<BackupCodeStatus> getBackupCodesStatus(String userId) async {
    final codes = await _getBackupCodes(userId);
    final usedCount = codes.where((c) => c.isUsed).length;
    
    return BackupCodeStatus(
      total: codes.length,
      used: usedCount,
      remaining: codes.length - usedCount,
    );
  }
  
  // Private helper methods
  
  /// Store encrypted TOTP secret
  static Future<void> _storeEncryptedSecret(String userId, String secret) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = _simpleEncrypt(secret, userId);
    await prefs.setString('$_keyPrefix$userId', encrypted);
  }
  
  /// Get encrypted TOTP secret
  static Future<String?> _getEncryptedSecret(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString('$_keyPrefix$userId');
    
    if (encrypted != null) {
      return _simpleDecrypt(encrypted, userId);
    }
    
    return null;
  }
  
  /// Store backup codes
  static Future<void> _storeBackupCodes(String userId, List<BackupCode> codes) async {
    final prefs = await SharedPreferences.getInstance();
    final codesJson = codes.map((c) => c.toJson()).toList();
    final encrypted = _simpleEncrypt(json.encode(codesJson), userId);
    await prefs.setString('$_backupCodesKey$userId', encrypted);
  }
  
  /// Get backup codes
  static Future<List<BackupCode>> _getBackupCodes(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString('$_backupCodesKey$userId');
    
    if (encrypted != null) {
      final decrypted = _simpleDecrypt(encrypted, userId);
      final codesJson = json.decode(decrypted) as List<dynamic>;
      return codesJson.map((c) => BackupCode.fromJson(c)).toList();
    }
    
    return [];
  }
  
  /// Save configuration
  static Future<void> _saveConfig(String userId, TwoFactorUserConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_configKey$userId', json.encode(config.toJson()));
  }
  
  /// Simple encryption for demo (use proper encryption in production)
  static String _simpleEncrypt(String data, String key) {
    final bytes = utf8.encode(data);
    final keyBytes = sha256.convert(utf8.encode(key)).bytes;
    
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] ^= keyBytes[i % keyBytes.length];
    }
    
    return base64.encode(bytes);
  }
  
  /// Simple decryption for demo
  static String _simpleDecrypt(String encryptedData, String key) {
    final bytes = base64.decode(encryptedData);
    final keyBytes = sha256.convert(utf8.encode(key)).bytes;
    
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] ^= keyBytes[i % keyBytes.length];
    }
    
    return utf8.decode(bytes);
  }
  
  /// Base32 encoding for TOTP compatibility
  static String _base32Encode(Uint8List bytes) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final output = StringBuffer();
    
    for (int i = 0; i < bytes.length; i += 5) {
      final chunk = <int>[];
      for (int j = 0; j < 5 && i + j < bytes.length; j++) {
        chunk.add(bytes[i + j]);
      }
      
      while (chunk.length < 5) {
        chunk.add(0);
      }
      
      final combined = (chunk[0] << 32) |
                      (chunk[1] << 24) |
                      (chunk[2] << 16) |
                      (chunk[3] << 8) |
                      chunk[4];
      
      for (int k = 7; k >= 0; k--) {
        output.write(alphabet[(combined >> (k * 5)) & 0x1F]);
      }
    }
    
    return output.toString();
  }
  
  /// Check if code was recently used (prevent replay attacks)
  static Future<bool> _isCodeRecentlyUsed(String userId, String code, int timeStep) async {
    final prefs = await SharedPreferences.getInstance();
    final usedCodesKey = 'used_codes_$userId';
    final usedCodes = prefs.getStringList(usedCodesKey) ?? [];
    
    final codeKey = '${code}_$timeStep';
    return usedCodes.contains(codeKey);
  }
  
  /// Mark code as used
  static Future<void> _markCodeAsUsed(String userId, String code, int timeStep) async {
    final prefs = await SharedPreferences.getInstance();
    final usedCodesKey = 'used_codes_$userId';
    final usedCodes = prefs.getStringList(usedCodesKey) ?? [];
    
    final codeKey = '${code}_$timeStep';
    usedCodes.add(codeKey);
    
    // Keep only recent codes (last 10 minutes)
    final cutoffTime = DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ _totpPeriod - 20;
    usedCodes.removeWhere((key) {
      final parts = key.split('_');
      if (parts.length == 2) {
        final timestamp = int.tryParse(parts[1]);
        return timestamp != null && timestamp < cutoffTime;
      }
      return true;
    });
    
    await prefs.setStringList(usedCodesKey, usedCodes);
  }
  
  /// Increment failed attempts
  static Future<void> _incrementFailedAttempts(String userId) async {
    final config = await getTwoFactorConfig(userId);
    final newFailedAttempts = config.failedAttempts + 1;
    
    DateTime? lockUntil;
    if (newFailedAttempts >= _maxFailedAttempts) {
      lockUntil = DateTime.now().add(const Duration(minutes: _lockoutDurationMinutes));
    }
    
    final updatedConfig = config.copyWith(
      failedAttempts: newFailedAttempts,
      lockedUntil: lockUntil,
    );
    
    await _saveConfig(userId, updatedConfig);
  }
  
  /// Reset failed attempts
  static Future<void> _resetFailedAttempts(String userId) async {
    final config = await getTwoFactorConfig(userId);
    final updatedConfig = config.copyWith(
      failedAttempts: 0,
      lockedUntil: null,
    );
    
    await _saveConfig(userId, updatedConfig);
  }
  
  /// Get remaining attempts before lockout
  static Future<int> _getRemainingAttempts(String userId) async {
    final config = await getTwoFactorConfig(userId);
    return _maxFailedAttempts - config.failedAttempts;
  }
  
  /// Log security event
  static Future<void> _logSecurityEvent(String userId, String event, Map<String, dynamic> data) async {
    // In production, this would send to a proper logging service
    developer.log('TOTP Security Event - User: $userId, Event: $event, Data: $data', name: 'TOTP');
  }
  
  /// Obfuscate code for logging
  static String _obfuscateCode(String code) {
    if (code.length <= 2) return '***';
    return '${code.substring(0, 1)}${'*' * (code.length - 2)}${code.substring(code.length - 1)}';
  }
}

/// TOTP verification result
class TOTPVerificationResult {
  final bool isValid;
  final String? errorCode;
  final String? errorMessage;
  final int? timeWindow;
  final int? nextCodeIn;
  final int? remainingAttempts;
  final Duration? remainingLockTime;
  
  const TOTPVerificationResult({
    required this.isValid,
    this.errorCode,
    this.errorMessage,
    this.timeWindow,
    this.nextCodeIn,
    this.remainingAttempts,
    this.remainingLockTime,
  });
}

/// Backup code verification result
class BackupCodeVerificationResult {
  final bool isValid;
  final String? errorCode;
  final String? errorMessage;
  final int? remainingCodes;
  final int? remainingAttempts;
  
  const BackupCodeVerificationResult({
    required this.isValid,
    this.errorCode,
    this.errorMessage,
    this.remainingCodes,
    this.remainingAttempts,
  });
}

/// Backup codes status
class BackupCodeStatus {
  final int total;
  final int used;
  final int remaining;
  
  const BackupCodeStatus({
    required this.total,
    required this.used,
    required this.remaining,
  });
  
  /// Check if user is running low on backup codes
  bool get isRunningLow => remaining <= 2;
  
  /// Check if user has no backup codes left
  bool get isEmpty => remaining == 0;
  
  /// Get status message in Dutch
  String get statusDutch {
    if (isEmpty) return 'Geen backup codes meer beschikbaar';
    if (isRunningLow) return 'Nog maar $remaining backup codes over';
    return '$remaining van $total backup codes beschikbaar';
  }
}

/// Two-factor user configuration
class TwoFactorUserConfig {
  final bool isTotpEnabled;
  final DateTime? setupDate;
  final int failedAttempts;
  final DateTime? lockedUntil;
  
  const TwoFactorUserConfig({
    this.isTotpEnabled = false,
    this.setupDate,
    this.failedAttempts = 0,
    this.lockedUntil,
  });
  
  /// Check if account is currently locked
  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }
  
  /// Get remaining lock time
  Duration? get lockTimeRemaining {
    if (!isLocked) return null;
    return lockedUntil!.difference(DateTime.now());
  }
  
  /// Copy with updated properties
  TwoFactorUserConfig copyWith({
    bool? isTotpEnabled,
    DateTime? setupDate,
    int? failedAttempts,
    DateTime? lockedUntil,
  }) {
    return TwoFactorUserConfig(
      isTotpEnabled: isTotpEnabled ?? this.isTotpEnabled,
      setupDate: setupDate ?? this.setupDate,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isTotpEnabled': isTotpEnabled,
      'setupDate': setupDate?.toIso8601String(),
      'failedAttempts': failedAttempts,
      'lockedUntil': lockedUntil?.toIso8601String(),
    };
  }
  
  /// Create from JSON
  factory TwoFactorUserConfig.fromJson(Map<String, dynamic> json) {
    return TwoFactorUserConfig(
      isTotpEnabled: json['isTotpEnabled'] ?? false,
      setupDate: json['setupDate'] != null ? DateTime.parse(json['setupDate']) : null,
      failedAttempts: json['failedAttempts'] ?? 0,
      lockedUntil: json['lockedUntil'] != null ? DateTime.parse(json['lockedUntil']) : null,
    );
  }
}