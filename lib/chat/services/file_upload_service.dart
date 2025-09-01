import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';

/// WhatsApp-quality file upload service with progressive upload and validation
/// Follows SecuryFlex patterns with Dutch localization
class FileUploadService {
  static FileUploadService? _instance;
  static FileUploadService get instance {
    _instance ??= FileUploadService._();
    return _instance!;
  }

  FileUploadService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // File size limits (in bytes)
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB

  // Allowed file types
  static const List<String> allowedImageTypes = [
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'
  ];
  static const List<String> allowedDocumentTypes = [
    'pdf', 'doc', 'docx', 'txt', 'rtf', 'xlsx', 'xls', 'pptx', 'ppt'
  ];
  static const List<String> allowedVideoTypes = [
    'mp4', 'mov', 'avi', 'mkv', 'webm'
  ];

  /// Upload file with progress tracking and validation
  Future<FileUploadResult> uploadFile({
    required String filePath,
    required String conversationId,
    required String fileName,
    Function(double progress)? onProgress,
    Function(String thumbnailUrl)? onThumbnailGenerated,
  }) async {
    try {
      // Validate file
      final validationResult = await _validateFile(filePath, fileName);
      if (!validationResult.isValid) {
        return FileUploadResult.failure(validationResult.errorMessage!);
      }

      final file = File(filePath);
      final fileExtension = path.extension(fileName).toLowerCase().substring(1);
      final fileType = _getFileType(fileExtension);
      
      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final hash = _generateFileHash(await file.readAsBytes());
      final uniqueFileName = '${timestamp}_${hash}_$fileName';
      
      // Create storage reference
      final storageRef = _storage
          .ref()
          .child('chat-files')
          .child(conversationId)
          .child(fileType.name)
          .child(uniqueFileName);

      // Generate thumbnail for images
      String? thumbnailUrl;
      if (fileType == FileType.image) {
        thumbnailUrl = await _generateAndUploadThumbnail(
          filePath,
          conversationId,
          uniqueFileName,
        );
        onThumbnailGenerated?.call(thumbnailUrl);
      }

      // Upload main file with progress tracking
      final uploadTask = storageRef.putFile(file);
      
      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Wait for upload completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Get file metadata
      final metadata = await snapshot.ref.getMetadata();

      return FileUploadResult.success(
        fileUrl: downloadUrl,
        thumbnailUrl: thumbnailUrl,
        fileName: fileName,
        fileSize: metadata.size ?? 0,
        mimeType: metadata.contentType ?? 'application/octet-stream',
        fileType: fileType,
      );
    } catch (e) {
      return FileUploadResult.failure('Fout bij uploaden bestand: ${e.toString()}');
    }
  }

  /// Generate and upload thumbnail for images
  Future<String> _generateAndUploadThumbnail(
    String imagePath,
    String conversationId,
    String fileName,
  ) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Kan afbeelding niet decoderen');
      }

      // Generate thumbnail (max 300x300)
      final thumbnail = img.copyResize(
        image,
        width: image.width > image.height ? 300 : null,
        height: image.height > image.width ? 300 : null,
      );

      // Encode as JPEG with compression
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);

      // Upload thumbnail
      final thumbnailRef = _storage
          .ref()
          .child('chat-files')
          .child(conversationId)
          .child('thumbnails')
          .child('thumb_$fileName');

      await thumbnailRef.putData(
        Uint8List.fromList(thumbnailBytes),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await thumbnailRef.getDownloadURL();
    } catch (e) {
      throw Exception('Fout bij genereren thumbnail: ${e.toString()}');
    }
  }

  /// Validate file before upload
  Future<FileValidationResult> _validateFile(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      
      // Check if file exists
      if (!await file.exists()) {
        return FileValidationResult.invalid('Bestand niet gevonden');
      }

      // Get file size
      final fileSize = await file.length();
      
      // Get file extension
      final fileExtension = path.extension(fileName).toLowerCase().substring(1);
      
      // Check file type
      final fileType = _getFileType(fileExtension);
      if (fileType == FileType.unknown) {
        return FileValidationResult.invalid(
          'Bestandstype niet ondersteund. Toegestane types: ${_getAllowedExtensions().join(', ')}'
        );
      }

      // Check file size limits
      final maxSize = _getMaxFileSize(fileType);
      if (fileSize > maxSize) {
        return FileValidationResult.invalid(
          'Bestand te groot. Maximum: ${_formatFileSize(maxSize)}'
        );
      }

      // Additional validation for images
      if (fileType == FileType.image) {
        final validationResult = await _validateImage(filePath);
        if (!validationResult.isValid) {
          return validationResult;
        }
      }

      return FileValidationResult.valid(
        fileSize: fileSize,
        fileType: fileType,
        mimeType: _getMimeType(fileExtension),
      );
    } catch (e) {
      return FileValidationResult.invalid('Fout bij valideren bestand: ${e.toString()}');
    }
  }

  /// Validate image file
  Future<FileValidationResult> _validateImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      
      // Try to decode image to verify it's valid
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return FileValidationResult.invalid('Ongeldig afbeeldingsbestand');
      }

      // Check image dimensions (max 4096x4096)
      if (image.width > 4096 || image.height > 4096) {
        return FileValidationResult.invalid(
          'Afbeelding te groot. Maximum: 4096x4096 pixels'
        );
      }

      return FileValidationResult.valid();
    } catch (e) {
      return FileValidationResult.invalid('Fout bij valideren afbeelding: ${e.toString()}');
    }
  }

  /// Delete file from storage
  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get file type from extension
  FileType _getFileType(String extension) {
    if (allowedImageTypes.contains(extension)) {
      return FileType.image;
    } else if (allowedDocumentTypes.contains(extension)) {
      return FileType.document;
    } else if (allowedVideoTypes.contains(extension)) {
      return FileType.video;
    } else {
      return FileType.unknown;
    }
  }

  /// Get maximum file size for type
  int _getMaxFileSize(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return maxImageSize;
      case FileType.document:
        return maxFileSize;
      case FileType.video:
        return maxVideoSize;
      case FileType.unknown:
        return 0;
    }
  }

  /// Get MIME type from extension
  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get all allowed file extensions
  List<String> _getAllowedExtensions() {
    return [
      ...allowedImageTypes,
      ...allowedDocumentTypes,
      ...allowedVideoTypes,
    ];
  }

  /// Generate file hash for deduplication
  String _generateFileHash(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// File upload result
class FileUploadResult {
  final bool isSuccess;
  final String? fileUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final FileType? fileType;
  final String? errorMessage;

  const FileUploadResult._({
    required this.isSuccess,
    this.fileUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.fileType,
    this.errorMessage,
  });

  factory FileUploadResult.success({
    required String fileUrl,
    String? thumbnailUrl,
    required String fileName,
    required int fileSize,
    required String mimeType,
    required FileType fileType,
  }) {
    return FileUploadResult._(
      isSuccess: true,
      fileUrl: fileUrl,
      thumbnailUrl: thumbnailUrl,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      fileType: fileType,
    );
  }

  factory FileUploadResult.failure(String errorMessage) {
    return FileUploadResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

/// File validation result
class FileValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? fileSize;
  final FileType? fileType;
  final String? mimeType;

  const FileValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.fileSize,
    this.fileType,
    this.mimeType,
  });

  factory FileValidationResult.valid({
    int? fileSize,
    FileType? fileType,
    String? mimeType,
  }) {
    return FileValidationResult._(
      isValid: true,
      fileSize: fileSize,
      fileType: fileType,
      mimeType: mimeType,
    );
  }

  factory FileValidationResult.invalid(String errorMessage) {
    return FileValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}

/// File type enumeration
enum FileType {
  image,
  document,
  video,
  unknown,
}
