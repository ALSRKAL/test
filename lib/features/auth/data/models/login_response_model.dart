import 'user_model.dart';

class LoginResponseModel {
  final bool success;
  final String message;
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  LoginResponseModel({
    required this.success,
    required this.message,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: UserModel.fromJson(json['data']['user']),
      accessToken: json['data']['accessToken'],
      refreshToken: json['data']['refreshToken'],
    );
  }
}
