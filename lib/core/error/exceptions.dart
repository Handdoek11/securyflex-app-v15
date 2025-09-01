// Custom exceptions for SecuryFlex application

/// Base exception class for all custom exceptions
abstract class SecuryFlexException implements Exception {
  const SecuryFlexException(this.message, {this.errorCode});

  final String message;
  final String? errorCode;

  @override
  String toString() {
    return errorCode != null 
        ? 'SecuryFlexException($errorCode): $message'
        : 'SecuryFlexException: $message';
  }
}

/// Authentication and authorization related exceptions
class AuthenticationException extends SecuryFlexException {
  const AuthenticationException(super.message, {super.errorCode});
}

class AuthorizationException extends SecuryFlexException {
  const AuthorizationException(super.message, {super.errorCode});
}

/// Validation exceptions for user input
class ValidationException extends SecuryFlexException {
  const ValidationException({
    required this.field,
    required String message,
    this.dutchMessage,
    String? errorCode,
  }) : super(message, errorCode: errorCode);

  final String field;
  final String? dutchMessage;

  String get localizedMessage => dutchMessage ?? message;
}

/// Business logic exceptions for Dutch compliance
class BusinessLogicException extends SecuryFlexException {
  const BusinessLogicException(super.message, {super.errorCode});
}

/// Network and API related exceptions
class NetworkException extends SecuryFlexException {
  const NetworkException(super.message, {super.errorCode});
}

/// GDPR and compliance exceptions
class ComplianceException extends SecuryFlexException {
  const ComplianceException(super.message, {super.errorCode});
}

/// Payment and financial exceptions
class PaymentException extends SecuryFlexException {
  const PaymentException(super.message, {super.errorCode});
}

/// KvK (Chamber of Commerce) related exceptions
class KvKException extends SecuryFlexException {
  const KvKException(super.message, {super.errorCode});
}

/// WPBR certificate related exceptions
class WPBRException extends SecuryFlexException {
  const WPBRException(super.message, {super.errorCode});
}