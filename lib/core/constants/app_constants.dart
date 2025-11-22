/// ثوابت التطبيق العامة (بدون عناوين API)
/// General application constants (without API URLs)
/// 
/// ملاحظة: عناوين API موجودة في api_endpoints.dart
/// Note: API URLs are in api_endpoints.dart
class AppConstants {
  AppConstants._();

  // ============================================
  // 🌐 Network Configuration
  // ============================================
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // ============================================
  // 📄 Pagination
  // ============================================
  static const int pageSize = 20;
  static const int maxImagesPerPhotographer = 20;

  // ============================================
  // 🎥 Video Configuration
  // ============================================
  static const int maxVideoSizeMB = 100;
  static const int maxVideoDurationSeconds = 120;
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi'];

  // ============================================
  // 💾 Cache Configuration
  // ============================================
  static const int cacheMaxAge = 3600; // 1 hour in seconds
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB

  // ============================================
  // ✅ Validation Rules
  // ============================================
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // ============================================
  // 📅 Booking Rules
  // ============================================
  static const int maxBookingDaysInAdvance = 90;
  static const int minBookingHoursInAdvance = 24;

  // ============================================
  // ⭐ Rating Configuration
  // ============================================
  static const double minRating = 1.0;
  static const double maxRating = 5.0;

  // ============================================
  // 💰 Business Rules
  // ============================================
  static const double commissionRate = 0.15; // 15%

  // ============================================
  // 📦 Subscription Plans
  // ============================================
  static const Map<String, dynamic> basicPlan = {
    'name': 'Basic',
    'price': 0,
    'maxBookings': 5,
  };

  static const Map<String, dynamic> proPlan = {
    'name': 'Pro',
    'price': 10,
    'maxBookings': -1, // unlimited
  };

  static const Map<String, dynamic> premiumPlan = {
    'name': 'Premium',
    'price': 20,
    'maxBookings': -1, // unlimited
    'featured': true,
  };

  // ============================================
  // ⭐ Featured Listing
  // ============================================
  static const int featuredListingPrice = 5;
  static const int featuredListingDurationDays = 30;
}
