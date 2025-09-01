import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Feedback types for guard experience
enum FeedbackType {
  bug,
  feature,
  improvement,
  compliment,
  complaint,
  general,
}

/// Feedback priority levels
enum FeedbackPriority {
  low,
  medium,
  high,
  critical,
}

/// Guard feedback system for collecting user feedback and suggestions
/// Helps improve the beveiliger dashboard experience
class GuardFeedbackSystem {
  static GuardFeedbackSystem? _instance;
  static GuardFeedbackSystem get instance {
    _instance ??= GuardFeedbackSystem._();
    return _instance!;
  }
  
  GuardFeedbackSystem._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Submit feedback from guard
  Future<bool> submitFeedback({
    required String userId,
    required FeedbackType type,
    required String title,
    required String description,
    FeedbackPriority priority = FeedbackPriority.medium,
    String? screenLocation,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final feedbackData = {
        'userId': userId,
        'type': type.name,
        'priority': priority.name,
        'title': title,
        'description': description,
        'screenLocation': screenLocation,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'open',
        'deviceInfo': await _getDeviceInfo(),
        'appVersion': await _getAppVersion(),
        'additionalData': additionalData ?? {},
        'resolved': false,
        'adminResponse': null,
        'resolvedAt': null,
      };
      
      await _firestore
          .collection('guard_feedback')
          .add(feedbackData);
      
      // Log feedback submission for analytics
      await _logFeedbackEvent(
        action: 'feedback_submitted',
        userId: userId,
        feedbackType: type.name,
        metadata: {
          'title': title,
          'priority': priority.name,
          'screenLocation': screenLocation,
        },
      );
      
      debugPrint('GuardFeedbackSystem: Feedback submitted successfully');
      return true;
    } catch (e) {
      debugPrint('GuardFeedbackSystem: Failed to submit feedback: $e');
      return false;
    }
  }
  
  /// Get feedback history for user
  Future<List<Map<String, dynamic>>> getFeedbackHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('guard_feedback')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('GuardFeedbackSystem: Failed to get feedback history: $e');
      return [];
    }
  }
  
  /// Submit quick rating (1-5 stars)
  Future<bool> submitQuickRating({
    required String userId,
    required int rating,
    required String feature,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) {
      debugPrint('GuardFeedbackSystem: Invalid rating value: $rating');
      return false;
    }
    
    try {
      final ratingData = {
        'userId': userId,
        'rating': rating,
        'feature': feature,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'quick_rating',
      };
      
      await _firestore
          .collection('guard_ratings')
          .add(ratingData);
      
      // Log rating for analytics
      await _logFeedbackEvent(
        action: 'quick_rating_submitted',
        userId: userId,
        metadata: {
          'rating': rating,
          'feature': feature,
          'hasComment': comment != null,
        },
      );
      
      debugPrint('GuardFeedbackSystem: Quick rating submitted successfully');
      return true;
    } catch (e) {
      debugPrint('GuardFeedbackSystem: Failed to submit quick rating: $e');
      return false;
    }
  }
  
  /// Report bug with automatic context
  Future<bool> reportBug({
    required String userId,
    required String bugDescription,
    required String stepsToReproduce,
    String? expectedBehavior,
    String? actualBehavior,
    String? screenLocation,
    List<String>? screenshots,
  }) async {
    try {
      final bugData = {
        'userId': userId,
        'type': 'bug_report',
        'description': bugDescription,
        'stepsToReproduce': stepsToReproduce,
        'expectedBehavior': expectedBehavior,
        'actualBehavior': actualBehavior,
        'screenLocation': screenLocation,
        'screenshots': screenshots ?? [],
        'timestamp': FieldValue.serverTimestamp(),
        'priority': FeedbackPriority.high.name,
        'status': 'open',
        'deviceInfo': await _getDeviceInfo(),
        'appVersion': await _getAppVersion(),
        'resolved': false,
      };
      
      await _firestore
          .collection('guard_bug_reports')
          .add(bugData);
      
      // Also create general feedback entry
      await submitFeedback(
        userId: userId,
        type: FeedbackType.bug,
        title: 'Bug Report: ${bugDescription.substring(0, 50)}...',
        description: bugDescription,
        priority: FeedbackPriority.high,
        screenLocation: screenLocation,
        additionalData: {
          'stepsToReproduce': stepsToReproduce,
          'expectedBehavior': expectedBehavior,
          'actualBehavior': actualBehavior,
        },
      );
      
      debugPrint('GuardFeedbackSystem: Bug report submitted successfully');
      return true;
    } catch (e) {
      debugPrint('GuardFeedbackSystem: Failed to submit bug report: $e');
      return false;
    }
  }
  
  /// Request new feature
  Future<bool> requestFeature({
    required String userId,
    required String featureTitle,
    required String featureDescription,
    required String businessJustification,
    FeedbackPriority priority = FeedbackPriority.medium,
  }) async {
    try {
      await submitFeedback(
        userId: userId,
        type: FeedbackType.feature,
        title: featureTitle,
        description: featureDescription,
        priority: priority,
        additionalData: {
          'businessJustification': businessJustification,
          'featureRequest': true,
        },
      );
      
      debugPrint('GuardFeedbackSystem: Feature request submitted successfully');
      return true;
    } catch (e) {
      debugPrint('GuardFeedbackSystem: Failed to submit feature request: $e');
      return false;
    }
  }
  
  /// Submit NPS (Net Promoter Score) response
  Future<bool> submitNPS({
    required String userId,
    required int score,
    String? reason,
  }) async {
    if (score < 0 || score > 10) {
      debugPrint('GuardFeedbackSystem: Invalid NPS score: $score');
      return false;
    }
    
    try {
      final npsData = {
        'userId': userId,
        'score': score,
        'reason': reason,
        'category': _getNPSCategory(score),
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      await _firestore
          .collection('guard_nps')
          .add(npsData);
      
      await _logFeedbackEvent(
        action: 'nps_submitted',
        userId: userId,
        metadata: {
          'score': score,
          'category': _getNPSCategory(score),
          'hasReason': reason != null,
        },
      );
      
      debugPrint('GuardFeedbackSystem: NPS submitted successfully');
      return true;
    } catch (e) {
      debugPrint('GuardFeedbackSystem: Failed to submit NPS: $e');
      return false;
    }
  }
  
  /// Get device information for debugging
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Get app version
  Future<String> _getAppVersion() async {
    // In a real app, this would get the actual version
    return '1.0.0';
  }
  
  /// Categorize NPS score
  String _getNPSCategory(int score) {
    if (score >= 9) return 'promoter';
    if (score >= 7) return 'passive';
    return 'detractor';
  }
  
  /// Log feedback events for analytics
  Future<void> _logFeedbackEvent({
    required String action,
    required String userId,
    String? feedbackType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final eventData = {
        'action': action,
        'userId': userId,
        'feedbackType': feedbackType,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
        'source': 'guard_feedback_system',
      };
      
      await _firestore
          .collection('feedback_analytics')
          .add(eventData);
    } catch (e) {
      debugPrint('GuardFeedbackSystem: Failed to log feedback event: $e');
    }
  }
  
  /// Get feedback type display name
  static String getFeedbackTypeDisplayName(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return 'Bug Report';
      case FeedbackType.feature:
        return 'Feature Verzoek';
      case FeedbackType.improvement:
        return 'Verbetering';
      case FeedbackType.compliment:
        return 'Compliment';
      case FeedbackType.complaint:
        return 'Klacht';
      case FeedbackType.general:
        return 'Algemeen';
    }
  }
  
  /// Get priority display name
  static String getPriorityDisplayName(FeedbackPriority priority) {
    switch (priority) {
      case FeedbackPriority.low:
        return 'Laag';
      case FeedbackPriority.medium:
        return 'Gemiddeld';
      case FeedbackPriority.high:
        return 'Hoog';
      case FeedbackPriority.critical:
        return 'Kritiek';
    }
  }
}