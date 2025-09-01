import 'package:equatable/equatable.dart';

/// CertificateMatchingService voor Nederlandse beveiligingscertificaten
/// 
/// Provides comprehensive matching algorithms for Dutch security certificates
/// including WPBR, VCA, BHV and other security qualifications.
/// Implements scoring system for job-certificate compatibility.
class CertificateMatchingService {
  CertificateMatchingService._();
  
  static final CertificateMatchingService _instance = CertificateMatchingService._();
  static CertificateMatchingService get instance => _instance;
  
  /// Match certificates against job requirements with scoring
  /// Returns CertificateMatchResult with detailed analysis
  static CertificateMatchResult matchCertificates(
    List<String> userCertificates,
    List<String> jobRequiredCertificates,
  ) {
    if (jobRequiredCertificates.isEmpty) {
      return CertificateMatchResult(
        matchScore: 100,
        isEligible: true,
        requiredCertificates: [],
        userCertificates: userCertificates,
        matchedCertificates: [],
        missingCertificates: [],
        extraCertificates: userCertificates,
        recommendations: [],
      );
    }
    
    if (userCertificates.isEmpty) {
      return CertificateMatchResult(
        matchScore: 0,
        isEligible: false,
        requiredCertificates: jobRequiredCertificates,
        userCertificates: [],
        matchedCertificates: [],
        missingCertificates: jobRequiredCertificates,
        extraCertificates: [],
        recommendations: _generateRecommendations([], jobRequiredCertificates),
      );
    }
    
    // Normalize certificate names for better matching
    final normalizedUserCerts = userCertificates.map(_normalizeCertificateName).toSet();
    final normalizedRequiredCerts = jobRequiredCertificates.map(_normalizeCertificateName).toSet();
    
    // Find exact matches
    final exactMatches = normalizedRequiredCerts.intersection(normalizedUserCerts);
    
    // Find equivalent matches (e.g., Beveiligingsdiploma A = WPBR A)
    final equivalentMatches = <String>{};
    final remainingRequired = normalizedRequiredCerts.difference(exactMatches);
    final remainingUser = normalizedUserCerts.difference(exactMatches);
    
    for (final required in remainingRequired) {
      for (final user in remainingUser) {
        if (_areEquivalentCertificates(required, user)) {
          equivalentMatches.add(required);
          break;
        }
      }
    }
    
    // Find partial matches (higher level certificates covering lower level requirements)
    final partialMatches = <String>{};
    final stillRequired = remainingRequired.difference(equivalentMatches);
    
    for (final required in stillRequired) {
      for (final user in normalizedUserCerts) {
        if (_isHigherLevelCertificate(user, required)) {
          partialMatches.add(required);
          break;
        }
      }
    }
    
    // Calculate results
    final allMatches = {...exactMatches, ...equivalentMatches, ...partialMatches};
    final missingCerts = normalizedRequiredCerts.difference(allMatches);
    final extraCerts = normalizedUserCerts.difference(normalizedRequiredCerts);
    
    // Calculate match score (0-100)
    final matchScore = _calculateMatchScore(
      totalRequired: normalizedRequiredCerts.length,
      exactMatches: exactMatches.length,
      equivalentMatches: equivalentMatches.length,
      partialMatches: partialMatches.length,
    );
    
    // Determine eligibility (must have all required certificates or equivalents)
    final isEligible = missingCerts.isEmpty || 
                      _hasMinimumRequirements(normalizedUserCerts, normalizedRequiredCerts);
    
    return CertificateMatchResult(
      matchScore: matchScore,
      isEligible: isEligible,
      requiredCertificates: jobRequiredCertificates,
      userCertificates: userCertificates,
      matchedCertificates: allMatches.toList(),
      missingCertificates: missingCerts.map(_denormalizeCertificateName).toList(),
      extraCertificates: extraCerts.map(_denormalizeCertificateName).toList(),
      recommendations: _generateRecommendations(
        normalizedUserCerts.toList(), 
        missingCerts.toList()
      ),
    );
  }
  
  /// Calculate compatibility score between user and job certificates
  static int calculateCompatibilityScore(
    List<String> userCertificates,
    List<String> jobCertificates,
  ) {
    final result = matchCertificates(userCertificates, jobCertificates);
    return result.matchScore;
  }
  
  /// Check if user is eligible for job based on certificates
  static bool isEligibleForJob(
    List<String> userCertificates,
    List<String> jobRequiredCertificates,
  ) {
    final result = matchCertificates(userCertificates, jobRequiredCertificates);
    return result.isEligible;
  }
  
  /// Get certificate recommendations for improving job match
  static List<String> getCertificateRecommendations(
    List<String> userCertificates,
    List<String> targetJobCertificates,
  ) {
    final result = matchCertificates(userCertificates, targetJobCertificates);
    return result.recommendations;
  }
  
  /// Normalize certificate names for consistent matching
  static String _normalizeCertificateName(String certificate) {
    return certificate
        .toLowerCase()
        .replaceAll('diploma', '')
        .replaceAll('certificaat', '')
        .replaceAll('beveiliging', '')
        .replaceAll('bewijs', '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
  
  /// Denormalize certificate name back to readable format
  static String _denormalizeCertificateName(String normalizedCertificate) {
    // This is a simplified reverse mapping - in production use a proper dictionary
    final mapping = {
      'wpbr a': 'WPBR Diploma A',
      'wpbr b': 'WPBR Diploma B',
      'beveiligingsdiploma a': 'Beveiligingsdiploma A',
      'beveiligingsdiploma b': 'Beveiligingsdiploma B',
      'bhv': 'BHV Certificaat',
      'vca': 'VCA Certificaat',
      'portier': 'Portier Diploma',
      'rijbewijs b': 'Rijbewijs B',
      'persoonbeveiliging': 'Persoonbeveiliging Diploma',
    };
    
    return mapping[normalizedCertificate] ?? normalizedCertificate;
  }
  
  /// Check if two certificates are equivalent
  static bool _areEquivalentCertificates(String cert1, String cert2) {
    final equivalents = {
      'wpbr a': ['beveiligingsdiploma a', 'beveiliger a'],
      'wpbr b': ['beveiligingsdiploma b', 'beveiliger b'],
      'bhv': ['bhv certificaat', 'bhv diploma', 'eerste hulp'],
      'vca': ['vca certificaat', 'vca diploma', 'veiligheid certificaat'],
      'portier': ['portier diploma', 'portier certificaat', 'deur beveiliging'],
    };
    
    for (final entry in equivalents.entries) {
      if (entry.key == cert1 && entry.value.contains(cert2)) return true;
      if (entry.key == cert2 && entry.value.contains(cert1)) return true;
    }
    
    return false;
  }
  
  /// Check if one certificate covers requirements of another (higher level)
  static bool _isHigherLevelCertificate(String userCert, String requiredCert) {
    final hierarchy = {
      'wpbr b': ['wpbr a', 'beveiligingsdiploma a'],
      'beveiligingsdiploma b': ['beveiligingsdiploma a', 'wpbr a'],
      'persoonbeveiliging': ['wpbr a', 'wpbr b', 'beveiligingsdiploma a'],
    };
    
    return hierarchy[userCert]?.contains(requiredCert) ?? false;
  }
  
  /// Check if user has minimum requirements even with missing certificates
  static bool _hasMinimumRequirements(Set<String> userCerts, Set<String> requiredCerts) {
    // If user has any B-level certificate, they can handle A-level jobs
    final hasBLevel = userCerts.any((cert) => 
        cert.contains('b') && (cert.contains('wpbr') || cert.contains('beveiliging')));
    
    final requiresOnlyALevel = requiredCerts.every((cert) => 
        cert.contains('a') && (cert.contains('wpbr') || cert.contains('beveiliging')));
    
    return hasBLevel && requiresOnlyALevel;
  }
  
  /// Calculate match score based on certificate matches
  static int _calculateMatchScore({
    required int totalRequired,
    required int exactMatches,
    required int equivalentMatches,
    required int partialMatches,
  }) {
    if (totalRequired == 0) return 100;
    
    // Weight different types of matches
    const exactWeight = 100;
    const equivalentWeight = 95;
    const partialWeight = 80;
    
    final totalScore = (exactMatches * exactWeight) +
                      (equivalentMatches * equivalentWeight) +
                      (partialMatches * partialWeight);
    
    final maxPossibleScore = totalRequired * exactWeight;
    
    return (totalScore * 100 / maxPossibleScore).round().clamp(0, 100);
  }
  
  /// Generate recommendations for missing certificates
  static List<String> _generateRecommendations(
    List<String> userCerts, 
    List<String> missingCerts
  ) {
    final recommendations = <String>[];
    
    for (final missing in missingCerts) {
      if (missing.contains('wpbr') || missing.contains('beveiliging')) {
        if (missing.contains('a')) {
          recommendations.add('Haal je WPBR Diploma A om deze functie uit te kunnen voeren');
        } else if (missing.contains('b')) {
          recommendations.add('Overweeg een upgrade naar WPBR Diploma B voor meer mogelijkheden');
        }
      } else if (missing.contains('bhv')) {
        recommendations.add('Een BHV certificaat is vereist - cursus duurt meestal 1 dag');
      } else if (missing.contains('vca')) {
        recommendations.add('VCA certificaat verplicht voor werkzaamheden op bouwplaatsen');
      } else if (missing.contains('portier')) {
        recommendations.add('Portier diploma nodig voor toegangscontrole werkzaamheden');
      } else if (missing.contains('rijbewijs')) {
        recommendations.add('Rijbewijs B vereist voor deze functie');
      } else {
        recommendations.add('Certificaat "$missing" is vereist voor deze functie');
      }
    }
    
    // Add general recommendations based on user's current certificates
    if (userCerts.isEmpty) {
      recommendations.add('Begin met het behalen van een WPBR Diploma A - dit is de basis voor beveiligingswerk');
    } else if (userCerts.any((cert) => cert.contains('a')) && 
               !userCerts.any((cert) => cert.contains('b'))) {
      recommendations.add('Overweeg een upgrade naar WPBR Diploma B voor toegang tot meer functies');
    }
    
    return recommendations;
  }
  
  /// Get all recognized Nederlandse security certificates
  static List<DutchSecurityCertificate> getAllRecognizedCertificates() {
    return [
      DutchSecurityCertificate(
        name: 'WPBR Diploma A',
        normalizedName: 'wpbr a',
        level: CertificateLevel.basic,
        category: CertificateCategory.security,
        description: 'Basis beveiligingsdiploma voor objectbeveiliging',
        validityPeriod: Duration(days: 1825), // 5 years
      ),
      DutchSecurityCertificate(
        name: 'WPBR Diploma B',
        normalizedName: 'wpbr b',
        level: CertificateLevel.advanced,
        category: CertificateCategory.security,
        description: 'Gevorderd beveiligingsdiploma voor complexe opdrachten',
        validityPeriod: Duration(days: 1825), // 5 years
      ),
      DutchSecurityCertificate(
        name: 'BHV Certificaat',
        normalizedName: 'bhv',
        level: CertificateLevel.basic,
        category: CertificateCategory.safety,
        description: 'Bedrijfshulpverlening certificaat voor eerste hulp',
        validityPeriod: Duration(days: 1095), // 3 years
      ),
      DutchSecurityCertificate(
        name: 'VCA Certificaat',
        normalizedName: 'vca',
        level: CertificateLevel.basic,
        category: CertificateCategory.safety,
        description: 'Veiligheid, Gezondheid en Milieu certificaat',
        validityPeriod: Duration(days: 3650), // 10 years
      ),
      DutchSecurityCertificate(
        name: 'Portier Diploma',
        normalizedName: 'portier',
        level: CertificateLevel.basic,
        category: CertificateCategory.security,
        description: 'Gespecialiseerd diploma voor portier werkzaamheden',
        validityPeriod: Duration(days: 1825), // 5 years
      ),
      DutchSecurityCertificate(
        name: 'Persoonbeveiliging Diploma',
        normalizedName: 'persoonbeveiliging',
        level: CertificateLevel.expert,
        category: CertificateCategory.security,
        description: 'Hoogwaardig diploma voor persoonbeveiliging',
        validityPeriod: Duration(days: 1825), // 5 years
      ),
    ];
  }
  
  /// Filter certificates by category
  static List<DutchSecurityCertificate> getCertificatesByCategory(CertificateCategory category) {
    return getAllRecognizedCertificates()
        .where((cert) => cert.category == category)
        .toList();
  }
  
  /// Filter certificates by level
  static List<DutchSecurityCertificate> getCertificatesByLevel(CertificateLevel level) {
    return getAllRecognizedCertificates()
        .where((cert) => cert.level == level)
        .toList();
  }
  
  /// Validate certificate name
  static bool isValidCertificate(String certificateName) {
    final normalized = _normalizeCertificateName(certificateName);
    return getAllRecognizedCertificates()
        .any((cert) => cert.normalizedName == normalized);
  }
}

/// Result of certificate matching analysis
class CertificateMatchResult extends Equatable {
  /// Match score from 0-100
  final int matchScore;
  
  /// Whether user is eligible for the job
  final bool isEligible;
  
  /// Required certificates for the job
  final List<String> requiredCertificates;
  
  /// User's certificates
  final List<String> userCertificates;
  
  /// Certificates that matched requirements
  final List<String> matchedCertificates;
  
  /// Certificates missing for full qualification
  final List<String> missingCertificates;
  
  /// Extra certificates user has beyond requirements
  final List<String> extraCertificates;
  
  /// Recommendations for improving match
  final List<String> recommendations;
  
  const CertificateMatchResult({
    required this.matchScore,
    required this.isEligible,
    required this.requiredCertificates,
    required this.userCertificates,
    required this.matchedCertificates,
    required this.missingCertificates,
    required this.extraCertificates,
    required this.recommendations,
  });
  
  /// Get match quality description in Dutch
  String get matchQualityDescription {
    if (matchScore >= 90) return 'Uitstekende match';
    if (matchScore >= 75) return 'Goede match';
    if (matchScore >= 50) return 'Redelijke match';
    if (matchScore >= 25) return 'Beperkte match';
    return 'Geen match';
  }
  
  /// Get eligibility description in Dutch
  String get eligibilityDescription {
    if (isEligible) {
      return missingCertificates.isEmpty 
          ? 'Volledig gekwalificeerd'
          : 'Gekwalificeerd met aanbevelingen';
    }
    return 'Niet gekwalificeerd';
  }
  
  @override
  List<Object?> get props => [
    matchScore,
    isEligible,
    requiredCertificates,
    userCertificates,
    matchedCertificates,
    missingCertificates,
    extraCertificates,
    recommendations,
  ];
}

/// Nederlandse security certificate model
class DutchSecurityCertificate extends Equatable {
  final String name;
  final String normalizedName;
  final CertificateLevel level;
  final CertificateCategory category;
  final String description;
  final Duration validityPeriod;
  
  const DutchSecurityCertificate({
    required this.name,
    required this.normalizedName,
    required this.level,
    required this.category,
    required this.description,
    required this.validityPeriod,
  });
  
  @override
  List<Object?> get props => [
    name,
    normalizedName,
    level,
    category,
    description,
    validityPeriod,
  ];
}

/// Certificate level enumeration
enum CertificateLevel {
  basic,
  advanced,
  expert,
}

/// Certificate category enumeration
enum CertificateCategory {
  security,
  safety,
  specialized,
}