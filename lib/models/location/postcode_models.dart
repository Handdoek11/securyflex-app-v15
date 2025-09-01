import 'package:equatable/equatable.dart';

/// Comprehensive models for Dutch postcode functionality
/// Supporting Dutch business requirements and Google Maps integration

/// Represents a Dutch postcode with coordinate information
class PostcodeCoordinate extends Equatable {
  final String postcode;
  final double latitude;
  final double longitude;
  final String? city;
  final String? province;
  final DateTime? cachedAt;
  final String? source; // 'google_maps', 'cache', 'fallback'

  const PostcodeCoordinate({
    required this.postcode,
    required this.latitude,
    required this.longitude,
    this.city,
    this.province,
    this.cachedAt,
    this.source,
  });

  factory PostcodeCoordinate.fromJson(Map<String, dynamic> json) {
    return PostcodeCoordinate(
      postcode: json['postcode'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String?,
      province: json['province'] as String?,
      cachedAt: json['cachedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['cachedAt'] as int)
          : null,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postcode': postcode,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'province': province,
      'cachedAt': cachedAt?.millisecondsSinceEpoch,
      'source': source,
    };
  }

  /// Check if cached data is still valid (24 hours)
  bool get isCacheValid {
    if (cachedAt == null) return false;
    final now = DateTime.now();
    final hoursDifference = now.difference(cachedAt!).inHours;
    return hoursDifference < 24;
  }

  PostcodeCoordinate copyWith({
    String? postcode,
    double? latitude,
    double? longitude,
    String? city,
    String? province,
    DateTime? cachedAt,
    String? source,
  }) {
    return PostcodeCoordinate(
      postcode: postcode ?? this.postcode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      province: province ?? this.province,
      cachedAt: cachedAt ?? this.cachedAt,
      source: source ?? this.source,
    );
  }

  @override
  String toString() => 'PostcodeCoordinate($postcode: $latitude, $longitude, city: $city)';

  @override
  List<Object?> get props => [postcode, latitude, longitude, city, province, cachedAt, source];
}

/// Result of detailed Dutch postcode validation
class PostcodeValidationResult extends Equatable {
  final bool isValid;
  final String? errorMessage;
  final String? errorCode;
  final String? cleanPostcode;
  final String? formattedPostcode;
  final String? province;
  final String? city;
  final List<String>? suggestions;

  const PostcodeValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorCode,
    this.cleanPostcode,
    this.formattedPostcode,
    this.province,
    this.city,
    this.suggestions,
  });

  factory PostcodeValidationResult.valid({
    required String cleanPostcode,
    required String formattedPostcode,
    String? province,
    String? city,
  }) {
    return PostcodeValidationResult(
      isValid: true,
      cleanPostcode: cleanPostcode,
      formattedPostcode: formattedPostcode,
      province: province,
      city: city,
    );
  }

  factory PostcodeValidationResult.invalid({
    required String errorMessage,
    required String errorCode,
    List<String>? suggestions,
  }) {
    return PostcodeValidationResult(
      isValid: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
      suggestions: suggestions,
    );
  }

  @override
  String toString() {
    return 'PostcodeValidationResult(isValid: $isValid, '
           'errorMessage: $errorMessage, errorCode: $errorCode)';
  }

  @override
  List<Object?> get props => [isValid, errorMessage, errorCode, cleanPostcode, formattedPostcode, province, city, suggestions];
}

/// Transport mode for travel calculations
enum TransportMode {
  driving('driving', 'Auto'),
  walking('walking', 'Lopen'),
  bicycling('bicycling', 'Fiets'),
  transit('transit', 'OV');

  const TransportMode(this.apiValue, this.displayName);
  
  final String apiValue;
  final String displayName;
}

/// Comprehensive travel details between two locations
class TravelDetails extends Equatable {
  final String fromPostcode;
  final String toPostcode;
  final double distanceKm;
  final Duration duration;
  final TransportMode mode;
  final String? routeDescription;
  final List<String>? instructions;
  final double? costEstimate; // For transit mode
  final DateTime calculatedAt;
  final String source; // 'google_maps', 'cache', 'estimate'

  const TravelDetails({
    required this.fromPostcode,
    required this.toPostcode,
    required this.distanceKm,
    required this.duration,
    required this.mode,
    this.routeDescription,
    this.instructions,
    this.costEstimate,
    required this.calculatedAt,
    required this.source,
  });

  factory TravelDetails.fromJson(Map<String, dynamic> json) {
    return TravelDetails(
      fromPostcode: json['fromPostcode'] as String,
      toPostcode: json['toPostcode'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      duration: Duration(seconds: json['durationSeconds'] as int),
      mode: TransportMode.values.firstWhere(
        (m) => m.apiValue == json['mode'], 
        orElse: () => TransportMode.driving,
      ),
      routeDescription: json['routeDescription'] as String?,
      instructions: (json['instructions'] as List<dynamic>?)?.cast<String>(),
      costEstimate: (json['costEstimate'] as num?)?.toDouble(),
      calculatedAt: DateTime.fromMillisecondsSinceEpoch(json['calculatedAt'] as int),
      source: json['source'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromPostcode': fromPostcode,
      'toPostcode': toPostcode,
      'distanceKm': distanceKm,
      'durationSeconds': duration.inSeconds,
      'mode': mode.apiValue,
      'routeDescription': routeDescription,
      'instructions': instructions,
      'costEstimate': costEstimate,
      'calculatedAt': calculatedAt.millisecondsSinceEpoch,
      'source': source,
    };
  }

  /// Check if cached data is still valid (24 hours)
  bool get isCacheValid {
    final now = DateTime.now();
    final hoursDifference = now.difference(calculatedAt).inHours;
    return hoursDifference < 24;
  }

  /// Get formatted duration string in Dutch
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}u ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '${meters}m';
    } else {
      return '${distanceKm.toStringAsFixed(1)}km';
    }
  }

  @override
  String toString() => 'TravelDetails($fromPostcode → $toPostcode: $formattedDistance, $formattedDuration via ${mode.displayName})';

  @override
  List<Object?> get props => [fromPostcode, toPostcode, distanceKm, duration, mode, routeDescription, instructions, costEstimate, calculatedAt, source];
}

/// Location with postcode and additional details
class Location extends Equatable {
  final String postcode;
  final String? name;
  final String? address;
  final double latitude;
  final double longitude;
  final String? city;
  final String? province;
  final String? type; // 'job', 'guard_location', 'company', etc.
  final Map<String, dynamic>? metadata;

  const Location({
    required this.postcode,
    this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    this.city,
    this.province,
    this.type,
    this.metadata,
  });

  factory Location.fromPostcodeCoordinate(
    PostcodeCoordinate coordinate, {
    String? name,
    String? address,
    String? type,
    Map<String, dynamic>? metadata,
  }) {
    return Location(
      postcode: coordinate.postcode,
      name: name,
      address: address,
      latitude: coordinate.latitude,
      longitude: coordinate.longitude,
      city: coordinate.city,
      province: coordinate.province,
      type: type,
      metadata: metadata,
    );
  }

  PostcodeCoordinate get coordinate => PostcodeCoordinate(
    postcode: postcode,
    latitude: latitude,
    longitude: longitude,
    city: city,
    province: province,
  );

  @override
  String toString() => 'Location($postcode: $name, $city)';

  @override
  List<Object?> get props => [postcode, name, address, latitude, longitude, city, province, type, metadata];
}

/// Distance calculation result with multiple transport modes
class DistanceCalculationResult extends Equatable {
  final String fromPostcode;
  final String toPostcode;
  final Map<TransportMode, TravelDetails> travelOptions;
  final DateTime calculatedAt;
  final bool fromCache;

  const DistanceCalculationResult({
    required this.fromPostcode,
    required this.toPostcode,
    required this.travelOptions,
    required this.calculatedAt,
    required this.fromCache,
  });

  /// Get the fastest travel option
  TravelDetails? get fastest {
    if (travelOptions.isEmpty) return null;
    return travelOptions.values.reduce((a, b) => a.duration < b.duration ? a : b);
  }

  /// Get the shortest distance option
  TravelDetails? get shortest {
    if (travelOptions.isEmpty) return null;
    return travelOptions.values.reduce((a, b) => a.distanceKm < b.distanceKm ? a : b);
  }

  /// Get driving option if available
  TravelDetails? get driving => travelOptions[TransportMode.driving];

  /// Get public transport option if available
  TravelDetails? get transit => travelOptions[TransportMode.transit];

  /// Get bicycling option if available
  TravelDetails? get bicycling => travelOptions[TransportMode.bicycling];

  /// Get walking option if available
  TravelDetails? get walking => travelOptions[TransportMode.walking];

  @override
  String toString() => 'DistanceCalculationResult($fromPostcode → $toPostcode: ${travelOptions.length} options)';

  @override
  List<Object?> get props => [fromPostcode, toPostcode, travelOptions, calculatedAt, fromCache];
}

/// Service status for API monitoring
enum ServiceStatus {
  active('Actief'),
  degraded('Beperkt'),
  down('Niet beschikbaar');

  const ServiceStatus(this.displayName);
  final String displayName;
}

/// API service health information
class ServiceHealth extends Equatable {
  final ServiceStatus status;
  final String service;
  final int responseTimeMs;
  final String? errorMessage;
  final DateTime checkedAt;

  const ServiceHealth({
    required this.status,
    required this.service,
    required this.responseTimeMs,
    this.errorMessage,
    required this.checkedAt,
  });

  bool get isHealthy => status == ServiceStatus.active && responseTimeMs < 2000;

  @override
  String toString() => 'ServiceHealth($service: ${status.displayName}, ${responseTimeMs}ms)';

  @override
  List<Object?> get props => [status, service, responseTimeMs, errorMessage, checkedAt];
}

/// Cache statistics for monitoring
class CacheStatistics extends Equatable {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final double hitRatio;
  final int totalRequests;
  final int cacheHits;
  final DateTime lastCleanup;

  const CacheStatistics({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.hitRatio,
    required this.totalRequests,
    required this.cacheHits,
    required this.lastCleanup,
  });

  int get cacheMisses => totalRequests - cacheHits;

  @override
  String toString() => 'CacheStatistics($totalEntries entries, ${hitRatio.toStringAsFixed(1)}% hit ratio)';

  @override
  List<Object?> get props => [totalEntries, validEntries, expiredEntries, hitRatio, totalRequests, cacheHits, lastCleanup];
}

/// Custom exceptions for postcode operations
class PostcodeException implements Exception {
  final String message;
  final String? code;
  final String? postcode;

  const PostcodeException(this.message, [this.code, this.postcode]);

  @override
  String toString() => 'PostcodeException: $message${postcode != null ? ' (postcode: $postcode)' : ''}';
}

class DistanceCalculationException implements Exception {
  final String message;
  final String? fromPostcode;
  final String? toPostcode;
  final String? cause;

  const DistanceCalculationException(this.message, [this.fromPostcode, this.toPostcode, this.cause]);

  @override
  String toString() => 'DistanceCalculationException: $message${fromPostcode != null && toPostcode != null ? ' ($fromPostcode → $toPostcode)' : ''}';
}

class ApiException implements Exception {
  final String message;
  final String service;
  final int? statusCode;
  final String? apiResponse;

  const ApiException(this.message, this.service, [this.statusCode, this.apiResponse]);

  @override
  String toString() => 'ApiException [$service]: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Dutch provinces for postcode mapping
enum DutchProvince {
  noordHolland('Noord-Holland'),
  zuidHolland('Zuid-Holland'),
  utrecht('Utrecht'),
  noordBrabant('Noord-Brabant'),
  limburg('Limburg'),
  gelderland('Gelderland'),
  overijssel('Overijssel'),
  friesland('Friesland'),
  groningen('Groningen'),
  drenthe('Drenthe'),
  flevoland('Flevoland'),
  zeeland('Zeeland');

  const DutchProvince(this.displayName);
  final String displayName;

  /// Get province for postcode number
  static DutchProvince? fromPostcodeNumber(int postcodeNumber) {
    if (postcodeNumber >= 1000 && postcodeNumber <= 1299) return noordHolland;
    if (postcodeNumber >= 1300 && postcodeNumber <= 1380) return flevoland;
    if (postcodeNumber >= 1400 && postcodeNumber <= 1499) return zuidHolland;
    if (postcodeNumber >= 1500 && postcodeNumber <= 1999) return noordHolland;
    if (postcodeNumber >= 2000 && postcodeNumber <= 2999) return zuidHolland;
    if (postcodeNumber >= 3000 && postcodeNumber <= 3999) return zuidHolland;
    if (postcodeNumber >= 4000 && postcodeNumber <= 4999) return zuidHolland;
    if (postcodeNumber >= 5000 && postcodeNumber <= 5999) return noordBrabant;
    if (postcodeNumber >= 6000 && postcodeNumber <= 6999) return limburg;
    if (postcodeNumber >= 7000 && postcodeNumber <= 7999) return overijssel;
    if (postcodeNumber >= 8000 && postcodeNumber <= 8999) return drenthe;
    if (postcodeNumber >= 9000 && postcodeNumber <= 9299) return groningen;
    if (postcodeNumber >= 9300 && postcodeNumber <= 9999) return friesland;
    return null;
  }
}