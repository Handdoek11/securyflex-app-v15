import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription tiers available in SecuryFlex
enum SubscriptionTier {
  zzpGuard('zzp_guard', 4.99, 'ZZP Beveiliger', 'Basis toegang voor zelfstandige beveiligers'),
  companyBasic('company_basic', 19.99, 'Bedrijf Basic', 'Voor kleine beveiligingsbedrijven (1-5 medewerkers)'),
  companyProfessional('company_professional', 39.99, 'Bedrijf Professional', 'Voor groeiende bedrijven (6-20 medewerkers)'),
  companyEnterprise('company_enterprise', 59.99, 'Bedrijf Enterprise', 'Voor grote organisaties (21+ medewerkers)'),
  clientUsage('client_usage', 2.99, 'Opdrachtgever', 'Per uur platform kosten voor opdrachtgevers');

  const SubscriptionTier(this.id, this.pricePerMonth, this.displayName, this.description);

  final String id;
  final double pricePerMonth;
  final String displayName;
  final String description;

  /// Get tier by ID
  static SubscriptionTier fromId(String id) {
    return SubscriptionTier.values.firstWhere(
      (tier) => tier.id == id,
      orElse: () => SubscriptionTier.zzpGuard,
    );
  }

  /// Calculate BTW inclusive price (21% Dutch VAT)
  double get priceWithBTW => pricePerMonth * 1.21;

  /// Get features available for this tier
  Map<String, bool> get features {
    switch (this) {
      case SubscriptionTier.zzpGuard:
        return {
          'job_applications': true,
          'max_applications_per_month': true, // 10
          'basic_chat': true,
          'certificate_management': true,
          'earnings_tracking': true,
          'shift_tracking': true,
          'profile_management': true,
          'basic_analytics': false,
          'advanced_analytics': false,
          'job_posting': false,
          'team_management': false,
          'priority_support': false,
          'api_access': false,
          'white_label': false,
        };
      case SubscriptionTier.companyBasic:
        return {
          'job_applications': false,
          'max_applications_per_month': false,
          'basic_chat': true,
          'certificate_management': false,
          'earnings_tracking': false,
          'shift_tracking': false,
          'profile_management': true,
          'basic_analytics': true,
          'advanced_analytics': false,
          'job_posting': true,
          'max_job_posts': true, // 50
          'team_management': true,
          'max_team_size': true, // 5
          'priority_support': false,
          'api_access': false,
          'white_label': false,
        };
      case SubscriptionTier.companyProfessional:
        return {
          'job_applications': false,
          'max_applications_per_month': false,
          'basic_chat': true,
          'certificate_management': false,
          'earnings_tracking': false,
          'shift_tracking': false,
          'profile_management': true,
          'basic_analytics': true,
          'advanced_analytics': true,
          'job_posting': true,
          'max_job_posts': false, // unlimited
          'team_management': true,
          'max_team_size': true, // 20
          'bulk_application_processing': true,
          'priority_support': true,
          'api_access': false,
          'white_label': false,
        };
      case SubscriptionTier.companyEnterprise:
        return {
          'job_applications': false,
          'max_applications_per_month': false,
          'basic_chat': true,
          'certificate_management': false,
          'earnings_tracking': false,
          'shift_tracking': false,
          'profile_management': true,
          'basic_analytics': true,
          'advanced_analytics': true,
          'job_posting': true,
          'max_job_posts': false, // unlimited
          'team_management': true,
          'max_team_size': false, // unlimited
          'bulk_application_processing': true,
          'priority_support': true,
          'api_access': true,
          'white_label': true,
          'custom_integrations': true,
          'dedicated_support': true,
        };
      case SubscriptionTier.clientUsage:
        return {
          'job_posting': true,
          'guard_verification': true,
          'payment_processing': true,
          'quality_assurance': true,
          'real_time_tracking': true,
          'invoice_management': true,
          'dispute_resolution': true,
        };
    }
  }

  /// Get usage limits for this tier
  Map<String, int?> get limits {
    switch (this) {
      case SubscriptionTier.zzpGuard:
        return {
          'max_applications_per_month': 10,
          'max_active_applications': 5,
          'max_saved_jobs': 50,
        };
      case SubscriptionTier.companyBasic:
        return {
          'max_job_posts': 50,
          'max_team_size': 5,
          'max_active_jobs': 10,
        };
      case SubscriptionTier.companyProfessional:
        return {
          'max_job_posts': null, // unlimited
          'max_team_size': 20,
          'max_active_jobs': null, // unlimited
        };
      case SubscriptionTier.companyEnterprise:
        return {
          'max_job_posts': null, // unlimited
          'max_team_size': null, // unlimited
          'max_active_jobs': null, // unlimited
        };
      case SubscriptionTier.clientUsage:
        return {
          'max_concurrent_jobs': 10,
          'max_monthly_hours': null, // pay per use
        };
    }
  }

  /// Whether this tier offers a trial period
  bool get hasTrialPeriod {
    switch (this) {
      case SubscriptionTier.zzpGuard:
        return true; // 30 days free trial
      case SubscriptionTier.companyBasic:
      case SubscriptionTier.companyProfessional:
      case SubscriptionTier.companyEnterprise:
        return false; // No trial for company tiers
      case SubscriptionTier.clientUsage:
        return false; // Pay per use
    }
  }
}

/// Current status of a subscription
enum SubscriptionStatus {
  trialing('trialing', 'Proefperiode'),
  active('active', 'Actief'),
  pastDue('past_due', 'Betaling achterstallig'),
  canceled('canceled', 'Geannuleerd'),
  unpaid('unpaid', 'Onbetaald'),
  incomplete('incomplete', 'Incompleet'),
  expired('expired', 'Verlopen');

  const SubscriptionStatus(this.id, this.displayName);

  final String id;
  final String displayName;

  static SubscriptionStatus fromId(String id) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.id == id,
      orElse: () => SubscriptionStatus.incomplete,
    );
  }

  bool get isActive => this == SubscriptionStatus.active || this == SubscriptionStatus.trialing;
  bool get requiresPayment => this == SubscriptionStatus.pastDue || this == SubscriptionStatus.unpaid;
}

/// Main subscription model
class Subscription {
  final String id;
  final String userId;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? trialEndDate;
  final double monthlyPrice;
  final String currency;
  final Map<String, bool> features;
  final Map<String, int?> limits;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Dutch compliance fields
  final bool isBtwExempt;
  final double btwRate;
  final String? btwNumber;
  final String? companyName;
  final String? kvkNumber;

  // Payment information
  final String? paymentMethodId;
  final String? lastPaymentId;
  final DateTime? lastPaymentDate;
  final DateTime? nextPaymentDate;

  const Subscription({
    required this.id,
    required this.userId,
    required this.tier,
    required this.status,
    required this.startDate,
    this.endDate,
    this.trialEndDate,
    required this.monthlyPrice,
    required this.currency,
    required this.features,
    required this.limits,
    required this.createdAt,
    required this.updatedAt,
    this.isBtwExempt = false,
    this.btwRate = 0.21,
    this.btwNumber,
    this.companyName,
    this.kvkNumber,
    this.paymentMethodId,
    this.lastPaymentId,
    this.lastPaymentDate,
    this.nextPaymentDate,
  });

  /// Create from Firestore document
  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Subscription(
      id: doc.id,
      userId: data['userId'] ?? '',
      tier: SubscriptionTier.fromId(data['tier'] ?? ''),
      status: SubscriptionStatus.fromId(data['status'] ?? ''),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      trialEndDate: data['trialEndDate'] != null ? (data['trialEndDate'] as Timestamp).toDate() : null,
      monthlyPrice: (data['monthlyPrice'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'EUR',
      features: Map<String, bool>.from(data['features'] ?? {}),
      limits: Map<String, int?>.from(data['limits'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isBtwExempt: data['isBtwExempt'] ?? false,
      btwRate: (data['btwRate'] ?? 0.21).toDouble(),
      btwNumber: data['btwNumber'],
      companyName: data['companyName'],
      kvkNumber: data['kvkNumber'],
      paymentMethodId: data['paymentMethodId'],
      lastPaymentId: data['lastPaymentId'],
      lastPaymentDate: data['lastPaymentDate'] != null ? (data['lastPaymentDate'] as Timestamp).toDate() : null,
      nextPaymentDate: data['nextPaymentDate'] != null ? (data['nextPaymentDate'] as Timestamp).toDate() : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'tier': tier.id,
      'status': status.id,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'trialEndDate': trialEndDate != null ? Timestamp.fromDate(trialEndDate!) : null,
      'monthlyPrice': monthlyPrice,
      'currency': currency,
      'features': features,
      'limits': limits,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isBtwExempt': isBtwExempt,
      'btwRate': btwRate,
      'btwNumber': btwNumber,
      'companyName': companyName,
      'kvkNumber': kvkNumber,
      'paymentMethodId': paymentMethodId,
      'lastPaymentId': lastPaymentId,
      'lastPaymentDate': lastPaymentDate != null ? Timestamp.fromDate(lastPaymentDate!) : null,
      'nextPaymentDate': nextPaymentDate != null ? Timestamp.fromDate(nextPaymentDate!) : null,
    };
  }

  /// Get days remaining in trial
  int? get trialDaysRemaining {
    if (trialEndDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(trialEndDate!)) return 0;
    return trialEndDate!.difference(now).inDays;
  }

  /// Check if trial is ending soon (within 3 days)
  bool get isTrialEndingSoon {
    final daysRemaining = trialDaysRemaining;
    return daysRemaining != null && daysRemaining <= 3 && daysRemaining > 0;
  }

  /// Check if subscription is expired
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Get price with BTW included
  double get priceWithBTW {
    if (isBtwExempt) return monthlyPrice;
    return monthlyPrice * (1 + btwRate);
  }

  /// Copy with updated fields
  Subscription copyWith({
    String? id,
    String? userId,
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? trialEndDate,
    double? monthlyPrice,
    String? currency,
    Map<String, bool>? features,
    Map<String, int?>? limits,
    DateTime? updatedAt,
    bool? isBtwExempt,
    double? btwRate,
    String? btwNumber,
    String? companyName,
    String? kvkNumber,
    String? paymentMethodId,
    String? lastPaymentId,
    DateTime? lastPaymentDate,
    DateTime? nextPaymentDate,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      currency: currency ?? this.currency,
      features: features ?? this.features,
      limits: limits ?? this.limits,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isBtwExempt: isBtwExempt ?? this.isBtwExempt,
      btwRate: btwRate ?? this.btwRate,
      btwNumber: btwNumber ?? this.btwNumber,
      companyName: companyName ?? this.companyName,
      kvkNumber: kvkNumber ?? this.kvkNumber,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      lastPaymentId: lastPaymentId ?? this.lastPaymentId,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
    );
  }

  @override
  String toString() {
    return 'Subscription(id: $id, userId: $userId, tier: ${tier.displayName}, status: ${status.displayName})';
  }
}

/// Usage record for usage-based subscriptions (clients)
class UsageRecord {
  final String id;
  final String subscriptionId;
  final String userId;
  final DateTime date;
  final String usageType; // 'job_hours', 'api_calls', etc.
  final double quantity;
  final double unitPrice;
  final double totalCost;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const UsageRecord({
    required this.id,
    required this.subscriptionId,
    required this.userId,
    required this.date,
    required this.usageType,
    required this.quantity,
    required this.unitPrice,
    required this.totalCost,
    required this.metadata,
    required this.createdAt,
  });

  factory UsageRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UsageRecord(
      id: doc.id,
      subscriptionId: data['subscriptionId'] ?? '',
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      usageType: data['usageType'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      unitPrice: (data['unitPrice'] ?? 0.0).toDouble(),
      totalCost: (data['totalCost'] ?? 0.0).toDouble(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'subscriptionId': subscriptionId,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'usageType': usageType,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalCost': totalCost,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Subscription change request
class SubscriptionChangeRequest {
  final String subscriptionId;
  final SubscriptionTier newTier;
  final DateTime? effectiveDate;
  final String reason;
  final bool prorated;

  const SubscriptionChangeRequest({
    required this.subscriptionId,
    required this.newTier,
    this.effectiveDate,
    required this.reason,
    this.prorated = true,
  });
}

/// Result of subscription operations
class SubscriptionResult {
  final bool success;
  final String? error;
  final Subscription? subscription;
  final Map<String, dynamic>? metadata;

  const SubscriptionResult({
    required this.success,
    this.error,
    this.subscription,
    this.metadata,
  });

  factory SubscriptionResult.success(Subscription subscription, {Map<String, dynamic>? metadata}) {
    return SubscriptionResult(
      success: true,
      subscription: subscription,
      metadata: metadata,
    );
  }

  factory SubscriptionResult.error(String error) {
    return SubscriptionResult(
      success: false,
      error: error,
    );
  }
}