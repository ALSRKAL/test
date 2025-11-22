import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hajzy/core/constants/api_endpoints.dart';

class ApiClient {
  late final Dio _dio;
  static String? _accessToken;
  final _secureStorage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token to requests
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 403 errors (Forbidden/Blocked)
          if (error.response?.statusCode == 403) {
            final data = error.response?.data;
            // Check if it's a block error
            if (data is Map &&
                (data['message']?.toString().toLowerCase().contains('block') ==
                        true ||
                    data['message']?.toString().toLowerCase().contains(
                          'suspended',
                        ) ==
                        true)) {
              onUserBanned?.call();
              return handler.next(error);
            }
          }

          // Handle 401 errors (token expired)
          if (error.response?.statusCode == 401) {
            // Don't retry FormData requests (file uploads) as FormData can't be reused
            if (error.requestOptions.data is FormData) {
              return handler.next(error);
            }

            // Try to refresh token
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request
              try {
                final response = await _retry(error.requestOptions);
                return handler.resolve(response);
              } on DioException catch (e) {
                return handler.next(e);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Add logging interceptor in debug mode
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  // Set access token
  static void setAccessToken(String token) {
    _accessToken = token;
  }

  // Clear access token
  static void clearAccessToken() {
    _accessToken = null;
  }

  // Callback for when user is banned/blocked
  static VoidCallback? onUserBanned;

  // Callback for when token expires and refresh fails
  static VoidCallback? onTokenExpired;

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Upload file
  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Refresh token
  Future<bool> _refreshToken() async {
    try {
      // Get refresh token from secure storage
      final refreshToken = await _secureStorage.read(key: 'refresh_token');

      if (refreshToken == null) {
        return false;
      }

      // Call refresh token endpoint WITHOUT interceptor to avoid infinite loop
      final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
      final response = await dio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        // Update access token in memory AND storage
        final newAccessToken = response.data['data']['accessToken'];
        _accessToken = newAccessToken;
        await _secureStorage.write(key: 'access_token', value: newAccessToken);

        // Also update refresh token if provided
        if (response.data['data']['refreshToken'] != null) {
          await _secureStorage.write(
            key: 'refresh_token',
            value: response.data['data']['refreshToken'],
          );
        }

        return true;
      }

      return false;
    } catch (e) {
      // Clear tokens on refresh failure
      _accessToken = null;
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');

      // Trigger token expired callback to force logout
      onTokenExpired?.call();

      return false;
    }
  }

  // Retry request
  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
