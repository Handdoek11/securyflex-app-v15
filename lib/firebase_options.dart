// SECURITY: Updated to use environment-based configuration
// No hardcoded API keys - all values loaded from secure environment variables
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'config/environment_config.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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