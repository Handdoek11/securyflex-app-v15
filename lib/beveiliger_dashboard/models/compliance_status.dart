import 'package:equatable/equatable.dart';

/// Compliance status for Nederlandse Arbeidsrecht (Dutch Labor Law)
class ComplianceStatus extends Equatable {
  final bool hasViolations;
  final List<ComplianceViolation> violations;
  final double weeklyHours;
  final double maxWeeklyHours;
  final Duration restPeriod;
  final Duration minRestPeriod;
  final bool wpbrValid;
  final DateTime? wpbrExpiryDate;
  final bool healthCertificateValid;
  final DateTime lastUpdated;

  const ComplianceStatus({
    required this.hasViolations,
    required this.violations,
    required this.weeklyHours,
    required this.maxWeeklyHours,
    required this.restPeriod,
    required this.minRestPeriod,
    required this.wpbrValid,
    this.wpbrExpiryDate,
    required this.healthCertificateValid,
    required this.lastUpdated,
  });

  /// Check if within CAO arbeidsrecht limits
  bool get isCAOCompliant {
    return weeklyHours <= maxWeeklyHours && 
           restPeriod >= minRestPeriod &&
           wpbrValid &&
           healthCertificateValid;
  }

  /// Get Dutch compliance summary
  String get dutchComplianceSummary {
    if (isCAOCompliant && !hasViolations) {
      return 'Volledig conform CAO arbeidsrecht';
    } else if (hasViolations) {
      return '${violations.length} overtredingen gevonden';
    } else {
      return 'Gedeeltelijk conform - controleer details';
    }
  }

  ComplianceStatus copyWith({
    bool? hasViolations,
    List<ComplianceViolation>? violations,
    double? weeklyHours,
    double? maxWeeklyHours,
    Duration? restPeriod,
    Duration? minRestPeriod,
    bool? wpbrValid,
    DateTime? wpbrExpiryDate,
    bool? healthCertificateValid,
    DateTime? lastUpdated,
  }) {
    return ComplianceStatus(
      hasViolations: hasViolations ?? this.hasViolations,
      violations: violations ?? this.violations,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      maxWeeklyHours: maxWeeklyHours ?? this.maxWeeklyHours,
      restPeriod: restPeriod ?? this.restPeriod,
      minRestPeriod: minRestPeriod ?? this.minRestPeriod,
      wpbrValid: wpbrValid ?? this.wpbrValid,
      wpbrExpiryDate: wpbrExpiryDate ?? this.wpbrExpiryDate,
      healthCertificateValid: healthCertificateValid ?? this.healthCertificateValid,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// JSON serialization
  factory ComplianceStatus.fromJson(Map<String, dynamic> json) {
    return ComplianceStatus(
      hasViolations: json['hasViolations'] as bool,
      violations: (json['violations'] as List<dynamic>)
          .map((violationJson) => ComplianceViolation.fromJson(violationJson as Map<String, dynamic>))
          .toList(),
      weeklyHours: (json['weeklyHours'] as num).toDouble(),
      maxWeeklyHours: (json['maxWeeklyHours'] as num).toDouble(),
      restPeriod: Duration(microseconds: json['restPeriod'] as int),
      minRestPeriod: Duration(microseconds: json['minRestPeriod'] as int),
      wpbrValid: json['wpbrValid'] as bool,
      wpbrExpiryDate: json['wpbrExpiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['wpbrExpiryDate'] as int)
          : null,
      healthCertificateValid: json['healthCertificateValid'] as bool,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasViolations': hasViolations,
      'violations': violations.map((violation) => violation.toJson()).toList(),
      'weeklyHours': weeklyHours,
      'maxWeeklyHours': maxWeeklyHours,
      'restPeriod': restPeriod.inMicroseconds,
      'minRestPeriod': minRestPeriod.inMicroseconds,
      'wpbrValid': wpbrValid,
      'wpbrExpiryDate': wpbrExpiryDate?.millisecondsSinceEpoch,
      'healthCertificateValid': healthCertificateValid,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [
    hasViolations,
    violations,
    weeklyHours,
    maxWeeklyHours,
    restPeriod,
    minRestPeriod,
    wpbrValid,
    wpbrExpiryDate,
    healthCertificateValid,
    lastUpdated,
  ];
}

/// Compliance violation details
class ComplianceViolation extends Equatable {
  final String id;
  final ComplianceViolationType type;
  final String dutchDescription;
  final String dutchRecommendation;
  final ComplianceSeverity severity;
  final DateTime detectedAt;
  final Map<String, dynamic>? additionalData;

  const ComplianceViolation({
    required this.id,
    required this.type,
    required this.dutchDescription,
    required this.dutchRecommendation,
    required this.severity,
    required this.detectedAt,
    this.additionalData,
  });

  /// JSON serialization
  factory ComplianceViolation.fromJson(Map<String, dynamic> json) {
    return ComplianceViolation(
      id: json['id'] as String,
      type: ComplianceViolationType.values.firstWhere((e) => e.name == json['type']),
      dutchDescription: json['dutchDescription'] as String,
      dutchRecommendation: json['dutchRecommendation'] as String,
      severity: ComplianceSeverity.values.firstWhere((e) => e.name == json['severity']),
      detectedAt: DateTime.fromMillisecondsSinceEpoch(json['detectedAt'] as int),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'dutchDescription': dutchDescription,
      'dutchRecommendation': dutchRecommendation,
      'severity': severity.name,
      'detectedAt': detectedAt.millisecondsSinceEpoch,
      'additionalData': additionalData,
    };
  }

  @override
  List<Object?> get props => [
    id,
    type,
    dutchDescription,
    dutchRecommendation,
    severity,
    detectedAt,
    additionalData,
  ];
}

/// Types of compliance violations
enum ComplianceViolationType {
  excessiveHours,        // Te veel werkuren
  insufficientRest,      // Onvoldoende rusttijd
  expiredWPBR,          // Verlopen WPBR
  expiredHealthCert,     // Verlopen gezondheidsverklaring
  unauthorizedOvertime,  // Ongeautoriseerde overuren
  missingBreaks,        // Ontbrekende pauzes
}

/// Severity levels for compliance violations
enum ComplianceSeverity {
  low,      // Laag - waarschuwing
  medium,   // Gemiddeld - actie vereist
  high,     // Hoog - onmiddellijke actie
  critical, // Kritiek - werk moet stoppen
}