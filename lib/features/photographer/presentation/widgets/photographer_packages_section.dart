import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/constants/app_strings.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';
import 'package:hajzy/features/photographer/domain/entities/photographer.dart';

class PhotographerPackagesSection extends StatelessWidget {
  final Photographer photographer;

  const PhotographerPackagesSection({super.key, required this.photographer});

  @override
  Widget build(BuildContext context) {
    // فلترة الباقات النشطة فقط
    final activePackages = photographer.packages
        .where((p) => p.isActive)
        .toList();

    // إخفاء القسم بالكامل إذا لم يكن هناك باقات نشطة
    if (activePackages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.packages,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...activePackages.asMap().entries.map((entry) {
            final index = entry.key;
            final package = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < activePackages.length - 1 ? AppSpacing.md : 0,
              ),
              child: PackageCard(
                title: package.name,
                price:
                    '${package.price.toStringAsFixed(0)}${photographer.currency == 'USD' ? '\$' : ' ${photographer.currency == 'SAR' ? 'ر.س' : 'ر.ي'}'}',
                duration: package.duration,
                features: package.features,
                isPopular: index == 1 && activePackages.length > 2,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class PackageCard extends StatelessWidget {
  final String title;
  final String price;
  final String duration;
  final List<String> features;
  final bool isPopular;

  const PackageCard({
    super.key,
    required this.title,
    required this.price,
    required this.duration,
    required this.features,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: isPopular
              ? AppColors.primaryGradientStart
              : context.dividerColor,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [context.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Text(
                    'الأكثر طلباً',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGradientStart,
                ),
              ),
              const Spacer(),
              Text(
                duration,
                style: TextStyle(fontSize: 14, color: context.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
