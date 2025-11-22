import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/utils/specialty_utils.dart';
import 'package:hajzy/features/photographer/domain/entities/photographer.dart';

class PhotographerInfoSection extends StatelessWidget {
  final Photographer photographer;

  const PhotographerInfoSection({super.key, required this.photographer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photographer.bio != null && photographer.bio!.isNotEmpty) ...[
            const Text(
              'نبذة عني',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              photographer.bio!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Specialties Section
          if (photographer.specialties.isNotEmpty) ...[
            const Text(
              'التخصصات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: photographer.specialties.map((specialty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGradientStart.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryGradientStart.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  child: Text(
                    SpecialtyUtils.translate(specialty),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryGradientStart,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${photographer.location.city}, ${photographer.location.area}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
