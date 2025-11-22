import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  });
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<String> refreshToken();
  Future<bool> isLoggedIn();
}
