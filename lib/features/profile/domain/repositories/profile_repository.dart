import 'dart:io';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
  });
  Future<String> uploadAvatar(File imageFile);
  Future<void> deleteAvatar();
  Future<void> updateNotificationSettings(
    NotificationSettings settings,
  );
  Future<void> deleteAccount();
  Future<UserStatistics> getUserStatistics();
}
