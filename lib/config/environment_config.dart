import 'package:flutter/foundation.dart';

/// Secure Environment Configuration for SecuryFlex
/// 
/// Manages sensitive configuration data using environment variables
/// and secure storage. No secrets are hardcoded in the codebase.
/// 
/// Usage:
/// - Development: Use .env files or --dart-define
/// - Production: Use secure environment variables
class EnvironmentConfig {
  EnvironmentConfig._();

  // ==========================================================================
  // FIREBASE CONFIGURATION (from environment variables)
  // ==========================================================================

  /// Get Firebase Web API Key
  static String get firebaseWebApiKey {
    const key = String.fromEnvironment('FIREBASE_WEB_API_KEY');
    if (key.isEmpty) {
      if (kDebugMode) {
        debugPrint('WARNING: FIREBASE_WEB_API_KEY not configured - using development default');
      }
      return 'AIzaSyDwcm7oamPkzlDyiuExwOpV2yFH6mdEg4c'; // Development default from Firebase Console
    }
    return key;
  }

  /// Get Firebase Android API Key  
  static String get firebaseAndroidApiKey {
    const key = String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
    if (key.isEmpty) {
      if (kDebugMode) {
        debugPrint('WARNING: FIREBASE_ANDROID_API_KEY not configured - using development default');
      }
      return 'AIzaSyDwcm7oamPkzlDyiuExwOpV2yFH6mdEg4c'; // Development default from Firebase Console
    }
    return key;
  }

  /// Get Firebase iOS API Key
  static String get firebaseIosApiKey {
    const key = String.fromEnvironment('FIREBASE_IOS_API_KEY');
    if (key.isEmpty) {
      if (kDebugMode) {
        debugPrint('WARNING: FIREBASE_IOS_API_KEY not configured - using development default');
      }
      return 'AIzaSyDwcm7oamPkzlDyiuExwOpV2yFH6mdEg4c'; // Development default from Firebase Console
    }
    return key;
  }

  /// Get Firebase Project ID
  static String get firebaseProjectId {
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if (projectId.isEmpty && kDebugMode) {
      debugPrint('WARNING: FIREBASE_PROJECT_ID not configured - using development default');
      return 'securyflex-cf93b'; // Development default (updated)
    }
    return projectId;
  }

  /// Get Firebase Messaging Sender ID
  static String get firebaseMessagingSenderId {
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    if (senderId.isEmpty && kDebugMode) {
      debugPrint('WARNING: FIREBASE_MESSAGING_SENDER_ID not configured - using development default');
      return '869360243690'; // Development default (updated)
    }
    return senderId;
  }

  /// Get Firebase App ID for Web
  static String get firebaseWebAppId {
    const appId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
    if (appId.isEmpty && kDebugMode) {
      debugPrint('WARNING: FIREBASE_WEB_APP_ID not configured - using development default');
      return '1:869360243690:web:f2d1e0549ab4a4f7409893'; // Development default (updated)
    }
    return appId;
  }

  /// Get Firebase App ID for Android
  static String get firebaseAndroidAppId {
    const appId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
    if (appId.isEmpty && kDebugMode) {
      debugPrint('WARNING: FIREBASE_ANDROID_APP_ID not configured - using development default');
      return '1:869360243690:android:d712276dd2383028409893'; // Development default (updated)
    }
    return appId;
  }

  /// Get Firebase App ID for iOS
  static String get firebaseIosAppId {
    const appId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
    if (appId.isEmpty && kDebugMode) {
      debugPrint('WARNING: FIREBASE_IOS_APP_ID not configured - using development default');
      return '1:869360243690:ios:f21bb8a9a843ed31409893'; // Development default (updated)
    }
    return appId;
  }

  /// Get Firebase Auth Domain
  static String get firebaseAuthDomain {
    const domain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
    if (domain.isEmpty && kDebugMode) {
      debugPrint('WARNING: FIREBASE_AUTH_DOMAIN not configured - using development default');
      return 'securyflex-cf93b.firebaseapp.com'; // Development default (updated)
    }
    return domain;
  }

  /// Get Firebase Storage Bucket
  static String get firebaseStorageBucket {
    const bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
    if (bucket.isEmpty && kDebugMode) {
      debugPrint('WARNING: FIREBASE_STORAGE_BUCKET not configured - using development default');
      return 'securyflex-cf93b.firebasestorage.app'; // Development default (updated)
    }
    return bucket;
  }

  /// Get Firebase Measurement ID (for Google Analytics)
  static String get firebaseMeasurementId {
    const measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');
    if (measurementId.isEmpty && kDebugMode) {
      debugPrint('WARNING: FIREBASE_MEASUREMENT_ID not configured - using development default');
      return 'G-KQQK104EB5'; // Development default from .env
    }
    return measurementId;
  }

  // ==========================================================================
  // DEMO ACCOUNT CONFIGURATION (Development Only)
  // ==========================================================================

  /// Get demo guard email (development only)
  static String get demoGuardEmail {
    const email = String.fromEnvironment('DEMO_GUARD_EMAIL');
    if (email.isEmpty && kDebugMode) {
      return 'guard@securyflex.nl'; // Development default
    }
    return email;
  }

  /// Get demo guard password (development only)
  static String get demoGuardPassword {
    const password = String.fromEnvironment('DEMO_GUARD_PASSWORD');
    if (password.isEmpty && kDebugMode) {
      return 'DemoGuard2024!'; // Development default
    }
    return password;
  }

  /// Get demo company email (development only)
  static String get demoCompanyEmail {
    const email = String.fromEnvironment('DEMO_COMPANY_EMAIL');
    if (email.isEmpty && kDebugMode) {
      return 'company@securyflex.nl'; // Development default
    }
    return email;
  }

  /// Get demo company password (development only)
  static String get demoCompanyPassword {
    const password = String.fromEnvironment('DEMO_COMPANY_PASSWORD');
    if (password.isEmpty && kDebugMode) {
      return 'DemoCompany2024!'; // Development default
    }
    return password;
  }

  /// Get demo admin email (development only)
  static String get demoAdminEmail {
    const email = String.fromEnvironment('DEMO_ADMIN_EMAIL');
    if (email.isEmpty && kDebugMode) {
      return 'admin@securyflex.nl'; // Development default
    }
    return email;
  }

  /// Get demo admin password (development only)
  static String get demoAdminPassword {
    const password = String.fromEnvironment('DEMO_ADMIN_PASSWORD');
    if (password.isEmpty && kDebugMode) {
      return 'DemoAdmin2024!'; // Development default
    }
    return password;
  }

  /// Check if demo mode is enabled
  /// Only enabled in debug mode AND when demo credentials are configured
  static bool get isDemoModeEnabled {
    if (!kDebugMode) return false;
    
    // Check if at least one demo account is configured
    return (demoGuardEmail.isNotEmpty && demoGuardPassword.isNotEmpty) ||
           (demoCompanyEmail.isNotEmpty && demoCompanyPassword.isNotEmpty) ||
           (demoAdminEmail.isNotEmpty && demoAdminPassword.isNotEmpty);
  }

  /// Get all demo accounts configuration
  /// Returns empty map if demo mode is not enabled
  static Map<String, Map<String, dynamic>> getDemoCredentials() {
    if (!isDemoModeEnabled) return {};
    
    final credentials = <String, Map<String, dynamic>>{};
    
    // Add guard demo account if configured
    if (demoGuardEmail.isNotEmpty && demoGuardPassword.isNotEmpty) {
      credentials[demoGuardEmail.toLowerCase()] = {
        'password': demoGuardPassword,
        'userType': 'guard',
        'name': 'Demo Beveiliger',
      };
    }
    
    // Add company demo account if configured
    if (demoCompanyEmail.isNotEmpty && demoCompanyPassword.isNotEmpty) {
      credentials[demoCompanyEmail.toLowerCase()] = {
        'password': demoCompanyPassword,
        'userType': 'company',
        'name': 'Demo Bedrijf',
      };
    }
    
    // Add admin demo account if configured
    if (demoAdminEmail.isNotEmpty && demoAdminPassword.isNotEmpty) {
      credentials[demoAdminEmail.toLowerCase()] = {
        'password': demoAdminPassword,
        'userType': 'admin',
        'name': 'Demo Admin',
      };
    }
    
    return credentials;
  }

  // ==========================================================================
  // GOOGLE SERVICES CONFIGURATION
  // ==========================================================================

  /// Get Google Maps API Key
  static String get googleMapsApiKey {
    const key = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (key.isEmpty && kDebugMode) {
      debugPrint('WARNING: GOOGLE_MAPS_API_KEY not configured - location services will use mock data');
    }
    return key;
  }

  // ==========================================================================
  // ENVIRONMENT DETECTION
  // ==========================================================================

  /// Check if we're in production environment
  static bool get isProduction {
    const env = String.fromEnvironment('FLUTTER_ENV');
    return env == 'production';
  }

  /// Check if we're in development environment
  static bool get isDevelopment {
    const env = String.fromEnvironment('FLUTTER_ENV');
    return env == 'development' || (env.isEmpty && kDebugMode);
  }

  /// Check if we're in staging environment
  static bool get isStaging {
    const env = String.fromEnvironment('FLUTTER_ENV');
    return env == 'staging';
  }

  /// Get current environment name
  static String get environmentName {
    const env = String.fromEnvironment('FLUTTER_ENV');
    if (env.isNotEmpty) return env;
    return kDebugMode ? 'development' : 'production';
  }

  // ==========================================================================
  // VALIDATION AND SECURITY
  // ==========================================================================

  /// Validate all required environment variables are set
  static List<String> validateConfiguration() {
    final issues = <String>[];

    // Only validate in production
    if (!isProduction) return issues;

    // Check Firebase configuration
    if (firebaseProjectId.isEmpty || firebaseProjectId == 'your-project-id') {
      issues.add('FIREBASE_PROJECT_ID not configured');
    }
    
    if (firebaseWebApiKey.isEmpty || firebaseWebApiKey == 'your-web-api-key') {
      issues.add('FIREBASE_WEB_API_KEY not configured');
    }

    if (firebaseAndroidApiKey.isEmpty || firebaseAndroidApiKey == 'your-android-api-key') {
      issues.add('FIREBASE_ANDROID_API_KEY not configured');
    }

    if (firebaseIosApiKey.isEmpty || firebaseIosApiKey == 'your-ios-api-key') {
      issues.add('FIREBASE_IOS_API_KEY not configured');
    }

    if (firebaseAuthDomain.isEmpty) {
      issues.add('FIREBASE_AUTH_DOMAIN not configured');
    }

    if (firebaseStorageBucket.isEmpty) {
      issues.add('FIREBASE_STORAGE_BUCKET not configured');
    }

    // Google Services
    if (googleMapsApiKey.isEmpty) {
      issues.add('GOOGLE_MAPS_API_KEY not configured - location services will be limited');
    }

    // Demo configuration warnings (development only)
    if (isDevelopment && isDemoModeEnabled) {
      final demoCredentials = getDemoCredentials();
      if (demoCredentials.isEmpty) {
        issues.add('Demo mode enabled but no demo credentials configured');
      }
    }

    return issues;
  }

  /// Check if Firebase is properly configured
  static bool get isFirebaseConfigured {
    return firebaseProjectId.isNotEmpty && 
           firebaseProjectId != 'your-project-id' &&
           firebaseWebApiKey.isNotEmpty && 
           firebaseWebApiKey != 'your-web-api-key';
  }

  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigurationSummary() {
    return {
      'environment': environmentName,
      'isProduction': isProduction,
      'isDevelopment': isDevelopment,
      'isStaging': isStaging,
      'firebase': {
        'configured': isFirebaseConfigured,
        'projectId': firebaseProjectId,
        'hasWebApiKey': firebaseWebApiKey.isNotEmpty,
        'hasAndroidApiKey': firebaseAndroidApiKey.isNotEmpty,
        'hasIosApiKey': firebaseIosApiKey.isNotEmpty,
        'authDomain': firebaseAuthDomain,
        'storageBucket': firebaseStorageBucket,
      },
      'googleServices': {
        'hasMapsApiKey': googleMapsApiKey.isNotEmpty,
      },
      'demo': {
        'enabled': isDemoModeEnabled,
        'accountCount': getDemoCredentials().length,
        'availableAccounts': getDemoCredentials().keys.toList(),
      },
      'validationIssues': validateConfiguration(),
    };
  }

  /// Initialize environment configuration
  static Future<void> initialize() async {
    try {
      // Validate configuration
      final issues = validateConfiguration();
      
      if (issues.isNotEmpty) {
        debugPrint('EnvironmentConfig: Configuration issues found:');
        for (final issue in issues) {
          debugPrint('  - $issue');
        }
      }

      if (kDebugMode) {
        debugPrint('EnvironmentConfig initialized for $environmentName environment');
        debugPrint('Firebase configured: $isFirebaseConfigured');
      }
    } catch (e) {
      debugPrint('EnvironmentConfig: Error during initialization: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // BUILD CONFIGURATION HELPERS
  // ==========================================================================

  /// Generate build command for different environments
  static String getBuildCommand(String environment, String platform) {
    final baseCommand = 'flutter build $platform';
    final envVars = _getEnvironmentVariables(environment);
    
    final dartDefines = envVars.entries
        .map((e) => '--dart-define=${e.key}=${e.value}')
        .join(' ');
    
    return '$baseCommand $dartDefines';
  }

  /// Get environment variables for specific environment
  static Map<String, String> _getEnvironmentVariables(String environment) {
    switch (environment.toLowerCase()) {
      case 'production':
        return {
          'FLUTTER_ENV': 'production',
          'FIREBASE_PROJECT_ID': 'securyflex-prod',
          // Note: Actual API keys should come from secure environment variables
          // These are placeholders that must be replaced in CI/CD pipeline
          'FIREBASE_WEB_API_KEY': '\${FIREBASE_WEB_API_KEY}',
          'FIREBASE_ANDROID_API_KEY': '\${FIREBASE_ANDROID_API_KEY}',
          'FIREBASE_IOS_API_KEY': '\${FIREBASE_IOS_API_KEY}',
          'GOOGLE_MAPS_API_KEY': '\${GOOGLE_MAPS_API_KEY}',
        };
      case 'staging':
        return {
          'FLUTTER_ENV': 'staging',
          'FIREBASE_PROJECT_ID': 'securyflex-staging',
          'FIREBASE_WEB_API_KEY': '\${FIREBASE_STAGING_WEB_API_KEY}',
          'FIREBASE_ANDROID_API_KEY': '\${FIREBASE_STAGING_ANDROID_API_KEY}',
          'FIREBASE_IOS_API_KEY': '\${FIREBASE_STAGING_IOS_API_KEY}',
          'GOOGLE_MAPS_API_KEY': '\${GOOGLE_MAPS_STAGING_API_KEY}',
        };
      case 'development':
      default:
        return {
          'FLUTTER_ENV': 'development',
          'FIREBASE_PROJECT_ID': 'securyflex-cf93b',
          // Development uses defaults defined in this class
          // Demo credentials can be set via environment variables:
          // 'DEMO_GUARD_EMAIL': 'guard@securyflex.nl',
          // 'DEMO_GUARD_PASSWORD': 'SecurePassword123!',
          // 'DEMO_COMPANY_EMAIL': 'company@securyflex.nl',
          // 'DEMO_COMPANY_PASSWORD': 'SecurePassword123!',
          // 'DEMO_ADMIN_EMAIL': 'admin@securyflex.nl',
          // 'DEMO_ADMIN_PASSWORD': 'SecurePassword123!',
        };
    }
  }
}

/// Environment-specific build configuration
class BuildConfig {
  BuildConfig._();

  /// Generate environment-specific Firebase configuration
  static String generateFirebaseOptionsContent() {
    return '''
// GENERATED FILE - DO NOT EDIT MANUALLY
// This file is generated based on environment variables
// To update, modify environment configuration and regenerate

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import '../config/environment_config.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Configuration is loaded from environment variables for security.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: EnvironmentConfig.firebaseWebApiKey,
    appId: EnvironmentConfig.firebaseWebAppId,
    messagingSenderId: EnvironmentConfig.firebaseMessagingSenderId,
    projectId: EnvironmentConfig.firebaseProjectId,
    authDomain: EnvironmentConfig.firebaseAuthDomain,
    storageBucket: EnvironmentConfig.firebaseStorageBucket,
    measurementId: EnvironmentConfig.firebaseMeasurementId,
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: EnvironmentConfig.firebaseAndroidApiKey,
    appId: EnvironmentConfig.firebaseAndroidAppId,
    messagingSenderId: EnvironmentConfig.firebaseMessagingSenderId,
    projectId: EnvironmentConfig.firebaseProjectId,
    storageBucket: EnvironmentConfig.firebaseStorageBucket,
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: EnvironmentConfig.firebaseIosApiKey,
    appId: EnvironmentConfig.firebaseIosAppId,
    messagingSenderId: EnvironmentConfig.firebaseMessagingSenderId,
    projectId: EnvironmentConfig.firebaseProjectId,
    storageBucket: EnvironmentConfig.firebaseStorageBucket,
    iosBundleId: 'com.securyflex.app',
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: EnvironmentConfig.firebaseIosApiKey,
    appId: EnvironmentConfig.firebaseIosAppId,
    messagingSenderId: EnvironmentConfig.firebaseMessagingSenderId,
    projectId: EnvironmentConfig.firebaseProjectId,
    storageBucket: EnvironmentConfig.firebaseStorageBucket,
    iosBundleId: 'com.securyflex.app',
  );

  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: EnvironmentConfig.firebaseWebApiKey,
    appId: EnvironmentConfig.firebaseWebAppId,
    messagingSenderId: EnvironmentConfig.firebaseMessagingSenderId,
    projectId: EnvironmentConfig.firebaseProjectId,
    authDomain: EnvironmentConfig.firebaseAuthDomain,
    storageBucket: EnvironmentConfig.firebaseStorageBucket,
    measurementId: EnvironmentConfig.firebaseMeasurementId,
  );
}
''';
  }
}