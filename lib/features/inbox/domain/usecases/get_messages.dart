import '../../../../core/errors/failures.dart';
import '../entities/message.dart';
import '../repositories/inbox_repository.dart';

class GetMessages {
  final InboxRepository _repository;

  const GetMessages(this._repository);

  Future<Result<List<Message>>> call() {
    return _repository.getMessages();
  }
}
