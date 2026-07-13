/// Portfolio Domain — Repository Contract
library;

import '../../../../core/domain/entities.dart';
import '../../../../core/errors/failures.dart';

/// Contract for all portfolio CRUD and layout operations.
abstract class PortfolioRepository {
  /// Fetches the authenticated user's portfolio with all blocks.
  Future<Result<Portfolio>> getPortfolio();

  /// Bulk-updates block positions after a drag-and-drop reorder.
  Future<Result<Portfolio>> updateBlockLayout(List<PortfolioBlock> blocks);

  /// Creates a new block and appends it to the portfolio grid.
  Future<Result<PortfolioBlock>> addBlock({
    required BlockType type,
    required GridPosition position,
    required Map<String, dynamic> content,
  });

  /// Permanently removes a block from the portfolio.
  Future<Result<void>> deleteBlock(String blockId);

  /// Uploads an image to the cloud bucket.
  Future<Result<String>> uploadImage(String filePath);
}
