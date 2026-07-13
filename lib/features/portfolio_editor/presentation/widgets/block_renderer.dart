/// Block Renderer — Polymorphic Block Component Router
///
/// Inspects the [BlockType] of a [PortfolioBlock] and renders the
/// appropriate widget. Adapts background and text colors to Light/Dark modes.
library;

import 'package:flutter/material.dart';

import '../../../../core/domain/entities.dart';
import '../../../../core/theme/app_theme.dart';

/// Routes a [PortfolioBlock] to its specialised widget.
class BlockRenderer extends StatelessWidget {
  final PortfolioBlock block;
  final String layoutTemplate;

  const BlockRenderer({
    super.key,
    required this.block,
    this.layoutTemplate = 'minimal_dark',
  });

  @override
  Widget build(BuildContext context) {
    final isLight = layoutTemplate == 'minimal_light';

    return switch (block.type) {
      BlockType.profile => _ProfileBlock(
        content: block.content,
        isLight: isLight,
      ),
      BlockType.text => _TextBlock(content: block.content, isLight: isLight),
      BlockType.link => _LinkBlock(content: block.content, isLight: isLight),
      BlockType.github => _GithubBlock(
        content: block.content,
        isLight: isLight,
      ),
      BlockType.figma => _FigmaBlock(content: block.content, isLight: isLight),
      BlockType.video => _VideoBlock(content: block.content, isLight: isLight),
      BlockType.rss => _RssBlock(content: block.content, isLight: isLight),
      BlockType.statsCounter => _StatsBlock(
        content: block.content,
        isLight: isLight,
      ),
      BlockType.prompt => _PromptBlock(
        content: block.content,
        isLight: isLight,
      ),
      BlockType.image => _ImageBlock(content: block.content, isLight: isLight),
      BlockType.project => _ProjectBlock(
        content: block.content,
        isLight: isLight,
      ),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════
// INDIVIDUAL BLOCK WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _ProfileBlock extends StatelessWidget {
  final Map<String, dynamic> content;
  final bool isLight;

  const _ProfileBlock({required this.content, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final textColor = isLight ? const Color(0xFF111827) : Colors.white;
    final subtitleColor = isLight
        ? const Color(0xFF4B5563)
        : AppColors.textSecondary;
    final avatarUrl = content['avatar_url'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accent.withValues(
                  alpha: isLight ? 0.12 : 0.2,
                ),
                backgroundImage: avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        (content['name'] as String? ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content['name'] as String? ?? 'Your Name',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      content['title'] as String? ?? 'Professional Title',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: subtitleColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (content['bio'] != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              content['bio'] as String,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: subtitleColor),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          // Availability status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  content['availability'] as String? ?? 'Open for roles',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.success,
                    fontSize: 12,
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

class _TextBlock extends StatelessWidget {
  final Map<String, dynamic> content;
  final bool isLight;

  const _TextBlock({required this.content, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final textColor = isLight ? const Color(0xFF1F2937) : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        content['text'] as String? ?? 'Add your text here...',
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: textColor),
      ),
    );
  }
}

class _LinkBlock extends StatelessWidget {
  final Map<String, dynamic> content;
  final bool isLight;

  const _LinkBlock({required this.content, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final textColor = isLight ? const Color(0xFF111827) : Colors.white;
    final subtitleColor = isLight
        ? const Color(0xFF4B5563)
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.link_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content['label'] as String? ?? 'Link',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  content['url'] as String? ?? 'https://...',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: subtitleColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_outward_rounded,
            color: AppColors.textMuted,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _GithubBlock extends StatelessWidget {
  final Map<String, dynamic> content;
  final bool isLight;

  const _GithubBlock({required this.content, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final textColor = isLight ? const Color(0xFF111827) : Colors.white;
    final subtitleColor = isLight
        ? const Color(0xFF4B5563)
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.code_rounded, color: textColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  content['repo_name'] as String? ?? 'repository',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            content['description'] as String? ?? 'No description',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: subtitleColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
              const SizedBox(width: 4),
              Text(
                '${content['stars'] ?? 0}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: textColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  content['language'] as String? ?? 'Code',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FigmaBlock extends StatelessWidget {
  final Map<String, dynamic> content;
  final bool isLight;

  const _FigmaBlock({required this.content, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final textColor = isLight ? const Color(0xFF111827) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.design_services_rounded,
                color: Color(0xFFA259FF),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Figma',
                style: TextStyle(
                  color: Color(0xFFA259FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content['project_name'] as String? ?? 'Design Project',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}

class _VideoBlock extends StatelessWidget {
  final Map<String, dynamic> content;
  final bool isLight;

  const _VideoBlock({required this.content, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final textColor = isLight ? const Color(0xFF111827) : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF3F4F6) : AppColors.canvasDark,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_filled_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              content['title'] as String? ?? 'Video',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _RssBlock extends StatelessWidget {
  final Map<String, dynamic> content;
  final bool isLight;

  const _RssBlock({required this.content, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final textColor = isLight ? const Color(0xFF111827) : Colors.white;
    final subtitleColor = isLight
        ? const Color(0xFF4B5563)
        : AppColors.textSecondary;
    final articles =
        (content['articles'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        [];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rss_feed_rounded,
                color: AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Latest Articles',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: textColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...articles
              .take(3)
              .map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• ${a['title'] ?? 'Article'}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: subtitleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _StatsBlock extends StatelessWidget {
  final Map<String, dynamic> content;
  final bool isLight;

  const _StatsBlock({required this.content, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final subtitleColor = isLight
        ? const Color(0xFF4B5563)
        : AppColors.textSecondary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            content['value'] as String? ?? '0',
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: 4),
          Text(
            content['label'] as String? ?? 'Metric',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: subtitleColor),
          ),
        ],
      ),
    );
  }
}

class _PromptBlock extends StatelessWidget {
  final Map<String, dynamic> content;
  final bool isLight;

  const _PromptBlock({required this.content, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final codeBg = isLight ? const Color(0xFFF3F4F6) : AppColors.canvasDark;
    final codeTextColor = isLight ? const Color(0xFF374151) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.smart_toy_rounded, color: AppColors.accent, size: 18),
              SizedBox(width: 6),
              Text(
                'Prompt Playground',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // System prompt preview
          Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            decoration: BoxDecoration(
              color: codeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              content['system'] as String? ??
                  'System: You are a helpful assistant...',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: codeTextColor,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  final Map<String, dynamic> content;
  final bool isLight;

  const _ImageBlock({required this.content, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final url = content['url'] as String?;
    if (url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Image.network(url, fit: BoxFit.cover),
      );
    }
    return const Center(
      child: Icon(Icons.image_rounded, color: AppColors.textMuted, size: 32),
    );
  }
}

class _ProjectBlock extends StatelessWidget {
  final Map<String, dynamic> content;
  final bool isLight;

  const _ProjectBlock({required this.content, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final title = content['title'] as String? ?? 'My Project';
    final desc = content['description'] as String? ?? '';
    final url = content['url'] as String? ?? '';
    final skills = (content['skills'] as List<dynamic>?)?.cast<String>() ?? [];
    final imageUrl = content['image_url'] as String? ?? '';

    final textColor = isLight ? const Color(0xFF111827) : Colors.white;
    final descColor = isLight
        ? const Color(0xFF4B5563)
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (url.isNotEmpty) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_outward_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ],
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(color: descColor, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          // Footer row with image/skills
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: skills
                      .take(2)
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              if (imageUrl.isNotEmpty) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
