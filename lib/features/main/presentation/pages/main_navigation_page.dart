import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_strings.dart';
import 'package:hajzy/features/home/presentation/pages/home_page.dart';
import 'package:hajzy/features/booking/presentation/pages/my_bookings_page.dart';
import 'package:hajzy/features/chat/presentation/pages/conversations_list_page.dart';
import 'package:hajzy/features/profile/presentation/pages/user_profile_page.dart';
import 'package:hajzy/features/chat/presentation/providers/chat_provider.dart';
import 'package:hajzy/features/booking/presentation/providers/booking_provider.dart';
import '../providers/navigation_provider.dart';

/// الصفحة الرئيسية للتنقل بين الأقسام
class MainNavigationPage extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigationPage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  @override
  void initState() {
    super.initState();
    // تعيين الصفحة الأولية في الـ provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationProvider.notifier).navigateTo(widget.initialIndex);
      // Load bookings to show badge
      ref.read(bookingProvider.notifier).getMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final chatState = ref.watch(chatProvider);
    final bookingState = ref.watch(bookingProvider);

    // Count bookings with recent status updates (within last 7 days)
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final bookingsWithUpdates = bookingState.bookings.where((booking) {
      // Get the most recent status change date
      DateTime? statusChangeDate;

      if (booking.status == 'accepted' && booking.confirmedAt != null) {
        statusChangeDate = booking.confirmedAt;
      } else if (booking.status == 'completed' && booking.completedAt != null) {
        statusChangeDate = booking.completedAt;
      } else if (booking.status == 'cancelled' && booking.cancelledAt != null) {
        statusChangeDate = booking.cancelledAt;
      } else if (booking.status == 'rejected') {
        // For rejected, we don't have a specific date, so use createdAt as fallback
        statusChangeDate = booking.createdAt;
      }

      // Check if status change is recent (within last 7 days)
      final isRecent =
          statusChangeDate != null && statusChangeDate.isAfter(sevenDaysAgo);

      return isRecent;
    }).length;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomePage(),
          MyBookingsPage(),
          ConversationsListPage(),
          UserProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(
        currentIndex,
        chatState.totalUnreadCount,
        bookingsWithUpdates,
      ),
    );
  }

  Widget _buildBottomNavigationBar(
    int currentIndex,
    int chatUnreadCount,
    int bookingsWithUpdates,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: AppStrings.home,
                index: 0,
                currentIndex: currentIndex,
              ),
              _buildNavItem(
                icon: Icons.calendar_today_rounded,
                label: AppStrings.myBookings,
                index: 1,
                currentIndex: currentIndex,
                badge: bookingsWithUpdates > 0 ? bookingsWithUpdates : null,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_rounded,
                label: AppStrings.chat,
                index: 2,
                currentIndex: currentIndex,
                badge: chatUnreadCount > 0 ? chatUnreadCount : null,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: AppStrings.profile,
                index: 3,
                currentIndex: currentIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    int? badge,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(navigationProvider.notifier).navigateTo(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.all(isSelected ? 8 : 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGradientStart
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.primaryGradientStart.withValues(
                                  alpha: 0.3,
                                )
                              : Colors.transparent,
                          blurRadius: isSelected ? 8 : 0,
                          offset: isSelected
                              ? const Offset(0, 4)
                              : const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondaryLight.withValues(alpha: 0.6),
                      size: isSelected ? 22 : 20,
                    ),
                  ),
                  if (badge != null) _buildBadge(badge),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: isSelected
                    ? Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGradientStart,
                        ),
                      )
                    : const SizedBox(height: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Positioned(
      top: -5,
      right: -5,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).cardColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Center(
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
