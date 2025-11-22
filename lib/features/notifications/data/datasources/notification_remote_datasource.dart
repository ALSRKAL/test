import 'package:dio/dio.dart';
import 'package:hajzy/core/constants/api_endpoints.dart';
import 'package:hajzy/core/network/api_client.dart';
import 'package:hajzy/features/notifications/data/models/notification_model.dart';

class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSource(this._apiClient);

  /// جلب جميع الإشعارات
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.notifications);
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'فشل في جلب الإشعارات');
    }
  }

  /// جلب عدد الإشعارات غير المقروءة
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.notificationsUnreadCount,
      );
      return response.data['data']['count'] ?? 0;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'فشل في جلب عدد الإشعارات',
      );
    }
  }

  /// تحديد إشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.put(
        '${ApiEndpoints.notifications}/$notificationId/read',
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'فشل في تحديث الإشعار');
    }
  }

  /// تحديد جميع الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    try {
      await _apiClient.patch('${ApiEndpoints.notifications}/read-all');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'فشل في تحديث الإشعارات');
    }
  }

  /// حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiClient.delete('${ApiEndpoints.notifications}/$notificationId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'فشل في حذف الإشعار');
    }
  }

  /// حذف جميع الإشعارات
  Future<void> deleteAllNotifications() async {
    try {
      await _apiClient.delete(ApiEndpoints.notifications);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'فشل في حذف الإشعارات');
    }
  }
}
