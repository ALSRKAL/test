import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../booking/presentation/providers/booking_provider.dart';

/// Notifications State
class NotificationsState {
  final int unreadMessages;
  final int pendingBookings;
  final int newReviews;
  final bool isLoading;

  const NotificationsState({
    this.unreadMessages = 0,
    this.pendingBookings = 0,
    this.newReviews = 0,
    this.isLoading = false,
  });

  int get totalCount => unreadMessages + pendingBookings + newReviews;

  NotificationsState copyWith({
    int? unreadMessages,
    int? pendingBookings,
    int? newReviews,
    bool? isLoading,
  }) {
    return NotificationsState(
      unreadMessages: unreadMessages ?? this.unreadMessages,
      pendingBookings: pendingBookings ?? this.pendingBookings,
      newReviews: newReviews ?? this.newReviews,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifications Notifier
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref ref;

  NotificationsNotifier(this.ref) : super(const NotificationsState()) {
    _initialize();
  }

  void _initialize() {
    // Listen to chat provider for unread messages
    ref.listen(chatProvider, (previous, next) {
      if (mounted) {
        state = state.copyWith(unreadMessages: next.totalUnreadCount);
      }
    });

    // Listen to booking provider for pending bookings
    ref.listen(bookingProvider, (previous, next) {
      if (mounted) {
        final pendingCount = next.bookings
            .where((b) => b.status == 'pending')
            .length;
        state = state.copyWith(pendingBookings: pendingCount);
      }
    });

    // Load initial data
    Future.microtask(() => loadNotifications());
  }

  Future<void> loadNotifications() async {
    if (!mounted) return;

    state = state.copyWith(isLoading: true);

    try {
      // Load unread messages count
      await ref.read(chatProvider.notifier).getUnreadCount();
      
      // Load bookings to count pending ones
      await ref.read(bookingProvider.notifier).getPhotographerBookings();

      if (mounted) {
        final chatState = ref.read(chatProvider);
        final bookingState = ref.read(bookingProvider);

        final pendingCount = bookingState.bookings
            .where((b) => b.status == 'pending')
            .length;

        state = state.copyWith(
          unreadMessages: chatState.totalUnreadCount,
          pendingBookings: pendingCount,
          isLoading: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void markMessagesAsRead() {
    if (mounted) {
      state = state.copyWith(unreadMessages: 0);
    }
  }

  void markBookingsAsViewed() {
    if (mounted) {
      state = state.copyWith(pendingBookings: 0);
    }
  }

  void clearAll() {
    if (mounted) {
      state = const NotificationsState();
    }
  }
}

/// Provider
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref);
});
