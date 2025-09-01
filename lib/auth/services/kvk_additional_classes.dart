import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'kvk_api_service.dart';

/// Secure cached KvK data with integrity verification
class SecureCachedKvKData {
  final KvKData data;
  final int timestamp;
  final String _checksum;

  SecureCachedKvKData({
    required this.data,
    required this.timestamp,
  }) : _checksum = _calculateChecksum(data, timestamp);

  /// Calculate checksum for integrity verification
  static String _calculateChecksum(KvKData data, int timestamp) {
    final content = '${data.kvkNumber}:${data.companyName}:$timestamp';
    return md5.convert(utf8.encode(content)).toString().substring(0, 8);
  }

  /// Verify data integrity
  bool verifyIntegrity() {
    final expectedChecksum = _calculateChecksum(data, timestamp);
    return _checksum == expectedChecksum;
  }

  /// Get age in hours
  double get ageInHours {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - timestamp) / (1000 * 60 * 60);
  }
}

/// Audit log entry for KvK validation operations
class AuditLogEntry {
  final DateTime timestamp;
  final String action;
  final String kvkNumber;
  final Map<String, dynamic> data;
  final String? userId;
  final bool success;
  final String? errorCode;

  AuditLogEntry({
    required this.timestamp,
    required this.action,
    required this.kvkNumber,
    required this.data,
    this.userId,
    this.success = true,
    this.errorCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'kvkNumber': kvkNumber,
      'data': data,
      'userId': userId,
      'success': success,
      'errorCode': errorCode,
    };
  }

  @override
  String toString() {
    return '${timestamp.toIso8601String()}: $action - $kvkNumber - $data';
  }
}

/// Enhanced KvK data model with security eligibility
class KvKData {
  final String kvkNumber;
  final String companyName;
  final String tradeName;
  final String legalForm;
  final KvKAddress? address;
  final bool isActive;
  final DateTime? foundationDate;
  final String? website;
  final String? phoneNumber;
  final String? sbiCode;
  final String? sbiDescription;
  final bool isSecurityEligible;
  final double eligibilityScore;
  final List<String> eligibilityReasons;

  const KvKData({
    required this.kvkNumber,
    required this.companyName,
    required this.tradeName,
    required this.legalForm,
    this.address,
    required this.isActive,
    this.foundationDate,
    this.website,
    this.phoneNumber,
    this.sbiCode,
    this.sbiDescription,
    this.isSecurityEligible = false,
    this.eligibilityScore = 0.0,
    this.eligibilityReasons = const [],
  });

  factory KvKData.fromJson(Map<String, dynamic> json) {
    return KvKData(
      kvkNumber: json['kvkNummer']?.toString() ?? '',
      companyName: json['naam']?.toString() ?? '',
      tradeName: json['handelsnaam']?.toString() ?? json['naam']?.toString() ?? '',
      legalForm: json['rechtsvorm']?.toString() ?? '',
      address: json['adres'] != null ? KvKAddress.fromJson(json['adres']) : null,
      isActive: json['actief'] == true || json['status'] == 'actief',
      foundationDate: json['datumOprichting'] != null 
          ? DateTime.tryParse(json['datumOprichting'].toString())
          : null,
      website: json['website']?.toString(),
      phoneNumber: json['telefoonnummer']?.toString(),
      sbiCode: json['sbiCode']?.toString(),
      sbiDescription: json['sbiOmschrijving']?.toString(),
      isSecurityEligible: json['isSecurityEligible'] ?? false,
      eligibilityScore: (json['eligibilityScore'] ?? 0.0).toDouble(),
      eligibilityReasons: (json['eligibilityReasons'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kvkNumber': kvkNumber,
      'companyName': companyName,
      'tradeName': tradeName,
      'legalForm': legalForm,
      'address': address?.toJson(),
      'isActive': isActive,
      'foundationDate': foundationDate?.toIso8601String(),
      'website': website,
      'phoneNumber': phoneNumber,
      'sbiCode': sbiCode,
      'sbiDescription': sbiDescription,
      'isSecurityEligible': isSecurityEligible,
      'eligibilityScore': eligibilityScore,
      'eligibilityReasons': eligibilityReasons,
    };
  }

  /// Get formatted display name for the company
  String get displayName {
    if (tradeName.isNotEmpty && tradeName != companyName) {
      return '$tradeName ($companyName)';
    }
    return companyName;
  }

  /// Get formatted eligibility status in Dutch
  String get eligibilityStatusDutch {
    if (isSecurityEligible) {
      return 'Geschikt voor beveiligingsopdrachten (${(eligibilityScore * 100).toInt()}%)';
    } else {
      return 'Niet geschikt voor beveiligingsopdrachten (${(eligibilityScore * 100).toInt()}%)';
    }
  }

  /// Get company age in years
  int? get ageInYears {
    if (foundationDate == null) return null;
    final now = DateTime.now();
    return now.year - foundationDate!.year;
  }

  /// Get business activities (based on SBI code and description)
  List<String> get businessActivities {
    final activities = <String>[];
    
    if (sbiDescription?.isNotEmpty == true) {
      activities.add(sbiDescription!);
    }
    
    // Add specific security activities if applicable
    if (sbiCode != null) {
      final securityDescription = SecuritySbiCodes.getSecurityDescription(sbiCode!);
      if (securityDescription != 'Algemene beveiligingsdiensten' && 
          !activities.contains(securityDescription)) {
        activities.add(securityDescription);
      }
    }
    
    // If no specific activities, add general business description
    if (activities.isEmpty) {
      activities.add('Algemene bedrijfsactiviteiten');
    }
    
    return activities;
  }
  
  /// Check if company is suitable for security work
  bool get isSuitableForSecurity => isSecurityEligible;
  
  /// Calculate data completeness score (0.0 - 1.0)
  double get dataCompletenessScore {
    double score = 0.0;
    int totalFields = 8;
    
    if (companyName.isNotEmpty) score += 1.0;
    if (tradeName.isNotEmpty) score += 1.0;
    if (legalForm.isNotEmpty) score += 1.0;
    if (address != null) score += 1.0;
    if (foundationDate != null) score += 1.0;
    if (website?.isNotEmpty == true) score += 1.0;
    if (phoneNumber?.isNotEmpty == true) score += 1.0;
    if (sbiDescription?.isNotEmpty == true) score += 1.0;
    
    return score / totalFields;
  }

  /// Create a copy with updated values
  KvKData copyWith({
    String? kvkNumber,
    String? companyName,
    String? tradeName,
    String? legalForm,
    KvKAddress? address,
    bool? isActive,
    DateTime? foundationDate,
    String? website,
    String? phoneNumber,
    String? sbiCode,
    String? sbiDescription,
    bool? isSecurityEligible,
    double? eligibilityScore,
    List<String>? eligibilityReasons,
  }) {
    return KvKData(
      kvkNumber: kvkNumber ?? this.kvkNumber,
      companyName: companyName ?? this.companyName,
      tradeName: tradeName ?? this.tradeName,
      legalForm: legalForm ?? this.legalForm,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      foundationDate: foundationDate ?? this.foundationDate,
      website: website ?? this.website,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      sbiCode: sbiCode ?? this.sbiCode,
      sbiDescription: sbiDescription ?? this.sbiDescription,
      isSecurityEligible: isSecurityEligible ?? this.isSecurityEligible,
      eligibilityScore: eligibilityScore ?? this.eligibilityScore,
      eligibilityReasons: eligibilityReasons ?? this.eligibilityReasons,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KvKData &&
          runtimeType == other.runtimeType &&
          kvkNumber == other.kvkNumber;

  @override
  int get hashCode => kvkNumber.hashCode;

  @override
  String toString() {
    return 'KvKData{kvkNumber: $kvkNumber, companyName: $companyName, isActive: $isActive, isSecurityEligible: $isSecurityEligible}';
  }
}

/// Advanced validation result with detailed feedback
class KvKValidationResult {
  final String kvkNumber;
  final KvKData? data;
  final String? message;
  final String? errorCode;
  final List<String> warnings;
  final Map<String, dynamic> metadata;
  
  // Convenience getters
  bool get isSuccess => data != null && errorCode == null;
  bool get isError => data == null || errorCode != null;
  bool get isValid => isSuccess;

  const KvKValidationResult({
    required this.kvkNumber,
    this.data,
    this.message,
    this.errorCode,
    this.warnings = const [],
    this.metadata = const {},
    bool? isSuccess,
    bool? isError,
  });

  factory KvKValidationResult.success(String kvkNumber, KvKData data, {List<String> warnings = const []}) {
    return KvKValidationResult(
      kvkNumber: kvkNumber,
      isSuccess: true,
      data: data,
      message: 'KvK validatie succesvol',
      warnings: warnings,
      metadata: {
        'validatedAt': DateTime.now().toIso8601String(),
        'source': 'kvk_api',
      },
    );
  }

  factory KvKValidationResult.error(String kvkNumber, String error, {String? errorCode, Map<String, dynamic>? metadata}) {
    return KvKValidationResult(
      kvkNumber: kvkNumber,
      isError: true,
      message: error,
      errorCode: errorCode,
      metadata: metadata ?? {},
    );
  }

  /// Get Dutch error message
  String get dutchErrorMessage {
    if (message == null) return '';
    
    switch (errorCode) {
      case 'invalid-format':
        return 'KvK nummer heeft een ongeldig formaat. Gebruik 8 cijfers.';
      case 'not-found':
        return 'KvK nummer niet gevonden in het handelsregister.';
      case 'inactive-company':
        return 'Bedrijf is niet actief in het handelsregister.';
      case 'not-security-eligible':
        return 'Bedrijf is niet geregistreerd voor beveiligingsactiviteiten.';
      case 'rate-limited':
        return 'Te veel KvK opzoekingen. Wacht even voordat u opnieuw probeert.';
      case 'network-error':
        return 'Netwerkfout. Controleer uw internetverbinding.';
      case 'api-error':
        return 'KvK service tijdelijk niet beschikbaar. Probeer later opnieuw.';
      default:
        return message ?? 'KvK validatie mislukt';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'kvkNumber': kvkNumber,
      'isSuccess': isSuccess,
      'isError': isError,
      'data': data?.toJson(),
      'message': message,
      'errorCode': errorCode,
      'warnings': warnings,
      'metadata': metadata,
    };
  }
}

/// Batch validation result for multiple KvK numbers
class BatchKvKValidationResult {
  final Map<String, KvKValidationResult> results;
  final int totalProcessed;
  final int successCount;
  final int errorCount;
  final Duration processingTime;
  final List<String> errors;

  const BatchKvKValidationResult({
    required this.results,
    required this.totalProcessed,
    required this.successCount,
    required this.errorCount,
    required this.processingTime,
    required this.errors,
  });

  factory BatchKvKValidationResult.fromResults(
    Map<String, KvKValidationResult> results,
    DateTime startTime,
  ) {
    final successCount = results.values.where((r) => r.isSuccess).length;
    final errors = results.values
        .where((r) => r.isError && r.message != null)
        .map((r) => r.message!)
        .toList();

    return BatchKvKValidationResult(
      results: results,
      totalProcessed: results.length,
      successCount: successCount,
      errorCount: results.length - successCount,
      processingTime: DateTime.now().difference(startTime),
      errors: errors,
    );
  }

  /// Get summary in Dutch
  String get dutchSummary {
    return '$successCount van de $totalProcessed KvK nummers succesvol gevalideerd in ${processingTime.inSeconds} seconden';
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.map((key, value) => MapEntry(key, value.toJson())),
      'totalProcessed': totalProcessed,
      'successCount': successCount,
      'errorCount': errorCount,
      'processingTimeMs': processingTime.inMilliseconds,
      'errors': errors,
    };
  }
}

/// Company search criteria for advanced searching
class CompanySearchCriteria {
  final String? name;
  final String? city;
  final String? postalCode;
  final List<String>? sbiCodes;
  final bool? activeOnly;
  final bool? securityEligibleOnly;
  final int maxResults;

  const CompanySearchCriteria({
    this.name,
    this.city,
    this.postalCode,
    this.sbiCodes,
    this.activeOnly,
    this.securityEligibleOnly,
    this.maxResults = 50,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    
    if (name != null) params['naam'] = name;
    if (city != null) params['plaats'] = city;
    if (postalCode != null) params['postcode'] = postalCode;
    if (sbiCodes != null && sbiCodes!.isNotEmpty) {
      params['sbiCode'] = sbiCodes!.join(',');
    }
    if (activeOnly == true) params['actief'] = 'true';
    params['aantal'] = maxResults.toString();
    
    return params;
  }

  /// Create criteria for security companies only
  factory CompanySearchCriteria.securityCompaniesOnly({
    String? name,
    String? city,
    int maxResults = 50,
  }) {
    return CompanySearchCriteria(
      name: name,
      city: city,
      sbiCodes: SecuritySbiCodes.validSecurityCodes,
      activeOnly: true,
      securityEligibleOnly: true,
      maxResults: maxResults,
    );
  }
}

/// Company statistics for analytics
class CompanyStatistics {
  final int totalCompanies;
  final int activeCompanies;
  final int securityEligibleCompanies;
  final Map<String, int> companiesByCity;
  final Map<String, int> companiesBySbiCode;
  final double averageEligibilityScore;

  const CompanyStatistics({
    required this.totalCompanies,
    required this.activeCompanies,
    required this.securityEligibleCompanies,
    required this.companiesByCity,
    required this.companiesBySbiCode,
    required this.averageEligibilityScore,
  });

  factory CompanyStatistics.fromCompanies(List<KvKData> companies) {
    final activeCompanies = companies.where((c) => c.isActive).length;
    final securityEligibleCompanies = companies.where((c) => c.isSecurityEligible).length;
    
    final companiesByCity = <String, int>{};
    final companiesBySbiCode = <String, int>{};
    double totalScore = 0.0;
    
    for (final company in companies) {
      // Count by city
      if (company.address?.city != null) {
        final city = company.address!.city;
        companiesByCity[city] = (companiesByCity[city] ?? 0) + 1;
      }
      
      // Count by SBI code
      if (company.sbiCode != null) {
        companiesBySbiCode[company.sbiCode!] = (companiesBySbiCode[company.sbiCode!] ?? 0) + 1;
      }
      
      totalScore += company.eligibilityScore;
    }
    
    return CompanyStatistics(
      totalCompanies: companies.length,
      activeCompanies: activeCompanies,
      securityEligibleCompanies: securityEligibleCompanies,
      companiesByCity: companiesByCity,
      companiesBySbiCode: companiesBySbiCode,
      averageEligibilityScore: companies.isNotEmpty ? totalScore / companies.length : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCompanies': totalCompanies,
      'activeCompanies': activeCompanies,
      'securityEligibleCompanies': securityEligibleCompanies,
      'companiesByCity': companiesByCity,
      'companiesBySbiCode': companiesBySbiCode,
      'averageEligibilityScore': averageEligibilityScore,
    };
  }

  /// Get Dutch summary
  String get dutchSummary {
    return '$totalCompanies bedrijven geregistreerd, waarvan $activeCompanies actief en $securityEligibleCompanies geschikt voor beveiligingsopdrachten';
  }
}

/// Company eligibility result
class CompanyEligibilityResult {
  final bool isEligible;
  final double score;
  final List<String> reasons;
  final List<String> requirements;
  
  const CompanyEligibilityResult({
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
}

/// Rate limiter for API requests
class RateLimiter {
  final Map<String, List<DateTime>> _requests = {};
  final int maxRequestsPerMinute;
  final Duration timeWindow;

  RateLimiter({
    this.maxRequestsPerMinute = 60,
    this.timeWindow = const Duration(minutes: 1),
  });

  /// Check if request is allowed
  bool isRequestAllowed(String identifier) {
    final now = DateTime.now();
    final requests = _requests[identifier] ?? [];
    
    // Remove old requests outside the time window
    requests.removeWhere((time) => now.difference(time) > timeWindow);
    
    // Check if under limit
    if (requests.length >= maxRequestsPerMinute) {
      return false;
    }
    
    // Add current request
    requests.add(now);
    _requests[identifier] = requests;
    
    return true;
  }

  /// Get remaining requests for identifier
  int getRemainingRequests(String identifier) {
    final now = DateTime.now();
    final requests = _requests[identifier] ?? [];
    
    // Remove old requests
    requests.removeWhere((time) => now.difference(time) > timeWindow);
    
    return maxRequestsPerMinute - requests.length;
  }

  /// Get time until next request is allowed
  Duration? getTimeUntilNextRequest(String identifier) {
    final now = DateTime.now();
    final requests = _requests[identifier] ?? [];
    
    if (requests.length < maxRequestsPerMinute) {
      return null; // Request allowed now
    }
    
    // Find oldest request within time window
    final oldestRequest = requests.reduce((a, b) => a.isBefore(b) ? a : b);
    final timeUntilExpired = timeWindow - now.difference(oldestRequest);
    
    return timeUntilExpired.isNegative ? null : timeUntilExpired;
  }

  /// Clear all rate limit data
  void clear() {
    _requests.clear();
  }
}

/// Request deduplicator to prevent duplicate simultaneous requests
class RequestDeduplicator<T> {
  final Map<String, Future<T>> _ongoingRequests = {};

  /// Get existing request or create new one
  Future<T> getOrCreate(String key, Future<T> Function() requestFactory) {
    if (_ongoingRequests.containsKey(key)) {
      if (kDebugMode) {
        debugPrint('Request deduplication: Using existing request for $key');
      }
      return _ongoingRequests[key]!;
    }

    final future = requestFactory().whenComplete(() {
      _ongoingRequests.remove(key);
    });

    _ongoingRequests[key] = future;
    return future;
  }

  /// Check if request is ongoing
  bool isOngoing(String key) {
    return _ongoingRequests.containsKey(key);
  }

  /// Cancel all ongoing requests
  void cancelAll() {
    _ongoingRequests.clear();
  }

  /// Get number of ongoing requests
  int get ongoingCount => _ongoingRequests.length;
}

/// Company validation status with detailed information
class CompanyValidationStatus {
  final String kvkNumber;
  final bool isValid;
  final bool isActive;
  final bool isSecurityEligible;
  final double eligibilityScore;
  final KvKData? companyData;
  final String? errorMessage;
  final String dutchStatusDescription;
  
  const CompanyValidationStatus({
    required this.kvkNumber,
    required this.isValid,
    required this.isActive,
    required this.isSecurityEligible,
    required this.eligibilityScore,
    this.companyData,
    this.errorMessage,
    required this.dutchStatusDescription,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'kvkNumber': kvkNumber,
      'isValid': isValid,
      'isActive': isActive,
      'isSecurityEligible': isSecurityEligible,
      'eligibilityScore': eligibilityScore,
      'companyData': companyData?.toJson(),
      'errorMessage': errorMessage,
      'dutchStatusDescription': dutchStatusDescription,
    };
  }
}
