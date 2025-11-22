import 'dart:io';
import '../repositories/profile_repository.dart';

class UploadAvatarUseCase {
  final ProfileRepository repository;

  UploadAvatarUseCase(this.repository);

  Future<String> call(File imageFile) async {
    return await repository.uploadAvatar(imageFile);
  }
}
