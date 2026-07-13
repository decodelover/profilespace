/// Onboarding Screen 5 — Domain Setup
///
/// Lets the user configure their subdomain (and custom domain if on Pro/Premium).
/// Implements debounced real-time availability checking via the backend API.
library;

import 'dart:async';
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
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();

  Timer? _debounce;
  bool _isCheckingSlug = false;
  bool _isSlugAvailable = true;
  String? _slugError;

  bool _isProOrPremium = false;
  bool _didInit = false;

  Map<String, String> get _queryParams {
    if (!mounted) return {};
    return GoRouterState.of(context).uri.queryParameters;
  }

  String get _fullName => _queryParams['full_name'] ?? 'User';
  String get _plan => _queryParams['plan'] ?? 'free';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _isProOrPremium = _plan == 'pro' || _plan == 'premium';

      // Pre-fill slug based on name
      final cleanedName = _fullName.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
      if (cleanedName.isNotEmpty) {
        _slugController.text = cleanedName;
        _domainController.text = '$cleanedName.com';
        _checkSlug(cleanedName);
      } else {
        _slugController.text = 'yourname';
        _domainController.text = 'yourdomain.com';
      }
    }
  }

  void _onSlugChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() {
      _isCheckingSlug = true;
      _slugError = null;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final cleanText = text.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9\-]'),
        '',
      );
      if (cleanText != text) {
        _slugController.text = cleanText;
        _slugController.selection = TextSelection.fromPosition(
          TextPosition(offset: cleanText.length),
        );
      }
      _checkSlug(cleanText);
    });
  }

  Future<void> _checkSlug(String slug) async {
    if (slug.isEmpty) {
      setState(() {
        _isCheckingSlug = false;
        _isSlugAvailable = false;
        _slugError = 'Slug cannot be empty';
      });
      return;
    }

    try {
      final dio = sl<Dio>();
      final response = await dio.get(
        '/portfolios/check-slug',
        queryParameters: {'slug': slug},
      );
      if (mounted) {
        setState(() {
          _isCheckingSlug = false;
          _isSlugAvailable = response.data['available'] == true;
          _slugError = _isSlugAvailable
              ? null
              : 'This subdomain is already taken';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCheckingSlug = false;
          _isSlugAvailable = true; // Fallback to allow progress
          _slugError = null;
        });
      }
    }
  }

  void _onCreateAndPublish() {
    final slug = _slugController.text.trim();
    final customDomain = _domainController.text.trim();

    if (slug.isEmpty) {
      setState(() => _slugError = 'Slug cannot be empty');
      return;
    }

    if (!_isSlugAvailable) {
      return;
    }

    HapticFeedback.mediumImpact();

    // Propagate all query parameters plus slug/domain to publishing loading screen
    final newParams = Map<String, String>.from(_queryParams);
    newParams['slug'] = slug;
    if (_isProOrPremium && customDomain.isNotEmpty) {
      newParams['custom_domain'] = customDomain;
    }

    final uri = Uri(
      path: RoutePaths.onboardingPublish,
      queryParameters: newParams,
    );
    context.go(uri.toString());
  }

  @override
  void dispose() {
    _slugController.dispose();
    _domainController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _plan == 'premium'
        ? const Color(0xFFEC4899)
        : (_plan == 'pro' ? const Color(0xFF6366F1) : const Color(0xFF94A3B8));

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          // Background ambient glows
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, -0.6),
                  radius: 1.1,
                  colors: [
                    activeColor.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Indicator & Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          final uri = Uri(
                            path: RoutePaths.onboardingTemplate,
                            queryParameters: _queryParams,
                          );
                          context.go(uri.toString());
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Step 5 of 6',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Step Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 5 / 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set up your domain',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isProOrPremium
                            ? 'Configure your custom domain or subdomain configuration below.'
                            : 'Set up your free subdomain. You can upgrade to a custom domain anytime.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Inputs
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── Subdomain Section ───
                            const Text(
                              'CHOOSE SUBDOMAIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildSubdomainField(activeColor),
                            if (_slugError != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _slugError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),

                            // ─── Custom Domain Section (Pro/Premium) ───
                            _buildCustomDomainSection(activeColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Fixed CTA Button
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            _isSlugAvailable
                                ? activeColor
                                : AppColors.textMuted,
                            _isSlugAvailable
                                ? activeColor.withValues(alpha: 0.8)
                                : AppColors.textMuted,
                          ],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _isSlugAvailable && !_isCheckingSlug
                            ? _onCreateAndPublish
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white.withValues(
                            alpha: 0.5,
                          ),
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Create & Publish Site',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubdomainField(Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _slugError != null
              ? AppColors.error
              : (_isSlugAvailable
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.error),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, color: activeColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _slugController,
              onChanged: _onSlugChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'yourname',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
              style: TextStyle(
                color: activeColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Text(
            '.tspace.me',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          if (_isCheckingSlug)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else if (_slugController.text.isNotEmpty)
            Icon(
              _isSlugAvailable
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: _isSlugAvailable ? AppColors.success : AppColors.error,
              size: 18,
            ),
        ],
      ),
    );
  }

  Widget _buildCustomDomainSection(Color activeColor) {
    if (!_isProOrPremium) {
      // Locked state for Free Plan
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'CUSTOM DOMAIN SUPPORT',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Hook up your own custom domain (e.g. yourname.com) to establish a unique professional brand.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                // Navigate back to pricing plan screen
                final uri = Uri(
                  path: RoutePaths.onboardingPlan,
                  queryParameters: _queryParams,
                );
                context.go(uri.toString());
              },
              child: const Text(
                'Upgrade to Pro for Custom Domains →',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Enabled state for Pro/Premium Plan
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONNECT CUSTOM DOMAIN (PRO)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.language_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _domainController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'yourname.com',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ensure you point your domain\'s DNS A-record to our server IP.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
