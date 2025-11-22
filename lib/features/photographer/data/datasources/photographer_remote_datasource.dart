import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/photographer_model.dart';

abstract class PhotographerRemoteDataSource {
  Future<List<PhotographerModel>> getPhotographers({
    int page = 1,
    int limit = 20,
    String? search,
    List<String>? specialties,
    String? city,
    double? minRating,
    bool? featured,
  });

  Future<PhotographerModel> getPhotographerById(String id);
  Future<PhotographerModel?> getMyPhotographerProfile();
  Future<List<PhotographerModel>> searchPhotographers(String query);
  Future<List<PhotographerModel>> getFeaturedPhotographers();
  Future<void> addToFavorites(String photographerId);
  Future<void> removeFromFavorites(String photographerId);
  Future<List<PhotographerModel>> getFavorites();

  // Media management
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

class PhotographerRemoteDataSourceImpl implements PhotographerRemoteDataSource {
  final ApiClient apiClient;

  PhotographerRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<PhotographerModel>> getPhotographers({
    int page = 1,
    int limit = 20,
    String? search,
    List<String>? specialties,
    String? city,
    double? minRating,
    bool? featured,
  }) async {
    try {
      print('🌐 DEBUG RemoteDataSource: getPhotographers called');

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (specialties != null && specialties.isNotEmpty)
          'specialties': specialties.join(','),
        if (city != null && city.isNotEmpty) 'city': city,
        if (minRating != null) 'minRating': minRating,
        if (featured != null) 'featured': featured,
      };

      print('🌐 DEBUG: Query params: $queryParams');
      print('🌐 DEBUG: Endpoint: ${ApiEndpoints.photographers}');

      final response = await apiClient.get(
        ApiEndpoints.photographers,
        queryParameters: queryParams,
      );

      print('🌐 DEBUG: Response status: ${response.statusCode}');
      print('🌐 DEBUG: Response data type: ${response.data.runtimeType}');
      print('🌐 DEBUG: Response data: ${response.data}');

      final List<dynamic> data = response.data['data'];
      print('🌐 DEBUG: Photographers count in response: ${data.length}');

      final photographers = data
          .map((json) => PhotographerModel.fromJson(json))
          .toList();
      print(
        '🌐 DEBUG: Successfully parsed ${photographers.length} photographers',
      );

      return photographers;
    } on DioException catch (e) {
      print('❌ DEBUG RemoteDataSource: DioException');
      print('  - Status code: ${e.response?.statusCode}');
      print('  - Response data: ${e.response?.data}');
      print('  - Message: ${e.message}');

      throw Exception(
        e.response?.data['message'] ?? 'Failed to get photographers',
      );
    }
  }

  @override
  Future<PhotographerModel> getPhotographerById(String id) async {
    try {
      final response = await apiClient.get('${ApiEndpoints.photographers}/$id');
      return PhotographerModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      // Special handling for 'me/profile' endpoint - return null for 404
      if (id == 'me/profile' && e.response?.statusCode == 404) {
        throw PhotographerProfileNotFoundException(
          'Photographer profile not found',
        );
      }
      throw Exception(
        e.response?.data['message'] ?? 'Failed to get photographer details',
      );
    }
  }

  @override
  Future<PhotographerModel?> getMyPhotographerProfile() async {
    try {
      print('🌐 DEBUG RemoteDataSource: getMyPhotographerProfile called');
      final response = await apiClient.get(
        '${ApiEndpoints.photographers}/me/profile',
      );
      print('🌐 DEBUG: getMyPhotographerProfile success');
      return PhotographerModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      print('❌ DEBUG RemoteDataSource: getMyPhotographerProfile DioException');
      print('  - Status: ${e.response?.statusCode}');

      if (e.response?.statusCode == 404) {
        print('  - Throwing PhotographerProfileNotFoundException');
        throw PhotographerProfileNotFoundException(
          'Photographer profile not found',
        );
      }
      throw Exception(
        e.response?.data['message'] ?? 'Failed to get photographer profile',
      );
    }
  }

  @override
  Future<List<PhotographerModel>> searchPhotographers(String query) async {
    try {
      final response = await apiClient.get(
        '${ApiEndpoints.photographers}/search',
        queryParameters: {'q': query},
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => PhotographerModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to search photographers',
      );
    }
  }

  @override
  Future<List<PhotographerModel>> getFeaturedPhotographers() async {
    try {
      final response = await apiClient.get(
        '${ApiEndpoints.photographers}/featured',
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => PhotographerModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to get featured photographers',
      );
    }
  }

  @override
  Future<void> addToFavorites(String photographerId) async {
    try {
      await apiClient.post(
        '${ApiEndpoints.photographers}/$photographerId/favorite',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to add to favorites',
      );
    }
  }

  @override
  Future<void> removeFromFavorites(String photographerId) async {
    try {
      await apiClient.delete(
        '${ApiEndpoints.photographers}/$photographerId/favorite',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to remove from favorites',
      );
    }
  }

  @override
  Future<List<PhotographerModel>> getFavorites() async {
    try {
      final response = await apiClient.get(
        '${ApiEndpoints.photographers}/favorites',
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => PhotographerModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get favorites');
    }
  }

  @override
  Future<List<String>> uploadImages(List<String> imagePaths) async {
    try {
      final formData = FormData();

      for (final path in imagePaths) {
        formData.files.add(
          MapEntry('images', await MultipartFile.fromFile(path)),
        );
      }

      // Use longer timeout for multiple image uploads (3 minutes)
      final response = await apiClient.post(
        ApiEndpoints.uploadMultipleImages,
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 3),
          receiveTimeout: const Duration(minutes: 3),
        ),
      );

      final List<dynamic> uploadedData = response.data['data'];
      return uploadedData.map((item) => item['url'] as String).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to upload images');
    }
  }

  @override
  Future<String> uploadVideo(String videoPath) async {
    try {
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(videoPath),
      });

      // Use longer timeout for video uploads (5 minutes)
      final response = await apiClient.post(
        ApiEndpoints.uploadVideo,
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      return response.data['data']['url'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to upload video');
    }
  }

  @override
  Future<void> deleteImage(String imageId) async {
    try {
      // Use simplified endpoint that gets photographer from current user
      await apiClient.delete(ApiEndpoints.deletePortfolioImage(imageId));
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete image');
    }
  }

  @override
  Future<void> deleteVideo() async {
    try {
      // Use simplified endpoint that gets photographer from current user
      await apiClient.delete(ApiEndpoints.deletePortfolioVideo);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete video');
    }
  }

  @override
  Future<void> updateBlockedDates(List<DateTime> blockedDates) async {
    try {
      await apiClient.put(
        '${ApiEndpoints.photographers}/me/availability',
        data: {
          'blockedDates': blockedDates.map((d) => d.toIso8601String()).toList(),
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update availability',
      );
    }
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
    try {
      final data = <String, dynamic>{};

      if (bio != null) data['bio'] = bio;
      if (specialties != null) data['specialties'] = specialties;
      if (city != null || area != null) {
        data['location'] = {};
        if (city != null) data['location']['city'] = city;
        if (area != null) data['location']['area'] = area;
      }
      if (startingPrice != null) data['startingPrice'] = startingPrice;
      if (currency != null) data['currency'] = currency;

      await apiClient.put(
        '${ApiEndpoints.photographers}/me/profile',
        data: data,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update profile',
      );
    }
  }

  Future<String> createPhotographerProfile({
    required String bio,
    required String city,
    required String area,
    required List<String> specialties,
    double? startingPrice,
    String? currency,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.photographers,
        data: {
          'bio': bio,
          'location': {'city': city, 'area': area},
          'specialties': specialties,
          if (startingPrice != null) 'startingPrice': startingPrice,
          if (currency != null) 'currency': currency,
        },
      );

      return response.data['data']['_id'];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create photographer profile',
      );
    }
  }

  @override
  Future<void> submitVerification({
    required String photographerId,
    required String idCardUrl,
    required List<String> portfolioSamples,
  }) async {
    try {
      await apiClient.post(
        ApiEndpoints.submitVerification,
        data: {
          'photographerId': photographerId,
          'documents': {
            'idCard': idCardUrl,
            'portfolioSamples': portfolioSamples,
          },
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to submit verification',
      );
    }
  }
}
