import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<UserProfile> call({
    String? name,
    String? phone,
  }) async {
    return await repository.updateProfile(
      name: name,
      phone: phone,
    );
  }
}
