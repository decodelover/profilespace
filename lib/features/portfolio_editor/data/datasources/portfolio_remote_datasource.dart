/// Portfolio Data Layer — Remote Data Source & Repository Implementation
library;

import 'package:dio/dio.dart';

import '../../../../core/domain/entities.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/portfolio_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// REMOTE DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════

/// Contract for portfolio network calls.
abstract class PortfolioRemoteDataSource {
  Future<Portfolio> getPortfolio();
  Future<Portfolio> updateBlockLayout(List<Map<String, dynamic>> blockData);
  Future<PortfolioBlock> addBlock(Map<String, dynamic> blockData);
  Future<void> deleteBlock(String blockId);
  Future<String> uploadImage(String filePath);
}

class PortfolioRemoteDataSourceImpl implements PortfolioRemoteDataSource {
  final Dio dio;

  const PortfolioRemoteDataSourceImpl({required this.dio});

  @override
  Future<Portfolio> getPortfolio() async {
    final response = await dio.get('/portfolios/me');
    return _parsePortfolio(response.data['data']);
  }

  @override
  Future<Portfolio> updateBlockLayout(
      List<Map<String, dynamic>> blockData) async {
    final response = await dio.put(
      '/portfolios/me/blocks/layout',
      data: {'blocks': blockData},
    );
    return _parsePortfolio(response.data['data']);
  }

  @override
  Future<PortfolioBlock> addBlock(Map<String, dynamic> blockData) async {
    final response = await dio.post(
      '/portfolios/me/blocks',
      data: blockData,
    );
    return _parseBlock(response.data['data']);
  }

  @override
  Future<void> deleteBlock(String blockId) async {
    await dio.delete('/portfolios/me/blocks/$blockId');
  }

  @override
  Future<String> uploadImage(String filePath) async {
    final file = await MultipartFile.fromFile(filePath);
    final formData = FormData.fromMap({'image': file});

    final response = await dio.post(
      '/upload/image',
      data: formData,
    );

    return response.data['data']['url'] as String;
  }

  Portfolio _parsePortfolio(Map<String, dynamic> data) {
    return Portfolio(
      id: data['id'].toString(),
      slug: data['slug'] as String,
      themeSettings: ThemeSettings(
        accentColor:
            (data['theme_settings'] as Map?)?['accent_color'] ?? '#6366F1',
        fontFamily:
            (data['theme_settings'] as Map?)?['font_family'] ?? 'Inter',
        layoutTemplate:
            (data['theme_settings'] as Map?)?['layout_template'] ??
                'minimal_dark',
      ),
      isPublished: data['is_published'] as bool? ?? false,
      blocks: (data['blocks'] as List<dynamic>?)
              ?.map((b) => _parseBlock(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  PortfolioBlock _parseBlock(Map<String, dynamic> data) {
    final pos = data['grid_position'] as Map<String, dynamic>? ?? {};
    return PortfolioBlock(
      id: data['id'].toString(),
      type: BlockType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => BlockType.text,
      ),
      gridPosition: GridPosition(
        x: pos['x'] as int? ?? 0,
        y: pos['y'] as int? ?? 0,
        w: pos['w'] as int? ?? 2,
        h: pos['h'] as int? ?? 1,
      ),
      content: data['content'] as Map<String, dynamic>? ?? {},
      isVisible: data['is_visible'] as bool? ?? true,
      sortOrder: data['sort_order'] as int? ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// REPOSITORY IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

class PortfolioRepositoryImpl implements PortfolioRepository {
  final PortfolioRemoteDataSource remoteDataSource;

  const PortfolioRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<Portfolio>> getPortfolio() async {
    try {
      final portfolio = await remoteDataSource.getPortfolio();
      return Result.success(portfolio);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data?['message']?.toString() ??
            'Failed to load portfolio.',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Result<Portfolio>> updateBlockLayout(
      List<PortfolioBlock> blocks) async {
    try {
      final blockData = blocks
          .map((b) => {
                'id': b.id,
                'sort_order': b.sortOrder,
                'grid_position': {
                  'x': b.gridPosition.x,
                  'y': b.gridPosition.y,
                  'w': b.gridPosition.w,
                  'h': b.gridPosition.h,
                },
              })
          .toList();
      final portfolio = await remoteDataSource.updateBlockLayout(blockData);
      return Result.success(portfolio);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data?['message']?.toString() ??
            'Failed to update layout.',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Result<PortfolioBlock>> addBlock({
    required BlockType type,
    required GridPosition position,
    required Map<String, dynamic> content,
  }) async {
    try {
      final block = await remoteDataSource.addBlock({
        'type': type.name,
        'grid_position': {
          'x': position.x,
          'y': position.y,
          'w': position.w,
          'h': position.h,
        },
        'content': content,
      });
      return Result.success(block);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message:
            e.response?.data?['message']?.toString() ?? 'Failed to add block.',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Result<void>> deleteBlock(String blockId) async {
    try {
      await remoteDataSource.deleteBlock(blockId);
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data?['message']?.toString() ??
            'Failed to delete block.',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Result<String>> uploadImage(String filePath) async {
    try {
      final url = await remoteDataSource.uploadImage(filePath);
      return Result.success(url);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data?['message']?.toString() ??
            'Failed to upload image.',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
}
