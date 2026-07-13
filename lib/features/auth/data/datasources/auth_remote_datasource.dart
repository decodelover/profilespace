/// Auth Data Layer — Remote Data Source
///
/// Handles all HTTP communication with the Laravel API for authentication.
/// Parses raw JSON into domain entities and throws [ServerException] on errors.
library;

import 'package:dio/dio.dart';

import '../../../../core/domain/entities.dart';

/// Contract for the auth remote data source.
abstract class AuthRemoteDataSource {
  Future<UserSession> loginWithGithub(String code);
  Future<UserSession> loginWithEmail(String email, String password);
  Future<void> logout(String token);
}

/// Exception thrown when the API returns a non-2xx response.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});
}

/// Concrete implementation using [Dio] for HTTP requests.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  const AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserSession> loginWithGithub(String code) async {
    try {
      final isGoogle = code.contains('google');
      final path = isGoogle ? '/auth/google/callback' : '/auth/github/callback';

      final response = await dio.post(path, data: {'code': code});

      final data = response.data['data'] as Map<String, dynamic>;

      return UserSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        user: User(
          id: data['user']['id'].toString(),
          email: data['user']['email'] as String,
          fullName: data['user']['full_name'] as String,
          avatarUrl: data['user']['avatar_url'] as String?,
          professionalTitle: data['user']['professional_title'] as String?,
          hasCompletedOnboarding:
              data['user']['has_completed_onboarding'] as bool? ?? false,
        ),
      );
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message']?.toString() ??
            'Authentication failed. Please try again.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserSession> loginWithEmail(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/email-login',
        data: {'email': email, 'password': password},
      );

      final data = response.data['data'] as Map<String, dynamic>;

      return UserSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        user: User(
          id: data['user']['id'].toString(),
          email: data['user']['email'] as String,
          fullName: data['user']['full_name'] as String,
          avatarUrl: data['user']['avatar_url'] as String?,
          professionalTitle: data['user']['professional_title'] as String?,
          hasCompletedOnboarding:
              data['user']['has_completed_onboarding'] as bool? ?? false,
        ),
      );
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message']?.toString() ??
            'Authentication failed. Please try again.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> logout(String token) async {
    try {
      await dio.post(
        '/auth/logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ?? 'Logout failed.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
