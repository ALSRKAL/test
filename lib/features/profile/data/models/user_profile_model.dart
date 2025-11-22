import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  UserProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.avatar,
    required super.role,
    required super.isActive,
    required super.createdAt,
    required super.favorites,
    required super.notificationSettings,
    required super.statistics,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    String? avatarUrl = json['avatar'];
    if (avatarUrl != null && avatarUrl.startsWith('http://')) {
      avatarUrl = avatarUrl.replaceFirst('http://', 'https://');
    }

    return UserProfileModel(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: avatarUrl,
      role: json['role'] ?? 'client',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      favorites: json['favorites'] != null
          ? List<String>.from(json['favorites'].map((f) => 
              f is String ? f : f['_id'] ?? f['id']))
          : [],
      notificationSettings: json['notificationSettings'] != null
          ? NotificationSettingsModel.fromJson(json['notificationSettings'])
          : NotificationSettings(messages: true, bookings: true, reviews: true),
      statistics: json['statistics'] != null
          ? UserStatisticsModel.fromJson(json['statistics'])
          : UserStatistics(
              totalBookings: 0,
              completedBookings: 0,
              cancelledBookings: 0,
              totalReviews: 0,
              favoritesCount: 0,
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'favorites': favorites,
      'notificationSettings': NotificationSettingsModel(
        messages: notificationSettings.messages,
        bookings: notificationSettings.bookings,
        reviews: notificationSettings.reviews,
      ).toJson(),
    };
  }
}

class NotificationSettingsModel extends NotificationSettings {
  NotificationSettingsModel({
    required super.messages,
    required super.bookings,
    required super.reviews,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      messages: json['messages'] ?? true,
      bookings: json['bookings'] ?? true,
      reviews: json['reviews'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messages': messages,
      'bookings': bookings,
      'reviews': reviews,
    };
  }
}

class UserStatisticsModel extends UserStatistics {
  UserStatisticsModel({
    required super.totalBookings,
    required super.completedBookings,
    required super.cancelledBookings,
    required super.totalReviews,
    required super.favoritesCount,
  });

  factory UserStatisticsModel.fromJson(Map<String, dynamic> json) {
    return UserStatisticsModel(
      totalBookings: json['totalBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      cancelledBookings: json['cancelledBookings'] ?? 0,
      totalReviews: json['totalReviews'] ?? 0,
      favoritesCount: json['favoritesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBookings': totalBookings,
      'completedBookings': completedBookings,
      'cancelledBookings': cancelledBookings,
      'totalReviews': totalReviews,
      'favoritesCount': favoritesCount,
    };
  }
}
