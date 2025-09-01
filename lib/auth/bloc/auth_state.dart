import 'package:firebase_auth/firebase_auth.dart';
import '../../core/bloc/base_bloc.dart';
import '../../core/bloc/error_handler.dart';
import '../models/enhanced_auth_models.dart';

/// Base class for all authentication states in SecuryFlex
abstract class AuthState extends BaseState {
  const AuthState();
}

/// Initial authentication state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Authentication operation in progress
class AuthLoading extends AuthState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage;
  
  const AuthLoading({this.loadingMessage});
  
  @override
  List<Object?> get props => [loadingMessage];
  
  @override
  String toString() => 'AuthLoading(message: $loadingMessage)';
}

/// User is authenticated and logged in
class AuthAuthenticated extends AuthState {
  final User? firebaseUser;
  final String userId;
  final String userType;
  final String userName;
  final String userEmail;
  final Map<String, dynamic> userData;
  final bool isDemo;
  
  const AuthAuthenticated({
    this.firebaseUser,
    required this.userId,
    required this.userType,
    required this.userName,
    required this.userEmail,
    required this.userData,
    this.isDemo = false,
  });
  
  /// Get Dutch role display name
  String get userRoleDisplayName {
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
  
  /// Check if user has specific role
  bool hasRole(String role) {
    return userType.toLowerCase() == role.toLowerCase();
  }
  
  /// Check if user is a guard
  bool get isGuard => hasRole('guard');
  
  /// Check if user is a company
  bool get isCompany => hasRole('company');
  
  /// Check if user is an admin
  bool get isAdmin => hasRole('admin');
  
  /// Get user's full display information
  String get fullDisplayInfo {
    if (isDemo) {
      return '$userName ($userRoleDisplayName) - Demo Mode';
    }
    return '$userName ($userRoleDisplayName)';
  }
  
  /// Create a copy with updated properties
  AuthAuthenticated copyWith({
    User? firebaseUser,
    String? userId,
    String? userType,
    String? userName,
    String? userEmail,
    Map<String, dynamic>? userData,
    bool? isDemo,
  }) {
    return AuthAuthenticated(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userData: userData ?? this.userData,
      isDemo: isDemo ?? this.isDemo,
    );
  }
  
  @override
  List<Object?> get props => [
    firebaseUser?.uid,
    userId,
    userType,
    userName,
    userEmail,
    userData,
    isDemo,
  ];
  
  @override
  String toString() => 'AuthAuthenticated(userId: $userId, userType: $userType, userName: $userName, isDemo: $isDemo)';
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
  
  @override
  String toString() => 'AuthUnauthenticated()';
}

/// Authentication error occurred
class AuthError extends AuthState with ErrorStateMixin {
  @override
  final AppError error;
  
  const AuthError(this.error);
  
  @override
  List<Object> get props => [error];
  
  @override
  String toString() => 'AuthError(error: ${error.localizedMessage})';
}

/// Registration completed successfully
class AuthRegistrationSuccess extends AuthState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final String email;
  final String userType;
  
  const AuthRegistrationSuccess({
    required this.email,
    required this.userType,
    this.successMessage = 'Account succesvol aangemaakt! Je kunt nu inloggen.',
  });
  
  @override
  List<Object> get props => [email, userType, successMessage];
  
  @override
  String toString() => 'AuthRegistrationSuccess(email: $email, userType: $userType)';
}

/// Profile update completed successfully
class AuthProfileUpdateSuccess extends AuthState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final Map<String, dynamic> updatedData;
  
  const AuthProfileUpdateSuccess({
    required this.updatedData,
    this.successMessage = 'Profiel succesvol bijgewerkt',
  });
  
  @override
  List<Object> get props => [updatedData, successMessage];
  
  @override
  String toString() => 'AuthProfileUpdateSuccess(updatedData: $updatedData)';
}

/// Email validation result
class AuthEmailValidation extends AuthState {
  final String email;
  final bool isValid;
  final String? errorMessage;
  
  const AuthEmailValidation({
    required this.email,
    required this.isValid,
    this.errorMessage,
  });
  
  String get dutchErrorMessage {
    if (isValid) return '';
    
    if (email.isEmpty) {
      return 'E-mailadres is verplicht';
    } else if (!isValid) {
      return 'Ongeldig e-mailadres format';
    }
    
    return errorMessage ?? 'Ongeldig e-mailadres';
  }
  
  @override
  List<Object?> get props => [email, isValid, errorMessage];
  
  @override
  String toString() => 'AuthEmailValidation(email: $email, isValid: $isValid)';
}

/// Password validation result
class AuthPasswordValidation extends AuthState {
  final String password;
  final bool isValid;
  final String? errorMessage;
  
  const AuthPasswordValidation({
    required this.password,
    required this.isValid,
    this.errorMessage,
  });
  
  String get dutchErrorMessage {
    if (isValid) return '';
    
    if (password.isEmpty) {
      return 'Wachtwoord is verplicht';
    } else if (password.length < 6) {
      return 'Wachtwoord moet minimaal 6 tekens bevatten';
    }
    
    return errorMessage ?? 'Ongeldig wachtwoord';
  }
  
  @override
  List<Object?> get props => [password.length, isValid, errorMessage]; // Don't expose actual password
  
  @override
  String toString() => 'AuthPasswordValidation(passwordLength: ${password.length}, isValid: $isValid)';
}

/// Enhanced KvK validation in progress with detailed status
class AuthKvKValidating extends AuthState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage;
  
  final String kvkNumber;
  final String? currentStep;
  final int? attemptNumber;
  
  const AuthKvKValidating(
    this.kvkNumber, {
    this.loadingMessage,
    this.currentStep,
    this.attemptNumber,
  });
  
  /// Get Dutch loading message with details
  String get detailedLoadingMessage {
    if (loadingMessage != null) return loadingMessage!;
    
    String base = 'KvK nummer valideren...';
    if (currentStep != null) {
      base += ' ($currentStep)';
    }
    if (attemptNumber != null && attemptNumber! > 1) {
      base += ' (poging $attemptNumber)';
    }
    return base;
  }
  
  @override
  List<Object?> get props => [kvkNumber, loadingMessage, currentStep, attemptNumber];
  
  @override
  String toString() => 'AuthKvKValidating(kvkNumber: $kvkNumber, step: $currentStep, attempt: $attemptNumber)';
}

/// Enhanced KvK validation result with security industry information
class AuthKvKValidation extends AuthState {
  final String kvkNumber;
  final bool isValid;
  final Map<String, dynamic>? kvkData;
  final String? errorMessage;
  final bool isSecurityEligible;
  final double eligibilityScore;
  final List<String> eligibilityReasons;
  
  const AuthKvKValidation({
    required this.kvkNumber,
    required this.isValid,
    this.kvkData,
    this.errorMessage,
    this.isSecurityEligible = false,
    this.eligibilityScore = 0.0,
    this.eligibilityReasons = const [],
  });
  
  String get dutchErrorMessage {
    if (isValid) return '';
    
    if (kvkNumber.isEmpty) {
      return 'KvK nummer is verplicht';
    }
    
    return errorMessage ?? 'KvK nummer is ongeldig';
  }
  
  /// Get company name from validated data
  String? get companyName => kvkData?['companyName'];
  
  /// Get company display name
  String? get displayName => kvkData?['displayName'];
  
  /// Check if company is active
  bool get isActive => kvkData?['isActive'] == true;
  
  /// Get security eligibility description in Dutch
  String get securityEligibilityDescription {
    if (!isSecurityEligible) {
      return 'Niet geschikt voor beveiligingsopdrachten';
    }
    final score = (eligibilityScore * 100).toInt();
    return 'Geschikt voor beveiligingsopdrachten ($score% geschiktheid)';
  }
  
  /// Get formatted eligibility reasons for display
  String get formattedEligibilityReasons {
    if (eligibilityReasons.isEmpty) return 'Geen details beschikbaar';
    return eligibilityReasons.map((reason) => '• $reason').join('\n');
  }
  
  @override
  List<Object?> get props => [kvkNumber, isValid, kvkData, errorMessage, isSecurityEligible, eligibilityScore, eligibilityReasons];
  
  @override
  String toString() => 'AuthKvKValidation(kvkNumber: $kvkNumber, isValid: $isValid, companyName: $companyName, securityEligible: $isSecurityEligible)';
}

/// WPBR validation in progress
class AuthWPBRValidating extends AuthState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage = 'WPBR certificaat verifiëren...';
  
  final String wpbrNumber;
  
  const AuthWPBRValidating(this.wpbrNumber);
  
  @override
  List<Object> get props => [wpbrNumber];
  
  @override
  String toString() => 'AuthWPBRValidating(wpbrNumber: $wpbrNumber)';
}

/// WPBR validation result
class AuthWPBRValidation extends AuthState {
  final String wpbrNumber;
  final bool isValid;
  final Map<String, dynamic>? wpbrData;
  final String? errorMessage;
  
  const AuthWPBRValidation({
    required this.wpbrNumber,
    required this.isValid,
    this.wpbrData,
    this.errorMessage,
  });
  
  String get dutchErrorMessage {
    if (isValid) return '';
    
    if (wpbrNumber.isEmpty) {
      return 'WPBR certificaatnummer is verplicht';
    }
    
    return errorMessage ?? 'WPBR certificaat is ongeldig';
  }
  
  /// Get certificate holder name
  String? get holderName => wpbrData?['holderName'];
  
  /// Get certificate status
  String? get status => wpbrData?['status'];
  
  /// Check if certificate is currently valid
  bool get isCurrentlyValid {
    if (!isValid || wpbrData == null) return false;
    
    final expirationDateStr = wpbrData!['expirationDate'];
    if (expirationDateStr != null) {
      final expirationDate = DateTime.tryParse(expirationDateStr);
      if (expirationDate != null) {
        return DateTime.now().isBefore(expirationDate);
      }
    }
    
    return wpbrData!['status'] == 'verified';
  }
  
  @override
  List<Object?> get props => [wpbrNumber, isValid, wpbrData, errorMessage];
  
  @override
  String toString() => 'AuthWPBRValidation(wpbrNumber: $wpbrNumber, isValid: $isValid, holderName: $holderName)';
}

/// Dutch postal code validation result
class AuthPostalCodeValidation extends AuthState {
  final String postalCode;
  final bool isValid;
  final String? formattedPostalCode;
  final String? errorMessage;
  
  const AuthPostalCodeValidation({
    required this.postalCode,
    required this.isValid,
    this.formattedPostalCode,
    this.errorMessage,
  });
  
  String get dutchErrorMessage {
    if (isValid) return '';
    
    if (postalCode.isEmpty) {
      return 'Postcode is verplicht';
    }
    
    return errorMessage ?? 'Postcode heeft onjuist formaat (gebruik: 1234AB)';
  }
  
  @override
  List<Object?> get props => [postalCode, isValid, formattedPostalCode, errorMessage];
  
  @override
  String toString() => 'AuthPostalCodeValidation(postalCode: $postalCode, isValid: $isValid, formatted: $formattedPostalCode)';
}

/// Multiple KvK validation in progress
class AuthMultipleKvKValidating extends AuthState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage;
  
  final List<String> kvkNumbers;
  final int currentIndex;
  
  const AuthMultipleKvKValidating({
    required this.kvkNumbers,
    this.currentIndex = 0,
    this.loadingMessage,
  });
  
  /// Get progress percentage
  double get progress => currentIndex / kvkNumbers.length;
  
  /// Get Dutch progress message
  String get dutchProgressMessage {
    return loadingMessage ?? 'KvK nummers valideren... ($currentIndex van ${kvkNumbers.length})';
  }
  
  @override
  List<Object?> get props => [kvkNumbers, currentIndex, loadingMessage];
  
  @override
  String toString() => 'AuthMultipleKvKValidating(progress: $currentIndex/${kvkNumbers.length})';
}

/// Multiple KvK validation results
class AuthMultipleKvKValidation extends AuthState {
  final Map<String, AuthKvKValidation> results;
  final int successCount;
  final int errorCount;
  
  const AuthMultipleKvKValidation({
    required this.results,
    required this.successCount,
    required this.errorCount,
  });
  
  /// Get Dutch summary message
  String get dutchSummaryMessage {
    final total = successCount + errorCount;
    return '$successCount van $total bedrijven succesvol gevalideerd';
  }
  
  /// Get successful validations
  List<AuthKvKValidation> get successfulValidations {
    return results.values.where((result) => result.isValid).toList();
  }
  
  /// Get failed validations
  List<AuthKvKValidation> get failedValidations {
    return results.values.where((result) => !result.isValid).toList();
  }
  
  /// Get security eligible companies
  List<AuthKvKValidation> get securityEligibleCompanies {
    return results.values.where((result) => result.isSecurityEligible).toList();
  }
  
  @override
  List<Object> get props => [results, successCount, errorCount];
  
  @override
  String toString() => 'AuthMultipleKvKValidation(success: $successCount, errors: $errorCount)';
}

/// Detailed KvK company information
class AuthKvKDetails extends AuthState {
  final String kvkNumber;
  final Map<String, dynamic> companyDetails;
  final bool isSecurityEligible;
  final double eligibilityScore;
  final List<String> businessActivities;
  
  const AuthKvKDetails({
    required this.kvkNumber,
    required this.companyDetails,
    required this.isSecurityEligible,
    required this.eligibilityScore,
    required this.businessActivities,
  });
  
  /// Get company name
  String get companyName => companyDetails['companyName'] ?? 'Onbekend bedrijf';
  
  /// Get formatted address
  String? get formattedAddress {
    final address = companyDetails['address'];
    if (address == null) return null;
    return '${address['street']} ${address['houseNumber']}, ${address['postalCode']} ${address['city']}';
  }
  
  /// Get company age in years
  int? get companyAge {
    final foundationDate = companyDetails['foundationDate'];
    if (foundationDate == null) return null;
    
    final date = DateTime.tryParse(foundationDate.toString());
    if (date == null) return null;
    
    final age = DateTime.now().difference(date);
    return (age.inDays / 365).floor();
  }
  
  @override
  List<Object> get props => [kvkNumber, companyDetails, isSecurityEligible, eligibilityScore, businessActivities];
  
  @override
  String toString() => 'AuthKvKDetails(kvkNumber: $kvkNumber, companyName: $companyName)';
}

/// Security eligibility calculation result
class AuthSecurityEligibilityResult extends AuthState {
  final String kvkNumber;
  final bool isEligible;
  final double score;
  final List<String> reasons;
  final List<String> requirements;
  
  const AuthSecurityEligibilityResult({
    required this.kvkNumber,
    required this.isEligible,
    required this.score,
    required this.reasons,
    required this.requirements,
  });
  
  /// Get Dutch eligibility message
  String get dutchMessage {
    if (isEligible) {
      return 'Bedrijf is geschikt voor beveiligingsopdrachten (${(score * 100).toInt()}% geschiktheid)';
    } else {
      return 'Bedrijf voldoet niet aan de vereisten voor beveiligingsopdrachten';
    }
  }
  
  /// Get formatted reasons
  String get formattedReasons {
    return reasons.map((reason) => '✓ $reason').join('\n');
  }
  
  /// Get formatted requirements
  String get formattedRequirements {
    return requirements.map((req) => '✗ $req').join('\n');
  }
  
  @override
  List<Object> get props => [kvkNumber, isEligible, score, reasons, requirements];
  
  @override
  String toString() => 'AuthSecurityEligibilityResult(kvkNumber: $kvkNumber, eligible: $isEligible, score: ${(score * 100).toInt()}%)';
}

/// Company search results
class AuthCompanySearchResults extends AuthState {
  final String searchQuery;
  final List<Map<String, dynamic>> companies;
  final int totalResults;
  
  const AuthCompanySearchResults({
    required this.searchQuery,
    required this.companies,
    required this.totalResults,
  });
  
  /// Get Dutch results message
  String get dutchResultsMessage {
    if (totalResults == 0) {
      return 'Geen bedrijven gevonden voor "$searchQuery"';
    }
    return '$totalResults bedrijven gevonden voor "$searchQuery"';
  }
  
  /// Get security eligible companies from results
  List<Map<String, dynamic>> get securityEligibleCompanies {
    return companies.where((company) => company['isSecurityEligible'] == true).toList();
  }
  
  @override
  List<Object> get props => [searchQuery, companies, totalResults];
  
  @override
  String toString() => 'AuthCompanySearchResults(query: $searchQuery, found: $totalResults)';
}

/// KvK service statistics
class AuthKvKStats extends AuthState {
  final Map<String, dynamic> cacheStats;
  final Map<String, dynamic> serviceStats;
  final DateTime timestamp;
  
  const AuthKvKStats({
    required this.cacheStats,
    required this.serviceStats,
    required this.timestamp,
  });
  
  /// Get cache hit rate percentage
  int get cacheHitRatePercentage {
    final hitRate = cacheStats['cache']?['hitRate'] ?? 0.0;
    return (hitRate * 100).round();
  }
  
  /// Get total cached entries
  int get totalCachedEntries {
    return cacheStats['cache']?['totalEntries'] ?? 0;
  }
  
  @override
  List<Object> get props => [cacheStats, serviceStats, timestamp];
  
  @override
  String toString() => 'AuthKvKStats(entries: $totalCachedEntries, hitRate: $cacheHitRatePercentage%)';
}

// ============================================================================
// ENHANCED AUTHENTICATION STATES - Two-Factor, Biometric, Security
// ============================================================================

/// Two-factor authentication enabled successfully
class AuthTwoFactorEnabled extends AuthState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final TwoFactorMethod method;
  final TwoFactorConfig config;
  
  const AuthTwoFactorEnabled({
    required this.method,
    required this.config,
    this.successMessage = 'Tweefactor authenticatie succesvol ingeschakeld',
  });
  
  @override
  List<Object> get props => [method, config, successMessage];
  
  @override
  String toString() => 'AuthTwoFactorEnabled(method: ${method.value})';
}

/// Two-factor authentication disabled successfully
class AuthTwoFactorDisabled extends AuthState with SuccessStateMixin {
  @override
  final String successMessage;
  
  const AuthTwoFactorDisabled({
    this.successMessage = 'Tweefactor authenticatie uitgeschakeld',
  });
  
  @override
  List<Object> get props => [successMessage];
  
  @override
  String toString() => 'AuthTwoFactorDisabled()';
}

/// Two-factor authentication verification result
class AuthTwoFactorVerified extends AuthState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final TwoFactorMethod method;
  final bool wasBackupCode;
  final int? remainingBackupCodes;
  
  const AuthTwoFactorVerified({
    required this.method,
    this.wasBackupCode = false,
    this.remainingBackupCodes,
    this.successMessage = 'Tweefactor authenticatie geverifieerd',
  });
  
  String get dutchSuccessMessage {
    if (wasBackupCode && remainingBackupCodes != null) {
      if (remainingBackupCodes == 0) {
        return 'Backup code geverifieerd. Geen backup codes meer beschikbaar.';
      } else if (remainingBackupCodes! <= 2) {
        return 'Backup code geverifieerd. Nog maar $remainingBackupCodes backup codes over.';
      } else {
        return 'Backup code geverifieerd. $remainingBackupCodes backup codes beschikbaar.';
      }
    }
    
    switch (method) {
      case TwoFactorMethod.sms:
        return 'SMS verificatie succesvol';
      case TwoFactorMethod.totp:
        return 'Authenticator code geverifieerd';
      case TwoFactorMethod.backupCode:
        return 'Backup code geverifieerd';
    }
  }
  
  @override
  List<Object?> get props => [method, wasBackupCode, remainingBackupCodes, successMessage];
  
  @override
  String toString() => 'AuthTwoFactorVerified(method: ${method.value}, backup: $wasBackupCode)';
}

/// TOTP setup with secret and QR code
class AuthTOTPSetup extends AuthState {
  final String secret;
  final String qrCodeData;
  final String userEmail;
  final List<BackupCode> backupCodes;
  
  const AuthTOTPSetup({
    required this.secret,
    required this.qrCodeData,
    required this.userEmail,
    required this.backupCodes,
  });
  
  @override
  List<Object> get props => [secret, qrCodeData, userEmail, backupCodes];
  
  @override
  String toString() => 'AuthTOTPSetup(email: $userEmail, codes: ${backupCodes.length})';
}

/// Backup codes generated
class AuthBackupCodesGenerated extends AuthState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final List<BackupCode> backupCodes;
  
  const AuthBackupCodesGenerated({
    required this.backupCodes,
    this.successMessage = 'Backup codes gegenereerd',
  });
  
  String get dutchInstructions => 
    'Bewaar deze backup codes op een veilige plaats. '
    'Elke code kan maar één keer gebruikt worden. '
    'Gebruik ze om toegang te krijgen als je je telefoon kwijt bent.';
  
  @override
  List<Object> get props => [backupCodes, successMessage];
  
  @override
  String toString() => 'AuthBackupCodesGenerated(count: ${backupCodes.length})';
}

/// SMS verification code sent
class AuthSMSCodeSent extends AuthState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final String verificationId;
  final String obfuscatedPhoneNumber;
  final int cooldownSeconds;
  final bool isResend;
  
  const AuthSMSCodeSent({
    required this.verificationId,
    required this.obfuscatedPhoneNumber,
    this.cooldownSeconds = 60,
    this.isResend = false,
    String? successMessage,
  }) : successMessage = successMessage ?? 
    'Verificatiecode verzonden naar $obfuscatedPhoneNumber';
  
  String get dutchCooldownMessage => 
    'Je kunt over $cooldownSeconds seconden een nieuwe code aanvragen';
  
  @override
  List<Object> get props => [verificationId, obfuscatedPhoneNumber, cooldownSeconds, isResend, successMessage];
  
  @override
  String toString() => 'AuthSMSCodeSent(phone: $obfuscatedPhoneNumber, resend: $isResend)';
}

/// Biometric authentication enabled
class AuthBiometricEnabled extends AuthState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final BiometricConfig config;
  final List<BiometricType> enabledTypes;
  
  const AuthBiometricEnabled({
    required this.config,
    required this.enabledTypes,
    this.successMessage = 'Biometrische authenticatie ingeschakeld',
  });
  
  String get dutchEnabledTypes => enabledTypes.map((t) => t.dutchName).join(', ');
  
  @override
  List<Object> get props => [config, enabledTypes, successMessage];
  
  @override
  String toString() => 'AuthBiometricEnabled(types: $dutchEnabledTypes)';
}

/// Biometric authentication disabled
class AuthBiometricDisabled extends AuthState with SuccessStateMixin {
  @override
  final String successMessage;
  
  const AuthBiometricDisabled({
    this.successMessage = 'Biometrische authenticatie uitgeschakeld',
  });
  
  @override
  List<Object> get props => [successMessage];
  
  @override
  String toString() => 'AuthBiometricDisabled()';
}

/// Biometric authentication successful
class AuthBiometricAuthenticated extends AuthState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final BiometricType authenticationType;
  final DateTime timestamp;
  
  const AuthBiometricAuthenticated({
    required this.authenticationType,
    required this.timestamp,
    this.successMessage = 'Biometrische authenticatie succesvol',
  });
  
  String get dutchAuthType => authenticationType.dutchName;
  
  @override
  List<Object> get props => [authenticationType, timestamp, successMessage];
  
  @override
  String toString() => 'AuthBiometricAuthenticated(type: ${authenticationType.name})';
}

/// Biometric availability status
class AuthBiometricAvailability extends AuthState {
  final bool isAvailable;
  final bool isSupported;
  final List<BiometricType> availableTypes;
  final String? reason;
  final String? errorCode;
  
  const AuthBiometricAvailability({
    required this.isAvailable,
    required this.isSupported,
    this.availableTypes = const [],
    this.reason,
    this.errorCode,
  });
  
  String get dutchStatus {
    if (!isSupported) return 'Biometrische authenticatie niet ondersteund';
    if (!isAvailable) return reason ?? 'Biometrische authenticatie niet beschikbaar';
    if (availableTypes.isEmpty) return 'Geen biometrische gegevens ingesteld';
    return 'Beschikbaar: ${availableTypes.map((t) => t.dutchName).join(', ')}';
  }
  
  @override
  List<Object?> get props => [isAvailable, isSupported, availableTypes, reason, errorCode];
  
  @override
  String toString() => 'AuthBiometricAvailability(available: $isAvailable, types: ${availableTypes.length})';
}

/// Security configuration state
class AuthSecurityConfig extends AuthState {
  final TwoFactorConfig twoFactorConfig;
  final BiometricConfig biometricConfig;
  final AuthenticationLevel currentLevel;
  final List<AuthSecurityEvent> recentEvents;
  final Map<String, dynamic> preferences;
  
  const AuthSecurityConfig({
    required this.twoFactorConfig,
    required this.biometricConfig,
    required this.currentLevel,
    this.recentEvents = const [],
    this.preferences = const {},
  });
  
  /// Get security status in Dutch
  String get dutchSecurityStatus {
    switch (currentLevel) {
      case AuthenticationLevel.basic:
        return 'Basis beveiliging (alleen wachtwoord)';
      case AuthenticationLevel.twoFactor:
        return 'Verhoogde beveiliging (wachtwoord + tweede factor)';
      case AuthenticationLevel.biometric:
        return 'Biometrische beveiliging';
      case AuthenticationLevel.combined:
        return 'Maximale beveiliging (alle beveiligingslagen actief)';
    }
  }
  
  /// Get security recommendations in Dutch
  List<String> get dutchRecommendations {
    final recommendations = <String>[];
    
    if (!twoFactorConfig.isEnabled) {
      recommendations.add('Schakel tweefactor authenticatie in voor extra beveiliging');
    }
    
    if (!biometricConfig.isEnabled && biometricConfig.isSupported) {
      recommendations.add('Gebruik biometrische authenticatie voor snelle en veilige toegang');
    }
    
    if (twoFactorConfig.backupCodesRemaining <= 2 && twoFactorConfig.isEnabled) {
      recommendations.add('Genereer nieuwe backup codes');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Je beveiligingsinstellingen zijn optimaal geconfigureerd');
    }
    
    return recommendations;
  }
  
  @override
  List<Object> get props => [twoFactorConfig, biometricConfig, currentLevel, recentEvents, preferences];
  
  @override
  String toString() => 'AuthSecurityConfig(level: ${currentLevel.dutchName})';
}

/// Security event logged
class AuthSecurityEventLogged extends AuthState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final AuthSecurityEvent event;
  
  const AuthSecurityEventLogged({
    required this.event,
    this.successMessage = 'Beveiligingsgebeurtenis geregistreerd',
  });
  
  @override
  List<Object> get props => [event, successMessage];
  
  @override
  String toString() => 'AuthSecurityEventLogged(type: ${event.type.value})';
}

/// Advanced authentication loading state
class AuthAdvancedLoading extends AuthState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage;
  
  final String operation;
  final Map<String, dynamic>? metadata;
  
  const AuthAdvancedLoading({
    required this.operation,
    this.loadingMessage,
    this.metadata,
  });
  
  String get dutchLoadingMessage {
    switch (operation) {
      case 'enable_2fa':
        return 'Tweefactor authenticatie inschakelen...';
      case 'disable_2fa':
        return 'Tweefactor authenticatie uitschakelen...';
      case 'verify_2fa':
        return 'Verificatiecode controleren...';
      case 'generate_totp':
        return 'TOTP secret genereren...';
      case 'generate_backup_codes':
        return 'Backup codes genereren...';
      case 'send_sms':
        return 'SMS verificatiecode versturen...';
      case 'setup_biometric':
        return 'Biometrische authenticatie instellen...';
      case 'biometric_auth':
        return 'Biometrische verificatie...';
      case 'check_biometric_availability':
        return 'Biometrische ondersteuning controleren...';
      default:
        return loadingMessage ?? 'Bezig met laden...';
    }
  }
  
  @override
  List<Object?> get props => [operation, loadingMessage, metadata];
  
  @override
  String toString() => 'AuthAdvancedLoading(operation: $operation)';
}
