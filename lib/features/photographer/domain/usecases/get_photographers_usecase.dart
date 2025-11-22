import '../entities/photographer.dart';
import '../repositories/photographer_repository.dart';

class GetPhotographersUseCase {
  final PhotographerRepository repository;

  GetPhotographersUseCase(this.repository);

  Future<List<Photographer>> call({
    int page = 1,
    int limit = 20,
    String? search,
    List<String>? specialties,
    String? city,
    double? minRating,
    bool? featured,
  }) async {
    return await repository.getPhotographers(
      page: page,
      limit: limit,
      search: search,
      specialties: specialties,
      city: city,
      minRating: minRating,
      featured: featured,
    );
  }
}
