import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive review model for two-way review system
/// Supports both guard-to-company and company-to-guard reviews
/// Dutch localization and compliance built-in
class ComprehensiveJobReview extends Equatable {
  final String id;
  final String workflowId;
  final String jobId;
  final String reviewerId;
  final String revieweeId;
  final ReviewerType reviewerType;
  
  // Multi-dimensional ratings
  final ReviewCategories categories;
  final double overallRating;
  final String? comment;
  final List<String> tags;
  
  // Timing and validation
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? shiftDate;
  final ReviewStatus status;
  final bool isVerified;
  
  // Privacy and moderation
  final bool isPublic;
  final bool isAnonymous;
  final ModerationStatus moderationStatus;
  
  // Response mechanism
  final String? responseText;
  final DateTime? responseDate;
  
  // Company specific fields (when guard reviews company)
  final CompanyReviewFields? companyFields;
  
  // Guard specific fields (when company reviews guard)
  final GuardReviewFields? guardFields;

  const ComprehensiveJobReview({
    required this.id,
    required this.workflowId,
    required this.jobId,
    required this.reviewerId,
    required this.revieweeId,
    required this.reviewerType,
    required this.categories,
    required this.overallRating,
    this.comment,
    this.tags = const [],
    required this.createdAt,
    this.editedAt,
    this.shiftDate,
    this.status = ReviewStatus.active,
    this.isVerified = false,
    this.isPublic = true,
    this.isAnonymous = false,
    this.moderationStatus = ModerationStatus.pending,
    this.responseText,
    this.responseDate,
    this.companyFields,
    this.guardFields,
  });

  factory ComprehensiveJobReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComprehensiveJobReview(
      id: doc.id,
      workflowId: data['workflowId'] ?? '',
      jobId: data['jobId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      revieweeId: data['revieweeId'] ?? '',
      reviewerType: ReviewerType.fromString(data['reviewerType'] ?? 'guard'),
      categories: ReviewCategories.fromMap(data['categories'] ?? {}),
      overallRating: (data['overallRating'] ?? 0).toDouble(),
      comment: data['comment'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      editedAt: data['editedAt'] != null 
          ? (data['editedAt'] as Timestamp).toDate() 
          : null,
      shiftDate: data['shiftDate'] != null
          ? (data['shiftDate'] as Timestamp).toDate()
          : null,
      status: ReviewStatus.fromString(data['status'] ?? 'active'),
      isVerified: data['isVerified'] ?? false,
      isPublic: data['isPublic'] ?? true,
      isAnonymous: data['isAnonymous'] ?? false,
      moderationStatus: ModerationStatus.fromString(
          data['moderationStatus'] ?? 'pending'),
      responseText: data['responseText'],
      responseDate: data['responseDate'] != null
          ? (data['responseDate'] as Timestamp).toDate()
          : null,
      companyFields: data['companyFields'] != null
          ? CompanyReviewFields.fromMap(data['companyFields'])
          : null,
      guardFields: data['guardFields'] != null
          ? GuardReviewFields.fromMap(data['guardFields'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workflowId': workflowId,
      'jobId': jobId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'reviewerType': reviewerType.value,
      'categories': categories.toMap(),
      'overallRating': overallRating,
      'comment': comment,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'shiftDate': shiftDate != null ? Timestamp.fromDate(shiftDate!) : null,
      'status': status.value,
      'isVerified': isVerified,
      'isPublic': isPublic,
      'isAnonymous': isAnonymous,
      'moderationStatus': moderationStatus.value,
      'responseText': responseText,
      'responseDate': responseDate != null 
          ? Timestamp.fromDate(responseDate!) 
          : null,
      'companyFields': companyFields?.toMap(),
      'guardFields': guardFields?.toMap(),
    };
  }

  /// Check if review is within edit window (24 hours)
  bool get canEdit {
    if (editedAt != null) return false; // Already edited once
    return DateTime.now().difference(createdAt).inHours < 24;
  }

  /// Check if review can receive a response
  bool get canRespond {
    return responseText == null && status == ReviewStatus.active;
  }

  ComprehensiveJobReview copyWith({
    String? comment,
    ReviewCategories? categories,
    double? overallRating,
    List<String>? tags,
    DateTime? editedAt,
    ReviewStatus? status,
    ModerationStatus? moderationStatus,
    String? responseText,
    DateTime? responseDate,
  }) {
    return ComprehensiveJobReview(
      id: id,
      workflowId: workflowId,
      jobId: jobId,
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      reviewerType: reviewerType,
      categories: categories ?? this.categories,
      overallRating: overallRating ?? this.overallRating,
      comment: comment ?? this.comment,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      editedAt: editedAt ?? this.editedAt,
      shiftDate: shiftDate,
      status: status ?? this.status,
      isVerified: isVerified,
      isPublic: isPublic,
      isAnonymous: isAnonymous,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      responseText: responseText ?? this.responseText,
      responseDate: responseDate ?? this.responseDate,
      companyFields: companyFields,
      guardFields: guardFields,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workflowId,
        reviewerId,
        revieweeId,
        overallRating,
        createdAt,
      ];
}

/// Review categories with Dutch labels
class ReviewCategories extends Equatable {
  final double communication;      // Communicatie
  final double professionalism;    // Professionaliteit
  final double reliability;        // Betrouwbaarheid
  final double safety;             // Veiligheid
  final double workQuality;        // Werkkwaliteit
  
  const ReviewCategories({
    required this.communication,
    required this.professionalism,
    required this.reliability,
    required this.safety,
    required this.workQuality,
  });

  factory ReviewCategories.empty() {
    return const ReviewCategories(
      communication: 0,
      professionalism: 0,
      reliability: 0,
      safety: 0,
      workQuality: 0,
    );
  }

  factory ReviewCategories.fromMap(Map<String, dynamic> map) {
    return ReviewCategories(
      communication: (map['communication'] ?? 0).toDouble(),
      professionalism: (map['professionalism'] ?? 0).toDouble(),
      reliability: (map['reliability'] ?? 0).toDouble(),
      safety: (map['safety'] ?? 0).toDouble(),
      workQuality: (map['workQuality'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communication': communication,
      'professionalism': professionalism,
      'reliability': reliability,
      'safety': safety,
      'workQuality': workQuality,
    };
  }

  double get averageRating {
    final ratings = [communication, professionalism, reliability, safety, workQuality];
    final validRatings = ratings.where((r) => r > 0).toList();
    if (validRatings.isEmpty) return 0;
    return validRatings.reduce((a, b) => a + b) / validRatings.length;
  }

  @override
  List<Object?> get props => [
        communication,
        professionalism,
        reliability,
        safety,
        workQuality,
      ];
}

/// Company-specific review fields (when guard reviews company)
class CompanyReviewFields extends Equatable {
  final double paymentTimeliness;  // Betalingssnelheid
  final double workEnvironment;    // Werkomgeving
  final double equipmentQuality;   // Kwaliteit uitrusting
  final double jobDescription;     // Opdracht beschrijving
  final bool wouldWorkAgain;       // Zou weer werken voor

  const CompanyReviewFields({
    required this.paymentTimeliness,
    required this.workEnvironment,
    required this.equipmentQuality,
    required this.jobDescription,
    required this.wouldWorkAgain,
  });

  factory CompanyReviewFields.fromMap(Map<String, dynamic> map) {
    return CompanyReviewFields(
      paymentTimeliness: (map['paymentTimeliness'] ?? 0).toDouble(),
      workEnvironment: (map['workEnvironment'] ?? 0).toDouble(),
      equipmentQuality: (map['equipmentQuality'] ?? 0).toDouble(),
      jobDescription: (map['jobDescription'] ?? 0).toDouble(),
      wouldWorkAgain: map['wouldWorkAgain'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentTimeliness': paymentTimeliness,
      'workEnvironment': workEnvironment,
      'equipmentQuality': equipmentQuality,
      'jobDescription': jobDescription,
      'wouldWorkAgain': wouldWorkAgain,
    };
  }

  @override
  List<Object?> get props => [
        paymentTimeliness,
        workEnvironment,
        equipmentQuality,
        jobDescription,
        wouldWorkAgain,
      ];
}

/// Guard-specific review fields (when company reviews guard)
class GuardReviewFields extends Equatable {
  final double punctuality;        // Stiptheid
  final double appearance;         // Presentatie
  final double followsInstructions; // Opvolgen instructies
  final double teamwork;           // Teamwerk
  final bool wouldHireAgain;      // Zou weer inhuren

  const GuardReviewFields({
    required this.punctuality,
    required this.appearance,
    required this.followsInstructions,
    required this.teamwork,
    required this.wouldHireAgain,
  });

  factory GuardReviewFields.fromMap(Map<String, dynamic> map) {
    return GuardReviewFields(
      punctuality: (map['punctuality'] ?? 0).toDouble(),
      appearance: (map['appearance'] ?? 0).toDouble(),
      followsInstructions: (map['followsInstructions'] ?? 0).toDouble(),
      teamwork: (map['teamwork'] ?? 0).toDouble(),
      wouldHireAgain: map['wouldHireAgain'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'punctuality': punctuality,
      'appearance': appearance,
      'followsInstructions': followsInstructions,
      'teamwork': teamwork,
      'wouldHireAgain': wouldHireAgain,
    };
  }

  @override
  List<Object?> get props => [
        punctuality,
        appearance,
        followsInstructions,
        teamwork,
        wouldHireAgain,
      ];
}

/// Review enums
enum ReviewerType {
  guard('guard'),
  company('company');

  final String value;
  const ReviewerType(this.value);

  static ReviewerType fromString(String value) {
    return ReviewerType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ReviewerType.guard,
    );
  }
}

enum ReviewStatus {
  active('active'),
  edited('edited'),
  deleted('deleted'),
  disputed('disputed');

  final String value;
  const ReviewStatus(this.value);

  static ReviewStatus fromString(String value) {
    return ReviewStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ReviewStatus.active,
    );
  }
}

enum ModerationStatus {
  pending('pending'),
  approved('approved'),
  flagged('flagged'),
  removed('removed');

  final String value;
  const ModerationStatus(this.value);

  static ModerationStatus fromString(String value) {
    return ModerationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ModerationStatus.pending,
    );
  }
}

/// Aggregated review statistics for users
class UserReviewStats extends Equatable {
  final String userId;
  final int totalReviews;
  final double averageRating;
  final ReviewCategories averageCategories;
  final Map<String, double> ratingDistribution;
  final int totalResponses;
  final DateTime? lastReviewDate;
  final List<String> topTags;
  final int verifiedReviews;

  const UserReviewStats({
    required this.userId,
    required this.totalReviews,
    required this.averageRating,
    required this.averageCategories,
    required this.ratingDistribution,
    required this.totalResponses,
    this.lastReviewDate,
    this.topTags = const [],
    this.verifiedReviews = 0,
  });

  factory UserReviewStats.empty(String userId) {
    return UserReviewStats(
      userId: userId,
      totalReviews: 0,
      averageRating: 0,
      averageCategories: ReviewCategories.empty(),
      ratingDistribution: {
        '5': 0,
        '4': 0,
        '3': 0,
        '2': 0,
        '1': 0,
      },
      totalResponses: 0,
      topTags: const [],
    );
  }

  @override
  List<Object?> get props => [
        userId,
        totalReviews,
        averageRating,
        lastReviewDate,
      ];
}