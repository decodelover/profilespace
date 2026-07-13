/// Onboarding Screen 4 — Profile Overview & Template Selection
///
/// Displays a summary of the captured profile details and dynamic projects list.
/// Allows jumping back to step 2 to edit. Provides a horizontal template selector gallery.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class OverviewTemplateScreen extends StatefulWidget {
  const OverviewTemplateScreen({super.key});

  @override
  State<OverviewTemplateScreen> createState() => _OverviewTemplateScreenState();
}

class _OverviewTemplateScreenState extends State<OverviewTemplateScreen> {
  String _selectedTemplate = 'minimal_dark'; // Default

  final List<Map<String, String>> _templates = [
    {
      'id': 'minimal_dark',
      'name': 'Minimal Dark',
      'desc': 'Sleek dark-first bento grid with neon gradients.',
      'previewColor': '0xFF0F172A',
    },
    {
      'id': 'minimal_light',
      'name': 'Minimal Light',
      'desc': 'Clean, spacious design with crisp text and shadows.',
      'previewColor': '0xFFF9FAFB',
    },
    {
      'id': 'bento_creative',
      'name': 'Bento Creative',
      'desc': 'Artistic layout with colorful grids and bold fonts.',
      'previewColor': '0xFF1E1B4B',
    },
  ];

  Map<String, String> get _queryParams {
    if (!mounted) return {};
    return GoRouterState.of(context).uri.queryParameters;
  }

  String get _fullName => _queryParams['full_name'] ?? '';
  String get _title => _queryParams['title'] ?? '';
  String get _bio => _queryParams['bio'] ?? '';
  String get _skills => _queryParams['skills'] ?? '';
  String get _plan => _queryParams['plan'] ?? 'free';
  String get _projectsParam => _queryParams['projects'] ?? '[]';

  List<dynamic> get _parsedProjects {
    try {
      return jsonDecode(_projectsParam) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final layoutParam = _queryParams['layout_template'];
    if (layoutParam != null && layoutParam.isNotEmpty) {
      _selectedTemplate = layoutParam;
    }
  }

  void _onEditProfile() {
    HapticFeedback.lightImpact();
    // Go back to details form carrying all parameters
    final uri = Uri(
      path: RoutePaths.onboardingDetails,
      queryParameters: _queryParams,
    );
    context.go(uri.toString());
  }

  void _onContinue() {
    HapticFeedback.mediumImpact();

    // Propagate all parameters + selected template choice
    final newParams = Map<String, String>.from(_queryParams);
    newParams['layout_template'] = _selectedTemplate;

    // Directs to domain setup (Screen 5)
    final uri = Uri(
      path: RoutePaths.onboardingLaunch,
      queryParameters: newParams,
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          // Ambient backgrounds
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, 0.6),
                  radius: 1.1,
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.08),
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
                            path: RoutePaths.onboardingPlan,
                            queryParameters: _queryParams,
                          );
                          context.go(uri.toString());
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Step 4 of 6',
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
                      widthFactor: 4 / 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
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
                  child: Text(
                    'Review & Choose Theme',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contents scroll area
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
                            // ─── Details Overview Summary ───
                            _buildSummaryCard(),
                            const SizedBox(height: 28),

                            // ─── Template Selector Gallery ───
                            const Row(
                              children: [
                                Icon(
                                  Icons.palette_outlined,
                                  color: Color(0xFF6366F1),
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'SELECT TEMPLATE DESIGN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTemplateSelector(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Next Button
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        ),
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
                        child: const Text(
                          'Continue to Domain Setup',
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

  Widget _buildSummaryCard() {
    final projects = _parsedProjects;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: Color(0xFF6366F1),
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'PROFILE OVERVIEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _onEditProfile,
                child: const Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF6366F1),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name and Title
          _summaryRow('Name', _fullName),
          _summaryRow('Title', _title),
          _summaryRow('Bio', _bio, maxLines: 2),
          _summaryRow('Skills', _skills),
          _summaryRow('Plan Selected', _plan.toUpperCase()),

          // Projects count summary
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Showcased Projects',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              Text(
                '${projects.length} project(s)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'None provided',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final t = _templates[index];
          final isSelected = _selectedTemplate == t['id'];
          final color = Color(int.parse(t['previewColor']!));

          return GestureDetector(
            onTap: () {
              setState(() => _selectedTemplate = t['id']!);
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 14),
              width: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.white.withValues(alpha: 0.05),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visual preview thumbnail box
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        index == 1
                            ? Icons.wb_sunny_rounded
                            : Icons.nights_stay_rounded,
                        color: index == 1
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF6366F1),
                        size: 24,
                      ),
                    ),
                  ),
                  // Name and description
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t['name']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t['desc']!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 8.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
