/// Tspace Error Handling — Domain Failures & Network Exceptions
///
/// Provides a unified [Failure] hierarchy and a [Result] type alias
/// to enforce explicit error handling across all use cases.
library;

import 'package:equatable/equatable.dart';

/// Base failure class. All domain-level errors extend this.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Failure originating from API / network layer.
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

/// Failure originating from local cache or secure storage.
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Failure due to invalid user input or business rule violation.
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

/// Failure when the user's session has expired or is unauthenticated.
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication required. Please sign in again.',
    super.statusCode = 401,
  });
}

/// Failure due to network connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
  });
}

/// A functional result type: either a [Failure] or a success value [T].
///
/// Usage:
/// ```dart
/// final Result<Portfolio> result = await getPortfolio();
/// result.fold(
///   (failure) => showError(failure.message),
///   (portfolio) => emit(Loaded(portfolio)),
/// );
/// ```
class Result<T> {
  final Failure? _failure;
  final T? _data;

  const Result.success(T data) : _data = data, _failure = null;

  const Result.failure(Failure failure) : _failure = failure, _data = null;

  bool get isSuccess => _failure == null;
  bool get isFailure => _failure != null;

  /// Fold over success and failure cases.
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T data) onSuccess,
  ) {
    if (_failure != null) {
      return onFailure(_failure);
    }
    return onSuccess(_data as T);
  }
}
