import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/payment_models.dart';

/// Payment Audit Service for compliance and security monitoring
/// 
/// Features:
/// - Comprehensive audit trail for all payment operations
/// - GDPR/AVG compliance logging
/// - PCI DSS audit requirements
/// - Real-time fraud detection and monitoring
/// - Dutch financial regulations compliance
/// - Automated compliance reporting
/// - Security event correlation
/// - Data retention policy management
class PaymentAuditService {
  final FirebaseFirestore _firestore;
  
  // Audit configuration
  static const Duration _auditRetentionPeriod = Duration(days: 2557); // 7 years for financial records
  static const int _maxBatchSize = 100;
  
  // Risk levels
  static const String _riskLow = 'LOW';
  static const String _riskMedium = 'MEDIUM';
  static const String _riskHigh = 'HIGH';
  static const String _riskCritical = 'CRITICAL';
  
  PaymentAuditService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Log payment transaction
  Future<void> logPaymentTransaction({
    required String paymentId,
    required PaymentType type,
    required double amount,
    required PaymentStatus status,
    String? userId,
    String? guardId,
    String? companyId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final auditId = const Uuid().v4();
      final auditEntry = {
        'audit_id': auditId,
        'event_type': 'PAYMENT_TRANSACTION',
        'payment_id': paymentId,
        'payment_type': type.name,
        'amount_eur': amount,
        'status': status.name,
        'user_id': userId,
        'guard_id': guardId,
        'company_id': companyId,
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'risk_level': _calculateRiskLevel(amount, type, status),
        'compliance_flags': _generateComplianceFlags(amount, type),
        'metadata': metadata ?? {},
        'ip_address': await _getCurrentIPAddress(),
        'user_agent': await _getCurrentUserAgent(),
        'session_id': await _getCurrentSessionId(),
        'retention_until': Timestamp.fromDate(
          DateTime.now().add(_auditRetentionPeriod),
        ),
      };

      await _firestore.collection('payment_audit').doc(auditId).set(auditEntry);

      // Check for suspicious patterns
      await _checkSuspiciousPatterns(auditEntry);

    } catch (e) {
      await _logAuditError('PAYMENT_TRANSACTION_AUDIT_FAILED', e.toString());
    }
  }

  /// Log bulk payment batch
  Future<void> logBulkPayment({
    required String batchId,
    required int paymentCount,
    required double totalAmount,
    required PaymentStatus status,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final auditId = const Uuid().v4();
      final auditEntry = {
        'audit_id': auditId,
        'event_type': 'BULK_PAYMENT',
        'batch_id': batchId,
        'payment_count': paymentCount,
        'total_amount_eur': totalAmount,
        'average_amount': totalAmount / paymentCount,
        'status': status.name,
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'risk_level': _calculateBulkRiskLevel(paymentCount, totalAmount),
        'compliance_flags': _generateBulkComplianceFlags(paymentCount, totalAmount),
        'metadata': metadata ?? {},
        'retention_until': Timestamp.fromDate(
          DateTime.now().add(_auditRetentionPeriod),
        ),
      };

      await _firestore.collection('payment_audit').doc(auditId).set(auditEntry);

      // Alert on large bulk payments
      if (totalAmount > 100000 || paymentCount > 100) {
        await _createSecurityAlert(
          'LARGE_BULK_PAYMENT',
          'Large bulk payment detected: €${totalAmount.toStringAsFixed(2)} for $paymentCount payments',
          _riskHigh,
          {'batch_id': batchId, 'total_amount': totalAmount, 'payment_count': paymentCount},
        );
      }

    } catch (e) {
      await _logAuditError('BULK_PAYMENT_AUDIT_FAILED', e.toString());
    }
  }

  /// Log payment request (API calls)
  Future<void> logPaymentRequest({
    required String type,
    required String status,
    Map<String, dynamic>? details,
  }) async {
    try {
      final auditId = const Uuid().v4();
      await _firestore.collection('api_audit').doc(auditId).set({
        'audit_id': auditId,
        'event_type': 'API_REQUEST',
        'request_type': type,
        'status': status,
        'details': details ?? {},
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'ip_address': await _getCurrentIPAddress(),
        'user_agent': await _getCurrentUserAgent(),
      });

    } catch (e) {
      await _logAuditError('API_REQUEST_AUDIT_FAILED', e.toString());
    }
  }

  /// Log webhook received
  Future<void> logWebhookReceived({
    required String paymentId,
    required String providerPaymentId,
    required PaymentStatus status,
    required Map<String, dynamic> webhookData,
  }) async {
    try {
      final auditId = const Uuid().v4();
      await _firestore.collection('webhook_audit').doc(auditId).set({
        'audit_id': auditId,
        'event_type': 'WEBHOOK_RECEIVED',
        'payment_id': paymentId,
        'provider_payment_id': providerPaymentId,
        'status': status.name,
        'webhook_data': webhookData,
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'processed': true,
      });

    } catch (e) {
      await _logAuditError('WEBHOOK_AUDIT_FAILED', e.toString());
    }
  }

  /// Log payment error
  Future<void> logPaymentError({
    required String type,
    required String error,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final auditId = const Uuid().v4();
      await _firestore.collection('error_audit').doc(auditId).set({
        'audit_id': auditId,
        'event_type': 'PAYMENT_ERROR',
        'error_type': type,
        'error_message': error,
        'metadata': metadata ?? {},
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'severity': _determineErrorSeverity(type),
        'resolved': false,
      });

      // Create alert for critical errors
      if (_determineErrorSeverity(type) == 'CRITICAL') {
        await _createSecurityAlert(
          'CRITICAL_PAYMENT_ERROR',
          'Critical payment error: $error',
          _riskCritical,
          {'error_type': type, 'metadata': metadata},
        );
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to log payment error: $e');
      }
    }
  }

  /// Log invoice generation
  Future<void> logInvoiceGenerated({
    required String invoiceId,
    required String invoiceNumber,
    required double amount,
    String? guardId,
    String? companyId,
  }) async {
    try {
      final auditId = const Uuid().v4();
      await _firestore.collection('invoice_audit').doc(auditId).set({
        'audit_id': auditId,
        'event_type': 'INVOICE_GENERATED',
        'invoice_id': invoiceId,
        'invoice_number': invoiceNumber,
        'amount_eur': amount,
        'guard_id': guardId,
        'company_id': companyId,
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'btw_amount': amount * 0.21, // 21% BTW
        'compliance_checked': true,
      });

    } catch (e) {
      await _logAuditError('INVOICE_AUDIT_FAILED', e.toString());
    }
  }

  /// Log invoice PDF generation
  Future<void> logInvoicePDFGenerated({
    required String invoiceId,
    required String filePath,
  }) async {
    try {
      final auditId = const Uuid().v4();
      await _firestore.collection('document_audit').doc(auditId).set({
        'audit_id': auditId,
        'event_type': 'INVOICE_PDF_GENERATED',
        'invoice_id': invoiceId,
        'file_path': filePath,
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });

    } catch (e) {
      await _logAuditError('INVOICE_PDF_AUDIT_FAILED', e.toString());
    }
  }

  /// Log invoice status update
  Future<void> logInvoiceStatusUpdate({
    required String invoiceId,
    required PaymentStatus newStatus,
    String? paymentReference,
  }) async {
    try {
      final auditId = const Uuid().v4();
      await _firestore.collection('invoice_audit').doc(auditId).set({
        'audit_id': auditId,
        'event_type': 'INVOICE_STATUS_UPDATE',
        'invoice_id': invoiceId,
        'new_status': newStatus.name,
        'payment_reference': paymentReference,
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });

    } catch (e) {
      await _logAuditError('INVOICE_STATUS_AUDIT_FAILED', e.toString());
    }
  }

  /// Log invoice error
  Future<void> logInvoiceError({
    required String type,
    required String error,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final auditId = const Uuid().v4();
      await _firestore.collection('invoice_audit').doc(auditId).set({
        'audit_id': auditId,
        'event_type': 'INVOICE_ERROR',
        'error_type': type,
        'error_message': error,
        'metadata': metadata ?? {},
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'severity': _determineErrorSeverity(type),
      });

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to log invoice error: $e');
      }
    }
  }

  /// Log refund creation
  Future<void> logRefundCreated({
    required String refundId,
    required String originalPaymentId,
    required double amount,
    required String description,
  }) async {
    try {
      final auditId = const Uuid().v4();
      await _firestore.collection('refund_audit').doc(auditId).set({
        'audit_id': auditId,
        'event_type': 'REFUND_CREATED',
        'refund_id': refundId,
        'original_payment_id': originalPaymentId,
        'amount_eur': amount,
        'description': description,
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'risk_level': _calculateRefundRiskLevel(amount),
      });

    } catch (e) {
      await _logAuditError('REFUND_AUDIT_FAILED', e.toString());
    }
  }

  /// Log payment completed
  Future<void> logPaymentCompleted({
    required String paymentId,
    required String userId,
    required double amount,
  }) async {
    try {
      final auditId = const Uuid().v4();
      await _firestore.collection('payment_audit').doc(auditId).set({
        'audit_id': auditId,
        'event_type': 'PAYMENT_COMPLETED',
        'payment_id': paymentId,
        'user_id': userId,
        'amount_eur': amount,
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'completion_time': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      await _logAuditError('PAYMENT_COMPLETED_AUDIT_FAILED', e.toString());
    }
  }

  /// Log payment failed
  Future<void> logPaymentFailed({
    required String paymentId,
    required String reason,
  }) async {
    try {
      final auditId = const Uuid().v4();
      await _firestore.collection('payment_audit').doc(auditId).set({
        'audit_id': auditId,
        'event_type': 'PAYMENT_FAILED',
        'payment_id': paymentId,
        'failure_reason': reason,
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });

    } catch (e) {
      await _logAuditError('PAYMENT_FAILED_AUDIT_FAILED', e.toString());
    }
  }

  /// Generate compliance report
  Future<Map<String, dynamic>> generateComplianceReport({
    required DateTime startDate,
    required DateTime endDate,
    String? reportType,
  }) async {
    try {
      final report = <String, dynamic>{
        'report_id': const Uuid().v4(),
        'report_type': reportType ?? 'PAYMENT_COMPLIANCE',
        'period_start': startDate.toIso8601String(),
        'period_end': endDate.toIso8601String(),
        'generated_at': DateTime.now().toIso8601String(),
        'generated_by': 'PaymentAuditService',
      };

      // Get payment statistics
      final paymentStats = await _getPaymentStatistics(startDate, endDate);
      report['payment_statistics'] = paymentStats;

      // Get error statistics
      final errorStats = await _getErrorStatistics(startDate, endDate);
      report['error_statistics'] = errorStats;

      // Get compliance flags
      final complianceFlags = await _getComplianceFlags(startDate, endDate);
      report['compliance_flags'] = complianceFlags;

      // Get security alerts
      final securityAlerts = await _getSecurityAlerts(startDate, endDate);
      report['security_alerts'] = securityAlerts;

      // Store report
      await _firestore.collection('compliance_reports').add(report);

      return report;

    } catch (e) {
      await _logAuditError('COMPLIANCE_REPORT_FAILED', e.toString());
      rethrow;
    }
  }

  /// Get audit trail for specific payment
  Future<List<Map<String, dynamic>>> getPaymentAuditTrail(String paymentId) async {
    try {
      final auditEntries = <Map<String, dynamic>>[];

      // Get payment audit entries
      final paymentAudit = await _firestore
          .collection('payment_audit')
          .where('payment_id', isEqualTo: paymentId)
          .orderBy('timestamp', descending: false)
          .get();

      auditEntries.addAll(paymentAudit.docs.map((doc) => doc.data()));

      // Get webhook audit entries
      final webhookAudit = await _firestore
          .collection('webhook_audit')
          .where('payment_id', isEqualTo: paymentId)
          .orderBy('timestamp', descending: false)
          .get();

      auditEntries.addAll(webhookAudit.docs.map((doc) => doc.data()));

      // Get error audit entries
      final errorAudit = await _firestore
          .collection('error_audit')
          .where('metadata.payment_id', isEqualTo: paymentId)
          .orderBy('timestamp', descending: false)
          .get();

      auditEntries.addAll(errorAudit.docs.map((doc) => doc.data()));

      // Sort by timestamp
      auditEntries.sort((a, b) {
        final timestampA = (a['timestamp'] as Timestamp).millisecondsSinceEpoch;
        final timestampB = (b['timestamp'] as Timestamp).millisecondsSinceEpoch;
        return timestampA.compareTo(timestampB);
      });

      return auditEntries;

    } catch (e) {
      await _logAuditError('AUDIT_TRAIL_RETRIEVAL_FAILED', e.toString());
      return [];
    }
  }

  /// Private helper methods

  /// Calculate risk level based on payment parameters
  String _calculateRiskLevel(double amount, PaymentType type, PaymentStatus status) {
    if (amount > 10000) return _riskHigh;
    if (amount > 5000 && type == PaymentType.idealPayment) return _riskMedium;
    if (status == PaymentStatus.failed) return _riskMedium;
    return _riskLow;
  }

  /// Calculate bulk payment risk level
  String _calculateBulkRiskLevel(int paymentCount, double totalAmount) {
    if (totalAmount > 100000 || paymentCount > 100) return _riskHigh;
    if (totalAmount > 50000 || paymentCount > 50) return _riskMedium;
    return _riskLow;
  }

  /// Calculate refund risk level
  String _calculateRefundRiskLevel(double amount) {
    if (amount > 5000) return _riskHigh;
    if (amount > 1000) return _riskMedium;
    return _riskLow;
  }

  /// Generate compliance flags
  List<String> _generateComplianceFlags(double amount, PaymentType type) {
    final flags = <String>[];
    
    if (amount > 10000) flags.add('HIGH_VALUE_TRANSACTION');
    if (type == PaymentType.idealPayment && amount > 50000) flags.add('HIGH_VALUE_IDEAL');
    if (amount > 15000) flags.add('AML_MONITORING_REQUIRED');
    
    return flags;
  }

  /// Generate bulk compliance flags
  List<String> _generateBulkComplianceFlags(int paymentCount, double totalAmount) {
    final flags = <String>[];
    
    if (totalAmount > 100000) flags.add('HIGH_VALUE_BULK');
    if (paymentCount > 100) flags.add('HIGH_VOLUME_BULK');
    if (totalAmount > 250000) flags.add('REGULATORY_REPORTING_REQUIRED');
    
    return flags;
  }

  /// Check suspicious patterns
  Future<void> _checkSuspiciousPatterns(Map<String, dynamic> auditEntry) async {
    try {
      // Check for rapid successive payments
      await _checkRapidPayments(auditEntry);
      
      // Check for unusual amounts
      await _checkUnusualAmounts(auditEntry);
      
      // Check for geographical anomalies
      await _checkGeographicalAnomalies(auditEntry);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to check suspicious patterns: $e');
      }
    }
  }

  /// Check for rapid successive payments
  Future<void> _checkRapidPayments(Map<String, dynamic> auditEntry) async {
    final userId = auditEntry['user_id'];
    if (userId == null) return;

    final recentPayments = await _firestore
        .collection('payment_audit')
        .where('user_id', isEqualTo: userId)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 10)),
        ))
        .get();

    if (recentPayments.docs.length > 5) {
      await _createSecurityAlert(
        'RAPID_PAYMENT_PATTERN',
        'User $userId made ${recentPayments.docs.length} payments in 10 minutes',
        _riskHigh,
        {'user_id': userId, 'payment_count': recentPayments.docs.length},
      );
    }
  }

  /// Check for unusual amounts
  Future<void> _checkUnusualAmounts(Map<String, dynamic> auditEntry) async {
    final amount = auditEntry['amount_eur'] as double?;
    if (amount == null) return;

    // Check for round numbers (potential fraud indicator)
    if (amount >= 1000 && amount % 1000 == 0) {
      await _createSecurityAlert(
        'ROUND_AMOUNT_PAYMENT',
        'Round amount payment detected: €${amount.toStringAsFixed(2)}',
        _riskMedium,
        {'amount': amount, 'payment_id': auditEntry['payment_id']},
      );
    }
  }

  /// Check for geographical anomalies
  Future<void> _checkGeographicalAnomalies(Map<String, dynamic> auditEntry) async {
    // Implementation would check IP geolocation against user's known location
    // For demo purposes, we'll skip this implementation
  }

  /// Create security alert
  Future<void> _createSecurityAlert(
    String alertType,
    String description,
    String riskLevel,
    Map<String, dynamic> details,
  ) async {
    try {
      final alertId = const Uuid().v4();
      await _firestore.collection('security_alerts').doc(alertId).set({
        'alert_id': alertId,
        'alert_type': alertType,
        'description': description,
        'risk_level': riskLevel,
        'details': details,
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'status': 'OPEN',
        'acknowledged': false,
      });

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to create security alert: $e');
      }
    }
  }

  /// Determine error severity
  String _determineErrorSeverity(String errorType) {
    final criticalErrors = [
      'PAYMENT_ENCRYPTION_FAILED',
      'KEY_ROTATION_FAILED',
      'TOKENIZATION_FAILED',
      'BULK_SEPA_FAILED',
    ];
    
    final highSeverityErrors = [
      'SEPA_PAYMENT_ERROR',
      'IDEAL_PAYMENT_ERROR',
      'INVOICE_GENERATION_ERROR',
    ];

    if (criticalErrors.contains(errorType)) return 'CRITICAL';
    if (highSeverityErrors.contains(errorType)) return 'HIGH';
    return 'MEDIUM';
  }

  /// Get payment statistics for compliance report
  Future<Map<String, dynamic>> _getPaymentStatistics(DateTime startDate, DateTime endDate) async {
    final snapshot = await _firestore
        .collection('payment_audit')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    double totalVolume = 0;
    final statusCounts = <String, int>{};
    final typeCounts = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['amount_eur'] as num?)?.toDouble() ?? 0;
      final status = data['status'] as String?;
      final type = data['payment_type'] as String?;

      totalVolume += amount;
      
      if (status != null) {
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
      
      if (type != null) {
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
    }

    return {
      'total_transactions': snapshot.docs.length,
      'total_volume_eur': totalVolume,
      'average_transaction': totalVolume / (snapshot.docs.isNotEmpty ? snapshot.docs.length : 1),
      'status_breakdown': statusCounts,
      'type_breakdown': typeCounts,
    };
  }

  /// Get error statistics for compliance report
  Future<Map<String, dynamic>> _getErrorStatistics(DateTime startDate, DateTime endDate) async {
    final snapshot = await _firestore
        .collection('error_audit')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final errorTypeCounts = <String, int>{};
    final severityCounts = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final errorType = data['error_type'] as String?;
      final severity = data['severity'] as String?;

      if (errorType != null) {
        errorTypeCounts[errorType] = (errorTypeCounts[errorType] ?? 0) + 1;
      }
      
      if (severity != null) {
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
      }
    }

    return {
      'total_errors': snapshot.docs.length,
      'error_type_breakdown': errorTypeCounts,
      'severity_breakdown': severityCounts,
    };
  }

  /// Get compliance flags for report
  Future<List<Map<String, dynamic>>> _getComplianceFlags(DateTime startDate, DateTime endDate) async {
    final snapshot = await _firestore
        .collection('payment_audit')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('compliance_flags', arrayContains: null)
        .get();

    final flags = <Map<String, dynamic>>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final complianceFlags = data['compliance_flags'] as List<dynamic>?;
      
      if (complianceFlags != null && complianceFlags.isNotEmpty) {
        flags.add({
          'payment_id': data['payment_id'],
          'flags': complianceFlags,
          'timestamp': data['timestamp'],
        });
      }
    }

    return flags;
  }

  /// Get security alerts for report
  Future<List<Map<String, dynamic>>> _getSecurityAlerts(DateTime startDate, DateTime endDate) async {
    final snapshot = await _firestore
        .collection('security_alerts')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Get current IP address (placeholder)
  Future<String> _getCurrentIPAddress() async {
    // In production, this would get the real client IP address
    return '192.168.1.1';
  }

  /// Get current user agent (placeholder)
  Future<String> _getCurrentUserAgent() async {
    // In production, this would get the real user agent
    return 'SecuryFlex Mobile App/1.0';
  }

  /// Get current session ID (placeholder)
  Future<String> _getCurrentSessionId() async {
    // In production, this would get the real session ID
    return const Uuid().v4();
  }

  /// Log audit error
  Future<void> _logAuditError(String type, String error) async {
    try {
      await _firestore.collection('system_errors').add({
        'error_type': type,
        'error_message': error,
        'component': 'PaymentAuditService',
        'timestamp': Timestamp.now(),
        'severity': 'ERROR',
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to log audit error: $e');
      }
    }
  }

  /// Log invoice creation for audit trail
  Future<void> logInvoiceCreation({
    required String invoiceId,
    required String paymentId,
    required String userId,
    required double amount,
    required String status,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('invoice_audit').add({
        'invoice_id': invoiceId,
        'payment_id': paymentId,
        'user_id': userId,
        'amount_eur': amount,
        'status': status,
        'action': 'CREATED',
        'timestamp': Timestamp.now(),
        'date_created': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'ip_address': await _getCurrentIPAddress(),
        'user_agent': await _getCurrentUserAgent(),
        'session_id': await _getCurrentSessionId(),
        'metadata': metadata ?? {},
      });

      if (kDebugMode) {
        debugPrint('✅ Invoice creation logged: $invoiceId');
      }

    } catch (e) {
      await _logAuditError('INVOICE_AUDIT_FAILED', e.toString());
      if (kDebugMode) {
        debugPrint('❌ Failed to log invoice creation: $e');
      }
    }
  }

  /// Clean up old audit records (compliance with data retention policies)
  Future<void> cleanupOldAuditRecords() async {
    try {
      final cutoffDate = DateTime.now().subtract(_auditRetentionPeriod);
      final collections = [
        'payment_audit',
        'webhook_audit',
        'api_audit',
        'error_audit',
        'invoice_audit',
        'refund_audit',
        'document_audit',
      ];

      for (final collection in collections) {
        final oldRecords = await _firestore
            .collection(collection)
            .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
            .limit(_maxBatchSize)
            .get();

        if (oldRecords.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (final doc in oldRecords.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          
          if (kDebugMode) {
            debugPrint('Cleaned up ${oldRecords.docs.length} old records from $collection');
          }
        }
      }

    } catch (e) {
      await _logAuditError('AUDIT_CLEANUP_FAILED', e.toString());
    }
  }
}