import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/environment_config.dart';

/// Password validation result with detailed feedback
class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;
  final int strength; // 0-100

  const PasswordValidationResult({
    required this.isValid,
    required this.errors,
    required this.strength,
  });

  /// Get strength description in Dutch
  String get strengthDescription {
    if (strength >= 80) return 'Zeer sterk';
    if (strength >= 60) return 'Sterk';
    if (strength >= 40) return 'Gemiddeld';
    if (strength >= 20) return 'Zwak';
    return 'Zeer zwak';
  }

  /// Get first error message or empty string
  String get firstError => errors.isNotEmpty ? errors.first : '';

  /// Get all errors as single string
  String get allErrors => errors.join('\n');
}

/// Authentication operation result
class AuthResult {
  final bool isSuccess;
  final String? errorCode;
  final String message;
  final Map<String, dynamic>? data;

  const AuthResult._({
    required this.isSuccess,
    this.errorCode,
    required this.message,
    this.data,
  });

  /// Create success result
  factory AuthResult.success(String message, {Map<String, dynamic>? data}) {
    return AuthResult._(
      isSuccess: true,
      message: message,
      data: data,
    );
  }

  /// Create error result
  factory AuthResult.error(String errorCode, String message) {
    return AuthResult._(
      isSuccess: false,
      errorCode: errorCode,
      message: message,
    );
  }
}

/// Validation result for Dutch business validation
class ValidationResult {
  final bool isValid;
  final String message;
  final Map<String, dynamic>? data;

  const ValidationResult._({
    required this.isValid,
    required this.message,
    this.data,
  });

  /// Create success validation result
  factory ValidationResult.success(String message, {Map<String, dynamic>? data}) {
    return ValidationResult._(
      isValid: true,
      message: message,
      data: data,
    );
  }

  /// Create error validation result
  factory ValidationResult.error(String message) {
    return ValidationResult._(
      isValid: false,
      message: message,
    );
  }

  /// Get first error message or empty string
  String get errorMessage => isValid ? '' : message;
}

/// Firebase-backed authentication service for SecuryFlex
/// Provides real user authentication with Firebase Auth and Firestore user data
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool _isLoggedIn = false;
  static String _currentUserType = '';
  static String _currentUserName = '';
  static String _currentUserId = '';
  static Map<String, dynamic> _currentUserData = {};

  /// Get demo credentials from secure environment configuration
  /// Only available in debug mode with proper environment variables
  static Map<String, Map<String, dynamic>> get _demoCredentials {
    return EnvironmentConfig.getDemoCredentials();
  }

  /// Check if user is currently logged in
  static bool get isLoggedIn => _isLoggedIn;

  /// Get current user type (guard, company, admin)
  static String get currentUserType => _currentUserType;

  /// Get current user name
  static String get currentUserName => _currentUserName;

  /// Get current user ID
  static String get currentUserId => _currentUserId;

  /// Get current user data
  static Map<String, dynamic> get currentUserData => _currentUserData;

  /// Get current Firebase user
  static User? get currentFirebaseUser => _auth.currentUser;

  /// Attempt to login with email and password
  /// Returns AuthResult with success/error information
  static Future<AuthResult> loginWithResult(String email, String password) async {
    final emailLower = email.toLowerCase().trim();

    // Check account lockout first
    if (isAccountLockedOut(emailLower)) {
      return AuthResult.error(
        'account-locked',
        'Account is vergrendeld wegens te veel mislukte inlogpogingen. Probeer over 24 uur opnieuw of neem contact op met support.',
      );
    }

    // Check rate limiting
    if (_isLoginRateLimited(emailLower)) {
      final remainingMinutes = _getRateLimitRemainingMinutes(emailLower, true);
      return AuthResult.error(
        'rate-limited',
        'Te veel inlogpogingen. Probeer opnieuw over $remainingMinutes minuten.',
      );
    }

    try {
      // Check if Firebase is properly configured
      if (_isFirebaseConfigured()) {
        // Try Firebase authentication
        final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        if (userCredential.user != null) {
          final user = userCredential.user!;

          // Check if email is verified
          if (!user.emailVerified) {
            // Sign out the user since they can't proceed without verification
            await _auth.signOut();
            return AuthResult.error(
              'email-not-verified',
              'E-mail niet geverifieerd. Controleer uw inbox en klik op de verificatielink.',
            );
          }

          await _loadUserData(user.uid);
          await _updateLastLogin();
          
          // Initialize session and reset failed login count
          _initializeSession(user.uid);
          _resetFailedLoginCount(emailLower);
          
          return AuthResult.success('Succesvol ingelogd');
        }
      } else {
        debugPrint('Firebase not configured - authentication unavailable');
        return AuthResult.error('firebase-not-configured', 'Firebase niet geconfigureerd. Authenticatie niet mogelijk.');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase login failed: ${e.code} - ${e.message}');
      // Record failed attempt for rate limiting and account lockout
      _recordLoginAttempt(emailLower);
      _recordFailedLogin(emailLower);
      // No demo mode - return authentication error
    } catch (e) {
      debugPrint('Login error: $e');
      // Record failed attempt for rate limiting and account lockout
      _recordLoginAttempt(emailLower);
      _recordFailedLogin(emailLower);
      // No demo mode - return authentication error
    }

    // DEVELOPMENT ONLY: Check demo credentials from secure environment configuration
    if (EnvironmentConfig.isDemoModeEnabled) {
      final demoCredentials = _demoCredentials;
      if (demoCredentials.isNotEmpty) {
        final demoUser = demoCredentials[emailLower];
        if (demoUser != null && demoUser['password'] == password) {
          // Validate demo password meets security requirements
          final passwordValidation = validatePasswordDetailed(password);
          if (!passwordValidation.isValid) {
            debugPrint('SECURITY: Demo password does not meet security requirements');
            return AuthResult.error('weak-demo-password', 'Demo wachtwoord voldoet niet aan veiligheidseisen');
          }
          
          // Demo login successful
          _isLoggedIn = true;
          _currentUserId = 'demo_${demoUser['userType']}_001';
          _currentUserType = demoUser['userType'] as String;
          _currentUserName = demoUser['name'] as String;
          _currentUserData = {
            'email': emailLower,
            'name': demoUser['name'] as String,
            'userType': demoUser['userType'] as String,
            'isDemo': true,
            'demoLoginTime': DateTime.now().toIso8601String(),
          };
          
          // Initialize session and reset failed login count
          _initializeSession(_currentUserId);
          _resetFailedLoginCount(emailLower);
          
          debugPrint('DEMO: Successful demo login for ${demoUser['userType']} account');
          return AuthResult.success('Demo account: succesvol ingelogd als ${demoUser['name']}');
        }
      }
    }

    return AuthResult.error('auth-failed', 'Inloggen mislukt. Controleer uw e-mailadres en wachtwoord.');
  }

  /// Legacy login method for backward compatibility
  /// Returns true if successful, false otherwise
  static Future<bool> login(String email, String password) async {
    final result = await loginWithResult(email, password);
    return result.isSuccess;
  }

  /// Check if Firebase is properly configured
  static bool _isFirebaseConfigured() {
    try {
      // Use environment configuration for validation
      return EnvironmentConfig.isFirebaseConfigured;
    } catch (e) {
      debugPrint('Firebase configuration check failed: $e');
      return false;
    }
  }

  /// Logout current user
  static Future<void> logout() async {
    final userId = _currentUserId;
    
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      // Clear session data
      if (userId.isNotEmpty) {
        _invalidateSession(userId);
      }
      
      _isLoggedIn = false;
      _currentUserType = '';
      _currentUserName = '';
      _currentUserId = '';
      _currentUserData = {};
    }
  }

  /// Load user data from Firestore
  static Future<void> _loadUserData(String uid) async {
    try {
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _isLoggedIn = true;
        _currentUserId = uid;
        _currentUserType = userData['userType'] ?? 'guard';
        _currentUserName = userData['name'] ?? 'Unknown User';
        _currentUserData = userData;
      } else {
        // Create a default user document if it doesn't exist
        debugPrint('User document not found, creating default user document for $uid');
        await _createDefaultUserDocument(uid);

        // Set default values
        _isLoggedIn = true;
        _currentUserId = uid;
        _currentUserType = 'company'; // Default to company for this demo
        _currentUserName = 'Demo User';
        _currentUserData = {
          'userType': 'company',
          'name': 'Demo User',
          'email': 'demo@securyflex.nl',
          'createdAt': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Don't rethrow, instead set default values for demo mode
      _isLoggedIn = true;
      _currentUserId = uid;
      _currentUserType = 'company';
      _currentUserName = 'Demo User';
      _currentUserData = {
        'userType': 'company',
        'name': 'Demo User',
        'email': 'demo@securyflex.nl',
      };
    }
  }

  /// Create a default user document
  static Future<void> _createDefaultUserDocument(String uid) async {
    try {
      // Determine user type based on current Firebase user email or use company as default
      String userType = 'company';
      String name = 'Demo User';
      String email = 'demo@securyflex.nl';

      final user = _auth.currentUser;
      if (user?.email != null) {
        email = user!.email!;
        if (email.contains('guard')) {
          userType = 'guard';
          name = 'Demo Beveiliger';
        } else if (email.contains('company')) {
          userType = 'company';
          name = 'Demo Bedrijf';
        } else if (email.contains('admin')) {
          userType = 'admin';
          name = 'Demo Admin';
        }
      }

      await _firestore.collection('users').doc(uid).set({
        'userType': userType,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isDemo': true,
      });
      
      debugPrint('Successfully created default user document for $uid with type: $userType');
    } catch (e) {
      debugPrint('Error creating default user document: $e');
      // Don't rethrow, we'll handle this gracefully
    }
  }

  /// Register new user with email and password
  static Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    required String userType,
    Map<String, dynamic>? additionalData,
  }) async {
    final emailLower = email.toLowerCase().trim();

    // Check rate limiting
    if (_isRegistrationRateLimited(emailLower)) {
      final remainingMinutes = _getRateLimitRemainingMinutes(emailLower, false);
      return AuthResult.error(
        'rate-limited',
        'Te veel registratiepogingen. Probeer opnieuw over $remainingMinutes minuten.',
      );
    }

    try {
      // Validate inputs
      if (!isValidEmail(email)) {
        return AuthResult.error('invalid-email', 'Ongeldig e-mailadres format');
      }

      final passwordValidation = validatePasswordDetailed(password);
      if (!passwordValidation.isValid) {
        return AuthResult.error('weak-password', passwordValidation.firstError);
      }

      // Check if Firebase is properly configured
      if (_isFirebaseConfigured()) {
        // Create Firebase user
        final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        if (userCredential.user != null) {
          final user = userCredential.user!;

          // Send email verification
          await user.sendEmailVerification();

          // Create user document in Firestore
          final userData = {
            'email': email.trim(),
            'name': name.trim(),
            'userType': userType,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'emailVerified': false,
            ...?additionalData,
          };

          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userData);

          return AuthResult.success(
            'Account succesvol aangemaakt! Controleer uw e-mail voor verificatie.',
            data: {'requiresEmailVerification': true, 'email': email},
          );
        }
      } else {
        debugPrint('Firebase not configured, registration not available in demo mode');
        return AuthResult.error('firebase-not-configured', 'Firebase niet geconfigureerd');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration failed: ${e.code} - ${e.message}');
      // Record failed attempt for rate limiting
      _recordRegistrationAttempt(emailLower);
      return AuthResult.error(e.code, _getFirebaseErrorMessage(e.code));
    } catch (e) {
      debugPrint('Registration error: $e');
      // Record failed attempt for rate limiting
      _recordRegistrationAttempt(emailLower);
      return AuthResult.error('unknown', 'Er is een onbekende fout opgetreden');
    }

    return AuthResult.error('unknown', 'Registratie mislukt');
  }

  /// Initialize authentication state on app start
  static Future<void> initialize() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _loadUserData(user.uid);
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    }
  }

  /// Check if user is authenticated and session is valid
  static Future<bool> checkAuthState() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null && !_isLoggedIn) {
        await _loadUserData(user.uid);
        _initializeSession(user.uid);
        return true;
      }
      
      // Check session validity for logged in users
      if (_isLoggedIn && _currentUserId.isNotEmpty) {
        if (!isSessionValid(_currentUserId)) {
          // Session expired, logout user
          await logout();
          return false;
        }
        updateLastActivity(_currentUserId);
      }
      
      return _isLoggedIn;
    } catch (e) {
      debugPrint('Auth state check error: $e');
      return false;
    }
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    // More comprehensive email validation regex that supports:
    // - Plus signs (+) for email aliases
    // - Dots in local part (but not consecutive)
    // - Various domain formats
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email) &&
           !email.contains('..'); // Prevent consecutive dots
  }

  /// Validate password strength with comprehensive requirements
  static bool isValidPassword(String password) {
    return password.length >= 12 &&
           _hasUppercase(password) &&
           _hasLowercase(password) &&
           _hasDigit(password) &&
           _hasSpecialChar(password) &&
           !_isCommonPassword(password);
  }

  /// Get detailed password validation result with Dutch error messages
  static PasswordValidationResult validatePasswordDetailed(String password) {
    final errors = <String>[];

    if (password.length < 12) {
      errors.add('Wachtwoord moet minimaal 12 tekens bevatten');
    }
    if (password.length > 128) {
      errors.add('Wachtwoord mag maximaal 128 tekens bevatten');
    }
    if (!_hasUppercase(password)) {
      errors.add('Wachtwoord moet minimaal één hoofdletter bevatten');
    }
    if (!_hasLowercase(password)) {
      errors.add('Wachtwoord moet minimaal één kleine letter bevatten');
    }
    if (!_hasDigit(password)) {
      errors.add('Wachtwoord moet minimaal één cijfer bevatten');
    }
    if (!_hasSpecialChar(password)) {
      errors.add('Wachtwoord moet minimaal één speciaal teken bevatten (!@#\$%^&*)');
    }
    if (_isCommonPassword(password)) {
      errors.add('Dit wachtwoord is te algemeen. Kies een unieker wachtwoord.');
    }

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      strength: _calculatePasswordStrength(password),
    );
  }

  /// Check if password contains uppercase letter
  static bool _hasUppercase(String password) {
    return RegExp(r'[A-Z]').hasMatch(password);
  }

  /// Check if password contains lowercase letter
  static bool _hasLowercase(String password) {
    return RegExp(r'[a-z]').hasMatch(password);
  }

  /// Check if password contains digit
  static bool _hasDigit(String password) {
    return RegExp(r'[0-9]').hasMatch(password);
  }

  /// Check if password contains special character
  static bool _hasSpecialChar(String password) {
    return RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  /// Calculate password strength (0-100)
  static int _calculatePasswordStrength(String password) {
    int strength = 0;

    // Length scoring (more emphasis on longer passwords)
    if (password.length >= 8) strength += 10;
    if (password.length >= 12) strength += 20;
    if (password.length >= 16) strength += 15;
    if (password.length >= 20) strength += 10;

    // Character variety scoring
    if (_hasUppercase(password)) strength += 10;
    if (_hasLowercase(password)) strength += 10;
    if (_hasDigit(password)) strength += 10;
    if (_hasSpecialChar(password)) strength += 15;

    // Bonus for multiple character types
    int characterTypes = 0;
    if (_hasUppercase(password)) characterTypes++;
    if (_hasLowercase(password)) characterTypes++;
    if (_hasDigit(password)) characterTypes++;
    if (_hasSpecialChar(password)) characterTypes++;
    strength += characterTypes * 5;

    // Penalty for common passwords
    if (_isCommonPassword(password)) {
      strength = (strength * 0.3).round(); // 70% reduction
    }

    // Penalty for sequential or repeated characters
    if (_hasSequentialChars(password)) {
      strength -= 15;
    }
    if (_hasRepeatedChars(password)) {
      strength -= 10;
    }

    return strength.clamp(0, 100);
  }

  /// Get Firebase configuration status
  static String getFirebaseStatus() {
    final firebaseStatus = _isFirebaseConfigured() 
        ? 'Firebase is configured and ready'
        : 'Firebase not configured';
    
    final demoStatus = EnvironmentConfig.isDemoModeEnabled
        ? 'Demo mode enabled (${_demoCredentials.length} accounts)'
        : 'Demo mode disabled';
    
    return '$firebaseStatus | $demoStatus';
  }

  /// Get available demo accounts (development only)
  /// Returns empty list if demo mode is not enabled
  static List<String> getAvailableDemoAccounts() {
    if (!EnvironmentConfig.isDemoModeEnabled) return [];
    return _demoCredentials.keys.toList();
  }

  /// Check if email is a demo account
  static bool isDemoAccount(String email) {
    if (!EnvironmentConfig.isDemoModeEnabled) return false;
    return _demoCredentials.containsKey(email.toLowerCase());
  }

  /// Send email verification to current user
  static Future<AuthResult> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.error('no-user', 'Geen gebruiker ingelogd');
      }

      if (user.emailVerified) {
        return AuthResult.error('already-verified', 'E-mail is al geverifieerd');
      }

      await user.sendEmailVerification();
      return AuthResult.success('Verificatie e-mail verzonden. Controleer uw inbox.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(e.code, _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('unknown', 'Er is een fout opgetreden bij het verzenden van de verificatie e-mail');
    }
  }

  /// Check if current user's email is verified
  static Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Reload user to get latest verification status
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  /// Resend email verification with rate limiting
  static Future<AuthResult> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.error('no-user', 'Geen gebruiker ingelogd');
      }

      if (user.emailVerified) {
        return AuthResult.error('already-verified', 'E-mail is al geverifieerd');
      }

      // Check rate limiting (prevent spam)
      final lastSent = _lastEmailVerificationSent[user.uid];
      if (lastSent != null) {
        final timeDiff = DateTime.now().difference(lastSent);
        if (timeDiff.inMinutes < 2) {
          return AuthResult.error('rate-limited', 'Wacht ${2 - timeDiff.inMinutes} minuten voordat u opnieuw een verificatie e-mail aanvraagt');
        }
      }

      await user.sendEmailVerification();
      _lastEmailVerificationSent[user.uid] = DateTime.now();

      return AuthResult.success('Verificatie e-mail opnieuw verzonden. Controleer uw inbox.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(e.code, _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('unknown', 'Er is een fout opgetreden bij het verzenden van de verificatie e-mail');
    }
  }

  // Rate limiting for email verification
  static final Map<String, DateTime> _lastEmailVerificationSent = {};

  /// Send password reset email
  static Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      if (!isValidEmail(email)) {
        return AuthResult.error('invalid-email', 'Ongeldig e-mailadres format');
      }

      // Check rate limiting (prevent spam)
      final lastSent = _lastPasswordResetSent[email.toLowerCase()];
      if (lastSent != null) {
        final timeDiff = DateTime.now().difference(lastSent);
        if (timeDiff.inMinutes < 5) {
          return AuthResult.error('rate-limited', 'Wacht ${5 - timeDiff.inMinutes} minuten voordat u opnieuw een wachtwoord reset aanvraagt');
        }
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      _lastPasswordResetSent[email.toLowerCase()] = DateTime.now();

      return AuthResult.success('Wachtwoord reset e-mail verzonden naar $email. Controleer uw inbox.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(e.code, _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('unknown', 'Er is een fout opgetreden bij het verzenden van de wachtwoord reset e-mail');
    }
  }

  /// Confirm password reset with code
  static Future<AuthResult> confirmPasswordReset(String code, String newPassword) async {
    try {
      final passwordValidation = validatePasswordDetailed(newPassword);
      if (!passwordValidation.isValid) {
        return AuthResult.error('weak-password', passwordValidation.firstError);
      }

      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      return AuthResult.success('Wachtwoord succesvol gewijzigd. U kunt nu inloggen met uw nieuwe wachtwoord.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(e.code, _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('unknown', 'Er is een fout opgetreden bij het wijzigen van het wachtwoord');
    }
  }

  /// Verify password reset code
  static Future<AuthResult> verifyPasswordResetCode(String code) async {
    try {
      final email = await _auth.verifyPasswordResetCode(code);
      return AuthResult.success('Code geverifieerd voor $email', data: {'email': email});
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(e.code, _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('unknown', 'Ongeldige of verlopen code');
    }
  }

  // Rate limiting for password reset
  static final Map<String, DateTime> _lastPasswordResetSent = {};

  // Rate limiting for login attempts
  static final Map<String, List<DateTime>> _loginAttempts = {};
  static final Map<String, List<DateTime>> _registrationAttempts = {};

  /// Check if login is rate limited for email
  static bool _isLoginRateLimited(String email) {
    final attempts = _loginAttempts[email.toLowerCase()] ?? [];
    final now = DateTime.now();

    // Remove attempts older than 15 minutes
    attempts.removeWhere((attempt) => now.difference(attempt).inMinutes > 15);
    _loginAttempts[email.toLowerCase()] = attempts;

    // Allow max 3 attempts per 15 minutes
    return attempts.length >= 3;
  }

  /// Record login attempt for rate limiting
  static void _recordLoginAttempt(String email) {
    final attempts = _loginAttempts[email.toLowerCase()] ?? [];
    attempts.add(DateTime.now());
    _loginAttempts[email.toLowerCase()] = attempts;
  }

  /// Check if registration is rate limited for email
  static bool _isRegistrationRateLimited(String email) {
    final attempts = _registrationAttempts[email.toLowerCase()] ?? [];
    final now = DateTime.now();

    // Remove attempts older than 1 hour
    attempts.removeWhere((attempt) => now.difference(attempt).inHours > 1);
    _registrationAttempts[email.toLowerCase()] = attempts;

    // Allow max 3 registration attempts per hour
    return attempts.length >= 3;
  }

  /// Record registration attempt for rate limiting
  static void _recordRegistrationAttempt(String email) {
    final attempts = _registrationAttempts[email.toLowerCase()] ?? [];
    attempts.add(DateTime.now());
    _registrationAttempts[email.toLowerCase()] = attempts;
  }

  /// Get remaining time for rate limit in minutes with progressive backoff
  static int _getRateLimitRemainingMinutes(String email, bool isLogin) {
    final attempts = isLogin
        ? (_loginAttempts[email.toLowerCase()] ?? [])
        : (_registrationAttempts[email.toLowerCase()] ?? []);

    if (attempts.isEmpty) return 0;

    final attemptCount = attempts.length;
    int baseLimitMinutes = isLogin ? 15 : 60;
    
    // Progressive backoff: more attempts = longer lockout
    if (attemptCount >= 5) {
      baseLimitMinutes = isLogin ? 120 : 240; // 2-4 hours
    } else if (attemptCount >= 3) {
      baseLimitMinutes = isLogin ? 60 : 120;  // 1-2 hours
    }

    final oldestAttempt = attempts.first;
    final elapsed = DateTime.now().difference(oldestAttempt).inMinutes;

    return (baseLimitMinutes - elapsed).clamp(0, baseLimitMinutes);
  }

  /// Get user role display name in Dutch
  static String getUserRoleDisplayName(String userType) {
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

  /// Check if current user has specific role
  static bool hasRole(String role) {
    return _currentUserType.toLowerCase() == role.toLowerCase();
  }

  /// Get user avatar based on role
  static String getUserAvatar(String userType) {
    switch (userType.toLowerCase()) {
      case 'guard':
        return 'assets/images/guard_avatar.png';
      case 'company':
        return 'assets/images/company_avatar.png';
      case 'admin':
        return 'assets/images/admin_avatar.png';
      default:
        return 'assets/images/default_avatar.png';
    }
  }

  // DUTCH BUSINESS VALIDATION METHODS

  /// Validate Dutch KvK (Chamber of Commerce) number
  /// KvK numbers are exactly 8 digits
  static bool isValidKvK(String kvkNumber) {
    if (kvkNumber.isEmpty) return false;
    final cleaned = kvkNumber.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length == 8 && RegExp(r'^\d{8}$').hasMatch(cleaned);
  }

  /// Validate Dutch postal code format (1234AB)
  static bool isValidDutchPostalCode(String postalCode) {
    if (postalCode.isEmpty) return false;
    final cleaned = postalCode.replaceAll(' ', '').toUpperCase();
    return RegExp(r'^\d{4}[A-Z]{2}$').hasMatch(cleaned);
  }

  /// Validate WPBR certificate number (WPBR-123456)
  static bool isValidWPBRNumber(String wpbrNumber) {
    if (wpbrNumber.isEmpty) return false;
    final cleaned = wpbrNumber.toUpperCase();
    return RegExp(r'^WPBR-\d{6}$').hasMatch(cleaned);
  }

  /// Calculate BTW (VAT) at Dutch standard rate of 21%
  static double calculateBTW(double amount) {
    return amount * 0.21;
  }

  /// Calculate amount including BTW
  static double calculateAmountWithBTW(double amount) {
    return amount * 1.21;
  }

  /// Calculate amount excluding BTW (reverse calculation)
  static double calculateAmountExcludingBTW(double amountWithBTW) {
    return amountWithBTW / 1.21;
  }

  /// Format Dutch postal code to standard format (1234 AB)
  static String formatDutchPostalCode(String postalCode) {
    if (postalCode.isEmpty) return '';
    final cleaned = postalCode.replaceAll(' ', '').toUpperCase();
    if (!isValidDutchPostalCode(cleaned)) return postalCode;
    return '${cleaned.substring(0, 4)} ${cleaned.substring(4)}';
  }

  /// Format KvK number with periods (12.34.56.78)
  static String formatKvKNumber(String kvkNumber) {
    if (kvkNumber.isEmpty) return '';
    final cleaned = kvkNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (!isValidKvK(cleaned)) return kvkNumber;
    return '${cleaned.substring(0, 2)}.${cleaned.substring(2, 4)}.${cleaned.substring(4, 6)}.${cleaned.substring(6, 8)}';
  }

  /// Get detailed KvK validation result with Dutch error messages
  static ValidationResult validateKvKDetailed(String kvkNumber) {
    if (kvkNumber.isEmpty) {
      return ValidationResult.error('KvK nummer is verplicht');
    }
    
    final cleaned = kvkNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.length < 8) {
      return ValidationResult.error('KvK nummer moet uit 8 cijfers bestaan');
    }
    if (cleaned.length > 8) {
      return ValidationResult.error('KvK nummer mag niet meer dan 8 cijfers bevatten');
    }
    if (!RegExp(r'^\d{8}$').hasMatch(cleaned)) {
      return ValidationResult.error('KvK nummer mag alleen cijfers bevatten');
    }

    return ValidationResult.success('KvK nummer is geldig', data: {'formatted': formatKvKNumber(cleaned)});
  }

  /// Get detailed Dutch postal code validation result
  static ValidationResult validateDutchPostalCodeDetailed(String postalCode) {
    if (postalCode.isEmpty) {
      return ValidationResult.error('Postcode is verplicht');
    }
    
    final cleaned = postalCode.replaceAll(' ', '').toUpperCase();
    
    if (cleaned.length < 6) {
      return ValidationResult.error('Postcode is te kort (formaat: 1234AB)');
    }
    if (cleaned.length > 6) {
      return ValidationResult.error('Postcode is te lang (formaat: 1234AB)');
    }
    if (!RegExp(r'^\d{4}[A-Z]{2}$').hasMatch(cleaned)) {
      return ValidationResult.error('Ongeldig postcode formaat. Gebruik: 1234AB');
    }

    return ValidationResult.success('Postcode is geldig', data: {'formatted': formatDutchPostalCode(cleaned)});
  }

  /// Get detailed WPBR validation result
  static ValidationResult validateWPBRDetailed(String wpbrNumber) {
    if (wpbrNumber.isEmpty) {
      return ValidationResult.error('WPBR certificaatnummer is verplicht');
    }
    
    final cleaned = wpbrNumber.toUpperCase();
    
    if (!cleaned.startsWith('WPBR-')) {
      return ValidationResult.error('WPBR nummer moet beginnen met "WPBR-"');
    }
    if (!RegExp(r'^WPBR-\d{6}$').hasMatch(cleaned)) {
      return ValidationResult.error('Ongeldig WPBR formaat. Gebruik: WPBR-123456');
    }

    return ValidationResult.success('WPBR certificaatnummer is geldig');
  }

  /// Validate beveiligingspas number format (KvK 2025 requirement)
  /// Dutch security pass - 7 digit format
  static bool isValidBeveiligingspasnumber(String pasNumber) {
    if (pasNumber.isEmpty) return false;
    final cleaned = pasNumber.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length == 7 && RegExp(r'^\d{7}$').hasMatch(cleaned);
  }

  /// Get detailed beveiligingspas validation result
  static ValidationResult validateBeveiligingspaDetailed(String pasNumber) {
    if (pasNumber.isEmpty) {
      return ValidationResult.error('Beveiligingspas nummer is verplicht');
    }
    
    final cleaned = pasNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.length != 7) {
      return ValidationResult.error('Beveiligingspas moet 7 cijfers bevatten');
    }
    
    if (!RegExp(r'^\d{7}$').hasMatch(cleaned)) {
      return ValidationResult.error('Ongeldig beveiligingspas formaat. Gebruik: 1234567');
    }

    return ValidationResult.success('Beveiligingspas nummer is geldig', data: {'formatted': cleaned});
  }

  /// Get detailed SVPB diploma validation result  
  static ValidationResult validateSVPBDiplomaDetailed(String diplomaNumber) {
    if (diplomaNumber.isEmpty) {
      return ValidationResult.error('SVPB diploma nummer is verplicht');
    }
    
    final cleaned = diplomaNumber.toUpperCase().trim();
    
    // SVPB format: SVPB-123456
    if (!RegExp(r'^SVPB-\d{6}$').hasMatch(cleaned)) {
      return ValidationResult.error('Ongeldig SVPB diploma formaat. Gebruik: SVPB-123456');
    }

    return ValidationResult.success('SVPB diploma nummer is geldig', data: {'formatted': cleaned});
  }

  /// Get Dutch error message for Firebase Auth error codes
  static String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      // Registration errors
      case 'email-already-in-use':
        return 'Dit e-mailadres is al in gebruik. Probeer in te loggen of gebruik een ander e-mailadres.';
      case 'weak-password':
        return 'Wachtwoord is te zwak. Gebruik minimaal 8 tekens met hoofdletters, kleine letters, cijfers en speciale tekens.';
      case 'invalid-email':
        return 'Ongeldig e-mailadres format. Controleer de invoer.';
      case 'operation-not-allowed':
        return 'E-mail/wachtwoord registratie is niet ingeschakeld. Neem contact op met support.';

      // Login errors
      case 'user-disabled':
        return 'Uw account is uitgeschakeld. Neem contact op met support voor meer informatie.';
      case 'user-not-found':
        return 'Geen account gevonden met dit e-mailadres. Controleer uw invoer of registreer een nieuw account.';
      case 'wrong-password':
        return 'Onjuist wachtwoord. Probeer opnieuw of gebruik "Wachtwoord vergeten".';
      case 'invalid-credential':
        return 'Ongeldige inloggegevens. Controleer uw e-mailadres en wachtwoord.';

      // Rate limiting and security
      case 'too-many-requests':
        return 'Te veel inlogpogingen. Wacht een paar minuten voordat u het opnieuw probeert.';
      case 'account-exists-with-different-credential':
        return 'Er bestaat al een account met dit e-mailadres maar met andere inlogmethode.';

      // Network and technical errors
      case 'network-request-failed':
        return 'Netwerkfout. Controleer uw internetverbinding en probeer opnieuw.';
      case 'internal-error':
        return 'Interne serverfout. Probeer later opnieuw.';
      case 'timeout':
        return 'Verbinding verlopen. Controleer uw internetverbinding.';

      // Password reset errors
      case 'expired-action-code':
        return 'De reset link is verlopen. Vraag een nieuwe wachtwoord reset aan.';
      case 'invalid-action-code':
        return 'Ongeldige of al gebruikte reset link. Vraag een nieuwe aan.';
      case 'user-token-expired':
        return 'Uw sessie is verlopen. Log opnieuw in.';

      // Email verification errors
      case 'email-not-verified':
        return 'E-mail niet geverifieerd. Controleer uw inbox en klik op de verificatielink.';
      case 'requires-recent-login':
        return 'Voor uw veiligheid moet u opnieuw inloggen om deze actie uit te voeren.';

      // Custom errors
      case 'firebase-not-configured':
        return 'Firebase is niet correct geconfigureerd. Neem contact op met support.';
      case 'rate-limited':
        return 'Te veel verzoeken. Wacht even voordat u het opnieuw probeert.';
      case 'auth-failed':
        return 'Inloggen mislukt. Controleer uw e-mailadres en wachtwoord.';

      default:
        return 'Er is een onbekende fout opgetreden. Probeer opnieuw of neem contact op met support.';
    }
  }

  /// Update user profile data
  static Future<bool> updateProfile({
    String? name,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (!_isLoggedIn || _currentUserId.isEmpty) return false;

      final updateData = <String, dynamic>{
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) {
        updateData['name'] = name.trim();
        _currentUserName = name.trim();
      }

      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .update(updateData);

      // Update local cache
      _currentUserData.addAll(updateData);
      return true;
    } catch (e) {
      debugPrint('Profile update error: $e');
      return false;
    }
  }

  /// Update last login timestamp
  static Future<void> _updateLastLogin() async {
    try {
      if (_currentUserId.isNotEmpty && (_currentUserData['isDemo'] != true)) {
        await _firestore
            .collection('users')
            .doc(_currentUserId)
            .update({'lastLoginAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      debugPrint('Last login update error: $e');
    }
  }

  /// Check if password is commonly used (basic implementation)
  static bool _isCommonPassword(String password) {
    final commonPasswords = {
      // Dutch common passwords
      'wachtwoord', 'wachtwoord123', 'password', 'password123',
      'welkom', 'welkom123', 'amsterdam', 'nederland',
      // International common passwords
      '123456789012', 'qwertyuiopas', 'asdfghjklzxc',
      'admin123456', 'user12345678', 'temp12345678',
      'letmein12345', 'monkey123456', 'dragon123456',
      'football1234', 'baseball1234', 'master123456',
      'shadow123456', 'jordan123456', 'superman1234',
      'michael12345', 'jennifer1234', 'welcome12345',
      'sunshine1234', 'princess1234', 'freedom12345',
      // Sequential patterns
      '123456789abc', 'abcdefghijkl', '987654321098',
      '098765432109', 'zyxwvutsrqpo',
    };
    
    final lowerPassword = password.toLowerCase();
    return commonPasswords.contains(lowerPassword) ||
           lowerPassword.contains('123456') ||
           lowerPassword.contains('password') ||
           lowerPassword.contains('qwerty');
  }

  /// Check for sequential characters
  static bool _hasSequentialChars(String password) {
    final sequences = ['123', '234', '345', '456', '567', '678', '789',
                      'abc', 'bcd', 'cde', 'def', 'efg', 'fgh', 'ghi',
                      'qwe', 'wer', 'ert', 'rty', 'tyu', 'yui', 'uio'];
    
    final lower = password.toLowerCase();
    return sequences.any((seq) => lower.contains(seq));
  }

  /// Check for repeated characters
  static bool _hasRepeatedChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i] == password[i + 2]) {
        return true; // Three or more consecutive identical characters
      }
    }
    return false;
  }

  // Session management for security
  static final Map<String, DateTime> _userSessions = {};
  static final Map<String, DateTime> _lastActivity = {};
  static const int _sessionTimeoutMinutes = 30;
  static const int _absoluteSessionTimeoutHours = 8;

  /// Initialize session for user
  static void _initializeSession(String userId) {
    final now = DateTime.now();
    _userSessions[userId] = now;
    _lastActivity[userId] = now;
  }

  /// Update last activity for session timeout
  static void updateLastActivity(String userId) {
    if (_userSessions.containsKey(userId)) {
      _lastActivity[userId] = DateTime.now();
    }
  }

  /// Check if session is valid
  static bool isSessionValid(String userId) {
    final sessionStart = _userSessions[userId];
    final lastActivity = _lastActivity[userId];
    
    if (sessionStart == null || lastActivity == null) {
      return false;
    }
    
    final now = DateTime.now();
    
    // Check absolute timeout (8 hours)
    if (now.difference(sessionStart).inHours >= _absoluteSessionTimeoutHours) {
      _invalidateSession(userId);
      return false;
    }
    
    // Check idle timeout (30 minutes)
    if (now.difference(lastActivity).inMinutes >= _sessionTimeoutMinutes) {
      _invalidateSession(userId);
      return false;
    }
    
    return true;
  }

  /// Invalidate session
  static void _invalidateSession(String userId) {
    _userSessions.remove(userId);
    _lastActivity.remove(userId);
  }

  /// Enhanced account lockout mechanism
  static final Map<String, DateTime> _accountLockouts = {};
  static final Map<String, int> _failedLoginCounts = {};
  static const int _maxFailedLogins = 5;
  static const int _lockoutHours = 24;

  /// Check if account is locked out
  static bool isAccountLockedOut(String email) {
    final lockoutTime = _accountLockouts[email.toLowerCase()];
    if (lockoutTime == null) return false;
    
    if (DateTime.now().difference(lockoutTime).inHours >= _lockoutHours) {
      // Lockout expired, remove it
      _accountLockouts.remove(email.toLowerCase());
      _failedLoginCounts.remove(email.toLowerCase());
      return false;
    }
    
    return true;
  }

  /// Record failed login and check for lockout
  static void _recordFailedLogin(String email) {
    final emailLower = email.toLowerCase();
    final currentCount = _failedLoginCounts[emailLower] ?? 0;
    _failedLoginCounts[emailLower] = currentCount + 1;
    
    if (_failedLoginCounts[emailLower]! >= _maxFailedLogins) {
      _accountLockouts[emailLower] = DateTime.now();
      debugPrint('SECURITY: Account locked due to failed login attempts: $emailLower');
    }
  }

  /// Reset failed login count on successful login
  static void _resetFailedLoginCount(String email) {
    final emailLower = email.toLowerCase();
    _failedLoginCounts.remove(emailLower);
    _accountLockouts.remove(emailLower);
  }

  /// Get demo account information for development/testing
  /// Returns null if not a demo account or demo mode disabled
  static Map<String, dynamic>? getDemoAccountInfo(String email) {
    if (!EnvironmentConfig.isDemoModeEnabled) return null;
    
    final demoUser = _demoCredentials[email.toLowerCase()];
    if (demoUser == null) return null;
    
    // Return account info without password
    return {
      'email': email.toLowerCase(),
      'userType': demoUser['userType'],
      'name': demoUser['name'],
      'isDemo': true,
    };
  }

  // 🚨 SECURITY: Terms acceptance validation for route guards
  static final Map<String, bool> _termsAcceptanceCache = {};
  static const String _currentTermsVersion = '2025.1';

  /// Check if user has accepted current terms (synchronous for route guards)
  /// Uses cached value with background refresh for performance
  static bool hasAcceptedCurrentTerms(String userId) {
    if (userId.isEmpty) return false;

    // Return cached value if available
    final cacheKey = '${userId}_$_currentTermsVersion';
    if (_termsAcceptanceCache.containsKey(cacheKey)) {
      return _termsAcceptanceCache[cacheKey]!;
    }

    // For route guard performance, assume false if not cached
    // Background refresh will update cache
    _refreshTermsAcceptanceCache(userId);
    return false;
  }

  /// Refresh terms acceptance cache in background
  static void _refreshTermsAcceptanceCache(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data();
      final acceptedVersion = userData?['termsVersion'] as String?;
      final hasAccepted = acceptedVersion == _currentTermsVersion;

      final cacheKey = '${userId}_$_currentTermsVersion';
      _termsAcceptanceCache[cacheKey] = hasAccepted;

      debugPrint('Terms acceptance cached for $userId: $hasAccepted');
    } catch (e) {
      debugPrint('Error refreshing terms cache: $e');
      // Default to false for security
      final cacheKey = '${userId}_$_currentTermsVersion';
      _termsAcceptanceCache[cacheKey] = false;
    }
  }

  /// Update terms acceptance status
  static Future<void> acceptCurrentTerms(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'termsVersion': _currentTermsVersion,
        'termsAcceptedAt': FieldValue.serverTimestamp(),
      });

      // Update cache immediately
      final cacheKey = '${userId}_$_currentTermsVersion';
      _termsAcceptanceCache[cacheKey] = true;

      debugPrint('Terms accepted for user: $userId');
    } catch (e) {
      debugPrint('Error updating terms acceptance: $e');
      throw e;
    }
  }
}
