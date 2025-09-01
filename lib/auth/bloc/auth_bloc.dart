import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/base_bloc.dart';
import '../../core/bloc/error_handler.dart';
import '../repository/auth_repository.dart';
import '../repository/firebase_auth_repository.dart';
import '../services/kvk_api_service.dart';
import '../services/kvk_additional_classes.dart';
import '../services/wpbr_verification_service.dart';
import '../services/totp_service.dart';
import '../services/sms_2fa_service.dart';
import '../services/biometric_auth_service.dart';
import '../models/enhanced_auth_models.dart';
import '../auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Authentication BLoC for SecuryFlex
/// Manages all authentication state and operations with Firebase integration
class AuthBloc extends BaseBloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  StreamSubscription<User?>? _authStateSubscription;
  
  AuthBloc({
    AuthRepository? repository,
  }) : _repository = repository ?? FirebaseAuthRepository(),
        super(const AuthInitial()) {
    
    // Register event handlers
    on<AuthInitialize>(_onInitialize);
    on<AuthLogin>(_onLogin);
    on<AuthRegister>(_onRegister);
    on<AuthLogout>(_onLogout);
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthUpdateProfile>(_onUpdateProfile);
    on<AuthRefreshUserData>(_onRefreshUserData);
    on<AuthValidateEmail>(_onValidateEmail);
    on<AuthValidatePassword>(_onValidatePassword);
    
    // Enhanced Dutch business validation handlers
    on<AuthValidateKvK>(_onValidateKvK);
    on<AuthValidateMultipleKvK>(_onValidateMultipleKvK);
    on<AuthGetKvKDetails>(_onGetKvKDetails);
    on<AuthCalculateSecurityEligibility>(_onCalculateSecurityEligibility);
    on<AuthSearchCompaniesByName>(_onSearchCompaniesByName);
    on<AuthClearKvKCache>(_onClearKvKCache);
    on<AuthGetKvKStats>(_onGetKvKStats);
    on<AuthValidateWPBR>(_onValidateWPBR);
    on<AuthValidatePostalCode>(_onValidatePostalCode);
    
    // Enhanced authentication event handlers
    on<AuthEnable2FA>(_onEnable2FA);
    on<AuthDisable2FA>(_onDisable2FA);
    on<AuthVerify2FA>(_onVerify2FA);
    on<AuthGenerateTOTP>(_onGenerateTOTP);
    on<AuthGenerateBackupCodes>(_onGenerateBackupCodes);
    on<AuthVerifyBackupCode>(_onVerifyBackupCode);
    on<AuthSetupBiometric>(_onSetupBiometric);
    on<AuthBiometricAuth>(_onBiometricAuth);
    on<AuthDisableBiometric>(_onDisableBiometric);
    on<AuthCheckBiometricAvailability>(_onCheckBiometricAvailability);
    on<AuthSendSMSCode>(_onSendSMSCode);
    on<AuthGetSecurityConfig>(_onGetSecurityConfig);
    on<AuthUpdateSecurityPreferences>(_onUpdateSecurityPreferences);
    on<AuthLogSecurityEvent>(_onLogSecurityEvent);
    
    // Demo mode handlers removed for production
    
    // Listen to Firebase auth state changes
    _authStateSubscription = _repository.authStateChanges.listen(
      (user) {
        if (!isClosed) {
          add(const AuthCheckStatus());
        }
      },
      onError: (error) {
        if (!isClosed) {
          add(const AuthCheckStatus());
        }
      },
    );
  }
  
  /// Initialize authentication state
  Future<void> _onInitialize(AuthInitialize event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(loadingMessage: 'Initialiseren...'));
    
    try {
      final user = _repository.currentUser;
      if (user != null) {
        await _loadUserData(user.uid, emit);
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Handle user login
  Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(loadingMessage: 'Inloggen...'));
    
    try {
      // Try Firebase authentication first if configured
      if (_repository.isFirebaseConfigured()) {
        final user = await _repository.signInWithEmailAndPassword(
          event.email,
          event.password,
        );
        
        if (user != null) {
          await _loadUserData(user.uid, emit);
          await _repository.updateLastLogin(user.uid);
          return;
        }
      } else {
        debugPrint('Firebase not configured, using demo mode');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase login failed: ${e.code} - ${e.message}');
      // Continue to demo mode fallback
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
      return;
    }
    
    // No demo fallback - production authentication only
    emit(AuthError(AppError(
      code: 'auth_failed',
      message: 'Invalid credentials',
      category: ErrorCategory.authentication,
    )));
  }
  
  /// Handle user registration
  Future<void> _onRegister(AuthRegister event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(loadingMessage: 'Account aanmaken...'));
    
    try {
      final user = await _repository.createUserWithEmailAndPassword(
        event.email,
        event.password,
      );
      
      if (user != null) {
        // Create user document
        final userData = {
          'email': event.email.trim(),
          'name': event.name.trim(),
          'userType': event.userType,
          'createdAt': DateTime.now(),
          'lastLoginAt': DateTime.now(),
          'isActive': true,
          'isDemo': false,
          ...?event.additionalData,
        };
        
        await _repository.createUserDocument(user.uid, userData);
        
        emit(AuthRegistrationSuccess(
          email: event.email,
          userType: event.userType,
        ));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Handle user logout
  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(loadingMessage: 'Uitloggen...'));
    
    try {
      await _repository.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Check authentication status
  Future<void> _onCheckStatus(AuthCheckStatus event, Emitter<AuthState> emit) async {
    try {
      final user = _repository.currentUser;
      if (user != null && state is! AuthAuthenticated) {
        await _loadUserData(user.uid, emit);
      } else if (user == null && state is! AuthUnauthenticated) {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Update user profile
  Future<void> _onUpdateProfile(AuthUpdateProfile event, Emitter<AuthState> emit) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      emit(const AuthLoading(loadingMessage: 'Profiel bijwerken...'));
      
      try {
        await _repository.updateUserData(currentState.userId, event.updates);
        
        // Reload user data
        await _loadUserData(currentState.userId, emit);
        
        emit(AuthProfileUpdateSuccess(updatedData: event.updates));
      } catch (e) {
        emit(AuthError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Refresh user data
  Future<void> _onRefreshUserData(AuthRefreshUserData event, Emitter<AuthState> emit) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      try {
        await _loadUserData(currentState.userId, emit);
      } catch (e) {
        emit(AuthError(ErrorHandler.fromException(e)));
      }
    }
  }
  
  /// Validate email
  Future<void> _onValidateEmail(AuthValidateEmail event, Emitter<AuthState> emit) async {
    final isValid = _repository.isValidEmail(event.email);
    emit(AuthEmailValidation(
      email: event.email,
      isValid: isValid,
      errorMessage: isValid ? null : 'Ongeldig e-mailadres format',
    ));
  }
  
  /// Validate password
  Future<void> _onValidatePassword(AuthValidatePassword event, Emitter<AuthState> emit) async {
    final isValid = _repository.isValidPassword(event.password);
    emit(AuthPasswordValidation(
      password: event.password,
      isValid: isValid,
      errorMessage: isValid ? null : 'Wachtwoord moet minimaal 6 tekens bevatten',
    ));
  }
  
  /// Enhanced Dutch KvK number validation
  Future<void> _onValidateKvK(AuthValidateKvK event, Emitter<AuthState> emit) async {
    // First check basic format
    final validation = AuthService.validateKvKDetailed(event.kvkNumber);
    if (!validation.isValid) {
      emit(AuthKvKValidation(
        kvkNumber: event.kvkNumber,
        isValid: false,
        errorMessage: validation.errorMessage,
      ));
      return;
    }

    // Show enhanced loading state
    emit(AuthKvKValidating(
      event.kvkNumber,
      loadingMessage: 'KvK nummer valideren...',
      currentStep: 'Verbinding maken met KvK API',
      attemptNumber: 1,
    ));
    
    try {
      final kvkData = await KvKApiService.validateKvK(
        event.kvkNumber,
        apiKey: event.apiKey,
      );
      
      if (kvkData != null) {
        // Check security eligibility if required
        final isSecurityValid = !event.requireSecurityEligibility || kvkData.isSecurityEligible;
        final isOverallValid = kvkData.isActive && isSecurityValid;
        
        String? errorMessage;
        if (!kvkData.isActive) {
          errorMessage = 'Bedrijf is niet actief in KvK register';
        } else if (event.requireSecurityEligibility && !kvkData.isSecurityEligible) {
          errorMessage = 'Bedrijf is niet geschikt voor beveiligingsopdrachten';
        }
        
        emit(AuthKvKValidation(
          kvkNumber: event.kvkNumber,
          isValid: isOverallValid,
          kvkData: kvkData.toJson(),
          errorMessage: errorMessage,
          isSecurityEligible: kvkData.isSecurityEligible,
          eligibilityScore: kvkData.eligibilityScore,
          eligibilityReasons: kvkData.eligibilityReasons,
        ));
      } else {
        emit(AuthKvKValidation(
          kvkNumber: event.kvkNumber,
          isValid: false,
          errorMessage: 'KvK nummer niet gevonden in register',
        ));
      }
    } on KvKValidationException catch (e) {
      emit(AuthKvKValidation(
        kvkNumber: event.kvkNumber,
        isValid: false,
        errorMessage: e.localizedMessage,
      ));
    } catch (e) {
      emit(AuthKvKValidation(
        kvkNumber: event.kvkNumber,
        isValid: false,
        errorMessage: 'KvK validatie mislukt. Probeer opnieuw.',
      ));
    }
  }
  
  /// Validate multiple KvK numbers
  Future<void> _onValidateMultipleKvK(AuthValidateMultipleKvK event, Emitter<AuthState> emit) async {
    if (event.kvkNumbers.isEmpty) {
      emit(const AuthMultipleKvKValidation(
        results: {},
        successCount: 0,
        errorCount: 0,
      ));
      return;
    }
    
    final results = <String, AuthKvKValidation>{};
    int successCount = 0;
    int errorCount = 0;
    
    for (int i = 0; i < event.kvkNumbers.length; i++) {
      emit(AuthMultipleKvKValidating(
        kvkNumbers: event.kvkNumbers,
        currentIndex: i,
        loadingMessage: 'KvK nummer ${i + 1} van ${event.kvkNumbers.length} valideren...',
      ));
      
      try {
        final kvkData = await KvKApiService.validateKvK(
          event.kvkNumbers[i],
          apiKey: event.apiKey,
        );
        
        final validation = AuthKvKValidation(
          kvkNumber: event.kvkNumbers[i],
          isValid: kvkData?.isActive ?? false,
          kvkData: kvkData?.toJson(),
          isSecurityEligible: kvkData?.isSecurityEligible ?? false,
          eligibilityScore: kvkData?.eligibilityScore ?? 0.0,
          eligibilityReasons: kvkData?.eligibilityReasons ?? [],
          errorMessage: kvkData?.isActive == false 
              ? 'Bedrijf is niet actief'
              : kvkData == null 
              ? 'KvK nummer niet gevonden'
              : null,
        );
        
        results[event.kvkNumbers[i]] = validation;
        
        if (validation.isValid) {
          successCount++;
        } else {
          errorCount++;
        }
      } catch (e) {
        final validation = AuthKvKValidation(
          kvkNumber: event.kvkNumbers[i],
          isValid: false,
          errorMessage: e is KvKValidationException ? e.localizedMessage : 'Validatie mislukt',
        );
        
        results[event.kvkNumbers[i]] = validation;
        errorCount++;
      }
      
      // Small delay between requests
      if (i < event.kvkNumbers.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    emit(AuthMultipleKvKValidation(
      results: results,
      successCount: successCount,
      errorCount: errorCount,
    ));
  }
  
  /// Get detailed KvK company information
  Future<void> _onGetKvKDetails(AuthGetKvKDetails event, Emitter<AuthState> emit) async {
    emit(AuthKvKValidating(
      event.kvkNumber,
      loadingMessage: 'Bedrijfsgegevens ophalen...',
      currentStep: 'Uitgebreide gegevens laden',
    ));
    
    try {
      final kvkData = await KvKApiService.validateKvK(
        event.kvkNumber,
        apiKey: event.apiKey,
      );
      
      if (kvkData != null) {
        emit(AuthKvKDetails(
          kvkNumber: event.kvkNumber,
          companyDetails: kvkData.toJson(),
          isSecurityEligible: kvkData.isSecurityEligible,
          eligibilityScore: kvkData.eligibilityScore,
          businessActivities: kvkData.businessActivities,
        ));
      } else {
        emit(AuthError(AppError(
          code: 'not-found',
          message: 'KvK nummer niet gevonden',
          category: ErrorCategory.validation,
        )));
      }
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Calculate security industry eligibility
  Future<void> _onCalculateSecurityEligibility(AuthCalculateSecurityEligibility event, Emitter<AuthState> emit) async {
    emit(AuthKvKValidating(
      event.kvkNumber,
      loadingMessage: 'Beveiligingsgeschiktheid berekenen...',
      currentStep: 'Geschiktheid analyseren',
    ));
    
    try {
      final kvkData = await KvKApiService.validateKvK(event.kvkNumber);
      
      if (kvkData != null) {
        final eligibilityResult = KvKApiService.calculateSecurityEligibility(kvkData);
        
        emit(AuthSecurityEligibilityResult(
          kvkNumber: event.kvkNumber,
          isEligible: eligibilityResult.isEligible,
          score: eligibilityResult.score,
          reasons: eligibilityResult.reasons,
          requirements: eligibilityResult.requirements,
        ));
      } else {
        emit(AuthError(AppError(
          code: 'not-found',
          message: 'KvK nummer niet gevonden voor geschiktheidsanalyse',
          category: ErrorCategory.validation,
        )));
      }
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Search companies by name
  Future<void> _onSearchCompaniesByName(AuthSearchCompaniesByName event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(loadingMessage: 'Bedrijven zoeken...'));
    
    try {
      // This would use real search API in production
      final companies = await _searchCompaniesDemo(event.companyName, event.limit);
      
      emit(AuthCompanySearchResults(
        searchQuery: event.companyName,
        companies: companies.map((company) => company.toJson()).toList(),
        totalResults: companies.length,
      ));
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Clear KvK validation cache
  Future<void> _onClearKvKCache(AuthClearKvKCache event, Emitter<AuthState> emit) async {
    try {
      KvKApiService.resetService();
      emit(AuthProfileUpdateSuccess(
        updatedData: {'cacheCleared': true},
        successMessage: 'KvK cache geleegd',
      ));
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Get KvK service statistics
  Future<void> _onGetKvKStats(AuthGetKvKStats event, Emitter<AuthState> emit) async {
    try {
      final stats = KvKApiService.getCacheStats();
      
      emit(AuthKvKStats(
        cacheStats: stats,
        serviceStats: {'version': '2.0', 'enhanced': true},
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }
  
  /// Demo company search implementation
  Future<List<KvKData>> _searchCompaniesDemo(String query, int limit) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final companies = <KvKData>[];
    for (int i = 1; i <= limit; i++) {
      companies.add(KvKData(
        kvkNumber: (20000000 + i).toString(),
        companyName: '$query $i B.V.',
        tradeName: '$query $i',
        legalForm: 'Besloten vennootschap',
        isActive: i % 10 != 0, // 90% active
        isSecurityEligible: i % 3 == 0, // 33% security eligible
        eligibilityScore: (i % 3 == 0) ? 0.7 : 0.2,
        foundationDate: DateTime.now().subtract(Duration(days: 365 * i)),
      ));
    }
    
    return companies;
  }
  
  /// Validate Dutch WPBR certificate
  Future<void> _onValidateWPBR(AuthValidateWPBR event, Emitter<AuthState> emit) async {
    // First check basic format
    final validation = AuthService.validateWPBRDetailed(event.wpbrNumber);
    if (!validation.isValid) {
      emit(AuthWPBRValidation(
        wpbrNumber: event.wpbrNumber,
        isValid: false,
        errorMessage: validation.errorMessage,
      ));
      return;
    }

    // Show loading state
    emit(AuthWPBRValidating(event.wpbrNumber));
    
    try {
      File? certificateFile;
      if (event.certificateFilePath != null) {
        certificateFile = File(event.certificateFilePath!);
      }
      
      final result = await WPBRVerificationService.verifyCertificate(
        event.wpbrNumber,
        certificateDocument: certificateFile,
      );
      
      if (result.isSuccess && result.data != null) {
        emit(AuthWPBRValidation(
          wpbrNumber: event.wpbrNumber,
          isValid: result.data!.isCurrentlyValid,
          wpbrData: result.data!.toJson(),
          errorMessage: result.data!.isCurrentlyValid ? null : 'WPBR certificaat is niet geldig of verlopen',
        ));
      } else {
        emit(AuthWPBRValidation(
          wpbrNumber: event.wpbrNumber,
          isValid: false,
          errorMessage: result.message,
        ));
      }
    } on WPBRVerificationException catch (e) {
      emit(AuthWPBRValidation(
        wpbrNumber: event.wpbrNumber,
        isValid: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(AuthWPBRValidation(
        wpbrNumber: event.wpbrNumber,
        isValid: false,
        errorMessage: 'WPBR verificatie mislukt. Probeer opnieuw.',
      ));
    }
  }
  
  /// Validate Dutch postal code
  Future<void> _onValidatePostalCode(AuthValidatePostalCode event, Emitter<AuthState> emit) async {
    final validation = AuthService.validateDutchPostalCodeDetailed(event.postalCode);
    final formattedPostalCode = validation.isValid 
        ? AuthService.formatDutchPostalCode(event.postalCode)
        : null;
        
    emit(AuthPostalCodeValidation(
      postalCode: event.postalCode,
      isValid: validation.isValid,
      formattedPostalCode: formattedPostalCode,
      errorMessage: validation.isValid ? null : validation.errorMessage,
    ));
  }
  
  // Demo methods removed for production
  
  /// Load user data from repository
  Future<void> _loadUserData(String uid, Emitter<AuthState> emit) async {
    try {
      final userData = await _repository.getUserData(uid);
      
      if (userData != null) {
        emit(AuthAuthenticated(
          firebaseUser: _repository.currentUser,
          userId: uid,
          userType: userData['userType'] ?? 'guard',
          userName: userData['name'] ?? 'Unknown User',
          userEmail: userData['email'] ?? '',
          userData: userData,
          isDemo: userData['isDemo'] ?? false,
        ));
      } else {
        throw Exception('User data not found');
      }
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }
  
  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
  
  /// Convenience getters for current authentication state
  bool get isAuthenticated => state is AuthAuthenticated;
  bool get isLoading => state is AuthLoading || state is AuthKvKValidating || state is AuthMultipleKvKValidating;
  bool get hasError => state is AuthError;
  bool get isValidatingKvK => state is AuthKvKValidating || state is AuthMultipleKvKValidating;
  
  AuthAuthenticated? get currentUser {
    return state is AuthAuthenticated ? state as AuthAuthenticated : null;
  }
  
  String get currentUserType {
    return currentUser?.userType ?? '';
  }
  
  String get currentUserName {
    return currentUser?.userName ?? '';
  }
  
  String get currentUserId {
    return currentUser?.userId ?? '';
  }
  
  Map<String, dynamic> get currentUserData {
    return currentUser?.userData ?? {};
  }

  // ============================================================================
  // ENHANCED AUTHENTICATION EVENT HANDLERS - Two-Factor, Biometric, Security
  // ============================================================================

  /// Enable two-factor authentication
  Future<void> _onEnable2FA(AuthEnable2FA event, Emitter<AuthState> emit) async {
    emit(const AuthAdvancedLoading(operation: 'enable_2fa'));
    
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(AuthError(AppError(
          code: 'not_authenticated',
          message: 'Gebruiker niet ingelogd',
          category: ErrorCategory.authentication,
        )));
        return;
      }
      
      switch (event.method) {
        case TwoFactorMethod.sms:
          if (event.phoneNumber == null) {
            emit(AuthError(AppError(
              code: 'phone_required',
              message: 'Telefoonnummer vereist voor SMS 2FA',
              category: ErrorCategory.validation,
            )));
            return;
          }
          
          final result = await SMS2FAService.setupSMS2FA(
            userId: currentState.userId,
            phoneNumber: event.phoneNumber!,
          );
          
          if (result) {
            final config = TwoFactorConfig(
              isEnabled: true,
              preferredMethod: TwoFactorMethod.sms,
              enabledMethods: [TwoFactorMethod.sms],
              phoneNumber: event.phoneNumber,
              setupDate: DateTime.now(),
            );
            
            emit(AuthTwoFactorEnabled(
              method: event.method,
              config: config,
            ));
          } else {
            emit(AuthError(AppError(
              code: 'sms_2fa_setup_failed',
              message: 'SMS 2FA instelling mislukt',
              category: ErrorCategory.service,
            )));
          }
          break;
          
        case TwoFactorMethod.totp:
          // TOTP setup will be initiated by AuthGenerateTOTP event
          emit(AuthError(AppError(
            code: 'totp_setup_required',
            message: 'Gebruik AuthGenerateTOTP om TOTP in te stellen',
            category: ErrorCategory.validation,
          )));
          break;
          
        case TwoFactorMethod.backupCode:
          emit(AuthError(AppError(
            code: 'backup_code_not_primary',
            message: 'Backup codes kunnen niet als primaire methode gebruikt worden',
            category: ErrorCategory.validation,
          )));
          break;
      }
      
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }

  /// Disable two-factor authentication
  Future<void> _onDisable2FA(AuthDisable2FA event, Emitter<AuthState> emit) async {
    emit(const AuthAdvancedLoading(operation: 'disable_2fa'));
    
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(AuthError(AppError(
          code: 'not_authenticated',
          message: 'Gebruiker niet ingelogd',
          category: ErrorCategory.authentication,
        )));
        return;
      }
      
      // Try TOTP verification first
      final totpResult = await TOTPService.verifyTOTP(
        currentState.userId,
        event.verificationCode,
      );
      
      bool verified = totpResult.isValid;
      
      // If TOTP failed, try backup code
      if (!verified) {
        final backupResult = await TOTPService.verifyBackupCode(
          currentState.userId,
          event.verificationCode,
        );
        verified = backupResult.isValid;
      }
      
      // If still not verified, try SMS 2FA (if configured)
      if (!verified) {
        final smsConfig = await SMS2FAService.getSMS2FAConfig(currentState.userId);
        if (smsConfig?.isEnabled == true) {
          final smsResult = await SMS2FAService.disableSMS2FA(
            userId: currentState.userId,
            verificationCode: event.verificationCode,
          );
          verified = smsResult;
        }
      }
      
      if (verified) {
        // Disable TOTP if enabled
        await TOTPService.disableTOTP(currentState.userId, event.verificationCode);
        
        emit(const AuthTwoFactorDisabled());
        
        // Log security event
        add(AuthLogSecurityEvent(
          eventType: AuthSecurityEventType.twoFactorSetup,
          description: 'Two-factor authentication disabled',
          metadata: {'success': true},
        ));
      } else {
        emit(AuthError(AppError(
          code: 'invalid_verification_code',
          message: 'Ongeldige verificatiecode',
          category: ErrorCategory.authentication,
        )));
      }
      
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }

  /// Verify two-factor authentication code
  Future<void> _onVerify2FA(AuthVerify2FA event, Emitter<AuthState> emit) async {
    emit(const AuthAdvancedLoading(operation: 'verify_2fa'));
    
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(AuthError(AppError(
          code: 'not_authenticated',
          message: 'Gebruiker niet ingelogd',
          category: ErrorCategory.authentication,
        )));
        return;
      }
      
      bool verified = false;
      int? remainingBackupCodes;
      
      switch (event.method) {
        case TwoFactorMethod.sms:
          if (event.verificationId == null) {
            emit(AuthError(AppError(
              code: 'verification_id_required',
              message: 'Verificatie ID vereist voor SMS verificatie',
              category: ErrorCategory.validation,
            )));
            return;
          }
          
          final result = await SMS2FAService.verifyCode(
            userId: currentState.userId,
            code: event.code,
            verificationId: event.verificationId!,
          );
          verified = result.success;
          break;
          
        case TwoFactorMethod.totp:
          final result = await TOTPService.verifyTOTP(
            currentState.userId,
            event.code,
          );
          verified = result.isValid;
          break;
          
        case TwoFactorMethod.backupCode:
          final result = await TOTPService.verifyBackupCode(
            currentState.userId,
            event.code,
          );
          verified = result.isValid;
          remainingBackupCodes = result.remainingCodes;
          break;
      }
      
      if (verified) {
        emit(AuthTwoFactorVerified(
          method: event.method,
          wasBackupCode: event.method == TwoFactorMethod.backupCode,
          remainingBackupCodes: remainingBackupCodes,
        ));
        
        // Log successful verification
        add(AuthLogSecurityEvent(
          eventType: AuthSecurityEventType.loginSuccess,
          description: '2FA verification successful',
          metadata: {
            'method': event.method.value,
            'wasBackupCode': event.method == TwoFactorMethod.backupCode,
          },
        ));
      } else {
        emit(AuthError(AppError(
          code: 'invalid_2fa_code',
          message: 'Ongeldige verificatiecode',
          category: ErrorCategory.authentication,
        )));
        
        // Log failed verification
        add(AuthLogSecurityEvent(
          eventType: AuthSecurityEventType.loginFailed,
          description: '2FA verification failed',
          metadata: {'method': event.method.value},
        ));
      }
      
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }

  /// Generate TOTP secret and QR code
  Future<void> _onGenerateTOTP(AuthGenerateTOTP event, Emitter<AuthState> emit) async {
    emit(const AuthAdvancedLoading(operation: 'generate_totp'));
    
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(AuthError(AppError(
          code: 'not_authenticated',
          message: 'Gebruiker niet ingelogd',
          category: ErrorCategory.authentication,
        )));
        return;
      }
      
      // Generate TOTP secret
      final secret = await TOTPService.generateSecret(currentState.userId);
      
      // Generate QR code data
      final qrCodeData = await TOTPService.getQRCodeData(
        userId: currentState.userId,
        userEmail: event.userEmail,
        secret: secret,
      );
      
      // Generate backup codes
      final backupCodes = await TOTPService.generateBackupCodes(currentState.userId);
      
      emit(AuthTOTPSetup(
        secret: secret,
        qrCodeData: qrCodeData,
        userEmail: event.userEmail,
        backupCodes: backupCodes,
      ));
      
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }

  /// Generate backup codes
  Future<void> _onGenerateBackupCodes(AuthGenerateBackupCodes event, Emitter<AuthState> emit) async {
    emit(const AuthAdvancedLoading(operation: 'generate_backup_codes'));
    
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(AuthError(AppError(
          code: 'not_authenticated',
          message: 'Gebruiker niet ingelogd',
          category: ErrorCategory.authentication,
        )));
        return;
      }
      
      final backupCodes = await TOTPService.generateBackupCodes(
        currentState.userId,
        count: event.count,
      );
      
      emit(AuthBackupCodesGenerated(backupCodes: backupCodes));
      
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }

  /// Verify backup code
  Future<void> _onVerifyBackupCode(AuthVerifyBackupCode event, Emitter<AuthState> emit) async {
    // This is handled by the general _onVerify2FA method
    add(AuthVerify2FA(
      code: event.code,
      method: TwoFactorMethod.backupCode,
    ));
  }

  /// Setup biometric authentication
  Future<void> _onSetupBiometric(AuthSetupBiometric event, Emitter<AuthState> emit) async {
    emit(const AuthAdvancedLoading(operation: 'setup_biometric'));
    
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(AuthError(AppError(
          code: 'not_authenticated',
          message: 'Gebruiker niet ingelogd',
          category: ErrorCategory.authentication,
        )));
        return;
      }
      
      final result = await BiometricAuthService.enableBiometric(
        userId: currentState.userId,
        enabledTypes: event.enabledTypes,
      );
      
      if (result) {
        final config = await BiometricAuthService.getBiometricConfig(currentState.userId);
        
        emit(AuthBiometricEnabled(
          config: config,
          enabledTypes: config.enabledTypes,
        ));
        
        // Log security event
        add(AuthLogSecurityEvent(
          eventType: AuthSecurityEventType.biometricSetup,
          description: 'Biometric authentication enabled',
          metadata: {
            'types': config.enabledTypes.map((t) => t.name).toList(),
          },
        ));
      } else {
        emit(AuthError(AppError(
          code: 'biometric_setup_failed',
          message: 'Biometrische authenticatie instelling mislukt',
          category: ErrorCategory.service,
        )));
      }
      
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }

  /// Authenticate with biometric
  Future<void> _onBiometricAuth(AuthBiometricAuth event, Emitter<AuthState> emit) async {
    emit(const AuthAdvancedLoading(operation: 'biometric_auth'));
    
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(AuthError(AppError(
          code: 'not_authenticated',
          message: 'Gebruiker niet ingelogd',
          category: ErrorCategory.authentication,
        )));
        return;
      }
      
      final result = await BiometricAuthService.authenticate(
        userId: currentState.userId,
        biometricOnly: event.biometricOnly,
        localizedFallbackTitle: event.localizedFallbackTitle,
      );
      
      if (result.isAuthenticated) {
        emit(AuthBiometricAuthenticated(
          authenticationType: result.biometricType!,
          timestamp: DateTime.now(),
        ));
        
        // Log successful authentication
        add(AuthLogSecurityEvent(
          eventType: AuthSecurityEventType.loginSuccess,
          description: 'Biometric authentication successful',
          metadata: {
            'biometricType': result.biometricType?.name,
          },
        ));
      } else {
        emit(AuthError(AppError(
          code: result.errorCode ?? 'biometric_auth_failed',
          message: result.errorMessageDutch ?? 'Biometrische authenticatie mislukt',
          category: ErrorCategory.authentication,
        )));
        
        // Log failed authentication
        add(AuthLogSecurityEvent(
          eventType: AuthSecurityEventType.loginFailed,
          description: 'Biometric authentication failed',
          metadata: {
            'errorCode': result.errorCode,
            'remainingAttempts': result.remainingAttempts,
          },
        ));
      }
      
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }

  /// Disable biometric authentication
  Future<void> _onDisableBiometric(AuthDisableBiometric event, Emitter<AuthState> emit) async {
    emit(const AuthAdvancedLoading(operation: 'disable_biometric'));
    
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(AuthError(AppError(
          code: 'not_authenticated',
          message: 'Gebruiker niet ingelogd',
          category: ErrorCategory.authentication,
        )));
        return;
      }
      
      final result = await BiometricAuthService.disableBiometric(
        userId: currentState.userId,
        verificationCode: event.verificationCode,
      );
      
      if (result) {
        emit(const AuthBiometricDisabled());
        
        // Log security event
        add(AuthLogSecurityEvent(
          eventType: AuthSecurityEventType.biometricSetup,
          description: 'Biometric authentication disabled',
          metadata: {'success': true},
        ));
      } else {
        emit(AuthError(AppError(
          code: 'biometric_disable_failed',
          message: 'Biometrische authenticatie uitschakeling mislukt',
          category: ErrorCategory.service,
        )));
      }
      
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }

  /// Check biometric availability
  Future<void> _onCheckBiometricAvailability(AuthCheckBiometricAvailability event, Emitter<AuthState> emit) async {
    emit(const AuthAdvancedLoading(operation: 'check_biometric_availability'));
    
    try {
      final availability = await BiometricAuthService.checkBiometricAvailability();
      
      emit(AuthBiometricAvailability(
        isAvailable: availability.isAvailable,
        isSupported: availability.isAvailable,
        availableTypes: availability.availableTypes ?? [],
        reason: availability.reasonDutch,
        errorCode: availability.errorCode,
      ));
      
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }

  /// Send SMS verification code
  Future<void> _onSendSMSCode(AuthSendSMSCode event, Emitter<AuthState> emit) async {
    emit(const AuthAdvancedLoading(operation: 'send_sms'));
    
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(AuthError(AppError(
          code: 'not_authenticated',
          message: 'Gebruiker niet ingelogd',
          category: ErrorCategory.authentication,
        )));
        return;
      }
      
      final result = await SMS2FAService.sendVerificationCode(
        userId: currentState.userId,
        phoneNumber: event.phoneNumber,
        isResend: event.isResend,
      );
      
      if (result.success) {
        emit(AuthSMSCodeSent(
          verificationId: result.verificationId!,
          obfuscatedPhoneNumber: _obfuscatePhoneNumber(event.phoneNumber),
          cooldownSeconds: result.cooldownSeconds ?? 60,
          isResend: event.isResend,
          successMessage: result.messageDutch,
        ));
      } else {
        emit(AuthError(AppError(
          code: result.errorCode ?? 'sms_send_failed',
          message: result.errorMessageDutch ?? 'SMS versturen mislukt',
          category: ErrorCategory.service,
        )));
      }
      
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }

  /// Get security configuration
  Future<void> _onGetSecurityConfig(AuthGetSecurityConfig event, Emitter<AuthState> emit) async {
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(AuthError(AppError(
          code: 'not_authenticated',
          message: 'Gebruiker niet ingelogd',
          category: ErrorCategory.authentication,
        )));
        return;
      }
      
      // Get configurations from services
      final twoFactorConfig = await TOTPService.getTwoFactorConfig(currentState.userId);
      final biometricConfig = await BiometricAuthService.getBiometricConfig(currentState.userId);
      
      // Determine current authentication level
      AuthenticationLevel level = AuthenticationLevel.basic;
      if (biometricConfig.isEnabled && twoFactorConfig.isTotpEnabled) {
        level = AuthenticationLevel.combined;
      } else if (biometricConfig.isEnabled) {
        level = AuthenticationLevel.biometric;
      } else if (twoFactorConfig.isTotpEnabled) {
        level = AuthenticationLevel.twoFactor;
      }
      
      // Convert to our models
      final twoFactorConfigModel = TwoFactorConfig(
        isEnabled: twoFactorConfig.isTotpEnabled,
        backupCodesRemaining: (await TOTPService.getBackupCodesStatus(currentState.userId)).remaining,
        setupDate: twoFactorConfig.setupDate,
        lastUsed: DateTime.now(), // This would come from service in production
      );
      
      emit(AuthSecurityConfig(
        twoFactorConfig: twoFactorConfigModel,
        biometricConfig: biometricConfig,
        currentLevel: level,
        recentEvents: [], // Would be loaded from audit service
        preferences: {}, // Would be loaded from user preferences
      ));
      
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }

  /// Update security preferences
  Future<void> _onUpdateSecurityPreferences(AuthUpdateSecurityPreferences event, Emitter<AuthState> emit) async {
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        emit(AuthError(AppError(
          code: 'not_authenticated',
          message: 'Gebruiker niet ingelogd',
          category: ErrorCategory.authentication,
        )));
        return;
      }
      
      // Update user preferences (would save to Firestore in production)
      await _repository.updateUserData(currentState.userId, {
        'securityPreferences': event.preferences,
        'updatedAt': DateTime.now(),
      });
      
      emit(AuthProfileUpdateSuccess(
        updatedData: event.preferences,
        successMessage: 'Beveiligingsinstellingen bijgewerkt',
      ));
      
    } catch (e) {
      emit(AuthError(ErrorHandler.fromException(e)));
    }
  }

  /// Log security event
  Future<void> _onLogSecurityEvent(AuthLogSecurityEvent event, Emitter<AuthState> emit) async {
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) {
        return; // Don't emit error for logging events
      }
      
      // Create security event
      final securityEvent = AuthSecurityEvent(
        eventId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentState.userId,
        type: event.eventType,
        description: event.description,
        timestamp: DateTime.now(),
        metadata: event.metadata ?? {},
      );
      
      // In production, this would be sent to a secure logging service
      developer.log('Security Event: ${securityEvent.toJson()}', name: 'AuthBloc.SecurityEvent');
      
      // Optional: emit state for UI feedback
      emit(AuthSecurityEventLogged(event: securityEvent));
      
    } catch (e) {
      // Don't emit error state for logging failures
      developer.log('Failed to log security event: $e', name: 'AuthBloc.SecurityEvent', level: 1000);
    }
  }

  // Helper methods
  
  /// Obfuscate phone number for display
  String _obfuscatePhoneNumber(String phoneNumber) {
    if (phoneNumber.length <= 4) return '****';
    return '${phoneNumber.substring(0, 3)}****${phoneNumber.substring(phoneNumber.length - 2)}';
  }
}
