import 'package:dio/dio.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Error handler for converting exceptions to failures
class ErrorHandler {
  /// Convert exception to failure
  static Failure handleException(Exception exception) {
    if (exception is ServerException) {
      return ServerFailure(exception.message, code: exception.code);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message, code: exception.code);
    } else if (exception is NetworkException) {
      return NetworkFailure(exception.message, code: exception.code);
    } else if (exception is AuthException) {
      return AuthFailure(exception.message, code: exception.code);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message, code: exception.code);
    } else if (exception is NotFoundException) {
      return NotFoundFailure(exception.message, code: exception.code);
    } else if (exception is UnauthorizedException) {
      return UnauthorizedFailure(exception.message, code: exception.code);
    } else if (exception is ForbiddenException) {
      return ForbiddenFailure(exception.message, code: exception.code);
    } else if (exception is TimeoutException) {
      return TimeoutFailure(exception.message, code: exception.code);
    } else if (exception is DioException) {
      return _handleDioException(exception);
    } else {
      return ServerFailure(exception.toString());
    }
  }

  /// Handle Dio exceptions
  static Failure _handleDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure('Connection timeout');

      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        final message = exception.response?.data['message'] ?? 'Server error';

        switch (statusCode) {
          case 400:
            return ValidationFailure(message);
          case 401:
            return const UnauthorizedFailure('Unauthorized');
          case 403:
            return const ForbiddenFailure('Forbidden');
          case 404:
            return const NotFoundFailure('Not found');
          case 500:
          case 502:
          case 503:
            return ServerFailure(message);
          default:
            return ServerFailure(message);
        }

      case DioExceptionType.cancel:
        return const ServerFailure('Request cancelled');

      case DioExceptionType.connectionError:
        return const NetworkFailure('No internet connection');

      case DioExceptionType.badCertificate:
        return const ServerFailure('Bad certificate');

      case DioExceptionType.unknown:
        return const NetworkFailure('Network error');
    }
  }

  /// Get user-friendly error message
  static String getUserMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'تحقق من اتصالك بالإنترنت';
    } else if (failure is ServerFailure) {
      return 'حدث خطأ في الخادم، حاول مرة أخرى';
    } else if (failure is AuthFailure) {
      return 'خطأ في المصادقة، قم بتسجيل الدخول مرة أخرى';
    } else if (failure is ValidationFailure) {
      return failure.message;
    } else if (failure is NotFoundFailure) {
      return 'العنصر المطلوب غير موجود';
    } else if (failure is UnauthorizedFailure) {
      return 'غير مصرح لك بالوصول';
    } else if (failure is ForbiddenFailure) {
      return 'ممنوع الوصول';
    } else if (failure is TimeoutFailure) {
      return 'انتهت مهلة الاتصال';
    } else {
      return 'حدث خطأ غير متوقع';
    }
  }
}
