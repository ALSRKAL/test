import '../../../../core/services/offline_service.dart';

/// مصدر البيانات المحلي للمصورين
class PhotographerLocalDataSource {
  final OfflineService _offlineService;

  PhotographerLocalDataSource(this._offlineService);

  // حفظ المصورين محلياً
  Future<void> savePhotographers(
    List<Map<String, dynamic>> photographers,
  ) async {
    for (final photographer in photographers) {
      await _offlineService.savePhotographerLocally(photographer);
    }
  }

  // الحصول على المصورين المحفوظين
  Future<List<Map<String, dynamic>>> getPhotographers() async {
    return await _offlineService.getLocalPhotographers();
  }

  // حفظ مصور واحد
  Future<void> savePhotographer(Map<String, dynamic> photographer) async {
    await _offlineService.savePhotographerLocally(photographer);
  }

  // الحصول على المصورين المفضلين
  Future<List<Map<String, dynamic>>> getFavorites() async {
    return await _offlineService.getFavoritePhotographers();
  }

  // تحديث حالة المفضلة
  Future<void> toggleFavorite(String photographerId, bool isFavorite) async {
    await _offlineService.updateFavoriteStatus(photographerId, isFavorite);

    // إضافة للمزامنة
    await _offlineService.addToSyncQueue(
      operation: isFavorite ? 'add_favorite' : 'remove_favorite',
      endpoint: '/api/photographers/$photographerId/favorite',
      method: isFavorite ? 'POST' : 'DELETE',
      data: {},
    );
  }

  // حفظ المصورين في الكاش (للتوافق مع Repository)
  Future<void> cachePhotographers(List<dynamic> photographers) async {
    for (final photographer in photographers) {
      final photographerMap = photographer is Map<String, dynamic>
          ? photographer
          : {
              '_id': photographer.id,
              'name': photographer.name,
              'email': photographer.email,
              'profileImage': photographer.avatar,
              'coverImage': photographer.portfolio?.images?.isNotEmpty == true
                  ? photographer.portfolio.images.first.url
                  : null,
              'bio': photographer.bio,
              'city': photographer.location?.city,
              'rating': photographer.rating?.average ?? 0.0,
              'reviewCount': photographer.rating?.count ?? 0,
              'specialties': photographer.specialties,
            };
      await _offlineService.savePhotographerLocally(photographerMap);
    }
  }

  // الحصول على المصورين من الكاش
  Future<List<dynamic>?> getCachedPhotographers() async {
    try {
      return await _offlineService.getLocalPhotographers();
    } catch (e) {
      return null;
    }
  }

  // حفظ تفاصيل مصور في الكاش
  Future<void> cachePhotographerDetails(String id, dynamic photographer) async {
    final photographerMap = photographer is Map<String, dynamic>
        ? photographer
        : {
            '_id': photographer.id,
            'name': photographer.name,
            'email': photographer.email,
            'profileImage': photographer.avatar,
            'coverImage': photographer.portfolio?.images?.isNotEmpty == true
                ? photographer.portfolio.images.first.url
                : null,
            'bio': photographer.bio,
            'city': photographer.location?.city,
            'rating': photographer.rating?.average ?? 0.0,
            'reviewCount': photographer.rating?.count ?? 0,
            'specialties': photographer.specialties,
          };
    await _offlineService.savePhotographerLocally(photographerMap);
  }

  // الحصول على تفاصيل مصور من الكاش
  Future<dynamic> getCachedPhotographerDetails(String id) async {
    try {
      final photographers = await _offlineService.getLocalPhotographers();
      return photographers.firstWhere((p) => p['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // الحصول على قائمة المفضلة من الكاش
  Future<List<String>> getCachedFavorites() async {
    try {
      final favorites = await _offlineService.getFavoritePhotographers();
      return favorites.map((p) => p['id'].toString()).toList();
    } catch (e) {
      return [];
    }
  }

  // حفظ قائمة المفضلة في الكاش
  Future<void> cacheFavorites(List<String> favoriteIds) async {
    // يتم التعامل مع المفضلة عبر toggleFavorite
  }
}
