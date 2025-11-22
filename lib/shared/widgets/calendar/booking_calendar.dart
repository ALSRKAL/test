import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';

class BookingCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final List<DateTime> bookedDates;
  final Function(DateTime) onDateSelected;

  const BookingCalendar({
    super.key,
    this.selectedDate,
    required this.bookedDates,
    required this.onDateSelected,
  });

  @override
  State<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: AppSpacing.md),
        _buildWeekDays(),
        const SizedBox(height: AppSpacing.sm),
        _buildCalendarGrid(),
        const SizedBox(height: AppSpacing.md),
        _buildLegend(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month - 1,
              );
            });
          },
        ),
        Text(
          _getMonthName(_currentMonth),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month + 1,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildWeekDays() {
    const weekDays = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = _getDaysInMonth(_currentMonth);
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: daysInMonth + startingWeekday,
      itemBuilder: (context, index) {
        if (index < startingWeekday) {
          return const SizedBox();
        }

        final day = index - startingWeekday + 1;
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
        
        return _buildDayCell(date);
      },
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isBooked = _isDateBooked(date);
    final isSelected = _isDateSelected(date);
    final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    final isToday = _isToday(date);

    Color? backgroundColor;
    Color? textColor;
    Border? border;

    if (isPast) {
      textColor = AppColors.textSecondaryLight.withOpacity(0.3);
    } else if (isSelected) {
      backgroundColor = AppColors.primaryGradientStart;
      textColor = Colors.white;
    } else if (isBooked) {
      backgroundColor = AppColors.error.withOpacity(0.1);
      textColor = AppColors.error;
    } else if (isToday) {
      border = Border.all(color: AppColors.primaryGradientStart, width: 2);
      textColor = AppColors.primaryGradientStart;
    }

    return GestureDetector(
      onTap: (!isPast && !isBooked)
          ? () {
              setState(() {
                _selectedDate = date;
              });
              widget.onDateSelected(date);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: border,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: textColor ?? AppColors.textPrimaryLight,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('متاح', AppColors.success),
        _buildLegendItem('محجوز', AppColors.error),
        _buildLegendItem('مختار', AppColors.primaryGradientStart),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  bool _isDateBooked(DateTime date) {
    return widget.bookedDates.any((bookedDate) =>
        bookedDate.year == date.year &&
        bookedDate.month == date.month &&
        bookedDate.day == date.day);
  }

  bool _isDateSelected(DateTime date) {
    if (_selectedDate == null) return false;
    return _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  String _getMonthName(DateTime date) {
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
    return '${months[date.month - 1]} ${date.year}';
  }
}
