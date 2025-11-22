import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<User> call({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    // Validation
    if (name.isEmpty) {
      throw Exception('Name is required');
    }

    if (email.isEmpty || !_isValidEmail(email)) {
      throw Exception('Valid email is required');
    }

    if (password.isEmpty || password.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }

    if (phone.isEmpty) {
      throw Exception('Phone number is required');
    }

    if (!['client', 'photographer'].contains(role)) {
      throw Exception('Invalid role');
    }

    return await repository.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}
