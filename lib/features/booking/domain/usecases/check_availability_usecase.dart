import '../repositories/booking_repository.dart';

class CheckAvailabilityUseCase {
  final BookingRepository repository;

  CheckAvailabilityUseCase(this.repository);

  Future<List<String>> call(String photographerId, DateTime date) async {
    if (photographerId.isEmpty) {
      throw Exception('Photographer ID is required');
    }

    if (date.isBefore(DateTime.now())) {
      throw Exception('Date must be in the future');
    }

    return await repository.checkAvailability(photographerId, date);
  }
}
