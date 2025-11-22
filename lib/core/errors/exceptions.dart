/// Base exception class
class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Server exception
class ServerException extends AppException {
  ServerException(super.message, {super.code});
}

/// Cache exception
class CacheException extends AppException {
  CacheException(super.message, {super.code});
}

/// Network exception
class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}

/// Authentication exception
class AuthException extends AppException {
  AuthException(super.message, {super.code});
}

/// Validation exception
class ValidationException extends AppException {
  ValidationException(super.message, {super.code});
}

/// Not found exception
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.code});
}

/// Unauthorized exception
class UnauthorizedException extends AppException {
  UnauthorizedException(super.message, {super.code});
}

/// Forbidden exception
class ForbiddenException extends AppException {
  ForbiddenException(super.message, {super.code});
}

/// Timeout exception
class TimeoutException extends AppException {
  TimeoutException(super.message, {super.code});
}

/// Photographer profile not found exception
class PhotographerProfileNotFoundException extends AppException {
  PhotographerProfileNotFoundException(super.message, {super.code});
}
