import 'package:equatable/equatable.dart';
import 'certificate_models.dart';

/// Job Requirements Models
/// 
/// Models for job certificate requirements, matching criteria, and
/// qualification specifications for the Dutch security marketplace.

/// Job Certificate Requirement Priority
enum RequirementPriority {
  mandatory('mandatory', 'Verplicht', 100),
  preferred('preferred', 'Gewenst', 75),
  advantageous('advantageous', 'Voordelig', 50),
  optional('optional', 'Optioneel', 25);

  const RequirementPriority(this.code, this.dutchName, this.weight);

  final String code;
  final String dutchName;
  final int weight; // Weight in matching algorithm

  static RequirementPriority fromCode(String code) {
    return RequirementPriority.values.firstWhere(
      (priority) => priority.code == code,
      orElse: () => RequirementPriority.optional,
    );
  }
}

/// Job Certificate Requirement
class JobCertificateRequirement extends Equatable {
  final String certificateId; // Reference to DutchSecurityCertificate
  final RequirementPriority priority;
  final String? description; // Dutch explanation of why this certificate is needed
  final bool acceptEquivalents; // Accept equivalent certificates
  final bool acceptHigherLevels; // Accept higher level certificates
  final int? minExperienceMonths; // Minimum months of experience with this certificate
  final DateTime? requiredBy; // When certificate must be obtained by
  final Map<String, dynamic> metadata;

  const JobCertificateRequirement({
    required this.certificateId,
    this.priority = RequirementPriority.optional,
    this.description,
    this.acceptEquivalents = true,
    this.acceptHigherLevels = true,
    this.minExperienceMonths,
    this.requiredBy,
    this.metadata = const {},
  });

  /// Get human-readable requirement description in Dutch
  String getRequirementDescription(DutchSecurityCertificate certificate) {
    final buffer = StringBuffer();
    
    buffer.write(certificate.name);
    
    if (priority == RequirementPriority.mandatory) {
      buffer.write(' (verplicht)');
    } else {
      buffer.write(' (${priority.dutchName.toLowerCase()})');
    }
    
    if (minExperienceMonths != null && minExperienceMonths! > 0) {
      final years = minExperienceMonths! ~/ 12;
      final months = minExperienceMonths! % 12;
      
      buffer.write(' - minimaal ');
      if (years > 0) {
        buffer.write('$years jaar');
        if (months > 0) buffer.write(' en $months maanden');
      } else {
        buffer.write('$months maanden');
      }
      buffer.write(' ervaring');
    }
    
    if (description != null) {
      buffer.write(' - $description');
    }
    
    return buffer.toString();
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'certificateId': certificateId,
      'priority': priority.code,
      'description': description,
      'acceptEquivalents': acceptEquivalents,
      'acceptHigherLevels': acceptHigherLevels,
      'minExperienceMonths': minExperienceMonths,
      'requiredBy': requiredBy?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory JobCertificateRequirement.fromJson(Map<String, dynamic> json) {
    return JobCertificateRequirement(
      certificateId: json['certificateId'],
      priority: RequirementPriority.fromCode(json['priority'] ?? 'optional'),
      description: json['description'],
      acceptEquivalents: json['acceptEquivalents'] ?? true,
      acceptHigherLevels: json['acceptHigherLevels'] ?? true,
      minExperienceMonths: json['minExperienceMonths'],
      requiredBy: json['requiredBy'] != null 
          ? DateTime.parse(json['requiredBy']) 
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
    certificateId, priority, description, acceptEquivalents,
    acceptHigherLevels, minExperienceMonths, requiredBy, metadata,
  ];
}

/// Job Security Level - determines required certificate combinations
enum JobSecurityLevel {
  basic('basic', 'Basis', 'Eenvoudige beveiligingstaken'),
  standard('standard', 'Standaard', 'Reguliere beveiligingsopdrachten'), 
  enhanced('enhanced', 'Verhoogd', 'Complexere beveiligingssituaties'),
  high('high', 'Hoog', 'Risicovolle beveiligingsopdrachten'),
  critical('critical', 'Kritiek', 'Hoogwaardige beveiligingsopdrachten');

  const JobSecurityLevel(this.code, this.dutchName, this.description);

  final String code;
  final String dutchName;
  final String description;

  /// Get minimum required certificates for this security level
  List<String> getMinimumRequiredCertificates() {
    switch (this) {
      case JobSecurityLevel.basic:
        return ['wpbr_a'];
      case JobSecurityLevel.standard:
        return ['wpbr_a'];
      case JobSecurityLevel.enhanced:
        return ['wpbr_a', 'bhv'];
      case JobSecurityLevel.high:
        return ['wpbr_b', 'bhv', 'vca_basic'];
      case JobSecurityLevel.critical:
        return ['wpbr_b', 'persoonbeveiliging', 'bhv', 'ehbo'];
    }
  }

  static JobSecurityLevel fromCode(String code) {
    return JobSecurityLevel.values.firstWhere(
      (level) => level.code == code,
      orElse: () => JobSecurityLevel.standard,
    );
  }
}

/// Job Environment Type - affects required certificates
enum JobEnvironmentType {
  office('office', 'Kantoor', ['wpbr_a']),
  retail('retail', 'Winkel', ['wpbr_a']),
  construction('construction', 'Bouwplaats', ['wpbr_a', 'vca_basic']),
  industrial('industrial', 'Industrieel', ['wpbr_a', 'vca_basic', 'bhv']),
  event('event', 'Evenement', ['wpbr_a', 'bhv', 'ehbo']),
  hospital('hospital', 'Ziekenhuis', ['wpbr_a', 'bhv']),
  airport('airport', 'Luchthaven', ['wpbr_b']),
  government('government', 'Overheid', ['wpbr_b']),
  transport('transport', 'Transport', ['wpbr_a', 'rijbewijs_b']),
  residential('residential', 'Woonwijk', ['wpbr_a']),
  nightlife('nightlife', 'Uitgaansleven', ['wpbr_a', 'bhv']);

  const JobEnvironmentType(this.code, this.dutchName, this.suggestedCertificates);

  final String code;
  final String dutchName;
  final List<String> suggestedCertificates;

  static JobEnvironmentType fromCode(String code) {
    return JobEnvironmentType.values.firstWhere(
      (env) => env.code == code,
      orElse: () => JobEnvironmentType.office,
    );
  }
}

/// Complete Job Certificate Requirements
class JobCertificateRequirements extends Equatable {
  final String jobId;
  final JobSecurityLevel securityLevel;
  final JobEnvironmentType environmentType;
  final List<JobCertificateRequirement> requirements;
  final bool allowPartialMatch; // Accept candidates with some missing certificates
  final int minimumMatchScore; // Minimum score (0-100) to be considered
  final List<String> disqualifyingFactors; // Automatic disqualifiers
  final String? specialInstructions; // Additional Dutch instructions
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const JobCertificateRequirements({
    required this.jobId,
    this.securityLevel = JobSecurityLevel.standard,
    this.environmentType = JobEnvironmentType.office,
    this.requirements = const [],
    this.allowPartialMatch = true,
    this.minimumMatchScore = 70,
    this.disqualifyingFactors = const [],
    this.specialInstructions,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Get all certificate IDs from requirements
  List<String> get requiredCertificateIds => 
      requirements.map((req) => req.certificateId).toList();

  /// Get mandatory certificate requirements only
  List<JobCertificateRequirement> get mandatoryRequirements =>
      requirements.where((req) => req.priority == RequirementPriority.mandatory).toList();

  /// Get preferred certificate requirements
  List<JobCertificateRequirement> get preferredRequirements =>
      requirements.where((req) => req.priority == RequirementPriority.preferred).toList();

  /// Check if job has any mandatory requirements
  bool get hasMandatoryRequirements => mandatoryRequirements.isNotEmpty;

  /// Get weighted total of all requirements (for scoring)
  int get totalRequirementWeight =>
      requirements.fold(0, (accumulator, req) => accumulator + req.priority.weight);

  /// Get Dutch summary of requirements
  String getDutchRequirementsSummary() {
    if (requirements.isEmpty) {
      return 'Geen specifieke certificaatvereisten';
    }

    final mandatory = mandatoryRequirements.length;
    final preferred = preferredRequirements.length;
    final other = requirements.length - mandatory - preferred;

    final parts = <String>[];
    
    if (mandatory > 0) {
      parts.add('$mandatory verplichte certificaten');
    }
    
    if (preferred > 0) {
      parts.add('$preferred gewenste certificaten');
    }
    
    if (other > 0) {
      parts.add('$other optionele certificaten');
    }

    return parts.join(', ');
  }

  /// Generate automatic requirements based on security level and environment
  static JobCertificateRequirements generateFromJobContext({
    required String jobId,
    required JobSecurityLevel securityLevel,
    required JobEnvironmentType environmentType,
    List<JobCertificateRequirement> additionalRequirements = const [],
  }) {
    final requirements = <JobCertificateRequirement>[];

    // Add minimum requirements for security level
    final minRequired = securityLevel.getMinimumRequiredCertificates();
    for (final certId in minRequired) {
      requirements.add(JobCertificateRequirement(
        certificateId: certId,
        priority: RequirementPriority.mandatory,
        description: 'Vereist voor ${securityLevel.dutchName} beveiligingsniveau',
      ));
    }

    // Add environment-specific suggested certificates
    for (final certId in environmentType.suggestedCertificates) {
      // Don't duplicate mandatory requirements
      if (!minRequired.contains(certId)) {
        requirements.add(JobCertificateRequirement(
          certificateId: certId,
          priority: RequirementPriority.preferred,
          description: 'Gewenst voor werkzaamheden in ${environmentType.dutchName.toLowerCase()}',
        ));
      }
    }

    // Add any additional requirements
    requirements.addAll(additionalRequirements);

    return JobCertificateRequirements(
      jobId: jobId,
      securityLevel: securityLevel,
      environmentType: environmentType,
      requirements: requirements,
      allowPartialMatch: securityLevel != JobSecurityLevel.critical,
      minimumMatchScore: _getMinScoreForLevel(securityLevel),
      updatedAt: DateTime.now(),
    );
  }

  /// Get minimum score based on security level
  static int _getMinScoreForLevel(JobSecurityLevel level) {
    switch (level) {
      case JobSecurityLevel.basic:
        return 60;
      case JobSecurityLevel.standard:
        return 70;
      case JobSecurityLevel.enhanced:
        return 80;
      case JobSecurityLevel.high:
        return 85;
      case JobSecurityLevel.critical:
        return 95;
    }
  }

  /// Copy with updated properties
  JobCertificateRequirements copyWith({
    String? jobId,
    JobSecurityLevel? securityLevel,
    JobEnvironmentType? environmentType,
    List<JobCertificateRequirement>? requirements,
    bool? allowPartialMatch,
    int? minimumMatchScore,
    List<String>? disqualifyingFactors,
    String? specialInstructions,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return JobCertificateRequirements(
      jobId: jobId ?? this.jobId,
      securityLevel: securityLevel ?? this.securityLevel,
      environmentType: environmentType ?? this.environmentType,
      requirements: requirements ?? this.requirements,
      allowPartialMatch: allowPartialMatch ?? this.allowPartialMatch,
      minimumMatchScore: minimumMatchScore ?? this.minimumMatchScore,
      disqualifyingFactors: disqualifyingFactors ?? this.disqualifyingFactors,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'securityLevel': securityLevel.code,
      'environmentType': environmentType.code,
      'requirements': requirements.map((req) => req.toJson()).toList(),
      'allowPartialMatch': allowPartialMatch,
      'minimumMatchScore': minimumMatchScore,
      'disqualifyingFactors': disqualifyingFactors,
      'specialInstructions': specialInstructions,
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory JobCertificateRequirements.fromJson(Map<String, dynamic> json) {
    return JobCertificateRequirements(
      jobId: json['jobId'],
      securityLevel: JobSecurityLevel.fromCode(json['securityLevel'] ?? 'standard'),
      environmentType: JobEnvironmentType.fromCode(json['environmentType'] ?? 'office'),
      requirements: (json['requirements'] as List<dynamic>?)
          ?.map((req) => JobCertificateRequirement.fromJson(req))
          .toList() ?? [],
      allowPartialMatch: json['allowPartialMatch'] ?? true,
      minimumMatchScore: json['minimumMatchScore'] ?? 70,
      disqualifyingFactors: List<String>.from(json['disqualifyingFactors'] ?? []),
      specialInstructions: json['specialInstructions'],
      updatedAt: DateTime.parse(json['updatedAt']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
    jobId, securityLevel, environmentType, requirements, allowPartialMatch,
    minimumMatchScore, disqualifyingFactors, specialInstructions, updatedAt, metadata,
  ];
}

/// Certificate Gap Analysis - identifies missing certificates
class CertificateGap extends Equatable {
  final String certificateId;
  final RequirementPriority priority;
  final String reason; // Dutch explanation why this certificate is missing
  final int impactScore; // Impact on overall match score (0-100)
  final String? recommendation; // Dutch recommendation for obtaining certificate
  final Duration? timeToObtain; // Estimated time to obtain certificate
  final double? estimatedCost; // Estimated cost in euros
  final List<String> trainingProviders; // Suggested training providers

  const CertificateGap({
    required this.certificateId,
    required this.priority,
    required this.reason,
    required this.impactScore,
    this.recommendation,
    this.timeToObtain,
    this.estimatedCost,
    this.trainingProviders = const [],
  });

  /// Get urgency level based on priority and impact
  String get urgencyLevel {
    if (priority == RequirementPriority.mandatory) return 'Kritiek';
    if (impactScore >= 75) return 'Hoog';
    if (impactScore >= 50) return 'Gemiddeld';
    return 'Laag';
  }

  /// Get Dutch urgency description
  String get urgencyDescription {
    switch (urgencyLevel) {
      case 'Kritiek':
        return 'Verplicht voor deze functie - onmiddellijk nodig';
      case 'Hoog':
        return 'Sterk aanbevolen voor betere kansen';
      case 'Gemiddeld':
        return 'Voordelig voor carrièreontwikkeling';
      case 'Laag':
        return 'Optionele toevoeging aan profiel';
      default:
        return 'Onbekende urgentie';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'certificateId': certificateId,
      'priority': priority.code,
      'reason': reason,
      'impactScore': impactScore,
      'recommendation': recommendation,
      'timeToObtain': timeToObtain?.inDays,
      'estimatedCost': estimatedCost,
      'trainingProviders': trainingProviders,
    };
  }

  /// Create from JSON
  factory CertificateGap.fromJson(Map<String, dynamic> json) {
    return CertificateGap(
      certificateId: json['certificateId'],
      priority: RequirementPriority.fromCode(json['priority']),
      reason: json['reason'],
      impactScore: json['impactScore'],
      recommendation: json['recommendation'],
      timeToObtain: json['timeToObtain'] != null 
          ? Duration(days: json['timeToObtain']) 
          : null,
      estimatedCost: json['estimatedCost']?.toDouble(),
      trainingProviders: List<String>.from(json['trainingProviders'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
    certificateId, priority, reason, impactScore, recommendation,
    timeToObtain, estimatedCost, trainingProviders,
  ];
}