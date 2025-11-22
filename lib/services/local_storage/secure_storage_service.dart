import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing secure storage
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: accessTokenKey, value: token);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: accessTokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: refreshTokenKey, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: refreshTokenKey);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: userIdKey, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: userIdKey);
  }

  /// Save user role
  Future<void> saveUserRole(String role) async {
    await _storage.write(key: userRoleKey, value: role);
  }

  /// Get user role
  Future<String?> getUserRole() async {
    return await _storage.read(key: userRoleKey);
  }

  /// Save auth data
  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String role,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUserId(userId),
      saveUserRole(role),
    ]);
  }

  /// Clear auth data
  Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: accessTokenKey),
      _storage.delete(key: refreshTokenKey),
      _storage.delete(key: userIdKey),
      _storage.delete(key: userRoleKey),
    ]);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all secure storage
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
