class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final List<String> favorites;
  final NotificationSettings notificationSettings;
  final UserStatistics statistics;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.favorites,
    required this.notificationSettings,
    required this.statistics,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    List<String>? favorites,
    NotificationSettings? notificationSettings,
    UserStatistics? statistics,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      favorites: favorites ?? this.favorites,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      statistics: statistics ?? this.statistics,
    );
  }
}

class NotificationSettings {
  final bool messages;
  final bool bookings;
  final bool reviews;

  NotificationSettings({
    required this.messages,
    required this.bookings,
    required this.reviews,
  });

  NotificationSettings copyWith({
    bool? messages,
    bool? bookings,
    bool? reviews,
  }) {
    return NotificationSettings(
      messages: messages ?? this.messages,
      bookings: bookings ?? this.bookings,
      reviews: reviews ?? this.reviews,
    );
  }
}

class UserStatistics {
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int totalReviews;
  final int favoritesCount;

  UserStatistics({
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalReviews,
    required this.favoritesCount,
  });
}
