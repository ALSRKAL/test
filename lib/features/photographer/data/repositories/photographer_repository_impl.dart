import '../../domain/entities/photographer.dart';
import '../../domain/repositories/photographer_repository.dart';
import '../datasources/photographer_remote_datasource.dart';
import '../datasources/photographer_local_datasource.dart';
import '../models/photographer_model.dart';

class PhotographerRepositoryImpl implements PhotographerRepository {
  final PhotographerRemoteDataSource remoteDataSource;
  final PhotographerLocalDataSource localDataSource;

  PhotographerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Photographer>> getPhotographers({
    int page = 1,
    int limit = 20,
    String? search,
    List<String>? specialties,
    String? city,
    double? minRating,
    bool? featured,
  }) async {
    try {
      // Try to get from remote
      final photographers = await remoteDataSource.getPhotographers(
        page: page,
        limit: limit,
        search: search,
        specialties: specialties,
        city: city,
        minRating: minRating,
        featured: featured,
      );

      // Cache the results (don't fail if caching fails)
      if (page == 1 && search == null && specialties == null && city == null) {
        try {
          await localDataSource.cachePhotographers(photographers);
        } catch (cacheError) {
          // Ignore cache errors, don't block the main flow
        }
      }

      return photographers;
    } catch (e) {
      // If remote fails, try to get from cache
      if (page == 1 && search == null && specialties == null && city == null) {
        try {
          final cached = await localDataSource.getCachedPhotographers();
          if (cached != null && cached.isNotEmpty) {
            // تحويل من Map إلى Photographer entities
            return cached.map((p) => PhotographerModel.fromJson(p)).toList();
          }
        } catch (cacheError) {
          // Ignore cache errors
        }
      }

      // إذا لم يكن هناك كاش، نرمي خطأ واضح
      throw Exception('لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة');
    }
  }

  @override
  Future<Photographer> getPhotographerById(String id) async {
    try {
      // Try to get from remote
      var photographer = await remoteDataSource.getPhotographerById(id);

      // Cache the result (don't fail if caching fails)
      try {
        await localDataSource.cachePhotographerDetails(id, photographer);
      } catch (cacheError) {
        // Ignore cache errors
      }

      return photographer;
    } catch (e) {
      // If remote fails, try to get from cache
      try {
        final cached = await localDataSource.getCachedPhotographerDetails(id);
        if (cached != null) {
          return PhotographerModel.fromJson(cached);
        }
      } catch (cacheError) {
        // Ignore cache errors
      }
      rethrow;
    }
  }

  @override
  Future<List<Photographer>> searchPhotographers(String query) async {
    return await remoteDataSource.searchPhotographers(query);
  }

  @override
  Future<List<Photographer>> getFeaturedPhotographers() async {
    return await remoteDataSource.getFeaturedPhotographers();
  }

  @override
  Future<void> addToFavorites(String photographerId) async {
    await remoteDataSource.addToFavorites(photographerId);

    // Update local cache (don't fail if caching fails)
    try {
      final favorites = await localDataSource.getCachedFavorites();
      if (!favorites.contains(photographerId)) {
        favorites.add(photographerId);
        await localDataSource.cacheFavorites(favorites);
      }
    } catch (cacheError) {
      // Ignore cache errors
    }
  }

  @override
  Future<void> removeFromFavorites(String photographerId) async {
    await remoteDataSource.removeFromFavorites(photographerId);

    // Update local cache (don't fail if caching fails)
    try {
      final favorites = await localDataSource.getCachedFavorites();
      favorites.remove(photographerId);
      await localDataSource.cacheFavorites(favorites);
    } catch (cacheError) {
      // Ignore cache errors
    }
  }

  @override
  Future<List<Photographer>> getFavorites() async {
    return await remoteDataSource.getFavorites();
  }

  @override
  Future<List<String>> uploadImages(List<String> imagePaths) async {
    return await remoteDataSource.uploadImages(imagePaths);
  }

  @override
  Future<String> uploadVideo(String videoPath) async {
    return await remoteDataSource.uploadVideo(videoPath);
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    await remoteDataSource.deleteImage(imageUrl);
  }

  @override
  Future<void> deleteVideo() async {
    await remoteDataSource.deleteVideo();
  }

  @override
  Future<String> createPhotographerProfile({
    required String bio,
    required String city,
    required String area,
    required List<String> specialties,
    double? startingPrice,
    String? currency,
  }) async {
    return await (remoteDataSource as PhotographerRemoteDataSourceImpl)
        .createPhotographerProfile(
          bio: bio,
          city: city,
          area: area,
          specialties: specialties,
          startingPrice: startingPrice,
          currency: currency,
        );
  }

  @override
  Future<void> updateBlockedDates(List<DateTime> blockedDates) async {
    await remoteDataSource.updateBlockedDates(blockedDates);
  }

  @override
  Future<void> updateProfile({
    String? bio,
    List<String>? specialties,
    String? city,
    String? area,
    double? startingPrice,
    String? currency,
  }) async {
    await remoteDataSource.updateProfile(
      bio: bio,
      specialties: specialties,
      city: city,
      area: area,
      startingPrice: startingPrice,
      currency: currency,
    );
  }

  @override
  Future<void> submitVerification({
    required String photographerId,
    required String idCardUrl,
    required List<String> portfolioSamples,
  }) async {
    await remoteDataSource.submitVerification(
      photographerId: photographerId,
      idCardUrl: idCardUrl,
      portfolioSamples: portfolioSamples,
    );
  }
}
