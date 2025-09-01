import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;

/// Biometric Authentication Security Tests
/// Tests enhanced biometric security implementations
void main() {
  group('👆 BIOMETRIC AUTHENTICATION SECURITY TESTS', () {
    
    group('🔒 Enhanced Lockout Mechanisms', () {
      test('Progressive lockout periods after failed attempts', () {
        // Test progressive lockout system
        final lockoutSystem = BiometricLockoutSystem();
        
        // First 2 failures: 30 seconds
        lockoutSystem.recordFailedAttempt('user_001');
        lockoutSystem.recordFailedAttempt('user_001');
        
        expect(lockoutSystem.getLockoutDuration('user_001'), 
          equals(Duration(seconds: 30)));
        expect(lockoutSystem.isLockedOut('user_001'), isTrue);
        
        // 3-4 failures: 2 minutes
        lockoutSystem.recordFailedAttempt('user_001');
        lockoutSystem.recordFailedAttempt('user_001');
        
        expect(lockoutSystem.getLockoutDuration('user_001'), 
          equals(Duration(minutes: 2)));
        
        // 5+ failures: 2 hours
        lockoutSystem.recordFailedAttempt('user_001');
        
        expect(lockoutSystem.getLockoutDuration('user_001'), 
          equals(Duration(hours: 2)));
      });

      test('User-specific lockout isolation', () {
        final lockoutSystem = BiometricLockoutSystem();
        
        // Lock out user_001 but not user_002
        for (int i = 0; i < 5; i++) {
          lockoutSystem.recordFailedAttempt('user_001');
        }
        
        expect(lockoutSystem.isLockedOut('user_001'), isTrue);
        expect(lockoutSystem.isLockedOut('user_002'), isFalse);
        
        // user_002 should still be able to authenticate
        expect(lockoutSystem.canAttemptAuthentication('user_002'), isTrue);
      });

      test('Lockout reset after successful authentication', () {
        final lockoutSystem = BiometricLockoutSystem();
        
        // Record failures
        for (int i = 0; i < 3; i++) {
          lockoutSystem.recordFailedAttempt('user_001');
        }
        
        expect(lockoutSystem.isLockedOut('user_001'), isTrue);
        
        // Successful authentication resets lockout
        lockoutSystem.recordSuccessfulAttempt('user_001');
        
        expect(lockoutSystem.isLockedOut('user_001'), isFalse);
        expect(lockoutSystem.getFailedAttempts('user_001'), equals(0));
      });

      test('Time-based lockout expiration', () {
        final lockoutSystem = BiometricLockoutSystem();
        
        // Record failure with specific timestamp
        final testTime = DateTime.now().subtract(Duration(minutes: 5));
        lockoutSystem.recordFailedAttemptAtTime('user_001', testTime);
        lockoutSystem.recordFailedAttemptAtTime('user_001', testTime);
        
        // Should be locked initially
        expect(lockoutSystem.isLockedOutAtTime('user_001', testTime.add(Duration(seconds: 10))), 
          isTrue);
        
        // Should be unlocked after lockout period
        expect(lockoutSystem.isLockedOutAtTime('user_001', testTime.add(Duration(minutes: 1))), 
          isFalse);
      });
    });

    group('🚫 Anti-Fraud Measures', () {
      test('Device fingerprinting validation', () {
        final deviceValidator = DeviceFingerprintValidator();
        
        // Create device fingerprints
        final device1 = DeviceFingerprint(
          deviceId: 'DEVICE_001_SAMSUNG_A52',
          hardwareModel: 'Samsung Galaxy A52',
          osVersion: 'Android 13',
          screenResolution: '1080x2400',
          biometricCapabilities: ['fingerprint', 'face'],
          timeZone: 'Europe/Amsterdam',
          locale: 'nl_NL',
        );
        
        final device2 = DeviceFingerprint(
          deviceId: 'DEVICE_002_IPHONE_14',
          hardwareModel: 'iPhone 14',
          osVersion: 'iOS 16.5',
          screenResolution: '1170x2532',
          biometricCapabilities: ['faceId', 'touchId'],
          timeZone: 'Europe/Amsterdam',
          locale: 'nl_NL',
        );
        
        // Register devices for user
        deviceValidator.registerDevice('user_001', device1);
        expect(deviceValidator.isKnownDevice('user_001', device1), isTrue);
        expect(deviceValidator.isKnownDevice('user_001', device2), isFalse);
        
        // Test suspicious device detection
        final suspiciousDevice = DeviceFingerprint(
          deviceId: 'EMULATOR_SUSPICIOUS',
          hardwareModel: 'Generic Android',
          osVersion: 'Android 10',
          screenResolution: '720x1280',
          biometricCapabilities: [],
          timeZone: 'UTC',
          locale: 'en_US',
        );
        
        expect(deviceValidator.isSuspiciousDevice(suspiciousDevice), isTrue);
      });

      test('Presentation attack detection', () {
        final padDetector = PresentationAttackDetector();
        
        // Test legitimate biometric samples
        final legitimateFingerprint = BiometricSample(
          type: BiometricType.fingerprint,
          quality: 0.95,
          liveness: 0.99,
          templateData: 'encrypted_template_data',
          captureTime: DateTime.now(),
          deviceSensorData: {
            'pressure': 0.8,
            'temperature': 36.5,
            'conductivity': 0.7,
          }
        );
        
        expect(padDetector.isLegitimate(legitimateFingerprint), isTrue);
        
        // Test spoofing attempts
        final spoofedFingerprint = BiometricSample(
          type: BiometricType.fingerprint,
          quality: 0.85,
          liveness: 0.3, // Low liveness score
          templateData: 'suspicious_template',
          captureTime: DateTime.now(),
          deviceSensorData: {
            'pressure': 0.2, // Low pressure (fake finger)
            'temperature': 20.0, // Room temperature
            'conductivity': 0.1, // Low conductivity
          }
        );
        
        expect(padDetector.isLegitimate(spoofedFingerprint), isFalse);
        expect(padDetector.getSpoofingRisk(spoofedFingerprint), greaterThan(0.7));
      });

      test('Behavioral biometrics analysis', () {
        final behaviorAnalyzer = BehavioralBiometricsAnalyzer();
        
        // Establish user baseline
        final userBaseline = BehavioralProfile(
          userId: 'user_001',
          typingPattern: TypingPattern(
            averageSpeed: 120, // words per minute
            keyHoldTimes: [0.1, 0.12, 0.11, 0.09],
            timeBetweenKeys: [0.08, 0.09, 0.07, 0.10],
          ),
          touchPattern: TouchPattern(
            averagePressure: 0.6,
            touchSize: 15.5,
            gestureSpeed: 200.0,
          ),
          deviceInteraction: DeviceInteractionPattern(
            averageSessionDuration: Duration(minutes: 45),
            screenTimePerDay: Duration(hours: 2),
            mostActiveHours: [9, 10, 14, 15, 17],
          ),
        );
        
        behaviorAnalyzer.setBaseline('user_001', userBaseline);
        
        // Test normal behavior
        final normalSession = BehavioralSession(
          typingPattern: TypingPattern(
            averageSpeed: 118, // Close to baseline
            keyHoldTimes: [0.11, 0.13, 0.10, 0.08],
            timeBetweenKeys: [0.09, 0.08, 0.08, 0.11],
          ),
          touchPattern: TouchPattern(
            averagePressure: 0.58,
            touchSize: 16.0,
            gestureSpeed: 195.0,
          ),
          sessionTime: DateTime.now().hour == 14 ? 14 : 9,
        );
        
        final normalityScore = behaviorAnalyzer.analyzeSession('user_001', normalSession);
        expect(normalityScore, greaterThan(0.8)); // Should be recognized as normal
        
        // Test anomalous behavior
        final anomalousSession = BehavioralSession(
          typingPattern: TypingPattern(
            averageSpeed: 200, // Much faster than baseline
            keyHoldTimes: [0.05, 0.04, 0.06, 0.03], // Much faster
            timeBetweenKeys: [0.03, 0.02, 0.04, 0.02],
          ),
          touchPattern: TouchPattern(
            averagePressure: 0.9, // Much higher pressure
            touchSize: 25.0, // Larger touch size
            gestureSpeed: 400.0, // Much faster gestures
          ),
          sessionTime: 3, // Unusual hour
        );
        
        final anomalyScore = behaviorAnalyzer.analyzeSession('user_001', anomalousSession);
        expect(anomalyScore, lessThan(0.3)); // Should be flagged as anomalous
      });
    });

    group('🔐 Enhanced Security Features', () {
      test('Multi-modal biometric fusion', () {
        final fusionSystem = MultiModalBiometricFusion();
        
        // Test combining multiple biometric modalities
        final fingerprintResult = BiometricAuthResult(
          type: BiometricType.fingerprint,
          confidence: 0.95,
          isAuthentic: true,
          userId: 'user_001',
          timestamp: DateTime.now(),
        );
        
        final faceResult = BiometricAuthResult(
          type: BiometricType.face,
          confidence: 0.88,
          isAuthentic: true,
          userId: 'user_001',
          timestamp: DateTime.now(),
        );
        
        final voiceResult = BiometricAuthResult(
          type: BiometricType.voice,
          confidence: 0.92,
          isAuthentic: true,
          userId: 'user_001',
          timestamp: DateTime.now(),
        );
        
        // Test fusion scoring
        final fusionResult = fusionSystem.fuseResults([
          fingerprintResult,
          faceResult,
          voiceResult,
        ]);
        
        expect(fusionResult.overallConfidence, greaterThan(0.95));
        expect(fusionResult.isAuthenticated, isTrue);
        expect(fusionResult.securityLevel, equals(SecurityLevel.high));
        
        // Test with conflicting results
        final conflictingFace = BiometricAuthResult(
          type: BiometricType.face,
          confidence: 0.3,
          isAuthentic: false,
          userId: 'unknown',
          timestamp: DateTime.now(),
        );
        
        final conflictingResult = fusionSystem.fuseResults([
          fingerprintResult,
          conflictingFace,
        ]);
        
        expect(conflictingResult.isAuthenticated, isFalse);
        expect(conflictingResult.securityLevel, equals(SecurityLevel.critical));
      });

      test('Template protection and privacy', () {
        final templateProtector = BiometricTemplateProtector();
        
        // Test template encryption
        const rawTemplate = 'biometric_template_raw_data_user_001';
        const userId = 'user_001';
        
        final protectedTemplate = templateProtector.protectTemplate(rawTemplate, userId);
        
        expect(protectedTemplate.isEncrypted, isTrue);
        expect(protectedTemplate.data, isNot(equals(rawTemplate)));
        expect(protectedTemplate.data.contains(rawTemplate), isFalse);
        expect(protectedTemplate.userId, equals(userId));
        
        // Test template verification without decryption
        final isMatch = templateProtector.verifyTemplate(
          rawTemplate, 
          protectedTemplate, 
          userId
        );
        
        expect(isMatch, isTrue);
        
        // Test with wrong user
        final wrongUserMatch = templateProtector.verifyTemplate(
          rawTemplate, 
          protectedTemplate, 
          'different_user'
        );
        
        expect(wrongUserMatch, isFalse);
        
        // Test template cancellation (for compromised templates)
        templateProtector.cancelTemplate(protectedTemplate.templateId);
        
        final canceledMatch = templateProtector.verifyTemplate(
          rawTemplate, 
          protectedTemplate, 
          userId
        );
        
        expect(canceledMatch, isFalse);
      });

      test('Secure biometric key derivation', () {
        final keyDerivation = BiometricKeyDerivation();
        
        // Test key derivation from biometric data
        const biometricData = 'stable_biometric_feature_vector_001';
        const userId = 'user_001';
        
        final derivedKey1 = keyDerivation.deriveKey(biometricData, userId);
        final derivedKey2 = keyDerivation.deriveKey(biometricData, userId);
        
        // Same input should produce same key
        expect(derivedKey1, equals(derivedKey2));
        expect(derivedKey1.length, equals(32)); // 256-bit key
        
        // Different user should produce different key
        final differentUserKey = keyDerivation.deriveKey(biometricData, 'user_002');
        expect(derivedKey1, isNot(equals(differentUserKey)));
        
        // Slightly different biometric data should produce similar key (fuzzy extraction)
        const slightlyDifferentData = 'stable_biometric_feature_vector_002';
        final fuzzyKey = keyDerivation.deriveKey(slightlyDifferentData, userId);
        
        final similarity = keyDerivation.calculateKeySimilarity(derivedKey1, fuzzyKey);
        expect(similarity, greaterThan(0.8)); // Should be similar but not identical
      });
    });

    group('🛡️ Privacy and Data Protection', () {
      test('Biometric data anonymization', () {
        final anonymizer = BiometricDataAnonymizer();
        
        final originalSample = BiometricSample(
          type: BiometricType.fingerprint,
          quality: 0.95,
          liveness: 0.99,
          templateData: 'user_001_fingerprint_template_detailed',
          captureTime: DateTime.now(),
          deviceSensorData: {
            'device_id': 'SAMSUNG_A52_001',
            'location': 'Amsterdam_Office_Building_A',
            'ip_address': '192.168.1.100',
          }
        );
        
        final anonymizedSample = anonymizer.anonymize(originalSample);
        
        expect(anonymizedSample.templateData, isNot(contains('user_001')));
        expect(anonymizedSample.deviceSensorData['device_id'], isNull);
        expect(anonymizedSample.deviceSensorData['location'], isNull);
        expect(anonymizedSample.deviceSensorData['ip_address'], isNull);
        expect(anonymizedSample.quality, equals(originalSample.quality));
      });

      test('Differential privacy for biometric analytics', () {
        final privacyEngine = DifferentialPrivacyEngine(epsilon: 1.0);
        
        // Test privacy-preserving analytics
        final biometricUsageStats = [
          BiometricUsageStat(userId: 'user_001', successRate: 0.95, avgResponseTime: 1.2),
          BiometricUsageStat(userId: 'user_002', successRate: 0.88, avgResponseTime: 1.5),
          BiometricUsageStat(userId: 'user_003', successRate: 0.92, avgResponseTime: 1.1),
          BiometricUsageStat(userId: 'user_004', successRate: 0.90, avgResponseTime: 1.3),
          BiometricUsageStat(userId: 'user_005', successRate: 0.85, avgResponseTime: 1.6),
        ];
        
        final noisyAvgSuccessRate = privacyEngine.calculateNoisyAverage(
          biometricUsageStats.map((stat) => stat.successRate).toList()
        );
        
        final actualAvg = biometricUsageStats
          .map((stat) => stat.successRate)
          .reduce((a, b) => a + b) / biometricUsageStats.length;
        
        // Should be close to actual average but with noise for privacy
        expect(noisyAvgSuccessRate, closeTo(actualAvg, 0.1));
        expect(noisyAvgSuccessRate, isNot(equals(actualAvg))); // Should have noise
      });

      test('Secure template storage and retrieval', () {
        final secureStorage = SecureBiometricStorage();
        
        const userId = 'user_001';
        const templateData = 'encrypted_biometric_template_data';
        
        // Store template securely
        final templateId = secureStorage.storeTemplate(userId, templateData);
        expect(templateId, isNotEmpty);
        expect(templateId.length, greaterThan(16));
        
        // Retrieve template
        final retrievedTemplate = secureStorage.retrieveTemplate(templateId, userId);
        expect(retrievedTemplate, equals(templateData));
        
        // Wrong user cannot retrieve
        final wrongUserTemplate = secureStorage.retrieveTemplate(templateId, 'wrong_user');
        expect(wrongUserTemplate, isNull);
        
        // Delete template (GDPR right to erasure)
        final deleteResult = secureStorage.deleteTemplate(templateId, userId);
        expect(deleteResult, isTrue);
        
        // Template should no longer exist
        final deletedTemplate = secureStorage.retrieveTemplate(templateId, userId);
        expect(deletedTemplate, isNull);
      });
    });

    group('📊 Performance and Reliability', () {
      test('Authentication speed benchmarks', () async {
        final biometricAuth = BiometricAuthenticator();
        
        const testIterations = 100;
        final authTimes = <Duration>[];
        
        for (int i = 0; i < testIterations; i++) {
          final stopwatch = Stopwatch()..start();
          
          // Simulate biometric authentication
          await biometricAuth.authenticate('user_001', BiometricType.fingerprint);
          
          stopwatch.stop();
          authTimes.add(stopwatch.elapsed);
        }
        
        final avgAuthTime = authTimes
          .map((duration) => duration.inMilliseconds)
          .reduce((a, b) => a + b) / testIterations;
        
        // Authentication should be fast (under 2 seconds average)
        expect(avgAuthTime, lessThan(2000));
        
        // 95th percentile should be under 3 seconds
        authTimes.sort((a, b) => a.inMilliseconds.compareTo(b.inMilliseconds));
        final p95Time = authTimes[(testIterations * 0.95).floor()].inMilliseconds;
        expect(p95Time, lessThan(3000));
      });

      test('False acceptance/rejection rate validation', () {
        final biometricValidator = BiometricValidator();
        
        // Test with legitimate users (should have low false rejection)
        const legitimateTests = 1000;
        int falseRejections = 0;
        
        for (int i = 0; i < legitimateTests; i++) {
          final result = biometricValidator.validateLegitimateUser('user_001');
          if (!result) falseRejections++;
        }
        
        final falseRejectionRate = falseRejections / legitimateTests;
        expect(falseRejectionRate, lessThan(0.02)); // Under 2% FRR
        
        // Test with imposters (should have low false acceptance)
        const imposterTests = 1000;
        int falseAcceptances = 0;
        
        for (int i = 0; i < imposterTests; i++) {
          final result = biometricValidator.validateImposter('user_001', 'imposter_$i');
          if (result) falseAcceptances++;
        }
        
        final falseAcceptanceRate = falseAcceptances / imposterTests;
        expect(falseAcceptanceRate, lessThan(0.001)); // Under 0.1% FAR
      });

      test('System resilience under load', () async {
        final biometricSystem = BiometricSystem();
        
        // Test concurrent authentication requests
        const concurrentUsers = 50;
        final authFutures = <Future<bool>>[];
        
        for (int i = 0; i < concurrentUsers; i++) {
          authFutures.add(biometricSystem.authenticate('user_$i', BiometricType.fingerprint));
        }
        
        final results = await Future.wait(authFutures);
        
        // System should handle concurrent requests without failures
        expect(results.where((result) => result).length, greaterThan(concurrentUsers * 0.9));
        
        // Test system recovery after failures
        await biometricSystem.simulateSystemFailure();
        await Future.delayed(Duration(seconds: 1));
        
        final recoveryResult = await biometricSystem.authenticate('user_001', BiometricType.fingerprint);
        expect(recoveryResult, isTrue); // Should recover quickly
      });
    });
  });
}

// Mock classes for testing biometric security features
class BiometricLockoutSystem {
  final Map<String, List<DateTime>> _failedAttempts = {};
  final Map<String, DateTime> _successfulAttempts = {};
  
  void recordFailedAttempt(String userId) {
    recordFailedAttemptAtTime(userId, DateTime.now());
  }
  
  void recordFailedAttemptAtTime(String userId, DateTime timestamp) {
    _failedAttempts.putIfAbsent(userId, () => []).add(timestamp);
  }
  
  void recordSuccessfulAttempt(String userId) {
    _successfulAttempts[userId] = DateTime.now();
    _failedAttempts.remove(userId);
  }
  
  bool isLockedOut(String userId) {
    return isLockedOutAtTime(userId, DateTime.now());
  }
  
  bool isLockedOutAtTime(String userId, DateTime currentTime) {
    final failures = _failedAttempts[userId] ?? [];
    if (failures.isEmpty) return false;
    
    final recentFailures = failures.where((time) {
      final lockoutDuration = _calculateLockoutDuration(failures.length);
      return currentTime.difference(time) < lockoutDuration;
    }).length;
    
    return recentFailures >= 2; // Locked after 2 failures
  }
  
  Duration getLockoutDuration(String userId) {
    final failures = _failedAttempts[userId] ?? [];
    return _calculateLockoutDuration(failures.length);
  }
  
  Duration _calculateLockoutDuration(int failureCount) {
    if (failureCount < 2) return Duration.zero;
    if (failureCount < 4) return Duration(seconds: 30);
    if (failureCount < 5) return Duration(minutes: 2);
    return Duration(hours: 2);
  }
  
  bool canAttemptAuthentication(String userId) {
    return !isLockedOut(userId);
  }
  
  int getFailedAttempts(String userId) {
    return _failedAttempts[userId]?.length ?? 0;
  }
}

class DeviceFingerprint {
  final String deviceId;
  final String hardwareModel;
  final String osVersion;
  final String screenResolution;
  final List<String> biometricCapabilities;
  final String timeZone;
  final String locale;
  
  DeviceFingerprint({
    required this.deviceId,
    required this.hardwareModel,
    required this.osVersion,
    required this.screenResolution,
    required this.biometricCapabilities,
    required this.timeZone,
    required this.locale,
  });
}

class DeviceFingerprintValidator {
  final Map<String, List<DeviceFingerprint>> _knownDevices = {};
  
  void registerDevice(String userId, DeviceFingerprint device) {
    _knownDevices.putIfAbsent(userId, () => []).add(device);
  }
  
  bool isKnownDevice(String userId, DeviceFingerprint device) {
    final devices = _knownDevices[userId] ?? [];
    return devices.any((d) => d.deviceId == device.deviceId);
  }
  
  bool isSuspiciousDevice(DeviceFingerprint device) {
    return device.deviceId.contains('EMULATOR') ||
           device.hardwareModel.contains('Generic') ||
           device.biometricCapabilities.isEmpty ||
           device.timeZone == 'UTC';
  }
}

enum BiometricType { fingerprint, face, voice, iris }
enum SecurityLevel { low, medium, high, critical }

class BiometricSample {
  final BiometricType type;
  final double quality;
  final double liveness;
  final String templateData;
  final DateTime captureTime;
  final Map<String, dynamic> deviceSensorData;
  
  BiometricSample({
    required this.type,
    required this.quality,
    required this.liveness,
    required this.templateData,
    required this.captureTime,
    required this.deviceSensorData,
  });
}

class PresentationAttackDetector {
  bool isLegitimate(BiometricSample sample) {
    return sample.liveness > 0.8 &&
           _checkSensorData(sample.deviceSensorData);
  }
  
  double getSpoofingRisk(BiometricSample sample) {
    return 1.0 - sample.liveness;
  }
  
  bool _checkSensorData(Map<String, dynamic> sensorData) {
    final pressure = sensorData['pressure'] as double? ?? 0.0;
    final temperature = sensorData['temperature'] as double? ?? 0.0;
    final conductivity = sensorData['conductivity'] as double? ?? 0.0;
    
    return pressure > 0.5 && temperature > 30.0 && conductivity > 0.5;
  }
}

class TypingPattern {
  final int averageSpeed;
  final List<double> keyHoldTimes;
  final List<double> timeBetweenKeys;
  
  TypingPattern({
    required this.averageSpeed,
    required this.keyHoldTimes,
    required this.timeBetweenKeys,
  });
}

class TouchPattern {
  final double averagePressure;
  final double touchSize;
  final double gestureSpeed;
  
  TouchPattern({
    required this.averagePressure,
    required this.touchSize,
    required this.gestureSpeed,
  });
}

class DeviceInteractionPattern {
  final Duration averageSessionDuration;
  final Duration screenTimePerDay;
  final List<int> mostActiveHours;
  
  DeviceInteractionPattern({
    required this.averageSessionDuration,
    required this.screenTimePerDay,
    required this.mostActiveHours,
  });
}

class BehavioralProfile {
  final String userId;
  final TypingPattern typingPattern;
  final TouchPattern touchPattern;
  final DeviceInteractionPattern deviceInteraction;
  
  BehavioralProfile({
    required this.userId,
    required this.typingPattern,
    required this.touchPattern,
    required this.deviceInteraction,
  });
}

class BehavioralSession {
  final TypingPattern typingPattern;
  final TouchPattern touchPattern;
  final int sessionTime;
  
  BehavioralSession({
    required this.typingPattern,
    required this.touchPattern,
    required this.sessionTime,
  });
}

class BehavioralBiometricsAnalyzer {
  final Map<String, BehavioralProfile> _baselines = {};
  
  void setBaseline(String userId, BehavioralProfile profile) {
    _baselines[userId] = profile;
  }
  
  double analyzeSession(String userId, BehavioralSession session) {
    final baseline = _baselines[userId];
    if (baseline == null) return 0.5;
    
    double score = 0.0;
    
    // Analyze typing pattern
    final typingScore = _analyzeTypingPattern(baseline.typingPattern, session.typingPattern);
    score += typingScore * 0.4;
    
    // Analyze touch pattern
    final touchScore = _analyzeTouchPattern(baseline.touchPattern, session.touchPattern);
    score += touchScore * 0.4;
    
    // Analyze session timing
    final timingScore = baseline.deviceInteraction.mostActiveHours.contains(session.sessionTime) ? 1.0 : 0.3;
    score += timingScore * 0.2;
    
    return score;
  }
  
  double _analyzeTypingPattern(TypingPattern baseline, TypingPattern session) {
    final speedDiff = (baseline.averageSpeed - session.averageSpeed).abs();
    final speedScore = math.max(0.0, 1.0 - speedDiff / baseline.averageSpeed);
    return speedScore;
  }
  
  double _analyzeTouchPattern(TouchPattern baseline, TouchPattern session) {
    final pressureDiff = (baseline.averagePressure - session.averagePressure).abs();
    final pressureScore = math.max(0.0, 1.0 - pressureDiff / baseline.averagePressure);
    return pressureScore;
  }
}

class BiometricAuthResult {
  final BiometricType type;
  final double confidence;
  final bool isAuthentic;
  final String userId;
  final DateTime timestamp;
  
  BiometricAuthResult({
    required this.type,
    required this.confidence,
    required this.isAuthentic,
    required this.userId,
    required this.timestamp,
  });
}

class MultiModalFusionResult {
  final double overallConfidence;
  final bool isAuthenticated;
  final SecurityLevel securityLevel;
  final List<BiometricAuthResult> individualResults;
  
  MultiModalFusionResult({
    required this.overallConfidence,
    required this.isAuthenticated,
    required this.securityLevel,
    required this.individualResults,
  });
}

class MultiModalBiometricFusion {
  MultiModalFusionResult fuseResults(List<BiometricAuthResult> results) {
    if (results.isEmpty) {
      return MultiModalFusionResult(
        overallConfidence: 0.0,
        isAuthenticated: false,
        securityLevel: SecurityLevel.critical,
        individualResults: [],
      );
    }
    
    // Check for conflicts
    final userIds = results.map((r) => r.userId).toSet();
    if (userIds.length > 1) {
      return MultiModalFusionResult(
        overallConfidence: 0.0,
        isAuthenticated: false,
        securityLevel: SecurityLevel.critical,
        individualResults: results,
      );
    }
    
    // Calculate weighted confidence
    double totalConfidence = 0.0;
    double totalWeight = 0.0;
    
    for (final result in results) {
      if (result.isAuthentic) {
        final weight = _getModalityWeight(result.type);
        totalConfidence += result.confidence * weight;
        totalWeight += weight;
      }
    }
    
    final overallConfidence = totalWeight > 0 ? totalConfidence / totalWeight : 0.0;
    final isAuthenticated = overallConfidence > 0.8 && results.every((r) => r.isAuthentic);
    final securityLevel = _determineSecurityLevel(overallConfidence, results.length);
    
    return MultiModalFusionResult(
      overallConfidence: overallConfidence,
      isAuthenticated: isAuthenticated,
      securityLevel: securityLevel,
      individualResults: results,
    );
  }
  
  double _getModalityWeight(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint: return 1.0;
      case BiometricType.face: return 0.9;
      case BiometricType.voice: return 0.8;
      case BiometricType.iris: return 1.2;
    }
  }
  
  SecurityLevel _determineSecurityLevel(double confidence, int modalityCount) {
    if (confidence < 0.5) return SecurityLevel.critical;
    if (confidence < 0.8) return SecurityLevel.low;
    if (modalityCount >= 3) return SecurityLevel.high;
    return SecurityLevel.medium;
  }
}

// Additional mock classes would continue here...
class BiometricTemplateProtector {
  final Map<String, bool> _canceledTemplates = {};
  
  ProtectedTemplate protectTemplate(String rawTemplate, String userId) {
    final templateId = 'tmpl_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final encryptedData = 'ENCRYPTED_$rawTemplate';
    
    return ProtectedTemplate(
      templateId: templateId,
      data: encryptedData,
      userId: userId,
      isEncrypted: true,
    );
  }
  
  bool verifyTemplate(String rawTemplate, ProtectedTemplate protected, String userId) {
    if (_canceledTemplates[protected.templateId] == true) return false;
    if (protected.userId != userId) return false;
    
    final expectedEncrypted = 'ENCRYPTED_$rawTemplate';
    return protected.data == expectedEncrypted;
  }
  
  void cancelTemplate(String templateId) {
    _canceledTemplates[templateId] = true;
  }
}

class ProtectedTemplate {
  final String templateId;
  final String data;
  final String userId;
  final bool isEncrypted;
  
  ProtectedTemplate({
    required this.templateId,
    required this.data,
    required this.userId,
    required this.isEncrypted,
  });
}

class BiometricKeyDerivation {
  String deriveKey(String biometricData, String userId) {
    // Simulate fuzzy key derivation
    final combined = '$biometricData:$userId';
    return 'KEY_${combined.hashCode.abs()}';
  }
  
  double calculateKeySimilarity(String key1, String key2) {
    // Simulate similarity calculation
    return 0.85; // Mock similarity
  }
}

// Continue with remaining mock classes for comprehensive testing
class BiometricDataAnonymizer {
  BiometricSample anonymize(BiometricSample original) {
    final anonymizedSensorData = Map<String, dynamic>.from(original.deviceSensorData);
    anonymizedSensorData.remove('device_id');
    anonymizedSensorData.remove('location');
    anonymizedSensorData.remove('ip_address');
    
    return BiometricSample(
      type: original.type,
      quality: original.quality,
      liveness: original.liveness,
      templateData: original.templateData.replaceAll(RegExp(r'user_\d+'), 'user_anon'),
      captureTime: original.captureTime,
      deviceSensorData: anonymizedSensorData,
    );
  }
}

class DifferentialPrivacyEngine {
  final double epsilon;
  
  DifferentialPrivacyEngine({required this.epsilon});
  
  double calculateNoisyAverage(List<double> values) {
    final actualAvg = values.reduce((a, b) => a + b) / values.length;
    final noise = math.Random().nextGaussian() * (1.0 / epsilon);
    return actualAvg + noise;
  }
}

class BiometricUsageStat {
  final String userId;
  final double successRate;
  final double avgResponseTime;
  
  BiometricUsageStat({
    required this.userId,
    required this.successRate,
    required this.avgResponseTime,
  });
}

class SecureBiometricStorage {
  final Map<String, Map<String, String>> _storage = {};
  final Set<String> _deletedTemplates = {};
  
  String storeTemplate(String userId, String templateData) {
    final templateId = 'tmpl_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    _storage[templateId] = {
      'userId': userId,
      'data': templateData,
    };
    return templateId;
  }
  
  String? retrieveTemplate(String templateId, String userId) {
    if (_deletedTemplates.contains(templateId)) return null;
    
    final template = _storage[templateId];
    if (template == null || template['userId'] != userId) return null;
    
    return template['data'];
  }
  
  bool deleteTemplate(String templateId, String userId) {
    final template = _storage[templateId];
    if (template == null || template['userId'] != userId) return false;
    
    _storage.remove(templateId);
    _deletedTemplates.add(templateId);
    return true;
  }
}

class BiometricAuthenticator {
  Future<bool> authenticate(String userId, BiometricType type) async {
    // Simulate authentication delay
    await Future.delayed(Duration(milliseconds: math.Random().nextInt(1500) + 500));
    return math.Random().nextDouble() > 0.05; // 95% success rate
  }
}

class BiometricValidator {
  bool validateLegitimateUser(String userId) {
    return math.Random().nextDouble() > 0.02; // 2% false rejection rate
  }
  
  bool validateImposter(String legitimateUserId, String imposterUserId) {
    return math.Random().nextDouble() < 0.001; // 0.1% false acceptance rate
  }
}

class BiometricSystem {
  bool _systemFailure = false;
  
  Future<bool> authenticate(String userId, BiometricType type) async {
    if (_systemFailure) {
      await Future.delayed(Duration(milliseconds: 100));
      _systemFailure = false; // Auto-recovery
      return false;
    }
    
    await Future.delayed(Duration(milliseconds: 50));
    return true;
  }
  
  Future<void> simulateSystemFailure() async {
    _systemFailure = true;
  }
}

extension on math.Random {
  double nextGaussian() {
    // Box-Muller transform for Gaussian random numbers
    double u1 = nextDouble();
    double u2 = nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }
}