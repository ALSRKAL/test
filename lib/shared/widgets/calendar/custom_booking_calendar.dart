import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';

class CustomBookingCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final List<DateTime> blockedDates;
  final List<DateTime> bookedDates;
  final DateTime firstDay;
  final DateTime lastDay;

  CustomBookingCalendar({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.blockedDates = const [],
    this.bookedDates = const [],
    DateTime? firstDay,
    DateTime? lastDay,
  })  : firstDay = firstDay ?? DateTime.now(),
        lastDay = lastDay ?? DateTime.now().add(const Duration(days: 90));

  @override
  State<CustomBookingCalendar> createState() => _CustomBookingCalendarState();
}

class _CustomBookingCalendarState extends State<CustomBookingCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate ?? DateTime.now();
    _selectedDay = widget.selectedDate;
  }

  bool _isDateBlocked(DateTime date) {
    return widget.blockedDates.any((blocked) =>
        blocked.year == date.year &&
        blocked.month == date.month &&
        blocked.day == date.day);
  }

  bool _isDateBooked(DateTime date) {
    return widget.bookedDates.any((booked) =>
        booked.year == date.year &&
        booked.month == date.month &&
        booked.day == date.day);
  }

  bool _isDateAvailable(DateTime date) {
    // التاريخ متاح إذا لم يكن محظوراً ولم يكن محجوزاً بالكامل
    return !_isDateBlocked(date) && !date.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Legend (دليل الألوان)
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                color: AppColors.success.withValues(alpha: 0.3),
                label: 'متاح',
                icon: Icons.check_circle_outline,
              ),
              _buildLegendItem(
                color: AppColors.warning.withValues(alpha: 0.3),
                label: 'محجوز جزئياً',
                icon: Icons.schedule,
              ),
              _buildLegendItem(
                color: AppColors.error.withValues(alpha: 0.3),
                label: 'محظور',
                icon: Icons.block,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Calendar
        Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            boxShadow: [context.cardShadow],
          ),
          child: TableCalendar(
            firstDay: widget.firstDay,
            lastDay: widget.lastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.saturday,
            locale: 'ar',
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_right,
                color: AppColors.primaryGradientStart,
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_left,
                color: AppColors.primaryGradientStart,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
              weekendStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              todayTextStyle: TextStyle(
                color: AppColors.primaryGradientStart,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, false);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, true);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, false, isToday: true);
              },
              disabledBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, false, isDisabled: true);
              },
            ),
            enabledDayPredicate: (day) {
              // تعطيل التواريخ الماضية والمحظورة
              if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                return false;
              }
              return true;
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (_isDateBlocked(selectedDay)) {
                // عرض رسالة أن التاريخ محظور
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('هذا التاريخ محظور من قبل المصورة'),
                    backgroundColor: AppColors.error,
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              widget.onDateSelected(selectedDay);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime day, bool isSelected,
      {bool isToday = false, bool isDisabled = false}) {
    final isBlocked = _isDateBlocked(day);
    final isBooked = _isDateBooked(day);
    final isAvailable = _isDateAvailable(day);

    return Builder(
      builder: (context) {
        Color? backgroundColor;
        Color? borderColor;
        Widget? badge;

        if (isSelected) {
          backgroundColor = null; // سيستخدم التدرج الافتراضي
        } else if (isBlocked) {
          backgroundColor = AppColors.error.withValues(alpha: 0.2);
          borderColor = AppColors.error;
          badge = const Icon(Icons.block, size: 12, color: AppColors.error);
        } else if (isBooked) {
          backgroundColor = AppColors.warning.withValues(alpha: 0.2);
          borderColor = AppColors.warning;
          badge = const Icon(Icons.schedule, size: 12, color: AppColors.warning);
        } else if (isAvailable) {
          backgroundColor = AppColors.success.withValues(alpha: 0.1);
          borderColor = AppColors.success.withValues(alpha: 0.3);
        }

        if (isToday && !isSelected) {
          borderColor = AppColors.primaryGradientStart;
        }

        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? null : backgroundColor,
            gradient: isSelected ? AppColors.primaryGradient : null,
            shape: BoxShape.circle,
            border: borderColor != null
                ? Border.all(color: borderColor, width: 2)
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isDisabled
                            ? context.textSecondary.withValues(alpha: 0.5)
                            : isBlocked
                                ? AppColors.error
                                : context.textPrimary,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (badge != null && !isSelected)
                Positioned(
                  top: 2,
                  right: 2,
                  child: badge,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Builder(
      builder: (context) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 1.0),
                  width: 2,
                ),
              ),
              child: Icon(icon, size: 12, color: color.withValues(alpha: 1.0)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}
