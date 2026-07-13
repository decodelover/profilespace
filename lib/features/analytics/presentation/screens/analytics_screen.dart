/// Analytics Dashboard Screen
///
/// Displays portfolio engagement metrics: total views, device statistics,
/// visitor geographic breakdown, and a daily traffic sparkline.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/analytics_bloc.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<AnalyticsBloc>()..add(const AnalyticsFetchRequested()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, state) {
            if (state is AnalyticsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }
            if (state is AnalyticsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton.icon(
                        onPressed: () => context.read<AnalyticsBloc>().add(
                          const AnalyticsFetchRequested(),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is AnalyticsLoaded) {
              final data = state.analyticsData;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Primary Stat Card ──────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: GlassDecoration.card(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Profile Views',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${data.totalViews}',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              const Icon(
                                Icons.trending_up_rounded,
                                color: AppColors.success,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Live visitor analytics active',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.success),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Mini sparkline
                          SizedBox(
                            height: 70,
                            child: CustomPaint(
                              size: const Size(double.infinity, 70),
                              painter: _SparklinePainter(
                                dataPoints: data.viewsOverTime
                                    .map((p) => p.views)
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ─── Metric Cards Row ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'Mobile Views',
                            value: '${data.mobileViews}',
                            icon: Icons.phone_android_rounded,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _MetricCard(
                            label: 'Desktop Views',
                            value: '${data.desktopViews}',
                            icon: Icons.computer_rounded,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ─── Visitor Countries ──────────────────────────────────
                    Text(
                      'Visitor Locations',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (data.countries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                        child: Center(
                          child: Text(
                            'No location data recorded yet.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
                      ...data.countries.map((entry) {
                        final flag = entry.code == 'US'
                            ? '🇺🇸'
                            : entry.code == 'GB'
                            ? '🇬🇧'
                            : entry.code == 'DE'
                            ? '🇩🇪'
                            : entry.code == 'IN'
                            ? '🇮🇳'
                            : '🌐';
                        final maxCount = data.countries
                            .map((c) => c.count)
                            .reduce((a, b) => a > b ? a : b);
                        final percentage = maxCount > 0
                            ? entry.count / maxCount
                            : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _CountryRow(
                            flag: flag,
                            country: entry.name,
                            percentage: percentage,
                            rawCount: entry.count,
                          ),
                        );
                      }),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: GlassDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  final String flag;
  final String country;
  final double percentage;
  final int rawCount;

  const _CountryRow({
    required this.flag,
    required this.country,
    required this.percentage,
    required this.rawCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: GlassDecoration.card(),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(country, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: AppColors.canvasDark,
                    color: AppColors.accent,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$rawCount views',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

/// Dynamic sparkline painter for the traffic chart.
class _SparklinePainter extends CustomPainter {
  final List<int> dataPoints;

  _SparklinePainter({required this.dataPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final maxVal = dataPoints.reduce((a, b) => a > b ? a : b);
    final minVal = dataPoints.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);

    // Map points with slight padding inside the canvas
    final normalized = dataPoints.map((v) {
      return 0.15 + 0.7 * ((v - minVal) / range);
    }).toList();

    final path = Path();

    for (var i = 0; i < normalized.length; i++) {
      final x = (i / (normalized.length - 1)) * size.width;
      final y = size.height - (normalized[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw gradient fill below the sparkline path
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withValues(alpha: 0.25),
          AppColors.accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints;
}
