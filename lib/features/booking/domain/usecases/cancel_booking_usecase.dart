import '../repositories/booking_repository.dart';

class CancelBookingUseCase {
  final BookingRepository repository;

  CancelBookingUseCase(this.repository);

  Future<void> call(String bookingId, String reason) async {
    if (bookingId.isEmpty) {
      throw Exception('Booking ID is required');
    }

    if (reason.isEmpty) {
      throw Exception('Cancellation reason is required');
    }

    await repository.cancelBooking(bookingId, reason);
  }
}
