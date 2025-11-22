import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';
import 'package:hajzy/core/utils/specialty_utils.dart';

class PhotographerCardEnhanced extends StatelessWidget {
  final String id;
  final String name;
  final List<String> specialties;
  final String? coverImageUrl;
  final String? avatarUrl;
  final double rating;
  final int reviewCount;
  final String? location;
  final String? priceRange;
  final bool isFeatured;
  final bool isFavorite;
  final bool isVerified;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final int? viewCount;
  final String? subscriptionPlan;

  const PhotographerCardEnhanced({
    super.key,
    required this.id,
    required this.name,
    required this.specialties,
    this.coverImageUrl,
    this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    this.location,
    this.priceRange,
    this.isFeatured = false,
    this.isFavorite = false,
    this.isVerified = false,
    this.onTap,
    this.onFavorite,
    this.viewCount,
    this.subscriptionPlan,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: _getPlanDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(context),
            Expanded(child: _buildContentSection(context)),
          ],
        ),
      ),
    );
  }

  BoxDecoration _getPlanDecoration(BuildContext context) {
    final baseDecoration = BoxDecoration(
      color: context.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    if (subscriptionPlan == 'pro') {
      return baseDecoration.copyWith(
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (subscriptionPlan == 'premium') {
      return baseDecoration.copyWith(
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC0C0C0).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }

    return baseDecoration;
  }

  Widget _buildImageSection(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            height: 130, // Reduced height to prevent overflow
            width: double.infinity,
            color: AppColors.primaryGradientStart.withValues(alpha: 0.1),
            child: coverImageUrl != null && coverImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: coverImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.primaryGradientStart.withValues(
                        alpha: 0.1,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                    memCacheWidth: 400,
                    memCacheHeight: 300,
                  )
                : _buildPlaceholder(),
          ),
        ),

        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),

        // Plan Badge
        if (subscriptionPlan == 'pro' || subscriptionPlan == 'premium')
          Positioned(top: 12, right: 12, child: _buildPlanBadge()),

        // Featured Badge (only if not showing plan badge or if needed)
        if (isFeatured &&
            subscriptionPlan != 'pro' &&
            subscriptionPlan != 'premium')
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'مميزة',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Favorite Button
        Positioned(
          top: 12,
          left: 12,
          child: GestureDetector(
            onTap: onFavorite,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: isFavorite ? Colors.red : Colors.grey[600],
              ),
            ),
          ),
        ),

        // Profile Avatar
        Positioned(
          bottom: -20,
          right: 16, // Arabic layout, so right is start
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.surface, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryGradientStart.withValues(
                alpha: 0.1,
              ),
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? const Icon(
                      Icons.person,
                      color: AppColors.primaryGradientStart,
                      size: 24,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanBadge() {
    final isPro = subscriptionPlan == 'pro';
    final color = isPro ? const Color(0xFFFFD700) : const Color(0xFFC0C0C0);
    final label = isPro ? 'محترف' : 'مميز';
    final icon = isPro ? Icons.verified : Icons.star;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryGradientStart.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(
          Icons.camera_alt,
          size: 40,
          color: AppColors.primaryGradientStart,
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 10), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Verification
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14, // Slightly smaller
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isVerified)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.verified,
                    size: 16,
                    color: AppColors.primaryGradientStart,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2), // Reduced spacing
          // Specialty
          Text(
            SpecialtyUtils.format(specialties),
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4), // Reduced spacing
          // Rating and Location
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: Color(0xFFFFB300),
              ),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              Text(
                ' ($reviewCount)',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSecondary.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              if (location != null && location!.isNotEmpty) ...[
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: context.textSecondary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    location!,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondary.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          const Spacer(),

          // Price and Views
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: context.textSecondary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                if (priceRange != null && priceRange!.isNotEmpty)
                  Expanded(
                    child: Text(
                      priceRange!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGradientStart,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (viewCount != null && viewCount! > 0)
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: context.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$viewCount',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondary.withValues(alpha: 0.5),
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
