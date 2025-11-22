import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/features/review/presentation/providers/review_provider.dart';
import 'package:hajzy/shared/widgets/reviews/review_card.dart';
import 'package:hajzy/shared/widgets/loading/loading_indicator.dart';
import 'package:hajzy/shared/widgets/errors/error_widget.dart' as custom;
import 'package:hajzy/shared/widgets/errors/empty_state.dart';

class ReviewsSectionPage extends ConsumerStatefulWidget {
  const ReviewsSectionPage({super.key});

  @override
  ConsumerState<ReviewsSectionPage> createState() => _ReviewsSectionPageState();
}

class _ReviewsSectionPageState extends ConsumerState<ReviewsSectionPage> {
  String _filterRating = 'all'; // all, 5, 4, 3, 2, 1
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reviewProvider.notifier).getPhotographerReviews();
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقييمات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(reviewProvider.notifier).getPhotographerReviews();
            },
          ),
        ],
      ),
      body: state.isLoading && state.reviews.isEmpty
          ? const Center(child: LoadingIndicator())
          : state.error != null && state.reviews.isEmpty
              ? custom.CustomErrorWidget(
                  message: state.error!,
                  onRetry: () {
                    ref.read(reviewProvider.notifier).getPhotographerReviews();
                  },
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildRatingSummary(state),
                    ),
                    SliverToBoxAdapter(
                      child: _buildFilterChips(),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: _buildReviewsList(state),
                    ),
                  ],
                ),
    );
  }

  Widget _buildRatingSummary(dynamic state) {
    final reviews = state.reviews;
    final totalReviews = reviews.length;
    
    // Calculate average rating
    double averageRating = 0.0;
    if (totalReviews > 0) {
      double sum = 0.0;
      for (var review in reviews) {
        sum += review.rating;
      }
      averageRating = sum / totalReviews;
    }

    // Calculate rating distribution
    final ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in reviews) {
      final rating = review.rating.floor();
      ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGradientStart,
            AppColors.primaryGradientEnd,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            averageRating.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Icon(
                index < averageRating.floor()
                    ? Icons.star
                    : (index < averageRating && averageRating % 1 != 0)
                        ? Icons.star_half
                        : Icons.star_border,
                color: AppColors.gold,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'بناءً على $totalReviews تقييم',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          if (totalReviews > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildRatingBars(ratingCounts, totalReviews),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingBars(Map<int, int> ratingCounts, int totalReviews) {
    return Column(
      children: [
        _buildRatingBar(5, ratingCounts[5]!, totalReviews),
        _buildRatingBar(4, ratingCounts[4]!, totalReviews),
        _buildRatingBar(3, ratingCounts[3]!, totalReviews),
        _buildRatingBar(2, ratingCounts[2]!, totalReviews),
        _buildRatingBar(1, ratingCounts[1]!, totalReviews),
      ],
    );
  }

  Widget _buildRatingBar(int stars, int count, int totalReviews) {
    final percentage = totalReviews > 0 ? (count / totalReviews * 100).round() : 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$stars',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.star,
            color: AppColors.gold,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalReviews > 0 ? count / totalReviews : 0,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$percentage%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('الكل', 'all'),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip('5 نجوم', '5'),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip('4 نجوم', '4'),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip('3 نجوم', '3'),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip('2 نجوم', '2'),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip('1 نجمة', '1'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterRating == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterRating = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGradientStart
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGradientStart
                : AppColors.getTextSecondary(context).withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.getTextPrimary(context),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList(dynamic state) {
    var reviews = state.reviews;

    // Filter by rating
    if (_filterRating != 'all') {
      final filterValue = int.parse(_filterRating);
      reviews = reviews.where((r) => r.rating.floor() == filterValue).toList();
    }

    if (reviews.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.rate_review,
          message: _filterRating == 'all'
              ? 'لا توجد تقييمات بعد'
              : 'لا توجد تقييمات بـ $_filterRating نجوم',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return ReviewCard(
          review: review,
          showReplyButton: true,
          onReply: () => _replyToReview(review.id),
          onReport: () => _reportReview(review.id),
          onEditReply: review.reply != null ? () => _editReply(review.id, review.reply!.text) : null,
          onDeleteReply: review.reply != null ? () => _deleteReply(review.id) : null,
        );
      },
    );
  }

  void _replyToReview(String reviewId) {
    _replyController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الرد على التقييم'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _replyController,
                decoration: const InputDecoration(
                  hintText: 'اكتب ردك...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 500,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_replyController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء كتابة رد'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await ref.read(reviewProvider.notifier).replyToReview(
                      reviewId,
                      _replyController.text.trim(),
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال الرد بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل إرسال الرد: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _reportReview(String reviewId) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إبلاغ عن التقييم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الرجاء تحديد سبب الإبلاغ:'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'السبب...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء تحديد سبب الإبلاغ'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await ref.read(reviewProvider.notifier).reportReview(
                      reviewId,
                      reasonController.text.trim(),
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال البلاغ بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل إرسال البلاغ: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('إبلاغ'),
          ),
        ],
      ),
    );
  }

  void _editReply(String reviewId, String currentReply) {
    _replyController.text = currentReply;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الرد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _replyController,
                decoration: const InputDecoration(
                  hintText: 'اكتب ردك...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 500,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_replyController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء كتابة رد'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await ref.read(reviewProvider.notifier).replyToReview(
                      reviewId,
                      _replyController.text.trim(),
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تعديل الرد بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل تعديل الرد: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteReply(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الرد'),
        content: const Text('هل أنت متأكد من حذف هذا الرد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // To delete a reply, we send an empty reply
        await ref.read(reviewProvider.notifier).replyToReview(reviewId, '');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الرد بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل حذف الرد: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
