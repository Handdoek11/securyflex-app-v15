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