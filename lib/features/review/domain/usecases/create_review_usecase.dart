import '../entities/review.dart';
import '../repositories/review_repository.dart';

class CreateReviewUseCase {
  final ReviewRepository repository;

  CreateReviewUseCase(this.repository);

  Future<Review> call({
    required String photographerId,
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    // Validation
    if (photographerId.isEmpty) {
      throw Exception('Photographer ID is required');
    }

    if (bookingId.isEmpty) {
      throw Exception('Booking ID is required');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    if (comment.isEmpty) {
      throw Exception('Comment is required');
    }

    if (comment.length < 10) {
      throw Exception('Comment must be at least 10 characters');
    }

    return await repository.createReview(
      photographerId: photographerId,
      bookingId: bookingId,
      rating: rating,
      comment: comment,
    );
  }
}
