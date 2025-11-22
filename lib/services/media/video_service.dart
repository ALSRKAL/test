import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// Service for handling video operations
class VideoService {
  static final VideoService _instance = VideoService._internal();
  factory VideoService() => _instance;
  VideoService._internal();

  final ImagePicker _picker = ImagePicker();

  // Video constraints
  static const int maxVideoSizeBytes = 100 * 1024 * 1024; // 100MB
  static const int maxVideoDurationSeconds = 120; // 2 minutes

  /// Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: maxVideoDurationSeconds),
      );

      if (video == null) return null;

      final file = File(video.path);

      // Check file size
      final size = await file.length();
      if (size > maxVideoSizeBytes) {
        throw Exception(
            'Video size exceeds maximum allowed size of ${formatFileSize(maxVideoSizeBytes)}');
      }

      // Check duration
      final duration = await getVideoDuration(file);
      if (duration > maxVideoDurationSeconds) {
        throw Exception(
            'Video duration exceeds maximum allowed duration of $maxVideoDurationSeconds seconds');
      }

      return file;
    } catch (e) {
      print('Error picking video: $e');
      rethrow;
    }
  }

  /// Pick video from camera
  Future<File?> pickVideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: maxVideoDurationSeconds),
      );

      if (video == null) return null;

      final file = File(video.path);

      // Check file size
      final size = await file.length();
      if (size > maxVideoSizeBytes) {
        throw Exception(
            'Video size exceeds maximum allowed size of ${formatFileSize(maxVideoSizeBytes)}');
      }

      return file;
    } catch (e) {
      print('Error recording video: $e');
      rethrow;
    }
  }

  /// Get video duration in seconds
  Future<int> getVideoDuration(File file) async {
    try {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      final duration = controller.value.duration.inSeconds;
      await controller.dispose();
      return duration;
    } catch (e) {
      print('Error getting video duration: $e');
      return 0;
    }
  }

  /// Get video size in bytes
  Future<int> getVideoSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      print('Error getting video size: $e');
      return 0;
    }
  }

  /// Format file size to human readable string
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Format duration to human readable string
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Validate video file
  Future<Map<String, dynamic>> validateVideo(File file) async {
    final size = await getVideoSize(file);
    final duration = await getVideoDuration(file);

    final isValidSize = size <= maxVideoSizeBytes;
    final isValidDuration = duration <= maxVideoDurationSeconds;

    return {
      'isValid': isValidSize && isValidDuration,
      'size': size,
      'duration': duration,
      'sizeFormatted': formatFileSize(size),
      'durationFormatted': formatDuration(duration),
      'errors': [
        if (!isValidSize)
          'Video size (${formatFileSize(size)}) exceeds maximum (${formatFileSize(maxVideoSizeBytes)})',
        if (!isValidDuration)
          'Video duration (${formatDuration(duration)}) exceeds maximum (${formatDuration(maxVideoDurationSeconds)})',
      ],
    };
  }
}
