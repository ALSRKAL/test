import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';

class TimeSlots extends StatefulWidget {
  final List<String> availableSlots;
  final String? selectedSlot;
  final Function(String) onSlotSelected;

  const TimeSlots({
    super.key,
    required this.availableSlots,
    this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  State<TimeSlots> createState() => _TimeSlotsState();
}

class _TimeSlotsState extends State<TimeSlots> {
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.selectedSlot;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر الوقت',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: widget.availableSlots.map((slot) {
            final isSelected = _selectedSlot == slot;
            return _buildTimeSlot(slot, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSlot(String slot, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSlot = slot;
        });
        widget.onSlotSelected(slot);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGradientStart
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGradientStart
                : AppColors.textSecondaryLight.withOpacity(0.2),
          ),
        ),
        child: Text(
          slot,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimaryLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
