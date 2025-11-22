import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class GetMyBookingsUseCase {
  final BookingRepository repository;

  GetMyBookingsUseCase(this.repository);

  Future<List<Booking>> call() async {
    return await repository.getMyBookings();
  }
}
