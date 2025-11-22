import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/utils/helpers.dart';
import 'package:hajzy/features/booking/presentation/providers/booking_provider.dart';
import 'package:hajzy/shared/widgets/buttons/custom_button.dart';
import 'package:hajzy/shared/widgets/errors/error_widget.dart' as custom;
import 'package:hajzy/shared/widgets/loading/loading_indicator.dart';

class BookingDetailsPage extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailsPage({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<BookingDetailsPage> createState() =>
      _BookingDetailsPageState();
}

class _BookingDetailsPageState extends ConsumerState<BookingDetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(bookingProvider.notifier).getMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);
    final booking = state.bookings.firstWhere(
      (b) => b.id == widget.bookingId,
      orElse: () => throw Exception('Booking not found'),
    );

    if (state.isLoading && state.bookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الحجز')),
        body: const Center(child: LoadingIndicator()),
      );
    }

    if (state.error != null && state.bookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الحجز')),
        body: custom.CustomErrorWidget(
          message: state.error!,
          onRetry: () {
            ref.read(bookingProvider.notifier).getMyBookings();
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الحجز'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share booking details
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(booking.status),
            const SizedBox(height: AppSpacing.lg),

            // Booking Info Card
            _buildInfoCard(
              'معلومات الحجز',
              [
                _InfoRow(
                  icon: Icons.confirmation_number,
                  label: 'رقم الحجز',
                  value: booking.id.substring(0, 8).toUpperCase(),
                ),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'التاريخ',
                  value: Helpers.formatDate(booking.date),
                ),
                _InfoRow(
                  icon: Icons.access_time,
                  label: 'الوقت',
                  value: booking.timeSlot,
                ),
                _InfoRow(
                  icon: Icons.card_giftcard,
                  label: 'الباقة',
                  value: booking.packageName,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Location Card
            if (booking.location.isNotEmpty)
              _buildInfoCard(
                'الموقع',
                [
                  _InfoRow(
                    icon: Icons.location_on,
                    label: 'العنوان',
                    value: booking.location,
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),

            // Notes Card
            if (booking.notes != null && booking.notes!.isNotEmpty)
              _buildInfoCard(
                'ملاحظات',
                [
                  _InfoRow(
                    icon: Icons.note,
                    label: 'الملاحظات',
                    value: booking.notes!,
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),

            // Price Card
            _buildPriceCard(booking.totalPrice),
            const SizedBox(height: AppSpacing.lg),

            // Action Buttons
            if (booking.status == 'pending') ...[
              OutlinedButton(
                onPressed: () => _handleCancelBooking(booking.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const Text('إلغاء الحجز'),
              ),
            ] else if (booking.status == 'confirmed') ...[
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'محادثة المصورة',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/chat/${booking.photographerId}/المصورة',
                        );
                      },
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleCancelBooking(booking.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      child: const Text('إلغاء الحجز'),
                    ),
                  ),
                ],
              ),
            ] else if (booking.status == 'completed') ...[
              CustomButton(
                text: 'تقييم المصورة',
                onPressed: () {
                  // TODO: Navigate to review page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('صفحة التقييم قريباً')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = AppColors.warning;
        statusText = 'قيد الانتظار';
        statusIcon = Icons.pending_actions;
        break;
      case 'confirmed':
        statusColor = AppColors.success;
        statusText = 'مؤكد';
        statusIcon = Icons.check_circle;
        break;
      case 'completed':
        statusColor = AppColors.primaryGradientStart;
        statusText = 'مكتمل';
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusText = 'ملغي';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.textSecondaryLight;
        statusText = status;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة الحجز',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<_InfoRow> rows) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      row.icon,
                      size: 20,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.value,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPriceCard(double price) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientStart.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'المبلغ الإجمالي',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${price.toStringAsFixed(0)} ريال',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الحجز'),
        content: const Text(
          'هل أنت متأكد من إلغاء هذا الحجز؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('رجوع'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('إلغاء الحجز'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(bookingProvider.notifier)
            .cancelBooking(bookingId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء الحجز بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل إلغاء الحجز: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}
