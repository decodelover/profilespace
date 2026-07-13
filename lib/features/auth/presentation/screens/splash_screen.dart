/// Splash Screen — Animated App Launch & Session Check
///
/// Displays the Tspace logo with a pulsing glow animation while
/// the [AuthBloc] checks for a cached session in secure storage.
/// Automatically navigates to the login screen or the dashboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulsing glow animation for the logo.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Trigger session check after a brief visual delay.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthCheckRequested());
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
        } else if (state is AuthUnauthenticated || state is AuthError) {
          context.go(RoutePaths.login);
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B0F19), Color(0xFF1a1040), Color(0xFF0B0F19)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo with pulsing glow.
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(
                            alpha: _pulseAnimation.value * 0.3,
                          ),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.space_dashboard_rounded,
                      size: 48,
                      color: AppColors.accent,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'TSPACE',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  letterSpacing: 6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Build. Showcase. Get Hired.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
