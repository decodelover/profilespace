/// OAuth Callback Screen — Deep Link Redirection Handler
///
/// Receives the authorization code from the deep link redirect,
/// triggers the AuthBloc token exchange event, and listens to
/// the auth state transitions to route the user appropriately.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class OAuthCallbackScreen extends StatefulWidget {
  final String? code;

  const OAuthCallbackScreen({super.key, this.code});

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _triggerAuthExchange();
  }

  void _triggerAuthExchange() {
    if (widget.code != null && widget.code!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthBloc>().add(AuthGithubLoginRequested(widget.code!));
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid authorization code received.'),
            backgroundColor: AppColors.error,
          ),
        );
        context.go(RoutePaths.login);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.session.user.hasCompletedOnboarding) {
            context.go(RoutePaths.editor);
          } else {
            context.go(RoutePaths.onboardingRole);
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
          context.go(RoutePaths.login);
        } else if (state is AuthUnauthenticated) {
          context.go(RoutePaths.login);
        }
      },
      child: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.accent),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Authenticating with GitHub...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Completing secure token exchange.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
