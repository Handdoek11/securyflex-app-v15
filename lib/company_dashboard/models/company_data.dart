

/// Company profile data model with Dutch business logic validation
/// Following BeveiligerProfielData pattern adapted for Company requirements
class CompanyData {
  // Bedrijfsgegevens
  final String companyId;
  final String companyName;
  final String kvkNumber;           // Dutch Chamber of Commerce number
  final String btwNumber;           // Dutch VAT number
  final String contactPerson;
  final String emailAddress;
  final String phoneNumber;        // Dutch format validation
  final String address;
  final String postalCode;         // 1234AB format
  final String city;
  final String description;
  final String logoUrl;
  final DateTime registeredSince;
  
  // Bedrijfsactiviteiten
  final List<String> serviceTypes;  // Types of security services offered
  final List<String> operatingRegions; // Geographic coverage areas
  final bool hasInsurance;
  final String? insuranceProvider;
  final DateTime? insuranceExpiry;
  
  // Platform statistieken
  final double averageRating;
  final int totalJobsPosted;
  final int activeJobs;
  final int completedJobs;
  final double totalSpent;
  final int totalGuardsHired;
  final double averageJobValue;
  
  // Status en verificatie
  final CompanyStatus status;
  final bool isVerified;
  final DateTime? lastActivity;
  final List<String> verificationDocuments;
  
  const CompanyData({
    required this.companyId,
    required this.companyName,
    required this.kvkNumber,
    this.btwNumber = '',
    required this.contactPerson,
    required this.emailAddress,
    required this.phoneNumber,
    required this.address,
    required this.postalCode,
    required this.city,
    this.description = '',
    this.logoUrl = '',
    required this.registeredSince,
    this.serviceTypes = const [],
    this.operatingRegions = const [],
    this.hasInsurance = false,
    this.insuranceProvider,
    this.insuranceExpiry,
    this.averageRating = 0.0,
    this.totalJobsPosted = 0,
    this.activeJobs = 0,
    this.completedJobs = 0,
    this.totalSpent = 0.0,
    this.totalGuardsHired = 0,
    this.averageJobValue = 0.0,
    this.status = CompanyStatus.active,
    this.isVerified = false,
    this.lastActivity,
    this.verificationDocuments = const [],
  });

  /// Copy with method for updates
  CompanyData copyWith({
    String? companyId,
    String? companyName,
    String? kvkNumber,
    String? btwNumber,
    String? contactPerson,
    String? emailAddress,
    String? phoneNumber,
    String? address,
    String? postalCode,
    String? city,
    String? description,
    String? logoUrl,
    DateTime? registeredSince,
    List<String>? serviceTypes,
    List<String>? operatingRegions,
    bool? hasInsurance,
    String? insuranceProvider,
    DateTime? insuranceExpiry,
    double? averageRating,
    int? totalJobsPosted,
    int? activeJobs,
    int? completedJobs,
    double? totalSpent,
    int? totalGuardsHired,
    double? averageJobValue,
    CompanyStatus? status,
    bool? isVerified,
    DateTime? lastActivity,
    List<String>? verificationDocuments,
  }) {
    return CompanyData(
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      kvkNumber: kvkNumber ?? this.kvkNumber,
      btwNumber: btwNumber ?? this.btwNumber,
      contactPerson: contactPerson ?? this.contactPerson,
      emailAddress: emailAddress ?? this.emailAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      registeredSince: registeredSince ?? this.registeredSince,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      operatingRegions: operatingRegions ?? this.operatingRegions,
      hasInsurance: hasInsurance ?? this.hasInsurance,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      averageRating: averageRating ?? this.averageRating,
      totalJobsPosted: totalJobsPosted ?? this.totalJobsPosted,
      activeJobs: activeJobs ?? this.activeJobs,
      completedJobs: completedJobs ?? this.completedJobs,
      totalSpent: totalSpent ?? this.totalSpent,
      totalGuardsHired: totalGuardsHired ?? this.totalGuardsHired,
      averageJobValue: averageJobValue ?? this.averageJobValue,
      status: status ?? this.status,
      isVerified: isVerified ?? this.isVerified,
      lastActivity: lastActivity ?? this.lastActivity,
      verificationDocuments: verificationDocuments ?? this.verificationDocuments,
    );
  }
}

/// Company status enumeration
enum CompanyStatus {
  active,      // Actief
  inactive,    // Inactief
  suspended,   // Opgeschort
  pending,     // In behandeling
}

/// Extension for Dutch display names
extension CompanyStatusExtension on CompanyStatus {
  String get displayName {
    switch (this) {
      case CompanyStatus.active:
        return 'Actief';
      case CompanyStatus.inactive:
        return 'Inactief';
      case CompanyStatus.suspended:
        return 'Opgeschort';
      case CompanyStatus.pending:
        return 'In behandeling';
    }
  }
}
