import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hajzy/core/constants/app_colors.dart';

class PortfolioHelpers {
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static Future<File?> pickVideo(ImagePicker picker) async {
    try {
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );

      if (video == null) return null;

      final file = File(video.path);
      final fileSize = await file.length();
      
      // Check file size (100MB max)
      if (fileSize > 100 * 1024 * 1024) {
        return null; // Caller should show error
      }

      return file;
    } catch (e) {
      return null;
    }
  }

  static Future<List<File>?> pickImages(ImagePicker picker) async {
    try {
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isEmpty) return null;

      return images.map((xfile) => File(xfile.path)).toList();
    } catch (e) {
      return null;
    }
  }

  static bool validateImageCount(int currentCount, int newCount, int maxCount) {
    return currentCount + newCount <= maxCount;
  }

  static int getRemainingSlots(int currentCount, int maxCount) {
    return maxCount - currentCount;
  }
}
