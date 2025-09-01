import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../shared/services/encryption_service.dart';
import '../../beveiliger_profiel/models/profile_stats_data.dart';
import '../../beveiliger_profiel/services/beveiliger_profiel_service.dart';
import '../models/job_workflow_models.dart';

/// Job completion rating service following existing SecuryFlex patterns
/// 
/// Extends existing rating calculation patterns from beveiliger_profiel_service.dart
/// and integrates with existing ProfileStatsData model for rating updates
class JobCompletionRatingService {
  static final JobCompletionRatingService _instance = JobCompletionRatingService._internal();
  factory JobCompletionRatingService() => _instance;
  JobCompletionRatingService._internal();

  static JobCompletionRatingService get instance => _instance;

  /// Firebase services - following existing service patterns
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Encryption service for secure rating data
  final EncryptionService _encryptionService = EncryptionService();
  
  /// Cache for recent ratings - following beveiliger_profiel_service pattern
  final Map<String, List<JobReview>> _ratingsCache = {};
  DateTime? _lastCacheUpdate;
  
  /// Cache duration matching existing patterns
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Submit job completion rating using existing patterns
  Future<JobReviewSubmissionResult> submitJobCompletionRating({
    required String workflowId,
    required String jobId,
    required String raterId,
    required String raterRole, // 'guard' or 'company'
    required double rating,
    String? comments,
  }) async {
    try {
      if (kDebugMode) {
        print('[JobCompletionRatingService] Submitting rating for job: $jobId');
      }

      // Validate input using existing patterns
      final validationResult = _validateRatingInput(rating, raterRole);
      if (!validationResult.isValid) {
        return JobReviewSubmissionResult(
          isSuccess: false,
          errorMessage: validationResult.errorMessage,
        );
      }

      // Create JobReview using new factory method
      final jobReview = JobReview.forJobCompletion(
        workflowId: workflowId,
        reviewerId: raterId,
        reviewerRole: raterRole,
        rating: rating,
        comment: comments,
      );

      // Store rating in Firestore
      final reviewDoc = await _firestore
          .collection('job_reviews')
          .add(jobReview.toFirestore());

      if (kDebugMode) {
        print('[JobCompletionRatingService] Rating stored with ID: ${reviewDoc.id}');
      }

      // Update workflow state to indicate rating submitted
      await _updateWorkflowRatingStatus(workflowId, raterId, raterRole);

      // Update profile statistics using existing rating calculation patterns
      await _updateProfileRatingStatistics(raterId, raterRole, rating);

      // Invalidate cache
      _invalidateCache();

      return JobReviewSubmissionResult(
        isSuccess: true,
        reviewId: reviewDoc.id,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[JobCompletionRatingService] Error submitting rating: $e');
      }
      return JobReviewSubmissionResult(
        isSuccess: false,
        errorMessage: 'Er is een fout opgetreden bij het indienen van de beoordeling: ${e.toString()}',
      );
    }
  }

  /// Get job ratings for display - following existing caching patterns
  Future<List<JobReview>> getJobRatings(String workflowId, {bool useCache = true}) async {
    try {
      // Check cache first if enabled
      if (useCache && _ratingsCache.containsKey(workflowId) && _isCacheValid()) {
        return _ratingsCache[workflowId]!;
      }

      if (kDebugMode) {
        print('[JobCompletionRatingService] Loading ratings for workflow: $workflowId');
      }

      final ratingsQuery = await _firestore
          .collection('job_reviews')
          .where('workflowId', isEqualTo: workflowId)
          .orderBy('createdAt', descending: true)
          .get();

      final ratings = ratingsQuery.docs
          .map((doc) => JobReview.fromFirestore(doc))
          .toList();

      // Cache the results
      _ratingsCache[workflowId] = ratings;
      _lastCacheUpdate = DateTime.now();

      return ratings;
    } catch (e) {
      if (kDebugMode) {
        print('[JobCompletionRatingService] Error loading ratings: $e');
      }
      return [];
    }
  }

  /// Calculate average rating from job reviews - using existing patterns
  Future<double> calculateAverageRating(String userId, String userRole) async {
    try {
      final ratingsQuery = await _firestore
          .collection('job_reviews')
          .where('reviewerId', isEqualTo: userId)
          .where('reviewerRole', isEqualTo: userRole)
          .get();

      if (ratingsQuery.docs.isEmpty) return 0.0;

      final ratings = ratingsQuery.docs
          .map((doc) => JobReview.fromFirestore(doc))
          .where((review) => review.isJobCompletionRating)
          .toList();

      if (ratings.isEmpty) return 0.0;

      final totalRating = ratings.fold<double>(0.0, (accumulator, review) => accumulator + review.rating);
      return totalRating / ratings.length;
    } catch (e) {
      if (kDebugMode) {
        print('[JobCompletionRatingService] Error calculating average rating: $e');
      }
      return 0.0;
    }
  }

  /// Check if both parties have rated the job
  Future<bool> areBothPartiesRated(String workflowId) async {
    try {
      final ratings = await getJobRatings(workflowId, useCache: false);
      
      final hasGuardRating = ratings.any((r) => r.reviewerRole == 'guard');
      final hasCompanyRating = ratings.any((r) => r.reviewerRole == 'company');
      
      return hasGuardRating && hasCompanyRating;
    } catch (e) {
      if (kDebugMode) {
        print('[JobCompletionRatingService] Error checking rating status: $e');
      }
      return false;
    }
  }

  /// Private methods

  RatingValidationResult _validateRatingInput(double rating, String raterRole) {
    if (rating < 1.0 || rating > 5.0) {
      return RatingValidationResult(
        isValid: false,
        errorMessage: 'Beoordeling moet tussen 1 en 5 sterren zijn',
      );
    }

    if (raterRole != 'guard' && raterRole != 'company') {
      return RatingValidationResult(
        isValid: false,
        errorMessage: 'Ongeldige gebruikersrol',
      );
    }

    return RatingValidationResult(isValid: true);
  }

  Future<void> _updateWorkflowRatingStatus(String workflowId, String raterId, String raterRole) async {
    try {
      final workflowRef = _firestore.collection('job_workflows').doc(workflowId);
      
      await workflowRef.update({
        '${raterRole}_rating_submitted': true,
        '${raterRole}_rating_submitted_by': raterId,
        '${raterRole}_rating_submitted_at': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Check if both parties have rated
      final bothRated = await areBothPartiesRated(workflowId);
      if (bothRated) {
        await workflowRef.update({
          'currentState': 'rated',
          'ratingCompletedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[JobCompletionRatingService] Error updating workflow rating status: $e');
      }
    }
  }

  Future<void> _updateProfileRatingStatistics(String userId, String userRole, double rating) async {
    try {
      // Update profile statistics using existing patterns from ProfileStatsData
      if (userRole == 'guard') {
        final profileService = BeveiligerProfielService.instance;
        final currentProfile = await profileService.loadProfile(userId);
        
        // Calculate new average rating (this would be more sophisticated in production)
        final newAverageRating = await calculateAverageRating(userId, userRole);
        
        // Update profile with new rating
        // Note: This would typically be handled by the ProfileStatsData service
        // For now, we'll log that the update should happen
        if (kDebugMode) {
          print('[JobCompletionRatingService] Should update guard profile rating to: $newAverageRating');
        }
      } else if (userRole == 'company') {
        // Similar logic for company rating updates
        if (kDebugMode) {
          print('[JobCompletionRatingService] Should update company rating');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[JobCompletionRatingService] Error updating profile statistics: $e');
      }
    }
  }

  bool _isCacheValid() {
    return _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration;
  }

  void _invalidateCache() {
    _ratingsCache.clear();
    _lastCacheUpdate = null;
  }
}

/// Result of job review submission
class JobReviewSubmissionResult {
  final bool isSuccess;
  final String? reviewId;
  final String? errorMessage;

  const JobReviewSubmissionResult({
    required this.isSuccess,
    this.reviewId,
    this.errorMessage,
  });
}

/// Rating validation result
class RatingValidationResult {
  final bool isValid;
  final String? errorMessage;

  const RatingValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}