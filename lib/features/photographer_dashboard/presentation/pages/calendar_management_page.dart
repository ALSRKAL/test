import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/features/photographer/presentation/providers/photographer_provider.dart';
import 'package:hajzy/features/booking/presentation/providers/booking_provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarManagementPage extends ConsumerStatefulWidget {
  const CalendarManagementPage({super.key});

  @override
  ConsumerState<CalendarManagementPage> createState() =>
      _CalendarManagementPageState();
}

class _CalendarManagementPageState
    extends ConsumerState<CalendarManagementPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  List<DateTime> _blockedDates = [];

  @override
  void initState() {
    super.initState();
    // Load data immediately from cache/state
    final photographer = ref.read(photographersProvider).selectedPhotographer;
    if (photographer != null) {
      _blockedDates = photographer.availability.blockedDates;
    }

    // Load fresh data in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataInBackground();
    });
  }

  Future<void> _loadDataInBackground() async {
    // Load silently without showing loading indicator
    await ref.read(photographersProvider.notifier).getMyPhotographerProfile();
    await ref.read(bookingProvider.notifier).getPhotographerBookings();

    final photographer = ref.read(photographersProvider).selectedPhotographer;
    if (photographer != null && mounted) {
      setState(() {
        _blockedDates = photographer.availability.blockedDates;
      });
    }
  }

  Future<void> _loadData() async {
    await ref.read(photographersProvider.notifier).getMyPhotographerProfile();
    await ref.read(bookingProvider.notifier).getPhotographerBookings();

    final photographer = ref.read(photographersProvider).selectedPhotographer;
    if (photographer != null && mounted) {
      setState(() {
        _blockedDates = photographer.availability.blockedDates;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final photographerState = ref.watch(photographersProvider);
    final bookingsState = ref.watch(bookingProvider);

    final photographer = photographerState.selectedPhotographer;
    final bookings = bookingsState.bookings;

    // Get booked dates from bookings
    final bookedDates = bookings
        .where((b) => b.status == 'confirmed' || b.status == 'pending')
        .map((b) => b.date)
        .toList();

    // No loading screen - show immediately with cached data

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة التقويم')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegend(),
              const SizedBox(height: AppSpacing.lg),
              _buildCalendar(bookedDates),
              if (_selectedDate != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildSelectedDateInfo(bookedDates),
              ],
              const SizedBox(height: AppSpacing.lg),
              _buildUpcomingBookings(bookings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(List<DateTime> bookedDates) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.saturday,
        locale: 'ar',
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(
            Icons.chevron_right,
            color: AppColors.primaryGradientStart,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_left,
            color: AppColors.primaryGradientStart,
          ),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.primaryGradientStart.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: AppColors.primaryGradientStart,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, bookedDates);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, bookedDates, isToday: true);
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, bookedDates, isSelected: true);
          },
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day,
    List<DateTime> bookedDates, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final isBooked = _isDateBooked(day, bookedDates);
    final isBlocked = _isDateBlocked(day);
    final isPast = day.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    Color? backgroundColor;
    Color? textColor;

    if (isSelected) {
      backgroundColor = AppColors.primaryGradientStart;
      textColor = Colors.white;
    } else if (isPast) {
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.grey.shade400;
    } else if (isBooked) {
      backgroundColor = AppColors.error.withValues(alpha: 0.2);
      textColor = AppColors.error;
    } else if (isBlocked) {
      backgroundColor = Colors.grey.shade300;
      textColor = Colors.grey.shade600;
    } else if (isToday) {
      backgroundColor = AppColors.primaryGradientStart.withValues(alpha: 0.2);
      textColor = AppColors.primaryGradientStart;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected || isToday
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'دليل الألوان:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _buildLegendItem('متاح', Colors.white, Colors.grey.shade400),
              _buildLegendItem(
                'محجوز',
                AppColors.error.withValues(alpha: 0.2),
                null,
              ),
              _buildLegendItem('محظور', Colors.grey.shade300, null),
              _buildLegendItem(
                'اليوم',
                AppColors.primaryGradientStart.withValues(alpha: 0.2),
                null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, Color? borderColor) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.getTextPrimary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDateInfo(List<DateTime> bookedDates) {
    final isBooked = _isDateBooked(_selectedDate!, bookedDates);
    final isBlocked = _isDateBlocked(_selectedDate!);
    final isPast = _selectedDate!.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.primaryGradientStart.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.primaryGradientStart),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _formatDate(_selectedDate!),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isPast
                  ? Colors.grey.shade200
                  : isBooked
                  ? AppColors.error.withValues(alpha: 0.1)
                  : isBlocked
                  ? Colors.grey.shade200
                  : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Text(
              isPast
                  ? 'تاريخ ماضي'
                  : isBooked
                  ? 'محجوز'
                  : isBlocked
                  ? 'محظور'
                  : 'متاح',
              style: TextStyle(
                color: isPast
                    ? Colors.grey.shade600
                    : isBooked
                    ? AppColors.error
                    : isBlocked
                    ? Colors.grey.shade600
                    : AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!isBooked && !isPast)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _toggleBlockDate(_selectedDate!),
                icon: Icon(
                  isBlocked ? Icons.lock_open : Icons.block,
                  color: Colors.white,
                ),
                label: Text(isBlocked ? 'إلغاء الحظر' : 'حظر التاريخ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBlocked
                      ? AppColors.success
                      : Colors.grey.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBookings(List bookings) {
    final upcomingBookings =
        bookings
            .where(
              (b) =>
                  (b.status == 'confirmed' || b.status == 'pending') &&
                  b.date.isAfter(
                    DateTime.now().subtract(const Duration(days: 1)),
                  ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الحجوزات القادمة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        if (upcomingBookings.isEmpty)
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
                    'لا توجد حجوزات قادمة',
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
            itemCount: upcomingBookings.length,
            itemBuilder: (context, index) {
              return _buildBookingItem(upcomingBookings[index]);
            },
          ),
      ],
    );
  }

  Widget _buildBookingItem(booking) {
    final statusColor = booking.status == 'pending'
        ? AppColors.warning
        : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.small),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today, color: statusColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(booking.date),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.packageName ?? 'باقة'} - ${booking.timeSlot ?? 'غير محدد'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    booking.status == 'pending' ? 'معلق' : 'مؤكد',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left, color: AppColors.getTextSecondary(context)),
        ],
      ),
    );
  }

  Future<void> _toggleBlockDate(DateTime date) async {
    final isBlocked = _isDateBlocked(date);
    final previousBlockedDates = List<DateTime>.from(_blockedDates);

    // Optimistic Update
    setState(() {
      if (isBlocked) {
        _blockedDates.removeWhere((d) => isSameDay(d, date));
      } else {
        _blockedDates.add(date);
      }
    });

    try {
      // API Call
      await ref
          .read(photographersProvider.notifier)
          .updateBlockedDates(_blockedDates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBlocked ? 'تم إلغاء حظر التاريخ' : 'تم حظر التاريخ بنجاح',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _blockedDates = previousBlockedDates;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث التاريخ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool _isDateBooked(DateTime date, List<DateTime> bookedDates) {
    return bookedDates.any((d) => isSameDay(d, date));
  }

  bool _isDateBlocked(DateTime date) {
    return _blockedDates.any((d) => isSameDay(d, date));
  }

  String _formatDate(DateTime date) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
