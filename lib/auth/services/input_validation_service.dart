
import 'package:flutter/foundation.dart';
import 'aes_gcm_crypto_service.dart';

/// Comprehensive input validation service with security-first approach
/// Implements OWASP validation guidelines for Dutch business requirements
class InputValidationService {
  // Security patterns for validation
  static final RegExp _alphanumericPattern = RegExp(r'^[a-zA-Z0-9\s\-_\.]+$');
  static final RegExp _dutchNamePattern = RegExp(r'^[a-zA-Z\s\-\.]+$');
  static final RegExp _emailPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp _dutchPostalCodePattern = RegExp(r'^[1-9][0-9]{3}[A-Z]{2}$');
  static final RegExp _dutchPhonePattern = RegExp(r'^(\+31|0)[1-9][0-9]{8}$');
  
  // Certificate patterns
  static final Map<String, RegExp> _certificatePatterns = {
    'wpbr': RegExp(r'^WPBR-[0-9]{6}$', caseSensitive: false),
    'vca': RegExp(r'^VCA-[0-9]{8}$', caseSensitive: false),
    'bhv': RegExp(r'^BHV-[0-9]{7}$', caseSensitive: false),
    'ehbo': RegExp(r'^EHBO-[0-9]{6}$', caseSensitive: false),
  };
  
  // KvK (Dutch Chamber of Commerce) pattern
  static final RegExp _kvkPattern = RegExp(r'^[0-9]{8}$');
  
  // BSN (Dutch Social Security Number) pattern
  static final RegExp _bsnPattern = RegExp(r'^[0-9]{9}$');
  
  // SQL Injection patterns
  static final List<RegExp> _sqlInjectionPatterns = [
    RegExp(r"'", caseSensitive: false),
    RegExp(r"(select|insert|update|delete|drop|create|alter|union|script)", caseSensitive: false),
    RegExp(r"(or|and)\s+(true|false)", caseSensitive: false),
    RegExp(r"--", caseSensitive: false),
    RegExp(r"(xp_|sp_|fn_)", caseSensitive: false),
  ];
  
  // XSS patterns
  static final List<RegExp> _xssPatterns = [
    RegExp(r"<\s*script[^>]*>.*?<\s*/\s*script\s*>", caseSensitive: false, dotAll: true),
    RegExp(r"javascript\s*:", caseSensitive: false),
    RegExp(r"on\w+\s*=", caseSensitive: false),
    RegExp(r"<\s*iframe[^>]*>", caseSensitive: false),
    RegExp(r"<\s*object[^>]*>", caseSensitive: false),
    RegExp(r"<\s*embed[^>]*>", caseSensitive: false),
    RegExp(r"<\s*link[^>]*>", caseSensitive: false),
    RegExp(r"<\s*meta[^>]*>", caseSensitive: false),
  ];
  
  // Command injection patterns
  static final List<RegExp> _commandInjectionPatterns = [
    RegExp(r"[;&|`\$\(\){}]", caseSensitive: false),
    RegExp(r"(cmd|command|powershell|bash|sh|exec|system|eval)\s*\(", caseSensitive: false),
    RegExp(r"(rm|del|format|fdisk|kill|pkill)\s", caseSensitive: false),
  ];
  
  /// Validate certificate number with comprehensive security checks
  static Future<ValidationResult> validateCertificateNumber(String? input, String certificateType) async {
    try {
      if (input == null || input.isEmpty) {
        return ValidationResult.invalid(
          'Certificaatnummer is verplicht',
          errorCode: 'required_field',
        );
      }
      
      // Security checks first
      final securityCheck = await _performSecurityChecks(input, 'certificate_number');
      if (!securityCheck.isValid) {
        return securityCheck;
      }
      
      // Length validation
      if (input.length < 6 || input.length > 20) {
        return ValidationResult.invalid(
          'Certificaatnummer moet tussen 6 en 20 karakters zijn',
          errorCode: 'invalid_length',
        );
      }
      
      // Format validation based on certificate type
      final pattern = _certificatePatterns[certificateType.toLowerCase()];
      if (pattern == null) {
        return ValidationResult.invalid(
          'Onbekend certificaattype: $certificateType',
          errorCode: 'unknown_certificate_type',
        );
      }
      
      final cleanInput = input.toUpperCase().trim();
      if (!pattern.hasMatch(cleanInput)) {
        return ValidationResult.invalid(
          'Ongeldig $certificateType certificaatnummer formaat. Verwacht: ${_getCertificateFormat(certificateType)}',
          errorCode: 'invalid_format',
        );
      }
      
      return ValidationResult.valid(cleanInput);
      
    } catch (e) {
      return ValidationResult.invalid(
        'Validatiefout bij certificaatnummer',
        errorCode: 'validation_error',
      );
    }
  }
  
  /// Validate Dutch BSN (Burgerservicenummer) with elfproef
  static Future<ValidationResult> validateBSN(String? input, {bool allowEncrypted = true}) async {
    try {
      if (input == null || input.isEmpty) {
        return ValidationResult.valid(''); // BSN is optional
      }
      
      // Allow encrypted BSN values
      if (allowEncrypted && (input.startsWith('ENC:') || input.startsWith('BSN_AES256_V1:'))) {
        return ValidationResult.valid(input);
      }
      
      // Security checks
      final securityCheck = await _performSecurityChecks(input, 'bsn');
      if (!securityCheck.isValid) {
        return securityCheck;
      }
      
      // Remove any spaces or hyphens
      final cleanInput = input.replaceAll(RegExp(r'[\s-]'), '');
      
      // Must be exactly 9 digits
      if (!_bsnPattern.hasMatch(cleanInput)) {
        return ValidationResult.invalid(
          'BSN moet precies 9 cijfers bevatten',
          errorCode: 'invalid_format',
        );
      }
      
      // Validate BSN checksum (elfproef)
      if (!_validateBSNChecksum(cleanInput)) {
        return ValidationResult.invalid(
          'Ongeldig BSN nummer (checksum fout)',
          errorCode: 'invalid_checksum',
        );
      }
      
      return ValidationResult.valid(cleanInput);
      
    } catch (e) {
      return ValidationResult.invalid(
        'Validatiefout bij BSN',
        errorCode: 'validation_error',
      );
    }
  }
  
  /// Validate Dutch name with special character support
  static Future<ValidationResult> validateDutchName(String? input, {required String fieldName}) async {
    try {
      if (input == null || input.isEmpty) {
        return ValidationResult.invalid(
          '$fieldName is verplicht',
          errorCode: 'required_field',
        );
      }
      
      // Security checks
      final securityCheck = await _performSecurityChecks(input, 'dutch_name');
      if (!securityCheck.isValid) {
        return securityCheck;
      }
      
      // Length validation
      if (input.length < 2) {
        return ValidationResult.invalid(
          '$fieldName moet minimaal 2 karakters bevatten',
          errorCode: 'too_short',
        );
      }
      
      if (input.length > 100) {
        return ValidationResult.invalid(
          '$fieldName mag maximaal 100 karakters bevatten',
          errorCode: 'too_long',
        );
      }
      
      // Dutch name pattern validation
      if (!_dutchNamePattern.hasMatch(input)) {
        return ValidationResult.invalid(
          '$fieldName bevat ongeldige karakters',
          errorCode: 'invalid_characters',
        );
      }
      
      // Additional validation for suspicious patterns
      if (_containsSuspiciousContent(input)) {
        return ValidationResult.invalid(
          '$fieldName bevat verdachte inhoud',
          errorCode: 'suspicious_content',
        );
      }
      
      return ValidationResult.valid(input.trim());
      
    } catch (e) {
      return ValidationResult.invalid(
        'Validatiefout bij $fieldName',
        errorCode: 'validation_error',
      );
    }
  }
  
  /// Validate KvK (Chamber of Commerce) number
  static Future<ValidationResult> validateKvKNumber(String? input) async {
    try {
      if (input == null || input.isEmpty) {
        return ValidationResult.invalid(
          'KvK nummer is verplicht',
          errorCode: 'required_field',
        );
      }
      
      // Security checks
      final securityCheck = await _performSecurityChecks(input, 'kvk_number');
      if (!securityCheck.isValid) {
        return securityCheck;
      }
      
      // Remove any spaces
      final cleanInput = input.replaceAll(RegExp(r'\s'), '');
      
      // Must be exactly 8 digits
      if (!_kvkPattern.hasMatch(cleanInput)) {
        return ValidationResult.invalid(
          'KvK nummer moet precies 8 cijfers bevatten',
          errorCode: 'invalid_format',
        );
      }
      
      // KvK numbers cannot start with 0
      if (cleanInput.startsWith('0')) {
        return ValidationResult.invalid(
          'KvK nummer kan niet beginnen met 0',
          errorCode: 'invalid_format',
        );
      }
      
      return ValidationResult.valid(cleanInput);
      
    } catch (e) {
      return ValidationResult.invalid(
        'Validatiefout bij KvK nummer',
        errorCode: 'validation_error',
      );
    }
  }
  
  /// Validate email address with comprehensive checks
  static Future<ValidationResult> validateEmail(String? input) async {
    try {
      if (input == null || input.isEmpty) {
        return ValidationResult.invalid(
          'E-mailadres is verplicht',
          errorCode: 'required_field',
        );
      }
      
      // Security checks
      final securityCheck = await _performSecurityChecks(input, 'email');
      if (!securityCheck.isValid) {
        return securityCheck;
      }
      
      // Length validation
      if (input.length > 254) {
        return ValidationResult.invalid(
          'E-mailadres is te lang (maximaal 254 karakters)',
          errorCode: 'too_long',
        );
      }
      
      // Basic format validation
      if (!_emailPattern.hasMatch(input)) {
        return ValidationResult.invalid(
          'Ongeldig e-mailadres formaat',
          errorCode: 'invalid_format',
        );
      }
      
      // Additional security checks for email
      if (_containsEmailThreats(input)) {
        return ValidationResult.invalid(
          'E-mailadres bevat verdachte inhoud',
          errorCode: 'suspicious_content',
        );
      }
      
      return ValidationResult.valid(input.toLowerCase().trim());
      
    } catch (e) {
      return ValidationResult.invalid(
        'Validatiefout bij e-mailadres',
        errorCode: 'validation_error',
      );
    }
  }
  
  /// Validate Dutch postal code
  static Future<ValidationResult> validateDutchPostalCode(String? input) async {
    try {
      if (input == null || input.isEmpty) {
        return ValidationResult.invalid(
          'Postcode is verplicht',
          errorCode: 'required_field',
        );
      }
      
      // Security checks
      final securityCheck = await _performSecurityChecks(input, 'postal_code');
      if (!securityCheck.isValid) {
        return securityCheck;
      }
      
      // Remove spaces and convert to uppercase
      final cleanInput = input.replaceAll(RegExp(r'\s'), '').toUpperCase();
      
      // Dutch postal code format: 1234AB
      if (!_dutchPostalCodePattern.hasMatch(cleanInput)) {
        return ValidationResult.invalid(
          'Ongeldige Nederlandse postcode (formaat: 1234AB)',
          errorCode: 'invalid_format',
        );
      }
      
      return ValidationResult.valid(cleanInput);
      
    } catch (e) {
      return ValidationResult.invalid(
        'Validatiefout bij postcode',
        errorCode: 'validation_error',
      );
    }
  }
  
  /// Validate Dutch phone number
  static Future<ValidationResult> validateDutchPhone(String? input) async {
    try {
      if (input == null || input.isEmpty) {
        return ValidationResult.invalid(
          'Telefoonnummer is verplicht',
          errorCode: 'required_field',
        );
      }
      
      // Security checks
      final securityCheck = await _performSecurityChecks(input, 'phone_number');
      if (!securityCheck.isValid) {
        return securityCheck;
      }
      
      // Remove spaces, hyphens, and parentheses
      final cleanInput = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      
      // Dutch phone number validation
      if (!_dutchPhonePattern.hasMatch(cleanInput)) {
        return ValidationResult.invalid(
          'Ongeldig Nederlands telefoonnummer',
          errorCode: 'invalid_format',
        );
      }
      
      return ValidationResult.valid(cleanInput);
      
    } catch (e) {
      return ValidationResult.invalid(
        'Validatiefout bij telefoonnummer',
        errorCode: 'validation_error',
      );
    }
  }
  
  /// Validate generic text input with security checks
  static Future<ValidationResult> validateTextInput(
    String? input, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 255,
    bool required = true,
    bool allowSpecialChars = false,
  }) async {
    try {
      if (input == null || input.isEmpty) {
        if (required) {
          return ValidationResult.invalid(
            '$fieldName is verplicht',
            errorCode: 'required_field',
          );
        }
        return ValidationResult.valid('');
      }
      
      // Security checks
      final securityCheck = await _performSecurityChecks(input, fieldName.toLowerCase());
      if (!securityCheck.isValid) {
        return securityCheck;
      }
      
      // Length validation
      if (input.length < minLength) {
        return ValidationResult.invalid(
          '$fieldName moet minimaal $minLength karakters bevatten',
          errorCode: 'too_short',
        );
      }
      
      if (input.length > maxLength) {
        return ValidationResult.invalid(
          '$fieldName mag maximaal $maxLength karakters bevatten',
          errorCode: 'too_long',
        );
      }
      
      // Character pattern validation
      if (!allowSpecialChars && !_alphanumericPattern.hasMatch(input)) {
        return ValidationResult.invalid(
          '$fieldName bevat ongeldige karakters',
          errorCode: 'invalid_characters',
        );
      }
      
      return ValidationResult.valid(input.trim());
      
    } catch (e) {
      return ValidationResult.invalid(
        'Validatiefout bij $fieldName',
        errorCode: 'validation_error',
      );
    }
  }
  
  /// Validate file upload data
  static Future<ValidationResult> validateFileUpload(
    String fileName,
    int fileSize,
    List<int> fileHeader, {
    List<String> allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
    int maxSizeBytes = 10485760, // 10MB
  }) async {
    try {
      // Security checks on filename
      final securityCheck = await _performSecurityChecks(fileName, 'file_name');
      if (!securityCheck.isValid) {
        return securityCheck;
      }
      
      // File name validation
      if (fileName.isEmpty) {
        return ValidationResult.invalid(
          'Bestandsnaam is verplicht',
          errorCode: 'required_field',
        );
      }
      
      if (fileName.length > 255) {
        return ValidationResult.invalid(
          'Bestandsnaam is te lang',
          errorCode: 'filename_too_long',
        );
      }
      
      // Check for dangerous file names
      if (_isDangerousFileName(fileName)) {
        return ValidationResult.invalid(
          'Bestandsnaam is niet toegestaan',
          errorCode: 'dangerous_filename',
        );
      }
      
      // Extension validation
      final extension = fileName.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        return ValidationResult.invalid(
          'Bestandstype niet toegestaan. Toegestaan: ${allowedExtensions.join(', ')}',
          errorCode: 'invalid_file_type',
        );
      }
      
      // Size validation
      if (fileSize <= 0) {
        return ValidationResult.invalid(
          'Bestand is leeg',
          errorCode: 'empty_file',
        );
      }
      
      if (fileSize > maxSizeBytes) {
        final maxSizeMB = maxSizeBytes ~/ (1024 * 1024);
        return ValidationResult.invalid(
          'Bestand is te groot (maximaal ${maxSizeMB}MB)',
          errorCode: 'file_too_large',
        );
      }
      
      // Header validation (magic numbers)
      if (!_isValidFileHeader(fileHeader, extension)) {
        return ValidationResult.invalid(
          'Bestand inhoud komt niet overeen met bestandstype',
          errorCode: 'invalid_file_header',
        );
      }
      
      return ValidationResult.valid(fileName);
      
    } catch (e) {
      return ValidationResult.invalid(
        'Validatiefout bij bestand',
        errorCode: 'validation_error',
      );
    }
  }
  
  /// Comprehensive security checks for all inputs
  static Future<ValidationResult> _performSecurityChecks(String input, String fieldType) async {
    try {
      // Check for SQL injection patterns
      for (final pattern in _sqlInjectionPatterns) {
        if (pattern.hasMatch(input)) {
          await _logSecurityIncident('sql_injection_attempt', fieldType, input);
          return ValidationResult.invalid(
            'Invoer bevat onveilige karakters',
            errorCode: 'security_violation',
            securityThreat: 'sql_injection',
          );
        }
      }
      
      // Check for XSS patterns
      for (final pattern in _xssPatterns) {
        if (pattern.hasMatch(input)) {
          await _logSecurityIncident('xss_attempt', fieldType, input);
          return ValidationResult.invalid(
            'Invoer bevat onveilige HTML/JavaScript',
            errorCode: 'security_violation',
            securityThreat: 'xss',
          );
        }
      }
      
      // Check for command injection patterns
      for (final pattern in _commandInjectionPatterns) {
        if (pattern.hasMatch(input)) {
          await _logSecurityIncident('command_injection_attempt', fieldType, input);
          return ValidationResult.invalid(
            'Invoer bevat verdachte karakters',
            errorCode: 'security_violation',
            securityThreat: 'command_injection',
          );
        }
      }
      
      // Check for excessively long input (DoS protection)
      if (input.length > 10000) {
        await _logSecurityIncident('oversized_input', fieldType, input.length.toString());
        return ValidationResult.invalid(
          'Invoer is te lang',
          errorCode: 'input_too_long',
          securityThreat: 'dos_attempt',
        );
      }
      
      // Check for suspicious encoding
      if (_containsSuspiciousEncoding(input)) {
        await _logSecurityIncident('suspicious_encoding', fieldType, input);
        return ValidationResult.invalid(
          'Invoer bevat ongeldige karaktercodering',
          errorCode: 'invalid_encoding',
          securityThreat: 'encoding_attack',
        );
      }
      
      return ValidationResult.valid('security_check_passed');
      
    } catch (e) {
      debugPrint('Security check error: $e');
      return ValidationResult.invalid(
        'Beveiligingsvalidatie mislukt',
        errorCode: 'security_check_failed',
      );
    }
  }
  
  // Helper methods for validation
  
  static bool _validateBSNChecksum(String bsn) {
    if (bsn.length != 9) return false;
    
    final digits = bsn.split('').map(int.parse).toList();
    int sum = 0;
    
    for (int i = 0; i < 8; i++) {
      sum += digits[i] * (9 - i);
    }
    
    final remainder = sum % 11;
    final checkDigit = remainder < 2 ? remainder : 11 - remainder;
    
    return digits[8] == checkDigit;
  }
  
  static String _getCertificateFormat(String type) {
    switch (type.toLowerCase()) {
      case 'wpbr':
        return 'WPBR-123456';
      case 'vca':
        return 'VCA-12345678';
      case 'bhv':
        return 'BHV-1234567';
      case 'ehbo':
        return 'EHBO-123456';
      default:
        return 'ONBEKEND-FORMAAT';
    }
  }
  
  static bool _containsSuspiciousContent(String input) {
    final suspiciousPatterns = [
      'eval(', 'exec(', 'system(', 'shell_exec(',
      '<script', 'javascript:', 'data:text/html',
      'file://', 'ftp://', '\\\\',
    ];
    
    final lowerInput = input.toLowerCase();
    return suspiciousPatterns.any((pattern) => lowerInput.contains(pattern));
  }
  
  static bool _containsEmailThreats(String email) {
    final threatPatterns = [
      '+', // Email aliasing that might bypass filters
      './', '../', // Directory traversal
      '@.', // Invalid domain patterns
      '..', // Multiple dots
    ];
    
    return threatPatterns.any((pattern) => email.contains(pattern));
  }
  
  static bool _isDangerousFileName(String fileName) {
    final dangerousPatterns = [
      RegExp(r'^\.|^\.\.', caseSensitive: false), // Hidden files, traversal
      RegExp(r'\.(exe|bat|cmd|com|scr|pif|vbs|js|jar)$', caseSensitive: false), // Executables
      RegExp(r'[<>:"|?*]'), // Invalid filename characters
      RegExp(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(\.|$)', caseSensitive: false), // Windows reserved names
    ];
    
    return dangerousPatterns.any((pattern) => pattern.hasMatch(fileName));
  }
  
  static bool _isValidFileHeader(List<int> header, String extension) {
    if (header.length < 4) return false;
    
    switch (extension.toLowerCase()) {
      case 'pdf':
        return header.length >= 4 && 
               header[0] == 0x25 && header[1] == 0x50 && 
               header[2] == 0x44 && header[3] == 0x46; // %PDF
      case 'jpg':
      case 'jpeg':
        return header.length >= 4 && 
               header[0] == 0xFF && header[1] == 0xD8 && 
               header[2] == 0xFF; // JPEG magic
      case 'png':
        return header.length >= 8 && 
               header[0] == 0x89 && header[1] == 0x50 && 
               header[2] == 0x4E && header[3] == 0x47 && 
               header[4] == 0x0D && header[5] == 0x0A && 
               header[6] == 0x1A && header[7] == 0x0A; // PNG signature
      default:
        return true; // Unknown extension, assume valid
    }
  }
  
  static bool _containsSuspiciousEncoding(String input) {
    try {
      // Check for unusual Unicode sequences that might be encoding attacks
      final unusual = RegExp(r'[\u0000-\u001F\u007F-\u009F\uFEFF\uFFFE\uFFFF]');
      if (unusual.hasMatch(input)) return true;
      
      // Check for mixed writing systems (potential homograph attacks)
      final hasCyrillic = RegExp(r'[\u0400-\u04FF]').hasMatch(input);
      final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(input);
      if (hasCyrillic && hasLatin) return true;
      
      // Check for excessive URL encoding
      final encodedChars = RegExp(r'%[0-9A-Fa-f]{2}').allMatches(input);
      if (encodedChars.length > input.length * 0.3) return true; // More than 30% encoded
      
      return false;
    } catch (e) {
      return true; // If we can't validate encoding, assume suspicious
    }
  }
  
  static Future<void> _logSecurityIncident(String incidentType, String fieldType, String inputSample) async {
    try {
      // In production, this would send to security monitoring system
      debugPrint('SECURITY INCIDENT: $incidentType in $fieldType');
      debugPrint('Sample: ${inputSample.length > 100 ? "${inputSample.substring(0, 100)}..." : inputSample}');
      
      // Hash the input for logging (privacy protection)
      final hashedInput = await AESGCMCryptoService.generateSecureHash(inputSample, 'audit_context');
      debugPrint('Hashed input: $hashedInput');
      
      // TODO: Send to Firebase security audit logs
    } catch (e) {
      debugPrint('Failed to log security incident: $e');
    }
  }
}

/// Validation result container
class ValidationResult {
  final bool isValid;
  final String? validatedValue;
  final String? errorMessage;
  final String? errorCode;
  final String? securityThreat;
  
  const ValidationResult._({
    required this.isValid,
    this.validatedValue,
    this.errorMessage,
    this.errorCode,
    this.securityThreat,
  });
  
  factory ValidationResult.valid(String validatedValue) {
    return ValidationResult._(
      isValid: true,
      validatedValue: validatedValue,
    );
  }
  
  factory ValidationResult.invalid(
    String errorMessage, {
    String? errorCode,
    String? securityThreat,
  }) {
    return ValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
      securityThreat: securityThreat,
    );
  }
  
  /// Convert to user-friendly Dutch error message
  String get userFriendlyMessage {
    if (isValid) return '';
    
    switch (errorCode) {
      case 'required_field':
        return errorMessage ?? 'Dit veld is verplicht';
      case 'invalid_format':
        return errorMessage ?? 'Ongeldige invoer';
      case 'too_short':
        return errorMessage ?? 'Invoer is te kort';
      case 'too_long':
        return errorMessage ?? 'Invoer is te lang';
      case 'invalid_characters':
        return errorMessage ?? 'Bevat ongeldige karakters';
      case 'security_violation':
        return 'Invoer bevat onveilige inhoud';
      case 'suspicious_content':
        return 'Invoer bevat verdachte inhoud';
      default:
        return errorMessage ?? 'Validatiefout';
    }
  }
  
  /// Check if this is a security-related validation failure
  bool get isSecurityThreat => securityThreat != null;
}