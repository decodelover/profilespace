/// Auth Use Cases — LoginWithGithub, Logout, GetCachedSession
///
/// Each use case encapsulates a single business action following
/// the Single Responsibility Principle. They are injected into the
/// [AuthBloc] via the service locator.
library;

import '../../../../core/errors/failures.dart';
import '../../../../core/domain/entities.dart';
import '../repositories/auth_repository.dart';

// ─── Login with GitHub ────────────────────────────────────────────────

class LoginWithGithub {
  final AuthRepository _repository;

  const LoginWithGithub(this._repository);

  /// Exchanges an OAuth authorization [code] for a full user session.
  Future<Result<UserSession>> call(String code) {
    return _repository.loginWithGithub(code);
  }
}

// ─── Logout ───────────────────────────────────────────────────────────

class Logout {
  final AuthRepository _repository;

  const Logout(this._repository);

  /// Clears the active session and revokes tokens.
  Future<Result<void>> call() {
    return _repository.logout();
  }
}

// ─── Get Cached Session ───────────────────────────────────────────────

class GetCachedSession {
  final AuthRepository _repository;

  const GetCachedSession(this._repository);

  /// Retrieves a locally cached session, or `null` if none exists.
  Future<Result<UserSession?>> call() {
    return _repository.getCachedSession();
  }
}

// ─── Login with Email & Password ──────────────────────────────────────

class LoginWithEmail {
  final AuthRepository _repository;

  const LoginWithEmail(this._repository);

  /// Authenticates using email and password.
  Future<Result<UserSession>> call(String email, String password) {
    return _repository.loginWithEmail(email, password);
  }
}
