/// Portfolio Use Cases — GetPortfolio, UpdateBlockLayout, AddBlock, DeleteBlock
library;

import '../../../../core/domain/entities.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/portfolio_repository.dart';

// ─── Get Portfolio ────────────────────────────────────────────────────

class GetPortfolio {
  final PortfolioRepository _repository;
  const GetPortfolio(this._repository);

  Future<Result<Portfolio>> call() => _repository.getPortfolio();
}

// ─── Update Block Layout ──────────────────────────────────────────────

class UpdateBlockLayout {
  final PortfolioRepository _repository;
  const UpdateBlockLayout(this._repository);

  Future<Result<Portfolio>> call(List<PortfolioBlock> blocks) =>
      _repository.updateBlockLayout(blocks);
}

// ─── Add Block ────────────────────────────────────────────────────────

class AddBlock {
  final PortfolioRepository _repository;
  const AddBlock(this._repository);

  Future<Result<PortfolioBlock>> call({
    required BlockType type,
    required GridPosition position,
    required Map<String, dynamic> content,
  }) =>
      _repository.addBlock(type: type, position: position, content: content);
}

// ─── Delete Block ─────────────────────────────────────────────────────

class DeleteBlock {
  final PortfolioRepository _repository;
  const DeleteBlock(this._repository);

  Future<Result<void>> call(String blockId) =>
      _repository.deleteBlock(blockId);
}
