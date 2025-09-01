import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized Firebase error handling for SecuryFlex
/// Provides consistent error handling across all Firebase operations
class FirebaseErrorHandler {
  /// Handle Firebase errors with proper logging and user-friendly messages
  static String handleFirebaseError(Object error, {String? context}) {
    if (kDebugMode && context != null) {
      debugPrint('🔥 Firebase Error [$context]: $error');
    }
    
    // Handle specific Firebase errors
    if (error is FirebaseException) {
      switch (error.code) {
        // Firestore errors
        case 'failed-precondition':
          if (error.message?.contains('index') == true) {
            if (kDebugMode) {
              debugPrint('⚠️ Missing Firestore index - functionality may be limited');
            }
            return 'Data wordt geladen, even geduld...';
          }
          return 'Er is een probleem met de database configuratie';
          
        case 'permission-denied':
          return 'Je hebt geen toegang tot deze functie';
          
        case 'not-found':
          return 'De gevraagde gegevens zijn niet gevonden';
          
        case 'already-exists':
          return 'Deze gegevens bestaan al';
          
        case 'resource-exhausted':
          return 'Er zijn te veel aanvragen, probeer het later opnieuw';
          
        case 'unauthenticated':
          return 'Je bent niet ingelogd, log opnieuw in';
          
        case 'unavailable':
          return 'Service tijdelijk niet beschikbaar, probeer het later';
          
        case 'deadline-exceeded':
          return 'Verzoek duurde te lang, probeer opnieuw';
          
        // Firebase Messaging errors
        case 'failed-service-worker-registration':
          if (kDebugMode) {
            debugPrint('⚠️ Service Worker registration failed - push notifications may not work');
          }
          return 'Notificaties kunnen mogelijk niet werken';
          
        case 'messaging/permission-blocked':
          return 'Notificaties zijn uitgeschakeld in je browser';
          
        case 'messaging/token-unsubscribe-failed':
          return 'Kan notificaties niet uitschakelen';
          
        // Authentication errors  
        case 'auth/user-not-found':
          return 'Gebruiker niet gevonden';
          
        case 'auth/wrong-password':
          return 'Onjuist wachtwoord';
          
        case 'auth/too-many-requests':
          return 'Te veel pogingen, probeer het later opnieuw';
          
        case 'auth/network-request-failed':
          return 'Netwerkfout, controleer je internetverbinding';
          
        // Storage errors
        case 'storage/unauthorized':
          return 'Geen toegang tot bestandsopslag';
          
        case 'storage/object-not-found':
          return 'Bestand niet gevonden';
          
        case 'storage/quota-exceeded':
          return 'Opslaglimiet bereikt';
          
        default:
          return _getGenericErrorMessage(error.code);
      }
    }
    
    // Handle network errors
    if (error.toString().contains('network') || 
        error.toString().contains('connection')) {
      return 'Geen internetverbinding, controleer je netwerk';
    }
    
    // Generic error handling
    return 'Er is een onbekende fout opgetreden';
  }
  
  /// Get user-friendly message for generic error codes
  static String _getGenericErrorMessage(String errorCode) {
    if (errorCode.contains('network')) {
      return 'Netwerkfout, controleer je verbinding';
    }
    if (errorCode.contains('timeout')) {
      return 'Verzoek duurde te lang, probeer opnieuw';
    }
    if (errorCode.contains('invalid')) {
      return 'Ongeldige gegevens ingevoerd';
    }
    if (errorCode.contains('cancelled')) {
      return 'Actie geannuleerd';
    }
    
    return 'Er is een technische fout opgetreden';
  }
  
  /// Handle and log Firebase errors gracefully
  static Future<T?> handleFirebaseOperation<T>(
    Future<T> operation, {
    String? context,
    T? fallbackValue,
    bool silent = false,
  }) async {
    try {
      return await operation;
    } catch (error) {
      if (!silent) {
        final message = handleFirebaseError(error, context: context);
        if (kDebugMode) {
          debugPrint('🚨 Firebase operation failed [$context]: $message');
        }
      }
      return fallbackValue;
    }
  }
  
  /// Check if error is due to missing index
  static bool isMissingIndexError(Object error) {
    if (error is FirebaseException) {
      return error.code == 'failed-precondition' && 
             error.message?.contains('index') == true;
    }
    return false;
  }
  
  /// Check if error is related to permissions
  static bool isPermissionError(Object error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied' || 
             error.code == 'unauthenticated';
    }
    return false;
  }
  
  /// Check if error is network related
  static bool isNetworkError(Object error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' || 
             error.code == 'deadline-exceeded' ||
             error.code == 'auth/network-request-failed';
    }
    return error.toString().toLowerCase().contains('network');
  }
}