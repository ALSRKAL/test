import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/utils/specialty_utils.dart';
import 'package:hajzy/features/photographer/domain/entities/photographer.dart';
import 'package:hajzy/features/photographer/presentation/pages/photographer_reviews_page.dart';
import 'package:hajzy/shared/widgets/common/rating_component.dart';

class PhotographerHeader extends StatelessWidget {
  final Photographer photographer;

  const PhotographerHeader({super.key, required this.photographer});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = photographer.avatar ?? 'https://via.placeholder.com/150';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(avatarUrl),
            onBackgroundImageError: (exception, stackTrace) {},
            child: avatarUrl.contains('placeholder')
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        photographer.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (photographer.isVerified)
                      const Icon(
                        Icons.verified,
                        color: AppColors.primaryGradientStart,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  SpecialtyUtils.format(photographer.specialties),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhotographerReviewsPage(
                              photographerId: photographer.id,
                              photographerName: photographer.name,
                            ),
                          ),
                        );
                      },
                      child: RatingComponent(
                        rating: photographer.rating.average,
                        reviewCount: photographer.rating.count,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(
                          context,
                        ).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textSecondaryLight.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${photographer.stats.views} مشاهدة',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
