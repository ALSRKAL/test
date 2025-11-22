import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/user_profile.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile();
  Future<UserProfileModel> updateProfile({String? name, String? phone});
  Future<String> uploadAvatar(File imageFile);
  Future<void> deleteAvatar();
  Future<void> updateNotificationSettings(NotificationSettings settings);
  Future<void> deleteAccount();
  Future<UserStatistics> getUserStatistics();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient apiClient;

  ProfileRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserProfileModel> getProfile() async {
    final response = await apiClient.get(ApiEndpoints.profile);
    return UserProfileModel.fromJson(response.data['data']);
  }

  @override
  Future<UserProfileModel> updateProfile({String? name, String? phone}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;

    final response = await apiClient.put(
      ApiEndpoints.profile,
      data: data,
    );
    return UserProfileModel.fromJson(response.data['data']);
  }

  @override
  Future<String> uploadAvatar(File imageFile) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'avatar.jpg',
      ),
    });

    // Use longer timeout for avatar upload (2 minutes)
    final response = await apiClient.post(
      ApiEndpoints.uploadAvatar,
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );

    return response.data['data']['avatar'];
  }

  @override
  Future<void> deleteAvatar() async {
    await apiClient.delete(ApiEndpoints.deleteAvatar);
  }

  @override
  Future<void> updateNotificationSettings(
    NotificationSettings settings,
  ) async {
    await apiClient.put(
      ApiEndpoints.notificationSettings,
      data: {
        'notificationSettings': {
          'messages': settings.messages,
          'bookings': settings.bookings,
          'reviews': settings.reviews,
        },
      },
    );
  }

  @override
  Future<void> deleteAccount() async {
    await apiClient.delete(ApiEndpoints.deleteAccount);
  }

  @override
  Future<UserStatistics> getUserStatistics() async {
    final response = await apiClient.get(ApiEndpoints.userStatistics);
    return UserStatisticsModel.fromJson(response.data['data']);
  }
}
