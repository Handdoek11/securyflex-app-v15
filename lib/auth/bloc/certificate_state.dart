import '../../core/bloc/base_bloc.dart';
import '../../core/bloc/error_handler.dart';
import '../services/certificate_management_service.dart';

/// Base class for all certificate states in SecuryFlex
abstract class CertificateState extends BaseState {
  const CertificateState();
}

/// Initial certificate state
class CertificateInitial extends CertificateState {
  const CertificateInitial();
}

/// Loading state for certificate operations
class CertificateLoading extends CertificateState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  @override
  final String? loadingMessage;
  
  const CertificateLoading({this.loadingMessage});
  
  @override
  List<Object?> get props => [loadingMessage];
  
  @override
  String get localizedLoadingMessage {
    if (loadingMessage != null) return loadingMessage!;
    return 'Certificaten laden...';
  }
}

/// Certificates loaded successfully
class CertificatesLoaded extends CertificateState with SuccessStateMixin {
  final List<CertificateData> certificates;
  final Map<CertificateType, int> certificateCount;
  final DateTime lastUpdated;
  
  const CertificatesLoaded({
    required this.certificates,
    required this.certificateCount,
    required this.lastUpdated,
  });
  
  @override
  List<Object> get props => [certificates, certificateCount, lastUpdated];
  
  @override
  String get successMessage => 'Certificaten succesvol geladen';
  
  /// Get certificates by type
  List<CertificateData> getCertificatesByType(CertificateType type) {
    return certificates.where((cert) => 
      cert.certificateNumber.startsWith(type.code)).toList();
  }
  
  /// Get expired certificates
  List<CertificateData> get expiredCertificates {
    return certificates.where((cert) => cert.isExpired).toList();
  }
  
  /// Get certificates expiring soon
  List<CertificateData> get certificatesExpiringSoon {
    return certificates.where((cert) => cert.expiresSoon).toList();
  }
  
  /// Get valid certificates
  List<CertificateData> get validCertificates {
    return certificates.where((cert) => cert.isCurrentlyValid).toList();
  }
  
  /// Check if user has valid certificate of specific type
  bool hasValidCertificateOfType(CertificateType type) {
    return certificates.any((cert) => 
      cert.certificateNumber.startsWith(type.code) && cert.isCurrentlyValid);
  }
}

/// Certificate operation completed successfully
class CertificateOperationSuccess extends CertificateState with SuccessStateMixin {
  @override
  final String successMessage;
  
  final String? certificateId;
  final String operation;
  final Map<String, dynamic>? operationData;
  
  const CertificateOperationSuccess({
    required this.successMessage,
    this.certificateId,
    required this.operation,
    this.operationData,
  });
  
  @override
  List<Object?> get props => [successMessage, certificateId, operation, operationData];
  
  /// Get localized success message based on operation
  @override
  String get localizedSuccessMessage {
    switch (operation.toLowerCase()) {
      case 'add':
        return 'Certificaat succesvol toegevoegd';
      case 'update':
        return 'Certificaat succesvol bijgewerkt';
      case 'delete':
        return 'Certificaat succesvol verwijderd';
      case 'upload':
        return 'Document succesvol geüpload';
      case 'verify':
        return 'Certificaat succesvol geverifieerd';
      case 'export':
        return 'Certificaten succesvol geëxporteerd';
      default:
        return successMessage;
    }
  }
}

/// Certificate verification result
class CertificateVerified extends CertificateState with SuccessStateMixin {
  final String certificateNumber;
  final CertificateType type;
  final bool isValid;
  final String verificationStatus;
  final Map<String, dynamic>? verificationData;
  final DateTime verifiedAt;
  
  const CertificateVerified({
    required this.certificateNumber,
    required this.type,
    required this.isValid,
    required this.verificationStatus,
    this.verificationData,
    required this.verifiedAt,
  });
  
  @override
  List<Object?> get props => [
    certificateNumber,
    type,
    isValid,
    verificationStatus,
    verificationData,
    verifiedAt,
  ];
  
  @override
  String get successMessage => isValid 
    ? 'Certificaat is geldig'
    : 'Certificaat verificatie voltooid';
    
  /// Get Dutch verification status
  String get dutchVerificationStatus {
    switch (verificationStatus.toLowerCase()) {
      case 'verified':
      case 'valid':
        return 'Geldig';
      case 'expired':
        return 'Verlopen';
      case 'suspended':
        return 'Geschorst';
      case 'revoked':
        return 'Ingetrokken';
      case 'pending':
        return 'In behandeling';
      default:
        return 'Onbekend';
    }
  }
}

/// Job requirements match result
class CertificateJobMatchResult extends CertificateState with SuccessStateMixin {
  final List<String> requiredCertificates;
  final List<String> matchedCertificates;
  final List<String> missingCertificates;
  final bool isFullMatch;
  final double matchPercentage;
  final Map<String, dynamic>? jobMetadata;
  
  const CertificateJobMatchResult({
    required this.requiredCertificates,
    required this.matchedCertificates,
    required this.missingCertificates,
    required this.isFullMatch,
    required this.matchPercentage,
    this.jobMetadata,
  });
  
  @override
  List<Object?> get props => [
    requiredCertificates,
    matchedCertificates,
    missingCertificates,
    isFullMatch,
    matchPercentage,
    jobMetadata,
  ];
  
  @override
  String get successMessage => isFullMatch 
    ? 'Alle vereiste certificaten aanwezig'
    : 'Gedeeltelijke match: ${matchPercentage.toStringAsFixed(1)}%';
}

/// Certificate search results
class CertificateSearchResults extends CertificateState with SuccessStateMixin {
  final List<CertificateData> results;
  final String? searchQuery;
  final CertificateType? filteredType;
  final Map<String, dynamic>? appliedFilters;
  final int totalCount;
  
  const CertificateSearchResults({
    required this.results,
    this.searchQuery,
    this.filteredType,
    this.appliedFilters,
    required this.totalCount,
  });
  
  @override
  List<Object?> get props => [
    results,
    searchQuery,
    filteredType,
    appliedFilters,
    totalCount,
  ];
  
  @override
  String get successMessage => '${results.length} certificaten gevonden';
}

/// Certificate statistics
class CertificateStatistics extends CertificateState with SuccessStateMixin {
  final int totalCertificates;
  final int validCertificates;
  final int expiredCertificates;
  final int expiringSoon;
  final Map<CertificateType, int> certificatesByType;
  final Map<String, int> certificatesByStatus;
  final DateTime generatedAt;
  
  const CertificateStatistics({
    required this.totalCertificates,
    required this.validCertificates,
    required this.expiredCertificates,
    required this.expiringSoon,
    required this.certificatesByType,
    required this.certificatesByStatus,
    required this.generatedAt,
  });
  
  @override
  List<Object> get props => [
    totalCertificates,
    validCertificates,
    expiredCertificates,
    expiringSoon,
    certificatesByType,
    certificatesByStatus,
    generatedAt,
  ];
  
  @override
  String get successMessage => 'Statistieken gegenereerd';
  
  /// Get certificate validity percentage
  double get validityPercentage {
    if (totalCertificates == 0) return 0.0;
    return (validCertificates / totalCertificates) * 100;
  }
  
  /// Get expiration warning percentage
  double get expirationWarningPercentage {
    if (totalCertificates == 0) return 0.0;
    return (expiringSoon / totalCertificates) * 100;
  }
}

/// Document upload progress
class CertificateDocumentUploading extends CertificateState with LoadingStateMixin {
  @override
  final bool isLoading = true;
  
  final String certificateId;
  final String fileName;
  final double progress;
  
  const CertificateDocumentUploading({
    required this.certificateId,
    required this.fileName,
    required this.progress,
  });
  
  @override
  List<Object> get props => [certificateId, fileName, progress];
  
  @override
  String? get loadingMessage => 'Document uploaden... ${(progress * 100).toStringAsFixed(1)}%';
}

/// Document uploaded successfully
class CertificateDocumentUploaded extends CertificateState with SuccessStateMixin {
  final String certificateId;
  final String fileName;
  final String downloadUrl;
  final int fileSizeBytes;
  final DateTime uploadedAt;
  
  const CertificateDocumentUploaded({
    required this.certificateId,
    required this.fileName,
    required this.downloadUrl,
    required this.fileSizeBytes,
    required this.uploadedAt,
  });
  
  @override
  List<Object> get props => [certificateId, fileName, downloadUrl, fileSizeBytes, uploadedAt];
  
  @override
  String get successMessage => 'Document succesvol geüpload';
  
  /// Get human readable file size
  String get humanReadableFileSize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Certificate export completed
class CertificateExportCompleted extends CertificateState with SuccessStateMixin {
  final String format;
  final String filePath;
  final int certificateCount;
  final int fileSizeBytes;
  final DateTime exportedAt;
  final bool includeDocuments;
  
  const CertificateExportCompleted({
    required this.format,
    required this.filePath,
    required this.certificateCount,
    required this.fileSizeBytes,
    required this.exportedAt,
    required this.includeDocuments,
  });
  
  @override
  List<Object> get props => [format, filePath, certificateCount, fileSizeBytes, exportedAt, includeDocuments];
  
  @override
  String get successMessage => 'Export voltooid: $certificateCount certificaten';
}

/// Certificate validation result
class CertificateFormatValidated extends CertificateState with SuccessStateMixin {
  final String certificateNumber;
  final CertificateType type;
  final bool isValidFormat;
  final List<String> validationErrors;
  final Map<String, dynamic>? validationDetails;
  
  const CertificateFormatValidated({
    required this.certificateNumber,
    required this.type,
    required this.isValidFormat,
    required this.validationErrors,
    this.validationDetails,
  });
  
  @override
  List<Object?> get props => [certificateNumber, type, isValidFormat, validationErrors, validationDetails];
  
  @override
  String get successMessage => isValidFormat 
    ? 'Certificaatformaat is geldig'
    : 'Certificaatformaat validatie voltooid';
}

/// Certificate error state
class CertificateError extends CertificateState with ErrorStateMixin {
  @override
  final AppError error;
  
  final String? certificateId;
  final String? operation;
  
  const CertificateError({
    required this.error,
    this.certificateId,
    this.operation,
  });
  
  @override
  List<Object?> get props => [error, certificateId, operation];
  
  /// Get Dutch error message based on error type
  @override
  String get localizedErrorMessage {
    if (error.code == 'certificate_not_found') {
      return 'Certificaat niet gevonden';
    }
    if (error.code == 'invalid_certificate_format') {
      return 'Ongeldig certificaatformaat';
    }
    if (error.code == 'certificate_expired') {
      return 'Certificaat is verlopen';
    }
    if (error.code == 'document_upload_failed') {
      return 'Document upload mislukt';
    }
    if (error.code == 'verification_failed') {
      return 'Certificaat verificatie mislukt';
    }
    if (error.code == 'insufficient_permissions') {
      return 'Onvoldoende rechten';
    }
    if (error.code == 'rate_limit_exceeded') {
      return 'Te veel verzoeken, probeer later opnieuw';
    }
    if (error.code == 'file_too_large') {
      return 'Bestand is te groot';
    }
    if (error.code == 'unsupported_file_type') {
      return 'Bestandstype niet ondersteund';
    }
    if (error.code == 'network_error') {
      return 'Netwerkfout, controleer je internetverbinding';
    }
    
    return error.localizedMessage;
  }
}

/// Certificate bulk operation completed
class CertificateBulkOperationCompleted extends CertificateState with SuccessStateMixin {
  final String operation;
  final int totalCount;
  final int successCount;
  final int errorCount;
  final List<String> errors;
  final DateTime completedAt;
  
  const CertificateBulkOperationCompleted({
    required this.operation,
    required this.totalCount,
    required this.successCount,
    required this.errorCount,
    required this.errors,
    required this.completedAt,
  });
  
  @override
  List<Object> get props => [operation, totalCount, successCount, errorCount, errors, completedAt];
  
  @override
  String get successMessage => errorCount > 0
    ? 'Bulk operatie voltooid: $successCount/$totalCount succesvol'
    : 'Bulk operatie succesvol voltooid: $successCount certificaten';
}

/// Cache refreshed state
class CertificateCacheRefreshed extends CertificateState with SuccessStateMixin {
  final String? userId;
  final CertificateType? type;
  final DateTime refreshedAt;
  final int itemsRefreshed;
  
  const CertificateCacheRefreshed({
    this.userId,
    this.type,
    required this.refreshedAt,
    required this.itemsRefreshed,
  });
  
  @override
  List<Object?> get props => [userId, type, refreshedAt, itemsRefreshed];
  
  @override
  String get successMessage => 'Cache vernieuwd: $itemsRefreshed items';
}

/// Enhanced WPBR verification result with document analysis
class CertificateWPBRVerified extends CertificateState with SuccessStateMixin {
  final String certificateNumber;
  final bool isValid;
  final String verificationStatus;
  final Map<String, dynamic>? verificationData;
  final String? documentUrl;
  final Map<String, dynamic>? documentAnalysis;
  final DateTime verifiedAt;
  final List<String> authorizations;
  final String issuingAuthority;
  
  const CertificateWPBRVerified({
    required this.certificateNumber,
    required this.isValid,
    required this.verificationStatus,
    this.verificationData,
    this.documentUrl,
    this.documentAnalysis,
    required this.verifiedAt,
    this.authorizations = const [],
    required this.issuingAuthority,
  });
  
  @override
  List<Object?> get props => [
    certificateNumber,
    isValid,
    verificationStatus,
    verificationData,
    documentUrl,
    documentAnalysis,
    verifiedAt,
    authorizations,
    issuingAuthority,
  ];
  
  @override
  String get successMessage => isValid 
    ? 'WPBR certificaat succesvol geverifieerd'
    : 'WPBR certificaat verificatie voltooid';
}

/// Batch verification result
class CertificateBatchVerificationCompleted extends CertificateState with SuccessStateMixin {
  final Map<String, bool> verificationResults; // Certificate number -> isValid
  final Map<String, String> verificationMessages;
  final int totalCount;
  final int validCount;
  final int invalidCount;
  final DateTime completedAt;
  
  const CertificateBatchVerificationCompleted({
    required this.verificationResults,
    required this.verificationMessages,
    required this.totalCount,
    required this.validCount,
    required this.invalidCount,
    required this.completedAt,
  });
  
  @override
  List<Object> get props => [
    verificationResults,
    verificationMessages,
    totalCount,
    validCount,
    invalidCount,
    completedAt,
  ];
  
  @override
  String get successMessage => 'Batch verificatie voltooid: $validCount/$totalCount geldig';
}

/// Certificate monitoring active state
class CertificateMonitoringActive extends CertificateState with SuccessStateMixin {
  final String userId;
  final List<String> monitoredCertificateIds;
  final Duration checkInterval;
  final DateTime startedAt;
  final int totalChecks;
  final DateTime? lastCheckAt;
  
  const CertificateMonitoringActive({
    required this.userId,
    required this.monitoredCertificateIds,
    required this.checkInterval,
    required this.startedAt,
    this.totalChecks = 0,
    this.lastCheckAt,
  });
  
  @override
  List<Object?> get props => [
    userId,
    monitoredCertificateIds,
    checkInterval,
    startedAt,
    totalChecks,
    lastCheckAt,
  ];
  
  @override
  String get successMessage => 'Certificaat monitoring actief voor ${monitoredCertificateIds.length} certificaten';
}

/// Certificate monitoring status update
class CertificateMonitoringUpdate extends CertificateState with SuccessStateMixin {
  final String userId;
  final Map<String, String> statusUpdates; // Certificate ID -> new status
  final List<String> expiredCertificates;
  final List<String> expiringSoonCertificates;
  final DateTime checkedAt;
  
  const CertificateMonitoringUpdate({
    required this.userId,
    required this.statusUpdates,
    required this.expiredCertificates,
    required this.expiringSoonCertificates,
    required this.checkedAt,
  });
  
  @override
  List<Object> get props => [
    userId,
    statusUpdates,
    expiredCertificates,
    expiringSoonCertificates,
    checkedAt,
  ];
  
  @override
  String get successMessage {
    if (expiredCertificates.isNotEmpty) {
      return 'Let op: ${expiredCertificates.length} certificaten zijn verlopen';
    }
    if (expiringSoonCertificates.isNotEmpty) {
      return 'Waarschuwing: ${expiringSoonCertificates.length} certificaten verlopen binnenkort';
    }
    return 'Alle certificaten zijn up-to-date';
  }
}

/// Enhanced job eligibility result with detailed feedback
class CertificateJobEligibilityChecked extends CertificateState with SuccessStateMixin {
  final String userId;
  final String jobId;
  final bool isEligible;
  final double eligibilityScore; // 0.0 to 1.0
  final Map<String, bool> requirementsMet; // Requirement -> is met
  final List<String> missingRequirements;
  final List<String> expiredRequirements;
  final Map<String, DateTime> expirationDates;
  final Map<String, dynamic>? jobMetadata;
  final DateTime checkedAt;
  
  const CertificateJobEligibilityChecked({
    required this.userId,
    required this.jobId,
    required this.isEligible,
    required this.eligibilityScore,
    required this.requirementsMet,
    required this.missingRequirements,
    required this.expiredRequirements,
    required this.expirationDates,
    this.jobMetadata,
    required this.checkedAt,
  });
  
  @override
  List<Object?> get props => [
    userId,
    jobId,
    isEligible,
    eligibilityScore,
    requirementsMet,
    missingRequirements,
    expiredRequirements,
    expirationDates,
    jobMetadata,
    checkedAt,
  ];
  
  @override
  String get successMessage => isEligible 
    ? 'Je bent geschikt voor deze functie'
    : 'Je voldoet gedeeltelijk aan de vereisten (${(eligibilityScore * 100).toStringAsFixed(1)}%)';
    
  /// Get action items for improving eligibility
  List<String> get actionItems {
    final actions = <String>[];
    
    if (missingRequirements.isNotEmpty) {
      actions.add('Benodigde certificaten: ${missingRequirements.join(', ')}');
    }
    
    if (expiredRequirements.isNotEmpty) {
      actions.add('Certificaten vernieuwen: ${expiredRequirements.join(', ')}');
    }
    
    return actions;
  }
}

/// Data cleared state (GDPR compliance)
class CertificateDataCleared extends CertificateState with SuccessStateMixin {
  final String userId;
  final String reason;
  final int itemsCleared;
  final DateTime clearedAt;
  final bool secureWipeCompleted;
  
  const CertificateDataCleared({
    required this.userId,
    required this.reason,
    required this.itemsCleared,
    required this.clearedAt,
    required this.secureWipeCompleted,
  });
  
  @override
  List<Object> get props => [userId, reason, itemsCleared, clearedAt, secureWipeCompleted];
  
  @override
  String get successMessage => 'Alle certificaatgegevens succesvol verwijderd';
}