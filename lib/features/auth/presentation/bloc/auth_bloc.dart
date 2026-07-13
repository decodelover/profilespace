/// Auth BLoC — State Management for Authentication
///
/// Manages the complete auth lifecycle: checking cached sessions on startup,
/// handling GitHub OAuth callbacks, and processing logouts. Emits typed
/// states that drive navigation decisions in the UI layer.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities.dart';
import '../../domain/usecases/login_with_github.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/get_cached_session.dart';

// ═══════════════════════════════════════════════════════════════════════
// EVENTS
// ═══════════════════════════════════════════════════════════════════════

/// Base event for the authentication BLoC.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired on app startup to check for a cached session in secure storage.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Fired when the GitHub OAuth callback returns an authorization code.
class AuthGithubLoginRequested extends AuthEvent {
  final String code;

  const AuthGithubLoginRequested(this.code);

  @override
  List<Object?> get props => [code];
}

/// Fired when the user explicitly requests logout.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Fired when the user attempts email/password sign-in.
class AuthEmailLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthEmailLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

// ═══════════════════════════════════════════════════════════════════════
// STATES
// ═══════════════════════════════════════════════════════════════════════

/// Base state for the authentication BLoC.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any auth check has been performed.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Auth check or login is in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated. Contains the active [UserSession].
class AuthAuthenticated extends AuthState {
  final UserSession session;

  const AuthAuthenticated(this.session);

  @override
  List<Object?> get props => [session];
}

/// User is not authenticated (no cached session or after logout).
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth operation failed. Contains a human-readable error message.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// ═══════════════════════════════════════════════════════════════════════
// BLOC
// ═══════════════════════════════════════════════════════════════════════

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginWithGithub _loginWithGithub;
  final Logout _logout;
  final GetCachedSession _getCachedSession;
  final LoginWithEmail _loginWithEmail;

  AuthBloc({
    required LoginWithGithub loginWithGithub,
    required Logout logout,
    required GetCachedSession getCachedSession,
    required LoginWithEmail loginWithEmail,
  }) : _loginWithGithub = loginWithGithub,
       _logout = logout,
       _getCachedSession = getCachedSession,
       _loginWithEmail = loginWithEmail,
       super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthGithubLoginRequested>(_onGithubLogin);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthEmailLoginRequested>(_onEmailLogin);
  }

  /// Checks secure storage for a cached session on app startup.
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _getCachedSession();

    result.fold((failure) => emit(const AuthUnauthenticated()), (session) {
      if (session != null) {
        emit(AuthAuthenticated(session));
      } else {
        emit(const AuthUnauthenticated());
      }
    });
  }

  /// Exchanges a GitHub OAuth code for a full session.
  Future<void> _onGithubLogin(
    AuthGithubLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _loginWithGithub(event.code);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (session) => emit(AuthAuthenticated(session)),
    );
  }

  /// Logs the user out and clears all cached credentials.
  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _logout();
    emit(const AuthUnauthenticated());
  }

  /// Logs in or registers using email and password credentials.
  Future<void> _onEmailLogin(
    AuthEmailLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _loginWithEmail(event.email, event.password);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (session) => emit(AuthAuthenticated(session)),
    );
  }
}
