import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../repositories/chat_repository.dart';
import '../../core/services/audit_service.dart';

/// Secure file attachment service for SecuryFlex chat
/// Handles file validation, encryption, compression, and secure storage
class FileAttachmentService {
  static FileAttachmentService? _instance;
  static FileAttachmentService get instance => _instance ??= FileAttachmentService._();
  
  FileAttachmentService._();
  
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Upload file with comprehensive security validation
  Future<FileUploadResult> uploadSecureFile({
    required String filePath,
    required String conversationId,
    required String userId,
    String? customFileName,
    bool generateThumbnail = true,
  }) async {
    try {
      // Step 1: Validate file exists and is accessible
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileAttachmentException('Bestand niet gevonden');
      }
      
      // Step 2: Security validation
      final securityCheck = await _performSecurityValidation(file);
      if (!securityCheck.isValid) {
        throw FileAttachmentException(securityCheck.errorMessage);
      }
      
      // Step 3: Get file metadata
      final fileMetadata = await _getFileMetadata(file);
      final fileName = customFileName ?? path.basename(filePath);
      
      // Step 4: Validate against Dutch business rules
      await _validateBusinessRules(fileMetadata);
      
      // Step 5: Process file (compress images, generate thumbnails)
      final processedFile = await _processFile(file, fileMetadata);
      
      // Step 6: Generate secure file path
      final secureFileName = _generateSecureFileName(fileName, userId, conversationId);
      
      // Step 7: Upload to Firebase Storage with metadata
      final uploadTask = _storage
          .ref()
          .child('chat_attachments')
          .child(conversationId)
          .child(secureFileName);
      
      // Add security metadata
      final metadata = SettableMetadata(
        contentType: fileMetadata.mimeType,
        customMetadata: {
          'uploadedBy': userId,
          'conversationId': conversationId,
          'originalFileName': fileName,
          'fileHash': fileMetadata.hash,
          'scanStatus': 'pending',
          'uploadTimestamp': DateTime.now().toIso8601String(),
        },
      );
      
      await uploadTask.putFile(processedFile.file, metadata);
      final downloadUrl = await uploadTask.getDownloadURL();
      
      // Step 8: Generate thumbnail if needed
      String? thumbnailUrl;
      if (generateThumbnail && _isImageFile(fileMetadata.mimeType)) {
        thumbnailUrl = await _generateAndUploadThumbnail(
          processedFile.file,
          conversationId,
          secureFileName,
          userId,
        );
      }
      
      // Step 9: Log successful upload
      await AuditService.instance.logEvent(
        'secure_file_upload',
        {
          'conversationId': conversationId,
          'userId': userId,
          'fileName': fileName,
          'fileSize': fileMetadata.size,
          'mimeType': fileMetadata.mimeType,
          'compressed': processedFile.wasCompressed,
          'thumbnailGenerated': thumbnailUrl != null,
        },
      );
      
      // Step 10: Schedule security scan
      await _scheduleSecurityScan(downloadUrl, userId);
      
      return FileUploadResult(
        success: true,
        downloadUrl: downloadUrl,
        thumbnailUrl: thumbnailUrl,
        fileName: fileName,
        fileSize: processedFile.finalSize,
        mimeType: fileMetadata.mimeType,
      );
      
    } catch (e) {
      await AuditService.instance.logEvent(
        'secure_file_upload_failed',
        {
          'conversationId': conversationId,
          'userId': userId,
          'error': e.toString(),
        },
      );
      
      return FileUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Securely download file with access validation
  Future<FileDownloadResult> downloadSecureFile({
    required String fileUrl,
    required String userId,
    required String localPath,
  }) async {
    try {
      // Step 1: Validate download permissions
      final hasPermission = await _validateDownloadPermission(fileUrl, userId);
      if (!hasPermission) {
        throw FileAttachmentException('Geen toegang tot dit bestand');
      }
      
      // Step 2: Download file
      final ref = _storage.refFromURL(fileUrl);
      final file = File(localPath);
      
      await ref.writeToFile(file);
      
      // Step 3: Verify file integrity
      final metadata = await ref.getMetadata();
      final expectedHash = metadata.customMetadata?['fileHash'];
      if (expectedHash != null) {
        final actualHash = await _calculateFileHash(file);
        if (actualHash != expectedHash) {
          await file.delete();
          throw FileAttachmentException('Bestandsintegriteit gecompromitteerd');
        }
      }
      
      // Step 4: Log download
      await AuditService.instance.logEvent(
        'secure_file_download',
        {
          'fileUrl': fileUrl,
          'userId': userId,
          'localPath': localPath,
        },
      );
      
      return FileDownloadResult(
        success: true,
        localPath: localPath,
        fileSize: await file.length(),
      );
      
    } catch (e) {
      return FileDownloadResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Delete file securely with audit trail
  Future<bool> deleteSecureFile(String fileUrl, String userId) async {
    try {
      // Validate deletion permissions
      final hasPermission = await _validateDeletePermission(fileUrl, userId);
      if (!hasPermission) {
        throw FileAttachmentException('Geen toestemming om dit bestand te verwijderen');
      }
      
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      
      // Also delete thumbnail if exists
      try {
        final thumbnailRef = _storage.refFromURL(fileUrl.replaceAll('.', '_thumb.'));
        await thumbnailRef.delete();
      } catch (_) {
        // Thumbnail might not exist, ignore error
      }
      
      await AuditService.instance.logEvent(
        'secure_file_deletion',
        {
          'fileUrl': fileUrl,
          'userId': userId,
        },
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Perform comprehensive security validation
  Future<SecurityValidationResult> _performSecurityValidation(File file) async {
    try {
      // Check file size limits
      final fileSize = await file.length();
      if (fileSize > 100 * 1024 * 1024) { // 100MB limit
        return SecurityValidationResult(false, 'Bestand te groot (maximaal 100MB)');
      }
      
      // Check file extension
      final extension = path.extension(file.path).toLowerCase();
      final allowedExtensions = [
        ...ChatBusinessRules.supportedImageTypes.map((e) => '.$e'),
        ...ChatBusinessRules.supportedDocumentTypes.map((e) => '.$e'),
      ];
      
      if (!allowedExtensions.contains(extension)) {
        return SecurityValidationResult(false, 'Bestandstype niet toegestaan');
      }
      
      // Basic malware scanning (simple heuristics)
      final bytes = await file.readAsBytes();
      if (_containsSuspiciousPatterns(bytes)) {
        return SecurityValidationResult(false, 'Verdachte bestandsinhoud gedetecteerd');
      }
      
      return SecurityValidationResult(true, '');
    } catch (e) {
      return SecurityValidationResult(false, 'Beveiligingsvalidatie mislukt');
    }
  }
  
  /// Get comprehensive file metadata
  Future<FileMetadata> _getFileMetadata(File file) async {
    final stat = await file.stat();
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes).toString();
    final extension = path.extension(file.path).toLowerCase().replaceAll('.', '');
    
    String mimeType;
    if (ChatBusinessRules.supportedImageTypes.contains(extension)) {
      mimeType = 'image/$extension';
    } else {
      mimeType = _getMimeTypeFromExtension(extension);
    }
    
    return FileMetadata(
      size: stat.size,
      mimeType: mimeType,
      hash: hash,
      extension: extension,
      lastModified: stat.modified,
    );
  }
  
  /// Validate against Dutch business rules
  Future<void> _validateBusinessRules(FileMetadata metadata) async {
    if (metadata.mimeType.startsWith('image/')) {
      if (metadata.size > ChatBusinessRules.maxImageSizeMB * 1024 * 1024) {
        throw FileAttachmentException('Afbeelding te groot (max ${ChatBusinessRules.maxImageSizeMB}MB)');
      }
    } else {
      if (metadata.size > ChatBusinessRules.maxDocumentSizeMB * 1024 * 1024) {
        throw FileAttachmentException('Document te groot (max ${ChatBusinessRules.maxDocumentSizeMB}MB)');
      }
    }
  }
  
  /// Process file (compression, optimization)
  Future<ProcessedFile> _processFile(File file, FileMetadata metadata) async {
    if (metadata.mimeType.startsWith('image/')) {
      return await _compressImage(file, metadata);
    }
    
    // For non-images, return as-is
    return ProcessedFile(
      file: file,
      finalSize: metadata.size,
      wasCompressed: false,
    );
  }
  
  /// Compress image while maintaining quality
  Future<ProcessedFile> _compressImage(File file, FileMetadata metadata) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        return ProcessedFile(
          file: file,
          finalSize: metadata.size,
          wasCompressed: false,
        );
      }
      
      // Resize if too large (max 1920x1080)
      img.Image resized = image;
      if (image.width > 1920 || image.height > 1080) {
        resized = img.copyResize(image, width: 1920, height: 1080, maintainAspect: true);
      }
      
      // Compress based on file type
      List<int> compressed;
      if (metadata.extension == 'png') {
        compressed = img.encodePng(resized, level: 6);
      } else {
        compressed = img.encodeJpg(resized, quality: 85);
      }
      
      // Only use compressed version if it's significantly smaller
      final originalSize = metadata.size;
      final compressedSize = compressed.length;
      
      if (compressedSize < originalSize * 0.8) {
        final tempFile = File('${file.path}.compressed');
        await tempFile.writeAsBytes(compressed);
        
        return ProcessedFile(
          file: tempFile,
          finalSize: compressedSize,
          wasCompressed: true,
        );
      }
      
      return ProcessedFile(
        file: file,
        finalSize: metadata.size,
        wasCompressed: false,
      );
    } catch (e) {
      return ProcessedFile(
        file: file,
        finalSize: metadata.size,
        wasCompressed: false,
      );
    }
  }
  
  /// Generate secure filename with timestamp and hash
  String _generateSecureFileName(String originalName, String userId, String conversationId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userHash = sha256.convert(userId.codeUnits).toString().substring(0, 8);
    final extension = path.extension(originalName);
    
    return '${timestamp}_$userHash$extension';
  }
  
  /// Generate and upload thumbnail for images
  Future<String?> _generateAndUploadThumbnail(
    File imageFile,
    String conversationId,
    String originalFileName,
    String userId,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;
      
      // Create thumbnail (150x150 max)
      final thumbnail = img.copyResize(image, width: 150, height: 150, maintainAspect: true);
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);
      
      // Upload thumbnail
      final thumbnailFileName = originalFileName.replaceAll(path.extension(originalFileName), '_thumb.jpg');
      final uploadTask = _storage
          .ref()
          .child('chat_attachments')
          .child(conversationId)
          .child('thumbnails')
          .child(thumbnailFileName);
      
      await uploadTask.putData(Uint8List.fromList(thumbnailBytes));
      return await uploadTask.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
  
  /// Simple suspicious pattern detection
  bool _containsSuspiciousPatterns(List<int> bytes) {
    // Very basic malware detection patterns
    final suspiciousStrings = ['<script', 'eval(', 'document.write', 'cmd.exe'];
    final content = String.fromCharCodes(bytes).toLowerCase();
    
    return suspiciousStrings.any((pattern) => content.contains(pattern));
  }
  
  String _getMimeTypeFromExtension(String extension) {
    const mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'txt': 'text/plain',
    };
    
    return mimeTypes[extension] ?? 'application/octet-stream';
  }
  
  bool _isImageFile(String mimeType) {
    return mimeType.startsWith('image/');
  }
  
  Future<String> _calculateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }
  
  Future<bool> _validateDownloadPermission(String fileUrl, String userId) async {
    // TODO: Implement proper permission checking
    return true;
  }
  
  Future<bool> _validateDeletePermission(String fileUrl, String userId) async {
    // TODO: Implement proper permission checking
    return true;
  }
  
  Future<void> _scheduleSecurityScan(String fileUrl, String userId) async {
    // TODO: Implement external security scanning integration
  }
}

/// Result of file upload operation
class FileUploadResult {
  final bool success;
  final String? downloadUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? error;
  
  const FileUploadResult({
    required this.success,
    this.downloadUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.error,
  });
}

/// Result of file download operation
class FileDownloadResult {
  final bool success;
  final String? localPath;
  final int? fileSize;
  final String? error;
  
  const FileDownloadResult({
    required this.success,
    this.localPath,
    this.fileSize,
    this.error,
  });
}

/// File metadata information
class FileMetadata {
  final int size;
  final String mimeType;
  final String hash;
  final String extension;
  final DateTime lastModified;
  
  const FileMetadata({
    required this.size,
    required this.mimeType,
    required this.hash,
    required this.extension,
    required this.lastModified,
  });
}

/// Processed file information
class ProcessedFile {
  final File file;
  final int finalSize;
  final bool wasCompressed;
  
  const ProcessedFile({
    required this.file,
    required this.finalSize,
    required this.wasCompressed,
  });
}

/// Security validation result
class SecurityValidationResult {
  final bool isValid;
  final String errorMessage;
  
  const SecurityValidationResult(this.isValid, this.errorMessage);
}

/// Custom exception for file attachment errors
class FileAttachmentException implements Exception {
  final String message;
  
  const FileAttachmentException(this.message);
  
  @override
  String toString() => 'FileAttachmentException: $message';
}