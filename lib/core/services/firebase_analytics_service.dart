import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firebase Analytics Service for SecuryFlex
/// 
/// Provides GDPR-compliant analytics tracking integrated with existing analytics system.
/// Tracks user interactions, performance metrics, and business events while respecting privacy.
class FirebaseAnalyticsService {
  static FirebaseAnalyticsService? _instance;
  static FirebaseAnalyticsService get instance {
    _instance ??= FirebaseAnalyticsService._();
    return _instance!;
  }

  FirebaseAnalyticsService._();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _isInitialized = false;
  bool _analyticsEnabled = true;

  /// Initialize Firebase Analytics
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      
      // Set analytics collection enabled based on privacy settings
      await _analytics!.setAnalyticsCollectionEnabled(_analyticsEnabled);
      
      // Set default user properties
      await _setDefaultUserProperties();
      
      _isInitialized = true;
      debugPrint('✅ Firebase Analytics initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Firebase Analytics: $e');
      _isInitialized = false;
    }
  }

  /// Get analytics observer for navigation tracking
  FirebaseAnalyticsObserver? get observer => _observer;

  /// Check if analytics is initialized
  bool get isInitialized => _isInitialized;

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    if (!_isInitialized || _analytics == null) return;
    
    try {
      await _analytics!.setUserId(id: userId);
      debugPrint('📊 Analytics user ID set: ${userId != null ? 'USER_ID_SET' : 'USER_ID_CLEARED'}');
    } catch (e) {
      debugPrint('❌ Failed to set analytics user ID: $e');
    }
  }

  /// Set user properties
  Future<void> setUserProperties(Map<String, String?> properties) async {
    if (!_isInitialized || _analytics == null) return;
    
    try {
      for (final entry in properties.entries) {
        await _analytics!.setUserProperty(
          name: entry.key,
          value: entry.value,
        );
      }
      debugPrint('📊 Analytics user properties updated: ${properties.keys.join(', ')}');
    } catch (e) {
      debugPrint('❌ Failed to set user properties: $e');
    }
  }

  /// Track screen view
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null || !_analyticsEnabled) return;
    
    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
        parameters: parameters,
      );
      debugPrint('📱 Screen view tracked: $screenName');
    } catch (e) {
      debugPrint('❌ Failed to track screen view: $e');
    }
  }

  /// Track custom event
  Future<void> trackEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null || !_analyticsEnabled) return;
    
    try {
      // Sanitize event name for Firebase (no spaces, special characters)
      final sanitizedEventName = _sanitizeEventName(eventName);
      
      // Sanitize parameters to ensure Firebase compliance
      final sanitizedParameters = _sanitizeParameters(parameters);
      
      await _analytics!.logEvent(
        name: sanitizedEventName,
        parameters: sanitizedParameters,
      );
      debugPrint('📊 Event tracked: $sanitizedEventName');
    } catch (e) {
      debugPrint('❌ Failed to track event: $e');
    }
  }

  /// Track security guard job application
  Future<void> trackJobApplication({
    required String jobId,
    required String jobTitle,
    required String companyId,
    required String location,
    String? specialization,
  }) async {
    await trackEvent(
      eventName: 'job_application',
      parameters: {
        'job_id': jobId,
        'job_title': jobTitle,
        'company_id': companyId,
        'location': location,
        if (specialization != null) 'specialization': specialization,
        'user_type': 'security_guard',
      },
    );
  }

  /// Track job posting by company
  Future<void> trackJobPosting({
    required String jobId,
    required String jobTitle,
    required String location,
    required double hourlyRate,
    String? specialization,
  }) async {
    await trackEvent(
      eventName: 'job_posted',
      parameters: {
        'job_id': jobId,
        'job_title': jobTitle,
        'location': location,
        'hourly_rate': hourlyRate,
        if (specialization != null) 'specialization': specialization,
        'user_type': 'company',
      },
    );
  }

  /// Track profile completion milestone
  Future<void> trackProfileMilestone({
    required String milestoneType,
    required int completionPercentage,
    String? certificateType,
  }) async {
    await trackEvent(
      eventName: 'profile_milestone',
      parameters: {
        'milestone_type': milestoneType,
        'completion_percentage': completionPercentage,
        if (certificateType != null) 'certificate_type': certificateType,
        'user_type': 'security_guard',
      },
    );
  }

  /// Track shift completion
  Future<void> trackShiftCompleted({
    required String shiftId,
    required String jobType,
    required double hoursWorked,
    required double earnings,
    double? rating,
  }) async {
    await trackEvent(
      eventName: 'shift_completed',
      parameters: {
        'shift_id': shiftId,
        'job_type': jobType,
        'hours_worked': hoursWorked,
        'earnings': earnings,
        if (rating != null) 'rating': rating,
        'user_type': 'security_guard',
      },
    );
  }

  /// Track payment transaction
  Future<void> trackPayment({
    required String transactionId,
    required String paymentMethod,
    required double amount,
    required String currency,
    String? transactionType,
  }) async {
    await trackEvent(
      eventName: 'payment_completed',
      parameters: {
        'transaction_id': transactionId,
        'payment_method': paymentMethod,
        'value': amount,
        'currency': currency,
        if (transactionType != null) 'transaction_type': transactionType,
      },
    );
  }

  /// Track feature usage
  Future<void> trackFeatureUsage({
    required String featureName,
    String? featureCategory,
    Map<String, Object>? additionalData,
  }) async {
    await trackEvent(
      eventName: 'feature_used',
      parameters: {
        'feature_name': featureName,
        if (featureCategory != null) 'feature_category': featureCategory,
        ...?additionalData,
      },
    );
  }

  /// Track error or exception
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    String? context,
  }) async {
    await trackEvent(
      eventName: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage.substring(0, errorMessage.length.clamp(0, 100)), // Limit length
        if (context != null) 'context': context,
        'fatal': false,
      },
    );
  }

  /// Enable or disable analytics collection
  Future<void> setAnalyticsEnabled(bool enabled) async {
    _analyticsEnabled = enabled;
    
    if (_analytics != null) {
      try {
        await _analytics!.setAnalyticsCollectionEnabled(enabled);
        debugPrint('📊 Analytics collection ${enabled ? 'enabled' : 'disabled'}');
      } catch (e) {
        debugPrint('❌ Failed to set analytics collection: $e');
      }
    }
  }

  /// Get analytics status for privacy settings
  bool get isAnalyticsEnabled => _analyticsEnabled;

  /// Set default user properties
  Future<void> _setDefaultUserProperties() async {
    if (!_isInitialized || _analytics == null) return;
    
    try {
      await setUserProperties({
        'app_version': '1.0.0', // Should be dynamic in production
        'platform': defaultTargetPlatform.name,
        'app_name': 'SecuryFlex',
        'market': 'netherlands',
        'language': 'dutch',
      });
    } catch (e) {
      debugPrint('❌ Failed to set default user properties: $e');
    }
  }

  /// Sanitize event names to comply with Firebase Analytics requirements
  String _sanitizeEventName(String eventName) {
    return eventName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .substring(0, eventName.length.clamp(0, 40)); // Max 40 chars
  }

  /// Sanitize parameters to comply with Firebase requirements
  Map<String, Object>? _sanitizeParameters(Map<String, Object>? parameters) {
    if (parameters == null) return null;
    
    final sanitized = <String, Object>{};
    
    for (final entry in parameters.entries) {
      // Sanitize parameter names
      final sanitizedKey = entry.key
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '')
          .substring(0, entry.key.length.clamp(0, 40));
      
      // Handle parameter values
      Object sanitizedValue;
      if (entry.value is String) {
        sanitizedValue = (entry.value as String).substring(0, (entry.value as String).length.clamp(0, 100));
      } else if (entry.value is num) {
        sanitizedValue = entry.value;
      } else if (entry.value is bool) {
        sanitizedValue = entry.value;
      } else {
        sanitizedValue = entry.value.toString().substring(0, entry.value.toString().length.clamp(0, 100));
      }
      
      sanitized[sanitizedKey] = sanitizedValue;
    }
    
    return sanitized;
  }

  /// Get analytics configuration for debugging
  Map<String, dynamic> getAnalyticsConfig() {
    return {
      'initialized': _isInitialized,
      'enabled': _analyticsEnabled,
      'firebase_available': _analytics != null,
      'observer_available': _observer != null,
    };
  }
}