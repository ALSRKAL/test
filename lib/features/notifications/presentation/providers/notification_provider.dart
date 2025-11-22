import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/network/api_client.dart';
import 'package:hajzy/core/services/offline_service.dart';
import 'package:hajzy/features/auth/presentation/providers/auth_provider.dart';
import 'package:hajzy/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:hajzy/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:hajzy/features/notifications/data/models/notification_model.dart';
import 'package:hajzy/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:hajzy/features/notifications/domain/entities/notification.dart';
import 'package:hajzy/features/notifications/domain/repositories/notification_repository.dart';
import 'package:hajzy/services/socket/socket_service.dart';

/// Provider لـ ApiClient
final apiClientProvider = Provider((ref) => ApiClient());

/// حالة الإشعارات
class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final bool isInitialized; // To track if we've loaded data at least once

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = true, // Start with loading state
    this.error,
    this.isInitialized = false,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Notifier للإشعارات
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;
  final SocketService _socketService;
  final String? _userId;

  NotificationNotifier(this._repository, this._socketService, this._userId)
    : super(const NotificationState()) {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    if (_userId == null) return;

    print('🔧 [NotificationProvider] Setting up socket listeners');

    // Listen for new notifications
    _socketService.onNewNotification((data) {
      if (!mounted) return;
      print('📬 [NotificationProvider] New notification received via Socket!');
      print('   Data: $data');

      try {
        final notification = NotificationModel.fromJson(data);
        print('   Parsed notification: ${notification.title}');
        addNotification(notification);
      } catch (e) {
        print('❌ [NotificationProvider] Error parsing notification: $e');
      }
    });

    // Listen for notification count updates
    _socketService.onNotificationCountUpdate((data) {
      if (!mounted) return;
      print('🔔 [NotificationProvider] Notification count update via Socket!');
      print('   Data: $data');

      final count = data['count'] as int? ?? 0;
      final increment = data['increment'] as bool? ?? false;

      if (increment) {
        // Increment current count
        print('   Incrementing count by: $count');
        final newCount = state.unreadCount + count;
        updateUnreadCount(newCount);
      } else {
        // Set absolute count
        print('   Setting count to: $count');
        updateUnreadCount(count);
      }
    });

    // Listen for notification updates (marked as read)
    _socketService.onNotificationUpdated((data) {
      if (!mounted) return;
      print('🔔 [NotificationProvider] Notification updated via Socket!');
      final notificationId = data['_id'] ?? data['id'];
      if (notificationId != null) {
        // Update local state
        final updatedNotifications = state.notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();

        final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        );
      }
    });

    // Listen for all notifications marked as read
    _socketService.onNotificationsMarkedAllRead((_) {
      if (!mounted) return;
      print(
        '🔔 [NotificationProvider] All notifications marked as read via Socket!',
      );
      final updatedNotifications = state.notifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    });

    // Listen for notification deletion
    _socketService.onNotificationDeleted((data) {
      if (!mounted) return;
      print('🗑️ [NotificationProvider] Notification deleted via Socket!');
      final notificationId = data['id'];
      if (notificationId != null) {
        final updatedNotifications = state.notifications
            .where((n) => n.id != notificationId)
            .toList();

        final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        );
      }
    });

    print('✅ [NotificationProvider] Socket listeners setup complete');
  }

  /// جلب جميع الإشعارات
  Future<void> getNotifications() async {
    if (_userId == null) {
      state = state.copyWith(isLoading: false, error: 'User not authenticated');
      return;
    }

    // Start loading
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Load local data first (Fast)
      final localNotifications = await _repository.getLocalNotifications(
        _userId!,
      );

      if (localNotifications.isNotEmpty) {
        final unreadCount = localNotifications.where((n) => !n.isRead).length;
        state = state.copyWith(
          notifications: localNotifications,
          unreadCount: unreadCount,
          // Keep isLoading true because we are still syncing
          isInitialized: true,
        );
      }

      // 2. Sync with remote (Slow)
      final remoteNotifications = await _repository.syncNotifications(_userId!);
      final unreadCount = remoteNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: remoteNotifications,
        unreadCount: unreadCount,
        isLoading: false,
        isInitialized: true,
      );
    } catch (e) {
      // If we have local data, don't show error screen, just show snackbar or keep silent
      // But if we have NO data, show error
      if (state.notifications.isNotEmpty) {
        state = state.copyWith(isLoading: false);
        // Optionally set a transient error or just log it
        print('Error syncing notifications: $e');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
          isInitialized: true,
        );
      }
    }
  }

  /// جلب عدد الإشعارات غير المقروءة
  Future<void> getUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      // Silent fail for unread count
    }
  }

  /// تحديد إشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);

      // تحديث الحالة المحلية
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      // Handle error
    }
  }

  /// تحديد جميع الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();

      // تحديث الحالة المحلية
      final updatedNotifications = state.notifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      // Handle error
    }
  }

  /// حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);

      // تحديث الحالة المحلية
      final updatedNotifications = state.notifications
          .where((n) => n.id != notificationId)
          .toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      // Handle error
    }
  }

  /// حذف جميع الإشعارات
  Future<void> deleteAllNotifications() async {
    try {
      await _repository.deleteAllNotifications();

      state = state.copyWith(notifications: [], unreadCount: 0);
    } catch (e) {
      // Handle error
    }
  }

  /// إضافة إشعار جديد (من Socket.IO)
  void addNotification(AppNotification notification) {
    final updatedNotifications = [notification, ...state.notifications];
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );

    // Also save to local if possible (requires converting back to JSON or updating repository to support save)
    // For now, we just update state. Ideally, we should persist this too.
  }

  /// تحديث عدد الإشعارات غير المقروءة
  void updateUnreadCount(int count) {
    state = state.copyWith(unreadCount: count);
  }
}

/// Provider for SocketService (singleton)
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

/// Provider للإشعارات
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      final authState = ref.watch(authProvider);
      final userId = authState.user?.id;

      final remoteDataSource = NotificationRemoteDataSource(apiClient);
      final localDataSource = NotificationLocalDataSource(OfflineService());
      final repository = NotificationRepositoryImpl(
        remoteDataSource,
        localDataSource,
      );

      final socketService = ref.read(socketServiceProvider);

      return NotificationNotifier(repository, socketService, userId);
    });
