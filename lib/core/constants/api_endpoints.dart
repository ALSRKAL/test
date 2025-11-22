/// مركز إدارة جميع عناوين API في التطبيق
/// Central API endpoints management for the entire application
class ApiEndpoints {
  ApiEndpoints._();

  // ============================================
  // 🌐 Base Configuration
  // ============================================
  
  /// عنوان API الأساسي - Cloudflare Tunnel
  /// Base API URL - Cloudflare Tunnel
  static const String baseUrl = 'https://jennifer-practical-den-fighting.trycloudflare.com/api';

  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetCode = '/auth/verify-reset-code';
  static const String resetPassword = '/auth/reset-password';

  // User Endpoints
  static const String profile = '/users/profile';
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String uploadAvatar = '/users/avatar';
  static const String deleteAvatar = '/users/avatar';
  static const String userFavorites = '/users/favorites';
  static const String notificationSettings = '/users/notification-settings';
  static const String userStatistics = '/users/statistics';
  static const String deleteAccount = '/users/account';

  // Photographer Endpoints
  static const String photographers = '/photographers';
  static const String myPhotographerProfile = '/photographers/me/profile';
  static String photographerDetails(String id) => '/photographers/$id';
  static String photographerPortfolio(String id) =>
      '/photographers/$id/portfolio';
  static String photographerPackages(String id) =>
      '/photographers/$id/packages';
  static String photographerReviews(String id) => '/photographers/$id/reviews';
  static String photographerAvailability(String id) =>
      '/photographers/$id/availability';

  // Booking Endpoints
  static const String bookings = '/bookings';
  static String bookingDetails(String id) => '/bookings/$id';
  static String updateBookingStatus(String id) => '/bookings/$id/status';
  static String cancelBooking(String id) => '/bookings/$id/cancel';
  static String bookedDates(String photographerId) =>
      '/bookings/booked-dates/$photographerId';

  // Review Endpoints
  static const String reviews = '/reviews';
  static String reviewDetails(String id) => '/reviews/$id';
  static String replyToReview(String id) => '/reviews/$id/reply';

  // Chat Endpoints
  static const String chat = '/chat';
  static const String conversations = '/chat/conversations';
  static const String createConversation = '/chat/conversations';
  static String conversationMessages(String id) =>
      '/chat/conversations/$id/messages';
  static const String sendMessage = '/chat/messages';
  static const String messages = '/chat/messages';
  static const String unreadCount = '/chat/unread-count';
  static String markConversationAsRead(String id) =>
      '/chat/conversations/$id/read';

  // Media Endpoints
  static const String media = '/media';
  static const String uploadImage = '/media/upload/image';
  static const String uploadVideo = '/media/upload/video';
  static const String uploadMultipleImages = '/media/upload/images';
  static String deleteMedia(String id) => '/media/$id';

  // Portfolio Media Endpoints (simplified - uses current user)
  static String deletePortfolioImage(String imageId) =>
      '/media/portfolio/images/$imageId';
  static const String deletePortfolioVideo = '/media/portfolio/video';

  // Subscription Endpoints
  static const String subscriptionPlans = '/subscriptions/plans';
  static const String subscribe = '/subscriptions/subscribe';
  static const String mySubscription = '/subscriptions/my-subscription';
  static const String cancelSubscription = '/subscriptions/cancel';

  // Verification Endpoints
  static const String submitVerification = '/verification/submit';
  static const String verificationStatus = '/verification/status';
  static const String uploadVerificationDocs = '/verification/upload-documents';

  // Search & Filter
  static const String searchPhotographers = '/photographers/search';
  static const String filterPhotographers = '/photographers/filter';
  static const String featuredPhotographers = '/photographers/featured';

  // Favorites
  static String addToFavorites(String id) => '/photographers/$id/favorite';
  static String removeFromFavorites(String id) => '/photographers/$id/favorite';
  static const String getFavorites = '/photographers/favorites';

  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationDetails(String id) => '/notifications/$id';
  static String markNotificationAsRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsAsRead = '/notifications/read-all';

  // ============================================
  // 🔌 Socket.IO Configuration
  // ============================================
  
  /// عنوان Socket.IO - Cloudflare Tunnel
  /// Socket.IO URL - Cloudflare Tunnel
  static const String socketUrl = 'https://jennifer-practical-den-fighting.trycloudflare.com';
}
