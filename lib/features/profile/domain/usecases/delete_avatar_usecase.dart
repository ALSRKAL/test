import '../repositories/profile_repository.dart';

class DeleteAvatarUseCase {
  final ProfileRepository repository;

  DeleteAvatarUseCase(this.repository);

  Future<void> call() async {
    return await repository.deleteAvatar();
  }
}
