import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/login_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login(String email, String password);
  Future<LoginResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  });
  Future<String> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<LoginResponseModel> login(String email, String password) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      return LoginResponseModel.fromJson(response.data);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<LoginResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
        },
      );

      return LoginResponseModel.fromJson(response.data);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      return response.data['data']['accessToken'];
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }
}
