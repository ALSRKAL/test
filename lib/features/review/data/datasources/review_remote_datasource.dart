import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/review_model.dart';

abstract class ReviewRemoteDataSource {
  Future<ReviewModel> createReview({
    required String photographerId,
    required String bookingId,
    required double rating,
    required String comment,
  });

  Future<List<ReviewModel>> getPhotographerReviews(String photographerId);
  Future<List<ReviewModel>> getMyPhotographerReviews();
  Future<ReviewModel> updateReview(String reviewId, double rating, String comment);
  Future<void> deleteReview(String reviewId);
  Future<ReviewModel> replyToReview(String reviewId, String replyText);
  Future<void> reportReview(String reviewId, String reason);
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final ApiClient apiClient;

  ReviewRemoteDataSourceImpl(this.apiClient);

  @override
  Future<ReviewModel> createReview({
    required String photographerId,
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.reviews,
        data: {
          'photographer': photographerId,
          'booking': bookingId,
          'rating': rating,
          'comment': comment,
        },
      );

      return ReviewModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to create review');
    }
  }

  @override
  Future<List<ReviewModel>> getPhotographerReviews(String photographerId) async {
    try {
      final response = await apiClient
          .get('${ApiEndpoints.reviews}/photographer/$photographerId');

      final List<dynamic> data = response.data['data'];
      return data.map((json) => ReviewModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to get reviews');
    }
  }

  @override
  Future<ReviewModel> updateReview(
      String reviewId, double rating, String comment) async {
    try {
      final response = await apiClient.put(
        '${ApiEndpoints.reviews}/$reviewId',
        data: {
          'rating': rating,
          'comment': comment,
        },
      );

      return ReviewModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to update review');
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      await apiClient.delete('${ApiEndpoints.reviews}/$reviewId');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to delete review');
    }
  }

  @override
  Future<List<ReviewModel>> getMyPhotographerReviews() async {
    try {
      final response = await apiClient.get(ApiEndpoints.reviews);

      final List<dynamic> data = response.data['data'];
      return data.map((json) => ReviewModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to get reviews');
    }
  }

  @override
  Future<ReviewModel> replyToReview(String reviewId, String replyText) async {
    try {
      final response = await apiClient.post(
        '${ApiEndpoints.reviews}/$reviewId/reply',
        data: {'text': replyText},
      );

      return ReviewModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to reply to review');
    }
  }

  @override
  Future<void> reportReview(String reviewId, String reason) async {
    try {
      await apiClient.post(
        '${ApiEndpoints.reviews}/$reviewId/report',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to report review');
    }
  }
}
