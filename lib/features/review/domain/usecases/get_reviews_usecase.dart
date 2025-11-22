import '../entities/review.dart';
import '../repositories/review_repository.dart';

class GetReviewsUseCase {
  final ReviewRepository repository;

  GetReviewsUseCase(this.repository);

  Future<List<Review>> call(String photographerId) async {
    if (photographerId.isEmpty) {
      throw Exception('Photographer ID is required');
    }

    return await repository.getPhotographerReviews(photographerId);
  }
}
