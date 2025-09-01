import 'package:flutter/foundation.dart';
import '../config/firebase_config_validator.dart';
import '../config/environment_config.dart';

/// Firebase Security Service
/// 
/// Manages Firebase security validation, monitoring, and compliance
/// checks throughout the application lifecycle.
class FirebaseSecurityService {
  static final FirebaseSecurityService _instance = FirebaseSecurityService._internal();
  factory FirebaseSecurityService() => _instance;
  FirebaseSecurityService._internal();

  FirebaseValidationResult? _lastValidationResult;
  DateTime? _lastValidationTime;
  
  /// Initialize Firebase security validation
  /// Should be called during app startup
  static Future<void> initialize() async {
    final instance = FirebaseSecurityService();
    await instance._performInitialValidation();
  }

  /// Perform comprehensive Firebase configuration validation
  Future<FirebaseValidationResult> validateConfiguration() async {
    debugPrint('FirebaseSecurityService: Starting configuration validation...');
    
    final result = await FirebaseConfigValidator.validateConfiguration();
    
    _lastValidationResult = result;
    _lastValidationTime = DateTime.now();
    
    // Log validation results
    if (result.isValid) {
      debugPrint('✅ Firebase configuration is valid');
      if (result.warnings.isNotEmpty) {
        debugPrint('⚠️ ${result.warnings.length} warnings found');
      }
    } else {
      debugPrint('❌ Firebase configuration validation failed');
      debugPrint('Errors: ${result.errors.length}');
      debugPrint('Warnings: ${result.warnings.length}');
    }
    
    // In development, print detailed results
    if (kDebugMode && result.hasIssues) {
      debugPrint('\n=== Firebase Configuration Issues ===');
      debugPrint(result.toString());
      debugPrint('======================================\n');
    }
    
    return result;
  }

  /// Get the last validation result
  FirebaseValidationResult? get lastValidationResult => _lastValidationResult;

  /// Check if validation is current (less than 1 hour old)
  bool get isValidationCurrent {
    if (_lastValidationTime == null) return false;
    final age = DateTime.now().difference(_lastValidationTime!);
    return age.inHours < 1;
  }

  /// Perform periodic validation check
  Future<void> performPeriodicCheck() async {
    if (!isValidationCurrent) {
      await validateConfiguration();
    }
  }

  /// Get security status summary
  Map<String, dynamic> getSecurityStatus() {
    final result = _lastValidationResult;
    if (result == null) {
      return {
        'status': 'unknown',
        'message': 'No validation performed',
        'lastValidation': null,
      };
    }

    return {
      'status': result.isValid ? 'valid' : 'invalid',
      'message': result.isValid 
          ? 'Firebase configuration is secure'
          : 'Firebase configuration has issues',
      'lastValidation': _lastValidationTime?.toIso8601String(),
      'errorCount': result.errors.length,
      'warningCount': result.warnings.length,
      'configurationHash': result.configurationHash,
      'environment': EnvironmentConfig.environmentName,
    };
  }

  /// Check if Firebase is properly secured for production
  bool get isProductionReady {
    if (!EnvironmentConfig.isProduction) return true;
    
    final result = _lastValidationResult;
    return result != null && result.isValid && result.errors.isEmpty;
  }

  /// Get configuration security recommendations
  List<String> getSecurityRecommendations() {
    final recommendations = <String>[];
    final result = _lastValidationResult;
    
    if (result == null) {
      recommendations.add('Run Firebase configuration validation');
      return recommendations;
    }

    // Based on validation results, provide recommendations
    if (result.errors.isNotEmpty) {
      recommendations.add('Fix all configuration errors before production deployment');
    }

    if (result.warnings.isNotEmpty) {
      recommendations.add('Review and address configuration warnings');
    }

    if (EnvironmentConfig.isProduction) {
      if (EnvironmentConfig.firebaseWebApiKey == EnvironmentConfig.firebaseAndroidApiKey) {
        recommendations.add('Use platform-specific API keys for better security');
      }

      if (kDebugMode) {
        recommendations.add('Ensure debug mode is disabled in production builds');
      }
    }

    // General security recommendations
    recommendations.addAll([
      'Regularly rotate Firebase API keys',
      'Monitor Firebase usage for unusual activity',
      'Enable Firebase App Check for enhanced security',
      'Use Firebase Security Rules to restrict data access',
      'Implement proper Firebase Auth security rules',
    ]);

    return recommendations;
  }

  /// Generate security report
  Map<String, dynamic> generateSecurityReport() {
    final result = _lastValidationResult;
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'environment': EnvironmentConfig.environmentName,
      'validation': result?.toJson() ?? {'status': 'not_performed'},
      'security_status': getSecurityStatus(),
      'production_ready': isProductionReady,
      'recommendations': getSecurityRecommendations(),
      'configuration_summary': EnvironmentConfig.getConfigurationSummary(),
    };
  }

  /// Initial validation during app startup
  Future<void> _performInitialValidation() async {
    try {
      // Validate configuration
      final result = await validateConfiguration();
      
      // In production, fail fast if configuration is invalid
      if (EnvironmentConfig.isProduction && !result.isValid) {
        throw Exception('Invalid Firebase configuration in production environment');
      }

      // Log security status
      final status = getSecurityStatus();
      debugPrint('Firebase Security Status: ${status['status']}');
      
      // Print recommendations in development
      if (kDebugMode) {
        final recommendations = getSecurityRecommendations();
        if (recommendations.isNotEmpty) {
          debugPrint('\n=== Firebase Security Recommendations ===');
          for (int i = 0; i < recommendations.length; i++) {
            debugPrint('${i + 1}. ${recommendations[i]}');
          }
          debugPrint('==========================================\n');
        }
      }

    } catch (e) {
      debugPrint('FirebaseSecurityService: Initialization failed: $e');
      if (EnvironmentConfig.isProduction) {
        rethrow; // Fail fast in production
      }
    }
  }

  /// Validate specific Firebase service security
  Future<bool> validateServiceSecurity(String serviceName) async {
    switch (serviceName.toLowerCase()) {
      case 'auth':
        return await _validateAuthSecurity();
      case 'firestore':
        return await _validateFirestoreSecurity();
      case 'storage':
        return await _validateStorageSecurity();
      case 'functions':
        return await _validateFunctionsSecurity();
      default:
        debugPrint('Unknown Firebase service: $serviceName');
        return false;
    }
  }

  /// Validate Firebase Auth security configuration
  Future<bool> _validateAuthSecurity() async {
    // Check auth domain configuration
    final authDomain = EnvironmentConfig.firebaseAuthDomain;
    if (authDomain.isEmpty) return false;
    
    // Validate domain format
    if (!RegExp(r'^[a-z0-9-]+\.firebaseapp\.com$').hasMatch(authDomain)) {
      debugPrint('Invalid Firebase Auth domain format');
      return false;
    }
    
    return true;
  }

  /// Validate Firestore security configuration
  Future<bool> _validateFirestoreSecurity() async {
    final projectId = EnvironmentConfig.firebaseProjectId;
    if (projectId.isEmpty) return false;
    
    // Additional Firestore-specific validation could be added here
    // Such as checking security rules, indexes, etc.
    
    return true;
  }

  /// Validate Firebase Storage security configuration
  Future<bool> _validateStorageSecurity() async {
    final storageBucket = EnvironmentConfig.firebaseStorageBucket;
    if (storageBucket.isEmpty) return false;
    
    // Validate storage bucket format
    if (!RegExp(r'^[a-z0-9-]+\.(appspot\.com|firebasestorage\.app)$').hasMatch(storageBucket)) {
      debugPrint('Invalid Firebase Storage bucket format');
      return false;
    }
    
    return true;
  }

  /// Validate Firebase Functions security configuration
  Future<bool> _validateFunctionsSecurity() async {
    final projectId = EnvironmentConfig.firebaseProjectId;
    if (projectId.isEmpty) return false;
    
    // Additional Functions-specific validation could be added here
    // Such as checking HTTPS requirements, CORS settings, etc.
    
    return true;
  }
}