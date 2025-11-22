import 'package:hajzy/features/notifications/domain/entities/notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.body,
    super.data,
    required super.isRead,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] ?? json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: isRead,
      createdAt: createdAt,
    );
  }
}
