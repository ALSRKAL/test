import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/api_endpoints.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/constants/app_strings.dart';
import 'package:hajzy/core/network/api_client.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';
import 'package:hajzy/features/booking/presentation/providers/booking_provider.dart';
import 'package:hajzy/features/photographer/presentation/providers/photographer_provider.dart';
import 'package:hajzy/shared/widgets/buttons/custom_button.dart';
import 'package:hajzy/shared/widgets/calendar/custom_booking_calendar.dart';
import 'package:hajzy/shared/widgets/common/custom_appbar.dart';
import 'package:hajzy/shared/widgets/inputs/custom_textfield.dart';
import 'package:hajzy/shared/widgets/loading/loading_indicator.dart';

// API Client Provider
final apiClientProvider = Provider((ref) => ApiClient());

class BookingPage extends ConsumerStatefulWidget {
  final String photographerId;

  const BookingPage({super.key, required this.photographerId});

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  DateTime? _selectedDate;
  String? _selectedPackageId;
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _showCalendar = false;
  List<DateTime> _blockedDates = [];
  List<DateTime> _bookedDates = [];

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    final photographerState = ref.read(photographersProvider);
    final photographer = photographerState.selectedPhotographer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 50,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Title
              Text(
                '🎉 تم إرسال طلب الحجز بنجاح!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Message
              Text(
                'تم إرسال طلب الحجز إلى ${photographer?.name ?? 'المصورة'} بنجاح.\n\nسيتم إشعارك فوراً عند قبول أو رفض الحجز.',
                style: TextStyle(
                  fontSize: 16,
                  color: context.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Booking Details
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.background,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.calendar_today,
                      'التاريخ',
                      '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(
                      Icons.location_on,
                      'الموقع',
                      _locationController.text,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                      child: const Text('العودة'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CustomButton(
                      text: 'حجوزاتي',
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back
                        // Navigate to bookings page
                        Navigator.pushNamed(context, '/my-bookings');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryGradientStart),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: context.textSecondary),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            const Text('فشل الحجز'),
          ],
        ),
        content: Text(
          error.contains('already booked')
              ? 'عذراً، هذا الموعد محجوز بالفعل. الرجاء اختيار موعد آخر.'
              : error.contains('not available')
              ? 'عذراً، هذا التاريخ غير متاح. الرجاء اختيار تاريخ آخر.'
              : 'حدث خطأ أثناء الحجز. الرجاء المحاولة مرة أخرى.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Add listener to location controller to update UI
    _locationController.addListener(() {
      setState(() {});
    });

    // Load photographer details if not already loaded
    Future.microtask(() {
      final state = ref.read(photographersProvider);
      if (state.selectedPhotographer == null ||
          state.selectedPhotographer!.id != widget.photographerId) {
        ref
            .read(photographersProvider.notifier)
            .getPhotographerDetails(widget.photographerId);
      }
    });
    _loadBlockedAndBookedDates();
  }

  Future<void> _loadBlockedAndBookedDates() async {
    try {
      // انتظر حتى يتم تحميل بيانات المصورة
      await Future.delayed(const Duration(milliseconds: 500));

      final photographerState = ref.read(photographersProvider);
      final photographer = photographerState.selectedPhotographer;

      if (photographer == null) {
        return;
      }

      // 1. تحميل التواريخ المحظورة من تقويم المصورة
      final blockedDates = photographer.availability.blockedDates;

      // 2. تحميل التواريخ المحجوزة من API
      List<DateTime> bookedDates = [];

      try {
        final apiClient = ref.read(apiClientProvider);
        final startDate = DateTime.now().toIso8601String().split('T')[0];
        final endDate = DateTime.now()
            .add(const Duration(days: 90))
            .toIso8601String()
            .split('T')[0];

        final response = await apiClient.get(
          ApiEndpoints.bookedDates(widget.photographerId),
          queryParameters: {'startDate': startDate, 'endDate': endDate},
        );

        if (response.data['success'] == true) {
          final bookedDatesData = response.data['data']['bookedDates'] as List;

          // نعتبر التاريخ محجوزاً إذا كان فيه حجوزات
          for (var dateInfo in bookedDatesData) {
            final dateStr = dateInfo['date'] as String;
            final bookingsCount = dateInfo['bookingsCount'] as int;

            // إذا كان هناك 3 حجوزات أو أكثر، نعتبر التاريخ محجوزاً بالكامل
            if (bookingsCount >= 3) {
              bookedDates.add(DateTime.parse(dateStr));
            }
          }
        }
      } catch (e) {
        // إذا فشل تحميل التواريخ المحجوزة، نستمر مع التواريخ المحظورة فقط
        // لا نعرض خطأ للمستخدم
      }

      if (mounted) {
        setState(() {
          _blockedDates = blockedDates;
          _bookedDates = bookedDates;
        });
      }
    } catch (e) {
      // في حالة حدوث خطأ، نستخدم قيم فارغة
      if (mounted) {
        setState(() {
          _blockedDates = [];
          _bookedDates = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final photographerState = ref.watch(photographersProvider);

    // Show loading while fetching photographer details
    if (photographerState.isLoading &&
        photographerState.selectedPhotographer == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'حجز جديد'),
        body: const Center(child: LoadingIndicator()),
      );
    }

    final photographer = photographerState.selectedPhotographer;

    if (photographer == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'حجز جديد'),
        body: const Center(child: Text('المصورة غير موجودة')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'حجز مع ${photographer.name}'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.selectDate,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showCalendar = !_showCalendar;
                    });
                  },
                  icon: Icon(
                    _showCalendar
                        ? Icons.keyboard_arrow_up
                        : Icons.calendar_month,
                  ),
                  label: Text(_showCalendar ? 'إخفاء التقويم' : 'عرض التقويم'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Selected Date Display
            if (_selectedDate != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primaryGradientStart.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: AppColors.primaryGradientStart),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available,
                      color: AppColors.primaryGradientStart,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'التاريخ المختار: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGradientStart,
                      ),
                    ),
                  ],
                ),
              ),

            // Calendar
            if (_showCalendar) ...[
              const SizedBox(height: AppSpacing.lg),
              CustomBookingCalendar(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                    _showCalendar = false; // إخفاء التقويم بعد الاختيار
                  });
                  // Removed _checkAvailability call as we don't need time slots anymore
                },
                blockedDates: _blockedDates,
                bookedDates: _bookedDates,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),

            // Package Selection (Optional)
            if (photographer.packages.where((p) => p.isActive).isNotEmpty) ...[
              Text(
                'اختر الباقة (اختياري)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'يمكنك اختيار باقة أو الحجز بدون باقة',
                style: TextStyle(fontSize: 14, color: context.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Option: No Package
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPackageId = null;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(
                      color: _selectedPackageId == null
                          ? AppColors.primaryGradientStart
                          : context.dividerColor,
                      width: _selectedPackageId == null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'بدون باقة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'سيتم الاتفاق على السعر مع المصورة',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _selectedPackageId == null
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: _selectedPackageId == null
                            ? AppColors.primaryGradientStart
                            : context.dividerColor,
                      ),
                    ],
                  ),
                ),
              ),

              // Available Packages
              ...photographer.packages.where((p) => p.isActive).map((package) {
                final isSelected = _selectedPackageId == package.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPackageId = package.id;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGradientStart
                            : context.dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                package.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${package.price.toStringAsFixed(0)} ريال - ${package.duration}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryGradientStart,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (package.features.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  package.features.join(' • '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected
                              ? AppColors.primaryGradientStart
                              : context.dividerColor,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Location
            CustomTextField(
              label: AppStrings.location,
              hint: 'أدخل موقع المناسبة',
              controller: _locationController,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Notes
            CustomTextField(
              label: AppStrings.notes,
              hint: 'أضف ملاحظات إضافية (اختياري)',
              controller: _notesController,
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Price Summary
            if (_selectedPackageId != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.background,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الإجمالي',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          '${photographer.packages.firstWhere((p) => p.id == _selectedPackageId).price.toStringAsFixed(0)} ريال',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGradientStart,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),

            // Validation message
            if (_selectedDate == null || _locationController.text.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  _selectedDate == null
                      ? '⚠️ الرجاء اختيار التاريخ'
                      : '⚠️ الرجاء إدخال الموقع',
                  style: const TextStyle(color: AppColors.error, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            // Confirm Button
            CustomButton(
              text: bookingState.isLoading
                  ? 'جاري الحجز...'
                  : AppStrings.confirmBooking,
              onPressed: bookingState.isLoading
                  ? null
                  : (_selectedDate != null &&
                        _locationController.text.isNotEmpty)
                  ? () async {
                      try {
                        await ref
                            .read(bookingProvider.notifier)
                            .createBooking(
                              photographerId: widget.photographerId,
                              packageId: _selectedPackageId,
                              date: _selectedDate!,
                              timeSlot:
                                  'غير محدد', // Default value since time selection is removed
                              location: _locationController.text,
                              notes: _notesController.text.isEmpty
                                  ? null
                                  : _notesController.text,
                            );

                        if (mounted) {
                          _showSuccessDialog();
                        }
                      } catch (e) {
                        if (mounted) {
                          _showErrorDialog(e.toString());
                        }
                      }
                    }
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
