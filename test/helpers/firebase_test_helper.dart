import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase Test Helper for SecuryFlex
/// Provides Firebase initialization and mocking for test environment
class FirebaseTestHelper {
  static bool _isInitialized = false;
  
  /// Initialize Firebase for testing environment
  /// This prevents "No Firebase App created" errors in tests
  /// Note: For unit tests, we don't actually initialize Firebase but set up the environment
  static Future<void> initializeFirebaseForTesting() async {
    if (_isInitialized) return;

    try {
      // Ensure Flutter binding is initialized first
      TestWidgetsFlutterBinding.ensureInitialized();

      // For unit tests, we don't actually initialize Firebase
      // Instead, we rely on the services' demo mode fallbacks
      // This prevents platform channel errors in test environment

      _isInitialized = true;
      debugPrint('✅ Firebase test environment prepared (demo mode)');
    } catch (e) {
      debugPrint('❌ Firebase test setup failed: $e');
      // Don't rethrow - let tests continue with demo mode
      _isInitialized = true;
    }
  }
  
  /// Setup Firebase for test group
  /// Call this in setUpAll() for each test group
  static Future<void> setupTestGroup() async {
    await initializeFirebaseForTesting();
  }
  
  /// Cleanup Firebase after tests
  /// Call this in tearDownAll() if needed
  static Future<void> cleanupTestGroup() async {
    // Currently no cleanup needed
    // Firebase test instance will be cleaned up automatically
  }
  
  /// Check if Firebase is properly initialized for testing
  static bool get isInitialized => _isInitialized;
  
  /// Reset initialization state (for testing the helper itself)
  @visibleForTesting
  static void resetInitializationState() {
    _isInitialized = false;
  }
}

/// Test configuration constants
class FirebaseTestConfig {
  static const String testProjectId = 'securyflex-test';
  static const String testApiKey = 'test-api-key-securyflex';
  static const String testAppId = 'test-app-id-securyflex';
  static const String testSenderId = 'test-sender-id-securyflex';
  static const String testAuthDomain = 'securyflex-test.firebaseapp.com';
  static const String testStorageBucket = 'securyflex-test.firebasestorage.app';
  
  /// Demo user credentials for testing
  static const Map<String, Map<String, String>> testCredentials = {
    'guard@test.nl': {
      'password': 'test123',
      'name': 'Test Guard',
      'userType': 'guard',
    },
    'company@test.nl': {
      'password': 'test123',
      'name': 'Test Company',
      'userType': 'company',
    },
    'admin@test.nl': {
      'password': 'test123',
      'name': 'Test Admin',
      'userType': 'admin',
    },
  };
}

/// Mixin for tests that need Firebase
/// Use this to automatically setup Firebase in test classes
mixin FirebaseTestMixin {
  @mustCallSuper
  void setUpFirebase() {
    setUpAll(() async {
      await FirebaseTestHelper.setupTestGroup();
    });
  }
}

/// Test utilities for Firebase-related testing
class FirebaseTestUtils {
  /// Wait for Firebase operations to complete
  static Future<void> waitForFirebaseOperation({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  /// Simulate network delay for realistic testing
  static Future<void> simulateNetworkDelay({
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    await Future.delayed(delay);
  }
  
  /// Create test user data
  static Map<String, dynamic> createTestUserData({
    required String email,
    required String name,
    required String userType,
    bool isDemo = true,
  }) {
    return {
      'email': email,
      'name': name,
      'userType': userType,
      'isDemo': isDemo,
      'createdAt': DateTime.now().toIso8601String(),
      'lastLoginAt': DateTime.now().toIso8601String(),
      'isActive': true,
      'emailVerified': true,
    };
  }
  
  /// Create test job data
  static Map<String, dynamic> createTestJobData({
    required String jobId,
    required String companyId,
    required String title,
    String status = 'active',
  }) {
    return {
      'jobId': jobId,
      'companyId': companyId,
      'title': title,
      'description': 'Test job description',
      'location': 'Test Location',
      'postalCode': '1234AB',
      'hourlyRate': 20.0,
      'status': status,
      'createdDate': DateTime.now().toIso8601String(),
      'applicationsCount': 0,
      'isUrgent': false,
    };
  }
  
  /// Create test application data
  static Map<String, dynamic> createTestApplicationData({
    required String applicationId,
    required String jobId,
    required String guardId,
    String status = 'pending',
  }) {
    return {
      'id': applicationId,
      'jobId': jobId,
      'guardId': guardId,
      'jobTitle': 'Test Job',
      'companyName': 'Test Company',
      'applicantName': 'Test Guard',
      'applicantEmail': 'guard@test.nl',
      'status': status,
      'applicationDate': DateTime.now().toIso8601String(),
      'motivationMessage': 'Test motivation',
      'contactPreference': 'email',
    };
  }
}
