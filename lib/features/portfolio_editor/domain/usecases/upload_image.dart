import '../../../../core/errors/failures.dart';
import '../repositories/portfolio_repository.dart';

class UploadImage {
  final PortfolioRepository _repository;

  const UploadImage(this._repository);

  Future<Result<String>> call(String filePath) {
    return _repository.uploadImage(filePath);
  }
}
