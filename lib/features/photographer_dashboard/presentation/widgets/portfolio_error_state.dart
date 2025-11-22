import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';

class PortfolioErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onCompleteProfile;
  final VoidCallback onBack;

  const PortfolioErrorState({
    super.key,
    required this.onRetry,
    required this.onCompleteProfile,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryGradientStart.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add,
                size: 64,
                color: AppColors.primaryGradientStart,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'لم يتم العثور على ملف المصور',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'يجب إكمال ملفك الشخصي كمصور أولاً\nلتتمكن من إدارة معرضك وحجوزاتك',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.getTextSecondary(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: onCompleteProfile,
                  icon: const Icon(Icons.edit),
                  label: const Text('إكمال الملف'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }
}
