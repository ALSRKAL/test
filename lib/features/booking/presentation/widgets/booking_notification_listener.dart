import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/features/booking/presentation/providers/booking_notifications_provider.dart';
import 'package:hajzy/features/booking/presentation/providers/booking_provider.dart';

/// Widget that listens to booking notifications and shows them to the user
class BookingNotificationListener extends ConsumerStatefulWidget {
  final Widget child;

  const BookingNotificationListener({super.key, required this.child});

  @override
  ConsumerState<BookingNotificationListener> createState() =>
      _BookingNotificationListenerState();
}

class _BookingNotificationListenerState
    extends ConsumerState<BookingNotificationListener> {

  void _showNewBookingNotification(Map<String, dynamic> booking) {
    if (!mounted) return;

    final clientName = booking['clientName'] ?? 'عميل جديد';
    final packageName = booking['packageName'] ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎉 حجز جديد!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'من $clientName',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      if (packageName.isNotEmpty)
                        Text(
                          packageName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        action: SnackBarAction(
          label: 'عرض',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/my-bookings');
          },
        ),
      ),
    );
  }

  void _showStatusUpdateNotification(Map<String, dynamic> update) {
    if (!mounted) return;

    final status = update['status'] ?? '';
    final statusInfo = _getStatusInfo(status);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusInfo['icon'] as IconData,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusInfo['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusInfo['message'] as String,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: statusInfo['color'] as Color,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        action: SnackBarAction(
          label: 'عرض',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/my-bookings');
          },
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return {
          'icon': Icons.check_circle,
          'title': '✅ تم تأكيد الحجز',
          'message': 'تم تأكيد حجزك بنجاح',
          'color': AppColors.success,
        };
      case 'completed':
        return {
          'icon': Icons.star,
          'title': '✨ تم إكمال الحجز',
          'message': 'تم إكمال حجزك بنجاح',
          'color': AppColors.primaryGradientStart,
        };
      case 'cancelled':
        return {
          'icon': Icons.cancel,
          'title': '❌ تم إلغاء الحجز',
          'message': 'تم إلغاء حجزك',
          'color': AppColors.error,
        };
      default:
        return {
          'icon': Icons.info,
          'title': 'تحديث الحجز',
          'message': 'تم تحديث حالة حجزك',
          'color': AppColors.primaryGradientStart,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to notification changes in build method
    ref.listen<BookingNotificationState>(bookingNotificationsProvider, (
      previous,
      next,
    ) {
      // Handle new booking notification (for photographers)
      if (next.latestBooking != null &&
          next.latestBooking != previous?.latestBooking) {
        _showNewBookingNotification(next.latestBooking!);
        ref.read(bookingNotificationsProvider.notifier).clearLatestBooking();

        // Refresh bookings list
        ref.read(bookingProvider.notifier).getPhotographerBookings();
      }

      // Handle booking status update (for clients)
      if (next.latestStatusUpdate != null &&
          next.latestStatusUpdate != previous?.latestStatusUpdate) {
        _showStatusUpdateNotification(next.latestStatusUpdate!);
        ref
            .read(bookingNotificationsProvider.notifier)
            .clearLatestStatusUpdate();

        // Refresh bookings list
        ref.read(bookingProvider.notifier).getMyBookings();
      }
    });

    return widget.child;
  }
}
