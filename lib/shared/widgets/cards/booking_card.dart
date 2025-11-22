import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';

class BookingCard extends StatelessWidget {
  final String photographerName;
  final String photographerImage;
  final String packageName;
  final String date;
  final String time;
  final String location;
  final String status;
  final double price;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const BookingCard({
    super.key,
    required this.photographerName,
    required this.photographerImage,
    required this.packageName,
    required this.date,
    required this.time,
    required this.location,
    required this.status,
    required this.price,
    this.onTap,
    this.onCancel,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'قيد الانتظار':
        return AppColors.warning;
      case 'confirmed':
      case 'مؤكد':
        return AppColors.success;
      case 'cancelled':
      case 'ملغي':
        return AppColors.error;
      case 'completed':
      case 'مكتمل':
        return AppColors.primaryGradientStart;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  String _getStatusText() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'cancelled':
        return 'ملغي';
      case 'completed':
        return 'مكتمل';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(photographerImage),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photographerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        packageName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            // Details
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'التاريخ',
              value: date,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              icon: Icons.access_time,
              label: 'الوقت',
              value: time,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              icon: Icons.location_on,
              label: 'الموقع',
              value: location,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Price & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$price ريال',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGradientStart,
                  ),
                ),
                if (status.toLowerCase() == 'pending' && onCancel != null)
                  TextButton(
                    onPressed: onCancel,
                    child: const Text(
                      'إلغاء الحجز',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondaryLight,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondaryLight,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }
}
