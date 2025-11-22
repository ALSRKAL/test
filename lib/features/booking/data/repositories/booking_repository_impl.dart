import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';
import '../datasources/booking_local_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;
  final BookingLocalDataSource localDataSource;

  BookingRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Booking> createBooking({
    required String photographerId,
    required String packageId,
    required DateTime date,
    required String timeSlot,
    required String location,
    String? notes,
  }) async {
    final booking = await remoteDataSource.createBooking(
      photographerId: photographerId,
      packageId: packageId,
      date: date,
      timeSlot: timeSlot,
      location: location,
      notes: notes,
    );

    // Invalidate cache after creating new booking (don't fail if it fails)
    try {
      await localDataSource.clearCache();
    } catch (e) {
      // Ignore cache errors
    }

    return booking;
  }

  @override
  Future<List<Booking>> getMyBookings() async {
    try {
      // Try to get from remote
      final bookings = await remoteDataSource.getMyBookings();

      // Cache the results (don't fail if caching fails)
      try {
        await localDataSource.cacheBookings(bookings);
      } catch (cacheError) {
        // Ignore cache errors
      }

      return bookings;
    } catch (e) {
      // If remote fails, try to get from cache
      try {
        final cached = await localDataSource.getCachedBookings();
        if (cached != null) {
          return cached;
        }
      } catch (cacheError) {
        // Ignore cache errors
      }
      rethrow;
    }
  }

  @override
  Future<List<Booking>> getPhotographerBookings(String photographerId) async {
    return await remoteDataSource.getPhotographerBookings(photographerId);
  }

  @override
  Future<Booking> getBookingById(String bookingId) async {
    return await remoteDataSource.getBookingById(bookingId);
  }

  @override
  Future<Booking> updateBookingStatus(String bookingId, String status) async {
    final booking =
        await remoteDataSource.updateBookingStatus(bookingId, status);

    // Invalidate cache after updating (don't fail if it fails)
    try {
      await localDataSource.clearCache();
    } catch (e) {
      // Ignore cache errors
    }

    return booking;
  }

  @override
  Future<void> cancelBooking(String bookingId, String reason) async {
    await remoteDataSource.cancelBooking(bookingId, reason);

    // Invalidate cache after cancelling (don't fail if it fails)
    try {
      await localDataSource.clearCache();
    } catch (e) {
      // Ignore cache errors
    }
  }

  @override
  Future<List<String>> checkAvailability(
      String photographerId, DateTime date) async {
    return await remoteDataSource.checkAvailability(photographerId, date);
  }
}
