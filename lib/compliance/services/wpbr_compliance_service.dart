import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// WPBR (Wet Particuliere Beveiligingsorganisaties) Compliance Service
/// Ensures compliance with Dutch private security regulations
class WPBRComplianceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // WPBR certificate validity periods
  static const Duration wpbrValidityPeriod = Duration(days: 1825); // 5 years
  static const Duration retrainingRequiredDays = Duration(days: 90); // 3 months before expiry
  static const Duration retentionPeriod = Duration(days: 2555); // 7 years
  
  // WPBR required certificate levels
  static const List<String> requiredCertificates = [
    'beveiligingsmedewerker_2',
    'wpbr_basis',
  ];
  
  // Enhanced certificate requirements by security level
  static const Map<String, List<String>> enhancedRequirements = {
    'crowd_control': ['beveiligingsmedewerker_2', 'crowd_control', 'ehbo'],
    'personal_protection': ['beveiligingsmedewerker_2', 'persoonbeveiliging', 'ehbo'],
    'cash_transport': ['beveiligingsmedewerker_2', 'geld_waardetransport', 'rijbewijs_b'],
    'aviation_security': ['beveiligingsmedewerker_2', 'luchtvaartbeveiliging'],
  };
  
  /// Validate WPBR compliance for a security guard
  Future<Map<String, dynamic>> validateGuardCompliance({
    required String guardId,
    required String companyId,
    required List<String> assignedSecurityLevels,
  }) async {
    
    try {
      final complianceResults = <String, dynamic>{};
      
      // Get guard's certificates
      final certificates = await _getGuardCertificates(guardId);
      complianceResults['certificates'] = certificates;
      
      // Check basic WPBR requirements
      final basicCompliance = _checkBasicWPBRCompliance(certificates);
      complianceResults['basic_compliance'] = basicCompliance;
      
      // Check enhanced requirements for assigned security levels
      final enhancedCompliance = _checkEnhancedCompliance(certificates, assignedSecurityLevels);
      complianceResults['enhanced_compliance'] = enhancedCompliance;
      
      // Check certificate validity and expiration
      final validityCheck = _checkCertificateValidity(certificates);
      complianceResults['validity_check'] = validityCheck;
      
      // Check training requirements
      final trainingCompliance = await _checkTrainingRequirements(guardId, certificates);
      complianceResults['training_compliance'] = trainingCompliance;
      
      // Verify BSN and identity compliance
      final identityCompliance = await _checkIdentityCompliance(guardId);
      complianceResults['identity_compliance'] = identityCompliance;
      
      // Check incident reporting compliance
      final incidentCompliance = await _checkIncidentReporting(guardId);
      complianceResults['incident_compliance'] = incidentCompliance;
      
      // Calculate overall compliance score
      final overallScore = _calculateComplianceScore(complianceResults);
      complianceResults['overall_score'] = overallScore;
      
      // Determine compliance status
      complianceResults['compliance_status'] = _determineComplianceStatus(overallScore);
      
      // Generate recommendations
      complianceResults['recommendations'] = _generateRecommendations(complianceResults);
      
      // Required actions
      complianceResults['required_actions'] = _getRequiredActions(complianceResults);
      
      // Log compliance check
      await _logComplianceCheck(guardId, companyId, complianceResults);
      
      return complianceResults;
      
    } catch (e) {
      throw Exception('WPBR compliance validation failed: $e');
    }
  }
  
  /// Validate company WPBR compliance
  Future<Map<String, dynamic>> validateCompanyCompliance({
    required String companyId,
  }) async {
    
    try {
      final complianceResults = <String, dynamic>{};
      
      // Get company details and registration
      final companyDetails = await _getCompanyDetails(companyId);
      complianceResults['company_details'] = companyDetails;
      
      // Check WPBR license validity
      final licenseCompliance = await _checkCompanyLicense(companyId);
      complianceResults['license_compliance'] = licenseCompliance;
      
      // Check all employed guards' compliance
      final guardCompliance = await _checkAllGuardsCompliance(companyId);
      complianceResults['guards_compliance'] = guardCompliance;
      
      // Check insurance requirements
      final insuranceCompliance = await _checkInsuranceCompliance(companyId);
      complianceResults['insurance_compliance'] = insuranceCompliance;
      
      // Check quality management system
      final qmsCompliance = await _checkQualityManagementSystem(companyId);
      complianceResults['qms_compliance'] = qmsCompliance;
      
      // Check incident reporting procedures
      final incidentProcedures = await _checkIncidentProcedures(companyId);
      complianceResults['incident_procedures'] = incidentProcedures;
      
      // Check data retention compliance (7 years)
      final retentionCompliance = await _checkDataRetentionCompliance(companyId);
      complianceResults['retention_compliance'] = retentionCompliance;
      
      // Calculate overall company compliance
      final overallScore = _calculateCompanyComplianceScore(complianceResults);
      complianceResults['overall_score'] = overallScore;
      
      // Determine compliance status
      complianceResults['compliance_status'] = _determineCompanyComplianceStatus(overallScore);
      
      // Generate company recommendations
      complianceResults['recommendations'] = _generateCompanyRecommendations(complianceResults);
      
      // Required company actions
      complianceResults['required_actions'] = _getRequiredCompanyActions(complianceResults);
      
      // Store compliance assessment
      await _storeCompanyComplianceAssessment(companyId, complianceResults);
      
      return complianceResults;
      
    } catch (e) {
      throw Exception('Company WPBR compliance validation failed: $e');
    }
  }
  
  /// Monitor ongoing WPBR compliance
  Future<void> monitorOngoingCompliance() async {
    try {
      // Check expiring certificates (within 90 days)
      await _checkExpiringCertificates();
      
      // Check overdue training
      await _checkOverdueTraining();
      
      // Validate company licenses
      await _checkExpiringCompanyLicenses();
      
      // Check incident reporting compliance
      await _checkIncidentReportingCompliance();
      
      // Generate compliance alerts
      await _generateComplianceAlerts();
      
      // Update compliance dashboard
      await _updateComplianceDashboard();
      
    } catch (e) {
      throw Exception('Ongoing compliance monitoring failed: $e');
    }
  }
  
  /// Generate WPBR compliance report
  Future<Map<String, dynamic>> generateWPBRComplianceReport({
    required DateTime reportPeriod,
    String? companyId,
  }) async {
    
    try {
      final report = <String, dynamic>{};
      
      // Report metadata
      report['report_metadata'] = {
        'period': reportPeriod.toIso8601String(),
        'generated_at': DateTime.now().toIso8601String(),
        'report_type': 'wpbr_compliance',
        'company_id': companyId,
        'version': '1.0',
      };
      
      // Certificate compliance statistics
      report['certificate_compliance'] = await _getCertificateComplianceStats(reportPeriod, companyId);
      
      // Training compliance statistics
      report['training_compliance'] = await _getTrainingComplianceStats(reportPeriod, companyId);
      
      // Incident reporting compliance
      report['incident_compliance'] = await _getIncidentComplianceStats(reportPeriod, companyId);
      
      // Company license compliance
      if (companyId != null) {
        report['company_license'] = await _getCompanyLicenseStats(companyId);
      } else {
        report['all_companies_licenses'] = await _getAllCompaniesLicenseStats();
      }
      
      // Data retention compliance
      report['data_retention'] = await _getDataRetentionStats(reportPeriod, companyId);
      
      // Quality metrics
      report['quality_metrics'] = await _getQualityMetrics(reportPeriod, companyId);
      
      // Compliance violations and remediation
      report['violations'] = await _getViolationsStats(reportPeriod, companyId);
      
      // Recommendations and action items
      report['recommendations'] = await _getReportRecommendations(report);
      
      // Store report
      await _storeWPBRComplianceReport(report);
      
      return report;
      
    } catch (e) {
      throw Exception('WPBR compliance report generation failed: $e');
    }
  }
  
  // Private helper methods
  
  Future<List<Map<String, dynamic>>> _getGuardCertificates(String guardId) async {
    final certificates = await _firestore
        .collection('certificates')
        .where('guard_id', isEqualTo: guardId)
        .where('is_valid', isEqualTo: true)
        .get();
    
    return certificates.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }
  
  Map<String, dynamic> _checkBasicWPBRCompliance(List<Map<String, dynamic>> certificates) {
    final requiredCerts = Set<String>.from(requiredCertificates);
    final availableCerts = certificates.map((cert) => cert['type'] as String).toSet();
    
    final missingCerts = requiredCerts.difference(availableCerts);
    final hasAllRequired = missingCerts.isEmpty;
    
    return {
      'compliant': hasAllRequired,
      'required_certificates': requiredCertificates,
      'available_certificates': availableCerts.toList(),
      'missing_certificates': missingCerts.toList(),
      'compliance_percentage': hasAllRequired ? 100.0 : 
          ((requiredCerts.length - missingCerts.length) / requiredCerts.length) * 100,
    };
  }
  
  Map<String, dynamic> _checkEnhancedCompliance(
    List<Map<String, dynamic>> certificates,
    List<String> assignedSecurityLevels,
  ) {
    final enhancedResults = <String, dynamic>{};
    final availableCerts = certificates.map((cert) => cert['type'] as String).toSet();
    
    for (final level in assignedSecurityLevels) {
      if (enhancedRequirements.containsKey(level)) {
        final required = Set<String>.from(enhancedRequirements[level]!);
        final missing = required.difference(availableCerts);
        
        enhancedResults[level] = {
          'compliant': missing.isEmpty,
          'required': required.toList(),
          'missing': missing.toList(),
          'compliance_percentage': missing.isEmpty ? 100.0 :
              ((required.length - missing.length) / required.length) * 100,
        };
      }
    }
    
    final overallCompliant = enhancedResults.values
        .every((result) => result['compliant'] == true);
    
    return {
      'overall_compliant': overallCompliant,
      'by_security_level': enhancedResults,
    };
  }
  
  Map<String, dynamic> _checkCertificateValidity(List<Map<String, dynamic>> certificates) {
    final now = DateTime.now();
    final validCerts = <Map<String, dynamic>>[];
    final expiredCerts = <Map<String, dynamic>>[];
    final expiringSoon = <Map<String, dynamic>>[];
    
    for (final cert in certificates) {
      final expiryDate = (cert['expires_at'] as Timestamp?)?.toDate();
      
      if (expiryDate == null) {
        continue; // Skip certificates without expiry date
      }
      
      if (expiryDate.isBefore(now)) {
        expiredCerts.add(cert);
      } else if (expiryDate.isBefore(now.add(retrainingRequiredDays))) {
        expiringSoon.add(cert);
      } else {
        validCerts.add(cert);
      }
    }
    
    return {
      'valid_certificates': validCerts.length,
      'expired_certificates': expiredCerts.length,
      'expiring_soon': expiringSoon.length,
      'expired_details': expiredCerts,
      'expiring_details': expiringSoon,
      'overall_valid': expiredCerts.isEmpty,
    };
  }
  
  Future<Map<String, dynamic>> _checkTrainingRequirements(String guardId, List<Map<String, dynamic>> certificates) async {
    // Check required periodic training
    final trainingRecords = await _firestore
        .collection('training_records')
        .where('guard_id', isEqualTo: guardId)
        .orderBy('completed_at', descending: true)
        .get();
    
    final trainings = trainingRecords.docs.map((doc) => doc.data()).toList();
    
    // Check if periodic training is up to date
    final lastPeriodicTraining = trainings
        .where((training) => training['type'] == 'periodic_wpbr')
        .isNotEmpty ? trainings.first : null;
    
    final periodicUpToDate = lastPeriodicTraining != null &&
        (lastPeriodicTraining['completed_at'] as Timestamp)
            .toDate()
            .isAfter(DateTime.now().subtract(const Duration(days: 1095))); // 3 years
    
    return {
      'periodic_training_up_to_date': periodicUpToDate,
      'last_periodic_training': lastPeriodicTraining?['completed_at'],
      'training_records_count': trainings.length,
      'recent_trainings': trainings.take(5).toList(),
    };
  }
  
  Future<Map<String, dynamic>> _checkIdentityCompliance(String guardId) async {
    final userDoc = await _firestore.collection('users').doc(guardId).get();
    final userData = userDoc.data() ?? {};
    
    // Check BSN presence and encryption
    final hasBSN = userData.containsKey('encrypted_bsn') && 
                  userData['encrypted_bsn'] != null;
    
    // Check identity verification
    final identityVerified = userData['identity_verified'] == true;
    
    // Check background check status
    final backgroundCheckValid = userData['background_check_valid'] == true &&
        userData['background_check_date'] != null;
    
    return {
      'bsn_compliant': hasBSN,
      'identity_verified': identityVerified,
      'background_check_valid': backgroundCheckValid,
      'overall_compliant': hasBSN && identityVerified && backgroundCheckValid,
    };
  }
  
  Future<Map<String, dynamic>> _checkIncidentReporting(String guardId) async {
    // Check if guard has reported incidents properly
    final incidents = await _firestore
        .collection('incident_reports')
        .where('guard_id', isEqualTo: guardId)
        .where('created_at', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 365))))
        .get();
    
    int properlyReported = 0;
    int lateReported = 0;
    
    for (final doc in incidents.docs) {
      final data = doc.data();
      final incidentDate = (data['incident_date'] as Timestamp).toDate();
      final reportedDate = (data['created_at'] as Timestamp).toDate();
      
      final reportingDelay = reportedDate.difference(incidentDate);
      
      if (reportingDelay.inHours <= 24) {
        properlyReported++;
      } else {
        lateReported++;
      }
    }
    
    final totalIncidents = incidents.docs.length;
    final complianceRate = totalIncidents > 0 ? properlyReported / totalIncidents : 1.0;
    
    return {
      'total_incidents': totalIncidents,
      'properly_reported': properlyReported,
      'late_reported': lateReported,
      'compliance_rate': complianceRate,
      'compliant': complianceRate >= 0.95, // 95% threshold
    };
  }
  
  double _calculateComplianceScore(Map<String, dynamic> results) {
    double totalScore = 0.0;
    
    // Basic compliance (30%)
    if (results['basic_compliance']?['compliant'] == true) {
      totalScore += 30;
    }
    
    // Enhanced compliance (25%)
    if (results['enhanced_compliance']?['overall_compliant'] == true) {
      totalScore += 25;
    }
    
    // Certificate validity (20%)
    if (results['validity_check']?['overall_valid'] == true) {
      totalScore += 20;
    }
    
    // Training compliance (15%)
    if (results['training_compliance']?['periodic_training_up_to_date'] == true) {
      totalScore += 15;
    }
    
    // Identity compliance (10%)
    if (results['identity_compliance']?['overall_compliant'] == true) {
      totalScore += 10;
    }
    
    return totalScore;
  }
  
  String _determineComplianceStatus(double score) {
    if (score >= 90) return 'Volledig compliant';
    if (score >= 75) return 'Grotendeels compliant - kleine tekortkomingen';
    if (score >= 50) return 'Gedeeltelijk compliant - actie vereist';
    return 'Niet-compliant - onmiddellijke actie vereist';
  }
  
  List<String> _generateRecommendations(Map<String, dynamic> results) {
    final recommendations = <String>[];
    
    // Check basic compliance
    final basicCompliance = results['basic_compliance'] as Map<String, dynamic>?;
    if (basicCompliance?['compliant'] != true) {
      final missing = basicCompliance?['missing_certificates'] as List?;
      if (missing != null && missing.isNotEmpty) {
        recommendations.add('Behaal ontbrekende basiscertificaten: ${missing.join(', ')}');
      }
    }
    
    // Check certificate validity
    final validityCheck = results['validity_check'] as Map<String, dynamic>?;
    if (validityCheck?['expired_certificates'] != null && 
        (validityCheck!['expired_certificates'] as int) > 0) {
      recommendations.add('Vernieuw verlopen certificaten onmiddellijk');
    }
    
    if (validityCheck?['expiring_soon'] != null && 
        (validityCheck!['expiring_soon'] as int) > 0) {
      recommendations.add('Plan hertraining voor binnenkort verlopende certificaten');
    }
    
    // Check training compliance
    final trainingCompliance = results['training_compliance'] as Map<String, dynamic>?;
    if (trainingCompliance?['periodic_training_up_to_date'] != true) {
      recommendations.add('Volg verplichte periodieke WPBR-training');
    }
    
    // Check identity compliance
    final identityCompliance = results['identity_compliance'] as Map<String, dynamic>?;
    if (identityCompliance?['overall_compliant'] != true) {
      recommendations.add('Zorg voor complete identiteitsverificatie en VOG');
    }
    
    return recommendations;
  }
  
  List<String> _getRequiredActions(Map<String, dynamic> results) {
    final actions = <String>[];
    
    final validityCheck = results['validity_check'] as Map<String, dynamic>?;
    if (validityCheck?['expired_certificates'] != null && 
        (validityCheck!['expired_certificates'] as int) > 0) {
      actions.add('URGENT: Vernieuw verlopen certificaten binnen 30 dagen');
    }
    
    final basicCompliance = results['basic_compliance'] as Map<String, dynamic>?;
    if (basicCompliance?['compliant'] != true) {
      actions.add('Behaal ontbrekende WPBR-certificaten binnen 90 dagen');
    }
    
    final identityCompliance = results['identity_compliance'] as Map<String, dynamic>?;
    if (identityCompliance?['bsn_compliant'] != true) {
      actions.add('Verstrek en verifieer BSN-gegevens');
    }
    
    return actions;
  }
  
  Future<void> _logComplianceCheck(String guardId, String companyId, Map<String, dynamic> results) async {
    await _firestore.collection('wpbr_compliance_log').add({
      'guard_id': guardId,
      'company_id': companyId,
      'compliance_results': results,
      'checked_at': FieldValue.serverTimestamp(),
      'checker': 'automated_system',
      'version': '1.0.0',
    });
  }
  
  Future<Map<String, dynamic>> _getCompanyDetails(String companyId) async {
    final companyDoc = await _firestore.collection('companies').doc(companyId).get();
    return companyDoc.data() ?? {};
  }
  
  Future<Map<String, dynamic>> _checkCompanyLicense(String companyId) async {
    final companyData = await _getCompanyDetails(companyId);
    
    final hasLicense = companyData['wpbr_license'] != null;
    final licenseValid = companyData['license_valid'] == true;
    final licenseExpiry = companyData['license_expires_at'] as Timestamp?;
    
    bool licenseNotExpired = true;
    if (licenseExpiry != null) {
      licenseNotExpired = licenseExpiry.toDate().isAfter(DateTime.now());
    }
    
    return {
      'has_license': hasLicense,
      'license_valid': licenseValid,
      'license_not_expired': licenseNotExpired,
      'license_expires_at': licenseExpiry?.toDate(),
      'overall_compliant': hasLicense && licenseValid && licenseNotExpired,
    };
  }
  
  Future<Map<String, dynamic>> _checkAllGuardsCompliance(String companyId) async {
    // Get all guards employed by the company
    final guards = await _firestore
        .collection('users')
        .where('company_id', isEqualTo: companyId)
        .where('user_type', isEqualTo: 'guard')
        .get();
    
    int compliantGuards = 0;
    int totalGuards = guards.docs.length;
    final nonCompliantGuards = <String>[];
    
    for (final guardDoc in guards.docs) {
      final guardCompliance = await validateGuardCompliance(
        guardId: guardDoc.id,
        companyId: companyId,
        assignedSecurityLevels: List<String>.from(guardDoc.data()['security_levels'] ?? []),
      );
      
      if ((guardCompliance['overall_score'] as double) >= 75) {
        compliantGuards++;
      } else {
        nonCompliantGuards.add(guardDoc.id);
      }
    }
    
    final complianceRate = totalGuards > 0 ? compliantGuards / totalGuards : 1.0;
    
    return {
      'total_guards': totalGuards,
      'compliant_guards': compliantGuards,
      'non_compliant_guards': nonCompliantGuards,
      'compliance_rate': complianceRate,
      'overall_compliant': complianceRate >= 0.95, // 95% threshold
    };
  }
  
  Future<Map<String, dynamic>> _checkInsuranceCompliance(String companyId) async {
    final companyData = await _getCompanyDetails(companyId);
    
    final hasLiabilityInsurance = companyData['liability_insurance'] != null;
    final insuranceValid = companyData['insurance_valid'] == true;
    final insuranceExpiry = companyData['insurance_expires_at'] as Timestamp?;
    
    bool insuranceNotExpired = true;
    if (insuranceExpiry != null) {
      insuranceNotExpired = insuranceExpiry.toDate().isAfter(DateTime.now());
    }
    
    return {
      'has_liability_insurance': hasLiabilityInsurance,
      'insurance_valid': insuranceValid,
      'insurance_not_expired': insuranceNotExpired,
      'insurance_expires_at': insuranceExpiry?.toDate(),
      'overall_compliant': hasLiabilityInsurance && insuranceValid && insuranceNotExpired,
    };
  }
  
  Future<Map<String, dynamic>> _checkQualityManagementSystem(String companyId) async {
    final qmsDoc = await _firestore
        .collection('quality_management')
        .doc(companyId)
        .get();
    
    final qmsData = qmsDoc.data() ?? {};
    
    return {
      'has_qms': qmsDoc.exists,
      'iso_certified': qmsData['iso_certified'] == true,
      'procedures_documented': qmsData['procedures_documented'] == true,
      'regular_audits': qmsData['regular_audits'] == true,
      'overall_compliant': qmsDoc.exists && 
                          qmsData['procedures_documented'] == true,
    };
  }
  
  Future<Map<String, dynamic>> _checkIncidentProcedures(String companyId) async {
    final proceduresDoc = await _firestore
        .collection('incident_procedures')
        .doc(companyId)
        .get();
    
    final proceduresData = proceduresDoc.data() ?? {};
    
    return {
      'procedures_documented': proceduresDoc.exists,
      'staff_trained': proceduresData['staff_trained'] == true,
      'escalation_defined': proceduresData['escalation_defined'] == true,
      'authorities_contact': proceduresData['authorities_contact'] != null,
      'overall_compliant': proceduresDoc.exists && 
                          proceduresData['staff_trained'] == true,
    };
  }
  
  Future<Map<String, dynamic>> _checkDataRetentionCompliance(String companyId) async {
    // Check if company follows 7-year data retention requirement
    final retentionDoc = await _firestore
        .collection('data_retention_policies')
        .doc(companyId)
        .get();
    
    final retentionData = retentionDoc.data() ?? {};
    
    return {
      'policy_documented': retentionDoc.exists,
      'seven_year_retention': retentionData['wpbr_retention_years'] == 7,
      'automated_deletion': retentionData['automated_deletion'] == true,
      'audit_trail': retentionData['audit_trail_maintained'] == true,
      'overall_compliant': retentionDoc.exists && 
                          retentionData['wpbr_retention_years'] == 7,
    };
  }
  
  double _calculateCompanyComplianceScore(Map<String, dynamic> results) {
    double totalScore = 0.0;
    
    // License compliance (25%)
    if (results['license_compliance']?['overall_compliant'] == true) {
      totalScore += 25;
    }
    
    // Guards compliance (30%)
    final guardsCompliance = results['guards_compliance']?['compliance_rate'] as double? ?? 0.0;
    totalScore += guardsCompliance * 30;
    
    // Insurance compliance (15%)
    if (results['insurance_compliance']?['overall_compliant'] == true) {
      totalScore += 15;
    }
    
    // QMS compliance (15%)
    if (results['qms_compliance']?['overall_compliant'] == true) {
      totalScore += 15;
    }
    
    // Incident procedures (10%)
    if (results['incident_procedures']?['overall_compliant'] == true) {
      totalScore += 10;
    }
    
    // Data retention (5%)
    if (results['retention_compliance']?['overall_compliant'] == true) {
      totalScore += 5;
    }
    
    return totalScore;
  }
  
  String _determineCompanyComplianceStatus(double score) {
    if (score >= 90) return 'Volledig WPBR-compliant bedrijf';
    if (score >= 75) return 'Grotendeels compliant - kleine verbeteringen nodig';
    if (score >= 50) return 'Gedeeltelijk compliant - significante actie vereist';
    return 'Niet-compliant - onmiddellijke maatregelen vereist';
  }
  
  List<String> _generateCompanyRecommendations(Map<String, dynamic> results) {
    final recommendations = <String>[];
    
    final licenseCompliance = results['license_compliance'] as Map<String, dynamic>?;
    if (licenseCompliance?['overall_compliant'] != true) {
      recommendations.add('Zorg voor geldige WPBR-vergunning');
    }
    
    final guardsCompliance = results['guards_compliance'] as Map<String, dynamic>?;
    if ((guardsCompliance?['compliance_rate'] as double? ?? 0.0) < 0.95) {
      recommendations.add('Verbeter compliance van alle beveiligers tot minimaal 95%');
    }
    
    final insuranceCompliance = results['insurance_compliance'] as Map<String, dynamic>?;
    if (insuranceCompliance?['overall_compliant'] != true) {
      recommendations.add('Zorg voor geldige aansprakelijkheidsverzekering');
    }
    
    return recommendations;
  }
  
  List<String> _getRequiredCompanyActions(Map<String, dynamic> results) {
    final actions = <String>[];
    
    final licenseCompliance = results['license_compliance'] as Map<String, dynamic>?;
    if (licenseCompliance?['has_license'] != true) {
      actions.add('URGENT: Aanvraag WPBR-vergunning binnen 30 dagen');
    }
    
    final guardsCompliance = results['guards_compliance'] as Map<String, dynamic>?;
    final nonCompliantGuards = guardsCompliance?['non_compliant_guards'] as List?;
    if (nonCompliantGuards != null && nonCompliantGuards.isNotEmpty) {
      actions.add('Breng ${nonCompliantGuards.length} beveiligers in compliance binnen 60 dagen');
    }
    
    return actions;
  }
  
  Future<void> _storeCompanyComplianceAssessment(String companyId, Map<String, dynamic> results) async {
    await _firestore.collection('company_wpbr_compliance').add({
      'company_id': companyId,
      'assessment_results': results,
      'assessed_at': FieldValue.serverTimestamp(),
      'assessor': 'automated_system',
      'version': '1.0.0',
    });
  }
  
  // Ongoing monitoring methods
  
  Future<void> _checkExpiringCertificates() async {
    final expiryThreshold = DateTime.now().add(retrainingRequiredDays);
    
    final expiringCerts = await _firestore
        .collection('certificates')
        .where('expires_at', isLessThan: Timestamp.fromDate(expiryThreshold))
        .where('is_valid', isEqualTo: true)
        .get();
    
    for (final cert in expiringCerts.docs) {
      await _createComplianceAlert(
        'certificate_expiring',
        cert.data()['guard_id'],
        'Certificaat ${cert.data()['type']} verloopt binnenkort',
        {'certificate_id': cert.id, 'expires_at': cert.data()['expires_at']},
      );
    }
  }
  
  Future<void> _checkOverdueTraining() async {
    final threeYearsAgo = DateTime.now().subtract(const Duration(days: 1095));
    
    // Find guards without recent periodic training
    final guards = await _firestore
        .collection('users')
        .where('user_type', isEqualTo: 'guard')
        .get();
    
    for (final guard in guards.docs) {
      final lastTraining = await _firestore
          .collection('training_records')
          .where('guard_id', isEqualTo: guard.id)
          .where('type', isEqualTo: 'periodic_wpbr')
          .orderBy('completed_at', descending: true)
          .limit(1)
          .get();
      
      bool trainingOverdue = false;
      
      if (lastTraining.docs.isEmpty) {
        trainingOverdue = true;
      } else {
        final lastTrainingDate = (lastTraining.docs.first.data()['completed_at'] as Timestamp).toDate();
        trainingOverdue = lastTrainingDate.isBefore(threeYearsAgo);
      }
      
      if (trainingOverdue) {
        await _createComplianceAlert(
          'training_overdue',
          guard.id,
          'Periodieke WPBR-training is achterstallig',
          {'guard_id': guard.id},
        );
      }
    }
  }
  
  Future<void> _checkExpiringCompanyLicenses() async {
    final ninetyDaysFromNow = DateTime.now().add(const Duration(days: 90));
    
    final companies = await _firestore
        .collection('companies')
        .where('license_expires_at', isLessThan: Timestamp.fromDate(ninetyDaysFromNow))
        .get();
    
    for (final company in companies.docs) {
      await _createComplianceAlert(
        'company_license_expiring',
        company.id,
        'WPBR-vergunning verloopt binnenkort',
        {'company_id': company.id, 'expires_at': company.data()['license_expires_at']},
      );
    }
  }
  
  Future<void> _checkIncidentReportingCompliance() async {
    // Check for incidents reported late or not at all
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    // This would typically cross-reference with actual incident data from security systems
    // For now, we'll check reported incidents only
    final lateReports = await _firestore
        .collection('incident_reports')
        .where('created_at', isGreaterThan: Timestamp.fromDate(yesterday))
        .get();
    
    for (final report in lateReports.docs) {
      final data = report.data();
      final incidentDate = (data['incident_date'] as Timestamp).toDate();
      final reportedDate = (data['created_at'] as Timestamp).toDate();
      
      if (reportedDate.difference(incidentDate).inHours > 24) {
        await _createComplianceAlert(
          'late_incident_report',
          data['guard_id'],
          'Incident te laat gemeld (>24 uur)',
          {'report_id': report.id, 'delay_hours': reportedDate.difference(incidentDate).inHours},
        );
      }
    }
  }
  
  Future<void> _generateComplianceAlerts() async {
    // This method would generate summary alerts for management
    final today = DateTime.now();
    const alertTypes = ['certificate_expiring', 'training_overdue', 'company_license_expiring'];
    
    for (final alertType in alertTypes) {
      final alerts = await _firestore
          .collection('compliance_alerts')
          .where('type', isEqualTo: alertType)
          .where('created_at', isGreaterThan: Timestamp.fromDate(today.subtract(const Duration(hours: 24))))
          .get();
      
      if (alerts.docs.isNotEmpty) {
        await _firestore.collection('daily_compliance_summary').add({
          'date': Timestamp.fromDate(today),
          'alert_type': alertType,
          'count': alerts.docs.length,
          'alerts': alerts.docs.map((doc) => doc.id).toList(),
        });
      }
    }
  }
  
  Future<void> _updateComplianceDashboard() async {
    // Update real-time compliance dashboard metrics
    final metrics = await _calculateDashboardMetrics();
    
    await _firestore.collection('compliance_dashboard').doc('current').set({
      'last_updated': FieldValue.serverTimestamp(),
      'metrics': metrics,
    });
  }
  
  Future<Map<String, dynamic>> _calculateDashboardMetrics() async {
    // Calculate key metrics for dashboard
    final totalGuards = await _firestore
        .collection('users')
        .where('user_type', isEqualTo: 'guard')
        .get();
    
    final totalCompanies = await _firestore
        .collection('companies')
        .get();
    
    return {
      'total_guards': totalGuards.docs.length,
      'total_companies': totalCompanies.docs.length,
      'compliance_rate': 0.95, // Would be calculated from actual compliance data
      'alerts_count': 0, // Would be calculated from active alerts
    };
  }
  
  Future<void> _createComplianceAlert(String type, String entityId, String message, Map<String, dynamic> details) async {
    await _firestore.collection('compliance_alerts').add({
      'type': type,
      'entity_id': entityId,
      'message': message,
      'details': details,
      'status': 'active',
      'created_at': FieldValue.serverTimestamp(),
      'resolved_at': null,
    });
  }
  
  // Report generation helper methods
  
  Future<Map<String, dynamic>> _getCertificateComplianceStats(DateTime period, String? companyId) async {
    // Implementation would gather certificate compliance statistics
    return {
      'total_certificates': 0,
      'valid_certificates': 0,
      'expired_certificates': 0,
      'expiring_soon': 0,
      'compliance_rate': 0.0,
    };
  }
  
  Future<Map<String, dynamic>> _getTrainingComplianceStats(DateTime period, String? companyId) async {
    return {
      'guards_with_current_training': 0,
      'overdue_training': 0,
      'training_completion_rate': 0.0,
    };
  }
  
  Future<Map<String, dynamic>> _getIncidentComplianceStats(DateTime period, String? companyId) async {
    return {
      'total_incidents': 0,
      'properly_reported': 0,
      'late_reported': 0,
      'compliance_rate': 0.0,
    };
  }
  
  Future<Map<String, dynamic>> _getCompanyLicenseStats(String companyId) async {
    final licenseCompliance = await _checkCompanyLicense(companyId);
    return licenseCompliance;
  }
  
  Future<Map<String, dynamic>> _getAllCompaniesLicenseStats() async {
    return {
      'total_companies': 0,
      'licensed_companies': 0,
      'expired_licenses': 0,
      'expiring_licenses': 0,
    };
  }
  
  Future<Map<String, dynamic>> _getDataRetentionStats(DateTime period, String? companyId) async {
    return {
      'retention_policies_documented': 0,
      'automated_retention': 0,
      'compliance_rate': 0.0,
    };
  }
  
  Future<Map<String, dynamic>> _getQualityMetrics(DateTime period, String? companyId) async {
    return {
      'iso_certified_companies': 0,
      'documented_procedures': 0,
      'regular_audits': 0,
      'quality_score': 0.0,
    };
  }
  
  Future<Map<String, dynamic>> _getViolationsStats(DateTime period, String? companyId) async {
    return {
      'total_violations': 0,
      'resolved_violations': 0,
      'pending_violations': 0,
      'resolution_rate': 0.0,
    };
  }
  
  Future<List<String>> _getReportRecommendations(Map<String, dynamic> report) async {
    return [
      'Implementeer geautomatiseerde compliance monitoring',
      'Verhoog training completion rate naar 100%',
      'Zorg voor tijdige vergunningsvernieuwing',
      'Verbeter incident reporting procedures',
    ];
  }
  
  Future<void> _storeWPBRComplianceReport(Map<String, dynamic> report) async {
    await _firestore.collection('wpbr_compliance_reports').add({
      ...report,
      'created_at': FieldValue.serverTimestamp(),
      'report_version': '1.0',
    });
  }
}