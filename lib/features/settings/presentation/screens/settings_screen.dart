/// Settings Screen — Account, Plan, Custom Domain & Theme Management
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(RoutePaths.login);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ─── Profile Section ──────────────────────────────────
            _SectionHeader(title: 'Account'),
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.palette_outlined,
              label: 'Theme & Customization',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.language_rounded,
              label: 'Custom Domain',
              subtitle: 'Connect your own domain',
              onTap: () {},
            ),

            const SizedBox(height: AppSpacing.lg),

            // ─── Plan Section ─────────────────────────────────────
            _SectionHeader(title: 'Subscription'),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: GlassDecoration.cardSelected(),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.star_rounded,
                        color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Free Plan',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('Upgrade to Pro for custom domains & analytics.',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Upgrade to Pro — \$8/mo'),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ─── Danger Zone ──────────────────────────────────────
            _SectionHeader(title: 'Account Actions'),
            _SettingsTile(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              isDestructive: true,
              onTap: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
            ),
            _SettingsTile(
              icon: Icons.delete_forever_rounded,
              label: 'Delete Account',
              subtitle: 'Permanently delete all data',
              isDestructive: true,
              onTap: () {
                // TODO: Show confirmation dialog.
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: GlassDecoration.card(),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: color),
                    ),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
