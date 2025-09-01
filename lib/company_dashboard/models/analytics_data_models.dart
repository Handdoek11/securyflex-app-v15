import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive analytics data models for SecuryFlex recruitment analytics
/// Following SecuryFlex patterns with Dutch business logic integration

/// Company daily analytics aggregation model
/// Provides comprehensive daily metrics for company recruitment performance
class CompanyDailyAnalytics {
  final String date;                    // YYYY-MM-DD format
  final String companyId;
  
  // Job Performance Metrics
  final int jobsPosted;
  final int jobsActive;
  final int jobsCompleted;
  final int jobsCancelled;
  
  // Application Metrics
  final int totalApplications;
  final int applicationsAccepted;
  final int applicationsRejected;
  final int applicationsPending;
  
  // Conversion Funnel
  final int jobViews;
  final int uniqueJobViews;
  final double viewToApplicationRate;
  final double applicationToHireRate;
  
  // Time & Cost Metrics (Dutch business requirements)
  final double averageTimeToFill;       // hours
  final double averageTimeToFirstApplication; // hours
  final double totalCostPerHire;        // euros
  final double totalRecruitmentSpend;   // euros
  
  // Source Effectiveness
  final Map<String, SourceMetrics> sourceBreakdown;
  
  // Quality Metrics
  final double averageApplicationQuality; // 1-5 scale
  final double guardRetentionRate;       // percentage
  
  final DateTime updatedAt;

  const CompanyDailyAnalytics({
    required this.date,
    required this.companyId,
    required this.jobsPosted,
    required this.jobsActive,
    required this.jobsCompleted,
    required this.jobsCancelled,
    required this.totalApplications,
    required this.applicationsAccepted,
    required this.applicationsRejected,
    required this.applicationsPending,
    required this.jobViews,
    required this.uniqueJobViews,
    required this.viewToApplicationRate,
    required this.applicationToHireRate,
    required this.averageTimeToFill,
    required this.averageTimeToFirstApplication,
    required this.totalCostPerHire,
    required this.totalRecruitmentSpend,
    required this.sourceBreakdown,
    required this.averageApplicationQuality,
    required this.guardRetentionRate,
    required this.updatedAt,
  });

  /// Copy with method for updates
  CompanyDailyAnalytics copyWith({
    String? date,
    String? companyId,
    int? jobsPosted,
    int? jobsActive,
    int? jobsCompleted,
    int? jobsCancelled,
    int? totalApplications,
    int? applicationsAccepted,
    int? applicationsRejected,
    int? applicationsPending,
    int? jobViews,
    int? uniqueJobViews,
    double? viewToApplicationRate,
    double? applicationToHireRate,
    double? averageTimeToFill,
    double? averageTimeToFirstApplication,
    double? totalCostPerHire,
    double? totalRecruitmentSpend,
    Map<String, SourceMetrics>? sourceBreakdown,
    double? averageApplicationQuality,
    double? guardRetentionRate,
    DateTime? updatedAt,
  }) {
    return CompanyDailyAnalytics(
      date: date ?? this.date,
      companyId: companyId ?? this.companyId,
      jobsPosted: jobsPosted ?? this.jobsPosted,
      jobsActive: jobsActive ?? this.jobsActive,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      jobsCancelled: jobsCancelled ?? this.jobsCancelled,
      totalApplications: totalApplications ?? this.totalApplications,
      applicationsAccepted: applicationsAccepted ?? this.applicationsAccepted,
      applicationsRejected: applicationsRejected ?? this.applicationsRejected,
      applicationsPending: applicationsPending ?? this.applicationsPending,
      jobViews: jobViews ?? this.jobViews,
      uniqueJobViews: uniqueJobViews ?? this.uniqueJobViews,
      viewToApplicationRate: viewToApplicationRate ?? this.viewToApplicationRate,
      applicationToHireRate: applicationToHireRate ?? this.applicationToHireRate,
      averageTimeToFill: averageTimeToFill ?? this.averageTimeToFill,
      averageTimeToFirstApplication: averageTimeToFirstApplication ?? this.averageTimeToFirstApplication,
      totalCostPerHire: totalCostPerHire ?? this.totalCostPerHire,
      totalRecruitmentSpend: totalRecruitmentSpend ?? this.totalRecruitmentSpend,
      sourceBreakdown: sourceBreakdown ?? this.sourceBreakdown,
      averageApplicationQuality: averageApplicationQuality ?? this.averageApplicationQuality,
      guardRetentionRate: guardRetentionRate ?? this.guardRetentionRate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'companyId': companyId,
      'jobsPosted': jobsPosted,
      'jobsActive': jobsActive,
      'jobsCompleted': jobsCompleted,
      'jobsCancelled': jobsCancelled,
      'totalApplications': totalApplications,
      'applicationsAccepted': applicationsAccepted,
      'applicationsRejected': applicationsRejected,
      'applicationsPending': applicationsPending,
      'jobViews': jobViews,
      'uniqueJobViews': uniqueJobViews,
      'viewToApplicationRate': viewToApplicationRate,
      'applicationToHireRate': applicationToHireRate,
      'averageTimeToFill': averageTimeToFill,
      'averageTimeToFirstApplication': averageTimeToFirstApplication,
      'totalCostPerHire': totalCostPerHire,
      'totalRecruitmentSpend': totalRecruitmentSpend,
      'sourceBreakdown': sourceBreakdown.map((key, value) => MapEntry(key, value.toMap())),
      'averageApplicationQuality': averageApplicationQuality,
      'guardRetentionRate': guardRetentionRate,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore map
  factory CompanyDailyAnalytics.fromMap(Map<String, dynamic> map) {
    return CompanyDailyAnalytics(
      date: map['date'] ?? '',
      companyId: map['companyId'] ?? '',
      jobsPosted: map['jobsPosted'] ?? 0,
      jobsActive: map['jobsActive'] ?? 0,
      jobsCompleted: map['jobsCompleted'] ?? 0,
      jobsCancelled: map['jobsCancelled'] ?? 0,
      totalApplications: map['totalApplications'] ?? 0,
      applicationsAccepted: map['applicationsAccepted'] ?? 0,
      applicationsRejected: map['applicationsRejected'] ?? 0,
      applicationsPending: map['applicationsPending'] ?? 0,
      jobViews: map['jobViews'] ?? 0,
      uniqueJobViews: map['uniqueJobViews'] ?? 0,
      viewToApplicationRate: (map['viewToApplicationRate'] ?? 0.0).toDouble(),
      applicationToHireRate: (map['applicationToHireRate'] ?? 0.0).toDouble(),
      averageTimeToFill: (map['averageTimeToFill'] ?? 0.0).toDouble(),
      averageTimeToFirstApplication: (map['averageTimeToFirstApplication'] ?? 0.0).toDouble(),
      totalCostPerHire: (map['totalCostPerHire'] ?? 0.0).toDouble(),
      totalRecruitmentSpend: (map['totalRecruitmentSpend'] ?? 0.0).toDouble(),
      sourceBreakdown: (map['sourceBreakdown'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, SourceMetrics.fromMap(value))),
      averageApplicationQuality: (map['averageApplicationQuality'] ?? 0.0).toDouble(),
      guardRetentionRate: (map['guardRetentionRate'] ?? 0.0).toDouble(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Calculate total conversion rate
  double get totalConversionRate {
    if (jobViews == 0) return 0.0;
    return (applicationsAccepted / jobViews) * 100;
  }

  /// Calculate recruitment efficiency score
  double get recruitmentEfficiencyScore {
    final timeScore = averageTimeToFill > 0 ? (168 / averageTimeToFill).clamp(0.0, 1.0) : 0.0; // 1 week baseline
    final costScore = totalCostPerHire > 0 ? (500 / totalCostPerHire).clamp(0.0, 1.0) : 0.0; // €500 baseline
    final qualityScore = averageApplicationQuality / 5.0;
    
    return ((timeScore + costScore + qualityScore) / 3) * 100;
  }
}

/// Source effectiveness metrics
class SourceMetrics {
  final int applications;
  final int hires;
  final double cost;

  const SourceMetrics({
    required this.applications,
    required this.hires,
    required this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'applications': applications,
      'hires': hires,
      'cost': cost,
    };
  }

  factory SourceMetrics.fromMap(Map<String, dynamic> map) {
    return SourceMetrics(
      applications: map['applications'] ?? 0,
      hires: map['hires'] ?? 0,
      cost: (map['cost'] ?? 0.0).toDouble(),
    );
  }

  double get hireRate {
    if (applications == 0) return 0.0;
    return (hires / applications) * 100;
  }

  double get costPerHire {
    if (hires == 0) return 0.0;
    return cost / hires;
  }
}

/// Job analytics event tracking model
/// Captures individual user interactions for detailed analytics
class JobAnalyticsEvent {
  final String eventId;
  final String jobId;
  final JobEventType eventType;
  final DateTime timestamp;

  // User Context
  final String? userId;
  final String userRole; // 'guard', 'company', 'admin'

  // Event Details
  final String source; // 'search', 'recommendation', 'direct', 'notification'
  final String deviceType; // 'mobile', 'desktop', 'tablet'
  final String? location;

  // Performance Data
  final int? sessionDuration; // seconds
  final int? pageLoadTime; // milliseconds

  // Conversion Context
  final bool? resultedInApplication;
  final String? applicationId;

  // Metadata for extensibility
  final Map<String, dynamic> metadata;

  const JobAnalyticsEvent({
    required this.eventId,
    required this.jobId,
    required this.eventType,
    required this.timestamp,
    this.userId,
    required this.userRole,
    required this.source,
    required this.deviceType,
    this.location,
    this.sessionDuration,
    this.pageLoadTime,
    this.resultedInApplication,
    this.applicationId,
    this.metadata = const {},
  });

  /// Copy with method for updates
  JobAnalyticsEvent copyWith({
    String? eventId,
    String? jobId,
    JobEventType? eventType,
    DateTime? timestamp,
    String? userId,
    String? userRole,
    String? source,
    String? deviceType,
    String? location,
    int? sessionDuration,
    int? pageLoadTime,
    bool? resultedInApplication,
    String? applicationId,
    Map<String, dynamic>? metadata,
  }) {
    return JobAnalyticsEvent(
      eventId: eventId ?? this.eventId,
      jobId: jobId ?? this.jobId,
      eventType: eventType ?? this.eventType,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      source: source ?? this.source,
      deviceType: deviceType ?? this.deviceType,
      location: location ?? this.location,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      pageLoadTime: pageLoadTime ?? this.pageLoadTime,
      resultedInApplication: resultedInApplication ?? this.resultedInApplication,
      applicationId: applicationId ?? this.applicationId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'jobId': jobId,
      'eventType': eventType.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'userRole': userRole,
      'source': source,
      'deviceType': deviceType,
      'location': location,
      'sessionDuration': sessionDuration,
      'pageLoadTime': pageLoadTime,
      'resultedInApplication': resultedInApplication,
      'applicationId': applicationId,
      'metadata': metadata,
    };
  }

  /// Create from Firestore map
  factory JobAnalyticsEvent.fromMap(Map<String, dynamic> map) {
    return JobAnalyticsEvent(
      eventId: map['eventId'] ?? '',
      jobId: map['jobId'] ?? '',
      eventType: JobEventType.values.firstWhere(
        (e) => e.name == map['eventType'],
        orElse: () => JobEventType.view,
      ),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: map['userId'],
      userRole: map['userRole'] ?? 'guard',
      source: map['source'] ?? 'direct',
      deviceType: map['deviceType'] ?? 'mobile',
      location: map['location'],
      sessionDuration: map['sessionDuration'],
      pageLoadTime: map['pageLoadTime'],
      resultedInApplication: map['resultedInApplication'],
      applicationId: map['applicationId'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

/// Job event types for analytics tracking
enum JobEventType {
  // Existing job lifecycle events
  view,
  application,
  hire,
  rejection,
  completion,
  cancellation,
  modification,
  expiration,
  
  // New events for job matching and specialization tracking
  userPreferenceUpdated,
  recommendationsGenerated,
  recommendationClicked,
  specializationFilterApplied,
  
  // Legacy aliases for backward compatibility
  jobViewed,
  jobApplied,
  jobSaved,
}

/// Recruitment funnel analytics model
/// Tracks the complete recruitment pipeline from job posting to hire
class RecruitmentFunnelAnalytics {
  final String period; // 'daily', 'weekly', 'monthly'
  final String companyId;

  // Funnel Stages
  final FunnelStage posted;
  final FunnelStage viewed;
  final FunnelStage applied;
  final FunnelStage interviewed;
  final FunnelStage hired;

  // Conversion Rates
  final ConversionRates conversionRates;

  // Drop-off Analysis
  final List<DropOffPoint> dropOffPoints;

  final DateTime updatedAt;

  const RecruitmentFunnelAnalytics({
    required this.period,
    required this.companyId,
    required this.posted,
    required this.viewed,
    required this.applied,
    required this.interviewed,
    required this.hired,
    required this.conversionRates,
    required this.dropOffPoints,
    required this.updatedAt,
  });

  /// Copy with method for updates
  RecruitmentFunnelAnalytics copyWith({
    String? period,
    String? companyId,
    FunnelStage? posted,
    FunnelStage? viewed,
    FunnelStage? applied,
    FunnelStage? interviewed,
    FunnelStage? hired,
    ConversionRates? conversionRates,
    List<DropOffPoint>? dropOffPoints,
    DateTime? updatedAt,
  }) {
    return RecruitmentFunnelAnalytics(
      period: period ?? this.period,
      companyId: companyId ?? this.companyId,
      posted: posted ?? this.posted,
      viewed: viewed ?? this.viewed,
      applied: applied ?? this.applied,
      interviewed: interviewed ?? this.interviewed,
      hired: hired ?? this.hired,
      conversionRates: conversionRates ?? this.conversionRates,
      dropOffPoints: dropOffPoints ?? this.dropOffPoints,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'period': period,
      'companyId': companyId,
      'posted': posted.toMap(),
      'viewed': viewed.toMap(),
      'applied': applied.toMap(),
      'interviewed': interviewed.toMap(),
      'hired': hired.toMap(),
      'conversionRates': conversionRates.toMap(),
      'dropOffPoints': dropOffPoints.map((point) => point.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore map
  factory RecruitmentFunnelAnalytics.fromMap(Map<String, dynamic> map) {
    return RecruitmentFunnelAnalytics(
      period: map['period'] ?? '',
      companyId: map['companyId'] ?? '',
      posted: FunnelStage.fromMap(map['posted'] ?? {}),
      viewed: FunnelStage.fromMap(map['viewed'] ?? {}),
      applied: FunnelStage.fromMap(map['applied'] ?? {}),
      interviewed: FunnelStage.fromMap(map['interviewed'] ?? {}),
      hired: FunnelStage.fromMap(map['hired'] ?? {}),
      conversionRates: ConversionRates.fromMap(map['conversionRates'] ?? {}),
      dropOffPoints: (map['dropOffPoints'] as List<dynamic>? ?? [])
          .map((point) => DropOffPoint.fromMap(point))
          .toList(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Calculate overall funnel efficiency
  double get funnelEfficiency {
    if (posted.count == 0) return 0.0;
    return (hired.count / posted.count) * 100;
  }
}

/// Funnel stage data
class FunnelStage {
  final int count;
  final List<String> items; // job IDs or application IDs
  final double? averageValue; // time, cost, etc.

  const FunnelStage({
    required this.count,
    required this.items,
    this.averageValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'items': items,
      'averageValue': averageValue,
    };
  }

  factory FunnelStage.fromMap(Map<String, dynamic> map) {
    return FunnelStage(
      count: map['count'] ?? 0,
      items: List<String>.from(map['items'] ?? []),
      averageValue: map['averageValue']?.toDouble(),
    );
  }
}

/// Conversion rates between funnel stages
class ConversionRates {
  final double viewToApplication;
  final double applicationToInterview;
  final double interviewToHire;
  final double overallConversion;

  const ConversionRates({
    required this.viewToApplication,
    required this.applicationToInterview,
    required this.interviewToHire,
    required this.overallConversion,
  });

  Map<String, dynamic> toMap() {
    return {
      'viewToApplication': viewToApplication,
      'applicationToInterview': applicationToInterview,
      'interviewToHire': interviewToHire,
      'overallConversion': overallConversion,
    };
  }

  factory ConversionRates.fromMap(Map<String, dynamic> map) {
    return ConversionRates(
      viewToApplication: (map['viewToApplication'] ?? 0.0).toDouble(),
      applicationToInterview: (map['applicationToInterview'] ?? 0.0).toDouble(),
      interviewToHire: (map['interviewToHire'] ?? 0.0).toDouble(),
      overallConversion: (map['overallConversion'] ?? 0.0).toDouble(),
    );
  }
}

/// Drop-off point analysis
class DropOffPoint {
  final String stage;
  final double dropOffRate;
  final List<String> commonReasons;

  const DropOffPoint({
    required this.stage,
    required this.dropOffRate,
    required this.commonReasons,
  });

  Map<String, dynamic> toMap() {
    return {
      'stage': stage,
      'dropOffRate': dropOffRate,
      'commonReasons': commonReasons,
    };
  }

  factory DropOffPoint.fromMap(Map<String, dynamic> map) {
    return DropOffPoint(
      stage: map['stage'] ?? '',
      dropOffRate: (map['dropOffRate'] ?? 0.0).toDouble(),
      commonReasons: List<String>.from(map['commonReasons'] ?? []),
    );
  }
}

/// Source effectiveness analytics model
/// Tracks performance of different recruitment sources
class SourceAnalytics {
  final String source; // 'search', 'recommendation', 'direct', etc.
  final String companyId;

  // Performance Metrics
  final int totalViews;
  final int totalApplications;
  final int totalHires;

  // Quality Metrics
  final double averageApplicationQuality; // 1-5 scale
  final double averageGuardRating;
  final double guardRetentionRate; // percentage

  // Cost Metrics (Dutch business requirements)
  final double costPerView; // euros
  final double costPerApplication; // euros
  final double costPerHire; // euros
  final double totalSpend; // euros

  // Time Metrics
  final double averageTimeToApplication; // hours
  final double averageTimeToHire; // hours

  // Trend Data (last 30 days)
  final Map<String, DailySourceMetrics> dailyMetrics;

  final DateTime lastUpdated;

  const SourceAnalytics({
    required this.source,
    required this.companyId,
    required this.totalViews,
    required this.totalApplications,
    required this.totalHires,
    required this.averageApplicationQuality,
    required this.averageGuardRating,
    required this.guardRetentionRate,
    required this.costPerView,
    required this.costPerApplication,
    required this.costPerHire,
    required this.totalSpend,
    required this.averageTimeToApplication,
    required this.averageTimeToHire,
    required this.dailyMetrics,
    required this.lastUpdated,
  });

  /// Copy with method for updates
  SourceAnalytics copyWith({
    String? source,
    String? companyId,
    int? totalViews,
    int? totalApplications,
    int? totalHires,
    double? averageApplicationQuality,
    double? averageGuardRating,
    double? guardRetentionRate,
    double? costPerView,
    double? costPerApplication,
    double? costPerHire,
    double? totalSpend,
    double? averageTimeToApplication,
    double? averageTimeToHire,
    Map<String, DailySourceMetrics>? dailyMetrics,
    DateTime? lastUpdated,
  }) {
    return SourceAnalytics(
      source: source ?? this.source,
      companyId: companyId ?? this.companyId,
      totalViews: totalViews ?? this.totalViews,
      totalApplications: totalApplications ?? this.totalApplications,
      totalHires: totalHires ?? this.totalHires,
      averageApplicationQuality: averageApplicationQuality ?? this.averageApplicationQuality,
      averageGuardRating: averageGuardRating ?? this.averageGuardRating,
      guardRetentionRate: guardRetentionRate ?? this.guardRetentionRate,
      costPerView: costPerView ?? this.costPerView,
      costPerApplication: costPerApplication ?? this.costPerApplication,
      costPerHire: costPerHire ?? this.costPerHire,
      totalSpend: totalSpend ?? this.totalSpend,
      averageTimeToApplication: averageTimeToApplication ?? this.averageTimeToApplication,
      averageTimeToHire: averageTimeToHire ?? this.averageTimeToHire,
      dailyMetrics: dailyMetrics ?? this.dailyMetrics,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'companyId': companyId,
      'totalViews': totalViews,
      'totalApplications': totalApplications,
      'totalHires': totalHires,
      'averageApplicationQuality': averageApplicationQuality,
      'averageGuardRating': averageGuardRating,
      'guardRetentionRate': guardRetentionRate,
      'costPerView': costPerView,
      'costPerApplication': costPerApplication,
      'costPerHire': costPerHire,
      'totalSpend': totalSpend,
      'averageTimeToApplication': averageTimeToApplication,
      'averageTimeToHire': averageTimeToHire,
      'dailyMetrics': dailyMetrics.map((key, value) => MapEntry(key, value.toMap())),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Create from Firestore map
  factory SourceAnalytics.fromMap(Map<String, dynamic> map) {
    return SourceAnalytics(
      source: map['source'] ?? '',
      companyId: map['companyId'] ?? '',
      totalViews: map['totalViews'] ?? 0,
      totalApplications: map['totalApplications'] ?? 0,
      totalHires: map['totalHires'] ?? 0,
      averageApplicationQuality: (map['averageApplicationQuality'] ?? 0.0).toDouble(),
      averageGuardRating: (map['averageGuardRating'] ?? 0.0).toDouble(),
      guardRetentionRate: (map['guardRetentionRate'] ?? 0.0).toDouble(),
      costPerView: (map['costPerView'] ?? 0.0).toDouble(),
      costPerApplication: (map['costPerApplication'] ?? 0.0).toDouble(),
      costPerHire: (map['costPerHire'] ?? 0.0).toDouble(),
      totalSpend: (map['totalSpend'] ?? 0.0).toDouble(),
      averageTimeToApplication: (map['averageTimeToApplication'] ?? 0.0).toDouble(),
      averageTimeToHire: (map['averageTimeToHire'] ?? 0.0).toDouble(),
      dailyMetrics: (map['dailyMetrics'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, DailySourceMetrics.fromMap(value))),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Calculate conversion rate from views to applications
  double get viewToApplicationRate {
    if (totalViews == 0) return 0.0;
    return (totalApplications / totalViews) * 100;
  }

  /// Calculate conversion rate from applications to hires
  double get applicationToHireRate {
    if (totalApplications == 0) return 0.0;
    return (totalHires / totalApplications) * 100;
  }

  /// Calculate ROI for this source
  double get returnOnInvestment {
    if (totalSpend == 0) return 0.0;
    final revenue = totalHires * 500; // Assume €500 value per hire
    return ((revenue - totalSpend) / totalSpend) * 100;
  }
}

/// Daily source metrics for trend analysis
class DailySourceMetrics {
  final int views;
  final int applications;
  final int hires;
  final double cost;

  const DailySourceMetrics({
    required this.views,
    required this.applications,
    required this.hires,
    required this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'views': views,
      'applications': applications,
      'hires': hires,
      'cost': cost,
    };
  }

  factory DailySourceMetrics.fromMap(Map<String, dynamic> map) {
    return DailySourceMetrics(
      views: map['views'] ?? 0,
      applications: map['applications'] ?? 0,
      hires: map['hires'] ?? 0,
      cost: (map['cost'] ?? 0.0).toDouble(),
    );
  }
}

/// Job daily analytics model
/// Provides detailed daily performance metrics for individual jobs
class JobDailyAnalytics {
  final String date; // YYYY-MM-DD format
  final String jobId;
  final String companyId;

  // View Metrics
  final int totalViews;
  final int uniqueViews;
  final double averageViewDuration; // seconds
  final double bounceRate; // percentage

  // Application Metrics
  final int newApplications;
  final int totalApplications;
  final double applicationQualityScore; // 1-5 scale

  // Conversion Metrics
  final double viewToApplicationRate;
  final double applicationToResponseRate;

  // Performance Indicators
  final int searchRanking; // average position in search results
  final double recommendationScore; // algorithm recommendation strength
  final double competitiveIndex; // vs similar jobs

  // Geographic Data
  final Map<String, int> viewsByLocation; // postal code -> views

  // Time-based Patterns
  final List<int> viewsByHour; // 24-hour array
  final List<String> peakViewingHours;

  final DateTime updatedAt;

  const JobDailyAnalytics({
    required this.date,
    required this.jobId,
    required this.companyId,
    required this.totalViews,
    required this.uniqueViews,
    required this.averageViewDuration,
    required this.bounceRate,
    required this.newApplications,
    required this.totalApplications,
    required this.applicationQualityScore,
    required this.viewToApplicationRate,
    required this.applicationToResponseRate,
    required this.searchRanking,
    required this.recommendationScore,
    required this.competitiveIndex,
    required this.viewsByLocation,
    required this.viewsByHour,
    required this.peakViewingHours,
    required this.updatedAt,
  });

  /// Copy with method for updates
  JobDailyAnalytics copyWith({
    String? date,
    String? jobId,
    String? companyId,
    int? totalViews,
    int? uniqueViews,
    double? averageViewDuration,
    double? bounceRate,
    int? newApplications,
    int? totalApplications,
    double? applicationQualityScore,
    double? viewToApplicationRate,
    double? applicationToResponseRate,
    int? searchRanking,
    double? recommendationScore,
    double? competitiveIndex,
    Map<String, int>? viewsByLocation,
    List<int>? viewsByHour,
    List<String>? peakViewingHours,
    DateTime? updatedAt,
  }) {
    return JobDailyAnalytics(
      date: date ?? this.date,
      jobId: jobId ?? this.jobId,
      companyId: companyId ?? this.companyId,
      totalViews: totalViews ?? this.totalViews,
      uniqueViews: uniqueViews ?? this.uniqueViews,
      averageViewDuration: averageViewDuration ?? this.averageViewDuration,
      bounceRate: bounceRate ?? this.bounceRate,
      newApplications: newApplications ?? this.newApplications,
      totalApplications: totalApplications ?? this.totalApplications,
      applicationQualityScore: applicationQualityScore ?? this.applicationQualityScore,
      viewToApplicationRate: viewToApplicationRate ?? this.viewToApplicationRate,
      applicationToResponseRate: applicationToResponseRate ?? this.applicationToResponseRate,
      searchRanking: searchRanking ?? this.searchRanking,
      recommendationScore: recommendationScore ?? this.recommendationScore,
      competitiveIndex: competitiveIndex ?? this.competitiveIndex,
      viewsByLocation: viewsByLocation ?? this.viewsByLocation,
      viewsByHour: viewsByHour ?? this.viewsByHour,
      peakViewingHours: peakViewingHours ?? this.peakViewingHours,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'jobId': jobId,
      'companyId': companyId,
      'totalViews': totalViews,
      'uniqueViews': uniqueViews,
      'averageViewDuration': averageViewDuration,
      'bounceRate': bounceRate,
      'newApplications': newApplications,
      'totalApplications': totalApplications,
      'applicationQualityScore': applicationQualityScore,
      'viewToApplicationRate': viewToApplicationRate,
      'applicationToResponseRate': applicationToResponseRate,
      'searchRanking': searchRanking,
      'recommendationScore': recommendationScore,
      'competitiveIndex': competitiveIndex,
      'viewsByLocation': viewsByLocation,
      'viewsByHour': viewsByHour,
      'peakViewingHours': peakViewingHours,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore map
  factory JobDailyAnalytics.fromMap(Map<String, dynamic> map) {
    return JobDailyAnalytics(
      date: map['date'] ?? '',
      jobId: map['jobId'] ?? '',
      companyId: map['companyId'] ?? '',
      totalViews: map['totalViews'] ?? 0,
      uniqueViews: map['uniqueViews'] ?? 0,
      averageViewDuration: (map['averageViewDuration'] ?? 0.0).toDouble(),
      bounceRate: (map['bounceRate'] ?? 0.0).toDouble(),
      newApplications: map['newApplications'] ?? 0,
      totalApplications: map['totalApplications'] ?? 0,
      applicationQualityScore: (map['applicationQualityScore'] ?? 0.0).toDouble(),
      viewToApplicationRate: (map['viewToApplicationRate'] ?? 0.0).toDouble(),
      applicationToResponseRate: (map['applicationToResponseRate'] ?? 0.0).toDouble(),
      searchRanking: map['searchRanking'] ?? 0,
      recommendationScore: (map['recommendationScore'] ?? 0.0).toDouble(),
      competitiveIndex: (map['competitiveIndex'] ?? 0.0).toDouble(),
      viewsByLocation: Map<String, int>.from(map['viewsByLocation'] ?? {}),
      viewsByHour: List<int>.from(map['viewsByHour'] ?? List.filled(24, 0)),
      peakViewingHours: List<String>.from(map['peakViewingHours'] ?? []),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Calculate engagement score based on view metrics
  double get engagementScore {
    if (totalViews == 0) return 0.0;
    final uniqueViewsRatio = uniqueViews / totalViews;
    final durationScore = (averageViewDuration / 60).clamp(0.0, 1.0); // normalize to 1 minute
    final bounceScore = (100 - bounceRate) / 100;

    return ((uniqueViewsRatio + durationScore + bounceScore) / 3) * 100;
  }

  /// Get most active viewing hour
  String get mostActiveHour {
    if (viewsByHour.isEmpty) return '12:00';
    final maxIndex = viewsByHour.indexOf(viewsByHour.reduce((a, b) => a > b ? a : b));
    return '${maxIndex.toString().padLeft(2, '0')}:00';
  }
}
