import 'package:equatable/equatable.dart';

class ViewsDataPoint extends Equatable {
  final String date;
  final int views;

  const ViewsDataPoint({required this.date, required this.views});

  @override
  List<Object?> get props => [date, views];
}

class CountryMetric extends Equatable {
  final String code;
  final String name;
  final int count;

  const CountryMetric({
    required this.code,
    required this.name,
    required this.count,
  });

  @override
  List<Object?> get props => [code, name, count];
}

class AnalyticsData extends Equatable {
  final int totalViews;
  final int mobileViews;
  final int desktopViews;
  final List<ViewsDataPoint> viewsOverTime;
  final List<CountryMetric> countries;

  const AnalyticsData({
    required this.totalViews,
    required this.mobileViews,
    required this.desktopViews,
    required this.viewsOverTime,
    required this.countries,
  });

  @override
  List<Object?> get props => [
    totalViews,
    mobileViews,
    desktopViews,
    viewsOverTime,
    countries,
  ];
}
