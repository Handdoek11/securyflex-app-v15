import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/beveiliger_profiel/models/specialization.dart';

/// eHerkenning authentication levels (KvK requirement)
enum EHerkenningLevel {
  none,     // Geen eHerkenning
  eh1,      // eHerkenning Level 1
  eh2,      // eHerkenning Level 2  
  eh3,      // eHerkenning Level 3 (minimum required)
  eh4,      // eHerkenning Level 4 (highest)
}

extension EHerkenningLevelExtension on EHerkenningLevel {
  String get displayName {
    switch (this) {
      case EHerkenningLevel.none:
        return 'Geen eHerkenning';
      case EHerkenningLevel.eh1:
        return 'eHerkenning Niveau 1';
      case EHerkenningLevel.eh2:
        return 'eHerkenning Niveau 2';
      case EHerkenningLevel.eh3:
        return 'eHerkenning Niveau 3';
      case EHerkenningLevel.eh4:
        return 'eHerkenning Niveau 4';
    }
  }

  bool get isValidForSecurity {
    return this == EHerkenningLevel.eh3 || this == EHerkenningLevel.eh4;
  }

  String get requirement {
    return 'eHerkenning niveau 3 of hoger is verplicht voor beveiligingsondernemers';
  }
}

/// Beveiliger profiel data model met Dutch business logic
/// 
/// Volgt SecuryFlex architecture patterns:
/// - DesignTokens voor validation constants  
/// - Dutch business logic voor KvK, postal codes, WPBR
/// - Integration met AuthService.currentUserData
/// - GDPR compliance fields
class BeveiligerProfielData extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? bio;
  final String? profileImageUrl;
  final List<String> specialisaties;
  final List<Specialization> specializations;
  final Map<SpecializationType, SkillLevel> skillLevels;
  final List<String> certificaten;
  final String? kvkNumber;
  final String? postalCode;
  final String? wpbrNumber;
  final DateTime? wpbrExpiryDate;
  
  // KvK 2025 Required Fields for Independent Security Guards
  final String? beveiligingspasnummer;
  final DateTime? beveiligingspasExpiryDate;
  final EHerkenningLevel eHerkenningLevel;
  final String? basisDiplomaNumber;
  final DateTime? basisDiplomaExpiryDate;
  final bool? uniformGoedkeuring;
  final String? uniformGoedkeuringDetails;
  
  final bool isVerified;
  final bool isActive;
  final bool gdprConsentGiven;
  final DateTime? lastUpdated;
  final DateTime createdAt;
  
  const BeveiligerProfielData({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.bio,
    this.profileImageUrl,
    this.specialisaties = const [],
    this.specializations = const [],
    this.skillLevels = const {},
    this.certificaten = const [],
    this.kvkNumber,
    this.postalCode,
    this.wpbrNumber,
    this.wpbrExpiryDate,
    // KvK 2025 Required Fields
    this.beveiligingspasnummer,
    this.beveiligingspasExpiryDate,
    this.eHerkenningLevel = EHerkenningLevel.none,
    this.basisDiplomaNumber,
    this.basisDiplomaExpiryDate,
    this.uniformGoedkeuring,
    this.uniformGoedkeuringDetails,
    this.isVerified = false,
    this.isActive = true,
    this.gdprConsentGiven = false,
    this.lastUpdated,
    required this.createdAt,
  });

  /// Create from AuthService.currentUserData
  factory BeveiligerProfielData.fromAuthService() {
    final userData = AuthService.currentUserData;
    return BeveiligerProfielData(
      id: AuthService.currentUserId,
      name: userData['name'] ?? 'Onbekende Naam',
      email: userData['email'] ?? '',
      phone: userData['phone'],
      bio: userData['bio'],
      profileImageUrl: userData['profileImageUrl'],
      specialisaties: List<String>.from(userData['specialisaties'] ?? []),
      specializations: _parseSpecializations(userData['specializations']),
      skillLevels: _parseSkillLevels(userData['skillLevels']),
      certificaten: List<String>.from(userData['certificaten'] ?? []),
      kvkNumber: userData['kvkNumber'],
      postalCode: userData['postalCode'],
      wpbrNumber: userData['wpbrNumber'],
      wpbrExpiryDate: userData['wpbrExpiryDate'] != null 
          ? DateTime.parse(userData['wpbrExpiryDate']) 
          : null,
      // KvK 2025 Required Fields
      beveiligingspasnummer: userData['beveiligingspasnummer'],
      beveiligingspasExpiryDate: userData['beveiligingspasExpiryDate'] != null
          ? DateTime.parse(userData['beveiligingspasExpiryDate'])
          : null,
      eHerkenningLevel: _parseEHerkenningLevel(userData['eHerkenningLevel']),
      basisDiplomaNumber: userData['basisDiplomaNumber'],
      basisDiplomaExpiryDate: userData['basisDiplomaExpiryDate'] != null
          ? DateTime.parse(userData['basisDiplomaExpiryDate'])
          : null,
      uniformGoedkeuring: userData['uniformGoedkeuring'],
      uniformGoedkeuringDetails: userData['uniformGoedkeuringDetails'],
      isVerified: userData['isVerified'] ?? false,
      isActive: userData['isActive'] ?? true,
      gdprConsentGiven: userData['gdprConsentGiven'] ?? false,
      lastUpdated: userData['lastUpdated'] != null 
          ? DateTime.parse(userData['lastUpdated']) 
          : null,
      createdAt: userData['createdAt'] != null 
          ? DateTime.parse(userData['createdAt']) 
          : DateTime.now(),
    );
  }

  /// Create sample data voor demo doeleinden
  factory BeveiligerProfielData.createSampleData() {
    return BeveiligerProfielData(
      id: 'demo_guard_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Jan van der Berg',
      email: 'jan.vandenberg@securyflex.nl',
      phone: '+31612345678',
      bio: 'Ervaren beveiliger met specialisatie in evenementen en retail. '
           '10+ jaar ervaring in de beveiligingsbranche.',
      profileImageUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Jan',
      specialisaties: [
        'Evenement Beveiliging',
        'Retail Beveiliging', 
        'Toegangscontrole',
        'EHBO',
      ],
      specializations: [
        Specialization(
          id: 'spec_1',
          type: SpecializationType.evenementbeveiliging,
          skillLevel: SkillLevel.ervaren,
          addedAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
        Specialization(
          id: 'spec_2',
          type: SpecializationType.winkelbeveiliging,
          skillLevel: SkillLevel.expert,
          addedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Specialization(
          id: 'spec_3',
          type: SpecializationType.toegangscontrole,
          skillLevel: SkillLevel.ervaren,
          addedAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ],
      skillLevels: {
        SpecializationType.evenementbeveiliging: SkillLevel.ervaren,
        SpecializationType.winkelbeveiliging: SkillLevel.expert,
        SpecializationType.toegangscontrole: SkillLevel.ervaren,
      },
      certificaten: [
        'WPBR Certificaat',
        'BHV Diploma',
        'EHBO Certificaat',
        'Security Awareness Training',
      ],
      kvkNumber: '12345678',
      postalCode: '1011AB',
      wpbrNumber: 'WPBR-123456',
      wpbrExpiryDate: DateTime.now().add(const Duration(days: 365)),
      // KvK 2025 Required Sample Data
      beveiligingspasnummer: '1234567',
      beveiligingspasExpiryDate: DateTime.now().add(const Duration(days: 1095)), // 3 years
      eHerkenningLevel: EHerkenningLevel.eh3,
      basisDiplomaNumber: 'SVPB-789012',
      basisDiplomaExpiryDate: DateTime.now().add(const Duration(days: 1825)), // 5 years
      uniformGoedkeuring: true,
      uniformGoedkeuringDetails: 'V-symbool goedgekeurd door Justis',
      isVerified: true,
      isActive: true,
      gdprConsentGiven: true,
      lastUpdated: DateTime.now().subtract(const Duration(days: 7)),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  /// Convert to JSON voor Firebase storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'specialisaties': specialisaties,
      'specializations': specializations.map((s) => s.toJson()).toList(),
      'skillLevels': skillLevels.map((key, value) => MapEntry(key.name, value.name)),
      'certificaten': certificaten,
      'kvkNumber': kvkNumber,
      'postalCode': postalCode,
      'wpbrNumber': wpbrNumber,
      'wpbrExpiryDate': wpbrExpiryDate?.toIso8601String(),
      // KvK 2025 Required Fields
      'beveiligingspasnummer': beveiligingspasnummer,
      'beveiligingspasExpiryDate': beveiligingspasExpiryDate?.toIso8601String(),
      'eHerkenningLevel': eHerkenningLevel.name,
      'basisDiplomaNumber': basisDiplomaNumber,
      'basisDiplomaExpiryDate': basisDiplomaExpiryDate?.toIso8601String(),
      'uniformGoedkeuring': uniformGoedkeuring,
      'uniformGoedkeuringDetails': uniformGoedkeuringDetails,
      'isVerified': isVerified,
      'isActive': isActive,
      'gdprConsentGiven': gdprConsentGiven,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON from Firebase
  factory BeveiligerProfielData.fromJson(Map<String, dynamic> json) {
    return BeveiligerProfielData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      bio: json['bio'],
      profileImageUrl: json['profileImageUrl'],
      specialisaties: List<String>.from(json['specialisaties'] ?? []),
      specializations: _parseSpecializations(json['specializations']),
      skillLevels: _parseSkillLevels(json['skillLevels']),
      certificaten: List<String>.from(json['certificaten'] ?? []),
      kvkNumber: json['kvkNumber'],
      postalCode: json['postalCode'],
      wpbrNumber: json['wpbrNumber'],
      wpbrExpiryDate: BeveiligerProfielData._parseDateTime(json['wpbrExpiryDate']),
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      gdprConsentGiven: json['gdprConsentGiven'] ?? false,
      lastUpdated: BeveiligerProfielData._parseDateTime(json['lastUpdated']),
      createdAt: BeveiligerProfielData._parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  /// Copy with new values
  BeveiligerProfielData copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? profileImageUrl,
    List<String>? specialisaties,
    List<Specialization>? specializations,
    Map<SpecializationType, SkillLevel>? skillLevels,
    List<String>? certificaten,
    String? kvkNumber,
    String? postalCode,
    String? wpbrNumber,
    DateTime? wpbrExpiryDate,
    bool? isVerified,
    bool? isActive,
    bool? gdprConsentGiven,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return BeveiligerProfielData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      specialisaties: specialisaties ?? this.specialisaties,
      specializations: specializations ?? this.specializations,
      skillLevels: skillLevels ?? this.skillLevels,
      certificaten: certificaten ?? this.certificaten,
      kvkNumber: kvkNumber ?? this.kvkNumber,
      postalCode: postalCode ?? this.postalCode,
      wpbrNumber: wpbrNumber ?? this.wpbrNumber,
      wpbrExpiryDate: wpbrExpiryDate ?? this.wpbrExpiryDate,
      // KvK 2025 Required Fields
      beveiligingspasnummer: beveiligingspasnummer ?? beveiligingspasnummer,
      beveiligingspasExpiryDate: beveiligingspasExpiryDate ?? beveiligingspasExpiryDate,
      eHerkenningLevel: eHerkenningLevel,
      basisDiplomaNumber: basisDiplomaNumber ?? basisDiplomaNumber,
      basisDiplomaExpiryDate: basisDiplomaExpiryDate ?? basisDiplomaExpiryDate,
      uniformGoedkeuring: uniformGoedkeuring ?? uniformGoedkeuring,
      uniformGoedkeuringDetails: uniformGoedkeuringDetails ?? uniformGoedkeuringDetails,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      gdprConsentGiven: gdprConsentGiven ?? this.gdprConsentGiven,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Dutch business logic validation methods

  /// Validate profiel data met Dutch business rules
  List<String> get validationErrors {
    final errors = <String>[];

    // Name validation
    if (name.isEmpty) {
      errors.add('Naam is verplicht');
    } else if (name.length < 2) {
      errors.add('Naam moet minimaal 2 karakters bevatten');
    } else if (name.length > DesignTokens.fontSizeDisplayLarge.toInt() * 3) {
      errors.add('Naam mag maximaal ${DesignTokens.fontSizeDisplayLarge.toInt() * 3} karakters bevatten');
    }

    // Email validation
    if (email.isEmpty) {
      errors.add('E-mailadres is verplicht');
    } else if (!AuthService.isValidEmail(email)) {
      errors.add('Ongeldig e-mailadres formaat');
    }

    // Phone validation (Dutch format)
    if (phone != null && phone!.isNotEmpty) {
      if (!_isValidDutchPhone(phone!)) {
        errors.add('Ongeldig Nederlands telefoonnummer formaat');
      }
    }

    // Bio length validation
    if (bio != null && bio!.length > 500) {
      errors.add('Bio mag maximaal 500 karakters bevatten');
    }

    // KvK validation
    if (kvkNumber != null && kvkNumber!.isNotEmpty) {
      if (!AuthService.isValidKvK(kvkNumber!)) {
        errors.add('Ongeldig KvK nummer formaat (8 cijfers verwacht)');
      }
    }

    // Postal code validation
    if (postalCode != null && postalCode!.isNotEmpty) {
      if (!AuthService.isValidDutchPostalCode(postalCode!)) {
        errors.add('Ongeldig Nederlands postcode formaat (1234AB verwacht)');
      }
    }

    // WPBR validation
    if (wpbrNumber != null && wpbrNumber!.isNotEmpty) {
      if (!AuthService.isValidWPBRNumber(wpbrNumber!)) {
        errors.add('Ongeldig WPBR certificaatnummer formaat (WPBR-123456 verwacht)');
      }
    }

    // WPBR expiry validation
    if (wpbrExpiryDate != null && wpbrExpiryDate!.isBefore(DateTime.now())) {
      errors.add('WPBR certificaat is verlopen');
    }

    return errors;
  }

  /// Check if profiel data is valid
  bool get isValid => validationErrors.isEmpty;

  /// Check if any required fields are missing
  bool get hasRequiredFields {
    return name.isNotEmpty && 
           email.isNotEmpty && 
           AuthService.isValidEmail(email);
  }

  /// Check if profile has enough information for job applications
  bool get isReadyForJobApplication {
    return hasRequiredFields &&
           wpbrNumber != null && 
           wpbrNumber!.isNotEmpty &&
           specialisaties.isNotEmpty &&
           certificaten.contains('WPBR Certificaat');
  }

  /// Get profile completion score (0.0 to 1.0)
  double get profileCompletionScore {
    double score = 0.0;
    final fields = [
      name.isNotEmpty, // Required
      email.isNotEmpty, // Required  
      phone != null && phone!.isNotEmpty,
      bio != null && bio!.isNotEmpty,
      profileImageUrl != null && profileImageUrl!.isNotEmpty,
      specialisaties.isNotEmpty,
      certificaten.isNotEmpty,
      kvkNumber != null && kvkNumber!.isNotEmpty,
      postalCode != null && postalCode!.isNotEmpty,
      wpbrNumber != null && wpbrNumber!.isNotEmpty,
    ];
    
    score = fields.where((field) => field).length / fields.length;
    return score.clamp(0.0, 1.0);
  }

  /// Get missing fields for completion
  List<String> get missingFields {
    final missing = <String>[];
    
    if (name.isEmpty) missing.add('Naam');
    if (email.isEmpty) missing.add('E-mailadres');
    if (phone == null || phone!.isEmpty) missing.add('Telefoonnummer');
    if (bio == null || bio!.isEmpty) missing.add('Bio/Beschrijving');
    if (profileImageUrl == null || profileImageUrl!.isEmpty) missing.add('Profielfoto');
    if (specialisaties.isEmpty) missing.add('Specialisaties');
    if (certificaten.isEmpty) missing.add('Certificaten');
    if (kvkNumber == null || kvkNumber!.isEmpty) missing.add('KvK Nummer');
    if (postalCode == null || postalCode!.isEmpty) missing.add('Postcode');
    if (wpbrNumber == null || wpbrNumber!.isEmpty) missing.add('WPBR Nummer');
    
    return missing;
  }

  /// Check if profile data has changed compared to another profile
  bool hasChangedFrom(BeveiligerProfielData other) {
    return name != other.name ||
           email != other.email ||
           phone != other.phone ||
           bio != other.bio ||
           profileImageUrl != other.profileImageUrl ||
           !_listEquals(specialisaties, other.specialisaties) ||
           !_listEquals(certificaten, other.certificaten) ||
           kvkNumber != other.kvkNumber ||
           postalCode != other.postalCode ||
           wpbrNumber != other.wpbrNumber ||
           wpbrExpiryDate != other.wpbrExpiryDate;
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  /// Check if WPBR certificate is expiring soon (binnen 30 dagen)
  bool get isWpbrExpiringSoon {
    if (wpbrExpiryDate == null) return false;
    final daysUntilExpiry = wpbrExpiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  /// Get completion percentage van profiel
  double get completionPercentage {
    double completed = 0;
    double total = 11; // Increased to include specializations

    if (name.isNotEmpty) completed++;
    if (email.isNotEmpty) completed++;
    if (phone != null && phone!.isNotEmpty) completed++;
    if (bio != null && bio!.isNotEmpty) completed++;
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) completed++;
    if (specialisaties.isNotEmpty) completed++;
    if (specializations.isNotEmpty) completed++; // New specializations system
    if (certificaten.isNotEmpty) completed++;
    if (kvkNumber != null && kvkNumber!.isNotEmpty) completed++;
    if (postalCode != null && postalCode!.isNotEmpty) completed++;
    if (wpbrNumber != null && wpbrNumber!.isNotEmpty) completed++;

    return (completed / total).clamp(0.0, 1.0);
  }

  /// Get display name voor UI
  String get displayName {
    if (name.isNotEmpty) return name;
    if (email.isNotEmpty) return email.split('@').first;
    return 'Onbekende Gebruiker';
  }

  /// Get formatted phone number
  String? get formattedPhone {
    if (phone == null || phone!.isEmpty) return null;
    
    // Remove non-numeric characters and format Dutch phone numbers
    final cleaned = phone!.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+31')) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 4)} ${cleaned.substring(4, 8)} ${cleaned.substring(8)}';
    } else if (cleaned.startsWith('31') && cleaned.length >= 10) {
      return '+${cleaned.substring(0, 2)} ${cleaned.substring(2, 3)} ${cleaned.substring(3, 7)} ${cleaned.substring(7)}';
    }
    
    return phone;
  }

  // Private helper methods

  /// Validate Dutch phone number format
  bool _isValidDutchPhone(String phone) {
    // Remove all spaces and special characters except +
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check Dutch mobile formats
    if (cleaned.startsWith('+31') && cleaned.length == 12) {
      return RegExp(r'^\+31[67]\d{8}$').hasMatch(cleaned);
    }
    
    // Check Dutch landline formats
    if (cleaned.startsWith('+31') && cleaned.length >= 11 && cleaned.length <= 12) {
      return RegExp(r'^\+31[1-5]\d{7,8}$').hasMatch(cleaned);
    }
    
    // Check local formats
    if (cleaned.startsWith('06') && cleaned.length == 10) {
      return RegExp(r'^06\d{8}$').hasMatch(cleaned);
    }
    
    if (cleaned.startsWith('0') && cleaned.length >= 9 && cleaned.length <= 10) {
      return RegExp(r'^0[1-5]\d{7,8}$').hasMatch(cleaned);
    }
    
    return false;
  }

  @override
  List<Object?> get props => [
    id, name, email, phone, bio, profileImageUrl, specialisaties, specializations, skillLevels, certificaten,
    kvkNumber, postalCode, wpbrNumber, wpbrExpiryDate,
    // KvK 2025 Required Fields
    beveiligingspasnummer, beveiligingspasExpiryDate, eHerkenningLevel, basisDiplomaNumber, 
    basisDiplomaExpiryDate, uniformGoedkeuring, uniformGoedkeuringDetails,
    isVerified, isActive, gdprConsentGiven, lastUpdated, createdAt,
  ];

  @override
  String toString() => 'BeveiligerProfielData(id: $id, name: $name, email: $email)';

  // Helper methods for specializations

  /// Parse specializations from JSON data
  static List<Specialization> _parseSpecializations(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return Specialization.fromJson(item);
        }
        return null;
      }).where((spec) => spec != null).cast<Specialization>().toList();
    }
    return [];
  }

  /// Parse skill levels from JSON data
  static Map<SpecializationType, SkillLevel> _parseSkillLevels(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      final result = <SpecializationType, SkillLevel>{};
      for (final entry in data.entries) {
        try {
          final type = SpecializationType.values.firstWhere(
            (t) => t.name == entry.key,
          );
          final level = SkillLevel.values.firstWhere(
            (l) => l.name == entry.value,
            orElse: () => SkillLevel.beginner,
          );
          result[type] = level;
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }
      return result;
    }
    return {};
  }

  /// Parse eHerkenning level from JSON data
  static EHerkenningLevel _parseEHerkenningLevel(dynamic data) {
    if (data == null) return EHerkenningLevel.none;
    if (data is String) {
      switch (data.toLowerCase()) {
        case 'eh1':
          return EHerkenningLevel.eh1;
        case 'eh2':
          return EHerkenningLevel.eh2;
        case 'eh3':
          return EHerkenningLevel.eh3;
        case 'eh4':
          return EHerkenningLevel.eh4;
        default:
          return EHerkenningLevel.none;
      }
    }
    return EHerkenningLevel.none;
  }

  /// Get all active specializations
  List<Specialization> get activeSpecializations {
    return specializations.where((spec) => spec.isActive).toList();
  }

  /// Get specializations by skill level
  List<Specialization> getSpecializationsBySkillLevel(SkillLevel level) {
    return specializations.where((spec) => spec.skillLevel == level && spec.isActive).toList();
  }

  /// Get expert specializations count
  int get expertSpecializationsCount {
    return getSpecializationsBySkillLevel(SkillLevel.expert).length;
  }


  /// Check if profile is ready for job recommendations
  bool get isReadyForJobRecommendations {
    return hasRequiredFields &&
           specializations.isNotEmpty &&
           certificaten.contains('WPBR Certificaat');
  }

  /// Get job matching compatibility score based on specializations
  double getJobCompatibilityScore(String jobType) {
    if (specializations.isEmpty) return 0.0;
    
    double maxScore = 0.0;
    for (final specialization in specializations) {
      if (specialization.matchesJobCategory(jobType)) {
        double score = specialization.skillLevel.matchingScore / 100.0;
        if (score > maxScore) {
          maxScore = score;
        }
      }
    }

    return maxScore;
  }

  /// Parse DateTime from Firebase data (handles both Timestamp and String)
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    // Handle Firebase Timestamp objects
    if (value is Timestamp) {
      return value.toDate();
    }

    // Handle ISO string format
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }
}

/// Available specialisatie options voor beveiligerspersoneel
class BeveiligerSpecialisaties {
  static const List<String> available = [
    'Evenement Beveiliging',
    'Retail Beveiliging',
    'Kantoor Beveiliging',
    'Toegangscontrole',
    'CCTV Monitoring',
    'Mobiele Surveillance',
    'VIP Beveiliging',
    'Transport Beveiliging',
    'Crowd Control',
    'Nacht Beveiliging',
    'Horeca Beveiliging',
    'Festival Beveiliging',
    'Corporate Security',
    'Airport Security',
    'Healthcare Security',
  ];

  /// Get specialisatie icon voor UI display
  static String getSpecialisatieIcon(String specialisatie) {
    switch (specialisatie) {
      case 'Evenement Beveiliging':
      case 'Festival Beveiliging':
        return '🎪';
      case 'Retail Beveiliging':
        return '🏪';
      case 'Kantoor Beveiliging':
      case 'Corporate Security':
        return '🏢';
      case 'Toegangscontrole':
        return '🚪';
      case 'CCTV Monitoring':
        return '📹';
      case 'Mobiele Surveillance':
        return '🚗';
      case 'VIP Beveiliging':
        return '👔';
      case 'Transport Beveiliging':
        return '🚛';
      case 'Crowd Control':
        return '👥';
      case 'Nacht Beveiliging':
        return '🌙';
      case 'Horeca Beveiliging':
        return '🍽️';
      case 'Airport Security':
        return '✈️';
      case 'Healthcare Security':
        return '🏥';
      default:
        return '🛡️';
    }
  }
}

/// Available certificaat options voor beveiligerspersoneel
class BeveiligerCertificaten {
  static const List<String> available = [
    'WPBR Certificaat',
    'BHV Diploma',
    'EHBO Certificaat',
    'AED Certificaat',
    'Security Awareness Training',
    'Crowd Management Certificate',
    'Fire Safety Certificate',
    'VCA Veiligheid Certificaat',
    'Preventie Medewerker Certificaat',
    'Surveillance Certificate',
    'Access Control Training',
    'Emergency Response Certificate',
    'Risk Assessment Certificate',
    'Communication Skills Training',
    'Conflict De-escalation Training',
  ];

  /// Get certificaat priority voor sorting (hoger getal = belangrijker)
  static int getCertificaatPriority(String certificaat) {
    switch (certificaat) {
      case 'WPBR Certificaat':
        return 10;
      case 'BHV Diploma':
        return 9;
      case 'EHBO Certificaat':
        return 8;
      case 'AED Certificaat':
        return 7;
      case 'VCA Veiligheid Certificaat':
        return 6;
      case 'Security Awareness Training':
        return 5;
      default:
        return 1;
    }
  }

  /// Check if certificaat is mandatory
  static bool isMandatory(String certificaat) {
    return certificaat == 'WPBR Certificaat' ||
           certificaat == 'BHV Diploma' ||
           certificaat == 'EHBO Certificaat';
  }
}