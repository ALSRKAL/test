import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/features/auth/presentation/providers/auth_provider.dart';
import 'package:hajzy/features/photographer/presentation/providers/photographer_provider.dart';
import 'package:hajzy/features/booking/presentation/providers/booking_provider.dart';
import 'package:hajzy/features/chat/presentation/providers/chat_provider.dart';
import 'package:hajzy/features/notifications/presentation/providers/notification_provider.dart';
import 'package:hajzy/features/notifications/presentation/widgets/notification_icon_button.dart';
import 'package:hajzy/shared/widgets/loading/loading_indicator.dart';
import 'package:hajzy/shared/widgets/errors/error_widget.dart' as custom;

class PhotographerDashboardPage extends ConsumerStatefulWidget {
  const PhotographerDashboardPage({super.key});

  @override
  ConsumerState<PhotographerDashboardPage> createState() =>
      _PhotographerDashboardPageState();
}

class _PhotographerDashboardPageState
    extends ConsumerState<PhotographerDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load photographer data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      // Get current photographer profile
      await ref.read(photographersProvider.notifier).getMyPhotographerProfile();

      // Only load other data if photographer profile exists
      final photographer = ref.read(photographersProvider).selectedPhotographer;
      if (photographer != null) {
        // Get bookings
        await ref.read(bookingProvider.notifier).getPhotographerBookings();
        // Get unread messages count
        await ref.read(chatProvider.notifier).getUnreadCount();
        await ref.read(chatProvider.notifier).getConversations();
        // Get notifications
        await ref.read(notificationProvider.notifier).getNotifications();
        await ref.read(notificationProvider.notifier).getUnreadCount();
      } else {
        // Profile not found, redirect to complete profile
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/complete-profile');
        }
      }
    } catch (e) {
      // Handle error - profile might not exist yet
      debugPrint('Error loading dashboard data: $e');
      if (e.toString().contains('Profile not found') && mounted) {
        Navigator.pushReplacementNamed(context, '/complete-profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final photographerState = ref.watch(photographersProvider);
    final bookingsState = ref.watch(bookingProvider);

    final user = authState.user;
    final photographer = photographerState.selectedPhotographer;
    final isLoading = photographerState.isLoading || bookingsState.isLoading;

    if (photographerState.error != null && photographer == null) {
      return Scaffold(
        body: Center(
          child: custom.CustomErrorWidget(
            message: photographerState.error!,
            onRetry: _loadData,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'لوحة التحكم',
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          NotificationIconButton(),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: AppColors.getTextPrimary(context),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/photographer-settings');
            },
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: isLoading
          ? const Center(child: LoadingIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(user, photographer),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStatsGrid(photographer, bookingsState),
                    const SizedBox(height: AppSpacing.xl),
                    _buildQuickActions(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildPendingBookings(context, bookingsState),
                    const SizedBox(height: AppSpacing.huge),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(user, photographer) {
    final displayName = photographer?.name ?? user?.name ?? 'اسم المصورة';
    final avatarUrl = photographer?.avatar ?? user?.avatar;
    final rating = photographer?.rating.average ?? 0.0;
    final reviewCount = photographer?.rating.count ?? 0;
    final subscriptionPlan = photographer?.subscription.plan ?? 'free';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryGradientStart,
            AppColors.primaryGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientStart.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? Icon(
                                Icons.person,
                                size: 35,
                                color: AppColors.primaryGradientStart,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (photographer?.isVerified == true) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'موثق',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: AppColors.gold,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${rating.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat(
                        'التقييمات',
                        '$reviewCount',
                        Icons.rate_review_outlined,
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildHeaderStat(
                        'الباقة',
                        subscriptionPlan.toUpperCase(),
                        Icons.card_membership_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(photographer, bookingsState) {
    final pendingBookings = bookingsState.bookings
        .where((b) => b.status == 'pending')
        .length;
    final completedBookings = bookingsState.bookings
        .where((b) => b.status == 'completed')
        .length;
    final portfolioCount = photographer?.portfolio.images.length ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.3, // Reduced from 1.6 to give more height
      children: [
        _buildStatCard(
          'الحجوزات المعلقة',
          '$pendingBookings',
          Icons.pending_actions,
          AppColors.warning,
          AppColors.warning.withOpacity(0.1),
        ),
        _buildStatCard(
          'الحجوزات المكتملة',
          '$completedBookings',
          Icons.check_circle_outline,
          AppColors.success,
          AppColors.success.withOpacity(0.1),
        ),
        _buildStatCard(
          'صور المعرض',
          '$portfolioCount',
          Icons.photo_library_outlined,
          AppColors.primaryGradientStart,
          AppColors.primaryGradientStart.withOpacity(0.1),
        ),

        _buildStatCard(
          'المشاهدات',
          '${photographer?.stats.views ?? 0}',
          Icons.visibility_outlined,
          Colors.blue,
          Colors.blue.withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm), // Reduced padding
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(context).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, size: 60, color: color.withOpacity(0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Changed from center/spacer
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reduced padding
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18), // Reduced icon size
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20, // Reduced font size
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11, // Reduced font size
                      color: AppColors.getTextSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إجراءات سريعة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.0, // Square aspect ratio
          children: [
            _buildActionButton(
              'إدارة المعرض',
              Icons.photo_library_outlined,
              () {
                Navigator.pushNamed(context, '/portfolio-management');
              },
            ),
            _buildActionButton('الباقات', Icons.card_giftcard_outlined, () {
              Navigator.pushNamed(context, '/package-management');
            }),
            _buildBookingsActionButton(
              'الحجوزات',
              Icons.event_note_outlined,
              () {
                Navigator.pushNamed(context, '/bookings-management');
              },
            ),
            _buildActionButton('التقويم', Icons.calendar_today_outlined, () {
              Navigator.pushNamed(context, '/calendar-management');
            }),
            _buildActionButton('التقييمات', Icons.star_outline, () {
              Navigator.pushNamed(context, '/reviews-section');
            }),
            _buildActionButton(
              'الأرباح',
              Icons.account_balance_wallet_outlined,
              () {
                Navigator.pushNamed(context, '/earnings-report');
              },
            ),
            _buildActionButtonWithBadge(
              'المحادثات',
              Icons.chat_bubble_outline,
              () {
                Navigator.pushNamed(context, '/conversations');
              },
            ),
            _buildActionButton(
              'توثيق الحساب',
              Icons.verified_user_outlined,
              () {
                Navigator.pushNamed(context, '/verification-request');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.getSurface(context),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      elevation: 2,
      shadowColor: AppColors.getShadow(context).withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGradientStart.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryGradientStart,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtonWithBadge(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    final chatState = ref.watch(chatProvider);
    final unreadCount = chatState.totalUnreadCount;

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand, // Ensure children fill the stack
      children: [
        _buildActionButton(label, icon, onTap),
        if (unreadCount > 0)
          Positioned(
            top: -4, // Adjusted position
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.getSurface(context),
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBookingsActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    final bookingsState = ref.watch(bookingProvider);
    final pendingCount = bookingsState.bookings
        .where((b) => b.status == 'pending')
        .length;

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand, // Ensure children fill the stack
      children: [
        _buildActionButton(label, icon, onTap),
        if (pendingCount > 0)
          Positioned(
            top: -4, // Adjusted position
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.getSurface(context),
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  pendingCount > 99 ? '99+' : '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPendingBookings(BuildContext context, bookingsState) {
    final pendingBookings = bookingsState.bookings
        .where((b) => b.status == 'pending')
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'الحجوزات المعلقة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/bookings-management');
              },
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (pendingBookings.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: AppColors.getTextSecondary(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'لا توجد حجوزات معلقة',
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingBookings.length,
            itemBuilder: (context, index) {
              final booking = pendingBookings[index];
              return _buildBookingCard(context, booking);
            },
          ),
      ],
    );
  }

  Widget _buildBookingCard(BuildContext context, booking) {
    final statusColor = AppColors.warning;
    final statusText = 'معلق';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(context).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryGradientStart.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primaryGradientStart.withOpacity(
                      0.1,
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppColors.primaryGradientStart,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.clientName ?? 'عميل',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            size: 14,
                            color: AppColors.getTextSecondary(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking.packageName ?? 'باقة',
                            style: TextStyle(
                              color: AppColors.getTextSecondary(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.divider.withOpacity(0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.getTextSecondary(context),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          booking.date.toString().split(' ')[0],
                          style: TextStyle(
                            color: AppColors.getTextSecondary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 20, color: AppColors.divider),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.getTextSecondary(context),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          booking.timeSlot ?? 'غير محدد',
                          style: TextStyle(
                            color: AppColors.getTextSecondary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 20, color: AppColors.divider),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      await ref
                          .read(bookingProvider.notifier)
                          .updateBookingStatus(booking.id, 'cancelled');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم رفض الحجز')),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    child: const Text('رفض', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(bookingProvider.notifier)
                          .updateBookingStatus(booking.id, 'confirmed');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم قبول الحجز')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    child: const Text('قبول', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
