import 'package:firebase_auth/firebase_auth.dart';

/// Abstract repository interface for authentication operations
/// Provides a clean separation between business logic and data sources
abstract class AuthRepository {
  /// Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password);
  
  /// Create user with email and password
  Future<User?> createUserWithEmailAndPassword(String email, String password);
  
  /// Sign out current user
  Future<void> signOut();
  
  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid);
  
  /// Update user data in Firestore
  Future<void> updateUserData(String uid, Map<String, dynamic> data);
  
  /// Create user document in Firestore
  Future<void> createUserDocument(String uid, Map<String, dynamic> userData);
  
  /// Update last login timestamp
  Future<void> updateLastLogin(String uid);
  
  /// Check if Firebase is properly configured
  bool isFirebaseConfigured();
  
  // Demo credentials removed for production
  
  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;
  
  /// Get current Firebase user
  User? get currentUser;
  
  /// Validate email format
  bool isValidEmail(String email);
  
  /// Validate password strength
  bool isValidPassword(String password);
  
  /// Get user role display name in Dutch
  String getUserRoleDisplayName(String userType);
  
  // Demo user creation removed for production
  
  /// Get Firebase configuration status
  String getFirebaseStatus();
}
