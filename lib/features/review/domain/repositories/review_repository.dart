import '../entities/review.dart';

abstract class ReviewRepository {
  Future<Review> createReview({
    required String photographerId,
    required String bookingId,
    required double rating,
    required String comment,
  });

  Future<List<Review>> getPhotographerReviews(String photographerId);
  
  Future<List<Review>> getMyPhotographerReviews();

  Future<Review> updateReview(String reviewId, double rating, String comment);

  Future<void> deleteReview(String reviewId);
  
  Future<Review> replyToReview(String reviewId, String replyText);
  
  Future<void> reportReview(String reviewId, String reason);
}
