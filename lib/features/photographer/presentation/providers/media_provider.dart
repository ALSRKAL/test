import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/upload_images_usecase.dart';
import '../../domain/usecases/upload_video_usecase.dart';
import '../../domain/usecases/delete_media_usecase.dart';
import './photographer_provider.dart';

// Upload Images UseCase Provider
final uploadImagesUseCaseProvider = Provider<UploadImagesUseCase>((ref) {
  return UploadImagesUseCase(
    ref.watch(photographerRepositoryProvider),
  );
});

// Upload Video UseCase Provider
final uploadVideoUseCaseProvider = Provider<UploadVideoUseCase>((ref) {
  return UploadVideoUseCase(
    ref.watch(photographerRepositoryProvider),
  );
});

// Delete Media UseCase Provider
final deleteMediaUseCaseProvider = Provider<DeleteMediaUseCase>((ref) {
  return DeleteMediaUseCase(
    ref.watch(photographerRepositoryProvider),
  );
});
