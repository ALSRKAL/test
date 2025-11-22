import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/features/review/presentation/providers/review_provider.dart';
import 'package:hajzy/shared/widgets/reviews/review_card.dart';
import 'package:hajzy/shared/widgets/loading/loading_indicator.dart';
import 'package:hajzy/shared/widgets/errors/error_widget.dart' as custom;
import 'package:hajzy/shared/widgets/errors/empty_state.dart';

class PhotographerReviewsPage extends ConsumerStatefulWidget {
  final String photographerId;
  final String photographerName;

  const PhotographerReviewsPage({
    super.key,
    required this.photographerId,
    required this.photographerName,
  });

  @override
  ConsumerState<PhotographerReviewsPage> createState() =>
      _PhotographerReviewsPageState();
}

class _PhotographerReviewsPageState
    extends ConsumerState<PhotographerReviewsPage> {
  String _filterRating = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reviewProvider.notifier).getReviews(widget.photographerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('تقييمات ${widget.photographerName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(reviewProvider.notifier).getReviews(widget.photographerId);
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
                    ref.read(reviewProvider.notifier).getReviews(widget.photographerId);
                  },
                )
              : Column(
                  children: [
                    _buildRatingSummary(state),
                    _buildFilterChips(),
                    Expanded(
                      child: _buildReviewsList(state),
                    ),
                  ],
                ),
    );
  }

  Widget _buildRatingSummary(ReviewState state) {
    final reviews = state.reviews;
    final totalReviews = reviews.length;
    final averageRating = state.averageRating;

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
            style: const TextStyle(
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
            style: const TextStyle(
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
            style: const TextStyle(
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
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGradientStart
                : AppColors.textSecondaryLight.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimaryLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList(ReviewState state) {
    var reviews = state.reviews;

    // Filter by rating
    if (_filterRating != 'all') {
      final filterValue = int.parse(_filterRating);
      reviews = reviews.where((r) => r.rating.floor() == filterValue).toList();
    }

    if (reviews.isEmpty) {
      return EmptyState(
        icon: Icons.rate_review,
        message: _filterRating == 'all'
            ? 'لا توجد تقييمات بعد'
            : 'لا توجد تقييمات بـ $_filterRating نجوم',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(reviewProvider.notifier).getReviews(widget.photographerId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          return ReviewCard(
            review: review,
            showReplyButton: false,
          );
        },
      ),
    );
  }
}
