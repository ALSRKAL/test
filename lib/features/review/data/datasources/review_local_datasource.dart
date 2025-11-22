import '../../../../core/services/offline_service.dart';

/// مصدر البيانات المحلي للتقييمات
class ReviewLocalDataSource {
  final OfflineService _offlineService;

  ReviewLocalDataSource(this._offlineService);

  // إنشاء تقييم محلياً
  Future<Map<String, dynamic>> createReviewLocally({
    required String photographerId,
    required String userId,
    required String userName,
    String? userAvatar,
    required double rating,
    String? comment,
    List<String>? images,
  }) async {
    final review = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'photographerId': photographerId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'images': images ?? [],
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    // حفظ التقييم محلياً
    await _offlineService.saveReviewLocally(review, isPending: true);

    // إضافة للمزامنة
    await _offlineService.addToSyncQueue(
      operation: 'create_review',
      endpoint: '/api/reviews',
      method: 'POST',
      data: review,
    );

    return review;
  }

  // الحصول على التقييمات المحلية
  Future<List<Map<String, dynamic>>> getLocalReviews(String photographerId) async {
    return await _offlineService.getLocalReviews(photographerId);
  }

  // حفظ التقييمات من السيرفر
  Future<void> cacheReviews(String photographerId, List<dynamic> reviews) async {
    for (final review in reviews) {
      final reviewMap = review is Map<String, dynamic>
          ? review
          : {
              '_id': review.id,
              'photographerId': photographerId,
              'userId': review.user?.id,
              'userName': review.user?.name,
              'userAvatar': review.user?.avatar,
              'rating': review.rating,
              'comment': review.comment,
              'images': review.images ?? [],
              'createdAt': review.createdAt?.millisecondsSinceEpoch,
            };
      await _offlineService.saveReviewLocally(reviewMap, isPending: false);
    }
  }

  // الحصول على التقييمات من الكاش
  Future<List<dynamic>?> getCachedReviews(String photographerId) async {
    try {
      return await _offlineService.getLocalReviews(photographerId);
    } catch (e) {
      return null;
    }
  }

  // مسح الكاش
  Future<void> clearCache() async {
    // يمكن إضافة منطق لمسح الكاش هنا إذا لزم الأمر
  }
}
