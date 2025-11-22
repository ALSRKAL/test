import '../../../../core/services/offline_service.dart';

/// مصدر البيانات المحلي للإشعارات
class NotificationLocalDataSource {
  final OfflineService _offlineService;

  NotificationLocalDataSource(this._offlineService);

  // حفظ الإشعارات محلياً
  Future<void> saveNotifications(
    String userId,
    List<Map<String, dynamic>> notifications,
  ) async {
    for (final notification in notifications) {
      await _offlineService.saveNotificationLocally({
        ...notification,
        'userId': userId,
      });
    }
  }

  // الحصول على الإشعارات المحلية
  Future<List<Map<String, dynamic>>> getLocalNotifications(
    String userId,
  ) async {
    return await _offlineService.getLocalNotifications(userId);
  }

  // تحديث حالة القراءة
  Future<void> markAsRead(String notificationId, String userId) async {
    // يمكن إضافة منطق التحديث هنا
    await _offlineService.addToSyncQueue(
      operation: 'mark_notification_read',
      endpoint: '/api/notifications/$notificationId/read',
      method: 'PATCH',
      data: {},
    );
  }

  // حذف إشعار محلياً
  Future<void> deleteNotification(String notificationId) async {
    await _offlineService.deleteNotificationLocally(notificationId);
  }

  // حذف جميع الإشعارات محلياً
  Future<void> deleteAllNotifications() async {
    await _offlineService.deleteAllNotificationsLocally();
  }
}
