/// Tspace Service Locator — Dependency Injection Container
///
/// Uses [get_it] to register all repositories, data sources, and BLoCs.
/// Called once from [main] before the widget tree mounts.
library;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../config/environment.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_with_github.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/get_cached_session.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/portfolio_editor/data/datasources/portfolio_remote_datasource.dart';
import '../../features/portfolio_editor/domain/repositories/portfolio_repository.dart';
import '../../features/portfolio_editor/domain/usecases/get_portfolio.dart';
import '../../features/portfolio_editor/domain/usecases/update_block_layout.dart';
import '../../features/portfolio_editor/domain/usecases/add_block.dart';
import '../../features/portfolio_editor/domain/usecases/delete_block.dart';
import '../../features/portfolio_editor/domain/usecases/upload_image.dart';
import '../../features/portfolio_editor/presentation/bloc/portfolio_bloc.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../features/analytics/data/repositories/analytics_repository_impl.dart';
import '../../features/analytics/domain/usecases/get_analytics.dart';
import '../../features/analytics/presentation/bloc/analytics_bloc.dart';
import '../../features/inbox/domain/repositories/inbox_repository.dart';
import '../../features/inbox/data/repositories/inbox_repository_impl.dart';
import '../../features/inbox/domain/usecases/get_messages.dart';
import '../../features/inbox/presentation/bloc/inbox_bloc.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Registers all dependencies in a bottom-up order:
/// External → Data Sources → Repositories → Use Cases → BLoCs.
Future<void> initServiceLocator() async {
  // ─── External ───────────────────────────────────────────────────────
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Environment.apiUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );
    // Attach auth interceptor to inject Bearer token from secure storage.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final storage = sl<FlutterSecureStorage>();
          final token = await storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    return dio;
  });

  // ─── Data Sources ───────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<PortfolioRemoteDataSource>(
    () => PortfolioRemoteDataSourceImpl(dio: sl()),
  );

  // ─── Repositories ──────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), secureStorage: sl()),
  );

  sl.registerLazySingleton<PortfolioRepository>(
    () => PortfolioRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(dio: sl()),
  );

  sl.registerLazySingleton<InboxRepository>(
    () => InboxRepositoryImpl(dio: sl()),
  );

  // ─── Use Cases ─────────────────────────────────────────────────────
  sl.registerLazySingleton(() => LoginWithGithub(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => GetCachedSession(sl()));
  sl.registerLazySingleton(() => LoginWithEmail(sl()));
  sl.registerLazySingleton(() => GetPortfolio(sl()));
  sl.registerLazySingleton(() => UpdateBlockLayout(sl()));
  sl.registerLazySingleton(() => AddBlock(sl()));
  sl.registerLazySingleton(() => DeleteBlock(sl()));
  sl.registerLazySingleton(() => UploadImage(sl()));
  sl.registerLazySingleton(() => GetAnalytics(sl()));
  sl.registerLazySingleton(() => GetMessages(sl()));

  // ─── BLoCs ─────────────────────────────────────────────────────────
  sl.registerFactory(
    () => AuthBloc(
      loginWithGithub: sl(),
      logout: sl(),
      getCachedSession: sl(),
      loginWithEmail: sl(),
    ),
  );

  sl.registerFactory(
    () => PortfolioBloc(
      getPortfolio: sl(),
      updateBlockLayout: sl(),
      addBlock: sl(),
      deleteBlock: sl(),
      uploadImage: sl(),
    ),
  );

  sl.registerFactory(() => AnalyticsBloc(getAnalytics: sl()));

  sl.registerFactory(() => InboxBloc(getMessages: sl()));
}
