import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<User> call(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('الرجاء إدخال البريد الإلكتروني وكلمة المرور');
    }

    if (!_isValidEmail(email)) {
      throw Exception('البريد الإلكتروني غير صحيح');
    }

    return await repository.login(email, password);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}
