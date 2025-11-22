import 'package:hive/hive.dart';
import '../models/user_profile_model.dart';

abstract class ProfileLocalDataSource {
  Future<UserProfileModel?> getCachedProfile();
  Future<void> cacheProfile(UserProfileModel profile);
  Future<void> clearCache();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  static const String _profileBoxName = 'user_profile';
  static const String _profileKey = 'current_profile';

  @override
  Future<UserProfileModel?> getCachedProfile() async {
    final box = await Hive.openBox(_profileBoxName);
    final data = box.get(_profileKey);
    
    if (data == null) return null;
    
    return UserProfileModel.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> cacheProfile(UserProfileModel profile) async {
    final box = await Hive.openBox(_profileBoxName);
    await box.put(_profileKey, profile.toJson());
  }

  @override
  Future<void> clearCache() async {
    final box = await Hive.openBox(_profileBoxName);
    await box.clear();
  }
}
