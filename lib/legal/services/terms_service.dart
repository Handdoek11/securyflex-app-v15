import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../terms_and_conditions.dart';
import '../privacy_policy.dart';

class TermsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Check if user has accepted the current version of terms
  static Future<bool> hasAcceptedCurrentTerms(String userId) async {
    try {
      // Check Firestore first
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final acceptedVersion = data['termsVersion'] as String?;
      final termsAccepted = data['termsAccepted'] as bool? ?? false;
      
      return termsAccepted && acceptedVersion == TermsAndConditions.version;
      
    } catch (e) {
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final localVersion = prefs.getString('terms_version');
      final localAccepted = prefs.getBool('terms_accepted') ?? false;
      
      return localAccepted && localVersion == TermsAndConditions.version;
    }
  }
  
  /// Record terms acceptance
  static Future<void> recordAcceptance({
    required String userId,
    required bool acceptTerms,
    required bool acceptPrivacy,
    required bool acceptCookies,
  }) async {
    final timestamp = FieldValue.serverTimestamp();
    
    // Save to Firestore
    await _firestore.collection('users').doc(userId).set({
      'termsAccepted': acceptTerms,
      'termsVersion': TermsAndConditions.version,
      'termsAcceptedAt': timestamp,
      'privacyAccepted': acceptPrivacy,
      'privacyVersion': PrivacyPolicy.version,
      'privacyAcceptedAt': timestamp,
      'cookieConsent': acceptCookies,
      'cookieConsentAt': acceptCookies ? timestamp : null,
      'lastUpdated': timestamp,
    }, SetOptions(merge: true));
    
    // Also save locally for offline access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', acceptTerms);
    await prefs.setString('terms_version', TermsAndConditions.version);
    await prefs.setBool('privacy_accepted', acceptPrivacy);
    await prefs.setString('privacy_version', PrivacyPolicy.version);
    await prefs.setBool('cookie_consent', acceptCookies);
  }
  
  /// Check if terms have been updated since user accepted
  static Future<bool> needsReacceptance(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) return true;
      
      final data = doc.data()!;
      final termsVersion = data['termsVersion'] as String?;
      final privacyVersion = data['privacyVersion'] as String?;
      
      return termsVersion != TermsAndConditions.version ||
             privacyVersion != PrivacyPolicy.version;
             
    } catch (e) {
      return true; // Safe default: require acceptance
    }
  }
  
  /// Get user's cookie consent status
  static Future<bool> hasCookieConsent(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) return false;
      
      return doc.data()!['cookieConsent'] as bool? ?? false;
      
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('cookie_consent') ?? false;
    }
  }
  
  /// Update cookie consent
  static Future<void> updateCookieConsent({
    required String userId,
    required bool consent,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'cookieConsent': consent,
      'cookieConsentAt': consent ? FieldValue.serverTimestamp() : null,
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cookie_consent', consent);
  }
  
  /// Log terms view event (for compliance tracking)
  static Future<void> logTermsView(String userId) async {
    await _firestore.collection('terms_events').add({
      'userId': userId,
      'event': 'terms_viewed',
      'termsVersion': TermsAndConditions.version,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  
  /// Log privacy policy view event
  static Future<void> logPrivacyView(String userId) async {
    await _firestore.collection('terms_events').add({
      'userId': userId,
      'event': 'privacy_viewed',
      'privacyVersion': PrivacyPolicy.version,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}