import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/get_messages.dart';

// EVENTS
abstract class InboxEvent extends Equatable {
  const InboxEvent();
  @override
  List<Object?> get props => [];
}

class InboxFetchRequested extends InboxEvent {
  const InboxFetchRequested();
}

// STATES
abstract class InboxState extends Equatable {
  const InboxState();
  @override
  List<Object?> get props => [];
}

class InboxInitial extends InboxState {
  const InboxInitial();
}

class InboxLoading extends InboxState {
  const InboxLoading();
}

class InboxLoaded extends InboxState {
  final List<Message> messages;

  const InboxLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class InboxError extends InboxState {
  final String message;

  const InboxError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLOC
class InboxBloc extends Bloc<InboxEvent, InboxState> {
  final GetMessages _getMessages;

  InboxBloc({required GetMessages getMessages})
      : _getMessages = getMessages,
        super(const InboxInitial()) {
    on<InboxFetchRequested>(_onFetch);
  }

  Future<void> _onFetch(
    InboxFetchRequested event,
    Emitter<InboxState> emit,
  ) async {
    emit(const InboxLoading());
    final result = await _getMessages();
    result.fold(
      (failure) => emit(InboxError(failure.message)),
      (messages) => emit(InboxLoaded(messages)),
    );
  }
}
