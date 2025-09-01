import 'package:equatable/equatable.dart';

/// Two-factor authentication method types
enum TwoFactorMethod {
  sms('sms', 'SMS'),
  totp('totp', 'Authenticator App'),
  backupCode('backup_code', 'Backup Code');

  const TwoFactorMethod(this.value, this.displayName);
  
  final String value;
  final String displayName;
  
  /// Get Dutch display name
  String get dutchDisplayName {
    switch (this) {
      case TwoFactorMethod.sms:
        return 'SMS';
      case TwoFactorMethod.totp:
        return 'Authenticator App';
      case TwoFactorMethod.backupCode:
        return 'Backup Code';
    }
  }
  
  static TwoFactorMethod fromString(String value) {
    return TwoFactorMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => TwoFactorMethod.sms,
    );
  }
}

/// Two-factor authentication configuration
class TwoFactorConfig extends Equatable {
  final bool isEnabled;
  final TwoFactorMethod preferredMethod;
  final List<TwoFactorMethod> enabledMethods;
  final String? phoneNumber;
  final bool hasTotpSecret;
  final int backupCodesRemaining;
  final DateTime? lastUsed;
  final DateTime? setupDate;
  
  const TwoFactorConfig({
    this.isEnabled = false,
    this.preferredMethod = TwoFactorMethod.sms,
    this.enabledMethods = const [],
    this.phoneNumber,
    this.hasTotpSecret = false,
    this.backupCodesRemaining = 0,
    this.lastUsed,
    this.setupDate,
  });
  
  /// Check if method is enabled
  bool isMethodEnabled(TwoFactorMethod method) {
    return enabledMethods.contains(method);
  }
  
  /// Get status in Dutch
  String get statusDutch {
    if (!isEnabled) return 'Niet ingeschakeld';
    if (enabledMethods.isEmpty) return 'Niet geconfigureerd';
    return 'Actief - ${preferredMethod.dutchDisplayName}';
  }
  
  /// Copy with updated properties
  TwoFactorConfig copyWith({
    bool? isEnabled,
    TwoFactorMethod? preferredMethod,
    List<TwoFactorMethod>? enabledMethods,
    String? phoneNumber,
    bool? hasTotpSecret,
    int? backupCodesRemaining,
    DateTime? lastUsed,
    DateTime? setupDate,
  }) {
    return TwoFactorConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      preferredMethod: preferredMethod ?? this.preferredMethod,
      enabledMethods: enabledMethods ?? this.enabledMethods,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      hasTotpSecret: hasTotpSecret ?? this.hasTotpSecret,
      backupCodesRemaining: backupCodesRemaining ?? this.backupCodesRemaining,
      lastUsed: lastUsed ?? this.lastUsed,
      setupDate: setupDate ?? this.setupDate,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'preferredMethod': preferredMethod.value,
      'enabledMethods': enabledMethods.map((m) => m.value).toList(),
      'phoneNumber': phoneNumber,
      'hasTotpSecret': hasTotpSecret,
      'backupCodesRemaining': backupCodesRemaining,
      'lastUsed': lastUsed?.toIso8601String(),
      'setupDate': setupDate?.toIso8601String(),
    };
  }
  
  /// Create from JSON
  factory TwoFactorConfig.fromJson(Map<String, dynamic> json) {
    return TwoFactorConfig(
      isEnabled: json['isEnabled'] ?? false,
      preferredMethod: TwoFactorMethod.fromString(json['preferredMethod'] ?? 'sms'),
      enabledMethods: (json['enabledMethods'] as List<dynamic>?)
          ?.map((m) => TwoFactorMethod.fromString(m.toString()))
          .toList() ?? [],
      phoneNumber: json['phoneNumber'],
      hasTotpSecret: json['hasTotpSecret'] ?? false,
      backupCodesRemaining: json['backupCodesRemaining'] ?? 0,
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
      setupDate: json['setupDate'] != null ? DateTime.parse(json['setupDate']) : null,
    );
  }
  
  @override
  List<Object?> get props => [
    isEnabled,
    preferredMethod,
    enabledMethods,
    phoneNumber,
    hasTotpSecret,
    backupCodesRemaining,
    lastUsed,
    setupDate,
  ];
}

/// Biometric authentication configuration
class BiometricConfig extends Equatable {
  final bool isEnabled;
  final bool isSupported;
  final List<BiometricType> availableTypes;
  final List<BiometricType> enabledTypes;
  final bool requiresPin;
  final DateTime? lastUsed;
  final DateTime? setupDate;
  final int failedAttempts;
  final DateTime? lockedUntil;
  
  const BiometricConfig({
    this.isEnabled = false,
    this.isSupported = false,
    this.availableTypes = const [],
    this.enabledTypes = const [],
    this.requiresPin = false,
    this.lastUsed,
    this.setupDate,
    this.failedAttempts = 0,
    this.lockedUntil,
  });
  
  /// Check if device is locked due to failed attempts
  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }
  
  /// Get status in Dutch
  String get statusDutch {
    if (!isSupported) return 'Niet ondersteund';
    if (isLocked) return 'Vergrendeld';
    if (!isEnabled) return 'Niet ingeschakeld';
    if (enabledTypes.isEmpty) return 'Niet geconfigureerd';
    return 'Actief';
  }
  
  /// Get available types in Dutch
  List<String> get availableTypesDutch {
    return availableTypes.map((type) => type.dutchName).toList();
  }
  
  /// Copy with updated properties
  BiometricConfig copyWith({
    bool? isEnabled,
    bool? isSupported,
    List<BiometricType>? availableTypes,
    List<BiometricType>? enabledTypes,
    bool? requiresPin,
    DateTime? lastUsed,
    DateTime? setupDate,
    int? failedAttempts,
    DateTime? lockedUntil,
  }) {
    return BiometricConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      isSupported: isSupported ?? this.isSupported,
      availableTypes: availableTypes ?? this.availableTypes,
      enabledTypes: enabledTypes ?? this.enabledTypes,
      requiresPin: requiresPin ?? this.requiresPin,
      lastUsed: lastUsed ?? this.lastUsed,
      setupDate: setupDate ?? this.setupDate,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'isSupported': isSupported,
      'availableTypes': availableTypes.map((t) => t.name).toList(),
      'enabledTypes': enabledTypes.map((t) => t.name).toList(),
      'requiresPin': requiresPin,
      'lastUsed': lastUsed?.toIso8601String(),
      'setupDate': setupDate?.toIso8601String(),
      'failedAttempts': failedAttempts,
      'lockedUntil': lockedUntil?.toIso8601String(),
    };
  }
  
  /// Create from JSON
  factory BiometricConfig.fromJson(Map<String, dynamic> json) {
    return BiometricConfig(
      isEnabled: json['isEnabled'] ?? false,
      isSupported: json['isSupported'] ?? false,
      availableTypes: (json['availableTypes'] as List<dynamic>?)
          ?.map((t) => BiometricType.fromString(t.toString()))
          .toList() ?? [],
      enabledTypes: (json['enabledTypes'] as List<dynamic>?)
          ?.map((t) => BiometricType.fromString(t.toString()))
          .toList() ?? [],
      requiresPin: json['requiresPin'] ?? false,
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
      setupDate: json['setupDate'] != null ? DateTime.parse(json['setupDate']) : null,
      failedAttempts: json['failedAttempts'] ?? 0,
      lockedUntil: json['lockedUntil'] != null ? DateTime.parse(json['lockedUntil']) : null,
    );
  }
  
  @override
  List<Object?> get props => [
    isEnabled,
    isSupported,
    availableTypes,
    enabledTypes,
    requiresPin,
    lastUsed,
    setupDate,
    failedAttempts,
    lockedUntil,
  ];
}

/// Biometric authentication types
enum BiometricType {
  fingerprint('fingerprint'),
  face('face'),
  iris('iris'),
  weak('weak'),
  strong('strong');
  
  const BiometricType(this.name);
  
  final String name;
  
  /// Get Dutch display name
  String get dutchName {
    switch (this) {
      case BiometricType.fingerprint:
        return 'Vingerafdruk';
      case BiometricType.face:
        return 'Gezichtsherkenning';
      case BiometricType.iris:
        return 'Iris scan';
      case BiometricType.weak:
        return 'Zwakke biometrie';
      case BiometricType.strong:
        return 'Sterke biometrie';
    }
  }
  
  static BiometricType fromString(String name) {
    return BiometricType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => BiometricType.fingerprint,
    );
  }
}

/// Authentication security levels
enum AuthenticationLevel {
  basic(1, 'Basis'),
  twoFactor(2, 'Tweefactor'),
  biometric(3, 'Biometrisch'),
  combined(4, 'Gecombineerd');
  
  const AuthenticationLevel(this.level, this.dutchName);
  
  final int level;
  final String dutchName;
  
  /// Check if this level is stronger than another
  bool isStrongerThan(AuthenticationLevel other) {
    return level > other.level;
  }
  
  /// Get description in Dutch
  String get descriptionDutch {
    switch (this) {
      case AuthenticationLevel.basic:
        return 'Alleen wachtwoord';
      case AuthenticationLevel.twoFactor:
        return 'Wachtwoord + tweede factor';
      case AuthenticationLevel.biometric:
        return 'Biometrische authenticatie';
      case AuthenticationLevel.combined:
        return 'Alle beveiligingslagen actief';
    }
  }
  
  static AuthenticationLevel fromString(String name) {
    return AuthenticationLevel.values.firstWhere(
      (level) => level.name == name,
      orElse: () => AuthenticationLevel.basic,
    );
  }
}

/// Backup code for 2FA recovery
class BackupCode extends Equatable {
  final String code;
  final bool isUsed;
  final DateTime createdAt;
  final DateTime? usedAt;
  final String hashedCode;
  
  const BackupCode({
    required this.code,
    required this.hashedCode,
    this.isUsed = false,
    required this.createdAt,
    this.usedAt,
  });
  
  /// Create a new backup code
  factory BackupCode.generate() {
    final code = _generateSecureCode();
    final hashedCode = _hashCode(code);
    
    return BackupCode(
      code: code,
      hashedCode: hashedCode,
      createdAt: DateTime.now(),
    );
  }
  
  /// Verify if provided code matches this backup code
  bool verify(String providedCode) {
    return _hashCode(providedCode.replaceAll('-', '')) == hashedCode;
  }
  
  /// Mark as used
  BackupCode markAsUsed() {
    return BackupCode(
      code: code,
      hashedCode: hashedCode,
      isUsed: true,
      createdAt: createdAt,
      usedAt: DateTime.now(),
    );
  }
  
  /// Format code for display (e.g., 12345-67890)
  String get formattedCode {
    if (code.length >= 8) {
      return '${code.substring(0, 4)}-${code.substring(4, 8)}';
    }
    return code;
  }
  
  /// Generate a secure 8-character alphanumeric code
  static String _generateSecureCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var code = '';
    
    // Simple secure random generation for demo
    // In production, use crypto.getRandomValues or similar
    for (int i = 0; i < 8; i++) {
      code += chars[(random + i * 7) % chars.length];
    }
    
    return code;
  }
  
  /// Hash the code for secure storage
  static String _hashCode(String code) {
    // Simple hash for demo - use proper crypto hashing in production
    var hash = 0;
    for (int i = 0; i < code.length; i++) {
      hash = ((hash << 5) - hash) + code.codeUnitAt(i);
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.toString();
  }
  
  /// Convert to JSON (excludes plain text code)
  Map<String, dynamic> toJson() {
    return {
      'hashedCode': hashedCode,
      'isUsed': isUsed,
      'createdAt': createdAt.toIso8601String(),
      'usedAt': usedAt?.toIso8601String(),
    };
  }
  
  /// Create from JSON
  factory BackupCode.fromJson(Map<String, dynamic> json) {
    return BackupCode(
      code: '', // Code is not stored in JSON for security
      hashedCode: json['hashedCode'],
      isUsed: json['isUsed'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
    );
  }
  
  @override
  List<Object?> get props => [hashedCode, isUsed, createdAt, usedAt];
}

/// Security event for audit logging
class AuthSecurityEvent extends Equatable {
  final String eventId;
  final String userId;
  final AuthSecurityEventType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? ipAddress;
  final String? userAgent;
  final AuthSecurityEventSeverity severity;
  
  const AuthSecurityEvent({
    required this.eventId,
    required this.userId,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata = const {},
    this.ipAddress,
    this.userAgent,
    this.severity = AuthSecurityEventSeverity.info,
  });
  
  /// Create a login attempt event
  factory AuthSecurityEvent.loginAttempt({
    required String userId,
    required bool success,
    String? ipAddress,
    String? userAgent,
    TwoFactorMethod? method,
  }) {
    return AuthSecurityEvent(
      eventId: _generateEventId(),
      userId: userId,
      type: success ? AuthSecurityEventType.loginSuccess : AuthSecurityEventType.loginFailed,
      description: success ? 'Successful login' : 'Failed login attempt',
      timestamp: DateTime.now(),
      severity: success ? AuthSecurityEventSeverity.info : AuthSecurityEventSeverity.warning,
      ipAddress: ipAddress,
      userAgent: userAgent,
      metadata: {
        'success': success,
        if (method != null) 'twoFactorMethod': method.value,
      },
    );
  }
  
  /// Create a 2FA setup event
  factory AuthSecurityEvent.twoFactorSetup({
    required String userId,
    required TwoFactorMethod method,
    required bool success,
    String? ipAddress,
  }) {
    return AuthSecurityEvent(
      eventId: _generateEventId(),
      userId: userId,
      type: AuthSecurityEventType.twoFactorSetup,
      description: 'Two-factor authentication ${success ? 'enabled' : 'setup failed'}: ${method.dutchDisplayName}',
      timestamp: DateTime.now(),
      severity: success ? AuthSecurityEventSeverity.info : AuthSecurityEventSeverity.warning,
      ipAddress: ipAddress,
      metadata: {
        'method': method.value,
        'success': success,
      },
    );
  }
  
  /// Create a biometric setup event
  factory AuthSecurityEvent.biometricSetup({
    required String userId,
    required BiometricType type,
    required bool success,
    String? ipAddress,
  }) {
    return AuthSecurityEvent(
      eventId: _generateEventId(),
      userId: userId,
      type: AuthSecurityEventType.biometricSetup,
      description: 'Biometric authentication ${success ? 'enabled' : 'setup failed'}: ${type.dutchName}',
      timestamp: DateTime.now(),
      severity: success ? AuthSecurityEventSeverity.info : AuthSecurityEventSeverity.warning,
      ipAddress: ipAddress,
      metadata: {
        'biometricType': type.name,
        'success': success,
      },
    );
  }
  
  /// Generate unique event ID
  static String _generateEventId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    final random = now.microsecond.toString().padLeft(6, '0');
    return 'evt_$timestamp$random';
  }
  
  /// Get Dutch description
  String get dutchDescription {
    switch (type) {
      case AuthSecurityEventType.loginSuccess:
        return 'Succesvol ingelogd';
      case AuthSecurityEventType.loginFailed:
        return 'Inlogpoging mislukt';
      case AuthSecurityEventType.twoFactorSetup:
        return 'Tweefactor authenticatie ingesteld';
      case AuthSecurityEventType.biometricSetup:
        return 'Biometrische authenticatie ingesteld';
      case AuthSecurityEventType.passwordChanged:
        return 'Wachtwoord gewijzigd';
      case AuthSecurityEventType.accountLocked:
        return 'Account vergrendeld';
      case AuthSecurityEventType.suspiciousActivity:
        return 'Verdachte activiteit gedetecteerd';
    }
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'userId': userId,
      'type': type.name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'severity': severity.name,
    };
  }
  
  /// Create from JSON
  factory AuthSecurityEvent.fromJson(Map<String, dynamic> json) {
    return AuthSecurityEvent(
      eventId: json['eventId'],
      userId: json['userId'],
      type: AuthSecurityEventType.fromString(json['type']),
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      severity: AuthSecurityEventSeverity.fromString(json['severity'] ?? 'info'),
    );
  }
  
  @override
  List<Object?> get props => [
    eventId,
    userId,
    type,
    description,
    timestamp,
    metadata,
    ipAddress,
    userAgent,
    severity,
  ];
}

/// Security event types
enum AuthSecurityEventType {
  loginSuccess('login_success'),
  loginFailed('login_failed'),
  twoFactorSetup('two_factor_setup'),
  biometricSetup('biometric_setup'),
  passwordChanged('password_changed'),
  accountLocked('account_locked'),
  suspiciousActivity('suspicious_activity');
  
  const AuthSecurityEventType(this.value);
  
  final String value;
  
  static AuthSecurityEventType fromString(String value) {
    return AuthSecurityEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AuthSecurityEventType.suspiciousActivity,
    );
  }
}

/// Security event severity levels
enum AuthSecurityEventSeverity {
  info('info'),
  warning('warning'),
  error('error'),
  critical('critical');
  
  const AuthSecurityEventSeverity(this.value);
  
  final String value;
  
  static AuthSecurityEventSeverity fromString(String value) {
    return AuthSecurityEventSeverity.values.firstWhere(
      (severity) => severity.value == value,
      orElse: () => AuthSecurityEventSeverity.info,
    );
  }
}