import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/constants/app_strings.dart';
import 'package:hajzy/features/photographer/domain/entities/photographer.dart';
import 'package:hajzy/features/photographer/presentation/pages/full_portfolio_page.dart';
import 'package:hajzy/shared/widgets/media/video_player_widget.dart';

/// قسم معرض الأعمال الاحترافي للمصور
/// يعرض الصور والفيديوهات بتصميم أنيق ومنظم
class PhotographerPortfolioSection extends StatelessWidget {
  final Photographer photographer;

  const PhotographerPortfolioSection({
    super.key,
    required this.photographer,
  });

  @override
  Widget build(BuildContext context) {
    // إخفاء القسم إذا لم يكن هناك محتوى
    if (photographer.portfolio.images.isEmpty &&
        photographer.portfolio.video == null) {
      return const SizedBox.shrink();
    }

    final hasVideo = photographer.portfolio.video != null;
    final hasImages = photographer.portfolio.images.isNotEmpty;
    final totalItems = photographer.portfolio.images.length + (hasVideo ? 1 : 0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeader(context, totalItems),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Portfolio Content
          if (hasVideo && hasImages)
            _buildMixedPortfolio(context)
          else if (hasVideo)
            _buildVideoOnlyPortfolio(context)
          else
            _buildImagesOnlyPortfolio(context),
        ],
      ),
    );
  }

  /// بناء رأس القسم مع العنوان وزر عرض الكل
  Widget _buildHeader(BuildContext context, int totalItems) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.portfolio,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalItems ${totalItems == 1 ? 'عمل' : 'أعمال'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (totalItems > 4)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToFullPortfolio(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'عرض الكل',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// بناء معرض مختلط (فيديو + صور)
  Widget _buildMixedPortfolio(BuildContext context) {
    return Column(
      children: [
        // Featured Video
        _buildFeaturedVideo(context),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Images Grid Preview
        _buildImagesGrid(context),
      ],
    );
  }

  /// بناء معرض الفيديو فقط
  Widget _buildVideoOnlyPortfolio(BuildContext context) {
    return _buildFeaturedVideo(context);
  }

  /// بناء معرض الصور فقط
  Widget _buildImagesOnlyPortfolio(BuildContext context) {
    return _buildImagesGrid(context);
  }

  /// بناء الفيديو المميز
  Widget _buildFeaturedVideo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GestureDetector(
        onTap: () => _navigateToFullPortfolio(context),
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Video Player
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: VideoPlayerWidget(
                  videoUrl: photographer.portfolio.video!.url,
                  autoPlay: false,
                ),
              ),
              
              // Video Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'فيديو',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء شبكة الصور
  Widget _buildImagesGrid(BuildContext context) {
    final displayImages = photographer.portfolio.images.take(6).toList();
    final remainingCount = photographer.portfolio.images.length - 6;

    return SizedBox(
      height: 280,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        scrollDirection: Axis.horizontal,
        itemCount: displayImages.length,
        itemBuilder: (context, index) {
          final image = displayImages[index];
          final isLast = index == displayImages.length - 1 && remainingCount > 0;
          
          return _buildImageCard(
            context,
            image.url,
            index,
            isLast: isLast,
            remainingCount: remainingCount,
          );
        },
      ),
    );
  }

  /// بناء بطاقة الصورة
  Widget _buildImageCard(
    BuildContext context,
    String imageUrl,
    int index, {
    bool isLast = false,
    int remainingCount = 0,
  }) {
    return GestureDetector(
      onTap: () => _navigateToFullPortfolio(context, initialIndex: index),
      child: Hero(
        tag: 'portfolio_image_$index',
        child: Container(
          width: 200,
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image with caching
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                  memCacheWidth: 600,
                  memCacheHeight: 400,
                ),
              ),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              
              // More Images Overlay
              if (isLast && remainingCount > 0)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '+$remainingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'المزيد',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// الانتقال إلى صفحة المعرض الكامل
  void _navigateToFullPortfolio(BuildContext context, {int initialIndex = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullPortfolioPage(
          photographer: photographer,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}
