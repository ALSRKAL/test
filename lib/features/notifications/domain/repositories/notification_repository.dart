import 'package:hajzy/features/notifications/domain/entities/notification.dart';

abstract class NotificationRepository {
  /// جلب الإشعارات المحلية
  Future<List<AppNotification>> getLocalNotifications(String userId);

  /// مزامنة الإشعارات (جلب من السيرفر وحفظ محلياً)
  Future<List<AppNotification>> syncNotifications(String userId);

  /// جلب عدد الإشعارات غير المقروءة
  Future<int> getUnreadCount();

  /// تحديد إشعار كمقروء
  Future<void> markAsRead(String notificationId);

  /// تحديد جميع الإشعارات كمقروءة
  Future<void> markAllAsRead();

  /// حذف إشعار
  Future<void> deleteNotification(String notificationId);

  /// حذف جميع الإشعارات
  Future<void> deleteAllNotifications();
}
