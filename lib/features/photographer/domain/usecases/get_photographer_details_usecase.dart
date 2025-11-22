import '../entities/photographer.dart';
import '../repositories/photographer_repository.dart';

class GetPhotographerDetailsUseCase {
  final PhotographerRepository repository;

  GetPhotographerDetailsUseCase(this.repository);

  Future<Photographer> call(String photographerId) async {
    if (photographerId.isEmpty) {
      throw Exception('Photographer ID is required');
    }

    return await repository.getPhotographerById(photographerId);
  }
}
