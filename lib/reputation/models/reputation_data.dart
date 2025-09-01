import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive reputation data model for SecuryFlex platform
/// 
/// Tracks reputation metrics for both guards and companies
/// Integrates with existing rating and profile systems
/// Follows Dutch business compliance and CAO arbeidsrecht standards
class ReputationData {
  final String userId;
  final String userRole; // 'guard' or 'company'
  final DateTime lastCalculated;
  final DateTime firstJobDate;
  
  // Core reputation metrics
  final double overallScore; // 0-100 weighted reputation score
  final double jobCompletionRating; // Average rating from completed jobs
  final double reliabilityScore; // On-time arrivals, no-shows etc.
  final double clientFeedbackScore; // Average client feedback rating
  final double complianceScore; // Certification and legal compliance
  final double experienceMultiplier; // Experience-based score multiplier
  
  // Detailed performance metrics
  final int totalJobsCompleted;
  final int totalJobsCancelled;
  final int noShowCount;
  final int lateArrivalCount;
  final int earlyCompletionCount;
  final double averageResponseTime; // Hours to respond to job offers
  
  // Client satisfaction metrics
  final int positiveReviewCount;
  final int neutralReviewCount;
  final int negativeReviewCount;
  final double repeatClientPercentage;
  final double recommendationRate;
  
  // Compliance and certification metrics
  final bool wpbrCertified; // For guards
  final bool kvkVerified; // For companies
  final int activeCertificateCount;
  final DateTime? lastCertificateUpdate;
  final int complianceViolationCount;
  
  // Trend and growth metrics
  final double monthlyScoreChange;
  final double quarterlyScoreChange;
  final ReputationTrend currentTrend;
  final List<ReputationMilestone> achievedMilestones;
  
  // Specialization reputation
  final Map<String, double> specializationScores; // Reputation per specialization
  final String? topSpecialization;
  final double averageHourlyRate;
  
  const ReputationData({
    required this.userId,
    required this.userRole,
    required this.lastCalculated,
    required this.firstJobDate,
    required this.overallScore,
    required this.jobCompletionRating,
    required this.reliabilityScore,
    required this.clientFeedbackScore,
    required this.complianceScore,
    required this.experienceMultiplier,
    required this.totalJobsCompleted,
    required this.totalJobsCancelled,
    required this.noShowCount,
    required this.lateArrivalCount,
    required this.earlyCompletionCount,
    required this.averageResponseTime,
    required this.positiveReviewCount,
    required this.neutralReviewCount,
    required this.negativeReviewCount,
    required this.repeatClientPercentage,
    required this.recommendationRate,
    required this.wpbrCertified,
    required this.kvkVerified,
    required this.activeCertificateCount,
    this.lastCertificateUpdate,
    required this.complianceViolationCount,
    required this.monthlyScoreChange,
    required this.quarterlyScoreChange,
    required this.currentTrend,
    required this.achievedMilestones,
    required this.specializationScores,
    this.topSpecialization,
    required this.averageHourlyRate,
  });

  /// Factory constructor for empty/initial reputation
  factory ReputationData.initial({
    required String userId,
    required String userRole,
  }) {
    return ReputationData(
      userId: userId,
      userRole: userRole,
      lastCalculated: DateTime.now(),
      firstJobDate: DateTime.now(),
      overallScore: 50.0, // Start with neutral score
      jobCompletionRating: 0.0,
      reliabilityScore: 100.0, // Start optimistic
      clientFeedbackScore: 0.0,
      complianceScore: userRole == 'guard' ? 0.0 : 50.0, // KvK gives baseline for companies
      experienceMultiplier: 1.0,
      totalJobsCompleted: 0,
      totalJobsCancelled: 0,
      noShowCount: 0,
      lateArrivalCount: 0,
      earlyCompletionCount: 0,
      averageResponseTime: 24.0,
      positiveReviewCount: 0,
      neutralReviewCount: 0,
      negativeReviewCount: 0,
      repeatClientPercentage: 0.0,
      recommendationRate: 0.0,
      wpbrCertified: false,
      kvkVerified: userRole == 'company',
      activeCertificateCount: 0,
      lastCertificateUpdate: null,
      complianceViolationCount: 0,
      monthlyScoreChange: 0.0,
      quarterlyScoreChange: 0.0,
      currentTrend: ReputationTrend.stable,
      achievedMilestones: [],
      specializationScores: {},
      topSpecialization: null,
      averageHourlyRate: 0.0,
    );
  }

  /// Create from Firestore document
  factory ReputationData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ReputationData(
      userId: data['userId'] as String,
      userRole: data['userRole'] as String,
      lastCalculated: (data['lastCalculated'] as Timestamp).toDate(),
      firstJobDate: (data['firstJobDate'] as Timestamp).toDate(),
      overallScore: (data['overallScore'] as num).toDouble(),
      jobCompletionRating: (data['jobCompletionRating'] as num).toDouble(),
      reliabilityScore: (data['reliabilityScore'] as num).toDouble(),
      clientFeedbackScore: (data['clientFeedbackScore'] as num).toDouble(),
      complianceScore: (data['complianceScore'] as num).toDouble(),
      experienceMultiplier: (data['experienceMultiplier'] as num).toDouble(),
      totalJobsCompleted: data['totalJobsCompleted'] as int,
      totalJobsCancelled: data['totalJobsCancelled'] as int,
      noShowCount: data['noShowCount'] as int,
      lateArrivalCount: data['lateArrivalCount'] as int,
      earlyCompletionCount: data['earlyCompletionCount'] as int,
      averageResponseTime: (data['averageResponseTime'] as num).toDouble(),
      positiveReviewCount: data['positiveReviewCount'] as int,
      neutralReviewCount: data['neutralReviewCount'] as int,
      negativeReviewCount: data['negativeReviewCount'] as int,
      repeatClientPercentage: (data['repeatClientPercentage'] as num).toDouble(),
      recommendationRate: (data['recommendationRate'] as num).toDouble(),
      wpbrCertified: data['wpbrCertified'] as bool,
      kvkVerified: data['kvkVerified'] as bool,
      activeCertificateCount: data['activeCertificateCount'] as int,
      lastCertificateUpdate: data['lastCertificateUpdate'] != null 
          ? (data['lastCertificateUpdate'] as Timestamp).toDate() 
          : null,
      complianceViolationCount: data['complianceViolationCount'] as int,
      monthlyScoreChange: (data['monthlyScoreChange'] as num).toDouble(),
      quarterlyScoreChange: (data['quarterlyScoreChange'] as num).toDouble(),
      currentTrend: ReputationTrend.values.firstWhere(
        (e) => e.name == data['currentTrend'],
        orElse: () => ReputationTrend.stable,
      ),
      achievedMilestones: (data['achievedMilestones'] as List<dynamic>)
          .map((m) => ReputationMilestone.values.firstWhere(
                (e) => e.name == m,
                orElse: () => ReputationMilestone.firstJob,
              ))
          .toList(),
      specializationScores: Map<String, double>.from(
        data['specializationScores'] as Map<String, dynamic>? ?? {},
      ),
      topSpecialization: data['topSpecialization'] as String?,
      averageHourlyRate: (data['averageHourlyRate'] as num).toDouble(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userRole': userRole,
      'lastCalculated': Timestamp.fromDate(lastCalculated),
      'firstJobDate': Timestamp.fromDate(firstJobDate),
      'overallScore': overallScore,
      'jobCompletionRating': jobCompletionRating,
      'reliabilityScore': reliabilityScore,
      'clientFeedbackScore': clientFeedbackScore,
      'complianceScore': complianceScore,
      'experienceMultiplier': experienceMultiplier,
      'totalJobsCompleted': totalJobsCompleted,
      'totalJobsCancelled': totalJobsCancelled,
      'noShowCount': noShowCount,
      'lateArrivalCount': lateArrivalCount,
      'earlyCompletionCount': earlyCompletionCount,
      'averageResponseTime': averageResponseTime,
      'positiveReviewCount': positiveReviewCount,
      'neutralReviewCount': neutralReviewCount,
      'negativeReviewCount': negativeReviewCount,
      'repeatClientPercentage': repeatClientPercentage,
      'recommendationRate': recommendationRate,
      'wpbrCertified': wpbrCertified,
      'kvkVerified': kvkVerified,
      'activeCertificateCount': activeCertificateCount,
      'lastCertificateUpdate': lastCertificateUpdate != null 
          ? Timestamp.fromDate(lastCertificateUpdate!) 
          : null,
      'complianceViolationCount': complianceViolationCount,
      'monthlyScoreChange': monthlyScoreChange,
      'quarterlyScoreChange': quarterlyScoreChange,
      'currentTrend': currentTrend.name,
      'achievedMilestones': achievedMilestones.map((m) => m.name).toList(),
      'specializationScores': specializationScores,
      'topSpecialization': topSpecialization,
      'averageHourlyRate': averageHourlyRate,
    };
  }

  /// Copy with updated values
  ReputationData copyWith({
    String? userId,
    String? userRole,
    DateTime? lastCalculated,
    DateTime? firstJobDate,
    double? overallScore,
    double? jobCompletionRating,
    double? reliabilityScore,
    double? clientFeedbackScore,
    double? complianceScore,
    double? experienceMultiplier,
    int? totalJobsCompleted,
    int? totalJobsCancelled,
    int? noShowCount,
    int? lateArrivalCount,
    int? earlyCompletionCount,
    double? averageResponseTime,
    int? positiveReviewCount,
    int? neutralReviewCount,
    int? negativeReviewCount,
    double? repeatClientPercentage,
    double? recommendationRate,
    bool? wpbrCertified,
    bool? kvkVerified,
    int? activeCertificateCount,
    DateTime? lastCertificateUpdate,
    int? complianceViolationCount,
    double? monthlyScoreChange,
    double? quarterlyScoreChange,
    ReputationTrend? currentTrend,
    List<ReputationMilestone>? achievedMilestones,
    Map<String, double>? specializationScores,
    String? topSpecialization,
    double? averageHourlyRate,
  }) {
    return ReputationData(
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      lastCalculated: lastCalculated ?? this.lastCalculated,
      firstJobDate: firstJobDate ?? this.firstJobDate,
      overallScore: overallScore ?? this.overallScore,
      jobCompletionRating: jobCompletionRating ?? this.jobCompletionRating,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      clientFeedbackScore: clientFeedbackScore ?? this.clientFeedbackScore,
      complianceScore: complianceScore ?? this.complianceScore,
      experienceMultiplier: experienceMultiplier ?? this.experienceMultiplier,
      totalJobsCompleted: totalJobsCompleted ?? this.totalJobsCompleted,
      totalJobsCancelled: totalJobsCancelled ?? this.totalJobsCancelled,
      noShowCount: noShowCount ?? this.noShowCount,
      lateArrivalCount: lateArrivalCount ?? this.lateArrivalCount,
      earlyCompletionCount: earlyCompletionCount ?? this.earlyCompletionCount,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      positiveReviewCount: positiveReviewCount ?? this.positiveReviewCount,
      neutralReviewCount: neutralReviewCount ?? this.neutralReviewCount,
      negativeReviewCount: negativeReviewCount ?? this.negativeReviewCount,
      repeatClientPercentage: repeatClientPercentage ?? this.repeatClientPercentage,
      recommendationRate: recommendationRate ?? this.recommendationRate,
      wpbrCertified: wpbrCertified ?? this.wpbrCertified,
      kvkVerified: kvkVerified ?? this.kvkVerified,
      activeCertificateCount: activeCertificateCount ?? this.activeCertificateCount,
      lastCertificateUpdate: lastCertificateUpdate ?? this.lastCertificateUpdate,
      complianceViolationCount: complianceViolationCount ?? this.complianceViolationCount,
      monthlyScoreChange: monthlyScoreChange ?? this.monthlyScoreChange,
      quarterlyScoreChange: quarterlyScoreChange ?? this.quarterlyScoreChange,
      currentTrend: currentTrend ?? this.currentTrend,
      achievedMilestones: achievedMilestones ?? this.achievedMilestones,
      specializationScores: specializationScores ?? this.specializationScores,
      topSpecialization: topSpecialization ?? this.topSpecialization,
      averageHourlyRate: averageHourlyRate ?? this.averageHourlyRate,
    );
  }

  /// Get reputation level based on overall score
  ReputationLevel get reputationLevel {
    if (overallScore >= 90) return ReputationLevel.exceptional;
    if (overallScore >= 80) return ReputationLevel.excellent;
    if (overallScore >= 70) return ReputationLevel.good;
    if (overallScore >= 60) return ReputationLevel.average;
    if (overallScore >= 40) return ReputationLevel.belowAverage;
    return ReputationLevel.poor;
  }

  /// Get completion rate percentage
  double get completionRate {
    if (totalJobsCompleted + totalJobsCancelled == 0) return 100.0;
    return (totalJobsCompleted / (totalJobsCompleted + totalJobsCancelled)) * 100;
  }

  /// Get total review count
  int get totalReviewCount => positiveReviewCount + neutralReviewCount + negativeReviewCount;

  /// Get positive review percentage
  double get positiveReviewPercentage {
    if (totalReviewCount == 0) return 0.0;
    return (positiveReviewCount / totalReviewCount) * 100;
  }

  /// Get years of experience
  double get yearsOfExperience {
    final difference = DateTime.now().difference(firstJobDate);
    return difference.inDays / 365.25;
  }

  /// Check if user is considered reliable (CAO arbeidsrecht compliant)
  bool get isReliableByCAOStandards {
    // Dutch CAO arbeidsrecht reliability standards
    return noShowCount <= 2 && // Max 2 no-shows per year
           (lateArrivalCount / (totalJobsCompleted + lateArrivalCount)) <= 0.05 && // <5% late arrivals
           completionRate >= 95.0; // 95% completion rate
  }

  /// Check if eligible for premium job matching
  bool get qualifiesForPremiumJobs {
    return overallScore >= 75.0 &&
           totalJobsCompleted >= 10 &&
           wpbrCertified && // For guards, WPBR required for premium jobs
           complianceViolationCount == 0;
  }

  /// Get Dutch formatted score display
  String get dutchFormattedScore => '${overallScore.round()}/100';

  /// Get next milestone to achieve
  ReputationMilestone? get nextMilestone {
    final allMilestones = ReputationMilestone.values;
    for (final milestone in allMilestones) {
      if (!achievedMilestones.contains(milestone)) {
        if (milestone.isEligible(this)) {
          return milestone;
        }
      }
    }
    return null;
  }
}

/// Reputation trend enumeration
enum ReputationTrend {
  declining,
  stable,
  improving;

  String get dutchDescription {
    switch (this) {
      case ReputationTrend.declining:
        return 'Dalende trend';
      case ReputationTrend.stable:
        return 'Stabiele reputatie';
      case ReputationTrend.improving:
        return 'Stijgende trend';
    }
  }

  String get dutchAdvice {
    switch (this) {
      case ReputationTrend.declining:
        return 'Focus op het verbeteren van je prestaties en klanttevredenheid';
      case ReputationTrend.stable:
        return 'Behoud je huidige prestatieniveau';
      case ReputationTrend.improving:
        return 'Blijf zo doorgaan! Je reputatie verbetert';
    }
  }
}

/// Reputation level enumeration
enum ReputationLevel {
  poor,
  belowAverage,
  average,
  good,
  excellent,
  exceptional;

  String get dutchTitle {
    switch (this) {
      case ReputationLevel.poor:
        return 'Onvoldoende';
      case ReputationLevel.belowAverage:
        return 'Onder gemiddeld';
      case ReputationLevel.average:
        return 'Gemiddeld';
      case ReputationLevel.good:
        return 'Goed';
      case ReputationLevel.excellent:
        return 'Uitstekend';
      case ReputationLevel.exceptional:
        return 'Uitzonderlijk';
    }
  }

  String get dutchDescription {
    switch (this) {
      case ReputationLevel.poor:
        return 'Je reputatie heeft verbetering nodig';
      case ReputationLevel.belowAverage:
        return 'Je presteert onder het gemiddelde niveau';
      case ReputationLevel.average:
        return 'Je presteert op gemiddeld niveau';
      case ReputationLevel.good:
        return 'Je hebt een goede reputatie opgebouwd';
      case ReputationLevel.excellent:
        return 'Je bent een uitstekende professional';
      case ReputationLevel.exceptional:
        return 'Je behoort tot de top van de sector';
    }
  }

  /// Get minimum score required for this level
  double get minimumScore {
    switch (this) {
      case ReputationLevel.poor:
        return 0.0;
      case ReputationLevel.belowAverage:
        return 40.0;
      case ReputationLevel.average:
        return 60.0;
      case ReputationLevel.good:
        return 70.0;
      case ReputationLevel.excellent:
        return 80.0;
      case ReputationLevel.exceptional:
        return 90.0;
    }
  }
}

/// Reputation milestone enumeration
enum ReputationMilestone {
  firstJob,
  firstGoodReview,
  tenJobsCompleted,
  fiftyJobsCompleted,
  hundredJobsCompleted,
  perfectMonth,
  topRatedGuard,
  reliabilityExpert,
  clientFavorite,
  certificationMaster;

  String get dutchTitle {
    switch (this) {
      case ReputationMilestone.firstJob:
        return 'Eerste Opdracht';
      case ReputationMilestone.firstGoodReview:
        return 'Eerste Positieve Review';
      case ReputationMilestone.tenJobsCompleted:
        return '10 Opdrachten Voltooid';
      case ReputationMilestone.fiftyJobsCompleted:
        return '50 Opdrachten Voltooid';
      case ReputationMilestone.hundredJobsCompleted:
        return '100 Opdrachten Voltooid';
      case ReputationMilestone.perfectMonth:
        return 'Perfecte Maand';
      case ReputationMilestone.topRatedGuard:
        return 'Top Beveiliger';
      case ReputationMilestone.reliabilityExpert:
        return 'Betrouwbaarheidsexpert';
      case ReputationMilestone.clientFavorite:
        return 'Klantenfavoriet';
      case ReputationMilestone.certificationMaster:
        return 'Certificeringsmeester';
    }
  }

  String get dutchDescription {
    switch (this) {
      case ReputationMilestone.firstJob:
        return 'Je hebt je eerste opdracht succesvol voltooid';
      case ReputationMilestone.firstGoodReview:
        return 'Je hebt je eerste positieve beoordeling ontvangen';
      case ReputationMilestone.tenJobsCompleted:
        return 'Je hebt 10 opdrachten succesvol voltooid';
      case ReputationMilestone.fiftyJobsCompleted:
        return 'Je hebt 50 opdrachten succesvol voltooid';
      case ReputationMilestone.hundredJobsCompleted:
        return 'Je hebt 100 opdrachten succesvol voltooid';
      case ReputationMilestone.perfectMonth:
        return 'Je hebt een maand zonder afzeggingen of te laat komen gehad';
      case ReputationMilestone.topRatedGuard:
        return 'Je behoort tot de best beoordeelde beveiligers';
      case ReputationMilestone.reliabilityExpert:
        return 'Je bent erkend als betrouwbaarheidsexpert';
      case ReputationMilestone.clientFavorite:
        return 'Je bent een favoriet bij terugkerende klanten';
      case ReputationMilestone.certificationMaster:
        return 'Je hebt alle relevante certificeringen behaald';
    }
  }

  /// Check if user is eligible for this milestone
  bool isEligible(ReputationData reputation) {
    switch (this) {
      case ReputationMilestone.firstJob:
        return reputation.totalJobsCompleted >= 1;
      case ReputationMilestone.firstGoodReview:
        return reputation.positiveReviewCount >= 1;
      case ReputationMilestone.tenJobsCompleted:
        return reputation.totalJobsCompleted >= 10;
      case ReputationMilestone.fiftyJobsCompleted:
        return reputation.totalJobsCompleted >= 50;
      case ReputationMilestone.hundredJobsCompleted:
        return reputation.totalJobsCompleted >= 100;
      case ReputationMilestone.perfectMonth:
        return reputation.noShowCount == 0 && reputation.lateArrivalCount == 0;
      case ReputationMilestone.topRatedGuard:
        return reputation.overallScore >= 90 && reputation.totalJobsCompleted >= 20;
      case ReputationMilestone.reliabilityExpert:
        return reputation.reliabilityScore >= 95 && reputation.isReliableByCAOStandards;
      case ReputationMilestone.clientFavorite:
        return reputation.repeatClientPercentage >= 50;
      case ReputationMilestone.certificationMaster:
        return reputation.activeCertificateCount >= 3 && reputation.wpbrCertified;
    }
  }
}