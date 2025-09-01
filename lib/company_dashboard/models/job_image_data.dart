import 'package:cloud_firestore/cloud_firestore.dart';

/// Job image data model for enhanced job postings with visual content
/// Premium Enterprise Solution - Nederlandse security marketplace compliant
class JobImageData {
  final String imageId;
  final String jobId;
  final String originalUrl;
  final String thumbnailUrl;
  final String? smallUrl;      // 300x200
  final String? mediumUrl;     // 600x400
  final String? largeUrl;      // 1200x800
  final String? webpUrl;       // WebP format voor moderne browsers
  final ImageMetadata metadata;
  final ImageAnalysisData? analysis;
  final DateTime uploadedAt;
  final String uploadedBy;
  final bool isPrimary;        // Hoofdafbeelding voor job card
  final int displayOrder;
  final ImageStatus status;
  final Map<String, dynamic>? securityTags;

  const JobImageData({
    required this.imageId,
    required this.jobId,
    required this.originalUrl,
    required this.thumbnailUrl,
    this.smallUrl,
    this.mediumUrl,
    this.largeUrl,
    this.webpUrl,
    required this.metadata,
    this.analysis,
    required this.uploadedAt,
    required this.uploadedBy,
    this.isPrimary = false,
    this.displayOrder = 0,
    this.status = ImageStatus.processing,
    this.securityTags,
  });

  /// Create from Firebase document
  factory JobImageData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return JobImageData(
      imageId: doc.id,
      jobId: data['jobId'] ?? '',
      originalUrl: data['originalUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      smallUrl: data['smallUrl'],
      mediumUrl: data['mediumUrl'],
      largeUrl: data['largeUrl'],
      webpUrl: data['webpUrl'],
      metadata: ImageMetadata.fromMap(data['metadata'] ?? {}),
      analysis: data['analysis'] != null 
          ? ImageAnalysisData.fromMap(data['analysis']) 
          : null,
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      uploadedBy: data['uploadedBy'] ?? '',
      isPrimary: data['isPrimary'] ?? false,
      displayOrder: data['displayOrder'] ?? 0,
      status: ImageStatus.values.firstWhere(
        (s) => s.toString().split('.').last == data['status'],
        orElse: () => ImageStatus.processing,
      ),
      securityTags: data['securityTags'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'originalUrl': originalUrl,
      'thumbnailUrl': thumbnailUrl,
      'smallUrl': smallUrl,
      'mediumUrl': mediumUrl,
      'largeUrl': largeUrl,
      'webpUrl': webpUrl,
      'metadata': metadata.toMap(),
      'analysis': analysis?.toMap(),
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': uploadedBy,
      'isPrimary': isPrimary,
      'displayOrder': displayOrder,
      'status': status.toString().split('.').last,
      'securityTags': securityTags,
      'lastModified': FieldValue.serverTimestamp(),
    };
  }

  /// Get optimal URL based on device/context
  String getOptimalUrl({
    required ImageSize size,
    bool preferWebP = false,
  }) {
    if (preferWebP && webpUrl != null) {
      return webpUrl!;
    }

    switch (size) {
      case ImageSize.thumbnail:
        return thumbnailUrl;
      case ImageSize.small:
        return smallUrl ?? thumbnailUrl;
      case ImageSize.medium:
        return mediumUrl ?? smallUrl ?? originalUrl;
      case ImageSize.large:
        return largeUrl ?? mediumUrl ?? originalUrl;
      case ImageSize.original:
        return originalUrl;
    }
  }

  /// Copy with updates
  JobImageData copyWith({
    String? imageId,
    String? jobId,
    String? originalUrl,
    String? thumbnailUrl,
    String? smallUrl,
    String? mediumUrl,
    String? largeUrl,
    String? webpUrl,
    ImageMetadata? metadata,
    ImageAnalysisData? analysis,
    DateTime? uploadedAt,
    String? uploadedBy,
    bool? isPrimary,
    int? displayOrder,
    ImageStatus? status,
    Map<String, dynamic>? securityTags,
  }) {
    return JobImageData(
      imageId: imageId ?? this.imageId,
      jobId: jobId ?? this.jobId,
      originalUrl: originalUrl ?? this.originalUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      smallUrl: smallUrl ?? this.smallUrl,
      mediumUrl: mediumUrl ?? this.mediumUrl,
      largeUrl: largeUrl ?? this.largeUrl,
      webpUrl: webpUrl ?? this.webpUrl,
      metadata: metadata ?? this.metadata,
      analysis: analysis ?? this.analysis,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      isPrimary: isPrimary ?? this.isPrimary,
      displayOrder: displayOrder ?? this.displayOrder,
      status: status ?? this.status,
      securityTags: securityTags ?? this.securityTags,
    );
  }
}

/// Image metadata for technical details
class ImageMetadata {
  final int width;
  final int height;
  final int sizeInBytes;
  final String mimeType;
  final String? fileName;
  final String? cameraModel;
  final DateTime? takenAt;
  final Map<String, dynamic>? exifData;
  final double? latitude;
  final double? longitude;

  const ImageMetadata({
    required this.width,
    required this.height,
    required this.sizeInBytes,
    required this.mimeType,
    this.fileName,
    this.cameraModel,
    this.takenAt,
    this.exifData,
    this.latitude,
    this.longitude,
  });

  factory ImageMetadata.fromMap(Map<String, dynamic> map) {
    return ImageMetadata(
      width: map['width'] ?? 0,
      height: map['height'] ?? 0,
      sizeInBytes: map['sizeInBytes'] ?? 0,
      mimeType: map['mimeType'] ?? 'image/jpeg',
      fileName: map['fileName'],
      cameraModel: map['cameraModel'],
      takenAt: map['takenAt'] != null 
          ? DateTime.parse(map['takenAt']) 
          : null,
      exifData: map['exifData'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      'sizeInBytes': sizeInBytes,
      'mimeType': mimeType,
      'fileName': fileName,
      'cameraModel': cameraModel,
      'takenAt': takenAt?.toIso8601String(),
      'exifData': exifData,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Get formatted file size
  String get formattedSize {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get aspect ratio
  double get aspectRatio => width / height;

  /// Check if image is landscape
  bool get isLandscape => width > height;

  /// Check if image is portrait
  bool get isPortrait => height > width;

  /// Check if image is square
  bool get isSquare => width == height;
}

/// AI-powered image analysis results
class ImageAnalysisData {
  final List<String> detectedObjects;
  final List<String> suggestedTags;
  final SecurityRelevanceScore relevanceScore;
  final LocationTypeClassification? locationType;
  final double imageQualityScore;
  final bool hasSecurityEquipment;
  final bool hasAccessPoints;
  final bool hasCrowds;
  final String? dominantColor;
  final Map<String, double>? colorPalette;
  final List<String>? textDetected;
  final double? brightnesLevel;
  final double? contrastLevel;

  const ImageAnalysisData({
    this.detectedObjects = const [],
    this.suggestedTags = const [],
    required this.relevanceScore,
    this.locationType,
    this.imageQualityScore = 0.0,
    this.hasSecurityEquipment = false,
    this.hasAccessPoints = false,
    this.hasCrowds = false,
    this.dominantColor,
    this.colorPalette,
    this.textDetected,
    this.brightnesLevel,
    this.contrastLevel,
  });

  factory ImageAnalysisData.fromMap(Map<String, dynamic> map) {
    return ImageAnalysisData(
      detectedObjects: List<String>.from(map['detectedObjects'] ?? []),
      suggestedTags: List<String>.from(map['suggestedTags'] ?? []),
      relevanceScore: SecurityRelevanceScore.values.firstWhere(
        (s) => s.toString().split('.').last == map['relevanceScore'],
        orElse: () => SecurityRelevanceScore.medium,
      ),
      locationType: map['locationType'] != null
          ? LocationTypeClassification.fromMap(map['locationType'])
          : null,
      imageQualityScore: map['imageQualityScore']?.toDouble() ?? 0.0,
      hasSecurityEquipment: map['hasSecurityEquipment'] ?? false,
      hasAccessPoints: map['hasAccessPoints'] ?? false,
      hasCrowds: map['hasCrowds'] ?? false,
      dominantColor: map['dominantColor'],
      colorPalette: map['colorPalette'] != null
          ? Map<String, double>.from(map['colorPalette'])
          : null,
      textDetected: map['textDetected'] != null
          ? List<String>.from(map['textDetected'])
          : null,
      brightnesLevel: map['brightnesLevel']?.toDouble(),
      contrastLevel: map['contrastLevel']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'detectedObjects': detectedObjects,
      'suggestedTags': suggestedTags,
      'relevanceScore': relevanceScore.toString().split('.').last,
      'locationType': locationType?.toMap(),
      'imageQualityScore': imageQualityScore,
      'hasSecurityEquipment': hasSecurityEquipment,
      'hasAccessPoints': hasAccessPoints,
      'hasCrowds': hasCrowds,
      'dominantColor': dominantColor,
      'colorPalette': colorPalette,
      'textDetected': textDetected,
      'brightnesLevel': brightnesLevel,
      'contrastLevel': contrastLevel,
    };
  }

  /// Get security insights summary
  String getSecurityInsights() {
    final insights = <String>[];
    
    if (hasSecurityEquipment) {
      insights.add('Beveiligingsapparatuur gedetecteerd');
    }
    if (hasAccessPoints) {
      insights.add('Toegangspunten zichtbaar');
    }
    if (hasCrowds) {
      insights.add('Drukte gedetecteerd - extra beveiligers mogelijk nodig');
    }
    
    if (locationType != null) {
      insights.add('Locatietype: ${locationType!.displayName}');
    }
    
    return insights.join(' • ');
  }
}

/// Location type classification from AI
class LocationTypeClassification {
  final LocationType type;
  final double confidence;
  final String displayName;
  final List<String> characteristics;

  const LocationTypeClassification({
    required this.type,
    required this.confidence,
    required this.displayName,
    this.characteristics = const [],
  });

  factory LocationTypeClassification.fromMap(Map<String, dynamic> map) {
    return LocationTypeClassification(
      type: LocationType.values.firstWhere(
        (t) => t.toString().split('.').last == map['type'],
        orElse: () => LocationType.unknown,
      ),
      confidence: map['confidence']?.toDouble() ?? 0.0,
      displayName: map['displayName'] ?? 'Onbekend',
      characteristics: List<String>.from(map['characteristics'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'confidence': confidence,
      'displayName': displayName,
      'characteristics': characteristics,
    };
  }
}

/// Enums for image management

enum ImageStatus {
  uploading,
  processing,
  ready,
  failed,
  deleted,
}

enum ImageSize {
  thumbnail,
  small,
  medium,
  large,
  original,
}

enum SecurityRelevanceScore {
  low,
  medium,
  high,
  critical,
}

enum LocationType {
  office,
  retail,
  industrial,
  event,
  residential,
  publicSpace,
  transport,
  healthcare,
  education,
  entertainment,
  construction,
  unknown,
}

/// Extension for Dutch localization
extension LocationTypeExtension on LocationType {
  String get dutchName {
    switch (this) {
      case LocationType.office:
        return 'Kantoor';
      case LocationType.retail:
        return 'Winkel';
      case LocationType.industrial:
        return 'Industrieel';
      case LocationType.event:
        return 'Evenement';
      case LocationType.residential:
        return 'Woonwijk';
      case LocationType.publicSpace:
        return 'Openbare Ruimte';
      case LocationType.transport:
        return 'Transport';
      case LocationType.healthcare:
        return 'Gezondheidszorg';
      case LocationType.education:
        return 'Onderwijs';
      case LocationType.entertainment:
        return 'Entertainment';
      case LocationType.construction:
        return 'Bouwplaats';
      case LocationType.unknown:
        return 'Onbekend';
    }
  }
}