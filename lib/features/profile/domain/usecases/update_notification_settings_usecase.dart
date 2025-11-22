import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateNotificationSettingsUseCase {
  final ProfileRepository repository;

  UpdateNotificationSettingsUseCase(this.repository);

  Future<void> call(NotificationSettings settings) async {
    return await repository.updateNotificationSettings(settings);
  }
}
