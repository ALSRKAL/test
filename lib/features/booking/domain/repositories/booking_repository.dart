import '../entities/booking.dart';

abstract class BookingRepository {
  Future<Booking> createBooking({
    required String photographerId,
    required String packageId,
    required DateTime date,
    required String timeSlot,
    required String location,
    String? notes,
  });

  Future<List<Booking>> getMyBookings();

  Future<List<Booking>> getPhotographerBookings(String photographerId);

  Future<Booking> getBookingById(String bookingId);

  Future<Booking> updateBookingStatus(String bookingId, String status);

  Future<void> cancelBooking(String bookingId, String reason);

  Future<List<String>> checkAvailability(String photographerId, DateTime date);
}
