import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/features/booking/presentation/providers/booking_provider.dart';
import 'package:hajzy/shared/widgets/errors/empty_state.dart';
import 'package:hajzy/shared/widgets/errors/error_widget.dart' as custom;
import 'package:hajzy/shared/widgets/loading/loading_indicator.dart';

class BookingsManagementPage extends ConsumerStatefulWidget {
  const BookingsManagementPage({super.key});

  @override
  ConsumerState<BookingsManagementPage> createState() =>
      _BookingsManagementPageState();
}

class _BookingsManagementPageState
    extends ConsumerState<BookingsManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      ref.read(bookingProvider.notifier).getPhotographerBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحجوزات'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Text('المعلقة'),
                  const SizedBox(width: 8),
                  _buildBadge(
                    state.bookings
                        .where((b) => b.status == 'pending')
                        .length,
                    AppColors.warning,
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('المؤكدة'),
                  const SizedBox(width: 8),
                  _buildBadge(
                    state.bookings
                        .where((b) => b.status == 'confirmed')
                        .length,
                    AppColors.success,
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('المكتملة'),
                  const SizedBox(width: 8),
                  _buildBadge(
                    state.bookings
                        .where((b) => b.status == 'completed')
                        .length,
                    AppColors.primaryGradientStart,
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('الملغية'),
                  const SizedBox(width: 8),
                  _buildBadge(
                    state.bookings
                        .where((b) => b.status == 'cancelled')
                        .length,
                    AppColors.error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: LoadingIndicator())
          : state.error != null
              ? custom.CustomErrorWidget(
                  message: state.error!,
                  onRetry: () {
                    ref.read(bookingProvider.notifier).getPhotographerBookings();
                  },
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsList('pending'),
                    _buildBookingsList('confirmed'),
                    _buildBookingsList('completed'),
                    _buildBookingsList('cancelled'),
                  ],
                ),
    );
  }

  Widget _buildBadge(int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBookingsList(String status) {
    final state = ref.watch(bookingProvider);
    final bookings = state.bookings.where((b) => b.status == status).toList();

    if (bookings.isEmpty) {
      return EmptyState(
        icon: _getStatusIcon(status),
        message: _getEmptyMessage(status),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(bookingProvider.notifier).getPhotographerBookings();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Booking Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryGradientStart,
                          backgroundImage: booking.clientAvatar != null && booking.clientAvatar!.isNotEmpty
                              ? NetworkImage(booking.clientAvatar!)
                              : null,
                          child: booking.clientAvatar == null || booking.clientAvatar!.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.clientName.isNotEmpty 
                                    ? booking.clientName 
                                    : 'عميل #${booking.id.substring(0, 8)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                booking.packageName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.getTextSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(booking.status),
                      ],
                    ),
                    const Divider(height: AppSpacing.lg),
                    
                    // Booking Details
                    _buildDetailRow(Icons.calendar_today, 'التاريخ', '${booking.date.day}/${booking.date.month}/${booking.date.year}'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(Icons.access_time, 'الوقت', booking.timeSlot),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(Icons.location_on, 'الموقع', booking.location),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(Icons.attach_money, 'السعر', '${booking.totalPrice} ريال'),
                    
                    if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildDetailRow(Icons.note, 'ملاحظات', booking.notes!),
                    ],
                    
                    // Action Buttons
                    if (status == 'pending') ...[
                      const Divider(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleConfirmBooking(booking.id),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('قبول'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleRejectBooking(booking.id),
                              icon: const Icon(Icons.cancel),
                              label: const Text('رفض'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (status == 'confirmed') ...[
                      const Divider(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleCompleteBooking(booking.id),
                              icon: const Icon(Icons.done_all),
                              label: const Text('إكمال الحجز'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGradientStart,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleCancelBooking(booking.id),
                              icon: const Icon(Icons.cancel),
                              label: const Text('إلغاء'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        text = 'معلق';
        break;
      case 'confirmed':
        color = AppColors.success;
        text = 'مؤكد';
        break;
      case 'completed':
        color = AppColors.primaryGradientStart;
        text = 'مكتمل';
        break;
      case 'cancelled':
        color = AppColors.error;
        text = 'ملغي';
        break;
      default:
        color = AppColors.getTextSecondary(context);
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.getTextSecondary(context)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.getTextSecondary(context),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.event_note;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pending':
        return 'لا توجد حجوزات معلقة';
      case 'confirmed':
        return 'لا توجد حجوزات مؤكدة';
      case 'completed':
        return 'لا توجد حجوزات مكتملة';
      case 'cancelled':
        return 'لا توجد حجوزات ملغية';
      default:
        return 'لا توجد حجوزات';
    }
  }

  Future<void> _handleConfirmBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحجز'),
        content: const Text('هل أنت متأكد من قبول هذا الحجز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('قبول'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(bookingProvider.notifier)
            .updateBookingStatus(bookingId, 'confirmed');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم قبول الحجز بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل قبول الحجز: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleRejectBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الحجز'),
        content: const Text('هل أنت متأكد من رفض هذا الحجز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('رفض'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(bookingProvider.notifier)
            .updateBookingStatus(bookingId, 'cancelled');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفض الحجز'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل رفض الحجز: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleCompleteBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إكمال الحجز'),
        content: const Text('هل تم إكمال هذا الحجز بنجاح؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGradientStart,
            ),
            child: const Text('إكمال'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(bookingProvider.notifier)
            .updateBookingStatus(bookingId, 'completed');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إكمال الحجز بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل إكمال الحجز: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleCancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الحجز'),
        content: const Text('هل أنت متأكد من إلغاء هذا الحجز؟'),
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
            .cancelBooking(bookingId, 'تم الإلغاء من قبل المصورة');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء الحجز'),
              backgroundColor: AppColors.warning,
            ),
          );
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
