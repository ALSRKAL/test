import '../repositories/photographer_repository.dart';

/// Delete Media UseCase
class DeleteMediaUseCase {
  final PhotographerRepository repository;

  DeleteMediaUseCase(this.repository);

  Future<void> call({
    required String mediaId,
    required String mediaType, // 'image' or 'video'
  }) async {
    // Validation
    if (mediaId.isEmpty) {
      throw Exception('Media ID is required');
    }

    if (!['image', 'video'].contains(mediaType)) {
      throw Exception('Invalid media type. Must be "image" or "video"');
    }

    // Delete from server
    if (mediaType == 'image') {
      await repository.deleteImage(mediaId);
    } else {
      await repository.deleteVideo();
    }
  }
}
