import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/usecases/get_analytics.dart';

// EVENTS
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

class AnalyticsFetchRequested extends AnalyticsEvent {
  const AnalyticsFetchRequested();
}

// STATES
abstract class AnalyticsState extends Equatable {
  const AnalyticsState();
  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading();
}

class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsData analyticsData;

  const AnalyticsLoaded(this.analyticsData);

  @override
  List<Object?> get props => [analyticsData];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLOC
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final GetAnalytics _getAnalytics;

  AnalyticsBloc({required GetAnalytics getAnalytics})
    : _getAnalytics = getAnalytics,
      super(const AnalyticsInitial()) {
    on<AnalyticsFetchRequested>(_onFetch);
  }

  Future<void> _onFetch(
    AnalyticsFetchRequested event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(const AnalyticsLoading());
    final result = await _getAnalytics();
    result.fold(
      (failure) => emit(AnalyticsError(failure.message)),
      (data) => emit(AnalyticsLoaded(data)),
    );
  }
}
