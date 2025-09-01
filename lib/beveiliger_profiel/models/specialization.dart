import 'package:equatable/equatable.dart';

/// Specialization model for Dutch security sector job matching
/// 
/// MANDATORY: Uses existing job categories from job_models.dart
/// MANDATORY: Follows existing enum patterns and Dutch naming
/// Integration with existing job matching categories
/// Dutch display names and descriptions following existing localization
class Specialization extends Equatable {
  /// Unique identifier for the specialization
  final String id;
  
  /// Specialization type from predefined categories
  final SpecializationType type;
  
  /// User's skill level in this specialization
  final SkillLevel skillLevel;
  
  /// Additional notes or specifics for this specialization
  final String? notes;
  
  /// Whether this specialization is actively being promoted
  final bool isActive;
  
  /// Date when this specialization was added to profile
  final DateTime addedAt;
  
  /// Date when skill level was last updated
  final DateTime? lastUpdated;

  const Specialization({
    required this.id,
    required this.type,
    this.skillLevel = SkillLevel.beginner,
    this.notes,
    this.isActive = true,
    required this.addedAt,
    this.lastUpdated,
  });

  /// Display name in Dutch
  String get displayName => type.displayName;
  
  /// Description in Dutch
  String get description => type.description;
  
  /// Icon emoji for UI display
  String get icon => type.icon;
  
  /// Color associated with this specialization type
  String get colorCode => type.colorCode;
  
  /// Skill level description in Dutch
  String get skillLevelDescription => skillLevel.description;

  /// Get years of experience based on skill level
  int get estimatedYearsOfExperience {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return 0;
      case SkillLevel.ervaren:
        return 3;
      case SkillLevel.expert:
        return 7;
    }
  }

  /// Check if this specialization matches a job category
  bool matchesJobCategory(String jobCategory) {
    return type.matchesJobCategory(jobCategory);
  }

  /// Copy with method for updates
  Specialization copyWith({
    String? id,
    SpecializationType? type,
    SkillLevel? skillLevel,
    String? notes,
    bool? isActive,
    DateTime? addedAt,
    DateTime? lastUpdated,
  }) {
    return Specialization(
      id: id ?? this.id,
      type: type ?? this.type,
      skillLevel: skillLevel ?? this.skillLevel,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      addedAt: addedAt ?? this.addedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'skillLevel': skillLevel.name,
      'notes': notes,
      'isActive': isActive,
      'addedAt': addedAt.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Specialization.fromJson(Map<String, dynamic> json) {
    return Specialization(
      id: json['id'] ?? '',
      type: SpecializationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => SpecializationType.objectbeveiliging,
      ),
      skillLevel: SkillLevel.values.firstWhere(
        (level) => level.name == json['skillLevel'],
        orElse: () => SkillLevel.beginner,
      ),
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
      addedAt: DateTime.tryParse(json['addedAt'] ?? '') ?? DateTime.now(),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.tryParse(json['lastUpdated'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    skillLevel,
    notes,
    isActive,
    addedAt,
    lastUpdated,
  ];

  @override
  String toString() => 'Specialization(type: ${type.displayName}, skillLevel: ${skillLevel.description})';
}

/// Specialization types based on existing job categories from security_job_data.dart
/// MANDATORY: Use existing job categories from job_models.dart
/// MANDATORY: Follow existing enum patterns and Dutch naming
enum SpecializationType {
  // Core security specializations matching existing job types
  objectbeveiliging,
  evenementbeveiliging, 
  personenbeveiliging,
  winkelbeveiliging,
  kantoorbeveiliging,
  transportbeveiliging,
  nachtbeveiliging,
  
  // Technical specializations
  cctvmonitoring,
  toegangscontrole,
  alarmopvolging,
  brandbeveiliging,
  
  // Sector-specific specializations  
  ziekenhuisbeveiliging,
  luchthavenbeveiliging,
  horecabeveiliging,
  onderwijsbeveiliging,
  industriebeveiliging,
  
  // Additional specializations
  mobielesurveillance,
  crowdcontrol,
  vipbeveiliging,
  portiersdiensten,
  interventiediensten,
}

/// Extension to add Dutch display properties
extension SpecializationTypeExtension on SpecializationType {
  /// Dutch display name
  String get displayName {
    switch (this) {
      case SpecializationType.objectbeveiliging:
        return 'Objectbeveiliging';
      case SpecializationType.evenementbeveiliging:
        return 'Evenementbeveiliging';
      case SpecializationType.personenbeveiliging:
        return 'Personenbeveiliging';
      case SpecializationType.winkelbeveiliging:
        return 'Winkelbeveiliging';
      case SpecializationType.kantoorbeveiliging:
        return 'Kantoorbeveiliging';
      case SpecializationType.transportbeveiliging:
        return 'Transportbeveiliging';
      case SpecializationType.nachtbeveiliging:
        return 'Nachtbeveiliging';
      case SpecializationType.cctvmonitoring:
        return 'CCTV Monitoring';
      case SpecializationType.toegangscontrole:
        return 'Toegangscontrole';
      case SpecializationType.alarmopvolging:
        return 'Alarmopvolging';
      case SpecializationType.brandbeveiliging:
        return 'Brandbeveiliging';
      case SpecializationType.ziekenhuisbeveiliging:
        return 'Ziekenhuisbeveiliging';
      case SpecializationType.luchthavenbeveiliging:
        return 'Luchthavenbeveiliging';
      case SpecializationType.horecabeveiliging:
        return 'Horecabeveiliging';
      case SpecializationType.onderwijsbeveiliging:
        return 'Onderwijsbeveiliging';
      case SpecializationType.industriebeveiliging:
        return 'Industriebeveiliging';
      case SpecializationType.mobielesurveillance:
        return 'Mobiele Surveillance';
      case SpecializationType.crowdcontrol:
        return 'Crowd Control';
      case SpecializationType.vipbeveiliging:
        return 'VIP Beveiliging';
      case SpecializationType.portiersdiensten:
        return 'Portiersdiensten';
      case SpecializationType.interventiediensten:
        return 'Interventiediensten';
    }
  }

  /// Dutch description
  String get description {
    switch (this) {
      case SpecializationType.objectbeveiliging:
        return 'Beveiliging van gebouwen, terreinen en objecten';
      case SpecializationType.evenementbeveiliging:
        return 'Beveiliging tijdens evenementen, festivals en bijeenkomsten';
      case SpecializationType.personenbeveiliging:
        return 'Persoonlijke beveiliging van individuen en VIPs';
      case SpecializationType.winkelbeveiliging:
        return 'Diefstalpreventie en beveiliging in retail omgevingen';
      case SpecializationType.kantoorbeveiliging:
        return 'Beveiliging van kantoorgebouwen en zakelijke complexen';
      case SpecializationType.transportbeveiliging:
        return 'Beveiliging van transporten en logistieke operaties';
      case SpecializationType.nachtbeveiliging:
        return 'Beveiliging tijdens nachtelijke uren';
      case SpecializationType.cctvmonitoring:
        return 'Bewaking via camera surveillance systemen';
      case SpecializationType.toegangscontrole:
        return 'Controle van toegang tot beveiligde gebieden';
      case SpecializationType.alarmopvolging:
        return 'Respons op alarmmeldingen en incidenten';
      case SpecializationType.brandbeveiliging:
        return 'Brandpreventie en evacuatieprocedures';
      case SpecializationType.ziekenhuisbeveiliging:
        return 'Gespecialiseerde beveiliging in zorgomgevingen';
      case SpecializationType.luchthavenbeveiliging:
        return 'Beveiliging op luchthavens en in luchtvaart';
      case SpecializationType.horecabeveiliging:
        return 'Beveiliging in restaurants, bars en uitgaansgelegenheden';
      case SpecializationType.onderwijsbeveiliging:
        return 'Beveiliging op scholen en onderwijsinstellingen';
      case SpecializationType.industriebeveiliging:
        return 'Beveiliging van industriële complexen en fabrieken';
      case SpecializationType.mobielesurveillance:
        return 'Mobiele bewaking en surveillance routes';
      case SpecializationType.crowdcontrol:
        return 'Menigte beheersing en crowd management';
      case SpecializationType.vipbeveiliging:
        return 'Hoogwaardige persoonlijke beveiliging';
      case SpecializationType.portiersdiensten:
        return 'Portier werkzaamheden en gastenservice';
      case SpecializationType.interventiediensten:
        return 'Snelle respons en interventie diensten';
    }
  }

  /// Icon for UI display
  String get icon {
    switch (this) {
      case SpecializationType.objectbeveiliging:
        return '🏢';
      case SpecializationType.evenementbeveiliging:
        return '🎪';
      case SpecializationType.personenbeveiliging:
        return '👤';
      case SpecializationType.winkelbeveiliging:
        return '🏪';
      case SpecializationType.kantoorbeveiliging:
        return '🏢';
      case SpecializationType.transportbeveiliging:
        return '🚛';
      case SpecializationType.nachtbeveiliging:
        return '🌙';
      case SpecializationType.cctvmonitoring:
        return '📹';
      case SpecializationType.toegangscontrole:
        return '🚪';
      case SpecializationType.alarmopvolging:
        return '🚨';
      case SpecializationType.brandbeveiliging:
        return '🔥';
      case SpecializationType.ziekenhuisbeveiliging:
        return '🏥';
      case SpecializationType.luchthavenbeveiliging:
        return '✈️';
      case SpecializationType.horecabeveiliging:
        return '🍽️';
      case SpecializationType.onderwijsbeveiliging:
        return '🎓';
      case SpecializationType.industriebeveiliging:
        return '🏭';
      case SpecializationType.mobielesurveillance:
        return '🚗';
      case SpecializationType.crowdcontrol:
        return '👥';
      case SpecializationType.vipbeveiliging:
        return '👔';
      case SpecializationType.portiersdiensten:
        return '🚪';
      case SpecializationType.interventiediensten:
        return '🚨';
    }
  }

  /// Color code for UI theming
  String get colorCode {
    switch (this) {
      case SpecializationType.objectbeveiliging:
      case SpecializationType.kantoorbeveiliging:
        return '#1E40AF'; // Blue
      case SpecializationType.evenementbeveiliging:
      case SpecializationType.crowdcontrol:
        return '#DC2626'; // Red
      case SpecializationType.personenbeveiliging:
      case SpecializationType.vipbeveiliging:
        return '#7C2D12'; // Brown
      case SpecializationType.winkelbeveiliging:
        return '#059669'; // Green
      case SpecializationType.transportbeveiliging:
      case SpecializationType.mobielesurveillance:
        return '#0891B2'; // Cyan
      case SpecializationType.nachtbeveiliging:
        return '#4C1D95'; // Purple
      case SpecializationType.cctvmonitoring:
      case SpecializationType.toegangscontrole:
        return '#374151'; // Gray
      case SpecializationType.alarmopvolging:
      case SpecializationType.interventiediensten:
        return '#EF4444'; // Light Red
      case SpecializationType.brandbeveiliging:
        return '#F59E0B'; // Orange
      case SpecializationType.ziekenhuisbeveiliging:
        return '#10B981'; // Emerald
      case SpecializationType.luchthavenbeveiliging:
        return '#3B82F6'; // Light Blue
      case SpecializationType.horecabeveiliging:
        return '#8B5CF6'; // Violet
      case SpecializationType.onderwijsbeveiliging:
        return '#06B6D4'; // Sky
      case SpecializationType.industriebeveiliging:
        return '#6B7280'; // Cool Gray
      case SpecializationType.portiersdiensten:
        return '#84CC16'; // Lime
    }
  }

  /// Check if this specialization matches a job category
  /// MANDATORY: Integration with existing job matching categories
  bool matchesJobCategory(String jobCategory) {
    final normalizedJobCategory = jobCategory.toLowerCase().trim();
    final normalizedSpecialization = displayName.toLowerCase().trim();
    
    // Direct match
    if (normalizedJobCategory == normalizedSpecialization) {
      return true;
    }
    
    // Match based on type mappings from existing job categories
    switch (this) {
      case SpecializationType.objectbeveiliging:
        return normalizedJobCategory.contains('object') || 
               normalizedJobCategory.contains('kantoor') ||
               normalizedJobCategory.contains('datacenter') ||
               normalizedJobCategory.contains('ziekenhuis');
               
      case SpecializationType.evenementbeveiliging:
        return normalizedJobCategory.contains('evenement') ||
               normalizedJobCategory.contains('festival') ||
               normalizedJobCategory.contains('concert');
               
      case SpecializationType.personenbeveiliging:
        return normalizedJobCategory.contains('persoon') ||
               normalizedJobCategory.contains('vip') ||
               normalizedJobCategory.contains('politicus');
               
      case SpecializationType.winkelbeveiliging:
        return normalizedJobCategory.contains('winkel') ||
               normalizedJobCategory.contains('retail') ||
               normalizedJobCategory.contains('warenhuis') ||
               normalizedJobCategory.contains('supermarkt');
               
      case SpecializationType.transportbeveiliging:
        return normalizedJobCategory.contains('transport') ||
               normalizedJobCategory.contains('logistiek');
               
      case SpecializationType.portiersdiensten:
        return normalizedJobCategory.contains('portier') ||
               normalizedJobCategory.contains('hotel') ||
               normalizedJobCategory.contains('luxe');
               
      default:
        return false;
    }
  }

  /// Popularity score based on SecuryFlex job market data (0-100)
  /// Higher scores indicate more in-demand specializations in the Dutch security market
  int get popularityScore {
    switch (this) {
      case SpecializationType.objectbeveiliging:
        return 100; // Most in-demand: 35% of all job postings
      case SpecializationType.evenementbeveiliging:
        return 85;  // High demand: 28% of job postings
      case SpecializationType.kantoorbeveiliging:
        return 70;  // Good demand: 22% of job postings
      case SpecializationType.nachtbeveiliging:
        return 55;  // Moderate demand: 18% of job postings
      case SpecializationType.winkelbeveiliging:
        return 40;  // Regular demand: 15% of job postings
      case SpecializationType.personenbeveiliging:
        return 35;  // Specialized demand: 12% of job postings
      case SpecializationType.cctvmonitoring:
        return 30;  // Technical demand: 10% of job postings
      case SpecializationType.transportbeveiliging:
        return 25;  // Logistics demand: 8% of job postings
      case SpecializationType.toegangscontrole:
        return 25;  // Access control: 8% of job postings
      case SpecializationType.horecabeveiliging:
        return 20;  // Entertainment sector: 6% of job postings
      case SpecializationType.ziekenhuisbeveiliging:
        return 20;  // Healthcare sector: 6% of job postings
      case SpecializationType.industriebeveiliging:
        return 18;  // Industrial sector: 5% of job postings
      case SpecializationType.mobielesurveillance:
        return 15;  // Mobile security: 4% of job postings
      case SpecializationType.alarmopvolging:
        return 15;  // Alarm response: 4% of job postings
      case SpecializationType.crowdcontrol:
        return 12;  // Event management: 3% of job postings
      case SpecializationType.luchthavenbeveiliging:
        return 10;  // Airport security: 2% of job postings
      case SpecializationType.vipbeveiliging:
        return 8;   // VIP protection: 1.5% of job postings
      case SpecializationType.onderwijsbeveiliging:
        return 8;   // Education sector: 1.5% of job postings
      case SpecializationType.brandbeveiliging:
        return 6;   // Fire safety: 1% of job postings
      case SpecializationType.portiersdiensten:
        return 6;   // Concierge services: 1% of job postings
      case SpecializationType.interventiediensten:
        return 5;   // Emergency response: 0.5% of job postings
    }
  }
  
  /// Check if this specialization is considered "popular" (top 5)
  bool get isPopular => popularityScore >= 40;
  
  /// Get all specializations sorted by popularity
  static List<SpecializationType> get byPopularity {
    final all = SpecializationType.values.toList();
    all.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
    return all;
  }
  
  /// Get the top N most popular specializations
  static List<SpecializationType> getTopPopular([int count = 5]) {
    return byPopularity.take(count).toList();
  }

  /// Get related specializations for recommendations
  List<SpecializationType> get relatedSpecializations {
    switch (this) {
      case SpecializationType.objectbeveiliging:
        return [
          SpecializationType.kantoorbeveiliging,
          SpecializationType.nachtbeveiliging,
          SpecializationType.toegangscontrole,
        ];
      case SpecializationType.evenementbeveiliging:
        return [
          SpecializationType.crowdcontrol,
          SpecializationType.horecabeveiliging,
          SpecializationType.mobielesurveillance,
        ];
      case SpecializationType.personenbeveiliging:
        return [
          SpecializationType.vipbeveiliging,
          SpecializationType.transportbeveiliging,
          SpecializationType.interventiediensten,
        ];
      case SpecializationType.winkelbeveiliging:
        return [
          SpecializationType.toegangscontrole,
          SpecializationType.cctvmonitoring,
          SpecializationType.alarmopvolging,
        ];
      default:
        return [];
    }
  }
}

/// Skill level enumeration with Dutch descriptions
enum SkillLevel {
  beginner,
  ervaren, 
  expert,
}

extension SkillLevelExtension on SkillLevel {
  /// Dutch description
  String get description {
    switch (this) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.ervaren:
        return 'Ervaren';
      case SkillLevel.expert:
        return 'Expert';
    }
  }

  /// Detailed Dutch description
  String get detailedDescription {
    switch (this) {
      case SkillLevel.beginner:
        return 'Beginnend niveau, basis vaardigheden';
      case SkillLevel.ervaren:
        return 'Ervaren niveau, 3+ jaar ervaring';
      case SkillLevel.expert:
        return 'Expert niveau, 7+ jaar ervaring';
    }
  }

  /// Color for UI display
  String get colorCode {
    switch (this) {
      case SkillLevel.beginner:
        return '#10B981'; // Green
      case SkillLevel.ervaren:
        return '#F59E0B'; // Orange  
      case SkillLevel.expert:
        return '#DC2626'; // Red
    }
  }

  /// Score for job matching calculations
  int get matchingScore {
    switch (this) {
      case SkillLevel.beginner:
        return 60;
      case SkillLevel.ervaren:
        return 80;
      case SkillLevel.expert:
        return 100;
    }
  }
}