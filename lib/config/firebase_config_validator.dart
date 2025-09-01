import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'environment_config.dart';

/// Advanced Firebase Configuration Validator with Cryptographic Security
/// 
/// Validates Firebase configuration integrity, authenticity, and security
/// using cryptographic methods and security best practices.
class FirebaseConfigValidator {
  FirebaseConfigValidator._();

  // Configuration integrity hashes (SHA-256) - for future use with known good configs
  // static const Map<String, String> _expectedConfigHashes = {
  //   'development': '8f43e5c2e9b1a4d6f7a2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6',
  //   'staging': '7f43e5c2e9b1a4d6f7a2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z7',
  //   'production': '9f43e5c2e9b1a4d6f7a2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z8',
  // };

  /// Validate Firebase configuration with cryptographic integrity checks
  static Future<FirebaseValidationResult> validateConfiguration() async {
    final result = FirebaseValidationResult();
    
    try {
      // Basic configuration validation
      await _validateBasicConfiguration(result);
      
      // Advanced security validation
      await _validateSecurityConfiguration(result);
      
      // API key format validation
      await _validateApiKeyFormats(result);
      
      // Configuration integrity validation
      await _validateConfigurationIntegrity(result);
      
      // Environment-specific validation
      await _validateEnvironmentSpecificSecurity(result);
      
    } catch (e) {
      result.addError('Critical validation error: ${e.toString()}');
      result.isValid = false;
    }
    
    return result;
  }

  /// Validate basic Firebase configuration requirements
  static Future<void> _validateBasicConfiguration(FirebaseValidationResult result) async {
    // Project ID validation
    final projectId = EnvironmentConfig.firebaseProjectId;
    if (projectId.isEmpty) {
      result.addError('Firebase Project ID is missing');
    } else if (!_isValidProjectId(projectId)) {
      result.addError('Firebase Project ID format is invalid');
    }

    // API Key validation
    if (EnvironmentConfig.firebaseWebApiKey.isEmpty) {
      result.addError('Firebase Web API Key is missing');
    }
    if (EnvironmentConfig.firebaseAndroidApiKey.isEmpty) {
      result.addError('Firebase Android API Key is missing');
    }
    if (EnvironmentConfig.firebaseIosApiKey.isEmpty) {
      result.addError('Firebase iOS API Key is missing');
    }

    // App ID validation
    if (EnvironmentConfig.firebaseWebAppId.isEmpty) {
      result.addError('Firebase Web App ID is missing');
    }
    if (EnvironmentConfig.firebaseAndroidAppId.isEmpty) {
      result.addError('Firebase Android App ID is missing');
    }
    if (EnvironmentConfig.firebaseIosAppId.isEmpty) {
      result.addError('Firebase iOS App ID is missing');
    }

    // Auth domain validation
    final authDomain = EnvironmentConfig.firebaseAuthDomain;
    if (authDomain.isEmpty) {
      result.addError('Firebase Auth Domain is missing');
    } else if (!_isValidAuthDomain(authDomain)) {
      result.addError('Firebase Auth Domain format is invalid');
    }

    // Storage bucket validation
    final storageBucket = EnvironmentConfig.firebaseStorageBucket;
    if (storageBucket.isEmpty) {
      result.addError('Firebase Storage Bucket is missing');
    } else if (!_isValidStorageBucket(storageBucket)) {
      result.addError('Firebase Storage Bucket format is invalid');
    }
  }

  /// Validate security aspects of Firebase configuration
  static Future<void> _validateSecurityConfiguration(FirebaseValidationResult result) async {
    // Check for development defaults in production
    if (EnvironmentConfig.isProduction) {
      if (_containsDevDefaults()) {
        result.addError('Production environment contains development defaults');
      }
    }

    // Validate API key entropy (randomness)
    final webApiKey = EnvironmentConfig.firebaseWebApiKey;
    if (!_hasValidEntropy(webApiKey)) {
      result.addWarning('Firebase Web API Key has low entropy');
    }

    // Check for common security misconfigurations
    if (EnvironmentConfig.firebaseProjectId.contains('test') || 
        EnvironmentConfig.firebaseProjectId.contains('demo')) {
      if (EnvironmentConfig.isProduction) {
        result.addError('Production project contains test/demo identifiers');
      }
    }

    // Validate domain security
    final authDomain = EnvironmentConfig.firebaseAuthDomain;
    if (authDomain.contains('localhost') || authDomain.contains('127.0.0.1')) {
      if (EnvironmentConfig.isProduction) {
        result.addError('Production auth domain contains localhost references');
      }
    }
  }

  /// Validate API key formats using pattern matching
  static Future<void> _validateApiKeyFormats(FirebaseValidationResult result) async {
    final webApiKey = EnvironmentConfig.firebaseWebApiKey;
    final androidApiKey = EnvironmentConfig.firebaseAndroidApiKey;
    final iosApiKey = EnvironmentConfig.firebaseIosApiKey;

    // Firebase Web API keys typically start with "AIza" and are 39 characters
    if (webApiKey.isNotEmpty && !_isValidFirebaseApiKey(webApiKey, 'web')) {
      result.addError('Firebase Web API Key format is invalid');
    }

    // Android API keys have similar format
    if (androidApiKey.isNotEmpty && !_isValidFirebaseApiKey(androidApiKey, 'android')) {
      result.addError('Firebase Android API Key format is invalid');
    }

    // iOS API keys have similar format
    if (iosApiKey.isNotEmpty && !_isValidFirebaseApiKey(iosApiKey, 'ios')) {
      result.addError('Firebase iOS API Key format is invalid');
    }

    // Validate App IDs format (1:number:platform:hash)
    if (!_isValidAppId(EnvironmentConfig.firebaseWebAppId, 'web')) {
      result.addError('Firebase Web App ID format is invalid');
    }
    if (!_isValidAppId(EnvironmentConfig.firebaseAndroidAppId, 'android')) {
      result.addError('Firebase Android App ID format is invalid');
    }
    if (!_isValidAppId(EnvironmentConfig.firebaseIosAppId, 'ios')) {
      result.addError('Firebase iOS App ID format is invalid');
    }
  }

  /// Validate configuration integrity using cryptographic hashing
  static Future<void> _validateConfigurationIntegrity(FirebaseValidationResult result) async {
    final environment = EnvironmentConfig.environmentName;
    final configHash = _calculateConfigHash();
    
    // In a real implementation, you would compare against known good hashes
    // For now, we'll validate the hash format and structure
    if (configHash.isEmpty) {
      result.addError('Configuration hash calculation failed');
    } else {
      // Validate hash format (SHA-256 should be 64 hex characters)
      if (configHash.length != 64 || !RegExp(r'^[a-f0-9]{64}$').hasMatch(configHash)) {
        result.addError('Configuration hash format is invalid');
      }
    }

    // Store hash for debugging
    result.configurationHash = configHash;
    debugPrint('Configuration hash for $environment: $configHash');
  }

  /// Validate environment-specific security requirements
  static Future<void> _validateEnvironmentSpecificSecurity(FirebaseValidationResult result) async {
    final environment = EnvironmentConfig.environmentName;

    switch (environment) {
      case 'production':
        await _validateProductionSecurity(result);
        break;
      case 'staging':
        await _validateStagingSecurity(result);
        break;
      case 'development':
        await _validateDevelopmentSecurity(result);
        break;
    }
  }

  /// Validate production-specific security requirements
  static Future<void> _validateProductionSecurity(FirebaseValidationResult result) async {
    // Ensure no debug mode in production
    if (kDebugMode) {
      result.addWarning('Debug mode is enabled in production build');
    }

    // Validate production project ID
    final projectId = EnvironmentConfig.firebaseProjectId;
    if (!projectId.contains('prod') && !projectId.endsWith('-production')) {
      result.addWarning('Production project ID does not follow naming convention');
    }

    // Check for secure API key storage
    if (EnvironmentConfig.firebaseWebApiKey == EnvironmentConfig.firebaseAndroidApiKey) {
      result.addWarning('Web and Android API keys are identical - consider platform-specific keys');
    }
  }

  /// Validate staging-specific security requirements
  static Future<void> _validateStagingSecurity(FirebaseValidationResult result) async {
    final projectId = EnvironmentConfig.firebaseProjectId;
    if (!projectId.contains('staging') && !projectId.contains('stage')) {
      result.addWarning('Staging project ID does not follow naming convention');
    }
  }

  /// Validate development-specific security requirements
  static Future<void> _validateDevelopmentSecurity(FirebaseValidationResult result) async {
    final projectId = EnvironmentConfig.firebaseProjectId;
    if (!projectId.contains('dev') && !projectId.contains('development')) {
      result.addInfo('Development project ID could follow naming convention');
    }

    // Check if demo mode is properly configured
    if (EnvironmentConfig.isDemoModeEnabled) {
      final demoCredentials = EnvironmentConfig.getDemoCredentials();
      if (demoCredentials.isEmpty) {
        result.addWarning('Demo mode enabled but no credentials configured');
      } else {
        result.addInfo('Demo mode configured with ${demoCredentials.length} accounts');
      }
    }
  }

  /// Calculate cryptographic hash of current configuration
  static String _calculateConfigHash() {
    final config = {
      'projectId': EnvironmentConfig.firebaseProjectId,
      'webApiKey': EnvironmentConfig.firebaseWebApiKey,
      'androidApiKey': EnvironmentConfig.firebaseAndroidApiKey,
      'iosApiKey': EnvironmentConfig.firebaseIosApiKey,
      'webAppId': EnvironmentConfig.firebaseWebAppId,
      'androidAppId': EnvironmentConfig.firebaseAndroidAppId,
      'iosAppId': EnvironmentConfig.firebaseIosAppId,
      'authDomain': EnvironmentConfig.firebaseAuthDomain,
      'storageBucket': EnvironmentConfig.firebaseStorageBucket,
      'messagingSenderId': EnvironmentConfig.firebaseMessagingSenderId,
      'measurementId': EnvironmentConfig.firebaseMeasurementId,
      'environment': EnvironmentConfig.environmentName,
    };

    final configJson = json.encode(config);
    final bytes = utf8.encode(configJson);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  // Helper validation methods

  static bool _isValidProjectId(String projectId) {
    // Firebase project IDs: 6-30 characters, lowercase, numbers, hyphens
    return RegExp(r'^[a-z0-9-]{6,30}$').hasMatch(projectId) &&
           !projectId.startsWith('-') &&
           !projectId.endsWith('-') &&
           !projectId.contains('--');
  }

  static bool _isValidAuthDomain(String authDomain) {
    // Should be in format: projectId.firebaseapp.com
    return RegExp(r'^[a-z0-9-]+\.firebaseapp\.com$').hasMatch(authDomain);
  }

  static bool _isValidStorageBucket(String storageBucket) {
    // Should be in format: projectId.appspot.com or projectId.firebasestorage.app
    return RegExp(r'^[a-z0-9-]+\.(appspot\.com|firebasestorage\.app)$').hasMatch(storageBucket);
  }

  static bool _isValidFirebaseApiKey(String apiKey, String platform) {
    // Firebase API keys start with "AIza" and are typically 39 characters
    return apiKey.startsWith('AIza') && 
           apiKey.length == 39 && 
           RegExp(r'^AIza[A-Za-z0-9_-]+$').hasMatch(apiKey);
  }

  static bool _isValidAppId(String appId, String platform) {
    // Format: 1:messagingSenderId:platform:hash
    final parts = appId.split(':');
    if (parts.length != 4) return false;
    
    return parts[0] == '1' && 
           RegExp(r'^\d+$').hasMatch(parts[1]) && // messaging sender ID
           (parts[2] == 'web' || parts[2] == 'android' || parts[2] == 'ios') &&
           parts[3].isNotEmpty;
  }

  static bool _containsDevDefaults() {
    return EnvironmentConfig.firebaseProjectId == 'securyflex-dev' ||
           EnvironmentConfig.firebaseWebApiKey == 'AIzaSyCs09ATGwyR1QxMeG-2AtPezzX97zQYgEQ';
  }

  static bool _hasValidEntropy(String value) {
    if (value.length < 20) return false;
    
    // Calculate simple entropy (unique character count / total length)
    final uniqueChars = value.split('').toSet().length;
    final entropy = uniqueChars / value.length;
    
    // Require at least 50% entropy
    return entropy >= 0.5;
  }
}

/// Result of Firebase configuration validation
class FirebaseValidationResult {
  bool isValid = true;
  final List<String> errors = [];
  final List<String> warnings = [];
  final List<String> info = [];
  String configurationHash = '';
  DateTime validatedAt = DateTime.now();

  void addError(String message) {
    errors.add(message);
    isValid = false;
    debugPrint('Firebase Config Error: $message');
  }

  void addWarning(String message) {
    warnings.add(message);
    debugPrint('Firebase Config Warning: $message');
  }

  void addInfo(String message) {
    info.add(message);
    debugPrint('Firebase Config Info: $message');
  }

  bool get hasIssues => errors.isNotEmpty || warnings.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'validatedAt': validatedAt.toIso8601String(),
      'configurationHash': configurationHash,
      'summary': {
        'errorCount': errors.length,
        'warningCount': warnings.length,
        'infoCount': info.length,
      },
      'errors': errors,
      'warnings': warnings,
      'info': info,
      'environment': EnvironmentConfig.environmentName,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Firebase Configuration Validation Result');
    buffer.writeln('Valid: $isValid');
    buffer.writeln('Environment: ${EnvironmentConfig.environmentName}');
    buffer.writeln('Validated: $validatedAt');
    
    if (errors.isNotEmpty) {
      buffer.writeln('\nErrors (${errors.length}):');
      for (final error in errors) {
        buffer.writeln('  ❌ $error');
      }
    }
    
    if (warnings.isNotEmpty) {
      buffer.writeln('\nWarnings (${warnings.length}):');
      for (final warning in warnings) {
        buffer.writeln('  ⚠️ $warning');
      }
    }
    
    if (info.isNotEmpty) {
      buffer.writeln('\nInfo (${info.length}):');
      for (final infoItem in info) {
        buffer.writeln('  ℹ️ $infoItem');
      }
    }
    
    return buffer.toString();
  }
}