/// Auth Data Layer — Repository Implementation
///
/// Bridges the domain [AuthRepository] contract with the concrete
/// [AuthRemoteDataSource] and [FlutterSecureStorage] for token persistence.
library;

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/domain/entities.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage secureStorage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'cached_user';

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<Result<UserSession>> loginWithGithub(String code) async {
    try {
      final session = await remoteDataSource.loginWithGithub(code);

      // Persist tokens and user data securely.
      await Future.wait([
        secureStorage.write(key: _accessTokenKey, value: session.accessToken),
        secureStorage.write(key: _refreshTokenKey, value: session.refreshToken),
        secureStorage.write(
          key: _userKey,
          value: jsonEncode({
            'id': session.user.id,
            'email': session.user.email,
            'full_name': session.user.fullName,
            'avatar_url': session.user.avatarUrl,
            'professional_title': session.user.professionalTitle,
            'has_completed_onboarding': session.user.hasCompletedOnboarding,
          }),
        ),
      ]);

      return Result.success(session);
    } on ServerException catch (e) {
      return Result.failure(
        ServerFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'An unexpected error occurred: $e'),
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final token = await secureStorage.read(key: _accessTokenKey);
      if (token != null) {
        await remoteDataSource.logout(token);
      }
      await secureStorage.deleteAll();
      return const Result.success(null);
    } on ServerException catch (e) {
      // Even if the server call fails, clear local session.
      await secureStorage.deleteAll();
      return Result.failure(
        ServerFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      await secureStorage.deleteAll();
      return const Result.success(null);
    }
  }

  @override
  Future<Result<UserSession?>> getCachedSession() async {
    try {
      final token = await secureStorage.read(key: _accessTokenKey);
      final refreshToken = await secureStorage.read(key: _refreshTokenKey);
      final userJson = await secureStorage.read(key: _userKey);

      if (token == null || userJson == null) {
        return const Result.success(null);
      }

      final userData = jsonDecode(userJson) as Map<String, dynamic>;

      return Result.success(
        UserSession(
          accessToken: token,
          refreshToken: refreshToken ?? '',
          user: User(
            id: userData['id'] as String,
            email: userData['email'] as String,
            fullName: userData['full_name'] as String,
            avatarUrl: userData['avatar_url'] as String?,
            professionalTitle: userData['professional_title'] as String?,
            hasCompletedOnboarding:
                userData['has_completed_onboarding'] as bool? ?? false,
          ),
        ),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to read cached session: $e'),
      );
    }
  }

  @override
  Future<Result<UserSession>> loginWithEmail(String email, String password) async {
    try {
      final session = await remoteDataSource.loginWithEmail(email, password);

      // Persist tokens securely.
      await Future.wait([
        secureStorage.write(key: _accessTokenKey, value: session.accessToken),
        secureStorage.write(key: _refreshTokenKey, value: session.refreshToken),
        secureStorage.write(
          key: _userKey,
          value: jsonEncode({
            'id': session.user.id,
            'email': session.user.email,
            'full_name': session.user.fullName,
            'avatar_url': session.user.avatarUrl,
            'professional_title': session.user.professionalTitle,
            'has_completed_onboarding': session.user.hasCompletedOnboarding,
          }),
        ),
      ]);

      return Result.success(session);
    } on ServerException catch (e) {
      return Result.failure(
        ServerFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'An unexpected error occurred: $e'),
      );
    }
  }
}
