import 'package:flutter/material.dart';
import '../../unified_status_colors.dart';
import 'dart:math' as math;
import 'job_image_data.dart' as new_img;

/// Job posting data model for Company job management
/// Enhanced version of SecurityJobData with Company management perspective
/// Now includes AI-powered features and analytics metadata
class JobPostingData {
  final String jobId;
  final String companyId;
  final String title;
  final String description;
  final String location;
  final String postalCode;          // Dutch postal code validation
  final double? latitude;           // Location coordinates for team management
  final double? longitude;          // Location coordinates for team management
  final double hourlyRate;          // Euro currency
  final DateTime startDate;
  final DateTime endDate;
  final int? numberOfGuards;        // Number of guards required
  final JobUrgency? urgency;        // Job urgency level
  final List<String> requiredCertificates;
  final List<String> requiredSkills;
  final int minimumExperience;      // Years of experience required
  final JobPostingStatus status;
  final DateTime createdDate;
  final DateTime? lastModified;
  final int applicationsCount;
  final List<String> applicantIds;
  final bool isUrgent;
  final String contactMethod;       // email, phone, both
  final String? specialInstructions;
  final double? maxBudget;
  final JobType jobType;

  // Image & Media Management
  final JobImageData? imageData;
  final List<JobPhotoData> photos;
  final JobLocationVisualsData? locationVisuals;
  final List<new_img.JobImageData>? images; // Premium image upload support

  // AI-Powered Features
  final SmartPricingData? smartPricing;
  final List<GuardMatchSuggestion> suggestedGuards;
  final JobTemplateData? templateUsed;
  final ComplianceCheckResult? complianceCheck;

  // Analytics & Performance Tracking
  final JobAnalyticsData? analytics;
  final MarketPositioningData? marketPositioning;
  final PredictionData? predictions;

  // Enhanced Job Management
  final AutoRenewalSettings? autoRenewal;
  final EscalationSettings? escalationSettings;
  final List<JobModificationRecord> modificationHistory;
  
  const JobPostingData({
    required this.jobId,
    required this.companyId,
    required this.title,
    required this.description,
    required this.location,
    required this.postalCode,
    this.latitude,
    this.longitude,
    required this.hourlyRate,
    required this.startDate,
    required this.endDate,
    this.numberOfGuards,
    this.urgency,
    this.requiredCertificates = const [],
    this.requiredSkills = const [],
    this.minimumExperience = 0,
    this.status = JobPostingStatus.draft,
    required this.createdDate,
    this.lastModified,
    this.applicationsCount = 0,
    this.applicantIds = const [],
    this.isUrgent = false,
    this.contactMethod = 'email',
    this.specialInstructions,
    this.maxBudget,
    this.jobType = JobType.objectbeveiliging,
    // Image & Media Management
    this.imageData,
    this.photos = const [],
    this.locationVisuals,
    this.images,
    // AI-Powered Features
    this.smartPricing,
    this.suggestedGuards = const [],
    this.templateUsed,
    this.complianceCheck,
    // Analytics & Performance Tracking
    this.analytics,
    this.marketPositioning,
    this.predictions,
    // Enhanced Job Management
    this.autoRenewal,
    this.escalationSettings,
    this.modificationHistory = const [],
  });
  
  /// Copy with method for updates
  JobPostingData copyWith({
    String? jobId,
    String? companyId,
    String? title,
    String? description,
    String? location,
    String? postalCode,
    double? latitude,
    double? longitude,
    double? hourlyRate,
    DateTime? startDate,
    DateTime? endDate,
    int? numberOfGuards,
    JobUrgency? urgency,
    List<String>? requiredCertificates,
    List<String>? requiredSkills,
    int? minimumExperience,
    JobPostingStatus? status,
    DateTime? createdDate,
    DateTime? lastModified,
    int? applicationsCount,
    List<String>? applicantIds,
    bool? isUrgent,
    String? contactMethod,
    String? specialInstructions,
    double? maxBudget,
    JobType? jobType,
    // Image & Media Management
    JobImageData? imageData,
    List<JobPhotoData>? photos,
    JobLocationVisualsData? locationVisuals,
    List<new_img.JobImageData>? images,
    // AI-Powered Features
    SmartPricingData? smartPricing,
    List<GuardMatchSuggestion>? suggestedGuards,
    JobTemplateData? templateUsed,
    ComplianceCheckResult? complianceCheck,
    // Analytics & Performance Tracking
    JobAnalyticsData? analytics,
    MarketPositioningData? marketPositioning,
    PredictionData? predictions,
    // Enhanced Job Management
    AutoRenewalSettings? autoRenewal,
    EscalationSettings? escalationSettings,
    List<JobModificationRecord>? modificationHistory,
  }) {
    return JobPostingData(
      jobId: jobId ?? this.jobId,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      numberOfGuards: numberOfGuards ?? this.numberOfGuards,
      urgency: urgency ?? this.urgency,
      requiredCertificates: requiredCertificates ?? this.requiredCertificates,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      minimumExperience: minimumExperience ?? this.minimumExperience,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
      applicationsCount: applicationsCount ?? this.applicationsCount,
      applicantIds: applicantIds ?? this.applicantIds,
      isUrgent: isUrgent ?? this.isUrgent,
      contactMethod: contactMethod ?? this.contactMethod,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      maxBudget: maxBudget ?? this.maxBudget,
      jobType: jobType ?? this.jobType,
      // Image & Media Management
      imageData: imageData ?? this.imageData,
      photos: photos ?? this.photos,
      locationVisuals: locationVisuals ?? this.locationVisuals,
      images: images ?? this.images,
      // AI-Powered Features
      smartPricing: smartPricing ?? this.smartPricing,
      suggestedGuards: suggestedGuards ?? this.suggestedGuards,
      templateUsed: templateUsed ?? this.templateUsed,
      complianceCheck: complianceCheck ?? this.complianceCheck,
      // Analytics & Performance Tracking
      analytics: analytics ?? this.analytics,
      marketPositioning: marketPositioning ?? this.marketPositioning,
      predictions: predictions ?? this.predictions,
      // Enhanced Job Management
      autoRenewal: autoRenewal ?? this.autoRenewal,
      escalationSettings: escalationSettings ?? this.escalationSettings,
      modificationHistory: modificationHistory ?? this.modificationHistory,
    );
  }
  
  /// Calculate total job budget
  double get totalBudget {
    final duration = endDate.difference(startDate);
    final hours = duration.inHours;
    return hours * hourlyRate;
  }
  
  /// Check if job is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == JobPostingStatus.active && 
           now.isAfter(startDate) && 
           now.isBefore(endDate);
  }
  
  /// Get job duration in hours
  int get durationInHours {
    return endDate.difference(startDate).inHours;
  }

  /// Get job ID (alias for compatibility with team management)
  String get id => jobId;

  /// Create JobPostingData from Firestore document
  static JobPostingData fromFirestore(Map<String, dynamic> doc) {
    return JobPostingData(
      jobId: doc['jobId'] ?? '',
      companyId: doc['companyId'] ?? '',
      title: doc['title'] ?? '',
      description: doc['description'] ?? '',
      location: doc['location'] ?? '',
      postalCode: doc['postalCode'] ?? '',
      latitude: doc['latitude']?.toDouble(),
      longitude: doc['longitude']?.toDouble(),
      hourlyRate: (doc['hourlyRate'] ?? 0.0).toDouble(),
      startDate: doc['startDate']?.toDate() ?? DateTime.now(),
      endDate: doc['endDate']?.toDate() ?? DateTime.now(),
      numberOfGuards: doc['numberOfGuards']?.toInt(),
      urgency: doc['urgency'] != null
          ? JobUrgency.values.firstWhere(
              (e) => e.name == doc['urgency'],
              orElse: () => JobUrgency.medium,
            )
          : null,
      requiredCertificates: List<String>.from(doc['requiredCertificates'] ?? []),
      requiredSkills: List<String>.from(doc['requiredSkills'] ?? []),
      minimumExperience: doc['minimumExperience'] ?? 0,
      status: JobPostingStatus.values.firstWhere(
        (e) => e.name == (doc['status'] ?? 'draft'),
        orElse: () => JobPostingStatus.draft,
      ),
      createdDate: doc['createdDate']?.toDate() ?? DateTime.now(),
      lastModified: doc['lastModified']?.toDate(),
      applicationsCount: doc['applicationsCount'] ?? 0,
      applicantIds: List<String>.from(doc['applicantIds'] ?? []),
      isUrgent: doc['isUrgent'] ?? false,
      contactMethod: doc['contactMethod'] ?? 'email',
      specialInstructions: doc['specialInstructions'],
      maxBudget: doc['maxBudget']?.toDouble(),
      jobType: JobType.values.firstWhere(
        (e) => e.name == (doc['jobType'] ?? 'objectbeveiliging'),
        orElse: () => JobType.objectbeveiliging,
      ),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'companyId': companyId,
      'title': title,
      'description': description,
      'location': location,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'hourlyRate': hourlyRate,
      'startDate': startDate,
      'endDate': endDate,
      'numberOfGuards': numberOfGuards,
      'urgency': urgency?.name,
      'requiredCertificates': requiredCertificates,
      'requiredSkills': requiredSkills,
      'minimumExperience': minimumExperience,
      'status': status.name,
      'createdDate': createdDate,
      'lastModified': lastModified,
      'applicationsCount': applicationsCount,
      'applicantIds': applicantIds,
      'isUrgent': isUrgent,
      'contactMethod': contactMethod,
      'specialInstructions': specialInstructions,
      'maxBudget': maxBudget,
      'jobType': jobType.name,
      // Image data stored separately for performance
      'hasImages': photos.isNotEmpty,
      'imageCount': photos.length,
      'featuredImageUrl': imageData?.featuredImageUrl,
    };
  }

  /// Check if job has visual content
  bool get hasVisualContent => 
    photos.isNotEmpty || imageData?.featuredImageUrl != null;

  /// Get primary image for job listing
  String? get primaryImageUrl => imageData?.featuredImageUrl;

  /// Get thumbnail for job card
  String? get thumbnailUrl => imageData?.thumbnailUrl;
}

/// Job posting status enumeration
enum JobPostingStatus {
  draft,       // Concept
  active,      // Actief
  filled,      // Vervuld
  cancelled,   // Geannuleerd
  completed,   // Voltooid
  expired,     // Verlopen
}

/// Job type enumeration for security services
enum JobType {
  objectbeveiliging,    // Object Security
  evenementbeveiliging, // Event Security
  persoonbeveiliging,   // Personal Security
  surveillance,         // Mobile Surveillance
  receptie,            // Reception Security
  transport,           // Transport Security
}

/// Job urgency enumeration for team management
enum JobUrgency {
  low,      // Laag
  medium,   // Gemiddeld
  high,     // Hoog
  urgent,   // Urgent
}

/// Extensions for Dutch display names
extension JobPostingStatusExtension on JobPostingStatus {
  String get displayName {
    switch (this) {
      case JobPostingStatus.draft:
        return 'Concept';
      case JobPostingStatus.active:
        return 'Actief';
      case JobPostingStatus.filled:
        return 'Vervuld';
      case JobPostingStatus.cancelled:
        return 'Geannuleerd';
      case JobPostingStatus.completed:
        return 'Voltooid';
      case JobPostingStatus.expired:
        return 'Verlopen';
    }
  }
  
  /// Get status color for UI (unified system)
  Color get statusColor {
    return StatusColorHelper.getJobPostingStatusColor(this);
  }
}

extension JobTypeExtension on JobType {
  String get displayName {
    switch (this) {
      case JobType.objectbeveiliging:
        return 'Objectbeveiliging';
      case JobType.evenementbeveiliging:
        return 'Evenementbeveiliging';
      case JobType.persoonbeveiliging:
        return 'Persoonbeveiliging';
      case JobType.surveillance:
        return 'Mobiele Surveillance';
      case JobType.receptie:
        return 'Receptiebeveiliging';
      case JobType.transport:
        return 'Transportbeveiliging';
    }
  }
}

// ============================================================================
// AI-POWERED FEATURES DATA MODELS
// ============================================================================

/// Smart pricing data with AI-powered rate recommendations
class SmartPricingData {
  final double recommendedRate;
  final double marketAverageRate;
  final double competitiveRate;
  final double premiumRate;
  final PricingConfidence confidence;
  final List<PricingFactor> factors;
  final MarketDemandData demandData;
  final DateTime calculatedAt;

  const SmartPricingData({
    required this.recommendedRate,
    required this.marketAverageRate,
    required this.competitiveRate,
    required this.premiumRate,
    required this.confidence,
    required this.factors,
    required this.demandData,
    required this.calculatedAt,
  });
}

/// Pricing confidence levels
enum PricingConfidence { low, medium, high, veryHigh }

/// Factors affecting pricing recommendations
class PricingFactor {
  final String name;
  final double impact; // -1.0 to 1.0
  final String description;

  const PricingFactor({
    required this.name,
    required this.impact,
    required this.description,
  });
}

/// Market demand data for pricing
class MarketDemandData {
  final double demandScore; // 0.0 to 1.0
  final int competingJobs;
  final int availableGuards;
  final double supplyDemandRatio;
  final List<String> peakHours;

  const MarketDemandData({
    required this.demandScore,
    required this.competingJobs,
    required this.availableGuards,
    required this.supplyDemandRatio,
    required this.peakHours,
  });
}

/// Guard match suggestion with AI-powered matching
class GuardMatchSuggestion {
  final String guardId;
  final String guardName;
  final double matchPercentage;
  final double rating;
  final int completedJobs;
  final double distanceKm;
  final List<String> matchingSkills;
  final List<String> matchingCertificates;
  final GuardAvailabilityStatus availability;
  final double hourlyRate;
  final String profileImageUrl;
  final List<MatchReason> matchReasons;

  const GuardMatchSuggestion({
    required this.guardId,
    required this.guardName,
    required this.matchPercentage,
    required this.rating,
    required this.completedJobs,
    required this.distanceKm,
    required this.matchingSkills,
    required this.matchingCertificates,
    required this.availability,
    required this.hourlyRate,
    required this.profileImageUrl,
    required this.matchReasons,
  });
}

/// Reasons for guard matching
class MatchReason {
  final String reason;
  final double weight;
  final MatchReasonType type;

  const MatchReason({
    required this.reason,
    required this.weight,
    required this.type,
  });
}

enum MatchReasonType { skill, experience, location, rating, availability, cost }

/// Guard availability status for matching
enum GuardAvailabilityStatus { available, busy, unavailable, onDuty }

/// Job template data for quick posting
class JobTemplateData {
  final String templateId;
  final String templateName;
  final String category;
  final String description;
  final List<String> defaultSkills;
  final List<String> defaultCertificates;
  final int defaultExperience;
  final double suggestedRate;
  final Map<String, dynamic> defaultSettings;
  final DateTime createdAt;
  final int usageCount;

  const JobTemplateData({
    required this.templateId,
    required this.templateName,
    required this.category,
    required this.description,
    required this.defaultSkills,
    required this.defaultCertificates,
    required this.defaultExperience,
    required this.suggestedRate,
    required this.defaultSettings,
    required this.createdAt,
    required this.usageCount,
  });
}

/// Compliance check result for job postings
class ComplianceCheckResult {
  final bool isCompliant;
  final List<ComplianceIssue> issues;
  final List<ComplianceWarning> warnings;
  final List<ComplianceSuggestion> suggestions;
  final DateTime checkedAt;
  final String checkedBy; // system or user

  const ComplianceCheckResult({
    required this.isCompliant,
    required this.issues,
    required this.warnings,
    required this.suggestions,
    required this.checkedAt,
    required this.checkedBy,
  });
}

/// Compliance issue types
class ComplianceIssue {
  final String issueId;
  final String title;
  final String description;
  final ComplianceSeverity severity;
  final String regulation;
  final String solution;

  const ComplianceIssue({
    required this.issueId,
    required this.title,
    required this.description,
    required this.severity,
    required this.regulation,
    required this.solution,
  });
}

class ComplianceWarning {
  final String warningId;
  final String title;
  final String description;
  final String recommendation;

  const ComplianceWarning({
    required this.warningId,
    required this.title,
    required this.description,
    required this.recommendation,
  });
}

class ComplianceSuggestion {
  final String suggestionId;
  final String title;
  final String description;
  final String benefit;

  const ComplianceSuggestion({
    required this.suggestionId,
    required this.title,
    required this.description,
    required this.benefit,
  });
}

enum ComplianceSeverity { low, medium, high, critical }

// ============================================================================
// ANALYTICS & PERFORMANCE TRACKING DATA MODELS
// ============================================================================

/// Job analytics data for performance tracking
class JobAnalyticsData {
  final int totalViews;
  final int uniqueViews;
  final int totalApplications;
  final double viewToApplicationRate;
  final double applicationToHireRate;
  final Duration averageTimeToFill;
  final double costPerHire;
  final double costPerApplication;
  final List<ViewAnalytics> viewHistory;
  final List<ApplicationAnalytics> applicationHistory;
  final DateTime lastUpdated;

  const JobAnalyticsData({
    required this.totalViews,
    required this.uniqueViews,
    required this.totalApplications,
    required this.viewToApplicationRate,
    required this.applicationToHireRate,
    required this.averageTimeToFill,
    required this.costPerHire,
    required this.costPerApplication,
    required this.viewHistory,
    required this.applicationHistory,
    required this.lastUpdated,
  });
}

/// View analytics for job postings
class ViewAnalytics {
  final DateTime timestamp;
  final String guardId;
  final String source; // search, recommendation, direct
  final Duration timeSpent;
  final bool resultedInApplication;

  const ViewAnalytics({
    required this.timestamp,
    required this.guardId,
    required this.source,
    required this.timeSpent,
    required this.resultedInApplication,
  });
}

/// Application analytics for job postings
class ApplicationAnalytics {
  final DateTime timestamp;
  final String guardId;
  final String source;
  final ApplicationQuality quality;
  final bool wasHired;
  final Duration responseTime;

  const ApplicationAnalytics({
    required this.timestamp,
    required this.guardId,
    required this.source,
    required this.quality,
    required this.wasHired,
    required this.responseTime,
  });
}

enum ApplicationQuality { poor, fair, good, excellent }

/// Market positioning data for competitive analysis
class MarketPositioningData {
  final double marketRank; // 0.0 to 1.0
  final double competitiveScore;
  final List<CompetitorAnalysis> competitors;
  final List<MarketInsight> insights;
  final PricingPosition pricingPosition;
  final QualityPosition qualityPosition;
  final DateTime analyzedAt;

  const MarketPositioningData({
    required this.marketRank,
    required this.competitiveScore,
    required this.competitors,
    required this.insights,
    required this.pricingPosition,
    required this.qualityPosition,
    required this.analyzedAt,
  });
}

/// Competitor analysis data
class CompetitorAnalysis {
  final String competitorId;
  final String competitorName;
  final double theirRate;
  final double theirRating;
  final int theirJobCount;
  final List<String> theirAdvantages;
  final List<String> ourAdvantages;

  const CompetitorAnalysis({
    required this.competitorId,
    required this.competitorName,
    required this.theirRate,
    required this.theirRating,
    required this.theirJobCount,
    required this.theirAdvantages,
    required this.ourAdvantages,
  });
}

/// Market insights for strategic decisions
class MarketInsight {
  final String insight;
  final String recommendation;
  final double impact; // 0.0 to 1.0
  final InsightType type;

  const MarketInsight({
    required this.insight,
    required this.recommendation,
    required this.impact,
    required this.type,
  });
}

enum InsightType { pricing, timing, skills, location, competition }
enum PricingPosition { budget, competitive, premium, luxury }
enum QualityPosition { basic, standard, premium, luxury }

/// Prediction data for job performance forecasting
class PredictionData {
  final int predictedApplications;
  final Duration predictedTimeToFill;
  final double predictedHireSuccess;
  final double confidenceScore;
  final List<PredictionFactor> factors;
  final List<ScenarioAnalysis> scenarios;
  final DateTime predictedAt;

  const PredictionData({
    required this.predictedApplications,
    required this.predictedTimeToFill,
    required this.predictedHireSuccess,
    required this.confidenceScore,
    required this.factors,
    required this.scenarios,
    required this.predictedAt,
  });
}

/// Factors affecting predictions
class PredictionFactor {
  final String factor;
  final double weight;
  final String explanation;

  const PredictionFactor({
    required this.factor,
    required this.weight,
    required this.explanation,
  });
}

/// Scenario analysis for different outcomes
class ScenarioAnalysis {
  final String scenario;
  final double probability;
  final Map<String, dynamic> outcomes;
  final List<String> recommendations;

  const ScenarioAnalysis({
    required this.scenario,
    required this.probability,
    required this.outcomes,
    required this.recommendations,
  });
}

// ============================================================================
// ENHANCED JOB MANAGEMENT DATA MODELS
// ============================================================================

/// Auto-renewal settings for recurring jobs
class AutoRenewalSettings {
  final bool isEnabled;
  final RenewalFrequency frequency;
  final int maxRenewals;
  final int currentRenewals;
  final DateTime nextRenewalDate;
  final bool requiresApproval;
  final List<String> notificationEmails;
  final Map<String, dynamic> renewalModifications;

  const AutoRenewalSettings({
    required this.isEnabled,
    required this.frequency,
    required this.maxRenewals,
    required this.currentRenewals,
    required this.nextRenewalDate,
    required this.requiresApproval,
    required this.notificationEmails,
    required this.renewalModifications,
  });
}

enum RenewalFrequency { daily, weekly, monthly, quarterly, yearly }

/// Escalation settings for unfilled jobs
class EscalationSettings {
  final bool isEnabled;
  final Duration warningThreshold;
  final Duration escalationThreshold;
  final List<EscalationAction> actions;
  final List<String> notificationContacts;
  final EscalationStatus currentStatus;

  const EscalationSettings({
    required this.isEnabled,
    required this.warningThreshold,
    required this.escalationThreshold,
    required this.actions,
    required this.notificationContacts,
    required this.currentStatus,
  });
}

/// Escalation actions to take
class EscalationAction {
  final EscalationActionType type;
  final Map<String, dynamic> parameters;
  final bool isCompleted;
  final DateTime? completedAt;

  const EscalationAction({
    required this.type,
    required this.parameters,
    required this.isCompleted,
    this.completedAt,
  });
}

enum EscalationActionType {
  increaseRate,
  broadenRequirements,
  notifyManager,
  contactAgency,
  markUrgent,
  extendDeadline
}

enum EscalationStatus { none, warning, escalated, resolved }

/// Job modification record for audit trail
class JobModificationRecord {
  final String modificationId;
  final DateTime timestamp;
  final String modifiedBy;
  final String modificationType;
  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;
  final String reason;
  final bool requiresClientApproval;
  final bool clientApproved;
  final DateTime? clientApprovedAt;

  const JobModificationRecord({
    required this.modificationId,
    required this.timestamp,
    required this.modifiedBy,
    required this.modificationType,
    required this.oldValues,
    required this.newValues,
    required this.reason,
    required this.requiresClientApproval,
    required this.clientApproved,
    this.clientApprovedAt,
  });
}

// ============================================================================
// JOB IMAGE & VISUAL CONTENT DATA MODELS - OPTIE 1: PREMIUM ENTERPRISE
// ============================================================================

/// Comprehensive job image management data
class JobImageData {
  final String? featuredImageUrl;
  final String? featuredImageId;
  final String? thumbnailUrl;
  final String? thumbnailId;
  final Map<String, String> responsiveImages; // size -> url mapping
  final ImageMetadata? metadata;
  final DateTime? uploadedAt;
  final String? uploadedBy;
  final bool isProcessed;
  final ImageProcessingStatus processingStatus;
  final List<String> tags;
  final ImageAnalysisData? analysis;

  const JobImageData({
    this.featuredImageUrl,
    this.featuredImageId,
    this.thumbnailUrl,
    this.thumbnailId,
    this.responsiveImages = const {},
    this.metadata,
    this.uploadedAt,
    this.uploadedBy,
    this.isProcessed = false,
    this.processingStatus = ImageProcessingStatus.pending,
    this.tags = const [],
    this.analysis,
  });

  factory JobImageData.fromFirestore(Map<String, dynamic> data) {
    return JobImageData(
      featuredImageUrl: data['featuredImageUrl'],
      featuredImageId: data['featuredImageId'],
      thumbnailUrl: data['thumbnailUrl'],
      thumbnailId: data['thumbnailId'],
      responsiveImages: Map<String, String>.from(data['responsiveImages'] ?? {}),
      uploadedAt: data['uploadedAt']?.toDate(),
      uploadedBy: data['uploadedBy'],
      isProcessed: data['isProcessed'] ?? false,
      processingStatus: ImageProcessingStatus.values.firstWhere(
        (status) => status.name == (data['processingStatus'] ?? 'pending'),
        orElse: () => ImageProcessingStatus.pending,
      ),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'featuredImageUrl': featuredImageUrl,
      'featuredImageId': featuredImageId,
      'thumbnailUrl': thumbnailUrl,
      'thumbnailId': thumbnailId,
      'responsiveImages': responsiveImages,
      'uploadedAt': uploadedAt,
      'uploadedBy': uploadedBy,
      'isProcessed': isProcessed,
      'processingStatus': processingStatus.name,
      'tags': tags,
    };
  }
}

/// Individual photo data for job galleries
class JobPhotoData {
  final String photoId;
  final String originalUrl;
  final String thumbnailUrl;
  final Map<String, String> sizes; // sm, md, lg, xl urls
  final ImageMetadata metadata;
  final DateTime uploadedAt;
  final String uploadedBy;
  final PhotoType type;
  final List<String> tags;
  final int sortOrder;
  final bool isPublic;
  final ImageAnalysisData? analysis;
  final LocationPhotoData? locationData;

  const JobPhotoData({
    required this.photoId,
    required this.originalUrl,
    required this.thumbnailUrl,
    required this.sizes,
    required this.metadata,
    required this.uploadedAt,
    required this.uploadedBy,
    required this.type,
    this.tags = const [],
    this.sortOrder = 0,
    this.isPublic = true,
    this.analysis,
    this.locationData,
  });
}

/// Photo metadata for EXIF and processing info
class ImageMetadata {
  final int width;
  final int height;
  final int fileSize;
  final String format;
  final double? latitude;
  final double? longitude;
  final DateTime? dateTaken;
  final String? cameraModel;
  final Map<String, dynamic> exifData;
  final bool isOptimized;
  final int? compressionQuality;

  const ImageMetadata({
    required this.width,
    required this.height,
    required this.fileSize,
    required this.format,
    this.latitude,
    this.longitude,
    this.dateTaken,
    this.cameraModel,
    this.exifData = const {},
    this.isOptimized = false,
    this.compressionQuality,
  });

  factory ImageMetadata.fromMap(Map<String, dynamic> data) {
    return ImageMetadata(
      width: data['width'] ?? 0,
      height: data['height'] ?? 0,
      fileSize: data['fileSize'] ?? 0,
      format: data['format'] ?? 'unknown',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      dateTaken: data['dateTaken']?.toDate(),
      cameraModel: data['cameraModel'],
      exifData: Map<String, dynamic>.from(data['exifData'] ?? {}),
      isOptimized: data['isOptimized'] ?? false,
      compressionQuality: data['compressionQuality'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      'fileSize': fileSize,
      'format': format,
      'latitude': latitude,
      'longitude': longitude,
      'dateTaken': dateTaken,
      'cameraModel': cameraModel,
      'exifData': exifData,
      'isOptimized': isOptimized,
      'compressionQuality': compressionQuality,
    };
  }
}

// Enums for image types
enum ImageProcessingStatus { pending, processing, completed, failed }
enum PhotoType { location, uniform, equipment, certificate, floorplan, other }
enum LocationPhotoType { exterior, interior, entrance, parking, security_post }

/// AI-powered image analysis data
class ImageAnalysisData {
  final List<String> detectedObjects;
  final List<String> detectedText;
  final ImageQualityScore qualityScore;
  final LocationType? detectedLocationType;
  final SecurityRelevanceScore securityRelevance;
  final List<String> suggestedTags;
  final DateTime analyzedAt;

  const ImageAnalysisData({
    required this.detectedObjects,
    required this.detectedText,
    required this.qualityScore,
    this.detectedLocationType,
    required this.securityRelevance,
    required this.suggestedTags,
    required this.analyzedAt,
  });
}

/// Location-specific photo data
class LocationPhotoData {
  final double? latitude;
  final double? longitude;
  final String? address;
  final LocationPhotoType type;
  final String? description;
  final List<String> accessNotes;

  const LocationPhotoData({
    this.latitude,
    this.longitude,
    this.address,
    required this.type,
    this.description,
    this.accessNotes = const [],
  });
}

enum LocationType { office, retail, warehouse, event_venue, residential, industrial }

/// Image quality scoring
class ImageQualityScore {
  final double overall; // 0.0 to 1.0
  final double sharpness;
  final double brightness;
  final double contrast;
  final double composition;
  
  const ImageQualityScore({
    required this.overall,
    required this.sharpness,
    required this.brightness,
    required this.contrast,
    required this.composition,
  });
}

/// Security relevance scoring for job images
class SecurityRelevanceScore {
  final double relevance; // 0.0 to 1.0
  final List<String> relevantFeatures;
  final List<String> securityConcerns;
  
  const SecurityRelevanceScore({
    required this.relevance,
    required this.relevantFeatures,
    required this.securityConcerns,
  });
}

/// Location visuals data for comprehensive job presentation
class JobLocationVisualsData {
  final List<LocationPhotoData> exteriorPhotos;
  final List<LocationPhotoData> interiorPhotos;
  final List<LocationPhotoData> accessPhotos;
  final String? virtualTourUrl;
  final DateTime lastUpdated;

  const JobLocationVisualsData({
    this.exteriorPhotos = const [],
    this.interiorPhotos = const [],
    this.accessPhotos = const [],
    this.virtualTourUrl,
    required this.lastUpdated,
  });
}
