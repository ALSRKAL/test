import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<BookingModel> createBooking({
    required String photographerId,
    required String packageId,
    required DateTime date,
    required String timeSlot,
    required String location,
    String? notes,
  });

  Future<List<BookingModel>> getMyBookings();
  Future<List<BookingModel>> getPhotographerBookings(String photographerId);
  Future<BookingModel> getBookingById(String bookingId);
  Future<BookingModel> updateBookingStatus(String bookingId, String status);
  Future<void> cancelBooking(String bookingId, String reason);
  Future<List<String>> checkAvailability(String photographerId, DateTime date);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final ApiClient apiClient;

  BookingRemoteDataSourceImpl(this.apiClient);

  @override
  Future<BookingModel> createBooking({
    required String photographerId,
    required String packageId,
    required DateTime date,
    required String timeSlot,
    required String location,
    String? notes,
  }) async {
    try {
      Map<String, dynamic>? packageData;
      
      // If packageId is provided, get package details
      if (packageId.isNotEmpty) {
        final photographerResponse = await apiClient.get(
          ApiEndpoints.photographerDetails(photographerId),
        );

        final photographer = photographerResponse.data['data'];
        final packages = photographer['packages'] as List<dynamic>;
        final selectedPackage = packages.firstWhere(
          (pkg) => pkg['_id'] == packageId,
          orElse: () => throw Exception('Package not found'),
        );

        packageData = {
          'name': selectedPackage['name'],
          'price': selectedPackage['price'],
          'duration': selectedPackage['duration'],
          'features': selectedPackage['features'],
        };
      }

      final response = await apiClient.post(
        ApiEndpoints.bookings,
        data: {
          'photographer': photographerId,
          if (packageData != null) 'package': packageData,
          'date': date.toIso8601String(),
          'timeSlot': timeSlot,
          'location': location,
          if (notes != null) 'notes': notes,
        },
      );

      return BookingModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create booking',
      );
    }
  }

  @override
  Future<List<BookingModel>> getMyBookings() async {
    try {
      final response = await apiClient.get(ApiEndpoints.bookings);

      print('📥 GET /api/bookings response:');
      print('  - success: ${response.data['success']}');
      print('  - data length: ${(response.data['data'] as List).length}');

      final List<dynamic> data = response.data['data'];
      final bookings = data.map((json) {
        try {
          return BookingModel.fromJson(json);
        } catch (e) {
          print('❌ Error parsing booking: $e');
          print('   JSON: $json');
          rethrow;
        }
      }).toList();

      print('✅ Parsed ${bookings.length} bookings successfully');
      return bookings;
    } on DioException catch (e) {
      print('❌ DioException in getMyBookings: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Failed to get bookings');
    } catch (e) {
      print('❌ Exception in getMyBookings: $e');
      rethrow;
    }
  }

  @override
  Future<List<BookingModel>> getPhotographerBookings(
    String photographerId,
  ) async {
    try {
      // The backend automatically filters by photographer based on user role
      final response = await apiClient.get(ApiEndpoints.bookings);

      final List<dynamic> data = response.data['data'];
      return data.map((json) => BookingModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to get photographer bookings',
      );
    }
  }

  @override
  Future<BookingModel> getBookingById(String bookingId) async {
    try {
      final response = await apiClient.get(
        '${ApiEndpoints.bookings}/$bookingId',
      );

      return BookingModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to get booking details',
      );
    }
  }

  @override
  Future<BookingModel> updateBookingStatus(
    String bookingId,
    String status,
  ) async {
    try {
      final response = await apiClient.put(
        '${ApiEndpoints.bookings}/$bookingId/status',
        data: {'status': status},
      );

      return BookingModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update booking status',
      );
    }
  }

  @override
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await apiClient.put(
        '${ApiEndpoints.bookings}/$bookingId/cancel',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to cancel booking',
      );
    }
  }

  @override
  Future<List<String>> checkAvailability(
    String photographerId,
    DateTime date,
  ) async {
    try {
      final response = await apiClient.get(
        '${ApiEndpoints.bookings}/availability/$photographerId',
        queryParameters: {'date': date.toIso8601String().split('T')[0]},
      );

      final List<dynamic> slots = response.data['data']['availableSlots'];
      return slots.cast<String>();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to check availability',
      );
    }
  }
}
