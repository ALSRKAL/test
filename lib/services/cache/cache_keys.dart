/// Cache keys for Hive boxes
class CacheKeys {
  // Box names
  static const String photographersBox = 'photographers';
  static const String bookingsBox = 'bookings';
  static const String reviewsBox = 'reviews';
  static const String userBox = 'user';
  static const String settingsBox = 'settings';

  // Cache keys
  static const String photographersList = 'photographers_list';
  static const String photographerDetails = 'photographer_details_';
  static const String userBookings = 'user_bookings';
  static const String photographerBookings = 'photographer_bookings';
  static const String photographerReviews = 'photographer_reviews_';
  static const String userProfile = 'user_profile';

  // Settings keys
  static const String isDarkMode = 'is_dark_mode';
  static const String language = 'language';
  static const String notificationsEnabled = 'notifications_enabled';

  // Cache expiry (in hours)
  static const int photographersListExpiry = 1;
  static const int photographerDetailsExpiry = 2;
  static const int bookingsExpiry = 1;
  static const int reviewsExpiry = 2;
  static const int userProfileExpiry = 24;
}
