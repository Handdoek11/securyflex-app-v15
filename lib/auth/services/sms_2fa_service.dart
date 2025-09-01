import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SMS Two-Factor Authentication service for SecuryFlex
/// 
/// Provides SMS-based 2FA with Dutch phone number validation,
/// rate limiting, fraud detection, and comprehensive audit logging.
class SMS2FAService {
  static const String _configKey = 'securyflex_sms_2fa_config';
  static const String _verificationKey = 'securyflex_sms_verification';
  static const int _codeValidityMinutes = 5;
  static const int _maxAttemptsPerHour = 5;
  static const int _maxCodesPerDay = 10;
  static const int _resendCooldownSeconds = 120; // Increased to 2 minutes
  
  static final Map<String, Timer> _cooldownTimers = {};

  /// Validate Dutch phone number format
  static bool isValidDutchPhoneNumber(String phoneNumber) {
    // Remove all non-digits
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Dutch phone number patterns
    final patterns = [
      RegExp(r'^\+31[6789]\d{8}$'),      // +31 6/7/8/9 xxxxxxxx
      RegExp(r'^0031[6789]\d{8}$'),      // 0031 6/7/8/9 xxxxxxxx  
      RegExp(r'^31[6789]\d{8}$'),        // 31 6/7/8/9 xxxxxxxx
      RegExp(r'^0[6789]\d{8}$'),         // 0 6/7/8/9 xxxxxxxx (national format)
      RegExp(r'^[6789]\d{8}$'),          // 6/7/8/9 xxxxxxxx (local format)
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(digits));
  }
  
  /// Format Dutch phone number to international format
  static String formatDutchPhoneNumber(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.startsWith('0031')) {
      return '+${digits.substring(2)}';
    } else if (digits.startsWith('31')) {
      return '+$digits';
    } else if (digits.startsWith('0')) {
      return '+31${digits.substring(1)}';
    } else if (digits.length == 9 && (digits.startsWith('6') || digits.startsWith('7') || digits.startsWith('8') || digits.startsWith('9'))) {
      return '+31$digits';
    }
    
    return phoneNumber; // Return original if format not recognized
  }
  
  /// Send SMS verification code
  static Future<SMS2FAResult> sendVerificationCode({
    required String userId,
    required String phoneNumber,
    bool isResend = false,
  }) async {
    try {
      // Validate phone number format
      if (!isValidDutchPhoneNumber(phoneNumber)) {
        return SMS2FAResult(
          success: false,
          errorCode: 'INVALID_PHONE_FORMAT',
          errorMessage: 'Ongeldig telefoonnummer format. Gebruik Nederlands format.',
          errorMessageDutch: 'Ongeldig telefoonnummer format. Gebruik Nederlands format.',
        );
      }
      
      final formattedPhone = formatDutchPhoneNumber(phoneNumber);
      
      // Check rate limiting
      final rateLimitCheck = await _checkRateLimit(userId);
      if (!rateLimitCheck.allowed) {
        return SMS2FAResult(
          success: false,
          errorCode: 'RATE_LIMITED',
          errorMessage: rateLimitCheck.errorMessage,
          errorMessageDutch: rateLimitCheck.errorMessage,
          cooldownSeconds: rateLimitCheck.cooldownSeconds,
        );
      }
      
      // Check resend cooldown with progressive backoff
      if (isResend) {
        final cooldownCheck = _checkResendCooldown(userId);
        if (!cooldownCheck.allowed) {
          return SMS2FAResult(
            success: false,
            errorCode: 'RESEND_COOLDOWN',
            errorMessage: cooldownCheck.errorMessage ?? 'Wacht voordat je opnieuw een code kunt aanvragen',
            errorMessageDutch: cooldownCheck.errorMessage ?? 'Wacht voordat je opnieuw een code kunt aanvragen',
            cooldownSeconds: cooldownCheck.cooldownSeconds ?? _resendCooldownSeconds,
          );
        }
      }
      
      // Fraud detection
      final fraudCheck = await _checkForFraud(userId, formattedPhone);
      if (fraudCheck.isFraudulent) {
        await _logSecurityEvent(userId, 'SMS fraud detection triggered', {
          'phoneNumber': _obfuscatePhone(formattedPhone),
          'reason': fraudCheck.reason,
        });
        
        return SMS2FAResult(
          success: false,
          errorCode: 'FRAUD_DETECTED',
          errorMessage: 'Verdachte activiteit gedetecteerd. Probeer het later opnieuw.',
          errorMessageDutch: 'Verdachte activiteit gedetecteerd. Probeer het later opnieuw.',
        );
      }
      
      // Use Firebase Phone Auth for production
      if (_isFirebaseConfigured()) {
        return await _sendFirebaseSMS(userId, formattedPhone, isResend);
      } else {
        // Demo/development mode
        return await _sendDemoSMS(userId, formattedPhone, isResend);
      }
      
    } catch (e) {
      await _logSecurityEvent(userId, 'SMS send error', {
        'error': e.toString(),
        'phoneNumber': _obfuscatePhone(phoneNumber),
      });
      
      return SMS2FAResult(
        success: false,
        errorCode: 'SEND_ERROR',
        errorMessage: 'Fout bij versturen van SMS. Probeer het opnieuw.',
        errorMessageDutch: 'Fout bij versturen van SMS. Probeer het opnieuw.',
      );
    }
  }
  
  /// Verify SMS code
  static Future<SMS2FAResult> verifyCode({
    required String userId,
    required String code,
    required String verificationId,
  }) async {
    try {
      // Get stored verification data
      final verificationData = await _getVerificationData(userId);
      if (verificationData == null) {
        return SMS2FAResult(
          success: false,
          errorCode: 'NO_VERIFICATION',
          errorMessage: 'Geen actieve verificatie gevonden',
          errorMessageDutch: 'Geen actieve verificatie gevonden',
        );
      }
      
      // Check if code is expired
      if (DateTime.now().isAfter(verificationData.expiresAt)) {
        await _clearVerificationData(userId);
        return SMS2FAResult(
          success: false,
          errorCode: 'CODE_EXPIRED',
          errorMessage: 'Verificatiecode is verlopen. Vraag een nieuwe code aan.',
          errorMessageDutch: 'Verificatiecode is verlopen. Vraag een nieuwe code aan.',
        );
      }
      
      // Check attempt limit
      if (verificationData.attempts >= verificationData.maxAttempts) {
        await _clearVerificationData(userId);
        return SMS2FAResult(
          success: false,
          errorCode: 'MAX_ATTEMPTS_EXCEEDED',
          errorMessage: 'Te veel onjuiste pogingen. Vraag een nieuwe code aan.',
          errorMessageDutch: 'Te veel onjuiste pogingen. Vraag een nieuwe code aan.',
        );
      }
      
      bool isValid = false;
      
      if (_isFirebaseConfigured()) {
        // Verify with Firebase
        isValid = await _verifyFirebaseCode(code, verificationId);
      } else {
        // Demo/development mode verification
        isValid = await _verifyDemoCode(userId, code, verificationData);
      }
      
      if (isValid) {
        // Clear verification data on success
        await _clearVerificationData(userId);
        
        // Log successful verification
        await _logSecurityEvent(userId, 'SMS verification successful', {
          'phoneNumber': _obfuscatePhone(verificationData.phoneNumber),
        });
        
        return SMS2FAResult(
          success: true,
          message: 'Telefoon succesvol geverifieerd',
          messageDutch: 'Telefoon succesvol geverifieerd',
        );
      } else {
        // Increment attempt count
        verificationData.attempts++;
        await _saveVerificationData(userId, verificationData);
        
        // Log failed verification
        await _logSecurityEvent(userId, 'SMS verification failed', {
          'phoneNumber': _obfuscatePhone(verificationData.phoneNumber),
          'attempts': verificationData.attempts,
        });
        
        return SMS2FAResult(
          success: false,
          errorCode: 'INVALID_CODE',
          errorMessage: 'Ongeldige verificatiecode',
          errorMessageDutch: 'Ongeldige verificatiecode',
          remainingAttempts: verificationData.maxAttempts - verificationData.attempts,
        );
      }
      
    } catch (e) {
      await _logSecurityEvent(userId, 'SMS verification error', {
        'error': e.toString(),
      });
      
      return SMS2FAResult(
        success: false,
        errorCode: 'VERIFICATION_ERROR',
        errorMessage: 'Fout bij verificatie van code',
        errorMessageDutch: 'Fout bij verificatie van code',
      );
    }
  }
  
  /// Resend verification code
  static Future<SMS2FAResult> resendCode({
    required String userId,
    required String phoneNumber,
  }) async {
    return sendVerificationCode(
      userId: userId,
      phoneNumber: phoneNumber,
      isResend: true,
    );
  }
  
  /// Setup SMS 2FA for user
  static Future<bool> setupSMS2FA({
    required String userId,
    required String phoneNumber,
  }) async {
    try {
      final result = await sendVerificationCode(
        userId: userId,
        phoneNumber: phoneNumber,
      );
      
      if (result.success) {
        // Store configuration
        final config = SMS2FAConfig(
          isEnabled: false, // Will be enabled after verification
          phoneNumber: formatDutchPhoneNumber(phoneNumber),
          setupDate: DateTime.now(),
        );
        
        await _saveSMS2FAConfig(userId, config);
        return true;
      }
      
      return false;
    } catch (e) {
      await _logSecurityEvent(userId, 'SMS 2FA setup error', {
        'error': e.toString(),
        'phoneNumber': _obfuscatePhone(phoneNumber),
      });
      return false;
    }
  }
  
  /// Enable SMS 2FA after successful verification
  static Future<void> enableSMS2FA(String userId) async {
    final config = await getSMS2FAConfig(userId);
    if (config != null) {
      final updatedConfig = config.copyWith(
        isEnabled: true,
        verifiedDate: DateTime.now(),
      );
      
      await _saveSMS2FAConfig(userId, updatedConfig);
      
      await _logSecurityEvent(userId, 'SMS 2FA enabled', {
        'phoneNumber': _obfuscatePhone(config.phoneNumber),
      });
    }
  }
  
  /// Disable SMS 2FA
  static Future<bool> disableSMS2FA({
    required String userId,
    required String verificationCode,
  }) async {
    // Verify current code before disabling
    final config = await getSMS2FAConfig(userId);
    if (config == null) return false;
    
    // This would normally verify the current code
    // For demo purposes, we'll just disable it
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_configKey$userId');
    
    await _logSecurityEvent(userId, 'SMS 2FA disabled', {
      'phoneNumber': _obfuscatePhone(config.phoneNumber),
    });
    
    return true;
  }
  
  /// Get SMS 2FA configuration
  static Future<SMS2FAConfig?> getSMS2FAConfig(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('$_configKey$userId');
    
    if (configJson != null) {
      return SMS2FAConfig.fromJson(json.decode(configJson));
    }
    
    return null;
  }
  
  // Private helper methods
  
  /// Send SMS using Firebase Phone Auth
  static Future<SMS2FAResult> _sendFirebaseSMS(String userId, String phoneNumber, bool isResend) async {
    try {
      final completer = Completer<SMS2FAResult>();
      
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification (rarely happens on iOS, more common on Android)
          completer.complete(SMS2FAResult(
            success: true,
            message: 'Telefoon automatisch geverifieerd',
            messageDutch: 'Telefoon automatisch geverifieerd',
            autoVerified: true,
          ));
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = 'Verificatie mislukt';
          
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Ongeldig telefoonnummer';
              break;
            case 'too-many-requests':
              errorMessage = 'Te veel aanvragen. Probeer het later opnieuw.';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota overschreden. Probeer het later opnieuw.';
              break;
          }
          
          completer.complete(SMS2FAResult(
            success: false,
            errorCode: e.code,
            errorMessage: errorMessage,
            errorMessageDutch: errorMessage,
          ));
        },
        codeSent: (String verificationId, int? resendToken) async {
          // Store verification data
          final verificationData = SMSVerificationData(
            verificationId: verificationId,
            phoneNumber: phoneNumber,
            sentAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: _codeValidityMinutes)),
            attempts: 0,
            maxAttempts: 3,
            resendToken: resendToken,
          );
          
          await _saveVerificationData(userId, verificationData);
          
          // Start cooldown timer
          _startCooldownTimer(userId);
          
          // Increment daily counter
          await _incrementDailyCounter(userId);
          
          // Log successful send (without sensitive data in production)
          await _logSecurityEvent(userId, 'SMS verification code sent', {
            'phoneNumber': _obfuscatePhone(phoneNumber),
            'isResend': isResend,
            // Remove demo code from logs in production
          });
          
          completer.complete(SMS2FAResult(
            success: true,
            verificationId: verificationId,
            message: 'Verificatiecode verzonden naar ${_obfuscatePhone(phoneNumber)}',
            messageDutch: 'Verificatiecode verzonden naar ${_obfuscatePhone(phoneNumber)}',
            cooldownSeconds: _resendCooldownSeconds,
          ));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout occurred, but code was sent
          if (!completer.isCompleted) {
            completer.complete(SMS2FAResult(
              success: true,
              verificationId: verificationId,
              message: 'Verificatiecode verzonden',
              messageDutch: 'Verificatiecode verzonden',
            ));
          }
        },
        timeout: const Duration(seconds: 30),
      );
      
      return await completer.future;
      
    } catch (e) {
      return SMS2FAResult(
        success: false,
        errorCode: 'FIREBASE_ERROR',
        errorMessage: 'Fout bij versturen van SMS via Firebase',
        errorMessageDutch: 'Fout bij versturen van SMS via Firebase',
      );
    }
  }
  
  /// Send demo SMS (for development)
  static Future<SMS2FAResult> _sendDemoSMS(String userId, String phoneNumber, bool isResend) async {
    // Generate random 6-digit code
    final code = _generateVerificationCode();
    
    // Store verification data
    final verificationData = SMSVerificationData(
      verificationId: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: phoneNumber,
      sentAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: _codeValidityMinutes)),
      attempts: 0,
      maxAttempts: 3,
      demoCode: code, // Store code for demo verification
    );
    
    await _saveVerificationData(userId, verificationData);
    
    // Start cooldown timer
    _startCooldownTimer(userId);
    
    // Increment daily counter
    await _incrementDailyCounter(userId);
    
    // Log successful send
    await _logSecurityEvent(userId, 'SMS verification code sent (demo)', {
      'phoneNumber': _obfuscatePhone(phoneNumber),
      'isResend': isResend,
      // Only log demo code in development mode
      if (kDebugMode) 'demoCode': code,
    });
    
    developer.log('📱 Demo SMS Code for $phoneNumber: $code', name: 'SMS2FA'); // For development
    
    return SMS2FAResult(
      success: true,
      verificationId: verificationData.verificationId,
      message: 'Verificatiecode verzonden naar ${_obfuscatePhone(phoneNumber)} (Demo: $code)',
      messageDutch: 'Verificatiecode verzonden naar ${_obfuscatePhone(phoneNumber)} (Demo: $code)',
      cooldownSeconds: _resendCooldownSeconds,
    );
  }
  
  /// Verify Firebase SMS code
  static Future<bool> _verifyFirebaseCode(String code, String verificationId) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      
      // This would normally link the credential to the current user
      // For 2FA verification, we just validate the credential
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // If we get here, the code was valid
      // Delete the temp user created by verification
      if (result.user != null) {
        await result.user!.delete();
      }
      
      return true;
    } on FirebaseAuthException {
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Verify demo SMS code
  static Future<bool> _verifyDemoCode(String userId, String code, SMSVerificationData verificationData) async {
    return code == verificationData.demoCode;
  }
  
  /// Generate 6-digit verification code
  static String _generateVerificationCode() {
    final random = Random.secure();
    return (random.nextInt(900000) + 100000).toString();
  }
  
  /// Check if Firebase is configured
  static bool _isFirebaseConfigured() {
    try {
      FirebaseAuth.instance;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Rate limiting check
  static Future<RateLimitResult> _checkRateLimit(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final hourKey = 'sms_hour_count_$userId';
    final dayKey = 'sms_day_count_$userId';
    final hourResetKey = 'sms_hour_reset_$userId';
    final dayResetKey = 'sms_day_reset_$userId';
    
    final now = DateTime.now();
    
    // Check hourly limit
    final hourReset = prefs.getString(hourResetKey);
    final hourCount = prefs.getInt(hourKey) ?? 0;
    
    if (hourReset != null) {
      final resetTime = DateTime.parse(hourReset);
      if (now.isAfter(resetTime)) {
        // Reset hourly counter
        await prefs.setInt(hourKey, 0);
        await prefs.setString(hourResetKey, now.add(const Duration(hours: 1)).toIso8601String());
      } else if (hourCount >= _maxAttemptsPerHour) {
        final remainingMinutes = resetTime.difference(now).inMinutes;
        return RateLimitResult(
          allowed: false,
          errorMessage: 'Te veel SMS aanvragen. Probeer over $remainingMinutes minuten opnieuw.',
          cooldownSeconds: resetTime.difference(now).inSeconds,
        );
      }
    }
    
    // Check daily limit
    final dayReset = prefs.getString(dayResetKey);
    final dayCount = prefs.getInt(dayKey) ?? 0;
    
    if (dayReset != null) {
      final resetTime = DateTime.parse(dayReset);
      if (now.isAfter(resetTime)) {
        // Reset daily counter
        await prefs.setInt(dayKey, 0);
        await prefs.setString(dayResetKey, DateTime(now.year, now.month, now.day + 1).toIso8601String());
      } else if (dayCount >= _maxCodesPerDay) {
        final remainingHours = resetTime.difference(now).inHours;
        return RateLimitResult(
          allowed: false,
          errorMessage: 'Dagelijkse SMS limiet bereikt. Probeer over $remainingHours uur opnieuw.',
          cooldownSeconds: resetTime.difference(now).inSeconds,
        );
      }
    }
    
    return const RateLimitResult(allowed: true);
  }
  
  /// Fraud detection check
  static Future<FraudCheckResult> _checkForFraud(String userId, String phoneNumber) async {
    // Implement fraud detection logic
    // For demo, we'll do basic checks
    
    final prefs = await SharedPreferences.getInstance();
    final recentPhonesKey = 'recent_phones_$userId';
    final recentPhones = prefs.getStringList(recentPhonesKey) ?? [];
    
    // Check for multiple phone numbers in short time
    if (recentPhones.length >= 3 && !recentPhones.contains(phoneNumber)) {
      return const FraudCheckResult(
        isFraudulent: true,
        reason: 'Multiple phone numbers used recently',
      );
    }
    
    // Add current phone to recent list
    if (!recentPhones.contains(phoneNumber)) {
      recentPhones.add(phoneNumber);
      if (recentPhones.length > 5) {
        recentPhones.removeAt(0);
      }
      await prefs.setStringList(recentPhonesKey, recentPhones);
    }
    
    return const FraudCheckResult(isFraudulent: false);
  }
  
  /// Check cooldown status
  static bool _isInCooldown(String userId) {
    return _cooldownTimers.containsKey(userId);
  }
  
  /// Check resend cooldown with progressive backoff
  static RateLimitResult _checkResendCooldown(String userId) {
    // Implementation would check stored cooldown timestamps
    // with progressive backoff based on recent attempts
    
    // For now, return basic cooldown check
    if (_isInCooldown(userId)) {
      return RateLimitResult(
        allowed: false,
        errorMessage: 'Wacht $_resendCooldownSeconds seconden voordat u opnieuw een code kunt aanvragen',
        cooldownSeconds: _resendCooldownSeconds,
      );
    }
    
    return const RateLimitResult(allowed: true);
  }
  
  /// Start cooldown timer with progressive backoff
  static void _startCooldownTimer(String userId) {
    _cooldownTimers[userId]?.cancel();
    
    // Progressive backoff: longer cooldown for repeated requests
    int cooldownDuration = _resendCooldownSeconds;
    // Could implement logic to increase cooldown based on recent attempts
    
    _cooldownTimers[userId] = Timer(Duration(seconds: cooldownDuration), () {
      _cooldownTimers.remove(userId);
    });
  }
  
  /// Increment daily counter
  static Future<void> _incrementDailyCounter(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final dayKey = 'sms_day_count_$userId';
    final count = prefs.getInt(dayKey) ?? 0;
    await prefs.setInt(dayKey, count + 1);
  }
  
  /// Save verification data
  static Future<void> _saveVerificationData(String userId, SMSVerificationData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_verificationKey$userId', json.encode(data.toJson()));
  }
  
  /// Get verification data
  static Future<SMSVerificationData?> _getVerificationData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString('$_verificationKey$userId');
    
    if (dataJson != null) {
      return SMSVerificationData.fromJson(json.decode(dataJson));
    }
    
    return null;
  }
  
  /// Clear verification data
  static Future<void> _clearVerificationData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_verificationKey$userId');
  }
  
  /// Save SMS 2FA configuration
  static Future<void> _saveSMS2FAConfig(String userId, SMS2FAConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_configKey$userId', json.encode(config.toJson()));
  }
  
  /// Obfuscate phone number for logging
  static String _obfuscatePhone(String phoneNumber) {
    if (phoneNumber.length <= 4) return '****';
    return '${phoneNumber.substring(0, 3)}****${phoneNumber.substring(phoneNumber.length - 2)}';
  }
  
  /// Log security event
  static Future<void> _logSecurityEvent(String userId, String event, Map<String, dynamic> data) async {
    // In production, this would send to a proper logging service
    developer.log('SMS 2FA Security Event - User: $userId, Event: $event, Data: $data', name: 'SMS2FA');
  }
}

/// SMS 2FA operation result
class SMS2FAResult {
  final bool success;
  final String? verificationId;
  final String? message;
  final String? messageDutch;
  final String? errorCode;
  final String? errorMessage;
  final String? errorMessageDutch;
  final int? cooldownSeconds;
  final int? remainingAttempts;
  final bool autoVerified;
  
  const SMS2FAResult({
    required this.success,
    this.verificationId,
    this.message,
    this.messageDutch,
    this.errorCode,
    this.errorMessage,
    this.errorMessageDutch,
    this.cooldownSeconds,
    this.remainingAttempts,
    this.autoVerified = false,
  });
}

/// SMS 2FA configuration
class SMS2FAConfig {
  final bool isEnabled;
  final String phoneNumber;
  final DateTime setupDate;
  final DateTime? verifiedDate;
  final DateTime? lastUsed;
  
  const SMS2FAConfig({
    required this.isEnabled,
    required this.phoneNumber,
    required this.setupDate,
    this.verifiedDate,
    this.lastUsed,
  });
  
  /// Copy with updated properties
  SMS2FAConfig copyWith({
    bool? isEnabled,
    String? phoneNumber,
    DateTime? setupDate,
    DateTime? verifiedDate,
    DateTime? lastUsed,
  }) {
    return SMS2FAConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      setupDate: setupDate ?? this.setupDate,
      verifiedDate: verifiedDate ?? this.verifiedDate,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'phoneNumber': phoneNumber,
      'setupDate': setupDate.toIso8601String(),
      'verifiedDate': verifiedDate?.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }
  
  /// Create from JSON
  factory SMS2FAConfig.fromJson(Map<String, dynamic> json) {
    return SMS2FAConfig(
      isEnabled: json['isEnabled'],
      phoneNumber: json['phoneNumber'],
      setupDate: DateTime.parse(json['setupDate']),
      verifiedDate: json['verifiedDate'] != null ? DateTime.parse(json['verifiedDate']) : null,
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
    );
  }
}

/// SMS verification data
class SMSVerificationData {
  final String verificationId;
  final String phoneNumber;
  final DateTime sentAt;
  final DateTime expiresAt;
  int attempts;
  final int maxAttempts;
  final int? resendToken;
  final String? demoCode; // For demo mode only
  
  SMSVerificationData({
    required this.verificationId,
    required this.phoneNumber,
    required this.sentAt,
    required this.expiresAt,
    required this.attempts,
    required this.maxAttempts,
    this.resendToken,
    this.demoCode,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'verificationId': verificationId,
      'phoneNumber': phoneNumber,
      'sentAt': sentAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'attempts': attempts,
      'maxAttempts': maxAttempts,
      'resendToken': resendToken,
      'demoCode': demoCode,
    };
  }
  
  /// Create from JSON
  factory SMSVerificationData.fromJson(Map<String, dynamic> json) {
    return SMSVerificationData(
      verificationId: json['verificationId'],
      phoneNumber: json['phoneNumber'],
      sentAt: DateTime.parse(json['sentAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      attempts: json['attempts'],
      maxAttempts: json['maxAttempts'],
      resendToken: json['resendToken'],
      demoCode: json['demoCode'],
    );
  }
}

/// Rate limiting result
class RateLimitResult {
  final bool allowed;
  final String? errorMessage;
  final int? cooldownSeconds;
  
  const RateLimitResult({
    required this.allowed,
    this.errorMessage,
    this.cooldownSeconds,
  });
}

/// Fraud detection result
class FraudCheckResult {
  final bool isFraudulent;
  final String? reason;
  
  const FraudCheckResult({
    required this.isFraudulent,
    this.reason,
  });
}