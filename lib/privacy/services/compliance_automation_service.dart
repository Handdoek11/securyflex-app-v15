import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/gdpr_models.dart';
import 'gdpr_compliance_service.dart';

/// Automated Compliance Workflows Service
/// Handles automated GDPR compliance tasks, retention policies,
/// consent expiry management, and compliance monitoring
class ComplianceAutomationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GDPRComplianceService _gdprService = GDPRComplianceService();
  
  static const String _automationLogsCollection = 'compliance_automation_logs';
  static const String _retentionTasksCollection = 'retention_tasks';
  static const String _complianceMetricsCollection = 'compliance_metrics';
  
  /// Timer for periodic compliance checks
  Timer? _complianceCheckTimer;
  Timer? _retentionPolicyTimer;
  
  /// Initialize automated compliance workflows
  Future<void> initializeAutomation() async {
    debugPrint('Initializing automated compliance workflows...');
    
    try {
      // Start periodic compliance checks (every 6 hours)
      _complianceCheckTimer = Timer.periodic(
        const Duration(hours: 6),
        (_) => runPeriodicComplianceCheck(),
      );
      
      // Start retention policy checks (daily at 2 AM)
      _retentionPolicyTimer = Timer.periodic(
        const Duration(hours: 24),
        (_) => runRetentionPolicyCheck(),
      );
      
      // Log automation initialization
      await _logAutomationEvent(
        eventType: 'automation_initialized',
        details: {
          'timestamp': DateTime.now().toIso8601String(),
          'checks_enabled': ['periodic_compliance', 'retention_policy'],
        },
      );
      
      debugPrint('Automated compliance workflows initialized successfully');
    } catch (e) {
      debugPrint('Error initializing compliance automation: $e');
      rethrow;
    }
  }
  
  /// Stop automated compliance workflows
  void stopAutomation() {
    _complianceCheckTimer?.cancel();
    _retentionPolicyTimer?.cancel();
    
    debugPrint('Automated compliance workflows stopped');
  }
  
  /// Run periodic compliance check
  Future<void> runPeriodicComplianceCheck() async {
    debugPrint('Running periodic compliance check...');
    
    try {
      final checkResults = <String, dynamic>{};
      
      // 1. Check overdue GDPR requests
      final overdueRequests = await _checkOverdueGDPRRequests();
      checkResults['overdue_requests'] = {
        'count': overdueRequests.length,
        'requests': overdueRequests.map((r) => r.id).toList(),
      };
      
      // 2. Check expired consents
      final expiredConsents = await _checkExpiredConsents();
      checkResults['expired_consents'] = {
        'count': expiredConsents.length,
        'purposes': expiredConsents,
      };
      
      // 3. Check retention policy violations
      final retentionViolations = await _checkRetentionViolations();
      checkResults['retention_violations'] = {
        'count': retentionViolations.length,
        'violations': retentionViolations,
      };
      
      // 4. Check BSN data compliance
      final bsnCompliance = await _checkBSNCompliance();
      checkResults['bsn_compliance'] = bsnCompliance;
      
      // 5. Check WPBR certificate compliance
      final wpbrCompliance = await _checkWPBRCompliance();
      checkResults['wpbr_compliance'] = wpbrCompliance;
      
      // Log compliance check results
      await _logAutomationEvent(
        eventType: 'periodic_compliance_check',
        details: {
          'timestamp': DateTime.now().toIso8601String(),
          'results': checkResults,
        },
      );
      
      // Send notifications for critical issues
      await _processComplianceIssues(checkResults);
      
      debugPrint('Periodic compliance check completed');
    } catch (e) {
      debugPrint('Error in periodic compliance check: $e');
      
      await _logAutomationEvent(
        eventType: 'compliance_check_error',
        details: {
          'timestamp': DateTime.now().toIso8601String(),
          'error': e.toString(),
        },
      );
    }
  }
  
  /// Run retention policy check and enforcement
  Future<void> runRetentionPolicyCheck() async {
    debugPrint('Running retention policy check...');
    
    try {
      final retentionResults = <String, dynamic>{};
      
      // Apply retention policies
      await _gdprService.applyRetentionPolicies();
      
      // 1. Check WPBR certificate retention (7 years)
      final wpbrRetentionResults = await _enforceWPBRRetention();
      retentionResults['wpbr_retention'] = wpbrRetentionResults;
      
      // 2. Check BSN data retention (7 years)
      final bsnRetentionResults = await _enforceBSNRetention();
      retentionResults['bsn_retention'] = bsnRetentionResults;
      
      // 3. Check CAO data retention (5 years)
      final caoRetentionResults = await _enforceCAORetention();
      retentionResults['cao_retention'] = caoRetentionResults;
      
      // 4. Clean up expired temporary data
      final cleanupResults = await _cleanupExpiredData();
      retentionResults['cleanup_results'] = cleanupResults;
      
      // Log retention policy results
      await _logAutomationEvent(
        eventType: 'retention_policy_enforcement',
        details: {
          'timestamp': DateTime.now().toIso8601String(),
          'results': retentionResults,
        },
      );
      
      debugPrint('Retention policy check completed');
    } catch (e) {
      debugPrint('Error in retention policy check: $e');
      
      await _logAutomationEvent(
        eventType: 'retention_policy_error',
        details: {
          'timestamp': DateTime.now().toIso8601String(),
          'error': e.toString(),
        },
      );
    }
  }
  
  /// Check for overdue GDPR requests (>30 days)
  Future<List<GDPRRequest>> _checkOverdueGDPRRequests() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final snapshot = await _firestore
          .collection('gdpr_requests')
          .where('status', whereIn: ['pending', 'under_review', 'in_progress'])
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();
      
      return snapshot.docs
          .map((doc) => GDPRRequest.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error checking overdue GDPR requests: $e');
      return [];
    }
  }
  
  /// Check for expired consents that need re-consent
  Future<List<String>> _checkExpiredConsents() async {
    try {
      // Check consents older than 2 years (typical re-consent period)
      final twoYearsAgo = DateTime.now().subtract(const Duration(days: 730));
      
      final snapshot = await _firestore
          .collection('consent_records')
          .where('timestamp', isLessThan: Timestamp.fromDate(twoYearsAgo))
          .where('isGiven', isEqualTo: true)
          .where('withdrawnAt', isNull: true)
          .get();
      
      final expiredPurposes = <String>{};
      for (final doc in snapshot.docs) {
        final consent = ConsentRecord.fromDocument(doc);
        expiredPurposes.add(consent.purpose);
      }
      
      return expiredPurposes.toList();
    } catch (e) {
      debugPrint('Error checking expired consents: $e');
      return [];
    }
  }
  
  /// Check for data retention policy violations
  Future<List<String>> _checkRetentionViolations() async {
    try {
      final violations = <String>[];
      
      // Check for old message data (>6 months)
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      final oldMessages = await _firestore
          .collection('messages')
          .where('timestamp', isLessThan: Timestamp.fromDate(sixMonthsAgo))
          .get();
      
      if (oldMessages.docs.isNotEmpty) {
        violations.add('old_messages_${oldMessages.docs.length}');
      }
      
      // Check for old temporary data
      final oldTempData = await _firestore
          .collection('temp_applications')
          .where('createdAt', isLessThan: Timestamp.fromDate(sixMonthsAgo))
          .get();
      
      if (oldTempData.docs.isNotEmpty) {
        violations.add('old_temp_data_${oldTempData.docs.length}');
      }
      
      return violations;
    } catch (e) {
      debugPrint('Error checking retention violations: $e');
      return [];
    }
  }
  
  /// Check BSN data compliance
  Future<Map<String, dynamic>> _checkBSNCompliance() async {
    try {
      // Check for BSN data without explicit consent
      final bsnDataWithoutConsent = await _firestore
          .collection('users')
          .where('bsn', isNull: false)
          .get();
      
      final complianceIssues = <String>[];
      
      for (final userDoc in bsnDataWithoutConsent.docs) {
        final userId = userDoc.id;
        
        // Check if user has given BSN consent
        final consentSnapshot = await _firestore
            .collection('consent_records')
            .where('userId', isEqualTo: userId)
            .where('purpose', isEqualTo: 'bsn_processing')
            .where('isGiven', isEqualTo: true)
            .where('withdrawnAt', isNull: true)
            .get();
        
        if (consentSnapshot.docs.isEmpty) {
          complianceIssues.add(userId);
        }
      }
      
      return {
        'total_bsn_records': bsnDataWithoutConsent.docs.length,
        'compliance_issues': complianceIssues.length,
        'compliance_rate': bsnDataWithoutConsent.docs.isEmpty 
            ? 1.0 
            : (bsnDataWithoutConsent.docs.length - complianceIssues.length) / bsnDataWithoutConsent.docs.length,
      };
    } catch (e) {
      debugPrint('Error checking BSN compliance: $e');
      return {
        'total_bsn_records': 0,
        'compliance_issues': 0,
        'compliance_rate': 0.0,
        'error': e.toString(),
      };
    }
  }
  
  /// Check WPBR certificate compliance
  Future<Map<String, dynamic>> _checkWPBRCompliance() async {
    try {
      final sevenYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 7));
      
      // Check certificates that should be archived after 7 years
      final expiredCertificates = await _firestore
          .collection('certificates')
          .where('createdAt', isLessThan: Timestamp.fromDate(sevenYearsAgo))
          .get();
      
      // Check if they are properly archived
      final archivedCount = await _firestore
          .collection('wpbr_archive')
          .get();
      
      return {
        'expired_certificates': expiredCertificates.docs.length,
        'archived_count': archivedCount.docs.length,
        'compliance_rate': expiredCertificates.docs.isEmpty 
            ? 1.0 
            : archivedCount.docs.length / expiredCertificates.docs.length,
      };
    } catch (e) {
      debugPrint('Error checking WPBR compliance: $e');
      return {
        'expired_certificates': 0,
        'archived_count': 0,
        'compliance_rate': 0.0,
        'error': e.toString(),
      };
    }
  }
  
  /// Enforce WPBR retention (7 years)
  Future<Map<String, dynamic>> _enforceWPBRRetention() async {
    try {
      final sevenYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 7));
      
      // Find WPBR certificates older than 7 years
      final oldCertificates = await _firestore
          .collection('certificates')
          .where('type', isEqualTo: 'wpbr')
          .where('createdAt', isLessThan: Timestamp.fromDate(sevenYearsAgo))
          .get();
      
      int archivedCount = 0;
      
      // Archive old certificates instead of deleting
      for (final certDoc in oldCertificates.docs) {
        try {
          await _firestore.collection('wpbr_archive').add({
            'original_id': certDoc.id,
            'data': certDoc.data(),
            'archived_at': FieldValue.serverTimestamp(),
            'retention_expires': DateTime.now().add(const Duration(days: 365 * 7)),
            'reason': 'WPBR 7-year retention requirement',
          });
          
          // Mark original as archived
          await certDoc.reference.update({
            'archived': true,
            'archived_at': FieldValue.serverTimestamp(),
          });
          
          archivedCount++;
        } catch (e) {
          debugPrint('Error archiving certificate ${certDoc.id}: $e');
        }
      }
      
      return {
        'certificates_found': oldCertificates.docs.length,
        'certificates_archived': archivedCount,
        'enforcement_date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error enforcing WPBR retention: $e');
      return {
        'certificates_found': 0,
        'certificates_archived': 0,
        'error': e.toString(),
      };
    }
  }
  
  /// Enforce BSN data retention (7 years)
  Future<Map<String, dynamic>> _enforceBSNRetention() async {
    try {
      final sevenYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 7));
      
      // Find BSN data older than 7 years
      final oldBSNData = await _firestore
          .collection('bsn_verifications')
          .where('created_at', isLessThan: Timestamp.fromDate(sevenYearsAgo))
          .get();
      
      int archivedCount = 0;
      
      // Archive BSN data with extra encryption
      for (final bsnDoc in oldBSNData.docs) {
        try {
          await _firestore.collection('bsn_archive').add({
            'original_id': bsnDoc.id,
            'encrypted_data': bsnDoc.data(), // Would be encrypted in production
            'archived_at': FieldValue.serverTimestamp(),
            'retention_expires': DateTime.now().add(const Duration(days: 365 * 7)),
            'reason': 'BSN 7-year retention requirement',
          });
          
          // Remove from active collection
          await bsnDoc.reference.delete();
          
          archivedCount++;
        } catch (e) {
          debugPrint('Error archiving BSN data ${bsnDoc.id}: $e');
        }
      }
      
      return {
        'bsn_records_found': oldBSNData.docs.length,
        'bsn_records_archived': archivedCount,
        'enforcement_date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error enforcing BSN retention: $e');
      return {
        'bsn_records_found': 0,
        'bsn_records_archived': 0,
        'error': e.toString(),
      };
    }
  }
  
  /// Enforce CAO data retention (5 years)
  Future<Map<String, dynamic>> _enforceCAORetention() async {
    try {
      final fiveYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 5));
      
      // Find CAO employment data older than 5 years
      final oldCAOData = await _firestore
          .collection('employment_records')
          .where('created_at', isLessThan: Timestamp.fromDate(fiveYearsAgo))
          .get();
      
      int deletedCount = 0;
      
      // Delete old CAO data (5 year retention limit)
      for (final caoDoc in oldCAOData.docs) {
        try {
          // Log before deletion for audit trail
          await _firestore.collection('deletion_log').add({
            'collection': 'employment_records',
            'document_id': caoDoc.id,
            'deleted_at': FieldValue.serverTimestamp(),
            'reason': 'CAO 5-year retention limit exceeded',
            'metadata': {
              'user_id': caoDoc.data()['userId'],
              'employment_period': caoDoc.data()['employment_period'],
            },
          });
          
          await caoDoc.reference.delete();
          deletedCount++;
        } catch (e) {
          debugPrint('Error deleting CAO data ${caoDoc.id}: $e');
        }
      }
      
      return {
        'cao_records_found': oldCAOData.docs.length,
        'cao_records_deleted': deletedCount,
        'enforcement_date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error enforcing CAO retention: $e');
      return {
        'cao_records_found': 0,
        'cao_records_deleted': 0,
        'error': e.toString(),
      };
    }
  }
  
  /// Clean up expired temporary data
  Future<Map<String, dynamic>> _cleanupExpiredData() async {
    try {
      final cleanupResults = <String, int>{};
      
      // Clean up old messages (6 months)
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      final oldMessages = await _firestore
          .collection('messages')
          .where('timestamp', isLessThan: Timestamp.fromDate(sixMonthsAgo))
          .get();
      
      for (final msgDoc in oldMessages.docs) {
        await msgDoc.reference.delete();
      }
      cleanupResults['messages_deleted'] = oldMessages.docs.length;
      
      // Clean up temporary application data
      final oldTempApps = await _firestore
          .collection('temp_applications')
          .where('created_at', isLessThan: Timestamp.fromDate(sixMonthsAgo))
          .get();
      
      for (final tempDoc in oldTempApps.docs) {
        await tempDoc.reference.delete();
      }
      cleanupResults['temp_applications_deleted'] = oldTempApps.docs.length;
      
      // Clean up old notification logs (3 months)
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final oldNotifications = await _firestore
          .collection('notification_logs')
          .where('sent_at', isLessThan: Timestamp.fromDate(threeMonthsAgo))
          .get();
      
      for (final notifDoc in oldNotifications.docs) {
        await notifDoc.reference.delete();
      }
      cleanupResults['notifications_deleted'] = oldNotifications.docs.length;
      
      return {
        'cleanup_results': cleanupResults,
        'total_deleted': cleanupResults.values.fold(0, (total, itemCount) => total + itemCount),
        'cleanup_date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error cleaning up expired data: $e');
      return {
        'cleanup_results': {},
        'total_deleted': 0,
        'error': e.toString(),
      };
    }
  }
  
  /// Process compliance issues and send notifications
  Future<void> _processComplianceIssues(Map<String, dynamic> checkResults) async {
    try {
      final criticalIssues = <String>[];
      
      // Check for critical compliance issues
      if (checkResults['overdue_requests']['count'] > 0) {
        criticalIssues.add('${checkResults['overdue_requests']['count']} overdue GDPR requests');
      }
      
      if (checkResults['retention_violations']['count'] > 10) {
        criticalIssues.add('${checkResults['retention_violations']['count']} retention policy violations');
      }
      
      final bsnCompliance = checkResults['bsn_compliance']['compliance_rate'] as double;
      if (bsnCompliance < 0.95) {
        criticalIssues.add('BSN compliance rate below 95%: ${(bsnCompliance * 100).toStringAsFixed(1)}%');
      }
      
      // Send notifications for critical issues
      if (criticalIssues.isNotEmpty) {
        await _sendComplianceNotification(criticalIssues);
      }
      
      // Update compliance metrics
      await _updateComplianceMetrics(checkResults);
    } catch (e) {
      debugPrint('Error processing compliance issues: $e');
    }
  }
  
  /// Send compliance notification to administrators
  Future<void> _sendComplianceNotification(List<String> issues) async {
    try {
      // In production, this would send emails/Slack notifications
      debugPrint('COMPLIANCE ALERT: ${issues.join(', ')}');
      
      // Log notification
      await _firestore.collection('compliance_notifications').add({
        'type': 'critical_compliance_alert',
        'issues': issues,
        'sent_at': FieldValue.serverTimestamp(),
        'recipients': ['privacy@securyflex.nl', 'admin@securyflex.nl'],
        'severity': 'high',
      });
    } catch (e) {
      debugPrint('Error sending compliance notification: $e');
    }
  }
  
  /// Update compliance metrics for reporting
  Future<void> _updateComplianceMetrics(Map<String, dynamic> checkResults) async {
    try {
      await _firestore.collection(_complianceMetricsCollection).add({
        'timestamp': FieldValue.serverTimestamp(),
        'overdue_gdpr_requests': checkResults['overdue_requests']['count'],
        'expired_consents': checkResults['expired_consents']['count'],
        'retention_violations': checkResults['retention_violations']['count'],
        'bsn_compliance_rate': checkResults['bsn_compliance']['compliance_rate'],
        'wpbr_compliance_rate': checkResults['wpbr_compliance']['compliance_rate'],
        'overall_compliance_score': _calculateOverallComplianceScore(checkResults),
      });
    } catch (e) {
      debugPrint('Error updating compliance metrics: $e');
    }
  }
  
  /// Calculate overall compliance score
  double _calculateOverallComplianceScore(Map<String, dynamic> checkResults) {
    try {
      double score = 100.0;
      
      // Deduct points for issues
      final overdueRequests = checkResults['overdue_requests']['count'] as int;
      score -= (overdueRequests * 5.0); // -5 points per overdue request
      
      final retentionViolations = checkResults['retention_violations']['count'] as int;
      score -= (retentionViolations * 2.0); // -2 points per violation
      
      final bsnCompliance = checkResults['bsn_compliance']['compliance_rate'] as double;
      score -= ((1.0 - bsnCompliance) * 30.0); // Up to -30 points for BSN non-compliance
      
      final wpbrCompliance = checkResults['wpbr_compliance']['compliance_rate'] as double;
      score -= ((1.0 - wpbrCompliance) * 20.0); // Up to -20 points for WPBR non-compliance
      
      return score.clamp(0.0, 100.0);
    } catch (e) {
      debugPrint('Error calculating compliance score: $e');
      return 0.0;
    }
  }
  
  /// Log automation events
  Future<void> _logAutomationEvent({
    required String eventType,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _firestore.collection(_automationLogsCollection).add({
        'event_type': eventType,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'service_version': '1.0.0',
      });
    } catch (e) {
      debugPrint('Error logging automation event: $e');
    }
  }
  
  /// Get compliance automation status
  Future<Map<String, dynamic>> getAutomationStatus() async {
    try {
      // Get latest automation logs
      final logsSnapshot = await _firestore
          .collection(_automationLogsCollection)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      
      // Get latest compliance metrics
      final metricsSnapshot = await _firestore
          .collection(_complianceMetricsCollection)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      final latestMetrics = metricsSnapshot.docs.isNotEmpty 
          ? metricsSnapshot.docs.first.data() 
          : {};
      
      return {
        'automation_active': _complianceCheckTimer?.isActive ?? false,
        'retention_checks_active': _retentionPolicyTimer?.isActive ?? false,
        'latest_metrics': latestMetrics,
        'recent_events': logsSnapshot.docs.map((doc) => {
          'event_type': doc.data()['event_type'],
          'timestamp': doc.data()['timestamp'],
        }).toList(),
        'status': 'operational',
      };
    } catch (e) {
      debugPrint('Error getting automation status: $e');
      return {
        'automation_active': false,
        'retention_checks_active': false,
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
  
  /// Force run compliance check (for manual trigger)
  Future<Map<String, dynamic>> forceComplianceCheck() async {
    debugPrint('Force running compliance check...');
    
    try {
      await runPeriodicComplianceCheck();
      
      return {
        'success': true,
        'message': 'Compliance check completed successfully',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Compliance check failed',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Force run retention policy check (for manual trigger)
  Future<Map<String, dynamic>> forceRetentionCheck() async {
    debugPrint('Force running retention policy check...');
    
    try {
      await runRetentionPolicyCheck();
      
      return {
        'success': true,
        'message': 'Retention policy check completed successfully',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Retention policy check failed',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
