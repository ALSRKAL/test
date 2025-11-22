import 'dart:io';
import '../repositories/photographer_repository.dart';
import '../../../../services/media/image_service.dart';

/// Upload Images UseCase
class UploadImagesUseCase {
  final PhotographerRepository repository;

  UploadImagesUseCase(this.repository);

  Future<List<String>> call(List<File> images) async {
    // Validation
    if (images.isEmpty) {
      throw Exception('No images selected');
    }

    if (images.length > 20) {
      throw Exception('Maximum 20 images allowed');
    }

    // Compress images
    final imageService = ImageService();
    final compressedImages = <File>[];

    for (final image in images) {
      try {
        final compressed = await imageService.compressImage(
          image,
          quality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );

        if (compressed != null) {
          compressedImages.add(compressed);
        } else {
          compressedImages.add(image);
        }
      } catch (e) {
        // Error compressing image, use original
        compressedImages.add(image);
      }
    }

    // Upload to server (convert File to path)
    final imagePaths = compressedImages.map((file) => file.path).toList();
    return await repository.uploadImages(imagePaths);
  }
}
