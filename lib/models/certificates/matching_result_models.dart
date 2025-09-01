import 'package:equatable/equatable.dart';
import 'job_requirements_models.dart';

/// Certificate Matching Result Models
/// 
/// Comprehensive models for certificate matching results, scoring,
/// recommendations, and compatibility analysis for the Dutch security marketplace.

/// Match Type Classification
enum MatchType {
  perfect('perfect', 'Perfecte Match', 'Alle vereisten volledig vervuld'),
  excellent('excellent', 'Uitstekende Match', 'Bijna alle vereisten vervuld'),
  good('good', 'Goede Match', 'Meeste vereisten vervuld'),
  partial('partial', 'Gedeeltelijke Match', 'Enkele vereisten vervuld'),
  insufficient('insufficient', 'Onvoldoende Match', 'Te weinig vereisten vervuld'),
  unqualified('unqualified', 'Niet Gekwalificeerd', 'Geen basisvereisten vervuld');

  const MatchType(this.code, this.dutchName, this.description);

  final String code;
  final String dutchName;
  final String description;

  /// Get match type based on score
  static MatchType fromScore(int score) {
    if (score >= 95) return MatchType.perfect;
    if (score >= 85) return MatchType.excellent;
    if (score >= 70) return MatchType.good;
    if (score >= 50) return MatchType.partial;
    if (score >= 25) return MatchType.insufficient;
    return MatchType.unqualified;
  }

  /// Get color for UI representation
  String get colorCode {
    switch (this) {
      case MatchType.perfect:
        return '#10B981'; // Success green
      case MatchType.excellent:
        return '#34D399'; // Light success green
      case MatchType.good:
        return '#3B82F6'; // Info blue
      case MatchType.partial:
        return '#F59E0B'; // Warning orange
      case MatchType.insufficient:
        return '#EF4444'; // Error red
      case MatchType.unqualified:
        return '#6B7280'; // Gray
    }
  }
}

/// Certificate Match Status for individual certificates
enum CertificateMatchStatus {
  exactMatch('exact_match', 'Exacte Match'),
  equivalentMatch('equivalent_match', 'Equivalente Match'),
  higherLevelMatch('higher_level_match', 'Hoger Niveau Match'),
  partialMatch('partial_match', 'Gedeeltelijke Match'),
  expired('expired', 'Verlopen'),
  missing('missing', 'Ontbrekend');

  const CertificateMatchStatus(this.code, this.dutchName);

  final String code;
  final String dutchName;

  /// Check if match status is acceptable for job eligibility
  bool get isAcceptable => this != missing && this != expired;

  /// Get match weight for scoring (0-100)
  int get matchWeight {
    switch (this) {
      case CertificateMatchStatus.exactMatch:
        return 100;
      case CertificateMatchStatus.equivalentMatch:
        return 95;
      case CertificateMatchStatus.higherLevelMatch:
        return 90;
      case CertificateMatchStatus.partialMatch:
        return 70;
      case CertificateMatchStatus.expired:
        return 30;
      case CertificateMatchStatus.missing:
        return 0;
    }
  }

  static CertificateMatchStatus fromCode(String code) {
    return CertificateMatchStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => CertificateMatchStatus.missing,
    );
  }
}

/// Individual Certificate Match Detail
class CertificateMatchDetail extends Equatable {
  final String requirementId; // Reference to JobCertificateRequirement
  final String certificateId; // Reference to DutchSecurityCertificate
  final String? userCertificateId; // Reference to UserCertificate if matched
  final CertificateMatchStatus status;
  final RequirementPriority priority;
  final int scoreContribution; // Points contributed to total score
  final String reason; // Dutch explanation of match/mismatch
  final DateTime? expiryDate; // For expiry warnings
  final List<String> alternatives; // Alternative certificate IDs that would match
  final Map<String, dynamic> metadata;

  const CertificateMatchDetail({
    required this.requirementId,
    required this.certificateId,
    this.userCertificateId,
    required this.status,
    required this.priority,
    required this.scoreContribution,
    required this.reason,
    this.expiryDate,
    this.alternatives = const [],
    this.metadata = const {},
  });

  /// Check if certificate needs attention (expired/expiring)
  bool get needsAttention {
    if (status == CertificateMatchStatus.expired) return true;
    if (expiryDate != null) {
      final now = DateTime.now();
      final sixMonthsFromNow = now.add(const Duration(days: 180));
      return expiryDate!.isBefore(sixMonthsFromNow);
    }
    return false;
  }

  /// Get days until expiry (if applicable)
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  /// Get urgency level for this match detail
  String get urgencyLevel {
    if (status == CertificateMatchStatus.missing && priority == RequirementPriority.mandatory) {
      return 'Kritiek';
    }
    if (status == CertificateMatchStatus.expired) return 'Urgent';
    if (needsAttention) return 'Aandacht';
    return 'Normaal';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'requirementId': requirementId,
      'certificateId': certificateId,
      'userCertificateId': userCertificateId,
      'status': status.code,
      'priority': priority.code,
      'scoreContribution': scoreContribution,
      'reason': reason,
      'expiryDate': expiryDate?.toIso8601String(),
      'alternatives': alternatives,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory CertificateMatchDetail.fromJson(Map<String, dynamic> json) {
    return CertificateMatchDetail(
      requirementId: json['requirementId'],
      certificateId: json['certificateId'],
      userCertificateId: json['userCertificateId'],
      status: CertificateMatchStatus.fromCode(json['status']),
      priority: RequirementPriority.fromCode(json['priority']),
      scoreContribution: json['scoreContribution'],
      reason: json['reason'],
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate']) 
          : null,
      alternatives: List<String>.from(json['alternatives'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
    requirementId, certificateId, userCertificateId, status, priority,
    scoreContribution, reason, expiryDate, alternatives, metadata,
  ];
}

/// Certificate Recommendation for improving match score
class CertificateRecommendation extends Equatable {
  final String certificateId;
  final RequirementPriority priority;
  final int potentialScoreImprovement; // Points this would add to score
  final String reason; // Dutch explanation why this is recommended
  final Duration? estimatedTimeToObtain;
  final double? estimatedCost;
  final List<String> trainingProviders;
  final List<String> prerequisites; // Other certificates needed first
  final String? nextAvailableCourse; // Next available training date
  final int urgencyScore; // 0-100, how urgent this recommendation is
  final Map<String, dynamic> metadata;

  const CertificateRecommendation({
    required this.certificateId,
    required this.priority,
    required this.potentialScoreImprovement,
    required this.reason,
    this.estimatedTimeToObtain,
    this.estimatedCost,
    this.trainingProviders = const [],
    this.prerequisites = const [],
    this.nextAvailableCourse,
    required this.urgencyScore,
    this.metadata = const {},
  });

  /// Get recommendation category in Dutch
  String get categoryDutch {
    if (priority == RequirementPriority.mandatory) return 'Verplicht';
    if (potentialScoreImprovement >= 20) return 'Sterk Aanbevolen';
    if (potentialScoreImprovement >= 10) return 'Aanbevolen';
    return 'Optioneel';
  }

  /// Get urgency description in Dutch
  String get urgencyDescription {
    if (urgencyScore >= 90) return 'Onmiddellijk nodig';
    if (urgencyScore >= 70) return 'Binnen 3 maanden';
    if (urgencyScore >= 50) return 'Binnen 6 maanden';
    if (urgencyScore >= 30) return 'Binnen 1 jaar';
    return 'Lange termijn planning';
  }

  /// Get ROI description (Return on Investment)
  String get roiDescription {
    if (estimatedCost == null || estimatedCost == 0) return 'Geen kosten bekend';
    
    final scorePerEuro = potentialScoreImprovement / estimatedCost!;
    
    if (scorePerEuro >= 1.0) return 'Zeer goede investering';
    if (scorePerEuro >= 0.5) return 'Goede investering';
    if (scorePerEuro >= 0.2) return 'Redelijke investering';
    return 'Dure investering';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'certificateId': certificateId,
      'priority': priority.code,
      'potentialScoreImprovement': potentialScoreImprovement,
      'reason': reason,
      'estimatedTimeToObtain': estimatedTimeToObtain?.inDays,
      'estimatedCost': estimatedCost,
      'trainingProviders': trainingProviders,
      'prerequisites': prerequisites,
      'nextAvailableCourse': nextAvailableCourse,
      'urgencyScore': urgencyScore,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory CertificateRecommendation.fromJson(Map<String, dynamic> json) {
    return CertificateRecommendation(
      certificateId: json['certificateId'],
      priority: RequirementPriority.fromCode(json['priority']),
      potentialScoreImprovement: json['potentialScoreImprovement'],
      reason: json['reason'],
      estimatedTimeToObtain: json['estimatedTimeToObtain'] != null
          ? Duration(days: json['estimatedTimeToObtain'])
          : null,
      estimatedCost: json['estimatedCost']?.toDouble(),
      trainingProviders: List<String>.from(json['trainingProviders'] ?? []),
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      nextAvailableCourse: json['nextAvailableCourse'],
      urgencyScore: json['urgencyScore'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
    certificateId, priority, potentialScoreImprovement, reason, estimatedTimeToObtain,
    estimatedCost, trainingProviders, prerequisites, nextAvailableCourse,
    urgencyScore, metadata,
  ];
}

/// Comprehensive Certificate Match Result
class CertificateMatchResult extends Equatable {
  final String jobId;
  final String userId;
  final int overallScore; // 0-100 overall match score
  final MatchType matchType;
  final bool isEligible; // Whether candidate can apply for job
  final List<CertificateMatchDetail> matchDetails;
  final List<CertificateGap> certificateGaps;
  final List<CertificateRecommendation> recommendations;
  final int mandatoryMet; // Number of mandatory requirements met
  final int mandatoryTotal; // Total mandatory requirements
  final int preferredMet; // Number of preferred requirements met
  final int preferredTotal; // Total preferred requirements
  final DateTime calculatedAt;
  final Duration? validityPeriod; // How long this result is valid
  final Map<String, dynamic> metadata;

  const CertificateMatchResult({
    required this.jobId,
    required this.userId,
    required this.overallScore,
    required this.matchType,
    required this.isEligible,
    this.matchDetails = const [],
    this.certificateGaps = const [],
    this.recommendations = const [],
    required this.mandatoryMet,
    required this.mandatoryTotal,
    required this.preferredMet,
    required this.preferredTotal,
    required this.calculatedAt,
    this.validityPeriod,
    this.metadata = const {},
  });

  /// Get match percentage as string
  String get matchPercentage => '$overallScore%';

  /// Get eligibility status in Dutch
  String get eligibilityStatusDutch {
    if (isEligible) {
      if (overallScore >= 95) return 'Volledig gekwalificeerd';
      if (overallScore >= 80) return 'Goed gekwalificeerd';
      return 'Basis gekwalificeerd';
    }
    return 'Niet gekwalificeerd';
  }

  /// Get summary description in Dutch
  String get summaryDutch {
    final buffer = StringBuffer();
    
    buffer.write('${matchType.dutchName} ($matchPercentage)');
    
    if (mandatoryTotal > 0) {
      buffer.write(' - $mandatoryMet/$mandatoryTotal verplichte vereisten');
    }
    
    if (preferredTotal > 0) {
      buffer.write(', $preferredMet/$preferredTotal gewenste vereisten');
    }
    
    return buffer.toString();
  }

  /// Get areas needing attention
  List<CertificateMatchDetail> get needsAttention =>
      matchDetails.where((detail) => detail.needsAttention).toList();

  /// Get high priority recommendations
  List<CertificateRecommendation> get highPriorityRecommendations =>
      recommendations.where((rec) => rec.urgencyScore >= 70).toList();

  /// Get critical gaps (mandatory missing certificates)
  List<CertificateGap> get criticalGaps =>
      certificateGaps.where((gap) => gap.priority == RequirementPriority.mandatory).toList();

  /// Check if result is still valid
  bool get isValid {
    if (validityPeriod == null) return true;
    final expiresAt = calculatedAt.add(validityPeriod!);
    return DateTime.now().isBefore(expiresAt);
  }

  /// Get detailed feedback in Dutch
  Map<String, String> get detailedFeedbackDutch {
    final feedback = <String, String>{};
    
    // Overall assessment
    feedback['overall'] = '${matchType.description} met een score van $matchPercentage.';
    
    // Mandatory requirements
    if (mandatoryTotal > 0) {
      if (mandatoryMet == mandatoryTotal) {
        feedback['mandatory'] = 'Alle verplichte certificaten zijn aanwezig.';
      } else {
        final missing = mandatoryTotal - mandatoryMet;
        feedback['mandatory'] = '$missing van de $mandatoryTotal verplichte certificaten ontbreken.';
      }
    }
    
    // Preferred requirements
    if (preferredTotal > 0) {
      final percentage = ((preferredMet / preferredTotal) * 100).round();
      feedback['preferred'] = '$percentage% van de gewenste certificaten zijn aanwezig.';
    }
    
    // Recommendations
    if (recommendations.isNotEmpty) {
      final highPriority = highPriorityRecommendations.length;
      if (highPriority > 0) {
        feedback['recommendations'] = '$highPriority belangrijke aanbevelingen voor verbetering.';
      } else {
        feedback['recommendations'] = '${recommendations.length} aanbevelingen voor verdere ontwikkeling.';
      }
    }
    
    return feedback;
  }

  /// Copy with updated properties
  CertificateMatchResult copyWith({
    String? jobId,
    String? userId,
    int? overallScore,
    MatchType? matchType,
    bool? isEligible,
    List<CertificateMatchDetail>? matchDetails,
    List<CertificateGap>? certificateGaps,
    List<CertificateRecommendation>? recommendations,
    int? mandatoryMet,
    int? mandatoryTotal,
    int? preferredMet,
    int? preferredTotal,
    DateTime? calculatedAt,
    Duration? validityPeriod,
    Map<String, dynamic>? metadata,
  }) {
    return CertificateMatchResult(
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      overallScore: overallScore ?? this.overallScore,
      matchType: matchType ?? this.matchType,
      isEligible: isEligible ?? this.isEligible,
      matchDetails: matchDetails ?? this.matchDetails,
      certificateGaps: certificateGaps ?? this.certificateGaps,
      recommendations: recommendations ?? this.recommendations,
      mandatoryMet: mandatoryMet ?? this.mandatoryMet,
      mandatoryTotal: mandatoryTotal ?? this.mandatoryTotal,
      preferredMet: preferredMet ?? this.preferredMet,
      preferredTotal: preferredTotal ?? this.preferredTotal,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      validityPeriod: validityPeriod ?? this.validityPeriod,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'userId': userId,
      'overallScore': overallScore,
      'matchType': matchType.code,
      'isEligible': isEligible,
      'matchDetails': matchDetails.map((detail) => detail.toJson()).toList(),
      'certificateGaps': certificateGaps.map((gap) => gap.toJson()).toList(),
      'recommendations': recommendations.map((rec) => rec.toJson()).toList(),
      'mandatoryMet': mandatoryMet,
      'mandatoryTotal': mandatoryTotal,
      'preferredMet': preferredMet,
      'preferredTotal': preferredTotal,
      'calculatedAt': calculatedAt.toIso8601String(),
      'validityPeriodHours': validityPeriod?.inHours,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory CertificateMatchResult.fromJson(Map<String, dynamic> json) {
    return CertificateMatchResult(
      jobId: json['jobId'],
      userId: json['userId'],
      overallScore: json['overallScore'],
      matchType: MatchType.fromScore(json['overallScore']),
      isEligible: json['isEligible'],
      matchDetails: (json['matchDetails'] as List<dynamic>?)
          ?.map((detail) => CertificateMatchDetail.fromJson(detail))
          .toList() ?? [],
      certificateGaps: (json['certificateGaps'] as List<dynamic>?)
          ?.map((gap) => CertificateGap.fromJson(gap))
          .toList() ?? [],
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((rec) => CertificateRecommendation.fromJson(rec))
          .toList() ?? [],
      mandatoryMet: json['mandatoryMet'],
      mandatoryTotal: json['mandatoryTotal'],
      preferredMet: json['preferredMet'],
      preferredTotal: json['preferredTotal'],
      calculatedAt: DateTime.parse(json['calculatedAt']),
      validityPeriod: json['validityPeriodHours'] != null
          ? Duration(hours: json['validityPeriodHours'])
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
    jobId, userId, overallScore, matchType, isEligible, matchDetails,
    certificateGaps, recommendations, mandatoryMet, mandatoryTotal,
    preferredMet, preferredTotal, calculatedAt, validityPeriod, metadata,
  ];
}

/// Batch matching result for multiple jobs
class BatchCertificateMatchResult extends Equatable {
  final String userId;
  final List<CertificateMatchResult> matchResults;
  final DateTime calculatedAt;
  final Map<String, int> overallStats; // Statistics across all matches
  final List<String> topRecommendations; // Most impactful recommendations
  final Map<String, dynamic> metadata;

  const BatchCertificateMatchResult({
    required this.userId,
    this.matchResults = const [],
    required this.calculatedAt,
    this.overallStats = const {},
    this.topRecommendations = const [],
    this.metadata = const {},
  });

  /// Get best match result
  CertificateMatchResult? get bestMatch {
    if (matchResults.isEmpty) return null;
    return matchResults.reduce((a, b) => a.overallScore > b.overallScore ? a : b);
  }

  /// Get average score across all jobs
  double get averageScore {
    if (matchResults.isEmpty) return 0.0;
    final total = matchResults.fold(0, (accumulator, result) => accumulator + result.overallScore);
    return total / matchResults.length;
  }

  /// Get number of jobs candidate is eligible for
  int get eligibleJobsCount => matchResults.where((result) => result.isEligible).length;

  /// Get match distribution
  Map<MatchType, int> get matchDistribution {
    final distribution = <MatchType, int>{};
    for (final matchType in MatchType.values) {
      distribution[matchType] = 0;
    }
    
    for (final result in matchResults) {
      distribution[result.matchType] = (distribution[result.matchType] ?? 0) + 1;
    }
    
    return distribution;
  }

  @override
  List<Object?> get props => [
    userId, matchResults, calculatedAt, overallStats, topRecommendations, metadata,
  ];
}