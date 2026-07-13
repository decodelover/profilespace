/// Login Screen — Premium Glassmorphic Authentication Portal
///
/// Implements a cinematic sign-in / sign-up experience with an aurora
/// mesh-gradient background, floating animated logo, frosted-glass auth
/// card, redesigned social buttons, and smooth form transitions.
/// All business logic (AuthBloc, OAuth, email login) is preserved.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showEmailForm = false;
  bool _obscurePassword = true;

  // Animated background
  late final AnimationController _auroraController;
  // Floating logo
  late final AnimationController _logoFloatController;
  // Logo pulse ring
  late final AnimationController _logoPulseController;
  // Card entrance
  late final AnimationController _cardEntranceController;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  // Particle field
  late final AnimationController _particleController;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _logoFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _cardEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardFade = CurvedAnimation(
      parent: _cardEntranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _cardEntranceController,
            curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _cardEntranceController.forward();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    final rng = math.Random(77);
    _particles = List.generate(
      30,
      (_) => _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 1.0 + rng.nextDouble() * 2.0,
        speed: 0.3 + rng.nextDouble() * 0.7,
        opacity: 0.1 + rng.nextDouble() * 0.25,
        phase: rng.nextDouble() * math.pi * 2,
      ),
    );
  }

  @override
  void dispose() {
    _auroraController.dispose();
    _logoFloatController.dispose();
    _logoPulseController.dispose();
    _cardEntranceController.dispose();
    _particleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── OAuth handlers (preserved exactly) ──────────────────────────────

  Future<void> _handleOAuthLogin(String provider) async {
    final apiBaseUrl = Environment.apiUrl;
    final baseUrl = apiBaseUrl.replaceAll('/api', '');
    final redirectOrigin = Uri.base.origin;
    final oauthUrl =
        '$baseUrl/oauth/$provider/simulate?redirect_origin=${Uri.encodeComponent(redirectOrigin)}';

    final uri = Uri.parse(oauthUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Browser cannot open $oauthUrl';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication page launch failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleGithubLogin(BuildContext context) {
    _handleOAuthLogin('github');
  }

  void _handleGoogleLogin(BuildContext context) {
    _handleOAuthLogin('google');
  }

  void _handleEmailLogin(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthEmailLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.session.user.hasCompletedOnboarding) {
            context.go(RoutePaths.editor);
          } else {
            context.go(RoutePaths.onboardingRole);
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050816),
        body: Stack(
          children: [
            // ─── Aurora background ──────────────────────────────────
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

            // ─── Particle field ─────────────────────────────────────
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

            // ─── Content ────────────────────────────────────────────
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: AppSpacing.xl),

                            // ── Animated floating logo ──────────
                            _buildAnimatedLogo(),
                            const SizedBox(height: AppSpacing.lg),

                            // ── Title ───────────────────────────
                            Text(
                              'Tspace',
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.0,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your proof of work, beautifully packaged.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                            const SizedBox(height: 36),

                            // ── Loading state ───────────────────
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                if (state is AuthLoading) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.lg,
                                    ),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            color: AppColors.accent,
                                            strokeWidth: 2.5,
                                            strokeCap: StrokeCap.round,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          'Signing you in...',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.textMuted,
                                                fontSize: 13,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),

                            // ── Frosted glass auth card ─────────
                            FadeTransition(
                              opacity: _cardFade,
                              child: SlideTransition(
                                position: _cardSlide,
                                child: _buildGlassCard(context),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ── Trust indicator ─────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  size: 13,
                                  color: AppColors.textMuted.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Secured with 256-bit encryption',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontSize: 11,
                                        color: AppColors.textMuted.withValues(
                                          alpha: 0.7,
                                        ),
                                        letterSpacing: 0.3,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── Legal footer ────────────────────
                            Text(
                              'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Animated floating logo with pulse ring ──────────────────────────

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoFloatController, _logoPulseController]),
      builder: (context, _) {
        final floatOffset = math.sin(_logoFloatController.value * math.pi) * 6;
        final pulseScale = 0.85 + 0.15 * _logoPulseController.value;

        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulse ring
                Transform.scale(
                  scale: pulseScale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent.withValues(
                          alpha: 0.2 * (1 - _logoPulseController.value),
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // Logo container
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                        Color(0xFFD946EF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: const Color(0xFFD946EF).withValues(alpha: 0.15),
                        blurRadius: 50,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.space_dashboard_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Frosted glass card ──────────────────────────────────────────────

  Widget _buildGlassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _showEmailForm
                  ? _buildEmailForm(context)
                  : _buildSocialButtons(context),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Social login buttons ────────────────────────────────────────────

  Widget _buildSocialButtons(BuildContext context) {
    return Column(
      key: const ValueKey('social_login'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // GitHub button
        _SocialButton(
          onPressed: () => _handleGithubLogin(context),
          icon: Icons.code_rounded,
          label: 'Continue with GitHub',
          backgroundColor: const Color(0xFF161B22),
          accentColor: Colors.white,
          borderColor: Colors.white.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 14),

        // Google button
        _SocialButton(
          onPressed: () => _handleGoogleLogin(context),
          icon: Icons.g_mobiledata_rounded,
          iconSize: 30,
          label: 'Continue with Google',
          backgroundColor: Colors.white.withValues(alpha: 0.04),
          accentColor: AppColors.textPrimary,
          borderColor: Colors.white.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 20),

        // Divider with "or"
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or continue with',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Email sign-up button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _showEmailForm = true),
            icon: Icon(
              Icons.email_outlined,
              size: 18,
              color: AppColors.accent.withValues(alpha: 0.9),
            ),
            label: Text(
              'Sign up with email',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: AppColors.accent.withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Email login form ────────────────────────────────────────────────

  Widget _buildEmailForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('email_form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.2),
                      const Color(0xFFD946EF).withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.email_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Continue with Email',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Email field
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration(
              context,
              label: 'Email Address',
              icon: Icons.alternate_email_rounded,
            ),
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration:
                _inputDecoration(
                  context,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit button — gradient
          SizedBox(
            width: double.infinity,
            height: 54,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFD946EF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _handleEmailLogin(context),
                  child: Center(
                    child: Text(
                      'Sign In / Register',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Back to social sign-in
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () => setState(() => _showEmailForm = false),
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: AppColors.textMuted.withValues(alpha: 0.8),
              ),
              label: Text(
                'Back to social sign-in',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared input decoration ─────────────────────────────────────────

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppColors.textMuted.withValues(alpha: 0.8),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SOCIAL BUTTON — Reusable glass button with left accent
// ═══════════════════════════════════════════════════════════════════════════

class _SocialButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double iconSize;
  final String label;
  final Color backgroundColor;
  final Color accentColor;
  final Color borderColor;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    this.iconSize = 20,
    required this.label,
    required this.backgroundColor,
    required this.accentColor,
    required this.borderColor,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _hovering
              ? widget.backgroundColor.withValues(alpha: 0.15)
              : widget.backgroundColor,
          border: Border.all(
            color: _hovering
                ? AppColors.accent.withValues(alpha: 0.3)
                : widget.borderColor,
          ),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: widget.iconSize,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AURORA PAINTER — Shared cinematic mesh-gradient background
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

    // Orb 1 — Indigo
    _drawOrb(
      canvas,
      Offset(
        w * (0.3 + 0.3 * math.sin(t * tau * 0.9)),
        h * (0.25 + 0.15 * math.cos(t * tau)),
      ),
      w * 0.65,
      const Color(0xFF6366F1),
      0.13,
    );

    // Orb 2 — Violet
    _drawOrb(
      canvas,
      Offset(
        w * (0.7 + 0.2 * math.cos((t + 0.4) * tau)),
        h * (0.65 + 0.15 * math.sin((t + 0.4) * tau * 0.8)),
      ),
      w * 0.55,
      const Color(0xFFD946EF),
      0.09,
    );

    // Orb 3 — Cyan
    _drawOrb(
      canvas,
      Offset(
        w * (0.5 + 0.25 * math.sin((t + 0.7) * tau * 0.6)),
        h * (0.5 + 0.2 * math.cos((t + 0.7) * tau)),
      ),
      w * 0.45,
      const Color(0xFF06B6D4),
      0.06,
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

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  _ParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final tau = math.pi * 2;
      final x =
          (p.x + 0.03 * math.sin(t * tau * p.speed + p.phase)) * size.width;
      final y =
          (p.y + 0.04 * math.cos(t * tau * p.speed + p.phase)) * size.height;

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
