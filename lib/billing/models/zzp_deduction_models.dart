import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/utils/dutch_formatting.dart';
import 'zzp_tax_models.dart';

/// Individual deduction record with validation and metadata
class ZZPDeductionRecord extends Equatable {
  final String id;
  final String guardId;
  final ZZPDeductionCategory category;
  final double amount;
  final String description;
  final DateTime expenseDate;
  final List<String> receiptImageUrls;
  final Map<String, dynamic> metadata;
  final ZZPDeductionValidationStatus validationStatus;
  final int taxYear;
  final bool isValidForDeduction;
  final ZZPAutomaticValidation automaticValidation;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ZZPDeductionRecord({
    required this.id,
    required this.guardId,
    required this.category,
    required this.amount,
    required this.description,
    required this.expenseDate,
    required this.receiptImageUrls,
    required this.metadata,
    required this.validationStatus,
    required this.taxYear,
    required this.isValidForDeduction,
    required this.automaticValidation,
    required this.createdAt,
    required this.updatedAt,
  });

  String get dutchFormattedAmount => DutchFormatting.formatCurrency(amount);
  String get dutchFormattedDate => DutchFormatting.formatDate(expenseDate);

  factory ZZPDeductionRecord.fromFirestore(Map<String, dynamic> data) {
    return ZZPDeductionRecord(
      id: data['id'] as String,
      guardId: data['guard_id'] as String,
      category: ZZPDeductionCategory.values.firstWhere(
        (c) => c.name == data['category'],
      ),
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] as String,
      expenseDate: (data['expense_date'] as Timestamp).toDate(),
      receiptImageUrls: List<String>.from(data['receipt_image_urls'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      validationStatus: ZZPDeductionValidationStatus.values.firstWhere(
        (s) => s.name == data['validation_status'],
      ),
      taxYear: data['tax_year'] as int,
      isValidForDeduction: data['is_valid_for_deduction'] as bool? ?? true,
      automaticValidation: ZZPAutomaticValidation.fromFirestore(
        data['automatic_validation'] as Map<String, dynamic>,
      ),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'guard_id': guardId,
      'category': category.name,
      'amount': amount,
      'description': description,
      'expense_date': Timestamp.fromDate(expenseDate),
      'receipt_image_urls': receiptImageUrls,
      'metadata': metadata,
      'validation_status': validationStatus.name,
      'tax_year': taxYear,
      'is_valid_for_deduction': isValidForDeduction,
      'automatic_validation': automaticValidation.toFirestore(),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
    id, guardId, category, amount, expenseDate, validationStatus,
    taxYear, isValidForDeduction,
  ];
}

/// Automatic validation results for deductions
class ZZPAutomaticValidation extends Equatable {
  final Map<String, bool> validationRules;
  final double overallScore;
  final List<String> warnings;
  final List<String> suggestions;
  final bool requiresManualReview;
  final DateTime validatedAt;

  const ZZPAutomaticValidation({
    required this.validationRules,
    required this.overallScore,
    required this.warnings,
    required this.suggestions,
    required this.requiresManualReview,
    required this.validatedAt,
  });

  String get scorePercentage => '${(overallScore * 100).toStringAsFixed(0)}%';

  factory ZZPAutomaticValidation.fromFirestore(Map<String, dynamic> data) {
    return ZZPAutomaticValidation(
      validationRules: Map<String, bool>.from(data['validation_rules'] ?? {}),
      overallScore: (data['overall_score'] as num).toDouble(),
      warnings: List<String>.from(data['warnings'] ?? []),
      suggestions: List<String>.from(data['suggestions'] ?? []),
      requiresManualReview: data['requires_manual_review'] as bool? ?? false,
      validatedAt: (data['validated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'validation_rules': validationRules,
      'overall_score': overallScore,
      'warnings': warnings,
      'suggestions': suggestions,
      'requires_manual_review': requiresManualReview,
      'validated_at': Timestamp.fromDate(validatedAt),
    };
  }

  @override
  List<Object?> get props => [
    validationRules, overallScore, warnings, requiresManualReview, validatedAt,
  ];
}

/// Transportation deduction calculation
class ZZPTransportationDeduction extends Equatable {
  final String guardId;
  final ZZPDeductionPeriod period;
  final double totalKilometers;
  final double ratePerKilometer;
  final double totalDeductionAmount;
  final List<ZZPValidatedTrip> validatedTrips;
  final double businessTripPercentage;
  final DateTime calculatedAt;

  const ZZPTransportationDeduction({
    required this.guardId,
    required this.period,
    required this.totalKilometers,
    required this.ratePerKilometer,
    required this.totalDeductionAmount,
    required this.validatedTrips,
    required this.businessTripPercentage,
    required this.calculatedAt,
  });

  String get dutchFormattedTotal => DutchFormatting.formatCurrency(totalDeductionAmount);
  String get dutchFormattedRate => DutchFormatting.formatCurrency(ratePerKilometer);
  String get dutchFormattedPercentage => '${(businessTripPercentage * 100).toStringAsFixed(1)}%';

  Map<String, dynamic> toFirestore() {
    return {
      'guard_id': guardId,
      'period': period.toFirestore(),
      'total_kilometers': totalKilometers,
      'rate_per_kilometer': ratePerKilometer,
      'total_deduction_amount': totalDeductionAmount,
      'validated_trips': validatedTrips.map((trip) => trip.toFirestore()).toList(),
      'business_trip_percentage': businessTripPercentage,
      'calculated_at': Timestamp.fromDate(calculatedAt),
    };
  }

  @override
  List<Object?> get props => [
    guardId, totalKilometers, totalDeductionAmount, businessTripPercentage,
    calculatedAt,
  ];
}

/// Individual trip record for transportation deductions
class ZZPTripRecord extends Equatable {
  final String fromLocation;
  final String toLocation;
  final double kilometers;
  final String purpose;
  final DateTime tripDate;
  final bool isBusinessTrip;
  final String? clientName;

  const ZZPTripRecord({
    required this.fromLocation,
    required this.toLocation,
    required this.kilometers,
    required this.purpose,
    required this.tripDate,
    required this.isBusinessTrip,
    this.clientName,
  });

  String get dutchFormattedDate => DutchFormatting.formatDate(tripDate);

  @override
  List<Object?> get props => [
    fromLocation, toLocation, kilometers, purpose, tripDate, isBusinessTrip,
  ];
}

/// Validated trip with deduction calculation
class ZZPValidatedTrip extends Equatable {
  final ZZPTripRecord originalTrip;
  final double validatedDistance;
  final double deductionAmount;
  final String validationNotes;

  const ZZPValidatedTrip({
    required this.originalTrip,
    required this.validatedDistance,
    required this.deductionAmount,
    required this.validationNotes,
  });

  String get dutchFormattedDeduction => DutchFormatting.formatCurrency(deductionAmount);

  Map<String, dynamic> toFirestore() {
    return {
      'from_location': originalTrip.fromLocation,
      'to_location': originalTrip.toLocation,
      'original_kilometers': originalTrip.kilometers,
      'validated_distance': validatedDistance,
      'deduction_amount': deductionAmount,
      'purpose': originalTrip.purpose,
      'trip_date': Timestamp.fromDate(originalTrip.tripDate),
      'validation_notes': validationNotes,
      'client_name': originalTrip.clientName,
    };
  }

  @override
  List<Object?> get props => [
    originalTrip, validatedDistance, deductionAmount, validationNotes,
  ];
}

/// Home office deduction calculation
class ZZPHomeOfficeDeduction extends Equatable {
  final String guardId;
  final int taxYear;
  final double homeSquareMeters;
  final double officeSquareMeters;
  final double officePercentage;
  final int workDaysPerWeek;
  final double businessUsagePercentage;
  final double totalHomeCosts;
  final Map<String, double> deductibleCosts;
  final double calculatedDeduction;
  final double cappedDeduction;
  final double maximumLimit;
  final DateTime calculatedAt;

  const ZZPHomeOfficeDeduction({
    required this.guardId,
    required this.taxYear,
    required this.homeSquareMeters,
    required this.officeSquareMeters,
    required this.officePercentage,
    required this.workDaysPerWeek,
    required this.businessUsagePercentage,
    required this.totalHomeCosts,
    required this.deductibleCosts,
    required this.calculatedDeduction,
    required this.cappedDeduction,
    required this.maximumLimit,
    required this.calculatedAt,
  });

  String get dutchFormattedDeduction => DutchFormatting.formatCurrency(cappedDeduction);
  String get dutchFormattedPercentage => '${(officePercentage * 100).toStringAsFixed(1)}%';
  String get dutchFormattedUsage => '${(businessUsagePercentage * 100).toStringAsFixed(1)}%';

  Map<String, dynamic> toFirestore() {
    return {
      'guard_id': guardId,
      'tax_year': taxYear,
      'home_square_meters': homeSquareMeters,
      'office_square_meters': officeSquareMeters,
      'office_percentage': officePercentage,
      'work_days_per_week': workDaysPerWeek,
      'business_usage_percentage': businessUsagePercentage,
      'total_home_costs': totalHomeCosts,
      'deductible_costs': deductibleCosts,
      'calculated_deduction': calculatedDeduction,
      'capped_deduction': cappedDeduction,
      'maximum_limit': maximumLimit,
      'calculated_at': Timestamp.fromDate(calculatedAt),
    };
  }

  Map<String, dynamic> toMetadata() {
    return {
      'home_office_calculation': {
        'home_square_meters': homeSquareMeters,
        'office_square_meters': officeSquareMeters,
        'office_percentage': officePercentage,
        'work_days_per_week': workDaysPerWeek,
        'business_usage_percentage': businessUsagePercentage,
      },
    };
  }

  @override
  List<Object?> get props => [
    guardId, taxYear, officePercentage, calculatedDeduction, cappedDeduction,
    calculatedAt,
  ];
}

/// Comprehensive deduction summary for a period
class ZZPDeductionSummary extends Equatable {
  final String guardId;
  final int taxYear;
  final Map<ZZPDeductionCategory, double> categoryTotals;
  final Map<ZZPDeductionCategory, List<ZZPDeductionRecord>> categoryDeductions;
  final Map<ZZPDeductionCategory, double> remainingLimits;
  final double totalDeductions;
  final double averageMonthlyDeductions;
  final double projectedYearEndTotal;
  final List<ZZPOptimizationOpportunity> optimizationOpportunities;
  final DateTime generatedAt;

  const ZZPDeductionSummary({
    required this.guardId,
    required this.taxYear,
    required this.categoryTotals,
    required this.categoryDeductions,
    required this.remainingLimits,
    required this.totalDeductions,
    required this.averageMonthlyDeductions,
    required this.projectedYearEndTotal,
    required this.optimizationOpportunities,
    required this.generatedAt,
  });

  String get dutchFormattedTotal => DutchFormatting.formatCurrency(totalDeductions);
  String get dutchFormattedProjected => DutchFormatting.formatCurrency(projectedYearEndTotal);
  String get dutchFormattedMonthly => DutchFormatting.formatCurrency(averageMonthlyDeductions);

  @override
  List<Object?> get props => [
    guardId, taxYear, totalDeductions, projectedYearEndTotal, generatedAt,
  ];
}

/// Deduction optimization opportunity
class ZZPOptimizationOpportunity extends Equatable {
  final ZZPDeductionCategory category;
  final double currentAmount;
  final double potentialAmount;
  final double opportunityAmount;
  final ZZPOptimizationPriority priority;

  const ZZPOptimizationOpportunity({
    required this.category,
    required this.currentAmount,
    required this.potentialAmount,
    required this.opportunityAmount,
    required this.priority,
  });

  String get dutchFormattedOpportunity => DutchFormatting.formatCurrency(opportunityAmount);
  String get utilizationPercentage => 
      '${(currentAmount / potentialAmount * 100).toStringAsFixed(0)}%';

  @override
  List<Object?> get props => [
    category, currentAmount, potentialAmount, opportunityAmount, priority,
  ];
}

/// Deduction optimization recommendation
class ZZPDeductionOptimization extends Equatable {
  final ZZPDeductionCategory category;
  final String title;
  final String description;
  final double potentialSavings;
  final ZZPOptimizationPriority priority;
  final List<String> actionItems;
  final DateTime deadline;

  const ZZPDeductionOptimization({
    required this.category,
    required this.title,
    required this.description,
    required this.potentialSavings,
    required this.priority,
    required this.actionItems,
    required this.deadline,
  });

  String get dutchFormattedSavings => DutchFormatting.formatCurrency(potentialSavings);
  String get dutchFormattedDeadline => DutchFormatting.formatDate(deadline);

  Map<String, dynamic> toFirestore() {
    return {
      'category': category.name,
      'title': title,
      'description': description,
      'potential_savings': potentialSavings,
      'priority': priority.name,
      'action_items': actionItems,
      'deadline': Timestamp.fromDate(deadline),
    };
  }

  @override
  List<Object?> get props => [
    category, title, potentialSavings, priority, deadline,
  ];
}

/// Deduction period specification
class ZZPDeductionPeriod extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const ZZPDeductionPeriod({
    required this.startDate,
    required this.endDate,
  });

  String get dutchFormattedPeriod => 
      '${DutchFormatting.formatDate(startDate)} - ${DutchFormatting.formatDate(endDate)}';

  int get durationDays => endDate.difference(startDate).inDays;

  Map<String, dynamic> toFirestore() {
    return {
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
    };
  }

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Deduction validation status
enum ZZPDeductionValidationStatus {
  pending,
  approved,
  rejected,
  requiresDocumentation,
  underReview,
}

/// Extensions for enum localization
extension ZZPDeductionValidationStatusExtension on ZZPDeductionValidationStatus {
  String get dutchName {
    switch (this) {
      case ZZPDeductionValidationStatus.pending:
        return 'In Behandeling';
      case ZZPDeductionValidationStatus.approved:
        return 'Goedgekeurd';
      case ZZPDeductionValidationStatus.rejected:
        return 'Afgekeurd';
      case ZZPDeductionValidationStatus.requiresDocumentation:
        return 'Documentatie Vereist';
      case ZZPDeductionValidationStatus.underReview:
        return 'Onder Review';
    }
  }
}

extension ZZPDeductionCategoryExtension on ZZPDeductionCategory {
  String get dutchName {
    switch (this) {
      case ZZPDeductionCategory.securityEquipment:
        return 'Beveiligingsuitrusting';
      case ZZPDeductionCategory.professionalTraining:
        return 'Professionele Opleidingen';
      case ZZPDeductionCategory.transportation:
        return 'Reiskosten';
      case ZZPDeductionCategory.homeOffice:
        return 'Thuiswerkkamer';
      case ZZPDeductionCategory.businessExpenses:
        return 'Zakelijke Uitgaven';
      case ZZPDeductionCategory.professionalInsurance:
        return 'Beroepsverzekering';
      case ZZPDeductionCategory.marketingCosts:
        return 'Marketing Kosten';
    }
  }

  String get iconName {
    switch (this) {
      case ZZPDeductionCategory.securityEquipment:
        return 'security';
      case ZZPDeductionCategory.professionalTraining:
        return 'school';
      case ZZPDeductionCategory.transportation:
        return 'directions_car';
      case ZZPDeductionCategory.homeOffice:
        return 'home_work';
      case ZZPDeductionCategory.businessExpenses:
        return 'business';
      case ZZPDeductionCategory.professionalInsurance:
        return 'security';
      case ZZPDeductionCategory.marketingCosts:
        return 'campaign';
    }
  }
}