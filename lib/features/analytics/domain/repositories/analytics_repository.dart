import '../../../../core/errors/failures.dart';
import '../entities/analytics_data.dart';

abstract class AnalyticsRepository {
  Future<Result<AnalyticsData>> getAnalytics();
}
