/// Onboarding Screen 4 — Portfolio Launch & Preview
///
/// Displays a live personalized preview of the portfolio (supporting both Dark and Light modes),
/// and calls the backend API to save the profile, domains, custom projects list, and finalize onboarding.
library;

import 'dart:convert';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  final TextEditingController _slugController =
      TextEditingController(text: 'yourname');
  final TextEditingController _domainController =
      TextEditingController(text: 'yourdomain.com');

  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 3));

  bool _isPro = false;
  bool _isPublishing = false;
  bool _isPublished = false;
  bool _didInit = false;

  Map<String, String> get _queryParams {
    if (!mounted) return {};
    return GoRouterState.of(context).uri.queryParameters;
  }

  String get _role => _queryParams['role'] ?? 'developer';
  String get _fullName => _queryParams['full_name'] ?? 'Your Name';
  String get _title => _queryParams['title'] ?? 'Software Engineer';
  String get _bio => _queryParams['bio'] ?? 'Hello, welcome to my portfolio!';
  String get _skills => _queryParams['skills'] ?? '';
  String get _avatarUrl => _queryParams['avatar_url'] ?? '';
  String get _accentColorHex => _queryParams['accent_color'] ?? '#6366F1';
  String get _layoutTemplate => _queryParams['layout_template'] ?? 'minimal_dark';
  String get _plan => _queryParams['plan'] ?? 'free';
  String get _projectsParam => _queryParams['projects'] ?? '[]';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _isPro = _plan == 'pro';
      final cleanedName = _fullName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (cleanedName.isNotEmpty) {
        _slugController.text = cleanedName;
        _domainController.text = '$cleanedName.com';
      }
    }
  }

  Color get _themeColor {
    return Color(int.parse(_accentColorHex.replaceFirst('#', '0xFF')));
  }

  List<dynamic> get _parsedProjects {
    try {
      return jsonDecode(_projectsParam) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  Future<void> _handlePublish() async {
    final slug = _slugController.text.trim();
    final customDomain = _domainController.text.trim();

    if (_isPro && customDomain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid custom domain'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_isPro && slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a custom slug'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);
    HapticFeedback.heavyImpact();

    try {
      final dio = sl<Dio>();

      final List<String> skillsList = _skills
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // 1. Setup domain
      if (_isPro) {
        await dio.post(
          '/portfolios/me/domain',
          data: {'hostname': customDomain},
        );
      } else {
        try {
          await dio.delete('/portfolios/me/domain');
        } catch (_) {}
      }

      // 2. Onboarding complete
      final response = await dio.post(
        '/onboarding/complete',
        data: {
          'role': _role,
          'professional_title': _title,
          'full_name': _fullName,
          'bio': _bio,
          'avatar_url': _avatarUrl,
          'accent_color': _accentColorHex,
          'layout_template': _layoutTemplate,
          'skills': skillsList,
          'projects': _parsedProjects,
        },
      );

      if (response.data['success'] == true) {
        // Update slug settings
        if (!_isPro) {
          await dio.put(
            '/portfolios/me/settings',
            data: {
              'slug': slug,
            },
          );
        }

        if (mounted) {
          setState(() {
            _isPublishing = false;
            _isPublished = true;
          });

          _confettiController.play();
          HapticFeedback.heavyImpact();

          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            context.go(RoutePaths.editor);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish site: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _slugController.dispose();
    _domainController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTemplate = _layoutTemplate != 'minimal_light';

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Background Glows
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, -0.6),
                  radius: 1.2,
                  colors: [
                    _themeColor.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _buildHeader(),
                  const SizedBox(height: 16),

                  // Phone preview
                  Expanded(child: _buildMockPreview(isDarkTemplate)),
                  const SizedBox(height: 16),

                  // Selected plan tag
                  _buildPlanTag(),
                  const SizedBox(height: 12),

                  // URL input field
                  _buildUrlInputField(),
                  const SizedBox(height: 16),

                  // Publish CTA Button
                  _buildPublishButton(),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),

          // Confetti
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 40,
            gravity: 0.25,
            colors: [
              _themeColor,
              AppColors.accent,
              AppColors.success,
              AppColors.warning,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          _isPublished ? 'You\'re live! 🎉' : 'Verify & launch site',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          _isPublished
              ? 'Your bento-style portfolio has been auto-built successfully.'
              : 'Review your site mock layout preview before launching.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlanTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _themeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _themeColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isPro ? Icons.star_rounded : Icons.insert_link_rounded,
            size: 16,
            color: _themeColor,
          ),
          const SizedBox(width: 6),
          Text(
            _isPro ? 'Pro Plan (\$8/mo) Selected' : 'Free Plan Selected',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(
            _isPro ? Icons.language_rounded : Icons.link_rounded,
            color: _themeColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          if (!_isPro)
            const Text(
              'tspace.me/',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          Expanded(
            child: TextField(
              controller: _isPro ? _domainController : _slugController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                color: _themeColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [_themeColor, _themeColor.withValues(alpha: 0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: _themeColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isPublishing || _isPublished ? null : _handlePublish,
          icon: _isPublishing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  _isPublished ? Icons.check_circle : Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 20,
                ),
          label: Text(
            _isPublishing
                ? 'Building & Launching...'
                : _isPublished
                    ? 'Published!'
                    : 'Publish My Site',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockPreview(bool isDark) {
    final previewProjects = _parsedProjects;
    final primaryProjTitle = previewProjects.isNotEmpty
        ? (previewProjects[0]['title'] ?? 'My Project')
        : 'My Project';

    // Set mockup colors based on theme settings choice
    final bgColor = isDark ? AppColors.canvasDark : const Color(0xFFF9FAFB);
    final cardBgColor = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final cardBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final mainTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? AppColors.textSecondary : const Color(0xFF4B5563);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Profile block
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorderColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _themeColor.withValues(alpha: 0.15),
                  backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                  child: _avatarUrl.isEmpty
                      ? Icon(Icons.person, color: _themeColor, size: 22)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fullName,
                        style: TextStyle(
                          color: mainTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _title,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Bento blocks preview
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _skeletonBlock(
                        flex: 3,
                        color: _themeColor,
                        icon: Icons.folder_open_rounded,
                        title: primaryProjTitle,
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _skeletonBlock(
                        flex: 2,
                        color: AppColors.success,
                        icon: Icons.trending_up_rounded,
                        title: 'Stats counter',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    children: [
                      _skeletonBlock(
                        flex: 2,
                        color: AppColors.warning,
                        icon: Icons.link_rounded,
                        title: 'Connect Link',
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _skeletonBlock(
                        flex: 3,
                        color: _themeColor,
                        icon: Icons.auto_awesome_rounded,
                        title: 'About Block',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBlock({
    required int flex,
    required Color color,
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    final blockBgColor = isDark
        ? color.withValues(alpha: 0.05)
        : color.withValues(alpha: 0.08);
    final textStyleColor = isDark
        ? Colors.white.withValues(alpha: 0.8)
        : const Color(0xFF1F2937);

    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: blockBgColor,
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: textStyleColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
