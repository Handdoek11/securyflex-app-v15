/// Dutch localization for job completion rating system
/// 
/// Follows existing localization patterns from company_nl.dart and team_management_nl.dart
/// Provides consistent Dutch terminology for rating functionality
class JobCompletionRatingLocalizationNL {
  // Rating widget texts
  static const String ratingTitle = 'Beoordeel je samenwerking';
  static const String ratingSubtitleGuard = 'Geef een eerlijke beoordeling van de samenwerking met dit bedrijf voor deze opdracht.';
  static const String ratingSubtitleCompany = 'Geef een eerlijke beoordeling van de samenwerking met deze beveiliger voor deze opdracht.';
  
  // Rating section
  static const String ratingInstructions = 'Geef een cijfer (1-5 sterren)';
  static const String commentsLabel = 'Opmerkingen (optioneel)';
  static const String commentsHint = 'Deel je ervaring met deze opdracht...';
  
  // Rating descriptions (following existing patterns)
  static const Map<int, String> ratingDescriptions = {
    5: 'Uitstekend!',
    4: 'Goed',
    3: 'Voldoende',
    2: 'Matig',
    1: 'Onvoldoende',
  };
  
  // Button texts
  static const String submitButton = 'Beoordeling indienen';
  static const String submittingButton = 'Beoordeling indienen...';
  
  // Status messages
  static const String ratingSubmitted = 'Beoordeling succesvol ingediend!';
  static const String ratingError = 'Er is een fout opgetreden bij het indienen van de beoordeling';
  static const String invalidRating = 'Beoordeling moet tussen 1 en 5 sterren zijn';
  static const String invalidRole = 'Ongeldige gebruikersrol';
  
  // Job completion screen texts
  static const String screenTitle = 'Opdracht voltooien';
  static const String jobSummaryTitle = 'Opdracht overzicht';
  static const String workflowStatusTitle = 'Status';
  static const String ratingRequiredTitle = 'Beoordeling vereist';
  
  // Job summary fields
  static const String jobIdLabel = 'Opdracht ID';
  static const String companyLabel = 'Opdrachtgever';
  static const String guardLabel = 'Beveiliger';
  static const String notAvailable = 'Niet beschikbaar';
  static const String securityJob = 'Beveiligingsopdracht';
  
  // Next steps messages
  static const String nextStepRating = 'Beoordeel je samenwerking om door te gaan';
  static const String nextStepPayment = 'Wachten op betaling verwerking';
  static const String nextStepCompleted = 'Opdracht succesvol afgerond!';
  static const String nextStepUpdating = 'Status wordt bijgewerkt...';
  
  // Completion messages
  static const String ratingCompleted = 'Beoordeling voltooid! Je wordt op de hoogte gehouden van de betaling.';
  
  // Profile integration texts (extending existing ProfileStatsData patterns)
  static const String averageRatingLabel = 'Gemiddelde beoordeling';
  static const String totalRatingsLabel = 'Aantal beoordelingen';
  static const String lastRatingLabel = 'Laatste beoordeling';
  static const String ratingHistoryLabel = 'Beoordelingen geschiedenis';
  
  // Rating categories (following existing PerformanceCategory patterns)
  static const Map<String, String> performanceCategories = {
    'excellent': 'Uitstekend',
    'good': 'Goed', 
    'satisfactory': 'Voldoende',
    'needsImprovement': 'Kan beter',
  };
  
  // Rating advice (following existing pattern)
  static const Map<String, String> performanceAdvice = {
    'excellent': 'Uitstekend werk! Je bent een topbeveiliger.',
    'good': 'Sterke prestaties! Behoud dit niveau.',
    'satisfactory': 'Je doet het goed! Probeer je beoordelingen te verbeteren.',
    'needsImprovement': 'Focus op het verbeteren van je beoordelingen en voltooiingspercentage.',
  };
  
  // Error messages
  static const Map<String, String> errorMessages = {
    'RATING_FAILED': 'Fout bij het indienen van beoordeling',
    'RATING_EXCEPTION': 'Er is een onverwachte fout opgetreden',
    'NETWORK_ERROR': 'Netwerkfout, controleer je internetverbinding',
    'PERMISSION_DENIED': 'Je hebt geen toestemming om deze beoordeling in te dienen',
    'ALREADY_RATED': 'Je hebt deze opdracht al beoordeeld',
    'INVALID_WORKFLOW': 'Ongeldige workflow status',
  };
  
  // Validation messages
  static const Map<String, String> validationMessages = {
    'rating_required': 'Selecteer een beoordeling',
    'rating_range': 'Beoordeling moet tussen 1 en 5 sterren zijn',
    'comments_length': 'Opmerkingen mogen maximaal 500 karakters bevatten',
    'invalid_user': 'Ongeldige gebruiker',
    'missing_workflow': 'Workflow informatie ontbreekt',
  };
  
  // Helper method to get rating description
  static String getRatingDescription(double rating) {
    if (rating >= 5.0) return ratingDescriptions[5]!;
    if (rating >= 4.0) return ratingDescriptions[4]!;
    if (rating >= 3.0) return ratingDescriptions[3]!;
    if (rating >= 2.0) return ratingDescriptions[2]!;
    return ratingDescriptions[1]!;
  }
  
  // Helper method to get performance category
  static String getPerformanceCategory(double averageRating, double completionRate) {
    if (averageRating >= 4.5 && completionRate >= 95) {
      return performanceCategories['excellent']!;
    } else if (averageRating >= 4.0 && completionRate >= 85) {
      return performanceCategories['good']!;
    } else if (averageRating >= 3.5 && completionRate >= 75) {
      return performanceCategories['satisfactory']!;
    } else {
      return performanceCategories['needsImprovement']!;
    }
  }
  
  // Helper method to get performance advice
  static String getPerformanceAdvice(double averageRating, double completionRate) {
    if (averageRating >= 4.5 && completionRate >= 95) {
      return performanceAdvice['excellent']!;
    } else if (averageRating >= 4.0 && completionRate >= 85) {
      return performanceAdvice['good']!;
    } else if (averageRating >= 3.5 && completionRate >= 75) {
      return performanceAdvice['satisfactory']!;
    } else {
      return performanceAdvice['needsImprovement']!;
    }
  }
  
  // Format rating display
  static String formatRating(double rating) {
    return '${rating.toStringAsFixed(1)} sterren';
  }
  
  // Format rating count
  static String formatRatingCount(int count) {
    if (count == 0) return 'Geen beoordelingen';
    if (count == 1) return '1 beoordeling';
    return '$count beoordelingen';
  }
}