import '../../../../core/errors/failures.dart';
import '../entities/analytics_data.dart';
import '../repositories/analytics_repository.dart';

class GetAnalytics {
  final AnalyticsRepository _repository;

  const GetAnalytics(this._repository);

  Future<Result<AnalyticsData>> call() {
    return _repository.getAnalytics();
  }
}
