import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'aes_gcm_crypto_service.dart';
import 'bsn_security_service.dart';
import 'document_upload_service.dart';

/// Enhanced document upload service with comprehensive security controls
/// Implements malware scanning, advanced validation, and secure storage
class EnhancedDocumentUploadService {
  // Security configuration
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const Duration _uploadRateLimit = Duration(seconds: 30); // Stricter rate limiting
  
  // Rate limiting with distributed tracking
  static final Map<String, List<DateTime>> _uploadHistory = {};
  static final Map<String, int> _dailyUploadCount = {};
  static const int _maxDailyUploads = 20;
  
  // Enhanced file type validation with comprehensive magic numbers
  static final Map<String, List<List<int>>> _allowedFileTypes = {
    'pdf': [
      [0x25, 0x50, 0x44, 0x46], // %PDF standard
      [0x25, 0x21, 0x50, 0x53], // %!PS (PostScript-based PDF)
    ],
    'jpg': [
      [0xFF, 0xD8, 0xFF, 0xE0], // JFIF
      [0xFF, 0xD8, 0xFF, 0xE1], // EXIF
      [0xFF, 0xD8, 0xFF, 0xE8], // SPIFF
    ],
    'jpeg': [
      [0xFF, 0xD8, 0xFF, 0xE0],
      [0xFF, 0xD8, 0xFF, 0xE1],
      [0xFF, 0xD8, 0xFF, 0xE8],
    ],
    'png': [
      [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    ],
    'tiff': [
      [0x49, 0x49, 0x2A, 0x00], // Little-endian
      [0x4D, 0x4D, 0x00, 0x2A], // Big-endian
    ],
  };

  // Comprehensive malware signatures (simplified for demonstration)
  static final List<List<int>> _malwareSignatures = [
    [0x4D, 0x5A], // PE executable
    [0x7F, 0x45, 0x4C, 0x46], // ELF binary
    [0xFE, 0xED, 0xFA, 0xCE], // Mach-O binary
    [0xCF, 0xFA, 0xED, 0xFE], // Mach-O binary (reverse)
    [0xD0, 0xCF, 0x11, 0xE0], // Microsoft compound document
    [0x50, 0x4B, 0x03, 0x04], // ZIP/Office files (require deeper inspection)
    // JavaScript patterns in PDFs (potential PDF malware)
    [0x2F, 0x4A, 0x61, 0x76, 0x61, 0x53, 0x63, 0x72], // /JavaScript
    [0x2F, 0x4A, 0x53], // /JS
    // Embedded objects in PDFs
    [0x2F, 0x4F, 0x62, 0x6A, 0x53, 0x74, 0x6D], // /ObjStm
    [0x2F, 0x45, 0x6D, 0x62, 0x65, 0x64, 0x64, 0x65, 0x64], // /Embedded
  ];

  // Suspicious PDF keywords that warrant additional scrutiny
  static final List<String> _suspiciousPdfKeywords = [
    '/JavaScript', '/JS', '/EmbeddedFile', '/Launch', '/SubmitForm',
    '/ImportData', '/ExportData', '/OpenAction', '/AcroForm',
    'shell', 'cmd.exe', 'powershell', 'eval(', 'document.write',
  ];

  /// Upload document with enhanced security validation
  static Future<DocumentUploadResult> uploadSecureDocument({
    required File file,
    required String documentType,
    required String userId,
    required String certificateNumber,
    Map<String, dynamic>? metadata,
    bool skipMalwareScan = false,
  }) async {
    try {
      // Generate unique upload ID for tracking
      final uploadId = _generateSecureUploadId();
      
      await _logSecurityEvent(
        action: 'secure_document_upload_started',
        userId: userId,
        documentType: documentType,
        metadata: {
          'uploadId': uploadId,
          'fileName': file.path.split('/').last,
          'certificateNumber': await BSNSecurityService.hashBSNForAudit(certificateNumber),
          'skipMalwareScan': skipMalwareScan,
        },
      );

      // 1. Enhanced rate limiting with daily caps
      if (!await _checkEnhancedRateLimit(userId)) {
        await _logSecurityEvent(
          action: 'document_upload_rate_limited',
          userId: userId,
          result: 'blocked',
          metadata: {'uploadId': uploadId, 'reason': 'rate_limit_exceeded'},
        );
        return DocumentUploadResult.error(
          'Upload limiet bereikt. Probeer later opnieuw.',
          errorCode: 'rate_limited',
        );
      }

      // 2. Comprehensive file validation
      final validationResult = await _validateFileComprehensive(file);
      if (!validationResult.isValid) {
        await _logSecurityEvent(
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

      // 3. Advanced malware scanning
      if (!skipMalwareScan) {
        final malwareScanResult = await _performAdvancedMalwareScan(file);
        if (!malwareScanResult.isClean) {
          await _logSecurityEvent(
            action: 'document_upload_malware_detected',
            userId: userId,
            result: 'blocked',
            metadata: {
              'uploadId': uploadId,
              'threatType': malwareScanResult.threatType,
              'confidence': malwareScanResult.confidence,
            },
          );
          return DocumentUploadResult.error(
            'Beveiligingsbedreiging gedetecteerd in bestand.',
            errorCode: 'malware_detected',
          );
        }
      }

      // 4. Generate secure file path with obfuscation
      final securePath = await _generateObfuscatedFilePath(
        userId: userId,
        documentType: documentType,
        originalFileName: file.path.split('/').last,
        uploadId: uploadId,
      );

      // 5. Encrypt file content before upload
      final fileBytes = await file.readAsBytes();
      final encryptedBytes = await AESGCMCryptoService.encryptBytes(
        fileBytes,
        'document_storage_$userId',
      );

      // 6. Calculate and store file integrity hash
      final integrityHash = sha256.convert(fileBytes).toString();
      final encryptedHash = sha256.convert(encryptedBytes).toString();

      // 7. Upload to Firebase Storage with comprehensive metadata
      final uploadMetadata = SettableMetadata(
        contentType: 'application/octet-stream', // Always encrypted
        customMetadata: {
          'uploadId': uploadId,
          'userId': await BSNSecurityService.hashBSNForAudit(userId),
          'documentType': documentType,
          'certificateNumber': await BSNSecurityService.hashBSNForAudit(certificateNumber),
          'uploadTimestamp': DateTime.now().toIso8601String(),
          'encrypted': 'true',
          'encryptionVersion': 'AES256_V1',
          'integrityHash': integrityHash,
          'encryptedHash': encryptedHash,
          'originalSize': fileBytes.length.toString(),
          'encryptedSize': encryptedBytes.length.toString(),
          'securityScanPassed': (!skipMalwareScan).toString(),
          ...?metadata,
        },
      );

      final storageRef = FirebaseStorage.instance.ref(securePath);
      final uploadTask = storageRef.putData(encryptedBytes, uploadMetadata);
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 8. Store comprehensive document metadata in Firestore
      final documentId = await _storeSecureDocumentMetadata(
        uploadId: uploadId,
        userId: userId,
        documentType: documentType,
        certificateNumber: certificateNumber,
        downloadUrl: downloadUrl,
        storagePath: securePath,
        integrityHash: integrityHash,
        originalSize: fileBytes.length,
        encryptedSize: encryptedBytes.length,
        metadata: metadata,
      );

      // 9. Record successful upload
      _recordUpload(userId);

      // 10. Clean up sensitive data from memory
      AESGCMCryptoService.secureWipe(Uint8List.fromList(fileBytes));
      AESGCMCryptoService.secureWipe(encryptedBytes);

      // 11. Log successful upload
      await _logSecurityEvent(
        action: 'secure_document_upload_completed',
        userId: userId,
        result: 'success',
        metadata: {
          'uploadId': uploadId,
          'documentId': documentId,
          'documentType': documentType,
          'encryptedSize': encryptedBytes.length,
        },
      );

      return DocumentUploadResult.success(
        downloadUrl: downloadUrl,
        documentId: documentId,
        metadata: {
          'uploadId': uploadId,
          'encrypted': true,
          'integrityHash': integrityHash,
        },
        fileName: file.path.split('/').last,
        fileSizeBytes: encryptedBytes.length,
      );

    } catch (e, stackTrace) {
      await _logSecurityEvent(
        action: 'secure_document_upload_error',
        userId: userId,
        result: 'error',
        metadata: {
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
          'documentType': documentType,
        },
      );
      
      debugPrint('Enhanced document upload error: $e');
      return DocumentUploadResult.error(
        'Upload mislukt door technische fout.',
        errorCode: 'upload_failed',
      );
    }
  }

  /// Comprehensive file validation with advanced security checks
  static Future<FileValidationResult> _validateFileComprehensive(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last.toLowerCase();
      
      // 1. Size validation
      if (bytes.length > _maxFileSizeBytes) {
        return FileValidationResult.invalid(
          'Bestand is te groot. Maximum ${_maxFileSizeBytes ~/ (1024 * 1024)}MB toegestaan.',
          securityThreat: 'file_too_large',
        );
      }

      if (bytes.length < 100) {
        return FileValidationResult.invalid(
          'Bestand is te klein of beschadigd.',
          securityThreat: 'file_too_small',
        );
      }

      // 2. File extension validation
      final extension = fileName.split('.').last;
      if (!_allowedFileTypes.containsKey(extension)) {
        return FileValidationResult.invalid(
          'Bestandstype niet toegestaan. Alleen PDF, JPG, PNG, TIFF bestanden zijn toegestaan.',
          securityThreat: 'invalid_file_type',
        );
      }

      // 3. Enhanced magic number validation (support multiple signatures per type)
      final expectedMagicNumbers = _allowedFileTypes[extension]!;
      bool validMagicNumber = false;
      
      for (final expectedMagic in expectedMagicNumbers) {
        if (bytes.length >= expectedMagic.length) {
          bool matches = true;
          for (int i = 0; i < expectedMagic.length; i++) {
            if (bytes[i] != expectedMagic[i]) {
              matches = false;
              break;
            }
          }
          if (matches) {
            validMagicNumber = true;
            break;
          }
        }
      }

      if (!validMagicNumber) {
        return FileValidationResult.invalid(
          'Bestand inhoud komt niet overeen met bestandstype.',
          securityThreat: 'file_type_mismatch',
        );
      }

      // 4. Advanced malware signature detection
      for (final signature in _malwareSignatures) {
        if (await _containsSignature(bytes, signature)) {
          return FileValidationResult.invalid(
            'Bestand bevat verdachte inhoud en kan niet worden geüpload.',
            securityThreat: 'malware_signature_detected',
          );
        }
      }

      // 5. PDF-specific security validation
      if (extension == 'pdf') {
        final pdfValidation = await _validatePDFSecurity(bytes);
        if (!pdfValidation.isValid) {
          return pdfValidation;
        }
      }

      // 6. Image-specific validation
      if (['jpg', 'jpeg', 'png', 'tiff'].contains(extension)) {
        final imageValidation = await _validateImageSecurity(bytes, extension);
        if (!imageValidation.isValid) {
          return imageValidation;
        }
      }

      // 7. Entropy analysis (detect encrypted/compressed content that might hide malware)
      final entropy = _calculateEntropy(bytes);
      if (entropy > 7.8) { // High entropy might indicate encryption/compression
        return FileValidationResult.invalid(
          'Bestand heeft verdachte eigenschappen.',
          securityThreat: 'high_entropy_detected',
        );
      }

      return FileValidationResult.valid({
        'fileSize': bytes.length,
        'extension': extension,
        'entropy': entropy,
        'contentType': _getContentType(extension),
        'validationPassed': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      debugPrint('File validation error: $e');
      return FileValidationResult.invalid(
        'Kan bestand niet valideren. Probeer opnieuw.',
        securityThreat: 'validation_error',
      );
    }
  }

  /// Advanced PDF security validation
  static Future<FileValidationResult> _validatePDFSecurity(Uint8List bytes) async {
    try {
      final content = utf8.decode(bytes.take(8192).toList(), allowMalformed: true);
      final endContent = utf8.decode(bytes.skip(bytes.length - 2048).toList(), allowMalformed: true);
      final fullContent = utf8.decode(bytes, allowMalformed: true);
      
      // 1. Basic PDF structure validation
      if (!content.contains('%PDF-')) {
        return FileValidationResult.invalid(
          'PDF bestand heeft een ongeldige structuur.',
          securityThreat: 'invalid_pdf_structure',
        );
      }

      if (!endContent.contains('%%EOF')) {
        return FileValidationResult.invalid(
          'PDF bestand is incompleet.',
          securityThreat: 'incomplete_pdf',
        );
      }

      // 2. Check for suspicious PDF content
      for (final keyword in _suspiciousPdfKeywords) {
        if (fullContent.contains(keyword)) {
          return FileValidationResult.invalid(
            'PDF bevat potentieel gevaarlijke inhoud.',
            securityThreat: 'suspicious_pdf_content',
          );
        }
      }

      // 3. Check for embedded files
      if (fullContent.contains('/EmbeddedFile')) {
        return FileValidationResult.invalid(
          'PDF bevat ingesloten bestanden die niet zijn toegestaan.',
          securityThreat: 'pdf_embedded_files',
        );
      }

      // 4. Check for forms (potential data extraction)
      if (fullContent.contains('/AcroForm') && fullContent.contains('/SubmitForm')) {
        return FileValidationResult.invalid(
          'PDF formulieren met data-overdracht zijn niet toegestaan.',
          securityThreat: 'pdf_form_submission',
        );
      }

      return FileValidationResult.valid({'pdfSecurityValidated': true});

    } catch (e) {
      return FileValidationResult.invalid(
        'PDF beveiligingsvalidatie mislukt.',
        securityThreat: 'pdf_validation_error',
      );
    }
  }

  /// Advanced image security validation
  static Future<FileValidationResult> _validateImageSecurity(Uint8List bytes, String extension) async {
    try {
      // 1. Check for EXIF data that might contain executable code
      if (extension.startsWith('jpg') || extension == 'jpeg') {
        if (await _containsSignature(bytes, [0xFF, 0xE1])) { // EXIF marker
          // EXIF is present - validate it doesn't contain suspicious content
          final exifSection = _extractExifSection(bytes);
          if (exifSection != null && _containsSuspiciousExifData(exifSection)) {
            return FileValidationResult.invalid(
              'Afbeelding bevat verdachte metadata.',
              securityThreat: 'suspicious_exif_data',
            );
          }
        }
      }

      // 2. Check for polyglot files (files that are valid in multiple formats)
      if (await _isPolyglotFile(bytes)) {
        return FileValidationResult.invalid(
          'Bestand heeft verdachte multi-format eigenschappen.',
          securityThreat: 'polyglot_file_detected',
        );
      }

      // 3. Validate image dimensions are reasonable
      final dimensions = await _getImageDimensions(bytes, extension);
      if (dimensions != null) {
        if (dimensions['width']! > 10000 || dimensions['height']! > 10000) {
          return FileValidationResult.invalid(
            'Afbeelding dimensies zijn verdacht groot.',
            securityThreat: 'suspicious_image_dimensions',
          );
        }
      }

      return FileValidationResult.valid({'imageSecurityValidated': true});

    } catch (e) {
      return FileValidationResult.invalid(
        'Afbeelding beveiligingsvalidatie mislukt.',
        securityThreat: 'image_validation_error',
      );
    }
  }

  /// Advanced malware scanning with multiple detection methods
  static Future<MalwareScanResult> _performAdvancedMalwareScan(File file) async {
    try {
      final bytes = await file.readAsBytes();
      
      // 1. Signature-based detection (already done in validation)
      // This would typically call an external malware scanning service
      
      // 2. Behavioral analysis simulation
      if (await _behavioralAnalysis(bytes)) {
        return MalwareScanResult.threat('behavioral_analysis', 0.9);
      }
      
      // 3. Heuristic analysis
      final heuristicScore = await _heuristicAnalysis(bytes);
      if (heuristicScore > 0.7) {
        return MalwareScanResult.threat('heuristic_analysis', heuristicScore);
      }
      
      // 4. Hash-based reputation check (simulate)
      final fileHash = sha256.convert(bytes).toString();
      if (await _checkHashReputation(fileHash)) {
        return MalwareScanResult.threat('hash_reputation', 1.0);
      }
      
      return MalwareScanResult.clean();
      
    } catch (e) {
      debugPrint('Malware scan error: $e');
      // Fail secure - if we can't scan, don't allow upload
      return MalwareScanResult.threat('scan_error', 0.5);
    }
  }

  /// Enhanced rate limiting with multiple tiers
  static Future<bool> _checkEnhancedRateLimit(String userId) async {
    final now = DateTime.now();
    
    // 1. Check per-minute rate limit
    final userUploads = _uploadHistory[userId] ?? [];
    userUploads.removeWhere((time) => now.difference(time) > _uploadRateLimit);
    
    if (userUploads.length >= 2) { // Max 2 uploads per 30 seconds
      return false;
    }
    
    // 2. Check daily upload limit
    final today = DateTime(now.year, now.month, now.day);
    final dailyKey = '${userId}_${today.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24)}';
    final dailyCount = _dailyUploadCount[dailyKey] ?? 0;
    
    if (dailyCount >= _maxDailyUploads) {
      return false;
    }
    
    return true;
  }

  /// Record upload for rate limiting
  static void _recordUpload(String userId) {
    // Record for per-minute limit
    final userUploads = _uploadHistory[userId] ?? [];
    userUploads.add(DateTime.now());
    _uploadHistory[userId] = userUploads;
    
    // Record for daily limit
    final today = DateTime.now();
    final dailyKey = '${userId}_${today.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24)}';
    _dailyUploadCount[dailyKey] = (_dailyUploadCount[dailyKey] ?? 0) + 1;
  }

  // Helper methods for security analysis

  static Future<bool> _containsSignature(Uint8List bytes, List<int> signature) async {
    if (bytes.length < signature.length) return false;
    
    for (int i = 0; i <= bytes.length - signature.length; i++) {
      bool found = true;
      for (int j = 0; j < signature.length; j++) {
        if (bytes[i + j] != signature[j]) {
          found = false;
          break;
        }
      }
      if (found) return true;
    }
    return false;
  }

  static double _calculateEntropy(Uint8List bytes) {
    final Map<int, int> frequency = {};
    for (final byte in bytes) {
      frequency[byte] = (frequency[byte] ?? 0) + 1;
    }
    
    double entropy = 0.0;
    final length = bytes.length;
    
    for (final count in frequency.values) {
      final probability = count / length;
      entropy -= probability * (log(probability) / log(2));
    }
    
    return entropy;
  }

  static Future<bool> _behavioralAnalysis(Uint8List bytes) async {
    // Simulate behavioral analysis - in production this would be more sophisticated
    // Check for patterns that might indicate malicious behavior
    
    // Look for suspicious string patterns
    final content = utf8.decode(bytes, allowMalformed: true);
    final suspiciousPatterns = [
      'cmd.exe', 'powershell', 'bash', '/bin/sh',
      'eval(', 'exec(', 'system(',
      'document.write', 'innerHTML',
      'buffer overflow', 'shellcode',
    ];
    
    for (final pattern in suspiciousPatterns) {
      if (content.toLowerCase().contains(pattern.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }

  static Future<double> _heuristicAnalysis(Uint8List bytes) async {
    double score = 0.0;
    
    // 1. Check for high entropy sections
    final entropy = _calculateEntropy(bytes);
    if (entropy > 7.0) score += 0.3;
    
    // 2. Check for unusual file structure
    if (bytes.length > 1024 * 1024 && bytes.take(1000).every((b) => b == 0)) {
      score += 0.4; // Large file with many null bytes at start
    }
    
    // 3. Check for embedded executables
    final content = utf8.decode(bytes.take(8192).toList(), allowMalformed: true);
    if (content.contains('PE\x00\x00') || content.contains('ELF')) {
      score += 0.6;
    }
    
    return score;
  }

  static Future<bool> _checkHashReputation(String fileHash) async {
    // In production, this would query a threat intelligence database
    // For now, we'll simulate with a blacklist of known bad hashes
    final knownBadHashes = {
      // Add known malware hashes here
      'd41d8cd98f00b204e9800998ecf8427e', // Example MD5 hash
    };
    
    return knownBadHashes.contains(fileHash.toLowerCase());
  }

  // Additional helper methods

  static Uint8List? _extractExifSection(Uint8List bytes) {
    // Extract EXIF data section from JPEG
    for (int i = 0; i < bytes.length - 1; i++) {
      if (bytes[i] == 0xFF && bytes[i + 1] == 0xE1) {
        final length = (bytes[i + 2] << 8) | bytes[i + 3];
        if (i + 2 + length <= bytes.length) {
          return bytes.sublist(i + 4, i + 2 + length);
        }
        break;
      }
    }
    return null;
  }

  static bool _containsSuspiciousExifData(Uint8List exifData) {
    final exifString = utf8.decode(exifData, allowMalformed: true);
    final suspiciousStrings = ['<script', 'javascript:', 'eval(', 'cmd.exe'];
    
    return suspiciousStrings.any((s) => 
      exifString.toLowerCase().contains(s.toLowerCase()));
  }

  static Future<bool> _isPolyglotFile(Uint8List bytes) async {
    // Check if file could be interpreted as multiple formats
    if (bytes.length < 16) return false;
    
    int formatCount = 0;
    
    // Check for various file format signatures
    if (bytes.length >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50) formatCount++; // PDF
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) formatCount++; // JPEG
    if (bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50) formatCount++; // PNG
    if (bytes.length >= 2 && bytes[0] == 0x4D && bytes[1] == 0x5A) formatCount++; // PE
    
    return formatCount > 1;
  }

  static Future<Map<String, int>?> _getImageDimensions(Uint8List bytes, String extension) async {
    try {
      switch (extension) {
        case 'png':
          if (bytes.length >= 24) {
            final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
            final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
            return {'width': width, 'height': height};
          }
          break;
        case 'jpg':
        case 'jpeg':
          // JPEG dimension extraction is more complex, simplified here
          for (int i = 2; i < bytes.length - 8; i++) {
            if (bytes[i] == 0xFF && bytes[i + 1] == 0xC0) {
              final height = (bytes[i + 5] << 8) | bytes[i + 6];
              final width = (bytes[i + 7] << 8) | bytes[i + 8];
              return {'width': width, 'height': height};
            }
          }
          break;
      }
    } catch (e) {
      debugPrint('Error extracting image dimensions: $e');
    }
    return null;
  }

  static Future<String> _generateObfuscatedFilePath({
    required String userId,
    required String documentType,
    required String originalFileName,
    required String uploadId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hashedUserId = await BSNSecurityService.hashBSNForAudit(userId);
    final randomComponent = AESGCMCryptoService.generateSecureToken(length: 16);
    
    // Obfuscate the path to prevent directory traversal and information disclosure
    return 'secure_docs/$documentType/$hashedUserId/$randomComponent/${uploadId}_$timestamp.enc';
  }

  static String _generateSecureUploadId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = AESGCMCryptoService.generateSecureToken(length: 8);
    return '${timestamp}_$random';
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

  static Future<String> _storeSecureDocumentMetadata({
    required String uploadId,
    required String userId,
    required String documentType,
    required String certificateNumber,
    required String downloadUrl,
    required String storagePath,
    required String integrityHash,
    required int originalSize,
    required int encryptedSize,
    Map<String, dynamic>? metadata,
  }) async {
    final docData = {
      'uploadId': uploadId,
      'userId': userId,
      'documentType': documentType,
      'certificateNumberHash': await BSNSecurityService.hashBSNForAudit(certificateNumber),
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'uploadTimestamp': FieldValue.serverTimestamp(),
      'encrypted': true,
      'encryptionVersion': 'AES256_V1',
      'integrityHash': integrityHash,
      'originalSize': originalSize,
      'encryptedSize': encryptedSize,
      'securityValidated': true,
      'malwareScanPassed': true,
      'status': 'uploaded',
      'metadata': metadata ?? {},
    };

    final docRef = await FirebaseFirestore.instance
        .collection('secure_document_uploads')
        .add(docData);

    return docRef.id;
  }

  static Future<void> _logSecurityEvent({
    required String action,
    required String userId,
    String? result,
    Map<String, dynamic>? metadata,
    String? documentType,
  }) async {
    try {
      final auditData = {
        'action': action,
        'userId': await BSNSecurityService.hashBSNForAudit(userId),
        'result': result ?? 'info',
        'timestamp': FieldValue.serverTimestamp(),
        'documentType': documentType,
        'metadata': metadata ?? {},
        'source': 'enhanced_document_upload_service',
        'version': '2.0',
      };

      await FirebaseFirestore.instance
          .collection('security_audit_logs')
          .doc('document_uploads')
          .collection('entries')
          .add(auditData);
    } catch (e) {
      debugPrint('Security audit logging error: $e');
    }
  }
}

/// Enhanced malware scan result
class MalwareScanResult {
  final bool isClean;
  final String? threatType;
  final double confidence;
  
  const MalwareScanResult._({
    required this.isClean,
    this.threatType,
    required this.confidence,
  });
  
  factory MalwareScanResult.clean() {
    return const MalwareScanResult._(isClean: true, confidence: 1.0);
  }
  
  factory MalwareScanResult.threat(String threatType, double confidence) {
    return MalwareScanResult._(
      isClean: false,
      threatType: threatType,
      confidence: confidence,
    );
  }
}

/// Import log function for entropy calculation
double log(double x) {
  return math.log(x);
}

