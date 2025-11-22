import 'dart:io';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<UserProfile> getProfile() async {
    if (await networkInfo.isConnected) {
      try {
        final profile = await remoteDataSource.getProfile();
        await localDataSource.cacheProfile(profile);
        return profile;
      } catch (e) {
        // Try to get cached profile if remote fails
        final cachedProfile = await localDataSource.getCachedProfile();
        if (cachedProfile != null) {
          return cachedProfile;
        }
        rethrow;
      }
    } else {
      final cachedProfile = await localDataSource.getCachedProfile();
      if (cachedProfile != null) {
        return cachedProfile;
      }
      throw Exception('No internet connection and no cached data');
    }
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
  }) async {
    final profile = await remoteDataSource.updateProfile(
      name: name,
      phone: phone,
    );
    await localDataSource.cacheProfile(profile);
    return profile;
  }

  @override
  Future<String> uploadAvatar(File imageFile) async {
    return await remoteDataSource.uploadAvatar(imageFile);
  }

  @override
  Future<void> deleteAvatar() async {
    await remoteDataSource.deleteAvatar();
  }

  @override
  Future<void> updateNotificationSettings(
    NotificationSettings settings,
  ) async {
    await remoteDataSource.updateNotificationSettings(settings);
  }

  @override
  Future<void> deleteAccount() async {
    await remoteDataSource.deleteAccount();
    await localDataSource.clearCache();
  }

  @override
  Future<UserStatistics> getUserStatistics() async {
    return await remoteDataSource.getUserStatistics();
  }
}
