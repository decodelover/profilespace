/// Editor Screen — Main Bento Grid Portfolio Editor
///
/// Implements the dashboard editor from the Mobile UX spec with:
/// - A 2-column mobile bento grid compiled from block data
/// - iOS-style "Wiggle & Move" reordering via long-press
/// - Floating "+" button that opens the "Add Block" bottom sheet
/// - Edit Mode / Live View segmented tab
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/domain/entities.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/portfolio_bloc.dart';
import '../widgets/block_renderer.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PortfolioBloc>()..add(const PortfolioLoadRequested()),
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView();

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0; // 0 = Edit, 1 = Live
  late final AnimationController _wiggleController;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  void _onLongPress(BuildContext context) {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
    context.read<PortfolioBloc>().add(const PortfolioWiggleModeToggled());
  }

  void _onDoneEditing(BuildContext context) {
    context.read<PortfolioBloc>().add(const PortfolioWiggleModeToggled());
  }

  void _showAddBlockSheet(BuildContext blocContext) {
    showModalBottomSheet(
      context: blocContext,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _AddBlockSheet(
        onBlockSelected: (type) {
          Navigator.pop(blocContext);
          blocContext.read<PortfolioBloc>().add(
            PortfolioBlockAdded(type: type, content: _defaultContent(type)),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _defaultContent(BlockType type) {
    return switch (type) {
      BlockType.profile => {
        'name': 'Your Name',
        'title': 'Your Title',
        'availability': 'Open for roles',
      },
      BlockType.text => {'text': 'Write something here...'},
      BlockType.link => {'label': 'My Link', 'url': 'https://...'},
      BlockType.github => {
        'repo_name': 'my-project',
        'description': 'A cool project',
        'stars': 0,
        'language': 'Dart',
      },
      BlockType.statsCounter => {'value': '100+', 'label': 'Projects'},
      BlockType.prompt => {
        'system': 'You are a helpful assistant...',
        'input': 'User prompt here',
        'output': 'Generated response...',
      },
      _ => {},
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {},
            ),
            title: const Text('TSPACE PORTFOLIO'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              // Segmented tab control: Edit / Live
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      _buildTab('Edit Mode', 0),
                      _buildTab('Live View', 1),
                    ],
                  ),
                ),
              ),

              // Grid content
              Expanded(child: _buildContent(context, state)),

              // Wiggle mode banner
              if (state is PortfolioLoaded && state.isWiggleMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  color: AppColors.accent.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.drag_indicator_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Drag blocks to reorder. Tap ✕ to delete.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.accent),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _onDoneEditing(context),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          floatingActionButton: state is PortfolioLoaded && !state.isWiggleMode
              ? FloatingActionButton(
                  onPressed: () => _showAddBlockSheet(context),
                  child: const Icon(Icons.add_rounded),
                )
              : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isActive ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PortfolioState state) {
    if (state is PortfolioLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (state is PortfolioError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => context.read<PortfolioBloc>().add(
                const PortfolioLoadRequested(),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is PortfolioLoaded) {
      final blocks = state.portfolio.blocks;

      if (blocks.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.grid_view_rounded,
                color: AppColors.textMuted,
                size: 64,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your grid is empty',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tap + to add your first block.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }

      return state.isWiggleMode
          ? _buildWiggleGrid(context, blocks, state)
          : _buildBentoGrid(
              context,
              blocks,
              state.portfolio.themeSettings.layoutTemplate,
            );
    }

    return const SizedBox.shrink();
  }

  /// Opens device gallery to select an image, uploads it to R2, and
  /// attaches the URL to the bento block.
  Future<void> _handleImageBlockTap(
    BuildContext context,
    PortfolioBlock block,
  ) async {
    if (block.type != BlockType.image) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null && context.mounted) {
      context.read<PortfolioBloc>().add(
        PortfolioBlockImageUploadRequested(
          blockId: block.id,
          filePath: image.path,
        ),
      );
    }
  }

  /// Standard 2-column bento grid with long-press to enter wiggle mode.
  Widget _buildBentoGrid(
    BuildContext context,
    List<PortfolioBlock> blocks,
    String layoutTemplate,
  ) {
    final isLight = layoutTemplate == 'minimal_light';
    final cardDec = isLight
        ? BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          )
        : GlassDecoration.card();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: blocks.length,
        itemBuilder: (context, index) {
          final block = blocks[index];
          return GestureDetector(
            onLongPress: () => _onLongPress(context),
            onTap: () => _handleImageBlockTap(context, block),
            child: Container(
              decoration: cardDec,
              clipBehavior: Clip.antiAlias,
              child: BlockRenderer(
                block: block,
                layoutTemplate: layoutTemplate,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Wiggle-mode grid: blocks rotate ±1° and show delete badges.
  Widget _buildWiggleGrid(
    BuildContext context,
    List<PortfolioBlock> blocks,
    PortfolioLoaded state,
  ) {
    final layoutTemplate = state.portfolio.themeSettings.layoutTemplate;
    final isLight = layoutTemplate == 'minimal_light';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ReorderableGridView(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        onReorder: (oldIndex, newIndex) {
          context.read<PortfolioBloc>().add(
            PortfolioBlocksReordered(oldIndex: oldIndex, newIndex: newIndex),
          );
        },
        children: blocks.map((block) {
          return _WiggleBlockWrapper(
            key: ValueKey(block.id),
            controller: _wiggleController,
            isLight: isLight,
            onDelete: () {
              context.read<PortfolioBloc>().add(
                PortfolioBlockDeleted(block.id),
              );
            },
            child: BlockRenderer(block: block, layoutTemplate: layoutTemplate),
          );
        }).toList(),
      ),
    );
  }
}

/// Wraps a block with a wiggle rotation animation and a delete badge.
class _WiggleBlockWrapper extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onDelete;
  final Widget child;
  final bool isLight;

  const _WiggleBlockWrapper({
    super.key,
    required this.controller,
    required this.onDelete,
    required this.child,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Wiggle between -1° and +1°.
        final angle = math.sin(controller.value * math.pi * 2) * 0.017;
        final borderAccent = AppColors.accent.withValues(alpha: 0.3);
        final cardDec = isLight
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderAccent, width: 1.5),
              )
            : GlassDecoration.card(borderColor: borderAccent);

        return Transform.rotate(
          angle: angle,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: cardDec,
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
              // Delete badge
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ADD BLOCK BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════

class _AddBlockSheet extends StatefulWidget {
  final ValueChanged<BlockType> onBlockSelected;

  const _AddBlockSheet({required this.onBlockSelected});

  @override
  State<_AddBlockSheet> createState() => _AddBlockSheetState();
}

class _AddBlockSheetState extends State<_AddBlockSheet> {
  int _categoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  static const _categories = [
    'General',
    'Developer',
    'Creative',
    'Writers',
    'AI / Prompts',
  ];

  static const _blockOptions = <String, List<_BlockOption>>{
    'General': [
      _BlockOption(BlockType.profile, 'Profile Card', Icons.person_rounded),
      _BlockOption(BlockType.text, 'Text Block', Icons.text_fields_rounded),
      _BlockOption(BlockType.link, 'Link', Icons.link_rounded),
      _BlockOption(
        BlockType.image,
        'Image Gallery',
        Icons.photo_library_rounded,
      ),
      _BlockOption(
        BlockType.statsCounter,
        'Stats Counter',
        Icons.trending_up_rounded,
      ),
    ],
    'Developer': [
      _BlockOption(BlockType.github, 'GitHub Repo', Icons.code_rounded),
    ],
    'Creative': [
      _BlockOption(
        BlockType.figma,
        'Figma Embed',
        Icons.design_services_rounded,
      ),
      _BlockOption(BlockType.video, 'Video Embed', Icons.play_circle_rounded),
    ],
    'Writers': [
      _BlockOption(BlockType.rss, 'RSS / Articles', Icons.rss_feed_rounded),
    ],
    'AI / Prompts': [
      _BlockOption(
        BlockType.prompt,
        'Prompt Playground',
        Icons.smart_toy_rounded,
      ),
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = _categories[_categoryIndex];
    final options = _blockOptions[categoryName] ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    'Add Block',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search blocks...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                  ),
                  isDense: true,
                ),
              ),
            ),

            // Category tabs
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemCount: _categories.length,
                itemBuilder: (_, index) {
                  final isActive = _categoryIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _categoryIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.accent
                            : AppColors.canvasDark,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: isActive
                            ? null
                            : Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        _categories[index],
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isActive ? Colors.white : AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Block options grid
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemCount: options.length,
                itemBuilder: (_, index) {
                  final option = options[index];
                  return GestureDetector(
                    onTap: () => widget.onBlockSelected(option.type),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: GlassDecoration.card(),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              option.icon,
                              color: AppColors.accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            option.label,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.add_circle_outline_rounded,
                            color: AppColors.textMuted,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BlockOption {
  final BlockType type;
  final String label;
  final IconData icon;

  const _BlockOption(this.type, this.label, this.icon);
}

// ═══════════════════════════════════════════════════════════════════════
// REORDERABLE GRID VIEW (simplified)
// ═══════════════════════════════════════════════════════════════════════

/// A minimal reorderable grid using [ReorderableListView] with grid wrapping.
class ReorderableGridView extends StatelessWidget {
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final List<Widget> children;
  final void Function(int oldIndex, int newIndex) onReorder;

  const ReorderableGridView({
    super.key,
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.children,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return Material(
              color: Colors.transparent,
              elevation: 8,
              child: child,
            );
          },
        );
      },
      onReorderItem: onReorder,
      children: children
          .map(
            (child) => Padding(
              key: child.key,
              padding: EdgeInsets.only(bottom: mainAxisSpacing),
              child: AspectRatio(aspectRatio: 1.0, child: child),
            ),
          )
          .toList(),
    );
  }
}
