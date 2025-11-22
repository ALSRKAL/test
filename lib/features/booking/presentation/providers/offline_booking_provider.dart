import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/offline_provider.dart';
import '../../../../core/services/offline_service.dart';
import '../../data/datasources/booking_local_datasource.dart';

// مزود مصدر البيانات المحلي
final bookingLocalDataSourceProvider = Provider<BookingLocalDataSource>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return BookingLocalDataSourceImpl(offlineService);
});

// مزود الحجوزات المحلية
final localBookingsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final localDataSource = ref.watch(bookingLocalDataSourceProvider);
    return await localDataSource.getLocalBookings(userId);
  },
);

// مزود إنشاء حجز أوف لاين
final createOfflineBookingProvider = Provider<CreateOfflineBooking>((ref) {
  final localDataSource = ref.watch(bookingLocalDataSourceProvider);
  final offlineService = ref.watch(offlineServiceProvider);
  return CreateOfflineBooking(localDataSource, offlineService);
});

class CreateOfflineBooking {
  final BookingLocalDataSource _localDataSource;
  final OfflineService _offlineService;

  CreateOfflineBooking(this._localDataSource, this._offlineService);

  Future<BookingResult> execute({
    required String userId,
    required String photographerId,
    required String packageId,
    required String date,
    required String time,
    required String location,
    String? notes,
    required double totalPrice,
  }) async {
    try {
      final isOnline = await _offlineService.isOnline();

      if (isOnline) {
        // محاولة الحجز عبر الإنترنت
        // يمكن استدعاء الـ API هنا
        // في حالة الفشل، سيتم الحفظ محلياً
      }

      // الحفظ المحلي
      final booking = await _localDataSource.createBookingLocally(
        userId: userId,
        photographerId: photographerId,
        packageId: packageId,
        date: date,
        time: time,
        location: location,
        notes: notes,
        totalPrice: totalPrice,
      );

      return BookingResult(
        success: true,
        message: isOnline
            ? 'تم إنشاء الحجز بنجاح'
            : 'تم حفظ الحجز محلياً وسيتم إرساله عند الاتصال',
        booking: booking,
        isOffline: !isOnline,
      );
    } catch (e) {
      return BookingResult(
        success: false,
        message: 'فشل في إنشاء الحجز: $e',
      );
    }
  }
}

class BookingResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? booking;
  final bool isOffline;

  BookingResult({
    required this.success,
    required this.message,
    this.booking,
    this.isOffline = false,
  });
}
