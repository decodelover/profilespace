/// Auth Domain — Repository Contract
///
/// Defines the authentication operations that the domain layer requires.
/// The data layer provides the concrete implementation.
library;

import '../../../../core/errors/failures.dart';
import '../../../../core/domain/entities.dart';

/// Contract for all authentication operations.
abstract class AuthRepository {
  /// Exchanges a GitHub OAuth [code] for a [UserSession] containing
  /// the access token, refresh token, and user profile.
  Future<Result<UserSession>> loginWithGithub(String code);

  /// Revokes the current session and clears secure storage.
  Future<Result<void>> logout();

  /// Attempts to load a cached session from secure storage.
  /// Returns `null` inside the Result if no session exists.
  Future<Result<UserSession?>> getCachedSession();

  /// Logs in or registers a user using email and password.
  Future<Result<UserSession>> loginWithEmail(String email, String password);
}
