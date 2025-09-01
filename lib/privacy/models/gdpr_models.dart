import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// GDPR/AVG Data Subject Rights enumeration
enum DataSubjectRight {
  access('access', 'Recht van Inzage', 'Art. 15 AVG'),
  rectification('rectification', 'Recht op Rectificatie', 'Art. 16 AVG'),
  erasure('erasure', 'Recht op Vergetelheid', 'Art. 17 AVG'),
  restrictProcessing('restrict_processing', 'Recht op Beperking', 'Art. 18 AVG'),
  dataPortability('data_portability', 'Recht op Data Portabiliteit', 'Art. 20 AVG'),
  object('object', 'Recht van Bezwaar', 'Art. 21 AVG');

  const DataSubjectRight(this.value, this.dutchName, this.articleReference);
  
  final String value;
  final String dutchName;
  final String articleReference;
  
  static DataSubjectRight fromString(String value) {
    return DataSubjectRight.values.firstWhere(
      (right) => right.value == value,
      orElse: () => DataSubjectRight.access,
    );
  }
}

/// Processing status for GDPR requests
enum GDPRRequestStatus {
  pending('pending', 'In Behandeling', 'Verzoek wordt verwerkt'),
  underReview('under_review', 'In Beoordeling', 'Juridische controle'),
  inProgress('in_progress', 'Wordt Uitgevoerd', 'Actieve verwerking'),
  completed('completed', 'Voltooid', 'Verzoek afgerond'),
  rejected('rejected', 'Afgewezen', 'Verzoek niet gehonoreerd'),
  partiallyCompleted('partially_completed', 'Gedeeltelijk Voltooid', 'Beperkt mogelijk');

  const GDPRRequestStatus(this.value, this.dutchName, this.description);
  
  final String value;
  final String dutchName;
  final String description;
  
  static GDPRRequestStatus fromString(String value) {
    return GDPRRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => GDPRRequestStatus.pending,
    );
  }
}

/// Lawful basis for data processing under GDPR Art. 6
enum LawfulBasis {
  consent('consent', 'Toestemming', 'Art. 6(1)(a)'),
  contract('contract', 'Contractuele Verplichting', 'Art. 6(1)(b)'),
  legalObligation('legal_obligation', 'Wettelijke Verplichting', 'Art. 6(1)(c)'),
  vitalInterests('vital_interests', 'Vitale Belangen', 'Art. 6(1)(d)'),
  publicTask('public_task', 'Publieke Taak', 'Art. 6(1)(e)'),
  legitimateInterests('legitimate_interests', 'Gerechtvaardigd Belang', 'Art. 6(1)(f)');

  const LawfulBasis(this.value, this.dutchName, this.articleReference);
  
  final String value;
  final String dutchName;
  final String articleReference;
  
  static LawfulBasis fromString(String value) {
    return LawfulBasis.values.firstWhere(
      (basis) => basis.value == value,
      orElse: () => LawfulBasis.consent,
    );
  }
}

/// GDPR Data Subject Request model
class GDPRRequest extends Equatable {
  final String id;
  final String userId;
  final DataSubjectRight requestType;
  final GDPRRequestStatus status;
  final String description;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final String? rejectionReason;
  final Map<String, dynamic>? requestData;
  final Map<String, dynamic>? responseData;
  final List<String> dataCategories;
  final bool isUrgent;
  final String processingNotes;
  
  const GDPRRequest({
    required this.id,
    required this.userId,
    required this.requestType,
    required this.status,
    required this.description,
    required this.createdAt,
    this.processedAt,
    this.completedAt,
    this.rejectionReason,
    this.requestData,
    this.responseData,
    this.dataCategories = const [],
    this.isUrgent = false,
    this.processingNotes = '',
  });

  /// Create from Firestore document
  factory GDPRRequest.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GDPRRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      requestType: DataSubjectRight.fromString(data['requestType'] ?? ''),
      status: GDPRRequestStatus.fromString(data['status'] ?? ''),
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
      requestData: data['requestData'] as Map<String, dynamic>?,
      responseData: data['responseData'] as Map<String, dynamic>?,
      dataCategories: List<String>.from(data['dataCategories'] ?? []),
      isUrgent: data['isUrgent'] ?? false,
      processingNotes: data['processingNotes'] ?? '',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'userId': userId,
      'requestType': requestType.value,
      'status': status.value,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'rejectionReason': rejectionReason,
      'requestData': requestData,
      'responseData': responseData,
      'dataCategories': dataCategories,
      'isUrgent': isUrgent,
      'processingNotes': processingNotes,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// Copy with new values
  GDPRRequest copyWith({
    String? id,
    String? userId,
    DataSubjectRight? requestType,
    GDPRRequestStatus? status,
    String? description,
    DateTime? createdAt,
    DateTime? processedAt,
    DateTime? completedAt,
    String? rejectionReason,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
    List<String>? dataCategories,
    bool? isUrgent,
    String? processingNotes,
  }) {
    return GDPRRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      requestType: requestType ?? this.requestType,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      requestData: requestData ?? this.requestData,
      responseData: responseData ?? this.responseData,
      dataCategories: dataCategories ?? this.dataCategories,
      isUrgent: isUrgent ?? this.isUrgent,
      processingNotes: processingNotes ?? this.processingNotes,
    );
  }

  /// Check if request is within legal timeframe (30 days)
  bool get isWithinTimeframe {
    final deadline = createdAt.add(const Duration(days: 30));
    return DateTime.now().isBefore(deadline);
  }

  /// Days remaining for processing
  int get daysRemaining {
    final deadline = createdAt.add(const Duration(days: 30));
    final difference = deadline.difference(DateTime.now());
    return difference.inDays.clamp(0, 30);
  }

  /// Check if request is overdue
  bool get isOverdue => !isWithinTimeframe && status != GDPRRequestStatus.completed;

  @override
  List<Object?> get props => [
    id,
    userId,
    requestType,
    status,
    description,
    createdAt,
    processedAt,
    completedAt,
    rejectionReason,
    requestData,
    responseData,
    dataCategories,
    isUrgent,
    processingNotes,
  ];
}

/// Consent record for granular consent management
class ConsentRecord extends Equatable {
  final String id;
  final String userId;
  final String purpose;
  final LawfulBasis lawfulBasis;
  final bool isGiven;
  final DateTime timestamp;
  final String? withdrawnAt;
  final String consentMethod; // web, app, phone, etc.
  final String? consentText;
  final Map<String, dynamic> metadata;
  final String version; // Privacy notice version
  
  const ConsentRecord({
    required this.id,
    required this.userId,
    required this.purpose,
    required this.lawfulBasis,
    required this.isGiven,
    required this.timestamp,
    this.withdrawnAt,
    required this.consentMethod,
    this.consentText,
    this.metadata = const {},
    required this.version,
  });

  /// Create from Firestore document
  factory ConsentRecord.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ConsentRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      purpose: data['purpose'] ?? '',
      lawfulBasis: LawfulBasis.fromString(data['lawfulBasis'] ?? ''),
      isGiven: data['isGiven'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      withdrawnAt: data['withdrawnAt'],
      consentMethod: data['consentMethod'] ?? '',
      consentText: data['consentText'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      version: data['version'] ?? '1.0',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'userId': userId,
      'purpose': purpose,
      'lawfulBasis': lawfulBasis.value,
      'isGiven': isGiven,
      'timestamp': Timestamp.fromDate(timestamp),
      'withdrawnAt': withdrawnAt,
      'consentMethod': consentMethod,
      'consentText': consentText,
      'metadata': metadata,
      'version': version,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// Check if consent is still valid (not withdrawn)
  bool get isValid => isGiven && withdrawnAt == null;

  @override
  List<Object?> get props => [
    id,
    userId,
    purpose,
    lawfulBasis,
    isGiven,
    timestamp,
    withdrawnAt,
    consentMethod,
    consentText,
    metadata,
    version,
  ];
}

/// Data retention policy model
class DataRetentionPolicy extends Equatable {
  final String dataType;
  final String category;
  final Duration retentionPeriod;
  final LawfulBasis lawfulBasis;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final Map<String, dynamic> conditions;
  
  const DataRetentionPolicy({
    required this.dataType,
    required this.category,
    required this.retentionPeriod,
    required this.lawfulBasis,
    required this.description,
    this.isActive = true,
    required this.createdAt,
    this.conditions = const {},
  });

  /// Check if data should be deleted based on creation date
  bool shouldDelete(DateTime dataCreationDate) {
    final expiryDate = dataCreationDate.add(retentionPeriod);
    return DateTime.now().isAfter(expiryDate);
  }

  /// Calculate expiry date for given data creation date
  DateTime getExpiryDate(DateTime dataCreationDate) {
    return dataCreationDate.add(retentionPeriod);
  }

  @override
  List<Object?> get props => [
    dataType,
    category,
    retentionPeriod,
    lawfulBasis,
    description,
    isActive,
    createdAt,
    conditions,
  ];
}

/// Dutch specific compliance requirements
class DutchComplianceRequirements {
  /// BSN (Burgerservicenummer) special handling requirements
  static const int bsnRetentionYears = 7;
  
  /// WPBR certificate retention (mandatory 7 years)
  static const int wpbrRetentionYears = 7;
  
  /// CAO particuliere beveiliging requirements
  static const int caoDataRetentionYears = 5;
  
  /// Dutch language requirement level (B1)
  static const String requiredLanguageLevel = 'B1';
  
  /// DigiD integration considerations
  static const List<String> digiDRequiredFields = [
    'bsn',
    'name',
    'birthDate',
    'address',
  ];
  
  /// WPBR certificate validation requirements
  static const List<String> wpbrRequiredCertificates = [
    'beveiligingsmedewerker_2',
    'crowd_control',
    'surveillance_officer',
  ];
}
