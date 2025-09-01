import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import '../models/comprehensive_review_model.dart';

/// Service for managing two-way reviews between guards and companies
/// Handles review submission, validation, analytics, and anti-manipulation
class ReviewManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _reviewsCollection = 'jobReviews';
  static const String _analyticsCollection = 'reviewAnalytics';
  static const String _disputesCollection = 'reviewDisputes';
  
  // Review window configuration (14 days in Dutch market)
  static const Duration reviewWindow = Duration(days: 14);
  static const Duration editWindow = Duration(hours: 24);
  static const Duration responseWindow = Duration(days: 7);

  /// Submit a new review
  Future<String> submitReview(ComprehensiveJobReview review) async {
    try {
      // Validate review eligibility
      final canSubmit = await canSubmitReview(
        review.workflowId,
        review.reviewerId,
      );
      
      if (!canSubmit) {
        throw Exception('Review periode is verlopen of al een review ingediend');
      }

      // Validate review authenticity
      final isAuthentic = await _validateReviewAuthenticity(review);
      if (!isAuthentic) {
        await _flagSuspiciousActivity(
          review.reviewerId,
          'Verdachte review activiteit gedetecteerd',
        );
        throw Exception('Review kon niet worden geverifieerd');
      }

      // Create review document
      final docRef = await _firestore.collection(_reviewsCollection).add(
        review.toFirestore()..['createdAt'] = FieldValue.serverTimestamp(),
      );

      // Update user analytics
      await _updateUserAnalytics(review);

      // Send notification to reviewee
      await _sendReviewNotification(review);

      return docRef.id;
    } catch (e) {
      throw Exception('Fout bij indienen review: $e');
    }
  }

  /// Edit an existing review (within 24 hour window)
  Future<void> editReview(String reviewId, ComprehensiveJobReview updates) async {
    try {
      final docRef = _firestore.collection(_reviewsCollection).doc(reviewId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Review niet gevonden');
      }

      final existingReview = ComprehensiveJobReview.fromFirestore(doc);
      
      if (!existingReview.canEdit) {
        throw Exception('Review kan niet meer worden aangepast (24 uur verlopen)');
      }

      await docRef.update({
        'comment': updates.comment,
        'categories': updates.categories.toMap(),
        'overallRating': updates.overallRating,
        'tags': updates.tags,
        'editedAt': FieldValue.serverTimestamp(),
        'status': ReviewStatus.edited.value,
      });

      // Update analytics with new ratings
      await _updateUserAnalytics(updates);
      
    } catch (e) {
      throw Exception('Fout bij bewerken review: $e');
    }
  }

  /// Delete a review (soft delete - maintains history)
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'status': ReviewStatus.deleted.value,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Fout bij verwijderen review: $e');
    }
  }

  /// Add response to a review
  Future<void> respondToReview(String reviewId, String responseText) async {
    try {
      final docRef = _firestore.collection(_reviewsCollection).doc(reviewId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Review niet gevonden');
      }

      final review = ComprehensiveJobReview.fromFirestore(doc);
      
      if (!review.canRespond) {
        throw Exception('Review heeft al een reactie of is niet actief');
      }

      await docRef.update({
        'responseText': responseText,
        'responseDate': FieldValue.serverTimestamp(),
      });

      // Notify original reviewer of response
      await _sendResponseNotification(review, responseText);
      
    } catch (e) {
      throw Exception('Fout bij reageren op review: $e');
    }
  }

  /// Check if user can submit review for workflow
  Future<bool> canSubmitReview(String workflowId, String userId) async {
    try {
      // Check if workflow is completed
      final workflowDoc = await _firestore
          .collection('jobWorkflows')
          .doc(workflowId)
          .get();
      
      if (!workflowDoc.exists) return false;
      
      final workflowData = workflowDoc.data()!;
      if (workflowData['status'] != 'completed') return false;

      // Check if within review window
      final completedAt = (workflowData['completedAt'] as Timestamp).toDate();
      if (DateTime.now().difference(completedAt) > reviewWindow) return false;

      // Check if user already submitted review
      final existingReview = await _firestore
          .collection(_reviewsCollection)
          .where('workflowId', isEqualTo: workflowId)
          .where('reviewerId', isEqualTo: userId)
          .limit(1)
          .get();
      
      return existingReview.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get remaining time in review window
  Future<Duration> getReviewWindowRemaining(String workflowId) async {
    try {
      final workflowDoc = await _firestore
          .collection('jobWorkflows')
          .doc(workflowId)
          .get();
      
      if (!workflowDoc.exists) return Duration.zero;
      
      final completedAt = (workflowDoc.data()!['completedAt'] as Timestamp).toDate();
      final deadline = completedAt.add(reviewWindow);
      final remaining = deadline.difference(DateTime.now());
      
      return remaining.isNegative ? Duration.zero : remaining;
    } catch (e) {
      return Duration.zero;
    }
  }

  /// Get user review statistics
  Future<UserReviewStats> getUserReviewStats(String userId) async {
    try {
      final analyticsDoc = await _firestore
          .collection(_analyticsCollection)
          .doc(userId)
          .get();
      
      if (!analyticsDoc.exists) {
        return UserReviewStats.empty(userId);
      }

      final data = analyticsDoc.data()!;
      return UserReviewStats(
        userId: userId,
        totalReviews: data['totalReviews'] ?? 0,
        averageRating: (data['averageRating'] ?? 0).toDouble(),
        averageCategories: ReviewCategories.fromMap(data['averageCategories'] ?? {}),
        ratingDistribution: Map<String, double>.from(data['ratingDistribution'] ?? {}),
        totalResponses: data['totalResponses'] ?? 0,
        lastReviewDate: data['lastReviewDate'] != null
            ? (data['lastReviewDate'] as Timestamp).toDate()
            : null,
        topTags: List<String>.from(data['topTags'] ?? []),
        verifiedReviews: data['verifiedReviews'] ?? 0,
      );
    } catch (e) {
      return UserReviewStats.empty(userId);
    }
  }

  /// Get reviews for a specific user
  Future<List<ComprehensiveJobReview>> getReviewsForUser(
    String userId, {
    ReviewerType? asRole,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_reviewsCollection)
          .where('revieweeId', isEqualTo: userId)
          .where('status', isEqualTo: ReviewStatus.active.value)
          .where('moderationStatus', isEqualTo: ModerationStatus.approved.value);

      if (asRole != null) {
        query = query.where('reviewerType', isEqualTo: asRole.value);
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ComprehensiveJobReview.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get pending reviews for user to submit
  Future<List<Map<String, dynamic>>> getPendingReviewsForUser(String userId) async {
    try {
      // Get completed workflows for user
      final workflowsQuery = await _firestore
          .collection('jobWorkflows')
          .where('guardId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .get();

      final pendingReviews = <Map<String, dynamic>>[];

      for (final workflow in workflowsQuery.docs) {
        final workflowData = workflow.data();
        final completedAt = (workflowData['completedAt'] as Timestamp).toDate();
        
        // Check if within review window
        if (DateTime.now().difference(completedAt) > reviewWindow) continue;

        // Check if review already submitted
        final existingReview = await _firestore
            .collection(_reviewsCollection)
            .where('workflowId', isEqualTo: workflow.id)
            .where('reviewerId', isEqualTo: userId)
            .limit(1)
            .get();

        if (existingReview.docs.isEmpty) {
          pendingReviews.add({
            'workflowId': workflow.id,
            'jobId': workflowData['jobId'],
            'companyId': workflowData['companyId'],
            'completedAt': completedAt,
            'daysRemaining': reviewWindow.inDays - 
                DateTime.now().difference(completedAt).inDays,
          });
        }
      }

      return pendingReviews;
    } catch (e) {
      return [];
    }
  }

  /// Flag a review for moderation
  Future<void> flagReview(String reviewId, String reason) async {
    try {
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'moderationStatus': ModerationStatus.flagged.value,
        'flagReason': reason,
        'flaggedAt': FieldValue.serverTimestamp(),
      });

      // Create moderation queue entry
      await _firestore.collection('reviewModerationQueue').add({
        'reviewId': reviewId,
        'reason': reason,
        'reporterId': AuthService.currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Fout bij rapporteren review: $e');
    }
  }

  // Private helper methods

  Future<bool> _validateReviewAuthenticity(ComprehensiveJobReview review) async {
    // Check for suspicious patterns
    // 1. Check submission timing (not too quick after completion)
    // 2. Validate text content (not duplicate)
    // 3. Check rating patterns (not all 5s or 1s)
    
    // For now, basic validation
    if (review.categories.averageRating == 5.0 && 
        (review.comment == null || review.comment!.length < 10)) {
      return false; // Suspicious: perfect rating with no meaningful comment
    }
    
    return true;
  }

  Future<void> _flagSuspiciousActivity(String userId, String reason) async {
    await _firestore.collection('suspiciousActivity').add({
      'userId': userId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'review',
    });
  }

  Future<void> _updateUserAnalytics(ComprehensiveJobReview review) async {
    final analyticsRef = _firestore
        .collection(_analyticsCollection)
        .doc(review.revieweeId);

    await _firestore.runTransaction((transaction) async {
      final analyticsDoc = await transaction.get(analyticsRef);
      
      if (!analyticsDoc.exists) {
        // Create new analytics document
        transaction.set(analyticsRef, {
          'userId': review.revieweeId,
          'totalReviews': 1,
          'averageRating': review.overallRating,
          'averageCategories': review.categories.toMap(),
          'ratingDistribution': {
            '${review.overallRating.round()}': 1,
          },
          'totalResponses': 0,
          'lastReviewDate': FieldValue.serverTimestamp(),
          'topTags': review.tags,
          'verifiedReviews': review.isVerified ? 1 : 0,
        });
      } else {
        // Update existing analytics
        final data = analyticsDoc.data()!;
        final totalReviews = (data['totalReviews'] ?? 0) + 1;
        final currentAverage = (data['averageRating'] ?? 0).toDouble();
        
        // Calculate new average
        final newAverage = ((currentAverage * (totalReviews - 1)) + 
            review.overallRating) / totalReviews;
        
        // Update rating distribution
        final distribution = Map<String, dynamic>.from(
            data['ratingDistribution'] ?? {});
        final ratingKey = '${review.overallRating.round()}';
        distribution[ratingKey] = (distribution[ratingKey] ?? 0) + 1;
        
        transaction.update(analyticsRef, {
          'totalReviews': totalReviews,
          'averageRating': newAverage,
          'ratingDistribution': distribution,
          'lastReviewDate': FieldValue.serverTimestamp(),
          'verifiedReviews': review.isVerified 
              ? FieldValue.increment(1) 
              : data['verifiedReviews'],
        });
      }
    });
  }

  Future<void> _sendReviewNotification(ComprehensiveJobReview review) async {
    // Send notification to reviewee about new review
    // This would integrate with existing notification system
    await _firestore.collection('notifications').add({
      'userId': review.revieweeId,
      'type': 'new_review',
      'title': 'Nieuwe beoordeling ontvangen',
      'message': 'Je hebt een nieuwe ${review.overallRating.toStringAsFixed(1)} sterren beoordeling ontvangen',
      'data': {
        'reviewId': review.id,
        'workflowId': review.workflowId,
        'rating': review.overallRating,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Future<void> _sendResponseNotification(
    ComprehensiveJobReview review,
    String responseText,
  ) async {
    // Send notification about review response
    await _firestore.collection('notifications').add({
      'userId': review.reviewerId,
      'type': 'review_response',
      'title': 'Reactie op je beoordeling',
      'message': 'Er is gereageerd op je beoordeling',
      'data': {
        'reviewId': review.id,
        'responseText': responseText,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}