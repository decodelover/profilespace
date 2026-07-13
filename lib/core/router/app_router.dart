/// Tspace App Router — GoRouter Configuration
///
/// Defines all application routes with guard redirects for authentication
/// and onboarding completion. Uses [ShellRoute] for the bottom navigation
/// shell on the main dashboard screens.
library;

import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/oauth_callback_screen.dart';
import '../../features/onboarding/presentation/screens/role_selector_screen.dart';
import '../../features/onboarding/presentation/screens/details_form_screen.dart';
import '../../features/onboarding/presentation/screens/integration_screen.dart';
import '../../features/onboarding/presentation/screens/launch_screen.dart';
import '../../features/onboarding/presentation/screens/plan_selection_screen.dart';
import '../../features/onboarding/presentation/screens/overview_template_screen.dart';
import '../../features/onboarding/presentation/screens/publish_generation_screen.dart';
import '../../features/onboarding/presentation/screens/live_preview_screen.dart';
import '../../features/portfolio_editor/presentation/screens/editor_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/inbox/presentation/screens/inbox_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../widgets/main_shell.dart';

/// Centralised route path constants to avoid magic strings.
abstract final class RoutePaths {
  static const String welcome = '/';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String authCallback = '/auth/callback';
  static const String onboardingRole = '/onboarding/role';
  static const String onboardingDetails = '/onboarding/details';
  static const String onboardingIntegration = '/onboarding/integration';
  static const String onboardingLaunch = '/onboarding/launch';
  static const String onboardingPlan = '/onboarding/plan';
  static const String onboardingTemplate = '/onboarding/template';
  static const String onboardingPublish = '/onboarding/publish';
  static const String onboardingPreview = '/onboarding/preview';
  static const String editor = '/editor';
  static const String analytics = '/analytics';
  static const String inbox = '/inbox';
  static const String settings = '/settings';
}

/// Application router with declarative route definitions.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.welcome,
    debugLogDiagnostics: true,
    routes: [
      // ─── Pre-Auth Routes ─────────────────────────────────────────
      GoRoute(
        path: RoutePaths.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(path: RoutePaths.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: RoutePaths.authCallback,
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return OAuthCallbackScreen(code: code);
        },
      ),

      // ─── Onboarding Routes ───────────────────────────────────────
      GoRoute(
        path: RoutePaths.onboardingRole,
        builder: (_, __) => const RoleSelectorScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingDetails,
        builder: (_, __) => const DetailsFormScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingIntegration,
        builder: (_, __) => const IntegrationScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingLaunch,
        builder: (_, __) => const LaunchScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingPlan,
        builder: (_, __) => const PlanSelectionScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingTemplate,
        builder: (_, __) => const OverviewTemplateScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingPublish,
        builder: (_, __) => const PublishGenerationScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingPreview,
        builder: (_, __) => const LivePreviewScreen(),
      ),

      // ─── Main App Shell (Bottom Navigation) ──────────────────────
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.editor,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: EditorScreen()),
          ),
          GoRoute(
            path: RoutePaths.analytics,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: AnalyticsScreen()),
          ),
          GoRoute(
            path: RoutePaths.inbox,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: InboxScreen()),
          ),
          GoRoute(
            path: RoutePaths.settings,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
}
