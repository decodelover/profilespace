import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final Dio dio;

  const AnalyticsRepositoryImpl({required this.dio});

  @override
  Future<Result<AnalyticsData>> getAnalytics() async {
    try {
      final response = await dio.get('/analytics');
      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;

        final viewsList = (data['views_over_time'] as List)
            .map(
              (item) => ViewsDataPoint(
                date: item['date'] as String,
                views: item['views'] as int,
              ),
            )
            .toList();

        final countriesList = (data['countries'] as List)
            .map(
              (item) => CountryMetric(
                code: item['code'] as String,
                name: item['name'] as String,
                count: item['count'] as int,
              ),
            )
            .toList();

        final breakdown = data['device_breakdown'] as Map<String, dynamic>;

        final analyticsData = AnalyticsData(
          totalViews: data['total_views'] as int,
          mobileViews: (breakdown['mobile'] ?? 0) as int,
          desktopViews: (breakdown['desktop'] ?? 0) as int,
          viewsOverTime: viewsList,
          countries: countriesList,
        );

        return Result.success(analyticsData);
      }
      return Result.failure(
        ServerFailure(message: 'Failed to fetch analytics data.'),
      );
    } on DioException catch (e) {
      return Result.failure(
        ServerFailure(
          message:
              e.response?.data?['message']?.toString() ??
              'Failed to load analytics.',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
}
