/// Onboarding Screen 7 — Live Preview & Launch Success
///
/// Displays success confirmation, shows the public site URL,
/// provides copy/share utilities, and routes back to the dashboard editor.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class LivePreviewScreen extends StatelessWidget {
  const LivePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract slug dynamically from GoRouter state uri
    final state = GoRouterState.of(context);
    final slug = state.uri.queryParameters['slug'] ?? 'username';

    // Compute the local public preview URL
    // e.g. http://127.0.0.1:8000/public/username
    final apiBaseUrl = Environment.apiUrl.replaceFirst('/api', '');
    final publicUrl = '$apiBaseUrl/public/$slug';

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Color(0xFF10B981).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success checkmark badge
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Success Title
                      Text(
                        'Your site is live! 🚀',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your bento-style portfolio has been generated, compiled, and published successfully.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Browser Preview Frame Mock
                      _buildBrowserMockFrame(context, publicUrl),
                      const SizedBox(height: 32),

                      // Action Button List
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _openLiveSite(publicUrl),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              'View Live Site',
                              style: TextStyle(
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
                      ),
                      const SizedBox(height: 12),

                      // Secondary Back to Dashboard button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.go(RoutePaths.editor);
                          },
                          icon: const Icon(
                            Icons.dashboard_customize_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Edit Bento Grid Editor',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowserMockFrame(BuildContext context, String url) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Browser address bar header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white.withValues(alpha: 0.02),
            child: Row(
              children: [
                // Red/Yellow/Green dots
                const Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: Colors.redAccent),
                    SizedBox(width: 4),
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: Colors.amberAccent,
                    ),
                    SizedBox(width: 4),
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: Colors.greenAccent,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // URL box
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Text(
                      url,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Copy/Share icon
                GestureDetector(
                  onTap: () => _copyToClipboard(context, url),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          // Browser body preview mockup
          Container(
            height: 160,
            width: double.infinity,
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1E293B),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.indigoAccent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 80, height: 8, color: Colors.white24),
                        const SizedBox(height: 4),
                        Container(width: 120, height: 6, color: Colors.white12),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 6,
                  color: Colors.white12,
                ),
                const SizedBox(height: 6),
                Container(width: 180, height: 6, color: Colors.white12),
                const SizedBox(height: 16),
                // Bento cards preview
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
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
    );
  }

  void _openLiveSite(String url) async {
    HapticFeedback.mediumImpact();
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  void _copyToClipboard(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Portfolio URL copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
