import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/get_my_bookings_usecase.dart';
import '../../domain/usecases/cancel_booking_usecase.dart';
import '../../domain/usecases/check_availability_usecase.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/datasources/booking_local_datasource.dart';
import '../../../../core/network/api_client.dart';
import '../../../../services/socket/socket_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../services/sync/sync_service.dart';

// Booking State
class BookingState {
  final bool isLoading;
  final String? error;
  final List<Booking> bookings;
  final Booking? currentBooking;
  final bool isAvailable;
  final bool isCheckingAvailability;

  const BookingState({
    this.isLoading = false,
    this.error,
    this.bookings = const [],
    this.currentBooking,
    this.isAvailable = false,
    this.isCheckingAvailability = false,
  });

  BookingState copyWith({
    bool? isLoading,
    String? error,
    List<Booking>? bookings,
    Booking? currentBooking,
    bool? isAvailable,
    bool? isCheckingAvailability,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bookings: bookings ?? this.bookings,
      currentBooking: currentBooking ?? this.currentBooking,
      isAvailable: isAvailable ?? this.isAvailable,
      isCheckingAvailability:
          isCheckingAvailability ?? this.isCheckingAvailability,
    );
  }
}

// Booking Notifier
class BookingNotifier extends StateNotifier<BookingState> {
  final CreateBookingUseCase createBookingUseCase;
  final GetMyBookingsUseCase getMyBookingsUseCase;
  final CancelBookingUseCase cancelBookingUseCase;
  final CheckAvailabilityUseCase checkAvailabilityUseCase;
  final BookingRepositoryImpl repository;
  final SocketService socketService;

  BookingNotifier({
    required this.createBookingUseCase,
    required this.getMyBookingsUseCase,
    required this.cancelBookingUseCase,
    required this.checkAvailabilityUseCase,
    required this.repository,
    required this.socketService,
  }) : super(const BookingState()) {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    print('🔧 [BookingProvider] Setting up socket listeners');

    // Listen for new bookings
    socketService.onNewBooking((data) {
      if (!mounted) return;
      print('📅 [BookingProvider] New booking received via Socket!');
      print('   Refreshing bookings list...');
      getPhotographerBookings();
    });

    // Listen for booking status updates
    socketService.onBookingStatusUpdated((data) {
      if (!mounted) return;
      print('📝 [BookingProvider] Booking status updated via Socket!');
      print('   Refreshing bookings list...');
      getPhotographerBookings();
    });

    // Listen for pending bookings count updates
    socketService.onPendingBookingsUpdate((data) {
      if (!mounted) return;
      print('⏳ [BookingProvider] Pending bookings count update via Socket!');
      print('   Refreshing bookings list...');
      getPhotographerBookings();
    });

    print('✅ [BookingProvider] Socket listeners setup complete');
  }

  Future<void> createBooking({
    required String photographerId,
    String? packageId,
    required DateTime date,
    required String timeSlot,
    required String location,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final syncService = SyncService();
      final isOnline = await syncService.isOnline();

      if (!isOnline) {
        print('⚠️ Device is offline, adding booking to pending actions');
        await syncService.addPendingAction('create_booking', {
          'photographerId': photographerId,
          'packageId': packageId,
          'date': date.toIso8601String(),
          'timeSlot': timeSlot,
          'location': location,
          'notes': notes,
        });

        state = state.copyWith(isLoading: false);
        // We can't show the booking immediately without more complex logic,
        // but we can stop the loading state and maybe show a success message via UI (handled by UI consuming this provider)
        return;
      }

      print('📤 Creating booking...');
      final booking = await createBookingUseCase.call(
        photographerId: photographerId,
        packageId: packageId ?? '',
        date: date,
        timeSlot: timeSlot,
        location: location,
        notes: notes,
      );

      print('✅ Booking created successfully: ${booking.id}');
      print(
        '   Adding to bookings list (current count: ${state.bookings.length})',
      );

      state = state.copyWith(
        isLoading: false,
        currentBooking: booking,
        bookings: [booking, ...state.bookings],
      );

      print('✅ State updated (new count: ${state.bookings.length})');
    } catch (e) {
      print('❌ Error creating booking: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> getMyBookings() async {
    print('📥 Loading my bookings...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final bookings = await getMyBookingsUseCase.call();
      print('✅ Loaded ${bookings.length} bookings');
      state = state.copyWith(isLoading: false, bookings: bookings);
      print('✅ State updated with ${state.bookings.length} bookings');
    } catch (e) {
      print('❌ Error loading bookings: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getPhotographerBookings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Backend automatically filters by photographer based on user role
      final bookings = await getMyBookingsUseCase.call();
      state = state.copyWith(isLoading: false, bookings: bookings);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cancelBooking(String bookingId, [String? reason]) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await cancelBookingUseCase.call(
        bookingId,
        reason ?? 'تم الإلغاء من قبل المستخدم',
      );

      final updatedBookings = state.bookings
          .map(
            (b) => b.id == bookingId
                ? Booking(
                    id: b.id,
                    photographerId: b.photographerId,
                    clientId: b.clientId,
                    packageId: b.packageId,
                    packageName: b.packageName,
                    date: b.date,
                    timeSlot: b.timeSlot,
                    location: b.location,
                    status: 'cancelled',
                    price: b.price,
                    totalPrice: b.totalPrice,
                    notes: b.notes,
                    createdAt: b.createdAt,
                    confirmedAt: b.confirmedAt,
                    completedAt: b.completedAt,
                    cancelledAt: DateTime.now(),
                    cancellationReason: reason,
                  )
                : b,
          )
          .toList();

      state = state.copyWith(isLoading: false, bookings: updatedBookings);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('📤 Updating booking status: $bookingId -> $status');

      // Call repository to update status in backend
      final updatedBooking = await repository.updateBookingStatus(
        bookingId,
        status,
      );

      print('✅ Booking status updated in backend');

      // Update local state with the response from backend
      final updatedBookings = state.bookings
          .map((b) => b.id == bookingId ? updatedBooking : b)
          .toList();

      state = state.copyWith(isLoading: false, bookings: updatedBookings);
      print('✅ Local state updated');
    } catch (e) {
      print('❌ Error updating booking status: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<List<String>> checkAvailability({
    required String photographerId,
    required DateTime date,
  }) async {
    state = state.copyWith(isCheckingAvailability: true, error: null);

    try {
      final availableSlots = await checkAvailabilityUseCase.call(
        photographerId,
        date,
      );

      state = state.copyWith(
        isCheckingAvailability: false,
        isAvailable: availableSlots.isNotEmpty,
      );

      return availableSlots;
    } catch (e) {
      state = state.copyWith(
        isCheckingAvailability: false,
        error: e.toString(),
        isAvailable: false,
      );
      return [];
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearCurrentBooking() {
    state = state.copyWith(currentBooking: null);
  }
}

// Providers
final bookingLocalDataSourceProvider = Provider<BookingLocalDataSource>((ref) {
  final offlineService = OfflineService();
  return BookingLocalDataSourceImpl(offlineService);
});

final bookingRepositoryProvider = Provider((ref) {
  return BookingRepositoryImpl(
    remoteDataSource: BookingRemoteDataSourceImpl(ApiClient()),
    localDataSource: ref.watch(bookingLocalDataSourceProvider),
  );
});

final createBookingUseCaseProvider = Provider((ref) {
  return CreateBookingUseCase(ref.watch(bookingRepositoryProvider));
});

final getMyBookingsUseCaseProvider = Provider((ref) {
  return GetMyBookingsUseCase(ref.watch(bookingRepositoryProvider));
});

final cancelBookingUseCaseProvider = Provider((ref) {
  return CancelBookingUseCase(ref.watch(bookingRepositoryProvider));
});

final checkAvailabilityUseCaseProvider = Provider((ref) {
  return CheckAvailabilityUseCase(ref.watch(bookingRepositoryProvider));
});

// Socket service provider (singleton)
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((
  ref,
) {
  return BookingNotifier(
    createBookingUseCase: ref.read(createBookingUseCaseProvider),
    getMyBookingsUseCase: ref.read(getMyBookingsUseCaseProvider),
    cancelBookingUseCase: ref.read(cancelBookingUseCaseProvider),
    checkAvailabilityUseCase: ref.read(checkAvailabilityUseCaseProvider),
    repository: ref.read(bookingRepositoryProvider),
    socketService: ref.read(socketServiceProvider),
  );
});
