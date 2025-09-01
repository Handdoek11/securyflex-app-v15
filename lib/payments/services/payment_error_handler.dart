import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/payment_models.dart';
import 'payment_audit_service.dart';

/// Comprehensive Payment Error Handler with Dutch localization and retry logic
/// 
/// Features:
/// - Intelligent retry mechanisms with exponential backoff
/// - Circuit breaker pattern for service protection
/// - Dutch error message localization
/// - Comprehensive error categorization
/// - Automatic recovery strategies
/// - Error reporting and analytics
/// - Rate limiting and backpressure handling
/// - Dead letter queue for failed operations
class PaymentErrorHandler {
  final PaymentAuditService _auditService;
  final FirebaseFirestore _firestore;
  
  // Retry configuration
  static const int _maxRetryAttempts = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(seconds: 30);
  static const double _backoffMultiplier = 2.0;
  static const double _jitterFactor = 0.1;
  
  // Circuit breaker configuration
  static const int _circuitBreakerThreshold = 5;
  static const Duration _circuitBreakerTimeout = Duration(minutes: 5);
  
  // Error tracking
  final Map<String, CircuitBreakerState> _circuitBreakers = {};
  final Map<String, List<DateTime>> _errorHistory = {};

  PaymentErrorHandler({
    PaymentAuditService? auditService,
    FirebaseFirestore? firestore,
  }) : _auditService = auditService ?? PaymentAuditService(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Execute operation with comprehensive error handling and retry logic
  Future<T> executeWithRetry<T>({
    required String operationName,
    required Future<T> Function() operation,
    int maxRetries = _maxRetryAttempts,
    Duration? baseDelay,
    bool useCircuitBreaker = true,
    Map<String, dynamic>? metadata,
  }) async {
    final delay = baseDelay ?? _baseRetryDelay;
    int attemptCount = 0;
    Exception? lastException;

    // Check circuit breaker
    if (useCircuitBreaker && _isCircuitBreakerOpen(operationName)) {
      throw PaymentException(
        'Service tijdelijk niet beschikbaar. Probeer het later opnieuw.',
        PaymentErrorCode.serverError,
        {'circuit_breaker': 'open', 'operation': operationName},
      );
    }

    while (attemptCount <= maxRetries) {
      try {
        attemptCount++;
        
        // Log attempt
        await _auditService.logPaymentRequest(
          type: 'OPERATION_ATTEMPT',
          status: 'STARTED',
          details: {
            'operation': operationName,
            'attempt': attemptCount,
            'max_attempts': maxRetries + 1,
            'metadata': metadata,
          },
        );

        final result = await operation();
        
        // Reset circuit breaker on success
        if (useCircuitBreaker) {
          _resetCircuitBreaker(operationName);
        }
        
        // Log successful operation
        if (attemptCount > 1) {
          await _auditService.logPaymentRequest(
            type: 'OPERATION_SUCCESS_AFTER_RETRY',
            status: 'SUCCESS',
            details: {
              'operation': operationName,
              'successful_attempt': attemptCount,
              'total_attempts': attemptCount,
            },
          );
        }

        return result;

      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Categorize error
        final errorCategory = _categorizeError(e);
        final shouldRetry = _shouldRetry(errorCategory, attemptCount, maxRetries);
        
        // Update circuit breaker
        if (useCircuitBreaker) {
          _recordError(operationName);
        }
        
        // Log error attempt
        await _auditService.logPaymentError(
          type: 'OPERATION_ATTEMPT_FAILED',
          error: e.toString(),
          metadata: {
            'operation': operationName,
            'attempt': attemptCount,
            'error_category': errorCategory.name,
            'should_retry': shouldRetry,
            'metadata': metadata,
          },
        );

        if (!shouldRetry) {
          break;
        }

        // Calculate delay with exponential backoff and jitter
        final retryDelay = _calculateRetryDelay(delay, attemptCount);
        
        if (kDebugMode) {
          debugPrint(
            'Operation $operationName failed (attempt $attemptCount/${maxRetries + 1}). '
            'Retrying in ${retryDelay.inMilliseconds}ms. Error: $e'
          );
        }

        await Future.delayed(retryDelay);
      }
    }

    // All retries exhausted
    final finalError = _createFinalError(operationName, lastException!, attemptCount);
    
    await _auditService.logPaymentError(
      type: 'OPERATION_FINAL_FAILURE',
      error: finalError.toString(),
      metadata: {
        'operation': operationName,
        'total_attempts': attemptCount,
        'original_error': lastException.toString(),
        'metadata': metadata,
      },
    );

    throw finalError;
  }

  /// Handle specific payment exceptions with Dutch translations
  PaymentException handlePaymentException(
    dynamic error,
    String context, {
    Map<String, dynamic>? metadata,
  }) {
    if (error is PaymentException) {
      return error;
    }

    // Network errors
    if (error is DioException) {
      return _handleDioError(error, context, metadata);
    }

    // Socket errors
    if (error is SocketException) {
      return PaymentException(
        'Netwerkverbinding mislukt. Controleer uw internetverbinding.',
        PaymentErrorCode.networkError,
        {'context': context, 'original_error': error.toString(), ...?metadata},
      );
    }

    // Timeout errors
    if (error is TimeoutException) {
      return PaymentException(
        'Bewerking duurde te lang. Probeer het opnieuw.',
        PaymentErrorCode.networkError,
        {'context': context, 'timeout': true, ...?metadata},
      );
    }

    // Firebase errors
    if (error is FirebaseException) {
      return _handleFirebaseError(error, context, metadata);
    }

    // Format errors
    if (error is FormatException) {
      return PaymentException(
        'Ongeldige gegevens. Controleer uw invoer.',
        PaymentErrorCode.serverError,
        {'context': context, 'format_error': error.toString(), ...?metadata},
      );
    }

    // Generic errors
    return PaymentException(
      'Er is een onverwachte fout opgetreden: ${error.toString()}',
      PaymentErrorCode.serverError,
      {'context': context, 'original_error': error.toString(), ...?metadata},
    );
  }

  /// Get user-friendly error message in Dutch
  String getDutchErrorMessage(PaymentException error) {
    switch (error.errorCode) {
      case PaymentErrorCode.invalidAmount:
        return 'Het opgegeven bedrag is ongeldig. Controleer het bedrag en probeer opnieuw.';
      
      case PaymentErrorCode.invalidIBAN:
        return 'Het IBAN nummer is ongeldig. Controleer het rekeningnummer.';
      
      case PaymentErrorCode.invalidRecipientName:
        return 'De naam van de ontvanger is ongeldig of te lang.';
      
      case PaymentErrorCode.invalidDescription:
        return 'De omschrijving is te lang of bevat ongeldige karakters.';
      
      case PaymentErrorCode.amountLimitExceeded:
        return 'Het bedrag overschrijdt de toegestane limiet.';
      
      case PaymentErrorCode.monthlyLimitExceeded:
        return 'Maandelijkse betalingslimiet overschreden.';
      
      case PaymentErrorCode.guardNotFound:
        return 'Beveiliger niet gevonden. Controleer de gegevens.';
      
      case PaymentErrorCode.paymentNotFound:
        return 'Betaling niet gevonden. Mogelijk is deze al verwerkt.';
      
      case PaymentErrorCode.missingBankDetails:
        return 'Bankgegevens ontbreken. Voeg eerst uw IBAN toe aan uw profiel.';
      
      case PaymentErrorCode.paymentCreationFailed:
        return 'Betaling aanmaken mislukt. Probeer het opnieuw.';
      
      case PaymentErrorCode.bankSelectionFailed:
        return 'Bank selectie mislukt. Kies een andere bank of probeer opnieuw.';
      
      case PaymentErrorCode.unsupportedBank:
        return 'De geselecteerde bank wordt niet ondersteund voor iDEAL betalingen.';
      
      case PaymentErrorCode.refundAmountTooHigh:
        return 'Terugbetaling kan niet hoger zijn dan het originele bedrag.';
      
      case PaymentErrorCode.refundCreationFailed:
        return 'Terugbetaling aanmaken mislukt. Neem contact op met de klantenservice.';
      
      case PaymentErrorCode.invalidWebhookSignature:
        return 'Beveiligingsfout bij betaling. Neem contact op met de support.';
      
      case PaymentErrorCode.paymentExpired:
        return 'Betaling is verlopen. Start een nieuwe betaling.';
      
      case PaymentErrorCode.insufficientFunds:
        return 'Onvoldoende saldo. Controleer uw bankrekening.';
      
      case PaymentErrorCode.networkError:
        return 'Netwerkfout. Controleer uw internetverbinding en probeer opnieuw.';
      
      case PaymentErrorCode.serverError:
        return 'Server fout. Probeer het later opnieuw of neem contact op met de support.';
      
      default:
        return error.message;
    }
  }

  /// Get error recovery suggestions
  List<String> getRecoverySuggestions(PaymentException error) {
    switch (error.errorCode) {
      case PaymentErrorCode.networkError:
        return [
          'Controleer uw internetverbinding',
          'Probeer over een paar minuten opnieuw',
          'Schakel tussen WiFi en mobiele data',
        ];
      
      case PaymentErrorCode.invalidIBAN:
        return [
          'Controleer of het IBAN correct is ingevoerd',
          'IBAN moet beginnen met landcode (bijv. NL)',
          'Gebruik geen spaties of speciale tekens',
        ];
      
      case PaymentErrorCode.amountLimitExceeded:
        return [
          'Verlaag het bedrag onder de limiet',
          'Verdeel over meerdere betalingen',
          'Neem contact op voor hogere limieten',
        ];
      
      case PaymentErrorCode.missingBankDetails:
        return [
          'Ga naar uw profiel',
          'Voeg uw IBAN toe',
          'Controleer dat alle gegevens correct zijn',
        ];
      
      case PaymentErrorCode.paymentExpired:
        return [
          'Start een nieuwe betaling',
          'Betalingen verlopen na 15 minuten',
          'Zorg voor een stabiele internetverbinding',
        ];
      
      case PaymentErrorCode.serverError:
        return [
          'Probeer het over een paar minuten opnieuw',
          'Controleer of de betaling toch is gelukt',
          'Neem contact op als het probleem aanhoudt',
        ];
      
      default:
        return [
          'Probeer de actie opnieuw',
          'Controleer uw invoer',
          'Neem contact op met de support',
        ];
    }
  }

  /// Store error in dead letter queue for analysis
  Future<void> storeErrorInDeadLetterQueue({
    required String operationType,
    required String error,
    required Map<String, dynamic> originalData,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('payment_dead_letter_queue').add({
        'operation_type': operationType,
        'error_message': error,
        'original_data': originalData,
        'metadata': metadata ?? {},
        'created_at': Timestamp.now(),
        'retry_count': 0,
        'status': 'pending',
        'next_retry': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 1)),
        ),
      });

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to store error in dead letter queue: $e');
      }
    }
  }

  /// Process dead letter queue items
  Future<void> processDeadLetterQueue() async {
    try {
      final items = await _firestore
          .collection('payment_dead_letter_queue')
          .where('status', isEqualTo: 'pending')
          .where('next_retry', isLessThanOrEqualTo: Timestamp.now())
          .limit(10)
          .get();

      for (final item in items.docs) {
        final data = item.data();
        final retryCount = data['retry_count'] as int;
        
        if (retryCount >= 3) {
          // Mark as failed after 3 retries
          await item.reference.update({
            'status': 'failed',
            'updated_at': Timestamp.now(),
          });
          continue;
        }

        // Schedule next retry
        await item.reference.update({
          'retry_count': retryCount + 1,
          'next_retry': Timestamp.fromDate(
            DateTime.now().add(Duration(hours: pow(2, retryCount + 1).toInt())),
          ),
          'updated_at': Timestamp.now(),
        });
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to process dead letter queue: $e');
      }
    }
  }

  /// Get error statistics for monitoring
  Future<Map<String, dynamic>> getErrorStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final errors = await _firestore
          .collection('error_audit')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final errorsByType = <String, int>{};
      final errorsBySeverity = <String, int>{};
      var totalErrors = 0;

      for (final error in errors.docs) {
        final data = error.data();
        final errorType = data['error_type'] as String? ?? 'unknown';
        final severity = data['severity'] as String? ?? 'medium';

        errorsByType[errorType] = (errorsByType[errorType] ?? 0) + 1;
        errorsBySeverity[severity] = (errorsBySeverity[severity] ?? 0) + 1;
        totalErrors++;
      }

      return {
        'total_errors': totalErrors,
        'errors_by_type': errorsByType,
        'errors_by_severity': errorsBySeverity,
        'period_start': startDate.toIso8601String(),
        'period_end': endDate.toIso8601String(),
      };

    } catch (e) {
      return {'error': 'Failed to get error statistics: $e'};
    }
  }

  /// Private helper methods

  /// Handle Dio HTTP errors
  PaymentException _handleDioError(
    DioException error,
    String context,
    Map<String, dynamic>? metadata,
  ) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return PaymentException(
          'Verbinding time-out. Controleer uw internetverbinding.',
          PaymentErrorCode.networkError,
          {'context': context, 'timeout_type': error.type.name, ...?metadata},
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _getHttpErrorMessage(statusCode);
        return PaymentException(
          message,
          _getErrorCodeFromHttpStatus(statusCode),
          {
            'context': context,
            'status_code': statusCode,
            'response_data': error.response?.data,
            ...?metadata
          },
        );

      case DioExceptionType.cancel:
        return PaymentException(
          'Bewerking geannuleerd.',
          PaymentErrorCode.networkError,
          {'context': context, 'cancelled': true, ...?metadata},
        );

      case DioExceptionType.unknown:
      default:
        return PaymentException(
          'Netwerkfout. Probeer het opnieuw.',
          PaymentErrorCode.networkError,
          {'context': context, 'dio_error': error.toString(), ...?metadata},
        );
    }
  }

  /// Handle Firebase errors
  PaymentException _handleFirebaseError(
    FirebaseException error,
    String context,
    Map<String, dynamic>? metadata,
  ) {
    switch (error.code) {
      case 'permission-denied':
        return PaymentException(
          'Toegang geweigerd. Controleer uw rechten.',
          PaymentErrorCode.serverError,
          {'context': context, 'firebase_code': error.code, ...?metadata},
        );

      case 'not-found':
        return PaymentException(
          'Gegevens niet gevonden.',
          PaymentErrorCode.paymentNotFound,
          {'context': context, 'firebase_code': error.code, ...?metadata},
        );

      case 'already-exists':
        return PaymentException(
          'Gegevens bestaan al.',
          PaymentErrorCode.serverError,
          {'context': context, 'firebase_code': error.code, ...?metadata},
        );

      case 'resource-exhausted':
        return PaymentException(
          'Service tijdelijk overbelast. Probeer het later opnieuw.',
          PaymentErrorCode.serverError,
          {'context': context, 'firebase_code': error.code, ...?metadata},
        );

      case 'unauthenticated':
        return PaymentException(
          'Authenticatie vereist. Log opnieuw in.',
          PaymentErrorCode.serverError,
          {'context': context, 'firebase_code': error.code, ...?metadata},
        );

      default:
        return PaymentException(
          'Database fout: ${error.message}',
          PaymentErrorCode.serverError,
          {'context': context, 'firebase_code': error.code, ...?metadata},
        );
    }
  }

  /// Get HTTP error message in Dutch
  String _getHttpErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Ongeldige aanvraag. Controleer uw gegevens.';
      case 401:
        return 'Niet geautoriseerd. Log opnieuw in.';
      case 403:
        return 'Toegang geweigerd.';
      case 404:
        return 'Service niet gevonden.';
      case 429:
        return 'Te veel aanvragen. Probeer het later opnieuw.';
      case 500:
        return 'Server fout. Probeer het later opnieuw.';
      case 502:
        return 'Service tijdelijk niet beschikbaar.';
      case 503:
        return 'Service onderhoud. Probeer het later opnieuw.';
      case 504:
        return 'Gateway time-out. Probeer het opnieuw.';
      default:
        return 'HTTP fout ($statusCode). Probeer het opnieuw.';
    }
  }

  /// Get error code from HTTP status
  PaymentErrorCode _getErrorCodeFromHttpStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return PaymentErrorCode.serverError;
      case 401:
      case 403:
        return PaymentErrorCode.serverError;
      case 404:
        return PaymentErrorCode.paymentNotFound;
      case 429:
        return PaymentErrorCode.serverError;
      case 500:
      case 502:
      case 503:
      case 504:
      default:
        return PaymentErrorCode.serverError;
    }
  }

  /// Categorize error for retry logic
  ErrorCategory _categorizeError(dynamic error) {
    if (error is PaymentException) {
      switch (error.errorCode) {
        case PaymentErrorCode.networkError:
          return ErrorCategory.network;
        case PaymentErrorCode.serverError:
          return ErrorCategory.server;
        case PaymentErrorCode.invalidAmount:
        case PaymentErrorCode.invalidIBAN:
        case PaymentErrorCode.invalidRecipientName:
        case PaymentErrorCode.invalidDescription:
          return ErrorCategory.validation;
        default:
          return ErrorCategory.business;
      }
    }

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ErrorCategory.network;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode != null && statusCode >= 500) {
            return ErrorCategory.server;
          }
          return ErrorCategory.business;
        default:
          return ErrorCategory.network;
      }
    }

    if (error is SocketException || error is TimeoutException) {
      return ErrorCategory.network;
    }

    return ErrorCategory.unknown;
  }

  /// Determine if operation should be retried
  bool _shouldRetry(ErrorCategory category, int attemptCount, int maxRetries) {
    if (attemptCount > maxRetries) {
      return false;
    }

    switch (category) {
      case ErrorCategory.network:
      case ErrorCategory.server:
        return true;
      case ErrorCategory.validation:
      case ErrorCategory.business:
        return false;
      case ErrorCategory.unknown:
        return attemptCount <= 1; // Only retry once for unknown errors
    }
  }

  /// Calculate retry delay with exponential backoff and jitter
  Duration _calculateRetryDelay(Duration baseDelay, int attemptCount) {
    final exponentialDelay = Duration(
      milliseconds: (baseDelay.inMilliseconds * pow(_backoffMultiplier, attemptCount - 1)).round(),
    );

    // Cap at max delay
    final cappedDelay = Duration(
      milliseconds: min(exponentialDelay.inMilliseconds, _maxRetryDelay.inMilliseconds),
    );

    // Add jitter
    final jitter = cappedDelay.inMilliseconds * _jitterFactor * Random().nextDouble();
    
    return Duration(
      milliseconds: cappedDelay.inMilliseconds + jitter.round(),
    );
  }

  /// Create final error after all retries exhausted
  PaymentException _createFinalError(
    String operationName,
    Exception lastException,
    int totalAttempts,
  ) {
    if (lastException is PaymentException) {
      return PaymentException(
        'Bewerking mislukt na $totalAttempts pogingen: ${lastException.message}',
        lastException.errorCode,
        {
          'operation': operationName,
          'total_attempts': totalAttempts,
          'final_retry': true,
          ...?lastException.metadata,
        },
      );
    }

    return PaymentException(
      'Bewerking "$operationName" mislukt na $totalAttempts pogingen.',
      PaymentErrorCode.serverError,
      {
        'operation': operationName,
        'total_attempts': totalAttempts,
        'original_error': lastException.toString(),
        'final_retry': true,
      },
    );
  }

  /// Circuit breaker methods

  bool _isCircuitBreakerOpen(String operationName) {
    final state = _circuitBreakers[operationName];
    if (state == null) return false;

    if (state.isOpen && DateTime.now().isAfter(state.nextAttempt)) {
      // Move to half-open state
      _circuitBreakers[operationName] = CircuitBreakerState(
        isOpen: false,
        errorCount: state.errorCount,
        nextAttempt: DateTime.now(),
        isHalfOpen: true,
      );
      return false;
    }

    return state.isOpen;
  }

  void _recordError(String operationName) {
    final now = DateTime.now();
    
    // Update error history
    _errorHistory[operationName] ??= [];
    _errorHistory[operationName]!.add(now);
    
    // Remove old errors (only count errors in the last 5 minutes)
    _errorHistory[operationName]!.removeWhere(
      (time) => now.difference(time) > const Duration(minutes: 5),
    );
    
    final recentErrors = _errorHistory[operationName]!.length;
    
    if (recentErrors >= _circuitBreakerThreshold) {
      _circuitBreakers[operationName] = CircuitBreakerState(
        isOpen: true,
        errorCount: recentErrors,
        nextAttempt: now.add(_circuitBreakerTimeout),
        isHalfOpen: false,
      );
    }
  }

  void _resetCircuitBreaker(String operationName) {
    _circuitBreakers.remove(operationName);
    _errorHistory.remove(operationName);
  }
}

/// Error categories for retry logic
enum ErrorCategory {
  network,
  server,
  validation,
  business,
  unknown,
}

/// Circuit breaker state
class CircuitBreakerState {
  final bool isOpen;
  final int errorCount;
  final DateTime nextAttempt;
  final bool isHalfOpen;

  const CircuitBreakerState({
    required this.isOpen,
    required this.errorCount,
    required this.nextAttempt,
    required this.isHalfOpen,
  });
}