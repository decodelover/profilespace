/// Portfolio BLoC — State Management for the Bento Grid Editor
///
/// Handles loading the portfolio, reordering blocks via drag-and-drop,
/// adding new blocks, deleting blocks, and toggling wiggle-mode.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities.dart';
import '../../domain/usecases/get_portfolio.dart';
import '../../domain/usecases/update_block_layout.dart';
import '../../domain/usecases/add_block.dart';
import '../../domain/usecases/delete_block.dart';
import '../../domain/usecases/upload_image.dart';

// ═══════════════════════════════════════════════════════════════════════
// EVENTS
// ═══════════════════════════════════════════════════════════════════════

abstract class PortfolioEvent extends Equatable {
  const PortfolioEvent();
  @override
  List<Object?> get props => [];
}

/// Load the user's portfolio from the API.
class PortfolioLoadRequested extends PortfolioEvent {
  const PortfolioLoadRequested();
}

/// Toggle wiggle mode on/off for drag reordering.
class PortfolioWiggleModeToggled extends PortfolioEvent {
  const PortfolioWiggleModeToggled();
}

/// Reorder blocks after a drag-and-drop operation.
class PortfolioBlocksReordered extends PortfolioEvent {
  final int oldIndex;
  final int newIndex;

  const PortfolioBlocksReordered({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// Add a new block to the portfolio.
class PortfolioBlockAdded extends PortfolioEvent {
  final BlockType type;
  final Map<String, dynamic> content;

  const PortfolioBlockAdded({required this.type, this.content = const {}});

  @override
  List<Object?> get props => [type, content];
}

/// Delete a block from the portfolio.
class PortfolioBlockDeleted extends PortfolioEvent {
  final String blockId;

  const PortfolioBlockDeleted(this.blockId);

  @override
  List<Object?> get props => [blockId];
}

/// Upload and attach an image to an existing block.
class PortfolioBlockImageUploadRequested extends PortfolioEvent {
  final String blockId;
  final String filePath;

  const PortfolioBlockImageUploadRequested({
    required this.blockId,
    required this.filePath,
  });

  @override
  List<Object?> get props => [blockId, filePath];
}

// ═══════════════════════════════════════════════════════════════════════
// STATES
// ═══════════════════════════════════════════════════════════════════════

abstract class PortfolioState extends Equatable {
  const PortfolioState();
  @override
  List<Object?> get props => [];
}

class PortfolioInitial extends PortfolioState {
  const PortfolioInitial();
}

class PortfolioLoading extends PortfolioState {
  const PortfolioLoading();
}

class PortfolioLoaded extends PortfolioState {
  final Portfolio portfolio;
  final bool isWiggleMode;

  const PortfolioLoaded({required this.portfolio, this.isWiggleMode = false});

  PortfolioLoaded copyWith({Portfolio? portfolio, bool? isWiggleMode}) {
    return PortfolioLoaded(
      portfolio: portfolio ?? this.portfolio,
      isWiggleMode: isWiggleMode ?? this.isWiggleMode,
    );
  }

  @override
  List<Object?> get props => [portfolio, isWiggleMode];
}

class PortfolioError extends PortfolioState {
  final String message;
  const PortfolioError(this.message);
  @override
  List<Object?> get props => [message];
}

// ═══════════════════════════════════════════════════════════════════════
// BLOC
// ═══════════════════════════════════════════════════════════════════════

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final GetPortfolio _getPortfolio;
  final UpdateBlockLayout _updateBlockLayout;
  final AddBlock _addBlock;
  final DeleteBlock _deleteBlock;
  final UploadImage _uploadImage;

  PortfolioBloc({
    required GetPortfolio getPortfolio,
    required UpdateBlockLayout updateBlockLayout,
    required AddBlock addBlock,
    required DeleteBlock deleteBlock,
    required UploadImage uploadImage,
  }) : _getPortfolio = getPortfolio,
       _updateBlockLayout = updateBlockLayout,
       _addBlock = addBlock,
       _deleteBlock = deleteBlock,
       _uploadImage = uploadImage,
       super(const PortfolioInitial()) {
    on<PortfolioLoadRequested>(_onLoad);
    on<PortfolioWiggleModeToggled>(_onWiggleToggle);
    on<PortfolioBlocksReordered>(_onReorder);
    on<PortfolioBlockAdded>(_onAddBlock);
    on<PortfolioBlockDeleted>(_onDeleteBlock);
    on<PortfolioBlockImageUploadRequested>(_onUploadBlockImage);
  }

  Future<void> _onLoad(
    PortfolioLoadRequested event,
    Emitter<PortfolioState> emit,
  ) async {
    emit(const PortfolioLoading());
    final result = await _getPortfolio();
    result.fold(
      (failure) => emit(PortfolioError(failure.message)),
      (portfolio) => emit(PortfolioLoaded(portfolio: portfolio)),
    );
  }

  void _onWiggleToggle(
    PortfolioWiggleModeToggled event,
    Emitter<PortfolioState> emit,
  ) {
    final current = state;
    if (current is PortfolioLoaded) {
      emit(current.copyWith(isWiggleMode: !current.isWiggleMode));
    }
  }

  Future<void> _onReorder(
    PortfolioBlocksReordered event,
    Emitter<PortfolioState> emit,
  ) async {
    final current = state;
    if (current is! PortfolioLoaded) return;

    // Optimistically reorder blocks locally.
    final blocks = List<PortfolioBlock>.from(current.portfolio.blocks);
    final item = blocks.removeAt(event.oldIndex);
    blocks.insert(event.newIndex, item);

    // Update sort orders.
    final reorderedBlocks = blocks.asMap().entries.map((entry) {
      return entry.value.copyWith(sortOrder: entry.key);
    }).toList();

    emit(
      current.copyWith(
        portfolio: current.portfolio.copyWithBlocks(reorderedBlocks),
      ),
    );

    // Persist to the backend.
    await _updateBlockLayout(reorderedBlocks);
  }

  Future<void> _onAddBlock(
    PortfolioBlockAdded event,
    Emitter<PortfolioState> emit,
  ) async {
    final current = state;
    if (current is! PortfolioLoaded) return;

    // Calculate next grid position (append at bottom).
    final maxY = current.portfolio.blocks.fold<int>(
      0,
      (max, b) => b.gridPosition.y + b.gridPosition.h > max
          ? b.gridPosition.y + b.gridPosition.h
          : max,
    );

    final position = GridPosition(x: 0, y: maxY, w: 2, h: 1);

    final result = await _addBlock(
      type: event.type,
      position: position,
      content: event.content,
    );

    result.fold(
      (failure) {
        // Silently fail; the user can retry.
      },
      (newBlock) {
        final updatedBlocks = [...current.portfolio.blocks, newBlock];
        emit(
          current.copyWith(
            portfolio: current.portfolio.copyWithBlocks(updatedBlocks),
          ),
        );
      },
    );
  }

  Future<void> _onDeleteBlock(
    PortfolioBlockDeleted event,
    Emitter<PortfolioState> emit,
  ) async {
    final current = state;
    if (current is! PortfolioLoaded) return;

    // Optimistically remove the block.
    final updatedBlocks = current.portfolio.blocks
        .where((b) => b.id != event.blockId)
        .toList();

    emit(
      current.copyWith(
        portfolio: current.portfolio.copyWithBlocks(updatedBlocks),
      ),
    );

    // Persist deletion.
    await _deleteBlock(event.blockId);
  }

  Future<void> _onUploadBlockImage(
    PortfolioBlockImageUploadRequested event,
    Emitter<PortfolioState> emit,
  ) async {
    final current = state;
    if (current is! PortfolioLoaded) return;

    final result = await _uploadImage(event.filePath);

    await result.fold(
      (failure) async {
        // Fail silently or log error
      },
      (url) async {
        final updatedBlocks = current.portfolio.blocks.map((b) {
          if (b.id == event.blockId) {
            final newContent = Map<String, dynamic>.from(b.content);
            newContent['url'] = url;
            return b.copyWith(content: newContent);
          }
          return b;
        }).toList();

        emit(
          current.copyWith(
            portfolio: current.portfolio.copyWithBlocks(updatedBlocks),
          ),
        );

        // Persist update back to database
        await _updateBlockLayout(updatedBlocks);
      },
    );
  }
}
