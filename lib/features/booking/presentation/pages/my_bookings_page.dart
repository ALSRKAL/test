import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';
import 'package:hajzy/features/booking/presentation/providers/booking_provider.dart';
import 'package:hajzy/features/review/presentation/pages/create_review_page.dart';
import 'package:hajzy/shared/widgets/loading/loading_indicator.dart';
import 'package:hajzy/shared/widgets/errors/empty_state.dart';
import 'package:hajzy/shared/widgets/common/offline_indicator.dart';
import 'package:intl/intl.dart';

class MyBookingsPage extends ConsumerStatefulWidget {
  const MyBookingsPage({super.key});

  @override
  ConsumerState<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends ConsumerState<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load bookings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).getMyBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);

    return Scaffold(
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          AppColors.primaryGradientStart,
                          AppColors.primaryGradientEnd,
                        ],
                      ),
                    ),
                    child: FlexibleSpaceBar(
                      centerTitle: true,
                      titlePadding: const EdgeInsets.only(bottom: 60),
                      title: const Text(
                        'حجوزاتي',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primaryGradientStart,
                      unselectedLabelColor: context.textSecondary,
                      indicatorColor: AppColors.primaryGradientStart,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'الكل'),
                        Tab(text: 'قيد الانتظار'),
                        Tab(text: 'مؤكدة'),
                        Tab(text: 'مكتملة'),
                      ],
                    ),
                  ),
                ),
              ],
              body: bookingState.isLoading && bookingState.bookings.isEmpty
                  ? const Center(child: LoadingIndicator())
                  : bookingState.error != null && bookingState.bookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'حدث خطأ في تحميل الحجوزات',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bookingState.error!,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref
                                  .read(bookingProvider.notifier)
                                  .getMyBookings();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(bookingProvider.notifier)
                            .getMyBookings();
                      },
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildBookingsList(bookingState.bookings),
                          _buildBookingsList(
                            bookingState.bookings
                                .where((b) => b.status == 'pending')
                                .toList(),
                          ),
                          _buildBookingsList(
                            bookingState.bookings
                                .where((b) => b.status == 'confirmed')
                                .toList(),
                          ),
                          _buildBookingsList(
                            bookingState.bookings
                                .where((b) => b.status == 'completed')
                                .toList(),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List bookings) {
    if (bookings.isEmpty) {
      return const Center(
        child: EmptyState(
          message: 'لا توجد حجوزات',
          icon: Icons.calendar_today_outlined,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        100,
      ),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _BookingCard(booking: booking);
      },
    );
  }
}

// Delegate for SliverPersistentHeader
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: context.surface, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _BookingCard extends ConsumerWidget {
  final dynamic booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');
    final timeFormat = DateFormat('hh:mm a', 'ar');

    // تحديد اللون والأيقونة حسب الحالة
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (booking.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'قيد الانتظار';
        break;
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'مؤكدة';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'مكتملة';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'ملغية';
        break;
      default:
        statusColor = context.textSecondary;
        statusIcon = Icons.help_outline;
        statusText = booking.status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [context.cardShadow],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/booking-details',
            arguments: booking.id,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    statusColor.withValues(alpha: 0.1),
                    statusColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Photographer avatar with border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage:
                          booking.photographerAvatar != null &&
                              booking.photographerAvatar!.isNotEmpty
                          ? NetworkImage(booking.photographerAvatar!)
                          : null,
                      child:
                          booking.photographerAvatar == null ||
                              booking.photographerAvatar!.isEmpty
                          ? Text(
                              booking.photographerName.isNotEmpty
                                  ? booking.photographerName[0].toUpperCase()
                                  : '؟',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Photographer name and package
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.photographerName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: context.textSecondary.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                booking.packageName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.textSecondary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Body with booking details
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Booking details in grid
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _DetailItem(
                                icon: Icons.calendar_today,
                                label: 'التاريخ',
                                value: dateFormat.format(booking.date),
                                color: Colors.blue,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.textSecondaryLight.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            Expanded(
                              child: _DetailItem(
                                icon: Icons.access_time,
                                label: 'الوقت',
                                value: timeFormat.format(booking.date),
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Divider(height: 1, color: context.dividerColor),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _DetailItem(
                                icon: Icons.location_on,
                                label: 'الموقع',
                                value: booking.location,
                                color: Colors.red,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.textSecondaryLight.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            Expanded(
                              child: _DetailItem(
                                icon: Icons.payments,
                                label: 'السعر',
                                value: '${booking.totalPrice} ريال',
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  if (booking.status == 'pending' ||
                      booking.status == 'confirmed' ||
                      booking.status == 'completed')
                    const SizedBox(height: AppSpacing.md),
                  if (booking.status == 'pending' ||
                      booking.status == 'confirmed' ||
                      booking.status == 'completed')
                    Row(
                      children: [
                        if (booking.status == 'pending')
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showCancelDialog(context, ref, booking.id);
                              },
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('إلغاء الحجز'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        if (booking.status == 'confirmed') ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/chat',
                                  arguments: {
                                    'otherUserId': booking.photographerId,
                                    'otherUserName': booking.photographerName,
                                    'otherUserAvatar':
                                        booking.photographerAvatar,
                                  },
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('محادثة'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/booking-details',
                                  arguments: booking.id,
                                );
                              },
                              icon: const Icon(Icons.info_outline),
                              label: const Text('التفاصيل'),
                            ),
                          ),
                        ],
                        if (booking.status == 'completed')
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreateReviewPage(
                                        photographerId: booking.photographerId,
                                        photographerName:
                                            booking.photographerName,
                                        bookingId: booking.id,
                                      ),
                                    ),
                                  );
                                  if (result == true && context.mounted) {
                                    ref
                                        .read(bookingProvider.notifier)
                                        .getMyBookings();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('حدث خطأ: $e'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.star_rate),
                              label: const Text('تقييم'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('إلغاء الحجز'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من إلغاء هذا الحجز؟\nلن تتمكن من التراجع عن هذا الإجراء.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(bookingProvider.notifier).cancelBooking(bookingId);

              if (context.mounted) {
                final state = ref.read(bookingProvider);
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error!),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إلغاء الحجز بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إلغاء الحجز'),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.textSecondary.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
