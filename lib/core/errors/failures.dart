import 'package:equatable/equatable.dart';

/// Base failure class
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Not found failure
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// Unauthorized failure
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message, {super.code});
}

/// Forbidden failure
class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message, {super.code});
}

/// Timeout failure
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message, {super.code});
}
