import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/comprehensive_review_model.dart';
import '../services/review_management_service.dart';

// Events
abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserReviews extends ReviewEvent {
  final String userId;
  final ReviewerType? asRole;

  const LoadUserReviews({
    required this.userId,
    this.asRole,
  });

  @override
  List<Object?> get props => [userId, asRole];
}

class LoadPendingReviews extends ReviewEvent {
  final String userId;

  const LoadPendingReviews({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class SubmitReview extends ReviewEvent {
  final ComprehensiveJobReview review;

  const SubmitReview({required this.review});

  @override
  List<Object?> get props => [review];
}

class EditReview extends ReviewEvent {
  final String reviewId;
  final ComprehensiveJobReview updates;

  const EditReview({
    required this.reviewId,
    required this.updates,
  });

  @override
  List<Object?> get props => [reviewId, updates];
}

class DeleteReview extends ReviewEvent {
  final String reviewId;

  const DeleteReview({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

class RespondToReview extends ReviewEvent {
  final String reviewId;
  final String responseText;

  const RespondToReview({
    required this.reviewId,
    required this.responseText,
  });

  @override
  List<Object?> get props => [reviewId, responseText];
}

class FlagReview extends ReviewEvent {
  final String reviewId;
  final String reason;

  const FlagReview({
    required this.reviewId,
    required this.reason,
  });

  @override
  List<Object?> get props => [reviewId, reason];
}

class LoadReviewStats extends ReviewEvent {
  final String userId;

  const LoadReviewStats({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// States
abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewsLoaded extends ReviewState {
  final List<ComprehensiveJobReview> reviews;
  final UserReviewStats? stats;

  const ReviewsLoaded({
    required this.reviews,
    this.stats,
  });

  @override
  List<Object?> get props => [reviews, stats];
}

class PendingReviewsLoaded extends ReviewState {
  final List<Map<String, dynamic>> pendingReviews;

  const PendingReviewsLoaded({required this.pendingReviews});

  @override
  List<Object?> get props => [pendingReviews];
}

class ReviewSubmitted extends ReviewState {
  final String reviewId;

  const ReviewSubmitted({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

class ReviewEdited extends ReviewState {}

class ReviewDeleted extends ReviewState {}

class ReviewResponseSubmitted extends ReviewState {}

class ReviewFlagged extends ReviewState {}

class ReviewStatsLoaded extends ReviewState {
  final UserReviewStats stats;

  const ReviewStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class ReviewError extends ReviewState {
  final String message;

  const ReviewError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewManagementService _reviewService;

  ReviewBloc({
    ReviewManagementService? reviewService,
  })  : _reviewService = reviewService ?? ReviewManagementService(),
        super(ReviewInitial()) {
    on<LoadUserReviews>(_onLoadUserReviews);
    on<LoadPendingReviews>(_onLoadPendingReviews);
    on<SubmitReview>(_onSubmitReview);
    on<EditReview>(_onEditReview);
    on<DeleteReview>(_onDeleteReview);
    on<RespondToReview>(_onRespondToReview);
    on<FlagReview>(_onFlagReview);
    on<LoadReviewStats>(_onLoadReviewStats);
  }

  Future<void> _onLoadUserReviews(
    LoadUserReviews event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());
    try {
      final reviews = await _reviewService.getReviewsForUser(
        event.userId,
        asRole: event.asRole,
      );
      
      final stats = await _reviewService.getUserReviewStats(event.userId);
      
      emit(ReviewsLoaded(
        reviews: reviews,
        stats: stats,
      ));
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }

  Future<void> _onLoadPendingReviews(
    LoadPendingReviews event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());
    try {
      final pendingReviews = await _reviewService.getPendingReviewsForUser(
        event.userId,
      );
      
      emit(PendingReviewsLoaded(pendingReviews: pendingReviews));
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }

  Future<void> _onSubmitReview(
    SubmitReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());
    try {
      final reviewId = await _reviewService.submitReview(event.review);
      emit(ReviewSubmitted(reviewId: reviewId));
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }

  Future<void> _onEditReview(
    EditReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());
    try {
      await _reviewService.editReview(event.reviewId, event.updates);
      emit(ReviewEdited());
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }

  Future<void> _onDeleteReview(
    DeleteReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());
    try {
      await _reviewService.deleteReview(event.reviewId);
      emit(ReviewDeleted());
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }

  Future<void> _onRespondToReview(
    RespondToReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());
    try {
      await _reviewService.respondToReview(
        event.reviewId,
        event.responseText,
      );
      emit(ReviewResponseSubmitted());
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }

  Future<void> _onFlagReview(
    FlagReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());
    try {
      await _reviewService.flagReview(event.reviewId, event.reason);
      emit(ReviewFlagged());
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }

  Future<void> _onLoadReviewStats(
    LoadReviewStats event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());
    try {
      final stats = await _reviewService.getUserReviewStats(event.userId);
      emit(ReviewStatsLoaded(stats: stats));
    } catch (e) {
      emit(ReviewError(message: e.toString()));
    }
  }
}