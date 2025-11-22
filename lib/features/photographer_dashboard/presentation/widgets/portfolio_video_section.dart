import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';
import 'package:hajzy/shared/widgets/media/video_player_widget.dart';
import 'package:hajzy/features/photographer/presentation/providers/portfolio_provider.dart';

class PortfolioVideoSection extends StatelessWidget {
  final dynamic video;
  final PortfolioState portfolioState;
  final VoidCallback onUpload;
  final Function(String) onDelete;

  const PortfolioVideoSection({
    super.key,
    required this.video,
    required this.portfolioState,
    required this.onUpload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasVideo = video != null && 
                     video.url != null && 
                     video.url.toString().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: hasVideo 
              ? AppColors.primaryGradientStart.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasVideo
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
          const SizedBox(height: AppSpacing.lg),
          if (hasVideo)
            _VideoPreview(
              video: video,
              isDeleting: portfolioState.isDeleting('video'),
              onDelete: () => onDelete(video.publicId),
            )
          else
            _VideoUploadButton(
              isUploading: portfolioState.isUploading,
              onUpload: onUpload,
            ),
          if (portfolioState.isUploading && portfolioState.uploadingType == 'video') ...[
            const SizedBox(height: AppSpacing.md),
            _UploadProgress(portfolioState: portfolioState),
          ],
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
            Icons.videocam,
            color: AppColors.primaryGradientStart,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الفيديو التعريفي',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'فيديو واحد • حد أقصى 100MB • مدة 2 دقيقة',
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

class _VideoPreview extends StatelessWidget {
  final dynamic video;
  final bool isDeleting;
  final VoidCallback onDelete;

  const _VideoPreview({
    required this.video,
    required this.isDeleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isDeleting ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: isDeleting ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                VideoPlayerWidget(
                  videoUrl: video.url,
                  autoPlay: false,
                  showControls: !isDeleting,
                ),
                if (isDeleting)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        color: Colors.black.withOpacity(0.6),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'جاري حذف الفيديو...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!isDeleting)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 20,
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
    );
  }
}

class _VideoUploadButton extends StatelessWidget {
  final bool isUploading;
  final VoidCallback onUpload;

  const _VideoUploadButton({
    required this.isUploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUploading ? null : onUpload,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isUploading
                  ? [Colors.grey[200]!, Colors.grey[300]!]
                  : [
                      AppColors.primaryGradientStart.withOpacity(0.05),
                      AppColors.primaryGradientEnd.withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: isUploading
                  ? Colors.grey[400]!
                  : AppColors.primaryGradientStart.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isUploading
                      ? Colors.grey[300]
                      : AppColors.primaryGradientStart.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.videocam_outlined,
                  size: 48,
                  color: isUploading
                      ? Colors.grey[600]
                      : AppColors.primaryGradientStart,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isUploading ? 'جاري الرفع...' : 'اضغط لرفع فيديو تعريفي',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isUploading ? Colors.grey[600] : context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isUploading ? Colors.grey[200] : context.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isUploading
                        ? Colors.grey[400]!
                        : context.textSecondary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  'MP4, MOV, AVI • حد أقصى 100MB • مدة 2 دقيقة',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUploading ? Colors.grey[600] : context.textSecondary,
                  ),
                ),
              ),
            ],
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
