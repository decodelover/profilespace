/// Welcome Screen — Cinematic Onboarding Experience
///
/// A premium, immersive multi-page carousel that introduces Tspace with
/// living aurora backgrounds, floating particle fields, frosted-glass hero
/// cards, gradient text shimmer, and staggered entrance animations.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// WELCOME SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Background aurora animation
  late final AnimationController _auroraController;
  // Particle field animation
  late final AnimationController _particleController;
  // Per-page stagger entrance
  late final AnimationController _entranceController;
  late final Animation<double> _iconEntrance;
  late final Animation<double> _titleEntrance;
  late final Animation<double> _subtitleEntrance;

  // Shimmer for the CTA button
  late final AnimationController _shimmerController;

  static const _pages = [
    _WelcomePage(
      icon: Icons.space_dashboard_rounded,
      gradientStart: Color(0xFF6366F1),
      gradientEnd: Color(0xFFD946EF),
      title: 'Build Stunning\nPortfolios',
      subtitle:
          'Create a professional online presence in minutes.\nNo code required — just drag, drop, and shine.',
    ),
    _WelcomePage(
      icon: Icons.hub_rounded,
      gradientStart: Color(0xFF10B981),
      gradientEnd: Color(0xFF06B6D4),
      title: 'Connect Your\nFavorite Tools',
      subtitle:
          'Import projects from GitHub, Dribbble, and more.\nYour work, auto-synced and always up to date.',
    ),
    _WelcomePage(
      icon: Icons.rocket_launch_rounded,
      gradientStart: Color(0xFFF59E0B),
      gradientEnd: Color(0xFFEF4444),
      title: 'Get Discovered\nby Recruiters',
      subtitle:
          'Share your portfolio link and track who views it.\nReal-time analytics. Direct recruiter messages.',
    ),
  ];

  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    // Aurora background — slow orbit
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Particle field — continuous drift
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Stagger entrance for each page
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _iconEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
    );
    _titleEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    );
    _subtitleEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
    );

    _entranceController.forward();

    // Shimmer for CTA
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Generate particles
    final rng = math.Random(42);
    _particles = List.generate(
      45,
      (_) => _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 1.5 + rng.nextDouble() * 2.5,
        speed: 0.3 + rng.nextDouble() * 0.7,
        opacity: 0.15 + rng.nextDouble() * 0.35,
        phase: rng.nextDouble() * math.pi * 2,
      ),
    );
  }

  @override
  void dispose() {
    _auroraController.dispose();
    _particleController.dispose();
    _entranceController.dispose();
    _shimmerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _entranceController.reset();
    _entranceController.forward();
  }

  void _goToLogin() {
    context.go(RoutePaths.splash);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          // ─── Aurora mesh-gradient background ──────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _auroraController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AuroraPainter(t: _auroraController.value),
                );
              },
            ),
          ),

          // ─── Floating particle field ─────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    t: _particleController.value,
                  ),
                );
              },
            ),
          ),

          // ─── Subtle noise overlay ────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF050816).withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Main content ────────────────────────────────────────
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // Skip button — top right
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        right: AppSpacing.lg,
                      ),
                      child: TextButton(
                        onPressed: _goToLogin,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.04),
                        ),
                        child: Text(
                          'Skip',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ),
                    ),
                  ),

                  // Page view carousel
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return _buildPage(context, _pages[index]);
                      },
                    ),
                  ),

                  // Bottom controls
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        // Page indicators
                        _buildIndicators(),
                        const SizedBox(height: AppSpacing.lg),

                        // CTA Button
                        _buildCTAButton(context, isLastPage),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Staggered page content ──────────────────────────────────────────

  Widget _buildPage(BuildContext context, _WelcomePage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Floating hero icon with frosted-glass border
          FadeTransition(
            opacity: _iconEntrance,
            child: ScaleTransition(
              scale: _iconEntrance,
              child: _HeroIcon(
                icon: page.icon,
                gradientStart: page.gradientStart,
                gradientEnd: page.gradientEnd,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Title with gradient shimmer
          FadeTransition(
            opacity: _titleEntrance,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(_titleEntrance),
              child: Text(
                page.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.8,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Subtitle
          FadeTransition(
            opacity: _subtitleEntrance,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(_subtitleEntrance),
              child: Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                  fontSize: 15,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pill indicators with glow ────────────────────────────────────────

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
        final isActive = _currentPage == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      _pages[_currentPage].gradientStart,
                      _pages[_currentPage].gradientEnd,
                    ],
                  )
                : null,
            color: isActive ? null : Colors.white.withValues(alpha: 0.15),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _pages[_currentPage].gradientStart.withValues(
                        alpha: 0.5,
                      ),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // ─── CTA button — gradient shimmer or glass ──────────────────────────

  Widget _buildCTAButton(BuildContext context, bool isLastPage) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: isLastPage
            ? _buildGetStartedButton(context)
            : _buildNextButton(context),
      ),
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return AnimatedBuilder(
      key: const ValueKey('get_started'),
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFD946EF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFFD946EF).withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _goToLogin,
              child: Stack(
                children: [
                  // Shimmer overlay
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment(
                            -1.0 + 3.0 * _shimmerController.value,
                            0,
                          ),
                          end: Alignment(
                            -0.5 + 3.0 * _shimmerController.value,
                            0,
                          ),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Label
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return Container(
      key: const ValueKey('next'),
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
            );
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO ICON — Frosted glass card with gradient glow
// ═══════════════════════════════════════════════════════════════════════════

class _HeroIcon extends StatefulWidget {
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;

  const _HeroIcon({
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
  });

  @override
  State<_HeroIcon> createState() => _HeroIconState();
}

class _HeroIconState extends State<_HeroIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        final offset = math.sin(_floatController.value * math.pi) * 8;
        return Transform.translate(
          offset: Offset(0, -offset),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.gradientStart.withValues(alpha: 0.2),
                  widget.gradientEnd.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.5,
              ),
              boxShadow: [
                // Outer colored glow
                BoxShadow(
                  color: widget.gradientStart.withValues(alpha: 0.25),
                  blurRadius: 50,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: widget.gradientEnd.withValues(alpha: 0.15),
                  blurRadius: 80,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner gradient circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [widget.gradientStart, widget.gradientEnd],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradientStart.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                // Icon
                Icon(widget.icon, size: 40, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASS
// ═══════════════════════════════════════════════════════════════════════════

class _WelcomePage {
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final String title;
  final String subtitle;

  const _WelcomePage({
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.title,
    required this.subtitle,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// PARTICLE DATA
// ═══════════════════════════════════════════════════════════════════════════

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double phase;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// AURORA PAINTER — Multi-orb mesh gradient background
// ═══════════════════════════════════════════════════════════════════════════

class _AuroraPainter extends CustomPainter {
  final double t;

  _AuroraPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tau = math.pi * 2;

    // Deep space base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF050816),
    );

    // Orb 1 — Indigo (top-left drift)
    _drawOrb(
      canvas,
      Offset(
        w * (0.25 + 0.35 * math.sin(t * tau)),
        h * (0.20 + 0.15 * math.cos(t * tau * 0.8)),
      ),
      w * 0.7,
      const Color(0xFF6366F1),
      0.14,
    );

    // Orb 2 — Violet / Magenta (bottom-right drift)
    _drawOrb(
      canvas,
      Offset(
        w * (0.75 + 0.2 * math.cos((t + 0.33) * tau)),
        h * (0.70 + 0.18 * math.sin((t + 0.33) * tau * 0.7)),
      ),
      w * 0.6,
      const Color(0xFFD946EF),
      0.10,
    );

    // Orb 3 — Cyan accent (center drift)
    _drawOrb(
      canvas,
      Offset(
        w * (0.5 + 0.3 * math.sin((t + 0.66) * tau * 0.6)),
        h * (0.45 + 0.2 * math.cos((t + 0.66) * tau)),
      ),
      w * 0.5,
      const Color(0xFF06B6D4),
      0.07,
    );

    // Orb 4 — Warm amber (subtle, top-right)
    _drawOrb(
      canvas,
      Offset(
        w * (0.7 + 0.15 * math.sin((t + 0.5) * tau * 1.2)),
        h * (0.15 + 0.1 * math.cos((t + 0.5) * tau)),
      ),
      w * 0.35,
      const Color(0xFFF59E0B),
      0.04,
    );
  }

  void _drawOrb(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.t != t;
}

// ═══════════════════════════════════════════════════════════════════════════
// PARTICLE PAINTER — Floating dot field
// ═══════════════════════════════════════════════════════════════════════════

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  _ParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final tau = math.pi * 2;
      // Gentle circular drift
      final x =
          (p.x + 0.03 * math.sin(t * tau * p.speed + p.phase)) * size.width;
      final y =
          (p.y + 0.04 * math.cos(t * tau * p.speed + p.phase)) * size.height;

      // Pulsing opacity
      final pulsedOpacity =
          p.opacity * (0.6 + 0.4 * math.sin(t * tau * 2 + p.phase));

      canvas.drawCircle(
        Offset(x % size.width, y % size.height),
        p.size,
        Paint()..color = Colors.white.withValues(alpha: pulsedOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.t != t;
}
