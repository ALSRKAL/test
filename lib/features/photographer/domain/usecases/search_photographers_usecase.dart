import '../entities/photographer.dart';
import '../repositories/photographer_repository.dart';

class SearchPhotographersUseCase {
  final PhotographerRepository repository;

  SearchPhotographersUseCase(this.repository);

  Future<List<Photographer>> call(String query) async {
    if (query.isEmpty) {
      return [];
    }

    if (query.length < 2) {
      throw Exception('Search query must be at least 2 characters');
    }

    return await repository.searchPhotographers(query);
  }
}
