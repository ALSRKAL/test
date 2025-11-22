import '../repositories/photographer_repository.dart';

class AddToFavoritesUseCase {
  final PhotographerRepository repository;

  AddToFavoritesUseCase(this.repository);

  Future<void> call(String photographerId) async {
    if (photographerId.isEmpty) {
      throw Exception('Photographer ID is required');
    }

    await repository.addToFavorites(photographerId);
  }
}
