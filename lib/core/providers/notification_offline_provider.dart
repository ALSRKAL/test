import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_service.dart';
import '../../features/notifications/data/datasources/notification_local_datasource.dart';

final notificationLocalDataSourceProvider = Provider<NotificationLocalDataSource>((ref) {
  return NotificationLocalDataSource(OfflineService());
});

final localNotificationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final localDataSource = ref.watch(notificationLocalDataSourceProvider);
    return await localDataSource.getLocalNotifications(userId);
  },
);
