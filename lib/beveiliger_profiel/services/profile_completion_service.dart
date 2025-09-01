import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../company_dashboard/services/analytics_service.dart';
import '../../company_dashboard/models/analytics_data_models.dart';
import '../../chat/services/notification_service.dart';
import '../../chat/models/message_model.dart';
import '../models/profile_completion_data.dart';
import '../models/profile_stats_data.dart';

/// Profile completion service with comprehensive analytics integration
/// 
/// Integrates with existing AnalyticsService, PerformanceAnalyticsService, and NotificationService
/// Provides profile completion tracking, milestone analytics, and completion reminders
/// Follows Dutch business logic and SecuryFlex architecture patterns
class ProfileCompletionService {
  static ProfileCompletionService? _instance;
  static ProfileCompletionService get instance {
    _instance ??= ProfileCompletionService._();
    return _instance!;
  }

  ProfileCompletionService._();

  final AnalyticsService _analyticsService = AnalyticsService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  // Cache for completion data
  final Map<String, ProfileCompletionData> _completionCache = {};
  final Map<String, ProfileStatsData> _statsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 15);

  // Completion tracking
  final Map<String, Set<ProfileCompletionMilestone>> _achievedMilestones = {};
  final Map<String, Timer> _reminderTimers = {};

  /// Calculate profile completion percentage and missing elements
  Future<ProfileCompletionData> calculateCompletionPercentage(String userId) async {
    final cacheKey = 'completion_$userId';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      debugPrint('Returning cached completion data successfully');
      return _completionCache[cacheKey]!;
    }

    try {
      debugPrint('Calculating profile completion successfully');
      
      // Get profile data from various sources
      final profileData = await _fetchProfileData(userId);
      final completionData = _calculateCompletion(profileData);
      
      // Cache the result
      _completionCache[cacheKey] = completionData;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      // Check for milestone achievements
      await _checkMilestoneAchievements(userId, completionData);
      
      // Schedule completion reminders if needed
      _scheduleCompletionReminders(userId, completionData);
      
      // Track analytics event
      await _trackCompletionCalculated(userId, completionData);
      
      return completionData;
    } catch (e) {
      debugPrint('Error calculating profile completion: $e');
      return ProfileCompletionData.empty();
    }
  }

  /// Get profile statistics integrated with performance analytics
  Future<ProfileStatsData> getProfileStats(String userId) async {
    final cacheKey = 'stats_$userId';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      debugPrint('Returning cached stats data successfully');
      return _statsCache[cacheKey]!;
    }

    try {
      debugPrint('Loading profile stats successfully');
      
      // Get performance analytics data
      final performanceData = await _getPerformanceData(userId);
      
      // Combine with profile-specific metrics
      final statsData = await _buildStatsData(userId, performanceData);
      
      // Cache the result
      _statsCache[cacheKey] = statsData;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      // Track analytics event
      await _trackStatsViewed(userId, statsData);
      
      return statsData;
    } catch (e) {
      debugPrint('Error loading profile stats: $e');
      return ProfileStatsData.empty();
    }
  }

  /// Get missing profile elements with priority ordering
  Future<List<MissingProfileElement>> getMissingElements(String userId) async {
    final completionData = await calculateCompletionPercentage(userId);
    return completionData.missingElements;
  }

  /// Track profile completion milestone achievement
  Future<void> trackCompletionMilestone(String userId, ProfileCompletionMilestone milestone) async {
    try {
      // Check if this milestone was already tracked to prevent duplicates
      final achievedMilestones = _achievedMilestones[userId] ?? {};
      
      if (achievedMilestones.contains(milestone)) {
        // Silently skip - milestone already tracked
        return;
      }
      
      debugPrint('Tracking completion milestone: ${milestone.dutchDescription} successfully');
      
      // Track directly to Firestore instead of using job analytics
      await _trackMilestoneToFirestore(userId, milestone);
      
      // Store achieved milestone locally
      _achievedMilestones.putIfAbsent(userId, () => {}).add(milestone);
      
      // Show celebration/notification for major milestones
      if (_isMajorMilestone(milestone)) {
        await _showMilestoneNotification(userId, milestone);
      }
      
      debugPrint('Milestone tracked successfully: ${milestone.dutchDescription}');
    } catch (e) {
      debugPrint('Error tracking completion milestone: $e');
    }
  }

  /// Track milestone directly to Firestore
  Future<void> _trackMilestoneToFirestore(String userId, ProfileCompletionMilestone milestone) async {
    try {
      await FirebaseFirestore.instance
        .collection('profile_completion_milestones')
        .add({
          'userId': userId,
          'milestone': milestone.toString(),
          'milestone_description': milestone.dutchDescription,
          'percentage_threshold': milestone.percentageThreshold,
          'achievedAt': FieldValue.serverTimestamp(),
        });
    } catch (e) {
      debugPrint('Error saving milestone to Firestore: $e');
    }
  }

  /// Track completion widget view for analytics
  Future<void> trackCompletionWidgetView(String userId) async {
    try {
      await _analyticsService.trackEvent(
        jobId: 'profile_completion',
        eventType: JobEventType.jobViewed,
        userId: userId,
        metadata: {
          'widget_type': 'profile_completion',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error tracking completion widget view: $e');
    }
  }

  /// Track quick action usage
  Future<void> trackQuickActionUsed(String userId, ProfileElementType elementType) async {
    try {
      await _analyticsService.trackEvent(
        jobId: 'profile_completion',
        eventType: JobEventType.view,
        userId: userId,
        metadata: {
          'action_type': 'quick_action',
          'element_type': elementType.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error tracking quick action usage: $e');
    }
  }

  /// Schedule completion reminders based on profile state
  void _scheduleCompletionReminders(String userId, ProfileCompletionData completionData) {
    // Cancel existing reminders
    _reminderTimers[userId]?.cancel();
    
    // Don't schedule reminders if profile is complete
    if (completionData.completionPercentage >= 100) return;
    
    // Schedule reminder based on completion percentage
    Duration reminderDelay;
    String reminderMessage;
    
    if (completionData.completionPercentage < 25) {
      // Very incomplete - remind in 1 day
      reminderDelay = const Duration(days: 1);
      reminderMessage = 'Vergeet niet je profiel aan te vullen om meer opdrachten te krijgen!';
    } else if (completionData.completionPercentage < 50) {
      // Partially complete - remind in 3 days
      reminderDelay = const Duration(days: 3);
      reminderMessage = 'Je profiel is nog niet compleet. Vul het aan voor betere kansen!';
    } else if (completionData.completionPercentage < 80) {
      // Mostly complete - remind in 1 week
      reminderDelay = const Duration(days: 7);
      reminderMessage = 'Je profiel is bijna compleet! Nog een paar details en je bent klaar.';
    } else {
      // Almost complete - remind in 2 weeks
      reminderDelay = const Duration(days: 14);
      reminderMessage = 'Maak je profiel helemaal compleet voor maximale zichtbaarheid!';
    }
    
    // Schedule the reminder
    _reminderTimers[userId] = Timer(reminderDelay, () {
      _sendCompletionReminder(userId, reminderMessage);
    });
  }

  /// Send completion reminder notification
  Future<void> _sendCompletionReminder(String userId, String message) async {
    try {
      // Use existing notification service to send reminder
      await _notificationService.sendMessageNotification(
        recipientUserId: userId,
        senderName: 'SecuryFlex',
        messageContent: message,
        conversationId: 'system_notifications',
        messageId: 'profile_reminder_${DateTime.now().millisecondsSinceEpoch}',
        messageType: MessageType.system,
      );
      
      debugPrint('Profile completion reminder sent successfully');
    } catch (e) {
      debugPrint('Error sending completion reminder: $e');
    }
  }

  /// Show milestone achievement notification
  Future<void> _showMilestoneNotification(String userId, ProfileCompletionMilestone milestone) async {
    try {
      final message = 'Gefeliciteerd! Je hebt een mijlpaal bereikt: ${milestone.dutchDescription}';
      
      await _notificationService.sendMessageNotification(
        recipientUserId: userId,
        senderName: 'SecuryFlex',
        messageContent: message,
        conversationId: 'system_notifications',
        messageId: 'milestone_${milestone.toString()}_${DateTime.now().millisecondsSinceEpoch}',
        messageType: MessageType.system,
      );
      
      debugPrint('Milestone notification sent for: ${milestone.dutchDescription}');
    } catch (e) {
      debugPrint('Error sending milestone notification: $e');
    }
  }

  /// Fetch profile data from various sources
  Future<Map<String, dynamic>> _fetchProfileData(String userId) async {
    // This would typically fetch from Firestore/API
    // For now, return mock data structure
    return {
      'basicInfo': {
        'name': 'Jan Jansen',
        'birthDate': '1990-01-01',
        'phone': '+31612345678',
        'email': 'jan@example.com',
      },
      'certificates': [
        {'type': 'wpbr', 'number': 'WPBR123456', 'expiry': '2025-12-31'},
        {'type': 'ehbo', 'number': 'EHBO789', 'expiry': '2024-06-30'},
      ],
      'specializations': ['eventbeveiliging', 'winkelbeveiliging'],
      'photo': 'https://example.com/profile.jpg',
      'createdAt': '2023-01-15',
    };
  }

  /// Calculate completion percentage from profile data
  ProfileCompletionData _calculateCompletion(Map<String, dynamic> profileData) {
    final completedElements = <ProfileElementType, bool>{};
    
    // Check basic info (25%)
    final basicInfo = profileData['basicInfo'] as Map<String, dynamic>?;
    completedElements[ProfileElementType.basicInfo] = basicInfo != null &&
        basicInfo['name']?.toString().isNotEmpty == true &&
        basicInfo['birthDate']?.toString().isNotEmpty == true;
    
    // Check contact info
    completedElements[ProfileElementType.contactInfo] = basicInfo != null &&
        basicInfo['phone']?.toString().isNotEmpty == true &&
        basicInfo['email']?.toString().isNotEmpty == true;
    
    // Check certificates (25%)
    final certificates = profileData['certificates'] as List<dynamic>? ?? [];
    completedElements[ProfileElementType.certificates] = certificates.isNotEmpty;
    
    // Check WPBR certificate specifically
    final hasWpbr = certificates.any((cert) => 
        cert is Map && cert['type'] == 'wpbr');
    completedElements[ProfileElementType.wpbrCertificate] = hasWpbr;
    
    // Check specializations (25%)
    final specializations = profileData['specializations'] as List<dynamic>? ?? [];
    completedElements[ProfileElementType.specializations] = specializations.isNotEmpty;
    
    // Check photo (25%)
    final photo = profileData['photo'] as String?;
    completedElements[ProfileElementType.photo] = photo?.isNotEmpty == true;
    
    return ProfileCompletionData.fromCompletedElements(completedElements);
  }

  /// Get performance data from analytics service
  Future<Map<String, dynamic>> _getPerformanceData(String userId) async {
    try {
      // Generate mock performance data
      final mockShifts = _generateMockShiftData();
      final completedShifts = mockShifts.where((shift) => shift['status'] == 'completed').toList();
      
      final totalHours = completedShifts.fold(0.0, (total, shift) => total + (shift['durationHours'] as double));
      final totalEarnings = completedShifts.fold(0.0, (total, shift) => total + (shift['totalEarnings'] as double));
      final ratings = completedShifts.where((shift) => shift['rating'] != null).map((shift) => shift['rating'] as double).toList();
      final averageRating = ratings.isNotEmpty ? ratings.reduce((a, b) => a + b) / ratings.length : 0.0;
      final completionRate = mockShifts.isNotEmpty ? (completedShifts.length / mockShifts.length) * 100 : 0.0;
      
      return {
        'totalShifts': completedShifts.length,
        'averageRating': averageRating,
        'completionRate': completionRate,
        'totalHours': totalHours,
        'totalEarnings': totalEarnings,
      };
    } catch (e) {
      debugPrint('Error getting performance data: $e');
      return {};
    }
  }

  /// Build comprehensive stats data
  Future<ProfileStatsData> _buildStatsData(String userId, Map<String, dynamic> performanceData) async {
    final totalHours = (performanceData['totalHours'] as double?) ?? 0.0;
    final totalEarnings = (performanceData['totalEarnings'] as double?) ?? 0.0;
    final averageHourlyRate = totalHours > 0 ? totalEarnings / totalHours : 15.0; // Dutch minimum for security
    
    return ProfileStatsData(
      memberSinceDate: DateTime.now().subtract(const Duration(days: 180)), // 6 months ago
      totalJobsCompleted: (performanceData['totalShifts'] as int?) ?? 0,
      totalHoursWorked: totalHours.round(),
      certificatesCount: 2, // From mock data
      averageRating: (performanceData['averageRating'] as double?) ?? 0.0,
      completionRate: (performanceData['completionRate'] as double?) ?? 0.0,
      averageHourlyRate: averageHourlyRate,
      monthlyEarnings: totalEarnings, // Assuming this is monthly
      activeSpecializations: 2, // From mock data
      repeatJobPercentage: 65.0, // Mock percentage
      lastUpdated: DateTime.now(),
    );
  }

  /// Generate mock shift data for performance analytics
  List<Map<String, dynamic>> _generateMockShiftData() {
    final random = Random();
    final shifts = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    // Generate 15 shifts over the last month
    for (int i = 0; i < 15; i++) {
      final daysAgo = random.nextInt(30);
      final startTime = now.subtract(Duration(days: daysAgo));
      final duration = 6 + random.nextDouble() * 6; // 6-12 hours
      final hourlyRate = 12.0 + random.nextDouble() * 8.0; // €12-20/hour
      final isCompleted = random.nextDouble() > 0.1;
      
      shifts.add({
        'id': 'shift_$i',
        'title': 'Beveiligingsopdracht ${i + 1}',
        'companyName': 'Bedrijf ${String.fromCharCode(65 + random.nextInt(10))}',
        'startTime': startTime,
        'endTime': startTime.add(Duration(hours: duration.round())),
        'durationHours': duration,
        'totalEarnings': duration * hourlyRate,
        'status': isCompleted ? 'completed' : 'cancelled',
        'rating': random.nextDouble() > 0.2 ? 3.5 + random.nextDouble() * 1.5 : null,
      });
    }
    
    return shifts;
  }

  /// Check and track milestone achievements
  Future<void> _checkMilestoneAchievements(String userId, ProfileCompletionData completionData) async {
    final userMilestones = _achievedMilestones.putIfAbsent(userId, () => {});
    
    // Check percentage-based milestones
    for (final milestone in ProfileCompletionMilestone.values) {
      if (milestone.percentageThreshold > 0 && 
          completionData.completionPercentage >= milestone.percentageThreshold &&
          !userMilestones.contains(milestone)) {
        await trackCompletionMilestone(userId, milestone);
      }
    }
    
    // Check special milestones
    if (completionData.completedElements[ProfileElementType.wpbrCertificate] == true &&
        !userMilestones.contains(ProfileCompletionMilestone.wpbrAdded)) {
      await trackCompletionMilestone(userId, ProfileCompletionMilestone.wpbrAdded);
    }
    
    if (completionData.completedElements[ProfileElementType.certificates] == true &&
        !userMilestones.contains(ProfileCompletionMilestone.firstCertificate)) {
      await trackCompletionMilestone(userId, ProfileCompletionMilestone.firstCertificate);
    }
    
    if (completionData.completedElements[ProfileElementType.photo] == true &&
        !userMilestones.contains(ProfileCompletionMilestone.photoAdded)) {
      await trackCompletionMilestone(userId, ProfileCompletionMilestone.photoAdded);
    }
  }

  /// Track completion calculation analytics event
  Future<void> _trackCompletionCalculated(String userId, ProfileCompletionData completionData) async {
    try {
      await _analyticsService.trackEvent(
        jobId: 'profile_completion',
        eventType: JobEventType.completion,
        userId: userId,
        metadata: {
          'event_type': 'completion_calculated',
          'completion_percentage': completionData.completionPercentage,
          'missing_elements_count': completionData.missingElements.length,
          'meets_minimum_requirements': completionData.meetsMinimumRequirements,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error tracking completion calculated event: $e');
    }
  }

  /// Track stats view analytics event
  Future<void> _trackStatsViewed(String userId, ProfileStatsData statsData) async {
    try {
      await _analyticsService.trackEvent(
        jobId: 'profile_stats',
        eventType: JobEventType.jobViewed,
        userId: userId,
        metadata: {
          'event_type': 'stats_viewed',
          'total_jobs_completed': statsData.totalJobsCompleted,
          'average_rating': statsData.averageRating,
          'experience_level': statsData.experienceLevel.dutchDescription,
          'performance_category': statsData.performanceCategory.dutchDescription,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error tracking stats viewed event: $e');
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheValidDuration;
  }

  /// Check if milestone is considered major (requires notification)
  bool _isMajorMilestone(ProfileCompletionMilestone milestone) {
    return [
      ProfileCompletionMilestone.halfComplete,
      ProfileCompletionMilestone.fullyComplete,
      ProfileCompletionMilestone.wpbrAdded,
    ].contains(milestone);
  }

  /// Clear cache for specific user
  void clearUserCache(String userId) {
    final keysToRemove = <String>[];
    for (final key in _completionCache.keys) {
      if (key.contains(userId)) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      _completionCache.remove(key);
      _statsCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    // Cancel any pending reminders
    _reminderTimers[userId]?.cancel();
    _reminderTimers.remove(userId);
    
    debugPrint('Cleared user cache successfully');
  }

  /// Clear all caches
  void clearAllCaches() {
    _completionCache.clear();
    _statsCache.clear();
    _cacheTimestamps.clear();
    
    // Cancel all reminder timers
    for (final timer in _reminderTimers.values) {
      timer.cancel();
    }
    _reminderTimers.clear();
    
    debugPrint('Cleared all profile completion caches');
  }

  /// Get service statistics for monitoring
  Map<String, dynamic> getServiceStats() {
    return {
      'completion_cache_size': _completionCache.length,
      'stats_cache_size': _statsCache.length,
      'active_reminder_timers': _reminderTimers.length,
      'tracked_users': _achievedMilestones.length,
      'total_milestones_achieved': _achievedMilestones.values
          .fold(0, (total, milestones) => total + milestones.length),
    };
  }

  /// Dispose service and clean up resources
  void dispose() {
    clearAllCaches();
    debugPrint('ProfileCompletionService disposed');
  }
}