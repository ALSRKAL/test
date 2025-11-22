import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/data/mock_data.dart';

// Provider للحجوزات
final bookingsProvider = StateNotifierProvider<BookingsNotifier, List<Map<String, dynamic>>>((ref) {
  return BookingsNotifier();
});

class BookingsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  BookingsNotifier() : super(List<Map<String, dynamic>>.from(MockData.bookings));

  // إضافة حجز جديد
  void addBooking(Map<String, dynamic> booking) {
    state = [...state, booking];
  }

  // تحديث حالة الحجز
  void updateBookingStatus(String bookingId, String status) {
    state = state.map((booking) {
      if (booking['id'] == bookingId) {
        return {...booking, 'status': status};
      }
      return booking;
    }).toList();
  }

  // إلغاء حجز
  void cancelBooking(String bookingId) {
    updateBookingStatus(bookingId, 'cancelled');
  }

  // الحصول على حجوزات حسب الحالة
  List<Map<String, dynamic>> getBookingsByStatus(String status) {
    return state.where((b) => b['status'] == status).toList();
  }
}
