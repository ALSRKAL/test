import 'package:hajzy/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:hajzy/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:hajzy/features/notifications/data/models/notification_model.dart';
import 'package:hajzy/features/notifications/domain/entities/notification.dart';
import 'package:hajzy/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;
  final NotificationLocalDataSource _localDataSource;

  NotificationRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<List<AppNotification>> getLocalNotifications(String userId) async {
    try {
      final localData = await _localDataSource.getLocalNotifications(userId);
      return localData.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<AppNotification>> syncNotifications(String userId) async {
    // 1. Fetch from remote
    final remoteNotifications = await _remoteDataSource.getNotifications();

    // 2. Save to local
    final notificationsJson = remoteNotifications
        .map((n) => n.toJson())
        .toList();
    await _localDataSource.saveNotifications(userId, notificationsJson);

    return remoteNotifications;
  }

  @override
  Future<int> getUnreadCount() async {
    return await _remoteDataSource.getUnreadCount();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _remoteDataSource.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead() async {
    await _remoteDataSource.markAllAsRead();
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _remoteDataSource.deleteNotification(notificationId);
    await _localDataSource.deleteNotification(notificationId);
  }

  @override
  Future<void> deleteAllNotifications() async {
    await _remoteDataSource.deleteAllNotifications();
    await _localDataSource.deleteAllNotifications();
  }
}
