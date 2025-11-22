import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';
import 'package:hajzy/features/review/domain/entities/review.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool showReplyButton;
  final VoidCallback? onReply;
  final VoidCallback? onReport;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onEditReply;
  final VoidCallback? onDeleteReply;

  const ReviewCard({
    super.key,
    required this.review,
    this.showReplyButton = false,
    this.onReply,
    this.onReport,
    this.onEdit,
    this.onDelete,
    this.onEditReply,
    this.onDeleteReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [context.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.md),
          _buildRating(),
          const SizedBox(height: AppSpacing.sm),
          _buildComment(),
          if (review.packageName != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildPackageInfo(),
          ],
          if (review.reply != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildReply(),
          ],
          const SizedBox(height: AppSpacing.sm),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryGradientStart.withValues(alpha: 0.1),
          backgroundImage: review.clientAvatar != null && review.clientAvatar!.isNotEmpty
              ? NetworkImage(review.clientAvatar!)
              : null,
          child: review.clientAvatar == null || review.clientAvatar!.isEmpty
              ? Icon(
                  Icons.person,
                  color: AppColors.primaryGradientStart,
                  size: 24,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.clientName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeago.format(review.createdAt, locale: 'ar'),
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (review.isReported)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flag,
                  size: 12,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  'مُبلغ عنه',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRating() {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < review.rating.floor()
              ? Icons.star
              : (index < review.rating && review.rating % 1 != 0)
                  ? Icons.star_half
                  : Icons.star_border,
          color: AppColors.gold,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildComment() {
    return Builder(
      builder: (context) => Text(
        review.comment,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: context.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPackageInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryGradientStart.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: AppColors.primaryGradientStart.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.card_giftcard,
            size: 16,
            color: AppColors.primaryGradientStart,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Builder(
              builder: (context) => Text(
                review.packageName!,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (review.bookingDate != null) ...[
            const SizedBox(width: 8),
            Builder(
              builder: (context) => Icon(
                Icons.calendar_today,
                size: 12,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Builder(
              builder: (context) => Text(
                '${review.bookingDate!.day}/${review.bookingDate!.month}/${review.bookingDate!.year}',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReply() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryGradientStart.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: AppColors.primaryGradientStart.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.reply,
                size: 16,
                color: AppColors.primaryGradientStart,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'رد المصورة',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGradientStart,
                  ),
                ),
              ),
              Builder(
                builder: (context) => Text(
                  timeago.format(review.reply!.repliedAt, locale: 'ar'),
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary,
                  ),
                ),
              ),
              if (onEditReply != null || onDeleteReply != null) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppColors.textSecondaryLight,
                  ),
                  onSelected: (value) {
                    if (value == 'edit' && onEditReply != null) {
                      onEditReply!();
                    } else if (value == 'delete' && onDeleteReply != null) {
                      onDeleteReply!();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEditReply != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('تعديل'),
                          ],
                        ),
                      ),
                    if (onDeleteReply != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('حذف', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Builder(
            builder: (context) => Text(
              review.reply!.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        if (showReplyButton && review.reply == null && onReply != null)
          TextButton.icon(
            onPressed: onReply,
            icon: const Icon(Icons.reply, size: 18),
            label: const Text('رد'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryGradientStart,
            ),
          ),
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('تعديل'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryGradientStart,
            ),
          ),
        const Spacer(),
        if (onDelete != null)
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('حذف'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
          ),
        if (onReport != null && !review.isReported)
          TextButton.icon(
            onPressed: onReport,
            icon: const Icon(Icons.flag, size: 18),
            label: const Text('إبلاغ'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
          ),
      ],
    );
  }
}
