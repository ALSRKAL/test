import '../../../../core/services/offline_service.dart';
import '../../domain/entities/booking.dart';

/// مصدر البيانات المحلي للحجوزات
abstract class BookingLocalDataSource {
  Future<Map<String, dynamic>> createBookingLocally({
    required String userId,
    required String photographerId,
    required String packageId,
    required String date,
    required String time,
    required String location,
    String? notes,
    required double totalPrice,
  });
  
  Future<List<Map<String, dynamic>>> getLocalBookings(String userId);
  Future<void> updateBookingLocally(String bookingId, Map<String, dynamic> updates);
  Future<void> cancelBookingLocally(String bookingId, String userId);
  Future<void> cacheBookings(List<Booking> bookings);
  Future<List<Booking>?> getCachedBookings();
  Future<void> clearCache();
}

class BookingLocalDataSourceImpl implements BookingLocalDataSource {
  final OfflineService _offlineService;

  BookingLocalDataSourceImpl(this._offlineService);

  // إنشاء حجز محلياً
  @override
  Future<Map<String, dynamic>> createBookingLocally({
    required String userId,
    required String photographerId,
    required String packageId,
    required String date,
    required String time,
    required String location,
    String? notes,
    required double totalPrice,
  }) async {
    final booking = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'userId': userId,
      'photographerId': photographerId,
      'packageId': packageId,
      'date': date,
      'time': time,
      'location': location,
      'notes': notes,
      'totalPrice': totalPrice,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };

    // حفظ الحجز محلياً
    await _offlineService.saveBookingLocally(booking, isPending: true);

    // إضافة للمزامنة
    await _offlineService.addToSyncQueue(
      operation: 'create_booking',
      endpoint: '/api/bookings',
      method: 'POST',
      data: booking,
    );

    return booking;
  }

  // الحصول على الحجوزات المحلية
  @override
  Future<List<Map<String, dynamic>>> getLocalBookings(String userId) async {
    return await _offlineService.getLocalBookings(userId);
  }

  // تحديث حجز محلياً
  @override
  Future<void> updateBookingLocally(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    // الحصول على الحجز الحالي
    final bookings = await _offlineService.getLocalBookings(updates['userId']);
    final booking = bookings.firstWhere((b) => b['id'] == bookingId);

    // تحديث البيانات
    final updatedBooking = {...booking, ...updates};

    // حفظ التحديث
    await _offlineService.saveBookingLocally(updatedBooking, isPending: true);

    // إضافة للمزامنة
    await _offlineService.addToSyncQueue(
      operation: 'update_booking',
      endpoint: '/api/bookings/$bookingId',
      method: 'PUT',
      data: updatedBooking,
    );
  }

  // إلغاء حجز محلياً
  @override
  Future<void> cancelBookingLocally(String bookingId, String userId) async {
    await updateBookingLocally(bookingId, {
      'userId': userId,
      'status': 'cancelled',
    });
  }

  // حفظ الحجوزات في الكاش
  @override
  Future<void> cacheBookings(List<Booking> bookings) async {
    for (final booking in bookings) {
      await _offlineService.saveBookingLocally({
        'id': booking.id,
        'userId': booking.clientId,
        'photographerId': booking.photographerId,
        'packageId': booking.packageId,
        'packageName': booking.packageName,
        'date': booking.date.toIso8601String(),
        'time': booking.timeSlot,
        'location': booking.location,
        'status': booking.status,
        'totalPrice': booking.totalPrice,
        'notes': booking.notes,
        'createdAt': booking.createdAt.toIso8601String(),
      }, isPending: false);
    }
  }

  // الحصول على الحجوزات من الكاش
  @override
  Future<List<Booking>?> getCachedBookings() async {
    try {
      // نحتاج userId هنا - يمكن الحصول عليه من auth provider
      // للآن سنرجع null
      return null;
    } catch (e) {
      return null;
    }
  }

  // مسح الكاش
  @override
  Future<void> clearCache() async {
    // يمكن إضافة منطق لمسح الكاش هنا إذا لزم الأمر
  }
}
