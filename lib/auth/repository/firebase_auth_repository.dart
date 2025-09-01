import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_repository.dart';

/// Firebase implementation of AuthRepository
/// Handles all Firebase Auth and Firestore operations for SecuryFlex
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  
  // Production-only authentication - no demo credentials
  
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase login failed: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  @override
  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase registration failed: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        throw Exception('User document not found');
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update(data);
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  @override
  Future<void> createUserDocument(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(userData);
    } catch (e) {
      debugPrint('Error creating user document: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'lastLoginAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Last login update error: $e');
      // Don't rethrow as this is not critical
    }
  }

  @override
  bool isFirebaseConfigured() {
    try {
      final app = _firebaseAuth.app;
      return app.options.apiKey != 'your-web-api-key' &&
             app.options.projectId != 'your-project-id' &&
             app.options.apiKey.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Demo credentials removed for production

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  @override
  String getUserRoleDisplayName(String userType) {
    switch (userType.toLowerCase()) {
      case 'guard':
        return 'Beveiliger';
      case 'company':
        return 'Bedrijf';
      case 'admin':
        return 'Beheerder';
      default:
        return 'Gebruiker';
    }
  }

  @override
  String getFirebaseStatus() {
    if (isFirebaseConfigured()) {
      return 'Firebase is configured and ready';
    } else {
      return 'Running in demo mode - Firebase not configured';
    }
  }

  // Demo methods removed for production
}
