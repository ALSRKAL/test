import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/services/socket/socket_service.dart';
import 'dart:developer' as developer;

/// State for booking notifications
class BookingNotificationState {
  final Map<String, dynamic>? latestBooking;
  final Map<String, dynamic>? latestStatusUpdate;
  final int unreadBookingsCount;

  const BookingNotificationState({
    this.latestBooking,
    this.latestStatusUpdate,
    this.unreadBookingsCount = 0,
  });

  BookingNotificationState copyWith({
    Map<String, dynamic>? latestBooking,
    Map<String, dynamic>? latestStatusUpdate,
    int? unreadBookingsCount,
  }) {
    return BookingNotificationState(
      latestBooking: latestBooking ?? this.latestBooking,
      latestStatusUpdate: latestStatusUpdate ?? this.latestStatusUpdate,
      unreadBookingsCount: unreadBookingsCount ?? this.unreadBookingsCount,
    );
  }
}

/// Notifier for booking notifications
class BookingNotificationsNotifier
    extends StateNotifier<BookingNotificationState> {
  final SocketService _socketService;

  BookingNotificationsNotifier(this._socketService)
    : super(const BookingNotificationState()) {
    developer.log('🔧 BookingNotificationsNotifier created', name: 'BookingNotifications');
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    developer.log('🔧 Setting up booking socket listeners', name: 'BookingNotifications');
    
    // Listen for new bookings (for photographers)
    _socketService.onNewBooking((data) {
      if (!mounted) return;
      
      developer.log('📅 New booking received via Socket!', name: 'BookingNotifications');
      developer.log('   Data: $data', name: 'BookingNotifications');

      try {
        state = state.copyWith(
          latestBooking: Map<String, dynamic>.from(data),
          unreadBookingsCount: state.unreadBookingsCount + 1,
        );
        
        developer.log('✅ State updated, unread count: ${state.unreadBookingsCount}', name: 'BookingNotifications');
      } catch (e, stackTrace) {
        developer.log('❌ Error handling new booking: $e', name: 'BookingNotifications');
        developer.log('   Stack trace: $stackTrace', name: 'BookingNotifications');
      }
    });

    // Listen for booking status updates (for clients)
    _socketService.onBookingStatusUpdated((data) {
      if (!mounted) return;
      
      developer.log('📝 Booking status updated via Socket!', name: 'BookingNotifications');
      developer.log('   Data: $data', name: 'BookingNotifications');

      try {
        state = state.copyWith(
          latestStatusUpdate: Map<String, dynamic>.from(data),
        );
        
        developer.log('✅ Status update state updated', name: 'BookingNotifications');
      } catch (e, stackTrace) {
        developer.log('❌ Error handling status update: $e', name: 'BookingNotifications');
        developer.log('   Stack trace: $stackTrace', name: 'BookingNotifications');
      }
    });

    // Listen for pending bookings count updates
    _socketService.onPendingBookingsUpdate((data) {
      if (!mounted) return;
      
      developer.log('⏳ Pending bookings count update via Socket!', name: 'BookingNotifications');
      developer.log('   Data: $data', name: 'BookingNotifications');
      
      try {
        final count = data['count'] as int? ?? 0;
        developer.log('   New count: $count', name: 'BookingNotifications');
        
        state = state.copyWith(unreadBookingsCount: count);
        
        developer.log('✅ Count state updated', name: 'BookingNotifications');
      } catch (e, stackTrace) {
        developer.log('❌ Error handling count update: $e', name: 'BookingNotifications');
        developer.log('   Stack trace: $stackTrace', name: 'BookingNotifications');
      }
    });

    developer.log('✅ Booking socket listeners setup complete', name: 'BookingNotifications');
  }

  void clearLatestBooking() {
    state = state.copyWith(latestBooking: null);
  }

  void clearLatestStatusUpdate() {
    state = state.copyWith(latestStatusUpdate: null);
  }

  void markBookingsAsRead() {
    state = state.copyWith(unreadBookingsCount: 0);
  }

  @override
  void dispose() {
    _socketService.removeListener('new_booking');
    _socketService.removeListener('booking_status_updated');
    super.dispose();
  }
}

// استخدام نفس SocketService instance من chat_provider
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

/// Provider for booking notifications
final bookingNotificationsProvider =
    StateNotifierProvider<
      BookingNotificationsNotifier,
      BookingNotificationState
    >((ref) {
      final socketService = ref.watch(socketServiceProvider);
      return BookingNotificationsNotifier(socketService);
    });
