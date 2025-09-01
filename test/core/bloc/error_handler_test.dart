import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/core/bloc/error_handler.dart';

void main() {
  group('AppError Tests', () {
    test('creates AppError with required parameters', () {
      final error = AppError(
        code: 'test_error',
        message: 'Test error message',
      );
      
      expect(error.code, equals('test_error'));
      expect(error.message, equals('Test error message'));
      expect(error.details, isNull);
      expect(error.severity, equals(ErrorSeverity.medium));
      expect(error.category, equals(ErrorCategory.general));
      expect(error.timestamp, isA<DateTime>());
    });

    test('creates AppError with all parameters', () {
      final timestamp = DateTime.now();
      final error = AppError(
        code: 'auth_failed',
        message: 'Authentication failed',
        details: 'Invalid credentials',
        timestamp: timestamp,
        severity: ErrorSeverity.high,
        category: ErrorCategory.authentication,
      );
      
      expect(error.code, equals('auth_failed'));
      expect(error.message, equals('Authentication failed'));
      expect(error.details, equals('Invalid credentials'));
      expect(error.timestamp, equals(timestamp));
      expect(error.severity, equals(ErrorSeverity.high));
      expect(error.category, equals(ErrorCategory.authentication));
    });

    group('Dutch Localized Messages', () {
      test('provides correct Dutch message for auth errors', () {
        final error = AppError(code: 'auth_failed', message: 'Auth failed');
        expect(error.localizedMessage,
               equals('Inloggen mislukt. Controleer uw e-mailadres en wachtwoord.'));
      });

      test('provides correct Dutch message for network errors', () {
        final error = AppError(code: 'network_error', message: 'Network failed');
        expect(error.localizedMessage,
               equals('Netwerkfout. Controleer uw internetverbinding.'));
      });

      test('provides correct Dutch message for permission errors', () {
        final error = AppError(code: 'permission_denied', message: 'Access denied');
        expect(error.localizedMessage,
               equals('Geen toegang. Controleer uw rechten.'));
      });

      test('provides correct Dutch message for job errors', () {
        final error = AppError(code: 'job_not_found', message: 'Job not found');
        expect(error.localizedMessage,
               equals('Opdracht niet gevonden of niet meer beschikbaar.'));
      });

      test('provides correct Dutch message for application errors', () {
        final error = AppError(code: 'application_failed', message: 'Application failed');
        expect(error.localizedMessage,
               equals('Sollicitatie mislukt. Probeer opnieuw.'));
      });

      test('provides correct Dutch message for file upload errors', () {
        final error = AppError(code: 'file_too_large', message: 'File too large');
        expect(error.localizedMessage,
               equals('Bestand is te groot. Maximaal 10MB toegestaan.'));
      });

      test('falls back to original message for unknown codes', () {
        final error = AppError(code: 'unknown_code', message: 'Original message');
        expect(error.localizedMessage, equals('Original message'));
      });

      test('provides default message when original is empty', () {
        final error = AppError(code: 'unknown_code', message: '');
        expect(error.localizedMessage, equals('Er is een fout opgetreden.'));
      });
    });

    group('Action Suggestions', () {
      test('provides network action suggestion', () {
        final error = AppError(
          code: 'network_error',
          message: 'Network failed',
          category: ErrorCategory.network,
        );
        expect(error.actionSuggestion,
               equals('Controleer uw internetverbinding en probeer opnieuw.'));
      });

      test('provides authentication action suggestion', () {
        final error = AppError(
          code: 'auth_failed',
          message: 'Auth failed',
          category: ErrorCategory.authentication,
        );
        expect(error.actionSuggestion,
               equals('Log opnieuw in of neem contact op met support.'));
      });

      test('provides permission action suggestion', () {
        final error = AppError(
          code: 'permission_denied',
          message: 'Access denied',
          category: ErrorCategory.permission,
        );
        expect(error.actionSuggestion,
               equals('Controleer uw rechten of neem contact op met uw beheerder.'));
      });

      test('provides validation action suggestion', () {
        final error = AppError(
          code: 'invalid_input',
          message: 'Invalid input',
          category: ErrorCategory.validation,
        );
        expect(error.actionSuggestion,
               equals('Controleer uw invoer en probeer opnieuw.'));
      });

      test('provides server action suggestion', () {
        final error = AppError(
          code: 'server_error',
          message: 'Server error',
          category: ErrorCategory.server,
        );
        expect(error.actionSuggestion,
               equals('Probeer later opnieuw of neem contact op met support.'));
      });

      test('provides general action suggestion', () {
        final error = AppError(
          code: 'general_error',
          message: 'General error',
          category: ErrorCategory.general,
        );
        expect(error.actionSuggestion,
               equals('Probeer opnieuw of neem contact op met support als het probleem aanhoudt.'));
      });
    });

    group('Error Reporting', () {
      test('high severity errors should be reported', () {
        final error = AppError(
          code: 'critical_error',
          message: 'Critical error',
          severity: ErrorSeverity.high,
        );
        expect(error.shouldReport, isTrue);
      });

      test('server errors should be reported', () {
        final error = AppError(
          code: 'server_error',
          message: 'Server error',
          category: ErrorCategory.server,
        );
        expect(error.shouldReport, isTrue);
      });

      test('unknown errors should be reported', () {
        final error = AppError(
          code: 'unknown_error',
          message: 'Unknown error',
        );
        expect(error.shouldReport, isTrue);
      });

      test('low severity errors should not be reported', () {
        final error = AppError(
          code: 'minor_error',
          message: 'Minor error',
          severity: ErrorSeverity.low,
        );
        expect(error.shouldReport, isFalse);
      });
    });

    test('copyWith creates new instance with updated properties', () {
      final originalError = AppError(
        code: 'original_code',
        message: 'Original message',
        severity: ErrorSeverity.low,
      );

      final updatedError = originalError.copyWith(
        code: 'updated_code',
        severity: ErrorSeverity.high,
      );

      expect(updatedError.code, equals('updated_code'));
      expect(updatedError.message, equals('Original message')); // Unchanged
      expect(updatedError.severity, equals(ErrorSeverity.high));
    });

    test('toString provides useful debug information', () {
      final error = AppError(
        code: 'test_error',
        message: 'Test message',
        severity: ErrorSeverity.medium,
      );

      final string = error.toString();
      expect(string, contains('test_error'));
      expect(string, contains('Test message'));
      expect(string, contains('medium'));
    });

    test('Equatable implementation works correctly', () {
      final timestamp = DateTime.now();

      final error1 = AppError(
        code: 'test_error',
        message: 'Test message',
        timestamp: timestamp,
      );

      final error2 = AppError(
        code: 'test_error',
        message: 'Test message',
        timestamp: timestamp,
      );

      final error3 = AppError(
        code: 'different_error',
        message: 'Test message',
        timestamp: timestamp,
      );

      expect(error1, equals(error2));
      expect(error1, isNot(equals(error3)));
    });
  });

  group('ErrorHandler Tests', () {
    group('fromException', () {
      test('returns AppError unchanged', () {
        final originalError = AppError(code: 'test', message: 'test');
        final result = ErrorHandler.fromException(originalError);
        expect(result, equals(originalError));
      });

      test('converts FormatException correctly', () {
        final formatException = FormatException('Invalid format');
        final result = ErrorHandler.fromException(formatException);
        
        expect(result.code, equals('format_error'));
        expect(result.message, equals('Invalid data format'));
        expect(result.category, equals(ErrorCategory.validation));
        expect(result.severity, equals(ErrorSeverity.low));
      });

      test('converts TimeoutException correctly', () {
        final timeoutException = TimeoutException('Operation timed out', Duration(seconds: 30));
        final result = ErrorHandler.fromException(timeoutException);
        
        expect(result.code, equals('timeout'));
        expect(result.message, equals('Operation timed out'));
        expect(result.category, equals(ErrorCategory.network));
        expect(result.severity, equals(ErrorSeverity.medium));
      });

      test('converts generic exception correctly', () {
        final genericException = Exception('Generic error');
        final result = ErrorHandler.fromException(genericException);
        
        expect(result.code, equals('unknown_error'));
        expect(result.category, equals(ErrorCategory.general));
        expect(result.severity, equals(ErrorSeverity.medium));
      });
    });
  });

  group('TimeoutException Tests', () {
    test('creates TimeoutException with message and duration', () {
      const timeout = Duration(seconds: 30);
      final exception = TimeoutException('Operation timed out', timeout);
      
      expect(exception.message, equals('Operation timed out'));
      expect(exception.timeout, equals(timeout));
    });

    test('toString provides useful information', () {
      const timeout = Duration(seconds: 30);
      final exception = TimeoutException('Operation timed out', timeout);
      final string = exception.toString();
      
      expect(string, contains('Operation timed out'));
      expect(string, contains('30s'));
    });
  });

  group('Error Enums Tests', () {
    test('ErrorSeverity enum has all expected values', () {
      expect(ErrorSeverity.values, hasLength(3));
      expect(ErrorSeverity.values, contains(ErrorSeverity.low));
      expect(ErrorSeverity.values, contains(ErrorSeverity.medium));
      expect(ErrorSeverity.values, contains(ErrorSeverity.high));
    });

    test('ErrorCategory enum has all expected values', () {
      expect(ErrorCategory.values, hasLength(6));
      expect(ErrorCategory.values, contains(ErrorCategory.authentication));
      expect(ErrorCategory.values, contains(ErrorCategory.network));
      expect(ErrorCategory.values, contains(ErrorCategory.permission));
      expect(ErrorCategory.values, contains(ErrorCategory.validation));
      expect(ErrorCategory.values, contains(ErrorCategory.server));
      expect(ErrorCategory.values, contains(ErrorCategory.general));
    });
  });
}
