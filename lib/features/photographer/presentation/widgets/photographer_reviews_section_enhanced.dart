import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';
import 'package:hajzy/features/auth/presentation/providers/auth_provider.dart';
import 'package:hajzy/features/photographer/domain/entities/photographer.dart';
import 'package:hajzy/features/photographer/presentation/pages/photographer_reviews_page.dart';
import 'package:hajzy/features/review/presentation/providers/review_provider.dart';
import 'package:hajzy/shared/widgets/reviews/review_card.dart';
import 'package:hajzy/shared/widgets/loading/loading_indicator.dart';

class PhotographerReviewsSectionEnhanced extends ConsumerStatefulWidget {
  final Photographer photographer;

  const PhotographerReviewsSectionEnhanced({
    super.key,
    required this.photographer,
  });

  @override
  ConsumerState<PhotographerReviewsSectionEnhanced> createState() =>
      _PhotographerReviewsSectionEnhancedState();
}

class _PhotographerReviewsSectionEnhancedState
    extends ConsumerState<PhotographerReviewsSectionEnhanced> {
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reviewProvider.notifier).getReviews(widget.photographer.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id;

    return Container(
      color: context.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with rating summary
          _buildRatingSummaryCard(state),

          const SizedBox(height: AppSpacing.md),

          // Add review section (if user is logged in and is a client)
          if (currentUserId != null && authState.user?.role == 'client')
            _buildAddReviewSection(currentUserId, state),

          const SizedBox(height: AppSpacing.md),

          // Reviews list
          _buildReviewsList(state, currentUserId),
        ],
      ),
    );
  }

  Widget _buildRatingSummaryCard(ReviewState state) {
    final totalReviews = state.reviews.length;
    final averageRating = state.averageRating;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGradientStart,
            AppColors.primaryGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientStart.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rating number
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < averageRating.floor()
                          ? Icons.star
                          : (index < averageRating && averageRating % 1 != 0)
                          ? Icons.star_half
                          : Icons.star_border,
                      color: AppColors.gold,
                      size: 24,
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$totalReviews تقييم',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Rating distribution
          Expanded(
            flex: 3,
            child: Column(
              children: List.generate(5, (index) {
                final rating = 5 - index;
                final count = state.reviews
                    .where((r) => r.rating.floor() == rating)
                    .length;
                final percentage = totalReviews > 0
                    ? (count / totalReviews)
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$rating',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star, color: AppColors.gold, size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddReviewSection(String currentUserId, ReviewState state) {
    // Check if user already reviewed
    final hasReviewed = state.reviews.any((r) => r.clientId == currentUserId);

    if (hasReviewed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: [context.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'شارك تجربتك',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Rating stars
          Row(
            children: [
              Text(
                'التقييم:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ...List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = index + 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      index < _selectedRating ? Icons.star : Icons.star_border,
                      color: AppColors.gold,
                      size: 32,
                    ),
                  ),
                );
              }),
              const Spacer(),
              Text(
                _getRatingText(_selectedRating),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryGradientStart,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Comment field
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'اكتب تعليقك هنا...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              filled: true,
              fillColor: context.background,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'نشر التقييم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'سيء جداً';
      case 2:
        return 'سيء';
      case 3:
        return 'مقبول';
      case 4:
        return 'جيد';
      case 5:
        return 'ممتاز';
      default:
        return '';
    }
  }

  Widget _buildReviewsList(ReviewState state, String? currentUserId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التقييمات (${state.reviews.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              if (state.reviews.length > 3)
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotographerReviewsPage(
                          photographerId: widget.photographer.id,
                          photographerName: widget.photographer.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('عرض الكل'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: LoadingIndicator(),
              ),
            )
          else if (state.reviews.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: context.dividerColor, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'لا توجد تقييمات بعد',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'كن أول من يقيم هذه المصورة',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: state.reviews.take(3).map((review) {
                final isOwnReview =
                    currentUserId != null && review.clientId == currentUserId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ReviewCard(
                    review: review,
                    showReplyButton: false,
                    onEdit: isOwnReview ? () => _editReview(review) : null,
                    onDelete: isOwnReview
                        ? () => _deleteReview(review.id)
                        : null,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء كتابة تعليق'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_commentController.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('التعليق يجب أن يكون 5 أحرف على الأقل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show message that review can only be added from completed bookings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('يمكنك إضافة تقييم من صفحة "حجوزاتي" بعد إكمال الحجز'),
        backgroundColor: AppColors.warning,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _editReview(review) async {
    _commentController.text = review.comment;
    _selectedRating = review.rating.toInt();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل التقييم'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRating = index + 1;
                        });
                      },
                      child: Icon(
                        index < _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.gold,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'التعليق',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'rating': _selectedRating.toDouble(),
                'comment': _commentController.text.trim(),
              });
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await ref
            .read(reviewProvider.notifier)
            .updateReview(review.id, result['rating'], result['comment']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تعديل التقييم بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل تعديل التقييم: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التقييم'),
        content: const Text('هل أنت متأكد من حذف هذا التقييم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(reviewProvider.notifier).deleteReview(reviewId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف التقييم بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل حذف التقييم: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
