import 'dart:io';
import '../../core/bloc/base_bloc.dart';
import '../services/certificate_management_service.dart';

/// Base class for all certificate events in SecuryFlex
abstract class CertificateEvent extends BaseEvent {
  const CertificateEvent();
}

/// Initialize certificate management state
class CertificateInitialize extends CertificateEvent {
  const CertificateInitialize();
}

/// Load all certificates for current user
class CertificateLoadAll extends CertificateEvent {
  final String userId;
  
  const CertificateLoadAll({required this.userId});
  
  @override
  List<Object> get props => [userId];
  
  @override
  String toString() => 'CertificateLoadAll(userId: $userId)';
}

/// Load certificates by type
class CertificateLoadByType extends CertificateEvent {
  final String userId;
  final CertificateType type;
  
  const CertificateLoadByType({
    required this.userId,
    required this.type,
  });
  
  @override
  List<Object> get props => [userId, type];
  
  @override
  String toString() => 'CertificateLoadByType(userId: $userId, type: ${type.code})';
}

/// Add new certificate
class CertificateAdd extends CertificateEvent {
  final String userId;
  final CertificateType type;
  final String certificateNumber;
  final String holderName;
  final String holderBsn;
  final DateTime issueDate;
  final DateTime expirationDate;
  final String issuingAuthority;
  final File? documentFile;
  final Map<String, dynamic>? metadata;
  
  const CertificateAdd({
    required this.userId,
    required this.type,
    required this.certificateNumber,
    required this.holderName,
    required this.holderBsn,
    required this.issueDate,
    required this.expirationDate,
    required this.issuingAuthority,
    this.documentFile,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [
    userId,
    type,
    certificateNumber,
    holderName,
    holderBsn,
    issueDate,
    expirationDate,
    issuingAuthority,
    documentFile?.path,
    metadata,
  ];
  
  @override
  String toString() => 'CertificateAdd(type: ${type.code}, number: $certificateNumber)';
}

/// Update existing certificate
class CertificateUpdate extends CertificateEvent {
  final String certificateId;
  final Map<String, dynamic> updates;
  
  const CertificateUpdate({
    required this.certificateId,
    required this.updates,
  });
  
  @override
  List<Object> get props => [certificateId, updates];
  
  @override
  String toString() => 'CertificateUpdate(id: $certificateId)';
}

/// Delete certificate
class CertificateDelete extends CertificateEvent {
  final String certificateId;
  final bool gdprCompliant;
  
  const CertificateDelete({
    required this.certificateId,
    this.gdprCompliant = true,
  });
  
  @override
  List<Object> get props => [certificateId, gdprCompliant];
  
  @override
  String toString() => 'CertificateDelete(id: $certificateId, gdpr: $gdprCompliant)';
}

/// Verify certificate against external database
class CertificateVerify extends CertificateEvent {
  final String certificateNumber;
  final CertificateType type;
  final String? apiKey;
  
  const CertificateVerify({
    required this.certificateNumber,
    required this.type,
    this.apiKey,
  });
  
  @override
  List<Object?> get props => [certificateNumber, type, apiKey];
  
  @override
  String toString() => 'CertificateVerify(type: ${type.code}, number: $certificateNumber)';
}

/// Check certificate expiration status
class CertificateCheckExpiration extends CertificateEvent {
  final String userId;
  final int warningDaysThreshold;
  
  const CertificateCheckExpiration({
    required this.userId,
    this.warningDaysThreshold = 30,
  });
  
  @override
  List<Object> get props => [userId, warningDaysThreshold];
  
  @override
  String toString() => 'CertificateCheckExpiration(userId: $userId, threshold: $warningDaysThreshold)';
}

/// Upload certificate document
class CertificateUploadDocument extends CertificateEvent {
  final String certificateId;
  final File documentFile;
  final String documentType;
  final Map<String, dynamic>? metadata;
  
  const CertificateUploadDocument({
    required this.certificateId,
    required this.documentFile,
    required this.documentType,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [certificateId, documentFile.path, documentType, metadata];
  
  @override
  String toString() => 'CertificateUploadDocument(id: $certificateId, type: $documentType)';
}

/// Download certificate document
class CertificateDownloadDocument extends CertificateEvent {
  final String certificateId;
  final String documentPath;
  
  const CertificateDownloadDocument({
    required this.certificateId,
    required this.documentPath,
  });
  
  @override
  List<Object> get props => [certificateId, documentPath];
  
  @override
  String toString() => 'CertificateDownloadDocument(id: $certificateId)';
}

/// Match certificates with job requirements
class CertificateMatchJobRequirements extends CertificateEvent {
  final String userId;
  final List<String> requiredCertificates;
  final Map<String, dynamic>? jobMetadata;
  
  const CertificateMatchJobRequirements({
    required this.userId,
    required this.requiredCertificates,
    this.jobMetadata,
  });
  
  @override
  List<Object?> get props => [userId, requiredCertificates, jobMetadata];
  
  @override
  String toString() => 'CertificateMatchJobRequirements(userId: $userId, required: ${requiredCertificates.length})';
}

/// Search certificates
class CertificateSearch extends CertificateEvent {
  final String userId;
  final String? searchQuery;
  final CertificateType? type;
  final Map<String, dynamic>? filters;
  
  const CertificateSearch({
    required this.userId,
    this.searchQuery,
    this.type,
    this.filters,
  });
  
  @override
  List<Object?> get props => [userId, searchQuery, type, filters];
  
  @override
  String toString() => 'CertificateSearch(userId: $userId, query: $searchQuery, type: ${type?.code})';
}

/// Bulk operations on certificates
class CertificateBulkOperation extends CertificateEvent {
  final List<String> certificateIds;
  final String operation; // 'delete', 'archive', 'update', etc.
  final Map<String, dynamic>? operationData;
  
  const CertificateBulkOperation({
    required this.certificateIds,
    required this.operation,
    this.operationData,
  });
  
  @override
  List<Object?> get props => [certificateIds, operation, operationData];
  
  @override
  String toString() => 'CertificateBulkOperation(operation: $operation, count: ${certificateIds.length})';
}

/// Export certificates data
class CertificateExport extends CertificateEvent {
  final String userId;
  final List<String>? certificateIds;
  final String format; // 'json', 'csv', 'pdf'
  final bool includeDocuments;
  
  const CertificateExport({
    required this.userId,
    this.certificateIds,
    required this.format,
    this.includeDocuments = false,
  });
  
  @override
  List<Object?> get props => [userId, certificateIds, format, includeDocuments];
  
  @override
  String toString() => 'CertificateExport(userId: $userId, format: $format, includeDocs: $includeDocuments)';
}

/// Refresh certificate cache
class CertificateRefreshCache extends CertificateEvent {
  final String? userId;
  final CertificateType? type;
  
  const CertificateRefreshCache({
    this.userId,
    this.type,
  });
  
  @override
  List<Object?> get props => [userId, type];
  
  @override
  String toString() => 'CertificateRefreshCache(userId: $userId, type: ${type?.code})';
}

/// Get certificate statistics
class CertificateGetStatistics extends CertificateEvent {
  final String userId;
  final DateTime? fromDate;
  final DateTime? toDate;
  
  const CertificateGetStatistics({
    required this.userId,
    this.fromDate,
    this.toDate,
  });
  
  @override
  List<Object?> get props => [userId, fromDate, toDate];
  
  @override
  String toString() => 'CertificateGetStatistics(userId: $userId)';
}

/// Validate certificate format
class CertificateValidateFormat extends CertificateEvent {
  final String certificateNumber;
  final CertificateType type;
  
  const CertificateValidateFormat({
    required this.certificateNumber,
    required this.type,
  });
  
  @override
  List<Object> get props => [certificateNumber, type];
  
  @override
  String toString() => 'CertificateValidateFormat(type: ${type.code}, number: $certificateNumber)';
}

/// Enhanced WPBR verification with document upload
class CertificateVerifyWPBRWithDocument extends CertificateEvent {
  final String userId;
  final String certificateNumber;
  final File? documentFile;
  final String? apiKey;
  final Map<String, dynamic>? metadata;
  
  const CertificateVerifyWPBRWithDocument({
    required this.userId,
    required this.certificateNumber,
    this.documentFile,
    this.apiKey,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [userId, certificateNumber, documentFile?.path, apiKey, metadata];
  
  @override
  String toString() => 'CertificateVerifyWPBRWithDocument(number: $certificateNumber)';
}

/// Batch verify multiple certificates
class CertificateBatchVerify extends CertificateEvent {
  final String userId;
  final List<String> certificateNumbers;
  final List<CertificateType> types;
  final String? apiKey;
  
  const CertificateBatchVerify({
    required this.userId,
    required this.certificateNumbers,
    required this.types,
    this.apiKey,
  });
  
  @override
  List<Object?> get props => [userId, certificateNumbers, types, apiKey];
  
  @override
  String toString() => 'CertificateBatchVerify(count: ${certificateNumbers.length})';
}

/// Real-time certificate status monitoring
class CertificateStartMonitoring extends CertificateEvent {
  final String userId;
  final List<String> certificateIds;
  final Duration checkInterval;
  
  const CertificateStartMonitoring({
    required this.userId,
    required this.certificateIds,
    this.checkInterval = const Duration(hours: 6),
  });
  
  @override
  List<Object> get props => [userId, certificateIds, checkInterval];
  
  @override
  String toString() => 'CertificateStartMonitoring(count: ${certificateIds.length})';
}

/// Stop certificate monitoring
class CertificateStopMonitoring extends CertificateEvent {
  final String userId;
  
  const CertificateStopMonitoring({required this.userId});
  
  @override
  List<Object> get props => [userId];
  
  @override
  String toString() => 'CertificateStopMonitoring(userId: $userId)';
}

/// Enhanced job requirement check with detailed feedback
class CertificateCheckJobEligibility extends CertificateEvent {
  final String userId;
  final String jobId;
  final Map<String, List<String>> jobRequirements; // Type -> required certs
  final Map<String, dynamic>? jobMetadata;
  
  const CertificateCheckJobEligibility({
    required this.userId,
    required this.jobId,
    required this.jobRequirements,
    this.jobMetadata,
  });
  
  @override
  List<Object?> get props => [userId, jobId, jobRequirements, jobMetadata];
  
  @override
  String toString() => 'CertificateCheckJobEligibility(jobId: $jobId)';
}

/// Clear all certificate data (GDPR compliance)
class CertificateClearAllData extends CertificateEvent {
  final String userId;
  final String reason;
  final bool secureWipe;
  
  const CertificateClearAllData({
    required this.userId,
    required this.reason,
    this.secureWipe = true,
  });
  
  @override
  List<Object> get props => [userId, reason, secureWipe];
  
  @override
  String toString() => 'CertificateClearAllData(userId: $userId, reason: $reason)';
}