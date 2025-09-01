import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive Session Security Management for SecuryFlex
/// 
/// Provides enterprise-grade session management with:
/// - Session timeout (idle and absolute)
/// - Concurrent session detection
/// - Security event logging
/// - Device fingerprinting
/// - Suspicious activity detection
class SessionSecurityService {
  static const String _sessionKey = 'securyflex_active_sessions';
  static const String _securityEventsKey = 'securyflex_security_events';
  static const String _deviceFingerprintKey = 'securyflex_device_fingerprint';
  
  // Session timeout configuration
  static const int _idleTimeoutMinutes = 30;
  static const int _absoluteTimeoutHours = 8;
  static const int _maxConcurrentSessions = 3;
  
  // Security monitoring
  static final Map<String, Timer> _heartbeatTimers = {};
  static final Map<String, DateTime> _lastActivity = {};
  
  /// Initialize session security
  static Future<void> initialize() async {
    try {
      // Clean up expired sessions on startup
      await _cleanupExpiredSessions();
      
      // Initialize device fingerprint
      await _initializeDeviceFingerprint();
      
      developer.log('Session Security Service initialized', name: 'SessionSecurity');
    } catch (e) {
      developer.log('Session Security initialization error: $e', name: 'SessionSecurity');
    }
  }
  
  /// Create new secure session
  static Future<SessionResult> createSession({
    required String userId,
    required String userType,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final now = DateTime.now();
      
      // Check for concurrent session limit
      final activeSessions = await _getActiveSessions(userId);
      if (activeSessions.length >= _maxConcurrentSessions) {
        // Terminate oldest session
        await _terminateOldestSession(userId);
        
        await _logSecurityEvent(userId, 'Concurrent session limit reached', {
          'maxSessions': _maxConcurrentSessions,
          'action': 'terminated_oldest_session',
        });
      }
      
      // Generate session
      final sessionId = _generateSecureSessionId();
      final deviceFingerprint = await _getDeviceFingerprint();
      
      final session = UserSession(
        sessionId: sessionId,
        userId: userId,
        userType: userType,
        createdAt: now,
        lastActivity: now,
        expiresAt: now.add(Duration(hours: _absoluteTimeoutHours)),
        deviceFingerprint: deviceFingerprint,
        deviceInfo: deviceInfo ?? {},
        isActive: true,
      );
      
      // Store session
      await _storeSession(session);
      
      // Start heartbeat monitoring
      _startHeartbeat(userId, sessionId);
      
      // Log security event
      await _logSecurityEvent(userId, 'Session created', {
        'sessionId': _obfuscateSessionId(sessionId),
        'deviceFingerprint': deviceFingerprint,
        'userType': userType,
      });
      
      return SessionResult.success(
        'Sessie succesvol aangemaakt',
        data: {'sessionId': sessionId},
      );
      
    } catch (e) {
      return SessionResult.error(
        'SESSION_CREATE_FAILED',
        'Fout bij aanmaken sessie: $e',
      );
    }
  }
  
  /// Validate existing session
  static Future<SessionValidationResult> validateSession({
    required String userId,
    required String sessionId,
  }) async {
    try {
      final session = await _getSession(userId, sessionId);
      
      if (session == null) {
        return SessionValidationResult(
          isValid: false,
          reason: 'Sessie niet gevonden',
          errorCode: 'SESSION_NOT_FOUND',
        );
      }
      
      final now = DateTime.now();
      
      // Check absolute timeout
      if (now.isAfter(session.expiresAt)) {
        await _terminateSession(userId, sessionId, 'absolute_timeout');
        return SessionValidationResult(
          isValid: false,
          reason: 'Sessie verlopen (maximale duur)',
          errorCode: 'SESSION_EXPIRED_ABSOLUTE',
        );
      }
      
      // Check idle timeout
      final idleTime = now.difference(session.lastActivity);
      if (idleTime.inMinutes > _idleTimeoutMinutes) {
        await _terminateSession(userId, sessionId, 'idle_timeout');
        return SessionValidationResult(
          isValid: false,
          reason: 'Sessie verlopen (inactiviteit)',
          errorCode: 'SESSION_EXPIRED_IDLE',
        );
      }
      
      // Check device fingerprint for suspicious activity
      final currentFingerprint = await _getDeviceFingerprint();
      if (currentFingerprint != session.deviceFingerprint) {
        await _logSecurityEvent(userId, 'Device fingerprint mismatch', {
          'sessionId': _obfuscateSessionId(sessionId),
          'originalFingerprint': session.deviceFingerprint,
          'currentFingerprint': currentFingerprint,
        });
        
        // Could terminate session here for high-security applications
        // For now, we'll log and continue
      }
      
      // Update last activity
      await _updateLastActivity(userId, sessionId);
      
      return SessionValidationResult(
        isValid: true,
        session: session,
        message: 'Sessie geldig',
      );
      
    } catch (e) {
      return SessionValidationResult(
        isValid: false,
        reason: 'Fout bij valideren sessie: $e',
        errorCode: 'VALIDATION_ERROR',
      );
    }
  }
  
  /// Update session activity
  static Future<void> updateActivity(String userId, String sessionId) async {
    try {
      await _updateLastActivity(userId, sessionId);
      _lastActivity['${userId}_$sessionId'] = DateTime.now();
    } catch (e) {
      developer.log('Error updating activity: $e', name: 'SessionSecurity');
    }
  }
  
  /// Terminate session
  static Future<void> terminateSession({
    required String userId,
    required String sessionId,
    String reason = 'user_logout',
  }) async {
    await _terminateSession(userId, sessionId, reason);
  }
  
  /// Terminate all sessions for user
  static Future<void> terminateAllSessions(String userId, {String reason = 'security_logout'}) async {
    try {
      final activeSessions = await _getActiveSessions(userId);
      
      for (final session in activeSessions) {
        await _terminateSession(userId, session.sessionId, reason);
      }
      
      await _logSecurityEvent(userId, 'All sessions terminated', {
        'reason': reason,
        'sessionCount': activeSessions.length,
      });
      
    } catch (e) {
      developer.log('Error terminating all sessions: $e', name: 'SessionSecurity');
    }
  }
  
  /// Get active sessions for user
  static Future<List<UserSession>> getActiveSessions(String userId) async {
    return await _getActiveSessions(userId);
  }
  
  /// Detect suspicious activity
  static Future<SuspiciousActivityResult> detectSuspiciousActivity(String userId) async {
    try {
      final activeSessions = await _getActiveSessions(userId);
      final securityEvents = await _getRecentSecurityEvents(userId, hours: 24);
      
      final suspiciousIndicators = <String>[];
      
      // Check for too many concurrent sessions
      if (activeSessions.length > _maxConcurrentSessions) {
        suspiciousIndicators.add('Te veel actieve sessies (${activeSessions.length})');
      }
      
      // Check for rapid session creation
      final recentCreations = securityEvents
          .where((event) => event.eventType == 'Session created')
          .where((event) => DateTime.now().difference(event.timestamp).inHours < 1)
          .length;
      
      if (recentCreations > 5) {
        suspiciousIndicators.add('Veelvuldige sessie aanmaak ($recentCreations in laatste uur)');
      }
      
      // Check for multiple device fingerprints
      final uniqueFingerprints = activeSessions
          .map((s) => s.deviceFingerprint)
          .toSet()
          .length;
      
      if (uniqueFingerprints > 2) {
        suspiciousIndicators.add('Meerdere apparaten ($uniqueFingerprints verschillende)');
      }
      
      // Check for authentication failures
      final failedLogins = securityEvents
          .where((event) => event.eventType.contains('failed') || event.eventType.contains('denied'))
          .where((event) => DateTime.now().difference(event.timestamp).inHours < 24)
          .length;
      
      if (failedLogins > 10) {
        suspiciousIndicators.add('Veel mislukte inlogpogingen ($failedLogins in 24 uur)');
      }
      
      final isSuspicious = suspiciousIndicators.isNotEmpty;
      
      if (isSuspicious) {
        await _logSecurityEvent(userId, 'Suspicious activity detected', {
          'indicators': suspiciousIndicators,
          'activeSessions': activeSessions.length,
          'riskLevel': suspiciousIndicators.length > 2 ? 'HIGH' : 'MEDIUM',
        });
      }
      
      return SuspiciousActivityResult(
        isSuspicious: isSuspicious,
        indicators: suspiciousIndicators,
        riskLevel: suspiciousIndicators.length > 2 ? 'HIGH' : 'MEDIUM',
        recommendedAction: isSuspicious 
          ? (suspiciousIndicators.length > 2 ? 'TERMINATE_ALL_SESSIONS' : 'REQUIRE_2FA')
          : 'MONITOR',
      );
      
    } catch (e) {
      return SuspiciousActivityResult(
        isSuspicious: false,
        indicators: ['Error tijdens detectie: $e'],
        riskLevel: 'UNKNOWN',
        recommendedAction: 'MONITOR',
      );
    }
  }
  
  /// Get security dashboard data
  static Future<SecurityDashboard> getSecurityDashboard(String userId) async {
    try {
      final activeSessions = await _getActiveSessions(userId);
      final recentEvents = await _getRecentSecurityEvents(userId, hours: 168); // 1 week
      final suspiciousActivity = await detectSuspiciousActivity(userId);
      
      return SecurityDashboard(
        activeSessions: activeSessions,
        recentSecurityEvents: recentEvents,
        suspiciousActivity: suspiciousActivity,
        lastSecurityCheck: DateTime.now(),
      );
    } catch (e) {
      return SecurityDashboard(
        activeSessions: [],
        recentSecurityEvents: [],
        suspiciousActivity: SuspiciousActivityResult(
          isSuspicious: false,
          indicators: [],
          riskLevel: 'UNKNOWN',
          recommendedAction: 'MONITOR',
        ),
        lastSecurityCheck: DateTime.now(),
      );
    }
  }
  
  // Private helper methods
  
  /// Generate secure session ID
  static String _generateSecureSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + DateTime.now().microsecond).toString();
    return 'sess_${random.substring(random.length - 16)}';
  }
  
  /// Store session
  static Future<void> _storeSession(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionKey = '$_sessionKey${session.userId}_${session.sessionId}';
    await prefs.setString(sessionKey, json.encode(session.toJson()));
  }
  
  /// Get specific session
  static Future<UserSession?> _getSession(String userId, String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionKey = '$_sessionKey${userId}_$sessionId';
    final sessionJson = prefs.getString(sessionKey);
    
    if (sessionJson != null) {
      return UserSession.fromJson(json.decode(sessionJson));
    }
    
    return null;
  }
  
  /// Get all active sessions for user
  static Future<List<UserSession>> _getActiveSessions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((key) => key.startsWith('$_sessionKey$userId'))
        .toList();
    
    final sessions = <UserSession>[];
    
    for (final key in keys) {
      final sessionJson = prefs.getString(key);
      if (sessionJson != null) {
        try {
          final session = UserSession.fromJson(json.decode(sessionJson));
          if (session.isActive) {
            sessions.add(session);
          }
        } catch (e) {
          // Remove corrupted session data
          await prefs.remove(key);
        }
      }
    }
    
    return sessions;
  }
  
  /// Update last activity
  static Future<void> _updateLastActivity(String userId, String sessionId) async {
    final session = await _getSession(userId, sessionId);
    if (session != null) {
      final updatedSession = session.copyWith(lastActivity: DateTime.now());
      await _storeSession(updatedSession);
    }
  }
  
  /// Terminate specific session
  static Future<void> _terminateSession(String userId, String sessionId, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = '$_sessionKey${userId}_$sessionId';
      
      // Remove session data
      await prefs.remove(sessionKey);
      
      // Stop heartbeat timer
      final timerKey = '${userId}_$sessionId';
      _heartbeatTimers[timerKey]?.cancel();
      _heartbeatTimers.remove(timerKey);
      _lastActivity.remove(timerKey);
      
      // Log termination
      await _logSecurityEvent(userId, 'Session terminated', {
        'sessionId': _obfuscateSessionId(sessionId),
        'reason': reason,
      });
      
    } catch (e) {
      developer.log('Error terminating session: $e', name: 'SessionSecurity');
    }
  }
  
  /// Terminate oldest session
  static Future<void> _terminateOldestSession(String userId) async {
    final activeSessions = await _getActiveSessions(userId);
    if (activeSessions.isNotEmpty) {
      // Sort by creation date and terminate oldest
      activeSessions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      await _terminateSession(userId, activeSessions.first.sessionId, 'concurrent_limit_reached');
    }
  }
  
  /// Start heartbeat monitoring
  static void _startHeartbeat(String userId, String sessionId) {
    final timerKey = '${userId}_$sessionId';
    
    _heartbeatTimers[timerKey] = Timer.periodic(
      const Duration(minutes: 5), // Check every 5 minutes
      (timer) async {
        final lastActivity = _lastActivity[timerKey];
        if (lastActivity != null) {
          final idleTime = DateTime.now().difference(lastActivity);
          if (idleTime.inMinutes > _idleTimeoutMinutes) {
            await _terminateSession(userId, sessionId, 'idle_timeout');
            timer.cancel();
            _heartbeatTimers.remove(timerKey);
            _lastActivity.remove(timerKey);
          }
        }
      },
    );
  }
  
  /// Clean up expired sessions
  static Future<void> _cleanupExpiredSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionKeys = prefs.getKeys()
        .where((key) => key.startsWith(_sessionKey))
        .toList();
    
    for (final key in sessionKeys) {
      final sessionJson = prefs.getString(key);
      if (sessionJson != null) {
        try {
          final session = UserSession.fromJson(json.decode(sessionJson));
          if (DateTime.now().isAfter(session.expiresAt)) {
            await prefs.remove(key);
          }
        } catch (e) {
          // Remove corrupted data
          await prefs.remove(key);
        }
      }
    }
  }
  
  /// Initialize device fingerprint
  static Future<void> _initializeDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_deviceFingerprintKey)) {
      final fingerprint = _generateDeviceFingerprint();
      await prefs.setString(_deviceFingerprintKey, fingerprint);
    }
  }
  
  /// Generate device fingerprint
  static String _generateDeviceFingerprint() {
    // Simple fingerprinting - in production would include more device characteristics
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'fp_${timestamp.toString().substring(timestamp.toString().length - 12)}';
  }
  
  /// Get device fingerprint
  static Future<String> _getDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceFingerprintKey) ?? _generateDeviceFingerprint();
  }
  
  /// Log security event
  static Future<void> _logSecurityEvent(String userId, String eventType, Map<String, dynamic> data) async {
    try {
      final event = SecurityEvent(
        userId: userId,
        eventType: eventType,
        timestamp: DateTime.now(),
        data: data,
      );
      
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList(_securityEventsKey) ?? [];
      
      // Add new event
      eventsJson.add(json.encode(event.toJson()));
      
      // Keep only last 1000 events per user
      if (eventsJson.length > 1000) {
        eventsJson.removeAt(0);
      }
      
      await prefs.setStringList(_securityEventsKey, eventsJson);
      
      // Log to console in debug mode
      if (kDebugMode) {
        developer.log('Security Event - $userId: $eventType', name: 'SessionSecurity');
      }
    } catch (e) {
      developer.log('Error logging security event: $e', name: 'SessionSecurity');
    }
  }
  
  /// Get recent security events
  static Future<List<SecurityEvent>> _getRecentSecurityEvents(String userId, {int hours = 24}) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getStringList(_securityEventsKey) ?? [];
    
    final events = <SecurityEvent>[];
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    
    for (final eventJson in eventsJson) {
      try {
        final event = SecurityEvent.fromJson(json.decode(eventJson));
        if (event.userId == userId && event.timestamp.isAfter(cutoff)) {
          events.add(event);
        }
      } catch (e) {
        // Skip corrupted event data
      }
    }
    
    return events;
  }
  
  /// Obfuscate session ID for logging
  static String _obfuscateSessionId(String sessionId) {
    if (sessionId.length <= 8) return '****';
    return '${sessionId.substring(0, 4)}****${sessionId.substring(sessionId.length - 4)}';
  }
}

/// User session data model
class UserSession {
  final String sessionId;
  final String userId;
  final String userType;
  final DateTime createdAt;
  final DateTime lastActivity;
  final DateTime expiresAt;
  final String deviceFingerprint;
  final Map<String, dynamic> deviceInfo;
  final bool isActive;
  
  const UserSession({
    required this.sessionId,
    required this.userId,
    required this.userType,
    required this.createdAt,
    required this.lastActivity,
    required this.expiresAt,
    required this.deviceFingerprint,
    required this.deviceInfo,
    required this.isActive,
  });
  
  UserSession copyWith({
    String? sessionId,
    String? userId,
    String? userType,
    DateTime? createdAt,
    DateTime? lastActivity,
    DateTime? expiresAt,
    String? deviceFingerprint,
    Map<String, dynamic>? deviceInfo,
    bool? isActive,
  }) {
    return UserSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      expiresAt: expiresAt ?? this.expiresAt,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      isActive: isActive ?? this.isActive,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'userType': userType,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'deviceFingerprint': deviceFingerprint,
      'deviceInfo': deviceInfo,
      'isActive': isActive,
    };
  }
  
  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      sessionId: json['sessionId'],
      userId: json['userId'],
      userType: json['userType'],
      createdAt: DateTime.parse(json['createdAt']),
      lastActivity: DateTime.parse(json['lastActivity']),
      expiresAt: DateTime.parse(json['expiresAt']),
      deviceFingerprint: json['deviceFingerprint'],
      deviceInfo: Map<String, dynamic>.from(json['deviceInfo']),
      isActive: json['isActive'] ?? true,
    );
  }
}

/// Security event data model
class SecurityEvent {
  final String userId;
  final String eventType;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  
  const SecurityEvent({
    required this.userId,
    required this.eventType,
    required this.timestamp,
    required this.data,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'eventType': eventType,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
  
  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      userId: json['userId'],
      eventType: json['eventType'],
      timestamp: DateTime.parse(json['timestamp']),
      data: Map<String, dynamic>.from(json['data']),
    );
  }
}

/// Session operation result
class SessionResult {
  final bool isSuccess;
  final String? errorCode;
  final String message;
  final Map<String, dynamic>? data;
  
  const SessionResult._({
    required this.isSuccess,
    this.errorCode,
    required this.message,
    this.data,
  });
  
  factory SessionResult.success(String message, {Map<String, dynamic>? data}) {
    return SessionResult._(
      isSuccess: true,
      message: message,
      data: data,
    );
  }
  
  factory SessionResult.error(String errorCode, String message) {
    return SessionResult._(
      isSuccess: false,
      errorCode: errorCode,
      message: message,
    );
  }
}

/// Session validation result
class SessionValidationResult {
  final bool isValid;
  final String? reason;
  final String? errorCode;
  final UserSession? session;
  final String? message;
  
  const SessionValidationResult({
    required this.isValid,
    this.reason,
    this.errorCode,
    this.session,
    this.message,
  });
}

/// Suspicious activity detection result
class SuspiciousActivityResult {
  final bool isSuspicious;
  final List<String> indicators;
  final String riskLevel; // LOW, MEDIUM, HIGH, CRITICAL
  final String recommendedAction; // MONITOR, REQUIRE_2FA, TERMINATE_SESSION, TERMINATE_ALL_SESSIONS
  
  const SuspiciousActivityResult({
    required this.isSuspicious,
    required this.indicators,
    required this.riskLevel,
    required this.recommendedAction,
  });
}

/// Security dashboard data
class SecurityDashboard {
  final List<UserSession> activeSessions;
  final List<SecurityEvent> recentSecurityEvents;
  final SuspiciousActivityResult suspiciousActivity;
  final DateTime lastSecurityCheck;
  
  const SecurityDashboard({
    required this.activeSessions,
    required this.recentSecurityEvents,
    required this.suspiciousActivity,
    required this.lastSecurityCheck,
  });
}