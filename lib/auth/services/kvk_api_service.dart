import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../auth_service.dart';
import 'kvk_additional_classes.dart';
import 'kvk_persistent_cache.dart';
import 'kvk_rate_limiter.dart';

/// KvK address data
class KvKAddress {
  final String street;
  final String houseNumber;
  final String houseNumberAddition;
  final String postalCode;
  final String city;
  final String country;

  const KvKAddress({
    required this.street,
    required this.houseNumber,
    this.houseNumberAddition = '',
    required this.postalCode,
    required this.city,
    this.country = 'Nederland',
  });

  factory KvKAddress.fromJson(Map<String, dynamic> json) {
    return KvKAddress(
      street: json['straatnaam']?.toString() ?? '',
      houseNumber: json['huisnummer']?.toString() ?? '',
      houseNumberAddition: json['huisnummerToevoeging']?.toString() ?? '',
      postalCode: json['postcode']?.toString() ?? '',
      city: json['plaats']?.toString() ?? '',
      country: json['land']?.toString() ?? 'Nederland',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'houseNumber': houseNumber,
      'houseNumberAddition': houseNumberAddition,
      'postalCode': postalCode,
      'city': city,
      'country': country,
    };
  }

  /// Get formatted full address
  String get fullAddress {
    final parts = <String>[];
    
    if (street.isNotEmpty && houseNumber.isNotEmpty) {
      final address = '$street $houseNumber${houseNumberAddition.isNotEmpty ? houseNumberAddition : ''}';
      parts.add(address);
    }
    
    if (postalCode.isNotEmpty && city.isNotEmpty) {
      parts.add('$postalCode $city');
    }
    
    if (country.isNotEmpty && country != 'Nederland') {
      parts.add(country);
    }
    
    return parts.join(', ');
  }

  /// Validate if postal code matches Dutch format
  bool get hasValidDutchPostalCode {
    return AuthService.isValidDutchPostalCode(postalCode);
  }
}

/// Enhanced exception thrown when KvK validation fails
class KvKValidationException implements Exception {
  final String message;
  final String code;
  final String? details;
  final Map<String, dynamic>? context;
  final DateTime timestamp;

  KvKValidationException(
    this.message, {
    this.code = 'kvk-validation-failed',
    this.details,
    this.context,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Get localized Dutch error message
  String get localizedMessage {
    switch (code) {
      case 'invalid-format':
        return 'KvK nummer heeft een ongeldig formaat. Gebruik 8 cijfers.';
      case 'not-found':
        return 'KvK nummer niet gevonden in het handelsregister.';
      case 'inactive-company':
        return 'Bedrijf is niet actief in het handelsregister.';
      case 'not-security-eligible':
        return 'Bedrijf is niet geregistreerd voor beveiligingsactiviteiten.';
      case 'rate-limited':
        return message; // Already localized
      case 'network-error':
        return 'Netwerkfout bij KvK validatie. Controleer uw internetverbinding.';
      case 'timeout':
        return 'KvK validatie duurde te lang. Probeer opnieuw.';
      case 'api-error':
        return 'KvK service tijdelijk niet beschikbaar. Probeer later opnieuw.';
      case 'unauthorized':
        return 'KvK API toegang geweigerd. Neem contact op met support.';
      case 'max-retries-exceeded':
        return message; // Already localized
      default:
        return message.isNotEmpty ? message : 'KvK validatie mislukt.';
    }
  }
  
  /// Get user-friendly action suggestion
  String get actionSuggestion {
    switch (code) {
      case 'invalid-format':
        return 'Controleer of u een geldig 8-cijferig KvK nummer heeft ingevoerd.';
      case 'not-found':
        return 'Controleer het KvK nummer en probeer opnieuw.';
      case 'inactive-company':
        return 'Zorg dat uw bedrijf actief is in het handelsregister.';
      case 'not-security-eligible':
        return 'Registreer uw bedrijf voor beveiligingsactiviteiten bij de KvK.';
      case 'rate-limited':
        return 'Wacht even voordat u opnieuw probeert.';
      case 'network-error':
      case 'timeout':
        return 'Controleer uw internetverbinding en probeer opnieuw.';
      case 'api-error':
        return 'Probeer later opnieuw of neem contact op met support.';
      default:
        return 'Probeer opnieuw of neem contact op met support als het probleem aanhoudt.';
    }
  }
  
  /// Check if this is a retryable error
  bool get isRetryable {
    return ['network-error', 'timeout', 'api-error'].contains(code);
  }

  @override
  String toString() => 'KvKValidationException($code): $localizedMessage';
}

/// Security industry SBI codes for validation
class SecuritySbiCodes {
  /// Private security activities
  static const String privateSecurityActivities = '80101';
  
  /// Guard services
  static const String guardServices = '80102';
  
  /// Alarm and surveillance systems
  static const String alarmSurveillance = '80201';
  
  /// Investigation and detective services
  static const String investigation = '80301';
  
  /// All valid security SBI codes
  static const List<String> validSecurityCodes = [
    privateSecurityActivities,
    guardServices,
    alarmSurveillance,
    investigation,
  ];
  
  /// Check if SBI code is valid for security industry
  static bool isValidSecurityCode(String? sbiCode) {
    if (sbiCode == null || sbiCode.isEmpty) return false;
    return validSecurityCodes.any((code) => sbiCode.startsWith(code));
  }
  
  /// Get security industry description for SBI code
  static String getSecurityDescription(String sbiCode) {
    if (sbiCode.startsWith(privateSecurityActivities)) {
      return 'Particuliere beveiligingsdiensten';
    } else if (sbiCode.startsWith(guardServices)) {
      return 'Bewakingsdiensten';
    } else if (sbiCode.startsWith(alarmSurveillance)) {
      return 'Alarm- en bewakingssystemen';
    } else if (sbiCode.startsWith(investigation)) {
      return 'Onderzoeks- en detectivediensten';
    }
    return 'Algemene beveiligingsdiensten';
  }
}

// CompanyEligibilityResult moved to kvk_additional_classes.dart

/// Enhanced service for validating Dutch Chamber of Commerce (KvK) data
/// with production-ready features including caching, rate limiting, and security validation
class KvKApiService {
  static const String _baseUrl = 'https://api.kvk.nl/api/v1';
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const int _maxCacheAge = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
  static const int _maxRetryAttempts = 3;
  static const Duration _initialBackoffDelay = Duration(milliseconds: 500);

  // Enhanced caching with secure cache keys
  static final Map<String, SecureCachedKvKData> _cache = {};
  
  // Rate limiting with exponential backoff
  static final Map<String, DateTime> _lastRequests = {};
  static final Map<String, int> _failureCount = {};
  
  // Request deduplication
  static final Map<String, Future<KvKData?>> _ongoingRequests = {};
  
  // Audit logging
  static final List<AuditLogEntry> _auditLog = [];

  /// Enhanced KvK validation with comprehensive error handling and security checks
  /// Returns validated KvK data with eligibility assessment
  static Future<KvKData?> validateKvK(String kvkNumber, {String? apiKey, String? userId}) async {
    final startTime = DateTime.now();
    final identifier = userId ?? 'anonymous';
    
    // Enhanced format validation
    final validation = AuthService.validateKvKDetailed(kvkNumber);
    if (!validation.isValid) {
      await KvKPersistentCache.logAudit(
        kvkNumber: kvkNumber,
        action: 'validation_format_error',
        success: false,
        errorCode: 'invalid-format',
      );
      throw KvKValidationException(validation.message, code: 'invalid-format');
    }

    final cleanedKvK = kvkNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check rate limiting first
    if (!KvKRateLimiter.isRequestAllowed(identifier)) {
      final rateLimitException = KvKRateLimiter.createException(identifier);
      await KvKPersistentCache.logAudit(
        kvkNumber: cleanedKvK,
        action: 'validation_rate_limited',
        success: false,
        errorCode: 'rate-limited',
      );
      throw KvKValidationException(
        rateLimitException.dutchMessage,
        code: 'rate-limited',
        details: rateLimitException.dutchSuggestion,
      );
    }
    
    // Check for ongoing request to prevent duplicates
    if (_ongoingRequests.containsKey(cleanedKvK)) {
      debugPrint('KvK validation already in progress for $cleanedKvK, waiting for result...');
      return await _ongoingRequests[cleanedKvK];
    }
    
    // Check persistent cache first
    final cachedData = await KvKPersistentCache.retrieve(cleanedKvK);
    if (cachedData != null) {
      debugPrint('KvK data retrieved from persistent cache for $cleanedKvK');
      await KvKPersistentCache.logAudit(
        kvkNumber: cleanedKvK,
        action: 'validation_cache_hit',
        success: true,
        source: 'persistent_cache',
      );
      return cachedData;
    }
    
    // Check in-memory cache as fallback
    final memoryCache = _getSecureCachedData(cleanedKvK);
    if (memoryCache != null) {
      debugPrint('KvK data retrieved from memory cache for $cleanedKvK');
      await KvKPersistentCache.logAudit(
        kvkNumber: cleanedKvK,
        action: 'validation_cache_hit',
        success: true,
        source: 'memory_cache',
      );
      return memoryCache.data;
    }
    
    // Create and track the ongoing request
    final requestFuture = _performValidationWithRetry(cleanedKvK, apiKey, startTime, identifier);
    _ongoingRequests[cleanedKvK] = requestFuture;
    
    try {
      final result = await requestFuture;
      return result;
    } finally {
      _ongoingRequests.remove(cleanedKvK);
    }
  }
  
  /// Perform validation with retry logic and exponential backoff
  static Future<KvKData?> _performValidationWithRetry(String cleanedKvK, String? apiKey, DateTime startTime, String identifier) async {
    KvKData? result;
    Exception? lastException;
    
    for (int attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      try {
        // In production, use real KvK API
        if (apiKey != null && apiKey.isNotEmpty) {
          result = await _validateWithKvKAPI(cleanedKvK, apiKey);
        } else {
          // Enhanced demo mode with realistic data
          result = await _generateEnhancedMockKvKData(cleanedKvK);
        }
        
        if (result != null) {
          // Enhanced validation with security industry check
          final validatedData = _enhanceWithSecurityValidation(result);
          
          // Store in both caches
          await KvKPersistentCache.store(cleanedKvK, validatedData);
          _cacheSecureData(cleanedKvK, validatedData);
          
          // Record successful request for rate limiting
          KvKRateLimiter.recordSuccessfulRequest(identifier);
          
          final duration = DateTime.now().difference(startTime);
          await KvKPersistentCache.logAudit(
            kvkNumber: cleanedKvK,
            action: 'validation_success',
            success: true,
            durationMs: duration.inMilliseconds,
            source: apiKey != null ? 'kvk_api' : 'mock_data',
          );
          
          _resetFailureCount(cleanedKvK);
          return validatedData;
        }
        break;
      } catch (e) {
        lastException = e as Exception;
        debugPrint('KvK validation attempt $attempt failed for $cleanedKvK: $e');
        
        // Record failed request for rate limiting on final attempt
        if (attempt == _maxRetryAttempts) {
          KvKRateLimiter.recordFailedRequest(identifier);
        }
        
        if (e is KvKValidationException && e.code != 'network-error' && e.code != 'timeout') {
          // Don't retry for non-transient errors
          final duration = DateTime.now().difference(startTime);
          await KvKPersistentCache.logAudit(
            kvkNumber: cleanedKvK,
            action: 'validation_error',
            success: false,
            errorCode: e.code,
            durationMs: duration.inMilliseconds,
          );
          _incrementFailureCount(cleanedKvK);
          rethrow;
        }
        
        if (attempt < _maxRetryAttempts) {
          final backoffDelay = _calculateBackoffDelay(attempt);
          debugPrint('Retrying KvK validation in ${backoffDelay.inMilliseconds}ms...');
          await Future.delayed(backoffDelay);
        }
      }
    }
    
    // All retry attempts failed
    _incrementFailureCount(cleanedKvK);
    final duration = DateTime.now().difference(startTime);
    await KvKPersistentCache.logAudit(
      kvkNumber: cleanedKvK,
      action: 'validation_failed_max_retries',
      success: false,
      errorCode: 'max-retries-exceeded',
      durationMs: duration.inMilliseconds,
    );
    
    if (lastException is KvKValidationException) {
      throw lastException;
    }
    
    throw KvKValidationException(
      'KvK validatie mislukt na $_maxRetryAttempts pogingen. Controleer uw internetverbinding en probeer opnieuw.',
      code: 'max-retries-exceeded',
    );
  }

  /// Validate with real KvK API with enhanced error handling and response processing
  static Future<KvKData?> _validateWithKvKAPI(String kvkNumber, String apiKey) async {
    final uri = Uri.parse('$_baseUrl/zoeken?kvkNummer=$kvkNumber');
    
    try {
      final response = await http.get(
        uri,
        headers: {
          'apikey': apiKey,
          'Accept': 'application/json',
          'User-Agent': 'SecuryFlex-App/1.0',
          'Cache-Control': 'no-cache',
        },
      ).timeout(_requestTimeout);

      _recordRequest(kvkNumber);

      // Enhanced response handling
      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          throw KvKValidationException(
            'KvK API heeft lege response teruggestuurd',
            code: 'empty-response',
          );
        }

        Map<String, dynamic> data;
        try {
          data = json.decode(responseBody) as Map<String, dynamic>;
        } catch (e) {
          throw KvKValidationException(
            'KvK API response kon niet worden verwerkt',
            code: 'invalid-json',
            details: 'JSON parsing failed: $e',
          );
        }
        
        // Enhanced result processing
        if (data['resultaten'] != null && data['resultaten'].isNotEmpty) {
          final resultList = data['resultaten'] as List<dynamic>;
          final firstResult = resultList.first as Map<String, dynamic>;
          
          try {
            final kvkData = KvKData.fromJson(firstResult);
            
            // Additional validation for required fields
            if (kvkData.companyName.isEmpty) {
              throw KvKValidationException(
                'KvK data onvolledig: bedrijfsnaam ontbreekt',
                code: 'incomplete-data',
              );
            }
            
            final enhancedData = _enhanceWithSecurityValidation(kvkData);
            _cacheSecureData(kvkNumber, enhancedData);
            return enhancedData;
          } catch (e) {
            if (e is KvKValidationException) rethrow;
            throw KvKValidationException(
              'KvK data kon niet worden verwerkt',
              code: 'data-processing-error',
              details: e.toString(),
            );
          }
        } else {
          throw KvKValidationException(
            'KvK nummer $kvkNumber niet gevonden in het handelsregister',
            code: 'not-found',
            details: 'Resultaten array is leeg of null',
          );
        }
      } else if (response.statusCode == 429) {
        final retryAfter = response.headers['retry-after'];
        final waitMessage = retryAfter != null 
          ? 'Probeer opnieuw over $retryAfter seconden.'
          : 'Probeer later opnieuw.';
        throw KvKValidationException(
          'Te veel KvK opzoekingen. $waitMessage',
          code: 'rate-limited',
          details: 'HTTP 429 - Rate limit exceeded',
        );
      } else if (response.statusCode == 401) {
        throw KvKValidationException(
          'KvK API sleutel ongeldig. Neem contact op met support.',
          code: 'unauthorized',
          details: 'HTTP 401 - API key invalid',
        );
      } else if (response.statusCode == 403) {
        throw KvKValidationException(
          'KvK API toegang geweigerd. Controleer API rechten.',
          code: 'forbidden',
          details: 'HTTP 403 - Access forbidden',
        );
      } else if (response.statusCode == 404) {
        throw KvKValidationException(
          'KvK API endpoint niet gevonden.',
          code: 'endpoint-not-found',
          details: 'HTTP 404 - Endpoint not found',
        );
      } else if (response.statusCode >= 500) {
        throw KvKValidationException(
          'KvK service tijdelijk niet beschikbaar. Probeer later opnieuw.',
          code: 'server-error',
          details: 'HTTP ${response.statusCode} - ${response.reasonPhrase}',
        );
      } else {
        throw KvKValidationException(
          'KvK service fout: onverwachte response (${response.statusCode})',
          code: 'unexpected-response',
          details: 'HTTP ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } on TimeoutException {
      throw KvKValidationException(
        'KvK validatie time-out na ${_requestTimeout.inSeconds} seconden. Controleer uw internetverbinding.',
        code: 'timeout',
        details: 'Request timeout after ${_requestTimeout.inSeconds}s',
      );
    } on http.ClientException catch (e) {
      throw KvKValidationException(
        'Netwerkfout bij KvK validatie. Controleer uw internetverbinding.',
        code: 'network-error',
        details: 'ClientException: ${e.message}',
      );
    } on SocketException catch (e) {
      throw KvKValidationException(
        'Geen internetverbinding beschikbaar voor KvK validatie.',
        code: 'no-internet',
        details: 'SocketException: ${e.message}',
      );
    } catch (e) {
      throw KvKValidationException(
        'Onverwachte fout bij KvK validatie',
        code: 'unexpected-error',
        details: e.toString(),
      );
    }
  }

  /// Enhance KvK data with security industry validation
  static KvKData _enhanceWithSecurityValidation(KvKData originalData) {
    // Calculate eligibility score based on multiple factors
    double eligibilityScore = 0.0;
    final List<String> eligibilityReasons = [];
    
    // Check if company is active (40% weight)
    if (originalData.isActive) {
      eligibilityScore += 0.4;
      eligibilityReasons.add('Bedrijf is actief in handelsregister');
    }
    
    // Check SBI code for security industry (40% weight)
    if (SecuritySbiCodes.isValidSecurityCode(originalData.sbiCode)) {
      eligibilityScore += 0.4;
      eligibilityReasons.add('Geregistreerd voor beveiligingsactiviteiten');
    }
    
    // Check company age (10% weight)
    if (originalData.foundationDate != null) {
      final age = DateTime.now().difference(originalData.foundationDate!);
      if (age.inDays > 365) { // More than 1 year old
        eligibilityScore += 0.1;
        eligibilityReasons.add('Bedrijf bestaat langer dan 1 jaar');
      }
    }
    
    // Check completeness of data (10% weight)
    if (originalData.address != null && 
        originalData.phoneNumber != null && 
        originalData.website != null) {
      eligibilityScore += 0.1;
      eligibilityReasons.add('Complete bedrijfsinformatie beschikbaar');
    }
    
    final isSecurityEligible = eligibilityScore >= 0.5; // 50% minimum threshold
    
    return KvKData(
      kvkNumber: originalData.kvkNumber,
      companyName: originalData.companyName,
      tradeName: originalData.tradeName,
      legalForm: originalData.legalForm,
      address: originalData.address,
      isActive: originalData.isActive,
      foundationDate: originalData.foundationDate,
      website: originalData.website,
      phoneNumber: originalData.phoneNumber,
      sbiCode: originalData.sbiCode,
      sbiDescription: originalData.sbiDescription,
      isSecurityEligible: isSecurityEligible,
      eligibilityScore: eligibilityScore,
      eligibilityReasons: eligibilityReasons,
    );
  }
  
  /// Calculate eligibility for security industry (static method for external use)
  static CompanyEligibilityResult calculateSecurityEligibility(KvKData kvkData) {
    double score = 0.0;
    final List<String> reasons = [];
    final List<String> requirements = [];
    
    // Active company requirement
    if (kvkData.isActive) {
      score += 0.4;
      reasons.add('Bedrijf is actief geregistreerd');
    } else {
      requirements.add('Bedrijf moet actief zijn in het handelsregister');
    }
    
    // Security industry SBI code requirement
    if (SecuritySbiCodes.isValidSecurityCode(kvkData.sbiCode)) {
      score += 0.4;
      reasons.add('Geregistreerd voor beveiligingsactiviteiten (SBI: ${kvkData.sbiCode})');
    } else {
      requirements.add('Registratie voor beveiligingsactiviteiten (SBI codes: ${SecuritySbiCodes.validSecurityCodes.join(", ")})');
    }
    
    // Company maturity
    if (kvkData.foundationDate != null) {
      final age = DateTime.now().difference(kvkData.foundationDate!);
      if (age.inDays > 365) {
        score += 0.1;
        reasons.add('Bedrijf bestaat ${(age.inDays / 365).floor()} jaar');
      } else {
        requirements.add('Bedrijf moet minimaal 1 jaar bestaan');
      }
    }
    
    // Data completeness
    if (kvkData.address?.hasValidDutchPostalCode == true) {
      score += 0.05;
      reasons.add('Geldig Nederlands adres');
    }
    if (kvkData.phoneNumber?.isNotEmpty == true) {
      score += 0.025;
      reasons.add('Telefoonnummer beschikbaar');
    }
    if (kvkData.website?.isNotEmpty == true) {
      score += 0.025;
      reasons.add('Website beschikbaar');
    }
    
    final isEligible = score >= 0.5;
    
    return CompanyEligibilityResult(
      isEligible: isEligible,
      score: score,
      reasons: reasons,
      requirements: requirements,
    );
  }
  
  /// Generate enhanced mock KvK data for demo/testing purposes
  static Future<KvKData> _generateEnhancedMockKvKData(String kvkNumber) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final mockCompanies = {
      '12345678': KvKData(
        kvkNumber: '12345678',
        companyName: 'Amsterdam Security Services B.V.',
        tradeName: 'Amsterdam Security',
        legalForm: 'Besloten vennootschap',
        address: const KvKAddress(
          street: 'Damrak',
          houseNumber: '123',
          postalCode: '1012AB',
          city: 'Amsterdam',
        ),
        isActive: true,
        foundationDate: DateTime(2015, 3, 15),
        website: 'https://amsterdamsecurity.nl',
        phoneNumber: '+31 20 123 4567',
        sbiCode: '80100',
        sbiDescription: 'Particuliere beveiliging',
      ),
      '87654321': KvKData(
        kvkNumber: '87654321',
        companyName: 'SecuryFlex Nederland B.V.',
        tradeName: 'SecuryFlex',
        legalForm: 'Besloten vennootschap',
        address: const KvKAddress(
          street: 'Zuidas',
          houseNumber: '456',
          postalCode: '1082AB',
          city: 'Amsterdam',
        ),
        isActive: true,
        foundationDate: DateTime(2020, 1, 1),
        website: 'https://securyflex.nl',
        phoneNumber: '+31 20 987 6543',
        sbiCode: '80200',
        sbiDescription: 'Beveiligingssystemen',
      ),
    };

    final mockData = mockCompanies[kvkNumber];
    if (mockData != null) {
      _cacheSecureData(kvkNumber, mockData);
      return mockData;
    }

    // Generate generic company for any other KvK number
    final data = KvKData(
      kvkNumber: kvkNumber,
      companyName: 'Demo Beveiligingsbedrijf B.V.',
      tradeName: 'Demo Security',
      legalForm: 'Besloten vennootschap',
      address: const KvKAddress(
        street: 'Hoofdstraat',
        houseNumber: '1',
        postalCode: '1234AB',
        city: 'Amsterdam',
      ),
      isActive: true,
      foundationDate: DateTime.now().subtract(const Duration(days: 365)),
      website: 'https://demo-security.nl',
      phoneNumber: '+31 20 000 0000',
      sbiCode: '80100',
      sbiDescription: 'Particuliere beveiliging',
    );

    _cacheSecureData(kvkNumber, data);
    return data;
  }

  /// Check if company is registered and active
  static Future<bool> isValidActiveCompany(String kvkNumber, {String? apiKey}) async {
    try {
      final data = await validateKvK(kvkNumber, apiKey: apiKey);
      return data?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Batch validate multiple KvK numbers (useful for bulk operations)
  static Future<Map<String, KvKData?>> validateMultiple(
    List<String> kvkNumbers, 
    {String? apiKey}
  ) async {
    final results = <String, KvKData?>{};
    
    for (final kvkNumber in kvkNumbers) {
      try {
        results[kvkNumber] = await validateKvK(kvkNumber, apiKey: apiKey);
        // Add small delay to respect rate limits
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        results[kvkNumber] = null;
        debugPrint('Failed to validate KvK $kvkNumber: $e');
      }
    }
    
    return results;
  }

  /// Clear the cache
  static void clearCache() {
    _cache.clear();
    debugPrint('KvK cache cleared');
  }

  /// Get secure cached data if valid and not expired
  static SecureCachedKvKData? _getSecureCachedData(String kvkNumber) {
    final cached = _cache[kvkNumber];
    if (cached == null) return null;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - cached.timestamp > _maxCacheAge) {
      _cache.remove(kvkNumber);
      return null;
    }
    
    // Verify cache integrity
    if (!cached.verifyIntegrity()) {
      debugPrint('Cache integrity check failed for $kvkNumber, removing from cache');
      _cache.remove(kvkNumber);
      return null;
    }
    
    return cached;
  }

  /// Cache KvK data securely with timestamp and integrity check
  static void _cacheSecureData(String kvkNumber, KvKData data) {
    _cache[kvkNumber] = SecureCachedKvKData(
      data: data,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    
    // Limit cache size to prevent memory issues
    if (_cache.length > 100) {
      _cleanupOldCacheEntries();
    }
  }
  
  /// Cleanup old cache entries to prevent memory bloat
  static void _cleanupOldCacheEntries() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys = _cache.entries
        .where((entry) => now - entry.value.timestamp > _maxCacheAge)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
    
    // If still too many entries, remove oldest ones
    if (_cache.length > 100) {
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      final toRemove = sortedEntries.take(_cache.length - 80).map((e) => e.key);
      for (final key in toRemove) {
        _cache.remove(key);
      }
    }
  }

  /// Record request timestamp for rate limiting
  static void _recordRequest(String kvkNumber) {
    _lastRequests[kvkNumber] = DateTime.now();
  }
  
  /// Increment failure count for exponential backoff
  static void _incrementFailureCount(String kvkNumber) {
    _failureCount[kvkNumber] = (_failureCount[kvkNumber] ?? 0) + 1;
  }
  
  /// Reset failure count on successful request
  static void _resetFailureCount(String kvkNumber) {
    _failureCount.remove(kvkNumber);
  }
  
  /// Calculate exponential backoff delay
  static Duration _calculateBackoffDelay(int attempt) {
    final baseDelay = _initialBackoffDelay.inMilliseconds;
    final exponentialDelay = baseDelay * (1 << (attempt - 1));
    final maxDelay = 10000; // Max 10 seconds
    return Duration(milliseconds: exponentialDelay.clamp(baseDelay, maxDelay));
  }
  
  /// Search companies by name with filtering
  static Future<List<KvKData>> searchCompaniesByName(
    String name, 
    {String? city, 
     bool activeOnly = true,
     int maxResults = 50,
     String? apiKey}
  ) async {
    debugPrint('Searching companies by name: $name');
    
    // In demo mode, return mock search results
    if (apiKey == null || apiKey.isEmpty) {
      final mockResults = <KvKData>[];
      
      // Generate some mock companies based on search term
      for (int i = 1; i <= maxResults.clamp(1, 5); i++) {
        final kvkNumber = (12345670 + i).toString();
        final mockData = await _generateEnhancedMockKvKData(kvkNumber);
        
        // Customize company name based on search term
        final customData = mockData.copyWith(
          companyName: '$name Security Services ${i == 1 ? 'B.V.' : 'N.V.'}',
          tradeName: '$name Security $i',
        );
        
        if (!activeOnly || customData.isActive) {
          mockResults.add(customData);
        }
      }
      
      return mockResults;
    }
    
    // In production, implement actual API search
    // This would use the KvK API search endpoint
    try {
      final uri = Uri.parse('$_baseUrl/zoeken').replace(queryParameters: {
        'naam': name,
        if (city != null) 'plaats': city,
        if (activeOnly) 'actief': 'true',
        'aantal': maxResults.toString(),
      });
      
      final response = await http.get(
        uri,
        headers: {
          'apikey': apiKey,
          'Accept': 'application/json',
          'User-Agent': 'SecuryFlex-App/1.0',
        },
      ).timeout(_requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = <KvKData>[];
        
        if (data['resultaten'] != null) {
          for (final item in data['resultaten']) {
            final kvkData = KvKData.fromJson(item);
            final enhancedData = _enhanceWithSecurityValidation(kvkData);
            results.add(enhancedData);
          }
        }
        
        return results;
      } else {
        throw KvKValidationException(
          'Zoeken mislukt: ${response.statusCode}',
          code: 'search-failed',
        );
      }
    } catch (e) {
      debugPrint('Search by name failed: $e');
      throw KvKValidationException(
        'Zoeken naar bedrijven mislukt',
        code: 'search-error',
      );
    }
  }

  /// Reset service state (clear caches, reset counters)
  static void resetService() {
    _cache.clear();
    _lastRequests.clear();
    _failureCount.clear();
    _ongoingRequests.clear();
    _auditLog.clear();
    debugPrint('KvK service state reset');
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final validEntries = _cache.values.where((entry) => 
      now - entry.timestamp <= _maxCacheAge
    ).length;
    
    final totalRequests = _auditLog.length;
    final successfulRequests = _auditLog.where((e) => e.data['success'] == true).length;
    final cacheHits = _auditLog.where((e) => e.data['fromCache'] == true).length;
    
    return {
      'cache': {
        'totalEntries': _cache.length,
        'validEntries': validEntries,
        'expiredEntries': _cache.length - validEntries,
        'hitRate': totalRequests > 0 ? cacheHits / totalRequests : 0.0,
        'memoryUsage': '${(_cache.length * 0.5).toStringAsFixed(1)} KB',
      },
      'rateLimiting': {
        'rateLimitedKvKs': _failureCount.length,
        'ongoingRequests': _ongoingRequests.length,
      },
      'requests': {
        'total': totalRequests,
        'successful': successfulRequests,
        'failed': totalRequests - successfulRequests,
      },
      'audit': {
        'totalLogEntries': _auditLog.length,
        'oldestEntry': _auditLog.isNotEmpty ? _auditLog.first.timestamp.toIso8601String() : null,
        'newestEntry': _auditLog.isNotEmpty ? _auditLog.last.timestamp.toIso8601String() : null,
      },
    };
  }
  
  /// Export audit log entries for compliance and debugging
  static List<AuditLogEntry> exportAuditLog({int? lastHours}) {
    if (lastHours == null) {
      return List.from(_auditLog);
    }
    
    final cutoffTime = DateTime.now().subtract(Duration(hours: lastHours));
    return _auditLog.where((entry) => entry.timestamp.isAfter(cutoffTime)).toList();
  }
  
  /// Clear audit log
  static void clearAuditLog() {
    _auditLog.clear();
    debugPrint('KvK audit log cleared');
  }
  
  /// Validate company status for security eligibility
  static Future<CompanyValidationStatus?> validateCompanyStatus(String kvkNumber) async {
    try {
      final kvkData = await validateKvK(kvkNumber);
      if (kvkData != null) {
        return CompanyValidationStatus(
          kvkNumber: kvkNumber,
          isValid: true,
          isActive: kvkData.isActive,
          isSecurityEligible: kvkData.isSecurityEligible,
          eligibilityScore: kvkData.eligibilityScore,
          companyData: kvkData,
          dutchStatusDescription: kvkData.eligibilityStatusDutch,
        );
      }
      return CompanyValidationStatus(
        kvkNumber: kvkNumber,
        isValid: false,
        isActive: false,
        isSecurityEligible: false,
        eligibilityScore: 0.0,
        errorMessage: 'KvK nummer niet gevonden',
        dutchStatusDescription: 'Niet gevalideerd',
      );
    } catch (e) {
      debugPrint('Error validating company status: $e');
      return CompanyValidationStatus(
        kvkNumber: kvkNumber,
        isValid: false,
        isActive: false,
        isSecurityEligible: false,
        eligibilityScore: 0.0,
        errorMessage: e.toString(),
        dutchStatusDescription: 'Validatie mislukt',
      );
    }
  }
}

// Internal classes moved to kvk_additional_classes.dart to avoid duplication