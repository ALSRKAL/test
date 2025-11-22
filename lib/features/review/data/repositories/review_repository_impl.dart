import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';
import '../datasources/review_local_datasource.dart';
import '../models/review_model.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;
  final ReviewLocalDataSource localDataSource;

  ReviewRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Review> createReview({
    required String photographerId,
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    final review = await remoteDataSource.createReview(
      photographerId: photographerId,
      bookingId: bookingId,
      rating: rating,
      comment: comment,
    );

    // Invalidate cache after creating new review (don't fail if it fails)
    try {
      await localDataSource.clearCache();
    } catch (e) {
      // Ignore cache errors
    }

    return review;
  }

  @override
  Future<List<Review>> getPhotographerReviews(String photographerId) async {
    try {
      // Try to get from remote
      final reviews =
          await remoteDataSource.getPhotographerReviews(photographerId);

      // Cache the results (don't fail if caching fails)
      try {
        await localDataSource.cacheReviews(photographerId, reviews);
      } catch (cacheError) {
        // Ignore cache errors
      }

      return reviews;
    } catch (e) {
      // If remote fails, try to get from cache
      try {
        final cached = await localDataSource.getCachedReviews(photographerId);
        if (cached != null && cached.isNotEmpty) {
          return cached.map((r) => ReviewModel.fromJson(r)).toList();
        }
      } catch (cacheError) {
        // Ignore cache errors
      }
      rethrow;
    }
  }

  @override
  Future<List<Review>> getMyPhotographerReviews() async {
    try {
      final reviews = await remoteDataSource.getMyPhotographerReviews();
      return reviews;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Review> updateReview(
      String reviewId, double rating, String comment) async {
    final review =
        await remoteDataSource.updateReview(reviewId, rating, comment);

    // Invalidate cache after updating (don't fail if it fails)
    try {
      await localDataSource.clearCache();
    } catch (e) {
      // Ignore cache errors
    }

    return review;
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await remoteDataSource.deleteReview(reviewId);

    // Invalidate cache after deleting (don't fail if it fails)
    try {
      await localDataSource.clearCache();
    } catch (e) {
      // Ignore cache errors
    }
  }

  @override
  Future<Review> replyToReview(String reviewId, String replyText) async {
    final review = await remoteDataSource.replyToReview(reviewId, replyText);

    // Invalidate cache after replying (don't fail if it fails)
    try {
      await localDataSource.clearCache();
    } catch (e) {
      // Ignore cache errors
    }

    return review;
  }

  @override
  Future<void> reportReview(String reviewId, String reason) async {
    await remoteDataSource.reportReview(reviewId, reason);

    // Invalidate cache after reporting (don't fail if it fails)
    try {
      await localDataSource.clearCache();
    } catch (e) {
      // Ignore cache errors
    }
  }
}
