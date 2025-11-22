import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';
import 'package:hajzy/features/photographer/presentation/providers/portfolio_provider.dart';

class PortfolioImagesSection extends StatelessWidget {
  final List<dynamic> images;
  final int imageCount;
  final PortfolioState portfolioState;
  final VoidCallback onAddImages;
  final Function(String) onDeleteImage;
  final Function(dynamic, int) onImageTap;

  const PortfolioImagesSection({
    super.key,
    required this.images,
    required this.imageCount,
    required this.portfolioState,
    required this.onAddImages,
    required this.onDeleteImage,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: imageCount > 0
              ? AppColors.primaryGradientStart.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: imageCount > 0
                ? AppColors.primaryGradientStart.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (portfolioState.isUploading && portfolioState.uploadingType == 'image') ...[
            const SizedBox(height: AppSpacing.md),
            _UploadProgress(portfolioState: portfolioState),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (images.isEmpty && !portfolioState.isUploading)
            _EmptyImagesState(onAddImages: onAddImages, isUploading: portfolioState.isUploading)
          else
            _ImagesGrid(
              images: images,
              imageCount: imageCount,
              portfolioState: portfolioState,
              onAddImages: onAddImages,
              onDeleteImage: onDeleteImage,
              onImageTap: onImageTap,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryGradientStart.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.photo_library,
            color: AppColors.primaryGradientStart,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'معرض الصور',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: imageCount >= 20
                          ? AppColors.error.withOpacity(0.1)
                          : imageCount >= 10
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$imageCount/20',
                      style: TextStyle(
                        fontSize: 14,
                        color: imageCount >= 20
                            ? AppColors.error
                            : imageCount >= 10
                                ? AppColors.success
                                : AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'حد أقصى 20 صورة • 10MB لكل صورة',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyImagesState extends StatelessWidget {
  final VoidCallback onAddImages;
  final bool isUploading;

  const _EmptyImagesState({
    required this.onAddImages,
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.getTextSecondary(context).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: AppColors.getTextSecondary(context),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'لا توجد صور في المعرض',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة صور لأعمالك لجذب المزيد من العملاء',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: isUploading ? null : onAddImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('إضافة صور'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagesGrid extends StatelessWidget {
  final List<dynamic> images;
  final int imageCount;
  final PortfolioState portfolioState;
  final VoidCallback onAddImages;
  final Function(String) onDeleteImage;
  final Function(dynamic, int) onImageTap;

  const _ImagesGrid({
    required this.images,
    required this.imageCount,
    required this.portfolioState,
    required this.onAddImages,
    required this.onDeleteImage,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: images.length + (imageCount < 20 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == images.length) {
          return _AddImageButton(
            currentCount: imageCount,
            isUploading: portfolioState.isUploading,
            onTap: onAddImages,
          );
        }
        return _ImageItem(
          image: images[index],
          index: index,
          isDeleting: portfolioState.isDeleting(images[index].id ?? images[index].publicId),
          onDelete: () => onDeleteImage(images[index].id ?? images[index].publicId),
          onTap: () => onImageTap(images[index], index),
        );
      },
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final int currentCount;
  final bool isUploading;
  final VoidCallback onTap;

  const _AddImageButton({
    required this.currentCount,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canAdd = currentCount < 20 && !isUploading;
    final remaining = 20 - currentCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canAdd ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          decoration: BoxDecoration(
            gradient: canAdd
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryGradientStart.withOpacity(0.1),
                      AppColors.primaryGradientEnd.withOpacity(0.1),
                    ],
                  )
                : null,
            color: canAdd ? null : Colors.grey[200],
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: canAdd
                  ? AppColors.primaryGradientStart.withOpacity(0.4)
                  : Colors.grey[400]!,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: canAdd
                      ? AppColors.primaryGradientStart.withOpacity(0.15)
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  canAdd ? Icons.add_photo_alternate : Icons.check_circle,
                  size: 28,
                  color: canAdd
                      ? AppColors.primaryGradientStart
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                canAdd ? 'إضافة' : 'مكتمل',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: canAdd ? Colors.black87 : Colors.grey[600],
                ),
              ),
              if (canAdd && remaining <= 5) ...[
                const SizedBox(height: 2),
                Text(
                  'متبقي $remaining',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageItem extends StatelessWidget {
  final dynamic image;
  final int index;
  final bool isDeleting;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ImageItem({
    required this.image,
    required this.index,
    required this.isDeleting,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isDeleting ? 0.8 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: isDeleting ? 0.3 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Hero(
          tag: 'portfolio_image_$index',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDeleting ? null : onTap,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      child: CachedNetworkImage(
                        imageUrl: image.url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryGradientStart,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isDeleting)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.medium),
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                    if (!isDeleting)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadProgress extends StatelessWidget {
  final PortfolioState portfolioState;

  const _UploadProgress({required this.portfolioState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGradientStart.withOpacity(0.05),
            AppColors.primaryGradientEnd.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.primaryGradientStart.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGradientStart.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryGradientStart,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      portfolioState.uploadingType == 'video'
                          ? 'جاري رفع الفيديو...'
                          : 'جاري رفع الصور...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'الرجاء الانتظار، لا تغلق الصفحة',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGradientStart,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(portfolioState.uploadProgress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: portfolioState.uploadProgress,
              minHeight: 8,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryGradientStart,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
