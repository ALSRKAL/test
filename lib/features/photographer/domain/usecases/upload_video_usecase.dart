import 'dart:io';
import '../repositories/photographer_repository.dart';
import '../../../../services/media/video_service.dart';

/// Upload Video UseCase
class UploadVideoUseCase {
  final PhotographerRepository repository;

  UploadVideoUseCase(this.repository);

  Future<String> call(File video) async {
    // Validate video
    final videoService = VideoService();
    final validation = await videoService.validateVideo(video);

    if (!validation['isValid']) {
      final errors = validation['errors'] as List<String>;
      throw Exception(errors.join('\n'));
    }

    // Check constraints
    final size = validation['size'] as int;
    final duration = validation['duration'] as int;

    if (size > VideoService.maxVideoSizeBytes) {
      throw Exception(
        'Video size (${videoService.formatFileSize(size)}) exceeds maximum '
        '(${videoService.formatFileSize(VideoService.maxVideoSizeBytes)})',
      );
    }

    if (duration > VideoService.maxVideoDurationSeconds) {
      throw Exception(
        'Video duration (${videoService.formatDuration(duration)}) exceeds maximum '
        '(${videoService.formatDuration(VideoService.maxVideoDurationSeconds)})',
      );
    }

    // Upload to server (server will handle compression)
    return await repository.uploadVideo(video.path);
  }
}
