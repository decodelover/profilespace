/// Onboarding Screen 6 — Site Generation & Deployment Progress
///
/// Runs the backend onboarding complete API call. Displays animated progress steps
/// with a warning banner. Disables device back gestures using PopScope.
library;

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class PublishGenerationScreen extends StatefulWidget {
  const PublishGenerationScreen({super.key});

  @override
  State<PublishGenerationScreen> createState() =>
      _PublishGenerationScreenState();
}

class _PublishGenerationScreenState extends State<PublishGenerationScreen> {
  int _currentStepIndex = 0;
  double _progressValue = 0.05;
  String _errorMessage = '';
  bool _isDone = false;

  final List<String> _statusSteps = [
    'Setting up your site...',
    'Applying template theme...',
    'Deploying code to edge nodes...',
    'Finalizing domain configuration...',
  ];

  Timer? _stepTimer;
  bool _startedApi = false;

  Map<String, String> get _queryParams {
    if (!mounted) return {};
    return GoRouterState.of(context).uri.queryParameters;
  }

  String get _role => _queryParams['role'] ?? 'developer';
  String get _fullName => _queryParams['full_name'] ?? 'User';
  String get _title => _queryParams['title'] ?? 'Tech Professional';
  String get _bio => _queryParams['bio'] ?? '';
  String get _skills => _queryParams['skills'] ?? '';
  String get _avatarUrl => _queryParams['avatar_url'] ?? '';
  String get _accentColorHex => _queryParams['accent_color'] ?? '#6366F1';
  String get _layoutTemplate =>
      _queryParams['layout_template'] ?? 'minimal_dark';
  String get _plan => _queryParams['plan'] ?? 'free';
  String get _slug => _queryParams['slug'] ?? 'yourname';
  String get _customDomain => _queryParams['custom_domain'] ?? '';
  String get _projectsParam => _queryParams['projects'] ?? '[]';

  List<dynamic> get _parsedProjects {
    try {
      return jsonDecode(_projectsParam) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _startGenerationTimeline();
  }

  void _startGenerationTimeline() {
    // 1. Advance steps visually
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) return;
      if (_currentStepIndex < _statusSteps.length - 1) {
        setState(() {
          _currentStepIndex++;
          _progressValue = (_currentStepIndex + 1) / _statusSteps.length;
        });
      } else {
        timer.cancel();
      }
    });

    // 2. Trigger API execution
    if (!_startedApi) {
      _startedApi = true;
      _executePublishApi();
    }
  }

  Future<void> _executePublishApi() async {
    try {
      final dio = sl<Dio>();

      final List<String> skillsList = _skills
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Step A: Point custom domain (if Pro/Premium is active)
      final isProOrPremium = _plan == 'pro' || _plan == 'premium';
      if (isProOrPremium && _customDomain.isNotEmpty) {
        await dio.post(
          '/portfolios/me/domain',
          data: {'hostname': _customDomain},
        );
      } else {
        try {
          await dio.delete('/portfolios/me/domain');
        } catch (_) {}
      }

      // Step B: Set portfolio slug
      await dio.put('/portfolios/me/settings', data: {'slug': _slug});

      // Step C: Trigger dynamic block auto-generation & details write
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
        // Wait briefly for step animations to conclude
        while (_currentStepIndex < _statusSteps.length - 1 && mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        if (mounted) {
          setState(() {
            _isDone = true;
            _progressValue = 1.0;
          });
          HapticFeedback.heavyImpact();

          // Wait a split second to let completion state display, then go to screen 7
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) {
            context.go('${RoutePaths.onboardingPreview}?slug=$_slug');
          }
        }
      }
    } catch (e) {
      _stepTimer?.cancel();
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _plan == 'premium'
        ? const Color(0xFFEC4899)
        : (_plan == 'pro' ? const Color(0xFF6366F1) : const Color(0xFF94A3B8));

    return PopScope(
      canPop: false, // Disables back button gesture
      child: Scaffold(
        backgroundColor: const Color(0xFF050816),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Animated Loader Orb
                _buildGenerationOrb(activeColor),
                const SizedBox(height: 40),

                // Step Status Text
                if (_errorMessage.isEmpty) ...[
                  Text(
                    _isDone
                        ? 'Deployment Complete! 🎉'
                        : 'Generating your portfolio...',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _statusSteps[_currentStepIndex],
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Generation Failed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = '';
                        _currentStepIndex = 0;
                        _progressValue = 0.05;
                      });
                      _startGenerationTimeline();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry Launch'),
                  ),
                ],
                const SizedBox(height: 30),

                // Progress Bar Indicator
                if (_errorMessage.isEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 6,
                      width: 240,
                      child: LinearProgressIndicator(
                        value: _progressValue,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        color: activeColor,
                      ),
                    ),
                  ),

                const Spacer(),

                // Warning Banner (Fixed near the bottom)
                if (_errorMessage.isEmpty) _buildWarningBanner(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerationOrb(Color activeColor) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: activeColor.withValues(alpha: 0.05),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.15),
          width: 2,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DO NOT CLOSE THE APP',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Please do not background, lock your device, or go back. Generating database grids...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
