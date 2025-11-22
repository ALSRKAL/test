import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';

/// Ad Banner Component - Placeholder for Google AdMob
/// TODO: Integrate with google_mobile_ads package
class AdBanner extends StatelessWidget {
  final bool isVisible;

  const AdBanner({
    super.key,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    // Placeholder UI - Replace with actual AdMob banner
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: AppColors.textSecondaryLight.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.ad_units,
              color: AppColors.textSecondaryLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'إعلان',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
