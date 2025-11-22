import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class CreateBookingUseCase {
  final BookingRepository repository;

  CreateBookingUseCase(this.repository);

  Future<Booking> call({
    required String photographerId,
    required String packageId,
    required DateTime date,
    required String timeSlot,
    required String location,
    String? notes,
  }) async {
    // Validation
    if (photographerId.isEmpty) {
      throw Exception('Photographer ID is required');
    }

    // Package ID is now optional - can be empty for bookings without package

    if (date.isBefore(DateTime.now())) {
      throw Exception('Booking date must be in the future');
    }

    if (timeSlot.isEmpty) {
      throw Exception('Time slot is required');
    }

    if (location.isEmpty) {
      throw Exception('Location is required');
    }

    return await repository.createBooking(
      photographerId: photographerId,
      packageId: packageId,
      date: date,
      timeSlot: timeSlot,
      location: location,
      notes: notes,
    );
  }
}
