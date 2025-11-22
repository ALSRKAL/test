import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/error_handler.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await remoteDataSource.login(email, password);

      // Save tokens and user data locally
      await localDataSource.saveTokens(
        response.accessToken,
        response.refreshToken,
      );
      await localDataSource.saveUser(response.user);

      // Set access token in API client for authenticated requests
      ApiClient.setAccessToken(response.accessToken);

      return response.user;
    } catch (e) {
      // إعادة رمي الخطأ كما هو لأنه تم معالجته بالفعل
      rethrow;
    }
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );

      // Save tokens and user data locally
      await localDataSource.saveTokens(
        response.accessToken,
        response.refreshToken,
      );
      await localDataSource.saveUser(response.user);

      // Set access token in API client for authenticated requests
      ApiClient.setAccessToken(response.accessToken);

      return response.user;
    } catch (e) {
      // إعادة رمي الخطأ كما هو لأنه تم معالجته بالفعل
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await localDataSource.clearAuth();
      // Clear access token from API client
      ApiClient.clearAccessToken();
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      return await localDataSource.getUser();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> refreshToken() async {
    try {
      final oldRefreshToken = await localDataSource.getRefreshToken();
      if (oldRefreshToken == null) {
        throw Exception('انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.');
      }

      final newAccessToken = await remoteDataSource.refreshToken(
        oldRefreshToken,
      );
      await localDataSource.saveTokens(newAccessToken, oldRefreshToken);

      // Update access token in API client
      ApiClient.setAccessToken(newAccessToken);

      return newAccessToken;
    } catch (e) {
      // إعادة رمي الخطأ كما هو لأنه تم معالجته بالفعل
      rethrow;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final accessToken = await localDataSource.getAccessToken();
      return accessToken != null;
    } catch (e) {
      return false;
    }
  }
}
