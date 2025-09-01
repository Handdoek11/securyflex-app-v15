/// Profile completion data model for tracking completion status
/// 
/// Integrates with existing Dutch business logic and performance analytics
/// Provides structured data for profile completion tracking widget
class ProfileCompletionData {
  final double completionPercentage;
  final List<MissingProfileElement> missingElements;
  final Map<ProfileElementType, bool> completedElements;
  final DateTime lastUpdated;
  final int totalMilestones;
  final int completedMilestones;
  
  const ProfileCompletionData({
    required this.completionPercentage,
    required this.missingElements,
    required this.completedElements,
    required this.lastUpdated,
    required this.totalMilestones,
    required this.completedMilestones,
  });

  /// Factory constructor for empty/initial state
  factory ProfileCompletionData.empty() {
    return ProfileCompletionData(
      completionPercentage: 0.0,
      missingElements: ProfileElementType.values.map((type) =>
        MissingProfileElement(
          type: type,
          title: _getElementTitle(type),
          description: _getElementDescription(type),
          importance: _getElementImportance(type),
        ),
      ).toList(),
      completedElements: Map.fromEntries(
        ProfileElementType.values.map((type) => MapEntry(type, false)),
      ),
      lastUpdated: DateTime.now(),
      totalMilestones: ProfileElementType.values.length,
      completedMilestones: 0,
    );
  }

  /// Calculate completion percentage based on completed elements
  factory ProfileCompletionData.fromCompletedElements(Map<ProfileElementType, bool> completed) {
    final completedCount = completed.values.where((isCompleted) => isCompleted).length;
    final totalCount = ProfileElementType.values.length;
    final percentage = (completedCount / totalCount) * 100;
    
    final missingElements = ProfileElementType.values
        .where((type) => !(completed[type] ?? false))
        .map((type) => MissingProfileElement(
          type: type,
          title: _getElementTitle(type),
          description: _getElementDescription(type),
          importance: _getElementImportance(type),
        ))
        .toList();
    
    // Sort by importance (highest first)
    missingElements.sort((a, b) => b.importance.compareTo(a.importance));
    
    return ProfileCompletionData(
      completionPercentage: percentage,
      missingElements: missingElements,
      completedElements: completed,
      lastUpdated: DateTime.now(),
      totalMilestones: totalCount,
      completedMilestones: completedCount,
    );
  }

  /// Create copy with updated completion data
  ProfileCompletionData copyWith({
    double? completionPercentage,
    List<MissingProfileElement>? missingElements,
    Map<ProfileElementType, bool>? completedElements,
    DateTime? lastUpdated,
    int? totalMilestones,
    int? completedMilestones,
  }) {
    return ProfileCompletionData(
      completionPercentage: completionPercentage ?? this.completionPercentage,
      missingElements: missingElements ?? this.missingElements,
      completedElements: completedElements ?? this.completedElements,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalMilestones: totalMilestones ?? this.totalMilestones,
      completedMilestones: completedMilestones ?? this.completedMilestones,
    );
  }

  /// Convert to JSON for persistence/API calls
  Map<String, dynamic> toJson() {
    return {
      'completionPercentage': completionPercentage,
      'missingElements': missingElements.map((e) => e.toJson()).toList(),
      'completedElements': completedElements.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'lastUpdated': lastUpdated.toIso8601String(),
      'totalMilestones': totalMilestones,
      'completedMilestones': completedMilestones,
    };
  }

  /// Create from JSON
  factory ProfileCompletionData.fromJson(Map<String, dynamic> json) {
    return ProfileCompletionData(
      completionPercentage: (json['completionPercentage'] as num).toDouble(),
      missingElements: (json['missingElements'] as List<dynamic>)
          .map((e) => MissingProfileElement.fromJson(e as Map<String, dynamic>))
          .toList(),
      completedElements: Map<ProfileElementType, bool>.fromEntries(
        (json['completedElements'] as Map<String, dynamic>).entries.map(
          (entry) => MapEntry(
            ProfileElementType.values.firstWhere(
              (type) => type.toString() == entry.key,
            ),
            entry.value as bool,
          ),
        ),
      ),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      totalMilestones: json['totalMilestones'] as int,
      completedMilestones: json['completedMilestones'] as int,
    );
  }

  /// Check if profile meets minimum completion requirements for job applications
  bool get meetsMinimumRequirements {
    // Dutch security work requires at least basic info, WPBR certificate, and contact info
    return (completedElements[ProfileElementType.basicInfo] ?? false) &&
           (completedElements[ProfileElementType.wpbrCertificate] ?? false) &&
           (completedElements[ProfileElementType.contactInfo] ?? false);
  }

  /// Get completion status message in Dutch
  String get dutchCompletionStatus {
    if (completionPercentage >= 100) {
      return 'Profiel compleet';
    } else if (completionPercentage >= 80) {
      return 'Bijna compleet';
    } else if (completionPercentage >= 60) {
      return 'Goed op weg';
    } else if (completionPercentage >= 40) {
      return 'Basisgegevens aanwezig';
    } else {
      return 'Net begonnen';
    }
  }

  /// Get next recommended action for user
  MissingProfileElement? get nextRecommendedAction {
    return missingElements.isEmpty ? null : missingElements.first;
  }

  static String _getElementTitle(ProfileElementType type) {
    switch (type) {
      case ProfileElementType.basicInfo:
        return 'Basisgegevens';
      case ProfileElementType.certificates:
        return 'Certificaten';
      case ProfileElementType.specializations:
        return 'Specialisaties';
      case ProfileElementType.photo:
        return 'Profielfoto';
      case ProfileElementType.wpbrCertificate:
        return 'WPBR Certificaat';
      case ProfileElementType.contactInfo:
        return 'Contactgegevens';
    }
  }

  static String _getElementDescription(ProfileElementType type) {
    switch (type) {
      case ProfileElementType.basicInfo:
        return 'Naam, geboortedatum en algemene informatie';
      case ProfileElementType.certificates:
        return 'Upload je beveiligingscertificaten';
      case ProfileElementType.specializations:
        return 'Geef je specialisaties en ervaring aan';
      case ProfileElementType.photo:
        return 'Voeg een professionele foto toe';
      case ProfileElementType.wpbrCertificate:
        return 'Verplicht WPBR certificaat voor beveiligingswerk';
      case ProfileElementType.contactInfo:
        return 'Telefoonnummer en e-mailadres';
    }
  }

  static int _getElementImportance(ProfileElementType type) {
    switch (type) {
      case ProfileElementType.wpbrCertificate:
        return 10; // Highest priority - required for all security work
      case ProfileElementType.basicInfo:
        return 9; // Essential information
      case ProfileElementType.contactInfo:
        return 8; // Required for communication
      case ProfileElementType.photo:
        return 6; // Important for trust and recognition
      case ProfileElementType.certificates:
        return 5; // Valuable for specialized jobs
      case ProfileElementType.specializations:
        return 4; // Nice to have for better matching
    }
  }
}

/// Individual missing profile element
class MissingProfileElement {
  final ProfileElementType type;
  final String title;
  final String description;
  final int importance; // 1-10 scale, 10 being most important
  
  const MissingProfileElement({
    required this.type,
    required this.title,
    required this.description,
    required this.importance,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'title': title,
      'description': description,
      'importance': importance,
    };
  }

  /// Create from JSON
  factory MissingProfileElement.fromJson(Map<String, dynamic> json) {
    return MissingProfileElement(
      type: ProfileElementType.values.firstWhere(
        (type) => type.toString() == json['type'],
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      importance: json['importance'] as int,
    );
  }
}

/// Profile element types for tracking completion
enum ProfileElementType {
  basicInfo,        // 25% - Name, birthdate, basic info
  certificates,     // 25% - Security certificates
  specializations,  // 25% - Specializations and experience
  photo,           // 25% - Profile photo
  wpbrCertificate, // Critical - Required WPBR certificate
  contactInfo,     // Critical - Phone and email
}

/// Profile completion milestone events for analytics
enum ProfileCompletionMilestone {
  started,        // 0% - User started profile
  basicComplete,  // 25% - Basic information filled
  halfComplete,   // 50% - Half of profile completed
  nearComplete,   // 75% - Three quarters completed
  fullyComplete,  // 100% - Profile fully completed
  wpbrAdded,      // Special milestone for WPBR certificate
  firstCertificate, // First certificate added
  photoAdded,     // Profile photo added
}

/// Extension for milestone percentage thresholds
extension ProfileCompletionMilestoneExtension on ProfileCompletionMilestone {
  double get percentageThreshold {
    switch (this) {
      case ProfileCompletionMilestone.started:
        return 0.0;
      case ProfileCompletionMilestone.basicComplete:
        return 25.0;
      case ProfileCompletionMilestone.halfComplete:
        return 50.0;
      case ProfileCompletionMilestone.nearComplete:
        return 75.0;
      case ProfileCompletionMilestone.fullyComplete:
        return 100.0;
      case ProfileCompletionMilestone.wpbrAdded:
        return 0.0; // Special milestone, not percentage-based
      case ProfileCompletionMilestone.firstCertificate:
        return 0.0; // Special milestone, not percentage-based
      case ProfileCompletionMilestone.photoAdded:
        return 0.0; // Special milestone, not percentage-based
    }
  }

  String get dutchDescription {
    switch (this) {
      case ProfileCompletionMilestone.started:
        return 'Profiel aangemaakt';
      case ProfileCompletionMilestone.basicComplete:
        return 'Basisgegevens compleet';
      case ProfileCompletionMilestone.halfComplete:
        return 'Profiel voor de helft compleet';
      case ProfileCompletionMilestone.nearComplete:
        return 'Profiel bijna compleet';
      case ProfileCompletionMilestone.fullyComplete:
        return 'Profiel volledig compleet';
      case ProfileCompletionMilestone.wpbrAdded:
        return 'WPBR certificaat toegevoegd';
      case ProfileCompletionMilestone.firstCertificate:
        return 'Eerste certificaat toegevoegd';
      case ProfileCompletionMilestone.photoAdded:
        return 'Profielfoto toegevoegd';
    }
  }
}