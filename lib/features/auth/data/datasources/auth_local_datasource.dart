import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'dart:convert';

abstract class AuthLocalDataSource {
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> saveRememberMe(bool rememberMe);
  Future<bool> getRememberMe();
  Future<void> clearAuth();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _rememberMeKey = 'remember_me';

  AuthLocalDataSourceImpl(this.secureStorage);

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    print('DEBUG Local Storage: Saving tokens...');
    await secureStorage.write(key: _accessTokenKey, value: accessToken);
    await secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    print('DEBUG Local Storage: Tokens saved successfully');
  }

  @override
  Future<String?> getAccessToken() async {
    final token = await secureStorage.read(key: _accessTokenKey);
    print('DEBUG Local Storage: Getting access token, exists: ${token != null}');
    return token;
  }

  @override
  Future<String?> getRefreshToken() async {
    final token = await secureStorage.read(key: _refreshTokenKey);
    print('DEBUG Local Storage: Getting refresh token, exists: ${token != null}');
    return token;
  }

  @override
  Future<void> saveUser(UserModel user) async {
    print('💾 DEBUG Local Storage: Saving user...');
    print('  - Name: ${user.name}');
    print('  - Role: ${user.role}');
    print('  - Email: ${user.email}');
    final userJson = jsonEncode(user.toJson());
    print('  - JSON length: ${userJson.length}');
    await secureStorage.write(key: _userKey, value: userJson);
    print('✅ DEBUG Local Storage: User saved successfully');
  }

  @override
  Future<UserModel?> getUser() async {
    print('📖 DEBUG Local Storage: Getting user...');
    final userJson = await secureStorage.read(key: _userKey);
    if (userJson == null) {
      print('❌ DEBUG Local Storage: No user found in storage');
      return null;
    }

    print('  - JSON found, length: ${userJson.length}');
    final userMap = jsonDecode(userJson) as Map<String, dynamic>;
    final user = UserModel.fromJson(userMap);
    print('✅ DEBUG Local Storage: User loaded successfully');
    print('  - Name: ${user.name}');
    print('  - Role: ${user.role}');
    print('  - Email: ${user.email}');
    return user;
  }

  @override
  Future<void> saveRememberMe(bool rememberMe) async {
    print('💾 DEBUG Local Storage: Saving rememberMe = $rememberMe');
    await secureStorage.write(key: _rememberMeKey, value: rememberMe.toString());
    print('✅ DEBUG Local Storage: RememberMe saved');
  }

  @override
  Future<bool> getRememberMe() async {
    final value = await secureStorage.read(key: _rememberMeKey);
    print('📖 DEBUG Local Storage: Getting rememberMe...');
    print('  - Raw value: $value');
    // If not set, default to true (remember by default)
    if (value == null) {
      print('  - Not set, defaulting to TRUE');
      return true;
    }
    final result = value == 'true';
    print('  - Result: $result');
    return result;
  }

  @override
  Future<void> clearAuth() async {
    final rememberMe = await getRememberMe();
    
    await secureStorage.delete(key: _accessTokenKey);
    await secureStorage.delete(key: _refreshTokenKey);
    await secureStorage.delete(key: _userKey);
    
    // Keep remember me preference if it was true
    if (!rememberMe) {
      await secureStorage.delete(key: _rememberMeKey);
    }
  }
}
