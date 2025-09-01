
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart' show GuardAvailabilityStatus;

/// Guard performance analytics data
class GuardPerformanceData {
  final String guardId;
  final String guardName;
  final double rating;
  final int totalJobsCompleted;
  final int jobsThisMonth;
  final double reliabilityScore; // 0-100
  final double clientSatisfactionScore; // 0-5
  final double averageResponseTime; // hours
  final double revenueGenerated;
  final int noShowCount;
  final int emergencyResponseCount;
  final List<String> specializations;
  final DateTime lastActiveDate;
  final bool isCurrentlyActive;
  final String currentLocation;
  final GuardAvailabilityStatus availabilityStatus;

  const GuardPerformanceData({
    required this.guardId,
    required this.guardName,
    this.rating = 0.0,
    this.totalJobsCompleted = 0,
    this.jobsThisMonth = 0,
    this.reliabilityScore = 0.0,
    this.clientSatisfactionScore = 0.0,
    this.averageResponseTime = 0.0,
    this.revenueGenerated = 0.0,
    this.noShowCount = 0,
    this.emergencyResponseCount = 0,
    this.specializations = const [],
    required this.lastActiveDate,
    this.isCurrentlyActive = false,
    this.currentLocation = '',
    this.availabilityStatus = GuardAvailabilityStatus.unavailable,
  });

  GuardPerformanceData copyWith({
    String? guardId,
    String? guardName,
    double? rating,
    int? totalJobsCompleted,
    int? jobsThisMonth,
    double? reliabilityScore,
    double? clientSatisfactionScore,
    double? averageResponseTime,
    double? revenueGenerated,
    int? noShowCount,
    int? emergencyResponseCount,
    List<String>? specializations,
    DateTime? lastActiveDate,
    bool? isCurrentlyActive,
    String? currentLocation,
    GuardAvailabilityStatus? availabilityStatus,
  }) {
    return GuardPerformanceData(
      guardId: guardId ?? this.guardId,
      guardName: guardName ?? this.guardName,
      rating: rating ?? this.rating,
      totalJobsCompleted: totalJobsCompleted ?? this.totalJobsCompleted,
      jobsThisMonth: jobsThisMonth ?? this.jobsThisMonth,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      clientSatisfactionScore: clientSatisfactionScore ?? this.clientSatisfactionScore,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      revenueGenerated: revenueGenerated ?? this.revenueGenerated,
      noShowCount: noShowCount ?? this.noShowCount,
      emergencyResponseCount: emergencyResponseCount ?? this.emergencyResponseCount,
      specializations: specializations ?? this.specializations,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      isCurrentlyActive: isCurrentlyActive ?? this.isCurrentlyActive,
      currentLocation: currentLocation ?? this.currentLocation,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
    );
  }
}

// GuardAvailabilityStatus moved to job_posting_data.dart to avoid conflicts

/// Client satisfaction analytics data
class ClientSatisfactionData {
  final String clientId;
  final String clientName;
  final double netPromoterScore; // -100 to 100
  final double averageRating; // 0-5
  final int totalFeedbackCount;
  final int positiveReviews;
  final int neutralReviews;
  final int negativeReviews;
  final double retentionProbability; // 0-100
  final List<String> commonComplaints;
  final List<String> commonPraises;
  final DateTime lastFeedbackDate;
  final double responseTime; // hours to resolve issues
  final int totalJobsCompleted;
  final double totalSpent;
  final ClientRiskLevel riskLevel;

  const ClientSatisfactionData({
    required this.clientId,
    required this.clientName,
    this.netPromoterScore = 0.0,
    this.averageRating = 0.0,
    this.totalFeedbackCount = 0,
    this.positiveReviews = 0,
    this.neutralReviews = 0,
    this.negativeReviews = 0,
    this.retentionProbability = 0.0,
    this.commonComplaints = const [],
    this.commonPraises = const [],
    required this.lastFeedbackDate,
    this.responseTime = 0.0,
    this.totalJobsCompleted = 0,
    this.totalSpent = 0.0,
    this.riskLevel = ClientRiskLevel.low,
  });
}

/// Client risk level for retention analysis
enum ClientRiskLevel {
  low,
  medium,
  high,
  critical
}

/// Revenue analytics data with forecasting
class RevenueAnalyticsData {
  final double currentMonthRevenue;
  final double previousMonthRevenue;
  final double monthlyGrowthRate; // percentage
  final double projectedRevenue30Days;
  final double projectedRevenue60Days;
  final double projectedRevenue90Days;
  final double averageJobValue;
  final double profitMargin; // percentage
  final double costPerAcquisition;
  final double lifetimeValue;
  final List<MonthlyRevenueData> revenueHistory;
  final List<RevenueByServiceType> revenueByService;
  final List<SeasonalTrendData> seasonalTrends;
  final DateTime lastUpdated;

  const RevenueAnalyticsData({
    this.currentMonthRevenue = 0.0,
    this.previousMonthRevenue = 0.0,
    this.monthlyGrowthRate = 0.0,
    this.projectedRevenue30Days = 0.0,
    this.projectedRevenue60Days = 0.0,
    this.projectedRevenue90Days = 0.0,
    this.averageJobValue = 0.0,
    this.profitMargin = 0.0,
    this.costPerAcquisition = 0.0,
    this.lifetimeValue = 0.0,
    this.revenueHistory = const [],
    this.revenueByService = const [],
    this.seasonalTrends = const [],
    required this.lastUpdated,
  });
}

/// Monthly revenue data for historical analysis
class MonthlyRevenueData {
  final DateTime month;
  final double revenue;
  final double profit;
  final int jobsCompleted;

  const MonthlyRevenueData({
    required this.month,
    required this.revenue,
    required this.profit,
    required this.jobsCompleted,
  });
}

/// Revenue breakdown by service type
class RevenueByServiceType {
  final String serviceType;
  final double revenue;
  final double percentage;
  final int jobCount;

  const RevenueByServiceType({
    required this.serviceType,
    required this.revenue,
    required this.percentage,
    required this.jobCount,
  });
}

/// Seasonal trend data for demand forecasting
class SeasonalTrendData {
  final String period; // e.g., "Q1", "Summer", "December"
  final double demandMultiplier; // 1.0 = normal, >1.0 = high demand
  final List<String> popularServices;

  const SeasonalTrendData({
    required this.period,
    required this.demandMultiplier,
    required this.popularServices,
  });
}

/// Operational efficiency metrics
class OperationalMetricsData {
  final double guardUtilizationRate; // percentage
  final double averageJobFillTime; // hours
  final double emergencyResponseTime; // minutes
  final int totalIncidents;
  final int resolvedIncidents;
  final double incidentResolutionRate; // percentage
  final double qualityScore; // 0-100
  final int complianceViolations;
  final List<CertificateExpiryData> upcomingExpirations;
  final double resourceEfficiency; // percentage
  final DateTime lastUpdated;

  const OperationalMetricsData({
    this.guardUtilizationRate = 0.0,
    this.averageJobFillTime = 0.0,
    this.emergencyResponseTime = 0.0,
    this.totalIncidents = 0,
    this.resolvedIncidents = 0,
    this.incidentResolutionRate = 0.0,
    this.qualityScore = 0.0,
    this.complianceViolations = 0,
    this.upcomingExpirations = const [],
    this.resourceEfficiency = 0.0,
    required this.lastUpdated,
  });
}

/// Certificate expiry tracking for compliance
class CertificateExpiryData {
  final String guardId;
  final String guardName;
  final String certificateType;
  final DateTime expiryDate;
  final int daysUntilExpiry;
  final CertificateUrgency urgency;

  const CertificateExpiryData({
    required this.guardId,
    required this.guardName,
    required this.certificateType,
    required this.expiryDate,
    required this.daysUntilExpiry,
    required this.urgency,
  });
}

/// Certificate expiry urgency levels
enum CertificateUrgency {
  normal,    // >30 days
  warning,   // 15-30 days
  urgent,    // 7-15 days
  critical   // <7 days
}

/// Real-time dashboard metrics aggregation
class LiveDashboardMetrics {
  final int activeGuards;
  final int availableGuards;
  final int ongoingJobs;
  final int emergencyAlerts;
  final double currentDayRevenue;
  final double averageClientSatisfaction;
  final int pendingApplications;
  final int complianceIssues;
  final DateTime lastUpdated;

  const LiveDashboardMetrics({
    this.activeGuards = 0,
    this.availableGuards = 0,
    this.ongoingJobs = 0,
    this.emergencyAlerts = 0,
    this.currentDayRevenue = 0.0,
    this.averageClientSatisfaction = 0.0,
    this.pendingApplications = 0,
    this.complianceIssues = 0,
    required this.lastUpdated,
  });
}
