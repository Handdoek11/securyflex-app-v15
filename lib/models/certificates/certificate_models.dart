import 'package:equatable/equatable.dart';

/// Nederlandse Security Certificate Models
/// 
/// Comprehensive models for Dutch security certificates including WPBR, VCA, BHV,
/// EHBO and specialized certifications. Supports intelligent matching, expiration
/// tracking, and career progression recommendations.

/// Security Certificate Level (normalized)
enum CertificateLevel {
  entry('entry', 'Instap', 1),
  basic('basic', 'Basis', 2),
  advanced('advanced', 'Professioneel', 4),
  expert('expert', 'Expert', 5);

  const CertificateLevel(this.code, this.dutchName, this.hierarchyLevel);

  final String code;
  final String dutchName;
  final int hierarchyLevel;

  /// Check if this level covers requirements for another level
  bool covers(CertificateLevel other) => hierarchyLevel >= other.hierarchyLevel;

  static CertificateLevel fromCode(String code) {
    return CertificateLevel.values.firstWhere(
      (level) => level.code == code,
      orElse: () => CertificateLevel.basic,
    );
  }
}

/// Certificate Category (consolidated)
enum CertificateCategory {
  security('security', 'Beveiliging'),
  safety('safety', 'Veiligheid'),
  driving('driving', 'Rijbewijzen'),
  firstAid('first_aid', 'Eerste Hulp');

  const CertificateCategory(this.code, this.dutchName);

  final String code;
  final String dutchName;

  static CertificateCategory fromCode(String code) {
    return CertificateCategory.values.firstWhere(
      (category) => category.code == code,
      orElse: () => CertificateCategory.security,
    );
  }
}

/// Certificate Status (simplified)
enum CertificateStatus {
  valid('valid', 'Geldig'),
  expiringSoon('expiring_soon', 'Vervalt binnenkort'),
  expired('expired', 'Verlopen'),
  pending('pending', 'In behandeling');

  const CertificateStatus(this.code, this.dutchName);

  final String code;
  final String dutchName;

  /// Check if certificate is usable for job matching
  bool get isUsable => this == valid || this == expiringSoon;

  /// Check if certificate needs attention
  bool get needsAttention => this == expiringSoon || this == expired;

  static CertificateStatus fromCode(String code) {
    return CertificateStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => CertificateStatus.valid,
    );
  }
}

/// Certificate Verification Method (essential only)
enum CertificateVerificationMethod {
  document('document'),
  manual('manual');

  const CertificateVerificationMethod(this.code);

  final String code;

  static CertificateVerificationMethod fromCode(String code) {
    return CertificateVerificationMethod.values.firstWhere(
      (method) => method.code == code,
      orElse: () => CertificateVerificationMethod.document,
    );
  }
}

/// Nederlandse Security Certificate Model (optimized)
class DutchSecurityCertificate extends Equatable {
  final String id;
  final String name;
  final CertificateLevel level;
  final CertificateCategory category;
  final Duration validityPeriod;
  final List<String> equivalentNames;
  final int matchWeight; // Weight in matching algorithm (0-100)
  final bool isMandatory; // Required for all security jobs

  const DutchSecurityCertificate({
    required this.id,
    required this.name,
    required this.level,
    required this.category,
    required this.validityPeriod,
    this.equivalentNames = const [],
    this.matchWeight = 50,
    this.isMandatory = false,
  });

  /// Check if this certificate covers another certificate's requirements
  bool covers(DutchSecurityCertificate other) {
    // Level hierarchy within same category
    if (category == other.category && level.covers(other.level)) return true;
    
    // WPBR specific logic
    if (category == CertificateCategory.security) {
      if (id == 'wpbr_b' && other.id == 'wpbr_a') return true;
    }
    
    return false;
  }

  /// Check if certificate name matches (simplified)
  bool matchesName(String searchName) {
    final normalized = searchName.toLowerCase().trim();
    final nameNormalized = name.toLowerCase();
    
    // Exact or partial match
    if (nameNormalized.contains(normalized) || normalized.contains(nameNormalized)) return true;
    
    // Equivalent names
    return equivalentNames.any((equiv) => equiv.toLowerCase().contains(normalized));
  }


  /// Convert to JSON (minimal)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level.code,
      'category': category.code,
      'validityPeriodDays': validityPeriod.inDays,
      'equivalentNames': equivalentNames,
      'matchWeight': matchWeight,
      'isMandatory': isMandatory,
    };
  }

  /// Create from JSON (minimal)
  factory DutchSecurityCertificate.fromJson(Map<String, dynamic> json) {
    return DutchSecurityCertificate(
      id: json['id'],
      name: json['name'],
      level: CertificateLevel.fromCode(json['level']),
      category: CertificateCategory.fromCode(json['category']),
      validityPeriod: Duration(days: json['validityPeriodDays']),
      equivalentNames: List<String>.from(json['equivalentNames'] ?? []),
      matchWeight: json['matchWeight'] ?? 50,
      isMandatory: json['isMandatory'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id, name, level, category, validityPeriod, equivalentNames, matchWeight, isMandatory,
  ];
}

/// User's Certificate Instance
class UserCertificate extends Equatable {
  final String id;
  final String userId;
  final String certificateId; // Reference to DutchSecurityCertificate
  final String certificateNumber;
  final DateTime issueDate;
  final DateTime expiryDate;
  final CertificateStatus status;
  final CertificateVerificationMethod verificationMethod;
  final String? documentUrl; // Secure Firebase Storage URL
  final bool isVerified;

  const UserCertificate({
    required this.id,
    required this.userId,
    required this.certificateId,
    required this.certificateNumber,
    required this.issueDate,
    required this.expiryDate,
    this.status = CertificateStatus.pending,
    this.verificationMethod = CertificateVerificationMethod.document,
    this.documentUrl,
    this.isVerified = false,
  });

  /// Check if certificate is currently valid
  bool get isValid => status.isUsable && DateTime.now().isBefore(expiryDate);

  /// Check if certificate expires soon (within 6 months)
  bool get expiresSoon {
    final now = DateTime.now();
    final sixMonthsFromNow = now.add(const Duration(days: 180));
    return expiryDate.isBefore(sixMonthsFromNow);
  }

  /// Get days until expiry
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  /// Get status with expiry consideration
  CertificateStatus get computedStatus {
    if (status != CertificateStatus.valid) return status;
    
    if (DateTime.now().isAfter(expiryDate)) {
      return CertificateStatus.expired;
    }
    
    if (expiresSoon) {
      return CertificateStatus.expiringSoon;
    }
    
    return CertificateStatus.valid;
  }

  /// Copy with updated properties
  UserCertificate copyWith({
    String? id,
    String? userId,
    String? certificateId,
    String? certificateNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    CertificateStatus? status,
    CertificateVerificationMethod? verificationMethod,
    String? documentUrl,
    bool? isVerified,
  }) {
    return UserCertificate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      certificateId: certificateId ?? this.certificateId,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      documentUrl: documentUrl ?? this.documentUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'certificateId': certificateId,
      'certificateNumber': certificateNumber,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'status': status.code,
      'verificationMethod': verificationMethod.code,
      'documentUrl': documentUrl,
      'isVerified': isVerified,
    };
  }

  /// Create from JSON
  factory UserCertificate.fromJson(Map<String, dynamic> json) {
    return UserCertificate(
      id: json['id'],
      userId: json['userId'],
      certificateId: json['certificateId'],
      certificateNumber: json['certificateNumber'],
      issueDate: DateTime.parse(json['issueDate']),
      expiryDate: DateTime.parse(json['expiryDate']),
      status: CertificateStatus.fromCode(json['status']),
      verificationMethod: CertificateVerificationMethod.fromCode(json['verificationMethod']),
      documentUrl: json['documentUrl'],
      isVerified: json['isVerified'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id, userId, certificateId, certificateNumber, issueDate, expiryDate,
    status, verificationMethod, documentUrl, isVerified,
  ];
}

/// Certificate Registry (optimized)
class CertificateRegistry {
  static const List<DutchSecurityCertificate> _certificates = [
    // WPBR Certificates
    DutchSecurityCertificate(
      id: 'wpbr_a',
      name: 'WPBR Diploma A',
      level: CertificateLevel.basic,
      category: CertificateCategory.security,
      validityPeriod: Duration(days: 1825),
      equivalentNames: ['beveiligingsdiploma a', 'beveiliger a'],
      matchWeight: 90,
      isMandatory: true,
    ),

    DutchSecurityCertificate(
      id: 'wpbr_b',
      name: 'WPBR Diploma B',
      level: CertificateLevel.advanced,
      category: CertificateCategory.security,
      validityPeriod: Duration(days: 1825),
      equivalentNames: ['beveiligingsdiploma b', 'beveiliger b'],
      matchWeight: 100,
    ),

    // VCA Certificates
    DutchSecurityCertificate(
      id: 'vca_basic',
      name: 'VCA Basis Certificaat',
      level: CertificateLevel.basic,
      category: CertificateCategory.safety,
      validityPeriod: Duration(days: 3650),
      equivalentNames: ['vca', 'vca certificaat'],
      matchWeight: 70,
    ),

    // BHV Certificates
    DutchSecurityCertificate(
      id: 'bhv',
      name: 'BHV Certificaat',
      level: CertificateLevel.basic,
      category: CertificateCategory.firstAid,
      validityPeriod: Duration(days: 1095),
      equivalentNames: ['bedrijfshulpverlening'],
      matchWeight: 60,
    ),

    // EHBO Certificate
    DutchSecurityCertificate(
      id: 'ehbo',
      name: 'EHBO Certificaat',
      level: CertificateLevel.basic,
      category: CertificateCategory.firstAid,
      validityPeriod: Duration(days: 1095),
      equivalentNames: ['eerste hulp'],
      matchWeight: 50,
    ),

    // Specialized Certificates
    DutchSecurityCertificate(
      id: 'portier',
      name: 'Portier Diploma',
      level: CertificateLevel.basic,
      category: CertificateCategory.security,
      validityPeriod: Duration(days: 1825),
      equivalentNames: ['portier certificaat'],
      matchWeight: 80,
    ),

    DutchSecurityCertificate(
      id: 'persoonbeveiliging',
      name: 'Persoonbeveiliging Diploma',
      level: CertificateLevel.expert,
      category: CertificateCategory.security,
      validityPeriod: Duration(days: 1825),
      equivalentNames: ['bodyguard diploma', 'close protection'],
      matchWeight: 95,
    ),

    // Driving Licenses
    DutchSecurityCertificate(
      id: 'rijbewijs_b',
      name: 'Rijbewijs B',
      level: CertificateLevel.basic,
      category: CertificateCategory.driving,
      validityPeriod: Duration(days: 3650),
      equivalentNames: ['rijbewijs', 'driving license'],
      matchWeight: 30,
    ),
  ];

  /// Get all registered certificates
  static List<DutchSecurityCertificate> getAllCertificates() => _certificates;

  /// Get certificate by ID
  static DutchSecurityCertificate? getCertificateById(String id) {
    try {
      return _certificates.firstWhere((cert) => cert.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get certificates by category
  static List<DutchSecurityCertificate> getCertificatesByCategory(CertificateCategory category) {
    return _certificates.where((cert) => cert.category == category).toList();
  }

  /// Get certificates by level
  static List<DutchSecurityCertificate> getCertificatesByLevel(CertificateLevel level) {
    return _certificates.where((cert) => cert.level == level).toList();
  }

  /// Get mandatory certificates
  static List<DutchSecurityCertificate> getMandatoryCertificates() {
    return _certificates.where((cert) => cert.isMandatory).toList();
  }

  /// Find certificate by name (fuzzy matching)
  static DutchSecurityCertificate? findCertificateByName(String name) {
    for (final cert in _certificates) {
      if (cert.matchesName(name)) {
        return cert;
      }
    }
    return null;
  }

}