import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'crypto_service.dart';

/// Result of document upload operation
class DocumentUploadResult {
  final bool success;
  final String? downloadUrl;
  final String? documentId;
  final String? error;
  final String? errorCode;
  final Map<String, dynamic>? metadata;
  final String? fileName;
  final int? fileSizeBytes;

  const DocumentUploadResult({
    required this.success,
    this.downloadUrl,
    this.documentId,
    this.error,
    this.errorCode,
    this.metadata,
    this.fileName,
    this.fileSizeBytes,
  });

  factory DocumentUploadResult.success({
    required String downloadUrl,
    required String documentId,
    Map<String, dynamic>? metadata,
    String? fileName,
    int? fileSizeBytes,
  }) {
    return DocumentUploadResult(
      success: true,
      downloadUrl: downloadUrl,
      documentId: documentId,
      metadata: metadata,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
    );
  }

  factory DocumentUploadResult.error(String error, {String? errorCode}) {
    return DocumentUploadResult(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }
}

/// File validation result
class FileValidationResult {
  final bool isValid;
  final String? error;
  final String? securityThreat;
  final Map<String, dynamic>? metadata;

  const FileValidationResult({
    required this.isValid,
    this.error,
    this.securityThreat,
    this.metadata,
  });

  factory FileValidationResult.valid([Map<String, dynamic>? metadata]) {
    return FileValidationResult(isValid: true, metadata: metadata);
  }

  factory FileValidationResult.invalid(String error, {String? securityThreat}) {
    return FileValidationResult(
      isValid: false,
      error: error,
      securityThreat: securityThreat,
    );
  }
}

/// Secure document upload service for WPBR certificates and other sensitive documents
/// Implements comprehensive security controls including file validation, encryption, and audit logging
class DocumentUploadService {
  // Security configuration
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const Duration _uploadRateLimit = Duration(minutes: 1);
  
  // Rate limiting storage
  static final Map<String, List<DateTime>> _uploadHistory = {};
  
  // Allowed file types with magic numbers for content validation
  static final Map<String, List<int>> _allowedFileTypes = {
    'pdf': [0x25, 0x50, 0x44, 0x46], // %PDF
    'jpg': [0xFF, 0xD8, 0xFF, 0xE0],
    'jpeg': [0xFF, 0xD8, 0xFF, 0xE0],
    'png': [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    'tiff': [0x49, 0x49, 0x2A, 0x00],
  };

  // Suspicious file patterns (basic malware detection)
  static final List<List<int>> _suspiciousPatterns = [
    [0x4D, 0x5A], // PE executable header
    [0x7F, 0x45, 0x4C, 0x46], // ELF header
    [0xFE, 0xED, 0xFA, 0xCE], // Mach-O binary
  ];

  /// Upload document with comprehensive security validation
  static Future<DocumentUploadResult> uploadDocument({
    required File file,
    required String documentType,
    required String userId,
    required String certificateNumber,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Start audit logging
      final uploadId = _generateUploadId();
      await _logAuditEvent(
        action: 'document_upload_started',
        userId: userId,
        documentType: documentType,
        metadata: {
          'uploadId': uploadId,
          'fileName': file.path.split('/').last,
          'certificateNumber': _hashCertificateNumber(certificateNumber),
        },
      );

      // 1. Rate limiting check
      if (!_checkRateLimit(userId)) {
        await _logAuditEvent(
          action: 'document_upload_rate_limited',
          userId: userId,
          result: 'blocked',
          metadata: {'uploadId': uploadId},
        );
        return DocumentUploadResult.error(
          'Te veel uploads. Wacht even voordat u opnieuw probeert.',
          errorCode: 'rate_limited',
        );
      }

      // 2. File validation
      final validationResult = await _validateFile(file);
      if (!validationResult.isValid) {
        await _logAuditEvent(
          action: 'document_upload_validation_failed',
          userId: userId,
          result: 'blocked',
          metadata: {
            'uploadId': uploadId,
            'error': validationResult.error,
            'securityThreat': validationResult.securityThreat,
          },
        );
        return DocumentUploadResult.error(
          validationResult.error ?? 'Bestand validatie mislukt',
          errorCode: 'validation_failed',
        );
      }

      // 3. Generate secure file path
      final securePath = _generateSecureFilePath(
        userId: userId,
        documentType: documentType,
        originalFileName: file.path.split('/').last,
        uploadId: uploadId,
      );

      // 4. Encrypt file before upload (for sensitive documents)
      Uint8List fileBytes = await file.readAsBytes();
      if (_isSensitiveDocument(documentType)) {
        fileBytes = await _encryptFileContent(fileBytes, userId);
      }

      // 5. Upload to Firebase Storage with metadata
      final uploadMetadata = SettableMetadata(
        contentType: _getContentType(file.path.split('.').last),
        customMetadata: {
          'uploadId': uploadId,
          'userId': userId,
          'documentType': documentType,
          'certificateNumber': _hashCertificateNumber(certificateNumber),
          'uploadTimestamp': DateTime.now().toIso8601String(),
          'encrypted': _isSensitiveDocument(documentType) ? 'true' : 'false',
          'checksum': _calculateChecksum(fileBytes),
          ...?metadata,
        },
      );

      final storageRef = FirebaseStorage.instance.ref(securePath);
      final uploadTask = storageRef.putData(fileBytes, uploadMetadata);
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 6. Store document metadata in Firestore
      final documentId = await _storeDocumentMetadata(
        uploadId: uploadId,
        userId: userId,
        documentType: documentType,
        certificateNumber: certificateNumber,
        downloadUrl: downloadUrl,
        storagePath: securePath,
        metadata: metadata,
      );

      // 7. Record successful upload
      _recordUpload(userId);

      // 8. Log success
      await _logAuditEvent(
        action: 'document_upload_completed',
        userId: userId,
        result: 'success',
        metadata: {
          'uploadId': uploadId,
          'documentId': documentId,
          'documentType': documentType,
        },
      );

      return DocumentUploadResult.success(
        downloadUrl: downloadUrl,
        documentId: documentId,
        metadata: {'uploadId': uploadId},
      );

    } catch (e) {
      await _logAuditEvent(
        action: 'document_upload_error',
        userId: userId,
        result: 'error',
        metadata: {
          'error': e.toString(),
          'documentType': documentType,
        },
      );
      
      debugPrint('Document upload error: $e');
      return DocumentUploadResult.error(
        'Upload mislukt. Probeer opnieuw.',
        errorCode: 'upload_failed',
      );
    }
  }

  /// Validate file content and security
  static Future<FileValidationResult> _validateFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last.toLowerCase();
      
      // 1. Size validation
      if (bytes.length > _maxFileSizeBytes) {
        return FileValidationResult.invalid(
          'Bestand is te groot. Maximum ${_maxFileSizeBytes ~/ (1024 * 1024)}MB toegestaan.',
        );
      }

      if (bytes.length < 100) {
        return FileValidationResult.invalid(
          'Bestand is te klein of beschadigd.',
        );
      }

      // 2. File extension validation
      final extension = fileName.split('.').last;
      if (!_allowedFileTypes.containsKey(extension)) {
        return FileValidationResult.invalid(
          'Bestandstype niet toegestaan. Alleen PDF, JPG, PNG, TIFF bestanden zijn toegestaan.',
        );
      }

      // 3. Magic number validation (file content vs extension)
      final expectedMagic = _allowedFileTypes[extension]!;
      if (bytes.length < expectedMagic.length) {
        return FileValidationResult.invalid(
          'Bestand is beschadigd of heeft een ongeldig formaat.',
        );
      }

      final actualMagic = bytes.take(expectedMagic.length).toList();
      bool magicMatch = true;
      for (int i = 0; i < expectedMagic.length; i++) {
        if (actualMagic[i] != expectedMagic[i]) {
          magicMatch = false;
          break;
        }
      }

      if (!magicMatch) {
        return FileValidationResult.invalid(
          'Bestand inhoud komt niet overeen met bestandstype.',
          securityThreat: 'file_type_mismatch',
        );
      }

      // 4. Malware/suspicious content detection
      for (final suspiciousPattern in _suspiciousPatterns) {
        if (bytes.length >= suspiciousPattern.length) {
          bool foundPattern = true;
          for (int i = 0; i < suspiciousPattern.length; i++) {
            if (bytes[i] != suspiciousPattern[i]) {
              foundPattern = false;
              break;
            }
          }
          if (foundPattern) {
            return FileValidationResult.invalid(
              'Bestand bevat verdachte inhoud en kan niet worden geüpload.',
              securityThreat: 'malware_detected',
            );
          }
        }
      }

      // 5. Additional PDF-specific validation
      if (extension == 'pdf') {
        if (!_validatePDFContent(bytes)) {
          return FileValidationResult.invalid(
            'PDF bestand is beschadigd of bevat ongeldige inhoud.',
            securityThreat: 'invalid_pdf',
          );
        }
      }

      return FileValidationResult.valid({
        'fileSize': bytes.length,
        'extension': extension,
        'contentType': _getContentType(extension),
      });

    } catch (e) {
      debugPrint('File validation error: $e');
      return FileValidationResult.invalid(
        'Kan bestand niet valideren. Probeer opnieuw.',
      );
    }
  }

  /// Validate PDF content structure
  static bool _validatePDFContent(Uint8List bytes) {
    try {
      final content = utf8.decode(bytes.take(1024).toList(), allowMalformed: true);
      
      // Check for PDF version
      if (!content.contains('%PDF-')) {
        return false;
      }

      // Look for EOF marker (should be near the end)
      final endContent = utf8.decode(bytes.skip(bytes.length - 1024).toList(), allowMalformed: true);
      if (!endContent.contains('%%EOF')) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check rate limiting for user
  static bool _checkRateLimit(String userId) {
    final now = DateTime.now();
    final userUploads = _uploadHistory[userId] ?? [];
    
    // Remove uploads older than rate limit window
    userUploads.removeWhere((time) => now.difference(time) > _uploadRateLimit);
    
    // Check if under limit (1 upload per minute)
    return userUploads.isEmpty;
  }

  /// Record upload for rate limiting
  static void _recordUpload(String userId) {
    final userUploads = _uploadHistory[userId] ?? [];
    userUploads.add(DateTime.now());
    _uploadHistory[userId] = userUploads;
  }

  /// Generate secure file path
  static String _generateSecureFilePath({
    required String userId,
    required String documentType,
    required String originalFileName,
    required String uploadId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hashedUserId = _hashUserId(userId);
    final sanitizedFileName = _sanitizeFileName(originalFileName);
    
    return 'secure_documents/$documentType/$hashedUserId/${uploadId}_${timestamp}_$sanitizedFileName';
  }

  /// Encrypt file content for sensitive documents using AES-256-GCM
  static Future<Uint8List> _encryptFileContent(Uint8List content, String userId) async {
    // Initialize crypto service if needed
    await CryptoService.initialize();
    
    // Use secure document encryption
    return await CryptoService.encryptDocument(content, userId);
  }

  /// Store document metadata in Firestore
  static Future<String> _storeDocumentMetadata({
    required String uploadId,
    required String userId,
    required String documentType,
    required String certificateNumber,
    required String downloadUrl,
    required String storagePath,
    Map<String, dynamic>? metadata,
  }) async {
    final docData = {
      'uploadId': uploadId,
      'userId': userId,
      'documentType': documentType,
      'certificateNumberHash': _hashCertificateNumber(certificateNumber),
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'uploadTimestamp': FieldValue.serverTimestamp(),
      'encrypted': _isSensitiveDocument(documentType),
      'status': 'uploaded',
      'metadata': metadata ?? {},
    };

    final docRef = await FirebaseFirestore.instance
        .collection('document_uploads')
        .add(docData);

    return docRef.id;
  }

  /// Log audit event for compliance
  static Future<void> _logAuditEvent({
    required String action,
    required String userId,
    String? result,
    Map<String, dynamic>? metadata,
    String? documentType,
  }) async {
    try {
      final auditData = {
        'action': action,
        'userId': userId,
        'result': result,
        'timestamp': FieldValue.serverTimestamp(),
        'documentType': documentType,
        'metadata': metadata ?? {},
        'ipAddress': await _getCurrentIPAddress(),
        'userAgent': await _getUserAgent(),
      };

      await FirebaseFirestore.instance
          .collection('audit_logs')
          .doc('document_uploads')
          .collection('entries')
          .add(auditData);
    } catch (e) {
      debugPrint('Audit logging error: $e');
    }
  }

  // Utility methods
  static String _generateUploadId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }

  static String _hashCertificateNumber(String number) {
    return sha256.convert(utf8.encode('${number}cert_salt')).toString().substring(0, 16);
  }

  static String _hashUserId(String userId) {
    return sha256.convert(utf8.encode('${userId}user_salt')).toString().substring(0, 12);
  }

  static String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\.\-_]'), '_');
  }

  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'tiff':
        return 'image/tiff';
      default:
        return 'application/octet-stream';
    }
  }

  static bool _isSensitiveDocument(String documentType) {
    return ['wpbr', 'vca', 'bhv', 'ehbo', 'identity'].contains(documentType.toLowerCase());
  }

  static String _calculateChecksum(Uint8List bytes) {
    return md5.convert(bytes).toString().substring(0, 16);
  }

  // Removed: Key generation now handled by SecureKeyManager and AESGCMCryptoService

  static Future<String> _getCurrentIPAddress() async {
    try {
      // In production, implement proper IP detection
      return 'localhost';
    } catch (e) {
      return 'unknown';
    }
  }

  static Future<String> _getUserAgent() async {
    try {
      // In production, get actual user agent
      return 'SecuryFlex-Flutter-App';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Delete document and cleanup
  static Future<bool> deleteDocument(String documentId, String userId) async {
    try {
      await _logAuditEvent(
        action: 'document_deletion_requested',
        userId: userId,
        metadata: {'documentId': documentId},
      );

      // Get document metadata
      final docSnapshot = await FirebaseFirestore.instance
          .collection('document_uploads')
          .doc(documentId)
          .get();

      if (!docSnapshot.exists) {
        return false;
      }

      final docData = docSnapshot.data()!;
      
      // Verify ownership
      if (docData['userId'] != userId) {
        await _logAuditEvent(
          action: 'document_deletion_unauthorized',
          userId: userId,
          result: 'blocked',
          metadata: {'documentId': documentId},
        );
        return false;
      }

      // Delete from storage
      final storagePath = docData['storagePath'] as String;
      await FirebaseStorage.instance.ref(storagePath).delete();

      // Delete metadata
      await FirebaseFirestore.instance
          .collection('document_uploads')
          .doc(documentId)
          .delete();

      await _logAuditEvent(
        action: 'document_deletion_completed',
        userId: userId,
        result: 'success',
        metadata: {'documentId': documentId},
      );

      return true;
    } catch (e) {
      await _logAuditEvent(
        action: 'document_deletion_error',
        userId: userId,
        result: 'error',
        metadata: {'documentId': documentId, 'error': e.toString()},
      );
      return false;
    }
  }

  /// Get user's uploaded documents
  static Future<List<Map<String, dynamic>>> getUserDocuments(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('document_uploads')
          .where('userId', isEqualTo: userId)
          .orderBy('uploadTimestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('Error fetching user documents: $e');
      return [];
    }
  }
}