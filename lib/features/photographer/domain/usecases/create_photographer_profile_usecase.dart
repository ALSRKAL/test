import '../repositories/photographer_repository.dart';

class CreatePhotographerProfileUseCase {
  final PhotographerRepository repository;

  CreatePhotographerProfileUseCase(this.repository);

  Future<String> call({
    required String bio,
    required String city,
    required String area,
    required List<String> specialties,
    double? startingPrice,
    String? currency,
  }) async {
    // Validation
    if (bio.isEmpty || bio.length < 50) {
      throw Exception('Bio must be at least 50 characters');
    }

    if (city.isEmpty || area.isEmpty) {
      throw Exception('Location is required');
    }

    if (specialties.isEmpty) {
      throw Exception('At least one specialty is required');
    }

    // Create profile
    return await repository.createPhotographerProfile(
      bio: bio,
      city: city,
      area: area,
      specialties: specialties,
      startingPrice: startingPrice,
      currency: currency,
    );
  }
}
