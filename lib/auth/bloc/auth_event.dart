import '../../core/bloc/base_bloc.dart';
import '../models/enhanced_auth_models.dart';

/// Base class for all authentication events in SecuryFlex
abstract class AuthEvent extends BaseEvent {
  const AuthEvent();
}

/// Initialize authentication state on app start
class AuthInitialize extends AuthEvent {
  const AuthInitialize();
}

/// Login with email and password
class AuthLogin extends AuthEvent {
  final String email;
  final String password;
  
  const AuthLogin({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object> get props => [email, password];
  
  @override
  String toString() => 'AuthLogin(email: $email)';
}

/// Register new user account
class AuthRegister extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String userType;
  final Map<String, dynamic>? additionalData;
  
  const AuthRegister({
    required this.email,
    required this.password,
    required this.name,
    required this.userType,
    this.additionalData,
  });
  
  @override
  List<Object?> get props => [email, password, name, userType, additionalData];
  
  @override
  String toString() => 'AuthRegister(email: $email, name: $name, userType: $userType)';
}

/// Logout current user
class AuthLogout extends AuthEvent {
  const AuthLogout();
}

/// Check current authentication status
class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
}

/// Update user profile information
class AuthUpdateProfile extends AuthEvent {
  final Map<String, dynamic> updates;
  
  const AuthUpdateProfile(this.updates);
  
  @override
  List<Object> get props => [updates];
  
  @override
  String toString() => 'AuthUpdateProfile(updates: $updates)';
}

/// Refresh user data from server
class AuthRefreshUserData extends AuthEvent {
  const AuthRefreshUserData();
}

/// Validate email format
class AuthValidateEmail extends AuthEvent {
  final String email;
  
  const AuthValidateEmail(this.email);
  
  @override
  List<Object> get props => [email];
  
  @override
  String toString() => 'AuthValidateEmail(email: $email)';
}

/// Validate password strength
class AuthValidatePassword extends AuthEvent {
  final String password;
  
  const AuthValidatePassword(this.password);
  
  @override
  List<Object> get props => [password];
  
  @override
  String toString() => 'AuthValidatePassword(password: [HIDDEN])';
}

/// Validate Dutch KvK number with enhanced options
class AuthValidateKvK extends AuthEvent {
  final String kvkNumber;
  final bool requireSecurityEligibility;
  final String? apiKey;
  
  const AuthValidateKvK(
    this.kvkNumber, {
    this.requireSecurityEligibility = false,
    this.apiKey,
  });
  
  @override
  List<Object?> get props => [kvkNumber, requireSecurityEligibility, apiKey];
  
  @override
  String toString() => 'AuthValidateKvK(kvkNumber: $kvkNumber, requireSecurity: $requireSecurityEligibility)';
}

/// Validate multiple KvK numbers in batch
class AuthValidateMultipleKvK extends AuthEvent {
  final List<String> kvkNumbers;
  final String? apiKey;
  
  const AuthValidateMultipleKvK(
    this.kvkNumbers, {
    this.apiKey,
  });
  
  @override
  List<Object?> get props => [kvkNumbers, apiKey];
  
  @override
  String toString() => 'AuthValidateMultipleKvK(count: ${kvkNumbers.length})';
}

/// Get detailed KvK company information
class AuthGetKvKDetails extends AuthEvent {
  final String kvkNumber;
  final String? apiKey;
  
  const AuthGetKvKDetails(
    this.kvkNumber, {
    this.apiKey,
  });
  
  @override
  List<Object?> get props => [kvkNumber, apiKey];
  
  @override
  String toString() => 'AuthGetKvKDetails(kvkNumber: $kvkNumber)';
}

/// Calculate security industry eligibility
class AuthCalculateSecurityEligibility extends AuthEvent {
  final String kvkNumber;
  
  const AuthCalculateSecurityEligibility(this.kvkNumber);
  
  @override
  List<Object> get props => [kvkNumber];
  
  @override
  String toString() => 'AuthCalculateSecurityEligibility(kvkNumber: $kvkNumber)';
}

/// Search companies by name (demo mode)
class AuthSearchCompaniesByName extends AuthEvent {
  final String companyName;
  final int limit;
  
  const AuthSearchCompaniesByName(
    this.companyName, {
    this.limit = 10,
  });
  
  @override
  List<Object> get props => [companyName, limit];
  
  @override
  String toString() => 'AuthSearchCompaniesByName(name: $companyName, limit: $limit)';
}

/// Validate Dutch WPBR certificate
class AuthValidateWPBR extends AuthEvent {
  final String wpbrNumber;
  final String? certificateFilePath;
  
  const AuthValidateWPBR({
    required this.wpbrNumber,
    this.certificateFilePath,
  });
  
  @override
  List<Object?> get props => [wpbrNumber, certificateFilePath];
  
  @override
  String toString() => 'AuthValidateWPBR(wpbrNumber: $wpbrNumber, hasFile: ${certificateFilePath != null})';
}

/// Validate Dutch postal code
class AuthValidatePostalCode extends AuthEvent {
  final String postalCode;
  
  const AuthValidatePostalCode(this.postalCode);
  
  @override
  List<Object> get props => [postalCode];
  
  @override
  String toString() => 'AuthValidatePostalCode(postalCode: $postalCode)';
}

/// Clear KvK validation cache
class AuthClearKvKCache extends AuthEvent {
  const AuthClearKvKCache();
}

/// Get KvK service statistics
class AuthGetKvKStats extends AuthEvent {
  const AuthGetKvKStats();
}

// ============================================================================
// ENHANCED AUTHENTICATION EVENTS - Two-Factor, Biometric, Security
// ============================================================================

/// Enable two-factor authentication
class AuthEnable2FA extends AuthEvent {
  final TwoFactorMethod method;
  final String? phoneNumber; // For SMS 2FA
  
  const AuthEnable2FA({
    required this.method,
    this.phoneNumber,
  });
  
  @override
  List<Object?> get props => [method, phoneNumber];
  
  @override
  String toString() => 'AuthEnable2FA(method: ${method.value}, phone: ${phoneNumber != null})';
}

/// Disable two-factor authentication
class AuthDisable2FA extends AuthEvent {
  final String verificationCode; // Current TOTP/SMS code or backup code
  
  const AuthDisable2FA(this.verificationCode);
  
  @override
  List<Object> get props => [verificationCode];
  
  @override
  String toString() => 'AuthDisable2FA()';
}

/// Verify two-factor authentication code
class AuthVerify2FA extends AuthEvent {
  final String code;
  final TwoFactorMethod method;
  final String? verificationId; // For SMS verification
  
  const AuthVerify2FA({
    required this.code,
    required this.method,
    this.verificationId,
  });
  
  @override
  List<Object?> get props => [code, method, verificationId];
  
  @override
  String toString() => 'AuthVerify2FA(method: ${method.value})';
}

/// Generate TOTP secret and QR code
class AuthGenerateTOTP extends AuthEvent {
  final String userEmail;
  
  const AuthGenerateTOTP(this.userEmail);
  
  @override
  List<Object> get props => [userEmail];
  
  @override
  String toString() => 'AuthGenerateTOTP(email: $userEmail)';
}

/// Generate backup codes for 2FA recovery
class AuthGenerateBackupCodes extends AuthEvent {
  final int count;
  
  const AuthGenerateBackupCodes({this.count = 10});
  
  @override
  List<Object> get props => [count];
  
  @override
  String toString() => 'AuthGenerateBackupCodes(count: $count)';
}

/// Verify backup code
class AuthVerifyBackupCode extends AuthEvent {
  final String code;
  
  const AuthVerifyBackupCode(this.code);
  
  @override
  List<Object> get props => [code];
  
  @override
  String toString() => 'AuthVerifyBackupCode()';
}

/// Setup biometric authentication
class AuthSetupBiometric extends AuthEvent {
  final List<BiometricType>? enabledTypes;
  
  const AuthSetupBiometric({this.enabledTypes});
  
  @override
  List<Object?> get props => [enabledTypes];
  
  @override
  String toString() => 'AuthSetupBiometric()';
}

/// Authenticate with biometric
class AuthBiometricAuth extends AuthEvent {
  final bool biometricOnly;
  final String? localizedFallbackTitle;
  
  const AuthBiometricAuth({
    this.biometricOnly = false,
    this.localizedFallbackTitle,
  });
  
  @override
  List<Object?> get props => [biometricOnly, localizedFallbackTitle];
  
  @override
  String toString() => 'AuthBiometricAuth(biometricOnly: $biometricOnly)';
}

/// Disable biometric authentication
class AuthDisableBiometric extends AuthEvent {
  final String verificationCode;
  
  const AuthDisableBiometric(this.verificationCode);
  
  @override
  List<Object> get props => [verificationCode];
  
  @override
  String toString() => 'AuthDisableBiometric()';
}

/// Check biometric availability
class AuthCheckBiometricAvailability extends AuthEvent {
  const AuthCheckBiometricAvailability();
}

/// Send SMS verification code
class AuthSendSMSCode extends AuthEvent {
  final String phoneNumber;
  final bool isResend;
  
  const AuthSendSMSCode({
    required this.phoneNumber,
    this.isResend = false,
  });
  
  @override
  List<Object> get props => [phoneNumber, isResend];
  
  @override
  String toString() => 'AuthSendSMSCode(isResend: $isResend)';
}

/// Get current security configuration
class AuthGetSecurityConfig extends AuthEvent {
  const AuthGetSecurityConfig();
}

/// Update security preferences
class AuthUpdateSecurityPreferences extends AuthEvent {
  final Map<String, dynamic> preferences;
  
  const AuthUpdateSecurityPreferences(this.preferences);
  
  @override
  List<Object> get props => [preferences];
  
  @override
  String toString() => 'AuthUpdateSecurityPreferences(preferences: $preferences)';
}

/// Log security event
class AuthLogSecurityEvent extends AuthEvent {
  final AuthSecurityEventType eventType;
  final String description;
  final Map<String, dynamic>? metadata;
  
  const AuthLogSecurityEvent({
    required this.eventType,
    required this.description,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [eventType, description, metadata];
  
  @override
  String toString() => 'AuthLogSecurityEvent(type: ${eventType.value})';
}
