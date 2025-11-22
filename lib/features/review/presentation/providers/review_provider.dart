import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/review.dart';
import '../../domain/usecases/get_reviews_usecase.dart';
import '../../domain/usecases/create_review_usecase.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../data/datasources/review_remote_datasource.dart';
import '../../data/datasources/review_local_datasource.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/offline_service.dart';

// Review State
class ReviewState {
  final bool isLoading;
  final String? error;
  final List<Review> reviews;
  final double averageRating;
  final int totalReviews;

  const ReviewState({
    this.isLoading = false,
    this.error,
    this.reviews = const [],
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  ReviewState copyWith({
    bool? isLoading,
    String? error,
    List<Review>? reviews,
    double? averageRating,
    int? totalReviews,
  }) {
    return ReviewState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      reviews: reviews ?? this.reviews,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}

// Review Notifier
class ReviewNotifier extends StateNotifier<ReviewState> {
  final GetReviewsUseCase getReviewsUseCase;
  final CreateReviewUseCase createReviewUseCase;
  final ReviewRepositoryImpl repository;

  ReviewNotifier({
    required this.getReviewsUseCase,
    required this.createReviewUseCase,
    required this.repository,
  }) : super(const ReviewState());

  Future<void> getReviews(String photographerId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final reviews = await getReviewsUseCase.call(photographerId);
      
      final avgRating = reviews.isEmpty
          ? 0.0
          : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
              reviews.length;

      state = state.copyWith(
        isLoading: false,
        reviews: reviews,
        averageRating: avgRating,
        totalReviews: reviews.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> getPhotographerReviews() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final reviews = await repository.getMyPhotographerReviews();
      
      final avgRating = reviews.isEmpty
          ? 0.0
          : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
              reviews.length;

      state = state.copyWith(
        isLoading: false,
        reviews: reviews,
        averageRating: avgRating,
        totalReviews: reviews.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createReview({
    required String photographerId,
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final review = await createReviewUseCase.call(
        photographerId: photographerId,
        bookingId: bookingId,
        rating: rating.toDouble(),
        comment: comment,
      );

      final updatedReviews = [review, ...state.reviews];
      final avgRating = updatedReviews.isEmpty
          ? 0.0
          : updatedReviews.map((r) => r.rating).reduce((a, b) => a + b) /
              updatedReviews.length;

      state = state.copyWith(
        isLoading: false,
        reviews: updatedReviews,
        averageRating: avgRating,
        totalReviews: updatedReviews.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> replyToReview(String reviewId, String replyText) async {
    try {
      final updatedReview = await repository.replyToReview(reviewId, replyText);
      
      final updatedReviews = state.reviews.map((review) {
        return review.id == reviewId ? updatedReview : review;
      }).toList();

      state = state.copyWith(reviews: updatedReviews);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reportReview(String reviewId, String reason) async {
    try {
      await repository.reportReview(reviewId, reason);
      
      final updatedReviews = state.reviews.map((review) {
        if (review.id == reviewId) {
          return Review(
            id: review.id,
            clientId: review.clientId,
            clientName: review.clientName,
            clientAvatar: review.clientAvatar,
            photographerId: review.photographerId,
            bookingId: review.bookingId,
            packageName: review.packageName,
            bookingDate: review.bookingDate,
            rating: review.rating,
            comment: review.comment,
            reply: review.reply,
            isReported: true,
            reportReason: reason,
            createdAt: review.createdAt,
            updatedAt: review.updatedAt,
          );
        }
        return review;
      }).toList();

      state = state.copyWith(reviews: updatedReviews);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateReview(String reviewId, double rating, String comment) async {
    try {
      final updatedReview = await repository.updateReview(reviewId, rating, comment);
      
      final updatedReviews = state.reviews.map((review) {
        return review.id == reviewId ? updatedReview : review;
      }).toList();

      state = state.copyWith(reviews: updatedReviews);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await repository.deleteReview(reviewId);
      
      final updatedReviews = state.reviews.where((review) => review.id != reviewId).toList();
      
      final avgRating = updatedReviews.isEmpty
          ? 0.0
          : updatedReviews.map((r) => r.rating).reduce((a, b) => a + b) /
              updatedReviews.length;

      state = state.copyWith(
        reviews: updatedReviews,
        averageRating: avgRating,
        totalReviews: updatedReviews.length,
      );
    } catch (e) {
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final reviewRepositoryProvider = Provider((ref) {
  return ReviewRepositoryImpl(
    remoteDataSource: ReviewRemoteDataSourceImpl(ApiClient()),
    localDataSource: ReviewLocalDataSource(OfflineService()),
  );
});

final getReviewsUseCaseProvider = Provider((ref) {
  return GetReviewsUseCase(ref.watch(reviewRepositoryProvider));
});

final createReviewUseCaseProvider = Provider((ref) {
  return CreateReviewUseCase(ref.watch(reviewRepositoryProvider));
});

final reviewProvider = StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  return ReviewNotifier(
    getReviewsUseCase: ref.read(getReviewsUseCaseProvider),
    createReviewUseCase: ref.read(createReviewUseCaseProvider),
    repository: ref.read(reviewRepositoryProvider),
  );
});
