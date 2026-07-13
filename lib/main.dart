/// Tspace Portfolio — Application Entry Point
///
/// Initializes dependency injection, secure storage, and the
/// root [TspaceApp] widget with dark-first theming and GoRouter navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for optimal bento-grid editing.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Set system UI overlay style for dark immersive chrome.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B0F19),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize service locator (dependency injection).
  await initServiceLocator();

  runApp(const TspaceApp());
}

/// Root application widget.
///
/// Provides the [AuthBloc] at the top of the widget tree so that
/// authentication state is available globally across all routes.
class TspaceApp extends StatelessWidget {
  const TspaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: MaterialApp.router(
        title: 'Tspace Portfolio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
