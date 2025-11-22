import '../cache/cache_manager.dart';

/// Service for managing local storage using Hive
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  final CacheManager _cacheManager = CacheManager();

  /// Initialize Hive
  Future<void> initialize() async {
    await _cacheManager.initialize();
  }

  /// Save photographers list
  Future<void> savePhotographersList(
    List<Map<String, dynamic>> photographers,
  ) async {
    await _cacheManager.save(
      'photographers',
      'photographers_list',
      photographers,
    );
  }

  /// Get photographers list
  Future<List<Map<String, dynamic>>?> getPhotographersList() async {
    final data = await _cacheManager.getWithExpiry(
      'photographers',
      'photographers_list',
      1,
    );
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(data);
  }

  /// Save photographer details
  Future<void> savePhotographerDetails(
    String id,
    Map<String, dynamic> photographer,
  ) async {
    await _cacheManager.save('photographers', 'photographer_$id', photographer);
  }

  /// Get photographer details
  Future<Map<String, dynamic>?> getPhotographerDetails(String id) async {
    final data = await _cacheManager.getWithExpiry(
      'photographers',
      'photographer_$id',
      2,
    );
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  /// Save user bookings
  Future<void> saveUserBookings(List<Map<String, dynamic>> bookings) async {
    await _cacheManager.save('bookings', 'user_bookings', bookings);
  }

  /// Get user bookings
  Future<List<Map<String, dynamic>>?> getUserBookings() async {
    final data = await _cacheManager.getWithExpiry(
      'bookings',
      'user_bookings',
      1,
    );
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(data);
  }

  /// Save photographer reviews
  Future<void> savePhotographerReviews(
    String photographerId,
    List<Map<String, dynamic>> reviews,
  ) async {
    await _cacheManager.save('reviews', 'reviews_$photographerId', reviews);
  }

  /// Get photographer reviews
  Future<List<Map<String, dynamic>>?> getPhotographerReviews(
    String photographerId,
  ) async {
    final data = await _cacheManager.getWithExpiry(
      'reviews',
      'reviews_$photographerId',
      2,
    );
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(data);
  }

  /// Save user profile
  Future<void> saveUserProfile(Map<String, dynamic> user) async {
    await _cacheManager.save('user', 'user_profile', user);
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    final data = await _cacheManager.getWithExpiry('user', 'user_profile', 24);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  /// Clear all photographers cache
  Future<void> clearPhotographersCache() async {
    await _cacheManager.clearBox('photographers');
  }

  /// Clear all bookings cache
  Future<void> clearBookingsCache() async {
    await _cacheManager.clearBox('bookings');
  }

  /// Clear all reviews cache
  Future<void> clearReviewsCache() async {
    await _cacheManager.clearBox('reviews');
  }

  /// Clear all user cache
  Future<void> clearUserCache() async {
    await _cacheManager.clearBox('user');
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    await _cacheManager.clearAll();
  }

  /// Save pending actions
  Future<void> savePendingActions(List<Map<String, dynamic>> actions) async {
    await _cacheManager.save('sync', 'pending_actions', actions);
  }

  /// Get pending actions
  Future<List<Map<String, dynamic>>?> getPendingActions() async {
    final data = await _cacheManager.get('sync', 'pending_actions');
    if (data == null) return null;
    // Handle dynamic list conversion safely
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }
}
