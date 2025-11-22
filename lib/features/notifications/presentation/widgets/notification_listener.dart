import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/features/auth/presentation/providers/auth_provider.dart';
import 'package:hajzy/features/notifications/presentation/providers/notification_provider.dart';
import 'package:hajzy/features/notifications/data/models/notification_model.dart';
import 'package:hajzy/features/booking/presentation/providers/booking_provider.dart';
import 'package:hajzy/features/chat/presentation/providers/chat_provider.dart';
import 'package:hajzy/services/socket/socket_service.dart';
import 'dart:developer' as developer;

// استخدام نفس socketServiceProvider من chat_provider
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

/// Widget للاستماع للإشعارات Real-time
class NotificationListener extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NotificationListener> createState() =>
      _NotificationListenerState();
}

class _NotificationListenerState extends ConsumerState<NotificationListener> {
  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();
    // استخدام نفس SocketService instance من chat_provider
    _socketService = ref.read(socketServiceProvider);
    developer.log('🔧 NotificationListener initialized', name: 'NotificationListener');
    developer.log('   Socket connected: ${_socketService.isConnected}', name: 'NotificationListener');
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    developer.log('🔧 Setting up notification socket listeners', name: 'NotificationListener');
    developer.log('   Socket connected: ${_socketService.isConnected}', name: 'NotificationListener');

    // الاستماع للإشعارات الجديدة
    _socketService.onNewNotification((data) {
      if (!mounted) return;
      
      developer.log('📬 New notification received via Socket!', name: 'NotificationListener');
      developer.log('   Data: $data', name: 'NotificationListener');
      
      try {
        final notification = NotificationModel.fromJson(data);
        developer.log('   Parsed notification: ${notification.title}', name: 'NotificationListener');
        ref.read(notificationProvider.notifier).addNotification(notification);
        
        // عرض SnackBar للإشعار
        if (mounted) {
          _showNotificationSnackBar(notification);
        }
      } catch (e, stackTrace) {
        developer.log('❌ Error parsing notification: $e', name: 'NotificationListener');
        developer.log('   Stack trace: $stackTrace', name: 'NotificationListener');
      }
    });

    // الاستماع لتحديثات عدد الإشعارات
    _socketService.onNotificationCountUpdate((data) {
      if (!mounted) return;
      
      developer.log('🔔 Notification count update via Socket!', name: 'NotificationListener');
      developer.log('   Data: $data', name: 'NotificationListener');
      
      final count = data['count'] as int? ?? 0;
      ref.read(notificationProvider.notifier).updateUnreadCount(count);
    });

    // الاستماع للحجوزات الجديدة
    _socketService.onNewBooking((data) {
      if (!mounted) return;
      
      developer.log('📅 New booking received via Socket!', name: 'NotificationListener');
      developer.log('   Data: $data', name: 'NotificationListener');
      developer.log('   Refreshing bookings list...', name: 'NotificationListener');
      
      // تحديث قائمة الحجوزات فوراً (للمصورة والمستخدم)
      final user = ref.read(authProvider).user;
      if (user?.role == 'photographer') {
        ref.read(bookingProvider.notifier).getPhotographerBookings();
      } else {
        ref.read(bookingProvider.notifier).getMyBookings();
      }
    });

    // الاستماع لتحديثات حالة الحجز
    _socketService.onBookingStatusUpdated((data) {
      if (!mounted) return;
      
      developer.log('📝 Booking status updated via Socket!', name: 'NotificationListener');
      developer.log('   Data: $data', name: 'NotificationListener');
      
      // تحديث قائمة الحجوزات فوراً (للمصورة والمستخدم)
      final user = ref.read(authProvider).user;
      if (user?.role == 'photographer') {
        ref.read(bookingProvider.notifier).getPhotographerBookings();
      } else {
        ref.read(bookingProvider.notifier).getMyBookings();
      }
    });

    // الاستماع لتحديثات عدد الحجوزات المعلقة
    _socketService.onPendingBookingsUpdate((data) {
      if (!mounted) return;
      
      developer.log('⏳ Pending bookings count update via Socket!', name: 'NotificationListener');
      developer.log('   Data: $data', name: 'NotificationListener');
      developer.log('   Count: ${data['count']}', name: 'NotificationListener');
      developer.log('   Refreshing bookings list...', name: 'NotificationListener');
      
      // تحديث قائمة الحجوزات فوراً (للمصورة والمستخدم)
      final user = ref.read(authProvider).user;
      if (user?.role == 'photographer') {
        ref.read(bookingProvider.notifier).getPhotographerBookings();
      } else {
        ref.read(bookingProvider.notifier).getMyBookings();
      }
    });

    // الاستماع لتحديثات الرسائل غير المقروءة
    _socketService.onUnreadMessagesUpdate((data) {
      if (!mounted) return;
      
      developer.log('💬 Unread messages update via Socket!', name: 'NotificationListener');
      developer.log('   Data: $data', name: 'NotificationListener');
      
      final count = data['count'] as int? ?? 0;
      ref.read(chatProvider.notifier).updateUnreadCount(count);
    });

    // الاستماع للرسائل الجديدة
    _socketService.onNewMessage((data) {
      developer.log('💬 New message received: $data', name: 'NotificationListener');
      
      // تحديث عدد الرسائل غير المقروءة
      ref.read(chatProvider.notifier).getUnreadCount();
    });

    developer.log('✅ Notification socket listeners setup complete', name: 'NotificationListener');
  }

  void _showNotificationSnackBar(NotificationModel notification) {
    final context = this.context;
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getNotificationIcon(notification.type),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _getNotificationColor(notification.type),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'عرض',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/notifications');
          },
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.event_note;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'review':
        return Icons.star_outline;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking':
        return Colors.orange;
      case 'message':
        return Colors.blue;
      case 'review':
        return Colors.amber;
      case 'payment':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      _socketService.leaveNotificationsRoom(user.id);
      _socketService.leaveBookingsRoom(user.id);
    }
    
    // إزالة المستمعين
    _socketService.removeListener('new_notification');
    _socketService.removeListener('notification_count_update');
    _socketService.removeListener('new_booking');
    _socketService.removeListener('booking_status_updated');
    _socketService.removeListener('pending_bookings_update');
    _socketService.removeListener('unread_messages_update');
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
