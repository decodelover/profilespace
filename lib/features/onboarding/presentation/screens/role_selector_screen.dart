/// Onboarding Screen 2 — Role Selector
///
/// Implements "The Core Identity" screen from the UX specification.
/// Displays a vertical deck of oversized profession cards with haptic
/// feedback and an Electric Indigo glow on selection.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/entities.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen> {
  ProfessionalRole? _selectedRole;

  void _onRoleTap(ProfessionalRole role) {
    HapticFeedback.mediumImpact();
    setState(() => _selectedRole = role);
  }

  void _onContinue() {
    if (_selectedRole == null) return;
    // Navigate to details form screen first
    context.go(
      '${RoutePaths.onboardingDetails}?role=${_selectedRole!.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // Header
              Text(
                'What do you do?',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We\'ll customize your portfolio layout and suggest\nthe right integrations for your work.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Role cards
              Expanded(
                child: ListView.separated(
                  itemCount: ProfessionalRole.values.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final role = ProfessionalRole.values[index];
                    final isSelected = _selectedRole == role;

                    return GestureDetector(
                      onTap: () => _onRoleTap(role),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: isSelected
                            ? GlassDecoration.cardSelected()
                            : GlassDecoration.card(),
                        child: Row(
                          children: [
                            // Emoji avatar
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : AppColors.canvasDark,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                role.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),

                            // Label & subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: isSelected
                                              ? AppColors.accent
                                              : AppColors.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    role.subtitle,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),

                            // Selection indicator
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.textMuted,
                                  width: isSelected ? 2 : 1.5,
                                ),
                                color: isSelected
                                    ? AppColors.accent
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Continue button
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedRole != null ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor:
                        AppColors.accent.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
