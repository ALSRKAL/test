import '../entities/photographer.dart';

abstract class PhotographerRepository {
  Future<List<Photographer>> getPhotographers({
    int page = 1,
    int limit = 20,
    String? search,
    List<String>? specialties,
    String? city,
    double? minRating,
    bool? featured,
  });

  Future<Photographer> getPhotographerById(String id);

  Future<List<Photographer>> searchPhotographers(String query);

  Future<List<Photographer>> getFeaturedPhotographers();

  Future<void> addToFavorites(String photographerId);

  Future<void> removeFromFavorites(String photographerId);

  Future<List<Photographer>> getFavorites();

  // Profile management
  Future<String> createPhotographerProfile({
    required String bio,
    required String city,
    required String area,
    required List<String> specialties,
    double? startingPrice,
    String? currency,
  });

  // Media management methods
  Future<List<String>> uploadImages(List<String> imagePaths);

  Future<String> uploadVideo(String videoPath);

  Future<void> deleteImage(String imageUrl);

  Future<void> deleteVideo();

  // Availability management
  Future<void> updateBlockedDates(List<DateTime> blockedDates);

  // Profile management
  Future<void> updateProfile({
    String? bio,
    List<String>? specialties,
    String? city,
    String? area,
    double? startingPrice,
    String? currency,
  });
  // Verification
  Future<void> submitVerification({
    required String photographerId,
    required String idCardUrl,
    required List<String> portfolioSamples,
  });
}
