/// Onboarding Screen 3 — Quick Integration
///
/// Implements "Auto-Discovery" from the UX specification.
/// Contextually renders integration options based on the selected
/// professional role (e.g., GitHub repo picker for developers,
/// RSS URL input for writers, YouTube username for creators).
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/domain/entities.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class IntegrationScreen extends StatefulWidget {
  const IntegrationScreen({super.key});

  @override
  State<IntegrationScreen> createState() => _IntegrationScreenState();
}

class _IntegrationScreenState extends State<IntegrationScreen> {
  final TextEditingController _urlController = TextEditingController();
  final Set<int> _selectedRepos = {};
  List<Map<String, dynamic>> _repos = [];
  bool _isLoading = false;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      if (_role == ProfessionalRole.developer) {
        _fetchRepos();
      }
    }
  }

  Future<void> _fetchRepos() async {
    setState(() => _isLoading = true);
    try {
      final dio = sl<Dio>();
      final response = await dio.get('/github/repos');
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        setState(() {
          _repos = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load GitHub repositories: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  ProfessionalRole get _role {
    final roleParam =
        GoRouterState.of(context).uri.queryParameters['role'] ?? 'developer';
    return ProfessionalRole.values.firstWhere(
      (r) => r.name == roleParam,
      orElse: () => ProfessionalRole.developer,
    );
  }

  Future<void> _onContinue() async {
    final uri = GoRouterState.of(context).uri;
    final queryStr = uri.query;
    final nextPath = '${RoutePaths.onboardingLaunch}?$queryStr';

    if (_role == ProfessionalRole.developer && _selectedRepos.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final selectedList = _selectedRepos.map((index) => _repos[index]).toList();
        final dio = sl<Dio>();
        final response = await dio.post(
          '/github/import',
          data: {'repos': selectedList},
        );
        if (response.data['success'] == true && mounted) {
          context.go(nextPath);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to import repositories: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      context.go(nextPath);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
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
                _headerTitle,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _headerSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Dynamic content
              Expanded(
                child: _isLoading 
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      )
                    : _buildRoleContent(),
              ),

              // Continue CTA
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _onContinue,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                  label: const Text('Auto-Build My Grid'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _headerTitle {
    return switch (_role) {
      ProfessionalRole.developer => 'Select your projects',
      ProfessionalRole.designer => 'Connect your design tools',
      ProfessionalRole.writer => 'Link your publications',
      ProfessionalRole.contentCreator => 'Connect your channels',
      ProfessionalRole.promptEngineer => 'Showcase your prompts',
    };
  }

  String get _headerSubtitle {
    return switch (_role) {
      ProfessionalRole.developer =>
        'We found these repositories from your GitHub account.\nWhich projects should we feature?',
      ProfessionalRole.designer =>
        'Enter your Figma or Behance profile URL to import your work.',
      ProfessionalRole.writer =>
        'Enter your Substack or Medium URL so we can auto-import articles.',
      ProfessionalRole.contentCreator =>
        'Enter your YouTube channel URL to embed your latest videos.',
      ProfessionalRole.promptEngineer =>
        'Add a link to your prompt collections or GitHub Gists.',
    };
  }

  Widget _buildRoleContent() {
    return switch (_role) {
      ProfessionalRole.developer => _buildRepoPicker(),
      _ => _buildUrlInput(),
    };
  }

  /// GitHub repository toggle list for developers.
  Widget _buildRepoPicker() {
    if (_repos.isEmpty) {
      return const Center(
        child: Text(
          'No repositories found on your account.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      itemCount: _repos.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final repo = _repos[index];
        final isSelected = _selectedRepos.contains(index);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedRepos.remove(index);
              } else {
                _selectedRepos.add(index);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration:
                isSelected ? GlassDecoration.cardSelected() : GlassDecoration.card(),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.textMuted,
                      width: 1.5,
                    ),
                    color: isSelected ? AppColors.accent : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),

                // Repo info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repo['name'] as String,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${repo['stars']}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              (repo['language'] ?? 'Code') as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 11,
                                    color: AppColors.accent,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// URL input for non-developer tracks.
  Widget _buildUrlInput() {
    final placeholder = switch (_role) {
      ProfessionalRole.designer => 'https://figma.com/@yourname',
      ProfessionalRole.writer => 'https://yourname.substack.com',
      ProfessionalRole.contentCreator => 'https://youtube.com/@yourname',
      ProfessionalRole.promptEngineer => 'https://gist.github.com/yourname',
      _ => 'https://...',
    };

    return Column(
      children: [
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon:
                const Icon(Icons.link_rounded, color: AppColors.textMuted),
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: GlassDecoration.card(),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'We\'ll automatically sync your latest content every week.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
