import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_service.dart';
import '../../features/review/data/datasources/review_local_datasource.dart';

final reviewLocalDataSourceProvider = Provider<ReviewLocalDataSource>((ref) {
  return ReviewLocalDataSource(OfflineService());
});

final localReviewsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, photographerId) async {
    final localDataSource = ref.watch(reviewLocalDataSourceProvider);
    return await localDataSource.getLocalReviews(photographerId);
  },
);

final createOfflineReviewProvider = Provider<CreateOfflineReview>((ref) {
  final localDataSource = ref.watch(reviewLocalDataSourceProvider);
  final offlineService = OfflineService();
  return CreateOfflineReview(localDataSource, offlineService);
});

class CreateOfflineReview {
  final ReviewLocalDataSource _localDataSource;
  final OfflineService _offlineService;

  CreateOfflineReview(this._localDataSource, this._offlineService);

  Future<ReviewResult> execute({
    required String photographerId,
    required String userId,
    required String userName,
    String? userAvatar,
    required double rating,
    String? comment,
    List<String>? images,
  }) async {
    try {
      final isOnline = await _offlineService.isOnline();

      final review = await _localDataSource.createReviewLocally(
        photographerId: photographerId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        rating: rating,
        comment: comment,
        images: images,
      );

      return ReviewResult(
        success: true,
        message: isOnline
            ? 'تم إضافة التقييم بنجاح'
            : 'تم حفظ التقييم محلياً وسيتم إرساله عند الاتصال',
        review: review,
        isOffline: !isOnline,
      );
    } catch (e) {
      return ReviewResult(
        success: false,
        message: 'فشل في إضافة التقييم: $e',
      );
    }
  }
}

class ReviewResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? review;
  final bool isOffline;

  ReviewResult({
    required this.success,
    required this.message,
    this.review,
    this.isOffline = false,
  });
}
