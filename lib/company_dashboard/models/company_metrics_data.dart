/// Company metrics data model for dashboard analytics
/// Provides comprehensive business metrics for Company dashboard widgets
class CompanyMetricsData {
  // Job metrics
  final int totalJobsPosted;
  final int activeJobs;
  final int completedJobs;
  final int draftJobs;
  final double averageJobValue;
  final double totalBudgetSpent;
  final double monthlyBudget;
  final double budgetRemaining;
  
  // Application metrics
  final int totalApplicationsReceived;
  final int pendingApplications;
  final int acceptedApplications;
  final int rejectedApplications;
  final double acceptanceRate;
  final double averageApplicationsPerJob;
  final double averageResponseTime; // hours
  
  // Guard metrics
  final int totalGuardsHired;
  final int activeGuards;
  final double averageGuardRating;
  final int repeatHires;
  final double repeatHireRate;
  final List<TopGuardData> topPerformingGuards;
  
  // Financial metrics
  final double monthlySpent;
  final double averageHourlyRate;
  final double costPerHire;
  final double returnOnInvestment;
  final List<MonthlySpendData> spendingHistory;
  
  // Performance metrics
  final double averageJobFillTime; // days
  final double jobCompletionRate;
  final double customerSatisfactionScore;
  final int totalJobViews;
  final double viewToApplicationRate;
  
  // Time-based metrics
  final DateTime lastUpdated;
  final DateTime periodStart;
  final DateTime periodEnd;
  
  const CompanyMetricsData({
    this.totalJobsPosted = 0,
    this.activeJobs = 0,
    this.completedJobs = 0,
    this.draftJobs = 0,
    this.averageJobValue = 0.0,
    this.totalBudgetSpent = 0.0,
    this.monthlyBudget = 0.0,
    this.budgetRemaining = 0.0,
    this.totalApplicationsReceived = 0,
    this.pendingApplications = 0,
    this.acceptedApplications = 0,
    this.rejectedApplications = 0,
    this.acceptanceRate = 0.0,
    this.averageApplicationsPerJob = 0.0,
    this.averageResponseTime = 0.0,
    this.totalGuardsHired = 0,
    this.activeGuards = 0,
    this.averageGuardRating = 0.0,
    this.repeatHires = 0,
    this.repeatHireRate = 0.0,
    this.topPerformingGuards = const [],
    this.monthlySpent = 0.0,
    this.averageHourlyRate = 0.0,
    this.costPerHire = 0.0,
    this.returnOnInvestment = 0.0,
    this.spendingHistory = const [],
    this.averageJobFillTime = 0.0,
    this.jobCompletionRate = 0.0,
    this.customerSatisfactionScore = 0.0,
    this.totalJobViews = 0,
    this.viewToApplicationRate = 0.0,
    required this.lastUpdated,
    required this.periodStart,
    required this.periodEnd,
  });
  
  /// Copy with method for updates
  CompanyMetricsData copyWith({
    int? totalJobsPosted,
    int? activeJobs,
    int? completedJobs,
    int? draftJobs,
    double? averageJobValue,
    double? totalBudgetSpent,
    double? monthlyBudget,
    double? budgetRemaining,
    int? totalApplicationsReceived,
    int? pendingApplications,
    int? acceptedApplications,
    int? rejectedApplications,
    double? acceptanceRate,
    double? averageApplicationsPerJob,
    double? averageResponseTime,
    int? totalGuardsHired,
    int? activeGuards,
    double? averageGuardRating,
    int? repeatHires,
    double? repeatHireRate,
    List<TopGuardData>? topPerformingGuards,
    double? monthlySpent,
    double? averageHourlyRate,
    double? costPerHire,
    double? returnOnInvestment,
    List<MonthlySpendData>? spendingHistory,
    double? averageJobFillTime,
    double? jobCompletionRate,
    double? customerSatisfactionScore,
    int? totalJobViews,
    double? viewToApplicationRate,
    DateTime? lastUpdated,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    return CompanyMetricsData(
      totalJobsPosted: totalJobsPosted ?? this.totalJobsPosted,
      activeJobs: activeJobs ?? this.activeJobs,
      completedJobs: completedJobs ?? this.completedJobs,
      draftJobs: draftJobs ?? this.draftJobs,
      averageJobValue: averageJobValue ?? this.averageJobValue,
      totalBudgetSpent: totalBudgetSpent ?? this.totalBudgetSpent,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      budgetRemaining: budgetRemaining ?? this.budgetRemaining,
      totalApplicationsReceived: totalApplicationsReceived ?? this.totalApplicationsReceived,
      pendingApplications: pendingApplications ?? this.pendingApplications,
      acceptedApplications: acceptedApplications ?? this.acceptedApplications,
      rejectedApplications: rejectedApplications ?? this.rejectedApplications,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      averageApplicationsPerJob: averageApplicationsPerJob ?? this.averageApplicationsPerJob,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      totalGuardsHired: totalGuardsHired ?? this.totalGuardsHired,
      activeGuards: activeGuards ?? this.activeGuards,
      averageGuardRating: averageGuardRating ?? this.averageGuardRating,
      repeatHires: repeatHires ?? this.repeatHires,
      repeatHireRate: repeatHireRate ?? this.repeatHireRate,
      topPerformingGuards: topPerformingGuards ?? this.topPerformingGuards,
      monthlySpent: monthlySpent ?? this.monthlySpent,
      averageHourlyRate: averageHourlyRate ?? this.averageHourlyRate,
      costPerHire: costPerHire ?? this.costPerHire,
      returnOnInvestment: returnOnInvestment ?? this.returnOnInvestment,
      spendingHistory: spendingHistory ?? this.spendingHistory,
      averageJobFillTime: averageJobFillTime ?? this.averageJobFillTime,
      jobCompletionRate: jobCompletionRate ?? this.jobCompletionRate,
      customerSatisfactionScore: customerSatisfactionScore ?? this.customerSatisfactionScore,
      totalJobViews: totalJobViews ?? this.totalJobViews,
      viewToApplicationRate: viewToApplicationRate ?? this.viewToApplicationRate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
    );
  }
}

/// Top performing guard data for metrics
class TopGuardData {
  final String guardId;
  final String guardName;
  final double rating;
  final int jobsCompleted;
  final double totalEarned;
  final String profileImageUrl;
  
  const TopGuardData({
    required this.guardId,
    required this.guardName,
    required this.rating,
    required this.jobsCompleted,
    required this.totalEarned,
    this.profileImageUrl = '',
  });
}

/// Monthly spending data for financial tracking
class MonthlySpendData {
  final DateTime month;
  final double amount;
  final int jobsPosted;
  final int guardsHired;
  
  const MonthlySpendData({
    required this.month,
    required this.amount,
    required this.jobsPosted,
    required this.guardsHired,
  });
}
