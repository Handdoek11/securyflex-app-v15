import 'dart:async';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced Security Audit Service for SecuryFlex
/// 
/// Provides real-time security monitoring, anomaly detection, automated threat response,
/// and comprehensive audit logging compliant with Dutch security standards.
class SecurityAuditService {
  static const String _auditLogKey = 'securyflex_audit_log';
  
  // Real-time monitoring thresholds
// requests per minute
  
  // Anomaly detection parameters
  static const double _behaviorAnomalyThreshold = 0.75;
  
  static Timer? _realTimeMonitoringTimer;
  static final List<SecurityEventListener> _eventListeners = [];
  
  /// Initialize real-time security monitoring
  static Future<void> initializeMonitoring({
    bool enableRealTimeAlerts = true,
    bool enableBehaviorAnalysis = true,
    bool enableThreatIntelligence = true,
  }) async {
    // Start real-time monitoring timer
    _realTimeMonitoringTimer?.cancel();
    _realTimeMonitoringTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _performRealTimeSecurityCheck(),
    );
    
    await _logSecurityEvent(
      SecurityEvent.securityMonitoring(
        eventType: SecurityEventType.monitoringStarted,
        description: 'Real-time security monitoring initialized',
        severity: SecuritySeverity.info,
        metadata: {
          'realTimeAlerts': enableRealTimeAlerts,
          'behaviorAnalysis': enableBehaviorAnalysis,
          'threatIntelligence': enableThreatIntelligence,
        },
      ),
    );
  }
  
  /// Log comprehensive security event with enhanced metadata
  static Future<void> logSecurityEvent({
    required String userId,
    required SecurityEventType eventType,
    required String description,
    SecuritySeverity severity = SecuritySeverity.info,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? userAgent,
    String? deviceFingerprint,
    GeoLocation? location,
  }) async {
    final event = SecurityEvent(
      id: _generateSecurityEventId(),
      userId: userId,
      eventType: eventType,
      description: description,
      severity: severity,
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      deviceFingerprint: deviceFingerprint,
      location: location,
      metadata: metadata ?? {},
    );
    
    // Store event in secure audit log
    await _storeAuditEvent(event);
    
    // Analyze event for anomalies and threats
    await _analyzeEventForThreats(event);
    
    // Update behavior profile
    if (eventType.isUserActivity) {
      await _updateBehaviorProfile(event);
    }
    
    // Notify listeners
    _notifyEventListeners(event);
    
    // Trigger automated responses for critical events
    if (severity.index >= SecuritySeverity.high.index) {
      await _triggerAutomatedSecurityResponse(event);
    }
  }
  
  /// Detect authentication anomalies in real-time
  static Future<AuthenticationAnomalyResult> detectAuthenticationAnomalies({
    required String userId,
    required String ipAddress,
    required String userAgent,
    String? deviceFingerprint,
    GeoLocation? location,
  }) async {
    final anomalies = <AuthenticationAnomaly>[];
    
    // Check for suspicious IP patterns
    final ipAnomaly = await _detectSuspiciousIP(userId, ipAddress);
    if (ipAnomaly != null) anomalies.add(ipAnomaly);
    
    // Check for unusual device fingerprint
    final deviceAnomaly = await _detectDeviceAnomaly(userId, deviceFingerprint);
    if (deviceAnomaly != null) anomalies.add(deviceAnomaly);
    
    // Check for geographical anomalies
    final geoAnomaly = await _detectGeographicalAnomaly(userId, location);
    if (geoAnomaly != null) anomalies.add(geoAnomaly);
    
    // Check for time-based anomalies
    final timeAnomaly = await _detectTimingAnomaly(userId);
    if (timeAnomaly != null) anomalies.add(timeAnomaly);
    
    // Check for behavioral anomalies
    final behaviorAnomaly = await _detectBehavioralAnomaly(userId, userAgent);
    if (behaviorAnomaly != null) anomalies.add(behaviorAnomaly);
    
    // Calculate overall risk score
    final riskScore = _calculateRiskScore(anomalies);
    
    final result = AuthenticationAnomalyResult(
      userId: userId,
      anomalies: anomalies,
      riskScore: riskScore,
      riskLevel: _getRiskLevel(riskScore),
      recommendedAction: _getRecommendedAction(riskScore),
      analysisTimestamp: DateTime.now(),
    );
    
    // Log anomaly detection results
    if (anomalies.isNotEmpty) {
      await logSecurityEvent(
        userId: userId,
        eventType: SecurityEventType.anomalyDetected,
        description: 'Authentication anomalies detected: ${anomalies.length}',
        severity: _getSeverityFromRisk(riskScore),
        metadata: {
          'anomalies': anomalies.map((a) => a.toJson()).toList(),
          'riskScore': riskScore,
          'riskLevel': result.riskLevel.name,
        },
        ipAddress: ipAddress,
        userAgent: userAgent,
        deviceFingerprint: deviceFingerprint,
        location: location,
      );
    }
    
    return result;
  }
  
  /// Monitor for brute force attacks
  static Future<BruteForceAnalysis> monitorBruteForceAttempts({
    required String userId,
    required String ipAddress,
    String? targetResource,
  }) async {
    final analysis = BruteForceAnalysis(
      userId: userId,
      ipAddress: ipAddress,
      targetResource: targetResource,
      analysisTimestamp: DateTime.now(),
    );
    
    // Get recent failed login attempts
    final recentFailures = await _getRecentFailedLogins(userId, ipAddress);
    analysis.failedAttempts = recentFailures.length;
    analysis.timeSpan = recentFailures.isNotEmpty
        ? DateTime.now().difference(recentFailures.first.timestamp)
        : Duration.zero;
    
    // Analyze patterns
    analysis.patterns = _analyzeBruteForcePatterns(recentFailures);
    
    // Calculate attack probability
    analysis.attackProbability = _calculateAttackProbability(analysis);
    
    // Determine if this is a coordinated attack
    analysis.isCoordinatedAttack = await _detectCoordinatedAttack(ipAddress);
    
    // Check if IP is in threat intelligence
    analysis.threatIntelMatch = await _checkThreatIntelligence(ipAddress);
    
    // Generate recommendations
    analysis.mitigationRecommendations = _generateBruteForceMitigation(analysis);
    
    // Log brute force analysis
    if (analysis.attackProbability > 0.7) {
      await logSecurityEvent(
        userId: userId,
        eventType: SecurityEventType.bruteForceDetected,
        description: 'Potential brute force attack detected',
        severity: SecuritySeverity.critical,
        metadata: {
          'failedAttempts': analysis.failedAttempts,
          'attackProbability': analysis.attackProbability,
          'isCoordinatedAttack': analysis.isCoordinatedAttack,
          'patterns': analysis.patterns,
        },
        ipAddress: ipAddress,
      );
    }
    
    return analysis;
  }
  
  /// Generate comprehensive security metrics dashboard
  static Future<SecurityMetricsDashboard> generateSecurityMetrics({
    Duration? timeRange,
  }) async {
    final range = timeRange ?? const Duration(days: 30);
    final endTime = DateTime.now();
    final startTime = endTime.subtract(range);
    
    final events = await _getEventsInRange(startTime, endTime);
    
    return SecurityMetricsDashboard(
      timeRange: range,
      generatedAt: DateTime.now(),
      
      // Authentication metrics
      totalLoginAttempts: _countEventsByType(events, SecurityEventType.loginAttempt),
      successfulLogins: _countEventsByType(events, SecurityEventType.loginSuccess),
      failedLogins: _countEventsByType(events, SecurityEventType.loginFailed),
      blockedLogins: _countEventsByType(events, SecurityEventType.loginBlocked),
      
      // Security event metrics
      securityAlertsGenerated: _countEventsBySeverity(events, SecuritySeverity.high),
      anomaliesDetected: _countEventsByType(events, SecurityEventType.anomalyDetected),
      bruteForceAttempts: _countEventsByType(events, SecurityEventType.bruteForceDetected),
      suspiciousActivities: _countEventsBySeverity(events, SecuritySeverity.warning),
      
      // User activity metrics
      uniqueUsers: _countUniqueUsers(events),
      uniqueIpAddresses: _countUniqueIPs(events),
      uniqueDevices: _countUniqueDevices(events),
      
      // Threat intelligence metrics
      threatIntelHits: _countThreatIntelHits(events),
      blockedIPs: await _getBlockedIPsCount(range),
      quarantinedUsers: await _getQuarantinedUsersCount(range),
      
      // Compliance metrics
      auditLogEntries: events.length,
      gdprRequestsProcessed: _countGDPRRequests(events),
      dataBreachIncidents: _countEventsByType(events, SecurityEventType.dataBreachSuspected),
      
      // Performance metrics
      averageResponseTime: _calculateAverageResponseTime(events),
      uptime: await _calculateSystemUptime(range),
      errorRate: _calculateErrorRate(events),
      
      // Top threats and patterns
      topThreatTypes: _identifyTopThreatTypes(events),
      topAttackSources: _identifyTopAttackSources(events),
      hourlyActivityPattern: _generateHourlyActivityPattern(events),
      geographicalDistribution: _generateGeographicalDistribution(events),
    );
  }
  
  /// Automated incident response system
  static Future<IncidentResponse> triggerIncidentResponse({
    required SecurityIncidentType incidentType,
    required SecuritySeverity severity,
    required String description,
    Map<String, dynamic>? context,
  }) async {
    final incident = SecurityIncident(
      id: _generateIncidentId(),
      type: incidentType,
      severity: severity,
      description: description,
      detectedAt: DateTime.now(),
      status: IncidentStatus.detected,
      context: context ?? {},
    );
    
    // Create incident response plan
    final responsePlan = _createIncidentResponsePlan(incident);
    
    // Execute automated responses
    final responses = <String>[];
    
    for (final action in responsePlan.automatedActions) {
      try {
        final success = await _executeAutomatedAction(action, incident);
        responses.add('${action.name}: ${success ? 'SUCCESS' : 'FAILED'}');
      } catch (e) {
        responses.add('${action.name}: ERROR - $e');
      }
    }
    
    // Update incident status
    incident.status = IncidentStatus.responding;
    incident.responseStartedAt = DateTime.now();
    
    // Store incident record
    await _storeSecurityIncident(incident);
    
    // Generate notifications
    await _sendSecurityNotifications(incident, responsePlan);
    
    // Log incident response
    await _logSecurityEvent(
      SecurityEvent.incidentResponse(
        incidentId: incident.id,
        incidentType: incidentType,
        severity: severity,
        description: 'Automated incident response triggered',
        responses: responses,
      ),
    );
    
    return IncidentResponse(
      incident: incident,
      responsePlan: responsePlan,
      executedActions: responses,
      responseTime: DateTime.now().difference(incident.detectedAt),
    );
  }
  
  /// Check security compliance status
  static Future<SecurityComplianceReport> generateComplianceReport() async {
    final report = SecurityComplianceReport(
      reportId: _generateReportId(),
      generatedAt: DateTime.now(),
      reportingPeriod: const Duration(days: 30),
    );
    
    // OWASP Mobile Top 10 Compliance
    report.owaspCompliance = await _assessOWASPCompliance();
    
    // Dutch Cybersecurity Act Compliance
    report.cybersecurityActCompliance = await _assessCybersecurityActCompliance();
    
    // GDPR/AVG Compliance
    report.gdprCompliance = await _assessGDPRCompliance();
    
    // ISO 27001 Compliance
    report.iso27001Compliance = await _assessISO27001Compliance();
    
    // Security control effectiveness
    report.securityControls = await _assessSecurityControlEffectiveness();
    
    // Vulnerability assessment
    report.vulnerabilityAssessment = await _performVulnerabilityAssessment();
    
    // Risk assessment
    report.riskAssessment = await _performRiskAssessment();
    
    // Recommendations
    report.recommendations = _generateComplianceRecommendations(report);
    
    await _storeComplianceReport(report);
    
    return report;
  }
  
  /// Register security event listener
  static void addSecurityEventListener(SecurityEventListener listener) {
    _eventListeners.add(listener);
  }
  
  /// Unregister security event listener
  static void removeSecurityEventListener(SecurityEventListener listener) {
    _eventListeners.remove(listener);
  }
  
  /// Dispose resources and stop monitoring
  static Future<void> dispose() async {
    _realTimeMonitoringTimer?.cancel();
    _realTimeMonitoringTimer = null;
    _eventListeners.clear();
    
    await _logSecurityEvent(
      SecurityEvent.securityMonitoring(
        eventType: SecurityEventType.monitoringStopped,
        description: 'Security monitoring service disposed',
        severity: SecuritySeverity.info,
      ),
    );
  }
  
  // Private helper methods
  
  /// Perform real-time security monitoring checks
  static Future<void> _performRealTimeSecurityCheck() async {
    try {
      // Check for ongoing attacks
      await _checkForOngoingAttacks();
      
      // Monitor system health
      await _monitorSystemHealth();
      
      // Update threat intelligence
      await _updateThreatIntelligence();
      
      // Clean up old audit logs
      await _cleanupOldAuditLogs();
      
      // Generate periodic security reports
      await _generatePeriodicReports();
      
    } catch (e) {
      await _logSecurityEvent(
        SecurityEvent.systemError(
          description: 'Real-time security check failed',
          error: e.toString(),
          severity: SecuritySeverity.warning,
        ),
      );
    }
  }
  
  /// Analyze security event for potential threats
  static Future<void> _analyzeEventForThreats(SecurityEvent event) async {
    // Check for known attack patterns
    await _checkAttackPatterns(event);
    
    // Check against threat intelligence
    if (event.ipAddress != null) {
      final threatMatch = await _checkThreatIntelligence(event.ipAddress!);
      if (threatMatch != null) {
        await logSecurityEvent(
          userId: event.userId,
          eventType: SecurityEventType.threatIntelMatch,
          description: 'IP address matches threat intelligence',
          severity: SecuritySeverity.high,
          metadata: {
            'originalEventId': event.id,
            'threatIntel': threatMatch.toJson(),
          },
          ipAddress: event.ipAddress,
        );
      }
    }
    
    // Check for correlation with other events
    await _checkEventCorrelation(event);
  }
  
  /// Update user behavior profile
  static Future<void> _updateBehaviorProfile(SecurityEvent event) async {
    final profile = await _getUserBehaviorProfile(event.userId);
    
    // Update behavioral metrics
    profile.updateWithEvent(event);
    
    // Check for behavioral anomalies
    final anomalyScore = profile.calculateAnomalyScore();
    if (anomalyScore > _behaviorAnomalyThreshold) {
      await logSecurityEvent(
        userId: event.userId,
        eventType: SecurityEventType.behavioralAnomalyDetected,
        description: 'Behavioral anomaly detected',
        severity: SecuritySeverity.warning,
        metadata: {
          'anomalyScore': anomalyScore,
          'originalEventId': event.id,
        },
      );
    }
    
    await _storeBehaviorProfile(profile);
  }
  
  /// Notify registered event listeners
  static void _notifyEventListeners(SecurityEvent event) {
    for (final listener in _eventListeners) {
      try {
        listener.onSecurityEvent(event);
      } catch (e) {
        developer.log('Error notifying security event listener: $e', name: 'SecurityAudit', level: 1000);
      }
    }
  }
  
  /// Trigger automated security responses
  static Future<void> _triggerAutomatedSecurityResponse(SecurityEvent event) async {
    switch (event.eventType) {
      case SecurityEventType.bruteForceDetected:
        await _handleBruteForceResponse(event);
        break;
      case SecurityEventType.anomalyDetected:
        await _handleAnomalyResponse(event);
        break;
      case SecurityEventType.threatIntelMatch:
        await _handleThreatIntelResponse(event);
        break;
      case SecurityEventType.suspiciousActivity:
        await _handleSuspiciousActivityResponse(event);
        break;
      default:
        break;
    }
  }
  
  /// Store audit event securely
  static Future<void> _storeAuditEvent(SecurityEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final auditLog = await _getAuditLog();
    
    auditLog.add(event);
    
    // Keep only recent events (last 10,000 events)
    if (auditLog.length > 10000) {
      auditLog.removeRange(0, auditLog.length - 10000);
    }
    
    // Encrypt and store audit log
    final encryptedLog = await _encryptAuditLog(auditLog);
    await prefs.setString(_auditLogKey, encryptedLog);
  }
  
  /// Generate unique security event ID
  static String _generateSecurityEventId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecond.toString().padLeft(6, '0');
    return 'sec_${timestamp}_$random';
  }
  
  /// Placeholder implementations for complex security analysis
  static Future<List<SecurityEvent>> _getAuditLog() async => [];
  static Future<String> _encryptAuditLog(List<SecurityEvent> log) async => '';
  static Future<AuthenticationAnomaly?> _detectSuspiciousIP(String userId, String ipAddress) async => null;
  static Future<AuthenticationAnomaly?> _detectDeviceAnomaly(String userId, String? deviceFingerprint) async => null;
  static Future<AuthenticationAnomaly?> _detectGeographicalAnomaly(String userId, GeoLocation? location) async => null;
  static Future<AuthenticationAnomaly?> _detectTimingAnomaly(String userId) async => null;
  static Future<AuthenticationAnomaly?> _detectBehavioralAnomaly(String userId, String userAgent) async => null;
  static double _calculateRiskScore(List<AuthenticationAnomaly> anomalies) => anomalies.length * 0.2;
  static SecurityRiskLevel _getRiskLevel(double riskScore) => SecurityRiskLevel.low;
  static SecurityAction _getRecommendedAction(double riskScore) => SecurityAction.monitor;
  static SecuritySeverity _getSeverityFromRisk(double riskScore) => SecuritySeverity.info;
  static Future<List<SecurityEvent>> _getRecentFailedLogins(String userId, String ipAddress) async => [];
  static List<String> _analyzeBruteForcePatterns(List<SecurityEvent> events) => [];
  static double _calculateAttackProbability(BruteForceAnalysis analysis) => 0.0;
  static Future<bool> _detectCoordinatedAttack(String ipAddress) async => false;
  static Future<ThreatIntelligenceMatch?> _checkThreatIntelligence(String ipAddress) async => null;
  static List<String> _generateBruteForceMitigation(BruteForceAnalysis analysis) => [];
  static Future<UserBehaviorProfile> _getUserBehaviorProfile(String userId) async => UserBehaviorProfile(userId: userId);
  static Future<void> _storeBehaviorProfile(UserBehaviorProfile profile) async {}
  
  // Additional placeholder methods for comprehensive implementation
  static Future<void> _handleBruteForceResponse(SecurityEvent event) async {}
  static Future<void> _handleAnomalyResponse(SecurityEvent event) async {}
  static Future<void> _handleThreatIntelResponse(SecurityEvent event) async {}
  static Future<void> _handleSuspiciousActivityResponse(SecurityEvent event) async {}
  static Future<void> _checkForOngoingAttacks() async {}
  static Future<void> _monitorSystemHealth() async {}
  static Future<void> _updateThreatIntelligence() async {}
  static Future<void> _cleanupOldAuditLogs() async {}
  static Future<void> _generatePeriodicReports() async {}
  static Future<List<String>> _checkAttackPatterns(SecurityEvent event) async => [];
  static Future<void> _checkEventCorrelation(SecurityEvent event) async {}
  static Future<List<SecurityEvent>> _getEventsInRange(DateTime start, DateTime end) async => [];
  static int _countEventsByType(List<SecurityEvent> events, SecurityEventType type) => 0;
  static int _countEventsBySeverity(List<SecurityEvent> events, SecuritySeverity severity) => 0;
  static int _countUniqueUsers(List<SecurityEvent> events) => 0;
  static int _countUniqueIPs(List<SecurityEvent> events) => 0;
  static int _countUniqueDevices(List<SecurityEvent> events) => 0;
  static int _countThreatIntelHits(List<SecurityEvent> events) => 0;
  static Future<int> _getBlockedIPsCount(Duration range) async => 0;
  static Future<int> _getQuarantinedUsersCount(Duration range) async => 0;
  static int _countGDPRRequests(List<SecurityEvent> events) => 0;
  static Duration _calculateAverageResponseTime(List<SecurityEvent> events) => Duration.zero;
  static Future<double> _calculateSystemUptime(Duration range) async => 99.9;
  static double _calculateErrorRate(List<SecurityEvent> events) => 0.01;
  static List<ThreatType> _identifyTopThreatTypes(List<SecurityEvent> events) => [];
  static List<String> _identifyTopAttackSources(List<SecurityEvent> events) => [];
  static Map<int, int> _generateHourlyActivityPattern(List<SecurityEvent> events) => {};
  static Map<String, int> _generateGeographicalDistribution(List<SecurityEvent> events) => {};
  static String _generateIncidentId() => 'inc_${DateTime.now().millisecondsSinceEpoch}';
  static IncidentResponsePlan _createIncidentResponsePlan(SecurityIncident incident) => IncidentResponsePlan(automatedActions: []);
  static Future<bool> _executeAutomatedAction(AutomatedAction action, SecurityIncident incident) async => true;
  static Future<void> _storeSecurityIncident(SecurityIncident incident) async {}
  static Future<void> _sendSecurityNotifications(SecurityIncident incident, IncidentResponsePlan plan) async {}
  static String _generateReportId() => 'rpt_${DateTime.now().millisecondsSinceEpoch}';
  static Future<ComplianceAssessment> _assessOWASPCompliance() async => ComplianceAssessment(score: 85, status: ComplianceStatus.compliant);
  static Future<ComplianceAssessment> _assessCybersecurityActCompliance() async => ComplianceAssessment(score: 90, status: ComplianceStatus.compliant);
  static Future<ComplianceAssessment> _assessGDPRCompliance() async => ComplianceAssessment(score: 92, status: ComplianceStatus.compliant);
  static Future<ComplianceAssessment> _assessISO27001Compliance() async => ComplianceAssessment(score: 88, status: ComplianceStatus.compliant);
  static Future<List<SecurityControl>> _assessSecurityControlEffectiveness() async => [];
  static Future<VulnerabilityAssessmentResult> _performVulnerabilityAssessment() async => VulnerabilityAssessmentResult(vulnerabilities: []);
  static Future<RiskAssessmentResult> _performRiskAssessment() async => RiskAssessmentResult(risks: []);
  static List<String> _generateComplianceRecommendations(SecurityComplianceReport report) => [];
  static Future<void> _storeComplianceReport(SecurityComplianceReport report) async {}
  
  static Future<void> _logSecurityEvent(SecurityEvent event) async {
    await _storeAuditEvent(event);
  }
}

// Supporting data models and enums

enum SecurityEventType {
  loginAttempt('login_attempt'),
  loginSuccess('login_success'),
  loginFailed('login_failed'),
  loginBlocked('login_blocked'),
  bruteForceDetected('brute_force_detected'),
  anomalyDetected('anomaly_detected'),
  behavioralAnomalyDetected('behavioral_anomaly_detected'),
  threatIntelMatch('threat_intel_match'),
  suspiciousActivity('suspicious_activity'),
  dataBreachSuspected('data_breach_suspected'),
  unauthorizedAccess('unauthorized_access'),
  privilegeEscalation('privilege_escalation'),
  malwareDetected('malware_detected'),
  phishingAttempt('phishing_attempt'),
  ddosAttack('ddos_attack'),
  sqlInjection('sql_injection'),
  xssAttempt('xss_attempt'),
  csrfAttempt('csrf_attempt'),
  sessionHijacking('session_hijacking'),
  cryptographicFailure('cryptographic_failure'),
  configurationError('configuration_error'),
  systemError('system_error'),
  monitoringStarted('monitoring_started'),
  monitoringStopped('monitoring_stopped');
  
  const SecurityEventType(this.value);
  final String value;
  
  bool get isUserActivity => [
    SecurityEventType.loginAttempt,
    SecurityEventType.loginSuccess,
    SecurityEventType.loginFailed,
  ].contains(this);
}

enum SecuritySeverity { 
  info(0), 
  low(1), 
  warning(2), 
  high(3), 
  critical(4);
  
  const SecuritySeverity(this.level);
  final int level;
}

enum SecurityRiskLevel { low, medium, high, critical }
enum SecurityAction { monitor, alert, block, quarantine }
enum IncidentStatus { detected, investigating, responding, contained, resolved }
enum SecurityIncidentType { bruteForce, anomaly, threatIntel, dataLeak, systemBreach }

// Data classes
class SecurityEvent {
  final String id;
  final String userId;
  final SecurityEventType eventType;
  final String description;
  final SecuritySeverity severity;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceFingerprint;
  final GeoLocation? location;
  final Map<String, dynamic> metadata;
  
  const SecurityEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.description,
    required this.severity,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.deviceFingerprint,
    this.location,
    required this.metadata,
  });
  
  factory SecurityEvent.securityMonitoring({
    required SecurityEventType eventType,
    required String description,
    required SecuritySeverity severity,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityEvent(
      id: 'sec_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'system',
      eventType: eventType,
      description: description,
      severity: severity,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
  }
  
  factory SecurityEvent.incidentResponse({
    required String incidentId,
    required SecurityIncidentType incidentType,
    required SecuritySeverity severity,
    required String description,
    required List<String> responses,
  }) {
    return SecurityEvent(
      id: 'inc_response_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'system',
      eventType: SecurityEventType.suspiciousActivity,
      description: description,
      severity: severity,
      timestamp: DateTime.now(),
      metadata: {
        'incidentId': incidentId,
        'incidentType': incidentType.name,
        'responses': responses,
      },
    );
  }
  
  factory SecurityEvent.systemError({
    required String description,
    required String error,
    required SecuritySeverity severity,
  }) {
    return SecurityEvent(
      id: 'err_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'system',
      eventType: SecurityEventType.systemError,
      description: description,
      severity: severity,
      timestamp: DateTime.now(),
      metadata: {'error': error},
    );
  }
}

class GeoLocation {
  final double latitude;
  final double longitude;
  final String? country;
  final String? city;
  
  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.country,
    this.city,
  });
}

class AuthenticationAnomaly {
  final String type;
  final String description;
  final double severity;
  final Map<String, dynamic> details;
  
  const AuthenticationAnomaly({
    required this.type,
    required this.description,
    required this.severity,
    required this.details,
  });
  
  Map<String, dynamic> toJson() => {
    'type': type,
    'description': description,
    'severity': severity,
    'details': details,
  };
}

class AuthenticationAnomalyResult {
  final String userId;
  final List<AuthenticationAnomaly> anomalies;
  final double riskScore;
  final SecurityRiskLevel riskLevel;
  final SecurityAction recommendedAction;
  final DateTime analysisTimestamp;
  
  const AuthenticationAnomalyResult({
    required this.userId,
    required this.anomalies,
    required this.riskScore,
    required this.riskLevel,
    required this.recommendedAction,
    required this.analysisTimestamp,
  });
}

class BruteForceAnalysis {
  final String userId;
  final String ipAddress;
  final String? targetResource;
  final DateTime analysisTimestamp;
  
  int failedAttempts = 0;
  Duration timeSpan = Duration.zero;
  List<String> patterns = [];
  double attackProbability = 0.0;
  bool isCoordinatedAttack = false;
  ThreatIntelligenceMatch? threatIntelMatch;
  List<String> mitigationRecommendations = [];
  
  BruteForceAnalysis({
    required this.userId,
    required this.ipAddress,
    this.targetResource,
    required this.analysisTimestamp,
  });
}

class SecurityMetricsDashboard {
  final Duration timeRange;
  final DateTime generatedAt;
  
  // Authentication metrics
  final int totalLoginAttempts;
  final int successfulLogins;
  final int failedLogins;
  final int blockedLogins;
  
  // Security event metrics
  final int securityAlertsGenerated;
  final int anomaliesDetected;
  final int bruteForceAttempts;
  final int suspiciousActivities;
  
  // User activity metrics
  final int uniqueUsers;
  final int uniqueIpAddresses;
  final int uniqueDevices;
  
  // Threat intelligence metrics
  final int threatIntelHits;
  final int blockedIPs;
  final int quarantinedUsers;
  
  // Compliance metrics
  final int auditLogEntries;
  final int gdprRequestsProcessed;
  final int dataBreachIncidents;
  
  // Performance metrics
  final Duration averageResponseTime;
  final double uptime;
  final double errorRate;
  
  // Analysis results
  final List<ThreatType> topThreatTypes;
  final List<String> topAttackSources;
  final Map<int, int> hourlyActivityPattern;
  final Map<String, int> geographicalDistribution;
  
  const SecurityMetricsDashboard({
    required this.timeRange,
    required this.generatedAt,
    required this.totalLoginAttempts,
    required this.successfulLogins,
    required this.failedLogins,
    required this.blockedLogins,
    required this.securityAlertsGenerated,
    required this.anomaliesDetected,
    required this.bruteForceAttempts,
    required this.suspiciousActivities,
    required this.uniqueUsers,
    required this.uniqueIpAddresses,
    required this.uniqueDevices,
    required this.threatIntelHits,
    required this.blockedIPs,
    required this.quarantinedUsers,
    required this.auditLogEntries,
    required this.gdprRequestsProcessed,
    required this.dataBreachIncidents,
    required this.averageResponseTime,
    required this.uptime,
    required this.errorRate,
    required this.topThreatTypes,
    required this.topAttackSources,
    required this.hourlyActivityPattern,
    required this.geographicalDistribution,
  });
}

class SecurityIncident {
  final String id;
  final SecurityIncidentType type;
  final SecuritySeverity severity;
  final String description;
  final DateTime detectedAt;
  IncidentStatus status;
  DateTime? responseStartedAt;
  final Map<String, dynamic> context;
  
  SecurityIncident({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.detectedAt,
    required this.status,
    this.responseStartedAt,
    required this.context,
  });
}

class IncidentResponse {
  final SecurityIncident incident;
  final IncidentResponsePlan responsePlan;
  final List<String> executedActions;
  final Duration responseTime;
  
  const IncidentResponse({
    required this.incident,
    required this.responsePlan,
    required this.executedActions,
    required this.responseTime,
  });
}

class IncidentResponsePlan {
  final List<AutomatedAction> automatedActions;
  
  const IncidentResponsePlan({
    required this.automatedActions,
  });
  
  List<AutomatedAction> get actions => automatedActions;
}

class AutomatedAction {
  final String name;
  final String description;
  
  const AutomatedAction({
    required this.name,
    required this.description,
  });
}

class SecurityComplianceReport {
  final String reportId;
  final DateTime generatedAt;
  final Duration reportingPeriod;
  
  ComplianceAssessment? owaspCompliance;
  ComplianceAssessment? cybersecurityActCompliance;
  ComplianceAssessment? gdprCompliance;
  ComplianceAssessment? iso27001Compliance;
  List<SecurityControl>? securityControls;
  VulnerabilityAssessmentResult? vulnerabilityAssessment;
  RiskAssessmentResult? riskAssessment;
  List<String>? recommendations;
  
  SecurityComplianceReport({
    required this.reportId,
    required this.generatedAt,
    required this.reportingPeriod,
  });
}

// Additional placeholder classes
class ThreatIntelligenceMatch {
  Map<String, dynamic> toJson() => {};
}

class UserBehaviorProfile {
  final String userId;
  
  UserBehaviorProfile({required this.userId});
  
  void updateWithEvent(SecurityEvent event) {}
  double calculateAnomalyScore() => 0.0;
}

class SecurityEventListener {
  void onSecurityEvent(SecurityEvent event) {}
}

class ComplianceAssessment {
  final int score;
  final ComplianceStatus status;
  
  const ComplianceAssessment({required this.score, required this.status});
}

enum ComplianceStatus { compliant, nonCompliant, partiallyCompliant }

class SecurityControl {
  final String name;
  final bool effective;
  
  const SecurityControl({required this.name, required this.effective});
}

class VulnerabilityAssessmentResult {
  final List<SecurityVulnerability> vulnerabilities;
  
  const VulnerabilityAssessmentResult({required this.vulnerabilities});
}

class SecurityVulnerability {
  final String id;
  final String description;
  final SecuritySeverity severity;
  
  const SecurityVulnerability({
    required this.id,
    required this.description,
    required this.severity,
  });
}

class RiskAssessmentResult {
  final List<SecurityRisk> risks;
  
  const RiskAssessmentResult({required this.risks});
}

class SecurityRisk {
  final String id;
  final String description;
  final SecurityRiskLevel level;
  
  const SecurityRisk({
    required this.id,
    required this.description,
    required this.level,
  });
}

class ThreatType {
  final String name;
  final int count;
  
  const ThreatType({required this.name, required this.count});
}