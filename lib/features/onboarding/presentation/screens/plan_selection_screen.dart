/// Onboarding Screen 3 — Plan Selection
///
/// Displays Free, Pro, and Premium plans in a swipeable PageView.
/// Highlights the recommended Pro plan. Saves choice to cache and continues.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _selectedPageIndex = 1; // Default to Pro plan (index 1)

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'free',
      'name': 'Free Plan',
      'price': '\$0',
      'period': 'free forever',
      'color': const Color(0xFF94A3B8),
      'isRecommended': false,
      'features': [
        'Built-in subdomain (username.tspace.me)',
        'Up to 1 project entry',
        'Dark & Light theme customization',
        'Basic layout templates',
      ],
    },
    {
      'id': 'pro',
      'name': 'Pro Plan',
      'price': '\$8',
      'period': 'per month',
      'color': const Color(0xFF6366F1),
      'isRecommended': true,
      'features': [
        'Full custom domain (yourdomain.com)',
        'Unlimited project entries',
        'Remove "Tspace" branding logo',
        'Real-time visitor analytics',
        'Standard SEO metadata settings',
      ],
    },
    {
      'id': 'premium',
      'name': 'Premium VIP',
      'price': '\$19',
      'period': 'per month',
      'color': const Color(0xFFEC4899),
      'isRecommended': false,
      'features': [
        'Dedicated VIP SSL domain routing',
        'Advanced custom SEO metadata fields',
        'Priority premium support response',
        'Analytics & Lead exports',
        'Early access to new layouts',
      ],
    },
  ];

  Map<String, String> get _queryParams {
    if (!mounted) return {};
    return GoRouterState.of(context).uri.queryParameters;
  }

  void _onContinue() {
    HapticFeedback.mediumImpact();
    final selectedPlanId = _plans[_selectedPageIndex]['id'];

    // Propagate all previous query parameters + selected plan
    final newParams = Map<String, String>.from(_queryParams);
    newParams['plan'] = selectedPlanId;

    final uri = Uri(
      path: RoutePaths.onboardingTemplate,
      queryParameters: newParams,
    );
    context.go(uri.toString());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          // Background Glows
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.7, -0.5),
                  radius: 1.2,
                  colors: [
                    _plans[_selectedPageIndex]['color'].withValues(alpha: 0.12),
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
                            path: RoutePaths.onboardingDetails,
                            queryParameters: _queryParams,
                          );
                          context.go(uri.toString());
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Step 3 of 6',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer balance
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
                      widthFactor: 3 / 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _plans[_selectedPageIndex]['color'],
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
                        'Select a pricing plan',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose the tier that fits your needs. You can change plans later.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Pricing Cards Slider
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _plans.length,
                    onPageChanged: (index) {
                      setState(() => _selectedPageIndex = index);
                      HapticFeedback.selectionClick();
                    },
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      final isSelected = _selectedPageIndex == index;

                      return AnimatedScale(
                        scale: isSelected ? 1.0 : 0.92,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: _buildPlanCard(plan, isSelected),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Select plan CTA button
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
                            _plans[_selectedPageIndex]['color'],
                            _plans[_selectedPageIndex]['color'].withValues(
                              alpha: 0.8,
                            ),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _plans[_selectedPageIndex]['color']
                                .withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Choose ${_plans[_selectedPageIndex]['name']}',
                          style: const TextStyle(
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

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isSelected) {
    final color = plan['color'] as Color;
    final isRecommended = plan['isRecommended'] as bool;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? color : Colors.white.withValues(alpha: 0.06),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    if (isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'RECOMMENDED',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan['price'] as String,
                      style: TextStyle(
                        color: color,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plan['period'] as String,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Divider
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 20),

                // Features list
                Expanded(
                  child: ListView.builder(
                    itemCount: (plan['features'] as List).length,
                    itemBuilder: (context, fIndex) {
                      final feature = plan['features'][fIndex] as String;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: color,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
