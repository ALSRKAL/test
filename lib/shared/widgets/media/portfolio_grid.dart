import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_spacing.dart';

class PortfolioGrid extends StatelessWidget {
  final List<String> images;
  final String? videoUrl;
  final VoidCallback? onImageTap;
  final VoidCallback? onVideoTap;

  const PortfolioGrid({
    super.key,
    required this.images,
    this.videoUrl,
    this.onImageTap,
    this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = <Widget>[];

    // Add video if exists
    if (videoUrl != null) {
      allItems.add(_buildVideoThumbnail());
    }

    // Add images
    allItems.addAll(
      images.map((url) => _buildImageItem(url)),
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
        childAspectRatio: 1,
      ),
      itemCount: allItems.length,
      itemBuilder: (context, index) => allItems[index],
    );
  }

  Widget _buildVideoThumbnail() {
    return GestureDetector(
      onTap: onVideoTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: const Icon(
              Icons.videocam,
              color: Colors.white,
              size: 40,
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(String url) {
    return GestureDetector(
      onTap: onImageTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            );
          },
        ),
      ),
    );
  }
}
