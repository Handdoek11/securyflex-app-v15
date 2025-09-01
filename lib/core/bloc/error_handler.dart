import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:equatable/equatable.dart';

/// Comprehensive error class for SecuryFlex with Dutch localization
/// Provides consistent error handling across all BLoCs and services
class AppError extends Equatable {
  final String code;
  final String message;
  final String? details;
  final DateTime timestamp;
  final ErrorSeverity severity;
  final ErrorCategory category;
  
  AppError({
    required this.code,
    required this.message,
    this.details,
    DateTime? timestamp,
    this.severity = ErrorSeverity.medium,
    this.category = ErrorCategory.general,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Get Dutch localized error message based on error code
  String get localizedMessage {
    switch (code) {
      // Authentication errors
      case 'auth_failed':
      case 'wrong-password':
      case 'user-not-found':
        return 'Inloggen mislukt. Controleer uw e-mailadres en wachtwoord.';
      case 'email-already-in-use':
        return 'Dit e-mailadres is al in gebruik. Probeer in te loggen.';
      case 'weak-password':
        return 'Wachtwoord is te zwak. Gebruik minimaal 6 tekens.';
      case 'invalid-email':
        return 'Ongeldig e-mailadres. Controleer de invoer.';
      case 'user-disabled':
        return 'Account is uitgeschakeld. Neem contact op met support.';
      case 'too-many-requests':
        return 'Te veel inlogpogingen. Probeer later opnieuw.';
      
      // Network errors
      case 'network_error':
      case 'network-request-failed':
        return 'Netwerkfout. Controleer uw internetverbinding.';
      case 'timeout':
        return 'Verbinding verlopen. Probeer opnieuw.';
      
      // Permission errors
      case 'permission_denied':
      case 'permission-denied':
        return 'Geen toegang. Controleer uw rechten.';
      case 'unauthenticated':
        return 'Niet ingelogd. Log eerst in.';
      
      // Job-related errors
      case 'job_not_found':
        return 'Opdracht niet gevonden of niet meer beschikbaar.';
      case 'application_failed':
        return 'Sollicitatie mislukt. Probeer opnieuw.';
      case 'already_applied':
        return 'U heeft al gesolliciteerd op deze opdracht.';
      case 'job_expired':
        return 'Deze opdracht is verlopen.';
      case 'insufficient_qualifications':
        return 'U voldoet niet aan de vereiste kwalificaties.';
      
      // Profile errors
      case 'profile_update_failed':
        return 'Profiel bijwerken mislukt. Probeer opnieuw.';
      case 'invalid_profile_data':
        return 'Ongeldige profielgegevens. Controleer de invoer.';
      case 'profile_not_found':
        return 'Profiel niet gevonden.';
      
      // File upload errors
      case 'file_upload_failed':
        return 'Bestand uploaden mislukt. Probeer opnieuw.';
      case 'file_too_large':
        return 'Bestand is te groot. Maximaal 10MB toegestaan.';
      case 'invalid_file_type':
        return 'Ongeldig bestandstype. Alleen PDF, JPG, PNG toegestaan.';
      
      // Planning/Calendar errors
      case 'planning_conflict':
        return 'Planning conflict. U heeft al een afspraak op dit tijdstip.';
      case 'invalid_date_range':
        return 'Ongeldige datumbereik. Controleer de datums.';
      case 'shift_not_found':
        return 'Dienst niet gevonden.';
      
      // Chat errors
      case 'message_send_failed':
        return 'Bericht verzenden mislukt. Probeer opnieuw.';
      case 'conversation_not_found':
        return 'Gesprek niet gevonden.';
      
      // Certificate errors
      case 'certificate_not_found':
        return 'Certificaat niet gevonden.';
      case 'invalid_certificate_format':
        return 'Ongeldig certificaatformaat.';
      case 'certificate_expired':
        return 'Certificaat is verlopen.';
      case 'document_upload_failed':
        return 'Document upload mislukt.';
      case 'verification_failed':
        return 'Certificaat verificatie mislukt.';
      case 'insufficient_permissions':
        return 'Onvoldoende rechten.';
      case 'rate_limit_exceeded':
        return 'Te veel verzoeken, probeer later opnieuw.';
      case 'unsupported_file_type':
        return 'Bestandstype niet ondersteund.';
      case 'certificate_validation_failed':
        return 'Certificaat validatie mislukt.';
      
      // General errors
      case 'unknown_error':
        return 'Onbekende fout opgetreden. Probeer opnieuw.';
      case 'server_error':
        return 'Serverfout. Probeer later opnieuw.';
      case 'maintenance_mode':
        return 'Systeem in onderhoud. Probeer later opnieuw.';
      case 'feature_not_available':
        return 'Functie tijdelijk niet beschikbaar.';
      
      default:
        return message.isNotEmpty ? message : 'Er is een fout opgetreden.';
    }
  }
  
  /// Get user-friendly action suggestion in Dutch
  String get actionSuggestion {
    switch (category) {
      case ErrorCategory.network:
        return 'Controleer uw internetverbinding en probeer opnieuw.';
      case ErrorCategory.authentication:
        return 'Log opnieuw in of neem contact op met support.';
      case ErrorCategory.permission:
        return 'Controleer uw rechten of neem contact op met uw beheerder.';
      case ErrorCategory.validation:
        return 'Controleer uw invoer en probeer opnieuw.';
      case ErrorCategory.server:
        return 'Probeer later opnieuw of neem contact op met support.';
      case ErrorCategory.service:
        return 'De service is tijdelijk niet beschikbaar. Probeer later opnieuw.';
      case ErrorCategory.general:
        return 'Probeer opnieuw of neem contact op met support als het probleem aanhoudt.';
    }
  }
  
  /// Check if error should be reported to crash analytics
  bool get shouldReport {
    return severity == ErrorSeverity.high || 
           category == ErrorCategory.server ||
           code == 'unknown_error';
  }
  
  /// Convert various exception types to AppError
  /// Delegates to ErrorHandler.fromException for consistency
  static AppError fromException(Object exception, [StackTrace? stackTrace]) {
    return ErrorHandler.fromException(exception);
  }
  
  /// Create a copy with updated properties
  AppError copyWith({
    String? code,
    String? message,
    String? details,
    DateTime? timestamp,
    ErrorSeverity? severity,
    ErrorCategory? category,
  }) {
    return AppError(
      code: code ?? this.code,
      message: message ?? this.message,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      severity: severity ?? this.severity,
      category: category ?? this.category,
    );
  }
  
  @override
  List<Object?> get props => [code, message, details, timestamp, severity, category];
  
  @override
  String toString() => 'AppError(code: $code, message: $message, severity: $severity)';
}

/// Error severity levels for prioritizing error handling
enum ErrorSeverity {
  low,    // Minor issues, user can continue
  medium, // Moderate issues, some functionality affected
  high,   // Critical issues, major functionality broken
}

/// Error categories for better error classification
enum ErrorCategory {
  authentication,
  network,
  permission,
  validation,
  server,
  service,
  general,
}

/// Centralized error handler for all BLoCs in SecuryFlex
class ErrorHandler {
  /// Handle BLoC errors with logging and analytics
  static void handleBlocError(BlocBase bloc, Object error, StackTrace stackTrace) {
    // Log error for debugging
    debugPrint('🔴 BLoC Error in ${bloc.runtimeType}: $error');
    if (kDebugMode) {
      debugPrint('StackTrace: $stackTrace');
    }
    
    // Convert to AppError if needed
    final appError = error is AppError ? error : fromException(error);
    
    // Report critical errors in production
    if (kReleaseMode && appError.shouldReport) {
      _reportError(bloc.runtimeType.toString(), appError, stackTrace);
    }
    
    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('🔴 Localized: ${appError.localizedMessage}');
      debugPrint('🔴 Suggestion: ${appError.actionSuggestion}');
    }
  }
  
  /// Convert various exception types to AppError
  static AppError fromException(Object exception) {
    if (exception is AppError) {
      return exception;
    }
    
    if (exception is FirebaseAuthException) {
      return AppError(
        code: exception.code,
        message: exception.message ?? 'Authentication error',
        details: exception.toString(),
        category: ErrorCategory.authentication,
        severity: _getAuthErrorSeverity(exception.code),
      );
    }
    
    if (exception is FirebaseException) {
      return AppError(
        code: exception.code,
        message: exception.message ?? 'Firebase error',
        details: exception.toString(),
        category: _getFirebaseErrorCategory(exception.code),
        severity: ErrorSeverity.medium,
      );
    }
    
    if (exception is FormatException) {
      return AppError(
        code: 'format_error',
        message: 'Invalid data format',
        details: exception.toString(),
        category: ErrorCategory.validation,
        severity: ErrorSeverity.low,
      );
    }
    
    if (exception is TimeoutException) {
      return AppError(
        code: 'timeout',
        message: 'Operation timed out',
        details: exception.toString(),
        category: ErrorCategory.network,
        severity: ErrorSeverity.medium,
      );
    }
    
    // Generic exception handling
    return AppError(
      code: 'unknown_error',
      message: exception.toString(),
      details: exception.toString(),
      category: ErrorCategory.general,
      severity: ErrorSeverity.medium,
    );
  }
  
  /// Get error severity for Firebase Auth exceptions
  static ErrorSeverity _getAuthErrorSeverity(String code) {
    switch (code) {
      case 'user-disabled':
      case 'too-many-requests':
        return ErrorSeverity.high;
      case 'wrong-password':
      case 'user-not-found':
      case 'email-already-in-use':
        return ErrorSeverity.medium;
      default:
        return ErrorSeverity.low;
    }
  }
  
  /// Get error category for Firebase exceptions
  static ErrorCategory _getFirebaseErrorCategory(String code) {
    if (code.contains('permission') || code.contains('unauthenticated')) {
      return ErrorCategory.permission;
    }
    if (code.contains('network') || code.contains('unavailable')) {
      return ErrorCategory.network;
    }
    return ErrorCategory.server;
  }
  
  /// Report error to crash analytics (placeholder for Firebase Crashlytics)
  static void _reportError(String blocName, AppError error, StackTrace stackTrace) {
    // TODO: Implement Firebase Crashlytics reporting
    // FirebaseCrashlytics.instance.recordError(
    //   'BLoC Error in $blocName: ${error.code}',
    //   stackTrace,
    //   fatal: error.severity == ErrorSeverity.high,
    //   information: [
    //     'Error Code: ${error.code}',
    //     'Message: ${error.message}',
    //     'Category: ${error.category}',
    //     'Severity: ${error.severity}',
    //     'Timestamp: ${error.timestamp}',
    //   ],
    // );
  }
}

/// Timeout exception for network operations
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  const TimeoutException(this.message, this.timeout);
  
  @override
  String toString() => 'TimeoutException: $message (timeout: ${timeout.inSeconds}s)';
}
